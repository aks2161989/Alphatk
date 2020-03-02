## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  CSS mode - tools for editing CSS documents
 # 
 #  FILE: "cssMenu.tcl"
 #                                    created: 98-05-31 16.18.01 
 #                                last update: 2005-02-21 17:50:33 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 2.2
 # 
 # Copyright 1997-2003 by Johan Linde
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
# This file defines the CSS menu.
#===============================================================================

proc cssMenu {} {}

namespace eval css {}
namespace eval html {}

# Load if this is a global menu.
foreach __tmp {cssProperties htmlcssInit htmlMenuDefinition} {
	if { [catch {eval ${__tmp}.tcl}] } {
		beep
		alertnote "Loading of ${__tmp}.tcl failed"
		return
	}
}

set htmlCSSSub {{"" @Charset} {"" @Import} {"" @Media} {"" Text} {"" "Text Shadow"} {"" Tables} {"<O<B/R" "Reload in Browser"}
{"" "Key BindingsÉ"} {"" "PreferencesÉ"}}

set htmlBoxSub {{"" Margin} {"" Padding} {"" Border} {"" "Border Top"} {"" "Border Right"} 
{"" "Border Bottom"} {"" "Border Left"} {"" "Border Width"} {"" "Border Color"} {"" "Border Style"}}

set htmlVisualSub {{"" Display} {"" Positioning} {"" Floats} {"" "Z-index"} {"" "Text Direction"}
{"" "Content Size"} {"" "Vertical Align"} {"" "Visual Effects"}}

set htmlGeneratedSub {{"" Content} {"" Quotes} {"" Counters} {"" "Marker Offset"} {"" "List Style"}}

set htmlPagedSub {{"" @Page} {"" Size} {"" Marks} {"" "Page Breaks"} {"" Page}}

set htmlColorSub {{"" Color} {"" Background}}

set htmlFontsSub {{"" Font} {"" "Other Properties"} "(-" {"" "@Font Face"} {"" "Font Selection"} 
{"" Matching} {"" Synthesis} {"" Alignment} {"" "Other Descriptors"}}

set htmlUserSub {{"" Cursor} {"" Outline}}

set htmlAuralSub {{"" Volume} {"" Pause} {"" Cue} {"" "Play During"} {"" Spatial} {"" Voice} {"" Speech}}

set cssSubMenus [list CSS {Box Model} {Visual Formatting} {Generated Content} {Paged Media} \
  {Color and Background} Fonts {User Interface} Aural Colors URLs]

foreach __tmp [lrange $cssSubMenus 1 end] {
	menu::buildProc $__tmp "css::BuildSubMenuProc [list $__tmp] css::MenuItem"
}
unset -nocomplain __tmp

hook::register requireOpenWindowsHook [list -m $cssMenu @Charset] 1
hook::register requireOpenWindowsHook [list -m $cssMenu @Import] 1
hook::register requireOpenWindowsHook [list -m $cssMenu @Media] 1
hook::register requireOpenWindowsHook [list -m $cssMenu "Box Model"] 1
hook::register requireOpenWindowsHook [list -m $cssMenu "Visual Formatting"] 1
hook::register requireOpenWindowsHook [list -m $cssMenu "Generated Content"] 1
hook::register requireOpenWindowsHook [list -m $cssMenu "Paged Media"] 1
hook::register requireOpenWindowsHook [list -m $cssMenu "Color and Background"] 1
hook::register requireOpenWindowsHook [list -m $cssMenu "Fonts"] 1
hook::register requireOpenWindowsHook [list -m $cssMenu "Text"] 1
hook::register requireOpenWindowsHook [list -m $cssMenu "Text Shadow"] 1
hook::register requireOpenWindowsHook [list -m $cssMenu "Tables"] 1
hook::register requireOpenWindowsHook [list -m $cssMenu "User Interface"] 1
hook::register requireOpenWindowsHook [list -m $cssMenu "Aural"] 1

proc css::BuildSubMenuProc {me proc} {
	global html::buildingWholeMenu
	if {![info exists html::buildingWholeMenu]} {html::ReadMenuKeys}
	return [list build [html::BuildOneMenu $me] "$proc -m" "" $me]
}

proc css::BuildMenuProc {} {
	global cssMenu cssSubMenus
	return [list build [css::BuildMenu0] "css::MenuItem -m" \
	  [lrange $cssSubMenus 1 end] $cssMenu]
}

proc css::BuildMenu0 {} {
	global cssSubMenus
	
	# Build submenus
	html::ReadMenuKeys	
	status::msg "Building CSS menuÉ"
	set CSSMenu [html::BuildOneMenu CSS]
	
	set me [lrange $CSSMenu 0 2]
	for {set i 1} {$i < 7} {incr i} {
		lappend me [list Menu -p css::MenuItem -m -n [lindex $cssSubMenus $i] {}]
	}
	append me " " [lrange $CSSMenu 3 5]
	for {set i 7} {$i < 9} {incr i} {
		lappend me [list Menu -p css::MenuItem -m -n [lindex $cssSubMenus $i] {}]
	}
	lappend me "(-"
	lappend me [list Menu -p css::MenuItem -m -n [lindex $cssSubMenus 9] {}]
	lappend me [list Menu -p css::MenuItem -m -n [lindex $cssSubMenus 10] {}]
	append me " " [lrange $CSSMenu 6 end]
	return $me
}

proc css::BuildMenuExtra {} {
	global htmlMenuKey
	unset -nocomplain htmlMenuKey
}

menu::buildProc cssMenu css::BuildMenuProc
hook::register menuBuild css::BuildMenuExtra cssMenu
html::BuildWholeMenu cssMenu

proc css::MenuItem {menu item} {
	global css::IsDescriptor global::features mode
	if {$menu == "Colors" || $menu == "URLs"} {
		if {($mode == "" || ([mode::exists $mode] && ![mode::isFeatureActive $mode cssMenu] && \
		  ![mode::isFeatureActive $mode htmlUtilsMenu])) && \
		  [info exists global::features] && ![lcontains global::features cssMenu] && \
		  ![lcontains global::features htmlUtilsMenu]} {return}
	} elseif {($mode == "" || ([mode::exists $mode] && ![mode::isFeatureActive $mode cssMenu])) && \
	  [info exists global::features] && ![lcontains global::features cssMenu]} {return}
	if {$mode == "HTML" && ($item == "@Charset" || $item == "@Import")} {return}
	if {$mode != "CSS" && $item == "Preferences"} {return}
	set css::IsDescriptor 0
	switch $menu {
		"Colors" {html::ColorsMenuProc $item}
		"URLs"	{html::URLWinMenuProc $menu $item}
		"Add New * To" {html::URLWinMenuProc $menu $item}
		default {
			switch $item {
				"Reload in Browser" {css::ReloadinBrowser}
				"Key Bindings" {css::MenuKeys}
				"Preferences" {css::modifyFlags}
				"@Font Face" {css::FontFace}
				default {
					if {![win::checkIfWinToEdit]} {return}
					if {$menu == "Fonts" && $item != "Font" && $item != "Other Properties"} {
						set css::IsDescriptor 1
					}
					if {${css::IsDescriptor} && ![css::IsInAtRule font-face]} {
						alertnote "Font descriptors are only allowed inside a @font-face at-rule."
						return
					}
					css::Dialog [join [string tolower $item] -]
				}
			}
		}
	}
}

proc css::SetCase {elem} {
	global CSSmodeVars html::xhtml
	if {([info exists html::xhtml] && $html::xhtml) || $CSSmodeVars(useLowerCase)} {
		return [string tolower $elem]
	} else {
		return [string toupper $elem]
	}
}

proc css::HTMLelement {elem} {
	replaceText [getPos] [selEnd] [css::SetCase $elem]
}

proc css::MenuKeys {} {
	global htmlMenuKey cssSubMenus
	html::ReadMenuKeys
	if {![catch {listpick -p "Choose a submenu to change key bindings in" \
	  [lsort $cssSubMenus]} meny] && $meny != ""} {
		catch {html::SetKeysInMenu $meny}
	}
	unset -nocomplain htmlMenuKey
}

proc css::GetHtmlWords {} {
	global html::ElemAttrOptional
	set words [array names html::ElemAttrOptional]
	regsub -all "\{INPUT \[^\}\]+\}" $words "" words
	regsub -all "\{LI \[^\}\]+\}" $words "" words
	lappend words INPUT
}

# Change mode hooks
proc css::ChangeModeFrom {args} {
	css::DisableEnablePrefs off
}
proc css::ChangeMode {args} {
	css::DisableEnablePrefs on
}

hook::register changeModeFrom css::ChangeModeFrom CSS 
hook::register changeMode css::ChangeMode CSS
css::ChangeModeFrom

#===============================================================================
# Reload in Browser
#===============================================================================

proc css::ReloadinBrowser {} {
	global browserSig HTMLmodeVars
	if {![app::isRunning $browserSig]} {beep; status::msg "Browser not running."; return}
	if {$browserSig == "MSIE" || $browserSig == "OPRA"} {
		# returns window ids
		if {[catch {tclAE::build::resultData '$browserSig' WWW! LSTW} winnums]} {beep; status::msg "No browser window."; return}
		# returns window info
		if {[catch {set winurl [lindex [tclAE::build::resultData '$browserSig' WWW! WNFO ---- [lindex $winnums 0]] 0]}] || ![regexp "://" $winurl]} {
			beep; status::msg "Empty browser window."; return
		}
	} elseif {$browserSig != "sfri" && ([catch {tclAE::build::resultData '$browserSig' core getd ---- \
	  [tclAE::build::propertyObject curl [tclAE::build::winByPos 1]]} winurl] || ![regexp "://" $winurl])} {
		beep; status::msg "Empty browser window."; return
	}
	if {[winDirty]} {
		html::SaveBeforeSending [lindex [winNames] 0]
	}
	# reloads window
	if {$browserSig == "sfri"} {
		tclAE::send '$browserSig' core setd ---- [tclAE::build::propertyObject pURL \
		  [tclAE::build::propertyObject docu [tclAE::build::winByPos 1]]] data \
		  [tclAE::build::propertyObject pURL [tclAE::build::propertyObject docu [tclAE::build::winByPos 1]]]
	} else {
		set flgs ""
		if {$browserSig != "MOSS"} {set flgs "FLGS 1"}
		eval tclAE::send -p '$browserSig' WWW! OURL ---- "Ò${winurl}Ó" $flgs
	}
	if {![info exists HTMLmodeVars(browseInForeground)] || $HTMLmodeVars(browseInForeground)} {switchTo '$browserSig'}
}


