//
//  HGMarkdownHighlighter.h
//  MDHExample
//
//  Created by Ali Rantakari on 27.2.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "mkd_types.h"


@interface HGMarkdownHighlighter : NSObject
{
	NSFont *defaultFont;
	NSTimeInterval waitInterval;
	NSTextView *targetTextView;
	int extensions;
	BOOL isHighlighting;
	BOOL highlightAutomatically;

@private
	NSTimer *updateTimer;
	element **cachedElements;
}

@property NSTimeInterval waitInterval;
@property(copy) NSFont *defaultFont;
@property(retain) NSTextView *targetTextView;
@property BOOL isHighlighting;
@property BOOL highlightAutomatically;
@property int extensions;

- (id) initWithTextView:(NSTextView *)textView;

- (void) parseAndHighlightNow;
- (void) startHighlighting;
- (void) stopHighlighting;

- (void) parserDidParse:(NSValue *)resultPointer;

@end
