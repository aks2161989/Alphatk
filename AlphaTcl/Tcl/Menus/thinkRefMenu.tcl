## -*-Tcl-*-  (nowrap)
 # ==========================================================================
 # Think Reference Menu - an extension package for Alpha
 #
 # FILE: "thinkRefMenu.tcl"
 # 
 #                                          created: 03/02/1995 {01:41:15 PM}
 #                                      last update: 02/04/2005 {10:55:51 AM}
 # Description:
 # 
 # Think Reference Help
 # 
 # Author: ??
 # 
 # Distributed under a Tcl style license.
 # 
 # ==========================================================================
 ##

# ×××× Menu declaration ×××× #
alpha::menu thinkRefMenu 1.1 "C C++ Java Pasc" "¥265" {
    # Initialization script.
    thinkRefMenu
    # Build the menu now.
    menu::buildProc "thinkRefMenu" {thinkRef::buildMenu}
    menu::buildSome "thinkRefMenu"
} {
    # Activation script.
    hook::register requireOpenWindowsHook \
      [list $thinkRefMenu "insertTrapTemplateÉ"] 1
} {
    # Deactivation script.
    hook::deregister requireOpenWindowsHook \
      [list $thinkRefMenu "insertTrapTemplateÉ"] 1
} uninstall {
    this-file
} maintainer {
} requirements {
    if {!${alpha::macos}} {
	error "The ThinkRef application is only available on the Macintosh"
    }
} description {
    Provides access to the Think Reference (MacClassic) application
} help {
    This menu provides access to the Think Reference (MacClassic) application.
}

## 
 # --------------------------------------------------------------------------
 # 
 # "thinkRefMenu" --
 # 
 # Dummy proc required by the AlphaTcl SystemCode.
 # 
 # --------------------------------------------------------------------------
 ##

proc thinkRefMenu {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval thinkRef" --
 # 
 # Make sure that our variable is defined.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval thinkRef {
    variable lastTrap
    if {![info exists lastTrap]} {
        set lastTrap ""
    } 
}

## 
 # --------------------------------------------------------------------------
 # 
 # "thinkRef::buildMenu" --
 # 
 # Build the "thinkRef" menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc thinkRef::buildMenu {} {
    
    global thinkRefMenu
    
    set menuList [list \
      "gotoReference" \
      "(-)" \
      "displayTrapTemplateÉ" \
      "insertTrapTemplateÉ" \
      "/L<O<UlookupTrapÉ" \
      ]
    
    return [list "build" $menuList {thinkRef::menuProc} {} $thinkRefMenu]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "thinkRef::menuProc" --
 # 
 # Called by the "thinkRef" menu, deal with all menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc thinkRef::menuProc {menuName itemName} {
    
    variable lastTrap
    
    switch -- $itemName {
        "gotoReference" {
	    if {[catch {app::launchFore DanR} result]} {
		error "Cancelled -- $result"
	    }
        }
        "displayTrapTemplate" {
	    if {[catch {app::launchFore DanR} result]} {
		error "Cancelled -- $result"
	    }
	    if {[isSelection]} {
		set text [getSelect]
	    } else {
		set text $lastTrap
	    }
	    set lastTrap [prompt "Trap name:" $text]
	    set aeResult [tclAE::send -p -r {'DanR'} DanR {TMPL} \
	      "----" [tclAE::build::TEXT $text]]
	    if {[regexp {Ò(.+)Ó} $aeResult -> text]} {
		alertnote $text
	    } else {
	        error "Cancelled -- no template information available."
	    }
	}
        "insertTrapTemplate" {
	    requireOpenWindow
	    if {[catch {app::ensureRunning DanR} result]} {
		error "Cancelled -- $result"
	    }
	    if {[isSelection]} {
		set text [getSelect]
	    } else {
		set text $lastTrap
	    }
	    set lastTrap [prompt "Trap name:" $text]
	    set aeResult [tclAE::send -p -r {'DanR'} DanR {TMPL} \
	      "----" [tclAE::build::TEXT $text]]
	    if {[regexp {Ò(.+)Ó} $aeResult -> text]} {
		typeText $text
	    } else {
		error "Cancelled -- no template information available."
	    }
        }
        "lookupTrap" {
	    if {[catch {app::ensureRunning DanR} result]} {
		error "Cancelled -- $result"
	    }
	    if {[isSelection]} {
		set text [getSelect]
	    } else {
		set text $lastTrap
	    }
	    set lastTrap [prompt "Trap name:" $text]
	    set num 0
	    tclAE::send -p {'DanR'} DanR {REF } \
	      "----" [tclAE::build::TEXT $text]
        }
    }
    return
}

# ===========================================================================
# 
# .