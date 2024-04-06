<img src="" alt="" />

# AdmobSDK
AdmobSDK is a Swift framework, a simple Ads engine that supports the google professional extension SDK

## Requirements

- iOS 12.0+
- Xcode 12.0+
- Swift 4.0+

## Installation

### CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

To integrate AdmobSDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```
pod 'AdmobSDK', :path => "../../AdmobSDK"
```

Then, run the following command:

```bash
$ pod install
```

## Usage

### Quick Start

Id ads Test:

```swift
public struct SampleAdUnitID {
    public static let adFormatAppOpen              = "ca-app-pub-3940256099942544/3419835294"
    public static let adFormatBanner               = "ca-app-pub-3940256099942544/6300978111"
    public static let adFormatInterstitial         = "ca-app-pub-3940256099942544/1033173712"
    public static let adFormatInterstitialVideo    = "ca-app-pub-3940256099942544/8691691433"
    public static let adFormatRewarded             = "ca-app-pub-3940256099942544/5224354917"
    public static let adFormatRewardedInterstitial = "ca-app-pub-3940256099942544/5354046379"
    public static let adFormatNativeAdvanced       = "ca-app-pub-3940256099942544/2247696110"
    public static let adFormatNativeAdvancedVideo  = "ca-app-pub-3940256099942544/1044960115"
}
```

Ads banner:

```swift
AdMobManager.shared.addAdBanner(unitId: SampleAdUnitID.adFormatBanner, rootVC: self, view: viewAdsBanner)
```

Ads NAtive:

```swift
// type: medium - small - unified
AdMobManager.shared.addAdNative(unitId: SampleAdUnitID.adFormatNativeAdvanced, rootVC: self, view: viewAdsNative, type: .small)
```

Ads Rewarded:

```swift
// Create id ads:
AdMobManager.shared.createAdRewardedIfNeed(unitId: SampleAdUnitID.adFormatRewarded)
// and
AdMobManager.shared.showRewarded(unitId: SampleAdUnitID.adFormatRewarded, completion: nil)
```

Ads Interstitial:

```swift
// Create id ads:
AdMobManager.shared.createAdInterstitialIfNeed(unitId: SampleAdUnitID.adFormatInterstitial)
// and
AdMobManager.shared.showIntertitial(unitId: SampleAdUnitID.adFormatInterstitial, isSplash: false)
```

```swift
import AdmobSDK

class MyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
```
## License

AdmobSDK is released under the GNU GPLv2 license. See LICENSE for details.
