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

#import "BBSyncFileTransferClient.h"
#import "OBEXFileTransferRequest.h"
#import "OBEXFileTransferUtilities.h"
#import "OBEXFileTransferResponse.h"
#import "OBEXFileTransferFolderListingParser.h"
#import "BBSyncStreamingClient.h"

NSString * const kBBSyncFileTransferErrorDomain = @"BBSyncFileTransferErrorDomain";

@interface BBSyncFileTransferClient() <NSStreamDelegate>

- (void)enqueueRequest:(OBEXFileTransferRequest*)request;
- (OBEXFileTransferRequest *)dequeueRequest;
- (void)requestTimedOut;

@property (nonatomic) NSData *connectionID;
@property (nonatomic) NSMutableData *directory;
@property (nonatomic) BBSessionController *sessionController;
@property (strong) NSMutableArray *requestQueue;
@property (nonatomic) NSTimer *timeoutTimer;
@property (nonatomic) OBEXFileTransferFile *tempFile;
@property (nonatomic) EASession *session;
@property (nonatomic) NSMutableData *writeData;
@property (nonatomic) NSMutableData *readData;
@property (nonatomic, readwrite) BBSyncFileTransferClientState state;
@property (nonatomic, readwrite) NSMutableString *currentDirectoryPath;

@end

@implementation BBSyncFileTransferClient

- (id)init {
    self = [super init];
    if (self) {
        _sessionController = [BBSessionController sharedController];
        _directory = [[NSMutableData alloc] init];
        _state = BBSyncFileTransferClientStateDisconnected;
        _requestQueue = [NSMutableArray new];
    }
    return self;
}

+ (instancetype)sharedClient {
    static BBSyncFileTransferClient *client = nil;
    if (client == nil) {
        client = [[BBSyncFileTransferClient alloc] init];
    }
    return client;
}

#define FTP_PROTOCOL_NAME @"com.improvelectronics.sync-ftp"

- (void)createSessionWithAccessory:(EAAccessory *)accessory {
    self.session = [[EASession alloc] initWithAccessory:accessory forProtocol:FTP_PROTOCOL_NAME];
    if (self.session) {
        NSLog(@"Creating new session.");
        [[self.session inputStream] setDelegate:self];
        [[self.session outputStream] setDelegate:self];
        [[self.session inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self.session inputStream] open];
        [[self.session outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self.session outputStream] open];
    } else {
        NSLog(@"Creating FTP session failed.");
    }
}

- (void)cleanup {
    [self.requestQueue removeAllObjects];
    self.tempFile = nil;
    self.state = BBSyncFileTransferClientStateDisconnected;
    [self.timeoutTimer invalidate];
    self.connectionID = nil;
    [self.directory setLength:0];
    self.writeData = nil;
    self.readData = nil;
    self.currentDirectoryPath = nil;
}

- (void)closeSession {
    if(self.session) {
        [self cleanup];
        [[self.session inputStream] close];
        [[self.session inputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self.session inputStream] setDelegate:nil];
        [[self.session outputStream] close];
        [[self.session outputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self.session outputStream] setDelegate:nil];
        self.session = nil;
    }
}

- (void)dealloc {
    [self closeSession];
}

#pragma mark - Public methods

- (void)listFolder {
    if(self.state == BBSyncFileTransferClientStateConnected) {
        NSLog(@"Creating list folder request.");
        OBEXFileTransferRequest *request = [[OBEXFileTransferRequest alloc] initWithOpCode:GET];
        [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:CONNECTION_ID body:self.connectionID]];
        [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:NAME]];
        NSData *folderListingTypeData = [[NSData alloc] initWithBytes:FOLDER_LISTING_TYPE length:22];
        [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:TYPE body:folderListingTypeData]];
        [self enqueueRequest:request];
    }
    else {
        NSError *error = [[NSError alloc] initWithDomain:kBBSyncFileTransferErrorDomain code:0 userInfo:nil];
        [self.delegate fileTransferClient:self didListFolder:nil error:error];
    }
}

- (void)changeFolder:(NSString *)folder {
    if(self.state == BBSyncFileTransferClientStateConnected) {
        NSLog(@"Creating change folder request.");
        OBEXFileTransferRequest *request  = [[OBEXFileTransferRequest alloc] initWithOpCode:SET_PATH];
        if(!folder) {
            [request setFlags:BACKUP_FLAG|DONT_CREATE_FOLDER_FLAG];
        }
        else {
            [request setFlags:DONT_CREATE_FOLDER_FLAG];
            [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:NAME name:folder]];
        }    
        [request setConstants:DEFAULT_CONSTANT];
        [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:CONNECTION_ID body:self.connectionID]];
        [self enqueueRequest:request];
    }
    else {
        NSError *error = [[NSError alloc] initWithDomain:kBBSyncFileTransferErrorDomain code:0 userInfo:nil];
        [self.delegate fileTransferClient:self didChangeFolder:nil error:error];
    }
}

- (void)rootFolder {
    if(self.state == BBSyncFileTransferClientStateConnected) {
        NSLog(@"Creating root folder request.");
        OBEXFileTransferRequest *request  = [[OBEXFileTransferRequest alloc] initWithOpCode:SET_PATH];
        [request setFlags:DONT_CREATE_FOLDER_FLAG];
        [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:NAME]];
        [request setConstants:DEFAULT_CONSTANT];
        [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:CONNECTION_ID body:self.connectionID]];
        [self enqueueRequest:request];
    }
    else {
        NSError *error = [[NSError alloc] initWithDomain:kBBSyncFileTransferErrorDomain code:0 userInfo:nil];
        [self.delegate fileTransferClient:self didChangeFolder:nil error:error];
    }
}

- (void)getFile:(OBEXFileTransferFile *)file {
    if(self.state == BBSyncFileTransferClientStateConnected) {
        NSLog(@"Creating get file request.");
        // Save the temp file to add the data to.
        self.tempFile = file;
        
        // Construct the descend directory request object.
        OBEXFileTransferRequest *request  = [[OBEXFileTransferRequest alloc] initWithOpCode:GET];
        [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:CONNECTION_ID body:self.connectionID]];
        [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:NAME name:file.name]];
        [self enqueueRequest:request];
    }
    else {
        NSError *error = [[NSError alloc] initWithDomain:kBBSyncFileTransferErrorDomain code:0 userInfo:nil];
        [self.delegate fileTransferClient:self didGetFile:nil error:error];
    }
}

- (void)deleteFile:(OBEXFileTransferFile *)file {
    if(self.state == BBSyncFileTransferClientStateConnected) {
        NSLog(@"Creating delete request.");
        // Save the temp file to delete.
        self.tempFile = file;
        
        // Construct request to delete a file from the device.
        OBEXFileTransferRequest *request  = [[OBEXFileTransferRequest alloc] initWithOpCode:PUT];
        [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:CONNECTION_ID body:self.connectionID]];
        [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:NAME name:file.name]];
        [self enqueueRequest:request];
    }
    else {
        NSError *error = [[NSError alloc] initWithDomain:kBBSyncFileTransferErrorDomain code:0 userInfo:nil];
        [self.delegate fileTransferClient:self didDeleteFile:nil error:error];
    }
}

- (void)abort {
    if(self.state == BBSyncFileTransferClientStateConnected) {
        NSLog(@"Creating abort request.");
        // Trying to abort operation so cancel all other requests.
        [self cancelAllRequests];
        
        // Clean up any properties.
        [self.directory setLength:0];
        self.tempFile = nil;
        
        // Construct the abort request object.
        OBEXFileTransferRequest *request  = [[OBEXFileTransferRequest alloc] initWithOpCode:ABORT];
        [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:CONNECTION_ID body:self.connectionID]];
        [self enqueueRequest:request];
    }
    else {
        //TODO
    }
}

- (void)disconnect {
    if(self.state == BBSyncFileTransferClientStateConnected) {

        // Abort the current opperation if we are trying to disconnect.
        if(self.requestQueue.count > 0) {
            [self abort];
        }
        
        NSLog(@"Creating disconnect request.");
        // Construct the disconnect request object.
        OBEXFileTransferRequest *request  = [[OBEXFileTransferRequest alloc] initWithOpCode:DISCONNECT];
        [request addHeader:[[OBEXFileTransferHeader alloc] initWithIdentifier:CONNECTION_ID body:self.connectionID]];
        self.state = BBSyncFileTransferClientStateDisconnecting;
        [self enqueueRequest:request];
    }
}

- (void)connect {
    if(self.state != BBSyncFileTransferClientStateConnected || self.state != BBSyncFileTransferClientStateConnecting) {
        NSLog(@"Creating connect request.");
        // Construct the connection request object.
        OBEXFileTransferRequest *request = [[OBEXFileTransferRequest alloc] initWithOpCode:CONNECT];
        [request setVersion:(OBEX_VERSION)];
        [request setFlags:(DEFAULT_FLAG)];
        NSData *maxPacketSize = [[NSData alloc] initWithBytes:MAXIMUM_PACKET_SIZE length:2];
        [request setMaxSize:maxPacketSize];
        NSData *targetData = [[NSData alloc] initWithBytes:OBEX_FTP_UUID length:16];
        [request addHeader:[[OBEXFileTransferHeader alloc]initWithIdentifier:TARGET body:targetData]];
        self.state = BBSyncFileTransferClientStateConnecting;
        [self enqueueRequest:request];
    }
    else {
        NSError *error = [[NSError alloc] initWithDomain:kBBSyncFileTransferErrorDomain code:0 userInfo:nil];
        [self.delegate fileTransferClient:self didConnectWithError:error];
    }
}

- (void)enqueueRequest:(OBEXFileTransferRequest *)request {
    if(!self.requestQueue) {
        self.requestQueue = [NSMutableArray new];
    }
    
    [self.requestQueue addObject:request];
    
    if(self.requestQueue.count == 1) {
        [self writeRequest:request];
    }
}

- (OBEXFileTransferRequest *)dequeueRequest {
    if(self.requestQueue.count > 0) {
        OBEXFileTransferRequest *request = self.requestQueue[0];
        [self.requestQueue removeObjectAtIndex:0];
        return request;
    }
    else {
        return nil;
    }
}

- (void)writeRequest:(OBEXFileTransferRequest *)request {
    request.state = BTFtpRequestStateProcessing;
    // Send request and start timeout timer.
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(requestTimedOut) userInfo:nil repeats:NO];
    [self writeData:[request byteArray]];
}

- (void)nextRequest {
    for(int i = 0; i < self.requestQueue.count; i++) {
        OBEXFileTransferRequest *request = self.requestQueue[i];
        if(request.state == BTFtpRequestStateCanceled) {
            [self.requestQueue removeObjectAtIndex:i];
            i--;
        }
        else {
            [self writeRequest:request];
            break;
        }
    }
}

- (void)cancelAllRequests {
    
    for(OBEXFileTransferRequest *request in self.requestQueue) {
        request.state = BTFtpRequestStateCanceled;
    }
}

- (void)requestTimedOut {
    NSString *description = @"Could not get a response from the Bluetooth FTP server.";
    NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : description};
    NSError *error = [[NSError alloc] initWithDomain:kBBSyncFileTransferErrorDomain code:0 userInfo:errorDictionary];
    [self cancelAllRequests];
    [self.delegate fileTransferClient:self didReceiveError:error];
}

- (void)sessionDataReceived {
    NSUInteger bytesAvailable = 0;
    NSError *error = nil;
    
    // Get the response.
    while((bytesAvailable = [self readBytesAvailable]) > 0) {
        NSData *data = [self readData:bytesAvailable];
        // Yay! We got a response back so invalidate the timer.
        [self.timeoutTimer invalidate];
        if(data) {
            OBEXFileTransferResponse *response = [[OBEXFileTransferResponse alloc] initWithData:data];
            OBEXFileTransferRequest *request = [self dequeueRequest];
            
            if(request.state == BTFtpRequestStateCanceled) {
                [self nextRequest];
                return;
            }
            
            // Process the response from the server.
            switch(response.code) {
                case SUCCESS:
                    if(request.code == CONNECT) {
                        NSLog(@"Connected to Bluetooth FTP Server.");
                        self.state = BBSyncFileTransferClientStateConnected;
                        
                        // Save connection id for future requests.
                        OBEXFileTransferHeader *header = [[response headers] objectForKey:[NSString stringWithFormat:@"%c" , CONNECTION_ID]];
                        self.connectionID = [[NSData alloc] initWithData:[header data]];
                        self.currentDirectoryPath = [NSMutableString stringWithString:@"/"];
                        
                        [self.delegate fileTransferClient:self didConnectWithError:nil];
                    }
                    else if(request.code == DISCONNECT) {
                        NSLog(@"Disconnected from Bluetooth FTP Server.");
                        self.state = BBSyncFileTransferClientStateDisconnected;
                        
                        [self nextRequest];
                    }
                    else if(request.code == PUT) {
                        [self.delegate fileTransferClient:self didDeleteFile:self.tempFile error:nil];
                    }
                    else if(request.code == SET_PATH) {
                        OBEXFileTransferHeader *nameHeader = [request.headers objectForKey:[NSString stringWithFormat:@"%c",NAME]];
                        NSString *folderName = [[NSString alloc] initWithData:nameHeader.data encoding:NSUTF16BigEndianStringEncoding];
                        
                        // Update the current directory path based on request.
                        if((request.flags & BACKUP_FLAG) == BACKUP_FLAG) {
                            self.currentDirectoryPath = [NSMutableString stringWithString:[self.currentDirectoryPath stringByDeletingLastPathComponent]];
                        }
                        else if(!folderName || [folderName isEqualToString:@""]) {
                            self.currentDirectoryPath = [NSMutableString stringWithString:@"/"];
                        }
                        else {
                            [self.currentDirectoryPath appendString:[NSString stringWithFormat:@"%@/",folderName]];
                        }
                        
                        [self.delegate fileTransferClient:self didChangeFolder:folderName error:nil];
                    }
                    else if(request.code == GET) {
                        if(request.headers.count == 3) {
                            // Add the data to the temporary directory.
                            OBEXFileTransferHeader *header = [[response headers] objectForKey:[NSString stringWithFormat:@"%c" , END_OF_BODY]];
                            [self.directory appendData:header.data];
                            
                            // Parse the directory data to get the resulting folder listing to send to delegate.
                            OBEXFileTransferFolderListingParser *parser = [[OBEXFileTransferFolderListingParser alloc] init];
                            OBEXFileTransferFolderListing *listing = [parser parseData:self.directory];
                            
                            // Reset directory data.
                            [self.directory setLength:0];
                            
                            [self.delegate fileTransferClient:self didListFolder:listing error:nil];
                        }
                        else {
                            // Add the data to the temporary file and send to delegate.
                            OBEXFileTransferHeader *header = [[response headers] objectForKey:[NSString stringWithFormat:@"%c" , END_OF_BODY]];
                            [self.tempFile.data appendData:[header data]];
                            
                            [self.delegate fileTransferClient:self didGetFile:self.tempFile error:nil];
                        }
                    }
                    else if(request.code == ACTION) {
                        NSLog(@"Moved file to ERASED folder.");
                    }
                    else if(request.code == ABORT) {
                        NSLog(@"Succesful abort command.");
                        [self nextRequest];
                    }
                    break;
                case CONTINUE:
                    if(request.headers.count == 3) { // Retrieve directory.
                        OBEXFileTransferHeader *header = response.headers[[NSString stringWithFormat:@"%c" , BODY]];
                        [self.directory appendData:header.data];
                        [self enqueueRequest:request];
                    }
                    else { // Retrieve file.
                        OBEXFileTransferHeader * header = [[response headers] objectForKey:[NSString stringWithFormat:@"%c" , BODY]];
                        if(self.tempFile.data == nil) {
                            self.tempFile.data = [[NSMutableData alloc] init];
                        }
                        [self.tempFile.data appendData:[header data]];
                        [self enqueueRequest:request];
                    }
                    break;
                case FORBIDDEN:
                    error = [[NSError alloc] initWithDomain:kBBSyncFileTransferErrorDomain code:response.code userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"This operation could not be completed.", @"Error that is presented when the user requested action could not be completed.")}];
                    break;
                case BAD_GATEWAY:
                    error = [[NSError alloc] initWithDomain:kBBSyncFileTransferErrorDomain code:response.code userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"This operation could not be completed.", @"Error that is presented when the user requested action could not be completed.")}];
                    break;
                case INTERNAL_SERVER_ERROR:
                    error = [[NSError alloc] initWithDomain:kBBSyncFileTransferErrorDomain code:response.code userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"This operation could not be completed.", @"Error that is presented when the user requested action could not be completed.")}];
                    break;
                default:
                    error = [[NSError alloc] initWithDomain:kBBSyncFileTransferErrorDomain code:response.code userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"This operation could not be completed.", @"Error that is presented when the user requested action could not be completed.")}];
                    break;
            }
            
            // Send error to delegate.
            if(error && request.code == GET && response.code == FORBIDDEN) { // This is a work around when disconnecting and connecting really quick gives me a forbidden command when listing a directory.
                NSLog(@"Received FORBIDDEN response, trying the same request again.");
                error = nil;
                [self enqueueRequest:request];
            }
            else if(error) {
                NSLog(@"Problem occured with Bluetooth device. Response code: %X. Request code: %X", response.code, request.code);
                [self.delegate fileTransferClient:self didReceiveError:error];
            }
        }
    }
}

#pragma mark NSStreamDelegateEventExtensions

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