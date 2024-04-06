//
//  ADManager+LoadAds.swift
//  AnimalTranslate-iOS
//
//  Created by Lê Minh Sơn on 23/08/2023.
//

import AdmobSDK
import Foundation
import GoogleMobileAds
import UIKit

enum AdvertResult: Int {
    case loaded = 0
    case showed = 1
    case closed = 2
    case success = 3
    case error = -1
}

extension AppDelegate {
    func getRootViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
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
        return (showState?.isShowBanner ?? false) && !Constants.isUserVip
    }
    
    fileprivate var isShowFull: Bool {
        return (showState?.isShowFull ?? false) && !Constants.isUserVip
    }
    
    fileprivate var isShowOpen: Bool {
        return (showState?.isShowOpen ?? false) && !Constants.isUserVip
    }
    
    fileprivate var isShowNative: Bool {
        return (showState?.isShowNative ?? false) && !Constants.isUserVip
    }
    
    fileprivate var isShowReward: Bool {
        return (showState?.isShowReward ?? false) && !Constants.isUserVip
    }
    
    fileprivate var timeRemoteShowOpen: Int {
        return configTime?.timeShowOpen ?? 15
    }
    
    fileprivate var timeRemoteShowReward: Int {
        return configTime?.timeShowReward ?? 20
    }
    
    var timeRemoteShowFull: Int {
        return configTime?.timeShowFull ?? 20
    }
    
    var maxClickShowAd: Int {
        return configTime?.maxClickShowAd ?? 5
    }
    
}

extension ADManager {
    
    func loadOpen(_ id: AdUnitID) {
        AdResumeManager.shared.appOpenAdManagerDelegate = nil
        var adId = id
        if isTestMode {
            adId = SampleAdUnitID.adFormatAppOpen
        }
        SSLogging.d("ADMANAGER: OPEN \(adId.rawValue)")
        guard isShowOpen else {
            SSLogging.d("ADMANAGER: OPEN REMOTE CLOSE")
            return
        }
        AdResumeManager.shared.resumeAdId = adId
        if (Int(Date().timeIntervalSince1970) - timeShowOpen) <= timeRemoteShowOpen {
            SSLogging.d("ADMANAGER: OPEN NOT MATCH TIME")
            return
        }
        
        if let controller = appDelegate?.getRootViewController() {
            if AdResumeManager.shared.showAdIfAvailable(id: adId.rawValue, viewController: controller) {
                SSLogging.d("ADMANAGER: OPEN SHOWING FOR AVAILABLE")
                self.timeShowOpen = Int(Date().timeIntervalSince1970)
            } else {
                SSLogging.d("ADMANAGER: OPEN SHOWING FOR NOT AVAILABLE")
            }
        }
    }
    
    func loadOpenAsync(_ id: AdUnitID, completion: @escaping ((_ showed: Bool) -> Void)) {
        let adId = id
        if isTestMode {
            // TODO: AppOpen Test not working show disable this ads for testmode
            // adId = SampleAdUnitID.adFormatAppOpen
            completion(false)
            return
        }
        SSLogging.d("ADMANAGER: OPEN \(adId.rawValue)")
        guard isShowOpen else {
            SSLogging.d("ADMANAGER: OPEN REMOTE CLOSE")
            completion(false)
            return
        }
        if let controller = appDelegate?.getRootViewController() {
            AdResumeManager.shared.appOpenAdManagerDelegate = completion
            AdResumeManager.shared.showOpenAd(adId: id, viewController: controller)
        } else {
            completion(false)
        }
    }
    
    func loadFull(_ id: AdUnitID, isSplash: Bool = true, _ completion: ((AdvertResult) -> Void)? = nil) {
        var adId = id
        if isTestMode {
            adId = SampleAdUnitID.adFormatInterstitialVideo
        }
        SSLogging.d("ADMANAGER: FULL \(adId)")
        guard isShowFull else {
            SSLogging.d("ADMANAGER: FULL REMOTE CLOSE")
            completion?(.closed)
            return
        }
        if isShowingAd {
            SSLogging.d("ADMANAGER: FULL HAS AD SHOWING")
            return
        }
        if (Int(Date().timeIntervalSince1970) - timeShowFull) <= timeRemoteShowFull {
            SSLogging.d("ADMANAGER: FULL NOT MATCH TIME")
            completion?(.closed)
            return
        }
        self.timeShowFull = Int(Date().timeIntervalSince1970)
        self.isShowingAd = true
        SSLogging.d("ADMANAGER: FULL Loading")
        AdMobManager.shared.showIntertitial(unitId: adId, isSplash: isSplash, blockDidDismiss: { [weak self] in
            SSLogging.d("ADMANAGER: FULL Showed and closed")
            AdMobManager.shared.blockFullScreenAdFailed = nil
            self?.isShowingAd = false
            completion?(.closed)
            AdMobManager.shared.createAdInterstitialIfNeed(unitId: adId)
        })
    }
    
    func loadReward(_ id: AdUnitID, _ completion: ((AdvertResult) -> Void)? = nil) {
        var adId = id
        if isTestMode {
            adId = SampleAdUnitID.adFormatRewarded
        }
        SSLogging.d("ADMANAGER: REWARD \(adId)")
        guard isShowReward else {
            SSLogging.d("ADMANAGER: REWARD REMOTE CLOSE")
            completion?(.closed)
            return
        }
        if isShowingAd {
            SSLogging.d("ADMANAGER: REWARD HAS AD SHOWING")
            return
        }
        if (Int(Date().timeIntervalSince1970) - timeShowReward) <= timeRemoteShowReward {
            SSLogging.d("ADMANAGER: REWARD NOT MATCH TIME")
            completion?(.closed)
            return
        }
        self.timeShowReward = Int(Date().timeIntervalSince1970)
        self.isShowingAd = true
        SSLogging.d("ADMANAGER: REWARD SHOWED started")
        AdMobManager.shared.showRewarded(unitId: adId) { [weak self] earned in
            SSLogging.d("ADMANAGER: REWARD Completed \(earned)")
            if earned {
                self?.isShowingAd = false
                completion?(.closed)
            } else {
                self?.isShowingAd = false
                completion?(.error)
            }
        }
    }
    
    func loadBanner(_ id: AdUnitID, viewBanner: UIView, completion: @escaping ((_ success: Bool) -> Void)) {
        var adId = id
        if isTestMode {
            adId = SampleAdUnitID.adFormatBanner
        }
        SSLogging.d("ADMANAGER: BANNER  \(adId)")
        guard isShowBanner, 
                let viewController = appDelegate?.getRootViewController() else {
            completion(false)
            SSLogging.d("ADMANAGER: BANNER REMOTE CLOSE")
            return
        }
        AdMobManager.shared.blockBannerFailed = { adId in
            SSLogging.d("ADMANAGER: BANNER LOAD FAILED: \(adId)")
            completion(false)
        }
        AdMobManager.shared.blockLoadBannerSuccess = { success in
            SSLogging.d("ADMANAGER: BANNER LOAD SUCCESS: \(adId)")
            completion(success)
        }
        AdMobManager.shared.blockBannerClick = { str in
            SSLogging.d("ADMANAGER: BANNER CLICKED AND REFRESH: \(str)")
            self.loadBanner(adId, viewBanner: viewBanner, completion: completion)
        }
        AdMobManager.shared.addAdBanner(unitId: adId, rootVC: viewController, view: viewBanner)
    }
    
    func loadBannerAdaptive(_ id: AdUnitID, viewBanner: UIView, completion: @escaping ((_ success: Bool) -> Void)) {
        var adId = id
        if isTestMode {
            adId = SampleAdUnitID.adFormatBanner_2
        }
        SSLogging.d("ADMANAGER: BANNER")
        guard isShowBanner,
              let viewController = appDelegate?.getRootViewController() else {
            completion(false)
            SSLogging.d("ADMANAGER: BANNER REMOTE CLOSE")
            return
        }
        AdMobManager.shared.blockBannerFailed = { adId in
            SSLogging.d("ADMANAGER: BANNER ADAPTIVE LOAD FAILED: \(adId)")
            completion(false)
        }
        AdMobManager.shared.blockLoadBannerSuccess = { success in
            SSLogging.d("ADMANAGER: BANNER ADAPTIVE LOAD SUCCESS: \(adId)")
            completion(success)
        }
        AdMobManager.shared.blockBannerClick = { str in
            SSLogging.d("ADMANAGER: BANNER ADAPTIVE CLICKED AND REFRESH: \(str)")
            self.loadBannerAdaptive(adId, viewBanner: viewBanner, completion: completion)
        }
        AdMobManager.shared.addAdBannerAdaptive(unitId: adId, rootVC: viewController, view: viewBanner)
    }
    
    func loadCollapsibleBannerAdaptive(_ id: AdUnitID,
                                       viewBanner: UIView,
                                       isCollapsible: Bool = false,
                                       completion: @escaping ((_ success: Bool) -> Void)) {
        var adId = id
        if isTestMode {
            adId = SampleAdUnitID.adFormatCollapsibleBanner
        }
        SSLogging.d("ADMANAGER: BANNER")
        guard isShowBanner,
              let viewController = appDelegate?.getRootViewController() else {
            completion(false)
            SSLogging.d("ADMANAGER: BANNER REMOTE CLOSE")
            return
        }
        AdMobManager.shared.blockBannerFailed = { adId in
            SSLogging.d("ADMANAGER: BANNER COLLAPSIBLE ADAPTIVE LOAD FAILED: \(adId)")
            completion(false)
        }
        AdMobManager.shared.blockLoadBannerSuccess = { success in
            SSLogging.d("ADMANAGER: BANNER COLLAPSIBLE ADAPTIVE LOAD SUCCESS: \(adId)")
            completion(success)
        }
        AdMobManager.shared.blockBannerClick = { str in
            SSLogging.d("ADMANAGER: BANNER COLLAPSIBLE  ADAPTIVE CLICKED AND REFRESH: \(str)")
            self.loadCollapsibleBannerAdaptive(adId, viewBanner: viewBanner, completion: completion)
        }
        AdMobManager.shared.addAdCollapsibleBannerAdaptive(unitId: adId, rootVC: viewController,
                                                           view: viewBanner, isCollapsibleBanner: isCollapsible)
    }
    
    func loadNative(_ id: AdUnitID,
                    to view: UIView,
                    nativeAdType: NativeAdType = .smallMedia,
                    _ completion: @escaping ((_ success: Bool) -> Void)) {
        var adId = id
        if isTestMode {
            adId = SampleAdUnitID.adFormatNativeAdvancedVideo
        }
        guard isShowNative, 
                let viewController = appDelegate?.getRootViewController() else {
            completion(false)
            return
        }
        AdMobManager.shared.blockNativeFailed = { adId in
            SSLogging.d("ADMANAGER: NATIVE LOAD FAILED: \(adId)")
            completion(false)
        }
        AdMobManager.shared.blockLoadNativeSuccess = { adId in
            SSLogging.d("ADMANAGER: NATIVE LOAD SUCCESS: \(adId)")
            completion(true)
        }
        AdMobManager.shared.addAdNative(unitId: adId, rootVC: viewController, views: [view],
                                        type: nativeAdType, ratio: .any)
    }
    
}
