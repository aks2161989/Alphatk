## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl core packages
 # 
 # FILE: "openWindowsMenu.tcl"
 #                                          created: 04/04/2001 {19:13:29 PM}
 #                                      last update: 05/25/2006 {10:42:44 AM} 
 #  
 # Author: Vince Darley, Craig Upright
 # 
 # Description:
 #  
 # Contains most stuff related to the 'Windows' menu in Alpha(tk).
 # 
 # Note: this code distinguishes between the permanent menu items (zoom,
 # defaultSize, etc) and the window names by always adding a trailing space
 # to the window names.
 # 
 # Copyright (c) 2001-2006  Vince Darley, Craig Upright
 #
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##
 
alpha::menu openWindowsMenu 1.0 global "¥263" {
    # Initialization script.
    win::initializeMenu
} {
    # Activation script.
    win::activateMenu 1
} {
    # Deactivation script.
    win::activateMenu 0
} description {
    Keeps track of all current open windows, and provides utilities to adjust
    the shape or arrangement of existing windows
} help {
    Windows menu
    
    This package creates and maintains the "Open Windows" menu, found in the
    main menu bar.  Use this menu to choose between open windows, and to
    adjust the shape or arrangement of existing windows
    
    This is a 'core' package that should never be turned off or uninstalled.
}

proc openWindowsMenu.tcl {} {}

namespace eval win {
    
    variable initialized
    if {![info exists initialized]} {
	set initialized 0
    }
    variable activated
    if {![info exists activated]} {
	set activated -1
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "win::initializeMenu" --
 # 
 # Called when this package is first initialized.
 # 
 # --------------------------------------------------------------------------
 ##

proc win::initializeMenu {} {
    
    variable initialized
    
    if {$initialized} {
	return
    }
    menu::buildProc openWindowsMenu win::buildWinMenu win::postBuild
    menu::buildSome openWindowsMenu
    # Contextual Menu module
    menu::buildProc "openWindows" {win::buildCMOpenWindows}
    # Includes all open windows; selecting one will make it the active window
    newPref f openWindowsMenu 1 contextualMenu
    namespace eval ::contextualMenu {
	# This is set of items potentially appearing at the start of the CM.
	lunion menuSections(1) "openWindowsMenu"
    }
    set initialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "win::activateMenu" --
 # 
 # Called when this package is turned on/off.
 # 
 # --------------------------------------------------------------------------
 ##

proc win::activateMenu {which} {
    
    global openWindowsMenu
    
    variable activated
    
    if {($which eq $activated)} {
	return
    }
    if {$which} {
	set cmd "register"
    } else {
	set cmd "deregister"
    }
    hook::$cmd requireOpenWindowsHook [list $openWindowsMenu ""] 1
    hook::$cmd requireOpenWindowsHook [list $openWindowsMenu arrangeWindows] 2
    
    hook::$cmd openHook             {win::addToMenu}
    hook::$cmd openHook             {win::rebuildCMOpenWindows}
    hook::$cmd closeHook            {win::removeFromMenu}
    hook::$cmd closeHook            {win::rebuildCMOpenWindows}
    hook::$cmd activateHook         {win::activateHook}
    hook::$cmd dirtyHook            {win::dirtyHook}
    hook::$cmd winChangedNameHook   {win::renameInMenu}
    
    prefs::$cmd "openWindows" "contextualMenu"
    
    set activated $which
    return
}

# ===========================================================================
# 
# ×××× Open Windows Menu ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "win::buildWinMenu" --
 # 
 # Build the "Open Windows" menubar menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc win::buildWinMenu {} {
    
    global openWindowsMenu winNameToNum alpha::platform
    
    set menuList {
	/M<E<Ominimize
	"//<E<Szoom"
	"//<S<I<OdefaultSize"
	{Menu -n shrinkWindow -p win::tileMenuProc {
	    full
	    high
	    low
	    left
	    right
	}}
	{Menu -n arrangeWindows -p win::tileMenuProc {
	    /J<O<Uvertically^1
	    /J<O<Ihorizontally^2
	    /J<B<OunequalVert^6
	    /J<B<I<OunequalHor^5
	    bufferOtherWindowÉ
	    (-)
	    tileAll
	    overlayAll
	    minimizeAll
	    deminimizeAll
	    (-)
	    swapWithNext
	    nextWindow
	    prevWindow
	}}
	(-)
	"/lsetFontsTabsÉ"
	<E<S/mtoggleSplitWindow
	<S<I/motherPane
	/o<EtoggleScrollbar
    }
    
    if {(${alpha::platform} eq "tk")} {
	lappend menuList "<O/otoggleLineNumbers"
    }
    lappend menuList \
      "openDuplicateÉ" \
      "(-)" \
      "/;chooseAWindowÉ" \
      "(-)"
    return [list "build" $menuList win::menuProc "" $openWindowsMenu]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "win::postBuild" --
 # 
 # Only necessary if the menu is being rebuilt for some reason, because the
 # first time it's built there should be no open windows.  Don't use
 # [winNames -f] to get the list of windows, because their order corresponds
 # to most recently in front.
 # 
 # --------------------------------------------------------------------------
 ##

proc win::postBuild {args} {
    
    global winNumToName openWindowsMenu
    
    foreach num [array names winNumToName] {
	set window $winNumToName($num)
	unset winNumToName($num)
	set windows($num) $window
    }
    foreach num [lsort -integer [array names windows]] {
	set window $windows($num)
	win::addToMenu $window
	win::markMenuItems [list $window]
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "win::markMenuItems" --
 # 
 # According to Apple's HIG, 
 # 
 #   In the Window menu, a checkmark should appear next to the active
 #   document's name.
 # 
 #   Use a bullet next to a document with unsaved changes and a diamond for a
 #   document the user has minimized into the Dock.  A minimized document
 #   with unsaved changes should have a diamond only.
 # 
 # <http://developer.apple.com/documentation/UserExperience/Conceptual/OSXHIGuidelines/XHIGMenus/chapter_16_section_3.html#//apple_ref/doc/uid/TP30000356-TPXREF115>
 # 
 # Most applications appear to use a filled-in diamond for minimized windows,
 # but that character ("\u25C6" ?) doesn't appear to be available in AlphaX's
 # [markMenuItem] command: it appears as a question mark.  We use "\u25CA"
 # (the open or white diamond) instead.
 # 
 # --------------------------------------------------------------------------
 ##

proc win::markMenuItems {{windows ""}} {
    
    global openWindowsMenu
    
    if {![llength $windows]} {
	set windows [winNames -f]
    }
    foreach w $windows {
	if {([windowVisibility -w $w] eq "hidden")} {
	    continue
	}
	set menuItem "[file tail $w] "
	markMenuItem -m $openWindowsMenu $menuItem 0 "×"
	markMenuItem -m $openWindowsMenu $menuItem 0 "Ã"
	markMenuItem -m $openWindowsMenu $menuItem 0 "¥"
	if {([windowVisibility -w $w] eq "minimized")} {
	    markMenuItem -m $openWindowsMenu $menuItem 1 "×"
	} elseif {($w eq [win::Current])} {
	    markMenuItem -m $openWindowsMenu $menuItem 1 "Ã"
	} elseif {[win::getInfo $w dirty]} {
	    markMenuItem -m $openWindowsMenu $menuItem 1 "¥"
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "win::buildCMOpenWindows" --
 # 
 # Builds an 'Open Windows' submenu for the CM. The order in which the
 # window names are presented can be changed to be:
 # 
 # ¥ alphabetical
 # ¥ most recently brought to front
 # ¥ most recently opened
 # 
 # and the bindings that appear in the menubar "Open Windows" window can
 # also be added as hints.  All of these options are currently hard-wired,
 # but preferences could be added if users request it.
 #  
 # --------------------------------------------------------------------------
 ##

proc win::buildCMOpenWindows {} {
    
    global winNameToNum winNumToName
    
    # Create the list of open windows in a desired order.  Only one
    # of the following options should be uncommented.
    
    # This builds the menu with window tail names in alphabetical order.
    if {![llength [set allWindows [winNames -f]]]} {
	Menu -m -n "openWindows" -p {} [list "\(No Open Windows"]
	return
    }
    foreach window $allWindows {
	set windowTail [file tail $window]
	lappend windowTails $windowTail
	set windowTailConnect($windowTail) $window
    }
    # This determines the order in which window names are presented.
    foreach window [lsort -dictionary $windowTails] {
	lappend windows $windowTailConnect($window)
    }
    # Given the list, build the menu with bindings.
    Menu -n "openWindows" -p {win::menuProc} {}
    foreach window $windows {
	set i ""
	if {[info exists winNameToNum($window)]} {
	    set num $winNameToNum($window)
	    if {($num == "10")} {
		set i /0
	    } elseif {[regexp {^[0-9]$} $num]} {
		set i "/$num"
	    }
	}
	addMenuItem -m -l $i openWindows "[file tail $window] "
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "win::rebuildCMOpenWindows" --
 # 
 # Rebuild the CM "Open Windows" menu.  This is called by open/close hooks,
 # and ensures that any torn-off menu will be properly updated.
 # 
 # --------------------------------------------------------------------------
 ##

proc win::rebuildCMOpenWindows {args} {
    
    global tearoffMenus contextualMenumodeVars
    
    if {$tearoffMenus && $contextualMenumodeVars(openWindowsMenu)} {
	menu::buildSome "openWindows"
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "win::menuProc" --
 # 
 # If "itemName" is a window, bring it to the front.  Otherwise perform the
 # given command on the active window.
 # 
 # Note that all window names are added to the menu with a single trailing
 # space to distinguish them from possible commands.
 # 
 # --------------------------------------------------------------------------
 ##

proc win::menuProc {menuName itemName} {
    
    global winNameToNum alpha::platform
    
    # We've added a space to all window-name menu items, so if there is no
    # space, it's a command from the top part of the menu.
    if {([string index $itemName end] ne " ")} {
	$itemName
	return
    }
    # It's a window name, so remove the space.
    set windowTail [string range $itemName 0 end-1]
    # Find all names that look as if they may match.
    set windowOptions [list]
    foreach w [array names winNameToNum] {
	if {([string match *[quote::Find $windowTail] $w] eq "1")}  {
	    lappend windowOptions $w
	}
    }
    # Out of those which match, do our best to find the right one.
    switch -- [llength $windowOptions] {
	"0" {
	    return "normal"
	}
	"1" {
	    set window [lindex $windowOptions 0]
	}
	default {
	    set foundWindow 0
	    # First look for exact matches.
	    foreach window $windowOptions {
		if {($name eq $window)} {
		    set foundWindow 1
		    break
		}
	    }
	    # If we didn't find one...
	    if {!$foundWindow} {
		# ... look for an exact file tail match.
		foreach window $windowOptions {
		    if {([file tail $name] eq $window)} {
			set foundWindow 1
			break
		    }
		}
	    }
	    if {!$foundWindow} {
		# This is odd -- not sure we should ever get here.
		set window [lindex $windowOptions 0]
	    }
	}
    }
    # Finally bring that one to the front.
    bringToFront $window
    windowVisibility -w $window "normal"
    # Alphatk has some problems with automatic handling of ticked items.
    # This workaround should be removed when those problems are correctly
    # resolved.
    if {(${alpha::platform} eq "tk")} {
	win::markMenuItems [list $window]
    }
    return
}

proc win::tileMenuProc {menu item} {
    
    if {($menu eq "shrinkWindow")} {
	set First [string toupper [string index $item 0]]
	shrink${First}[string range $item 1 end]
    } else {
	switch -- $item {
	    "vertically"	{win$item}
	    "horizontally"	{win$item}
	    "unequalVert"	{win$item}
	    "unequalHor"	{win$item}
	    "tileAll"		{wintiled}
	    "overlayAll"	{winoverlay}
	    "deminimizeAll"	{minimizeAll 0}
	    default		{$item}
	}
    }
    return
}

# ===========================================================================
# 
# ×××× Adding/Removing Windows ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "win::addToMenu" --
 # 
 # Adds a window name to the window menu.  If an optional number is given,
 # then we'll try to use that number as the shortcut (but we will always
 # check whether that number is actually available first).
 # 
 # --------------------------------------------------------------------------
 ##

proc win::addToMenu {name {i 1}} {
    
    global winNameToNum winNumToName
    
    if {![win::Exists $name]} {
	# Most likely some other procedure has closed the window while it was
	# being opened.
	return
    }
    while {[info exists winNumToName($i)]} {
	incr i
    }
    win::_addToMenu $name $i
    win::markMenuItems [list $name]
    
    set winNumToName($i) $name
    set winNameToNum($name) $i
    return
}

proc win::_addToMenu {name i} {
    
    global openWindowsMenu
    
    regsub { <[0-9]+>$} $name {} nm
    if {[file exists $nm]} {
	set nm [file tail $name]
    } else {
	set nm $name
    }
    if {($i < 11)} {
	set key [expr {$i % 10}]
	addMenuItem -m -l "/$key" $openWindowsMenu "$nm "
    } else {
	addMenuItem -m -l "" $openWindowsMenu "$nm "
    }
    return
}

proc win::removeFromMenu {name} {
    
    global winNameToNum winNumToName
    
    if {![info exists winNameToNum($name)]} {
	# The window is being closed halfway through creation, so we haven't
	# ever added it to the menu.
	return
    }
    win::_removeFromMenu $name
    
    set num $winNameToNum($name)
    unset winNumToName($num)
    unset winNameToNum($name)
    return $num
}

proc win::_removeFromMenu {name} {
    
    global openWindowsMenu
    
    regsub { <[0-9]+>$} $name {} nm
    if {[file exists $nm]} {
	set nm [file tail $name]
    } else {
	# in case it was a file but the file was actually moved!
	global tcl_platform
	if {!([set nm [file tail $name]] eq $name)} {
	    if {![catch {deleteMenuItem -m $openWindowsMenu "$nm "}]} {
		return
	    }
	}
	if {($tcl_platform(platform) eq "windows")} {
	    if {[regexp "\[^/\]+\$" $name nm]} {
		if {![catch {deleteMenuItem -m $openWindowsMenu "$nm "}]} {
		    return
		}
	    }
	}
	set nm $name
    }
    # To handle Alpha problem with rebuilding the menu.
    if {[catch {deleteMenuItem -m $openWindowsMenu "$nm "}]} {
	deleteMenuItem $openWindowsMenu "$nm "
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "win::renameInMenu" --
 # 
 # This proc ensures the shortcut 'num' for the new name is the same as the
 # shortcut for the old name.
 # 
 # --------------------------------------------------------------------------
 ##

proc win::renameInMenu {to from} {
    
    if {([file tail $from] eq [file tail $to])} {
	# The menu contents don't need to be changed.
	global winNumToName winNameToNum
	set i $winNameToNum($from)
	unset winNameToNum($from)
	set winNumToName($i) $to
	set winNameToNum($to) $i
    } else {
	set num [win::removeFromMenu $from]
	win::addToMenu $to $num
	win::markMenuItems [list $to]
    }
    return
}

# ===========================================================================
# 
# ×××× Window Hooks ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "win::activateHook" --
 # 
 # Called when a window has been brought to the front, dim/enable Windows
 # menu commands as necessary and update the markers associated with each
 # open window.
 # 
 # --------------------------------------------------------------------------
 ##

proc win::activateHook {name} {
    
    global openWindowsMenu
    
    enableMenuItem $openWindowsMenu "openDuplicateÉ" [win::IsFile $name]
    win::markMenuItems
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "win::dirtyHook" --
 # 
 # Called when the "dirty" status of a window has changed.  The active window
 # will always have the "Ã" marker, so we only adjust the bullet marker of a
 # window that is in the background.
 # 
 # --------------------------------------------------------------------------
 ##

proc win::dirtyHook {name dirty} {
    
    global openWindowsMenu
    
    if {($name ne [win::Current])} {
	markMenuItem -m $openWindowsMenu "[file tail $name] " $dirty "¥"
    }
    return
}

# ===========================================================================
# 
# Back compatibility procedures.
# 

namespace eval menu {}

proc menu::winProc {args} {
    return [eval win::menuProc $args]
}

proc menu::winTileProc {args} {
    return [eval win::tileMenuProc $args]
}

# ===========================================================================
# 
# .