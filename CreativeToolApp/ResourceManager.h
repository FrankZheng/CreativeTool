//
//  ResourceManager.h
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

//This class used to manage the static resources for web content
@interface ResourceManager : NSObject
@property(nonatomic, readonly) NSString *webStaticFolderPath;
@property(nonatomic, readonly) NSString *webUploadFolderPath;
@property(nonatomic, readonly) NSArray<NSString *> *uploadEndcardNames;
@property(nonatomic, assign) NSInteger uploadEndcardMaxCount;


+(instancetype)sharedInstance;

-(void)setup;

//remove all uploaded creatives
-(void)cleanUpUploadFolder;


@end
