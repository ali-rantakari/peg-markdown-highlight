
PEG-Markdown-Highlight
========================

Description
------------------

This project contains:

- A Markdown parser for syntax highlighting, written in C99. The parser itself
  should compile as is on OS X, Linux and Windows (at least).
- Helper classes for syntax highlighting an `NSTextView` in a Cocoa GUI
  application

_Copyright 2011 Ali Rantakari_ -- <http://hasseg.org>

This program uses the PEG grammar from John McFarlane's `peg-markdown` project,
and the `peg/leg` parser generator by Ian Piumarta. Thanks to these gentlemen
(and everyone who contributed to their projects) for making this possible.



API Documentation
----------------------

The public APIs are documented using Doxygen. If you have it installed, just
run `make docs` and they should be available under the `docs/` directory.



Using the Parser in Your Application
-------------------------------------

You need to add the following files into your project:

- `markdown_definitions.h`
- `markdown_parser.h`
- `markdown_parser.c`
- `markdown_parser_head.c`
- `markdown_parser_foot.c`

*(Note that `markdown_parser.c` must be generated with `make`.)*

Then just `#import "markdown_parser.h"` and go wild. See the API docs for
more information.



Compiling in Microsoft Visual C++
-------------------------------------

First you need to generate `markdown_parser.c` somehow. There are two main
ways to do this:

- Use a Linux or OS X machine to generate it
- Generate it on Windows using MinGW (you'd run `make` in the MinGW shell)

Whichever way you go, the command you run is `make markdown_parser.c`.

The parser is written in C99, which MSVC does not explicitly support (it
apparently expects `.c` files to be C89), but the code should compile nicely as
C++ (just change the extensions to `.cpp` or set some magic switch in the
project settings to make them compile as C++).



