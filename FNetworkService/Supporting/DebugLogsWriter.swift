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
    
    var dateLocale: Locale {
        return Locale(identifier: "en_US")
    }
    
    private var currentDate: String {
        return String(describing: Date().description(with: dateLocale))
    }
    
}
