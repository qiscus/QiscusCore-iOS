//
//  ViewController.swift
//  sample
//
//  Created by Qiscus on 26/08/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import UIKit
import QiscusCore

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        QiscusCore.setup(WithAppID: "sampleapp-65ghcsaysse")
        QiscusCore.enableDebugPrint = true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func clickLogin(_ sender: Any) {
        QiscusCore.connect(userID: "amsibsan", userKey: "12345678") { (user, error) in
            print("result:: \(user!)")
            //            QiscusCore.network.removeParticipants(roomId: "939225", userSdkEmail: ["mantab"], completion: { (success, error) in
            //                print("is success delete \(success)")
            //            })
            //            QiscusCore.network.getRoomList(showParticipant: true, page: 1, completion: { (rooms, meta, error) in
            //                if let roomList = rooms {
            //                    print("room list result \(roomList)")
            //                }
            //            })
            
            //            QiscusCore.network.clearComments(roomUniqueIds: ["e4acd029322accc8322a1a786bbe991f"])
            
            
            //            QiscusCore.network.postComment(roomId: "926962", comment: "halo cuy, from core", completion: { comment, error in
            //
            //            })
            //            QiscusCore.network.deleteComment(commentUniqueId: ["ios-15324189369190"], completion: { comments, error in
            //
            //            })
            //            QiscusCore.network.sync(lastCommentReceivedId: "5147992")
            //            QiscusCore.network.updateCommentStatus(roomId: "926962", lastCommentReadId: "5147992")
            //            QiscusCore.network.loadComments(roomId: "926962", completion: { comments, error in
            //                print("comment result \(comments)")
            //            })
            //            QiscusCore.networkManager.createRoom(name: "room kacang ini", participants: ["amsibsam", "jiwa"], completion: { (room, error) in
            //                if let qRoom = room {
            //                    print("room result \(qRoom)")
            //                }
            //            })
            
        }
    }
    
    
}

