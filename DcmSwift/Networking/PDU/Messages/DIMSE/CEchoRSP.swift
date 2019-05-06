//
//  EchoRSP.swift
//  DcmSwift
//
//  Created by Rafael Warnault on 03/05/2019.
//  Copyright © 2019 Read-Write.fr. All rights reserved.
//

import Foundation

class CEchoRSP: DataTF {
    public override func data() -> Data {
        return Data()
    }

    public override func decodeData(data: Data) -> Bool {
        super.decodeDIMSEStatus(data: data)
        
        if let s = self.dimseStatus, s.status == DIMSEStatus.Status.Success {
            return true
        }
        return false
    }
}

