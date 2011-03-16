

void parse_markdown(parser_data *p_data)
{
    MKD_PRINTF("\nPARSER: ");
    
    GREG *g = yyparse_new(p_data);
    yyparse(g);
    yyparse_free(g);
    
    MKD_PRINTF("\n\n");
}



