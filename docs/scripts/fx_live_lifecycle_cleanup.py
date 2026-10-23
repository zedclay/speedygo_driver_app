#!/usr/bin/env python3
"""Neutralize only this run's lifecycle fixture records. No FLUSHDB.

Usage: fx_live_lifecycle_cleanup.py
"""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

FX_SQL = Path(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/isolated/fx_sql.sh',
)
SECRETS = Path.home() / '.speedygo' / 'parity_fx' / 'live_lifecycle' / 'secrets.json'
DRIVER_ID = '0d00f0f0-fa00-7000-8000-000000009131'


def sql(statement: str) -> str:
    p = subprocess.run(
        ['bash', str(FX_SQL)], input=statement, capture_output=True, text=True,
    )
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip()[:400])
    return p.stdout.strip()


def main() -> None:
    db = sql('SELECT current_database();')
    if db != 'speedygo_parity_fx':
        raise SystemExit(f'refused db={db}')
    if not SECRETS.exists():
        print(json.dumps({'ok': True, 'note': 'no secrets file'}))
        return
    secrets = json.loads(SECRETS.read_text())
    order_id = secrets.get('orderId')
    delivery_id = secrets.get('deliveryId')
    assignment_id = secrets.get('assignmentId')
    if not order_id or not delivery_id:
        raise SystemExit('incomplete secrets')

    # Release any leftover active assignment for this delivery/driver.
    sql(f"""
UPDATE driver_assignments
SET status = 'RELEASED', released_at = COALESCE(released_at, now())
WHERE id = '{assignment_id}' OR (
  driver_id = '{DRIVER_ID}' AND released_at IS NULL
);
UPDATE driver_availability
SET status = 'OFFLINE', offline_after_current_delivery = false, updated_at = now()
WHERE driver_id = '{DRIVER_ID}';
""")

    # Remove task-owned auth OTP keys only.
    subprocess.run(
        [
            'bash', '-c',
            "redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' "
            "| while read -r k; do redis-cli -p 6381 -n 9 DEL \"$k\" >/dev/null; done",
        ],
        capture_output=True, text=True, check=False,
    )

    # Wipe secrets (tokens/codes) from disk; keep meta evidence elsewhere.
    if 'pickupCode' in secrets:
        secrets['pickupCode'] = '<cleared>'
    secrets['cleanedAt'] = __import__('time').strftime(
        '%Y-%m-%dT%H:%M:%SZ', __import__('time').gmtime(),
    )
    SECRETS.write_text(json.dumps(secrets) + '\n')
    SECRETS.unlink(missing_ok=True)

    active = sql(f"""
SELECT count(*)::text FROM driver_assignments
WHERE driver_id = '{DRIVER_ID}' AND released_at IS NULL;
""")
    print(json.dumps({
        'ok': True,
        'orderIdSuffix': order_id[-8:],
        'deliveryIdSuffix': delivery_id[-8:],
        'remainingActiveAssignments': int(active or 0),
        'secretsRemoved': True,
        'flushdb': False,
    }))


if __name__ == '__main__':
    main()
