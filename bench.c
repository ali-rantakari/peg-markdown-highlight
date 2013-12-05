/* PEG Markdown Highlight
 * Copyright 2011-2013 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * bench.c
 * 
 * Used for measuring the execution speed of the parser.
 */

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <libgen.h>
#include <sys/time.h>
#include "pmh_parser.h"


#define READ_BUFFER_LEN 1024
char *read_utf8(FILE *stream)
{
	char buffer[READ_BUFFER_LEN];
	size_t content_len = 1;
	char *content = malloc(sizeof(char) * READ_BUFFER_LEN);
	content[0] = '\0';
	
	while (fgets(buffer, READ_BUFFER_LEN, stream))
	{
		content_len += strlen(buffer);
		content = realloc(content, content_len);
		strcat(content, buffer);
	}
	
	return content;
}


double get_time()
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec + t.tv_usec*1e-6;
}

int main(int argc, char * argv[])
{
	if (argc < 3) {
		printf("usage: %s [-s] [iterations] input_file\n", basename(argv[0]));
		printf("\n  -s = sort by position\n  Use - as input_file to read from stdin\n");
		return 0;
	}
	
	int iterations = atoi(argv[argc-2]);
	bool sort = (argc > 2 && strcmp(argv[1], "-s") == 0);
	
	FILE *stream = (strcmp(argv[argc-1], "-") == 0) ? stdin : fopen(argv[argc-1], "r");
	char *md_source = read_utf8(stream);
	
	double starttime = get_time();
	int i;
	for (i = 0; i < iterations; i++)
	{
		pmh_element **result;
		pmh_markdown_to_elements(md_source, pmh_EXT_NONE, &result);
		if (sort)
			pmh_sort_elements_by_pos(result);
	}
	double endtime = get_time();
	
	printf("%f\n", (endtime-starttime));
	
    return(0);
}
