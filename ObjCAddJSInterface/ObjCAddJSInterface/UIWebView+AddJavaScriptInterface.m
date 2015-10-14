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

@implementation UIWebView (AddJavaScriptInterface)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        SEL setDel = @selector(setDelegate:);
        SEL swizzlingSetDel = @selector(YQHybridSetDelegate:);
        
        Method existingMtd = class_getInstanceMethod(self, setDel);
        Method newMtd = class_getInstanceMethod(self, swizzlingSetDel);
        
        BOOL add = class_addMethod([self class], setDel, method_getImplementation(newMtd), method_getTypeEncoding(newMtd));
        
        if (add) {
            class_replaceMethod([self class], swizzlingSetDel, method_getImplementation(existingMtd), method_getTypeEncoding(newMtd));
        }else{
            method_exchangeImplementations(existingMtd, newMtd);
        }
    });
}

- (void)YQHybridSetDelegate:(id<UIWebViewDelegate>)del{
    
    NSCAssert([del conformsToProtocol:@protocol(UIWebViewDelegate)], @"must conform UIWebViewDelegate");

    YQWebViewProxyDelegate *proxyDelegate = [self webViewProxyDelegate];
    if (![del isEqual:proxyDelegate]) {
        [proxyDelegate setDelegate:del];
    }
    
    [self YQHybridSetDelegate:del];
}

- (void)addJavascriptInterfaces:(id)interface WithName:(NSString *)name
{
    [[self webViewProxyDelegate] addJavascriptInterfaces:interface WithName:name];
}

- (YQWebViewProxyDelegate*)webViewProxyDelegate
{
    YQWebViewProxyDelegate *retDelegate = nil;
    
    retDelegate = objc_getAssociatedObject(self, @selector(webViewProxyDelegate));
    
    if (!retDelegate) {
        retDelegate = [[YQWebViewProxyDelegate alloc]init];
        objc_setAssociatedObject(self, @selector(webViewProxyDelegate), retDelegate, OBJC_ASSOCIATION_RETAIN);
        self.delegate = retDelegate;
    }
    
    return retDelegate;
}


@end
