ALL : tester

TEST_PROGRAM=tester
CFLAGS ?= -Wall -O3 -framework Foundation -framework AppKit
PEGDIR=peg
LEG=$(PEGDIR)/leg

$(LEG):
	CC=gcc make -C $(PEGDIR)

markdown_parser.c : markdown_parser.leg $(LEG) markdown_parser_header.c markdown_parser_footer.c
	$(LEG) -o $@ $<

$(TEST_PROGRAM) : tester.m markdown_parser.c markdown_parser.h
	clang $(CFLAGS) -o $@ markdown_parser.c ANSIEscapeHelper.m $<

.PHONY: clean test

clean:
	rm -f markdown_parser.c $(TEST_PROGRAM) *.o; \
	make -C $(PEGDIR) clean

distclean: clean
	make -C $(PEGDIR) spotless

leak-check: $(TEST_PROGRAM)
	valgrind --leak-check=full ./$(TEST_PROGRAM) README

