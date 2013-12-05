/* PEG Markdown Highlight
 * Copyright 2011-2013 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * MDHExampleAppDelegate.h
 * 
 * Cocoa example for highlighting a rich text widget.
 */

#import <Cocoa/Cocoa.h>
#import "HGMarkdownHighlighter.h"

@interface MDHExampleAppDelegate : NSObject
{
	IBOutlet NSTextField *delayLabel;
	IBOutlet NSSlider *delaySlider;
	IBOutlet NSPopUpButton *stylePopUpButton;
	
	HGMarkdownHighlighter *hl1;
	HGMarkdownHighlighter *hl2;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *textView1;
@property (unsafe_unretained) IBOutlet NSTextView *textView2;

- (IBAction) delaySliderMove:(id)sender;
- (IBAction) manualHighlightButtonPress:(id)sender;
- (IBAction) styleSelected:(id)sender;

@end
