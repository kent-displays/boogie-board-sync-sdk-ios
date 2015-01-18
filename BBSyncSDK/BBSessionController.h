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

#import <ExternalAccessory/ExternalAccessory.h>

/**
 *  Posted when a Boogie Board Sync becomes connected and available for your
 *  application to use.
 *  The notification object is the session controller. The userInfo dictionary
 *  contains an BBSessionControllerAccessoryKey, whose value is an EAAccessory 
 *  object representing the accessory that is now connected.
 */
extern NSString * const BBSessionControllerDidConnect;

/**
 *  Posted when a Boogie Baord Sync is disconnected and no longer available for
 *  your application to use.
 *  The notification object is the shared accessory manager. The userInfo 
 *  dictionary contains an BBSessionControllerAccessoryKey, whose value is the
 *  EAAccessory object representing the accessory that was disconnected.
 */
extern NSString * const BBSessionControllerDidDisconnect;

/**	
 *  The value assigned to this key is the EAAccessory object that conntected or
 *  disconnected from the iOS device.
 */
extern NSString * const BBSessionControllerAccessoryKey;

/**
 *  The 'BBSessionController' class automatically manages the connection to a
 *  Boogie Board Sync. This includes setting up and tearing down connections.
 *
 *  Provides notifications for the connection and disconnection of a Sync.
 *
 *  @warning sharedController must be called during
 *  application:didFinishLaunchingWithOptions: to ensure controller is set up to
 *  find currently connected devices at launch.
 */
@interface BBSessionController : NSObject <EAAccessoryDelegate>

/**-----------------------------------------------------------------------------
 * @name Getting Connection Information
 * -----------------------------------------------------------------------------
 */

/**
 *  A Boolean value indicating whether the Boogie Board Sync is currently
 *  connected to the iOS-based device. (read-only)
 */
@property (nonatomic, readonly, getter = isConnected) BOOL connected;

/**
 *  Accessory object corresponding to the connected Boogie Board Sync, nil if no
 *  Sync is connected. (read-only)
 */
@property (readonly, nonatomic) EAAccessory *accessory;

/**-----------------------------------------------------------------------------
 * @name Accessing the Session Controller Instance
 * -----------------------------------------------------------------------------
 */

/**
 *  Returns the shared `BBSessionController` instance, creating it if necessary.
 *
 *  @return The shared `BBSessionController` instance.
 */
+ (instancetype)sharedController;

@end
