# Driver Navigation Correction Report — 2026-10-10

## 1. Verified starting Git state

| Item | Value |
| --- | --- |
| Branch | `test/driver-post-accept-lifecycle-live-v1` |
| HEAD | `59f2013866b488016e6b6283235f6860d2bff318` |
| Worktree | Dirty (live lifecycle harness/evidence + COD padding) — preserved |
| Backend | `feat/driver-assignment-version-contract` @ `3131c4ec…` (read-only) |
| Live evidence | `docs/evidence/post_accept_lifecycle_live_2026-10-09/` (22 screenshots + MANIFEST) retained |
| Baseline tests | 142/142 before navigation work |

No commit, push, merge, rebase, stash, checkout, or migration.

## 2. Root cause

Navigation was **session-binary** (`signedIn` → Home) rather than **business-state-driven**:

1. Splash and OTP always `context.go(/home)` for any profile-bearing session.
2. `driverRedirect` treated Splash as an auth route and bounced `signedIn` → Home, racing ahead of DriverMe / current-delivery resolution.
3. PENDING_REVIEW / REJECTED / incomplete UNVERIFIED Drivers could enter the four-tab shell.
4. Active delivery was not restored on cold start (only via Home banner after bootstrap).
5. Stitch “accueil_*” folders were easy to misread as a linear slideshow; Home is one route with states.

## 3. Previous behavior (before)

```
Splash → restore session
  signedIn → /home
  needsProfile → /onboarding/profile
  signedOut → /auth/phone

OTP success → /home if signedIn

Redirect: signedIn + (phone|otp|splash) → /home
Pending/rejected: not gated from shell
Active delivery on relaunch: not selected at Splash
```

## 4. Final canonical graph

```
Splash ──resolve──► Phone
                 ├─► Onboarding (first incomplete / pending / corrections)
                 ├─► Support (account suspended/inactive)
                 ├─► /delivery/current (approved + active delivery)
                 └─► /home (approved, no active delivery)

Home states: Offline | Online waiting | Offer | Active banner
Offer accept ──► /delivery/current
Delivery stages (same route): ASSIGNED→…→DELIVERED → Home
Shell tabs ↔ nested Profile/Settings/Support/Notifications (push/pop)
Blocked /blocked/:kind ← delivery help (pop back)
Logout confirm → Phone (stack replace)
```

## 5. 47-screen classification summary

| Classification | Count | Role |
| --- | --- | --- |
| sequential_step | 11 | Auth + onboarding funnel |
| state_variant | 16 | Home / delivery status variants |
| tab_root | 3 | History, Earnings, Profile roots |
| nested_detail | 9 | Profile/settings/support/history detail |
| blocked_contract | 5 | Contact, PIN, failure report, etc. |
| branch | 2 | Remaining mapped branches |
| not_applicable_duplicate | 1 | Discarded Drawer |
| **Total** | **47** | |

Full list: `DRIVER_NAVIGATION_STATE_MACHINE.json`.

## 6. Files changed

**Production**

- `lib/app/router/driver_navigation_resolver.dart` (new)
- `lib/app/router/driver_bootstrap_controller.dart` (new)
- `lib/app/router/app_router.dart`
- `lib/features/auth/presentation/splash_screen.dart`
- `lib/features/auth/presentation/otp_screen.dart`
- `lib/features/availability/presentation/driver_home_screen.dart`
- `lib/features/delivery/presentation/current_delivery_screen.dart`
- `lib/features/onboarding/presentation/onboarding_status_screen.dart`

**Tests / docs**

- `test/driver_navigation_resolver_test.dart` (new)
- `test/shell_navigation_test.dart` (redirect expectations)
- `docs/DRIVER_NAVIGATION_STATE_MACHINE.md`
- `docs/DRIVER_NAVIGATION_STATE_MACHINE.json`
- `docs/DRIVER_NAVIGATION_CORRECTION_REPORT_2026-10-10.md`

Live lifecycle evidence and harness files left intact.

## 7. Guards and resolver

- Pure `resolveColdStartDestination` + `driverRedirect(snapshot:)`.
- `DriverBootstrapController` loads `/driver/me` and current delivery after session/OTP.
- GoRouter refresh listens to session **and** nav snapshot.
- Pending Drivers cannot open Home/History/Earnings/Delivery.
- Approved Drivers cannot reopen editable onboarding via Back/deep link.
- Pending status CTA refreshes; no longer deep-links into Home.

## 8. Back / relaunch / tabs / logout

| Concern | Behavior |
| --- | --- |
| Back from delivery | `go(/home)` + clear active flag |
| Relaunch mid-delivery | Splash → bootstrap → `/delivery/current` |
| Tabs | IndexedStack; no duplicate stack entries |
| Notifications | `push` → pop to prior shell context |
| Language | Allowed in all lanes; no auth/delivery reset |
| Logout cancel | Stay on Profile |
| Logout confirm | Session clear → phone |

Deep links to shell while PENDING redirect to pending.

## 9. Tests

- New: `driver_navigation_resolver_test.dart` (cold start + guards).
- Updated: `shell_navigation_test.dart` redirect cases.
- Existing suite preserved (including COD sticky geometry assertion).

## 10. Analyzer

Post-smoke: **2 info** diagnostics only (pre-existing). Navigation-introduced `prefer_const_constructors` **fixed**.

## 10b. Live navigation smoke (2026-10-10)

See `DRIVER_NAVIGATION_LIVE_SMOKE_REPORT_2026-10-10.md` and `docs/evidence/navigation_live_smoke_2026-10-10/`.

| Scenario | Result |
| --- | --- |
| A No session | PASS live |
| B Approved home | PASS live |
| C Pending/corrections/inactive | NOT VERIFIED |
| D Active delivery cold start / relaunch | PASS live |
| E Offer accept | NOT RERUN |
| F Logout | PASS live |

## 11. Evidence level

| Area | Level |
| --- | --- |
| Resolver / redirects | `unit_tested` |
| Shell / tabs | `widget_tested` + `live_driver_ui_verified` (smoke B) |
| Splash/OTP wiring | `live_driver_ui_verified` (smoke A/B/D/F) |
| Delivery cold-start / relaunch | `live_driver_ui_verified` (smoke D) |
| Pending/rejected live guards | `not_verified` |
| Offer accept nav | prior Offers evidence; smoke E not rerun |
| COD lifecycle | prior `live_driver_ui_verified` (preserved) |

## 12. Remaining blocked contracts

- Customer delivery PIN
- Call/contact proxy
- Delivery failure / report submission
- Notification preferences Backend
- Maps SDK / turn-by-turn
- FCM/APNs
- Bicycle licence exemption (Backend still requires licence for current vehicle types)

## 13–14. Git / safety

Uncommitted navigation + prior live work remain local.  
**No commit / push / merge / migration / provider activation.**
