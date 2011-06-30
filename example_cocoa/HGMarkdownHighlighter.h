/* PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * HGMarkdownHighlighter.h
 */

#import <Cocoa/Cocoa.h>
#import "markdown_definitions.h"

/**
 * \brief Highlighter for an NSTextView.
 *
 * Given a reference to an NSTextView, handles the highlighting of its
 * contents based on the Markdown syntax.
 */
@interface HGMarkdownHighlighter : NSObject
{
	NSTimeInterval waitInterval;
	NSTextView *targetTextView;
	int extensions;
	BOOL isActive;
	BOOL parseAndHighlightAutomatically;
	BOOL resetTypingAttributes;
	BOOL makeLinksClickable;
	NSArray *styles;

@private
	NSFontTraitMask clearFontTraitMask;
	NSColor *defaultTextColor;
	NSDictionary *defaultTypingAttributes;
	NSTimer *updateTimer;
	NSThread *workerThread;
	element **cachedElements;
	char *currentHighlightText;
	BOOL workerThreadResultsInvalid;
	BOOL styleDependenciesPending;
}

/** \brief The order and styles for higlighting different elements.
 * 
 * Values must be instances of HGMarkdownHighlightingStyle. The
 * order of objects in this array determines the highlighting order
 * for element types. You can use the helper macros defined in
 * HGMarkdownHighlightingStyle.h to create the array (see the
 * implementation of the private -getDefaultStyles method in this
 * class for an example).
 * 
 * \sa HGMarkdownHighlightingStyle
 * \sa element_type
 */
@property(copy) NSArray *styles;

/** \brief The delay between editing text and it getting highlighted. */
@property NSTimeInterval waitInterval;

/** \brief The NSTextView to highlight. */
@property(retain) NSTextView *targetTextView;

/** \brief Whether to parse and highlight after each change.
 * 
 * Whether this highlighter will automatically parse and
 * highlight the text whenever it changes, after a certain delay
 * (determined by waitInterval).
 * 
 * \sa waitInterval
 */
@property BOOL parseAndHighlightAutomatically;

/** \brief Whether this highlighter is active.
 * \sa activate
 * \sa deactivate
 */
@property BOOL isActive;

/** \brief Whether to reset typing attributes after highlighting.
 * 
 * Whether to reset the typing attributes of the NSTextView to
 * its default styles after each time highlighting is performed.
 * 
 * This feature depends on the values stored by readClearTextStylesFromTextView().
 */
@property BOOL resetTypingAttributes;

/** \brief Whether add hyperlink property to links.
 * 
 * Whether to make all links clickable (i.e. make them behave
 * like hyperlinks).
 */
@property BOOL makeLinksClickable;

/** \brief The extensions to use for parsing.
 * 
 * A bitfield of markdown_extensions values.
 * 
 * \sa markdown_extensions
 */
@property int extensions;


/** \brief Init new instance while setting targetTextView. */
- (id) initWithTextView:(NSTextView *)textView;
/** \brief Init new instance while setting targetTextView and waitInterval. */
- (id) initWithTextView:(NSTextView *)textView waitInterval:(NSTimeInterval)interval;
/** \brief Init new instance while setting targetTextView, waitInterval and styles. */
- (id) initWithTextView:(NSTextView *)textView waitInterval:(NSTimeInterval)interval styles:(NSArray *)inStyles;

/** \brief Read and store the representation of "clear" text
 *         from the current state of the NSTextView.
 * 
 * Use this method to tell this highlighter what "clear" formatting
 * should look like. The values stored by this method are used by
 * clearHighlighting().
 * 
 * Note that if you provide the target NSTextView in the init method
 * call, this method will be called automatically at that time.
 */
- (void) readClearTextStylesFromTextView;

/** \brief Manually invoke parsing and highlighting of the NSTextView contents. */
- (void) parseAndHighlightNow;

/** \brief Manually invoke highlighting (without parsing) of the NSTextView contents. */
- (void) highlightNow;

/** \brief Clear highlighting from the NSTextView.
 * 
 * This method depends on the values stored by readClearTextStylesFromTextView().
 */
- (void) clearHighlighting;

/** \brief Begin tracking changes in the NSTextView.
 * 
 * Begin listening for scroll events in the NSTextView's enclosing
 * scroll view and highlighting the visible range upon scrolling.
 * If parseAndHighlightAutomatically is YES, this method will make
 * the highlighter start listening for changes in the target
 * NSTextView's contents.
 * 
 * \sa deactivate
 */
- (void) activate;

/** \brief Stop tracking changes in the NSTextView.
 * \sa activate
 */
- (void) deactivate;


@end
