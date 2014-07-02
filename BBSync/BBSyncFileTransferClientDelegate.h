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
#import "OBEXFileTransferFolderListing.h"
#import "OBEXFileTransferFile.h"

@class BBSyncFileTransferClient;

/**
 *  The delegate of a BBSyncFileTransferClient object must adopt the
 *  BBSyncFileTransferClientDelegate protocol. The optional methods provide an
 *  asynchronous callback for any reqeust sent to the file transfer client.
 */
@protocol BBSyncFileTransferClientDelegate <NSObject>

@optional

/**
 *  Asynchronous callback when requesting a file from the file transfer client
 *  with getFile:. If error is present then file will be nil.
 *
 *  @param client The file transfer client object that returned the reponse.
 *  @param file File object.
 *  @param error An error object detailing why the getFile: request failed.
 */
- (void)fileTransferClient:(BBSyncFileTransferClient *)client didGetFile:(OBEXFileTransferFile *)file error:(NSError *)error;

/**
 *  Asynchronous callback when requesting a folder listing from the file
 *  transfer client with listFolder. If an error is present then the folder
 *  listing oject will be nil.
 *
 *  @param client The file transfer client object that returned the reponse.
 *  @param file Folder listing object.
 *  @param error An error object detailing why the listFolder request failed.
 */
- (void)fileTransferClient:(BBSyncFileTransferClient *)client didListFolder:(OBEXFileTransferFolderListing *)folderListing error:(NSError *)error;

/**
 *  Asynchronous callback when requesting to delete file from the file transfer
 *  client with deletFile:. If error is present then file will be nil.
 *
 *  @param client The file transfer client object that returned the reponse.
 *  @param file File object.
 *  @param error An error object detailing why the deletFile: request failed.
 */
- (void)fileTransferClient:(BBSyncFileTransferClient *)client didDeleteFile:(OBEXFileTransferFile *)file error:(NSError *)error;

/**
 *  Asynchronous callback when requesting a change folder from the file transfer
 *  client with changeFolder:. If error is present then folder will be nil.
 *
 *  @param client The file transfer client object that returned the reponse.
 *  @param folder Name of the folder.
 *  @param error An error object detailing why the changeFolder: request failed.
 */
- (void)fileTransferClient:(BBSyncFileTransferClient *)client didChangeFolder:(NSString *)folder error:(NSError *)error;

/**
 *  Asynchronous callback when requesting a connection to the file transfer
 *  client with connect.
 *
 *  @param client The file transfer client object that returned the reponse.
 *  @param error An error object detailing why the connect request failed.
 */
- (void)fileTransferClient:(BBSyncFileTransferClient *)client didConnectWithError:(NSError *)error;

/**
 *  Callback when an error is received, but is not in response to a previous
 *  request.
 *
 *  @param client The file transfer client object that returned the reponse.
 *  @param error An error object detailing why the connect request failed.
 */
- (void)fileTransferClient:(BBSyncFileTransferClient *)client didReceiveError:(NSError *)error;

@end
