
#import <Foundation/Foundation.h>
#import "ANSIEscapeHelper.h"
#import "markdown_parser.h"


void removeZeroLengthRAWSpans(element *elem)
{
	element *parent = NULL;
	element *c = elem;
	while (c != NULL)
	{
		if (c->type == RAW && c->pos >= c->end)
		{
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

// Print null-terminated string s.t. some characters are
// represented by their corresponding espace sequences
void printStrEscapes(char *str)
{
	char *c = str;
	MKD_PRINTF("'");
	while (*c != '\0')
	{
		if (*c == '\n')			MKD_PRINTF("\\n");
		else if (*c == '\e')	MKD_PRINTF("\\e");
		else if (*c == '\t')	MKD_PRINTF("\\t");
		else putchar(*c);
		c++;
	}
	MKD_PRINTF("'");
}

// Print elements in a linked list of
// RAW, SEPARATOR, EXTRA_TEXT elements
void printSpansInline(element *elem)
{
	element *cur = elem;
	while (cur != NULL) {
		if (cur->type == SEPARATOR)
			MKD_PRINTF("<SEP %ld> ", cur->pos);
		else if (cur->type == EXTRA_TEXT) {
			MKD_PRINTF("{ETEXT "); printStrEscapes(cur->text); MKD_PRINTF("}");
		}
		else
			MKD_PRINTF("(%ld-%ld) ", cur->pos, cur->end);
		cur = cur->next;
	}
}

// Perform postprocessing parsing runs for RAW_LIST elements in `elem`,
// iteratively until no such elements exist.
element ** process_raw_blocks(char *text, element *elem[], int extensions)
{
	MKD_PRINTF("--------process_raw_blocks---------\n");
	while (elem[RAW_LIST] != NULL)
	{
		MKD_PRINTF("new iteration.\n");
		element *cursor = elem[RAW_LIST];
		elem[RAW_LIST] = NULL;
		while (cursor != NULL)
		{
			element *span_list = cursor->children;
			
			removeZeroLengthRAWSpans(span_list);
			
			#if MKD_DEBUG_OUTPUT
			MKD_PRINTF("  process: "); printSpansInline(span_list); MKD_PRINTF("\n");
			#endif
			
			while (span_list != NULL)
			{
				MKD_PRINTF("next: span_list: %ld-%ld\n", span_list->pos, span_list->end);
				
				element *subspan_list = span_list;
				element *previous = NULL;
				while (span_list != NULL && span_list->type != SEPARATOR) {
					previous = span_list;
					span_list = span_list->next;
				}
				if (span_list != NULL && span_list->type == SEPARATOR) {
					span_list = span_list->next;
					previous->next = NULL;
				}
				
				#if MKD_DEBUG_OUTPUT
				MKD_PRINTF("    subspan process: "); printSpansInline(subspan_list); MKD_PRINTF("\n");
				#endif
				
				parse_markdown(text, subspan_list, extensions);
				MKD_PRINTF("parse over\n");
			}
			
			cursor = cursor->next;
		}
	}
	return elem;
}

void print_raw_blocks(char *text, element *elem[])
{
	MKD_PRINTF("--------print_raw_blocks---------\n");
	MKD_PRINTF("block:\n");
	element *cursor = elem[RAW_LIST];
	while (cursor != NULL)
	{
		printSpansInline(cursor->children);
		cursor = cursor->next;
	}
}

void markdown_to_elements(char *text, int extensions, element **out[])
{
	element *parsing_elem = malloc(sizeof(element));
	parsing_elem->pos = 0;
	parsing_elem->end = strlen(text)-1;
	parsing_elem->next = NULL;
    element **result = parse_markdown(text, parsing_elem, extensions);
    free(parsing_elem);
    
    #if MKD_DEBUG_OUTPUT
    print_raw_blocks(text, result);
    #endif
    
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
				case AUTO_LINK_URL:      typeStr = "AUTO_LINK_URL"; break;
				case AUTO_LINK_EMAIL:    typeStr = "AUTO_LINK_EMAIL"; break;
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
            MKD_PRINTF("[%ld-%ld] 0x%x: %s\n", cursor->pos, cursor->end, (int)cursor, typeStr);
			
			cursor = cursor->next;
		}
	}
}

void applyHighlighting(NSMutableAttributedString *attrStr, element *elem[])
{
	int sourceLength = [attrStr length];
	
	int order[] = {
		H1, H2, H3, H4, H5, H6,  
		ELLIPSIS,
		EMDASH,
		ENDASH,
		APOSTROPHE,
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
		PLAIN,
		PARA,
		LISTITEM,
		BULLETLIST,
		ORDEREDLIST,
		BLOCKQUOTE,
		VERBATIM,
		HTMLBLOCK,
		HRULE,
		REFERENCE,
		NOTE
	};
	
	for (int i = 0; i < 31; i++)
	{
		//MKD_PRINTF("applyHighlighting: %i\n", i);
		
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
				case ORDEREDLIST:
				case BULLETLIST:fgColor = [NSColor magentaColor]; break;
				case AUTO_LINK_EMAIL:
				case AUTO_LINK_URL:fgColor = [NSColor cyanColor]; break;
				case IMAGE:
				case LINK:		bgColor = [NSColor blackColor];
								fgColor = [NSColor cyanColor]; break;
				case BLOCKQUOTE:removeBgColor = YES;
								fgColor = [NSColor magentaColor]; break;
				default: break;
			}
			
			//MKD_PRINTF("  %i-%i\n", cursor->pos, cursor->end);
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

NSAttributedString *highlight(NSString *str)
{
	int extensions = 0;
	element **result;
	markdown_to_elements((char *)[str UTF8String], extensions, &result);
	
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
		markdown_to_elements((char *)[contents UTF8String], extensions, &result);
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
