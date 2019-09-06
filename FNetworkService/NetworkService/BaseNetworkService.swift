//
//  BaseNetworkService.swift
//  FNetworkService
//
//  Created by Eugene on 06/09/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

import Alamofire

public class BaseNetworkService: NetworkServiceProtocol {
    
    // MARK: - NetworkServiceProtocol
    
    public typealias Success = BaseDataResponse
    
    public func parse(_ response: DefaultDataResponse) -> APIResult<BaseDataResponse> {
        
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
        
        return .success(BaseDataResponse(httpMeta: httpResponse, body: data))
    }
    
    public func request(endpoint: EndpointProtocol, isCacheEnabled: Bool, completion: @escaping (APIResult<BaseDataResponse>) -> Void) {
        
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
    
    internal let debugLogger: NetworkLogWriter
    internal let networkLogger: NetworkLogWriter?
    internal let settings: Settings
    internal let decoder: JSONDecoder
    internal let alamofireManager: SessionManager
    internal let cacheStorage: Storage
    
    
    // MARK: - Internal methods
    
    internal func createServerError(from response: DefaultDataResponse) -> APIError {
        return APIError.serverError(error: response.error, response: response.response, data: response.data)
    }
    
    // MARK: - Cache helpers
    
    internal func retrieveCachedResponseIfExists<Response: Codable>(for endpoint: EndpointProtocol) -> Response? {
        guard let cacheKey = endpoint.cacheKey else { return nil }
        return cacheStorage.retrieveValue(for: cacheKey)
    }
    
    internal func cacheResponseIfNeeded<Response: Codable>(_ response: Response, for endpoint: EndpointProtocol) {
        guard let cacheKey = endpoint.cacheKey else { return }
        cacheStorage.save(response, for: cacheKey)
    }
    
    
    // MARK: - Logger helpers
    
    internal func perfomLogWriting<T>(endpoint: EndpointProtocol, result: APIResult<T>) {
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.networkLogger?.write(endpoint: endpoint, result: result)
            self?.debugLogger.write(endpoint: endpoint, result: result)
        }
        
    }
    
    
    // MARK: - Request helpers
    
    
    
}


public extension BaseNetworkService {
    
    struct Settings {
        
        public var validCodes = (200 ..< 300)
        public var cacheRequestTimeout: TimeInterval = 0.3
        public var requestTimeout: TimeInterval = 10
        public var dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.millisecondsSince1970
        public var networkLogger: NetworkLogWriter? = Settings.defaultLogger
        public var debugLogger: NetworkLogWriter = Settings.defaultDebugLogger
        
        
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
