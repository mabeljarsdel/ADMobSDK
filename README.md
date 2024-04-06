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

Pod automatically updates latest version
```
pod 'AdmobSDK', :git => "https://github.com/Binary-Bridge-Labs/ADMobSDK"
```

Pod from special branch
```
pod 'AdmobSDK', :git => "https://github.com/Binary-Bridge-Labs/ADMobSDK", :branch => 'dev'
```

Pod from special tag
```
pod 'AdmobSDK', :git => "https://github.com/Binary-Bridge-Labs/ADMobSDK", :tag => 'x.y.z'
```

Pod from special commit
```
pod 'AdmobSDK', :git => "https://github.com/Binary-Bridge-Labs/ADMobSDK", :commit => 'xxx'
```

Then, run the following command:

```bash
$ pod install
```

## Usage

### Quick Start

Id ads Test:
Refernce: https://developers.google.com/admob/ios/test-ads

```swift
public struct SampleAdUnitID {
    public static let adFormatAppOpen              = ""
    public static let adFormatBanner               = ""
    public static let adFormatInterstitial         = ""
    public static let adFormatInterstitialVideo    = ""
    public static let adFormatRewarded             = ""
    public static let adFormatRewardedInterstitial = ""
    public static let adFormatNativeAdvanced       = ""
    public static let adFormatNativeAdvancedVideo  = ""
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
