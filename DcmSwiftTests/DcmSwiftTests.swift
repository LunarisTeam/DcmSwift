//
//  DcmSwiftTests.swift
//  DcmSwiftTests
//
//  Created by Rafael Warnault on 29/10/2017.
//  Copyright © 2017 OPALE, Rafaël Warnault. All rights reserved.
//

import XCTest
import Cocoa
import DcmSwift

/**
 This class provides a suite of unit tests to qualify DcmSwift framework features.
 
 It is sort of decomposed by categories using boolean attributes you can toggle to target some features
 more easily (`testDicomFileRead`, `testDicomFileWrite`, `testDicomImage`, etc.)

 Some of the tests, especially those done around actual files, are dynamically generated using NSInvocation
 for better integration and readability.
 
 */
class DcmSwiftTests: XCTestCase {
    // Configure the test suite with the following boolean attributes
    
    /// Run tests on DICOM Date and Time
    private static var testDicomDateAndTime     = true
    
    /// Run tests to read files (rely on embedded test files, dynamically generated)
    private static var testDicomFileRead        = true
    
    /// Run tests to write files (rely on embedded test files, dynamically generated)
    private static var testDicomFileWrite       = true
    
    /// Run tests to update dataset (rely on embedded test files, dynamically generated)
    private static var testDicomDataSet         = false
    
    /// Run tests to read image(s) (rely on embedded test files, dynamically generated)
    private static var testDicomImage           = false
    
    
    internal var filePath:String!
    private var finderTestDir:String = ""
    private var printDatasets = false
    
    /**
     We mostly prepare the output directory for test to write test files back.
     */
    override func setUp() {
        super.setUp()
        
        // prepare a test output directory for rewritten files
        self.finderTestDir = String(NSString(string: "~/Desktop/DcmSwiftTests").expandingTildeInPath)
        
        do {
            try FileManager.default.createDirectory(atPath: self.finderTestDir, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
    }
    
    override func tearDown() {
        // code here
        super.tearDown()
    }
    
    
    /**
     Override defaultTestSuite to ease generation of dynamic tests
     and coustomized configuration using boolean attributes
     */
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(forTestCaseClass: DcmSwiftTests.self)
        
        let bundle = Bundle(for: DcmSwiftTests.self)
        let paths = bundle.paths(forResourcesOfType: "dcm", inDirectory: "Test Files")
        
        if testDicomDateAndTime {
            suite.addTest(DcmSwiftTests(selector: #selector(readDicomDate)))
            suite.addTest(DcmSwiftTests(selector: #selector(writeDicomDate)))
            suite.addTest(DcmSwiftTests(selector: #selector(dicomDateWrongLength)))
            suite.addTest(DcmSwiftTests(selector: #selector(readDicomTimeMidnight)))
            // TODO: fix it!
            //suite.addTest(DcmSwiftTests(selector: #selector(dicomTimeWrongLength)))
            suite.addTest(DcmSwiftTests(selector: #selector(dicomTimeWeirdTime)))
            suite.addTest(DcmSwiftTests(selector: #selector(readDicomTime)))
            suite.addTest(DcmSwiftTests(selector: #selector(writeDicomTime)))
            suite.addTest(DcmSwiftTests(selector: #selector(combineDateAndTime)))
            suite.addTest(DcmSwiftTests(selector: #selector(readWriteDicomRange)))
        }
        
        
        if testDicomFileRead {
            paths.forEach { path in
                let block: @convention(block) (DcmSwiftTests) -> Void = { t in
                    _ = t.readFile(withPath: path)
                }
                
                DcmSwiftTests.addFileTest(withName: "FileRead", inSuite: suite, withPath:path, block: block)
            }
        }
        
        
        if testDicomFileWrite {
            /**
             This test suite performs a read/write on a set of DICOM files without
             modifying them, them check the MD5 checksum to ensure the I/O features
             of DcmSwift work properly.
             */
            paths.forEach { path in
                let block: @convention(block) (DcmSwiftTests) -> Void = { t in
                    t.readWriteTest()
                }
                
                DcmSwiftTests.addFileTest(withName: "FileWrite", inSuite: suite, withPath:path, block: block)
            }
        }
        
        
        
        if testDicomDataSet {
            paths.forEach { path in
                let block: @convention(block) (DcmSwiftTests) -> Void = { t in
                    t.readUpdateWriteTest()
                }
                
                DcmSwiftTests.addFileTest(withName: "DataSet", inSuite: suite, withPath:path, block: block)
            }
        }
        
        if testDicomImage {
            paths.forEach { path in
                let block: @convention(block) (DcmSwiftTests) -> Void = { t in
                    t.readImageTest()
                }
                
                DcmSwiftTests.addFileTest(withName: "DicomImage", inSuite: suite, withPath:path, block: block)
            }
        }
        
        return suite
    }
    
    
    private class func addFileTest(withName name: String, inSuite suite: XCTestSuite, withPath path:String, block: Any) {
        var fileName = String((path as NSString).deletingPathExtension.split(separator: "/").last!)
        fileName = (fileName as NSString).replacingOccurrences(of: "-", with: "_")
        
        // with help of ObjC runtime we add new test method to class
        let implementation = imp_implementationWithBlock(block)
        let selectorName = "test_\(name)_\(fileName)"
        let selector = NSSelectorFromString(selectorName)
                        
        class_addMethod(DcmSwiftTests.self, selector, implementation, "v@:")
        
        // Generate a test for our specific selector
        let test = DcmSwiftTests(selector: selector)
        
        // Each test will take the size argument and use the instance variable in the test
        test.filePath = path
        
        // Add it to the suite, and the defaults handle the rest
        suite.addTest(test)
    }
    
    
    
    public func readDicomDate() {
        let ds1 = "20001201"
        let dd1 = Date(dicomDate: ds1)

        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let expected_res = "2000/12/01 00:00:00"

        XCTAssert(expected_res == df.string(from: dd1!))
        
        // ACR-NEMA date format
        let ds2 = "2000.12.01"
        let dd2 = Date(dicomDate: ds2)

        XCTAssert(expected_res == df.string(from: dd2!))
    }
    
    
    public func writeDicomDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        let ds1 = "2012/01/24"
        let d1  = dateFormatter.date(from: ds1)
        let dd1 = d1!.dicomDateString()
        
        XCTAssert(dd1 == "20120124")
    }

    public func dicomDateWrongLength() {
        // Must be 8 or 10 bytes
        var ds = ""
        for i in 0...11 {
            if i == 8 || i == 10 {
                ds += "1"
                continue
            }

            let dd = Date(dicomDate: ds)
            XCTAssert(dd == nil)

            ds += "1"
        }
    }
    
    
    public func readDicomTime() {
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let expected_res = "2000/01/01 14:32:50"

        let ds1 = "143250"
        let dd1 = Date(dicomTime: ds1)

        XCTAssert(expected_res == df.string(from: dd1!))



        // ACR-NEMA time format
        let ds2 = "14:32:50"
        let dd2 = Date(dicomTime: ds2)

        XCTAssert(expected_res == df.string(from: dd2!))
    }


    public func readDicomTimeMidnight() {
        let ds1 = "240000"
        let dd1 = Date(dicomTime: ds1)

        XCTAssert(dd1 == nil)

        // ACR-NEMA time format
        let ds2 = "24:00:00"
        let dd2 = Date(dicomTime: ds2)

        XCTAssert(dd2 == nil)
    }


//    public func dicomTimeWrongLength() {
//        var ds1 = "1"
//        for _ in 0...3 {
//            print("ds1  \(ds1)")
//            let dd1 = Date(dicomTime: ds1)
//            XCTAssert(dd1 == nil)
//            ds1 += "11"
//        }
//    }

    public func dicomTimeWeirdTime() {
        let ds1 = "236000"
        let dd1 = Date(dicomTime: ds1)

        XCTAssert(dd1 == nil)

        let ds2 = "235099"
        let dd2 = Date(dicomTime: ds2)

        XCTAssert(dd2 == nil)

        let ds3 = "255009"
        let dd3 = Date(dicomTime: ds3)

        XCTAssert(dd3 == nil)
    }
    
    public func writeDicomTime() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        let ds1 = "14:32:50"
        let d1  = dateFormatter.date(from: ds1)
        let dd1 = d1!.dicomTimeString()
                
        XCTAssert(dd1 == "143250.000000")
    }

    
    public func combineDateAndTime() {
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let expected_res = "2000/12/01 14:32:50"

        let ds1 = "20001201"
        let ts1 = "143250"
        
        let dateAndTime = Date(dicomDate: ds1, dicomTime: ts1)

        XCTAssert(expected_res == df.string(from: dateAndTime!))
    }
    
    
    
    
    public func readWriteDicomRange() {
        let ds1 = "20001201"
        let ds2 = "20021201"
        
        let dicomRange = "\(ds1)-\(ds2)"
        let dateRange = DateRange(dicomRange: dicomRange, type: DicomConstants.VR.DA)
        
        XCTAssert(dateRange!.range          == .between)
        XCTAssert(dateRange!.description    == "20001201-20021201")
    }
    
    

    public func readWriteTest() {
        XCTAssert(self.readWriteFile(withPath: self.filePath))
    }
    
    
    
    public func readTest() {
        XCTAssert(self.readFile(withPath: self.filePath))
    }
    
    
    public func readUpdateWriteTest() {
        XCTAssert(self.readUpdateWriteFile(withPath: self.filePath))
    }
    
    
    public func readImageTest() {
        XCTAssert(self.readImageFile(withPath: self.filePath))
    }
    
    
    
    
    private func readImageFile(withPath path:String, checksum:Bool = true) -> Bool {
        let fileName = path.components(separatedBy: "/").last!.replacingOccurrences(of: ".dcm", with: "")
        var writePath = "\(self.finderTestDir)/\(fileName)-rwi-test.png"
        
        Logger.info("#########################################################")
        Logger.info("# PIXEL DATA TEST")
        Logger.info("#")
        Logger.info("# Source file : \(path)")
        Logger.info("# Destination file : \(writePath)")
        Logger.info("#")
        
        if let dicomFile = DicomFile(forPath: path) {
            if printDatasets { Logger.info("\(dicomFile.dataset.description )") }
            
            Logger.info("# Read succeeded")
            
            if let dicomImage = dicomFile.dicomImage {
                for i in 0 ..< 1 {
                    writePath = "\(self.finderTestDir)/\(fileName)-rwi-test-\(i)"
                    
                    if let image = dicomImage.image(forFrame: i) {
                        if dicomFile.dataset.transferSyntax == DicomConstants.JPEG2000 ||
                           dicomFile.dataset.transferSyntax == DicomConstants.JPEG2000Part2 ||
                           dicomFile.dataset.transferSyntax == DicomConstants.JPEG2000LosslessOnly ||
                           dicomFile.dataset.transferSyntax == DicomConstants.JPEG2000Part2Lossless {
                            _ = image.writeToFile(file: writePath, atomically: true, usingType: NSBitmapImageRep.FileType.jpeg2000)
                        }
                        else if dicomFile.dataset.transferSyntax == DicomConstants.JPEGLossless ||
                                dicomFile.dataset.transferSyntax == DicomConstants.JPEGLosslessNonhierarchical {
                            _ = image.writeToFile(file: writePath, atomically: true, usingType: NSBitmapImageRep.FileType.jpeg)
                        }
                        else {
                            _ = image.writeToFile(file: writePath, atomically: true, usingType: NSBitmapImageRep.FileType.bmp)
                        }
                    } else {
                        Logger.info("# Error: while extracting Pixel Data")
                        Logger.info("#")
                        Logger.info("#########################################################")
                        return false
                    }
                }
            } else {
                Logger.info("# Error: while extracting Pixel Data")
                Logger.info("#")
                Logger.info("#########################################################")
                return false
                
            }
            
            Logger.info("#")
            Logger.info("#########################################################")
            
            return true
        }
        
        return true
    }
    
    
    
    /**
     This test reads a source DICOM file, updates its PatientName attribute, then writes a DICOM file copy.
     Then it re-reads the just updated DICOM file to set back its original PatientName and then checks data integrity against the source DICOM file using MD5
     */
    private func readUpdateWriteFile(withPath path:String, checksum:Bool = true) -> Bool {
        let fileName = path.components(separatedBy: "/").last!.replacingOccurrences(of: ".dcm", with: "")
        let writePath = "\(self.finderTestDir)/\(fileName)-rwu-test.dcm"
        
        Logger.info("#########################################################")
        Logger.info("# UPDATE INTEGRITY TEST")
        Logger.info("#")
        Logger.info("# Source file : \(path)")
        Logger.info("# Destination file : \(writePath)")
        Logger.info("#")
        
        if let dicomFile = DicomFile(forPath: path) {
            if printDatasets { Logger.info("\(dicomFile.dataset.description )") }
            
            Logger.info("# Read succeeded")
            
            let oldPatientName = dicomFile.dataset.string(forTag: "PatientName")
            
            if dicomFile.dataset.set(value: "Dicomix", forTagName: "PatientName") != nil {
                Logger.info("# Update succeeded")
            } else {
                Logger.error("# Update failed")
            }
            
            if (dicomFile.write(atPath: writePath)) {
                Logger.info("# Write succeeded")
                Logger.info("#")
                
                if let newDicomFile = DicomFile(forPath: writePath) {
                    Logger.info("# Re-read updated file read succeeded !!!")
                    Logger.info("#")
                    
                    if oldPatientName == nil {
                        Logger.error("# DICOM object do not provide a PatientName")
                        return false
                    }
                
                    if newDicomFile.dataset.set(value: oldPatientName!, forTagName: "PatientName") != nil {
                        Logger.error("# Restore PatientName failed")
                        return false
                    }
                    
                    if !newDicomFile.write(atPath: writePath) {
                        Logger.error("# Cannot write restored DICOM object")
                        return false
                    }
                    
                    let originalSum = shell(launchPath: "/sbin/md5", arguments: ["-q", path]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    let savedSum = shell(launchPath: "/sbin/md5", arguments: ["-q", writePath]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    
                    Logger.info("# Source file MD5 : \(originalSum)")
                    Logger.info("# Dest. file MD5  : \(savedSum)")
                    Logger.info("#")
                    
                    if originalSum == savedSum {
                        Logger.info("# Checksum succeeded: \(originalSum) == \(savedSum)")
                    }
                    else {
                        Logger.info("# Error: wrong checksum: \(originalSum) != \(savedSum)")
                        Logger.info("#")
                        Logger.info("#########################################################")
                        return false
                    }
                    
                } else {
                    Logger.error("# Re-read updated file read failed…")
                    Logger.info("#")
                    Logger.info("#########################################################")
                    return false
                }
            }
            else {
                Logger.error("# Error: while writing file: \(writePath)")
                Logger.info("#")
                Logger.info("#########################################################")
                return false
            }
            
            Logger.info("#")
            Logger.info("#########################################################")
            
            return true
        }
        
        return true
    }
    
    
    
    
    private func readWriteFile(withPath path:String, checksum:Bool = true) -> Bool {
        let fileName = path.components(separatedBy: "/").last!.replacingOccurrences(of: ".dcm", with: "")
        let writePath = "\(self.finderTestDir)/\(fileName)-rw-test.dcm"
        
        Logger.info("#########################################################")
        Logger.info("# READ/WRITE INTEGRITY TEST")
        Logger.info("#")
        Logger.info("# Source file : \(path)")
        Logger.info("# Destination file : \(writePath)")
        Logger.info("#")
        
        if let dicomFile = DicomFile(forPath: path) {
            if printDatasets { Logger.info("\(dicomFile.dataset.description )") }
            
            Logger.info("# Read succeeded")
            
            if (dicomFile.write(atPath: writePath)) {
                Logger.info("# Write succeeded")
                Logger.info("#")
                
                let sourceFileSize  = self.fileSize(filePath: path)
                let destFileSize    = self.fileSize(filePath: writePath)
                let deviationPercents = (Double(sourceFileSize) - Double(destFileSize)) / Double(sourceFileSize) * 100.0
                
                Logger.info("# Source file size : \(sourceFileSize) bytes")
                Logger.info("# Dest. file size  : \(destFileSize) bytes")
                
                if deviationPercents > 0.0 {
                    Logger.info("# Size deviation   : \(String(format:"%.8f", deviationPercents))%")
                }
                
                Logger.info("#")
                
                Logger.info("# Calculating checksum...")
                Logger.info("#")
                
                let originalSum = shell(launchPath: "/sbin/md5", arguments: ["-q", path]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let savedSum = shell(launchPath: "/sbin/md5", arguments: ["-q", writePath]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                Logger.info("# Source file MD5 : \(originalSum)")
                Logger.info("# Dest. file MD5  : \(savedSum)")
                Logger.info("#")
                
                if originalSum == savedSum {
                    Logger.info("# Checksum succeeded: \(originalSum) == \(savedSum)")
                }
                else {
                    Logger.info("# Error: wrong checksum: \(originalSum) != \(savedSum)")
                    Logger.info("#")
                    Logger.info("#########################################################")
                    return false
                }
            }
            else {
                Logger.info("# Error: while writing file: \(writePath)")
                Logger.info("#")
                Logger.info("#########################################################")
                return false
            }
            
            Logger.info("#")
            Logger.info("#########################################################")
            
            return true
        }
        
        return true
    }
    
    
    
    private func readFile(withPath path:String, checksum:Bool = true) -> Bool {
        let fileName = path.components(separatedBy: "/").last!.replacingOccurrences(of: ".dcm", with: "")
        let writePath = "\(self.finderTestDir)/\(fileName)-rw-test.dcm"
        
        Logger.info("#########################################################")
        Logger.info("# READ/WRITE INTEGRITY TEST")
        Logger.info("#")
        Logger.info("# Source file : \(path)")
        Logger.info("# Destination file : \(writePath)")
        Logger.info("#")
        
        if let dicomFile = DicomFile(forPath: path) {
            if printDatasets { Logger.info("\(dicomFile.dataset.description )") }
            
            Logger.info("# Read succeeded")
            Logger.info("#")
            Logger.info("#########################################################")
            
            return true
        }
        
        return true
    }
    
    
    
    
    private func filePath(forName name:String) -> String {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: name, ofType: "dcm")!
        
        return path
    }
    
    
    
    func fileSize(filePath:String) -> UInt64 {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: filePath)
            let dict = attr as NSDictionary
            
            return dict.fileSize()
        } catch {
            print("Error: \(error)")
            
            return 0
        }
    }
    
    
    
    private func shell(launchPath: String, arguments: [String]) -> String {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = String(data: data, encoding: String.Encoding.utf8)!
        
        return output
    }
}
