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

#import "OBEXFileTransferFolderListing.h"
#import "OBEXFileTransferItem.h"

@interface OBEXFileTransferFolderListing()

@property (nonatomic, strong) NSComparator itemComparator;

@end

@implementation OBEXFileTransferFolderListing

- (id) init {
    if (self = [super init]) {
        _files = [[NSMutableArray alloc] init];
        _folders = [[NSMutableArray alloc] init];
        _descending = NO;
        _itemComparator = ^(OBEXFileTransferItem *item1, OBEXFileTransferItem *item2) {
            return [item1.modified compare:item2.modified];
        };
    }
    return self;
}

- (void)addFile:(OBEXFileTransferFile *)file {
    NSUInteger newIndex = [self.files indexOfObject:file inSortedRange:(NSRange){0, self.files.count} options:NSBinarySearchingInsertionIndex usingComparator:self.itemComparator];
    [self.files insertObject:file atIndex:newIndex];
}

- (void)addFolder:(OBEXFileTransferFolder *)folder {
    NSUInteger newIndex = [self.folders indexOfObject:folder inSortedRange:(NSRange){0, self.folders.count} options:NSBinarySearchingInsertionIndex usingComparator:self.itemComparator];
    [self.folders insertObject:folder atIndex:newIndex];
}

- (NSUInteger)count {
    return self.files.count + self.folders.count;
}

- (OBEXFileTransferItem *)objectAtIndex:(NSUInteger)index {
    if(index < [self count]){        
        if(index < self.folders.count)
            return self.folders[index];
        else
            return self.files[index - self.folders.count];
    }
    else
        return nil;
}

- (void)setDescending:(BOOL)descending {
    if(_descending == descending) return;
    
    if(_descending) {
        [self.files sortUsingComparator:self.itemComparator];
        [self.folders sortUsingComparator:self.itemComparator];
    }
    else {
        NSComparator ascendComparator = ^(OBEXFileTransferItem *item1, OBEXFileTransferItem *item2) {
            return [item2.modified compare:item1.modified];
        };
        [self.files sortUsingComparator:ascendComparator];
        [self.folders sortUsingComparator:ascendComparator];
    }
    
    _descending = descending;
}

- (void)removeAllItems {
    [self.files removeAllObjects];
    [self.folders removeAllObjects];
}

@end
