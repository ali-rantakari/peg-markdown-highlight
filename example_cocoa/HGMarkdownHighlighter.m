/* PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * HGMarkdownHighlighter.m
 */

#import "HGMarkdownHighlighter.h"
#import "pmh_parser.h"
#import "pmh_styleparser.h"

#define kStyleParsingErrorInfoKey_ErrorMessage @"message"
#define kStyleParsingErrorInfoKey_LineNumber @"lineNumber"

void styleparsing_error_callback(char *error_message, int line_number, void *context_data)
{
	NSString *errMsg = [NSString stringWithUTF8String:error_message];
	if (errMsg == nil)
		NSLog(@"Cannot interpret error message as UTF-8: '%s'", error_message);
	NSDictionary *errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							 errMsg, kStyleParsingErrorInfoKey_ErrorMessage,
							 [NSNumber numberWithInt:line_number], kStyleParsingErrorInfoKey_LineNumber,
							 nil];
	[((HGMarkdownHighlighter *)context_data) performSelector:@selector(handleStyleParsingError:)
												  withObject:errInfo];
}


// 'private members' category
@interface HGMarkdownHighlighter()

@property(retain) NSTimer *updateTimer;
@property(copy) NSColor *defaultTextColor;
@property(retain) NSThread *workerThread;
@property(retain) NSDictionary *defaultTypingAttributes;

- (NSFontTraitMask) getClearFontTraitMask:(NSFontTraitMask)currentFontTraitMask;

@end


@implementation HGMarkdownHighlighter

@synthesize waitInterval;
@synthesize targetTextView;
@synthesize updateTimer;
@synthesize isActive;
@synthesize parseAndHighlightAutomatically;
@synthesize extensions;
@synthesize styles;
@synthesize defaultTextColor;
@synthesize workerThread;
@synthesize defaultTypingAttributes;
@synthesize resetTypingAttributes;
@synthesize makeLinksClickable;
@synthesize currentLineStyle;


- (id) init
{
	if (!(self = [super init]))
		return nil;
	
	cachedElements = NULL;
	currentHighlightText = NULL;
	styleDependenciesPending = NO;
	styleParsingErrors = [[NSMutableArray array] retain];
	
	self.defaultTypingAttributes = nil;
	self.workerThread = nil;
	self.defaultTextColor = nil;
	self.styles = nil;
	self.currentLineStyle = nil;
	self.isActive = NO;
	self.resetTypingAttributes = YES;
	self.makeLinksClickable = NO;
	self.parseAndHighlightAutomatically = YES;
	self.updateTimer = nil;
	self.targetTextView = nil;
	self.waitInterval = 1;
	self.extensions = pmh_EXT_NONE;
	
	return self;
}

- (id) initWithTextView:(NSTextView *)textView
{
	if (!(self = [self init]))
		return nil;
	self.targetTextView = textView;
	return self;
}

- (id) initWithTextView:(NSTextView *)textView
		   waitInterval:(NSTimeInterval)interval
{
	if (!(self = [self initWithTextView:textView]))
		return nil;
	self.waitInterval = interval;
	return self;
}

- (id) initWithTextView:(NSTextView *)textView
		   waitInterval:(NSTimeInterval)interval
				 styles:(NSArray *)inStyles
{
	if (!(self = [self initWithTextView:textView waitInterval:interval]))
		return nil;
	self.styles = inStyles;
	return self;
}

- (void) dealloc
{
	self.defaultTypingAttributes = nil;
	self.workerThread = nil;
	self.defaultTextColor = nil;
	self.targetTextView = nil;
	self.updateTimer = nil;
	self.styles = nil;
	self.currentLineStyle = nil;
	[styleParsingErrors release], styleParsingErrors = nil;
	[super dealloc];
}


#pragma mark -


- (pmh_element **) parse
{
	pmh_element **result = NULL;
	pmh_markdown_to_elements(currentHighlightText, self.extensions, &result);
	pmh_sort_elements_by_pos(result);
	return result;
}



- (void) threadParseAndHighlight
{
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
	
	pmh_element **result = [self parse];
	
	[self
	 performSelectorOnMainThread:@selector(parserDidParse:)
	 withObject:[NSValue valueWithPointer:result]
	 waitUntilDone:YES];
	
	[autoReleasePool drain];
}

- (void) threadDidExit:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:NSThreadWillExitNotification
	 object:self.workerThread];
	if (currentHighlightText != NULL)
		free(currentHighlightText);
	currentHighlightText = NULL;
	self.workerThread = nil;
	if (workerThreadResultsInvalid)
		[self
		 performSelectorOnMainThread:@selector(requestParsing)
		 withObject:nil
		 waitUntilDone:NO];
}

- (void) requestParsing
{
	if (self.workerThread != nil) {
		workerThreadResultsInvalid = YES;
		return;
	}
	
	self.workerThread = [[NSThread alloc]
						 initWithTarget:self
						 selector:@selector(threadParseAndHighlight)
						 object:nil];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(threadDidExit:)
	 name:NSThreadWillExitNotification
	 object:self.workerThread];
	
	if (currentHighlightText != NULL)
		free(currentHighlightText);
	char *textViewContents = (char *)[[self.targetTextView string] UTF8String];
	currentHighlightText = malloc(sizeof(char)*strlen(textViewContents)+1);
	strcpy(currentHighlightText, textViewContents);
	
	workerThreadResultsInvalid = NO;
	[self.workerThread start];
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
	[textStorage removeAttribute:NSLinkAttributeName range:range];
	if (self.defaultTextColor != nil)
		[textStorage addAttribute:NSForegroundColorAttributeName value:self.defaultTextColor range:range];
	else
		[textStorage removeAttribute:NSForegroundColorAttributeName range:range];
}

- (void) readClearTextStylesFromTextView
{
	clearFontTraitMask = [self getClearFontTraitMask:
						  [[NSFontManager sharedFontManager]
						   traitsOfFont:[self.targetTextView font]]];
	
	self.defaultTextColor = [self.targetTextView textColor];
	
	NSMutableDictionary *typingAttrs = [NSMutableDictionary dictionary];
	if ([self.targetTextView backgroundColor] != nil)
		[typingAttrs setObject:[self.targetTextView backgroundColor]
						forKey:NSBackgroundColorAttributeName];
	if ([self.targetTextView textColor] != nil)
		[typingAttrs setObject:[self.targetTextView textColor]
						forKey:NSForegroundColorAttributeName];
	if ([self.targetTextView font] != nil)
		[typingAttrs setObject:[self.targetTextView font]
						forKey:NSFontAttributeName];
	if ([self.targetTextView defaultParagraphStyle] != nil)
		[typingAttrs setObject:[self.targetTextView defaultParagraphStyle]
						forKey:NSParagraphStyleAttributeName];
	self.defaultTypingAttributes = typingAttrs;
}

- (void) applyHighlighting:(pmh_element **)elements withRange:(NSRange)range
{
	NSUInteger rangeEnd = NSMaxRange(range);
	[[self.targetTextView textStorage] beginEditing];
	[self clearHighlightingForRange:range];
	
	NSMutableAttributedString *attrStr = [self.targetTextView textStorage];
	unsigned long sourceLength = [attrStr length];
	
	for (HGMarkdownHighlightingStyle *style in self.styles)
	{
		pmh_element *cursor = elements[style.elementType];
		
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
			
			if (self.makeLinksClickable
				&& (style.elementType == pmh_LINK
					|| style.elementType == pmh_AUTO_LINK_URL
					|| style.elementType == pmh_AUTO_LINK_EMAIL)
				&& cursor->address != NULL)
			{
				NSString *linkAddress = [NSString stringWithUTF8String:cursor->address];
				if (style.elementType == pmh_AUTO_LINK_EMAIL && ![linkAddress hasPrefix:@"mailto:"])
					linkAddress = [@"mailto:" stringByAppendingString:linkAddress];
				[attrStr addAttribute:NSLinkAttributeName
								value:linkAddress
								range:hlRange];
			}
			
			for (NSString *attrName in style.attributesToRemove)
				[attrStr removeAttribute:attrName range:hlRange];
			
			[attrStr addAttributes:style.attributesToAdd range:hlRange];
			
			if (style.fontTraitsToAdd != 0)
				[attrStr applyFontTraits:style.fontTraitsToAdd range:hlRange];
			
			cursor = cursor->next;
		}
	}
	
	[[self.targetTextView textStorage] endEditing];
}

- (void) applyVisibleRangeHighlighting
{
	NSRect visibleRect = [[[self.targetTextView enclosingScrollView] contentView] documentVisibleRect];
	NSRange visibleRange = [[self.targetTextView layoutManager] glyphRangeForBoundingRect:visibleRect inTextContainer:[self.targetTextView textContainer]];
	
	if (cachedElements == NULL)
		return;
	[self applyHighlighting:cachedElements withRange:visibleRange];
	if (self.resetTypingAttributes)
		[self.targetTextView setTypingAttributes:self.defaultTypingAttributes];
}

- (void) clearHighlighting
{
	[self clearHighlightingForRange:NSMakeRange(0, [[self.targetTextView textStorage] length])];
}


- (void) cacheElementList:(pmh_element **)list
{
	if (cachedElements != NULL) {
		pmh_free_elements(cachedElements);
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
	if (workerThreadResultsInvalid)
		return;
	[self cacheElementList:(pmh_element **)[resultPointer pointerValue]];
	[self applyVisibleRangeHighlighting];
}


- (void) textViewUpdateTimerFire:(NSTimer*)timer
{
	self.updateTimer = nil;
	[self requestParsing];
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


- (NSArray *) getDefaultStyles
{
	static NSArray *defaultStyles = nil;
	if (defaultStyles != nil)
		return defaultStyles;
	
	defaultStyles = [[NSArray arrayWithObjects:
		HG_MKSTYLE(pmh_H1, HG_D(HG_DARK(HG_BLUE),HG_FORE, HG_LIGHT(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
		HG_MKSTYLE(pmh_H2, HG_D(HG_DARK(HG_BLUE),HG_FORE, HG_LIGHT(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
		HG_MKSTYLE(pmh_H3, HG_D(HG_DARK(HG_BLUE),HG_FORE, HG_LIGHT(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
		HG_MKSTYLE(pmh_H4, HG_D(HG_DARK(HG_BLUE),HG_FORE, HG_LIGHT(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
		HG_MKSTYLE(pmh_H5, HG_D(HG_DARK(HG_BLUE),HG_FORE, HG_LIGHT(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
		HG_MKSTYLE(pmh_H6, HG_D(HG_DARK(HG_BLUE),HG_FORE, HG_LIGHT(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
		HG_MKSTYLE(pmh_HRULE, HG_D(HG_DARK_GRAY,HG_FORE, HG_LIGHT_GRAY,HG_BACK), nil, 0),
		HG_MKSTYLE(pmh_LIST_BULLET, HG_D(HG_DARK(HG_MAGENTA),HG_FORE), nil, 0),
		HG_MKSTYLE(pmh_LIST_ENUMERATOR, HG_D(HG_DARK(HG_MAGENTA),HG_FORE), nil, 0),
		HG_MKSTYLE(pmh_LINK, HG_D(HG_DARK(HG_CYAN),HG_FORE, HG_LIGHT(HG_CYAN),HG_BACK), nil, 0),
		HG_MKSTYLE(pmh_AUTO_LINK_URL, HG_D(HG_DARK(HG_CYAN),HG_FORE, HG_LIGHT(HG_CYAN),HG_BACK), nil, 0),
		HG_MKSTYLE(pmh_AUTO_LINK_EMAIL, HG_D(HG_DARK(HG_CYAN),HG_FORE, HG_LIGHT(HG_CYAN),HG_BACK), nil, 0),
		HG_MKSTYLE(pmh_IMAGE, HG_D(HG_DARK(HG_MAGENTA),HG_FORE, HG_LIGHT(HG_MAGENTA),HG_BACK), nil, 0),
		HG_MKSTYLE(pmh_REFERENCE, HG_D(HG_DIM(HG_RED),HG_FORE), nil, 0),
		HG_MKSTYLE(pmh_CODE, HG_D(HG_DARK(HG_GREEN),HG_FORE, HG_LIGHT(HG_GREEN),HG_BACK), nil, 0),
		HG_MKSTYLE(pmh_EMPH, HG_D(HG_DARK(HG_YELLOW),HG_FORE), nil, NSItalicFontMask),
		HG_MKSTYLE(pmh_STRONG, HG_D(HG_DARK(HG_MAGENTA),HG_FORE), nil, NSBoldFontMask),
		HG_MKSTYLE(pmh_HTML_ENTITY, HG_D(HG_MED_GRAY,HG_FORE), nil, 0),
		HG_MKSTYLE(pmh_COMMENT, HG_D(HG_MED_GRAY,HG_FORE), nil, 0),
		HG_MKSTYLE(pmh_VERBATIM, HG_D(HG_DARK(HG_GREEN),HG_FORE, HG_LIGHT(HG_GREEN),HG_BACK), nil, 0),
		HG_MKSTYLE(pmh_BLOCKQUOTE, HG_D(HG_DARK(HG_MAGENTA),HG_FORE), HG_A(HG_BACK), NSUnboldFontMask),
		nil] retain];
	
	return defaultStyles;
}

- (void) applyStyleDependenciesToTargetTextView
{
	if (self.targetTextView == nil)
		return;
	
	// Set NSTextView link styles to match the styles set for
	// LINK elements, with the "pointing hand cursor" style added:
	for (HGMarkdownHighlightingStyle *style in self.styles)
	{
		if (style.elementType != pmh_LINK)
			continue;
		NSMutableDictionary *linkAttrs = [[style.attributesToAdd mutableCopy] autorelease];
		[linkAttrs setObject:[NSCursor pointingHandCursor] forKey:NSCursorAttributeName];
		[self.targetTextView setLinkTextAttributes:linkAttrs];
		break;
	}
	styleDependenciesPending = NO;
}

- (void) setStyles:(NSArray *)newStyles
{
	NSArray *stylesToApply = (newStyles != nil) ? newStyles : [self getDefaultStyles];
	
	[styles autorelease];
	styles = [stylesToApply copy];
	
	if (self.targetTextView != nil)
		[self applyStyleDependenciesToTargetTextView];
	else
		styleDependenciesPending = YES;
}

- (NSDictionary *) getDefaultSelectedTextAttributes
{
	static NSDictionary *cachedValue = nil;
	if (cachedValue == nil)
		cachedValue = [[[[[NSTextView alloc] initWithFrame:NSMakeRect(1,1,1,1)] autorelease]
						selectedTextAttributes] retain];
	return cachedValue;
}

- (void) handleStyleParsingError:(NSDictionary *)errorInfo
{
	NSString *errorMessage = (NSString *)[errorInfo objectForKey:kStyleParsingErrorInfoKey_ErrorMessage];
	NSString *messageToAdd = nil;
	if (errorMessage == nil)
		messageToAdd = @"<broken error message>";
	else
	{
		int lineNumber = [(NSNumber *)[errorInfo objectForKey:kStyleParsingErrorInfoKey_LineNumber] intValue];
		messageToAdd = [NSString stringWithFormat:@"(Line %i): %@", lineNumber, errorMessage];
	}
	[styleParsingErrors addObject:messageToAdd];
}

- (void) applyStylesFromStylesheet:(NSString *)stylesheet
				 withErrorDelegate:(id)errorDelegate
					 errorSelector:(SEL)errorSelector
{
	if (stylesheet == nil)
		return;
	
	char *c_stylesheet = (char *)[stylesheet UTF8String];
	pmh_style_collection *style_coll = NULL;
	
	if (errorDelegate == nil)
		style_coll = pmh_parse_styles(c_stylesheet, NULL, NULL);
	else
	{
		[styleParsingErrors removeAllObjects];
		style_coll = pmh_parse_styles(c_stylesheet, &styleparsing_error_callback, self);
		if ([styleParsingErrors count] > 0)
			[errorDelegate performSelector:errorSelector
							    withObject:styleParsingErrors];
	}
	
	NSMutableArray *stylesArr = [NSMutableArray array];
	
	// Set language element styles
	int i;
	for (i = 0; i < pmh_NUM_LANG_TYPES; i++)
	{
		pmh_style_attribute *cur = style_coll->element_styles[i];
		if (cur == NULL)
			continue;
		HGMarkdownHighlightingStyle *style = [[[HGMarkdownHighlightingStyle alloc]
											   initWithStyleAttributes:cur] autorelease];
		[stylesArr addObject:style];
	}
	
	self.styles = stylesArr;
	
	// Set editor styles
	if (self.targetTextView != nil)
	{
		[self clearHighlighting];
		
		// General editor styles
		if (style_coll->editor_styles != NULL)
		{
			pmh_style_attribute *cur = style_coll->editor_styles;
			while (cur != NULL)
			{
				if (cur->type == pmh_attr_type_background_color)
					[self.targetTextView setBackgroundColor:[HGMarkdownHighlightingStyle
															 colorFromARGBColor:cur->value->argb_color]];
				else if (cur->type == pmh_attr_type_foreground_color)
					[self.targetTextView setTextColor:[HGMarkdownHighlightingStyle
													   colorFromARGBColor:cur->value->argb_color]];
				else if (cur->type == pmh_attr_type_caret_color)
					[self.targetTextView setInsertionPointColor:[HGMarkdownHighlightingStyle
																 colorFromARGBColor:cur->value->argb_color]];
				cur = cur->next;
			}
		}
		
		// Selection styles
		if (style_coll->editor_selection_styles != NULL)
		{
			NSMutableDictionary *selAttrs = [[self getDefaultSelectedTextAttributes] mutableCopy];
			
			pmh_style_attribute *cur = style_coll->editor_selection_styles;
			while (cur != NULL)
			{
				// Cocoa (as of Mac OS 10.6.6) supports only foreground color,
				// background color and underlining attributes for selections:
				if (cur->type == pmh_attr_type_background_color)
					[selAttrs setObject:[HGMarkdownHighlightingStyle
										 colorFromARGBColor:cur->value->argb_color]
								 forKey:NSBackgroundColorAttributeName];
				else if (cur->type == pmh_attr_type_foreground_color)
					[selAttrs setObject:[HGMarkdownHighlightingStyle
										 colorFromARGBColor:cur->value->argb_color]
								 forKey:NSForegroundColorAttributeName];
				else if (cur->type == pmh_attr_type_font_style)
				{
					if (cur->value->font_styles->underlined)
						[selAttrs setObject:[NSNumber numberWithInt:NSUnderlineStyleSingle]
									 forKey:NSUnderlineStyleAttributeName];
				}
				cur = cur->next;
			}
			
			[self.targetTextView setSelectedTextAttributes:selAttrs];
		}
		else
			[self.targetTextView setSelectedTextAttributes:[self getDefaultSelectedTextAttributes]];
		
		// Current line styles
		if (style_coll->editor_current_line_styles != NULL)
		{
			self.currentLineStyle = [[[HGMarkdownHighlightingStyle alloc]
									  initWithStyleAttributes:style_coll->editor_current_line_styles]
									 autorelease];
		}
		else
			self.currentLineStyle = nil;
			
		[self readClearTextStylesFromTextView];
	}
	
	pmh_free_style_collection(style_coll);
	[self highlightNow];
}


- (void) setTargetTextView:(NSTextView *)newTextView
{
	if (targetTextView == newTextView)
		return;
	
	[targetTextView release];
	targetTextView = [newTextView retain];
	
	if (targetTextView != nil)
		[self readClearTextStylesFromTextView];
}


- (void) parseAndHighlightNow
{
	[self requestParsing];
}

- (void) highlightNow
{
	[self applyVisibleRangeHighlighting];
}

- (void) activate
{
	// todo: throw exception if targetTextView is nil?
	
	if (self.styles == nil)
		self.styles = [self getDefaultStyles];
	if (styleDependenciesPending)
		[self applyStyleDependenciesToTargetTextView];
	
	[self requestParsing];
	
	if (self.parseAndHighlightAutomatically)
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
	
	self.isActive = YES;
}

- (void) deactivate
{
	if (!self.isActive)
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
	self.isActive = NO;
}



@end
