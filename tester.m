
#import <Foundation/Foundation.h>
#import "ANSIEscapeHelper.h"
#import "markdown_parser.h"

void markdown_to_tree(char *text, element **out[]) {
	int extensions = 0;
    element **result = parse_markdown(text, extensions);
	*out = result;
}

void print_result(element *elem[])
{
	for (int i = 0; i < 34; i++)
	{
		element *cursor = elem[i];
		while (cursor != NULL)
		{
			char *typeStr;
			switch (cursor->type)
			{
				case LIST:               typeStr = "LIST"; break;
				case RAW:                typeStr = "RAW"; break;
				case SPACE:              typeStr = "SPACE"; break;
				case LINEBREAK:          typeStr = "LINEBREAK"; break;
				case ELLIPSIS:           typeStr = "ELLIPSIS"; break;
				case EMDASH:             typeStr = "EMDASH"; break;
				case ENDASH:             typeStr = "ENDASH"; break;
				case APOSTROPHE:         typeStr = "APOSTROPHE"; break;
				case SINGLEQUOTED:       typeStr = "SINGLEQUOTED"; break;
				case DOUBLEQUOTED:       typeStr = "DOUBLEQUOTED"; break;
				case STR:                typeStr = "STR"; break;
				case LINK:               typeStr = "LINK"; break;
				case IMAGE:              typeStr = "IMAGE"; break;
				case CODE:               typeStr = "CODE"; break;
				case HTML:               typeStr = "HTML"; break;
				case EMPH:               typeStr = "EMPH"; break;
				case STRONG:             typeStr = "STRONG"; break;
				case PLAIN:              typeStr = "PLAIN"; break;
				case PARA:               typeStr = "PARA"; break;
				case LISTITEM:           typeStr = "LISTITEM"; break;
				case BULLETLIST:         typeStr = "BULLETLIST"; break;
				case ORDEREDLIST:        typeStr = "ORDEREDLIST"; break;
				case H1:                 typeStr = "H1"; break;
				case H2:                 typeStr = "H2"; break;
				case H3:                 typeStr = "H3"; break;
				case H4:                 typeStr = "H4"; break;
				case H5:                 typeStr = "H5"; break;
				case H6:                 typeStr = "H6"; break;
				case BLOCKQUOTE:         typeStr = "BLOCKQUOTE"; break;
				case VERBATIM:           typeStr = "VERBATIM"; break;
				case HTMLBLOCK:          typeStr = "HTMLBLOCK"; break;
				case HRULE:              typeStr = "HRULE"; break;
				case REFERENCE:          typeStr = "REFERENCE"; break;
				case NOTE:               typeStr = "NOTE"; break;
				default:                 typeStr = "?";
			}
            fprintf(stderr, "[%i-%i] 0x%x: %s\n", cursor->pos, cursor->end, (int)cursor, typeStr);
			
			cursor = cursor->next;
		}
	}
}

void applyHighlighting(NSMutableAttributedString *attrStr, element *elem[])
{
	for (int i = 0; i < 34; i++)
	{
		element *cursor = elem[i];
		while (cursor != NULL)
		{
			NSColor *fgColor = nil;
			
			switch (cursor->type)
			{
				case H1:
				case H2:
				case H3:
				case H4:
				case H5:
				case H6:		fgColor = [NSColor blueColor]; break;
				case EMPH:		fgColor = [NSColor cyanColor]; break;
				case STRONG:	fgColor = [NSColor redColor]; break;
				case VERBATIM:	fgColor = [NSColor greenColor]; break;
			}
			
			if (fgColor != nil)
				[attrStr
					addAttribute:NSForegroundColorAttributeName
					value:fgColor
					range:NSMakeRange(cursor->pos, cursor->end - cursor->pos)
					];
			
			cursor = cursor->next;
		}
	}
}

NSAttributedString *highlight(NSString *str)
{
	element **result;
	markdown_to_tree([str UTF8String], &result);
	
	NSMutableAttributedString *attrStr = [[[NSMutableAttributedString alloc] initWithString:str] autorelease];
	applyHighlighting(attrStr, result);
	
	return attrStr;
}


void Print(NSString *aStr)
{
	[aStr writeToFile:@"/dev/stdout" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
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
	
	if (strcmp(argv[1], "-d") == 0)
	{
		element **result;
		markdown_to_tree([contents UTF8String], &result);
		print_result(result);
	}
	else
	{
		ANSIEscapeHelper *ansiHelper = [[[ANSIEscapeHelper alloc] init] autorelease];
		Print([ansiHelper ansiEscapedStringWithAttributedString:highlight(contents)]);
	}
	
	[autoReleasePool release];
    return(0);
}
