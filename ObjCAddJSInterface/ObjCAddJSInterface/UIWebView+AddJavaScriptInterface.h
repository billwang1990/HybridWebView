//
//  UIWebView+AddJavaScriptInterface.h
//  ObjCAddJSInterface
//
//  Created by wangyaqing on 15/4/8.
//  Copyright (c) 2015年 billwang1990.github.io. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YQWebViewProxyDelegate;

@interface UIWebView (AddJavaScriptInterface)

- (void) addJavascriptInterfaces:(NSObject*) interface WithName:(NSString*) name;

/**
 *  USE THIS METHOD REPLATE ORIGINAL setDelegate
 *
 *  @param delegate 
 */
- (void)setCustomDelegate:(NSObject<UIWebViewDelegate>*)delegate;

@end
