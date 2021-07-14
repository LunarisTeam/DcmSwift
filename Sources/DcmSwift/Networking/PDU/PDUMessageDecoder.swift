//
//  File.swift
//  
//
//  Created by Rafael Warnault on 14/07/2021.
//

import Foundation
import NIO

public struct PDUMessageDecoder: ByteToMessageDecoder {
    public typealias InboundOut = ByteBuffer
    
    private var association:DicomAssociation!
    private var pduType:[UInt8]?
    private var deadByte:[UInt8]?
    private var length:[UInt8]?
    private var data:[UInt8]?
    var payload = ByteBuffer()
    
    public init(withAssociation association: DicomAssociation) {
        self.association = association
    }

    public mutating func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) -> DecodingState {
        if pduType == nil {
            guard let pt = buffer.readBytes(length: 1) else {
                return .needMoreData
            }

            pduType = pt
        }

        if deadByte == nil {
            guard let db = buffer.readBytes(length: 1) else {
                return .needMoreData
            }

            deadByte = db
        }

        if length == nil {
            guard let l = buffer.readBytes(length: 4) else {
                return .needMoreData
            }

            length = l
        }

        if data == nil {
            let realLength = Int(Data(length!).toInt32(byteOrder: .BigEndian))

            guard let d = buffer.readBytes(length: realLength) else {
                return .needMoreData
            }

            data = d
        }

        payload.writeBytes(pduType!)
        payload.writeBytes(deadByte!)
        payload.writeBytes(length!)
        payload.writeBytes(data!)

        context.fireChannelRead(self.wrapInboundOut(payload))
        
        payload.clear()
        
        pduType     = nil
        deadByte    = nil
        length      = nil
        data        = nil
        
        return .continue
    }
}
