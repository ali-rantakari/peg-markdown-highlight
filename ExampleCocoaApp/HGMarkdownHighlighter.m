//
//  HGMarkdownHighlighter.m
//  MDHExample
//
//  Created by Ali Rantakari on 27.2.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

#import "HGMarkdownHighlighter.h"
#import "markdown_parser.h"


// 'private members' category
@interface HGMarkdownHighlighter()

@property(retain) NSMutableSet *targetTextViews;
@property(retain) NSTimer *updateTimer;
@property(retain) NSMutableDictionary *elementLists;
@property(retain) NSThread *workerThread;
@property(retain) NSMutableArray *queue;
@property(retain) NSTextView *currentHighlightTarget;

@end


@implementation HGMarkdownHighlighter

@synthesize waitInterval;
@synthesize defaultFont;
@synthesize targetTextViews;
@synthesize updateTimer;
@synthesize elementLists;
@synthesize workerThread;
@synthesize currentHighlightTarget;
@synthesize queue;

- (id) init
{
	if (!(self = [super init]))
		return nil;
	
	self.queue = [NSMutableArray array];
	self.workerThread = nil;
	self.updateTimer = nil;
	self.currentHighlightTarget = nil;
	self.targetTextViews = [NSMutableSet new];
	self.waitInterval = 1;
	self.defaultFont = [NSFont userFixedPitchFontOfSize:12];
	self.elementLists = [NSMutableDictionary dictionary];
	
	return self;
}

- (void) dealloc
{
	self.elementLists = nil;
	self.targetTextViews = nil;
	self.defaultFont = nil;
	self.updateTimer = nil;
	self.workerThread = nil;
	self.queue = nil;
	[super dealloc];
}


#pragma mark -

- (void) clearHighlightingIn:(NSTextView *)textView withRange:(NSRange)range
{
	[[textView textStorage] addAttributes:[NSDictionary dictionaryWithObject:self.defaultFont forKey:NSFontAttributeName] range:range];
	[[textView textStorage] removeAttribute:NSBackgroundColorAttributeName range:range];
	[[textView textStorage] removeAttribute:NSForegroundColorAttributeName range:range];
}

- (void) applyHighlighting:(element **)elements to:(NSTextView *)textView withRange:(NSRange)range
{
	//NSLog(@"applyHighlighting: %@", NSStringFromRange(range));
	NSUInteger rangeEnd = NSMaxRange(range);
	
	[self clearHighlightingIn:textView withRange:range];
	
	NSMutableAttributedString *attrStr = [textView textStorage];
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
}

- (void) applyVisibleRangeHighlightingTo:(NSTextView *)textView
{
	NSRect visibleRect = [[[textView enclosingScrollView] contentView] documentVisibleRect];
	NSRange visibleRange = [[textView layoutManager] glyphRangeForBoundingRect:visibleRect inTextContainer:[textView textContainer]];
	
	NSValue *elementValue = [self.elementLists objectForKey:[NSValue valueWithPointer:textView]];
	if (elementValue == nil)
		return;
	element **result = (element **)[elementValue pointerValue];
	[self applyHighlighting:result to:textView withRange:visibleRange];
}

- (element **) parse:(NSTextView *)textView
{
	int extensions = 0;
	element **result = NULL;
	markdown_to_elements((char *)[[textView string] UTF8String], extensions, &result);
	return result;
}


- (void) cacheElementList:(element **)list forTextView:(NSTextView *)textView
{
	NSValue *viewKey = [NSValue valueWithPointer:textView];
	NSValue *oldValue = [self.elementLists objectForKey:viewKey];
	if (oldValue != nil)
		free_elements((element **)[oldValue pointerValue]);
	
	if (list == NULL)
		[self.elementLists removeObjectForKey:viewKey];
	else
		[self.elementLists setObject:[NSValue valueWithPointer:list] forKey:viewKey];
}

- (void) threadDoneHandler:(NSDictionary *)info
{
	NSTextView *textView = (NSTextView *)[info objectForKey:@"textView"];
	
	if ([self.queue containsObject:textView])
		return;
	
	element **result = (element **)[[info objectForKey:@"result"] pointerValue];
	[self cacheElementList:result forTextView:textView];
	
	[self applyVisibleRangeHighlightingTo:textView];
}

- (void) threadParseAndHighlight:(NSTextView *)textView
{
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
	
	element **result = [self parse:textView];
	
	NSDictionary *infoDict = [NSDictionary
							  dictionaryWithObjectsAndKeys:
							  textView, @"textView",
							  [NSValue valueWithPointer:result], @"result",
							  nil];
	[self
	 performSelectorOnMainThread:@selector(threadDoneHandler:)
	 withObject:infoDict
	 waitUntilDone:YES];
	
	[autoReleasePool drain];
}

- (void) threadDidExit:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:NSThreadWillExitNotification
	 object:self.workerThread];
	self.workerThread = nil;
	self.currentHighlightTarget = nil;
	[self
	 performSelectorOnMainThread:@selector(processNextFromQueue)
	 withObject:nil
	 waitUntilDone:NO];
}

- (void) processNextFromQueue
{
	if ([self.queue count] == 0 || self.workerThread != nil)
		return;
	
	// pop textView from queue
	NSTextView *textView = [self.queue objectAtIndex:0];
	[self.queue removeObjectAtIndex:0];
	
	self.workerThread = [[NSThread alloc]
			  initWithTarget:self
			  selector:@selector(threadParseAndHighlight:)
			  object:textView];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(threadDidExit:)
	 name:NSThreadWillExitNotification
	 object:self.workerThread];
	
	self.currentHighlightTarget = textView;
	
	[self.workerThread start];
}

- (void) requestHighlightFor:(NSTextView *)textView
{
	if ([self.queue containsObject:textView])
		return;
	
	[self.queue addObject:textView];
	[self processNextFromQueue];
}


- (void) textViewUpdateTimerFire:(NSTimer*)timer
{
	NSTextView *textView = (NSTextView *)[timer userInfo];
	if (textView != nil && ![self.targetTextViews containsObject:textView])
		return;
	
	self.updateTimer = nil;
	
	[self requestHighlightFor:textView];
}


- (void) textViewTextDidChange:(NSNotification *)notification
{
	NSTextView *textView = (NSTextView *)[notification object];
	if (textView != nil && ![self.targetTextViews containsObject:textView])
		return;
	
	if (self.updateTimer != nil)
		[self.updateTimer invalidate], self.updateTimer = nil;
	self.updateTimer = [NSTimer
				   scheduledTimerWithTimeInterval:self.waitInterval
				   target:self
				   selector:@selector(textViewUpdateTimerFire:)
				   userInfo:textView
				   repeats:NO
				   ];
}

- (void) textViewDidScroll:(NSNotification *)notification
{
	NSClipView *scrollViewContentView = (NSClipView *)[notification object];
	NSTextView *textView = [scrollViewContentView documentView];
	if (textView != nil && ![self.targetTextViews containsObject:textView])
		return;
	
	[self applyVisibleRangeHighlightingTo:textView];
}


- (void) startHighlighting:(NSTextView *)textView
{
	if ([self.targetTextViews containsObject:textView])
		return;
	
	[self.targetTextViews addObject:textView];
	
	[self requestHighlightFor:textView];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(textViewTextDidChange:)
	 name:NSTextDidChangeNotification
	 object:textView];
	
	NSScrollView *scrollView = [textView enclosingScrollView];
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
}

- (void) stopHighlighting:(NSTextView *)textView
{
	if (![self.targetTextViews containsObject:textView])
		return;
	
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:NSTextDidChangeNotification
	 object:textView];
	
	NSScrollView *scrollView = [textView enclosingScrollView];
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
	
	[self.targetTextViews removeObject:textView];
	[self cacheElementList:NULL forTextView:textView];
	
}







#pragma mark -
#pragma mark Singleton methods

static HGMarkdownHighlighter *sharedInstance = NULL;

+ (HGMarkdownHighlighter *) sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil)
			sharedInstance = [[HGMarkdownHighlighter alloc] init];
    }
    return sharedInstance;
}

+ (id) allocWithZone:(NSZone *)zone
{
    @synchronized(self)
	{
        if (sharedInstance == nil)
		{
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    return nil;
}

- (id) copyWithZone:(NSZone *)zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (NSUInteger) retainCount
{
    return UINT_MAX;
}

- (void) release
{
    // do nothing
}

- (id) autorelease
{
    return self;
}


@end
