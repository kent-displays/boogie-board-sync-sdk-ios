//
//  BBFileTransferViewController.m
//  Sync SDK Example
//
//  Created by Camden Fullmer on 7/1/14.
//  Copyright (c) 2014 Improv Electronics. All rights reserved.
//

#import "BBFileTransferViewController.h"
#import "BBSyncSDK.h"

@interface BBFileTransferViewController () <BBSyncFileTransferClientDelegate>
- (IBAction)parentButtonClicked:(id)sender;

@property (nonatomic) OBEXFileTransferFolderListing *folderListing;
@property (nonatomic) BBSyncFileTransferClient *fileTransferClient;

@end

@implementation BBFileTransferViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        _folderListing = [[OBEXFileTransferFolderListing alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidConnect:) name:BBSessionControllerDidConnect object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidDisconnect:) name:BBSessionControllerDidDisconnect object:nil];
    self.fileTransferClient = [BBSyncFileTransferClient sharedClient];
    self.fileTransferClient.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if([BBSessionController sharedController].isConnected) {
        [self.fileTransferClient connect];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if(self.fileTransferClient.state == BBSyncFileTransferClientStateConnected) {
        [self.fileTransferClient disconnect];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.folderListing.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BBFileTransferCell" forIndexPath:indexPath];
    OBEXFileTransferItem *item = [self.folderListing objectAtIndex:indexPath.row];
    cell.textLabel.text = item.name;
    if([item isKindOfClass:[OBEXFileTransferFolder class]]) {
        cell.detailTextLabel.text = @"Folder";
    }
    else {
        cell.detailTextLabel.text = @"File";
    }
    return cell;
}

#pragma mark - Table view delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OBEXFileTransferItem *item = [self.folderListing objectAtIndex:indexPath.row];
    if([item isKindOfClass:[OBEXFileTransferFolder class]]) {
        [self.fileTransferClient changeFolder:item.name];
    }
}

#pragma mark - Private methods

- (void)syncDidConnect:(NSNotification *)note {
    [self.fileTransferClient connect];
}

- (void)syncDidDisconnect:(NSNotification *)note {
    
}

#pragma mark - BBSyncFileTransferClientDelegate methods

- (void)fileTransferClient:(BBSyncFileTransferClient *)client didGetFile:(OBEXFileTransferFile *)file error:(NSError *)error {
    
}

- (void)fileTransferClient:(BBSyncFileTransferClient *)client didListFolder:(OBEXFileTransferFolderListing *)folderListing error:(NSError *)error {
    self.folderListing = folderListing;
    [self.tableView reloadData];
}

- (void)fileTransferClient:(BBSyncFileTransferClient *)client didDeleteFile:(OBEXFileTransferFile *)file error:(NSError *)error {
}

- (void)fileTransferClient:(BBSyncFileTransferClient *)client didChangeFolder:(NSString *)folder error:(NSError *)error {
    if(!error) {
        NSLog(@"Changed folder");
        [self.fileTransferClient listFolder];
    }
}

- (void)fileTransferClient:(BBSyncFileTransferClient *)client didConnectWithError:(NSError *)error {
    if(!error) {
        NSLog(@"Connected to file transfer server.");
        [self.fileTransferClient rootFolder];
    }
}

- (void)fileTransferClient:(BBSyncFileTransferClient *)client didReceiveError:(NSError *)error {
}

- (IBAction)parentButtonClicked:(id)sender {
    [self.fileTransferClient changeFolder:nil];
}
@end
