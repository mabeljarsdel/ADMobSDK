//
//  AppVersionModel.swift
//  PrankSound-iOS
//
//  Created by PrankSound on 24/11/2023.
//  Copyright © 2024 BBLabs. All rights reserved.
//

import Foundation

struct AppVersionModel: Codable {
    var configUpdate: AppVersionConfigUpdate?
    
    private enum CodingKeys: String, CodingKey {
        case configUpdate = "config_update"
    }
}

struct AppVersionConfigUpdate: Codable {
    var ios: PlatformAppVersion?
}

struct PlatformAppVersion: Codable {
    var link: String?
    var versionName: String?
    var forceUpdate: Bool?
    var latestForceVersion: String?
    var description: String?
    
    func checkForceUpdate() -> (ableUpdate: Bool, force: Bool) {
        if !(forceUpdate ?? true) {
            if let lateVersion = latestForceVersion,
               !lateVersion.isEmpty,
               checkAppUpdate(version: lateVersion) {
                return (true, true)
            }
        }
        let version = versionName ?? ""
        return (checkAppUpdate(version: version), true)
    }
    
    private func checkAppUpdate(version: String) -> Bool {
        let versionBuild = Bundle.main.releaseVersionNumber
        if versionBuild.elementsEqual(version) {
            return false
        } else {
            let arrVerNumb = version.split(separator: ".")
            let arrVerNumbBuild = versionBuild.split(separator: ".")
            if arrVerNumb.count != 3 || arrVerNumbBuild.count != 3 {
                return true
            } else {
                var verNo = Int(arrVerNumb[0]) ?? -2
                var verBuildNo = Int(arrVerNumbBuild[0]) ?? -1
                if verNo < verBuildNo {
                    return false
                } else if verNo == verBuildNo {
                    verNo = Int(arrVerNumb[1]) ?? -2
                    verBuildNo = Int(arrVerNumbBuild[1]) ?? -1
                    if verNo < verBuildNo {
                        return false
                    } else if verNo == verBuildNo {
                        verNo = Int(arrVerNumb[2]) ?? -2
                        verBuildNo = Int(arrVerNumbBuild[2]) ?? -1
                        if verNo <= verBuildNo {
                            return false
                        }
                    }
                }
            }
            return true
        }
    }
}
