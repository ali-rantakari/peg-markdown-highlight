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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[textView1 setFont:[NSFont fontWithName:@"courier" size:12]];
	[textView1 setTextColor:[NSColor whiteColor]];
	[textView1 setBackgroundColor:HG_COLOR_HEX(0x191e24)];
	[textView1 setInsertionPointColor:[NSColor whiteColor]];
	
	NSString *s = [NSString
				   stringWithContentsOfFile:[[NSBundle mainBundle]
											 pathForResource:@"huge"
											 ofType:@"md"]
				   encoding:NSUTF8StringEncoding
				   error:NULL];
	[textView1 insertText:s];
	[textView2 insertText:s];
	
	hl1 = [[HGMarkdownHighlighter alloc] initWithTextView:textView1
											 waitInterval:[delaySlider intValue]
												   styles:[self getDarkStyles]];
	hl1.makeLinksClickable = YES;
	[hl1 activate];
	
	hl2 = [[HGMarkdownHighlighter alloc] init];
	hl2.targetTextView = textView2;
	hl2.parseAndHighlightAutomatically = NO;
	[hl2 activate];
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
