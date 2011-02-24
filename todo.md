
### Primary stuff:

- Problem with tabs/spaces? *(see `preformat_text()`)*
    - Ask John McFarlane why expand tabs to spaces when `Indent = "\t" | "    "`
- Fix memory leaks
    - Valgrind
    - clang static analyzer _(useful for C code?)_


### Secondary stuff:

- Fix blockquote handling
- Implement highlighting for the rest of the language types
- Implement process isolation/separation
    - Highlighter stdin: `_markdown_ contents...`
    - Highlighter stdout: `1:0-10,32-39|13:9-10,12-15`


### Nice to have:

- Encapsulate
    - Into a C++ class?
    - Into an Objective-C class?
- Highlight disjoint spans separately
    - Not fully possible given the implementation right now (?)
    - Could be done as a post-processing step, albeit with a performance penalty
- _"[foo][bar] isn't a link in Markdown unless "bar" is defined somewhere"_ (?)
    - There are differing opinions about this...

