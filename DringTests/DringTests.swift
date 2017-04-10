//
//  DringTests.swift
//  DringTests
//
//  Created by 刘兴明 on 16/01/2017.
//  Copyright © 2017 刘兴明. All rights reserved.
//

import XCTest
@testable import Dring

class DringTests: XCTestCase {
    var vc: ViewController!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        vc = storyboard.instantiateInitialViewController() as! ViewController
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testProperty() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssert(ViewController.isWiatDry==true)
        XCTAssert(ViewController.temperatureDatas.count==0)
        XCTAssert(ViewController.currentLineNo==0)
        XCTAssert(ViewController.lineStartTime[0]==0)
        
        XCTAssert(vc.dryingRecord.count==0)
        XCTAssert(vc.scales==["默认","20 分钟","30 分钟","1 小时","2 小时","3 小时","4 小时","5 小时","6 小时","7 小时","8 小时"])
        XCTAssert(vc.valuePicker==0)
        XCTAssert(vc.scrollPos==0.0)
        XCTAssert(vc.dryingRecord.count==0)
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
