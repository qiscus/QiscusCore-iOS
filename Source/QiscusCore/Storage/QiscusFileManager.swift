//
//  QiscusFileManager.swift
//  QiscusCore
//
//  Created by Qiscus on 06/09/18.
//

import Foundation

class QiscusFileManager {
    static var shared : QiscusFileManager = QiscusFileManager()
    // Get local file path: download task stores tune here; AV player plays it.
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let qiscusDocumentsPath = "Qiscus"
    
    func localFilePath(for url: URL) -> URL {
        return documentsPath.appendingPathComponent("\(qiscusDocumentsPath)/\(url.lastPathComponent)")
    }
    
    func move(fromURL sourceURL: URL, to location: URL) -> Bool {
        guard createDir(name: self.qiscusDocumentsPath) != nil else { return false }
        
        let destinationURL = localFilePath(for: sourceURL)
        QiscusLogger.debugPrint(destinationURL.absoluteString)
        // 3
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destinationURL)
        do {
            try fileManager.copyItem(at: location, to: destinationURL)
            return true
        } catch let error {
            QiscusLogger.errorPrint("Could not copy file to disk: \(error.localizedDescription)")
            return false
        }
    }
    
    func getlocalPath(from: URL) -> URL? {
        let url = localFilePath(for: from)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            return url
        }else {
            return nil
        }
    }
    
    private func createDir(name: String) -> URL? {
        let fileManager = FileManager.default
        let dir         = documentsPath.appendingPathComponent(name)
        // check folder exist?
        if !fileManager.fileExists(atPath: dir.path) {
            // create
            do {
                try fileManager.createDirectory(atPath: dir.path, withIntermediateDirectories: true, attributes: nil)
            }catch {
                QiscusLogger.errorPrint("Could not create dir: \(error.localizedDescription)")
                return nil
            }
        }
        return dir
    }
    
    func clearTempFolder() {
        let fileManager = FileManager.default
        let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let diskCacheStorageBaseUrl = myDocuments.appendingPathComponent(qiscusDocumentsPath)
        guard let filePaths = try? fileManager.contentsOfDirectory(at: diskCacheStorageBaseUrl, includingPropertiesForKeys: nil, options: []) else { return }
        for filePath in filePaths {
            try? fileManager.removeItem(at: filePath)
        }
    }
}
