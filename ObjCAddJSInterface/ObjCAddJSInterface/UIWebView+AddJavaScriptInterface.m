//
//  UIWebView+AddJavaScriptInterface.m
//  ObjCAddJSInterface
//
//  Created by wangyaqing on 15/4/8.
//  Copyright (c) 2015年 billwang1990.github.io. All rights reserved.
//

#import "UIWebView+AddJavaScriptInterface.h"
#import "YQWebViewProxyDelegate.h"
#import <objc/runtime.h>

static void *kYQWebViewProxyDelegateKey = &kYQWebViewProxyDelegateKey;


@implementation UIWebView (AddJavaScriptInterface)

- (void)addJavascriptInterfaces:(NSObject *)interface WithName:(NSString *)name
{
    [[self webViewProxyDelegate] addJavascriptInterfaces:interface WithName:name];
}

- (YQWebViewProxyDelegate*)webViewProxyDelegate
{
    YQWebViewProxyDelegate *retDelegate = nil;
    
    retDelegate = objc_getAssociatedObject(self, kYQWebViewProxyDelegateKey);
    
    if (!retDelegate) {
        retDelegate = [[YQWebViewProxyDelegate alloc]init];
        objc_setAssociatedObject(self, kYQWebViewProxyDelegateKey, retDelegate, OBJC_ASSOCIATION_RETAIN);
    }
    
    return retDelegate;
}

- (void)setCustomDelegate:(NSObject<UIWebViewDelegate> *)delegate
{
    NSCAssert([delegate conformsToProtocol:@protocol(UIWebViewDelegate)], @"must conform UIWebViewDelegate");
    
    YQWebViewProxyDelegate *proxyDelegate = [self webViewProxyDelegate];
    [proxyDelegate setDelegate:delegate];
    
    self.delegate = proxyDelegate;
}


@end
