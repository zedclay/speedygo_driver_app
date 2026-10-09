#!/usr/bin/env python3
"""Prepare scoped FX fixtures for live Driver offers UI phases.

Writes meta JSON without tokens/OTPs.
Usage: fx_live_offers_setup.py <meta-out.json> <phase>
  phases: offline | waiting | accept | reject | expire | arabic
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE = 'http://127.0.0.1:3100/api/v1'
OTP = Path.home() / '.speedygo' / 'parity_fx' / 'otp' / 'otp-last'
FX_ISOLATED = Path(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/isolated',
)
FX_SQL = FX_ISOLATED / 'fx_sql.sh'
CREATE_INCOMING = FX_ISOLATED / 'fx_create_incoming.py'

NS = '0d00f0f0-fa00-7000-8000-'
MERCHANT = NS + '000000001001'
DRIVER_PHONE = '+213550009131'
DRIVER_ID = NS + '000000009131'
DRIVER_ACCT = NS + '000000000131'
OWNER = '+213550009101'
BRANCH_LAT = 36.785
BRANCH_LNG = 3.060
RUN_ID = f'ui_offers_{int(time.time())}'


def jreq(method, path, token=None, data=None):
    headers = {}
    body = None
    if token:
        headers['Authorization'] = f'Bearer {token}'
    if data is not None:
        body = json.dumps(data).encode()
        headers['Content-Type'] = 'application/json'
    req = urllib.request.Request(BASE + path, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as res:
            return res.status, json.loads(res.read().decode() or '{}')
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or '{}')


def sql(statement: str) -> str:
    p = subprocess.run(
        ['bash', str(FX_SQL)], input=statement, capture_output=True, text=True,
    )
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip()[:300])
    return p.stdout.strip()


def clear_otp():
    subprocess.run(
        [
            'bash', '-c',
            "redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' "
            "| while read -r k; do redis-cli -p 6381 -n 9 DEL \"$k\" >/dev/null; done",
        ],
        capture_output=True, text=True, check=False,
    )


def login(phone: str, label: str) -> str:
    clear_otp()
    time.sleep(0.3)
    before = time.time() - 1
    for attempt in range(5):
        s, _ = jreq('POST', '/auth/otp/request', data={
            'channel': 'PHONE', 'identifier': phone, 'purpose': 'AUTHENTICATE',
        })
        if s in (200, 201, 202):
            break
        if s == 429:
            time.sleep(6 + attempt * 3)
            clear_otp()
            continue
        raise SystemExit(f'otp request {label} http={s}')
    otp = None
    for _ in range(80):
        if OTP.exists() and OTP.stat().st_mtime >= before:
            text = OTP.read_text().strip()
            if text.isdigit():
                otp = text
                break
        time.sleep(0.25)
    if not otp:
        raise SystemExit(f'otp missing {label}')
    s, body = jreq('POST', '/auth/otp/verify', data={
        'channel': 'PHONE', 'identifier': phone, 'purpose': 'AUTHENTICATE',
        'code': otp, 'platform': 'ios', 'appVersion': '1.0.0',
        'deviceName': f'parity-fx-ui-{label}-{RUN_ID}',
    })
    if s not in (200, 201):
        raise SystemExit(f'otp verify {label} http={s}')
    return body['accessToken']


def fx_uuid(tag: str) -> str:
    return NS + hashlib.sha1(f'{RUN_ID}:{tag}'.encode()).hexdigest()[:12]


def ensure_driver_offline():
    sql(f"""
UPDATE driver_assignments
SET status = 'RELEASED', released_at = COALESCE(released_at, now())
WHERE driver_id = '{DRIVER_ID}' AND released_at IS NULL;
UPDATE driver_availability
SET status = 'OFFLINE', offline_after_current_delivery = false, updated_at = now()
WHERE driver_id = '{DRIVER_ID}';
""")


def ensure_driver_online_api(token: str):
    jreq('POST', '/driver/availability/go-offline', token=token)
    s, me = jreq('POST', '/driver/availability/go-online', token=token)
    if s != 200 or (me.get('availability') or {}).get('status') != 'ONLINE':
        raise RuntimeError(f'go-online http={s}')
    for attempt in range(6):
        s, loc = jreq('POST', '/driver/location', token=token, data={
            'latitude': BRANCH_LAT, 'longitude': BRANCH_LNG, 'accuracyMeters': 10,
        })
        if s == 200:
            return
        if s == 429:
            time.sleep(2 + attempt)
            continue
        raise RuntimeError(f'location http={s}')


def create_ready_order(merchant_token: str) -> str:
    out = Path('/tmp') / f'{RUN_ID}_incoming.json'
    last = ''
    for attempt in range(6):
        p = subprocess.run(
            ['python3', str(CREATE_INCOMING), str(out), '1'],
            capture_output=True, text=True,
        )
        if p.returncode == 0:
            break
        last = (p.stderr or p.stdout)[:300]
        time.sleep(6 + attempt * 3)
        clear_otp()
    else:
        raise RuntimeError(f'incoming failed {last}')
    order_id = json.loads(out.read_text())['orders'][0]['id']
    out.unlink(missing_ok=True)
    for path, data in (
        (f'/merchant/{MERCHANT}/orders/{order_id}/accept', {'preparationMinutes': 20}),
        (f'/merchant/{MERCHANT}/orders/{order_id}/start-preparation', {}),
        (f'/merchant/{MERCHANT}/orders/{order_id}/mark-ready', {}),
    ):
        s, body = jreq('POST', path, token=merchant_token, data=data)
        if s not in (200, 201):
            raise RuntimeError(f'{path} http={s} {body}')
    return order_id


def seed_offer(order_id: str, *, assigned_offset_seconds: int = 0) -> tuple[str, str]:
    delivery_id = sql(f"SELECT id FROM deliveries WHERE order_id = '{order_id}'")
    if not delivery_id:
        delivery_id = fx_uuid('del')
        sql(f"""
INSERT INTO deliveries (id, order_id, status, driver_search_started_at, created_at, updated_at)
VALUES ('{delivery_id}', '{order_id}', 'SEARCHING_DRIVER', now(), now(), now());
""")
    else:
        sql(f"""
UPDATE deliveries SET status='SEARCHING_DRIVER', updated_at=now() WHERE id='{delivery_id}';
""")
    sql(f"""
UPDATE driver_assignments
SET status='RELEASED', released_at=now()
WHERE released_at IS NULL AND (delivery_id='{delivery_id}' OR driver_id='{DRIVER_ID}');
""")
    assignment_id = fx_uuid(f'asg-{assigned_offset_seconds}')
    offset = f"now() - interval '{assigned_offset_seconds} seconds'"
    sql(f"""
INSERT INTO driver_assignments (
  id, delivery_id, driver_id, status, assigned_at, accepted_at, released_at, version
) VALUES (
  '{assignment_id}', '{delivery_id}', '{DRIVER_ID}', 'OFFERED',
  {offset}, NULL, NULL, 1
);
""")
    return delivery_id, assignment_id


def main():
    meta_path = Path(sys.argv[1])
    phase = sys.argv[2]
    if phase == 'arm':
        # Called by screenshot watcher after UI login: seed a fresh OFFERED row.
        prior = json.loads(meta_path.read_text())
        order_id = prior['orderId']
        offset = int(prior.get('assignedOffsetSeconds') or 0)
        delivery_id, assignment_id = seed_offer(
            order_id, assigned_offset_seconds=offset,
        )
        prior.update({
            'assignmentId': assignment_id,
            'assignmentIdSuffix': assignment_id[-8:],
            'deliveryId': delivery_id,
            'offerSeeded': True,
            'armedAt': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        })
        meta_path.write_text(json.dumps(prior, indent=2) + '\n')
        print(json.dumps({'phase': 'arm', 'runId': prior.get('runId'), 'ok': True}))
        return

    ensure_driver_offline()
    meta = {
        'runId': RUN_ID,
        'phase': phase,
        'fixtureType': 'isolated_deterministic_fixture',
        'api': BASE,
        'database': 'speedygo_parity_fx',
        'redisIndex': 9,
        'driverPhoneMasked': '+213550009***',
    }
    if phase == 'offline':
        meta['availabilityPrepared'] = 'OFFLINE'
    elif phase == 'waiting':
        # UI taps go-online itself; only ensure offline start.
        meta['availabilityPrepared'] = 'OFFLINE'
    elif phase in ('accept', 'reject', 'arabic', 'expire'):
        merchant = login(OWNER, 'merchant')
        driver = login(DRIVER_PHONE, 'driver-setup')
        ensure_driver_online_api(driver)
        order_id = create_ready_order(merchant)
        # Prepare SEARCHING_DRIVER delivery but defer OFFERED insert until after
        # UI login (offer timeout is 30s; OTP login can exceed that).
        delivery_id = sql(f"SELECT id FROM deliveries WHERE order_id = '{order_id}'")
        if not delivery_id:
            delivery_id = fx_uuid('del')
            sql(f"""
INSERT INTO deliveries (id, order_id, status, driver_search_started_at, created_at, updated_at)
VALUES ('{delivery_id}', '{order_id}', 'SEARCHING_DRIVER', now(), now(), now());
""")
        else:
            sql(f"""
UPDATE deliveries SET status='SEARCHING_DRIVER', updated_at=now()
WHERE id='{delivery_id}';
""")
        sql(f"""
UPDATE driver_assignments
SET status='RELEASED', released_at=now()
WHERE released_at IS NULL AND (delivery_id='{delivery_id}' OR driver_id='{DRIVER_ID}');
""")
        offset = 22 if phase == 'expire' else 0
        meta.update({
            'orderId': order_id,
            'deliveryId': delivery_id,
            'orderIdSuffix': order_id[-8:],
            'deliveryIdSuffix': delivery_id[-8:],
            'availabilityPrepared': 'ONLINE',
            'offerSeeded': False,
            'armOffer': True,
            'assignedOffsetSeconds': offset,
            'fixtureType': 'isolated_deterministic_fixture',
        })
        del merchant, driver
    else:
        raise SystemExit(f'unknown phase {phase}')
    meta_path.write_text(json.dumps(meta, indent=2) + '\n')
    print(json.dumps({'phase': phase, 'runId': RUN_ID, 'ok': True}))


if __name__ == '__main__':
    main()
