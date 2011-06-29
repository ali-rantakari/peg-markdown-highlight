/* PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * MDHExampleAppDelegate.m
 * 
 * Cocoa example for highlighting a rich text widget.
 */

#import "MDHExampleAppDelegate.h"
#import "HGMarkdownHighlightingStyle.h"

#define ROUND_QUARTER(x)	(round((x) * 4) / 4)


@implementation MDHExampleAppDelegate

@synthesize window;
@synthesize textView1;
@synthesize textView2;

- (id) init
{
	if (!(self = [super init]))
		return nil;
	
	solarizedColors = [[self getSolarizedColors] retain];
	#define SOL(x) [solarizedColors objectForKey:(x)]
	
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) awakeFromNib
{
	[delaySlider setFloatValue:0.25];
	[delayLabel setFloatValue:ROUND_QUARTER([delaySlider floatValue])];
}

- (NSDictionary *) getSolarizedColors
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			HG_COLOR_HEX(0x002b36), @"base03",
			HG_COLOR_HEX(0x073642), @"base02",
			HG_COLOR_HEX(0x586e75), @"base01",
			HG_COLOR_HEX(0x657b83), @"base00",
			HG_COLOR_HEX(0x839496), @"base0",
			HG_COLOR_HEX(0x93a1a1), @"base1",
			HG_COLOR_HEX(0xeee8d5), @"base2",
			HG_COLOR_HEX(0xfdf6e3), @"base3",
			HG_COLOR_HEX(0xb58900), @"yellow",
			HG_COLOR_HEX(0xcb4b16), @"orange",
			HG_COLOR_HEX(0xdc322f), @"red",
			HG_COLOR_HEX(0xd33682), @"magenta",
			HG_COLOR_HEX(0x6c71c4), @"violet",
			HG_COLOR_HEX(0x268bd2), @"blue",
			HG_COLOR_HEX(0x2aa198), @"cyan",
			HG_COLOR_HEX(0x859900), @"green",
			nil];
}


- (NSArray *) getDarkStyles
{
	return [NSArray arrayWithObjects:
			HG_MKSTYLE(H1, HG_D(HG_LIGHT(HG_BLUE),HG_FORE, HG_VDARK(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
			HG_MKSTYLE(H2, HG_D(HG_LIGHT(HG_BLUE),HG_FORE, HG_VDARK(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
			HG_MKSTYLE(H3, HG_D(HG_LIGHT(HG_BLUE),HG_FORE, HG_VDARK(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
			HG_MKSTYLE(H4, HG_D(HG_LIGHT(HG_BLUE),HG_FORE, HG_VDARK(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
			HG_MKSTYLE(H5, HG_D(HG_LIGHT(HG_BLUE),HG_FORE, HG_VDARK(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
			HG_MKSTYLE(H6, HG_D(HG_LIGHT(HG_BLUE),HG_FORE, HG_VDARK(HG_BLUE),HG_BACK), nil, NSBoldFontMask),
			HG_MKSTYLE(HRULE, HG_D(HG_LIGHT_GRAY,HG_FORE, HG_DARK_GRAY,HG_BACK), nil, 0),
			HG_MKSTYLE(LIST_BULLET, HG_D(HG_MED(HG_MAGENTA),HG_FORE), nil, 0),
			HG_MKSTYLE(LIST_ENUMERATOR, HG_D(HG_MED(HG_MAGENTA),HG_FORE), nil, 0),
			HG_MKSTYLE(LINK, HG_D(HG_LIGHT(HG_CYAN),HG_FORE, HG_VDARK(HG_CYAN),HG_BACK), nil, 0),
			HG_MKSTYLE(AUTO_LINK_URL, HG_D(HG_LIGHT(HG_CYAN),HG_FORE, HG_VDARK(HG_CYAN),HG_BACK), nil, 0),
			HG_MKSTYLE(AUTO_LINK_EMAIL, HG_D(HG_LIGHT(HG_CYAN),HG_FORE, HG_VDARK(HG_CYAN),HG_BACK), nil, 0),
			HG_MKSTYLE(IMAGE, HG_D(HG_LIGHT(HG_MAGENTA),HG_FORE, HG_VDARK(HG_MAGENTA),HG_BACK), nil, 0),
			HG_MKSTYLE(REFERENCE, HG_D(HG_DIM(HG_RED),HG_FORE), nil, 0),
			HG_MKSTYLE(CODE, HG_D(HG_LIGHT(HG_GREEN),HG_FORE, HG_VDARK(HG_GREEN),HG_BACK), nil, 0),
			HG_MKSTYLE(EMPH, HG_D(HG_MED(HG_YELLOW),HG_FORE), nil, NSItalicFontMask),
			HG_MKSTYLE(STRONG, HG_D(HG_MED(HG_MAGENTA),HG_FORE), nil, NSBoldFontMask),
			HG_MKSTYLE(HTML_ENTITY, HG_D(HG_MED_GRAY,HG_FORE), nil, 0),
			HG_MKSTYLE(COMMENT, HG_D(HG_MED_GRAY,HG_FORE), nil, 0),
			HG_MKSTYLE(VERBATIM, HG_D(HG_LIGHT(HG_GREEN),HG_FORE, HG_VDARK(HG_GREEN),HG_BACK), nil, 0),
			HG_MKSTYLE(BLOCKQUOTE, HG_D(HG_MED(HG_CYAN),HG_FORE), HG_A(HG_BACK), 0),
			nil];
}

- (NSArray *) getSolarizedStyles
{
	return [NSArray arrayWithObjects:
			HG_MKSTYLE(H1, HG_D(SOL(@"blue"),HG_FORE), nil, NSBoldFontMask),
			HG_MKSTYLE(H2, HG_D(SOL(@"blue"),HG_FORE), nil, NSBoldFontMask),
			HG_MKSTYLE(H3, HG_D(SOL(@"violet"),HG_FORE), nil, NSBoldFontMask),
			HG_MKSTYLE(H4, HG_D(SOL(@"violet"),HG_FORE), nil, 0),
			HG_MKSTYLE(H5, HG_D(SOL(@"violet"),HG_FORE), nil, 0),
			HG_MKSTYLE(H6, HG_D(SOL(@"violet"),HG_FORE), nil, 0),
			HG_MKSTYLE(HRULE, HG_D(SOL(@"base01"),HG_FORE), nil, 0),
			HG_MKSTYLE(LIST_BULLET, HG_D(SOL(@"yellow"),HG_FORE), nil, 0),
			HG_MKSTYLE(LIST_ENUMERATOR, HG_D(SOL(@"yellow"),HG_FORE), nil, 0),
			HG_MKSTYLE(LINK, HG_D(SOL(@"cyan"),HG_FORE), nil, 0),
			HG_MKSTYLE(AUTO_LINK_URL, HG_D(SOL(@"cyan"),HG_FORE), nil, 0),
			HG_MKSTYLE(AUTO_LINK_EMAIL, HG_D(SOL(@"cyan"),HG_FORE), nil, 0),
			HG_MKSTYLE(IMAGE, HG_D(SOL(@"magenta"),HG_FORE), nil, 0),
			HG_MKSTYLE(REFERENCE, HG_D(HG_ALPHA(SOL(@"yellow"), 0.5),HG_FORE), nil, 0),
			HG_MKSTYLE(CODE, HG_D(SOL(@"green"),HG_FORE), nil, 0),
			HG_MKSTYLE(EMPH, HG_D(SOL(@"orange"),HG_FORE), nil, NSItalicFontMask),
			HG_MKSTYLE(STRONG, HG_D(SOL(@"red"),HG_FORE), nil, NSBoldFontMask),
			HG_MKSTYLE(HTML_ENTITY, HG_D(SOL(@"violet"),HG_FORE), nil, 0),
			HG_MKSTYLE(COMMENT, HG_D(SOL(@"base1"),HG_FORE), nil, 0),
			HG_MKSTYLE(VERBATIM, HG_D(SOL(@"green"),HG_FORE), nil, 0),
			HG_MKSTYLE(BLOCKQUOTE, HG_D(SOL(@"magenta"),HG_FORE), nil, 0),
			nil];
}

- (void) setTextView1Styles:(NSString *)styleName
{
	if ([styleName isEqualToString:@"Solarized Light"])
	{
		[textView1 setTextColor:SOL(@"base01")];
		[textView1 setBackgroundColor:SOL(@"base2")];
		[textView1 setInsertionPointColor:[NSColor blackColor]];
		hl1.styles = [self getSolarizedStyles];
	}
	else if ([styleName isEqualToString:@"Solarized Dark"])
	{
		[textView1 setTextColor:SOL(@"base1")];
		[textView1 setBackgroundColor:SOL(@"base03")];
		[textView1 setInsertionPointColor:[NSColor whiteColor]];
		hl1.styles = [self getSolarizedStyles];
	}
	else if ([styleName isEqualToString:@"Custom Dark"])
	{
		[textView1 setTextColor:[NSColor whiteColor]];
		[textView1 setBackgroundColor:HG_COLOR_HEX(0x191e24)];
		[textView1 setInsertionPointColor:[NSColor whiteColor]];
		hl1.styles = [self getDarkStyles];
	}
	else if ([styleName isEqualToString:@"Default"])
	{
		[textView1 setTextColor:nil];
		[textView1 setBackgroundColor:nil];
		[textView1 setInsertionPointColor:nil];
		hl1.styles = nil;
	}
	[hl1 readClearTextStylesFromTextView];
	[hl1 highlightNow];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[textView1 setFont:[NSFont fontWithName:@"courier" size:12]];
	
	NSString *s = [NSString
				   stringWithContentsOfFile:[[NSBundle mainBundle]
											 pathForResource:@"huge"
											 ofType:@"md"]
				   encoding:NSUTF8StringEncoding
				   error:NULL];
	[textView1 insertText:s];
	[textView2 insertText:s];
	
	hl1 = [[HGMarkdownHighlighter alloc] initWithTextView:textView1
											 waitInterval:[delaySlider intValue]];
	hl1.makeLinksClickable = YES;
	[self styleSelected:self];
	[hl1 activate];
	
	hl2 = [[HGMarkdownHighlighter alloc] init];
	hl2.targetTextView = textView2;
	hl2.parseAndHighlightAutomatically = NO;
	[hl2 activate];
}

- (IBAction) styleSelected:(id)sender
{
	[self setTextView1Styles:[[stylePopUpButton selectedItem] title]];
}


- (IBAction) delaySliderMove:(id)sender
{
	float interval = ROUND_QUARTER([delaySlider floatValue]);
	[delayLabel setFloatValue:interval];
	hl1.waitInterval = interval;
}

- (IBAction) manualHighlightButtonPress:(id)sender
{
	[hl2 parseAndHighlightNow];
}


@end
