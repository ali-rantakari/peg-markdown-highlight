
#import <Foundation/Foundation.h>
#import "ANSIEscapeHelper.h"
#import "mkd_types.h"


void Print(NSString *aStr)
{
	[aStr writeToFile:@"/dev/stdout" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}


void applyHighlighting(NSMutableAttributedString *attrStr, element *elem[])
{
	int sourceLength = [attrStr length];
	
	int order[] = {
		H1, H2, H3, H4, H5, H6,  
		SINGLEQUOTED,
		DOUBLEQUOTED,
		LINK,
		AUTO_LINK_URL,
		AUTO_LINK_EMAIL,
		IMAGE,
		HTML,
		EMPH,
		STRONG,
		CODE,
		LIST_BULLET,
		LIST_ENUMERATOR,
		BLOCKQUOTE,
		VERBATIM,
		HTMLBLOCK,
		HRULE,
		REFERENCE,
		NOTE
	};
	int order_len = 24;
	
	for (int i = 0; i < order_len; i++)
	{
		element *cursor = elem[order[i]];
		while (cursor != NULL)
		{
			if (cursor->end <= cursor->pos)
				goto next;
			
			NSColor *fgColor = nil;
			NSColor *bgColor = nil;
			BOOL removeFgColor = NO;
			BOOL removeBgColor = NO;
			
			switch (cursor->type)
			{
				case H1:
				case H2:
				case H3:
				case H4:
				case H5:
				case H6:		fgColor = [NSColor blueColor]; break;
				case EMPH:		fgColor = [NSColor yellowColor]; break;
				case STRONG:	fgColor = [NSColor magentaColor]; break;
				case CODE:
				case VERBATIM:	fgColor = [NSColor greenColor]; break;
				case HRULE:		fgColor = [NSColor cyanColor]; break;
				case LIST_ENUMERATOR:
				case LIST_BULLET:fgColor = [NSColor magentaColor]; break;
				case AUTO_LINK_EMAIL:
				case AUTO_LINK_URL:fgColor = [NSColor cyanColor]; break;
				case IMAGE:
				case LINK:		bgColor = [NSColor blackColor];
								fgColor = [NSColor cyanColor]; break;
				case BLOCKQUOTE:removeBgColor = YES;
								fgColor = [NSColor magentaColor]; break;
				default: break;
			}
			
			if (fgColor != nil || bgColor != nil) {
				int rangePos = MIN(MAX(cursor->pos, 0), sourceLength);
				int len = cursor->end - cursor->pos;
				if (rangePos+len > sourceLength)
					len = sourceLength-rangePos;
				NSRange range = NSMakeRange(rangePos, len);
				
				if (removeBgColor)
					[attrStr
						removeAttribute:NSBackgroundColorAttributeName
						range:range
						];
				else if (bgColor != nil)
					[attrStr
						addAttribute:NSBackgroundColorAttributeName
						value:bgColor
						range:range
						];
				
				if (removeFgColor)
					[attrStr
						removeAttribute:NSForegroundColorAttributeName
						range:range
						];
				else if (fgColor != nil)
					[attrStr
						addAttribute:NSForegroundColorAttributeName
						value:fgColor
						range:range
						];
			}
			
			next:
			cursor = cursor->next;
		}
	}
}

element * mk_element(int type, long pos, long end)
{
    element *result = malloc(sizeof(element));
    result->type = type;
    result->pos = pos;
    result->end = end;
    result->next = NULL;
    return result;
}


element **getHighlightElements(NSString *markdown_str)
{
	element **elements = malloc(sizeof(element*) * NUM_TYPES);
	for (int i = 0; i < NUM_TYPES; i++)
		elements[i] = NULL;
	
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"highlighter"];
	
	NSPipe *inPipe = [NSPipe pipe];
	NSPipe *outPipe = [NSPipe pipe];
	NSPipe *errPipe = [NSPipe pipe];
	[task setStandardInput:inPipe];
	[task setStandardOutput:outPipe];
	[task setStandardError:errPipe];
	NSFileHandle *inHandle = [inPipe fileHandleForWriting];
	NSFileHandle *outHandle = [outPipe fileHandleForReading];
	NSFileHandle *errHandle = [errPipe fileHandleForReading];
	
	[task launch];
	
	NSData *inputData = [markdown_str dataUsingEncoding:NSUTF8StringEncoding];
	[inHandle writeData:inputData];
	[inHandle closeFile];
	
	NSData *outData = nil;
	NSData *errData = nil;
	
	outData = [outHandle readDataToEndOfFile];
	errData = [errHandle readDataToEndOfFile];
	[outHandle closeFile];
	[errHandle closeFile];
	
	[task waitUntilExit];
	
	if (errData && [errData length] > 0)
		NSLog(@"stderr: %@", [[[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding] autorelease]);
	int exitStatus = [task terminationStatus];
	
	if (exitStatus != 0) {
		NSLog(@"highlighter exited with status: %i", exitStatus);
	} else {
		//Print([[[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding] autorelease]);
		//Print(@"\n--------\n");
		
		NSString *outStr = [[[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding] autorelease];
		
		NSCharacterSet *digitsSet = [NSCharacterSet decimalDigitCharacterSet];
		NSMutableCharacterSet *digitsOrPipeSet = [NSMutableCharacterSet decimalDigitCharacterSet];
		[digitsOrPipeSet addCharactersInString:@"|"];
		
		NSScanner *scanner = [NSScanner scannerWithString:outStr];
		while (![scanner isAtEnd])
		{
			int type = NO_TYPE;
			[scanner scanUpToCharactersFromSet:digitsSet intoString:NULL];
			[scanner scanInt:&type];
			[scanner scanUpToCharactersFromSet:digitsSet intoString:NULL];
			while (![scanner isAtEnd] && [outStr characterAtIndex:[scanner scanLocation]] != '|')
			{
				int startIndex = -1;
				int endIndex = -1;
				[scanner scanInt:&startIndex];
				[scanner scanString:@"-" intoString:NULL];
				[scanner scanInt:&endIndex];
				[scanner scanUpToCharactersFromSet:digitsOrPipeSet intoString:NULL];
				
				element *new = mk_element(type, startIndex, endIndex);
				element *head = elements[type];
				elements[type] = new;
				new->next = head;
			}
		}
		
	}
	
	[task release];
	return elements;
}


int main(int argc, char * argv[])
{
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
	
	if (argc == 1)
	{
		Print(@"Argument must be path to file\n");
		return(0);
	}
	
	NSString *filePath = [NSString stringWithUTF8String:argv[argc-1]];
	NSString *contents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
	NSMutableAttributedString *attrStr = nil;
	
	int iterations = 1;
	if (argc > 2) {
		iterations = atoi(argv[1]);
		printf("Doing %i iterations.\n", iterations);
	}
	
	int stepProgress = 0;
	for (int i = 0; i < iterations; i++)
	{
		element **highlightElements = getHighlightElements(contents);
		attrStr = [[[NSMutableAttributedString alloc] initWithString:contents] autorelease];
		applyHighlighting(attrStr, highlightElements);
		
		if (stepProgress == 9) {
			Print(@"x");
			stepProgress = 0;
		} else {
			Print(@"-");
			stepProgress++;
		}
	}
	
	ANSIEscapeHelper *ansiHelper = [[[ANSIEscapeHelper alloc] init] autorelease];
	Print([ansiHelper ansiEscapedStringWithAttributedString:attrStr]);
	
	[autoReleasePool release];
    return(0);
}
