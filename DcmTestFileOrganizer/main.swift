//
//  main.swift
//  DcmTestFileOrganizer
//
//  Created by Rafael Warnault on 08/06/2021.
//  Copyright © 2021 OPALE. All rights reserved.
//

import Foundation
import DcmSwift



//func clean(filename: String) -> String {
//    var string = filename
//
//    string = (string as NSString).replacingOccurrences(of: " ",  with: "")
//    string = (string as NSString).replacingOccurrences(of: ":",  with: "")
//    string = (string as NSString).replacingOccurrences(of: ",",  with: "")
//    string = (string as NSString).replacingOccurrences(of: "/",  with: "")
//    string = (string as NSString).replacingOccurrences(of: "\\", with: "")
//
//    return string
//}
//
//Logger.setMaxLevel(Logger.LogLevel.FATAL)
//
//if CommandLine.arguments.count != 2 {
//    print("Missing argument: DICOM files directory path")
//    exit(0)
//}
//
//let dirPath = CommandLine.arguments.last!
//let expandedDirPath = (dirPath as NSString).expandingTildeInPath
//
//var toRename:[String:String] = [:]
//var index = 0
//
//try? FileManager.default.contentsOfDirectory(atPath: expandedDirPath).forEach { (filename) in
//    let filePath = "\(expandedDirPath)/\(filename)"
//
//    if let dicomFile = DicomFile(forPath: filePath) {
//        guard let modality = dicomFile.dataset.string(forTag: "Modality") else {
//            print("Missing required DICOM attribute: Modality")
//            exit(0)
//        }
//
//        let transferSyntax  = DicomSpec.shared.nameForUID(withUID: dicomFile.dataset.transferSyntax)
//        let isMultiframe    = dicomFile.dicomImage!.isMultiframe ? "MULTI" : "SINGLE"
//
//        let photometricInterpretation = dicomFile.dataset.string(forTag: "PhotometricInterpretation") ?? "NULL"
//        let bitsAllocated = dicomFile.dataset.integer16(forTag: "BitsAllocated") ?? 0
//
//        var manufacturer = dicomFile.dataset.string(forTag: "Manufacturer") ?? "NULL"
//        var manufacturersModelName = dicomFile.dataset.string(forTag: "ManufacturersModelName") ?? "NULL"
//        var implementationVersionName = dicomFile.dataset.string(forTag: "ImplementationVersionName") ?? "NULL"
//        var softwareVersions = dicomFile.dataset.string(forTag: "SoftwareVersions") ?? "NULL"
//
//        manufacturer                = clean(filename: manufacturer)
//        manufacturersModelName      = clean(filename: manufacturersModelName)
//        implementationVersionName   = clean(filename: implementationVersionName)
//        softwareVersions            = clean(filename: softwareVersions)
//
//        let newFilename = "\(modality)_\(transferSyntax)_\(isMultiframe)_\(photometricInterpretation)_\(bitsAllocated)_\(manufacturer)_\(manufacturersModelName)_\(implementationVersionName)_\(softwareVersions)_\(index).dcm"
//
//        //print("\(filename)  :  \(newFilename)")
//
//        toRename[filePath] = "\(expandedDirPath)/\(newFilename)"
//
//        index += 1
//    }
//}
//
//// rename
//toRename.forEach { (key: String, value: String) in
//    try? FileManager.default.moveItem(at: URL(fileURLWithPath: key), to: URL(fileURLWithPath: value))
//}
//
//// delete oldies
//toRename.forEach { (key: String, value: String) in
//    try? FileManager.default.removeItem(at: URL(fileURLWithPath: key))
//}



/** A SIMPLE FILE TESTER */

let filePath = "/Users/nark/Development/Opale/Cocoa/DcmSwift/DcmSwiftTests/Test Files/US_JPEGBaseline1_MULTI_YBR_FULL_422_8_GEVingmedUltrasound_NULL_NULL_VividE9113.1.3_2.dcm"

if let dicomFile = DicomFile(forPath: filePath) {
    
}
