#!/usr/bin/env tclsh

# extract glyph to unicode mapping from adobes glyphlist.txt
# TODO: insert url!

proc get_glyphnames {ch} {
	while {[gets $ch line]!=-1} {
		if {![regexp {^#} $line]} {
			foreach {glyph_name ucs2} [split $line ";"] {break}
			set g($ucs2) $glyph_name
		}
	}
	return [array get g]
}

puts stdout "
package provide pdf4tcl::glyphnames 0.1

# this file is auto-generated, please do NOT edit!

namespace eval pdf4tcl {
	variable glyph_names
"
puts stdout "array set glyph_names {[get_glyphnames stdin]}"

puts stdout "}"

# vim: tw=0

