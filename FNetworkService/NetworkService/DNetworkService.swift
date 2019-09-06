//
//  DNetworkService.swift
//  FNetworkService
//
//  Created by Eugene on 06/09/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

import Alamofire

// MARK: - Network Service Implementation
public class DNetworkService: BaseNetworkService, NetworkServiceProtocol {
    
    // MARK: - NetworkServiceProtocol
    
    public typealias Success = DecodableResponse
    
    public func parse(_ response: DefaultDataResponse) -> APIResult<DecodableResponse> {
        
        let result: APIResult<DecodableResponse>
        
        guard let httpResponse = response.response else {
            result = APIResult.failure(APIError.noNetwork)
            return result
        }
        
        guard (self.settings.validCodes ~= httpResponse.statusCode) else {
            let serverError = self.createServerError(from: response)
            result = APIResult.failure(serverError)
            return result
        }
        
        guard let data = response.data else {
            let serverError = self.createServerError(from: response)
            result = APIResult.failure(serverError)
            return result
        }
        
        do {
            let object = try self.decoder.decode(Response.self, from: data)
            result = APIResult.success(object)
        } catch {
            result = APIResult.failure(.decodingError)
            performDegubLogIfMatch(writeOptions: .all, .onError, text: String(data: data, encoding: .utf8) ?? "Reponse data is empty!")
        }
        
        return result
        
    }
    
    public func request(endpoint: EndpointProtocol, isCaheEnabled: Bool, completion: @escaping (APIResult<DecodableResponse>) -> Void) {
        
        guard let _ ensureBaseUrlProvided(endpoint: endpoint) else { completion(.failure(.noBaseUrl)); return }
        
        switch isCaheEnabled {
        case true:
            
        case false:
            break
        }
        
    }
    
    /// Simple HTTP request without cache
    func requestWOCache(endpoint: EndpointProtocol, completion: @escaping (APIResult<Response>) -> Void) where Response: Decodable {
        
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
                                    
                                    let result: APIResult<Response> = self.parse(response: response)
                                    
                                    DispatchQueue.main.async {
                                        completion(result)
                                    }
                                    
                                    self.perfomLogWriting(endpoint: endpoint, result: result)
                                    
        }
        
    }
    
    private func createServerError(from response: DefaultDataResponse) -> APIError {
        return APIError.serverError(error: response.error, response: response.response, data: response.data)
    }
    
    
    // MARK: - Cache helpers
    
//    private func retrieveCachedResponseIfExists<Response: Codable>(for endpoint: EndpointProtocol) -> Response? {
//        guard let cacheKey = endpoint.cacheKey else { return nil }
//        return cacheStorage.retrieveValue(for: cacheKey)
//    }
//
//    private func cacheResponseIfNeeded<Response: Codable>(_ response: Response, for endpoint: EndpointProtocol) {
//        guard let cacheKey = endpoint.cacheKey else { return }
//        cacheStorage.save(response, for: cacheKey)
//    }
//
//
//    // MARK: - Logger helpers
//
//    private func perfomLogWriting<T>(endpoint: EndpointProtocol, result: APIResult<T>) {
//
//        DispatchQueue.global(qos: .background).async { [weak self] in
//            self?.networkLogger?.write(endpoint: endpoint, result: result)
//            self?.debugLogger.write(endpoint: endpoint, result: result)
//        }
//
//    }
//
//    private func performDegubLogIfMatch(writeOptions: LoggerWriteOptions..., text: String) {
//
//        guard writeOptions.contains(debugLogger.writeOptions) else { return }
//
//        DispatchQueue.global(qos: .background).async { [weak self] in
//            self?.debugLogger.write(log: text)
//        }
//
//    }
    
}


// MARK: - Simple HTTP request with cache // TODO refactoring
public extension NetworkService {
    
    /// Simple HTTP request with cache.
    /// Note you shoud provide cacheKey within EndpointProtocol
    func requestWithCache<Response: Codable>(endpoint: EndpointProtocol, completion: @escaping (APIResult<Response>) -> Void) {
        
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
                                    
                                    let result: APIResult<Response> = self.parse(response: response)
                                    
                                    DispatchQueue.main.async {
                                        
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
                                    
                                    self.perfomLogWriting(endpoint: endpoint, result: result)
                                    
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + settings.cacheRequestTimeout) {
            
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
            completion(APIResult.failure(.noBaseUrl))
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        
        let progressUpdateBlock: (Progress) -> Void = { progress in
            progressHandler?(progress.fractionCompleted)
        }
        
        let responseHandler: (DefaultDataResponse) -> Void = { [weak self] response in
            
            guard let self = self else { return }
            
            let result: APIResult<Response> = self.parse(response: response)
            
            DispatchQueue.main.async {
                completion(result)
            }
            
            self.perfomLogWriting(endpoint: endpoint, result: result)
            
        }
        
        alamofireManager.upload(data, to: url,
                                method: endpoint.method,
                                headers: endpoint.headers)
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
                                    
                                    let result: APIResult<ModelWithResponse<Response>>
                                    
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
                                        let model = ModelWithResponse(model: object,
                                                                      response: response.response)
                                        result = APIResult.success(model!)
                                    } catch {
                                        result = APIResult.failure(.decodingError)
                                    }
                                    
        }
        
    }
    
    
    // MARK: - Request with result caching
    
    func cachebleRequestWithHTTPResponse<Response>(
        endpoint: EndpointProtocol,
        completion: @escaping (APIResult<ModelWithResponse<Response>>) -> Void) where Response: Codable {
        
        guard let baseUrl = endpoint.baseUrl else {
            completion(APIResult.failure(.noBaseUrl))
            return
        }
        
        let url = baseUrl.appendingPathComponent(endpoint.path)
        
        let cachedObject: Response? = retrieveCachedResponseIfExists(for: endpoint)
        let cachedModel = ModelWithResponse(model: cachedObject, response: nil)
        
        let cachedResponseExists = (cachedModel != nil)
        
        var completionCalled = false // To avoid calling completion block twice (with network response and cached response)
        
        alamofireManager.request(url,
                                 method: endpoint.method,
                                 parameters: endpoint.parameters,
                                 encoding: endpoint.encoding,
                                 headers: endpoint.headers).response { [weak self] response in
                                    
                                    guard let self = self else { return }
                                    
                                    let result: APIResult<ModelWithResponse<Response>>
                                    
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
                                        let model = ModelWithResponse(model: object, response: response.response)
                                        result = APIResult.success(model!)
                                    } catch {
                                        result = APIResult.failure(.decodingError)
                                    }
                                    
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + settings.cacheRequestTimeout) {
            
            guard !completionCalled, let cachedResponse = cachedModel else { return }
            
            completionCalled = true
            completion(.success(cachedResponse))
        }
        
    }
    
}
