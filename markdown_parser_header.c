
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
		case NO_TYPE:			 return "NO TYPE"; break;
		case LIST:               return "LIST"; break;
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
static element * cons(element *new, element *list) {
    assert(new != NULL);
    
    int c = 1;
    element *cur = new;
    while (cur->next != NULL) {
    	cur = cur->next;
    	c++;
    }
    cur->next = list;
    printf("  cons: added %i to list. result: ", c);
    cur = new;
    while (cur != NULL) {
    	printf("(%ld-%ld) ", cur->pos, cur->end);
    	cur = cur->next;
    }
    printf("\n");
    
    return new;
}

/* reverse - reverse a list, returning pointer to new list */
static element *reverse(element *list) {
	/*
    element *new = NULL;
    element *next = NULL;
    while (list != NULL) {
        next = list->next;
        new = cons(list, new);
        list = next;
    }
    return new;
    */
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
    
	printf("  mk_element: %s [%ld - %ld]\n", typeName(type), pos, end);
	
    return result;
}


void fixOffsets(element *elem)
{
	int new_pos = -1;
	int new_end = -1;
	
	int c = 0;
	element *cursor = p_elem_head;
	while (cursor != NULL)
	{
		int thislen = cursor->end - cursor->pos;
		
		if (new_pos == -1 && (c <= elem->pos < c+thislen))
			new_pos = cursor->pos + (elem->pos - c);
		if (new_end == -1 && (c <= elem->end < c+thislen))
			new_end = cursor->pos + (elem->end - c);
		
		if (new_pos != -1 && new_end != -1)
			break;
		
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
	
	printf("  add: %s [%ld - %ld]\n", typeName(elem->type), elem->pos, elem->end);
	// TODO: split into parts instead of just fixing offsets
	fixOffsets(elem);
	printf("     : %s [%ld - %ld]\n", typeName(elem->type), elem->pos, elem->end);
}

element * add_element(int type, long pos, long end)
{
	element *new_element = mk_element(type, pos, end);
	add(new_element);
	return new_element;
}

void add_raw(long pos, long end)
{
	element *elem = add_element(RAW, pos, end);
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
    	*(buf) = *(charbuf+p_offset);  \
    	result = 1;                    \
		p_offset++;                    \
		if (p_offset > p_elem->end) {  \
			p_elem = p_elem->next;     \
			if (p_elem != NULL) p_offset = p_elem->pos;\
		}                              \
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


