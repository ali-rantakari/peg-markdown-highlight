ALL : styleparsertester

CFLAGS ?= -Wall -Wswitch -Wshadow -Wsign-compare -Werror -O3 -std=gnu89

ifdef DEBUG
	CFLAGS += -g -O0
endif

styleparser.o : styleparser.c styleparser.h
	@echo '------- building styleparser.o'
	$(CC) $(CFLAGS) -c -o $@ $<

styleparsertester : styleparsertester.c styleparser.o
	@echo '------- building styleparsertester'
	$(CC) $(CFLAGS) -o $@ styleparser.o $<

clean:
	rm -f *.o styleparsertester; \
	rm -rf *.dSYM; \

leak-check: $(TESTER)
	valgrind --leak-check=full ./styleparsertester < styles/teststyle.style

