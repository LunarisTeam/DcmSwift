//
//  DcmEcho.swift
//  
//
//  Created by Rafael Warnault on 25/06/2021.
//

import Foundation
import DcmSwift
import ArgumentParser

struct DcmEcho: ParsableCommand {
    @Option(name: .shortAndLong, help: "DcmEcho local AET")
    var callingAET: String = "DCMCLIENT"
    
    @Argument(help: "Remote AE title")
    var calledAET: String = "DCMSERVER"
    
    @Argument(help: "Remote AE hostname")
    var calledHostname: String = "127.0.0.1"
    
    @Argument(help: "Remote AE port")
    var calledPort: Int = 11112
    
    mutating func run() throws {
        let callingAE   = DicomEntity(title: callingAET, hostname: "127.0.0.1", port: 11115)
        let calledAE    = DicomEntity(title: calledAET, hostname: calledHostname, port: calledPort)

        let client = DicomClient(localEntity: callingAE, remoteEntity: calledAE)

        client.connect { (connected, error) in
            if connected {
                client.echo { (message) in
                    Logger.info("ECHO Succeeded: \(message.messageName())")
                }
                errorCompletion: { (error) in
                    if let e = error?.description {
                        Logger.error("ECHO Failed: \(e)")
                    }
                }
                closeCompletion: { (association) in
                    
                }

            } else {
                if let e = error?.description {
                    Logger.error("CONNECT Error: \(e)")
                }
            }
        }
    }
}

DcmEcho.main()
