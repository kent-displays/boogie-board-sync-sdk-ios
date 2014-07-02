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

#import "OBEXFileTransferRequest.h"
#import "OBEXFileTransferUtilities.h"

@interface OBEXFileTransferRequest ()

@end

@implementation OBEXFileTransferRequest

- (id)initWithOpCode:(char)opCode {
    if (self = [super init]) {
        _length = -1;
        _code = opCode;
        _headers = [[NSMutableDictionary alloc] init];
        _state = BTFtpRequestStateReady;
    }
    return self;
}

- (void)addHeader:(OBEXFileTransferHeader *)header {
    [self.headers setObject:header forKey:[NSString stringWithFormat:@"%c", header.identifier]];
}

- (NSData *)byteArray {
    NSMutableData *tempData = [[NSMutableData alloc] init];
    [self calculatePacketLength];
    if(self.length == -1) {
        return nil;
    }
    else {
        [tempData appendBytes:&_code length:1];
    }
        
    [tempData appendData:[OBEXFileTransferUtilities lengthToBytes:self.length]];
    if (self.code == CONNECT) {
        [tempData appendBytes:&_version length:1];
        [tempData appendBytes:&_flags length:1];
        [tempData appendData:self.maxSize];
    }
    
    if (self.code == SET_PATH) {
        [tempData appendBytes:&_flags length:1];
        [tempData appendBytes:&_constants length:1];
    }
    
    // Since NSDictionary is not ordered the connection id needs to be added first then the other headers.
    OBEXFileTransferHeader *connectionIdHeader = [self.headers objectForKey:[NSString stringWithFormat:@"%c",CONNECTION_ID]];
    if(connectionIdHeader != nil) {
        [tempData appendData:[connectionIdHeader byteArray]];
    }
    
    for (NSString *key in self.headers) {
        if(![key isEqualToString:[NSString stringWithFormat:@"%c",CONNECTION_ID]]) {
            [tempData appendData:[[self.headers objectForKey:key] byteArray]];
        } 
    }

    return tempData;
}

- (void)calculatePacketLength {
    // One for operation code and two for the packet length.
    self.length = 3;
    
    if (self.code == CONNECT) {
        self.length += 4;
    }
    else if (_code == SET_PATH) {
        self.length += 2;
    }

    for(NSString *key in self.headers) {
        self.length += [[self.headers objectForKey:key] length];
    }
}

@end
