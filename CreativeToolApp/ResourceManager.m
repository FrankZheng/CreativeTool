//
//  ResourceManager.m
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import "ResourceManager.h"

@implementation ResourceManager

+(instancetype)sharedInstance {
    static ResourceManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ResourceManager alloc] init];
    });
    return instance;
}

-(void)setup {
    //copy the resources in the app bundle to documents for later use
    //copy web/static folder to Application Support/web/static folder
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *supportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSString *webFolderPath = [supportPath stringByAppendingPathComponent:@"web"];
    _webStaticFolderPath = [webFolderPath stringByAppendingPathComponent:@"static"];
    BOOL isFolder = NO;
    if (![fm fileExistsAtPath:webFolderPath isDirectory:&isFolder]) {
        //create web folder
        NSError *error = nil;
        if ([fm createDirectoryAtPath:webFolderPath withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSString *staticPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"static"];
            if (![fm copyItemAtPath:staticPath toPath:_webStaticFolderPath error:&error]) {
                NSLog(@"failed to copy web static resources");
            }
        } else {
            NSLog(@"Failed to create web folder, %@, %@", webFolderPath, error);
        }
    }
    
#if 0
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSLog(@"caches path: %@", cachesPath);
    NSString *adCachesDirPath = [cachesPath stringByAppendingPathComponent:@"com.vungle.ads"];
    NSArray *adCaches = [fm contentsOfDirectoryAtPath:adCachesDirPath error:NULL];
    NSLog(@"%@", adCaches);
    
    NSString *supportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSString *placementsPath = [[supportPath stringByAppendingPathComponent:@"com.vungle"] stringByAppendingPathComponent:@"placements"];
    NSArray *placementMetaFiles = [fm contentsOfDirectoryAtPath:placementsPath error:NULL];
    NSLog(@"%@", placementMetaFiles);
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *placementMetaItem in placementMetaFiles) {
        NSString *placementMetaPath = [placementsPath stringByAppendingPathComponent:placementMetaItem];
        NSError *error = nil;
        NSString *metaStr = [NSString stringWithContentsOfFile:placementMetaPath encoding:NSASCIIStringEncoding error:&error];
        if (error != nil) {
            NSLog(@"failed to read placement meta data, %@", error);
        }
        for (NSString *cacheDirName in adCaches) {
            if([metaStr containsString:cacheDirName]) {
                dict[placementMetaItem] = cacheDirName;
                break;
            };
        }
    }
    
#endif

}


@end
