//
//  AdMobManager+Rewarded.swift
//  AdmobSDK
//
//  Created by Quang Ly Hoang on 22/02/2022.
//

import Foundation
import GoogleMobileAds

// MARK: - GADInterstitial
extension AdMobManager {
    
    func getAdRewarded(unitId: AdUnitID) -> GADRewardedAd? {
        if let rewarded = listAd.object(forKey: unitId.rawValue) as? GADRewardedAd {
            return rewarded
        }
        return nil
    }
    
    /// khởi tạo id ads trước khi show
    public func createAdRewardedIfNeed(unitId: AdUnitID, completion: BoolBlockAds? = nil) {
        if self.getAdRewarded(unitId: unitId) != nil {
            completion?(true)
            return
        }
        if loadingRewardIds.contains(unitId.rawValue) { return }
        loadingRewardIds.append(unitId.rawValue)
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: unitId.rawValue, request: request) { [weak self] ad, error in
            self?.loadingRewardIds.removeAll(where: { $0 == unitId.rawValue })
            if let error = error {
                print("Failed to load rewarded ad with error: \(error.localizedDescription)")
                
                self?.removeAd(unitId: unitId.rawValue)
                self?.blockFullScreenAdFailed?(unitId.rawValue)
                self?.blockCompletionHandeler?(false)
                completion?(false)
                return
            }
            
            guard let ad = ad else {
                self?.removeAd(unitId: unitId.rawValue)
                self?.blockFullScreenAdFailed?(unitId.rawValue)
                self?.blockCompletionHandeler?(false)
                completion?(false)
                return
            }
            ad.fullScreenContentDelegate = self
            ad.paidEventHandler = { value in
                self?.trackAdRevenue(value: value, unitId: ad.adUnitID)
            }
            self?.listAd.setObject(ad, forKey: unitId.rawValue as NSCopying)
            self?.blockLoadFullScreenAdSuccess?(unitId.rawValue)
            completion?(true)
        }
    }
    
    public func presentAdRewarded(unitId: AdUnitID) {
        createAdRewardedIfNeed(unitId: unitId)
        let rewarded = getAdRewarded(unitId: unitId)
        didEarnReward = false
        if let topVC =  UIApplication.getTopViewController() {
            rewarded?.present(fromRootViewController: topVC) { [weak self] in
                self?.didEarnReward = true
            }
            AdResumeManager.shared.isShowingAd = true // check nếu show rewarded thig ko show resume
        }
    }
    
    public func showRewarded(unitId: AdUnitID, completion: BoolBlockAds?) {
        if AdMobManager.shared.getAdRewarded(unitId: unitId) != nil {
            var rootVC = UIApplication.getTopViewController()
            if rootVC?.navigationController != nil {
                rootVC = rootVC?.navigationController
                if rootVC?.tabBarController != nil {
                    rootVC = rootVC?.tabBarController
                }
            }
            guard let rootVC = rootVC else { return }
            
            let loadingVC = AdFullScreenLoadingVC.createViewController(unitId: unitId, adType: .reward(id: unitId))
            rootVC.addChild(loadingVC)
            rootVC.view.addSubview(loadingVC.view)
            loadingVC.blockDidDismiss = { [weak loadingVC] in
                loadingVC?.view.removeFromSuperview()
                loadingVC?.removeFromParent()
                completion?(self.didEarnReward)
            }
            loadingVC.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            Utils.showToast(rewardErrorString, on: UIApplication.getTopViewController()?.view)
            createAdRewardedIfNeed(unitId: unitId)
            completion?(false)
        }
    }
    
}
