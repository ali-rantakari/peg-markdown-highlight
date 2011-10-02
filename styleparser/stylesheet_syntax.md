
The Syntax of PEG Markdown Highlight Stylesheets
================================================

[PEG Markdown Highlight][pmh] includes a parser for stylesheets that define how different Markdown language elements are to be highlighted. This document describes the syntax of these stylesheets.

[pmh]: http://hasseg.org/peg-markdown-highlight/


Example
-------

Here is a quick, simple example of a stylesheet:

    # The first comment lines describe the
    # stylesheet.
    
    editor:
      foreground: ff0000 # red text
      background: 000000
    
    H1:
      font-size: 14
      font-style: bold, underlined
    
    EMPH:
      font-style: italic


Style Rules
-----------

A stylesheet is composed of one or more *rules*. Rules are separated from each other by **empty lines** like so:

    H2:
    foreground: ff0000
    
    H3:
    foreground: 00ff00

Each begins with the ***name* of the rule**, which is always on its own line, and may be one of the following:

- **`editor`**: Styles that apply to the whole document/editor
- **`editor-current-line`**: Styles that apply to the current line in the editor (i.e. the line where the caret is)
- **`editor-selection`**: Styles that apply to the selected range in the editor when the user makes a selection in the text
- A Markdown element type (like `EMPH`, `REFERENCE` or `H1`): Styles that apply to occurrences of that particular element

The name may be optionally prefixed with an assignment operator (either `:` or `=`):

    H1:
    foreground: ff00ff
    
    H2 =
    foreground: ff0000
    
    H3
    foreground: 00ff00

The **order of style rules is significant**; it defines the order in which different language elements should be highlighted. *(Of course applications that use PEG Markdown Highlight and the style parser may disregard this and highlight elements in whatever order they desire.)*

After the name of the rule, there can be one or more *attributes*.


Style Attributes
----------------

Attribute assignments are each on their own line, and they consist of the *name* of the attribute as well as the *value* assigned to it. An assignment operator (either `:` or `=`) separates the name from the value:

    attribute-name: value
    attribute-name= value

Attribute assignment lines **may be indented**.

### Attribute Names and Types

The following is a list of all valid attribute names, and the values that may be defined for them:

- `foreground-color` *(aliases: `foreground` and `color`)*
    - See the *Color Attribute Values* subsection for information about valid values for this attribute.
- `background-color` *(alias: `background`)*
    - See the *Color Attribute Values* subsection for information about valid values for this attribute.
- `caret-color` *(alias: `caret`)*
    - See the *Color Attribute Values* subsection for information about valid values for this attribute.
- `font-size`
    - An integer value for the font size, *in points* (i.e. not in pixels). The number may have a textual suffix such as `pt`.
- `font-family`
    - A comma-separated list of one or more arbitrary font family names. *(It is up to the application that uses the PEG Markdown Highlight library to resolve this string to actual fonts on the system.)*
- `font-style`
    - A comma-separated list of one or more of the following:
        - `italic`
        - `bold`
        - `underlined`

## Color Attribute Values

Colors can be specified either in **RGB** (red, green, blue) or **ARGB** (alpha, red, green, blue) formats. In both, each component is a two-character hexadecimal value (from `00` to `FF`):

    foreground: ff00ee  # red = ff, green = 00, blue = ee (and implicitly, alpha = ff)
    background: 99ff00ee  # alpha = 99, red = ff, green = 00, blue = ee


Comments
--------

Each line in a stylesheet may have a comment. The `#` character begins a line comment that continues until the end of the line:

    # this line has only this comment
    H1:  # this line has a style rule name and then a comment
    foreground: ff0000  # this line has an attribute and then a comment









