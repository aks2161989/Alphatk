## -*-Tcl-*- (nowrap) (indentationAmount:4)
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "help.tcl"
 #                                          created: 07/21/2000 {18:31:50 PM}
 #                                      last update: 05/24/2006 {09:46:25 AM}
 # Description:
 # 
 # Procedures that create the main menubar Help menu, to choose the correct
 # file to open when a Help menu item is selected based on user defined
 # preferences, and support for automatic marking, colorizing, hyperising of
 # help files opened within Alpha.  For some examples of how to include
 # various colours/hyperlinks, see the "Help Files Help" file.  This file
 # also defines the "AlphaDev Help Files" and "Help File Marking" submenus
 # for the AlphaDev menu.
 # 
 # Also provides some preliminary support for adding a 'Help' mode, which
 # could (among other things) provide a menu containing additional help
 # procedures for the user, i.e. obtaining the latest version of the current
 # help file, searching the 'Help' fileset for more information, etc.
 # Several variables below are defined in a HelpmodeVars array, used in many
 # procs in this file but also globally available.
 # 
 # Note that all procs in the "Window Marks/Colours/Hypers" sections are not
 # necessarily specific to Help files, and can be safely called by any other
 # code in AlphaTcl.  They all perform actions on the current window, many
 # accept optional arguments for different colours.  When supplying a colour
 # argument, calling code must include a 'refresh' if desired.  (Including
 # them here rather than in "colorsMenu.tcl" ensures that they will be
 # available even if that package has been uninstalled.)
 # 
 # --------------------------------------------------------------------------
 # 
 # Procedures for marking, colorizing and hyperizing "Alpha Commands" and
 # "Alpha Manual" files based on those originally by Peter Keheler,
 # 
 # Copyright (c) Peter Keleher
 # All rights reserved.
 # 
 # All other procedures:
 # 
 # Copyright (c) 1997-2006 Vince Darley, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# Auto-loading extension declaration.
alpha::library "helpMenu" 1.8.4 {
    help::initializePackage
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Creates the menubar Help menu, and provides utilities for opening and
    marking AlphaTcl help windows
} help {
    file "Help Files Help"
}

proc help.tcl {} {}

namespace eval contextualMenu {
    
    variable menuSections
    # Place this item in the first section.
    lunion menuSections(1) "${::alpha::application}HelpMenu"
    
    # Includes a list of Help files, such as those items in the main Help
    # menu
    newPref flag "${alpha::application}HelpMenu" 1 contextualMenu
    menu::buildProc "${alpha::application}Help" {help::buildCMenu}
}

# This section defines AlphaDev help files, and support for AlphaDev Menu
# submenus.

namespace eval alphadev {
    
    # Register the "AlphaDev Help Files" and "Help File Marking" submenus
    # for the AlphaDev menu.
    menu::buildProc "AlphaDev Help Files" {alphadev::help::buildFilesMenu}
    menu::buildProc "alphaDevHelp"        {alphadev::help::buildFilesMenu}
    menu::buildProc "Help File Marking"   {alphadev::help::buildMarkingMenu}
}

namespace eval alphadev::help {
    
    global alpha::platform

    variable hooksRegistered 0
    
    # This is the list of help files used by the AlphaDev menu, and they will
    # not be included in the main Help menu.  Note that in Alphatk,
    # 
    #     addHelpMenu "\(-"
    #     
    # is _not_ the same as
    # 
    #     addHelpMenu "(-)"
    #     
    # and the latter will be inserted literally into the Help menu, so we use
    # the former in all of these lists (as well as in [help::buildMenu]) to
    # indicate a divider.
    variable fileList [list \
      "Extending Alpha" \
      "Alpha Developers FAQ" \
      "Alpha Commands" \
      "Debugging Help" \
      "Developer Menu Help" \
      "Tcl 8.4 Commands" \
      "TclX Commands" \
      "\(-" \
      "AEGizmos" \
      "Dialogs Help" \
      "Error Help" \
      "Help Files Help" \
      "TclAE Help" \
      "Xserv API" \
      "Xserv Help" \
      "\(-" \
      "Changes - AlphaTcl"
      ]
    if {(${alpha::platform} eq "alpha")} {
        lappend fileList "Changes - Alpha" "Release Notes - Alpha" \
	  "\(-" "Changes - Alphatk" "Release Notes - Alphatk"
    } else {
        lappend fileList "Changes - Alphatk" "Release Notes - Alphatk" \
	  "\(-" "Changes - Alpha" "Release Notes - Alpha"
    }
    # The list of "Help File Marking" menu items.
    variable markingItems [list \
      "/H<U<BmimicHelpMenu" \
      "\(-" \
      "markHelpFile" \
      "markAsReferenceManual" \
      "markAsAlphaManual" \
      "markAsAlphaCommands" \
      "\(-" \
      "colourTitleÉ" \
      "colourMarksÉ" \
      "underlineMarks" \
      "colourCodeInsertsÉ" \
      "colourAllCapLinesÉ" \
      "\(-" \
      "hyperiseUrls" \
      "hyperiseEmails" \
      "hyperiseExtras" \
      "\(-" \
      "removeAllMarks" \
      "removeAllColoursAndHypers" \
      "convertToSetext" \
      ]
    if {${alpha::platform} == "alpha"} {
	# These only make sense if we have resource forks available.
	lappend markingItems "\(-" \
	  "markEtcAllHelpFilesÉ" "unmarkAllHelpFilesÉ"
    } 
}

proc alphadev::help::buildFilesMenu {} {
    
    variable fileList
    
    return [list build $fileList {alphadev::help::menuProc -m}]
}

proc alphadev::help::buildMarkingMenu {} {
    
    global alphaDeveloperMenu global::features
    
    variable markingItems
    variable hooksRegistered
    
    if {!$hooksRegistered && [info exists alphaDeveloperMenu] \
      && [lsearch ${global::features} alphaDeveloperMenu]} {
	hook::register requireOpenWindowsHook \
	  [list $alphaDeveloperMenu "Help File Marking"] 1
	set hooksRegistered 1
    } 
    return [list build $markingItems {alphadev::help::menuProc}]
}

proc alphadev::help::menuProc {menuName itemName} {
    
    switch -- $menuName {
	"AlphaDev Help Files" - "alphaDevHelp" {
	    if {$itemName eq "Developer Menu Help"} {
	        package::helpWindow "alphaDeveloperMenu"
	    } else {
		helpMenu $itemName
	    }
	}
	"Help File Marking" {
	    if {[catch {menu::generalProc help $itemName} err]} {
		alertnote $err
	    }
	}
	default {
	    error "Unknown menu name: '${menuName}'"
	}
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

# ===========================================================================
# 
# ×××× Preferences ×××× #
# 

# Global preferences.  These used to be defined in "alphaDefinitions.tcl", 
# but it makes more sense to define them here.

# Some Help files are available in multiple formats, such as html, pdf,
# etc.  This preference sets a default format to open, if available.
newPref var preferedHelpFormat "Always offer options" global "" \
  help::Types varitem

# Some Help files are available in multiple formats, such as html, pdf,
# etc.  This preference sets a default format to open, if available.
newPref var secondChoiceHelpFormat "text" global "" \
  help::Choices varitem

# Some Help files are available in multiple formats, such as html, pdf,
# etc.  This preference sets a default format to open, if available.
newPref var thirdChoiceHelpFormat "html" global "" \
  help::Choices varitem

newPref var helpFileWindowSize "Default Size" global "" \
  [list "Don't Change" "Default Size" "-" \
  "Shrink High" "Shrink Low" "Shrink Right" "Shrink Left"]

# Now add these "Config > Preferences > System Preferences" options.
lunion flagPrefs(Help)
lunion varPrefs(Help) preferedHelpFormat secondChoiceHelpFormat \
  thirdChoiceHelpFormat helpFileWindowSize

namespace eval help {
    
    variable initialized
    if {![info exists initialized]} {
        set initialized 0
    }
    
    # Lists used in creating the Help menu.  Each list in a numbered array
    # item will be included, separated from the others by a divider.  Don't
    # include any file extensions in any of these lists.
    # 
    # We use "..." instead of "É" to avoid any silly encoding issues.
    # 
    variable helpMenuLists
    set helpMenuLists(www) [list \
      "ALPHA Home Page" \
      "AlphaTcl Home Page" \
      "Search E-mail Archives..." \
      ]
    set helpMenuLists(global1) [list \
      "Readme" \
      "Quick Start" \
      "ALPHA Manual" \
      "Installed Packages" \
      "Examples Help" \
      ]
    set helpMenuLists(global2) [list \
      "Keyboard Shortcuts" \
      "Regular Expressions" \
      "Search Help" \
      ]
    set helpMenuLists(packages1) [list \
      "Modes Menus & Features" \
      "Electrics Help" \
      "Filesets Help" \
      "FTP Menu Help" \
      "HTML Mode Help" \
      "LaTeX Mode Help" \
      "Tcl-Tk Mode Help" \
      ]
    set helpMenuLists(packages2) [list \
      "More Modes Help..." \
      "More Menus Help..." \
      "More Features Help..." \
      ]
    set helpMenuLists(bugs) [list \
      "Known Bugs" \
      "Debugging Help" \
      "Report A Bug..." \
      "Make A Suggestion..." \
      ]
    set helpMenuLists(changes) [list \
      "Release Notes" \
      "Register ALPHA..." \
      ]
    # Create the order of help file blocks added to the menu.
    set helpMenuLists(order) [list "" \
      "www" "global1" "global2" "packages1" "packages2" "bugs" "changes" \
      ]
    for {set i 1} {($i < [llength $helpMenuLists(order)])} {incr i} {
	set helpMenuLists($i) $helpMenuLists([lindex $helpMenuLists(order) $i])
    }
    unset i
    
    # This list is used by [help::hyperiseExtras], and can include some
    # regular expression type constructions.  No need to include anything
    # that ends in "Help".
    variable helpFileHyperList [list \
      "AEGizmos" \
      "Alpha Developers FAQ" \
      "Alpha Manual" \
      "Changes - Alpha(|Tcl|tk)" \
      "Changes" \
      "Extending Alpha" \
      "Internet Config" \
      "Installed Packages" \
      "Keyboard Shortcuts" \
      "Known Bugs" \
      "Packages" \
      "Quick Start" \
      "Readme" \
      "Registering" \
      "Regular Expressions" \
      "Release Notes" \
      "Shells" \
      "Symantec" \
      "Xserv API" \
      ]
    
    # These are used to set some preferences below, and when choosing the
    # proper Help file format to open for the user.
    variable Types      [list "Always offer options" "text" "html" "pdf"]
    variable Choices    [list "text" "html" "pdf"]
    variable Extensions
    array set Extensions {
	"html" {.html}
	"pdf"  {.pdf}
	"text" {"" .text .txt}
    }
    
    # Used by [help::openPrefsDialog] in some listpick dialogs.
    variable lastChosenMode "Text"
    # Variables used in both [help::chooseColour] and [help::convertColour].
    # These are colours 0 through 7.
    variable Colours [list \
      "none" "blue" "cyan" "green" "magenta" "red" "white" "yellow"]
    # This is the default colour for the dialog.
    variable LastColourChosen "red"
}

## 
 # --------------------------------------------------------------------------
 # 
 # "help::initializePackage" --
 # 
 # Create the HELP and EXAMPLES variables.  For each of the "local" and
 # "user" domains, attempt to create "Help" and "Examples" folders in each
 # SUPPORT directory.
 # 
 # --------------------------------------------------------------------------
 ##

proc help::initializePackage {} {
    
    global alpha::application HOME SUPPORT HELP EXAMPLES
    
    variable initialized
    
    if {$initialized} {
        return
    }
    # Add a new internal "Help" mode.  This ensures that any file with the 
    # mode line "-*-Help-*-" will be automatically colorized.
    addMode "Help" "" "" ""
    alpha::internalModes "Help"
    hook::register openHook {Help::openHook} "Help"
    
    # List all possible locations for help and example files, creating these
    # directories if they don't exist and if we have proper permissions.
    foreach dirName [list "Help" "Examples"] {
	set searchPaths  [list]
	set pathsToCheck [list]
	foreach domain [list user local] {
	    if {($SUPPORT($domain) ne "")} {
		lappend pathsToCheck \
		  [file join $SUPPORT($domain) AlphaTcl $dirName]
	    } 
	}
	lappend pathsToCheck [file join $HOME $dirName]
	foreach path $pathsToCheck {
	    if {![file exists $path] && [file writable [file dirname $path]]} {
		catch {file mkdir $path}
	    }
	    if {[file exists $path]} {
		lappend searchPaths $path
	    } 
	} 
	set [string toupper $dirName] $searchPaths
    }
    set initialized 1
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Called from core ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "alphaHelp" --
 # 
 # Called from "About Alpha" box.  Can also be called from other code.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphaHelp {} {
    
    global HOME alpha::platform
    
    set files [list "Alpha Manual" "Quick Start" "Readme"]
    foreach f $files {
	if {[file exists [help::pathToHelp $f]]} {
	    helpMenu $f
	    return
	}
    }
    # No help files present ...
    help::openAlphaHomePage
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "register" --
 # 
 # Called from "About Alpha" box.  Can also be called from other code.
 # 
 # --------------------------------------------------------------------------
 ##

proc register {} {
    
    global HOME alpha::platform
    
    if {[file exists [set f [file join $HOME Register]]]} {
	alertnote "Please use the \"Register\" application that\
	  will now be launched."
	launch -f $f
    } elseif {${alpha::platform} == "alpha"} {
	set q "Registration must take place on-line in the web page that\
	  will be opened in your browser.  There is no special registration\
	  code that needs to be entered.\r\rDo you want to continue?"
	if {[askyesno $q]} {
	    url::execute "http://order.kagi.com/?PK&lang=en"
	} 
    } else {
	alpha::finalStartup 1
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "helpMenu" --
 # 
 # Called from OS menubar "Help" menu.  Be wary of calling this from other
 # code to avoid recursive loops.  We redirect as necessary, the default
 # option will send the given Help Menu item name to [help::openFile].
 # 
 # Some of the installed Help files could be renamed to avoid some switching
 # here, make sure that this proc is adjusted as necessary.  Other help files
 # (such as "AlphaTcl Home Page.tcl") could be removed entirely, and some
 # of the scripts could be incorporated in SystemCode files (or here) as
 # defined AlphaTcl procedures.
 # 
 # Unlike other menu procs, only the item name is passed along to this proc.
 # 
 # --------------------------------------------------------------------------
 ##

proc helpMenu {args} {
    
    global HOME PREFS alpha::application alpha::platform
    
    regsub -- {(É|\.\.\.)$} [join $args] "" helpFile
    regsub -- ${alpha::application} $helpFile "Alpha" helpFile
    switch -- $helpFile {
	"Alpha Home Page" {
	    help::openAlphaHomePage
	    return
	}
	"Alpha Manual" {
	    set helpFile "Alpha Manual"
	}
	"Alpha's www FAQ" {
	    url::execute "http://www.purl.org/net/alpha/faq"
	    return
	}
	"AlphaTcl Home Page" {
	    url::execute "http://www.purl.org/net/alpha/wiki/"
	    return
	}
	"Changes - Alpha" {
	    switch -- ${alpha::platform} {
		"alpha" {
		    set helpFile "Changes - Alpha"
		}
		"tk" {
		    set helpFile "Changes - Alphatk"
		}
	    }
	}
	"Developer Help" {
	    package::helpWindow "alphaDeveloperMenu"
	    return
	}
	"Emacs Help" {
	    package::helpWindow "emacs"
	    return
	}
	"Filesets Help" {
	    package::helpWindow "filesets"
	    return
	}
	"FTP Menu Help" {
	    package::helpWindow "ftpMenu"
	    return
	}
	"HTML Mode Help" {
	    package::helpWindow "HTML"
	    return
	}
	"Installed Packages" - "Packages" {
	    if {[file exists [file join $PREFS "Packages"]]} {
		set helpFile [file join $PREFS "Packages"]
	    } elseif {[file exists [help::pathToHelp "Packages"]]} {
		set helpFile [help::pathToHelp "Packages"]
	    } else {
		global::listPackages
		return
	    }
	}
	"Known Bugs" {
	    set helpFile "Known Bugs"
	}
	"LaTeX Mode Help" {
	    package::helpWindow "TeX"
	    return
	}
	"Macros Help" {
	    package::helpWindow "macros"
	    return
	}
	"Make A Suggestion" {
	    makeASuggestion
	    return
	}
	"Readme Alpha" {
	    set helpFile "Readme"
	}
	"Register Alpha" {
	    register
	    return
	}
	"Release Notes" {
	    switch -- ${alpha::platform} {
		"alpha" {
		    set helpFile "Release Notes - Alpha"
		}
		"tk" {
		    set helpFile "Release Notes - Alphatk"
		}
	    }
	}
	"Report A Bug" {
	    reportABug
	    return
	}
	"Search E-mail Archives" {
	    set helpFile "Search E-mail Archives"
	}
	"Search Help" {
	    package::helpWindow "supersearch"
	    return
	}
	"Tcl-Tk Mode Help" {
	    package::helpWindow "Tcl"
	    return
	}
	"TclX Commands" {
	    if {[file exists [help::pathToHelp "TclX Help"]]} {
		# This file should be renamed in the cvs.
		set helpFile "TclX Help"
	    } 
	}
    }
    # Still here?  Send the item name along to [help::openFile].
    help::openFile $helpFile
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Building the Help Menu ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "help::buildMenu" --
 # 
 # Called by [menu::buildBasic], which is called in "runAlphaTcl.tcl" during
 # the startup sequence.
 # 
 # The list of potential Help Menu items is created in "help::helpMenuLists"
 # and we make no effort to determine if the files actually exist.  If the
 # user has removed any of them, an error will be displayed in the status bar
 # when the item is selected from the Help Menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc help::buildMenu {} {
    
    global HOME alpha::application
    
    variable helpMenuBuilt
    variable helpMenuLists
    
    if {[info exists helpMenuBuilt]} {
	# We must have already done this once, and we don't want to add the
	# same list of items to the bottom of the Help menu!
	status::msg "The Help menu has already been built."
	return
    } elseif {![file isdirectory [set helpFolder [file join $HOME Help]]]} {
	# "$HOME/Help" folder doesn't exist.
	addHelpMenu "No Help files found"
	return
    }
    
    for {set i 1} {[info exists helpMenuLists($i)]} {incr i} {
	if {($i != 1)} {
	    addHelpMenu "\(-"
	} 
	foreach itemName $helpMenuLists($i) {
	    regsub -- {ALPHA} $itemName ${alpha::application} itemName
	    addHelpMenu $itemName
	}
    }
    
    # We don't need to run through this again.
    set helpMenuBuilt 1
    return
}

# ===========================================================================
# 
# ×××× Help File procedures ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "help::openFile" --
 # 
 # Given the name delivered by the Help menu, find all files which contain it
 # (including the name itself, and any variations with file extensions).  The
 # "helpFile" argument should _not_ be a complete path; if this is the case
 # use [help::openDirect] instead.
 # 
 # If there is a "<something> Help.tcl" file, as in "LaTeX Help.tcl", then
 # that file is sourced immediately.  It's up to the script to decide if more
 # options will be presented.
 # 
 # If there are multiple files, or if the item selected is actually a
 # directory containing other files, the options will be offered to the user.
 # 
 # Thus there can be multiple versions of "LaTeX Help" (for example), such as
 # "LaTeX Help", "LaTeX Help.html", "LaTeX Help.pdf", "LaTeX Help", which
 # will be dealt with by [help::askOrOpen].
 # 
 # The proc [help::pathToHelp] will by default return the first file found in
 # any of the defined HELP directories, but we will search all possible HELP
 # directories to locate related files with unique file tail names.  This
 # means that if we have the following options:
 # 
 # (1) $SUPPORT(user)/AlphaTcl/Help/SomeFile.txt
 # (2) $SUPPORT(local)/AlphaTcl/Help/SomeFile.txt
 # (3) $SUPPORT(local)/AlphaTcl/Help/SomeFile.pdf
 # (4) $HOME/Help/SomeFile.txt
 # (5) $HOME/Help/SomeFile.pdf
 # (6) $HOME/Help/SomeFile.html
 # 
 # then all of (1) (3) and (6) will be passed to [help::askOrOpen].
 # 
 # --------------------------------------------------------------------------
 ##

proc help::openFile {helpFile} {
    
    global HELP
    
    set fileTail [file tail $helpFile]
    if {($fileTail eq "No Help files found")} {
	# The list was built without any files
	if {[askyesno "No help files were found -- perhaps you need to\
	  re-install them. Would you like to open the AlphaTcl home page?"]} {
	    url::execute "http://www.purl.org/net/alpha/wiki/"
	    return
	} else {
	    error "No Help files found in the top level of Alpha's hierarchy."
	}
    }
    # First look for a Tcl script to evaluate.
    if {[file exists [set tclHelpFile [help::pathToHelp ${fileTail}.tcl]]]} {
	# It is up to the script to decide if more options will be presented.
	help::openDirect $tclHelpFile
	return
    } 
    # Find out what file options we have.
    set fileOptions [list]
    foreach helpFolder $HELP {
	set filePath [file join $HELP $helpFolder $fileTail]
	if {[file isdirectory $filePath]} {
	    # This item is actually a subdirectory.
	    eval [list lappend fileOptions] [glob -nocomplain -dir $filePath *]
	} else {
	    # Are there files with this name plus an extension.
	    eval [list lappend fileOptions] [glob -nocomplain -path $filePath ".*"]
	} 
	if {[file isfile $filePath]} {
	    # The filePath exists without an extension, so we add that too.
	    lappend fileOptions $filePath
	} 		
    }
    if {[file exists $helpFile]} {
        lappend fileOptions $helpFile
    }
    if {![llength $fileOptions]} {
	# No options found.
	status::msg "Sorry, no \"$helpFile\" files were found."
	error "No \"$helpFile\" files were found."
    }
    # Pare down the list.
    set fileTails [list]
    set uniqueOptions [list]
    foreach filePath $fileOptions {
	if {([lsearch $fileTails [file tail $filePath]] == -1)} {
	    lappend uniqueOptions $filePath
	}
	lappend fileTails [file tail $filePath]
    }
    # Now that the list of potential files has been set, check some of the
    # "help menu" preferences to see if we have some default action, or if we
    # should adjust the list.
    eval [list help::askOrOpen $fileTail] $uniqueOptions
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "help::pathToHelp" --
 # 
 # Determine the path to the given help file, searching in the list of all 
 # defined HELP folders.  At present this only searches in the top level of 
 # each HELP folder; the argument "help" can be a hierarchy.
 # 
 # If the 'firstFound' argument is 1, return only the first match found.
 # Otherwise, return a list of all the matches.
 # 
 # --------------------------------------------------------------------------
 ##

proc help::pathToHelp {help {firstFound 1}} {
    
    global HELP
    
    set result ""
    foreach path $HELP {
	set f [file join $path $help]
	if {[file exists $f]} {
	    if {$firstFound} {
		# First found wins
		return $f
	    } else {
		lappend result $f
	    }
	} 
    } 
    return $result
}

## 
 # --------------------------------------------------------------------------
 # 
 # "help::pathToExample" --
 # 
 # Determine the path to the given help file, searching in the list of all
 # defined EXAMPLES folders.  At present this only searches in the top level
 # of each EXAMPLES folder; the argument "example" can be a hierarchy.
 # 
 # If the 'firstFound' argument is 1, return only the first match found.
 # Otherwise, return a list of all the matches.
 # 
 # --------------------------------------------------------------------------
 ##

proc help::pathToExample {example {firstFound 1}} {
    
    global EXAMPLES
    
    set result ""
    foreach path $EXAMPLES {
	set f [file join $path $example]
	if {[file exists $f]} {
	    if {$firstFound} {
		# First found wins
		return $f
	    } else {
		lappend result $f
	    }
	} 
    } 
    return $result
}

proc help::askOrOpen {what args} {
    
    set files [eval help::getChoices $args]
    if {[llength $files] == 1} {
	set helpFile [lindex $files 0]
    }
    if {![info exists helpFile]} {
	# No file has been set yet.
	if {[llength $files] == 1} {
	    # Only one file found.
	    set helpFile [lindex $files 0]
	} else {
	    # There is more than one file, with different extensions.
	    foreach f $files {
		set ext [string range [file extension $f] 1 end]
		set tail [file tail $f]
		if {$ext eq "" || $ext eq "txt" } { set ext "text" }
		set ch "View $ext help ($tail)"
		lappend choices $ch
		set choice($ch) $f
	    }
	    lappend choices "(Set Help preferences to avoid this dialog É)"
	    set helpFile [listpick -p "\"$what\" options:" $choices]
	    if {$helpFile == "(Set Help preferences to avoid this dialog É)"} {
		prefs::dialogs::globalPrefs "Help"
		eval helpMenu $args
		return
	    }
	    set helpFile $choice($helpFile)
	    # In case $helpFile is itself a directory ...  This will also
	    # help make sure that the help menu item can work even if a
	    # .tcl file has been deleted.
	    while {[file isdirectory $helpFile]} {
		set files [glob -nocomplain -dir $helpFile *]
		set fileTails ""
		foreach f $files {
		    lappend fileTails [file tail $f]
		}
		set fileDir $helpFile
		set helpFile [listpick -p \
		  "\"[file tail $helpFile]\"  options :" \
		  [lsort $fileTails]]
		set helpFile [file join $fileDir $helpFile]
	    }
	}
    }
    help::openDirect $helpFile
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "help::getChoices"  --
 # 
 # Given a list of possible filenames or file-rootnames, find a list of
 # files which exist and then of those find ones which satisfy the users
 # preferences. 
 # 
 # --------------------------------------------------------------------------
 # 
 ##

proc help::getChoices {args} {
    
    variable Choices 
    variable Extensions
    
    set choices {}
    # Build a list of files which exist and which satisfy one of the known
    # extension types, plus anything ending in .txt or a straight filename
    # with no extension.
    foreach f $args {
	if {[file exists $f] && ![file isdirectory $f]} {
	    if {[lsearch -exact $choices $f] == -1} {
		lappend choices $f
	    }
	}
	if {[file extension $f] == ""} {
	    foreach ext [set help::Choices] {
		if {[file exists ${f}.$ext]} {
		    if {[lsearch -exact $choices ${f}.$ext] == -1} {
			lappend choices ${f}.$ext
		    }
		}
	    }
	    if {[file exists ${f}.txt]} {
		if {[lsearch -exact $choices ${f}.txt] == -1} {
		    lappend choices ${f}.txt
		}
	    }
	}
    }
    # Now we need to just take items from this list of choices which
    # satisfy the user's help preferences
    foreach pref {prefered secondChoice thirdChoice} {
	global ${pref}HelpFormat
	set val [set ${pref}HelpFormat]
	if {$val == "Always offer options"} {
	    return $choices
	}
	foreach f $choices {
	    set ext [file extension $f]
	    if {[lsearch -exact $Extensions($val) $ext] != -1} {
		# We found one, and since we're looking in order of the
		# user's preference, return it.
		return [list $f]
	    }
	}
    }
    return {}
}

## 
 # --------------------------------------------------------------------------
 # 
 # "help::openDirect" --
 # 
 # Called from the Help menu to evaluate (.tcl), send (.html), or just
 # open/mark/hyper (no extension) a file .  Other formats opened by OS.
 # 
 # AlphaDevelopers tool: if the help file is located in a SmarterSource
 # folder, that will be opened preferentially.
 # 
 # ------------------------------------------------------------------------
 ##

proc help::openDirect {filename} {
    
    if {([file pathtype $filename] ne "absolute")} {
	if {[file exists [help::pathToHelp $filename]]} {
	    set filename [help::pathToHelp $filename]
	} elseif {[file exists [help::pathToHelp [file tail $filename]]]} {
	    set filename [help::pathToHelp [file tail $filename]]
	}
    }
    if {[file isdirectory $filename]} {
	return [file::showInFinder $filename]
    } elseif {![file exists $filename] || ![file isfile $filename]} {
	# Let the OS try to handle this?  (Might be an alias, and I'm not sure
	# how we should handle that yet.  [file link ...]  seems to not be
	# fully implemented as of Tcl 8.5a0 .)
	return [file::openAny $filename]
    }
    switch -- [file extension $filename] {
	".tcl" {
	    uplevel \#0 [list source $filename]
	}
	".html" {
	    htmlView $filename
	}
	".txt" - "" {
	    set wins [file::hasOpenWindows $filename]
	    if {[llength $wins]} {
		bringToFront [lindex $wins 0]
	    } else {
		set w [edit -r -c -tabsize 4 $filename]
		if {([win::getMode $w] eq "Text")} {
		    win::ChangeMode "Help"
		}
		if {[catch {help::markColourAndHyper} err]} {
		    error::occurred $err
		}
	    } 
	}
	default {
	    file::openInDefault $filename
	}
    }
    return $filename
}

# ===========================================================================
# 
# ×××× Open via hyperlinks ×××× #
# 
# Provides support for all hyperised help windows, although these can also
# be called directly by other code as well.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "help::openGeneral" --
 # 
 # Called by embedded hyperlinks; look first for "package" help, and
 # otherwise try to open the named help file (as if from Help menu.)
 # 
 # ------------------------------------------------------------------------
 ##

proc help::openGeneral {name {gotomark ""}} {

    regsub -nocase { Help} $name {} package
    if {[catch {package::helpWindow $package}]} {
	helpMenu $name
    }
    if {$gotomark != ""} {
	help::goToSectionMark $gotomark
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "help::openExample" --
 # 
 # Called by embedded hyperlinks.  This proc assumes that (1) the example
 # file is to demonstrate a mode, and (2) "fileTail" exists within one of the
 # Examples folders.  If either of these conditions are not true, calling
 # code should probably determine the file that should be used as an example
 # and call the helper procs below.
 # 
 # Example files must be of the form "<something>-Example.sfx", with the
 # suffix optional.  If the hyperlink looks like "<something> Example.sfx",
 # it will open in a shell window, and inserts some explanatory text at the
 # beginning.  If there is a completions tutorial available for the mode,
 # that will be noted as well.
 # 
 # Exceptions (which are evaluated first):
 # 
 # -- Hyperlinks such as "<something>-Example.sfx" (the actual file name,
 # with the dash) open the actual example file, read-only.
 #  
 # -- If a package includes not only an example file, but wants to do
 # something special with it, then it should install two different files,
 # both a "<something>-Example.sfx" AND a "<something>-Example.sfx.tcl"
 # file, and make the hyperlink with "<something> Example.sfx" .
 # 
 # The presence of a "<something>-Example.sfx.tcl" file creates a special
 # case.  The hyperlink "Calculator Example", for example, evaluates the
 # file "Calculator-Example.tcl", which will then open a calculator window,
 # etc.  ("Tcl Example.tcl" will simply open as an example without being
 # sourced, because there is no "Tcl-Example.tcl.tcl" file.)
 # 
 # ------------------------------------------------------------------------
 ##

proc help::openExample {fileTail} {
    
    global EXAMPLES
    
    # "fileTail" refers to the name given, while "FileTail" is our massaged
    # version that substitutes dashes for spaces.
    regsub -all { +} $fileTail {-} FileTail
    # If the original name didn't have any spaces in it, attempt to locate
    # the file and open it read-only.
    if {($fileTail eq $FileTail) \
      && [file exists [set exampleFile [help::pathToExample $fileTail 1]]]} {
	edit -r -c $exampleFile
	return
    }
    # Now look for a Tcl script to evaluate.
    foreach exampleFolder $EXAMPLES {
	set exampleTclFile [file join $exampleFolder "${fileTail}.tcl"]
	set ExampleTclFile [file join $exampleFolder "${FileTail}.tcl"]
	if {[file isfile $exampleTclFile]} {
	    # A special case -- evaluate the ${filePath}.tcl file.
	    uplevel \#0 [list source $exampleTclFile]
	    return
	} elseif {[file exists $ExampleTclFile]} {
	    # We'll also check to see if the file was erroneously named
	    # without the dash, as in "<something> Example.tcl" .
	    uplevel \#0 [list source $ExampleTclFile]
	    return
	}
    }
    # Special cases are done, and we're still here, so if the file exists
    # open it in a special shell window.
    set ExampleFile [help::pathToExample $FileTail 1]
    if {($ExampleFile ne "") && [file exists $ExampleFile]} {
	help::openExampleFile $ExampleFile [win::FindMode $ExampleFile]
	return
    } else {
	# The file suggested by "fileTail" doesn't exist.
	beep
	error "Cancelled -- \"$fileTail\" is not in any Examples folder."
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "help::openExampleFile" --
 # 
 # Called by [help::openExample], this can also be called by other code that
 # already has a filename that it wants to use as an example.
 # 
 # --------------------------------------------------------------------------
 ##

proc help::openExampleFile {filePath {modeName ""}} {
    
    if {($modeName eq "")} {
	set title "* Example *"
    } elseif {[lsearch [mode::listAll] $modeName] > -1} {
	set title "* [mode::getName $modeName 1] Mode Example *"
    } else {
	set title "* $modeName Example *"
    }
    set wins [file::hasOpenWindows $title]
    if {[llength $wins]} {
	bringToFront [lindex $wins 0]
	return
    }
    set t [help::openExampleFileHelper $modeName]
    status::msg "Opening example file..."
    new -n $title -m $modeName -text [file::readAll $filePath] -shell 1
    goto [minPos]
    
    insertText $t
    if {($modeName eq "Text")} {
	help::hyperiseEmails 1
	help::hyperiseUrls 1
	refresh
    }
    goto [minPos]
    # Now try to mark the file.
    markFile
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "help::openExampleFileHelper" --
 # 
 # Called by [help::openExampleFile], this can also be called by other code
 # that is opening an example file and wants to insert this explanatory text
 # someplace other than the default (top of window).
 # 
 # --------------------------------------------------------------------------
 ##

proc help::openExampleFileHelper {{modeName ""}} {
    
    global HOME SUPPORT
    
    set begComment [set endComment ""]
    # Does Alpha know what mode this is?  If not, send an alertnote.  If so,
    # determine the comment characters for the mode.
    if {($modeName eq "Text")} {
	alertnote "Alpha doesn't recognize the mode for this example,\
	  and will open it in as plain text."    
    } elseif {($modeName ne "")} {
	status::msg "Loading mode ${modeName}..."
	loadAMode $modeName
	set begComment [string trim [comment::Characters General [list $modeName]]]
	if {($begComment eq "")} {
	    set commentChars [comment::Characters Paragraph [list $modeName]]
	    set endComment   [string trim [lindex $commentChars 1]]
	    set begComment   [string trim [lindex $commentChars 0]]
	}
    }
    if {($begComment eq "")} {
	set begComment ">"
    }
    # Create the basic helper template.
    set intro {
	None of the changes you make will affect the actual file.  If you close
	the window and then click on the hyperlink again, you will start with the
	same example as before.  This also means that you cannot send this window
	to other applications - technically, it doesn't exist as a file, which
	also means that 'undo' is turned off, not available.
    }
    # If we have a mode, add extra text to the basic template.
    if {($modeName eq "")} {
	set t $intro
    } else {
	set ModeName [mode::getName $modeName 1]
	append t "\r" \
	  "'${ModeName}' mode example: modify this window as much as you like !\r" \
	  $intro "\r" \
	  "Press Control-Help to open any available help for '${ModeName}' mode." \
	  "\r"
	# Find out if there's a tutorial available for this mode.
	set completionFolders [list [file join $HOME Tcl Completions]]
	foreach domain [list "local" "user"] {
	    if {($SUPPORT($domain) ne "")} {
		lappend completionFolders \
		  [file join $SUPPORT($domain) AlphaTcl Tcl Completions]
	    }
	}
	foreach completionFolder $completionFolders {
	    set pattern "$modeName Tutorial.*"
	    if {[llength [glob -nocomplain -dir $completionFolder $pattern]]} {
		append t "\r'${ModeName}' mode also has a " \
		  "\"Completions Tutorial\" available" \
		  "\rin the Config > Mode Prefs menu.\r"
	    }
	    break
	}
    }
    # Now 'wrap' each line in comment characters.
    foreach line [split $t "\r\n"] {
	if {([set line [string trim $line]] eq "")} {
	    lappend lines ""
	} else {
	    lappend lines "$begComment $line $endComment"
	}
    }
    set t [join $lines "\r"]
    append t "\r" $begComment " " [string repeat = 72] " " $endComment "\r\r"
    return $t
}

## 
 # --------------------------------------------------------------------------
 # 
 # "help::openHyper" --
 # 
 # Called by embedded hyperlinks; we look through an installation directory
 # (and subdirs) if it is known, then the prefs directory, then all of the
 # auto_path.  If it is a tutorial shell, find the proper mode and open it
 # in a shell window.  Otherwise, if the file is of type TEXT we open it as
 # read-only, else we ask the finder to open it.
 #  
 # --------------------------------------------------------------------------
 ##

proc help::openHyper {name {quietly 0}} {

    global HOME PREFS smarterSourceFolder auto_path

    # If this is a "prefs.tcl" or a "<mode>Prefs.tcl" file, attempt
    # to open it using standard procedures.
    if {[regsub -nocase {Prefs.tcl} $name {} m]} {
	if {$m != ""} {
	    # Edit a <mode>Prefs.tcl file, prompting to create if necessary.
	    mode::editPrefsFile $m
	} else {
	    # Edit a prefs.tcl file, creating one if necessary.
	    prefs::editPrefsFile
	}
	return 1
    }
    # Create a list of all possible directories in which we'll search for a
    # file.  First add the current directory, and then its hierarchy.
    lappend directories [set currDir [file dirname [win::Current]]]
    foreach d [glob -types d -dir $currDir -nocomplain -- *] {
	lappend directories [string trimright $d [file separator]]
    }
    # Add the user's "smarterSource" directory if it exists.
    if {[info exists smarterSourceFolder]} {
	lappend directories $smarterSourceFolder
    }
    # Add the PREFS directory.
    lappend directories $PREFS
    # Add the "Help" and "Examples" directories.
    foreach dir [list "Help" "Examples"] {
	lappend directories [file join $HOME $dir]
    }
    # Now add everything in the auto_path, and begin looking for the file.
    foreach d [lunique [concat $directories $auto_path]] {
	set f [file join $d $name]
	if {[file exists $f]} {
	    if {[regsub { +Tutorial.*$} $name {} m]} {
		# This is a tutorial, so open it in a shell window
		if {[mode::exists $m]} {
		    mode::completionsTutorial $m
		} else {
		    mode::completionsTutorial [win::FindMode $f]
		}
	    } elseif {[file::getType $f] == {TEXT}} {
		# Type is Text, so open as read-only
		edit -r -c $f
	    } else {
		# Unknown type, so prompt user
		file::openAny $f 
	    }
	    return 1
	}
    }
    # Still here?
    if {!$quietly} {
        alertnote "Sorry, couldn't find $name"
    } 
    return 0
}

proc help::openSource {path} {
    
    global HOME
    
    lappend places [list $HOME Developer Source]
    lappend places [list $HOME Source]
    foreach place $places {
	set fname [eval [list file join] $place $path]
	if {[file exists $fname]} then {
	    file::openQuietly $fname
	    return 1
	}
    }
    alertnote "I'm afraid you don't have that file."
    return 0
}

# urlView or url::execute
proc help::openAlphaHomePage {} {
    
    global alpha::platform alpha::macos
    
    if {($alpha::platform eq "tk")} {
	url::execute "http://www.purl.org/net/alpha/alphatk"
    } elseif {($alpha::macos == 1)} {
	url::execute "http://www.purl.org/net/alpha/alpha8"
    } else {
	url::execute "http://www.purl.org/net/alpha/alphaX"
    }
}


## 
 # --------------------------------------------------------------------------
 # 
 # "help::openPrefsDialog" --
 # 
 # Called by embedded hyperlinks; open a specific preferences dialog, for all
 # of global preference dialog panes, recognized packages or modes, etc.
 # These hyperlink are created using the strings
 # 
 #     preferences: <packageName>
 #     Preferences: <packageName>
 # 
 # Here's some examples:
 # 
 #     preferences: Appearance 
 #     preferences: Menus
 #     Preferences: InterfacePreferences
 #     Preferences: supersearch
 #     
 #     Preferences: Mode-Bib
 #     Preferences: Mode-Menus
 #     Preferences: Mode-Features
 #     Preferences: Mode-Features-Bib
 # 
 # Excepting the 'switch' elements in the proc below, "packageName" must be
 # exact with respect to case.  'specialKeys' is the same as 'SpecialKeys',
 # but 'appearance' is _not_ the same as "Appearance" or "APPEARANCE".  There
 # is a special case for packageNames ending in 'Mode', as in 'BibMode'.
 # This is mainly in place because 'Text' opens the global 'Text' dialog pane
 # found in the dialog for "InterfacePreferences".  After checking a variety
 # of special cases, "$packageName" is shipped off to the dialog procedure
 # [prefs::dialogs::globalPrefs] so this is an easy test to determine if the
 # hyperlink will work or not.
 # 
 # Note that this proc will never return an error, and there's no guarantee
 # that the user will be notified as to why something didn't work, so please
 # double-check any hyperlinks which call this item.
 #  
 # --------------------------------------------------------------------------
 ##

proc help::openPrefsDialog {item} {
    
    global mode flagPrefs varPrefs alpha::prefs alpha::packageRequirementsFailed
    
    variable lastChosenMode
    
    watchCursor
    # Preliminaries.
    if {([string tolower $item] eq "helper applications")} {
	prefs::dialogs::externalHelpers
	return
    }
    if {[regsub -nocase -- {^Mode-?} $item "" modePref]} {
	# This is a mode prefs items.
	set m ""
	set modeArgs [split $modePref "-"]
	switch --  [lindex $modeArgs 0] {
	    "Menus"    {set which "Menus"    ; set m [lindex $modeArgs 1]}
	    "Features" {set which "Features" ; set m [lindex $modeArgs 1]}
	    default    {set which "Prefs"    ; set m [lindex $modeArgs 0]}
	}
	# This code path used to check if we had an open window and
	# return if not.  But there's no good reason that we need
	# such a thing.
	if {($m eq "")} {
	    set m [listpick -p "Choose a mode:" \
	      -L [list $lastChosenMode] [mode::listAll 1 1]]
	    watchCursor
	} 
	set M [mode::getName $m 1]
	set m [mode::getName $m 0]
	set lastChosenMode $M
	loadAMode $m
	switch -- $which {
	    "Menus"    {catch {mode::menus $m}}
	    "Features" {catch {mode::features $m}}
	    "Prefs"    {catch {prefs::dialogs::modePrefs $m}}
	}
	return
    } elseif {[regsub -nocase -- {^Helper(App)?s-} $item "" xservname]} {
	if {([lsearch [::xserv::listOfServices "nobundle"] $xservname] == -1)} {
	    alertnote "Sorry, no \"Xserv\" external service helper\
	      has been defined for $xservname."
	    return
	}
	xserv::setImplementationFor $xservname
	alertnote "The new setting for the \"$xservname\"\
	  external service helper has been saved."
	return
    } elseif {[info exists flagPrefs($item)] || [info exists varPrefs($item)]} {
	prefs::dialogs::globalPrefs $item
	return
    } elseif {[alpha::package exists $item]} {
	set Item [quote::Prettify $item]
	if {([lsearch ${alpha::packageRequirementsFailed} $item] > -1)} {
	    set msg "Sorry, the \"${Item}\" package is not available."
	    if {![dialog::yesno -y "OK" -n "More Info" $msg]} {
		help::openGeneral "Packages" "Incompatible Packages"
	    }
	    return
	} 
	# This is a package.
	set q "The package \"${item}\" is not active -- do you\
	  want to activate it before trying to set its preferences?"
	if {![package::active $item] && [askyesno $q]} {
	    watchCursor
	    package::activate $item
	} 
	watchCursor
	if {[info exists alpha::prefs($item)]} {
	    # Redirect to prefs array specified in [prefs::addPrefsDialog].
	    prefs::dialogs::packagePrefs [set alpha::prefs($item)]
	} else {
	    prefs::dialogs::packagePrefs $item
	}
	return
    }
    # Open the appropriate preferences dialog.
    watchCursor
    regsub -all -- {\s+} $item {} item
    switch -- [string tolower $item] {
	"contextualmenu" {
	    # Open the dialog for contextual menu modules.
	    contextualMenu::contextualMenuItems
	}
	"features" {
	    # Open the "Config > Global Setup > Features" dialog.
	    prefs::dialogs::globalMenusFeatures "features"
	}
	"helperapps" - "helperapplications" {
	    # Open the "Config > Global Setup > Helper Applications" dialog.
	    prefs::dialogs::externalHelpers
	}
	"menus" {
	    # Open the "Config > Global Setup > Menus" dialog.
	    prefs::dialogs::globalMenusFeatures "menus"
	}
	"specialkeys" {
	    # Open the "Config > Special Keys" dialog.
	    global::specialKeys
	}
	"suffixmappings" {
	    # Open the "Config > Global Setup > Suffix Mappings"
	    # dialog.
	    prefs::dialogs::fileMappings
	}
	default {
	    # Hopefully a global preferences dialog ...
	    prefs::dialogs::globalPrefs $item
	}
    }
    return
}

# This is a variation of [editMark].

proc help::goToSectionMark {args} {
    
    win::parseArgs w markName
    # First find out if we have any marks at all ...
    if {![llength [set markList [getNamedMarks -w $w -n]]]} {
	catch {hook::callProcForWin MarkFile}
	if {![llength [set markList [getNamedMarks -w $w -n]]]} {
	    alertnote "This window does not contain any section marks."
	    return 0
	}
    }
    # Manipulate mark, marks list.
    lappend markList $markName
    foreach mark $markList {
	lappend marks1 $mark
	lappend marks2 [string trimleft $mark]
	lappend marks3 [string trim $mark]
	lappend marks4 [string tolower [string trim $mark]]
    }
    # Now try to find the mark.
    for {set n 1} {$n <= 4} {incr n} {
	set mark  [lindex [set marks$n] end]
	set marks [lrange [set marks$n] 0 end-1]
	if {[set idx [lsearch -exact $marks $mark]] > -1} {
	    gotoMark -w $w [lindex $markList $idx]
	    return 1
	} 
    }
    # Still here? Try one last ditch effort.
    if {[editMark $w $markName]} {
	return 1
    }
    alertnote "Couldn't find the section mark '${markName}'"
    return 0
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Help Window support ×××× #
# 
# The procedures in this section all support the presentation of Help
# windows, and could possibly be placed in a new SystemCode file named
# something like "alphaHelpWindows.tcl"
# 

# ×××× Mark Colour Hyper ×××× #

## 
 # ----------------------------------------------------------------------
 #       
 # "help::markColourAndHyper" --
 #      
 # A general purpose procedure that attempts to colour, mark, and hyperise
 # the current open window in a manner specific to the type of help file
 # that we seem to be dealing with.  Any code that wants to mark etc a help
 # window in the "Alpha Manual" format just needs to call this proc.
 # 
 # ----------------------------------------------------------------------
 ##

proc help::markColourAndHyper {args} {
    
    global HelpmodeVars HelpmodeVars alpha::platform
    
    win::parseArgs w
    
    requireOpenWindow
    if {[icon -f $w -q]} {
	icon -f $w -o
    }
    # Make sure that we don't have old colours in a new file.  This
    # is important both for Alpha 8/X (where the resource fork may be
    # older than the data fork) and for Alphatk (where the remember
    # windows package will act as a virtual resource fork which again
    # may be out of date).
    help::confirmFileStamp $w

    help::sizeHelpWindow $w
    set mode [win::getMode $w]
    # Should we continue?
    if {[lsearch -exact [list "Chng" "Help" "man" "Text" "Setx"] $mode] == -1} {
	return
    }
    if {(${alpha::platform} eq "alpha") && [llength [getColors -w $w]]} {
	return
    }
    # More preliminaries ...
    watchCursor
    status::msg "Please wait: Colouring and marking the help file"
    # Now go through all of the routines relevant for this window.
    help::hyperiseEmails -w $w 1
    help::hyperiseUrls -w $w 1
    help::colourCodeInserts $HelpmodeVars(codeInsertsColour)
    switch -- [help::markHelpFile -w $w 1] {
	"Alpha Changes" {
	    # help::hyperiseExtras 1
	    help::colourTitle -w $w $HelpmodeVars(titleColour)
	}
	"Alpha Commands" {
	    help::colourTitle -w $w $HelpmodeVars(titleColour)
	    # Obsolete procs are always coloured red, transitional (those now
	    # defined in AlphaTcl) are magenta.
	    help::colourAlphaCommands -w $w \
	      $HelpmodeVars(alphaCommandsColour) 5 4
	    help::hyperiseExtras -w $w 1
	}
	"Alpha Manual" {
	    help::colourTitle -w $w $HelpmodeVars(titleColour)
	    help::colourMarks -w $w $HelpmodeVars(manualMarksColour) 1
	    help::hyperiseExtras -w $w 1
	}
	"Reference Manual" {
	    help::colourTitle -w $w $HelpmodeVars(titleColour)
	    help::colourMarks -w $w $HelpmodeVars(referenceMarksColour) 0
	    help::colourAllCapLines -w $w $HelpmodeVars(allCapsColour)
	    help::hyperiseExtras -w $w 1
	}
    }
    # Now try to save this info so that we don't have to do this again.
    help::saveResourceChanges $w
    status::msg ""
    return
}

## 
 # ----------------------------------------------------------------------
 #       
 # "help::confirmFileStamp" --
 # 
 # This will help us to automatically update the marks/colours/hypers when
 # the user updates via the cvs.  We only delete the info if we've seen
 # this window before and we now have a newer modified date.
 #      
 # ----------------------------------------------------------------------
 ##

proc help::confirmFileStamp {winName} {
    
    global helpFileStamps
    
    set fileName [win::StripCount $winName]
    set fileTail [file tail $fileName]
    # Make sure this is an actual file, but not the "Packages" file.
    if {![file isfile $fileName] || $fileTail == "Packages"} {return}
    set modified [file mtime $fileName]
    # Have we seen this one before?
    if {[info exists helpFileStamps($fileTail)]} {
	# File was previously marked ...
	if {($helpFileStamps($fileTail) eq $modified)} {
	    return
	}
	# ... but has since been modified.
	help::removeCHMCleanly $fileName
    } 
    # Still here? Save the modified time stamp.
    set helpFileStamps($fileTail) $modified
    prefs::modified helpFileStamps($fileTail)
    return
}

## 
 # ----------------------------------------------------------------------
 #       
 # "help::sizeHelpWindow" --
 # 
 # Adjust the Help window to suit the user's preference.
 #      
 # This used to be registed as an 'openHook' for all Text mode files, but
 # that meant that we would call the proc for any Text mode file opened. 
 # Now we only call it if we're about to color/hyper a file, which means
 # that if that info is saved in the resource fork (or elsewhere) we retain
 # the previous window geometry set by the user.
 # 
 # ----------------------------------------------------------------------
 ##

proc help::sizeHelpWindow {winName} {
    
    global HOME helpFileWindowSize
    
    if {[win::IsFile $winName]} {
	set test [file::pathStartsWith $winName [file join $HOME Help]]
    } else {
	set test [string match {\* '*' Help \*} $winName]
    }
    if {$test} {
	if {[set size $helpFileWindowSize] == "Don't Change"} {return}
	# Wish that we had 'quote::Unprettify' or 'quote::Unmenuify' ...
	set s [string tolower [string index $size 0]]
	regsub -all { +} [string range $size 1 end] {} ize
	eval ${s}${ize}
    } 
    return
}

## 
 # ----------------------------------------------------------------------
 #       
 # "help::saveResourceChanges" --
 # 
 # Save all marks/colours/hypers in the MacOS file's resource fork.
 # 
 # ----------------------------------------------------------------------
 ##

proc help::saveResourceChanges {winName} {
    if {$alpha::platform eq "tk"} { return }
    
    catch {setWinInfo -w $winName read-only 0}
    setWinInfo -w $winName state mpw
    if {[win::IsFile $winName path] && [file tail $path] != "Packages"} {
	file::saveResourceChanges $winName
    }
    setWinInfo -w $winName dirty 0
    setWinInfo -w $winName read-only 1
    refresh -w $winName

    return
}

# ×××× Window Marks ×××× #

## 
 # ----------------------------------------------------------------------
 #       
 # "help::markHelpFile" --
 #      
 # Attempt to determine what type of Help file we're dealing with, mark it
 # accordingly, and return the "type" to the calling procedure.
 # 
 # ----------------------------------------------------------------------
 ##

proc help::markHelpFile {args} {
    
    win::parseArgs w {quietly 0}
    
    requireOpenWindow
    removeAllMarks -w $w
    
    set mode [win::getMode $w]
    
    # Try to determine the type of help file that we're dealing with.
    set tail [win::Tail $w]
    set pat1 "^\[\t \]*NAME\[\t \]*\$"
    set pat2 "^\t  \t"
    if {($tail eq "Alpha Commands")} {
	# The "Alpha Commands" file.
	help::markAsAlphaCommands $quietly
	set type "Alpha Commands"
    } elseif {($mode eq "Chng") || [regexp "Changes.*Alpha" $tail]} {
	# A "Changes - Alpha*" file.  Hopefully Chng mode is installed.
	catch {Chng::MarkFile}
	set type "Alpha Changes"
    } elseif {![catch {search -w $w -s -f 1 -r 1 -- $pat1 [minPos -w $w]}]} {
	# This is a unix style reference file
	help::markAsReferenceManual -w $w $quietly
	set type "Reference Manual"
    } elseif {![catch {search -w $w -s -f 1 -r 1 -- $pat2 [minPos -w $w]}]} {
	# Mark it as an Alpha Manual
	help::markAsAlphaManual -w $w $quietly
	set type "Alpha Manual"
    } elseif {($mode eq "Text") || ($mode eq "Help")} {
	help::markAsAlphaManual -w $w $quietly
	set type "Alpha Manual"
    } else {
	# ??
	catch {markFile -w $w}
	set type "Unknown"
    } 
    return $type
}

## 
 # ----------------------------------------------------------------------
 #       
 # "help::markAsAlphaManual" --
 #      
 # Use our special "\t  \t" convention to determine file marks.
 # 
 # Original by Pete Keheler.
 # 
 # ----------------------------------------------------------------------
 ##

proc help::markAsAlphaManual {args} {
    
    win::parseArgs w {quietly 0}
    
    removeAllMarks -w $w
    
    if {!$quietly} {
	status::msg "Marking Alpha help fileÉ"
    }
    set pos [minPos -w $w]
    set pat {^((\t  \t)|(\t[\t ]*==+[\t ]*$))}
    while {![catch {search -w $w -f 1 -r 1 -s $pat $pos} match]} {
	set pos0  [lindex $match 0]
	set pos1  [lindex $match 1]
	set pos   [pos::nextLineStart -w $w $pos1]
	if {[regexp {^==+$} [string trim [getText -w $w $pos0 $pos]]]} {
	    set mark "-"
	} elseif {![string length [string trim [getText -w $w $pos1 $pos]]]} {
	    continue
	} else {
	    regsub -all "\t" [string trimright [getText -w $w $pos1 $pos]] " " mark
	}
	while {[lcontains marks $mark]} {
	    append mark " "
	}
	lappend marks $mark
	set pos2 [pos::lineStart -w $w \
	  [pos::math -w $w [pos::lineStart -w $w $pos1] - 1]]
	setNamedMark -w $w $mark $pos2 $pos0 $pos0
    }
    if {!$quietly} {
	status::msg "Marking Alpha help fileÉ complete."
    }
    return
}

## 
 # ----------------------------------------------------------------------
 #       
 # "help::markAsReferenceManual" --
 #      
 # An alternative marking scheme for command reference files, generally
 # viewed in unix using 'man' or 'nroff'.
 # 
 # See "Tcl Commands" or "Error Help" for examples.
 # 
 # If the manual has only one command (such as the "Regular Expressions"
 # file) then we instead mark the sections found within it.
 # 
 # ----------------------------------------------------------------------
 ##

proc help::markAsReferenceManual {args} {
    
    win::parseArgs w {quietly 0}
    
    removeAllMarks -w $w
    
    if {!$quietly} {
	status::msg "Marking Reference CommandsÉ"
    }
    set msgExtra ""
    set commands 0
    set pos  [minPos -w $w]
    set pat1 "^\[\t \]*NAME\[\t \]*\$"
    set pat2 "\[^ \t\r\n\]+"
    while {![catch {search -w $w -s -f 1 -r 1 -i 0 $pat1 $pos} match1]} {
	set posDisplay [pos::prevLineStart -w $w [lindex $match1 0]]
	set match2 [search -w $w -s -n -f 1 -r 1 $pat2 [lindex $match1 1]]
	if {[llength match2]} {
	    set posTextBeg [lindex $match2 0]
	    set posTextEnd [lindex $match2 1]
	    set mark [eval [list getText -w $w] $match2]
	    while {[lcontains marks $mark]} {
		append mark " "
	    }
	    lappend marks $mark
	    setNamedMark -w $w $mark $posDisplay $posTextBeg $posTextEnd
	    incr commands
	    set pos [pos::nextLineStart -w $w $posTextEnd]
	} else {
	    set pos [pos::nextLineStart -w $w [lindex $inds 1]]
	}
	set msgExtra "$commands commands in this window."
    }
    # Does this reference manual only deal with one command?
    if {([llength [getNamedMarks -w $w -n]] == 1)} {
	set marks [list]
	removeAllMarks -w $w
	set pos [minPos -w $w]
	set pat {^[A-Z][A-Z0-9:\t ]+$}
	while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 0 $pat $pos} match]} {
	    set pos0 [lindex $match 0]
	    set pos1 [lindex $match 1]
	    set mark [string trim [getText -w $w $pos0 $pos1]]
	    set pos2 [set pos [pos::nextLineStart -w $w $pos1]]
	    if {$mark == "NAME"} {
		set mark [getText -w $w $pos2 [pos::nextLineStart -w $w $pos2]]
		regsub { \- .+$} [string trim $mark] {} mark
	    }
	    set mark [markTrim $mark]
	    while {[lcontains marks $mark]} {
		append mark " "
	    }
	    lappend marks $mark
	    setNamedMark -w $w $mark $pos0 $pos0 $pos0
	}
	set msgExtra "[llength $marks] sections in this window."
    } 
    if {!$quietly} {
	status::msg "Marking Reference CommandsÉ complete. $msgExtra"
    }
    return
}

## 
 # ----------------------------------------------------------------------
 #       
 # "help::markAsAlphaCommands" --
 #      
 # Special file marking routine for the "Alpha Commands" file.
 # 
 # Original by Pete Keheler.
 # 
 # ----------------------------------------------------------------------
 ##

proc help::markAsAlphaCommands {args} {
    
    win::parseArgs w {quietly 0}
    
    removeAllMarks -w $w
    
    if {!$quietly} {
	status::msg "Marking Alpha CommandsÉ"
    }
    
    set marks [list]
    set pos [minPos -w $w]
    set pat {^= }
    while {![catch {search -w $w -s -f 1 -r 1 $pat $pos} inds]} {
	set pos1 [lindex $inds 1]
	set pos2 [pos::lineEnd -w $w $pos1]
	set pos3 [pos::prevLineStart -w $w $pos1]
	set txt  "¥ [getText -w $w $pos1 [pos::lineEnd -w $w $pos1]]"
	lappend marks [list $txt $pos2 $pos2 $pos1 $pos2]
	set pos [pos::nextLineStart -w $w $pos1]
    }
    set pos [minPos -w $w]
    set pat {^¥ }
    while {![catch {search -w $w -s -f 1 -r 1 $pat $pos} inds]} {
	set pos1  [lindex $inds 1]
	set match [search -w $w -s -n -f 1 -r 1 "\[^ \t\r\n\]+" $pos1]
	if {[llength $match]} {
	    set txt  [eval [list getText -w $w] $match]
	    set pos2 [lindex $match 0]
	    set pos3 [lindex $match 1]
	    lappend marks [list $txt $pos1 $pos1 $pos2 $pos3]
	}
	set pos [pos::nextLineStart -w $w $pos1]
    }
    # Sort the marks alphabetically.
    foreach mark [lsort -dictionary $marks] {
	set name [lindex $mark 0]
	set disp [lindex $mark 2]
	set pos  [lindex $mark 3]
	set end  [lindex $mark 4]
	while {[lcontains names $name]} {
	    append name " "
	}
	lappend names $name
	setNamedMark -w $w $name $disp $pos $end
    }
    if {!$quietly} {
	status::msg "Marking Alpha CommandsÉ complete.\
	  [llength $marks] commands in this window."
    }
    return
}

# ===========================================================================
# 
# ×××× Window Colours ×××× #
# 
# All of the colour procs in this section should be given default colours
# to use, else the user will be presented with a 'listpick' dialog.  If a
# default colour is given, however, no 'refresh' will be performed, and the
# calling code will have to do that itself.  (This allows for several of
# these procs to be called in succession without the user seeing a bunch of
# jerky window behavior.

proc help::colourTitle {args} {
    
    win::parseArgs w {colour ""}
    
    # Make sure that we have a colour.  If not, it is most likely being
    # called via a menu item so we'll refresh at the end.
    set quietly 1
    if {![string length $colour]} {
	set colour [help::chooseColour]
	set quietly 0
    } else {
	set colour [help::convertColour $colour]
    }
    # Colour, underline the title.
    if {!$quietly} {
	status::msg "Colouring, underlining the window titleÉ"
    }
    set pos [minPos -w $w]
    set pat {[a-zA-Z0-9]}
    while {![catch {search -w $w -s -f 1 -r 1 -- $pat $pos} match]} {
	set pos0 [lindex $match 0]
	set pos1 [pos::lineEnd -w $w $pos0]
	if {[regexp {[-a-zA-Z0-9+]+-\*-} [getText -w $w $pos0 $pos1]]} {
	    set pos [pos::nextLineStart -w $w $pos0]
	    continue
	} else {
	    text::color -w $w $pos0 $pos1 $colour
	    text::color -w $w $pos0 $pos1 15
	    break
	}
    } 
    if {!$quietly} {
	refresh -w $w
	status::msg "Colouring, underlining the window titleÉ complete."
    }
    return
}

proc help::colourMarks {args} {
    
    win::parseArgs w {colour ""} {underline 0}
    
    # Make sure that we have a colour.  If not, it is most likely being
    # called via a menu item so we'll refresh at the end.
    set quietly 1
    if {![string length $colour]} {
	set colour [help::chooseColour]
	set quietly 0
    } else {
	set colour [help::convertColour $colour]
    }
    watchCursor
    # Colour each mark.
    if {!$quietly} {
	status::msg "Coloring all window marksÉ"
    }
    foreach mark [getNamedMarks -w $w] {
	if {[set name [string trim [lindex $mark 0]]] == "-"} {
	    continue
	}
	set pos [lindex $mark 2]
	if {![catch {search -w $w -s -f 1 -r 0 -- $name $pos} match]} {
	    set pos0 [lindex $match 0]
	    set pos1 [lindex $match 1]
	    text::color -w $w $pos0 $pos1 $colour
	    if {$underline} {
		text::color -w $w $pos0 $pos1 15  
	    } 
	} 
    }
    if {!$quietly} {
	refresh -w $w
	status::msg "Coloring all window marksÉ complete."
    }
    return
}

proc help::underlineMarks {args} {
    
    win::parseArgs w {quietly 0}
    
    watchCursor
    # Underline each mark.
    if {!$quietly} {
	status::msg "Underlining all window marksÉ"
    }
    foreach mark [getNamedMarks -w $w] {
	if {[set name [string trim [lindex $mark 0]]] == "-"} {
	    continue
	}
	set pos [lindex $mark 2]
	if {![catch {search -w $w -s -f 1 -r 0 -- $name $pos} match]} {
	    set pos0 [lindex $match 0]
	    set pos1 [lindex $match 1]
	    text::color -w $w $pos0 $pos1 15
	} 
    }
    if {!$quietly} {
	refresh -w $w
	status::msg "Underlining all window marksÉ complete."
    }
    return
}

## 
 # --------------------------------------------------------------------------
 #       
 # "help::colourCodeInserts" --
 # 
 # Color blocks of text that are offset by a Tab.  The first line must have
 # some non-whitespace text following the first Tab, and each subsequent line
 # must begin with a Tab even if it an "empty" line.  The block is ended by
 # any line that does _not_ start with a Tab.
 # 
 # The regexp used to be
 # 
 # {^[ \t]*[\r\n]\t[^¥" \t\r\n][^\n\r]*[\r\n](\t([ \t]*[\r\n]|[ \t]*[^ \t\r\n]+[^\n\r]*[\r\n]))*[ \t]*[\r\n]}
 # 
 # which worked well in Alpha7 (with no offset of the final position) but for
 # some reason this isn't handled the same with Tcl 8.4 regexp searching, and
 # failed to properly capture entire blocks of code that had "empty" lines.
 # 
 # --------------------------------------------------------------------------
 ##

proc help::colourCodeInserts {args} {
    
    win::parseArgs w {colour ""}
    
    watchCursor
    # Make sure that we have a colour.  If not, it is most likely being
    # called via a menu item so we'll refresh at the end.
    set quietly 1
    if {![string length $colour]} {
	set colour [help::chooseColour "for code inserts"]
	set quietly 0
    } else {
	set colour [help::convertColour $colour]
    }
    if {!$quietly} {
	status::msg "Colouring all code insertsÉ"
    }
    # Colour code inserts.
    set pat {^\t[^ \t\r\n][^\r\n]*(eol\t[^\r\n]*)*eol(eol|[^\t])}
    regsub -all -- "eol" $pat {(\r|(\r?\n))} pat
    win::searchAndHyperise -w $w $pat {} 1 $colour 0 -1
    if {!$quietly} {
	refresh -w $w
	status::msg "Colouring all code insertsÉ complete."
    }
    return
}

proc help::colourAlphaCommands {args} {
    
    global alphaObsCommands alphaKeyWords
    
    win::parseArgs w {colour1 ""} {colour2 ""} {colour3 ""}
    
    watchCursor
    # Make sure that we have a colour.  If not, it is most likely being
    # called via a menu item so we'll refresh at the end.
    set quietly 1
    if {![string length $colour1]} {
	set colour1 [help::chooseColour "for normal commands"]
	set quietly 0
    } else {
	set colour1 [help::convertColour $colour1]
    }
    if {![string length $colour2]} {
	set colour2 [help::chooseColour "for obsolete commands"]
	set quietly 0
    } else {
	set colour2 [help::convertColour $colour2]
    }
    if {![string length $colour3]} {
	set colour3 [help::chooseColour "for former commands"]
	set quietly 0
    } else {
	set colour3 [help::convertColour $colour3]
    }
    if {!$quietly} {
	status::msg "Colouring Alpha CommandsÉ"
    }
    # Do we have the AlphaDev menu handy?
    if {[catch alphaDeveloperMenu.tcl] || ![info exists alphaObsCommands]} {
	set coreCommands [list]
	set obsCommands  [list]
    } else {
	set coreCommands $alphaKeyWords
	# These generally aren't included in the obs command list, because
	# they're defined as Tcl commands.
	set obsCommands [concat $alphaObsCommands "bind" "unbind" "mkdir"]
    }
    # Colour each mark.  We assume that if a command is not defined as either
    # a core or an obsolete command, it is transitional, defined in AlphaTcl.
    set pos [minPos -w $w]
    set pat "^¥ \[a-zA-Z0-9:_&]+"
    while {![catch {search -w $w -s -f 1 -r 1 -- $pat $pos} match]} {
	set pos0 [pos::math -w $w [lindex $match 0] + 2]
	set pos1 [lindex $match 1]
	set txt  [getText -w $w $pos0 $pos1]
	if {([lsearch -exact $coreCommands $txt] > "-1")} {
	    set colour $colour1
	} elseif {([lsearch -exact $obsCommands $txt] > "-1")} {
	    set colour $colour2
	} else {
	    set colour $colour3
	}
	text::color -w $w $pos0 $pos1 $colour
	set pos [pos::nextLineStart -w $w $pos1]
    }
    # Colour all lines starting with "="
    set pos [minPos -w $w]
    set pat "^=\[^\r\n\]*\[\r\n\]"
    while {![catch {search -w $w -s -f 1 -r 1 -- $pat $pos} match]} {
	set pos0 [lindex $match 0]
	set pos1 [lindex $match 1]
	text::color $pos0 $pos1 5
	set pos [pos::nextLineStart -w $w $pos1]
    }
    if {!$quietly} {
	refresh -w $w
	status::msg "Colouring Alpha CommandsÉ complete."
    }
    return
}

proc help::colourAllCapLines {args} {
    
    win::parseArgs w {colour ""}
    
    watchCursor
    # Make sure that we have a colour.  If not, it is most likely being
    # called via a menu item so we'll refresh at the end.
    set quietly 1
    if {![string length $colour]} {
	set colour [help::chooseColour]
	set quietly 0
    } else {
	set colour [help::convertColour $colour]
    }
    if {!$quietly} {
	status::msg "Colouring ALL CAP stringsÉ"
    }
    # Search and color lines with all CAP words, allowing one final
    # piece of punctuation or small letter 
    # (seems to be necessary for Tcl 8.4 commands)
    set pos [minPos -w $w]
    set pat {^[A-Z][-A-Z,\t ]+[^\r\n]?$}
    while {![catch {search -w $w -s -f 1 -r 1 -i 0 $pat $pos} inds]} {
	eval [list text::color -w $w] $inds [list $colour]
	set pos [pos::nextLineStart -w $w [lindex $inds 0]]
    }
    if {!$quietly} {
	refresh -w $w
	status::msg "Colouring ALL CAP stringsÉ complete."
    }
    return
}

proc help::chooseColour {{extraPrompt ""} {defaultColour ""}} {
    
    variable Colours 
    variable LastColourChosen
    
    set p "Choose a colour ${extraPrompt}:"
    if {![string length $defaultColour]} {
	set defaultColour [set help::LastColourChosen]
    } 
    if {[catch {listpick -p $p -L $defaultColour \
      [set help::Colours]} colour]} {
	error "cancel"
    } 
    set LastColourChosen $colour
    return [help::convertColour $colour]
}

proc help::convertColour {colour} {
    
    variable Colours
    
    if {[is::PositiveInteger $colour]} {
	return $colour
    } elseif {[set colour [lsearch -exact $Colours $colour]] != "-1"} {
	return $colour
    } else {
	return 0
    }
}

# ===========================================================================
# 
# ×××× Window Hypers ×××× #
# 
# Unlike the 'Help Window Colours' procs, by default we always use the colour
# preferences that have already been set, and the only argument that should
# be passed is 'quietly', which determines if we should refresh and give a
# message at the end.

## 
 # ----------------------------------------------------------------------
 #       
 #  "help::hyperiseUrls" --
 #  "help::hyperiseEmails" --
 #      
 #  This attaches hypertext links to all '<http:...  >' or '<mailto...>'
 #  strings in a document.  This procedure works best on files in Text
 #  mode; in other modes the colouring schemes can make the links invisible
 #  (although they still function).
 #      
 # ----------------------------------------------------------------------
 ##

proc help::hyperiseUrls {args} {
    
    global HelpmodeVars
    
    win::parseArgs w {quietly 0}

    # Make sure that we have a colour.
    if {![info exists HelpmodeVars(urlsColour)]} {
	set colour [help::chooseColour "for e-mails"]
    } else {
	set colour [help::convertColour $HelpmodeVars(urlsColour)]
    }
    watchCursor
    if {!$quietly} {
	status::msg "Colouring and hyperising all url stringsÉ"
    }
    set pattern {<((https?|news|mailto|ftp|afp|smb):[^ >]*)>}
    # Could use {urlView "\1"} here to use the WWW menu if desired.
    set script  {url::execute "\1"}
    win::searchAndHyperise -w $w $pattern $script 1 $colour
    if {!$quietly} {
	refresh -w $w
	status::msg "Colouring and hyperising all url stringsÉ complete."
    }
    return
}

proc help::hyperiseEmails {args} {
    
    global HelpmodeVars
    
    win::parseArgs w {quietly 0}

    # Make sure that we have a colour.
    if {![info exists HelpmodeVars(emailsColour)]} {
	set colour [help::chooseColour "for urls"]
    } else {
	set colour [help::convertColour $HelpmodeVars(emailsColour)]
    }
    watchCursor
    if {!$quietly} {
	status::msg "Colouring and hyperising all e-mail stringsÉ"
    }
    set pattern {<([-+_a-zA-Z0-9.]+@([-+_a-zA-Z0-9.]+))>}
    set script  {composeEmail "mailto:\1"}
    win::searchAndHyperise -w $w $pattern $script 1 $colour
    if {!$quietly} {
	refresh -w $w
	status::msg "Colouring and hyperising all e-mail stringsÉ complete."
    }
    return
}

## 
 # ----------------------------------------------------------------------
 #       
 # "help::hyperiseExtras" --
 #      
 # Create hyperlinks for regexp strings for the following items:
 # 
 # (1) Any "*.tcl" file
 # (2) Any tutorial file 
 # (3) "CLICK|OPEN TO INSTALL"
 # (4) Most help file names
 # (5) "package: <package>"
 # (6) "# <markName>" section marks 
 # (7) Any <<something>> Alpha/Tcl command line
 # (8) "proc: <procedure>"
 # (9) "command: <Alpha core command>"
 # (10) "<Menu Name> > <Menu Item>" indicators
 # (11) "IMPORTANT:"
 #      
 # ----------------------------------------------------------------------
 ##

proc help::hyperiseExtras {args} {
    
    global HOME HelpmodeVars bugzillaHomePage
    
    variable helpFileHyperList
    
    win::parseArgs w {quietly 0}
    
    # Determine the colours to use for hyperising, colouring.
    foreach name [array names HelpmodeVars] {
	set $name $HelpmodeVars($name)
    }
    foreach colorPref [list fileHyperlinks packageHelp \
      sectionTargets alphaTclHyperlinks tclProcs alphaCommands \
      menuDirections importantStrings urls] {
	if {![info exists ${colorPref}Colour]} {
	    set $colorPref \
	      [help::chooseColour "for [quote::Prettify $colorPref]"]
	} else {
	    set $colorPref [help::convertColour [set ${colorPref}Colour]]
	}
    }
    if {!$quietly} {
	status::msg "Colouring and hyperising 'extra' stringsÉ"
    }
    watchCursor
    # Search for "<something>.tcl" and attach appropriate lookup.
    # Search for "<something >Tutorial<.sfx>" and attach appropriate lookup.
    win::searchAndHyperise -w $w \
      {"([-a-zA-Z_+0-9# ]*\.tcl|[-a-zA-Z0-9_+. ][-a-zA-Z0-9_+.# ]*Tutorial([ \.][-a-zA-Z0-9_+. ]*)?)"} \
      {help::openHyper "\1"} \
      1 $fileHyperlinks +1 -1
    # Search for "license.terms" and attach appropriate lookup.
    win::searchAndHyperise -w $w \
      {"license.terms"} \
      "help::openDirect \"[file join $HOME Tcl license.terms]\"" \
      0 $fileHyperlinks +1 -1
    # Search for "<something>Example" and attach appropriate lookup.
    win::searchAndHyperise -w $w \
      {"([-a-zA-Z_+0-9# ]*Example(\.[a-zA-Z0-9_]+)?)"} \
      {help::openExample "\1"} \
      1 $fileHyperlinks +1 -1
    # Help file hyperlinks -- 
    # Search for "<something>Help" etc and attach appropriate lookup.
    # Search for specific Help files and attach appropriate lookup.
    win::searchAndHyperise -w $w \
      {"([a-zA-Z0-9][-a-zA-Z0-9._+#/ ]+(Help|Commands))( # ([^\r\n\"]+))?"} \
      {help::openGeneral "\1" "\4"} \
      1 $fileHyperlinks +1 -1
    win::searchAndHyperise -w $w \
      "\"\([join $helpFileHyperList |]\)( # (\[^\r\n\"\]+))?\"" \
      {help::openGeneral "\1" "\4"} \
      1 $fileHyperlinks +1 -1
    # Search for "CLICK TO INSTALL" etc and attach appropriate lookup.
    # (This will not, however, open the actual 'OPEN-TO-INSTALL' file that
    # might be included with the distribution -- we either need to call a
    # different proc, or [install::installThisPackage] should be modified
    # to look for such an installation script file.)
    win::searchAndHyperise -w $w \
      {\"(CLICK|OPEN)[- A-Z]*INSTALL\"} \
      {install::installThisPackage} \
      1 $fileHyperlinks
    # Search for "package: <something>" and attach appropriate lookup.
    win::searchAndHyperise -w $w \
      {package: ([a-zA-Z0-9][-a-zA-Z0-9._+#/]*)} \
      {help::openGeneral "\1"} \
      1 $packageHelp +9
    # Search for "preferences: <something>" and attach appropriate lookup.
    win::searchAndHyperise -w $w \
      {[Pp]references: ([a-zA-Z0-9][-a-zA-Z0-9._+#/]*)} \
      {help::openPrefsDialog "\1"} \
      1 $alphaTclHyperlinks +13
    # Search for "variable: <something>" and attach appropriate lookup.
    win::searchAndHyperise -w $w \
      {variable: (\$?[-\w:.+]+)} \
      {showVarValue "\1"} \
      1 $alphaTclHyperlinks +10
    # Hyperlink section marks for the current window, anything in double
    # quotes that starts with "# " (similar to html in-file-target.)  Note
    # that you do not need to include extra leading spaces within the quotes.
    win::searchAndHyperise -w $w \
      {"\# +([^ ][^\r\n\"]+)"} \
      {help::goToSectionMark {\1}} \
      1 $sectionTargets +3 -1
    # Search for "<<something>>" and embed as hypertext.
    win::searchAndHyperise -w $w \
      {<<([^>\r\n]+)>>} \
      {\1} \
      1 $alphaTclHyperlinks +2 -2
    # Search for "proc: <something>" and attach appropriate lookup.
    win::searchAndHyperise -w $w \
      {proc: ([-a-zA-Z:\+\.\_]+\w+)} \
      {Tcl::DblClickHelper "\1" ; setWinInfo read-only 1} \
      1 $tclProcs +6 
    # Search for "command: <something>" and attach appropriate lookup.
    win::searchAndHyperise -w $w \
      {command: ([-\w+:\+\.\_]+\w+)} \
      {Tcl::DblClickHelper "\1" ; setWinInfo read-only 1} \
      1 $alphaCommands +9 
    # Search for "Bug# 666" and hyperize to open the bugzilla window.
    win::searchAndHyperise -w $w \
      {((Bug|bug)|(RFE))# +([0-9]+)} \
      "url::execute ${bugzillaHomePage}show_bug.cgi?id=\\4" \
      1 $urlsColour
    # Highlight "<something>-><something>" menu directions
    win::searchAndHyperise -w $w \
      {"[^\r\n"]+( |-)>[^\r\n"]+"|'[^\r\n']+( |-)>[^\r\n']+'} \
      {} \
      1 $menuDirections +1 -1
    # Highlight IMPORTANT bits
    win::searchAndHyperise -w $w \
      {(IMPORTANT|WARNING|TIP):} \
      {} \
      1 $importantStrings
    # Refresh if necessary.
    if {!$quietly} {
	refresh -w $w
	status::msg "Colouring and hyperising 'extra' stringsÉ complete."
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Help File Marking Menu ×××× #
# 
# These procs provide support for "AlphaDev > Help File Marking"
# 

## 
 # ----------------------------------------------------------------------
 #       
 # "help::mimicHelpMenu" --
 #      
 # This proc can be used in the Alpha Developer Menu's "Help File Marking"
 # menu, or called by other code.  Assume that this is for the current
 # open window unless called from a shell prompt.
 #      
 # "help::mimicHelpMenu -choose" will offer a list-pick dialog to select
 # files for pre-marking.
 # 
 # "help::mimicHelpMenu -all" will pre-mark all Help files, useful for
 # public releases of Alpha (not Alphatk).
 # 
 # Both options will only select valid (i.e. Text mode) files in the top
 # level of the Help folder. 
 # ----------------------------------------------------------------------
 ##

proc help::mimicHelpMenu {{files ""}} {
    
    global HOME alpha::platform
    
    set fileList ""
    # Should we select of list of files to mark/hyper ...
    if {$files == "-choose" || $files == "-all"} {
	# Create the list of all valid help files (those in Text mode).
	status::msg "Creating the list of valid Help files\
	  for marking/hyperizing É"
	set helpFiles [help::listTEXTHelpFiles]
	if {$files == "-choose"} {
	    # Offer a list-pick of Help files to mark/hyper.
	    foreach f $helpFiles {
		if {[file isfile $f] && [win::FindMode $f] == "Text"} {
		    lappend helpFileTails [file tail $f]
		} 
	    }
	    set helpTailsList [listpick -l \
	      -p "Choose some Help files to pre-mark" $helpFileTails]
	    foreach f $helpTailsList {
		lappend fileList [file join $HOME Help $f]
	    } 
	} elseif {${alpha::platform} != "alpha"} {
	    error "Pre-marking/hyperizing help files using\
	      \"help::mimicHelpMenu -all\" is only\
	      useful on the Macintosh."
	} else {
	    # Select all valid help files to mark.
	    set fileList $helpFiles
	} 
    }
    # ...  or given a single file argument "f", which is surrounded either
    # by quotes or brackets, assume that the file is in the Help folder
    # unless the entire path is given ...
    if {$files != "" && $fileList == ""} {
	set f1 [list $files]
	set f2 [file join $HOME Help $files]
	if {[file isfile $f1]} {
	    lappend fileList $f1
	} elseif {[file isfile $f2]} {
	    lappend fileList $f2
	} 
    } 
    # ...  or given no arguments, use the current window.
    if {$files == ""} {
	set fileList [list [win::Current]]
    }
    # Do we have any files to mark/hyper?
    if {![llength $fileList]} {
	status::msg "No valid files were selected."
	error "No valid files were selected."
    } 
    # Now we actually mark/hyper the file.
    foreach f $fileList {
	# We already know that all files in "f2" exist, are complete paths.
	help::removeCHMCleanly $f
	# This avoids updating the header.
	winReadOnly $f
	help::markColourAndHyper
	# Must make writable before adjusting anything else
	setWinInfo read-only 0
	setWinInfo dirty 0
	if {$files == "-all"} {
	    # If only marking files for public release, close them.
	    goto [minPos]
	    shrinkFull
	    menu::fileProc "File" "close"
	}
    }
    return
}

proc help::listTEXTHelpFiles {} {
    
    global HOME
    
    set helpFiles [list]
    foreach f [glob -dir [file join $HOME Help] *] {
	if {[file isfile $f] && [win::FindMode $f] == "Text"} {
	    lappend helpFiles $f
	} 
    } 
    return $helpFiles
}

proc help::markEtcAllHelpFiles {} {
    
    set q "Do you really want to mark and hyper all help files?\
      This could take a little while É"
    if {![askyesno $q]} {return [status::msg "Cancelled."]}
    watchCursor
    mimicHelpMenu -all
    status::msg "All Help files of type 'TEXT' have been marked,\
      coloured, and hyperized."
    return
}

proc help::unmarkAllHelpFiles {} {
    
    global helpFileStamps
    
    set q "Do you really want to remove marks and hypers from all help files?"
    if {![askyesno $q]} {return [status::msg "Cancelled."]}
    foreach f [help::listTEXTHelpFiles] {
	setFileInfo $f resourcelen
    }
    unset -nocomplain helpFileStamps
    prefs::modified helpFileStamps
    status::msg "All Help files of type 'TEXT' have been unmarked."
    return
}

## 
 # ----------------------------------------------------------------------
 #       
 # "help::removeAllColoursAndHypers" --
 # "help::removeCHMCleanly" --
 #      
 # Remove all colors and hypers from the current window.  Removing them
 # "cleanly" also removes marks, but will not change the last save date
 # contained in the resource fork.  "help::removeCHMCleanly" is also used
 # by "help::mimicHelpMenu". 
 # ----------------------------------------------------------------------
 ##

proc help::removeAllColoursAndHypers {args} {
    win::parseArgs win

    # Get rid of the old stuff
    catch {removeColorEscapes -w $win}
    refresh -w $win
    return
}

# This has the side-effect of opening the given file in a window,
# if it is not already open.
proc help::removeCHMCleanly {{path ""}} {

    global HOME

    # This proc can be used for open windows, or called by other code.
    if {($path ne "")} {
	if {[win::Exists $path]} {
	    bringToFront $path
	} elseif {[file exists $path]} {
	    file::openQuietly $path
	}
    } elseif {[llength [winNames -f]] == 0} {
	findFile [file join $HOME Help] 
    } 
    # Altered windows can not be saved "cleanly"
    if {[win::getInfo [win::Current] dirty]} {
	beep ; status::msg "File must first be saved."
	error "File must first be saved."
    }
    setWinInfo read-only 0
    removeAllMarks
    help::removeAllColoursAndHypers
    setWinInfo dirty 0
    return
}

## 
 # --------------------------------------------------------------------------
 #       
 # "help::convertToSetext" --
 #      
 # Convert the active window to use Setext style file marking, removing all
 # extraneous hyperlink syntaxes that don't make sense outside of Alpha.
 # 
 # --------------------------------------------------------------------------
 ##

proc help::convertToSetext {} {
    
    if {![alpha::package exists Setx]} {
	error "Cancelled -- this item requires the Setx mode."
    } 
    loadAMode "Setx"
    Setx::textToSetext
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Miscellaneous help support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 #       
 # "help::prefString" --
 #      
 # Given a preference and optionally a package name, determine if there is
 # some help text associated with it and return the entire string.  If there
 # is no package-specific help available but there is some defined for a
 # global preference with the same name, that will be used.  If no information
 # is available, return a simple string with that message.
 # 
 # We make no attempt to parse out any sections delimited by "|", which might
 # be used for context-specific balloon help.  That is the responsibility of
 # any calling procedure.  Any trailing "\" will be removed -- this
 # construction is used to define a preference help string without actually
 # defining the [newPref] preference, as in
 # 
 #   # Make a backup every time a file is saved, in either the active file's
 #   # folder or a specified "Backup Folder" location\
 #   newPref flag backup 0
 # 
 # in "backup.tcl".
 # 
 # The name of the application will be substituted for the string "ÇALPHAÈ".
 # 
 # Returns a text string suitable for "tooltip" tags.
 # 
 # --------------------------------------------------------------------------
 ##

proc help::prefString {pref {pkg ""}} {
    
    global index::prefshelp alpha::application
    
    if {![array exists index::prefshelp]} {
	cache::readContents index::prefshelp
    }
    set description ""
    if {[info exists index::prefshelp(${pkg},${pref})]} {
	set description $index::prefshelp(${pkg},${pref})
    } elseif {[info exists index::prefshelp($pref)]} {
	set description $index::prefshelp($pref)
    } else {
	set description "No information available for \"${pref}\""
    }
    regsub -all -- {ÇALPHAÈ} $description $alpha::application description
    regsub -all -- {\\\s*$}  $description "" description
    return $description
}

## 
 # --------------------------------------------------------------------------
 # 
 # "help::itemDescription" --
 # 
 # Given the name of an item, whether it is a preference or a package,
 # attempt to find some pre-indexed description for it.  If the item is a
 # preference and the "pkgName" is specified (i.e. a mode or a feature that
 # has defined preferences using [newPref]) then we first see if there is
 # specific help defined by that package; if not then we see if there is a
 # "global" preference description.  If "itemName" is a mode, it must be the
 # internal AlphaTcl name, not the user-interface display name, i.e. "Setx"
 # rather than "Setext".
 # 
 # To get the description for a package, use
 # 
 #     help::itemDescription "" <pkgName>
 # 
 # We make no attempt to parse out any sections delimited by "|", which might
 # be used for context-specific balloon help.  That is the responsibility of
 # any calling procedure.  Any trailing "\" will be removed -- this
 # construction is used to define a preference help string without actually
 # defining the [newPref] preference, as in
 # 
 #   # Make a backup every time a file is saved, in either the active file's
 #   # folder or a specified "Backup Folder" location\
 #   newPref flag backup 0
 # 
 # in "backup.tcl".
 # 
 # The name of the application will be substituted for the string "ÇALPHAÈ".
 # 
 # Returns a text string suitable for "tooltip" tags.
 # 
 # --------------------------------------------------------------------------
 ##

proc help::itemDescription {itemName {pkgName ""}} {
    
    global index::prefshelp alpha::application
    
    if {![array exists index::prefshelp]} {
	cache::readContents index::prefshelp
    }
    if {[info exists index::prefshelp($pkgName,$itemName)]} {
	set description $index::prefshelp($pkgName,$itemName)
    } elseif {[info exists index::prefshelp($itemName)]} {
	set description $index::prefshelp($itemName)
    } elseif {[catch {package::description $pkgName} description] \
      && [catch {package::description $itemName} description]} {
        set description ""
    }
    regsub -all -- {ÇALPHAÈ} $description $alpha::application description
    regsub -all -- {\\\s*$}  $description "" description
    return $description
}

## 
 # --------------------------------------------------------------------------
 # 
 # "help::regexpHelpDialog" --
 # 
 # Open a dialog with multiple panes that explain various aspects of the
 # regular expression syntax.  This is a "courtesty" procedure that calls 
 # [prefs::dialogs::_regexpHelp] and guarantees that no error occurs..
 # 
 # --------------------------------------------------------------------------
 ##

proc help::regexpHelpDialog {} {
    catch {prefs::dialogs::_regexpHelp}
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "help::filePatternsHelpDialog" --
 # 
 # Open a dialog with multiple panes that explain various aspects of the
 # regular expression syntax.  This is a "courtesty" procedure that calls 
 # [prefs::dialogs::_filePatternsHelp] and guarantees that no error occurs.
 # 
 # --------------------------------------------------------------------------
 ##

proc help::filePatternsHelpDialog {} {
    catch {prefs::dialogs::_filePatternsHelp}
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Contextual Menu ×××× #
# 
# This will be included in the Contextual Menu as "Alpha/X/tk Help" if the
# appropriate preference has been set.
# 

## 
 # --------------------------------------------------------------------------
 #       
 # "help::buildCMenu" --
 #      
 # Build a list of relevant options given the current window's context.
 # 
 # --------------------------------------------------------------------------
 ##

proc help::buildCMenu {} {
    
    global alpha::application
    
    variable helpMenuLists
    variable helpItemConnect
    
    unset -nocomplain helpItemConnect
    
    if {[string length [set w [win::Current]]]} {
	set m [win::getMode $w]
	set M [mode::getName $m 1]
	set itemName "'$M' mode Help"
	set menuList [list $itemName]
	set helpItemConnect($itemName) $m
    } 
    # Add help items for current menus, and add extras.
    set helpMenuLists(contextual) [list menus]
    set helpMenuLists(menus) [list]
    set currentMenus [list]
    if {![package::active "alphaDeveloperMenu"]} {
	# Add items for current global menus.
	foreach menuName [alpha::listAlphaTclPackages "menus-global"] {
	    if {![package::active $menuName]} {
		continue
	    } 
	    lappend currentMenus $menuName
	}
	lappend helpMenuLists(contextual) "packages2" "global2" "global1"
    } else {
	set currentMenus [list "alphaDeveloperMenu"]
	lappend helpMenuLists(contextual) "bugs" "packages2" "www"
    }
    foreach menuName $currentMenus {
	set MenuName [quote::Prettify $menuName]
	set helpItemConnect($MenuName) $menuName
	lappend helpMenuLists(menus) $MenuName
    }
    foreach i $helpMenuLists(contextual) {
	if {![llength $helpMenuLists($i)]} {
	    continue
	} 
	set menuList [concat $menuList [list "(-)"] $helpMenuLists($i)]
    }
    # Massage the list of items.
    regsub -all -- {ALPHA} $menuList ${alpha::application} menuList
    
    return [list build $menuList {help::cMenuProc -m}] 
}

## 
 # --------------------------------------------------------------------------
 #       
 # "help::cMenuProc" --
 #      
 # Redirect as necessary to open the relevant Help File item.  If the item
 # name represents an AlphaTcl package, we open the registered Help window.
 # Otherwise we pass the item along to [helpMenu].
 # 
 # --------------------------------------------------------------------------
 ##

proc help::cMenuProc {menuName itemName} {
    
    variable helpItemConnect
    
    if {[info exists helpItemConnect($itemName)]} {
	package::helpWindow $helpItemConnect($itemName)
    } else {
	helpMenu $itemName
    }
    $return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Help Mode Support ×××× #
# 

namespace eval Help {}

# Define some "Help" mode preferences.

newPref var commentsContinuation 1      Help "" \
  [list "only at line start" "spaces allowed" "anywhere"] index
newPref var fillColumn          {77}    Help
newPref var leftFillColumn      {0}     Help
newPref var lineWrap            {1}     Help
newPref var prefixString        {> }    Help
newPref var suffixString        {}      Help
newPref var tabSize             {4}     Help

newPref var wordBreak {(\$)?[:\.\w]*\w+} Help

# Files opened via the Help Menu are always marked and colored when they are
# opened.  To automatically mark and color Help mode files no matter how they
# are opened, turn this item on||To only automatically mark and color Help
# mode files when they are opened from the Help menu, turn this item off
newPref flag autoMarkHelpFiles  {1}     Help
# To automatically indent the new line produced by pressing Return, turn this
# item on.  The indentation amount is determined by the context||To have the
# Return key produce a new line without indentation, turn this item off
newPref flag indentOnReturn     {0}     Help

# Default colours to use for Help files.  These were previously defined as
# part of a non-existent "HelpColours" package.

set colorPrefs [list allCapsColour alphaCommandsColour \
  alphaTclHyperlinksColour codeInsertsColour emailsColour \
  fileHyperlinksColour importantStringsColour manualMarksColour \
  menuDirectionsColour packageHelpColour referenceMarksColour \
  sectionTargetsColour tclProcsColour titleColour urlsColour]

foreach colorPref $colorPrefs {
    prefs::renameOld HelpColoursmodeVars($colorPref) \
      HelpmodeVars($colorPref)
}

unset colorPrefs colorPref

# The colour of ALL CAP strings in command reference manuals.
newPref colour allCapsColour            red     Help
# The colour of Alpha core commands in the 'Alpha Commands' file, and in
# 'command: <coreCommand>' hyperlinks.
newPref colour alphaCommandsColour      blue    Help
# The colour of <<some alpha/tcl command>> hyperlinks.
newPref colour alphaTclHyperlinksColour magenta Help
# The colour of specially indented code inserts.
newPref colour codeInsertsColour        blue    Help
# The colour of <e-mail@someplace.com> hyperlinks.
newPref colour emailsColour             green   Help
# The colour of "someFile.tcl" hyperlinks.
newPref colour fileHyperlinksColour     green   Help
# The colour of "IMPORTANT:" strings.
newPref colour importantStringsColour   red     Help
# The colour of Alpha Manual help file marks.
newPref colour manualMarksColour        red     Help
# The colour of "Menu Name > Menu Item" strings.
newPref colour menuDirectionsColour     red     Help
# The colour of 'package: somePackage' help file hyperlinks.
newPref colour packageHelpColour        magenta Help
# The colour of command reference manual marks.
newPref colour referenceMarksColour     blue    Help
# The colour of "# Some Window Mark" hyperlinks.
newPref colour sectionTargetsColour     green   Help
# The colour of 'proc: someProc' hyperlinks
newPref colour tclProcsColour           blue    Help
# The colour of the title (first alpha-numeric line) in Help files.  This
# string is always underlined as well.
newPref colour titleColour              red     Help
# The colour of <http://www.someWebPage.com> hyperlinks.
newPref colour urlsColour               green   Help

# Create categorized preference pane lists.

prefs::dialogs::setPaneLists "Help" "Editing" [list \
  "autoMarkHelpFiles" \
  "commentsContinuation" \
  "fillColumn" \
  "indentOnReturn" \
  "leftFillColumn" \
  "lineWrap" \
  "prefixString" \
  "suffixString" \
  "tabSize" \
  "wordBreak" \
  ]

prefs::dialogs::setPaneLists "Help" "Help File Colors" [list \
  "allCapsColour" \
  "codeInsertsColour" \
  "importantStringsColour" \
  "manualMarksColour" \
  "menuDirectionsColour" \
  "referenceMarksColour" \
  "titleColour" \
  ]


prefs::dialogs::setPaneLists "Help" "Hyperlink Colors" [list \
  "alphaCommandsColour" \
  "alphaTclHyperlinksColour" \
  "emailsColour" \
  "fileHyperlinksColour" \
  "packageHelpColour" \
  "sectionTargetsColour" \
  "tclProcsColour" \
  "urlsColour" \
  ]

## 
 # --------------------------------------------------------------------------
 # 
 # "Help::openHook" --
 # 
 # Called when a window is opened in "Help" mode.
 # 
 # --------------------------------------------------------------------------
 ##

proc Help::openHook {name} {
    
    global HelpmodeVars
    
    if {$HelpmodeVars(autoMarkHelpFiles)} {
	help::markColourAndHyper -w $name
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Help::MarkFile" --
 # 
 # Called by [markFile] and the Marks pop-up menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc Help::MarkFile {args} {
    
    win::parseArgs w
    
    help::removeAllColoursAndHypers -w $w
    help::markColourAndHyper -w $w
    if {([set marks [llength [getNamedMarks -w $w]]] == 1)} {
        status::msg "One section heading in \"[win::Tail $w]\""
    } else {
        status::msg "$marks sections headings in \"[win::Tail $w]\""
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Help::DblClick" --
 # 
 # Attempt to obtain information on (Alpha)Tcl procs, variables, commands.
 # 
 # --------------------------------------------------------------------------
 ##

proc Help::DblClick {args} {
    return [eval Tcl::DblClick $args]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 07/22/00 vmd 0.1    Original
#  -> 2006     - 1.7  Various changes throughout the years.
# 01/02/06 bd  1.8    Initial "SUPPORT" usage for help file search paths.
#                     New "Help > Developer Help" menu item.
#                     "Help > Developer Help" opens AlphaDevMenu help.
# 01/04/06 cbu 1.8.1  New [help::initializePackage] procedure.
#                     New global HELP and EXAMPLES variables with path lists.
#                     Removed "Help > Developer Help" menu item.
# 01/10/06 cbu 1.8.2 [help::openFile] only looks for "extra" files/folders in
#                       the first [help::pathToHelp] directory.
#                     New [help::pathToExample] procedure.
#                     SUPPORT Help/Examples are in SUPPORT/AlphaTcl/...
# 02/07/06 cbu 1.8.3  RFE# 1055 : "Display Names" for modes in UI.
# 02/25/06 cbu 1.8.4  New "Help" mode can auto-mark and color files.


# ===========================================================================
# 
# .