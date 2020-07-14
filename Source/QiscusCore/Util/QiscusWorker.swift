//
//  QiscusWorker.swift
//  QiscusCore
//
//  Created by Qiscus on 09/10/18.
//

import Foundation

typealias Job = () -> Void

class QiscusWorker {
    
    var tasks : [Job] = [Job]()
    
    func resume() {
        tasks.forEach { (job) in
            job()
        }
    }
}
