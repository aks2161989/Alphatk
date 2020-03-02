## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 #
 # FILE: "clickUtils.tcl"
 #                                          created: 02/11/1996 {09:17:08 am}
 #                                      last update: 03/21/2006 {01:14:18 PM}
 # Description:
 # 
 # Procedures for various "clicking" routines.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 # 
 # Copyright (c) 1996-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc clickUtils.tcl {} {}

# ×××× Option click in titlebar ×××× #

proc optClickTB_List {} {
    global minItemsInTitlePopup
    set lines [hook::callProcForWin OptionTitlebar]
    if {[llength $lines] < $minItemsInTitlePopup} {
	return [::OptionTitlebar $lines]
    } else {
	return $lines
    }
}

# Doesn't add anything extra for windows which are not saved to disk. 
proc ::OptionTitlebar {{lines ""}} {
    if {[win::IsFile [win::Current]]} {
	set dir [file dirname [win::Current]]
	if {[llength $lines]} {
	    lappend lines "-"
	}
	eval lappend lines [lsort -dictionary \
	  [glob -nocomplain -tails -dir $dir *]]
    }
    return $lines
}

## 
 # -------------------------------------------------------------------------
 #	 
 # "optClickTB_Pick" --
 #	
 #  Called when you select an item from the option-click pop-up.  Call a
 #  mode-specific procedure if possible, else assume it's a file in the
 #  same directory as the current window, and open it.  If the mode
 #  specific procedure ends in an error, we use the default version. 
 # -------------------------------------------------------------------------
 ##
proc optClickTB_Pick {item} {
    if {[catch {hook::callProcForWin OptionTitlebarSelect "" $item}]} {
	::OptionTitlebarSelect $item
    }
}

proc optClickPick {menu item} {
    optClickTB_Pick $item
}

proc ::OptionTitlebarSelect {item} {
    set obviousChoice [file join [file dirname [win::Current]] $item]
    if {[file exists $obviousChoice]} {
	if {$obviousChoice eq [win::Current]} {
	    return
	} elseif {[file isdirectory $obviousChoice]} {
	    if {[lindex [file system $obviousChoice] 0] != "native"} {
		file::browseFor $obviousChoice
	    } else {
		file::showInFinder $obviousChoice
	    }
	} else {
	    file::tryToOpen $item
	}
    } else {
	file::tryToOpen $item
    }
}

proc relatedFilesMenuHook {} {
    menu::buildOne relatedFilesMenu
    return "relatedFilesMenu"
}

proc buildRelatedFilesMenu {} {
    return [list build [optClickTB_List] {optClickPick -m -c} {}]
}

menu::buildProc relatedFilesMenu buildRelatedFilesMenu

# ×××× Command click on window title ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 # "titlebarPathHook" --
 # 
 #  Called when user clicks the title in a window.  
 #  Available in Alpha 8.0b5 and AlphaX 8.0a7.  (in Alphatk this is 
 #  triggered by Command/Alt-right-clicking in the window)
 #  
 #  procs registered to titlebarPathHook receive the window path and should
 #  return the name of a built path menu or throw an error.  If hook builds
 #  a menu, it is responsible for supplying a menu proc to handle menu
 #  selections.  The arguments to this menu proc are slightly different
 #  from the standard; see comment for [titlebarSelectProc].
 # 
 # Results:
 # 
 #  Name of a titlebar path menu to display.
 # 
 # Side effects:
 #  
 #  titlebar path menu is built.
 # -------------------------------------------------------------------------
 ##
proc titlebarPathHook {} {
    set win [win::Current]
    
    # If a hooked procedure can handle this, let it.
    set cmd [list hook::callForWin titlebarPathHook "untilok" $win $win]
    if {![catch $cmd res]} {
	return $res
    } else {
	menu::buildOne titleBarPathMenu
	return "titleBarPathMenu"
    }
}

menu::buildProc titleBarPathMenu buildPathMenu

proc buildPathMenu {} {
    global alpha::macos
    
    if {[win::IsFile [set window [win::Current]]]} {
	set pathList [lreverse [file split $window]]
	
	if {$alpha::macos == 1} {
	    # As a cosmetic issue, we don't want the volume to display the
	    # terminal ':' on Classic Mac OS.
	    
	    set volume [lindex $pathList end]
	    set volume [string trimright $volume [file separator]]
	    set pathList [lreplace $pathList end end $volume]
	} 
    } else {
	set pathList [list $window]
    }
    
    return [list build $pathList {titlebarSelectProc -m -c} {}]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "titlebarSelectProc" --
 # 
 #  Default titlebar path menu handler. Arguments differ form standard menu
 #  handlers:
 # 
 # Argument     Description
 # ------------ ---------------------------------------------
 #  menu        name of menu selected from
 #  pathList	list of every element in the menu from the bottom to the 
 #              item selected, inclusive.
 # 
 # Results:
 #  None.
 # 
 # Side effects: 
 # 
 #  If first item is selected, full path is copied to the Clipboard.  If
 #  other items are selected and <shift> is held down, the appropriate
 #  directory is opened in the Finder.  Else, a file selection dialog is
 #  opened to that directory. 
 #  -------------------------------------------------------------------------
 ##
proc titlebarSelectProc {menu pathList} {
    global alpha::macos
    
    set win [win::Current]
    if {![win::IsFile $win]} {
	putScrap $win
	status::msg "Copied the name of the window to the Clipboard."
	return
    } 

    if {$alpha::macos == 1} {
	# Reattach the ':' to the volume that we removed for cosmetic
	# reasons on Classic Mac OS.
	
	set volume [lindex $pathList 0]
	set volume "${volume}[file separator]"
	set pathList [lreplace $pathList 0 0 $volume]
    } 
    set path [eval file join $pathList]

    # To avoid troubles on Windoze with paths...
    set path [file::ensureStandardPath $path]
    if {$path eq $win} {
	if {[key::shiftPressed]} {
	    win::showInFinder
	} else {
	    putScrap $path
	    status::msg "Copied full path of '[file tail $path]' to the Clipboard."
	}
    } else {
	if {[key::shiftPressed]} {
	    file::showInFinder $path
	} else {
	    file::browseFor $path
	}
    }
}

# ×××× Command Double Click ×××× #

proc cmdDoubleClick {{from -1} {to -1} {shift 0} {option 0} {control 0}} {
    if {![llength [winNames]]} {return}
    if {[expandURL] != ""} {
	sendUrl [getSelect]
    } else {
	if {$from < 0} {
	    set from [getPos]
	    set to [selEnd]
	    if {[pos::compare $from == $to]} {
		hiliteWord
		set from [getPos]
		set to [selEnd]
	    }
	}
	set proc [hook::procForWin DblClick]
	# Mode must have already loaded this proc
	if {$proc ne "" && [llength [info commands $proc]]} {
	    if {[llength [info args $proc]] == 2} {
		$proc $from $to
	    } else {
		$proc $from $to $shift $option $control
	    }
	} else {
	    status::msg "No docs"
	}
    }	
}

proc commandClick {from to url} {
    selectText $from
    for {set i 0} {$i < 200} {incr i} {}
    selectText $from $to
    for {set i 0} {$i < 200} {incr i} {}
    selectText $from
    for {set i 0} {$i < 200} {incr i} {}
    selectText $from $to
    url::execute $url
}	

# ×××× URL handling ×××× #

# (WTP 7/30/95) Slightly improved 'sendUrl'.
# By accepting a text arg, this can now be used to make sendUrl 
# hypertext links (useful for "mailto" links in documentation, f'rinstance) 
#===============================================================================

proc sendUrl {{text {}}} {
    if {$text == {}} { catch {set text [getSelect]} }
    if {$text == {}} { set text [prompt {URL?} {}] }
    if {[string length $text] == 0} { return }
    url::execute $text
}

proc expandURL {} {
    set pos [getPos]
    set beg [lineStart $pos]
    set whe [search -s -n -f 1 -r 1 -i 1 -m 0 -l [nextLineStart $pos] \
      {[a-zA-Z0-9]+://[a-zA-Z/._0-9%~?\&=,-]+} $beg]
    if {[string length $whe]} {
	if {([pos::compare $pos >= [lindex $whe 0]]) \
	  && ([pos::compare $pos < [lindex $whe 1]])} {
	    eval selectText $whe
	    return $whe
	}
    }
}


# ×××× OS X Dock Tile menu ×××× #

# ---------------------------------------------------------------------------
# Since version 8.1a4, it is possible to add items at the top of the
# docktile menu which pops up when clicking on the application's icon in
# the dock without releasing the mouse button. The menu is defined as a Tcl
# list returned by the docktileMenuHook proc. When an item is selected, the
# docktileSelectProc is invoked.
# ---------------------------------------------------------------------------

proc docktileMenuHook {} {
	return [list "Alpha Manual" "Quick Start" "Readme"]
}

proc docktileSelectProc {item} {
	# Do something
	alertnote $item
	if {[file exists [help::pathToHelp $item]]} {
		helpMenu $item
		return
	}
}

