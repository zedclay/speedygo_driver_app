#!/usr/bin/env bash
# Resume COD collect → complete on existing ARRIVED_CUSTOMER fixture (no new setup).
set -euo pipefail

DRIVER_APP=/Users/mac/Downloads/speedygo_project/apps/driver_app
FX_ISOLATED=/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/isolated
# shellcheck source=/dev/null
. "$FX_ISOLATED/fx_common.sh"
fx_load_targets

UDID=8DB9007A-B816-4EC5-86ED-C627AC60F2C5
BUNDLE=com.speedygo.speedygoDriverApp
EVIDENCE="$DRIVER_APP/docs/evidence/post_accept_lifecycle_live_2026-10-09"
PREFIX=fxlife
SHOT=/tmp/parity_fx_lifecycle_shot.txt
API_BASE=http://127.0.0.1:3100/api/v1
OTP_FILE="$HOME/.speedygo/parity_fx/otp/otp-last"
SECRETS="$HOME/.speedygo/parity_fx/live_lifecycle/secrets.json"
CUSTOMER_LAT=36.770
CUSTOMER_LNG=3.050

curl -sf http://127.0.0.1:3100/health >/dev/null || { echo "API not healthy"; exit 1; }
DB_NAME=$(bash "$FX_ISOLATED/fx_sql.sh" <<<'SELECT current_database();')
[[ "$DB_NAME" == "speedygo_parity_fx" ]] || { echo "FX_ERROR db=$DB_NAME"; exit 1; }

# Guard: only resume when still ARRIVED_CUSTOMER without COD
STATUS=$(python3 <<'PY'
import json,subprocess
from pathlib import Path
s=json.loads(Path.home().joinpath('.speedygo/parity_fx/live_lifecycle/secrets.json').read_text())
did=s['deliveryId']
out=subprocess.check_output(['bash','/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/isolated/fx_sql.sh'],input=f"SELECT status FROM deliveries WHERE id='{did}';",text=True).strip()
print(out)
PY
)
echo "RESUME_STATUS=$STATUS"
[[ "$STATUS" == "ARRIVED_CUSTOMER" ]] || { echo "FX_ERROR expected ARRIVED_CUSTOMER got $STATUS"; exit 1; }

xcrun simctl location "$UDID" set "${CUSTOMER_LAT},${CUSTOMER_LNG}" >/dev/null 2>&1 || true
printf '{"lat":%s,"lng":%s}\n' "$CUSTOMER_LAT" "$CUSTOMER_LNG" > /tmp/parity_fx_lifecycle_loc.json

clear_otp_keys() {
  redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' \
    | while read -r k; do redis-cli -p 6381 -n 9 DEL "$k" >/dev/null; done || true
}

: > "$SHOT"
(
  last=""
  while true; do
    tag=$(tail -1 "$SHOT" 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$tag" && "$tag" != "$last" ]]; then
      case "$tag" in
        "${PREFIX}_clear_otp") clear_otp_keys; echo "OTP_CLEARED"; last="$tag"; continue ;;
        "${PREFIX}_99_done") break ;;
      esac
      xcrun simctl io "$UDID" screenshot "$EVIDENCE/screenshots/${tag}.png" >/dev/null 2>&1 || true
      echo "SHOT $tag $(stat -f%z "$EVIDENCE/screenshots/${tag}.png" 2>/dev/null || echo 0)"
      last="$tag"
    fi
    sleep 0.3
  done
) > "$EVIDENCE/shots_watch_resume.log" 2>&1 &
WATCH=$!

set +e
(
  cd "$DRIVER_APP" && flutter test \
    integration_test/live_post_accept_lifecycle_resume_cod_test.dart \
    -d "$UDID" \
    --reporter expanded \
    --dart-define=API_BASE_URL="$API_BASE" \
    --dart-define=FX_OTP_FILE="$OTP_FILE" \
    --dart-define=FX_EVIDENCE_DIR="$EVIDENCE" \
    --dart-define=FX_SECRETS_PATH="$SECRETS" \
    --dart-define=PARITY_PREFIX="$PREFIX"
) > "$EVIDENCE/flutter_resume_cod.log" 2>&1
RC=$?
set +e
sleep 2
kill "$WATCH" 2>/dev/null || true
wait "$WATCH" 2>/dev/null || true
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
sed -E 's/\b[0-9]{6,8}\b/<otp>/g' -i '' "$EVIDENCE/flutter_resume_cod.log" 2>/dev/null || true

python3 "$DRIVER_APP/docs/scripts/fx_live_lifecycle_verify.py" \
  "$EVIDENCE/meta/meta_cod.json" "$EVIDENCE/verify_cod.json" \
  | tee "$EVIDENCE/verify_console.json"

echo "RESUME_RC=$RC"
tail -30 "$EVIDENCE/flutter_resume_cod.log"
exit "$RC"
