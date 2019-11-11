//
//  NetworkRequestable.swift
//  FNetworkService
//
//  Created by Eugene on 11/11/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

import Foundation

public protocol NetworkRequestable {
    
    /// APIResult = Swift.Result<Data, APIError>
    func request(endpoint: EndpointProtocol, completion: @escaping(APIResult<Data>) -> Void)
    
    
    /// APIResult = Swift.Result<Decodable, APIError>
    func request<Response: Decodable>(endpoint: EndpointProtocol, completion: @escaping (APIResult<Response>) -> Void)
    /// APIResult = Swift.Result<Codable, APIError>; Note you should provide cacheKey within EndpointProtocol
    func requestWithCache<Response: Codable>(endpoint: EndpointProtocol, completion: @escaping (APIResult<Response>) -> Void)
    
    
    /// APIXResult<Decodable> = Swift.Result<ModelWithResponse<Decodable>, APIError>
    func request<Response: Decodable>(endpoint: EndpointProtocol, completion: @escaping (APIXResult<Response>) -> Void)
    /// APIXResult<Codable> = Swift.Result<ModelWithResponse<Codable>, APIError>; Note you shoud provide cacheKey within EndpointProtocol
    func requestWithCache<Response: Codable>(endpoint: EndpointProtocol, completion: @escaping (APIXResult<Response>) -> Void)
    
    
    /// APIResult = Swift.Result<Codable, APIError>
    func uploadRequest<Response: Decodable>(endpoint: EndpointProtocol,
                                            data: Data, progressHandler: ((Double) -> Void)?,
                                            completion: @escaping (APIResult<Response>) -> Void)
}


// MARK: - Convenience methods
extension NetworkRequestable {
    
    /// APIResult = Swift.Result<Codable, APIError>,
    public func request<Response: Codable>(endpoint: EndpointProtocol,
                                           isCahingEnabled: Bool,
                                           completion: @escaping (APIResult<Response>) -> Void) {
        isCahingEnabled
            ? self.request(endpoint: endpoint, completion: completion)
            : self.requestWithCache(endpoint: endpoint, completion: completion)
    }
    
    /// APIXResult<Codable> = Swift.Result<ModelWithResponse<Codable>, APIError>
    public func request<Response: Codable>(endpoint: EndpointProtocol,
                                           isCahingEnabled: Bool,
                                           completion: @escaping (APIXResult<Response>) -> Void) {
        isCahingEnabled
            ? self.request(endpoint: endpoint, completion: completion)
            : self.requestWithCache(endpoint: endpoint, completion: completion)
    }
    
    /// APIResult = Swift.Result<Decodable, APIError>
    public func uploadRequest<Response: Decodable>(endpoint: EndpointProtocol,
                                                   data: Data, progressHandler: ((Double) -> Void)? = nil,
                                                   completion: @escaping (APIResult<Response>) -> Void) {
        
        self.uploadRequest(endpoint: endpoint, data: data, progressHandler: progressHandler, completion: completion)
    }
    
    
}
