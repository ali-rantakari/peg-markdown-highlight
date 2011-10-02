ALL : styleparsertester

CFLAGS ?= -Wall -Wswitch -Wshadow -Wsign-compare -Werror -O3 -std=gnu89

ifdef DEBUG
	CFLAGS += -g -O0
endif
ifdef DEBUGOUT
	CFLAGS += -Dpmh_DEBUG_OUTPUT=1
endif

pmh_styleparser.o : pmh_styleparser.c pmh_styleparser.h
	@echo '------- building pmh_styleparser.o'
	$(CC) $(CFLAGS) -c -o $@ $<

styleparsertester : styleparsertester.c pmh_styleparser.o
	@echo '------- building styleparsertester'
	$(CC) $(CFLAGS) -o $@ pmh_styleparser.o $<

clean:
	rm -f *.o styleparsertester; \
	rm -rf *.dSYM; \

analyze:
	clang --analyze pmh_styleparser.c

leak-check: $(TESTER)
	valgrind --leak-check=full --dsymutil=yes ./styleparsertester < styles/teststyle.style

