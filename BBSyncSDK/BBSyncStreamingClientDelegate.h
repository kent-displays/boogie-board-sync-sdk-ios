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
#import "BBSyncCaptureMessage.h"

@class BBSyncStreamingClient;

/**
 *  The delegate of a BBSyncStreamingClient object must adopt the
 *  BBSyncStreamingClientDelegate protocol. The methods provide an
 *  asynchronous callback for any messages that the Booige Board Sync reports
 *  from the streaming client.
 */
@protocol BBSyncStreamingClientDelegate <NSObject>

/**
 *  Asynchronous callback from the streaming server returning the UIBezier path
 *  objects. These paths can be directly used to draw to a canvas.
 *
 *  @param client The streaming client object that returned the paths.
 *  @param paths  Array of paths.
 */
- (void)streamingClient:(BBSyncStreamingClient *)client didReceivePaths:(NSArray *)paths;

/**
 *  Callback to inform the delegate that the erase button was pushed on the
 *  Sync.
 */
- (void)syncWasErased;

@optional

/**
 *  Asynchronous callback from streaming server returning the raw capture
 *  message.
 *
 *  @param client  The streaming client object that returned the message.
 *  @param message Capture message.
 */
- (void)streamingClient:(BBSyncStreamingClient *)client didReceiveCaptureMessage:(BBSyncCaptureMessage *)message;

@end