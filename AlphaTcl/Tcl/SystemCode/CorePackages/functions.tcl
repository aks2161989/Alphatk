## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 #
 # FILE: "functions.tcl"
 # 
 #                                          created: 09/19/2001 {12:28:55 pm}
 #                                      last update: 03/21/2006 {12:46:03 PM}
 # Description:
 # 
 # Provides a set of generalized routines for navigating functions within a
 # window.  Allows individual modes to specify how a 'function' is defined,
 # by defining new regexps or (if something more complicated is desired) a
 # [<mode>::getLimits] procedure.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # Copyright (c) 2001-2006 Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ===========================================================================
 ##

proc functions.tcl {} {}

# ============================================================================
# 
# ×××× Function Navigation ×××× #
# 
# The procs in this file are intended to support mode-specific window
# navigation.  Any mode/menu should feel to call these procs:
# 
# function::next
# function::prev
# function::select
# function::reformat
# 
# The remaining procs in this file primarily provide support for the above.
# 
# Most of the routines here are pretty generic.  The basic idea is that
# given a cursor position, we want to know:
# 
# (1)  Where is the start of the previous 'function', however a mode wants
#        to define what a function is.
# (2)  Where is the end of that function.
# (3)  Where is the start of the next function below the cursor.
# (4)  Where is the end of that function.
# 
# Given these four positions (along with current position and possibly
# selection end), then we do various things (cursor movement, selection,
# etc), based upon the relationship of the current position(s) to them,
# i.e. are we inside?  above?  below?  So the key is to come up with an
# easy way to determine these four positions.
# 
# The proc '::getLimits' contains some pre-defined regexp's that work pretty
# well in most cases, but are based solely on indentation, assuming that
# anything that is in column 1 (but isn't a comment) is the start of a
# function, and that the function continues until either an end brace appears
# or another function starts.  The 'end' of a function is based on 'negative'
# regexps -- the idea is that you want to search down/up in the window to
# find the start of the next function, and then back up to find the last
# 'real' line, ignoring comments and any other special characters along the
# way.
# 
# If a mode has defined <mode>::start/endFunction variables, as in
# 
# set Lisp::startFunction {^\([a-zA-Z0-9;]}
# set Lisp::endFunction   {^((\([a-zA-Z0-9])|\;)}
# 
# then these are used to determine the start and the end of a function. 
# These must come in pairs, otherwise they'll be ignored.  Searches for
# these regexps are case-sensitive.
# 
# If defining the start/endFunction regexps still doesn't provide enough
# flexibility, the mode can define a <mode>::getLimits proc instead which
# returns the beginning and the end of a function closest to position 'pos'
# in direction 'direction'.  If no function is found, then that proc should
# return a list with two empty values.  This proc should NEVER throw an
# error.  The 'four' positions described above are obtained if necessary by
# calling function::getLimits twice with either two different positions or
# two different directions.  This proc is always used preferentially.
# 
# Any mode can also redefine what a function is called  with this:
# 
# set Lisp::functionName  "macro"
# set Igor::functionName  "macro"
# set mapl::functionName  "proc"
# set Tcl::functionName   "proc"
# 
# These values are primarily used in status messages when the user has
# reached the beginning/end of a window and no more functions are available.
# The default value is 'function'.
# 

namespace eval function {}

## 
 # --------------------------------------------------------------------------
 # 
 # "function::next" --
 # 
 # This procedure can simply return the position of the next function
 # (quietly == 1), move the cursor to the start of the next function (placing
 # the cursor at the top of the window if insertTo == 1, centerRedraw if
 # insertTo == 2,), extend the current selection to the end of the this
 # function, or (if the current function is already highlighted in its
 # entirety) extend the current selection to the end of the next function.
 # 
 # --------------------------------------------------------------------------
 ##

proc function::next {args} {
    
    requireOpenWindow
    win::parseArgs w {quietly 0} {insertTo 0}
    # Set initial positions for the search.  We advance one to ensure
    # that we don't capture the current function.
    set pos0 [pos::math -w $w [selEnd -w $w] + 1]
    if {$quietly} {
        # Simply return the start position of the next function from
        # 'selEnd'.  It's up to the calling proc to decide what further
        # tests (if any) to perform on this position.
	return [lindex [function::getLimits -w $w $pos0 1] 0]
    } elseif {[isSelection -w $w]} {
	# We have a selection, so we are going to advance to either the end
	# of the current function (if we're not already there), or to the
	# end of the next function.  First we need to find out the end of
	# the previous function.
	set result [function::getLimits -w $w $pos0 0]
	if {[set pos1 [lindex $result 1]] eq ""} {
	    # No 'previous' function found.
	    set pos1 $pos0
	}
	if {[pos::compare -w $w $pos0 >= $pos1]} {
	    # We are below or at the very end of the previous function (as
	    # opposed to being in it), so try to find the end of the next
	    # function.
	    set pos1 [lindex [function::getLimits -w $w $pos0 1] 1]
	}
	if {$pos1 eq ""} {
	    # No 'next' function found.
	    status::msg "No further [lindex $result 2]s in the file."
	    return
	} else {
	    selectText [getPos -w $w] $pos1
	}
    } else {
	# Search for the start of the next function.
	set result [function::getLimits -w $w $pos0 1]
	if {([set pos1 [lindex $result 0]] eq "")} {
	    status::msg "No further [lindex $result 2]s in the file."
	    return
	}
	goto -w $w $pos1
    }
    if {($insertTo == 1)} {
	insertToTop -w $w
    } elseif {($insertTo == 2)} {
	centerRedraw -w $w
    }
    if {![isSelection -w $w]} {
	status::msg [getText -w $w $pos1 [nextLineStart -w $w $pos1]]
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "function::prev" --
 # 
 # This procedure can simply return the position of the previous function
 # (quietly == 1), move the cursor to the start of the previous function
 # (placing the cursor at the top of the window if insertTo == 1,
 # centerRedraw if insertTo == 2,), extend the current selection to the start
 # of the this function, or (if the current function is already highlighted
 # in its entirety) extend the current selection to the start of the previous
 # function.
 # 
 # --------------------------------------------------------------------------
 ##

proc function::prev {args} {
    
    requireOpenWindow
    win::parseArgs w {quietly 0} {insertTo 0}
    # We are going to backup to either the start of the current function
    # (if we're not already there), or to the start of the function prior
    # to it.  We back up one to ensure that we don't capture the current
    # function.  Going backwards is a lot easier than forwards ...
    set pos0 [pos::math -w $w [getPos -w $w] - 1]
    set pos1 [lindex [set result [function::getLimits -w $w $pos0 0]] 0]
    if {$quietly} {
	# Simply return the start position of the next function from
	# 'getPos'.  It's up to the calling proc to decide what further
	# tests (if any) to perform on this position.
	return $pos1
    } elseif {($pos1 eq "")} {
	# No 'previous' function found.
	status::msg "No further [lindex $result 2]s in the file."
	return
    } elseif {[isSelection -w $w]} {
	# Simply extend the selection.
	selectText -w $w $pos1 [selEnd -w $w]
    } else {
	goto -w $w $pos1
    }
    if {($insertTo == 1)} {
	insertToTop -w $w
    } elseif {($insertTo == 2)} {
	centerRedraw -w $w
    }
    if {![isSelection -w $w]} {
	status::msg [getText -w $w $pos1 [pos::nextLineStart -w $w $pos1]]
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "function::reformat" -- 
 # 
 # Find the limits of the function in which the cursor currently resides,
 # select it, and use standard indentation procedures.
 # 
 # --------------------------------------------------------------------------
 ##

proc function::reformat {args} {
    
    requireOpenWindow
    win::parseArgs w {pos ""}
    if {($pos eq "")} {
	set pos [getPos -w $w]
    }
    if {![isSelection -w $w]} {
	function::select -w $w $pos
    }
    status::msg "Reformatting É"
    ::indentRegion -w $w
    status::msg "Reformatted."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "function::select" -- 
 # 
 # Select the entire function in which the cursor currently resides.
 # 
 # --------------------------------------------------------------------------
 ##

proc function::select {args} {
    
    requireOpenWindow
    win::parseArgs w {pos ""}
    if {($pos eq "")} {
	set pos [getPos -w $w]
    }
    set results [function::inFunction -w $w $pos]
    
    if {[lindex $results 0]} {
	# We are in a function.
	set posBeg  [lindex $results 1]
	set posEnd  [lindex $results 2]
	selectText -w $w $posBeg $posEnd
    } else {
	set what [lindex $results 3]
	error "Cancelled -- The cursor is not within a ${what}."
    }
    return
}

# The rest of these mainly support the code above.

## 
 # --------------------------------------------------------------------------
 # 
 # "::getLimits" -- 
 # 
 # Find the start and end of any function that possibly contains 'pos'.
 # 
 # 'pat1' is the start of a function.
 # 'pat2' is the end of a function.
 # 'what' is what the mode wants to call functions.  (Could be 'macros', etc)
 # 
 # The default routine works well for most syntax languages, but some modes
 # may wish to use the second one provided, especially if a function has an
 # explicit 'end' tag (which makes this easier).  See 'mapleMode.tcl' for an
 # example.
 # 
 # If a <mode>::getLimits proc has been defined, it will take precedence.
 # Such a proc should return a three element list containing the start and
 # the end of the closest function in the 'direction' from 'pos', plus
 # whatever name the mode wants to call a function.  This should NEVER throw
 # an error -- if no function is the specified direction, then return a list
 # with two empty elements plus the function name.  See 'Lisp::getLimits' for
 # an example.
 # 
 # Note that in this case a mode need not define either of the variable
 # entries such as <mode>::start/endFunction, since these are only accessed
 # by ::getLimits, and only when they come as a pair.
 # 
 # --------------------------------------------------------------------------
 ##

proc function::getLimits {args} {
    win::parseArgs w pos direction
    return [hook::callProcForWin getLimits $w $pos $direction]
}

proc ::getLimits {args} {
    
    win::parseArgs w pos direction
    set what [win::getModeVar $w functionName function]
    set pat1 [win::getModeVar $w startFunction ""]
    set pat2 [win::getModeVar $w endFunction ""]
    
    set posBeg ""
    set posEnd ""
    # Two different methods used here.
    if {($pat1 eq "") || ($pat2 eq "")} {
	# This works well for a lot of syntaxes ...  the idea is to find
	# the start of the closest function (in the specified direction,
	# and based solely on indentation), the start of the next, and then
	# back up to remove empty lines.  Trailing braces are not ignored
	# backing up, so that they are retained as part of the function.
	# This first regexp ignores comment characters '#' "*" "/" "-".
	set pat1 {^[^\r\n\t \#\*/\;\{\}\(\)-]}
	set pat2 {^[\t ]*([\#\*/-].*)?$}
	set pos1 $pos
	set posBeg ""
	set posEnd ""
	if {![catch {search -w $w -f $direction -s -r 1 -i 1 $pat1 $pos1} match]} {
	    # This is the start of the closest function.
	    set posBeg [lindex $match 0]
	    set pos2   [lindex $match 1]
	    if {![catch {search -w $w -s -f 1 -r 1 $pat1 $pos2} match]} {
		# This is the start of the next one.
		set posEnd [lindex $match 0]
	    } else {
		set posEnd [maxPos -w $w]
	    }
	    # Now back up to skip empty lines, ignoring comments as well.
	    while {1} {
		set posEndPrev [pos::math -w $w $posEnd - 1]
		set prevLine   [getText -w $w \
		  [pos::lineStart -w $w $posEndPrev] $posEndPrev]
		if {![regexp $pat2 $prevLine]} {
		    break
		}
		set posEnd [pos::lineStart -w $w $posEndPrev]
	    }
	}
    } else {
	# The mode has designated a pair of regexps for us, so we use a
	# very simple routine.
	if {![catch {search -w $w -f $direction -r 1 -i 0 -s $pat1 $pos} match]} {
	    set posBeg [lindex $match 0] ; # Where the function starts
	    set pos    [lindex $match 1] ; # Where the function start tag ends
	    if {![catch {search -w $w -f 1 -r 1 -i 0 -s $pat2 $pos} match]} {
		set posEnd [pos::nextLineStart -w $w [lindex $match 1]]
	    }
	}
    }
    return [list $posBeg $posEnd $what]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "function::inFunction" -- 
 # 
 # Determine if the cursor currently resides within a function, based
 # upon the limits returned by function::getLimits.  
 # 
 # --------------------------------------------------------------------------
 ##

proc function::inFunction {args} {
    
    win::parseArgs w pos
    
    set limits [function::getLimits -w $w $pos 0]
    set posBeg [lindex $limits 0]
    set posEnd [lindex $limits 1]
    set what   [lindex $limits 2]
    
    if {($posBeg == "") || ($posEnd == "")} {
	# Function limits weren't found.
	set result 0
    } else {
	set test1 [pos::compare -w $w $pos >= $posBeg]
	set test2 [pos::compare -w $w $pos <= $posEnd]
	set result [expr {$test1 && $test2} ? 1 : 0]
    }
    return [list $result $posBeg $posEnd $what]
}

# ===========================================================================
# 
# ×××× Global Implementation ×××× #
# 
# Any mode could make use of this by defining a 'navigateParagraphs' pref,
# and then include the following.
# 
# Bind    up   <sz>   {prevWhat 0 0} <mode>
# Bind  left   <sz>   {prevWhat 0 1} <mode>
# Bind  down   <sz>   {nextWhat 0 0} <mode>
# Bind right   <sz>   {nextWhat 0 1} <mode>
# 
# Bind    's'  <sz>   {selectWhat}   <mode>
# Bind    'i'  <cz>   {reformatWhat} <mode>
# 
# (Although modes can simply bind to 'function::prev' if desired ... the pref
# simply allows the user to change the style of navigation manually.)
# 
# Here's some examples.
# 
# newPref f navigateParagraphs {1} Setx
# newPref f navigateParagraphs {1} TeX
# newPref f navigateParagraphs {1} Mf
# newPref f navigateParagraphs {1} HTML
# newPref f navigateParagraphs {1} Fort
# 
# set Mf::paragraphName   "block"
# set Fort::paragraphName "block"
# 
# That's all there is to it.  Now the control-shift arrow keys will be
# bound to either paragraph or function navigation for each mode, including
# selection and reformatting.
# 

proc nextWhat {args} {
    
    global navigateParagraphs
    
    if {[info exists navigateParagraphs] && $navigateParagraphs} {
	return [eval ::paragraph::next $args]
    } else {
	return [eval ::function::next $args]
    }
}

proc prevWhat {args} {
    
    global navigateParagraphs
    
    if {[info exists navigateParagraphs] && $navigateParagraphs} {
	return [eval ::paragraph::prev $args]
    } else {
	return [eval ::function::prev $args]
    }
}

proc selectWhat {args} {
    
    global navigateParagraphs
    
    if {[info exists navigateParagraphs] && $navigateParagraphs} {
	return [eval ::paragraph::select $args]
    } else {
	return [eval ::function::select $args]
    }
}

proc reformatWhat {args} {
    
    global navigateParagraphs
    
    if {[info exists navigateParagraphs] && $navigateParagraphs} {
	return [eval ::paragraph::reformat $args]
    } else {
	return [eval ::function::reformat $args]
    }
}

# ===========================================================================
# 
# .