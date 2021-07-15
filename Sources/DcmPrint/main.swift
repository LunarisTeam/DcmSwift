//
//  DcmPrint.swift
//  
//
//  Created by Rafael Warnault, OPALE on 23/06/2021.
//

import Foundation
import DcmSwift
import ArgumentParser


//struct DcmPrint: ParsableCommand {
//    @Argument(help: "Path of DICOM file to print")
//    var sourcePath: String
//
//    mutating func run() throws {
//        if let dicomFile = DicomFile(forPath: sourcePath) {
//            if let dataset = dicomFile.dataset {
//                Logger.info(dataset.description)
//            }
//        }
//    }
//}
//
//DcmPrint.main()

let path = "/Users/home/Desktop/DICOM Example/TEST_DICOMDIR/"

if let d = DicomDir.parse(atPath: path){
    //let _ = d.writeDicomDir(atPath: "/Users/home/Documents/Test write DICOMDIR/")
    //print(d.series)
    let a = d.index(forSeriesInstanceUID: "1.2.840.113619.2.5.1762879363.1818.1029819454.163")
    print(a)
}


/*
if let dir = DicomDir.parse(atPath: pathFolder) {
    for (a,b) in dir.studies {
        print("key : \(a) value : \(b)")
    }
}
*/

//let d2 = DicomDir.init(forPath: "/Users/home/Documents/Test write DICOMDIR/DICOMDIR")
//print(d2?.index)
