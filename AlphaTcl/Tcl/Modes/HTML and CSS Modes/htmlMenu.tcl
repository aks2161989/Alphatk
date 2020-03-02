## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlMenu.tcl"
 #                                    created: 96-04-29 21.31.40 
 #                                last update: 01/12/2006 {05:05:50 PM} 
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

#===============================================================================
# This file contains the main procs for building and handling the two HTML menus.
#===============================================================================

proc html::Hide {} {
	html::DisableSome on
	html::SetDis
	html::DisableSome off
}

# Disable some HTML elements	
proc html::DisableSome {onoff} {
	global html::DisabledItems htmlMenu
	# if called from CSS mode.
	if {![info exists html::DisabledItems]} {return}
	foreach i ${html::DisabledItems} {
		set it [split $i /]
		set m [lindex $it 0]
		if {[string index $m 0] == "$"} {eval set m $m}
		enableMenuItem $m [lindex $it 1] $onoff
	}
}

proc html::DisableMenuItems {me deprecated extensions {strict ""} {trans ""}} {
	global HTMLmodeVars html::HideDeprecated html::HideExtensions html::HideFrames
	set disabled ""
	if {${html::HideDeprecated} || $HTMLmodeVars(hideDeprecated)} {
		set disabled [concat $extensions $deprecated]
	} elseif {${html::HideExtensions} || $HTMLmodeVars(hideExtensions)} {
		set disabled $extensions
	}
	if {${html::HideDeprecated}} {
		eval lappend disabled $strict
	} elseif {${html::HideFrames}} {
		eval lappend disabled $trans
	}
	foreach i $disabled {
		enableMenuItem $me $i off
	}
}

proc html::UseBigBrother {} {
	global HTMLmodeVars
	set HTMLmodeVars(useBigBrother) [expr {!$HTMLmodeVars(useBigBrother)}]
	if {[catch {nameFromAppl Bbth}]} {
		set HTMLmodeVars(useBigBrother) 0
		enableMenuItem {Check Links} {Use Big Brother} off
	}
	markMenuItem -m {Check Links} {Use Big Brother} $HTMLmodeVars(useBigBrother)
	prefs::modifiedModeVar useBigBrother HTML
	status::msg "[lindex {"Don't use" Use} [set HTMLmodeVars(useBigBrother)]] Big Brother."
}

# Called from HTML menu to change browser.
proc html::ToggleBrowser {brws} {
	global html::Browsers browserSig alpha::platform alpha::macos
	foreach b ${html::Browsers} {
		if {$brws == [lindex $b 1]} {set browserSig [lindex $b 0]}
	}
	prefs::modifiedVar browserSig
	# Work around for absorbed modifier
	if {$alpha::platform == "alpha" && $alpha::macos == 2} {key::optionPressed}
	if {![key::optionPressed]} {
		if {[key::shiftPressed]} {
			html::SendWindow "" 1
		} else {
			html::SendWindow
		}
	}
}

# Called whenever browserSig is changed.
proc html::ToggleBrowser2 {args} {
	global browserSig html::Browsers HTMLmodeVars
	if {![lcontains HTMLmodeVars(browsers) $browserSig]} {html::AddBrowser $browserSig}
	foreach b ${html::Browsers} {
		if {$browserSig == [lindex $b 0]} {
			markMenuItem -m Browsers [lindex $b 1] on
		} else {
			markMenuItem -m Browsers [lindex $b 1] off
		}
	}
}

# Add a browser to Browser menu.
proc html::AddBrowser {{sig ""}} {
	global html::Browsers HTMLmodeVars browserSig
	if {$sig == ""} {
		set fil [getfile "Locate a web browser."]
		set sig [file::getSig $fil]
	}
	if {[catch {nameFromAppl $sig} fil]} {
		alertnote "Couldn't get the name of the browser. If nothing else helps try rebuilding the desktop."
		return
	}
	if {[lcontains HTMLmodeVars(browsers) $sig]} {return}
	lappend HTMLmodeVars(browsers) $sig
	prefs::modifiedModeVar browsers HTML
	set app [file tail $fil]
	regsub {\.app$} $app "" app
	lappend html::Browsers [list $sig $app]
	html::AddBrowserItem $app $sig
	status::msg "$app added to Browsers menu."
}

# Remove a browser from Browser menu.
proc html::RemoveBrowser {} {
	global html::Browsers HTMLmodeVars browserSig
	foreach b ${html::Browsers} {
		lappend tmp [lindex $b 1]
	}
	if {[catch {listpick -p "Select browser to remove" $tmp} brws] || $brws == ""} {return}
	for {set i 0} {$i < [llength ${html::Browsers}]} {incr i} {
		if {$brws == [lindex [lindex ${html::Browsers} $i] 1]} {
			html::AddBrowserItem $brws [lindex [lindex ${html::Browsers} $i] 0] removeFrom
			if {[lindex $HTMLmodeVars(browsers) $i] == $browserSig} {
				set j 0
				if {$i == 0} {incr j}
				if {$j < [llength $HTMLmodeVars(browsers)]} {set browserSig [lindex $HTMLmodeVars(browsers) $j]}
				prefs::modifiedVar browserSig
			}
			set html::Browsers [lreplace ${html::Browsers} $i $i]
			set HTMLmodeVars(browsers) [lreplace $HTMLmodeVars(browsers) $i $i] 
		}
	}
	prefs::modifiedModeVar browsers HTML
	status::msg "$brws removed from Browsers menu."
}

proc html::AddBrowserItem {app sig {proc insert}} {
	switch $sig {
		MOSS {
			if {[string match "*Navigator*" $app]} {
				set ic 85
			} else {
				set ic 86
			}
		}
		MSIE {set ic 87}
		OlG1 {set ic 88}
		dogz {set ic 73}
		iCAB {set ic 89}
		MOZZ {set ic 98}
		OPRA {set ic 97}
		sfri {set ic 1}
		OWEB {set ic 2}
		CHIM {set ic 3}
		default {set ic 78}
	}
	menu::$proc Browsers items end [menu::itemWithIcon $app $ic]
}


proc html::EnableExtend {} {
	enableMenuItem Extend "Remove AdditionsÉ" [html::AdditionsExists]
}

proc html::ActivateHook {args} {
	global html::HideDeprecated html::HideExtensions html::HideFrames html::OptionalClosingTags 
	global html::ElemLayout html::ElemLayoutClosing HTMLmodeVars
	set html::HideExtensions 0
	set html::HideDeprecated 0
	set html::HideFrames 0
	set doc [html::FindDoctype]
	if {$doc == "transitional" || $doc == "xhtml10transitional" || $doc == "frameset" || $doc == "xhtml10frameset"} {
		set html::HideExtensions 1
		if {$doc == "transitional" || $doc == "xhtml10transitional"} {set html::HideFrames 1}
	} elseif {$doc == "strict" || $doc == "xhtml10strict" || $doc == "xhtml11"} {
		set html::HideDeprecated 1
	}
	if {[string match "xhtml*" $doc]} {
		foreach elem $html::OptionalClosingTags {
			set html::ElemLayout($elem) $html::ElemLayoutClosing($elem)
			if {$html::ElemLayout($elem) == "cr2" && [lcontains HTMLmodeVars(indentInXHTML) $elem] && 
			![lcontains HTMLmodeVars(indentElements) $elem]} {
				lappend HTMLmodeVars(indentElements) $elem
				prefs::modifiedModeVar indentElements HTML
			}
		}
	} else {
		foreach elem $html::OptionalClosingTags {
			html::FindOptionalLayout $elem
			# Make sure content is not indented if it shouldn't be.
			if {$html::ElemLayout($elem) != "cr2" && [lcontains HTMLmodeVars(indentElements) $elem]} {
				set HTMLmodeVars(indentElements) [lremove -all $HTMLmodeVars(indentElements) [list $elem]]
				prefs::modifiedModeVar indentElements HTML
			}
		}
	}
	html::Hide
}

proc html::FindDoctype {} {
	global html::xhtml html::xhtmlversion
	set html::xhtml 0
	set html::xhtmlversion 0
	set posL [pos::max]
	# WORKAROUND for bug# 1865.
	set posL [pos::math [pos::min] + 20000]
	if {![catch {search -s -f 1 -r 1 -i 1 -m 0 -l $posL -- {<!doctype[^<>]+html[ \t\r\n]+4.01?[ \t\r\n]+transitional[^<>]+>} [minPos]}]} {
		return transitional
	} elseif {![catch {search -s -f 1 -r 1 -i 1 -m 0 -l $posL -- {<!doctype[^<>]+html[ \t\r\n]+4.01?[ \t\r\n]+frameset[^<>]+>} [minPos]}]} {
		return frameset
	} elseif {![catch {search -s -f 1 -r 1 -i 1 -m 0 -l $posL -- {<!doctype[^<>]+html[ \t\r\n]+4.01?[ \t\r\n]*//[^<>]+>} [minPos]}]} {
		return strict
	} elseif {![catch {search -s -f 1 -r 1 -i 1 -m 0 -l $posL -- {<!doctype[^<>]+xhtml[ \t\r\n]+1.0[ \t\r\n]+transitional[^<>]+>} [minPos]}]} {
		set html::xhtml 1
		set html::xhtmlversion 1.0
		return xhtml10transitional
	} elseif {![catch {search -s -f 1 -r 1 -i 1 -m 0 -l $posL -- {<!doctype[^<>]+xhtml[ \t\r\n]+1.0[ \t\r\n]+frameset[^<>]+>} [minPos]}]} {
		set html::xhtml 1
		set html::xhtmlversion 1.0
		return xhtml10frameset
	} elseif {![catch {search -s -f 1 -r 1 -i 1 -m 0 -l $posL -- {<!doctype[^<>]+xhtml[ \t\r\n]+1.0[ \t\r\n]+strict[^<>]+>} [minPos]}]} {
		set html::xhtml 1
		set html::xhtmlversion 1.0
		return xhtml10strict
	} elseif {![catch {search -s -f 1 -r 1 -i 1 -m 0 -l $posL -- {<!doctype[^<>]+xhtml[ \t\r\n]+1.1[ \t\r\n]*//[^<>]+>} [minPos]}]} {
		set html::xhtml 1
		set html::xhtmlversion 1.1
		return xhtml11
	}
	return ""
}

#===============================================================================
# Menu Processing
#===============================================================================

proc html::MenuItem {menu item} {
	global html::DisabledItems html::ElemAttrOptional
	global screenWidth defWidth
	global global::features mode

	if {($mode == "" || ([mode::exists $mode] && ![mode::isFeatureActive $mode htmlMenu])) && \
	  [info exists global::features] && ![lcontains global::features htmlMenu]} {return}
	
	foreach it ${html::DisabledItems} {
		if {[lindex [split $it /] 1] == $menu || "${menu}/$item" == $it} {beep; return}
	}
	
	switch -glob $menu {
		"¥*" -
		"Html*" {eval html::[join $item ""]} 
		"Browsers" {
			switch $item {
				"Send File to Browser"	{html::SendWindow}
				"Send URL to Browser"	{html::SendWindow "" 1}
				"Add"	{html::AddBrowser}
				"Remove" {html::RemoveBrowser}
				default {html::ToggleBrowser $item}
			}
		}
		"Preferences" {
			switch $item {
				"Attributes Globally" {html::GlobalAttrsPrefs}
				"Use Attributes" {html::UseAttributes}
				"Indentation" {html::IndentationPrefs}
				"Element Layout" {html::ElementLayout}
				"Optional Closing Tags" {html::OptionalClosingTags}
				"Content Types" {html::TypesPrefs contenttypes "Content Types"}
				"Media Descriptors" {html::TypesPrefs mediatypes "Media Descriptors"}
				"Link Types" {html::TypesPrefs linktypes "Link Types"}
				"Home Pages" {html::HomePages}
				"Key Bindings" {html::KeyBindings}
				default {html::modifyFlags [lindex $item 0]}
			}
		}
		"Palettes" {float -m "$item" -t 50 -l [expr {$screenWidth - $defWidth > 110 ? $defWidth : $screenWidth - 110}] -z HTML} 
		"Style Sheets" {
			switch $item {
				Style {html::Tag STYLE}
				Span {html::Tag SPAN}
				default {eval html::[join $item ""]}
			}
		}
		"Headers" {
			switch $item {
				"Header1"	{html::Tag H1}
				"H1 no attr" {html::Tag H1 NOATTR}
				"Header2"	{html::Tag H2}
				"H2 no attr" {html::Tag H2 NOATTR}
				"Header3"	{html::Tag H3}
				"H3 no attr" {html::Tag H3 NOATTR}
				"Header4"	{html::Tag H4}
				"H4 no attr" {html::Tag H4 NOATTR}
				"Header5"	{html::Tag H5}
				"H5 no attr" {html::Tag H5 NOATTR}
				"Header6"	{html::Tag H6}
				"H6 no attr" {html::Tag H6 NOATTR}
				default {eval html::[join $item ""]}
			}
		}
		"Blocks and Dividers" {
			switch $item {
				"Paragraph"	{html::Tag P}
				"P no attr" {html::Tag P NOATTR}
				"Division"		{html::Tag DIV}
				"Block Quote"	{html::Tag BLOCKQUOTE}
				"Address"		{html::Tag ADDRESS}
				"Center"		{html::Tag CENTER}
				"Preformatted"	{html::Tag PRE}
				"Multi Column"	{html::Tag MULTICOL}
				"Spacing"		{html::Tag SPACER}
				"Direction Override" {html::Tag BDO}
				"Inserted Text"	{html::Tag INS}
				"Deleted Text"	{html::Tag DEL}
				"Line Break"		{html::Tag BR}
				"BR no attr"		{html::Tag BR NOATTR}
				"Horizontal Rule"	{html::Tag HR}
				"HR no attr"	{html::Tag HR NOATTR}
				"No Line Break"	{html::Tag NOBR}
				"Word Break"	{html::Tag WBR}
				default {eval html::[join $item ""]}
			}
		}
		"Styles"	{
			switch $item {
				"Font"			{html::Tag FONT}
				"Basefont"		{html::Tag BASEFONT}
				"Marquee"		{html::Tag MARQUEE}
				"Bold"			{html::Tag B}
				"Italic"		{html::Tag I}
				"Strike out"	{html::Tag STRIKE}
				"Underlined"	{html::Tag U}
				"Subscript"		{html::Tag SUB}
				"Superscript"	{html::Tag SUP}
				"Bigger"		{html::Tag BIG}
				"Smaller"		{html::Tag SMALL}
				"Emphasis"		{html::Tag EM}
				"Strong"		{html::Tag STRONG}
				"Definition"	{html::Tag DFN}
				"Code"			{html::Tag CODE}
				"Variable"		{html::Tag VAR}
				"Citation"		{html::Tag CITE}
				"Keyboard"		{html::Tag KBD}
				"Typewriter"	{html::Tag TT}
				"Sample"		{html::Tag SAMP}
				"Blinking"		{html::Tag BLINK}
				"Quotation"		{html::Tag Q}
				"Abbreviation"	{html::Tag ABBR}
				"Acronym"		{html::Tag ACRONYM}
				default {eval html::[join $item ""]}
			}
		}
		"Links"	{
			switch $item {
				"Link or Anchor" {html::Tag A}
				"Image"	{html::Tag IMG}
				Object {html::Tag OBJECT}
				Sound {html::Tag BGSOUND}
				default {eval html::[join $item ""]}
			}
		}
		"Plug-ins" {
			switch $item {
				"General" {html::Tag EMBED}
				"No Embed" {html::Tag NOEMBED}
				default {eval html::[join $item ""]}
			}
		}
		"Lists"	{
			switch $item {
				"Unordered List"	{html::BuildList UL "LI IN UL" UL}
				"UL no attr"	{html::BuildList UL NOATTR NOATTR}
				"Ordered List"	{html::BuildList OL "LI IN OL" OL}
				"OL no attr"	{html::BuildList OL NOATTR NOATTR}
				"Directory"	{html::BuildList DIR LI}
				"Menu"		{html::BuildList MENU LI}
				default {eval html::[join $item ""]}
			}
		}
		"Forms" {
			switch $item {
				"Form"		{html::Tag FORM}
				"Field Set" {html::Tag FIELDSET}
				"Legend"	{html::Tag LEGEND}
				"Label"		{html::Tag LABEL}
				"Text"		{html::Tag "INPUT TYPE=TEXT"}
				"Checkbox"	{html::Tag "INPUT TYPE=CHECKBOX"}
				"Input Button"	{html::Tag "INPUT TYPE=BUTTON"}
				"Radio"		{html::Tag "INPUT TYPE=RADIO"}
				"Submit"		{html::Tag "INPUT TYPE=SUBMIT"}
				"Reset"		{html::Tag "INPUT TYPE=RESET"}
				"Password"	{html::Tag "INPUT TYPE=PASSWORD"}
				"Hidden"		{html::Tag "INPUT TYPE=HIDDEN"}
				"Image"		{html::Tag "INPUT TYPE=IMAGE"}
				"File Upload" {html::Tag "INPUT TYPE=FILE"}
				"Button"	{html::Tag BUTTON}
				"Select"		{html::Tag SELECT}
				"Option Group" {html::Tag OPTGROUP}
				"Option"		{html::Tag OPTION}
				"Textarea"	{html::Tag TEXTAREA}
				"Key Generator" {html::Tag KEYGEN}
				default {eval html::[join $item ""]}
			}
		}
		"Tables" {
			switch $item {
				Table	{html::Tag TABLE}
				Row		{html::Tag TR}
				"TR no attr"		{html::Tag TR NOATTR}
				Header		{html::Tag TH}
				"TH no attr"		{html::Tag TH NOATTR}
				Cell		{html::Tag TD}
				"TD no attr"		{html::Tag TD NOATTR}
				Caption	{html::Tag CAPTION}
				Head {html::Tag THEAD}
				Body {html::Tag TBODY}
				Foot {html::Tag TFOOT}
				"Column Group" {html::Tag COLGROUP}
				Column {html::Tag COL}
				default {eval html::[join $item ""]}
			}
		}
		"Frames" {
			switch $item {
				Frameset		{html::Tag FRAMESET}
				Frame		{html::Tag FRAME}
				"Inline Frame" {html::Tag IFRAME}
				"No Frames"	{html::Tag NOFRAMES}
				default {eval html::[join $item ""]}
			}
		}
		"Image Maps" {
			switch $item {
				Map		{html::Tag MAP}
				Area	{html::Tag AREA}
				default {eval html::[join $item ""]}
			}
		}
		"Java and JavaScript"	{
			switch $item {
				Applet	{html::Tag APPLET}
				Parameter {html::Tag PARAM}
				Script	{html::Tag SCRIPT}
				"No Script" {html::Tag NOSCRIPT}
				Server {html::Tag SERVER}
				default {eval html::[join $item ""]}
			}
		}
		"Layers" {
			switch $item {
				Layer {html::Tag LAYER}
				"Inline Layer" {html::Tag ILAYER}
				"No Layer" {html::Tag NOLAYER}
				default {eval html::[join $item ""]}
			}
		}
		"Ruby" {
			switch $item {
				Ruby {html::Tag RUBY}
				"Base Container" {html::Tag RBC}
				Base {html::Tag RB}
				"Text Container" {html::Tag RTC}
				Text {html::Tag RT}
				Parenthesis {html::Tag RP}
				default {eval html::[join $item ""]}
			}
		}
		"Other"	{
			switch $item {
				"Base"	{html::Tag BASE}
				"Isindex" {html::Tag ISINDEX}
				"Link"	{html::Tag LINK}
				"Meta"	{html::Tag META}
				default {eval html::[join $item ""]}
			}
		}
		"Character Entities"	{
			switch $item {
				"Add"	{html::AddCommonChars}
				"Remove" {html::RemoveCommonChars}
				default		{html::InsertCharacter $item}
			}
		}
		"*Chars*" {
			html::InsertCharacter $item
		}
		"Custom"	{
			set elem [string toupper $item]
			if {[info exists html::ElemAttrOptional($elem)]} {
				html::Tag $elem
			} elseif {[html::AdditionsExists]} {
				html::Tag "INPUT TYPE=$elem"
			}
		}
	}
}

proc html::UtilsMenuItem {menu item} {
	global global::features mode
	if {$menu == "Colors" || $menu == "URLs"} {
		if {($mode == "" || ([mode::exists $mode] && ![mode::isFeatureActive $mode cssMenu] && \
		  ![mode::isFeatureActive $mode htmlUtilsMenu])) && \
		  [info exists global::features] && ![lcontains global::features cssMenu] && \
		  ![lcontains global::features htmlUtilsMenu]} {return}
	} elseif {($mode == "" || ([mode::exists $mode] && ![mode::isFeatureActive $mode htmlUtilsMenu])) && \
	  [info exists global::features] && ![lcontains global::features htmlUtilsMenu]} {return}

	switch -glob $menu {
		"¥*" -
		"Html*" - 
		"Check Links" -
		"Includes" -
		"FTP" -
		"Formatting" -
		"Extend" -
		"Editing" -
		"Validate" {eval html::[join $item ""]}
		"Character Translation"	{
			switch $item {
				"ŒŠš -> HTML"		{html::Characterstohtml 0}
				"HTML -> ŒŠš"	{html::htmltoCharacters 0}
				"<>& -> HTML"	{html::Characterstohtml 1}
				"HTML -> <>&"	{html::htmltoCharacters 1}
				default {eval html::[join $item ""]}
			}
		}
		"Colors" {html::ColorsMenuProc $item}
		"URLs"	{html::URLWinMenuProc $menu $item}
		"Targets"	{html::URLWinMenuProc $menu $item}
		"Add New * To" {html::URLWinMenuProc $menu $item}
		"Home Page Windows" {
			switch $item {
				"Open" {html::OpenHPwin}
				default {eval html::[join $item ""]}
			}
		}
	}
}


#
# The menu.
#
# <B = control <I = option <U = shift <O = command <S = dynamic

proc html::BuildSubMenuProc {me proc} {
	global html::buildingWholeMenu
	if {![info exists html::buildingWholeMenu]} {html::ReadMenuKeys}
	return [list build [html::BuildOneMenu $me] "$proc -m -M HTML" "" $me]
}

proc html::BuildSubCharsMenu {me name flg} {
	global html::OtherChars2Menu html::OtherChars1Menu html::CapitalCharsMenu html::SmallCharsMenu
	return [list build [set $me] "html::MenuItem $flg -m -M HTML" "" $name]
}

proc html::BuildCharsMenu {} {
	global HTMLmodeVars
	set me $HTMLmodeVars(commonChars)
	foreach char $HTMLmodeVars(commonChars) {
		regsub {^!.} $char "" char
		hook::register requireOpenWindowsHook [list -m "Character Entities" $char] 1
	}
	if {[llength $me]} {lappend me "(-"}
	return [list build [concat $me AddÉ RemoveÉ \
	  [list [list Menu -p html::MenuItem -m -M HTML -n "Small Chars" {}]] \
	  [list [list Menu -p html::MenuItem -m -M HTML -c -n "Capital Chars" {}]] \
	  [list [list Menu -p html::MenuItem -m -M HTML -n "Other Chars 1" {}]] \
	  [list [list Menu -p html::MenuItem -m -M HTML -n "Other Chars 2" {}]]] \
	  "html::MenuItem -m -M HTML" [list "Small Chars" "Capital Chars" "Other Chars 1" "Other Chars 2"] "Character Entities"]
}

proc html::BuildCustomMenu {} {
	global html::buildingWholeMenu
	if {![info exists html::buildingWholeMenu]} {html::ReadMenuKeys}
	html::CreateCustomSub
	return [list build [html::BuildOneMenu Custom] "html::MenuItem -m -M HTML" "" Custom]	
}

proc html::BuildMenuProc {} {
	global htmlMenu htmlSubMenus
	return [list build [html::BuildMenu0] "html::MenuItem -m -M HTML" \
	  [concat [lrange $htmlSubMenus 1 end] [list "Character Entities"]] $htmlMenu]
	
}

proc html::BuildUtilsMenuProc {} {
	global htmlUtilsMenu htmlUtilSubMenus
	return [list build [html::BuildUtilsMenu0] "html::UtilsMenuItem -m -M HTML" \
	  [lrange $htmlUtilSubMenus 1 end] $htmlUtilsMenu]
	
}

proc html::BuildMenu0 {} {
	global htmlStartElements html::PrefsFolder htmlCustomSub
	global htmlSubMenus customHTMLpalettes
	
	# Build submenus
	html::ReadMenuKeys	
	status::msg "Building HTML menuÉ"
	set HTMLMenu [html::BuildOneMenu HTML]
	
	lappend htmlMenuList [list Menu -p html::MenuItem -m -M HTML -n Browsers {}]
	append htmlMenuList " " [lindex $HTMLMenu 0]
	lappend htmlMenuList [list Menu -p html::MenuItem -m -M HTML -n Preferences {}]
	# add custom pallettes if any
	if {[info exists customHTMLpalettes]} {
		lappend htmlMenuList [list Menu -p html::MenuItem -m -M HTML -n Palettes $customHTMLpalettes]
	}
	lappend htmlMenuList "(-" [lindex $HTMLMenu 1] [lindex $HTMLMenu 2]
	for {set i $htmlStartElements} {$i < [llength $htmlSubMenus]} {incr i} {
		lappend htmlMenuList [list Menu -p html::MenuItem -m -M HTML -n [lindex $htmlSubMenus $i] {}]
	}
	
	# Allow user to insert custom menu items
	if {[html::NewElementsExists]} {
		lappend htmlMenuList [list Menu -p html::MenuItem -m -M HTML -n "Custom" {}]
	}
	lappend htmlMenuList [list Menu -p html::MenuItem -m -M HTML -n "Character Entities" {}]
		
	return $htmlMenuList
}

proc html::BuildMenuExtra {} {
	global htmlMenuKey htmlMenu
	if {[html::NewElementsExists]} {
		menu::buildSome Custom
	}
	unset -nocomplain htmlMenuKey
	html::DisableMenuItems $htmlMenu {} {Plug-ins Layers}
}

proc html::BlocksDisable {} {
	html::DisableMenuItems "Blocks and Dividers" Center {"Multi Column" Spacing "No Line Break" "Word Break"}
}

proc html::StylesDisable {} {
	html::DisableMenuItems Styles {Font Basefont "Strike out" Underlined} {Marquee Blinking}
}

proc html::LinksDisable {} {
	html::DisableMenuItems Links {} Sound
}

proc html::ListsDisable {} {
	html::DisableMenuItems Lists {Directory Menu} {}
}

proc html::FormsDisable {} {
	html::DisableMenuItems Forms {} {"Key Generator"}
}

proc html::FramesDisable {} {
	html::DisableMenuItems Frames {} {} {Frameset Frame "Inline Frame" "No Frames"} {Frameset Frame}
}

proc html::JavaDisable {} {
	html::DisableMenuItems "Java and JavaScript" Applet Server
}

proc html::OtherDisable {} {
	html::DisableMenuItems Other Isindex {}
}

proc html::MarkBrowsersMenu {} {
	global HTMLmodeVars browserSig html::Browsers
	if {[info exists html::Browsers]} {
		foreach brws ${html::Browsers} {
			if {[lindex $brws 0] == $browserSig} {markMenuItem -m "Browsers" [lindex $brws 1] on}
		}
    }
}

proc html::BuildUtilsMenu0 {} {
	global htmlUtilSubMenus HTMLmodeVars htmlUtilsMenu
	# Build submenus
	html::ReadMenuKeys
	status::msg "Building HTML Utilities menuÉ"
	set UtilitiesMenu [html::BuildOneMenu Utilities]

	foreach me [lrange $htmlUtilSubMenus 1 end] {
		lappend utilSubs [list Menu -p html::UtilsMenuItem -m -M HTML -n $me {}]
	}
	
	return [concat $utilSubs "(-" $UtilitiesMenu]
}

proc html::BuildUtilsMenuExtra {} {
	global htmlMenuKey
	unset -nocomplain htmlMenuKey
}

# Add some things to translation menu.
proc html::CharacterMenuExtra {} {
	addMenuItem -m -l "" "Character Translation" "<>& -> HTML"
	addMenuItem -m -l "" "Character Translation" "HTML -> <>&"
}

# Check if Big Brother exists and if it should be used.
proc html::CheckMenuExtra {} {
	global HTMLmodeVars
	if {[catch {nameFromAppl Bbth}]} {
		enableMenuItem "Check Links" "Use Big Brother" off
		enableMenuItem "Check Links" "Check Remote Links" off
		if {$HTMLmodeVars(useBigBrother)} {
			set HTMLmodeVars(useBigBrother) 0
			prefs::modifiedModeVar useBigBrother HTML
		}
	} elseif {$HTMLmodeVars(useBigBrother)} {
		markMenuItem -m {Check Links} {Use Big Brother} 1
	}
}

proc html::FtpMenuExtra {} {
	if {[catch {nameFromAppl Woof}]} {
		enableMenuItem -m FTP "NetFinder Mirror FilesÉ" off
	}
}

proc html::SetDis {} {
	global HTMLmodeVars html::DisabledItems html::DisabledExtensions html::DisabledDeprecated
	global html::HideDeprecated html::HideExtensions html::HideFrames html::xhtml html::xhtmlversion
	set html::DisabledItems ""
	if {${html::HideDeprecated} || $HTMLmodeVars(hideDeprecated)} {
		set html::DisabledItems ${html::DisabledDeprecated}
		if {!$html::xhtml || $html::xhtmlversion == 1.0} {
			lappend html::DisabledItems {$htmlMenu/Ruby}
		}
	} elseif {${html::HideExtensions} || $HTMLmodeVars(hideExtensions)} {
		set html::DisabledItems ${html::DisabledExtensions}
		if {!$html::xhtml || $html::xhtmlversion == 1.0} {
			lappend html::DisabledItems {$htmlMenu/Ruby}
		}
	}
	if {${html::HideDeprecated}} {
		lappend html::DisabledItems "Frames/Frameset" "Frames/Frame" "Frames/Inline Frame" "Frames/No Frames"
	} elseif {${html::HideFrames}} {
		lappend html::DisabledItems "Frames/Frameset" "Frames/Frame"
	}
	if {$html::xhtml} {
		lappend html::DisabledItems "Preferences/Optional Closing TagsÉ"
	}
}

