//
//  YQWebViewProxyDelegate.m
//  ObjCAddJSInterface
//
//  Created by wangyaqing on 15/4/8.
//  Copyright (c) 2015年 billwang1990.github.io. All rights reserved.
//

#import "YQWebViewProxyDelegate.h"
#import <objc/runtime.h>

#define kCustomProtocolScheme @"ika-js-scheme"


@implementation YQWebViewProxyDelegate
{
    __weak NSObject<UIWebViewDelegate> *_realDelegate;
}

- (void)addJavascriptInterfaces:(NSObject *)interface WithName:(NSString *)name
{
    [self.registInterFaces setObject:interface forKey:name];
}

- (NSMutableDictionary *)registInterFaces
{
    if (!_registInterFaces) {
        _registInterFaces = [[NSMutableDictionary alloc]init];
    }
    return _registInterFaces;
}

- (void)setDelegate:(id<UIWebViewDelegate>)delegate
{
    _realDelegate = delegate;
}

#pragma mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ([_realDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_realDelegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([_realDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [_realDelegate webView:webView didFailLoadWithError:error];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if ([_realDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_realDelegate webViewDidStartLoad:webView];
    }
    [self injectObjectForWebView:webView];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [self injectObjectForWebView:webView];
    
    NSURL *url = [request URL];
    
    if ([[url scheme] hasPrefix:kCustomProtocolScheme]) {
        
        NSArray *components = [[url absoluteString] componentsSeparatedByString:@":"];
        
        NSString* obj = (NSString*)[components objectAtIndex:1];
        
        NSString* method = [(NSString*)[components objectAtIndex:2]
                            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSObject* interface = [self.registInterFaces objectForKey:obj];
        
        SEL selector = NSSelectorFromString(method);
        NSMethodSignature* sig = [[interface class] instanceMethodSignatureForSelector:selector];
        
        NSInvocation* invoker = [NSInvocation invocationWithMethodSignature:sig];
        invoker.selector = selector;
        invoker.target = interface;
        
        //An NSInvocation by default does not retain or copy given arguments for efficiency, so each object passed as argument must still live when the invocation is invoked.
        NSMutableArray *holdOnParam = [[NSMutableArray alloc]init];
        
        BOOL callAsync = NO;
        NSString *callBackID = nil;
        
        if ([components count] > 3){
            
            NSString *argsAsString = [(NSString*)[components objectAtIndex:3]
                                      stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSArray* formattedArgs = [argsAsString componentsSeparatedByString:@":"];
            
            for (NSInteger i = 0, j = 0, l = [formattedArgs count]; i < l; i+=2, j++){
                
                NSString* type = ((NSString*) [formattedArgs objectAtIndex:i]);
                NSString* argStr = ((NSString*) [formattedArgs objectAtIndex:i + 1]);
                
                if ([@"s" isEqualToString:type]){
                    NSString* arg = [argStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    [holdOnParam addObject:arg];
                    [invoker setArgument:&arg atIndex:(j + 2)];
                }
                else if([@"d" isEqualToString:type])
                {
                    NSString* numStr = [argStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    CGFloat arg = [numStr floatValue];
                    [invoker setArgument:&arg atIndex:(j+2)];
                }
                else if ([@"b" isEqualToString:type])
                {
                    NSString* boolStr = [argStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    BOOL arg = [boolStr boolValue];
                    [invoker setArgument:&arg atIndex:(j+2)];
                }
                else if ([@"o" isEqualToString:type])
                {
                    NSString* objStr = [argStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    NSData *data = [objStr dataUsingEncoding:NSUTF8StringEncoding];
                    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data
                                                                        options:0
                                                                          error:nil];
                    [holdOnParam addObject:dic];
                    [invoker setArgument:&dic atIndex:(j+2)];
                }
                else if ([@"a" isEqualToString:type])
                {
                    NSString *arrStr = [argStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    NSData *data = [arrStr dataUsingEncoding:NSUTF8StringEncoding];
                    NSArray *array = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:0
                                                                       error:nil];
                    [holdOnParam addObject:array];
                    [invoker setArgument:&array atIndex:(j+2)];
                }
                else if ([@"f" isEqualToString:type])
                {
                    callAsync = YES;
                    callBackID = [argStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }
            }
        }
        
        if (callAsync) {
            __weak typeof(self) wSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                [invoker invoke];
                //return the value by using javascript, only support string, now!!!
                if ([sig methodReturnLength] > 0){
                    NSString* retValue;
                    [invoker getReturnValue:&retValue];
                    [wSelf returnResultFrom:webView callBkId:callBackID args:retValue];
                }
                [holdOnParam removeAllObjects];
            });
        }
        else
        {
            [invoker invoke];
            if ([sig methodReturnLength] > 0){
                NSString* retValue;
                [invoker getReturnValue:&retValue];
                
                if (retValue == NULL || retValue == nil){
                    [webView stringByEvaluatingJavaScriptFromString:@"IKAJS.retValue=null;"];
                }else{
                    retValue = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef) retValue, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));
                    [webView stringByEvaluatingJavaScriptFromString:[@"" stringByAppendingFormat:@"IKAJS.retValue=\"%@\";", retValue]];
                }
            }
            [holdOnParam removeAllObjects];

        }
        return NO;
    }
    
    if (!_realDelegate || ![_realDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]){
        return YES;
    }
    
    return [_realDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
}

- (void)injectObjectForWebView:(UIWebView*)webView
{
    if (![[webView stringByEvaluatingJavaScriptFromString:@"typeof IKAJS == 'object'"] isEqualToString:@"true"]) {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *filePath = [bundle pathForResource:@"YQAddJSInterface" ofType:@"js"];
        NSString *js = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        [webView stringByEvaluatingJavaScriptFromString:js];
    }
    
    __block NSMutableString* injection = [[NSMutableString alloc] init];
    
    [self.registInterFaces enumerateKeysAndObjectsUsingBlock:^(id objectKey, NSObject *obj, BOOL *stop) {
        
        /*
         IKAJS.inject("objname", ["mehod1", "method2"]);
         */
        //object name
        [injection appendString:@"IKAJS.inject(\""];
        [injection appendString:objectKey];
        [injection appendString:@"\", ["];
        
        //object methods
        unsigned int count = 0;
        Class thisCls = object_getClass(obj);
        
        Method *mtdList = class_copyMethodList(thisCls, &count);
        
        for (int i = 0; i < count; i++) {
            
            [injection appendString:@"\""];
            [injection appendString:[NSString stringWithUTF8String:sel_getName(method_getName(mtdList[i]))]];
            [injection appendString:@"\""];
            
            if (i != count - 1){
                [injection appendString:@", "];
            }
        }
        
        [injection appendString:@"]);"];
        
        free(mtdList);
    }];
    
    [webView stringByEvaluatingJavaScriptFromString:injection];
}

- (void)returnResultFrom:(UIWebView*)web callBkId:(NSString*)callbackId args:(NSString*)arg;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [web stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"IKAJS.invokeCallBack(%@,%@)",callbackId,arg]];
    });
}

@end
