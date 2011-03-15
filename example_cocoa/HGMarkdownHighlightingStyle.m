//
//  HGMarkdownHighlightingStyle.m
//  MDHExample
//
//  Created by Ali Rantakari on 15.3.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

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
