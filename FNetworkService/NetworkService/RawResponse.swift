//
//  RawResponse.swift
//  FNetworkService
//
//  Created by Eugene on 06/09/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

import Foundation

public protocol Response {
    
    associatedtype T
    
    var httpMeta: HTTPURLResponse { get }
    var body: T { get }
}

public struct BaseDataResponse: Response {
    
    public typealias T = Data
    public let httpMeta: HTTPURLResponse
    public let body: Data
}


public struct RawResponse: Response {
    
    public typealias T = String
    
    public let httpMeta: HTTPURLResponse
    public let body: String
}


public struct CodableResponse: Response {
    
    public typealias T = Codable
    
    public let httpMeta: HTTPURLResponse
    public let body: Codable
}


public struct DecodableResponse: Response {
    
    public typealias T = Decodable
    
    public let httpMeta: HTTPURLResponse
    public let body: Decodable
}
