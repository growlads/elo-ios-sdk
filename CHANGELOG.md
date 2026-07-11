# Changelog

## Unreleased

## 0.1.7 — 2026-07-11

- **`Elo.initialize` is deprecated** and will be removed in 1.0.
  `Elo.configure` is now the single entry point, in two forms:
  - `Elo.configure(publisherId:adUnitId:shareGeoLocation:geoLocationPrecision:)` —
    new convenience for Elo-only integrations; the geo controls keep the
    on-by-default sharing opt-out visible at the simplest entry point.
  - `Elo.configure(with: EloConfiguration)` — unchanged; mediation
    adapters, COPPA/TFUA, `logLevel`, and `baseUrl` live here.
  Migrating from `initialize` is a rename for most apps; if you passed
  `coppa:`/`tfua:`, move them onto `EloConfiguration`.
- `EloError.notConfigured`'s description now points at `Elo.configure(with:)`.
- **Breaking: `EloAdLayout.heroCard` is removed.** Elo-direct creatives never
  had a dedicated hero treatment (it silently fell back to
  `.compactHorizontal`), and the AdMob hero card was the only layout that
  drew a CTA button. Switch statements over `EloAdLayout` and
  `.eloAdLayout(.heroCard)` call sites need updating; renderer-backed fills
  now always use the compact card treatment, so no bundled adapter draws a
  CTA button anymore.
- The dist-repo example app is now generated from this repo's sources and
  compile-checked against the SDK on every release, so it can no longer drift
  from the published API.



## 0.1.6 — 2026-07-11

- **Behavior change for upgraders:** passive geo sharing is now **on by
  default** and configurable directly from `Elo.initialize(...)` via
  `shareGeoLocation` / `geoLocationPrecision`. Apps whose users already
  granted location permission start attaching a rounded, coarse location to
  ad requests after upgrading. The SDK still never requests location
  permission; it only reads an already-authorized location. Opt out with
  `shareGeoLocation: false` at init or `Elo.setShareGeoLocation(false)`.
  See `PRIVACY.md` before shipping.
- New `.inlineBanner` layout: a two-line strip (thumbnail, "Title · Ad"
  attribution, one-line description, chevron) for persistent slots anchored
  to the composer or keyboard.
- New `.eloKeyboardBannerAd(messages:)` view modifier that pins the inline banner
  above the keyboard with a single line — no keyboard tracking or layout
  code in the host app. The slot collapses on no-fill and keeps the current
  ad on screen while a reload is in flight.
- Elo-rendered creatives drop the CTA pill: the whole card is tappable and a
  trailing chevron signals it. `callToActionLabel` now only affects
  renderer-backed fills that draw their own CTA button.
- The inline banner's outer margins are excluded from the tap target so the
  gap next to a composer cannot register accidental ad clicks.
- Send permission-free `device.geo.country` (locale region mapped to
  alpha-3, App Store storefront fallback) and `device.geo.utcoffset` on
  every ad request. Both reflect account/settings, not physical location.
- Fixed: renderer-backed ads size to their intrinsic height again after a
  sizing regression left dead space around some creatives.
- Fixed: preloaded creatives are released on `shutdown` and reconfigure so
  mediation resources (e.g. AdMob `NativeAd` handles) no longer leak.
- Fixed: a request-owning `EloAdView` whose slot collapsed after a no-fill
  could never reload when `messages` changed.
- Docs: new host-app privacy guide (`PRIVACY.md`) with App Store
  nutrition-label and consent guidance, README privacy warnings,
  `MessageRole` mapping guidance for human-to-human chats, and an accuracy
  pass across the SDK docs.



## 0.1.5 — 2026-06-30

- Repair the public SwiftPM release path after the `0.1.3` and `0.1.4`
  binary assets drifted from the checksums recorded in their package
  manifests.
- Harden release publishing so existing GitHub release assets are treated as
  immutable and verified by downloading them after release creation.
- Update installation snippets to the current public release version and point
  iOS documentation links at the canonical `docs.elo.ad` site.



## 0.1.4 — 2026-06-27

EloAds iOS SDK 0.1.4. See the source-repo for full changelog.

## 0.1.3 — 2026-05-31

- Ship `EloAdsMediationAdMob` as a binary XCFramework alongside `EloAds`.
- Add a linker dependency target so AdMob consumers receive the Google Mobile Ads dependencies through SwiftPM.
- Keep release tags pointed at the generated SwiftPM package commit.

## 0.1.2 — 2026-05-24

Move native ad presentation control to `EloAdView` so Elo-direct and
AdMob-rendered cards share the same SwiftUI styling path. This release also
includes the configuration and AdMob documentation updates that were prepared
for the superseded `0.1.1` package update.

- Added view-level `EloAdLayout`, `.eloAdLayout(...)`, and renderer configuration propagation.
- Removed AdMob adapter initializer presentation knobs; `AdMobNetworkAdapter` now only handles network configuration.
- Deprecated `AdMobNativeStyle` and `AdMobNativeLayout` in favor of `EloAdStyle` and `EloAdLayout`.
- Rebuilt renderer-backed native views when layout/style/label configuration changes on an already-mounted `EloAdView`.
- Simplified `EloConfiguration` around publisher/ad-unit identity, privacy
  flags, log level, and optional mediation adapters.
- Replaced legacy ad view variants with the single SwiftUI `EloAdView` surface.
- Added AdMob `expectedEcpm` bidding, compact native layout updates, and
  no-CTA rendering.
- Standardized impression tracking at 50% visible for 1 second.
- Updated README snippets for the `0.1.2` package and current AdMob API.

## 0.1.0 — 2026-05-09

Rebrand from Growl to Elo across the SDK surface so iOS naming matches the Android SDK (`ad.elo.androidsdk`). No behavior change.

- Swift module `GrowlAds` → `EloAds`; mediation adapter target `GrowlAdsMediationAdMob` → `EloAdsMediationAdMob`.
- Public namespace `Growl` → `Elo`; all `GrowlFoo` types → `EloFoo` (`EloAd`, `EloAdView`, `EloAdDelegate`, `EloConfiguration`, `EloChatSession`, `EloState`, `EloError`, `EloAdStyle`, etc.).
- Lowercase: `Configuration.growl` → `.elo`; delegate callbacks `growlAdDid*` → `eloAdDid*`; `.growlAdStyle` modifier → `.eloAdStyle`; default network ID `"growl"` → `"elo"`.
- XCFramework artifact `GrowlAds.xcframework.zip` → `EloAds.xcframework.zip`.
- **Breaking change:** existing 0.0.x consumers must migrate symbol names; there is no shim. Per the project's pre-1.0 contract, breaking changes are expected on minor bumps.

## 0.0.1 — 2026-04-15

Initial public release. SDK distributed as an XCFramework via Swift Package Manager.

- `Elo` entry point: `configure`, `loadAd`, `preloadAd`, `setDelegate`, `mediationDebugSnapshot`, `enable`/`disable`, `shutdown`.
- SwiftUI ad views: `EloAdView`, `EloBadgeAdView`, `EloChatAdView` with automatic render/impression/click tracking (impression fires after ≥50% visible for 1s).
- Manual tracking hooks: `Elo.trackRender`, `Elo.trackImpression`, `Elo.trackClick`.
- Optional AdMob mediation via the `EloAdsMediationAdMob` product (source target).
- Minimum deployment target: iOS 16.
