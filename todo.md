
### Primary stuff:

- Fix memory leaks
    - Valgrind
    - clang static analyzer _(useful for C code?)_
- Replace mangled UTF-8 characters with something else?
    - With what? Might have to replace alphas with `a`, puncs with `.`, numerics 
      with `1` etc.
    - Would it be just as fast (or slow) to transform to UTF-32?
        - But then the parser expects ASCII which UTF-8 is compatible with, so
          this would warrant more significant changes to it. Not good.


### Secondary stuff:

- Fix blockquote handling
- Implement highlighting for the rest of the language types
- Implement process isolation/separation
    - Highlighter stdin: `_markdown_ contents...`
    - Highlighter stdout: `1:0-10,32-39|13:9-10,12-15`


### Nice to have:

- Strip continuation bytes at the same time as reading stdin
- Encapsulate
    - Into a C++ class?
    - Into an Objective-C class?
- Highlight disjoint spans separately
    - Not fully possible given the implementation right now (?)
    - Could be done as a post-processing step, albeit with a performance penalty
- _"[foo][bar] isn't a link in Markdown unless "bar" is defined somewhere"_ (?)
    - There are differing opinions about this...
- CSS (or similar) parser for defining colors + highlighting order

