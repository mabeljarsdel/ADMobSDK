//
//  AdvertManager.swift
//  Base
//
//  Created by Base on 10/08/2023.
//

import AdmobSDK
import GoogleMobileAds
import UIKit

public protocol AdConfigId {
    
    var name: String { get }
    
    var adType: AdType { get }
    
    var adId: String { get }
    
    var isEnableAd: Bool { get }
    
}

extension AdConfigId {
    
    
    var adUnitId: AdUnitID {
        return AdUnitID(rawValue: adId)
    }
    
    var isEnableAd: Bool {
        return (RemoteConfigManager.shared.getValue(by: name)?.boolValue ?? false)
        && !Constants.isUserVip
    }
    
}

public enum AdType: String {
    case OpenApp = "App Open"
    case Banner = "Banner"
    case Reward = "Reward"
    case Interstitial = "Interstitial"
    case Native = "Native"
}

public enum AdNativeSize: Int {
    case normal = 0
    case small = 1
}

public class ADManager: NSObject {
    
    public static let shared = ADManager()
    
    internal var isShowingAd = false // Cờ để check xem đang show quảng cáo hay không. Chỉ cho phép show 1 loại quảng cáo/1 thời điểm
    
    internal var timeShowOpen: Int = 0
    internal var timeShowFull: Int = 0
    internal var timeShowReward: Int = 0
    
    internal var showState: AdShowState?
    internal var configTime: AdConfigTime?
    internal var loadableAd = true
    
    override init() {
        super.init()
        self.showState = AdShowState(version: Bundle.main.releaseVersionNumber,
                                     isShowBanner: false,
                                     isShowOpen: false,
                                     isShowFull: false,
                                     isShowNative: false,
                                     isTestMode: false)
        timeShowOpen = 0
    }
    
    func startAds(style: ThemeStyleAds = ThemeStyleAds.origin,
                  testIds: [String] = []) {
        if !testIds.isEmpty {
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = testIds
        }
        GADMobileAds.sharedInstance().start()
        AdMobManager.shared.adsNativeColor = style
    }
    
    func disableAds() {
        self.showState = AdShowState(version: Bundle.main.releaseVersionNumber,
                                     isShowBanner: false,
                                     isShowOpen: false,
                                     isShowFull: false,
                                     isShowNative: false,
                                     isTestMode: false)
    }
    
    func initialize(readConfig enable: Bool,
                    completion: @escaping ((_ success: Bool) -> Void)) {
        
        SSLogging.d("ADMANAGER: \(enable)")
        
        if !enable {
            self.loadDefaults()
        } else {
            self.initialAdverts()
        }
        completion(true)
    }
    
}
