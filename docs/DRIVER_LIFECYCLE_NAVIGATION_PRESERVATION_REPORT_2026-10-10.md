# Driver Lifecycle + Navigation Preservation Report

Date: 2026-10-10  
Repository: `speedygo_driver_app` (`apps/driver_app`)  
Preservation branch: `feat/driver-lifecycle-navigation-verified-v1`

## Starting baseline

| Item | Value |
| --- | --- |
| Starting branch | `test/driver-post-accept-lifecycle-live-v1` |
| Starting HEAD | `59f2013866b488016e6b6283235f6860d2bff318` |
| Backend (read-only) | `3131c4ec…` (unchanged) |
| Related remote | `origin/feat/driver-stitch-full-ui-v1` @ `59f2013866b488016e6b6283235f6860d2bff318` |
| Related remote | `origin/feat/driver-availability-offers-v1` @ `be7cedd142f3810757d699a60ee3808ce6f8fdf7` |

This report preserves verified Driver lifecycle and navigation work. It is **not** a release-readiness declaration.

## Commit list (parent → tip)

Created on `feat/driver-lifecycle-navigation-verified-v1` from the starting SHA above (no amend, no rebase, no force):

1. `feat(driver): add state-driven navigation and lifecycle routing`
2. `test(driver): verify lifecycle and navigation flows`
3. `docs(driver): preserve lifecycle and navigation evidence`
4. `docs(driver): record lifecycle navigation preservation` (this file)

Exact tip SHA is the tip of this branch after this commit lands; do not amend earlier commits to rewrite SHAs into this document.

## Evidence directories

| Directory | Screenshots | Manifest |
| --- | --- | --- |
| `docs/evidence/post_accept_lifecycle_live_2026-10-09/` | 22 | `MANIFEST.json` |
| `docs/evidence/navigation_live_smoke_2026-10-10/` | 17 | `MANIFEST.json` |

Prior Offers evidence under `docs/evidence/availability_offers_live_2026-10-09/` was not modified.

## Navigation smoke classifications (unchanged)

| Scenario | Classification |
| --- | --- |
| A — no-session cold start | `live_driver_ui_verified` |
| B — approved Driver without delivery | `live_driver_ui_verified` |
| C — pending/corrections/inactive | `not_verified` (live NOT VERIFIED) |
| D — active-delivery cold start/relaunch | `live_driver_ui_verified` |
| E — offer acceptance | `not_rerun` / `not_verified` for this smoke; prior Offers live evidence remains separately preserved |
| F — logout | `live_driver_ui_verified` |

Lifecycle COD path remains separately live verified under the post-accept lifecycle evidence set.

## Stitch classification (unchanged)

From `docs/DRIVER_STITCH_SCREEN_COVERAGE.json`:

- Folder total: **47**
- `unreviewed`: **0**
- All four shell destinations remain represented (`tab_root = 3` intentional; Home is `state_variant`)

## Security scan

Before staging:

- Removed `secretsPath` absolute home paths from evidence meta JSON.
- Removed `secretsPath` emission from lifecycle/nav smoke setup harnesses.
- Relativized `setup_console.json` meta path to `meta/meta_cod.json`.
- Confirmed manifests lack OTP/pickup-code values and credential headers.
- Integration harnesses only accept `FX_SECRETS_PATH` via compile-time `--dart-define` (runtime injection; not fixture metadata).

No `.env`, tokens, OTPs, pickup codes, private keys, or credentialed URLs were committed.

## Large-file scan

- Largest committed PNG under evidence ≈ 343 KB.
- Logo asset ≈ 113 KB.
- No file near GitHub’s 100 MB per-file limit.

## Deliberately excluded (left untracked)

Runtime / local artifacts under evidence dirs:

- `*.log` (also covered by repo `.gitignore`)
- `analyze.txt`
- `flutter_test.txt`
- `disk_*.txt`
- `handoff_fetch.err`

These remain on disk for local debugging and are not part of the preservation branch tip.

## Remaining unverified scenarios

- Navigation smoke **C** — live NOT VERIFIED
- Navigation smoke **E** — not rerun in this batch; prior Offers evidence preserved separately

## Validation note

Pre-push validation required on this branch tip:

- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze` (only the two pre-existing info diagnostics allowed)
- `flutter test` (≥ 164/164)

## Confirmation

- No merge into `main`
- No rebase / reset / stash / force-push
- No Backend / Merchant / Customer / Admin source modification as part of this preservation
- Not release ready

## Post-commit validation fix

After the initial four preservation commits, `flutter test` failed on pending splash brand-hold timers. A fifth commit added `splashMinDurationProvider` (default 1200ms; tests override to zero). Production hold behavior is unchanged.
