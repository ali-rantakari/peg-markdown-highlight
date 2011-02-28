#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
# Given a path to a Markdown file, calls `highlighter`, parses the output,
# and checks whether the positions (start offsets) of element spans are ordered
# (ascending or descending).
# 

import subprocess
import sys

if len(sys.argv) == 1:
    print >> sys.stderr, 'First argument must be path to .md file'
    sys.exit(1)

file_path = sys.argv[1]

print '-----reading %s' % file_path
f = open(file_path, 'r')
content = f.read()
f.close()

print '-----calling highlighter'
out = subprocess.Popen('./highlighter',
                       stdout=subprocess.PIPE,
                       stdin=subprocess.PIPE).communicate(input=content)[0]

print '-----checking output'
type_lists = [(y[0], y[1].split(','))
              for y in [x.split(':') for x in out.split('|')]]

# ignore the last element types
type_lists = type_lists[:-6]

w = lambda s: sys.stdout.write(s); sys.stdout.flush()

for t in type_lists:
    w('type %s: ' % t[0])
    pos_list = [int(x.split('-')[0]) for x in t[1]]
    if sorted(pos_list) == pos_list:
        w('ordered by pos, ascending')
    elif sorted(pos_list, reverse=True) == pos_list:
        w('ordered by pos, descending')
    else:
        w('NOT ORDERED BY POS: '+str(pos_list))
    w('\n')

