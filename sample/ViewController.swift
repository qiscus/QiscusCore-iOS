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
    
    var rooms = [RoomModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        QiscusCore.setup(WithAppID: "sampleapp-65ghcsaysse")
        QiscusCore.enableDebugPrint = true
        
        if QiscusCore.isLogined {
            // database
            rooms = QiscusCore.database.room.all()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func clickLogin(_ sender: Any) {
        QiscusCore.login(userID: "amsibsan", userKey: "12345678") { (user, error) in
            print("result:: \(user!)")
            
            QiscusCore.shared.getAllRoom(completion: { (rooms, meta, error) in
                if let r = rooms {
                    print("rooms count : \(r.count)")
                }else {
                    if let message = error?.message {
                        print(message)
                    }
                }
            })
        }
    }
    
    
}

