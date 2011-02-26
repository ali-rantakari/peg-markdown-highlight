
#include <stdbool.h>
#include <stdlib.h>
#include <assert.h>

#ifndef MKD_DEBUG_OUTPUT
#define MKD_DEBUG_OUTPUT 1
#endif

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

// Element types
enum types
{
	SINGLEQUOTED,
	DOUBLEQUOTED,
	LINK,
	AUTO_LINK_URL,
	AUTO_LINK_EMAIL,
	IMAGE,
	CODE,
	HTML,
	EMPH,
	STRONG,
	PLAIN,
	BULLETLIST,
	ORDEREDLIST,
	H1, H2, H3, H4, H5, H6,  // Code assumes that these are in order.
	BLOCKQUOTE,
	VERBATIM,
	HTMLBLOCK,
	HRULE,
	REFERENCE,
	NOTE,
	
	// The following are not language element types; they're
	// 'utility types' only used by the parser itself.
	
	RAW_LIST,	// List of RAW element lists, each to be processed separately from others
	RAW,    	// Span marker for positions in original input to be post-processed
				// in a second parsing step
	EXTRA_TEXT,	// Additional text to be parsed along with spans in the original input
				// (these may be added to linked lists of RAW elements)
	SEPARATOR,	// Separates linked lists of RAW elements into parts to be processed
				// separately from each other
	NO_TYPE
};

#define NUM_TYPES 40


// Semantic value of a parsing action.
struct Element
{
    enum types        type;
    long              pos; // start offset in input
    long              end; // end offset in input
    char              *text;
    struct Element    *next;
    struct Element    *children;
};
typedef struct Element element;


// see implementation for docs
element ** parse_markdown(char *string, element *elem, int extensions);
void markdown_to_elements(char *text, int extensions, element **out[]);
char *typeName(enum types type);

