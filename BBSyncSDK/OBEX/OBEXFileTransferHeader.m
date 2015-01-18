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

#import "OBEXFileTransferHeader.h"
#import "OBEXFileTransferUtilities.h"

@interface OBEXFileTransferHeader()

- (void)calculateLength;

@end

@implementation OBEXFileTransferHeader

- (id)initWithIdentifier:(char)identifier body:(NSData *)body {
    if (self = [super init]) {
        _identifier = identifier;
        _data = body;
        [self calculateLength];
    }
    return self;
}

- (id)initWithIdentifier:(char)identifier name:(NSString *)name {
    if (self = [super init]) {
        self.identifier = identifier;
        
        // Add null terminating char to end of string        
        self.data = [[name stringByAppendingString:@"\0"] dataUsingEncoding:NSUTF16BigEndianStringEncoding];
        [self calculateLength];
    }
    return self;
}

- (id)initWithIdentifier:(char)identifier {
    if (self = [super init]) {
        _identifier = identifier;
        _data = nil;
        [self calculateLength];
    }
    return self;
}

- (NSData *)byteArray {
    NSMutableData *tempData = [[NSMutableData alloc] init];
    [tempData appendBytes:&_identifier length: 1];
    
    if (self.identifier != CONNECTION_ID) {
        [tempData appendData:[OBEXFileTransferUtilities lengthToBytes:self.length]];
    }
    if (self.data != nil && ![self.data isEqual:@""]) {
        [tempData appendData:self.data];
    }
    
    return tempData;
}

- (void)calculateLength {
    if (self.identifier == CONNECTION_ID) {
        self.length = 5;
    }
    else {
        self.length = 3;
        
        if(self.data) {
            self.length += self.data.length;
        }
    }
}

@end
