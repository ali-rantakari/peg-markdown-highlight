
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "styleparser.h"

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

int main(int argc, char *argv[])
{
    char *input = get_contents(stdin);
    style_attribute **attrs = parse_styles(input);
    
    printf("------\n");
    int i;
    for (i = 0; i < NUM_LANG_TYPES; i++)
    {
        if (attrs[i] == NULL)
            continue;
        
        printf("type: %i\n", i);
        style_attribute *cur = attrs[i];
        while (cur != NULL)
        {
            printf("  attr %i = ", cur->type);
            if (cur->type == attr_type_background_color || cur->type == attr_type_foreground_color)
                printf("%i,%i,%i,%i\n", cur->value->argb_color->alpha, cur->value->argb_color->red, cur->value->argb_color->green, cur->value->argb_color->blue);
            else
                printf("%s\n", cur->value->string);
            cur = cur->next;
        }
    }
    
    return 0;
}
