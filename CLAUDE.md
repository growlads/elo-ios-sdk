# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The **public, consumer-facing distribution** of the Growl iOS SDK — what app developers SPM-fetch from `https://github.com/growlads/elo-ios-sdk`. This repo is **not** where the SDK is developed.

Source-of-truth lives in a separate, private source repository. Bugs are fixed there; releases are published from there into this repo by an automated workflow.

If a teammate is reading this repo: assume their question is either an integration question (answer from `README.md` and `Example/`) or a release-mechanics question (release mechanics live in the source repo and are not visible here).

## Do not edit by hand

`Package.swift` in this repo is produced by the upstream publish workflow and will be **clobbered on the next release**. The header comment in the file itself says so. The `binaryTarget` URL and `checksum:` are computed during the XCFramework build in the source repo. Editing the checksum without editing the bytes it references will break SPM resolution for every consumer. Editing the URL without re-uploading the matching artifact does the same.

When you'd be tempted to edit it, edit upstream and re-publish instead. If a hotfix in this repo is ever genuinely needed (e.g. an emergency revert outside the publish window), it must be paired with a same-day upstream patch so the next normal release doesn't silently roll the fix back.

Things that **can** be edited directly here:

- `README.md` — consumer integration docs. The README upstream is dev-facing and different; keep this one focused on installation, Quick Start, and AdMob mediation wiring.
- `LICENSE`, `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md`
- `Example/` — the runnable integration smoke test (see below). Useful to update when adding a new public API surface so users have a working reference.
- `CLAUDE.md` (this file)
- `.gitignore`, `.github/`

## What's in `Package.swift`

One product, no external dependencies:

- `GrowlAds` — `binaryTarget` pointing at a GitHub Releases asset (`GrowlAds.xcframework.zip`). This is the SDK. There is no SDK Swift source in this repo to read; the implementation lives in the source repo.

Mediation adapters (e.g. AdMob) ship from the separate `growlads/elo-ios-mediation` package and are not bundled here.

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

- A new tag matching the version embedded in `Package.swift`'s `binaryTarget` URL (currently `0.0.1`).
- A GitHub Release with `GrowlAds.xcframework.zip` and dSYMs attached.
- A commit updating `Package.swift` (binaryTarget URL + checksum).

If those three are out of sync — e.g. `Package.swift` references a version that doesn't have a release artifact yet — the publish workflow either failed mid-flight or someone edited `Package.swift` by hand. Don't try to "fix forward" here; check upstream.

dSYMs for crash symbolication come from each release's GitHub assets. README points consumers there.

## Observed conventions

Inferred from the code, README content, and the source-repo's publish pipeline. Not yet confirmed by the team — correct any that are wrong.

- **Default hotfix policy: don't.** Because the publish workflow regenerates `Package.swift` on every release, any direct fix in this repo will be silently rolled back the next time a version is published from upstream. Patch upstream and re-publish; never hotfix here unless an emergency forces it, in which case pair the fix with an immediate same-day upstream patch so the next normal release doesn't undo it.
- **README divergence is intentional.** The source-repo's `README.md` is dev-facing (build/test/release flow). This repo's `README.md` is consumer-facing (install/integrate/AdMob wiring). They are not synced and should not be — changes belong wherever the audience cares.
- **Version coupling is total.** The `Package.swift` declared version, the `binaryTarget` URL's version path segment, the `CFBundleShortVersionString` baked into the XCFramework, the `sdkVersion` constant inside the binary, and the GitHub Release tag must all match. The publish script enforces this; manual edits anywhere risk drift that breaks `swift package resolve` for every consumer.
- **Manual `main` commits.** Outside the publish workflow, only the editable paths listed in "Do not edit by hand" should land here directly. Anything else implies the publish workflow either failed mid-flight or is being bypassed — investigate before "fixing forward."
- **`Example/` placeholder IDs.** `Example/Sources/GrowlAdsExampleApp.swift` ships with placeholder publisher/ad-unit IDs. Real IDs go in via consumer-local edits and should not be committed to this public repo.
