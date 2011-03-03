
#include "markdown_parser.h"

element ** parse_markdown(char *string, element *elem, int extensions);


void remove_zero_length_raw_spans(element *elem)
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
			parent = c;
			c = c->next;
			continue;
		}
		parent = c;
		c = c->next;
	}
}

// Print null-terminated string s.t. some characters are
// represented by their corresponding espace sequences
void print_str_literal_escapes(char *str)
{
	char *c = str;
	MKD_PRINTF("'");
	while (*c != '\0')
	{
		if (*c == '\n')			MKD_PRINTF("\\n");
		else if (*c == '\t')	MKD_PRINTF("\\t");
		else putchar(*c);
		c++;
	}
	MKD_PRINTF("'");
}

// Print elements in a linked list of
// RAW, SEPARATOR, EXTRA_TEXT elements
void print_raw_spans_inline(element *elem)
{
	element *cur = elem;
	while (cur != NULL)
	{
		if (cur->type == SEPARATOR)
			MKD_PRINTF("<SEP %ld> ", cur->pos);
		else if (cur->type == EXTRA_TEXT) {
			MKD_PRINTF("{ETEXT "); print_str_literal_escapes(cur->text); MKD_PRINTF("}");
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
			
			remove_zero_length_raw_spans(span_list);
			
			#if MKD_DEBUG_OUTPUT
			MKD_PRINTF("  process: "); print_raw_spans_inline(span_list); MKD_PRINTF("\n");
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
				MKD_PRINTF("    subspan process: "); print_raw_spans_inline(subspan_list); MKD_PRINTF("\n");
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
		print_raw_spans_inline(cursor->children);
		cursor = cursor->next;
	}
}










// Buffer of characters to be parsed:
static char *charbuf = "";

// Linked list of {start, end} offset pairs determining which parts
// of charbuf to actually parse:
static element *p_elem;
static element *p_elem_head;

// Current parsing offset within charbuf:
static int p_offset;

// The extensions to use for parsing (bitfield
// of enum markdown_extensions):
static int p_extensions;

// Array of parsing result elements, indexed by type:
element **head_elements;

// Free all elements created while parsing
void free_elements(element **elems)
{
	element *cursor = elems[ALL];
	while (cursor != NULL) {
		element *old = cursor;
		cursor = cursor->allElemsNext;
		free(old);
	}
	elems[ALL] = NULL;
	
	free(elems);
}








#define IS_CONTINUATION_BYTE(x)		((x & 0xc0) == 0x80)

char *strcpy_without_continuation_bytes(char *str)
{
	char *new_str = malloc(sizeof(char)*strlen(str) +1);
	char *c = str;
	int i = 0;
	while (*c != '\0')
	{
		if (!IS_CONTINUATION_BYTE(*c))
			*(new_str+i) = *c, i++;
		c++;
	}
	*(new_str+i) = '\0';
	
	return new_str;
}

void markdown_to_elements(char *text, int extensions, element **out_result[])
{
	char *text_copy = strcpy_without_continuation_bytes(text);
	
	head_elements = malloc(sizeof(element**)*NUM_TYPES);
	int i;
	for (i = 0; i < NUM_TYPES; i++)
		head_elements[i] = NULL;
	
	element *parsing_elem = malloc(sizeof(element));
	parsing_elem->type = RAW;
	parsing_elem->pos = 0;
	parsing_elem->end = strlen(text_copy)-1;
	parsing_elem->next = NULL;
    element **result = parse_markdown(text_copy, parsing_elem, extensions);
    free(parsing_elem);
    
    #if MKD_DEBUG_OUTPUT
    print_raw_blocks(text_copy, result);
    #endif
    
    result = process_raw_blocks(text_copy, result, extensions);
    
    *out_result = result;
    free(text_copy);
}








char *type_name(element_type type)
{
	switch (type)
	{
		case SEPARATOR:			 return "SEPARATOR"; break;
		case EXTRA_TEXT:		 return "EXTRA_TEXT"; break;
		case NO_TYPE:			 return "NO TYPE"; break;
		case RAW_LIST:			 return "RAW_LIST"; break;
		case RAW:                return "RAW"; break;
		
		case SINGLEQUOTED:       return "SINGLEQUOTED"; break;
		case DOUBLEQUOTED:       return "DOUBLEQUOTED"; break;
		case LINK:               return "LINK"; break;
		case IMAGE:              return "IMAGE"; break;
		case CODE:               return "CODE"; break;
		case HTML:               return "HTML"; break;
		case EMPH:               return "EMPH"; break;
		case STRONG:             return "STRONG"; break;
		case LIST_BULLET:        return "LIST_BULLET"; break;
		case LIST_ENUMERATOR:    return "LIST_ENUMERATOR"; break;
		case H1:                 return "H1"; break;
		case H2:                 return "H2"; break;
		case H3:                 return "H3"; break;
		case H4:                 return "H4"; break;
		case H5:                 return "H5"; break;
		case H6:                 return "H6"; break;
		case BLOCKQUOTE:         return "BLOCKQUOTE"; break;
		case VERBATIM:           return "VERBATIM"; break;
		case HTMLBLOCK:          return "HTMLBLOCK"; break;
		case HRULE:              return "HRULE"; break;
		case REFERENCE:          return "REFERENCE"; break;
		case NOTE:               return "NOTE"; break;
		default:                 return "?";
	}
}

// return true if extension is selected
bool extension(int ext)
{
    return (p_extensions & ext);
}


// cons an element/list onto a list, returning pointer to new head
static element * cons(element *elem, element *list)
{
    assert(elem != NULL);
    
    element *cur = elem;
    while (cur->next != NULL) {
    	cur = cur->next;
    }
    cur->next = list;
    
    return elem;
}


// reverse a list, returning pointer to new list
static element *reverse(element *list)
{
    element *new_head = NULL;
    element *next = NULL;
    while (list != NULL) {
    	next = list->next;
    	list->next = new_head;
    	new_head = list;
    	list = next;
    }
    return new_head;
}



// construct element
element * mk_element(element_type type, long pos, long end)
{
    element *result = malloc(sizeof(element));
    result->type = type;
    result->pos = pos;
    result->end = end;
    result->next = NULL;
    
    element *old_all_elements_head = head_elements[ALL];
    head_elements[ALL] = result;
    result->allElemsNext = old_all_elements_head;
    
	MKD_PRINTF("  mk_element: %s [%ld - %ld]\n", type_name(type), pos, end);
	
    return result;
}

// construct EXTRA_TEXT element
element * mk_etext(char *string)
{
    element *result;
    assert(string != NULL);
    result = mk_element(EXTRA_TEXT, 0,0);
    result->text = strdup(string);
    return result;
}


// Given an element where the offsets {pos, end} represent
// locations in the *parsed text* (defined by the linked list of RAW and
// EXTRA_TEXT elements in p_elem), fix these offsets to represent
// corresponding offsets in the original input (charbuf).
void fix_offsets(element *elem)
{
	if (elem->type == EXTRA_TEXT)
		return;
	
	int new_pos = -1;
	int new_end = -1;
	
	int previous_end = 0;
	int c = 0;
	element *cursor = p_elem_head;
	while (cursor != NULL)
	{
		int thislen = (cursor->type == EXTRA_TEXT)
						? strlen(cursor->text)
						: cursor->end - cursor->pos;
		
		if (new_pos == -1 && (c <= elem->pos && elem->pos <= c+thislen)) {
			new_pos = (cursor->type == EXTRA_TEXT)
						? previous_end
						: cursor->pos + (elem->pos - c);
		}
		
		if (new_end == -1 && (c <= elem->end && elem->end <= c+thislen)) {
			new_end = (cursor->type == EXTRA_TEXT)
						? previous_end
						: cursor->pos + (elem->end - c);
		}
		
		if (new_pos != -1 && new_end != -1)
			break;
		
		if (cursor->type != EXTRA_TEXT)
			previous_end = cursor->end;
		c += thislen;
		cursor = cursor->next;
	}
	
	elem->pos = new_pos;
	elem->end = new_end;
}


// Add an element to head_elements.
void add(element *elem)
{
	if (head_elements[elem->type] == NULL)
		head_elements[elem->type] = elem;
	else
	{
		elem->next = head_elements[elem->type];
		head_elements[elem->type] = elem;
	}
	
	// TODO: split into parts instead of just fixing offsets
	// (so that the color span would be disjoint just as the
	// text in the input is, like:)
	// > text HIGHLIGHTING
	// > CONTINUES text
	if (elem->type != RAW_LIST) {
		MKD_PRINTF("  add: %s [%ld - %ld]\n", type_name(elem->type), elem->pos, elem->end);
		fix_offsets(elem);
		MKD_PRINTF("     : %s [%ld - %ld]\n", type_name(elem->type), elem->pos, elem->end);
	}
	else {
		MKD_PRINTF("  add: RAW_LIST ");
		element *cursor = elem->children;
		while (cursor != NULL) {
			MKD_PRINTF("(%ld-%ld)>", cursor->pos, cursor->end);
			fix_offsets(cursor);
			MKD_PRINTF("(%ld-%ld) ", cursor->pos, cursor->end);
			cursor = cursor->next;
		}
		MKD_PRINTF("\n");
	}
}

element * add_element(element_type type, long pos, long end)
{
	element *new_element = mk_element(type, pos, end);
	add(new_element);
	return new_element;
}

void add_raw(long pos, long end)
{
	add_element(RAW, pos, end);
}



/**********************************************************************

  Definitions for leg parser generator.
  YY_INPUT is the function the parser calls to get new input.
  We take all new input from (static) charbuf.

 ***********************************************************************/

# define YYSTYPE element *
#ifdef __DEBUG__
# define YY_DEBUG 1
#endif

#define YY_INPUT(buf, result, max_size)              \
{                                                    \
    if (p_elem == NULL) {              \
    	result = 0;                    \
    } else {                           \
    	if (p_elem->type == EXTRA_TEXT) {\
    		int yyc;\
    		if (p_elem->text && *p_elem->text != '\0') {\
    			yyc = *p_elem->text++;\
				MKD_PRINTF("\e[47;30m"); MKD_PUTCHAR(yyc); MKD_PRINTF("\e[0m");\
				if (yyc == '\n') MKD_PRINTF("\e[47m \e[0m");\
    		} else {\
    			yyc = EOF;\
    			p_elem = p_elem->next;\
				MKD_PRINTF("\e[41m \e[0m");\
				if (p_elem != NULL) p_offset = p_elem->pos;\
    		}\
    		result = (EOF == yyc) ? 0 :(*(buf) = yyc, 1);\
    	} else {\
    		*(buf) = *(charbuf+p_offset);  \
			result = 1;                    \
			p_offset++;                    \
			MKD_PRINTF("\e[43;30m"); MKD_PUTCHAR(*buf); MKD_PRINTF("\e[0m");\
			if (*buf == '\n') MKD_PRINTF("\e[42m \e[0m");\
			if (p_offset >= p_elem->end) {  \
				p_elem = p_elem->next;     \
				MKD_PRINTF("\e[41m \e[0m");\
				if (p_elem != NULL) p_offset = p_elem->pos;\
			}                              \
		} \
	}                                  \
}


