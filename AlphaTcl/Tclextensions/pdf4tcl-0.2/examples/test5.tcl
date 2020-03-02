#!/usr/bin/env tclsh

lappend auto_path [pwd]/..
package require pdf4tcl

pdf4tcl::new p1 -compress false -paper a4
p1 startPage

p1 line 100 100 200 200
p1 circle 0 100 100 50
p1 arc 100 100 90 0 90
p1 arc 100 100 85 15 135
p1 arc 100 100 85 5 -135
p1 write -file test5.pdf
p1 cleanup
