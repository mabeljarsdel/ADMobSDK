//
//  AdBannerBottomVC.swift
//  AdmobSDK
//
//  Created by macbook on 28/08/2021.
//

import UIKit
import GoogleMobileAds
import SnapKit

open class AdBannerBottomVC: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var bottomBannerView: UIView!
    @IBOutlet weak var adHeightConstraint: NSLayoutConstraint!
    var unitId: AdUnitID?
    var isAdaptive: Bool = true
    var adSize = CGSize(width: screenWidthAds, height: 90)
   
    open override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let unitId = unitId {
            AdMobManager.shared.removeAd(unitId: unitId.rawValue)
        }
    }
    
    open func loadAd() {
        guard let unitId = self.unitId else {
            return
        }
        self.bottomBannerView.isSkeletonable = true
        self.bottomBannerView.showAnimatedGradientSkeleton()
        if isAdaptive {
            adHeightConstraint.isActive = false
            AdMobManager.shared.addAdBannerAdaptive(unitId: unitId, rootVC: self, view: self.bottomBannerView)
        } else {
            adHeightConstraint.isActive = true
            adHeightConstraint.constant = adSize.height
            AdMobManager.shared.addAdBanner(unitId: unitId, rootVC: self, view: self.bottomBannerView)
        }
     
    }

    public static func createViewController(contentVC: UIViewController, unitId: AdUnitID, isAdaptive: Bool = true) -> AdBannerBottomVC {
        let vc = AdBannerBottomVC.instance()
        vc.loadViewIfNeeded()
        vc.addChild(contentVC)
        vc.modalPresentationStyle = .fullScreen
        vc.unitId = unitId
        vc.isAdaptive = isAdaptive
        vc.containerView.addSubview(contentVC.view)
        vc.loadAd()
        contentVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return vc
    }

}

