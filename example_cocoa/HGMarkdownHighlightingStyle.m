/* PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * HGMarkdownHighlightingStyle.m
 */

#import "HGMarkdownHighlightingStyle.h"

@implementation HGMarkdownHighlightingStyle

- (id) initWithType:(element_type)elemType
	attributesToAdd:(NSDictionary *)toAdd
		   toRemove:(NSArray *)toRemove
	fontTraitsToAdd:(NSFontTraitMask)traits
{
	if (!(self = [super init]))
		return nil;
	
	self.elementType = elemType;
	self.attributesToAdd = toAdd;
	self.attributesToRemove = toRemove;
	self.fontTraitsToAdd = traits;
	
	return self;
}

- (void) dealloc
{
	self.attributesToAdd = nil;
	self.attributesToRemove = nil;
	[super dealloc];
}

@synthesize elementType;
@synthesize attributesToAdd;
@synthesize attributesToRemove;
@synthesize fontTraitsToAdd;

@end
