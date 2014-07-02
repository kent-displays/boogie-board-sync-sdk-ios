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

/**
 *  The 'BBFiltering' class provides the neccessary methods to convert the raw
 *  data from a Boogie Board Sync digitizer into Cocoa/Cocoa Touch objects
 *  which can be used for drawing to a canvas.
 */
@interface BBFiltering : NSObject

/**-----------------------------------------------------------------------------
 * @name Filtering Paths 
 * -----------------------------------------------------------------------------
 */

/**
 *  Returns an array of either UIBezierPath or NSBezierPath depending on the 
 *  corresponding device. The array may contain anywhere from 0 to 4 objects.
 *
 *  @param captureMessage Capture message returned from a Boogie Board Sync.
 *
 *  @return Array of paths.
 */
+ (NSArray *)filteredPathsForCaptureMessage:(BBSyncCaptureMessage *)captureMessage;

@end
