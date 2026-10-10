#!/usr/bin/env python3
"""Fetch PENDING merchant pickup handoff into secrets (no stdout secrets).

Call after live arrive-pickup reaches AT_PICKUP.
Usage: fx_live_lifecycle_handoff_fetch.py
"""
from __future__ import annotations

import json
import os
import stat
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE = 'http://127.0.0.1:3100/api/v1'
OTP = Path.home() / '.speedygo' / 'parity_fx' / 'otp' / 'otp-last'
SECRETS = Path.home() / '.speedygo' / 'parity_fx' / 'live_lifecycle' / 'secrets.json'
MERCHANT = '0d00f0f0-fa00-7000-8000-000000001001'
OWNER = '+213550009101'


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
        'deviceName': 'parity-fx-life-handoff',
    })
    if s not in (200, 201):
        raise SystemExit(f'otp verify http={s}')
    return body['accessToken']


def main() -> None:
    if not SECRETS.exists():
        raise SystemExit('secrets missing')
    secrets = json.loads(SECRETS.read_text())
    order_id = secrets['orderId']
    token = login(OWNER)
    s, handoff = jreq(
        'GET',
        f'/merchant/{MERCHANT}/orders/{order_id}/delivery/pickup-handoff',
        token=token,
    )
    code = handoff.get('pickupCode') if isinstance(handoff, dict) else None
    if s != 200 or not (
        isinstance(code, str) and len(code) == 4 and code.isdigit()
    ):
        raise SystemExit(f'handoff fetch failed http={s} status={handoff.get("status") if isinstance(handoff, dict) else None}')
    secrets['pickupCode'] = code
    secrets['handoffStatus'] = handoff.get('status')
    secrets['handoffSource'] = 'authenticated_merchant_api'
    SECRETS.write_text(json.dumps(secrets) + '\n')
    os.chmod(SECRETS, stat.S_IRUSR | stat.S_IWUSR)
    jreq('POST', '/auth/logout', token=token)
    # Never print the code.
    print(json.dumps({
        'ok': True,
        'handoffStatus': handoff.get('status'),
        'codeLength': 4,
        'source': 'authenticated_merchant_api',
    }))


if __name__ == '__main__':
    main()
