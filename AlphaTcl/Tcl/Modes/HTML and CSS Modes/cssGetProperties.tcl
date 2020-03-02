## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  CSS mode - tools for editing CSS documents
 # 
 #  FILE: "cssGetProperties.tcl"
 #                                    created: 00-01-02 00.26.20 
 #                                last update: 2005-02-21 17:51:11 
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
# This file contain procs for parsing the property value in a document
# and get a default value for the property dialog.
# For each type of property there is a proc
# css::GetProperties<type>
#===============================================================================

#===============================================================================
# ×××× Getting properties ×××× #
#===============================================================================

proc css::GetProperties {group v r0 r1 im et} {
	upvar $v val $r0 removePos0 $r1 removePos1 $im important $et errorText
	global css::Property css::Descriptor css::IsDescriptor css::GroupLikeProperties
	
	# Find interval to search in.
	if {[catch {matchIt "\}" [getPos]} start]} {
		if {![catch {search -s -f 0 -m 0 -r 0 "\}" [getPos]} r0] ||
		![catch {search -s -f 1 -i 1 -m 0 -r 0 "<STYLE([ \t\r\n]+[^<>]*>|>)" [getPos]} r0]} {
			set start [lindex $r0 1]
		} else {
			set start [minPos]
		}
	}
	if {[catch {matchIt "\{" [getPos]} end]} {
		set rbrace [maxPos]
		set style [maxPos]
		if {![catch {search -s -f 1 -m 0 -r 0 "\{" [getPos]} r0]} {
			set rbrace [lineStart [lindex $r0 0]]
		}
		if {![catch {search -s -f 1 -i 1 -m 0 -r 0 "</STYLE>" [getPos]} r0]} {
			set style [lindex $r0 0]
		}
		if {[pos::compare $rbrace < $style]} {
			set end $rbrace
		} else {
			set end $style
		}
	}
	if {${css::IsDescriptor}} {
		set gprop [set css::Descriptor($group)]
	} else {
		set gprop [set css::Property($group)]
	}
	# Find all properties
	if {[lcontains css::GroupLikeProperties $gprop]} {
		css::GetPropertiesgroup $start $end $group val removePos0 removePos1 important errorText
	} else {
		set propValue [css::FindProperty $start $end $group removePos0 removePos1 important]
		eval css::GetProperties$gprop $group propValue val
		if {[string length [string trim $propValue]]} {
			lappend errorText "$group: $propValue"
		}
	}
}

proc css::GetPropertiesgroup {start end group v r0 r1 im et} {
	upvar $v val $r0 removePos0 $r1 removePos1 $im important $et errorText
	
	global css::ExpandProps css::Shorthand css::UseShort css::Group css::IsDescriptor 
	global css::InheritAll css::Descriptor css::Property
    # If shorthand property, look for a shorthand definition.
	if {[set css::Shorthand($group)]} {
		set groupValue [css::FindProperty $start $end $group removePos0 removePos1 important]
		if {[string tolower $groupValue] == "inherit"} {
			set css::InheritAll 1
			set groupValue ""
		}
		eval [set css::ExpandProps($group)] $group [list $groupValue] propValue errorText
	}
	# Find all properties belonging to the group.
	foreach prop [set css::Group($group)] {
		# Trick for border
		set prop1 $prop
		if {$group == "border"} {regsub -- "-top-" $prop "-" prop1}
		if {![info exists propValue($prop1)]} {set propValue($prop1) ""}
		if {${css::IsDescriptor}} {
			set p [set css::Descriptor($prop)]
		} else {
			set p [set css::Property($prop)]
		}
		set pval [css::FindProperty $start $end $prop1 removePos0 removePos1 important]
		if {$pval != ""} {
			set propValue($prop1) $pval
			set css::UseShort 0
		}
		set pval $propValue($prop1)
		eval css::GetProperties$p $prop pval val
		if {[string length [string trim $pval]]} {
			lappend errorText "$prop1: $pval"
		}
	}
}

proc css::FindProperty {start end prop r0 r1 im} {
	upvar $r0 remove0 $r1 remove1 $im important
	global css::CommentRegexp
	set propValue ""
	set st0 $start
	while {1} {
		if {[catch {search -s -f 1 -i 1 -m 0 -r 1 -l $end "(\[ \t\r\n\]+|;|\{)$prop\[ \t\r\n\]*:" $st0} res]} {
			break
		} elseif {![catch {search -s -f 1 -i 1 -m 0 -r 0 -l $end "\;" [lindex $res 1]} res1]} {
			if {![css::IsInComment [lindex $res 0]]} {
				set propValue [string trim [getText [lindex $res 1] [pos::math [lindex $res1 1] - 1]]]
				set r00 [lindex $res 0]
				if {[lookAt $r00] == ";" || [lookAt $r00] == "\{"} {set r00 [pos::math $r00 + 1]}
				lappend remove0 $r00 
				lappend remove1 [lindex $res1 1]
				break
			} else {
				set st0 [lindex $res1 1]
			}
		} else {
			if {![css::IsInComment [lindex $res 0]]} {
				set propValue [string trim [getText [lindex $res 1] $end]]
				set r00 [lindex $res 0]
				if {[lookAt $r00] == ";" || [lookAt $r00] == "\{"} {set r00 [pos::math $r00 + 1]}
				lappend remove0 $r00 
				lappend remove1 $end
				break
			} else {
				set st0 [lindex $res1 1]
			}
		}
	}
	regsub -all ${css::CommentRegexp} $propValue "" propValue
	if {[regsub -nocase "!\[ \t\r\n\]*important" $propValue {} propValue]} {set important($prop) 1}
	return [string trim $propValue]
}

# choices
proc css::GetPropertieschoices {prop pval v} {
	upvar $pval pvalue $v val
	global css::Choices
	css::GetChoicesProp [set css::Choices($prop)] pvalue val
}

# color
proc css::GetPropertiescolor {prop pval v} {
	upvar $pval pvalue $v val
	css::GetChoicesProp "" pvalue val
	css::GetColorProp pvalue val
}

# url
proc css::GetPropertiesurl {prop pval v} {
	upvar $pval pvalue $v val
	css::GetChoicesProp "" pvalue val
	css::GetUrlProp pvalue val
}

# family = like font-family and voice-family
proc css::GetPropertiesfamily {prop pval v} {
	upvar $pval pvalue $v val
	if {[string tolower $pvalue] == "inherit"} {
		lappend val inherit "" 0
	} else {
		lappend val " " $pvalue 0
	}
	set pvalue ""	
}

# integer
proc css::GetPropertiesinteger {prop pval v} {
	upvar $pval pvalue $v val
	css::GetChoicesProp "" pvalue val
	css::GetNumberNoUnit $prop pvalue val 0 1
}

# number
proc css::GetPropertiesnumber {prop pval v} {
	upvar $pval pvalue $v val
	css::GetChoicesProp "" pvalue val
	css::GetNumberNoUnit $prop pvalue val 0 0
}

# nlpc = number, length, percentage, or choices
proc css::GetPropertiesnlpc {prop pval v} {
	upvar $pval pvalue $v val
	css::GetNumChoices $prop pvalue val length 1 1 0
}

# lpc = length, percentage, or choices
proc css::GetPropertieslpc {prop pval v} {
	upvar $pval pvalue $v val
	css::GetNumChoices $prop pvalue val length 1 0 0
}

# npc = number, percentage, or choices
proc css::GetPropertiesnpc {prop pval v} {
	upvar $pval pvalue $v val
	css::GetNumChoices $prop pvalue val number 1 1 1
}

# lc = length or choices
proc css::GetPropertieslc {prop pval v} {
	upvar $pval pvalue $v val
	css::GetNumChoices $prop pvalue val length 0 0 0
}

# ac = angle or choices
proc css::GetPropertiesac {prop pval v} {
	upvar $pval pvalue $v val
	css::GetNumChoices $prop pvalue val angle 0 0 0
}

# fc = frequency or choices
proc css::GetPropertiesfc {prop pval v} {
	upvar $pval pvalue $v val
	css::GetNumChoices $prop pvalue val frequency 0 0 0
}

# cc = color or choices
proc css::GetPropertiescc {prop pval v} {
	upvar $pval pvalue $v val
	css::GetPropertieschoices $prop pvalue val
	css::GetColorProp pvalue val
}

# uc = url or choices
proc css::GetPropertiesuc {prop pval v} {
	upvar $pval pvalue $v val
	css::GetPropertieschoices $prop pvalue val
	css::GetUrlProp pvalue val
}

# lp = length or percentage
proc css::GetPropertieslp {prop pval v} {
	upvar $pval pvalue $v val
	css::GetChoicesProp "" pvalue val
	css::GetNumber $prop pvalue val length 1 0 0
}

# tp = time or percentage
proc css::GetPropertiestp {prop pval v} {
	upvar $pval pvalue $v val
	css::GetChoicesProp "" pvalue val
	css::GetNumber $prop pvalue val time 1 0 0
}

# ic = integer or choices
proc css::GetPropertiesic {prop pval v} {
	upvar $pval pvalue $v val
	css::GetPropertieschoices $prop pvalue val
	css::GetNumberNoUnit $prop pvalue val 0 1
}

# nc = number or choices
proc css::GetPropertiesnc {prop pval v} {
	upvar $pval pvalue $v val
	css::GetPropertieschoices $prop pvalue val
	css::GetNumberNoUnit $prop pvalue val 0 0
}

# border
# No proc needed!

# clip
proc css::GetPropertiesclip {prop pval v} {
	upvar $pval pvalue $v val
	global css::Choices
	css::GetChoicesProp [set css::Choices($prop)] pvalue val
	if {![regexp {^rect\(([^,]+),([^,]+),([^,]+),([^,]+)\)$} [string tolower $pvalue] "" top right bottom left]} {
		lappend val 0 "" "" 0 "" "" 0 "" "" 0 "" ""
		return
	}
	foreach side {top right bottom left} {
		set $side [string trim [set $side]]
		if {[set $side] == "auto"} {
			set $side ""
			lappend val 1
		} else {
			lappend val 0
		}
		css::GetNumber clip $side val length 0 0 0
		lappend pv [set $side]
	}
	set pvalue [join $pv]
}

# quotes
proc css::GetPropertiesquotes {prop pval v} {
	upvar $pval pvalue $v val
	css::GetPropertieschoices $prop pvalue val
	lappend val "" "" 0 $pvalue
	if {$pvalue != "" && [regexp {^(('[^']+'|\"[^\"]+\")[ \t\r\n]+('[^']+'|\"[^\"]+\")[ \t\r\n]+)+$} "$pvalue "]} {
		set pvalue ""
	}
}

# counter
proc css::GetPropertiescounter {prop pval v} {
	upvar $pval pvalue $v val
	css::GetPropertieschoices $prop pvalue val
	lappend val $pvalue
	if {$pvalue != "" && [regexp {^([^-0-9][^ \t\r\n]*([ \t\r\n]+[-\+]?[0-9]+)?[ \t\r\n]+)+$} "$pvalue "]} {
		set pvalue ""
	}
}

# size
proc css::GetPropertiessize {prop pval v} {
	upvar $pval pvalue $v val
	css::GetPropertieschoices $prop pvalue val
	for {set i 0} {$i < 2} {incr i} {
		set pv [lindex $pvalue $i]
		css::GetNumber $prop pv val length 0 0 0
		lappend newpv $pv
	}
	set pvalue [join [concat $newpv [lrange $pvalue 2 end]]]
}

# content
proc css::GetPropertiescontent {prop pval v} {
	upvar $pval pvalue $v val
	if {[string tolower $pvalue] == "inherit"} {
		lappend val [string tolower $pvalue]
	} else {
		lappend val " " $pvalue
	}
	set pvalue ""
}

# marks
proc css::GetPropertiesmarks {prop pval v} {
	upvar $pval pvalue $v val
	css::GetChoicesProp none pvalue val
	lappend val [regsub -nocase "(^|\[ \t\r\n\])crop($|\[ \t\r\n\])" $pvalue "" pvalue]
	lappend val [regsub -nocase "(^|\[ \t\r\n\])cross($|\[ \t\r\n\])" $pvalue "" pvalue]
}

# page
proc css::GetPropertiespage {prop pval v} {
	upvar $pval pvalue $v val
	if {[string tolower [lindex $pvalue 0]] == "auto"} {
		lappend val 1
		set pvalue [lrange $pvalue 1 end]
	} else {
		lappend val 0
		lappend val $pvalue
		if {[regexp {^[^-0-9][^ \t\r\n]*$} $pvalue]} {
			set pvalue ""
		}
	}
}

# backpos
proc css::GetPropertiesbackpos {prop pval v} {
	upvar $pval pvalue $v val
	css::GetChoicesProp "" pvalue val
	foreach bp [list {top center bottom} {left center right}] {
		set found 0
		set nv ""
		foreach v $pvalue {
			if {!$found && [lcontains bp [string tolower $v]]} {
				lappend val [string tolower $v]
				set found 1
			} else {
				lappend nv $v
			}
		}
		if {!$found} {lappend val " "}
		set pvalue $nv
	}
	for {set i 0} {$i < 2} {incr i} {
		set pv [lindex $pvalue $i]
		css::GetNumber $prop pv val length 1 0 0
		lappend newpv $pv
	}
	set pvalue [join [concat $newpv [lrange $pvalue 2 end]]]
}

# fontstyle
proc css::GetPropertiesfontstyle {prop pval v} {
	upvar $pval pvalue $v val
	global css::Choices
	set pvalue [string tolower $pvalue]
	if {$pvalue == "all"} {
		lappend val " " "" 0 1
		set pvalue ""
	} else {
		# Special case with font-stretch descriptor
		set ch [set css::Choices($prop)]
		if {$prop == "font-stretch"} {set ch [lrange $ch 2 end]}
		set pvs ""; set err ""
		foreach p [split $pvalue ,] {
			set p [string trim $p]
			if {[lcontains ch $p]} {
				lappend pvs $p
			} else {
				lappend err $p
			}
		}
		lappend val " " [join $pvs ", "] 0 0
		set pvalue [join $err]
	}
}

# fontvariant
proc css::GetPropertiesfontvariant {prop pval v} {
	upvar $pval pvalue $v val
	global css::Choices
	set pvalue [string tolower $pvalue]
	set pvs ""; set err ""
	foreach p [split $pvalue ,] {
		set p [string trim $p]
		if {[lcontains  css::Choices($prop) $p]} {
			lappend pvs $p
		} else {
			lappend err $p
		}
	}
	lappend val " " [join $pvs ", "] 0
	set pvalue [join $err]
}

# fontsize
proc css::GetPropertiesfontsize {prop pval v} {
	upvar $pval pvalue $v val
	lappend val 0
	set pvalue [string tolower $pvalue]
	if {$pvalue == "all"} {
		lappend val "" " " "" 1
		set pvalue ""
	} else {
		set pvs ""; set err ""
		foreach p [split $pvalue ,] {
			set p [string trim $p]
			if {![catch {css::CheckNumber $prop length $p "" 0 0 0}]} {
				lappend pvs $p
			} else {
				lappend err $p
			}
		}
		lappend val "" " "
		lappend val [join $pvs ", "] 0
		set pvalue [join $err]
	}
}

# panose
proc css::GetPropertiespanose {prop pval v} {
	upvar $pval pvalue $v val
	if {$pvalue != "" && [llength $pvalue] != 10} {return}
	set nv ""
	foreach v $pvalue {
		css::GetNumberNoUnit $prop v val 0 1
		if {$v != ""} {lappend nv $v}
	}
	set pvalue $nv
}

# widths
proc css::GetPropertieswidths {prop pval v} {
	upvar $pval pvalue $v val
	set vlist [split $pvalue ,]
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
	lappend val [string trimleft $vv ", "]
	set pvalue [join $err]
}

# bbox
proc css::GetPropertiesbbox {prop pval v} {
	upvar $pval pvalue $v val
	set n 0
	set nv ""
	foreach num [split $pvalue ,] {
		set num [string trim $num]
		if {$n < 4} {css::GetNumberNoUnit $prop num val 0 1}
		if {$num != ""} {lappend nv $num}
		incr n
	}
	for {set i $n} {$i < 4} {incr i} {
		lappend val ""
	}
	set pvalue $nv
}

# unirange
proc css::GetPropertiesunirange {prop pval v} {
	upvar $pval pvalue $v val
	set vlist [split $pvalue ,]
	set err ""; set vv ""
	foreach u $vlist {
		if {![css::CheckUrange [string trim $u]]} {
			lappend err $u
		} else {
			append vv ", [string trim $u]"
		}
	}
	lappend val [string trimleft $vv ", "]
	set pvalue [join $err]
}

# src
proc css::GetPropertiessrc {prop pval v} {
	upvar $pval pvalue $v val
	lappend val "" " " 0 "" "" 0
	set src [set src0 [string trim $pvalue]]
	if {$src == ""} {return}
	while {[regsub -nocase "^((url\\(\[ \t\r\n\]*(\"\[^\"\]+\"|'\[^'\]+'|\[^\"' \t\r\n\]+)\[ \t\r\n\]*\\)\[ \t\r\n\]*(format\\((\"\[^\"\]+\"|'\[^'\]+')(\[ \t\r\n\]*,\[ \t\r\n\](\"\[^\"\]+\"|'\[^'\]+'))*\\))?)|local\\((\"\[^\"\]+\"|'\[^'\]+')\\)),?\[ \t\r\n\]*" $src "" src]} {
	}
	set pvalue $src
	lappend val $src0
}

# textalign
proc css::GetPropertiestextalign {prop pval v} {
	upvar $pval pvalue $v val
	if {[regexp {^("[^"]+"|'[^']+')$} $pvalue]} {
		lappend val " " $pvalue
		set pvalue ""
	} else {
		css::GetPropertieschoices $prop pvalue val
		lappend val ""
	}
}

# textdecoration
proc css::GetPropertiestextdecoration {prop pval v} {
	upvar $pval pvalue $v val
	global css::Choices
	css::GetChoicesProp none pvalue val
	set pvalue [string tolower $pvalue]
	foreach c [set css::Choices($prop)] {
		if {[set i [lsearch -exact $pvalue $c]] >= 0} {
			lappend val 1
			set pvalue [lreplace $pvalue $i $i]
		} else {
			lappend val 0
		} 
	}
}

# textshadow
proc css::GetPropertiestextshadow {prop pval v} {
	upvar $pval pvalue $v val
	if {[set pp [string tolower $pvalue]] == "inherit" || $pp == "none"} {
		lappend val $pp
		set pvalue ""
		return
	}
	set pv ""
	set err ""
	foreach p [split $pvalue ,] {
		set c ""
		if {![catch {css::CheckColorNumber [lindex $p 0]} c0]} {
			set p [lrange $p 1 end]
			set c $c0
		} elseif {![catch {css::CheckColorNumber [lindex $p end]} c0]} {
			set p [lrange $p 0 [expr {[llength $p] - 2}]]
			set c $c0
		}
		set p0 ""
		set e ""
		set i -1
		foreach p1 $p {
			if {![catch {css::CheckNumber [lindex {horizontal vertical blur} [incr i]] length $p1 "" 0 0 0} n]} {
				lappend p0 $n
			} else {
				lappend e $p1
			}
		}
		set p $p0
		if {$c != ""} {lappend p $c}
		if {$p != ""} {append pv ", $p"}
		if {$e != ""} {lappend err $e}
	}
	lappend val " " "" "" "" "" "" "" "" " " 0 0 [string trim $pv ", "]
	set pvalue [join $err]
}

# borderspacing
proc css::GetPropertiesborderspacing {prop pval v} {
	upvar $pval pvalue $v val
	css::GetChoicesProp "" pvalue val
	for {set i 0} {$i < 2} {incr i} {
		set pv [lindex $pvalue $i]
		css::GetNumber $prop pv val length 0 0 0
		lappend newpv $pv
	}
	set pvalue [join [concat $newpv [lrange $pvalue 2 end]]]
}

# cursor
proc css::GetPropertiescursor {prop pval v} {
	upvar $pval pvalue $v val
	global css::Choices
	set vlist [split $pvalue ,]
	set pvalue ""
	set eurl ""
	lappend val "" " " 0
	for {set i 0} {$i < [expr {[llength $vlist] - 1}]} {incr i} {
		set tmp ""
		set u [lindex $vlist $i]
		css::GetUrlProp u tmp
		if {[lindex $tmp 1] != " "} {append eurl ", url(\"[lindex $tmp 1]\")"}
		append pvalue $u
	}
	lappend val [string trimleft $eurl ", "] 0
	set c [string trim [lindex $vlist end]]
	css::GetChoicesProp [set css::Choices($prop)] c val
	append pvalue $c
}

# playduring
proc css::GetPropertiesplayduring {prop pval v} {
	upvar $pval pvalue $v val
	css::GetPropertiesuc $prop pvalue val
	set pvalue [string tolower $pvalue]
	lappend val [regsub -nocase "(^|\[ \t\r\n\])mix($|\[ \t\r\n\])" $pvalue "" pvalue]
	lappend val [regsub -nocase "(^|\[ \t\r\n\])repeat($|\[ \t\r\n\])" $pvalue "" pvalue]
}

# azimuth
proc css::GetPropertiesazimuth {prop pval v} {
	upvar $pval pvalue $v val
	css::GetNumChoices $prop pvalue val angle 0 0 0
	set pvalue [string tolower $pvalue]
	set found 0
	foreach c {left-side far-left left center-left center center-right right far-right right-side} {
		if {[set i [lsearch -exact $pvalue $c]] >= 0} {
			lappend val $c
			set pvalue [lreplace $pvalue $i $i]
			set found 1
			break
		}
	}
	if {!$found} {lappend val " "}
	if {$pvalue == "behind"} {
		lappend val 1
		set pvalue ""
	} else {
		lappend val 0
	}
}

#===============================================================================
# ×××× Getting properties help procs ×××× #
#===============================================================================

proc css::GetChoicesProp {items pval v} {
	upvar $pval pvalue $v val
	global css::IsDescriptor
	if {${css::IsDescriptor} && ![llength $items]} {return}
	if {!${css::IsDescriptor}} {lappend items inherit}
	if {[set i [lsearch -exact $items [string tolower $pvalue]]] >= 0} {
		if {[llength $items] == 1} {
			lappend val 1
		} else {
			lappend val [lindex $items $i]
		}
		set pvalue ""
	} elseif {[llength $items] == 1} {
		lappend val 0
	} else {
		lappend val " "
	}
}

proc css::GetColorProp {pval v} {
	upvar $pval pvalue $v val
	global html::userColorname html::ColorNumber html::ColorName css::Colors
	
	if {[catch {css::CheckColorNumber $pvalue} tv]} {
		lappend val "" " " 0
	} else {
		if {[set c1 [info exists html::userColorname($tv)]]} {set tv [set html::userColorname($tv)]}
		if {[info exists html::ColorNumber($tv)]} {set tv [set html::ColorNumber($tv)]}
 		if {$c1 || [info exists html::ColorName($tv)] || [lcontains css::Colors $tv]} {
			lappend val "" $tv 0
		} else {
			lappend val $tv " " 0
		}
		set pvalue ""
	}
}

proc css::GetUrlProp {pval v} {
	upvar $pval pvalue $v val
	global html::UserURLs
	if {[regexp -nocase -indices {url\([ \t\r\n]*("[^"]+"|'[^']+'|[^ "'\t\n\r\)]+)[ \t\r\n]*\)} $pvalue url tv]} {
		set tv [quote::Unurl [string trim [string range $pvalue [lindex $tv 0] [lindex $tv 1]] {"'}]]
		html::AddToCache URLs $tv
		if {[lcontains html::UserURLs $tv]} {
			lappend val "" $tv 0
		} else {
			lappend val $tv " " 0
		}
		set pvalue "[string range $pvalue 0 [expr {[lindex $url 0] - 1}]][string range $pvalue [expr {[lindex $url 1] + 1}] end]"
	} else {
		lappend val "" " " 0
	}
}

proc css::GetNumberNoUnit {prop pval v percent integer} {
	upvar $pval pvalue $v val
	if {![catch {css::CheckNumber $prop "" $pvalue " " $percent 1 $integer} res]} {
		lappend val $res
		set pvalue ""
	} else {
		lappend val ""
	}
}

proc css::GetNumChoices {prop pval v type percent number integer} {
	upvar $pval pvalue $v val
	global css::Choices
	css::GetChoicesProp [set css::Choices($prop)] pvalue val
	css::GetNumber $prop pvalue val $type $percent $number $integer
}

proc css::GetNumber {prop pval v type percent number integer} {
	upvar $pval pvalue $v val
	set unit ""
	if {$number} {set unit " "}
	if {![catch {css::CheckNumber $prop $type $pvalue $unit $percent $number $integer} res]} {
		regexp {^([-\+]?[0-9]+\.?[0-9]*)([%a-zA-Z]*)$} $res "" n u
		lappend val $n $u
		set pvalue ""
	} else {
		lappend val "" ""
	}
}

