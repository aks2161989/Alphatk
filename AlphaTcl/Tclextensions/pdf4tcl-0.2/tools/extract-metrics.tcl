#!/usr/bin/env tclsh

# helper application -- extract char widths from afm file
# write a list of lists (char - width) to stdout

# Copyright (c) 2004 by Frank Richter <frichter@truckle.in-chemnitz.de>
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

# 2004-11-30  Frank Richter  output glyph names instead of character codes

puts stdout "
package provide pdf4tcl::metrics 0.1

# this file is auto-generated, please do NOT edit!

namespace eval pdf4tcl {
	variable font_widths
"

set lpath {/usr/share/fonts/afms/adobe}

foreach path $lpath {
	foreach file [glob -nocomplain [file join $path "*.afm"]] {
		set if [open $file "r"]
		set inMetrics 0
		set fontname ""
		array set widths {}
		while {[gets $if line]!=-1} {
			if {[regexp {^FontName\s*([^\s]*)} $line dummy match]} {
				set fontname $match
			}
			if {! $inMetrics} {
				if {[regexp {^StartCharMetrics} $line]} {
					set inMetrics 1
				}
			} else {
				if {[regexp {^EndCharMetrics} $line]} {
					break
				}
				if {[regexp {^C\s(-?\d*)\s*;\s*WX\s*(\d*)\s*;\s*N\s*([^;]*);} $line dummy ch w glyph_name]} {
					set char [format "%c" $ch]
					set glyph_name [string trim $glyph_name]
					scan $w "%d" w
#					set widths($char) $w
					set widths($glyph_name) $w
				}
			}
		}
		close $if
		set wl [array get widths]
#		puts stderr $wl
		puts stdout "set font_widths($fontname) \{$wl\}"
	}
}

puts stdout "}"

# vim: tw=0
