//
//  ADConfig.swift
//  Base
//
//  Created by Base on 14/08/2023.
//

import Foundation

struct AdShowState: Codable {
    var version: String?
    var isShowBanner: Bool?
    var isShowOpen: Bool?
    var isShowFull: Bool?
    var isShowReward: Bool?
    var isShowNative: Bool?
    var isTestMode: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case version = "version"
        case isTestMode = "is_test_mode"
        case isShowBanner = "is_show_banner"
        case isShowOpen = "is_show_open"
        case isShowFull = "is_show_full"
        case isShowReward = "is_show_reward"
        case isShowNative = "is_show_native"
    }
    
}

struct AdConfigTime: Codable {
    
    var timeShowOpen: Int?
    var timeShowFull: Int?
    var timeShowReward: Int?
    var maxClickShowAd: Int?
    
    enum CodingKeys: String, CodingKey {
        case timeShowOpen = "time_show_open"
        case timeShowFull = "time_show_full"
        case timeShowReward = "time_show_reward"
        case maxClickShowAd = "max_click_show_ad"
    }

}
