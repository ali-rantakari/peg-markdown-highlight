
#import <Foundation/Foundation.h>
#import "ANSIEscapeHelper.h"
#import "markdown_parser.h"

/* process_raw_blocks - traverses an element list, replacing any RAW elements with
 * the result of parsing them as markdown text, and recursing into the children
 * of parent elements.  The result should be a tree of elements without any RAWs. */
/*
static element * process_raw_blocks2(element *input, int extensions, element *references, element *notes) {
    element *current = NULL;
    element *last_child = NULL;
    char *contents;
    current = input;

    while (current != NULL) {
        if (current->key == RAW) {
            // \001 is used to indicate boundaries between nested lists when there
            // is no blank line.  We split the string by \001 and parse
            // each chunk separately.
            contents = strtok(current->contents.str, "\001");
            current->key = LIST;
            current->children = parse_markdown(contents, extensions, references, notes);
            last_child = current->children;
            while ((contents = strtok(NULL, "\001"))) {
                while (last_child->next != NULL)
                    last_child = last_child->next;
                last_child->next = parse_markdown(contents, extensions, references, notes);
            }
            free(current->contents.str);
            current->contents.str = NULL;
        }
        if (current->children != NULL)
            current->children = process_raw_blocks2(current->children, extensions, references, notes);
        current = current->next;
    }
    return input;
}
*/

element ** process_raw_blocks(char *text, element *elem[], int extensions)
{
	element *cursor = elem[RAW];
	while (cursor != NULL)
	{
		int len = cursor->end - cursor->pos;
		char *rawtext = malloc(len + 1);
		strncat(rawtext, text+cursor->pos, len);
		
		printf("process: (len %i, pos %ld) '%s'\n", len, cursor->pos, rawtext);
		elem = parse_markdown(rawtext, cursor->pos, extensions);
		
		free(rawtext);
		cursor = cursor->next;
	}
	return elem;
}

void print_raw_blocks(element *elem[])
{
	element *cursor = elem[RAW];
	while (cursor != NULL)
	{
		printf("raw: [%ld - %ld]\n", cursor->pos, cursor->end);
		cursor = cursor->next;
	}
}

void markdown_to_tree(char *text, int extensions, element **out[])
{
    element **result = parse_markdown(text, 0, extensions);
    
    print_raw_blocks(result);
    result = process_raw_blocks(text, result, extensions);
	
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
		if (i == RAW)
			continue;
		
		printf("applyHighlighting: %i\n", i);
		
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
				case EMPH:		fgColor = [NSColor yellowColor]; break;
				case STRONG:	fgColor = [NSColor magentaColor]; break;
				case CODE:
				case VERBATIM:	fgColor = [NSColor greenColor]; break;
				case HRULE:		fgColor = [NSColor cyanColor]; break;
				case ORDEREDLIST:
				case BULLETLIST:fgColor = [NSColor magentaColor]; break;
			}
			
			printf("  %i-%i\n", cursor->pos, cursor->end);
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
	int extensions = 0;
	element **result;
	markdown_to_tree((char *)[str UTF8String], extensions, &result);
	
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
		int extensions = 0;
		element **result;
		markdown_to_tree((char *)[contents UTF8String], extensions, &result);
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
