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
#import "BBSyncFileTransferClientDelegate.h"
#import "OBEXFileTransferFolderListing.h"
#import "BBSessionController.h"
#import "OBEXFileTransferResponse.h"
#import "OBEXFileTransferFile.h"

/**
 *  These contansts indicate the the state of the file transfer client.
 */
typedef NS_ENUM(NSInteger, BBSyncFileTransferClientState) {
    /**
     *  Indicates the client is disconnected.
     */
    BBSyncFileTransferClientStateDisconnected,
    /**
     *  Indicates the client is disconnecting.
     */
    BBSyncFileTransferClientStateDisconnecting,
    /**
     *  Indicates the client is connecting.
     */
    BBSyncFileTransferClientStateConnecting,
    /**
     *  Indicates the client is connected.
     */
    BBSyncFileTransferClientStateConnected
};

/**
 *  Constant to be used when returning errors from the file transfer client.
 */
extern NSString * const kBBSyncFileTransferErrorDomain;

/**
 *  The 'BBSyncFileTransferClient' class facilitates in communicating with a
 *  Boogie Board Sync through a file transfer protocol based on OBEX File
 *  Transfer. The use of this client allows for files to be downloaded, deleted
 *  and listed on a Sync.
 *  
 *  @warning Before trying to make requests, the BBSessionController must first
 *  be set up.
 *
 *  The connection must first be made to the file transfer server before
 *  executing any other requests. Do this by calling connect and wait for the
 *  delegate's didConnect: to be called.
 *
 *  Once finished with the file transfer client, remember to call disconnect.
 */
@interface BBSyncFileTransferClient : NSObject

/**-----------------------------------------------------------------------------
 * @name Accessing the File Transfer Client Instance
 * -----------------------------------------------------------------------------
 */

/**
 *  Returns the shared `BBSyncFileTransferClient` instance, creating it if
 *  necessary.
 *
 *  @return The shared `BBSyncFileTransferClient` instance.
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
 * @name Connecting and Disconnecting
 * -----------------------------------------------------------------------------
 */

/**
 *  Sends a connection request to the Sync's file transfer server. This is an
 *  asynchronous call.
 *  
 *  @warning The session must first be setup with createSessionWithAccessory:.
 */
- (void)connect;

/**
 *  Sends a disconnection request to the Sync's file transfer server. This is an
 *  asynchronous call.
 */
- (void)disconnect;

/**-----------------------------------------------------------------------------
 * @name Manipulating File Structure
 * -----------------------------------------------------------------------------
 */

/**
 *  Sends a get file request to the Sync's file transfer server to retrieve the
 *  specified file. This is an asynchronous call.
 *  
 *  @param file File object to be retrieved.
 */
- (void)getFile:(OBEXFileTransferFile *)file;

/**
 *  Sends a delete file request to the Sync's file transfer server to delete the
 *  specified file. This is an asynchronous call.
 *
 *  @param file File object to be deleted.
 */
- (void)deleteFile:(OBEXFileTransferFile *)file;

/**
 *  Sends a list folder request to the Sync's file transfer server. This is an
 *  asynchronous call.
 */
- (void)listFolder;

/**
 *  Sends a root folder request to the Sync's file transfer server. This is an
 *  asynchronous call.
 */
- (void)rootFolder;

/**
 *  Sends a change folder request to the Sync's file transfer server to change
 *  to the specified folder. This is an asynchronous call.
 *
 *  @param file Name of the folder to change to.
 */
- (void)changeFolder:(NSString *)folder;

/**
 *  Sends an abort request to the Sync's file transfer server. This is an
 *  asynchronous call.
 *
 *  This is very useful when no longer needing to list a folder directory or get
 *  a file.
 */
- (void)abort;

/**-----------------------------------------------------------------------------
 * @name Managing the Delegate
 * -----------------------------------------------------------------------------
 */

/**
 *  The object that acts as the delegate of the file transfer object.
 */
@property (weak) id<BBSyncFileTransferClientDelegate> delegate;

/**-----------------------------------------------------------------------------
 * @name Getting State Information
 * -----------------------------------------------------------------------------
 */

/**
 *  Current state of the file transfer client.
 */
@property (nonatomic, readonly) BBSyncFileTransferClientState state;

/**
 *  String representation of the current directory path.
 */
@property (nonatomic, readonly) NSMutableString *currentDirectoryPath;

@end
