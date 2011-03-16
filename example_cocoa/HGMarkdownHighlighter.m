//
//  HGMarkdownHighlighter.m
//  MDHExample
//
//  Created by Ali Rantakari on 27.2.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

#import "HGMarkdownHighlighter.h"
#import "HGMarkdownParser.h"
#import "HGMarkdownHighlightingStyle.h"

// 'private members' category
@interface HGMarkdownHighlighter()

@property(retain) NSTimer *updateTimer;
@property(copy) NSColor *defaultTextColor;

@end


@implementation HGMarkdownHighlighter

@synthesize waitInterval;
@synthesize targetTextView;
@synthesize updateTimer;
@synthesize isHighlighting;
@synthesize highlightAutomatically;
@synthesize extensions;
@synthesize styles;
@synthesize defaultTextColor;

- (id) initWithTextView:(NSTextView *)textView
{
	if (!(self = [super init]))
		return nil;
	
	cachedElements = NULL;
	
	self.defaultTextColor = nil;
	self.styles = nil;
	self.isHighlighting = NO;
	self.highlightAutomatically = YES;
	self.updateTimer = nil;
	self.targetTextView = textView;
	self.waitInterval = 1;
	self.extensions = 0;
	isDirty = NO;
	
	return self;
}

- (void) dealloc
{
	self.defaultTextColor = nil;
	self.targetTextView = nil;
	self.updateTimer = nil;
	self.styles = nil;
	[super dealloc];
}


#pragma mark -

- (NSFontTraitMask) getClearFontTraitMask:(NSFontTraitMask)currentFontTraitMask
{
	static NSDictionary *oppositeFontTraits = nil;	
	if (oppositeFontTraits == nil)
		oppositeFontTraits = [[NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithUnsignedInt:NSItalicFontMask], [NSNumber numberWithUnsignedInt:NSUnitalicFontMask],
							   [NSNumber numberWithUnsignedInt:NSUnitalicFontMask], [NSNumber numberWithUnsignedInt:NSItalicFontMask],
							   [NSNumber numberWithUnsignedInt:NSUnboldFontMask], [NSNumber numberWithUnsignedInt:NSBoldFontMask],
							   [NSNumber numberWithUnsignedInt:NSBoldFontMask], [NSNumber numberWithUnsignedInt:NSUnboldFontMask],
							   [NSNumber numberWithUnsignedInt:NSCondensedFontMask], [NSNumber numberWithUnsignedInt:NSExpandedFontMask],
							   [NSNumber numberWithUnsignedInt:NSExpandedFontMask], [NSNumber numberWithUnsignedInt:NSCondensedFontMask],
							   nil] retain];
	NSFontTraitMask traitsToApply = 0;
	for (NSNumber *trait in oppositeFontTraits)
	{
		if ((currentFontTraitMask & [trait unsignedIntValue]) != 0)
			continue;
		traitsToApply |= [(NSNumber *)[oppositeFontTraits objectForKey:trait] unsignedIntValue];
	}
	return traitsToApply;
}

- (void) clearHighlightingForRange:(NSRange)range
{
	NSTextStorage *textStorage = [self.targetTextView textStorage];
	
	[textStorage applyFontTraits:clearFontTraitMask range:range];
	[textStorage removeAttribute:NSBackgroundColorAttributeName range:range];
	if (self.defaultTextColor != nil)
		[textStorage addAttribute:NSForegroundColorAttributeName value:self.defaultTextColor range:range];
	else
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
	unsigned long sourceLength = [attrStr length];
	
	for (HGMarkdownHighlightingStyle *style in self.styles)
	{
		element *cursor = elements[style.elementType];
		
		while (cursor != NULL)
		{
			// Ignore (length <= 0) elements (just in case) and
			// ones that end before our range begins
			if (cursor->end <= cursor->pos
				|| cursor->end <= range.location)
			{
				cursor = cursor->next;
				continue;
			}
			
			// HGMarkdownParser orders elements by pos so we can stop
			// at the first one that goes over our range
			if (cursor->pos >= rangeEnd)
				break;
			
			unsigned long rangePosLowLimited = MAX(cursor->pos, (unsigned long)0);
			unsigned long rangePos = MIN(rangePosLowLimited, sourceLength);
			unsigned long len = cursor->end - cursor->pos;
			if (rangePos+len > sourceLength)
				len = sourceLength-rangePos;
			NSRange hlRange = NSMakeRange(rangePos, len);
			
			for (NSString *attrName in style.attributesToRemove)
				[attrStr removeAttribute:attrName range:hlRange];
			
			[attrStr addAttributes:style.attributesToAdd range:hlRange];
			
			if (style.fontTraitsToAdd != 0)
				[attrStr applyFontTraits:style.fontTraitsToAdd range:hlRange];
			
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
	if (isDirty)
		return;
	[self cacheElementList:(element **)[resultPointer pointerValue]];
	[self applyVisibleRangeHighlighting];
}


- (void) requestParsing
{
	isDirty = NO;
	[[HGMarkdownParser sharedInstance] requestParsing:self];
}


- (void) textViewUpdateTimerFire:(NSTimer*)timer
{
	self.updateTimer = nil;
	[self requestParsing];
}


- (void) textViewTextDidChange:(NSNotification *)notification
{
	isDirty = YES;
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


- (NSArray *) getDefaultStyles
{
	static NSArray *defaultStyles = nil;
	if (defaultStyles != nil)
		return defaultStyles;
	
	defaultStyles = [[NSArray arrayWithObjects:
		HG_MKSTYLE(H1, HG_D(HG_DARK(HG_BLUE),HG_FORE, HG_LIGHT(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
		HG_MKSTYLE(H2, HG_D(HG_DARK(HG_BLUE),HG_FORE, HG_LIGHT(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
		HG_MKSTYLE(H3, HG_D(HG_DARK(HG_BLUE),HG_FORE, HG_LIGHT(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
		HG_MKSTYLE(H4, HG_D(HG_DARK(HG_BLUE),HG_FORE, HG_LIGHT(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
		HG_MKSTYLE(H5, HG_D(HG_DARK(HG_BLUE),HG_FORE, HG_LIGHT(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
		HG_MKSTYLE(H6, HG_D(HG_DARK(HG_BLUE),HG_FORE, HG_LIGHT(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
		HG_MKSTYLE(HRULE, HG_D(HG_DARK_GRAY,HG_FORE, HG_LIGHT_GRAY,HG_BACK), nil, 0),
		HG_MKSTYLE(LIST_BULLET, HG_D(HG_DARK(HG_MAGENTA),HG_FORE), nil, 0),
		HG_MKSTYLE(LIST_ENUMERATOR, HG_D(HG_DARK(HG_MAGENTA),HG_FORE), nil, 0),
		HG_MKSTYLE(LINK, HG_D(HG_DARK(HG_CYAN),HG_FORE, HG_LIGHT(HG_CYAN),HG_BACK), nil, 0),
		HG_MKSTYLE(AUTO_LINK_URL, HG_D(HG_DARK(HG_CYAN),HG_FORE, HG_LIGHT(HG_CYAN),HG_BACK), nil, 0),
		HG_MKSTYLE(AUTO_LINK_EMAIL, HG_D(HG_DARK(HG_CYAN),HG_FORE, HG_LIGHT(HG_CYAN),HG_BACK), nil, 0),
		HG_MKSTYLE(REFERENCE, HG_D(HG_DIM(HG_RED),HG_FORE), nil, 0),
		HG_MKSTYLE(CODE, HG_D(HG_DARK(HG_GREEN),HG_FORE, HG_LIGHT(HG_GREEN),HG_BACK), nil, 0),
		HG_MKSTYLE(EMPH, HG_D(HG_DARK(HG_YELLOW),HG_FORE), nil, NSItalicFontMask),
		HG_MKSTYLE(STRONG, HG_D(HG_DARK(HG_MAGENTA),HG_FORE), nil, NSBoldFontMask),
		HG_MKSTYLE(VERBATIM, HG_D(HG_DARK(HG_GREEN),HG_FORE, HG_LIGHT(HG_GREEN),HG_BACK), nil, 0),
		HG_MKSTYLE(BLOCKQUOTE, HG_D(HG_DARK(HG_MAGENTA),HG_FORE), HG_A(HG_BACK), NSUnboldFontMask),
		nil] retain];
	
	return defaultStyles;
}


- (void) parseAndHighlightNow
{
	[self requestParsing];
}

- (void) startHighlighting
{
	// todo: throw exception if targetTextView is nil?
	
	if (self.styles == nil)
		self.styles = [self getDefaultStyles];
	
	clearFontTraitMask = [self getClearFontTraitMask:[[NSFontManager sharedFontManager] traitsOfFont:[self.targetTextView font]]];
	self.defaultTextColor = [self.targetTextView textColor];
	
	[[HGMarkdownParser sharedInstance] requestParsing:self];
	
	if (self.highlightAutomatically)
		[[NSNotificationCenter defaultCenter]
		 addObserver:self
		 selector:@selector(textViewTextDidChange:)
		 name:NSTextDidChangeNotification
		 object:self.targetTextView];
	
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
