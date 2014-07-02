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

#import "HIDSetReport.h"
#import "HIDUtilities.h"

@implementation HIDSetReport

- (id)initWithReportType:(char)reportType reportId:(char)reportId payload:(NSData *)payload {
    self = [super initWithType:HIDMessageTypeSetReport channel:HIDMessageChannelControl parameter:reportType];
    if(self) {
        _reportType = reportType;
        _reportId = reportId;
        _payload = payload;
    }
    return self;
}

#pragma mark - Public methods

- (NSData *)framedData {
    NSMutableData *data = [NSMutableData new];
    const unsigned char initialBytes[] = {self.channel, self.header, self.reportId, self.reportId, 0x00};
    [data appendBytes:initialBytes length:sizeof(initialBytes)];
    if(self.payload) {
        [data appendData:self.payload];
    }
    return [HIDUtilities framedData:data];
}

@end
