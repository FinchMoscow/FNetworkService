//
//  RawResponse.swift
//  FNetworkService
//
//  Created by Eugene on 06/09/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

import Foundation

public struct BaseDataResponse {
    
    public let httpMeta: HTTPURLResponse
    public let payload: Data
    
    public var httpBody: String? {
        return String(data: payload, encoding: .utf8)
    }
    
}

public struct Response<Model> {
    
    public let httpMeta: HTTPURLResponse
    public let payload: Model
}
