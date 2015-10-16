//
//  UIWebView+AddJavaScriptInterface.h
//  ObjCAddJSInterface
//
//  Created by wangyaqing on 15/4/8.
//  Copyright (c) 2015年 billwang1990.github.io. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWebView (AddJavaScriptInterface)

- (void) addJavascriptInterfaces:(NSObject*) interface WithName:(NSString*) name;

@end
