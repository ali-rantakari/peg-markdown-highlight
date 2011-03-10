
### Primary stuff:

- Interface in Obj-C for specifying highlighting styles
    - GUI widget for this?
- Implement (stress) tests for modifying several NSTextViews simultaneously


### Secondary stuff:

- Fix blockquote handling
- Implement highlighting for the rest of the language types
- CSS (or similar) parser for defining colors + highlighting order
- Enable supported extensions
    - Add interface to choose which ones to use
- Document (lack of) thread safety & re-entranness (is that a word?)
- Use a union to separate elements into language & parser classes


### Nice to have

- .NET (C#) example of highlighting a `RichTextBox`
    - Need to create a wrapper assembly for the parser
- GTK+ or Qt example of highlighting a rich text widget
- Reduce memory usage (profile with valgrind)



### Maybe (or then maybe not):

- Handle UTF-8 BOM?
- Ability to choose whether to highlight whole NSTextView when parsing is over
  or to only highlight visible area on scroll
    - Would it be better to highlight a copy of the NSTextStorage in the
      background thread and then switch it with the original in the foreground
      thread (assuming it hasn't changed, the checking of which would be of
      the utmost importance)?
    - Would make editing slower but scrolling faster.
    - Add widget to choose between these into the test app
- Highlight disjoint spans separately
    - Not fully possible given the implementation right now (?)
    - Could be done as a post-processing step, albeit with a performance penalty
- _"[foo][bar] isn't a link in Markdown unless "bar" is defined somewhere"_ (?)
    - There are differing opinions about this...
- Replace mangled UTF-8 characters with something else?
    - Is this even necessary? Need test cases.
    - With what? Might have to replace alphas with `a`, puncs with `.`, numerics 
      with `1` etc.
    - Would it be just as fast (or slow) to transform to UTF-32?
        - But then the parser expects ASCII which UTF-8 is compatible with, so
          this would warrant more significant changes to it. Not good.

