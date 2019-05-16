//
//  Optional+stringValue.swift
//  FNetworkService
//
//  Created by Alexander Antonov on 16/09/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation

extension Optional {
    
    var stringValue: String {
        
        switch self {
        case .some(let value):
            return String(describing: value)
        case .none:
            return "(nil)"
        }
    }
    
}
