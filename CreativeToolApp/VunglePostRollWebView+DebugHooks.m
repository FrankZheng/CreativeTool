//
//  VunglePostRollWebView+DebugHooks.m
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/4/2.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import "VunglePostRollWebView+DebugHooks.h"
@import WebKit;
@import ObjectiveC.runtime;



@implementation NSObject(VunglePostRollWebViewDebugHooks)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class clazz = objc_getClass("VunglePostRollWebView");
        Method loadMethod = class_getInstanceMethod(clazz, @selector(load));
        Method newLoadMethod = class_getInstanceMethod(self, @selector(new_load));
        method_exchangeImplementations(loadMethod, newLoadMethod);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        Method jsMsgHandlerMethod = class_getInstanceMethod(clazz, @selector(javascriptMessageHandler:));
#pragma clang diagnostic pop
        Method newJsMsgHandlerMethod = class_getInstanceMethod(self, @selector(new_javascriptMessageHandler:));
        method_exchangeImplementations(jsMsgHandlerMethod, newJsMsgHandlerMethod);
    });
    
}

- (void)new_load {
    id obj = [self valueForKey:@"webView"];
    if([obj isKindOfClass:[WKWebView class]]) {
        WKWebView *webView = (WKWebView *)obj;
        //inject extra js script for debugging
        NSString *scriptFilePath = [[NSBundle mainBundle] pathForResource:@"inject" ofType:@"js"];
        NSError *error = nil;
        NSString *script = [NSString stringWithContentsOfFile:scriptFilePath encoding:NSUTF8StringEncoding error:&error];
        WKUserScript *userScript = [[ WKUserScript alloc] initWithSource:script
                                                           injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                        forMainFrameOnly:YES];
        [webView.configuration.userContentController addUserScript:userScript];
        
        [webView.configuration.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    }
    //call original `load` implementation
    [self new_load];
}

- (BOOL)new_javascriptMessageHandler:(NSString *)message {
    NSArray *prefixes = @[@"log:", @"error:"];
    for(NSString *prefix in prefixes) {
        if([message hasPrefix:prefix]) {
            NSString *content = [message substringFromIndex:prefix.length];
            NSLog(@"%@", content);
            return YES;
        }
    }
    
    return [self new_javascriptMessageHandler:message];
}





@end
