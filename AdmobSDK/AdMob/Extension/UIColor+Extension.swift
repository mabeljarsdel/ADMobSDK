//
//  UIColor+Extension.swift
//  AdmobSDK
//
//  Created by ANH VU on 28/04/2022.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: alpha)
    }
    
    convenience init(hex: Int,  alpha: CGFloat = 1.0) {
        self.init(red: ((hex >> 16) & 0xFF), green: ((hex >> 8) & 0xFF), blue: (hex & 0xFF), alpha: alpha)
    }
    
    func gradientColor(bounds: CGRect, colorStart: UIColor = .white, colorEnd: UIColor = .white, isHorizontalMode: Bool = true) -> UIColor? {
        let getGradientLayer = getGradientLayer(bounds: bounds, colorStart: colorStart, colorEnd: colorEnd, isHorizontalMode: isHorizontalMode)
        UIGraphicsBeginImageContext(getGradientLayer.bounds.size)
        guard (UIGraphicsGetCurrentContext() != nil) else {return UIColor(hex: 0xFD5900)}
        getGradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return UIColor(patternImage: image!)
    }
    
    func getGradientLayer(bounds : CGRect, colorStart: UIColor = .white, colorEnd: UIColor = .white, isHorizontalMode: Bool) -> CAGradientLayer{
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [colorStart.cgColor ,colorEnd.cgColor]
        gradient.startPoint = isHorizontalMode ? CGPoint(x: 0.0, y: 0.5) : CGPoint(x: 0.5, y: 0)
        gradient.endPoint = isHorizontalMode ? CGPoint(x: 1.0, y: 0.5) : CGPoint(x: 0.5, y: 1)
        return gradient
    }

}

