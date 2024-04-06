//
//  LoadingProgressHUD.swift
// PetTranslate-iOS
//
//  Created by BBLabs on 3/16/23.
//  Copyright © 2024 BBLabs.All rights reserved.
//

import Foundation
//import Lottie
import SVProgressHUD
import UIKit

public class LoadingProgressHUD: UIView {
    
    //    private static let shared = LoadingProgressHUD()
    //    let hudView = LottieAnimationView()
    //
    //    // options
    //    var hudWidth: CGFloat = 80
    //    var hudHeight: CGFloat = 80
    //    var animationFileName = "LoadingAnimation"
    //
    //    override init(frame: CGRect) {
    //        super.init(frame: frame)
    //        self.setup()
    //    }
    //
    //    required init?(coder aDecoder: NSCoder) {
    //        super.init(coder: aDecoder)
    //        self.setup()
    //    }
    //
    //    func setup() {
    //        self.isUserInteractionEnabled = true
    //        self.frame = UIScreen.main.bounds
    //        self.backgroundColor = R.color.textColor()?.withAlphaComponent(0.4)
    //        hudView.backgroundColor = R.color.neutralNeutral4()
    //        hudView.roundCorners(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner],
    //                             radius: 10)
    //        hudView.translatesAutoresizingMaskIntoConstraints = false
    //        self.addSubview(hudView)
    //        NSLayoutConstraint.activate([
    //            hudView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0),
    //            hudView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0),
    //            hudView.widthAnchor.constraint(equalToConstant: hudWidth),
    //            hudView.heightAnchor.constraint(equalToConstant: hudHeight)
    //        ])
    //    }
    //
    //    func show() {
    //        self.isHidden = false
    //        self.hudView.loadAnimation(file: animationFileName, loopMode: .loop, autoPlay: true)
    //        self.fadeIn()
    //    }
    //
    //    func hide() {
    //        DispatchQueue.main.asyncSafety{
    //            self.hudView.stop()
    //            self.fadeOut()
    //            self.isHidden = true
    //            self.removeFromSuperview()
    //        }
    //    }
    //
    public class func isVisible() -> Bool {
        //        return !LoadingProgressHUD.shared.isHidden && (LoadingProgressHUD.shared.superview != nil)
        return SVProgressHUD.isVisible()
    }
    
    public class func show() {
        SVProgressHUD.show()
        //        DispatchQueue.main.asyncSafety{
        //            let progressHUD = LoadingProgressHUD.shared
        //            if isVisible() { return }
        //            if let currentController = AppRouter.shared.rootViewController {
        //                currentController.view.addSubview(progressHUD)
        //            } else {
        //                if let window = UIApplication.shared.keyWindow {
        //                    window.addSubview(progressHUD)
        //                }
        //            }
        //            progressHUD.show()
        //        }
    }
    
    public class func dismiss() {
        SVProgressHUD.dismiss(withDelay: 0.25)
        //        DispatchQueue.main.asyncSafety{
        //            LoadingProgressHUD.shared.hide()
        //        }
    }
}
