
#include "markdown_parser.h"

static long parsing_offset = 0;

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


/* mk_element - generic constructor for element */
element * mk_element(int type, long pos, long end)
{
    element *result = malloc(sizeof(element));
    result->type = type;
    result->pos = pos;
    result->end = end;
    result->next = NULL;
    
	printf("  mk_element: %i (%s) [%ld - %ld] + %ld\n", type, typeName(type), pos, end, parsing_offset);
	
    return result;
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
	
    if (elem->type != NO_TYPE)
    {
    	elem->pos += parsing_offset;
    	elem->end += parsing_offset;
    }
	printf("  add: %i (%s) [%ld - %ld]\n", elem->type, typeName(elem->type), elem->pos, elem->end);
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



static bool useCounter = false;
static int counter = 0;
static char *charbuf = "";     /* Buffer of characters to be parsed. */

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
    int yyc;                                         \
    if ((!useCounter || counter > 0) && charbuf && *charbuf != '\0') {               \
        yyc= *charbuf++;                             \
    } else {                                         \
        yyc= EOF;                                    \
    }                                                \
    result= (EOF == yyc) ? 0 : (*(buf)= yyc, 1);     \
    if (useCounter) counter--;\
}



