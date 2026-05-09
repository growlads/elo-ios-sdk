# EloAdsMediationAdMob

AdMob mediation adapter for the Elo iOS SDK. Wraps `GoogleMobileAds`
13.x and exposes it through Elo's `AdNetworkAdapter` contract. Ships
on the SDK's release cadence — there is no separate adapter version.

## Integration

```swift
import EloAds
import EloAdsMediationAdMob

Elo.configure(
    with: EloConfiguration(
        elo: EloNetworkConfiguration(
            publisherId: "YOUR_PUBLISHER_ID",
            adUnitId: "YOUR_AD_UNIT_ID"
        ),
        adapters: [
            AdMobNetworkAdapter(adUnitId: "ca-app-pub-…/…"),
        ]
    )
)
```

## Resources

This adapter ships an `AdMobSKAdNetworkItems.plist` with the AdMob
SKAdNetwork IDs. Merge into your app's `Info.plist` `SKAdNetworkItems`
key. See [Resources/UPDATING.md](Resources/UPDATING.md) for refresh
instructions when AdMob publishes new IDs.

## Consent forwarding

`AdMobConsent` derives the AdMob `npa` (non-personalized ads) parameter
from the per-request `AdConsent`. No global CMP state is read.
