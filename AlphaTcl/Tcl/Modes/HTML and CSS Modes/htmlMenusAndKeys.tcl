## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlMenusAndKeys.tcl"
 #                                    created: 00-01-22 15.06.06 
 #                                last update: 2005-02-21 17:51:59 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 3.2
 # 
 # Copyright 1996-2003 by Johan Linde
 #  
 # This program is free software; you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation; either version 2 of the License, or
 # (at your option) any later version.
 # 
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 # 
 # You should have received a copy of the GNU General Public License
 # along with this program; if not, write to the Free Software
 # Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 # 
 # ###################################################################
 ##

#===============================================================================
# This file contains some general procs for building menus and redefining
# key bindings for the menu items.
#===============================================================================

proc html::BuildWholeMenu {me} {
	global html::buildingWholeMenu
	set html::buildingWholeMenu 1
	menu::buildSome $me
	unset html::buildingWholeMenu
}

proc html::CreateCustomSub {} {
	global htmlCustomSub html::PrefsFolder html::Plugins
	set elems [glob -nocomplain -dir [file join ${html::PrefsFolder} "New elements"] *]
	set htmlCustomSub ""
	foreach e [lsort $elems] {
		set e [file tail $e]
		set cssElem $e
		if {[lcontains html::Plugins $e]} {set cssElem EMBED}
		if {[regexp "INPUT TYPE=(.*)" $e "" e]} {set cssElem INPUT}
		lappend htmlCustomSub "{} [string index $e 0][string tolower [string range $e 1 end]] $cssElem"
	}
}

# Returns a list defining a submenu.
proc html::BuildOneMenu {me} {
	global htmlMenuKey
	set me0 [lindex $me 0]
	global html${me0}Sub
	set tmp ""
	foreach it [set html${me0}Sub] {
		if {$it == "(-"} {lappend tmp $it; continue}
		if {[info exists htmlMenuKey(${me0}/[lindex $it 1])]} {
			set key $htmlMenuKey(${me0}/[lindex $it 1])
		} else {
			set key [lindex $it 0]
		}
		set it2 [split [lindex $it 1] /]
		if {[llength $it2] == 1} {
			lappend tmp "$key[lindex $it2 0]"
		} elseif {$key != ""} {
			lappend tmp "<S$key[lindex $it2 0]" "<S<I$key[lindex $it2 1]"
		} else {
			lappend tmp "<S$key[lindex $it2 1]" "<S$key[lindex $it2 0]"
		}
	}
	return $tmp
}

#===============================================================================
# ×××× Custom Key Bindings ×××× #
#===============================================================================

proc html::ReadMenuKeys {} {
	global html::PrefsFolder htmlMenuKey
	unset -nocomplain htmlMenuKey
	if {[file exists [file join ${html::PrefsFolder} "Menu key bindings"]]} {
		catch {uplevel #0 [list source [file join ${html::PrefsFolder} "Menu key bindings"]]}
	}
}

proc html::WriteMenuKeys {} {
	global html::PrefsFolder htmlMenuKey tcl_platform
	if {![info exists htmlMenuKey]} {return}
	status::msg "Saving custom key bindingsÉ"
	foreach m [array names htmlMenuKey] {
		lappend txt "set htmlMenuKey(\[list $m\]) [list $htmlMenuKey($m)]"
	}
	file::ensureDirExists ${html::PrefsFolder}
	if {[info exists txt]} {
		set fid [open [file join ${html::PrefsFolder} "Menu key bindings"] w]
		if {$tcl_platform(platform) != "macintosh"} {
			fconfigure $fid -encoding macRoman
		}
		puts $fid [join $txt \n]
		close $fid
	} elseif {[file exists [file join ${html::PrefsFolder} "Menu key bindings"]]} {
		file delete [file join ${html::PrefsFolder} "Menu key bindings"]
	}
	unset htmlMenuKey
}

proc html::KeyBindings {} {
	global htmlSubMenus htmlUtilSubMenus htmlMenuKey
	html::ReadMenuKeys
	set menus [concat $htmlSubMenus $htmlUtilSubMenus {{Small Chars} {Capital Chars} {Other Chars 1} {Other Chars 2}}]
	if {[html::NewElementsExists]} {lappend menus Custom}
	if {![catch {listpick -p "Choose a submenu to change key bindings in" \
	  [lsort $menus]} meny] && $meny != ""} {
		if {[string match "*Chars*" $meny]} {
			catch {html::SetEntityKeys $meny}
		} else {
			catch {html::SetKeysInMenu $meny}
		}
	}
	unset -nocomplain htmlMenuKey
}


# Redefine key bindings in one submenu.
proc html::SetKeysInMenu {meny} {
	global htmlMenuKey htmlModeIsLoaded cssModeIsLoaded mode
	
	set meny0 [lindex $meny 0]
	global html${meny0}Sub
	set items [set html${meny0}Sub]
	regsub -all {\"\(-\"} $items "" items
	foreach it $items {
		if {[info exists htmlMenuKey(${meny0}/[lindex $it 1])]} {
			set tmpKeys([lindex $it 1]) $htmlMenuKey(${meny0}/[lindex $it 1])
		} else {
			set tmpKeys([lindex $it 1]) [lindex $it 0]
		}
		lappend items2 [list $tmpKeys([lindex $it 1]) [lindex $it 1]]
	}
	if {[eval dialog::adjustBindings [list $meny] newKeys modified 1 $items2] == "Cancel"} {return}

	# Save new key bindings
	foreach it $modified {
		set htmlMenuKey(${meny0}/$it) $newKeys($it)
	}
	if {[llength $modified]} {
		html::DeleteCache "CSS keybindings cache"
		html::WriteMenuKeys
		switch $meny {
			HTML {html::BuildWholeMenu htmlMenu}
			Utilities {html::BuildWholeMenu htmlUtilsMenu}
			CSS {html::BuildWholeMenu cssMenu; css::ChangeMode $mode}
			default {
				menu::buildSome $meny
				# Redefine key bindinds in CSS mode.
				if {[info exists cssModeIsLoaded]} {
					foreach k [array names newKeys] {
						lappend re [list $k $tmpKeys($k) $newKeys($k)]
						css::ReBindKey $meny0 $re
					}
				}
			}
		}
	}
}

proc css::BindOneKey {key elem {un ""} {tmplist ""}} {
	set key1 [keys::toBind $key]
	if {$key1 == ""} {return}
	eval ${un}Bind $key1 [list "css::HTMLelement $elem"] CSS
	if {$tmplist != ""} {
		upvar $tmplist tmp
		append tmp [concat ${un}Bind $key1 [list "css::HTMLelement $elem"] CSS] \n
	}
}

# Redefine key bindings when changed in HTML menu.
proc css::ReBindKey {meny keyItems} {
	global html${meny}Sub
	set items [set html${meny}Sub]
	foreach it $keyItems {
		set it0 [lindex $it 0]
		foreach it1 $items {
			if {[lindex $it1 1] == $it0} {
				set elem [lindex $it1 2]
				break
			}
		}
		# Skip those which aren't html elements
		if {[llength $it1] < 3} {continue}
		css::BindOneKey [lindex $it 1] $elem un
		css::BindOneKey [lindex $it 2] $elem
	}
}

