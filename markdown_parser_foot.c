

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
void parse_markdown(parser_data *p_data)
{
    MKD_PRINTF("\nPARSER: ");
    
    GREG *g = yyparse_new(p_data);
    yyparse(g);
    yyparse_free(g);
    
    MKD_PRINTF("\n\n");
}



