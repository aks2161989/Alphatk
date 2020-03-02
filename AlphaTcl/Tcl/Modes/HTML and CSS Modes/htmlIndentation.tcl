## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlIndentation.tcl"
 #                                    created: 99-07-17 22.45.03 
 #                                last update: 02/07/2005 {12:27:23 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 3.2
 # 
 # Copyright 1996-2003 by Johan Linde
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
# This file contains procs for handling the indentation of HTML elements.
#===============================================================================

#===============================================================================
# ◊◊◊◊ Indentation ◊◊◊◊ #
#===============================================================================
  
# Find the indentation the current line should have.
proc html::FindIndent {args} {
	win::parseArgs w {pos0 ""}
	
	global HTMLmodeVars
	set indent $HTMLmodeVars(indentElements)
	# Find previous non-blank line.
	if {$pos0 == ""} {set pos0 [getPos -w $w]}
	set pos [pos::math -w $w [lineStart -w $w $pos0] - 1]
	while {[pos::compare -w $w $pos > [minPos]] \
	  && [regexp -- {^[ \t]*$} [getText -w $w [lineStart -w $w $pos] $pos]]} {
		set pos [pos::math -w $w [lineStart -w $w $pos] - 1]
	}
	if {[pos::compare -w $w $pos < [minPos]]} {set pos [minPos]}
	# Get indentation on that line.
	set previndent [html::GetIndent -w $w $pos]
	# Find last tag on or before that line.
	if {[catch {search -w $w -s -f 0 -m 0 -r 1 {<([^<>]+)>} $pos} tag] || 
	[pos::compare -w $w [lindex $tag 1] < [lineStart -w $w $pos]] ||
	( [pos::compare -w $w [lindex $tag 0] < [lineStart -w $w $pos0]] && [pos::compare -w $w [lindex $tag 1] > [lineStart -w $w $pos0]])} {
		set tag ""
	} else {
		set tag [string trim [eval [list getText -w $w] $tag] "<>"]
	}
	regexp {^[ \t\r\n]*(/?[^ \r\t\n>/]+)} $tag "" tag
	set tag [string toupper $tag]
	# Add to indentation?
	if {[lcontains indent $tag]} {
		set previndent [html::IncreaseIndent -w $w $previndent]
	}
	# Find last tag on current line.
	set tag ""
	set lstart [lineStart -w $w $pos0]
	if {[pos::compare -w $w [set npos [nextLineStart -w $w $pos0]] <= $lstart]} {
		set lend $lstart
	} else {
		set lend [pos::math -w $w $npos - 1]
	}
	regexp {<([^<>]+)>[^<>]*$} [getText -w $w $lstart $lend] dum tag
	regexp {[ \t\r\n]*([^ \r\t\n>]+)} $tag "" tag
	set tag [string toupper $tag]
	
	# Reduce indentation?
	if {[string index $tag 0] == "/" && [lcontains indent [string range $tag 1 end]]} {
		set previndent [html::ReduceIndent -w $w $previndent]
	}
	return $previndent
}

# Find the indentation the next line should have.
proc html::FindNextIndent {args} {
	win::parseArgs w {pos0 ""}
	
	global HTMLmodeVars
	set indent $HTMLmodeVars(indentElements)
	if {$pos0 == ""} {set pos0 [getPos -w $w]}
	set ind [html::FindIndent -w $w $pos0]
	# Find last tag before pos0 on current line.
	set tag ""
	set lstart [lineStart -w $w $pos0]
	regexp {<([^<>]+)>[^<>]*$} [getText -w $w $lstart $pos0] dum tag
	regexp {^[ \t\r\n]*(/?[^ \r\t\n>/]+)} $tag "" tag
	set tag [string toupper $tag]
	# Add to indentation?
	if {[lcontains indent $tag]} {set ind [html::IncreaseIndent -w $w $ind]}
	return $ind
}

# get the leading whitespace of the line determined by pos
proc html::GetIndent {args} {
	win::parseArgs w pos
	return [text::indentOf -w $w [string length [text::maxSpaceForm -w $w [text::indentString -w $w $pos]]]]
}

# Adds indentationAmount whitespace.
proc html::IncreaseIndent {args} {
	win::parseArgs w indent
	return [text::indentBy -w $w $indent [text::getIndentationAmount -w $w]]
}

# Removes indentationAmount whitespace.
proc html::ReduceIndent {args} {
	win::parseArgs w indent
	return [text::indentBy -w $w $indent [expr {-[text::getIndentationAmount -w $w]}]]
}

proc html::IndentShouldBeAdjusted {{pos ""}} {
    if {$pos == ""} {set pos [getPos]}
	return [expr {[string length [text::maxSpaceForm [text::indentString $pos]]] < [string length [text::maxSpaceForm [html::FindNextIndent $pos]]]}]
}

#===============================================================================
# ◊◊◊◊ Reformat paragraph/document ◊◊◊◊ #
#===============================================================================

proc html::RegisterFormattingStyle {style menutext lineproc {blockproc ::indentRegion} {corrindproc ::correctIndentation}} {
	global html::formattingStyles html::formatBlockProcs html::indentLineProcs html::correctIndentProc
	set html::formattingStyles [lunique [lappend html::formattingStyles $style]]
	set html::formatBlockProcs($style) $blockproc
	set html::indentLineProcs($style) $lineproc
	set html::correctIndentProc($style) $corrindproc
	;proc [join $menutext ""] {} "html::InsertFormatTags $style"
	menu::insert Formatting items end $menutext
}

proc html::InsertFormatTags {tag} {
	global htmlCurSel htmlIsSel
	if {![win::checkIfWinToEdit]} {return}
	html::GetSel
	if {!$htmlIsSel} {
		elec::Insertion "[html::OpenCR]<!-- [html::SetCase #$tag] -->\r•content•\r<!-- [html::SetCase /#$tag] -->•end•"
	} else {
		replaceText [getPos] [selEnd] "<!-- [html::SetCase #$tag] -->\r$htmlCurSel\r<!-- [html::SetCase /#$tag] -->"
	} 
}

proc html::NoFormatting {} {
	html::InsertFormatTags NO-FORMATTING
}

proc html::CStyleFormatting {} {
	html::InsertFormatTags C-STYLE-FORMATTING
}
proc html::ReformatParagraph {} {html::TidyUp paragraph}
proc html::ReformatDocument {} {html::TidyUp document}

proc html::TidyUp {where} {
	global fillColumn
	if {![win::checkIfWinToEdit]} {return}
	set oldFill $fillColumn
	catch {html::TidyUp2 $where}
	set fillColumn $oldFill
}

proc html::TidyUp2 {where} {
	global HTMLmodeVars html::ElemLayout fillColumn html::formattingStyles html::formatBlockProcs
	status::msg "Reformatting…"
	set oldfillColumn $fillColumn
	if {$where == "paragraph"} {
		set selection [isSelection]
		if {$selection} {
			set startPos [getPos]
			set endPos [selEnd]
		} else {
			if {[catch {search -s -f 0 -m 0 -r 1 {^[ \t]*$} [getPos]} sp]} {set sp [list [minPos] [minPos]]}
			set startPos [nextLineStart [lindex $sp 1]]
			if {[catch {search -s -f 1 -m 0 -r 1 {^[ \t]*$} [getPos]} sp]} {set sp [list [minPos] [maxPos]]}
			if {[pos::compare [lindex $sp 1] < [maxPos]]} {
				set endPos [pos::math [lindex $sp 1] + 1]
			} else {
				set endPos [maxPos]
			}
		}
		if {[pos::compare $startPos == $endPos]} {return}
		# Avoid doing something inside STYLE and SCRIPT and PRE.
		foreach stsc {STYLE SCRIPT PRE} {
			if {[html::IsInContainer $stsc $startPos]} {
				if {[catch {search -s -f 1 -m 0 -r 0 -i 1 "</$stsc>" $startPos} rrr]} {
					status::msg ""; return
				} else {
					set startPos [lindex $rrr 1]
				}
			}
			if {[html::IsInContainer $stsc $endPos]} {
				if {[catch {search -s -f 0 -m 0 -r 1 -i 1 "<$stsc\[^<>\]*>" $endPos} rrr]} {
					status::msg ""; return
				} else {
					set endPos [lindex $rrr 0]
				}
			} 
		}
		set informat 0
		# Avoid doing someting inside formatting tags.
		foreach stsc ${html::formattingStyles} {
			if {[html::IsInCommentContainer $stsc $startPos]} {
				if {[catch {search -s -f 1 -m 0 -r 1 -i 1 "<!--\[ \t\r\n\]*/#$stsc\[ \t\r\n\]*-->" $startPos} rrr]} {
					status::msg ""; return
				} else {
					set startPos [lindex $rrr 1]
				}
				set informat 1
				set form $stsc
			}
			if {[html::IsInCommentContainer $stsc $endPos]} {
				if {[catch {search -s -f 0 -m 0 -r 1 -i 1 "<!--\[ \t\r\n\]*#$stsc\[ \t\r\n\]*-->" $endPos} rrr]} {
					status::msg ""; return
				} else {
					set endPos [lindex $rrr 0]
				}
				set informat 1
				set form $stsc
			} 
		}
		set ind [html::FindIndent $startPos]
		set fillColumn [expr {$oldfillColumn - [string length [text::maxSpaceForm $ind]]}]
		set cr 2
	} else {
		set startPos [minPos]
		set endPos [maxPos]
		set ind ""
		set cr 0
	}
	# Indent region if completely inside STYLE, SCRIPT, PRE or formatting tags.
	if {[pos::compare $startPos > $endPos]} {
		if {$informat} {
			if {[set html::formatBlockProcs($form)] != ""} {
				eval [set html::formatBlockProcs($form)]
			}
		} else {
			::indentRegion
		}
		status::msg ""
		return
	}
	# Remember position
	if {[pos::compare [getPos] > $startPos]} {
		set pos [getPos]
	} else {
		set pos $startPos
	}
	if {[pos::compare [pos::math $pos - 20] < $startPos]} {
		set srem $startPos
	} else {
		set srem [pos::math $pos - 20]
	}
	set remember_str [quote::Regfind [getText $srem $pos ]]
	regsub -all {\?} $remember_str {\\?} remember_str
	regsub -all "\[ \t\r\n\]+" $remember_str {[ \t\r\n]+} remember_str
	# To handle indentation
	set indList $HTMLmodeVars(indentElements)
	
	# These tags should have a blank line before
	set blBef {}
	# These tags should have a cr before
	set crBef {!--}
	# These tags should have a blank line after
	set blAft {}
	# These tags should have a cr after
	set crAft {!-- !DOCTYPE ?XML}
	# Custom elements
	foreach c [array names html::ElemLayout] {
		switch [set html::ElemLayout($c)] {
			open00 -
			nocr {}
			open01 {lappend crAft $c}
			open10 {lappend crBef $c}
			open11 {lappend crBef $c; lappend crAft $c}
			cr0 {lappend crBef $c; lappend crAft /$c}
			cr1 {lappend blBef $c; lappend blAft /$c}
			cr2 {lappend blBef $c; lappend crBef /$c; lappend blAft /$c; lappend crAft $c}
		}
	}
	set all [concat $blBef $blAft $crBef $crAft]
	set bef [concat $blBef $crBef]
	set aft [concat $blAft $crAft]
	set pos $startPos
	set tmp ""
	set text ""
	while {![catch {search -s -f 1 -m 0 -r 1 {(<!--|<[^<>]+>)} $pos} pos1] && [pos::compare [lindex $pos1 1] <= $endPos]} {
		set wholeTag [string trim [eval getText $pos1] "<>"]
		if {[string range $wholeTag 0 2] == "!--"} {
			set wholeTag "!--"
			set pos1 [list [lindex $pos1 0] [pos::math [lindex $pos1 0] + 4]]
		}
		set tag ""
		regexp {^[ \t\r\n]*(/?[^ \t\r\n>/]+)} $wholeTag "" tag
		set tag [string toupper $tag]
		if {$tag != "!--"} {
			set w ""
			# To avoid line breaks inside attributes
			while {[regexp -indices {=[ \t\r\n]*(\"[^ \"]* [^\"]*\"|'[^ ']* [^']*')} $wholeTag i]} {
				append w [string range $wholeTag 0 [expr {[lindex $i 0] - 1}]]
				regsub -all "\[ \t\r\n\]+" [string range $wholeTag [lindex $i 0] [lindex $i 1]] "" w1
				append w $w1
				set wholeTag [string range $wholeTag [expr {[lindex $i 1] + 1}] end]
			}
			set wholeTag $w$wholeTag
		}
		append tmp [getText $pos [lindex $pos1 0]]
		set pos [lindex $pos1 1]			
		if {[lsearch $all $tag] < 0} {
			append tmp <$wholeTag>
			continue
		}
		# cr or blank line before tag
		if {[lsearch $bef $tag] >= 0} {
			regsub -all "\[ \t\]*\[\r\n\]\[ \t\]*" [string trim $tmp] " " tmp
			set tmp [string trimright [breakIntoLines $tmp]]
			regsub -all "" $tmp " " tmp
			regsub -all "\r" $tmp "\r$ind" tmp
			if {![is::Whitespace $tmp]} {set cr 0; append text $ind}
			append text $tmp
			set ble [lsearch $blBef $tag]
			if {$cr == 1 && $ble >= 0} {
				append text $ind
			}
			if {$cr == 0} {
				append text \r
				incr cr
				if {$cr == 1 && $ble >= 0} {append text $ind}
			}
			if {$ble >= 0 && $cr < 2} {append text \r; incr cr}
			set tmp <$wholeTag>
			# Take care of comments separately
			if {$tag == "!--"} {
				set tmp "<!--"
				if {[catch {search -s -f 1 -m 0 -r 1 -i 1 -- "-->" $pos} pos2]} {
					set pos2 "[minPos] $endPos"
				} elseif {[regexp -nocase "\[ \t\r\n\]*#([join ${html::formattingStyles} |])\[ \t\r\n\]*-->" [getText $pos [lindex $pos2 1]] "" form]} {
					if {[catch {search -s -f 1 -m 0 -r 1 -i 1 "<!--\[ \t\r\n\]*/#$form\[ \t\r\n\]*-->" $pos2} pos2]} {
						set pos2 "[minPos] [maxPos]"
					}
				}
				append text $ind$tmp[getText $pos [set pos [lindex $pos2 1]]]
				set tmp ""
				set cr 0
			}
			# The contents of these tags should be left untouched
			if {[lsearch {SCRIPT STYLE PRE} $tag] >= 0} {
				set tag /$tag
				regsub -all "" $tmp " " tmp
				if {[catch {search -s -f 1 -m 0 -r 1 -i 1 "<$tag>" $pos} pos2]} {set pos2 "[minPos] $endPos"}
				append text $ind$tmp[getText $pos [set pos [lindex $pos2 1]]]
				set tmp ""
				set cr 0
			}
		} else {
			append tmp <$wholeTag>
		}
		# cr or blank line after tag
		if {[lsearch $aft $tag] >= 0} {
			if {[string index $tag 0] == "/" && [lsearch $indList [string range $tag 1 end]] >= 0} {
				set ind [html::ReduceIndent $ind]
				set fillColumn [expr {$oldfillColumn - [string length [text::maxSpaceForm $ind]]}]
			}
			regsub -all "\[ \t\]*\[\r\n\]\[ \t\]*" [string trim $tmp] " " tmp
			set tmp [string trimright [breakIntoLines $tmp]]
			regsub -all "" $tmp " " tmp
			regsub -all "\r" $tmp "\r$ind" tmp
			if {![is::Whitespace $tmp]} {set cr 0; append text $ind}
			append text $tmp
			set bla [lsearch $blAft $tag]
			if {[lsearch $indList $tag] >= 0} {
				set ind [html::IncreaseIndent $ind]
				set fillColumn [expr {$oldfillColumn - [string length [text::maxSpaceForm $ind]]}]
			}
			if {$cr == 0} {
				append text \r
				incr cr
				if {$cr == 1 && $bla >= 0} {append text $ind}
			}
			if {$bla >= 0 && $cr < 2} {append text \r; incr cr}
			set tmp ""
		}
	}
	# Add what's left
	if {$tmp != "" || [pos::compare $pos < $endPos]} {
		if {[pos::compare $pos < $endPos]} {append tmp [getText $pos $endPos]}
		regsub -all "\[ \t\]*\[\r\n\]\[ \t\]*" [string trim $tmp] " " tmp
		set tmp [string trimright [breakIntoLines $tmp]]
		regsub -all "" $tmp " " tmp
		regsub -all "\r" $tmp "\r$ind" tmp
		if {![is::Whitespace $tmp]} {append text $ind}
		append text $tmp
		if {![is::Whitespace $tmp]} {append text \r}
	}
	# Make sure there is a blank line after the text when tidying paragraph and there's no selection
	if {$where == "paragraph" && !$selection && ![regexp {\r[ \t]*\r[ \t]*$} $text]} {append text \r}
	replaceText $startPos $endPos $text
	# Go back to previous position.
	if { $remember_str != "" } {
		set end [pos::math $startPos + [string length $text]]
		regexp -indices $remember_str [getText $startPos $end] wholematch
		if {[info exists wholematch]} {
			set p [pos::math $startPos + 1 + [lindex $wholematch 1]]
		} else {
			set p $end
		}
		if {[pos::compare $p >= $end]} {
			goto [pos::math $end - 1]
		} else {
			goto $p
		}
	}
}
