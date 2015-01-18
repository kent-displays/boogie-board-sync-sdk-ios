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

static char const CONTINUE = 0x90;
static char const SUCCESS = 0xA0;
static char const CREATED = 0xA1;
static char const ACCEPTED = 0xA2;
static char const MULTIPLE_CHOICES = 0xB0;
static char const MOVED_PERMANENTLY = 0xB1;
static char const MOVED_TEMPORARILY = 0xB2;
static char const SEE_OTHER = 0xB3;
static char const NOT_MODIFIED = 0xB4;
static char const USE_PROXY = 0xB5;
static char const BAD_REQUEST = 0xC0;
static char const UNAUTHORIZED = 0xC1;
static char const FORBIDDEN = 0xC3;
static char const NOT_FOUND = 0xC4;
static char const METHOD_NOT_ALLOWED = 0xC5;
static char const NOT_ACCEPTABLE = 0xC6;
static char const PROXY_AUTHENTICATION_REQUIRED = 0xC7;
static char const REQUEST_TIME_OUT = 0xC8;
static char const CONFLICT = 0xC9;
static char const GONE = 0xCA;
static char const LENGTH_REQUIRED = 0xCB;
static char const PRECONDITION_FAILED = 0xCC;
static char const REQUEST_ENTITY_TOO_LARGE = 0xCD;
static char const REQUEST_URL_TOO_LARGE = 0xCE;
static char const UNSUPPORTED_MEDIA_TYPE = 0xCF;
static const char INTERNAL_SERVER_ERROR = 0xD0;
static char const NOT_IMPLEMENTED = 0xD1;
static char const BAD_GATEWAY = 0xD2;
static char const SERVICE_UNAVAILABLE = 0xD3;
static char const GATEWAY_TIMEOUT = 0xD4;
static char const HTTP_VERSION_NOT_SUPPORTED = 0xD5;
static char const DATABASE_FULL = 0xE0;
static char const DATABASE_LOCKED = 0xE1;

@interface OBEXFileTransferResponse : NSObject

@property(nonatomic, retain) NSData *data;
@property(nonatomic, retain) NSMutableDictionary *headers;
@property(nonatomic, assign) NSInteger length;
@property(nonatomic, assign) NSInteger maxLength;
@property(nonatomic, readonly) char code;
@property(nonatomic, readonly) char version;
@property(nonatomic, readonly) char flag;

- (id)initWithData:(NSData *)data;
@end
