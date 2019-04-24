//
//  NetworkSettings.swift
//  THT-Premier
//
//  Created by Alexander Antonov on 28/11/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation

public struct NetworkSettings {
    
    public var validCodes = (200 ..< 300)
    public var cacheRequestTimeout: TimeInterval = 0.3
    
    public var requestTimeout: TimeInterval = 10
    public var resourceTimeout: TimeInterval = 10
    
    public var dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.millisecondsSince1970
    
    public static var `default`: NetworkSettings {
        return NetworkSettings()
    }
    
    private init() { }
    
}
