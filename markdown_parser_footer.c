

int yyparse(void);

element ** parse_markdown(char *string, element *elem, int extensions)
{
	p_elem_head = p_elem = elem;
	p_offset = elem->pos;
	
    char *oldcharbuf;
    
    oldcharbuf = charbuf;
    charbuf = string;
    
    yybuflen = 0;
    printf("\n");
    printf("(starting at %ld -- yybuflen:%i yypos:%i)\n", p_offset, yybuflen, yypos);
    printf("PARSER: ");
    
    yyparsefrom(yy_Doc);
    
    printf("\n\n");
    
    charbuf = oldcharbuf;          /* restore charbuf to original value */
    return head_elements;
}



