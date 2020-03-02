## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "vcVoodoo.tcl"
 #                                          created: 03/27/2000 {14:57:19 PM}
 #                                      last update: 2005-02-23 23:47:33
 # Author: Jonathan Guyer
 # E-mail: <jguyer@his.com>
 #   mail: Alpha Cabal
 #    www: <http://www.his.com/~jguyer/>
 #  
 # Copyright (c) 2001  Jonathan Guyer.
 # Copyright (c) 2000-2003  Vince Darley.
 # All rights reserved.
 # 
 # Redistributable under standard 'Tcl' license.
 # 
 # No more than a dummy shell right now...
 #
 # ==========================================================================
 ##

# Feature declaration
alpha::library vcVoodoo 0.2 {
    if {$::alpha::macos} {
	namespace eval vcs {
	    variable system
	    set system(Voodoo) Vodo
	}
    }
} uninstall {
    this-file
} maintainer {
    {Jonathan Guyer} <jguyer@his.com> <http://www.his.com/~jguyer/Alpha/>
} description {
    Support for Voodoo personal version control
} help {
    This package provides support for VOODOO (Versions Of Outdated Documents
    Organized Orthogonally) personal version control.
    
    <http://www.unisoftwareplus.com/products/voodooserver/>

    It is only useful if the package: versionControl has been activated --
    consult the help file opened by this hyperlink for more general
    information about using 'version control' in Alpha.
    
    At one point Jon wrote:
    
	No more than a dummy shell right now...

    and you can check the "vcVoodoo.tcl" file to see if you have more to
    contribute to this package.
}

# Note: sig of voodoo is 'VoDo'.

proc vcVoodoo.tcl {} {}

# ×××× -------- ×××× #

namespace eval Vodo {}

proc Vodo::menuProc {menu item} {
    global voodoo voodooProject
    
    if {![info exists voodooProject]} {
	return
    }
    
    if {[regexp {(.*)WithDialog$} $item blah item]} {
	set dialog 1
    } else {
	set dialog 0
    }
    
    switch -- $item {
	"store" -
	"fetch" -
	"fetchReadOnly" -
	"add" -
	"compare" {
	    voodoo::try [list voodoo::window voodoo::${item}]
	}
	"add&Store" {
	    voodoo::try [list voodoo::window voodoo::add]
	    voodoo::try [list voodoo::window voodoo::store]
	}
	"makeWritable" {
	    vcs::makeWritable [win::Current]
	}
	default {
	    vcs::menuProc $menu $item
	}
    }
}

proc Vodo::getState {name} {
    return [vcs::getState $name]
}

proc Vodo::checkCompatibility {name} {
    vcs::ckid::checkCompatibility $name [list "VOODOO"]
}

proc Vodo::otherCommands {state} {
    return ""
}

proc Vodo::lock {name} {
    vcs::lock $name
}

proc Vodo::unlock {name} {
    vcs::unlock $name
}

proc Vodo::store {name} {
    voodoo::submenuProc store window
}

proc Vodo::storeWithDialog {name} {
    voodoo::submenuProc store windowWithDialog
}

proc Vodo::fetch {name} {
    voodoo::submenuProc fetch window
}

proc Vodo::fetchWithDialog {name} {
    voodoo::submenuProc fetch windowWithDialog
}

proc Vodo::add {name} {
    voodoo::submenuProc add window
}

proc Vodo::fetchReadOnly {name} {
    voodoo::submenuProc "Fetch Read-Only" window
}

proc Vodo::fetchReadOnlyWithDialog {name} {
    voodoo::submenuProc "Fetch Read-Only" windowWithDialog
}

proc Vodo::makeWritable {name} {
    vcs::makeWritable $name
}

proc Vodo::compare {name} {
    voodoo::submenuProc compare window
}

proc Vodo::status {name} {
    voodoo::submenuProc status window
}

proc Vodo::getInfo {name} {
    vcs::ckid::getInfo $name
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Vodo::getMenuItems" --
 # 
 #  Returns menu items pertinant to VOODOO
 # -------------------------------------------------------------------------
 ##
proc Vodo::getMenuItems {state} {
    global voodooProject
    
    if {![info exists voodooProject]} {
	voodoo::defaultSettings
    }
    
    if {$voodooProject(lockFiles)} {
        set storeIcon [icon::FromID 491]
    } else {
	set storeIcon [icon::FromID 490]
    }
    # Icon prefix
    set icn "/\x1e"
    
    lappend res "(-"
    
    switch -- $state {
      "no-vcs" { 
	  lappend res "<E<S${icn}add&StoreÉ$storeIcon"                 \
	    "<S${icn}addÉ[icon::FromID 490]"		               \
	    "<E<S(${icn}store$storeIcon"              	               \
	    "<S${icn}storeWithDialogÉ$storeIcon"                       \
      }
      "checked-out" { 
	  lappend res                                                  \
	    "<E<S${icn}store[icon::FromID 490]"                        \
	    "<S${icn}storeWithDialogÉ[icon::FromID 490]"               \
	    "<E<S${icn}fetchReadOnly[icon::FromID 491]"                \
	    "<S${icn}fetchReadOnlyWithDialogÉ[icon::FromID 491]"       \
	    "\(${icn}makeWritable[icon::FromID 492]"                   \
	    "(-)"                                                      \
	    "compare" 				                       \
	    "status"
      }
      "read-only" { 
	  lappend res                                                 \
	    "<E<S${icn}fetch[icon::FromID 490]"                       \
	    "<S${icn}fetchWithDialogÉ[icon::FromID 490]"              \
	    "<E<S${icn}refetchReadOnly[icon::FromID 491]"             \
	    "<S${icn}refetchReadOnlyWithDialogÉ[icon::FromID 491]"    \
	    "${icn}makeWritable[icon::FromID 492]"	              \
	    "(-)"                                                     \
	    "compare"				                      \
	    "status"
      }
      "mro" { 
	  lappend res                                                 \
	    "<E<S${icn}fetch[icon::FromID 490]"             	      \
	    "<S${icn}fetchWithDialogÉ[icon::FromID 490]"              \
	    "<E<S${icn}refetchReadOnly[icon::FromID 491]"             \
	    "<S${icn}refetchReadOnlyWithDialogÉ[icon::FromID 491]"    \
	    "<E<S${icn}store[icon::FromID 490]"                       \
	    "<S${icn}storeWithDialogÉ[icon::FromID 490]"              \
	    "(-)"                                                     \
	    "compare"				                      \
	    "status"
      }
      "" {
	  # no version control registered, or not possible 
	  # to place under version control with current
	  # system
	  set res {}
      }
      default {
	  error "Bad response '$state' received from vcs system"
      }
    }
    
    return $res
}

