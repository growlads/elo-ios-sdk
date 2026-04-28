# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The **public, consumer-facing distribution** of the Growl iOS SDK — what app developers SPM-fetch from `https://github.com/growlads/growl-ios-sdk`. This repo is **not** where the SDK is developed.

Source-of-truth lives in a sibling repo: `elo-ios-sdk-source` (privately at `growlads/GrowlIosSdk`). Bugs are fixed there; releases are published from there into this repo by an automated workflow.

If a teammate is reading this repo: assume their question is either an integration question (answer from `README.md` and `Example/`) or a release-mechanics question (answer by pointing at the source repo's `scripts/build-xcframework.sh` and `.github/workflows/publish-ios-sdk.yml`).

## Do not edit by hand

Two things in this repo are produced by the upstream publish workflow and will be **clobbered on the next release**:

1. **`Package.swift`** — generated. The header comment in the file itself says so. The `binaryTarget` URL and `checksum:` are computed during the XCFramework build (see `scripts/build-xcframework.sh` upstream). Editing the checksum without editing the bytes it references will break SPM resolution for every consumer. Editing the URL without re-uploading the matching artifact does the same.
2. **`Sources/GrowlAdsMediationAdMob/`** — rsynced from upstream `Sources/GrowlAdsMediationAdMob/` during publishing. Any edits here are lost on the next release.

When you'd be tempted to edit either of those, edit upstream and re-publish instead. If a hotfix in this repo is ever genuinely needed (e.g. an emergency revert outside the publish window), it must be paired with a same-day upstream patch so the next normal release doesn't silently roll the fix back.

Things that **can** be edited directly here:

- `README.md` — consumer integration docs. The README upstream is dev-facing and different; keep this one focused on installation, Quick Start, and AdMob mediation wiring.
- `LICENSE`
- `Example/` — the runnable integration smoke test (see below). Useful to update when adding a new public API surface so users have a working reference.
- `CLAUDE.md` (this file)
- `.gitignore`

## What's in `Package.swift`

Two products, one external dependency:

- `GrowlAds` — `binaryTarget` pointing at a GitHub Releases asset (`GrowlAds.xcframework.zip`). This is the SDK. There is no SDK Swift source in this repo to read; if you need to look at the implementation, open it in the source repo.
- `GrowlAdsMediationAdMob` — opt-in source target for AdMob mediation. Ships as source because its `GoogleMobileAds` transitive dep can't be vendored into an XCFramework.
- Single SPM dependency: `swift-package-manager-google-mobile-ads` (only pulled when consumers depend on the AdMob product).

Min platform is `iOS 16` (load-bearing — see the source repo for why).

## Build & test

There is no test target in this repo. The integration is verified by running the example app:

```sh
cd Example
open GrowlAdsExample.xcodeproj
# Run on iPhone simulator. Tap "Load ad".
```

Replace the placeholder publisher/ad-unit IDs in `Example/Sources/GrowlAdsExampleApp.swift` with real values from the Growl dashboard before expecting real fills (test ad units fill freely).

If you need to validate that a freshly published version actually resolves cleanly, do it from a throwaway consumer project, not from this repo's own `Package.resolved`.

## Release pipeline (pointer)

The full release flow lives in the source repo. From this repo's perspective, releases arrive as:

- A new tag matching the version in `Package.swift` (currently `0.0.7`).
- A GitHub Release with `GrowlAds.xcframework.zip` and dSYMs attached.
- A commit updating `Package.swift` (binaryTarget URL + checksum) and `Sources/GrowlAdsMediationAdMob/`.

If those three are out of sync — e.g. `Package.swift` references a version that doesn't have a release artifact yet — the publish workflow either failed mid-flight or someone edited `Package.swift` by hand. Don't try to "fix forward" here; check upstream.

dSYMs for crash symbolication come from each release's GitHub assets. README points consumers there.

## House Rules

> _TODO (Gökhan): Fill this section with 5–10 lines of repo-specific rules I can't infer. Strong candidates:_
>
> - _Hotfix policy — is direct editing of `Sources/GrowlAdsMediationAdMob/` here ever acceptable, and if so, what's the upstream-sync requirement?_
> - _README divergence — what kinds of changes belong in this README vs. the source repo's README?_
> - _Branch discipline — does this repo only ever receive commits from the publish workflow, or are manual `main` commits expected for non-generated files?_
> - _Anything you've had to correct me on more than once._
>
> _Delete this blockquote once filled in._
