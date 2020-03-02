## -*-Tcl-*-
 # ###################################################################
 #  AlphaVOODOO - integrates Alpha with VOODOO
 # 
 #  FILE: "voodooMenu.tcl"
 #                                    created: 6/24/97 {9:59:36 AM} 
 #                                last update: 04/28/2004 {07:14:09 PM} 
 #                                    version: 2.0.1
 #  Author: Jonathan Guyer
 #  E-mail: <jguyer@his.com>
 #     www: <http://www.his.com/jguyer/>
 #  
 #  Copyright (C) 1998-2004  Jonathan Guyer
 #  
 #  This program is free software; you can redistribute it and/or modify
 #  it under the terms of the GNU General Public License as published by
 #  the Free Software Foundation; either version 2 of the License, or
 #  (at your option) any later version.
 #  
 #  This program is distributed in the hope that it will be useful,
 #  but WITHOUT ANY WARRANTY; without even the implied warranty of
 #  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 #  GNU General Public License for more details.
 #  
 #  You should have received a copy of the GNU General Public License
 #  along with this program; if not, write to the Free Software
 #  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 #  
 # ###################################################################
 ##

# menu declaration
alpha::menu voodooMenu 2.0.2 "¥500" in_menu {
    if {!${alpha::macos}} {
	error "The 'VooDoo Menu' is only useful on MacOS"
    }

    alpha::package require version 2.0
    
    hook::register quitHook voodoo::disconnect
    
    # <command> <shift> <control>
    set voodoo(menuKeys) "<O<U<B"
    set voodoo(projects) {}
    set voodoo(actual) ""
	    
    trace variable voodoo(projects) w voodoo::enableConnectMenu
    trace variable voodooCurrent w voodoo::enableConnectMenu
    
    trace variable voodooProject w voodoo::synchronize
    trace variable voodooProject(alis) w voodoo::enableMainMenu
    
    voodoo::try voodoo::modernizeProjects

    menu::buildProc voodooMenu voodoo::buildMenu
    
    newPref var voodooCurrent "" "global" voodoo::changeProjectProc \
        voodoo(projects) "varitem"
      
    menu::buildProc "Connect" {
        menu::buildFlagMenu "Connect" list voodooCurrent "" \
        voodoo::projectProc {"ChooseÉ" "Remove From ListÉ" "RenameÉ"} 
    }
    
    menu::buildSome voodooMenu

    # this next call can be very slow
    voodoo::defaultSettings
    set voodoo(projects) [voodoo::projects]
	
    tclAE::installCoercionHandler "enum" "TEXT" voodoo::coerce::enum>TEXT
} requirements {
    if {!${alpha::macos}} {
	error "The 'Voodoo Menu' is only useful on MacOS"
    }
} maintainer {
    {Jonathan Guyer} <jguyer@his.com> <http://www.his.com/jguyer/>
} description {
    Integrates Alpha with the VOODOO (Versions Of Outdated Documents
    Organized Orthogonally) version management package
} help {
    file "VOODOO Help"
} uninstall {
    this-directory
}

proc voodooMenu {} {}

namespace eval voodoo {}

proc voodoo::submenu {name {withDialog 0} {winKeys ""} {allKeys ""} {fileKeys ""}} {
    if {$withDialog} {
	return [list \
	  build \
	  [list \
	  "<E<S${winKeys}windowWithDialogÉ" \
	  "<S<I${winKeys}window" \
	  "<E<S${allKeys}allWindowsWithDialogÉ" \
	  "<S<I${allKeys}allWindows" \
	  "<E<S${fileKeys}filesetWithDialogÉ" \
	  "<S<I${fileKeys}fileset" \
	  ] \
	  voodoo::submenuProc \
	  {} \
	  $name \
	  ]
    } else {		
	return [list \
	  build \
	  [list \
	  "${winKeys}window" \
	  "${allKeys}allWindows" \
	  "${fileKeys}fileset" \
	  ] \
	  voodoo::submenuProc \
	  {} \
	  $name \
	  ]
    }
}

proc voodoo::buildSubmenu {menuInfo} {
    set submenuName [lindex $menuInfo 0]
    menu::buildProc $submenuName [concat "voodoo::submenu" $menuInfo]
    return [list [list Menu -n "$submenuName" {}]]
}

proc voodoo::buildMenu {} {
    global voodooMenu voodoo voodooProject
    
    set submenus [list \
      [list Store 1 "$voodoo(menuKeys)/S"] \
      [list Fetch 1 "$voodoo(menuKeys)/F"] \
      [list {Fetch Read-Only} 1] \
      [list {Locking Status Of} 0 "$voodoo(menuKeys)/L"] \
      [list Add 1 "$voodoo(menuKeys)/A"] \
      ]
    
    set submenuNames "Connect"
    foreach submenu $submenus {
	lappend submenuNames [lindex $submenu 0]
    }
    
    return [list \
      build \
      [concat \
	  [voodoo::buildSubmenu [lindex $submenus 0]] \
	  [voodoo::buildSubmenu [lindex $submenus 1]] \
	  [voodoo::buildSubmenu [lindex $submenus 2]] \
	  {(-)} \
	  "$voodoo(menuKeys)/=Compare" \
	  [voodoo::buildSubmenu [lindex $submenus 3]] \
	  {(-)} \
	  [voodoo::buildSubmenu [lindex $submenus 4]] \
	  {(-)} \
	  {{Menu -n "Connect" {}}} \
	  "SettingsÉ" \
	  "Disconnect" \
	  [list \
	      "<E<S$voodoo(menuKeys)/VAbout AlphaVOODOOÉ" \
	      "<S<I$voodoo(menuKeys)/VSwitch To VOODOO" \
	  ] \
      ] \
      {voodoo::menuProc -m} \
      $submenuNames \
      $voodooMenu \
      ]
}

proc voodoo::enableConnectMenu {array name rwu} {
    global voodooMenu voodooProject voodoo
    
    menu::buildSome "Connect"
    
    set enable [expr {[llength $voodoo(projects)] == 0 ? "off" : "on"}]
    
    enableMenuItem "Connect" "Remove From ListÉ" $enable
    enableMenuItem "Connect" "RenameÉ" $enable
}

proc voodoo::enableMainMenu {array name rwu} {
    global voodooProject voodooMenu
    
    
    if {$voodooProject(alis) != ""} {
	set enable "on"
    } else {
	set enable "off"
    }
    
    foreach menuitem [list Store Fetch {Fetch Read-Only} \
      Compare {Locking Status Of} Add \
      "SettingsÉ" Disconnect] {
	enableMenuItem $voodooMenu $menuitem $enable
    }
}

proc voodoo::synchronize {array name rwu} {
    global voodooProject voodoo
    
    if {$name != "alis" && $voodoo(actual) != ""} {
	upvar \#0 $voodoo(actual) project
	
	set project($name) $voodooProject($name)
    }
}

proc voodoo::projectProc {menu item} {
	switch $item {
	  "Choose" {voodoo::try voodoo::chooseProject}
	  "Remove From List" {voodoo::try voodoo::removeProject}
	  "Rename" {voodoo::try voodoo::renameProject}
	}
}

proc voodoo::changeProjectProc {project} {
    voodoo::try {
	voodoo::changeProject $project
    }
}

proc voodoo::menuProc {menu item} {
    global voodooProject
    
    switch $item {
	"Compare" {
	    if {[info exists voodooProject]} {
		voodoo::try {voodoo::window "voodoo::compare"}
	    }
	}
	"Settings" {voodoo::try voodoo::settings}
	"Disconnect" {voodoo::try voodoo::disconnect}
	"Switch To VOODOO" {app::launchFore Vodo}
	"About AlphaVOODOO" {voodoo::try voodoo::about}
    }
}

proc voodoo::submenuProc {menu item} {
    global voodoo voodooProject
    
    if {![info exists voodooProject]} {
	return
    }
    
    if {[regexp {(.*)WithDialog$} $item blah item]} {
	set voodoo(dialog) 1
    } else {
	set voodoo(dialog) 0
    }
    
    switch $menu {
	"Fetch Read-Only" {
	    voodoo::try [list voodoo::${item} voodoo::fetchReadOnly]
	}
	"add&Store" {
	    voodoo::try [list voodoo::${item} voodoo::add]
	    voodoo::try [list voodoo::${item} voodoo::store]
	}
	"Locking Status Of" {
	    voodoo::try [list voodoo::${item} voodoo::status]
	}
	default {
	    set menu [string tolower $menu]
	    voodoo::try [list voodoo::${item} voodoo::${menu}]
	}
    }
}
