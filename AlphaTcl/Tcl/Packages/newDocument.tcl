## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # (formerly Vince's Additions - an extension package for Alpha)
 # 
 # FILE: "newDocument.tcl"
 #                                          created: 09/18/1997 {04:47:39 pm}
 #                                      last update: 03/02/2006 {05:29:49 PM}
 # Description:
 # 
 # Offers a simple API for opening new windows using either pre-set template
 # options defined by various packages in AlphaTcl, or with new window
 # handlers (such as Document Projects).  Replaces the menu item "File > New"
 # item with a submenu of the same name, which offers all of the various new
 # doc types available.  "File > New > Create A New" will offer all options.
 #  
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #     
 # Includes contributions from Craig Barton Upright, who shamelessly stole
 # some ideas from BBEdit.
 #   
 # Copyright (c) 1997-2006  Vince Darley, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # --------------------------------------------------------------------------
 # 
 # Notes:
 # 
 # This package serves two main purposes.
 # 
 # First, it provides a method for users to create new open windows using
 # pre-set templates via the dialog called by "File > New > New Document".
 # Any package can declare a new type of document to be added to the set of
 # dialog panes simply by adding to the 'newDocTypes' array, as in
 # 
 #     array set newDocTypes [list "New LaTeX Doc" {TeX::newLaTeXDocument}]
 # 
 # (Actually the "New " is no longer necessary, and will be stripped from
 # the name of the item, so it is sufficient to just use
 # 
 #     array set newDocTypes [list "LaTeX Doc" {TeX::newLaTeXDocument}]
 # 
 # The submenu "File > New" offers all of these options, plus some extras
 # that are defined by this package.  If any of them require open windows,
 # add an entry to the "newDocTypesRequire" array, as in
 # 
 #     array set newDocTypesRequire [list "New HTML With Content" 1]
 #     
 # where the number indicates the number of required windows.
 # 
 # If you don't want ellipses to be automatically added to the end of the
 # menu item's name, add an entry to the "newDocTypesDots" array, as in
 # 
 #     array set newDocTypesDots [list "Untitled Window" "0"]
 # 
 # Modes can include such a statement in their [alpha::mode] initialization
 # argument if they want such an option to be available even if the mode has
 # not yet been loaded.
 # 
 # Second, it provides an interface with 'New Document Handlers' such as the
 # one found in the package: documentProjects.  Any use of 'new' can be
 # applied with [file::newDocument] instead, and if the user has selected the
 # documentProjects handler for new documents, the info will first be passed
 # to the handler before opening the new window.  Default settings will not
 # deviate from standard behavior beyond the initial dialog.
 # 
 # See the examples below for more information.
 # 
 # ==========================================================================
 ##

alpha::feature newDocument 1.0.3 "global-only" {
    # Initialization script.  We don't put much in here in case some code is
    # calling [file::newDocument] without this package being activated.
    newDocument.tcl
    package::addPrefsDialog newDocument
    menu::buildProc "New" {newDocument::buildMenu "0"}
} {
    # Activation script.
    menu::replaceWith File "/Nnew" submenu "New"
    newDocument::registerOWH 1
} {
    # De-activation script.
    menu::removeFrom  File "/Nnew" submenu "New"
    newDocument::registerOWH 0
} uninstall {
    this-file
} preinit {
    # Contextual Menu module.  Doesn't require this package to be formally
    # turned on by the user.
    
    # Includes all of the options provided by the "File > New Document" menu,
    # i.e. those new document options defined by other AlphaTcl packages to 
    # create new windows with specific templates
    newPref flag newDocumentMenu 0 contextualMenu
    menu::buildProc "newDocument" {newDocument::buildMenu "1"}
    # Place this item in the first section.
    ;namespace eval contextualMenu {
	variable menuSections
	lappend menuSections(1) "newDocumentMenu"
    }
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Offers a variety of 'New Document' options for window creation
} help {
    This package offers a variety of 'New Document' options for creating
    new windows, including a preset list of template options created by
    other packages in AlphaTcl, as well as different new window 'handlers'
    as described below.  After the package has been activated, 
    
    Preferences: Features
    
    the "File > New" menu item is replaced by a submenu of the same name.

	  	Table Of Contents

    "# The New Document Menu"
    "# New Document Preferences"
    "# Contextual Menu Module"
    
    <<floatNamedMarks>>


	  	The New Document Menu

    The new "File > New" menu includes all of the possible "New Document"
    options that have been registered by other AlphaTcl packages (such as
    creating a new e-mail message, or inserting a template for a new HTML or
    LaTeX document.)  You can select any of them to evaluate the associated
    script.
    
    Click some of these hyperlinks for an example:
    
    <<newDocument::menuProc "" "New Email Message">>
    <<newDocument::menuProc "" "New LaTeX Doc">>
    <<newDocument::menuProc "" "New HTML Doc">>
    
    Selecting the "File > New > Create A New" menu item presents a dialog
    that looks like <<::newDocument::selectType>> which includes the entire
    list of the preset options.  Select "File > New > New Text Window" to
    only be prompted for a window name.  When you create a new document/text
    window your "New Document Handler" is used to complete the process, as
    described below.
    
    If you simply want to open a new untitled window without being prompted
    any further for window names or other options, then select the menu item
    "File > New Document > Untitled Window".  You can assign a Keyboard
    Shortcut to this item, as well as to any other "File > New" item by
    selecting "File > new Document > New Document Shortcuts".
    
    
	  	New Document Preferences

    For new windows which aren't templates, this package has some different
    preferences to help determine how many additional options should be
    presented.  These preferences are available by selecting the "Prefs"
    button in the "File > New > Create A new" dialog, or (after the package
    has been activated) by the "File > New > New Document Prefs" menu item.
    
    Preferences: newDocument
 
    The options include:

	Untitled Docs Are Empty

    Set this preference to always open 'untitled' windows without any extra
    template information created by your New Document Handler.
    
	New Document Handler
	
    Initially set to 'Alpha', this preference determines which package should
    handle new open windows.  'Alpha' will simply open a new window, with
    prompting you for any additional information.
    
    The package: documentProjects creates an additional handler that you can
    select.  The "Doc Projects" handler will optionally add header info at
    the top of the window, or insert additional template information.  (You
    have to activate the "Document Projects" feature to have access to this
    handler.)  Many of the "Doc Projects" headers are only useful after you
    have created your identity and defined some projects -- see the
    "documentProjects Help" window for more information.
    
	----------------------------------------------------------------

	  	Contextual Menu Module
    
    A Contextual Menu "New Document" module is also available which
    provides a submenu with all New Document options.
    
    Preferences: ContextualMenu
    
    It is not necessary to formally turn this package on in order to have
    access to this CM module.
}

proc newDocument.tcl {} {}

# ===========================================================================
# 
# ×××× Preferences, Variables ×××× #
# 

# We keep all of this stuff in here so that 'file::newDocument' won't fail
# even if this package hasn't been activated.

namespace eval newDocument {
    
    # This is the list of top-level item names.
    variable newOptions [list \
      "Create A New" \
      "New Text Window" \
      "    Ç with selection È " \
      "    Ç with Clipboard È " \
      "Untitled Window" \
      ]
    array set ::newDocTypesDots [list \
      "Untitled Window" "0" \
      ]
    # These are default shortcuts.
    variable shortcuts
    foreach itemName $newOptions {
	if {![info exists shortcuts($itemName)]} {
	    switch -- $itemName {
		"Create A New" {
		    set shortcuts($itemName) "<O/N"
		}
		"New Text Window" {
		    set shortcuts($itemName) "<U<O/N"
		}
	    }
	} 
    }
    unset itemName
    # This is used in [newDocument::promptForName].
    variable windowName "untitled"
}

array set newDocument::handlers [list [set ::alpha::application] {::new}]

prefs::removeObsolete newDocumentmodeVars(newDocNamePrompt)

# Turn this item on to open 'untitled' windows directly without asking
# for templates etc||Turn this item off to prompt for templates etc
# when opening 'untitled' windows
newPref flag untitledDocsAreEmpty 1 newDocument

# The handler of new documents.  'Alpha' simply creates a new window,
# other packages (such as Document Projects) have more sophisticated
# options.
newPref var newDocumentHandler [set ::alpha::application] newDocument "" \
  ::newDocument::handlers array

# This line could/should be moved into the "filesetsMenu.tcl" package.
if {![info exists "newDocTypes(File-set)"]} {
    array set newDocTypes [list "File-set" {::newFileset}]
} 

if {(${alpha::platform} eq "tk") \
  && ![info exists "newDocTypes(New Tabbed Window)"]} {
    array set newDocTypes [list "New Tabbed Window" {::useTabbedWindow}]
}

# This array contains items that should be dimmed when there are no open
# windows.  Any AlphaTcl package can also add items to this array.
array set "newDocTypesRequire" [list "    Ç with selection È " 1]

##
 # --------------------------------------------------------------------------
 #
 # "newDocument::addNewItem" --
 # 
 # Now that we've defined all of the "newDocTypes" entries, we'll ensure that
 # any additional ones trigger rebuilding of the submenu.  (Most of the
 # "newDocTypes" entries are added during mode/package "preinit" scripts, so
 # they will be declared before this file is sourced.)
 # 
 # --------------------------------------------------------------------------
 ##

trace add variable newDocTypes {array write unset} {::newDocument::addNewItem}

proc newDocument::addNewItem {args} {
    
    newDocument::rebuildMenu
    newDocument::registerOWH [package::active "newDocument"]
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "newDocument::listOptions" --
 # 
 # Many AlphaTcl packages register the new types used by this package
 # naming then "New <something>".  This makes less sense given how they are
 # presented to the user, so this proc strips that off and sorts the list.
 # 
 # --------------------------------------------------------------------------
 ##

proc newDocument::listOptions {{checkWindowLength "0"}} {
    
    global newDocTypes newDocTypesRequire
    
    set types [list]
    foreach type [array names newDocTypes] {
	regsub -- {^New\s+} $type {} type
	lappend types $type
    }
    if {$checkWindowLength} {
	set valid [list]
	set winsL [llength [winNames]]
	foreach type $types {
	    if {[info exists newDocTypesRequire($type)]} {
		set requiredWindows $newDocTypesRequire($type)
	    } elseif {[info exists "newDocTypesRequire(New $type)"]} {
		set requiredWindows "$newDocTypesRequire(New $type)"
	    } else {
		set requiredWindows $winsL
	    }
	    if {($winsL >= $requiredWindows)} {
		lappend valid $type
	    } 
	}
	set types $valid
    } 
    return [lsort -dictionary $types]
}

# ===========================================================================
# 
# ×××× "File > New" menu, support ×××× #
# 

##
 # --------------------------------------------------------------------------
 #
 # "newDocument::buildMenu" --
 # 
 # Build the "File > New" submenu, as well as the "New Document" CM menu.
 # Any user-defined Keyboard Shortcuts are automatically added.  The argument
 # "forCMenu" distinguishes that this is being built for the Contextual Menu
 # versus the File menu.  This determines whether we add Keyboard Shortcuts
 # or not.  (It's possible that the CM module is activated even though these
 # feature has not been, so the Keyboard Shortcuts wouldn't make any sense or
 # actually work.)
 # 
 # --------------------------------------------------------------------------
 ##

proc newDocument::buildMenu {{forCMenu "0"}} {
    
    global newDocumentmodeVars newDocTypesDots
    
    variable shortcuts
    
    # Start the list with some default options.
    if {!$forCMenu} {
	# Building for "File > New".
	set firstItems [list "Create A New" "New Text Window"]
    } else {
	# Building for Contextual Menu -- no Keyboard Shortcuts.
	set firstItems [list "New Text Window"]
    }
    if {!$forCMenu || [contextualMenu::isSelection]} {
	lappend firstItems "    Ç with selection È "
    } 
    lappend firstItems "    Ç with Clipboard È " "Untitled Window"
    # Add any Keyboard Shortcuts.
    foreach itemName $firstItems {
	if {!$forCMenu && [info exists shortcuts($itemName)]} {
	    set shortcut $shortcuts($itemName)
	} else {
	    set shortcut ""
	}
	if {![info exists newDocTypesDots($itemName)] \
	  || ($newDocTypesDots($itemName) == "1")} {
	    append itemName "É"
	} 
	lappend menuList "${shortcut}${itemName}"
    }
    lappend menuList "(-)"
    # Add each registered New Document Type.
    foreach itemName [newDocument::listOptions $forCMenu] {
	if {!$forCMenu && [info exists shortcuts($itemName)]} {
	    set shortcut $shortcuts($itemName)
	} else {
	    set shortcut ""
	}
	if {![info exists newDocTypesDots($itemName)] \
	  || ($newDocTypesDots($itemName) == "1")} {
	    append itemName "É"
	} 
	lappend menuList "${shortcut}${itemName}"
    }
    # Add some Utility items.
    lappend menuList "(-)" "New Document PrefsÉ"
    if {!$forCMenu} {
	lappend menuList "New Document ShortcutsÉ"
    }
    lappend menuList "New Document Help"
    
    return [list build $menuList {newDocument::menuProc -m}] 
}

proc newDocument::rebuildMenu {args} {
    
    menu::buildSome "New"
    if {[llength $args]} {
        status::msg "The \"File > New\" menu has been rebuilt."
    } 
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "newDocument::registerOWH" --
 # 
 # Any "New Document" item can declare itself useful only if there are a
 # given number of open windows present.  Use
 # 
 #     set newDocTypesRequire(<itemName>) <num>
 # 
 # where "<num>" is the number of required windows.
 # 
 # --------------------------------------------------------------------------
 ##

proc newDocument::registerOWH {{register "1"}} {
    
    global newDocTypesRequire

    if {$register} {
        set cmd "hook::register"
    } else {
        set cmd "hook::deregister"
    }
    foreach itemName [array names newDocTypesRequire] {
	set num $newDocTypesRequire($itemName)
	if {![is::PositiveInteger $num]} {
	    continue
	}
	regsub -- {^New\s+} $itemName {} itemName
	$cmd requireOpenWindowsHook [list -m "New" "${itemName}É"] $num
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "newDocument::menuProc" --
 # 
 # Deal with any Utility items as necessary, evaluate any pre-defined scripts
 # if the New Document Type is recognized, and otherwise pass on any supplied
 # Window Name (-n <name>) and Content (-text <text>) to [file::newDocument].
 # 
 # This should always return the name of the new window that was created.
 # 
 # A note on Window Names: Whenever [newDocument::promptForName] is called,
 # the value is saved in the "windowName" variable.  This will be used as
 # the default in subesquent "File > New > New Document" dialogs.  For the
 # "File > New > New Text Window" items, the default is always "untitled".
 # This makes sense to me after working with this for a while, if it
 # doesn't seem intuitive to others then we can modify this behavior.
 # 
 # --------------------------------------------------------------------------
 ##

proc newDocument::menuProc {{menuName ""} {itemName ""}} {
    
    global newDocTypes newDocumentmodeVars
    
    variable content ""
    variable windowName
    
    switch -- [string trim $itemName] {
	"Create A New" - "" {
	    set itemName [newDocument::selectType]
	}
	"New Text Window" {
	    set p "New Text Window Name:"
	    newDocument::promptForName $p "untitled"
	    if {($windowName eq "untitled") \
	      && $newDocumentmodeVars(untitledDocsAreEmpty)} {
		return [new -n $windowName]
	    }
	    set itemName "New Window"
	}
	"New Document Prefs" {
            prefs::dialogs::packagePrefs "newDocument"
	    status::msg "\"New Document\" Preferences have been saved."
	    return
        }
        "New Document Shortcuts" {
	    newDocument::assignShortcuts
	    status::msg "The new Keyboard Shortcuts have been assigned."
	    return
        }
	"New Document Help" {
	    package::helpWindow "newDocument"
	    return
	}
	"Ç with selection È" {
	    if {![llength [winNames]]} {
		error "Cancelled -- there is no active window."
	    } elseif {![isSelection]} {
	        error "Cancelled -- there is no current selection."
	    } else {
	        set content [getSelect]
	    }
	    set p "New Text Window Name:"
	    newDocument::promptForName $p "untitled"
	}
	"Ç with Clipboard È" {
	    if {[catch {getScrap} content]} {
		set content ""
		error "Cancelled -- the Clipboard is empty."
	    }
	    set p "New Text Window Name:"
	    newDocument::promptForName $p "untitled"
	}
	"Untitled Window" {
	    ::new
	    return
	}
    }
    # Still here?  If this is a registered "newDocType", then evaluate the
    # given script.  Otherwise, pass the item along to [file::newDocument].
    # All scripts should return the name of the new window.
    if {[info exists newDocTypes($itemName)]} {
        set w [eval $newDocTypes($itemName)]
    } elseif {[info exists "newDocTypes(New $itemName)"]} {
        set w [eval "$newDocTypes(New $itemName)"]
    } else {
        set w [file::newDocument -n $windowName -text $content]
    }
    # Reset this for the next round.
    set content ""
    # Return the name of the new window that was created.
    return $w
}

##
 # --------------------------------------------------------------------------
 #
 # "newDocument::selectType" --
 # 
 # Create a dialog in which each pane represents a New Document Type.  The
 # first pane include a text-edit field for entering the name of the new
 # window, but this is only used if that pane is the one selected.
 # 
 # --------------------------------------------------------------------------
 ##

proc newDocument::selectType {} {
    
    global newDocTypesRequire
    
    variable windowName
    
    # The first pane of the dialog is for "New Document"
    set dialogScript [list dialog::make -title "Create A NewÉ" \
      -width 350 \
      -ok "Continue" \
      -okhelptag "Click here to continue creating the new document." \
      -cancelhelptag "Click here to cancel the new document creation." \
      -addbuttons [list \
      "Help" \
      "Click here to open the New Documents Help window." \
      {package::helpWindow newDocument ; set retCode 1 ; set retVal {cancel}} \
      "PrefsÉ" \
      "Click here to review/adjust your New Document preferences." \
      {catch {::prefs::dialogs::packagePrefs newDocument}}] \
      [list "Document Window" "thepage" \
      [list var "Name:" $windowName "Enter the name of the new document."]]]
    # Now we add a new pane for each new type.
    foreach type [newDocument::listOptions 1] {
	lappend dialogScript [list $type]
    }
    set result [eval $dialogScript]
    if {([set pane [lindex $result 0]] eq "Document Window")} {
	set newType "New Window"
	set windowName [lindex $result 1]
	if {![string length [string trim $windowName]]} {
	    set windowName "untitled"
	} 
    } else {
	set newType $pane
    }
    return $newType
}

##
 # --------------------------------------------------------------------------
 #
 # "newDocument::promptForName" --
 # 
 # Prompt the user for a valid name for the new window.  If the name is
 # empty or otherwise won't work very well, we let the user know and try
 # again until we get a good one.  We always save the result in the variable
 # "windowName" so that it can be used for the next round.
 # 
 # --------------------------------------------------------------------------
 ##

proc newDocument::promptForName {{p ""} {name ""}} {
    
    variable windowName
    
    if {![string length $p]} {
	set p "New Document Window Name:"
    } 
    if {![string length $name]} {
        set name $windowName
    } 
    while {1} {
        set name [prompt $p $name]
	if {![string length [string trim $name]]} {
	    alertnote "You must enter a new name!"
	    set name "untitled"
	} elseif {[regexp -- [quote::Regfind [file separator]] $name]} {
	    alertnote "OS file separator characters are not allowed!"
	} else {
	    break
	}
    }
    return [set windowName $name]
}

##
 # --------------------------------------------------------------------------
 #
 # "newDocument::assignShortcuts" --
 # 
 # Create a dialog that allows the user to assign/remove Keyboard Shortcuts
 # that will appear in the "File > New" submenu.  All settings are saved
 # between editing sessions.
 # 
 # --------------------------------------------------------------------------
 ##

proc newDocument::assignShortcuts {} {
    
    variable newOptions
    variable shortcuts
    
    # We first add the top level items.
    foreach itemName $newOptions {
	if {[info exists shortcuts($itemName)]} {
	    set menuBindings($itemName) $shortcuts($itemName)
	} else {
	    set menuBindings($itemName) ""
	}
	set oldBindings($itemName) $menuBindings($itemName)
    }
    # Now add all user-defined Favorites.
    foreach itemName [newDocument::listOptions] {
	if {[info exists shortcuts($itemName)]} {
	    set menuBindings($itemName) $shortcuts($itemName)
	} else {
	    set menuBindings($itemName) ""
	}
	set oldBindings($itemName) $menuBindings($itemName)
    }
    # Present the dialog.
    set title "New Document Keyboard Shortcuts É"
    catch {dialog::arrayBindings $title menuBindings 1}
    # Change the binding.
    foreach itemName [array names menuBindings] {
	if {($menuBindings($itemName) ne $oldBindings($itemName))} {
	    set shortcuts($itemName) $menuBindings($itemName)
	    prefs::modified shortcuts($itemName)
	} 
    }
    newDocument::rebuildMenu 1
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "file::newDocument" --
 # 
 # This procedure accepts any argument that can be provided to [new].
 # 
 # If no "-n <name>" is supplied, we continue to prompt the user until
 # we have a non-empty string.
 # 
 # If the "name" is "untitled" and the "untitledDocsAreEmpty" preference
 # is set to "1", then we simply open a new window.
 # 
 # Otherwise, we call the user's "New Document Handler".  If this value is
 # "Alpha", then we just open a new window.  Otherwise, we pass along all
 # of the information that we've collected.
 # 
 # In all cases, we return the name of the new window that was created.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval file {}

proc file::newDocument {args} {
    
    global newDocumentmodeVars newDocument::handlers alpha::application
    
    getOpts {n mode text}
    
    # Determine what 'typeName' really should be if initially untitled.
    if {![info exists opts(-n)] || ![string length $opts(-n)]} {
	# If the 'menuName' is anything but the null string, use the
	# suggested window name, otherwise prompt until we get one.
	set opts(-n) [newDocument::promptForName]
    }
    if {![info exists opts(-mode)]} {
        set opts(-mode) [win::FindMode $opts(-n)]
    } 
    if {![info exists opts(-text)]} {
	set opts(-text) ""
    } 
    # Place these values back into the 'args' list.
    lappend args "-n" $opts(-n) "-mode" $opts(-mode) -text $opts(-text)
    if {$opts(-n) eq "untitled" \
      && $newDocumentmodeVars(untitledDocsAreEmpty)} {
        return [eval [list new] $args]
    } 
    # It's a new window to be handled by the handler.
    set handlerName $newDocumentmodeVars(newDocumentHandler)
    set handlerProc [set newDocument::handlers($handlerName)]
    if {[catch {eval $handlerProc $args} w]} {
	# The handler threw an error.  "w" contains the error info.
	if {[info commands $handlerProc] == ""} {
	    # Handler poorly set.
	    alertnote "Your new document handler was poorly set.\
	      I'll reset it (err: $w)."
	    set newDocumentmodeVars(newDocumentHandler) \
	      [set alpha::application]
	    prefs::modified newDocumentmodeVars(newDocumentHandler)
	    set w [eval [list new] $args]
	} else {
	    # Not sure what went wrong ...
	    alertnote "Your new document handler \"${handlerName}\"\
	      caused an error\r\r$w."
	    error "Cancelled: $w"
	}
    }
    return $w
}

# ===========================================================================
#
# ×××× ------------ ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 09-18-97 VMD 0.1    Original.
# ??       ??  0.2    Various updates througout the years.
# 03-20-02 cbu 0.3    Added CM module.
#                     [file::newDocument] now accepts all valid args that can
#                       be passed onto 'new'.
# 2002-2004    0.4    Various minor bug fixes.
#                     Vince did a nice cleanup of the dialog.
# 03/03/04 cbu 0.5    "File > New Document" is now presented as a submenu.
# 03/03/04 cbu 1.0    Major update in how the menu items are handled, and how
#                       the default "New Document" item is processed.
#                     The submenu is now named "File > New".
#                     User can now assign Keyboard Shortcuts.
#                     [file::newDocument] is considerably simplified.
# 03/05/04 cbu 1.0.1  Better Shortcut setting, and the top-level item names
#                       can be assigned Shortcuts.
# 05/21/04 vmd 1.0.2  Don't use "::alpha::application" for new doc handler.
# 01/12/05 cbu 1.0.3  Added "New > Untitled Window" per users' requests.
#                     Empty new window names default to "untitled".
#                     Updated dialog help tags.
# 

# ===========================================================================
#
# .