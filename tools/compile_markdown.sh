#!/bin/sh

DN=`dirname $0`
THISDIR="`cd $DN; pwd`"

echo '<!DOCTYPE html>'
echo '<html lang="en">'
echo '<head>'
echo '  <meta charset="utf-8" />'
echo '  <link href="markdown.css" rel="stylesheet"></link>'
echo "  <title>${2}</title>"
echo '</head>'
echo '<body>'
"${THISDIR}/Markdown.pl" < "${1}"
echo '</body>'
echo '</html>'

