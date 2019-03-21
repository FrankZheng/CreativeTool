//
//  WebServer.m
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import "WebServer.h"
#import <GCDWebServers/GCDWebServer.h>
#import <GCDWebServers/GCDWebServerDataResponse.h>
#import <GCDWebServers/GCDWebUploader.h>
@import ZipArchive;


@interface WebServer()
@property(nonatomic, strong) GCDWebServer *webServer;

@end

@implementation WebServer

+(instancetype)sharedInstance {
    static WebServer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WebServer alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _webServer = [[GCDWebServer alloc] init];
        _portNumber = 8091;
    }
    return self;
    
}



- (void)setup {
    //setup end points
    __weak __typeof(self) weakSelf = self;
    
    //home page
    [_webServer addDefaultHandlerForMethod:@"GET"
                              requestClass:[GCDWebServerRequest class]
                              processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                  return [weakSelf homePageHandler:request];
                              }];
    
    //upload
    [_webServer addHandlerForMethod:@"POST"
                               path:@"/upload"
                       requestClass:[GCDWebServerMultiPartFormRequest class]
                       processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                           return [weakSelf uploadHandler:(GCDWebServerMultiPartFormRequest*)request];
                       }];
    
    //mock ad server config
    [_webServer addHandlerForMethod:@"POST"
                               path:@"/config"
                       requestClass:[GCDWebServerRequest class]
                       processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                           return [weakSelf adConfigHandler:request];
                       }];
    
    //ok -> {"msg":"ok", code:200}
    [_webServer addHandlerForMethod:@"POST"
                               path:@"/ok"
                       requestClass:[GCDWebServerRequest class]
                       processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                           return [weakSelf okHandler:request];
                       }];
    
    //ads
    [_webServer addHandlerForMethod:@"POST"
                               path:@"/ads"
                       requestClass:[GCDWebServerRequest class]
                       processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                           return [weakSelf adsHandler:request];
                       }];
    
    
    //static resources
    [_webServer addGETHandlerForBasePath:@"/"
                           directoryPath:self.webStaticFolderPath
                           indexFilename:nil
                                cacheAge:3600
                      allowRangeRequests:YES];
    
    
    [_webServer startWithPort:_portNumber bonjourName:nil];
    NSLog(@"Visit %@ in your web browser", _webServer.serverURL);
    
}

- (NSURL *)serverURL {
    return self.webServer.serverURL;
}

- (NSString *)serverURLWithPath:(NSString*)path  {
    return [[self.serverURL URLByAppendingPathComponent:path] absoluteString];
}


//for home page, "/" or "/index"
- (GCDWebServerResponse *)homePageHandler:(GCDWebServerRequest*)req {
    NSString *indexFile = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSString *indexStr = [NSString stringWithContentsOfFile:indexFile
                                                   encoding:NSUTF8StringEncoding error:NULL];
    return [GCDWebServerDataResponse responseWithHTML:indexStr];
}

//for upload, user could upload end card zip file by using this
- (GCDWebServerResponse *)uploadHandler:(GCDWebServerMultiPartFormRequest*)req {
    
    GCDWebServerMultiPartFile* file = [req firstFileForControlName:@"bundle"];
    //NSString* relativePath = [[req firstArgumentForControlName:@"path"] string];
    NSLog(@"%@", file.temporaryPath);
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *tempDir = [fm temporaryDirectory];
    NSLog(@"%@", tempDir);
    NSString *targetZipPath = [[tempDir URLByAppendingPathComponent:@"banner_ads_1"] path];
    NSLog(@"%@", targetZipPath);
    NSError *error = nil;
#if 0
    if(![fm moveItemAtPath:file.temporaryPath toPath:targetZipPath error:&error]) {
        NSLog(@"Failed to move multipart file to tempoary dir, %@", error);
    }
#endif
    
    if(![SSZipArchive unzipFileAtPath:file.temporaryPath
                        toDestination:targetZipPath
                            overwrite:YES password:nil error:&error]) {
        NSLog(@"Failed to unzip bundle, %@", error);
    }
    
    
    //1.Verify the file.contentType == 'application/zip" and file.fileName is with .zip extension
    //
    
    //Move the uploaded zip file into a temporary dir
    //Unzip the zip file and check if it's valid
    //Have index.html at root level
    //Search all folders, if has files other than .js, .css, need reminder user
    //Should only put all resources under root dir with the index.html
    
    return [GCDWebServerDataResponse responseWithHTML:@"<html><body>Uploaded</body></html>"];
}

- (GCDWebServerResponse *)adConfigHandler:(GCDWebServerRequest*)req {
    NSString *configFilePath = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:configFilePath];
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSMutableDictionary *endpoints = [json[@"endpoints"] mutableCopy];
    endpoints[@"new"] = [self serverURLWithPath:@"ok"];
    endpoints[@"report_ad"] = [self serverURLWithPath:@"ok"];
    endpoints[@"ads"] = [self serverURLWithPath:@"ads"];
    
    //Following endpoints should not be called
    //logging is disabled
    //will_play_ad is disabled
    //ri is disabled
    //endpoints[@"log"] =
    //endpoints[@"will_play_ad"] =
    //endpoints[@"ri"] =
    NSMutableDictionary *mutableJson = [json mutableCopy];
    mutableJson[@"endpoints"] = endpoints;
    
    return [GCDWebServerDataResponse responseWithJSONObject:[mutableJson copy]];
}

- (GCDWebServerResponse *)adsHandler:(GCDWebServerRequest*)req {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ads" ofType:@"json"];
    //NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    NSString *str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    NSString *adPath = [self serverURLWithPath:@"endcard.zip"];
    NSString *videoPath = [self serverURLWithPath:@"countdown_video.mp4"];
    
    NSString *str1 = [str stringByReplacingOccurrencesOfString:@"${postBundle}" withString:adPath];
    NSString *str2 = [str1 stringByReplacingOccurrencesOfString:@"${videoURL}" withString:videoPath];
    NSData *data = [str2 dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return [GCDWebServerDataResponse responseWithJSONObject:json];
}

- (GCDWebServerResponse *)okHandler:(GCDWebServerRequest*)req {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ok" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return [GCDWebServerDataResponse responseWithJSONObject:json];
}







@end
