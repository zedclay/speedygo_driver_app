#!/usr/bin/env python3
"""Scoped authenticated FX API checks for Driver availability / location / offer read.

Targets only:
  Database: speedygo_parity_fx
  API:      http://127.0.0.1:3100/api/v1
  Redis:    index 9 (auth:parityfx:*)

Never prints tokens or OTP codes. No migrations. No FLUSHDB. No Merchant/Customer writes.
Offer accept/reject/expiration require a live matching offer — reported separately when absent.
"""
from __future__ import annotations

import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE = 'http://127.0.0.1:3100/api/v1'
OTP = Path.home() / '.speedygo' / 'parity_fx' / 'otp' / 'otp-last'
DRIVER_PHONE = '+213550009131'
RUN_ID = f'avail_{int(time.time())}'
RESULTS: list[dict] = []


def record(name: str, ok: bool, detail: str = '', evidence: str = 'authenticated_api') -> None:
    RESULTS.append({
        'check': name,
        'result': 'PASS' if ok else 'FAIL',
        'detail': detail,
        'evidence': evidence,
    })
    print(f'{"PASS" if ok else "FAIL"}  {name}  {detail}'[:400])


def req(method: str, path: str, token: str | None = None, data=None, timeout=45):
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


def login(phone: str) -> str:
    clear_otp_keys()
    time.sleep(0.2)
    before = time.time() - 1
    status, body = jreq(
        'POST',
        '/auth/otp/request',
        data={'channel': 'PHONE', 'identifier': phone, 'purpose': 'AUTHENTICATE'},
    )
    if status not in (200, 201, 202):
        raise SystemExit(f'otp request failed http={status}')
    otp = None
    for _ in range(80):
        if OTP.exists() and OTP.stat().st_mtime >= before:
            text = OTP.read_text().strip()
            if text.isdigit():
                otp = text
                break
        time.sleep(0.25)
    if not otp:
        raise SystemExit('otp code unavailable')
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
            'deviceName': f'parity-fx-avail-{RUN_ID}',
        },
    )
    token = body.get('accessToken')
    if status not in (200, 201) or not token:
        raise SystemExit(f'otp verify failed http={status}')
    return token


def main() -> int:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
    out.mkdir(parents=True, exist_ok=True)

    status, health = jreq('GET', '/')
    record('fx_api_reachable', status == 200 and health.get('status') == 'ok', f'http={status}')

    try:
        token = login(DRIVER_PHONE)
        record('driver_otp_login', True, 'authenticated')
    except SystemExit as error:
        record('driver_otp_login', False, str(error))
        _write(out)
        return 1

    status, me = jreq('GET', '/driver/me', token=token)
    record(
        'driver_me',
        status == 200 and me.get('driverProfileExists') is True,
        f'http={status} availability={(me.get("availability") or {}).get("status")}',
    )

    # Normalize to OFFLINE when possible so go-online is testable.
    availability = (me.get('availability') or {}).get('status')
    if availability in ('ONLINE', 'OFFLINE_AFTER_CURRENT_DELIVERY'):
        status, me = jreq('POST', '/driver/availability/go-offline', token=token)
        record(
            'go_offline_normalize',
            status == 200 and (me.get('availability') or {}).get('status') in (
                'OFFLINE', 'OFFLINE_AFTER_CURRENT_DELIVERY',
            ),
            f'http={status} status={(me.get("availability") or {}).get("status")}',
        )

    status, me = jreq('POST', '/driver/availability/go-online', token=token)
    online_ok = status == 200 and (me.get('availability') or {}).get('status') == 'ONLINE'
    record(
        'go_online',
        online_ok,
        f'http={status} status={(me.get("availability") or {}).get("status")} '
        f'matchingEligible={me.get("matchingEligible")}',
    )

    status, loc = jreq(
        'POST',
        '/driver/location',
        token=token,
        data={'latitude': 36.7538, 'longitude': 3.0588, 'accuracyMeters': 15},
    )
    record(
        'publish_location_http',
        status == 200 and loc.get('recordedAt') is not None,
        f'http={status} applied={loc.get("applied")}',
    )

    status, offer_body = jreq('GET', '/driver/assignments/current-offer', token=token)
    offer = offer_body.get('offer')
    record(
        'current_offer_read',
        status == 200 and 'offer' in offer_body,
        f'http={status} offer={"present" if offer else "null"}',
    )
    if offer:
        record(
            'offer_shape',
            all(
                key in offer
                for key in (
                    'assignmentId',
                    'deliveryId',
                    'orderPublicReference',
                    'expiresAt',
                    'driverRemunerationMinor',
                    'pickup',
                )
            )
            and 'phone' not in json.dumps(offer).lower(),
            'authorized fields only',
        )
        # Do not accept/reject a live foreign offer belonging to another run.
        RESULTS.append({
            'check': 'accept_reject_expiration',
            'result': 'NOT_VERIFIED',
            'detail': 'live offer present; accept/reject left to dedicated matching fixture',
            'evidence': 'not_verified',
        })
        print('NOT_VERIFIED  accept_reject_expiration  live offer present; skipped mutating actions')
    else:
        RESULTS.append({
            'check': 'accept_reject_expiration',
            'result': 'NOT_VERIFIED',
            'detail': 'no live OFFERED assignment for this Driver in FX at run time',
            'evidence': 'not_verified',
        })
        print('NOT_VERIFIED  accept_reject_expiration  no live OFFERED assignment')

    status, current = jreq('GET', '/driver/deliveries/current', token=token)
    record(
        'current_delivery_read',
        status == 200,
        f'http={status} delivery={"present" if current.get("delivery") else "null"}',
    )

    status, me = jreq('POST', '/driver/availability/go-offline', token=token)
    record(
        'go_offline',
        status == 200 and (me.get('availability') or {}).get('status') in (
            'OFFLINE', 'OFFLINE_AFTER_CURRENT_DELIVERY',
        ),
        f'http={status} status={(me.get("availability") or {}).get("status")}',
    )

    _write(out)
    failed = sum(1 for row in RESULTS if row['result'] == 'FAIL' and row['evidence'] != 'not_verified')
    return 1 if failed else 0


def _write(out: Path) -> None:
    payload = {
        'runId': RUN_ID,
        'api': BASE,
        'database': 'speedygo_parity_fx',
        'redisIndex': 9,
        'results': RESULTS,
    }
    (out / 'fx_availability_api_verify.json').write_text(
        json.dumps(payload, indent=2) + '\n',
    )


if __name__ == '__main__':
    raise SystemExit(main())
