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

#import "BBSessionController.h"
#import "BBSyncStreamingClientDelegate.h"

/**
 *  These constants indicate the mode of the steaming client.
 */
typedef NS_ENUM(char, BBSyncMode) {
    /**
     *  Indicates the Sync will report no information.
     */
    BBSyncModeNone = 0x01,
    /**
     *  Indicates the Sync will report all raw information.
     */
    BBSyncModeCapture = 0x04,
    /**
     *  Indicates the Sync will report when a file was saved.
     */
    BBSyncModeFile = 0x05
};

/**
 *  Posted when a Boogie Baord Sync completed a save.
 *  The notification object is the shared streaming client.
 */
extern NSString * const BBSyncStreamingClientDidSave;

/**
 *  The 'BBSyncStreamingClient' class facilitates in communicating with a
 *  Boogie Board Sync through a custom data capture protocl based on HID. The
 *  use of this client allows for real time information including paths drawn,
 *  button pushes and raw data reports.
 *  
 *  When the stremaing client is first set up it will be put into
 *  BBSyncModeCapture. If no reporting is required then it is encourgaged to put
 *  the streaming server into BBSyncModeNone. Lastly, if drawn paths are
 *  required then the streaming server must be put into BBSyncModeCapture.
 *
 *  @warning Before trying to make requests, the BBSessionController must first
 *  be set up.
 *
 */
@interface BBSyncStreamingClient : NSObject

/**-----------------------------------------------------------------------------
 * @name Accessing the Streaming Client Instance
 * -----------------------------------------------------------------------------
 */

/**
 *  Returns the shared `BBSyncStreamingClient` instance, creating it if
 *  necessary.
 *
 *  @return The shared `BBSyncStreamingClient` instance.
 */
+ (instancetype)sharedClient;

/**-----------------------------------------------------------------------------
 * @name Managing Session
 * -----------------------------------------------------------------------------
 */

/**
 *  Initializes a connection with the corresponding accessory. Sets up the input
 *  and output stream for communication.
 *
 *  @param accessory Accessory object to initiate the session with.
 */
- (void)createSessionWithAccessory:(EAAccessory *)accessory;

/**
 *  Closes the current session if one exists.
 */
- (void)closeSession;

/**-----------------------------------------------------------------------------
 * @name Manipulating Sync
 * -----------------------------------------------------------------------------
 */

/**
 *  Sends a request to the streaming server to erase the display on the Sync.
 */
- (void)eraseSync;

/**
 *  Sends a request to put the Sync into the corresponding mode.
 *
 *  @param mode Mode to put Sync into.
 */
- (void)setSyncMode:(BBSyncMode)mode;

/**-----------------------------------------------------------------------------
 * @name Managing the Delegate
 * -----------------------------------------------------------------------------
 */

/**
 *  The object that acts as the delegate of the file transfer object.
 */
@property (nonatomic, weak) id<BBSyncStreamingClientDelegate> delegate;

/**-----------------------------------------------------------------------------
 * @name Getting State Information
 * -----------------------------------------------------------------------------
 */

/**
 *  Current paths drawn on the Sync screen.
 *  
 *  @warning This property is only up to date when the current Sync mode is
 *  BBSyncModeCapture.
 */
@property (nonatomic, readonly) NSMutableArray *paths;

@end
