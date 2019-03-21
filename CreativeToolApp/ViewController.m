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


@interface ViewController () <AdDelegate>
@property(nonatomic, weak) IBOutlet UITextView *instructionTv;
@property(nonatomic, weak) IBOutlet UIButton *loadBtn;
@property(nonatomic, weak) IBOutlet UIButton *playBtn;
@property(nonatomic, weak) IBOutlet UILabel *pIDLabel;
@property(nonatomic, strong) SDKManager *sdkManager;
@property(nonatomic, strong) WebServer *webServer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _sdkManager = [SDKManager sharedInstance];
    _sdkManager.adDelegate = self;
    _webServer = [WebServer sharedInstance];
    
    //set the instruction text
    NSString *txtFmt = @"Please open your brower on your computer and visit following url to upload creative bundle files(.zip). \n%@";
    [_instructionTv setText:[NSString stringWithFormat:txtFmt, _webServer.serverURL.absoluteString]];
    
    [_pIDLabel setText:[AppConfig placementId]];
    
    [_playBtn setEnabled:NO];
    
    
    
}

- (IBAction)loadAd:(id)sender {
    [_sdkManager loadAd];
}

- (IBAction)playAd:(id)sender {
    [_sdkManager playAd:self];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - AdDelegate methods

-(void)onAdLoaded:(NSError *)error {
    if (error == nil) {
        [_playBtn setEnabled:YES];
        [_loadBtn setEnabled:NO];
    }
}

-(void)onAdDidPlay {
    [_playBtn setEnabled:NO];
}

-(void)onAdDidClose {
    [_playBtn setEnabled:NO];
    [_loadBtn setEnabled:YES];
}



@end
