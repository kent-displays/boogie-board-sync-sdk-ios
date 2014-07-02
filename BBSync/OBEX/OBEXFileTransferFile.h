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

#import "OBEXFileTransferItem.h"

/**
 *  The 'OBEXFileTransferFile' class is a subclass of OBEXFileTransferItem that
 *  represents a file adding properties that are unique to it.
 */
@interface OBEXFileTransferFile : OBEXFileTransferItem

/**
 *  Initializer to create an file transfer file.
 *
 *  @param name     Name of the file.
 *  @param modified Date the file was modified.
 *  @param size     Size of the file.
 *  @param data     Data that represents the file.
 *
 *  @return File transfer file with the associated fields.
 */
- (id)initWithName:(NSString *)name modified:(NSDate *)modified size:(NSUInteger)size data:(NSMutableData *)data;

/**
 *  Size of the file.
 */
@property (nonatomic, readonly) NSInteger size;

/**
 *  Data that the file contains.
 */
@property (nonatomic) NSMutableData *data;

@end
