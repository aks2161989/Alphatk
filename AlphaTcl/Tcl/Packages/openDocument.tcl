## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "openDocument.tcl"
 #                                          created: 11/15/2004 {05:50:05 PM}
 #                                      last update: 05/25/2006 {10:54:44 AM}
 # Description:
 # 
 # Creates a new "File > Open" menu for opening files using methods provided
 # by other packages, and to easily set global "File > Open > Local File"
 # preferences.
 # 
 # All of the procedures in the "openDocument" namespace are private, and
 # should not be called by any other code.
 # 
 # All of the procedures in the "file" namespace could be useful for other
 # code, and could be placed in the "fileManipulation.tcl" file.
 #  
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #   
 # Copyright (c) 2004-2006  Craig Barton Upright, Joachim Kock
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # --------------------------------------------------------------------------
 # 
 # Notes:
 # 
 # This package serves four main purposes.
 # 
 # (1) It provides a method for users to open existing files, using any
 # criteria or method provided by other packages.  Any package can declare a
 # new type of open-file method to be added to the menu simply by adding to
 # the 'openDocTypes' array, as in
 # 
 #   array set openDocTypes [list "Open Fileset File" {file::openViaFileset}]
 # 
 # Modes can include such a statement in their [alpha::mode] initialization
 # argument if they want such an option to be available even if the mode has
 # not yet been loaded.
 # 
 # The submenu "File > Open" offers all of these options, plus some extras
 # that are defined by this package.
 # 
 # (2) It creates a User Interface to change the Current Working Directory, 
 # optionally instructing Alpha to change the directory to a specified 
 # folder during the application's launch.  Two menu items
 # 
 #   File > Open >     via Status Prompt      (status prompt method)
 #   File > Open > Current Directory Query    (quick search method)
 # 
 # allow the user to open a file from the Current Working Directory.
 # 
 # (3) Extending the idea of the "Current Directory Query" method even 
 # further, the user can create pre-defined matching criteria for repeated 
 # use via the menu item
 # 
 #   File > Open > Matching File Query
 # 
 # This routine was adapted from a code contribution from Joachim Koch.
 # 
 # (4) It provides an interface to the various "Open File" preferences, such
 # as "openPackages" and "showInvisibleFiles", which are normally set by
 # selecting "Config > Preferences > Input-Output Preferences > Files".  This
 # can be a bit cumbersome if the user wants to switch back and forth amongst
 # these options for whatever reason.  These preferences are all presented in
 # the "File > Open" menu as toggleable items.
 # 
 # See the help text below for more information.
 # 
 # ==========================================================================
 ##

alpha::feature openDocument 1.2.1 "global-only" {
    # Initialization script.  We don't put much in here in case some code is
    # calling [file::openDocument] without this package being activated.
    openDocument.tcl
} {
    # Activation script.
    openDocument::activatePackage 1
} {
    # De-activation script.
    openDocument::activatePackage 0
} uninstall {
    this-file
} preinit {
    # Contextual Menu module.  Doesn't require this package to be formally
    # turned on by the user.
    
    # Includes all "Open Document" items registered by other AlphaTcl 
    # packages, as well as utilities to quickly search directories and 
    # pre-defined filesets to locate a file for editing
    newPref flag openDocumentMenu 0 contextualMenu
    menu::buildProc "openDocument" {openDocument::buildMenu "1"} \
      {openDocument::postBuildMenu "1"}
    # Place this item in the first section.
    ;namespace eval contextualMenu {
	variable menuSections
	lappend menuSections(1) "openDocumentMenu"
    }
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Offers a variety of 'Open Document' options for window creation
} help {
    This package offers a variety of 'Open Document' options for opening
    various types of files.
    
    Preferences: Features
    
    The "File > Open" menu item is replaced by a submenu of the same name.
    It contains commands to open a file via the status bar prompt, and to
    quickly search through a hierarchy of files for a given file pattern.
    

	  	Table Of Contents

    "# Introduction"
    "# The 'File Open' Menu"
    "# Open Via Status Prompt"
    "# File Matching Queries"
    "# Current Working Directory"
    "# Open Document Preferences"
    "# Contextual Menu Module"
    
    <<floatNamedMarks>>


	  	Introduction

    Several different Alpha menus and features attempt to make it easier for
    you to quickly locate and open a file that you wish to edit.  There are
    many different methods for doing so: by collecting a list files in
    "filesets", by remembering recent files or directories, by assigning
    keyboard shortcuts to open favorite files, etc.  You aren't expected to
    learn and use all of these methods, as each user's style is somewhat
    different.  One of Alpha's goals is to provide with with a variety of
    tools from which you can choose to make your editing sessions easier.
    
    Related packages include
    
    package: favoritesMenu
    package: filesetsMenu
    package: ftpMenu
    package: recentDirsMenu
    package: recentFilesMenu
    package: recentFilesMultiMenu
    
    This particular package collects several of these methods, and replaces
    the "File > Open" command with a submenu of the same name.  If you want
    to give this package a try, click here <<openDocument::testPackage 1>> to
    temporarily turn on this feature.  It will be turned off the next time
    that you restart Alpha.  (Click here <<openDocument::testPackage 0>> to
    restore the previous "File > Open" menu item.)
    

	  	The 'File Open' Menu

    The new "File > Open" menu includes all of the possible "Open Document"
    options that have been registered by other AlphaTcl packages (such as
    from a remote site or via a pre-defined fileset.)  You can select any of
    them to evaluate the associated script.
    
    Click some of these hyperlinks for an example:
    
    <<openDocument::menuProc "" "Open Local File">>
    <<openDocument::menuProc "" "Open Remote File">>
    <<openDocument::menuProc "" "Open Fileset File">>
    
    Selecting the "File > Open > Local File" menu item presents a dialog that
    looks like <<findFile>> which uses the "# Open Document Preferences"
    described below to present a list of editable files.
    
    
	  	Open Via Status Prompt
    
    The menu command "File > Open > via Status Prompt" allows you to type in
    the name of the file that you're looking for.  The initial path is always
    the "Current Working Directory" which you are able to change at any time.
    (See the "# Current Working Directory" section below for more
    information.)  While you are typing the name of the file, you can ...
    
    Press Tab to complete the path.  If there is only one completion
    available, it will be added to the path automatically, otherwise all
    possible options will be offered in a list-pick dialog.  If the current
    path ends with a file separator, all files and folders within that folder
    will be offered.  If you select a file rather than a directory, that file
    will be opened immediately.  If you cancel the list-pick dialog, you'll
    still have the option to edit the path you've entered.
    
    Press Return to open the file designated by the current path.  If the
    path is incomplete and there is only one possible option, this file is
    opened automatically, otherwise all possible file options will be offered
    in a list-pick dialog.
    
    Press Escape or any of the Arrow Navigation keys to abort the prompt.
    
    Type "../" to move one level higher.
    
    Tip: You can use the "File > Open > Current Directory" menu to change the
    Current Working Directory.  If you enjoy entering commands in the status
    prompt, you can also press Escape-X and type "pwd" followed by Return to
    display the Current Working Directory in the status bar, or you can type
    "cd <directory>" to change the directory.
    
    Tip: If the current path ends with a file separator, typing that key
    again will also trigger a list-pick completion dialog.  So if the current
    directory is too low in your hierarchy, you can type "..//" to get a
    list-pick with the contents one level up.  The one thing you cannot do is
    press Delete to remove the text of the initial directory.
    
    
	  	File Matching Queries
    
    The middle section of the "File > Open" menu includes options for
    searching any local path hierarchy to find a matching file.  For example,
    if you want to open a .tex file in your "Dissertation" folder whose name
    includes "draft-1-1", you can select "File > Open > Matching File Query"
    and be presented with a dialog that looks like
    
    <<openDocument::openMatchingFile>>
    
    and fill in the appropriate values, as in
    
	draft-1-1
	.tex
	/Documents/Dissertation
    
    Alpha will then recursively search through the specified "Search Path"
    and locate any matching files.  If only one file matches the criteria,
    then it is opened automatically.  If there are several options, they will
    be presented in a list-pick dialog, and you can choose one (or more) of
    the files that you want to open.  The values that you enter will be saved
    and used as the next defaults when this menu item is called in the
    future, and saved between editing sessions.  If you don't know the exact
    name of the folder to search, you can press the "Browse Path" button to
    browse a file-system "Find Folder" dialog, or select an option from the
    "# Current Working Directory" list.
    
    The "File > Open > Fileset Query" is very similar, but in this case you
    simply select the name of a pre-defined fileset to specify which files
    will be queried.  For more information about creating filesets, see the
    "Filesets Help" file.
    
    Tip: the "File name pattern" doesn't have to include the full name of the
    file you're looking for, or even the proper start of its name.  For
    example, the pattern
    
	notes

    in your Dissertation folder could match all of
    
	/Documents/Dissertation/write-up/chapter1/chapter1-notes.txt
	/Documents/Dissertation/write-up/chapter4/chapter4-notes.txt
	/Documents/Dissertation/misc/notesToSort.txt
	/Documents/Dissertation/misc/oldNotes.txt
    
    Case sensitivity for these patterns is dependent upon your OS; in the
    MacOS the file "Readme" is the same as "readme" and README".
    
    You can also create some "Pre-Set File Matching Queries" and assign them
    unique Keyboard Shortcuts.  When these items are selected, a dialog will
    appear asking you for a file pattern to search for.  All pre-set queries
    are saved between editing sessions, and you can edit, rename, or delete
    them by selecting "File > Open > Pre-Set File Queries" menu commands.
    
    <<openDocument::addFMItem>>
    
    Here's an example, one that AlphaTcl developers might find useful:

	AlphaTcl
	/Applications/Alpha/
	.tcl
	Command-F1
    
    Tip: If you have several pre-set Matching File Queries set up, you might
    find it cumbersome to assign (and remember) a unique Keyboard Shortcut
    for each one.  The "File > Open > Open Pre-Set Query" menu item will
    present all of them in a list-pick dialog for you to choose from, and you
    could just assign one shortcut to this menu command.
    
    The "File > Open > List Local Files" has a similar dialog, but will
    present all results in a new window.
    
    <<openDocument::listMatchingFiles>>
    
    This dialog allows you to specify that the search string is the complete
    name of the file you're looking for, or the start, middle, or end.
    
    You'll notice that in both of these dialogs there is a text field named
    "Patterns to ignore" -- this should contain a list of any strings that
    you do not want included in the results.  These must follow the syntax
    found in the "Alpha Manual # File Patterns" section.  This field should
    contain a list of items, each separated by a space.  These patterns will
    apply to the full file path, including parent directories.
    
    One such pattern might be
    
   	*~
    
    to ignore backup files created by Alpha.  These patterns are _not_ case
    sensitive, so "*bak" will ignore a file named "text.BAK" .
    
    
	  	Current Working Directory
    
    Alpha maintains a "Current Working Directory" that can be used as a
    default location for locating files.  This is the path returned by the
    Tcl command: pwd , and is set by the command: cd .  Using the menu
    command "File > Open > Current Directory > Set Default Directory" you set
    the initial working directory to be set whenever ÇALPHAÈ is launched.
    
    The "File > Open > Current Directory > Set Working Directory" command
    opens a dialog to select and set the working directory to any existing
    local folder.  (You can also use the "File > Open > Current Directory"
    menu to change the current working directory to any recent folder you
    have used.)  The list of saved working directories is used in the pop-up
    menus in several Open Document dialogs, allowing you to quickly choose
    from your most commonly used file hierarchies.
    
    Once the Current Working Directory has been set, select the menu command
    "File > Open > via Status Prompt" to open a status bar prompt into which
    you can type the path of a file relative to this directory.
    
    
	  	Open Document Preferences
    
    There are several global preferences that affect how items are presented
    in the standard "File > Open" dialog, such as invisible files, package
    contents, etc.  These preferences are specific to the platform that you
    are using, and the "Config > Preferences > Input-Output Prefs > Files"
    menu item allows you to change them.
     
    Preferences: Files
    
    The "File > Open > Open Document Prefs" menu lists the "flag" preferences
    as toggleable menu items, allowing you ro change them "on the fly" as
    your needs change.
    
    The "File > Open > Open Document Shortcuts" menu item allows to add or
    change any of the default shortcuts associated with these menu items.

	----------------------------------------------------------------

	  	Contextual Menu Module
    
    A Contextual Menu "Open Document" module is also available which provides
    a submenu with all Open Document options.
    
    Preferences: ContextualMenu
    
    It is not necessary to formally turn on this package in order to have
    access to this CM module.
}

proc openDocument.tcl {} {}

# ===========================================================================
# 
# ×××× Preferences, Variables ×××× #
# 

# We keep all of this stuff in here so that 'file::openDocument' won't fail
# even if this package hasn't been activated.

namespace eval openDocument {
    
    # Used in [openDocument::activatePackage] and [openDocument::testPackage]
    # to keep track of our menu manipulations.
    variable activated
    if {![info exists activated]} {
	set activated "-1"
    }
    
    # Help tags used in various dialogs.
    variable helpTags
    array set helpTags [list \
      "searchPath" \
      "The full path of the directory to recursively search for files" \
      "pattern" \
      "The list of found files will be restricted to files that match\
      this \"file pattern\" extension." \
      "extension" \
      "If non-empty, the search will be restricted to files that match\
      this \"file pattern\" extension." \
      "ignorePats" \
      "No files matching these patterns will be included in the found list.\
      Each pattern should be separated by a space." \
      ]
    
    # Define menus.
    menu::buildProc "Open" {openDocument::buildMenu "0"} \
      {openDocument::postBuildMenu "0"}
    menu::buildProc "Current Directory" {openDocument::buildCDMenu} \
      {openDocument::postBuildCDMenu}
    
    # This is the list of top-level item names.
    variable defaultOptions [list \
      "Open Local File" \
      "    via Status Prompt" \
      "Current Directory Query" \
      "List Local Files" \
      "Matching File Query" \
      "Fileset Query" \
      "Open Pre-Set Query" \
      ]
    set allDefaults [concat $defaultOptions [list]]
    # These are default shortcuts.
    variable shortcuts
    foreach itemName $allDefaults {
	if {![info exists shortcuts($itemName)]} {
	    switch -- $itemName {
		"Matching File Query" {
		    set shortcuts($itemName) "<U<O/M"
		}
		"Open Local File" {
		    set shortcuts($itemName) "<O/O"
		}
		"    via Status Prompt" {
		    set shortcuts($itemName) "<U<O/O"
		}
	    }
	}
    }
    # These are legacy shortcuts.
    foreach itemName [list "Open Remote File" "Open Fileset File"] {
	if {![info exists shortcuts($itemName)]} {
	    switch -- $itemName {
		"Open Remote File" {
		    set shortcuts($itemName) "<B<O/O"
		}
		"Open Fileset File" {
		    set shortcuts($itemName) "<I<O/O"
		}
	    }
	}
    }
    unset itemName
    
    # These options appear as toggleable items in the menu.
    variable toggleablePrefs
    array set toggleablePrefs [list \
      "Enable Non-Text Files"   "openAllFiles" \
      "Show Package Contents"   "openPackages" \
      "Show Invisible Files"    "showInvisibleFiles" \
      ]
    if {(${alpha::platform} eq "alpha")} {
	array set toggleablePrefs [list \
	  "Never Wrap On Open"  "neverWrapOnOpen" \
	  ]
    }
    
    # The "backupExtension" variable is used as a default "ignorePats" value.
    if {[info exists ::backupExtension]} {
	set backupExt $::backupExtension
    } else {
	set backupExt "~"
    }
    # These are used by [openDocument::listMatchingFiles].
    set items [list "criterion" "depth" "searchPath" "pattern" "ignorePats"]
    foreach item $items {
	variable lmfDefaults
	if {![info exists lmfDefaults($item)]} {
	    switch -- $item {
		"criterion" {
		    set lmfDefaults($item) "are"
		}
		"depth" {
		    set lmfDefaults($item) "3"
		}
		"searchPath" {
		    set lmfDefaults($item) [pwd]
		}
		"ignorePats" {
		    set lmfDefaults($item) [list "*$backupExt"]
		}
		default {
		    set lmfDefaults($item) ""
		}
	    }
	}
    }
    prefs::modified lmfDefaults
    unset items item
    
    # This is used by "File > Open > Matching File Query".
    variable fileMatcherQueries
    if {![info exists fileMatcherQueries(omfDefaults)]} {
	set fileMatcherQueries(omfDefaults) [list [pwd] "" "" "*$backupExt"]
    }
    prefs::modified fileMatcherQueries(omfDefaults)
    if {![info exists fileMatcherQueries(filesetMatch)]} {
	set fileMatcherQueries(filesetMatch) [list "" "" "" "*$backupExt"]
    }
    prefs::modified fileMatcherQueries(filesetMatch)
    # This is now obsolete.
    if {[info exists fileMatcherQueries(wdMatch)]} {
	prefs::modified fileMatcherQueries(wdMatch)
	unset fileMatcherQueries(wdMatch)
    }
}

# This line could/should be moved into the "filesetsMenu.tcl" package.
if {![info exists "openDocTypes(Fileset File)"]} {
    array set openDocTypes [list "Open Fileset File" {::file::openViaFileset}]
}
# This line could/should be moved into the "ftpMenu.tcl" package.
if {![info exists "openDocTypes(Remote File)"]} {
    array set openDocTypes [list "Open Remote File" {::file::openRemote}]
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::activatePackage" --  activate
 # 
 # This procedure makes it easier to make changes to the activation sequence
 # without requiring a full rebuilding of AlphaTcl package indices.  We try
 # to keep the activity here to a minimum so that the CM module will work
 # even if this package has not been formally turned on by the user.
 # 
 # At present, the "alpha::guiNotReady" check is a hacky workaround at which
 # Vince will cringe.  The goal here is to avoid removing menu items until
 # other packages (such as "filesets") have had a chance to add them.  If we
 # are being activated after startup, then this isn't an issue.  If this
 # package was part of the standard distribution, we could adjust the menu
 # building in "alphaMenus.tcl" to avoid this issue, and ensure that no other
 # package is attempting to add menu items based on the presence of the
 # "openViaFileset" or "openRemote" items.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::activatePackage {activate} {
    
    global alpha::guiNotReady flagPrefs varPrefs \
      setWorkingDirectoryOnStart initialWorkingDirectoryFolder
    
    variable activated
    
    if {$activated eq "-1"} {
	# Turn this item on to remember and reset the "Current Working Directory"
	# to the value below when Alpha is restarted.
	newPref flag "setWorkingDirectoryOnStart" 0 "global"
	# This is the Current Working Directory that will be set when Alpha is
	# launched if the preference for "Set Working Directory On Start" is
	# turned on
	newPref folder "initialWorkingDirectoryFolder" [pwd] "global" \
	  {openDocument::setWorkingDirectory}
	
	lunion flagPrefs(Files) "setWorkingDirectoryOnStart"
	lunion varPrefs(Files)  "initialWorkingDirectoryFolder"
	
	if {$setWorkingDirectoryOnStart} {
	    cd $initialWorkingDirectoryFolder
	}
    }
    
    if {($activate == $activated)} {
	return
    } elseif {$activate} {
	# This is our main replacement.
	menu::replaceWith File "/OopenÉ" submenu "Open"
	if {[info exists alpha::guiNotReady] && ${alpha::guiNotReady}} {
	    hook::register startupHook {
		# This item is now included in our menu.
		menu::replaceWith File "<E<B<O/OopenRemoteÉ" items
		# This was added by the package: filesetMenu
		menu::uninsert File items "<E<B<O/OopenRemoteÉ" \
		  "<S<I<O/OopenViaFilesetÉ"
	    }
	} else {
	    # This item is now included in our menu.
	    menu::replaceWith File "<E<B<O/OopenRemoteÉ" items
	    # This was added by the package: filesetMenu
	    menu::uninsert File items "<E<B<O/OopenRemoteÉ" \
	      "<S<I<O/OopenViaFilesetÉ"
	}
	# Redefine [cd] so that our "File > Open > Current Directory" menu 
	# is always updated.
	hook::procRename "::cd" "::openDocument::newCD"
    } else {
	menu::removeFrom  File "/OopenÉ" submenu "Open"
	menu::removeFrom  File "<E<B<O/OopenRemoteÉ" items
	menu::insert   File items "<E<B<O/OopenRemoteÉ" \
	  "<S<I<O/OopenViaFilesetÉ"
	# Restore [cd].
	hook::procRevert "::openDocument::newCD"
    }
    set activated $activate
    return
}

##
 # -------------------------------------------------------------------------
 #
 # "openDocument::testPackage" --  activate
 #
 # A useful little proc to test out the feature.  This should only be called
 # from a hyperlink in this package's help window.
 #
 # -------------------------------------------------------------------------
 ##

proc openDocument::testPackage {activate} {
    
    variable activated
    
    set msg "The 'Open Document' package has "
    if {$activate == $activated} {
	append msg "already been turned [expr {$activated ? on : off}]."
    } else {
	openDocument::activatePackage $activate
	if {$activate} {
	    append msg "been temporarily activated.\
	      You can now test any of the new commands\
	      found in the \"File > Open\" menu."
	} else {
	    append msg "been turned off.\r\r(Thanks for testing it!)"
	}
    }
    alertnote $msg
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::addOpenItem" --  ?args?
 # 
 # Now that we've defined all of the "openDocTypes" entries, we'll ensure that
 # any additional ones trigger rebuilding of the submenu.  (Most of the
 # "openDocTypes" entries are added during mode/package "preinit" scripts, so
 # they will be declared before this file is sourced.)
 # 
 # --------------------------------------------------------------------------
 ##

trace add variable openDocTypes {array write unset} \
  {::openDocument::addOpenItem}

proc openDocument::addOpenItem {args} {
    openDocument::rebuildMenu
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::listItems" --  which ?addEllipses 0?
 # 
 # Return a listing for Open Document (OD) or File Matching (FM) items that
 # have been added for inclusion in the "File > Open" menu.
 # 
 # (OD) AlphaTcl packages might register the open types used by this package
 # naming then "Open <something>".  This makes less sense given how they are
 # presented to the user, so this proc strips that off and sorts the list.
 # 
 # (FM) We want to explicitly ignore the "omfDefaults" item, since that
 # cannot be edited by the user.
 # 
 # (WD) All saved "working directories" used to create the menu.
 # 
 # (CD) Same as above, but also ensures that the Current Working Directory is
 # included in the list.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::listItems {which {addEllipses 0}} {
    
    switch -- $which {
	"OD" {
	    global [set varName "openDocTypes"]
	}
	"FM" {
	    variable [set varName "fileMatcherQueries"]
	}
	"CD" - "WD" {
	    variable [set varName "workingDirs"]
	}
	default {
	    error "Unknown listing type: $which"
	}
    }
    set itemList [list]
    foreach itemName [array names $varName] {
	if {($itemName eq "omfDefaults") || ($itemName eq "filesetMatch")} {
	    continue
	} elseif {($which eq "WD")} {
	    set itemName [lindex [array get $varName $itemName] 1]
	}
	if {($which eq "WD") || ($which eq "CD")} {
	    set itemName [openDocument::massageName $itemName]
	}
	if {$addEllipses} {
	    append itemName "É"
	}
	lappend itemList $itemName
    }
    if {($which eq "CD")} {
	lappend itemList [openDocument::massageName [pwd]]
    }
    return [lsort -unique -dictionary $itemList]
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::massageName" --  dirName ?addTrailingSeparator 0?
 # 
 # Ensure that the given directory name includes or omits the trailing file 
 # separator.  Useful for creating consistent menus, and allows us to store 
 # names using whatever the file system likes without worrying about it.
 # 
 # The "addTrailingSeparator" variable determines how items are presented in
 # the menu.  Note: I've run into weird startup bugs with AlphaX 8.0 when
 # this is turned on.  You run into a series of "problem rebuilding menu"
 # dialogs, even though the menu is properly built.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::massageName {dirName {addTrailingSeparator 0}} {
    
    set dirName  [eval [list file join] [file split $dirName]]
    set fsLength [string length [file separator]]
    set fsIndex  [expr {[string length $dirName] - $fsLength}]
    if {([string range $dirName $fsIndex end] eq [file separator])} {
	set dirName [string range $dirName 0 [expr {$fsIndex - 1}]]
    }
    if {$addTrailingSeparator || ($dirName eq "")} {
	append dirName [file separator]
    }
    return $dirName
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× "File > Open" menu, support ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "openDocument::buildMenu" --  ?forCMenu 0?
 # 
 # Build the "File > Open" submenu, as well as the "Open Document" CM menu.
 # The argument "forCMenu" distinguishes that this is being built for the
 # Contextual Menu versus the File menu, and determines whether we add the
 # Keyboard Shortcuts or not.  (It's possible that the CM module is activated
 # even though these feature has not been, so the Keyboard Shortcuts wouldn't
 # actually work, and are distracting in the CM no matter what.)
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::buildMenu {{forCMenu "0"}} {
    
    variable fileMatcherQueries
    variable shortcuts
    variable toggleablePrefs
    variable workingDirs
    
    # (1) Start the list with default options and other registered items.
    set menuList [list "Open Local FileÉ" "    via Status PromptÉ"]
    eval [list lappend menuList] [openDocument::listItems "OD" 1] \
      [list "List Local FilesÉ"]
    # (2) Add "File Matching" commands.
    lappend menuList "(-)" "Matching File QueryÉ" "Fileset QueryÉ"
    # Add the "Pre-Set File Queries".
    eval [list lappend menuList] [openDocument::listItems "FM" 1]
    lappend menuList "Open Pre-Set QueryÉ"
    # (3) Add utility items.
    foreach utilItem [list "Add" "Edit" "Rename" "Delete"] {
	lappend presetUtils "$utilItem File Match Query ItemÉ"
    }
    lappend menuList "(-)" "Menu -m -n {Pre-Set File Queries} \
      -p {openDocument::menuProc} \"${presetUtils}\"" \
      "Menu -m -n {Current Directory} -c \
      -p {openDocument::menuProc} {}"
    # Add toggleable preferences.
    set prefsList [list]
    foreach itemName [lsort -dictionary [array names toggleablePrefs]] {
	if {[info exists ::$toggleablePrefs($itemName)]} {
	    lappend prefsList $itemName
	}
    }
    if {[llength $prefsList]} {
	lappend prefsList "(-)" "More File PreferencesÉ"
	lappend menuList "Menu -m -n {Open Document Prefs} \
	  -p {openDocument::menuProc} \"${prefsList}\""
    } else {
	lappend menuList "Open Document PrefsÉ"
    }
    # Add some package utility/preference items.
    lappend menuList "Open Document ShortcutsÉ" \
      "Open Document Help"
    if {$forCMenu} {
	set menuList [lreplace $menuList end-1 end-1]
    } else {
	set menuList [openDocument::addMenuShortcuts $menuList]
    }
    # These are additional menus that must be built.
    set subMenus [list "Current Directory"]
    
    return [list build $menuList {openDocument::menuProc -m} $subMenus]
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::addMenuShortcuts" --  menuList
 # 
 # Add any user-defined Keyboard Shortcuts for the items in the menu list
 # that has been constructed.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::addMenuShortcuts {menuList} {
    
    variable fileMatcherQueries
    variable shortcuts
    
    set newList [list]
    foreach itemName $menuList {
	if {([string range $itemName 0 10] eq "Menu -m -n ")} {
	    lappend newList $itemName
	    continue
	}
	regexp {^([^É]+)(É)?$} $itemName -> itemName ellipses
	if {[info exists shortcuts($itemName)]} {
	    set shortcut $shortcuts($itemName)
	} elseif {[info exists fileMatcherQueries($itemName)]} {
	    set shortcut [lindex $fileMatcherQueries($itemName) 4]
	} else {
	    set shortcut ""
	}
	lappend newList ${shortcut}${itemName}${ellipses}
    }
    return $newList
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::postBuildMenu" --  ?forCMenu?
 # 
 # Mark the toggleable preferences with "Ã" to indicate their current value.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::postBuildMenu {{forCMenu "0"}} {
    
    variable toggleablePrefs
    
    if {!$forCMenu} {
	set menuName "Open"
    } else {
	set menuName "openDocument"
    }
    # Pre-Set File Match Utility items.
    set dim [expr {([openDocument::listItems "FM"] > 0) ? 1 : 0}]
    foreach utilItem [list "Edit" "Rename" "Delete"] {
	set menuItem "$utilItem File Match Query ItemÉ"
	enableMenuItem -m "Pre-Set File Queries" $menuItem $dim
    }
    enableMenuItem -m $menuName "Open Pre-Set QueryÉ" $dim
    # Toggleable preferences.
    foreach itemName [array names toggleablePrefs] {
	if {![info exists ::$toggleablePrefs($itemName)]} {
	    continue
	}
	set prefValue [set ::$toggleablePrefs($itemName)]
	markMenuItem -m "Open Document Prefs" $itemName $prefValue "Ã"
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::postBuildMenu" --  ?args?
 # 
 # This is a simple shortcut to rebuild the "File > Open" menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::rebuildMenu {args} {
    
    menu::buildSome "Open"
    if {[llength $args]} {
	status::msg "The \"File > Open\" menu has been rebuilt."
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::menuProc" --  menuName itemName
 # 
 # Deal with any utility items or toggleable preferences as necessary, or
 # evaluate any pre-defined scripts if the Open Document Type is recognized.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::menuProc {menuName itemName} {
    
    global openDocTypes
    
    variable fileMatcherQueries
    variable lastOPSQ
    variable toggleablePrefs
    variable workingDirs
    
    if {[info exists fileMatcherQueries($itemName)]} {
	openDocument::openMatchingFile $itemName
	return
    }
    switch -- $menuName {
	"Pre-Set File Queries" {
	    regexp {^(\w+)} $itemName -> which
	    set which [string tolower $which]
	    openDocument::${which}FMItem
	}
	"Open Document Prefs" {
	    if {[info exists toggleablePrefs($itemName)]} {
		set prefName $toggleablePrefs($itemName)
		set newValue [expr {1 - [set ::$prefName]}]
		set ::$prefName $newValue
		prefs::modified ::$prefName
		status::msg "The \"${itemName}\" preference is now turned\
		  [expr {$newValue ? "on" : "off"}]."
		openDocument::postBuildMenu
	    } elseif {($itemName eq "More File Preferences")} {
		prefs::dialogs::globalPrefs "Files"
	    } else {
		error "Unknown menu item: $itemName"
	    }
	}
	"Current Directory" {
	    openDocument::cdMenuProc $menuName $itemName
	}
	default {
	    switch -- $itemName {
		"Fileset Query" {
		    openDocument::openFilesetMatch
		}
		"List Local Files" {
		    openDocument::listMatchingFiles
		}
		"Matching File Query" {
		    openDocument::openMatchingFile
		}
		"Open Document Help" {
		    package::helpWindow "openDocument"
		}
		"Open Document Prefs" {
		    prefs::dialogs::globalPrefs "Files"
		}
		"Open Document Shortcuts" {
		    openDocument::assignShortcuts
		}
		"Open Local File" - "" {
		    findFile
		}
		"Open Pre-Set Query" {
		    set p "Open which pre-set query?"
		    set options [openDocument::listItems "FM"]
		    switch -- [llength $options] {
			0 {
			    error "Cancelled -- \
			      there are no pre-set query items."
			}
			1 {
			    set query [lindex $options 0]
			}
			default {
			    if {![info exists lastOPSQ] \
			      || ([lsearch $options $lastOPSQ] == -1)} {
				set L [lrange $options 0 0]
			    } else {
				set L [list $lastOPSQ]
			    }
			    set query [listpick -p $p -L $L $options]
			}
		    }
		    set lastOPSQ $query
		    openDocument::openMatchingFile $query
		}
		"    via Status Prompt" {
		    file::openViaStatusPrompt [pwd]
		}
		default {
		    set options [list $itemName "${itemName}É" \
		      "Open $itemName" "Open ${itemName}É"]
		    foreach option $options {
			if {[info exists openDocTypes($option)]} {
			    set script $openDocTypes($option)
			    break
			}
		    }
		    if {[info exists script]} {
			return [eval $script]
		    } else {
			status::msg "Sorry, no script is associated with\
			  the menu item \"${itemName}\""
		    }
		}
	    }
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::assignShortcuts" --
 # 
 # Create a dialog that allows the user to assign/remove Keyboard Shortcuts
 # that will appear in the "File > Open" submenu.  All settings are saved
 # between editing sessions.  (Note: if the use selects "no binding" we don't
 # unset the previous shortcut, just set it to the null string to that we
 # don't reset it to the default during the [namespace eval openDocument]
 # call the next time that this file is sourced.)
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::assignShortcuts {} {
    
    variable defaultOptions
    variable fileMatcherQueries
    variable shortcuts
    
    # We first add the top level items.
    foreach itemName $defaultOptions {
	if {[info exists shortcuts($itemName)]} {
	    set newShortcuts($itemName) $shortcuts($itemName)
	} else {
	    set newShortcuts($itemName) ""
	}
	set oldShortcuts($itemName) $newShortcuts($itemName)
    }
    # Now add all user-defined shortcuts.
    foreach itemName [openDocument::listItems "OD"] {
	if {[info exists shortcuts($itemName)]} {
	    set newShortcuts($itemName) $shortcuts($itemName)
	} else {
	    set newShortcuts($itemName) ""
	}
	set oldShortcuts($itemName) $newShortcuts($itemName)
    }
    # Now add all "File Matching" items.
    foreach itemName [openDocument::listItems "FM"] {
	set newShortcuts($itemName) [lindex $fileMatcherQueries($itemName) 4]
	set oldShortcuts($itemName) $newShortcuts($itemName)
    }
    # Present the dialog.
    set title "Open Document Keyboard Shortcuts É"
    dialog::arrayBindings $title newShortcuts 1
    # Change the shortcuts.
    set changed 0
    foreach itemName [array names newShortcuts] {
	if {($newShortcuts($itemName) eq $oldShortcuts($itemName))} {
	    continue
	} elseif {[info exists fileMatcherQueries($itemName)]} {
	    set mfItems $fileMatcherQueries($itemName)
	    set mfItems [lreplace $mfItems 3 3 $newShortcuts($itemName)]
	    array set fileMatcherQueries [list $itemName $mfItems]
	    prefs::modified fileMatcherQueries($itemName)
	} else {
	    set shortcuts($itemName) $newShortcuts($itemName)
	    prefs::modified shortcuts($itemName)
	}
	incr changed
    }
    set FO {"File > Open"}
    if {!$changed} {
	status::msg "No $FO Keyboard Shortcuts have been changed."
    } elseif {($changed == 1)} {
	openDocument::rebuildMenu
	status::msg "The new $FO Keyboard Shortcut has been assigned."
    } else {
	openDocument::rebuildMenu
	status::msg "The new $FO Keyboard Shortcuts have been assigned."
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Current Working Directory ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "openDocument::buildCDMenu" --
 # 
 # Build the "File > Open > Current Directory" submenu.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::buildCDMenu {} {
    
    variable workingDirs
    
    # Add the "Current Directory" menu.
    set menuList [list]
    # Ensure consistent use of trailing (or not) file separator.
    set menuList [openDocument::listItems "CD"]
    lappend menuList "(-)"  "Set Current DirectoryÉ" "Set Default DirectoryÉ" \
      "Delete Directory Menu ItemÉ"
    # This seems redundant to "Set WD" : "Add Directory Menu ItemÉ" 
    return [list build $menuList {openDocument::cdMenuProc -m -c}]
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::postBuildCDMenu" --
 # 
 # Mark the Current Directory in the menu with a bullet.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::postBuildCDMenu {} {
    
    set dim [expr {([llength [openDocument::listItems "WD"]] > 0) ? 1 : 0}]
    enableMenuItem -m "Current Directory" "Delete Directory Menu ItemÉ" $dim
    set cwd [openDocument::massageName [pwd]]
    foreach dir [openDocument::listItems "CD"] {
	set mark [expr {($cwd eq $dir) ? 1 : 0}]
	catch {markMenuItem -m "Current Directory" $dir $mark "¥"}
	if {![file isdir $dir]} {
	    catch {enableMenuItem -m "Current Directory" $dir 0}
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::cdMenuProc" --  menuName itemName
 # 
 # Set the Current Working Directory, or manipulate the list of items 
 # included in the menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::cdMenuProc {menuName itemName} {
    
    variable workingDirs
    
    switch -- $itemName {
	"Add Directory Menu ItemÉ" {
	    openDocument::addWorkingDirectory
	}
	"Delete Directory Menu ItemÉ" {
	    set delDirs [list]
	    set dirOptions [lsort -unique -dictionary \
	      [array names workingDirs]]
	    switch -- [llength $dirOptions] {
		"0" {
		    error "Cancelled -- there are no saved directories\
		      to delete."
		}
		"1" {
		    set q "Do you want to remove\
		      \r\r[lindex $dirOptions 0]\
		      \r\rfrom the menu of \
		      possible working directories?"
		    if {[askyesno $q]} {
			set delDirs $dirOptions
		    } else {
			error "cancel"
		    }
		}
		default {
		    if {([lsearch $dirOptions [pwd]] > -1)} {
			set L [pwd]
		    } else {
			set L [lindex $dirOptions 0]
		    }
		    set p "Select directories to remove from the menu:"
		    set delDirs [listpick -p $p -L $L -l $dirOptions]
		}
	    }
	    foreach dir $delDirs {
		if {[info exists workingDirs($dir)]} {
		    prefs::modified workingDirs($dir)
		    unset workingDirs($dir)
		}
	    }
	    menu::buildSome "Current Directory"
	    status::msg "The \"Current Directory\" menu has been rebuilt."
	}
	"Set Current DirectoryÉ" {
	    openDocument::setWorkingDirectory
	}
	"Set Default DirectoryÉ" {
	    openDocument::setDefaultDirectory
	}
	default {
	    if {[file isdir $itemName]} {
		cd $itemName
		openDocument::postBuildCDMenu
		status::msg "The Current Directory is \"$itemName\""
	    } else {
		openDocument::postBuildCDMenu
		error "Cancelled -- the directory \"$itemName\"\
		  doesn't exist."
	    }
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::addWorkingDirectory" --
 # 
 # Allow the user to add a new Working Directory to the list, without 
 # actually changing the Current Working Directory.  After adding one, the 
 # user is given the option to add another.  This is mainly used in button 
 # scripts of various dialogs.  This procedure will throw an error if the 
 # user presses "Cancel", so it should be caught when necessary.
 # 
 # Returns a list of all new directories added.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::addWorkingDirectory {} {
    
    variable workingDirs
    
    set newDirs [list]
    set p "Choose a directory"
    while {1} {
	set newDir [get_directory -p $p [pwd]]
	set workingDirs($newDir) \
	  [openDocument::massageName $newDir]
	prefs::modified workingDirs($newDir)
	menu::buildSome "Current Directory"
	set p "Choose another directory"
	set q "Would you like to add another directory?"
	if {[askyesno $q]} {
	    continue
	} else {
	    break
	}
    }
    status::msg "The \"Current Directory\" menu has been rebuilt."
    return $newDirs
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::setWorkingDirectory" --  ?args?
 # 
 # Allow the user to set the Current Working Directory, and offer the option
 # to remember this the next time that Alpha is launched.  If the "args" list
 # is non-empty, then this was called by a preferences dialog _after_ the
 # value has already been set.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::setWorkingDirectory {args} {
    
    global initialWorkingDirectoryFolder
    
    variable workingDirs
    
    set newDir ""
    if {![llength $args]} {
	# Called from the menu, the user wants to set the cwd.
	status::msg "The Current Working Directory is: [pwd]"
	cd [get_directory -p "Select a new Working Directory:" [pwd]]
	status::msg "The new working directory is: [pwd]"
	set newDir [pwd]
    } else {
	set newDir $initialWorkingDirectoryFolder
	if {[lindex $args 0] eq "initialWorkingDirectoryFolder"} {
	    set q "Would you like to set the Current Working Directory\
	      to\r\r${initialWorkingDirectoryFolder}\r\r?"
	    if {[askyesno $q]} {
		cd $initialWorkingDirectoryFolder
	    }
	}
    }
    # Always save this for inclusion in the "Current Directory" menu.
    if {($newDir ne "")} {
	set workingDirs($newDir) [openDocument::massageName $newDir]
	prefs::modified workingDirs($newDir)
	menu::buildSome "Current Directory"
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::setDefaultDirectory" --
 # 
 # Create a dialog that allows the user to set the default working directory,
 # and/or to tell Alpha to change to this directory when it is launched.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::setDefaultDirectory {} {
    
    global initialWorkingDirectoryFolder setWorkingDirectoryOnStart \
      alpha::application
    
    set newDir $initialWorkingDirectoryFolder
    set newSet $setWorkingDirectoryOnStart
    
    while {1} {
	set dirOption  "Use the path specified above, or select from list below"
	set dirOptions [concat [list $dirOption "-"] \
	  [openDocument::listItems "CD" 0] \
	  [list "-" "Add New Working DirectoryÉ"]]
	set dialogScript [list dialog::make \
	  -title "Set Default Directory" \
	  -width 575 \
	  -addbuttons [list \
	  "Help" \
	  "Click here for more information about the Current Directory." \
	  "help::openGeneral openDocument {The Current Directory} ; \
	  set retCode 1 ; set retVal {cancel}" \
	  "Browse PathsÉ" \
	  "Click here to use an OS dialog to locate a new directory." \
	  {catch {dialog::valSet $dial ",Search Path :" \
	  [get_directory -p {Select a new default folder :} \
	  [dialog::valGet $dial ",Directory :"]]}} \
	  ] \
	  [list "" \
	  [list "text" "You can set the initial working directory to any\
	  pre-existing folder.  Type in the path name, or press the \"Browse\"\
	  button to select it via a file system dialog.\r"] \
	  [list "var" "Directory :" $newDir \
	  "Enter the full path of the directory."] \
	  [list [list "menu" $dirOptions] "Options :" $dirOption \
	  "Use the above directory, or select one of your saved search paths"] \
	  [list "flag" "Always set the working directory to this folder\
	  when ${alpha::application} is launched.\r" $newSet] \
	  ]]
	set results   [eval $dialogScript]
	set newDir    [lindex $results 0]
	set dirOption [lindex $results 1]
	set newSet    [lindex $results 2]
	if {($dirOption eq "Add New Working DirectoryÉ")} {
	    catch {openDocument::addWorkingDirectory}
	} else {
	    break
	}
    }
    if {($dirOption ne [lindex $dirOptions 0])} {
	set newDir $dirOption
    }
    if {($newDir ne $initialWorkingDirectoryFolder)} {
	set initialWorkingDirectoryFolder $newDir
	prefs::modified initialWorkingDirectoryFolder
	set msg "New initial directory: $newDir"
	cd $newDir
    }
    if {($newSet ne $setWorkingDirectoryOnStart)} {
	set setWorkingDirectoryOnStart $newSet
	prefs::modified setWorkingDirectoryOnStart
	set msg "The initial working directory will\
	  [expr {$newSet ? "now" : "no longer"}]\
	  be set when ${alpha::application} is launched."
    }
    if {![info exists msg]} {
	set msg "No changes."
    }
    status::msg $msg
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::newCD" --  ?args?
 # 
 # A redefinition of [cd] that ensures that the "File > Current Directory"
 # menu is rebuilt after the direcotry has been changed.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::newCD {args} {
    
    set oldDir [pwd]
    eval [list hook::procOriginal "::openDocument::newCD"] $args
    set newDir [pwd]
    if {($oldDir ne $newDir)} {
	menu::buildSome "Current Directory"
    }
    return
}

# ===========================================================================
#
# ×××× ------------ ×××× #
# 
# ×××× File Matching Queries ×××× #
# 
# This section provides support for quickly searching a search path hierarchy
# for a given file pattern to edit in Alpha.  The main functionality is found
# in the procedure [openDocument::openMatchingFile].  When this is called
# with no arguments, we present a dialog that includes
# 
# (1) the initial search path
# (2) a file name matching pattern
# (3) any limiting file extension
# (4) a list of file patterns that should be ignored.
# 
# These values are stored between calls and saved between editing sessions to
# be used as defaults the next time the menu item is called, in a local array
# named "fileMatcherQueries" as the "omfDefaults" entry.  The fourth item,
# for "ignored patterns," applies only to the file tails, not to the parent
# directories.
# 
# We also provide support for the user to create pre-set file matching
# queries, saving them in the menu with user-defined keyboard shortcuts.
# When a menu item is chosen, we collect the necessary information and pass
# it on to [file::openViaPathExtension] to present a dialog then open the
# desired files.
# 
# All information is saved in the local "fileMatcherQueries" array, where the
# name of the array entry is the menu name, and the array entry value is a
# list containing
# 
# (1) the initial search path
# (2) the last file matching pattern used
# (3) any limiting file extension
# (4) a list of file patterns that should be ignored.
# (5) the keyboard shortcut for the menu
# 
# Item (2) is not initially supplied when the pre-set query item is created,
# but only added when the user actually selects an item from the menu to
# perform a search.  When we add new items, we use the "omfDefaults"
# information as the field defaults.  This way the user doesn't have to reset
# the same information several times.
# 
# Pre-set query items can then be edited, renamed, or deleted.  Whenever we
# manipulate a pre-set item, we also adjust the "omfDefaults" entry to
# reflect the contents of the one we last saw.
# 
# Inspired by a contribution from Joachim Kock.
# 

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::fmDialog" --  ?args?
 # 
 # Prompt for an Item Type if necessary, and then use any default values in
 # the "args" list to create the dialog.  If an Item Name has been supplied,
 # the user is not allowed to change that.  We go to a little bit of trouble
 # to ensure that there is an Item Name and a proper Location set.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::fmDialog {args} {
    
    variable helpTags
    
    set title      [lindex $args 0]
    set itemName   [lindex $args 1]
    set searchPath [lindex $args 2]
    set extension  [lindex $args 3]
    set ignorePats [lindex $args 4]
    set shortcut   [lindex $args 5]
    
    # Build the dialog page.
    set dialogPage [list ""]
    if {![regexp {^Edit} $title]} {
	lappend dialogPage [list "var" "Menu Item Name :" $itemName \
	  "The name of the item that will appear in the menu;\
	  this must be alpha-numeric"]
    } else {
	lappend dialogPage \
	  [list [list "menu" [list $itemName]] "Menu Item Name :" $itemName \
	  "This is the current name of the item;\
	  it cannot be changed in this dialog"]
    }
    lappend dialogPage \
      [list "folder" "Search Path :" $searchPath $helpTags(searchPath)] \
      [list "var" "Extension (optional) :" $extension $helpTags(extension)] \
      [list "var" "Patterns to ignore :" $ignorePats $helpTags(ignorePats)] \
      [list "menubinding" "Menu Shortcut :" $shortcut \
      "The keyboard shortcut that will appear in the menu"]
    # Add a "Help" button.
    set results [dialog::make -title $title \
      -addbuttons [list \
      "Help" \
      "Click here to open File Matcher help." \
      "help::openGeneral openDocument {File Matching} ; \
      set retCode 1 ; set retVal {cancel}" \
      "File PatternsÉ" \
      "Click here to open a dialog explaining file patterns." \
      "help::filePatternsHelpDialog"] $dialogPage]
    # Collect the new values, and ensure that they are valid.
    set itemName   [openDocument::verifyName [lindex $results 0]]
    set searchPath [lindex $results 1]
    set extension  [lindex $results 2]
    set ignorePats [lindex $results 3]
    set shortcut   [lindex $results 4]
    return [list $itemName $searchPath $extension $ignorePats $shortcut]
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::verifyName" --  menuName
 # 
 # Ensure that the menu name for the pre-set query is valid for insertion
 # into the "File > Open" menu.  We are fairly restrictive, only allowing
 # alpha-numeric characters and spaces.  Well, that's what we say, at least,
 # though we do allow non-leading "-" and spaces.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::verifyName {menuName} {
    
    while {![regexp {^[a-zA-Z0-9][-a-zA-Z0-9 ]*$} $menuName]} {
	alertnote "The menu name \"${menuName}\" is not valid --\
	  it must be alpha-numeric."
	set menuName [prompt "Choose another menu name:" $menuName]
    }
    return $menuName
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::addFMItem" --
 # 
 # Calls [openDocument::fmDialog], prompting the user to select an Item Type
 # and other relevant settings.  At the end we allow the user to run through
 # the routine again to add more pre-set query items.  All settings are saved
 # between Alpha editing sessions.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::addFMItem {} {
    
    variable fileMatcherQueries
    
    set results    [list]
    set title      "Create New Pre-Set File Matcher"
    set itemName   ""
    set searchPath [lindex $fileMatcherQueries(omfDefaults) 0]
    set filePat    [lindex $fileMatcherQueries(omfDefaults) 1]
    set extension  [lindex $fileMatcherQueries(omfDefaults) 2]
    set ignorePats [lindex $fileMatcherQueries(omfDefaults) 3]
    set shortcut   ""
    while {1} {
	# Call the dialog.
	set results [openDocument::fmDialog \
	  $title $itemName $searchPath $extension $ignorePats $shortcut]
	set itemName   [lindex $results 0]
	set searchPath [lindex $results 1]
	set extension  [lindex $results 2]
	set ignorePats [lindex $results 3]
	set shortcut   [lindex $results 4]
	if {![info exists fileMatcherQueries($itemName)]} {
	    break
	}
	set q "A pre-set query item named \"${itemName}\" already exists.\
	  Do you want to over-write its previous values?"
	if {[askyesno $q]} {
	    break
	}
    }
    array set fileMatcherQueries [list \
      $itemName    [list $searchPath $filePat $extension $ignorePats $shortcut] \
      omfDefaults  [list $searchPath $filePat $extension $ignorePats] \
      ]
    prefs::modified fileMatcherQueries($itemName)
    openDocument::rebuildMenu
    if {[askyesno "Do you want to add another pre-set query item?"]} {
	openDocument::addFMItem
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::editFMItem" --
 # 
 # Edit the settings (except for the Item Name) of a File Matcher Query item
 # previously defined by the user, save the new settings, and then rebuild
 # the menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::editFMItem {} {
    
    variable fileMatcherQueries
    
    if {![llength [set fmQueries [openDocument::listItems "FM"]]]} {
	error "Cancelled -- there are no pre-set queries to edit."
    }
    set p "Choose a menu item to edit:"
    set options $fmQueries
    set title "Edit A Pre-Set File Matcher"
    while {1} {
	set itemName [listpick -p $p $options]
	if {($itemName eq "(Finish)")} {
	    break
	}
	set searchPath [lindex $fileMatcherQueries($itemName) 0]
	set filePat    [lindex $fileMatcherQueries($itemName) 1]
	set extension  [lindex $fileMatcherQueries($itemName) 2]
	set ignorePats [lindex $fileMatcherQueries($itemName) 3]
	set shortcut   [lindex $fileMatcherQueries($itemName) 4]
	set results    [openDocument::fmDialog $title $itemName \
	  $searchPath $extension $ignorePats $shortcut]
	set searchPath [lindex $results 1]
	set extension  [lindex $results 2]
	set ignorePats [lindex $results 3]
	set shortcut   [lindex $results 4]
	array set fileMatcherQueries [list \
	  $itemName \
	  [list $searchPath $filePat $extension $ignorePats $shortcut] \
	  omfDefaults \
	  [list $searchPath $filePat $extension $ignorePats] \
	  ]
	prefs::modified fileMatcherQueries($itemName)
	openDocument::rebuildMenu
	set p "Choose another, or Finish:"
	set options [concat [list "(Finish)"] $fmQueries]
    }
    status::msg "All changes have been saved."
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::renameFMItem" --
 # 
 # Rename a previously saved pre-set query item.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::renameFMItem {} {
    
    variable fileMatcherQueries
    
    if {![llength [set fmQueries [openDocument::listItems "FM"]]]} {
	error "Cancelled -- there are no File Matcher Query items to edit."
    }
    set p "Choose a menu item to rename"
    set options $fmQueries
    set title "Rename A Menu Item"
    while {1} {
	set itemName [listpick -p $p $options]
	set newName  ""
	if {($itemName eq "(Finish)")} {
	    break
	}
	while {1} {
	    set p "New name for \"${itemName}\":"
	    set newName [prompt $p $itemName]
	    set newName [openDocument::verifyName $newName]
	    if {($newName eq $itemName)} {
		set newName ""
		status::msg "No changes were made."
		break
	    } elseif {([lsearch $fmQueries $newName] > -1)} {
		set q "The name \"${newName}\" is already used by a different\
		  menu item -- do you want to over-write the previous values?"
		if {![askyesno $q]} {
		    continue
		} else {
		    break
		}
	    } else {
		break
	    }
	}
	if {($newName ne "")} {
	    array set fileMatcherQueries [list \
	      $newName      $fileMatcherQueries($itemName) \
	      "omfDefaults" $fileMatcherQueries($itemName) \
	      ]
	    prefs::modified fileMatcherQueries($itemName)
	    prefs::modified fileMatcherQueries($newName)
	    unset fileMatcherQueries($itemName)
	}
	openDocument::rebuildMenu
	set fmQueries [openDocument::listItems "FM"]
	set options [concat [list "(Finish)"] $fmQueries]
	set p "Choose another, or Finish:"
    }
    status::msg "All changes have been saved."
    return
}
   
##
 # --------------------------------------------------------------------------
 #
 # "openDocument::deleteFMItem" --
 # 
 # Remove a previously saved pre-set query from the user's preferences.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::deleteFMItem {} {
    
    variable fileMatcherQueries
    
    if {![llength [set fmQueries [openDocument::listItems "FM"]]]} {
	error "Cancelled -- there are no pre-set queries to delete."
    }
    set p "Delete which File Matcher Query item(s)?"
    set itemNames [listpick -p $p -l $fmQueries]
    foreach itemName $itemNames {
	prefs::modified fileMatcherQueries($itemName)
	unset fileMatcherQueries($itemName)
    }
    openDocument::rebuildMenu
    if {([llength $itemNames] == 1)} {
	status::msg "The pre-set query \"[lindex $itemNames 0]\"\
	  has been deleted."
    } else {
	status::msg "The selected pre-set queries have been deleted."
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::openMatchingFile" --  ?preSetQuery "omfDefaults"?
 # 
 # Opens a dialog for the user to specify a file pattern and a possible file 
 # extension to search in a specified directory and open the found files.
 # 
 # If no "preSetQuery" is specified (or if it doesn't exist) then we use the
 # information from the last query used.  Otherwise we fill in the text
 # fields using the pre-set information.
 # 
 # If a "preSetQuery" is specified, then we allow the user to save any
 # changes made to the "searchPath" or "extension" fields.
 # 
 # When the user presses the "OK" button we send the information along to
 # [file::openViaPathExtension] which takes care of opening the file(s).
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::openMatchingFile {{preSetQuery "omfDefaults"}} {
    
    global alpha::platform
    
    variable fileMatcherQueries
    variable helpTags
    
    # Get our default field values.
    if {![info exists fileMatcherQueries($preSetQuery)]} {
	error "Unknown pre-set query item : $preSetQuery"
    }
    set searchPath [lindex $fileMatcherQueries($preSetQuery) 0]
    set filePat    [lindex $fileMatcherQueries($preSetQuery) 1]
    set extension  [lindex $fileMatcherQueries($preSetQuery) 2]
    set ignorePats [lindex $fileMatcherQueries($preSetQuery) 3]
    if {($preSetQuery eq "omfDefaults")} {
	set savedUserQuery 0
	set title "Open File In Path"
    } else {
	set savedUserQuery 1
	set title "Open File in \"$preSetQuery\" Path"
    }
    
    # Offer the dialog to the user.
    while {1} {
	set dirOption  "Use the path specified above, or select from list below"
	set dirOptions [concat [list $dirOption "-"] \
	  [openDocument::listItems "CD" 0] \
	  [list "-" "Add New Working DirectoryÉ"]]
	set dialogScript [list dialog::make -title $title \
	  -width 550 \
	  -ok "Search" \
	  -okhelptag "Click here to start the search for files\
	  matching the given criteria." \
	  -addbuttons [list \
	  "Help" \
	  "Click here to open File Matcher help." \
	  "help::openGeneral openDocument {File Matching} ; \
	  set retCode 1 ; set retVal {cancel}" \
	  "Browse PathsÉ" \
	  "Click here to change the search path." \
	  {catch {dialog::valSet $dial ",Search Path :" \
	  [get_directory -p {Select a new search path :} \
	  [dialog::valGet $dial ",Search Path :"]]}} \
	  "File PatternsÉ" \
	  "Click here to open a dialog explaining file patterns." \
	  "help::filePatternsHelpDialog" \
	  ]]
	set dialogPage [list "" \
	  [list "text" "Enter the full or partial name of a file you wish to\
	  recursively search for and open in the given path :\r"] \
	  [list "var" "File name pattern :" $filePat \
	  "The full or partial name of the file(s) to search for\
	  in the specified search path"] \
	  [list "var" "Extension (optional) :" $extension $helpTags(extension)] \
	  [list "var" "Patterns to ignore :" $ignorePats $helpTags(ignorePats)] \
	  [list "var" "Search Path :" $searchPath $helpTags(searchPath)] \
	  [list [list "menu" $dirOptions] "Options :" $dirOption \
	  "Use the above directory, or select one of your saved search paths"] \
	  ]
	if {$savedUserQuery} {
            set divider [list "divider" divider]
	    lappend dialogPage $divider \
	      [list "text" "You can save any new Extension, Ignore Pattern,\
	      and Search Path values for the \"${preSetQuery}\" menu item.\r"] \
	      [list "flag" "Save changes for pre-set file matching query" 0] \
	      $divider
	}
	lappend dialogScript $dialogPage
	set results    [eval $dialogScript]
	set filePat    [lindex $results 0]
	set extension  [lindex $results 1]
	set ignorePats [lindex $results 2]
	set searchPath [lindex $results 3]
	set dirOption  [lindex $results 4]
	if {($dirOption eq "Add New Working DirectoryÉ")} {
	    catch {openDocument::addWorkingDirectory}
	} elseif {($filePat eq "")} {
	    alertnote "The file pattern cannot be empty!"
	} else {
	    break
	}
    }
    if {($dirOption ne [lindex $dirOptions 0])} {
	set searchPath $dirOption
    }
    if {$savedUserQuery && [lindex $results 5]} {
	# Save the new values for the pre-set item.
	set fileMatcherQueries($preSetQuery) \
	  [lreplace $fileMatcherQueries($preSetQuery) 0 2 \
	  $searchPath $filePat $extension $ignorePats]
    } else {
	# Retain the old values, but replace the old "filePat" used.
	set fileMatcherQueries($preSetQuery) \
	  [lreplace $fileMatcherQueries($preSetQuery) 1 1 \
	  $filePat]
    }
    prefs::modified fileMatcherQueries($preSetQuery)
    set fileMatcherQueries(omfDefaults) \
      [list $searchPath $filePat $extension $ignorePats]
    file::openViaPathExtension $searchPath $filePat $extension $ignorePats
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::openFilesetMatch" --
 # 
 # Similar to [openDocument::openMatchingFile], create a dialog that allows
 # the user to specify a file pattern, potential extensions and patterns to
 # ignore, and search for all files matching these criteria within the
 # selected fileset.  Unlike [openDocument::openMatchingFile], the last field
 # is a pop-up menu with all of the relevant filesets which can be selected
 # for the list of known files.  All dialog values are saved during and
 # between editing sessions.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::openFilesetMatch {} {
    
    variable fileMatcherQueries
    variable helpTags
    
    while {1} {
	set fileset    [lindex $fileMatcherQueries(filesetMatch) 0]
	set filePat    [lindex $fileMatcherQueries(filesetMatch) 1]
	set extension  [lindex $fileMatcherQueries(filesetMatch) 2]
	set ignorePats [lindex $fileMatcherQueries(filesetMatch) 3]
	set filesets   [lsort -dictionary [fileset::names]]
	if {([win::Current] eq "")} {
	    set filesetsToIgnore [list "Open Windows" \
	      "Top Window's Folder" "Top Window's Hierarchy"]
	    set filesets [lremove $filesets $filesetsToIgnore]
	}

	if {![info exists filesets]} {
	    alertnote "Sorry, you don't have any filesets defined that\
	      can be queried for specific files."
	    return
	}
	if {([lsearch $filesets $fileset] == -1)} {
	    set fileset [lindex $filesets 0]
	}
	set dialogScript [list dialog::make \
	  -title "Find Match in Fileset" \
	  -width 400 \
	  -ok "Search" \
	  -okhelptag "Click here to start the search for files\
	  matching the given criteria." \
	  -addbuttons [list \
	  "Help" \
	  "Click here to open File Matcher help." \
	  {set retCode 1 ; set retVal {cancel} ; \
	  help::openGeneral openDocument {File Matching}} \
	  "File PatternsÉ" \
	  "Click here to open a dialog explaining file patterns." \
	  "help::filePatternsHelpDialog" \
	  ]]
	set dialogPage [list "" \
	  [list "text" "Enter the full or partial name of a file you wish to\
	  search for and open in the specified fileset :\r"] \
	  [list "var"  "File name pattern :" $filePat \
	  "The full or partial name of the file(s) to search for\
	  in the specified fileset"] \
	  [list "var"  "Extension (optional) :" $extension $helpTags(extension)] \
	  [list "var"  "Patterns to ignore :" $ignorePats $helpTags(ignorePats)] \
	  [list [list "menu" $filesets] "Fileset :" $fileset \
	  "Select one of your pre-defined filesets."] \
	  ]
	lappend dialogScript $dialogPage
	set results    [eval $dialogScript]
	set filePat    [lindex $results 0]
	set extension  [lindex $results 1]
	set ignorePats [lindex $results 2]
	set fileset    [lindex $results 3]
	# Retain the new values.
	set fileMatcherQueries(filesetMatch) \
	  [list $fileset $filePat $extension $ignorePats]
	if {($filePat eq "")} {
	    alertnote "The file pattern cannot be empty!"
	    continue
	} else {
	    break
	}
    }
    prefs::modified fileMatcherQueries(filesetMatch)
    # Now we create a list of files, and check for our match.
    set filePat "*[string trim $filePat *]"
    if {($extension eq "")} {
	append filePat "*"
    } elseif {![string match -nocase "*$extension" $filePat]} {
	append filePat "*" [string trimleft $extension "*"]
    }
    # Find all possible matches, and select a single valid option to edit.
    set filesToOpen [list]
    set ignoreFiles [list]
    status::msg "Creating \"$fileset\" fileset list of files É"
    watchCursor
    set fileList [list]
    foreach f [getFilesInSet $fileset] {
	set tail [file tail $f]
	if {[string match -nocase $filePat $tail]} {
	    lappend fileList $f
	}
    }
    foreach f $fileList {
	foreach pat $ignorePats {
	    if {[string match -nocase $pat $f]} {
		lappend ignoreFiles $f
		break
	    }
	}
    }
    set fileList [lsort -unique [lremove $fileList $ignoreFiles]]
    if {![llength $fileList]} {
	error "Cancelled -- No files match \"${filePat}\""
    } elseif {([llength $fileList] == 1)} {
	set filesToOpen $fileList
    } else {
	set dialogPrompt "Open which file(s)?"
	set filesToOpen [dialog::chooseFileFromList $fileList 1 $dialogPrompt]
    }
    # Open the selected option(s), and return the results.
    foreach f $filesToOpen {
	lappend windowsOpened [edit -c $f]
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "openDocument::listMatchingFiles" -- 
 # 
 # This is a variation of "File > Open > Matching File Query" in which we
 # give the user a bit more control over file matching patterns (i.e. the use
 # of "*") without requiring the actual file pattern syntax.  This is similar
 # to the MacOS "Find" dialog wrt "whose names are/begins with/..."  options.
 # In this procedure we also allow the user to specify hierarchy depth.
 # 
 # Results are listed in a new window, complete with hyperlinks to open the
 # files in Alpha or to view them in the OS Finder.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDocument::listMatchingFiles {} {
    
    global alpha::application
    
    variable helpTags
    variable lmfDefaults
    
    # Create a dialog with various options.
    set txt0 "in this path :"
    set txt1 "with names that"
    set txt2 "this pattern :"
    set txt3 "but ignoring :"
    set txt4 "following the path's hierarchy to this depth :"
    set dialogScript [list dialog::make -title "List Local Files" \
      -width 550 \
      -ok "Search" \
      -okhelptag "Click here to start the search for files\
      matching the given criteria." \
      -addbuttons [list \
      "Help" \
      "Click here to open File Matcher help." \
      "help::openGeneral openDocument {File Matching} ; \
      set retCode 1 ; set retVal {cancel}" \
      "Browse PathsÉ" \
      "Click here to change the search path." \
      "dialog::valSet \$dial \",$txt0\" \
      \[get_directory -p \"Select a folder :\" \]" \
      "File PatternsÉ" \
      "Click here to open a dialog explaining file patterns." \
      "help::filePatternsHelpDialog"] \
      [list "" \
      [list "text" "List local filesÉ"] \
      [list "var" $txt0 $lmfDefaults(searchPath) $helpTags(searchPath)] \
      [list [list "menu" [list "are" "contain" "start with" "end with"]] \
      $txt1 $lmfDefaults(criterion) \
      "File name matching criteria"] \
      [list "var" $txt2 $lmfDefaults(pattern) $helpTags(pattern)] \
      [list "var" $txt3 $lmfDefaults(ignorePats) $helpTags(ignorePats)] \
      [list [list "menu" [list "0" "1" "2" "3" "4" "5" "6" "7" "°"]] \
      $txt4 $lmfDefaults(depth) "Hierarchy depth"] \
      ]]
    # Present the dialog, and record the values.
    set results [eval $dialogScript]
    array set lmfDefaults [list \
      "searchPath" [lindex $results 0] \
      "criterion"  [lindex $results 1] \
      "pattern"    [lindex $results 2] \
      "ignorePats" [lindex $results 3] \
      "depth"      [lindex $results 4] \
      ]
    # Confirm valid values.
    if {![file isdir $lmfDefaults(searchPath)]} {
	alertnote "Sorry, \"$lmfDefaults(searchPath)\" does not exist."
	return [openDocument::listMatchingFiles]
    } elseif {([string trim $lmfDefaults(pattern)] eq "")} {
	alertnote "You must enter a search pattern."
	return [openDocument::listMatchingFiles]
    } elseif {[regexp {\*} $lmfDefaults(pattern)]} {
	alertnote "Sorry, \"*\" cannot be used in the search pattern."
	return [openDocument::listMatchingFiles]
    }
    switch -- $lmfDefaults(criterion) {
	"are"        {set pattern $lmfDefaults(pattern)}
	"contain"    {set pattern "*$lmfDefaults(pattern)*"}
	"start with" {set pattern "$lmfDefaults(pattern)*"}
	"end with"   {set pattern "*$lmfDefaults(pattern)"}
    }
    # Create the list of all files.
    watchCursor
    status::msg "Creating list of foldersÉ"
    set fileList [set results [set ignoreFiles [list]]]
    if {([set depth $lmfDefaults(depth)] eq "°")} {
	set depth "10000"
    }
    if {($depth > 0)} {
	set folders [file::hierarchy $lmfDefaults(searchPath) $depth]
    }
    lappend folders $lmfDefaults(searchPath)
    status::msg "Creating list of matching filesÉ"
    foreach d $folders {
	eval [list lappend fileList] [glob -nocomplain -dir $d -- $pattern]
    }
    foreach f $fileList {
	set tail [file tail $f]
	foreach pat $lmfDefaults(ignorePats) {
	    if {[string match -nocase $pat $tail]} {
		lappend ignoreFiles $f
		break
	    }
	}
    }
    set results [lremove $fileList $ignoreFiles]
    if {![llength $results]} {
	status::msg "No matching files were found."
	return
    }
    # Create a header for the new window, and format the results.
    status::msg "Creating the formatted window with resultsÉ"
    set header {
	Found Files
	
	Path :        PATH
	Depth :       DEPTH
	Match Rule :  CRITERION
	Matching :    PATTERN
	Ignoring :    IGNORE
	Files Found : COUNT
	Date/Time :   DATE
	
	This window contains all files found using the criteria listed above.
	
	Clicking on the "edit" hyperlinks will open the file in ALPHA, while the
	"show" hyperlinks will display its location in the OS Finder.
    }
    regsub -all -- {PATH}      $header $lmfDefaults(searchPath) header
    regsub -all -- {DEPTH}     $header $lmfDefaults(depth)      header
    regsub -all -- {CRITERION} $header $lmfDefaults(criterion)  header
    regsub -all -- {PATTERN}   $header $lmfDefaults(pattern)    header
    regsub -all -- {IGNORE}    $header $lmfDefaults(ignorePats) header
    regsub -all -- {DATE}      $header [mtime [now] long]       header
    regsub -all -- {ALPHA}     $header ${alpha::application}    header
    set openShow "open  show  "
    set editShow "edit  show  "
    set count 0
    
    foreach f $results {
	lappend pathLengths([llength [file split $f]]) $f
    }
    foreach n [lsort [array names pathLengths]] {
	foreach f [lsort -unique $pathLengths($n)] {
	    if {![info exists seenFolders([set d [file dirname $f]])]} {
		set s ${openShow}${d}
		append t "\r[string repeat "_" [string length $s]]\r\r${s}\r\r"
		set seenFolders($d) ""
	    }
	    append t "${editShow}${f}\r"
	    incr count
	}
    }
    regsub -all -- {COUNT} $header $count header
    # Create a new window with the information.
    set t "${header}${t}\r\r"
    set w [new -n "* Found Files *" -text $t -mode "Text" -dirty 0]
    setWinInfo -w $w read-only 1
    goto [minPos]
    help::colourTitle "red"
    # Highlight the search strings found in the new window.
    set pattern "^${editShow}\[^\r\]+\r"
    set pos [minPos -w $w]
    while {1} {
	set pp [search -n -s -all -f 1 -r 1 -- $pattern $pos]
	if {![llength $pp]} {
	    break
	}
	set editBeg [lindex $pp 0]
	set editEnd [pos::math -w $w $editBeg + 4]
	set showBeg [pos::math -w $w $editBeg + 6]
	set showEnd [pos::math -w $w $editBeg + 10]
	set nameBeg [pos::math -w $w $editBeg + 12]
	set nameEnd [pos::math -w $w [lindex $pp 1] - 1]
	set name    [getText -w $w $nameBeg $nameEnd]
	text::color $editBeg $editEnd blue
	text::hyper $editBeg $editEnd "edit -c \"${name}\""
	text::color $showBeg $showEnd red
	text::hyper $showBeg $showEnd "file::showInFinder \"${name}\""
	set pos $nameEnd
    }
    set pattern "^${openShow}\[^\r\]+\r"
    set pos [minPos -w $w]
    while {1} {
	set pp [search -n -s -all -f 1 -r 1 -- $pattern $pos]
	if {![llength $pp]} {
	    break
	}
	set brwsBeg [lindex $pp 0]
	set brwsEnd [pos::math -w $w $brwsBeg + 4]
	set showBeg [pos::math -w $w $brwsBeg + 6]
	set showEnd [pos::math -w $w $brwsBeg + 10]
	set nameBeg [pos::math -w $w $brwsBeg + 12]
	set nameEnd [pos::math -w $w [lindex $pp 1] - 1]
	set name    [getText -w $w $nameBeg $nameEnd]
	text::color $brwsBeg $brwsEnd blue
	text::hyper $brwsBeg $brwsEnd "file::browseFor \"${name}\""
	text::color $showBeg $showEnd red
	text::hyper $showBeg $showEnd "file::showInFinder \"${name}\""
	set pos $nameEnd
    }
    refresh
    status::msg ""
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Proposed SystemCode procs ×××× #
# 
# All of the procedures in the "file" namespace could be useful for other
# code, and could be placed in the "fileManipulation.tcl" file.
# 

namespace eval file {}

##
 # --------------------------------------------------------------------------
 #
 # "file::openViaStatusPrompt" --  ?dir? ?filePattern?
 # 
 # Allow the user to type in a name in the status bar to open a file via a
 # status bar prompt.  Pressing Tab will attempt to complete the current
 # path.  If there is a unique path, simply put it in the new prompt,
 # otherwise open a list-pick dialog with all options.  When the user presses
 # Return, we do a final validation check, and offer all possible file name
 # completions in a list-pick dialog if there's more than 1.
 # 
 # If no "dir" is supplied or if it is not an existing folder, then [pwd]
 # will be used instead.  The optional file pattern is used for the
 # completion routines, to help identify a unique file by limiting the
 # options to those that match the pattern.
 # 
 # This proc serves as its own "-command" validation function for the call to
 # [status::prompt].  We maintain an "ofwdText" variable which is appended to
 # the default path to determine the chosen file.  If the user cancels any of
 # the [listpick] dialogs we don't do a full scale cancel, just allow the
 # prompt text to be edited further.
 # 
 # During the Tab completion routine ("9" in the switch) we continue to offer
 # all possible completions whenever the user selects a directory, adjusting
 # the status message as we go.  We go to some trouble to strip and add the
 # trailing file separator character to conform to MacClassic issues with
 # [file join], i.e. [file join a: b:] vs [file join a: b].
 # 
 # Returns the full name of the window created by Alpha.
 # 
 # Contributed by Craig Barton Upright.
 # 
 # --------------------------------------------------------------------------
 # 
 # Examples:
 # 
 #     file::openViaStatusPrompt 
 #     file::openViaStatusPrompt "/Users/cbu/"
 #     file::openViaStatusPrompt "/Documents/"
 #     file::openViaStatusPrompt "/Documents/research/spouses/" "*.tex"
 #     file::openViaStatusPrompt \"[file join $HOME Tcl]\" {*.tcl}"
 # 
 # Usage notes:
 # 
 # While you are typing the name of the file, you can ...
 # 
 # Press Tab to complete the path.  If there is only one completion
 # available, it will be added to the path automatically, otherwise all
 # possible options will be offered in a list-pick dialog.  If the current
 # path ends with a file separator, all files and folders within that folder
 # will be offered.  If you select a file rather than a directory, that file
 # will be opened immediately.  If you cancel the list-pick dialog, you'll
 # still have the option to edit the path you've entered.
 # 
 # Press Return to open the file designated by the current path.  If the path
 # is incomplete and there is only one possible option, this file is opened
 # automatically, otherwise all possible file options will be offered in a
 # list-pick dialog.
 # 
 # Press Escape or any of the Arrow Navigation keys to abort the prompt.
 # 
 # Type "../" to move one level higher.
 # 
 # Tip: Press Escape-X and type "pwd" followed by Return to display the
 # Current Working Directory in the status bar.  You can also use this method
 # to type "cd <directory>" to change the Current Working Directory.
 # 
 # Tip: If the current path ends with a file separator, typing that key again
 # will also trigger a list-pick completion dialog.  So if the current
 # directory is too low in your hierarchy, you can type "..//" to get a
 # list-pick with the contents one level up.  The one thing you cannot do is
 # press Delete to remove the text of the initial working directory.
 # 
 # --------------------------------------------------------------------------
 ##

proc file::openViaStatusPrompt {args} {
    
    variable ovspDefault
    variable ovspExtPat
    variable ovspPath
    variable ovspText
    
    getOpts
    if {![info exists opts(-command)] || [llength $args] > 2} {
	# This is the first call for the status bar prompt.
	set ovspDefault [lindex $args 0]
	# Make sure that the supplied "ovspDefault" path actually exists.
	if {($ovspDefault eq "")} {
	    set ovspDefault [pwd]
	} else {
	    while {![file isdirectory $ovspDefault]} {
		set ovspDefault [file dirname $ovspDefault]
		if {($ovspDefault eq [file dirname $ovspDefault])} {
		    break
		}
	    }
	}
	if {[string index $ovspDefault end] ne [file separator]} {
	    append ovspDefault [file separator]
	}
	# Make sure that we have a valid extension pattern.
	if {([lindex $args 1] ne "")} {
	    set ovspExtPat [lindex $args 1]
	} else {
	    set ovspExtPat "*"
	}
	set ovspPath ""
	set ovspText ""
	set p "Open File (press Tab to complete) : $ovspDefault"
	set promptFunc "::file::openViaStatusPrompt -command --"
	catch {
	    status::prompt -f -appendvar ovspText -command $promptFunc $p
	} result
	set f $ovspPath
	unset ovspDefault ovspExtPat ovspPath ovspText
	switch -- $result {
	    "cancel" {
		error "Cancelled."
	    }
	    "done" {
		if {![file isfile $f]} {
		    error "Cancelled -- file doesn't exist : $f"
		}
	    }
	    default {
		error "Cancelled -- ${result}."
	    }
	}
	return [edit -c $f]
    } else {
	# This is the function used when a key has been pressed.
	set ovspPath "${ovspDefault}${ovspText}"
	set separator [file separator]
	set key [lindex $args 0]
	if {($key eq $separator) \
	  && ([string index $ovspPath end] eq $separator)} {
	    # A double separator, so do a completion.
	    set decVal 9
	} elseif {($key ne "")} {
	    scan $key %c decVal
	} else {
	    # ???
	    set decVal ""
	}
	switch -- $decVal {
	    1 - 4 - 11 - 12 - 28 - 29 - 30 - 31 {
		# Navigation keys.
		error "navigation key pressed"
	    }
	    8 {
		# Delete key.
		set ovspText [string range $ovspText 0 end-1]
	    }
	    9 {
		# Tab key -- attempt to complete.  If the user completes to
		# an existing file, then we're done.
		set completions [list]
		set offerMore 0
		if {[file isdirectory $ovspPath]} {
		    set dir $ovspPath
		} else {
		    set dir [file dirname $ovspPath]
		    set pat [file tail $ovspPath]
		}
		append pat "*"
		set files [glob -nocomplain -tails -dir $dir -- $pat]
		for {set i 0} {$i < [llength $files]} {incr i} {
		    set f [lindex $files $i]
		    if {[file isdirectory [file join $dir $f]]} {
			append f $separator
		    } elseif {![string match $ovspExtPat $f]} {
			continue
		    }
		    lappend completions $f
		}
		if {![llength $completions]} {
		    alertnote "No additional completions available."
		    return
		} elseif {([llength $completions] == 1) \
		  && ![file isdirectory $ovspPath]} {
		    # We're completing a unique path after typing a portion
		    # of its path.
		    set completion [lindex $completions 0]
		} else {
		    # Since we're entering "list-pick" mode, we'll continue
		    # to offer more completions until we have a complete file
		    # path.  (Is this annoying?)
		    set offerMore 1
		    if {([string trimright $dir $separator] \
		      ne [string trimright $ovspDefault $separator])} {
			set completions [concat [list ".. (up one level)"] \
			  $completions]
			set L [list [lindex $completions 1]]
		    } else {
			set L [list [lindex $completions 0]]
		    }
		    status::msg "Open File ( select a completion ) : $ovspPath"
		    if {[catch {
			listpick -p $dir -L $L -- $completions
		    } completion]} {
			return
		    } elseif {($completion eq ".. (up one level)")} {
			if {[file isdirectory $ovspPath]} {
			    set dir [file dirname $dir]
			}
			set completion ""
		    }
		}
		set completion [string trim $completion $separator]
		set ovspPath [file join $dir $completion]
		if {[file isdirectory $ovspPath]} {
		    set ovspPath [string trimright $ovspPath $separator]
		    append ovspPath $separator
		}
		set idx [string length $ovspDefault]
		set ovspText [string range $ovspPath $idx end]
		if {[file isfile $ovspPath]} {
		    error "done"
		} elseif {[file isfile "${ovspPath}${ovspExtPat}"]} {
		    append ovspPath $ovspExtPat
		    error "done"
		} elseif {!$offerMore} {
		    return
		} elseif {[file isdirectory $ovspPath]} {
		    status::msg "Open File ( select a completion ) : $ovspPath"
		    return [::file::openViaStatusPrompt -command "\t"]
		} else {
		    # Not a file, not a directory ??
		    error "done"
		}
	    }
	    13 {
		# Return key.  Confirm that we have a valid file, and offer
		# the remaining file-only choices if we don't.
		if {[file isdirectory $ovspPath]} {
		    return [file::openViaStatusPrompt -command "\t"]
		} elseif {![file isfile $ovspPath]} {
		    set dir   [file dirname $ovspPath]
		    set tail  [file tail $ovspPath]
		    set files [glob -nocomplain -dir $dir -tails -- $ovspExtPat]
		    set options [list]
		    foreach f $files {
			if {[file isdirectory $f]} {
			    continue
			} elseif {[string match ${tail}${ovspExtPat} $f]} {
			    lappend options [file tail $f]
			}
		    }
		    if {![llength $options]} {
			error "done"
		    } elseif {([llength $options] == 1)} {
			set ovspPath [file join $dir [lindex $files 0]]
		    } else {
			set p "Choose a file:"
			if {[catch {listpick -p $p -- $options} option]} {
			    return
			}
			set ovspPath [file join $dir $option]
		    }
		}
		error "done"
	    }
	    27 {
		# Escape key.
		error "escape key pressed"
	    }
	    default {
		append ovspText $key
	    }
	}
	return $ovspText
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "file::openViaPathExtension" --  dir filePattern ?extension?
 # 
 # Recursively find all files in "dir" that match a given pattern.  All but
 # the first two arguments are optional, and include (in this order) :
 # 
 #     dir          -- defaults to [pwd] if  it is the null string.  If this
 #                     path doesn't exist, we attempt to use its parent until
 #                     we find a path that does exist.
 #     filePat      -- If empty, an error will be thrown.  This pattern
 #                     should be "glob-style" for file matching.
 #     extension    -- an optional argument that will be placed at the end of
 #                     the filePat argument.  It will be automatically
 #                     prefixed with "*" if not supplied.
 #     ignorePats   -- a list of file matching patterns to ignore.
 # 
 # If the compiled list of all possible matching files within the hierarchy
 # of the given "dir" has a single item, we automatically open it for
 # editing.  Otherwise we offer the user a list of all options, truncating
 # the file names so that the original "dir" string is removed.  (In the case
 # of multiple options, we allow the user to open multiple files.)
 # 
 # Returns a list containing the full window name(s) created by Alpha.
 # 
 # Contributed by Joachim Kock, modified by Craig Barton Upright. 
 # 
 # --------------------------------------------------------------------------
 ##

proc file::openViaPathExtension {args} {
    
    if {([llength $args] > 4)} {
	error "usage: file::openViaPathExtension dir filePat\
	  ?extension? ?ignorePats?"
    }
    set dir        [lindex $args 0]
    set filePat    [lindex $args 1]
    set extension  [lindex $args 2]
    set ignorePats [lindex $args 3]
    # Make sure that we have a valid file pattern to search for.
    if {($filePat eq "")} {
	error "a non-empty file pattern must be supplied."
    }
    # Make sure that the supplied "dir" actually exists.
    if {($dir eq "")} {
	set dir [pwd]
    } else {
	while {![file isdirectory $dir]} {
	    set dir [file dirname $dir]
	    if {($dir eq [file dirname $dir])} {
		break
	    }
	}
    }
    if {[string index $dir end] ne [file separator]} {
	append dir [file separator]
    }
    # Massage our variable strings.
    if {[string index $dir end] ne [file separator]} {
	append dir [file separator]
    }
    set filePat "*[string trim $filePat *]"
    if {($extension eq "")} {
	append filePat "*"
    } elseif {![string match -nocase "*$extension" $filePat]} {
	append filePat "*" [string trimleft $extension "*"]
    }
    # Find all possible matches, and select a single valid option to edit.
    set filesToOpen [list]
    set ignoreFiles [list]
    status::msg "Searching \"${dir}\" É"
    watchCursor
    set fileList [file::listFilesInHierarchy $dir $filePat]
    foreach f $fileList {
	foreach pat $ignorePats {
	    if {[string match -nocase $pat $f]} {
		lappend ignoreFiles $f
		break
	    }
	}
    }
    set fileList [lremove $fileList $ignoreFiles]
    if {![llength $fileList]} {
	error "Cancelled -- No files match \"${filePat}\""
    } elseif {([llength $fileList] == 1)} {
	set filesToOpen $fileList
    } else {
	set dialogPrompt "Open which file(s)?"
	set filesToOpen [dialog::chooseFileFromList $fileList 1 $dialogPrompt]
    }
    # Open the selected option(s), and return the results.
    foreach f $filesToOpen {
	lappend windowsOpened [edit -c $f]
    }
    return $windowsOpened
}

##
 # --------------------------------------------------------------------------
 #
 # "file::listFilesInHierarchy" --  dir ?pattern?
 # 
 # Returns a list of all files in the given "dir", limited to those matching
 # the glob-style "pattern".  This is an enhanced version of [file::recurse], 
 # addressing two limitation of that procedure:
 # 
 # (1) [file::recurse] will return folders that match "pattern", while this
 # only returns items that are actual files.
 # 
 # (2) [file::recurse] uses [string match ...]  to limit its results, but in
 # file systems that are case-insensitive (where "Readme" is also "readme"
 # when listing the file names) the results are not entirely accurate.  This
 # limitation could be addressed by using [string match -nocase] when this is
 # appropriate, but that requires platform checking.  Using [glob ...  $pat]
 # will always take this into account.
 # 
 # The [exec] version below is quite a bit faster, so if that Tcl command is
 # available we use that preferentially.
 # 
 # Version 1 contributed by Craig Barton Upright.
 # Version 2 contributed by Joachim Kock.
 # 
 # --------------------------------------------------------------------------
 # 
 # Version 1 note: [file::hierarchy] requires a "depth" argument.  We don't
 # want to limit the depth, but find all files recursively, so we set this
 # argument to an arbitrarily high value.  There is no performance issue
 # here, as evidenced by
 # 
 #   ÇAlphaÈ time {file::hierarchy $HOME 5} 10
 #   106898 microseconds per iteration
 #   ÇAlphaÈ time {file::hierarchy $HOME 10} 10
 #   126133 microseconds per iteration
 #   ÇAlphaÈ time {file::hierarchy $HOME 100} 10
 #   126279 microseconds per iteration
 #   ÇAlphaÈ time {file::hierarchy $HOME 1000} 10
 #   126187 microseconds per iteration
 #   ÇAlphaÈ time {file::hierarchy $HOME 10000} 10
 #   126326 microseconds per iteration
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands ::exec]]} {
    
    proc file::listFilesInHierarchy {dir {pattern *}} {
	
	if {![file exists $dir]} {
	    return
	}
	set files   [list]
	set folders [file::hierarchy $dir 10000]
	lappend folders $dir
	foreach folder $folders {
	    foreach f [glob -nocomplain -dir $folder -- $pattern] {
		if {[file isfile $f]} {
		    lappend files $f
		}
	    }
	}
	return $files
    }
    
} else {
    
    proc file::listFilesInHierarchy {dir {pattern *}} {
	
	if {![file exists $dir]} {
	    return
	}
	set dir [string trimright $dir [file separator]]
	return [split [exec sh << "find \"$dir\" -type f -iname \
	  \"$pattern\" 2>/dev/null; exit 0" ] \n]
    }
}

namespace eval dialog {
    variable chooseFileFromListNames
    if {![info exists chooseFileFromListNames]} {
	set chooseFileFromListNames [list]
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "dialog::chooseFileFromList" --  fileList ?multiList? ?dialogPrompt?
 # 
 # Given a list of files, present them to the user for selection in a
 # list-pick dialog.  The main function of this procedure is to truncate the
 # file names, removing any shared path elements so that it is easier to
 # identify the files.
 # 
 # If the initial list of files has a single item, we simply return that
 # item.  Otherwise we offer the user a list of all options, optionally
 # allowing multiple selections.
 # 
 # In any case, results are returned as a list.  If the user cancels the 
 # list-pick dialog, an error is thrown.
 # 
 # --------------------------------------------------------------------------
 ##

proc dialog::chooseFileFromList {fileList {multiList "1"} {dialogPrompt ""}} {
    
    variable chooseFileFromListNames
    
    # Preliminaries.
    if {([llength $fileList] <= 1)} {
	return $fileList
    }
    if {($dialogPrompt eq "")} {
	if {!$multiList} {
	    set dialogPrompt "Select a file:"
	} else {
	    set dialogPrompt "Select file(s):"
	}
    }
    set finalList [list]
    # Create the list of file path elements.
    set filePaths [list]
    foreach fileName $fileList {
	lappend filePaths [file split $fileName]
    }
    # Find the common leading file path elements.
    set pathLevel 0
    while {1} {
	set dirNames [list]
	for {set idx 0} {($idx < [llength $filePaths])} {incr idx} {
	    set dirName [lindex $filePaths $idx $pathLevel]
	    if {($dirName eq "")} {
		lappend dirNames "must" "break" "now" "!"
		break
	    } else {
		lappend dirNames $dirName
	    }
	}
	if {([llength [lsort -unique $dirNames]] > 1)} {
	    break
	} else {
	    incr pathLevel
	}
    }
    foreach fileListing $filePaths {
	lappend options [eval [list file join] \
	  [lrange $fileListing $pathLevel end]]
    }
    # Offer all options to the user.
    status::msg "All listed files are in \"[file join [eval [list file join] \
      [lrange $fileListing 0 [expr {$pathLevel - 1}]]]]\" É"
    set listPickScript [list "listpick" "-p" $dialogPrompt "-indices"]
    if {$multiList} {
	lappend listPickScript "-l"
    }
    foreach previousFile $chooseFileFromListNames {
	if {([lsearch -exact $options $previousFile] > -1)} {
	    lappend listPickScript "-L" [list $previousFile]
	    break
	}
    }
    lappend listPickScript $options
    foreach idx [eval $listPickScript] {
	lappend finalList [lindex $fileList $idx]
	set chooseFileFromListNames \
	  [linsert $chooseFileFromListNames 0 [lindex $options $idx]]
	set chooseFileFromListNames [lunique $chooseFileFromListNames]
	prefs::modified chooseFileFromListNames
    }
    return $finalList
}

# ===========================================================================
#
# ×××× ------------ ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 11/15/04 cbu 0.1    Original.
# 11/17/04 cbu 0.2    Cleanup, simplified [file::openViaStatusPrompt].
# 11/18/04 cbu 1.0    Added Joachim's [file::openViaPathExtension] routine.
#                     This is probably ready for the public to test/use.
# 11/22/04 cbu 1.0.1  Addressed MacClassic [file join a: b:] issues.
#                     Added ".. (up one level) in [file::openViaStatusPrompt]
# 11/04/05 cbu 1.1    Added "Current Directory" submenu.
#                     Reorganized menu slightly for "CD" submenu.
# 12/19/05 cbu 1.1.1  "CD" menu always indicates the current working 
#                       directory, but intervening in [cd] command.
#                     Adjustments to how default/new directories are set.
# 12/20/05 cbu 1.1.2  Added "File > Open > Working Directory Match" command.
#                     Minor re-organization of procedures in this file.
# 12/21/05 cbu 1.2    Changed "Open > Local File" to "Open > Open Local File"
#                     Changed "Open > Working Directory File" to a new item
#                       below "Open Local File", "Open > via Status Prompt".
#                     Re-organization of entire submenu.
#                     "Matches" now always referred to as "Queries".
#                     New "File > Open > Fileset Query" menu item.
#                     All "File Match Query" dialogs include a pop-up menu
#                       with the list of Working Directory options.
#                     Updated annotation and help argument.
#                     New [dialog::chooseFileFromList] procedure.
#                     "Ignore" patterns now apply to the entire path.
# 01/25/06 cbu 1.2.1  [dialog::chooseFileFromList] remembers last chosen.
#                     Better pattern+extension for finding matching files.
#                     Replaced {![string length ...]} with {... eq ""}
#                     Update dialog help tags.
# 

# ===========================================================================
#
# .