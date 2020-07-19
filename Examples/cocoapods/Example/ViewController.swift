//
//  ViewController.swift
//  Example
//
//  Created by Qiscus on 16/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import UIKit
import QiscusCore

class ViewController: UIViewController {
    let a = QiscusCore()
    let b = QiscusCore()
    override func viewDidLoad() {
        super.viewDidLoad()
        a.setup(WithAppID: "sampleapp-65ghcsaysse")
        
        a.enableDebugPrint = true
     
        b.setup(WithAppID: "sdksample")
        b.enableDebugMode(value: true)
        
        //login from appID A
        a.loginOrRegister(userID: "arief92", userKey: "arief92", onSuccess: { (user) in
            print("user: \(user.name)")
            print ("user a =\(self.a.getUserData()?.name)")
            self.a.shared.getAllChatRooms(showParticipant: false, showRemoved: false, showEmpty: true, page: 1, limit: 100, onSuccess: { (rooms, meta) in
                let dbRoom = self.a.database.room.all()
            }) { (error) in
                
            }
        }) { (error) in
            print(error.message)
        }
        
        //login from appID B
        b.loginOrRegister(userID: "arief10", userKey: "arief10", onSuccess: { (user) in
            print("user b: \(user.name)")
            print ("user b =\(self.b.getUserData()?.name)")
            self.b.shared.getAllChatRooms(showParticipant: false, showRemoved: false, showEmpty: true, page: 1, limit: 100, onSuccess: { (rooms, meta) in
                let dbRoom2 = self.b.database.room.all()
            }) { (error) in
                
            }
        }) { (error) in
            print(error.message)
        }
        
       
       
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
