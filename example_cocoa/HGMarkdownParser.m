//
//  HGMarkdownParser.m
//  MDHExample
//
//  Created by Ali Rantakari on 28.2.11.
//  Copyright 2011 hasseg.org. All rights reserved.
//

#import "HGMarkdownParser.h"


// 'private members' category
@interface HGMarkdownParser ()

@property(retain) NSThread *workerThread;
@property(retain) NSMutableArray *queue;
@property(retain) HGMarkdownHighlighter *currentHighlightTarget;

@end


@implementation HGMarkdownParser

@synthesize workerThread;
@synthesize currentHighlightTarget;
@synthesize queue;

- (id) init
{
	if (!(self = [super init]))
		return nil;
	
	self.queue = [NSMutableArray array];
	self.workerThread = nil;
	self.currentHighlightTarget = nil;
	
	return self;
}

- (void) dealloc
{
	self.workerThread = nil;
	self.currentHighlightTarget = nil;
	self.queue = nil;
	[super dealloc];
}





- (element **) parse:(NSString *)content extensions:(int)extensions
{
	element **result = NULL;
	markdown_to_elements((char *)[content UTF8String], extensions, &result);
	sort_elements_by_pos(result);
	return result;
}



- (void) threadParseAndHighlight:(HGMarkdownHighlighter *)highlighter
{
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
	
	element **result = [self
						parse:[highlighter.targetTextView string]
						extensions:highlighter.extensions];
	
	[highlighter
	 performSelectorOnMainThread:@selector(parserDidParse:)
	 withObject:[NSValue valueWithPointer:result]
	 waitUntilDone:YES];
	
	[autoReleasePool drain];
}

- (void) threadDidExit:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:NSThreadWillExitNotification
	 object:self.workerThread];
	self.workerThread = nil;
	self.currentHighlightTarget = nil;
	[self
	 performSelectorOnMainThread:@selector(processNextFromQueue)
	 withObject:nil
	 waitUntilDone:NO];
}

- (void) processNextFromQueue
{
	if ([self.queue count] == 0 || self.workerThread != nil)
		return;
	
	HGMarkdownHighlighter *highlighter = [self.queue objectAtIndex:0];
	[self.queue removeObjectAtIndex:0];
	
	self.workerThread = [[NSThread alloc]
						 initWithTarget:self
						 selector:@selector(threadParseAndHighlight:)
						 object:highlighter];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(threadDidExit:)
	 name:NSThreadWillExitNotification
	 object:self.workerThread];
	
	self.currentHighlightTarget = highlighter;
	
	[self.workerThread start];
}

- (void) requestParsing:(HGMarkdownHighlighter *)sender
{
	if ([self.queue containsObject:sender] || self.currentHighlightTarget == sender)
		return;
	
	[self.queue addObject:sender];
	[self processNextFromQueue];
}
















#pragma mark -
#pragma mark Singleton implementation

static HGMarkdownParser *sharedInstance = NULL;

+ (HGMarkdownParser *) sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil)
			sharedInstance = [[HGMarkdownParser alloc] init];
    }
    return sharedInstance;
}

+ (id) allocWithZone:(NSZone *)zone
{
    @synchronized(self)
	{
        if (sharedInstance == nil)
		{
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    return nil;
}

- (id) copyWithZone:(NSZone *)zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (NSUInteger) retainCount
{
    return UINT_MAX;
}

- (void) release
{
    // do nothing
}

- (id) autorelease
{
    return self;
}


@end
