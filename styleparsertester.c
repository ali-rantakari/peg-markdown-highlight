/* PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * styleparsertester.c
 * 
 * Program for testing the stylesheet parser. Reads stylesheet input from stdin
 * and prints out the parsing results in a human-readable format.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pmh_styleparser.h"
#include "pmh_parser.h"


#define READ_BUFFER_LEN 1024
char *get_contents(FILE *f)
{
    char buffer[READ_BUFFER_LEN];
    size_t content_len = 1;
    char *content = malloc(sizeof(char) * READ_BUFFER_LEN);
    content[0] = '\0';
    
    while (fgets(buffer, READ_BUFFER_LEN, f))
    {
        content_len += strlen(buffer);
        content = realloc(content, content_len);
        strcat(content, buffer);
    }
    
    return content;
}

void print_styles(pmh_style_attribute *list)
{
    while (list != NULL)
    {
        char *attr_name = (list->type == pmh_attr_type_other)
                          ? list->name
                          : pmh_attr_name_from_type(list->type);
        
        if (list->type == pmh_attr_type_other)
            printf("  \"%s\" = ", attr_name);
        else
            printf("  %s = ", attr_name);
        
        if (list->type == pmh_attr_type_background_color
            || list->type == pmh_attr_type_foreground_color
            || list->type == pmh_attr_type_caret_color
            )
            printf("%i,%i,%i,%i\n",
                   list->value->argb_color->alpha,
                   list->value->argb_color->red,
                   list->value->argb_color->green,
                   list->value->argb_color->blue);
        else if (list->type == pmh_attr_type_font_style)
        {
            bool any_styles = false;
            if (list->value->font_styles->bold == true)
                printf("bold "), any_styles = true;
            if (list->value->font_styles->italic == true)
                printf("italic "), any_styles = true;
            if (list->value->font_styles->underlined == true)
                printf("underlined "), any_styles = true;
            if (!any_styles)
                printf("(none)");
            printf("\n");
        }
        else if (list->type == pmh_attr_type_font_size_pt)
            printf("%i pt\n", list->value->font_size_pt);
        else if (list->type == pmh_attr_type_font_family)
            printf("\"%s\"\n", list->value->font_family);
        else if (list->type == pmh_attr_type_other)
            printf("\"%s\"\n", list->value->string);
        else
            printf("??? (unknown attribute type)\n");
        list = list->next;
    }
}

void parsing_error_callback(char *error_message, int line_number,
                            void *context_data)
{
    fprintf(stderr, "ERROR (line %i): %s\n", line_number, error_message);
}

int main(int argc, char *argv[])
{
    char *input = get_contents(stdin);
    pmh_style_collection *styles = pmh_parse_styles(input, &parsing_error_callback, NULL);
    
    printf("------\n");
    
    if (styles->editor_styles != NULL)
    {
        printf("Editor styles:\n");
        print_styles(styles->editor_styles);
        printf("\n");
    }
    if (styles->editor_current_line_styles != NULL)
    {
        printf("Current line styles:\n");
        print_styles(styles->editor_current_line_styles);
        printf("\n");
    }
    if (styles->editor_selection_styles != NULL)
    {
        printf("Selection styles:\n");
        print_styles(styles->editor_selection_styles);
        printf("\n");
    }
    
    int i;
    for (i = 0; i < pmh_NUM_LANG_TYPES; i++)
    {
        pmh_style_attribute *cur = styles->element_styles[i];
        
        if (cur == NULL)
            continue;
        printf("%s:\n", pmh_element_name_from_type(cur->lang_element_type));
        print_styles(cur);
    }
    
    pmh_free_style_collection(styles);
    free(input);
    
    return 0;
}



