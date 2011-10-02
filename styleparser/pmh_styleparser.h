
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
} pmh_attr_argb_color;

/**
* \brief Font style attribute value.
*/
typedef struct
{
    bool italic;
    bool bold;
    bool underlined;
} pmh_attr_font_styles;

/**
* \brief Style attribute types.
*/
typedef enum
{
    pmh_attr_type_foreground_color, /**< Foreground color */
    pmh_attr_type_background_color, /**< Background color */
    pmh_attr_type_caret_color,      /**< Caret (insertion point) color */
    pmh_attr_type_font_size_pt,     /**< Font size (in points) */
    pmh_attr_type_font_family,      /**< Font family */
    pmh_attr_type_font_style,       /**< Font style */
    pmh_attr_type_other             /**< Arbitrary custom attribute */
} pmh_attr_type;

/**
* \brief Style attribute value.
* 
* Determine which member to access in this union based on the
* 'type' value of the pmh_style_attribute.
* 
* \sa pmh_style_attribute
*/
typedef union
{
    pmh_attr_argb_color *argb_color;    /**< ARGB color */
    pmh_attr_font_styles *font_styles;  /**< Font styles */
    int font_size_pt;                   /**< Font size */
    char *font_family;                  /**< Font family */
    char *string;                       /**< Arbitrary custom string value */
} pmh_attr_value;

/**
* \brief Style attribute.
*/
typedef struct pmh_style_attribute
{
    pmh_element_type lang_element_type; /**< The Markdown language element this
                                             style applies to */
    pmh_attr_type type;                 /**< The type of the attribute */
    char *name;                         /**< The name of the attribute */
    pmh_attr_value *value;              /**< The value of the attribute */
    struct pmh_style_attribute *next;   /**< Next attribute in linked list */
} pmh_style_attribute;

/**
* \brief Collection of styles.
*/
typedef struct
{
    /** Styles that apply to the editor in general */
    pmh_style_attribute *editor_styles;
    
    pmh_style_attribute *editor_current_line_styles;    /**<  */
    pmh_style_attribute *editor_selection_styles;       /**<  */
    pmh_style_attribute **element_styles;               /**<  */
} pmh_style_collection;


pmh_style_collection *pmh_parse_styles(char *input,
                                       void(*error_callback)(char*,int,void*),
                                       void *error_callback_context);
void pmh_free_style_collection(pmh_style_collection *coll);

pmh_element_type pmh_element_type_from_name(char *name);
char *pmh_element_name_from_type(pmh_element_type type);
pmh_attr_type pmh_attr_type_from_name(char *name);
char *pmh_attr_name_from_type(pmh_attr_type type);

