## -*-Tcl-*-  (nowrap)
 # ==========================================================================
 # Toolbox Reference Menu - an extension package for Alpha
 #
 # FILE: "toolboxAssistMenu.tcl"
 # 
 #                                          created: 03/02/1995 {01:42:37 PM}
 #                                      last update: 02/23/2005 {02:52:33 PM}
 # Description:
 # 
 # QuickView Toolbox Assistant Help
 # 
 # Author: ??
 # 
 # Distributed under a Tcl style license.
 # 
 # ==========================================================================
 ##

# ×××× Menu declaration ×××× #
alpha::menu toolboxRefMenu 1.1 "C C++" "¥400" {
    # Initialization script.
    toolboxRefMenu
    # Build the menu now.
    menu::buildProc "toolboxRefMenu" {toolboxRef::buildMenu}
    menu::buildSome "toolboxRefMenu"
} {
    # Activation script.
    hook::register requireOpenWindowsHook \
      [list $toolboxRefMenu "insertTrapTemplateÉ"] 1
} {
    # Deactivation script.
    hook::deregister requireOpenWindowsHook \
      [list $toolboxRefMenu "insertTrapTemplateÉ"] 1
} uninstall {
    this-file
} maintainer {
} requirements {
    if {!${alpha::macos}} {
	error "The QuickView application is only available on the Macintosh"
    }
} description {
    Provides access to the QuickView Toolbox Assistant
} help {
    This menu provides access to the QuickView Toolbox Assistant.
    
    The QuickView application (MacClassic) is available here:

    <ftp://ftp.apple.com/developer/Technical_Documentation/Toolbox_Assistant_Updates/QuickView.sit.hqx>

    and here:

    <ftp://ftp.apple.com/developer/Tool_Chest/Core_Mac_OS_Tools/MPW_etc./Documentation/MPW_Reference/QuickView.sit.hqx>
}

## 
 # --------------------------------------------------------------------------
 # 
 # "toolboxRefMenu" --
 # 
 # Dummy proc required by the AlphaTcl SystemCode.
 # 
 # --------------------------------------------------------------------------
 ##

proc toolboxRefMenu {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval toolboxRef" --
 # 
 # Make sure that our variable is defined.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval toolboxRef {
    variable lastTrap
    if {![info exists lastTrap]} {
	set lastTrap ""
    } 
}

## 
 # --------------------------------------------------------------------------
 # 
 # "toolboxRef::buildMenu" --
 # 
 # Build the "toolboxRef" menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc toolboxRef::buildMenu {} {
    
    global toolboxRefMenu
    
    set menuList [list \
      "gotoReference" \
      "(-)" \
      "displayTrapTemplateÉ" \
      "insertTrapTemplateÉ" \
      "/L<O<UlookupTrapÉ" \
      ]
    
    return [list "build" $menuList {toolboxRef::menuProc} {} $toolboxRefMenu]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "toolboxRef::menuProc" --
 # 
 # Called by the "toolboxRef" menu, deal with all menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc toolboxRef::menuProc {menuName itemName} {
    
    variable lastTrap
    
    # No longer a real preference
    set toolboxRefSignature "ALTV"
    
    switch -- $itemName {
        "gotoReference" {
	    if {[catch {app::launchFore $toolboxRefSignature} result]} {
		error "Cancelled -- $result"
	    }
        }
        "displayTrapTemplate" {
	    if {[catch {app::ensureRunning $toolboxRefSignature} result]} {
		error "Cancelled -- $result"
	    }
	    if {[isSelection]} {
		set text [getSelect]
	    } else {
		set text $lastTrap
	    }
	    set lastTrap [prompt "Trap name:" $text]
	    set aeResult [tclAE::send -p -r '$toolboxRefSignature' DanR {TMPL} \
	      "----" [tclAE::build::TEXT $text]]
	    regexp {Ò(.*)Ó} $aeResult -> text
	    if {[regexp {Ò(.+)Ó} $aeResult -> text]} {
		alertnote $text
	    } else {
		error "Cancelled -- no template information available."
	    }
        }
        "insertTrapTemplate" {
	    requireOpenWindow
	    if {[catch {app::ensureRunning $toolboxRefSignature} result]} {
		error "Cancelled -- $result"
	    }
	    if {[isSelection]} {
		set text [getSelect]
	    } else {
		set text $lastTrap
	    }
	    set lastTrap [prompt "Trap name:" $text]
	    set aeResult [tclAE::send -p -r '$toolboxRefSignature' DanR {TMPL} \
	      "----" [tclAE::build::TEXT $text]]
	    regexp {Ò(.*)Ó} $aeResult -> text
	    if {[regexp {Ò(.+)Ó} $aeResult -> text]} {
		typeText $text
	    } else {
		error "Cancelled -- no template information available."
	    }
        }
        "lookupTrap" {
	    if {[catch {app::ensureRunning $toolboxRefSignature} result]} {
		error "Cancelled -- $result"
	    }
	    if {[isSelection]} {
		set text [getSelect]
	    } else {
		set text $lastTrap
	    }
	    set lastTrap [prompt "Trap name:" $text]
	    tclAE::send -p '$toolboxRefSignature' DanR {REF } \
	      "----" [tclAE::build::TEXT $text]
        }
    }
    return
}

# ===========================================================================
# 
# .