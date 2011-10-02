
#include "pmh_definitions.h"
#include <stdbool.h>

/**
* \brief Color (ARGB) attribute value.
* 
* All values are 0-255.
*/
typedef struct
{
    int red;    /**< Red color component (0-255) */
    int green;  /**< Green color component (0-255) */
    int blue;   /**< Blue color component (0-255) */
    int alpha;  /**< Alpha (opacity) color component (0-255) */
} attr_argb_color;

/**
* \brief Font style attribute value.
*/
typedef struct
{
    bool italic;
    bool bold;
    bool underlined;
} attr_font_styles;

/**
* \brief Style attribute types.
*/
typedef enum
{
    attr_type_foreground_color, /**< Foreground color */
    attr_type_background_color, /**< Background color */
    attr_type_caret_color,      /**< Caret (insertion point) color */
    attr_type_font_size_pt,     /**< Font size (in points) */
    attr_type_font_family,      /**< Font family */
    attr_type_font_style,       /**< Font style */
    attr_type_other             /**< Arbitrary custom attribute */
} attr_type;

/**
* \brief Style attribute value.
* 
* Determine which member to access in this union based on the
* 'type' value of the style_attribute.
* 
* \sa style_attribute
*/
typedef union
{
    attr_argb_color *argb_color;    /**< ARGB color */
    attr_font_styles *font_styles;  /**< Font styles */
    int font_size_pt;               /**< Font size */
    char *font_family;              /**< Font family */
    char *string;                   /**< Arbitrary custom string value */
} attr_value;

/**
* \brief Style attribute.
*/
typedef struct style_attribute
{
    pmh_element_type lang_element_type; /**< The Markdown language element this
                                             style applies to */
    attr_type type;                     /**< The type of the attribute */
    char *name;                         /**< The name of the attribute */
    attr_value *value;                  /**< The value of the attribute */
    struct style_attribute *next;       /**< Next attribute in linked list */
} style_attribute;

/**
* \brief Collection of styles.
*/
typedef struct
{
    /** Styles that apply to the editor in general */
    style_attribute *editor_styles;
    
    style_attribute *editor_current_line_styles;    /**<  */
    style_attribute *editor_selection_styles;       /**<  */
    style_attribute **element_styles;               /**<  */
} style_collection;


style_collection *parse_styles(char *input,
                               void(*error_callback)(char*,int,void*),
                               void *error_callback_context);
void free_style_collection(style_collection *coll);

pmh_element_type element_type_from_name(char *name);
char *element_name_from_type(pmh_element_type type);
attr_type attr_type_from_name(char *name);
char *attr_name_from_type(attr_type type);

