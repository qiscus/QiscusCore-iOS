//
//  FileModel.swift
//  QiscusCore
//
//  Created by Qiscus on 06/09/18.
//

/**
 file =         {
     name = "upload1.jpg";
     pages = 1;
     size = 2128079;
     url = "https://upload1.jpg";
 }
 */

import SwiftyJSON

public struct FileModel {
    public var name : String    = ""
    public var size : Int       = 1
    public var url  : URL
    var downloaded  : Bool      = false
    
    public init(url: URL) {
        self.url = url
    }
    
    init(json: JSON) {
        url     = json["url"].url ?? URL(string: "http://")!
        name    = json["name"].stringValue
        size    = json["size"].intValue
    }
}

open class FileUploadModel {
    public var data     : Data?
    public var name     : String    = ""
    public var caption  : String    = ""
    
    public init() {
    
    }
}

class Download {
    
    var file: FileModel
    init(file: FileModel) {
        self.file = file
    }
    
    // Download service sets these values:
    var task: URLSessionDownloadTask?
    var isDownloading = false
    var resumeData: Data?
    var totalBytes: Int64 = 0
    
    // Download delegate sets this value:
    var progress: Float = 0
    
    // Download progress bind
    var onProgress : (Float) -> Void = { _ in}
    var onCompleted : (Bool) -> Void = { _ in}
}
