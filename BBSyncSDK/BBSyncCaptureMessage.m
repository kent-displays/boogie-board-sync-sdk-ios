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

#import "BBSyncCaptureMessage.h"

#define SW_ERASE_FLAG (1 << 7)
#define SW_SAVE_FLAG (1 << 6)
#define ERASE_FLAG (1 << 5)
#define SAVE_FLAG (1 << 4)
#define RDY_FLAG (1 << 2)
#define BSW_FLAG (1 << 1)
#define TSW_FLAG 0x01

float const kBBSyncCaptureMessageMaxX = 20280.0f;
float const kBBSyncCaptureMessageMaxY = 13942.0f;

@interface BBSyncCaptureMessage()

@end

@implementation BBSyncCaptureMessage

- (id)initWithReportId:(char)reportId captureData:(NSData *)captureData {
    self = [super initWithChannel:HIDMessageChannelControl reportType:HIDDataMessageTypeInput reportId:reportId payload:captureData];
    if(self) {
        const unsigned char *bytes = [captureData bytes];
        // Next two bytes are the x coordinate from 0 to 20280
        _x = (unsigned int)bytes[0];
        _x += (unsigned int)bytes[1] << 8;
        
        // Next two bytes are the y coordinate from 0 to 13942
        _y = (unsigned int)bytes[2];
        _y += (unsigned int)bytes[3] << 8;
        
        // Next two bytes are the pressure from 0 to 1023.
        _pressure = (unsigned int)bytes[4];
        _pressure += (unsigned int)bytes[5] << 8;
        
        // Next byte contains the flags.
        _flags = (int)bytes[6];
    }
    return self;
}

- (BOOL)hasSaveFlag {
    return (self.flags & SAVE_FLAG) == SAVE_FLAG;
}

- (BOOL)hasEraseFlag {
    return (self.flags & ERASE_FLAG) == ERASE_FLAG;
}

- (BOOL)hasEraseSwitchFlag {
    return (self.flags & SW_ERASE_FLAG) == SW_ERASE_FLAG;
}

- (BOOL)hasSaveSwitchFlag {
    return (self.flags & SW_SAVE_FLAG) == SW_SAVE_FLAG;
}

- (BOOL)hasReadyFlag {
    return (self.flags & RDY_FLAG) == RDY_FLAG;
}

- (BOOL)hasBarrelSwitchFlag {
    return (self.flags & BSW_FLAG) == BSW_FLAG;
}

- (BOOL)hasTipSwitchFlag {
    return (self.flags & TSW_FLAG) == TSW_FLAG;
}

@end
