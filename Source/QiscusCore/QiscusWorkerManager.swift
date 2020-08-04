//
//  QiscusWorkerManager.swift
//  QiscusCore
//
//  Created by Qiscus on 09/10/18.
//

import Foundation
import UIKit

class QiscusWorkerManager {
    var isBackground : Bool = false
    func resume() {
        // MARK : Improve realtime state acurate disconnected
        if QiscusCore.isLogined {
            self.sync()
            self.pending()
            DispatchQueue.main.sync {
                let state = UIApplication.shared.applicationState
                
                DispatchQueue.global(qos: .background).sync {
                    if state == .active {
                        // foreground
                        if QiscusCore.realtime.state == .connected {
                            QiscusCore.shared.publishOnlinePresence(isOnline: true)
                            isBackground = false
                        }
                    }else{
                        if isBackground == false {
                            isBackground = true
                            if QiscusCore.realtime.state == .connected {
                                QiscusCore.shared.publishOnlinePresence(isOnline: false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func resumeSyncEvent() {
           // MARK : Improve realtime state acurate disconnected
           if QiscusCore.isLogined {
               self.syncAuto()
           }
       }
    
    private func syncEvent() {
        //sync event
        let id = ConfigManager.shared.syncEventId
        QiscusCore.network.synchronizeEvent(lastEventId: id, onSuccess: { (events) in
            if !events.isEmpty{
                ConfigManager.shared.syncEventId = events.first!.id
            }
            
            events.forEach({ (event) in
                DispatchQueue.global(qos: .background).sync {
                    if event.id == id { return }
                    
                    switch event.actionTopic {
                    case .deletedMessage :
                        let ids = event.getDeletedMessageUniqId()
                        ids.forEach({ (id) in
                            if let comment = QiscusCore.database.comment.find(uniqueId: id) {
                                _ = QiscusCore.database.comment.delete(comment)
                            }
                        })
                        ConfigManager.shared.syncEventId = event.id
                    case .clearRoom:
                        let ids = event.getClearRoomUniqId()
                        ids.forEach({ (id) in
                            if let room = QiscusCore.database.room.find(uniqID: id) {
                                _ = QiscusCore.database.comment.clear(inRoom: room.id, timestamp: event.timestamp)
                            }
                        })
                        ConfigManager.shared.syncEventId = event.id
                        
                    case .noActionTopic:
                        break
                        
                    case .sent:
                        break
                        
                    case .delivered:
                        event.updatetStatusMessage()
                    case .read:
                        event.updatetStatusMessage()
                    }
                    
                }
               
            })
        }) { (error) in
            QiscusLogger.errorPrint("sync error, \(error.message)")
        }
    }
    
    private func sync() {
        DispatchQueue.global(qos: .background).sync {
            if ConfigManager.shared.isConnectedMqtt == false {
                var id = ConfigManager.shared.syncId
                let latestComment = ConfigManager.shared.lastCommentId
                
                if latestComment != "" && id != "" {
                    if id.contains(latestComment) == true {
                        //id same
                    }else{
                        id = latestComment
                    }
                }
                
                QiscusCore.shared.synchronize(lastMessageId: id, onSuccess: { (comments) in
                    self.syncEvent()
                    if let c = comments.first {
                        ConfigManager.shared.syncId = c.id
                    }
                }, onError: { (error) in
                    QiscusLogger.errorPrint("sync error, \(error.message)")
                })
            }
        }
        
    }
    
    //default is 30s
    private func syncAuto() {
        DispatchQueue.global(qos: .background).async {
            if ConfigManager.shared.isConnectedMqtt == true {
                var id = ConfigManager.shared.syncId
                let latestComment = ConfigManager.shared.lastCommentId
                
                if latestComment != "" && id != "" {
                    if id.contains(latestComment) == true {
                        //id same
                    }else{
                        id = latestComment
                    }
                }
                
                QiscusCore.shared.synchronize(lastMessageId: id, onSuccess: { (comments) in
                    self.syncEvent()
                    if let c = comments.first {
                        ConfigManager.shared.syncId = c.id
                    }
                }, onError: { (error) in
                    QiscusLogger.errorPrint("sync error, \(error.message)")
                })
            }
        }
    }
    
    private func pending() {
        DispatchQueue.global(qos: .background).sync {
            guard let comments = QiscusCore.database.comment.find(status: .pending) else { return }
            comments.reversed().forEach { (c) in
                // validation comment prevent id
                if c.uniqId.isEmpty { QiscusCore.database.comment.evaluate(); return }
                QiscusCore.shared.sendMessage(message: c, onSuccess: { (response) in
                     QiscusLogger.debugPrint("success send pending message \(response.uniqId)")
                     ConfigManager.shared.lastCommentId = response.id
                }, onError: { (error) in
                    QiscusLogger.errorPrint("failed send pending message \(c.uniqId)")
                })
            }
        }
    }
}
