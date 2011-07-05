ALL : styleparsertester

CFLAGS ?= -Wall -Wswitch -Wshadow -Wsign-compare -Werror -O3 -std=gnu89

GREGDIR=../greg
GREG=$(GREGDIR)/greg

ifdef DEBUG
	CFLAGS += -g -O0
endif

$(GREG):
	@echo '------- building greg'
	CC=gcc make -C $(GREGDIR)

styleparser.c : styleparser.leg
	@echo '------- generating parser code from grammar'
	$(GREG) -o $@ $<

styleparser.o : styleparser.c styleparser.h
	@echo '------- building styleparser.o'
	$(CC) $(CFLAGS) -c -o $@ $<

styleparsertester : styleparsertester.c styleparser.o
	@echo '------- building styleparsertester'
	$(CC) $(CFLAGS) -o $@ styleparser.o $<

clean:
	rm -f styleparser.c *.o styleparsertester; \
	rm -rf *.dSYM; \
	make -C $(GREGDIR) clean

distclean: clean
	make -C $(GREGDIR) spotless

leak-check: $(TESTER)
	valgrind --leak-check=full ./styleparsertester < styles/teststyle.style

