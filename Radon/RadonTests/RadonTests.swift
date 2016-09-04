//
//  RadonTests.swift
//  RadonTests
//
//  Created by mhaddl on 06/05/16.
//  Copyright © 2016 Martin Hartl. All rights reserved.
//

import XCTest
import CloudKit
@testable import Radon_iOS

class RadonTests: XCTestCase {
    
    var mockInterface: MockCloudKitInterface!
    var radon: Radon<ExampleRadonStore, TestClass>!
    var store: ExampleRadonStore!
    
    override func setUp() {
        store = ExampleRadonStore()
        mockInterface = MockCloudKitInterface()
        radon = Radon<ExampleRadonStore, TestClass>(store: store, interface: mockInterface, recordZoneErrorBlock: nil)
    }
    
    func testDateExtensionEalier() {
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date()
        
        XCTAssert(date1.isEarlierThan(date2))
        XCTAssert(!date2.isEarlierThan(date1))
        XCTAssert(!date1.isEarlierThan(date1))
    }
    
    func testDateExtensionNil() {
        let date1: Date? = nil
        let date2 = Date()
        
        XCTAssert(!date2.isEarlierThan(date1))
    }
    
    func testUserDefaultsExtension() {
        let userDefaults = UserDefaults()
        let key = "key"
        let testString = "1234Test"
        userDefaults.saveObject(testString, forKey: key)
        XCTAssert(testString == userDefaults.loadObjectForKey(key) as? String)
    }
    
    func testFullInit() {
        
        mockInterface.failsSaveRecordZone = true
        _ = Radon<ExampleRadonStore, TestClass>(store: ExampleRadonStore(), interface: mockInterface) { (error) in
            XCTAssert(error != nil)
        }
        
        XCTAssert(true)
    }
    
    func testCreateObjectSuccess() {
        radon.createObject({ (newObject) -> TestClass in
            newObject.string = "MockString"
            newObject.int = 12345
            newObject.double = 2
            return newObject
        }) { (error) in
            if let object = self.store.objectWithIdentifier("Mock") {
                XCTAssert(object.string == "MockString")
            } else {
                XCTFail()
            }
        }
    }
    
    func testCreateObjectFail() {
        mockInterface.failsCreateRecord = true
        
        radon.createObject({ (newObject) -> TestClass in
            newObject.string = "MockString"
            newObject.int = 12345
            newObject.double = 2
            return newObject
        }) { (error) in
            if let _ = self.store.objectWithIdentifier("Mock") {
                XCTFail()
            } else {
                XCTAssert(error != nil)
            }
        }
    }
    
    func testUpdateObjectSuccess() {
        let expectation = self.expectation(description: "Update Object")
        
        mockInterface.failsCreateRecord = true
        let testObject = TestClass(string: "", int: 0, double: 0)
        store.addObject(testObject)
        store.setRecordName("Mock", forObject: testObject)
        XCTAssert(testObject.internSyncStatus == false)
        radon.updateObject({ testClass in
            testObject.string = "Update"
            return testObject
        }) { (error) in
            XCTAssert(error == nil)
            XCTAssert(testObject.internSyncStatus == true)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
    }
    
    func testUpdateObjectError() {
        let expectation = self.expectation(description: "Update Object")
        
        mockInterface.failsCreateRecord = true
        let testObject = TestClass(string: "", int: 0, double: 0)
        store.addObject(testObject)
        XCTAssert(testObject.internSyncStatus == false)
        //Fail because object could not be found in the store by its record name
        radon.updateObject({ testClass in
            testObject.string = "Update"
            return testObject
        }) { (error) in
            XCTAssert(error != nil)
            XCTAssert(testObject.internSyncStatus == false)
            expectation.fulfill()
        }
        
        store.setRecordName("Mock", forObject: testObject)
        mockInterface.failsModifyRecord = true
        //Fail because modify failed
        let expectation2 = self.expectation(description: "Update Object fail 2")
        radon.updateObject({ testClass in
            testObject.string = "Update"
            return testObject
        }) { (error) in
            XCTAssert(error != nil)
            XCTAssert(testObject.internSyncStatus == false)
            expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        let expectation3 = self.expectation(description: "Update Object fail 3")
        mockInterface.failsFetchRecord = true
        //Fail because fetch failed
        radon.updateObject({ testClass in
            testObject.string = "Update"
            return testObject
        }) { (error) in
            XCTAssert(error != nil)
            XCTAssert(testObject.internSyncStatus == false)
            expectation3.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUpdateObjectForNotYetSyncedObject() {
        let expectation = self.expectation(description: "Update Object")
        
        mockInterface.failsCreateRecord = true
        let testObject = TestClass(string: "", int: 0, double: 0)
        store.addObject(testObject)
        store.setRecordName(nil, forObject: testObject)
        XCTAssert(testObject.internSyncStatus == false)
        radon.updateObject({ testClass in
            testObject.string = "Update"
            return testObject
        }) { (error) in
            XCTAssert(error != nil)
            XCTAssert(testObject.internSyncStatus == false)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    func testDeleteRecordSuccess() {
        let expectation = self.expectation(description: "Delete Object")
        let testObject = TestClass(string: "hi", int: 1, double: 1)
        testObject.internRecordID = "123"
        store.addObject(testObject)
        XCTAssert(store.objectWithIdentifier(testObject.internRecordID) != nil)
        radon.deleteObject(testObject) { (error) in
            XCTAssert(error == nil)
            XCTAssert(self.store.objectWithIdentifier(testObject.internRecordID) == nil)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testHandleQueryNotificationReasonUpdated() {
        let testObject = TestClass(string: "hi", int: 1, double: 1)
        testObject.internRecordID = "123"
        store.addObject(testObject)
        XCTAssert(store.objectWithIdentifier(testObject.internRecordID) != nil)
        let recordID = CKRecordID(recordName: "123")
        radon.handleQueryNotificationReason(.recordUpdated, forRecordID: recordID)
        XCTAssert(testObject.string == "Mock")
    }
    
    func testHandleQueryNotificationReasonUpdatedRecordNotFound() {
        let testObject = TestClass(string: "hi", int: 1, double: 1)
        testObject.internRecordID = "123"
        store.addObject(testObject)
        XCTAssert(store.objectWithIdentifier(testObject.internRecordID) != nil)
        let recordID = CKRecordID(recordName: "123")
        mockInterface.failsFetchRecord = true
        radon.handleQueryNotificationReason(.recordUpdated, forRecordID: recordID)
        XCTAssert(testObject.string == "hi")
    }
    
    func testHandleQueryNotificationReasonDelete() {
        let testObject = TestClass(string: "hi", int: 1, double: 1)
        testObject.internRecordID = "123"
        store.addObject(testObject)
        XCTAssert(store.objectWithIdentifier(testObject.internRecordID) != nil)
        let recordID = CKRecordID(recordName: "123")
        radon.handleQueryNotificationReason(.recordDeleted, forRecordID: recordID)
        XCTAssert(store.objectWithIdentifier(testObject.internRecordID) == nil)
    }
    
    func testHandleQueryNotificationReasonRecordCreated() {
        XCTAssert(store.objectWithIdentifier("Mock") == nil)
        let recordID = CKRecordID(recordName: "Mock")
        radon.handleQueryNotificationReason(.recordCreated, forRecordID: recordID)
        XCTAssert(store.objectWithIdentifier("Mock") != nil)
    }
    
    func testHandleQueryNotificationReasonRecordCreatedRecordNotFound() {
        XCTAssert(store.objectWithIdentifier("Mock") == nil)
        mockInterface.failsFetchRecord = true
        let recordID = CKRecordID(recordName: "Mock")
        radon.handleQueryNotificationReason(.recordCreated, forRecordID: recordID)
        XCTAssert(store.objectWithIdentifier("Mock") == nil)
    }
    
    func testSyncWithNewObjectToFetch() {
        let expectation = self.expectation(description: "New object from sync")
        XCTAssert(store.objectWithIdentifier("Mock") == nil)
        mockInterface.syncRecordChangeHasNewObject = true
        radon.sync({ (error) in
            
        }) { (error) in
            XCTAssert(self.store.objectWithIdentifier("Mock") != nil)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSyncWithNewerObjectAlreadyInStore() {
        let testObject = TestClass(string: "hi", int: 1, double: 1)
        testObject.internRecordID = "Mock"
        store.addObject(testObject)
        mockInterface.syncOlderObject = true
        let expectation = self.expectation(description: "New object from sync")
        XCTAssert(store.objectWithIdentifier("Mock") != nil)
        mockInterface.syncRecordChangeHasNewObject = true
        radon.sync({ (error) in
            
        }) { (error) in
            XCTAssert(self.store.objectWithIdentifier("Mock") != nil)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSyncWithOlderObjectAlreadyInStore() {
        let testObject = TestClass(string: "hi", int: 1, double: 1)
        testObject.internRecordID = "Mock"
        store.addObject(testObject)
        mockInterface.syncOlderObject = false
        let expectation = self.expectation(description: "New object from sync")
        XCTAssert(store.objectWithIdentifier("Mock") != nil)
        mockInterface.syncRecordChangeHasNewObject = true
        radon.sync({ (error) in
            
        }) { (error) in
            let object = self.store.objectWithIdentifier("Mock")
            XCTAssert(object?.string == "ServerUpdated");
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSyncRecordDeleted() {
        let testObject = TestClass(string: "hi", int: 1, double: 1)
        testObject.internRecordID = "Mock"
        let recordID = CKRecordID(recordName: "Mock")
        mockInterface.recordIDtoDeleteInSync = recordID
        store.addObject(testObject)
        let expectation = self.expectation(description: "Delete object from sync")
        XCTAssert(store.objectWithIdentifier("Mock") != nil)
        radon.sync({ (error) in
            
        }) { (error) in
            XCTAssert(self.store.objectWithIdentifier("Mock") == nil)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
//    func testServerChangeToken() {
//        let mockInterface = MockCloudKitInterface()
//        mockInterface.failsCreateRecord = true
//        let store = ExampleRadonStore()
//        let radon = Radon<ExampleRadonStore, TestClass>(store: store, interface: mockInterface) { (error) in
//            
//        }
//        radon.defaultsStoreable = MockDefaultsStoreable()
//        let changeData = "123456".dataUsingEncoding(NSUTF8StringEncoding)
//        radon.syncToken = CKServerChangeToken()
//    }
    
}
