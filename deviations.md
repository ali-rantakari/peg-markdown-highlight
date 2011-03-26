
-------------------------------------------------------------------------------

The following applies to both `_` and `*` emphasis and strong:

Case:

    _text _here_

- Markdown.pl: `<em>text _here</em>`
- PEG-Markdown: `_text <em>here</em>`


-------------------------------------------------------------------------------

Case:

    - first
      
      second
      
        - third

Markdown.pl:

    <ul>
    <li><p>first</p>
    
    <p>second</p>
    
    <ul><li>third</li></ul></li>
    </ul>

PEG-Markdown:

    <ul>
    <li>first</li>
    </ul>
    
    <p>second</p>
    
    <pre><code>- third
    </code></pre>

