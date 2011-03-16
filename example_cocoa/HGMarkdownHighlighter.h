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
	NSTimeInterval waitInterval;
	NSTextView *targetTextView;
	int extensions;
	BOOL isHighlighting;
	BOOL highlightAutomatically;
	NSArray *styles;

@private
	NSFontTraitMask clearFontTraitMask;
	NSColor *defaultTextColor;
	NSTimer *updateTimer;
	element **cachedElements;
	BOOL isDirty;
}

/** \brief The order and styles for higlighting different elements.
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
