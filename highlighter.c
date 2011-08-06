/* PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * highlighter.c
 * 
 * Test program that parses the Markdown content from stdin and outputs
 * the positions of found language elements.
 */

#include <stdio.h>
#include <string.h>
#include "markdown_parser.h"


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


void output_result(element *elem[])
{
    element *cursor;
    bool firstType = true;
    int i;
    for (i = 0; i < pmh_NUM_LANG_TYPES; i++)
    {
        cursor = elem[i];
        if (cursor == NULL)
            continue;
        
        if (!firstType)
            printf("|");
        printf("%i:", i);
        
        bool firstSpan = true;
        while (cursor != NULL)
        {
            if (!firstSpan)
                printf(",");
            printf("%ld-%ld", cursor->pos, cursor->end);
            cursor = cursor->next;
            firstSpan = false;
        }
        firstType = false;
    }
}


int main(int argc, char * argv[])
{
    element **result;
    
    FILE *file = stdin;
    if (argc > 1)
        file = fopen(argv[1], "r");
    char *md_source = get_contents(file);
    markdown_to_elements(md_source, pmh_EXT_NONE, &result);
    sort_elements_by_pos(result);
    output_result(result);
    
    return(0);
}
