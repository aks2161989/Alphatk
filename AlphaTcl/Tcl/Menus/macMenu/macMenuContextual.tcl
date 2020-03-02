## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "macMenuContextual.tcl"
 #                                          created: 01/22/2003 {02:13:55 PM}
 #                                      last update: 02/25/2006 {03:26:38 AM}
 # Description: 
 # 
 # Contextual menu modules for the Mac Menu.
 # 
 # --------------------------------------------------------------------------
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # Copyright (c) 2003-2006 Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc macMenuContextual.tcl {} {}

namespace eval mac {}

proc mac::buildCMWindow {} {
    
    if {[win::Exists [win::Current]]} {
	set menuList [list \
	  "changeType…" "changeCreator…" "deleteRezFork…" "(-)" \
	  "getFileInfo" "getFolderInfo"  "getVolumeInfo" \
	  ]
    } else {
	set menuList [list "\(Current window doesn't exist"]
    }
    return [list "build" $menuList {mac::cmWindowProc}]
}

proc mac::postBuildCMWindow {args} {

    if {!$::contextualMenumodeVars(macWindowMenu)} {return}
    if {![win::Exists [win::Current]]} {
	enableMenuItem [lindex $args 0] "macWindow" 0
    } 
}

proc mac::buildCMSystem {} {
    
    set macFilesUtils [list \
      "copyFiles…"   "moveFiles…"    "renameFiles…"      "duplicateFiles…" \
      "trashFiles…"  "aliasFiles…"   "removeAliasFiles…" "deleteRezForks…" \
      "lockFiles…"   "unlockFiles…"  "listFiles…" "(-)"  "changeEncoding…" \
	  "changeEols…"  "changeType…"   "changeCreator…"
    ]
    set menuList [list \
      "getHardwareInfo" "getApplicationInfo…" "getProcessInfo…" "(-)" \
      [list Menu -n "macFileUtils" -p {mac::MenuProc} $macFilesUtils] \
      "emptyTrash" "(-)" "macShell" "macMenuPreferences" \
	  "macMenuBindings"  "macMenuTutorial" "macMenuHelp" \
      ]
    return [list "build" $menuList {mac::cmSystemProc}]
}

proc mac::cmWindowProc {menuName itemName} {
    
    set fileName [win::StripCount [win::Current]]
    set fileTail [win::StripCount [win::CurrentTail]]
    
    switch -- $itemName {
	"changeType" {
	    changeFileTypeCreator "type" $fileName
	}
	"changeCreator" {
	    changeFileTypeCreator "creator" $fileName
	}
	"deleteRezFork" {
	    if {[askyesno "Do you really want to delete the resource fork ? \
	      This cannot be 'undone'"] != "yes"} {
		return 0
	    }
	    killWindow
	    status::msg "Deleting resource fork for ${fileTail}…"
	    setFileInfo $fileName resourcelen
	    edit -c [win::StripCount $fileName]
	    status::msg "Deleting resource fork for ${fileTail}… complete"
	}
	"getFileInfo"   {
	    getFilesInfo $fileName
	    showFilesInfo 
	}
	"getFolderInfo" {
	    getFolderInfo [file dirname $fileName]
	    showFolderInfo 
	}
	"getVolumeInfo" {
	    foreach volume [mac::getAllVolsList] {
		if {[string match ${volume}* [file::unixPathToFinder $fileName]]} {
		    break
		} 
	    }
	    getVolumeInfo $volume
	    showVolumeInfo 
	}
	default         {
	    $itemName $fileName
	}
    }
}

proc mac::cmSystemProc {menuName itemName} {
    
    switch -- $itemName {
	"getHardwareInfo"     {infoMenuProc "contextualMenu" hardware}
	"getApplicationInfo"  {infoMenuProc "contextualMenu" application}
	"getProcessInfo"      {infoMenuProc "contextualMenu" process}
	"macMenuBindings"     {macMenuBindingsInfo}
	"macMenuTutorial"     {help::openExample "MacMenu Example"}
	"macMenuHelp"         {package::helpWindow "macMenu"}
	"macMenuPreferences"  {prefs::dialogs::packagePrefs "macMenu"}
	default               {MenuProc "contextualMenu" $itemName}
    }
}

# ◊◊◊◊ -------- ◊◊◊◊ #

# These next two procs are adapted from others in the macMenu package.

# Alpha8 buglet: how can we change the icon in the titlebar?
# Note that it does change when the file is saved ...

proc mac::changeFileTypeCreator {which args} {

    # Preliminaries
    switch -- $which {
	"type"    {set aeArg "asty"}
	"creator" {set aeArg "fcrt"}
	default   {error "incorrect arg specification: 'type' or 'creator'"}
    }
    if {[llength $args] > 2} {
	error "Incorrect specification of args: ?fileName? ?new${which}?"
    } 
    set fileName [lindex $args 0]
    set newValue [lindex $args 1]
    set oldValue ""
    set quietly 1

    # Do we have a default file name?
    if {![string length $fileName]} {
	set quietly 0
	status::msg "Choose a file whose $which you want to change"
	if {[catch {getfile "Choose a file:"} fileName]} {return 0}
	set oldValue $newValue
	set newValue ""
    } 
    # Do we have a default new $which value?
    if {![string length $newValue]} {
	set quietly 0
	if {![string length $oldValue]} {
	    set oldValue [mac::getTypeCreator $aeArg $fileName]
	} 
	set newValue [changeTypeCreatorDialog $which $oldValue]
	if {$oldValue == $newValue} {
	    status::msg "Cancelled -- nothing was change."
	    return 0
	} 
    } 
    # Now change the $which .
    set msg1 "Changing $which for [file tail $fileName]…"
    set msg2 "${msg1} complete. New $which is '$newValue'."
    set msg3 "Could not change ${which}."
    if {!$quietly} {status::msg $msg1}
    if {![catch {mac::setTypeCreator $aeArg $fileName $newValue} res]} {
	if {!$quietly} {status::msg $msg2}
	return 1
    } else {
	if {!$quietly} {status::msg $msg3}
	return 0
    }
}

proc mac::changeTypeCreatorDialog {which {defaultValue ""}} {
    
    switch -- $which {
	"type"    {set aeArg "asty"}
	"creator" {set aeArg "fcrt"}
	default   {error "incorrect arg specification: 'type' or 'creator'"}
    }
    status::msg "Enter a new $which, or press 'Change' to use this value."
    lappend d [list \
      -t "* Choose a new $which *"   70 10 290  30 \
      -b "Change"                   220 80 295 100 \
      -b "Cancel"                   130 80 200 100 \
      -t "New $which :"              10 40 100  60 \
      -e $defaultValue              110 40 150  60 \
      -t "or"                       170 40 190  60 \
      -b "Same as…"                 210 40 300  60 ]
    if {[lindex [set result [eval dialog -w 310 -h 120 [join $d]]] 1]} {
	# User pressed cancel.
	status::msg "Cancelled."
	error "cancel"
    } elseif {[lindex $result 0]} {
	# User entered a value.
	if {[string length [lindex $result 2]] == 4} {
	    return [lindex $result 2]
	} else {
	    alertnote "The '$which' must be a four character string."
	    changeTypeCreatorDialog $which [lindex $result 2]
	}
	return [lindex $result 2]
    } elseif {[lindex $result 3]} {
	# Get the $which of an example.
	status::msg "Choose a file whose $which you want to mimic"
	if {[catch {getfile "Choose a file to mimic:"} fileLike]} {error "cancel"}
	set defaultValue [mac::getTypeCreator $aeArg $fileLike]
	# Offer this dialog again to confirm.
	changeTypeCreatorDialog $which $defaultValue
    }
}

# ===========================================================================
# 
# .