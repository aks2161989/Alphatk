#!/usr/bin/env tclsh

lappend auto_path [pwd]/../..
package require pdf4tcl

pdf4tcl::new p1
p1 startPage 595 842
p1 write -file test0.pdf
p1 cleanup

