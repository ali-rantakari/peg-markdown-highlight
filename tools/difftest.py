#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Given references to two programs and a path to a folder containing
# .md files, compares the outputs of the two programs against each other
# for each of the .md files.
#
# Useful for quick and dirty regression tests with manual validation.
#

from ansihelper import *


def difftest(old_program, new_program, md_file_paths):
    import sh
    import os

    num_files = len(md_file_paths)

    print 'Old program:', old_program
    print 'New program:', new_program
    print '%d files to check.' % num_files
    print '------'

    file_number = 1
    for md_file_path in md_file_paths:
        print '>> %d/%d Checking %s' % (file_number, num_files, md_file_path)
        old_output = sh.Command(old_program)(md_file_path)
        new_output = sh.Command(new_program)(md_file_path)
        if old_output == new_output:
            print green('   OK — no diffs.')
        else:
            print red('   DIFFS.')
        file_number += 1


def main():
    import sys
    import os
    old_program = os.path.abspath(sys.argv[1])
    new_program = os.path.abspath(sys.argv[2])
    folder_path = sys.argv[3]
    md_file_paths = [os.path.join(folder_path, f) for f in os.listdir(folder_path)
                     if os.path.isfile(os.path.join(folder_path, f))
                        and f.endswith(".md")]
    difftest(old_program, new_program, md_file_paths)


main()
