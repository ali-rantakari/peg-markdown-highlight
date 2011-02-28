//
//  MDHExampleAppDelegate.m
//  MDHExample
//
//  Created by Ali Rantakari on 27.2.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

#import "MDHExampleAppDelegate.h"

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
	[delayLabel takeIntValueFrom:delaySlider];
	[delaySlider setIntValue:1];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSString *s = [NSString
				   stringWithContentsOfFile:[[NSBundle mainBundle]
											 pathForResource:@"big"
											 ofType:@"md"]
				   encoding:NSUTF8StringEncoding
				   error:NULL];
	[textView1 insertText:s];
	[textView2 insertText:s];
	
	hl1 = [[HGMarkdownHighlighter alloc] initWithTextView:textView1];
	hl1.waitInterval = [delaySlider intValue];
	[hl1 startHighlighting];
	
	hl2 = [[HGMarkdownHighlighter alloc] initWithTextView:textView2];
	hl2.waitInterval = 2; // only relevant if highlightAutomatically == YES
	hl2.highlightAutomatically = NO;
	[hl2 startHighlighting];
}


- (IBAction) delaySliderMove:(id)sender
{
	[delayLabel takeIntValueFrom:delaySlider];
	hl1.waitInterval = [delaySlider intValue];
}

- (IBAction) manualHighlightButtonPress:(id)sender
{
	[hl2 parseAndHighlightNow];
}


@end
