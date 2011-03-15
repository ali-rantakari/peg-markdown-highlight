#import <Cocoa/Cocoa.h>
#import "markdown_definitions.h"

/**
 * \brief Highlighter for an NSTextView.
 *
 * Given a reference to an NSTextView, handles the highlighting of its
 * contents based on the Markdown syntax.
 *
 */
@interface HGMarkdownHighlighter : NSObject
{
	NSFont *defaultFont;
	NSTimeInterval waitInterval;
	NSTextView *targetTextView;
	int extensions;
	BOOL isHighlighting;
	BOOL highlightAutomatically;
	NSArray *styles;

@private
	NSTimer *updateTimer;
	element **cachedElements;
}

/** \brief The styles to highlight different language elements with.
 * Values must be instances of HGMarkdownHighlightingStyle. The
 * order of objects in this array determines the highlighting order
 * for element types.
 * 
 * \sa element_type
 */
@property(copy) NSArray *styles;

/** \brief The delay between editing text and it getting highlighted. */
@property NSTimeInterval waitInterval;

/** \brief The NSTextView to highlight. */
@property(retain) NSTextView *targetTextView;

/** \brief Whether this highlighter is active.
 * 
 * \sa startHighlighting
 */
@property BOOL isHighlighting;

/** \brief Whether to automatically highlight.
 * Whether this highlighter will automatically parse and
 * highlight the text whenever it changes, after a certain delay
 * (determined by waitInterval).
 * 
 * \sa waitInterval
 */
@property BOOL highlightAutomatically;

/** \brief The extensions to use for parsing.
 * 
 * A bitfield of markdown_extensions values.
 * 
 * \sa markdown_extensions
 */
@property int extensions;


@property(copy) NSFont *defaultFont;


/**
 * 
 * 
 */
- (id) initWithTextView:(NSTextView *)textView;

/** \brief Manually highlight the NSTextView.
 * 
 */
- (void) parseAndHighlightNow;

/** \brief Begin highlighting the NSTextView.
 * 
 * 
 */
- (void) startHighlighting;

/** \brief Stop highlighting the NSTextView.
 * 
 * 
 */
- (void) stopHighlighting;


@end
