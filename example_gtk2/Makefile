all: gtkexample

gtkexample: gtkexample.c pmh_*
	gcc -Wall --std=c99 -g $< pmh_parser.c -o $@ `pkg-config --libs --cflags gtk+-2.0`

