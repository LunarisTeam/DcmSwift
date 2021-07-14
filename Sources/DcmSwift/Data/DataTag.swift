//
//  DataTag.swift
//  DcmSwift
//
//  Created by Rafael Warnault, OPALE on 26/10/2017.
//  Copyright © 2017 OPALE, Rafaël Warnault. All rights reserved.
//

import Foundation

public class DataTag : DicomObject {
    public var data:Data!
    public var group:String     = ""
    public var element:String   = ""
    
    public var bytreOrder:ByteOrder = .LittleEndian
    
    static func == (lhs: DataTag, rhs: DataTag) -> Bool {
        return lhs.group == rhs.group && lhs.element == rhs.element
    }
    
    public var code:String { return "\(self.group)\(self.element)" }
    public var name:String { return DicomSpec.shared.nameForTag(withCode: code) ?? "Unknow" }
    
    
    public init(withData data:Data, byteOrder:ByteOrder = .LittleEndian) {
        super.init()
        
        self.data       = data
        self.bytreOrder = byteOrder
        
        self.readData(withByteOrder: self.bytreOrder)
    }
    
    
    public init?(withStream stream:DicomInputStream, byteOrder:ByteOrder = .LittleEndian) {
        super.init()
        
        guard let tagData = stream.read(length: 4) else {
            return nil
        }
        
        if tagData.count < 4 {
            return nil
        }
        
        self.data       = tagData
        self.bytreOrder = byteOrder
        
        self.readData(withByteOrder: self.bytreOrder)
    }
    
    
    
    public init(withGroup group:String, element:String, byteOrder:ByteOrder = .LittleEndian) {
        super.init()
        
        self.group      = group
        self.element    = element
        self.bytreOrder = byteOrder
        
        self.writeData(withByteOrder: self.bytreOrder)
    }
    
    
    
    public func data(withByteOrder:ByteOrder) -> Data {
        var data = Data()
        
        if withByteOrder == .BigEndian {
            let groupIndex = self.group.index(self.group.startIndex, offsetBy:2)
            let group1 = String(self.group[..<groupIndex])
            let group2 = String(self.group[groupIndex...])
            
            if let subdata = group1.hexData() {
                data.append(subdata)
            }
            if let subdata = group2.hexData() {
                data.append(subdata)
            }
            
            let elementIndex = self.element.index(self.element.startIndex, offsetBy:2)
            let element1 = String(self.element[..<elementIndex])
            let element2 = String(self.element[elementIndex...])
            
            if let subdata = element1.hexData() {
                data.append(subdata)
            }
            if let subdata = element2.hexData() {
                data.append(subdata)
            }
            
        } else {
            let groupIndex = self.group.index(self.group.startIndex, offsetBy:2)
            let group1 = String(self.group[..<groupIndex])
            let group2 = String(self.group[groupIndex...])
            
            if let subdata = group2.hexData() {
                data.append(subdata)
            }
            if let subdata = group1.hexData() {
                data.append(subdata)
            }
            
            let elementIndex = self.element.index(self.element.startIndex, offsetBy:2)
            let element1 = String(self.element[..<elementIndex])
            let element2 = String(self.element[elementIndex...])
            
            if let subdata = element2.hexData() {
                data.append(subdata)
            }
            if let subdata = element1.hexData() {
                data.append(subdata)
            }
        }
        
        return data
    }
        
    private func writeData(withByteOrder:ByteOrder) {
        self.data = Data()
        
        if withByteOrder == .BigEndian {
            let groupIndex = self.group.index(self.group.startIndex, offsetBy:2)
            let group1 = String(self.group[..<groupIndex])
            let group2 = String(self.group[groupIndex...])
            
            if let subdata = group1.hexData() {
                self.data.append(subdata)
            }
            if let subdata = group2.hexData() {
                self.data.append(subdata)
            }
            
            let elementIndex = self.element.index(self.element.startIndex, offsetBy:2)
            let element1 = String(self.element[..<elementIndex])
            let element2 = String(self.element[elementIndex...])
            
            if let subdata = element1.hexData() {
                self.data.append(subdata)
            }
            if let subdata = element2.hexData() {
                self.data.append(subdata)
            }
            
        } else {
            let groupIndex = self.group.index(self.group.startIndex, offsetBy:2)
            let group1 = String(self.group[..<groupIndex])
            let group2 = String(self.group[groupIndex...])
            
            if let subdata = group2.hexData() {
                self.data.append(subdata)
            }
            if let subdata = group1.hexData() {
                self.data.append(subdata)
            }
            
            let elementIndex = self.element.index(self.element.startIndex, offsetBy:2)
            let element1 = String(self.element[..<elementIndex])
            let element2 = String(self.element[elementIndex...])

            if let subdata = element2.hexData() {
                self.data.append(subdata)
            }
            if let subdata = element1.hexData() {
                self.data.append(subdata)
            }
        }
    }
    

    
    
    
    private func readData(withByteOrder:ByteOrder) {
        if withByteOrder == .BigEndian {
            let group1      = self.data.subdata(in: 0..<1).toHex()
            let group2      = self.data.subdata(in: 1..<2).toHex()
            let elem1       = self.data.subdata(in: 2..<3).toHex()
            let elem2       = self.data.subdata(in: 3..<4).toHex()
            
            self.group      = group1 + group2
            self.element    = elem1  + elem2
        } else {
            let group1      = self.data.subdata(in: 0..<1).toHex()
            let group2      = self.data.subdata(in: 1..<2).toHex()
            let elem1       = self.data.subdata(in: 2..<3).toHex()
            let elem2       = self.data.subdata(in: 3..<4).toHex()
            
            self.group      = group2 + group1
            self.element    = elem2 + elem1
        }
    }
    
    
    override public var description: String {
        return "(\(self.group),\(self.element))"
    }
    
}
