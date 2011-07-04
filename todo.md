Parser
------
- Fix bug: image highlight when image label does not exist
- More granular matching of elements:
    - Match whole blockquote area separately from blockquote indicator
    - Match actual content separately from syntax characters (e.g. provide
      offsets for _whole area_, _content_ and _label_ for links like
      `[This is a link][label]`)
- Highlight footnote syntax
- Use same type for offsets in greg-generated parser code and additional
  parser code (now they're `int` and `unsigned long`).
- Highlight more HTML
    - Elements corresponding to Markdown elements
    - Other elements? (we have the HTML element type for that -- need more?)
- Reduce memory usage (profile with valgrind, Instruments or somesuch)


Cocoa
-----
- Investigate using temporary attributes
    - In which way are they temporary? When are they removed?
- When copying to clipboard, remove highlights if possible (make this an option?)
- When an edit event comes to the highlighter, **don't do the timer if there
  is a parser running at the moment**, but act on the changes immediately
- GUI widget for specifying highlighting styles
- Implement (stress) tests for modifying several NSTextViews simultaneously


Misc
----
- .NET (C#) example of highlighting a `RichTextBox`
    - Need to create a wrapper assembly for the parser or something like that?

