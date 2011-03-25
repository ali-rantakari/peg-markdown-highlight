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
	BOOL isActive;
	BOOL highlightAutomatically;
	BOOL resetTypingAttributes;
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
}

/** \brief The order and styles for higlighting different elements.
 * Values must be instances of HGMarkdownHighlightingStyle. The
 * order of objects in this array determines the highlighting order
 * for element types.
 * 
 * \sa HGMarkdownHighlightingStyle
 * \sa element_type
 */
@property(copy) NSArray *styles;

/** \brief The delay between editing text and it getting highlighted. */
@property NSTimeInterval waitInterval;

/** \brief The NSTextView to highlight. */
@property(retain) NSTextView *targetTextView;

/** \brief Whether to automatically highlight.
 * Whether this highlighter will automatically parse and
 * highlight the text whenever it changes, after a certain delay
 * (determined by waitInterval).
 * 
 * \sa waitInterval
 */
@property BOOL highlightAutomatically;

/** \brief Whether this highlighter is active.
 * 
 * \sa activate
 * \sa deactivate
 */
@property BOOL isActive;

/** \brief Whether to reset typing attributes after highlighting.
 * Whether to reset the typing attributes of the NSTextView to
 * its default styles after each time highlighting is performed.
 */
@property BOOL resetTypingAttributes;

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

/** \brief Manually parse and highlight the NSTextView contents.
 * 
 */
- (void) parseAndHighlightNow;

/** \brief Begin highlighting the NSTextView.
 * 
 * 
 */
- (void) activate;

/** \brief Stop highlighting the NSTextView.
 * 
 * 
 */
- (void) deactivate;


@end
