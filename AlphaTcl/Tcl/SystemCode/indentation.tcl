## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "indentation.tcl"
 #                                          created: 07/27/1997 {01:08:08 am}
 #                                      last update: 03/21/2006 {01:23:51 PM}
 # Description:
 # 
 # Supports the correct (and sometimes automatic) indentation of text within
 # the current window.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # modified   by  rev reason
 # ---------- --- --- -----------
 # 2000-12-07 DWH 0.1 updated help text for electricReturn
 # 2001-09-26 JK      call to text::inCommentBlock replaced by call 
 #                    to text::isInDoubleComment (the former is obsolete)
 #                    
 # ==========================================================================
 ##

proc indentation.tcl {} {}

alpha::flag specialIndentForCaseLabel 0.1 Electrics {
    global
} description {
    Instructs Alpha to indent "case foo:" and "foo:" by only half an ordinary
    indentation unit, useful in C, C++, Java, and Jscr modes
} help {
    Enabling this feature tells Alpha to indent 'case foo:' and 'foo:' by
    only half an ordinary indentation unit.  This is primarily useful for C,
    C++, Java, Jscr modes.

    Preferences: Electrics
}

alpha::flag autoContinueComment 0.1 Electrics {
    global
} description {
    Automatically comments new lines created by pressing Return if the
    current line is already in a comment block
} help {
    The 'Auto Continue Comment' preference changes the behavior of pressing
    Return when the current line is in a commented block of text.
    
    Preferences: Electrics
    
    When it is turned on, pressing Return will automatically indent the newly
    created line and insert the proper comment character(s) before the
    cursor.  Pressing Control-Return will simply create a new line without
    doing any automatic indentation or insertion of comment characters.
}

alpha::flag autoWrapComments 0.1 Electrics {
    global
} description {
    Automatically wraps comments as you type, ignoring the current "Wrap"
    preference for the active window
} help {
    The 'Auto Wrap Comments' preference changes how lines are automatically
    wrapped as you type.
    
    Preferences: Electrics
    
    When it is turned on, text that is typed within a comment will be
    automatically wrapped, ignoring the current value of the Line Wrap
    preference of the active window.
}

alpha::flag indentUsingSpacesOnly 0.1 Electrics {
    global TeX
} description {
    Indents without inserting any Tab characters, only Space strings
} help {
    If set, do not use tabs to indent, but spaces only.  This is mostly
    useful for modes in which the 'tab' character has a special meaning, such
    as python or TeX (the latter usually only for TeX as a programming
    language, not as a document preparation system).

    Preferences: Electrics
}

alpha::flag commentsArentSpecialWhenIndenting 0.1 Electrics {
    global TeX
} description {
    Ignores previous commented text when searching backwards for the proper
    level of indentation to use for the current line
} help {
    When indenting, we always look back at previous lines to determine
    the correct current indentation level.  Normally the first such
    previous non-commented line that is found is used for this
    calculation (since comments are simply adornments and you might be in
    the habit of indenting your comments differently to your code/text).
    
    If this feature is active, then Alpha will look back for commented or
    non-commented lines, and simply make use of the first one in its
    calculation.  Often this makes little difference, but, for example if
    your files contain vast comments (especially .dtx files in TeX mode,
    for instance), it can lead to better editing performance if you
    activate this feature.

    Preferences: Electrics
}

namespace eval bind {}
namespace eval text {}

proc IndentLine {args} {
    return [eval bind::IndentLine $args]
}

# This function behaves exactly as if the user had typed the given
# text, character by character.  This means it can cause lines
# to wrap, indentation to occur, etc.
proc typeText {args} {
    win::parseArgs w text
    if {![win::checkIfWinToEdit $w]} {
	return
    }
    if {[isSelection -w $w]} {
	deleteSelection -w $w
    }
    # Insert each character, one by one, and ask AlphaTclCore to 
    # handle any wrapping as appropriate.
    foreach char [split $text {}] {
	insertText -w $w $char
	characterInsertedHook $w [getPos -w $w] $char
    }
    # Since we're mimicking typing, make sure that the final
    # position is visible to the user.  This is the only way
    # we have to do so (easily, anyway).
    goto -w $w [getPos -w $w]
}

proc normalLeftBrace {} {
    typeText "\{"
}
proc normalRightBrace {} {
    typeText "\}"
    blink [matchIt "\}" [pos::math [getPos] - 2]]
}
			
# ×××× Electric indentation ×××× #
proc bind::LeftBrace {} {
    if {![win::checkIfWinToEdit]} {
	return
    }
    if {[isSelection]} { deleteSelection }
    global electricBraces mode
    if {![info exists electricBraces] || !$electricBraces} {
	insertText "\{"
	return
    }
    hook::callProcForWin electricLeft
}

proc ::electricLeft {} {
    if {[text::isInComment [getPos]]} {
	insertText "\{"
	return
    }
    if {![catch {search -s -l \
      [lineStart [pos::math [lineStart [getPos]] - 1]] \
      -f 0 -r 0 "\}" [getPos]} res]} {
	set end [getPos]
	if {[pos::compare [getPos] != [maxPos]]} {
	    set end [pos::math $end + 1]
	}
	
	if {[regexp -- "\}\[ \t\r\n\]*else" [getText [lindex $res 0] $end]]} {
	    set res2 [search -s -f 0 -r 1 {else} [getPos]]
	    oneSpace
	    set text [getText [lindex $res2 0] [getPos]]
	    if {[lookAt [pos::math [getPos] - 1]] != " "} {
		append text " "
	    }
	    replaceText [pos::math [lindex $res 0] + 1] [getPos] " $text\{\r"
	    bind::IndentLine
	    return 
	}
    }
    set pos [getPos]
    set i [text::firstNonWsLinePos $pos]
    
    if {([pos::compare $i == $pos]) || ([lookAt [pos::math $pos - 1]] == " ")} {
	insertText "\{\r" [text::indentString $pos] [text::standardIndent]
    } else {
	insertText " \{\r" [text::indentString $pos] [text::standardIndent]
    }
}

proc ::electricRight {} {
    set pos [getPos]
    set start [lineStart $pos]
    
    if {[catch {matchIt "\}" [pos::math $pos - 1]} matched]} {
	insertText "\}"
	beep
	status::msg "No matching '\{'!"
	return
    }
    if {[text::isInComment [getPos]]} {
	insertText "\}"
	return
    }
    set text [getText [lineStart $matched] $matched]
    regexp -- "^\[ \t\]*" $text indentation
    if {[string trim [getText $start $pos]] != ""} {
	insertText "\r" $indentation "\}\r" $indentation
	blink $matched
	return
    }
    set text "${indentation}\}\r$indentation"
    replaceText $start $pos $text
    goto [pos::math $start + [string length $text]]
    if {[catch {blink [matchIt "\}" [pos::math $start - 2]]} err]} {
	status::msg $err
    }
}

proc bind::RightBrace {} {
    if {![win::checkIfWinToEdit]} {
	return
    }
    if {[isSelection]} { deleteSelection }
    global electricBraces mode
    if {![info exists electricBraces] || !$electricBraces} {
	insertText "\}"
	if {[catch {blink [matchIt "\}" [pos::math [getPos] - 2]]} err]} {
	    status::msg $err
	}
	return
    }
    hook::callProcForWin electricRight
}

proc bind::electricSemi {} {
    global electricSemicolon
    if {![win::checkIfWinToEdit]} {
	return
    }
    if {![info exists electricSemicolon] || !$electricSemicolon} {
	typeText ";"
    } else {
	hook::callProcForWin electricSemi
    }
}

proc ::electricSemi {} {
    if {[isSelection]} { deleteSelection }
    set pos [getPos]
    set text [getText [lineStart $pos] $pos]
    
    set inFor 0
    if {[string first "for" $text] != "-1"} {
	set len [string length $text]
	for {set i 0} {$i < $len} {incr i} {
	    switch -- [string index $text $i] {
		"("	{ incr inFor }
		")"	{ incr inFor -1 }
	    }
	}
    }
    
    insertText ";"
    if {!($inFor != 0 || [text::isInComment $pos] \
      || [text::isInString $pos] || [text::isEscaped $pos])} {
	hook::callProcForWin carriageReturn
    }
}

## 
 # -------------------------------------------------------------------------
 #	 
 # "bind::CarriageReturn" --
 #	
 # General purpose CR procedure.  This is bound to Return in the SystemCode,
 # and modes should avoid creating mode specific bindings which over-ride
 # this procedure.  Instead, they should define [<mode>::carriageReturn]
 # which will be called here when necessary.
 # 
 # If "autoContinueComment" is turned on and we are in a comment, then we
 # simply insert a "\r" followed by the current (er, previous) line's comment
 # character string.  We use two separate [insertText] calls so that each
 # action (the return, then the comment string) can be undone separately.
 # 
 # Otherwise, we attempt to call a mode specific proc, defaulting to the
 # SystemCode [::carriageReturn] which will then again try to use a mode's
 # procedure for determining the proper indentation.
 # 
 # If the "indentOnReturn" variable exists and is turned on, then the line
 # has already been properly indented.  Unless, however, we're in a comment.
 # If Return was pressed in the middle of a line moving the text to the next
 # line, there might be some whitespace between the Cursor and the start of
 # the text, i.e. within this comment where | represents the Cursor
 # 
 #     # this is a line| with more text
 # 
 # will end up like
 # 
 #     # this is a line
 #     # | with more text
 # 
 # In this case, because the user has said "Indent On Return", we need to
 # remove the whitespace between the Cursor and the text.  Again, this can be 
 # undone as a separate history item.
 # 
 # Outside of a comment, a similar issue arises, in which
 #  
 #     this is a line| with more text
 # 
 # will end up like
 # 
 #     this is a line
 #   | with more text
 # 
 # so the indentation is correct but the Cursor position is odd.  If the user 
 # said "Indent On Return", it seems reasonable to shift the Cursor to the
 # right so that text which is immediately typed is properly indented too!
 #  
 # -------------------------------------------------------------------------
 ##

proc bind::CarriageReturn {} {
    
    global autoContinueComment indentOnReturn
    
    if {![win::checkIfWinToEdit]} {
        return
    }
    if {[isSelection]} {
	deleteSelection
    }
    if {[info exists autoContinueComment] \
      && $autoContinueComment \
      && [text::isInComment [getPos] start]} {
	set inComment 1
	insertText "\r"
	insertText $start
    } else {
	set inComment 0
	hook::callProcForWin carriageReturn
    }
    if {[info exists indentOnReturn] && $indentOnReturn} {
	set textToEnd [getText [set pos0 [getPos]] [pos::lineEnd]]
	if {[regexp {^([\t ]+)[^\t ]} $textToEnd -> white]} {
	    set pos1 [pos::math $pos0 + [string length $white]]
	    if {$inComment} {
		deleteText $pos0 $pos1
	    } else {
		goto $pos1
	    }
	}
    } 
    return
}

proc bind::continueComment {} {
    if {![win::checkIfWinToEdit]} {
	return
    }
    if {[isSelection]} { deleteSelection }
    set p [getPos]
    # special case for beginning of line
    if {[pos::compare $p == [lineStart $p]]} {
	backwardChar
	set p [getPos]
    }
    if {![text::isInComment $p start]} {
	# What is this default '/' for?
	set start [win::getModeVar [win::Current] prefixString "/"]
    }
    insertReturnAndContinueComment $start
}

# We could possibly hook into this procedure in the future to allow
# different comment style handling.
proc insertReturnAndContinueComment {prefixOf} {
    # Use this sequence so the user can easily remove
    # the extra stuff inserted, with cmd-x
    insertText "\r"
    goto [getPos]
    replaceText [getPos] [getPos] $prefixOf
}

proc ::carriageReturn {} {
    typeText "\r"
    global indentOnReturn
    if {[info exists indentOnReturn] && $indentOnReturn} {
	bind::IndentLine
    }
}

proc bind::IndentLine {args} {
    win::parseArgs w
    if {![win::checkIfWinToEdit $w]} {
	return
    }
    hook::callProcForWin indentLine $w
}

proc bind::TypewriterTab {} {
    if {![win::checkIfWinToEdit]} {
	return
    }
    set tabSize [text::getTabSize]

    set white ""
    set pos  [lindex [pos::toRowCol [getPos]] 1]
    set stop [expr {($pos / $tabSize) + 1}]
    while {($pos / $tabSize) < $stop} {
	append white " "
	incr pos
    }
    typeText $white
}

proc insertActualTab {args} {
    win::parseArgs w
    if {![win::checkIfWinToEdit $w]} {
	return
    }
    typeText -w $w "\t"
    return
}

proc text::surroundingWord {args} {
    win::parseArgs w
    if {[isSelection -w $w]} {
	return [list [getPos -w $w] [selEnd -w $w]]
    }
    set pos [getPos -w $w]
    backwardWord -w $w ; set pos0 [getPos -w $w]
    forwardWord -w $w  ; set pos1 [getPos -w $w]
    forwardWord -w $w  ; set pos2 [getPos -w $w]
    backwardWord -w $w ; set pos3 [getPos -w $w]
    goto $pos
    if {[pos::compare -w $w $pos >= $pos0] \
      && [pos::compare -w $w $pos <= $pos1]} {
	return [list $pos0 $pos1]
    } elseif {[pos::compare -w $w $pos >= $pos3] \
      && [pos::compare -w $w $pos <= $pos2]} {
	return [list $pos3 $pos2]
    } else {
	return [list $pos $pos]
    }
}

# ×××× Indentation utility routines ×××× #

proc beginningOfLineSmart {args} {
    win::parseArgs w
    set pos [getPos -w $w]
    set start [pos::lineStart -w $w $pos]
    if {[string is space -strict [getText -w $w $start $pos]]} {
	beginningOfLine -w $w
    } else {
	goto -w $w [text::firstNonWsLinePos -w $w $pos]
    }
    return
}

proc beginningOfLineSelectSmart {args} {
    win::parseArgs w
    set pos [getPos -w $w]
    set start [getText -w $w [pos::lineStart -w $w $pos] $pos]
    if {[string length $start] && ([string trim $start] == "")} {
	beginningLineSelect -w $w
    } else {
	selectText -w $w [text::firstNonWsLinePos -w $w $pos] [selEnd -w $w]
    }
    return
}

proc text::firstNonWs {args} {
    win::parseArgs w pos
    set p [text::firstNonWsPos -w $w $pos]
    if {[pos::compare -w $w $p > [minPos -w $w]]} {
	return [lookAt -w $w $p]
    } else {
	return ""
    }
}

## 
 # -------------------------------------------------------------------------
 #   
 # "text::firstNonWsPos" --
 #  
 # This returns the position of the first non-whitespace character from the
 # start of pos' line.  If none is found, we return the position for the
 # start of the line containing "pos".
 # 
 # -------------------------------------------------------------------------
 ##

proc text::firstNonWsPos {args} {
    win::parseArgs w pos
    set posBeg [pos::lineStart -w $w $pos]
    set match  [search -w $w -n -s -f 1 -r 1 -- {\S} $posBeg]
    if {[llength $match]} {
	return [lindex $match 0]
    } else {
	return $posBeg
    }
}

## 
 # -------------------------------------------------------------------------
 #   
 # "text::firstNonWsLinePos" --
 #  
 # This returns the position of the first non-whitespace character from the
 # start of pos' line, but on the same line.  If none is found, we return the
 # position for the start of the line containing "pos".
 #  
 # -------------------------------------------------------------------------
 ##

proc text::firstNonWsLinePos {args} {
    win::parseArgs w pos
    set posBeg [pos::lineStart -w $w $pos]
    set posL   [pos::lineEnd -w $w   $pos]
    set match  [search -w $w -n -s -f 1 -r 1 -l $posL -- {\S} $posBeg]
    if {[llength $match]} {
	return [lindex $match 0]
    } else {
	return $posBeg
    }
}

proc text::indentation {args} {
    win::parseArgs w pos
    set pat {^[ \t]*[^ \t]}
    return [search -w $w -s -m 0 -f 1 -r 1 -- $pat [pos::lineStart -w $w $pos]]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "text::minSpaceForm" --
 # 
 #  Converts to minimal form: tabs then spaces.  Takes optional '-w win'
 #  arguments, to take account of window-dependent tabSize.
 #  
 #  IMPORTANT: This function should not generally be used without first
 #  checking the 'text::indentUsingSpacesOnly' value, since if that value
 #  is true, the user will *not* want any tabs in their document.
 #  
 # -------------------------------------------------------------------------
 ##
proc text::minSpaceForm {args} {
    win::parseArgs w ws
    set sp [spacesEqualTab -w $w]
    if {[string length $sp]} {
	regsub -all $sp $ws "\t" ws
	regsub -all " +\t" $ws "\t" ws
    } else {
	regsub -all "\t" $ws "" ws
    }
    return $ws
}


## 
 # -------------------------------------------------------------------------
 # 
 # "text::maxSpaceForm" --
 # 
 #  Converts it to maximal form - just spaces.  Takes account of tab-size,
 #  spaces interspersed with tabs,...
 # -------------------------------------------------------------------------
 ##
proc text::maxSpaceForm {args} {
    win::parseArgs w ws
    return [text::maxSpaceFormWithTab [spacesEqualTab -w $w] $ws]
}

proc text::maxSpaceFormWithTab {tabspace ws} {
    if {[string length $tabspace]} {
	regsub -all $tabspace $ws "\t" ws
	regsub -all " +\t" $ws "\t" ws
	regsub -all "\t" $ws "$tabspace" ws
    } else {
	regsub -all "\t" $ws "" ws
    }
    return $ws
}

## 
 # -------------------------------------------------------------------------
 # 
 # "spacesEqualTab" --
 # 
 #  Return the number of spaces equivalent to a single tab. If tabs are too
 #  big, this won't work.  Can add '-w win' if desired.
 # -------------------------------------------------------------------------
 ##
proc spacesEqualTab {args} {
    ::win::parseArgs w
    getWinInfo -w $w a
    return [string repeat " " $a(tabsize)]
}

proc doubleLookAt {args} {
    win::parseArgs w pos
    return [getText -w $w $pos [pos::math -w $w $pos + 2]]
}

proc text::indentOf {args} {
    win::parseArgs win size
    if {[text::indentUsingSpacesOnly -w $win]} {
	return [string repeat " " $size]
    } else {
	getWinInfo -w $win a
	if {$a(tabsize) == 0} {
	    return [string repeat " " $size]
	} else {
	    set ret [string repeat "\t" [expr {$size / $a(tabsize)}]]
	    append ret [string repeat " " [expr {$size % $a(tabsize)}]]
	}
    }
    return $ret
}

# returns the indent string of the line named by 'pos'
proc text::indentString {args} {
    win::parseArgs win pos
    set beg [lineStart -w $win $pos]
    regexp -- "^\[ \t\]*" [getText -w $win $beg [nextLineStart -w $win $beg]] white
    return $white
}

# returns the indent string of the line up to position 'pos' 
proc text::indentTo {args} {
    win::parseArgs win pos
    regexp -- "^\[ \t\]*" [getText -w $win [lineStart -w $win $pos] $pos] white
    return $white
}

## 
 # -------------------------------------------------------------------------
 # 
 # "text::indentBy" --
 # 
 #  Take the given block of text, and insert/remove spaces and tabs to
 #  indent it $by spaces to the left or right. This version should work
 #  ok for Tcl 7.5/8.0/8.1
 # -------------------------------------------------------------------------
 ##
proc text::indentBy {args} {
    win::parseArgs w text by {tabsize -1}
    if {$tabsize == -1} {
	set sp [spacesEqualTab -w $w]
    } else {
	set sp [string repeat " " $tabsize]
    }
    # Convert all leading whitespace to spaces
    if {[string length $sp]} {
	while {[regsub -all "((^|\r|\n)($sp)*) *\t" $text "\\1$sp" text]} {}
    } else {
	while {[regsub -all "(^|\r|\n)( *)\t" $text "\\1" text]} {}
    }
    set sby [string repeat " " [expr {abs($by)}]]
    if {$by < 0} {
	# need to indent less
	regsub -all "(^|\r|\n)$sby" $text "\\1" text
    } else {
	# need to indent more: add spaces to beginning of each line,
	# apart from blank lines and the final line
	regsub -all "(\[\r\n\])(\[^\r\n\])" $sby$text "\\1$sby\\2" text
    }
    # We already converted everything to spaces, so we only convert
    # to tabs if the user wants them.
    if {![text::indentUsingSpacesOnly -w $w] && [string length $sp]} {
	while {[regsub -all "((^|\r|\n)\t*)$sp" $text "\\1\t" text]} {}
    }
    return $text
}

proc text::halfIndent {args} {
    win::parseArgs w
    return [string repeat " " [expr {[text::getIndentationAmount -w $w]/2}]]
}

proc text::standardIndent {args} {
    win::parseArgs w
    return [text::indentOf -w $w [text::getIndentationAmount -w $w]]
}

proc text::getIndentationAmount {args} {
    ::win::parseArgs w
    if {($w ne "") && [win::infoExists $w indentationAmount]} {
	return [win::getInfo $w indentationAmount]
    } else {
	global indentationAmount
	return $indentationAmount
    }
}

proc text::indentUsingSpacesOnly {args} {
    ::win::parseArgs w
    if {($w ne "") && [win::infoExists $w indentUsingSpacesOnly]} {
	return [win::getInfo $w indentUsingSpacesOnly]
    } else {
	global indentUsingSpacesOnly
	return $indentUsingSpacesOnly
    }
}

proc text::getTabSize {args} {
    win::parseArgs w
    getWinInfo -w $w a
    return $a(tabsize)
}

# ×××× General purpose indentation ×××× #

## 
 # --------------------------------------------------------------------------
 # 
 # "indentSelection" --
 # 
 # Indent the selection in the active window, reselecting as necessary.  If
 # there is no selection, we defer to [bind::IndentLine].  Otherwise, we
 # calculate the "offset" from the end of the line to the start/end of the
 # selection, and use this to calculate the new selection boundaries.  In
 # each case, we default to the start of the line if that's where we began.
 # 
 # All of the "Beg" variables deal with the left hand or top side of the
 # selection, while "End" indicates that right hand (bottom) side.
 # 
 # --------------------------------------------------------------------------
 ##

proc indentSelection {args} {
    
    win::parseArgs w
    
    requireSelection -w $w
    
    # Preliminaries
    set selBeg    [getPos -w $w]
    set selEnd    [selEnd -w $w]
    set offsetBeg [pos::diff -w $w $selBeg [pos::lineEnd -w $w $selBeg]]
    set offsetEnd [pos::diff -w $w $selEnd [pos::lineEnd -w $w $selEnd]]
    set rowColBeg [pos::toRowCol -w $w $selBeg]
    set rowColEnd [pos::toRowCol -w $w $selEnd]
    set rowBeg    [lindex $rowColBeg 0]
    set rowEnd    [lindex $rowColEnd 0]
    # Indent the region.
    hook::callProcForWin indentRegion $w
    # Now we reselect, making sure that we're on the same lines that we
    # started with.  "rowL(ine)S(tart)" is the first column in the row.
    set rowLSBeg  [pos::fromRowCol -w $w $rowBeg 0]
    set rowLSEnd  [pos::fromRowCol -w $w $rowEnd 0]
    set newSelBeg [pos::math -w $w [pos::lineEnd -w $w $rowLSBeg] - $offsetBeg]
    set newSelEnd [pos::math -w $w [pos::lineEnd -w $w $rowLSEnd] - $offsetEnd]
    if {([lindex $rowColBeg 1] == 0) \
      || [pos::compare -w $w $newSelBeg < $rowLSBeg]} {
	set newSelBeg $rowLSBeg
    }
    if {([lindex $rowColEnd 1] == 0) \
      || [pos::compare -w $w $newSelEnd < $rowLSEnd]} {
	set newSelEnd $rowLSEnd
    }
    selectText -w $w $newSelBeg $newSelEnd
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "::indentLine" --
 # 
 #  This procedure can be used by any mode which defines its
 #  'correctIndentation' procedure.  It is therefore no longer
 #  necessary for a mode to define its own indentLine procedure.
 #  
 #  The advantage of this is (i) extra code-sharing, and (ii)
 #  the 'position after indentation' preference may be global.
 # -------------------------------------------------------------------------
 ##
proc ::indentLine {args} {
    win::parseArgs w
    if {![win::checkIfWinToEdit $w]} {
	return
    }
    
    # perform basic line indentation
    set beg [pos::lineStart -w $w [set p [getPos -w $w]]]
    set text [getText -w $w $beg [pos::nextLineStart -w $w $beg]]
    regexp -- {^[ \t]*} $text white
    set next [pos::math -w $w $beg + [string length $white]]
    set text [getText -w $w $next [pos::nextLineStart -w $w $next]]
    set lwhite [hook::callProcForWin correctIndentation $w $p $text]
    set replacement [text::indentOf -w $w $lwhite]
    if {($white ne $replacement)} {
        replaceText -w $w $beg $next $replacement
    }
    # At present, "positionAfterIndentation" is only a global preference and
    # will never be different for individual modes/windows.
    global positionAfterIndentation
    if {$positionAfterIndentation && [string length [string trim $text]]} {
	# Keep relative position
        set to [pos::math -w $w $p + [string length $replacement] \
          - [pos::diff -w $w $beg $next]]
        if {[pos::compare -w $w $to < $beg]} {
            goto -w $w $beg
        } else {
            goto -w $w $to
        }
    } else {
	goto [pos::math -w $w $beg + [string length $replacement]]
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "::correctIndentation" --
 # 
 #  This is a fallback procedure for all modes which do not
 #  define their own 'correctIndentation' procedure.  Most complex
 #  modes will probably want to over-ride this.
 # -------------------------------------------------------------------------
 ##
proc ::correctIndentation {args} {
    win::parseArgs w pos {next ""}
    
    set pos [lineStart -w $w $pos]
    # Find last previous non-comment non-white line and get its leading
    # whitespace:
    while 1 {
	if {[pos::compare -w $w $pos == [minPos]] \
	  || [catch {search -w $w -s -f 0 -r 1 -i 0 -m 0 \
	  "^\[ \t\]*\[^ \t\r\n\]" [pos::math -w $w $pos - 1]} lst]} {
	    # search failed at top of file
	    set line "#"
	    return 0
	}
	set lst0 [lindex $lst 0]  ;# the start of the found line
	set lst1 [lindex $lst 1]  ;# just after first non-white on the line

	global commentsArentSpecialWhenIndenting
	if {!$commentsArentSpecialWhenIndenting} {
	    if {[text::isInDoubleComment -w $w $lst1 res] \
	      || [text::isInSingleComment -w $w $lst1 res]} {
		if {[pos::compare -w $w [lindex $res 0] < $lst0]} {
		    set pos [lindex $res 0]
		} else {
		    set pos $lst0
		}
		# look further back.  ($pos is smaller than in previous
		# loop)
		continue
	    }
	}
	
	# the essence is really the following --- all the above was
	# special-case yoga
	set line [getText -w $w $lst0 [pos::math -w $w [nextLineStart -w $w $lst0] - 1]]
	set lwhite [lindex [pos::toRowCol -w $w [pos::math -w $w $lst1 - 1]] 1]
	return $lwhite
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "::correctBracesIndentation" --
 # 
 #  This is a procedure which can be used by modes which don't want
 #  to write a complex <mode>::correctIndentation procedure of their
 #  own, but require braces to be correctly indented.
 # -------------------------------------------------------------------------
 ##
proc ::correctBracesIndentation {args} {
    win::parseArgs w pos {next ""}
    
    set pos [lineStart -w $w $pos]
    if {[pos::compare -w $w $pos != [minPos]]} {
	global commentsArentSpecialWhenIndenting
	# Find last previous non-comment line and get its leading whitespace
	while 1 {
	    if {[pos::compare -w $w $pos == [minPos]] \
	      || [catch {search -w $w -s -f 0 -r 1 -i 0 -m 0 \
	      "^\[ \t\]*\[^ \t\r\n\]" [pos::math -w $w $pos - 1]} lst]} {
		# search failed at top of file
		set line "#"
		set lwhite 0
		break
	    }
	    if {!$commentsArentSpecialWhenIndenting && \
	      [text::isInDoubleComment -w $w [lindex $lst 0] res]} {
		set pos [lindex $res 0]
	    } else {
		set line [getText -w $w [lindex $lst 0] \
		  [pos::math -w $w [nextLineStart -w $w [lindex $lst 0]] - 1]]
		set lwhite [lindex [pos::toRowCol -w $w \
		  [pos::math -w $w [lindex $lst 1] - 1]] 1]
		break
	    }
	}
	
	regexp -- "(\[^ \t\])\[ \t\]*\$" $line "" nextC
	global specialIndentForCaseLabel
	set ia [text::getIndentationAmount -w $w]
	if {($nextC == "\{")} {
	    incr lwhite $ia
	} elseif {$nextC == ":" && $specialIndentForCaseLabel} {
	    incr lwhite [expr {$ia /2}]
	}
	set text [getText -w $w [lineStart -w $w $pos] $pos]
	append text $next
	if {[regexp -- ":\[ \t\r\n\]*\$" $text] && $specialIndentForCaseLabel} {
	    incr lwhite [expr {-$ia / 2}]
	}
	if {[string index $next 0] == "\}"} {
	    incr lwhite [expr {-$ia}]
	}
    } else {
	set lwhite 0
    }
    return $lwhite
}


proc ::indentRegion {args} {
    win::parseArgs w
    if {![win::checkIfWinToEdit $w]} {
	return
    }
    watchCursor
    set from [lindex [pos::toRowChar -w $w [getPos -w $w]] 0]
    set to [lindex [pos::toRowChar -w $w [selEnd -w $w]] 0]
    selectText -w $w [getPos -w $w]
    while {$from <= $to} {
	goto -w $w [pos::fromRowCol -w $w $from 0]
	bind::IndentLine -w $w
	incr from
    }
    return
}

# ×××× Code folding ×××× #

# For code folding - only in Alphatk for the moment.

proc bind::Fold {} {
    set p [getPos]
    set range [::fold info $p]
    if {[llength $range]} {
	eval ::fold show $range
    } else {
	if {[catch {::FoldRegion $p} range]} {
	    status::msg "$range"
	} else {
	    eval ::fold hide $range
	    goto [lindex $range 0]
	}
    }
}

proc FoldRegion {pos} {
    hook::callProcForWin foldableRegion "" $pos
}

proc ::foldableRegion {pos} {
    error "No foldable region found"
}

# ===========================================================================
# 
# .