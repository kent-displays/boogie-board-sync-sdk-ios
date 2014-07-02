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

#import "OBEXFileTransferResponse.h"
#import "OBEXFileTransferUtilities.h"
#import "OBEXFileTransferHeader.h"

@implementation OBEXFileTransferResponse

- (id)initWithData:(NSData *)data {
    if (self = [super init]) {
        _length = -1;
        _maxLength = -1;
        _headers = [NSMutableDictionary dictionaryWithCapacity:10];
        _data = data;
        [self parseResponse];
    }
    return self;
}

- (void)parseResponse {   
    NSInteger currentIndex = 3;
    [self.data getBytes:&_code length:1];
    self.length = [OBEXFileTransferUtilities getLength:[self.data subdataWithRange:NSMakeRange(1, 2)]];
    
    if (self.length > 3) {
        
        char temp;
        [self.data getBytes:&temp range:NSMakeRange(3, 1)];
        
        // Weak condition to check if it was a connection response.
        if (temp == 16) {
            [self.data getBytes:&_version range:NSMakeRange(3, 1)];
            [self.data getBytes:&_flag range:NSMakeRange(4, 1)];
            self.maxLength = [OBEXFileTransferUtilities getLength:[self.data subdataWithRange:NSMakeRange(5, 2)]];
            currentIndex = 7;
        }
        
        // Loop until the whole packet has been parsed.
        while (currentIndex < self.data.length) {
            char identifier;
            NSInteger headerLength;
            OBEXFileTransferHeader *temp;
            
            // Get the header id and header length.
            [self.data getBytes:&identifier range:NSMakeRange(currentIndex, 1)];
            headerLength = [OBEXFileTransferUtilities getLength:[self.data subdataWithRange:NSMakeRange(currentIndex + 1, 2)]];            
            
            // Format the headerId as a NSString to use with a NSDictionary.
            NSString* key = [NSString stringWithFormat:@"%c" , identifier];
            
            // This is needed because Connection Id and Length headers have no length attribute.
            if (identifier == CONNECTION_ID || identifier == LENGTH) {
                temp = [[OBEXFileTransferHeader alloc] initWithIdentifier:identifier body:[self.data subdataWithRange:NSMakeRange(currentIndex + 1, 4)]];
                currentIndex += 5;
            }
            // Take care of a regular header that has a length corresponding to it.
            else {
                temp = [[OBEXFileTransferHeader alloc] initWithIdentifier:identifier body:[self.data subdataWithRange:NSMakeRange(currentIndex + 3, headerLength - 3)]];
                currentIndex += headerLength;
            }      
            // Add the header to the dictionary.
            [self.headers setObject:temp forKey:key];
        }        
    }
}

@end
