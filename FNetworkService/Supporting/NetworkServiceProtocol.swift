//
//  NetworkServiceProtocol.swift
//  FNetworkService
//
//  Created by Eugene on 06/09/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

import Foundation
import Alamofire

public protocol NetworkServiceProtocol {
    
    associatedtype Success: Response
    
    func parse(_ response: DefaultDataResponse) -> APIResult<Success>
    func request(endpoint: EndpointProtocol, isCacheEnabled: Bool, completion: @escaping (APIResult<Success>) -> Void)
}

public extension NetworkServiceProtocol {
    
    func request(endpoint: EndpointProtocol, completion: @escaping (APIResult<Success>) -> Void) {
        request(endpoint: endpoint, isCaheEnabled: false, completion: completion)
    }
    
}



