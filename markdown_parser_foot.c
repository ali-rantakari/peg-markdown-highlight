

/**
* Parse a Markdown document.
* 
* string -- The text to parse
* elem -- Linked list of RAW or EXTRA_TEXT elements, the former
*         specifying offset spans in `string` to parse, and the
*         latter containing additional text to parse but not
*         take into account when adjusting offsets to match the
*         original input (`string`).
* extensions -- A bitfield specifying which extensions to use
*/
element ** parse_markdown(char *string, element *elem, int extensions)
{
	p_extensions = extensions;
	p_elem_head = p_elem = elem;
	p_offset = elem->pos;
	
    charbuf = string;
    
    MKD_PRINTF("\nPARSER: ");
    
    GREG *g = yyparse_new(charbuf);
    yyparse(g);
    yyparse_free(g);
    
    MKD_PRINTF("\n\n");
    
    charbuf = NULL;
    
    return head_elements;
}



