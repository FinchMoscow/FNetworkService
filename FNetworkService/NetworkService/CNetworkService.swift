//
//  CNetworkService.swift
//  FNetworkService
//
//  Created by Eugene on 06/09/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

import Alamofire

public final class CNetworkService: BaseNetworkService {
    
    // MARK: - Public convenience methods
    
    public func request<Model: Codable>(endpoint: EndpointProtocol, isCacheEnabled: Bool, completion: @escaping (APIResult<Model>) -> Void) {
        
        switch isCacheEnabled {
            
        case true:
            requestWithCache(endpoint: endpoint, completion: completion)
            
        case false:
            requestWithoutCache(endpoint: endpoint, completion: completion)
            
        }
        
    }
    
    public func request<Model: Codable>(endpoint: EndpointProtocol, isCacheEnabled: Bool, completion: @escaping (APIResult<Response<Model>>) -> Void) {
        
        switch isCacheEnabled {
            
        case true:
            requestWithCache(endpoint: endpoint, completion: completion)
            
        case false:
            requestWithoutCache(endpoint: endpoint, completion: completion)
            
        }
        
    }
    
    public func uploadRequest<Model: Codable>(endpoint: EndpointProtocol,
                                              data: Data,
                                              progressHandler: ((Double) -> Void)?,
                                              completion: @escaping (APIResult<Response<Model>>) -> Void) {
        
        super.uploadRequest(endpoint: endpoint, data: data, progressHandler: progressHandler) { [weak self] baseResult in
            
            guard let self = self else { return }
            
            let result: APIResult<Response<Model>> = self.convert(from: baseResult)
            
            self.settings.completionQueue.async {
                completion(result)
            }
            
        }
        
    }
    
    
    // MARK: - Private methods
    
    private func convert<Model: Codable>(from baseResult: APIResult<BaseDataResponse>) -> APIResult<Model> {
        
        let result: APIResult<Model>
        
        switch baseResult {
            
        case .success(let baseSuccess):
            
            do {
                let modelObject = try self.decoder.decode(Model.self, from: baseSuccess.payload)
                result = .success(modelObject)
            }
            catch {
                result = .failure(.decodingError)
            }
            
        case .failure(let error):
            result = .failure(error)
        }
        
        return result
    }
    
    private func convert<Model: Codable>(from baseResult: APIResult<BaseDataResponse>) -> APIResult<Response<Model>> {
        
        let modelResult: APIResult<Model> = convert(from: baseResult)
        
        guard let modelObject = modelResult.value else {
            return .failure(modelResult.error!)
        }
        
        return .success(Response<Model>(httpMeta: baseResult.value!.httpMeta, payload: modelObject))
    }
    
}

public extension CNetworkService {
    
    /// Simple HTTP request without cache
    func requestWithoutCache<Model: Codable>(endpoint: EndpointProtocol, completion: @escaping (APIResult<Model>) -> Void) {
        
        super.request(endpoint: endpoint, isCacheEnabled: false) { [weak self] baseResult in
            
            guard let self = self else { return }
            
            let result: APIResult<Model> = self.convert(from: baseResult)
            
            self.settings.completionQueue.async {
                completion(result)
            }
            
        }
        
    }
    
    func requestWithoutCache<Model: Codable>(endpoint: EndpointProtocol, completion: @escaping (APIResult<Response<Model>>) -> Void) {
        
        super.request(endpoint: endpoint, isCacheEnabled: false) { [weak self] baseResult in
            
            guard let self = self else { return }
            
            let result: APIResult<Response<Model>> = self.convert(from: baseResult)
            
            self.settings.completionQueue.async {
                completion(result)
            }
            
        }
        
    }
    
}

public extension CNetworkService {
    
    /// Simple HTTP request with cache.
    /// Note you shoud provide cacheKey within EndpointProtocol
    func requestWithCache<Model: Codable>(endpoint: EndpointProtocol, completion: @escaping (APIResult<Model>) -> Void) {
        
        super.requestWithCache(endpoint: endpoint) { [weak self] baseResult in
            
            guard let self = self else { return }
            
            let result: APIResult<Model> = self.convert(from: baseResult)
            
            self.settings.completionQueue.async {
                completion(result)
            }
            
        }
        
    }
    
    
    func requestWithCache<Model: Codable>(endpoint: EndpointProtocol, completion: @escaping (APIResult<Response<Model>>) -> Void) {
        
        super.requestWithCache(endpoint: endpoint) { [weak self] baseResult in
            
            guard let self = self else { return }
            
            let result: APIResult<Response<Model>> = self.convert(from: baseResult)
            
            self.settings.completionQueue.async {
                completion(result)
            }
            
        }
        
    }
    
}
