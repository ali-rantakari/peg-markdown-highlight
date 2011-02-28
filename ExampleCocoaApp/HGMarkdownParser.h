//
//  HGMarkdownParser.h
//  MDHExample
//
//  Created by Ali Rantakari on 28.2.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "markdown_parser.h"
#import "HGMarkdownHighlighter.h"


@interface HGMarkdownParser : NSObject
{
@private
	NSThread *workerThread;
	NSMutableArray *queue;
	HGMarkdownHighlighter *currentHighlightTarget;
}

+ (HGMarkdownParser *) sharedInstance;

- (void) requestParsing:(HGMarkdownHighlighter *)sender;
- (element **) parse:(NSString *)content extensions:(int)extensions;

@end
