//
//  SDKManager.m
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import "SDKManager.h"
//#import <VungleSDK/VungleSDK.h>
@import VungleSDKDynamic;
#import "AppConfig.h"


@interface VungleSDK ()
- (void)setPluginName:(NSString *)pluginName version:(NSString *)version;
- (void)setHTTPHeaderPair:(NSDictionary *)header;
- (void)clearAdUnitCreativesForPlacement:(NSString *)placementRefID completionBlock:(nullable void (^)(NSError *))completionBlock;
- (NSArray *)getValidPlacementInfo;
@end


@interface SDKManager() <VungleSDKDelegate, VungleSDKLogger>
@property(nonatomic, strong) VungleSDK *sdk;
@property(nonatomic, copy) NSString *placementId;
@property(nonatomic, copy) NSString *appId;
@property(nonatomic, strong) NSMutableArray<NSString *> *queue;

@end


@implementation SDKManager

+ (instancetype)sharedInstance {
    static SDKManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SDKManager alloc] init];
    });
    return instance;
    
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //_sdk = [VungleSDK sharedSDK];
        _placementId = [AppConfig placementId];
        _appId = [AppConfig appId];
        _queue = [NSMutableArray array];
    }
    return self;
}

- (void)start {
    //initialize SDK
    if (!_sdk || !_sdk.isInitialized) {
        //if sdk not initialized, try to initialize
        //should set endpoint before sdk instantiation
        //It's tricky, but needed for 5.3.2 version
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *url = self.serverURL.absoluteString;
        if([url characterAtIndex:url.length-1] == '/') {
            url = [url substringWithRange:NSMakeRange(0,url.length-1)];
        }
        [defaults setObject:url forKey:@"vungle.api_endpoint"];
        
        _sdk = [VungleSDK sharedSDK];
        [_sdk setLoggingEnabled:YES];
        [_sdk attachLogger:self];
        _sdk.delegate = self;
        
        [defaults setBool:YES forKey:@"vungle.network_logging"];

        [defaults synchronize];
        
        NSError *error = nil;
        NSArray *placements = @[_placementId];
        if (![_sdk startWithAppId:_appId placements:placements error:&error]) {
            NSLog(@"Failed to initialize sdk, %@", error);
        }
    }
}


- (void)loadAd {
    if (!_sdk.isInitialized) {
        //add placementId to queue
        [_queue addObject:_placementId];
        
    } else {
        //if sdk already initialized, just load ad directly
        [self loadPlacement:_placementId];
    }
}

- (void)playAd:(UIViewController*)viewController {
    NSError *error = nil;
    if(![_sdk playAd:viewController options:nil placementID:_placementId error:&error]) {
        NSLog(@"Failed to play ad, %@", error);
    }
}

- (void)loadPlacement:(NSString *)pID {
    
    __weak typeof(self) weakSelf = self;
    [self clearCache:pID completionBlock:^(NSError *error) {
        if(error != nil) {
            NSLog(@"Failed to clear cache, %@", error);
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *err = nil;
            if(![weakSelf.sdk loadPlacementWithID:pID error:&err]) {
                NSLog(@"Failed to load ad, %@", error);
            }
        });
    }];
    
#if 0
    NSError *error = nil;
    if(![_sdk loadPlacementWithID:pID error:&error]) {
        NSLog(@"Failed to load ad, %@", error);
    }
#endif
}

- (void)clearCache:(NSString *)pID completionBlock:(nullable void (^)(NSError *))completionBlock;{
    if([_sdk isAdCachedForPlacementID:pID]) {
        //if has cache, remove the cache
        [_sdk clearAdUnitCreativesForPlacement:pID completionBlock:^(NSError *error) {
            if (completionBlock != nil) {
                completionBlock(error);
            }
        }];
    } else {
        if (completionBlock != nil) {
            completionBlock(nil);
        }
    }
}


- (void)clearCache {
    [self clearCache:_placementId completionBlock:nil];
}

- (void)vungleSDKLog:(NSString *)message {
    NSLog(@"sdk log: %@", message);
}

#pragma mark - VungleSDKDelegate methods

- (void)vungleSDKDidInitialize {
    NSLog(@"vungleSDKDidInitialize");
    
    if(_delegate != nil && [_delegate respondsToSelector:@selector(sdkDidInitialize)]) {
        [_delegate sdkDidInitialize];
    }
    
    if(_queue.count > 0) {
        NSString *pID = [_queue firstObject];
        [self loadPlacement:pID];
        [_queue removeObjectAtIndex:0];
    }
}

- (void)vungleSDKFailedToInitializeWithError:(NSError *)error {
    NSLog(@"vungleSDKFailedToInitializeWithError, %@", error);
}

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable placementID:(nullable NSString *)placementID {
    NSLog(@"vungleAdPlayabilityUpdate:%@ placementID:%@", @(isAdPlayable), placementID);
    if (_sdk.initialized && isAdPlayable && [placementID isEqualToString:_placementId]) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(onAdLoaded:)]) {
            [self.delegate onAdLoaded:nil];
        }
    }
}


#if 0
- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable placementID:(nullable NSString *)placementID error:(nullable NSError *)error {
    NSLog(@"vungleAdPlayabilityUpdate:%@ placementID:%@  error:%@", @(isAdPlayable), placementID, error);
    if (_sdk.initialized && isAdPlayable && [placementID isEqualToString:_placementId]) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(onAdLoaded:)]) {
            [self.delegate onAdLoaded:nil];
        }
    }
}
#endif

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID {
    NSLog(@"vungleWillShowAdForPlacementID, %@", placementID);
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(onAdDidPlay)]) {
        [self.delegate onAdDidPlay];
    }
}

- (void)vungleWillCloseAdWithViewInfo:(nonnull VungleViewInfo *)info placementID:(nonnull NSString *)placementID {
    NSLog(@"vungleWillCloseAdWithViewInfo, %@, %@", info, placementID);
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(onAdDidClose)]) {
        [self.delegate onAdDidClose];
    }
}

#if 0
- (void)vungleDidCloseAdWithViewInfo:(nonnull VungleViewInfo *)info placementID:(nonnull NSString *)placementID {
    NSLog(@"vungleDidCloseAdWithViewInfo, %@, %@", info, placementID);
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(onAdDidClose)]) {
        [self.delegate onAdDidClose];
    }
}
#endif


@end
