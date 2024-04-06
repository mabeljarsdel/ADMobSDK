//
//  RemoteConfigManager.swift
//  AnimalTranslate
//
//  Created by BBLabs on 8/22/23.
//  Copyright ©2024 BBLabs. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig

public class RemoteConfigManager: NSObject {
    static let shared = RemoteConfigManager()
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
        remoteConfig.setDefaults(fromPlist: KeyRemoteConfig.filePetAdverts.rawValue)
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
    
    func fetchConfig(completion: @escaping ((_ success: Bool) -> Void)) {
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
    
    func fetchConfigSync(completion: @escaping ((_ success: Bool) -> Void)) {
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
    func getValue(by key: KeyRemoteConfig) -> RemoteConfigValue? {
        return self.remoteConfig[key.rawValue]
    }
    
    func getValue(by key: String) -> RemoteConfigValue? {
        return self.remoteConfig[key]
    }
    
    public func number(forKey key: KeyRemoteConfig) -> Int {
        return RemoteConfig.remoteConfig()[key.rawValue].numberValue.intValue
    }
    
    public func bool(forKey key: KeyRemoteConfig) -> Bool {
        return RemoteConfig.remoteConfig()[key.rawValue].boolValue
    }
    
    public func string(forKey key: KeyRemoteConfig) -> String {
        return RemoteConfig.remoteConfig()[key.rawValue].stringValue ?? ""
    }
    
    public func double(forKey key: KeyRemoteConfig) -> Double {
        return RemoteConfig.remoteConfig()[key.rawValue].numberValue.doubleValue
    }
    
    public func objectJson<T: Decodable>(forKey key: KeyRemoteConfig, type: T.Type) -> T? {
        let data = RemoteConfig.remoteConfig()[key.rawValue].dataValue
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
