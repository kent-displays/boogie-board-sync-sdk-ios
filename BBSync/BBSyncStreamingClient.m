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

#import "BBSyncStreamingClient.h"
#import "HIDUtilities.h"
#import "BBFiltering.h"
#import "HIDMessage.h"
#import "BBSyncCaptureMessage.h"
#import "HIDSetReport.h"
#import "HIDGetReport.h"

NSString * const BBSyncStreamingClientDidSave = @"BBSyncStreamingClientDidSave";

@interface BBSyncStreamingClient() <NSStreamDelegate>

@property (nonatomic) BBSessionController *sessionController;
@property (nonatomic) NSMutableArray *reportQueue;
@property (nonatomic) EASession *session;
@property (nonatomic) NSMutableData *writeData;
@property (nonatomic) NSMutableData *readData;
@property (nonatomic) NSMutableArray *paths;

- (void)setSyncDeviceFlags;
- (void)setSyncDateTime;

@end

@implementation BBSyncStreamingClient

- (id)init {
    self = [super init];
    if (self) {
        // Get reference to the controller.
        _sessionController = [BBSessionController sharedController];
        _reportQueue = [NSMutableArray new];
        _paths = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    [self closeSession];
}

#pragma mark - Public methods

+ (instancetype)sharedClient {
    static BBSyncStreamingClient *client = nil;
    if (client == nil) {
        client = [[BBSyncStreamingClient alloc] init];
    }
    
    return client;
}

#define HID_PROTOCOL_NAME @"com.improvelectronics.sync-hid"

- (void)createSessionWithAccessory:(EAAccessory *)accessory {
    self.session = [[EASession alloc] initWithAccessory:accessory forProtocol:HID_PROTOCOL_NAME];
    if (self.session) {
        NSLog(@"Creating new session.");
        [[self.session inputStream] setDelegate:self];
        [[self.session outputStream] setDelegate:self];
        [[self.session inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self.session inputStream] open];
        [[self.session outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self.session outputStream] open];
        
        [self setSyncDateTime];
        [self setSyncDeviceFlags];
        [self setSyncMode:BBSyncModeFile];
    } else {
        NSLog(@"Creating HID session failed.");
    }
}

- (void)closeSession {    
    if(self.sessionController.isConnected) {
        [self setSyncMode:BBSyncModeNone];
    }
    
    [self.reportQueue removeAllObjects];
    self.writeData = nil;
    self.readData = nil;
    
    [[self.session inputStream] close];
    [[self.session inputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[self.session inputStream] setDelegate:nil];
    [[self.session outputStream] close];
    [[self.session outputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[self.session outputStream] setDelegate:nil];
    self.session = nil;
}

#define ERASE_MODE 0x01
- (void)eraseSync {
    const unsigned char payloadBytes[] = {ERASE_MODE};
    NSData *payload = [NSData dataWithBytes:payloadBytes length:1];
    HIDSetReport *report = [[HIDSetReport alloc] initWithReportType:HIDSetReportTypeFeature reportId:HIDSetReportIdOperationRequest payload:payload];
    [self writeData:report.framedData];
}

- (void)setSyncMode:(BBSyncMode)mode {
    const unsigned char payloadBytes[] = {mode};
    NSData *payload = [NSData dataWithBytes:payloadBytes length:1];
    HIDSetReport *report = [[HIDSetReport alloc] initWithReportType:HIDSetReportTypeFeature reportId:HIDSetReportIdMode payload:payload];
    [self writeData:report.framedData];
}

#pragma mark - Private methods

- (void)sessionDataReceived {
    NSUInteger bytesAvailable = 0;
    
    while ((bytesAvailable = [self readBytesAvailable]) > 0) {
        NSData *data = [self readData:bytesAvailable];
        NSArray *messages = [HIDUtilities parsedMessagesFromData:data];
        for(HIDMessage *message in messages) {
            if([message isKindOfClass:[BBSyncCaptureMessage class]]) {
                BBSyncCaptureMessage *captureMessage = (BBSyncCaptureMessage *)message;
                NSArray *paths = [BBFiltering filteredPathsForCaptureMessage:captureMessage];
                
                if(paths.count > 0) {
                    [self.paths addObjectsFromArray:paths];
                }
                
                if([captureMessage hasEraseFlag]) {
                    [self.paths removeAllObjects];
                }
                
                if([captureMessage hasSaveFlag]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:BBSyncStreamingClientDidSave object:self];
                }
                
                // Send information to the delegate that is set.
                if(self.delegate) {
                    [self.delegate streamingClient:self didReceiveCaptureMessage:captureMessage];
                    
                    if([captureMessage hasEraseFlag]) {
                        [self.delegate syncWasErased];
                    }
                    
                    if(paths.count > 0) {
                        [self.delegate streamingClient:self didReceivePaths:paths];
                    }
                }
            }
        }
    }
}

#define IOS_DEVICE 0x04
- (void)setSyncDeviceFlags {
    const unsigned char payloadBytes[] = {IOS_DEVICE, 0x00, 0x00, 0x00};
    NSData *payload = [NSData dataWithBytes:payloadBytes length:4];
    HIDSetReport *report = [[HIDSetReport alloc] initWithReportType:HIDSetReportTypeFeature reportId:HIDSetReportIdDevice payload:payload];
    [self writeData:report.framedData];
}

#define YEAR_OFFSET 1980
- (void)setSyncDateTime {
    // Retrieve all the units for the current time.
    NSDate *currentDate = [[NSDate alloc] init];
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSSecondCalendarUnit|NSMinuteCalendarUnit|NSHourCalendarUnit|NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit;
    NSDateComponents *dateComponents = [currentCalendar components:(unitFlags) fromDate:currentDate];
    
    uint8_t second = [dateComponents second] / 2; // Must divide by 2 to abide by protocol.
    uint8_t minute = [dateComponents minute];
    uint8_t hour = [dateComponents hour];
    uint8_t day = [dateComponents day];
    uint8_t month = [dateComponents month];
    uint8_t year = [dateComponents year] - YEAR_OFFSET; // Year offset starting from 1980.
    
    // Convert all the numbers into the current bytes to send in the feature report.
    uint8_t byte1 = (minute << 5) | second;
    uint8_t byte2 = (hour << 3) | (minute >> 3);
    uint8_t byte3 = (month << 5) | day;
    uint8_t byte4 = (year << 1) | (month >> 3);
    
    // Create payload for date message.
    const unsigned char payloadBytes[] = {byte1, byte2, byte3, byte4};
    NSData *payload = [NSData dataWithBytes:payloadBytes length:4];
    HIDSetReport *report = [[HIDSetReport alloc] initWithReportType:HIDSetReportTypeFeature reportId:HIDSetReportIdDate payload:payload];
    [self writeData:report.framedData];
}

#pragma mark - NSStreamDelegateEventExtensions methods

// asynchronous NSStream handleEvent method
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventNone:
            break;
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventHasBytesAvailable:
            [self _readData];
            break;
        case NSStreamEventHasSpaceAvailable:
            [self _writeData];
            break;
        case NSStreamEventErrorOccurred:
            break;
        case NSStreamEventEndEncountered:
            break;
        default:
            break;
    }
}

// low level write method - write data to the accessory while there is space available and data to write
- (void)_writeData {
    while (([[self.session outputStream] hasSpaceAvailable]) && ([self.writeData length] > 0)) {
        NSInteger bytesWritten = [[self.session outputStream] write:[self.writeData bytes] maxLength:[self.writeData length]];
        if (bytesWritten == -1)
        {
            NSLog(@"Write error on FTP session.");
            break;
        }
        else if (bytesWritten > 0)
        {
            [self.writeData replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
        }
    }
}

// low level read method - read data while there is data and space available in the input buffer
- (void)_readData {
#define EAD_INPUT_BUFFER_SIZE 256
    uint8_t buf[EAD_INPUT_BUFFER_SIZE];
    NSInteger bytesRead = 0;
    while ([self.session.inputStream hasBytesAvailable]) {
        bytesRead = [self.session.inputStream read:buf maxLength:EAD_INPUT_BUFFER_SIZE];
        if (self.readData == nil) {
            self.readData = [[NSMutableData alloc] init];
        }
        [self.readData appendBytes:(void *)buf length:bytesRead];
    }

    if(bytesRead > 0) {
        [self sessionDataReceived];
    }
}

// high level write data method
- (void)writeData:(NSData *)data {
    if (self.writeData == nil) {
        self.writeData = [[NSMutableData alloc] init];
    }
    [self.writeData appendData:data];
    [self _writeData];
}

// high level read method
- (NSData *)readData:(NSUInteger)bytesToRead {
    NSData *data = nil;
    if ([self.readData length] >= bytesToRead) {
        NSRange range = NSMakeRange(0, bytesToRead);
        data = [self.readData subdataWithRange:range];
        [self.readData replaceBytesInRange:range withBytes:NULL length:0];
    }
    return data;
}

// get number of bytes read into local buffer
- (NSUInteger)readBytesAvailable {
    return self.readData.length;
}

@end
