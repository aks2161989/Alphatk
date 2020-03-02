## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "emacs.tcl"
 #                                          created: 05/04/1998 {08:09:08 PM}
 #                                      last update: 03/21/2006 {02:13:42 PM}
 # Description:
 # 
 # Emacs emulation in Alpha.
 # 
 # Original Author: Peter Keleher
 # 
 # Updated by: trf
 # 
 # Further Updates and Corrections: Donavan Hall
 # 
 #  E-mail: hall@magnet.fsu.edu
 #    mail: National High Magnetic Field Lab
 #          1800 E. Paul Dirac Drive, Tallahassee, FL 32310
 #     www: http://magnet.fsu.edu/~hall/
 # 
 # Copyright 1998-2006 Peter Keleher, Tom Fetherston, Donavan Hall
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # added bindings	C-x u	undo
 # 			ESC q	fillParagraph
 # 			C-@	setMark (in addition to C-SPACE)
 # 			C-x C-c	quit
 # 			ESC-w 	bound to copyRegion
 #
 # History
 #
 # modified   by  rev reason
 # ---------- --- --- -----------
 # 1998-04-05 PK  0.1 original
 # 2000-03-18 DWH 0.3 added more bindings
 # 2000-05-17 DWH 0.3.1 rebound C-y to yank because of problem with killLine
 # 			added copyRegion so C-y works with ESC-w
 # ==========================================================================
 ##

alpha::extension emacs 0.3.3 {
    # To add a menu of emacs related actions to the Edit menu, click this box.||
    # To remove the emacs menu from the Edit menu (once you've learnt all the
    # shortcuts), click this box.
    newPref f useEmacsMenu 1 global emacsToggle
    # To make the capitalisation commands effect the previous word if the
    # cursor is at its end, click this box.||To leave capitalisation commands
    # unaltered, click this box.
    newPref f emacLastWordIfTouching 0 global effectLastToggle

    if {$tcl_platform(platform) == "windows"} {
	# If you prefer windows bindings (particularly ctrl-v for paste)
	# instead of emacs bindings (ctrl-v for page-down), then set this
	# preference.  You will need to restart for this to take effect.
	newPref f windowsBindingsPreferredToEmacs 1 global
    }
    menu::buildProc emacs emacsBindings
    emacsToggle
    effectLastToggle
    alpha::addToPreferencePage Packages emacLastWordIfTouching useEmacsMenu
} uninstall {
    this-file
} maintainer {
} description {
    Adds keyboard navigation shortcuts familiar to Emacs users
} help {
    file "Emacs Help"
}

proc emacs.tcl {} {}

proc effectLastToggle {args} {
    global emacLastWordIfTouching
    if {$emacLastWordIfTouching} {
	if {[info command __upcaseWord] == ""} {
	    rename upcaseWord __upcaseWord
	    rename downcaseWord __downcaseWord
	    rename capitalizeWord __capitalizeWord
	}
	;proc upcaseWord {} {
	    set p [getPos]
	    backwardWord
	    set sw [getPos]
	    forwardWord
	    set ew [getPos]
	    goto $p
	    if {[pos::compare $p == $ew]} {
		backwardWord
		__upcaseWord
	    } else {
		__upcaseWord
	    }
	}
	;proc downcaseWord {} {
	    set p [getPos]
	    backwardWord
	    set sw [getPos]
	    forwardWord
	    set ew [getPos]
	    goto $p
	    if {[pos::compare $p == $ew]} {
		backwardWord
		__downcaseWord
	    } else {
		__downcaseWord
	    }
	}
	;proc capitalizeWord {} {
	    set p [getPos]
	    backwardWord
	    set sw [getPos]
	    forwardWord
	    set ew [getPos]
	    goto $p
	    if {[pos::compare $p == $ew]} {
		backwardWord
		while {![regexp {\w} [lookAt [getPos]]]} {
		    forwardChar
		}
		__capitalizeWord
	    } else {
		__capitalizeWord
	    }
	}
	unBind 'h' <z>	hiliteWord
	Bind 'h' <z>	touchHiliteWord
    } else {
	if {[info command __upcaseWord] != ""} {
	    rename upcaseWord {}
	    rename downcaseWord {}
	    rename capitalizeWord {}
	    
	    rename __upcaseWord upcaseWord
	    rename __downcaseWord downcaseWord
	    rename __capitalizeWord capitalizeWord
	    unBind 'h' <z>	touchHiliteWord
	    Bind 'h' <z>	hiliteWord
	}
    }
}

proc touchHiliteWord {} {
    if {[pos::compare [getPos] == [selEnd]]} {
	set p [getPos]
	backwardWord
	set sw [getPos]
	forwardWord
	set ew [getPos]
	goto $p
	if {[pos::compare $p == $ew]} {
	    selectText $sw $ew
	} else {
	    forwardWord
	    set start [getPos]
	    backwardWord
	    selectText $start [getPos]
	}
    } else {
	forwardChar
	forwardWord
	set start [getPos]
	backwardWord
	selectText $start [getPos]
    }
}

proc beginningOfLogicalLine {} {
    beginningOfLine
    set p [getPos]
    set limit [pos::math [nextLineStart $p] - 1]
    set llstart [search -s -f 1 -r 1 -n -l $limit {[^ \t\r\n]} $p]
    if {$llstart != ""} {
	goto [lindex $llstart 0]
    }
}

proc emacsToggle {args} {
    global useEmacsMenu
    if {$useEmacsMenu} {
	menu::insert Edit items 0 "(-)"
	menu::insert Edit submenu "(-)" emacs
	hook::register requireOpenWindowsHook [list Edit emacs] 1
    } else {
	menu::removeFrom Edit submenu "(-)" emacs
	hook::deregister requireOpenWindowsHook [list Edit emacs] 1
	emacsBindings
    }
}

# Emacs-ish bindings.
if {$tcl_platform(platform) == "windows"} {
    Bind 'c' <c> 	prefixChar
    Bind 'x' <c> 	prefixChar
} else {
    Bind 'c' <z> 	prefixChar
    Bind 'x' <z> 	prefixChar
}
Bind 0x33 <e>  	backwardDeleteWord
Bind 'b' <es>	backwardWordSelect
Bind '<' <se> 	beginningOfBuffer
Bind 'b' <X>	chooseAWindow
Bind 'l' <X>	{alertnote "Current: [getPos], maximum: [maxPos]"}
Bind ')' <Xs>	macro::endRecording
Bind '>' <se> 	endOfBuffer
Bind 'x' <Xz>	exchangePointAndPin
Bind 'w' <Xz>	saveAs
Bind 'e' <X>	macro::execute
Bind 'f' <Xz>	findFile
Bind 'f' <es> 	forwardWordSelect
Bind 'r' <e> 	findAgain
Bind 's' <e> 	findAgainBackward
Bind 's' <Xz>	save
Bind '(' <sX>	macro::startRecording
Bind 'o' <X>	otherThing
Bind '1' <X>	zoom
Bind 'k' <X>	closeAWindow


# added by DWH
#
Bind 'u' <X> undo
# yank wasn't pasting the copied region most of the time
# so I explicitly bound it to the paste proc
Bind 'y' <z> yank
# fillParagraph is ESC-q in Emacs
Bind 'q' <e> paragraph::fill
# setMark is bound to C-@ or C-SPACE in Emacs 
Bind 0x13 <sz> setPin
Bind 'c' <Xz> quit
#
# end added by DWH

Bind 'f' <e> forwardWord
Bind 'b' <e> backwardWord
Bind 'd' <e> deleteWord
Bind 'h' <e> backwardDeleteWord
Bind 'v' <e> pageBack
Bind 'w' <e> copyRegion
Bind 'g' <e> gotoLine
Bind 'e' <e> nextSentence
Bind 'a' <e> prevSentence
Bind 'c' <e> capitalizeWord
Bind 'u' <e> upcaseWord
Bind 'l' <e> downcaseWord

# added next -trf
Bind 'm' <e> beginningOfLogicalLine
Bind 'x' <e> execute
Bind '\ '  <e> oneSpace
Bind '\ '  <o> oneSpace

Bind 'd' <X>	killRegion

proc emacsBindings {} {
    global useEmacsMenu
    
    global windowsBindingsPreferredToEmacs
    if {[info exists windowsBindingsPreferredToEmacs] \
      && $windowsBindingsPreferredToEmacs} {
	set ctrlc 0
    } else {
	set ctrlc 1
    }
    
    if {$useEmacsMenu} {
	set emacs {
	    "/F<BforwardChar"
	    "/B<BbackwardChar"
	    "/D<BdeleteChar"
	    "/N<BnextLine"
	    "/P<BpreviousLine"
	    "(-"
	    "/F<IforwardWord"
	    "/B<IbackwardWord"
	    "/D<IdeleteWord"
	    "/v<IdeleteWord"
	    "/H<IbackwardDeleteWord"
	    "/u<IbackwardDeleteWord"
	    "(-"
	    "/K<BkillLine"
	    "/Y<Byank"
	    "/A<BbeginningOfLine"
	    "/E<BendOfLine"
	    "/O<BopenLine"
	    "(-"
	}
	if {$ctrlc} {
	    lappend emacs "/V<BpageForward"
	} else {
	    lappend emacs "pageForward"
	}
	lappend emacs \
	  "/V<IpageBack" "/L<BcenterRedraw" "(-" \
	  "/ <BsetMark" "/W<Bcut" "/W<Icopy" "(-" \
	  "/C<IcapitalizeWord" "upcaseWord" "/L<IdowncaseWord" "(-" \
	  "/X<Iexecute" "/U<BiterationCount" "/G<BabortEm"
	
	Menu -n emacs $emacs
    } else {
	Bind 'f' <z> forwardChar
	Bind 'b' <z> backwardChar
	Bind 'd' <z> deleteChar
	Bind 'n' <z> nextLine
	Bind 'p' <z> previousLine
	Bind 'f' <o>  forwardWord
	Bind 'b' <o>  backwardWord
	Bind 'd' <o>  deleteWord
	Bind 'h' <o>  backwardDeleteWord
	Bind 'k' <z> killLine
	Bind 'y' <z> yank
	Bind 'a' <z> beginningOfLine
	Bind 'e' <z> endOfLine
	Bind 'o' <z> openLine
	if {$ctrlc} {
	    Bind 'v' <z> pageForward
	}
	Bind 'v' <o> pageBack
	Bind 'l' <z> centerRedraw
	Bind '\ ' <z> setPin
	Bind 'w' <z> cut
	Bind 'w' <o> copyRegion
	Bind 'c' <o> capitalizeWord
	Bind 'l' <o> downcaseWord
	Bind 'x' <o> execute
	Bind 'u' <z> iterationCount
	Bind 'g' <z> abortEm
    }
}

proc killRegion {} {
    set from [getPin]
    set to [getPos]
    if {[pos::compare $to < $from]} {
	deleteText $to $from
    } else {
	deleteText $from $to
    }
}

proc copyRegion {} {
    set from [getPin]
    set to [getPos]
    if {[pos::compare $to < $from]} {
	putScrap [getText $to $from]
    } else {
	putScrap [getText $from $to]
    }
    status::msg "Region copied"
}

# ===========================================================================
# 
# .