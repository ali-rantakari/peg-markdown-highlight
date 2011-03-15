//
//  HGMarkdownHighlightingStyle.h
//  MDHExample
//
//  Created by Ali Rantakari on 15.3.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "markdown_definitions.h"


#define HG_MKSTYLE(elem, add, remove)	[[[HGMarkdownHighlightingStyle alloc] initWithType:(elem) attributesToAdd:(add) toRemove:(remove)] autorelease]
#define HG_D(...)	[NSDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__, nil]
#define HG_A(...)	[NSArray arrayWithObjects:__VA_ARGS__, nil]

#define HG_FORE			NSForegroundColorAttributeName
#define HG_BACK			NSBackgroundColorAttributeName

#define HG_COLOR_RGB(r,g,b)	[NSColor colorWithCalibratedRed:(r) green:(g) blue:(b) alpha:1.0]
#define HG_COLOR_HSB(h,s,b)	[NSColor colorWithCalibratedHue:(h) saturation:(s) brightness:(b) alpha:1.0]

// brightness/saturation
#define HG_DARK(h)	HG_COLOR_HSB(h, 1, 0.4)
#define HG_MED(h)	HG_COLOR_HSB(h, 1, 1)
#define HG_LIGHT(h)	HG_COLOR_HSB(h, 0.2, 1)

// hues
#define HG_GREEN	0.34
#define HG_YELLOW	0.15
#define HG_BLUE		0.67
#define HG_RED		0
#define HG_MAGENTA	0.87
#define HG_CYAN		0.5

#define HG_DARK_GRAY	HG_COLOR_HSB(0, 0, 0.2)
#define HG_LIGHT_GRAY	HG_COLOR_HSB(0, 0, 0.9)


@interface HGMarkdownHighlightingStyle : NSObject
{
	NSDictionary *attributesToAdd;
	NSArray *attributesToRemove;
	element_type elementType;
}

- (id) initWithType:(element_type)elemType attributesToAdd:(NSDictionary *)toAdd toRemove:(NSArray *)toRemove;

@property element_type elementType;
@property(copy) NSDictionary *attributesToAdd;
@property(copy) NSArray *attributesToRemove;

@end
