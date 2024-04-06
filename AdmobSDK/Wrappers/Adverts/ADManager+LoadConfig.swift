//
//  ADManager++.swift
//  AnimalTranslate-iOS
//
//  Created by Lê Minh Sơn on 23/08/2023.
//

import AdmobSDK
import Foundation

extension ADManager {
    
    private func loadStateShowAds(_ stateShowAd: String) {
        guard !stateShowAd.isEmpty,
              let jsonData = stateShowAd.data(using: .utf8) else {
            self.loadDefaults()
            return
        }
        guard let adShowState = try? JSONDecoder().decode(AdShowState.self,
                                                          from: jsonData) else {
            self.loadDefaults()
            return
        }
        
        if adShowState.version?.elementsEqual(Bundle.main.releaseVersionNumber) ?? false {
            SSLogging.d("ADMANAGER: CONFIG SHOW STATE SETIING")
            self.showState = adShowState
        } else {
            SSLogging.d("ADMANAGER: CONFIG SHOW STATE DEFAULT")
            self.showState = AdShowState(version: nil,
                                         isShowBanner: true,
                                         isShowOpen: true,
                                         isShowFull: true,
                                         isShowNative: true,
                                         isTestMode: false)
        }
    }
    
    private func loadTimeRemoteShowAd(_ timeRemoteShowAd: String) {
        guard !timeRemoteShowAd.isEmpty,
              let jsonData = timeRemoteShowAd.data(using: .utf8) else {
            self.loadDefaults()
            return
        }
        guard let configTime = try? JSONDecoder().decode(AdConfigTime.self,
                                                         from: jsonData) else {
            self.loadDefaults()
            return
        }
        self.configTime = configTime
    }
    
    internal func initialAdverts() {
        if !loadableAd { return }
        SSLogging.d("ADMANAGER: CONFIG ADMOB started")
        
        let remoteConfig = RemoteConfigManager.shared
        let stateShowAds = remoteConfig.getValue(by: KeyRemoteConfig.stateShowAds.rawValue)?.stringValue ?? ""
        let timeRemoteShowAd = remoteConfig.getValue(by: KeyRemoteConfig.timeRemoteShowAd.rawValue)?.stringValue ?? ""
        
        loadStateShowAds(stateShowAds)
        
        loadTimeRemoteShowAd(timeRemoteShowAd)
        
        SSLogging.d("ADMANAGER: CONFIG ADMOB done")
    }
    
    internal func loadDefaults() {
        SSLogging.d("ADMANAGER")
        if loadableAd {
            self.showState = AdShowState(version: nil,
                                         isShowBanner: true,
                                         isShowOpen: true,
                                         isShowFull: true,
                                         isShowNative: true,
                                         isTestMode: false)
        } else {
            self.showState = AdShowState(version: nil,
                                         isShowBanner: false,
                                         isShowOpen: false,
                                         isShowFull: false,
                                         isShowNative: false,
                                         isTestMode: false)
        }
        self.configTime = AdConfigTime(timeShowOpen: 15,
                                       timeShowFull: 20,
                                       timeShowReward: 20,
                                       maxClickShowAd: 5)
    }
}
