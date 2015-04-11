//
//  YQWebViewProxyDelegate.h
//  ObjCAddJSInterface
//
//  Created by wangyaqing on 15/4/8.
//  Copyright (c) 2015年 billwang1990.github.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YQWebViewProxyDelegate : NSObject<UIWebViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *registInterFaces;

- (void) addJavascriptInterfaces:(NSObject*) interface WithName:(NSString*) name;
- (void)setDelegate:(id<UIWebViewDelegate>)delegate;

@end
