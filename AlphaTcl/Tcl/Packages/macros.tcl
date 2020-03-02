## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 #
 # FILE: "macros.tcl"
 #                                          created: 07/27/1997 {11:39:46 pm}
 #                                      last update: 03/01/2006 {02:01:48 PM}
 # Description:
 # 
 # Support for user created macros.  We rely on the core "Macro Recording"
 # commands to do the heavy lifting, this package simply provides a user
 # interface to use them.
 # 
 # Note: None of these procedures have been designed to be called by any other
 # code -- they all assume that the package has been activated by the user
 # using standard AlphaTcl routines.
 # 
 # See the "Macro Scripts" section below for information about how scripts
 # are stored and used during normal operation.  The "Script Files/Windows"
 # section describes how macros are saved between editing sessions, and how
 # the user is able to save and edit personal macros.
 # 
 # Original Author: Pete Keleher ??
 # 
 # Principal AlphaTcl package organization created by Vince Darley.
 # 
 # Includes contributions from Craig Barton Upright.
 # 
 # Copyright (c) 2001-2006 Vince Darley, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ## 

# ===========================================================================
# 
# ×××× Feature Declaration ×××× # 
# 

alpha::feature macros 2.0.1 "global-only" {
    # Initialization script.
    macro::initializePackage
} {
    # Activation script: insert the menus.
    macro::activatePackage 1
} {
    # Deactivation script: remove the menus.
    macro::activatePackage 0
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Adds the ability to record and execute keyboard macros
} help {
    file "Macros Help"
}

proc macros.tcl {} {}

##
 # --------------------------------------------------------------------------
 # 
 # "namespace eval macro" --
 # 
 # Ensures that some variables have been defined in the "macro" namespace,
 # those required for the proper execution of the procedures in this file.
 # This block will be evaluated _before_ [macro::initializePackage] is
 # actually called, during the [auto_load] sequence.
 # 
 # The "macro::recording" variable is set and used by Alpha Macro Recording
 # core commands.  When it's value is "0", it means that recording is
 # currently turned off, "1" means that recording is in progress.  Any other
 # value indicates some transitional state -- recording is being set up, or
 # possibly suspended.  Query the value of this variable very carefully.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval macro {
    
    variable activated
    variable hiddenMacros
    variable initialized
    variable lastChosenMacro
    variable recording
    
    if {![info exists activated]} {
	set activated -1
    }
    if {![info exists hiddenMacros]} {
	set hiddenMacros [list]
    }
    if {![info exists initialized]} {
	set initialized 0
    }
    if {![info exists lastChosenMacro]} {
	set lastChosenMacro ""
    }
    if {![info exists recording]} {
	set recording 0
    }

    # These are used for editing saved macros.
    variable carriageReturn {
}
    variable macrosFolder
    if {($::SUPPORT(user) ne "")} {
        set macrosFolder [file join $::SUPPORT(user) Macros]
    } else {
        set macrosFolder [file join $::PREFS Macros]
    }
    variable macroHeader {# -*-Tcl-*-
# 
# This file contains the script for the macro indicated by the window name.
# 
# This window is in "Tcl" mode -- you can COMMAND-Double-Click on any command
# or AlphaTcl procedure to find more information about its usage and syntax.
# 
# When you are done editing the macro, simply save this window, and the 
# changes will be recognized the next time this macro is invoked.
# 
}
    append macroHeader "# " [string repeat {=} 76] " #" \
      $carriageReturn $carriageReturn
    if {$::alpha::macos} {
        regsub -all -- {COMMAND} $macroHeader {Command} macroHeader
    } else {
        regsub -all -- {COMMAND} $macroHeader {Alt} macroHeader
    }
    variable reservedNames
    if {![info exists reservedNames]} {
        set reservedNames [list "lastRecordedMacro" "-all"]
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::initializePackage" --
 # 
 # Called when this package is first activated via normal AlphaTcl routines.
 # This will define all necessary preferences, transferring anything from
 # older versions as necessary.  It also registers any hooks/traces that are
 # used by this package.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::initializePackage {} {
    
    global alpha::macos PREFS defaultEncoding macroArr macroNames macroKeys \
      macrosmodeVars
    
    variable initialized
    variable macrosFolder
    variable recording
    variable savedMacroProcs
    variable savedMacroScripts
    variable savedScripts
    
    if {$initialized} {
	return
    }
    
    # Make sure that our Macros Folder exists.
    if {![file exists $macrosFolder]} {
	alpha::log "stdout" "Creating Macros folder."
	file mkdir $macrosFolder
    }
    # In Alpha 8/X, since encodings aren't really supported the user will be
    # editing all files in macRoman, which means we must force AlphaTcl to
    # source them in macRoman too.
    if {$alpha::macos && ![info exists defaultEncoding]} {
	set macroEncoding "macRoman"
    } else {
	set macroEncoding $defaultEncoding
    }
    alpha::registerEncodingFor $macrosFolder $macroEncoding
    # If the user didn't have SUPPORT available before but now does, transfer
    # all of those files to the new location.
    set prefsMacros [file join $PREFS "Macros"]
    if {($macrosFolder ne $prefsMacros) && [file exists $prefsMacros]} {
	foreach fileTail [glob -nocomplain -tails -dir $prefsMacros "*"] {
	    set oldFile [file join $prefsMacros $fileTail]
	    set newFile [file join $macrosFolder $fileTail]
	    if {![file exists $newFile]} {
		file copy -force $oldFile $newFile
		catch {file::toAlphaSigType $newFile}
	    }
	    file delete -force $oldFile
	}
	file delete -force $prefsMacros
    }
    
    # -----------------------------------------------------------------------
    # 
    # Back Compatibility.
    # 
    # Make sure that this works with older versions of this package, i.e.
    # that all previously used variables are reassigned as necessary.
    # 
    # -----------------------------------------------------------------------
    if {[info exists macroKeys]} {
	# Earlier global array which kept track of macro bindings.
	foreach macroName [array names macroKeys] {
	    macro::setBinding $macroName $macroKeys($macroName)
	    prefs::removeObsolete macroKeys($macroName)
	}
    }
    if {[info exists macroNames]} {
	# Earlier global array which kept track of hide/show information.
	foreach macroName [array names macroNames] {
	    if {!$macroNames($macroName)} {
		macro::hideSave $macroName "hide"
	    }
	    prefs::removeObsolete macroNames($macroName)
	}
    }
    if {[info exists macroArr]} {
	# Earlier global array which kept track of macro procs.
	foreach macroName [array names macroArr] {
	    regsub -all -- {;([\r\n]+|$)} $macroArr($macroName) \
	      "\r" macroProc
	    set macroScript [lindex $macroProc end]
	    macro::createScriptFile $macroName $macroScript
	    prefs::removeObsolete macroArr($macroName)
	}
    }
    if {[info exists savedMacroProcs]} {
	# Earlier "macro" namespace array which kept track of macro procs.
	foreach macroName [array names savedMacroProcs] {
	    regsub -all -- {;([\r\n]+|$)} $savedMacroProcs($macroName) \
	      "\r" macroProc
	    set macroScript [lindex $macroProc end]
	    macro::createScriptFile $macroName $macroScript
	    prefs::removeObsolete savedMacroProcs($macroName)
	}
    }
    if {[info exists savedMacroScripts]} {
	# Earlier versions saved macros in "arrdefs.tcl" rather than in a 
	# separate "$PREFS/$SUPPORT/Macros" folder.
	foreach macroName [array names savedMacroScripts] {
	    macro::createScriptFile $macroName $savedMacroScripts($macroName)
	}
    }
    # -----------------------------------------------------------------------
    # 
    # END OF Back Compatibility.
    # 
    # -----------------------------------------------------------------------
    
    # Read in the last recorded macro.
    macro::sourceScriptFile "lastRecordedMacro"
    macro::deleteScriptFile "lastRecordedMacro"
    if {![info exists savedScripts(lastRecordedMacro)]} {
	set savedScripts(lastRecordedMacro) ""
    }
    macro::currentScript $savedScripts(lastRecordedMacro)
    # Register all current saved macros.  They are initially empty, but their
    # source files will be read as needed.  (We could source all of the
    # scripts now with [macro::sourceScriptFile "-all"], but that wouldn't be
    # efficient during startup.)
    foreach macroName [macro::createList "files"] {
	if {![info exists savedScripts($macroName)]} {
	    set savedScripts($macroName) ""
	}
    }
    
    # Preferences.
    
    # Move any old binding prefs into the macrosmodeVars array.
    prefs::renameOld startRecording   macrosmodeVars(beginRecording)
    prefs::renameOld macrosmodeVars(startRecording) \
      macrosmodeVars(beginRecording)
    prefs::renameOld endRecording     macrosmodeVars(endRecording)
    prefs::renameOld executeLastMacro macrosmodeVars(executeLastMacro)
    
    # Key binding for the "Macro Recording > Begin Recording" menu item.
    newPref menubinding beginRecording   "/q" macros {macro::rebuildMenu}
    # Key binding for the "Macro Recording > End Recording" menu item.
    newPref menubinding endRecording     "/r" macros {macro::rebuildMenu}
    # Key binding for the "Macro Recording > Execute Last Macro" menu item.
    newPref menubinding executeLastMacro "/s" macros {macro::rebuildMenu}
    
    # Emacs bindings.  We define these here in case the package: emacs is not
    # activated but the user is still familiar with them.  (The "Macros Help"
    # file mentions them, so we ensure that they are available.)
    
    # Begin Macro Recording.
    Bind '(' <sX> {macro::menuProc "" "beginRecording"}
    # End Macro Recording.
    Bind ')' <Xs> {macro::menuProc "" "endRecording"}
    # Execute the Last Recorded Macro.
    Bind 'e' <X>  {macro::menuProc "" "executeLastMacro"}
    
    # The location of the Macros menus in the Utils menu.
    newPref var "macrosMenusLocation" "1" macros {macro::placeMenus} \
      [list "Top of Utils Menu" "Bottom of Utils Menu"] "index"
    # Remember this so we know how to adjust when this changes.
    variable oldMenuLocation $macrosmodeVars(macrosMenusLocation)
    
    # Register the build procs for the menus.
    menu::buildProc macroRecording  {macro::buildRecordMenu} \
      {macro::postBuildRecord}
    menu::buildProc savedMacros     {macro::buildSavedMenu} \
      {macro::postBuildSaved}
    
    # This will automatically dim menu items when macros are started/stopped.
    # Because this variable is set/reset by the core commands, we know that
    # any Emacs key bindings that don't directly use [macro::] procedures will
    # still call [macro::postBuildRecord].
    trace add variable "recording" "write" {macro::postBuildRecord}
    
    # Register a quit hook to save variables if the user changed them during
    # this editing session.
    hook::register quitHook {macro::quitHook}
    # This allows the "Last Recorded Macro" to be automatically re-loaded
    # when its editing window is saved.
    hook::register savePostHook {macro::saveWindowHook}  macro
    hook::register closeHook    {macro::closeWindowHook} macro
    
    # Make sure that we don't do this again.
    set initialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "macro::activatePackage" --
 # 
 # Insert or remove menu items as needed.  The "oldMenuLocation" is always
 # initially set to the "macrosmodeVars(macrosMenusLocation)" value.  When
 # this changes, [macro::placeMenus] is called.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::activatePackage {which} {
    
    variable activated
    variable oldMenuLocation
    
    if {($which == $activated)} {
	return
    } elseif {$which} {
	package::addPrefsDialog "macros"
	if {!$oldMenuLocation} {
	    menu::insert   Utils items   "0"   "(-)"
	    menu::insert   Utils submenu "(-)" "macroRecording"
	    menu::insert   Utils submenu "(-)" "savedMacros"
	} else {
	    menu::insert   Utils items   "end" "(-) "
	    menu::insert   Utils submenu "end" "macroRecording"
	    menu::insert   Utils submenu "end" "savedMacros"
	}
    } else {
	package::removePrefsDialog "macros"
	if {!$oldMenuLocation} {
	    menu::uninsert Utils submenu "(-)" "macroRecording"
	    menu::uninsert Utils submenu "(-)" "savedMacros"
	} else {
	    menu::uninsert Utils submenu "end" "macroRecording"
	    menu::uninsert Utils submenu "end" "savedMacros"
	}
    }
    set activated $which
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "macro::placeMenus" --
 # 
 # Trace procedure called after the "macrosmodeVars(macrosMenusLocation)"
 # preference has been changed via the preferences dialog.  If this package 
 # is still activated, we remove the menus and then reinsert them.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::placeMenus {prefName} {
    
    global macrosmodeVars
    
    variable activated
    variable oldMenuLocation
    
    if {$activated} {
	macro::activatePackage 0
	set oldMenuLocation $macrosmodeVars(macrosMenusLocation)
	macro::activatePackage 1
    } else {
	set oldMenuLocation $macrosmodeVars(macrosMenusLocation)
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::quitHook" --
 # 
 # Called when Alpha is quitting.  Save any necessary variables/preferences
 # for use during the next editing session.  (We do this here to avoid
 # including [prefs::modified] calls throughout this file.)  If the variables
 # don't exist, we (1) set them to a dummy value, (2) register them to be
 # saved, (3) unset them so that any previously set values will not be saved.
 # This little song and dance is necessary in case the user has completely
 # removed some array/list items.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::quitHook {} {
    
    variable hiddenMacros
    variable macroBindings
    variable macrosFolder
    
    # Save the "last recorded macro" for the next session.
    macro::createScriptFile "lastRecordedMacro" [macro::currentScript]
    set emptyVars [list]
    
    foreach item [list hiddenMacros macroBindings] {
	if {![info exists $item]} {
	    set $item ""
	    lappend emptyVars $item
	}
	prefs::modified $item
    }
    foreach item $emptyVars {
	unset $item
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::currentScript" --
 # 
 # This is our primary interface with the core [macro::current] command.  If
 # the script is "-1" then we return the value of the current script that is
 # maintained by the core, otherwise we set the new core macro script.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::currentScript {{macroScript "-1"}} {
    
    if {($macroScript eq "-1")} {
	return [lindex [macro::current] end]
    } else {
	macro::current "proc macroName {} {\r${macroScript}\r}"
	return
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Macro Scripts ×××× #
# 
# While this package is in operation, all saved macro scripts are stored in
# the array "savedScripts".  The procedure [macro::setScript] will (un)set an
# item in this array, while [macro::getScript] will retrieve it.
# 
# Use [macro::evalScript] to run the script.
# 
# All of this code tries to allow for various forms of deviant behavior on
# behalf of the user, such as modifying the contents of the Macros Folder
# files outside of "Utils > ?Macros?"  menu commands.  The user might be
# copying files, deleting them, editing them in a different text editor...
# During this editing session we attempt to run (or edit) a macro whether it
# exists in the "savedScripts" array, as a file, or both.  When Alpha is
# relaunched, the list of saved macros is built from scratch based on the
# existence of files in the Macros Folder.
# 

##
 # --------------------------------------------------------------------------
 # 
 # "macro::setScript" --
 # 
 # Manipulate the user-defined Saved Macro Scripts.  If the given script is
 # anything but "-unset", we assign the script to the given Macro Name, even
 # if it is the null string.
 # 
 # If the "macroScript" value is "-unset" then we remove the script from the 
 # "savedScripts" array.  The calling code is responsible for removing the 
 # script's file if necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::setScript {macroName {macroScript ""}} {
    
    variable savedScripts
    
    if {($macroName eq "")} {
	error "The Macro Name cannot be an empty string!"
    } elseif {($macroScript eq "-unset")} {
	# Unset the script.
	if {($macroName == "lastRecordedMacro")} {
	    macro::currentScript ""
	}
	unset -nocomplain savedScripts($macroName)
	return
    }
    # Set the new Macro Script for the Macro Name.
    set newMacroScript [list]
    if {($macroName eq "lastRecordedMacro")} {
	# Strip out all leading comments and blank lines.
	set newScript [list]
	set lines [split $macroScript "\r\n"]
	for {set i 0} {($i < [llength $lines])} {incr i} {
	    set line [lindex $lines $i]
	    if {([string trim $line] eq "")} {
		continue
	    } elseif {![regexp -- {^\s*\#} $line]} {
		break
	    }
	}
	foreach line [lrange $lines $i end] {
	    lappend newScript [string trimleft $line]
	}
	set macroScript [join $newScript "\r"]
    }
    # Massage the script as needed.
    foreach line [split $macroScript "\r\n"] {
	set line [string trimleft $line]
	if {[regexp -- {macro::menuProc.+endRecording} $line]} {
	    continue
	} elseif {[string length $line]} {
	    regsub -- {^insertText(\s+)} $line {typeText\1} line
	    lappend newMacroScript [string trim $line]
	}
    }
    set macroScript [join $newMacroScript "\n"]
    if {($macroName eq "lastRecordedMacro")} {
	macro::currentScript $macroScript
    }
    set savedScripts($macroName) $macroScript
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "macro::getScript" --
 # 
 # Get the current script for the given macro.  The "lastRecordedMacro" is
 # always obtained by [macro::currentScript].  All others are stored in the
 # "savedScripts" array.  We always check to see if the file containing the
 # script has changed since the last time we saved the script, by comparing
 # its last modification timestamp to what we have recorded, and if it has
 # then we source it anew.
 # 
 # If no script can be found, an empty string is returned.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::getScript {macroName} {
    
    variable macrosFolder
    variable savedScripts
    variable scriptTimes
    
    set fileName [file join $macrosFolder $macroName]
    if {($macroName eq "")} {
	error "The Macro Name cannot be an empty string!"
    } elseif {($macroName eq "lastRecordedMacro")} {
	return [macro::currentScript]
    } elseif {![file exists $fileName]} {
	if {[info exists savedScripts($macroName)]} {
	    return $savedScripts($macroName)
	} else {
	    return ""
	}
    }
    # Still here?  Check to see if the file has changed.
    if {![info exists savedScripts($macroName)] \
      || ![info exists scriptTimes($fileName)] \
      || ([file mtime $fileName] ne $scriptTimes($fileName))} {
	macro::sourceScriptFile $macroName
    }
    if {[info exists savedScripts($macroName)]} {
	return $savedScripts($macroName)
    } else {
	return ""
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "macro::evalScript" --
 # 
 # Evaluate the given macro script in the top stack level.  If an error is 
 # thrown, we offer the chance to review the problem.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::evalScript {macroName} {
    
    global errorInfo
    
    variable macroError
    variable macroScript
    
    if {[macro::emptyScript $macroName]} {
	status::msg "The script for the \"$macroName\" macro is empty."
	return
    }
    set macroScript [macro::getScript $macroName]
    if {![catch {uplevel \#0 [list eval $::macro::macroScript]}]} {
	status::msg "The \"$macroName\" macro has been executed."
    } else {
	set macroError $errorInfo
	append q "The \"$macroName\" script threw an error.\r\r" \
	  [lindex [split $macroError "\r\n"] 0] "\r"
	if {![dialog::yesno -y "OK" -n "View Error" $q]} {
	    set w [new -n "* Macro Script Error *" -text $macroError]
	    goto [minPos -w $w]
	    winReadOnly $w
	}
    }
    unset -nocomplain macroScript
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::emptyScript" --
 # 
 # Determine if the Macro Script for the given Macro Name is empty.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::emptyScript {macroName} {
    
    foreach line [split [macro::getScript $macroName] "\r\n"] {
	if {[regexp -- {^\s*\#} $line] || ([string trim $line] eq "")} {
	    continue
	}
	return 0
    }
    # Still here?  The script must be empty.
    return 1
}

# ===========================================================================
# 
# ×××× Script Files/Windows ×××× #
# 
# All saved user macros are stored between editing sessions in files in the 
# specified Macros Folder directory.  These are "sourced" as needed by 
# [macro::getScript] to ensure that we're working with the current version.
# 
# The user is thus able to open these files and edit them using any method,
# i.e. they don't have to use "Saved Macros > Edit Saved Macro" to ensure
# that fancy window hooks are added triggering a re-source.
# 
# The "lastRecordedMacro" script is always saved internally while Alpha is an
# open application.  When the user quits Alpha, the "lastRecordedMacro" is
# saved as a file in the Macros Folder until the application is launched
# again, at which point we source the file and then delete it.  If the user
# chooses to edit the last recorded macro, we create a temporary file, but
# then source it and delete it as soon as it is closed.  Via fancy hooks...
# 

##
 # --------------------------------------------------------------------------
 # 
 # "macro::createScriptFile" --
 # 
 # Create a "macroName" file in the Macros Folder, containing the given
 # script and an explanatory header.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::createScriptFile {macroName macroScript} {
    
    variable carriageReturn
    variable macrosFolder
    variable macroHeader
    
    # Add the header if it is not included in the script.
    set idx0 [string first "# -*-Tcl-*-" $macroScript]
    set idx1 [string first "# [string repeat {=} 76] #" $macroScript]
    if {($idx0 == "-1") && ($idx1 == "-1")} {
	set txt $macroHeader
    } else {
	set txt ""
    }
    foreach line [split $macroScript "\r\n"] {
	regsub -- {^insertText(\s+)} $line {typeText\1} line
	append txt $line $carriageReturn
    }
    # Find out if our target file exists.  We close all such windows,
    # since they may actually be old versions.
    set fileName [file join $macrosFolder $macroName]
    if {[file exists $fileName]} {
	foreach w [file::hasOpenWindows $fileName] {
	    if {[win::getInfo $w dirty]} {
		win::setInfo $w dirty 0
	    }
	    killWindow -w $w
	}
    }
    # Create the file.
    file::writeAll $fileName $txt 1
    file::toAlphaSigType $fileName
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::sourceScriptFile" --
 # 
 # Add the previously saved "macroName" script to the "savedScripts" array by
 # reading the Macros Folder file.  If the file doesn't exist, the we do
 # nothing, and there's no guarantee that the "savedScripts" entry exists.
 # 
 # If the "macroName" value is "-all" then we make sure that all recognized 
 # macros have a "savedScripts" array value, even if they don't exist as 
 # files in the Macros Folder.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::sourceScriptFile {macroName} {
    
    variable macrosFolder
    variable savedScripts
    variable scriptTimes
    
    if {($macroName eq "-all")} {
	foreach macroName [macro::createList] {
	    set fileName [file join $macrosFolder $macroName]
	    if {[file exists [file join $macrosFolder $macroName]]} {
		macro::sourceScriptFile $macroName
	    }
	}
	return
    }
    set fileName [file join $macrosFolder $macroName]
    if {[file exists $fileName]} {
	set macroScript [file::readAll $fileName]
	set savedScripts($macroName) $macroScript
	set scriptTimes($fileName) [file mtime $fileName]
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "macro::deleteScriptFile" --
 # 
 # Delete a saved script file.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::deleteScriptFile {macroName} {
    
    variable macrosFolder
    
    set fileName [file join $macrosFolder $macroName]
    foreach w [file::hasOpenWindows $fileName] {
	win::setInfo $w dirty 0
	killWindow -w $w
    }
    if {[file exists $fileName]} {
	catch {file delete -force $fileName}
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::editScriptFile" --
 # 
 # Edit a Saved Macro Script.  We make sure that the script exists in the
 # Macros Folder as a file.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::editScriptFile {macroName} {
    
    variable macrosFolder
    variable savedScripts
    
    if {![file exists [file join $macrosFolder $macroName]]} {
	if {[info exists savedScripts($macroName)]} {
	    macro::createScriptFile $macroName $savedScripts($macroName)
	} else {
	    error "Cancelled -- could not find macro script to edit."
	}
    }
    set w [edit -c -mode "Tcl" [file join $macrosFolder $macroName]]
    if {($macroName eq "lastRecordedMacro")} {
	# Register a hook to save this special window.
	win::setInfo $w hookmodes [linsert [win::getInfo $w hookmodes] 0 macro]
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::saveWindowHook" --
 # 
 # Called when a user has opened a Macro Editing window containing the
 # contents of the Last Recorded Macro and is saving any editing changes.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::saveWindowHook {w {giveAlert "1"}} {
    
    variable macrosFolder
    variable saveAlert
    
    if {([file dirname $w] ne $macrosFolder)} {
	return
    }
    set macroName [win::StripCount [win::Tail $w]]
    set macroScript [getText -w $w [minPos -w $w] [maxPos -w $w]]
    macro::setScript $macroName $macroScript
    set msg "Changes for the macro script have been saved,\
      and will be used when executing it."
    if {$giveAlert} {
	if {![info exists saveAlert]} {
	    alertnote $msg
	    set saveAlert 1
	} else {
	    status::msg $msg
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::closeWindowHook" --
 # 
 # Called when a user has closed a Macro Editing window containing the
 # contents of the Last Recorded Macro and is saving any editing changes.
 # The window has already been destroyed when this is called.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::closeWindowHook {w} {
    
    variable macrosFolder
    
    if {([file dirname $w] ne $macrosFolder)} {
	return
    }
    set macroName [win::StripCount [win::Tail $w]]
    set fileName [file join $macrosFolder $macroName]
    macro::setScript $macroName [file::readAll $fileName]
    if {($macroName eq "lastRecordedMacro")} {
	macro::deleteScriptFile "lastRecordedMacro"
    }
    return
}

# ===========================================================================
# 
# ×××× Saved Macros ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "macro::createList" --
 # 
 # Return a list of Saved Macros using a given criteria.  Procedures in this
 # file do not need to be aware of how these lists are stored or created.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::createList {{listingMethod "all"}} {
    
    variable macrosFolder
    variable savedScripts
    
    set macroList      [list]
    set allSavedMacros [list]
    foreach savedMacro [array names savedScripts] {
	if {($savedMacro ne "lastRecordedMacro")} {
	    lappend allSavedMacros $savedMacro
	}
    }
    foreach savedMacro [glob -nocomplain -dir $macrosFolder -tails "*"] {
	if {($savedMacro ne "lastRecordedMacro")} {
	    lappend allSavedMacros $savedMacro
	}
    }
    set allSavedMacros [lsort -dictionary -unique $allSavedMacros]
    
    switch -- $listingMethod {
	"all" {
	    set macroList $allSavedMacros
	}
	"files" {
	    set macroList [glob -nocomplain -dir $macrosFolder -tails "*"]
	}
	"visible" {
	    foreach macroName $allSavedMacros {
		if {[macro::hideSave $macroName]} {
		    lappend macroList $macroName
		}
	    }
	}
	"hidden" {
	    foreach macroName $allSavedMacros {
		if {![macro::hideSave $macroName]} {
		    lappend macroList $macroName
		}
	    }
	}
	"withKeys" {
	    foreach macroName $allSavedMacros {
		if {![macro::hideSave $macroName]} {
		    continue
		} elseif {([macro::getBinding $macroName] ne "")} {
		    lappend macroList $macroName
		}
	    }
	}
    }
    return [lsort -dictionary -unique $macroList]
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::setBinding" --
 # 
 # Manipulate the user-defined keyboard shortcuts for Saved Macros.  If the
 # given binding is "-unset" then we remove the binding, otherwise we assign
 # the binding to the given Macro Name, even if it is the null string.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::setBinding {macroName {binding ""}} {
    
    variable macroBindings
    
    if {($macroName eq "")} {
	error "The Macro Name cannot be an empty string!"
    } elseif {($binding eq "-unset")} {
	unset -nocomplain macroBindings($macroName)
    } else {
	set macroBindings($macroName) $binding
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::getBinding" --
 # 
 # Return the user-defined keyboard shortcuts for Saved Macros.  If none has
 # been defined, return the null string.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::getBinding {macroName} {
    
    variable macroBindings
    
    if {($macroName eq "")} {
	error "The Macro Name cannot be an empty string!"
    } elseif {[info exists macroBindings($macroName)]} {
	return $macroBindings($macroName)
    } else {
	return ""
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::hideSave" --
 # 
 # Manipulate the list of Hidden Macros.  If the "action" is the null string,
 # return "0" or "1" indicating the current visibility of the Saved Macro.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::hideSave {macroName {action ""}} {
    
    variable hiddenMacros
    
    set result ""
    switch -- $action {
	"hide" {
	    lappend hiddenMacros $macroName
	}
	"show" {
	    if {([set idx [lsearch $hiddenMacros $macroName]] > -1)} {
		set hiddenMacros [lreplace $hiddenMacros $idx $idx]
	    }
	}
	"remove" {
	    if {([set idx [lsearch $hiddenMacros $macroName]] > -1)} {
		set hiddenMacros [lreplace $hiddenMacros $idx $idx]
	    }
	}
	"" {
	    if {([lsearch $hiddenMacros $macroName] > -1)} {
		set result 0
	    } else {
		set result 1
	    }
	}
    }
    return $result
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::verifyName" --
 # 
 # Ensure that the proposed name for a Saved Macro is valid, and will not
 # over-write any current macro procedures.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::verifyName {{macroName ""}} {
    
    variable reservedNames
    
    set savedMacros [macro::createList]
    while {1} {
	set macroName [string trim $macroName]
	if {($macroName eq "")} {
	    alertnote "The Macro Name cannot be an empty string!"
	} elseif {![regexp {^[-a-zA-Z0-9+ ]+$} $macroName]} {
	    alertnote "The Macro Name must be alpha-numeric!"
	} elseif {([lsearch $savedMacros $macroName] > -1)} {
	    alertnote "The name \"${macroName} is already used by a different\
	      saved macro."
	} elseif {([lsearch $reservedNames $macroName] > -1)} {
	    alertnote "Sorry, the name \"$macroName\" is reserved, and\
	      cannot be used for a saved macro."
	} else {
	    break
	}
	set macroName [prompt "Try another name:" $macroName]
    }
    return [string trim $macroName]
}

proc macro::removeMacro {macroName} {
    
    macro::setScript  $macroName "-unset"
    macro::setBinding $macroName "-unset"
    macro::hideSave   $macroName "remove"
    macro::deleteScriptFile $macroName
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Macro Menus ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "macro::buildRecordMenu" --
 # 
 # Create the menu containing the Macro Recording commands as well as all of
 # the Saved Macros utilities.  We'll decide which ones should be enabled or
 # dimmed in [macro::postBuildRecord].
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::buildRecordMenu {} {
    
    global macrosmodeVars
    
    set menuList [list \
      "$macrosmodeVars(beginRecording)beginRecording" \
      "$macrosmodeVars(endRecording)endRecording" \
      "$macrosmodeVars(executeLastMacro)executeLastMacro" \
      "(-)" \
      "displayLastMacro" "saveLastMacroÉ" "(-)" \
      "recordingShortcutsÉ" "macrosHelp" "macrosTutorial" \
      ]
    return [list build $menuList macro::menuProc]
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::buildSavedMenu" --
 # 
 # Build the menu containing all saved (and not hidden) user macros.  These
 # can be used when creating a new macro as well, and each can be assigned a
 # keyboard shortcut by the user.
 # 
 # If the number of saved (and visible) macros is large, then we place all of
 # the utility items in a separate submenu, one that can be either easily
 # accessed or skipped over to select the name of a saved macro.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::buildSavedMenu {} {
    
    global macrosmodeVars
    
    variable reservedNames
    variable utilitiesMenu
    
    # The list of utility items in the menu.
    set utilityItems [list \
      "Edit Saved MacroÉ" "Rename Saved MacroÉ" \
      "Copy Saved MacroÉ" "Delete Saved MacroÉ" "(-)" \
      "Assign ShortcutsÉ" "Remove ShortcutsÉ" \
      "Hide Saved MacrosÉ" "Show Hidden MacrosÉ" "(-)" \
      "Show Macros Folder" "Rebuild Menu"\
      ]
    foreach item $utilityItems {
	if {($item ne "(-)") && ([lsearch $reservedNames $item] == -1)} {
	    lappend reservedNames $item
	}
    }
    # Create the menu list.
    set visibleMacros [macro::createList "visible"]
    if {![llength [macro::createList]]} {
	set menuList [list "No Saved Macros"]
    } elseif {![llength $visibleMacros]} {
	set menuList [list "All Macros Are Hidden"]
    } else {
	foreach macroName $visibleMacros {
	    lappend menuList "[macro::getBinding $macroName]${macroName}"
	}
    }
    if {([llength $menuList] > 10)} {
	set utilsMenu \
	  [list Menu -m -n "Macro Utilities" -p {macro::menuProc} $utilityItems]
	if {!$macrosmodeVars(macrosMenusLocation)} {
	    set menuList [linsert $menuList 0 $utilsMenu "(-)"]
	} else {
	    lappend menuList "(-)" $utilsMenu
	}
	set utilitiesMenu "Macro Utilities"
    } else {
	set menuList [concat $menuList "(-)" $utilityItems]
	set utilitiesMenu "savedMacros"
    }
    return [list build $menuList {macro::menuProc -m}]
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::postBuildRecord" --
 # 
 # Enable/dim Macro Recording commands as necessary.  This is called when the
 # menu is first built, when the user changes any of the keyboard shortcuts,
 # and (most importantly) whenever the variable "macro::recording" is changed
 # to some new value.
 # 
 # Because the Macro Recording commands might be called by a variety of
 # keyboard shortcuts, some of which might not get passed through our
 # [macro::menuProc], we cannot simply call this directly when the recording
 # starts/stops.  Instead, we count on the [trace] that we put on the
 # "macro::recording" variable in [macro::initializePackage].
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::postBuildRecord {args} {
    
    if {([set r [macro::recording]] != 0) && ($r != 1)} {
	return
    }
    set dim1 [expr {$r == 0} ? 1 : 0]
    set dim2 [expr {$dim1} ? 0 : 1]
    set dim4 [expr {[macro::emptyScript "lastRecordedMacro"]} ? 0 : 1]
    set dim3 [expr {$dim1 && $dim4} ? 1 : 0]
    enableMenuItem macroRecording beginRecording        $dim1
    enableMenuItem macroRecording endRecording          $dim2
    enableMenuItem macroRecording executeLastMacro      $dim3
    enableMenuItem macroRecording displayLastMacro      $dim4
    enableMenuItem macroRecording saveLastMacroÉ        $dim4
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::postBuildSaved" --
 # 
 # Enable/dim "Utils > Saved Macros" items based on the length of the list of
 # macros saved in the lists and arrays associated with this package.  This
 # is called when the menu is rebuilt via [menu::buildSome].
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::postBuildSaved {} {
    
    variable utilitiesMenu
    
    set dim1 [expr {[llength [macro::createList]]} ? 1 : 0]
    set dim2 0
    set dim3 0
    set dim4 0
    if {!$dim1} {
	enableMenuItem -m "savedMacros" "No Saved Macros" 0
    } elseif {![llength [macro::createList "visible"]]} {
	enableMenuItem -m "savedMacros" "All Macros Are Hidden" 0
	set dim4 1
    } else {
	set dim2 1
	set dim3 [expr {[llength [macro::createList "withKeys"]]}  ? 1 : 0]
	set dim4 [expr {[llength [macro::createList "hidden"]]}  ? 1 : 0]
    }
    enableMenuItem -m $utilitiesMenu "Edit Saved MacroÉ"   $dim1
    enableMenuItem -m $utilitiesMenu "Rename Saved MacroÉ" $dim1
    enableMenuItem -m $utilitiesMenu "Copy Saved MacroÉ"   $dim1
    enableMenuItem -m $utilitiesMenu "Delete Saved MacroÉ" $dim1
    enableMenuItem -m $utilitiesMenu "Assign ShortcutsÉ"   $dim2
    enableMenuItem -m $utilitiesMenu "Remove ShortcutsÉ"   $dim3
    enableMenuItem -m $utilitiesMenu "Hide Saved MacrosÉ"  $dim2
    enableMenuItem -m $utilitiesMenu "Show Hidden MacrosÉ" $dim4
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::rebuildMenu" --
 # 
 # Rebuild the given menus, possibly determining the menus that should be
 # rebuilt if called when the user has changed a keyboard shortcut.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::rebuildMenu {args} {
    
    getOpts
    set prefsList [list "beginRecording" "endRecording" "executeLastMacro"]
    if {([lsearch $prefsList [lindex $args 0]] > -1)} {
	# Called from the Macros Packages dialog.
	set args [list "macroRecording"]
    } elseif {![llength $args]} {
	set args [list "macroRecording" "savedMacros"]
    }
    foreach menuName $args {
	if {($menuName eq "savedMacros")} {
	    # Make sure that all macro files are recognized.
	    macro::sourceScriptFile "-all"
	}
	menu::buildOne $menuName
	if {[info exists opts(-msg)]} {
	    status::msg "The \"[quote::Prettify $menuName]\"\
	      menu has been rebuilt."
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::menuProc" --
 # 
 # Execute "Utils > Macro Recording" menu items.
 # 
 # When calling the Begin/End Macro Recording commands, we assume that an
 # error-free execution of the core commands will properly display any useful
 # messages regarding recording status and set the "macro::recording" variable
 # to either 0 or 1.  Otherwise, we take matters into our own hands to ensure
 # that the "recording" variable is properly reset, and let the user know why
 # the operation was not successful.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::menuProc {menuName itemName} {
    
    variable macrosFolder
    variable recording
    
    switch -- $menuName {
	"macroRecording" {
	    switch -- $itemName {
		"beginRecording" {
		    macro::currentScript ""
		    if {($recording != 0)} {
			catch {macro::endRecording}
			if {($recording != 0)} {
			    set recording 0
			}
			macro::currentScript ""
			set msg "Cancelled -- Recording was already in progress\
			  but has now been aborted."
		    } elseif {[catch {macro::startRecording} err]} {
			set recording 0
			error "Cancelled -- $err"
		    } else {
			set msg "Recording keyboard macro É"
		    }
		}
		"endRecording" {
		    if {($recording == 0)} {
			set msg "Cancelled -- Not recording!"
		    } elseif {[catch {macro::endRecording} err]} {
			macro::currentScript ""
			if {($recording != 0)} {
			    set recording 0
			}
			error "Cancelled -- $err"
		    } else {
			set msg "Finished keyboard macro."
		    }
		}
		"executeLastMacro" {
		    if {($recording != 0)} {
			catch {macro::endRecording}
			macro::currentScript ""
			if {($recording != 0)} {
			    set recording 0
			}
			set msg "Cancelled -- Cannot execute the\
			  last recorded macro while recording a new one;\
			  recording has been aborted."
			return
		    } elseif {[macro::emptyScript "lastRecordedMacro"]} {
			set msg "The last recorded macro is an empty script."
		    } else {
			uplevel \#0 [list eval [::macro::currentScript]]
			set msg "The last recorded macro has been executed."
		    }
		}
		"displayLastMacro" -
		"saveLastMacro" -
		"editSavedMacro" -
		"renameSavedMacro" -
		"copySavedMacro" -
		"deleteSavedMacro"      {macro::$itemName}
		"recordingShortcuts"    {prefs::dialogs::packagePrefs "macros"}
		"macrosHelp"            {package::helpWindow "macros"}
		"macrosTutorial"        {help::openExample "Macros Example"}
		default                 {error "Unknown menu item: $itemName"}
	    }
	}
	"savedMacros" - "Macro Utilities" {
	    switch -- $itemName {
		"Edit Saved Macro"      {macro::editSavedMacro}
		"Rename Saved Macro"    {macro::renameSavedMacro}
		"Copy Saved Macro"      {macro::copySavedMacro}
		"Delete Saved Macro"    {macro::deleteSavedMacro}
		"Show Macros Folder"    {file::showInFinder $macrosFolder}
		"Assign Shortcuts"      {macro::assignShortcuts}
		"Remove Shortcuts"      {macro::removeShortcuts}
		"Hide Saved Macros"     {macro::hideSavedMacros}
		"Show Hidden Macros"    {macro::showHiddenMacros}
		"Rebuild Menu"          {macro::rebuildMenu -msg}
		default                 {macro::evalScript $itemName}
	    }
	}
    }
    if {[info exists msg]} {
	status::msg $msg
    }
    return
}

# ===========================================================================
# 
# ×××× Macro Utilities ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "macro::displayLastMacro" --
 # 
 # Open a new window and insert the contents of the Last Recorded Macro.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::displayLastMacro {} {
    
    # Do we have a valid macro yet? If not, this should have been dimmed.
    if {[macro::emptyScript "lastRecordedMacro"]} {
	macro::postBuildRecord
	error "Cancelled -- there is no 'last' macro to be displayed."
    }
    set lrm "lastRecordedMacro"
    macro::setScript $lrm [macro::currentScript]
    macro::createScriptFile $lrm [macro::currentScript]
    macro::editScriptFile $lrm
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::saveLastMacro" --
 # 
 # Save the Last Recorded Macro for use between editing sessions.  Saved
 # Macros can also be "hidden" by the user to make the "Utils > Saved Macros"
 # submenu more manageable.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::saveLastMacro {} {
    
    # Do we have a valid macro yet? If not, this should have been dimmed.
    if {[macro::emptyScript "lastRecordedMacro"]} {
	macro::postBuildRecord
	error "Cancelled -- there is no 'last' macro to be saved."
    }
    set macroName [macro::verifyName [prompt "New Macro Name:" ""]]
    macro::createScriptFile $macroName [macro::currentScript]
    macro::sourceScriptFile $macroName
    macro::rebuildMenu
    status::msg "The macro \"$macroName\" has been saved\
      and inserted into the \"Saved Macros\" menu."
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::editSavedMacro" --
 # 
 # Create a dialog which includes a pop-up menu with all Saved Macro Names,
 # allowing the user to open a new Tcl window containing the Macro Procedure.
 # This window can be edited by the user, and then the new definition can be
 # saved between editing sessions.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::editSavedMacro {} {
    
    global alpha::application
    
    variable lastChosenMacro
    
    if {![llength [set savedMacros [macro::createList]]]} {
	status::msg "Cancelled -- there are no saved macros to edit."
	return
    }
    # Open a dialog explaining how this works, with a pop-up menu containing
    # all Saved Macros from which to choose.
    set txt "\
      (1) Select a macro to edit from the pop-up menu below.\r\
      (2) Click \"OK\" to open\
      a new Macro Editing Window containing all of the\
      ALPHA commands and AlphaTcl procedures contained in the macro's script.\
      Saving this Macro Editing Window will load the new script.\r\
      (3) When you are finished editing the macro,\
      you can save and close the window.\r"
    regsub -all -- {ALPHA} $txt ${alpha::application} txt
    set result [dialog::make -title "Editing Saved Macros" \
      -ok "Continue" \
      -okhelptag "Click here to edit the selected macro." \
      -cancelhelptag "Click here to exit without editing any macros." \
      [list "" \
      [list "text" $txt] \
      [list [list "menu" $savedMacros] "Saved Macros:" $lastChosenMacro]]]
    set macroName [set lastChosenMacro [lindex $result 0]]
    macro::editScriptFile $macroName
    status::msg "Edit the \"$macroName\" macro, then save the window."
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::copySavedMacro" --
 # 
 # Copy the contents of a previously Saved Macro Name.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::copySavedMacro {} {
    
    variable lastChosenMacro
    
    if {![llength [set savedMacros [macro::createList]]]} {
	status::msg "Cancelled -- there are no saved macros to copy."
	return
    }
    if {([lsearch $savedMacros $lastChosenMacro] > -1)} {
	set L [list $lastChosenMacro]
    } else {
	set L [lrange $savedMacros 0 0]
    }
    set oldMacroName [listpick -p "Copy which macro?" -L $L $savedMacros]
    set p "Copy \"$oldMacroName\" as É"
    set newMacroName [macro::verifyName [prompt $p $oldMacroName]]
    macro::createScriptFile $newMacroName [macro::getScript $oldMacroName]
    macro::sourceScriptFile $newMacroName
    prefs::saveNow
    macro::rebuildMenu "savedMacros"
    status::msg "The macro \"$oldMacroName\"\
      has been copied to \"$newMacroName\"."
    set lastChosenMacro $newMacroName
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::renameSavedMacro" --
 # 
 # Rename a previously Saved Macro Name, removing all traces of it.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::renameSavedMacro {} {
    
    variable lastChosenMacro
    variable macrosFolder
    
    if {![llength [set savedMacros [macro::createList]]]} {
	status::msg "Cancelled -- there are no saved macros to rename."
	return
    }
    if {([lsearch $savedMacros $lastChosenMacro] > -1)} {
	set L [list $lastChosenMacro]
    } else {
	set L [lrange $savedMacros 0 0]
    }
    set oldMacroName [listpick -p "Rename which macro?" -L $L $savedMacros]
    set p "Rename \"$oldMacroName\" to É"
    set newMacroName [macro::verifyName [prompt $p $oldMacroName]]
    # Copy the old file to the new one.
    set oldMacroFile [file join $macrosFolder $oldMacroName]
    set newMacroFile [file join $macrosFolder $newMacroName]
    set reOpenWindow 0
    foreach w [file::hasOpenWindows $oldMacroFile] {
	killWindow -w $w
	set reOpenWindow 1
    }
    file copy -force $oldMacroFile $newMacroFile
    catch {file::toAlphaSigType $newMacroFile}
    macro::sourceScriptFile $newMacroName
    # Now apply settings from the old macro.
    macro::setBinding $newMacroName [macro::setBinding $oldMacroName]
    if {![macro::hideSave $oldMacroName]} {
	macro::hideSave $newMacroName "hide"
    }
    # Completely remove the old macro.
    macro::removeMacro $oldMacroName
    if {$reOpenWindow} {
	catch {macro::editScriptFile $newMacroName}
    }
    prefs::saveNow
    macro::rebuildMenu "savedMacros"
    status::msg "The macro \"$oldMacroName\"\
      has been renamed to \"$newMacroName\"."
    set lastChosenMacro $newMacroName
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::deleteSavedMacro" --
 # 
 # Delete a previously saved Macro Name, removing all traces of it in the
 # various lists and arrays used in this source file.  This will also remove
 # it from the list of defined procedures in the Tcl interpreter.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::deleteSavedMacro {} {
    
    variable lastChosenMacro
    
    if {![llength [set savedMacros [macro::createList]]]} {
	status::msg "Cancelled -- there are no saved macros to delete."
	return
    }
    if {([lsearch $savedMacros $lastChosenMacro] > -1)} {
	set L [list $lastChosenMacro]
    } else {
	set L [lrange $savedMacros 0 0]
    }
    set macroList [listpick -l -p "Delete which macros?" -L $L $savedMacros]
    foreach macroName $macroList {
	macro::removeMacro $macroName
    }
    prefs::saveNow
    macro::rebuildMenu "savedMacros"
    if {([llength $macroList] == 1)} {
	status::msg "The macro $macroList has been deleted."
    } elseif {([llength $macroList] > 1)} {
	status::msg "The macros $macroList have been deleted."
    } else {
        status::msg "No changes."
    }
    set lastChosenMacro [lindex [macro::createList] 0]
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::hideSavedMacros" --
 # 
 # Hide a previously Saved Macro Name from the "Utils > Saved Macros" menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::hideSavedMacros {} {
    
    variable lastChosenMacro
    
    if {![llength [set visibleMacros [macro::createList "visible"]]]} {
	status::msg "Cancelled -- all saved macros are currently hidden."
	return
    }
    if {([lsearch $visibleMacros $lastChosenMacro] > -1)} {
	set L [list $lastChosenMacro]
    } else {
	set L [lrange $visibleMacros 0 0]
    }
    set macroList [listpick -l -p "Hide which macros?" -L $L $visibleMacros]
    foreach macroName $macroList {
	macro::hideSave $macroName "hide"
	set lastChosenMacro $macroName
    }
    prefs::saveNow
    macro::rebuildMenu "savedMacros"
    if {([llength $macroList] == 1)} {
	set hasHave "has"
	set s ""
    } else {
	set hasHave "have"
	set s "s"
    }
    status::msg "The macro$s $macroList $hasHave\
      been hidden from the \"Saved Macros\" menu."
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::showHiddenMacros" --
 # 
 # Show a previously Hidden Saved Macro in the "Utils > Saved Macros" menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::showHiddenMacros {} {
    
    variable lastChosenMacro
    
    if {![llength [set hiddenMacros [macro::createList "hidden"]]]} {
	status::msg "Cancelled -- there are no hidden macros to show."
	return
    }
    if {([lsearch $hiddenMacros $lastChosenMacro] > -1)} {
	set L [list $lastChosenMacro]
    } else {
	set L [lrange $hiddenMacros 0 0]
    }
    set macroList [listpick -l -p "Show which macros?" -L $L $hiddenMacros]
    foreach macroName $macroList {
	macro::hideSave $macroName "show"
	set lastChosenMacro $macroName
    }
    prefs::saveNow
    macro::rebuildMenu "savedMacros"
    if {([llength $macroList] == 1)} {
	set isAre "is"
	set s ""
    } else {
	set isAre "are"
	set s "s"
    }
    status::msg "The macro$s $macroList $isAre\
      now in the \"Saved Macros\" menu."
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::assignShortcuts" --
 # 
 # Assign user-defined keyboard shortcuts to any Saved Macro which will be
 # included in the "Utils > Saved Macros" menu.  We only offer Saved Macros
 # which are also "visible".
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::assignShortcuts {} {
    
    if {![llength [set visibleMacros [macro::createList "visible"]]]} {
	status::msg "Cancelled -- there are no shown macros to assign"
	return
    }
    foreach macroName $visibleMacros {
	set tempBindings($macroName) [macro::getBinding $macroName]
    }
    set title "Saved Macro Keyboard Shortcuts"
    catch {dialog::arrayBindings $title tempBindings 1}
    
    foreach macroName $visibleMacros {
	if {[info exists tempBindings($macroName)]} {
	    macro::setBinding $macroName $tempBindings($macroName)
	} else {
	    macro::setBinding $macroName ""
	}
    }
    prefs::saveNow
    macro::rebuildMenu "savedMacros"
    status::msg "The new Keyboard Shortcuts have been assigned,\
      and appear in the \"Saved Macros\" menu."
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "macro::removeShortcuts" --
 # 
 # Remove a previously set keyboard shortcut to any Saved Macro.  The user
 # could create a "<no binding>" shortcut to any item by using the menu
 # command "Utils > Saved Macros > Assign Shortcuts", but this procedure
 # allows one to select several at once.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::removeShortcuts {} {
    
    if {![llength [set macrosWithKeys [macro::createList "withKeys"]]]} {
	status::msg "Cancelled -- there are no assigned shortcuts to unset."
	return
    }
    set macroList [listpick -l -p "Remove which shortcuts?" $macrosWithKeys]
    foreach macroName $macroList {
	macro::setBinding $macroName ""
    }
    prefs::saveNow
    macro::rebuildMenu "savedMacros"
    if {([llength $macroList] == 1)} {
	status::msg "The Keyboard Shortcut for $macroList has been removed."
    } elseif {([llength $macroList] > 1)} {
	status::msg "The Keyboard Shortcuts for $macroList have been removed."
    } else {
        status::msg "No changes."
	return
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  vers#  reason
# -------- --- ------ -----------
#    ??    ??  0.1
#    ??    ??  0.2
# 02/26/01 cbu 1.0    Added support for assigning menu binding codes for
#                       user defined macros.
#                     Split the single menu into three, one for recording,
#                       one for utilities, one for saved macros.
#                     Added macro::renameSavedMacro menu item.
#                     Added ability to hide/show saved macros.
#                     Changed "Dump Saved Macro" to "List Saved Macros".
#                     All listpicks now take multiple lists.
#                     Added "Macros Help/Tutorial" menu items.
# 03/01/01 cbu 1.1    Added "Display Last Macro" menu item.
#                     Saved macros can now be easily edited by the user.
# 08/29/01 vmd 1.2    Renamed core macros procs, see "coreFixes.tcl."
# 10/16/01 cbu 1.3    Using 'posteval' rather than trying to dim items as
#                       menus are being built.  (Much more robust, esp wrt
#                       Alphatk, where it's harder to both dim and have
#                       keyboard bindings embedded in menus.  Plus, enabling
#                       menu items is less intensive than rebuilding menus.)
#                     Macro keys can be set using menu item.
# 08/13/03 cbu 1.4    Tcl 8.0 or greater is now required.
#                     Craig took over maintenance of this package.
#                     Minor Tcl formatting changes.
#                     Version 1.4.x is transitional, reorganizing this file,
#                       adding annotation, etc.  Version 1.5 will introduce
#                       a new storage method for saved macros.
# 08/14/03 cbu 1.4.1  New [macro::initializePackage] proc, called when package
#                       is first initialized.  AlphaTcl package and Tcl indices
#                       should be rebuilt for this version.
#                     Package variables saved during [macro::quitHook] to avoid
#                       calling [prefs::modified] throughout all of the Saved
#                       Macro manipulation procs.
#                     Annotation of source file procedures.
# 08/15/03 cbu 1.4.2  New [macro::setBinding] procedure, so that other procs
#                       can query, set, unset bindings easier.
#                     The global variable "macroKeys" has been replaced by
#                       a macro variable named "macroBindings"
# 08/16/03 cbu 1.4.3  Removed "Utils > Macro Utils > List Saved Macros" menu
#                       command -- very similar to editing a macro.
#                     [macro::savedMacroList] is a new internal procedure.
#                     New [macro::createMacroList] procedure, so that other
#                       procs don't have to know how macros are saved, or the
#                       names of the various macro lists.
#                     Local variables do a better job of distinguishing the
#                       "macroName" from the "macroProc".
# 08/16/03 cbu 1.4.4  New [macro::emptyLastMacro] procedure, to avoid using
#                       the same scriptlet so many times in this file.
#                     Minor bug fix in [macro::save/displayLastMacro], should
#                       have used [macro::current] at some point.
# 08/16/03 cbu 1.4.5  Hidden macros are now saved as a list, the global
#                       variable "macroNames" is now obsolete.
# 08/16/03 cbu 1.4.6  New [macros::add/edit/deleteMacro] procedures to help
#                       simplify what's going on in some of the utility items.
#                     The global array "macroArr" has been replaced by a
#                       macro variable named "savedMacroProcs".
#                     Another file re-organization.
# 08/16/03 cbu 1.4.7  Internal procedure renaming, and code cleanup.
#                     Removed several unused procedure arguments.
# 08/16/03 cbu 1.4.8  Combined the "Macro Recording" and "Macros Utils" menus
#                       into one to save some real estate, and moved some of
#                       the Saved Macros Utilities into the "Saved Macros" menu.
#                     New "Utils > Macro Recording > Copy Saved Macro" command.
#                     The "Saved Macros" menu now gets passed through its own
#                       menu proc, [macro::savedMacrosProc].  It is also built
#                       without any menu conversion of the item names.
#                     In future versions, it might make more sense to simply
#                       save the macro body (script) rather than the entire
#                       string "proc <macroNames> {} <script>".
# 08/17/03 cbu 1.5    Now saving Macro Scripts instead of Macro Procs.  This
#                       a lot of little changes in how we deal with Saved Macro
#                       manipulation, especially in the "Macros Utils" commands.
#                       This helps simplify what is taking place.
#                     Editing a Saved Macro will open a Macro Editing Window
#                       in a temporary folder.  Saving this window will source
#                       the contents of the new macro script.
# 08/21/03 cbu 1.5.1  Minor adjustment in "macro::recording" queries.
# 01/20/05 vmd 1.5.2  Added "hookmode" registered for our save procedure.
# 07/15/05 cbu 2.0b1  All saved macro scripts are now saved as files within
#                       a new "$PREFS/Macros" folder.  Saved macro scripts
#                       are now [eval]ed, never turned into procedures.
#                     New [macro::currentScript] is our interface proc to
#                       determine the contents of the last recorded macro.
# 07/29/05 cbu 2.0b2  The last recorded macro is saved between editing sessions.
#                     [insertText] -> [typeText] in current macros.
# 08/05/05 cbu 2.0b3  Moved some more utilities into the "Saved Macros" menu.
#                     [macro::savedMacrosProc] incorporated into the main 
#                       [macro::menuProc].
#                     [macro::postBuildUtilities] into [macro::postBuildSaved]
#                     New internal [macro::removeMacro] procedure.
#                     New "lastChosenMacro" is used for most list-pick dialogs.
# 01/04/06 cbu 2.0b4  Default "macrosFolder" is now in $SUPPORT(user).
#                     New [macro::activatePackage] procedure.
#                     New preference to determine location of Macros menus.
# 01/06/06 cbu 2.0    Updated documentation, final release of version 2.0 .
# 03/01/06 cbu 2.0.1  Preferences are saved after they change.
# 

# ===========================================================================
# 
# .