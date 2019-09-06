//
//  RawNetworkService.swift
//  FNetworkService
//
//  Created by Eugene on 06/09/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

import Alamofire


// MARK: - Network Service Implementation
public class RawNetworkService: BaseNetworkService {
    
    // MARK: - NetworkServiceProtocol
    
    public typealias Success = RawResponse
    
    public func parse(_ response: DefaultDataResponse) -> APIResult<RawResponse> {
        
        let baseResult = super.parse(response)
        
        switch baseResult {
            
        case .success(let baseSuccess):
            
            guard let stringRepresent = String(data: baseSuccess.body, encoding: .utf8) else {
                return APIResult.failure(.decodingError)
            }
            
            let response = RawResponse(httpMeta: baseSuccess.httpMeta, body: stringRepresent)
            return .success(response)
            
        case .failure(let error):
            return .failure(error)
        }
        
    }
    
    public func request(endpoint: EndpointProtocol, isCaheEnabled: Bool, completion: @escaping (APIResult<RawResponse>) -> Void) {
        
        guard let baseURL = ensureBaseUrlProvided(endpoint: endpoint) else { completion(.failure(.noBaseUrl)); return }
        
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        alamofireManager.request(url,
                                 method: endpoint.method,
                                 parameters: endpoint.parameters,
                                 encoding: endpoint.encoding,
                                 headers: endpoint.headers).response { [weak self] response in
                                    
                                    guard let self = self else { return }
                                    
                                    let result = self.parse(response)
                                    
                                    DispatchQueue.main.async {
                                        completion(result)
                                    }
                                    
                                    self.perfomLogWriting(endpoint: endpoint, result: result)
                                    
        }

        
    }
    
    //    public func request(endpoint: EndpointProtocol, completion: @escaping (Swift.Result<Success, APIError>) -> Void) {
    //
    //        guard let baseUrl = endpoint.baseUrl else {
    //            let result = APIResult<Success>.failure(.noBaseUrl)
    //            completion(result)
    //            perfomLogWriting(endpoint: endpoint, result: result)
    //            return
    //        }
    //
//            let url = baseUrl.appendingPathComponent(endpoint.path)
//
//            alamofireManager.request(url,
//                                     method: endpoint.method,
//                                     parameters: endpoint.parameters,
//                                     encoding: endpoint.encoding,
//                                     headers: endpoint.headers).response { [weak self] response in
//
//                                        guard let self = self else { return }
//
//                                        let result: Swift.Result<String, APIError> = self.transform(response)
//
//                                        DispatchQueue.main.async {
//                                            completion(result)
//                                        }
//    
//                                        self.perfomLogWriting(endpoint: endpoint, result: result)
//
//            }
    //
    //    }
    
    
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
    
    
    // MARK: - Logger helpers
    
//    private func perfomLogWriting<T>(endpoint: EndpointProtocol, result: APIResult<T>) {
//
//        DispatchQueue.global(qos: .background).async { [weak self] in
//            self?.networkLogger?.write(endpoint: endpoint, result: result)
//            self?.debugLogger.write(endpoint: endpoint, result: result)
//        }
//
//    }
    
}
