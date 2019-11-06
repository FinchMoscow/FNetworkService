//
//  RequestSettings.swift
//  FNetworkService
//
//  Created by Eugene on 06/11/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

public protocol RequestSettingsProtocol {
    
    var additionalHeaders: [String: String]? { get set }
    
}

extension NetworkService {
    
    public final class RequestSettings: RequestSettingsProtocol {
        
        /// if set, will be merged with each endpoint's headers
        public var additionalHeaders: [String: String]?
        
    }
    
}
