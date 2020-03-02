## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "notes.tcl"
 #                                          created: 09/18/1997 {04:33:31 pm}
 #                                      last update: 02/28/2006 {04:12:49 PM}
 # Description:
 # 
 # Creates a new "File > Notes" submenu which lists the contents of a Notes
 # folder initially located in Alpha's SUPPORT or PREFS folder.  
 # 
 # This is really just a simplified version of a "fromDirectory" fileset,
 # albeit it is dynamically created each time that Alpha is launched.  It is
 # possible to use the new contextual menu "Notes" module without turning
 # this package on.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Includes contributions from Craig Barton Upright
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
alpha::feature notes 1.1 "global-only" {
    # Initialization script.
    notes::initializePackage
} {
    # Activation script.
    notes::activatePackage 1
} {
    # Deactivation script.
    notes::activatePackage 0
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} uninstall {
    this-file
} preinit {
    # Contextual Menu module.
    # Declare a build proc for the Notes menu.
    menu::buildProc notes notes::buildMenu
    # Includes all of the files in your Notes folder; selecting an item will
    # open it in ÇALPHAÈ for editing
    newPref f notesMenu 0 contextualMenu
} description {
    This package inserts a new "File > Notes" submenu which allows you to
    manage a set a notes retained in your Support folder
} help {
    This package inserts a new "File > Notes" submenu which allows you to
    manage a set a Note Files retained in your preferences folder.  To turn
    this package on select "Config > Global Setup > Features" and click on
    the checkbox next to "Notes".
    
    Preferences: Features
    
    Once it has been turned on, you can select "File > Notes > Notes Prefs" to
    adjust the few preferences associated with this package.
    
    Preferences: notes
    
    The preference named "Open Notes On Startup" allows you to automatically
    open these Note Files whenever Alpha is first launched.
    
    The default "Notes" folder is located in your ÇALPHAÈ Support folder.  If
    you have previously set your folder to a different location, you can
    transfer all of your note files to this Support folder if desired.
    
    <<notes::useSupportFolder>>
    
    Click here to show your Notes folder in the Finder:
    
    <<notes::menuProc "" "Show Notes Folder">>
    
    A Contextual Menu "Notes" module is also available which provides a
    submenu with all Note Files and utility items.  It is not necessary to
    turn this package on in order to have access to the contextual menu
    version of the Notes menu and all Note Files.
}

proc notes.tcl {} {}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval notes" --
 # 
 # Define all variables required to run this package.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval notes {
    
    variable initialized
    if {![info exists initialized]} {
        set initialized 0
    }
    # Keep track of our Notes folder location.  We'll use any previously set 
    # preference values, or the previously created default location in PREFS 
    # if they exist; otherwise we try to use the SUPPORT(user) directory.
    variable notesFolder
    if {[info exists ::notesmodeVars(notesFolder)]} {
        set notesFolder $::notesmodeVars(notesFolder)
    } elseif {[file isdir [file join $::PREFS "Notes"]]} {
	set notesFolder [file join $::PREFS "Notes"]
    } elseif {($::SUPPORT(user) ne "")} {
        set notesFolder [file join $::SUPPORT(user) Notes]
    } else {
        set notesFolder [file join $::PREFS Notes]
    }
    # Declare a build proc for the Notes menu.
    menu::buildProc notes notes::buildMenu
    # For beta-testing only.
    variable debugging
    if {![info exists debugging]} {
	set debugging 0
    } 
}

## 
 # --------------------------------------------------------------------------
 # 
 # "notes::initializePackage" --
 # 
 # Define any other variables required in order to properly use this package,
 # and make sure that the "notesFolder" exists.  Remember that because of our
 # CM module definition in the "preinit" argument, some procedures might be
 # called even if this feature is not turned on.
 # 
 # --------------------------------------------------------------------------
 ##

proc notes::initializePackage {} {
    
    global newDocTypes notesmodeVars PREFS
    
    variable initialized
    variable notesFolder
    variable oldNotesFolder
    
    if {($initialized)} {
        return
    }
    
    # Preferences.
    
    # Rename old Notes prefs
    prefs::renameOld openNotesOnStartup notesmodeVars(openNotesOnStartup)
    
    # The location of the "Notes" folder.
    newPref folder notesFolder $notesFolder notes {notes::changeNotesFolder}
    # All files in the "Notes" folder can be opened with Alpha is first
    # started, or opened but iconified.
    newPref var   openNotesOnStartup 0 notes "" [list \
      "Never" "Always" "Always, but minimized" "Always, Shrunk High" \
      "Always, Shrunk Right" "Always, Tiled"] index
    
    # Reset our "notesFolder" variable, and make sure that we can create our
    # Notes folder.
    set notesFolder $notesmodeVars(notesFolder)
    set oldNotesFolder $notesFolder
    if {![file exists $notesFolder]} {
	catch {file mkdir $notesFolder}
    }
    # This should never happen...
    if {![file exists $notesFolder]} {
	alertnote "\"Notes\" package warning:\r\rIt was not possible\
	  to create the \"Notes\" folder in\r\r$notesFolder"
    }
    
    # Declare a new item for the "New Document" package, but only if we are
    # being activated.
    set {newDocTypes(New Note)} [list notes::menuProc "" "New Note"]
    # Startup hook.
    hook::register startupHook notes::startupHook
    set initialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "notes::activatePackage" --
 # 
 # Either insert or remove the "File > Notes" menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc notes::activatePackage {which} {
    
    if {$which} {
	menu::insert   "File" "submenu" 0 "notes"
    } else {
	menu::uninsert "File" "submenu" 0 "notes"
    }
    return
}

# ===========================================================================
# 
# ×××× Hooks, Support Procs ×××× #
# 

##
 # --------------------------------------------------------------------------
 #
 # "notes::startupHook" --
 # 
 # Automatically open all Note Files on startup if desired.  Will also shrink
 # or minimize the windows if the pref has the appropriate value.
 # 
 # --------------------------------------------------------------------------
 ##

proc notes::startupHook {} {
    
    global notesmodeVars
    
    variable notesFolder
    
    notes::initializePackage
    
    if {!$notesmodeVars(openNotesOnStartup)} {
	return
    }
    foreach noteFile [notes::listNoteFiles] {
	if {[catch {file::openQuietly [file join $notesFolder $noteFile]}]} {
	    status::msg "Couldn't open the Notes file \"${noteFile}\""
	    continue
	}
	switch -- $notesmodeVars(openNotesOnStartup) {
	    "2" {icon -t}
	    "3" {shrinkHigh}
	    "4" {shrinkRight}
	}
    }
    if {($notesmodeVars(openNotesOnStartup) == 5)} {
	wintiled
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "notes::deactivate" --
 # 
 # Automatically minimize any Note File when it is put into the background.
 # 
 # This was included in earlier versions of this package, but it only works
 # kindof sortof, and not very well with Alphatk.  The preference would go in
 # the Preferences section above.  Retained here mainly for archiving
 # purposes, although if it seems useful somebody should feel free to try to
 # implement it.
 # 
 # --------------------------------------------------------------------------
 ##

# # To always iconify notes when they are put in the background, turn this
# # item on||To disable the automatic iconification of notes when they
# # are put in the background, turn this item off
# newPref flag  alwaysIconifyNotes 0 "global"    
# 
# hook::register deactivateHook notes::deactivate
# 
# proc notes::deactivate {name} {
#     
#     global notesmodeVars
#     
#     variable notesFolder
#     
#     if {!$notesmodeVars(alwaysIconifyNotes)} {
# 	return
#     }
#     if {[file::pathStartsWith $name $notesFolder]} {
# 	if {![icon -q]} {
# 	    icon -t
# 	}
#     }
# }

##
 # --------------------------------------------------------------------------
 #
 # "notes::listNoteFiles" --
 # 
 # Lists all files in the Notes Folder, minus backups.
 # 
 # --------------------------------------------------------------------------
 ##

proc notes::listNoteFiles {{folderPath ""}} {
    
    global backupExtension
    
    variable notesFolder
    
    notes::initializePackage
    
    set noteList [list]
    if {($folderPath eq "")} {
	set folderPath $notesFolder
    }
    foreach noteFile [glob -nocomplain -dir $folderPath -- *] {
	if {[regexp -- "${backupExtension}\$" $noteFile]} {
	    continue
	}
	lappend noteList "[file tail $noteFile]"
    }
    return [lsort -dictionary $noteList]
}

##
 # --------------------------------------------------------------------------
 #
 # "notes::changeNotesFolder" --
 # 
 # Move all of the contents of the older Notes Folder into the new one. 
 # This is only called when the user changes the preference via the package
 # prefs dialog.
 # 
 # The preference should have already been changed when this is called, so 
 # "notesmodeVars(notesFolder)" has been set but the local "notesFolder" 
 # variable is still the old location.
 # 
 # --------------------------------------------------------------------------
 ##

proc notes::changeNotesFolder {args} {
    
    global notesmodeVars
    
    variable notesFolder
    variable oldNotesFolder
    
    set newNotesFolder $notesmodeVars(notesFolder)
    set reopenFiles    [list]
    set copyFiles      [list]
    set uncopiedFiles  [list]
    # Make sure that we're not over-writing pre-existing files in the new
    # "Notes" directory.
    foreach f [notes::listNoteFiles $oldNotesFolder] {
	set oldFile [file join $oldNotesFolder $f]
	set newFile [file join $newNotesFolder $f]
	if {[file exists $newFile]} {
	    set msg "\"${f}\" already exists in the new Notes Folder\
	      location -- do you want to replace it?"
	    if {![askyesno $msg]} {
		lappend uncopiedFiles $f
	    } else {
		lappend copyFiles $oldFile
	    }
	} else {
	    lappend copyFiles $oldFile
	}
	set openWins [file::hasOpenWindows $oldFile]
	if {[llength $openWins]} {
	    foreach w $openWins {
		killWindow -w $w
	    }
	    lappend reopenFiles $newFile
	}
    }
    if {[llength $copyFiles]} {
	eval [list file copy -force --] $copyFiles [list $newNotesFolder]
    }
    foreach f $reopenFiles {edit -c $f}
    if {[llength $uncopiedFiles]} {
	set p "The following files were not moved:"
	listpick -p $p $uncopiedFiles
	file::showInFinder $oldNotesFolder
	file::showInFinder $newNotesFolder
    } else {
	status::msg "All note files have been copied to the new folder."
	if {[askyesno "Do you want to delete the older \"Notes\" folder?"]} {
	    file delete -force -- $oldNotesFolder
	    status::msg "The older \"Notes\" folder has been removed."
	}
    }
    set notesFolder $newNotesFolder
    set oldNotesFolder $newNotesFolder
    notes::filesToAlpha
    menu::buildSome "notes"
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "notes::useSupportFolder" --
 # 
 # Called by a hyperlink in the Help window, attempt to change the default
 # location of the "Notes" folder to the SUPPORT(user) directory and transfer
 # all of the files.
 # 
 # --------------------------------------------------------------------------
 ##

proc notes::useSupportFolder {} {
    
    global notesmodeVars SUPPORT alpha::application
    
    variable notesFolder
    
    # Make sure that we've been turned on.
    if {![package::active "notes"]} {
        set q "The \"Notes\" feauture has not been turned on.  Would you\
	  like to do so now?"
	if {![askyesno $q]} {
	    error "Cancelled."
	} else {
	    package::makeOnOrOff "notes" "basic-on" "global"
	}
    }
    if {($SUPPORT(user) eq "") || ![file exists $SUPPORT(user)]} {
        dialog::errorAlert "Cancelled -- the $alpha::application\
	  Support Folder doesn't exist."
    }
    set newNotesFolder [file join $SUPPORT(user) Notes]
    if {($notesmodeVars(notesFolder) eq $newNotesFolder)} {
        alertnote "Cancelled -- the current Notes Folder is already in your\
	  $alpha::application Support folder."
	return
    }
    set q "Do you want to set your $alpha::application Support folder to be\
      the new location for your Note files?"
    if {![askyesno $q]} {
        error "Cancelled."
    }
    if {![file exists $newNotesFolder]} {
        catch {file mkdir $newNotesFolder}
    }
    if {![file exists $newNotesFolder]} {
        dialog::errorAlert "Cancelled -- Could not create the new folder:\
	  \r\r$newNotesFolder"
    }
    set notesmodeVars(notesFolder) $newNotesFolder
    prefs::modified notesmodeVars(notesFolder)
    notes::changeNotesFolder
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "notes::filesToAlpha" --
 # 
 # A convenience procedure to change the creator and type codes of all files 
 # in the Notes folder.
 # 
 # --------------------------------------------------------------------------
 ##

proc notes::filesToAlpha {} {
    
    variable notesFolder
    
    foreach fileTail [notes::listNoteFiles] {
	set filePath [file join $notesFolder $fileTail]
        catch {file::toAlphaSigType $filePath}
    } 
    return
}

# ===========================================================================
# 
# ×××× Notes Menu ×××× #
# 

##
 # --------------------------------------------------------------------------
 #
 # "notes::buildMenu" --
 # 
 # Build the Notes menu.  Since none of these operate on any position in the
 # active window, we can use the same menu for the CM.
 # 
 # --------------------------------------------------------------------------
 ##

proc notes::buildMenu {} {
    
    notes::initializePackage
    
    if {[llength [set noteFiles [notes::listNoteFiles]]]} {
	foreach noteFile $noteFiles {
	    lappend menuList "$noteFile&"
	}
	lappend menuList "(-)" "New NoteÉ" "Rename NoteÉ" "Delete NoteÉ"
    } else {
	lappend menuList "New NoteÉ" "(Rename NoteÉ" "(Delete NoteÉ"
    }
    lappend menuList "Show Notes Folder" "(-)" "Notes PrefsÉ" "Notes Help"
    return [list build $menuList "notes::menuProc -m"]
}

##
 # --------------------------------------------------------------------------
 #
 # "notes::menuProc" --
 # 
 # The procedure called for all items in the "Notes" menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc notes::menuProc {menuName itemName} {
    
    global backupExtension
    
    variable notesFolder
    
    switch -- $itemName {
	"New Note" {
	    # Create a new note.
	    set p "New Note Name:"
	    while {1} {
		set noteName [prompt $p ""]
		if {![string length $noteName]} {
		    set p "You must enter a name:"
		    continue
		} elseif {[file exists [file join $notesFolder $noteName]]} {
		    set q "The note \"${noteName}\" already exists.\r\r\
		      Do you want to open it?"
		    if {[askyesno $q]} {
			break
		    } else {
			set p "Try a different name:"
			continue
		    }
		} else {
		    break
		}
	    }
	    set newNote [file join $notesFolder $noteName]
	    if {[file exists $newNote]} {
		file::openQuietly $newNote
	    } else {
		close [open $newNote "w"]
		edit -c $newNote
		menu::buildSome "notes"
	    }
	}
	"Rename Note" {
	    # Rename an existing note.
	    set p1 "Select a note to rename:"
	    set notes [notes::listNoteFiles]
	    while {![catch {listpick -p $p1 $notes} res]} {
		if {![llength $res]} {
		    error "Cancelled."
		}
		set p2 "New name for \"${res}\""
		if {[catch {prompt $p2 $res} newName] \
		  || (![string length $newName])} {
		    error "Cancelled."
		}
		set oldNote [file join $notesFolder $res]
		set newNote [file join $notesFolder $newName]
		set reOpen  0
		if {[file exists $newNote]} {
		    alertnote "\"${newName}\" is already a note."
		    continue
		} elseif {![file exists $oldNote]} {
		    alertnote "Couldn't find \"${res}\" !!"
		    error "Cancelled"
		} elseif {![catch {bringToFront $oldNote}]} {
		    killWindow
		    set reOpen 1
		}
		# Now we move the note.
		if {[file exists $oldNote]} {
		    file copy $oldNote ${newNote}
		    file delete $oldNote
		}
		# Make sure that we transfer the backups as well.
		set oldNote "${oldNote}${backupExtension}"
		if {[file exists $oldNote]} {
		    file copy $oldNote "${newNote}${backupExtension}"
		    file delete $oldNote
		}
		if {$reOpen} {
		    file::openQuietly $newNote
		}
		set notes [notes::listNoteFiles]
		menu::buildSome "notes"
		status::msg "\"${res}\" has been renamed \"$newName'."
		set p1 "Select another, or press cancel:"
	    }
	}
	"Delete Note" {
	    # Delete an existing note.
	    set noteFiles [notes::listNoteFiles]
	    set results [listpick -l -p "Delete which notes?" $noteFiles]
	    foreach noteFile $results {
		lappend results "${noteFile}${backupExtension}"
	    }
	    foreach noteFile $results {
		if {![catch {bringToFront $noteFile}]} {
		    set question "\"${noteFile}\" is an open window.\
		      Delete it anyway?"
		    if {![askyesno $question]} {
			continue
		    }
		    setWinInfo dirty 0
		    killWindow
		}
		catch {file delete [file join $notesFolder $noteFile]}
		if {![regexp -- "${backupExtension}\$" $noteFile]} {
		    lappend deletedNotes $noteFile
		}
	    }
	    menu::buildSome "notes"
	    if {![info exists deletedNotes]} {
		return
	    }
	    if {([llength $deletedNotes] == 1)} {
		status::msg "\"[lindex $deletedNotes 0]\" has been deleted."
	    } else {
		status::msg "$deletedNotes have been deleted."
	    }
	}
	"Show Notes Folder" {
	    file::showInFinder $notesFolder
	}
	"Rebuild Menu" {
	    # Rebuild the menu.  Useful mainly for debugging.
	    menu::buildSome "notes"
	    status::msg "The \"Notes\" menu has been rebuilt."
	}
	"Notes Prefs" {
	    # Open a prefs dialog.
	    prefs::dialogs::packagePrefs "notes"
	}
	"Notes Help" {
	    # Open the Notes Help window.
	    package::helpWindow "notes"
	}
	default {
	    # Open a note file.
	    if {[file exists [file join $notesFolder $itemName]]} {
		file::openQuietly [file join $notesFolder $itemName]
		bringToFront $itemName
		if {[icon -q]} {
		    icon -o
		}
	    } elseif {[dialog::yesno "Couldn't find \"${itemName}\".\
	      \rWould you like to rebuild the menu?"]} {
		menu::buildSome "notes"
	    } else {
		status::msg "Couldn't find \"${itemName}\"."
	    }
	}
    }
    return
}

# ===========================================================================
#
# ×××× -------- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 05/22/03 cbu 0.5    Re-organization of the procedures in source file.
#                     Update "help" argument.
# 06/28/03 cbu 0.6    Minor Tcl formatting changes.
# 07/05/03 cbu 0.7    New [notes::setNotesFolder] procedure, to help simplify
#                       all of the [file join $PREF ...] stuff.
#                     New "File > Notes > Show Notes Folder" menu command.  
# 07/08/03 cbu 1.0    The Notes Folder can now be specified, the default
#                       is still in the $PREFS folder.  All of Alpha8/X/tk
#                       can now share the same Notes Folder.
#                     New [notes::changeNotesFolder] procedure will help the
#                       user transfer files when changing folder location.
# 08/28/03 cbu 1.0.1  Opening Note Files on startup temporarily disabled for
#                       both Alpha8 and AlphaX -- see bug# 1037 for more info. 
# 10/13/03 cbu 1.0.2  Bug# 1037 workaround removed.
#                     Minor bug fix -- there is no [notes::rebuildMenu] proc.
# 02/04/04 cbu 1.0.3  Better creation of new notes w/ [file::openQuietly].
# 01/05/06 cbu 1.1    Default "Notes" folder is now in "SUPPORT(user)"
#                     User can transfer files to new location if desired.
#                     New [notes::initializePackage] procedure.
#                     New [notes::activatePackage] procedure.
#                     [notes::setNotesFolder] is now obsolete.
# 

# ===========================================================================
#
# .