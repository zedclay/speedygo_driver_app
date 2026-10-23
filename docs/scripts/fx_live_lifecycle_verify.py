#!/usr/bin/env python3
"""Authenticated API + DB readbacks for post-accept lifecycle (no secrets).

Usage: fx_live_lifecycle_verify.py <meta.json> <out.json>
"""
from __future__ import annotations

import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

FX_SQL = Path(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/isolated/fx_sql.sh',
)
BASE = 'http://127.0.0.1:3100/api/v1'
OTP = Path.home() / '.speedygo' / 'parity_fx' / 'otp' / 'otp-last'
SECRETS = Path.home() / '.speedygo' / 'parity_fx' / 'live_lifecycle' / 'secrets.json'
DRIVER_PHONE = '+213550009131'


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
        raise RuntimeError(p.stderr.strip()[:400])
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


def login(phone: str) -> str:
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
        raise SystemExit(f'otp request http={s}')
    otp = None
    for _ in range(80):
        if OTP.exists() and OTP.stat().st_mtime >= before:
            text = OTP.read_text().strip()
            if text.isdigit():
                otp = text
                break
        time.sleep(0.25)
    if not otp:
        raise SystemExit('otp missing')
    s, body = jreq('POST', '/auth/otp/verify', data={
        'channel': 'PHONE', 'identifier': phone, 'purpose': 'AUTHENTICATE',
        'code': otp, 'platform': 'ios', 'appVersion': '1.0.0',
        'deviceName': 'parity-fx-life-verify',
    })
    if s not in (200, 201):
        raise SystemExit(f'otp verify http={s}')
    return body['accessToken']


def main() -> None:
    meta_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])
    meta = json.loads(meta_path.read_text())
    secrets = json.loads(SECRETS.read_text())
    order_id = secrets['orderId']
    delivery_id = secrets['deliveryId']
    expected_cod = int(secrets['expectedCodMinor'])

    db = sql('SELECT current_database();')
    if db != 'speedygo_parity_fx':
        raise SystemExit(f'refused db={db}')

    delivery_row = sql(f"""
SELECT status, picked_up_at IS NOT NULL, arrived_customer_at IS NOT NULL,
       delivered_at IS NOT NULL
FROM deliveries WHERE id = '{delivery_id}';
""")
    parts = delivery_row.split('|') if delivery_row else []
    delivery_status = parts[0] if parts else None

    handoff = sql(f"""
SELECT status, consumed_at IS NOT NULL
FROM delivery_pickup_handoffs
WHERE delivery_id = '{delivery_id}'
ORDER BY created_at DESC LIMIT 1;
""")
    handoff_status = handoff.split('|')[0] if handoff else None

    events = sql(f"""
SELECT type, count(*)::text
FROM delivery_events WHERE delivery_id = '{delivery_id}'
GROUP BY type ORDER BY type;
""")
    event_counts = {}
    for line in events.splitlines():
        if '|' in line:
            k, v = line.split('|', 1)
            event_counts[k] = int(v)

    cod = sql(f"""
SELECT count(*)::text, coalesce(max(collected_amount_minor),0)::text,
       coalesce(max(status),'')
FROM cod_collections WHERE order_id = '{order_id}';
""")
    cod_parts = cod.split('|') if cod else ['0', '0', '']
    pay = sql(f"""
SELECT method::text, status::text FROM payments WHERE order_id = '{order_id}' LIMIT 1;
""")
    pay_method, pay_status = (pay.split('|') + ['', ''])[:2]

    earnings = sql(f"""
SELECT count(*)::text, coalesce(max(net_earning_minor),0)::text,
       coalesce(max(status),'')
FROM driver_earnings WHERE delivery_id = '{delivery_id}';
""")
    earn_parts = earnings.split('|') if earnings else ['0', '0', '']

    remit = sql(f"""
SELECT count(*)::text FROM cod_remittances
WHERE driver_id = (SELECT driver_id FROM driver_assignments
                   WHERE delivery_id = '{delivery_id}' LIMIT 1);
""")
    alloc = sql(f"""
SELECT count(*)::text FROM cod_remittance_allocations cra
JOIN cod_collections cc ON cc.id = cra.collection_id
WHERE cc.order_id = '{order_id}';
""")

    assignment = sql(f"""
SELECT status, version::text, released_at IS NOT NULL
FROM driver_assignments WHERE delivery_id = '{delivery_id}'
ORDER BY assigned_at DESC LIMIT 1;
""")
    asg_parts = assignment.split('|') if assignment else []

    token = login(DRIVER_PHONE)
    cs, current = jreq('GET', '/driver/deliveries/current', token=token)
    hs, history = jreq('GET', '/driver/deliveries/history?limit=20', token=token)
    es, earnings_api = jreq('GET', '/driver/earnings', token=token)
    cos, cod_summary = jreq('GET', '/driver/cod/summary', token=token)
    jreq('POST', '/auth/logout', token=token)

    current_delivery = None
    if isinstance(current, dict):
        current_delivery = current.get('delivery')

    history_has = False
    if hs == 200 and isinstance(history, dict):
        items = history.get('items') or history.get('deliveries') or []
        for item in items if isinstance(items, list) else []:
            if isinstance(item, dict) and (
                item.get('deliveryId') == delivery_id
                or item.get('orderId') == order_id
            ):
                history_has = True
                break

    out = {
        'runId': meta.get('runId'),
        'database': db,
        'delivery': {
            'status': delivery_status,
            'hasPickedUpAt': parts[1] == 't' if len(parts) > 1 else False,
            'hasArrivedCustomerAt': parts[2] == 't' if len(parts) > 2 else False,
            'hasDeliveredAt': parts[3] == 't' if len(parts) > 3 else False,
            'arrivedPickupAtColumn': 'N/A — event DRIVER_ARRIVED_PICKUP only',
        },
        'assignment': {
            'status': asg_parts[0] if asg_parts else None,
            'version': int(asg_parts[1]) if len(asg_parts) > 1 and asg_parts[1].isdigit() else None,
            'released': asg_parts[2] == 't' if len(asg_parts) > 2 else None,
        },
        'handoff': {
            'status': handoff_status,
            'consumed': handoff.split('|')[1] == 't' if handoff and '|' in handoff else False,
        },
        'events': event_counts,
        'cod': {
            'collectionCount': int(cod_parts[0] or 0),
            'collectedAmountMinor': int(cod_parts[1] or 0),
            'status': cod_parts[2],
            'expectedAmountMinor': expected_cod,
            'amountMatch': int(cod_parts[1] or 0) == expected_cod,
        },
        'payment': {'method': pay_method, 'status': pay_status},
        'earnings': {
            'count': int(earn_parts[0] or 0),
            'netMinor': int(earn_parts[1] or 0),
            'status': earn_parts[2],
        },
        'remittanceCount': int(remit or 0),
        'allocationCount': int(alloc or 0),
        'api': {
            'currentHttp': cs,
            'currentIsNull': current_delivery is None,
            'historyHttp': hs,
            'historyContainsDelivery': history_has,
            'earningsHttp': es,
            'codSummaryHttp': cos,
            'codSummaryKeys': sorted(list(cod_summary.keys()))[:20]
            if isinstance(cod_summary, dict) else [],
            'earningsKeys': sorted(list(earnings_api.keys()))[:20]
            if isinstance(earnings_api, dict) else [],
        },
        'invariants': {
            'pickupEventOnce': event_counts.get('ORDER_PICKED_UP', 0) == 1,
            'completionEventOnce': event_counts.get('DELIVERY_COMPLETED', 0) == 1,
            'codOnce': int(cod_parts[0] or 0) == 1,
            'earningOnce': int(earn_parts[0] or 0) == 1,
            'noRemittanceFabricated': int(remit or 0) == 0,
            'noAllocationFabricated': int(alloc or 0) == 0,
            'delivered': delivery_status == 'DELIVERED',
            'handoffConsumed': handoff_status == 'CONSUMED',
            'paymentSucceeded': pay_status == 'SUCCEEDED',
        },
    }
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(out, indent=2) + '\n')
    print(json.dumps({
        'ok': all(out['invariants'].values()),
        'deliveryStatus': delivery_status,
        'invariants': out['invariants'],
    }))


if __name__ == '__main__':
    main()
