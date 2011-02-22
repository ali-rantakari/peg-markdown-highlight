
#include "markdown_parser.h"


static char *charbuf = "";     /* Buffer of characters to be parsed. */

// linked list of (start, end) offset pairs determining which parts
// of charbuf to parse
static element *p_elem;
static element *p_elem_head;
static int p_offset; // current parsing offset


char *typeName(int type)
{
	switch (type)
	{
		case SEPARATOR:			 return "SEPARATOR"; break;
		case EXTRA_TEXT:		 return "EXTRA_TEXT"; break;
		case NO_TYPE:			 return "NO TYPE"; break;
		case LIST:               return "LIST"; break;
		case RAW_LIST:			 return "RAW_LIST"; break;
		case RAW:                return "RAW"; break;
		case SPACE:              return "SPACE"; break;
		case LINEBREAK:          return "LINEBREAK"; break;
		case ELLIPSIS:           return "ELLIPSIS"; break;
		case EMDASH:             return "EMDASH"; break;
		case ENDASH:             return "ENDASH"; break;
		case APOSTROPHE:         return "APOSTROPHE"; break;
		case SINGLEQUOTED:       return "SINGLEQUOTED"; break;
		case DOUBLEQUOTED:       return "DOUBLEQUOTED"; break;
		case STR:                return "STR"; break;
		case LINK:               return "LINK"; break;
		case IMAGE:              return "IMAGE"; break;
		case CODE:               return "CODE"; break;
		case HTML:               return "HTML"; break;
		case EMPH:               return "EMPH"; break;
		case STRONG:             return "STRONG"; break;
		case PLAIN:              return "PLAIN"; break;
		case PARA:               return "PARA"; break;
		case LISTITEM:           return "LISTITEM"; break;
		case BULLETLIST:         return "BULLETLIST"; break;
		case ORDEREDLIST:        return "ORDEREDLIST"; break;
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

/* extension = returns true if extension is selected */
bool extension(int ext)
{
    return false;
}


/* cons - cons an element onto a list, returning pointer to new head */
static element * cons(element *new, element *list)
{
    assert(new != NULL);
    
    element *cur = new;
    while (cur->next != NULL) {
    	cur = cur->next;
    }
    cur->next = list;
    
    return new;
}

// add to end
element * conc(element *new, element *list)
{
    if (list == NULL) {
    	list = new;
    } else {
		element *cur = list;
		while (cur->next != NULL)
			cur = cur->next;
		cur->next = new;
    }
    return list;
}


/* reverse - reverse a list, returning pointer to new list */
static element *reverse(element *list)
{
    element *new = NULL;
    element *next = NULL;
    while (list != NULL) {
    	next = list->next;
    	list->next = new;
    	new = list;
    	list = next;
    }
    return new;
}




/* mk_element - generic constructor for element */
element * mk_element(int type, long pos, long end)
{
    element *result = malloc(sizeof(element));
    result->type = type;
    result->pos = pos;
    result->end = end;
    result->next = NULL;
    
	MKD_PRINTF("  mk_element: %s [%ld - %ld]\n", typeName(type), pos, end);
	
    return result;
}


void fixOffsets(element *elem)
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


element* head_elements[33];

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
		MKD_PRINTF("  add: %s [%ld - %ld]\n", typeName(elem->type), elem->pos, elem->end);
		fixOffsets(elem);
		MKD_PRINTF("     : %s [%ld - %ld]\n", typeName(elem->type), elem->pos, elem->end);
	}
	else {
		MKD_PRINTF("  add: RAW_LIST ");
		element *cursor = elem->children;
		while (cursor != NULL) {
			MKD_PRINTF("(%ld-%ld)>", cursor->pos, cursor->end);
			fixOffsets(cursor);
			MKD_PRINTF("(%ld-%ld) ", cursor->pos, cursor->end);
			cursor = cursor->next;
		}
		MKD_PRINTF("\n");
	}
}

element * add_element(int type, long pos, long end)
{
	element *new_element = mk_element(type, pos, end);
	add(new_element);
	return new_element;
}

void add_raw(long pos, long end)
{
	add_element(RAW, pos, end);
}

element * mk_etext(char *string)
{
    element *result;
    assert(string != NULL);
    result = mk_element(EXTRA_TEXT, 0,0);
    result->text = strdup(string);
    return result;
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

/*
#define YY_INPUT(buf, result, max_size)              \
{                                                    \
    int yyc;                                         \
    if (charbuf && *charbuf != '\0') {               \
        yyc= *charbuf++;                             \
    } else {                                         \
        yyc= EOF;                                    \
    }                                                \
    result= (EOF == yyc) ? 0 : (*(buf)= yyc, 1);     \
}
*/


