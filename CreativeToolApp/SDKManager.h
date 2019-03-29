//
//  SDKManager.h
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol SDKDelegate
@optional
- (void)sdkDidInitialize;
- (void)onAdLoaded:(NSError *)error;
- (void)onAdDidPlay;
- (void)onAdDidClose;

@end

@interface SDKManager : NSObject
@property(nonatomic, weak) NSObject<SDKDelegate> *delegate;
@property(nonatomic, copy) NSURL *serverURL; //for mock the backend server
@property(nonatomic, readonly, getter=isStarted) BOOL started;

+ (instancetype)sharedInstance;


- (void)start;

- (void)loadAd;

- (void)playAd:(UIViewController*)viewController;

- (void)clearCache;





@end
