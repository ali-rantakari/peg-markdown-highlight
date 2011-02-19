
#include "markdown_parser.h"

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
}






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
    if (charbuf && *charbuf != '\0') {               \
        yyc= *charbuf++;                             \
    } else {                                         \
        yyc= EOF;                                    \
    }                                                \
    result= (EOF == yyc) ? 0 : (*(buf)= yyc, 1);     \
}



