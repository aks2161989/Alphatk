## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 #
 # FILE: "elecTemplates.tcl"
 #                                          created: 02/24/1997 {01:34:29 pm}
 #                                      last update: 03/21/2006 {02:10:13 PM}
 # Description:
 #
 # Routines for electric insertions, and keeping track of template positions.
 # This package enhances the default behavior for "ring::" procs and some
 # electric bindings/procs that are supplied by default in "templates.tcl".
 #
 # Activating this package will redefine them to create template 'rings'
 # whenever electric insertions are added to the current window.  When this
 # package is deactivated, the default procedures are used again.  Template
 # rings make it easier to navigate to previous template stops even if the
 # "Elec Stop Marker" has been deleted, and helps ensure that we don't delete
 # valid occurances of this marker.
 #
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #
 # Copyright (c) 1997-2006  Vince Darley, Craig Barton Upright
 # All rights reserved.
 #
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 #
 # ==========================================================================
 ##

# ×××× Feature Declaration ×××× #
alpha::feature betterTemplates 9.3.1 global {
    # Initialization script.
    namespace eval ring {
	# We're not actually activated yet.
	variable betterTemplatesActivated -1
	# Define prefs, etc.  We include call the proc below because we know
	# that we're going to source this file anyway, and this makes it
	# easier to make changes without having to rebuild package indices.
	initialize
    }
} {
    # Activation script.
    namespace eval ring {
	variable betterTemplatesActivated 1
    }
    # Call on close to clear the stop ring.
    hook::register   closeHook        ring::unsetBTWindowVars
    # Make sure we reset messsage if the special keys change.
    hook::register   electricBindings ring::setTemplateMessage
} {
    # Deactivation script.
    namespace eval ring {
	variable betterTemplatesActivated 0
    }
    hook::deregister closeHook        ring::unsetBTWindowVars
    hook::deregister electricBindings ring::setTemplateMessage
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} uninstall {
    this-file
} description {
    This package enhances default electric key behavior, including all
    'ring' procedures
} help {
    Activate this feature using the "Config > Global Setup > Features" menu
    item.  While this is generally a global feature, individual modes can also
    turn it off if desired.
    
    Preferences: Features

    Note that this package will do very little for you already make use of the
    package: elecCompletions and have defined a keyboard shortcut that creates
    Electric Completion templates.
    
    Preferences: SpecialKeys
    
    The "Better Templates" package enhances the default electric template
    behavior, by creating electric template 'rings' the can be navigated using
    "Special Keys" keyboard shortcuts, and also adds several options for how
    templates and template 'hints' are inserted into the window.  Template
    rings make it easier to navigate to previous template stops even if the
    "Elec Stop Marker" has been deleted, and helps ensure that we don't delete
    valid occurances of this marker.

    (For more information about basic 'electric' behavior that is supplied by
    default, see the "Electrics Help" file.)

    Note: some of the features described here will only make sense in modes
    that have defined sophisticated electric completions.  Bib, HTML, Perl,
    Tcl, TeX, and most of the "Statistical Modes" do so.  See the help file
    "Electrics Help" for more information on how to add more completions for
    any given mode.  Throughout this file, '¥' refers to your current setting
    for the "Elec Stop Marker" preference.

    "# Template Prompts"
    "# Template Wrappers"
    "# 'Ring' Behavior"
    "# Testing"

    <<floatNamedMarks>>

    This package adds some additional "Interface > Completions" preferences
    that are described below.  See the "# Testing" section below for more
    information about temporarily activating this feature and opening this
    prefs dialog to change them.
    
    Preferences: Completions

	------------------------------------------------------------------

	  	Template Prompts

    When this package is NOT activated, electric completions will simply
    insert '¥' into your window, looking something like

	if {|} {
	    ¥
	} ¥

    where '|' indicates the current cursor position and '¥' indicates a
    template stop.  By default, this package will also insert an electric
    template message in the status bar window giving you a 'hint' as to what
    should be included in the template, something that might look like

	Fill in 'test',  press user-defined keys to move from stop to stop.

    or

	Fill in 'true body', press ctrl-j (shift-ctrl-j) to move to the next (previous) stop.

    TIP: You can turn off the tail end of this message by setting the
    'Electric' preference for 'Turn Navigation Msg Off', so that the message
    will instead just include something like

	Fill in 'test'

    or

	Fill in 'true body'

    These 'hints' can also be included in the template that is inserted into
    the window.  If the "Template Prompts" pref is "Put prompts in the text"
    then the template will look like

	if {|} {
	    <true body>
	}

    Navigating to the next 'hint' (See "# 'Ring' Behavior" below) will delete
    it, but insert the message into the status bar to help jog your memory.
    If the preference is set to "Highlight prompts in the text" then ring
    navigation will NOT delete the hint, but highlight it instead -- you can
    just begin to type to remove it.

    To only insert '¥' without any additional hints in either in the status
    bar or in the window, set your Electric "Template Prompts" preference to
    "Just use 'Electric Stop Marker'".


	  	Template Wrappers

    If the value for "Template Prompts" is set to include the hints in the
    actual template, you can change the 'wrapper' that surrounds it to

	<Angle brackets>   (the default) or
	ÒCurly quotesÓ     or
	ÇCurly bracketsÈ

    Changing this pref has no effect if hints are included in the status bar.


	  	'Ring' Behavior

    By default, Alpha supplies key bindings that you can set for

	Next Stop
	Previous Stop
	Clear All Stops
	Nth Stop

    in the "Config > Special Keys" dialog.
    
    Preferences: SpecialKeys

    If this package is turned off, the first three items refer to the
    presence of '¥' within the text, and allow you to navigate to the
    next/previous marker, or delete all of them.  The item "Nth Stop" is
    disabled unless this package is activated.

    With this package turned on, electric insertions create a 'ring' of
    template stops, and all of these items perform actions relative to this
    ring.  The first benefit of this feature is that "Next Stop" will never
    inadvertently jump to and delete any '¥' string that appears outside of
    the current ring.

    The second benefit is that if you are currently within a ring and create
    another electric insertion, this is included within the current ring so
    that you can still navigate previous stops.  This will continue to occur
    so long as (1) you remain within the current ring, and (2) the number of
    insertions does NOT exceed the "Max Template Nesting" preference -- when
    this number is exceeded, all previous template stops are first cleared.

    The third benefit provided by this package is that the "Nth Stop" item
    and key binding is now enabled, allowing you to jump to any template stop
    via a 'listpick' dialog -- stops are identified by their hints.

    If, however, you create an electric insertion that is OUTSIDE the current
    ring, all template markers/prompts are first deleted before the new ring
    is created.  This is also the action performed by "Clear All Stops",
    which again means that any '¥' appearing outside the ring will be
    preserved rather than deleted (a fourth major benefit !!).

    Note that the action performed by the binding for "Indent Or Next Stop"
    is identical to that for "Next Stop" SO LONG AS you are still within
    the limits of the current ring.  Otherwise, the current ring is cleared
    and the current line/selection is indented.

	------------------------------------------------------------------

	  	Testing

    To test this package, click on this <<ring::testBetterTemplates>>
    hyperlink.  This will temporarily activate this package, open some
    dialogs allowing you to set/change various 'electric' and 'special keys'
    preferences, and then open an electric completions tutorial window in
    which you can experiment with the bindings.  To turn this package off,
    click on this <<package::deactivate betterTemplates>> hyperlink.

    Source code can be found in "elecTemplates.tcl", code contributions are
    always welcome.
}

# ×××× -------- ×××× #

proc elecTemplates.tcl {} {}

namespace eval ring {
    
    # Activation, initialization variables.
    variable betterTemplatesActivated
    if {![info exists betterTemplatesActivated]} {
	set betterTemplatesActivated -2
    }
    variable initialized
    if {![info exists initialized]} {set initialized -1}
    
    # Only needed if debugging this package.
    variable debugging
    if {![info exists debugging]} {
	set debugging 0
    }
    
    # Make sure that all default procs are in place.
    if {$debugging && [info procs ::alpha::useElectricTemplates] != ""} {
	# This line is only necessary if you are working on this file, and
	# need to force the loading of "templates.tcl" before redefining the
	# ring:: procedures.  Evalute [set ::ring::debugging 1] if desired.
	rename ::alpha::useElectricTemplates ""
    }
    # This will source "templates.tcl" if necessary.
    alpha::useElectricTemplates
    # In normal usage, we only redefine these procs once, and turning this
    # package off will automatically redirect to the earlier versions.
    # Sourcing this file 'manually' will ensure that the 'templates.tcl' file
    # is sourced, and then we redefine these procs below.
    foreach Item [list Type + - Clear Nth] {
	set item [string tolower $Item]
	if {![string length [info procs preBTRing${Item}]]} {
	    rename $item preBTRing${Item}
	}
    }
}

# ===========================================================================
#
# ×××× -------- ×××× #
#
# ×××× Electric procs ×××× #
#

##
 # -------------------------------------------------------------------------
 #
 # "bind::IndentOrNextstop" --
 #
 # Either jump to the next template stop (if we're mid-template), or jump to
 # the first prompt in the current nest if one exists -- if all of this
 # fails, indent the current line/selection correctly.
 #
 # -------------------------------------------------------------------------
 ##

namespace eval bind {
    # Intervene in "bind::IndentOrNextstop"
    if {[string length [info procs preBTIONS]]} {
	rename preBTIONS ""
    }
    rename IndentOrNextstop preBTIONS
    # Redefine the proc now.
}

;proc bind::IndentOrNextstop {{hard 0}} {
    
    if {![win::checkIfWinToEdit]} {
	return
    } elseif {$::ring::betterTemplatesActivated  != 1} {
	preBTIONS $hard
    } elseif {$hard} {
	insertActualTab
    } elseif {[ring::positionIsInRing]} {
	ring::+
    } elseif {0 && [ring::currentRingHasPrompt]} {
	# This behavior is still subject to debate.
	ring::nextPrompt
    } else {
	ring::clear 1
	if {[isSelection]} {
	    indentSelection
	    status::msg "Selection indented."
	} else {
	    IndentLine
	    status::msg "Line indented."
	}
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "elec::_Insertion" --
 #
 # Insert a piece of text, padding on the left appropriately.  The text
 # should already be correctly indented within itself.
 #
 # The 'options' entry is currently undocumented and unsupported, pending a
 # future cleanup.  (See the notes in "templates.tcl")
 #
 # -------------------------------------------------------------------------
 ##

namespace eval elec {
    # Intervene in "elec::Insertion"
    if {[string length [info procs preBTEI]]} {
	rename preBTEI ""
    }
    # Redefine the proc now.
    rename _Insertion preBTEI
}

;proc elec::_Insertion {options args} {
    if {![win::checkIfWinToEdit]} {
	return
    } elseif {$::ring::betterTemplatesActivated  != 1} {
	return [eval [list preBTEI $options] $args]
    }
    set txt [join $args ""]
    set pos [getPos]
    if {!($options & 2)} {
	regsub -all "\t" $txt [text::standardIndent] txt
	if {[regexp -- "\[\n\r\]" $txt]} {
	    regsub -all "\[\n\r\]" $txt "\r[text::indentTo $pos]" txt
	}
	if {[regexp -- "É" $txt]} {
	    regsub -all "É" $txt [text::halfIndent] txt
	}
    }
    set center [expr {$options & 1}]
    if {![regexp -- "¥" $txt] || [regexp -- {^([^¥]*)¥¥$} $txt "" txt]} {
	insertText $txt
	if {$center} {centerRedraw}
	return
    }
    set colours [list]
    while {[regexp -- {^([^¥]*)¥([^¥]*)¥(.*)$} $txt "" tt hint txt]} {
	lappend ::ring::elecPrompts $hint
	append t "${tt}${::elecStopMarker}"
	if {$::TemplatePrompts <= 1 || ![string length $hint]} {
	    set hintLength 1
	} else {
	    set hintLength [expr {3 + [string length $hint]}]
	    append t ${::ring::_tstart}${hint}${::ring::_tend}
	}
	lappend colours [list [string length $tt] $hintLength]
    }
    append t $txt
    # We insert in one chunk so undoing is easy.
    insertText $t
    if {$::templateStopColor} {
	set pos0 $pos
	foreach col $colours {
	    set pos0 [pos::math $pos0 + [lindex $col 0]]
	    set pos1 [pos::math $pos0 + [lindex $col 1]]
	    text::color $pos0 [set pos0 $pos1] $::templateStopColor
	}
	refresh
    }
    goto $pos
    if {$center} {centerRedraw}
    ring::_createStops $t
}

# ===========================================================================
#
# ×××× -------- ×××× #
#
# ×××× Init, prefs support procs ×××× #
#

namespace eval ring {
    
    # Make sure that we have these in place.  They will normally be set when
    # [ring::changeTemplateWrappers] is called.
    variable _tstart
    if {![info exists _tstart]} {
	set _tstart ""
    }
    variable _tend
    if {![info exists _tend]} {
	set _tend ""
    }
    variable _tmatch
    if {![info exists _tmatch]} {
	set _tmatch ¥
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::initialize" --
 #
 # Should be called only once, when "betterTemplates" is activated for the
 # first time.  Creates all variables needed for this package, and also
 # redefines all default 'ring' and some 'bind' and 'elec' procs.
 #
 # -------------------------------------------------------------------------
 ##

proc ring::initialize {} {
    
    variable initialized
    
    if {$initialized == 1} {return}
    
    global varPrefs
    
    prefs::renameOld stopNavigationMsgOff turnNavigationMsgOff
    
    # Define additional global 'electric' prefs
    lunion varPrefs(Completions) [list "Better Templates:" \
      turnNavigationMsgOff \
      templateStopColor maxTemplateNesting \
      TemplatePrompts TemplateWrappers]
    # Don't bother with the basic 'hit tab to go to next stop...' message
    newPref flag turnNavigationMsgOff 0 global "ring::setTemplateMessage ; #"
    # The colour used for template stops inserted into the text.
    newPref var templateStopColor 4 global "" alpha::basiccolors varindex
    # If the level of nesting of template stops exceeds this value,
    # we clear all template stops.
    newPref var maxTemplateNesting 5
    # The format of the template stops:
    #
    #     (a) just use the 'Elec Stop Marker'
    #     (b) use markers but signal the name in the status window
    #     (c) insert names into the window with the markers
    #     (d) insert names and highlight into the window with the markers
    #     (e) insert names as in (d), but delete prompt when advancing.
    newPref var TemplatePrompts 1 global "" [list \
      {Just use 'Electric Stop Marker'} \
      {Use marker and status window prompt} \
      {Put prompts in the text} \
      {Highlight prompts in the text} \
      {Highlight, but delete when moving} \
      ] index
    # Visual appearance of templates in the text
    newPref var TemplateWrappers 0 global ring::changeTemplateWrappers \
      [list {<Angle brackets>} {ÒCurly quotesÓ} {ÇCurly bracketsÈ}] index
    
    # The character inserted into the text to indicate 'stop marks': useful
    # positions which you can jump between very quickly
    newPref variable elecStopMarker "¥" global ring::changeTemplateWrappers
    # NOTE: The elecStopMarker preference has already been declare in
    # AlphaTclCore, but we redeclare it here because we need to attach a
    # modification script 'ring::changeTemplateWrappers'
    
    # Set the template wrappers.
    changeTemplateWrappers
    # Set the template message.
    setTemplateMessage
    
    # Make sure that we don't do this again.
    set initialized 1
    return "'Better Templates' preferences, variables have been set."
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::changeTemplateWrappers" --
 #
 # Called when the package is activated for the first time, and whenever the
 # "TemplateWrappers" or "TemplatePrompts" prefs are changed.
 #
 # -------------------------------------------------------------------------
 ##

proc ring::changeTemplateWrappers {{flag ""}} {
    global TemplateWrappers elecStopMarker
    
    set values  [prefs::options TemplateWrappers]
    set wrapper [lindex $values $TemplateWrappers]
    
    set a [string index $wrapper 0]
    set b [string index $wrapper end]
    set m $elecStopMarker
    
    # Set the template prompt match pattern.
    append tMatch "(${m}${a}\[^${a}${b}]*${b}|${m}${a}"
    append tMatch "(\[^${a}${b}\]*(${a}\[^${a}${b}\]*${b})\[^${a}${b}\]*)*${b})"
    
    variable _tstart $a
    variable _tend   $b
    variable _tmatch $tMatch
    
    return "Template wrappers have been reset."
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::changeTemplateWrappers" --
 #
 # Called when the package is activated for the first time, and whenever the
 # "turnNavigationMsgOff" pref is changed.  This will change the message based
 # on the "Special Keys" settings.
 #
 # -------------------------------------------------------------------------
 ##

proc ring::setTemplateMessage {} {
    
    variable templateMessage
    
    if {$::turnNavigationMsgOff} {
	set templateMessage ""
    } else {
	# Determine the "Next/Prev Stop" keys.
	set key1 [set "::keys::specialBindings(Next Stop)"]
	set key2 [set "::keys::specialBindings(Next Stop Or Indent)"]
	set key3 [set "::keys::specialBindings(Prev Stop)"]
	if {[string length $key1]} {
	    set nextKey [dialog::specialView::binding $key1]
	} elseif {[string length $key2]} {
	    set nextKey [dialog::specialView::binding $key2]
	} else {
	    set nextKey "??"
	}
	if {[string length $key3]} {
	    set prevKey [dialog::specialView::binding $key3]
	} else {
	    set prevKey "??"
	}
	set templateMessage \
	  ", press ${nextKey}/${prevKey} to move to the next/prev stop."
    }
    return "Template message has been reset."
}

proc ring::testBetterTemplates {} {
    
    variable betterTemplatesActivated
    if {$betterTemplatesActivated < 1} {
	package::activate betterTemplates
	set msg "The 'Better Templates' package has now been \
	  temporarily activated. "
    }
    append msg {
	The "Config > Preferences > Interface Prefs > Completions" dialog will
	now be presented, allowing you to set various preferences associated
	with this package.  Then the "Config > Special Keys" dialog will
	appear, allowing you to change the various key bindings used in
	electric completions.  Then the "Perl Tutorial" shell window will be
	opened, allowing you to experiment with these bindings.
    }
    regsub -all "\[\r\n\t \]+" $msg " " msg
    if {![dialog::yesno -y "OK" -n "Cancel" $msg]} {return}
    help::openPrefsDialog Completions
    help::openPrefsDialog SpecialKeys
    # This is the best tutorial to create complicated ring completions.
    help::openHyper "Perl Tutorial .pl"
}

# ===========================================================================
#
# ×××× -------- ×××× #
#
# ×××× Standard Ring Procs ×××× #
#
# All of these are replacements for the default versions supplied in the file
# "templates.tcl".  If this package is turned off, we redirect to the
# previously defined versions.
#

;proc ring::type {} {
    
    variable betterTemplatesActivated
    
    if {$betterTemplatesActivated != 1} {
	return [preBTRingType]
    } else {
	return 1
    }
}

;proc ring::+ {} {
    
    variable betterTemplatesActivated
    
    if {![win::checkIfWinToEdit]} {
	return 0
    } elseif {$betterTemplatesActivated  != 1} {
	return [preBTRing+]
    }
    _upvarStops
    
    if {![info exists stops] || ![llength $stops]} {
	status::msg "No ring stops found in this window."
	return 0
    }
    if {$::TemplatePrompts == 4} {
	# We need to delete this prompt before moving on.
	_deleteMarker [getPos] 0
    }
    if {[llength $stops] == 1} {
	goToStop [lindex $stops 0]
    } else {
	goToStop [lindex $stops 1]
    }
    return 1
}

;proc ring::- {} {
    
    variable betterTemplatesActivated
    
    if {![win::checkIfWinToEdit]} {
	return 0
    } elseif {$betterTemplatesActivated  != 1} {
	return [preBTRing-]
    }
    _upvarStops
    
    if {![info exists stops] || ![llength $stops]} {
	status::msg "No ring stops found in this window."
	return 0
    }
    if {$::TemplatePrompts == 4} {
	# We need to delete this prompt before moving on.
	_deleteMarker [getPos] 0
    }
    goToStop [lindex $stops end]
    return 1
}

;proc ring::clear {{quietly 0}} {
    
    variable betterTemplatesActivated
    
    if {![win::checkIfWinToEdit]} {
	return
    } elseif {$betterTemplatesActivated  != 1} {
	preBTRingClear
	return
    }
    _upvarStops
    
    set count 0
    if {[info exists stops] && $stops != ""} {
	if {!$quietly} {status::msg "Deleting non-nested promptsÉ"}
	createTMark "_deleting_" [getPos]
	foreach stop $stops {
	    if {![catch {tmark::getPos $stop} p]} {
		incr count [_deleteMarker $p]
		removeTMark $stop
	    }
	}
	status::msg ""
	gotoTMark "_deleting_"
	removeTMark "_deleting_"
	
    }
    set stops ""
    if {[info exists w]} {unset w}
    
    set elecNestingLevel($x)    0
    set elecLastStop($x)        ""
    
    removeTMark "nestStart"
    removeTMark "nestEnd"
    
    if {!$quietly} {status::msg "All template prompts removed"}
    return $count
}

;proc ring::nth {} {
    
    variable betterTemplatesActivated
    
    if {![win::checkIfWinToEdit]} {
	return
    } elseif {$betterTemplatesActivated  != 1} {
	preBTRingNth
	return
    }
    
    _upvarStops
    
    set stopList [list]
    foreach stop $stops {
	if {$w($stop) != ""} {
	    lappend stopList "$stop -- $w($stop)"
	} else {
	    lappend stopList "$stop -- (no prompt)"
	}
    }
    if {![llength $stopList]} {
	beep
	status::msg "No template stops exist."
    } else {
	set p "Pick a stop (listed from current pos)É"
	set item [lindex [listpick -p $p $stopList] 0]
	goToStop $item
    }
}

# ===========================================================================
#
# ×××× -------- ×××× #
#
# ×××× Ring queries, stops ×××× #
#

##
 # -------------------------------------------------------------------------
 #
 # "ring::positionIsInRing" --
 #
 # Determine if position <pos> is part of the current ring.  This is somewhat
 # liberal, in that we might consider a cursor position that is technically
 # outside the ring but on the same line as a start/end to be 'in' the ring,
 # unless that line is empty.  This helps avoid some unfortunate clearing of
 # the ring when the temp mark wasn't adjusted properly as text was typed in
 # the window.
 #
 # -------------------------------------------------------------------------
 ##

proc ring::positionIsInRing {{pos ""}} {

    if {[catch {tmark::getPositions {nestStart nestEnd}} limits]} {return 0}

    if {![string length $pos]} {set pos [getPos]}
    # Starting position.
    set pos0A [lindex $limits 0]
    set pos0B [pos::lineStart $pos0A]
    set pos0C [pos::lineEnd   $pos0A]
    if {[string length [getText $pos0B $pos0C]]} {
	set pos0 $pos0B
    } else {
	set pos0 $pos0A
    }
    # Ending position.
    set pos1A [lindex $limits 1]
    set pos1B [pos::lineStart $pos1A]
    set pos1C [pos::lineEnd   $pos1A]
    if {[string length [getText $pos1B $pos1C]]} {
	set pos1 $pos1C
    } else {
	set pos1 $pos1A
    }
    # Are we in the ring?
    if {[pos::compare $pos0 == $pos1]} {
        return 0
    } elseif {[pos::compare $pos >= $pos0] && [pos::compare $pos <= $pos1]} {
        return 1
    } else {
        return 0
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::positionWithinRing" --
 #
 # Determine the stop index of a given position relative to all other
 # positions associated with stops in the current ring.  If the <pos> is not
 # within the current ring, return -1.
 #
 # -------------------------------------------------------------------------
 ##

proc ring::positionWithinRing {{pos ""}} {
    
    if {![string length $pos]} {set pos [getPos]}
    # Check to see if 'pos' is in the current ring.
    if {![positionIsInRing $pos]} {return -1}
    # Obtain the current position index relative to all other positions
    # in the current ring.
    set positions [currentRingPositions]
    if {![llength $positions]} {
	return -1
    } elseif {[pos::compare $pos < [lindex $positions 0]]} {
	return 0
    } elseif {[pos::compare $pos >= [lindex $positions end]]} {
	return [llength $positions]
    } else {
	set i 0
	set posP [lindex $positions 0]
	while {[pos::compare $pos >= $posP]} {
	    if {![string length [set posP [lindex $positions [incr i]]]]} {
		incr i -1
		break
	    }
	}
	return $i
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::currentRingHasPrompt" --
 #
 # Determine if any template stop in the current ring still has a template
 # prompt (thus indicating that the user has not yet navigated to it.)  If you
 # want to know where it is, then add an upvar argument.
 #
 # -------------------------------------------------------------------------
 ##

proc ring::currentRingHasPrompt {{p ""}} {
    
    if {[string length $p]} {
	upvar pos $p
    }
    set char [string index $::elecStopMarker 0]
    if {[catch {currentRingPositions} positions]} {
	return 0
    }
    foreach pos $positions {
	if {[lookAt $pos] == $char} {return 1}
    }
    # Still here?
    if {[info exists pos]} {unset pos}
    return 0
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::currentRingPositions" --
 #
 # Return a list (in ascending order) of all positions associated with the
 # current template ring.  The var 'stops' is also created, with a matched
 # index so that the [lindex $positions 4] <--> [lindex $stops 4], e.g.
 #
 # -------------------------------------------------------------------------
 ##

proc ring::currentRingPositions {} {
    
    _upvarStops
    
    if {![info exists stops] || ![llength $stops]} {
	return [list]
    } else {
	set positions [tmark::getPositions $stops]
	set max ""
	set idx 0
	set lpos -1
	foreach stop $stops {
	    set pos [lindex $positions $idx]
	    if {(![string length $max]) || ([pos::compare $pos > $max])} {
		set max $pos
		set lpos $idx
	    }
	    incr idx
	}
	set list1 [lrange $stops [expr {$lpos + 1}] end]
	set list2 [lrange $stops 0 $lpos]
	set stops [concat $list1 $list2]
	set list3 [lrange $positions [expr {$lpos + 1}] end]
	set list4 [lrange $positions 0 $lpos]
	set positions [concat $list3 $list4]
	return $positions
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::goToStop" --
 #
 # <stop> should be a valid element of the $stops list, of the form stop0:0
 #
 # -------------------------------------------------------------------------
 ##

proc ring::goToStop {stop} {
    
    _upvarStops
    
    if {![info exists stops]} {
	status::msg "Couldn't find stop: $stop"
    } elseif {[set lpos [lsearch -exact $stops $stop]] == -1} {
	status::msg "Couldn't find stop: $stop"
    } else {
	set list1 [lrange $stops $lpos end]
	set list2 [lrange $stops 0 [incr lpos -1]]
	set stops [concat $list1 $list2]
	_goToStop $stop
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::gotoNamed" --
 #
 # <name> should be a valid element of the $stops list, of the form stop0:0
 # This differs from [ring::goToStop] in that we only go to the stop but
 # don't actually delete it, and the order is not changed (so that the next
 # call to [ring::+] will assume that we never moved.)
 # 
 # This is somewhat buggy, and I think that [ring::replaceStopMatches] should
 # be able to handle anything that wants to use this code.  (cbu)
 #
 # -------------------------------------------------------------------------
 ##

proc ring::gotoNamed {name} {
    
    _upvarStops
    
    foreach stop [array names w] {
	if {[string match $name $w($stop)]} {
	    goto $stop
	    return
	}
    }
    error "Not known"
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::nextPrompt" --
 #
 # Go to the next prompt in the current ring if one exists, whether we are in
 # the ring or not.  This is a possible behavior for "Indent Or Next Stop".
 #
 # -------------------------------------------------------------------------
 ##

proc ring::nextPrompt {} {
    
    if {![win::checkIfWinToEdit]} {return}
    
    _upvarStops

    if {![catch {currentRingPositions} positions]} {
	set char [string index $::elecStopMarker 0]
	foreach pos $positions {
	    if {[lookAt $pos] == $char} {
		goToStop [lindex $stops $idx]
		return
	    }
	}
    }
    # Still here?
    status::msg "Couldn't find prompt."
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::unsetBTWindowVars" --
 #
 # Forget all vars associated with this window.  (Temporary marks will
 # magically disappear.)
 #
 # -------------------------------------------------------------------------
 ##

proc ring::unsetBTWindowVars {windowName} {
    
    # namespace problem - need to remove all colons.
    # array problem - need to remove all ( )
    set x [string map {( < ) > " " "" "::" "--"} $windowName]
    
    variable elecLastStop
    variable elecNestingLevel
    variable elecRingStops
    variable elecRingPrompts$x
    
    unset -nocomplain elecLastStop($x)
    unset -nocomplain elecNestingLevel($x)
    unset -nocomplain elecRingStops($x)
    unset -nocomplain elecRingPrompts$x
}

# ===========================================================================
#
# ×××× -------- ×××× #
#
# ×××× Additional Ring support ×××× #
#
# These aren't used by this package, but required by some mode specific
# completion routines.
#

##
 # -------------------------------------------------------------------------
 #
 # "ring::replaceStopMatches" --
 #
 # Replace all stops which match 'stopPat' (a simple glob like pattern) with
 # the text '$txt'.  The stops are permanently deleted.  Returns the number
 # of stops that were replaced.
 #
 # -------------------------------------------------------------------------
 ##

proc ring::replaceStopMatches {stopPat txt} {
    
    _upvarStops
    
    set count 0
    if {![info exists stops]} {
	clear 1
    } else {
	set ringPos  [expr {[positionWithinRing] -1}]
	set ringStop [lindex $stops $ringPos]
	placeBookmark 0
	set i 0
	foreach stop $stops {
	    if {[string match $stopPat $w($stop)]} {
		if {![catch {tmark::getPos $stop} p]} {
		    if {[_deleteMarker $p]} {
			insertText $txt
			incr count
		    }
		    removeTMark $stop
		    set stops [lreplace $stops $i $i]
		    incr i -1
		}
	    }
	    incr i
	}
	# Need to back up one.  But this causes a bug in TeX
	# completions, so we have removed it.
	#ring::-
	returnToBookmark 0
	status::msg ""
    }
    return $count
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::TMarkAt" --
 #
 # Is the template stop with prompt 'name' at position 'pos'?  The 'name' is
 # the name of the enclosed prompt as in '¥environment name¥', but
 # without the bullets.  It is matched via 'string match'.
 # -------------------------------------------------------------------------
 ##

proc ring::TMarkAt {name pos} {
    
    set stop [tmark::isAt $pos]
    if {![string length $stop]} {
	return 0
    } else {
	_upvarStops
	return [string match $name $w($stop)]
    }
}

proc ring::deleteStop {} {
    _deleteStop
}

proc ring::deleteStopAndMove {} {
    _deleteStop
    _upvarStops
    _goToStop [lindex $stops 0]
}

# This really is an internal proc, but some packages might need it.
proc ring::insert {args} {
    eval _createStops $args
}

# ===========================================================================
#
# ×××× -------- ×××× #
#
# ×××× Ring internal procs ×××× #
#
# None of these should be called directly, but only by other procs defined
# within this file.
#

##
 # -------------------------------------------------------------------------
 #
 # "ring::_createStops" --
 #
 # Given a string of text that has just been inserted into the current
 # window, create a set of template stops (temporary marks) associated with
 # template prompts.  This is perhaps the most important procedure in this
 # entire package, as it creates all of the variables/marks used for all ring
 # navigation procedures.
 #
 # -------------------------------------------------------------------------
 ##

proc ring::_createStops {txt {goToFirstStop 1}} {
    
    _upvarStops
    
    variable elecPrompts
    
    # If the current position is not within the current ring, clear
    # everything to create a new ring.
    set p [positionWithinRing]
    if {$p == -1 || [incr elecNestingLevel($x)] > $::maxTemplateNesting} {
	clear
	set p 0
    }
    set level $elecNestingLevel($x)
    # Preliminaries
    set pos0 [getPos]
    set ii   [set i 0]
    if {![info exists elecPrompts]} {set elecPrompts ""}
    # Do the stop ring, extracting prompts from 'elecPrompts'
    set list1 [list]
    while {[regexp -indices -- $::elecStopMarker $txt I] == 1} {
	regsub $::elecStopMarker $txt "o" txt
	createTMark "stop${level}:$i" [pos::math $pos0 + [lindex $I 0]]
	lappend list1 "stop${level}:$i"
	set w(stop${level}:$i) [lindex $elecPrompts $i]
	incr i
    }
    if {$i > 1} {
	set pos1 [pos::math $pos0 + [string length $txt]]
	if {$level == 0} {
	    # Create new ring limits, if we have at least two stops and the
	    # nesting level is "0".  (If 'level' > 0, then the temporary
	    # marks should already be in place.)
	    createTMark "nestStart" $pos0
	    createTMark "nestEnd"   $pos1
	} elseif {[catch {tmark::getPos nestEnd} end]} {
	    # (Should never happen.)
	    createTMark "nestEnd" $pos1
	} elseif {[pos::compare $end < $pos1]} {
	    # Could easily happen with nested templates.  Make sure that the
	    # temporary nestEnd mark doesn't precede the end of the text.
	    createTMark "nestEnd" $pos1
	}
    }
    # Put the stop ring together
    set list2 [lrange $stops $p end]
    set list3 [lrange $stops 0 [expr {$p - 1}]]
    set stops [concat $list1 $list2 $list3]
    # Forget the prompt list (we've stored them in an array)
    unset -nocomplain elecPrompts
    # Go to the first stop we just inserted?
    if {$goToFirstStop} {_goToStop "stop${level}:${ii}"}
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::_upvarStops" --
 #
 # Get a local reference to the window's stopRing
 #
 # -------------------------------------------------------------------------
 ##

proc ring::_upvarStops {} {
    
    uplevel 1 {

	unset -nocomplain x
	unset -nocomplain stops
	unset -nocomplain w
	
	variable elecNestingLevel
	variable elecLastStop

	upvar x x
	set x [join [win::Current] ""]
	# namespace problem - need to remove all colons.
	regsub -all "::+" $x "--" x
	# array problem - need to remove all ( )
	set x [string map {( < ) >} $x]
	
	upvar \#0 ring::elecRingStops($x) stops
	upvar \#0 ring::elecRingPrompts$x w
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::_goToStop" --
 #
 #
 # -------------------------------------------------------------------------
 ##

proc ring::_goToStop {stop} {
    
    _upvarStops
    
    variable elecLastStop
    
    if {[catch {tmark::getPos [set elecLastStop($x) $stop]} pos]} {
	error $pos
    } else {
	goto $pos
    }
    # Remove the stop marker plus optional prompt-tag.
    _deleteMarker [getPos] [expr {$::TemplatePrompts >= 3}]
    if {$::TemplatePrompts} {
	variable templateMessage
	if {[string length $w($stop)]} {
	    set msg "Fill in '$w($stop)'"
	} else {
	    set msg "Fill in template stop"
	}
	status::msg "${msg}${templateMessage}"
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::_deleteStop" --
 #
 #
 # -------------------------------------------------------------------------
 ##

proc ring::_deleteStop {} {
    
    _upvarStops
    
    variable elecLastStop
    
    set l [lsearch -exact $stops $elecLastStop($x)]
    if {$l != -1 } {
	if {$::TemplatePrompts == 3} {
	    _deleteMarker [getPos]
	}
	set stops [lreplace $stops $l $l]
	removeTMark $elecLastStop($x)
	set elecLastStop($x) ""
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "ring::_deleteMarker" --
 #
 # Deletes the "elec stop marker" and a following tag-prompt.  The mark moves
 # to the location of the deleted text (side-effect).  Returns '1' if the
 # deletion was successful, else '0'.
 # -------------------------------------------------------------------------
 ##

proc ring::_deleteMarker {pos {h 0}} {
    
    variable _tmatch
    variable _tstart
    
    if {[lookAt $pos] != $::elecStopMarker} {return 0}
    if {$::TemplatePrompts > 1} {
	if {[lookAt [pos::math $pos + 1]] == $_tstart} {
	    set posL [pos::math $pos + 80]
	    set ppos [search -n -s -f 1 -r 1 -l $posL $_tmatch $pos]
	    if {[llength $ppos] && [pos::compare [lindex $ppos 0] == $pos]} {
		if {$h} {
		    eval selectText $ppos
		} else {
		    eval deleteText $ppos
		}
		return 1
	    }
	}
    }
    deleteText $pos [pos::math $pos + 1]
    return 1
}

# ===========================================================================
#
# ×××× ------------ ×××× #
#
# ×××× Version History ×××× #
#
#  modified by  rev    reason
#  -------- --- ------ -----------
#
#  02/24/97 VMD 0.1    Original.
#  ??/??/?? VMD -9.2.5 Various fixes and updates
#  12/19/02 cbu 9.3    Major update for Tcl 8.4
#                      Reorganized procedures, renamed most of them, removed
#                        those which are never used.
#                      All of the 'ring' procs are now redefined only once,
#                        when the package is first initialized.  When this
#                        package is disabled, we just set one variable that
#                        will redirect us to the earlier definitions.
#                        (Previous versions of this package would re-source
#                        either "templates.tcl" or this file each time the
#                        package was turned on and off.
#                      Fix to reset template search pattern when the pref for
#                        "elecStopMarker" is changed.
#                      Fix to enhance nested ring insertions.  (Earlier versions
#                        often cleared the ring, even if we were in it.)
#                      Added support to "bind::IndentOrNextstop" to check to
#                        see if there is an 'untouched' template prompt in
#                        the current ring, even if we are out of the ring.
#                        Otherwise, being out of the ring automatically clears
#                        it, which might not be desired.  (This is questionable
#                        behavior, subject to more debate.  The default behavior
#                        has not been changed.)
#                      Improved 'help' argument.
#                      Even if 'TemplatePrompts' is set to '0', we still add
#                        colors to the prompts, so long as this package is
#                        activated.
#                      New 'TemplatePrompts' option to auto-clear the prompt
#                        if it is still highlighted when advancing.
#

# ===========================================================================
#
# .