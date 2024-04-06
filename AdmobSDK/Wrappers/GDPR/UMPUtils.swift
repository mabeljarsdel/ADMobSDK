//
//  UMPUtils.swift
//  PrankSound-iOS
//
//  Created by Animat on 20/12/2023.
//  Copyright © 2024 BBLabs. All rights reserved.
//

import Foundation
import UserMessagingPlatform
import FirebaseAnalytics

/**
 Log event tracking
 Tracking cần 5 chỗ
 Lần 1
 - Tracking load ( điều kiện user chưa consent)
 - Tracking user k cần hiển thị consent ( lưu lại biến cho lần sau k cần load consent nữa)
 - Tracking hiển thị
 - Tracking có or không ( sau đó mới load remote config và luồng như thông thường)
 - Tracking bị lỗi bất kỳ
 
 Lần 2
 - Tracking load ( điều kiện user chưa consent)
 - Tracking hiển thị
 - Tracking có or không
 - Tracking bị lỗi bất kỳ
 
 ví dụ Tracking : consent_load_1, consent_show_1
 Sử dụng Google Analytics để tracking
 
 */

enum UMPEventType: String {
    case trackingNetwork = "consent_%d_network"                     // Tracking network của user kết nối/không kết nối tại vị trí %d (1|2)
    case trackingLoadCMPIfNot = "consent_%d_user_consent_not_yet"   // Tracking load CMP nếu user chưa consent tại vị trí %d (1|2)
    case trackingUserNotNeedConsent = "consent_%d_not_need_show"    // Tracking số lượng user không cần hiển thị CMP tại vị trí %d (1|2)
    case trackingViewConsent = "consent_%d_view_form"               // Tracking số lượng hiển thị CMP với user tại vị trí %d (1|2)
    case trackingAcceptConsent = "consent_%d_accept_consent"        // Tracking số lượng chấp nhận CMP tại vị trí %d (1|2)
    case trackingNotAcceptConsent = "consent_%d_not_accept_consent" // Tracking số lượng không chấp nhận CMP tại vị trí %d (1|2)
    case trackingConsentError = "consent_%d_error"                  // Tracking số lượng lỗi của user tại vị trí %d (1|2)
}


public class UMPUtils {
    public static let shared = UMPUtils()
    public var umpDebugSettings: UMPDebugSettings? = nil
    
    public var consentStatus: UMPConsentStatus {
        return UMPConsentInformation.sharedInstance.consentStatus
    }
    
    public var formStatus: UMPFormStatus {
        return UMPConsentInformation.sharedInstance.formStatus
    }
    
    public var privacyOptionsRequirementStatus: UMPPrivacyOptionsRequirementStatus {
        return UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus
    }
    
    public var personalizeAds: Bool {
        let purposeConsents = UserDefaults.standard.string(forKey: "IABTCF_PurposeConsents")
        // Purposes are zero-indexed. Index 0 contains information about Purpose 1.
        return purposeConsents?.first == "1"
    }
    
    public func resetStateGDPRAgreement() {
        UMPConsentInformation.sharedInstance.reset()
    }
    
    public func showFormGDPR(idx: Int, completion: @escaping ((_ accepted: Bool) -> Void)) {
//        let networkConnected = isNetworkConnected()
//        // Log tracking user network status
//        logEvent(idx: idx, event: .trackingNetwork, content: ["connected": networkConnected])
//        if !networkConnected {
//            completion(false)
//            return
//        }
        switch consentStatus {
        case .unknown:
            // Log tracking error user content unknown status
            logEvent(idx: idx, event: .trackingConsentError, content: ["consentStatus": "Unknown consent status"])
            createIfNeedFormGDPR(idx: idx) { [weak self] created in
                if created {
                    self?.presentFormGDPR(idx: idx, completion: completion)
                    return
                }
                completion(true)
            }
        case .required:
            // Log tracking error user is not accept CMP
            logEvent(idx: idx, event: .trackingLoadCMPIfNot, content: ["consentStatus": "User is not consent. Required action of user"])
            switch formStatus {
            case .available:
                presentFormGDPR(idx: idx, completion: completion)
            default:
                createIfNeedFormGDPR(idx: idx) { [weak self] created in
                    if created {
                        self?.presentFormGDPR(idx: idx, completion: completion)
                        return
                    }
                    completion(true)
                }
            }
        case .notRequired:
            // Log tracking for user not need accept consent
            logEvent(idx: idx, event: .trackingUserNotNeedConsent, content: ["consentStatus": "User not need to show consent dialog"])
            completion(true)
        case .obtained:
            // Log tracking for user not need accept consent
            logEvent(idx: idx, event: .trackingConsentError, content: ["consentStatus": "Consent document is not available"])
            switch formStatus {
            case .available:
                presentFormGDPR(idx: idx, completion: completion)
            default:
                createIfNeedFormGDPR(idx: idx) { [weak self] created in
                    if created {
                        self?.presentFormGDPR(idx: idx, completion: completion)
                        return
                    }
                    completion(true)
                }
            }
        @unknown default:
            logEvent(idx: idx, event: .trackingLoadCMPIfNot, content: ["consentStatus": "default unknown consent status"])
            completion(true)
        }
    }
    
    private func presentFormGDPR(idx: Int, completion: @escaping ((_ accepted: Bool) -> Void)) {
        guard let currentController = UIApplication.shared.delegate?.getRootViewController() else {
            completion(false)
            return
        }
        logEvent(idx: idx, event: .trackingViewConsent, content: ["consentStatus": "Consent dialog is displayed"])
        UMPConsentForm.loadAndPresentIfRequired(from: currentController) { [weak self] loadAndPresentError in
            if let consentError = loadAndPresentError {
                // Consent gathering failed.
                print("Error: \(consentError.localizedDescription)")
                self?.logEvent(idx: idx, event: .trackingConsentError, content: ["consent_accept_error": "\(consentError)"])
                completion(false)
                return
            }
            let isAcceptedConsent = self?.canShowPersonalizeAd ?? false
            if isAcceptedConsent {
                self?.logEvent(idx: idx, event: .trackingAcceptConsent, content: ["consent_accepted": true])
            } else {
                self?.resetStateGDPRAgreement()
                self?.logEvent(idx: idx, event: .trackingNotAcceptConsent, content: ["consent_accepted": false])
            }
            completion(isAcceptedConsent)
            // Consent has been gathered.
        }
    }
    
    private func createIfNeedFormGDPR(idx: Int, completion: @escaping ((_ created: Bool) -> Void)) {
        let umpParams = UMPRequestParameters()
        if let debugSetting = umpDebugSettings {
            umpParams.debugSettings = debugSetting
        }
        umpParams.tagForUnderAgeOfConsent = false
        
        // Request an update for the consent information.
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: umpParams) { [weak self] requestConsentError in
            if let consentError = requestConsentError {
                // Consent gathering failed.
                print("consentError: \(consentError)")
                self?.logEvent(idx: idx, event: .trackingConsentError, content: ["Consent create dialog error": "\(consentError)"])
                completion(false)
                return
            }
            completion(self?.formStatus == .available)
        }
    }
    
    public var canShowPersonalizeAd: Bool {
        let prefs = UserDefaults.standard
        let purposeConsent: String = prefs.string(forKey: "IABTCF_PurposeConsents") ?? ""
        let vendorConsent: String = prefs.string(forKey:"IABTCF_VendorConsents") ?? ""
        let vendorLI: String = prefs.string(forKey:"IABTCF_VendorLegitimateInterests") ?? ""
        let purposeLI: String = prefs.string(forKey:"IABTCF_PurposeLegitimateInterests") ?? ""
        let googleId = 755
        let hasGoogleVendorConsent = hasAttribute(vendorConsent, googleId)
        let hasGoogleVendorLI = hasAttribute(vendorLI, googleId)
        var indexes: [Int] = []
        indexes.append(1)
        indexes.append(3)
        indexes.append(4)
        var indexesLI: [Int] = []
        indexesLI.append(2)
        indexesLI.append(7)
        indexesLI.append(9)
        indexesLI.append(10)
        return hasConsentFor(indexes, purposeConsent, hasGoogleVendorConsent)
        && hasConsentOrLegitimateInterestFor(indexesLI, purposeConsent, purposeLI,
                                             hasGoogleVendorConsent, hasGoogleVendorLI)
    }
    
    // Check if a binary string has a "1" at position "index" (1-based)
    private func hasAttribute(_ input: String, _ index: Int) -> Bool {
        return (input.count >= index) && (input[index-1] == "1")
    }
    
    // Check if consent is given for a list of purposes
    private func hasConsentFor(_ purposes: [Int], _ purposeConsent: String, _ hasVendorConsent: Bool) -> Bool {
        return purposes.contains(where: { p in
            hasAttribute(purposeConsent, p)
        }) && hasVendorConsent
    }
    
    // Check if a vendor either has consent or legitimate interest for a list of purposes
    private func hasConsentOrLegitimateInterestFor(_ purposes: [Int], _ purposeConsent: String,
                                                   _ purposeLI: String,
                                                   _ hasVendorConsent: Bool, _ hasVendorLI: Bool) -> Bool {
        return purposes.contains(where: { p in
            (hasAttribute(purposeLI, p) && hasVendorLI) ||
            (hasAttribute(purposeConsent, p) && hasVendorConsent)
        })
    }
}

// MARK: - Define log event tracking
extension UMPUtils {
    
    private func logEvent(idx: Int, event type: UMPEventType, content: [String: Any]) {
        Analytics.logEvent(String.init(format: type.rawValue, idx), parameters: content)
    }
    
}

extension String {

    internal func indexOf(_ sub: String) -> Int? {
        guard let range = self.range(of: sub), !range.isEmpty else {
            return nil
        }
        return self.distance(from: self.startIndex, to: range.lowerBound)
    }

    func urlEncodedString(_ encodeAll: Bool = false) -> String {
        var allowedCharacterSet: CharacterSet = .urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\n:#/?@!$&'()*+,;=")
        if !encodeAll {
            allowedCharacterSet.insert(charactersIn: "[]")
        }
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
    }
    
    var queryStringParameters: [String: String] {
        var parameters = [String: String]()
        guard let url = URLComponents(string: self) else { return [:] }
        for queryItem in url.queryItems ?? [] {
            parameters.updateValue(queryItem.value ?? "", forKey: queryItem.name)
        }
        return parameters
    }
    
    subscript(value: Int) -> Character {
        self[index(at: value)]
    }
    
    subscript(value: NSRange) -> Substring {
        self[value.lowerBound..<value.upperBound]
    }
    
    subscript(value: CountableClosedRange<Int>) -> Substring {
        self[index(at: value.lowerBound)...index(at: value.upperBound)]
    }
    
    subscript(value: CountableRange<Int>) -> Substring {
        self[index(at: value.lowerBound)..<index(at: value.upperBound)]
    }
    
    subscript(value: PartialRangeUpTo<Int>) -> Substring {
        self[..<index(at: value.upperBound)]
    }
    
    subscript(value: PartialRangeThrough<Int>) -> Substring {
        self[...index(at: value.upperBound)]
    }
    
    subscript(value: PartialRangeFrom<Int>) -> Substring {
        self[index(at: value.lowerBound)...]
    }
    
    func index(at offset: Int) -> String.Index {
        index(startIndex, offsetBy: offset)
    }
    
}
