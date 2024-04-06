//
//  Utils.swift
//  AdmobSDK
//
//  Created by Quang Ly Hoang on 24/05/2022.
//

import UIKit
import Toast_Swift

class Utils {
    static func showToast(_ message: String, on view: UIView? = nil) {
        let topView = view == nil ? UIApplication.shared.windows.last : UIApplication.getTopViewController()?.view
        topView?.hideToast()
        topView?.makeToast(message, duration: 2.0, position: .center)
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
