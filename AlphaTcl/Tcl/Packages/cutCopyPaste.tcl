## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 #
 # FILE: "cutCopyPaste.tcl"
 #                                          created: 01/29/2002 {02:50:59 pm}
 #                                      last update: 03/21/2006 {02:06:11 PM}
 # Description:
 # 
 # Adds additional 'smart' Clipboard Utilities as described below.
 # 
 # Alpha8/X/tk binaries provide core [alpha::<cut|copy>Region] commands that
 # are used by the SystemCode [cut|copy] procedures.  This package redefines
 # these Clipboard procedures, providing additional "smart" functions as
 # described below in the 'help' argument for the feature declaration.
 # 
 # The standard [cut|copy|paste] operations called by the user via the Edit
 # menu always take place in the current window, but all of the extra
 # functionality provided here accepts an optional ?-w win?  argument.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # 'Cut Paste Whitespace' is based on the 'Smart Cut Paste' function which
 # previously provided by the package: copyRing.  Original "copyRing" by
 # Dominique d'Humieres <dominiq@physique.ens.fr> following ideas from Juan
 # Falgueras <juanfc@lcc.uma.es>
 #
 # Copyright (c) 1994-2006  Juan Falgueras, Dominique d'Humieres,
 #                          Vince Darley and Craig Barton Upright
 #
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ×××× Feature Declaration ×××× #
alpha::feature clipboardPreferences 1.3 "global-only" {
    # This used to be defined in "copyRing.tcl"
    prefs::renameOld smartCutPaste cutPasteWhitespace
    # To use the Window Pin for the default region when cutting and pasting
    # should there be no current selection, turn this item on||To only peform
    # [cut] and [copy] operations when there is a selection in the window, turn
    # this item off
    newPref flag cutAndCopyUsingPin 0 global
    # To adjust the whitespace when cutting or pasting a word in the current
    # window, turn this item on||To disable the adjustment of whitespace when
    # cutting or pasting a word in the current window, turn this item off
    newPref flag cutPasteWhitespace 0 global
    # After pasting with, the region that was just inserted can be
    # highlighted.
    newPref var  selectAfterPaste   0 global "" \
      [list "Never" "Only if pasting over selection" "Always"] index
    # Includes items to Cut, Copy, and Paste into the active window
    newPref flag clipboardMenu 0 contextualMenu
    menu::buildProc "clipboard" {cutCopyPaste::buildClipboardCM}
} {
    # Activation script.
    # 
    # We redefine [cut|copy|paste] using [hook::procRename], ensuring that
    # our versions will get used.  This allows us to modify and reload the
    # 'core' versions without affecting any of the [hook::procRename] actions
    # that might take place following other package activations.
    foreach ccpItem [list cut copy paste] {
	hook::procRename ::$ccpItem ::cutCopyPaste::${ccpItem}
    }
    unset ccpItem
    # Add the preferences to "global" dialog panes.
    lunion flagPrefs(Text) cutAndCopyUsingPin cutPasteWhitespace
    lunion varPrefs(Text)  selectAfterPaste
} {
    # Deactivation script.
    foreach ccpItem [list cut copy paste] {
	hook::procRevert ::cutCopyPaste::${ccpItem}
    }
    unset ccpItem
    # Remove the preferences to "global" dialog panes.
    set flagPrefs(Text) [lremove $flagPrefs(Text) [list \
      "cutAndCopyUsingPin" "cutPasteWhitespace"]]
    set varPrefs(Text) [lremove $varPrefs(Text) [list "selectAfterPaste"]]
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} uninstall {
    this-file
} description {
    This package provides preferences for additional Clipboard Utilities
} help {
    This package provides preferences for additional Clipboard Utilities,
    such as an optional preference for 'Cut Copy Whitespace' to ensure that
    the cutting/pasting of a word will adjust the whitespace surrounding it
    in a context specific way.

		Table Of Contents

    "# Additional Clipboard Utilities"
    "#   Reselect After Paste"
    "#   Cut And Copy Using Pin"
    "#   Cut Paste Whitespace"
    "# Mode Preference Over-rides"
    "# Contextual Menu Module"

    <<floatNamedMarks>>


		Additional Clipboard Utilities

    In addition to the automatic indentation of pasted text provided by the
    package: smartPaste, additional Cut/Copy/Paste functions can be added to Alpha
    by turning on this feature.
   
    Preferences: Features
   
    Settings for "# Reselect After Paste", "# Cut And Copy Using Pin", and
    "# Cut Paste Whitespace" can then be changed in the dialog pane found
    in "Config > Preferences > Interface Preferences > Text"
    
    Preferences: Text

			Reselect After Paste

    If the "Reselect After Paste" pref is set then the text string that was
    just pasted into the window will be highlighted.  This can take place
    after every paste, or only when you're pasting over a selection.
    
    This function is ignored for rectangular editing.

			Cut And Copy Using Pin

    Normally, you must have a region selected in order to user [cut] or
    [copy] -- otherwise there is no text to use for the clipboard.  Alpha,
    however, maintains a Window Pin -- a temporary floating mark for every
    window -- that can be used to create this region if you have not selected
    one already.  You can set the "Cut And Copy Using Pin" preference to use
    this region if desired for all cutting/copying operations.

    If there is already a region selected, that selection will always be used
    by default.  When there is no selection, both [cut] and [copy] will
    essentially be shortcuts for two consecutive operations:

    (1) "Search > The Pin > Hilite To Pin"
    (2) "Edit > Cut/Copy"

    Following a [copy] operation using the pin, the region copied will be
    automatically highlighted so that you know exactly what was placed into
    the clipboard.

    You can set the Window Pin by selecting "Search > The Pin > Set Pin",
    move to some different position in the window, and then [copy] the region
    between the pin and the cursor.  If you have any experience with 'emacs',
    then you are probably familiar with such 'window mark' in cut/copy
    operations

    Note that some AlphaTcl functions reset the Window Pin silently, such as
    selecting text and some text insertion operations, so in general you
    should set the pin 'manually' and then cut/copy the text relatively soon
    to ensure that you are manipulating the region that you actually want.
    (Experiment with the "The Pin > Hilite To Pin" menu item and binding for
    a while to get used to the setting of the pin and learn what the region
    looks like.)

			Cut Paste Whitespace

    This preference will adjust the whitespace surrounding cut/pasted text to
    ensure that there is not too much or too little.  For example, if the
    text string in the window looks like

	This is a test of |whitespace| adjustments
			   ^^^^^^^^^^

    and the 'whitespace' string is highlighted, performing a [cut] will
    remove one of the surrounding spaces, resulting in

	This is a test of| adjustments

    (where '|' indicates the cursor) rather than

	This is a test of | adjustments

    This may seem trivial, but once you begin using it you'll realize how
    many times a cut must be followed by a combination of arrow key
    navigation and delete keys.  When pasting, whitespace is added if one and
    only one side of the current position has whitespace.

    This is a somewhat 'conservative' feature, in that we tend to error on
    the side of leaving whitespace as is in ambiguous situations.  For
    example, if the text to be cut/pasted has any whitespace at its own
    borders then we make no adjustment.  It does, however, make an attempt to
    look at the surrounding text so that pasting next to a double quote
    (e.g.) will add whitespace as necessary, so the pasting here:
    
	This is another "|test of this feature"

    will result in
    
	This is another "interesting test of this feature"
    
    The whitespace is always adjusted after the [cut|paste] operation takes
    places, so it will be the first [undo] item available.

    This function is ignored for rectangular editing.

		Mode Preference Over-rides

    The three preferences in the Preferences: Text dialog (those specific
    to "Cut Copy Paste" utilities) are 'global' in the sense that they
    apply to every mode for which this package is activated.  It is
    possible, however, to turn them on/off for any mode.  For example, the
    'Cut Paste Whitespace' pref might be very useful for TeX mode, but less
    so for C++ or other computer language 'syntax' modes.

    You can define a mode specific preference for any of these items by
    including a couple line of AlphaTcl code in "prefs.tcl" file.  For
    example, to turn off "Cut Paste Whitespace" feature in Tex mode, add

	newPref flag cutPasteWhitespace 0 Text

    This preference can then be adjusted with the dialog that appears with
    the "Config > Text Mode Prefs > Preferences" menu item.

    Use these lines of code to define such mode preferences for each mode
    desired, where '<mode>' is the name of the mode for which you want
    specific behavior:

	newPref flag cutAndCopyUsingPin 0 <mode>
	
	newPref flag cutPasteWhitespace 0 <mode>
	
	newPref var  selectAfterPaste   0 <mode> "" \
	  [list "Never" "Only if pasting over selection" "Always"] index

    You must do this for each mode -- if the mode of the given window does
    not have such a preference, then the 'normal' global preferences are
    used.
    
    
		Contextual Menu Module
    
    A Contextual Menu module named "Clipboard Menu" is also made available by
    this package.
    
    Preferences: ContextualMenu
    
    In addition to the standard Cut Copy Paste items, you can move the
    selected region to the "target" click-position, or place a copy of it at
    that position.  These functions are similar to "Drag And Drop".


    If you have any additional Clipboard Utilities you'd like to add to
    this package, please contact the maintainer listed above.
}

# ×××× -------- ×××× #

proc cutCopyPaste.tcl {} {}

# ===========================================================================
#
# ×××× Core Command Redefinitions ×××× #
#

namespace eval cutCopyPaste {
    
    # Make sure that we have these vars in place.
    variable reselect         0
    variable whiteSpaceAdjust 0
    variable whiteSpaceLeft   0
    variable whiteSpaceRight  0
}

##
 # --------------------------------------------------------------------------
 #
 # "cutCopyPaste::cut" --
 # "cutCopyPaste::copy" --
 # "cutCopyPaste::paste" --
 #
 # These are called by [cut|copy|paste] due to the [hook::procRename] magic.
 # The goals in each case include:
 # 
 # (1) Determine if the action can be taken
 # (2) Remember any context information that might be required later
 # (3) Perform the desired Clipboard action
 # (4) Make any further adjustments as necessary
 # (5) Return an empty string
 #
 # --------------------------------------------------------------------------
 ##

proc cutCopyPaste::cut {args} {
    
    win::parseArgs w
    
    if {![win::checkIfWinToEdit $w]} {
	return
    } 
    if {![cutCopyPaste::checkSelection -w $w "cut"]} {
	return
    }
    cutCopyPaste::checkWhitespace -w $w "cut"
    hook::procOriginal "::cutCopyPaste::cut" -w $w
    cutCopyPaste::adjustWhitespace -w $w "cut"
    return
}

proc cutCopyPaste::copy {args} {
    
    win::parseArgs w
    
    if {![cutCopyPaste::checkSelection -w $w "copy"]} {
	return
    }
    hook::procOriginal "::cutCopyPaste::copy" -w $w
    return
}

proc cutCopyPaste::paste {args} {
    
    win::parseArgs w
    
    variable reselect [isSelection -w $w]
    variable ranges
    
    if {![win::checkIfWinToEdit $w]} {
	return
    }
    cutCopyPaste::checkWhitespace -w $w "paste"
    set ranges [hook::procOriginal "::cutCopyPaste::paste" -w $w]
    cutCopyPaste::adjustWhitespace -w $w "paste"
    cutCopyPaste::reselectAfterPaste -w $w
    return $ranges
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Cut Copy Paste Support ×××× #
#

##
 # --------------------------------------------------------------------------
 #
 # "cutCopyPaste::checkSelection" --
 #
 # Check to see if we have a selection, and if not then if we should try to
 # use the Window Pin.  [hiliteToPin] might not create a selection!
 #
 # The order in which we perform these tests is very specific.
 #
 # --------------------------------------------------------------------------
 ##

proc cutCopyPaste::checkSelection {args} {
    
    global cutAndCopyUsingPin
    
    win::parseArgs w action
    
    if {[isSelection -w $w]} {
	# No need to check any further situations.
	set result 1
    } elseif {$cutAndCopyUsingPin} {
	hiliteToPin -w $w
	set result [isSelection -w $w]
    } else {
	# All other cases dealt with, and no selection to use.
	set result 0
    }
    if {!$result} {
	status::msg "Cancelled -- no region available to $action."
    }
    return $result
}

##
 # --------------------------------------------------------------------------
 #
 # "cutCopyPaste::checkWhitespace" --
 #
 # If the user has selected the preference for 'cutPasteWhitespace', then we
 # check before performing a cut/paste to find out if any whitespace
 # surrounding the target region should be adjusted following the action.
 #
 # The test that we perform concern not just the surrounding whitespace, but
 # also whether the adjacent text is really a 'word'.  We try to be a little
 # conservative here, setting 'whiteSpaceAdjust' to 0 if there's any doubt
 # about what really should be done.
 # 
 # --------------------------------------------------------------------------
 ##

proc cutCopyPaste::checkWhitespace {args} {
    
    global cutPasteWhitespace wordBreak
    
    variable whiteSpaceAdjust 0
    variable whiteSpaceRight
    variable whiteSpaceLeft
    
    win::parseArgs w action
    
    # Should we adjust surrounding whitespace?
    if {!$cutPasteWhitespace} {
	return
    }
    # Preliminary test -- if our region has any whitespace at the borders,
    # then we're not going to mess with anything.
    switch -- $action {
	"cut"   {set txt1 [getSelect -w $w]}
	"paste" {set txt1 [getScrap]}
    }
    if {([string trim $txt1] ne $txt1)} {
	return
    }
    # 'txt2/3' are the non-whitespace strings up to our region.  If our
    # region is the entire line (less any leading/trailing whitespace), we'll
    # do nothing.
    set txt2 [getText -w $w [pos::lineStart -w $w] [getPos -w $w]]
    set txt3 [getText -w $w [selEnd -w $w] [pos::lineEnd -w $w]]
    set txt2 [string trimleft  $txt2]
    set txt3 [string trimright $txt3]
    if {![string length $txt2] && ![string length $txt3]} {
	return
    }
    # 'wsLeft/Right' are the whitespace strings touching our region.
    regexp -- {([^\t ]*)([\t ]*)$} $txt2 allofit textLeft wsLeft
    regexp -- {^([\t ]*)([^\t ]*)} $txt3 allofit wsRight textRight
    # Set these now, although we might adjust them later.  The variables
    # 'whiteSpaceLeft/Right' are the lengths of whitespace that is currently
    # touching our region.
    set whiteSpaceAdjust 1
    set whiteSpaceLeft   [string length $wsLeft]
    set whiteSpaceRight  [string length $wsRight]
    # As always, there are some special cases to deal with.
    set regTest1 [regexp -- "${wordBreak}$" $textLeft]
    set regTest2 [regexp -- "^${wordBreak}" $textRight]
    switch -- $action {
	"cut" {
	    # 'whiteSpaceLeft/Right' will indicate how much whitespace should
	    # be removed from the region following a cut.
	    if {$whiteSpaceLeft && $whiteSpaceRight} {
		# This is the amount of whitespace that we're going to
		# delete, so decrease it by one.  That way we're sure to
		# leave one space there.
		incr whiteSpaceLeft -1
	    } elseif {$whiteSpaceLeft && $regTest1 && !$regTest2} {
		# Whitespace to the left, word to the left, non word char to
		# the right, so we'll leave this all as is so that we shift
		# text to touch the punctuation characters.
		return
	    } elseif {$whiteSpaceRight && !$regTest1 && $regTest2} {
		# Whitespace to the right, non word char to the left, word to
		# the right, so we'll leave this all as is so that we shift
		# text to touch the punctuation characters.
		return
	    } elseif {[string length $txt2] && [string length $txt3]} {
		# We're not at the start/end of a line, and one of the values
		# is already 0, so we probably should not be adjusting
		# whitespace.  Err on the side of doing nothing.
		set whiteSpaceAdjust 0
	    }
	}
	"paste" {
	    # A little bit more complicated here, but not so bad.  In this
	    # case 'whiteSpaceLeft/Right' is going to indicate what white
	    # space is already present, so a value of '0' is going to trigger
	    # the addition of whitespace, while '1' will turn this off (even
	    # if there isn't really any whitespace there.)
	    
	    # Are we at the start of a line?
	    if {![string length $txt2]} {
		set whiteSpaceLeft  1
	    }
	    # Are we at the end?
	    if {![string length $txt3]} {
		set whiteSpaceRight 1
	    }
	    # Perform some tests.
	    if {$whiteSpaceLeft && $whiteSpaceRight} {
		# No adjustments need to be made.
		set whiteSpaceAdjust 0
	    } elseif {!$whiteSpaceLeft && !$whiteSpaceRight} {
		# No whitespace -- if we're between a word and a non-word,
		# then we'll add some space to one side or the other.
		if {($regTest1 && $regTest2) || (!$regTest1 && !$regTest2)} {
		    # We're either in the middle of a word, or else in the
		    # middle of symbols (like "" perhaps), so do nothing.
		    set whiteSpaceAdjust 0
		} else {
		    # One side is a word, the other isn't (possibly some sort
		    # of punctuation mark), so only add whitespace on the
		    # side that has the word -- indicated by setting the
		    # other side to a positive value.
		    set whiteSpaceLeft  $regTest2
		    set whiteSpaceRight $regTest1
		}
	    } elseif {!$whiteSpaceLeft && $whiteSpaceRight && !$regTest1} {
		# Only add to the left if it is a word.
		set whiteSpaceAdjust 0
	    } elseif {$whiteSpaceLeft && !$whiteSpaceRight && !$regTest2} {
		# Only add to the right if it is a word.
		set whiteSpaceAdjust 0
	    }
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "cutCopyPaste::adjustWhitespace" --
 #
 # Deal with any whitespace manipulation.  We're doing this last so that
 # restoring any previous whitespace will be the first undo.  If adjusting
 # during a [paste], we make sure that the "ranges" variable is adjusted as
 # well so that it can be properly returned and used by other procs.  If the
 # "ranges" variable has more than two positions, then we're dealing with a
 # rectangular paste and as of this writing we can't handle that.
 #
 # --------------------------------------------------------------------------
 ##

proc cutCopyPaste::adjustWhitespace {args} {
    
    variable ranges
    variable whiteSpaceLeft
    variable whiteSpaceRight
    variable whiteSpaceAdjust
    
    if {!$whiteSpaceAdjust} {
	return
    }
    
    win::parseArgs w action {varName ""}
    
    switch -- $action {
	"cut" {
	    set pos0 [getPos -w $w]
	    set pos1 [selEnd -w $w]
	    if {$whiteSpaceLeft} {
		set pos  [pos::math -w $w $pos0 - $whiteSpaceLeft]
		deleteText -w $w $pos $pos0
		set pos1 [pos::math -w $w $pos1 - $whiteSpaceLeft]
	    }
	    if {$whiteSpaceRight} {
		set pos  [pos::math -w $w $pos1 + $whiteSpaceRight]
		deleteText -w $w $pos1 $pos
	    }
	    goto -w $w $pos1
	}
	"paste" {
	    if {([llength $ranges] > 2)} {
		return
	    }
	    set pos0 [lindex $ranges 0]
	    set pos1 [lindex $ranges 1]
	    if {!$whiteSpaceLeft} {
		goto -w $w $pos0
		insertText -w $w " "
		set pos0   [pos::math -w $w $pos0 + 1]
		set pos1   [pos::math -w $w $pos1 + 1]
		set ranges [list $pos0 $pos1]
	    }
	    if {!$whiteSpaceRight} {
		goto -w $w $pos1
		insertText -w $w " "
	    }
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "cutCopyPaste::reselectAfterPaste" --
 #
 # Determine if we should select the text that we just pasted in.  If the
 # "ranges" variable has more than two positions, then we're dealing with a
 # rectangular paste and as of this writing we can't handle that.
 #
 # --------------------------------------------------------------------------
 ##

proc cutCopyPaste::reselectAfterPaste {args} {
    
    global selectAfterPaste
    
    variable reselect
    variable ranges
    
    if {([llength $ranges] > 2)} {
	return
    }
    
    win::parseArgs w
    
    set pos0 [lindex $ranges 0]
    set pos1 [lindex $ranges 1]
    # Should we re-highlight the region we just pasted into?
    if {([expr {$reselect + $selectAfterPaste}] < 2)} {
	goto -w $w $pos1
    } else {
	selectText -w $w $pos0 $pos1
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Contextual Menu support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 #       
 # "cutCopyPaste::buildClipboardCM" --
 # "cutCopyPaste::clipboardCMProc" --
 #      
 # Build the "Clipboard" menu module for the Contextual Menu.  As with all CM
 # items, if the click position is within a selected region, the functions
 # will operate on that region.  Otherwise, "Cut" and "Copy" will place the
 # word surrounding the click position into the clipboard, and "Paste" will
 # insert the current Clipboard Contents at the click position without
 # deleting any other text.
 # 
 # --------------------------------------------------------------------------
 ##

proc cutCopyPaste::buildClipboardCM {} {
    
    set inSelect [contextualMenu::isSelection]
    set inWord   [string length [lindex [contextualMenu::clickWord] 0]]   
    if {$inSelect || $inWord} {
	set dim ""
    } else {
	set dim "("
    }
    if {[::isSelection] && !$inSelect} {
	set menuList [list "insertSelection" "moveSelection" "(-)"]
    } 
    lappend menuList "${dim}cut" "${dim}copy" "paste"
    return [list build $menuList {cutCopyPaste::clipboardCMProc}]
}

proc cutCopyPaste::clipboardCMProc {menuName itemName} {
    
    global alpha::CMArgs
    
    set clickPos [lindex ${alpha::CMArgs} 0]
    switch -- $itemName {
	"insertSelection" {
	    ::copy
	    goto $clickPos
	    ::paste
	    refresh
	}
	"moveSelection" {
	    if {[pos::compare $clickPos > [selEnd]]} {
		set lengthFromEnd [pos::diff $clickPos [maxPos]]
		::cut
		goto [pos::math [maxPos] - $lengthFromEnd]
	    } else {
	        ::cut
		goto $clickPos
	    }
	    ::paste
	    refresh
	}
	"paste" {
	    if {![contextualMenu::isSelection]} {
		goto $clickPos
	    } 
	    ::$itemName
	}
	"cut" - "copy" {
	    if {![contextualMenu::isSelection]} {
		eval [list selectText] [lrange [contextualMenu::clickWord] 1 2]
	    }
	    if {![::isSelection]} {
		error "Cancelled -- no text to [string totitle $itemName]."
	    } 
	    ::$itemName
	} 
	"paste" {
	    if {![contextualMenu::isSelection]} {
		goto $clickPos
	    } 
	    ::$itemName
	}
    }
}


# ===========================================================================
#
# ×××× ------------ ×××× #
#
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 01/29/02 cbu 0.1    Original, which attempted to separate some of the
#                       features from 'copyRing' into a different package.
#                     The main change is that we no longer try to revert
#                       previous [cut|copy|paste] procs back to 'original'
#                       versions, because other packages might have redefined
#                       them after we were activated.
#                     Added 'reselectAfterPaste' preference.
# 03/31/02 cbu 0.2    Added some utilities previously found in the package
#                       "copyRing", such as 'cutPasteWhitespace'
#                     Added 'cutAndCopyUsingPin' preference, which was
#                       previously a global pref in AlphaTcl.  (That one
#                       really should be removed, and the core [cut|copy]
#                       commands need only check for a selection now before
#                       performing action.)
#                     New [cutCopyPaste::testPackage] proc/hyperlink
#                     New [cutCopyPaste::pkg_options] proc/hyperlink
#                     Improved 'help' argument.
#                     'reselectAfterPaste' renamed to 'selectAfterPaste',
#                       and is now a 'var' pref with 3 options.
#                     User can define mode prefs for automatic indentation
#                       of pasted text, as well as 'cutPasteWhitespace'
#                       and 'selectAfterPaste'.  These always take precedence
#                       over package prefs, though if the package is turned
#                       off then we do nothing.
# 02/03/03 cbu 1.0b1  Resurrected this package, in order to avoid burdening
#                       "smartPaste" with all of this functionality.
#                     More stuff called through 'cutCopyPaste' namespace.
#                     Simplified initialization script.
#                     Activation now checked in [cutCopyPaste::cut|copy|paste],
#                       as well as read-only windows.
# 02/07/03 cbu 1.0b1  Minor fix to ensure that 'activated' is always set.
#                     Further simplifications to init/(de)activate scripts.
# 03/24/03 cbu 1.0    Both "copyRing" and "smartPaste" now use the new
#                       [hook::procRename] etc procs.  This package was
#                       redesigned to be a core 'alwaysOn' package so that
#                       we intervene in [cut|copy|paste] before any other
#                       package has a chance to change things.
#                     We now take over the 'cutAndCopyUsingPin' preference,
#                       and the redefining into [alpha::cutRegion] etc.
#                     This package is never turned off, so the 'activated'
#                       variable is now obsolete.
#                     Added check for ?-w window? arguments.
# 07/28/03 cbu 1.0.1  Reimplemented use of [global].
#                     Replaced use of "==" with "eq".
# 09/05/03 cbu 1.1    Added "Clipboard" contextual menu module.
# 01/26/04 cbu 1.1.1  Better handling of "-w $win" arguments.
# 02/26/04 cbu 1.2    This is now an [alpha::library] package.  It can be
#                       uninstalled by the user, by so long as it is present
#                       in AlphaTcl the new prefs will be added and used
#                       appropriately in all cut/copy/paste operations.
#                     We now use [hook::procRename] and [hook::procOriginal]
#                       to call previously defined Clipboard commands.
#                     Renamed "Cut Copy Paste Utilities"
# 03/12/04 cbu 1.3    "First In Last Out" is no longer required due to
#                       SystemCode core changes with [paste] , "ranges".
#                     This is now an [alpha::feature] package that must be
#                       turned on by the user.  Activation now sets some of
#                       the preferences so that behavior is changed.
#                     Renamed "Clipboard Preferences".
# 

# ===========================================================================
#
# .