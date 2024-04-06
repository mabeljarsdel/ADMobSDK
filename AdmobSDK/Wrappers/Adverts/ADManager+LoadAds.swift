//
//  ADManager+LoadAds.swift
//  AnimalTranslate-iOS
//
//  Created by Lê Minh Sơn on 23/08/2023.
//

import Foundation
import GoogleMobileAds
import UIKit

public enum AdvertResult: Int {
    case loaded = 0
    case showed = 1
    case closed = 2
    case success = 3
    case error = -1
}

extension UIApplicationDelegate {
    public func getRootViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return getRootViewController(base: nav.visibleViewController)
        } else if let tab = base as? UITabBarController,
                  let selected = tab.selectedViewController {
            return getRootViewController(base: selected)
        } else if let presented = base?.presentedViewController {
            return getRootViewController(base: presented)
        }
        return base
    }
}

// MARK: - Load and reload Ads
extension ADManager {
    
    fileprivate var isTestMode: Bool { // Setting cho chế độ testmode
        return showState?.isTestMode ?? false
    }
    
    fileprivate var isShowBanner: Bool {
        return (showState?.isShowBanner ?? false) && !IAPState.isUserVip
    }
    
    fileprivate var isShowFull: Bool {
        return (showState?.isShowFull ?? false) && !IAPState.isUserVip
    }
    
    fileprivate var isShowOpen: Bool {
        return (showState?.isShowOpen ?? false) && !IAPState.isUserVip
    }
    
    fileprivate var isShowNative: Bool {
        return (showState?.isShowNative ?? false) && !IAPState.isUserVip
    }
    
    fileprivate var isShowReward: Bool {
        return (showState?.isShowReward ?? false) && !IAPState.isUserVip
    }
    
    fileprivate var timeRemoteShowOpen: Int {
        return configTime?.timeShowOpen ?? 15
    }
    
    fileprivate var timeRemoteShowReward: Int {
        return configTime?.timeShowReward ?? 20
    }
    
    public var timeRemoteShowFull: Int {
        return configTime?.timeShowFull ?? 20
    }
    
    public var maxClickShowAd: Int {
        return configTime?.maxClickShowAd ?? 5
    }
    
}

extension ADManager {
    
    public func loadOpen(_ id: AdConfigId) {
        AdResumeManager.shared.appOpenAdManagerDelegate = nil
        var adId = id.adUnitId
        if isTestMode {
            adId = SampleAdUnitID.adFormatAppOpen
        }
        BBLLogging.d("ADMANAGER: OPEN \(adId.rawValue)")
        guard isShowOpen,
              id.isEnableAd else {
            BBLLogging.d("ADMANAGER: OPEN REMOTE CLOSE")
            return
        }
        AdResumeManager.shared.resumeAdId = adId
        if (Int(Date().timeIntervalSince1970) - timeShowOpen) <= timeRemoteShowOpen {
            BBLLogging.d("ADMANAGER: OPEN NOT MATCH TIME")
            return
        }
        
        if let controller = UIApplication.shared.delegate?.getRootViewController() {
            if AdResumeManager.shared.showAdIfAvailable(id: adId.rawValue, viewController: controller) {
                BBLLogging.d("ADMANAGER: OPEN SHOWING FOR AVAILABLE")
                self.timeShowOpen = Int(Date().timeIntervalSince1970)
            } else {
                BBLLogging.d("ADMANAGER: OPEN SHOWING FOR NOT AVAILABLE")
            }
        }
    }
    
    public func loadOpenAsync(_ id: AdConfigId, completion: @escaping ((_ showed: Bool) -> Void)) {
        let adId = id.adUnitId
        if isTestMode {
            // TODO: AppOpen Test not working show disable this ads for testmode
            // adId = SampleAdUnitID.adFormatAppOpen
            completion(false)
            return
        }
        BBLLogging.d("ADMANAGER: OPEN \(adId.rawValue)")
        guard isShowOpen,
              id.isEnableAd else {
            BBLLogging.d("ADMANAGER: OPEN REMOTE CLOSE")
            completion(false)
            return
        }
        if let controller = UIApplication.shared.delegate?.getRootViewController() {
            AdResumeManager.shared.appOpenAdManagerDelegate = completion
            AdResumeManager.shared.showOpenAd(adId: adId, viewController: controller)
        } else {
            completion(false)
        }
    }
    
    public func loadFull(_ id: AdConfigId, isSplash: Bool = true, _ completion: ((AdvertResult) -> Void)? = nil) {
        var adId = id.adUnitId
        if isTestMode {
            adId = SampleAdUnitID.adFormatInterstitialVideo
        }
        BBLLogging.d("ADMANAGER: FULL \(adId)")
        guard isShowFull,
              id.isEnableAd else {
            BBLLogging.d("ADMANAGER: FULL REMOTE CLOSE")
            completion?(.closed)
            return
        }
        if isShowingAd {
            BBLLogging.d("ADMANAGER: FULL HAS AD SHOWING")
            return
        }
        if (Int(Date().timeIntervalSince1970) - timeShowFull) <= timeRemoteShowFull {
            BBLLogging.d("ADMANAGER: FULL NOT MATCH TIME")
            completion?(.closed)
            return
        }
        self.timeShowFull = Int(Date().timeIntervalSince1970)
        self.isShowingAd = true
        BBLLogging.d("ADMANAGER: FULL Loading")
        AdMobManager.shared.showIntertitial(unitId: adId, isSplash: isSplash, blockDidDismiss: { [weak self] in
            BBLLogging.d("ADMANAGER: FULL Showed and closed")
            AdMobManager.shared.blockFullScreenAdFailed = nil
            self?.isShowingAd = false
            completion?(.closed)
            AdMobManager.shared.createAdInterstitialIfNeed(unitId: adId)
        })
    }
    
    public func loadReward(_ id: AdConfigId, _ completion: ((AdvertResult) -> Void)? = nil) {
        var adId = id.adUnitId
        if isTestMode {
            adId = SampleAdUnitID.adFormatRewarded
        }
        BBLLogging.d("ADMANAGER: REWARD \(adId)")
        guard isShowReward,
                id.isEnableAd else {
            BBLLogging.d("ADMANAGER: REWARD REMOTE CLOSE")
            completion?(.closed)
            return
        }
        if isShowingAd {
            BBLLogging.d("ADMANAGER: REWARD HAS AD SHOWING")
            return
        }
        if (Int(Date().timeIntervalSince1970) - timeShowReward) <= timeRemoteShowReward {
            BBLLogging.d("ADMANAGER: REWARD NOT MATCH TIME")
            completion?(.closed)
            return
        }
        self.timeShowReward = Int(Date().timeIntervalSince1970)
        self.isShowingAd = true
        BBLLogging.d("ADMANAGER: REWARD SHOWED started")
        AdMobManager.shared.showRewarded(unitId: adId) { [weak self] earned in
            BBLLogging.d("ADMANAGER: REWARD Completed \(earned)")
            if earned {
                self?.isShowingAd = false
                completion?(.closed)
            } else {
                self?.isShowingAd = false
                completion?(.error)
            }
        }
    }
    
    public func loadBanner(_ id: AdConfigId, viewBanner: UIView, completion: @escaping ((_ success: Bool) -> Void)) {
        var adId = id.adUnitId
        if isTestMode {
            adId = SampleAdUnitID.adFormatBanner
        }
        BBLLogging.d("ADMANAGER: BANNER  \(adId)")
        guard isShowBanner, 
                id.isEnableAd,
                let viewController = UIApplication.shared.delegate?.getRootViewController() else {
            completion(false)
            BBLLogging.d("ADMANAGER: BANNER REMOTE CLOSE")
            return
        }
        AdMobManager.shared.blockBannerFailed = { adId in
            BBLLogging.d("ADMANAGER: BANNER LOAD FAILED: \(adId)")
            completion(false)
        }
        AdMobManager.shared.blockLoadBannerSuccess = { success in
            BBLLogging.d("ADMANAGER: BANNER LOAD SUCCESS: \(adId)")
            completion(success)
        }
        AdMobManager.shared.blockBannerClick = { str in
            BBLLogging.d("ADMANAGER: BANNER CLICKED AND REFRESH: \(str)")
            self.loadBanner(id, viewBanner: viewBanner, completion: completion)
        }
        AdMobManager.shared.addAdBanner(unitId: adId, rootVC: viewController, view: viewBanner)
    }
    
    public func loadBannerAdaptive(_ id: AdConfigId, viewBanner: UIView, completion: @escaping ((_ success: Bool) -> Void)) {
        var adId = id.adUnitId
        if isTestMode {
            adId = SampleAdUnitID.adFormatBanner_2
        }
        BBLLogging.d("ADMANAGER: BANNER")
        guard isShowBanner,
              id.isEnableAd,
              let viewController = UIApplication.shared.delegate?.getRootViewController() else {
            completion(false)
            BBLLogging.d("ADMANAGER: BANNER REMOTE CLOSE")
            return
        }
        AdMobManager.shared.blockBannerFailed = { adId in
            BBLLogging.d("ADMANAGER: BANNER ADAPTIVE LOAD FAILED: \(adId)")
            completion(false)
        }
        AdMobManager.shared.blockLoadBannerSuccess = { success in
            BBLLogging.d("ADMANAGER: BANNER ADAPTIVE LOAD SUCCESS: \(adId)")
            completion(success)
        }
        AdMobManager.shared.blockBannerClick = { str in
            BBLLogging.d("ADMANAGER: BANNER ADAPTIVE CLICKED AND REFRESH: \(str)")
            self.loadBannerAdaptive(id, viewBanner: viewBanner, completion: completion)
        }
        AdMobManager.shared.addAdBannerAdaptive(unitId: adId, rootVC: viewController, view: viewBanner)
    }
    
    public func loadCollapsibleBannerAdaptive(_ id: AdConfigId,
                                       viewBanner: UIView,
                                       isCollapsible: Bool = false,
                                       completion: @escaping ((_ success: Bool) -> Void)) {
        var adId = id.adUnitId
        if isTestMode {
            adId = SampleAdUnitID.adFormatCollapsibleBanner
        }
        BBLLogging.d("ADMANAGER: BANNER")
        guard isShowBanner,
              id.isEnableAd,
              let viewController = UIApplication.shared.delegate?.getRootViewController() else {
            completion(false)
            BBLLogging.d("ADMANAGER: BANNER REMOTE CLOSE")
            return
        }
        AdMobManager.shared.blockBannerFailed = { adId in
            BBLLogging.d("ADMANAGER: BANNER COLLAPSIBLE ADAPTIVE LOAD FAILED: \(adId)")
            completion(false)
        }
        AdMobManager.shared.blockLoadBannerSuccess = { success in
            BBLLogging.d("ADMANAGER: BANNER COLLAPSIBLE ADAPTIVE LOAD SUCCESS: \(adId)")
            completion(success)
        }
        AdMobManager.shared.blockBannerClick = { str in
            BBLLogging.d("ADMANAGER: BANNER COLLAPSIBLE  ADAPTIVE CLICKED AND REFRESH: \(str)")
            self.loadCollapsibleBannerAdaptive(id, viewBanner: viewBanner, completion: completion)
        }
        AdMobManager.shared.addAdCollapsibleBannerAdaptive(unitId: adId, rootVC: viewController,
                                                           view: viewBanner, isCollapsibleBanner: isCollapsible)
    }
    
    public func loadNative(_ id: AdConfigId,
                    to view: UIView,
                    nativeAdType: NativeAdType = .smallMedia,
                    _ completion: @escaping ((_ success: Bool) -> Void)) {
        var adId = id.adUnitId
        if isTestMode {
            adId = SampleAdUnitID.adFormatNativeAdvancedVideo
        }
        guard isShowNative,
              id.isEnableAd,
                let viewController = UIApplication.shared.delegate?.getRootViewController() else {
            completion(false)
            return
        }
        AdMobManager.shared.blockNativeFailed = { adId in
            BBLLogging.d("ADMANAGER: NATIVE LOAD FAILED: \(adId)")
            completion(false)
        }
        AdMobManager.shared.blockLoadNativeSuccess = { adId in
            BBLLogging.d("ADMANAGER: NATIVE LOAD SUCCESS: \(adId)")
            completion(true)
        }
        AdMobManager.shared.addAdNative(unitId: adId, rootVC: viewController, views: [view],
                                        type: nativeAdType, ratio: .any)
    }
    
}
