/* PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * markdown_parser_foot.c
 * 
 * Code to be appended to the end of the parser code generated from the
 * PEG grammar.
 */


void parse_markdown(parser_data *p_data)
{
    MKD_PRINTF("\nPARSER: ");
    
    GREG *g = yyparse_new(p_data);
    yyparse(g);
    yyparse_free(g);
    
    MKD_PRINTF("\n\n");
}



