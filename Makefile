ALL : tester testclient highlighter

TEST_PROGRAM=tester
TEST_CLIENT_PROGRAM=testclient
PROGRAM=highlighter
CFLAGS ?= -Wall -O3
OBJC_CFLAGS=-framework Foundation -framework AppKit
PEGDIR=peg
LEG=$(PEGDIR)/leg

$(LEG):
	@echo '------- building peg/leg'
	CC=gcc make -C $(PEGDIR)

markdown_parser.c : markdown_parser.leg $(LEG) markdown_parser_header.c markdown_parser_footer.c
	$(LEG) -o $@ $<

$(TEST_PROGRAM) : tester.m markdown_parser.c markdown_parser.h ANSIEscapeHelper.m ANSIEscapeHelper.h
	@echo '------- building tester'
	clang $(CFLAGS) $(OBJC_CFLAGS) -o $@ markdown_parser.c ANSIEscapeHelper.m $<

$(TEST_CLIENT_PROGRAM) : testclient.m ANSIEscapeHelper.m ANSIEscapeHelper.h
	@echo '------- building testclient'
	clang $(CFLAGS) $(OBJC_CFLAGS) -o $@ ANSIEscapeHelper.m $<

$(PROGRAM) : highlighter.c markdown_parser.c markdown_parser.h
	@echo '------- building highlighter'
	cc $(CFLAGS) -DMKD_DEBUG_OUTPUT=0 -o $@ markdown_parser.c $<

docs: markdown_parser.h mkd_types.h doxygen.cfg
	doxygen doxygen.cfg
	touch docs

.PHONY: clean test

clean:
	rm -f markdown_parser.c $(TEST_PROGRAM) $(TEST_CLIENT_PROGRAM) $(PROGRAM) *.o; \
	make -C $(PEGDIR) clean

distclean: clean
	make -C $(PEGDIR) spotless

leak-check: $(TEST_PROGRAM)
	valgrind --leak-check=full ./$(TEST_PROGRAM) 100 todo.md

