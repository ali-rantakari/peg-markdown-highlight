/* PEG Markdown Highlight
 * Copyright 2011-2012 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * multithread_tester.c
 * 
 * Test program that spawns multiple threads that run the parser
 * simultaneously for a given number of iterations each.
 */

#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <string.h>
#include <sys/time.h>
#include <libgen.h>
#include "pmh_parser.h"


#define READ_BUFFER_LEN 1024
char *get_contents(FILE *f)
{
    char buffer[READ_BUFFER_LEN];
    size_t content_len = 1;
    char *content = malloc(sizeof(char) * READ_BUFFER_LEN);
    content[0] = '\0';
    
    while (fgets(buffer, READ_BUFFER_LEN, f))
    {
        content_len += strlen(buffer);
        content = realloc(content, content_len);
        strcat(content, buffer);
    }
    
    return content;
}


typedef struct
{
    char *md_content;
    char *results_str;
    char *name;
    int iterations;
} threadinfo;

threadinfo *mk_threadinfo(char *content, char *name, int iterations)
{
    threadinfo *t = malloc(sizeof(threadinfo));
    t->md_content = content;
    t->name = name;
    t->iterations = iterations;
    t->results_str = NULL;
    return t;
}


double get_time()
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_usec;
}


char *elements_to_str(pmh_element **elems)
{
    char *out = malloc(sizeof(char));
    out[0] = '\0';
    size_t content_len = 1;
    
    int i;
    for (i = 0; i < pmh_NUM_LANG_TYPES; i++)
    {
        char *f;
        content_len += asprintf(&f, "%i:", i);
        out = realloc(out, content_len);
        strcat(out, f);
        free(f);
        
        pmh_element *cursor = elems[i];
        while (cursor != NULL)
        {
            char *ff;
            content_len += asprintf(&ff, "%ld-%ld,", cursor->pos, cursor->end);
            out = realloc(out, content_len);
            strcat(out, ff);
            free(ff);
            cursor = cursor->next;
        }
        
        content_len += 1;
        out = realloc(out, content_len);
        strcat(out, "|");
    }
    
    return out;
}


void *thread_run(void *arg)
{
    threadinfo *ti = (threadinfo *)arg;
    int i;
    for (i = 0; i < ti->iterations; i++)
    {
        int sleep_ms = (int)get_time() % 100;
        fprintf(stderr, "%s (iteration %i/%i, sleep %i ms after)\n",
                ti->name, i+1, ti->iterations, sleep_ms);
        
        pmh_element **result;
        pmh_markdown_to_elements(ti->md_content, pmh_EXT_NONE, &result);
        pmh_sort_elements_by_pos(result);
        
        char *this_results = elements_to_str(result);
        if (ti->results_str == NULL)
            ti->results_str = this_results;
        else
        {
            if (strcmp(this_results, ti->results_str) != 0)
            {
                fprintf(stderr, "ERROR! Thread %s results differ:\n\n"
                                "1st iteration results:\n%s\n"
                                "this iteration (#%i) results:\n%s\n",
                                ti->name, ti->results_str, i+1, this_results);
            }
            free(this_results);
        }
        
        pmh_free_elements(result);
        
        usleep(sleep_ms);
    }
    return NULL;
}


int main(int argc, char *argv[])
{
    int i, j, k;
    
    int num_threads = 3;
    int num_iterations = 5;
    if (argc >= 3) {
        num_threads = atoi(argv[1]);
        num_iterations = atoi(argv[2]);
    }
    
    char **md_source_filenames = NULL;
    char **md_sources = NULL;
    int *md_source_lengths = NULL;
    int num_md_sources = 0;
    for (i=0, j=0; i < argc; i++)
    {
        if (strcmp(argv[i], "--") == 0)
        {
            num_md_sources = argc-i-1;
            md_sources = (char **)malloc(sizeof(char*)*num_md_sources);
            md_source_filenames = (char **)malloc(sizeof(char*)*num_md_sources);
            md_source_lengths = (int *)malloc(sizeof(int*)*num_md_sources);
        }
        else if (md_sources != NULL)
        {
            printf("read %s\n", argv[i]);
            md_source_filenames[j] = argv[i];
            FILE *f = fopen(argv[i], "r");
            md_sources[j] = get_contents(f);
            fclose(f);
            md_source_lengths[j] = strlen(md_sources[j]);
            j++;
        }
    }
    
    if (md_sources == NULL) {
        printf("usage: %s [NUM_THREADS] [NUM_ITERATIONS] -- file1 [file2...]\n",
               basename(argv[0]));
        return 0;
    }
    
    printf("Parsing input in %i threads, %i iterations each.\n",
           num_threads, num_iterations);
    
    int colors[5] = {31,32,33,35,36};
    int num_colors = 5;
    
    pthread_t threads[num_threads];
    for (i=0, j=0, k=0;
         i < num_threads;
         i++, j = ((j+1) % num_md_sources), k = ((k+1) % num_colors))
    {
        char *md_source_copy = malloc(md_source_lengths[j]+1);
        strcpy(md_source_copy, md_sources[j]);
        pthread_t thread;
        char *name = malloc(sizeof(char)*(strlen(md_source_filenames[j])+30));
        sprintf(name, "\e[%imt%i\e[0m \e[34m<%s>\e[0m",
                colors[k], i+1, md_source_filenames[j]);
        threadinfo *ti = mk_threadinfo(md_source_copy, name, num_iterations);
        pthread_create(&thread, NULL, thread_run, (void *)ti);
        threads[i] = thread;
    }
    
    for (i = 0; i < num_threads; i++)
        pthread_join(threads[i], NULL);
    
    printf("done.\n");
    
    return 0;
}
