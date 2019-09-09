//
//  BaseNetworkService.swift
//  FNetworkService
//
//  Created by Eugene on 06/09/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

import Alamofire

public class BaseNetworkService {
    
    // MARK: - Public methods
    
    public func request(endpoint: EndpointProtocol, isCacheEnabled: Bool, completion: @escaping (APIResult<BaseDataResponse>) -> Void) {
        
        switch isCacheEnabled {
            
        case true:
            requestWithCache(endpoint: endpoint, completion: completion)
            
        case false:
            requestWithoutCache(endpoint: endpoint, completion: completion)
            
        }
        
    }
    
    public func uploadRequest(endpoint: EndpointProtocol, data: Data, progressHandler: ((Double) -> Void)?, completion: @escaping (APIResult<BaseDataResponse>) -> Void) {
        
        guard let baseURL = endpoint.baseUrl else {
            let result = APIResult<BaseDataResponse>.failure(.noBaseUrl)
            completion(result)
            perfomLogWriting(endpoint: endpoint, result: result)
            return
        }
        
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        let progressUpdateBlock: (Progress) -> Void = { progress in
            progressHandler?(progress.fractionCompleted)
        }
        
        let responseHandler: (DefaultDataResponse) -> Void = { [weak self] response in
            
            guard let self = self else { return }
            
            let result: APIResult<BaseDataResponse> = self.parse(response)
            
            completion(result)
            
            self.perfomLogWriting(endpoint: endpoint, result: result)
        }
        
        alamofireManager.upload(data, to: url,
                                method: endpoint.method,
                                headers: endpoint.headers)
            .uploadProgress(queue: DispatchQueue.main, closure: progressUpdateBlock)
            .response(completionHandler: responseHandler)
        
    }
    
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
    
    
    // MARK: - Internal Properties
    
    let debugLogger: NetworkLogWriter
    let networkLogger: NetworkLogWriter?
    let settings: Settings
    let decoder: JSONDecoder
    let alamofireManager: SessionManager
    let cacheStorage: Storage
    
    
    // Internal methods
    
    func createServerError(from response: DefaultDataResponse) -> APIError {
        return APIError.serverError(error: response.error, response: response.response, data: response.data)
    }
    
    // MARK: - Cache helpers
    
     func retrieveCachedResponseIfExists(for endpoint: EndpointProtocol) -> BaseDataResponse? {
        guard let cacheKey = endpoint.cacheKey else { return nil }
        return cacheStorage.retrieveValue(for: cacheKey)
    }
    
     func cacheResponseIfNeeded(_ response: BaseDataResponse, for endpoint: EndpointProtocol) {
        guard let cacheKey = endpoint.cacheKey else { return }
        cacheStorage.save(response, for: cacheKey)
    }
    
    
    // MARK: - Logger helpers
    
    func perfomLogWriting<T>(endpoint: EndpointProtocol, result: APIResult<T>) {
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.networkLogger?.write(endpoint: endpoint, result: result)
            self?.debugLogger.write(endpoint: endpoint, result: result)
        }
        
    }
    
    // MARK: - Private methods
    
    private func parse(_ response: DefaultDataResponse) -> APIResult<BaseDataResponse> {
        
        let result: APIResult<BaseDataResponse>
        
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
        
        return .success(BaseDataResponse(httpMeta: httpResponse, payload: data))
    }
    
}


// Public convenience methods
extension BaseNetworkService {
    
    public func request(endpoint: EndpointProtocol, completion: @escaping (APIResult<BaseDataResponse>) -> Void) {
        request(endpoint: endpoint, isCacheEnabled: false, completion: completion)
    }
    
    public func uploadRequest(endpoint: EndpointProtocol, data: Data, completion: @escaping (APIResult<BaseDataResponse>) -> Void) {
        uploadRequest(endpoint: endpoint, data: data, progressHandler: nil, completion: completion)
    }
    
}


extension BaseNetworkService {
    
    /// Simple HTTP request without cache
    func requestWithoutCache(endpoint: EndpointProtocol, completion: @escaping (APIResult<BaseDataResponse>) -> Void) {
        
        guard let baseURL = endpoint.baseUrl else {
            let result = APIResult<BaseDataResponse>.failure(.noBaseUrl)
            completion(result)
            perfomLogWriting(endpoint: endpoint, result: result)
            return
        }
        
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        alamofireManager.request(url,
                                 method: endpoint.method,
                                 parameters: endpoint.parameters,
                                 encoding: endpoint.encoding,
                                 headers: endpoint.headers).response { [weak self] response in
                                    
                                    guard let self = self else { return }
                                    
                                    let result = self.parse(response)
                                    
                                    completion(result)
                                    
                                    self.perfomLogWriting(endpoint: endpoint, result: result)
                                    
        }
        
    }
    
}

extension BaseNetworkService {
    
    /// Simple HTTP request with cache.
    /// Note you shoud provide cacheKey within EndpointProtocol
    func requestWithCache(endpoint: EndpointProtocol, completion: @escaping (APIResult<BaseDataResponse>) -> Void) {
        
        guard let baseURL = endpoint.baseUrl else {
            let result = APIResult<BaseDataResponse>.failure(.noBaseUrl)
            completion(result)
            perfomLogWriting(endpoint: endpoint, result: result)
            return
        }
        
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        let cachedResponse = retrieveCachedResponseIfExists(for: endpoint)
        let cachedResponseExists = (cachedResponse != nil)
        
        var completionCalled = false // To avoid calling completion block twice (with network response and cached response)
        
        alamofireManager.request(url,
                                 method: endpoint.method,
                                 parameters: endpoint.parameters,
                                 encoding: endpoint.encoding,
                                 headers: endpoint.headers).response { [weak self] response in
                                    
                                    guard let self = self else { return }
                                    
                                    let result: APIResult<BaseDataResponse> = self.parse(response)
                                    
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


public extension BaseNetworkService {
    
    struct Settings {
        
        public var validCodes = (200 ..< 300)
        public var cacheRequestTimeout: TimeInterval = 0.3
        public var requestTimeout: TimeInterval = 10
        public var dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.millisecondsSince1970
        public var networkLogger: NetworkLogWriter? = Settings.defaultLogger
        public var debugLogger: NetworkLogWriter = Settings.defaultDebugLogger
        public var completionQueue: DispatchQueue = .main
        
        
        // MARK: - Singleton
        
        public static var `default`: Settings {
            return Settings()
        }
        
        private init() { }
        
        
        // MARK: - Project settings
        
        /// Implement and assign your logger, it'll be used by every instance as default.
        /// In order to change logger in particular NetworkService you may use `init(settings: NetworkService.Settings)`
        public static var defaultLogger: NetworkLogWriter?
        
        /// Implement and assign your debug logger if needed.
        /// In order to change debug logger in particular NetworkService you may use `init(settings: NetworkService.Settings)`
        public static var defaultDebugLogger: NetworkLogWriter = DebugLogWriter()
    }
    
}
