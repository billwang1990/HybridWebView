//
//  YQWebViewProxyDelegate.m
//  ObjCAddJSInterface
//
//  Created by wangyaqing on 15/4/8.
//  Copyright (c) 2015年 billwang1990.github.io. All rights reserved.
//

#import "YQWebViewProxyDelegate.h"
#import <objc/runtime.h>

#define kCustomProtocolScheme @"hybrid-js-scheme"

@implementation YQWebViewProxyDelegate
{
    __weak NSObject<UIWebViewDelegate> *_realDelegate;
    __strong NSMutableArray *holdOnParams;
}

- (void)addJavascriptInterfaces:(NSObject *)interface WithName:(NSString *)name
{
    [self.registInterface setObject:interface forKey:name];
}

- (NSMapTable *)registInterface
{
    if (!_registInterface) {
        _registInterface = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
    }
    return _registInterface;
}

- (void)setDelegate:(id<UIWebViewDelegate>)delegate
{
    _realDelegate = delegate;
}

#pragma mark UIWebViewDelegate
//注入实体一定要在webview加载完成后才能调用
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ([_realDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_realDelegate webViewDidFinishLoad:webView];
    }
    [self injectObjectForWebView:webView];
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
    };
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
        
        NSObject* interface = [self.registInterface objectForKey:obj];
        
        SEL selector = NSSelectorFromString(method);
        NSMethodSignature* sig = [[interface class] instanceMethodSignatureForSelector:selector];
        
        NSInvocation* invoker = [NSInvocation invocationWithMethodSignature:sig];
        invoker.selector = selector;
        invoker.target = interface;
        
        //An NSInvocation by default does not retain or copy given arguments for efficiency, so each object passed as argument must still live when the invocation is invoked.
        if (!holdOnParams) {
            holdOnParams = [[NSMutableArray alloc]init];
        }
        
        BOOL callAsync = NO;
        NSString *callBackID = nil;
        if ([components count] > 3){
            
            NSString *argsAsString = [(NSString*)[components objectAtIndex:3]
                                      stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSArray* formattedArgs = [argsAsString componentsSeparatedByString:@"/@@/"];
            for (NSInteger i = 0, j = 0, l = [formattedArgs count]; i < l; i+=2, j++){
                NSString* type = ((NSString*) [formattedArgs objectAtIndex:i]);
                NSString* argStr = ((NSString*) [formattedArgs objectAtIndex:i + 1]);
                
                if ([@"s" isEqualToString:type]){
                    [holdOnParams addObject:argStr];
                    
                    [invoker setArgument:&argStr atIndex:(j + 2)];
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
                else if ([@"a" isEqualToString:type])
                {
                    NSString *arrStr = [argStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    NSData *data = [arrStr dataUsingEncoding:NSUTF8StringEncoding];
                    NSArray *array = [[NSJSONSerialization JSONObjectWithData:data
                                                                      options:0
                                                                        error:nil]copy];
                    [holdOnParams addObject:array];
                    [invoker setArgument:&array atIndex:(j+2)];
                }
                else if ([@"f" isEqualToString:type])
                {
                    callAsync = YES;
                    callBackID = [argStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }
                else if ([@"o" isEqualToString:type])
                {
                    //ONLY for inject ajax
                    NSString* objStr = [argStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    NSData *data = [objStr dataUsingEncoding:NSUTF8StringEncoding];
                    NSMutableArray *arr = [[NSJSONSerialization JSONObjectWithData:data
                                                                           options:0
                                                                             error:nil]mutableCopy];
                    //                    NSDictionary *dic = [arr objectAtIndex:1];
                    //arr[0]: 在js中对应的obj的key, arr[1]:参数, arr[2]:webview
                    [arr addObject:webView];
                    [holdOnParams addObject:arr];
                    [invoker setArgument:&arr atIndex:(j+2)];
                    callAsync = YES;
                }
            }
            printf("\n");
        }
        if (callAsync) {
            
            __weak typeof(self) wSelf = self;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                //                [invoker retainArguments];
                [invoker invoke];
                //return the value by using javascript, only support string, now!!!
                if (callBackID && [sig methodReturnLength] > 0){
                    NSString* retValue = nil;
                    void *resultVal;
                    [invoker getReturnValue:&resultVal];
                    retValue = (__bridge NSString*)resultVal;
                    
                    [wSelf returnResultFrom:webView callBkId:callBackID args:retValue];
                }
            });
        }
        else
        {
            [invoker retainArguments];
            [invoker invoke];
            if ([sig methodReturnLength] > 0){
                NSString* retValue = nil;
                
                void *resultVal;
                [invoker getReturnValue:&resultVal];
                retValue = (__bridge NSString*)resultVal;
                
                if (retValue == NULL || retValue == nil){
                    [webView stringByEvaluatingJavaScriptFromString:@"window.HybridWeb.retValue=null;"];
                }else{
                    retValue = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef) retValue, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));
                    [webView stringByEvaluatingJavaScriptFromString:[@"" stringByAppendingFormat:@"window.HybridWeb.retValue=\"%@\";", retValue]];
                }
            }
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
    if (![[webView stringByEvaluatingJavaScriptFromString:@"typeof HybridWeb == 'object'"] isEqualToString:@"true"]) {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *filePath = [bundle pathForResource:@"YQAddJSInterface" ofType:@"js"];
        NSString *js = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        [webView stringByEvaluatingJavaScriptFromString:js];
    }
    
    __block NSMutableString* injection = [[NSMutableString alloc] init];
    
    [[self.registInterface dictionaryRepresentation] enumerateKeysAndObjectsUsingBlock:^(id objectKey, NSObject *obj, BOOL *stop) {
        
        /*
         HybridWeb.inject("objname", ["mehod1", "method2"]);
         */
        //object name
        [injection appendString:@"HybridWeb.inject(\""];
        [injection appendString:objectKey];
        [injection appendString:@"\", ["];
        
        //get object methods
        NSArray *methods = DumpObjMethods(object_getClass(obj));
        for (NSString *method in methods) {
            [injection appendString:@"\""];
            [injection appendString:method];
            [injection appendString:@"\""];
            
            if ([method isEqual:methods.lastObject]) {
                [injection appendString:@"]);"];
            }else{
                [injection appendString:@", "];
            }
        }
    }];
    
    [webView stringByEvaluatingJavaScriptFromString:injection];
}

- (void)returnResultFrom:(UIWebView*)web callBkId:(NSString*)callbackId args:(NSString*)arg
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [web stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.HybridWeb.invokeCallBack(%@,'%@');",callbackId,arg]];
    });
}

#pragma mark Dump Class
NSArray* DumpObjMethods(Class clz){
    
    Class thisClass = clz;
    NSMutableArray *ret = [[NSMutableArray alloc]init];
    do {
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(clz, &methodCount);
        
        for (unsigned int i = 0; i < methodCount; i++) {
            
            Method method = methods[i];
            [ret addObject:@(sel_getName(method_getName(method)))];
            
            printf("\t'%s' has method named '%s' of encoding '%s'\n",
                   class_getName(clz),
                   sel_getName(method_getName(method)),
                   method_getTypeEncoding(method));
        }
        
        free(methods);
        thisClass = class_getSuperclass(thisClass);
        
    } while (thisClass);
    return ret;
}

@end
