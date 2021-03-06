//
//  MockCloudKitInterface.swift
//  Radon
//
//  Created by mhaddl on 06/05/16.
//  Copyright © 2016 Martin Hartl. All rights reserved.
//

import Foundation
@testable import Radon_iOS

struct MockError: Error {
    
}

class MockRecord: Record {
    var recordName: String
    var modificationDate: Date?
    
    var string:String
    var int: Int
    var double: Double
    
    func valuesDictionaryForKeys(_ keys: [String], syncableType: Syncable.Type) -> [String : Any] {
        return [
            "string":string,
            "int":int,
            "double":double
        ]
    }
    
    func updateWithDictionary(_ dictionary: [String : Any]) {
        guard let string = dictionary["string"] as? String,
            let int = dictionary["int"] as? Int,
            let double = dictionary["double"] as? Double else {
                assert(true)
             return
        }
        self.string = string
        self.int = int
        self.double = double
    }
    
    init(recordName: String, modificationDate: Date, string: String, int: Int, double: Double) {
        self.recordName = recordName
        self.modificationDate = modificationDate
        self.string = string
        self.int = int
        self.double = double
    }
}

struct MockServerChangeToken: ServerChangeToken { }

class MockCloudKitInterface: CloudInterface {
    
    typealias RecordType = MockRecord
    typealias ChangeToken = MockServerChangeToken
    
    var failsSaveRecordZone = false
    var failsCreateRecord = false
    var failsFetchRecord = false
    var failsModifyRecord = false
    var failsDeleteRecord = false
    var syncRecordChangeHasNewObject = false
    var syncOlderObject = false
    var syncNeedsFreshSync = false
    var recordNametoDeleteInSync: String? = nil
    var fetchSameUserRecord = false
    
    func setup(completion: (Error?) -> Void) {
        if failsSaveRecordZone {
            completion(MockError())
        } else {
            completion(nil)
        }
    }
    
    func createRecord(withDictionary dictionary: [String : Any], onQueue queue: DispatchQueue, createRecordCompletionBlock: (@escaping (String?, Error?) -> Void)) {
        if failsCreateRecord {
            createRecordCompletionBlock(nil, MockError())
        } else {
            createRecordCompletionBlock("Mock", nil)
            
        }
    }
    
    func fetchRecord(_ recordName: String, onQueue queue: DispatchQueue, fetchRecordsCompletionBlock: @escaping ((MockRecord?, Error?) -> Void)) {
        
        let mockStore = ExampleRadonStore()
        let object = TestClass(string: "Mock", int: 1, double: 2)
        
        if failsFetchRecord {
            fetchRecordsCompletionBlock(nil, MockError())
        } else {
            let record = MockRecord(recordName: "Mock", modificationDate: Date(),  string: "Mock", int: 123, double: 123)
            record.updateWithDictionary(mockStore.allPropertiesForObject(object))
            fetchRecordsCompletionBlock(record, nil)
        }
    }
    
    func modifyRecord(_ record: MockRecord, onQueue queue: DispatchQueue, modifyRecordsCompletionBlock: (@escaping ([MockRecord]?, [String]?, Error?) -> Void)) {
        if failsModifyRecord {
            modifyRecordsCompletionBlock(nil, nil, MockError())
        } else {
            modifyRecordsCompletionBlock([record],nil,nil)
        }
    }
    
    func deleteRecordWithName(_ recordName: String, onQueue queue: DispatchQueue, modifyRecordsCompletionBlock: @escaping ((Error?) -> Void)) {
        if failsDeleteRecord {
            modifyRecordsCompletionBlock(MockError())
        } else {
            modifyRecordsCompletionBlock(nil)
        }
    }
    
    
    func fetchRecordChanges(onQueue queue: DispatchQueue, previousServerChangeToken: ServerChangeToken?, recordChangeBlock: @escaping ((Record) -> Void), recordWithNameWasDeletedBlock: @escaping ((String) -> Void), fetchRecordChangesCompletionBlock: @escaping ((ServerChangeToken?, Bool, Error?, Bool) -> Void)) {
        
        if syncRecordChangeHasNewObject {
            
            let date: Date
            if syncOlderObject {
                date = Date(timeIntervalSince1970: 0)
            } else {
                date = Date()
            }
            
            let record = MockRecord(recordName: "Mock", modificationDate: date, string: "ServerUpdated", int: 4, double: 5)
            recordChangeBlock(record)
        }
        
        if let recordNametoDeleteInSync = recordNametoDeleteInSync {
            recordWithNameWasDeletedBlock(recordNametoDeleteInSync)
        }
        
        fetchRecordChangesCompletionBlock(nil, false, nil, syncNeedsFreshSync)
    }
    
    func fetchUserRecordNameWithCompletionHandler(_ completionHandler: @escaping (String?, Error?) -> Void) {
        if fetchSameUserRecord {
            completionHandler("Mock", nil)
        } else {
            completionHandler(String(arc4random()), nil)
        }
    }
    
    func queryNotificationReason(for userInfo: [AnyHashable : Any]) -> QueryNotificationReason {
        //TODO: add tests
        return .recordCreated(recordName: "Mock")
    }
    
}
