//
//  BBStreamingViewController.m
//  Sync SDK Example
//
//  Created by Camden Fullmer on 7/1/14.
//  Copyright (c) 2014 Improv Electronics. All rights reserved.
//

#import "BBStreamingViewController.h"
#import "BBSync.h"

@interface BBStreamingViewController () <BBSyncStreamingClientDelegate>

@property (strong, nonatomic) IBOutlet UILabel *xLabel;
@property (strong, nonatomic) IBOutlet UILabel *yLabel;
@property (strong, nonatomic) IBOutlet UILabel *pressureLabel;
@property (nonatomic) BBSyncStreamingClient *streamingClient;

@end

@implementation BBStreamingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidConnect:) name:BBSessionControllerDidConnect object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidDisconnect:) name:BBSessionControllerDidDisconnect object:nil];
    self.xLabel.text = @"0";
    self.yLabel.text = @"0";
    self.pressureLabel.text = @"0";
    self.streamingClient = [BBSyncStreamingClient sharedClient];
    self.streamingClient.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if([BBSessionController sharedController].isConnected) {
        [self.streamingClient setSyncMode:BBSyncModeCapture];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if([BBSessionController sharedController].isConnected) {
        [self.streamingClient setSyncMode:BBSyncModeNone];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - BBSyncStreamingClientDelegate methods

- (void)streamingClient:(BBSyncStreamingClient *)client didReceivePaths:(NSArray *)paths {
}

- (void)syncWasErased {
}

- (void)streamingClient:(BBSyncStreamingClient *)client didReceiveCaptureMessage:(BBSyncCaptureMessage *)message {
    self.xLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)message.x];
    self.yLabel.text = [NSString stringWithFormat:@"%lu", message.y];
    self.pressureLabel.text = [NSString stringWithFormat:@"%lu", message.pressure];
}

#pragma mark - Private methods

- (void)syncDidConnect:(NSNotification *)note {
    [self.streamingClient setSyncMode:BBSyncModeCapture];
}

- (void)syncDidDisconnect:(NSNotification *)note {
    
}

@end
