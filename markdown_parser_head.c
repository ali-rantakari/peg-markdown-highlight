/* PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * markdown_parser_head.c
 * 
 * Code to be inserted into the beginning of the parser code generated
 * from the PEG grammar.
 */

#include "markdown_parser.h"


// Alias strdup to _strdup on MSVC:
#ifdef _MSC_VER
#define strdup _strdup
#endif


typedef struct
{
    /* Buffer of characters to be parsed: */
    char *charbuf;
    
    /* Linked list of {start, end} offset pairs determining which parts */
    /* of charbuf to actually parse: */
    element *elem;
    element *elem_head;
    
    /* Current parsing offset within charbuf: */
    unsigned long offset;
    
    /* The extensions to use for parsing (bitfield */
    /* of enum markdown_extensions): */
    int extensions;
    
    /* Array of parsing result elements, indexed by type: */
    element **head_elems;
    
    /* Whether we are parsing only references: */
    bool parsing_only_references;
    
    /* List of reference elements: */
    element *references;
} parser_data;

parser_data *mk_parser_data(char *charbuf,
                            element *parsing_elems,
                            unsigned long offset,
                            int extensions,
                            element **head_elems,
                            element *references)
{
    parser_data *p_data = (parser_data *)malloc(sizeof(parser_data));
    p_data->extensions = extensions;
    p_data->charbuf = charbuf;
    p_data->offset = offset;
    p_data->elem_head = p_data->elem = parsing_elems;
    p_data->references = references;
    p_data->parsing_only_references = false;
    if (head_elems != NULL)
        p_data->head_elems = head_elems;
    else {
        p_data->head_elems = (element **)malloc(sizeof(element *) * NUM_TYPES);
        int i;
        for (i = 0; i < NUM_TYPES; i++)
            p_data->head_elems[i] = NULL;
    }
    return p_data;
}


// Forward declarations
void parse_markdown(parser_data *p_data);
void parse_references(parser_data *p_data);





void remove_zero_length_raw_spans(element *elem)
{
    element *parent = NULL;
    element *c = elem;
    while (c != NULL)
    {
        if (c->type == RAW && c->pos >= c->end)
        {
            if (parent != NULL) {
                parent->next = c->next;
            } else {
                elem = c->next;
            }
            parent = c;
            c = c->next;
            continue;
        }
        parent = c;
        c = c->next;
    }
}

/*
Print null-terminated string s.t. some characters are
represented by their corresponding espace sequences
*/
void print_str_literal_escapes(char *str)
{
    char *c = str;
    MKD_PRINTF("'");
    while (*c != '\0')
    {
        if (*c == '\n')         MKD_PRINTF("\\n");
        else if (*c == '\t')    MKD_PRINTF("\\t");
        else putchar(*c);
        c++;
    }
    MKD_PRINTF("'");
}

/*
Print elements in a linked list of
RAW, SEPARATOR, EXTRA_TEXT elements
*/
void print_raw_spans_inline(element *elem)
{
    element *cur = elem;
    while (cur != NULL)
    {
        if (cur->type == SEPARATOR)
            MKD_PRINTF("<SEP %ld> ", cur->pos);
        else if (cur->type == EXTRA_TEXT) {
            MKD_PRINTF("{ETEXT "); print_str_literal_escapes(cur->text); MKD_PRINTF("}");
        }
        else
            MKD_PRINTF("(%ld-%ld) ", cur->pos, cur->end);
        cur = cur->next;
    }
}

/*
Perform postprocessing parsing runs for RAW_LIST elements in `elem`,
iteratively until no such elements exist.
*/
void process_raw_blocks(parser_data *p_data)
{
    MKD_PRINTF("--------process_raw_blocks---------\n");
    while (p_data->head_elems[RAW_LIST] != NULL)
    {
        MKD_PRINTF("new iteration.\n");
        element *cursor = p_data->head_elems[RAW_LIST];
        p_data->head_elems[RAW_LIST] = NULL;
        while (cursor != NULL)
        {
            element *span_list = cursor->children;
            
            remove_zero_length_raw_spans(span_list);
            
            #if MKD_DEBUG_OUTPUT
            MKD_PRINTF("  process: "); print_raw_spans_inline(span_list); MKD_PRINTF("\n");
            #endif
            
            while (span_list != NULL)
            {
                MKD_PRINTF("next: span_list: %ld-%ld\n", span_list->pos, span_list->end);
                
                element *subspan_list = span_list;
                element *previous = NULL;
                while (span_list != NULL && span_list->type != SEPARATOR) {
                    previous = span_list;
                    span_list = span_list->next;
                }
                if (span_list != NULL && span_list->type == SEPARATOR) {
                    span_list = span_list->next;
                    previous->next = NULL;
                }
                
                #if MKD_DEBUG_OUTPUT
                MKD_PRINTF("    subspan process: "); print_raw_spans_inline(subspan_list); MKD_PRINTF("\n");
                #endif
                
                parser_data *raw_p_data = mk_parser_data(p_data->charbuf,
                                                         subspan_list,
                                                         subspan_list->pos,
                                                         p_data->extensions,
                                                         p_data->head_elems,
                                                         p_data->references);
                parse_markdown(raw_p_data);
                free(raw_p_data);
                
                MKD_PRINTF("parse over\n");
            }
            
            cursor = cursor->next;
        }
    }
}

void print_raw_blocks(char *text, element *elem[])
{
    MKD_PRINTF("--------print_raw_blocks---------\n");
    MKD_PRINTF("block:\n");
    element *cursor = elem[RAW_LIST];
    while (cursor != NULL)
    {
        print_raw_spans_inline(cursor->children);
        cursor = cursor->next;
    }
}





/* Free all elements created while parsing */
void free_elements(element **elems)
{
    element *cursor = elems[ALL];
    while (cursor != NULL) {
        element *old = cursor;
        cursor = cursor->allElemsNext;
        free(old);
    }
    elems[ALL] = NULL;
    
    free(elems);
}








#define IS_CONTINUATION_BYTE(x) ((x & 0xC0) == 0x80)
#define HAS_UTF8_BOM(x)         (((*x & 0xFF) == 0xEF) && ((*(x+1) & 0xFF) == 0xBB) && ((*(x+2) & 0xFF) == 0xBF))

/*
Copy `str` to `out`, while doing the following:
  - remove UTF-8 continuation bytes
  - remove possible UTF-8 BOM (byte order mark)
  - append two newlines to the end (like peg-markdown does)
*/
int strcpy_preformat(char *str, char **out)
{
    // +2 in the following is due to the "\n\n" suffix:
    char *new_str = (char *)malloc(sizeof(char) * strlen(str) + 1 + 2);
    char *c = str;
    int i = 0;
    
    if (HAS_UTF8_BOM(c))
        c += 3;
    
    while (*c != '\0')
    {
        if (!IS_CONTINUATION_BYTE(*c))
            *(new_str+i) = *c, i++;
        c++;
    }
    *(new_str+(i++)) = '\n';
    *(new_str+(i++)) = '\n';
    *(new_str+i) = '\0';
    
    *out = new_str;
    return i;
}



void markdown_to_elements(char *text, int extensions, element **out_result[])
{
    char *text_copy = NULL;
    int text_copy_len = strcpy_preformat(text, &text_copy);
    
    element *parsing_elem = (element *)malloc(sizeof(element));
    parsing_elem->type = RAW;
    parsing_elem->pos = 0;
    parsing_elem->end = text_copy_len;
    parsing_elem->next = NULL;
    
    parser_data *p_data = mk_parser_data(text_copy, parsing_elem, 0, extensions, NULL, NULL);
    element **result = p_data->head_elems;
    
    if (*text_copy != '\0')
    {
        // Get reference definitions into p_data->references
        parse_references(p_data);
        
        // Reset parser state to beginning of input
        p_data->offset = 0;
        p_data->elem = p_data->elem_head;
        
        // Parse whole document
        parse_markdown(p_data);
        
        #if MKD_DEBUG_OUTPUT
        print_raw_blocks(text_copy, result);
        #endif
        
        process_raw_blocks(p_data);
    }
    
    free(p_data);
    free(parsing_elem);
    free(text_copy);
    
    *out_result = result;
}



/*
Mergesort linked list of elements (using comparison function `compare`),
return new head. (Adapted slightly from Simon Tatham's algorithm.)
*/
element *ll_mergesort(element *list, int (*compare)(const element*, const element*))
{
    if (!list)
        return NULL;
    
    element *out_head = list;
    
    /* Merge widths of doubling size until done */
    int merge_width = 1;
    while (1)
    {
        element *l, *r; /* left & right segment pointers */
        element *tail = NULL; /* tail of sorted section */
        
        l = out_head;
        out_head = NULL;
        
        int merge_count = 0;
        
        while (l)
        {
            merge_count++;
            
            /* Position r, determine lsize & rsize */
            r = l;
            int lsize = 0;
            int i;
            for (i = 0; i < merge_width; i++) {
                lsize++;
                r = r->next;
                if (!r)
                    break;
            }
            int rsize = merge_width;
            
            /* Merge l & r */
            while (lsize > 0 || (rsize > 0 && r))
            {
                bool get_from_left = false;
                if (lsize == 0)             get_from_left = false;
                else if (rsize == 0 || !r)  get_from_left = true;
                else if (compare(l,r) <= 0) get_from_left = true;
                
                element *e;
                if (get_from_left) {
                    e = l; l = l->next; lsize--;
                } else {
                    e = r; r = r->next; rsize--;
                }
                
                /* add the next element to the merged list */
                if (tail)
                    tail->next = e;
                else
                    out_head = e;
                tail = e;
            }
            
            l = r;
        }
        tail->next = NULL;
        
        if (merge_count <= 1)
            return out_head;
        
        merge_width *= 2;
    }
}

int elem_compare_by_pos(const element *a, const element *b) {
    return a->pos - b->pos;
}

void sort_elements_by_pos(element *element_lists[])
{
    int i;
    for (i = 0; i < NUM_LANG_TYPES; i++)
        element_lists[i] = ll_mergesort(element_lists[i], &elem_compare_by_pos);
}








char *type_name(element_type type)
{
    switch (type)
    {
        case SEPARATOR:          return "SEPARATOR"; break;
        case EXTRA_TEXT:         return "EXTRA_TEXT"; break;
        case NO_TYPE:            return "NO TYPE"; break;
        case RAW_LIST:           return "RAW_LIST"; break;
        case RAW:                return "RAW"; break;
        
        case LINK:               return "LINK"; break;
        case IMAGE:              return "IMAGE"; break;
        case CODE:               return "CODE"; break;
        case HTML:               return "HTML"; break;
        case EMPH:               return "EMPH"; break;
        case STRONG:             return "STRONG"; break;
        case LIST_BULLET:        return "LIST_BULLET"; break;
        case LIST_ENUMERATOR:    return "LIST_ENUMERATOR"; break;
        case H1:                 return "H1"; break;
        case H2:                 return "H2"; break;
        case H3:                 return "H3"; break;
        case H4:                 return "H4"; break;
        case H5:                 return "H5"; break;
        case H6:                 return "H6"; break;
        case BLOCKQUOTE:         return "BLOCKQUOTE"; break;
        case VERBATIM:           return "VERBATIM"; break;
        case HTMLBLOCK:          return "HTMLBLOCK"; break;
        case HRULE:              return "HRULE"; break;
        case REFERENCE:          return "REFERENCE"; break;
        case NOTE:               return "NOTE"; break;
        default:                 return "?";
    }
}

/* return true if extension is selected */
bool extension(parser_data *p_data, int ext)
{
    return ((p_data->extensions & ext) != 0);
}

/* return reference element for a given label */
element *get_reference(parser_data *p_data, char *label)
{
    if (!label)
        return NULL;
    
    element *cursor = p_data->references;
    while (cursor != NULL)
    {
        if (cursor->label && strcmp(label, cursor->label) == 0)
            return cursor;
        cursor = cursor->next;
    }
    return NULL;
}


/* cons an element/list onto a list, returning pointer to new head */
static element * cons(element *elem, element *list)
{
    assert(elem != NULL);
    
    element *cur = elem;
    while (cur->next != NULL) {
        cur = cur->next;
    }
    cur->next = list;
    
    return elem;
}


/* reverse a list, returning pointer to new list */
static element *reverse(element *list)
{
    element *new_head = NULL;
    element *next = NULL;
    while (list != NULL) {
        next = list->next;
        list->next = new_head;
        new_head = list;
        list = next;
    }
    return new_head;
}



/* construct element */
element * mk_element(parser_data *p_data, element_type type, long pos, long end)
{
    element *result = (element *)malloc(sizeof(element));
    result->type = type;
    result->pos = pos;
    result->end = end;
    result->next = NULL;
    result->label = result->address = result->text = NULL;
    
    element *old_all_elements_head = p_data->head_elems[ALL];
    p_data->head_elems[ALL] = result;
    result->allElemsNext = old_all_elements_head;
    
    //MKD_PRINTF("  mk_element: %s [%ld - %ld]\n", type_name(type), pos, end);
    
    return result;
}

element * copy_element(parser_data *p_data, element *elem)
{
    element *result = mk_element(p_data, elem->type, elem->pos, elem->end);
    result->label = elem->label;
    result->text = elem->text;
    result->address = elem->address;
    return result;
}

/* construct EXTRA_TEXT element */
element * mk_etext(parser_data *p_data, char *string)
{
    element *result;
    assert(string != NULL);
    result = mk_element(p_data, EXTRA_TEXT, 0,0);
    result->text = string;
    return result;
}


/*
Given an element where the offsets {pos, end} represent
locations in the *parsed text* (defined by the linked list of RAW and
EXTRA_TEXT elements in p_data->elem), fix these offsets to represent
corresponding offsets in the original input (p_data->charbuf). Also split
the given element into multiple parts if its offsets span multiple
p_data->elem elements. Return the (list of) elements with real offsets.
*/
element *fix_offsets(parser_data *p_data, element *elem)
{
    if (elem->type == EXTRA_TEXT)
        return mk_etext(p_data, elem->text);
    
    element *new_head = copy_element(p_data, elem);
    
    element *tail = new_head;
    element *prev = NULL;
    
    bool found_start = false;
    bool found_end = false;
    bool tail_needs_pos = false;
    unsigned long previous_end = 0;
    unsigned long c = 0;
    
    element *cursor = p_data->elem_head;
    while (cursor != NULL)
    {
        int thislen = (cursor->type == EXTRA_TEXT)
                        ? strlen(cursor->text)
                        : cursor->end - cursor->pos;
        
        if (tail_needs_pos && cursor->type != EXTRA_TEXT) {
            tail->pos = cursor->pos;
            tail_needs_pos = false;
        }
        
        unsigned int this_pos = cursor->pos;
        
        if (!found_start && (c <= elem->pos && elem->pos <= c+thislen)) {
            tail->pos = (cursor->type == EXTRA_TEXT)
                        ? previous_end
                        : cursor->pos + (elem->pos - c);
            this_pos = tail->pos;
            found_start = true;
        }
        
        if (!found_end && (c <= elem->end && elem->end <= c+thislen)) {
            tail->end = (cursor->type == EXTRA_TEXT)
                        ? previous_end
                        : cursor->pos + (elem->end - c);
            found_end = true;
        }
        
        if (found_start && found_end)
            break;
        
        if (cursor->type != EXTRA_TEXT)
            previous_end = cursor->end;
        
        if (found_start) {
            element *new_elem = mk_element(p_data, tail->type, this_pos, cursor->end);
            new_elem->next = tail;
            if (prev != NULL)
                prev->next = new_elem;
            if (new_head == tail)
                new_head = new_elem;
            prev = new_elem;
            tail_needs_pos = true;
        }
        
        c += thislen;
        cursor = cursor->next;
    }
    
    return new_head;
}



/* Add an element to p_data->head_elems. */
void add(parser_data *p_data, element *elem)
{
    if (elem->type != RAW_LIST)
    {
        MKD_PRINTF("  add: %s [%ld - %ld]\n", type_name(elem->type), elem->pos, elem->end);
        elem = fix_offsets(p_data, elem);
        MKD_PRINTF("     > %s [%ld - %ld]\n", type_name(elem->type), elem->pos, elem->end);
    }
    else
    {
        MKD_PRINTF("  add: RAW_LIST ");
        element *cursor = elem->children;
        element *previous = NULL;
        while (cursor != NULL)
        {
            element *next = cursor->next;
            MKD_PRINTF("(%ld-%ld)>", cursor->pos, cursor->end);
            element *new_cursor = fix_offsets(p_data, cursor);
            if (previous != NULL)
                previous->next = new_cursor;
            else
                elem->children = new_cursor;
            MKD_PRINTF("(%ld-%ld)", new_cursor->pos, new_cursor->end);
            while (new_cursor->next != NULL) {
                new_cursor = new_cursor->next;
                MKD_PRINTF("(%ld-%ld)", new_cursor->pos, new_cursor->end);
            }
            MKD_PRINTF(" ");
            if (next != NULL)
                new_cursor->next = next;
            previous = new_cursor;
            cursor = next;
        }
        MKD_PRINTF("\n");
    }
    
    if (p_data->head_elems[elem->type] == NULL)
        p_data->head_elems[elem->type] = elem;
    else
    {
        element *last = elem;
        while (last->next != NULL)
            last = last->next;
        last->next = p_data->head_elems[elem->type];
        p_data->head_elems[elem->type] = elem;
    }
}

element * add_element(parser_data *p_data, element_type type, long pos, long end)
{
    element *new_element = mk_element(p_data, type, pos, end);
    add(p_data, new_element);
    return new_element;
}

void add_raw(parser_data *p_data, long pos, long end)
{
    add_element(p_data, RAW, pos, end);
}





# define YYSTYPE element *
#ifdef __DEBUG__
# define YY_DEBUG 1
#endif

#define YY_INPUT(buf, result, max_size) yy_input_func(buf, &result, max_size, (parser_data *)G->data)

void yy_input_func(char *buf, int *result, int max_size, parser_data *p_data)
{
    if (p_data->elem == NULL) {
        (*result) = 0;
    } else {
        if (p_data->elem->type == EXTRA_TEXT) {
            int yyc;
            if (p_data->elem->text && *p_data->elem->text != '\0') {
                yyc = *p_data->elem->text++;
                MKD_PRINTF("\e[47;30m"); MKD_PUTCHAR(yyc); MKD_PRINTF("\e[0m");
                MKD_IF(yyc == '\n') MKD_PRINTF("\e[47m \e[0m");
            } else {
                yyc = EOF;
                p_data->elem = p_data->elem->next;
                MKD_PRINTF("\e[41m \e[0m");
                if (p_data->elem != NULL)
                    p_data->offset = p_data->elem->pos;
            }
            (*result) = (EOF == yyc) ? 0 : (*(buf) = yyc, 1);
        } else {
            *(buf) = *(p_data->charbuf + p_data->offset);
            (*result) = (*buf != '\0');
            p_data->offset++;
            MKD_PRINTF("\e[43;30m"); MKD_PUTCHAR(*buf); MKD_PRINTF("\e[0m");
            MKD_IF(*buf == '\n') MKD_PRINTF("\e[42m \e[0m");
            if (p_data->offset >= p_data->elem->end) {
                p_data->elem = p_data->elem->next;
                MKD_PRINTF("\e[41m \e[0m");
                if (p_data->elem != NULL)
                    p_data->offset = p_data->elem->pos;
            }
        }
    }
}


