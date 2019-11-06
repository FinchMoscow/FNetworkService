//
//  ModelWithResponse.swift
//  FNetworkService
//
//  Created by Loginov Anton on 25/07/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

import Foundation

public struct ModelWithResponse<Model> {
    
    // MARK: - Properties
    
    public let model: Model
    public let response: HTTPURLResponse?
    
    
    // MARK: - Init
    
    init(model: Model, response: HTTPURLResponse?) {
        self.model = model
        self.response = response
    }
    
}
