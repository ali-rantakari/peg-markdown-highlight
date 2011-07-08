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
	
	styleParsingErrors = [[NSMutableArray array] retain];
	
	return self;
}

- (void) dealloc
{
	if (styleParsingErrors != nil)
		[styleParsingErrors release], styleParsingErrors = nil;
	[super dealloc];
}

- (void) awakeFromNib
{
	[delaySlider setFloatValue:0.25];
	[delayLabel setFloatValue:ROUND_QUARTER([delaySlider floatValue])];
}


- (void) handleStyleParsingError:(NSString *)errorMessage
{
	[styleParsingErrors addObject:errorMessage];
}

- (void) reportStyleParsingErrors
{
	if ([styleParsingErrors count] == 0)
		return;
	
	NSMutableString *errorsInfo = [NSMutableString string];
	for (NSString *str in styleParsingErrors)
	{
		[errorsInfo appendString:@"• "];
		[errorsInfo appendString:str];
		[errorsInfo appendString:@"\n"];
	}
	
	NSAlert *alert = [NSAlert alertWithMessageText:@"There were some errors when parsing the stylesheet:"
									 defaultButton:@"Ok"
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:errorsInfo];
	[alert runModal];
}

- (void) setTextView1Styles:(NSString *)styleName
{
	if ([styleName isEqualToString:@"Default"])
	{
		[textView1 setTextColor:nil];
		[textView1 setBackgroundColor:nil];
		[textView1 setInsertionPointColor:nil];
		hl1.styles = nil;
		[hl1 readClearTextStylesFromTextView];
	}
	else
	{
		NSString *styleFilePath = [[NSBundle mainBundle] pathForResource:styleName
																  ofType:@"style"];
		NSString *styleContents = [NSString stringWithContentsOfFile:styleFilePath
															encoding:NSUTF8StringEncoding
															   error:NULL];
		[styleParsingErrors removeAllObjects];
		[hl1 applyStylesFromStylesheet:styleContents
					 withErrorDelegate:self
						 errorSelector:@selector(handleStyleParsingError:)];
		[self reportStyleParsingErrors];
	}

	[hl1 highlightNow];
}

- (void) populateStylesPopUpButton
{
	[stylePopUpButton removeAllItems];
	[stylePopUpButton addItemWithTitle:@"Default"];
	
	NSArray *styleFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"style"
															 inDirectory:nil];
	for (NSString *file in styleFiles)
		[stylePopUpButton addItemWithTitle:[[file lastPathComponent] stringByDeletingPathExtension]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self populateStylesPopUpButton];
	
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
