//
//  ViewController.swift
//  Example
//
//  Created by Qiscus on 13/07/20.
//  Copyright © 2020 Qiscus. All rights reserved.
//

import UIKit
import QiscusRealtime

class ViewController: UIViewController {
private var client : QiscusRealtime? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let config = QiscusRealtimeConfig(appName: "sdksample", clientID: "sampleClientId", host: "realtime-jogja.qiscus.com", port: 1885)
        client = QiscusRealtime.init(withConfig: config)
        QiscusRealtime.enableDebugPrint = true
        client?.connect(username: "crowdid92", password: "crowdid92",delegate: self)
    }

}

extension ViewController :  QiscusRealtimeDelegate {
    func connectionState(change state: QiscusRealtimeConnectionState) {
        print("state = \(state)")
    }
    
    func disconnect(withError err: Error?) {
        print("error connect realtime")
    }
    
    func didReceiveUser(userEmail: String, isOnline: Bool, timestamp: String) {
        
    }
    
    func didReceiveMessage(data: String) {
        
    }
    
    func didReceiveMessageStatus(roomId: String, commentId: String, commentUniqueId: String, Status: MessageStatus, userEmail: String) {
        
    }
    
    func didReceiveUser(typing: Bool, roomId: String, userEmail: String) {
        
    }
    
    func didReceiveRoomEvent(roomID: String, data: String) {
        
    }
    
    
}


