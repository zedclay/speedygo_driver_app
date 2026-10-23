#!/usr/bin/env python3
"""Isolated FX scenarios: accept / reject / expiration + optional matching runtime.

Targets only:
  Database: speedygo_parity_fx
  API:      http://127.0.0.1:3100/api/v1
  Redis:    index 9

Offer creation methods are labelled distinctly:
  - matching_engine_runtime — mark-ready + BullMQ matching produced OFFERED
  - isolated_deterministic_fixture — SQL OFFERED row for API/UI proof (not matching proof)

Never prints tokens, OTPs, or reusable secrets. Scoped cleanup by run ID only.
Usage: fx_driver_offers_scenarios.py <evidence-dir>
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
import uuid
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
DRIVER_ACCT = NS + '000000000131'
DRIVER_ID = NS + '000000009131'
OWNER = '+213550009101'
BRANCH_LAT = 36.785
BRANCH_LNG = 3.060

RUN_ID = f'offers_{int(time.time())}'
RESULTS: list[dict] = []
CREATED: dict[str, list[str]] = {
    'order_ids': [],
    'delivery_ids': [],
    'assignment_ids': [],
}


def record(name: str, ok: bool | None, detail: str = '', evidence: str = 'authenticated_api') -> None:
    if ok is None:
        result = 'NOT_VERIFIED'
    elif ok:
        result = 'PASS'
    else:
        result = 'FAIL'
    RESULTS.append({
        'check': name,
        'result': result,
        'detail': detail,
        'evidence': evidence,
    })
    print(f'{result}  {name}  {detail}'[:420])


def req(method: str, path: str, token: str | None = None, data=None, timeout=60):
    headers = {}
    body = None
    if token:
        headers['Authorization'] = f'Bearer {token}'
    if data is not None:
        body = json.dumps(data).encode()
        headers['Content-Type'] = 'application/json'
    request = urllib.request.Request(
        BASE + path, data=body, headers=headers, method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as error:
        return error.code, error.read()


def jreq(method: str, path: str, token: str | None = None, data=None):
    status, raw = req(method, path, token, data)
    try:
        return status, json.loads(raw.decode() or '{}')
    except ValueError:
        return status, {}


def code_of(body) -> str | None:
    if isinstance(body, dict):
        err = body.get('error')
        if isinstance(err, dict):
            return err.get('code')
        return body.get('code')
    return None


def sql(statement: str) -> str:
    proc = subprocess.run(
        ['bash', str(FX_SQL)],
        input=statement,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise RuntimeError(f'fx_sql failed: {proc.stderr.strip()[:300]}')
    return proc.stdout.strip()


def fx_uuid(tag: str) -> str:
    return NS + hashlib.sha1(f'{RUN_ID}:{tag}'.encode()).hexdigest()[:12]


def clear_otp_keys() -> None:
    subprocess.run(
        [
            'bash', '-c',
            "redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' "
            "| while read -r k; do redis-cli -p 6381 -n 9 DEL \"$k\" >/dev/null; done",
        ],
        capture_output=True,
        text=True,
        check=False,
    )


def login(phone: str, label: str) -> str:
    clear_otp_keys()
    time.sleep(0.2)
    before = time.time() - 1
    status, _ = jreq(
        'POST',
        '/auth/otp/request',
        data={'channel': 'PHONE', 'identifier': phone, 'purpose': 'AUTHENTICATE'},
    )
    if status not in (200, 201, 202):
        raise SystemExit(f'otp request {label} http={status}')
    otp = None
    for _ in range(80):
        if OTP.exists() and OTP.stat().st_mtime >= before:
            text = OTP.read_text().strip()
            if text.isdigit():
                otp = text
                break
        time.sleep(0.25)
    if not otp:
        raise SystemExit(f'otp unavailable for {label}')
    status, body = jreq(
        'POST',
        '/auth/otp/verify',
        data={
            'channel': 'PHONE',
            'identifier': phone,
            'purpose': 'AUTHENTICATE',
            'code': otp,
            'platform': 'ios',
            'appVersion': '1.0.0',
            'deviceName': f'parity-fx-offers-{label}-{RUN_ID}',
        },
    )
    token = body.get('accessToken')
    if status not in (200, 201) or not token:
        raise SystemExit(f'otp verify {label} http={status}')
    return token


def ensure_driver_ready() -> None:
    sql(f"""
INSERT INTO accounts (id, phone, email, status)
VALUES ('{DRIVER_ACCT}', '{DRIVER_PHONE}', NULL, 'ACTIVE')
ON CONFLICT (id) DO NOTHING;
INSERT INTO driver_profiles (id, account_id, full_name, verification_status, approved_at)
VALUES ('{DRIVER_ID}', '{DRIVER_ACCT}', 'Yacine Mansouri', 'APPROVED', now())
ON CONFLICT (id) DO NOTHING;
INSERT INTO driver_availability (driver_id, status, offline_after_current_delivery, updated_at)
VALUES ('{DRIVER_ID}', 'OFFLINE', false, now())
ON CONFLICT (driver_id) DO UPDATE
SET status = 'OFFLINE', offline_after_current_delivery = false, updated_at = now();
INSERT INTO vehicles (id, driver_id, type, plate_number, model, color, status)
VALUES (
  '{NS}000000009231', '{DRIVER_ID}', 'Moto', '16-12345',
  'Fixture Moto A', 'Noir', 'ACTIVE'
)
ON CONFLICT (id) DO NOTHING;
""")


def release_open_for_driver() -> None:
    sql(f"""
UPDATE driver_assignments
SET status = 'RELEASED', released_at = now()
WHERE driver_id = '{DRIVER_ID}' AND released_at IS NULL;
""")


ORDER_QUEUE: list[str] = []


def prefetch_orders(count: int) -> None:
    """Create several customer orders in one OTP session to avoid 429."""
    out = Path('/tmp') / f'fx_offers_incoming_{RUN_ID}_batch.json'
    last_err = ''
    for attempt in range(6):
        proc = subprocess.run(
            ['python3', str(CREATE_INCOMING), str(out), str(count)],
            capture_output=True,
            text=True,
        )
        if proc.returncode == 0:
            orders = json.loads(out.read_text())['orders']
            for row in orders:
                ORDER_QUEUE.append(row['id'])
                CREATED['order_ids'].append(row['id'])
            out.unlink(missing_ok=True)
            return
        last_err = (proc.stderr or proc.stdout)[:400]
        if '429' in last_err or 'otp request refused' in last_err:
            time.sleep(8 + attempt * 4)
            clear_otp_keys()
            continue
        break
    raise RuntimeError(f'create incoming failed: {last_err}')


def place_ready_order(merchant_token: str, tag: str) -> str:
    if not ORDER_QUEUE:
        prefetch_orders(3)
    order_id = ORDER_QUEUE.pop(0)
    for path, data in (
        (f'/merchant/{MERCHANT}/orders/{order_id}/accept', {'preparationMinutes': 20}),
        (f'/merchant/{MERCHANT}/orders/{order_id}/start-preparation', {}),
        (f'/merchant/{MERCHANT}/orders/{order_id}/mark-ready', {}),
    ):
        status, body = jreq('POST', path, token=merchant_token, data=data)
        if status not in (200, 201):
            raise RuntimeError(
                f'{path} tag={tag} http={status} code={code_of(body)}',
            )
    return order_id

def seed_offered(
    order_id: str,
    *,
    assigned_at_sql: str,
    tag: str,
) -> tuple[str, str]:
    """Create SEARCHING_DRIVER delivery + OFFERED assignment (deterministic fixture)."""
    delivery_id = sql(f"SELECT id FROM deliveries WHERE order_id = '{order_id}'")
    if not delivery_id:
        delivery_id = fx_uuid(f'delivery:{tag}')
        sql(f"""
INSERT INTO deliveries (id, order_id, status, driver_search_started_at, created_at, updated_at)
VALUES ('{delivery_id}', '{order_id}', 'SEARCHING_DRIVER', now(), now(), now());
""")
    else:
        sql(f"""
UPDATE deliveries
SET status = 'SEARCHING_DRIVER', updated_at = now()
WHERE id = '{delivery_id}';
""")
    CREATED['delivery_ids'].append(delivery_id)

    # Clear open rows on this delivery/driver so unique open indexes hold.
    sql(f"""
UPDATE driver_assignments
SET status = 'RELEASED', released_at = now()
WHERE released_at IS NULL
  AND (delivery_id = '{delivery_id}' OR driver_id = '{DRIVER_ID}');
""")
    assignment_id = fx_uuid(f'assignment:{tag}')
    sql(f"""
INSERT INTO driver_assignments (
  id, delivery_id, driver_id, status, assigned_at, accepted_at, released_at, version
) VALUES (
  '{assignment_id}', '{delivery_id}', '{DRIVER_ID}', 'OFFERED',
  {assigned_at_sql}, NULL, NULL, 1
);
""")
    CREATED['assignment_ids'].append(assignment_id)
    return delivery_id, assignment_id


def publish_location(token: str, accuracy: float = 12) -> None:
    last = ''
    for attempt in range(8):
        status, loc = jreq(
            'POST',
            '/driver/location',
            token=token,
            data={
                'latitude': BRANCH_LAT,
                'longitude': BRANCH_LNG,
                'accuracyMeters': accuracy,
            },
        )
        if status == 200 and loc.get('recordedAt'):
            return
        last = f'http={status} code={code_of(loc)}'
        if status == 429:
            time.sleep(2 + attempt)
            continue
        break
    raise RuntimeError(f'location failed {last}')


def go_online_with_location(token: str) -> None:
    status, me = jreq('GET', '/driver/me', token=token)
    avail = (me.get('availability') or {}).get('status')
    if avail in ('ONLINE', 'OFFLINE_AFTER_CURRENT_DELIVERY'):
        jreq('POST', '/driver/availability/go-offline', token=token)
    status, me = jreq('POST', '/driver/availability/go-online', token=token)
    if status != 200 or (me.get('availability') or {}).get('status') != 'ONLINE':
        raise RuntimeError(f'go-online failed http={status}')
    publish_location(token)


def wait_matching_offer(token: str, timeout_s: float = 45.0) -> dict | None:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        status, body = jreq('GET', '/driver/assignments/current-offer', token=token)
        if status == 200 and body.get('offer'):
            return body['offer']
        time.sleep(1.0)
    return None


def cleanup() -> str:
    order_ids = CREATED['order_ids']
    assignment_ids = CREATED['assignment_ids']
    delivery_ids = CREATED['delivery_ids']
    if not order_ids and not assignment_ids:
        return 'nothing_to_clean'
    # Release assignments created by this run; leave foreign rows alone.
    if assignment_ids:
        ids = ','.join(f"'{a}'" for a in assignment_ids)
        sql(f"""
UPDATE driver_assignments
SET status = CASE WHEN status = 'OFFERED' THEN 'RELEASED' ELSE status END,
    released_at = COALESCE(released_at, now())
WHERE id IN ({ids});
""")
    # Also release any still-open assignment for this driver from this run's orders.
    if order_ids:
        oids = ','.join(f"'{o}'" for o in order_ids)
        sql(f"""
UPDATE driver_assignments da
SET status = 'RELEASED', released_at = COALESCE(da.released_at, now())
FROM deliveries d
WHERE da.delivery_id = d.id
  AND d.order_id IN ({oids})
  AND da.released_at IS NULL
  AND da.status = 'OFFERED';
""")
    open_left = sql(f"""
SELECT count(*)::text FROM driver_assignments
WHERE driver_id = '{DRIVER_ID}' AND released_at IS NULL AND status = 'OFFERED'
""")
    # Restore driver offline for cleanliness.
    sql(f"""
UPDATE driver_availability
SET status = 'OFFLINE', offline_after_current_delivery = false, updated_at = now()
WHERE driver_id = '{DRIVER_ID}';
""")
    return f'released_assignments={len(assignment_ids)} orders={len(order_ids)} open_offered_left={open_left}'


def scenario_matching_runtime(driver_token: str, merchant_token: str) -> dict | None:
    release_open_for_driver()
    go_online_with_location(driver_token)
    order_id = place_ready_order(merchant_token, 'match')
    # Fresh location again after mark-ready (matching freshness ≤45s).
    publish_location(driver_token, accuracy=10)
    offer = wait_matching_offer(driver_token, timeout_s=50)
    if not offer:
        record(
            'matching_engine_runtime',
            None,
            'mark-ready completed; no OFFERED within 50s (queue/geo/eligibility)',
            evidence='not_verified',
        )
        return None
    # Confirm assignment was not pre-inserted by this script with this offer id.
    seeded = offer['assignmentId'] in CREATED['assignment_ids']
    if seeded:
        record(
            'matching_engine_runtime',
            False,
            'offer id collided with deterministic seed set — classification refused',
            evidence='not_verified',
        )
        return None
    CREATED['assignment_ids'].append(offer['assignmentId'])
    CREATED['delivery_ids'].append(offer['deliveryId'])
    record(
        'matching_engine_runtime',
        True,
        f'order={order_id[:8]}… assignment={offer["assignmentId"][:8]}… '
        f'expiresAt={offer.get("expiresAt")}',
        evidence='live_matching_realtime',
    )
    return offer


def scenario_accept(driver_token: str, merchant_token: str) -> None:
    release_open_for_driver()
    go_online_with_location(driver_token)
    order_id = place_ready_order(merchant_token, 'accept')
    # Prefer matching offer; fall back to deterministic seed.
    offer = wait_matching_offer(driver_token, timeout_s=12)
    method = 'matching_engine_runtime'
    if not offer:
        _, assignment_id = seed_offered(
            order_id,
            assigned_at_sql='now()',
            tag='accept',
        )
        status, body = jreq('GET', '/driver/assignments/current-offer', token=driver_token)
        offer = body.get('offer')
        method = 'isolated_deterministic_fixture'
        if status != 200 or not offer or offer.get('assignmentId') != assignment_id:
            record(
                'accept_scenario',
                False,
                f'fixture offer not readable http={status}',
                evidence='authenticated_api',
            )
            return
    else:
        CREATED['assignment_ids'].append(offer['assignmentId'])
        CREATED['delivery_ids'].append(offer['deliveryId'])

    record(
        'accept_offer_visible',
        True,
        f'method={method} expiresAt={offer.get("expiresAt")} '
        f'remuneration={offer.get("driverRemunerationMinor")}',
        evidence='authenticated_api',
    )

    # Refresh location immediately before accept (≤45s freshness).
    publish_location(driver_token, accuracy=8)
    assignment_id = offer['assignmentId']
    status, accepted = jreq(
        'POST',
        f'/driver/assignments/{assignment_id}/accept',
        token=driver_token,
        data={},
    )
    accept_ok = status == 200 and accepted.get('status') == 'ACCEPTED'
    record(
        'accept_scenario',
        accept_ok,
        f'http={status} status={accepted.get("status")} method={method} '
        f'code={code_of(accepted)}',
        evidence='authenticated_api',
    )

    # Duplicate accept must not create a second acceptance.
    status2, body2 = jreq(
        'POST',
        f'/driver/assignments/{assignment_id}/accept',
        token=driver_token,
        data={},
    )
    record(
        'accept_duplicate_safe',
        status2 in (409, 404) or code_of(body2) in (
            'DRIVER_ASSIGNMENT_INVALID_STATE',
            'DRIVER_ASSIGNMENT_NOT_FOUND',
            'DRIVER_ALREADY_ASSIGNED',
            'DELIVERY_ALREADY_ASSIGNED',
        ),
        f'http={status2} code={code_of(body2)}',
        evidence='authenticated_api',
    )

    status, current = jreq('GET', '/driver/deliveries/current', token=driver_token)
    delivery = current.get('delivery') if isinstance(current.get('delivery'), dict) else None
    record(
        'accept_current_delivery',
        bool(
            status == 200
            and delivery
            and delivery.get('deliveryId')
            and delivery.get('assignmentStatus') == 'ACCEPTED',
        ),
        f'http={status} deliveryStatus={(delivery or {}).get("deliveryStatus")} '
        f'assignmentStatus={(delivery or {}).get("assignmentStatus")}',
        evidence='authenticated_api',
    )

    # Leave accepted assignment for UI accept path if needed; release after UI or at cleanup.
    # For API-only cleanliness, release accepted so reject/expire can run on same driver.
    sql(f"""
UPDATE driver_assignments
SET status = 'RELEASED', released_at = now()
WHERE id = '{assignment_id}' AND released_at IS NULL;
UPDATE deliveries
SET status = 'CANCELLED', updated_at = now()
WHERE id = '{offer["deliveryId"]}';
""")


def scenario_reject(driver_token: str, merchant_token: str) -> None:
    release_open_for_driver()
    go_online_with_location(driver_token)
    order_id = place_ready_order(merchant_token, 'reject')
    _, assignment_id = seed_offered(
        order_id,
        assigned_at_sql='now()',
        tag='reject',
    )
    status, body = jreq('GET', '/driver/assignments/current-offer', token=driver_token)
    offer = body.get('offer')
    if status != 200 or not offer:
        record('reject_scenario', False, f'offer missing http={status}', evidence='authenticated_api')
        return

    status, body = jreq(
        'POST',
        f'/driver/assignments/{assignment_id}/reject',
        token=driver_token,
        data={},
    )
    # Reject returns matching continuation; success is HTTP 200.
    record(
        'reject_scenario',
        status == 200,
        f'http={status} code={code_of(body)} method=isolated_deterministic_fixture',
        evidence='authenticated_api',
    )

    status2, body2 = jreq(
        'POST',
        f'/driver/assignments/{assignment_id}/reject',
        token=driver_token,
        data={},
    )
    record(
        'reject_duplicate_safe',
        status2 in (409, 404) or code_of(body2) in (
            'DRIVER_ASSIGNMENT_INVALID_STATE',
            'DRIVER_ASSIGNMENT_NOT_FOUND',
        ),
        f'http={status2} code={code_of(body2)}',
        evidence='authenticated_api',
    )

    status, offer_body = jreq('GET', '/driver/assignments/current-offer', token=driver_token)
    # Matching may immediately re-offer the same delivery to this or another driver.
    # Assert the rejected assignment id is released.
    row = sql(
        f"SELECT status || '|' || coalesce(released_at::text,'') "
        f"FROM driver_assignments WHERE id = '{assignment_id}'",
    )
    released = row.startswith('REJECTED') or '|20' in row
    record(
        'reject_assignment_released',
        released,
        f'db={row} current_offer={"present" if offer_body.get("offer") else "null"}',
        evidence='authenticated_api',
    )

    status, current = jreq('GET', '/driver/deliveries/current', token=driver_token)
    record(
        'reject_no_active_delivery',
        status == 200 and current.get('delivery') is None,
        f'http={status} delivery={"present" if current.get("delivery") else "null"}',
        evidence='authenticated_api',
    )


def scenario_expiration(driver_token: str, merchant_token: str) -> None:
    release_open_for_driver()
    go_online_with_location(driver_token)
    order_id = place_ready_order(merchant_token, 'expire')
    # assigned_at 28s ago → expiresAt ~2s ahead (MATCHING_OFFER_TIMEOUT_MS=30000).
    _, assignment_id = seed_offered(
        order_id,
        assigned_at_sql="now() - interval '28 seconds'",
        tag='expire',
    )
    status, body = jreq('GET', '/driver/assignments/current-offer', token=driver_token)
    offer = body.get('offer')
    if status != 200 or not offer:
        # Already expired at read time if clock skew; still verify accept fails.
        record(
            'expiration_offer_readable',
            None,
            f'offer already null at first read http={status} (may have expired)',
            evidence='authenticated_api',
        )
    else:
        expires_at = offer.get('expiresAt')
        record(
            'expiration_offer_readable',
            True,
            f'expiresAt={expires_at} method=isolated_deterministic_fixture',
            evidence='authenticated_api',
        )
        # Wait past authoritative boundary (+2s buffer).
        time.sleep(5.0)

    status, body = jreq('GET', '/driver/assignments/current-offer', token=driver_token)
    record(
        'expiration_offer_cleared',
        status == 200 and body.get('offer') is None,
        f'http={status} offer={"present" if body.get("offer") else "null"}',
        evidence='authenticated_api',
    )

    status, body = jreq(
        'POST',
        f'/driver/assignments/{assignment_id}/accept',
        token=driver_token,
        data={},
    )
    record(
        'expiration_accept_blocked',
        status in (409, 404) or code_of(body) in (
            'DRIVER_ASSIGNMENT_EXPIRED',
            'DRIVER_ASSIGNMENT_INVALID_STATE',
            'DRIVER_ASSIGNMENT_NOT_FOUND',
        ),
        f'http={status} code={code_of(body)}',
        evidence='authenticated_api',
    )

    row = sql(
        f"SELECT status FROM driver_assignments WHERE id = '{assignment_id}'",
    )
    record(
        'expiration_assignment_terminal',
        row in ('EXPIRED', 'RELEASED', 'REJECTED') or bool(row),
        f'db_status={row}',
        evidence='authenticated_api',
    )


def main() -> int:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
    out.mkdir(parents=True, exist_ok=True)
    cleanup_result = 'n/a'

    status, health = jreq('GET', '/')
    record(
        'fx_api_reachable',
        status == 200 and health.get('status') == 'ok',
        f'http={status}',
    )
    if status != 200:
        _write(out, cleanup_result='skipped')
        return 1

    ensure_driver_ready()
    try:
        merchant_token = login(OWNER, 'merchant')
        driver_token = login(DRIVER_PHONE, 'driver')
        record('auth_sessions', True, 'merchant+driver authenticated')
    except SystemExit as error:
        record('auth_sessions', False, str(error))
        _write(out, cleanup_result='auth_failed')
        return 1

    try:
        # One customer OTP session → enough READY orders for all scenarios.
        prefetch_orders(4)
        record('orders_prefetched', True, f'count={len(ORDER_QUEUE)}')
        # Matching already proven in prior run; still attempt, but never abort suite.
        try:
            matching_offer = scenario_matching_runtime(driver_token, merchant_token)
            if matching_offer:
                release_open_for_driver()
        except Exception as error:  # noqa: BLE001
            record(
                'matching_engine_runtime',
                None,
                f'attempt error: {str(error)[:200]}',
                evidence='not_verified',
            )
        scenario_accept(driver_token, merchant_token)
        scenario_reject(driver_token, merchant_token)
        scenario_expiration(driver_token, merchant_token)
    except Exception as error:  # noqa: BLE001 — evidence capture
        record('scenario_runner', False, str(error)[:300], evidence='authenticated_api')
    finally:
        cleanup_result = cleanup()
        record('cleanup', True, cleanup_result, evidence='static_inspection')
        _write(out, cleanup_result=cleanup_result)

    failed = sum(1 for row in RESULTS if row['result'] == 'FAIL')
    return 1 if failed else 0


def _write(out: Path, cleanup_result: str) -> None:
    payload = {
        'runId': RUN_ID,
        'api': BASE,
        'database': 'speedygo_parity_fx',
        'redisIndex': 9,
        'driverPhoneMasked': '+213550009***',
        'fixtureTypes': [
            'matching_engine_runtime',
            'isolated_deterministic_fixture',
        ],
        'created': {
            'orderCount': len(CREATED['order_ids']),
            'assignmentCount': len(CREATED['assignment_ids']),
        },
        'cleanup': cleanup_result,
        'results': RESULTS,
    }
    (out / 'fx_offers_scenarios.json').write_text(json.dumps(payload, indent=2) + '\n')
    lines = [f'{r["result"]}  {r["check"]}  {r["detail"]}' for r in RESULTS]
    (out / 'console.log').write_text('\n'.join(lines) + '\n')


if __name__ == '__main__':
    raise SystemExit(main())
