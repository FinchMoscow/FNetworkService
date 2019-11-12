//
//  APIResult.swift
//  FNetworkService
//
//  Created by Alexander Antonov on 06/09/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation

public typealias APIResult<Model> = Swift.Result<Model, APIError>

extension APIResult {
    
    /// Returns `true` if the result is a success, `false` otherwise.
    public var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    /// Returns `true` if the result is a failure, `false` otherwise.
    public var isFailure: Bool {
        return !isSuccess
    }
    
    
    /// Returns the associated value if the result is a success, `nil` otherwise.
    public var value: Success? {
        switch self {
        case .success(let value):   return value
        case .failure:              return nil
        }
    }
    
    
    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    public var error: Failure? {
        switch self {
        case .success:              return nil
        case .failure(let error):   return error
        }
    }
    
}
