/* PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * markdown_definitions.h
 */

#ifndef MARKDOWN_DEFINITIONS
#define MARKDOWN_DEFINITIONS

/** \file
* \brief Global definitions for the parser.
*/


/**
* \brief Element types.
* 
* The first (documented) ones are language element types.
* 
* The last (non-documented) ones are utility types used
* by the parser itself.
* 
* \sa element
*/
typedef enum
{
	LINK,				/**< Link */
	AUTO_LINK_URL,		/**< Automatic URL link */
	AUTO_LINK_EMAIL,	/**< Automatic email link */
	IMAGE,				/**< Image definition */
	CODE,				/**< Code */
	HTML,				/**< HTML */
	HTML_ENTITY,		/**< HTML special entity definition */
	EMPH,				/**< Emphasized text */
	STRONG,				/**< Strong text */
	LIST_BULLET,		/**< Bullet for a list item */
	LIST_ENUMERATOR,	/**< Enumerator for a list item */
	COMMENT,			/**< (HTML) comment */
	
	/* Code assumes that H1-6 are in order. */
	H1,					/**< Header, level 1 */
	H2,					/**< Header, level 2 */
	H3,					/**< Header, level 3 */
	H4,					/**< Header, level 4 */
	H5,					/**< Header, level 5 */
	H6,					/**< Header, level 6 */
	
	BLOCKQUOTE,			/**< Blockquote */
	VERBATIM,			/**< Verbatim */
	HTMLBLOCK,			/**< .. */
	HRULE,				/**< Horizontal rule */
	REFERENCE,			/**< Reference */
	NOTE,				/**< Note */
	
	/* Utility types used by the parser itself: */
	RAW_LIST,	/* List of RAW element lists, each to be processed separately from others
				 * (for each element in linked lists of this type, `children` points
				 * to a linked list of RAW elements) */
	RAW,		/* Span marker for positions in original input to be post-processed
				 * in a second parsing step */
	EXTRA_TEXT, /* Additional text to be parsed along with spans in the original input
				 * (these may be added to linked lists of RAW elements) */
	SEPARATOR,	/* Separates linked lists of RAW elements into parts to be processed
				 * separate from each other */
	NO_TYPE,	/* Placeholder element used while parsing */
	ALL			/* Linked list of *all* elements created while parsing */
} element_type;

/**
* \brief Number of types in element_type.
* \sa element_type
*/
#define NUM_TYPES 30

/**
* \brief Number of *language element* types in element_type.
* \sa element_type
*/
#define NUM_LANG_TYPES (NUM_TYPES - 6)

/**
* \brief Semantic value of a parsing action.
*/
struct Element
{
	element_type type;			  /**< \brief type of element */
	unsigned long pos;			  /**< \brief start offset in input */
	unsigned long end;			  /**< \brief end offset in input */
	struct Element *next;		  /**< \brief next element in list */
	struct Element *allElemsNext; /**< \brief next element in list of all elements */
	int textOffset;               /**< \brief offset to text (for elements of type EXTRA_TEXT, used when the parser reads the value of 'text') */
	char *text;					  /**< \brief text content (for elements of type EXTRA_TEXT) */
	char *label;				  /**< \brief label (for links and references) */
	char *address;                /**< \brief address (for links and references) */
	struct Element *children;	  /**< \brief children of element (for elements of type RAW_LIST) */
};
typedef struct Element element;

/**
* \brief Bitfield enumeration of supported Markdown extensions.
*/
enum markdown_extensions
{
    EXT_NONE    = 0,        /**< No extensions */
	EXT_NOTES   = (1 << 0)  /**< A footnote syntax like that of Pandoc or PHP Markdown Extra */
};

#endif
