//
//  PDUMessage.swift
//  DcmSwift
//
//  Created by Rafael Warnault on 02/05/2019.
//  Copyright © 2019 Read-Write.fr. All rights reserved.
//

import Foundation


public protocol PDUResponsable {
    func handleResponse(data:Data) -> PDUMessage?
    func handleRequest() -> PDUMessage?
}


public class PDUMessage: PDUResponsable, PDUDecodable, PDUEncodable {
    public var pduType:PDUType!
    public var commandField:CommandField?
    public var association:DicomAssociation!
    public var dimseStatus:DIMSEStatus!
    public var flags:UInt8!
    public var responseDataset:DataSet!
    public var errors:[DicomError] = []
    public var debugDescription:String = "No message description"
    public var requestMessage:PDUMessage?
    public var messageID = UInt16(1).bigEndian
    
    public init(pduType:PDUType, association:DicomAssociation) {
        self.pduType = pduType
        self.association = association
    }
    
    
    public convenience init(pduType:PDUType, commandField:CommandField, association:DicomAssociation) {
        self.init(pduType: pduType, association: association)
        self.commandField = commandField
    }


    
    public convenience init?(data:Data, pduType:PDUType, association:DicomAssociation) {
        self.init(pduType: pduType, association: association)
        
        if !decodeData(data: data) {
            return nil
        }
    }
    
    
    public convenience init?(data:Data, pduType:PDUType, commandField:CommandField, association:DicomAssociation) {
        self.init(pduType: pduType, commandField:commandField, association: association)
        
        if !decodeData(data: data) {
            return nil
        }
    }
    
    
    public func messageName() -> String {
        return "UNKNOW-DIMSE"
    }
    
    public func messagesData() -> [Data] {
        Logger.warning("Not implemented yet \(#function) \(self.pduType)")
        return []
    }
    
    
    public func data() -> Data {
        Logger.warning("Not implemented yet \(#function) \(self.pduType)")
        return Data()
    }
    
    
    public func decodeData(data:Data) -> Bool {
        Logger.warning("Not implemented yet \(#function) \(self.pduType)")
        return false
    }
    
    
    public func handleResponse(data:Data) -> PDUMessage? {
        Logger.warning("Not implemented yet \(#function) \(self.pduType)")
        return nil
    }

    public func handleRequest() -> PDUMessage? {
        return nil
    }
    
}
