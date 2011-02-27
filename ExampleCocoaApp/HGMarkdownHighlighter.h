//
//  HGMarkdownHighlighter.h
//  MDHExample
//
//  Created by Ali Rantakari on 27.2.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HGMarkdownHighlighter : NSObject
{
	NSFont *defaultFont;
	NSTimeInterval waitInterval;

@private
	NSTimer *updateTimer;
	NSMutableSet *targetTextViews;
	NSThread *workerThread;
	NSTextView *currentHighlightTarget;
	NSMutableArray *queue;
	NSMutableDictionary *elementLists;
}

@property NSTimeInterval waitInterval;
@property(copy) NSFont *defaultFont;

+ (HGMarkdownHighlighter *) sharedInstance;

- (void) startHighlighting:(NSTextView *)textView;
- (void) stopHighlighting:(NSTextView *)textView;

@end
