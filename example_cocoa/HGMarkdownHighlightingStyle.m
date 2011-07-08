/* PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * HGMarkdownHighlightingStyle.m
 */

#import "HGMarkdownHighlightingStyle.h"


@implementation HGMarkdownHighlightingStyle

+ (NSColor *) colorFromARGBColor:(attr_argb_color *)argb_color
{
	return [NSColor colorWithDeviceRed:(argb_color->red / 255.0)
								 green:(argb_color->green / 255.0)
								  blue:(argb_color->blue / 255.0)
								 alpha:(argb_color->alpha / 255.0)];
}

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

- (id) initWithStyleAttributes:(style_attribute *)attributes
{
	if (!(self = [super init]))
		return nil;
	
	style_attribute *cur = attributes;
	self.elementType = cur->lang_element_type;
	self.fontTraitsToAdd = 0;
	
	NSMutableDictionary *toAdd = [NSMutableDictionary dictionary];
	NSString *fontName = nil;
	CGFloat fontSize = -1;
	
	while (cur != NULL)
	{
		if (cur->type == attr_type_foreground_color)
			[toAdd setObject:[HGMarkdownHighlightingStyle colorFromARGBColor:cur->value->argb_color]
					  forKey:NSForegroundColorAttributeName];
		
		else if (cur->type == attr_type_background_color)
			[toAdd setObject:[HGMarkdownHighlightingStyle colorFromARGBColor:cur->value->argb_color]
					  forKey:NSBackgroundColorAttributeName];
		
		else if (cur->type == attr_type_font_weight && cur->value->font_weight == attr_font_weight_bold)
			self.fontTraitsToAdd |= NSBoldFontMask;
		
		else if (cur->type == attr_type_font_style && cur->value->font_style == attr_font_style_italic)
			self.fontTraitsToAdd |= NSItalicFontMask;
		
		else if (cur->type == attr_type_font_size_pt)
			fontSize = (CGFloat)cur->value->font_size_pt;
		
		else if (cur->type == attr_type_font_family)
			fontName = [NSString stringWithUTF8String:cur->value->font_family];
		
		cur = cur->next;
	}
	
	if (fontName != nil || 0 < fontSize)
	{
		if (fontName == nil)
			fontName = @"Helvetica";
		[toAdd setObject:[NSFont fontWithName:fontName size:fontSize]
				  forKey:NSFontAttributeName];
	}
	
	self.attributesToAdd = toAdd;
	self.attributesToRemove = nil;
	
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
