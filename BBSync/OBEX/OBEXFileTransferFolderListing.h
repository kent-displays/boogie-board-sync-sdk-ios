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

#import "OBEXFileTransferFile.h"
#import "OBEXFileTransferFolder.h"

/**
 *  The 'OBEXFileTransferFolderListing' class is a representation of the xml
 *  based response that the file transfer server returns for a folder listing
 *  request.
 */
@interface OBEXFileTransferFolderListing : NSObject

/**
 *  Array of files that are contained in the folder listing.
 */
@property (nonatomic) NSMutableArray *files;

/**
 *  Array of folders that are contained in the folder listing.
 */
@property (nonatomic) NSMutableArray *folders;

/**
 *  Orders the files/folders by the modified date in either ascending or 
 *  descending order.
 */
@property (nonatomic) BOOL descending;

/**
 *  Adds an OBEXFileTransferFile object to the folder listing.
 *
 *  @param file File to be added to the folder listing.
 */
- (void)addFile:(OBEXFileTransferFile *)file;

/**
 *  Adds an OBEXFileTransferFolder object to the folder listing.
 *
 *  @param folder Folder to be added to the folder listing.
 */
- (void)addFolder:(OBEXFileTransferFolder *)folder;

/**
 *  Returns the total number of files and folders in the folder listing.
 *
 *  @return Integer for the count of files and folders.
 */
- (NSUInteger)count;

/**
 *  Returns the OBEXFileTransferItem at the specific index.
 *
 *  @param index Index of the item to return.
 *
 *  @return File transfer item, can either be a file or a folder.
 */
- (OBEXFileTransferItem *)objectAtIndex:(NSUInteger)index;

/**
 *  Removes all the items in the folder listing.
 */
- (void)removeAllItems;

@end