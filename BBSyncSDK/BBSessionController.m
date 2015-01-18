// Copyright © 2014 Kent Displays, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import <UIKit/UIKit.h>

#import "BBSessionController.h"
#import "HIDMessage.h"
#import "BBSyncFileTransferClient.h"
#import "BBSyncStreamingClient.h"

#define FTP_PROTOCOL_NAME @"com.improvelectronics.sync-ftp"
#define HID_PROTOCOL_NAME @"com.improvelectronics.sync-hid"

NSString * const BBSessionControllerDidConnect = @"BBSessionControllerDidConnect";
NSString * const BBSessionControllerDidDisconnect = @"BBSessionControllerDidDisconnect";
NSString * const BBSessionControllerAccessoryKey = @"BBSessionControllerAccessoryKey";

@interface BBSessionController()

@property (nonatomic, readwrite) EAAccessory *accessory;
@property (nonatomic, readwrite) BOOL connected;

- (void)setupControllerForAccessory:(EAAccessory *)accessory;
- (void)teardown;
- (void)closeSessions;
- (void)lookForConnectedAccessories;

@end

@implementation BBSessionController

- (id)init {
    self = [super init];
    if (self) {
        _connected = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(teardown) name:UIApplicationWillTerminateNotification object:nil];
        [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
    [self teardown];
}

#pragma mark - Public methods

+ (instancetype)sharedController {
    static BBSessionController *sessionController = nil;
    if (sessionController == nil) {
        sessionController = [[BBSessionController alloc] init];
    }
    
    [sessionController lookForConnectedAccessories];
    
    return sessionController;
}

#pragma mark - Private methods

- (void)lookForConnectedAccessories {
    if(!self.isConnected) {
        // Check to see if a Sync is alread connected that is not known.
        NSArray *accessories = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
        for (int i = 0; i < [accessories count]; i++) {
            EAAccessory *connectedAccessory = [accessories objectAtIndex:i];
            if([[connectedAccessory protocolStrings] containsObject:FTP_PROTOCOL_NAME] && [[connectedAccessory protocolStrings] containsObject:HID_PROTOCOL_NAME]){
                [self setupControllerForAccessory:[accessories objectAtIndex:i]];
                break;
            }
        }
    }
}

- (void)setupControllerForAccessory:(EAAccessory *)accessory {
    self.accessory = accessory;
    // Open the sessions if there is a valid accessory that was connected.
    if(accessory != nil) {
        self.connected = YES;
        
        BBSyncFileTransferClient *ftpClient = [BBSyncFileTransferClient sharedClient];
        BBSyncStreamingClient *streamingClient = [BBSyncStreamingClient sharedClient];
        [ftpClient createSessionWithAccessory:accessory];
        [streamingClient createSessionWithAccessory:accessory];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BBSessionControllerDidConnect object:self userInfo:@{BBSessionControllerAccessoryKey:accessory}];
    }
}

- (void)teardown {
    self.connected = NO;
    if(self.accessory != nil) {
        [self closeSessions];
        [self setupControllerForAccessory:nil];
    }
}

- (void)closeSessions {
    BBSyncStreamingClient *streamingClient = [BBSyncStreamingClient sharedClient];
    BBSyncFileTransferClient *ftpClient = [BBSyncFileTransferClient sharedClient];
    [streamingClient closeSession];
    [ftpClient closeSession];
}

#pragma mark - Notifications

- (void)_accessoryDidConnect:(NSNotification *)notification {
    EAAccessory *connectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    
    if([connectedAccessory protocolStrings].count == 0) {
        return;
    }
    
    // Check that the device that was connected is a SYNC device.
    if([[connectedAccessory protocolStrings] containsObject:HID_PROTOCOL_NAME] && [[connectedAccessory protocolStrings] containsObject:FTP_PROTOCOL_NAME]) {
        // Set up the shared controller with the accessory and string.
        [self setupControllerForAccessory:connectedAccessory];
    }
}

- (void)_accessoryDidDisconnect:(NSNotification *)notification {
    EAAccessory *disconnectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
     
    // Check that the device that was disconnected is a SYNC device.
    if([[disconnectedAccessory protocolStrings] containsObject:HID_PROTOCOL_NAME] && [[disconnectedAccessory protocolStrings] containsObject:FTP_PROTOCOL_NAME]) {
        if(self.connected) {
            [self teardown];
            [[NSNotificationCenter defaultCenter] postNotificationName:BBSessionControllerDidDisconnect object:self userInfo:@{BBSessionControllerAccessoryKey : disconnectedAccessory}];
        }
    }
}

- (void)applicationDidBecomeActive:(id)sender {
    if(self.isConnected) {
        BBSyncStreamingClient *streamingClient = [BBSyncStreamingClient sharedClient];
        [streamingClient setSyncMode:BBSyncModeCapture];
    }
    else {
        [self lookForConnectedAccessories];
    }
}

@end
