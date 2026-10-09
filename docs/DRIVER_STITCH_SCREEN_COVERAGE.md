# Driver Stitch screen coverage matrix

Date: 2026-10-09  
Driver branch: `feat/driver-stitch-full-ui-v1`  
Protected Offers baseline HEAD: `be7cedd`  
Backend (read-only): `feat/driver-assignment-version-contract` @ `3131c4ec`  
ZIP: `screens/DriverScreens/stitch_speedygo_driver_mobile_app.zip` (outside Driver git repo)

Evidence status for this batch: **IMPLEMENTED — STATIC/UNIT/WIDGET/MOCKED UI VERIFIED**

## Inventory

| Metric | Count |
| --- | ---: |
| Screen folders | 47 |
| `code.html` | 47 |
| Named `screen.png` | 47 |
| Valid PNG images | 13 |
| Invalid PNG exports (HTML/text) | 34 |
| `vitesse_system/DESIGN.md` | present |

## Decision summary (primary classification)

Primary classifications are mutually exclusive and sum to **47**.

| Decision | Count |
| --- | ---: |
| `implemented` | 28 |
| `merged_state` | 5 |
| `already_implemented_and_preserved` | 8 |
| `blocked_contract` | 5 |
| `deferred_provider` | 0 |
| `not_applicable_duplicate` | 1 |
| `unreviewed` | 0 |
| Total | 47 |

`deferred_provider = 0` means no folder’s *primary* decision is “provider-only deferred.”  
Maps, native push, and call-proxy remain **deferred dependencies** on some rows (see below and JSON `provider_dependencies`).

### Deferred-provider dependencies (secondary field)

| Provider | Rows with `deferred` | Notes |
| --- | ---: | --- |
| `maps_provider` | 5 | Honest nav card; no Maps SDK |
| `native_push_provider` | 2 | In-app inbox only; FCM/APNs deferred |
| `call_proxy_provider` | 2 | Same folders as contact `blocked_contract` |
| Distinct folders with any deferred provider dep | **9** | Primary classification unchanged |

## Exact five `blocked_contract` rows

These are the only primary `blocked_contract` classifications (not document-picker):

| # | Source folder | Missing contract |
| --- | --- | --- |
| 1 | `contact_marchand` | No merchant call-proxy / masked-number API |
| 2 | `contact_client` | No customer call-proxy / masked-number API |
| 3 | `validation_du_code_de_livraison` | No Driver customer-delivery-proof/PIN API (complete-delivery is proofless MVP) |
| 4 | `signalement_de_probl_me_de_livraison` | No Driver delivery issue-report endpoint |
| 5 | `chec_de_livraison` | No Driver delivery-failure endpoint |

**Not** a sixth blocked primary row: document camera/file picker (`UnavailableDocumentSource`) is a client dependency on **implemented** onboarding/document uploads, not a missing backend table/route for a whole Stitch folder.

## Design conflicts resolved

| Conflict | Resolution |
| --- | --- |
| 9 home variants | One `/home` with ONLINE/OFFLINE/offer/location states |
| Hamburger drawer | Not shipped; `DriverShell` AppBar + 4-tab NavigationBar |
| Offer countdown `00:45` | Visual sample only; UI uses server `expiresAt` |
| Map mockups | Provider-neutral honest nav card; Maps deferred |
| Customer delivery PIN | `blocked_contract`; complete-delivery remains proofless per backend |
| Theme teal vs Stitch blue | AppTheme seed → DriverTokens primary `#0A4096` |
| Profile / logout | Profile tab and shell avatar open Profile; logout is a deliberate confirmed action on Profile/Settings — not automatic on tab select |

## Profile and logout (clarified)

- `nav_profile` and `shell_profile_button` → Profile screen (`goBranch(3)`).
- Logout button on Profile (and Settings) opens a confirmation sheet.
- Cancel keeps `SessionStatus.signedIn`.
- Confirm calls session logout; `driverRedirect` then sends unauthenticated users to phone auth.
- Selecting Profile never logs the user out by itself.

## Delivery policy (clarified)

Backend (`3131c4ec`) order:

1. `start-to-pickup` → `TO_PICKUP`
2. `arrive-pickup` (+ fresh location / proximity)
3. `AT_PICKUP` / prep wait (refresh current delivery; no fake local timer)
4. `confirm-pickup` (coded or legacy) — preserved
5. `start-delivery` → `IN_TRANSIT`
6. `arrive-customer` (+ location)
7. `collect-cod` when payment is COD (exact `collectedAmountMinor`)
8. Customer delivery proof — **not in contract** (proofless MVP)
9. `complete-delivery` — server enforces COD collection when COD; ELECTRONIC requires SUCCEEDED payment; no DeliveryProof

Flutter shows complete when `allowedActions` contains `complete-delivery`. COD completion failures surface `DRIVER_DELIVERY_COD_COMPLETION_NOT_READY`. Customer PIN UI is blocked, not faked.

## Mocked widget evidence mapping

Directory: `docs/evidence/stitch_full_ui_2026-10-09/{fr,ar}/` — kind **`mocked_widget_ui`** (not live).

| Capture | Covers (source folders / states) |
| --- | --- |
| `01_phone` | `connexion_chauffeur_t_l_phone` |
| `02_otp` | `v_rification_otp_chauffeur` |
| `03_home_online` | Online home variants + shell chrome + splash routing context |
| `04_home_offline` | Offline home variants + offer privacy detail state |
| `05_delivery_to_pickup` | `navigation_vers_le_marchand` |
| `06_delivery_at_pickup` | arrive / prep / pickup handoff |
| `07_delivery_arrived_customer` | customer leg + COD card |
| `08_delivery_delivered` | `livraison_termin_e` |
| `09_history` | history list (+ detail shares list empty hub) |
| `10_earnings` | earnings + COD custody section |
| `11_profile` | profile hub; onboarding/settings/docs/ratings share this shell destination |
| `12_notifications` | inbox |
| `13_support` | support list (+ detail) |
| `14_blocked_contact` | merchant + customer contact blocked |
| `15_blocked_delivery_pin` | customer PIN blocked |
| `16_blocked_failure` | issue report + failure blocked |

## Full matrix

Machine-readable source of truth: `DRIVER_STITCH_SCREEN_COVERAGE.json` (47 objects, unique `source_folder`).

Human table (same 47 folders) was generated with the Stitch inventory; regenerate counts via:

```bash
python3 -c "import json;d=json.load(open('docs/DRIVER_STITCH_SCREEN_COVERAGE.json'));print(d['summary'], d['summary_total'], d['unreviewed'])"
```

| # | Source folder | Decision |
| --- | --- | --- |
| 1 | `splash_and_session_routing` | `already_implemented_and_preserved` |
| 2 | `connexion_chauffeur_t_l_phone` | `already_implemented_and_preserved` |
| 3 | `v_rification_otp_chauffeur` | `already_implemented_and_preserved` |
| 4 | `inscription_chauffeur` | `implemented` |
| 5 | `t_l_chargement_pi_ce_d_identit` | `implemented` |
| 6 | `t_l_chargement_permis_de_conduire` | `implemented` |
| 7 | `informations_du_v_hicule_2` | `implemented` |
| 8 | `informations_du_v_hicule_1` | `implemented` |
| 9 | `mes_documents_chauffeur` | `implemented` |
| 10 | `r_vision_de_la_v_rification` | `implemented` |
| 11 | `v_rification_en_attente` | `implemented` |
| 12 | `soumission_des_corrections_optimis_e` | `implemented` |
| 13 | `v_rification_approuv_e` | `implemented` |
| 14 | `accueil_en_ligne_fonctionnel` | `already_implemented_and_preserved` |
| 15 | `accueil_en_ligne_perfect_sync` | `merged_state` |
| 16 | `accueil_en_ligne_support_statut_pur` | `merged_state` |
| 17 | `accueil_en_ligne_menu_hamburger_top_bar_bleue` | `merged_state` |
| 18 | `accueil_en_ligne_menu_hamburger_drawer_bleu` | `not_applicable_duplicate` |
| 19 | `accueil_hors_ligne_fonctionnel` | `already_implemented_and_preserved` |
| 20 | `accueil_hors_ligne_banni_re_demande` | `already_implemented_and_preserved` |
| 21 | `accueil_hors_ligne_support_statut_pur` | `merged_state` |
| 22 | `accueil_hors_ligne_menu_hamburger` | `merged_state` |
| 23 | `d_tails_de_la_course_00_45_privacy` | `already_implemented_and_preserved` |
| 24 | `navigation_vers_le_marchand` | `implemented` |
| 25 | `arriv_chez_le_marchand` | `implemented` |
| 26 | `en_attente_de_pr_paration` | `implemented` |
| 27 | `confirmation_du_retrait_pin_s_curis` | `already_implemented_and_preserved` |
| 28 | `contact_marchand` | `blocked_contract` |
| 29 | `navigation_vers_le_client` | `implemented` |
| 30 | `chauffeur_proximit` | `implemented` |
| 31 | `contact_client` | `blocked_contract` |
| 32 | `validation_du_code_de_livraison` | `blocked_contract` |
| 33 | `signalement_de_probl_me_de_livraison` | `blocked_contract` |
| 34 | `chec_de_livraison` | `blocked_contract` |
| 35 | `livraison_termin_e` | `implemented` |
| 36 | `historique_des_livraisons` | `implemented` |
| 37 | `d_tails_de_livraison_historique` | `implemented` |
| 38 | `gains_et_totaux_op_rationnels` | `implemented` |
| 39 | `r_conciliation_de_caisse` | `implemented` |
| 40 | `profil_du_chauffeur` | `implemented` |
| 41 | `param_tres_du_chauffeur` | `implemented` |
| 42 | `param_tres_de_langue_et_notifications` | `implemented` |
| 43 | `notifications_chauffeur_haute_demande` | `implemented` |
| 44 | `aide_support` | `implemented` |
| 45 | `support_ticket_detail` | `implemented` |
| 46 | `notes_et_commentaires_du_chauffeur` | `implemented` |
| 47 | `d_connexion_confirmation` | `implemented` |

## Test-count history (do not confuse)

| Checkpoint | Result | Role |
| --- | --- | --- |
| Offers V1 @ `be7cedd` | 63/63 PASS | Preserved baseline |
| Intermediate shell wiring | 104/104 PASS | Intermediate only (shell_navigation not yet loadable) |
| Stitch suite before coverage parser tests | 137/137 PASS | Intermediate within Stitch batch |
| Stitch full preservation | **142/142 PASS** | Authoritative for this commit (fresh `flutter test`) |
