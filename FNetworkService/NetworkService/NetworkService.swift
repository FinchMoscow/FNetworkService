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
    
    public init(logger: NetworkLogsWriter? = nil, settings: NetworkSettings = NetworkSettings.default) {
        
        self.settings = settings
        self.logger = logger
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = settings.dateDecodingStrategy
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = settings.requestTimeout
        sessionConfiguration.timeoutIntervalForResource = settings.resourceTimeout
        self.alamofireManager = Alamofire.SessionManager(configuration: sessionConfiguration)
        
        self.cacheStorage = GenericStorage()
    }
    
    
    // MARK: - Properties
    
    private let logger: NetworkLogsWriter?
    private let settings: NetworkSettings
    private let decoder: JSONDecoder
    private let alamofireManager: SessionManager
    private let cacheStorage: Storage
    
    
    // MARK: - Public methods
    
    // MARK: - Simple request without cache
    
    public func request<Response>(
        endpoint: EndpointProtocol,
        completion: @escaping (Result<Response>) -> Void) where Response: Decodable {
        
        guard let baseUrl = endpoint.baseUrl else {
            completion(Result.failure(.noBaseUrl))
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        
        alamofireManager.request(url, method: endpoint.method,
                                 parameters: endpoint.parameters,
                                 encoding: endpoint.encoding,
                                 headers: endpoint.headers).response { [weak self] response in
                                    
                                    guard let self = self else { return }
                                    
                                    let result: Result<Response>
                                    
                                    defer {
                                        DispatchQueue.main.async {
                                            completion(result)
                                            self.writeLogsIfNeeded(with: endpoint, and: result)
                                        }
                                    }
                                    
                                    guard let httpResponse = response.response else {
                                        result = Result.failure(APIError.noNetwork)
                                        return
                                    }
                                    
                                    guard (self.settings.validCodes ~= httpResponse.statusCode) else {
                                        let serverError = self.createServerError(from: response)
                                        result = Result.failure(serverError)
                                        return
                                    }
                                    
                                    self.printStatusCodeIfEnabled(httpResponse.statusCode)
                                    
                                    guard let data = response.data else {
                                        let serverError = self.createServerError(from: response)
                                        result = Result.failure(serverError)
                                        return
                                    }
                                    
                                    self.printResponseIfEnabled(data)
                                    
                                    do {
                                        let object = try self.decoder.decode(Response.self, from: data)
                                        result = Result.success(object)
                                    } catch {
                                        result = Result.failure(.decodingError)
                                    }
                                    
        }
        
    }
    
    
    // MARK: - Request with result caching
    
    private func requestWithCache<Response>(
        endpoint: EndpointProtocol,
        completion: @escaping (Result<Response>) -> Void) where Response: Codable {
        
        guard let baseUrl = endpoint.baseUrl else {
            completion(Result.failure(.noBaseUrl))
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        
        let cachedResponse: Response? = retrieveCachedResponseIfExists(for: endpoint)
        let cachedResponseExists = (cachedResponse != nil)
        
        var completionCalled = false // To avoid calling completion block twice (with network response and cached response)
        
        alamofireManager.request(url, method: endpoint.method,
                                 parameters: endpoint.parameters,
                                 encoding: endpoint.encoding,
                                 headers: endpoint.headers).response { [weak self] response in
                                    
                                    guard let self = self else { return }
                                    
                                    let result: Result<Response>
                                    
                                    defer {
                                        
                                        DispatchQueue.main.async {
                                            
                                            self.writeLogsIfNeeded(with: endpoint, and: result)
                                            
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
                                        
                                    }
                                    
                                    guard let httpResponse = response.response else {
                                        result = Result.failure(APIError.noNetwork)
                                        return
                                    }
                                    
                                    guard (self.settings.validCodes ~= httpResponse.statusCode) else {
                                        let serverError = self.createServerError(from: response)
                                        result = Result.failure(serverError)
                                        return
                                    }
                                    
                                    self.printStatusCodeIfEnabled(httpResponse.statusCode)
                                    
                                    guard let data = response.data else {
                                        let serverError = self.createServerError(from: response)
                                        result = Result.failure(serverError)
                                        return
                                    }
                                    
                                    self.printResponseIfEnabled(data)
                                    
                                    do {
                                        let object = try self.decoder.decode(Response.self, from: data)
                                        result = Result.success(object)
                                    } catch {
                                        result = Result.failure(.decodingError)
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
        endpoint: EndpointProtocol, data: Data,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Result<Response>) -> Void) where Response: Decodable {
        
        guard let baseUrl = endpoint.baseUrl else {
            completion(Result.failure(.noBaseUrl))
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        
        let progressUpdateBlock: (Progress) -> Void = { progress in
            progressHandler?(progress.fractionCompleted)
        }
        
        let responseHandler: (DefaultDataResponse) -> Void = { [weak self] response in
            
            guard let self = self else { return }
            
            let result: Result<Response>
            
            defer {
                DispatchQueue.main.async {
                    completion(result)
                    self.writeLogsIfNeeded(with: endpoint, and: result)
                }
            }
            
            guard let httpResponse = response.response else {
                result = Result.failure(APIError.noNetwork)
                return
            }
            
            guard (self.settings.validCodes ~= httpResponse.statusCode) else {
                let serverError = self.createServerError(from: response)
                result = Result.failure(serverError)
                return
            }
            
            self.printStatusCodeIfEnabled(httpResponse.statusCode)
            
            guard let data = response.data else {
                let serverError = self.createServerError(from: response)
                result = Result.failure(serverError)
                return
            }
            
            self.printResponseIfEnabled(data)
            
            do {
                let object = try self.decoder.decode(Response.self, from: data)
                result = Result.success(object)
            } catch {
                result = Result.failure(.decodingError)
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
    
    private func writeLogsIfNeeded<T>(with endPoint: EndpointProtocol, and result: Result<T>) {
        
        guard let logger = logger else { return }
        
        switch logger.writeOptions {
            
        case .onError:
            guard result.isFailure else { return }
            logger.write(endpoint: endPoint, result: result)
            
        case .onSuccess:
            guard result.isSuccess else { return }
            logger.write(endpoint: endPoint, result: result)
            
        case .all:
            logger.write(endpoint: endPoint, result: result)
        }
        
    }
    
    private func printResponseIfEnabled(_ data: Data) {
        
        guard FSettings.isDebugPrintEnabled else { return }
        
        let text = String(data: data, encoding: .utf8) ?? "Error occured while to converting Data to String!"
        print("JSON DATA = \(text)")
    }
    
    private func printStatusCodeIfEnabled(_ statusCode: Int) {
        
        guard FSettings.isDebugPrintEnabled else { return }
        print("status code = \(statusCode)")
    }
    
}
