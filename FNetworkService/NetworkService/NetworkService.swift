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
    
    
    // MARK: - Public methods
    
    public func request<Response>( endpoint: EndpointProtocol,
                                   isCahingEnabled: Bool,
                                   completion: @escaping (APIResult<Response>) -> Void) where Response: Codable
    {
        
        switch isCahingEnabled {
        case false: request(endpoint: endpoint, completion: completion)
        case true: requestWithCache(endpoint: endpoint, completion: completion)
        }
        
    }
    
    
    // MARK: - Simple request without cache
    
    public func request<Response>(
        endpoint: EndpointProtocol,
        completion: @escaping (APIResult<Response>) -> Void) where Response: Decodable
    {
        
        guard let baseUrl = endpoint.baseUrl else {
            completion(APIResult.failure(.noBaseUrl))
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        
        alamofireManager.request(url,
                                 method: endpoint.method,
                                 parameters: endpoint.parameters,
                                 encoding: endpoint.encoding,
                                 headers: endpoint.headers).response { [weak self] response in
                                    
                                    guard let self = self else { return }
                                    
                                    let result: APIResult<Response>
                                    
                                    defer {
                                        DispatchQueue.main.async {
                                            completion(result)
                                        }
                                        self.perfomLogWriting(endpoint: endpoint, result: result)
                                    }
                                    
                                    guard let httpResponse = response.response else {
                                        result = APIResult.failure(APIError.noNetwork)
                                        return
                                    }
                                    
                                    guard (self.settings.validCodes ~= httpResponse.statusCode) else {
                                        let serverError = self.createServerError(from: response)
                                        result = APIResult.failure(serverError)
                                        return
                                    }
                                    
                                    guard let data = response.data else {
                                        let serverError = self.createServerError(from: response)
                                        result = APIResult.failure(serverError)
                                        return
                                    }
                                    
                                    do {
                                        let object = try self.decoder.decode(Response.self, from: data)
                                        result = APIResult.success(object)
                                    } catch {
                                        result = APIResult.failure(.decodingError)
                                    }
                                    
        }
        
    }
    
    
    // MARK: - Request with result caching
    
    public func requestWithCache<Response>(
        endpoint: EndpointProtocol,
        completion: @escaping (APIResult<Response>) -> Void) where Response: Codable {
        
        guard let baseUrl = endpoint.baseUrl else {
            completion(APIResult.failure(.noBaseUrl))
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        
        let cachedResponse: Response? = retrieveCachedResponseIfExists(for: endpoint)
        let cachedResponseExists = (cachedResponse != nil)
        
        var completionCalled = false // To avoid calling completion block twice (with network response and cached response)
        
        alamofireManager.request(url,
                                 method: endpoint.method,
                                 parameters: endpoint.parameters,
                                 encoding: endpoint.encoding,
                                 headers: endpoint.headers).response { [weak self] response in
                                    
                                    guard let self = self else { return }
                                    
                                    let result: APIResult<Response>
                                    
                                    defer {
                                        
                                        DispatchQueue.main.async {
                                            
                                            switch result {
                                                
                                            case .success(let object):
                                                
                                                self.cacheResponseIfNeeded(object, for: endpoint)
                                                
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
                                        
                                        self.perfomLogWriting(endpoint: endpoint, result: result)
                                    }
                                    
                                    guard let httpResponse = response.response else {
                                        result = APIResult.failure(APIError.noNetwork)
                                        return
                                    }
                                    
                                    guard (self.settings.validCodes ~= httpResponse.statusCode) else {
                                        let serverError = self.createServerError(from: response)
                                        result = APIResult.failure(serverError)
                                        return
                                    }
                                    
                                    guard let data = response.data else {
                                        let serverError = self.createServerError(from: response)
                                        result = APIResult.failure(serverError)
                                        return
                                    }
                                    
                                    do {
                                        let object = try self.decoder.decode(Response.self, from: data)
                                        result = APIResult.success(object)
                                    } catch {
                                        result = APIResult.failure(.decodingError)
                                    }
                                    
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + settings.cacheRequestTimeout) {
            
            guard !completionCalled, let cachedResponse = cachedResponse else { return }
            
            completionCalled = true
            completion(.success(cachedResponse))
        }
        
    }
    
    
    // MARK: - Upload request
    
    public func uploadRequest<Response>(
        endpoint: EndpointProtocol,
        data: Data,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (APIResult<Response>) -> Void) where Response: Decodable {
        
        guard let baseUrl = endpoint.baseUrl else {
            completion(APIResult.failure(.noBaseUrl))
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        
        let progressUpdateBlock: (Progress) -> Void = { progress in
            progressHandler?(progress.fractionCompleted)
        }
        
        let responseHandler: (DefaultDataResponse) -> Void = { [weak self] response in
            
            guard let self = self else { return }
            
            let result: APIResult<Response>
            
            defer {
                DispatchQueue.main.async {
                    completion(result)
                }
                self.perfomLogWriting(endpoint: endpoint, result: result)
            }
            
            guard let httpResponse = response.response else {
                result = APIResult.failure(APIError.noNetwork)
                return
            }
            
            guard (self.settings.validCodes ~= httpResponse.statusCode) else {
                let serverError = self.createServerError(from: response)
                result = APIResult.failure(serverError)
                return
            }
            
            guard let data = response.data else {
                let serverError = self.createServerError(from: response)
                result = APIResult.failure(serverError)
                return
            }
            
            do {
                let object = try self.decoder.decode(Response.self, from: data)
                result = APIResult.success(object)
            } catch {
                result = APIResult.failure(.decodingError)
            }
            
        }
        
        alamofireManager.upload(data, to: url,
                                method: endpoint.method,
                                headers: endpoint.headers)
            .uploadProgress(queue: DispatchQueue.main, closure: progressUpdateBlock)
            .response(completionHandler: responseHandler)
        
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
    
    
    // MARK: - Helper methods
    
    private func createServerError(from response: DefaultDataResponse) -> APIError {
        return APIError.serverError(error: response.error, response: response.response, data: response.data)
    }
    
    private func perfomLogWriting<T>(endpoint: EndpointProtocol, result: APIResult<T>) {
        
        DispatchQueue.global(qos: .background).async {
            self.writeLogsIfNeeded(using: self.networkLogger, with: endpoint, and: result)
            self.writeLogsIfNeeded(using: self.debugLogger, with: endpoint, and: result)
        }
        
    }
    
    private func writeLogsIfNeeded<T>(using logger: NetworkLogWriter?,
                                      with endpoint: EndpointProtocol,
                                      and result: APIResult<T>)
    {
        
        guard let logger = logger else { return }
        
        switch logger.writeOptions {
            
        case .all:
            logger.write(endpoint: endpoint, result: result)
            
        case .onSuccess:
            guard result.isSuccess else { return }
            logger.write(endpoint: endpoint, result: result)
            
        case .onError:
            guard result.isFailure else { return }
            logger.write(endpoint: endpoint, result: result)

        case .none:
            return
            
        }
        
    }
    
}
