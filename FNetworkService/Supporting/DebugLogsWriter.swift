//
//  DebugLogsWriter.swift
//  FNetworkService
//
//  Created by Eugene on 16/05/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

private let endLine = "\n"
private let separator = "<<<-RESPONSE->>>"

final class DebugLogWriter: NetworkLogWriter {
    
    var writeOptions: LoggerWriteOptions = .all
    
    func write(log: String) {
        print(log)
    }
    
    func write<T>(endpoint: EndpointProtocol, result: APIResult<T>) {
        
        guard shouldPerformLogging(isResultSuccess: result.isSuccess) else { return }
        
        let responseStatus: String = result.isSuccess ? "SUCCESS" : "FAILURE"
        let method = endpoint.method
        let domain = endpoint.baseUrl?.absoluteString ?? "Domain missed!"
        let path = endpoint.path
        let parameters = endpoint.parameters.stringValue
        let headers = endpoint.headers.stringValue
        
        var endpointLog = "\(separator) \(responseStatus)"
        endpointLog += "\(endLine)\(currentDate)\(endLine)"
        endpointLog += "\(method.rawValue) Request: \(domain)\(path)\(endLine)"
        endpointLog += "with parameters: \(parameters)\(endLine)"
        endpointLog += "headers: \(headers)\(endLine)"
        
        let resultText: String
        
        switch result {
        case .failure(let error):
            resultText = "\(error.localizedDescription)"
        case .success(let model):
            resultText = "\(model)"
        }
        
        let logText = endpointLog + resultText
        
        write(log: logText)
    }
    
    var dateLocale: Locale {
        return Locale(identifier: "en_US")
    }
    
    private var currentDate: String {
        return String(describing: Date().description(with: dateLocale))
    }
    
}
