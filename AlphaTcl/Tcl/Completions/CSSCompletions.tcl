## -*-Tcl-*-
 # ###################################################################
 #  CSS mode - tools for editing CSS documents
 # 
 #  FILE: "CSSCompletions.tcl"
 #                                    created: 98-04-05 21.30.48 
 #                                last update: 03/21/2006 {01:45:32 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 2.2
 # 
 # Copyright 1997-2006 by Johan Linde
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

proc CSSCompletions.tcl {} {}

set completions(CSS) {completion::electric word}

set CSSelectrics(@media) " ¥media¥ \{\n\t¥ruleset¥\n\}\n¥¥"
set CSSelectrics(@font-face) " \{\n\t¥declarations¥\n\}\n¥¥"
set CSSelectrics(@page) " ¥page name¥ \{\n\t¥declarations¥\n\}\n¥¥"
set CSSelectrics(@import) " url(\"¥url¥\") ¥media¥;"

namespace eval CSS::Completion {}

# Word completion
proc CSS::Completion::word {args} {
	global css::Property css::Descriptor css::Shorthand css::IsDescriptor
	
	# Between {}?
	set thepos [getPos]
	if {$thepos == [maxPos]} {set thepos [pos::math [maxPos] - 1]}
	if {[catch {matchIt "\}" $thepos} bpos] || [css::IsInAtRule media]} {
		set allHtmlWords [css::GetHtmlWords]
		set pos [getPos]
		backwardWord
		set word [string toupper [getText [getPos] $pos]]
		if {[catch {html::FindLargestMatch allHtmlWords $word dum 1} match]} {goto $pos; return 1}
		if {![string length $match]} {
			selectText [getPos] $pos
		} else {
			replaceText [getPos] $pos [css::SetCase $match]
		}
		return 1
	}
	
	if {[set css::IsDescriptor [css::IsInAtRule font-face]]} {
		foreach p [array names css::Descriptor] {
			if {[set css::Descriptor($p)] != "group" || [set css::Shorthand($p)]} {
				lappend allCss $p
			}
		}
	} else {
		foreach p [array names css::Property] {
			if {[set css::Property($p)] != "group" || [set css::Shorthand($p)]} {
				lappend allCss $p
			}
		}
	}
	
	# Get current word
	if {[catch {search -s -f 0 -m 0 -r 1 {[\{;: \t\r\n]} [pos::math [getPos] - 1]} wpos]} {set wpos [minPos]}
	set wpos [lindex $wpos end]
	set word [getText $wpos [getPos]]
	# Before or after :?
	if {[catch {search -s -f 0 -m 0 -r 0 {;} [pos::math [getPos] - 1]} spos] || [pos::compare [lindex $spos 0] < $bpos]} {set spos [minPos]}
	set spos [lindex $spos 0]
	if {[catch {search -s -f 0 -m 0 -r 0 {:} [getPos]} cpos] || [pos::compare [lindex $cpos 0] < $bpos]} {set cpos [minPos]}
	set cpos [lindex $cpos 0]
	if {[pos::compare $spos < $cpos]} {
		# After colon
		if {[catch {search -s -f 0 -m 0 -r 1 {[;\{ \t\r\n]} $cpos} w2pos]} {set w2pos [minPos]}
		set pword [string tolower [getText [lindex $w2pos 1] $cpos]]
		if {![lcontains allCss $pword]} {
			selectText [lindex $w2pos 1] [getPos]
			return 1
		}
		if {${css::IsDescriptor}} {
			set newval [css::Complete[set css::Descriptor($pword)] $pword $word]
		} else {
			set newval [css::Complete[set css::Property($pword)] $pword $word]
		} 
		if {![string length $newval]} {
			selectText $wpos [getPos]
		} elseif {$newval != $word} {
			replaceText $wpos [getPos] $newval
		} else {
			status::msg "No completion."
		}
	} else {
		# Before colon
		set unique 0
		set match [html::FindLargestMatch allCss $word unique 1]
		if {![string length $match]} {
			selectText $wpos [getPos]
		} else {
			if {$unique} {
				append match ": "
			}
			replaceText $wpos [getPos] $match
		}
	}
	return 1
}

#===============================================================================
# ×××× Completion procs ×××× #
#===============================================================================

proc css::Completegroup {prop word} {
	global css::Group css::Property
	foreach p [set css::Group($prop)] {
		if {[string length [set m [eval css::Complete[set css::Property($p)] $p $word]]] && $m != $word} {
			return $m
		}
	}
	return $word
}

# choices
proc css::Completechoices {prop word} {
	global css::Choices
	return [css::CompleteChoiceList [set css::Choices($prop)] $word]
}

# color
proc css::Completecolor {prop word} {
	return [css::CompleteColor $word]
}

# url
proc css::Completeurl {prop word} {
	return [css::CompleteURL $word]
}

# family = like font-family and voice-family
proc css::Completefamily {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# integer
proc css::Completeinteger {prop word} {
	return $word
}

# number
proc css::Completenumber {prop word} {
	return $word
}

# nlpc = number, length, percentage, or choices
proc css::Completenlpc {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# lpc = length, percentage, or choices
proc css::Completelpc {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# npc = number, percentage, or choices
proc css::Completenpc {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# lc = length or choices
proc css::Completelc {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# ac = angle or choices
proc css::Completeac {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# fc = frequency or choices
proc css::Completefc {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# cc = color or choices
proc css::Completecc {prop word} {
	if {[set m [css::CompleteColor $word]] == $word} {
		set m [css::CompleteChoiceOrKeep $prop $word]
	}
	return $m
}

# uc = url or choices
proc css::Completeuc {prop word} {
	if {[set m [css::CompleteURL $word]] == $word} {
		set m [css::CompleteChoiceOrKeep $prop $word]
	}
	return $m
}

# lp = length or percentage
proc css::Completelp {prop word} {
	return $word
}

# tp = time or percentage
proc css::Completetp {prop word} {
	return $word
}

# ic = integer or choices
proc css::Completeic {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# nc = number or choices
proc css::Completenc {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# border
proc css::Completeborder {prop word} {
	return $word
	#to be written
}

# clip
proc css::Completeclip {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# quotes
proc css::Completequotes {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# counter
proc css::Completecounter {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# size
proc css::Completesize {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# content
proc css::Completecontent {prop word} {
	return [css::Completeuc $prop $word]
}

# marks
proc css::Completemarks {prop word} {
	return $word
	#to be written
}

# page
proc css::Completepage {prop word} {
	return $word
	#to be written
}

# backpos
proc css::Completebackpos {prop word} {
	return $word
	#to be written
}

# font
proc css::Completefont {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]	
}

# fontstyle
proc css::Completefontstyle {prop word} {
	return $word
	#to be written
}

# fontvariant
proc css::Completefontvariant {prop word} {
	return $word
	#to be written
}

# fontsize
proc css::Completefontsize {prop word} {
	return $word
	#to be written
}

# panose
proc css::Completepanose {prop word} {
	return $word
	#to be written
}

# widths
proc css::Completewidths {prop word} {
	return $word
	#to be written	
}

# bbox
proc css::Completebbox {prop word} {
	return $word
	#to be written	
}

# unirange
proc css::Completeunirange {prop word} {
	return $word
	#to be written	
}

# src
proc css::Completesrc {prop word} {
	return $word
	#to be written	
}

# textalign
proc css::Completetextalign {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# textdecoration
proc css::Completetextdecoration {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# textshadow
proc css::Completetextshadow {prop word} {
	return $word
	#to be written
}

# borderspacing
proc css::Completeborderspacing {prop word} {
	return $word
	#to be written
}

# cursor
proc css::Completecursor {prop word} {
	return [css::CompleteChoiceOrKeep $prop $word]
}

# playduring
proc css::Completeplayduring {prop word} {
	return $word
	#to be written
}

# azimuth
proc css::Completeazimuth {prop word} {
	return $word
	#to be written
}

#===============================================================================
# ×××× Completion help procs ×××× #
#===============================================================================

proc css::CompleteChoiceList {choices word} {
	global css::IsDescriptor
	if {${css::IsDescriptor} && ![llength $choices]} {return}
	if {!${css::IsDescriptor}} {lappend choices inherit}
	return [html::FindLargestMatch choices [string tolower $word] dum 1]
}

proc css::CompleteChoiceOrKeep {prop word} {
	global css::IsDescriptor css::Choices
	set choices [set css::Choices($prop)]
	if {${css::IsDescriptor} && ![llength $choices]} {return}
	if {!${css::IsDescriptor}} {lappend choices inherit}
	if {[string length [set m [html::FindLargestMatch choices [string tolower $word] dum 1]]]} {
		return $m
	} else {
		return $word
	}
}

proc css::CompleteURL {word} {
	global HTMLmodeVars html::UserURLs
	if {![string match "url(*" [string tolower $word]]} {return $word}
	set w [string trimleft [string range $word 4 end] \"]
	set unique 0
	set match [html::FindLargestMatch html::UserURLs [quote::Unurl $w] unique]
	if {$match == ""} {return $word}
	set match "url(\"[quote::UrlExceptAnchor $match]"
	if {$unique} {append match "\")"}
	return $match
}

proc css::CompleteColor {word} {
	global html::basicColors html::userColors css::Colors
	set colors [lsort [concat ${html::basicColors} [array names html::userColors] ${css::Colors}]]
	set unique 0
	set match [html::FindLargestMatch colors $word unique]
	if {$match == ""} {return $word}
	if {$unique} {
		if {[info exist html::userColors($match)]} {
			set match [set html::userColors($match)]
		}
	}
	return $match
}
