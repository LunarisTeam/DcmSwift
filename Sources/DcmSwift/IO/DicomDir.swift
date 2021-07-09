//
//  File.swift
//  
//
//  Created by Colombe on 29/06/2021.
//

import Foundation

/**
    Class representing a Dicom Directory and all associated methods.
    DICOMDIR stores the informatique about a DICOM files in a given file directoru (folder). Thus, DICOMDIR plays the role of
    a small DICOM database, or an index of DICOM files, placed in the root folder of the media (like a DVD).
 */
public class DicomDir:DicomFile {
    private var offset:Int = 0
    private var offsetFirst:Int = 0
    private var offsetLast:Int = 0
    
    public var index:[String] = []
    
    // PatientID:PatientName
    public var patients:[String:String] = [:]
    
    // StudyInstanceUID:[PatientID,StudyDate,StudyTime,StudyDescription]
    public var studies:[String:[Any]] = [:]
    
    // SeriesInstanceUID:[StudyInstanceUID
    public var series:[String:String] = [:]
    //public var series:[String:[String]] = [:]
    
    // ReferencedSOPInstanceUIDInFile:[SeriesInstanceUID,filepath]
    public var images:[String:[String]] = [:]
    
    
    // MARK: - Methods
    
    /**
        Load a DICOMDIR for a given path
     */
    public override init?(forPath filepath: String) {
        super.init(forPath: filepath)
    }
    
    /**
        Create a void DICOMDIR
     */
    public override init() {
        super.init()
    }
    
    /**
        Return a boolean that indicates if a file is a DICOMDIR. 
    */
    public static func isDicomDir(forPath filepath: String) -> Bool {
        let inputStream = DicomInputStream(filePath: filepath)
        
        do {
            if let dataset = try inputStream.readDataset() {
                //print("offset : \(inputStream.offset)")
                
                if dataset.hasElement(forTagName:"DirectoryRecordSequence") {
                    return true
                } else {
                    return false
                }
            }
        } catch _ {
            return false
        }
        return false
    }
    
    
    override func read() -> Bool {
        let rez = super.read()
        
        if rez == false {
            return false
        }
        
        load()
        
        return rez
    }
    
    /**
        Return an array of String wich represents all the DICOM files corresponding to a given patient
    */
    public func index(forPatientID givenID:String) -> [String] {
        var resultat : [String] = []
        
        for(patientsID,_) in patients {
            if(patientsID == givenID) {
                for(studyUID, arrayStudies) in studies {
                    if(patientsID == arrayStudies[0] as? String) {
                        for(seriesUID, studyUID_2) in series {
                            if(studyUID == studyUID_2) {
                                for(_,array) in images {
                                    if(array[0] == seriesUID) {
                                        let path = array[1]
                                        if(path != DicomDir.amputation(forPath: filepath)) {
                                            resultat.append(path)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return resultat
    }
    
    /**
        Return an array of String wich represents all the DICOM files corresponding to a given study
     */
    public func index(forStudyInstanceUID givenStudyUID:String) -> [String] {
        var resultat : [String] = []
        
        for(_,_) in patients {
            for(studyUID, _) in studies {
                if(studyUID == givenStudyUID) {
                    for(seriesUID, studyUID_2) in series {
                        if(studyUID == studyUID_2) {
                            for(_,array) in images {
                                if(array[0] == seriesUID) {
                                    let path = array[1]
                                    if(path != DicomDir.amputation(forPath: filepath)) {
                                        resultat.append(path)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return resultat
    }
    
    /**
        Return an array of String wich represents all the DICOM files corresponding to a given serie
     */
    public func index(forSeriesInstanceUID givenSeriesUID:String) -> [String] {
        var resultat : [String] = []
        
        for(_,_) in patients {
            for(_,_) in studies {
                for(seriesUID, _) in series {
                    if(seriesUID == givenSeriesUID) {
                        for(_,array) in images {
                            if(array[0] == seriesUID) {
                                let path = array[1]
                                if(path != DicomDir.amputation(forPath: filepath)) {
                                    if !resultat.contains(path) {
                                        resultat.append(path)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return resultat
    }
    
    /**
        Load all the properties of a DicomDir instance (patients, index etc)
     */
    private func load() {
        if let dataset = self.dataset {
            if let directoryRecordSequence = dataset.element(forTagName: "DirectoryRecordSequence") as? DataSequence {
                var patientName     = ""
                var patientID       = ""
                
                var studyUID        = ""
                var studyDate       = ""
                var studyTime       = ""
                var studyDescri     = ""
                
                var serieUID        = ""
                var SOPUID          = ""
                var path            = ""
                
                for item in directoryRecordSequence.items {
                    
                    for element in item.elements {
                    // Load the index property
                        if(element.name == "ReferencedFileID") {
                            path = DicomDir.amputation(forPath: filepath)
                            for dataValue in element.values {
                                path += "/" + dataValue.value
                            }
                            if(path != DicomDir.amputation(forPath: filepath)) {
                                index.append(path)
                            }
                        } 
                         
                    // Load the patients property
                        if element.name == "PatientName" {
                            patientName = "\(element.value)"
                        }
                            
                        if element.name == "PatientID" {
                            patientID = "\(element.value)"
                        }
                        
                    // Load the studies property
                        if element.name == "StudyInstanceUID" {
                            studyUID = "\(element.value)"
                            if studyUID.count > 0 {
                                studies[studyUID]?.insert(patientID, at: 0)
                            }
                        }
                        
                        if element.name == "StudyDate" {
                            studyDate = "\(element.value)"
                            studies[studyUID]?.insert(studyDate, at: 1)
                        }
                        
                        if element.name == "StudyTime" {
                            studyTime = "\(element.value)"
                            studies[studyUID]?.insert(studyTime, at: 2)
                        }
                        
                        if element.name == "StudyDescription" {
                            studyDescri = "\(element.value)"
                            studies[studyUID]?.insert(studyDescri, at: 3)
                        }
                        
                    // Load the series property
                        if element.name == "SeriesInstanceUID" {
                            serieUID = "\(element.value)"
                            if serieUID.count > 0 {
                                series[serieUID] = studyUID
                            }
                        }
                        
                        if element.name == "SeriesNumber" {
                            studyDate = "\(element.value)"
                        }
                    
                    // Load the images property
                        if element.name == "ReferencedSOPInstanceUIDInFile" {
                            SOPUID = "\(element.value)"
                            if SOPUID.count > 0 && serieUID.count > 0 {
                                if(path != DicomDir.amputation(forPath: filepath)) {
                                    images[SOPUID] = [serieUID,path]
                                }
                            }
                        }
                    }
                    
                    if patientName.count > 0 && patientID.count > 0 {
                        patients[patientID] = patientName
                    }
                }
            }
        }
    }
    
    public static func studies(forPath filepath: String) {
        
    }
    
//    private func truncate(forPath filepath: String) -> String  {
//        return NSString(string: filepath).deletingLastPathComponent
//    }
    
    /**
        Return a String without the last part (after the last /)
     */
    public static func amputation(forPath filepath: String) -> String {
        var stringAmputee = ""
        let array = filepath.components(separatedBy: "/")
        let size = array.count
        for i in 0 ..< size-1 {
            if i == size-2 {
                stringAmputee += array[i]
            } else {
                stringAmputee += array[i] + "/"
            }
        }
        return stringAmputee
    }
    
    /**
        Create the DirectoryRecordSequence using the given properties : patients, studies, series, images.
     */
    public func createDirectoryRecordSequence() -> DataSequence? {
        let dataTag = DataTag.init(withGroup: "0004", element: "1220", byteOrder: .LittleEndian)
        let sequence:DataSequence = DataSequence(withTag: dataTag, parent: nil)
        var cpt = 1
        offset += sequence.toData().count
        
        for(patientID,patientName) in patients {
            let tagItem = DataTag.init(withGroup: "fffe", element: "e000", byteOrder: .LittleEndian)
            let item = DataItem(withTag: tagItem, parent: sequence)
            
            if(cpt == 1) {
                offsetFirst = offset
                print("offsetFirst \(offsetFirst)")
            } else if(cpt == patients.count) {
                offsetLast = offset
                print("offsetLast \(offsetLast)")
            }
            
            offset += item.toData().count
            
            sequence.items.append(item)
            
            let tagOffsetNext = DataTag.init(withGroup: "0004", element: "1400", byteOrder: .LittleEndian)
            let tagRecordInUseFlag = DataTag.init(withGroup: "0004", element: "1410", byteOrder: .LittleEndian)
            let tagID = DataTag.init(withGroup: "0010", element: "0020", byteOrder: .LittleEndian)
            let tagName = DataTag.init(withGroup: "0010", element: "0010", byteOrder: .LittleEndian)
            let tagType = DataTag.init(withGroup: "0004", element: "1430", byteOrder: .LittleEndian)
            let tagCharacterSet = DataTag.init(withGroup: "0008", element: "0005", byteOrder: .LittleEndian)
            
            let elementOffsetNext = DataElement(withTag: tagOffsetNext, parent: item)
            let elementRecordInUseFlag = DataElement(withTag: tagRecordInUseFlag, parent: item)
            let elementPatientID = DataElement(withTag: tagID, parent: item)
            let elementPatientName = DataElement(withTag: tagName, parent: item)
            let elementPatientType = DataElement(withTag: tagType, parent: item)
            let elementCharacterSet = DataElement(withTag: tagCharacterSet, parent: item)
            
            _ = elementOffsetNext.setValue(UInt32(4820).bigEndian) //TODO:INSERT REAL VALUE
            _ = elementRecordInUseFlag.setValue(-1)
            _ = elementPatientID.setValue(patientID)
            _ = elementPatientName.setValue(patientName)
            _ = elementPatientType.setValue("PATIENT")
            _ = elementCharacterSet.setValue("ISO_IR 100")
            
            
            offset += elementOffsetNext.toData().count
            offset += elementRecordInUseFlag.toData().count
            offset += elementPatientID.toData().count
            offset += elementPatientName.toData().count
            offset += elementPatientType.toData().count
            offset += elementCharacterSet.toData().count
        
            item.elements.append(elementOffsetNext)
            item.elements.append(elementRecordInUseFlag)
            item.elements.append(elementPatientType)
            item.elements.append(elementCharacterSet)
            item.elements.append(elementPatientName)
            item.elements.append(elementPatientID)
            
            for(studyID,patientID_2) in studies {
                
                if(patientID == patientID_2[0] as? String) {
                
                    let tagItem = DataTag.init(withGroup: "fffe", element: "e000", byteOrder: .LittleEndian)
                    let item = DataItem(withTag: tagItem, parent: sequence)
                    sequence.items.append(item)
                    
                    let tagstID = DataTag.init(withGroup: "0020", element: "000d", byteOrder: .LittleEndian)
                    let tagstDescription = DataTag.init(withGroup: "0008", element: "1030", byteOrder: .LittleEndian)
                    let tagstDate = DataTag.init(withGroup: "0008", element: "0020", byteOrder: .LittleEndian)
                    let tagstTime = DataTag.init(withGroup: "0008", element: "0030", byteOrder: .LittleEndian)
                    
                    let elementStudyInstanceUID = DataElement(withTag: tagstID, parent: item)
                    let elementStudyType = DataElement(withTag: tagType, parent: item)
                    let elementStudyDate = DataElement(withTag: tagstDate, parent: item)
                    let elementStudyTime = DataElement(withTag: tagstTime, parent: item)
                    let elementStudyDescri = DataElement(withTag: tagstDescription, parent: item)
                    
                    _ = elementRecordInUseFlag.setValue(-1)
                    _ = elementStudyType.setValue("STUDY")
                    _ = elementStudyDate.setValue(patientID_2[1])
                    _ = elementStudyTime.setValue(patientID_2[2])
                    _ = elementStudyDescri.setValue(patientID_2[3])
                    _ = elementStudyInstanceUID.setValue(studyID)
                    
                    offset += elementRecordInUseFlag.toData().count
                    offset += elementStudyType.toData().count
                    offset += elementStudyDate.toData().count
                    offset += elementStudyTime.toData().count
                    offset += elementStudyDescri.toData().count
                    offset += elementStudyInstanceUID.toData().count
                    
                    item.elements.append(elementRecordInUseFlag)
                    item.elements.append(elementStudyType)
                    item.elements.append(elementStudyDate)
                    item.elements.append(elementStudyTime)
                    //item.elements.append(elementCharacterSet)
                    item.elements.append(elementStudyInstanceUID)
                    
                    for(serieID,studyID_2) in series {
                        
                        if(studyID == studyID_2) {
                        
                            let tagItem = DataTag.init(withGroup: "fffe", element: "e000", byteOrder: .LittleEndian)
                            let item = DataItem(withTag: tagItem, parent: sequence)
                            sequence.items.append(item)
                            
                            let tagseID = DataTag.init(withGroup: "0020", element: "000e", byteOrder: .LittleEndian)
                            
                            let elementSerieInstanceUID = DataElement(withTag: tagseID, parent: item)
                            let elementSerieType = DataElement(withTag: tagType, parent: item)
                            
                            _ = elementSerieInstanceUID.setValue(serieID)
                            _ = elementSerieType.setValue("SERIE")
                            
                            offset += elementSerieInstanceUID.toData().count
                            offset += elementSerieType.toData().count
                            
                            item.elements.append(elementSerieType)
                            item.elements.append(elementSerieInstanceUID)
                            
                            for(sop,array) in images {
                                
                                if(array[0] == serieID) {
                                
                                    let tagItem = DataTag.init(withGroup: "fffe", element: "e000", byteOrder: .LittleEndian)
                                    let item = DataItem(withTag: tagItem, parent: sequence)
                                    sequence.items.append(item)
                                    
                                    let tagSOP = DataTag.init(withGroup: "0004", element: "1511", byteOrder: .LittleEndian)
                                    
                                    let elementImageSOP = DataElement(withTag: tagSOP, parent: item)
                                    let elementImageType = DataElement(withTag: tagType, parent: item)
                                    
                                    _ = elementImageSOP.setValue(sop)
                                    _ = elementImageType.setValue("IMAGE")
                                    
                                    offset += elementImageSOP.toData().count
                                    offset += elementImageType.toData().count
                                    
                                    item.elements.append(elementImageType)
                                    item.elements.append(elementImageSOP)
                                }
                            }
                        }
                    }
                }
            }
            cpt += 1
        }
        
        return sequence
    }
    
    /**
        Write a new DICOMDIR using a folder
     */
    public func writeDicomDir(atPath folderPath:String) -> Bool {
        hasPreamble = true
        dataset = DataSet()
        
        // Write the Prefix Header
        _ = dataset.set(value: UInt32(0).bigEndian, forTagName: "FileMetaInformationGroupLength")
        _ = dataset.set(value: Data(repeating: 0x00, count: 2), forTagName: "FileMetaInformationVersion") // WRONG DATA
        _ = dataset.set(value: "1.2.840.10008.1.3.10", forTagName: "MediaStorageSOPClassUID")
        _ = dataset.set(value: "2.25.263396925751148424850033748771929175867", forTagName: "MediaStorageSOPInstanceUID")
        _ = dataset.set(value: "1.2.840.10008.1.2.1", forTagName: "TransferSyntaxUID")
        _ = dataset.set(value: "1.2.40.0.13.1.3", forTagName: "ImplementationClassUID")
        _ = dataset.set(value: "dcm4che-5.23.3", forTagName: "ImplementationVersionName")
        
        let headerCount = dataset.toData().count
        _ = dataset.set(value: UInt32(headerCount-12).bigEndian, forTagName: "FileMetaInformationGroupLength") // headerCount - 12 car on ne compte pas les bytes de FileMetaInformationGroupLength

        offset += 132 // 128 bytes preamble + 4 bytes
        offset += headerCount
        
        // Write the DataSet
        _ = dataset.set(value: "", forTagName: "FileSetID")
        let sizeFileSetID = dataset.toData().count - headerCount
        offset += sizeFileSetID
        
        _ = dataset.set(value: UInt32(000).bigEndian, forTagName:  "OffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity") // offsetFirst
        _ = dataset.set(value: UInt32(0000).bigEndian, forTagName: "OffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity") // offsetLast
        _ = dataset.set(value: UInt16(0).bigEndian, forTagName: "FileSetConsistencyFlag")
        
        let sizeAfterOffset = dataset.toData().count - headerCount - sizeFileSetID
        offset += sizeAfterOffset
                
        // Write the DirectoryRecordSequence
        if let c:DataSequence = createDirectoryRecordSequence() {
            c.length = -1
            for item in c.items {
                item.length = -1
            }
            dataset.add(element: c as DataElement)
        }
        
        _ = dataset.set(value: UInt32(offsetFirst).bigEndian, forTagName:  "OffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity") // offsetFirst
        _ = dataset.set(value: UInt32(offsetLast).bigEndian, forTagName: "OffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity") // offsetLast
        
        dataset.hasPreamble = hasPreamble
        
        let dicomDirPAth = folderPath.last == "/" ? folderPath + "DICOMDIR" : folderPath + "/DICOMDIR"
        
        return self.write(atPath: dicomDirPAth)
    }
    
    /**
        Create a DicomDir instance wich contains the interesting data of the given folder
     */
    public static func parse(atPath folderPath:String) -> DicomDir? {
        
        let dcmDir = DicomDir.init()
        dcmDir.filepath = amputation(forPath:folderPath)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: folderPath)
            
            var pathFolder = folderPath
            if(pathFolder.last != "/") {
                pathFolder += "/"
            }
            
            for file in files {
                // add to DicomDir.index the file path
                let absolutePath = pathFolder+file
                
                dcmDir.index.append(absolutePath)
                
                guard let dcmFile = DicomFile(forPath: absolutePath) else {
                    return nil
                }
            
                // fill patient property
                let patientKey = dcmFile.dataset.string(forTag: "PatientID")
                let patientVal = dcmFile.dataset.string(forTag: "PatientName")
                if let key = patientKey {
                    dcmDir.patients[key] = patientVal
                }
                
                // fill study property
                let studyKey = dcmFile.dataset.string(forTag: "StudyInstanceUID")
                let date = dcmFile.dataset.date(forTag: "StudyDate")
                let time = dcmFile.dataset.time(forTag: "StudyTime")
                let description = dcmFile.dataset.time(forTag: "StudyDescription")
                let studyVal = patientKey
                
                if let key = studyKey {
                    if dcmDir.studies[key] == nil {
                        dcmDir.studies[key] = []
                        dcmDir.studies[key]?.insert(studyVal!, at: 0)
                        dcmDir.studies[key]?.insert(date as Any, at: 1)
                        dcmDir.studies[key]?.insert(time as Any, at: 2)
                        dcmDir.studies[key]?.insert(description as Any, at: 3)
                    }
                }
                
                // fill serie property
                let serieKey = dcmFile.dataset.string(forTag: "SeriesInstanceUID")
                let serieVal = studyKey
                if let key = serieKey {
                    dcmDir.series[key] = serieVal
                }
                
                // fill images property
                let imageKey = dcmFile.dataset.string(forTag: "SOPInstanceUID")
                if let serieKeyUnwrapped = serieKey {
                    let imageVal = [serieKeyUnwrapped,absolutePath]
                    if let key = imageKey {
                        dcmDir.images[key] = imageVal
                    }
                }
            }
        } catch {
            print(error)
            return nil
        }
        return dcmDir
    }
}
