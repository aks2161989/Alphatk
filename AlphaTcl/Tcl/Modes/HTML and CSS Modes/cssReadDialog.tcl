## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  CSS mode - tools for editing CSS documents
 # 
 #  FILE: "cssReadDialog.tcl"
 #                                    created: 00-01-02 00.24.27 
 #                                last update: 2005-02-21 17:51:18 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 2.2
 # 
 # Copyright 1997-2003 by Johan Linde
 #  
 # This program is free software; you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation; either version 2 of the License, or
 # (at your option) any later version.
 # 
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 # 
 # You should have received a copy of the GNU General Public License
 # along with this program; if not, write to the Free Software
 # Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 # 
 # ###################################################################
 ##

#===============================================================================
# This file contain procs for reading the CSS property dialogs.
# For each type of property there is a proc
# css::ReadDialog<type>
#===============================================================================

#===============================================================================
# ×××× Reading dialog values ×××× #
#===============================================================================

# group
proc css::ReadDialoggroup {group v ind imp ptext etext} {
	upvar $v val $ind index $imp important $ptext proptext $etext errText
	
	global css::Group css::Property css::Descriptor css::IsDescriptor
	foreach prop [set css::Group($group)] {
		if {${css::IsDescriptor}} {
			set p [set css::Descriptor($prop)]
		} else {
			set p [set css::Property($prop)]
		}
		set curr $proptext
		eval css::ReadDialog$p $prop val index important proptext errText
		if {[string length $proptext] > [string length $curr] && 
		([info exists important($prop)] || [info exists important($group)])} {
			append proptext " ! important"
		}
	}
}

# @charset
proc css::ReadDialog@charset {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext
	if {[set txt [string trim [lindex $val $index] "\" "]] != ""} {
		append proptext ";\r$prop \"$txt\""
	}
}

# @import
proc css::ReadDialog@import {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext
	if {[set txt [css::ReadUrl val index]] != ""} {
		append txt [css::ReadMediaList val index]
		append proptext ";\r$prop$txt"
	} else {
		incr index 2
	}
}

# @media
proc css::ReadDialog@media {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext
	if {[set txt [css::ReadMediaList val index]] != ""} {
		append proptext ";\r$prop$txt"
	}
}

# @page
proc css::ReadDialog@page {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext
	incr index
	append proptext ";\r$prop [string trim [lindex $val [expr {$index - 1}]][css::ReadChoiceList 1 val index]]"
}

# choices
proc css::ReadDialogchoices {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext
	if {[set txt [css::ReadChoiceList 1 val index]] != ""} {
		append proptext ";\r$prop:$txt"
	}
}

# color
proc css::ReadDialogcolor {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {([set txt [css::ReadChoiceList 0 val index inherit]] != "" && [incr index 3]) || 
	[set txt [css::ReadColor $prop val index errtext]] != ""} {
		append proptext ";\r$prop:$txt"
	}
}

# url
proc css::ReadDialogurl {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext
	if {([set txt [css::ReadChoiceList 0 val index inherit]] != "" && [incr index 3]) || 
	[set txt [css::ReadUrl val index]] != ""} {
		append proptext ";\r$prop:$txt"
	}
}

# family = like font-family and voice-family
proc css::ReadDialogfamily {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext
	if {[set txt [css::ReadChoiceList 1 val index]] != " inherit"} {
		set txt " [string trim [join [list [lindex $val $index] $txt] ,] " ,"]"
	}
	if {![is::Whitespace $txt]} {append proptext ";\r$prop:$txt"}
	incr index 2
}

# integer
proc css::ReadDialoginteger {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {([set txt [css::ReadChoiceList 0 val index inherit]] != "" && [incr index]) || 
	[set txt [css::ReadNumberNoUnit $prop val index 0 1 errtext]] != ""} {
		append proptext ";\r$prop:$txt"
	}
}

# number
proc css::ReadDialognumber {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {([set txt [css::ReadChoiceList 0 val index inherit]] != "" && [incr index]) || 
	[set txt [css::ReadNumberNoUnit $prop val index 0 0 errtext]] != ""} {
		append proptext ";\r$prop:$txt"
	}
}

# nlpc = number, length, percentage, or choices
proc css::ReadDialognlpc {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	css::ReadNumChoices $prop val index length 1 1 0 proptext errtext
}

# lpc = length, percentage, or choices
proc css::ReadDialoglpc {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	css::ReadNumChoices $prop val index length 1 0 0 proptext errtext
}

# npc = number, percentage, or choices
proc css::ReadDialognpc {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	css::ReadNumChoices $prop val index number 1 1 1 proptext errtext
}

# lc = length or choices
proc css::ReadDialoglc {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	css::ReadNumChoices $prop val index length 0 0 0 proptext errtext
}

# ac = angle or choices
proc css::ReadDialogac {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	css::ReadNumChoices $prop val index angle 0 0 0 proptext errtext
}

# fc = frequency or choices
proc css::ReadDialogfc {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	css::ReadNumChoices $prop val index frequency 0 0 0 proptext errtext
}

# cc = color or choices
proc css::ReadDialogcc {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {([set txt [css::ReadChoiceList 1 val index]] != "" && [incr index 3]) || 
	[set txt [css::ReadColor $prop val index errtext]] != ""} {
		append proptext ";\r$prop:$txt"
	}	
}

# uc = url or choices
proc css::ReadDialoguc {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {([set txt [css::ReadChoiceList 1 val index]] != "" && [incr index 3]) || 
	[set txt [css::ReadUrl val index]] != ""} {
		append proptext ";\r$prop:$txt"
	}	
}

# lp = length or percentage
proc css::ReadDialoglp {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {([set txt [css::ReadChoiceList 0 val index inherit]] != "" && [incr index 2]) || 
	[set txt [css::ReadNumber $prop val index length 1 0 0 errtext]] != ""} {
		append proptext ";\r$prop:$txt"
	}	
}

# tp = time or percentage
proc css::ReadDialogtp {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {([set txt [css::ReadChoiceList 0 val index inherit]] != "" && [incr index 2]) || 
	[set txt [css::ReadNumber $prop val index time 1 0 0 errtext]] != ""} {
		append proptext ";\r$prop:$txt"
	}	
}

# ic = integer or choices
proc css::ReadDialogic {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {([set txt [css::ReadChoiceList 1 val index]] != "" && [incr index 2]) || 
	[set txt [css::ReadNumberNoUnit $prop val index 0 1 errtext]] != ""} {
		append proptext ";\r$prop:$txt"
	}	
}

# nc = number or choices
proc css::ReadDialognc {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {([set txt [css::ReadChoiceList 1 val index]] != "" && [incr index 1]) || 
	[set txt [css::ReadNumberNoUnit $prop val index 0 0 errtext]] != ""} {
		append proptext ";\r$prop:$txt"
	}	
}

# border
proc css::ReadDialogborder {prop v ind imp ptext etext} {
	upvar $v val $ind index $imp important $ptext proptext $etext errtext
	css::ReadDialoggroup $prop val index important proptext errtext
	regsub -all -- "-top-" $proptext "-" proptext
}

# clip
proc css::ReadDialogclip {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {[set txt [css::ReadChoiceList 1 val index]] != ""} {
		incr index 12
		append proptext ";\rclip:$txt"
	} else {
		set txt ""
		for {set i 0} {$i < 4} {incr i} {
			if {([set txt1 [css::ReadChoiceList 0 val index auto]] != "" && [incr index 2]) || 
			[set txt1 [css::ReadNumber clip val index length 0 0 0 errtext]] != ""} {
				append txt $txt1
			}
		}
		if {[llength $txt]} {
			if {[llength $txt] != 4} {
				lappend errtext "clip: All four sides must be specified."
			} else {
				append proptext ";\rclip: rect([join $txt ", "])"
			}
		}
	}
}

# quotes
proc css::ReadDialogquotes {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {[set txt [css::ReadChoiceList 1 val index]] != ""} {
		append proptext ";\r$prop:$txt"
	} elseif {[set txt [string trim [lindex $val [incr index 3]]]] != ""} {
		if {![regexp {^(('[^']+'|\"[^\"]+\")[ \t\r\n]+('[^']+'|\"[^\"]+\")[ \t\r\n]+)+$} "$txt "]} {
			lappend errtext "$prop: An even number of strings required."
		} else {
			append proptext ";\r$prop: $txt"
		}
	}
	incr index
}

# counter
proc css::ReadDialogcounter {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {[set txt [css::ReadChoiceList 1 val index]] != ""} {
		append proptext ";\r$prop:$txt"
	} elseif {[set txt [string trim [lindex $val $index]]] != ""} {
		if {![regexp {^([^-0-9][^ \t\r\n]*([ \t\r\n]+[-\+]?[0-9]+)?[ \t\r\n]+)+$} "$txt "]} {
			lappend errtext "$prop: Incorrect data."
		} else {
			append proptext ";\r$prop: $txt"
		}
	}
	incr index
}

# size
proc css::ReadDialogsize {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {([set txt [css::ReadChoiceList 1 val index]] != "" && [incr index 4]) || 
	[set txt "[css::ReadNumber $prop val index length 0 0 0 errtext][css::ReadNumber $prop val index length 0 0 0 errtext]"] != ""} {
		append proptext ";\r$prop:$txt"
	}
}

# content
proc css::ReadDialogcontent {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {[set txt [css::ReadChoiceList 1 val index]] == " inherit"} {
		append proptext ";\r$prop:$txt"
	} elseif {[append txt " " [lindex $val $index]] != " "} {
		append proptext ";\r$prop: [string trim $txt]"
	}
}

# marks
proc css::ReadDialogmarks {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {[set txt [css::ReadChoiceList 1 val index]] != "" && [incr index 2]} {
		append proptext ";\r$prop:$txt"
	} else {
		if {[lindex $val $index]} {set txt crop}
		if {[lindex $val [expr {$index + 1}]]} {append txt " cross"}
		incr index 2
		if {$txt != ""} {append proptext ";\r$prop: [string trim $txt]"}
	}
}

# page
proc css::ReadDialogpage {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {[lindex $val $index]} {
		append proptext ";\rpage: auto"
	} elseif {[set txt [string trim [lindex $val [incr index]]]] != ""} {
		if {![regexp {^[^-0-9][^ \t\r\n]*$} $txt]} {
			lappend errtext "$prop: Invalid indentifier: $txt"
		} else {
			append proptext ";\rpage: $txt"
		}
	}
}

# backpos
proc css::ReadDialogbackpos {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {[lindex $val $index] && [incr index 7]} {
		append proptext ";\r$prop: inherit"
	} elseif {[incr index] && [llength [set txt "[css::ReadChoiceList 1 val index][css::ReadChoiceList 1 val index]"]] == 2} {
		append proptext ";\r$prop:$txt"
	} elseif {[set txt2 "[css::ReadNumber $prop val index length 1 0 0 errtext][css::ReadNumber $prop val index length 1 0 0 errtext]"] != ""} {
		if {[llength $txt2] == 2} {
			set p1 [regexp % [lindex $txt2 0]]
			set p2 [regexp % [lindex $txt2 1]]
			if {$p1 && !$p2 || !$p1 && $p2} {
				lappend errtext "$prop: Mixing length and percentage not allowed,$txt2"
			} else {
				append proptext ";\r$prop:$txt2"
			}
		} else {
			append proptext ";\r$prop:$txt2"
		}			
	} elseif {[llength $txt] == 1} {
		lappend errtext "$prop: Both sides must be specified, not only '[string trim $txt]'."
	}
}

# font
proc css::ReadDialogfont {prop v ind imp ptext etext} {
	upvar $v val $ind index $imp important $ptext proptext $etext errtext
	css::ReadDialoggroup $prop val index important proptext errtext
	if {[set fval [lindex $val $index]] != " "} {
		set proptext ";\r$prop: $fval"
		if {[info exists important($prop)]} {append proptext " ! important"}
	}
}

# fontstyle
proc css::ReadDialogfontstyle {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	global css::Choices
	if {[lindex $val [expr {$index + 3}]] && [incr index 4]} {
		append proptext ";\r$prop: all"
	} else {
		set txt [string trim "[css::ReadChoiceList 1 val index], [lindex $val $index]" ", "]
		incr index 3
		foreach c [split $txt ,] {
			if {![lcontains css::Choices($prop) [string trim $c]]} {
				append tmperr $c
			}
		}
		if {[info exists tmperr]} {
			lappend errtext "$prop: Incorrect descriptor(s), $tmperr"
		} elseif {$txt != ""} {
			append proptext ";\r$prop: $txt"
		}
	}
}

# fontvariant
proc css::ReadDialogfontvariant {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	global css::Choices
	set txt [string trim "[css::ReadChoiceList 1 val index], [lindex $val $index]" ", "]
	incr index 2
	foreach c [split $txt ,] {
		if {![lcontains css::Choices($prop) [string trim $c]]} {
			append tmperr $c
		}
	}
	if {[info exists tmperr]} {
		lappend errtext "$prop: Incorrect descriptor(s), $tmperr"
	} elseif {$txt != ""} {
		append proptext ";\r$prop: $txt"
	}
}

# fontsize
proc css::ReadDialogfontsize {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {[lindex $val [expr {$index  + 4}]] && [incr index 5]} {
		append proptext ";\r$prop: all"
	} else {
		incr index
		set txt [string trim "[css::ReadNumber $prop val index length 0 0 0 errtext], [lindex $val $index]" ", "]
		incr index 2
		foreach c [split $txt ,] {
			if {[catch {css::CheckNumber $prop length [string trim $c] "" 0 0 0}]} {
				append tmperr $c
			}
		}
		if {[info exists tmperr]} {
			lappend errtext "$prop: Incorrect descriptor(s), $tmperr"
		} elseif {$txt != ""} {
			append proptext ";\r$prop: $txt"
		}
	}
}

# panose
proc css::ReadDialogpanose {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	for {set i 0} {$i < 10} {incr i} {
		append txt [css::ReadNumberNoUnit $prop val index 0 1 errtext]
	}
	if {[llength $txt] && [llength $txt] != 10} {
		lappend errtext "$prop: All 10 numbers must be specified"
	} elseif {[llength $txt]} {
		append proptext ";\r$prop:$txt"
	}
}

# widths
proc css::ReadDialogwidths {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	set vlist [split [string toupper [string trim [lindex $val $index]]] ,]
	set err ""; set vv ""
	foreach u $vlist {
		set e 0
		set ur [lindex [string trim $u] 0]
		if {![css::CheckUrange $ur] && ![regexp {^[0-9]+$} $ur]} {
			set e 1
			lappend err $ur
		} 
		foreach n [lrange $u 1 end] {
			if {![regexp {^[0-9]+$} $n]} {lappend err $n}
		}
		append vv ", [string trim $u]"
		if {!$e && [llength $u] == 1 && ![regexp {^[0-9]+$} $ur]} {
			lappend err $u
		}
	}
	if {[llength $vlist]} {append proptext ";\r$prop:[string trimleft $vv ,]"}
	if {$err != ""} {lappend errtext "$prop: [join $err]"}
	incr index
}

# bbox
proc css::ReadDialogbbox {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	set n 0
	set orgerr $errtext
	for {set i 0} {$i < 4} {incr i} {
		set txt [css::ReadNumberNoUnit $prop val index 0 1 errtext]
		if {$txt != ""} {incr n}
		lappend t $txt
	}
	if {$n == 4} {
		append proptext ";\r$prop:[join $t ","]"
	} elseif {$n && $orgerr == $errtext} {
		lappend errtext "$prop: All four numbers must be specified."
	}
}

# unirange
proc css::ReadDialogunirange {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	set vlist [split [string toupper [string trim [lindex $val $index]]] ,]
	set err ""; set vv ""
	foreach u $vlist {
		if {![css::CheckUrange [string trim $u]]} {
			lappend err $u
		} else {
			append vv ", [string trim $u]"
		}
	}
	if {[llength $vlist]} {append proptext ";\r$prop:[string trimleft $vv ,]"}
	if {$err != ""} {lappend errtext "$prop: [join $err]"}
	incr index
}

# src
proc css::ReadDialogsrc {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	set src [set src0 [string trim [lindex $val [incr index 6]]]]
	incr index
	if {$src == ""} {return}
	while {[regsub -nocase "^((url\\(\[ \t\r\n\]*(\"\[^\"\]+\"|'\[^'\]+'|\[^\"' \t\r\n\]+)\[ \t\r\n\]*\\)\[ \t\r\n\]*(format\\((\"\[^\"\]+\"|'\[^'\]+')(\[ \t\r\n\]*,\[ \t\r\n\](\"\[^\"\]+\"|'\[^'\]+'))*\\))?)|local\\((\"\[^\"\]+\"|'\[^'\]+')\\)),?\[ \t\r\n\]*" $src "" src]} {
	}
	if {$src != ""} {
		lappend errtext "$prop: $src"
	} else {
		append proptext ";\r$prop: $src0"
	}
}

# textalign
proc css::ReadDialogtextalign {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	global css::Choices
	if {[set txt [css::ReadChoiceList 1 val index]] != ""} {
		append proptext ";\r$prop:$txt"
	} elseif {[set txt [string trim [lindex $val $index]]] != ""} {
		set txt [css::QuoteValue $txt]
		append proptext ";\r$prop: $txt"
	}
	incr index
}

# textdecoration
proc css::ReadDialogtextdecoration {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	global css::Choices
	if {[set txt [css::ReadChoiceList 1 val index]] != ""} {
		append proptext ";\r$prop:$txt"
	} else {
		for {set i 0} {$i < 4} {incr i} {
			if {[lindex $val [expr {$index + $i}]]} {
				append txt " " [lindex [set css::Choices($prop)] $i]
			}
		}
		if {$txt != ""} {
			append proptext ";\r$prop:$txt"
		}
	}
	incr index 4
}

# textshadow
proc css::ReadDialogtextshadow {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext
	if {[set txt [css::ReadChoiceList 1 val index]] != ""} {
		append proptext ";\r$prop:$txt"
	} else {
		set txt [lindex $val [expr {$index + 10}]]
		if {$txt != ""} {append proptext ";\r$prop: $txt"}
	}
}

# borderspacing
proc css::ReadDialogborderspacing {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {[set txt [css::ReadChoiceList 0 val index inherit]] != "" && [incr index 4]} {
		append proptext ";\r$prop:$txt"
	} else {
		set err ""
		set txt [css::ReadNumber $prop val index length 0 0 0 err]
		append txt [css::ReadNumber $prop val index length 0 0 0 err]
		if {$txt != "" && $err == ""} {
			append proptext ";\r$prop:$txt"
		} elseif {$err != ""} {
			eval lappend errtext $err
		}
	} 
}

# cursor
proc css::ReadDialogcursor {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	incr index 5
	if {[set txt [css::ReadChoiceList 1 val index]] == " inherit" && [incr index]} {
		append proptext ";\r$prop:$txt"
	} else {
		incr index -6
		set url [css::ReadUrl val index]
		set eurl0 [set eurl [string trim [lindex $val $index]]]
		while {[regsub -nocase "^url\\(\[ \t\r\n\]*(\"\[^\"\]+\"|'\[^'\]+'|\[^\"' \t\r\n\]+)\[ \t\r\n\]*\\)\[ \t\r\n\]*(,\[ \t\r\n\]*|\[ \t\r\n\]*$)" $eurl0 "" eurl0]} {
		}
		if {$eurl0 != ""} {
			lappend errtext "$prop: $eurl0"
		}
		if {[set eurl [string trim [lindex $val $index]]] != ""} {
			append url ", $eurl"
		}
		if {$url != "" && $txt == ""} {
			lappend errtext "$prop: A generic cursor is required."
		} else {
			append proptext ";\r$prop:[string trimleft $url,$txt ,]"
		}
	}
}

# playduring
proc css::ReadDialogplayduring {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext
	if {[set txt [css::ReadChoiceList 1 val index]] != "" && [incr index 5]} {
		append proptext ";\r$prop:$txt"
	} elseif {[set txt [css::ReadUrl val index]] != ""} {
		if {[lindex $val $index]} {lappend txt mix}
		incr index
		if {[lindex $val $index]} {lappend txt repeat}
		incr index
		append proptext ";\r$prop:$txt"		
	} else {
		incr index 2
	}
}

# azimuth
proc css::ReadDialogazimuth {prop v ind imp ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	if {[set txt [css::ReadChoiceList 1 val index]] != "" && [incr index 4]} {
		append proptext ";\r$prop:$txt"
	} elseif {[set txt [css::ReadNumber $prop val index angle 0 0 0 errtext]] != "" && [incr index 2]} {
		append proptext ";\r$prop:$txt"
	} else {
		set txt [css::ReadChoiceList 1 val index]
		if {[lindex $val $index]} {append txt " behind"}
		if {$txt != ""} {
			append proptext ";\r$prop:$txt"
		}
		incr index
	}
}

proc css::ReadAllValuesBox {v} {
	upvar $v val
	global css::SetAllValues
	set css::SetAllValues [lindex $val [expr {[llength $val] - 4}]]
}

#===============================================================================
# ×××× Dialog reading help procs ×××× #
#===============================================================================

proc css::ReadChoiceList {choices v ind args} {
	upvar $v val $ind index
	
	global css::IsDescriptor
	if {${css::IsDescriptor} && !$choices} {return}
	set txt ""
	if {$choices} {
		if {[set c [lindex $val $index]] != " "} {
			set txt " $c"
		}
	} elseif {[lindex $val $index]} {
		append txt " $args"
	}
	incr index
	return $txt
}

proc css::ReadColor {prop v ind err} {
	upvar $v val $ind index $err errtext
	set txt ""
	if {[set ctxt [string trim [lindex $val $index]]] != ""} {
		if {[catch {css::CheckColorNumber $ctxt} col]} {
			lappend errtext "$prop: $ctxt is not a valid color."
		} else {
			set txt " $col"
		}
	} elseif {[set cval [lindex $val [expr {$index + 1}]]] != " "} {
		set txt " [css::CheckColorNumber $cval]"
	}
	incr index 3
	return $txt
}

proc css::ReadUrl {v ind} {
	upvar $v val $ind index
	set txt ""
	if {[set url [string trim [lindex $val $index]]] != "" || 
	[set url [lindex $val [expr {$index + 1}]]] != " "} {
		set txt " url(\"[quote::UrlExceptAnchor $url]\")"
		html::AddToCache URLs $url
	}
	incr index 3
	return $txt
}

proc css::ReadNumChoices {prop v ind type percent number integer ptext etext} {
	upvar $v val $ind index $ptext proptext $etext errtext
	global css::Choices
	if {([set txt [css::ReadChoiceList 1  val index [set css::Choices($prop)]]] != "" && [incr index 2]) || 
	[set txt [css::ReadNumber $prop val index $type $percent $number $integer errtext]] != ""} {
		append proptext ";\r$prop:$txt"
	}
}

proc css::ReadNumber {prop v ind type percent number integer etext} {
	upvar $v val $ind index $etext errtext
	set txt ""
	if {[set n [string trim [lindex $val $index]]] != ""} {
		regsub -all " " $n "" n
		if {[catch {css::CheckNumber $prop $type $n [lindex $val [expr {$index + 1}]] $percent $number $integer} res]} {
			lappend errtext "$prop: $res"
		} else {
			set txt " $res"
		}
	}
	incr index 2
	return $txt
}

proc css::ReadNumberNoUnit {prop v ind percent integer etext} {
	upvar $v val $ind index $etext errtext
	set txt ""
	if {[set n [string trim [lindex $val $index]]] != ""} {
		if {[catch {css::CheckNumber $prop "" $n " " $percent 1 $integer} res]} {
			lappend errtext "$prop: $res"
		} else {
			set txt " $res"
		}
	}
	incr index
	return $txt
}

proc css::ReadMediaList {v ind} {
	upvar $v val $ind index
	global HTMLmodeVars
	set txt " [string trim [join [list [css::ReadChoiceList 1 val index] " [lindex $val $index]"] ,] " ,"]"
	foreach t [split $txt ,] {
		set t [string tolower [string trim $t]]
		if {![lcontains HTMLmodeVars(mediatypes) $t]} {
			lappend HTMLmodeVars(mediatypes) $t
			prefs::modifiedModeVar mediatypes HTML
		}
	}
	incr index
	return [string trimright $txt]
}
