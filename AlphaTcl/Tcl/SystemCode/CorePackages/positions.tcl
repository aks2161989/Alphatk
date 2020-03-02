## -*-Tcl-*- 
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "positions.tcl"
 #                                          created: 02/21/2002 {11:30:21 am}
 #                                      last update: 03/07/2006 {11:38:17 AM}
 # Description:
 #  
 # Provides a set of generalized routines for determining various positions
 # within an open window.  These assume that an application has already
 # defined the core commands:
 #  
 #   maxPos
 #   lineStart
 #   nextLineStart
 #  
 # and if necessary will create the core commands:
 #  
 #   minPos
 #   pos::compare
 #   pos::math
 #   pos::diff
 #   pos::fromRowChar
 #   pos::fromRowCol
 #   pos::toRowChar
 #   pos::toRowCol
 #  
 # This file should be sourced automatically when the procs are called, no
 # need to source it during initialization.  For greater efficiency, we
 # usually define two versions taking advantage of calling procs within the
 # 'pos' namespace when we can, and using 'expr' instead of 'pos::math' for
 # Alpha7.
 #  
 # All of the procs in this file, including the core procs, can accept an
 # optional '-w <window>' argument, which should come first.  If none given,
 # the frontmost window is the assumed window for the operation.
 #  
 # All of the procs in the 'Position procs' sections accept an optional
 # <position> argument, which should always come at the end.  If none is
 # given, either the beginning or the end position of a selection is assumed,
 # depending on context.  (Procs which look for positions forward take the
 # end, those which go back take the beginning.)
 #  
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # Copyright (c) 2002-2006 Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # --------------------------------------------------------------------------
 # 
 # A note regarding 'valid positions'
 # 
 # In Alpha7 the proc: nextLineStart tends to always return a valid position,
 # i.e.
 #  
 #   nextLineStart [maxPos]
 #  
 # will return the 'maxPos' -- although it does so by returning the pos
 # argument if it already exceeds 'maxPos', so that
 #  
 #   nextLineStart "10000000"
 #  
 # will return     "10000000"
 #  
 # Following the spirit of only returning valid positions which is implied by
 # nextLineStart (and which is explictly the case in Alphatk), all of these
 # procs will do so.  (This includes pos::math for Alpha7, which is a change
 # from previous behavior.)  Thus
 # 
 #   pos::nextLineStart "10000000"
 #   
 # will return something like '20772' in this file, or the same position
 # returned by 'pos::max'.
 #  
 # The positions given to the procs 'pos::diff' and 'pos::toRow(Col/Char)
 # will be converted to valid positions if they are outside the window minPos
 # and maxPos window parameters.  In Alphatk, I think that the positions for
 # 'pos::compare' have to be valid as well, but that isn't the case here for
 # Alpha7/8.  This should only present a problem when comparing two positions
 # that are both outside of the window parameters -- Alphatk will decide that
 # the two positions are the same before making the comparison, while
 # Alpha7/8 will simply run the comparison arguments through 'expr'.
 #  
 # ===========================================================================
 ##

proc positions.tcl {} {}

namespace eval pos {}

# ×××× Position utilities ×××× #

## 
 # --------------------------------------------------------------------------
 # 
 # "pos::_getWPos" --
 # 
 # A shorthand for determining if a '-w' option is being passed to the
 # position argument, and if not specifying the current window.
 # 
 # --------------------------------------------------------------------------
 ##

proc pos::_getWPos {{defaultPos ""}} {
    upvar 1 args args
    upvar 1 pos  pos
    upvar 1 w    w
    if {[lindex $args 0] == "-w"} {
	set w    [lindex $args 1]
	set pos  [lindex $args 2]
	set args [lrange $args 2 end]
    } else {
	set w    [win::Current]
	set pos  [lindex $args 0]
    }
    if {![string length $pos] && [string length $defaultPos]} {
	set pos  [$defaultPos -w $w]
    } 
}

## 
 # --------------------------------------------------------------------------
 # 
 # "pos::_ensureValid" --
 # 
 # Ensure that a given position is not out of the range of the window. 
 # Should only be called by procs in this file, not by other code.  Unlike
 # other procs in this file, this one requires a window argument.
 # 
 # --------------------------------------------------------------------------
 ##

proc pos::_ensureValid {w pos} {
    if {[compare -w $w $pos < [set posM [min]]]} {
	set posM
    } elseif {[compare -w $w $pos > [set posM [max -w $w]]]} {
	set posM
    } else {
	set pos
    }
}

# ×××× -------- ×××× #

# ×××× Min/Max positions ×××× #

## 
 # --------------------------------------------------------------------------
 # 
 # "pos::min" "pos::max" --
 # 
 # These are included simply for nomenclature consistency.
 # 
 # --------------------------------------------------------------------------
 ##

proc pos::min {args} {
    pos::_getWPos
    minPos -w $w
}

proc pos::max {args} {
    pos::_getWPos
    maxPos -w $w
}

# ×××× Line Start positions ×××× #

## 
 # --------------------------------------------------------------------------
 # 
 # "pos::lineStart" "pos::nextLineStart" --
 # 
 # These are included mainly for nomenclature consistency, although we now
 # ensure that a valid position is returned for 'pos::nextLineStart'.
 # 
 # "pos::prevLineStart" --
 # 
 # This always returns a valid position.  It's up to the calling proc to
 # ensure that the position returned is not actually on the same line, i.e.
 # that '$pos' is not in the first line of the window.
 # 
 # --------------------------------------------------------------------------
 ##

proc pos::lineStart {args} {
    _getWPos "getPos"
    ::lineStart -w $w [_ensureValid $w $pos]
}

proc pos::nextLineStart {args} {
    _getWPos "selEnd"
    ::nextLineStart -w $w [_ensureValid $w $pos]
}

proc pos::prevLineStart {args} {
    _getWPos "getPos"
    lineStart -w $w [math -w $w [lineStart -w $w $pos] - 1]
}

# ×××× Line End positions ×××× #

## 
 # --------------------------------------------------------------------------
 # 
 # "pos::lineEnd" --
 # 
 # This always returns a valid position, by indirectly calling the above
 # 'pos::_ensureValid' in both 'pos::nextLineStart' and 'pos::math'
 # 
 # "pos::nextLineEnd" "pos::prevLineEnd" --
 # 
 # These always return valid positions.  It's up to the calling proc to
 # ensure that the position returned is not actually on the same line, i.e.
 # that '$pos' is not in the last or first line of the window.
 # 
 # --------------------------------------------------------------------------
 ##

proc pos::lineEnd {args} {
    _getWPos "selEnd"
    set pos0 [nextLineStart -w $w $pos]
    if {[compare -w $w [lineStart -w $w $pos] == [lineStart -w $w $pos0]]} {
	# It wasn't possible to come down a line.  This means we are at 
	# file-end, and consequently at line-end.  So we can just
	return [maxPos -w $w]
    } else {
	# Normal case: go back one step:
	return [math -w $w $pos0 - 1]
    }
}

proc pos::nextLineEnd {args} {
    _getWPos "selEnd"
    lineEnd -w $w [nextLineStart -w $w $pos]
}

proc pos::prevLineEnd {args} {
    _getWPos "getPos"
    set pos0 [lineStart -w $w $pos]
    if {[compare -w $w $pos0 <= [set posM [min -w $w]]]} {
	set posM
    } else {
	math -w $w $pos0 - 1
    }
}

# ×××× Char/Line positions ×××× #

## 
 # --------------------------------------------------------------------------
 # 
 # "pos::nextChar" "pos::prevChar" --
 # 
 # These always return valid positions.  It's up to the calling proc to
 # ensure that the position returned is not actually the same position,
 # i.e. that '$pos' is not in the last or first position of the window.
 # 
 # "pos::nextLine" "pos::prevLine" --
 # 
 # These always return valid positions.  It's up to the calling proc to
 # ensure that the position returned is not actually on the same line, i.e.
 # that '$pos' is not in the last or first line of the window.
 # 
 # We compensate for tabs in the current and next/previous line to try to
 # return the position that is visually closest to that in the current
 # (given) line.
 # 
 # --------------------------------------------------------------------------
 ##

proc pos::nextChar {args} {
    _getWPos "selEnd"
    math -w $w $pos + 1
}

proc pos::prevChar {args} {
    _getWPos "getPos"
    math -w $w $pos - 1
}

proc pos::nextLine {args} {
    _getWPos "selEnd"
    set rowCol [toRowCol -w $w $pos]
    fromRowCol -w $w [expr [lindex $rowCol 0] + 1] [lindex $rowCol 1]
}

proc pos::prevLine {args} {
    _getWPos "getPos"
    set rowCol [toRowCol -w $w $pos]
    if {[set row [lindex $rowCol 0]] == 1} {return [min -w $w]}
    fromRowCol -w $w [expr $row - 1] [lindex $rowCol 1]
}

if {${alpha::platform} == "alpha"} {

## 
 # --------------------------------------------------------------------------
 # 
 # "pos::currentWord" --
 # 
 # Arguments:
 # 
 #     ?-w window? position
 # 
 # Given a window position, determine if there is a word surrounding it.  We
 # can't use [text::surroundingWord] because that uses the cursor position of
 # the active window by default, and manipulates the selection which might be
 # outside the visible parameters of the window.
 # 
 # Returns a three item list if a word was found, including the word and its
 # surrounding positions.  If none is found, an empty list is returned.
 # 
 # Alphatk has this as a primitive operation.  Alpha 8/X need to resolve what
 # to do about 'wordBreakPreface' here, which is no longer defined.
 # 
 # --------------------------------------------------------------------------
 ##

proc pos::currentWord {args} {
    
    global wordBreak
    
    _getWPos "getPos"
    set pos0 [pos::lineStart -w $w $pos]
    set pos1 [pos::lineEnd -w $w $pos]
    #set pat0 "(\[\r\n\t \])|(${wordBreakPreface}${wordBreak})"
    # This is a tempory pattern -- need to revisit this later.
    set pat0 "(\[\r\n\t \])|((\[^a-zA-Z0-9:$\])${wordBreak})"
    set pat1 "(\[\r\n\t \])|(${wordBreak})"
    if {![catch {search -w $w -f 0 -r 1 -s -l $pos0 -- $pat0 $pos} match]} {
	set pos0 [pos::nextChar -w $w [lindex $match 0]]
    }
    if {![catch {search -w $w -f 1 -r 1 -s -l $pos1 -- $pat1 $pos0} match]} {
	if {[regexp "\[\r\n\t \]+" [eval [list getText -w $w] $match]]} {
	    set pos1 [lindex $match 0]
	} else {
	    set pos1 [lindex $match 1]	    
	}
    }
    if {[pos::compare -w $w $pos0 > $pos] || [pos::compare -w $w $pos1 < $pos]} {
	set currentWord [list]
    } elseif {![regexp "^${wordBreak}\$" [set word [getText -w $w $pos0 $pos1]]]} {
	set currentWord [list]
    } else {
	set currentWord [list $word $pos0 $pos1]
    }
    return $currentWord
}

}

# ===========================================================================
# 
# .