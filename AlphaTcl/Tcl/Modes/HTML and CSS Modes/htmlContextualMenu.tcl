## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlContextualMenu.tcl"
 #                                    created: 01-10-27 22.04.47 
 #                                last update: 02/28/2006 {03:37:54 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 3.2
 # 
 # Copyright 1996-2006 by Johan Linde
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

proc htmlContextualMenu.tcl {} {}

namespace eval contextualMenu {}

# Opens a dialog allowing you to edit the attributes of the current tag
newPref f editTag…Item 1 contextualMenuHTML
# Opens the file indicated by the surrounding url
newPref f followLinkItem 1 contextualMenuHTML
# Includes all attributes not included for the current tag, allowing you to
# quickly insert them
newPref f htmlAttributesMenu 1 contextualMenuHTML

hook::register contextualPostBuildHook html::contextualPostBuild HTML
menu::buildProc "htmlAttributes" html::buildTagArgsMenu

proc html::buildTagArgsMenu {args} {
	global alpha::CMArgs
	variable CMattrmenuList
	set pos [lindex $alpha::CMArgs 0]
	set CMattrmenuList [html::GetAttributes $pos elem]
	if {[info exists elem] && [string index $elem 0] != "/"} {
		set CMattrmenuList [concat [list "('${elem}' Attributes:" "-"] $CMattrmenuList]
	} else {
		set CMattrmenuList ""
		status::msg ""
	} 
	return [list build $CMattrmenuList {html::CMTagArgsProc -m}]
}

proc html::CMTagArgsProc {menuName itemName} {
	global alpha::CMArgs
	html::InsertAttributes $itemName [lindex [set alpha::CMArgs] 0]
}

proc html::contextualPostBuild {args} {
	global contextualMenuHTMLmodeVars
	variable CMattrmenuList
	if {$contextualMenuHTMLmodeVars(editTag…Item)} {
		set tagpos [html::GetOpening [set pos [lindex $args 1]] 1]
		if {![llength $tagpos] || [pos::compare $pos < [lindex $tagpos 0]] || [pos::compare $pos > [lindex $tagpos 1]] || 
		[string index [lindex $tagpos 2] 0] == "/"} {
			enableMenuItem [lindex $args 0] editTag… off
		}
	}
	if {$contextualMenuHTMLmodeVars(followLinkItem) && [catch {html::FollowLink [lindex $args 1] 0}]} {
		enableMenuItem [lindex $args 0] followLink off
	}
	if {$contextualMenuHTMLmodeVars(htmlAttributesMenu) && ![llength $CMattrmenuList]} {
		enableMenuItem [lindex $args 0] htmlAttributes off
	}
}

proc contextualMenu::editTag {} {
    global alpha::CMArgs
    goto [lindex [set alpha::CMArgs] 0]
    html::EditTag
}

proc contextualMenu::followLink {} {
    global alpha::CMArgs
    goto [lindex [set alpha::CMArgs] 0]
    catch {html::FollowLink [getPos]}
}
