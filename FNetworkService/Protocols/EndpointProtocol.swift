//
//  FEndpointProtocol.swift
//  FNetworkService
//
//  Created by Alexander Antonov on 06/09/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation
import Alamofire

/// A dictionary of parameters to apply to a `URLRequest`
public typealias Parameters = [String: Any]
/// A dictionary of headers to apply to a `URLRequest`
public typealias HTTPHeaders = [String: String]
/// Enum HTTP method
public typealias HTTPMethod = Alamofire.HTTPMethod

public protocol EndpointProtocol {
    
    var baseUrl: URL? { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
    var headers: HTTPHeaders? { get }
    var cacheKey: String? { get }
}


// MARK: - Default implementation
public extension EndpointProtocol {
    
    var encoding: ParameterEncoding {
        switch method {
        case .get:      return URLEncoding()
        default:        return JSONEncoding()
        }
    }
    
    var headers: HTTPHeaders? {
        return nil
    }
    
    var cacheKey: String? {
        return nil
    }
    
}


public extension EndpointProtocol {
    
    var description: String {
        
        let domain = baseUrl?.absoluteString ?? "Domain missed!"
        var endpointLog = "\(method.rawValue) Request: \(domain)\(path)\n"
        endpointLog += "with parameters: \(parameters.stringValue)\n"
        endpointLog += "headers: \(headers.stringValue)"
        
        return endpointLog
    }
        
}
