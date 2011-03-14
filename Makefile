ALL : tester testclient highlighter

BENCH=bench
TESTER=tester
TEST_CLIENT=testclient
HIGHLIGHTER=highlighter
CFLAGS ?= -Wall -O3 --std=c99
OBJC_CFLAGS=-framework Foundation -framework AppKit
PEGDIR=peg
LEG=$(PEGDIR)/leg

$(LEG):
	@echo '------- building peg/leg'
	CC=gcc make -C $(PEGDIR)

markdown_parser.c : markdown_parser.leg $(LEG)
	$(LEG) -o $@ $<

pmh_parser.c : markdown_parser.c markdown_parser_head.c markdown_parser_foot.c
	./combine_parser_files.py > $@

$(TESTER) : tester.m pmh_parser.c markdown_parser.h ANSIEscapeHelper.m ANSIEscapeHelper.h
	@echo '------- building tester'
	clang $(CFLAGS) $(OBJC_CFLAGS) -o $@ pmh_parser.c ANSIEscapeHelper.m $<

$(TEST_CLIENT) : testclient.m ANSIEscapeHelper.m ANSIEscapeHelper.h
	@echo '------- building testclient'
	clang $(CFLAGS) $(OBJC_CFLAGS) -o $@ ANSIEscapeHelper.m $<

$(HIGHLIGHTER) : highlighter.c pmh_parser.c markdown_parser.h
	@echo '------- building highlighter'
	cc -Wall -O3 -ansi -DMKD_DEBUG_OUTPUT=0 -o $@ pmh_parser.c $<

$(BENCH) : bench.c pmh_parser.c markdown_parser.h
	@echo '------- building bench'
	cc $(CFLAGS) -DMKD_DEBUG_OUTPUT=0 -o $@ pmh_parser.c $<

docs: markdown_parser.h markdown_definitions.h doxygen.cfg example_cocoa/HGMarkdownHighlighter.h
	doxygen doxygen.cfg
	touch docs

.PHONY: clean test

clean:
	rm -f markdown_parser.c pmh_parser.c $(TESTER) $(TEST_CLIENT) $(HIGHLIGHTER) *.o; \
	make -C $(PEGDIR) clean

distclean: clean
	make -C $(PEGDIR) spotless

leak-check: $(TESTER)
	valgrind --leak-check=full ./$(TESTER) 100 todo.md

