
#include <stdbool.h>
#include <stdlib.h>
#include <assert.h>

#define MKD_DEBUG_OUTPUT 1

#if MKD_DEBUG_OUTPUT
#define MKD_PRINTF(x, args...)	fprintf(stderr, x, ##args)
#define MKD_PUTCHAR(x)			putchar(x)
#else
#define MKD_PRINTF(x, args...)
#define MKD_PUTCHAR(x)
#endif


enum markdown_extensions {
    EXT_SMART            = 0x01,
    EXT_NOTES            = 0x02,
    EXT_FILTER_HTML      = 0x04,
    EXT_FILTER_STYLES    = 0x08
};

/* Types of semantic values returned by parsers. */ 
enum types
{
	NO_TYPE,
	SEPARATOR,
	EXTRA_TEXT,
	LIST,   /* A generic list of values.  For ordered and bullet lists, see below. */
	RAW_LIST,
	RAW,    /* Raw markdown to be processed further */
	SPACE,
	LINEBREAK,
	ELLIPSIS,
	EMDASH,
	ENDASH,
	APOSTROPHE,
	SINGLEQUOTED,
	DOUBLEQUOTED,
	STR,
	LINK,
	AUTO_LINK_URL,
	AUTO_LINK_EMAIL,
	IMAGE,
	CODE,
	HTML,
	EMPH,
	STRONG,
	PLAIN,
	PARA,
	LISTITEM,
	BULLETLIST,
	ORDEREDLIST,
	H1, H2, H3, H4, H5, H6,  /* Code assumes that these are in order. */
	BLOCKQUOTE,
	VERBATIM,
	HTMLBLOCK,
	HRULE,
	REFERENCE,
	NOTE
};

#define NUM_TYPES 37;


/* Semantic value of a parsing action. */
struct Element
{
    int               type;
    long              pos;
    long              end;
    char              *text;
    struct Element    *next;
    struct Element    *children;
};
typedef struct Element element;


element ** parse_markdown(char *string, element *elem, int extensions);

