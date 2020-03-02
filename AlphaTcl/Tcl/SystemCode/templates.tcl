## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "templates.tcl"
 #                                          created: 07/27/1997 {09:29:20 pm}
 #                                      last update: 03/21/2006 {01:25:09 PM}
 # Description:
 # 
 # Simple template insertion mechanism.  Can be easily overridden by a more
 # sophisticated scheme providing more features, whilst still working simply
 # if desired.  Call any of these procs from the outside:
 # 
 #     elec::Insertion args  -- insert the given args
 #     elec::CenterInsertion args -- insert, then center redraw
 #     elec::Wrap left right -- wrap left and right about the selection
 #  
 #     ring::+ -- move to the next template stop
 #     ring::- -- move to the previous template stop
 #  
 # Any piece of text given to the three 'elec::' procs has a template
 # conversion done.  Text of the form '¥blah¥' is converted to a single
 # bullet '¥', with 'blah' attached to it internally.
 # 
 # A more sophisticated template package, available separately, can prompt
 # the user with 'blah' in useful ways, and creates a proper template ring.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # History:
 # 
 #  modified by  rev reason
 #  -------- --- --- -----------
 #  27/7/97  VMD 1.0 original
 #  
 # ===========================================================================
 ##

proc templates.tcl {} {}

# alpha::flag electricTab 0.1.3 Electrics global help {
#     Enabling the 'Electric Tab' feature allows Alpha you to use
#     the procedures 'Indent or Next Stop' and 'Tab or Complete' as
#     any of your 'Special Keys' bindings.
#     
#     What these procedures do is change the behaviour of the Tab
#     key to depend upon the context.  In other words, hitting Tab
#     will not usually insert a Tab, rather it may indent the
#     current line, or move to the next Stop mark or complete the
#     current text,...
#     
#     Note that 'cmd-Tab' is one of the possible key-bindings
#     used to complete whatever you type.  If you use cmd-Tab as
#     a 'program switcher' in MacOS or other software, then you
#     obviously cannot use that keybinding in Alpha, since it
#     will be intercepted by the operating system.
# }

namespace eval elec {}
namespace eval bind {}
namespace eval ring {}

proc alpha::useElectricTemplates {} {}

# The character inserted into the text to indicate 'stop marks': useful
# positions which you can jump between very quickly
newPref variable elecStopMarker "¥"

## 
 # -------------------------------------------------------------------------
 #	 
 #	"elec::_Insertion" --
 #	
 #  Insert a piece of text, padding on the left appropriately.  The text
 #  should already be correctly indented within itself.
 #	 
 #  Any piece of the text of the form '¥blah¥' is converted into a single
 #  bullet.  A more advanced version of this procedure, available
 #  separately, allows the use of '¥blah¥' to prompt the user either in the
 #  window, or status line, and makes the template stops permanent entities
 #  so you can cycle back and forth through a template 'ring'. 
 #  
 #  The 'options' entry is currently undocumented and unsupported,
 #  pending a future cleanup, but 'options & 1' says whether to recenter
 #  the window, and 'options & 2' says whether not to indent the text.
 #  These may change at any moment (along with the version in
 #  elecTemplates.tcl)
 # -------------------------------------------------------------------------
 ##
proc elec::_Insertion { options args } {
    set text [join $args ""]
    set pos [getPos]
    if {!($options & 2)} {
	regsub -all "\t" $text [text::standardIndent] text
	if {[regexp "\[\n\r\]" $text]} {
	    regsub -all "\[\n\r\]" $text "\r[text::indentTo $pos]" text
	}
	if {[regexp "É" $text]} {
	    regsub -all "É" $text [text::halfIndent] text
	}
    }
    setPin
    global elecStopMarker
    if {![regexp "¥" $text] || ([regexp {^([^¥]*)¥¥$} $text "" text])} {
	insertText $text
	if {$options & 1} { centerRedraw }
    } else {
	regsub -all {¥[^¥]*¥} $text $elecStopMarker text
	insertText $text
	goto $pos
	if {$options & 1} { centerRedraw }
	# need to go to the first tab stop
	ring::+
    }
}


# ×××× possible tab key bindings ×××× #

# note: Also provided by the base Alpha system, these overide when 
# other packages are in use.

## 
 # -------------------------------------------------------------------------
 #	 
 #	"bind::IndentOrNextstop" --
 #	
 #  Either jump to the next template stop (if we're mid-template), or indent
 #  the current line correctly.
 #	 
 # -------------------------------------------------------------------------
 ##
proc bind::IndentOrNextstop {{hard 0}} {
    if {![win::checkIfWinToEdit]} {return}
    if {$hard} {
	insertActualTab 
    } elseif {![ring::+]} {
	if {[isSelection]} {
	    indentSelection
	    status::msg "Selection indented."
	} else {
	    bind::IndentLine
	    status::msg "Line indented."
	}
    }
    return
}

# MUST return 0 or 1
proc ring::+ {} {
    global elecStopMarker
    if {![win::checkIfWinToEdit]} {return 0}
    set pos [getPos]
    if {[pos::compare $pos == [maxPos]]} { return 0 }
    set searchResult [lindex [search -s -n -f 1 -m 0 \
      -i 1 -r 0 -- $elecStopMarker $pos] 0]
    if {[string length $searchResult]} {
	goto $searchResult
	deleteChar
	return 1
    } else {
	return 0
    }
}

# MUST return 0 or 1
proc ring::- {} {
    global elecStopMarker
    if {![win::checkIfWinToEdit]} {return 0}
    set pos [getPos]
    if {[pos::compare $pos == [minPos]]} { return 0 }
    set searchResult [lindex [search -s -n -f 0 -m 0 \
      -i 1 -r 0 -- $elecStopMarker $pos] 0]
    if {[string length $searchResult]} {
	goto $searchResult
	deleteChar
	return 1
    } else {
	return 0
    }
}

# Removes all tab stops from the current selection (if there is one) 
# or the current document, maintaining the cursor position in the 
# latter case.
proc ring::clear {} {
    if {![win::checkIfWinToEdit]} {return}
    watchCursor
    set pos [getPos]
    global elecStopMarker
    if {[pos::compare [set start $pos] == [set end [selEnd]]]} {
	set changes 0
	createTMark "ring::clear" $pos
	while {![catch {search -s -r 0 -f 1 -l $pos \
	  -- $elecStopMarker [minPos]} got]} {
	    incr changes
	    eval deleteText $got
	}
	while {![catch {search -s -r 0 -f 0 -l $pos \
	  -- $elecStopMarker [maxPos]} got]} {
	    incr changes
	    eval deleteText $got
	}
	if {!$changes} {return}
	gotoTMark "ring::clear"
	removeTMark "ring::clear"
	status::msg "$changes stops cleared"
    } else {
	set text [getText $start $end]
	set changes [regsub -all -- $elecStopMarker $text {} text]
	if {$changes == 0} {return}
	replaceText $start $end $text
	selectText $start [getPos]
	status::msg "$changes stops cleared"
    }
}
# indicates we're a very basic ring
proc ring::type {} { return 0 }
proc ring::nth {} {
    status::msg "ring::nth requires the Better Templates feature"
}

## 
 # -------------------------------------------------------------------------
 # 
 # "elec::CenterInsertion" --
 # 
 #  Insert and then do a refresh.  Useful for large electric insertions.
 # -------------------------------------------------------------------------
 ##
proc elec::CenterInsertion {args} {
    eval elec::_Insertion 1 $args
}

## 
 # -------------------------------------------------------------------------
 # 
 # "elec::Insertion" --
 # 
 #  Just insert the electric item
 # -------------------------------------------------------------------------
 ##
proc elec::Insertion { args } {
    eval elec::_Insertion 0 $args
}
proc elec::ReplaceText { start end args } {
    deleteText $start $end 
    eval elec::_Insertion 0 $args
}

## 
 # -------------------------------------------------------------------------
 #	 
 #	"elec::Wrap" --
 #	
 #  Currently doesn't deal with indentation -- the wrapper is supposed to
 #  handle that.
 #	 
 #  Returns 0/1 to indicate if there was a selection which this proc
 #  wrapped. 
 # -------------------------------------------------------------------------
 ##
proc elec::Wrap { left right {complete 0}} {
    set pos [getPos]
    set s [getSelect]
    if {[string length $s]} {
	deleteText $pos [selEnd]
	elec::_Insertion 2 $left $s $right
	return 1
    } else {
	elec::Insertion $left "¥¥" $right
	if {$complete} {
	    bind::Completion
	}
	return 0
    }
}

# ===========================================================================
# 
# .