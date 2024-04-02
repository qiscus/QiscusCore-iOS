//
//  QMessageStorage.swift
//  QiscusCore
//
//  Created by Qiscus on 19/08/18.
//

import Foundation
import CoreData

class QMessageStorage : QiscusStorage {
    var qiscusCore : QiscusCore? = nil
    var messageStore: Message{
//        if #available(iOS 10.0, *) {
//            let message = Message(context:  QiscusDatabase.init(qiscusCore: self.qiscusCore!).persistenStore.context)
//            message.qiscusCore = self.qiscusCore
//            return message
//        } else {
//            // Fallback on earlier versions
//            let context =  QiscusDatabase.init(qiscusCore: self.qiscusCore!).persistenStore.context
//            let description = NSEntityDescription.entity(forEntityName: "Message", in: context)
//            let message = Message(entity: description!, insertInto: context)
//            message.qiscusCore = self.qiscusCore
//            return message
//        }
        return self.qiscusCore!.messagePersistens
    }
    
    init(qiscusCore : QiscusCore) {
        self.qiscusCore = qiscusCore
        // MARK: TODO load data rooms from local storage to var data
    }
    
    func loadData() {
        self.qiscusCore?.dataDBQMessage = self.loadFromLocal()
    }
    
    func removeAll() {
        qiscusCore?.dataDBQMessage.removeAll()
        self.clearDB() // clear db
    }
    
    func delete(byUniqueID id: String) -> Bool {
        // remove from memory
        if let index = self.qiscusCore?.dataDBQMessage.index(where: {$0.uniqueId == id}) {
            qiscusCore?.dataDBQMessage.remove(at: index)
        }else {
            return false
        }
        
        // remove from db
        if let db = messageStore.find(predicate: NSPredicate(format: "uniqId = %@", id))?.first {
            db.qiscusCore = self.qiscusCore
            db.remove()
        }else {
            return false
        }
        
        return true
    }
    
    func all() -> [QMessage] {
        self.qiscusCore?.dataDBQMessage = self.loadFromLocal()
        return self.qiscusCore!.dataDBQMessage
    }
    
    func add(_ comment: QMessage, onCreate: @escaping (QMessage) -> Void, onUpdate: @escaping (QMessage) -> Void) {
            // filter if comment exist update, if not add
            if let r = find(byUniqueID: comment.uniqueId)  {
                // check new comment status, end status is read. sending - sent - deliverd - read
                if comment.status.intValue <= r.status.intValue && comment.status != .deleted {
                    
                    if comment.status == .failed {
                         onUpdate(comment)
                    }else{
                        // update
                        comment.status = r.status
                        if !updateCommentDataEvent(old: r, new: comment) {
                            // add new
                            qiscusCore?.dataDBQMessage.append(comment)
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
                        qiscusCore?.dataDBQMessage.append(comment)
                        onCreate(comment)
                        save(comment)
                    }else {
                        // update
                        save(comment)
                        onUpdate(comment)
                    }
                   
                }
            }else {
                //new mekanism
                if let r = find(byID: comment.id)  {
                    // check new comment status, end status is read. sending - sent - deliverd - read
                    if comment.status.intValue <= r.status.intValue && comment.status != .deleted {
                        
                        if comment.status == .failed {
                             onUpdate(comment)
                        }else{
                            // update
                            comment.status = r.status
                            if !updateCommentDataEvent(old: r, new: comment) {
                                // add new
                                qiscusCore?.dataDBQMessage.append(comment)
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
                            qiscusCore?.dataDBQMessage.append(comment)
                            onCreate(comment)
                            save(comment)
                        }else {
                            // update
                            save(comment)
                            onUpdate(comment)
                        }
                       
                    }
                }else{
                    // add new
                    if let r = find(byID: comment.id)  {
                        // update
                        save(comment)
                        onUpdate(comment)
                    }else{
                        // add new
                        qiscusCore?.dataDBQMessage.append(comment)
                        onCreate(comment)
                        save(comment)
                    }
                }

            }
        }
    
    func find(byID id: String) -> QMessage? {
        if qiscusCore!.dataDBQMessage.isEmpty {
            return nil
        }else {
            return qiscusCore?.dataDBQMessage.filter{ $0.id == id }.first
        }
    }
    
    func find(byUniqueID id: String) -> QMessage? {
        if qiscusCore!.dataDBQMessage.isEmpty {
            return nil
        }else {
            return qiscusCore?.dataDBQMessage.filter{ $0.uniqueId == id }.first
        }
    }
    
    func find(byRoomID id: String) -> [QMessage]? {
        if qiscusCore!.dataDBQMessage.isEmpty {
            return nil
        }else {
            let result = qiscusCore!.dataDBQMessage.filter{ $0.chatRoomId == id }
            return sort(result) // short by unix
        }
    }
    
    func findOlderCommentsThan(byRoomID id: String, message : QMessage, limit : Int) -> [QMessage]? {
        if qiscusCore!.dataDBQMessage.isEmpty {
            return nil
        }else {
            let result = qiscusCore!.dataDBQMessage.filter{ $0.chatRoomId == id }
            return sort(result) // short by unix
        }
    }
    
    func find(status: QMessageStatus) -> [QMessage]? {
        if qiscusCore!.dataDBQMessage.isEmpty {
            return nil
        }else {
            let result = qiscusCore!.dataDBQMessage.filter{ $0.status == status }
            return sort(result) // short by unix
        }
    }
    
    // update/replace === identical object
    private func updateCommentDataEvent(old: QMessage, new: QMessage) -> Bool{
        if let index = qiscusCore?.dataDBQMessage.index(where: { $0 === old }) {
            qiscusCore?.dataDBQMessage[index] = new
            return true
        }else {
            return false
        }
    }
    
    func sort(_ data: [QMessage]) -> [QMessage]{
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
        if qiscusCore!.dataDBQMessage.count != 0 {
            for (index,c) in qiscusCore!.dataDBQMessage.enumerated() {
                if c.uniqueId.isEmpty {
                    self.qiscusCore?.dataDBQMessage.remove(at: index)
                    // MARK : TODO remove from local db
                }
            }
        }
    }
}

// MARK: Comment database
extension QMessageStorage {
    func find(predicate: NSPredicate) -> [QMessage]? {
        guard let data = messageStore.find(predicate: predicate) else { return nil }
        var results = [QMessage]()
        for r in data {
            results.append(map(r))
        }
        return results
    }
    
    func clearDB() {
        messageStore.clear()
        self.qiscusCore?.qiscusLogger.debugDBPrint("delete all comments from DB")
    }
    
    func save(_ data: QMessage) {
        if let db = messageStore.find(predicate: NSPredicate(format: "id = %@", data.id))?.first {
            if  data.id != "0"{
                let _comment = map(data, data: db) // update value
                if let commentId = _comment.id{
                    _comment.qiscusCore = self.qiscusCore
                    _comment.update() // save to db
                }
            }
           
        }else {
            if data.id != "0" {
                let _comment = self.map(data)
                if let commentId = _comment.id{
                    _comment.qiscusCore = self.qiscusCore
                    _comment.save()
                }
            }
            
        }
        self.qiscusCore?.qiscusLogger.debugDBPrint("save or update comment with commentId = \(data.id) & roomId = \(data.chatRoomId)")
    }
    
    private func loadFromLocal() -> [QMessage] {
        var results = [QMessage]()
        let db = messageStore.all()
        self.qiscusCore?.qiscusLogger.debugPrint("number of comment in db : \(db.count)")
        for comment in db {
            let _comment = map(comment)
            // validasi comment
            if !_comment.uniqueId.isEmpty && !_comment.chatRoomId.isEmpty {
               results.append(_comment)
            } else {
                self.qiscusCore?.qiscusLogger.debugDBPrint("delete comment (for comment Id = \(comment.id) and room ID = \(comment.roomId)")
                comment.qiscusCore = self.qiscusCore
                comment.remove() // remove from db
            }
        }
        self.qiscusCore?.qiscusLogger.debugPrint("number of comment in cache : \(results.count)")
        return results
    }
    
    
    /// create or update db object
    ///
    /// - Parameters:
    ///   - core: core model
    ///   - data: db model, if exist just update falue
    /// - Returns: db object
    private func map(_ core: QMessage, data: Message? = nil) -> Message {
        var result : Message
        if let _result = data {
            result = _result // Update data
        }else {
            if let db = messageStore.find(predicate: NSPredicate(format: "id = %@", core.id))?.first {
                result = db
            }else{
                result = messageStore.generate() // prepare create new
            }
        }
        QiscusThread.background {
            result.id               = core.id
            result.type             = core.type
            result.userAvatarUrl    = core.userAvatarUrl?.absoluteString
            result.username         = core.sender.name
            result.userEmail        = core.userEmail
            result.userId           = core.userId
            result.message          = core.message
            result.uniqId           = core.uniqueId
            result.roomId           = core.chatRoomId
            result.commentBeforeId  = core.previousMessageId
            result.status           = core.status.rawValue
            result.unixTimestamp    = Int64(core.unixTimestamp)
            result.timestamp        = core.timestampString
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
    private func map(_ data: Message) -> QMessage {
        let result = QMessage(json: [:], qiscusCore: nil)
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
            result.id                = id
            result.type              = type
            result.userAvatarUrl     = URL(string: userAvatarUrl)
            result.sender.name       = username
            result.userEmail         = userEmail
            result.userId            = userId
            result.message           = message
            result.uniqueId          = uniqueId
            result.chatRoomId        = roomId
            result.previousMessageId = commentBeforeId
            result.isDeleted         = data.isDeleted
            result.unixTimestamp     = Int64(data.unixTimestamp)
            result.timestampString   = timestamp
            result.isPublicChannel   = data.isPublicChannel
            
            for s in QMessageStatus.all {
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

