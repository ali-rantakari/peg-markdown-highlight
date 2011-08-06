/* PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * markdown_parser_foot.c
 * 
 * Code to be appended to the end of the parser code generated from the
 * PEG grammar.
 */


void _parse(parser_data *p_data, yyrule start_rule)
{
    GREG *g = yyparse_new(p_data);
    if (start_rule == NULL)
        yyparse(g);
    else
        yyparse_from(g, start_rule);
    yyparse_free(g);
    
    pmh_PRINTF("\n\n");
}

void parse_markdown(parser_data *p_data)
{
    pmh_PRINTF("\nPARSING DOCUMENT: ");
    
    _parse(p_data, NULL);
}

void parse_references(parser_data *p_data)
{
    pmh_PRINTF("\nPARSING REFERENCES: ");
    
    p_data->parsing_only_references = true;
    _parse(p_data, yy_References);
    p_data->parsing_only_references = false;
    
    p_data->references = p_data->head_elems[pmh_REFERENCE];
    p_data->head_elems[pmh_REFERENCE] = NULL;
}

