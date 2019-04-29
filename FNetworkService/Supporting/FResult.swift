//
//  FResult.swift
//  Stewards
//
//  Created by Alexander Antonov on 06/09/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation

public enum FResult<Model> {
    
    case success(Model)
    case failure(ApiError)
    
    
    // Returns `true` if the result is a success, `false` otherwise.
    
    public var isSuccess: Bool {
        
        switch self {
        case .success:      return true
        case .failure:      return false
        }
    }
    
    
    // Returns `true` if the result is a failure, `false` otherwise.
    
    public var isFailure: Bool {
        return !isSuccess
    }
    
    
    // Returns the associated value if the result is a success, `nil` otherwise.
    
    public var value: Model? {
        
        switch self {
        case .success(let value):   return value
        case .failure:              return nil
        }
    }
    
    
    // Returns the associated error value if the result is a failure, `nil` otherwise.
    
    public var error: Error? {
        
        switch self {
        case .success:              return nil
        case .failure(let error):   return error
        }
    }
    
}


// MARK: - Equatable
extension FResult: Equatable where Model: Equatable {
    
    public static func == (lhs: FResult, rhs: FResult) -> Bool {
        
        switch (lhs, rhs) {
        case (.success(let lhs), .success(let rhs)):
            return lhs == rhs
        case (.failure(let lhs), .failure(let rhs)):
            return lhs == rhs
        default:
            return false
        }
        
    }
    
}
