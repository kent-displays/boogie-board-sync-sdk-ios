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

static char const CONNECT = 0x80;
static char const DISCONNECT = 0x81;
static char const PUT = 0x82;
static char const GET = 0x83;
static char const SET_PATH = 0x85;
static char const ACTION = 0x86;
static char const SESSION = 0x87;
static char const ABORT = 0xFF;
static char const DEFAULT_FLAG = 0x00;
static char const DONT_CREATE_FOLDER_FLAG = 0x02;
static char const BACKUP_FLAG = 0x01;
static char const DEFAULT_CONSTANT = 0x00;
static char const OBEX_VERSION = 0x10;
static const unsigned char MAXIMUM_PACKET_SIZE[] = {0x0F, 0xFF};
static const unsigned char  OBEX_FTP_UUID[] = {0xF9, 0xEC, 0x7B, 0xC4, 0x95, 0x3C, 0x11, 0xD2, 0x98, 0x4E, 0x52, 0x54, 0x00, 0xDC, 0x9E, 0x09};
static const unsigned char  FOLDER_LISTING_TYPE[] = {0x78, 0x2D, 0x6F, 0x62, 0x65, 0x78, 0x2F, 0x66, 0x6F, 0x6C, 0x64, 0x65, 0x72, 0x2D, 0x6C, 0x69, 0x73, 0x74, 0x69, 0x6E, 0x67, 0x00};

typedef NS_ENUM(char, BTFtpAction) {
    BTFtpActionCopy = 0x00,
    BTFtpActionMoveRename = 0x01,
    BTFtpActionSetPermissions = 0x02
};

typedef NS_ENUM(char, BTFtpRequestState) {
    BTFtpRequestStateReady,
    BTFtpRequestStateProcessing,
    BTFtpRequestStateCanceled,
    BTFtpRequestStateDone
};

@interface OBEXFileTransferRequest : NSObject

@property (nonatomic) char code;
@property (nonatomic) char version;
@property (nonatomic) char flags;
@property (nonatomic) char constants;
@property (nonatomic) NSMutableDictionary *headers;
@property (nonatomic) NSUInteger length;
@property (nonatomic) NSData *maxSize;
@property (nonatomic) int state;

- (id)initWithOpCode:(char)opCode;
- (void)addHeader:(OBEXFileTransferHeader *)header;
- (NSData *)byteArray;
@end
