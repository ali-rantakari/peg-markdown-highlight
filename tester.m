
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

void printStr(char *str, int max_chars)
{
	char *c = str;
	int i = max_chars;
	printf("'");
	while (i > 0 && *c != EOF)
	{
		putchar(*c);
		i--; c++;
	}
	printf("'\n");
}
/*
element ** process_raw_blocks(char *text, element *elem[], int extensions)
{
	while (elem[RAW] != NULL)
	{
		element *cursor = elem[RAW];
		elem[RAW] = NULL;
		while (cursor != NULL)
		{
			long len = cursor->end - cursor->pos;
			//char *rawtext = malloc((len + 1) * sizeof(char));
			//strncat(rawtext, text+cursor->pos, len);
			
			printf("process: (len %ld, pos %ld) ", len, cursor->pos);
			printStr(text+cursor->pos, len);
			elem = parse_markdown(text+cursor->pos, cursor->pos, len, extensions);
			
			//free(rawtext);
			cursor = cursor->next;
		}
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
*/

void removeZeroLengthSpans(element *elem)
{
	element *parent = NULL;
	element *c = elem;
	while (c != NULL)
	{
		if (c->pos >= c->end) {
			if (parent != NULL) {
				parent->next = c->next;
			} else {
				elem = c->next;
			}
			element *oldc = c;
			parent = c;
			c = c->next;
			free(oldc);
			continue;
		}
		parent = c;
		c = c->next;
	}
}

element ** process_raw_blocks(char *text, element *elem[], int extensions)
{
	printf("--------process_raw_blocks---------\n");
	while (elem[RAW_LIST] != NULL)
	{
		printf("new iteration.\n");
		element *cursor = elem[RAW_LIST];
		elem[RAW_LIST] = NULL;
		while (cursor != NULL)
		{
			removeZeroLengthSpans(cursor->children);
			
			printf("  process: ");
			element *cur = cursor->children;
			while (cur != NULL) {
				printf("(%ld-%ld) ", cur->pos, cur->end);
				cur = cur->next;
			}
			printf("\n");
			
			element **result = parse_markdown(text, cursor->children, extensions);
			cursor = cursor->next;
		}
	}
	return elem;
}

void print_raw_blocks(char *text, element *elem[])
{
	printf("--------print_raw_blocks---------\n");
	printf("block:\n");
	element *cursor = elem[RAW_LIST];
	while (cursor != NULL)
	{
		element *child = cursor->children;
		while (child != NULL)
		{
			printf("  [%ld - %ld]\n", child->pos, child->end);
			child = child->next;
		}
		cursor = cursor->next;
	}
}

void markdown_to_tree(char *text, int extensions, element **out[])
{
	element *parsing_elem = malloc(sizeof(element));
	parsing_elem->pos = 0;
	parsing_elem->end = strlen(text)-1;
	parsing_elem->next = NULL;
    element **result = parse_markdown(text, parsing_elem, extensions);
    free(parsing_elem);
    
    print_raw_blocks(text, result);
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
				case RAW_LIST:			 typeStr = "RAW_LIST"; break;
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
	int sourceLength = [attrStr length];
	
	for (int i = 0; i < 34; i++)
	{
		if (i == RAW_LIST)
			continue;
		
		//printf("applyHighlighting: %i\n", i);
		
		element *cursor = elem[i];
		while (cursor != NULL)
		{
			if (cursor->end <= cursor->pos)
				goto next;
			
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
			
			//printf("  %i-%i\n", cursor->pos, cursor->end);
			if (fgColor != nil) {
				int rangePos = MIN(MAX(cursor->pos, 0), sourceLength);
				int len = cursor->end - cursor->pos;
				if (rangePos+len > sourceLength)
					len = sourceLength-rangePos;
				NSRange range = NSMakeRange(rangePos, len);
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
