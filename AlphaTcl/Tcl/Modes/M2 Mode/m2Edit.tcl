# to autoload this file (tabsize:8)
proc m2Edit.tcl {} {}

#####################################################################################
# 
#   Author    Date        Modification
#   ------    ----        ------------
#    af       21.02.00    Replacing braces in all regexp statements like 
#                          regexp {[ \t]*PROCEDURE[ \t]+([^\s;(]+)} $t all procName
# 			  with quotes and preceeding brackets "[" and "]" with "\" like
# 			   regexp "\[ \t\]*PROCEDURE\[ \t\]+(\[^\\r;(\]+)" $t all procName
#                         whenever a "\t" is in the expression (hint by 
#                         Dominique Dhumier).  Since I'm not sure how well the
#                         new expressions really are, I have left the previous ones
#                         as comments before the new ones.
#    af       20.02.05    v1.8 -> v1.9 -> v1.10 -> v1.11
#                         - Fixing procs M2::getCurLine, M2::discardBullet,
#                           M2::jumpToTemplatePlaceHolder, M2::getIndentation, 
#                           M2::correctIndentation, M2::indentCurLine, M2::indentLine, 
#                           M2::modulaTab



#================================================================================
# ×××× M2 Editing (also in templates) and Moving around in a file ×××× #
#================================================================================

namespace eval M2 {}


#================================================================================
proc M2::getCurLine {args} {
    win::parseArgs w
    set pos [getPos -w $w]
    set start [pos::lineStart -w $w $pos]
    set end [pos::nextLineStart -w $w $pos]
    set text [getText -w $w $start $end]
    regexp "(\[^\r\]*)\r?" $text dummyText text
    return $text
}

#================================================================================
proc M2::isNotMODModule {} {
    set firstWord [lindex [getText [minPos] [nextLineStart [minPos]]] 0]
    if {([set firstWord] == "MODULE") | ([set firstWord] == "IMPLEMENTATION")} {
	return 0
    } else {
	return 1
    }
}


#================================================================================
# M2::discardBullet performs a mode specific return, i.e. jumps out of the current line 
# (does NOT really break it, see proc M2::breakTheLine for that other behavior) and does 
# insert a new line which is indented according to context.  The latter means, that 
# indentation is done in a Modula-2 language specific way, either new line is 
# indented the same way as the previous line, e.g.
#
#          x := 7*y;
#          |<- hitting return makes new line and moves cursor here 
#              if cursor has been anywhere within above line
# 
# or is indented by one level more if the scope changes, e.g.
#
#     IF (a<=b) THEN
#       |<- hitting return makes new line and moves cursor here 
#           if cursor has been anywhere within above line
#     ELSE
#     END(*IF*);
#
# Note, uses procs M2::jumpOutOfLnAndReturn and M2::modulaTab. 

proc M2::discardBullet {args} {
    win::parseArgs w
    set oldPos [getPos -w $w]
    set matchStr "\[ \\t\]*¥"
    set end [lindex [search -w $w -s -r 1 -f 1  -i 0 -n -- $matchStr $oldPos] 1]
    if {$end != ""} then {
	set newPos [pos::math -w $w $end - 1]
	selectText -w $w $newPos $end
	# set text [getText $newPos $end]
	# alertnote "pos $pos, end $end, text = '$text'"
	# alertnote "in M2::discardBullet"
	if { [isSelection -w $w] } { deleteSelection -w $w }
	if {[pos::compare -w $w $oldPos == $newPos]} then {
	    set moved 0
	} else {
	    set moved 1
	}
	# alertnote "moved = $moved"
	return $moved
    } else {
	return 0
    }
}

proc M2::jumpToTemplatePlaceHolder {args} {
    global M2::returnWords
    global M2::returnCompleteWords
    global M2::posBeforeJumpOutOfLn
    global M2::selEndBeforeJumpOutOfLn
    win::parseArgs w
    
    # returns 0 nothing more needs to be done by callee, was just a jump
    #         1 just an additional action by callee necessary (no indentation)
    #         2 same as 1 but do also add indentation
    #         3 similar to 1 but no language specific handling could be determined
    #         4 opposite of 2, i.e. unindent (M2::unIndent)
    set M2::posBeforeJumpOutOfLn [getPos -w $w]
    set M2::selEndBeforeJumpOutOfLn [selEnd -w $w]
    set line [M2::getCurLine -w $w]
    set pos [getPos -w $w]
    set start [pos::lineStart -w $w $pos]
    set first [M2::firstWord $line]
    set first [M2::trimString $first]
    
    # Allow for breaking a line if cursor is exactly before ELSE
    set elseBegin [pos::math $start + [string first "ELSE" $line]]
    if { [pos::diff $pos $elseBegin] == 0 } {
	if {$first == "IF"} {
	    return 1
	} else {
	    # call for unindent since first is not IF
	    return 4
	}
    }
    # Allow for breaking a line if cursor is exactly before END
    set endBegin [pos::math $start + [string first "END" $line]]
    if { [pos::diff $pos $endBegin] == 0 } {
	if { ($first == "IF") | ($first == "ELSE") | ($first == "WHILE") | ($first == "FOR") | ($first == "WITH") } {
	    return 1
	} else {
	    # call for unindent since first is not IF
	    return 4
	}
    }
    
    # Now look at first
    if {[lsearch " [set M2::returnWords] " $first] > -1} {
	# reserved word $first found
	set finish [pos::lineEnd -w $w $pos]
	set leftText [getText -w $w $start $pos]
	set rightText [getText -w $w $pos $finish]
	set next [M2::firstWord $rightText]
	set next [M2::trimString $next]
	if {[lsearch " [set M2::returnCompleteWords] " $first] > -1} {
	    if {$first == "IF"} {
		if { [regexp {^(.+)( ELSE )(.+)$} $line] } then {
		    if {[string first "ELSE" $leftText] > -1} {
			# M2::jumpOutOfLnAndReturn
			return 1
		    }
		    if {[string first "THEN" $leftText] > -1} {
			goto -w $w [pos::math -w $w $start + [string first "ELSE" $line] + 5]
			M2::discardBullet -w $w
			return 0
		    }
		    goto -w $w [pos::math -w $w $start + [string first "THEN" $line] + 5]
		    M2::discardBullet -w $w
		    return 0
		} elseif {[regexp {END} $line]} then {
		    return 1
		} else {
		    # its an "ordinary" IF spread over several lines (not on one single line)
		    # M2::jumpOutOfLnAndReturn
		    # M2::modulaTab
		    return 2
		}
	    }
	    if {$first == "FOR"} {
		if {[regexp {END} $line]} then {
		    return 1
		}
		if {[string first "BY" $leftText] > -1} {
		    # M2::jumpOutOfLnAndReturn
		    # M2::modulaTab
		    return 2
		}
		if {[string first "TO" $leftText] > -1} {
		    if { [regexp {^(.+)( BY )(.+)$} $line] } then {
			goto -w $w [pos::math -w $w $start + [string first "BY" $line] + 3]
			M2::discardBullet -w $w
			return 0
		    } elseif {[regexp {END} $line]} then {
			return 1
		    } else {
			# M2::jumpOutOfLnAndReturn
			# M2::modulaTab
			return 2
		    }
		}
		if {[string first ":=" $leftText] > -1} {
		    goto -w $w [pos::math -w $w $start + [string first "TO" $line] + 3]
		    M2::discardBullet -w $w
		    return 0
		}
		if {[string first "FOR" $leftText] > -1} {
		    goto -w $w [pos::math -w $w $start + [string first ":=" $line] + 3]
		    M2::discardBullet -w $w
		    return 0
		}
		goto -w $w [pos::math -w $w $start + [string first "FOR" $line] + 4]
		M2::discardBullet -w $w
		return 0
	    }
	    if {$first == "FROM"} {
		if {[string first "IMPORT" $leftText] > -1} {
		    # M2::jumpOutOfLnAndReturn
		    return 1
		}
		if {[string first "FROM" $leftText] > -1} {
		    goto -w $w [pos::math -w $w $start + [string first "IMPORT" $line] + 7]
		    M2::discardBullet -w $w
		    return 0
		}
		goto -w $w [pos::math -w $w $start + [string first "FROM" $line] + 5]
	    }
	    M2::discardBullet -w $w
	    return 0
	} else {
	    # M2::jumpOutOfLnAndReturn
	    # M2::modulaTab
	    if {($first == "PROCEDURE") && [M2::isNotMODModule]} {
		return 1
	    } elseif {[regexp {END} $line]} then {
		return 1
	    } else {
		return 2
	    }
	}
    } else {
	# no reserved word found
	# M2::jumpOutOfLnAndReturn
	return 3
    }
}

# Alternative to Tab (used to be plain Return)
proc M2::tabOrJumpOutOfLnAndReturn {} {
    global M2RightShift
    set result [M2::jumpToTemplatePlaceHolder]
    if !$result {return} else {
	switch $result {
	    1      { M2::jumpEOLNewLnIndent "" }
	    2      { M2::jumpEOLNewLnIndent $M2RightShift }
	    default { M2::jumpEOLNewLnIndent "" }
	}
    }	
}

# Tab handles auto place holders in template supported Modula-2 constructs like Return 
proc M2::tabKey {} {
    global M2RightShift
    set result [M2::jumpToTemplatePlaceHolder]
    if !$result {return} else {
	switch $result {
	    1      { if {![M2::discardBullet]} {M2::jumpEOLNewLnIndent "" } }
	    2      { if {![M2::discardBullet]} {M2::jumpEOLNewLnIndent $M2RightShift} }
	    default { if {![M2::discardBullet]} {M2::modulaTab} }
	}
    }	
}




#================================================================================
# returns the amount of white space needed from the begin of the line as defined
# by the first, non-white space line preceeding the line which contains pos. 
# This algorithm assumes that there are no tab (ASCII ht=11C) characters within 
# the theText. Preserves current position.
proc M2::getIndentation {args} {
    win::parseArgs w pos
    set curPos [getPos -w $w]
    set curLineBeg [pos::lineStart -w $w $pos]
    set nextLineBeg [pos::nextLineStart -w $w $pos]
    if {[pos::compare -w $w $curLineBeg != $nextLineBeg]} then {
	# it is not just an empty line at the end of the file
	# omit the carriage return at the end of the string
	set nextLineBeg [pos::math -w $w [pos::nextLineStart -w $w $pos] - 1]
    }
    selectText -w $w $curLineBeg $nextLineBeg
    if {[pos::compare -w $w $curLineBeg != $nextLineBeg]} { tabsToSpaces -w $w }
    set theText [getText -w $w $curLineBeg $nextLineBeg ] 
    # set theText [getText $curLineBeg [expr [nextLineStart $pos] - 1] ]
    # regexp {(^[ \t]*)(.*)$} $theText all theIndentation rest
    regexp "(^\[ \t\]*)(.*)$" $theText all theIndentation rest
    # alertnote "curLineBeg = $curLineBeg, theIndentation = '$theIndentation', rest = '$rest'"
    # Make sure this loops does not become infinite in case any needed AlphaTcl 
    # function gets corrupted, e.g. as this was the case in Alpha8 8.0b8 for previousLine!
    # The result was not only a crash of Alpha but also of the entire system. Pretty
    # nasty! Due to this safety belt, the following algo should fail only 
    # in case there are more than 1000 white space lines above current line.  
    set maxIter 1000
    set iter 0
    while {($rest == "") && ([pos::compare -w $w $curLineBeg != [minPos -w $w]]) && ($iter < $maxIter)} {
	# line was empty or just white space, search above
	    # Bug in Alpha8 8.0b8 - previousLine is broken (bug #951), fortunately prevLineSelect 
	    # works. http://www.maths.mq.edu.au/~steffen/Alpha/bugzilla/show_bug.cgi?id=951
	    # previousLine
	prevLineSelect -w $w
	set pos [getPos -w $w]
	selectText -w $w $pos $pos
	# alertnote "in M2::getIndentation pos = $pos / [pos::toRowChar $pos]"
	set otherLineBeg [pos::lineStart -w $w $pos]
	set nextLineBeg [pos::math -w $w [pos::nextLineStart -w $w $pos] - 1]
	# selectText $otherLineBeg $nextLineBeg
        if {[pos::compare -w $w [getPos -w $w] != [selEnd -w $w]]} { tabsToSpaces -w $w }
	set theText [getText -w $w $otherLineBeg $nextLineBeg ]
	# regexp {(^[ \t]*)(.*)$} $theText all theIndentation rest
	regexp "(^\[ \t\]*)(.*)$" $theText all theIndentation rest
	set iter [expr $iter + 1]
    }
    goto -w $w $curPos
    return $theIndentation
}

#================================================================================
# Moves the cursor to a new line next, next to the current one and indents 
# the insertion (cursor) by inserting white space with what's returned by 
# M2::getIndentation.
proc M2::jumpOutOfLnAndReturn {} {
    global M2RightShift
    global M2::posBeforeJumpOutOfLn
    global M2::selEndBeforeJumpOutOfLn
    set M2::posBeforeJumpOutOfLn [getPos]
    set M2::selEndBeforeJumpOutOfLn [selEnd]
    if { [isSelection] } { deleteSelection }
    set whiteSpace [M2::getIndentation [getPos]]
    set result [M2::jumpToTemplatePlaceHolder]
    endOfLine
    if {$result == 2} then { set whiteSpace "$whiteSpace$M2RightShift" }
    insertText "\r$whiteSpace"
}

#================================================================================
# Very similar to M2::jumpOutOfLnAndReturn, but does no $M2RightShift.
proc M2::jumpOutOfLnAndRet {} {
    global M2RightShift
    global M2::posBeforeJumpOutOfLn
    global M2::selEndBeforeJumpOutOfLn
    set M2::posBeforeJumpOutOfLn [getPos]
    set M2::selEndBeforeJumpOutOfLn [selEnd]
    if { [isSelection] } { deleteSelection }
    set whiteSpace [M2::getIndentation [getPos]]
    endOfLine
    insertText "\r$whiteSpace"
}


#================================================================================
# Similar to M2::jumpOutOfLnAndReturn but no scope or other language specific context 
# analyzed; on the other hand it accepts some identation amount to be added (allows
# for single Cmd^Z undo). Basic routine needed by many other scripts or template 
# procedures.  Needs M2::getIndentation.
proc M2::jumpEOLNewLnIndent {indentation} {
	# alertnote "In M2::jumpEOLNewLnIndent at begin"
	if { [isSelection] } { deleteSelection }
	set whiteSpace "[M2::getIndentation [getPos]]$indentation"
	endOfLine
	insertText "\r$whiteSpace"
}

#================================================================================
# M2 Carriage return but skips first next line. This is convenient, e.g. in
# following situaition
# 
#  PROCEDURE MyProc;
#  BEGIN
#    |<-   here is the cursor now
#  END MyProc;
#  |<-   here you would like to jump to continue typing
# 
#  use M2::skipLnReturn (bound to CMD-RETURN) to get the desired result.
proc M2::skipLnReturn {} {
	global M2::posBeforeJumpOutOfLn
	global M2::selEndBeforeJumpOutOfLn
	# alertnote "In M2::skipLnReturn at begin"
	set curPos [getPos]
	set curSelEnd [selEnd]
	if { [isSelection] } { deleteSelection }
	endOfLine
	forwardChar
	M2::jumpOutOfLnAndReturn
	set M2::posBeforeJumpOutOfLn $curPos
	set M2::selEndBeforeJumpOutOfLn $curSelEnd
}

proc M2::openNewAbove {} {
	global M2::posBeforeJumpOutOfLn
	global M2::selEndBeforeJumpOutOfLn
	# alertnote "In M2::openNewAbove at begin"
	set curPos [getPos]
	set curSelEnd [selEnd]
	if { [isSelection] } { deleteSelection }
	beginningOfLine
	backwardChar
	M2::jumpOutOfLnAndReturn
	set M2::posBeforeJumpOutOfLn $curPos
	set M2::selEndBeforeJumpOutOfLn $curSelEnd
}

proc M2::skipPrevLnOpenNew {} {
	global M2::posBeforeJumpOutOfLn
	global M2::selEndBeforeJumpOutOfLn
	# alertnote "In M2::skipPrevLnOpenNew at begin"
	set curPos [getPos]
	set curSelEnd [selEnd]
	if { [isSelection] } { deleteSelection }
	beginningOfLine
	backwardChar
	beginningOfLine
	backwardChar
	M2::jumpOutOfLnAndReturn
	set M2::posBeforeJumpOutOfLn $curPos
	set M2::selEndBeforeJumpOutOfLn $curSelEnd
}
	


#================================================================================
# Combines effect of M2::breakTheLine and M2::indentCurLine, was breakLineAndIndent
proc M2::carriageReturn {} {
    global M2RightShift
    # alertnote "In M2::carriageReturn at begin"
    if { [isSelection] } { deleteSelection }
    set curPos [getPos]
    set result [M2::jumpToTemplatePlaceHolder]
    # the following would allow to jump within line
    # if !$result {return}
    # alertnote "In M2::carriageReturn: result = $result"
    set whiteSpace [M2::getIndentation $curPos]
    if {$result == 2} then { 
	insertText "\r${whiteSpace}${M2RightShift}" 
    } elseif {$result == 4} then {
	insertText "\r${whiteSpace}"
	M2::unIndent
    } else { 
	insertText "\r${whiteSpace}" 
    }
}


#================================================================================
# Breaks the line at the current position (old fashioned plain-vanilla return 
# without any indentation)
proc M2::breakTheLine {} {
    # alertnote "In M2::breakTheLine at begin"
    if { [isSelection] } { deleteSelection }
    insertText "\r"
}

#================================================================================
# Moves insertion point to the indentation position (as returned by M2::getIndentation)
# within same line
# Note, is based on M2::getIndentation. 
proc M2::indentCurLine {args} {
    win::parseArgs w
    # alertnote "In M2::indentCurLine at begin"
    set beg [pos::lineStart -w $w [getPos -w $w]]
    previousLine -w $w
    set whiteSpace [M2::getIndentation -w $w [getPos -w $w]]
    goto -w $w $beg
    insertText -w $w "$whiteSpace"
}

#================================================================================
# In contrast to M2::indentCurLine does also really indent one level further
proc M2::indentLine {args} {
    win::parseArgs w
    # alertnote "In M2::indentLine at begin"
    M2::indentCurLine -w $w
    M2::modulaTab -w $w
}

#================================================================================
# Used by smartPaste feature (package) which unfortunately assumes, this procedure
# is only called if the current line contains only whitespace (?)
proc M2::correctIndentation {args} {
    global M2RightShift
    win::parseArgs w pos {next ""}
    # alertnote "In M2::correctIndentation at begin"
    set curPos [getPos -w $w]
    set whiteSpace [M2::getIndentation -w $w $pos]
    # assume this routine is never called if current line contains something <> white-space
    previousLine -w $w
    # make sure not to leave current line by backwardWord in case it contains only a single word
    endOfLine -w $w
    backwardWord -w $w
    set result [M2::jumpToTemplatePlaceHolder -w $w]
    if {$result != 0} then { goto -w $w $curPos }
    if {$result == 2} then { set whiteSpace "$whiteSpace$M2RightShift" }
    # alertnote "result = $result / length(whiteSpace) = [string length $whiteSpace]"
    # maybe the following helps copyRing to collaborate better with smartPaste?
    insertText -w $w $whiteSpace
    return [string length $whiteSpace]
}


#================================================================================
# Moves current line such that its first non white-space char is indented
# the same as the previous line
proc M2::adjCurLnToIndentAbove {} {
    # alertnote "In M2::adjCurLnToIndentAbove at begin"
    set oldPos [getPos]
    set beg [lineStart [getPos]]
    previousLine
    set whiteSpace [M2::getIndentation [getPos]]
    goto $beg
    set oldPos [getPos]
    oneSpace
    set newPos [getPos]
    if {[pos::compare $oldPos != $newPos]} then {
	# oneSpace has changed position since there was actually
	# some white space to the right of the current position
	backSpace
    }
    insertText "$whiteSpace"
}

#================================================================================
# Moves current line such that its first non white-space char is indented
# the same as the next non-white space line
proc M2::adjCurLnToIndentBelow {} {
    # alertnote "In M2::adjCurLnToIndentBelow at begin"
    set beg [lineStart [getPos]]
    endOfLine
    forwardWord
    set whiteSpace [M2::getIndentation [getPos]]
    goto $beg
    set oldPos [getPos]
    oneSpace
    set newPos [getPos]
    if {[pos::compare $oldPos != $newPos]} then {
	# oneSpace has changed position since there was actually
	# some white space to the right of the current position
	backSpace
    }
    insertText "$whiteSpace"
}


#================================================================================
proc M2::unIndent {} {
    global M2RightShift
    # alertnote "In M2::unIndent at begin"
    set count [string length $M2RightShift]
    set beg [lineStart [getPos]]
    for {set i 0} {$i < $count} {incr i} {
	if {[pos::compare [getPos] > $beg]} then {backwardCharSelect}
    }
    if { [isSelection] } { deleteSelection }
}

#================================================================================
# Indents insertion point from current position by M2RightShift
proc M2::modulaTab {args} {
    global M2RightShift
    win::parseArgs w
    # alertnote "In M2::modulaTab at begin"
    insertText -w $w $M2RightShift
}


#================================================================================
proc M2::resumeBeforeCarRet {} {
    global M2::posBeforeJumpOutOfLn
    global M2::selEndBeforeJumpOutOfLn
    # alertnote "In M2::resumeBeforeCarRet: at begin"
    if {[info exists M2::posBeforeJumpOutOfLn] && [info exists M2::selEndBeforeJumpOutOfLn]} {
	selectText [set M2::posBeforeJumpOutOfLn] [set M2::selEndBeforeJumpOutOfLn]
    }
}

# Initialize M2::posBeforeJumpOutOfLn and M2::selEndBeforeJumpOutOfLn
set M2::posBeforeJumpOutOfLn [minPos]
set M2::selEndBeforeJumpOutOfLn [minPos]


#================================================================================
proc M2::newLnAtSameCol {} {
    # alertnote "In M2::newLnAtSameCol at begin"
    if { [isSelection] } { deleteSelection }
    set pos [getPos]
    set col [pos::diff [lineStart $pos] $pos]
    endOfLine
    set whiteSpace ""
    for {set i 0} {$i < $col} {incr i} {
	set whiteSpace "$whiteSpace "
    }
    insertText "\r$whiteSpace"
}


#================================================================================
# Does completions of templates if preceeding reserved word is matched. Triggered
# with the space you typically type after a reserved word (I think much more
# comfortable than Alpha's conventional completion (but, BTW, which does also work 
# the conventional way).
proc M2::modulaSpace {} {
    global M2::spaceWords
    # alertnote "In M2::modulaSpace at begin"
    set line [M2::getCurLine]
    set first [M2::firstWord $line]
    set first [M2::trimString $first]
    set rest [M2::restWord $line]
    set rest [M2::trimString $rest]
    if {[lsearch " [set M2::spaceWords] " $first] > -1} {
	if {[string length $rest] > 0} {
	    deleteText [getPos] [selEnd]
	    insertText " "
	} else {
	    if {[catch M2::template$first]} {
		beep
		alertnote "Template for $first not defined"
	    } 			
	}
    } else {
	deleteText [getPos] [selEnd]
	insertText " "
    }
}

#================================================================================
# The actual completion procedure of M2 mode.  Kept here for upward compatibility
# and support of the traditional M2 menu. The latter offers also most templates, 
# which offer more comfort than just a completion (file, window handling etc. all 
# accessible with a single menu command!). IMPLEMENTATION NOTE: If this routine
# can't expand itself it will call the predefined completion routine, making
# words already in existence available for completion (the usual behavior 
# expected by Alpha users).
proc M2::expandSpace {} {
    global M2::expandWords
    global M2::doubleDefinedWords
    set pos [getPos]
    backwardWord
    set bPos [getPos]
    if {[pos::compare $bPos == [pos::math [minPos] + 1]]} {
	set text " "
	regexp "\[A-Za-z\]" [lookAt [minPos]] text
	if {$text != " "} {
	    set bPos [minPos]
	}
    }
    
    forwardWord
    set fPos [getPos]
    goto $pos
    set origWord [getText $bPos $fPos]
    set word [string toupper $origWord]
    set ind [lsearch [set M2::expandWords] ${origWord}*]
    set thereIsCompletion [lsearch [set M2::doubleDefinedWords] ${origWord}*]
    if {($ind == -1) | ($thereIsCompletion != -1)} {
	# wordCompletion does no longer work in Alpha > 7.x 
	bind::Completion
	return
    }
    set expandWord [lindex [set M2::expandWords] $ind]
    if {$expandWord != $origWord} {
	replaceText $bPos $fPos $expandWord
    } 
}

#================================================================================
proc M2::completePrevWord {} {
	set pos [getPos]
	backwardWord
	forwardWord
	bind::Completion
}

#================================================================================
proc M2::killWholeLine {} {
	goto [lineStart [getPos]]
	killLine
	M2::KillLnIfEmpty
}

#================================================================================
proc M2::KillPrevLnIfOnlyComment {} {
    previousLine
    set lnBeg [lineStart [getPos]]
    set lnEnd [pos::math [nextLineStart [getPos]] -1]
    set prevLnTxt [getText $lnBeg $lnEnd]
    # regexp {^[ \t]*\(\*.*\*\)[ \t]*$} $prevLnTxt
    if {[regexp "^\[ \t\]*\\(\\*.*\\*\\)\[ \t\]*$" $prevLnTxt ]} then {
	# line contains really just a comment, delete it
	killLine
	killLine
	return 1
    } else {
	# not just a comment, resume position
	nextLine
	return 0
    }
}

#================================================================================
proc M2::KillNextLnIfOnlyComment {} {
    nextLine
    set lnBeg [lineStart [getPos]]
    set lnEnd [pos::math [nextLineStart [getPos]] -1]
    set nextLnTxt [getText $lnBeg $lnEnd]
    # regexp {^[ \t]*\(\*.*\*\)[ \t]*$} $nextLnTxt
    if {[regexp "^\[ \t\]*\\(\\*.*\\*\\)\[ \t\]*$" $nextLnTxt ]} then {
	# line contains really just a comment, delete it
	previousLine
	killLine
	killLine
	return 1
    } else {
	# not just a comment, resume position
	previousLine
	return 0
    }
}


#================================================================================
proc M2::KillLnIfEmpty {} {
    set savePos [getPos]
    set lnBeg [lineStart [getPos]]
    set lnEnd [pos::math [nextLineStart [getPos]] -1]
    # beginningLineSelect appears to be buggy
    # endLineSelect
    selectText $lnBeg $lnEnd
    set theLine [getSelect]
    # regexp {^[ \t]*$} $theLine
    if {[regexp "^\[ \t\]*$" $theLine]} then {
	# is really empty line
	clear ; killLine 
	return 1
    } else {
	# not empty line
	goto $savePos
	return 0
    }
}

#================================================================================
proc M2::JoinToOneSpace {} {
    global M2::posBeforeJumpOutOfLn
    set M2::posBeforeJumpOutOfLn [getPos]
    endOfLine 
    deleteChar
    oneSpace
}


#================================================================================
proc M2::SplitLineAt {} {
    global M2::posBeforeJumpOutOfLn
    set M2::posBeforeJumpOutOfLn [getPos]
    M2::breakTheLine
    M2::indentLine
}

#================================================================================
proc M2::notAComment {args} {
    win::parseArgs win
    set pos [getPos -w $win]
    set end [selEnd -w $win]
    set comBeg [getText -w $win $pos [pos::math -w $win $pos + 2]]
    set comEnd [getText -w $win [pos::math -w $win $end -2] $end]
    # alertnote "pos = $pos / end = $end / comBeg = '$comBeg' / comEnd = '$comEnd'"
    if {($comBeg == "(*") && ($comEnd == "*)")} then {
	# alertnote "M2::notAComment = 0"
	return 0
    } else {
	if {([pos::compare -w $win $pos == $end]) || ([pos::compare -w $win $pos <= [minPos]]) || ([pos::compare -w $win $end >= [maxPos -w $win]])} then {
	    # abort if end reached
	    # alertnote "M2::notAComment = 0"
	    return 0
	} else {
	    # alertnote "M2::notAComment = 1"
	    return 1
	}
    }
}


#================================================================================
proc M2::selectM2Comment {} {
    balance
    set pos [getPos]
    set end [selEnd]
    if {[pos::compare $pos == $end]} {
	# first balance failed
	status::msg "Cursor not in comment, missing '(*', '*)', or non-paired (),{},\[\]"
	return {0 1}
    }
    while {([pos::compare $pos > [minPos]]) && ([pos::compare $end < [maxPos]]) && [M2::notAComment]} {
	balance
	set pos [getPos]
	set end [selEnd]
    }
    if {[pos::compare $pos == $end]} {
	status::msg "Couldn't find begin or end of comment, or it contains non-paired parantheses"
	return {0 0}
    } else {	
	status::msg "Comment selected"
	return {1 0}
    }
}

#================================================================================
proc M2::selectNestedM2Comment {args} {
    win::parseArgs win
    set comBeg [getPos -w $win]
    set comEnd [getPos -w $win]
    balance -w $win
    set pos [getPos -w $win]
    set end [selEnd -w $win]
    if {[pos::compare -w $win $pos == $end]} {
	# first balance failed
	status::msg ""  # clears Abort message
	return {0 1}
    }
    while {([pos::compare -w $win $pos > [minPos -w $win]]) && ([pos::compare -w $win $end < [maxPos -w $win]])} {
	while {([pos::compare -w $win $pos != $end]) && [M2::notAComment -w $win]} {
	    balance -w $win
	    set pos [getPos -w $win]
	    set end [selEnd -w $win]
	}
	if {[pos::compare -w $win $pos == $end]} {
	    # balance failed
	    status::msg ""  # clears Abort message
	    break
	} else {	
	    # is a comment
	    set comBeg $pos
	    set comEnd $end
	    # try one more
	    balance -w $win
	    set pos [getPos -w $win]
	    set end [selEnd -w $win]
	}
    }
    # now select last comment (if any)
    selectText -w $win $comBeg $comEnd
    if {([pos::compare -w $win $comBeg != $comEnd])} then {
	status::msg "Nested comment selected"
	return {1 0}
    } else {
	status::msg ""  # clears Abort message
	return {0 0}
    }
}


#================================================================================
proc M2::wrapComment {} {
    global leftFillColumn
    global M2RightShift
    global M2WrapRightMargin
    global fillColumn
    global M2::curAlphaV
    set selBeg0 [getPos]
    set selEnd0 [selEnd]
    set increment [string length $M2RightShift]
    set selComment [M2::selectM2Comment]
    set succeeded [lindex $selComment 0]
    set firstFailed [lindex $selComment 1]
    if !$succeeded {
	beep
	if $firstFailed {
	    status::msg "Cursor not in comment, missing '(*', '*)', or non-paired (),{},\[\]"
	} else {
	    status::msg "Couldn't find begin or end of comment, or it contains non-paired parantheses"
	}
	return
    }
    set firstPos [getPos]
    set lastPos [selEnd]
    set leftMargColumn [expr [lindex [pos::toRowCol $firstPos] 1] + $increment]
    if {[set M2WrapRightMargin] <= [set leftMargColumn]} {
	beep
	status::msg "Wrapping impossible,  M2_Fill Right Margin (= $M2WrapRightMargin) <= left margin (= $leftMargColumn)"
	selectText $selBeg0 $selEnd0
	return
    }
    # alertnote "pos = $pos / end = $end / firstPos = $firstPos / lastPos = $lastPos"
    goto [pos::math $firstPos + 2]
    # M2::jumpOutOfLnAndReturn
    insertText "\r"
    M2::indentCurLine
    set lastPos [matchIt "\(" [pos::math $firstPos +$increment]]
    set pos [getPos]
    set end [pos::math $lastPos +1]
    selectText $pos $end
    set tmpLeftFillColumn $leftFillColumn
    set tmpfillColumn $fillColumn
    if {[pos::compare [getPos] != [selEnd]]} { tabsToSpaces }
    # in Alpha8 tabsToSpaces deselects but fillRegion needs the selection
    selectText $pos $end
    if {[set M2::curAlphaV] <= "6.01"} {
	# Has old wrap behavior, which requires following statement
	set leftFillColumn $leftMargColumn
	set fillColumn $M2WrapRightMargin
    } else {
	# Has new wrap behavior
	set leftFillColumn $increment
	set fillColumn [expr $M2WrapRightMargin -$leftMargColumn]
    }
    fillRegion
    set leftFillColumn $tmpLeftFillColumn
    set fillColumn $tmpfillColumn
    goto [pos::math [matchIt "\(" [pos::math $firstPos +$increment]] -1]
    insertText "\r"
    M2::indentCurLine
    set curPos [getPos]
    goto [pos::math $curPos -2]
    M2::unIndent
    set topTxtLeftMargRow [lindex [pos::toRowCol $firstPos] 0]
    set topTxtLeftMargRow [expr $topTxtLeftMargRow +1]
    set topTxtLeftMarg [pos::fromRowCol $topTxtLeftMargRow 0]
    set textBeg [expr [lindex [pos::toRowCol $firstPos] 1] + $increment]
    set count [expr $textBeg]
    goto $topTxtLeftMarg
    if {[set M2::curAlphaV] <= "6.01"} {
	# Has old wrap behavior, which requires following statement
	for {set i 0} {$i < $count} {incr i} {
	    deleteChar
	}
    } else {
	for {set i 0} {$i < $increment} {incr i} {
	    deleteChar
	}
    }
    goto [pos::math $firstPos + 2]
    balance
    set end [selEnd]
    # delete extra line which was inserted by algorithm
    selectText $end [pos::math $end + 1]
    deleteSelection
    # to to begin of last line
    previousLine
    # Sometimes empty line between text and *) is created, cursors sits in it => clear it
    M2::KillLnIfEmpty
    status::msg "Comment wrapped"
}


#================================================================================
proc M2::wrapText {} {
    global leftFillColumn
    global fillColumn
    global M2WrapRightMargin
    global M2::curAlphaV
    # alertnote "In M2::wrapText at begin"
    set pos [getPos]
    set end [selEnd]
    if {[pos::compare $pos == $end]} {
	beep
	status::msg "Please make a selection"
	return
    }
    set firstPos [search -s -r 1 -f 1 -n -- "\[\^ \\t\\r\]" $pos]
    set firstPosBeg [lindex $firstPos 0]
    if {[pos::compare $firstPosBeg > $end]} {
	beep
	status::msg "No text in selection"
	return
    }
    set tmpLeftFillColumn $leftFillColumn
    set tmpfillColumn $fillColumn
    set leftMargColumn [lindex [pos::toRowCol [lindex $firstPos 0]] 1]
    if {[set M2WrapRightMargin] <= [set leftMargColumn]} {
	beep
	status::msg "Wrapping impossible,  M2_Fill Right Margin (= $M2WrapRightMargin) <= left margin (= $leftMargColumn)"
	selectText $pos $end
	return
    }
    if {[pos::compare [getPos] != [selEnd]]} { tabsToSpaces }
    # in Alpha8 tabsToSpaces deselects but fillRegion needs the selection
    selectText $pos $end
    if {[set M2::curAlphaV] <= "6.01"} {
	# Has old wrap behavior, which requires following statement
	set leftFillColumn $leftMargColumn
	set fillColumn $M2WrapRightMargin
    } else {
	# Has new wrap behavior
	set fillColumn [expr $M2WrapRightMargin - $leftMargColumn]
    }
    fillRegion
    set leftFillColumn $tmpLeftFillColumn
    set fillColumn $tmpfillColumn
    
    set topTxtLeftMargRow [lindex [pos::toRowCol [lindex $firstPos 0]] 0]
    set topTxtLeftMarg [pos::fromRowChar $topTxtLeftMargRow 0]
    set textBeg [lindex [pos::toRowCol [lindex $firstPos 0]] 1]
    set count [expr $textBeg]
    goto $topTxtLeftMarg
    if {[set M2::curAlphaV] <= "6.01"} {
	# Has old wrap behavior, which requires following statement
	for {set i 0} {$i < $count} {incr i} {
	    deleteChar
	}
    }
    goto $pos
    status::msg "Text wrapped"
}



#================================================================================
proc M2::encloseSelection {} {
    global M2modeVars
    set pos [getPos]
    set end [selEnd]
    if {[pos::compare $pos == $end]} {
	beep
	status::msg "Please make a selection"
	return
    }
    replaceText $pos $end "$M2modeVars(prefixString)[getText $pos $end]$M2modeVars(suffixString)"
    selectText $pos [pos::math $end + [string length $M2modeVars(prefixString)] + [string length $M2modeVars(suffixString)]]
}

#================================================================================
proc M2::unencloseSelection {} {
    global M2modeVars
    set pos [getPos]
    set end [selEnd]
    if {[pos::compare $pos == $end]} {
	beep
	status::msg "Please make a selection"
	return
    }
    set prefixLe [string length $M2modeVars(prefixString)]
    set suffixLe [string length $M2modeVars(suffixString)]
    if {[getText $pos [pos::math $pos + $prefixLe]] != "$M2modeVars(prefixString)"} {
	beep
	status::msg "Begin of selection different from '$M2modeVars(prefixString)'"
	return
    }
    if {[getText [pos::math $end - $suffixLe] $end] != "$M2modeVars(suffixString)"} {
	beep
	status::msg "End of selection different from '$M2modeVars(suffixString)'"
	return
    }
    replaceText [pos::math $end - $suffixLe] $end ""
    replaceText $pos [pos::math $pos + $prefixLe] ""
    selectText $pos [pos::math $end - $suffixLe - $prefixLe]
}

#================================================================================
proc M2::commentSelection {} {
    set pos [getPos]
    set end [selEnd]
    if {[pos::compare $pos == $end]} {
	beep
	status::msg "Please make a selection"
	return
    }
    if {[getText [pos::math $end - 1] $end] == "\r"} {
	# selection end is at begin of line => don't insert blank
	replaceText $pos $end "\(\*\. [getText $pos $end]\.\*\)"
	set addedChars 7
    } else {
	replaceText $pos $end "\(\*\. [getText $pos $end] \.\*\)"
	set addedChars 8
    }
    selectText $pos [pos::math $end + $addedChars]
}

#================================================================================
proc M2::uncommentSelection {} {
    set pos [getPos]
    set end [selEnd]
    if {[pos::compare $pos == $end]} {
	beep
	status::msg "Please make a selection"
	return
    }
    if {[pos::diff $pos $end] < 8} {
	beep
	status::msg "Selection to small"
	return
    }
    set leftSize 4 
    if {[getText $pos [pos::math $pos + $leftSize]] != "(*. "} {
	set leftSize 3
	if {[getText $pos [pos::math $pos + $leftSize]] != "(*."} {
	    beep
	    status::msg "Wrong left comment-start in selection"
	    return
	}
    }	
    set rightSize 4
    if {[getText [pos::math $end - $rightSize] $end] != " .*)"} {
	set rightSize 3
	if {[getText [pos::math $end - $rightSize] $end] != ".*)"} {
	    beep
	    status::msg "Wrong right comment-start in selection"
	    return
	}
    }
    replaceText [pos::math $end - $rightSize] $end ""
    replaceText $pos [pos::math $pos + $leftSize] ""
    selectText $pos [pos::math $end - $leftSize - $rightSize]
}


 
#================================================================================
# This procedure is a replacement for textManip.tcl uncommentLine, which
# does not properly reverse the effect of Alpha's menu command 
# "Text > Comment Line" (Cmd^D), since it does not call removeSuffix
proc M2::uncommentLine {} { 
	removePrefix; removeSuffix; 
	# deselect
	selectText [getPos] [getPos]
	# status::msg "Line uncommented"
}

#================================================================================
# This procedure is from Juan Falgueras, thanks!
proc M2::myWrapObject {left right} {
	set currentPos [getPos]
# 	set selected [isSelection]
	if {[isSelection]} then {
		replaceText $currentPos [selEnd] $left [getSelect] "$right¥"
	} else {
		insertText $left "¥" "$right¥"
	}
	goto $currentPos
# 	ring::+
	M2::tabKey
# 	return $selected
}

#================================================================================
proc M2::doM2ShiftLeft {} {
    global M2LeftShift
    if {![isSelection]} {M2::selectLine}
    set start [lineStart [getPos]]
    set end   [nextLineStart [pos::math [selEnd] -1]]
    selectText $start $end
    if {[pos::compare [getPos] != [selEnd]]} { tabsToSpaces }
    set increment [string length $M2LeftShift]
    for {set i $start} {[pos::compare $i < $end]} {set i [nextLineStart $i]} {
	if {[getText $i [pos::math $i + $increment]] != $M2LeftShift} {
	    beep
	    return
	} 
    }
    selectText $start $start
    for {set i $start} {[pos::compare $i < $end]} {set i [nextLineStart $i]} {
	set end [pos::math $end -$increment]
	goto $i
	replaceText $i [pos::math $i + $increment] ""
    }
    goto $start
    selectText $start $end
}


#================================================================================
proc M2::doM2ShiftRight {} {
    global M2RightShift
    if {![isSelection]} {M2::selectLine}
    set start [lineStart [getPos]]
    set end   [nextLineStart [pos::math [selEnd] -1]]
    selectText $start $end
    if {[pos::compare [getPos] != [selEnd]]} { tabsToSpaces }
    set increment [string length $M2RightShift]
    for {set i $start} {[pos::compare $i < $end]} {set i [nextLineStart $i]} {
	set end [pos::math $end + $increment]
	goto $i
	insertText $M2RightShift
    }
    goto $start
    selectText $start $end
}

#================================================================================
proc M2::selectLine {} {
    set pos [getPos]
    set start [lineStart $pos]
    set end [nextLineStart $pos]
    selectText $start $end
}



#================================================================================
proc M2::nextPlaceholder {} {
	M2::searchPlaceholder 1
}
proc M2::prevPlaceholder {} {
	M2::searchPlaceholder 0
}


#================================================================================
proc M2::searchPlaceholder {dir} {
    set pos [getPos]
    set depth 1
    if ($dir==1) {
	set push "(*."
	set pop  ".*)"
	if {[getSelect] != ""} {
	    set pos [pos::math $pos +1]
	}
	set add 3;
	set position [search -s -r 1 -f $dir -n -- "\\(\\*\\." $pos]
    } else {
	set push  ".*)"
	set pop   "(*."
	set pos [pos::math [selEnd] -4]
	set add -3;
	set position [search -s -r 1 -f $dir -n -- "\\.\\*\\)" $pos]
    }
    if {$position != ""} {
	set pos [pos::math [lindex $position 0] + $add]
	set str "(\\(\\*\\.)|(\\.\\*\\))"
	while {1} {
	    set limits [search -s -r 1 -f $dir -n -- "$str" $pos]
	    if {$limits == ""}  {
		status::msg "Not matched placeholder"
		beep
		return
	    }
	    set pos [lindex $limits 0]
	    set c [getText $pos [pos::math $pos +3]]
	    if {$c == $push} {
		incr depth
	    } 
	    if {$c == $pop} {
		if {[set depth [expr $depth-1]] == 0} {
		    if ($dir==1) {
			selectText [lindex $position 0] [pos::math $pos + 3]
		    } else {
			selectText $pos [lindex $position 1]
		    }
		    return
		}
	    }
	    set pos [pos::math $pos + $add]
	    if {[pos::compare $pos > [maxPos]]} {
		alertnote "makro error, please contact jth"
	    }
	}
    } else {
	status::msg "no more placeholders"
	beep
    }
}





# Reporting that end of this script has been reached
status::msg "m2Edit.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
    alertnote "m2Edit.tcl for Programing in Modula-2 loaded"
}
