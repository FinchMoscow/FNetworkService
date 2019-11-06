//
//  APIError.swift
//  FNetworkService
//
//  Created by Alexander Antonov on 06/09/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation

public enum APIError: Error {
    
    case noBaseUrl
    case noNetwork
    case requestTimeout
    case serverError(error: Error?, response: HTTPURLResponse?, data: Data?)
    case decodingError
    
    
    // MARK: - LocalizedError
    
    public var localizedDescription: String {
        
        switch self {
            
        case .noBaseUrl:
            return "No base URL provided."
            
        case .requestTimeout:
            return "No response for a given time"
            
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
            return "Error occured while decoding object."
            
        }
        
    }
    
}


// MARK: - Equatable
extension APIError: Equatable {
    
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        
        switch (lhs, rhs) {
        case (.noBaseUrl, .noBaseUrl):
            return true
        case (.noNetwork, .noNetwork):
            return true
        case (.requestTimeout, .requestTimeout):
            return true
        case (.decodingError, .decodingError):
            return true
        case (.serverError(_, let lhsResp, let lhsData), .serverError(_, let rhsResp, let rhsData)):
            return lhsResp?.statusCode == rhsResp?.statusCode && lhsData == rhsData
        default:
            return false
        }
    }
    
}


// MARK: - IsNetworkError
extension APIError {
    
    public var isNetworkError: Bool {
        switch self {
        case .noNetwork:    return true
        default:            return false
        }
    }
    
}
