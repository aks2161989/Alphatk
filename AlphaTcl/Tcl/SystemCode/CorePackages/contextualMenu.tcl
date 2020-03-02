## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "contextualMenu.tcl"
 #                                          created: 01/31/2001 {09:16:50 PM}
 #                                      last update: 05/23/2006 {03:11:20 PM}
 # Description: 
 # 
 # Provides a default set of Contextual Menu modules, plus an API for other
 # AlphaTcl packages to add more.
 # 
 # See [contextualMenu::developersHelp] for more information.
 # 
 # Author: Jonathan Guyer
 # E-mail: jguyer@his.com
 #   mail: Alpha Cabal
 #    www: http://www.his.com/jguyer/
 # 
 # Includes contributions from Craig Barton Upright
 # 
 # Copyright (c) 2001-2006 Jonathan Guyer, Craig Barton Upright.
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::feature contextualMenu 1.2.1 "global-only" {
    # Initialization script.
    # Add the user interface dialog to "Config > Packages".
    namespace eval contextualMenu {}
    menu::buildProc "contextualMenuUtils" {contextualMenu::buildCMUtils}
    ;proc contextualMenu::buildCMUtils {} {
	set menuList [list \
	  "Contextual Menu PrefsÉ" "Contextual Menu Help"]
	return [list build $menuList {contextualMenu::cMUtils -m} {}]
    }
    menu::insert preferences submenu "(-)" "contextualMenuUtils"
} {
    # Activiation script.
    hook::register   contextualMenuHook      contextualMenu::contextualMenu
    hook::register   contextualPostBuildHook contextualMenu::postBuild
} {
    # Deactivation script.
    hook::deregister contextualMenuHook      contextualMenu::contextualMenu
    hook::deregister contextualPostBuildHook contextualMenu::postBuild
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Creates Contextual Menus specific to the text surrounding the Cursor --
    the CM is invoked by pressing Control and the mouse button
    simultaneously, or (in Windows) by pressing the right mouse button
} help {
    This package provides support for Contextual Menus, invoked in the Mac OS
    by pressing Control and the mouse button simultaneously.  In the Windows
    OS, the CM is accessed by clicking the mouse's right button.
    
    Individual CM modules (menus or items) can be added/removed from the CM
    by selecting "Config > Preferences > Contextual Menu Utils > Prefs".
    Note that this dialog, like the CM itself, is mode specific, and you can
    change the modules associated with the mode of the current window as well
    as 'global' settings.
    
    Preferences: ContextualMenu
    
    Default items include

	Related Files

    This submenu includes all of the files found in the directory of the
    current window.  (Similar to option titlebar clicking.)
    
	Window Path Menu

    This submenu contains a list of all folders found in the path of the
    current window.  Selecting any item will open a standard OS "Find File"
    dialog using that folder as the default.  (Similar to clicking on the
    titlebar window.)
    
	Window Marks Menu

    This submenu contains all of the items found in the Marks pop-up menu.

	Text Utils

    This submenu contains various items found in the main 'Text' menu in the
    menu bar, allowing you to indent, fill, comment, etc either the selected
    region surrounding the click position or the line in which it resides.
    
	Format Menu

    This submenu contains all of the items found in the 'File Info' pop-up
    menu in the status bar, allowing you to change tab size, line endings,
    etc.  for the current window.

	Wrap Menu

    This submenu allows you to change the current 'wrap' style of the current
    window.  See the "Alpha Manual # Text Wrapping" help file section for
    more information.
    
	Mode Menu

    Allows you to change the mode of the current window.

	Contextual Menu Utils

    This menu contains two items, the first allowing you to change the
    Contextual Menu preferences, turning items on and off both globally and
    for mode specific items, and a "Help" menu item which opens this window.

	----------------------------------------------------------------
    
    In addition to these default contextual menu items, modes might have
    additional CM modules which only appear for that mode, such as a
    "Process" menu in TeX mode, or an "Html Attributes" menu which will list
    all possible options for the tag surrounding the CM click position.
    These additional modules can be turned on and off by selecting the menu
    item "Config > Packages > Contextual Menu Utils > Prefs" dialog, also
    available in the "Contextual Menu Utils" CM module.
    
    Some packages in AlphaTcl offer additional plug-ins to add submenus which
    might already appear in some of Alpha's global menus, such as one
    containing a list of all recent files (package: recentFilesMenu), or note
    files that you have created and saved (package: notes), etc.  The best
    way to find out what these items do is to simply activate them and see
    what is now available in the contextual menu -- items can always be
    turned off, with the changes taking effect immediately.
  
    AlphaTcl developers should click here <<contextualMenu::developersHelp>>
    for more information on how to create contextual menu plug-ins.
}

proc contextualMenu.tcl {} {}

# ×××× Contextual Menu Prefs ×××× #

# Adds a menu allowing you to change all of these CM module preferences!
newPref f contextualMenuUtilsMenu   1 contextualMenu
# Includes files residing in the same folder as the active window, or 
# possibly some mode-specific listing of related files
newPref f relatedFilesMenu          1 contextualMenu
# Includes items from the "Edit" menu for sorting lines, commenting text, 
# filling paragraphs, etc. 
newPref f textUtilsMenu             1 contextualMenu
# Includes the navigation marks from each window's "Mark" pop-up menu.
newPref f windowMarksMenu           1 contextualMenu
# Includes each directory in the active window's path.  Selecting any item in
# the path will open a 'Find File' dialog with that default location
newPref f windowPathMenu            1 contextualMenu
if {($alpha::macos == 2) && [file exists "/Applications/Dictionary.app"]} {
    # Sends the current word (beneath the cursor) to "Dictionary.app"
    newPref flag "lookUpInDictionaryItem" 1 contextualMenu
}

namespace eval contextualMenu {
    
    variable lastCMArgs ""
    variable clickWord  ""
    
    variable menuSections
    # This is set of items potentially appearing at the start of the CM.
    lunion menuSections(1) "relatedFilesMenu" "windowPathMenu" "windowMarksMenu"
    # This is set of items potentially appearing at the bottom of the CM.
    lunion menuSections(4) "vcsMenu"
}


proc contextualMenu::developersHelp {} {
    
    set title "Contextual Menu Developers Help"
    if {[win::Exists $title]} {
	bringToFront $title
	return
    }

    set txt {
Contextual Menu Developers Help

"# Description"
"# Adding Global Submenus"
"# Adding Global Items"
"# Adding Mode Specific CM Menus and Items"
"# Dimming CM modules"
"# CM tooltip help tags"
"# 'selectionDesc'"
"# To Do:"

<<floatNamedMarks>>

	  	Description

This package is designed to make it much easier for modes or other packages
in AlphaTcl to add/remove items from the contextual menu.  This menu is
completely modular -- the user can add or remove items from the CM with
changes taking effect immediately.  Modes, global packages, and mode specific
packages can all create new modules to add to the CM Preferences dialog.

The 'context' here might be specifics about the current window, the current
mode, or the position and/or selection surrounding the CM click point.  The
items added via this package might be global or mode specific, but will be
added no matter what is going on in the window regarding selected text and/or
click position.  Items within particular submenus added to the main CM,
however, can certainly change depending on the list of values currently
stored in the variable 'alpha::CMArgs' or other 'context' parameters.

'Non-contextual' modules can also be added to the CM, generally global
submenus that might already be inserted into one of the menu bar menus that
users might find useful as a CM shortcut.  If these perform text editing
tasks within the current window, however, they must take the CM click
position (again, available via the list of values in 'alpha::CMArgs'), and
NOT on the current position.

The CM is listed in four sections, each separated by a divider.  The first
contains window specific modules defined by this package, such as the current
path (similar to the title bar pop-up), and the current marks.  The second is
for mode-specific modules.  The third includes global CM modules defined by
other packages in AlphaTcl.  The final section includes more window specific
modules defined in this package that probably won't be accessed very often,
such as mode, format, and wrap.  The CM Utils module is always listed last.

The following sections explain how to add modules to the second and third
sections, how to dim CM menus/items, and other miscellaneous information.

	  	Adding Global Submenus

Any package can add a submenu in the third section of the CM by simply
defining a new contextualMenu package preference, as in:

	newPref f <contextualMenuSubmenuName>Menu 0 contextualMenu

and then declaring a 'menu build proc' using the proc: menu::buildProc for a
menu whose name does NOT end in Menu.  The package: notes, for example, can
add this:

	newPref f notesMenu 0 contextualMenu

Note that in order to add a submenu, the preference MUST end in 'Menu'.

This preference will then appear in the "Contextual Menu" preferences page,
allowing the user to add it if desired.  During the actual construction of
the CM, the 'Menu' string will be stripped from the name of the submenu which
will be added, in this example appearing as 'Notes'.  In this case, the
package: notes has already defined a menu with this stripped name, so nothing
more needs to be done here.

Packages that already create submenus for Alpha's global menu bar will find
that adding a CM submenu involves just this one line of extra code, so long
as a menu build proc is registered.

(Only defined submenus can be added this way, not menus created for the menu
bar with alpha::menu or addMenu.)

These preferences should be declared in a package's initialization script so
that they're available the first time the CM is created.  Because the number
of potential modules is virtually unlimited, it is considered bad practice to
set the initial value of these preferences to '1' -- simply let the user know
in a help file that the module is available, and allow him/her to choose to
activate it.

If your package has not been activated the first time that the CM is built
(which will always be well past initialization, btw), the user's module pref
for your package will be ignored.  If your package is not likely to be
globally activated but is intended for a specific mode, simply declare the
preference for each mode which might make use of it as described below.

	  	Adding Global Items

It is also possible to add an item that appears in the third section of the
main CM, although this is not recommended -- given that there will be a lot
of possibilities for adding CM items/submenus, the CM could get very busy
very quickly which kind of defeats the purpose of the whole exercise.

Given that ...  simply define a preference WITHOUT 'Menu' at the end of its
name.  If the name ends with 'Item' that will be stripped from the item's
name before being inserted into the CM. (The rationale here is that it will
be much easier for a user to know what they're adding or removing in the
prefs dialog if each name ends with 'Menu' or 'Item', although we don't place
that as a hard restriction for 'items'.)

However, you're not done yet.  These items will not be routed through a
submenu's menu proc, as they are with the submenus described above, but
rather through 'contextualMenu::contextualProc'.  In order for the item's
procedure to be properly called, you must define a proc with either the name

	<mode>::<menuItemName>
  
or

	contextualMenu::<menuItemName>

No arguments are passed -- the proc must get the CM click position via the
"alpha::CMArgs" variable.

An alternative is to register a 'contextualMenuHandler' hook -- this is
passed through the proc: contextualMenu::contextualProc, along with some
arguments as indicated.  Note that once this hook is registered, it is called
even if the contextualMenu preference has been turned off.  For this reason
it is best to check to see if the item is still active before making any
calls to the command: enableMenuItem .

	  	Adding Mode Specific CM Menus and Items

Mode specific CM modules appear in the second section of the CM, and can be
turned on and off by the user in a separate page presented in the "Contextual
Menu Items" dialog.  These can be defined both by a mode or by a package that
might be activated by the mode.

This is done just as in (1) and (2), except that the preference should be
declared for 'contextualMenu<mode>', as in:

	newPref flag someCMThing<Menu/Item> 0 contextualMenu<mode>

which in practice will look something like:

	newPref f tclUtilsMenu 0 contextualMenuTcl

These menus must also have a build proc declared, as in:

	menu::buildProc "tclUtils" Tcl::buildCMUtils

and similar to global menus, should take the CM click position into account
rather than the cursor position when both building the menu and executing the
item.

While package modules should always be initially turned off, mode developers
have complete discretion in deciding which mode specific CM modules defined
in the mode's source files should be turned on by default.

	  	Dimming CM modules

Any submenu can dim or mark items within it via a menu 'post build proc' in
the normal manner -- see the examples below.  To dim menus or items within
the main CM, register a 'contextualPostBuildHook' instead, as in

	hook::register contextualPostBuildHook {somePackage::postBuildCM}
  
This will be called each time after the CM is built.  If the module is mode
specific, add a <mode> argument at the end, as in

	hook::register contextualPostBuildHook {Tcl::dimCM} "Tcl"
  
so that the hook is only called when in "Tcl" mode, for example.

	  	'selectionDesc'

See the notes preceeding the proc: contextualMenuHook regarding the
"selectionDesc" argument in 'alpha::CMArgs'.  Note that in Windows, calls to
TclAE procedures will throw either throw an error or produce meaningless
dummy results, so if your module wants to make use of this information please
conditionalize this use based on the value of the global variable
'alpha::macos'.

	  	CM tooltip help tags

As with all preferences defined with [newPref], any comments which
immediately precede this command will be indexed as "prefs help".  This will
be available to the user either as "tooltip" tags (if available) or via the
"Modules Help" button that appears in the dialog.  Do _not_ use this sort of
description:

	# Turn this item on to include a 'Recent Dirs' submenu in the
	# contextual pop-up menu|| Turn this item off to remove the 'Open
	# Recent Dir' submenu from the contextual pop-up menu
	newPref f recentDirsMenu       0 contextualMenu

These descriptive strings should assume that the user is looking at the
dialog, and already knows that checking a flag next to a CM module's name
will insert something new into the CM.

These tooltip tags will be much more useful if they let the user know what
sorts of items will be included, and what happens when these items are
selected, as in

	# Includes the directory names of the most recently opened files.
	# Selecting a directory name will trigger an "Open File" dialog using
	# that directory as the default location.
	newPref f recentDirsMenu       0 contextualMenu

Don't bother with the "||" construction that displayed different help tags
depending on the status of the checkbox; it is largely obsolete.

	------------------------------------------------------------------

	  	To Do:

¥ Create more mode/click position specific contextual items !!!

Some of the following would give developers/users more control over how the
items in the CM are presented, but adding more user control also contributes
to the idea that Alpha takes a lot of time to configure ...

¥ Create some method to allow packages/modes to decide where in the
  menu the item should be placed?  The current scheme feels pretty
  intuitive to me -- with mode specific items being given priority over
  global items, and all of these lists being sorted alphabetically.
  More control == longer time to build the CM ??
  
¥ Along with the above, perhaps a package API to declare items would be
  in order.  Currently, a mode/package only has to declare a [newPref]
  and a 'menu build proc' to interface with the CM, which seems pretty
  minimal, but perhaps a
  
	contextualMenu::register
  
  procedure could be created which takes 'name' 'where' 'value' 'global/mode'
  arguments would be easier.  One problem with this is where to define such a
  procedure -- we want to avoid sourcing this file until init is complete,
  and if a mode or package is calling the proc before this package's init
  script is sourced, there might be trouble.  (This shouldn't be such an
  issue now that we use the proc: prefs::isRegistered .)
  
¥ Give the user control over the order in which items are presented.
  More control == longer time to build the CM ??

}
    new -n $title -tabsize 4 -info $txt
    help::markColourAndHyper
    return
}

# ==========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Contextual Menu ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "contextualMenu::buildContextualMenu" --
 # 
 # The main task here is to define the menu proc that will be used for the
 # top level CM items.  The actual building of the menu takes place in
 # 'contextualMenuHook'.
 # 
 # --------------------------------------------------------------------------
 ##

proc contextualMenu::buildContextualMenu {} {
    return [list build {} {contextualMenu::contextualProc} {}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "contextualMenu::contextualMenu" --
 # 
 # The main task here is add to the list of items used in creating the CM.
 # The actual building of the menu takes place in 'contextualMenuHook'.
 # 
 # --------------------------------------------------------------------------
 ##

proc contextualMenu::contextualMenu {menuName args} {
    
    # In case other packages want to know the name of the main CM menu.
    variable cmMenuName $menuName
    
    menu::buildProc $menuName contextualMenu::buildContextualMenu
    # Add the menus/items
    foreach item [listMenuItems] {
	if {[regsub "Menu$" $item {} item]} {
	    lappend ::menu::additions($menuName) [list submenu end $item]
	} else {
	    regsub "Item$" $item {} item
	    lappend ::menu::additions($menuName) [list items end $item]
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "contextualMenu::listMenuItems" --
 # 
 # Create the list (including dividers) of CM items based on global/mode
 # prefs associated with this package.  We'll do this separately and call
 # it above just in case some other code wants to get the actual list.
 # 
 # --------------------------------------------------------------------------
 ##

proc contextualMenu::listMenuItems {} {
    
    set m [win::getMode]
    
    global contextualMenumodeVars contextualMenu${m}modeVars
    
    variable menuSections
    variable ModeItemsOff
    
    if {[info exists ModeItemsOff($m)]} {
	set ignoreList $ModeItemsOff($m)
    } else {
	set ignoreList [list]
    }
    lappend ignoreList "contextualMenuUtilsMenu"
    
    set list1 [list]
    set list2 [list]
    set list3 [list]
    set list4 [list]
    # This is set of items potentially appearing at the top of the CM.
    set begList [lsort -dictionary -unique $menuSections(1)]
    # This is set of items potentially appearing at the bottom of the CM.
    set endList [lsort -dictionary -unique $menuSections(4)]
    # Add items as needed to the top of the list.
    foreach pref $begList {
	if {![info exists contextualMenumodeVars($pref)] \
	  || ![prefs::isRegistered $pref "contextualMenu"] \
	  || !$contextualMenumodeVars($pref) \
	  || [lcontains ignoreList $pref] } {
	    continue
	}
	lappend list1      $pref
	lappend ignoreList $pref
    }
    # Add any additional mode specific items.
    if {[string length $m]} {
	foreach pref [array name [lsort -dictionary contextualMenu${m}modeVars]] {
	    if {![prefs::isRegistered $pref "contextualMenu${m}"] \
	      || ![set contextualMenu${m}modeVars($pref)]} {
		continue
	    }
	    lappend list2 $pref
	}
    }
    # Add any additional global items.
    foreach pref [array names contextualMenumodeVars] {
	# Only add it if it doesn't appear above, below, but has been
	# declared using [newPref] (and is activated).
	if {[lcontains ignoreList $pref] \
	  || [lcontains endList $pref] \
	  || ![prefs::isRegistered $pref "contextualMenu"] \
	  || !$contextualMenumodeVars($pref) } {
	    continue
	}
	lappend list3      $pref
	lappend ignoreList $pref
    }
    # Add items as needed to the bottom of the list.
    foreach pref $endList {
	if {![info exists contextualMenumodeVars($pref)] \
	  || ![prefs::isRegistered $pref "contextualMenu"] \
	  || !$contextualMenumodeVars($pref)  \
	  || [lcontains ignoreList $pref] } {
	    continue
	}
	lappend list4 $pref
    }
    # Now create the final list.
    set finalList $list1
    foreach section [list 2 3 4] {
	if {[llength [set list${section}]]} {
	    if {[llength $finalList]} {
		lappend finalList "(-)"
	    }
	    eval lappend finalList \
	      [lsort -dictionary -unique [set list${section}]]
	}
    }
    if {$contextualMenumodeVars(contextualMenuUtilsMenu)} {
	# This one is always added at the end.
	if {[llength $finalList]} {
	    lappend finalList "(-)"
	}
	lappend finalList contextualMenuUtilsMenu
    }
    return $finalList
}

## 
 # --------------------------------------------------------------------------
 # 
 # "contextualMenu::postBuild" --
 # 
 # Dim submenus in the main CM if appropriate.  Only applies to modules
 # defined in this package.  Modes or packages which want to also perform
 # some tests should register their own 'contextualPostBuildHook', which can
 # also take a 'mode' argument, as in
 # 
 #   hook::register contextualPostBuildHook {Tcl::dimCM} "Tcl"
 #   
 # so that the hook is only called when in "Tcl" mode, for example.
 # 
 # --------------------------------------------------------------------------
 ##

proc contextualMenu::postBuild {menuName args} {
    
    # 'win::IsFile' automatically strips <2> window count.
    set isFile [win::IsFile [win::Current]]
    
    # Dim "Window Path" if window isn't a file.
    if {$::contextualMenumodeVars(windowPathMenu)} {
	enableMenuItem $menuName "windowPath" $isFile
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "contextualMenu::contextualProc" --
 # 
 # The proc called for all main CM items.
 # 
 # --------------------------------------------------------------------------
 ##

proc contextualMenu::contextualProc {menuName itemName} {
    
    if {[info proc ::${::mode}::${itemName}] != ""} {
	# Item is defined within the mode's namespace.  (Recommended)
	::${::mode}::${itemName}
    } elseif {[info proc $itemName] != ""} {
	# Item is defined with the 'contextualMenu' namespace.
	$itemName
    } else {
	# Hopefully item is defined via a handler hook.
	hook::callAll contextualMenuHandler $::mode $menuName $itemName
    }
    return
}

# ×××× Contextual Menu Utilities ×××× #

## 
 # --------------------------------------------------------------------------
 # 
 # "contextualMenu::clickWord" --
 # 
 # Given a click position, determine if there is a word surrounding it.  We
 # can't use 'text::surroundingWord' because that uses the cursor position,
 # and manipulates the selection which might be outside the visible
 # parameters of the window.  We remember the word and positions in case
 # several procs are calling this in the course of building CM submenus so
 # that we only have to do it once.
 # 
 # --------------------------------------------------------------------------
 ##

proc contextualMenu::clickWord {} {
    
    variable lastCMArgs
    variable clickWord
    
    if {$::alpha::CMArgs == $lastCMArgs} {return $clickWord}
    
    set lastCMArgs $::alpha::CMArgs
    if {[regexp {\s} [lookAt [set pos [lindex $::alpha::CMArgs 0]]]]} {
	set pos [pos::prevChar $pos]
    }
    
    set clickWord [pos::currentWord $pos]
    return $clickWord
}

proc contextualMenu::isSelection {} {
    
    set pos1 [lindex $::alpha::CMArgs 1]
    set pos2 [lindex $::alpha::CMArgs 2]
    if {[pos::compare $pos1 != $pos2]} {
	return 1
    } else {
	return 0
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

# ×××× Look Up In Dictionary ×××× #

## 
 # --------------------------------------------------------------------------
 # 
 # "contextualMenu::lookUpInDictionary" --
 # 
 # In Mac OS X, send the current word to "Dictionary.app" 
 # 
 # Known bugs:
 # 
 # (*) "Dictionary.app" must be launched before "dict:///word" will work.
 # 
 # (*) "Dictionary.app" cannot handle diacritics via [exec open dict:///...]
 # such as "dict:///na•ve"; using [quote::Url] or [unicode::decompose] has no
 # positive effect.  If this is ever fixed, use "[\w]" instead of "[a-zA-Z]"
 # in the [regexp] calls below.
 # 
 #     exec open "dict:///na•vetŽ"
 #     exec open "dict:///[quote::Url na•vetŽ]"
 #     exec open "dict:///[unicode::decompose na•vetŽ]"
 # 
 # (*) If the word doesn't exist in the dictionary, the user is only informed
 # by an unchanged "Dictionary.app" window.
 # 
 # --------------------------------------------------------------------------
 ##

proc contextualMenu::lookUpInDictionary {{word ""}} {
    
    global alpha::macos
    
    if {($alpha::macos != 2)} {
	error "Cancelled -- only available in Mac OS X."
    }
    if {($word eq "")} {
	set word [lindex [contextualMenu::clickWord] 0]
    }
    while {1} {
	set word [string trim $word]
	if {[regexp {^[a-zA-Z]+$} $word]} {
	    break
	} 
	set word [prompt "Look up in Dictionary:" $word]
	if {[regexp {\s} $word]} {
	    alertnote "The word cannot contain any spaces."
	} elseif {[regexp {_} $word]} {
	    alertnote "The word cannot contain any underscores."
	} elseif {[regexp {^[\w]+} $word] && ![regexp {^[a-zA-Z]+$} $word]} {
	    alertnote "Sorry, diacritic characters cannot be used."
	} elseif {![regexp {^[a-zA-Z]+$} $word]} {
	    alertnote "The word must be alpha-numeric."
	}
    }
    # We need the "dummy" call to ensure that "Dictionary.app" is launched.
    exec open "dict:///"
    exec open "dict:///$word"
    # Alternative method:
    # url::execute "dict:///" ; url::execute "dict:///$word"
    return
}

# ×××× Related Files Menu ×××× #

menu::buildProc "relatedFiles" {contextualMenu::buildRelated}

proc contextualMenu::buildRelated {} {
    
    set menuList [list]
    if {[llength [info procs ::${::mode}::OptionTitlebar]]} {
	set menuList [::${::mode}::OptionTitlebar]
    }
    if {![llength $menuList]} {
	set menuList [::OptionTitlebar]
    }
    if {![llength $menuList]} {
	set menuList [list "(No related files found"]
    }
    return [list build $menuList {contextualMenu::related -c -m}]
}

proc contextualMenu::related {menuName itemName} {
    hook::callProcForWin OptionTitlebarSelect "" $itemName
    return
}

# ×××× Text Utils Menu ×××× #

menu::buildProc "textUtils" {contextualMenu::buildTextUtils}

proc contextualMenu::buildTextUtils {} {
    
    if {![contextualMenu::isSelection]} {
	set menuList [list \
	  "fillParagraph" "indentLine" "commentLine" "uncommentLine" \
	  "(-)" "wordCount"
	]
    } else {
	set menuList [list \
	  "fillRegion" "indentSelection" "commentRegion" "uncommentRegion" \
	  "(-)" "sortLines" "reverseSortLines" "wordCount" \
	  "(-)" "allTabsToSpaces" "allSpacesToTabs" \
	  "leadingTabsToSpaces" "leadingSpacesToTabs" \
	  "(-)" "downcaseRegion" "upcaseRegion" \
	  ]
    }
    return [list build $menuList {contextualMenu::textUtils}]
}

proc contextualMenu::textUtils {menuName itemName} {
    
    if {![contextualMenu::isSelection]} {
	# No selection surrounding click point.
	goto [lindex $::alpha::CMArgs 0]
    }
    switch $itemName {
	"commentRegion"    {set itemName "commentLine"}
	"uncommentRegion"  {set itemName "uncommentLine"}
	"reverseSortLines" {set itemName "reverseSort"}
    }
    menu::textEditProc "" $itemName
    return
}

# ×××× Window Marks Menu ×××× #

menu::buildProc "windowMarks" {buildMarksMenu}

# ×××× Window Path Menu ×××× #

# This should be the same behavior as clicking on the title bar.  It
# probably needs some revision to work properly in AlphaX.  Also works for
# remote files.

menu::buildProc "windowPath" {contextualMenu::buildPath} \
  {contextualMenu::postBuildPath}

proc contextualMenu::buildPath {} {
    
    variable pathElements
    variable pathProc
    
    unset -nocomplain pathElements
    
    # If a hooked procedure can handle this, let it.
    set win [win::Current]
    set cmd [list hook::callForWin titlebarPathHook "untilok" $win $win]
    if {[catch $cmd res]} {
	set res [buildPathMenu]
    }
    # In order to avoid ambiguous path elements like 
    # 
    #   iBook:alpha:test:alpha:file.txt
    # 
    # we'll go through this routine now.  The real titlebar menu
    # (see titlebarSelectProc) handles this menu in a special
    # hard-coded fashion which avoids this code (but complicates
    # Alpha's core).
    set elements [lreverse [lindex $res 1]]
    set eltsSoFar [list]
    set menuList [list]
    foreach item $elements {
	lappend elts $item
	while {[info exists pathElements($item)]} {
	    append item " "
	}
	lappend menuList $item
	set pathElements($item) $elts
    }
    set pathProc [lindex [lindex $res 2] 0]
    set menuList [concat [lreverse $menuList] [list "Ç-- Show in Finder --È"]]
    return [list "build" $menuList {contextualMenu::path -c -m} {}]
}

proc contextualMenu::postBuildPath {args} {
    
    if {![win::IsFile [set path [win::Current]]]} {
	enableMenuItem -m "windowPath" $path 0
    }
    return
}

# Procedure which takes a call to the contextual windowPath menu
# and converts it into a call to the original titlebar proc.
proc contextualMenu::path {menuName itemName} {
    
    variable pathElements
    variable pathProc
    
    if {[info exists pathElements($itemName)]} {
	eval $pathProc [list "windowPath" $pathElements($itemName)]
    } elseif {($itemName eq "Ç-- Show in Finder --È")} {
	win::showInFinder [win::Current]
    } else {
	error "Cancelled -- couldn't find directory for $itemName"
    }
    return
}

# ×××× -------- ×××× #

# ×××× Contextual Menu Utils Menu ×××× #

proc contextualMenu::cMUtils {menuName itemName} {
    
    switch $itemName {
	"Contextual Menu Prefs"  {contextualMenu::contextualMenuItems}
	"Contextual Menu Help"   {package::helpWindow "contextualMenu"}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "contextualMenu::contextualMenuItems" --
 # 
 # Creates a dialog to turn on/off global contextualMenu preferences, as well
 # as those associated only with a particular mode.  This is called by the
 # "Config > Packages > Contextual Menu Items > Prefs" menu item, as well as
 # the menu item in the CM Utils pop-up menu.
 # 
 # If this item was in the "Config > Packages" menu, it should be named
 # 
 #   global::contextualMenuItems
 #   
 # in order to be properly called.  (And don't name the menu item with
 # "Prefs" instead of "Items" because a default dialog will be used instead
 # of this one.)
 # 
 # The 'Help' button opens up help for this package.  If "tooltip" tags are
 # not available, we include a "Modules Help" button that includes the
 # description for each.
 # 
 # --------------------------------------------------------------------------
 ##

proc contextualMenu::contextualMenuItems {} {
    
    set m [win::getMode]
    set M [mode::getName $m 1]
    
    global contextualMenumodeVars contextualMenu${m}modeVars alpha::macos
    
    variable dialogFlagHelp
    variable lastChosenPane
    variable ModeItemsOff
    
    array unset dialogFlagHelp
    
    # Preliminaries.
    watchCursor
    foreach item [list "Global" "ModeOnly" "ModeOff"] {
	foreach type [list "Items" "Values" "Help"] {
	    set flag${type}${item} [list]
	}
    }
    set prefVariables    [prefs::dialogs::setVariables]
    set standardHeight   [lindex $prefVariables 0]
    set standardWidth    [lindex $prefVariables 1]
    set flagColumns      [lindex $prefVariables 2]
    set listboxAvailable [lindex $prefVariables 3]
    set listboxOffset    [lindex $prefVariables 4]
    set tooltipAvailable [lindex $prefVariables 5]
    
    # Collect the list of known (registered) CM modules.
    set globalCMPrefs [list]
    foreach globalPref [array names contextualMenumodeVars] {
	if {![prefs::isRegistered $globalPref "contextualMenu"]} {
	    continue
	}
	lappend globalCMPrefs $globalPref
    }
    set globalCMPrefs [lsort -dictionary $globalCMPrefs]
    if {($m ne "") && [info exists ModeItemsOff($m)]} {
	set modeItemsTurnedOff $ModeItemsOff($m)
    } else {
	set modeItemsTurnedOff [list]
    }
    foreach item $globalCMPrefs {
	set itemHelp [help::itemDescription $item contextualMenu]
	lappend flagItemsGlobal  [quote::Prettify $item]
	lappend flagValuesGlobal $contextualMenumodeVars($item)
	lappend flagHelpGlobal   $itemHelp
	if {($m eq "")} {
	    continue
	}
	lappend flagItemsModeOff  [quote::Prettify $item]
	lappend flagValuesModeOff [lcontains modeItemsTurnedOff $item]
	lappend flagHelpModeOff   $itemHelp
    }
    if {($m ne "")} {
	set modeCMPrefs [list]
	foreach cmPref [array names contextualMenu${m}modeVars] {
	    if {![prefs::isRegistered $cmPref "contextualMenu$m"]} {
		continue
	    }
	    lappend modeCMPrefs $cmPref
	}
	set modeCMPrefs [lsort -dictionary $modeCMPrefs]
	foreach item $modeCMPrefs {
	    set itemHelp [help::itemDescription $item contextualMenu${m}]
	    lappend flagItemsModeOnly  [quote::Prettify $item]
	    lappend flagValuesModeOnly [set contextualMenu${m}modeVars($item)]
	    lappend flagHelpModeOnly   $itemHelp
	}
    }
    
    # Create the dialog script in several pieces: the global options and mode
    # options, each in several different panes.
    set title "Contextual Menu Modules"
    set buttons [list \
      "CM Help" \
      "Click here for more information about the Contextual Menu." \
      "set retCode 1 ; set retVal {cancel} ; \
      package::helpWindow {contextualMenu}" \
      ]
    if {!$tooltipAvailable} {
	lappend buttons "Modules Help" \
	  "Click here for module specific information." \
	  [list contextualMenu::_prefsHelp $title]
    }
    set paneNames    [list]
    set dialogPanes  [list]
    set dialogScript [list dialog::make -title $title -addbuttons $buttons]
    set width $standardWidth
    if {($listboxAvailable)} {
	lappend dialogScript -pager "listbox"
	incr width $listboxOffset
    }
    lappend dialogScript -width $width
    set height      [expr {(300 < $standardHeight) ? 300 : $standardHeight}]
    set flagsInPane [expr {(($height - 50)/15)}]
    if {($flagsInPane % 2)} {
	incr flagsInPane
    }
    set flagsInPane 14
    
    # Create the Introduction pane.
    set introText "This dialog allows you to adjust the presentation of\
      different \"modules\" in Contextual Menus. The CM is invoked by "
    if {$alpha::macos} {
	append introText "pressing Control and the mouse button simultaneously."
    } else {
	append introText "clicking the mouse's right button."
    }
    set s [expr {([llength $buttons] > 3) ? "s" : ""}]
    append introText "\r\rIndividual CM modules (menus or items) can be\
      added/removed from the CM via the dialog panes which follow.\
      \r\rNote that this dialog, like the CM itself, is mode specific,\
      and you can change the modules associated with the mode of the\
      current window as well as 'global' settings.\r"
    set introHelp "For more information, press the help button$s below."
    set dialogPane [list "Introduction" [list "thepage" "thepage"]]
    if {$listboxAvailable} {
	lappend dialogPane \
	  [list "text" "Introduction: Contextual Menu modules"] \
	  [list "divider" "divider"]
    }
    lappend dialogPane  [list "text" $introText] [list "text" $introHelp]
    lappend dialogPanes $dialogPane
    lappend paneNames   "Introduction"
    set dialogFlagHelp(Introduction) [list \
      [list "Introduction"] [list $introText]]
    
    if {[info exists lastChosenPane($title)] \
      && ([lsearch $paneNames $lastChosenPane($title)] > -1)} {
	lappend dialogScript "-defaultpage" $lastChosenPane($title)
    }
    
    # Global CM modules.
    set modulesLength [llength $flagItemsGlobal]
    for {set i 0} {($i < $modulesLength)} {incr i $flagsInPane} {
	set idx1 $i
	if {([set idx2 [expr {$i + $flagsInPane - 1}]] >= $modulesLength)} {
	    set idx2 "end"
	}
	set paneName  "Global CM"
	set moduleName1 [lindex $flagItemsGlobal $idx1]
	set moduleName2 [lindex $flagItemsGlobal $idx2]
	set moduleRange ""
	append moduleRange ": " [string range $moduleName1 0 1] " - " \
	  [string range $moduleName2 0 1]
	if {($modulesLength > $flagsInPane)} {
	    append paneName $moduleRange
	}
	while {([lsearch $paneNames $paneName] > -1)} {
	    append paneName " "
	}
	lappend paneNames $paneName
	set dialogPane [list $paneName]
	if {$listboxAvailable} {
	    set PaneName "Global Contextual Menu modules"
	    if {($modulesLength > $flagsInPane)} {
		append PaneName $moduleRange
	    }
	    lappend dialogPane [list "text" $PaneName] \
	      [list "divider" "divider"]
	}
	lappend dialogPane [list [list "multiflag" \
	  [lrange $flagItemsGlobal  $idx1 $idx2] 2] \
	  "These CM modules have been designed to be used in any mode.\
	  Check any module name to turn it on globally:\r" \
	  [lrange $flagValuesGlobal $idx1 $idx2] \
	  [lrange $flagHelpGlobal   $idx1 $idx2]]
	lappend dialogPanes $dialogPane
	set dialogFlagHelp($paneName) [list \
	  [lrange $flagItemsGlobal $idx1 $idx2] \
	  [lrange $flagHelpGlobal  $idx1 $idx2]]
    }
    
    # Mode-specific CM modules.
    if {($m ne "")} {
	set modulesLength [llength $flagItemsModeOnly]
	set modeIntroText "Some CM modules have been designed to provide\
	  functions that are specific to the mode of the active window.\r"
	if {!$modulesLength} {
	    lappend paneNames "$M mode CM"
	    set dialogPane [list "$M mode CM"]
	    if {$listboxAvailable} {
		set PaneName "$M mode Contextual Menu modules"
		lappend dialogPane [list "text" $PaneName] \
		  [list "divider" "divider"]
	    }
	    lappend dialogPane \
	      [list "text" $modeIntroText] \
	      [list "text" "No such modules are available for $M mode."]
	    lappend dialogPanes $dialogPane
	    set dialogFlagHelp($paneName) [list \
	      [list $paneName] [list $modeIntroText]]
	}
	for {set i 0} {($i < $modulesLength)} {incr i $flagsInPane} {
	    set idx1 $i
	    if {([set idx2 [expr {$i + $flagsInPane - 1}]] >= $modulesLength)} {
		set idx2 "end"
	    }
	    set paneName  "$M mode CM"
	    set moduleName1 [lindex $flagItemsModeOnly $idx1]
	    set moduleName2 [lindex $flagItemsModeOnly $idx2]
	    set moduleRange ""
	    append moduleRange ": " [string range $moduleName1 0 1] " - " \
	      [string range $moduleName2 0 1]
	    if {($modulesLength > $flagsInPane)} {
		append paneName $moduleRange
	    }
	    while {([lsearch $paneNames $paneName] > -1)} {
		append paneName " "
	    }
	    lappend paneNames $paneName
	    set dialogPane [list $paneName]
	    if {$listboxAvailable} {
		set PaneName "$M mode Contextual Menu modules"
		if {($modulesLength > $flagsInPane)} {
		    append PaneName $moduleRange
		}
		lappend dialogPane [list "text" $PaneName] \
		  [list "divider" "divider"]
	    }
	    lappend dialogPane [list "text" $modeIntroText] \
	      [list [list "multiflag" \
	      [lrange $flagItemsModeOnly  $idx1 $idx2] 2] \
	      "These modules have been designed specifically for $M mode:\r" \
	      [lrange $flagValuesModeOnly $idx1 $idx2] \
	      [lrange $flagHelpModeOnly   $idx1 $idx2]]
	    lappend dialogPanes $dialogPane
	    set dialogFlagHelp($paneName) [list \
	      [lrange $flagItemsModeOnly $idx1 $idx2] \
	      [lrange $flagHelpModeOnly  $idx1 $idx2]]
	}
	
	set modulesLength [llength $flagItemsModeOff]
	for {set i 0} {($i < $modulesLength)} {incr i $flagsInPane} {
	    set idx1 $i
	    if {([set idx2 [expr {$i + $flagsInPane - 1}]] >= $modulesLength)} {
		set idx2 "end"
	    }
	    set paneName  "Disable"
	    set moduleName1 [lindex $flagItemsModeOff $idx1]
	    set moduleName2 [lindex $flagItemsModeOff $idx2]
	    set moduleRange ""
	    append moduleRange ": " [string range $moduleName1 0 1] " - " \
	      [string range $moduleName2 0 1]
	    if {($modulesLength > $flagsInPane)} {
		append paneName $moduleRange
	    }
	    while {([lsearch $paneNames $paneName] > -1)} {
		append paneName " "
	    }
	    lappend paneNames $paneName
	    set dialogPane [list $paneName]
	    if {$listboxAvailable} {
		set PaneName "Disable CM modules for $M mode"
		if {($modulesLength > $flagsInPane)} {
		    append PaneName $moduleRange
		}
		lappend dialogPane [list "text" $PaneName] \
		  [list "divider" "divider"]
	    }
	    lappend dialogPane \
	      [list [list "multiflag" \
	      [lrange $flagItemsModeOff  $idx1 $idx2] 2] \
	      "Check any of these boxes to turn \"global\" modules off\
	      when the active window is in $M mode:\r" \
	      [lrange $flagValuesModeOff $idx1 $idx2] \
	      [lrange $flagHelpModeOff   $idx1 $idx2]]
	    lappend dialogPanes $dialogPane
	    set dialogFlagHelp($paneName) [list \
	      [lrange $flagItemsModeOff $idx1 $idx2] \
	      [lrange $flagHelpModeOff  $idx1 $idx2]]
	}
    }
    
    # Now we present the dialog and collect the results.
    if {[info exists lastChosenPane($title)] \
      && ([lsearch $paneNames $lastChosenPane($title)] > -1)} {
	lappend dialogScript "-defaultpage" $lastChosenPane($title)
    }
    set results [eval $dialogScript $dialogPanes]
    set lastChosenPane($title) [lindex $results 0]
    prefs::modified lastChosenPane($title)
    for {set i 1} {($i < [llength $results])} {incr i} {
	eval [list lappend newValues] [lindex $results $i]
    }
    
    # Adjust the current settings as required.
    for {set i 0} {($i < [llength $globalCMPrefs])} {incr i} {
	set newValue [lindex $newValues $i]
	set oldValue [lindex $flagValuesGlobal $i]
	if {($newValue ne $oldValue)} {
	    set prefName [lindex $globalCMPrefs $i]
	    set contextualMenumodeVars($prefName) $newValue
	    prefs::modified contextualMenumodeVars($prefName)
	}
    }
    if {($m ne "")} {
	set newValues [lrange $newValues $i end]
	for {set i 0} {($i < [llength $modeCMPrefs])} {incr i} {
	    set newValue [lindex $newValues $i]
	    set oldValue [lindex $flagValuesModeOnly $i]
	    if {($newValue ne $oldValue)} {
		set prefName [lindex $modeCMPrefs $i]
		set contextualMenu${m}modeVars($prefName) $newValue
		prefs::modified contextualMenu${m}modeVars($prefName)
	    }
	}
	set newValues [lrange $newValues $i end]
	set newModeItemsOff [list]
	for {set i 0} {($i < [llength $globalCMPrefs])} {incr i} {
	    if {[lindex $newValues $i]} {
		set prefName [lindex $globalCMPrefs $i]
		lappend newModeItemsOff [lindex $globalCMPrefs $i]
	    }
	}
	if {($modeItemsTurnedOff ne $newModeItemsOff)} {
	    set ModeItemsOff($m) $newModeItemsOff
	    prefs::modified ModeItemsOff($m)
	    if {![llength $ModeItemsOff($m)]} {
		unset ModeItemsOff($m)
	    }
	}
    }
    status::msg "Contextual Menu preferences have been saved."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "contextualMenu::_prefsHelp" --
 # 
 # Called by [contextualMenu::contextualMenuItems] "Modules Help" button,
 # create a new dialog with preferences information.  If tooltip tags are
 # available, then this button will not be presented.
 # 
 # Based (in spirit, at least) on [prefs::dialogs::_prefsHelp].
 # 
 # --------------------------------------------------------------------------
 ##

proc contextualMenu::_prefsHelp {title} {
    
    variable dialogFlagHelp
    
    set prefVariables  [prefs::dialogs::setVariables]
    set standardHeight [lindex $prefVariables 0]
    set standardWidth  [lindex $prefVariables 1]
    
    upvar 1 helpA helpA
    upvar 1 pages pages
    upvar 1 currentpage currentpage
    
    set dialogPanes [list]
    foreach {paneName paneItems} $pages {
	set dialogPane [list $paneName]
	if {![info exists dialogFlagHelp($paneName)]} {
	    set dialogFlagHelp($paneName) [list]
	}
	set flagLength [llength [lindex $dialogFlagHelp($paneName) 0]]
	for {set i 0} {($i < $flagLength)} {incr i} {
	    set flagItem [lindex $dialogFlagHelp($paneName) 0 $i]
	    set flagHelp [lindex $dialogFlagHelp($paneName) 1 $i]
	    if {([string trim $flagHelp] eq "")} {
		set flagHelp "(No information available.)"
	    } else {
		regsub -all {\|.*} $flagHelp {} flagHelp
	    }
	    lappend dialogPane \
	      [list [list discretionary $standardHeight]] \
	      [list "text" "$flagItem : $flagHelp \r"]
	}
	lappend dialogPanes $dialogPane
    }
    catch {eval [list dialog::make -cancel {} -defaultpage $currentpage \
      -title "Help for $title" -width $standardWidth] $dialogPanes}
    return
}

# ===========================================================================
#
# ×××× ------------ ×××× #
# 
# ×××× Version History ×××× #
# 
#  modified by  rev    reason
#  -------- --- ------ -----------
# 01-31-01 JEG 0.1    Original.
# 01-06-02 JL  0.2    Added handler of top level menu items.
# 02-10-02 cbu 0.3    Changed package name to "contextualMenu".
#                     Changed package to global-only feature in order to
#                       easily create a deactivation script.
#                     Added more default CM submenus: "Open Windows", 
#                       "Window Path" "Window Marks"
#                     Enhanced contextualMenu::buildContextualMenu to accept
#                       items based upon contextualMenu preferences.
#                     Modifications so that any package can declare such a
#                       preference to add an item globally to the CM.
#                     Each mode now has a "<mode> Utils" menu reserved.
# 02-26-02 cbu 0.4    Added ability for 'contextualMenu::contextualProc' 
#                       to call individual items.
#                     Each mode can now have a mode specific set of preferences
#                       which can be turned on or off.  Useful for packages
#                       which might not be global but are only active for
#                       certain modes.  Also allows for easy insertion/
#                       removal of mode menu submenus.
#                     No longer using the standard package prefs dialog.
# 02-27-02 cbu 0.5    Minor dialog improvements.  
#                     Taking advantage of the fact that we're using Tcl 8.0
#                       and calling procs within namespaces if possible.
#                     Improved support code which takes 'click position'
#                       context into account to demonstrate functionality.
#                     Speed improvement by not using 'menu::insert', which
#                       causes the menu to be rebuilt each time.  Now we
#                       simply add to the CM "menu::additions" array.
#                       The menu gets built in 'contextualMenuHook'.
#                     "Open Windows" module no longer part of this package,
#                       but should be defined in "openWindowsMenu.tcl"
#                     Improved documentation, which probably should be moved
#                       to "Extending Alpha" eventually.
#                     Removed support for "<mode> Utils" menus.
# 03-03-02 cbu 0.6    Changed 'mode' menu name to 'mode ' to reduce conflicts
#                       with 'Mode Prefs' menu.  ("elecCompletions.tcl" adds
#                       items to the 'mode' menu which is used to create
#                       the "Mode Prefs" menu.)
#                     Support code for "Open Windows" module fixed to deal with
#                       duplicate window names, i.e. <2>, now lists them all
#                       in alphabetical order w/o key bindings.
#                     Package adopted in AlphaTcl as 'always on' for Alpha8/X.
# 03-18-02 cbu 0.7    Small fixes for Windows.  (Package is now 'always on' for
#                       Alphatk, accessed via mouse right click.)
#                     Added 'Related Files' submenu, similar to option 
#                       title bar click.
#                     Added 'VCS' menu, same as on side of window bar.  Should
#                       this be moved into "vcsCore.tcl" ??  (If so, be sure
#                       to look at 'contextualMenu::postBuild' and move some
#                       vcs stuff into its own hook.)
#                     Modes can now define mode specific item procs within
#                       their own namespace, as in '<mode>::itemName' rather
#                       than 'contextualMenu::itemName' (which still works)
#                       for main CM items.
# 06-03-02 cbu 0.8    Minor fixes.
#                     We now dim some submenus in the main CM (those defined
#                       in this package) if appropriate.
#                     User can now turn global items off for specific modes.
# 06-06-02 cbu 0.9    Added 'Text Utils' module.
# 01/28/03 cbu 1.0    Greater use of Tcl 8.0, esp [variable].
#                     New [contextualMenu::isSelection] procedure.
#                     New [contextualMenu::developersHelp] window.
# 06/13/03 cbu 1.0.1  Moved 'Vcs' menu to "vcsCore.tcl"
#                     New "::contextualMenu::cmMenuName" variable.
# 09/02/03 cbu 1.0.2  [contextualMenu::buildPath] no longer includes an
#                       "empty" directory name.
# 09/19/03 cbu 1.0.3  The variable "wordBreakPreface" is going to be removed,
#                       [contextualMenu::clickWord] contains a temporary
#                       regexp pattern that should be investigated further.
# 03/27/04 cbu 1.0.4  Using [prefs::isRegisterd] to determine which modules
#                       should be used or presented to the user in dialog.
#                     Fix for "Text Utils > Reverse Sort Lines"
# 02/25/05 cbu 1.1b1  "Window Path" CM includes "Show in Finder" option.
#                     Added "-c" flag to [contextualMenu::buildRelated] 
#                       menu build proc (bug 1808).
# 06/13/05 cbu 1.1b2  Added all tab/space conversion commands.
# 01/04/06 cbu 1.1    Updated [contextualMenu::contextualMenuItems] dialog.
#                     Use [win::getMode] instead of global $mode variable.
# 02/27/06 cbu 1.2    Add tooltip help when available in the prefs dialog,
#                       otherwise offer a "Modules Help" button.
#                     Use "listbox" format for prefs dialog when available.
#                     No longer defining modules in "statusPopupMenus.tcl".
# 05/23/06 cbu 1.2.1  Added "Look Up In Dictionary" module.
# 

# ===========================================================================
# 
# .