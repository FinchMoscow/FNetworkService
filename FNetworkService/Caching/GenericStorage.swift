//
//  GenericStorage.swift
//  FNetworkService
//
//  Created by Eugene on 09/09/2019.
//  Copyright © 2019 Finch. All rights reserved.
//

import Foundation

// TODO - Rafactoring
protocol Storage {
    
    func save(_ value: Data, httpMeta: HTTPURLResponse, for key: String)
    func retrieveValue(for key: String) -> (data: Data, httpMeta: HTTPURLResponse)?
    
    func clearStorage()
    func deleteStoredValue(for key: String)
}

extension Storage {
    
    func retrieveValue(for key: String) -> BaseDataResponse? {
        guard let cache = retrieveValue(for: key) else { return nil }
        return BaseDataResponse(httpMeta: cache.httpMeta, payload: cache.data)
    }
    
    func save(_ value: BaseDataResponse, for key: String) {
        save(value.payload, httpMeta: value.httpMeta, for: key)
    }
    
}

final class GenericStorage: Storage {
    
    // MARK: - Init
    
    init() {
        ensureFolderExists()
    }
    
    
    // MARK: - Public methods
    
    func save(_ value: Data, httpMeta: HTTPURLResponse, for key: String) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileUrl = self.buildFileUrl(with: key)
            let fileMetaUrl = self.buildFileUrl(with: key + "httpMeta")
            try? value.write(to: fileUrl)
            try? httpMeta.dataCache.write(to: fileMetaUrl)
        }
        
    }
    
    func retrieveValue(for key: String) -> (data: Data, httpMeta: HTTPURLResponse)? {
        
        let fileUrl = buildFileUrl(with: key)
        let fileHttpMetaUrl = buildFileUrl(with: key + "httpMeta")
        
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: fileUrl),
            let httpMetaData = try? Data(contentsOf: fileHttpMetaUrl),
            let url = URL(string: String(data: httpMetaData, encoding: .utf8) ?? ""),
            let httpMeta = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: nil) else {
            return nil
        }
        
        return (data, httpMeta)
    }
    
    func clearStorage() {
        try? FileManager.default.removeItem(at: folder)
    }
    
    func deleteStoredValue(for key: String) {
        try? FileManager.default.removeItem(at: buildFileUrl(with: key))
    }
    
    
    // MARK: - Private methods
    
    private var folder: URL {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let subfolder = "\(Bundle.main.bundleIdentifier ?? "")network.responses"
        return URL(fileURLWithPath: path).appendingPathComponent(subfolder)
    }
    
    private func buildFileUrl(with key: String) -> URL {
        return folder.appendingPathComponent(key)
    }
    
    private func ensureFolderExists() {
        
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        
        if fileManager.fileExists(atPath: folder.path, isDirectory: &isDir) {
            
            if isDir.boolValue { return }
            try? FileManager.default.removeItem(at: folder)
        }
        
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: false, attributes: nil)
    }
    
}


extension HTTPURLResponse {
    
    var dataCache: Data {
        let urlString = url?.absoluteString ?? ""
        return (urlString).data(using: .utf8) ?? Data()
    }
    
}
