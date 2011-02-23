
### Primary stuff:

- UTF-8 support
    - Determine offsets reliably with UTF-8 input
- Problem with tabs/spaces? *(see `preformat_text()`)*


### Secondary stuff:

- Fix blockquote handling
- Implement highlighting for the rest of the language types
- Fix memory leaks
    - Valgrind
    - clang static analyzer _(useful for C code?)_


### Nice to have:

- Encapsulate
    - Into a C++ class?
    - Into an Objective-C class?
- Highlight disjoint spans separately
    - Not fully possible given the implementation right now (?)
    - Could be done as a post-processing step, albeit with a performance penalty
- _"[foo][bar] isn't a link in Markdown unless "bar" is defined somewhere"_ (?)
    - There are differing opinions about this...

