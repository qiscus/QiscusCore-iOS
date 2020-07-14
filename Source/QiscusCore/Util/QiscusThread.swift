//
//  QiscusThread.swift
//  QiscusCore
//
//  Created by Qiscus on 08/10/18.
//

import Foundation

class QiscusThread {
    static func background(_ work: @escaping () -> ()) {
        //DispatchQueue.global(qos: .userInitiated).async {
            work()
        //}
    }

    static func main(_ work: @escaping () -> ()) {
        //DispatchQueue.main.async {
            work()
        //}
    }
}
