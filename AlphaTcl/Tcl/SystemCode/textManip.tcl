## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "textManip.tcl"
 #                                          created: 09/23/1999 {03:30:49 PM}
 #                                      last update: 05/04/2006 {04:31:35 PM} 
 # Description: 
 # 
 # Procedures that provide information about a selection or window, or
 # manipulate text for a given window.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 # 
 # (Includes contributions by many others over the years -- thanks!)
 #  
 # Copyright (c) 1999-2006 Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 #  
 # ==========================================================================
 ##

proc textManip.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "wordCount" -- ?-w <window>?
 # 
 # Determine the number of characters, words, and lines in a text string.
 # 
 # The counts are computed for the given window, defaulting to the active
 # one.  Values are returned in a dialog that allows the user to save the
 # information in the Clipboard.
 # 
 # The majority of this procedure is concerned with properly presenting the
 # data in a "tabular" format within a dialog.  This is a bit tricky, as the
 # Tab (and more importantly how far it extends in relationship to normal
 # text) can be interpreted in different ways for different platforms.
 # 
 # --------------------------------------------------------------------------
 ##

proc wordCount {args} {
    
    global alpha::platform
    
    win::parseArgs w
    
    # Determine information for selection, window.
    if {[isSelection -w $w]} {
	set counts [countWords -w $w [getSelect -w $w]]
    } else {
	set counts [list 0 0 0]
    }
    if {([set winText [getText -w $w [minPos -w $w] [maxPos -w $w]]] ne "")} {
	eval [list lappend counts] [countWords -w $w $winText]
    } else {
	lappend counts 0 0 0
    }
    # Adjust the window line count if it ends with \r|\n .
    if {[regexp {[\r\n]} [lookAt -w $w [pos::prevChar -w $w [maxPos -w $w]]]]} {
	set counts [lreplace $counts 5 5 [expr {[lindex $counts 5] + 1}]]
    }
    # This helps us present "tabular" data, embedding "\t" in the text below.
    for {set i 0} {($i < 6)} {incr i} {
	set count$i [format {%7s} [lindex $counts $i]]
    }
    # Create the dialog text.  We have three different flavors, since Alpha
    # and Alphatk handle embedded tabs in dialog text metrics differently.
    if {([string length [lindex $counts 3]] > 7)} {
	# We have a huge file.  Don't even try to present this data in a
	# three column format, it will be a mess.  (If the routines below are
	# problematic with different OS versions, we can just use this for
	# all platforms.)
	set width 275
	append txt1 "Selection contents" \r 
	append txt1 "Chars:  " \t\t $count0 \n
	append txt1 "Words:  " \t\t $count1 \n
	append txt1 "Lines:  " \t\t $count2 \r
	append txt2 "Window contents" \r
	append txt2 "Chars:  " \t\t $count3 \n
	append txt2 "Words:  " \t\t $count4 \n
	append txt2 "Lines:  " \t\t $count5 \r
    } elseif {(${alpha::platform} eq "alpha")} {
	set width 275
	append txt1 "Counts  " \t\t "  Selection" \t " Window"
	append txt2 "Chars:  " \t\t "  " $count0 "    " \t $count3 \n
	append txt2 "Words:  " \t\t "  " $count1 "    " \t $count4 \n
	append txt2 "Lines:  " \t\t "  " $count2 "    " \t $count5 \r
    } else {
	set width 325
	append txt1 "Counts  " \t\t "Selection" \t "   Window"
	append txt2 "Chars:  " \t\t $count0 \t "  " $count3 \n
	append txt2 "Words:  " \t\t $count1 \t "  " $count4 \n
	append txt2 "Lines:  " \t\t $count2 \t "  " $count5 \r
    }
    # Present the dialog, save the information in the Clipboard if that
    # options is selected by the user.
    set dialogScript [list dialog::make -width $width \
      -title "Word Count" \
      -okhelptag "Click here to dismiss this dialog." \
      -cancel "Save To Clipboard" \
      -cancelhelptag "Click here to save this information in the Clipboard." \
      [list "" \
      [list text "\"[file tail $w]\"\r"] \
      [list text $txt1] \
      [list "divider" "divider"] \
      [list text $txt2] \
      ]]
    if {[catch {eval $dialogScript}]} {
	# User pressed "Save To Clipboard" button.
	for {set i 0} {($i < 6)} {incr i} {
	    set count$i [format {%-12s} [lindex $counts $i]]
	}
	append scrapText $w \r\r \
	  "Type    " "Selection   " "Window" \r \
	  "----    " "---------   " "------" \r \
	  "Chars:  " $count0        $count3  \r \
	  "Words:  " $count1        $count4  \r \
	  "Lines:  " $count2        $count5  \r
	putScrap $scrapText
	set msg "Information has been placed in the Clipboard."
    } elseif {($w ne [win::Current])} {
	return
    } elseif {([lindex $counts 0] != 0)} {
	set msg "Current selection: "
	set msgCounts [lrange $counts 0 2]
    } else {
	set msg "Window counts: "
	set msgCounts [lrange $counts 3 5]
    }
    if {[info exists msgCounts]} {
	append msg \
	  [lindex $msgCounts 0] " character" \
	  [expr {([lindex $msgCounts 0] != 1) ? "s" : ""}] "; " \
	  [lindex $msgCounts 1] " word" \
	  [expr {([lindex $msgCounts 1] != 1) ? "s" : ""}] "; " \
	  [lindex $msgCounts 2] " line" \
	  [expr {([lindex $msgCounts 2] != 1) ? "s" : ""}]
    }
    status::msg $msg
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "countWords" -- ?-w <window>? <text>
 # 
 # Determine the number of characters, words, and lines in a text string.
 # 
 # The results are returned in a three item list.  The "wordBreakPat" is
 # based on the "wordBreak" preference for the mode of the given window, and
 # is used to determine the number of words in the supplied text string.  If
 # no window is supplied, the preference for the active window is used;
 # supply "-w {}" to use the default "\w+" pattern.  For example, this
 # command will use the "* Tcl Shell *" value:
 # 
 #   «Alpha» countWords "status::msg test"
 #   16 2 1
 #   
 # while this one uses the default "\w+" value:
 # 
 #   «Alpha» countWords -w "" "status::msg test"
 #   16 3 1
 # 
 # If you need to supply a different "wordBreak" pattern that is not related
 # to any open window, you might as well just write a specialized procedure
 # yourself borrowing from the code below.
 # 
 # Note that any string that ends with \r|\n will have its number of "lines"
 # reduced by one, i.e. that last eol will be ignored.
 # 
 # --------------------------------------------------------------------------
 ##

proc countWords {args} {
    
    win::parseArgs w text
    
    # Number of characters.
    set characters [string length $text]
    # Number of words.
    set words [regexp -all -- [win::getModeVar $w wordBreak {\w+}] $text]
    # Number of lines.  Ignore any trailing line-ending character(s).
    regsub -- {(\r|(\r?\n))$} $text "" lineText
    set lines [llength [split $lineText "\r\n"]]
    return [list $characters $words $lines]
}

proc requireOpenWindow {{msg ""}} {
    if {[llength [winNames -f]]} {
	return
    }
    if {![string length $msg]} {
	if {[catch {info level -1} item]} {
	    set item "this item"
	}
	set msg "Cancelled -- \"[quote::Prettify $item]\"\
	  requires an open window."
    } elseif {![string match -nocase "*cancel*" $msg]} {
        set msg "Cancelled -- $msg"
    }
    error $msg
}

proc requireSelection {args} {
    win::parseArgs w {msg ""}
    if {[isSelection -w $w]} {
	return
    }
    if {![string length $msg]} {
	if {[catch {info level -1} item]} {
	    set item "this item"
	}
	set msg "Cancelled -- \"[quote::Prettify $item]\"\
	  requires a selection."
    } elseif {![string match -nocase "*cancel*" $msg]} {
	set msg "Cancelled -- $msg"
    }
    error $msg
}

# FILE: sortLines.tcl
#
# This version of sortLines has the option of ignoring blanks/whitespace (-b)
# and case-insensitive sorting (-i), or reverse sorting, and removing duplicates
# if desired [-d]
# 	sortLines [-b] [-i] [-r] [-d]

# COPYRIGHT:
#
#	Copyright © 1992,1993 by David C. Black All rights reserved.
#	Portions copyright © 1990, 1991, 1992 Pete Keleher. All Rights Reserved.
#   Portions copyright (c) 1999-2004 Vince Darley, no rights reserved.
#
#	Redistribution and use in source and binary forms are permitted
#	provided that the above copyright notice and this paragraph are
#	duplicated in all such forms and that any documentation,
#	advertising materials, and other materials related to such
#	distribution and use acknowledge that the software was developed
#	by David C. Black.
#
#	THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#	IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
################################################################################

# AUTHOR
#
#	David C. Black
#	GEnie:    D.C.Black
#	Internet: black@mpd.tandem.com (preferred)
#	USnail:   6217 John Chisum Lane, Austin, TX 78749
#
################################################################################

proc reverseSort {} {sortLines -r}

proc sortLines {args} {
    if {![win::checkIfWinToEdit]} {return}
    getOpts

    if {[info exists opts(-r)]} {
	set mode "-decreas"
    } else {
	set mode "-increas"
    }

    if {[pos::compare [getPos] == [selEnd]]} {
	set start [minPos]
	set end [maxPos]
    } else {
	# We extend last line to the end :
	if {![is::Eol [lookAt [pos::math [selEnd] - 1]]]} {
	    set end [nextLineStart [selEnd]]
	} else {
	    set end [selEnd]
	}
	# We extend first line to the start :
	set start [lineStart [getPos]]
    }
    if {![is::Eol [lookAt [pos::math $end - 1]]]} {
	set endoftext $end
    } else {
	set endoftext [pos::math $end - 1]
    }
    set text [split [getText $start $endoftext] "\n\r"]
    if {[info exists opts(-b)] || [info exists opts(-i)] \
      || [info exists opts(-d)]} {
	foreach line $text {
	    if {[info exists opts(-i)]} {
		set key [string tolower $line]
	    } else {
		set key $line
	    }
	    if {[info exists opts(-b)]} {
		regsub -all "\[ \t\]+" $key " " key
	    }
	    if {![info exists orig($key)]} {
		set orig($key) $line
		lappend list $key
	    } elseif {![info exists opts(-d)]} {
		while {[info exists dup($key)]} {
		    append key "z"
		}
		set dup($key) $line
	    }
	}
	unset text
	foreach key [lsort $mode $list] {
	    lappend text $orig($key)
	    while {[info exists dup($key)]} {
		lappend text $dup($key)
		append key "z"
	    }
	}
    } else {
	set text [lsort $mode $text]
    }
    set text [join $text "\r"]
    replaceText $start $endoftext $text
    set endoftext [pos::math $start + [string length $text] + 1]
    if {[pos::compare [maxPos] < $endoftext]} {
	set endoftext [maxPos]
    }
    selectText $start $endoftext
}

# Test case:
#
# a  black
# A  black dog
# a black cat
# A  Black dog
# A  black dog


## 
 # -------------------------------------------------------------------------
 # 
 # "sortParagraphs" --
 # 
 #  Sorts selected paragraphs according to their first 30 characters,
 #  it's case insensitive and removes all non alpha-numeric characters
 #  before the sort.
 # -------------------------------------------------------------------------
 ##
proc sortParagraphs {args} {
    set start [getPos]
    set end  [selEnd]
    if {[pos::compare [getPos] == [selEnd]]} {
	set start [minPos]
	set end [maxPos]
    } else {
	# We extend last line to the end :
	if {![is::Eol [lookAt [pos::math [selEnd] - 1]]]} {
	    set end [nextLineStart [selEnd]]
	} else {
	    set end [selEnd]
	}
	# We extend first line to the start :
	set start [lineStart [getPos]]
    }
    if {![is::Eol [lookAt [pos::math $end - 1]]]} {
	set endoftext $end
    } else {
	set endoftext [pos::math $end - 1]
    }
    set text [getText $start $end]

    if {[string first "•" $text] != -1} {
	alertnote "Sorry, can't sort paragraphs with bullets '•'."
	return
    }
    regsub -all "\[\r\n\]\[ \t\]*\[\r\n]" $text "\r•" text
    set paras [split $text "•"]
    unset text
    # now each paragraph ends in \r
    foreach para $paras {
	set key [string tolower [string range $para 0 30]]
	regsub -all {[^-a-z0-9]} $key "" key
	# so we don't clobber duplicates!
	if {![info exists orig($key)]} {
	    set orig($key) $para
	} else {
	    while {[info exists dup($key)]} {
		append key "z"
	    }
	    set dup($key) $para
	}
    }
    unset para
    foreach key [lsort [array names orig]] {
	lappend text $orig($key)
	while {[info exists dup($key)]} {
	    lappend text $dup($key)
	    append key "z"
	}
    }
    replaceText $start $end [join $text "\r"]
    selectText $start $end
}

#================================================================================
# Block shift left and right.
#================================================================================

proc shiftBy {amount} {
    if {![win::checkIfWinToEdit]} {return}
    #### Preliminary positions ####
    # --- concerning the first involved line (line0)
    set pos0 [getPos]
    set start0 [pos::lineStart $pos0]
    set end0 [pos::lineEnd $pos0]
    # 'restSize0' is the distance from current position to the end of
    # that line
    set restSize0 [pos::diff $pos0 $end0]
    # Special case: Selection starts at line-start; keep it that way:
    if {[pos::compare $pos0 == $start0] && [isSelection]} {
	set restSize0 "1000"
    }
    # --- concerning the last line (line1)
    set pos1 [selEnd]
    set end1 [pos::lineEnd $pos1]
    # 'restSize1' is the distance from selEnd to the end of that line
    # (last line)
    set restSize1 [pos::diff $pos1 $end1]
    # Special case: Selection ends at next-line-start, so back up to prev line:
    if {[pos::compare $pos1 == [pos::lineStart $pos1]] && [isSelection] } {
	set end1 [pos::prevLineEnd $pos1]
	set restSize1 "-1"
    }
    #### Shift the text ####
    set newText [text::indentBy [getText $start0 $end1] $amount]
    replaceText $start0 $end1 $newText
    #### Restore original position/selection relative to text ####
    # Note that the only position that we can still count on is $start0,
    # but we have enough info to obtain line end positions and then back up
    # using $restSize0/1.
    set newPos0 [pos::math [pos::lineEnd $start0] - $restSize0]
    if {[pos::compare $newPos0 < $start0]} { set newPos0 $start0 }
    set newPos1 [pos::math $start0 + [string length $newText] - $restSize1]
    if {[pos::compare $newPos1 < $start0]} { set newPos1 $start0 }
    selectText $newPos0 $newPos1
}

proc shiftRight {} {
    shiftBy [text::getIndentationAmount]
}

proc shiftLeft {} {
    shiftBy -[text::getIndentationAmount]
}

proc shiftLeftSpace {} {
    shiftBy -1
}

proc shiftRightSpace {} {
    shiftBy 1
}

proc doShiftLeft {shiftChar} {
    set start [lineStart [getPos]]
    set end [nextLineStart [pos::math [selEnd] - 1]]
    if {[pos::compare $start >= $end]} {set end [nextLineStart $start]}
    
    set text [split [getText $start [pos::math $end - 1]] "\r\n"]
    
    set textout ""
    
    foreach line $text {
	if {[regexp "($shiftChar)(.*)$" $line "" "" c]} {
	    lappend textout $c
	} else {
	    lappend textout $line
	}
    }
    
    set text [join $textout "\r"]	
    replaceText $start [pos::math $end - 1] $text
    selectText $start [pos::math $start + [expr {1 + [string length $text]}]]
}

proc doShiftRight {shiftChar} {
    set start [lineStart [getPos]]
    set end [nextLineStart [pos::math [selEnd] - 1]]
    if {[pos::compare $start >= $end]} {set end [nextLineStart $start]}
    
    set text [split [getText $start [pos::math $end - 1]] "\r\n"]
    
    set text "$shiftChar[join $text \r${shiftChar}]"
    replaceText $start [pos::math $end - 1] $text
    selectText $start [pos::math $start + [expr {1 + [string length $text]}]]
}

proc selectAll {args} {
    win::parseArgs w
    selectText -w $w [minPos -w $w] [maxPos -w $w]
}

proc isSelection {args} {
    win::parseArgs w
    if {![llength [winNames -f]]} {
	return 0
    } else {
	return [pos::compare -w $w [getPos -w $w] != [selEnd -w $w]]
    }
}

# Select the next or current word. If word already selected, will go to next.
proc hiliteWord {} {
    requireOpenWindow
    if {[pos::compare [getPos] != [selEnd]]} forwardChar
    forwardWord
    set start [getPos]
    backwardWord
    if {[pos::compare [getPos] < [lineStart $start]]} {
	goto [lineStart $start]
    }
    selectText $start [getPos] 
}

proc text::replace {old new {fwd 1} {pos ""}} {
    if {$pos == ""} {set pos [getPos]}
    set m [search -s -f $fwd -m 0 -r 0 -- $old $pos]
    eval replaceText $m [list $new]
}

## 
 # -------------------------------------------------------------------------
 #	 
 #	"containsSpace"	--
 #	
 #  Does the given text contain any spaces?  In general we don't complete
 #  commands that contain spaces (although perhaps future extensions should
 #  do this: e.g. cycle through 'string match', 'string compare',…)
 #	 
 # -------------------------------------------------------------------------
 ##
proc containsSpace { cmd } { return [string match "*\[ \t\]*" $cmd] }
proc containsReturn { cmd } { return [string match "*\[\r\n\]*" $cmd] }

## 
 # -------------------------------------------------------------------------
 # 
 # "togglePrefix" --
 # 
 #  Useful for e.g. Tcl mode to add/remove a '$', TeX to add/remove 
 #  a backslash, etc.  Only works for single character prefixes.
 #  
 #  Returns +/- 1 depending on if a character was inserted (1) or
 #  deleted (-1).
 # -------------------------------------------------------------------------
 ##
proc togglePrefix {pref} {
    set p [getPos]
    backwardWord
    if {[lookAt [getPos]] eq $pref} {
	deleteChar
	goto [pos::math $p -1]
	return -1
    } else {
	insertText $pref
	goto [pos::math $p +1]
	return 1
    }
}

proc twiddle {} {
    global twiddleAdjusts
    if {![win::checkIfWinToEdit]} {return}
    
    set pos [getPos]
    
    # If there is a selection
    if {[string length [set text [getSelect]]]} {
	if {[string length $text] == 1} {
	    status::msg "Select more than one character to twiddle"
	} else {
	    set sel [pos::math [selEnd] - 1]
	    set char1 [lookAt $sel]
	    set char2 [lookAt $pos]
	    replaceText $pos [pos::math $sel + 1] \
	      "$char1[getText [pos::math $pos + 1] $sel]$char2"
	    status::msg "twiddled chars: $char1$char2"
	    selectText $pos [pos::math $sel + 1]
	}
    } else {
	# If there is no selection, there are three possibilities,
	# depending on the user's preference.
	if {[pos::compare $pos == [minPos]]} {return}
	
	switch -- $twiddleAdjusts {
	    0 {
		if {[pos::compare $pos == [maxPos]]} {return}
		set first $pos
		set second [pos::math $pos - 1]
	    }
	    1 {
		set first [pos::math $pos -1]
		if {[pos::compare $first == [minPos]]} {return}
		set second [pos::math $first -1]
	    }
	    2 {
		set searchResult [search -s -n -f 0 -m 0 -i 1 \
		  -r 1 {[^ \r\n\t]} [pos::math $pos - 1]]
		if {![llength $searchResult]} {return}

		set first [lindex $searchResult 0]
		if {[pos::compare $first == [minPos]]} {return}
		set second [pos::math $first -1]
	    }
	}
	
	set char1 [lookAt $first]
	set char2 [lookAt $second]
	
	replaceText $second [pos::math $first +1] "${char1}${char2}"
	status::msg "twiddled chars: ‘$char1$char2’"
	# Emacs like movement of cursor for this preference.
	if {$twiddleAdjusts == 0} {set pos [pos::math $pos + 1]}
	goto $pos
    }
}

proc twiddleWords {} {
    global twiddleAdjusts
    if {![win::checkIfWinToEdit]} {return}

    set pos [getPos]
    set start1 $pos
    set end2 [selEnd]

    # If there is a selection
    if {[pos::compare $start1 != $end2]} {
	selectText $start1
	forwardWord; set end1 [getPos]
	goto $end2
	backwardWord; set start2 [getPos]
	# If there is no selection, there are two possibilities,
	# depending on the user's preference.
    } elseif {$twiddleAdjusts} {
	backwardWord; backwardWord; set start1 [getPos]
	forwardWord; set end1 [getPos]
	forwardWord; set end2 [getPos]
	backwardWord; set start2 [getPos]
    } else {
	backwardWord; set start1 [getPos]
	forwardWord; set end1 [getPos]
	goto $pos
	forwardWord; set end2 [getPos]
	backwardWord; set start2 [getPos]
    }

    if {[pos::compare $end1 > $start2] \
      || [pos::compare $start1 == $start2] || [pos::compare $end1 == $end2]} {
	status::msg "twiddleWords error: two words not specified"
	if {$twiddleAdjusts} {forwardWord}
	return
    }

    set mid [getText $end1 $start2]
    set one [getText $start2 $end2]
    set two [getText $start1 $end1]
    replaceText $start1 $end2 "$one$mid$two"
    status::msg "twiddleWords words “${one}” with “${two}”"
    goto $end2
}

proc insertPrefix {} {doPrefix insert}
proc removePrefix {} {doPrefix remove}

proc doPrefix {which} {
    if {![win::checkIfWinToEdit]} {return}
    
    set prefix [win::getModeVar [win::Current] prefixString ""]
    if {$prefix eq ""} { return }
    
    set reselect [isSelection]

    set pos0 [pos::lineStart]
    set lng0 [pos::diff $pos0 [getPos]]
    if {![pos::diff $pos0 [selEnd]] && $which ne "insert"} {
	# We're uncommenting at the beginning of the line.
	set offset [string length $prefix]
	set pos1 [pos::math $pos0 + $offset]
    } else {
	set offset 0
	set pos1 [selEnd]
    }
    set txt1 [getText $pos0 $pos1]
    set lng1 [string length $txt1]
    set txt2 [doPrefixText $which $prefix $txt1]
    set lng2 [string length $txt2]
    if {$lng1 == $lng2} {return}
    replaceText $pos0 $pos1 $txt2
    set pos0 [pos::math $pos0 + $offset]
    set pos2 [pos::math $pos0 + $lng2]
    if {$reselect} {
	set lng3 [string length $prefix]
	if {$which == "insert"} {
	    if {$lng0} {set pos0 [pos::math $pos0 + $lng0 + $lng3]}
	} else {
	    if {$lng0} {set pos0 [pos::math $pos0 + $lng0 - $lng3]}
	}
	selectText $pos0 $pos2
    } else {
	goto [pos::math $pos2 + $lng0 - $lng1]
    }
}

proc quoteChar {} {
    status::msg "Literal keystroke to be inserted:"
    insertText [getChar]
}

proc setPrefix {} {
    global prefixString
    if {[info exists prefixString]} {
	synchroniseModeVar prefixString \
	  [prompt "New Prefix String:" $prefixString]
	status::msg "New prefix string stored."
    } else {
        alertnote "No prefix string in the current mode"
    }
}

proc setSuffix {} {
    global suffixString
    if {[info exists suffixString]} {
	synchroniseModeVar suffixString \
	  [prompt "New Suffix String:" $suffixString]
	status::msg "New suffix string stored."
    } else {
	alertnote "No suffix string in the current mode"
    }
}

proc insertSuffix {} {doSuffix insert}
proc removeSuffix {} {doSuffix remove}
proc doSuffix {which} {
    if {![win::checkIfWinToEdit]} {return}
    
    set suffix [win::getModeVar [win::Current] suffixString ""]
    if {$suffix eq ""} {return}
    
    # Do we need to reselect at the end?
    set reselect [isSelection]
    # We need these positions, rows, columns to perform tests below, and to
    # properly replace text.
    set trc0 [pos::toRowCol [getPos]]
    set pos0 [pos::lineStart]
    set row0 [lindex $trc0 0]
    set col0 [lindex $trc0 1]
    set trc1 [pos::toRowCol [selEnd]]
    set pos1 [pos::nextLineStart [selEnd]]
    set row1 [lindex $trc1 0]
    set col1 [lindex $trc1 1]
    set trcM [pos::toRowCol [pos::max]]
    set rowM [lindex $trcM 0]
    # Perform some tests to ensure we will get the correct text to replace.
    if {$row1 == $rowM && (!$reselect || $col1 != 0)} {
	# We're in the last row.  Make sure that our selection has a trailing
	# carriage return.
	set txt1 [getText $pos0 $pos1]
	set txt2 [doSuffixText $which $suffix ${txt1}\r]
	set txt2 [string trimright $txt2]
    } elseif {$reselect && $row1 != $rowM && $col1 == 0} {
	# Fairly common case, where we have a selection that doesn't border
	# on the last row, but extends to the start of the next line.
	set txt1 [getText $pos0 [pos::prevLineEnd $pos1]]
	set txt2 [doSuffixText $which $suffix $txt1]\r
	set txt1 ${txt1}\r
    } else {
	# Default routine.
	set txt1 [getText $pos0 $pos1]
	set txt2 [doSuffixText $which $suffix $txt1]
    }
    if {$txt1 eq $txt2} {return}
    replaceText $pos0 $pos1 $txt2
    if {$reselect} {
	selectText [pos::fromRowCol $row0 $col0] [pos::fromRowCol $row1 $col1]
    } else {
	goto  [pos::fromRowCol $row0 $col0]
    }
}

proc prevLineStart {args} {
    win::parseArgs w pos
    return [lineStart -w $w [pos::math -w $w [lineStart -w $w $pos] - 1]]
}

proc forwardDeleteUntil {{c ""}} {
    if {$c == ""} {
	status::msg "Forward delete up to next:"
	set c [getChar]
    }
    set p [lindex [search -s -n -f 1 -r 1 [quote::Regfind $c] [getPos]] 0]
    if {$p != ""} {
	deleteText [getPos] [pos::math $p + 1]
    }
}

proc forwardDeleteWhitespace {} {
    set p [lindex [search -s -n -f 1 -r 1 "\[^ \t\r\n\]" [getPos]] 0]
    if {$p != ""} {
	deleteText [getPos] $p
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "leadingTabsToSpaces" --
 # "leadingSpacesToTabs" --
 # "allTabsToSpaces" --
 # "allSpacesToTabs" --
 # 
 # Called directly by the Text menu proc, pass to [convertWhitespace] with no
 # additional arguments.  These can also be called by any other code.  All
 # procs can accept
 # 
 #   ?-w window? ?pos0? ?pos1?
 # 
 # as arguments, though all are optional.  If no arguments are given, a
 # message will be put in the status bar window.  All procs return the
 # number of changes made in the given region.
 # 
 # --------------------------------------------------------------------------
 ##

proc leadingTabsToSpaces {args} {
    set results [eval convertWhitespace leadingSpaces $args]
    if {![llength $args]} {status::msg [lindex $results 1]}
    return [lindex $results 0]
}
proc leadingSpacesToTabs {args} {
    set results [eval convertWhitespace leadingTabs $args]
    if {![llength $args]} {status::msg [lindex $results 1]}
    return [lindex $results 0]
}
proc allTabsToSpaces {args} {
    set results [eval convertWhitespace allSpaces $args]
    if {![llength $args]} {status::msg [lindex $results 1]}
    return [lindex $results 0]
}
proc allSpacesToTabs {args} {
    set results [eval convertWhitespace allTabs $args]
    if {![llength $args]} {status::msg [lindex $results 1]}
    return [lindex $results 0]
}

##
 # --------------------------------------------------------------------------
 # 
 # "convertWhitespace" --
 # 
 # 'to' is one of the options in the switch below.
 # 
 # Additional 'args' can specify window and positions, looking like
 # 
 #   ?-w window? ?pos0? ?pos1?
 # 
 # If no arguments are given, any selection (or the boundaries of the
 # current line) in the current window are used for the initial conversion
 # text, after being extended to include the start of the first line and
 # the end of the last.  If there are changes to be made, the text is
 # replaced and the specified region is highlighted once again.  Returns a
 # two item list containing the number of conversions performed in the
 # selection and an informative message that can be delivered to the user
 # by the calling proc.
 # 
 # --------------------------------------------------------------------------
 ##

proc convertWhitespace {to args} {
	
    # Preliminaries
    win::parseArgs w {pos0 ""} {pos1 ""}
    if {[win::getInfo $w read-only]} {
	beep ; status::msg "Read-only!" ; return -code return
    }
    if {![string length $pos0]} {set pos0 [getPos -w $w]}
    if {![string length $pos1]} {set pos1 [selEnd -w $w]}
    watchCursor
    # Confirm, adjust positions.
    set pos0 [pos::lineStart -w $w $pos0]
    if {[pos::compare -w $w $pos0 == $pos1]} {
	set pos1 [pos::nextLineStart -w $w $pos0]
    } elseif {[pos::compare -w $w $pos1 != [pos::lineStart -w $w $pos1]]} {
	set pos1 [pos::nextLineStart -w $w $pos1]
    }   
    selectText -w $w $pos0 $pos1
    # Convert whitespace.
    set count 0
    switch -- $to {
	"leadingTabs" {
	    set lines 0
	    set space [string repeat " " [win::getInfo $w tabsize]]
	    set pat   {^([\t ]* [\t ]*)([^\r\n]*$)}
	    foreach line [split [getSelect -w $w] \r\n] {
		incr lines
		if {[regexp $pat $line -> leadingWhite txt]} {
		    regsub -all -- $space $leadingWhite "\t" leadingWhite
		    regsub -all -- { +\t} $leadingWhite "\t" leadingWhite
		    if {("${leadingWhite}${txt}" ne $line)} {
			set line "${leadingWhite}${txt}"
			incr count
		    } 
		}
		lappend results $line
	    }
	    if {$count} {
		replaceAndSelectText -w $w $pos0 $pos1 [join $results \r]
		if {$lines > 1}  {incr lines -1}
		if {$lines == 1} {set what line} else {set what lines}
		set what1 "${lines} ${what}, ${count} leading space string"
		set what2 "converted to tab"
	    }   
	}
	"leadingSpaces" {
	    set lines 0
	    set space [string repeat " " [win::getInfo $w tabsize]]
	    set pat   {^([\t ]*\t[\t ]*)([^\r\n]*$)}
	    foreach line [split [getSelect -w $w] \r\n] {
		incr lines
		if {[regexp $pat $line -> leadingWhite txt]} {
		    regsub -all -- $space $leadingWhite "\t" leadingWhite
		    regsub -all -- { +\t} $leadingWhite "\t" leadingWhite
		    regsub -all -- {\t} $leadingWhite $space leadingWhite
		    set line "${leadingWhite}${txt}"
		    incr count
		}
		lappend results $line
	    }
	    if {$count} {
		replaceAndSelectText -w $w $pos0 $pos1 [join $results \r]
		if {$lines > 1} {incr lines -1}
		if {$lines == 1} {set what line} else {set what lines}
		set what1 "${lines} ${what}, ${count} leading tab"
		set what2 "converted to space"
	    }   
	}
	"allTabs" {
	    set tabs1 [regexp -all {\t} [getSelect -w $w]]
	    spacesToTabs -w $w
	    selectText -w $w $pos0 [selEnd -w $w]
	    set tabs2 [regexp -all {\t} [getSelect -w $w]]
	    set count [expr {$tabs2 - $tabs1}]
	    set what1 "$count space string"
	    set what2 "converted to tab"
	}
	"allSpaces" {
	    set count [regexp -all {\t} [getSelect -w $w]]
	    tabsToSpaces -w $w
	    selectText -w $w $pos0 [selEnd -w $w]
	    set what1 "$count tab"
	    set what2 "converted to space string"
	}
	default {
	    error "Unsupported option: '$to'"
	}
    }
    # Report results.
    if {!$count} {
	set msg "No changes."
    } elseif {$count == 1} {
	set msg "${what1} ${what2}."
    } else {
	set msg "${what1}s ${what2}s."
    }
    return [list $count $msg]
}

##
 # --------------------------------------------------------------------------
 # 
 # "spacesToTabs" --
 # 
 # Formerly defined in the core, converts all space runs in a given region
 # to tabs.  Accepts arguments of
 #  
 #   ?-w win?  ?from to?
 #   
 # If no positions are given, the current selection (if any) is used,
 # otherwise the contents of the line containing the cursor are converted.
 # Whatever region is initially specified, it will be extended to include
 # the start of the first line and the end of the last.  After replacing
 # the text, the cursor is left at the start of the next line following
 # the original region, consistent with Alpha 7.x behavior.  Returns the
 # number of space runs converted.
 #   
 # --------------------------------------------------------------------------
 ##

proc spacesToTabs {args} {
    
    # Preliminaries
    win::parseArgs w {pos0 ""} {pos1 ""}
    if {[win::getInfo $w read-only]} {
	beep ; status::msg "Read-only!" ; return 0
    }
    if {![string length $pos0]} {set pos0 [getPos -w $w]}
    if {![string length $pos1]} {set pos1 [selEnd -w $w]}
    # Confirm, adjust positions.
    if {[pos::compare -w $w $pos0 == $pos1]} {
	error "Cancelled -- 'tabsToSpaces' require a selection."
    }
    set pos0 [pos::lineStart -w $w $pos0]
    if {[pos::compare -w $w $pos0 == $pos1]} {
	set pos1 [pos::nextLineStart -w $w $pos0]
    } elseif {[pos::compare -w $w $pos1 != [pos::lineStart -w $w $pos1]]} {
	set pos1 [pos::nextLineStart -w $w $pos1]
    }       
    selectText -w $w $pos0 $pos1
    # First convert all tabs to spaces.
    set count1 [tabsToSpaces -w $w $pos0 $pos1]     
    set pos1 [selEnd -w $w]
    # Convert all relevant space strings to tabs.
    set count2 0
    set idx2 [win::getInfo [win::Current] tabsize]
    set idx1 [expr {$idx2 - 1}]
    foreach line [split [getText -w $w $pos0 $pos1] "\r\n"] {
	set txt  ""
	set txt1 [string range $line 0 $idx1]
	while {[string length $txt1] == $idx2} {
	    incr count2 [regsub { +$} $txt1 "\t" txt2]
	    append txt $txt2
	    set line [string range $line $idx2 end]
	    set txt1 [string range $line 0 $idx1]
	}
	lappend results ${txt}${txt1}
    }
    set count [expr $count2 - $count1]
    set txt [join $results \r]
    replaceText -w $w $pos0 $pos1 $txt
    goto [pos::math $pos0 + [string length $txt]]
    return $count
}

##
 # --------------------------------------------------------------------------
 # 
 # "tabsToSpaces" --
 # 
 # Formerly defined in the core, converts all tabs in a given region to
 # space runs corresponding to the visual column at the end of each tab.
 # Accepts arguments of
 #  
 #   ?-w win?  ?from to?
 #   
 # If no positions are given, the current selection (if any) is used,
 # otherwise the contents of the line containing the cursor are converted.
 # Whatever region is initially specified, it will be extended to include
 # the start of the first line and the end of the last.  After replacing
 # the text, the cursor is left at the start of the next line following
 # the original region, consistent with Alpha 7.x behavior.  Returns the
 # number of tabs converted.
 #   
 # --------------------------------------------------------------------------
 ##

proc tabsToSpaces {args} {
    
    # Preliminaries
    win::parseArgs w {pos0 ""} {pos1 ""}
    if {[win::getInfo $w read-only]} {
	beep ; status::msg "Read-only!" ; return 0
    }
    if {![string length $pos0]} {set pos0 [getPos -w $w]}
    if {![string length $pos1]} {set pos1 [selEnd -w $w]}
    # Confirm, adjust positions.
    if {[pos::compare -w $w $pos0 == $pos1]} {
	error "Cancelled -- 'tabsToSpaces' require a selection."
    }
    set pos0 [pos::lineStart -w $w $pos0]
    if {[pos::compare -w $w $pos0 == $pos1]} {
	set pos1 [pos::nextLineStart -w $w $pos0]
    } elseif {[pos::compare -w $w $pos1 != [pos::lineStart -w $w $pos1]]} {
	set pos1 [pos::nextLineStart -w $w $pos1]
    }       
    selectText -w $w $pos0 $pos1
    # Convert all tabs to spaces.
    set count 0
    set tabsize [win::getInfo [win::Current] tabsize]
    foreach line [split [getSelect -w $w] \r\n] {
	while {[regexp -indices -- {\t} $line match]} {
	    incr count
	    set idx0 [expr {[lindex $match 0] - 1}]
	    set idx1 [expr {[lindex $match 1] + 1}]
	    set txt0 [string range $line 0 $idx0]
	    set idx2 [expr {[lindex $match 0] % $tabsize}]
	    set txt1 [string repeat " " [expr {$tabsize - $idx2}]]
	    set txt2 [string range $line $idx1 end]
	    set line "${txt0}${txt1}${txt2}"
	}
	lappend results $line
    }
    set txt [join $results \r]
    if {$count} {replaceText -w $w $pos0 $pos1 $txt}
    goto [pos::math $pos0 + [string length $txt]]
    return $count
}

##
 # --------------------------------------------------------------------------
 # 
 # "replaceAndSelectText" --
 # 
 # All versions of [replaceText] in the Alpha* binaries attempt to reselect
 # any prior selection after any text window is replaced.  This can get
 # tricky if, say, the selection starts in the middle of the region to be
 # replaced but extends beyond its ending position.  This should be called if
 # you want to not only replace text but also ensure that it is selected.
 # Accepts args of
 # 
 #   ?-w window? ?pos0? ?pos1?
 # 
 # --------------------------------------------------------------------------
 ##

proc replaceAndSelectText {args} {
    win::parseArgs w {pos0 ""} {pos1 ""} args
    if {[win::getInfo $w read-only]} {
        beep ; status::msg "Read-only!" ; return 0
    }
    if {![string length $pos0]} {set pos0 [getPos -w $w]}
    if {![string length $pos1]} {set pos1 [selEnd -w $w]}
    set txt [join $args ""]
    replaceText -w $w $pos0 $pos1 $txt
    set pos1 [pos::math -w $w $pos0 + [string length $txt]]
    selectText -w $w $pos0 $pos1
}

#• upcaseRegion - convert all lowercase letters to 
#  uppercase in the current region
proc upcaseRegion {args} {
    requireSelection
    win::parseArgs w
    replaceAndSelectText -w $w [getPos -w $w] [selEnd -w $w] \
      [string toupper [getSelect -w $w]]
    return
}

#• downcaseRegion - changes all uppercase letters to 
#  lowercase in current region
proc downcaseRegion {args} {
    requireSelection
    win::parseArgs w
    replaceAndSelectText -w $w [getPos -w $w] [selEnd -w $w] \
      [string tolower [getSelect -w $w]]
    return
} 

# ===========================================================================
# 
# .