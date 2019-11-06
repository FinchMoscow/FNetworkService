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
    func write<T>(endpoint: EndpointProtocol, result: APIResult<T>, data: Data?)
}

// MARK: - NetworkLogsWriter default implementation
public extension NetworkLogWriter {
    
    func write<T>(endpoint: EndpointProtocol, result: APIResult<T>, data: Data?) {
        
        guard shouldPerformLogging(isResultSuccess: result.isSuccess) else { return }
        
        var endpointLog = "\(currentDate)\(endLine)"
        endpointLog += endpoint.description + endLine
        
        let resultText: String
        
        switch result {
        case .failure(let error):
            resultText = "ERROR: " + errorDescription(error: error, data: data)
        case .success:
            resultText = "SUCCESS"
        }
        
        let networkLog = endpointLog + resultText
        
        write(log: networkLog)
    }
    
    var dateLocale: Locale {
        return Locale(identifier: "en_US")
    }
    
    
    // MARK: - Private helpers
    
    private func errorDescription(error: APIError, data: Data?) -> String {
        
        func dataDescription(_ data: Data?) -> String {
            let descriptionEntry = "Response body: "
            guard let data = data else { return descriptionEntry + "Empty body!" }
            return descriptionEntry + endLine + (String(data: data, encoding: .utf8) ?? "Failed to convert Data to String") + endLine
        }
        
        switch error {
        case .noBaseUrl:
            return error.localizedDescription + endLine
            
        case .noNetwork:
            return error.localizedDescription + endLine
            
        case .requestTimeout:
            var description = error.localizedDescription + endLine
            description += dataDescription(data)
            return description
            
        case .decodingError:
            return error.localizedDescription + endLine + dataDescription(data)
            
        case let .serverError(error, response, data):
            var description = error?.localizedDescription ?? "(nil)" + endLine
            description += "Status code: " + (response?.statusCode == nil ? "(nil)" : "\(response!.statusCode)")
            description += dataDescription(data)
            return description
        }
        
    }
    
    private var currentDate: String {
        return String(describing: Date().description(with: dateLocale))
    }
    
}


// MARK: - shouldPerformLogging
extension NetworkLogWriter {
    
    func shouldPerformLogging(isResultSuccess: Bool) -> Bool {
        
        if writeOptions == .all { return true }
        if writeOptions == .none { return false }
        
        if isResultSuccess && writeOptions == .onSuccess {
            return true
        }
        
        if !isResultSuccess && writeOptions == .onError {
            return true
        }
        
        return false
    }
    
}

