//
//  JSONEncoding.swift
//  Stewards
//
//  Created by Alexander Antonov on 08/09/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation
import Alamofire

struct AnyEncodable: Encodable {
    
    private let encodable: Encodable
    
    public init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
    
}

struct JSONEncoding: ParameterEncoding {
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        
        var request = try urlRequest.asURLRequest()
        
        guard let parameters = parameters else { return request }
        
        var encodableParameters: [String: AnyEncodable] = [:]
        
        for (key, value) in parameters {
            
            guard let encodableValue = value as? Encodable else { continue }
            
            let anyEncodable = AnyEncodable(encodableValue)
            encodableParameters[key] = anyEncodable
        }
        
        let encoder = JSONEncoder()
        
        let encodedParameters: Data = try encoder.encode(encodableParameters)
        request.httpBody = encodedParameters
        
        let contentTypeHeaderName = "Content-Type"
        
        if request.value(forHTTPHeaderField: contentTypeHeaderName) == nil {
            request.setValue("application/json", forHTTPHeaderField: contentTypeHeaderName)
        }
        
        return request
    }
    
}
