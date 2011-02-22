

int yyparse(void);

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
    
    charbuf = oldcharbuf;          /* restore charbuf to original value */
    return head_elements;
}



