//
//  ApiError.swift
//  Stewards
//
//  Created by Alexander Antonov on 06/09/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation

public enum ApiError: Error, LocalizedError {
    
    case noBaseUrl
    case noNetwork
    case serverError(error: Error?, response: HTTPURLResponse?, data: Data?)
    case decodingError
    case custom(String?)

    
    // MARK: - LocalizedError
    
    public var localizedDescription: String {
        
        switch self {
            
        case .noBaseUrl:
            return "Ошибка запроса"
            
        case .noNetwork:
            return "Отсутствует интернет соединение"
            
        case .serverError, .decodingError:
            return "Не удалось получить данные"
        case .custom(let errorText):
            return errorText ?? "Непредвиденная ошибка!"
        }
        
    }
    
    public var failureReason: String? {
        
        switch self {
            
        case .noBaseUrl:
            return "No base URL provided."
            
        case .noNetwork:
            return "No network connection."
            
        case .serverError(let error, let response, _):
            var resultString = "Server error."
            if let response = response {
                resultString += " Status code: \(response.statusCode)"
            }
            if let error = error {
                resultString += " Error description: \(error.localizedDescription)"
            }
            return resultString
            
        case .decodingError:
            return "Error decoding object."
            
        case .custom(let errorText):
            return "Custom error: \(errorText ?? "No info provided")"
        }
        
    }
    
}


// MARK: - Equatable
extension ApiError: Equatable {
    
    public static func == (lhs: ApiError, rhs: ApiError) -> Bool {
        
        switch (lhs, rhs) {
        case (.noBaseUrl, .noBaseUrl):
            return true
        case (.noNetwork, .noNetwork):
            return true
        case (.decodingError, .decodingError):
            return true
        case (.serverError(_, let lhsResp, let lhsData), .serverError(_, let rhsResp, let rhsData)):
            return lhsResp?.statusCode == rhsResp?.statusCode && lhsData == rhsData
        case (.custom(let leftErrText), .custom(let rightErrText)):
            return leftErrText == rightErrText
        default:
            return false
        }
    }
    
}


// MARK: - IsNetworkError
extension ApiError {
    
    public var isNetworkError: Bool {
        switch self {
        case .noNetwork:    return true
        default:            return false
        }
    }
    
}
