## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "marks.tcl"
 #                                          created: 04/05/1998 {09:31:26 PM}
 #                                      last update: 02/08/2006 {01:21:23 PM}
 # Description:
 # 
 # Marks for front window.
 # 
 # This file is distributed under a Tcl style license.
 # 
 # ==========================================================================
 ##

# Auto-loading extension declaration.
# 
# Note that this could be an 'always on' package, and on initialization
# could add the "Named Marks" and "The Pin" submenus.

alpha::extension marks 1.0.1 {
} maintainer {
} description {
    Helps create, navigate marks within windows
} help {
    This auto-loading extension package helps create/navigate different types
    of marks within windows.  Alpha allows the user to use "marks" to
    remember positions in files.  Marks "float".  That is, if a mark is
    initially at position 312 and then five characters are inserted at
    location 297, the mark's new value will be 317.

    
	  	Table Of Contents


    "# Introduction"
    "# Permanent, Named Marks"
    "# The Window Pin"
    "# Bookmarks"
    "# Funcs Menu"
    
    <<floatNamedMarks>>
    

	  	Introduction
    
    Alpha uses three different types of marks.  One type of mark, referred to
    as "# Permanent, Named Marks", can be accessed via the 'Marks Menu' in
    the sidebar of every open window.  The Marks Menu is the one labelled
    with an M or using a paperclip icon.  Other types of window marks include
    "# The Window Pin" and "# Bookmarks".
    
    This package also implements the "# Funcs Menu" in the sidebar, which is
    an alternative, dynamically created set of named window positions.  The
    Funcs Menu has the {} icon.
    

	  	Permanent, Named Marks

    The first type of mark are the permanent marks.  Permanent marks are set,
    removed, and moved-to through the three corresponding menu items in the
    "Search > Named Marks" menu.  Permanent marks differ from the generic mark
    in that they have names, there can be any number of them, and they are
    saved in the resource fork if the file is subsequently saved.

    But setting individual marks 'by hand' can get real old real fast.  Most
    modes define their owning marking scheme based on the context of the
    current window.  Selecting 'Mark file' will generate marks for the
    current window.  In TeX mode, for example, chapters/sections etc defined
    by the strings
    
	\section{<section title>}
    
    will be identified as permanent window marks using the "Mark Window" menu
    item.  The "Marks" menu lists all marks for the current window, and
    allows them to be cleared or automatically created.  Selecting any named
    mark in the Marks menu will move the cursor to that position.  The marks
    are saved when you save the file.
    
    Refer to the mode specific help files for information about which marks
    are generated in a specific mode.

    Permanent marks can be accessed via the "Search > Named Marks" menu items,
    by a popup menu called by mousing down on the Marks Menu icon above a
    vertical scrollbar, or by Command-mousing on a window's titlebar.

    Tip: Control-Command-K will put up a listpick dialog with the current
    marks of the window.

    Tip: Command-Shift-F will create a floating menu with all of the marks in
    the current window as menu items.  Whenever you 're-mark' a window, this
    floating menu will be updated with the current marks.


	  	The Window Pin
    
    The second type of mark is referred to as "window pin".  The pin is set to
    the current insertion point by the command 'Set Pin' (Control-Space).
    (This requires that the Emacs feature is active.)  The position in the
    file indicated by the blinking cursor is referred to as the current
    insertion point.  Once the pin is set, you can use it in a variety of
    "Search > The Pin" submenu operations, such as

	Exchange Point And Pin
	Hilite To Pin

    You should try experimenting with these operations until you get used to
    them, but after a while you might see how handy they are.
    
    Tip: while the 'Hilite To Pin' has a keyboard shortcut listed in the menu,
    you'll notice that 'Exchange Point And Pin' does not.  If your keyboard
    has a numeric keypad, you should note that by default Alpha takes over the
    keypad for various navigation functions.  You can toggle this behavior on
    and off by pressing Shift-Numlock/Clear.  When the keypad is locked, NLCK
    will appear in the status bar window -- click here <<toggleNumLock>>
    several times to find it.  Keypad-5 is bound to 'Exchange Point And Pin'.
    Keypad-2 is also bound to "Hilite To Pin" for your convenience.
    
    Some commands (such as "Cut" and "Copy") can operate either on the
    currently selected (hilighted) text, or the text between the current
    insertion point and "the pin".  This is only true if the preference named
    "Cut And Copy Using Pin" is set in the preferences: Text dialog.

    For example, if you move the cursor to the beginning of the word
    "allybaba", press your keyboard shortcut for "Search > The Pin > Set Pin"
    (the status bar should say "Pin set"), move to the end of the word and hit
    Option-W or your keyboard shortcut for "Edit > Copy" (the status bar
    should say "Region copied"), the effect is the same as if you had used the
    mouse to select the text (or first called 'Hilite To Pin') and then
    selected the "Edit > Copy" menu command.

    
	  	Bookmarks

    Alpha also uses 'temporary' marks in many of its AlphaTcl routines.  Most
    of these temp marks are created/deleted behind the scenes, but one use of
    them involves the placing of 'bookmarks' throughout your collection of
    open windows.  Created via the "Search > Place Bookmark" menu item (or its
    associated keyboard shortcut), bookmarks are stacked in an incremental
    list.  The "Search > Return To Bookmark" menu item will return you to the
    most recently placed bookmark, removing it permanently from the top of the
    list.  If the last bookmark was in different window, that window is first
    brought to the front.  If the window in which that bookmark was place has
    been closed but exists on your local disk, it will be opened for you.
    
    Bookmarks are often placed for you when you perform specific actions. 
    For example, if you Command-Double-Click on a region, and the current
    mode's Command-Double-Click routine moves you to a different part of the
    current window, often a bookmark will be placed to make it easy for you
    to return to your starting point.  Clicking on hyperlinks in help windows
    will also create a bookmark so that you can easily return to where you
    started.  For example, this hyperlink "# The Window Pin" will both jump
    to that mark in this window, and place a bookmark so that you can return
    here once you're done reading that section again.  Try it!  In general,
    you will be informed in the status bar window that a bookmark has been
    automatically placed for you.


	  	Funcs Menu

    Above the vertical scrollbar on the right is an icon with curly braces
    ('{}').  This is the so called "Funcs" menu.  The content of this menu is
    mode dependent, but for modes for programming languages it usually lists
    function definitions of the current window.  Select a function in the
    menu to jump to its definition in the window.  Refer the mode specific
    help files for details about the Funcs menu for a specific mode.  The
    menu is built when you press the braces, so it is always up-to-date.

    By default, the content in this menu is sorted alphanumerically.  This
    feature can be turned off via the preference 'Sort Funcs Menu' in the
    dialog "Config > Preferences > Interface".  Note that Text mode doesn't
    have any 'function parsing' routine, so this menu is disabled for this
    window.
    
    Preferences: Appearance

    Power user tip: Command-Option-K will put up a listpick dialog of the
    content of the '{}' menu.  As this is usually alphabetical you can type
    the starting letters of the index you want to go to.

    
	==============================================================


	  	Developers Notes
    
    In order for the Marks menu to work for your mode, you need to create a
    <mode>::MarkFile procedure that is loaded when your mode is first
    sourced.  (It will _not_ be auto-loaded.)  For some examples, see the
    proc: Tcl::MarkFile or the proc: Pasc::MarkFile -- most modes contain
    mark file procedures that you can also pirate as necessary.
    
    In order for the ParseFuncs {} pop-up menu to work, you need to either
    define a <mode>::ParseFunces procedure, or else define mode preferences
    for 'parseFuncs' and 'funcExpr'.  Again, consult any of the existing
    modes for more examples.  The file "marks.tcl" contains several different
    utilities for sorting, displaying, floating etc all of the permanent
    marks in the current (or any open) window.
}

proc marks.tcl {} {}

# ×××× Search Menu Procs ×××× #

proc gotoFileMark {} {
    
    set namedMarks [getNamedMarks -n]
    if {([set idx [lsearch $namedMarks [getSelect]]] > -1)} {
	set L [lindex $namedMarks $idx]
    } else {
        set L [lindex $namedMarks 0]
    }
    gotoMark [listpick -p "Go To Named Mark :" -L [list $L] $namedMarks]
    return
}

proc gotoFunc {} {
    set l [parseFuncsAlpha]
    if {[set ind [lsearch -exact $l "\(-"]] >= 0} {
	array set pos [lrange $l [expr {$ind + 2}] end]
    } else {
	array set pos $l
    }
    set res [listpick -p "Go to Function :" [lsort [array names pos]]]
    goto $pos($res)
}

proc namedMarkProc {menu item} {
    switch -- $item {
	"sortAlphabetically"    {sortMarksFile}
	"sortByPosition"        {orderMarks}
	default                 {$item}
    }
}

proc findViaFileMarks {args} {
    
    win::parseArgs w dir {pos ""}
    
    if {($pos eq "")} {
        set pos [getPos -w $w]
    }
    set markAbovePos ""
    set markBelowPos ""
    
    foreach n [getNamedMarks -w $w] {
	set posOf_n [lindex $n 3]
	if {[pos::compare -w $w $posOf_n < $pos]} {
	    set markAbovePos [lindex $n 0]
	} elseif {[pos::compare -w $w $posOf_n == $pos]} {
	    continue 
	} else {
	    set markBelowPos [lindex $n 0]
	    break
	}
    }
    if {$dir} {
	if {($markBelowPos ne "")} {
	    gotoMark -w $w $markBelowPos
	    return $markBelowPos
	} else {
	    error "Cancelled -- no more marks below position."
	}
    } else {
	if {($markAbovePos ne "")} {
	    gotoMark -w $w $markAbovePos
	    return $markAbovePos
	} else {
	    error "Cancelled -- no more marks above position."
	}
    }
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Named Mark Procs ×××× #
#       

## 
 # --------------------------------------------------------------------------
 # 
 # "buildMarksMenu" --
 # 
 # Called by the core [marksMenuHook], which defined the menu build proc.
 # 
 # If there are previously named marks present for the active window, the
 # building of the menu includes the "-c" flag, which means that ellipses
 # will still be part of the "itemName" passed to the menu proc.  If there
 # are no current marks, then we don't use "-c" so that we can easily dim
 # some of the irrelevant menu items by adding "\(" in front of them.
 # 
 # (We should probably use
 # 
 #     hook::callAll "namedMarks" "*"
 # 
 # in [marksMenuHook], and allow this package to register the hook itself so
 # that we have more control over the name of the procedure that we use.
 # This would also allow use to create a "post-eval" menu building procedure
 # for better dimming of the inappropriate menu items.)
 # 
 # --------------------------------------------------------------------------
 ##

proc buildMarksMenu {} {
    
    set menuList [list "Mark Window" "Set MarkÉ" \
      "Sort MarksÉ" "Remove MarkÉ" "Clear Marks" "Float Marks" "(-)" ]
    set menuProc {marksMenuProc -m}
    if {![set marksLen [llength [set namedMarks [getNamedMarks -n]]]]} {
	set pattern {^(Sort|Remove|Clear|Float)}
	for {set i 0} {($i < [llength $menuList])} {incr i} {
	    if {[regexp -- $pattern [set menuItem [lindex $menuList $i]]]} {
		set menuList [lreplace $menuList $i $i "\(${menuItem}"]
	    } 
	}
	set menuList [lrange $menuList 0 end-1]
    } else {
        if {$marksLen > 100} {
	    lappend menuList "Go To Named MarkÉ" "(-)"
	}
	eval [list lappend menuList] $namedMarks
	append menuProc { -c}
    }
    return [list "build" $menuList $menuProc]
}

proc markTrim  {markName {limit 31}} {
    if {[string length $markName] > $limit} {
        set markName "[string range $markName 0 [expr {$limit - 1}]]É"
    }
    return $markName
}

## 
 # --------------------------------------------------------------------------
 # 
 # "marksMenuProc" --
 # 
 # Called by the window's sidebar "Marks" menu when the user has selected one
 # of the menu item names.  If the item is one of our Marking Utilities, we
 # perform that action, else we assume that the name of the menu item was a
 # previously set mark that we should jump to.  The core command [gotoMark]
 # includes information about the proper position that should be displayed at
 # the top of the window.
 # 
 # --------------------------------------------------------------------------
 ##

proc marksMenuProc {menuName itemName} {
    
    switch -- [string trim $itemName "É"] {
	"Mark Window" {
	    markFile
	}
	"Set Mark" {
	    setNamedMark
	}
	"Sort Marks" {
	    set q "How do you want to sort the named marks?"
	    set y "Alphabetically"
	    set n "By Position"
	    if {[dialog::yesno -y $y -n $n -c $q]} {
	        sortMarksFile
	    } else {
	        orderMarks
	    }
	}
	"Remove Mark" {
	    removeNamedMark -w [win::Current]
	}
	"Clear Marks" {
	    clearFileMarks
	}
	"Float Marks" {
	    floatNamedMarks
	}
	"Go To Named Mark" {
	    gotoFileMark
	}
	default {
	    if {[catch {gotoMark $itemName}]} {
	        status::msg "Could not find the mark \"${itemName}\""
	    }
	}
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "markFile" --
 # 
 #  This function must not throw an error.  If it does so, that is a bug
 #  which needs fixing.
 # -------------------------------------------------------------------------
 ##
proc markFile {args} {
    win::parseArgs win args
    set refloat [unfloatNamedMarks -w $win]
    if {[llength [getNamedMarks -w $win -n]]} {
	removeAllMarks -w $win
    }
    
    watchCursor
    if {[catch [concat [list hook::callProcForWin MarkFile $win] $args] err]} {
	error::occurred "Marking of the window failed. Please report this\
	  bug, and the mode \"[win::getMode $win 1]\" (err: $err)"
    }
    
    if {$refloat} {floatNamedMarks -w $win}
}

proc ::MarkFile {args} {
    win::parseArgs win
    set m [win::getInfo $win mode]
    status::msg "\"$m\" mode does not support file marking."
}

proc displayNamedMarks {} {
    
    global mode
    
    # Return all mark names in a new window.
    set    result "\rCurrent named marks for \"[win::CurrentTail]\" :\r\r"
    append result [join [getNamedMarks -n] \r]
    new -n "* [win::CurrentTail] Marks *" -m $mode -info $result
    shrinkWindow 1
}

proc floatNamedMarks {args} {
    win::parseArgs win

    global windowMarks windowMarksMenu defTop defWidth

    if {![llength [getNamedMarks -w $win]]} {
	set msg "No marks found in \"[win::Tail $win]\"."
    }
    if {[info exists msg]} {beep ; status::msg $msg ; return}

    # Create a floating menu with mark names.
    if {[win::IsFile $win]} {
	set windowMarks [list $win]
    } else {
	set windowMarks [list [win::Tail $win]]
    }
    eval [list lappend windowMarks "Re-Mark Window" "-"] [getNamedMarks -w $win -n]
    set  windowMarks [lremove -all -regexp $windowMarks [list {^mark[0-9]+$}]]
    Menu -n "Marks" -p goToWindowMark -c -m [lrange $windowMarks 1 end]
    # Determine the proper width for the floating menu.
    set width 125
    foreach item [lrange $windowMarks 1 end] {
	set newWidth [expr {[string length $item] * 7}]
	if {$newWidth > $width} {set width $newWidth}
    }
    if {$width > 280} {set width 280}
    # Float the menu.
    catch {unfloat $windowMarksMenu}
    set windowMarksMenu \
      [float -m "Marks" -w $width -t $defTop -l [expr {$defWidth + 20}]]
}

proc unfloatNamedMarks {args} {
    win::parseArgs win {refloat 1}

    global windowMarks windowMarksMenu 
    
    # This logic looks peculiar -- are we sure this works?
    set wm  [info exists windowMarks] 
    set wmm [info exists windowMarksMenu] 
    if {!$wm || !$wmm} {
	return 0
    } elseif {!([win::Tail $win] eq [file tail [lindex $windowMarks 0]])} {
	return 0
    } else {
	return [unfloat $windowMarksMenu]
    }
}

## 
 # --------------------------------------------------------------------------
 #       
 # "clearFileMarks" --
 #      
 # Remove all named marks from the active window, and inform the user that
 # this has been completed.  This is the UI procedure called by the sidebar
 # "Marks Menus" -- AlphaTcl code that wants to remove all marks from a
 # specified window should use [removeAllMarks].
 # 
 # --------------------------------------------------------------------------
 ##

proc clearFileMarks {} {
    
    requireOpenWindow
    removeAllMarks
    status::msg "All marks for \"[win::Tail]\" have been removed."
    return
}

## 
 # --------------------------------------------------------------------------
 #       
 # "removeAllMarks" --
 # 
 # Arguments:
 # 
 #   ?-w window? ?pattern?
 #      
 # Remove all named marks matching the glob-style pattern "$pattern" -- if not
 # specified (or if an empty string) all marks will be removed.  The active
 # window is used by default.  Any "Named Marks" floating menu palette
 # specific to the window name will be necessarily "unfloated" -- the return
 # value indicates whether it was there in the first place so that other code
 # can decide if it should be replaced after further window marks operations.
 # 
 # We should check to see if the "fixed in Alpha8" clause below is actually
 # true, in which case that part of the code could be removed.
 # 
 # --------------------------------------------------------------------------
 ##

proc removeAllMarks {args} {
    win::parseArgs win {pat ""}
    
    if {![string length $pat]} {
        set pat "*"
    } 
    if {[catch {foreach mark [getNamedMarks -w $win -n] {
	if {[string match $pat $mark]} {removeNamedMark -w $win -n $mark}}}]
    } {
	# some marks contain curly braces!
	# (This will be fixed in Alpha8)
	foreach mark [quote::Regfind [getNamedMarks -w $win -n]] {
	    if {[string match $pat $mark]} {
		removeNamedMark -w $win -n $mark
	    }
	    if {[string index $mark 0] == "\{"} {
		set mk [string range $mark 1 [expr {[string length $mark] -1}]]
	    }
	    if {[string match $pat $mark]} {
		removeNamedMark -w $win -n $mark
	    }
	}
	
    }
    return [unfloatNamedMarks -w $win]
}

proc sortMarksFile {{ignoreCase 1}} {
    set marks    [getNamedMarks]
    set question "Really sort all marks alphabetically?"
    if {![llength $marks]} {
	status::msg "No marks found in \"[win::CurrentTail]\"."
    } else {
	set refloat [unfloatNamedMarks]
	set w       [win::Current]
	set wCT     [win::CurrentTail]
	foreach mark $marks {
	    removeNamedMark -n [lindex $mark 0] -w $w
	    lappend marks2 $mark
	}
	if {$ignoreCase} {
	    set marks2 [lsort -index 0 -dictionary $marks2]
	} else {
	    set marks2 [lsort -index 0 $marks2]
	}
	foreach mark $marks2 {
	    set name [lindex $mark 0]
	    set disp [lindex $mark 2]
	    set pos  [lindex $mark 3]
	    set end  [lindex $mark 4]
	    setNamedMark $name $disp $pos $end
	}
	if {$refloat} {floatNamedMarks}
	status::msg "All named marks for \"$wCT\" have been sorted alphabetically."
    }
}

proc orderMarks {} {
    set marks    [getNamedMarks]
    set question "Really re-order all marks by position?"
    if {![llength $marks]} {
	status::msg "No marks found in \"[win::CurrentTail]\"."
    } else {
	set refloat [unfloatNamedMarks]
	set w       [win::Current]
	set wCT     [win::CurrentTail]
	foreach mark $marks {
	    removeNamedMark -n [lindex $mark 0] -w $w
	    set name   [lindex $mark 0]
	    set disp   [lindex $mark 2]
	    set pos    [lindex $mark 3]
	    set end    [lindex $mark 4]
	    set mark2  [list $pos $disp $name $end]
	    lappend marks2 $mark2
	}
	# Sort on the first index
	foreach mark [lsort -index 0 -dictionary $marks2] {
	    set name [lindex $mark 2]
	    set disp [lindex $mark 1]
	    set pos  [lindex $mark 0]
	    set end  [lindex $mark 3]
	    setNamedMark $name $disp $pos $end
	}
	if {$refloat} {floatNamedMarks}
	status::msg "All named marks for \"$wCT\" have been sorted by position."
    }
}

proc goToWindowMark {menuName item} {
    
    global windowMarks
    
    if {[llength [winNames -f]] && $item != "Re-Mark Window"} {
	set pB 1 ; placeBookmark
    } else {
	set pB 0
    }
    set w [lindex $windowMarks 0]
    if {[catch {win::OpenQuietly $w}]} {
	set msg "Couldn't find the window \"$w\""
	status::msg "Error: $msg" ; error $msg
    }
    if {[icon -q]} {icon -o} 
    if {$item == "Re-Mark Window"} {markFile ; return}
    if {$pB} {status::msg "Press <Ctrl-.> to return to original position"}
    if {[catch {gotoMark "$item"}]} {
	set msg "couldn't find the mark \"$item\"."
	beep ; status::msg "Sorry, $msg"
    } 
}

proc editMark {fname mname {readonly ""}} {
    # Try to open the window.
    if {[catch {win::OpenQuietly $fname} window]} {
	error "Cancelled -- couldn't find the window '$fname'."
    }
    # First find out if we have any marks at all ...
    if {![llength [set mNames [getNamedMarks -n]]]} {
	catch {hook::callProcForWin MarkFile}
	set mNames [getNamedMarks -n]
    }
    # Now try to find the mark.
    set result 0
    if {[set index [lsearch -exact $mNames $mname]] >= 0} {
	# Found the exact mark name.
	gotoMark [lindex $mNames $index]
	set result 1
    } elseif {[set index [lsearch -regexp $mNames "\\m[quote::Regfind $mname]\\M"]] >= 0} {
	# Found a mark name that seems to resemble what we're looking for.
	gotoMark [lindex $mNames $index]
	set result 1
    } 
    # If we still didn't find anything ...
    if {!$result} {
	if {$::alpha::platform == "tk"} {
	    set pat1 "\\m[quote::Regfind $mname]\\M"
	    set pat2 "\\m[quote::Regfind [string trimright [string trimright $pat1] É]]\\M"
	} else {
	    set pat1 "[quote::Regfind $mname]"
	    set pat2 "[quote::Regfind [string trimright [string trimright $pat1] É]]"
	}
	if {![catch {search -s -f 1 -r 1 -i 0 $pat1 [minPos]} match]} {
	    # Found something in the file at least.
	    goto [lindex $match 0]
	    set result 1
	} elseif {![catch {search -s -f 1 -r 1 -i 0 $pat2 [minPos]} match]} {
	    # Found something in the file at least.
	    # (Mark was probably truncated using 'win::MakeTitle'.)
	    goto [lindex $match 0]
	    set result 1
	}
    } 
    # Finish up.
    if {$readonly == "-r"} {
	winReadOnly
    }
    return $result
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Parse Funcs ×××× #
# 
# Used to create a popup of all funcs in window.  Routine should return
# list containing, consecutively, proc name and start of definition.
# 

proc buildParseMenu {} {
    global currentParseItems
    
    set currentParseItems [parseFuncsAlpha]
    
    set items [list]
    set skip 0
    foreach item $currentParseItems {
	if {!$skip} {
	    lappend items $item
	} 
	set skip [expr {!$skip}]
    }
    
    return [list build $items {parseMenuProc -m -c} {}]
}

proc parseMenuProc {menu item} {
    global currentParseItems
    
    set num [lsearch -exact $currentParseItems $item]
    set pos [lindex $currentParseItems [expr {$num + 1}]]
    
    if {$pos < 0} {
        optClickTB_Pick $item
    } else {
	goto $pos
	insertToTop
     }
}

proc parseFuncsAlpha {} {
    watchCursor
    hook::callProcForWin parseFuncs
}

proc ::parseFuncs {} {
    global sortFuncsMenu funcExpr parseExpr mode
    if {![info exists funcExpr] || ![info exists parseExpr]} {
	# Give an informative error message
	set msg "\"$mode\" mode does not support function parsing."
	status::msg $msg ; beep
	return {}
    }
    set pos [minPos]
    set m {}
    if {$sortFuncsMenu} {
	while {[set res [search -s -f 1 -r 1 -i 0 -n $funcExpr $pos]] != ""} {
	    if {[regexp -- $parseExpr [eval getText $res] dummy word]} {
		lappend m [list $word [lindex $res 0]]
	    }
	    set pos [lindex $res 1]
	}
	set m [eval concat [lsort -dictionary -index 0 $m]]
    } else {
	while {[set res [search -s -f 1 -r 1 -i 0 -n $funcExpr $pos]] != ""} {
	    if {[regexp -- $parseExpr [eval getText $res] dummy word]} {
		lappend m $word [lindex $res 0]
	    }
	    set pos [lindex $res 1]
	}
    }
    return $m
}

