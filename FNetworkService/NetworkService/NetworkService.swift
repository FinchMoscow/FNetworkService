//
//  NetworkService.swift
//
//  Created by ALEXANDER ANTONOV on 17/11/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Network Service Implementation
public class NetworkService {
    
    // MARK: - Init
    
    public init(settings: Settings = Settings.default) {
        
        self.settings = settings
        self.networkLogger = settings.networkLogger
        self.debugLogger = settings.debugLogger
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = settings.dateDecodingStrategy
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = settings.requestTimeout
        self.alamofireManager = Alamofire.SessionManager(configuration: sessionConfiguration)
        
        self.cacheStorage = GenericStorage()
    }
    
    
    // MARK: - Properties
    
    private let debugLogger: NetworkLogWriter?
    private let networkLogger: NetworkLogWriter?
    private let settings: Settings
    private let decoder: JSONDecoder
    private let alamofireManager: SessionManager
    private let cacheStorage: Storage
    
    
    // MARK: - Private methods
    
    private func mergeHeaders(endpointHeaders: HTTPHeaders?) -> HTTPHeaders? {
        
        guard var endpointHeaders = endpointHeaders else { return settings.requestSettings.additionalHeaders }
        guard let additionalHeaders = settings.requestSettings.additionalHeaders else { return endpointHeaders }
        
        additionalHeaders.forEach({ key, value in
            endpointHeaders.updateValue(value, forKey: key)
        })
        
        return endpointHeaders
    }
    
    
    // MARK: - Requests helpers
    
    private func parse<Response: Decodable>(response: DefaultDataResponse) -> APIResult<Response> {
        
        guard let httpResponse = response.response else {
            return APIResult.failure(APIError.noNetwork)
        }
        
        guard httpResponse.statusCode != Locals.timeoutStatusCode else {
            return APIResult.failure(.requestTimeout)
        }
        
        guard (self.settings.validCodes ~= httpResponse.statusCode) else {
            let serverError = self.createServerError(from: response)
            return APIResult.failure(serverError)
        }
        
        guard let data = response.data else {
            let serverError = self.createServerError(from: response)
            return APIResult.failure(serverError)
        }
        
        do {
            let object = try self.decoder.decode(Response.self, from: data)
            return APIResult.success(object)
        } catch {
            return APIResult.failure(.decodingError)
        }
        
    }
    
    private func parse<Response: Decodable>(response: DefaultDataResponse) -> APIResult<ModelWithResponse<Response>> {
        
        let baseResult: APIResult<Response> = parse(response: response)
        guard let payload = baseResult.value else { return .failure(baseResult.error!)  }
        return APIResult.success(ModelWithResponse<Response>(model: payload, response: response.response))
    }
    
    private func createServerError(from response: DefaultDataResponse) -> APIError {
        return APIError.serverError(error: response.error, response: response.response, data: response.data)
    }
    
    
    // MARK: - Cache helpers
    
    private func retrieveCachedResponseIfExists<Response: Codable>(for endpoint: EndpointProtocol) -> Response? {
        guard let cacheKey = endpoint.cacheKey else { return nil }
        return cacheStorage.retrieveValue(for: cacheKey)
    }
    
    private func cacheResponseIfNeeded<Response: Codable>(_ response: Response, for endpoint: EndpointProtocol) {
        guard let cacheKey = endpoint.cacheKey else { return }
        cacheStorage.save(response, for: cacheKey)
    }
    
    
    // MARK: - Logger helpers
    
    private func perfomLogWriting<T>(endpoint: EndpointProtocol, result: APIResult<T>, data: Data?) {
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.networkLogger?.write(endpoint: endpoint, result: result, data: data)
            self?.debugLogger?.write(endpoint: endpoint, result: result, data: data)
        }
        
    }
    
}


// MARK: - Public Convenience methods
public extension NetworkService {
    
    func request<Response>( endpoint: EndpointProtocol,
                            isCahingEnabled: Bool,
                            completion: @escaping (APIResult<Response>) -> Void) where Response: Codable
    {
        
        switch isCahingEnabled {
        case false: request(endpoint: endpoint, completion: completion)
        case true: requestWithCache(endpoint: endpoint, completion: completion)
        }
        
    }
    
    
    func requestWithHTTPResponse<Response>( endpoint: EndpointProtocol,
                                            isCahingEnabled: Bool,
                                            completion: @escaping (APIResult<ModelWithResponse<Response>>) -> Void) where Response: Codable
    {
        switch isCahingEnabled {
        case false: requestWithHTTPResponse(endpoint: endpoint, completion: completion)
        case true: cachebleRequestWithHTTPResponse(endpoint: endpoint, completion: completion)
        }
        
    }
    
}


// MARK: - Simple HTTP request without cache
public extension NetworkService {
    
    /// Simple HTTP request without cache
    func request<Response>(endpoint: EndpointProtocol, completion: @escaping (APIResult<Response>) -> Void) where Response: Decodable {
        
        guard let baseUrl = endpoint.baseUrl else {
            settings.completionQueue.async {
                completion(APIResult.failure(.noBaseUrl))
            }
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        let headers = mergeHeaders(endpointHeaders: endpoint.headers)
        
        alamofireManager.request(url,
                                 method: endpoint.method,
                                 parameters: endpoint.parameters,
                                 encoding: endpoint.encoding,
                                 headers: headers).response { [weak self] response in
                                    
                                    guard let self = self else { return }
                                    
                                    let result: APIResult<Response> = self.parse(response: response)
                                    
                                    self.settings.completionQueue.async {
                                        completion(result)
                                    }
                                    
                                    self.perfomLogWriting(endpoint: endpoint, result: result, data: response.data)
                                    
        }
        
    }
    
}


// MARK: - Simple HTTP request with cache // TODO refactoring
public extension NetworkService {
    
    /// Simple HTTP request with cache.
    /// Note you shoud provide cacheKey within EndpointProtocol
    func requestWithCache<Response: Codable>(endpoint: EndpointProtocol, completion: @escaping (APIResult<Response>) -> Void) {
        
        guard let baseUrl = endpoint.baseUrl else {
            settings.completionQueue.async {
                completion(APIResult.failure(.noBaseUrl))
            }
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        let headers = mergeHeaders(endpointHeaders: endpoint.headers)
        
        let cachedResponse: Response? = retrieveCachedResponseIfExists(for: endpoint)
        let cachedResponseExists = (cachedResponse != nil)
        
        var completionCalled = false // To avoid calling completion block twice (with network response and cached response)
        
        alamofireManager.request(url,
                                 method: endpoint.method,
                                 parameters: endpoint.parameters,
                                 encoding: endpoint.encoding,
                                 headers: headers).response { [weak self] response in
                                    
                                    guard let self = self else { return }
                                    
                                    let result: APIResult<Response> = self.parse(response: response)
                                    
                                    self.settings.completionQueue.async {
                                        
                                        switch result {
                                            
                                        case .success(let object):
                                            
                                            self.cacheResponseIfNeeded(object, for: endpoint)
                                            
                                            if !completionCalled {
                                                completionCalled = true
                                                completion(result)
                                            }
                                            
                                        case .failure:
                                            
                                            if !completionCalled && !cachedResponseExists {
                                                completionCalled = true
                                                completion(result)
                                            }
                                        }
                                        
                                    }
                                    
                                    self.perfomLogWriting(endpoint: endpoint, result: result, data: response.data)
                                    
        }
        
        settings.completionQueue.asyncAfter(deadline: .now() + settings.cacheRequestTimeout) {
            
            guard !completionCalled, let cachedResponse = cachedResponse else { return }
            
            completionCalled = true
            completion(.success(cachedResponse))
        }
        
    }
    
}


// MARK: - Upload Request
public extension NetworkService {
    
    func uploadRequest<Response>(
        endpoint: EndpointProtocol,
        data: Data,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (APIResult<Response>) -> Void) where Response: Decodable {
        
        guard let baseUrl = endpoint.baseUrl else {
            settings.completionQueue.async {
                completion(APIResult.failure(.noBaseUrl))
            }
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        let headers = mergeHeaders(endpointHeaders: endpoint.headers)
        
        let progressUpdateBlock: (Progress) -> Void = { progress in
            progressHandler?(progress.fractionCompleted)
        }
        
        let responseHandler: (DefaultDataResponse) -> Void = { [weak self] response in
            
            guard let self = self else { return }
            
            let result: APIResult<Response> = self.parse(response: response)
            
            self.settings.completionQueue.async {
                completion(result)
            }
            
            self.perfomLogWriting(endpoint: endpoint, result: result, data: response.data)
            
        }
        
        alamofireManager.upload(data, to: url,
                                method: endpoint.method,
                                headers: headers)
            .uploadProgress(queue: DispatchQueue.main, closure: progressUpdateBlock)
            .response(completionHandler: responseHandler)
        
    }
    
}


// MARK: - Request with boxed Codable and HTTPURLResponse
public extension NetworkService {
    
    
    // MARK: - Simple request without cache
    
    func requestWithHTTPResponse<Response>(
        endpoint: EndpointProtocol,
        completion: @escaping (APIResult<ModelWithResponse<Response>>) -> Void) where Response: Decodable {
        
        guard let baseUrl = endpoint.baseUrl else {
            settings.completionQueue.async {
                completion(APIResult.failure(.noBaseUrl))
            }
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        let headers = mergeHeaders(endpointHeaders: endpoint.headers)
        
        alamofireManager.request(url,
                                 method: endpoint.method,
                                 parameters: endpoint.parameters,
                                 encoding: endpoint.encoding,
                                 headers: headers).response { [weak self] response in
                                    
                                    guard let self = self else { return }
                                    
                                    let result: APIResult<ModelWithResponse<Response>> = self.parse(response: response)
                                    
                                    self.settings.completionQueue.async {
                                        completion(result)
                                    }
                                    
                                    self.perfomLogWriting(endpoint: endpoint, result: result, data: response.data)
                                    
        }
        
    }
    
    
    // MARK: - Request with result caching
    
    func cachebleRequestWithHTTPResponse<Response>(
        endpoint: EndpointProtocol,
        completion: @escaping (APIResult<ModelWithResponse<Response>>) -> Void) where Response: Codable {
        
        guard let baseUrl = endpoint.baseUrl else {
            settings.completionQueue.async {
                completion(APIResult.failure(.noBaseUrl))
            }
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        let headers = mergeHeaders(endpointHeaders: endpoint.headers)
        
        let cachedObject: Response? = retrieveCachedResponseIfExists(for: endpoint)
        let cachedResponseExists = (cachedObject != nil)
        
        var completionCalled = false // To avoid calling completion block twice (with network response and cached response)
        
        alamofireManager.request(url,
                                 method: endpoint.method,
                                 parameters: endpoint.parameters,
                                 encoding: endpoint.encoding,
                                 headers: headers).response { [weak self] response in
                                    
                                    guard let self = self else { return }
                                    
                                    let result: APIResult<ModelWithResponse<Response>> = self.parse(response: response)
                                    
                                    defer {
                                        
                                        DispatchQueue.main.async {
                                            
                                            switch result {
                                                
                                            case .success(let object):
                                                
                                                self.cacheResponseIfNeeded(object.model, for: endpoint)
                                                
                                                if !completionCalled {
                                                    completionCalled = true
                                                    completion(result)
                                                }
                                                
                                            case .failure(let error):
                                                
                                                if !completionCalled && !cachedResponseExists {
                                                    completionCalled = true
                                                    completion(result)
                                                }
                                            }
                                            
                                        }
                                        
                                        self.perfomLogWriting(endpoint: endpoint, result: result, data: response.data)
                                    }
                                    
                                    self.perfomLogWriting(endpoint: endpoint, result: result, data: response.data)
                                    
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + settings.cacheRequestTimeout) {
            
            guard !completionCalled, let cachedResponse = cachedObject else { return }
            
            completionCalled = true
            completion(.success(ModelWithResponse<Response>(model: cachedResponse, response: nil)))
        }
        
    }
    
}


// MARK: - Locals
private extension NetworkService {
    
    struct Locals {
        
        static let timeoutStatusCode = -1001
        
    }
    
}
