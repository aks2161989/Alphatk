## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "statusPopupMenus.tcl"
 #                                          created: 02/29/2000 {09:40:40 AM}
 #                                      last update: 05/24/2006 {04:39:00 PM}
 # Description:
 #  
 # Provides AlphaTcl support for creating the status bar pop-up menus.  Each
 # is invoked by an "alphaHooks.tcl" procedure, calling the hooks that we've
 # registered below in the [alpha::library] script.
 #  
 # Author: Vince Darley
 # E-mail: vince@santafe.edu
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Author: Craig Barton Upright
 #
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # Copyright (c) 2004-2006 Vince Darley, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::library "statusPopupMenus" 1.1 {
    # Initialization script.
    status::initializePopups
} maintainer {
    "AlphaTcl Development Community"
} description {
    Creates the pop-up menus that appear in the status bar
} help {
    This package creates pop-up menus in the status bar.  A brief description
    for each is given below, along with hyperlinks for further information.
    
    "# Wrap Style"
    "# File Info"
    "# Current Mode"    
    "# Encodings"
    
	  	Wrap Style
    
    Each window has a "wrap" style associated with it, which determines how
    text is entered and/or displayed when a line exceeds a pre-set length.
    The initial wrap style is determined by the "Line Wrap" preference for
    the mode of the active window.  (The column in which wrapping comes into
    play is generally the "Fill Column" preference amount for the mode
    of the active window.)
    
    When you change the wrap style using the status bar pop-up menu, you are
    changing the setting only for the active window, and only for this
    editing session.  When you restart Alpha (or if you simply close and
    re-open the file) the initial style will revert to the default setting, i.e. the
    current mode's "Line Wrap" preference.
    
    Preferences: Mode
    
    See "Alpha Manual # Text Wrapping" for more information.
    
	  	File Info
    
    You can change several different settings for the active window using the
    "File Info" pop-up menu in the status bar.  Many of these will only be
    presented if the window exists as a file on a local disk.
    
	Line Endings
    
    Line endings can be set for Mac (\r), Unix (\n), or DOS/windows (\r\n).
    ÇALPHAÈ will open and edit files with any line-ending; this setting
    determines how the line-endings will be stored in the actual file.
    
    See "Alpha Manual # File formats" for more information.
    
	Window State
    
    (AlphaX only.)
    
    When "Remember Window State" is selected, the current position (including
    any selection), font settings, and window geometry is "remembered"
    between editing sessions, with the information saved in the file's
    resource fork.  Select "Forget Window State" to stop remembering.  This
    setting is specific to the active window.
    
    The "Delete Resource Fork" item will remove the contents of the current
    resource fork; this cannot be undone.
    
	File State
    
    The "Show In Finder" and "Get Info" items do what they say.
    
    On a unix platform (such as Mac OS X), you can set the "Permissions"
    associated with the file.  The initial value in the dialog reflects the
    current permissions.
    
    The "Executable" item is toggleable; when the file of the active window
    is an executable it is preceded by a bullet.
    
	Display Parameters
    
    The commands "Lock File" and "Unlock File" will toggle the "Read-Only"
    status of the active window.
    
    The commands "Show Invisibles" and "Hide Invisibles" affect the display
    all "invisible" characters such as spaces, tabs, and returns.
    
    The current font, font-size, tab-size, and indentation amount can be set
    for the active window.  If the file is set to remember the window state,
    all of these settings _except_ the indentation amount will be saved when
    the window is closed and re-opened later.  (The indentation always
    reverts to the global or mode-specific preferences.)
    
    The "Set window to defaults" item will be enabled if any of the current
    values differ from those set as your defaults in the "Appearance"
    preference settings.
    
    Preferences: Appearance
    
    Selecting this item will change all of the settings in this section to
    those defaults for the active window.
    
	Creator
    
    (Mac OS X only.)
    
    You can set the file's "Creator" and "Type" code by selecting the
    appropriate items.  If the codes are not those specified for ÇALPHAÈ, the
    "Set ÇALPHAÈ As Creator" item will be enabled.
    
	  	Current Mode
    
    The current mode of the active window is displayed in this pop-up menu as
    a bulleted item.  You can select any of the other modes listed to change
    the mode of the active window.  This change will remain in effect until
    this window is closed or you quit ÇALPHAÈ.  When you re-open the file,
    the standard algorithms for determining the initial mode for new windows
    will once again be used.
    
    By default, only a small set of ÇALPHAÈ's many installed modes are listed
    as options in this menu.  You can select "More Choices" to be presented
    with the complete list of installed modes.
    
    As new modes are loaded, they will be automatically added to the list
    presented as items in this menu.  By default, these newly loaded modes
    will be "remembered" between editing sessions for inclusion in this menu.
    The "Set Defaults" menu item allows you to adjust this list, as well as
    other preferences associated with the presentation of this menu.
    
    (Tip: use the "Browse" button in the "Set Defaults" dialog to select
    modes; this will ensure that they are spelled correctly.  Anything you
    select will be added to the dialog's current field value.)
    
    See "Alpha Manual # Modes" for more information.
    
	  	Encodings
    
    If the "Encodings" pop-up menu is present, then ÇALPHAÈ supports the
    editing of files using different encodings.  The current encoding is
    always indicated in this menu as a bulleted item.  Additional encodings
    are listed if they are included in the "Preferred Encodings" preference.
    You can select the command "Set Preferred" to adjust this list.
    
    (Tip: use the "Browse" button in the "Set Preferred" dialog to select
    encodings; this will ensure that they are spelled correctly.  Anything
    you select will be added to the dialog's current field value.)
    
    See "Alpha Manual # File encodings" for more information.
}

proc statusPopupMenus.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval contextualMenu" --
 # 
 # Ensure that the location of contextual menu modules defined by this
 # package will be presented in the proper location.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval contextualMenu {
    
    variable menuSections
    lunion menuSections(4) "formatMenu" "mode Menu" "wrapMenu"
}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval status" --
 # 
 # Define all variables required to initialize this package.  In order to
 # properly build menus, [status::initializePopups] also needs to be called.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval status {
    
    variable initialized
    if {![info exists initialized]} {
        set initialized 0
    }
    # Remember a version number for this package so that we can reset 
    # variables as needed with updates.
    variable versionNumber
    if {![info exists versionNumber]} {
        set oldVersionNumber "0.0"
    } else {
        set oldVersionNumber $versionNumber
    }
    set newVersionNumber [alpha::package versions "statusPopupMenus"]
    
    # Modes pop-up menu.
    
    variable dontExplainModeDialog
    if {![info exists dontExplainModeDialog]} {
	set dontExplainModeDialog 0
    }
    variable loadedModes
    if {![info exists loadedModes]} {
        set loadedModes [list]
    }
    
    # Rename modes from previously set preference if necessary.
    if {([alpha::package vcompare $oldVersionNumber 1.0.1] < 0)} {
	if {[info exists ::popupMenuModes]} {
	    set oldPopupModes $::popupMenuModes
	    foreach modeName $::popupMenuModes {
		lappend newPopupModes [mode::getName $modeName 1]
	    }
	    if {($oldPopupModes ne $newPopupModes)} {
	        set ::popupMenuModes $newPopupModes
		prefs::modified ::popupMenuModes
	    }
	    unset -nocomplain modeName oldPopupModes newPopupModes
	}
    }
    
    # Remember our version number.
    if {($oldVersionNumber < $newVersionNumber)} {
        set versionNumber $newVersionNumber
	prefs::modified versionNumber
    }
    unset -nocomplain oldVersionNumber newVersionNumber
}

## 
 # --------------------------------------------------------------------------
 # 
 # "status::initializePopups" --
 # 
 # Define all preferences, menu build procs, and hooks required to make this
 # package work properly.  We know that this file will be sourced after a
 # window has been opened, so do this explicitly when this package is first
 # loaded.  (This allows us to make changes to this initialization script
 # without requiring a rebuild of indices.)
 # 
 # --------------------------------------------------------------------------
 ##

proc status::initializePopups {} {
    
    variable initialized
    
    if {$initialized} {
        return
    }
    # Register our build procs.
    menu::buildProc "modeMenu"      {status::buildModeMenu} \
      {status::postBuildModeMenu}
    menu::buildProc "wrapMenu"      {status::buildWrapMenu}
    menu::buildProc "fileInfoMenu"  {status::buildInfoMenu}
    menu::buildProc "encodingMenu"  {status::buildEncodingMenu}
    
    # Modes pop-up menu.
    
    # These modes will always appear in the "Mode" pop-up menu in the status
    # bar window.  In addition to these modes, this menu will include all
    # modes which have been loaded during the current editing session.
    # "Text" mode is always included.
    newPref var "popupMenuModes" [list "BibTeX" "C" "C++" "CSS" "HTML" \
      "Python" "PHP" "Tcl" "LaTeX" "XML"]
    # To always remember the modes you've used during this editing session in
    # your set of defaults for your next session, turn this item on|| To only
    # remember the modes you've explicitly set as defaults between editing
    # sessions, turn this item off
    newPref flag "rememberLoadedPopupModes" "1"
    # To show all options in the "Mode" pop-up menu, turn this item on||To
    # only show the items included in the "Popup Menu Modes" preference in
    # the "Mode" pop-up menu, turn this item off
    newPref flag "showAllPopupModes"  "0"
    # We have something similar for the "encodings" menu.  Note that the
    # "defaultEncoding" preference is defined in "alphaDefinitions.tcl", as
    # is "preferredEncodings", and this is a good test to determine if the
    # user has any control over encodings for windows.  We could easily
    # define the "preferredEncodings" preference here, since this is the only
    # file that makes use of it.
    
    # Encodings pop-up menu.
    
    # To show all options in the "Encodings" pop-up menu, turn this item
    # on||To only show the items included in the "Preferred Encodings"
    # preference in the "Encodings" pop-up menu, turn this item off
    newPref flag "showAllPopupEncodings"  "0"
    
    # The following are only defined if we can change encodings.
    if {[info exists defaultEncoding]} {
	# To always add the encoding selected in the "Encodings" pop-up 
	# menu as a preferred option, turn this item on||To only add 
	# encodings to the preferred list "manually," turn this item off
	newPref flag "addChosenEncodingsToPreferred" "1"
	if {![info exists ::preferredEncodings]} {
	    # List your preferred encodings here to have them appear first
	    # in the popup encoding menu.
	    newPref var preferredEncodings ""
	}
    }
    
    # Contextual Menu preferences.
    
    # Allows you to change the mode of the active window
    newPref f "mode Menu" 1 contextualMenu
    menu::buildProc "mode " {status::buildModeMenu}
    # Allows you to change the current wrap style for the active window; this
    # is a duplicate of the status bar "Wrap" menu
    newPref f wrapMenu 1 contextualMenu
    menu::buildProc "wrap" {status::buildWrapMenu}
    # Allows you to change line endings, tabsize, etc,; this is a duplicate
    # of the status bar "File Info" menu
    newPref f formatMenu 1 contextualMenu
    menu::buildProc "format" {status::buildInfoMenu}
    
    # Rebuild menus in case they are floating palettes.
    hook::register activateHook         {status::activateHook}
    hook::register closeHook            {status::closeHook}
    # Register this hook to be evaluated when a new mode is loaded.
    hook::register mode::init           {status::addLoadedMode}
    # Register this hook to be evaluated when Alpha quits.
    hook::register quitHook             {status::saveLoadedModes}
    
    set initialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "status::activateHook" --
 # 
 # Rebuild status bar menus in case they are torn-off palettes.
 # 
 # --------------------------------------------------------------------------
 ##

proc status::activateHook {name} {
    
    global tearoffMenus
    
    if {!$tearoffMenus} {
        return
    }
    set menusToBuild [list "modeMenu" "wrapMenu" "fileInfoMenu"]
    if {[info exists defaultEncoding]} {
        lappend menusToBuild "encodingMenu"
    }
    foreach menuName $menusToBuild {
	menu::buildSome $menuName
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "status::closeHook" --
 # 
 # Called after a window has been closed.  If there are still active windows,
 # we do nothing because an [activateHook] will take care of any rebuilding.
 # Otherwise we rebuild all of the menus (presumably with nothing present).
 # 
 # --------------------------------------------------------------------------
 ##

proc status::closeHook {name} {
    
    global tearoffMenus
    
    if {$tearoffMenus && ![llength [winNames]]} {
	status::activateHook $name
    }
    return
}

# ===========================================================================
# 
# ×××× Mode Menu ×××× #
# 
# The "Mode" pop-up indicator indicates the mode of the active window.  When
# the user clicks on it, the menu contains all the names of the currently
# installed modes.  Selecting one will change the mode of the active window.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "status::buildModeMenu"  --
 # 
 # Create the status bar "Modes" pop-up menu.  The item "ChooseÉ" is always
 # listed near the mouse, which is why we pay attention to the global pref
 # for "locationOfStatusBar" ("1" at top, "0" at bottom").  We always make
 # sure that "Text" and the current mode are in the list.
 # 
 # --------------------------------------------------------------------------
 ##

proc status::buildModeMenu {} {
    
    global popupMenuModes locationOfStatusBar showAllPopupModes
    
    if {([win::Current] eq "")} {
        return [list "build" {"\(No Open Window"} {status::modeMenuProc -m}]
    }
    set thisMode [win::getMode [win::Current] 1]
    # Create the list of modes to offer to the user.
    if {$showAllPopupModes} {
	# The user's preference instructs us to offer all modes.
        set menuModes [mode::listAll 1]
    } else {
	set menuModes [list $thisMode "Text"]
	# Sanity check for unmatched braces/quotes in list.
	if {[catch {lindex $popupMenuModes 0} errorMsg]} {
	    beep
	    alertnote "Error in Popup Menu Modes List:\r\r$errorMsg\
	      \r\rThis must be fixed."
	    status::modeMenuProc "" "Set Defaults"
	    return [status::buildModeMenu]
	}
	# Only add defaults if they currently exist as installed modes.
	foreach modeName $popupMenuModes {
	    if {[mode::exists [mode::getName $modeName 0]]} {
		lappend menuModes [mode::getName $modeName 1]
	    }
	}
	# Add all non-internal modes loaded during this editing session.
	foreach M [mode::listAllLoaded 1] {
	    if {([lsearch [alpha::internalModes] $M] == -1)} {
		lappend menuModes $M
	    }
	}
    }
    set menuModes [lsort -dictionary -unique $menuModes]
    # Add a "Choose" option, place it near the mouse.
    if {$showAllPopupModes} {
	set chooseOrMore "ChooseÉ"
    } else {
	set chooseOrMore "More ChoicesÉ"
    }
    if {$locationOfStatusBar} {
	set menuList [concat [list $chooseOrMore "(-)"] $menuModes \
	  [list "(-)" "Set DefaultsÉ" "Modes Help"]]
    } else {
	set menuList [concat [list "Set DefaultsÉ" "Modes Help" "(-)"] \
	  $menuModes [list "(-)" $chooseOrMore]]
    }
    # Return the list required to properly build the menu.
    return [list "build" $menuList {status::modeMenuProc -m -c}]
}

proc status::postBuildModeMenu {} {
    
    if {([win::Current] ne "")} {
	catch {markMenuItem "modeMenu"  [win::getMode "" 1] 1 "¥"}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "status::modeMenuProc"  --
 # 
 # If the "itemName" is not a Mode Menu Utility, change the mode of the
 # active window to the desired new value.  If "More Choices" is selected, we
 # check to see if the original list didn't include any loaded "internal"
 # modes -- if this is the case, we offer a list-pick dialog which now
 # includes them.  (The user can then select "Show All Modes" to display all
 # of the installed options if desired.)
 # 
 # --------------------------------------------------------------------------
 ##

proc status::modeMenuProc {menuName itemName} {
    
    global popupMenuModes rememberLoadedPopupModes showAllPopupModes \
      alpha::application dialog::simple_type
    
    variable dontExplainModeDialog
    variable loadedModes
    
    set thisMode [win::getMode "" 1]
    set itemName [string trim $itemName "É"]
    switch -- $itemName {
	"Modes Help" {
	    help::openGeneral "statusPopupMenus" "Current Mode"
	    return
	}
	"Set Defaults" {
	    set oldDefaultModes $popupMenuModes
	    # Sanity check for unmatched braces/quotes in list.
	    if {![catch {lindex $popupMenuModes 0} errorMsg]} {
		set popupMenuModes [lsort -dictionary -unique $popupMenuModes]
		for {set i 0} {($i < [llength $popupMenuModes])} {incr i} {
		    set modeName [lindex $popupMenuModes $i]
		    set ModeName [mode::getName $modeName 1]
		    if {($modeName ne $ModeName)} {
			set popupMenuModes \
			  [lreplace $popupMenuModes $i $i $ModeName]
		    }
		}
		if {$rememberLoadedPopupModes} {
		    foreach m $loadedModes {
			if {([lsearch [alpha::internalModes] $m] == -1)} {
			    lappend popupMenuModes $m
			}
		    }
		    set popupMenuModes [lsort -dictionary -unique $popupMenuModes]
		}
	    }
	    # Set up some variables needed to create the dialog.
	    set width 400
	    set left  "-20"
	    set right [expr $width - 15]
	    set buttons [list \
	      "More Help" \
	      "Press this button for more information" \
	      {status::modeMenuProc {} {Modes Help} ; set retCode 0} \
	      "BrowseÉ" \
	      "Press this button to select new items" \
	      {catch {dialog::valSet $dial ","  \
	      [lsort -dictionary -unique [concat \
	      [listpick -p "Select some new favorite modes" \
	      -l -- [mode::listAll 1 0]] \
	      [dialog::valGet $dial ","]]]}} \
	      ]
	    set dialog::simple_type(popupMenuModes) \
	      "dialog::makeEditItem res script $left $right y \$name \$val 5"
	    set txt1 "The list of modes offered in this pop-up menu always includes\
	      all modes that have been loaded since ALPHA was launched, as\
	      well as the modes in the editable list below.  You can press\
	      the \"Browse\" button below to add more modes from a list of\
	      those which are currently installed."
	    set txt2 "You can also instruct ALPHA to \"remember\" all of\
	      the modes seen during this editing session in your list of\
	      saved defaults.\r"
	    set txt3 "If you want to always show all available modes, then\
	      use the checkbox below.\r"
	    regsub -all -- {ALPHA} $txt1 [set alpha::application] txt1
	    regsub -all -- {ALPHA} $txt2 [set alpha::application] txt2
	    # Create and present the dialog.
	    set dialogScript [list dialog::make -title "Initial Session Modes" \
	      -width $width -addbuttons $buttons \
	      [list "" \
	      [list "text" $txt1] \
	      [list "popupMenuModes" "" $popupMenuModes] \
	      [list "text" $txt2] \
	      [list [list "smallval" "flag"] \
	      "Remember loaded modes between sessions" \
	      $rememberLoadedPopupModes] \
	      [list "divider" "divider"] \
	      [list "text" $txt3] \
	      [list [list "smallval" "flag"] \
	      "Show all available modes in pop-up menu" \
	      $showAllPopupModes] \
	      ]]
	    set results [eval $dialogScript]
	    set msg "No changes have been made."
	    set newDefaultModes [lindex $results 0]
	    # Make sure that we have a valid list.
	    if {[catch {lindex $newDefaultModes 0} errorMsg]} {
		alertnote "Error in Popup Menu Modes List:\r\r$errorMsg"
		return [status::modeMenuProc $menuName $itemName]
	    }
	    # Now check to see if anything changed.
	    if {($oldDefaultModes ne $newDefaultModes)} {
		set popupMenuModes $newDefaultModes
		prefs::modified popupMenuModes
		set msg "The list of default pop-up menu modes has been saved."
	    }
	    set newRemember [lindex $results 1]
	    if {($newRemember ne $rememberLoadedPopupModes)} {
		set rememberLoadedPopupModes $newRemember
		prefs::modified showAllPopupModes
		set msg "Loaded modes will be\
		  [expr {$newRemember ? "now" : "no longer"}] \
		  be remembered between editing sessions."
	    }
	    set newShowAll [lindex $results 2]
	    if {($newShowAll ne $showAllPopupModes)} {
		set showAllPopupModes $newShowAll
		prefs::modified showAllPopupModes
		set msg "All modes will\
		  [expr {$newShowAll ? "now" : "no longer"}] \
		  be displayed in the in the pop-up menu."
	    }
	    if {$rememberLoadedPopupModes} {
		# These were either added or deleted by the user.
		set loadedModes [list]
	    }
	    status::msg $msg
	    return
        }
        "Choose" - "More Choices" {
	    set allModes [mode::listAll 1]
	    set p "Choose a new mode:"
	    set L [list $thisMode]
	    set itemName [listpick -p $p -L $L -- $allModes]
	}
    }
    # Change the mode of the active window.
    if {($itemName eq $thisMode)} {
	status::msg "No changes were made."
    } elseif {!$dontExplainModeDialog} {
	set dialogScript [list dialog::make -title "Mode Pop-up Menu" \
	  -width "450" \
	  -addbuttons [list \
	  "Help" \
	  "Click this button for more information" \
	  {set retCode 1 ; set retVal cancel ;  \
	  help::openGeneral {Alpha Manual} {Initial Mode Selection}}] \
	  [list "" \
	  [list "text" "You have chosen to change the mode of the active window\
	  from \"${thisMode}\" to \"${itemName}\" via the \"Modes\" pop-up menu.\
	  This will only affect the active window, and will\
	  remain in effect until this window is closed.\r"] \
	  [list "text" "You can adjust your suffix mappings (which are used to\
	  determine the initial mode when opening new files) by selecting\
	  \"Config > Global Setup > Suffix Mappings\".\r"] \
	  [list "text" "(This dialog is only displayed once per editing\
	  session, but you can avoid it forever if you want.)\r"] \
	  [list "flag" "Don't show this dialog ever again." 0] \
	  ]]
	set result [eval $dialogScript]
	set dontExplainModeDialog 1
	if {[lindex $result 0]} {
	    prefs::modified dontExplainModeDialog
	}
    }
    win::ChangeMode [mode::getName $itemName 0]
    status::msg "The new mode for \"[win::Tail]\" is \"${itemName}\"."
    status::addLoadedMode
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "status::addLoadedMode" --
 # 
 # Registered as a "mode::init" hook so that newly loaded modes can be added
 # to the list used for the mode pop-up menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc status::addLoadedMode {args} {
    
    variable loadedModes
    
    if {([set NewMode [win::getMode "" 1]] ne "")} {
	lunion loadedModes $NewMode
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "status::saveLoadedModes" --
 # 
 # Registered as a "quitHook" so that we can remember all modes which have 
 # been loaded during this editing session for inclusion in the mode pop-up 
 # menu when Alpha is restarted.
 # 
 # If you want to reset the main variables to start with a clean slate, 
 # simply set the "resetPopupModes" to "1" using
 # 
 #     set status::resetPopupModes "1"
 # 
 # This will then reset the variables with Alpha quits.  This is mainly for 
 # debugging purposes.
 # 
 # --------------------------------------------------------------------------
 ##

proc status::saveLoadedModes {args} {
    
    global rememberLoadedPopupModes popupMenuModes
    
    variable dontExplainModeDialog
    variable loadedModes
    variable resetPopupModes
    
    # This is mainly for debugging.
    if {[info exists resetPopupModes] && $resetPopupModes} {
        foreach varName [list "popupMenuModes" "rememberLoadedPopupModes" \
	  "dontExplainModeDialog"] {
	    if {[info exists $varName]} {
	        prefs::modified $varName
		unset $varName
	    }
	}
	return
    }
    # If the user doesn't want to remember modes, do nothing.
    if {!$rememberLoadedPopupModes} {
	return
    }
    foreach m $loadedModes {
	if {([lsearch [alpha::internalModes] $m] == -1)} {
	    lappend popupMenuModes $m
	}
    }
    set popupMenuModes [lsort -dictionary -unique $popupMenuModes]
    prefs::modified popupMenuModes
    return
}

# ===========================================================================
# 
# ×××× Wrap Menu ×××× #
# 
# The "Wrap" pop-up indicator indicates the current wrap style.  It defaults
# to the mode's setting.  When the user clicks on it, the menu contains all
# the names of the wrap styles that are available.  Selecting one will change
# the style for either the active window or the mode of the active window.
# 
# This indicator reflects the current "wrap" attribute of the active window;
# when the user changes the setting we only register this information for the
# window but we don't change the mode's default setting.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "status::buildWrapMenu"  --
 # 
 # Create the status bar "Wrap" pop-up menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc status::buildWrapMenu {} {
    
    global lineWrapStyles locationOfStatusBar
    
    if {([set w [win::Current]] eq "")} {
	return [list "build" {"\(noOpenWindow"} {status::wrapMenuProc}]
    }
    # Define the list of menu items.
    set menuList $lineWrapStyles
    if {[catch {win::getInfo $w linewrap} current]} {
	set current [win::getModeVar $w lineWrap]
    }
    append marked "!¥" [lindex $lineWrapStyles $current]
    set menuList [lreplace $menuList $current $current $marked]
    if {$locationOfStatusBar} {
	lappend menuList "(-)" "help"
    } else {
        set menuList [concat [list "help"] $menuList]
    }
    
    return [list "build" $menuList {status::wrapMenuProc}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "status::wrapMenuProc"  --
 # 
 # Change the current wrapping method for the active window.
 # 
 # --------------------------------------------------------------------------
 ##

proc status::wrapMenuProc {menuName itemName} {

    # We allow each window to have its own wrapping style.
    global lineWrapStyles
    
    if {($itemName eq "help")} {
	help::openGeneral "statusPopupMenus" "Wrap Style"
	return
    } else {
	set newWrap  [lsearch $lineWrapStyles $itemName]
	win::setInfo [win::Current] linewrap $newWrap
	set msg "The Wrap setting is now \"$itemName\" for \"[win::Tail]\"."
    }
    displayWrap [string totitle $itemName]
    status::msg $msg
    # Rebuild the menu in case it has been torn off.
    menu::buildSome "wrapMenu"
    return
}

# ===========================================================================
# 
# ×××× Window Info Menu ×××× #
# 
# The "Info" pop-up indicator indicates the line-ending variable of the
# active window.  When the user clicks on it, the menu contains line-ending
# information plus a lot of other variables specific to the active window.
# Selecting one will either change the variable or open a dialog allowing the 
# user to set the variable there.
# 
# The last section contains "Creator Shortcuts" which allow the user to set
# the creator/type codes of the active window to any one of several of
# pre-set options.  Additional Creator Shortcuts can be easily created.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "status::buildInfoMenu"  --
 # 
 # Create the status bar "Info" pop-up menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc status::buildInfoMenu {} {
    
    global locationOfStatusBar showInvisibles alpha::platform tcl_platform \
      defaultFont fontSize tabSize indentationAmount
    
    variable tempWinArray
    variable tempFileArray
    
    # Current window/file information.
    if {([set w [win::Current]] eq "")} {
	return [list "build" {"\(No Open Window"} {status::infoMenuProc -m}]
    }
    getWinInfo -w $w tempWinArray
    if {![info exists tempWinArray(showInvisibles)]} {
	if {[info exists showInvisibles]} {
	    set tempWinArray(showInvisibles) $showInvisibles
	}
    }
    if {[catch {win::getInfo $w indentationAmount} indentation]} {
	set indentation [win::getModeVar $w indentationAmount]
    }
    set isFile [win::IsFile $w filename]
    unset -nocomplain tempFileArray
    if {$isFile && ${alpha::macos}} {
	catch {getFileInfo $filename tempFileArray}
    }
    # Define the list of menu items.  The "markItems" list will be used at
    # the end to indicate the current value of the given items.
    for {set i 1} {($i <= 7)} {incr i} {
	set menuList$i [list]
    }
    set markItems [list]
    # (1) Line endings, resource fork.
    if {${alpha::platform} eq "tk"} {
	lappend menuList1 "macintosh" "unix" "windows"
	lappend markItems $tempWinArray(platform)
    } else {
	lappend menuList1 "Mac" "Unix" "DOS"
	switch -- $tempWinArray(platform) {
	    "mac"               {lappend markItems "Mac"}
	    "unix"              {lappend markItems "Unix"}
	    "ibm" - "dos"       {lappend markItems "DOS"}
	}
	# (2) "Remember Window State
	if {$isFile} {
	    if {($tempWinArray(state) eq "mpw")} {
		lappend menuList2 "Forget Window State"
	    } else {
		lappend menuList2 "Remember Window State"
	    }
	}
	if {[info exists tempFileArray(resourcelen)]} {
	    if {$tempWinArray(dirty)} {
		set dim "\("
	    } else {
		set dim [expr {($tempFileArray(resourcelen) > 0) ? "" : "\("}]
	    }
	    lappend menuList2 "${dim}Delete Resource ForkÉ"
	}
    }
    # (3) File status, toggleable states.
    if {$isFile} {
	lappend menuList3 "Show In Finder" "Get InfoÉ"
	if {($tcl_platform(platform) eq "unix")} {
	    set menuItem "Permissions "
	    if {![catch {file attributes $filename -permissions} perm]} {
		append menuItem "'" $perm "' "
	    }
	    lappend menuList3 [append menuItem "É"]
	}
	if {($tcl_platform(platform) ne "macintosh")} {
	    lappend menuList3 "ExecutableÉ"
	    if {[file executable $w]} {
		lappend markItems "ExecutableÉ"
	    }
	}
    }
    # (4) Read-only, Invisibles.
    if {!$tempWinArray(read-only)} {
	lappend menuList4 "Lock File"
    } else {
	lappend menuList4 "Unlock File"
    }
    if {[info exists tempWinArray(showInvisibles)]} {
	if {!$tempWinArray(showInvisibles)} {
	    lappend menuList4 "Show Invisibles"
	} else {
	    lappend menuList4 "Hide Invisibles"
	}
    } elseif {[info exists showInvisibles]} {
	if {!$showInvisibles} {
	    lappend menuList4 "Show Invisibles"
	} else {
	    lappend menuList4 "Hide Invisibles"
	}
    }
    # (5) Window/file variable settings.
    lappend menuList5 \
      "$tempWinArray(font) $tempWinArray(fontsize) É" \
      "Tab Size '$tempWinArray(tabsize)' É" \
      "Indentation '${indentation}' É"
    if {([string tolower $tempWinArray(font)] ne [string tolower $defaultFont]) \
      || ($tempWinArray(fontsize) ne $fontSize) \
      || ($tempWinArray(tabsize) ne $tabSize) \
      || ($indentation ne $indentationAmount)} {
        lappend menuList5 "Set Window To Defaults"
    } else {
	lappend menuList5 "(Set Window To Defaults"
    }
    # (6) Creator and Type codes.
    if {$isFile && ${alpha::macos} \
      && ![catch {getFileInfo $filename tempFileArray}]} {
	foreach item [list "creator" "type"] {
	    set menuItem "[string totitle $item] '"
	    if {($tempFileArray($item) eq "")} {
	        append menuItem {____}
	    } else {
	        append menuItem $tempFileArray($item)
	    }
	    lappend menuList6 [append menuItem "' É"]
	}
	# Include a shortcut to change the creator to AlphaX/Alphatk.
	set alphaItem "Set ALPHA As Creator"
	regsub -- {ALPHA} $alphaItem $alpha::application alphaItem
	if {($alpha::platform eq "alpha")} {
	    set alphaDim [expr {$tempFileArray(creator) eq "ALFA" ? "\(" : ""}]
	} else {
	    set alphaDim [expr {$tempFileArray(creator) eq "AlTk" ? "\(" : ""}]
	}
	lappend menuList6 "${alphaDim}${alphaItem}"
    }
    # (7) Help
    lappend menuList7 "File Info Help"
    # Now we add the items.
    set menuList [list]
    if {$locationOfStatusBar} {
        set nums [list 1 2 3 4 5 6 7]
    } else {
        set nums [list 7 6 5 4 3 2 1]
    }
    foreach num $nums {
	if {![llength [set menuList$num]]} {
	    continue
	} elseif {[llength $menuList]} {
	    lappend menuList "(-)"
	}
	foreach itemName [set menuList$num] {
	    if {[lcontains markItems $itemName]} {
		lappend menuList "!¥$itemName"
	    } else {
		lappend menuList $itemName
	    }
	}
    }
    return [list "build" $menuList {status::infoMenuProc -m}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "status::infoMenuProc" --
 # 
 # Execute the selected menu item.
 # 
 # --------------------------------------------------------------------------
 ##

proc status::infoMenuProc {menuName itemName} {
    
    global mode alpha::macos alpha::platform showInvisibles \
      defaultFont fontSize tabSize indentationAmount
    global ${mode}modeVars
    
    variable tempWinArray
    variable tempFileArray
    
    # Deal with these special cases first.
    append fontItem $tempWinArray(font) " " $tempWinArray(fontsize)
    if {([string trim $itemName] eq $fontItem)} {
	set itemName "change font"
    } elseif {($itemName eq "File Info Help")} {
	help::openGeneral "statusPopupMenus" "File Info"
	return
    } elseif {($itemName eq "Set $alpha::application As Creator")} {
        set itemName "creator 'to_alpha'"
    }
    # Current window information.
    set w [win::Current]
    set f [win::StripCount $w]
    set t "\"[win::Tail $f]\""
    # Variable, value information
    set value ""
    set var [string tolower [string trim $itemName]]
    regexp {^(permissions|creator|type|tab size|indentation) '([\w]*)'} \
      $var -> var value
    set Var "\"[string totitle $var]\""
    # Adjust the variable as indicated.
    switch -- $var {
	"unix" - "windows" - "macintosh" - "mac" - "dos" {
	    setWinInfo -w $w platform $var
	    setWinInfo -w $w dirty 1
	    switch $var {
		"mac"   {set Var "Mac"}
		"unix"  {set Var "Unix"}
		"dos"   {set Var "DOS"}
		default {set Var [string totitle $var]}
	    }
	    displayPlatform $Var
	    status::msg "The line-endings for $t are now in $Var format."
	}
	"remember window state" - "forget window state" {
	    switch -- $tempWinArray(state) {
		"mpw" - "think" {
		    setWinInfo -w $w state none
		    markMenuItem fileInfoMenu "Remember Window State" 0
		    status::msg "Current state will be ignored upon saving."
		}
		"none" {
		    setWinInfo -w $w state mpw
		    markMenuItem fileInfoMenu "Remember Window State" 1
		    status::msg "Current state will be remembered upon saving."
		}
	    }
	}
	"delete resource fork" {
	    if {$tempWinArray(dirty)} {
	        alertnote "The file $t must first be saved before\
		  the resource fork can be deleted."
		return
	    }
	    set q "Are you sure that you want to delete the resource fork\
	      for the window $t?  This cannot be undone."
	    if {[askyesno $q]} {
	        if {![catch {setFileInfo $f resourcelen}]} {
		    revert -w $w
		    enableMenuItem fileInfoMenu "Delete Resource ForkÉ" 0
		    status::msg "The resource fork for $t has been deleted."
		} else {
		    status::msg "The resource fork could not be deleted."
		}
	    } else {
	        status::msg "Cancelled."
	    }
	}
	"get info" {
	    if {$::alpha::macos && \
	      ([llength [info commands ::mac::getFilesInfo]] \
	      || [auto_load ::mac::getFilesInfo])} {
		# Call the 'Mac Menu' procedure.
		if {![mac::getFilesInfo $f]} {
		    status::msg "Sorry, cannot retrieve file information."
		} else {
		    mac::showFilesInfo
		}
	    } else {
		foreach {a v} [file attributes $f] {
		    append res "[string range $a 1 end] : $v\n"
		}
		alertnote $res
	    }
	}
	"show in finder" {
	    file::showInFinder $f
	}
	"permissions" {
	    if {[catch {file attributes $f -permissions} perm]} {
		status::msg $perm
		return
	    }
	    set newperm [::prompt "New permissions?" $perm]
	    file attributes $f -permissions $newperm
	    status::msg "The new permissions for $t are '${newperm}'"
	}
	"executable" {
	    if {[catch {file attributes $f} attrs]} {
		status::msg "The $t window is not a file."
		return
	    }
	    if {([lsearch -exact $attrs "-permissions"] == -1)} {
		status::msg "Sorry, permissions cannot be set on this platform."
		return
	    }
	    if {[file executable $f]} {
		if {![askyesno "Do you want to make $t an un-executable file?"]} {
		    error "cancel"
		}
		file attributes $f -permissions u-x
		status::msg "The file $t is no longer executable."
	    } else {
		if {![askyesno "Do you want to make $t an executable file?"]} {
		    error "cancel"
		}
		file attributes $f -permissions u+x
		status::msg "The file $t is now executable."
	    }
	}
	"lock file" - "unlock file" {
	    set value [expr {1 - $tempWinArray(read-only)}]
	    setWinInfo -w $w read-only $value
	    if {$value} {
		status::msg "The window $t is now read-only."
	    } else {
		status::msg "The window $t is no longer read-only."
	    }
	}
	"show invisibles" - "hide invisibles" {
	    if {[info exists tempWinArray(showInvisibles)]} {
		set value [expr {1 - $tempWinArray(showInvisibles)}]
		setWinInfo -w $w showInvisibles $value
		refresh
		set where "in ${t}."
	    } elseif {[info exists showInvisibles]} {
		# This global "linkvar" will refresh the window.
		set value [expr {1 - $showInvisibles}]
		set showInvisibles $value
		set where "in all windows."
	    } else {
		status::msg "Sorry, \"Show Invisibles\" is not an option."
		return
	    }
	    if {$value} {
		status::msg "'Invisible' characters are now shown $where"
	    } else {
		status::msg "'Invisible' characters are now hidden $where"
	    }
	}
	"change font" {
	    setFontsTabs
	}
	"tab size"  {
	    set value [::prompt "New tab size?" $value]
	    setWinInfo -w $w tabsize $value
	    status::msg "The new tab-size for $t is '${value}'."
	}
	"indentation" {
	    if {[catch {win::getInfo $w indentUsingSpacesOnly} spaces]} {
		set spaces [win::getModeVar $w indentUsingSpacesOnly]
	    }
	    if {[catch {win::getInfo $w indentationAmount} amount]} {
		set amount [win::getModeVar $w indentationAmount]
	    }
	    set res [dialog::make -title "Indentation" \
	      [list "" \
	      [list text "Both of these settings are specific to the\
	      active window.  Their initial values always reflect your\
	      \"Global Preference\" settings.\r"] \
	      [list text "If 'Indent Using Spaces Only' is set then\
	      tab characters will never be inserted for indentation\
	      purposes.\r"] \
	      [list flag "Indent Using Spaces Only" $spaces] \
	      [list text "How many character-widths should be used for each\
	      indentation level in the code/text?  Note that this is\
	      independent of the tab size.\r"] \
	      [list var "Indentation Amount" $amount]]]
	    set newSpaces [lindex $res 0]
	    set newAmount [lindex $res 1]
	    if {$spaces != $newSpaces} {
		win::setInfo $w indentUsingSpacesOnly $newSpaces
		set onOrOff [expr {$newSpaces ? on : off}]
		lappend msg "Indent Using Spaces Only : $onOrOff"
	    }
	    if {$amount != $newAmount} {
		win::setInfo $w indentationAmount $newAmount
		lappend msg "New indentation amount: $newAmount"
	    }
	    if {![info exists msg]} {
		set msg "No changes."
	    } else {
		set msg "[join $msg " ; "] (for this window only)"
	    }
	    status::msg $msg
	      
	}
	"set window to defaults" {
	    win::setInfo $w font        $defaultFont
	    win::setInfo $w fontsize    $fontSize
	    win::setInfo $w tabsize     $tabSize
	    win::setInfo $w indentation $indentationAmount
	    status::msg "$t -- font: $defaultFont ; font size: $fontSize ;\
	      tab size: $tabSize ; indentation: $indentationAmount"
	}
	"creator" - "type" {
	    if {!${alpha::macos}} {
		# This shouldn't have even be offered.
		status::msg "Cannot change the $Var on this platform."
		return
	    } elseif {($value eq "to_alpha")} {
		file::toAlphaSigType $f
		set Var "creator and/or type"
	    } elseif {[llength [info procs ::mac::fileInfo]] \
	      || [auto_load ::mac::fileInfo]} {
		# Call this nifty 'Mac Menu' procedure.
		watchCursor
		if {![mac::changeFileTypeCreator $var $f]} {
		    status::msg "The $Var for $t could not be changed."
		    return
		}
	    } else {
		set value [::prompt "New $Var?" $tempFileArray($var)]
		# Tcl 8.5
# 		if {[catch {file attributes $f -$var} val]} {
# 		    status::msg "Sorry, could not obtain file information."
# 		    return
# 		}
# 		set value [::prompt "New $Var?" $val]
		if {([string length $value] > 4)} {
		    error "Cancelled --\
		      $Var code can't be longer than 4 characters."
		}
		switch -- $var {
		    "type"    {set var "asty"}
		    "creator" {set var "fcrt"}
		}
		# With Tcl 8.5 we should use 'file attributes' here?
		if {[catch {tclAE::send 'MACS' core setd ---- \
		  [tclAE::build::propertyObject $var \
		  [tclAE::build::filename $f]] \
		  data [tclAE::build::objectType $value]} res]} {
		    alertnote $res
		    return
		}
	    }
	    status::msg "The $Var for $t has been changed."
	}
	
    }
    # Rebuild the menu in case it has been torn off.
    menu::buildSome "fileInfoMenu"
    return
}

# ===========================================================================
# 
# ×××× Encoding Menu ×××× #
# 
# The "Encoding" pop-up indicator indicates the encoding of the active
# window.  When the user clicks on it, the menu contains all the names of the
# currently available encodings.  Selecting one will change the encoding of
# the active window.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "status::buildEncodingMenu"  --
 # 
 # Create the status bar "Encodings" pop-up menu.  The item "ChooseÉ" is
 # always listed near the mouse, which is why we pay attention to the global
 # pref for "locationOfStatusBar" ("1" at top, "0" at bottom").  We always
 # make sure that the current encoding is in the list.
 # 
 # --------------------------------------------------------------------------
 ##

proc status::buildEncodingMenu {} {

    global encoding preferredEncodings locationOfStatusBar \
      addChosenEncodingsToPreferred showAllPopupEncodings
    
    if {([win::Current] eq "")} {
	return [list "build" {"\(No Open Window"} {status::encodingMenuProc -m}]
    }
    set allEncodings [lsort -dictionary [encoding names]]
    
    set encodingList $preferredEncodings
    lappend encodingList $encoding
    set encodingList [lsort -dictionary -unique $encodingList]
    if {$showAllPopupEncodings} {
	set chooseOrMore "ChooseÉ"
	set encodingList \
	  [eval [list lappend encodingList "(-)"] \
	  [lremove $allEncodings $encodingList]]
    } else {
	set chooseOrMore "More ChoicesÉ"
    }
    if {$locationOfStatusBar} {
	set menuList \
	  [concat [list $chooseOrMore (-)] $encodingList \
	  [list "(-)" "Set PreferredÉ" "Encodings Help"]]
    } else {
	set menuList \
	  [concat [list "Encodings Help" "Set PreferredÉ" "(-)"] \
	  $encodingList [list "(-)" $chooseOrMore]]
    }
    if {([set idx [lsearch -exact $menuList $encoding]] > -1)} {
	set menuList [lreplace $menuList $idx $idx "!¥${encoding}"]
    }
    return [list build $menuList {status::encodingMenuProc -m}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "status::encodingMenuProc" --
 # 
 # Change the encoding of the active window.
 # 
 # --------------------------------------------------------------------------
 ##

proc status::encodingMenuProc {menuName itemName} {
    
    global encoding preferredEncodings addChosenEncodingsToPreferred \
      showAllPopupEncodings dialog::simple_type
    
    switch -- $itemName {
        "Encodings Help" {
	    help::openGeneral "statusPopupMenus" "Encodings"
            return
        }
        "More Choices" - "Choose" {
	    set allEncodings [lsort -dictionary [encoding names]]
	    set p "Choose a new encoding:"
	    set L [list $encoding]
	    set itemName [listpick -p $p -L $L -- $allEncodings]
        }
	"Set Preferred" {
	    set preferredEncodings \
	      [lsort -dictionary -unique $preferredEncodings]
	    # Set up some variables needed to create the dialog.
	    set width 400
	    set left  "-20"
	    set right [expr $width - 15]
	    set buttons [list \
	      "More Help" \
	      "Press this button for more information" \
	      {status::encodingMenuProc {} {Encodings Help} ; set retCode 0} \
	      "BrowseÉ" \
	      "Press this button to select new items" \
	      {catch {dialog::valSet $dial "," \
	      [lsort -dictionary -unique [concat \
	      [listpick -p "Select some new preferred encodings:" \
	      -l -- [lremove [encoding names] [dialog::valGet $dial ","]]] \
	      [dialog::valGet $dial ","]]]}} \
	      ]
	    set dialog::simple_type(popupEncodings) \
	      "dialog::makeEditItem res script $left $right y \$name \$val 5"
	    set txt1 "The list of encodings offered in this pop-up menu always\
	      includes your \"preferred\" list.  You can press the \"Browse\"\
	      button below to add items from the recognized list of encodings."
	    set txt2 "You can also instruct ALPHA to always add encodings\
	      that you have chosen from this pop-up to your \"preferred\"\
	      encodings list.\r"
	    set txt3 "If you want to always show all available encodings, then\
	      use the checkbox below.\r"
	    regsub -all -- {ALPHA} $txt1 [set alpha::application] txt1
	    regsub -all -- {ALPHA} $txt2 [set alpha::application] txt2
	    # Create and present the dialog.
	    set dialogScript [list dialog::make -title "Preferred Encodings" \
	      -width $width -addbuttons $buttons \
	      [list "" \
	      [list "text" $txt1] \
	      [list "popupEncodings" "" $preferredEncodings] \
	      [list "text" $txt2] \
	      [list "flag" "Always add chosen encodings to default set" \
	      $addChosenEncodingsToPreferred] \
	      [list "divider" "divider"] \
	      [list "text" $txt3] \
	      [list "flag" "Always show all available encodings" \
	      $showAllPopupEncodings] \
	      ]]
	    set results [eval $dialogScript]
	    set msg "No changes have been made."
	    set newPreferred [lindex $results 0]
	    if {($preferredEncodings ne $newPreferred)} {
		set preferredEncodings $newPreferred
		prefs::modified preferredEncodings
		status::msg "The list of preferred encodings has been saved."
	    }
	    set newRemember [lindex $results 1]
	    if {($newRemember ne $addChosenEncodingsToPreferred)} {
		set addChosenEncodingsToPreferred $newRemember
		prefs::modified addChosenEncodingsToPreferred
		set msg "Chosen encodings will be\
		  [expr {$newRemember ? "now" : "no longer"}] \
		  be remembered between editing sessions."
	    }
	    set newShowAll [lindex $results 2]
	    if {($newShowAll ne $showAllPopupEncodings)} {
		set showAllPopupEncodings $newShowAll
		prefs::modified showAllPopupEncodings
		set msg "All encodings will\
		  [expr {$newRemember ? "now" : "no longer"}] \
		  be displayed in the in the pop-up menu."
	    }
	    status::msg $msg
	    return
	}
    }
    if {($itemName eq $encoding)} {
        status::msg "Nothing was changed."
	return
    }
    if {$addChosenEncodingsToPreferred} {
	lappend preferredEncodings $itemName
	set preferredEncodings [lsort -dictionary -unique $preferredEncodings]
	prefs::modified preferredEncodings
    }
    win::Encoding [win::Current] $itemName
    status::msg "The encoding for \"[win::Tail]\" is now \"${itemName}\"."
    # Rebuild the menu in case it has been torn off.
    menu::buildSome "encodingMenu"
    return
}

# ===========================================================================
# 
# .