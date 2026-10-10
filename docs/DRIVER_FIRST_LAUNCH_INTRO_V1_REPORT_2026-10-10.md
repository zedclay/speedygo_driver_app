# Driver First-Launch Intro V1 Report

Date: 2026-10-10  
Branch: `feat/driver-first-launch-intro-v1`  
Base: `feat/driver-lifecycle-navigation-verified-v1` @ `c46440ae5eef53f427a5264b34343ff1a39fb57d`

## Scope

Three product-introduction slides shown once per local install after Splash, before the existing business-state resolver.

These are **not** Driver registration `/onboarding/*`.

Stitch tracker remains **47/47** (`unreviewed = 0`).  
These screens are documented separately as **3 additional approved first-launch intro screens**.

## Visual references

| Page | Source file | Pixels |
| --- | --- | --- |
| 1 | `…/SpeedyGo_Driver__Receive_Delivery_Offers-1-….jpg` | 473×1024 |
| 2 | `…/SpeedyGo_delivery_journey_onboarding-2-….jpg` | 472×1024 |
| 3 | `…/Track_earnings_with_SpeedyGo-3-….jpg` | 472×1024 |

Preserved unchanged under `docs/evidence/first_launch_intro_v1_2026-10-10/references/`.

## Asset strategy

- Full-screen references kept as non-interactive archives.
- Illustration regions cropped (header logo / titles / CTA excluded) into:
  - `assets/images/first_launch_intro/intro_{1,2,3}_illustration.png`
- Official logo: `assets/branding/speedygo_logo.png`
- All chrome rebuilt natively (SafeArea, Skip, titles, bodies, dots, buttons, PageView).

Limitation: crops are from flattened marketing comps; residual header logo pixels were covered with white. Soft white fade at illustration bottom blends into native copy.

## Routing

```
Native Launch → Splash
  → restore locale + intro flag + session
  → if !driver_first_launch_intro_v1_completed → /welcome-intro
  → else → existing resolveAfterSession() → destination
```

After Skip / Commencer:

1. Persist completion locally  
2. `resolveAfterSession()`  
3. `context.go(destination)` (replace; no hardcoded `/home`)

Gate also blocks protected routes until completion (`driverRedirect(introCompleted: false)`).

## Persistence

| Item | Value |
| --- | --- |
| Key | `driver_first_launch_intro_v1_completed` |
| Storage | `FlutterSecureStorage` via `FirstLaunchIntroStore` |
| Set on | Skip or Commencer only |
| Not cleared by | logout, session expiry, language change |
| Cleared by | reinstall / clear app data / test `resetForTests()` |

## Strings (ARB + AppStrings)

| Key | FR | AR |
| --- | --- | --- |
| Skip | Passer | تخطي |
| Next | Suivant | التالي |
| Start | Commencer | ابدأ |
| P1 title | Recevez des courses | استلم طلبات التوصيل |
| P1 body | Passez en ligne… | فعّل وضع الاتصال… |
| P2 title | Livrez en toute simplicité | وصّل بكل سهولة |
| P2 body | Suivez chaque étape… | تابع كل مرحلة… |
| P3 title | Gardez le contrôle de vos gains | تحكّم في أرباحك |
| P3 body | Consultez vos livraisons… | راجع عمليات التوصيل… |

ARB: `lib/l10n/app_fr.arb`, `lib/l10n/app_ar.arb`  
Runtime UI uses `AppStrings` (existing Driver pattern) bound to locale.

## Tests

- `test/first_launch_intro_test.dart` — gate, pages, skip, commence, relaunch, RTL, scale, back, logout
- `test/first_launch_intro_evidence_test.dart` — mocked widget screenshots
- Existing shell/widget tests override intro completed = true

## Validation

- `dart format`: clean  
- `flutter analyze`: 2 pre-existing info only  
- `flutter test`: **188+** (164 baseline + intro suite + evidence captures)

## Live simulator (iPhone 16e)

Evidence: `docs/evidence/first_launch_intro_v1_2026-10-10/live/`

| Scenario | Class |
| --- | --- |
| FR pages 1–3 | `live_driver_ui_verified` |
| FR Commencer → phone | `live_driver_ui_verified` |
| FR relaunch skips intro | `live_driver_ui_verified` |
| FR Skip → phone | `live_driver_ui_verified` |
| AR pages 1–3 | `live_driver_ui_verified` |

Not claimed: authenticated API, COD, offers, release readiness.

## Visual differences vs references

- Native controls (not raster buttons).
- Official logo asset instead of screenshot logo.
- Illustration crops may slightly trim sky/edges vs full comps.
- Page 3 has no Skip (matches reference).
- No invented balances on earnings slide.

## Git

No commit / push performed for this implementation task.
