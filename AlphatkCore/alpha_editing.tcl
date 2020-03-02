## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_editing.tcl"
 #                                    created: 04/12/98 {23:17:46 PM} 
 #  Author: Vince Darley
 #  E-mail: vince.darley@kagi.com
 #    mail: Flat 10, 98 Gloucester Terrace, London W2 6HP
 #     www: http://www.purl.org/net/alphatk
 #  
 # Copyright (c) 1998-2005  Vince Darley
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # In particular, while this is 'open source', it is NOT free, and
 # cannot be copied in full or in part except according to the terms
 # of the license agreement.
 # 
 # ###################################################################
 ##

#¥ search  [optionsÉ] <pattern> <pos> - 
#  -f <num>		- go forward?
#  -r <num>		- regular expression?
#  -s			- save previous search string and search flags.
#  -i <num>		- ignore case?
#  -m <num>		- match words?
#  -n			- failed search still returns TCL_OK, but null string.
#  -l <limit>	- limit on how search goes.
#  --	 		- next arg is the pattern.
#
#  Searches for 'pattern' from position 'pos'.  If the search succeeds, a 
#  list of two positions will be returned.  The first is the starting position 
#  of the match, the second is one past the last character. If no '-n', 
#  TCL_ERROR returned.
proc search {args} {
    array set opts {-r 0 -f 1 -m 0 -i 1}
    getOpts {-r -f -m -i -l -w}
    if {[llength $args] != 2} {
	return -code error "Wrong number of args. Should\
	  be \"search ?options? pattern pos\""
    }
    set switches ""
    set pattern [lindex $args 0]
    if {$opts(-r)} {
	lappend switches "-nolinestop"
	lappend switches "-regexp"
	# this isn't ideal but is better than nothing!
	if {$opts(-m)} {
	    set pattern "\\m${pattern}\\M"
	}
    } else {
	if {$opts(-m)} {
	    lappend switches "-regexp"
	    set pattern "\\m[quote::Regfind ${pattern}]\\M"
	}
    }
    #echo "search $pattern"
    if {[info exists opts(-l)]} {
	set limit "$opts(-l)"
    } else {
	if {$opts(-f)} {
	    set limit end
	} else { 
	    set limit 1.0 
	}
    }
    
    if {$opts(-i)} {lappend switches "-nocase"}
    if {[info exists opts(-all)]} {lappend switches "-all"}
    global win::tk
    if {[info exists opts(-w)]} {
	if {![info exists win::tk($opts(-w))]} {
	    set opts(-w) [winTailToFullName $opts(-w)]
	}
	set w $win::tk($opts(-w))
    } else {
	set w $win::tk([win::Current])
    }
    if {$opts(-f)} {
	set from [lindex $args 1]
	lappend switches "-forwards"
    } else {
	lappend switches "-backwards"
	set from "[lindex $args 1] +1c"
    }
    set found [eval [list $w search] $switches \
      [list -count count -- $pattern $from $limit]]
    if {[llength $found]} {
	foreach f $found c $count {
	    lappend res $f [$w index "$f + ${c}c"]
	}
	return $res
    } else {
	if {[info exists opts(-n)]} {
	    return ""
	} else {
	    error "not found"
	}
    }
}
# should be ".text search ?switches? pattern index ?stopIndex?
# must be -forward, -backward, -exact, -regexp, -nocase, -count, or --

proc fold {args} {
    win::parseArgs w action args
    eval [list text_wcmd $w fold $action] $args
}

# ×××× The mark (pin?) ×××× #

#¥ exchangePointAndPin - exchange the current 'mark' 
#  w/ the current insertion point
proc exchangePointAndPin {args} {
    win::parseArgs w
    set pos [getPin -w $w]
    setPin -w $w
    goto -w $w $pos
    status::msg "Point and pin exchanged"
}
#¥ getPin - return the current mark.
proc getPin {args} {
    win::parseArgs w
    if {[catch {text_wcmd $w index thePin} result]} {
	# No mark set manually, so use the [minPos]
	set result [minPos -w $w]
    }
    return $result
}
#¥ hiliteToPin - This is the 'Hilite' from the 'Edit'
#  menu. If there is a currently hilited selection, the 
#  selection is unhilited, leaving the mark and the 
#  insertion point around the old selection. If there 
#  is not a selection, the region between the insertion 
#  point and the mark is selected.
proc hiliteToPin {args} {
    win::parseArgs w
    if {[isSelection -w $w]} {
	set pos0 [getPos -w $w]
	set pos1 [selEnd -w $w]
	goto -w $w $pos1 ; setPin -w $w
	goto -w $w $pos0
    } else {
	selectText -w $w [getPos -w $w] [getPin -w $w]
    }
}
#¥ setPin - set the current mark to the insertion point
proc setPin {args} {
    win::parseArgs w {pos ""}
    if {$pos == ""} { set pos [getPos -w $w] }
    text_wcmds $w [list mark set thePin $pos] [list mark gravity thePin left]
    status::msg "Pin set"
}

# ×××× Basic editing ×××× #
#¥ backSpace - delete selection, or a single char if no selection.
proc backSpace {args} {
    win::parseArgs w
    set sel [selectSegments -w $w]
    if {[llength $sel]} {
	foreach {from to} $sel {
	    text_wcmd $w delete $from $to
	}
    } else {
	if {[text_wcmd $w compare insert != 1.0]} {
	    text_wcmd $w delete_key "insert -1c"
	}
    }
}
#¥ deleteChar - delete selection, or single char AFTER cursor if no selection
proc deleteChar {args} {
    win::parseArgs w
    set sel [selectSegments -w $w]
    if {[llength $sel]} {
	foreach {from to} $sel {
	    text_wcmd $w delete $from $to
	}
    } else {
	text_wcmd $w delete_key "insert"
    }
}
#¥ backwardChar - moves insertion one char back
proc backwardChar {args} {
    win::parseArgs w
    if {[isSelection -w $w]} {
	goto -w $w [getPos -w $w]
    } else {
	goto -w $w [pos::math -w $w [getPos -w $w] -1]
    }
}
#¥ backwardCharSelect - extends selection one char back
proc backwardCharSelect {args} {
    win::parseArgs w
    set sel [selectLimits -w $w]
    if {$sel == ""} { set p [getPos -w $w] } else { set p [lindex $sel 0] }
    text_wcmd $w tag add sel "$p -1c" $p
}
#¥ backwardDeleteWord - deletes previous word
proc backwardDeleteWord {args} {
    win::parseArgs w
    deleteText -w $w [text_wcmd $w backward_word insert] insert
}
#¥ backwardWord - moves insertion one word back
proc backwardWord {args} {
    win::parseArgs w 
    goto -w $w [text_wcmd $w backward_word insert]
}
#¥ forwardWord - move insertion one word forward
proc forwardWord {args} {
    win::parseArgs w
    goto -w $w [text_wcmd $w forward_word insert]
}

proc pos::currentWord {args} {
    win::parseArgs w index
    text_wcmd $w current_word $index
}

proc pos::backwardWord {args} {
    win::parseArgs w index
    text_wcmd $w backward_word $index
}

proc pos::forwardWord {args} {
    win::parseArgs w index
    text_wcmd $w forward_word $index
}

proc forwardWordSelect {args} {
    win::parseArgs w
    set pos0 [getPos -w $w]
    set pos1 [selEnd -w $w]
    goto -w $w $pos1
    forwardWord -w $w
    set pos2 [getPos -w $w]
    selectText -w $w $pos0 $pos2
}

proc backwardWordSelect {args} {
    win::parseArgs w
    set pos0 [getPos -w $w]
    set pos1 [selEnd -w $w]
    goto -w $w $pos0
    backwardWord -w $w
    set pos2 [getPos -w $w]
    selectText -w $w $pos2 $pos1
}

#¥ beginningBufferSelect - extend selection to the 
#  beginning of the buffer
proc beginningBufferSelect {args} {
    win::parseArgs w
    text_wcmd $w tag add sel 1.0 insert
}
#¥ beginningLineSelect - extend selection to the 
#  beginning of the line
proc beginningLineSelect {args} {
    win::parseArgs w
    text_wcmd $w tag add sel "insert linestart" insert
}
#¥ beginningOfBuffer - move insertion to the beginning 
#  of the buffer
proc beginningOfBuffer {args} {
    win::parseArgs w
    setPin -w $w
    goto -w $w [minPos -w $w]
}
#¥ beginningOfLine - move insertion to the beginning of 
#  the line
proc beginningOfLine {args} {
    win::parseArgs w
    text_wcmd $w goto "insert linestart"
}
#¥ blink <pos> - blink cursor at 'pos'
proc blink {args} {
    win::parseArgs w pos
    text_wcmd $w tag add blink $pos
    getWinInfo -w $w ww
    if {[info exists ww(currline)]} {
	set topl $ww(currline)
	set endl [expr {$topl + $ww(linesdisp)}]
	scan [pos::toRowCol -w $w $pos] "%d %d" row col
	if {$row < $topl || $row >= $endl} {
	    status::msg "Matching '[getText -w $w [lineStart -w $w $pos]\
	      [pos::math -w $w $pos + 1]]'"
	}
    }
    after 500 [list text_wcmd $w tag remove blink $pos]
}
#¥ capitalizeRegion - capitalize all words in selected 
#  region 
proc capitalizeRegion {args} {
    win::parseArgs w
    set pos0 [getPos -w $w]
    set pos1 [selEnd -w $w]
    while {[pos::compare -w $w $pos0 < $pos1]} {
	capitalizeWord -w $w
	forwardWord -w $w; backwardWord -w $w
	set pos0 [getPos -w $w]
    }
    goto -w $w $pos1
}
#¥ capitalizeWord - capitalize word
proc capitalizeWord {args} {
    win::parseArgs w
    set pos0 [getPos -w $w]
    forwardWord -w $w ; set pos1 [getPos -w $w] ; backwardWord -w $w
    if {[pos::compare -w $w [getPos] > $pos0]} {set pos0 [getPos -w $w]}
    if {[pos::compare -w $w $pos1    < $pos0]} {set pos1 [maxPos -w $w]}
    set word [string tolower [getText -w $w $pos0 $pos1]]
    set char [string index $word 0]
    set word [string toupper $char][string range $word 1 end]
    replaceText -w $w $pos0 $pos1 $word
    goto -w $w $pos1
}
#¥ centerRedraw - redraw window with current line in 
#  the middle.
proc centerRedraw {args} {
    win::parseArgs w
    getWinInfo -w $w ww
    set topl $ww(currline)
    set endl [expr {$topl + $ww(linesdisp)}]
    # I don't think this logic is correct when there is soft wrapping.
    foreach {row col} [pos::toRowChar -w $w [getPos -w $w]] {}
    if {$row < $topl - 10 || $row >= 10 + $endl} {
	text_wcmd $w see [getPos -w $w]
    } else {
	text_wcmd $w yview scroll [expr {$row - $topl - $ww(linesdisp)/2}] units
    }
}
#¥ clear - clear selected text
proc clear {args} {
    win::parseArgs w
    set ww $::win::tk($w)
    foreach {s e} [selectSegments -w $w] {
	$ww delete $s $e
    }
}
#¥ copy - copy region
proc alpha::copyRegion {args} {
    win::parseArgs ww
    global win::tk
    if {![info exists win::tk($ww)]} { set ww [winTailToFullName $ww] }
    set limits [selectSegments -w $ww]
    set w $win::tk($ww)
    clipboard clear -displayof $w
    if {[llength $limits]} {
	foreach {s e} $limits {
	    lappend data [$w get $s $e]
	}
	set data [join $data \n]
	clipboard append -displayof $w $data
	status::msg "Region copied"
    } else {
	status::msg "No region to copy"
    }
}
#¥ alpha::pasteRegion - insert the last chunk of text created by 'cut' 
#  or 'copy', and return the list of from-to positions modified.
proc alpha::pasteRegion {args} {
    win::parseArgs ww
    global win::tk
    if {![info exists win::tk($ww)]} { set ww [winTailToFullName $ww] }
    set limits [selectSegments -w $ww]
    set w $win::tk($ww)
    if {![$w readvar read-only]} {
	if {[llength $limits]} {
	    foreach {s e} $limits {
		$w delete $s $e
	    }
	}
	if {[catch {selection get -displayof $w -selection CLIPBOARD} clip]} {
	    status::msg $clip
	    return
	}
	regsub -all "\r" $clip "\n" text
	setPin -w $ww
	set from [$w index insert]
	$w insert insert $text
	return [list $from [$w index "$from + [string length $text]c"]]
    } else {
	status::msg "Can't paste, window is read-only"
	return {}
    }
}
#¥ alpha::cutRegion - deletes and saves region
proc alpha::cutRegion {args} {
    win::parseArgs ww
    global win::tk
    if {![info exists win::tk($ww)]} { set ww [winTailToFullName $ww] }
    set limits [selectSegments -w $ww]
    set w $win::tk($ww)
    if {[llength $limits]} {
	foreach {s e} $limits {
	    lappend data [$w get $s $e]
	}
	set data [join $data \n]
	clipboard clear -displayof $w
	clipboard append -displayof $w $data
	if {![$w readvar read-only]} {
	    foreach {s e} $limits {
		$w delete $s $e
	    }
	    status::msg "Region killed"
	} else {
	    status::msg "Region copied, since read-only"
	}
    } else {
	status::msg "No region to cut"
    }
}
#¥ deleteSelection - delete current position, don't save
proc deleteSelection {args} {
    win::parseArgs w
    global win::tk
    if {![info exists win::tk($w)]} { set w [winTailToFullName $w] }
    set ww $win::tk($w)
    foreach {s e} [selectSegments -w $w] {
	$ww delete $s $e
    }
}
#¥ deleteWord - delete word after cursor
proc deleteWord {args} {
    win::parseArgs w
    text_wcmd $w delete insert "insert wordend"
}
#¥ deleteText <pos1> <pos2> - remove text between 'pos1' 
#  and 'pos2'
proc deleteText {args} {
    win::parseArgs w pos1 pos2
    text_wcmds $w [list delete $pos1 $pos2] \
      [list mark set insert $pos1] [list see insert]
}
#¥ downcaseWord - changes all uppercase letters to 
#  lowercase in current word
proc downcaseWord {args} {
    win::parseArgs w
    foreach {start end} [text_wcmd $w current_word [getPos -w $w]] {}
    selectText -w $w $start $end
    replaceText -w $w $start $end [string tolower [getText -w $w $start $end]]
}
#¥ endBufferSelect - extend selection to the end of the 
#  buffer
proc endBufferSelect {args} {
    win::parseArgs w
    text_wcmd $w tag add sel insert end
}
#¥ endLineSelect - extend selection to the end of line
proc endLineSelect {args} {
    win::parseArgs w
    selectText -w $w [getPos -w $w] [pos::lineEnd -w $w]
}
#¥ endOfBuffer - move insertion to the end of the buffer
proc endOfBuffer {args} {
    win::parseArgs w
    setPin -w $w
    goto -w $w [maxPos -w $w]
}
#¥ endOfLine - move insertion to the end of the line
proc endOfLine {args} {
    win::parseArgs w
    text_wcmd $w goto "insert lineend"
}
#¥ forwardChar - move insertion one character forward
proc forwardChar {args} {
    win::parseArgs w
    if {[isSelection -w $w]} {
	goto -w $w [selEnd -w $w]
    } else {
	goto -w $w [pos::math -w $w [getPos -w $w] +1]
    }
}
#¥ forwardCharSelect - extend selection one character 
#  forward
proc forwardCharSelect {args} {
    win::parseArgs w
    set sel [selectLimits -w $w]
    if {$sel == ""} { set p [getPos -w $w] } else { set p [lindex $sel 1] }
    text_wcmd $w tag add sel $p "$p +1c"
}
#¥ getPos [-w <win>] - return the current insertion point
# By default Alpha and Tk manipulate selections differently.  If you
# select some text with the cursor/mouse, Alpha leaves the insertion point
# at the start of the selction.  Tk leaves it wherever you last left it --- 
# often at the end or middle of the selection.  The best solution is really
# to change the default behaviour encoded in text.tcl, but until that is
# fixed, we really need this proc to be more than just 'text_cmd index insert'.
proc getPos {args} {
    win::parseArgs w
    set sel [text_wcmd $w select]
    if {[llength $sel]} { return [lindex $sel 0] }
    text_wcmd $w index insert
}
#¥ putScrap [<string>]+ - Concatenate strings together into the system 
#  scrap. The scrap can be appended to through calls of the form 'putScrap 
#  [getScrap] " another word"'.
proc putScrap {args} {
    clipboard clear
    eval clipboard append $args
}
#¥ getScrap - returns system TEXT scrap.
proc getScrap {} {
    if {[catch {selection get -selection CLIPBOARD} result]} {
	set result ""
    }
    return $result
}
#¥ getSelect - return the currently selected text, if 
#  any.
proc getSelect {args} {
    win::parseArgs w
    set res ""
    foreach {s e} [selectSegments -w $w] {
	lappend res [text_wcmd $w get $s $e]
    }
    return [join $res \n]
}

#¥ getText [-w <win>] <pos1> <pos2> - return the text between 'pos1' 
#  and 'pos2'. '-w' can be used to specify a window.
proc getText {args} {
    win::parseArgs w pos1 pos2
    text_wcmd $w get $pos1 $pos2
}

#¥ getNamedMarks [-w <win>] [-n] - 
#  return list of all permanent marks in open files. Each
#  element of a list describes one mark as a sublist of the mark's name, 
#  the complete pathname of the mark's file, the position of the first 
#  character in the first line displayed, the current position, and the 
#  end of the selection if text is hilited, or the current position again 
#  if there is no hilited section. '-w' allows window name to be applied 
#  as filter, '-n' means only names will be returned.
proc getNamedMarks {args} {
    getOpts {-w}
    if {[info exists opts(-w)]} {
	set w $opts(-w)
	if {![info exists win::tk($w)]} { set w [winTailToFullName $w] }
    } else {
	set w [win::Current]
    }
    global win::tk
    set w $win::tk($w)
    if {[info exists opts(-n)]} {
	set res ""
	foreach m [$w tag names] {
	    if {[regexp -- "^mark:(.*)$" $m "" mm]} {
		lappend res $mm
	    }
	}
	return $res
    } else {
	set res ""
	foreach m [$w tag names] {
	    if {[regexp -- "^mark:(.*)$" $m "" mm]} {
		set r [$w tag ranges $m]
		lappend res [eval list [list $mm "" [lindex $r 0]] $r]
	    }
	}
	return $res
    }
}
#¥ setNamedMark [name disp pos end] - set named mark. If optional arguments are 
#  present, the mark is created without prompting user. 'disp' is the 
#  character position of the start of the first line to be displayed, 
#  while 'pos' and 'end' bracket the text to be selected.
proc setNamedMark {args} {
    requireOpenWindow
    if {![llength $args]} {
	set p "New Mark Name:"
	if {[catch {prompt $p [getSelect]} name] || $name == ""} {
	    return -code error "Cancelled."
	}
	set disp [getPos]
	set pos  [getPos]
	set end  [selEnd]
	set w [win::Current]
	set quietly 0
    } else {
	win::parseArgs w name disp pos end
	set quietly 1
    }
    set pos [text_wcmd $w index $pos]
    set end [text_wcmd $w index $end]
    if {$pos == $end} { set end "$end +1c" }
    # we'll ignore disp
    text_wcmd $w tag add "mark:$name" $pos $end
    if {!$quietly} {status::msg "'$name' added as a mark."}
}

#¥ removeMark [-all]|[[-n <mark name] [-w <specname>]]- allows marks to be 
#  removed. If no options are specified, it's interactive.
proc removeMark {args} {uplevel 1 removeNamedMark $args}

proc removeNamedMark {args} {
    getOpts {-n -w}
    if {[info exists opts(-w)]} {
	set w $opts(-w)
    } else {
	set w [win::Current]
    }
    if {[info exists opts(-all)]} {
	foreach m [text_wcmd $w tag names] {
	    if {[regexp -- "^mark:" $m]} {
		text_wcmd $w tag delete $m
	    }
	}
	return
    } elseif {![info exists opts(-n)]} {
	# Present the user with a list of marks to remove.
	if {![llength [set marks [getNamedMarks -n]]]} {
	    return -code error "There are no marks to remove."
	}
	set p "Remove which mark?"
	if {[catch {listpick -p $p $marks} opts(-n)]} {
	    return -code error "Cancelled."
	}
	set quietly 0
    } else {
	set quietly 1
    }
    text_wcmd $w tag delete "mark:$opts(-n)"
    if {!$quietly} {status::msg "The '$opts(-n)' mark has been removed."}
}

#¥ getTMarks - Return a list of temporary marks. Each item of the returned 
#  list is a sublist containing the mark name, the complete pathname of the 
#  mark, and the start and finish of the selection named by the mark. The 
#  following is an example of the result: 
#
#    {{temp1 External:file.c 1312 1315} {temp2 Internal:it.h 111 111}} 
#
proc getTMarks {args} {
    win::parseArgs w
    foreach m [text_wcmd $w mark names] {
	set where [text_wcmd $w index $m]
	lappend res [list $m $w $where $where]
    }
    return $res
}
namespace eval tmark {}

proc tmark::getPos {args} {
    win::parseArgs w m
    text_wcmd $w index $m
}

proc tmark::isAt {args} {
    win::parseArgs w p
    set m [text_wcmd $w mark next $p]
    if {($m != "") && [text_wcmd $w compare $m == $p]} {
	return $m
    } else {
	return ""
    }
}

proc tmark::getPositions {args} {
    win::parseArgs w mm
    set res {}
    foreach m $mm {
	lappend res [text_wcmd $w index $m]
    }
    return $res
}

proc tmark::getRange {args} {
    win::parseArgs w m
    set res [text_wcmd $w tag ranges $m]
    if {$res == ""} {
	error "No such mark"
    }
    return [list [lindex $res 0] "" [lindex $res 1]]
}

namespace eval mark {}
proc mark::getRange {args} {
    win::parseArgs w m
    set res [text_wcmd $w tag ranges mark:$m]
    if {$res == ""} {
	error "No such mark"
    }
    return [list [lindex $res 0] "" [lindex $res 1]]
}

# refresh [-w win] -- in Alphatk this isn't required.
proc refresh {args} {}

#¥ display [-w <win>] <pos> - move pos's line to top of screen.
proc display {args} {
    win::parseArgs w pos
    text_wcmd $w yview $pos
}

#¥ goto <pos> - goto the position 'pos'.
proc goto {args} {
    win::parseArgs w pos
    text_wcmd $w goto $pos
    selectText -w $w insert insert
}

proc compare {i op i2} {
    text_cmd compare $i $op $i2
}

#¥ gotoMark - goto named mark, use 'mark' in macros.
proc gotoMark {args} {
    win::parseArgs w mark
    text_wcmds $w [list mark set insert mark:${mark}.first] "see insert"    
    eval [list selectText -w $w] [text_wcmd $w tag ranges mark:$mark]
}
#¥ createTMark <name> <pos> - create a temporary 'mark' 
#  at location 'pos'. 
proc createTMark {args} {
    win::parseArgs w name pos
    text_wcmds $w [list mark set $name $pos] [list mark gravity $name left]
}
#¥ removeTMark <name> - remove temporary mark.
proc removeTMark {args} {
    win::parseArgs w name
    text_wcmd $w mark unset $name
}
#¥ gotoTMark <name> - goto the temporary mark 'name'.
proc gotoTMark {args} {
    win::parseArgs w mark
    text_wcmds $w [list mark set insert $mark] [list see insert]
    selectText -w $w insert insert
}
#¥ insertText [-w <win name>] <text>* - Insert 'text' at the current 
#  insertion point.
proc insertText {args} {
    win::parseArgs w args 
    $::win::tk($w) insert insert [regsub -all "\r" [join $args ""] "\n"]
}

#¥ insertToTop - make the line that the insertion point 
#  is on the first line shown, and display the current 
#  line number along w/ the total number of lines in file
proc insertToTop {args} {
    win::parseArgs w 
    text_wcmd $w yview insert
}
# For killLine and yank
set alpha::lastKillCache ""
set alpha::lastKillWinPos ""
#¥ killLine - kill text from insertion point to the end 
#  of the line. If the line has no text, delete the line 
#  and move succeeding lines up one.
proc killLine {args} {
    win::parseArgs w
    global alpha::lastKillWinPos alpha::lastKillCache
    if {!([lindex $alpha::lastKillWinPos 0] eq $w) \
     || [pos::compare -w $w [lindex $alpha::lastKillWinPos 1] != [getPos -w $w]]} {
	# This is not a concurrent killLine.
	set alpha::lastKillCache ""
    }
    set end "insert lineend"
    if {[text_wcmd $w compare insert == $end]} {set end "insert +1c"}
    append alpha::lastKillCache [text_wcmd $w get insert $end]
    text_wcmd $w delete insert $end
    set alpha::lastKillWinPos [list $w [getPos -w $w]]
}
#¥ yank - insert the last piece of deleted text of less
#  than 1k. Consecutive deletes are concatenated.
#  together.
proc yank {args} {
    win::parseArgs w
    global alpha::lastKillCache
    insertText -w $w $alpha::lastKillCache
}
#¥ lineStart <pos> - return the position of the start of
#  the line 'pos' is on.
proc lineStart {args} {
    win::parseArgs w pos
    return "$pos linestart"
}
#¥ lookAt [-w <name>] <pos> - return the 'pos'th character of the 
#  current file, or the file named by <name> if the '-w' option is specified.
proc lookAt {args} {
    win::parseArgs w pos {chars 1}
    text_wcmd $w get $pos "$pos + ${chars}c"
}
#¥ matchBrace - moves the insertion point to the 
#  character that matches the character after the current 
#  insertion point
proc matchBrace {args} {
    win::parseArgs w
    goto -w $w [matchIt -w $w [text_wcmd $w get insert] insert]
}
#¥ balance - selects smallest set of parens, braces, or 
#  brackets that encloses the current selection.  Throws
#  an error if nothing matched.
proc balance {args} {
    win::parseArgs w
    if {[catch {text_wcmd $w balance} res]} {
	return -code error "Cancelled - $res"
    }
    return $res
}
#¥ matchIt <brace char> <pos> [<limit>] - Return pos of matching brace.
#Recognizes parenthesis, square brackets, and curly braces.  Optional
#third argument specifies how many characters to search.
proc matchIt {args} {
    win::parseArgs w char pos {limit ""}
    if {$limit != ""} {
	text_wcmd $w match $char $pos $limit
    } else {
	text_wcmd $w match $char $pos
    }
}
# Returns minimum position in the window (depends upon window system
# whether this starts with 1 or 0 or ...).  Can take '-w win' which
# it ignores.
proc minPos {args} { win::parseArgs w ; return 1.0 }
#¥ maxPos [-w <win>] - returns the number of characters in the front
#  window.
proc maxPos {args} {
    win::parseArgs w
    text_wcmd $w index "end -1c"
}
#¥ moveInsertionHere [-last] - move the insertion point to the 
#  first (or last) line displayed
proc moveInsertionHere {args} {
    win::parseArgs w {where -first}
    getWinInfo -w $w ww
    set topl $ww(currline)
    foreach {row col} [pos::toRowChar -w $w [getPos -w $w]] {}
    if {$where == "-first"} {
	goto -w $w "[expr {$topl +1}].0"
    } else {
	set endl [expr {$topl + $ww(linesdisp)}]
	goto -w $w "$endl.0"
    }
}

#¥ nextLine - move insertion point to next line
proc nextLine {args} {
    win::parseArgs w
    if {[isSelection -w $w]} {
	goto -w $w [selEnd -w $w]
    } else {
        #goto -w $w "insert +1l"
        goto -w $w [text_updownline $w insert 1]
    }
}
#¥ nextLineSelect - extend selection to the next line
proc nextLineSelect {args} {
    win::parseArgs w
    set sel [selectLimits -w $w]
    if {$sel == ""} {
	set p [getPos -w $w]
    } else {
	set p [lindex $sel 1]
    }
    #set next "$p +1l"
    set next [text_updownline $w $p 1]
    text_wcmds $w [list tag add sel $p $next] [list see $next]
}
#¥ previousLine - move insertion point to the previous 
#  line
proc previousLine {args} {
    win::parseArgs w
    if {[isSelection -w $w]} {
        goto -w $w [getPos -w $w]
    } else {
        #goto -w $w "insert -1l"
        goto -w $w [text_updownline $w insert -1]
    }
}
#¥ prevLineSelect - extend selection to the previous line
proc prevLineSelect {args} {
    win::parseArgs w
    set sel [selectLimits -w $w]
    if {$sel == ""} {
        set p insert
    } else {
        set p [lindex $sel 0]
    }
    #set prev "$p -1l"
    set prev [text_updownline $w $p -1]
    text_wcmds $w [list tag add sel $prev $p] [list see $prev]
}
#¥ nextLineStart <pos> - return the position of the start 
#  of the next line after position 'pos'.
proc nextLineStart {args} {
    win::parseArgs w pos
    set res "$pos linestart +1l"
    if {[string length $res] > 20} {
	set res [text_wcmd $w index $res]
    }
    return $res
}
#¥ oneSpace - converts whitespace surrounding insertion
#  into a single space.
proc oneSpace {args} {
    win::parseArgs w
    set p [getPos -w $w]
    set char [lookAt -w $w $p]
    if {[string trim $char] != ""} {
	set p [pos::math -w $w $p -1]
	if {[string trim [lookAt -w $w $p]] != ""} { return }
    }
    set first [lindex [search -w $w -s -n -r 1 -f 0 {[^ \t\r\n]} $p] 1]
    set last [lindex [search -w $w -s -n -r 1 -f 1 {[^ \t\r\n]} $p] 0]
    if {$first == ""} {
	set first [minPos -w $w]
    }
    if {$last == ""} {
	set last [maxPos -w $w]
    }
    if {![pos::compare -w $w $first == $last]} {
	if {[getText -w $w $first $last] != " "} {
	    replaceText -w $w $first $last " "
	}
    }
}
#¥ openLine - insert a new line following the current 
#  one and move the insertion point to it
proc openLine {args} {
    win::parseArgs w
    goto -w $w "insert lineend"
    insertText -w $w "\r"
}
#¥ pageBack - display previous screenful, move the
#  insertion point if 'moveInsertion' enabled
proc pageBack {args} {
    win::parseArgs w
    global moveInsertion
    text_wcmd $w yview scroll -1 pages
    if {$moveInsertion} {
	set i [text_wcmd $w index insert]
	set first [text_wcmd $w index @0,0]
	set ww $win::tk($w)
	set last [text_wcmd $w index "@[winfo width $ww],[winfo height $ww]"]
	if {[pos::compare -w $w insert < $first]\
	  || [pos::compare -w $w insert > $last]} {
	    scan $i "%d.%d" line char
	    scan $last "%d.%d" lastline lastchar
	    goto -w $w $lastline.$char
	}
    }
}
#¥ pageForward - display next screenful, move the
#  insertion point if 'moveInsertion' enabled
proc pageForward {args} {
    win::parseArgs w
    global moveInsertion
    text_wcmd $w yview scroll 1 pages
    if {$moveInsertion} {
	set i [text_wcmd $w index insert]
	set first [text_wcmd $w index @0,0]
	set ww $win::tk($w)
	set last [text_wcmd $w index "@[winfo width $ww],[winfo height $ww]"]
	if {[pos::compare -w $w insert < $first]\
	  || [pos::compare -w $w insert > $last]} {
	    scan $i "%d.%d" line char
	    scan $first "%d.%d" firstline firstchar
	    goto -w $w $firstline.$char
	}
    }
}
#¥ rectangularHiliteToPin - creates a rectangular selection 
#  between the mark and the insertion point.
proc rectangularHiliteToPin {args} {
    win::parseArgs w
    # Not sure how good an implementation this is.
    set corner1 [text_wcmd $w index sel]
    set corner2 [text_wcmd $w index insert]
    
    foreach {row1 col1} [pos::toRowCol -w $w $corner1] {}
    foreach {row2 col2} [pos::toRowCol -w $w $corner2] {}
    if {$row1 > $row2} {
	set tmp $row1
	set row1 $row2
	set row2 $row1
    }
    if {$col1 > $col2} {
	set tmp $col1
	set col1 $col2
	set col2 $col1
    }
    for {set col $col1} {$col <= $col2} {incr col} {
	set pos1 [pos::fromRowCol -w $w $row1 $col]
	set pos2 [pos::fromRowCol -w $w $row2 $col]
	text_wcmd $w tag add sel $pos1 $pos2
    }
}
#¥ replaceText <pos1> <pos2> [text]+ - replaces the text
#  between 'pos1' and 'pos2' with 'text', where 'text' can be any number 
#  of arguments. Leaves insertion at end, mark at beginning of inserted 
#  text. 
proc replaceText {args} {
    win::parseArgs w begin end args
    set text [regsub -all "\r" [join $args ""] "\n"]
    text_wcmd $w replace $begin $end $text
}

proc placeText {args} {
    win::parseArgs w pos text
    regsub -all "\r" $text "\n" text
    text_wcmd $w insert $pos $text
}

#¥ scrollDownLine - same action as that which occurs when 
#  the down arrow in the vertical scrollbar is selected
proc scrollDownLine {args} {
    win::parseArgs w
    text_wcmd $w yview scroll 1 units
}

#¥ scrollLeftCol - same action as that which occurs when
#  the left arrow in the horizontal scrollbar is selected
proc scrollLeftCol {args} {
    win::parseArgs w chars
    text_wcmd $w xview scroll -$chars units
}
#¥ scrollRightCol - same action as that which occurs when
#  the right arrow in the horizontal scrollbar is 
#  selected
proc scrollRightCol {args} {
    win::parseArgs w chars
    text_wcmd $w xview scroll $chars units
}
#¥ scrollUpLine - same action as that which occurs when 
#  the up arrow in the vertical scrollbar is selected
proc scrollUpLine {args} {
    win::parseArgs w
    text_wcmd $w yview scroll -1 units
}
#¥ select [-w <win>] <pos1> ?<pos2>?  ?<pos3> <pos4>...?- selects the
#  text between 'pos1' and 'pos2', and between pos3 and pos4 ...  If
#  any 'to' position is missing, it's assumed to be the same as the from
#  position.
proc selectText {args} {
    win::parseArgs w args
    
    if {![llength $args]} {
	return -code error "Bad arguments $args, should be \
	  selectText -w <win> <pos1> ?<pos2>? ?<pos3> <pos4>...?"
    }
    
    text_wcmd $w mark set insert [lindex $args 0]

    # Now order the positions for the rest of
    # this procedure
    foreach {from to} $args {
	if {$to eq ""} {
	    set to $from
	}
	if {[text_wcmd $w compare $from > $to]} {
	    set tmp $from
	    set from $to
	    set to $tmp
	}
	lappend selranges $from $to
    }
    
    # Clear existing selection
    set range [text_wcmd $w tag ranges sel]
    if {$range != ""} {
	eval [list text_wcmd $w tag remove sel] $range
    }
    eval [list text_wcmd $w tag add sel] $selranges
    text_wcmd $w see [lindex $args 0]
    return
    
    # Need to check here with min/max are both offscreen, and in that
    # case don't bother with the 'see' business.
    set viewable [text_wcmd $w viewable $pos2 $pos1]
    if {$viewable == "0 0"} { return }
    if {[expr [join $viewable *]] != -1} {
	# Do the 'see $pos1' last, because we want the 'insert'
	# to be visible.
	text_wcmds $w [list see $pos2] [list see $pos1]
    }
}

#¥ selEnd [-w <win] - returns the end of the hilited selection, or 
#  the current insertion point if no text is selected.
proc selEnd {args} {
    win::parseArgs w
    set sel [text_wcmd $w select]
    if {[llength $sel]} { return [lindex $sel end] }
    text_wcmd $w index insert
}
#¥ tab - insert a tab
proc tab {args} {
    win::parseArgs w
    typeText -w $w "\t"
}
#¥ upcaseWord - convert all lowercase letters to 
#  uppercase in the current word
proc upcaseWord {args} {
    win::parseArgs w
    foreach {start end} [text_wcmd $w current_word [getPos -w $w]] {}
    selectText -w $w $start $end
    replaceText -w $w $start $end [string toupper [getText -w $w $start $end]]
}
