
#include "pmh_definitions.h"
#include <stdbool.h>

// Attribute value types
typedef struct
{
    int red;
    int green;
    int blue;
    int alpha;
} attr_argb_color;

// Style attribute types
typedef enum
{
    attr_type_foreground_color,
    attr_type_background_color,
    attr_type_caret_color,
    attr_type_font_size_pt,
    attr_type_font_family,
    attr_type_font_style,
    attr_type_other
} attr_type;

typedef struct
{
    bool italic;
    bool bold;
    bool underlined;
} attr_font_styles;

// Style attribute value
typedef union
{
    attr_argb_color *argb_color;
    attr_font_styles *font_styles;
    int font_size_pt;
    char *font_family;
    char *string;
} attr_value;

// Style attribute
typedef struct style_attribute
{
    pmh_element_type lang_element_type;
    attr_type type;
    char *name;
    attr_value *value;
    struct style_attribute *next;
} style_attribute;

// Collection of styles
typedef struct
{
    style_attribute *editor_styles;
    style_attribute *editor_current_line_styles;
    style_attribute *editor_selection_styles;
    style_attribute **element_styles;
} style_collection;

style_collection *parse_styles(char *input,
                               void(*error_callback)(char*,int,void*),
                               void *error_callback_context);
void free_style_collection(style_collection *coll);

pmh_element_type element_type_from_name(char *name);
char *element_name_from_type(pmh_element_type type);
attr_type attr_type_from_name(char *name);
char *attr_name_from_type(attr_type type);

