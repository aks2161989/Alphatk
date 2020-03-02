## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 #
 # FILE: "copyRing.tcl"
 #                                          created: 03/11/1994 {09:52:00 am}
 #                                      last update: 05/23/2006 {12:30:05 PM}
 # Description:
 #
 # Remembers a history of items placed in the OS Clipboard, saving them in a
 # Clipboard Cache for inclusion in the active window using various methods
 # including an an "Edit > Clip Recorder" submenu, or by cycling through
 # recent items via a "Paste Ring".
 # 
 # All of the procedures in this file have been constructed assuming that the
 # "copyRing" package will be activated via normal AlphaTcl routines.  They
 # are not designed to be called by other code, except for those items
 # included as hyperlinks in the "Copy Ring Help" file.
 #
 # Original "copyRing" by Dominique d'Humieres <dominiq@physique.ens.fr>
 # following ideas from Juan Falgueras <juanfc@lcc.uma.es>
 #
 # Updated by Craig Barton Upright
 #
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
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
alpha::feature copyRing 1.7.4 "global-only" {
    # Initialization script.
    namespace eval copyRing {
	# We're not actually activated yet.
	variable activated   -1
	variable initialized 0
    }
    # This will force the sourcing of this file.
    copyRing::initializePackage
    # Register a quit hook to save/delete the Clipboard history cache.
    hook::register quitHook {copyRing::saveCacheFile}
} {
    # Activation script.
    hook::procRename ::cut   ::copyRing::cut
    hook::procRename ::copy  ::copyRing::copy
    hook::procRename ::paste ::copyRing::paste
    set copyRing::activated 1
    # Insert the menus.
    copyRing::insertEditMenuItems
    # Add the current Clipboard contents.
    copyRing::pushCRScrap
    copyRing::pushPRScrap
    # Register all hooks.
    hook::register   resumeHook   copyRing::resumeHook
    hook::register   activateHook copyRing::activateHook
} {
    # Deactivation script.
    hook::procRevert ::copyRing::cut
    hook::procRevert ::copyRing::copy
    hook::procRevert ::copyRing::paste
    set copyRing::activated 0
    # Disable the menus.
    copyRing::insertEditMenuItems
    # Deregister all hooks.
    hook::deregister resumeHook   copyRing::resumeHook
    hook::deregister activateHook copyRing::activateHook
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    This package allows you to retain a history of the previous items placed
    in the Clipboard so that they can be inserted later
} help {
    file "Copy Ring Help"
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

proc copyRing.tcl {} {}

##
 # --------------------------------------------------------------------------
 #
 # "namespace eval copyRing" --
 #
 # This defines some basic variables used throughout this package.  Anything
 # that looks like a preference, or something that is saved between editing
 # sessions should be defined in [copyRing::initializePackage].
 #
 # --------------------------------------------------------------------------
 ##

namespace eval copyRing {
    
    global PREFS alpha::application

    # Activation, initialization variables.
    variable activated
    if {![info exists activated]} {
	set activated -2
    }
    variable initialized
    if {![info exists initialized]} {
	set initialized -1
    }
    variable debugging
    if {![info exists debugging]} {
	set debugging 0
    }
    variable insertWhere "delete"
    
    # Clipboard Cache.
    variable cacheFolder [file join $PREFS "CopyRing"]
    variable cacheFile   [file join $cacheFolder "ClipboardCache"]
    variable carriageReturn {
}

    # Make sure that we have these vars in place.
    variable clipRecorderCMenu  "clipRecorder "
    variable clipRecorderMenu   "clipRecorder"
    variable crUtilsMenu        "Clip Recorder Utilities"
    variable cyclingRing        0
    variable setFloatWindow     "* Clip Floats *"
    variable initialSelection   ""
    variable ringPosition       0
    variable wcUtilsMenu        "Window Clips Utilities"
    variable windowClipsCMenu   "windowClips "
    variable windowClipsMenu    "windowClips"

    # Are floats available?  Very buggy in Alphatk right now.
    variable allowFloats
    if {(${alpha::platform} == "alpha") || $debugging} {
        set allowFloats 1
    } else {
        set allowFloats 0
    }
    # Define the "Clip Recorder" submenu and contextual menu.
    foreach menuClass [list "clipRecorder" "windowClips"] {
	foreach type [list "Menu" "CMenu"] {
	    set menuName ${menuClass}${type}
	    menu::buildProc [set $menuName] \
	      "copyRing::buildMenu [list [set $menuName]]" \
	      "copyRing::postBuildMenu [list [set $menuName]]"
	}
    }
    unset menuClass type menuName
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::initialize" --
 #
 # Defines package preferences, menu build procs, etc, and resets/removes old
 # variables from earlier versions.  This is designed to be called when this
 # package is first activated by "normal" AlphaTcl methods.  If it is not
 # called, most of the other procs in this source file will fail.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::initializePackage {{reset 0}} {
    
    global copyRingmodeVars alpha::platform alpha::macos \
      defLeft defTop defWidth defHeight

    variable cacheFile
    variable clipboardCache
    variable clipRecorderCMenu
    variable clipRecorderMenu
    variable crCache
    variable debugging
    variable floatingMenuGeometry
    variable floatingMenuParameters
    variable historyWindowGeometry
    variable historyWindowParameters
    variable initialized
    variable prCache
    variable setFloatWindow
    variable windowClipsMenu
    
    set savedVars [list]

    if {$reset} {
	# This is just a debugging tool
	unset -nocomplain copyRingmodeVars
    } elseif {($initialized == 1)} {
	return
    }
    # Update any old preferences.
    variable versionNumber
    if {![info exists versionNumber]} {
	set versionNumber "0.1"
    }
    # Version 1.3 changes
    if {($versionNumber < 1.3)} {
	# No longer supported in this package.
	prefs::removeObsolete smartCutPaste
    }
    # Version 1.6 changes
    if {($versionNumber < 1.6)} {
	# We don't have separate arrays for shortcuts anymore.
	prefs::renameOld copyRingBindingsmodeVars(pasteRingBinding) \
	  copyRingmodeVars(pastePreviousShortcut)
	prefs::removeObsolete copyRingBindingsmodeVars
	# We don't use these preferences anymore.
	foreach pref [list autoFloatMenu textInMenu recordPasteRing] {
	    prefs::removeObsolete copyRingmodeVars($pref)
	}
	# If the "crCache" variable was previously saved, rename and then
	# remove it.  "clipboardCache" was also the name of a scalar
	# variable in some earlier versions, but now it is an array.
	if {[info exists clipboardCache] && ![array exists clipboardCache]} {
	    unset clipboardCache
	}
	if {[info exists crCache]} {
	    set clipboardCache(globalCache) $crCache
	    prefs::removeObsolete crCache
	}
	# If the "floatingMenuParameters" variable was previously saved,
	# move it into "floatingMenuGeometry($clipRecorderMenu)"
	prefs::renameOld floatingMenuParameters \
	  floatingMenuGeometry($clipRecorderMenu)
	# If the "historyWindowParameters" variable was previously saved,
	# rename it (mainly for nomenclature consistency).
	prefs::renameOld historyWindowParameters historyWindowGeometry
    }
    # Version 1.7 changes
    if {($versionNumber < 1.7)} {
	prefs::renameOld copyRingmodeVars(pasteRingShortcut) \
	  copyRingmodeVars(pastePreviousShortcut)
    } 
    # Set and save the version number.
    set versionNumber 1.7
    lappend savedVars "versionNumber"
    
    # Flag preferences
    
    set crup {copyRing::updatePreferences}

    # Store the "Clipboard Cache" between ÇALPHAÈ editing sessions
    newPref flag rememberHistory 0  copyRing
    # Enable the recording of Clipboard actions
    newPref flag recordClipboard 1  copyRing $crup
    # Only include one copy of an item in the Clipboard Cache, even if it is
    # cut or copied multiple times
    newPref flag uniqueHistory   1  copyRing $crup
    # Include an "Edit > Clip Recorder" submenu
    newPref flag useClipRecorderSubmenu 1 copyRing $crup
    # Include an "Edit > Window Clips" submenu whose contents are unique to
    # the active window
    newPref flag useWindowClipsSubmenu  0 copyRing $crup
    
    # Inserts items from the current Clip Recorder History cache into the 
    # active window
    newPref flag "clipRecorder Menu" 0 contextualMenu
    # Inserts items from the current Window Clips History cache into the
    # active window, i.e. items that have recently been cut, copied, or 
    # pasted in the active window
    newPref flag "windowClips Menu" 0 contextualMenu

    # Variable preferences

    # The "Clip Recorder" and "Window Clips" menus will display this number of
    # recent items.
    newPref var  displayLimit     10 copyRing $crup \
      [list 5 10 15 20 25 30]
    # The "Clipboard Cache" will remember this number of recent items
    newPref var  historyLimit     30 copyRing $crup \
      [list 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
    # Items in the "Clip Recorder" and "Window Clips" menus will be truncated
    # to this length (although the full text of the history item will always
    # be inserted.)
    newPref var  menuStringLength 40 copyRing $crup \
      [list 15 20 25 30 35 40 45 50 55 60 65 70 75 80]
    # The number of recent Clipboard items retained in the Paste Ring Cache.
    newPref var  pasteRingDepth    5 copyRing $crup \
      [list 3 4 5 6 7 8 9 10 12 15 20 25 30]
    # Clipboard Cache strings will be truncated to this many characters.
    # Longer lengths might burden Alpha's memory parameters.
    newPref var  stringLimit    10000 copyRing $crup \
      [list 200 400 600 800 1000 5000 10000 25000 50000 100000 1000000]
    
    # Make sure that all of the limit prefs are valid.
    copyRing::validPrefValue

    # Menu shortcuts

    if {${alpha::macos}} {
	# The keyboard shortcut for the "Edit > Paste Previous" command
	newPref menubinding pastePreviousShortcut "/V<I<O" copyRing $crup
    } else {
	# The keyboard shortcut for the "Edit > Paste Previous" command
	newPref menubinding pastePreviousShortcut "/V<B<U" copyRing $crup
	# Use this keyboard shortcut to add the contents from the Clipboard to
	# the Clipboard Cache after you have switched back to Alphatk from
	# another application.
	newPref menubinding addClipboardContents "" copyRing $crup
    }
    # The keyboard shortcut for the "Edit > Swap Clipboard" command, which
    # swaps the current selection and the Clipboard contents
    newPref menubinding swapClipboardShortcut "/V<U<O" copyRing $crup
    
    # Make sure that we remember the last shortcuts.
    variable lastPRShortcut $copyRingmodeVars(pastePreviousShortcut)
    variable lastSCShortcut $copyRingmodeVars(swapClipboardShortcut)
    
    # Add a new pane to the "Package Preferences" dialog.
    package::addPrefsDialog copyRing
    
    # This is for emacs users -- a variation of "yank-pop"
    Bind 'y' <e> {paste-pop}
    
    # Clipboard Cache.
    if {[file exists $cacheFile]} {
	if {[catch {uplevel 1 [list source $cacheFile]} err] && $debugging} {
	    dialog::alert "Couldn't source cache file:\r\r$err"
	}
    }
    copyRing::ensureClipboardCache "globalCache"
    # Paste Ring Cache.
    if {![info exists prCache]} {
	set prCache [list]
    }
    # Clip Recorder History Window geometry parameters.
    if {![info exists historyWindowGeometry]} {
	set historyWindowGeometry \
	  [list $defLeft $defTop $defWidth $defHeight]
    }
    lappend savedVars [list historyWindowGeometry]
    # Floating menu parameters: {<left margin> <top margin> <width> <height>}
    # are used to set the positions for the floating menus.  Users can use the
    # "Clip Recorder/Window Clips Utils > Set Float Geometry" menu commands to
    # change them.
    if {![info exists floatingMenuGeometry]} {
	foreach menuName [list $clipRecorderMenu $windowClipsMenu] {
	    set floatingMenuGeometry($menuName) \
	      [list [expr {$defWidth + 20}] $defTop 200 250]
	}
    }
    lappend savedVars floatingMenuGeometry

    # Always save these.
    foreach var $savedVars {
	prefs::modified $var
    }

    # Make sure that we don't do this again.
    set initialized 1
    return "'Copy Ring' preferences, variables have been set."
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::insertEditMenuItems" --
 #
 # Insert/remove/dim/enable menus as necessary.  Called during (de)activation
 # of this package, and whenever the 'pastePreviousShortcut' changes.  In all
 # of Alpha8/X/tk the 'Edit' menu is automatically dimmed whenever there is no
 # open window, so there's no need to register dimming hooks for these items.
 # 
 # As a reminder:
 #
 # "menu::(un)insert" --
 # 
 # name, type, where, then list of items.  type = 'items' 'submenu'
 # 
 # There's a bug here in that while these two lines work:
 # 
 # menu::replaceWith Edit "$cutItem1  $cutItem2"  items $cutItem1
 # menu::replaceWith Edit "$copyItem1 $copyItem2" items $copyItem1
 # 
 # attempting to put the menu items back in (say if this package was turned
 # on, then off, then on again) won't work.  Best to just leave them in there
 # until the user restarts, and only dim menu items when deactivated.
 # 
 # --------------------------------------------------------------------------
 ##

proc copyRing::insertEditMenuItems {args} {
    
    global tcl_platform copyRingmodeVars alpha::guiNotReady
    
    variable activated
    variable clipRecorderMenu
    variable editMenuItems
    variable insertWhere
    variable windowClipsMenu
    
    set usingEditCRMenu $copyRingmodeVars(useClipRecorderSubmenu)
    set usingEditWCMenu $copyRingmodeVars(useWindowClipsSubmenu)
    
    if {([lindex $args 0] == "useClipRecorderSubmenu")} {
        # Called by the user changing the preference.
	if {$usingEditCRMenu} {
	    menu::insert   Edit submenu $insertWhere $clipRecorderMenu
	} else {
	    menu::uninsert Edit submenu $insertWhere $clipRecorderMenu
	}
	if {[info exists editMenuItems]} {
	    set idx [lsearch $editMenuItems $clipRecorderMenu]
	    if {$usingEditCRMenu && ($idx == -1)} {
	        lappend editMenuItems $clipRecorderMenu
	    } elseif {!$usingEditCRMenu && ($idx > -1)} {
	        set editMenuItems [lreplace $editMenuItems $idx $idx]
	    }
	}
	return
    }
    if {([lindex $args 0] == "useWindowClipsSubmenu")} {
	# Called by the user changing the preference.
	if {$usingEditWCMenu} {
	    menu::insert   Edit submenu $insertWhere $windowClipsMenu
	} else {
	    menu::uninsert Edit submenu $insertWhere $windowClipsMenu
	}
	if {[info exists editMenuItems]} {
	    set idx [lsearch $editMenuItems $windowClipsMenu]
	    if {$usingEditWCMenu && ($idx == -1)} {
		lappend editMenuItems $windowClipsMenu
	    } elseif {!$usingEditWCMenu && ($idx > -1)} {
		set editMenuItems [lreplace $editMenuItems $idx $idx]
	    }
	}
	return
    }

    if {($activated == 1) && ![info exists editMenuItems]} {
	set alphaTclVersion [alpha::package versions AlphaTcl]
	if {($tcl_platform(platform) == "windows")} {
	    set cutItem1   "/X<S<Bcut"
	    set cutItem2   "/X<S<B<Ucut&Append"
	    set copyItem1  "/C<S<Bcopy"
	    set copyItem2  "/C<S<B<Ucopy&Append"
	} elseif {1 || [alpha::package vcompare $alphaTclVersion 8.0b4] > 0} {
	    set cutItem1   "/X<E<Scut"
	    set cutItem2   "/X<S<I<Ocut&Append"
	    set copyItem1  "/C<E<Scopy"
	    set copyItem2  "/C<S<I<Ocopy&Append"
	} else {
	    set cutItem1   "/X<Scut"
	    set cutItem2   "/X<S<I<Ocut&Append"
	    set copyItem1  "/C<Scopy"
	    set copyItem2  "/C<S<I<Ocopy&Append"
	}
	# Insert the menus/items
	menu::insert   Edit items   $insertWhere \
	  "$copyRingmodeVars(pastePreviousShortcut)pastePrevious"
	menu::insert   Edit items   $insertWhere \
	  "$copyRingmodeVars(swapClipboardShortcut)swapClipboard"
	set editMenuItems [list "cut&Append" "copy&Append" "pastePrevious"]
	if {$usingEditCRMenu} {
	    menu::insert   Edit submenu $insertWhere $clipRecorderMenu
	    lappend editMenuItems $clipRecorderMenu
	}
	if {$usingEditWCMenu} {
	    menu::insert   Edit submenu $insertWhere $windowClipsMenu
	    lappend editMenuItems $windowClipsMenu
	}
	# These might 'fail' without throwing an error if we've already
	# inserted them once before.
	menu::replaceWith Edit $cutItem1  items $cutItem1  $cutItem2
	menu::replaceWith Edit $copyItem1 items $copyItem1 $copyItem2
    }
    if {![info exists alpha::guiNotReady]} {
	if {($activated >= 0) && [info exists editMenuItems]} {
	    foreach item $editMenuItems {
		enableMenuItem "Edit" $item $activated
	    }
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::updatePreferences" --
 #
 # Called whenever the user changes some of the "Copy Ring Preferences" that
 # are offered by the standard AlphaTcl user interface.  All of the values of
 # the preferences have been changed by the time this is called.  This proc
 # could also be used by other code in this file.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::updatePreferences {args} {
    
    variable clipRecorderMenu
    variable windowClipsMenu
    
    foreach prefName $args {
	switch -- $prefName {
	    "addClipboardContents" {
	        copyRing::buildUtilitiesList $clipRecorderMenu
		copyRing::rebuildMenus $clipRecorderMenu
	    }
	    "displayLimit" {
		copyRing::validPrefValue $prefName
		copyRing::rebuildMenus
	    }
	    "historyLimit" {
		copyRing::validPrefValue $prefName
	    }
	    "menuStringLength" {
		copyRing::rebuildMenus
	    }
	    "pastePreviousShortcut" -
	    "swapClipboardShortcut" {
	        copyRing::adjustItemShortcuts $prefName
	    }
	    "pasteRingDepth" {
		copyRing::validPrefValue $prefName
		copyRing::truncatePRCache
	    }
	    "recordClipboard" {
		copyRing::buildUtilitiesList $clipRecorderMenu
		copyRing::buildUtilitiesList $windowClipsMenu
		copyRing::rebuildMenus all quietly
	    }
	    "stringLimit" {
		copyRing::validPrefValue $prefName
		copyRing::adjustSCShortcut
	    }
	    "uniqueHistory" {
		copyRing::rebuildMenus
	    }
	    "useClipRecorderSubmenu" {
		copyRing::insertEditMenuItems $prefName
	    }
	    "useWindowClipsSubmenu" {
		copyRing::insertEditMenuItems $prefName
	    }
	}
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::validPrefValue" --
 #
 # Make sure that the limit for the given "variable" preference is a valid
 # number.  The user is alerted if any of the preferences were not legal.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::validPrefValue {args} {
    
    global copyRingmodeVars

    if {![llength $args]} {
	set args [list "displayLimit" "historyLimit" "menuStringLength" \
	  "pasteRingDepth" "stringLimit" ]
    }
    array set defaultValues {
	displayLimit            10
	historyLimit            30
	menuStringLength        40
	pasteRingDepth          5
	stringLimit             10000
    }
    set results [list]
    foreach arg $args {
	set value $copyRingmodeVars($arg)
	if {![string length $value] \
	  || ![is::UnsignedInteger $value] \
	  || ($value == 0)} {
	    if {[info exists defaultValues($arg)]} {
		set newValue $defaultValues($arg)
	    } else {
		set newValue 10
	    }
	    lappend results [list $arg $value $newValue]
	    set copyRingmodeVars($arg) $newValue
	    prefs::modified copyRingmodeVars($arg)
	}
    }
    if {[llength $results]} {
	foreach prefList $results {
	    set msg "The Copy Ring preference\
	      '[lindex $prefList 0]' was set to\
	      '[lindex $prefList 1]', but this is not a legal value.\
	      It has been reset to '[lindex $prefList 2]'."
	    dialog::alert $msg
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::adjustItemShortcuts" --
 #
 # Called when the user changes the keyboard shortcuts for "Paste Previous"
 # or "Swap Clipboard" via the prefs dialog.  If this package is still
 # active, then we remove the older menu item and replace it with the current
 # one.  Note the [menu::uninsert] never throws an error, which is useful.
 # We go to a little trouble here to ensure that it is replaced in the same
 # place as before, by removing both of the "Clip Recorder" and "Window
 # Clips" menus first, and then putting them back where they were.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::adjustItemShortcuts {prefName} {
    
    global copyRingmodeVars

    variable activated
    variable clipRecorderMenu
    variable insertWhere
    variable lastPRShortcut
    variable lastSCShortcut
    variable windowClipsMenu
    
    # Adjust the menu.
    switch -- $prefName {
	"pastePreviousShortcut" {
	    set nextPRShortcut $copyRingmodeVars(pastePreviousShortcut)
	    set nextSCShortcut $lastSCShortcut
	}
	"swapClipboardShortcut" {
	    set nextSCShortcut $copyRingmodeVars(swapClipboardShortcut)
	    set nextPRShortcut $lastPRShortcut
	}
    }
    if {($activated >= 0)} {
	# Remove the item with the old shortcut.
	if {$copyRingmodeVars(useWindowClipsSubmenu)} {
	    menu::uninsert Edit submenu $insertWhere $windowClipsMenu
	}
	if {$copyRingmodeVars(useClipRecorderSubmenu)} {
	    menu::uninsert Edit submenu $insertWhere $clipRecorderMenu
	}
	menu::uninsert Edit items $insertWhere "${lastPRShortcut}pastePrevious"
	menu::uninsert Edit items $insertWhere "${lastSCShortcut}swapClipboard"
	# Insert the item with the new shortcut.
	menu::insert   Edit items $insertWhere "${nextPRShortcut}pastePrevious"
	menu::insert   Edit items $insertWhere "${nextSCShortcut}swapClipboard"
	if {$copyRingmodeVars(useClipRecorderSubmenu)} {
	    menu::insert   Edit submenu $insertWhere $clipRecorderMenu
	}
	if {$copyRingmodeVars(useWindowClipsSubmenu)} {
	    menu::insert   Edit submenu $insertWhere $windowClipsMenu
	}
	# Enable as necessary.
	copyRing::insertEditMenuItems
    }
    switch -- $prefName {
        "pastePreviousShortcut" {
	    set lastPRShortcut $copyRingmodeVars(pastePreviousShortcut)
        }
        "swapClipboardShortcut" {
	    set lastSCShortcut $copyRingmodeVars(swapClipboardShortcut)
        }
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::testPackage" --
 #
 # A useful little proc to test out the feature.  This should only be called
 # from a hyperlink in this package's help window.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::testPackage {} {

    variable activated
    
    if {($activated < 1)} {
	package::activate copyRing
	set msg "The 'Copy Ring' package has been temporarily activated.  "
    }
    setWinInfo read-only 0
    setWinInfo shell 1
    append msg "The preferences dialogs for this package will now be opened\
      allowing you to change some menu appearance items, keyboard shortcuts,\
      etc. and then you can experiment in this window."
    alertnote $msg
    catch {prefs::dialogs::packagePrefs "copyRing"}
    if {[copyRing::floatsAvailable 1]} {
	copyRing::floatMenu
    }
    status::msg "Give the contextual menu a try !!"
    return
}

# ===========================================================================
#
# ×××× -------- ×××× #
#
# ×××× Core Command Redefinitions ×××× #
#

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::cut" --
 # "copyRing::copy" --
 # "copyRing::paste" --
 #
 # Wrappers around the previously defined versions of these core commands.
 # [copyRing::cut|copy] will reset the Paste Ring, while [copyRing::paste]
 # will set the ring position to '1' if we're not in a Paste Ring cycle.
 #
 # The [if {[llength $args]} ...]  in these procedures is a temporary
 # work-around -- previous "coreFixes.tcl" versions of [cut/copy] didn't have
 # any arguments, but current sources require them to allow for "?-w win?"
 # and automatically pass this argument.
 # 
 # If this update is included in the cvs, then we could simply assume that
 # the args are accepted and use the first conditional scripts.
 # 
 # --------------------------------------------------------------------------
 ##

proc copyRing::cut {args} {
    
    if {[llength $args]} {
	win::parseArgs w
	hook::procOriginal ::copyRing::cut -w $w
    } else {
	hook::procOriginal ::copyRing::cut
    }
    copyRing::pushCRScrap
    copyRing::pushPRScrap
    return
}

proc copyRing::copy {args} {

    if {[llength $args]} {
	win::parseArgs w
	hook::procOriginal ::copyRing::copy -w $w
    } else {
	hook::procOriginal ::copyRing::copy
    }
    copyRing::pushCRScrap
    copyRing::pushPRScrap
    return
}

proc copyRing::paste {args} {

    variable cyclingRing
    variable ringPosition

    if {[llength $args]} {
	win::parseArgs w
	createTMark -w $w pasteRingStart  [getPos -w $w]
	set ranges [hook::procOriginal ::copyRing::paste -w $w]
	createTMark -w $w pasteRingFinish [selEnd -w $w]
    } else {
	createTMark pasteRingStart  [getPos]
	set ranges [hook::procOriginal ::copyRing::paste]
	createTMark pasteRingFinish [selEnd]
    }
    if {!$cyclingRing} {
	set ringPosition 1
    }
    return $ranges
}

# ===========================================================================
# 
# ×××× Cut/Copy And Append ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "cut&Append" --
 # "copy&Append" --
 # 
 # Called by the Edit menu proc in the global namespace, we redirect to
 # the "copyRing" procedures.
 # 
 # "copyRing::cutAndAppend" --
 # "copyRing::copyAndAppend" --
 #
 # Perform a 'normal' [cut] or [copy], but then append the selection to the
 # original Clipboard contents.
 #
 # --------------------------------------------------------------------------
 ##

proc cut&Append  {} {
    
    copyRing::cutAndAppend
    return
}

proc copy&Append {} {
    
    copyRing::copyAndAppend
    return
}

proc copyRing::cutAndAppend {} {

    if {![win::checkIfWinToEdit]} {
	return
    }
    if {[catch {getScrap} oldScrap]} {
	set oldScrap ""
    }
    ::cut
    putScrap $oldScrap[getScrap]
    copyRing::pushCRScrap
    copyRing::pushPRScrap
    status::msg "Region cut, and appended to previous Clipboard contents."
    return
}

proc copyRing::copyAndAppend {} {

    if {[catch {getScrap} oldScrap]} {
	set oldScrap ""
    }
    ::copy
    putScrap $oldScrap[getScrap]
    copyRing::pushCRScrap
    copyRing::pushPRScrap
    status::msg "Region copied, and appended to previous Clipboard contents."
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "swapClipboard" --
 # 
 # Swap the current selection with the current Clipboard contents.  This will
 # throw an error if there is no selection, of if the Clipboard is empty.  We
 # use [::cut] and [::paste] to ensure that items are added to all of the
 # appropriate Clipboard caches maintained by this (or other) packages.
 #
 # --------------------------------------------------------------------------
 ##

proc swapClipboard {} {
    
    if {![win::checkIfWinToEdit]} {
	return
    }
    if {[catch {getScrap} oldScrap]} {
	error "Cancelled -- there is nothing in the Clipboard to swap."
    } elseif {![isSelection]} {
        error "Cancelled -- there is no selection in the current window\
	  to swap with the Clipboard."
    }
    set oldSelection [getSelect]
    ::cut
    putScrap $oldScrap
    ::paste
    putScrap $oldSelection
    status::msg "The previous selection has been swapped\
      with the Clipboard contents."
    return
}

# ===========================================================================
#
# ×××× ------------ ×××× #
#
# ×××× Paste Ring ×××× #
#
# Based on the "yank-pop" function of Emacs' killRing, this is a Paste Ring.
# Anytime that a [cut] or [copy] function is called, the contents of the
# Clipboard are added to a Paste Ring Cache.  Using "Edit > Paste Ring" will
# cycle through this history of previous Clipboard strings.
#

##
 # --------------------------------------------------------------------------
 #
 # "pastePrevious" --
 #
 # Called by the Edit menu proc in the global namespace, we redirect to
 # the "copyRing" procedure.
 # 
 # "paste-pop" --
 # 
 # This is for Emacs users familiar with this "yank-pop".  This isn't put into
 # any menu as a command, we assume that Emacs users are used to using
 # keyboard shortcuts for everything!
 #
 # --------------------------------------------------------------------------
 ##

proc pastePrevious   {} {
    copyRing::cycleRing
    return
}

proc paste-pop {} {
    
    copyRing::pastePop
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::pushPRScrap" --
 #
 # Remember the current Clipboard contents in our Paste Ring Cache, which can
 # be used later for cycling the ring.  Unlike the Clipboard Cache and the
 # procs that use it, the Paste Ring Cache is always updated even if package
 # pref for "recordClipboard" has been turned off by the user.
 #
 # Since we're pushing the scrap, reset the copy ring.  [removeTMark] never
 # throws an error, so there's no need to first check for the existence of
 # the temporary mark.
 # 
 # --------------------------------------------------------------------------
 ##

proc copyRing::pushPRScrap {} {
    
    global copyRingmodeVars

    variable cyclingRing
    variable prCache

    if {[catch {getScrap} newScrap]} {
	return
    }
    # Uniquify, so that we can put this one at the end.
    while {[set idx [lsearch -exact $prCache $newScrap]] > -1} {
	set prCache [lreplace $prCache $idx $idx]
    }
    lappend prCache $newScrap
    # We truncate this list, but to avoid doing it after every Clipboard
    # action we let it build up some.
    set prLength [llength $prCache]
    if {($prLength > [expr {$copyRingmodeVars(pasteRingDepth) + 25}])} {
	copyRing::truncatePRCache
    }
    # Reset the copy ring.
    foreach tempMark [list "pasteRingStart" "pasteRingFinish"] {
	removeTMark $tempMark
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::truncatePRCache" --
 #
 # Update the Paste Ring Cache to only include the "pasteRingDepth" number of
 # unique items.  This is called whenever we are executing a Paste Ring cycle,
 # and whenever the limit is exceeded by some considerable amount.  (We don't
 # call this every time that we [lappend] to the cache, in order to help
 # ensure that [cut|copy] isn't bogged down by this each time.)
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::truncatePRCache {} {
    
    global copyRingmodeVars

    variable prCache

    set prLength [llength $prCache]
    set prStart  [expr {$prLength - $copyRingmodeVars(pasteRingDepth)}]
    set prCache  [lrange $prCache $prStart end]
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::cycleRing" --
 #
 # Called by the user via the menu item or its keyboard shortcut, find out
 # 
 # (1) Are we in the middle of a Paste Ring already?
 # 
 # If so, delete the text that was inserted by the last Paste Ring call, put
 # the next item from the Paste Ring Cache into the Clipboard, call [::paste]
 # and then restore the Clipboard.
 # 
 # (2) Did we just [paste] without moving the cursor?
 # 
 # If so, we are starting the Paste Ring.  Delete the text that was inserted
 # by the last Paste Ring call, put the next item from the Paste Ring Cache
 # into the Clipboard, call [::paste] and then restore the Clipboard.
 # 
 # 
 # If neither of these are true, then we are in essence treating this as a
 # normal [::paste] and the most recent Paste Ring Cache item will be the same
 # as the current Clipboard contents.  If the user doesn't move the cursor,
 # then the next call to [pastePrevious] will actually start the ring.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::cycleRing {} {

    variable activated
    variable prCache
    
    if {![win::checkIfWinToEdit]} {
	return
    } elseif {($activated != 1)} {
	::paste
	return
    }

    # If we don't have the current Clipboard contents in the cache, we
    # should add them now.  (Some operations might change the scrap without
    # an explicit call to [cut|copy].)
    if {([lindex $prCache end] ne [getScrap])} {
	copyRing::pushPRScrap
    }
    # We're now in 'cycling' mode.
    variable cyclingRing 1
    variable ringPosition
    # These might be reset below if we're in a paste ring cycle.
    set pasteStart  [getPos]
    set pasteFinish [selEnd]
    # Trim Clipboard cache.
    copyRing::truncatePRCache
    set ringLength [llength $prCache]
    # Determine if we're in the middle of a paste ring cycle, or (if not) we
    # should treat this as a 'normal' first paste.  This assumes that no code
    # dealing with 'paste' ever inadvertantly removes temp marks.
    set tempMarks [list "pasteRingStart" "pasteRingFinish"]
    if {[catch {tmark::getPositions $tempMarks} limits]} {
	# This will fail if the temporary marks have never been created, or
	# if some Clipboard action removed them.
	set ringPosition 0
    } elseif {[pos::compare $pasteFinish != [lindex $limits 1]]} {
	# Our last paste is not the selection endpoint position.
	set ringPosition 0
    } else {
	# We have limits.  Do they correspond to the last [paste]?
	# 'txt1' refers to the text within the temporary marks.
	# 'txt2' is the 'last' item pasted via the paste ring.
	set pos0 [lindex $limits 0]
	set pos1 [lindex $limits 1]
	set txt1 [string trim [getText $pos0 $pos1]]
	set txt2 [lindex $prCache [expr {$ringLength - $ringPosition}]]
	set txt2 [string trim $txt2]
	regsub -all -- {\s+} $txt1 {°} txt1
	regsub -all -- {\s+} $txt2 {°} txt2
	if {![regexp -- [quote::Regfind $txt2] $txt1]} {
	    set ringPosition 0
	} else {
	    set pasteStart  $pos0
	    set pasteFinish $pos1
	}
    }
    # Adjust the scrap and the selection, and paste.
    set oldScrap [getScrap]
    # Record the current selection?
    if {!$ringPosition} {
	variable initialSelection [getSelect]
    }
    if {[pos::compare $pasteStart != [getPos]] || \
      [pos::compare $pasteFinish != [selEnd]]} {
	selectText $pasteStart $pasteFinish
    }
    if {([incr ringPosition] > $ringLength)} {
	# If we've reached the end of the ring, remove the selection.
	variable initialSelection
	replaceAndSelectText [getPos] [selEnd] $initialSelection
	# There's a [replaceText] glitch that occasionally occurs in Alpha8/X.
	refresh
	removeTMark pasteRingStart
	removeTMark pasteRingFinish
	set ringPosition 1
	set msg "All paste ring items have been cycled --\
	  original text has been replaced."
    } else {
	set newScrap [lindex $prCache [expr {$ringLength - $ringPosition}]]
	regsub -all -- "\r?\n" $newScrap "\r" newScrap
	if {($oldScrap ne $newScrap)} {
	    putScrap $newScrap
	}
	::paste
	putScrap $oldScrap
	set msg "Paste ring item (${ringPosition}) of (${ringLength}).  "
	if {($ringPosition == $ringLength)} {
	    append msg "Next item: (original selection)"
	} else {
	    set nextItem [lindex $prCache end-$ringPosition]
	    set nextItem [copyRing::trimItemForMenu $nextItem]
	    append msg "Next item: $nextItem"
	}
    }
    status::msg $msg
    set cyclingRing 0
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::pastePop" --
 # 
 # This isn't the most faithful implementation of "yank-pop" for Emacs users,
 # since we're not using any actual "killRing" cache.  But short of creating a
 # new "killRing" package, this is pretty good.  (The only difference is that
 # we're using the ring created by [cut|copy] operations.)
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::pastePop {} {

    variable activated
    variable ringPosition
    
    if {$activated < 1} {
	status::msg "The \"Copy Ring\" package has been turned off."
	return
    }
    if {$ringPosition == 0 && ![isSelection]} {
	if {[pos::compare [setPin] == [getPos]]} {
	    status::msg "Window pin is the same as the cursor!"
	    return
	}
	hiliteToPin
    }
    pastePrevious
}

# ===========================================================================
# 
# ×××× -------- ×××× #
#
# ×××× Clipboard History Cache ×××× #
# 

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::recordHistory" --
 # 
 # Determine if we should record the Clipboard contents in the various names
 # in the "clipboardCache" array.  If this package has been turned off, we
 # obviously do nothing, and if for some reason we can't get the scrap then we
 # should also stop.  We have a package preference for "recordClipboard" that
 # we'll check to see if the user wants to "freeze" the contents of the
 # caches.  Returns "0" if we should stop, else "1" indicating that we should
 # continue with whatever we're doing.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::recordHistory {{globalCache "1"}} {
    
    global copyRingmodeVars contextualMenumodeVars
    
    # Should we record the Clipboard in the cache?
    if {[catch {getScrap} item]} {
	# Couldn't get the scrap!
	return 0
    } elseif {!$copyRingmodeVars(recordClipboard)} {
	# Package pref turned us off.
	return 0
    } elseif {!$globalCache \
      && !$copyRingmodeVars(useWindowClipsSubmenu) \
      && !"$contextualMenumodeVars(windowClips Menu)"} {
	return 0
    } else {
	return 1
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::ensureClipboardCache" --
 #
 # Make sure that we have something in the "clipboardCache" array for the
 # given name.  We record the date that the cache was created if the cache
 # doesn't exist, which allows us to use [lindex] to find the desired item
 # when given a natural number.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::ensureClipboardCache {{cache "globalCache"}} {
    
    global copyRingmodeVars
    
    variable clipboardCache

    set usingEditWCMenu $copyRingmodeVars(useWindowClipsSubmenu)
    if {![string length $cache] && [llength [winNames]]} {
	set cache [win::StripCount [win::Current]]
    }
    if {![info exists clipboardCache($cache)]} {
	set clipboardCache($cache) [list [mtime [now] short]]
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::pushCRScrap" --
 #
 # Update the Clipboard Cache with the current Clipboard contents.  This will
 # automatically trim the list to conform to the appropriate limit for the
 # number of items remembered, and update any menus currently in use.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::pushCRScrap {} {
    
    global copyRingmodeVars

    variable clipboardCache
    variable clipRecorderMenu
    variable windowClipsMenu
    
    # Should we record the Clipboard in the cache?
    if {![copyRing::recordHistory]} {
	return
    } elseif {[catch {getScrap} item]} {
	return
    }
    # Make sure that we have a string, and that it's not too long.
    if {![set sl [string length $item]]} {
	return
    } elseif {($sl > $copyRingmodeVars(stringLimit))} {
	set item "[string range $item 0 $copyRingmodeVars(stringLimit)] ..."
    }
    # Add it to the history caches.
    set caches [list "globalCache"]
    if {[copyRing::recordHistory 0]} {
	copyRing::ensureClipboardCache [set w [win::StripCount [win::Current]]]
        lappend caches $w
    }
    foreach cache $caches {
	copyRing::ensureClipboardCache $cache
	set clipboardCache($cache) \
	  [linsert $clipboardCache($cache) 1 $item]
	if {$copyRingmodeVars(uniqueHistory)} {
	    set clipboardCache($cache) [lunique $clipboardCache($cache)]
	}
	set clipboardCache($cache) \
	  [lrange $clipboardCache($cache) 0 $copyRingmodeVars(historyLimit)]
    }
    # How do we deal with the menus?
    if {$copyRingmodeVars(useClipRecorderSubmenu)} {
	# Need to shuffle all of the menu items.
	copyRing::rebuildMenus $clipRecorderMenu quietly
    }
    if {$copyRingmodeVars(useWindowClipsSubmenu)} {
	# Need to shuffle all of the menu items.
	copyRing::rebuildMenus $windowClipsMenu quietly
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::historyWindow" --
 #
 # Open the contents of the specified Clipboard Cache in a new window.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::historyWindow {{cache "globalCache"}} {

    variable clipboardCache
    variable historyWindowGeometry

    # Only necessary when called from hypertext in help window.
    if {![package::active copyRing]} {
	package::activate copyRing
    }
    # Refine the history window name.
    if {($cache == "globalCache")} {
	set n "* Global Clipboard History *"
    } else {
        set n "* Clipboard History for \"[win::Tail]\" *"
    }
    # If there is already a history window, close it.
    if {[win::Exists $n]} {
	bringToFront $n
	set historyWindowGeometry [getGeometry]
	killWindow
    }
    # Create the header.
    set t {
Clipboard History

CACHE since HISTDATE

Click here <<Update Clipboard History>> to update this window,
or to save this window's size parameters as defaults.

Click on any blue hyperlink to place the history item's
contents into the OS Clipboard.

______________________________________________________________

}

    if {($cache == "globalCache")} {
        regsub -- "CACHE " $t "" t
    } else {
        regsub -- "CACHE"  $t "for \"[win::Tail]\"" t
    }
    regsub -- "HISTDATE" $t [lindex $clipboardCache(globalCache) 0] t
    # Add all of the appropriate Clipboard Cache items.
    if {([llength $clipboardCache($cache)] == "1")} {
	append t "(The Clipboard history is empty.)"
    } else {
	set i 1
	foreach item [lrange $clipboardCache($cache) 1 end] {
	    append t "Clipboard History Item ${i}:"
	    append t "\r\r${item}\r\r"
	    incr i
	}
    }
    set g $historyWindowGeometry
    set w [eval new -g $g [list -n $n -text $t -m Text]]
    help::colourTitle red
    win::searchAndHyperise "<<Update Clipboard History>>" \
      "copyRing::historyWindow \"${cache}\"" 1 4 +2 -2
    win::searchAndHyperise "^Clipboard History Item (\[0-9\]+):" \
      {copyRing::changeClipboard \1} 1 1
    goto -w $w [minPos -w $w]
    refresh
    setWinInfo -w $w dirty 0
    setWinInfo -w $w read-only 0
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::changeClipboard" --
 #
 # Update the Clipboard with the given item from the Clipboard Cache.  This
 # should only be called by clicking on a hyperlink in the history window.
 # This will only work with a correctly formatted history window, and we
 # implicitly assume that this is the active window when this is called.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::changeClipboard {item} {

    variable firstUpdate

    # Determine the contents of the Clipboard Cache item in the window.
    set pat "^Clipboard History Item ${item}:"
    if {![llength [set match [search -n -s -f 1 -r 1 -- $pat [minPos]]]]} {
	status::msg "Sorry, cannot find the history item."
	return
    }
    set pos0 [nextLineStart [nextLineStart [lindex $match 0]]]
    set pat  "^Clipboard History Item [incr item]:"
    if {![llength [set match [search -n -s -f 1 -r 1 -- $pat $pos0]]]} {
	set match [list [maxPos] [maxPos]]
    }
    set pos1 [pos::math [lineStart [pos::math [lindex $match 0] - 1]] - 1]
    selectText $pos0 $pos1
    copy
    incr item -1
    # Give a message to the user.
    set msg "The higlighted contents of history item number ${item}\
      are now in the Clipboard."
    if {![info exists firstUpdate]} {
	alertnote $msg
    } else {
	status::msg $msg
    }
    set firstUpdate 1
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::resumeHook" --
 #
 # Update the Clipboard Cache and the Paste Ring Cache with the current
 # Clipboard contents after switching back to Alpha from another program.
 # Note that Alphatk attempts to call this hook but under some circumstances
 # might not.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::resumeHook {args} {

    variable clipboardCache

    if {[catch {getScrap} newScrap]} {
        return
    } elseif {($newScrap eq [lindex $clipboardCache(globalCache) 0])} {
	return
    }
    # Contents of the Clipboard have changed in a different application.
    copyRing::pushCRScrap
    copyRing::pushPRScrap
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::activateHook" --
 #
 # If we are using the "Edit > Window Clips" menu, update it whenever we bring
 # a new window to the front.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::activateHook {args} {
    
    global copyRingmodeVars
    
    variable windowClipsMenu
    
    if {$copyRingmodeVars(useWindowClipsSubmenu)} {
        copyRing::rebuildMenus $windowClipsMenu quietly
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::saveCacheFile" --
 #
 # Called when Alpha is quitting.  If the user wants to remember the contents
 # of the Clipboard Cache, we save it in a special PREFS file.  This will be
 # automatically sourced the next time Alpha is launched and this package is
 # activated.  If the user doesn't want to remember the Clipboard Cache, then
 # we delete any existing cache file.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::saveCacheFile {} {
    
    global copyRingmodeVars alpha::application

    variable activated
    variable cacheFile
    variable cacheFolder
    variable carriageReturn
    variable clipboardCache
    variable debugging
    variable versionNumber

    # First delete the old cache file.
    if {[file exists $cacheFile]} {
	file delete -force $cacheFile
    }
    # Are we going to save the Clipboard Cache?
    if {($activated > 0) && $copyRingmodeVars(rememberHistory)} {
	# Quitting Alpha, save the Clipboard Cache in a file.
	set cacheHeader "# -*-Tcl-*-
# 
# Copy Ring Version VERSIONNUMBER
# 
# This file contains the contents of the Clipboard Cache that was saved /
# available when Alpha was launched.  This file is either automatically
# updated when ALPHA quits, or it is deleted if the Copy Ring preference
# for \"Remember History\" is turned off.  The \"copyRing::clipboardCache\"
# array includes items specific to existing windows.
# 
# Command-Double-Click on this proc: \[copyRing::saveCacheFile\] to see how
# this file is automatically created when ALPHA quits.
# 

"
	append cacheHeader "namespace eval copyRing {}${carriageReturn}"
	regsub -all -- {ALPHA} $cacheHeader ${alpha::application} cacheHeader
	regsub -all -- {VERSIONNUMBER} $cacheHeader $versionNumber t
	foreach item [array names clipboardCache] {
	    if {($item != "globalCache")} {
	        if {![file exists $item] || ![llength $clipboardCache($item)]} {
	            continue
	        }
	    }
	    regsub -all -- {[][\$?"()\{\}\\]} $item {\\&} name
	    append t "${carriageReturn}set \"copyRing::clipboardCache($name)\" "
	    append t "\{$clipboardCache($item)\}${carriageReturn}"
	}
	if {![file isdir $cacheFolder]} {
	    file mkdir $cacheFolder
	}
	if {![catch {alphaOpen $cacheFile "w+"} fid]} {
	    puts -nonewline $fid $t
	    close $fid
	} elseif {$debugging} {
	    set err "Could not save cache file\r\r$fid"
	    dialog::alert $err
	}
    } else {
	# Quitting Alpha, delete the Clipboard Cache folder.
	if {[file isdir $cacheFolder]} {
	    file delete -force $cacheFolder
	}
    }
    return
}

# ==========================================================================
#
# ×××× Clip Recorder Menu ×××× #
#

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::redirectMenuName" --
 #
 # Many of these procedures can be called from contextual or utilities menus,
 # and what we really want to know is the name of the proper Edit submenu that
 # should be rebuilt, or the name associated with different variables.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::redirectMenuName {{menuName ""}} {
    
    variable clipRecorderMenu
    variable crUtilsMenu
    variable wcUtilsMenu
    variable windowClipsMenu
    
    set menuName [string trim $menuName]
    if {![string length $menuName]} {
        set menuName $clipRecorderMenu
    } elseif {($menuName == $crUtilsMenu)} {
	set menuName $clipRecorderMenu
    } elseif {($menuName == $wcUtilsMenu)} {
	set menuName $windowClipsMenu
    }
    return [string trim $menuName]
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::buildUtilitiesList" --
 #
 # Create the list of utility items presented in the specific submenu being
 # inserted into the Edit menu.  This list is updated when the user performs
 # various operations, including changing some of the package preferences.
 # We make no attempt to dim/enable items here, that will occur in
 # [copyRing::postBuildMenu].
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::buildUtilitiesList {menuName} {

    global copyRingmodeVars
    
    variable clipRecorderMenu
    variable debugging
    variable utilitiesList
    
    set menuName [copyRing::redirectMenuName $menuName]
    set crUtils  [regexp -- $clipRecorderMenu $menuName]
    set menuList [list]
    if {$debugging} {
        lappend menuList "Open Prefs Cache File"
    }
    # Do we have floating menus available?
    if {[copyRing::floatsAvailable 1]} {
	lappend menuList "Float Menu"
    }
    # We only add the "Clip Recorder Utilities > Add Clipboard Contents" menu
    # command in Alphatk.
    if {$crUtils && [info exists copyRingmodeVars(addClipboardContents)]} {
	append accItem $copyRingmodeVars(addClipboardContents)
	append accItem "Add Clipboard Contents"
	lappend menuList $accItem
    }
    lappend menuList "History Window" "Reset List"
    if {$crUtils} {
        lappend menuList "Reset Paste Ring"
    }
    if {$copyRingmodeVars(recordClipboard)} {
        lappend menuList "(-)" "Stop Recording"
    } else {
        lappend menuList "(-)" "Resume Recording"
    }
    if {[copyRing::floatsAvailable 1]} {
        lappend menuList "Set Float GeometryÉ"
    }
    lappend menuList "Copy Ring PrefsÉ" "Copy Ring Help"
    set utilitiesList($menuName) $menuList
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::buildMenu" --
 #
 # Build the "Edit > Clip Recorder" or "Edit > Window Clips" submenu, or one
 # of the contextual menu modules.  This is not called directly by any code in
 # this file, but is registered above using [menu::buildProc] and called by
 # [menu::buildSome].
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::buildMenu {menuName} {
   
    global copyRingmodeVars
    
    variable clipboardCache
    variable clipRecorderMenu
    variable crUtilsMenu
    variable utilitiesList
    variable wcUtilsMenu
    variable windowClipsMenu
    
    set menuList1 [set menuList2 [list]]
    set menuProc  "copyRing::menuProc"
    set menuName  [copyRing::redirectMenuName $menuName]
    # Create the list based upon the name of the menu we're building.
    if {[regexp -- $clipRecorderMenu $menuName]} {
	set cache "globalCache"
	set utilsName $crUtilsMenu
    } elseif {[llength [winNames]]} {
	set cache [win::StripCount [win::Current]]
	set utilsName $wcUtilsMenu
	lappend menuList1 "××× [win::Tail] ×××"
    } else {
        set cache ""
	set utilsName $wcUtilsMenu
    }
    # Create the "... Utilities" menu.
    if {![info exists utilitiesList($menuName)]} {
	copyRing::buildUtilitiesList $menuName
    }
    lappend menuList1 \
      [list Menu -n $utilsName -m -p $menuProc $utilitiesList($menuName)]
    # Add all clip recorder history items.
    copyRing::ensureClipboardCache $cache
    set cacheList $clipboardCache($cache)
    for {set i 1} {$i <= $copyRingmodeVars(displayLimit)} {incr i} {
	lappend menuList2 \
	  "${i}: [copyRing::trimItemForMenu [lindex $cacheList $i]]"
    }
    # Finish building the list, and return it for building the menu.
    set menuList [concat $menuList1 "(-)" $menuList2]
    return [list build $menuList "$menuProc -m -c" {}]
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::postBuildMenu" --
 #
 # Automatically dim/enable certain menu items for the given submenu.  This is
 # not called directly by any code in this file, but is registered above using
 # [menu::buildProc] and called by [menu::buildSome].
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::postBuildMenu {menuName} {
    
    global copyRingmodeVars

    variable clipboardCache
    variable clipRecorderMenu
    variable crUtilsMenu
    variable wcUtilsMenu
    variable windowClipsMenu

    # Dim Clipboard Cache items as necessary.
    if {[regexp -- $clipRecorderMenu $menuName]} {
	set cache "globalCache"
	set utilsName $crUtilsMenu
    } else {
        set cache [win::StripCount [win::Current]]
	set utilsName $wcUtilsMenu
    }
    copyRing::ensureClipboardCache $cache
    set cacheList   $clipboardCache($cache)
    set cacheLength [llength $cacheList]
    for {set i 1} {$i <= $copyRingmodeVars(displayLimit)} {incr i} {
	set onOrOff [expr {$i < $cacheLength ? 1 : 0}]
	set item [lindex $cacheList $i]
	set item "${i}: [copyRing::trimItemForMenu $item]"
	enableMenuItem -m $menuName $item $onOrOff
    }
    # Dim other utility menu items as necessary.
    set onOrOff [expr {[llength $cacheList] > 1 ? 1 : 0}]
    enableMenuItem -m $utilsName "Reset List"     $onOrOff
    enableMenuItem -m $utilsName "History Window" $onOrOff
    # Dim the Window Clips file identifier.
    if {[regexp -- $windowClipsMenu $menuName]} {
	enableMenuItem -m $menuName "××× [win::Tail] ×××" 0
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::trimItemForMenu" --
 #
 # Create an appropriate menu item name given text in the Clipboard Cache.
 # All of Alpha8/X/tk will handle the special characters in the menu so long
 # as the "-c" is passed along to [menu::buildSome], but there are some
 # suggested substitutions are provided below in case this ever gets buggy.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::trimItemForMenu {item} {
    
    global copyRingmodeVars

    if {![string length $item]} {
        return ""
    }
    set limit $copyRingmodeVars(menuStringLength)
    if {![is::PositiveInteger $limit]} {
	set limit 30
    }
    if {([string length $item] > $limit)} {
	set item [string range $item 0 [expr {$limit - 2}]]É
    }
    regsub -all -- "(\r|\r?\n)" $item {Â} item
    return $item

    # These were required for Alpha7.
    regsub -all -- {\(|\[|\{|<} $item {Ü} item
    regsub -all -- {\)|\]|\}|>} $item {Ý} item
    regsub -all -- {!|/|&}      $item {|} item
    regsub -all -- {\^}         $item {~} item
    return $item
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::rebuildMenus" --
 #
 # Rebuilds the menu after certain actions have been taken, such as adding
 # something new to the "clipboardCache" array items.  If "args" is empty, or
 # contains the string "all" we'll rebuild all of the appropriate "Edit"
 # menus.  If there is a "quietly" item in the list of args then we don't pass
 # on any message to the user.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::rebuildMenus {args} {
    
    global copyRingmodeVars
    
    variable utilitiesList
    variable clipRecorderMenu
    variable windowClipsMenu
    
    set usingEditCRMenu $copyRingmodeVars(useClipRecorderSubmenu)
    set usingEditWCMenu $copyRingmodeVars(useWindowClipsSubmenu)
    set rebuildMenus [list]
    set quietly 0
    
    # This is a debugging tool.
    if {([set idx [lsearch $args "reset"]] > -1)} {
	unset -nocomplain utilitiesList
        set args [lreplace $args $idx $idx]
    }
    # Make sure that we have a good list of some menus to build.
    if {![llength $args] || ([lsearch $args "all"] > -1)} {
        set args [list $clipRecorderMenu $windowClipsMenu]
	set quietly 1
    }
    # Redirect some menu names to the ones we actually rebuild.
    set menuNames [list]
    foreach arg $args {
	lappend menuNames [copyRing::redirectMenuName $arg]
    }
    # Rebuild the specified menus if appropriate.
    foreach menuName $menuNames {
	if {($menuName == $clipRecorderMenu) && !$usingEditCRMenu} {
	    continue
	} elseif {($menuName == $windowClipsMenu) && !$usingEditWCMenu} {
	    continue
	} elseif {($menuName == "quietly")} {
	    set quietly 1
	} else {
	    menu::buildSome $menuName
	    lappend rebuiltMenus $menuName
	}
    }
    if {!$quietly} {
	foreach menuName $rebuiltMenus {
	    set menuName [quote::Prettify $menuName]
	    status::msg "The \"Edit > ${menuName}\" menu has been rebuilt."
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::menuProc" --
 #
 # The main menu proc for all submenus.
 # 
 # If we're going to paste in a Clipboard Cache item, we simply adjust the
 # scrap, call [paste], and the put the old scrap back in.  This is how we can
 # co-exist with 'smartPaste' or any other Clipboard packages without having
 # to redefine [paste] in any way.
 # 
 # Utility items have their own section here.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::menuProc {menuName itemName args} {
    
    global alpha::CMArgs copyRingmodeVars

    variable cacheFile
    variable clipRecorderCMenu
    variable clipRecorderMenu
    variable crUtilsMenu
    variable clipboardCache
    variable wcUtilsMenu
    variable windowClipsCMenu
    variable windowClipsMenu
    
    if {($menuName == $clipRecorderMenu) \
      || ($menuName == $clipRecorderCMenu) \
      || ($menuName == $windowClipsMenu) \
      || ($menuName == $windowClipsCMenu)} {
	# All items here relate to Clipboard Cache contents.
	requireOpenWindow
	set w [win::StripCount [win::Current]]
	# Adjust the current positions if called from the contextual menu.
	if {($menuName != [string trim $menuName])} {
	    set pos1 [lindex ${alpha::CMArgs} 1]
	    set pos2 [lindex ${alpha::CMArgs} 2]
	    selectText $pos1 $pos2
	}
	# Determine the history item that we're using.
	if {[regexp -- {^([0-9]+):.+} $itemName allofit number]} {
	    set number [string trim $number]
	} else {
	    set number 1
	}
	# Determine what we're going to paste in.
	if {[catch {getScrap} oldScrap]} {
	    set oldScrap ""
	}
	if {[regexp -- $clipRecorderMenu $menuName]} {
	    set cache $clipboardCache(globalCache)
	} else {
	    copyRing::ensureClipboardCache $w
	    set cache $clipboardCache($w)
	}
	if {![string length [set newScrap [lindex $cache $number]]]} {
	    status::msg "The history item \"${number}\" was an empty string."
	    return
	}
	# Adjust the scrap, paste, put the old scrap back in.
	regsub -all -- "(\r|\r?\n)" $newScrap "\r" newScrap
	putScrap $newScrap
	::paste
	if {[string length $oldScrap]} {
	    putScrap $oldScrap
	}
    } elseif {($menuName == $crUtilsMenu) || ($menuName == $wcUtilsMenu)} {
	# A utility item.
	if {($menuName == $crUtilsMenu)} {
	    set cache "globalCache"
	} else {
	    set cache [win::StripCount [win::Current]]
	}
	switch -- $itemName {
	    "Open Prefs Cache File" {
		if {[file exists $cacheFile]} {
		    edit -c -r $cacheFile
		} else {
		    status::msg "The clip recorder cache file doesn't exist."
		}
	    }
	    "Add Clipboard Contents" {
		if {[catch {getScrap} item]} {
		    status::msg "The Clipboard is empty."
		    return -code return
		}
		copyRing::pushCRScrap
		copyRing::pushPRScrap
		status::msg "The contents of the Clipboard have been added."
	    }
	    "History Window" {
		copyRing::historyWindow $cache
	    }
	    "Reset List" {
		unset -nocomplain clipboardCache($cache)
		copyRing::ensureClipboardCache $cache
		copyRing::rebuildMenus $menuName quietly
		set menuName [copyRing::redirectMenuName $menuName]
		set menuName [quote::Prettify $menuName]
		status::msg "The \"{$menuName}\" history has been cleared."
	    }
	    "Reset Paste Ring" {
		variable prCache [list]
		copyRing::pushPRScrap
		status::msg "The 'Paste Ring' history has been cleared."
	    }
	    "Float Menu"   {
		copyRing::floatMenu $menuName
	    }
	    "Stop Recording" {
		set copyRingmodeVars(recordClipboard) 0
		copyRing::updatePreferences "recordClipboard"
		status::msg "The Clip Recorder is no longer\
		  recording Clipboard actions."
	    }
	    "Resume Recording" {
		set copyRingmodeVars(recordClipboard) 1
		copyRing::updatePreferences "recordClipboard"
		status::msg "The Clip Recorder is now\
		  recording Clipboard actions."
	    }
	    "Set Float Geometry" {
		copyRing::setFloatGeometry $menuName
	    }
	    "Copy Ring Prefs" {
		prefs::dialogs::packagePrefs "copyRing"
	    }
	    "Copy Ring Help" {
		package::helpWindow   "copyRing"
	    }
	    default {
		error "Unknown menu command: $menuName > $itemName"
	    }
	}
    } else {
	error "Unknown menu name: $menuName"
    }
    return
}

# ==========================================================================
#
# ×××× Floating Menus ×××× #
#

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::floatsAvailable" --
 #
 # The support below for floating menus might not be available in all Alpha
 # executables, as described/defined in the namespace evaluation above.  If
 # not, we can either inform the calling proc or let the user know.
 # 
 # --------------------------------------------------------------------------
 ##

proc copyRing::floatsAvailable {{quietly 0}} {
    
    variable allowFloats
    
    if {$quietly} {
	return $allowFloats
    } elseif {!$allowFloats} {
	alertnote "Sorry, floating menus are not yet available\
	  with ${alpha::application}"
	return -code return
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::floatMenu" --
 #
 # Unfloat the menu if possible, and then float it again using the specified
 # parameters for the given menu name.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::floatMenu {{menuName ""}} {

    global alpha::application
    
    variable clipRecorderMenu
    variable crUtilsMenu
    variable debugging
    variable floatingMenuGeometry
    variable floatMenuId
    variable wcUtilsMenu
    variable windowClipsMenu
    
    # Confirm that floats are available, and if so redefine the menu name.
    copyRing::floatsAvailable 0
    set menuName [copyRing::redirectMenuName $menuName]
    # Only necessary when called from hypertext in help window.
    if {![package::active copyRing]} {
	package::activate copyRing
    }
    catch {unfloat $floatMenuId($menuName)}
    set args $floatingMenuGeometry($menuName)
    foreach {l t w h} $floatingMenuGeometry($menuName) {}
    if {![catch {
	eval [list float -m $menuName] -l $l -t $t -w $w
    } result]} {
	set floatMenuId($menuName) $result
    } elseif {$debugging && [string length $result]} {
        error::window $result
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::setFloatGeometry" --
 #
 # Unfloat the menu if possible, and the create a new window using the current
 # floating parameters.  This window contains a "Save Settings" hyperlink
 # that will call [copyRing::saveFloatGeometry].
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::setFloatGeometry {{menuName ""}} {

    global alpha::application
    
    variable floatingMenuGeometry
    variable floatMenuId
    variable setFloatWindow

    # Confirm that floats are available, and if so redefine the menu name.
    copyRing::floatsAvailable 0
    set menuName [copyRing::redirectMenuName $menuName]
    # Only necessary when called from hypertext in help window.
    if {![package::active copyRing]} {
	package::activate copyRing
    }

    catch {unfloat $floatMenuId($menuName)}
    if {[win::Exists $setFloatWindow]} {
	bringToFront $setFloatWindow
	return
    }
    # Text to include in the "Set Float Window".
    set floatWindowText {
Move and size this
window to where
you would the
MENUNAME
floating menu to
appear when the
'Float Menu' item
is selected.

Click here:
<Save Settings>
when you want to
save the new
geometry parameters.
}
    regsub -all -- {MENUNAME} $floatWindowText [quote::Prettify $menuName] t
    set n $setFloatWindow
    # Create a new window, and hyperlink text.
    set g $floatingMenuGeometry($menuName)
    set w [eval new -g $g [list -n $n -text $t -m "Text"]]
    win::searchAndHyperise {<Save Settings>} \
      "copyRing::saveFloatGeometry $menuName" 1 3 +1 -1
    setWinInfo -w $w dirty 0
    setWinInfo -w $w read-only 1
    goto -w $w [minPos -w $w]
    refresh
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "copyRing::saveFloatGeometry" --
 #
 # Called from a hyperlink [copyRing::setFloatGeometry] window that has
 # already been created, grab the current geometry of this window and use it
 # to create the new floating menu.
 #
 # --------------------------------------------------------------------------
 ##

proc copyRing::saveFloatGeometry {{menuName ""}} {

    global alpha::application
    
    variable floatingCRMenuParameters
    variable floatingMenuGeometry
    variable setFloatWindow

    # Confirm that floats are available, and if so redefine the menu name.
    copyRing::floatsAvailable 0
    set menuName [copyRing::redirectMenuName $menuName]
    # Bring the set floats window to the front, grab its geometry, close it.
    if {![win::Exists $setFloatWindow]} {
        status::msg "Cancelled -- could not find the '$setFloatWindow' window."
	return -code return
    }
    bringToFront $setFloatWindow
    set floatingMenuGeometry($menuName) [getGeometry]
    killWindow
    copyRing::floatMenu $menuName
    status::msg "The new float geometry parameters have been saved."
    return
}

# ===========================================================================
#
# ×××× ------------ ×××× #
#
# ×××× Version History ×××× #
#
# modified by  rev    reason
# -------- --- ------ -----------
# 03/11/94 ??  0.1    Original
# ?? - ??  ??  0.2.1  Various fixes throughout the years.
# 02/02/02 cbu 0.3    Implementation of "Clip Recorder", inspired by "CopyPaste"
#                     (Originally separate package, later incorporated here.)
# 10/15/02 cbu 1.0    Various minor bug fixes.
#                     Added "autoFloatMenu" preference for Alpha7 (mainly),
#                       might be necessary for Alphatk too.
# 12/09/02 cbu 1.0.1  Various minor bug fixes.
#                     Made some package prefs 'invisible'.
#                     No longer refloat menu on startup.
# 12/12/02 cbu 1.1    Some prefs array names reorganization.
#                     Prefs are no longer 'invisible'.
#                     Added [copyRing::updateVersionPreferences]
#                     Correct help file pointer.
# 01/06/03 cbu 1.1.1  Prefs dialogs not added for Alpha7.
# 01/19/03 cbu 1.1.2  Fix for 'rememberHistory' turned off so that the
#                        history var is still properly set.
# 01/31/03 cbu 1.2    Updated for Tcl 8.4 (which is now required).
#                     Also updated "smartPaste", and transferred the
#                       "smartCutPaste" functionality there.
#                     'cut/copyAndAppend' are no longer menu items, but
#                       user definable keyboard shortcut prefs.  This allows
#                       them to have 'prefix' bindings.
# 02/02/03 cbu 1.3    Everything is now in the 'copyRing' namespace,
#                       including temporary and saved variables.
# 02/03/03 cbu 1.3.1  More stuff called through 'copyRing' namespace.
#                     Better presentation of whitespace, carriage returns
#                       in "Clip Recorder" menu.
# 02/04/03 cbu 1.3.2  Added the 'cut/copy&Append' dynamic menu items back
#                       to the "Edit" menu, with safer bindings.  User-defined
#                       bindings are no longer used.
#                     When resetting the history cache, the current Clipboard
#                       contents are always added back to the list.
#                     New "Reset Paste Ring" utility.
#                     Removed [copyRing::updateVersionPreferences], replaced
#                       by the more general [copyRing::initialize].
# 02/06/03 cbu 1.3.3  [copyRing::cycleRing] now requires the cursor to be the
#                       exact ending location of the last paste to cycle.
#                     "Paste Ring" could now be used as a general replacement
#                       for "Paste" by using its default key binding.
#                     (Many thanks to Troels Petersen for recent debugging!)
# 02/07/03 cbu 1.4    Minor fix to ensure that 'activated' is always set.
#                     Further simplifications to init/(de)activate scripts.
# 03/06/03 cbu 1.4.1  After reaching the end of the paste ring, the original
#                       selected text that we were pasting over is inserted
#                       into the window.
# 03/24/03 cbu 1.5    Using new [hook::procRename] etc procs to redefine
#                       [cut|copy|paste].  Requires AlphaTcl 8.0d2 .
#                     Checks for the 'activated' variable should no longer be
#                       required nearly as much, but they're left in for now.
#                       (Still required for some operations.)
# 07/28/03 cbu 1.6    Reimplemented use of [global].
#                     Replaced use of "==" with "eq".
#                     Alphatk still has a lot of floating menu problems, so
#                       we have an "allowFloats" variable that determines if
#                       some of these items should be available.
#                     Removed "autoFloatMenu" preference, as well as some
#                       "floatMenu" keyboard shortcuts.
#                     New "clipRecorderMenu" and "clipRecorderCMenu" variables
#                       so that we can easily change their names if needed.
#                     New "useClipRecorderSubmenu" preference, if turned off
#                       then Clipboard actions are speedier.
#                     Removed "textInMenu" preference, now if the we're using
#                       the menu we always put in the text.
#                     Removed "copyRingBindingsmodeVars" array, now all prefs
#                       are stored in "copyRingmodeVars".
#                     Various [copyRing::insertEditMenuItems] subtleties.
#                     Renamed "crCache" to "clipboardCache", which is an array
#                       containing window specific Clipboard items.
#                     The "clipboardCache" array is now optionally saved
#                       between editing sessions in a separate PREFS cache file.
#                     New optional "Edit > Window Clips" menu remembers all
#                       of the window specific Clipboard actions.  This has
#                       its own separate utilities menu, and the float
#                       parameters can be set separately for the two menus.
#                     New "Window Clips" contextual menu module.
#                     Paste Ring message gives hint for next item.
#                     The "Float Menu" command is now in the utilities menus.
#                     Compensation for a [replaceText] glitch that occasionally
#                       causes "phantom text" in the window -- use [refresh].
# 10/21/03 cbu 1.6.1  Menu insertion changes for new "alphaMenus.tcl".
# 11/06/03 cbu 1.7    Renamed "Edit > Paste Ring" to "Edit > Paste Previous".
# 12/29/03 cbu 1.7.1  Default Shortcuts now use "Option" key in MacOS, as in
#                       previous version of this package.
# 01/26/04 cbu 1.7.2  Better handling of "-w $win" arguments.
# 04/27/04 cbu 1.7.3  Changed menu insertion location for AlphaTcl global
#                       menu adjustments.  Now that [menu::removeFrom] is
#                       finally fixed, could consider using that now for
#                       package deactivation.
# 06/01/05 cbu 1.7.4  Added "Swap Clipboard" menu command.
# 

# ===========================================================================
#
# .