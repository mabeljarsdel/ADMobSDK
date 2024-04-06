//
//  BBLLogging.swift
//  Base
//
//  Created by BBLabs on 04/09/2023.
//

import Foundation
import ObjectiveC

@objc
public final class BBLLogging: NSObject {
    
    private enum BBLLoggingLevel {
        case debug
        case error
        case info
        case verbose
        case warning
    }
    
    private override init() {
        super.init()
    }
    
    @objc public static func d(_ message: @autoclosure () -> String = "",
                         file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), file: file, function: function, line: line, level: .debug)
    }
    
    @objc public static func e(_ message: @autoclosure () -> String = "",
                         file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), file: file, function: function, line: line, level: .error)
    }
    
    @objc public static func i(_ message: @autoclosure () -> String = "",
                         file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), file: file, function: function, line: line, level: .info)
    }
    
    @objc public static func v(_ message: @autoclosure () -> String = "",
                         file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), file: file, function: function, line: line, level: .verbose)
    }
    
    @objc public static func w(_ message: @autoclosure () -> String = "",
                         file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), file: file, function: function, line: line, level: .warning)
    }
    
    private static func log(_ message: @autoclosure () -> String,
                            file: String = #file, function: String = #function, line: Int = #line, level: BBLLoggingLevel = .debug) {
//        #if DEBUG
        switch level {
        case .debug:
            NSLog("🟦 Logging->D: %@ %@", "\((file as NSString).lastPathComponent).\(function):\(line)", message())
        case .error:
            NSLog("🟥 Logging->E: %@ %@", "\((file as NSString).lastPathComponent).\(function):\(line)", message())
        case .info:
            NSLog("🟩 Logging->I: %@ %@", "\((file as NSString).lastPathComponent).\(function):\(line)", message())
        case .verbose:
            NSLog("🟧 Logging->V: %@ %@", "\((file as NSString).lastPathComponent).\(function):\(line)", message())
        case .warning:
            NSLog("🟨 Logging->W: %@ %@", "\((file as NSString).lastPathComponent).\(function):\(line)", message())
        }
//        #endif
    }
    
}
