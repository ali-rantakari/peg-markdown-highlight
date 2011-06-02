
### Primary stuff:

- Investigate using temporary attributes
	- In which way are they temporary? When are they removed?
- When copying to clipboard, remove highlights if possible (make this an option?)
- When an edit event comes to the highlighter, **don't do the timer if there
  is a parser running at the moment**, but act on the changes immediately
- Smarter matching:
    - Match whole blockquote area separately from blockquote indicator
    - Match actual content separately from syntax characters
- GUI widget for specifying highlighting styles
- Standardize whitespace style (spaces/tabs)


### Secondary stuff:

- Highlight footnote syntax
- Use same type for offsets in greg-generated parser code and additional
  parser code (now they're `int` and `unsigned long`).
- Implement (stress) tests for modifying several NSTextViews simultaneously
- Highlight HTML?


### Nice to have

- Option to remove whitespace after newlines for inline elements
- Reduce memory usage (profile with valgrind)
- .NET (C#) example of highlighting a `RichTextBox`
    - Need to create a wrapper assembly for the parser


### Maybe (or then maybe not):

- Ability to choose whether to highlight whole NSTextView when parsing is over
  or to only highlight visible area on scroll
    - Would make editing slower but scrolling faster.
    - Add widget to choose between these into the test app
- CSS (or similar) parser for defining colors + highlighting order
- _"[foo][bar] isn't a link in Markdown unless "bar" is defined somewhere"_ (?)
    - There are differing opinions about this...

