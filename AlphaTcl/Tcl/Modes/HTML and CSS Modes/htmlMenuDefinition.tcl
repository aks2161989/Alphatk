## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlMenuDefinition.tcl"
 #                                    created: 99-07-15 20.03.23 
 #                                last update: 2005-02-21 17:51:56 
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
# This file contains the definition of the HTML menus.
# 
# For each submenu a list html<menu>Sub is defined where each item has the following format:
# <default key binding> <menu item> <optionally the element related to the menu item>
# The optional element is used by CSS mode to define key bindings.
#===============================================================================

proc htmlMenuDefinition.tcl {} {}

set htmlHTMLSub {{"<I/t" "Help"} {"<U<O/N" "New Document…"} {"<U<O<I/N" "New with Content…"}}

set htmlBrowsersSub {{"<U<O/S" "Send File to Browser"} {"<U<O/U" "Send URL to Browser"} "(-" {"" "Add…"} {"" "Remove…"}}

set htmlPreferencesSub {{"" "General…"} "(-" {"" "Attributes Globally…"} {"<B/m" "Use Attributes…"} {"" "Indentation…"} 
	{"" "Element Layout…"} {"" "Optional Closing Tags…"} "(-" {"" "Home Pages…"} {"" "Key Bindings…"}
	{"" "Coloring…"} {"" "Checking Links…"} {"" "Word Wrapping…"} "(-"
	{"" "Content Types…"} {"" "Media Descriptors…"} {"" "Link Types…"}}

set htmlStyleSub {{"<B<O<U/S" Style STYLE} {"<B/b" Span SPAN}}
	
set htmlHeadersSub {{"<B<O/1" "Header1/H1 no attr" H1}
		{"<B<O/2" "Header2/H2 no attr" H2}
		{"<B<O/3" "Header3/H3 no attr" H3}
		{"<B<O/4" "Header4/H4 no attr" H4}
		{"<B<O/5" "Header5/H5 no attr" H5}
		{"<B<O/6" "Header6/H6 no attr" H6}}
	
set htmlBlocksSub {{"" "Insert Line Breaks"} {"" "Remove Line Breaks"}
		{"" "Insert Paragraphs"} "(-"
		{"<U/b" "Paragraph/P no attr" P}
		{"<U<O/b" "Division" DIV}
		{"<B<O/Q" "Block Quote" BLOCKQUOTE} {"<B<O/S" "Address" ADDRESS}
		{"<B<O/C" "Center" CENTER} {"<B<O/P" "Preformatted" PRE}
		{"<B<O/X" "Multi Column" MULTICOL}
		{"<B<O/Z" "Spacing" SPACER} {"" "Direction Override" BDO} {"<B<O/u" "Inserted Text" INS}
		{"<B<O/v" "Deleted Text" DEL} "(-"
		{"<O/b" "Line Break/BR no attr" BR}
		{"<B<O/H" "Horizontal Rule/HR no attr" HR}
		{"<B<O/B" "No Line Break" NOBR} {"<B<O/W" "Word Break" WBR}}
	
set htmlStylesSub {{"<B<I/F" Font FONT} {"<B<I/N" Basefont BASEFONT}
		{"<B<I/M" Marquee MARQUEE} "(-" {"<B<I/B" Bold B}
		{"<B<I/I" Italic I} {"<B<I/-" "Strike out" STRIKE} {"<B<I<O/-" Underlined U}
		{"<B<I/." Superscript SUP} {"<B<I/," Subscript SUB} {"<B<I<O/." Bigger BIG}
		{"<B<I<O/," Smaller SMALL} {"<B<I/T" Typewriter TT} {"<B<I/Z" Blinking BLINK}
		"(-" {"<B<I/Q" Quotation Q} {"<B<I/A" Abbreviation ABBR} {"<B<I/Y" Acronym ACRONYM} 
		{"<B<I/E" Emphasis EM} {"<B<I/S" Strong STRONG} {"<B<I/D" Definition DFN}
		{"<B<I/C" Code CODE} {"<B<I/V" Variable VAR}	{"<B<I/X" Citation CITE} 
		{"<B<I/K" Keyboard KBD} {"<B<I/P" Sample SAMP}}
		
set htmlLinksSub {{"<B<O/A" "Link or Anchor" A} {"<B<O/I" Image IMG}
		{"<B<O/T" Object OBJECT} {"" Sound BGSOUND}}
	
if {${alpha::platform} == "alpha"} {
    set htmlPlug-insSub {{"<B<O/E" General EMBED} {"<B<O/N" "No Embed" NOEMBED}}
} else {
    set htmlPlug-insSub {{"<B<O<U/E" General EMBED} {"<B<O/N" "No Embed" NOEMBED}}
}
	
set htmlListsSub {{"" "Make List…"} "(-" {"<B<O/U" "Unordered List/UL no attr" UL}
		{"<B<O/O" "Ordered List/OL no attr" OL}
		{"<B<O/D" "Directory" DIR}
		{"<B<O/M" "Menu" MENU} {"<B<I/L" "List Item" LI} "(-"
		{"<B<U<O/D" "Definition List" DL} {"<B<I<O/L" "Definition Entry"}}
	
set htmlFormsSub {{"<B<U/F" Form FORM} {"<B<U/D" "Field Set" FIELDSET} {"<B<U/L" Legend LEGEND}
		{"<B<U/E" Label LABEL} "(-" {"<B<U/T" Text INPUT}
		{"<B<U/B" Checkbox  INPUT} {"<B<U/N" "Input Button" INPUT}
		{"<B<U/R" Radio INPUT} {"<B<U/S" Submit INPUT}
		{"<B<U/C" Reset INPUT} {"<B<U/P" Password INPUT}
		{"<B<U/H" Hidden INPUT} {"<B<U/I" Image INPUT}
		{"<B<U/U" "File Upload" INPUT}
		"(-" {"<B<U<I/U" Button BUTTON} {"<B<U<I/S" Select SELECT} {"<B<U/G" "Option Group" OPTGROUP}
		{"<B<U/O" Option OPTION} {"<B<U<I/T" Textarea TEXTAREA} {"" "Key Generator" KEYGEN}}
	
set htmlTablesSub {{"" "Table Template…"} {"" "Tabs to Rows…"} {"" "Rows to Tabs"} {"" "Import Table…"} "(-"
		{"<U<O/T" Table TABLE} {"<U<O/R" "Row/TR no attr" TR}
		{"<U<O/H" "Header/TH no attr" TH} {"<U<O/D" "Cell/TD no attr" TD}
		{"<U<O/C" Caption CAPTION} "(-"
		{"<B<U<O/H" Head THEAD} {"<B<U<O/B" Body TBODY} {"<B<U<O/F" Foot TFOOT}
		"(-" {"<B<U<O/G" "Column Group" COLGROUP} {"<B<U<O/C" "Column" COL}}
	
set htmlFramesSub {{"<B<U<I/F" "New Doc. with Frames…"} "(-" {"<B<U<I/O" Frameset FRAMESET}
		{"<B<U<I/R" Frame FRAME} {"" "Inline Frame" IFRAME}
		{"<B<U<I/N" "No Frames" NOFRAMES}}
	
set htmlImageSub {{"" "Convert NCSA Map…"} {"" "Convert CERN Map…"} "(-" {"<B<U/M" Map MAP} 
		{"<B<U/A" Area AREA}}
	
set htmlJavaSub {{"<U<I<O/J" Applet APPLET} {"<U<I<O/P" Parameter PARAM}
		"(-" {"<U<I<O/S" Script SCRIPT} {"<B<U<O/N" "No Script" NOSCRIPT} {"" Server SERVER}}

set htmlRubySub {{"" Ruby RUBY} {"" "Base Container" RBC} {"" Base RB}
		{"" "Text Container" RTC} {"" Text RT} {"" Parenthesis RP}}

set htmlLayersSub {{"" Layer LAYER} {"" "Inline Layer" ILAYER} {"" "No Layer" NOLAYER}}
	
set htmlOtherSub {{"<B<U<I/C" Comment} {"<B<U<I/B" Base BASE}
		{"<B<U<I/I" Isindex ISINDEX}
		{"<B<U<I/L" Link LINK} {"<B<U<I/M" Meta META} {"" "Comment Line"}}

# Variables defining the HTML Utilities menu
		
set htmlUtilitiesSub {{"" "Move Files…"} {"" "Rename File…"} {"" "Rename Folder…"} 
	"(-" {"" "Last Modified…"} {"" "Document Type…"} {"" "Document Size"} 
	{"" "Document Index…"}}

set htmlEditingSub {{"<O/B" "Select Container"}
	{"<U<O/B" "Select in Container"} {"<O<I/B" "Select Tag"}
	{"<U/e" "Untag"} {"<U<B/e" "Untag and Select"} {"<U/f" "Remove Opening"}
	{"<U/g" "Edit Tag…"} {"<U/h" "Change Choice"}
	{"<U/i" "Reveal Color"} {"<U/j" "Insert Attributes"} {"" "Quote All Attributes"}
	{"" "Tags to Uppercase"} {"" "Tags to Lowercase"} {"" "Remove Tags"}}

set htmlValidateSub {{"" "Find Unbalanced Tags"} {"" "Check Tags"} {"" "Check Tags and Attributes"}}

set htmlCharacterSub {{"" "åäö -> HTML"} {"" "HTML -> åäö"}}

set htmlColorsSub {{"" "New Color Set…"} {"" "Delete Color Set…"} {"" "Edit Color Set…"} {"" "Rename Color Set…"}}

set htmlURLsSub {{"" "New URL Set…"} {"" "Delete URL Set…"} {"" "Edit URL Set…"} {"" "Rename URL Set…"}
	{"" "Import…"} {"" "Add Folder…"}}

set htmlTargetsSub {{"" "New Target Set…"} {"" "Delete Target Set…"} {"" "Edit Target Set…"} {"" "Rename Target Set…"}}

set htmlCheckSub {{"" "Check Window"} {"" "Check Home Page…"} {"" "Check Folder…"} {"" "Check File…"}
	{"" "Check Remote Links"} "(-" {"" "Use Big Brother"}}

set htmlIncludesSub {{"" "Insert Include Tags…"} "(-" {"" "Update Window"} {"" "Update Home Page…"}
	{"" "Update Folder…"} {"" "Update File…"}}

set htmlHomeSub {{"" Open…} {"<U<O/V" "Paste URL"} {"<U<O<I/V" "Paste Include Tags"} {"" "Refresh Windows"}}

set htmlFTPSub {{"" "Save to FTP Server"} {"" "Forget Passwords"} {"" "Upload Home Page…"} {"" "NetFinder Mirror Files…"}}

set htmlFormattingSub {{"<O/I" "Reformat Paragraph"} {"<O<I/I" "Reformat Document"} {"" "No Formatting"} {"" "C Style Formatting"}}

set htmlExtendSub {{"" "New Element…"} {"" "Edit Element…"} {"" "Remove Additions…"}}


set htmlSubMenus [list HTML Browsers Preferences {Style Sheets} Headers {Blocks and Dividers} \
  Styles Links Plug-ins Lists Forms Tables Frames {Image Maps} {Java and JavaScript} Ruby Layers Other]

set htmlUtilSubMenus [list Utilities Editing Validate {Character Translation} Colors URLs Targets \
  {Check Links} Includes FTP Formatting {Home Page Windows} Extend]


# Index of which menu is the first with HTML elements.
set htmlStartElements 3

foreach __tmp [lrange $htmlSubMenus 1 end] {
	menu::buildProc $__tmp "html::BuildSubMenuProc [list $__tmp] html::MenuItem"
}

foreach __tmp [lrange $htmlUtilSubMenus 1 end] {
	menu::buildProc $__tmp "html::BuildSubMenuProc [list $__tmp] html::UtilsMenuItem"
}
unset -nocomplain __tmp

menu::buildProc "Character Entities" html::BuildCharsMenu
menu::buildProc "Small Chars" {html::BuildSubCharsMenu html::SmallCharsMenu "Small Chars" ""}
menu::buildProc "Capital Chars" {html::BuildSubCharsMenu html::CapitalCharsMenu "Capital Chars" ""}
menu::buildProc "Other Chars 1" {html::BuildSubCharsMenu html::OtherChars1Menu "Other Chars 1" ""}
menu::buildProc "Other Chars 2" {html::BuildSubCharsMenu html::OtherChars2Menu "Other Chars 2" ""}
menu::buildProc htmlMenu html::BuildMenuProc
menu::buildProc htmlUtilsMenu html::BuildUtilsMenuProc
menu::buildProc Custom html::BuildCustomMenu
menu::buildProc "Add New URLs To" {html::BuildAddCacheMenu URLs}
menu::buildProc "Add New Targets To" {html::BuildAddCacheMenu Targets}

hook::register menuBuild html::BlocksDisable "Blocks and Dividers"
hook::register menuBuild html::StylesDisable Styles
hook::register menuBuild html::LinksDisable Links
hook::register menuBuild html::ListsDisable Lists
hook::register menuBuild html::FormsDisable Forms
hook::register menuBuild html::FramesDisable Frames
hook::register menuBuild html::JavaDisable "Java and JavaScript"
hook::register menuBuild html::OtherDisable Other

hook::register menuBuild html::BuildMenuExtra htmlMenu
hook::register menuBuild html::BuildUtilsMenuExtra htmlUtilsMenu
hook::register menuBuild html::MarkBrowsersMenu Browsers
hook::register menuBuild html::CharacterMenuExtra "Character Translation"
hook::register menuBuild html::CheckMenuExtra "Check Links"
hook::register menuBuild html::URLsMenuExtra URLs
hook::register menuBuild {html::AddToCacheMark URLs} "Add New URLs To"
hook::register menuBuild {html::AddToCacheMark Targets} "Add New Targets To"
hook::register menuBuild html::WindowsMenuExtra Targets
hook::register menuBuild html::ColorsMenuExtra Colors
hook::register menuBuild html::FtpMenuExtra FTP
hook::register menuBuild html::EnableExtend Extend

hook::register requireOpenWindowsHook [list -m $htmlMenu "New with Content…"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Style Sheets"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Headers"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Blocks and Dividers"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Styles"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Links"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Plug-ins"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Lists"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Forms"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Tables"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Image Maps"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Java and JavaScript"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Layers"] 1
hook::register requireOpenWindowsHook [list -m $htmlMenu "Other"] 1
hook::register requireOpenWindowsHook [list -m Browsers "Send File to Browser"] 1
hook::register requireOpenWindowsHook [list -m Browsers "Send URL to Browser"] 1
hook::register requireOpenWindowsHook [list -m Frames "Frameset"] 1
hook::register requireOpenWindowsHook [list -m Frames "Frame"] 1
hook::register requireOpenWindowsHook [list -m Frames "Inline Frame"] 1
hook::register requireOpenWindowsHook [list -m Frames "No Frames"] 1
hook::register requireOpenWindowsHook [list -m "Character Entities" "Small Chars"] 1
hook::register requireOpenWindowsHook [list -m "Character Entities" "Capital Chars"] 1
hook::register requireOpenWindowsHook [list -m "Character Entities" "Other Chars 1"] 1
hook::register requireOpenWindowsHook [list -m "Character Entities" "Other Chars 2"] 1
hook::register requireOpenWindowsHook [list -m $htmlUtilsMenu "Editing"] 1
hook::register requireOpenWindowsHook [list -m $htmlUtilsMenu "Validate"] 1
hook::register requireOpenWindowsHook [list -m $htmlUtilsMenu "Character Translation"] 1
hook::register requireOpenWindowsHook [list -m $htmlUtilsMenu "Formatting"] 1
hook::register requireOpenWindowsHook [list -m $htmlUtilsMenu "Last Modified…"] 1
hook::register requireOpenWindowsHook [list -m $htmlUtilsMenu "Document Type…"] 1
hook::register requireOpenWindowsHook [list -m $htmlUtilsMenu "Document Size"] 1
hook::register requireOpenWindowsHook [list -m $htmlUtilsMenu "Document Index…"] 1
hook::register requireOpenWindowsHook [list -m "Check Links" "Check Window"] 1
hook::register requireOpenWindowsHook [list -m "Check Links" "Check Remote Links"] 1
hook::register requireOpenWindowsHook [list -m Includes "Insert Include Tags…"] 1
hook::register requireOpenWindowsHook [list -m Includes "Update Window"] 1
hook::register requireOpenWindowsHook [list -m FTP "Save to FTP Server"] 1
hook::register requireOpenWindowsHook [list -m "Home Page Windows" "Paste URL"] 1
hook::register requireOpenWindowsHook [list -m "Home Page Windows" "Paste Include Tags"] 1
hook::register requireOpenWindowsHook [list -m "Home Page Windows" "Refresh Windows"] 1

set html::DisabledExtensions [list "Blocks and Dividers/Multi Column" \
  "Blocks and Dividers/Spacing" "Blocks and Dividers/No Line Break" "Blocks and Dividers/Word Break" \
  "Styles/Marquee" "Styles/Blinking" "Links/Sound" {$htmlMenu/Plug-ins} \
  "Forms/Key Generator" "Java and JavaScript/Server" {$htmlMenu/Layers}]

set html::DisabledDeprecated ${html::DisabledExtensions}
lappend html::DisabledDeprecated "Java and JavaScript/Applet" "Styles/Font" "Styles/Basefont" \
  "Blocks and Dividers/Center" "Lists/Directory" "Lists/Menu" "Other/Isindex" \
  "Styles/Strike out" "Styles/Underlined"
