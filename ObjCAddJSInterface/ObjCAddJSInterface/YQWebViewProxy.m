//
//  YQWebViewProxyDelegate.m
//  ObjCAddJSInterface
//
//  Created by wangyaqing on 15/4/8.
//  Copyright (c) 2015年 billwang1990.github.io. All rights reserved.
//

#import "YQWebViewProxy.h"
#import <objc/runtime.h>

#define kCustomProtocolScheme @"hybrid-js-scheme"

#pragma mark NSDictionary & NSArray Category -JSONString
@interface NSDictionary(JSONString)
- (NSString*)JSONString;
@end

@implementation NSDictionary (JSONString)
- (NSString *)JSONString
{
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    
    if (!jsonData) {
        NSLog(@"jsonStringWithPrettyPrint: error: %@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}
@end


@interface NSArray(JSONString)
- (NSString*)JSONString;
@end

@implementation NSArray (JSONString)
- (NSString *)JSONString
{
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    
    if (!jsonData) {
        NSLog(@"jsonStringWithPrettyPrint: error: %@", error.localizedDescription);
        return @"[]";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}
@end


#pragma mark YQWebViewProxyDelegate
@implementation YQWebViewProxy
{
    __weak NSObject<UIWebViewDelegate> *_realDelegate;
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

#pragma mark UIWebView Delegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ([_realDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_realDelegate webViewDidFinishLoad:webView];
    }
    [self injectObjectForWebView:webView];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"call %s", __FUNCTION__);

    if ([_realDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [_realDelegate webView:webView didFailLoadWithError:error];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"call %s", __FUNCTION__);

    if ([_realDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_realDelegate webViewDidStartLoad:webView];
    };
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"call %s", __FUNCTION__);
    
    [self injectObjectForWebView:webView];

    NSURL *url = [request URL];
    
    if ([[url scheme] isEqualToString:kCustomProtocolScheme]) {
        
        NSString *obj = url.host;
        NSString *method = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
        NSArray  *params = [self objectWithQueryString:url.query];
        
        if (url.query.length > 0) {
            method = [method stringByAppendingString:@"_"];
            method = [method stringByReplacingOccurrencesOfString:@"_" withString:@":"];
        }
        
        NSObject* interface = [self.registInterface objectForKey:obj];
        
        SEL selector = NSSelectorFromString(method);
        NSMethodSignature* sig = [[interface class] instanceMethodSignatureForSelector:selector];
        if (!sig) {
            selector = NSSelectorFromString([method substringToIndex:method.length -1]);
            sig = [[interface class]instanceMethodSignatureForSelector:selector];
            if (!sig) {
                return NO;
            }
        }
        NSInvocation* invoker = [NSInvocation invocationWithMethodSignature:sig];
        invoker.selector = selector;
        invoker.target = interface;

        NSString *callBackID = nil;
        
        if (params.count > 0){
            
            for (NSInteger i = 0; i < params.count; i++) {
                id arg = params[i];
                NSUInteger allCount = [sig numberOfArguments];
                NSUInteger parameterCount = allCount - 2;
                
                if (i < parameterCount) {
                    [invoker setArgument:&arg atIndex:i+2];
                }else{
                    if ([arg isKindOfClass:[NSString class]]) {
                        callBackID = [arg stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    }
                }
            }
            [invoker retainArguments];
        }
    
        if (callBackID) {
            //exist callback function
            __weak typeof(self) wSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [wSelf invoke:invoker methodSignature:sig onWebView:webView callBackID:callBackID];
            });
        }
        else
        {
            [self invoke:invoker methodSignature:sig onWebView:webView callBackID:nil];
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
        
        __block NSMutableString* injection = [[NSMutableString alloc] init];
        
        [[self.registInterface dictionaryRepresentation] enumerateKeysAndObjectsUsingBlock:^(id objectKey, NSObject *obj, BOOL *stop) {
            
            //   HybridWeb.inject("objname", ["mehod1", "method2"]);
            [injection appendString:@"HybridWeb.inject(\""];
            [injection appendString:objectKey];
            [injection appendString:@"\", ["];
            
            NSArray *methods = DumpObjMethods(object_getClass(obj));

            [methods enumerateObjectsUsingBlock:^(NSString *method, NSUInteger idx, BOOL * _Nonnull stop) {
                [injection appendString:@"\""];
                [injection appendString:method];
                [injection appendString:@"\""];
                
                if (idx == methods.count - 1) {
                    [injection appendString:@"]);"];
                }else{
                    [injection appendString:@", "];
                }
                
            }];
            
            [webView stringByEvaluatingJavaScriptFromString:injection];
        }];
    }
}

#pragma mark Dump Class
NSArray* DumpObjMethods(Class clz){
    
    Class thisClass = clz;
    NSMutableArray *ret = [[NSMutableArray alloc]init];
    
    do {
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(thisClass, &methodCount);
        
        for (unsigned int i = 0; i < methodCount; i++) {
            
            Method method = methods[i];
            
            NSString *name = @(sel_getName(method_getName(method)));
        
            const char *encoding = method_getTypeEncoding(method);
            NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:encoding];
            NSUInteger allCount = [signature numberOfArguments]; // The parameter count including the self and the _cmd ones
            NSUInteger parameterCount = allCount - 2;

            if (parameterCount < 2) {
                name = [name stringByReplacingOccurrencesOfString:@":" withString:@""];
            }else{
                name = [name substringToIndex:name.length-1];
                name = [name stringByReplacingOccurrencesOfString:@":" withString:@"_"];
            }
            [ret addObject:name];
            
//            printf("\t'%s' has method named '%s' of encoding '%s'\n",
//                   class_getName(clz),
//                   sel_getName(method_getName(method)),
//                   method_getTypeEncoding(method));
        }
        
        free(methods);
        thisClass = class_getSuperclass(thisClass);
        
    } while (thisClass);
    return ret;
}

#pragma mark Parse params from url query
- (id)objectWithQueryString:(NSString *)queryString
{
    if (queryString == nil) {
        return nil;
    }
    
    NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
    
    NSArray *components = [queryString componentsSeparatedByString:@"&"];
    
    [components enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSArray *param = [obj componentsSeparatedByString:@"="];
            if ([param count] == 2) {
                NSString *key = param[0];
                NSString *encodedValue = param[1];
                
                NSString *decodedValue = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)encodedValue, CFSTR(""), kCFStringEncodingUTF8);
                resultDictionary[key] = decodedValue;
            }
        }
    }];
    
    NSError *error = nil;
    id param = [NSJSONSerialization JSONObjectWithData:[resultDictionary[@"params"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];

    return [param copy]?:nil;
}

#pragma mark send result back to js
- (void)sendResultFrom:(UIWebView*)web value:(NSString*)val asJSString:(BOOL)asStr callBack:(NSString*)callback{
    
    NSString *jsVal = asStr ? [NSString stringWithFormat:@"\"%@\"",val] : [NSString stringWithFormat:@"%@",val];
    if (!val) {
        jsVal = @"undefined";
    }
    
    if (callback) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [web stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.HybridWeb.invokeCallBack(%@,%@);",callback, jsVal]];
        });
    }else{
        jsVal = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)jsVal, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));
        [web stringByEvaluatingJavaScriptFromString:[@"" stringByAppendingFormat:@"window.HybridWeb.retValue=\"%@\";", jsVal]];
    }
}

- (void)invoke:(NSInvocation*)invocation methodSignature:(NSMethodSignature*)sig onWebView:(UIWebView*)webView callBackID:(NSString*)callBack
{
    [invocation invoke];
    
    const char *returnType = [sig methodReturnType];
    
    if (!strcmp(returnType, @encode(void))) {
        //return void
    }else{
        
        NSUInteger bufferLen = [sig methodReturnLength];
        void *buffer = (void*)malloc(bufferLen);
        if (buffer == NULL) {
            printf("malloc failed!");
            return;
        }

        if(!strcmp(returnType, @encode(id))) {
            [invocation getReturnValue:&buffer];
        } else {
            [invocation getReturnValue:buffer];
        }

        NSString *ret = nil;
        
        __weak typeof(self) wSelf = self;
        
        void (^sendResult)(NSString*, BOOL) = ^(NSString *strValue, BOOL asJSString){
            __strong typeof(wSelf) sSelf = wSelf;
            [sSelf sendResultFrom:webView value:strValue asJSString:asJSString callBack:callBack];
        };
        
        if(!strcmp(returnType, @encode(id))){
            id obj = (__bridge id)buffer;
            if ([obj isKindOfClass:[NSString class]]) {
                ret = (NSString*)obj;
                sendResult(ret,YES);
            }else if([obj isKindOfClass:[NSArray class]]){
                ret = [(NSArray*)obj JSONString]?:@"";
                sendResult(ret,NO);
            }else if ([obj isKindOfClass:[NSDictionary class]]){
                ret = [(NSDictionary*)obj JSONString]?:@"";
                sendResult(ret,NO);
            }else{
                if ([obj respondsToSelector:@selector(description)]) {
                    ret = [obj description];
                }else{
                    ret = nil;
                }
                sendResult(ret, YES);
            }
        }else if (!strcmp(returnType, @encode(float))){
            ;
        }
    }
}

@end

