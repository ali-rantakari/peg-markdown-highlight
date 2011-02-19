

int yyparse(void);

element ** parse_markdown(char *string, int extensions)
{
    char *oldcharbuf;
    
    oldcharbuf = charbuf;
    charbuf = string;
    
    yyparsefrom(yy_Doc);
    
    charbuf = oldcharbuf;          /* restore charbuf to original value */
    return head_elements;
}



