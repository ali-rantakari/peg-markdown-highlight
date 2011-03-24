
### Primary stuff:

- GUI widget for specifying highlighting styles
- Implement (stress) tests for modifying several NSTextViews simultaneously
- Highlight HTML?


### Secondary stuff:

- Implement highlighting for the rest of the language types
- Fix blockquote handling (umm.. what's wrong with it? I forgot)
- Enable supported extensions
    - Add interface to choose which ones to use


### Nice to have

- GTK+ or Qt example of highlighting a rich text widget
- Reduce memory usage (profile with valgrind)
- .NET (C#) example of highlighting a `RichTextBox`
    - Need to create a wrapper assembly for the parser
- Handle cases where memory could not be allocated (`malloc` etc. return `NULL`)


### Maybe (or then maybe not):

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
- CSS (or similar) parser for defining colors + highlighting order
- _"[foo][bar] isn't a link in Markdown unless "bar" is defined somewhere"_ (?)
    - There are differing opinions about this...

