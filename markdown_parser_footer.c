

int yyparse(void);

element ** parse_markdown(char *string, element *elem, int extensions)
{
	p_elem_head = p_elem = elem;
	p_offset = elem->pos;
	
    char *oldcharbuf;
    
    oldcharbuf = charbuf;
    charbuf = string;
    
    yyparsefrom(yy_Doc);
    
    charbuf = oldcharbuf;          /* restore charbuf to original value */
    return head_elements;
}



