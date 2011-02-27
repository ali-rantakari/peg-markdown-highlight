//
//  MDHExampleAppDelegate.m
//  MDHExample
//
//  Created by Ali Rantakari on 27.2.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

#import "MDHExampleAppDelegate.h"
#import "HGMarkdownHighlighter.h"

@implementation MDHExampleAppDelegate

@synthesize window;
@synthesize textView1;
@synthesize textView2;

- (void) dealloc
{
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[HGMarkdownHighlighter sharedInstance] startHighlighting:textView1];
	[[HGMarkdownHighlighter sharedInstance] startHighlighting:textView2];
}

@end
