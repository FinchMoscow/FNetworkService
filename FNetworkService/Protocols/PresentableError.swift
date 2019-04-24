//
//  PresentableError.swift
//  NetworkService
//
//  Created by Eugene on 22/04/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

public protocol PresentableError where Self: Error {
    var userMessage: String { get }
}
