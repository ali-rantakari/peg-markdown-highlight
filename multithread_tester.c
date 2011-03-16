#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <string.h>
#include <sys/time.h>
#include "markdown_parser.h"


#define READ_BUFFER_LEN 1024
char *utf8_from_stdin()
{
	char buffer[READ_BUFFER_LEN];
	size_t content_len = 1;
	char *content = malloc(sizeof(char) * READ_BUFFER_LEN);
	content[0] = '\0';
	
	while (fgets(buffer, READ_BUFFER_LEN, stdin))
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
	char *name;
	int iterations;
} threadinfo;

threadinfo *mk_threadinfo(char *content, char *name, int iterations)
{
	threadinfo *t = malloc(sizeof(threadinfo));
	t->md_content = content;
	t->name = name;
	t->iterations = iterations;
	return t;
}


double get_time()
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_usec;
}


void *thread_run(void *arg)
{
	threadinfo *ti = (threadinfo *)arg;
	int i;
	for (i = 0; i < ti->iterations; i++)
	{
		int sleep_ms = (int)get_time() % 100;
		fprintf(stderr, "%s (iteration %i/%i, sleep %i ms after)\n", ti->name, i+1, ti->iterations, sleep_ms);
		int extensions = 0;
		element **result;
		markdown_to_elements(ti->md_content, extensions, &result);
		free_elements(result);
		usleep(sleep_ms);
	}
	return NULL;
}


int main(int argc, char *argv[])
{
	char *md_source = utf8_from_stdin();
	int md_source_len = strlen(md_source);
	
	int num_threads = 3;
	int num_iterations = 5;
	if (argc >= 3) {
		num_threads = atoi(argv[1]);
		num_iterations = atoi(argv[2]);
	}
	
	printf("Parsing input in %i threads, %i iterations each.\n", num_threads, num_iterations);
	
	pthread_t threads[num_threads];
	int i;
	for (i = 0; i < num_threads; i++)
	{
		char *md_source_copy = malloc(md_source_len+1);
		strcpy(md_source_copy, md_source);
		pthread_t thread;
		char *name = malloc(sizeof(char)*10);
		sprintf(name, "t%i", i+1);
		threadinfo *ti = mk_threadinfo(md_source_copy, name, num_iterations);
		pthread_create(&thread, NULL, thread_run, (void *)ti);
		threads[i] = thread;
	}
	
	for (i = 0; i < num_threads; i++)
		pthread_join(threads[i], NULL);
	
	printf("done.\n");
	
	return 0;
}
