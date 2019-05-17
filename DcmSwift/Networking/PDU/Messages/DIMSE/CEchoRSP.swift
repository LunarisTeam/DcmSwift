//
//  EchoRSP.swift
//  DcmSwift
//
//  Created by Rafael Warnault on 03/05/2019.
//  Copyright © 2019 Read-Write.fr. All rights reserved.
//

import Foundation

public class CEchoRSP: DataTF {
    public override func messageName() -> String {
        return "C-ECHO-RSP"
    }
    
    public override func data() -> Data {
        var data = Data()
        
        let pdvDataset = DataSet()
        _ = pdvDataset.set(value: CommandField.C_ECHO_RQ.rawValue.bigEndian, forTagName: "CommandField")
        _ = pdvDataset.set(value: self.association.abstractSyntax, forTagName: "AffectedSOPClassUID")
        _ = pdvDataset.set(value: UInt16(1).bigEndian, forTagName: "MessageID")
        _ = pdvDataset.set(value: UInt16(257).bigEndian, forTagName: "CommandDataSetType")
        
        let commandGroupLength = pdvDataset.toData().count
        _ = pdvDataset.set(value: UInt32(commandGroupLength).bigEndian, forTagName: "CommandGroupLength")
        
        var pdvData = Data()
        let pdvLength = commandGroupLength + 14
        pdvData.append(uint32: UInt32(pdvLength), bigEndian: true)
        pdvData.append(uint8: association.presentationContexts.keys.first!, bigEndian: true) // Context
        pdvData.append(byte: 0x03) // Flags
        pdvData.append(pdvDataset.toData())
        
        let pduLength = UInt32(pdvLength + 4)
        data.append(uint8: self.pduType.rawValue, bigEndian: true)
        data.append(byte: 0x00) // reserved
        data.append(uint32: pduLength, bigEndian: true)
        data.append(pdvData)
        
        return data
    }

    public override func decodeData(data: Data) -> Bool {
        super.decodeDIMSEStatus(data: data)
        
        if let s = self.dimseStatus, s.status == DIMSEStatus.Status.Success {
            return true
        }
        return false
    }
}

