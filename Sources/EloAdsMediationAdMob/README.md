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
            // From the Elo dashboard — identifies your Elo demand integration.
            publisherId: "YOUR_ELO_PUBLISHER_ID",
            adUnitId: "YOUR_ELO_AD_UNIT_ID"
        ),
        adapters: [
            // From the AdMob console — identifies the AdMob ad unit you want
            // bidding into the auction. Distinct from the Elo adUnitId above.
            AdMobNetworkAdapter(adUnitId: "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYYYY"),
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
from the per-request `AdConsent`, and additionally inspects
`IABTCF_PurposeConsents` in `UserDefaults.standard` (the IAB TCF v2
storage key your CMP writes) to honour withdrawn purpose-1/3/4
consent. If you don't use a TCF-compliant CMP, only the per-request
`AdConsent` value is consulted.
