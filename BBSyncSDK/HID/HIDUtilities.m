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

#import "HIDUtilities.h"
#import "HIDMessage.h"
#import "HIDHandshake.h"
#import "HIDGetReport.h"
#import "HIDDataMessage.h"
#import "BBSyncCaptureMessage.h"

char const FEND = 0xC0;
char const FESC = 0xDB;
char const TFEND = 0xDC;
char const TFESC = 0xDD;
#define POLY 0x8408

@implementation HIDUtilities

+ (NSData *)removeEscapeFromData:(NSData *)data {
    const char *bytes = [data bytes];
    NSMutableData *unescapedData = [[NSMutableData alloc] init];
    if (data) {
        // Take out all the escape sequences in the data.
        for(int i=0; i< [data length]; i++){
            char currentByte = bytes[i];
            
            if(currentByte == FEND && i ==0)
                continue;
            else if(currentByte == FEND && i+1 == [data length])
                break;
            else if(currentByte == FESC) {
                currentByte = bytes[++i];
                if(currentByte == TFEND)
                    currentByte = FEND;
                else if(currentByte ==TFESC)
                    currentByte = FESC;
            }            
            [unescapedData appendBytes:&currentByte length:1];
        }
    }
    return unescapedData;
}

+ (NSData *)escapeData:(NSData *)data {
    const char *bytes = [data bytes];
    NSMutableData *escapedData = [[NSMutableData alloc] init];
    if (data) {
        // Take out all the escape sequences in the data.
        for(int i=0; i< [data length]; i++){
            char currentByte = bytes[i];
            
            if(currentByte == FESC && i != 0 && i+1 != [data length]) {
                [escapedData appendBytes:&FESC length:1];
                [escapedData appendBytes:&TFEND length:1];
                continue;
            } else if(currentByte == FESC) {
                [escapedData appendBytes:&FESC length:1];
                [escapedData appendBytes:&TFESC length:1];
                continue;
            }
            [escapedData appendBytes:&currentByte length:1];
        }
    }
    return escapedData;
}

+ (unsigned short)CRC8OnData:(NSData *)data {
    unsigned short crc = 0xffff;
    NSUInteger length = [data length];
    const char *bufp = [data bytes];
    NSUInteger len;
    static unsigned short lotab[16] = {
        0x0000, 0x1189, 0x2312, 0x329b, 0x4624, 0x57ad, 0x6536, 0x74bf,
        0x8c48, 0x9dc1, 0xaf5a, 0xbed3, 0xca6c, 0xdbe5, 0xe97e, 0xf8f7,
    };
    static unsigned short hitab[16] = {
        0x0000, 0x1081, 0x2102, 0x3183, 0x4204, 0x5285, 0x6306, 0x7387,
        0x8408, 0x9489, 0xa50a, 0xb58b, 0xc60c, 0xd68d, 0xe70e, 0xf78f,
    };
    for (len = length; len > 0; len--) {
        unsigned char ch = *bufp++ ^ crc;
        crc = (crc >> 8) ^ lotab[ch&0xf] ^ hitab[(ch&0xf0) >> 4];
    }
    return crc;
}

+ (NSData *)framedData:(NSData *)data {
    // Generate CRC.
    unsigned short crc = [HIDUtilities CRC8OnData:data];
    
    // Frame the data and create the packet to be returned.
    NSMutableData *packet = [[NSMutableData alloc] init];
    [packet appendBytes:&FEND length:1];
    [packet appendData:data];
    [packet appendBytes:&crc length:2];
    [packet appendBytes:&FEND length:1];
    
    return packet;
}

+ (NSArray *)parsedMessagesFromData:(NSData *)data {
    NSMutableArray *messages = [NSMutableArray new];
    
    if(data) {
        char const *bytes = [data bytes];
        NSMutableData *unescapedData = [[NSMutableData alloc] init];
    
        // Remove all escape sequences in the data.
        for(int i=0; i < data.length; i++) {
            char currentByte = bytes[i];
            
            if(currentByte == FEND && i ==0) {
                continue;
            }
            else if(currentByte == FEND && i != 0) {
                if(unescapedData.length >= 4) {
                    if([HIDUtilities CRC8OnData:unescapedData] == 0){
                        // Get the byte array as well as remove the CRC from the end of the packet.
                        NSData *cleanData = [unescapedData subdataWithRange:NSMakeRange(0, unescapedData.length-2)];
                        char const *cleanBytes = [cleanData bytes];
                        char channel = cleanBytes[0];
                        char type = (cleanBytes[1] & 0xF0) >> 4;
                        char parameter = cleanBytes[1] & 0x0F;
                        char report = cleanBytes[2];
                        
                        switch(channel) {
                            case HIDMessageChannelControl:
                                if(type == HIDMessageTypeHandshake) {
                                    [messages addObject:[[HIDHandshake alloc] initWithResultCode:parameter]];
                                }
                                else if(type == HIDMessageTypeData) {
                                    // Returned data messages from the Sync are from a requested get report.
                                    // These get reports add an extra two bytes for satisfying other systems.
                                    // Make sure to remove these two bytes.
                                    NSData *payload = [cleanData subdataWithRange:NSMakeRange(5, cleanData.length - 5)];
                                    [messages addObject:[[HIDDataMessage alloc] initWithChannel:channel reportType:parameter reportId:report payload:payload]];
                                }
                                break;
                            case HIDMessageChannelInterrupt:
                                if(type == HIDMessageTypeData) {
                                    NSData *payload = [cleanData subdataWithRange:NSMakeRange(3, cleanData.length - 3)];
                                    if(report == BBSyncCaptureMessageReportIdDataCapture || report == BBSyncCaptureMessageReportIdDigitizer) {
                                        [messages addObject:[[BBSyncCaptureMessage alloc] initWithReportId:report captureData:payload]];
                                    }
                                    else {
                                        [messages addObject:[[HIDDataMessage alloc] initWithChannel:channel reportType:parameter reportId:report payload:payload]];
                                    }
                                }
                                else {
                                    [messages addObject:[[HIDMessage alloc] initWithType:type channel:channel parameter:parameter]];
                                }
                                break;
                            default:
                                break;
                        }
                    }
                    else {
                        NSLog(@"CRC check failed.");
                    }
                    [unescapedData setLength:0];
                }
                continue;
            }
            else if(currentByte == FESC) {
                currentByte = bytes[++i];
                if(currentByte == TFEND) {
                    currentByte = FEND;
                }
                else if(currentByte ==TFESC) {
                    currentByte = FESC;
                }
            }
            
            [unescapedData appendBytes:&currentByte length:1];
        }
    }
    return messages;
}

@end
