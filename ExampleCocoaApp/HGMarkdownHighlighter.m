//
//  HGMarkdownHighlighter.m
//  MDHExample
//
//  Created by Ali Rantakari on 27.2.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

#import "HGMarkdownHighlighter.h"
#import "HGMarkdownParser.h"


// 'private members' category
@interface HGMarkdownHighlighter()

@property(retain) NSTimer *updateTimer;

@end


@implementation HGMarkdownHighlighter

@synthesize waitInterval;
@synthesize defaultFont;
@synthesize targetTextView;
@synthesize updateTimer;
@synthesize isHighlighting;
@synthesize highlightAutomatically;
@synthesize extensions;

- (id) initWithTextView:(NSTextView *)textView
{
	if (!(self = [super init]))
		return nil;
	
	cachedElements = NULL;
	
	self.isHighlighting = NO;
	self.highlightAutomatically = YES;
	self.updateTimer = nil;
	self.targetTextView = textView;
	self.waitInterval = 1;
	self.extensions = 0;
	self.defaultFont = [NSFont userFixedPitchFontOfSize:12];
	
	return self;
}

- (void) dealloc
{
	self.targetTextView = nil;
	self.defaultFont = nil;
	self.updateTimer = nil;
	[super dealloc];
}


#pragma mark -

- (void) clearHighlightingForRange:(NSRange)range
{
	NSTextStorage *textStorage = [self.targetTextView textStorage];
	
	[textStorage addAttributes:[NSDictionary dictionaryWithObject:self.defaultFont forKey:NSFontAttributeName] range:range];
	[textStorage removeAttribute:NSBackgroundColorAttributeName range:range];
	[textStorage removeAttribute:NSForegroundColorAttributeName range:range];
}

- (void) applyHighlighting:(element **)elements withRange:(NSRange)range
{
	//NSLog(@"applyHighlighting: %@", NSStringFromRange(range));
	NSUInteger rangeEnd = NSMaxRange(range);
	
	// todo: disable undo registration
	[[self.targetTextView textStorage] beginEditing];
	
	[self clearHighlightingForRange:range];
	
	NSMutableAttributedString *attrStr = [self.targetTextView textStorage];
	int sourceLength = [attrStr length];
	
	int order[] = {
		H1, H2, H3, H4, H5, H6,  
		SINGLEQUOTED,
		DOUBLEQUOTED,
		LINK,
		AUTO_LINK_URL,
		AUTO_LINK_EMAIL,
		IMAGE,
		HTML,
		EMPH,
		STRONG,
		CODE,
		LIST_BULLET,
		LIST_ENUMERATOR,
		BLOCKQUOTE,
		VERBATIM,
		HTMLBLOCK,
		HRULE,
		REFERENCE,
		NOTE
	};
	int order_len = 24;
	
	for (int i = 0; i < order_len; i++)
	{
		element *cursor = elements[order[i]];
		
		while (cursor != NULL)
		{
			
			if ((cursor->end <= cursor->pos)
				|| (cursor->end <= range.location || cursor->pos >= rangeEnd))
			{
				cursor = cursor->next;
				continue;
			}
			
			NSColor *fgColor = nil;
			NSColor *bgColor = nil;
			BOOL removeFgColor = NO;
			BOOL removeBgColor = NO;
			
			switch (cursor->type)
			{
				case H1:
				case H2:
				case H3:
				case H4:
				case H5:
				case H6:		fgColor = [NSColor blueColor]; break;
				case EMPH:		fgColor = [NSColor yellowColor]; break;
				case STRONG:	fgColor = [NSColor magentaColor]; break;
				case CODE:
				case VERBATIM:	fgColor = [NSColor greenColor]; break;
				case HRULE:		fgColor = [NSColor cyanColor]; break;
				case LIST_ENUMERATOR:
				case LIST_BULLET:fgColor = [NSColor magentaColor]; break;
				case AUTO_LINK_EMAIL:
				case AUTO_LINK_URL:fgColor = [NSColor cyanColor]; break;
				case IMAGE:
				case LINK:		bgColor = [NSColor grayColor];
					fgColor = [NSColor cyanColor]; break;
				case BLOCKQUOTE:removeBgColor = YES;
					fgColor = [NSColor magentaColor]; break;
				default: break;
			}
			
			if (fgColor != nil || bgColor != nil) {
				int rangePos = MIN(MAX(cursor->pos, 0), sourceLength);
				int len = cursor->end - cursor->pos;
				if (rangePos+len > sourceLength)
					len = sourceLength-rangePos;
				NSRange range = NSMakeRange(rangePos, len);
				
				if (removeBgColor)
					[attrStr
					 removeAttribute:NSBackgroundColorAttributeName
					 range:range
					 ];
				else if (bgColor != nil)
					[attrStr
					 addAttribute:NSBackgroundColorAttributeName
					 value:bgColor
					 range:range
					 ];
				
				if (removeFgColor)
					[attrStr
					 removeAttribute:NSForegroundColorAttributeName
					 range:range
					 ];
				else if (fgColor != nil)
					[attrStr
					 addAttribute:NSForegroundColorAttributeName
					 value:fgColor
					 range:range
					 ];
			}
			
			cursor = cursor->next;
		}
	}
	
	[[self.targetTextView textStorage] endEditing];
	// todo: re-enable undo registration
}

- (void) applyVisibleRangeHighlighting
{
	NSRect visibleRect = [[[self.targetTextView enclosingScrollView] contentView] documentVisibleRect];
	NSRange visibleRange = [[self.targetTextView layoutManager] glyphRangeForBoundingRect:visibleRect inTextContainer:[self.targetTextView textContainer]];
	
	if (cachedElements == NULL)
		return;
	[self applyHighlighting:cachedElements withRange:visibleRange];
}



- (void) cacheElementList:(element **)list
{
	if (cachedElements != NULL) {
		free_elements(cachedElements);
		cachedElements = NULL;
	}
	cachedElements = list;
}

- (void) clearElementsCache
{
	[self cacheElementList:NULL];
}



- (void) parserDidParse:(NSValue *)resultPointer
{
	[self cacheElementList:(element **)[resultPointer pointerValue]];
	[self applyVisibleRangeHighlighting];
}

- (void) textViewUpdateTimerFire:(NSTimer*)timer
{
	self.updateTimer = nil;
	[[HGMarkdownParser sharedInstance] requestParsing:self];
}


- (void) textViewTextDidChange:(NSNotification *)notification
{
	if (self.updateTimer != nil)
		[self.updateTimer invalidate], self.updateTimer = nil;
	self.updateTimer = [NSTimer
				   scheduledTimerWithTimeInterval:self.waitInterval
				   target:self
				   selector:@selector(textViewUpdateTimerFire:)
				   userInfo:nil
				   repeats:NO
				   ];
}

- (void) textViewDidScroll:(NSNotification *)notification
{
	if (cachedElements == NULL)
		return;
	[self applyVisibleRangeHighlighting];
}


- (void) parseAndHighlightNow
{
	[[HGMarkdownParser sharedInstance] requestParsing:self];
}

- (void) startHighlighting
{
	// todo: throw exception if targetTextView is nil?
	
	[[HGMarkdownParser sharedInstance] requestParsing:self];
	
	if (self.highlightAutomatically)
		[[NSNotificationCenter defaultCenter]
		 addObserver:self
		 selector:@selector(textViewTextDidChange:)
		 name:NSTextDidChangeNotification
		 object:nil];
	
	NSScrollView *scrollView = [self.targetTextView enclosingScrollView];
	if (scrollView != nil)
	{
		[[scrollView contentView] setPostsBoundsChangedNotifications: YES];
		[[NSNotificationCenter defaultCenter]
		 addObserver:self
		 selector:@selector(textViewDidScroll:)
		 name:NSViewBoundsDidChangeNotification
		 object:[scrollView contentView]
		 ];
	}
	
	self.isHighlighting = YES;
}

- (void) stopHighlighting
{
	if (!self.isHighlighting)
		return;
	
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:NSTextDidChangeNotification
	 object:self.targetTextView];
	
	NSScrollView *scrollView = [self.targetTextView enclosingScrollView];
	if (scrollView != nil)
	{
		// let's not change this here... the user may wish to control it
		//[[scrollView contentView] setPostsBoundsChangedNotifications: NO];
		
		[[NSNotificationCenter defaultCenter]
		 removeObserver:self
		 name:NSViewBoundsDidChangeNotification
		 object:[scrollView contentView]
		 ];
	}
	
	[self clearElementsCache];
	self.isHighlighting = NO;
}



@end
