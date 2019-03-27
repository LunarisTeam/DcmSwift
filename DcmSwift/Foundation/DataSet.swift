//
//  Dataset.swift
//  DICOM Test
//
//  Created by Rafael Warnault on 17/10/2017.
//  Copyright © 2017 Read-Write.fr. All rights reserved.
//

import Foundation





public class DataSet: DicomObject {
    public var fileMetaInformationGroupLength:Int32 = 0
    public var transferSyntax:String                = "1.2.840.10008.1.2.1"
    public var vrMethod:DicomSpec.VRMethod          = .Explicit
    public var byteOrder:DicomSpec.ByteOrder        = .LittleEndian
    private var readHeader:Bool                     = true
    
    public var metaInformationHeaderElements:[DataElement]  = []
    public var datasetElements:[DataElement]                = []
    public var allElements:[DataElement]                    = []
    
    private var data:Data!
    
    
    
    public override init() {
        initLogger()
    }
    
    
    public init?(withData data:Data, readHeader:Bool = true) {
        initLogger()
        
        self.data           = data
        self.readHeader     = readHeader
    }
    
    
    
    override public var description: String {
        var string = ""
        for e in self.allElements {
            string += e.description + "\n"
        }
        return string
    }
    
    
    
    // MARK: - Public methods
    public func loadData() -> Bool {
        var offset = 0
        
        if self.readHeader {
            offset = DicomConstants.dicomBytesOffset
        }
        
        // reset elements arrays
        self.metaInformationHeaderElements  = []
        self.datasetElements                = []
        self.allElements                    = []
        
        while(offset < data.count) {
            let (newElement, elementOffset) = self.readDataElement(offset: offset)
            
            if !self.validate(dataElement: newElement) {
                return false
            }
            
            if newElement.name == "FileMetaInformationGroupLength" {
                self.fileMetaInformationGroupLength = newElement.value as! Int32
            }
            
            // determine transfer syntax
            if newElement.name == "TransferSyntaxUID" {
                self.transferSyntax = newElement.value as! String
                
                if self.transferSyntax == DicomConstants.implicitVRLittleEndian {
                    self.vrMethod = .Implicit
                    self.byteOrder = .LittleEndian
                }
                else if self.transferSyntax == DicomConstants.explicitVRBigEndian {
                    self.vrMethod = .Explicit
                    self.byteOrder = .BigEndian
                }
                else {
                    self.vrMethod = .Explicit
                    self.byteOrder = .LittleEndian
                }
                
            }
            
            // append to sub-datasets
            if newElement.group != DicomConstants.metaInformationGroup {
                self.datasetElements.append(newElement)
            }
            else {
                self.metaInformationHeaderElements.append(newElement)
                
            }
            
            self.allElements.append(newElement)
            
            offset = elementOffset
        }
        
        // be sure to sort all dataset elements by group, then element
        self.sortElements()
        
        return true
    }

    
    
    
    
     public override func toData(vrMethod inVrMethod:DicomSpec.VRMethod = .Explicit, byteOrder inByteOrder:DicomSpec.ByteOrder = .LittleEndian) -> Data {
        var newData = Data()
        
        if self.readHeader {
            // write 128 bytes preamble
            newData.append(Data(repeating: 0x00, count: 128))
            
            // write DICM magic word
            newData.append(DicomConstants.dicomMagicWord.data(using: .utf8)!)
        }
        
        // be sure element are sorted properly before write
        self.sortElements()
        
        // append meta header elements as binary data
        for element in self.allElements {
            //print(type(of: element))
            newData.append(self.write(dataElement: element))
        }
        
        return newData
    }
    
    
    
    override public func toJSONArray() -> Any {
        var json:[String:[String:Any]] = [:]
        
        for element in self.allElements {
            
            var val:Any = ""
            
            if element.isMultiple {
                val = element.values.map { $0.value == "" ? "null" : $0.value }
            }
            else {
                if  element.vr == .OB ||
                    element.vr == .OD ||
                    element.vr == .OF ||
                    element.vr == .OW ||
                    element.vr == .UN {
                    if (element.data != nil) {
                        val = element.data.base64EncodedString()
                        
                    } else {
                        val = ""
                    }
                }
                else {
                    val = "\(element.value)"
                }
            }
            
            json[element.tagCode().uppercased()] = [
                "vr": "\(element.vr)",
                "value": val
            ]
        }
        
        return json
    }
    

    
    
    public func string(forTag tag:String ) -> String! {
        for el in self.allElements {
            if el.name == tag {
                return el.value as? String
            }
        }
        return nil
    }
    
    
    public func integer32(forTag tag:String ) -> Int32 {
        for el in self.allElements {
            if el.name == tag {
                return el.value as! Int32
            }
        }
        return 0
    }
    
    
    public func integer16(forTag tag:String ) -> Int16 {
        for el in self.allElements {
            if el.name == tag {
                return el.value as! Int16
            }
        }
        return 0
    }
    
    
    public func date(forTag tag:String ) -> Date! {
        for el in self.allElements {
            if el.name == tag {
                if let dicomDateString = el.value as? String {
                    return Date(dicomDate: dicomDateString)
                }
            }
        }
        return nil
    }
    
    
    public func datetime(forTag tag:String ) -> Date {
        return Date()
    }
    
    
    public func time(forTag tag:String ) -> Date {
        return Date()
    }
    
    
    
    
    public func set(value:Any, toElement element:DataElement) -> Bool {
        return element.setValue(value)
    }
    
    
    public func set(value:Any, forTagName name:String) -> DataElement? {
        // element already exists in dataset
        if let element = self.element(forTagName: name) {
            return self.set(value: value, toElement: element) ? element : nil
        }
        
        // element does not already exist in dataset
        if let element = DataElement(withTagName: name, dataset: self) {
            if element.setValue(value) {
                self.allElements.append(element)
                
                if (element.group == "0002") {
                    self.metaInformationHeaderElements.append(element)
                }
                else {
                    self.datasetElements.append(element)
                }
                
                self.sortElements()
                
                return element
            }
        }
        
        return nil
    }
    
    
    public func element(forTagName name:String) -> DataElement? {
        for el in self.allElements {
            if el.name == name {
                return el
            }
        }
        return nil
    }
    
    
    
    public func remove(dataElement element:DataElement) -> DataElement {
        if let index = self.allElements.index(where: {$0 === element}) {
            self.allElements.remove(at: index)
        }
        if let index = self.metaInformationHeaderElements.index(where: {$0 === element}) {
            self.metaInformationHeaderElements.remove(at: index)
        }
        if let index = self.datasetElements.index(where: {$0 === element}) {
            self.datasetElements.remove(at: index)
        }
        return element
    }
    
    

    public var dicomImage:DicomImage? {
        get {
            if let pixelDataElement = self.element(forTagName: "PixelData") {
                return DicomImage(self, withPixelDataElement: pixelDataElement)
            }
            return nil
        }
    }
    
    
    
    
    public func write(atPath path:String, vrMethod inVrMethod:DicomSpec.VRMethod? = nil, byteOrder inByteOrder:DicomSpec.ByteOrder? = nil) -> Bool {
        var finalVR     = self.vrMethod
        var finalOrder  = self.byteOrder
        
        if let inVR = inVrMethod {
            finalVR = inVR
        }
        if let inOrder = inByteOrder {
            finalOrder = inOrder
        }
        
        let data = self.toData(vrMethod: finalVR, byteOrder: finalOrder)
        
        // overwrite file
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                Swift.print("Error : Cannot overwrite file at path : \(path)")
                return false
            }
        }
        
        // write file to FS        
        return FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
    }
    
    
    
    
    
    
    
    
    // MARK: - Private methods
    
    
    
    private func sortElements() {
        self.allElements = self.allElements.sorted(by: { (a, b) -> Bool in
            if a.group != b.group {
                return a.group < b.group
            }
            return a.element < b.element
        })
        
        self.metaInformationHeaderElements = self.metaInformationHeaderElements.sorted(by: { (a, b) -> Bool in
            if a.group != b.group {
                return a.group < b.group
            }
            return a.element < b.element
        })
        
        self.datasetElements = self.datasetElements.sorted(by: { (a, b) -> Bool in
            if a.group != b.group {
                return a.group < b.group
            }
            return a.element < b.element
        })
    }
    
    
    private func validate(dataElement element:DataElement) -> Bool {
        if DicomSpec.shared.validate {
            if element.name == "TransferSyntaxUID" {
                if !DicomSpec.shared.isSupported(transferSyntax: element.value as! String) {
                    print("Validation error : this transfer syntax is not supported [\(element.value)]")
                    return false
                }
            }
            else if element.name == "SOPClassUID" {
                if !DicomSpec.shared.isSupported(sopClass: element.value as! String) {
                    print("Validation error : this SOP class is not supported [\(element.value)]")
                    return false
                }
            }
        }
        
        return true
    }
    
    
    
    
    
    
    private func readDataElement(offset:Int) -> (DataElement, Int) {
        var order:DicomSpec.ByteOrder           = .LittleEndian
        var localVRMethod:DicomSpec.VRMethod    = .Explicit
        var length:Int                          = 0
        var os                                  = offset

        
        // set local byte order to enforce Little Endian for Meta Information Header elements
        if self.byteOrder == .BigEndian && os >= self.fileMetaInformationGroupLength+144 {
            order = .BigEndian
        } else {
            order = .LittleEndian
        }

        if self.readHeader {
            // set local VR Method to enforce Explicit for Meta Information Header elements
            if self.vrMethod == .Implicit && os >= self.fileMetaInformationGroupLength+144 {
                localVRMethod = .Implicit
            } else {
                localVRMethod = .Explicit
            }
        } else {
            // force implicit if no header (truncated DICOM file, ACR-NEMA, etc)
            localVRMethod = .Implicit
        }
        
        // read tag
        let tagData = data.subdata(in: os..<os+4)
        let tag = DataTag(withData:tagData, byteOrder:order)
        
        os += 4
        
        // create new data element
        var element:DataElement = DataElement(withTag:tag, dataset: self)
        element.startOffset = os
        element.byteOrder = order
        
        // read VR
        if localVRMethod == .Explicit {
            element.vr = DicomSpec.vr(for: data.subdata(in: os..<os+2).toString())
            
            // 0000H reserved VR bytes
            // http://dicom.nema.org/dicom/2013/output/chtml/part05/sect_7.5.html
            if element.vr == .SQ {
                os += 4
            }
            // Table 7.1-1. Data Element with Explicit VR of OB, OW, OF, SQ, UT or UN
            // http://dicom.nema.org/Dicom/2013/output/chtml/part05/chapter_7.html
            else if element.vr == .OB ||
                element.vr == .OW ||
                element.vr == .OF ||
                element.vr == .SQ ||
                element.vr == .UT ||
                element.vr == .UN {
                os += 4
            } else {
                os += 2
            }
        }
        else {
            // if it's an implicit element group length
            // we set the VR as undefined
            if element.element == "0000" {
                element.vr = .UL
            }
                // else we take the VR from the spec
            else {
                // TODO: manage VR couples (ex: "OB/OW" in xml spec)
                element.vr = DicomSpec.shared.vrForTag(withCode:element.tag.code)
            }
        }
        

        
        // read length
        if localVRMethod == .Explicit {
            if element.vr == .SQ {
                let bytes:Data = self.data.subdata(in: os..<os+4)
                
                if bytes == Data(bytes: [0xff, 0xff, 0xff, 0xff]) {
                    length = -1
                } else {
                    length = Int(data.subdata(in: os..<os+4).toInt32(byteOrder: order))
                }
                os += 4
            } else if element.vr == .OB ||
                element.vr == .OW ||
                element.vr == .OF ||
                element.vr == .SQ ||
                element.vr == .UT ||
                element.vr == .UN {
                length = Int(data.subdata(in: os..<os+4).toInt32(byteOrder: order))
                os += 4
            } else {
                length = Int(data.subdata(in: os..<os+2).toInt16(byteOrder: order))
                os += 2
            }
        }
        else {
            // implicit length
            length = Int(data.subdata(in: os..<os+4).toInt32(byteOrder: order))
            os += 4
        }
        
        
        // MISSING VR FOR IMPLICIT ELEMENT
        // TODO: if VR is implicit, do we need to use the correpsonding tag VR ?
        element.dataOffset = os
        
        // read value data
        if element.vr == .OW || element.vr == .OB {
            if element.name == "PixelData" && length == -1 {
                let (sequence, seqOffset) = self.readPixelSequence(tag: tag, offset: os, byteOrder: order)
                sequence.parent         = element
                sequence.vr             = element.vr
                sequence.startOffset    = element.startOffset
                sequence.dataOffset     = element.dataOffset
                element                 = sequence
                os = seqOffset
            }
            else {
                element.data = data.subdata(in: os..<os+Int(length))
            }
        }
        else if element.vr == .SQ {
            let (sequence, seqOffset) = self.readDataSequence(tag:element.tag, offset: os, length: Int(length), byteOrder:order)
            sequence.parent         = element
            sequence.vr             = element.vr
            sequence.startOffset    = element.startOffset
            sequence.dataOffset     = element.dataOffset
            element                 = sequence
            
            if sequence.vrMethod == .Implicit {
                length = 0
            }
            
            os = seqOffset
        }
        else {
            // TODO: manage default value better ?
            if length > 0 {
                element.data = data.subdata(in: os..<os+Int(length))
            }
        }
        
        element.length = Int(length)
        
        if element.vr != .SQ {
            //element.value = value
        }
        
        os += Int(length)
        
        // is Pixel Data reached
        if element.tagCode() == "7fe00010" {
            os = data.count
        }
        
        element.endOffset = os
        
        return (element, os)
    }
    
    
    
    
    private func readDataSequence(tag:DataTag, offset:Int, length:Int, byteOrder:DicomSpec.ByteOrder) -> (DataSequence, Int) {
        let sequence:DataSequence = DataSequence(withTag:tag)
        var bytesRead = 0
        var os = offset
        
        if length > 0 {
            // data items
            while (length > bytesRead) {
                let tag = DataTag(withData: data.subdata(in: os..<os+4), byteOrder: byteOrder)
                bytesRead       += 4
                os              += 4
                
                let itemLength   = data.subdata(in: os..<os+4).toInt32(byteOrder: byteOrder)
                bytesRead       += 4
                os              += 4
                
                let item         = DataItem(withTag:tag, parent: sequence)
                item.length      = Int(itemLength)
                item.startOffset = os - 12
                item.dataOffset  = os
                sequence.items.append(item)
                
                // item data elements
                var itemBytesRead = 0
                while(itemLength > itemBytesRead) {
                    let (newElement, elementOffset) = self.readDataElement(offset: os)
                    newElement.parent = item
                    item.elements.append(newElement)
                    
                    itemBytesRead += elementOffset - os
                    bytesRead += elementOffset - os
                    
                    os = elementOffset                    
                }
                item.endOffset = os
            }
        }
            // Undefined Length data items (length == FFFFFFFF)
        else if length == -1 {
            sequence.vrMethod = .Implicit
            
            var tag = DataTag(withData: data.subdata(in: os..<os+4), byteOrder: byteOrder)
            os += 4
            
            while(tag.code == "fffee000") {
                let subdata = data.subdata(in: os..<os+4)
                var itemLength:Int16 = 0
                
                os += 4
                
                let item            = DataItem(withTag:tag, parent: sequence)
                item.startOffset    = os - 8
                item.dataOffset     = os
                item.vrMethod       = .Implicit
                
                sequence.items.append(item)
                
                // Undefined Length data elements (ffffffff)
                if subdata == Data(bytes: [0xff, 0xff, 0xff, 0xff]) {
                    var reachEnd = false
                    
                    while(reachEnd == false) {
                        let subtag = DataTag(withData: data.subdata(in: os..<os+4), byteOrder: byteOrder)
                        
                        if subtag.code != "fffee00d" {
                            let (newElement, elementOffset) = self.readDataElement(offset: os)
                            newElement.parent = item
                            os = elementOffset
                            
                            item.elements.append(newElement)
                        } else {
                            reachEnd = true
                            os += 8
                        }
                    }
                    
                    if tag.code == "fffee0dd" {
                        os += 4
                    }
                    
                    tag = DataTag(withData: data.subdata(in: os..<os+4), byteOrder: byteOrder)
                    os += 4
                }
                // Length defined data elements
                else {
                    itemLength  = subdata.toInt16(byteOrder: byteOrder)
                    item.length = Int(itemLength)
                    
                    var itemBytesRead = 0
                    while(itemLength > itemBytesRead) {
                        let (newElement, elementOffset) = self.readDataElement(offset: os)
                        newElement.parent = item
                        item.elements.append(newElement)
                        
                        itemBytesRead += elementOffset - os
                        bytesRead += elementOffset - os
                        
                        os = elementOffset
                    }
                    
                    tag = DataTag(withData: data.subdata(in: os..<os+4), byteOrder: byteOrder)
                    os += 4
                }
                
                item.endOffset = os
            }
            
            os += 4
            
            // in order to return the good offset
            return (sequence, os)
        }
        // empty sequence
        else if length == 0 {
            // TODO: fix issue when a empty sequence is the element of an item
            //print("empty seq")
            //print(sequence)
        }
        
        return (sequence, offset)
    }
    
    
    
    
    private func readPixelSequence(tag:DataTag, offset:Int, byteOrder:DicomSpec.ByteOrder) -> (PixelSequence, Int) {
        let pixelSequence = PixelSequence(withTag: tag)
        var os = offset
        
        // read item tag
        var itemTag = DataTag(withData: data.subdata(in: os..<os+4), byteOrder: byteOrder)
        os += 4
        
        while itemTag.code != "fffee0dd" {
            // read item
            let item            = DataItem(withTag: itemTag)
            item.startOffset    = os - 4
            item.dataOffset     = os
            item.vrMethod       = .Explicit
            
            pixelSequence.items.append(item)
            
            // read item length
            let itemLength = data.subdata(in: os..<os+4).toInt32(byteOrder: byteOrder)
            os += 4
            
            item.length = Int(itemLength)
            
            if itemLength > 0 {
                item.data = data.subdata(in: os..<os+Int(itemLength))
                os += Int(itemLength)
            }
            
            // read next again
            if os < self.data.count {
                itemTag = DataTag(withData: data.subdata(in: os..<os+4), byteOrder: byteOrder)
                os += 4
            }
        }
        
        return (pixelSequence, os)
    }
    
    
    
    
    
    private func write(dataElement element:DataElement, vrMethod:DicomSpec.VRMethod = .Explicit, byteOrder:DicomSpec.ByteOrder = .LittleEndian) -> Data {
        var data = Data()
        var localVRMethod:DicomSpec.VRMethod = .Explicit
        var order:DicomSpec.ByteOrder = .LittleEndian
        
        // set local byte order to enforce Little Endian for Meta Information Header elements
        if self.byteOrder == .BigEndian && element.endOffset > self.fileMetaInformationGroupLength+144 {
            order = .BigEndian
        }
        
        if self.readHeader {
            // set local VR Method to enforce Explicit for Meta Information Header elements
            if self.vrMethod == .Implicit && element.endOffset > self.fileMetaInformationGroupLength+144 {
                localVRMethod = .Implicit
            }
        } else {
            // force implicit if no header (always implicit, truncated DICOM file, ACR-NEMA, etc)
            localVRMethod = .Implicit
        }
        
        // write tag code
        data.append(element.toData(vrMethod: localVRMethod, byteOrder: order))
        
        return data
    }
    
    
    
}
