#!/usr/bin/env python3
"""Prepare DRIVER_ASSIGNED COD fixture for live post-accept lifecycle UI.

Isolated only: :3100 / speedygo_parity_fx / Redis 9.
Classification: isolated deterministic fixture (not matching-generated).

Never prints tokens, OTPs, or pickup codes.
Usage: fx_live_lifecycle_setup.py <meta-out.json>
"""
from __future__ import annotations

import json
import os
import stat
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
FX_ISOLATED = Path(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/isolated',
)
FX_SQL = FX_ISOLATED / 'fx_sql.sh'
CREATE_INCOMING = FX_ISOLATED / 'fx_create_incoming.py'

BASE = 'http://127.0.0.1:3100/api/v1'
OTP = Path.home() / '.speedygo' / 'parity_fx' / 'otp' / 'otp-last'
NS = '0d00f0f0-fa00-7000-8000-'
MERCHANT = NS + '000000001001'
BRANCH = NS + '000000002001'
DRIVER_PHONE = '+213550009131'
DRIVER_ID = NS + '000000009131'
DRIVER_ACCT = NS + '000000000131'
OWNER = '+213550009101'
BRANCH_LAT = 36.785
BRANCH_LNG = 3.060
CUSTOMER_LAT = 36.770
CUSTOMER_LNG = 3.050

META_OUT = Path(sys.argv[1])
RUN_ID = f"fxlive_driver_lifecycle_{time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())}"
SECRETS_DIR = Path.home() / '.speedygo' / 'parity_fx' / 'live_lifecycle'
SECRETS_FILE = SECRETS_DIR / 'secrets.json'


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
    import subprocess
    p = subprocess.run(
        ['bash', str(FX_SQL)], input=statement, capture_output=True, text=True,
    )
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip()[:400])
    return p.stdout.strip()


def clear_otp():
    import subprocess
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
        'deviceName': f'parity-fx-life-{label}-{RUN_ID}',
    })
    if s not in (200, 201):
        raise SystemExit(f'otp verify {label} http={s}')
    return body['accessToken']


def fx_uuid(tag: str) -> str:
    import hashlib
    return NS + hashlib.sha1(f'{RUN_ID}:{tag}'.encode()).hexdigest()[:12]


def seed_driver():
    sql(f"""
INSERT INTO accounts (id, phone, email, status)
VALUES ('{DRIVER_ACCT}', '{DRIVER_PHONE}', NULL, 'ACTIVE')
ON CONFLICT (id) DO NOTHING;
INSERT INTO driver_profiles (id, account_id, full_name, verification_status, approved_at)
VALUES ('{DRIVER_ID}', '{DRIVER_ACCT}', 'Yacine Mansouri', 'APPROVED', now())
ON CONFLICT (id) DO NOTHING;
UPDATE driver_assignments
SET status = 'RELEASED', released_at = COALESCE(released_at, now())
WHERE driver_id = '{DRIVER_ID}' AND released_at IS NULL;
UPDATE driver_availability
SET status = 'OFFLINE', offline_after_current_delivery = false, updated_at = now()
WHERE driver_id = '{DRIVER_ID}';
INSERT INTO driver_availability (driver_id, status, offline_after_current_delivery, updated_at)
VALUES ('{DRIVER_ID}', 'OFFLINE', false, now())
ON CONFLICT (driver_id) DO UPDATE
SET status = 'OFFLINE', offline_after_current_delivery = false, updated_at = now();
INSERT INTO vehicles (id, driver_id, type, plate_number, model, color, status)
VALUES ('{NS}000000009231', '{DRIVER_ID}', 'Moto', '16-12345', 'Fixture Moto A', 'Noir', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;
""")


def place_cod_order() -> tuple[str, int]:
    import subprocess
    out = META_OUT.parent / f'incoming_{RUN_ID}.json'
    p = subprocess.run(
        ['python3', str(CREATE_INCOMING), str(out), '1'],
        capture_output=True, text=True,
    )
    if p.returncode != 0:
        raise SystemExit(f'create_incoming failed: {p.stderr[-300:]}')
    data = json.loads(out.read_text())
    orders = data.get('orders') or []
    if not orders:
        raise SystemExit(f'no orders: {data.get("errors")}')
    return orders[0]['id'], int(orders[0]['customerTotalMinor'])


def main() -> None:
    # Isolation guard
    db = sql('SELECT current_database();')
    if db != 'speedygo_parity_fx':
        raise SystemExit(f'refused: database is {db}')
    seed_driver()
    owner = login(OWNER, 'owner')
    order_id, payable = place_cod_order()
    s, body = jreq(
        'POST', f'/merchant/{MERCHANT}/orders/{order_id}/accept',
        token=owner, data={'preparationMinutes': 20},
    )
    if s not in (200, 201):
        raise SystemExit(f'accept http={s} body={body.get("code")}')
    s, body = jreq(
        'POST', f'/merchant/{MERCHANT}/orders/{order_id}/start-preparation',
        token=owner, data={},
    )
    if s not in (200, 201):
        raise SystemExit(f'start-preparation http={s} body={body.get("code")}')
    s, body = jreq(
        'POST', f'/merchant/{MERCHANT}/orders/{order_id}/mark-ready',
        token=owner, data={},
    )
    if s not in (200, 201):
        raise SystemExit(f'mark-ready http={s} body={body.get("code")}')

    delivery_id = sql(f"SELECT id FROM deliveries WHERE order_id = '{order_id}'")
    if not delivery_id:
        delivery_id = fx_uuid('delivery')
        sql(f"""
INSERT INTO deliveries (id, order_id, status, driver_search_started_at, created_at, updated_at)
VALUES ('{delivery_id}', '{order_id}', 'DRIVER_ASSIGNED', now(), now(), now());
""")
    sql(f"""
UPDATE driver_assignments
SET status = 'RELEASED', released_at = now()
WHERE released_at IS NULL
  AND (delivery_id = '{delivery_id}' OR driver_id = '{DRIVER_ID}');
UPDATE deliveries
SET status = 'DRIVER_ASSIGNED', updated_at = now()
WHERE id = '{delivery_id}';
""")
    assignment_id = fx_uuid('assignment')
    sql(f"""
INSERT INTO driver_assignments (
  id, delivery_id, driver_id, status, assigned_at, accepted_at, released_at, version
) VALUES (
  '{assignment_id}', '{delivery_id}', '{DRIVER_ID}', 'ACCEPTED',
  now(), now(), NULL, 1
);
UPDATE driver_availability
SET status = 'OFFLINE_AFTER_CURRENT_DELIVERY', updated_at = now()
WHERE driver_id = '{DRIVER_ID}';
""")
    version = int(sql(
        f"SELECT version::text FROM driver_assignments WHERE id = '{assignment_id}'",
    ) or '1')

    # Authoritative payable from snapshot when present
    snap = sql(f"""
SELECT customer_payable_minor::text
FROM order_financial_snapshots WHERE order_id = '{order_id}' LIMIT 1;
""")
    if snap.isdigit():
        payable = int(snap)

    pay_method = sql(f"""
SELECT method::text FROM payments WHERE order_id = '{order_id}' LIMIT 1;
""") or 'COD'

    # Seed a fresh location at merchant for first GPS gate (driver UI will re-publish).
    import subprocess
    driver_token = login(DRIVER_PHONE, 'driver')
    s, _ = jreq('POST', '/driver/location', token=driver_token, data={
        'latitude': BRANCH_LAT, 'longitude': BRANCH_LNG, 'accuracyMeters': 10,
    })
    if s not in (200, 201):
        raise SystemExit(f'location seed http={s}')

    ds, current = jreq('GET', '/driver/deliveries/current', token=driver_token)
    delivery = (current or {}).get('delivery') or {}
    if ds != 200 or delivery.get('deliveryStatus') != 'DRIVER_ASSIGNED':
        raise SystemExit(
            f'current not DRIVER_ASSIGNED http={ds} status={delivery.get("deliveryStatus")}',
        )
    actions = delivery.get('allowedActions') or []
    if 'start-to-pickup' not in actions:
        raise SystemExit(f'expected start-to-pickup in {actions}')

    SECRETS_DIR.mkdir(parents=True, exist_ok=True)
    secrets = {
        'runId': RUN_ID,
        'orderId': order_id,
        'deliveryId': delivery_id,
        'assignmentId': assignment_id,
        'assignmentVersion': version,
        'driverPhoneLocal': '550009131',
        'ownerPhoneLocal': '550009101',
        'merchantId': MERCHANT,
        'expectedCodMinor': payable,
        'paymentMethod': pay_method,
        'branchLat': BRANCH_LAT,
        'branchLng': BRANCH_LNG,
        'customerLat': CUSTOMER_LAT,
        'customerLng': CUSTOMER_LNG,
        'classification': 'isolated_deterministic_fixture',
    }
    SECRETS_FILE.write_text(json.dumps(secrets) + '\n')
    os.chmod(SECRETS_FILE, stat.S_IRUSR | stat.S_IWUSR)

    meta = {
        'runId': RUN_ID,
        'classification': 'isolated_deterministic_fixture',
        'paymentMethod': pay_method,
        'expectedCodMinor': payable,
        'orderIdSuffix': order_id[-8:],
        'deliveryIdSuffix': delivery_id[-8:],
        'assignmentIdSuffix': assignment_id[-8:],
        'assignmentVersion': version,
        'startingDeliveryStatus': 'DRIVER_ASSIGNED',
        'pickupHandoffRequired': True,
        'pickupHandoffNote': 'PENDING handoff issued after live arrive-pickup',
        'branchLat': BRANCH_LAT,
        'branchLng': BRANCH_LNG,
        'customerLat': CUSTOMER_LAT,
        'customerLng': CUSTOMER_LNG,
        'api': BASE,
        'database': 'speedygo_parity_fx',
        'redisDb': 9,
    }
    META_OUT.parent.mkdir(parents=True, exist_ok=True)
    META_OUT.write_text(json.dumps(meta, indent=2) + '\n')
    # logout tokens (best-effort)
    jreq('POST', '/auth/logout', token=driver_token)
    jreq('POST', '/auth/logout', token=owner)
    print(json.dumps({
        'runId': RUN_ID,
        'orderIdSuffix': order_id[-8:],
        'startingStatus': 'DRIVER_ASSIGNED',
        'expectedCodMinor': payable,
        'meta': 'meta/meta_cod.json',
    }))


if __name__ == '__main__':
    main()
