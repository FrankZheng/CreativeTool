//
//  ViewController.m
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/5.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import "ViewController.h"
#import "SDKManager.h"
#import "WebServer.h"
#import "AppConfig.h"
#import "ResourceManager.h"
#import "AppInitializer.h"


@interface ViewController () <AppInitializerDelegate, SDKDelegate, WebServerDelegate>
@property(nonatomic, weak) IBOutlet UITextView *instructionTv;
@property(nonatomic, weak) IBOutlet UIButton *playBtn;
@property(nonatomic, weak) IBOutlet UILabel *pIDLabel;
@property(nonatomic, weak) IBOutlet UILabel *serverURLLabel;

@property(nonatomic, strong) AppInitializer *appInitializer;
@property(nonatomic, strong) SDKManager *sdkManager;
@property(nonatomic, strong) WebServer *webServer;
@property(nonatomic, strong) ResourceManager *resourceManager;
@property(nonatomic, assign) BOOL playingAd;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //hide all controls for now
    [_playBtn setHidden:YES];
    [_pIDLabel setHidden:YES];
    
    _appInitializer = [AppInitializer sharedInstance];
    if(_appInitializer.isInitialized) {
        [self setup];
    } else {
        [_appInitializer addDelegate:self];
    }
}

- (void)setup {
    _sdkManager = [SDKManager sharedInstance];
    _sdkManager.delegate = self;
    _webServer = [WebServer sharedInstance];
    _resourceManager = [ResourceManager sharedInstance];
    _webServer.delegate = self;
    [self configInstructionText];
    [self showUploadEndcards];

    
}

- (IBAction)loadAd:(id)sender {
    [_sdkManager loadAd];
}

- (IBAction)playAd:(id)sender {
    [_sdkManager playAd:self];
}

- (void)showUploadEndcards {
    if(_resourceManager.didSetup) {
        NSArray *uploadEndcards = _resourceManager.uploadEndcardNames;
        if ([uploadEndcards count] > 0) {
            //has uploaded end cards, load it for now
            [_pIDLabel setHidden:NO];
            [_pIDLabel setText:[uploadEndcards firstObject]];
            [_playBtn setEnabled:NO];
            
            //Here need think about clear cache later
            [_sdkManager loadAd];
        }
    }
}

- (void)configInstructionText {
    NSString *txt = @"Please open the browser on your computer and visit following url to upload creatives.";
    [_instructionTv setText:txt];
    
    NSString *serverURL = _webServer.serverURL.absoluteString;
    if (serverURL.length > 0) {
        _serverURLLabel.text = serverURL;
    } else {
        _serverURLLabel.text = serverURL;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - SDKManagerDelegate methods
- (void)appDidInitialize {
    [self setup];
}

- (void)onAdLoaded:(NSError *)error {
    if (error == nil) {
        [_playBtn setHidden:NO];
        [_playBtn setEnabled:YES];
    }
    
    //TODO: handle errors later
}

- (void)onAdDidPlay {
    _playingAd = YES;
    [_playBtn setEnabled:NO];
}

- (void)onAdDidClose {
    _playingAd = NO;
    
    dispatch_async(dispatch_get_main_queue(),  ^{
        [self loadAd:nil];
    });
}

#pragma mark - WebServerDelegate methods
- (void)onEndcardUploaded:(NSString *)zipName {
    if (!_playingAd) {
        __weak __typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //there is a end card uploaded, need reload ad if not playing
            [weakSelf.sdkManager loadAd];
            [weakSelf.pIDLabel setText:zipName];
            [weakSelf.pIDLabel setHidden:NO];
        });
    } else {
        //If there is ad playing, just wait ad reloaded after ad did close.
    }
    
    //TODO: here need think about what happened if reloading ads for now?
}






@end
