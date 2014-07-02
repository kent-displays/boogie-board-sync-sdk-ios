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

#import "HIDDataMessage.h"

/**
 *  Constant for the maximum X value that a capture message will return.
 */
extern float const kBBSyncCaptureMessageMaxX;

/**
 *  Constant for the maximum Y value that a capture message will return.
 */
extern float const kBBSyncCaptureMessageMaxY;

/**
 *  These constants indicate the type of report returned from the streaming
 *  server.
 */
typedef NS_ENUM(char, BBSyncCaptureMessageReportId) {
    /**
     *  This is not implemented in iOS and should never be used.
     */
    BBSyncCaptureMessageReportIdDigitizer = 0x02,
    /**
     *  Indicates that the report is a data capture.
     */
    BBSyncCaptureMessageReportIdDataCapture = 0x03
};

/**
 *  The 'BBSyncCaptureMessage' class is a subclass of HIDDataMessage that
 *  supports the custom capture message returned from the Boogie Board Sync's
 *  streaming server.
 *
 *  Class also offers convienence methods to quickly check the flags sent along
 *  in the message.
 */
@interface BBSyncCaptureMessage : HIDDataMessage

/**-----------------------------------------------------------------------------
 * @name Properties
 * -----------------------------------------------------------------------------
 */

/**
 *  Integer value for the x coordinate.
 */
@property (nonatomic, readonly) NSUInteger x;

/**
 *  Integer value for the y coordinate.
 */
@property (nonatomic, readonly) NSUInteger y;

/**
 *  Integer value for pressure.
 */
@property (nonatomic, readonly) NSUInteger pressure;

/**
 *  Char inidicating the flags for the message.
 */
@property (nonatomic, readonly) char flags;

/**-----------------------------------------------------------------------------
 * @name Initialization
 * -----------------------------------------------------------------------------
 */

/**
 *  Initializer that creates a BBSyncCaptureMessage based on the report id and
 *  the raw data returned from the streaming server.
 *
 *  @param reportId    BBSyncCaptureMessagesReportId
 *  @param captureData raw data to parse out contents of the capture message.
 *
 *  @return initialized capture message.
 */
- (id)initWithReportId:(char)reportId captureData:(NSData *)captureData;

/**-----------------------------------------------------------------------------
 * @name Identifying Flags
 * -----------------------------------------------------------------------------
 */

/**
 *  Returns a Boolean value that indicates if the capture message contains a
 *  save flag.
 *
 *  @return YES if the capture message has a save flag, otherwise NO.
 */
- (BOOL)hasSaveFlag;

/**
 *  Returns a Boolean value that indicates if the capture message contains a
 *  save switch flag.
 *
 *  @return YES if the capture message has a save switch flag, otherwise NO.
 */
- (BOOL)hasSaveSwitchFlag;

/**
 *  Returns a Boolean value that indicates if the capture message contains an
 *  erase flag.
 *
 *  @return YES if the capture message has an erase flag, otherwise NO.
 */
- (BOOL)hasEraseFlag;

/**
 *  Returns a Boolean value that indicates if the capture message contains an
 *  erase switch flag.
 *
 *  @return YES if the capture message has an erase switch flag, otherwise NO.
 */
- (BOOL)hasEraseSwitchFlag;

/**
 *  Returns a Boolean value that indicates if the capture message contains a
 *  ready flag.
 *
 *  @return YES if the capture message has a ready flag, otherwise NO.
 */
- (BOOL)hasReadyFlag;

/**
 *  Returns a Boolean value that indicates if the capture message contains a
 *  barrel switch flag.
 *
 *  @return YES if the capture message has a barrel switch flag, otherwise NO.
 */
- (BOOL)hasBarrelSwitchFlag;

/**
 *  Returns a Boolean value that indicates if the capture message contains a
 *  tip switch flag.
 *
 *  @return YES if the capture message has a tip switch flag, otherwise NO.
 */
- (BOOL)hasTipSwitchFlag;

@end
