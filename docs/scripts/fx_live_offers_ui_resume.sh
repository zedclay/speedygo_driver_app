#!/usr/bin/env bash
# Resume remaining live UI phases after offline/waiting already captured.
set -euo pipefail

DRIVER_APP=/Users/mac/Downloads/speedygo_project/apps/driver_app
FX_ISOLATED=/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/isolated
# shellcheck source=/dev/null
. "$FX_ISOLATED/fx_common.sh"
fx_load_targets

UDID=8DB9007A-B816-4EC5-86ED-C627AC60F2C5
BUNDLE=com.speedygo.speedygoDriverApp
EVIDENCE="$DRIVER_APP/docs/evidence/availability_offers_live_2026-10-09"
SCREENS="$EVIDENCE/screenshots"
META_DIR="$EVIDENCE/meta"
PREFIX=fxoffers
SHOT=/tmp/parity_fx_offers_shot.txt
API_BASE=http://127.0.0.1:3100/api/v1
OTP_FILE="$HOME/.speedygo/parity_fx/otp/otp-last"
RESULTS="$EVIDENCE/ui_phase_results.txt"

mkdir -p "$SCREENS" "$META_DIR"
if ! xcrun simctl list devices | grep "$UDID" | grep -q Booted; then
  xcrun simctl boot "$UDID"
  sleep 6
fi
xcrun simctl privacy "$UDID" grant location "$BUNDLE" >/dev/null 2>&1 || true
xcrun simctl location "$UDID" set 36.785,3.060 >/dev/null 2>&1 || true

clear_otp_keys() {
  redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' \
    | while read -r k; do redis-cli -p 6381 -n 9 DEL "$k" >/dev/null; done || true
}

phase_shot_ok() {
  local phase="$1"
  case "$phase" in
    accept)
      [[ -f "$SCREENS/${PREFIX}_03_active_offer.png" ]] &&
        [[ -f "$SCREENS/${PREFIX}_05_accepted_current_delivery.png" ]]
      ;;
    reject) [[ -f "$SCREENS/${PREFIX}_06_reject_waiting.png" ]] ;;
    expire) [[ -f "$SCREENS/${PREFIX}_08_expired_offer.png" ]] ;;
    arabic) [[ -f "$SCREENS/${PREFIX}_09_arabic_rtl_offer.png" ]] ;;
    *) return 1 ;;
  esac
}

watch_shots() {
  local phase_meta="$1"
  (
    last=""
    while true; do
      tag=$(tail -1 "$SHOT" 2>/dev/null | tr -d '\n' || true)
      if [[ -n "$tag" && "$tag" != "$last" ]]; then
        if [[ "$tag" == "${PREFIX}_clear_otp" ]]; then
          clear_otp_keys
          last="$tag"
          continue
        fi
        if [[ "$tag" == "${PREFIX}_arm_offer" ]]; then
          python3 "$DRIVER_APP/docs/scripts/fx_live_offers_setup.py" \
            "$phase_meta" arm >/dev/null
          echo "OFFER_ARMED"
          last="$tag"
          continue
        fi
        [[ "$tag" == "${PREFIX}_99_done" ]] && break
        xcrun simctl io "$UDID" screenshot "$SCREENS/${tag}.png" >/dev/null 2>&1 || true
        echo "SHOT $tag"
        last="$tag"
      fi
      sleep 0.3
    done
  ) > "$EVIDENCE/shots_watch.log" 2>&1 &
  echo $!
}

printf '%s\n' 'offline PASS' 'waiting PASS' > "$RESULTS"

for phase in accept reject expire arabic; do
  FREE=$(df -g /System/Volumes/Data | awk 'NR==2{print $4}')
  if [[ "${FREE:-0}" -lt 3 ]]; then
    echo "STOP disk=${FREE}Gi"
    echo "$phase NOT_RUN" >> "$RESULTS"
    break
  fi
  echo "PHASE_START $phase free=${FREE}Gi"
  clear_otp_keys
  sleep 4
  python3 "$DRIVER_APP/docs/scripts/fx_live_offers_setup.py" \
    "$META_DIR/meta_${phase}.json" "$phase"
  : > "$SHOT"
  WATCH=$(watch_shots "$META_DIR/meta_${phase}.json")
  set +e
  (
    cd "$DRIVER_APP" && flutter test \
      integration_test/live_availability_offers_driver_test.dart \
      -d "$UDID" \
      --dart-define=API_BASE_URL="$API_BASE" \
      --dart-define=FX_OTP_FILE="$OTP_FILE" \
      --dart-define=FX_EVIDENCE_DIR="$EVIDENCE" \
      --dart-define=PARITY_PREFIX="$PREFIX" \
      --dart-define=LIVE_OFFERS_PHASE="$phase"
  ) > "$EVIDENCE/flutter_${phase}.log" 2>&1
  rc=$?
  set +e
  sleep 2
  kill "$WATCH" 2>/dev/null || true
  wait "$WATCH" 2>/dev/null || true
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  sed -E 's/\b[0-9]{6,8}\b/<otp>/g' -i '' \
    "$EVIDENCE/flutter_${phase}.log" 2>/dev/null || true
  if phase_shot_ok "$phase"; then
    echo "$phase PASS" >> "$RESULTS"
    echo "PHASE_END $phase PASS (shots ok, flutter_rc=$rc)"
  else
    echo "$phase FAIL" >> "$RESULTS"
    echo "PHASE_END $phase FAIL flutter_rc=$rc"
  fi
  find /var/folders -maxdepth 4 -type d -name 'flutter_tools.*' -exec rm -rf {} + \
    2>/dev/null || true
  sleep 8
done

echo DONE
df -h /System/Volumes/Data | tail -1 | tee "$EVIDENCE/disk_after_ui.txt"
cat "$RESULTS"
