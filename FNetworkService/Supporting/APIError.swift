//
//  APIError.swift
//  Stewards
//
//  Created by Alexander Antonov on 06/09/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation

public enum APIError: Error, LocalizedError {
    
    case noBaseUrl
    case noNetwork
    case serverError(error: Error?, response: HTTPURLResponse?, data: Data?)
    case decodingError

    
    // MARK: - LocalizedError
    
    public var localizedDescription: String {
        
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
        
        }
    }
    
}


// MARK: - PresentableError
extension APIError: PresentableError {
    
    public var userMessage: String {
        
        switch self {
            
        case .noBaseUrl:
            return "Ошибка запроса"
            
        case .noNetwork:
            return "Отсутствует интернет соединение"
            
        case .serverError, .decodingError:
            return "Не удалось получить данные"
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


// TODO: To think about
//extension APIError: PresentableError {
//
//    var userMessage: String {
//
//        let errorStrings = Config.main.apiErrorStrings
//
//        switch self {
//
//        case .noBaseUrl:
//            return errorStrings?.noBaseUrl ?? "Ошибка запроса"
//        case .noNetwork:
//            return errorStrings?.noNetwork ?? "Отсутствует интернет соединение"
//        case .serverError, .decodingError:
//            return errorStrings?.serverError ?? "Не удалось получить данные"
//        case .notAuthorized:
//            return errorStrings?.notAuthorized ?? "Для корректной работы раздела необходима авторизация"
//
//        case .wrongPayment(let system):
//            return "Ранее подписка была оформлена через \(system)"
//
//        case .expiresDate:
//            return errorStrings?.expiresDate ?? " Дата подписки истекла"
//
//        case .storeKit(let error):
//            return error.localizedDescription
//
//        case .custom(let message):
//            return message ?? "Непредвиденная ошибка!"
//
//        }
//
//    }
//
//}
