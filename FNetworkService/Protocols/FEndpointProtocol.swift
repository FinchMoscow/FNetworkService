//
//  FEndpointProtocol.swift
//  Stewards
//
//  Created by Alexander Antonov on 06/09/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation
import Alamofire

public typealias Parameters = [String: Any] // A dictionary of parameters to apply to a `URLRequest`
public typealias HTTPHeaders = [String: String] // A dictionary of headers to apply to a `URLRequest`
public typealias HTTPMethod = Alamofire.HTTPMethod
public typealias Headers = HTTPHeaders

public protocol FEndpointProtocol {
    
    var baseUrl: URL? { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
    var headers: HTTPHeaders? { get }
    var cacheKey: String? { get }
}

public extension FEndpointProtocol {
    
    var encoding: ParameterEncoding {
        switch method {
        case .get:
            return URLEncoding()
        default:
            return JSONEncoding()
        }
    }
    
    var headers: HTTPHeaders? {
        return nil
    }
    
    var cacheKey: String? {
        return nil
    }
    
}
