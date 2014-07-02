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

#import "OBEXFileTransferFolderListingParser.h"

@implementation OBEXFileTransferFolderListingParser

@synthesize folderListing; 

- (OBEXFileTransferFolderListing *)parseData:(NSData *)data {
    folderListing = [[OBEXFileTransferFolderListing alloc] init];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser parse];
    
    return folderListing;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
    attributes:(NSDictionary *)attributeDict {
    if(qName) elementName = qName;
	if(elementName) {
        current = [NSString stringWithString:elementName];
        // Determine the modified date.
        // Parse string into NSDate with format: 20070605T113800.
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMdd'T'HHmmss"];
        NSDate *modified = [dateFormatter dateFromString:[attributeDict objectForKey:@"modified"]];
        // Add file object to folder listing.
        if([current isEqualToString:@"file"]){
            OBEXFileTransferFile *tempFile = [[OBEXFileTransferFile alloc] initWithName:[attributeDict objectForKey:@"name"] modified:modified size:[[attributeDict objectForKey:@"name"] integerValue] data:nil];
            [folderListing addFile:tempFile];
        }
        else if([current isEqualToString:@"folder"]){
            if(!modified) {
                modified = [NSDate date];
            }
            OBEXFileTransferFolder *tempFolder = [[OBEXFileTransferFolder alloc] initWithName:[attributeDict objectForKey:@"name"] modified:modified];
            [folderListing addFolder:tempFolder];
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName
{
	current = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (!current) return;
}

-(void) parserDidStartDocument:(NSXMLParser *)parser {
	//NSLog(@"parserDidStartDocument");
}

-(void) parserDidEndDocument: (NSXMLParser *)parser {
	//NSLog(@"parserDidEndDocument");
}

@end
