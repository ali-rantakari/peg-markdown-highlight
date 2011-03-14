//
//  MDHExampleAppDelegate.h
//  MDHExample
//
//  Created by Ali Rantakari on 27.2.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HGMarkdownHighlighter.h"

@interface MDHExampleAppDelegate : NSObject
{
    NSWindow *window;
	NSTextView *textView1;
	NSTextView *textView2;
	
	IBOutlet NSTextField *delayLabel;
	IBOutlet NSSlider *delaySlider;
	
	HGMarkdownHighlighter *hl1;
	HGMarkdownHighlighter *hl2;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextView *textView1;
@property (assign) IBOutlet NSTextView *textView2;

- (IBAction) delaySliderMove:(id)sender;
- (IBAction) manualHighlightButtonPress:(id)sender;

@end
