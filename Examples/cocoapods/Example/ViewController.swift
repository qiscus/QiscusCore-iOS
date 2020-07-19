//
//  ViewController.swift
//  Example
//
//  Created by Qiscus on 14/07/20.
//  Copyright © 2020 Qiscus. All rights reserved.
//

import UIKit
import QiscusCore

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        QiscusCore.setup(WithAppID: "sdksample")
        QiscusCore.enableDebugPrint = true
        
        QiscusCore.loginOrRegister(userID: "arief92", userKey: "arief92", onSuccess: { (user) in
            print("user: \(user.username)")
            
            QiscusCore.shared.chatUser(userId: "arief93", onSuccess: { (room, comments) in
                
            }) { (error) in
                
            }
            
            QiscusCore.shared.getAllChatRooms(page: 1, limit: 100, onSuccess: { (rooms, meta) in
                
            }) { (error) in
                
            }
            
        }) { (error) in
            print(error.message)
        }
    }


}

