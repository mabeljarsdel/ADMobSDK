//
//  UIViewControll+Extension+Ads.swift
//  AdmobSDK
//
//  Created by ANH VU on 08/03/2022.
//

import Foundation
import UIKit
import MONActivityIndicatorView
import SnapKit

extension UIViewController {
    func showLoadingDotAds(backgroundColor: UIColor = .clear, textLoading: String? = nil) {
        let keyWindow = self.keyWindowAds ?? self.view
        
        if self.view.subviews.first(where: {$0.tag == -111}) != nil {
            return
        }
        let overLayView = UIView()
        overLayView.backgroundColor = backgroundColor
        overLayView.tag = -112
        overLayView.frame = keyWindow!.frame
        
        let dotView = UIActivityIndicatorView()
        dotView.tag = -111
        self.view.addSubview(overLayView)
        overLayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        overLayView.addSubview(dotView)
        dotView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        dotView.startAnimating()
        
        if let textLoading = textLoading {
            let label = UILabel()
            label.textColor = .lightGray
            overLayView.addSubview(label)
            label.text = textLoading
            label.snp.makeConstraints { make in
                make.centerY.equalToSuperview().offset(-40)
                make.centerX.equalToSuperview()
            }
        }
    }
    
    func hideLoadingDotAds() {
        self.view.subviews.first(where: {$0.tag == -111})?.removeFromSuperview()
        self.view.subviews.first(where: {$0.tag == -112})?.removeFromSuperview()
    }
    
    var keyWindowAds: UIWindow? {
        get {
            return UIApplication.shared.windows.first(where: {$0.isKeyWindow})
        }
    }
}
