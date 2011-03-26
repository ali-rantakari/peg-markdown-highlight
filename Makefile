ALL : tester testclient highlighter

BENCH=bench
TESTER=tester
MULTITHREAD_TESTER=multithread_tester
TEST_CLIENT=testclient
HIGHLIGHTER=highlighter
CFLAGS ?= -Wall -Wswitch -Wshadow -Wsign-compare -Werror -O3 -std=gnu89
OBJC_CFLAGS=-framework Foundation -framework AppKit

GREGDIR=greg
GREG=$(GREGDIR)/greg

ifdef DEBUG
	CFLAGS += -g
endif
ifdef DEBUGOUT
	CFLAGS += -DMKD_DEBUG_OUTPUT=1
endif

$(GREG):
	@echo '------- building greg'
	CC=gcc make -C $(GREGDIR)

markdown_parser_core.c : markdown_grammar.leg $(GREG)
	@echo '------- generating parser core from grammar'
	$(GREG) -o $@ $<

markdown_parser.c : markdown_parser_core.c markdown_parser_head.c markdown_parser_foot.c tools/combine_parser_files.sh
	@echo '------- combining parser code'
	./tools/combine_parser_files.sh > $@

markdown_parser.o : markdown_parser.c
	@echo '------- building markdown_parser.o'
	$(CC) $(CFLAGS) -c -o $@ $<

ANSIEscapeHelper.o : ANSIEscapeHelper.m ANSIEscapeHelper.h
	@echo '------- building ANSIEscapeHelper.o'
	clang -Wall -O3 -c -o $@ $<

$(TESTER) : tester.m markdown_parser.o markdown_parser.h ANSIEscapeHelper.o ANSIEscapeHelper.h
	@echo '------- building tester'
	clang $(CFLAGS) $(OBJC_CFLAGS) -o $@ markdown_parser.o ANSIEscapeHelper.o $<

$(TEST_CLIENT) : testclient.m ANSIEscapeHelper.o ANSIEscapeHelper.h
	@echo '------- building testclient'
	clang $(CFLAGS) $(OBJC_CFLAGS) -o $@ ANSIEscapeHelper.o $<

$(HIGHLIGHTER) : highlighter.c markdown_parser.o markdown_parser.h
	@echo '------- building highlighter'
	$(CC) $(CFLAGS) -o $@ markdown_parser.o $<

$(MULTITHREAD_TESTER) : multithread_tester.c markdown_parser.o markdown_parser.h
	@echo '------- building multithread_tester'
	$(CC) $(CFLAGS) -o $@ markdown_parser.o $<

$(BENCH) : bench.c markdown_parser.o markdown_parser.h
	@echo '------- building bench'
	$(CC) $(CFLAGS) -o $@ markdown_parser.o $<

docs: markdown_parser.h markdown_definitions.h doxygen/doxygen.cfg doxygen/doxygen.h doxygen/doxygen_footer.html example_cocoa/HGMarkdownHighlighter.h
	doxygen doxygen/doxygen.cfg
	touch docs

.PHONY: clean test

clean:
	rm -f markdown_parser_core.c markdown_parser.c *.o $(TESTER) $(TEST_CLIENT) $(HIGHLIGHTER) $(BENCH) $(MULTITHREAD_TESTER); \
	rm -rf *.dSYM; \
	make -C $(GREGDIR) clean

distclean: clean
	make -C $(GREGDIR) spotless

leak-check: $(TESTER)
	valgrind --leak-check=full ./$(TESTER) 100 todo.md

