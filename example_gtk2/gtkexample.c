/* PEG Markdown Highlight
 * Copyright 2011-2012 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * gtkexample.c
 * 
 * GTK+ example for highlighting a rich text widget.
 */

#include <gtk/gtk.h>
#include <string.h>
#include "pmh_parser.h"

// Element in list of text style tags
typedef struct TagListelem
{
	GtkTextTag *tag;
	struct TagListelem *next;
} tag_listelem;

tag_listelem *mk_listelem(GtkTextTag *tag)
{
	tag_listelem *e = (tag_listelem *)malloc(sizeof(tag_listelem));
	e->tag = tag;
	e->next = NULL;
	return e;
}

tag_listelem *add_tag_listelem(tag_listelem *list, tag_listelem *new_elem)
{
	new_elem->next = list;
	return new_elem;
}

// Create and return table (array) of linked lists of text style
// tags, indexed by Markdown language element type.
tag_listelem **make_tags_table(GtkTextBuffer *buffer)
{
	tag_listelem **tags_table = (tag_listelem **)malloc(sizeof(tag_listelem*)
														* pmh_NUM_LANG_TYPES);
	for (int i = 0; i < pmh_NUM_LANG_TYPES; i++)
		tags_table[i] = NULL;

	#define ADDTAG(type,name,value) tags_table[type] = add_tag_listelem(tags_table[type], mk_listelem(gtk_text_buffer_create_tag(buffer, NULL, name, value)))

	ADDTAG(pmh_H6, "foreground", "#0000ff");
	ADDTAG(pmh_H6, "weight", PANGO_WEIGHT_BOLD);
	tags_table[pmh_H1] = tags_table[pmh_H2] =
	tags_table[pmh_H3] = tags_table[pmh_H4] =
	tags_table[pmh_H5] = tags_table[pmh_H6];

	ADDTAG(pmh_EMPH, "foreground", "#999900");
	ADDTAG(pmh_EMPH, "style", PANGO_STYLE_ITALIC);
	ADDTAG(pmh_STRONG, "foreground", "#990099");
	ADDTAG(pmh_STRONG, "weight", PANGO_WEIGHT_BOLD);

	ADDTAG(pmh_LINK, "background", "#ccccff");
	tags_table[pmh_AUTO_LINK_EMAIL] = tags_table[pmh_AUTO_LINK_URL] = tags_table[pmh_LINK];

	ADDTAG(pmh_CODE, "foreground", "#3e6b3e");
	ADDTAG(pmh_CODE, "background", "#e1e6e1");
	tags_table[pmh_VERBATIM] = tags_table[pmh_CODE];

	ADDTAG(pmh_HRULE, "foreground", "#cccccc");
	ADDTAG(pmh_HRULE, "background", "#eeeeee");

	ADDTAG(pmh_LIST_BULLET, "foreground", "#990099");
	tags_table[pmh_LIST_ENUMERATOR] = tags_table[pmh_LIST_BULLET];

	ADDTAG(pmh_IMAGE, "foreground", "#4a5a77");
	ADDTAG(pmh_IMAGE, "background", "#d8dde6");
	
	ADDTAG(pmh_REFERENCE, "foreground", "#9f92ad");
	ADDTAG(pmh_REFERENCE, "background", "#e9e1f2");
	
	ADDTAG(pmh_COMMENT, "foreground", "#999999");
	
	return tags_table;
}

// Return linked list of tags to apply for occurrences
// of the language element `type`
tag_listelem *tags_for_type(GtkTextBuffer *buffer, pmh_element_type type)
{
	static tag_listelem **tags_table;
	if (tags_table == NULL)
		tags_table = make_tags_table(buffer);
	return tags_table[type];
}

void highlight_buffer(GtkTextBuffer *buffer)
{
	GtkTextIter start;
	GtkTextIter end;
	gchar *text;
	gtk_text_buffer_get_start_iter(buffer, &start);
	gtk_text_buffer_get_end_iter(buffer, &end);
	text = gtk_text_buffer_get_text(buffer, &start, &end, FALSE);

	pmh_element **result = NULL;
	pmh_markdown_to_elements((char *)text, pmh_EXT_NONE, &result);

	gtk_text_buffer_remove_all_tags(buffer, &start, &end);

	for (int i = 0; i < pmh_NUM_LANG_TYPES; i++)
	{
		tag_listelem *tags = tags_for_type(buffer, i);
		if (tags == NULL)
			continue;

		pmh_element *cur = result[i];
		while (cur != NULL)
		{
			GtkTextIter posIter;
			GtkTextIter endIter;
			gtk_text_buffer_get_iter_at_offset(buffer, &posIter,
											   (gint)cur->pos);
			gtk_text_buffer_get_iter_at_offset(buffer, &endIter,
											   (gint)cur->end);
			tag_listelem *tagcur = tags;
			while (tagcur != NULL)
			{
				gtk_text_buffer_apply_tag(buffer, tagcur->tag,
										  &posIter, &endIter);
				tagcur = tagcur->next;
			}
			cur = cur->next;
		}
	}

	pmh_free_elements(result);
	g_free(text);
}


guint edit_timeout_interval_ms = 0;
gint edit_timeout_id = -1;

gboolean on_edit_timeout(gpointer data)
{
	highlight_buffer((GtkTextBuffer *)data);
	return FALSE;
}

void on_buffer_changed(GtkTextBuffer *buffer, GtkTextView *text_view)
{
	// scroll to show cursor
	/*
	GtkTextIter iter;
	gint x = gtk_text_view_virtual_cursor_x(text_view);
	gint y = gtk_text_view_virtual_cursor_y(text_view);
	gtk_text_view_get_iter_at_location(text_view, &iter, x, y);
	gtk_text_view_scroll_to_iter(text_view, &iter, 0,false,0,0);
	*/
	
	// (re)set highlight timer
	if (edit_timeout_id != -1)
		g_source_remove((guint)edit_timeout_id);
	edit_timeout_id = (gint)g_timeout_add(edit_timeout_interval_ms,
										  on_edit_timeout, (gpointer)buffer);
}



#define READ_BUFFER_LEN 1024
char *get_file_contents(char *path)
{
	FILE *fh = fopen(path, "rt");
	
	char buffer[READ_BUFFER_LEN];
	size_t content_len = 1;
	char *content = malloc(sizeof(char) * READ_BUFFER_LEN);
	content[0] = '\0';
	
	while (fgets(buffer, READ_BUFFER_LEN, fh))
	{
		content_len += strlen(buffer);
		content = realloc(content, content_len);
		strcat(content, buffer);
	}
	
	fclose(fh);
	return content;
}



void on_window_destroy(GtkWidget *widget, gpointer data)
{
	gtk_main_quit();
}


int main(int argc, char *argv[])
{
	gtk_init(&argc, &argv);
	
	// Main window and container box
	GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	gtk_window_set_title(GTK_WINDOW(window), "Simple Multiline Text Input");
	gtk_window_set_default_size(GTK_WINDOW(window), 450, 600);
	g_signal_connect(G_OBJECT(window), "destroy", 
					 G_CALLBACK(on_window_destroy),
					 NULL);
	GtkWidget *vbox = gtk_vbox_new(FALSE, 2);
	gtk_container_add(GTK_CONTAINER(window), vbox);
	
	// Scroll window and text view
	GtkWidget *scrolled_window = gtk_scrolled_window_new(NULL, NULL);
	gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scrolled_window),
								   GTK_POLICY_NEVER, GTK_POLICY_ALWAYS);
	gtk_box_pack_start(GTK_BOX(vbox), scrolled_window, 1, 1, 0);

	GtkWidget *text_view = gtk_text_view_new();
	gtk_text_view_set_wrap_mode(GTK_TEXT_VIEW(text_view), GTK_WRAP_WORD);
	PangoFontDescription *font_descr = pango_font_description_from_string(
															"DejaVu Sans Mono");
	gtk_widget_modify_font(text_view, font_descr);
	gtk_scrolled_window_add_with_viewport(GTK_SCROLLED_WINDOW(scrolled_window),
										  text_view);
	
	// Set contents to text view buffer
	GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(text_view));
	char *contents = get_file_contents("big.md");
	gtk_text_buffer_set_text(buffer, contents, -1);
	
	// Set handler for buffer change event
	highlight_buffer(buffer);
	g_signal_connect(G_OBJECT(buffer), "changed",
					 G_CALLBACK(on_buffer_changed), GTK_TEXT_VIEW(text_view));

	gtk_widget_show_all(window);
	gtk_main();
	return 0;
}
