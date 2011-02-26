
#include <stdbool.h>
#include <stdlib.h>
#include <assert.h>
#include "mkd_types.h"

#ifndef MKD_DEBUG_OUTPUT
#define MKD_DEBUG_OUTPUT 0
#endif

#if MKD_DEBUG_OUTPUT
#define MKD_PRINTF(x, args...)	fprintf(stderr, x, ##args)
#define MKD_PUTCHAR(x)			putchar(x)
#else
#define MKD_PRINTF(x, args...)
#define MKD_PUTCHAR(x)
#endif

// see implementation for docs
element ** parse_markdown(char *string, element *elem, int extensions);
void markdown_to_elements(char *text, int extensions, element **out[]);
char *typeName(enum types type);
void free_elements();

