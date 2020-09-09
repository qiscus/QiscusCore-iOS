//
//  CommentStorage.swift
//  QiscusCore
//
//  Created by Qiscus on 19/08/18.
//

import Foundation

class CommentStorage : QiscusStorage {
    private var data : [CommentModel] {
        get {
            return _data
        }
        set {
            _data = newValue
        }
    }
    
    private var _data : [CommentModel] = [CommentModel]()
    
    override init() {
        super.init()
        // MARK: TODO load data rooms from local storage to var data
    }
    
    func loadData() {
        self.data = self.loadFromLocal()
    }
    
    func removeAll() {
        data.removeAll()
        self.clearDB() // clear db
    }
    
    func delete(byUniqueID id: String) -> Bool {
        // remove from memory
        if let index = self.data.index(where: {$0.uniqId == id}) {
            data.remove(at: index)
        }else {
            return false
        }
        
        // remove from db
        if let db = Comment.find(predicate: NSPredicate(format: "uniqId = %@", id))?.first {
            QiscusLogger.debugDBPrint("delete comment (for comment Id = \(String(describing: db.id)) and room ID = \(String(describing: db.id)))")
            db.remove()
        }else {
            return false
        }
        
        return true
    }
    
    func all() -> [CommentModel] {
        return data
    }
    
    func add(_ comment: CommentModel, onCreate: @escaping (CommentModel) -> Void, onUpdate: @escaping (CommentModel) -> Void) {
        // filter if comment exist update, if not add
        if let r = find(byUniqueID: comment.uniqId)  {
            // check new comment status, end status is read. sending - sent - deliverd - read
            if comment.status.intValue <= r.status.intValue && comment.status != .deleted {
                
                if comment.status == .failed {
                     onUpdate(comment)
                }else{
                    // update
                    comment.status = r.status
                    if !updateCommentDataEvent(old: r, new: comment) {
                        // add new
                        data.append(comment)
                        onCreate(comment)
                        save(comment)
                    }else {
                       save(comment)
                       onUpdate(comment)
                    }
                   // return // just ignore, except delete(soft, connten ischanged) this part is trick from backend. after receiver update comment status then sender call api load comment somehow status still sent but sender already receive event status read/deliverd via mqtt
                }
            }else{
                if !updateCommentDataEvent(old: r, new: comment) {
                    // add new
                    data.append(comment)
                    onCreate(comment)
                    save(comment)
                }else {
                    // update
                    save(comment)
                    onUpdate(comment)
                }
               
            }
        }else {
            // add new
            data.append(comment)
            onCreate(comment)
            save(comment)
        }
    }
    
    func find(byID id: String) -> CommentModel? {
        if data.isEmpty {
            return nil
        }else {
            return data.filter{ $0.id == id }.first
        }
    }
    
    func find(byUniqueID id: String) -> CommentModel? {
        if data.isEmpty {
            return nil
        }else {
            return data.filter{ $0.uniqId == id }.first
        }
    }
    
    func find(byRoomID id: String) -> [CommentModel]? {
        if data.isEmpty {
            return nil
        }else {
            let result = data.filter{ $0.roomId == id }
            return sort(result) // short by unix
        }
    }
    
    func find(status: CommentStatus) -> [CommentModel]? {
        if data.isEmpty {
            return nil
        }else {
            let result = data.filter{ $0.status == status }
            return sort(result) // short by unix
        }
    }
        
    func findOlderCommentsThan(byRoomID id: String, message : CommentModel, limit : Int) -> [CommentModel]? {
        if data.isEmpty {
            return nil
        }else {
            let result = data.filter{ $0.roomId == id }
            return sort(result) // short by unix
        }
    }
    
    // update/replace === identical object
    private func updateCommentDataEvent(old: CommentModel, new: CommentModel) -> Bool{
        if let index = data.index(where: { $0 === old }) {
            data[index] = new
            return true
        }else {
            return false
        }
    }
    
    func sort(_ data: [CommentModel]) -> [CommentModel]{
        var result = data
        //self.background {
            result.sort { (comment1, comment2) -> Bool in
                return comment1.unixTimestamp > comment2.unixTimestamp
            }
        //}
        return result
    }
    
    /// Evaluate data source, remove invalid comment object. exp: uniqid empty, id empty, etc
    func evaluate() {
        for (index,c) in data.enumerated() {
            if c.uniqId.isEmpty {
                self.data.remove(at: index)
                // MARK : TODO remove from local db
            }
        }
    }
}

// MARK: Comment database
extension CommentStorage {
    func find(predicate: NSPredicate) -> [CommentModel]? {
        guard let data = Comment.find(predicate: predicate) else { return nil }
        var results = [CommentModel]()
        for r in data {
            results.append(map(r))
        }
        return results
    }
    
    func clearDB() {
        Comment.clear()
        QiscusLogger.debugDBPrint("delete all comments from DB")
    }
    
    func save(_ data: CommentModel) {
        if let db = Comment.find(predicate: NSPredicate(format: "id = %@", data.id))?.first {
            let _comment = map(data, data: db) // update value
            _comment.update() // save to db
        }else {
            let _comment = self.map(data)
            _comment.save()
        }
        QiscusLogger.debugDBPrint("save or update comment with commentId = \(data.id) & roomId = \(data.roomId)")
    }
    
    private func loadFromLocal() -> [CommentModel] {
        var results = [CommentModel]()
        let db = Comment.all()
        QiscusLogger.debugPrint("number of comment in db : \(db.count)")
        for comment in db {
            let _comment = map(comment)
            // validasi comment
            if !_comment.uniqId.isEmpty && !_comment.roomId.isEmpty {
                results.append(_comment)
            } else {
                QiscusLogger.debugDBPrint("delete comment (for comment Id = \(comment.id) and room ID = \(comment.roomId)")
                comment.remove() // remove from db
            }
        }
        QiscusLogger.debugPrint("number of comment in cache : \(results.count)")
        return results
    }
    
    
    /// create or update db object
    ///
    /// - Parameters:
    ///   - core: core model
    ///   - data: db model, if exist just update falue
    /// - Returns: db object
    private func map(_ core: CommentModel, data: Comment? = nil) -> Comment {
        var result : Comment
        if let _result = data {
            result = _result // Update data
        }else {
            result = Comment.generate() // prepare create new
        }
        QiscusThread.background {
            result.id               = core.id
            result.type             = core.type
            result.userAvatarUrl    = core.userAvatarUrl?.absoluteString
            result.username         = core.username
            result.userEmail        = core.userEmail
            result.userId           = core.userId
            result.message          = core.message
            result.uniqId           = core.uniqId
            result.roomId           = core.roomId
            result.commentBeforeId  = core.commentBeforeId
            result.status           = core.status.rawValue
            result.unixTimestamp    = Int64(core.unixTimestamp)
            result.timestamp        = core.timestamp
            result.isPublicChannel  = core.isPublicChannel
            if let payload = core.payload {
                result.payload = payload.dict2json()
            }
            if let extras = core.extras {
                result.extras   = extras.dict2json()
            }
            
            if let userExtras = core.userExtras {
                result.userExtras   = userExtras.dict2json()
            }
        }
        return result
    }
    
    /// map from db model to core model
    private func map(_ data: Comment) -> CommentModel {
        let result = CommentModel(json: [:])
        // check record data
        guard let id = data.id else { return result }
        guard let message = data.message else { return result }
        guard let status = data.status else { return result }
        guard let type = data.type else { return result }
        guard let userId = data.userId else { return result }
        guard let username = data.username else { return result }
        guard let userEmail = data.userEmail else { return result }
        guard let userAvatarUrl = data.userAvatarUrl else { return result }
        guard let roomId = data.roomId else { return result }
        guard let uniqueId = data.uniqId else { return result }
        guard let timestamp = data.timestamp else { return result }
        guard let commentBeforeId = data.commentBeforeId else { return result }
        
        QiscusThread.background {
            result.id               = id
            result.type             = type
            result.userAvatarUrl    = URL(string: userAvatarUrl)
            result.username         = username
            result.userEmail        = userEmail
            result.userId           = userId
            result.message          = message
            result.uniqId           = uniqueId
            result.roomId           = roomId
            result.commentBeforeId  = commentBeforeId
            result.isDeleted        = data.isDeleted
            result.unixTimestamp    = Int64(data.unixTimestamp)
            result.timestamp        = timestamp
            result.isPublicChannel  = data.isPublicChannel
            
            for s in CommentStatus.all {
                if s.rawValue == status {
                    result.status = s
                }
            }
            if let _payload = data.payload {
                result.payload          = self.convertToDictionary(from: _payload)
            }else {
                result.payload          = nil
            }
            
            if let _extras = data.extras {
                result.extras          = self.convertToDictionary(from: _extras)
            }else {
                result.extras          = nil
            }
            
            if let _userExtras = data.userExtras {
                result.userExtras          = self.convertToDictionary(from: _userExtras)
            }else {
                result.userExtras          = nil
            }
        }
        return result
    }
    
    private func convertToDictionary(from text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8) else { return nil }
        let anyResult = try? JSONSerialization.jsonObject(with: data, options: [])
        return anyResult as? [String: Any]
    }
}

extension Dictionary {
    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
    
    func dict2json() -> String {
        return json
    }
}

