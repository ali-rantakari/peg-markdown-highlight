

int yyparse(void);

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
	p_elem_head = p_elem = elem;
	p_offset = elem->pos;
	
    char *oldcharbuf;
    
    oldcharbuf = charbuf;
    charbuf = string;
    
    yybuflen = 0;
    MKD_PRINTF("\n");
    MKD_PRINTF("(starting at %i -- yybuflen:%i yypos:%i)\n", p_offset, yybuflen, yypos);
    MKD_PRINTF("PARSER: ");
    
    yyparsefrom(yy_Doc);
    
    MKD_PRINTF("\n\n");
    
    charbuf = oldcharbuf;
    return head_elements;
}



