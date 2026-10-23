# Driver First-Launch Intro Preservation Report

Date: 2026-10-10  
Branch: `feat/driver-first-launch-intro-v1`

## Relationship to prior preservation

Lifecycle + navigation work was already preserved and pushed as:

- Branch: `feat/driver-lifecycle-navigation-verified-v1`
- Tip SHA: `c46440ae5eef53f427a5264b34343ff1a39fb57d`

This branch starts from that tip and adds the verified first-launch intro + splash brand-hold fix. It does **not** rewrite the lifecycle branch.

## Starting baseline

| Item | Value |
| --- | --- |
| Starting branch | `feat/driver-first-launch-intro-v1` |
| Starting HEAD | `c46440ae5eef53f427a5264b34343ff1a39fb57d` |
| Parent preservation | `origin/feat/driver-lifecycle-navigation-verified-v1` @ same SHA |

## What this push contains

1. First-launch intro (`/welcome-intro`) with FR/AR, persistence, resolver gate
2. Splash brand hold fix (router no longer yanks splash; hold 2.5s)
3. Tests, live simulator evidence, navigation doc updates

## Exclusions

Runtime logs under prior evidence dirs (`analyze.txt`, `disk_*.txt`, `flutter_test.txt`, `*.err`, `*.log`) remain untracked.

## Not release ready

This is preservation of verified work, not a release declaration.
