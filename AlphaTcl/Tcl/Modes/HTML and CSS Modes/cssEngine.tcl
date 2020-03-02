## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  CSS mode - tools for editing CSS documents
 # 
 #  FILE: "cssEngine.tcl"
 #                                    created: 97-03-08 19.32.58 
 #                                last update: 2005-02-21 17:51:06 
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
# This file contains the main procs for handling the CSS property dialogs.
#===============================================================================

proc css::FindWhereToInsert {group pos} {
	if {[string index $group 0] == "@"} {css::FindWhereToInsertAtRule $group $pos; return}
	if {[pos::compare $pos > [minPos]]} {set pos [pos::math $pos - 1]}
	if {[catch {search -s -f 0 -m 0 -r 1 "\{" $pos} lbrace]} {set lbrace [minPos]; set noleft 1}
	set lbrace [pos::math [lindex $lbrace 0] + 1]
	if {[catch {search -s -f 0 -m 0 -r 1 "\}" $pos} rbrace]} {set rbrace [minPos]}
	set rbrace [pos::math [lindex $rbrace 0] + 1]
	if {[info exists noleft] || [pos::compare $rbrace > $lbrace]} {
		alertnote "Incorrect position to insert properties."
		error "cancel"
	}
	if {[catch {search -s -f 0 -m 0 -r 1 "\;" $pos} semi] || [pos::compare [lindex $semi 0] < $lbrace]} {set semi [minPos]}
	set semi [pos::math [lindex $semi 0] + 1]
	set go $pos
	if {[pos::compare $lbrace > [minPos]] || [pos::compare $semi > [minPos]]} {
		if {[pos::compare $lbrace > $semi]} {
			set go $lbrace
		} else {
			set go $semi
		}
	}
	if {[css::IsInComment $go]} {
		set go [lindex [search -s -f 0 -m 0 -r 0 "/*" $go] 0]
		css::FindWhereToInsert $group $go
	} else {
		goto $go
	}
}

proc css::FindWhereToInsertAtRule {atrule pos} {
	switch $atrule {
		@charset {goto [minPos]}
		@import {
			if {![catch {search -s -f 1 -m 0 -r 1 {@charset[^;]+;} [minPos]} res]} {
				goto [lindex $res 1]
			} else {
				goto [minPos]
			}
		}
		default {
			if {![catch {matchIt "\}" $pos} res]} {
				if {[catch {search -s -f 0 -m 0 -r 1 "\}" [pos::math [lindex $res 0] - 1]} rbrace]} {
					goto [minPos]
				} else {
					goto [lindex $rbrace 1]
				}
			}
		}
	}
}

proc css::IsInComment {pos} {
	global css::CommentRegexp
	if {[catch {search -s -f 0 -m 0 -r 1 ${css::CommentRegexp} $pos} res]} {return 0}
	return [pos::compare [lindex $res 1] > $pos]
}

proc css::IsInAtRule {atrule} {
	global css::CommentRegexp
	if {[catch {matchIt "\}" [getPos]} p]} {return 0}
	if {[catch {search -s -f 0 -m 0 -r 1 "\}" $p} rbrace]} {set rbrace [minPos]}
	set rbrace [lindex $rbrace end]
	set txt [getText $rbrace $p]
	regsub -all [set css::CommentRegexp] $txt "" txt
	return [regexp -nocase "@$atrule\[ \t\r\n\]*$" $txt]
}

proc css::FontFace {} {
	if {![win::checkIfWinToEdit]} {return}
	css::FindWhereToInsert @font-face [getPos]
	insertText "[html::OpenCR]@font-face \{\r[text::standardIndent]\r\}\r"
	goto [pos::math [getPos] - 3]
}

# CSS properties dialog
proc css::Dialog {group} {
	global mode css::Property css::UseShort css::InheritAll css::SetAllValues css::Shorthand css::IsDescriptor
	global css::ExtraDialog css::ReadExtraDialog css::AddMissingValues indentationAmount css::Descriptor css::GroupLikeProperties
	
	if {$mode == "HTML" && ![html::IsInContainer STYLE]} {
		beep
		status::msg "Current position is not inside STYLE tags."
		return
	}

	# Find where to insert text.
	set currPos [getPos]
	css::FindWhereToInsert $group $currPos
	
	# Get current properties
	set val {0 0}
	set css::UseShort 1
	set css::InheritAll 0
	set css::SetAllValues 0
	set removePos0 {}
	set removePos1 {}
	if {[string index $group 0] != "@"} {css::GetProperties $group val removePos0 removePos1 important errorText}
	if {[info exists errorText] && ![html::ErrorWindow "$group not well-defined" $errorText 1]} {return}
	
	# The dialog
	set ttype "properties"
	if {${css::IsDescriptor}} {set ttype "descriptors"}
	set invalidInput 1
	while {$invalidInput} {
		while {1} {
			set htxt "[string toupper [string index $group 0]][string range $group 1 end]"
			if {[string index $group 0] != "@" && ![regexp $ttype $group]} {append htxt " $ttype"}
			set box ""
			set hpos 10
			set wpos 10
			set index 2
			set buttons ""
			if {${css::IsDescriptor}} {
				set gprop [set css::Descriptor($group)]
			} else {
				set gprop [set css::Property($group)]
			}
			# Build the dialog
			eval css::BuildDialog$gprop $group val box hpos wpos buttons buttonAction index
			set val [eval dialog -T [list $htxt] -w 470 -h [expr {$hpos + 50}] \
			  -b OK 390 [expr {$hpos + 20}]  455 [expr {$hpos + 40}] \
			  -b Cancel 305 [expr {$hpos + 20}] 370 [expr {$hpos + 40}] $box]
			# Read checkboxes for shorthand groups.
			if {[lcontains css::GroupLikeProperties $gprop] && [set css::Shorthand($group)]} {
				set css::UseShort [lindex $val [expr {[llength $val] - 1}]]
				set css::InheritAll [lindex $val [expr {[llength $val] - 2}]]
				# Extra dialog for shorthand groups
				if {[info exist css::ExtraDialog($group)]} {
					eval [set css::ReadExtraDialog($group)] val
				}
			}
			# OK clicked?
			if {[lindex $val 0]} {break}
			# Cancel clicked?
			if {[lindex $val 1]} {goto $currPos; return}
			# Another button clicked
			foreach b $buttons {
				if {[lindex $val $b]} {eval $buttonAction($b) val $b}
			}
		}
		set index 2
		set proptext ""
		set errtext ""
		# Read dialog
		eval css::ReadDialog$gprop $group val index important proptext errtext
		# Add important for single properties.
		if {![lcontains css::GroupLikeProperties $gprop] && [info exists important($group)]} {
			append proptext " ! important"
		}
		if {![llength $errtext]} {
			set invalidInput 0
			# Add missing values automatically
			if {!${css::SetAllValues} && [info exists css::AddMissingValues($group)]} {eval [set css::AddMissingValues($group)] $group proptext important}
			# Make shorthand form
			if {${css::UseShort} && [info exists css::Shorthand($group)] && [set css::Shorthand($group)]} {css::MakeShort $group proptext important}
			# Inherit all
			if {${css::InheritAll}} {
				set proptext ";\r$group: inherit"
				if {[info exists important($group)]} {append proptext " ! important"}
			}
		} else {
			html::ErrorWindow "Invalid input" $errtext
		}
	}		
	set proptext [string trimleft $proptext "\;"]
	
	if {[string index $group 0] != "@"} {
		# Find indentation.
		set indent ""
		if {![catch {matchIt "\}" [getPos]} pos]} {
			set indent [text::indentString $pos]
		}
		set indent [text::indentBy "" [expr {[string length [text::maxSpaceForm $indent]] + [text::getIndentationAmount]}]]
		regsub -all "\r" $proptext "\r$indent" proptext
	} else {
		set proptext [html::OpenCR][string trimleft $proptext]
	}
	set len 0
	set ps [getPos]
	set removePos0 [lsort -command css::posCompare -decreasing $removePos0]
	set removePos1 [lsort -command css::posCompare -decreasing $removePos1]
	# Check for overlapping positions.
	set r0 [maxPos]
	for {set i 0} {$i < [llength $removePos1]} {incr i} {
		set r00 [lindex $removePos0 $i]
		set r11 [lindex $removePos1 $i]
		if {[pos::compare $r11 > $r0]} {set r11 $r0}
		if {[pos::compare $r11 > $r00]} {lappend rem [list $r00 $r11]}
		set r0 $r00
	}
	if {[info exists rem]} {
		set hasinserted 0
		foreach r $rem {
			set xpos 0
			if {!$hasinserted && [pos::compare [lindex $r 0] < $ps]} {
				css::insertPropText $group $proptext
				set hasinserted 1
			}
			deleteText [lindex $r 0] [lindex $r 1]
		}
		if {!$hasinserted} {css::insertPropText $group $proptext}
	} else {
		css::insertPropText $group $proptext
	}		
}

proc css::insertPropText {group proptext} {
	if {![is::Whitespace $proptext]} {
		if {$group != "@media" && $group != "@page"} {
			append proptext ";"
		} else {
			append proptext " \{\r[text::standardIndent]\r\}\r"
		} 
		insertText "$proptext"
		set len [string length $proptext]
		if {$group == "@media" || $group == "@page"} {
			goto [pos::math [getPos] - 3]
		}
	}
}

proc css::posCompare {p1 p2} {
	if {[pos::compare $p1 < $p2]} {
		return -1
	} else {
		return [pos::compare $p1 != $p2]
	}
}

proc css::QuoteValue {v} {
	if {![regexp {^("[^"]+"|'[^']+')$} $v]} {
		if {[regexp {"} $v]} {set v "'$v'"} else {set v "\"$v\""}
	}
	return $v
}

# Add missing values to top, right, bottom, left properties.
proc css::AddMissingVals {group ptext imp} {
	upvar $ptext proptext $imp important
	global css::Group
	set text $proptext
	set tmp [split $text "\r"]
	set sideList {top right bottom left}
	# Find those values which have been set
	foreach side $sideList {
		set $side 0
		foreach l $tmp {
			if {[string match *${side}* [lindex $l 0]]} {
				set $side 1
				set ${side}val [string trimright [lindex $l 1] "\;"]
			}
		}
	}
	# Add missing values.
	foreach side $sideList {
		if {![set $side]} {
			switch $side {
				top {set opside bottom}
				right {set opside left}
				bottom {set opside top}
				left {set opside right}
			}
			if {[set $opside]} {
				set use $opside
			} elseif {$top} {
				set use top
			} else {
				# Can't add missing value.
				return
			}	
			set pr [lindex [set css::Group($group)] [lsearch $sideList $side]]
			append text "\;\r$pr: [set ${use}val]"
			if {[info exists important($group)] || [info exists important($pr)]} {append text " ! important"}
		}
	}
	set proptext $text
}

#===============================================================================
# ×××× Making short form properties ×××× #
#===============================================================================

proc css::MakeShort {group p im} {
	upvar $p proptext $im important
	global css::Group css::MakeShort
	# don't make short if only some properties are important
	if {[info exists important] && [llength [set css::Group($group)]] > 
	[expr {[llength [array names important]] - [info exists important($group)]}]} {return}
	
	set lines [split $proptext \r]
	foreach l [lrange $lines 1 end] {
		regsub { ! important} $l "" l
		regexp {^([^:]+):[ ]*([^;]+)} $l "" pr v
		set propvalue($pr) $v
	}
	# don't make short if some are inherited
	foreach pr [array names propvalue] {
		if {$propvalue($pr) == "inherit"} {return}
	}
	if {[info exists propvalue]} {
		eval [set css::MakeShort($group)] $group proptext propvalue important
	}
}

proc css::MakeShort4lengths {group pt pv im} {
	upvar $pt proptext $pv propvalue $im important
	if {[llength [array names propvalue]] != 4} {return}
	
	foreach side {top right bottom left} {
		foreach p [array names propvalue] {
			if {[string match "*$side*" $p]} {lappend values $propvalue($p)}
		}
	}
	
	if {[llength [lunique $values]] == 1} {
		set values [lindex $values 0]
	} elseif {[lindex $values 0] == [lindex $values 2] && [lindex $values 1] == [lindex $values 3]} {
		set values [lrange $values 0 1]
	} elseif {[lindex $values 1] == [lindex $values 3]} {
		set values [lrange $values 0 2]
	}
	set proptext ";\r$group: $values"
	if {[info exists important]} {append proptext " ! important"}
}

proc css::MakeShortPile {group pt pv im} {
	upvar $pt proptext $pv propvalue $im important
	set ptext ";\r$group:"
	set inherit 0
	foreach p [array names propvalue] {
		append ptext " " $propvalue($p)
		if {$propvalue($p) == "inherit"} {incr inherit}
	}
	if {$inherit} {
		if {$inherit == [llength [array names propvalue]]} {
			set ptext ";\r$group: inherit"
		} else {
			return
		}
	}
	if {[info exists important]} {append ptext " ! important"}
	set proptext $ptext
}

proc css::MakeShortPileIfBoth {group pt pv im} {
	upvar $pt proptext $pv propvalue $im important
	if {[llength [set n [lsort [array names propvalue]]]] == 2} {
		set v [array get propvalue]
		if {[lindex $v 1] != [lindex $v 3]} {
			set propvalue([lindex $n 0]) [concat $propvalue([lindex $n 1]) $propvalue([lindex $n 0])]
		}
		unset propvalue([lindex $n 1])
		css::MakeShortPile $group proptext propvalue important
	}
}

proc css::MakeShortFont {group pt pv im} {
	upvar $pt proptext $pv propvalue $im important
	if {![info exists propvalue(font-size)] || ![info exists propvalue(font-family)]} {return}
	set ptext ";\r$group:"
	set inherit 0
	foreach p [array names propvalue] {
		if {$propvalue($p) == "inherit"} {incr inherit}
		if {$p == "font-family"} {continue}
		if {$p == "line-height"} {
			append ptext " " $propvalue(font-size) "/" $propvalue($p)
			continue
		}
		if {$p != "font-size" || ![info exists propvalue(line-height)]} {
			append ptext " " $propvalue($p)
		}
	}
	append ptext " " $propvalue(font-family)
	if {$inherit} {
		if {$inherit == [llength [array names propvalue]]} {
			set ptext ";\r$group: inherit"
		} else {
			return
		}
	}
	if {[info exists important]} {append ptext " ! important"}
	set proptext $ptext
}

#===============================================================================
# ×××× Expanding short form properties ×××× #
#===============================================================================

proc css::ExpandPile {group value pv err {ignore ""}} {
	upvar $pv prop $err errorText
	global css::Group css::Property
	foreach p [set css::Group($group)] {
		if {[lcontains ignore $p]} {continue}
		for {set i 0} {$i < [llength $value]} {incr i} {
			set v [lindex $value $i]
			set val ""
			eval css::GetProperties[set css::Property($p)] $p v val
			set index 0
			set propvalue ""
			eval css::ReadDialog[set css::Property($p)] $p val index important propvalue errtext
			if {$propvalue != ""} {
				regsub ";\r$p: " $propvalue "" propvalue
				set prop($p) $propvalue
				break
			}
		}
		if {$i < [llength $value]} {set value [lreplace $value $i $i]}
	}
	if {[llength $value]} {lappend errorText "$group: $value"}
}

proc css::ExpandPileIfBoth {group value pv err} {
	upvar $pv prop $err errorText
	if {[llength $value] == 1} {lappend value $value}
	css::ExpandPile $group $value prop errorText
}

proc css::ExpandBorder {group value pv err} {
	upvar $pv prop $err errorText
	global css::Group
	css::ExpandPile $group $value prop errorText
	foreach p [set css::Group($group)] {
		if {[info exists prop($p)]} {
			regsub -- "-top-" $p "-" p1
			set prop($p1) $prop($p)
			unset prop($p)
		}
	}
}

proc css::ExpandURL {group value pv err urlprop {ignore ""}} {
	upvar $pv prop $err errorText
	if {[regexp -nocase -indices {url\([ \t\r\n]*("[^"]+"|'[^']+'|[^ \t\n\r\)]+)[ \t\r\n]*\)} $value uv]} {
		set prop($urlprop) [string range $value [lindex $uv 0] [lindex $uv 1]]
		set value "[string range $value 0 [expr {[lindex $uv 0] - 1}]][string range $value [expr {[lindex $uv 1] + 1}] end]"
		css::ExpandPile $group $value prop errorText [concat $urlprop $ignore]
	} else {
		css::ExpandPile $group $value prop errorText $ignore
	}
}

proc css::ExpandListStyle {group value pv err} {
	upvar $pv prop $err errorText
	css::ExpandURL $group $value prop errorText list-style-image
}

proc css::ExpandCue {group value pv err} {
	upvar $pv prop $err errorText
	set exp "url\\(\[ \t\r\n\]*(\"\[^\"\]+\"|'\[^'\]+'|\[^ \t\n\r\\)\]+)\[ \t\r\n\]*\\)"
	regsub -all -nocase $exp $value "\{\\0\}" value
	css::ExpandPileIfBoth $group $value prop errorText
}

proc css::ExpandFont {group value pv err} {
	upvar $pv prop $err errorText
	global css::Choices css::FontValue
	set css::FontValue ""
	if {[lsearch -exact [set css::Choices(font)] [string tolower $value]] >= 0} {
		set css::FontValue [string tolower $value]
		return
	}
	regexp {[^ \t\r\n]*(,[ \t\r\n]*[^ \t\r\n]+)*[ \t\r\n]*$} $value family
	regsub -all "\[\t\r\n\]+" $family " " family
	set value [string range $value 0 [expr {[string length $value] - [string length $family] - 1}]]
	set prop(font-family) [string trim $family]
	set fontsize [string tolower [lindex $value end]]
	set lineheight ""
	regexp {^([^/]+)/?(.*)$} $fontsize "" fontsize lineheight
	if {[lcontains css::Choices(font-size) $fontsize] || ![catch {css::CheckNumber font-size length $fontsize "" 1 0 0}]} {
		set prop(font-size) $fontsize
	}
	if {[lcontains css::Choices(line-height) $lineheight] || ![catch {css::CheckNumber line-height length $lineheight " " 1 1 0}]} {
		set prop(line-height) $lineheight
	}
	set value [lrange $value 0 [expr {[llength $value] - 2}]]
	if {[regsub -all "normal" $value "" value]} {
		set prop(font-style) normal
		set prop(font-variant) normal
		set prop(font-weight) normal
	}
	css::ExpandPile $group $value prop errorText {font-family font-size line-height}
}

proc css::ExpandBackground {group value pv err} {
	upvar $pv prop $err errorText
	
	foreach bp [list {top center bottom} {left center right}] {
		set nv ""
		foreach v $value {
			if {[lcontains bp $v]} {
				lappend prop(background-position) $v
			} else {
				lappend nv $v
			}
		}
		set value $nv
	}
	set nv ""
	foreach v $value {
		if {![catch {css::CheckNumber background-position length $v "" 1 0 0} v1]} {
			lappend prop(background-position) $v1
		} else {
			append nv " " $v
		}
	}
	set value $nv
	css::ExpandURL $group $value prop errorText background-image background-position
}


#===============================================================================
# ×××× Button actions ×××× #
#===============================================================================

proc css::ColorButton {v index} {
	upvar $v val
	if {[set newColor [html::AddANewColor]] != ""} {
		if {[string index $newColor 0] == "#"} {
			set val [lreplace $val [incr index -2] $index "$newColor"]
		} else {
			set val [lreplace $val [incr index -1] $index "$newColor"]
		}
	}
}

proc css::FileButton {v index} {
	upvar $v val
	global html::UserURLs
	if {[set newFile [html::GetFile]] != ""} {
		if {[lcontains html::UserURLs [lindex $newFile 0]]} {
			set val [lreplace $val [incr index -1] $index [lindex $newFile 0]]
		} else {
			set val [lreplace $val [incr index -2] $index [lindex $newFile 0]]
		}
	}
}

proc css::FamilyAddButton {v index} {
	upvar $v val
	if {[set f [lindex $val [expr {$index - 2}]]] != "inherit" && $f != " "} {
		set fm [string trim [join [list [lindex $val [expr {$index - 1}]] $f] ", "] ", "]
		set val [lreplace $val [expr {$index - 2}] [expr {$index - 1}] " " $fm]
	}	
}

proc css::ContentAddButton {v index} {
	upvar $v val
	if {[set f [lindex $val [expr {$index - 2}]]] != "inherit" && $f != " "} {
		set fm [string trim [join [list [lindex $val [expr {$index - 1}]] $f] " "]]
		set val [lreplace $val [expr {$index - 2}] [expr {$index - 1}] " " $fm]
	}	
}

proc css::ContentURLButton {v index} {
	upvar $v val
	set uind [expr {$index + 1}]
	if {[set txt [css::ReadUrl val uind]] != ""} {
		set val [lreplace $val [expr {$index - 2}] [expr {$index - 2}] [string trim "[lindex $val [expr {$index - 2}]] $txt"]]
		set val [lreplace $val [expr {$index + 1}] [expr {$index + 2}] "" " "]
	}
}

proc css::ContentCounterButton {v index} {
	upvar $v val
	set name [string trim [lindex $val [expr {$index + 1}]]]
	set string [string trim [lindex $val [expr {$index + 2}]]]
	set style [lindex $val [expr {$index + 3}]]
	if {$name == ""} {alertnote "The counter name must be specified."; return}
	if {![regexp {^[^-0-9][^ \t\r\n]*$} $name]} {alertnote "Invalid counter name."; return}
	if {$string != ""} {set string [css::QuoteValue $string]}
	set txt counter
	if {$string != ""} {append txt "s"}
	append txt "($name"
	if {$string != ""} {append txt ",$string"}
	if {$style != " "} {append txt ",$style"}
	append txt ")"
	set val [lreplace $val [expr {$index - 6}] [expr {$index - 6}] [string trim "[lindex $val [expr {$index - 6}]] $txt"]]
	set val [lreplace $val [expr {$index + 1}] [expr {$index + 3}] "" "" " "]
}

proc css::ContentAttrButton {v index} {
	upvar $v val
	if {[set attr [string trim [lindex $val [expr {$index - 1}]]]] != ""} {
		set val [lreplace $val [expr {$index - 11}] [expr {$index - 11}] [string trim "[lindex $val [expr {$index - 11}]] attr($attr)"]]
		set val [lreplace $val [expr {$index - 1}] [expr {$index - 1}] ""]
	}
}

proc css::QuotesAddButton {v index} {
	upvar $v val
	set q1 [string trim [lindex $val [incr index -2]]]
	set q2 [string trim [lindex $val [incr index]]]
	if {$q1 == "" || $q2 == ""} {
		alertnote "Both the opening and closing quote strings must be specified."
		return
	}
	set q1 [css::QuoteValue $q1]
	set q2 [css::QuoteValue $q2]
	set val [lreplace $val [incr index -1] [incr index 3] "" "" 0 "[lindex $val $index] $q1 $q2"]
}

proc css::FontSizeAddButton {v index} {
	upvar $v val
	incr index
	set errtext ""
	if {[set txt [css::ReadNumber font-size val index length 0 0 0 errtext]] != ""} {
		if {$errtext != ""} {
			alertnote $errtext
		} else {
			set val [lreplace $val [expr {$index - 2}] $index "" " " [string trim "[lindex $val $index],$txt" ", "]]
		}
	}
}

proc css::AddTextShadow {v index} {
	upvar $v val
	set errtext ""
	incr index -9
	foreach item {horizontal vertical blur} {
		set $item [css::ReadNumber $item val index length 0 0 0 errtext]
	}
	if {$horizontal == "" || $vertical == ""} {
		alertnote "Both a horizontal and vertical value must be specified."
		return
	}
	set txt "$horizontal$vertical$blur"
	append txt [css::ReadColor color val index errtext]
	if {$errtext != ""} {
		html::ErrorWindow "Invalid input" $errtext
	} else {
		incr index
		set val [lreplace $val $index $index [string trim "[lindex $val $index], $txt" ", "]]
		set val [lreplace $val [expr {$index - 10}] [expr {$index - 3}] "" "" "" "" "" "" "" " "]
	}
}

proc css::SrcButton {v index} {
	upvar $v val
	set turl [string trim [lindex $val [incr index -5]]]
	set murl [lindex $val [incr index]]
	set format [string trim [lindex $val [incr index 2]]]
	set face [string trim [lindex $val [incr index]]]
	set url ""
	if {[set u $turl] != "" || [set u $murl] != " "} {set url $u}
	if {$url != ""} {
		if {$format != "" && ![regexp {^("[^"]+"|'[^']+')([ \t\r\n]*,[ \t\r\n]("[^"]+"|'[^']+'))*$} $format]} {
			alertnote "Format should be a list of comma separated strings."
		} else {
			set i $index
			set newval url(\"$url\")
			if {$format != ""} {append newval " format($format)"}
			set val [lreplace $val [incr i 2] $i [string trimleft [join [list [lindex $val $i] $newval] ", "] ", "]]
			set val [lreplace $val [incr i -6] [incr i 3] "" " " 0 ""]
		}
	}
	if {$face != ""} {
		set val [lreplace $val [incr index 2] $index [string trimleft [join [list [lindex $val $index] "local(\"$face\")"] ", "] ", "]]
		set val [lreplace $val [incr index -2] $index ""]
	}
}

proc css::CursorAddButton {v index} {
	upvar $v val
	incr index -4 
	if {[set url [css::ReadUrl val index]] != ""} {
		set val [lreplace $val [expr {$index - 3}] $index "" " " 0 [string trimleft [join [list [lindex $val $index] $url] ", "] ", "]]
	}
}

#===============================================================================
# ×××× Checking dialog values ×××× #
#===============================================================================

# Check if a color number is a valid number, or one of the predefined names.
proc css::CheckColorNumber {color} {
	global html::ColorName css::Colors html::userColors
	if {[info exists html::ColorName($color)]} {return $color}
	if {[info exists html::userColors($color)]} {return [set html::userColors($color)]}
	set color [string tolower $color]
	if {[set i [lsearch -exact [string tolower ${css::Colors}] $color]] >= 0} {
		return [lindex ${css::Colors} $i]
	}
	# rgb(1,2,3)
	if {[regexp {^rgb\(([0-9]+),([0-9]+),([0-9]+)\)$} $color dum c1 c2 c3]} {
		if {$c1 > -1 && $c1 < 256 && $c2 > -1 && $c2 < 256 && $c3 > -1 && $c3 < 256} {
			return $color
		} else {
			error "Invalid color."
		}
	}
	# rgb(1.0%,2.0%,3.0%)
	if {[regexp {^rgb\(([0-9]+\.?[0-9]*)%,([0-9]+\.?[0-9]*)%,([0-9]+\.?[0-9]*)%\)$} $color dum c1 c2 c3]} {
		if {$c1 >= 0.0 && $c1 <= 100.0 && $c2 >= 0.0 && $c2 <= 100.0 && $c3 >= 0.0 && $c3 <= 100.0} {
			return $color
		} else {
			error "Invalid color."
		}
	}
		
	# #123456 or #123
	if {[string index $color 0] != "#"} {
		set color "#${color}"
	}
	set color [string toupper $color]
	if {([string length $color] != 7 && [string length $color] != 4) || ![regexp {^#[0-9A-F]+$} $color]} {
		error "Invalid color."
	} else {
		return $color
	}	
}

# Check if a CSS number is ok.
proc css::CheckNumber {prop type num unit percent number integer} {
	global css::Units css::Range
	if {![regexp {^([-\+]?[0-9]+\.?[0-9]*)([%a-zA-Z]*)$} $num d n u]} {
		error "Invalid number, $num."
	}
	if {$integer && [regexp {\.} $n]} {
		error "Integer required, $num."
	}
	if {$u != ""} {set unit $u}
	set allowedUnits ""
	if {$type != ""} {set allowedUnits [set css::Units($type)]}
	if {$percent} {lappend allowedUnits %}
	if {$number} {lappend allowedUnits " "}
	if {[set w [lsearch -exact [string tolower $allowedUnits] [string tolower $unit]]] < 0 && $num != "0"} {
		if {$number && [llength $allowedUnits] == 1} {error "Invalid number, $num."}
		error "Invalid unit, $num."
	}
	regexp {([^:]*):(.*)} [set css::Range($prop)] "" min max
	if {$min != "-i" && $n < $min} {error "Value must be greater than or equal to $min."}
	if {$max != "i" && $n > $max} {error "Value must be less than or equal to $min."}
	set unit [lindex $allowedUnits $w]
	if {$unit == " "} {set unit ""}
	return "$n$unit"
}

proc css::CheckUrange {urange} {
	return [regexp {^U\+([0-9A-F\?]+|[0-9A-F]+-[0-9A-F]+)$} $urange]
}
