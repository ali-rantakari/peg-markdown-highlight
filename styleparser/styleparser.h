
#include "markdown_definitions.h"

// Attribute value types
typedef struct
{
    int red;
    int green;
    int blue;
    int alpha;
} attr_argb_color;

typedef enum
{
    attr_font_style_normal,
    attr_font_style_condensed,
    attr_font_style_italic
} attr_font_style;

typedef enum
{
    attr_font_weight_normal,
    attr_font_weight_bold
} attr_font_weight;

// Style attribute types
typedef enum
{
    attr_type_foreground_color,
    attr_type_background_color,
    attr_type_font_size_pt,
    attr_type_font_family,
    attr_type_font_style,
    attr_type_font_weight,
    attr_type_other
} attr_type;

// Style attribute value
typedef union
{
    attr_argb_color *argb_color;
    int font_size_pt;
    char *font_family;
    attr_font_style font_style;
    attr_font_weight font_weight;
    char *string;
} attr_value;

// Style attribute
typedef struct style_attribute
{
    element_type lang_element_type;
    attr_type type;
    char *name;
    attr_value *value;
    struct style_attribute *next;
} style_attribute;

// Collection of styles
typedef struct
{
    style_attribute *editor_styles;
    style_attribute **element_styles;
} style_collection;

style_collection *parse_styles(char *input, void(*error_callback)(char*));

element_type element_type_from_name(char *name);
char *element_name_from_type(element_type type);
attr_type attr_type_from_name(char *name);
char *attr_name_from_type(attr_type type);

