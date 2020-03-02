## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "alphaDevSmarterSource.tcl"
 #                                          created: 12/29/2005 {11:50:35 PM}
 #                                      last update: 01/24/2006 {05:50:21 PM}
 # Description:
 # 
 # Provides access to various web sites which might be useful for Alpha
 # developers, including some specific AlphaTcl wiki pages, by creating a
 # submenu inserted into the AlphaDev menu.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cbupright@earthlink.net>
 #    www: <http://home.earthlink.net/~cupright/>
 #
 # Copyright (c) 2005-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # Distributed under a Tcl style license.
 # 
 # ==========================================================================
 ##

proc alphaDevSmarterSource.tcl {} {}

namespace eval alphadev::ss {
    variable hooksRegistered
    if {![info exists hooksRegistered]} {
	set hooksRegistered 0
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::ss::buildMenu" --
 # 
 # The menu building procedure for "AlphaDev > Smarter Source"
 # 
 # We also register all window hooks when this package is to properly
 # dim/enable "AlphaDev > Smarter Source" menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::ss::buildMenu {} {
    
    global smarterSourceFolder smarterSourceStatus
    
    variable hooksRegistered
    
    set menuList [list "Open AlphaTcl File…" "Save In Smarter Source…" \
      "Open Smarter Source File…" "Show Smarter Source Folder" "(-)" \
      "Set Smarter Source Folder…" "Smarter Source Help" "(-)"]
    
    if {![info exists smarterSourceStatus]} {
	set sss [package::active "smarterSource"]
    } else {
	set sss $smarterSourceStatus
    }
    lappend menuList "Status: [expr {($sss == 1) ? {Active} : {Inactive}}]…"
    
    # Register the activate, open window hook.
    if {!$hooksRegistered} {
	foreach item [list "Save In Smarter Source…"] {
	    hook::register requireOpenWindowsHook [list "Smarter Source" $item] 1
	}
	hook::register activateHook {alphadev::ss::activateHook}
	set hooksRegistered 1
	# Place a trace on "smarterSourceFolder" to adjust menu items when 
	# the value of the preference changes.
	trace add variable "::smarterSourceFolder" write \
	  {alphadev::ss::postBuildMenu}
	trace add variable "::smarterSourceStatus" write \
	  {menu::buildSome "Smarter Source"}
    }
    # Return the list of items for the menu.
    return [list "build" $menuList {alphadev::ss::menuProc -m}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::ss::postBuildMenu" --
 # 
 # Dim/Enable items based on existence of Smarter Source Folder.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::ss::postBuildMenu {args} {
    
    global smarterSourceFolder
    
    if {![package::active "alphaDeveloperMenu"]} {
	return
    } elseif {![info exists smarterSourceFolder]} {
	set dim1 "0"
    } else {
	set dim1 [file isdir $smarterSourceFolder]
    }
    foreach menuItem [list "Save In SS…" "Open SS File…" "Show SS Folder"] {
	regsub -- {SS} $menuItem {Smarter Source} menuItem
	enableMenuItem -m "Smarter Source" $menuItem $dim1
    } 
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::ss::menuProc" --
 # 
 # The procedure used for all "AlphaDev > Smarter Source" menu commands.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::ss::menuProc {menuName itemName} {
    
    global smarterSourceFolder HOME alpha::application
    
    switch -- $itemName {
	"Open AlphaTcl File" {
	    file::openViaListpicks [file join $HOME Tcl]
	}
	"Save In Smarter Source" {
	    alphadev::ss::folderExists 1
	    # Do we have a legitimate file?
	    requireOpenWindow
	    if {![win::IsFile [win::Current] fileName]} {
		alphadev::ss::activateHook [win::Current]
		error "Cancelled -- The active window doesn't exist as a file."
	    } 
	    if {![alphadev::ss::fileIsInAlphaTcl $fileName relative]} {
		set q "The active window is not in the AlphaTcl hierarchy.\
		  Do you want to continue?"
		if {![askyesno $q]} {
		    error "cancel"
		}
	    }
	    # Is Smarter Source turned on?
	    if {![package::active "smarterSource"]} {
	        alertnote "Warning: Smarter Source is not turned on…"
	    }
	    # Do we need to save the file?
	    if {[win::isDirty]} {
		set q "Do you want to save \"[win::Tail]\"\
		  before saving it in your Smarter Source folder?"
		if {[askyesno -c $q]} {
		    save
		}
	    }
	    # Determine the new Smarter Source file location.
	    if {[info exists relative]} {
		set pathDirs [file split $relative]
		# "pathDirs" includes the file name as the last item.
		set pathDirs [lrange $pathDirs 0 end-1]
		if {([lindex $pathDirs 0] eq "Tcl")} {
		    set pathDirs [lrange $pathDirs 1 end]
		}
	    } else {
		set pathDirs [list]
	    }
	    set newDir $smarterSourceFolder
	    foreach dir $pathDirs {
		set newDir [file join $newDir $dir]
		if {![file isdir $newDir]} {
		    file mkdir $newDir
		}
	    }
	    set newFile [file join $newDir [file tail $fileName]]
	    # Does this new file already exist?  Does the user know what 
	    # this item is going to do?
	    if {[file exists $newFile]} {
		# Find out when the target file was last modified.
		set nfLastMod [file mtime $newFile]
		# Find out when the source file was last modified
		set fnLastMod [file mtime $fileName]
		# Which is newer?
		if {[expr {$nfLastMod < $fnLastMod}]} {
		    set which "An older file named"
		} elseif {[expr {$nfLastMod > $fnLastMod}]} {
		    set which "A newer file named"
		} else {
		    set which "A file named"
		}
		# Should we over-write the existing target?
		set q "$which '${fileName}' already exists\
		  in\r\r'${newDir}'\r\rDo you want to replace it?"
	    } else {
		set q "Saving a file in your Smarter Source folder allows\
		  you to make modifications to ${alpha::application}'s\
		  behavior.\r\rDo you want to save \"[win::Tail]\" in your\
		  Smarter Source folder?"
	    }
	    if {![askyesno $q]} {
		error "cancel"
	    }
	    # Now we copy the file to the new location.
	    saveAs -f $newFile
	    save
	    # Make sure that our activate hooks are used.
	    catch {activateHook [win::Current]}
	    set q "The active window is now a file in your Smarter Source\
	      folder.  You can modify it as you wish.  If you are adding new\
	      procedures or modifying a package's declaration scripts,\
	      it is recommended that you rebuild all Tcl and AlphaTcl\
	      indices when you have finished."
	    if {![dialog::yesno -y "OK" -n "More Information" $q]} {
		package::helpWindow "smarterSource"
	    }
	}
	"Open Smarter Source File" {
	    alphadev::ss::folderExists 1
	    file::openViaListpicks $smarterSourceFolder
	}
	"Show Smarter Source Folder" {
	    alphadev::ss::folderExists 1
	    file::showInFinder $smarterSourceFolder
	}
	"Set Smarter Source Folder" {
	    # Is Smarter Source turned on?
	    if {![package::active "smarterSource"]} {
		alertnote "Warning: Smarter Source is not turned on…"
	    }
	    set q "Do you want to set a new location for your\
	      Smarter Source folder?"
	    if {![askyesno $q]} {
		error "cancel"
	    }
	    set oldSSF $smarterSourceFolder
	    if {[file isdir $oldSSF]} {
		set newSSF $oldSSF
	    } else {
		set newSSF $PREFS
	    }
	    set p "Select a new Smarter Source folder:"
	    set smarterSourceFolder [get_directory -p $p $newSSF]
	    prefs::modified smarterSourceFolder
	    if {[file isdir $oldSSF]} {
		if {[llength [glob -nocomplain -directory $oldSSF "*"]]} {
		    set q "There are some files in your older Smarter Source\
		      Folder location.  Would you like to display both the\
		      old and the new locations in the Finder so that you can\
		      transfer these files?"
		    if {[askyesno $q]} {
			file::showInFinder $oldSSF
			file::showInFinder $smarterSourceFolder
		    }
		}
	    }
	    alphadev::ss::postBuildMenu
	    alphadev::ss::activateHook [win::Current]
	    alertnote "It is recommended that you rebuild all Tcl and AlphaTcl\
	      indices before continuing with other operations."
	}
	"Smarter Source Help" {
	    package::helpWindow "smarterSource"
	}
	"Status: " - "Status: Active" - "Status: Inactive" {
	    set status [package::active "smarterSource"]
	    set txt1 "The Smarter Source package is currently turned\
	      [expr {$status ? "on" : "off"}].  If you change the activation\
	      status, it is highly recommended that you rebuild Tcl and\
	      AlphaTcl indices and then quit $alpha::application before\
	      engaging in any more operations.\r"
	    set txt2 "Note that any change in activation status will continue\
	      after $alpha::application is quit and launched again."
	    set dialogScript [list dialog::make \
	      -title "Smarter Source Activation Status" \
	      -width 450 \
	      -addbuttons [list \
	      "Help" \
	      "Click this button for more help" \
	      "help::openGeneral smarterSource {} ; \
	      set retCode 1 ; set retVal {cancel}" \
	      ] \
	      [list "" \
	      [list "text" $txt1] \
	      [list "flag" "Activate Smarter Source" $status] \
	      [list "text" $txt2] \
	      ]]
	    set result [eval $dialogScript]
	    if {([lindex $result 0] != $status)} {
		set state [expr {$status ? "basic-off" : "basic-on"}]
		package::makeOnOrOff "smarterSource" $state "global"
	    }
	    menu::buildSome "Smarter Source"
	    status::msg "The Smarter Source package is now turned\
	      [expr {[package::active "smarterSource"] ? "on" : "off"}]."
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::ss::folderExists" --
 # 
 # A convenience procedure to determine if the Smarter Source Folder exists, 
 # optionally prompting the user to locate it.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::ss::folderExists {{promptToSet "0"}} {
    
    global smarterSourceFolder
    
    if {[file isdir $smarterSourceFolder]} {
	return 1
    } elseif {!$promptToSet} {
	return 0
    } else {
	alphadev::ss::postBuildMenu
	set q "Your Smarter Source folder doesn't exist!\
	  \rWould you like to set its location?"
	if {![askyesno $q]} {
	    error "cancel"
	}
	alphadev::menuProc $menuName "Set Smarter Source Folder"
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::ss::registerHooks" --
 # 
 # (De)Register all window hooks when this package is (de)activated to 
 # properly dim/enable "AlphaDev > Smarter Source" menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::ss::registerHooks {which} {
    
    if {$which} {
	set which "register"
    } else {
	set which "deregister"
    }
    # Items requiring an open window.
    foreach item [list "Save In Smarter Source…"] {
	hook::$which requireOpenWindowsHook [list "Smarter Source" $item] 1
    }
    hook::$which activateHook {alphadev::ss::activateHook}
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::ss::activateHook" --
 # 
 # Dim/enable menu items when a new window is brought to the front.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::ss::activateHook {name} {
    
    if {![package::active "alphaDeveloperMenu"]} {
	return
    }
    set dim1 [alphadev::ss::fileIsInAlphaTcl $name]
    enableMenuItem -m "Smarter Source" "Save In Smarter Source…" $dim1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::ss::fileIsInAlphaTcl" --
 # 
 # A modified version of [alpha::inAlphaHierarchy], but we want to ignore
 # files that are in the $PREFS folder.  If "relative" is not the null
 # string, then a new variable is created in the context of the calling code,
 # with the relative path to $HOME. (This will include any leading "Tcl"
 # directory after $HOME.)
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::ss::fileIsInAlphaTcl {name {relative ""}} {
    
    global PREFS HOME
    
    if {[win::IsFile $name] && ![file::pathStartsWith $name $PREFS] && \
      [file::pathStartsWith $name $HOME relVar1]} {
	if {($relative ne "")} {
	    upvar 1 $relative relVar2
	    set relVar2 $relVar1
	}
	return 1 
    } else {
	return 0
    }
}

# ===========================================================================
# 
# .