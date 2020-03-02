## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  CSS mode - tools for editing CSS documents
 # 
 #  FILE: "cssMode.tcl"
 #                                    created: 97-03-01 17.02.41 
 #                                last update: 01/09/2006 {02:02:11 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 2.2
 # 
 # Copyright 1997-2006 by Johan Linde
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
# This is the main file for CSS mode
#===============================================================================

alpha::mode CSS 2.2b1 cssMode {*.css} {
	cssMenu
} {
	addMenu cssMenu •150
} uninstall {
	if {[askyesno "This will uninstall both HTML and CSS modes. Continue?"] == "no"} {return}
	catch {file delete [file join $HOME Tcl Completions HTMLCompletions.tcl]}
	catch {file delete [file join $HOME Tcl Completions CSSCompletions.tcl]}
	catch {file delete [file join $HOME Help "CSS Help.tcl"]}
	catch {file delete [file join $HOME Help "HTML Help.tcl"]}
	catch {file delete -force [file join $HOME Help "HTML Help"]}
	set folder [procs::find htmlMenu]
	if {$folder != ""} {
		set folder [file dirname $folder]
		if {[file exists $folder]} {catch {file delete -force $folder}}
	}
} maintainer {
	"Johan Linde" <alpha_www_tools@go.to> <http://go.to/alpha_www_tools>
} description {
	Supports the editing of [C]ascading [S]tyle [S]heet files
} help {
	file "HTML Help"
}

proc cssMode {} {}

namespace eval css {}
namespace eval html {}

newPref var lineWrap 0 CSS
newPref v wordBreak {[-@\w]+} CSS
# Color of comments
newPref v commentColor red CSS
# Color of CSS keywords
newPref v keywordColor blue CSS
# Color of HTML elements
newPref v htmlColor magenta CSS
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 CSS
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 CSS
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 CSS

# Coloring
proc css::Coloring {{changing 0}} {
	global CSSmodeVars css::Property css::Descriptor
	if {!$changing} {
		regModeKeywords -b {/*} {*/} -c $CSSmodeVars(commentColor) CSS {}
	}
	regModeKeywords -a -k $CSSmodeVars(htmlColor) CSS [css::GetHtmlWords]
	regsub -all {([a-z])( )} "[concat [array names css::Property] [array names css::Descriptor]] " {\1:\2} words
	regsub -all {(@[a-z]+):} $words {\1} words
	regModeKeywords -a -k $CSSmodeVars(keywordColor) CSS \
	  [concat $words {@font-face important active after before first first-child first-letter 
	first-line focus hover lang left link right visited}]
}

proc css::ChangeColoring {flag} {
	global CSSmodeVars
	switch $flag {
		htmlColor -
		keywordColor {css::Coloring 1}
		commentColor {regModeKeywords -a -c $CSSmodeVars(commentColor) CSS}
	}
	refresh
}

# Load other CSS mode files.
foreach __tmp {cssProperties htmlcssInit htmlMenuDefinition html40} {
	if {[catch {${__tmp}.tcl}]} {
		beep
		alertnote "Loading of ${__tmp}.tcl failed"
		return
	}
}

foreach __vvv [array names CSSmodeVars] {
	set CSSmodeVarsInvisible($__vvv) 1
}

unset __vvv

proc css::DividingLine {} {
	insertText "/*=============================================================================*/\r"
}
Bind 'l' <C> css::DividingLine CSS

proc CSS::parseFuncs {} {
	set pos [minPos]
	set funcExpr {^[ \t]*([^\r\n\{]+)\{}
	while {[set res [search -s -f 1 -r 1 -i 0 -n $funcExpr $pos]] != ""} {
		if {[regexp $funcExpr [eval getText $res] dummy word]} {
			lappend m [list $word [lindex $res 0]]
		}
		set pos [lindex $res 1]
	}
	return [join [lsort -dictionary $m]]
}

proc CSS::DblClick {from to} {
	global css::IsDescriptor
	if {![catch {search -s -f 0 -r 1 -m 0 {[ \t\r\n]+[^ \t\r\n;:]+[ \t\r\n]*:} $from} res] && [pos::compare [lindex $res 1] >= $to]} {
		set css::IsDescriptor [css::IsInAtRule font-face]
		css::Dialog [string tolower [string trim [eval getText $res] " \t\r\n:"]]
	} else {
		HTML::DblClick $from $to
	}
}

proc CSSmodifyFlags {} {
	css::modifyFlags
}

#===============================================================================
# Preferences
#===============================================================================

proc css::modifyFlags {} {
	global CSSmodeVars HTMLmodeVars alpha::colors
	set box "[dialog::title {CSS mode Preferences} 465] \
	  -c {Create missing file without asking when cmd-double-clicking a link} $HTMLmodeVars(createWithoutAsking) 10 15 460 30 \
	  -c {Cmd-double-clicking on non-text file link opens file} $HTMLmodeVars(openNonTextFile) 10 35 450 50 \
	  -c {Use lowercase for HTML element names} $CSSmodeVars(useLowerCase) 10 55 450 70 \
	  -c {Electric Braces} $CSSmodeVars(electricBraces) 10 75 450 90 \
	  -c {Electric Semicolon} $CSSmodeVars(electricSemicolon) 10 95 450 110 \
	  -c {Indent On Return} $CSSmodeVars(indentOnReturn) 10 115 450 130 \
	  -t {Color of keywords:} 10 140 150 155 \
	  -m [list [concat $CSSmodeVars(keywordColor) ${alpha::colors}]] 160 140 310 160 \
	  -t {Color of comments:} 10 165 150 180 \
	  -m [list [concat $CSSmodeVars(commentColor) ${alpha::colors}]] 160 165 310 185 \
	  -t {Color of HTML:} 10 190 150 205 \
	  -m [list [concat $CSSmodeVars(htmlColor) ${alpha::colors}]] 160 190 310 210 \
	  -t wordBreak: 10 220 150 235 \
	  -e [list $CSSmodeVars(wordBreak)] 155 220 450 235"
	set values [eval [concat dialog -w 465 -h 280 -b OK 385 250 450 270 \
	  -b Cancel 300 250 365 270 $box]]
	if {[lindex $values 1]} {return}
	set allFlags {createWithoutAsking openNonTextFile useLowerCase electricBraces electricSemicolon \
	  indentOnReturn keywordColor commentColor htmlColor wordBreak}
	for {set i 0} {$i < [llength $allFlags]} {incr i} {
		set flag [lindex $allFlags $i]
		global $flag
		set m CSS
		if {$i < 2} {set m HTML}
		set val [lindex $values [expr {$i + 2}]]
		if {[set ${m}modeVars($flag)] != $val} {
			if {[string match "word*" $flag] || $flag == "electricBraces" || $flag == "electricSemicolon" || $flag == "indentOnReturn"} {
				set $flag $val
			}
			set ${m}modeVars($flag) $val
			prefs::modifiedModeVar $flag $m
			if {[string match "*Color" $flag]} {css::ChangeColoring $flag}
		}
	}
}

#===============================================================================
# ◊◊◊◊ Initialization ◊◊◊◊ #
#===============================================================================

# Define key bindings from html menu.
proc css::BindingsFromMenu {me tmplist} {
	global htmlMenuKey html${me}Sub
	upvar $tmplist tmp
	foreach it [set html${me}Sub] {
		if {[llength $it] > 2} {
			set elem [lindex $it 2]			
		 	if {[info exists htmlMenuKey(${me}/[lindex $it 1])]} {
				set key $htmlMenuKey(${me}/[lindex $it 1])
			} else {
				set key [lindex $it 0]
			}
			css::BindOneKey $key $elem "" tmp
		}
	}
}

# Define key bindings.
if {[catch {html::ReadCache "CSS keybindings cache"}]} {
	html::ReadMenuKeys
	status::msg "Defining key bindings…"
	foreach __tmp [lrange $htmlSubMenus $htmlStartElements end] {
		css::BindingsFromMenu [lindex $__tmp 0] tmplist
	}
	if {[html::NewElementsExists]} {
		html::CreateCustomSub
		css::BindingsFromMenu Custom tmplist
	}
	html::SaveCache "CSS keybindings cache" $tmplist
	unset tmplist
	unset -nocomplain htmlMenuKey
} else {
	status::msg "Reading key bindings…"
}

css::Coloring
rename css::BindingsFromMenu ""
unset -nocomplain __tmp

set CSS::commentCharacters(General) "*"
set CSS::commentCharacters(Paragraph) [list "/* " " */" " * "]
set CSS::commentCharacters(Box) [list "/*" 2 "*/" 2 "*" 3]

set cssModeIsLoaded 1

status::msg "CSS initialization complete."

