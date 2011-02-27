//
//  MDHExampleAppDelegate.h
//  MDHExample
//
//  Created by Ali Rantakari on 27.2.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MDHExampleAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	NSTextView *textView1;
	NSTextView *textView2;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextView *textView1;
@property (assign) IBOutlet NSTextView *textView2;

@end
