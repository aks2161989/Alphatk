## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlPreferences.tcl"
 #                                    created: 99-07-18 00.29.30 
 #                                last update: 2005-02-21 17:52:03 
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
# This file contains procs for settings preferences in HTML mode.
#===============================================================================

# Dialog to set HTML mode variables.
proc html::modifyFlags {{which General}} {
	global HTMLmodeVars htmlIconTxt htmlIcons htmlMenu htmlUtilsMenu global::features mode
	
	set box [eval html::${which}PrefsBox]
	set allFlags [eval html::${which}Flags]

	set attrTxt {"status bar" "dialog boxes"}
	set manTxt {"first page in manual" "table of contents without frames" "table of contents with frames"}
	set coltxt {"Simple coloring" "Complex coloring"}
	set eh 0
	if {$which == "Coloring"} {set eh 25}
	set values [eval [concat dialog -w 465 -h [expr {315 + $eh}] -b OK 385 [expr {285 + $eh}] 450 [expr {305 + $eh}] \
	  -b Cancel 300 [expr {285 +$eh}] 365 [expr {305 + $eh}] $box]]
	if {[lindex $values 1]} {return}
	if {$which == "General"} {
		set iconidx [llength $allFlags]
		if {[lindex $values [expr $iconidx + 1]] == [lindex $values [expr $iconidx + 2]]} {
			alertnote "You can't use the same menu icon for both menus. Menu icon changes are ignored."
			set allFlags [lrange $allFlags 0 [expr $iconidx - 3]]
		}
	}
	set i 1
	if {$which == "General"} {incr i}
	set haveShownColorAlert 0
	foreach flag $allFlags {
		global $flag
		incr i
		set val [lindex $values $i]
		if {$flag == "useBigWindows" || $flag == "changeInBigWindows"} {set val [lsearch -exact $attrTxt $val]}
		if {$flag == "simpleColoring"} {set val [expr {![lsearch -exact $coltxt $val]}]}
		if {$flag == "dummyflag"} {continue}
		if {[string match "*Icon" $flag]} {set val [lindex $htmlIcons [lsearch $htmlIconTxt $val]]}
		if {$HTMLmodeVars($flag) != $val} {
			if {$which == "Word" || $flag == "electricBraces" || $flag == "electricSemicolon" || $flag == "indentOnReturn"} {
				set $flag $val
			}
			set HTMLmodeVars($flag) $val
			prefs::modifiedModeVar $flag HTML
			if {$flag == "oldStyleCommPara"} {html::SetCommentCharacters}
			if {[string match "*Color*" $flag]} {set haveShownColorAlert [html::ChangeColorizing $flag $haveShownColorAlert]}
			if {[string match "*Icon" $flag]} {
				set themenu [string trim $flag "Icon"]
				catch {removeMenu [set $themenu]}
				set $themenu $val
				menu::buildSome $themenu
				if {[mode::isFeatureActive $mode $themenu] || \
				  [info exists global::features] && [lcontains global::features $themenu]} {insertMenu [set $themenu]}
			}
		}
	}
}

proc html::GeneralPrefsBox {} {
	global HTMLmodeVars htmlIconTxt htmlIcons alpha::colors elecStopMarker
	
	set attrTxt {"status bar" "dialog boxes"}
	set manTxt {"first page in manual" "table of contents without frames" "table of contents with frames"}

	set box "[dialog::title {General HTML mode Preferences} 450] \
	  -m {{Page 1 of preferences} {Page 1 of preferences} {Page 2 of preferences} {Page 3 of preferences}} 100 15 300 35 \
	  -n {Page 1 of preferences} \
	  -c {Bring browser to front when sending a window to it} $HTMLmodeVars(browseInForeground) 10 45 450 60 \
	  -c {Save window without asking when sending it to the browser} $HTMLmodeVars(saveWithoutAsking) 10 65 450 80 \
	  -c {Set tags in lower case} $HTMLmodeVars(useLowerCase) 10 85 450 100 \
	  -c {Add extra space before /> in empty XHTML elements} $HTMLmodeVars(extraSpace) 10 105 450 120 \
	  -c {Use template stops ($elecStopMarker)} $HTMLmodeVars(useTabMarks)  10 125 450 140 \
	  -c {Electric Braces} $HTMLmodeVars(electricBraces)  10 145 450 160 \
	  -c {Electric Semicolon} $HTMLmodeVars(electricSemicolon)  10 165 450 180 \
	  -c {Indent On Return} $HTMLmodeVars(indentOnReturn)  10 185 450 200 \
	  -t {Give attributes in}  10 205 150 220 \
	  -m {[list [lindex $attrTxt $HTMLmodeVars(useBigWindows)]] {dialog boxes} {status bar}} 155 205 450 225 \
	  -t {Change attributes in} 10 230 150 245 \
	  -m {[list [lindex $attrTxt $HTMLmodeVars(changeInBigWindows)]] {dialog boxes} {status bar}} 155 230 450 250 \
	  -c {Beep for first attribute (applies only if you use the status bar)} $HTMLmodeVars(promptNoisily) 10 255 450 270 \
	  -n {Page 2 of preferences} \
	  -c {Use old style Comment Paragraph} $HTMLmodeVars(oldStyleCommPara) 10 45 450 60 \
	  -c {Auto-indent when typing > of a tag} $HTMLmodeVars(electricGreater) 10 65 450 80 \
	  -c {Adjust current line indentation when inserting a template} $HTMLmodeVars(adjustIndentation) 10 85 450 100 \
	  -c {Open attribute dialog after completing an element} $HTMLmodeVars(attrDialogAfterCompleting) 10 105 450 120 \
	  -c {Create missing file without asking when cmd-double-clicking a link} $HTMLmodeVars(createWithoutAsking) 10 125 460 140 \
	  -c {Cmd-double-clicking on non-text file link opens file} $HTMLmodeVars(openNonTextFile) 10 145 450 160 \
	  -c {Return on non-text file in home page window opens file} $HTMLmodeVars(homeOpenNonTextFile) 10 165 450 180 \
	  -c {'Insert include tags' only inserts tags} $HTMLmodeVars(includeOnlyTags) 10 185 450 200 \
	  -c {Preserve line endings when updating includes or moving files} $HTMLmodeVars(preserveLineEndings) 10 205 450 220 \
	  -c {Update META tags with NAME=\"DATE\" attribute when saving} $HTMLmodeVars(updateMetaDate) 10 225 450 240 \
	  -n {Page 3 of preferences} \
	  -t {'Last modified' text:} 10 45 150 60 -e [list $HTMLmodeVars(lastModified)] 160 45 450 60 \
	  -t {HTML menu icon:} 10 70 180 85 \
	  -m [list [concat [list [lindex $htmlIconTxt [lsearch $htmlIcons $HTMLmodeVars(htmlMenuIcon)]]] $htmlIconTxt]] 190 70 450 90 \
	  -t {HTML Utilities menu icon:} 10 95 180 110 \
	  -m [list [concat [list [lindex $htmlIconTxt [lsearch $htmlIcons $HTMLmodeVars(htmlUtilsMenuIcon)]]] $htmlIconTxt]] 190 95 450 115"
	
	return $box
}

proc html::GeneralFlags {} {
	return [list browseInForeground saveWithoutAsking useLowerCase extraSpace useTabMarks \
	  electricBraces electricSemicolon indentOnReturn\
	  useBigWindows changeInBigWindows promptNoisily oldStyleCommPara electricGreater \
	  adjustIndentation attrDialogAfterCompleting createWithoutAsking openNonTextFile \
	  homeOpenNonTextFile includeOnlyTags preserveLineEndings updateMetaDate lastModified htmlMenuIcon htmlUtilsMenuIcon]
}

proc html::ColoringPrefsBox {} {
	global HTMLmodeVars alpha::colors
	set coltxt {"Simple coloring" "Complex coloring"}
	set box "[dialog::title {HTML mode Coloring Preferences} 450] \
	  -m {[concat [list [lindex $coltxt [expr {!$HTMLmodeVars(simpleColoring)}]]] $coltxt]} 100 15 450 35 \
	  -t {Color of HTML tags:} 10 45 150 60 \
	  -m [list [concat $HTMLmodeVars(tagColor) ${alpha::colors}]] 160 45 310 65 \
	  -n {Complex coloring} \
	  -t {Color of attributes:} 10 70 150 85 \
	  -m [list [concat $HTMLmodeVars(attributeColor) ${alpha::colors}]] 160 70 310 90 \
	  -t {Color of strings:} 10 95 150 110 \
	  -m [list [concat $HTMLmodeVars(stringColor) ${alpha::colors}]] 160 95 310 115 \
	  -r {Always color immediately when typing} $HTMLmodeVars(ColorImmediately) 10 120 300 135 \
	  -r {Coloring of best quality} [expr {!$HTMLmodeVars(ColorImmediately)}] 10 140 300 155 \
	  -c {Color JavaScript keywords} $HTMLmodeVars(JavaScriptColoring) 10 165 450 180 \
	  -t {Color of JavaScript keywords:} 10 185 215 200 \
	  -m [list [concat $HTMLmodeVars(JavaScriptColor) ${alpha::colors}]] 220 185 360 205 \
	  -c {Color CSS keywords} $HTMLmodeVars(CSSColoring) 10 215 450 230 \
	  -t {Color of CSS keywords:} 10 235 215 250 \
	  -m [list [concat $HTMLmodeVars(CSSColor) ${alpha::colors}]] 220 235 360 255 \
	  -t {Color of JavaScript and CSS comments:} 10 265 270 280 \
	  -m [list [concat $HTMLmodeVars(JavaCommentColor) ${alpha::colors}]] 275 265 420 285"

	return $box	
}

proc html::ColoringFlags {} {
	return [list simpleColoring tagColor attributeColor stringColor ColorImmediately dummyflag \
	  JavaScriptColoring JavaScriptColor CSSColoring CSSColor JavaCommentColor]
}

proc html::CheckingPrefsBox {} {
	global HTMLmodeVars
	set box "[dialog::title {HTML mode Checking Links Preferences} 450] \
	  -t {These settings apply when you check links with Alpha:} 10 20 450 35 \
	  -c {Check anchors} $HTMLmodeVars(checkAnchors) 10 40 450 55 \
	  -c {Case sensitive checking (slower)} $HTMLmodeVars(caseSensitive) 10 60 450 75 \
	  -t {These settings apply when you check links with Big Brother:} 10 85 450 100 \
	  -c {Bring Big Brother to front when checking links} $HTMLmodeVars(checkInFront) 10 105 450 120 \
	  -c {Use Big Brother's link check options} $HTMLmodeVars(useBBoptions) 10 125 450 140 \
	  -c {Ignore remote links (if you don't use Big Brother's option)} $HTMLmodeVars(ignoreRemote) 30 145 450 160 \
	  -c {Ignore local links (if you don't use Big Brother's option)} $HTMLmodeVars(ignoreLocal) 30 165 450 180"
	return $box
}

proc html::CheckingFlags {} {
	return [list checkAnchors caseSensitive checkInFront useBBoptions ignoreRemote ignoreLocal]
}

proc html::WordPrefsBox {} {
	global HTMLmodeVars
	set box "[dialog::title {HTML mode Word Wrapping Preferences} 450] \
	  -t {Line width:} 10 20 90 35 -e [list $HTMLmodeVars(fillColumn)] 100 20 140 35 \
	  -t characters 145 20 300 35 \
	  -t {The variables below determine which characters build up words, and the word wrapping. Normally\
	  there is no need to change them. Read about them in general manual if you want to change them.} \
	  10 50 450 110 \
	  -t wordBreak: 10 120 150 135 -e [list $HTMLmodeVars(wordBreak)] 155 120 450 135 \
	  -t wrapBreak: 10 145 150 160 -e [list $HTMLmodeVars(wrapBreak)] 155 145 450 160 \
	  -t wrapBreakPreface: 10 170 150 185 -e [list $HTMLmodeVars(wrapBreakPreface)] 155 170 450 185"
}

proc html::WordFlags {} {
	return [list fillColumn wordBreak wrapBreak wrapBreakPreface]
}

proc html::GlobalAttrsPrefs {} {
	global HTMLmodeVars
	set attrs " ID= CLASS= STYLE= TITLE= LANG= DIR= onClick= onDblClick= \
	 onMouseDown= onMouseUp= onMouseOver= onMouseMove= onMouseOut= onKeyPress= onKeyDown= onKeyUp="
	set alwaysask $HTMLmodeVars(alwaysaskforAttributes)
	set dontask $HTMLmodeVars(dontaskforAttributes)
	set hidden $HTMLmodeVars(neveraskforAttributes)
	html::UseAttrsDialog "HTML mode Attributes Preferences" $attrs alwaysask hidden dontask 1
	set HTMLmodeVars(alwaysaskforAttributes) $alwaysask
	set HTMLmodeVars(dontaskforAttributes) $dontask
	set HTMLmodeVars(neveraskforAttributes) $hidden
	prefs::modifiedModeVar alwaysaskforAttributes HTML
	prefs::modifiedModeVar dontaskforAttributes HTML
	prefs::modifiedModeVar neveraskforAttributes HTML
}

# Choose an item from Use Attributes menu.
proc html::UseAttributes {} {
	global html::ElemAttrOptional
	foreach a [array names html::ElemAttrOptional] {
		if {[llength [set html::ElemAttrOptional($a)]]} {lappend htmlPossibleToUse $a}
	}
	regsub " S " $htmlPossibleToUse " " htmlPossibleToUse
	if {![catch {listpick -p "Choose HTML element" [lsort $htmlPossibleToUse]} elem] &&
	$elem != ""} {html::UseAttributes2 $elem}
}

# Customize list of attributes which get asked about
proc html::UseAttributes2 {item} {
	global html::ElemAttrUsed html::ElemAttrHidden html::ElemAttrOverride
	set reqattrs [html::GetRequired $item]
	set optatts [html::GetOptional $item 1]
	set used [html::GetUsed $item $reqattrs $optatts 1]
	set hidden [html::GetHidden $item]
	set override [html::GetOverride $item]
	html::UseAttrsDialog "Attributes for $item" $optatts used hidden
	set html::ElemAttrUsed($item) $used
	set html::ElemAttrHidden($item) $hidden
	set html::ElemAttrOverride($item) $override
	prefs::modifiedArrayElement $item html::ElemAttrUsed
	prefs::modifiedArrayElement $item html::ElemAttrHidden
	prefs::modifiedArrayElement $item html::ElemAttrOverride
}

proc html::UseAttrsDialog {txt optatts us hi {do ""} {isGlobal 0}} {
	global HTMLmodeVars
	upvar $us used $hi hidden
	if {$do != ""} {upvar $do dont}
	if {!$isGlobal} {upvar override over}
	set hideExtensions $HTMLmodeVars(hideExtensions)
	set hideDeprecated $HTMLmodeVars(hideDeprecated)
	set alwaysask $HTMLmodeVars(alwaysaskforAttributes)
	set dontask $HTMLmodeVars(dontaskforAttributes)
	set neverask $HTMLmodeVars(neveraskforAttributes)
	set page 0
	set attrnumber [llength $optatts]
	set options {"Always ask about" "Don't ask about at first" "Never ask about"}
	set len 10
	if {$isGlobal} {
		set options "{Use individual settings} $options"
		set len 8
	}
	foreach a $optatts {
		if {[lcontains used $a]} {
			lappend uh $isGlobal
		} elseif {[lcontains hidden $a]} {
			lappend uh [expr {2 + $isGlobal}]
		} elseif {!$isGlobal || [lcontains dont $a]} {
			lappend uh [expr {1 + $isGlobal}]
		} else {
			lappend uh 0
		}
	}
	set start(0) 0
	set end(0) -1
	while {1} {
		set box "[dialog::title $txt 370]"
		if {!$isGlobal} {append box " -t {Global settings} 370 10 540 25"}
		set h [expr $isGlobal ? 15 : 35]
		if {$isGlobal && !$page} {
			append box " -c {Don't use extensions to HTML 4.01} $hideExtensions 10 $h 370 [expr {$h + 20}]"
			append box " -c {Don't use deprecated elements and attributes} $hideDeprecated 10 [expr {$h + 25}] 370 [expr {$h + 45}]"
			incr h 50
		}
		set n 0
		set g 0
		set g1 ""
		set end($page) [expr {$end($page) == -1 ? $start($page) + $len - 1 : $end($page)}]
		foreach a [lrange $optatts $start($page) $end($page)] {
			set m [lindex $uh [expr {$start($page) + $n}]]
			append box " -t [string trimright $a =] 10 $h 150 [expr {$h + 20}] -m {[lrange $options $m $m] $options} 160 $h 360 [expr {$h + 20}]"
			if {!$isGlobal} {
				if {[lcontains neverask $a]} {append box " -t {Never ask about} 370 $h 540 [expr {$h + 20}]"}
				if {[lcontains dontask $a]} {append box " -t {Don't ask about at first} 370 $h 540 [expr {$h + 20}]"}
				if {[lcontains alwaysask $a]} {append box " -t {Always ask about} 370 $h 540 [expr {$h + 20}]"}
				if {[lcontains alwaysask $a] || [lcontains dontask $a] || [lcontains neverask $a]} {
					incr h 20
					append box " -c {Override global setting} [lcontains over $a] 370 $h 540 [expr {$h + 20}]"
					incr h 5
					incr g
					lappend g1 1
				} else {
					lappend g1 0
				}
			} else {
				lappend g1 0
			}
			incr h 25
			incr n
			if {$h > 300} {
				set end($page) [expr {$start($page) + $n - 1}]
				break
			}
		}
		incr h 10
		set h1 [expr {$h + 20}]
		if {$page > 0} {append box " -b {<< Prev} 20 $h 95 $h1"}
		if {[expr {$start($page) + $len}] < $attrnumber} {append box " -b {Next >>} 110 $h 185 $h1"}
		set values [eval [concat dialog -w [expr {$isGlobal ? 380 : 550}] -h [expr {$h + 30}] \
		  -b OK [expr {$isGlobal ? 300 : 470}] $h [expr {$isGlobal ? 365 : 535}] $h1 \
		  -b Cancel [expr {$isGlobal ? 215 : 385}] $h [expr {$isGlobal ? 280 : 450}] $h1 $box]]
		if {$isGlobal && !$page} {
			set hideExtensions [lindex $values 2]
			set hideDeprecated [lindex $values 3]
			set values [lreplace $values 2 3]
		}
		if {[lindex $values 1]} {error "Cancel"}
		set uh1 ""
		set g2 0
		for {set i 0} {$i < $n} {incr i} {
			set v [lindex $values [expr {$i + $g2 + 2}]]
			if {[lindex $g1 $i]} {
				if {[lindex $values [expr {$i + $g2 + 3}]]} {
					lappend over [lindex $optatts [expr {$start($page) + $i}]]
					set over [lunique $over]
				} else {
					set over [lremove $over [list [lindex $optatts [expr {$start($page) + $i}]]]]
				}
				incr g2
			}
			lappend uh1 [lsearch -exact $options $v]
		}
		set uh [eval [concat lreplace [list $uh] $start($page) $end($page) $uh1]]
		if {[lindex $values 0]} {break}
		if {$page > 0 && [lindex $values [expr {$n + $g + 2}]]} {
			incr page -1
		} else {
			incr page
			if {![info exists start($page)]} {set start($page) [expr {$end([expr {$page - 1}]) + 1}]}
			if {![info exists end($page)]} {set end($page) -1}
		}
	}
	set used ""
	set hidden ""
	set dont ""
	for {set i 0} {$i < $attrnumber} {incr i} {
		if {[lindex $uh $i] == $isGlobal} {lappend used [lindex $optatts $i]}
		if {$isGlobal && [lindex $uh $i] == 2} {lappend dont [lindex $optatts $i]}
		if {[lindex $uh $i] == [expr {2 + $isGlobal}]} {lappend hidden [lindex $optatts $i]}
	}
	foreach h {hideExtensions hideDeprecated} {
		if {[set $h] != $HTMLmodeVars($h)} {
			set HTMLmodeVars($h) [set $h]
			prefs::modifiedModeVar $h HTML
			html::Hide
		}
	}
}

proc html::IndentationPrefs {} {
	global HTMLmodeVars html::ElemLayout html::OptionalClosingTags html::xhtml
	set indent $HTMLmodeVars(indentElements)
	set box [dialog::title {HTML mode Indentation Preferences} 450]
	append box " -t {Indent the content of} 10 15 150 30"
	set ww 45; set hh 10
	set elements ""
	foreach elem [lsort [array names html::ElemLayout]] {
		if {[set html::ElemLayout($elem)] == "cr2"} {
			lappend elements $elem
		}
	}
	if {[llength $elements] > 40} {
		for {set i 1} {$i <= [expr {[llength $elements]/40 + 1}]} {incr i} {
			lappend mtxt "Page $i of preferences"
		}
		append box " -m [list [concat {{Page 1 of preferences}} $mtxt]] 250 15 450 35"
		append box " -n {Page 1 of preferences}"
	}
	set i 1
	foreach elem $elements {
		append box " -c $elem [lcontains indent $elem] $hh $ww [expr {$hh + 110}] [expr {$ww + 15}]"
		incr ww 20
		if {$ww > 225} {
			set ww 45
			incr hh 115
			if {$hh > 440} {
				set hh 10
				append box " -n {Page [incr i] of preferences}"
			}
		}
	}
	
	if {![llength $elements]} {alertnote "No elements can be indented."; return}
	set val [eval [concat dialog -w 460 -h 290 -b OK 380 260 445 280 \
	  -b Cancel 295 260 360 280 $box]]
	if {[lindex $val 1]} {return}
	set indent ""
	set indentinX ""
	set ex [expr {[llength $elements] > 40}]
	for {set i 0} {$i < [llength $elements]} {incr i} {
		if {[lindex $val [expr {$i + 2 + $ex}]]} {
			lappend indent [lindex $elements $i]
			if {$html::xhtml && [lcontains html::OptionalClosingTags [lindex $elements $i]]} {
				lappend indentinX [lindex $elements $i]
			}
		}
	}
	set HTMLmodeVars(indentElements) $indent
	prefs::modifiedModeVar indentElements HTML
	if {$html::xhtml} {
		set HTMLmodeVars(indentInXHTML) $indentinX
		prefs::modifiedModeVar indentInXHTML HTML
	}
}

proc html::OptionalClosingTags {} {
	global HTMLmodeVars html::OptionalClosingTags html::ElemLayout html::xhtml
	if {$html::xhtml} {return}
	set box [dialog::title {HTML mode Optional Closing Tags Preferences} 450]
	append box " -t {Use the closing tags of} 10 15 450 30"
	set ww 45; set hh 10
	foreach elem ${html::OptionalClosingTags} {
		append box " -c $elem [lcontains HTMLmodeVars(optionalClosing) $elem] $hh $ww [expr {$hh + 100}] [expr {$ww + 15}]"
		incr ww 20
		if {$ww > 125} {
			set ww 45
			incr hh 110
		}
	}
	set val [eval [concat dialog -w 460 -h 190 -b OK 380 160 445 180 \
	  -b Cancel 295 160 360 180 $box]]
	if {[lindex $val 1]} {return}
	set oldclosing $HTMLmodeVars(optionalClosing)
	set HTMLmodeVars(optionalClosing) ""
	for {set i 0} {$i < [llength ${html::OptionalClosingTags}]} {incr i} {
		set elem [lindex ${html::OptionalClosingTags} $i]
		if {[lindex $val [expr {$i + 2}]]} {
			lappend HTMLmodeVars(optionalClosing) $elem
		}
		if {([lindex $val [expr {$i + 2}]] && ![lcontains oldclosing $elem]) ||
		(![lindex $val [expr {$i + 2}]] && [lcontains oldclosing $elem])} {
			# Find new layout
			html::FindOptionalLayout $elem
			# Make sure content is not indented if is shouldn't be.
			if {[set html::ElemLayout($elem)] != "cr2" && [lcontains HTMLmodeVars(indentElements) $elem]} {
				set HTMLmodeVars(indentElements) [lremove $HTMLmodeVars(indentElements) [list $elem]]
				prefs::modifiedModeVar indentElements HTML
			}
		}
	}
	prefs::modifiedModeVar optionalClosing HTML
}


proc html::ElementLayout {} {
	global html::ElemAttrOptional
	set htmlPossibleToUse [lremove [array names html::ElemAttrOptional] {{LI IN OL}} {{LI IN UL}}]
	regsub -all {\{INPUT TYPE=[^ ]+} $htmlPossibleToUse " " htmlPossibleToUse
	lappend htmlPossibleToUse INPUT
	if {![catch {listpick -p "Choose HTML element" [lsort $htmlPossibleToUse]} elem] &&
	$elem != ""} {html::ElementLayoutDialog $elem}
}

proc html::ElementLayoutDialog {elem} {
	global html::ElemLayout HTMLmodeVars html::ElemLayoutNoClosing html::ElemLayoutClosing html::OptionalClosingTags
	switch [set html::ElemLayout($elem)] {
		nocr {set val {1 0 0 0}}
		cr0 {set val {0 1 0 0}}
		cr1 {set val {0 0 1 0}}
		cr2 {set val {0 0 0 1}}
		open00 {set val {0 0}}
		open10 {set val {1 0}}
		open01 {set val {0 1}}
		open11 {set val {1 1}}
	}
	if {[regexp {open} [set html::ElemLayout($elem)]]} {
		set layout [html::SetLayoutEmpty $val $elem]
	} else {
		set layout [html::SetLayoutClosing $val $elem]
	}
	set html::ElemLayout($elem) $layout
	prefs::modifiedArrayElement $elem html::ElemLayout
	if {[lcontains html::OptionalClosingTags $elem]} {
		if {[regexp {open} [set html::ElemLayout($elem)]]} {
			set html::ElemLayoutNoClosing($elem) $html::ElemLayout($elem)
			prefs::modifiedArrayElement $elem html::ElemLayoutNoClosing
		} else {
			set html::ElemLayoutClosing($elem) $html::ElemLayout($elem)
			prefs::modifiedArrayElement $elem html::ElemLayoutClosing
		}
	}
	
	# Make sure content is not indented if it shouldn't be.
	if {$layout != "cr2" && [lcontains HTMLmodeVars(indentElements) $elem]} {
		set HTMLmodeVars(indentElements) [lremove $HTMLmodeVars(indentElements) [list $elem]]
		prefs::modifiedModeVar indentElements HTML
	}
}

proc html::SetLayoutEmpty {values element} {
	set box "[dialog::title "Layout of $element" 180] \
	-c {Always a new line before tag} [lindex $values 0] 10 20 225 35 \
	-c {Always a new line after tag} [lindex $values 1] 10 40 225 55 \
	-b OK 150 70 215 90 -b Cancel 65 70 130 90"
	set values [eval [concat dialog -w 230 -h 100 $box]]
	if {[lindex $values 3]} {error "Cancel"}
	return "open[lindex $values 0][lindex $values 1]"
}

proc html::SetLayoutClosing {values element} {
	set box "[dialog::title "Layout of $element" 180] \
	-r {text<TAG>text</TAG>text} [lindex $values 0] 10 20 220 40 \
	-r {text\r<TAG>text</TAG>\rtext} [lindex $values 1] 10 50 200 110 \
	-r {blank line\r<TAG>text</TAG>\rblank line} [lindex $values 2] 10 120 200 180 \
	-r {blank line\r<TAG>\rtext\r</TAG>\rblank line} [lindex $values 3] 10 190 200 290"
	set values [eval [concat dialog -w 220 -h 330 \
	-b OK 140 300 205 320 -b Cancel 55 300 120 320 $box]]
	if {[lindex $values 1]} {error "Cancel"}
	if {[lindex $values 2]} {set layout nocr}
	if {[lindex $values 3]} {set layout cr0}
	if {[lindex $values 4]} {set layout cr1}
	if {[lindex $values 5]} {set layout cr2}
	return $layout
}

proc html::TypesPrefs {type txt} {
	global HTMLmodeVars
	hook::register deactivateHook html::${type}DeactHook Text
	hook::register closeHook html::${type}CloseHook Text
	if {[catch {bringToFront "* $txt *"}]} { 
		new -n "* $txt *" -shell 1
		insertText [join $HTMLmodeVars($type) "\r"]
		shrinkWindow 1 
		if {$HTMLmodeVars(explainTypePrefs)} {
			set txt1 [string tolower $txt]
			set v [dialog -w 350 -h 210 -t "Modify the list of $txt1 by editing the window just opened.\
			  Each [string trim $txt1 s] must be separated by either a space or a new line.\
			  Any item containing spaces must be put within quotes."  10 10 340 75\
			  -t "The\
			  new $txt1 are saved when the window is closed.\
			  Cancel the changes by holding down the shift key while clicking the window's\
			  close box." 10 80 340 140 \
			  -c "Do not explain this to me in the future" 0 10 150 340 165 \
			  -b OK 270 180 335 200]
			if {[lindex $v 0]} {
				set HTMLmodeVars(explainTypePrefs) 0
				prefs::modifiedModeVar explainTypePrefs HTML
			}
		}
	}
}


proc html::contenttypesDeactHook {name} {
	if {$name != "* Content Types *"} {return}
	html::TypesDeactHook contenttypes
}

proc html::linktypesDeactHook {name} {
	if {$name != "* Link Types *"} {return}
	html::TypesDeactHook linktypes
}

proc html::mediatypesDeactHook {name} {
	if {$name != "* Media Descriptors *"} {return}
	html::TypesDeactHook mediatypes	
}

proc html::contenttypesCloseHook {name} {
	if {$name != "* Content Types *"} {return}
	html::TypesCloseHook contenttypes
}

proc html::linktypesCloseHook {name} {
	if {$name != "* Link Types *"} {return}
	html::TypesCloseHook linktypes
}

proc html::mediatypesCloseHook {name} {
	if {$name != "* Media Descriptors *"} {return}
	html::TypesCloseHook mediatypes	
}

proc html::TypesDeactHook {type} {
	global html::tmp${type}
	set html::tmp${type} [getText [minPos] [maxPos]]
}

proc html::TypesCloseHook {type} {
	global HTMLmodeVars html::tmp${type}
	if {![key::shiftPressed]} {
		set HTMLmodeVars($type) [set html::tmp${type}]
		prefs::modifiedModeVar $type HTML
	}
	hook::deregister deactivateHook html::${type}DeactHook Text
	hook::deregister closeHook html::${type}CloseHook Text
}

#===============================================================================
# ×××× Home pages ×××× #
#===============================================================================

# Dialog to handle servers and corresponding home page folders.
proc html::HomePages {{this ""}} {
	global HTMLmodeVars html::NFmirrorFiles
	
	set pages $HTMLmodeVars(homePages)
	set servers $HTMLmodeVars(FTPservers)
	set templates $HTMLmodeVars(templateFolders)
	array set mirrors [array get html::NFmirrorFiles]
	set touchedIt 0
	if {$this == ""} {set this °}
	while {1} {
		set box "[dialog::title {Home pages} 300] -t {URLs:} 10 20 100 40 \
		-t {Home Page Folder:} 10 50 110 85 \
		-t {Include Folder:} 10 90 110 110 \
		-t {Template Folder:} 10 120 120 140 \
		-t {Default file:} 10 150 100 170 \
		-t {Ftp server:} 10 180 100 200 -t {User ID:} 10 205 100 225 \
		-t Password: 10 230 100 250 -t Directory: 10 255 100 275 \
		-b OK 340 305 405 325 -b Cancel 260 305 325 325 \
		-b NewÉ 10 305 75 325 \
		-c {Tell Big Brother} 0 280 285 400 300"
		if {[llength $pages]} {
			set pgs ""
			foreach pg $pages {
				lappend pgs "[lindex $pg 1][lindex $pg 2]"
			}
			append box " -m [list [concat $this $pgs]] 125 20 400 40"
			append box " -b ChangeÉ 85 305 165 325 -b Remove 175 305 250 325"
			foreach pg $pages {
				lappend box -n "[lindex $pg 1][lindex $pg 2]" -t [dialog::specialView::file [lindex $pg 0]] 125 50 400 90 \
				-t [lindex $pg 3] 125 150 310 170
				if {[llength $pg] == 5} {lappend box -t [dialog::specialView::file [lindex $pg 4]] 125 90 400 110}
				foreach f $servers {
					if {[lindex $f 0] == [lindex $pg 0]} {
						lappend box -t [lindex $f 1] 125 180 400 200 \
						-t [lindex $f 2] 125 205 400 225
						set pwb ""
						for {set i 0} {$i < [string length [lindex $f 3]]} {incr i} {
							append pwb ¥
						}
						lappend box -t $pwb 125 230 400 250 \
						-t [dialog::specialView::file [lindex $f 4]] 125 255 400 275
					}
				}
				foreach f $templates {
					if {[lindex $f 0] == [lindex $pg 0]} {
						lappend box -t [dialog::specialView::file [lindex $f 1]] 125 120 400 140
					}
				}
			}
		} else {
			append box  " -m {{None defined} {None defined}} 125 20 400 40"
		}
		set values [eval [concat dialog -w 410 -h 335 $box]]
		set this [lindex $values 4]
		if {[lindex $values 0]} {
			set HTMLmodeVars(homePages) $pages
			set HTMLmodeVars(FTPservers) $servers
			set HTMLmodeVars(templateFolders) $templates
			prefs::modifiedModeVar homePages HTML
			prefs::modifiedModeVar FTPservers HTML
			prefs::modifiedModeVar templateFolders HTML
			foreach mir [array names html::NFmirrorFiles] {
				if {![info exists mirrors($mir)]} {unset html::NFmirrorFiles($mir)}
				if {![info exists mirrors($mir)] || [set html::NFmirrorFiles($mir)] != $mirrors($mir)} {
					prefs::modifiedArrayElement $mir html::NFmirrorFiles
				}
			}
			foreach mir [array names mirrors] {
				if {![info exists html::NFmirrorFiles($mir)]} {
					prefs::modifiedArrayElement $mir html::NFmirrorFiles
				}
			}
			array set html::NFmirrorFiles [array get mirrors]
			if {[lindex $values 3]} {
				if {[html::GetVersion Bbth] < 1.1} {
					alertnote "Cannot change the settings in Big Brother. You need Big Brother 1.1 or later."
				} elseif {[askyesno "Change URL mappings in Big Brother?"] == "yes"} {
					if {![app::isRunning Bbth] && [catch {app::launchBack Bbth}]} {
						alertnote "Could not find or launch Big Brother."
						return
					}
					set urlmap [html::URLmap]
					tclAE::send 'Bbth' core setd "----" "obj{want:type('mapG'),from:null(),form:'prop',seld:type('mapS')}" "data" "\[$urlmap\]"
				}
			}
			return
		} elseif {[lindex $values 1]} {
			if {!$touchedIt || [askyesno "Really cancel without saving changes?"] == "yes"} {return}
		} elseif {[lindex $values 2]} {
			set newpg {{} {} {} "index.html" {}}
			set newserver {{} {} {} {}}
			set newtemplate {}
			while {1} {
				if {[catch {html::SetHomePages $pages [lindex $newpg 0] "[lindex $newpg 1][lindex $newpg 2]" [lindex $newpg 3] [lindex $newpg 4]} newpg]} {break}
				if {[html::TestHomePage $pages $newpg]} {
					lappend pages $newpg
					if {[lindex $newserver 0] != ""} {lappend servers [concat [list [lindex $newpg 0]] $newserver]}
					if {$newtemplate != ""} {lappend templates [concat [list [lindex $newpg 0]] [list $newtemplate]]}
					set this "[lindex $newpg 1][lindex $newpg 2]"
					set touchedIt 1
					break
				}
			}
		} else {
			for {set i 0} {$i < [llength $pages]} {incr i} {
				if {"[lindex [lindex $pages $i] 1][lindex [lindex $pages $i] 2]" == $this} {
					if {[lindex $values 5]} {
						set newpg [lindex $pages $i]
						set pg "[lindex $newpg 1][lindex $newpg 2]"
						set oldpage [lindex $newpg 0]
						set newserver {{} {} {} {}}
						foreach f $servers {
							if {[lindex $f 0] == $oldpage} {set newserver [lrange $f 1 end]}
						}
						set newtemplate {}
						foreach f $templates {
							if {[lindex $f 0] == $oldpage} {set newtemplate [lindex $f 1]}
						}
						while {1} {
							if {[catch {html::SetHomePages $pages [lindex $newpg 0] "[lindex $newpg 1][lindex $newpg 2]" [lindex $newpg 3] [lindex $newpg 4] $pg} newpg]} {break}
							if {[html::TestHomePage $pages $newpg $pg]} {
								set pages [lreplace $pages $i $i $newpg]
								set ns ""
								foreach f $servers {
									if {[lindex $f 0] != $oldpage} {lappend ns $f}
								}
								set servers $ns
								set nt ""
								foreach f $templates {
									if {[lindex $f 0] != $oldpage} {lappend nt $f}
								}
								set templates $nt
								if {[lindex $newserver 0] != ""} {lappend servers [concat [list [lindex $newpg 0]] $newserver]}
								if {$newtemplate != ""} {lappend templates [concat [list [lindex $newpg 0]] [list $newtemplate]]}
								if {[info exists mirrors($oldpage)]} {
									set mirrors([lindex $newpg 0]) $mirrors($oldpage)
									unset mirrors($oldpage)
								}
								set this "[lindex $newpg 1][lindex $newpg 2]"
								set touchedIt 1
								break
							}
						}
					} else {
						set tpg [lindex [lindex $pages $i] 0]
						set ns ""
						foreach f $servers {
							if {[lindex $f 0] != $tpg} {lappend ns $f}
						}
						set servers $ns
						set nt ""
						foreach f $templates {
							if {[lindex $f 0] != $tpg} {lappend nt $f}
						}
						set templates $nt
						catch {unset mirrors($tpg)}
						set pages [lreplace $pages $i $i]
						set touchedIt 1
					}
				}
			}
		}
	}
}

# Dialog to define or change a home page.
proc html::SetHomePages {pages folder url defFile inclFld {pg ""}} {
	upvar newserver server newtemplate template
	while {1} {
		set pwb ""
		for {set i 0} {$i < [string length [lindex $server 2]]} {incr i} {
			append pwb ¥
		}
		set box "-T {Edit Home Page}"
		lappend box -t {Home Page Folder:} 10 10 135 30 -t [dialog::specialView::file $folder] 140 10 440 50 \
		  -t {Include Folder:} 10 60 110 80 -t [dialog::specialView::file $inclFld] 130 60 440 100 \
		  -t {Template Folder:} 10 110 120 130 -t [dialog::specialView::file $template] 130 110 440 150 \
		  -t {URL:} 10 160 90 180 \
		  -e $url 100 160 440 175 -t {Default file:} 10 195 90 210 \
		-e $defFile 100 195 440 210 \
		  -t {Ftp Server:} 10 230 90 250 -e [lindex $server 0] 100 230 440 245 \
		  -t {User ID:} 10 255 90 275 -e [lindex $server 1] 100 255 440 270 \
		  -t Password: 10 280 85 300 -t $pwb 160 280 440 295 \
		  -t Directory: 10 310 90 330 -e [lindex $server 3] 100 310 440 325 \
		-b OK 370 340 435 360 -b Cancel 285 340 350 360  -b SetÉ 90 280 150 300 \
		  -b SetÉ 20 30 80 50 -b SetÉ 5 80 60 100 -b Unset 70 80 128 100 \
		  -b SetÉ 5 130 60 150 -b Unset 70 130 128 150
		set val [eval [concat dialog -w 450 -h 370 $box]]
		set url [string trim [lindex $val 0]]
		set defFile [string trim [lindex $val 1]]
		set ftp [string trim [lindex $val 2]]
		regexp {^(ftp://)?(.*)$} $ftp dum1 dum2 ftp
		set dir [string trimright [string trim [lindex $val 4]] /]
		if {[lindex $val 7] && ![catch {dialog::password "Password for $ftp:"} newpw]} {
			set pw $newpw
		} else {
			set pw [lindex $server 2]
		}
		set server [list $ftp [string trim [lindex $val 3]] \
		$pw $dir]
		if {[lindex $val 8] && ![catch {html::GetDir "Home Page Folder:"} fld]} {
			set folder $fld
		} elseif {[lindex $val 9] && ![catch {html::GetDir "Include Folder:"} fld]} {
			set inclFld $fld
		} elseif {[lindex $val 10]} {
			set inclFld ""
		} elseif {[lindex $val 11] && ![catch {html::GetDir "Template Folder:"} fld]} {
			set template $fld
		} elseif {[lindex $val 12]} {
			set template ""
		} elseif {[lindex $val 5]} {
			if {![regexp {://} $url] && $url != ""} {
				set url "http://$url"
			}
			if {[lindex $server 0] != "" && [lindex $server 1] == ""} {
				alertnote "When you specify an ftp server you must give the user ID."
			} elseif {[string length $folder] && [string length $url] && [string length $defFile]} {
				regexp -indices {://} $url css
				set sl [string first / [string range $url [expr {[lindex $css 1] + 1}] end]]
				if {$sl < 0} {
					set base "$url/"
					set path ""
				} elseif {[string index $url [expr {[string length $url] -1}]] != "/"} {
					alertnote "A directory URL ending with a slash expected."
					continue
				} else {
					set base [string range $url 0 [expr {[lindex $css 1] + $sl + 1}]]
					set path [string range $url [expr {[lindex $css 1] + $sl + 2}] end]
				}
				set ret [list $folder $base $path $defFile]
				if {$inclFld != ""} {lappend ret $inclFld}
				return  $ret
			} else {
				alertnote "Home page folder, URL, and default file must be specified."
			}
		} elseif {[lindex $val 6]} {
			error ""
		}
	}
}

proc html::TestHomePage {pages newpg {pg ""}} {
	
	foreach p $pages {
		if {"[lindex $p 1][lindex $p 2]" == $pg} {continue}
		if {[string match "[lindex $p 1][lindex $p 2]*" "[lindex $newpg 1][lindex $newpg 2]"] ||
		[string match "[lindex $newpg 1][lindex $newpg 2]*" "[lindex $p 1][lindex $p 2]"]} {
			if {[string length "[lindex $p 1][lindex $p 2]"] > [string length "[lindex $newpg 1][lindex $newpg 2]"]} {
				set s1 "[lindex $p 1][lindex $p 2]"; set s2 "[lindex $newpg 1][lindex $newpg 2]"
			} else {
				set s2 "[lindex $p 1][lindex $p 2]"; set s1 "[lindex $newpg 1][lindex $newpg 2]"
			}
			if {$s1 == $s2} {
				alertnote "You have already defined a home page folder for $s1."
			} else {				
				dialog::alert "There is already a home page folder for [lindex $p 1][lindex $p 2].\
				  You can't define a home page folder for both [lindex $p 1][lindex $p 2] and [lindex $newpg 1][lindex $newpg 2].\
				  Instead put the content of $s1 inside $s2 and use one home page folder."
			}
			return 0
		}
	}
	set msg {"home page" "" "" "" include}
	foreach p $pages {
		foreach i {0 4} {
			if {"[lindex $p 1][lindex $p 2]" == $pg	|| [llength $p] == $i} {continue}
			foreach j {0 4} {
				if {[llength $newpg] == $j} {continue}
				if {[string match [file join [lindex $p $i] *] [file join [lindex $newpg $j] " "]] || \
				  [string match [file join [lindex $newpg $j] *] [file join [lindex $p $i] " "]]} {
					alertnote "The [lindex $msg $j] folder overlaps with the [lindex $msg $i] folder for [lindex $p 1][lindex $p 2]."
					return 0
				}
			}
		}
	}
	if {[lindex $newpg 4] != "" && 
	([string match [file join [lindex $newpg 0] *] [file join [lindex $newpg 4] " "]] ||
	[string match [file join [lindex $newpg 4] *] [file join [lindex $newpg 0] " "]])} {
		alertnote "The home page folder and include folder cannot be inside one another."
		return 0
	}
	return 1
}	


