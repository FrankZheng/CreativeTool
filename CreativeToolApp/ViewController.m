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


@interface ViewController () <AdDelegate, WebServerDelegate>
@property(nonatomic, weak) IBOutlet UITextView *instructionTv;
@property(nonatomic, weak) IBOutlet UIButton *loadBtn;
@property(nonatomic, weak) IBOutlet UIButton *playBtn;
@property(nonatomic, weak) IBOutlet UILabel *pIDLabel;
@property(nonatomic, strong) SDKManager *sdkManager;
@property(nonatomic, strong) WebServer *webServer;
@property(nonatomic, strong) ResourceManager *resourceManager;
@property(nonatomic, assign) BOOL playingAd;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _sdkManager = [SDKManager sharedInstance];
    _sdkManager.adDelegate = self;
    _webServer = [WebServer sharedInstance];
    _resourceManager = [ResourceManager sharedInstance];
    _webServer.delegate = self;
    
    //hide all controls for now
    [_loadBtn setHidden:YES];
    
    [self configInstructionText];
    
    NSArray *uploadEndcards = _resourceManager.uploadEndcardNames;
    if ([uploadEndcards count] > 0) {
        //has uploaded end cards, load it for now
        [_pIDLabel setText:[uploadEndcards firstObject]];
        [_playBtn setEnabled:NO];
        
        //Here need think about clear cache later
        [_sdkManager loadAd];
        
    } else {
        //hide all controls for now
        [_loadBtn setHidden:YES];
        [_playBtn setHidden:YES];
        [_pIDLabel setHidden:YES];
    }
}

- (IBAction)loadAd:(id)sender {
    [_sdkManager loadAd];
}

- (IBAction)playAd:(id)sender {
    [_sdkManager playAd:self];
}

- (void)configInstructionText {
    NSString *serverURL = _webServer.serverURL.absoluteString;
    if (serverURL.length > 0) {
        NSString *txtFmt = @"Please open your brower on your computer and visit following url to upload creative bundle files(.zip). \n%@";
        [_instructionTv setText:[NSString stringWithFormat:txtFmt, serverURL]];
    } else {
        [_instructionTv setText:@""];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - AdDelegate methods

-(void)onAdLoaded:(NSError *)error {
    if (error == nil) {
        [_playBtn setHidden:NO];
        [_playBtn setEnabled:YES];
        [_loadBtn setEnabled:NO];
    }
}

-(void)onAdDidPlay {
    _playingAd = YES;
    [_playBtn setEnabled:NO];
}

-(void)onAdDidClose {
    _playingAd = NO;
    //[_playBtn setEnabled:NO];
    //[_loadBtn setEnabled:YES];
    
    //could load ad again
}

-(void)onEndcardUploaded:(NSString *)zipName {
    if (!_playingAd) {
        //there is a end card uploaded, need reload ad if not playing
        [_sdkManager loadAd];
        __weak __typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.pIDLabel setText:zipName];
            [weakSelf.pIDLabel setHidden:NO];
        });
        
    }
}

-(void)onServerStarted {
    [self configInstructionText];
}



@end
