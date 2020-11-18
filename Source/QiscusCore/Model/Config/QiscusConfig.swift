//
//  QiscusConfig.swift
//  QiscusCore
//
//  Created by Qiscus on 07/08/18.
//

import Foundation

public struct QiscusServer {
    public let url : URL
    public let realtimeURL      : String?
    public let realtimePort     : UInt16?
    public let brokerLBUrl      : String?
    
    public init (url: URL, realtimeURL: String?, realtimePort: UInt16?, brokerLBUrl: String? = nil) {
        //check for urlServerApi
        if (url.absoluteString.range(of: "/api/v2/mobile") == nil){
            self.url            = url.appendingPathComponent("/api/v2/mobile")
        }else{
            self.url            = url
        }
        
        //check for realtimeURL
        if let realtimeURL = realtimeURL{
            if (realtimeURL.range(of: "ssl://") != nil){
                let urlFull = realtimeURL.components(separatedBy: "ssl://")
                let ssl    = urlFull[0] 
                let baseRealtimeUrl = urlFull[1]
                
                //check again
                if (baseRealtimeUrl.range(of: ":") != nil){
                    let checkBase       = baseRealtimeUrl.components(separatedBy: ":")
                    let realtimeURL     = checkBase[0]
                    self.realtimeURL    = realtimeURL
                }else{
                    self.realtimeURL    = baseRealtimeUrl
                }
            }else{
                if (realtimeURL.range(of: ":") != nil){
                    let checkBase       = realtimeURL.components(separatedBy: ":")
                    let realtimeURL     = checkBase[0]
                    self.realtimeURL    = realtimeURL
                }else{
                    self.realtimeURL    = realtimeURL
                }
            }
        }else{
             self.realtimeURL        = realtimeURL
        }
       
        self.realtimePort       = realtimePort
        if let urlBroker = brokerLBUrl {
            self.brokerLBUrl    = urlBroker
        }else{
            self.brokerLBUrl    = nil
        }
        
    }
}
