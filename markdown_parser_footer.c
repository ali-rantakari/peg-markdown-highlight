

int yyparse(void);

element ** parse_markdown(char *string, long offset, int max_chars, int extensions)
{
	counter = max_chars;
	useCounter = (counter != -1);
	parsing_offset = offset;
	
    char *oldcharbuf;
    
    oldcharbuf = charbuf;
    charbuf = string;
    
    yyparsefrom(yy_Doc);
    
    charbuf = oldcharbuf;          /* restore charbuf to original value */
    return head_elements;
}



