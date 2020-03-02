## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlCharTrans.tcl"
 #                                    created: 99-07-20 17.51.05 
 #                                last update: 03/21/2006 {03:07:40 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 3.2
 # 
 # Copyright 1996-2006 by Johan Linde
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
# This file contains the procs for the Character Translation submenu.
#===============================================================================

proc htmlCharTrans.tcl {} {}

#
# Converting  characters to HTML entities.
#
# 1 = < > &
# 0 = ‡Ž etc.
proc html::Characterstohtml {ltgtamp} {
	global html::SpecialCharacter
	
	if {![win::checkIfWinToEdit]} {return}
	if {$ltgtamp} {
		set charlist {& < >}
	} else {
		set charlist [array names html::SpecialCharacter]
	}
	
	set subs1 0;  set lett 0
	set upos1 [getPos]
	if {[set start $upos1] == [set end [selEnd]]} {
		if {$ltgtamp && \
		[askyesno "There is no selection. Really translate < > & in whole document?"] == "no"} {return}
		set messageString "document"
		set start [minPos]
		set end [maxPos]
		set isDoc 1
	} else {
		set messageString "selection"
		set isDoc 0
	}
	status::msg "TranslatingÉ"
	set tmp [getText $start $end]
	set text ""
	set pos [set upos [pos::diff [minPos] $upos1]]
	set st [set st0 [pos::diff [minPos] $start]]
	if {!$ltgtamp} {
		while {[regexp -indices "<!--" $tmp str] && [regexp -indices -- "-->" $tmp str1]} {
			if {[lindex $str1 0] > [lindex $str 1]} {
				set sv [string range $tmp [lindex $str 0] [lindex $str1 1]]
				if {[expr {$st + [lindex $str1 1]}] < $upos} {
					incr pos [expr {6 - [string length $sv]}]
				} elseif {[expr {$st + [lindex $str 0]}] < $upos} {
					incr pos [expr {$st + [lindex $str 0] - $upos}]
				}
				lappend savestr $sv
				append text [string range $tmp 0 [expr {[lindex $str 0] - 1}]] ""
			} else {
				append text [string range $tmp 0 [lindex $str1 1]]
			}
			set tmp [string range $tmp [expr {[lindex $str1 1] + 1}] end]
			incr st [expr {[lindex $str1 1] + 1}]
		}
		append text $tmp
	} else {
		set text $tmp
	}
	if {$isDoc} {	
		set text1 [string range $text 0 [expr {$pos - $st0 - 1}]]
		set text2 [string range $text [expr {$pos - $st0}] end]
	} else {
		set text1 $text
	}
	foreach char $charlist {
		if {[info exists html::SpecialCharacter($char)]} {
			set rtext "\\&[set html::SpecialCharacter($char)];"
		} elseif {$char == ">"} {
			set rtext "\\&gt;" 
		} elseif {$char == "<"} {
			set rtext "\\&lt;"
		} elseif {$char == "&"} {
			set rtext "\\&amp;"
		}
		
		catch {set subNum [regsub -all $char $text1 [set rtext] text1]}
		incr subs1 [expr {$subNum * ([string length $rtext] - 2)}]
		incr lett $subNum
		if {$isDoc} {
			catch {incr lett [regsub -all $char $text2 [set rtext] text2]}
		}
		
	}
	set text $text1
	if {$isDoc} {append text $text2}
	if {$lett} {
		if {[info exists savestr]} {
			set i 0
			set tmp ""
			while {[regexp -indices -nocase {} $text str]} {
				append tmp [string range $text 0 [expr {[lindex $str 0] - 1}]]
				append tmp [lindex $savestr $i]
				set text [string range $text [expr {[lindex $str 1] + 1}] end]
				incr i
			}
			set text "$tmp$text"
		}
		replaceText $start $end $text
		if {$isDoc} {
			goto [pos::math $upos1 + $subs1]
		} else {
			selectText $start [getPos]
		}
	}
	status::msg "$lett characters translated in $messageString."
}



#
# Converting HTML entities to characters.
#
# 1 = < > &
# 0 = ‡Ž etc.
proc html::htmltoCharacters {ltgtamp} {
	global html::CharacterSpecial
	
	if {![win::checkIfWinToEdit]} {return}
	status::msg "TranslatingÉ"
	
	if {$ltgtamp} {
		set entitylist {"&amp;" "&lt;" "&gt;"} 
	} else {
		foreach a [array names html::CharacterSpecial] {
			lappend entitylist "&$a;"
		}
	}
	set subs1 0;  set lett 0
	set upos1 [getPos]
	if {[set start $upos1] == [set end [selEnd]]} {
		# Move position to linestart to make sure no letter is split.
		set upos1 [lineStart $upos1]
		set messageString "document"
		set start [minPos]
		set end [maxPos]
		set isDoc 1
	} else {
		set messageString "selection"
		set isDoc 0
	}

	set tmp [getText $start $end]
	set text ""
	set pos [set upos [pos::diff [minPos] $upos1]]
	set st [set st0 [pos::diff [minPos] $start]]
	if {!$ltgtamp} {
		while {[regexp -indices "<!--" $tmp str] && [regexp -indices -- "-->" $tmp str1]} {
			if {[lindex $str1 0] > [lindex $str 1]} {
				set sv [string range $tmp [lindex $str 0] [lindex $str1 1]]
				if {[expr {$st + [lindex $str1 1]}] < $upos} {
					incr pos [expr {6 - [string length $sv]}]
				} elseif {[expr {$st + [lindex $str 0]}] < $upos} {
					incr pos [expr {$st + [lindex $str 0] - $upos}]
				}
				lappend savestr $sv
				append text [string range $tmp 0 [expr {[lindex $str 0] - 1}]] ""
			} else {
				append text [string range $tmp 0 [lindex $str1 1]]
			}
			set tmp [string range $tmp [expr {[lindex $str1 1] + 1}] end]
			incr st [expr {[lindex $str1 1] + 1}]
		}
		append text $tmp
	} else {
		set text $tmp
	}
	if {$isDoc} {
		set text1 [string range $text 0 [expr {$pos - $st0 - 1}]]
		set text2 [string range $text [expr {$pos - $st0}] end]
	} else {
		set text1 $text
	}		
	foreach char $entitylist {
		set schar [string range $char 1 [expr {[string length $char] - 2}]]
		if {[info exists html::CharacterSpecial($schar)]} {
			set rtext [set html::CharacterSpecial($schar)]
		} elseif {$schar == "amp"} {
			set rtext "\\&"
		} elseif {$schar == "lt"} {
			set rtext "<"
		} elseif {$schar == "gt"} {
			set rtext ">"
		}
		
		set subNum [regsub -all $char $text1 $rtext text1]
		incr subs1 [expr {$subNum * ([string length $char] - 1)}]
		incr lett $subNum
		if {$isDoc} {
			incr lett [regsub -all $char $text2 $rtext text2]
		}
		
	}
	set text $text1
	if {$isDoc} {append text $text2}
	if {$lett} {
		if {[info exists savestr]} {
			set i 0
			set tmp ""
			while {[regexp -indices -nocase {} $text str]} {
				append tmp [string range $text 0 [expr {[lindex $str 0] - 1}]]
				append tmp [lindex $savestr $i]
				set text [string range $text [expr {[lindex $str 1] + 1}] end]
				incr i
			}
			set text "$tmp$text"
		}
		replaceText $start $end $text
		if {$isDoc} {
			goto [pos::math $upos1 - $subs1]
		} else {
			selectText $start [getPos]
		}
	}
	status::msg "$lett characters translated in $messageString."
}

