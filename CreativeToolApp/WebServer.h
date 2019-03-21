//
//  WebServer.h
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebServer : NSObject
@property(nonatomic, readonly) NSURL* serverURL;
@property(nonatomic, assign) NSInteger portNumber;
@property(nonatomic, copy) NSString *webStaticFolderPath;


+(instancetype)sharedInstance;

-(void)setup;

@end
