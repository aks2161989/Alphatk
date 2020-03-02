## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "alphaDevSupportFolders.tcl"
 #                                          created: 01/04/2006 {05:06:04 PM}
 #                                      last update: 03/06/2006 {07:17:13 PM}
 # Description:
 # 
 # Provides access to AlphaTcl's "SUPPORT" folders.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@earthlink.net>
 #    www: <http://home.earthlink.net/~cupright/>
 #  
 # Copyright (c) 2006  Craig Barton Upright
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::library "supportFolders" "1.0b2" {
    # Define the "Config > Support Folders" menu.
    menu::buildProc "supportFolders" {alphadev::support::buildMenu} \
      {alphadev::support::postBuildMenu}
    # Insert this menu.
    menu::insert "Config" submenu "\(-" "supportFolders"
}


proc alphaDevSupportFolders.tcl {} {}

namespace eval alphadev::support {
    
    # Used in [alphadev::support::buildMenu] to determine if our hooks have	 
    # been registered yet or not.	 
    variable hooksRegistered	 
    if {![info exists hooksRegistered]} {	 
	set hooksRegistered 0	 
    }
    variable descriptions
    array set descriptions [list \
      "user"    "\"user\" -- Specific to your account" \
      "local"   "\"local\" -- System folder, readable by all" \
      ]
    foreach domain [array names ::SUPPORT] {
	if {![info exists descriptions($domain)]} {
	    set descriptions($domain) "\"$domain\" -- no information available."
	}
    }
    unset -nocomplain domain
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::support::buildMenu" --
 # 
 # The menu building procedure for "AlphaDev > Support Folders"
 # 
 # We also register all window hooks when this package is to properly
 # dim/enable "AlphaDev > Support Folders" menu items, or to detect when a
 # user has opened an AlphaTcl file in a Support Folder.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::support::buildMenu {} {
    
    variable hooksRegistered
    
    set folders [alphadev::support::folderExists]
    set dots [expr {([llength $folders] > 1) ? "É" : ""}]
    set menuList [list "Open AlphaTcl FileÉ" "Open Support Folder FileÉ" \
      "Save In Support FolderÉ" "Show Support Folder$dots" "(-)" \
      "Support Folders StatusÉ" "Support Folders Help"]
    
    # Register the activate, open window hook.
    if {!$hooksRegistered} {
	foreach item [list "Save In Support FolderÉ"] {
	    foreach menuName [list "Support Folders" "supportFolders"] {
		hook::register requireOpenWindowsHook [list $menuName $item] 1
	    }
	}
	hook::register activateHook {alphadev::support::activateHook}
	hook::register savePostHook {alphadev::support::editSaveHook}  support
	hook::register closeHook    {alphadev::support::editCloseHook} support
	set hooksRegistered 1
    }
    # Return the list of items for the menu.
    return [list "build" $menuList {alphadev::support::menuProc -m}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::support::postBuildMenu" --
 # 
 # Dim/Enable items based on existence of Support Folders.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::support::postBuildMenu {args} {
    
    if {![package::active "alphaDeveloperMenu"]} {
	return
    }
    set folders [alphadev::support::folderExists]
    set dim1 [expr {[llength $folders] ? "1" : "0"}]
    set dots [expr {([llength $folders] > 1) ? "É" : ""}]
    foreach menuItem [list "Save In SFÉ" "Open SF FileÉ" "Show SF$dots"] {
	regsub -- {SF} $menuItem {Support Folder} menuItem
	foreach menuName [list "Support Folders" "supportFolders"] {
	    catch {enableMenuItem -m $supportFolders $menuItem $dim1}
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::support::menuProc" --
 # 
 # The procedure used for all "AlphaDev > Support Folders" menu commands.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::support::menuProc {menuName itemName} {
    
    global HOME SUPPORT alpha::application
    
    switch -- $itemName {
	"Open AlphaTcl File" {
	    alphadev::support::openAlphaTclFile
	}
	"Open Support Folder File" {
	    set w [file::openViaListpicks [alphadev::support::chooseFolder 0 0]]
	    winReadOnly $w
	}
	"Save In Support Folder" {
	    alphadev::support::saveInSupportFolder
	}
	"Show Support Folder" {
	    file::showInFinder [alphadev::support::chooseFolder 0 0]
	}
	"Support Folders Status" {
	    alphadev::support::supportFoldersStatus
	}
	"Support Folders Help" {
	    help::openGeneral "Support Folders Help"
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::support::folderExists" --
 # 
 # A convenience procedure to determine if the Support Folders exist.  
 # Returns a (possibly empty) list of all Support Folders.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::support::folderExists {{throwError "0"}} {
    
    global SUPPORT
    
    set folders [list]
    foreach domain [array names SUPPORT] {
	if {($SUPPORT($domain) ne "") && [file isdir $SUPPORT($domain)]} {
	    lappend folders $SUPPORT($domain)
	}
    }
    if {![llength $folders] && $throwError} {
	dialog::errorAlert "Cancelled -- No Support Folders exist!"
    } else {
	return $folders
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::support::chooseFolder" --
 # 
 # Choose a SUPPORT folder.  If "inHierarchy" is "1" then we allow the user
 # to find a folder within the chosen SUPPORT domain.  If "requireWritable"
 # is "1" then we only offer domains in which the user has write-permissions.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::support::chooseFolder {{inHierarchy "0"} {requireWritable "1"}} {
    
    global SUPPORT
    
    variable descriptions
    variable lastChosenDomain
    
    alphadev::support::folderExists 1
    set domains [list]
    foreach domain [list "user" "local"] {
	if {($SUPPORT($domain) eq "")} {
	    continue
	} elseif {$requireWritable && ![file writable $SUPPORT($domain)]} {
	    continue
	}
	lappend domains $domain
	lappend options $descriptions($domain)
    }
    if {![llength $domains]} {
	alertnote "Sorry, you do not have permission to write to any\
	  Support Folders."
	error "cancel"
    }
    if {[info exists lastChosenDomain]} {
	set L [list $descriptions($lastChosenDomain)]
    } elseif {([lsearch $domains "user"] > -1)} {
	set L [list $descriptions(user)]
    } else {
	set L [lrange $options 0 0]
    }
    if {([llength $domains] == 1)} {
	set domain [lindex $domains 0]
    } else {
	set p "Choose a Support Folder domain:"
	set domain [lindex $domains [listpick -p $p -L $L -indices $options]]
    }
    set lastChosenDomain $domain
    if {!$inHierarchy} {
	return $SUPPORT($domain)
    } else {
	set p "Choose a directory in SUPPORT($domain):"
	return [get_directory -p $p $SUPPORT($domain)]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::support::activateHook" --
 # 
 # Dim/enable menu items when a new window is brought to the front.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::support::activateHook {window} {
    
    if {![package::active "alphaDeveloperMenu"]} {
	return
    }
    set dim1 [win::IsFile $window]
    foreach menuName [list "Support Folders" "supportFolders"] {
	catch {enableMenuItem -m $menuName "Save In Support FolderÉ" $dim1}
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::support::openAlphaTclFile" --
 # 
 # Inform the user what an "AlphaTcl file" is and does, and then select a
 # file using the list-pick method.  Once the file is selected, we look for a
 # $SUPPORT(local) version and/or a $SUPPORT(user) version of the file.  If
 # no over-ride files exist, we simply open the selected $HOME source file
 # for editing (although initially read-only).  If there are multiple
 # versions available, we allow the user to select the $HOME file, an
 # over-ride file, or all versions.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::support::openAlphaTclFile {{homeFile ""}} {
    
    global HOME SUPPORT alpha::application
    
    variable editHookWindows
    variable editWindowSource
    
    set txt1 "You are about to open a file in the \"AlphaTcl\" directory.\r"
    set txt2 "AlphaTcl open-source files provide the basic functionality\
      of $alpha::application -- you can edit these to modify\
      ${alpha::application}'s default behavior.  You can also completely\
      disable a feature if you don't know what you're doing!\r"
    set txt3 "The chosen file will be opened for editing from its installed\
      location.  If you want to modify it later you should then select the\
      command \"Support Folders > Save In Support Folder\".\r"
    set dialogScript [list dialog::make \
      -title "Open AlphaTcl File?" \
      -width 450 \
      -ok "Continue" \
      -okhelptag "Click here to select an AlphaTcl file to open." \
      -cancelhelptag "Click here to cancel the operation." \
      -addbuttons [list \
      "Help" \
      "Click here to obtain more information about AlphaTcl\
      and Support Folders." \
      "set retCode 0 ; set retVal return ; \
      help::openGeneral {Support Folders Help}" \
      ] \
      [list "" [list "text" $txt1] [list "text" $txt2] [list "text" $txt3] \
      ]]
    eval $dialogScript
    if {($homeFile eq "") || ![file exists $homeFile]} {
	# Select an AlphaTcl file to open.
	set homeFile [file::selectViaListpicks [file join $HOME Tcl]]
    }
    if {![file::pathStartsWith $homeFile $HOME relName]} {
	alertnote "The chosen file is not in the AlphaTcl hierarchy!"
	edit -c $homeFile
	return
    } elseif {([file tail [file dirname $relName]] eq "CVS")} {
	alertnote "Cancelled -- \r\r\
	  You should never attempt to edit \"CVS\" files!"
	error "cancel"
    }
    set allFiles [list $homeFile]
    foreach domain [list "local" "user"] {
	if {($SUPPORT($domain) ne "") \
	  && [file exists [file join $SUPPORT($domain) AlphaTcl $relName]]} {
	    set ${domain}File [file join $SUPPORT($domain) AlphaTcl $relName]
	    lappend allFiles [set ${domain}File]
	}
    }
    if {([llength $allFiles] == 1)} {
	# We only have one version of this file to deal with.
	set filesToOpen $allFiles
    } else {
	# We have multiple versions of this file to offer.
	set localFile [file join $SUPPORT(local) AlphaTcl $relName]
	set options [list "Open the distributed (original) version"]
	if {[info exists localFile]} {
	    lappend options "Open the System Administrator (over-ride) version"
	}
	if {[info exists userFile]} {
	    lappend options "Open your personal version of this file"
	}
	lappend options "-" "Open all versions of this file"
	switch -- [llength $allFiles] {
	    "2" {set howMany "Two"}
	    "3" {set howMany "Three"}
	}
	set intro "$howMany different versions of this source file exist.\r\r"
	if {[info exists localFile] && ![info exists userFile]} {
	    append intro "In addition to the default version distributed with\
	      ${alpha::application}, your System Administrator has installed\
	      an over-ride which is currently used instead of the original."
	} elseif {![info exists localFile] && [info exists userFile]} {
	    append intro "You have already created a Support Folder version\
	      that over-rides the default distributed with ${alpha::application}."
	} else {
	    append intro "In addition to the default version distributed with\
	      ${alpha::application}, your System Administrator has installed\
	      an over-ride, and you have already created a Support Folder\
	      version that over-rides both of these."
	}
	append intro "\r\r" "What would you like to do?\r"
	set dialogScript [list dialog::make \
	  -title "Open Which AlphaTcl File Version?" \
	  -width 450 \
	  -ok "Continue" \
	  -okhelptag "Click here to open the selected AlphaTcl file(s)." \
	  -cancelhelptag "Click here to cancel the operation." \
	  -addbuttons [list \
	  "Help" \
	  "Click here to obtain more information about AlphaTcl\
	  and Support Folders." \
	  "set retCode 0 ; set retVal return ; \
	  help::openGeneral {Support Folders Help}" \
	  ] \
	  [list "" [list "text" $intro] \
	  [list [list "menu" $options] "Option:" [lindex $options 0] \
	  "Select one (or more) files to open"]
	]]
	switch -- [lindex [eval $dialogScript] 0] {
	    "Open the distributed (original) version" {
		set filesToOpen [list $homeFile]
	    }
	    "Open the System Administrator (over-ride) version" {
		set filesToOpen [list $localFile]
	    }
	    "Open your personal version of this file" {
		set filesToOpen [list $userFile]
	    }
	    "Open all versions of this file" {
		set filesToOpen $allFiles
	    }
	}
    }
    foreach fileName $filesToOpen {
	edit -r -c $fileName
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::support::saveInSupportFolder" --
 # 
 # Offer the user the decision to save the active window in a Support Folder.
 # If the active window is in the AlphaTcl hierarchy, then we will try to 
 # save it in the "SUPPORT/Tcl" folder.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::support::saveInSupportFolder {} {
    
    global HOME SUPPORT alpha::application
    
    alphadev::support::folderExists 1
    # Do we have a legitimate file?
    requireOpenWindow
    if {![win::IsFile [win::Current] fileName]} {
	alphadev::support::activateHook [win::Current]
	error "Cancelled -- The active window doesn't exist as a file."
    }
    set homeDirs [list "Help" "Examples" "Tcl"]
    if {([file::pathStartsWith $fileName [file join $HOME] relName] \
      || [file::pathStartsWith $fileName [file join $SUPPORT(local) AlphaTcl] relName]) \
      && ([lsearch $homeDirs [lindex [file split $relName] 0]] > -1)} {
	set txt1 "The active window is in the \"AlphaTcl\" directory.\r"
	set txt2 "AlphaTcl open-source files provide the basic functionality\
	  of $alpha::application -- you can edit these to modify\
	  ${alpha::application}'s default behavior.  You can also completely\
	  disable a feature if you don't know what you're doing!\r"
	set txt3 "If you save this file in your Support Folder, then it\
	  will be used instead of the default version, even if you\
	  upgrade Alpha to a newer version in the future.\r"
	set dialogScript [list dialog::make \
	  -title "Save AlphaTcl File In Support Folder?" \
	  -width 450 \
	  -ok "Continue" \
	  -okhelptag "Click here to save the current window\
	  in your Support Folder." \
	  -cancelhelptag "Click here to cancel the operation." \
	  -addbuttons [list \
	  "Help" \
	  "Click here to obtain more information about Support Folders." \
	  "set retCode 0 ; set retVal return ; \
	  help::openGeneral {Support Folders Help}" \
	  ] \
	  [list "" \
	  [list "text" $txt1] [list "text" $txt2] [list "text" $txt3] \
	  ]]
	eval $dialogScript
    } else {
	set q "Saving a file in your Support Folder allows\
	  you to make modifications to ${alpha::application}'s\
	  behavior.\r\rDo you want to save \"[win::Tail]\" in your\
	  Support Folder?"
	if {![askyesno $q]} {
	    error "cancel"
	}
    }
    # Do we need to save the file?
    if {[win::isDirty]} {
	set q "Do you want to save \"[win::Tail]\"\
	  before saving it in your Support Folder?"
	if {[askyesno -c $q]} {
	    save
	}
    }
    # Determine the new Support Folder file location.
    if {[info exists relName]} {
	set newFile [file join [alphadev::support::chooseFolder 0 1] \
	  AlphaTcl $relName]
	set newDir  [file dirname $newFile]
    } else {
	set newDir  [alphadev::support::chooseFolder 1 1]
	set newFile [file join $newDir [file tail $fileName]]
    }
    if {($newFile eq $fileName)} {
	error "Cancelled -- target and original are the same file!"
    }
    if {![file isdir $newDir]} {
	catch {file mkdir $newDir}
    }
    if {![file writable $newDir]} {
	alertnote "Sorry, you do not have the proper permissions\
	  to save a file in\r\r$newDir"
	error "cancel"
    }
    # Does this new file already exist?  Does the user know what 
    # this item is going to do?
    if {[file exists $newFile]} {
	switch -- [file::compareModifiedDates $fileName $newFile] {
	    "-1" {set which "An older file named"}
	    "0"  {set which "A file named"}
	    "1"  {set which "A newer file named"}
	}
	# Should we over-write the existing target?
	set txt1 "$which '[file tail $fileName]' already exists in\r\r"
	set txt2 "Do you want to replace it?\r"
	set dialogScript [list dialog::make \
	  -title "Modifying AlphaTcl File" \
	  -width 450 \
	  -ok "Continue" \
	  -addbuttons [list \
	  "Open Support File" \
	  "Click here to open the current Support Folder file." \
	  "set retCode 1 ; set retVal edit ; \
	  ::edit -c \{$newFile\}" \
	  ] \
	  [list "" \
	  [list "text" $txt1] \
	  [list [list "smallall" "text"] "$newDir\r\r"] \
	  [list "text" $txt2] \
	  ]]
	if {[catch {eval $dialogScript} result]} {
	    if {($result eq "edit")} {
		status::msg "The Support Folder version of the file\
		  has been opened."
		return
	    } else {
		error "Cancelled."
	    }
	}
    }
    # Now we copy the file to the new location.
    saveAs -f $newFile
    save
    status::msg "The active window is now a file in your Support Folder"
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::support::supportFoldersStatus" --
 # 
 # Display the current status of Support Folders, including the existence and
 # write-status of each one.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::support::supportFoldersStatus {} {
    
    global SUPPORT
    
    variable descriptions
    
    set domains [list]
    foreach domain [list "local" "user"] {
	if {($SUPPORT($domain) ne "")} {
	    lappend domains $domain
	}
    }
    set n1 [llength $domains]
    if {!$n1} {
	alertnote "No Support Folders are defined."
	return
    }
    set plural [expr {($n1 == 1)                 ? ""   : "s"}]
    set areIs  [expr {($n1 == 1)                 ? "is" : "are"}]
    set dots   [expr {([llength $domains] > 1)   ? "É"  : ""}]
    set dialogScript [list dialog::make -title "Support Folders Status" \
      -width 500 -cancel "" \
      -okhelptag "Click here to exit this dialog." \
      -addbuttons [list \
      "Help" \
      "Click here for more information about Support Folders." \
      "set retCode 0 ; set retVal return ; \
      help::openGeneral {Support Folders Help}" \
      "Show Folder$dots" \
      "Click here to display the Support Folder$plural in the Finder." \
      \
      "set retCode 0 ; set retVal return ; \
      alphadev::support::menuProc {} {Show Support Folder}" \
      ]]
    set dialogPane [list ""]
    lappend dialogPane [list "text" \
      "$n1 Support Folder$plural $areIs currently defined, in the\
      [join $domains " and "] domain${plural}.\r"] \
      [list "divider" "divider"]
    foreach domain $domains {
	set folder $SUPPORT($domain)
	set txt $descriptions($domain)
	if {![file exists $SUPPORT($domain)]} {
	    append txt "\rthe folder doesn't exist:\r"
	} else {
	    append txt "\r\"write\" permissions are " \
	      [expr {[file writable $folder] ? {} : "not "}] \
	      "available for:\r"
	}
	lappend dialogPane [list "text" $txt] \
	  [list [list "smallval" "text"] "$folder\r"] \
	  [list "divider" "divider"]
    }
    lappend dialogScript $dialogPane
    catch {eval $dialogScript}
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
# 01/05/06 cbu 0.1    Original.
# 01/10/06 cbu 0.2    SUPPORT variable always exists with both domains.
#                     Updated [alphadev::support::helpWindow] information.
#                     Corrected [alphadev::support::postBuildMenu] variables.
# 01/11/06 cbu 0.3    New "Support Folders Help" file.
#                     Enhanced "Save In Support Folder" when active window
#                       is an AlphaTcl file.
#                     SUPPORT/Tcl -> SUPPORT/AlphaTcl/Tcl
# 01/13/06 cbu 0.4    "Open AlphaTcl File" automatically copies chosen file
#                       to Support Folder, deletes it if necessary.
#                     New dummy "support" mode for registering window hooks.
#                     Updated dialogs, more information.
#                     "Open Support Folder File" opens windows read-only.
# 01/13/06 cbu 1.0b1  New "Config > Support Folders" prototype.
#                     [alphadev::support::openAlphaTclFile] accepts filename.
# 03/06/06 cbu 1.0b2  "Open AlphaTcl File" no longer automatically copies
#                       chosen file to Support Folder.
# 

# ===========================================================================
# 
# .