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

#import <Foundation/Foundation.h>

static const char TARGET = 0x46;
static const char CONNECTION_ID = 0xCB;
static const char NAME = 0x01;
static const char DEST_NAME = 0x015;
static const char TYPE = 0x42;
static const char WHO = 0x4A;
static const char BODY = 0x48;
static const char END_OF_BODY = 0x49;
static const char LENGTH = 0xC3;
static const char DESCRIPTION = 0x05;

@interface OBEXFileTransferHeader : NSObject

@property NSUInteger length;
@property NSData *data;
@property char identifier;

- (id)initWithIdentifier:(char)identifier;
- (id)initWithIdentifier:(char)identifier body:(NSData *)body;
- (id)initWithIdentifier:(char)identifier name:(NSString *)name;
- (NSData *)byteArray;

@end
