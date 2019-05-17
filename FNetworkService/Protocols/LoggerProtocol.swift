//
//  LoggerProtocol.swift
//  FNetworkService
//
//  Created by Eugene on 25/03/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

private let endLine = "\n"

public protocol NetworkLogWriter: AnyObject {
    
    var writeOptions: LoggerWriteOptions { get set }
    var dateLocale: Locale { get }
    
    func write(log: String)
    func write<T>(endpoint: EndpointProtocol, result: APIResult<T>)
}

// MARK: - NetworkLogsWriter default implementation
public extension NetworkLogWriter {
    
    func write<T>(endpoint: EndpointProtocol, result: APIResult<T>) {
        
        let method = endpoint.method
        let domain = endpoint.baseUrl?.absoluteString ?? "Domain missed!"
        let path = endpoint.path
        
        let parameters = endpoint.parameters.stringValue
        let headers = endpoint.headers.stringValue
        
        var endpointLog = "\(currentDate)\(endLine)"
        endpointLog += "\(method.rawValue) Request: \(domain)\(path)\(endLine)"
        endpointLog += "with parameters: \(parameters)\(endLine)"
        endpointLog += "headers: \(headers)\(endLine)"
        
        let resultText: String
        
        switch result {
        case .failure(let error):
            resultText = "ERROR: " + error.localizedDescription
        case .success:
            resultText = "SUCCESS"
        }
        
        let networkLog = endpointLog + resultText
        
        write(log: networkLog)
    }
    
    var dateLocale: Locale {
        return Locale(identifier: "en_US")
    }
    
    private var currentDate: String {
        return String(describing: Date().description(with: dateLocale))
    }
    
}

