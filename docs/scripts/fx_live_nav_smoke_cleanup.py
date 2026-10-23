#!/usr/bin/env python3
"""Cleanup nav-smoke fixtures only. No FLUSHDB."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

FX_SQL = Path(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/isolated/fx_sql.sh',
)
SECRETS = Path.home() / '.speedygo' / 'parity_fx' / 'live_nav_smoke' / 'secrets.json'
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
    sql(f"""
UPDATE driver_assignments
SET status = 'RELEASED', released_at = COALESCE(released_at, now())
WHERE driver_id = '{DRIVER_ID}' AND released_at IS NULL;
UPDATE driver_availability
SET status = 'OFFLINE', offline_after_current_delivery = false, updated_at = now()
WHERE driver_id = '{DRIVER_ID}';
""")
    subprocess.run(
        [
            'bash', '-c',
            "redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' "
            "| while read -r k; do redis-cli -p 6381 -n 9 DEL \"$k\" >/dev/null; done",
        ],
        capture_output=True, text=True, check=False,
    )
    removed = False
    if SECRETS.exists():
        SECRETS.unlink()
        removed = True
    active = sql(f"""
SELECT count(*)::text FROM driver_assignments
WHERE driver_id = '{DRIVER_ID}' AND released_at IS NULL;
""")
    print(json.dumps({
        'ok': True,
        'secretsRemoved': removed,
        'remainingActiveAssignments': int(active or 0),
        'flushdb': False,
    }))


if __name__ == '__main__':
    main()
