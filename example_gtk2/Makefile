all: gtkexample

gtkexample: gtkexample.c markdown_*
	gcc -Wall --std=c99 -g $< markdown_parser.c -o $@ `pkg-config --libs --cflags gtk+-2.0`

