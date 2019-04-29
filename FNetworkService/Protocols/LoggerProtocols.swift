//
//  LoggerProtocols.swift
//  THT-Premier
//
//  Created by Eugene on 25/03/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

private let endLine = "\n"

public protocol NetworkLogsWriter: AnyObject {
    
    var writeOptions: LoggerWriteOptions { get }
    var dateLocale: Locale { get }
    
    func write(log: String)
    func write<T>(endpoint: FEndpointProtocol, result: FResult<T>)
}

// MARK: - NetworkLogsWriter default implementation
public extension NetworkLogsWriter {
    
    func write<T>(endpoint: FEndpointProtocol, result: FResult<T>) {
        
        let method = endpoint.method
        let domain = endpoint.baseUrl?.absoluteString ?? "Domain missed!"
        let path = endpoint.path
        
        let parameters = endpoint.parameters.stringValue
        let headers = endpoint.headers.stringValue
        
        var networkLog = endLine + currentDate + endLine
        networkLog += method.rawValue + " Request: " + domain + path + endLine
        networkLog += "with parameters: " + parameters + endLine
        networkLog += "headers: " + headers + endLine
        
        let resultText: String
        
        switch result {
        case .failure(let error):
            resultText = "ERROR: " + error.localizedDescription
        case .success:
            resultText = "SUCCESS"
        }
        
        networkLog += resultText
        
        write(log: networkLog)
    }
    
    var dateLocale: Locale {
        return Locale(identifier: "en_US")
    }
    
    private var currentDate: String {
        return String(describing: Date().description(with: dateLocale))
    }
    
}

