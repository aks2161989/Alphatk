## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlElems.tcl"
 #                                    created: 96-04-29 21.31.14 
 #                                last update: 01/24/2005 {06:16:08 PM} 
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
# This file contains procs for various menu items found in the element submenus.
#===============================================================================

#===============================================================================
# ×××× Insert/Remove linebreaks ×××× #
#===============================================================================

# Insert a <BR> in the end of every line in selection.

proc html::InsertLineBreaks {} {
	global html::xhtml HTMLmodeVars
	if {![win::checkIfWinToEdit]} {return}
	if {![isSelection]} {
		beep
		status::msg "No selection."
		return
	}
	set br [html::SetCase "<BR"]
	if {$html::xhtml} {
		if {$HTMLmodeVars(extraSpace)} {append br " "}
		append br /
	}
	append br >
	regsub -all {[\r\n]} [getSelect] "$br\r" text
	replaceText [getPos] [selEnd] $text
}

# Remove all <BR> in selection.
proc html::RemoveLineBreaks {} {
	if {![win::checkIfWinToEdit]} {return}
	if {![isSelection]} {
		beep
		status::msg "No selection."
		return
	}
	regsub -all -nocase "<BR(\[ \t\r\n\]+\[^<>\]*>|>)" [getSelect] "" text
	if {$text != [getSelect]} {
		replaceText [getPos] [selEnd] $text
	}
}

#===============================================================================
# ×××× Insert Paragraphs ×××× #
#===============================================================================

# Insert <P> at empty lines in selection, and in the beginning of the selection.
# Several empty lines are contracted to one.
proc html::InsertParagraphs {} {
	global HTMLmodeVars
	if {![win::checkIfWinToEdit]} {return}
	if {![isSelection]} {
		beep
		status::msg "No selection."
		return
	}
	set pIsContainer [html::UseOptionalClosingTag P]
	html::indentCR P
	if {[set oelem [html::OpenElem P "" 0]] == ""} {return}
	set pind ""
	if {[lcontains HTMLmodeVars(indentElements) P]} {set pind "\t"}
	set text "\r$oelem"
	if {$crAftP} {append text "\r"}
	set prevLineEmpty 1
	
	foreach ln [split [string trimright [string trimleft [getSelect] "\r\n"]] "\r\n"] {
		regexp {[ \t]*} $ln lntest
		# Only add <P> if previous line was not empty.
		if {$ln == $lntest && !$prevLineEmpty} {
			set prevLineEmpty 1
			if {$pIsContainer} {
				append text [html::CloseElem P]
				if {${blAft/P} || ${crAft/P}} {append text "\r"}
				if {${blAft/P}} {append text "\r"}
				append text $oelem
				if {$crAftP} {append text "\r"}
			} else {
				append text $oelem
				if {$crAftP} {append text "\r"}
			}
		} else {
			# Skip an empty line which follows another empty line.
			if {$ln != $lntest} {
				set prevLineEmpty 0
				append text "$pind[string trim $ln]\r"
			}
		}
	}
	if {$pIsContainer} {
		append text [html::CloseElem P]
		if {${blAft/P}} {
			append text	[html::CloseCR2 [selEnd]]
		} elseif {${crAft/P}} {append text	[html::CloseCR [selEnd]]}
	}
	deleteText [getPos] [selEnd]
	HTML::indentLine
	if {[pos::compare [set p [text::firstNonWsLinePos [getPos]]] > [getPos]]} {goto $p}
	elec::Insertion $text
}

#===============================================================================
# ×××× Make list ×××× #
#===============================================================================

# Make list items from selection.
proc html::MakeList {} {
	global HTMLmodeVars html::HideDeprecated
	if {![win::checkIfWinToEdit]} {return}
	
	set isContainer [html::UseOptionalClosingTag LI]
	
	if {![isSelection]} {
		beep
		status::msg "No selection."
		return
	}
	if {${html::HideDeprecated} || $HTMLmodeVars(hideDeprecated)} {
		set men {UL UL OL None}
	} else {
		set men {UL UL OL DIR MENU None}
	}

	set box [dialog::title "Make list" 220]
	lappend box -t "Each item begins with:" 10 20 160 35 \
	  -e "*" 170 20 200 35 \
	  -t "List:" 10 45 50 65 -m $men 55 45 200 65 \
	  -b OK 140 80 205 100 -b Cancel 55 80 120 100
	set values [eval [concat dialog -w 220 -h 110 $box]]
	
	if {[lindex $values 3]} {return}
	set itemStr [string trim [lindex $values 0]]
	set listtype [lindex $values 1]
	set indentContent [lcontains HTMLmodeVars(indentElements) $listtype]
	set indentLI [lcontains HTMLmodeVars(indentElements) LI]
	if {$listtype != "None"} {html::indentCR $listtype}
	html::indentCR LI
	
	if {![string length $itemStr]} {
		beep
		status::msg "You must give a string which each item begins with."
		return
	}
	set startPos [getPos]
	set endPos [selEnd]
	if {[catch {search -s -f 1 -i 0 -r 0 -m 0 -- $itemStr $startPos} res] || \
	  [pos::compare [lindex $res 1] > $endPos]} {
		beep 
		status::msg "No list item in selection."
		return
	}
	# Check that the selections begins with a list item.
	set preText [getText $startPos [lindex $res 0]]
	if {![is::Whitespace $preText]} {
		beep
		status::msg "There is some text before the first list item."
		return
	}
	set indent ""
	set curr ""
	set text ""
	set cr [expr {2 - [string length [html::OpenCR 1]]}]
	if {$listtype != "None"} {
		html::crBefore [set blBef$listtype] [set crBef$listtype] text $indent cr curr [html::SetCase <$listtype>]
		html::crAfter [set blAft$listtype] [set crAft$listtype] text indent cr curr 0 $indentContent
	}
	
	# Get each list item.
	set startPos [lindex $res 1]
	while {![catch {search -s -f 1 -i 0 -r 0 -m 0 -- $itemStr $startPos} res2] && \
	  [pos::compare [lindex $res2 1] <= $endPos]} {
		html::crBefore $blBefLI $crBefLI text $indent cr curr [html::SetCase <LI>]
		html::crAfter $blAftLI $crAftLI text indent cr curr 0 $indentLI
		append curr [html::prepareForBreaking [string trim [getText $startPos [lindex $res2 0]]]]
		if {$isContainer} {
			html::crBefore ${blBef/LI} ${crBef/LI} text $indent cr curr [html::CloseElem LI]
			html::crAfter ${blAft/LI} ${crAft/LI} text indent cr curr 1 $indentLI
		}
		set startPos [lindex $res2 1]
	}
	html::crBefore $blBefLI $crBefLI text $indent cr curr [html::SetCase <LI>]
	html::crAfter $blAftLI $crAftLI text indent cr curr 0 $indentLI
	append curr [html::prepareForBreaking [string trim [getText $startPos $endPos]]]
	if {$isContainer} {
		html::crBefore ${blBef/LI} ${crBef/LI} text $indent cr curr [html::CloseElem LI]
	}
	if {$listtype != "None"} {
		if {$isContainer} {html::crAfter ${blAft/LI} ${crAft/LI} text indent cr curr 1 $indentLI}
		html::crBefore [set blBef/$listtype] [set crBef/$listtype] text $indent cr curr [html::CloseElem $listtype]
		append text [html::BreakIntoLines $curr $indent]
		if {[set crAft/$listtype]} {append text [html::CloseCR [selEnd]]}
		if {[set blAft/$listtype]} {append text [html::CloseCR2 [selEnd]]}
	} else {
		append text [html::BreakIntoLines $curr $indent]
		if {$isContainer} {
			if {[set crAft/LI]} {append text [html::CloseCR [selEnd]]}
			if {[set blAft/LI]} {append text [html::CloseCR2 [selEnd]]}
		} else {
			append text [html::CloseCR [selEnd]]
		}
	}
	deleteText [getPos] [selEnd]
	HTML::indentLine
	if {[pos::compare [set p [text::firstNonWsLinePos [getPos]]] > [getPos]]} {goto $p}
	elec::Insertion $text
}

#===============================================================================
# ×××× Building lists ×××× #
#===============================================================================

# Ask for input how to build a list. Returns "number of items" and
# "ask for list item attributes". Returns "" if canceled or any problem.
proc html::ListQuestions {ltype liattr lipr} {
	global HTMLmodeVars
	
	set promptNoisily $HTMLmodeVars(promptNoisily)
	if {[string length $liattr]} {
		set usedatts [html::GetUsed $liattr]
	} else {
		set usedatts [html::GetUsed LI]
	}
	if {$lipr != "LI"} { 
		eval lappend usedatts [html::GetUsed DD]
	}
	if {$HTMLmodeVars(useBigWindows)} {
		set it {0 0 3 0}
		while {1} {
			set txt [dialog::title "$ltype list" 280]
			append txt " -b OK 200 80 265 100 \
			  -b Cancel 115 80 180 100 \
			  -t {Number of items:} 10 20 130 40 \
			  -e [list [lindex $it 2]] 140 20 160 35"
			if {[llength $usedatts]} {
				append txt " -c {Ask for attributes for each $lipr} [lindex $it 3] \
				10 50 330 65"
			}
			set it [eval [concat dialog -w 280 -h 110 $txt]]
			if {[lindex $it 1]} {return}
			set items [lindex $it 2]
			if {[llength $it] == 4 && [lindex $it 3]} {
				set askForLiAttr 1
			} else {
				set askForLiAttr 0
			}
			
			if {![is::UnsignedInteger $items] && $ltype != "DL"} {
				alertnote "Invalid input: non-negative integer required"
			} elseif {![is::PositiveInteger $items] && $ltype == "DL"} {
				alertnote "Invalid input: positive integer required"
			} else {
				break
			}
		}
	} else {
		if {$promptNoisily} {beep}	
		global html::StatusNumRegexp
		set html::StatusNumRegexp {^[0-9]*$}
		while {[catch {html::StatusPrompt "" "$ltype list: How many items? " html::NumberStatusFunc} items]} {
			if {$items == "Cancel all!"} {status::msg "Cancel"; return}
		}
		if {![is::UnsignedInteger $items] && $ltype != "DL"} {
			beep; status::msg "Invalid input: non-negative integer required."; return
		} elseif {![is::PositiveInteger $items] && $ltype == "DL"} {
			beep; status::msg "Invalid input: positive integer required."; return
		}
		if {[llength $usedatts] && $items} {
			if {$promptNoisily} {beep}	
			while {[catch {html::StatusPrompt "" "Ask for attributes for each $lipr? \[n\] " \
			html::StatusAskYesOrNo} v]} {
				if {$v == "Cancel all!"} {status::msg "Cancel"; return}
			}
			if {$v == "yes"} {
				set askForLiAttr 1
			} else {
				set askForLiAttr 0
			}
		} else {
			set askForLiAttr 0
		}
	}
	return [list $items $askForLiAttr]
}
	

# Lists: Puts <cr>s before and after a list, inserts <li>, leaves the
# insertion point there.  If anything is selected, makes it the first item.
proc html::BuildList {ltype {liattr ""} {listattr ""}} {
	global HTMLmodeVars htmlCurSel htmlIsSel html::ElemLayout

	if {![win::checkIfWinToEdit]} {return}
	if {[html::IsInContainer STYLE]} {
		replaceText [getPos] [selEnd] $ltype
		return
	}
	
	set useTabMarks $HTMLmodeVars(useTabMarks)
	set containers [html::UseOptionalClosingTag LI]
	
	set listStr [html::ListQuestions $ltype $liattr LI]
	if {![llength $listStr]} {
		return
	} else {
		set items [lindex $listStr 0]
		set askForLiAttr [lindex $listStr 1]
	}

	# If zero list items, just make an html::Tag
	if {$items == 0} {
		html::Tag $ltype $listattr
		return
	}
	
	html::indentCR $ltype LI
	html::GetSel
	set sel $htmlCurSel
	if {[set text1 [html::OpenElem $ltype $listattr 0]] == ""} {return}
	if {[set html::ElemLayout($ltype)] != "nocr" && [is::Whitespace [getText [lineStart [getPos]] [getPos]]]
	&& [pos::compare [lineStart [getPos]] > [minPos]]} {goto [pos::math [lineStart [getPos]] - 1]}
	set indcont [lcontains HTMLmodeVars(indentElements) $ltype]
	set indLI [lcontains HTMLmodeVars(indentElements) LI]
	set IsSel $htmlIsSel
	set indent ""
	set curr ""
	set text ""
	set cr [expr {2 - [string length [html::OpenCR 1]]}]
	html::crBefore [set blBef$ltype] [set crBef$ltype] text $indent cr curr [html::prepareForBreaking $text1]
	html::crAfter [set blAft$ltype] [set crAft$ltype] text indent cr curr 0 $indcont
	for {set i 0} {$i < $items} {incr i} {
		if {$askForLiAttr} {
			set text1 [html::OpenElem LI $liattr 0]
		} else {
			set text1 [html::SetCase <LI>]
		}
		html::crBefore $blBefLI $crBefLI text $indent cr curr [html::prepareForBreaking $text1]
		html::crAfter $blAftLI $crAftLI text indent cr curr 0 $indLI
		if {$i == 0 && $IsSel} {	
			append curr [html::prepareForBreaking $sel]
		} elseif {$useTabMarks} {
			append curr "¥content¥"
		}
		if {$containers} {
			html::crBefore ${blBef/LI} ${crBef/LI} text $indent cr curr [html::CloseElem LI]
			html::crAfter ${blAft/LI} ${crAft/LI} text indent cr curr 1 $indLI
		}
	}
	html::crBefore [set blBef/$ltype] [set crBef/$ltype] text $indent cr curr [html::CloseElem $ltype]
	append text [html::BreakIntoLines $curr $indent]
	if {[set crAft/$ltype]} {append text [html::CloseCR]}
	if {[set blAft/$ltype]} {append text [html::CloseCR2 [selEnd]]}

	if {$useTabMarks} {append text "¥end¥"}
	if {$IsSel} { deleteSelection }
	html::elecInsertion text
}

proc html::ListItem {} {
	if {![win::checkIfWinToEdit]} {return}
	set tag LI
	html::FindList tag
	html::Tag LI $tag
}

# Definition Lists (term and description elems)
#
# The selection becomes the *description* (*not* the term)

# Build a discursive list
proc html::DefinitionList {} {
	global htmlCurSel htmlIsSel HTMLmodeVars html::ElemLayout
	
	if {![win::checkIfWinToEdit]} {return}
	if {[html::IsInContainer STYLE]} {
		replaceText [getPos] [selEnd] DL
		return
	}
	set containerDT [html::UseOptionalClosingTag DT]
	set containerDD [html::UseOptionalClosingTag DD]
	set indDL [lcontains HTMLmodeVars(indentElements) DL]
	set indDT [lcontains HTMLmodeVars(indentElements) DT]
	set indDD [lcontains HTMLmodeVars(indentElements) DT]
	html::indentCR DL DT DD
	set useTabMarks	$HTMLmodeVars(useTabMarks)
	
	set listStr [html::ListQuestions DL DT "DT and DD"]
	if {![llength $listStr]} {
		return
	} else {
		set dlEntries [lindex $listStr 0]
		set askForLiAttr [lindex $listStr 1]
	}
	
	if {[set text1 [html::OpenElem DL "" 0]] == ""} {return}
	html::GetSel
	set Sel $htmlCurSel
	if {[set html::ElemLayout(DL)] != "nocr" && [is::Whitespace [getText [lineStart [getPos]] [getPos]]]
	&& [pos::compare [lineStart [getPos]] > [minPos]]} {goto [pos::math [lineStart [getPos]] - 1]}
	set indent ""
	set curr ""
	set text ""
	set cr [expr {2 - [string length [html::OpenCR 1]]}]

	html::crBefore $blBefDL $crBefDL text $indent cr curr [html::prepareForBreaking $text1]
	html::crAfter $blAftDL $crAftDL text indent cr curr 0 $indDL

	for {set i 0} {$i < $dlEntries} {incr i} {
		if {$askForLiAttr} {
			set text1 [html::OpenElem DT "" 0]
		} else {
			set text1 [html::SetCase <DT>]
		}
		html::crBefore $blBefDT $crBefDT text $indent cr curr [html::prepareForBreaking $text1]
		html::crAfter $blAftDT $crAftDT text indent cr curr 0 $indDT
		if {$useTabMarks} {append curr "¥content¥"}
		if {$containerDT} {
			html::crBefore ${blBef/DT} ${crBef/DT} text $indent cr curr [html::CloseElem DT]
			html::crAfter ${blAft/DT} ${crAft/DT} text indent cr curr 1 $indDT
		}
		if {$askForLiAttr} {
			set text1 [html::OpenElem DD "" 0]
		} else {
			set text1 [html::SetCase <DD>]
		}
		html::crBefore $blBefDD $crBefDD text $indent cr curr [html::prepareForBreaking $text1]
		html::crAfter $blAftDD $crAftDD text indent cr curr 0 $indDD
		if {$i == 0 && $htmlIsSel} {
			append curr [html::prepareForBreaking $Sel]
		} elseif {$useTabMarks} {
			append curr "¥content¥"
		}
		if {$containerDD} {
			html::crBefore ${blBef/DD} ${crBef/DD} text $indent cr curr [html::CloseElem DD]
			html::crAfter ${blAft/DD} ${crAft/DD} text indent cr curr 1 $indDD
		}
	}
	
	html::crBefore ${blBef/DL} ${crBef/DL} text $indent cr curr [html::CloseElem DL]
	append text [html::BreakIntoLines $curr $indent]
	if {${crAft/DL}} {append text [html::CloseCR]}
	if {${blAft/DL}} {append text [html::CloseCR2 [selEnd]]}
	if {$useTabMarks} {append text "¥end¥"}
	if {$htmlIsSel} { deleteSelection }
	html::elecInsertion text
}

# Add an individual entry to a discursive list
proc html::DefinitionEntry {} {
	global htmlCurSel htmlIsSel HTMLmodeVars html::ElemLayout
 
	if {![win::checkIfWinToEdit]} {return}
	# Is in STYLE container?
	if {[html::IsInContainer STYLE]} {replaceText [getPos] [selEnd] DT; return}

	set useTabMarks	$HTMLmodeVars(useTabMarks)
	set containerDT [html::UseOptionalClosingTag DT]
	set containerDD [html::UseOptionalClosingTag DD]
	set indDT [lcontains HTMLmodeVars(indentElements) DT]
	set indDD [lcontains HTMLmodeVars(indentElements) DT]
	html::indentCR DT DD
	
	html::GetSel
	set Sel $htmlCurSel
	set indent ""
	set curr ""
	set text ""
	if {[set text1 [html::OpenElem DT "" 0]] == ""} {return}
	if {[set html::ElemLayout(DT)] != "nocr" && [is::Whitespace [getText [lineStart [getPos]] [getPos]]]
	&& [pos::compare [lineStart [getPos]] > [minPos]]} {goto [pos::math [lineStart [getPos]] - 1]}
	set cr [expr {2 - [string length [html::OpenCR 1]]}]

	html::crBefore $blBefDT $crBefDT text $indent cr curr [html::prepareForBreaking $text1]
	html::crAfter $blAftDT $crAftDT text indent cr curr 0 $indDT
	append curr "¥content¥"
	if {$containerDT} {
		html::crBefore ${blBef/DT} ${crBef/DT} text $indent cr curr [html::CloseElem DT]
		html::crAfter ${blAft/DT} ${crAft/DT} text indent cr curr 1 $indDT
	}
	if {[set text1 [html::OpenElem DD "" 0]] == ""} {return}
	html::crBefore $blBefDD $crBefDD text $indent cr curr [html::prepareForBreaking $text1]
	html::crAfter $blAftDD $crAftDD text indent cr curr 0 $indDD
	if {$htmlIsSel} {
		append curr [html::prepareForBreaking $Sel]
	} elseif {$useTabMarks} {
		append curr "¥content¥"
	}
	if {$containerDD} {
		html::crBefore ${blBef/DD} ${crBef/DD} text $indent cr curr [html::CloseElem DD]
		append text [html::BreakIntoLines $curr $indent]
		if {${crAft/DD}} {append text [html::CloseCR]}
		if {${blAft/DD}} {append text [html::CloseCR2 [selEnd]]}
		append text "¥end¥"
	} else {
		append text [html::BreakIntoLines $curr $indent] [html::CloseCR]
	}
	if {$htmlIsSel} { deleteSelection }
	html::elecInsertion text
}

#===============================================================================
# ×××× Tables ×××× #
#===============================================================================

# Table template. If there is any selection it is put in the first cell.
proc html::TableTemplate {} {
	global htmlCurSel htmlIsSel HTMLmodeVars html::ElemLayout
	
	if {![win::checkIfWinToEdit]} {return}

	set useTabMarks $HTMLmodeVars(useTabMarks)
	set containerTR [html::UseOptionalClosingTag TR]
	set containerTH [html::UseOptionalClosingTag TH]
	set containerTD [html::UseOptionalClosingTag TD]
	set indTABLE [lcontains HTMLmodeVars(indentElements) TABLE]
	set indTR [lcontains HTMLmodeVars(indentElements) TR]
	set indTD [lcontains HTMLmodeVars(indentElements) TD]
	set indTH [lcontains HTMLmodeVars(indentElements) TH]
	html::indentCR TABLE TR TH TD

	set values {"" "" 0 0 0}
	set rows ""
	set cols ""
	set tableOpen [html::SetCase <TABLE>]
	set trOpen [html::SetCase <TR>]
	while {1} {
		
		set box "[dialog::title {Table template} 230] \
		  -t {Number of rows:} 10 20 150 35 \
		  -e [list [lindex $values 0]] 160 20 180 35 \
		  -t {Number of columns:} 10 45 150 60 \
		  -e [list [lindex $values 1]] 160 45 180 60 \
		  -c {Table headers in first row} [lindex $values 2] 10 70 250 92 \
		  -c {Table headers in first column} [lindex $values 3] 10 92 250 114 \
		  -c {Don't insert TABLE tags} [lindex $values 4] 10 114 250 136 \
		  -b OK 150 230 215 250 \
		  -b Cancel 65 230 130 250 \
		  -b {TABLE attributesÉ} 10 150 150 170 \
		  -b {TR attributesÉ} 10 180 150 200 "
		
		set values [eval [concat dialog -w 230 -h 260 $box]]
		
		# Cancel?
		if {[lindex $values 6] } {return}
		
		set rows [lindex $values 0]
		set cols [lindex $values 1]
		set THrow [lindex $values 2]
		set THcol [lindex $values 3]
		set table [expr {![lindex $values 4]}]
		if {[lindex $values 7]} {
			if {!$table} {
				alertnote "You have chosen not to insert TABLE tags."
			} elseif {[set tmp [html::ChangeElement [string range $tableOpen 1 [expr {[string length $tableOpen] - 2}]] TABLE]] != ""} {
				set tableOpen $tmp
			}
			continue
		}
		if {[lindex $values 8]} {
			if {[set tmp [html::ChangeElement [string range $trOpen 1 [expr {[string length $trOpen] - 2}]] TR]] != ""} {
				set trOpen $tmp
			}
			continue
		}
		if {![is::PositiveInteger $rows] || ![is::PositiveInteger $cols] } {
			alertnote "The number of rows and columns must be positive."
		} else {
			break
		}
	}
	
	html::GetSel
	if {$htmlIsSel} {deleteSelection}
	set indent ""
	set curr ""
	set text ""
	if {$table} {set felem TABLE} else {set felem TR}
	if {[set html::ElemLayout($felem)] != "nocr" && [is::Whitespace [getText [lineStart [getPos]] [getPos]]]
	&& [pos::compare [lineStart [getPos]] > [minPos]]} {goto [pos::math [lineStart [getPos]] - 1]}
	set cr [expr {2 - [string length [html::OpenCR 1]]}]
	if {$table} {
		html::crBefore $blBefTABLE $crBefTABLE text $indent cr curr [html::prepareForBreaking $tableOpen]
		html::crAfter $blAftTABLE $crAftTABLE text indent cr curr 0 $indTABLE
	}
	
	for {set i 1} {$i <= $rows} {incr i} {
		html::crBefore $blBefTR $crBefTR text $indent cr curr $trOpen
		html::crAfter $blAftTR $crAftTR text indent cr curr 0 $indTR
		for {set j 1} {$j <= $cols} {incr j} {
			# Put TH in first row or column?
			if {$i == 1 && $THrow || $j == 1 && $THcol} {
				set cell TH
			} else {
				set cell TD
			}
			html::crBefore [set blBef$cell] [set crBef$cell] text $indent cr curr [html::SetCase <$cell>]
			html::crAfter [set blAft$cell] [set crAft$cell] text indent cr curr 0 [set ind$cell]
			if {$i == 1 && $j == 1 && $htmlIsSel} {
				append curr [html::prepareForBreaking $htmlCurSel]
			} elseif {$useTabMarks} {
				append curr "¥content¥"
			}
			if {[set container$cell]} {
				html::crBefore [set blBef/$cell] [set crBef/$cell] text $indent cr curr [html::CloseElem $cell]
				if {$i == $rows && $j == $cols && !$containerTR && !$table} {
					append text [html::BreakIntoLines $curr $indent]
					if {[set crAft/$cell]} {append text [html::CloseCR]}
					if {[set blAft/$cell]} {append text [html::CloseCR2 [selEnd]]}
				} else {
					html::crAfter [set blAft/$cell] [set crAft/$cell] text indent cr curr 1 [set ind$cell]
				}					
			}
		}
		if {$containerTR} {
			html::crBefore ${blBef/TR} ${crBef/TR} text $indent cr curr [html::CloseElem TR]
			if {$i < $rows || $table} {
				html::crAfter ${blAft/TR} ${crAft/TR} text indent cr curr 1 $indTR
			} else {
				append text [html::BreakIntoLines $curr $indent]
				if {${crAft/TR}} {append text [html::CloseCR]}
				if {${blAft/TR}} {append text [html::CloseCR2 [selEnd]]}
			}
		}
	}
	if {$table} {
		html::crBefore ${blBef/TABLE} ${crBef/TABLE} text $indent cr curr [html::CloseElem TABLE]
		append text [html::BreakIntoLines $curr $indent]
		if {${crAft/TABLE}} {append text [html::CloseCR]}
		if {${blAft/TABLE}} {append text [html::CloseCR2 [selEnd]]}
	}
	if {$useTabMarks && ($rows > 1 || $cols > 1 || !$htmlIsSel)} {append text "¥end¥"}
	html::elecInsertion text
}


# Take table rows in a selection and remove the TR, TD and TH elements and
# put tabs between the elements.
proc html::RowstoTabs {} {
	if {![win::checkIfWinToEdit]} {return}

	if {![isSelection]} {
		beep
		status::msg "No selection."
		return
	}
	
	set startPos [getPos]
	set endPos [selEnd]
	if {[catch {search -s -f 1 -i 1 -r 1 -m 0 {<TR([ \t\r\n]+[^>]*>|>)} $startPos} res] || \
	  [pos::compare [lindex $res 1] > $endPos]} {
		beep 
		status::msg "No table row in selection."
		return
	}
	# Check that the selections begins with a table row.
	set preText [getText $startPos [lindex $res 0]]
	if {![is::Whitespace $preText]} {
		beep
		status::msg "First part of selection is not in a table row."
		return
	}
	# Extract each table row.
	set startPos [lindex $res 1]
	while {![catch {search -s -f 1 -i 1 -r 1 -m 0 {<TR([ \t\r\n]+[^>]*>|>)} $startPos} res2] && \
	  [pos::compare [lindex $res2 1] <= $endPos]} {
		set text2 [getText $startPos [lindex $res2 0]]
		regsub -all "\[\t\r\n\]+" $text2 " " text2
		append text [string trim $text2] "\r"
		set startPos [lindex $res2 1]
	}
	set text2 [getText $startPos $endPos]
	regsub -all "\[\t\r\n\]+" $text2 " " text2
	append text [string trim $text2]
	
	# Check that there is nothing after the last table row.
	if {![catch {search -s -f 1 -i 1 -r 1 -m 0 {</TR>} $startPos} res] \
	  && [pos::compare [lindex $res 1] <= $endPos]} {
		set preText [getText [lindex $res 1] $endPos]
		if {![is::Whitespace $preText]} {
			beep
			status::msg "Last part of selection not in a table row."
			return
		}
	}
	# Make the transformation.
	foreach ln [split $text "\r"] {
		if {![string length $ln]} continue
		regsub -all {> +<} $ln "><" ln
		regsub -all {<(t|T)(h|H|d|D)([ ]+[^>]*>|>)} $ln "\t" ln
		regsub {	} $ln "" ln
		regsub -all {</(t|T)(h|H|d|D|r|R)>} $ln "" ln
		append out "$ln\r"
	}
	replaceText [getPos] [selEnd] $out
}

# Convert tab-delimited format to table rows.
# First row and first coloumn can optionally consist of table headers.
proc html::ImportTable {} {html::TabstoRows file}

proc html::TabstoRows {{where selection}} {
	global HTMLmodeVars
	if {![win::checkIfWinToEdit]} {return}
	
	set containerTR [html::UseOptionalClosingTag TR]
	set containerTH [html::UseOptionalClosingTag TH]
	set containerTD [html::UseOptionalClosingTag TD]
	set indTABLE [lcontains HTMLmodeVars(indentElements) TABLE]
	set indTR [lcontains HTMLmodeVars(indentElements) TR]
	set indTD [lcontains HTMLmodeVars(indentElements) TD]
	set indTH [lcontains HTMLmodeVars(indentElements) TH]
	html::indentCR TABLE TR TH TD

	if {$where == "selection"} {
		if {![isSelection]} {
			beep
			status::msg "No selection."
			return
		}
		set tabtext [string trim [getSelect] " \r\n"]
		set htext "Tabs to Rows"
	} else {
		set fil [getfile "Select file with table."]
		if {![html::IsTextFile $fil alertnote]} {return}
		set fid [open $fil r]
		set tabtext [string trim [read $fid] " \r\n"]
		close $fid
		regsub -all "\n\r" $tabtext "\n" tabtext
		set htext "Import table"
	}
	set values {0 0 0 0}
	set tableOpen [html::SetCase <TABLE>]
	set trOpen [html::SetCase <TR>]
	while {1} {
		
		set box "[dialog::title $htext 230] \
		  -c {Table headers in first row} [lindex $values 0] 10 20 250 42 \
		  -c {Table headers in first column} [lindex $values 1] 10 42 250 64 \
		  -c {Don't insert TABLE tags} [lindex $values 2] 10 64 250 86 \
		  -c {Treat multiple tabs as one} [lindex $values 3] 10 86 250 108 \
		  -b OK 150 200 215 220 -b Cancel 65 200 130 220 \
		  -b {TABLE attributesÉ} 10 120 150 140 \
		  -b {TR attributesÉ} 10 150 150 170"
		
		set values [eval [concat dialog -w 230 -h 230 $box]]
		
		# Cancel?
		if {[lindex $values 5] } {return}
		
		set THrow [lindex $values 0]
		set THcol [lindex $values 1]
		set table [expr {![lindex $values 2]}]
		if {[lindex $values 3]} {
			set tabexp "\t+"
		} else {
			set tabexp \t
		}
		if {[lindex $values 6]} {
			if {!$table} {
				alertnote "You have chosen not to insert TABLE tags."
			} elseif {[set tmp [html::ChangeElement [string range $tableOpen 1 [expr {[string length $tableOpen] - 2}]] TABLE]] != ""} {
				set tableOpen $tmp
			}
			continue
		}
		if {[lindex $values 7]} {
			if {[set tmp [html::ChangeElement [string range $trOpen 1 [expr {[string length $trOpen] - 2}]] TR]] != ""} {
				set trOpen $tmp
			}
			continue
		}
		break
	}
				
	set indent ""
	set curr ""
	set text ""
	set cr [expr {2 - [string length [html::OpenCR 1]]}]
	if {$table} {
		html::crBefore $blBefTABLE $crBefTABLE text $indent cr curr [html::prepareForBreaking $tableOpen]
		html::crAfter $blAftTABLE $crAftTABLE text indent cr curr 0 $indTABLE
	}

	set lines [split $tabtext "\r\n"]
	set i 1
	foreach ln $lines {
		if {![string length $ln]} {
			incr i
			continue
		} else {
			html::crBefore $blBefTR $crBefTR text $indent cr curr [html::prepareForBreaking $trOpen]
			html::crAfter $blAftTR $crAftTR text indent cr curr 0 $indTR
			# Should there be headers in the first row?
			if {$i == 1 && $THrow} {
				set cell TH
			} else {
				set cell TD
			}
			# Should there be headers in the first column?
			if {$THcol || ($i == 1 && $THrow)} {
				set fcell TH
			} else {
				set fcell TD
			}
			set tabs 0
			html::crBefore [set blBef$fcell] [set crBef$fcell] text $indent cr curr [html::SetCase <$fcell>]
			html::crAfter [set blAft$fcell] [set crAft$fcell] text indent cr curr 0 [set ind$fcell]
			while {[regexp -indices $tabexp $ln t]} {
				append curr [html::prepareForBreaking [string range $ln 0 [expr {[lindex $t 0] - 1}]]]
				if {$tabs} {
					set lcell $cell
				} else {
					set lcell $fcell
				}
				if {[set container$lcell]} {
					html::crBefore [set blBef/$lcell] [set crBef/$lcell] text $indent cr curr [html::CloseElem $lcell]
					html::crAfter [set blAft/$lcell] [set crAft/$lcell] text indent cr curr 1 [set ind$lcell]
				}
				html::crBefore [set blBef$cell] [set crBef$cell] text $indent cr curr [html::SetCase <$cell>]
				html::crAfter [set blAft$cell] [set crAft$cell] text indent cr curr 0 [set ind$cell]
				set ln [string range $ln [expr {[lindex $t 1] + 1}] end]
				incr tabs
			}
			append curr [html::prepareForBreaking $ln]
			# Add cell or fcell closing, depending on if there is more than one cell.
			if {$tabs} {
				set lcell $cell
			} else {
				set lcell $fcell
			}
			if {[set container$lcell]} {
				html::crBefore [set blBef/$lcell] [set crBef/$lcell] text $indent cr curr [html::CloseElem $lcell]
				if {$i == [llength $lines] && !$containerTR && !$table} {
					append text [html::BreakIntoLines $curr $indent]
					if {[set crAft/$lcell]} {append text [html::CloseCR]}
					if {[set blAft/$lcell]} {append text [html::CloseCR2 [selEnd]]}
				} else {
					html::crAfter [set blAft/$lcell] [set crAft/$lcell] text indent cr curr 1 [set ind$lcell]
				}					
			}
			if {$containerTR} {
				html::crBefore ${blBef/TR} ${crBef/TR} text $indent cr curr [html::CloseElem TR]
				if {$i < [llength $lines] || $table} {
					html::crAfter ${blAft/TR} ${crAft/TR} text indent cr curr 1 $indTR
				} else {
					append text [html::BreakIntoLines $curr $indent]
					if {${crAft/TR}} {append text [html::CloseCR]}
					if {${blAft/TR}} {append text [html::CloseCR2 [selEnd]]}
				}
			}
		}
		incr i
	}
	if {$table} {
		html::crBefore ${blBef/TABLE} ${crBef/TABLE} text $indent cr curr [html::CloseElem TABLE]
		append text [html::BreakIntoLines $curr $indent]
		if {${crAft/TABLE}} {append text [html::CloseCR]}
		if {${blAft/TABLE}} {append text [html::CloseCR2 [selEnd]]}
	}
	if {$where == "selection"} {
		deleteText [getPos] [selEnd]
		HTML::indentLine
		if {[pos::compare [set p [text::firstNonWsLinePos [getPos]]] > [getPos]]} {goto $p}
		elec::Insertion $text
	} else {
		html::elecInsertion text
	}
}

#===============================================================================
# ×××× Image maps ×××× #
#===============================================================================

# Converts an NCSA or CERN image map file to a client side image map.
proc html::ConvertNCSAMap {} {html::ConvertMap NCSA}
proc html::ConvertCERNMap {} {html::ConvertMap CERN}

proc html::ConvertMap {type} {
	global HTMLmodeVars
	
	if {![win::checkIfWinToEdit]} {return}
	if {[catch {getfile "Select the $type image map file."} fil] || ![html::IsTextFile $fil alertnote] ||
	[catch {open $fil r} fid]} {return}
	set filecont [read $fid]
	close $fid
	if {[regexp {\n} $filecont]} {
		set newln "\n"
	} else {
		set newln "\r"
	}
	if {![string length [set map [html::OpenElem MAP "" 0]]]} {return}
	html::indentCR MAP AREA
	set aind ""
	if {[lcontains HTMLmodeVars(indentElements) MAP]} {set aind "\t"}
	set indent ""
	set curr ""
	set out ""
	set cr [expr {2 - [string length [html::OpenCR 1]]}]
	html::crBefore $blBefMAP $crBefMAP out $indent cr curr [html::prepareForBreaking $map]
	html::crAfter $blAftMAP $crAftMAP out indent cr curr 0 [lcontains HTMLmodeVars(indentElements) MAP]
	html::${type}map [split $filecont $newln] notknown invalid out curr cr $aind
	if {$invalid} {
		if {[askyesno "Some lines in [file tail $fil] have invalid syntax. They are ignored. Continue?"] == "no"} {return}
	} elseif {$notknown} {
		if {[askyesno "Some lines in [file tail $fil] specify a shape not supported. They are ignored. Continue?"] == "no"} {return}
	}
	html::crBefore ${blBef/MAP} ${crBef/MAP} out $indent cr curr [html::CloseElem MAP]
	append out [html::BreakIntoLines $curr $indent]
	if {${crAft/MAP}} {append out [html::CloseCR]}
	if {${blAft/MAP}} {append out [html::CloseCR2 [getPos]]}
	html::elecInsertion out
}

proc html::NCSAmap {lines nknw sinv ar crr c indent} {
	upvar $nknw notknown $sinv someinvalid $ar area $crr curr $c cr
	set notknown 0
	set someinvalid 0
	set defarea ""
	html::indentCR AREA
	foreach l $lines {
		set invalid 0
		set l [string trim $l]
		# Skip comments and blank lines
		if {[regexp {^#} $l] || ![string length $l]} {continue}
		set shape [string toupper [lindex $l 0]]
		if {[lsearch {RECT CIRCLE POLY DEFAULT} $shape] < 0} {
			set notknown 1
			continue
		}
		set url [lindex $l 1]
		set exp "^\[0-9\]+,\[0-9\]+$"
		if {[regexp $exp $url]} {
			set url ""
			set cind 1
		} else {
			set cind 2
		}
		switch $shape {
			RECT {
				if {[regexp $exp [lindex $l $cind]] && [regexp $exp [lindex $l [expr {$cind + 1}]]]} {
					set coord "[lindex $l $cind],[lindex $l [expr {$cind + 1}]]"
				} else {
					set invalid 1
				}
			}
			CIRCLE {
				if {[regexp $exp [lindex $l $cind] cent] && [regexp $exp [lindex $l [expr {$cind + 1}]] edge]} {
					regexp {[0-9]+} $cent xc
					regexp {[0-9]+} $edge xe
					set coord "$cent,[expr {$xe-$xc}]"
				} else {
					set invalid 1
				}
			}
			POLY {
				set coord ""
				foreach c [lrange $l $cind end] {
					if {![regexp $exp $c]} {
						set invalid 1
						break
					}
					append coord "$c,"
				}
				set coord [string trimright $coord ,]
			}
		}
		if {!$invalid} {
			set tmp "<[html::SetCase "AREA SHAPE=\"$shape\""]"
			if {$shape != "DEFAULT"} {
				append tmp " [html::SetCase COORDS]=\"$coord\""
			}
			if {[string length $url]} {
				append tmp " [html::SetCase HREF]=\"$url\""
			} else {
				append tmp " [html::SetCase NOHREF]"
			}
			append tmp ">"
			if {$shape != "DEFAULT"} {
				html::crBefore $blBefAREA $crBefAREA area $indent cr curr $tmp
				html::crAfter $blAftAREA $crAftAREA area indent cr curr 0 0
			} else {
				set defarea $tmp
			}
		} else {
			set someinvalid 1
		}
	}
	if {$defarea != ""} {
		html::crBefore $blBefAREA $crBefAREA area $indent cr curr $defarea
		html::crAfter $blAftAREA $crAftAREA area indent cr curr 0 0
	}
}

proc html::CERNmap {lines nknw sinv ar crr c indent} {
	upvar $nknw notknown $sinv someinvalid $ar area $crr curr $c cr
	set notknown 0
	set someinvalid 0
	set defarea ""
	html::indentCR AREA
	foreach l $lines {
		set invalid 0
		set l [string trim $l]
		# Skip comments and blank lines
		if {[regexp {^#} $l] || ![string length $l]} {continue}
		set shape [string toupper [lindex $l 0]]
		if {![string match RECT* $shape] && ![string match CIRC* $shape] &&
		![string match POLY* $shape] && ![string match DEFAULT $shape]} {
			set notknown 1
			continue
		}
		set exp "^\\(\[0-9\]+,\[0-9\]+\\)$"
		switch -glob $shape {
			RECT* {
				set url [lindex $l 3]
				if {[regexp $exp [lindex $l 1]] && [regexp $exp [lindex $l 2]]} {
					set coord "[string trimleft [string trimright [lindex $l 1] )] (],[string trimleft [string trimright [lindex $l 2] )] (]"
					set shape RECT
				} else {
					set invalid 1
				}
			}
			CIRC* {
				set url [lindex $l 3]
				if {[regexp $exp [lindex $l 1]] && [regexp {^[0-9]+$} [lindex $l 2]]} {
					set coord "[string trimleft [string trimright [lindex $l 1] )] (],[lindex $l 2]"
					set shape CIRCLE
				} else {
					set invalid 1
				}
			}
			POLY* {
				set coord ""
				set url [lindex $l [expr {[llength $l] - 1}]]
				if {[regexp $exp $url]} {
					set url ""
					set cind 1
				} else {
					set cind 2
				}
				foreach c [lrange $l 1 [expr {[llength $l] - $cind}]] {
					if {![regexp $exp $c]} {
						set invalid 1
						break
					}
					append coord "[string trimleft [string trimright $c )] (],"
				}
				set coord [string trimright $coord ,]
				set shape POLY
			}
			DEFAULT {
				set url [lindex $l 1]
			}
		}
		if {!$invalid} {
			set tmp "<[html::SetCase "AREA SHAPE=\"$shape\""]"
			if {$shape != "DEFAULT"} {
				append tmp " [html::SetCase COORDS]=\"$coord\""
			}
			if {[string length $url]} {
				append tmp " [html::SetCase HREF]=\"$url\""
			} else {
				append tmp " [html::SetCase NOHREF]"
			}
			append tmp ">"
			if {$shape != "DEFAULT"} {
				html::crBefore $blBefAREA $crBefAREA area $indent cr curr $tmp
				html::crAfter $blAftAREA $crAftAREA area indent cr curr 0 0
			} else {
				set defarea $tmp
			}
		} else {
			set someinvalid 1
		}
	}
	if {$defarea != ""} {
		html::crBefore $blBefAREA $crBefAREA area $indent cr curr $defarea
		html::crAfter $blAftAREA $crAftAREA area indent cr curr 0 0
	}
}

#===============================================================================
# ×××× Comments ×××× #
#===============================================================================

proc html::Comment {} {
	global htmlCurSel htmlIsSel HTMLmodeVars
	if {![win::checkIfWinToEdit]} {return}
	set comStrs [html::CommentStrings]
	html::GetSel
	if {$htmlIsSel} { 
		deleteSelection 
		set text2 $htmlCurSel
	} else {
		append text2 "¥comment¥"
	}
	if {[lindex $comStrs 0] == "/* "} {
		elec::Insertion [lindex $comStrs 0] $text2 [lindex $comStrs 1]
		return
	}
	if {[is::Whitespace [getText [lineStart [getPos]] [getPos]]]
	&& [pos::compare [lineStart [getPos]] > [minPos]]} {goto [pos::math [lineStart [getPos]] - 1]}
	set text "[html::OpenCR][lindex $comStrs 0]$text2"
	append text [lindex $comStrs 1] [html::CloseCR]
	if {!$htmlIsSel && $HTMLmodeVars(useTabMarks)} {append text "¥end¥"}
	html::elecInsertion text
}

#
# dividing line
#
proc html::CommentLine {} {
	global HTMLmodeVars fillColumn
	if {![win::checkIfWinToEdit]} {return}
	set lineWrap $HTMLmodeVars(lineWrap)
	set comStr	[html::CommentStrings]
	set prefixString [lindex $comStr 0]
	set suffixString [lindex $comStr 1]
	set s "===================================================================================="
	set l [expr {[string length $prefixString] + [string length $suffixString]}]
	if {$lineWrap} { 
		set l [expr {$fillColumn - $l - 1}] 
	} else {
		set l [expr {75 - $l - 1}]
	}
	elec::Insertion [html::OpenCR] $prefixString [string range $s 0 $l] $suffixString "\r"
}


