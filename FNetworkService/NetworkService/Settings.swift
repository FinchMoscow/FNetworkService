//
//  Settings.swift
//  FNetworkService
//
//  Created by Alexander Antonov on 28/11/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation

extension NetworkService {

    public class Settings {
        
        public var validCodes = (200 ..< 300)
        public var cacheRequestTimeout: TimeInterval = 0.3
        public var requestTimeout: TimeInterval = 10
        public var completionQueue: DispatchQueue = .main
        public var dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.millisecondsSince1970
        public var keyDecodingStrategy = JSONDecoder.KeyDecodingStrategy.useDefaultKeys
        public var requestSettings: RequestSettingsProtocol = Settings.defaultRequestSettings
        public var networkLogger: NetworkLogWriter? = Settings.defaultLogger
        public var debugLogger: NetworkLogWriter? = Settings.defaultDebugLogger
        
        public lazy var decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = self.dateDecodingStrategy
            decoder.keyDecodingStrategy = self.keyDecodingStrategy
            return decoder
        }()
        
        
        // MARK: - Singleton
        
        public static var `default`: Settings {
            return Settings()
        }
        
        private init() { }
        
        
        // MARK: - Project settings
        
        /// This object is responsible for additional configuration of each request of NetworkService instance
        public static let defaultRequestSettings = RequestSettings()
        
        /// Implement and assign your logger, it'll be used by every instance as default.
        /// In order to change logger in particular NetworkService you may use `init(settings: NetworkService.Settings)`
        public static var defaultLogger: NetworkLogWriter?
        
        /// Implement and assign your debug logger if needed.
        /// In order to change debug logger in particular NetworkService you may use `init(settings: NetworkService.Settings)`
        public static var defaultDebugLogger: NetworkLogWriter = DebugLogWriter()
    }
    
}
