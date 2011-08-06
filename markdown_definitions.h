/* PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * markdown_definitions.h
 */

#ifndef pmh_MARKDOWN_DEFINITIONS
#define pmh_MARKDOWN_DEFINITIONS

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
    pmh_LINK,               /**< Link */
    pmh_AUTO_LINK_URL,      /**< Automatic pmh_URL link */
    pmh_AUTO_LINK_EMAIL,    /**< Automatic email link */
    pmh_IMAGE,              /**< Image definition */
    pmh_CODE,               /**< Code */
    pmh_HTML,               /**< pmh_HTML */
    pmh_HTML_ENTITY,        /**< pmh_HTML special entity definition */
    pmh_EMPH,               /**< Emphasized text */
    pmh_STRONG,             /**< Strong text */
    pmh_LIST_BULLET,        /**< Bullet for a list item */
    pmh_LIST_ENUMERATOR,    /**< Enumerator for a list item */
    pmh_COMMENT,            /**< (pmh_HTML) comment */
    
    /* Code assumes that pmh_H1-6 are in order. */
    pmh_H1,                 /**< Header, level 1 */
    pmh_H2,                 /**< Header, level 2 */
    pmh_H3,                 /**< Header, level 3 */
    pmh_H4,                 /**< Header, level 4 */
    pmh_H5,                 /**< Header, level 5 */
    pmh_H6,                 /**< Header, level 6 */
    
    pmh_BLOCKQUOTE,         /**< Blockquote */
    pmh_VERBATIM,           /**< Verbatim */
    pmh_HTMLBLOCK,          /**< .. */
    pmh_HRULE,              /**< Horizontal rule */
    pmh_REFERENCE,          /**< Reference */
    pmh_NOTE,               /**< Note */
    
    /* Utility types used by the parser itself: */
    pmh_RAW_LIST,   /* List of pmh_RAW element lists, each to be processed separately from others
                     * (for each element in linked lists of this type, `children` points
                     * to a linked list of pmh_RAW elements) */
    pmh_RAW,        /* Span marker for positions in original input to be post-processed
                     * in a second parsing step */
    pmh_EXTRA_TEXT, /* Additional text to be parsed along with spans in the original input
                     * (these may be added to linked lists of pmh_RAW elements) */
    pmh_SEPARATOR,  /* Separates linked lists of pmh_RAW elements into parts to be processed
                     * separate from each other */
    pmh_NO_TYPE,    /* Placeholder element used while parsing */
    pmh_ALL         /* Linked list of *all* elements created while parsing */
} element_type;

/**
* \brief Number of types in element_type.
* \sa element_type
*/
#define pmh_NUM_TYPES 30

/**
* \brief Number of *language element* types in element_type.
* \sa element_type
*/
#define pmh_NUM_LANG_TYPES (pmh_NUM_TYPES - 6)

/**
* \brief Semantic value of a parsing action.
*/
struct Element
{
    element_type type;            /**< \brief type of element */
    unsigned long pos;            /**< \brief start offset in input */
    unsigned long end;            /**< \brief end offset in input */
    struct Element *next;         /**< \brief next element in list */
    struct Element *allElemsNext; /**< \brief next element in list of all elements */
    int textOffset;               /**< \brief offset to text (for elements of type pmh_EXTRA_TEXT, used when the parser reads the value of 'text') */
    char *text;                   /**< \brief text content (for elements of type pmh_EXTRA_TEXT) */
    char *label;                  /**< \brief label (for links and references) */
    char *address;                /**< \brief address (for links and references) */
    struct Element *children;     /**< \brief children of element (for elements of type pmh_RAW_LIST) */
};
typedef struct Element element;

/**
* \brief Bitfield enumeration of supported Markdown extensions.
*/
enum markdown_extensions
{
    pmh_EXT_NONE    = 0,        /**< No extensions */
    pmh_EXT_NOTES   = (1 << 0)  /**< pmh_A footnote syntax like that of Pandoc or pmh_PHP Markdown Extra */
};

#endif
