//
//  RemoteConfigManager.swift
//  AnimalTranslate
//
//  Created by BBLabs on 8/22/23.
//  Copyright ©2024 BBLabs. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig
import FirebaseAnalytics

public protocol KeyRemote {
    var key: String { get }
}

public protocol EventTracking {
    var key: String { get }
}

public enum DefaultRemoteKey: String, KeyRemote {
    
    // Subscription List
    case subscriptionList = "subscription_list"
    // Adverts
    case stateShowAds = "state_show_ads"
    case timeRemoteShowAd = "time_remote_show_ads"
    
    public var key: String { return rawValue }
}

public class RemoteConfigManager: NSObject {
    public static let shared = RemoteConfigManager()
    private let remoteConfig = RemoteConfig.remoteConfig()
    private let TIMEOUT_REMOTE_CONFIG: TimeInterval = 5 // 5 seconds
    private var workItemTimeOut: DispatchWorkItem? // Create a private DispatchWorkItem property

    public var onConfigChanged: ((_ keysChanged: Set<String>) -> Void)?
    
    override init() {
        super.init()
        initRemoteConfig()
    }
    
    private func initRemoteConfig() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        settings.fetchTimeout = TIMEOUT_REMOTE_CONFIG
        remoteConfig.configSettings = settings
        remoteConfig.addOnConfigUpdateListener { [weak self] configUpdate, error in
            guard let configUpdate, error == nil else {
                print("Error listening for config updates: \(error)")
                return
            }
            print("Updated keys: \(configUpdate.updatedKeys)")
            self?.remoteConfig.activate { changed, error in
                if changed {
                    self?.onConfigChanged?(configUpdate.updatedKeys)
                }
            }
            DispatchQueue.main.asyncSafety {
                ADManager.shared.initialize(readConfig: error == nil,
                                            completion: { _ in })
            }
        }
    }
    
    public func fetchConfig(completion: @escaping ((_ success: Bool) -> Void)) {
        remoteConfig.fetch { [weak self] status, error in
            print("Callback fetch remote config")
            guard let self = self else { return }
            switch status {
            case .noFetchYet:
                completion(false)
            case .success:
                self.remoteConfig.activate()
                print("Config success need active")
                completion(error == nil)
            case .failure:
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "Has error")")
                completion(false)
            case .throttled:
                print("Config using pre fetched not need active")
                completion(error == nil)
            @unknown default:
                completion(false)
            }
        }
    }
    
    public func fetchConfigSync(completion: @escaping ((_ success: Bool) -> Void)) {
        workItemTimeOut?.cancel()
        workItemTimeOut = nil
        remoteConfig.fetch { [weak self] status, error in
            self?.workItemTimeOut?.cancel()
            self?.workItemTimeOut = nil
            self?.completionFetch(status: status, error: error, completion: completion)
        }
        workItemTimeOut = DispatchWorkItem(block: {
            completion(false)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(TIMEOUT_REMOTE_CONFIG)), execute: workItemTimeOut!)
    }
    
    private func completionFetch(status: RemoteConfigFetchStatus,
                                 error: Error?,
                                 completion: @escaping ((_ success: Bool) -> Void)) {
        print("Callback fetch remote config")
        switch status {
        case .noFetchYet:
            completion(false)
        case .success:
            self.remoteConfig.activate()
            print("Config using pre fetched need active")
            completion(error == nil)
        case .failure:
            print("Config not fetched")
            print("Error: \(error?.localizedDescription ?? "Has error")")
            completion(false)
        case .throttled:
            print("Config using pre fetched not need active")
            completion(error == nil)
        @unknown default:
            completion(false)
        }
    }
    
    // MARK: - Support function
    public func getValue(by key: KeyRemote) -> RemoteConfigValue? {
        return self.remoteConfig[key.key]
    }
    
    public func getValue(by key: String) -> RemoteConfigValue? {
        return self.remoteConfig[key]
    }
    
    public func number(forKey key: KeyRemote) -> Int {
        return RemoteConfig.remoteConfig()[key.key].numberValue.intValue
    }
    
    public func bool(forKey key: KeyRemote) -> Bool {
        return RemoteConfig.remoteConfig()[key.key].boolValue
    }
    
    public func string(forKey key: KeyRemote) -> String {
        return RemoteConfig.remoteConfig()[key.key].stringValue ?? ""
    }
    
    public func double(forKey key: KeyRemote) -> Double {
        return RemoteConfig.remoteConfig()[key.key].numberValue.doubleValue
    }
    
    public func objectJson<T: Decodable>(forKey key: KeyRemote, type: T.Type) -> T? {
        let data = RemoteConfig.remoteConfig()[key.key].dataValue
        return try? JSONDecoder().decode(type, from: data)
    }
    
    public func number(forKey key: String) -> Int {
        return RemoteConfig.remoteConfig()[key].numberValue.intValue
    }
    
    public func bool(forKey key: String) -> Bool {
        return RemoteConfig.remoteConfig()[key].boolValue
    }
    
    public func string(forKey key: String) -> String {
        return RemoteConfig.remoteConfig()[key].stringValue ?? ""
    }
    
    public func double(forKey key: String) -> Double {
        return RemoteConfig.remoteConfig()[key].numberValue.doubleValue
    }
    
    public func objectJson<T: Decodable>(forKey key: String, type: T.Type) -> T? {
        let data = RemoteConfig.remoteConfig()[key].dataValue
        return try? JSONDecoder().decode(type, from: data)
    }
}

public class FirebaseEventManager {
    
    public class func logEvent(with name: String, params: [String: Any] = [:]) {
        Analytics.logEvent(name, parameters: params)
    }
    
    public class func logEvent(with event: EventTracking, params: [String: Any] = [:]) {
        var content = params
        content["app_version"] = "\(Bundle.main.releaseVersionNumber)(\(Bundle.main.buildVersionNumber))"
        Analytics.logEvent(event.key,
                           parameters: content)
    }
    
}
