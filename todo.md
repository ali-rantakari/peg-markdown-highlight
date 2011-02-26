
### Primary stuff:

- Unify naming (don't use both `under_scores` and `camelCase`)
- Make it possible to use several highlighting textareas at the same time
    - Encapsulate implementation?
        - Problem: `peg` and its globals :( -- lots of work to fix
    - Maybe just highlight through a singleton that makes sure only one
      parsing job is running at a time? (sub-optimal but might be good enough).
- Replace mangled UTF-8 characters with something else?
    - Does lack of this cause trouble? Need test cases.
    - With what? Might have to replace alphas with `a`, puncs with `.`, numerics 
      with `1` etc.
    - Would it be just as fast (or slow) to transform to UTF-32?
        - But then the parser expects ASCII which UTF-8 is compatible with, so
          this would warrant more significant changes to it. Not good.


### Secondary stuff:

- Fix blockquote handling
- Implement highlighting for the rest of the language types


### Nice to have:

- Strip continuation bytes at the same time as reading stdin in `highlighter`
- Highlight disjoint spans separately
    - Not fully possible given the implementation right now (?)
    - Could be done as a post-processing step, albeit with a performance penalty
- _"[foo][bar] isn't a link in Markdown unless "bar" is defined somewhere"_ (?)
    - There are differing opinions about this...
- CSS (or similar) parser for defining colors + highlighting order

