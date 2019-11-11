//
//  ResponseParser.swift
//  FNetworkService
//
//  Created by Eugene on 11/11/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

import Alamofire

public protocol ResponseParser {
    
    func parse(response: DefaultDataResponse, forEndpoint endpoint: EndpointProtocol) -> APIResult<Data>
    func parse<Response: Decodable>(response: DefaultDataResponse, forEndpoint endpoint: EndpointProtocol) -> APIResult<Response>
    func parse<Response: Decodable>(response: DefaultDataResponse, forEndpoint endpoint: EndpointProtocol) -> APIXResult<Response>
    
}
