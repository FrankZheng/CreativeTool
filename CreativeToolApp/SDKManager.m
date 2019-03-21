//
//  SDKManager.m
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import "SDKManager.h"
#import <VungleSDK/VungleSDK.h>
#import "AppConfig.h"

@interface SDKManager() <VungleSDKDelegate, VungleSDKLogger>
@property(nonatomic, strong) VungleSDK *sdk;
@property(nonatomic, copy) NSString *placementId;
@property(nonatomic, copy) NSString *appId;

@end


@implementation SDKManager

+(instancetype)sharedInstance {
    static SDKManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SDKManager alloc] init];
    });
    return instance;
    
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _sdk = [VungleSDK sharedSDK];
        _placementId = [AppConfig placementId];
        _appId = [AppConfig appId];
    }
    return self;
}


- (void)loadAd {
    if (!_sdk.isInitialized) {
        //if sdk not initialized, try to initialize
        //and load ad when sdk initialized
        [_sdk setLoggingEnabled:YES];
        [_sdk attachLogger:self];
        _sdk.delegate = self;
        
        
        [[NSUserDefaults standardUserDefaults] setObject:self.serverURL.absoluteString forKey:@"vungle.api_endpoint"];
        NSError *error = nil;
        if ([_sdk startWithAppId:_appId error:&error]) {
            NSLog(@"Failed to initialize sdk, %@", error);
        }
    } else {
        //if sdk already initialized, just load ad directly
        NSError *error = nil;
        if(![_sdk loadPlacementWithID:_placementId error:&error]) {
            NSLog(@"Failed to load ad, %@", error);
        }
    }
}

- (void)playAd:(UIViewController*)viewController {
    NSError *error = nil;
    if(![_sdk playAd:viewController options:nil placementID:_placementId error:&error]) {
        NSLog(@"Failed to play ad, %@", error);
    }
}

- (void)vungleSDKLog:(NSString *)message {
    NSLog(@"sdk log: %@", message);
}

#pragma mark - VungleSDKDelegate methods

- (void)vungleSDKDidInitialize {
    NSLog(@"vungleSDKDidInitialize");
    
    //directly load ad
    NSError *error = nil;
    if(![_sdk loadPlacementWithID:_placementId error:&error]) {
        NSLog(@"Failed to load ad, %@", error);
    }
}

- (void)vungleSDKFailedToInitializeWithError:(NSError *)error {
    NSLog(@"vungleSDKFailedToInitializeWithError, %@", error);
}

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable placementID:(nullable NSString *)placementID error:(nullable NSError *)error {
    NSLog(@"vungleAdPlayabilityUpdate:%@ placementID:%@  error:%@", @(isAdPlayable), placementID, error);
    if (isAdPlayable && [placementID isEqualToString:_placementId]) {
        if (self.adDelegate != nil && [self.adDelegate respondsToSelector:@selector(onAdLoaded:)]) {
            [self.adDelegate onAdLoaded:nil];
        }
    }
}

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID {
    NSLog(@"vungleWillShowAdForPlacementID, %@", placementID);
    if (self.adDelegate != nil && [self.adDelegate respondsToSelector:@selector(onAdDidPlay)]) {
        [self.adDelegate onAdDidPlay];
    }
}

- (void)vungleWillCloseAdWithViewInfo:(nonnull VungleViewInfo *)info placementID:(nonnull NSString *)placementID {
    NSLog(@"vungleWillCloseAdWithViewInfo, %@, %@", info, placementID);
}

- (void)vungleDidCloseAdWithViewInfo:(nonnull VungleViewInfo *)info placementID:(nonnull NSString *)placementID {
    NSLog(@"vungleDidCloseAdWithViewInfo, %@, %@", info, placementID);
    if (self.adDelegate != nil && [self.adDelegate respondsToSelector:@selector(onAdDidClose)]) {
        [self.adDelegate onAdDidClose];
    }
}





@end
