//
//  NetworkService.swift
//
//  Created by ALEXANDER ANTONOV on 17/11/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation
import Alamofire

public typealias NetworkServiceProtocol = NetworkRequestable & ResponseParser

// MARK: - Network Service Implementation
open class NetworkService: NetworkServiceProtocol {
    
    // MARK: - Init
    
    public init(settings: Settings = Settings.default) {
        
        self.settings = settings
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = settings.requestTimeout
        self.alamofireManager = Alamofire.SessionManager(configuration: sessionConfiguration)
        
        self.cacheStorage = GenericStorage()
    }
    
    
    // MARK: - Properties
    
    public let settings: Settings

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
    
    
    // MARK: - ResponseParser
    
    open func parse(response: DefaultDataResponse, forEndpoint endpoint: EndpointProtocol) -> APIResult<Data> {
        return rawParse(response: response, settings: settings)
    }
    
    open func parse<Response: Decodable>(response: DefaultDataResponse, forEndpoint endpoint: EndpointProtocol) -> APIResult<Response> {
        
        let dataResult = rawParse(response: response, settings: settings)
        guard let data = dataResult.value else { return .failure(dataResult.error!) }
        
        do {
            let object = try self.settings.decoder.decode(Response.self, from: data)
            return APIResult.success(object)
        } catch {
            return APIResult.failure(.decodingError)
        }
        
    }
    
    open func parse<Response: Decodable>(response: DefaultDataResponse, forEndpoint endpoint: EndpointProtocol) -> APIXResult<Response> {
        
        let dataResult = rawParse(response: response, settings: settings)
        guard let data = dataResult.value else { return .failure(dataResult.error!) }
        
        do {
            let object = try self.settings.decoder.decode(Response.self, from: data)
            return APIXResult.success(ModelWithResponse<Response>(model: object, response: response.response))
        } catch {
            return APIResult.failure(.decodingError)
        }
        
    }
    

    // MARK: - ResponseParser helpers
    
    private func rawParse(response: DefaultDataResponse, settings: NetworkService.Settings) -> APIResult<Data> {
        
        if let error = response.error, (error as NSError).code == Locals.timeoutStatusCode {
            return APIResult.failure(.requestTimeout)
        }
        
        guard let httpResponse = response.response else {
            return APIResult.failure(APIError.noNetwork)
        }
        
        guard (settings.validCodes ~= httpResponse.statusCode) else {
            let serverError = self.createServerError(from: response)
            return APIResult.failure(serverError)
        }
        
        guard let data = response.data else {
            let serverError = self.createServerError(from: response)
            return APIResult.failure(serverError)
        }
        
        return .success(data)
    }
    
    func createServerError(from response: DefaultDataResponse) -> APIError {
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
            self?.settings.networkLogger?.write(endpoint: endpoint, result: result, data: data)
            self?.settings.debugLogger?.write(endpoint: endpoint, result: result, data: data)
        }
        
    }
    
    
    // MARK: - NetworkRequestable
    
    // MARK: - Simple HTTP request with raw Data Result without cache
    open func request(endpoint: EndpointProtocol, completion: @escaping(APIResult<Data>) -> Void) {
        
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
                                    
                                    let result: APIResult<Data> = self.parse(response: response, forEndpoint: endpoint)
                                    
                                    self.settings.completionQueue.async {
                                        completion(result)
                                    }
                                    
                                    self.perfomLogWriting(endpoint: endpoint, result: result, data: response.data)
                                    
        }
        
    }
    
    
    // MARK: - Simple HTTP request without cache
    open func request<Response: Decodable>(endpoint: EndpointProtocol, completion: @escaping (APIResult<Response>) -> Void) {
        
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
                                    
                                    let result: APIResult<Response> = self.parse(response: response, forEndpoint: endpoint)
                                    
                                    self.settings.completionQueue.async {
                                        completion(result)
                                    }
                                    
                                    self.perfomLogWriting(endpoint: endpoint, result: result, data: response.data)
                                    
        }
        
    }
    
    
    // MARK: - Simple HTTP request with cache
    open func requestWithCache<Response: Codable>(endpoint: EndpointProtocol, completion: @escaping (APIResult<Response>) -> Void) {
        
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
                                    
                                    let result: APIResult<Response> = self.parse(response: response, forEndpoint: endpoint)
                                    
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
    
    
    // MARK: - Upload Request
    open func uploadRequest<Response>(
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
            
            let result: APIResult<Response> = self.parse(response: response, forEndpoint: endpoint)
            
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
    
    
    // MARK: - Request with boxed Response into `ModelWithResponse`, no cache
    open func request<Response: Decodable>(endpoint: EndpointProtocol, completion: @escaping (APIXResult<Response>) -> Void) {
        
        guard let baseUrl = endpoint.baseUrl else {
            settings.completionQueue.async {
                completion(APIXResult.failure(.noBaseUrl))
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
                                    
                                    let result: APIXResult<Response> = self.parse(response: response, forEndpoint: endpoint)
                                    
                                    self.settings.completionQueue.async {
                                        completion(result)
                                    }
                                    
                                    self.perfomLogWriting(endpoint: endpoint, result: result, data: response.data)
                                    
        }
        
    }
    
    
    // MARK: - Request with boxed Response into `ModelWithResponse`, with cache
    open func requestWithCache<Response: Codable>(endpoint: EndpointProtocol, completion: @escaping (APIXResult<Response>) -> Void) {
        
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
                                    
                                    let result: APIXResult<Response> = self.parse(response: response, forEndpoint: endpoint)
                                    
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
