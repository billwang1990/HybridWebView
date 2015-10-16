//
//  ObjCAddJSInterfaceTests.m
//  ObjCAddJSInterfaceTests
//
//  Created by wangyaqing on 15/4/8.
//  Copyright (c) 2015年 billwang1990.github.io. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "UIWebView+AddJavaScriptInterface.h"

@interface ObjCAddJSInterfaceTests : XCTestCase

@property (nonatomic, strong) UIWebView *web;

@end

@implementation ObjCAddJSInterfaceTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.web = [[UIWebView alloc]init];
    
    __weak typeof(self) wSelf = self;
    [self.web addJavascriptInterfaces:wSelf WithName:@"this"];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}


@end
