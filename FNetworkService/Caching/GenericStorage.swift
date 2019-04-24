//
//  GenericStorage.swift
//  THT-Premier
//
//  Created by Alexander Antonov on 17/11/2018.
//  Copyright © 2018 Finch. All rights reserved.
//

import Foundation

protocol Storage {
    
    func save<Value: Codable>(_ value: Value, for key: String)
    func retrieveValue<Value: Codable>(for key: String) -> Value?
    
    func clearStorage()
    func deleteStoredValue(for key: String)
}

final class GenericStorage: Storage {
    
    // MARK: - Init
    
    init() {
        ensureFolderExists()
    }
    
    
    // MARK: - Public methods
    
    func save<Value: Codable>(_ value: Value, for key: String) {
                
        DispatchQueue.global(qos: .userInitiated).async {
            
            guard let data = try? JSONEncoder().encode(value) else {
                return
            }
            let fileUrl = self.buildFileUrl(with: key)
            try? data.write(to: fileUrl)
        }
        
    }
    
    func retrieveValue<Value: Codable>(for key: String) -> Value? {
        
        let fileUrl = buildFileUrl(with: key)
        
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            return try JSONDecoder().decode(Value.self, from: data)
            
        } catch let error {
            print("STORAGE ERROR: \(error)")
            return nil
        }
        
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
