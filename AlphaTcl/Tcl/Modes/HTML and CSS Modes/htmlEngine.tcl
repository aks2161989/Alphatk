## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlEngine.tcl"
 #                                    created: 99-07-17 14.03.18 
 #                                last update: 01/24/2005 {06:16:21 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 3.2
 # 
 # Copyright 1996-2004 by Johan Linde
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
# This file contains the main procs building elements and for handling 
# the attribute dialogs.
#===============================================================================

#===============================================================================
# ×××× Element building routines ×××× #
#===============================================================================

proc html::Tag {elem {option ""}} {
	global html::ElemLayout html::Plugins
	if {![win::checkIfWinToEdit]} {return}
	if {[html::IsInContainer STYLE]} {
		if {[lcontains html::Plugins $elem]} {set elem EMBED}
		if {[regexp {INPUT TYPE=} $elem]} {set elem INPUT}
		replaceText [getPos] [selEnd] [css::SetCase $elem]
		return
	}
	set elem2 $elem
	if {[regexp {INPUT TYPE=} $elem]} {set elem2 INPUT}
	if {[lcontains html::Plugins $elem]} {set elem2 EMBED}
	switch [set html::ElemLayout($elem2)] {
		open00 {html::BuildOpening $elem 0 0 $option}
		open10 {html::BuildOpening $elem 1 0 $option}
		open01 {html::BuildOpening $elem 0 1 $option}
		open11 {html::BuildOpening $elem 1 1 $option}
		nocr   {html::BuildElem $elem $option}
		cr0    {html::BuildCRElem $elem 0 $option}
		cr1    {html::BuildCRElem $elem 1 $option}
		cr2    {html::BuildCR2Elem $elem $option}
	}
}

# Closing tag of an element
proc html::CloseElem {elem} {
	return "</[html::SetCase $elem]>"
}

proc html::SetCase {elem} {
	global HTMLmodeVars html::xhtml
	if {$HTMLmodeVars(useLowerCase) || $html::xhtml} { 
		return [string tolower $elem] 
	} else {
		return [string toupper $elem] 
	}
}

# Build elements with only a opening tag.
proc html::BuildOpening {elem {begCR 0} {endCR 0} {attr ""}} {
	global html::Plugins html::xhtml HTMLmodeVars
	set text ""
	if {$begCR} { 
		set text [html::OpenCR]
	}
	if {[lcontains html::Plugins $elem]} {set attr $elem; set elem EMBED}
	set pos [expr {[string length $text] ? [string length [text::maxSpaceForm [text::indentString [getPos]]]] : -1}]
	if {[set text1 [html::OpenElem $elem $attr $pos]] == ""} {return}
	if {$html::xhtml} {
		set text1 [html::EndOfEmptytag $text1]
	}
	append text $text1
	if {$endCR} {
		set text2 [html::CloseCR]
		append text $text2
	}
	html::elecInsertion text
}


# This is used for almost all containers
proc html::BuildElem {ftype {attr ""}} {
	global HTMLmodeVars htmlCurSel htmlIsSel
	
	if {[set text [html::OpenElem $ftype $attr]] == ""} {return}
	html::GetSel
	set ind [string length [text::maxSpaceForm [text::indentString [getPos]]]]
	if {$htmlIsSel} {
		append text [text::indentBy $htmlCurSel [expr {-$ind}]]
	} else {
		append text "¥content¥"
	}
	append text [html::CloseElem $ftype]
	if {!$htmlIsSel && $HTMLmodeVars(useTabMarks)} {append text "¥end¥"}
	if {$htmlIsSel} {
		deleteSelection
	} 
	if {$HTMLmodeVars(adjustIndentation) && [is::Whitespace [getText [lineStart [getPos]] [getPos]]]} {
		HTML::indentLine
		if {[pos::compare [set p [lindex [text::firstNonWsLinePos [getPos]] 0]] > [getPos]]} {goto $p}
	}
	elec::Insertion $text
}

# This is used for elements that should be surrounded by newlines
proc html::BuildCRElem {ftype {extrablankline 0} {attr ""}} {
	global htmlCurSel htmlIsSel HTMLmodeVars
	
	html::GetSel
	set ind [string length [text::maxSpaceForm [text::indentString [getPos]]]]
	if {$htmlIsSel} {
		set htmlCurSel [text::indentBy $htmlCurSel [expr {-$ind}]]
	}	
	if {[set text2 [html::OpenElem $ftype $attr $ind]] == ""} {return}
	if {$htmlIsSel} { deleteSelection }
	html::RemoveSurroundingWhite
	set text [html::OpenCR $extrablankline]
	append text $text2
	if {$htmlIsSel} {
		append text $htmlCurSel
	} else {
		append text "¥content¥"
	}
	append text [html::CloseElem $ftype]
	set text2 ""
	if {$extrablankline} {
		set text2 [html::CloseCR2 [selEnd]]
	} else {
		set text2 [html::CloseCR]
	}
	append text $text2
	if {!$htmlIsSel && $HTMLmodeVars(useTabMarks)} {append text "¥end¥"}
	html::elecInsertion text
}

# This is used for elements that should be surrounded by empty lines
proc html::BuildCR2Elem {ftype {attr ""}} {
	global HTMLmodeVars htmlCurSel htmlIsSel
	
	html::GetSel
	set ind [string length [text::maxSpaceForm [text::indentString [getPos]]]]
	if {$htmlIsSel} {
		set htmlCurSel [text::indentBy $htmlCurSel [expr {-$ind}]]
	}	
	if {[set text1 [html::OpenElem $ftype $attr $ind]] == ""} {return}
	if {$htmlIsSel} { deleteSelection }
	html::RemoveSurroundingWhite
	set text [html::OpenCR 1]
	append text $text1
	set text0 "\r"
	if {$ftype == "SCRIPT" || $ftype == "STYLE"} {
		append text0 "<!--\r"
	}
	if {$htmlIsSel} {
		append text0 $htmlCurSel
	} else {
		append text0 "¥content¥"
	}
	if {[lcontains HTMLmodeVars(indentElements) $ftype]} {
		regsub -all "\r" $text0 "\r\t" text0
	}
	append text $text0
	set pre(SCRIPT) "// "; set pre(STYLE) "";
	if {$ftype == "SCRIPT" || $ftype == "STYLE"} {
		set text0 "\r$pre($ftype)-->"
		if {[lcontains HTMLmodeVars(indentElements) $ftype]} {
			regsub -all "\r" $text0 "\r\t" text0
		}
		append text $text0
	}
	append text \r [html::CloseElem $ftype] [html::CloseCR2 [selEnd]]
	if {!$htmlIsSel && $HTMLmodeVars(useTabMarks)} {append text "¥end¥"}
	html::elecInsertion text
}

# Returns one or two carriage returns at the insertion point if any
# character preceding the insertion point (on the same line)
# is a non-whitespace character.
proc html::OpenCR {{extrablankline 0} {etxt ""}} {
	set end [getPos]
	set start [lineStart $end]
	set text [getText $start $end]
	if {![is::Whitespace $text]} {
		set r "\r$etxt"
		if {$extrablankline} {append r "\r$etxt"}
		return $r
	} elseif {[pos::compare $start > [minPos]] } { 
		set prevstart [lineStart [pos::math $start - 1 ]]
		set text [getText $prevstart [pos::math $start - 1]]
		if {![is::Whitespace $text] && $extrablankline} {
			return "\r$etxt"
		} else { 
			return ""
		}
	} else {
		return ""
	}
}

# Insert a carriage return at the insertion point if any
# character following the insertion point (on the same line)
# is a non-whitespace character.
proc html::CloseCR {{start ""}} {
	if {$start == ""} {set start [selEnd]}
	if {![is::Whitespace [getText $start [nextLineStart $start]]]} {
		return "\r"
	}
	return ""
}

# Insert up to two carriage return at the insertion point depending
# on how many blank lines there are after the insertion point.
proc html::CloseCR2 {pos {etxt ""}} {
	set blank1 [is::Whitespace [getText $pos [nextLineStart $pos]]]
	set blank2 [is::Whitespace [getText $pos [nextLineStart [nextLineStart $pos]]]]
	if {!$blank1} {
		return "\r$etxt\r"
	} elseif {!$blank2} {
		return "\r"
	}
	return ""
}

# A couple of functions to get element variables from the right package.
proc html::GetSomeAttrs {item type} {
	global html::Elem${type}
	if {[catch {set atts [set html::Elem${type}($item)]}]} { 
		set atts {} 
	}
	return $atts
}	

proc html::GetRequired {item} {
	global html::HideDeprecated html::xhtml
	set attrs [html::GetSomeAttrs $item AttrRequired]
	if {${html::HideDeprecated} && $item == "BASE"} {lappend attrs "HREF="}
	if {$html::xhtml && $item == "MAP"} {
		set attrs [concat "ID=" $attrs]
		regsub "NAME=" $attrs " " attrs
	}
	set exp "\[ \n\r\t]+([join [html::GetNotIn $item] |])"
	regsub -all $exp " $attrs" " " attrs
	return $attrs
}

proc html::GetUsed {item {reqatts ""} {optatts ""} {arr 0}} {
	global HTMLmodeVars
	set useatts [html::GetSomeAttrs $item AttrUsed]
	if {$arr} {return $useatts}
	if {$reqatts == ""} {set reqatts [html::GetRequired $item]}
	if {$optatts == ""} {set optatts [html::GetOptional $item]}
	set over [html::GetOverride $item]
	set exp "\[ \n\r\t]+([join $over |])"
	regsub -all $exp " $HTMLmodeVars(alwaysaskforAttributes)" " " alwaysask
	regsub -all $exp " $HTMLmodeVars(dontaskforAttributes)" " " dontask
	set exp "\[ \n\r\t]+([join [concat $useatts $alwaysask] |])"
	regsub -all $exp " $optatts" " " opt1
	set exp "\[ \n\r\t]+([join $opt1 |])"
	regsub -all $exp " $optatts" " " useatts
	set exp "\[ \n\r\t]+([join $dontask |])"
	regsub -all $exp " $useatts" " " useatts
	return [concat $reqatts $useatts]
}

proc html::GetHidden {item} {
	return [html::GetSomeAttrs $item AttrHidden]
}

proc html::GetExtensions {item} {
	return [html::GetSomeAttrs $item Extension]
}

proc html::GetNotIn {item} {
	global html::xhtml html::xhtmlversion
	if {!$html::xhtml} {
		return [html::GetSomeAttrs $item NotInHTML]
	}
	if {$html::xhtmlversion == 1.0} {
		return [concat [html::GetSomeAttrs $item NotInXHTML1.0] [html::GetSomeAttrs $item NotInXHTML1.0strict]]
	}
	return [html::GetSomeAttrs $item NotInXHTML$html::xhtmlversion]
}

proc html::GetDeprecated {item} {
	return [html::GetSomeAttrs $item Deprecated]
}

proc html::GetOverride {item} {
	return [html::GetSomeAttrs $item AttrOverride]
}

proc html::GetOptional {item {all 0}} {
	global HTMLmodeVars html::HideDeprecated html::HideExtensions html::xhtml
	set attrs [html::GetSomeAttrs $item AttrOptional]
	if {${html::HideDeprecated} && $item == "BASE"} {
		regsub "HREF=" $attrs " " attrs
	}
	if {$html::xhtml && $item == "MAP"} {
		set attrs [concat "NAME=" $attrs]
		regsub "ID=" $attrs " " attrs
	}
	if {$all} {return $attrs}
	set hidden [html::GetHidden $item]
	set over [html::GetOverride $item]
	set exp1 "\[ \n\r\t]+([join $over |])"
	regsub -all $exp1 " $HTMLmodeVars(alwaysaskforAttributes)" " " alwaysask
	regsub -all $exp1 " $HTMLmodeVars(dontaskforAttributes)" " " dontask
	regsub -all $exp1 " $HTMLmodeVars(neveraskforAttributes)" " " neverask
	set exp1 "\[ \n\r\t]+([join $alwaysask |])"
	regsub -all $exp1 " $hidden" " " hidden
	set exp "\[ \n\r\t]+([join $dontask |])"
	regsub -all $exp " $hidden" " " hidden
	set exp "\[ \n\r\t]+([join $hidden |])"
	regsub -all $exp " $attrs" " " attrs
	set exp "\[ \n\r\t]+([join $neverask |])"
	regsub -all $exp " $attrs" " " attrs
	if {${html::HideDeprecated} || $HTMLmodeVars(hideDeprecated)} {
		set exp "\[ \n\r\t]+([join [concat [html::GetExtensions $item] [html::GetDeprecated $item] [html::GetNotIn $item]] |])"
		regsub -all $exp " $attrs" " " attrs
		if {${html::HideDeprecated}} {regsub "TARGET=" $attrs " " attrs}
	} elseif {${html::HideExtensions} || $HTMLmodeVars(hideExtensions)} {
		set exp "\[ \n\r\t]+([join [concat [html::GetExtensions $item] [html::GetNotIn $item]] |])"
		regsub -all $exp " $attrs" " " attrs
	}
	return $attrs
}

proc html::GetEventHandlers {elem} {
	global html::AttrType
	set attrs ""
	foreach a [html::GetOptional $elem] {
		if {[html::GetAttrType $elem $a] == "eventhandler"} {
			lappend attrs $a
		}
	}
	return $attrs
}


proc html::GetSomeAttrDef {type elem attr} {
	global html::Attr$type
	if {[info exists html::Attr${type}($elem%$attr)]} {
		return [set html::Attr${type}($elem%$attr)]
	} else {
		return [set html::Attr${type}($attr)]
	}
	
}

proc html::GetAttrChoices {elem attr} {
	return [html::GetSomeAttrDef Choices $elem $attr]
}

proc html::GetAttrFixed {elem attr} {
	return [html::GetSomeAttrDef Fixed $elem $attr]
}

proc html::GetAttrType {elem attr} {
	return [html::GetSomeAttrDef Type $elem $attr]
}

proc html::GetAttrRange {elem attr} {
	return [html::GetSomeAttrDef Range $elem $attr]
}

proc html::GetAttrOfType {type} {
	global html::AttrType
	foreach a [array names html::AttrType] {
		if {[set html::AttrType($a)] == $type} {lappend attrs $a}
	}
	return $attrs
}

proc html::GetURLAttrs {} {
	return [html::GetAttrOfType url]
}

proc html::GetColorAttrs {} {
	return [html::GetAttrOfType color]
}

proc html::GetExcludedElems {} {
	global HTMLmodeVars html::HideDeprecated html::HideExtensions html::HideFrames html::xhtml html::xhtmlversion
	global html::NotInStrict html::NotInTransitional html::HTMLextensions html::DeprecatedElems html::XHTML11Only
	set elems ""
	if {${html::HideExtensions} || ${html::HideDeprecated} || $HTMLmodeVars(hideDeprecated) || $HTMLmodeVars(hideExtensions)} {
		set elems ${html::HTMLextensions}
		if {!$html::xhtml || $html::xhtmlversion == 1.0} {
			append elems " " $html::XHTML11Only
		}
	}
	if {${html::HideFrames}} {
		append elems " " ${html::NotInTransitional}
	}
	if {${html::HideDeprecated}} {
		append elems " " ${html::NotInStrict}
	}
	if {$HTMLmodeVars(hideDeprecated)} {
		append elems " " ${html::DeprecatedElems}
	}
	return [lunique $elems]
}

proc html::OpenElem {elem {used ""} {pos -1}} {
	global HTMLmodeVars 
	if {$HTMLmodeVars(useBigWindows)} {
		return [html::OpenElemWindow $elem $used $pos]
	} else {
		return [html::OpenElemStatusBar $elem $used $pos]
	}
}

# Opening or only tag of an element - include attributes
# Big window with all attributes.
# Return empty string if user clicks "Cancel".
proc html::OpenElemWindow {elem used wrPos {values ""} {addNotUsed 0} {addHidden 0} {absPos ""}} {
	global html::WrapPos html::AbsPos
	
	if {![string length $used]} {set used $elem}
	set elem [string toupper $elem]
	set used [string toupper $used]
	
	# get variables for the element
	set reqatts [html::GetRequired $used]
	set optatts [html::GetOptional $used]
	set allatts [html::GetUsed $used $reqatts $optatts]
	regsub -all "\[ \n\r\t]+([join $allatts |])" " $optatts" " " notUsedAtts
	if {$addNotUsed} {
		append allatts " $notUsedAtts"
		set notUsedAtts ""
	}
	if {$addHidden} {
		regsub -all "\[ \n\r\t]+([join $optatts |])" " [html::GetOptional $used 1]" " " hiddenAtts
		set exp "\[ \n\r\t]+([join [html::GetNotIn $used] |])"
		regsub -all $exp " $hiddenAtts" " " hiddenAtts
		append allatts " $hiddenAtts"
	}
	
	set text "<"
	append text [html::SetCase $elem]
	# trick for INPUT
	regsub -nocase {TYPE=(.*)$} $text [html::SetCase "TYPE=\"\\1\""] text
	
	if {![llength $allatts]} {return "$text>"}
	
	set maxHeight [expr {[lindex [getMainDevice] 3] - 140}]
	set thisPage "Page 1 of attributes"
	
	set widthIndex -1
	set heightIndex -1
	set srcIndex -1
	if {$absPos == ""} {
		set html::AbsPos [getPos]
	} else {
		set html::AbsPos $absPos
	}
	
	# build window with attributes 
	set invalidInput 1
	while {$invalidInput} {
		# wrapping
		set html::WrapPos [expr {$wrPos == -1 ? [lindex [pos::toRowCol [getPos]] 1] : $wrPos}]
		incr html::WrapPos [expr {[string length $text] + 1}]
		while {1} {
			set pr $elem
			if {$elem == "EMBED" && $used != "EMBED"} {append pr ", $used"}
			set box1 ""; set box2 ""; set box3 ""
			set page 1
			set wpos 10
			if {[llength $reqatts]} {
				lappend box$page -t {Required attributes} 10 35 200 50
				set hpos 60
			} else {
				set hpos 30
			}
			set attrIndex 2
			set buttons ""
			for {set i 0} {$i < [llength $allatts]} {incr i} {
				set attr [lindex $allatts $i]
				if {$i == [llength $reqatts]} {
					if {$wpos > 20} { incr hpos 20 }
					lappend box$page -t {Optional attributes} 10 [expr {$hpos + 5}] 200 [expr {$hpos + 20}]
					set wpos 10
					incr hpos 30
				}
				set attrType [html::GetAttrType $used $attr]
				if {[catch {eval html::BuildDialog$attrType [list $used] $attr values box$page hpos wpos buttons buttonAction attrIndex $maxHeight}]} {
					incr page
					set hpos 40
					set wpos 10
					eval html::BuildDialog$attrType [list $used] $attr values box$page hpos wpos buttons buttonAction attrIndex $maxHeight
				}
			}
			if {$wpos > 20} { incr hpos 25 }
			
			set box ""
			if {$page == 1} {
				append box $box1
			} elseif {$page == 2} {
				set hpos $maxHeight
				append box " -m \{\{$thisPage\} \{Page 1 of attributes\} \{Page 2 of attributes\}\} 10 10 180 30 -n \{Page 1 of attributes\} $box1 -n \{Page 2 of attributes\} $box2"
			} elseif {$page == 3} {
				set hpos $maxHeight
				append box " -m \{\{$thisPage\} \{Page 1 of attributes\} \{Page 2 of attributes\} \{Page 3 of attributes\}\} 10 10 180 30 -n \{Page 1 of attributes\} $box1 -n \{Page 2 of attributes\} $box2 -n \{Page 3 of attributes\} $box3"
			}
			# Add More button if hidden attrs
			set moreButton 0
			if {[llength $notUsedAtts]} {
				set box " -b MoreÉ 180 [expr {$hpos + 20}] 245 [expr {$hpos + 40}] $box"
				set moreButton 1
			}
			set values [eval dialog -T [list [concat Attributes for $pr]] -w 460 -h [expr {$hpos + 50}] \
			  -b OK 380 [expr {$hpos + 20}] 445 [expr {$hpos + 40}] \
			  -b Cancel 295 [expr {$hpos + 20}] 360 [expr {$hpos + 40}] $box]
			# More button clicked?
			if {$moreButton && [lindex $values 2]} {
				append allatts " $notUsedAtts"
				set notUsedAtts ""
			}
			# If more button...
			if {$moreButton} {
				set values [lreplace $values 2 2]
			}
			# If two pages...
			if {$page > 1} {
				set thisPage [lindex $values 2]
				set values [lreplace $values 2 2]
			}
			# OK button clicked?
			if {[lindex $values 0] } { break }
			# Cancel button clicked?
			if {[lindex $values 1] } { return}
			# Another button clicked
			foreach b $buttons {
				if {[lindex $values $b]} {eval $buttonAction($b) values $b}
			}
		}
		
		
		# put everything together
		set attrtext ""
		set errtext ""
		
		set j 2
		for {set i 0} {$i < [llength $allatts]} {incr i} {
			set attr [lindex $allatts $i]
			set currerr $errtext
			set atext [eval html::ReadDialog[html::GetAttrType $used $attr] [list $used] $attr values j errtext]
			if {$atext == "" && [lcontains reqatts $attr]} {
				if {$currerr == $errtext} {lappend errtext "$attr required."}
			} else {
				append attrtext $atext
			}
		}
		# If everything is OK, add the attribute text to text.
		if {![llength $errtext]} {
			if {([info commands html::${elem}test] == "" && [info commands ::html::${elem}test] == "") || ![eval html::${elem}test $elem [list "$text$attrtext"] alertnote]} { 
				append text $attrtext
				set invalidInput 0
			}
		} else {
			# Put up alert with the error text.
			html::ErrorWindow "Invalid input for $used" $errtext
		}
	}
	
	if {[string length $text] } {append text ">"}
	
	return ${text}
}

proc html::WrapTag {toadd} {
	global fillColumn HTMLmodeVars html::WrapPos html::AbsPos
	if {!$HTMLmodeVars(lineWrap)} {return " $toadd"}
	incr html::WrapPos [string length $toadd]
	if {${html::WrapPos} > $fillColumn && ![html::IsInContainer PRE]} {
		set ind [html::GetIndent ${html::AbsPos}]
		set html::WrapPos [string length "[text::maxSpaceForm $ind]$toadd"]
		return "\r$toadd"
	} else {
		return " $toadd"
	}
}

# Add quotes to attribute
proc html::AddQuotes {v} {
	if {[regexp {\"} $v]} {
		if {[regexp {\'} $v]} {
			regsub -all {\"} $v {\&quot;} v
			return \"$v\"
		}
		return \'$v\'
	}
	return \"$v\"
}

# Remove all whitespace surrounding a given position.
proc html::RemoveSurroundingWhite {{pos ""}} {
	if {![string length $pos]} {
		set pos [getPos]
	} 
	set ppBeg [search -n -s -r 1 -f 0 -- {\S\s+} [pos::prevChar $pos]]
	set ppEnd [search -n -s -r 1 -f 1 -- {\s+\S} $pos]
	if {[llength $ppBeg]} {
		set posBeg [pos::nextChar [lindex $ppBeg 0]]
	} else {
		set posBeg [getPos]
	}
	if {[llength $ppBeg]} {
		set posEnd [pos::prevChar [lindex $ppBeg 1]]
	} else {
		set posEnd [getPos]
	}
	if {[regexp {^\s+$} [getText $posBeg $posEnd]]} {
		deleteText $posBeg $posEnd
		goto $posBeg
	} 
	return
}

#===============================================================================
# ×××× Build dialog procs ×××× #
#===============================================================================

# flag 
proc html::BuildDialogflag {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	if {[expr {$hpos + 20}] > $maxHeight && $wpos < 20 && $page < 3} {error "end of page"}
	set fval [expr {!([lindex $val $index] == "" || ![lindex $val $index])}]
	lappend box -c $attr $fval $wpos $hpos [expr {$wpos + 100}] [expr {$hpos + 15}]
	incr index 
	if {$wpos > 20} { 
		incr hpos 25
		set wpos 10
	} else {
		set wpos 230
	}
}

# url 
proc html::BuildDialogurl {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	upvar srcIndex srcIndex
	global html::UserURLs
	if {$wpos > 20} { incr hpos 25 ; set wpos 10}
	if {[expr {$hpos + 45}] > $maxHeight && $page < 3} {error "end of page"}
	lappend box -t $attr 10 $hpos 120 [expr {$hpos + 15}] \
	  -e [lindex $val $index] 120 $hpos 450 [expr {$hpos + 15}] \
	  -m [concat [list [lindex $val [expr {$index + 1}]] { }] ${html::UserURLs}] \
	  120 [expr {$hpos + 25}] 450 [expr {$hpos + 45}] \
	  -b "FileÉ" 10 [expr {$hpos + 20}] 70 [expr {$hpos + 40}]
	incr index 3
	incr hpos 50
	lappend buttons [expr {$index - 1}]
	if {$elem == "IMG" && $attr == "SRC="} {
		set buttonAction([expr {$index - 1}]) html::FileButtonIMGSRC
		set srcIndex [expr {$index - 3}]
	} else {
		set buttonAction([expr {$index - 1}]) html::FileButton
	}
}

# color 
proc html::BuildDialogcolor {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	global html::userColors html::basicColors
	
	if {$wpos > 20} { incr hpos 25 ; set wpos 10}					
	if {[expr {$hpos + 25}] > $maxHeight && $page < 3} {error "end of page"}
	set htmlColors [lsort [array names html::userColors]]
	append htmlColors " - " ${html::basicColors}
	set ex 0
	if {[string length $attr] > 14} {set ex 20}
	lappend box -t $attr 10 $hpos [expr {120 + $ex}] [expr {$hpos + 15}] \
	  -e [lindex $val $index] [expr {120+ $ex}] $hpos [expr {190 + $ex}] [expr {$hpos + 15}] \
	  -m [concat [list [lindex $val [expr {$index + 1}]] { }] $htmlColors] \
	  [expr {200 + $ex}] $hpos 340 [expr {$hpos + 20}] \
	  -b "New ColorÉ" 350 $hpos 450 [expr {$hpos + 20}]
	incr index 3
	incr hpos 30
	lappend buttons [expr {$index - 1}]
	set buttonAction([expr {$index - 1}]) html::ColorButton
}

# frametarget 
proc html::BuildDialogframetarget {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	global html::UserTargets
	if {$wpos > 20} { incr hpos 25 ; set wpos 10}					
	if {[expr {$hpos + 25}] > $maxHeight && $page < 3} {error "end of page"}
	set Windows {_self _top _parent _blank}
	if {[llength ${html::UserTargets}]} {append Windows " - " ${html::UserTargets}}
	lappend box -t $attr 10 $hpos 120 [expr {$hpos + 15}] \
	  -e [lindex $val $index] 120 $hpos 240 [expr {$hpos + 15}] \
	  -m [concat [list [lindex $val [expr {$index + 1}]] { }] $Windows] \
	  250 $hpos 440 [expr {$hpos + 20}]
	incr index 2
	incr hpos 30
}

# choices 
proc html::BuildDialogchoices {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	if {[expr {$hpos + 20}] > $maxHeight && $wpos < 20 && $page < 3} {error "end of page"}
	lappend box -t $attr $wpos $hpos [expr {$wpos + 100}] [expr {$hpos + 15}] \
	  -m [concat [list [lindex $val $index] { }] [html::GetAttrChoices $elem $attr]] \
	  [expr {$wpos + 110}] $hpos [expr {$wpos + 205}] [expr {$hpos + 20}]
	incr index 
	if {$wpos > 20} { 
		incr hpos 25 
		set wpos 10
	} else {
		set wpos 230
	}
}

# length 
proc html::BuildDialoglength {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	upvar widthIndex widthIndex heightIndex heightIndex
	if {$elem == "IMG" && $attr == "WIDTH=" && $wpos > 20} {
		incr hpos 25
		set wpos 10
	}
	if {[expr {$hpos + 20}] > $maxHeight && $wpos < 20 && $page < 3} {error "end of page"}
	if {$attr == "WIDTH="} {set widthIndex $index}
	if {$attr == "HEIGHT="} {set heightIndex $index}
	lappend box -t $attr $wpos $hpos [expr {$wpos + 100}] [expr {$hpos + 15}] \
	  -e [lindex $val $index] [expr {$wpos + 110}] $hpos [expr {$wpos + 150}] [expr {$hpos + 15}]
	incr index
	if {$elem == "IMG" && $attr == "WIDTH="} {
		incr wpos 170
		lappend box -b "Update Size" $wpos $hpos [expr {$wpos + 95}] [expr {$hpos + 20}]
		lappend buttons $index
		set buttonAction($index) html::UpdateSizeButton
		incr index
	}
	if {$wpos > 20} { 
		incr hpos 25
		set wpos 10
	} else {
		set wpos 230
	}
}

# integer 
proc html::BuildDialoginteger {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialoglength $elem $attr val box hpos wpos bt ba index $maxHeight
}

# other 
proc html::BuildDialogother {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	if {$wpos > 20} { incr hpos 25 ; set wpos 10}					
	if {[expr {$hpos + 20}] > $maxHeight && $page < 3} {error "end of page"}
	lappend box -t $attr 10 $hpos 120 [expr {$hpos + 15}] \
	  -e [lindex $val $index] 120 $hpos 450 [expr {$hpos + 15}] 
	incr index
	incr hpos 25
}

# othernotrim
proc html::BuildDialogothernotrim {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialogother $elem $attr val box hpos wpos bt ba index $maxHeight
}

# fixed 
proc html::BuildDialogfixed {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	if {$wpos > 20} { incr hpos 25 ; set wpos 10}					
	if {[expr {$hpos + 20}] > $maxHeight && $page < 3} {error "end of page"}
	lappend box -t $attr 10 $hpos 120 [expr {$hpos + 15}] \
	  -t [html::GetAttrFixed $elem $attr] 120 $hpos 450 [expr {$hpos + 15}] 
	incr hpos 25
}

# id
proc html::BuildDialogid {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialogother $elem $attr val box hpos wpos bt ba index $maxHeight
}

# ids
proc html::BuildDialogids {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialogother $elem $attr val box hpos wpos bt ba index $maxHeight
}

# anchor
proc html::BuildDialoganchor {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialogother $elem $attr val box hpos wpos bt ba index $maxHeight
}

# targetname
proc html::BuildDialogtargetname {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialogother $elem $attr val box hpos wpos bt ba index $maxHeight
}

# contenttype 
proc html::BuildDialogcontenttype {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	global HTMLmodeVars
	if {$wpos > 20} { incr hpos 25 ; set wpos 10}					
	if {[expr {$hpos + 25}] > $maxHeight && $page < 3} {error "end of page"}
	set ct ""
	if {[llength $HTMLmodeVars(contenttypes)]} {append ct $HTMLmodeVars(contenttypes)}
	lappend box -t $attr 10 $hpos 120 [expr {$hpos + 15}] \
	  -e [lindex $val $index] 120 $hpos 240 [expr {$hpos + 15}] \
	  -m [concat [list [lindex $val [expr {$index + 1}]] { }] $ct] \
	  250 $hpos 440 [expr {$hpos + 20}]
	incr index 2
	incr hpos 30
}

# contenttypes
proc html::BuildDialogcontenttypes {elem attr v b hp wp bt ba ind maxHeight {types contenttypes}} {
	upvar $v val $b box $hp hpos $wp wpos $ind index $bt buttons $ba buttonAction
	global HTMLmodeVars
	if {$wpos > 20} { incr hpos 25 ; set wpos 10}					
	if {[expr {$hpos + 45}] > $maxHeight && $page < 3} {error "end of page"}
	lappend box -t $attr 10 $hpos 120 [expr {$hpos + 15}] \
	  -m [concat [list [lindex $val $index] { }] $HTMLmodeVars($types)] 120 $hpos 250 [expr {$hpos + 20}] \
	  -e [lindex $val [expr {$index + 1}]] 120 [expr {$hpos + 25}] 450 [expr {$hpos + 40}] \
	  -b Add 260 $hpos 320 [expr {$hpos + 20}]
	lappend buttons [expr {$index + 2}]
	set buttonAction([expr {$index + 2}]) html::Add${types}Button
	incr index 3
	incr hpos 50
}

# eventhandler 
proc html::BuildDialogeventhandler {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialogother $elem $attr val box hpos wpos bt ba index $maxHeight
}

# linktypes 
proc html::BuildDialoglinktypes {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index $bt buttons $ba buttonAction
	html::BuildDialogcontenttypes $elem $attr val box hpos wpos buttons buttonAction index $maxHeight linktypes
}

# multilength 
proc html::BuildDialogmultilength {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialoglength $elem $attr val box hpos wpos bt ba index $maxHeight
}

# multilengths 
proc html::BuildDialogmultilengths {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialogother $elem $attr val box hpos wpos bt ba index $maxHeight
	# to be modified
}

# languagecode 
proc html::BuildDialoglanguagecode {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialogother $elem $attr val box hpos wpos bt ba index $maxHeight
	# to be modified
}

# charset 
proc html::BuildDialogcharset {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialogother $elem $attr val box hpos wpos bt ba index $maxHeight
	# to be modified
}

# charsets 
proc html::BuildDialogcharsets {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialogother $elem $attr val box hpos wpos bt ba index $maxHeight
	# to be modified
}

# coords 
proc html::BuildDialogcoords {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialogother $elem $attr val box hpos wpos bt ba index $maxHeight
	# to be modified
}

# oltype 
proc html::BuildDialogoltype {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialogchoices $elem $attr val box hpos wpos bt ba index $maxHeight
}

# datetime 
proc html::BuildDialogdatetime {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	# Any other
	if {$wpos > 20} { incr hpos 25 ; set wpos 10}					
	if {[expr {$hpos + 45}] > $maxHeight && $page < 3} {error "end of page"}
	set fval [expr {!([lindex $val [expr {$index + 7}]] == "" || ![lindex $val [expr {$index + 7}]])}]
	lappend box -t $attr 10 $hpos 120 [set h [expr {$hpos + 15}]] \
	  -e [lindex $val $index] 120 $hpos 155 $h \
	  -t "-" 165 $hpos 175 $h -e [lindex $val [expr {$index + 1}]] 183 $hpos 203 $h \
	  -t "-" 213 $hpos 223 $h -e [lindex $val [expr {$index + 2}]] 231 $hpos 251 $h \
	  -t "T" 261 $hpos 271 $h -e [lindex $val [expr {$index + 3}]] 279 $hpos 299 $h \
	  -t ":" 309 $hpos 319 $h -e [lindex $val [expr {$index + 4}]] 325 $hpos 345 $h \
	  -t ":" 355 $hpos 365 $h -e [lindex $val [expr {$index + 5}]] 371 $hpos 391 $h \
	  -e [lindex $val [expr {$index + 6}]] 405 $hpos 450 $h \
	  -c "Current time" $fval 120 [expr {$hpos + 25}] 300 [expr {$h + 25}]
	incr index 8
	incr hpos 50
}

# character 
proc html::BuildDialogcharacter {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	html::BuildDialoglength $elem $attr val box hpos wpos bt ba index $maxHeight
}

# mediadesc 
proc html::BuildDialogmediadesc {elem attr v b hp wp bt ba ind maxHeight} {
	upvar $v val $b box $hp hpos $wp wpos $ind index $bt buttons $ba buttonAction
	html::BuildDialogcontenttypes $elem $attr val box hpos wpos buttons buttonAction index $maxHeight mediatypes
}


#===============================================================================
# ×××× Button actions ×××× #
#===============================================================================

proc html::ColorButton {v index} {
	upvar $v val
	if {[set newColor [html::AddANewColor]] != ""} {
		if {[string index $newColor 0] == "#"} {
			set val [lreplace $val [incr index -2] $index "$newColor"]
		} else {
			set val [lreplace $val [incr index -1] $index "$newColor"]
		}
	}
}

proc html::FileButton {v index} {
	upvar $v val
	global html::UserURLs
	if {[set newFile [html::GetFile]] != ""} {
		if {[lcontains html::UserURLs [lindex $newFile 0]]} {
			set val [lreplace $val [incr index -1] $index [lindex $newFile 0]]
		} else {
			set val [lreplace $val [incr index -2] $index [lindex $newFile 0]]
		}
	}
	return $newFile
}

proc html::FileButtonIMGSRC {v index} {
	upvar $v val widthIndex widthIndex heightIndex heightIndex
	set newFile [html::FileButton val $index]
	if {[llength [set widhei [lindex $newFile 1]]]} {
		if {$widthIndex >= 0} {set val [lreplace $val $widthIndex $widthIndex [lindex $widhei 0]]}
		if {$heightIndex >= 0} {set val [lreplace $val $heightIndex $heightIndex [lindex $widhei 1]]}
	}
}

proc html::UpdateSizeButton {v index} {
	upvar $v val widthIndex widthIndex heightIndex heightIndex srcIndex srcIndex
	if {[set url [string trim [lindex $val $srcIndex]]] == "" && [set url [lindex $val [expr {$srcIndex + 1}]]] == " "} {return}
	set this [html::ThisFilePath 3]
	if {$this == ""} {return}
	if {[catch {lindex [html::PathToFile [lindex $this 0] [lindex $this 1] [lindex $this 2] [lindex $this 3] $url] 0} path] ||
	![file exists $path]} {
		alertnote "Could not find file."
		return
	} 
	set widthheight [html::GetImageSize $path]
	if {[llength $widthheight]} {
		if {$widthIndex >= 0} {set val [lreplace $val $widthIndex $widthIndex [lindex $widthheight 0]]}
		if {$heightIndex >= 0} {set val [lreplace $val $heightIndex $heightIndex [lindex $widthheight 1]]}
	}
}

proc html::AddcontenttypesButton {v index} {
	upvar $v val
	if {[set f [lindex $val [expr {$index - 2}]]] != " "} {
		set fm [string trim [join [list [lindex $val [expr {$index - 1}]] $f] ", "] ", "]
		set val [lreplace $val [expr {$index - 2}] [expr {$index - 1}] " " $fm]
	}	
}

proc html::AddmediatypesButton {v index} {
	upvar $v val
	html::AddcontenttypesButton val $index
}

proc html::AddlinktypesButton {v index} {
	upvar $v val
	if {[set f [lindex $val [expr {$index - 2}]]] != " "} {
		set fm [string trim [join [list [lindex $val [expr {$index - 1}]] $f] " "]]
		set val [lreplace $val [expr {$index - 2}] [expr {$index - 1}] " " $fm]
	}	
}

#===============================================================================
# ×××× Reading dialog values ×××× #
#===============================================================================

# flag 
proc html::ReadDialogflag {elem attr v ind etext} {
	upvar $v val $ind index
	global html::xhtml
	set attrtext ""
	if {[lindex $val $index]} {
		if {$html::xhtml} {
			set attrtext [html::WrapTag "[html::SetCase $attr]=[html::AddQuotes [html::SetCase $attr]]"]
		} else {
			set attrtext [html::WrapTag [html::SetCase $attr]]
		}
	}
	incr index
	return $attrtext
}

# url 
proc html::ReadDialogurl {elem attr v ind etext} {
	upvar $v val $ind index
	set attrtext ""
	set texturl [string trim [lindex $val $index]]
	set menuurl [lindex $val [expr {$index + 1}]]
	if {[string length $texturl]} {		
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes [quote::UrlExceptAnchor $texturl]]"]
		html::AddToCache URLs $texturl
	} elseif {$menuurl != " "} {
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes [quote::UrlExceptAnchor $menuurl]]"] 
	}
	incr index 3
	return $attrtext
}

# color 
proc html::ReadDialogcolor {elem attr v ind etext} {
	upvar $v val $ind index
	global html::userColors html::ColorName
	set attrtext ""
	set colortxt [lindex $val $index]
	set colorval [lindex $val [expr {$index + 1}]]
	if {[string length $colortxt]} {
		set col [html::CheckColorNumber $colortxt]
		if {$col == 0} {
			lappend errtext "$attr: $colortxt is not a valid color number."
		} else {	
			set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $col]"]
		}
	} elseif {$colorval != " "} {
		# Users own color?
		if {[info exists html::userColors($colorval)]} {
			set colornum [set html::userColors($colorval)]
		}
		# Predefined color?
		if {[info exists html::ColorName($colorval)]} {
			set colornum [set html::ColorName($colorval)]
		}
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $colornum]"]
	}
	incr index 3
	return $attrtext
}

# frametarget 
proc html::ReadDialogframetarget {elem attr v ind etext} {
	upvar $v val $ind index
	set attrtext ""
	set textwin [string trim [lindex $val $index]]
	set menuwin [lindex $val [expr {$index + 1}]]
	if {[string length $textwin]} {		
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $textwin]"]
		html::AddToCache Targets $textwin
	} elseif {$menuwin != " "} {
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $menuwin]"]
	}
	incr index 2
	return $attrtext
}

# choices 
proc html::ReadDialogchoices {elem attr v ind etext} {
	upvar $v val $ind index
	set attrtext ""
	if {[set anyval [string trim [lindex $val $index]]] != ""} {
		set attrtext [html::WrapTag "[html::SetCase $attr[html::AddQuotes $anyval]]"]
	}
	incr index
	return $attrtext
}

# length 
proc html::ReadDialoglength {elem attr v ind etext {multilength 0}} {
	upvar $v val $ind index $etext errtext
	set attrtext ""
	if {[set numval [string trim [lindex $val $index]]] != ""} {
		if {[set res [html::CheckAttrNumber $elem $attr $numval 1 $multilength]] == "1"} {		
			set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $numval]"]
		} else {
			lappend errtext "$attr: $res"
		}
	}
	incr index
	if {$elem == "IMG" && $attr == "WIDTH="} {incr index}
	return $attrtext
}

# integer
proc html::ReadDialoginteger {elem attr v ind etext} {
	upvar $v val $ind index $etext errtext
	set attrtext ""
	if {[set numval [string trim [lindex $val $index]]] != ""} {
		if {[set res [html::CheckAttrNumber $elem $attr $numval 0]] == "1"} {		
			set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $numval]"]
		} else {
			lappend errtext "$attr: $res"
		}
	}
	incr index
	return $attrtext
}

# other 
proc html::ReadDialogother {elem attr v ind etext} {
	upvar $v val $ind index
	set attrtext ""
	if {[set anyval [string trim [lindex $val $index]]] != ""} {
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $anyval]"]
	}
	incr index
	return $attrtext
}

# othernotrim
proc html::ReadDialogothernotrim {elem attr v ind etext} {
	upvar $v val $ind index
	set attrtext ""
	set anyval [lindex $val $index]
	if {$anyval != ""} {
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $anyval]"]
	}
	incr index
	return $attrtext
}

# fixed 
proc html::ReadDialogfixed {elem attr v ind etext} {
	return [html::WrapTag "[html::SetCase $attr][html::AddQuotes [html::GetAttrFixed $elem $attr]]"]
}

# id
proc html::ReadDialogid {elem attr v ind etext} {
	upvar $v val $ind index $etext errtext
	set attrtext ""
	if {[set idval [string trim [lindex $val $index]]] != ""} {
		if {[html::CheckId $idval]} {		
			set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $idval]"]
		} else {
			lappend errtext "$attr: Must be first a letter and then letters, digits, and '_' '-' ':' '.'"
		}
	}
	incr index
	return $attrtext
}

# ids
proc html::ReadDialogids {elem attr v ind etext} {
	upvar $v val $ind index $etext errtext
	set attrtext ""
	if {[set idval [string trim [lindex $val $index]]] != ""} {
		if {[html::CheckIds $idval]} {		
			set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $idval]"]
		} else {
			lappend errtext "$attr: Must be first a letter and then letters, digits, and '_' '-' ':' '.'"
		}
	}
	incr index
	return $attrtext
}

# anchor
proc html::ReadDialoganchor {elem attr v ind etext} {
	upvar $v val $ind index
	set attrtext ""
	set anyval [string trim [lindex $val $index]]
	if {$anyval != ""} {
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $anyval]"]
		html::AddToCache URLs "#$anyval"
	}
	incr index
	return $attrtext
}

# targetname
proc html::ReadDialogtargetname {elem attr v ind etext} {
	upvar $v val $ind index
	set attrtext ""
	set anyval [string trim [lindex $val $index]]
	if {$anyval != ""} {
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $anyval]"]
		html::AddToCache Targets $anyval
	}
	incr index
	return $attrtext
}

# contenttype 
proc html::ReadDialogcontenttype {elem attr v ind etext} {
	upvar $v val $ind index
	global HTMLmodeVars
	set attrtext ""
	set textwin [string trim [lindex $val $index]]
	set menuwin [lindex $val [expr {$index + 1}]]
	if {$textwin != ""} {
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $textwin]"]
		if {![lcontains HTMLmodeVars(contenttypes) [string tolower $textwin]]} {
			lappend HTMLmodeVars(contenttypes) [string tolower $textwin]
			prefs::modifiedModeVar contenttypes HTML
		}
	} elseif {$menuwin != " "} {
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $menuwin]"]
	}
	incr index 2
	return $attrtext
}

# contenttypes
proc html::ReadDialogcontenttypes {elem attr v ind etext {types contenttypes} {comma 1}} {
	upvar $v val $ind index
	global HTMLmodeVars
	set attrtext ""
	set menuwin [lindex $val $index]
	set textwin [string trim [lindex $val [expr {$index + 1}]]]
	set aval ""
	if {$menuwin != " "} {
		set aval $menuwin
	}
	if {$textwin != ""} {
		if {$comma && $aval != ""} {append aval ,}
		append aval " " $textwin
		if {$comma} {
			set tlist [split $textwin ,]
		} else {
			set tlist $textwin
		}
		foreach t $tlist {
			set t [string tolower [string trim $t]]
			if {![lcontains HTMLmodeVars($types) $t]} {
				lappend HTMLmodeVars($types) $t
				prefs::modifiedModeVar $types HTML
			}
		}
	}
	if {$aval != ""} {
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes [string trim $aval]]"]
	}
	incr index 3
	return $attrtext
}

# eventhandler 
proc html::ReadDialogeventhandler {elem attr v ind etext} {
	upvar $v val $ind index
	set attrtext ""
	set anyval [string trim [lindex $val $index]]
	if {$anyval != ""} {
		set attrtext [html::WrapTag "$attr[html::AddQuotes $anyval]"]
	}
	incr index
	return $attrtext
}

# linktypes 
proc html::ReadDialoglinktypes {elem attr v ind etext} {
	upvar $v val $ind index
	return [html::ReadDialogcontenttypes $elem $attr val index errtext linktypes 0]
}

# multilength 
proc html::ReadDialogmultilength {elem attr v ind etext} {
	upvar $v val $ind index $etext errtext
	return [html::ReadDialoglength $elem $attr val index errtext 1]
}


# multilengths 
proc html::ReadDialogmultilengths {elem attr v ind etext} {
	upvar $v val $ind index $etext errtext
	return [html::ReadDialogcoords $elem $attr val index errtext 1]
}

# languagecode 
proc html::ReadDialoglanguagecode {elem attr v ind etext} {
	upvar $v val $ind index $etext errtext
	return [html::ReadDialogother $elem $attr val index errtext]
	# to be modified
}

# charset 
proc html::ReadDialogcharset {elem attr v ind etext} {
	upvar $v val $ind index
	return [html::ReadDialogother $elem $attr val index errtext]
	# to be modified
}

# charsets 
proc html::ReadDialogcharsets {elem attr v ind etext} {
	upvar $v val $ind index
	return [html::ReadDialogother $elem $attr val index errtext]
	# to be modified
}

# coords 
proc html::ReadDialogcoords {elem attr v ind etext {multilength 0}} {
	upvar $v val $ind index $etext errtext
	set attrtext ""
	if {[set numval [string trim [lindex $val $index]]] != ""} {
		set atxt ""
		set err 0
		foreach l [split $numval ,] {
			set l [string trim $l]
			if {[set res [html::CheckAttrNumber $elem $attr $l 1 $multilength]] == "1"} {
				append atxt ",$l"
			} else {
				lappend errtext "$attr: $res"
				set err 1
				break
			}
		}
		if {!$err} {
			set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes [string trim $atxt ,]]"]
		}
	}
	incr index
	return $attrtext
}

# oltype 
proc html::ReadDialogoltype {elem attr v ind etext} {
	upvar $v val $ind index
	set attrtext ""
	if {[set choiceval [lindex $val $index]] != " "} {		
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $choiceval]"]
	}
	incr index
	return $attrtext
}

# datetime 
proc html::ReadDialogdatetime {elem attr v ind etext} {
	upvar $v val $ind index $etext errtext
	set attrtext ""
	if {[lindex $val [expr {$index + 7}]]} {
		set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes [mtime [now] iso]]"]
	} elseif {[join [set date [lrange $val $index [expr {$index + 6}]]] ""] != ""} {
		if {![catch {html::CheckDateTime $date} res]} {
			set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $res]"]
		} else {
			lappend errtext "$attr: $res"
		}
	}
	incr index 8
	return $attrtext
}

# character 
proc html::ReadDialogcharacter {elem attr v ind etext} {
	upvar $v val $ind index $etext errtext
	set attrtext ""
	if {[set char [string trim [lindex $val $index]]] != ""} {
		if {[string length $char] == 1} {		
			set attrtext [html::WrapTag "[html::SetCase $attr][html::AddQuotes $char]"]
		} else {
			lappend errtext "$attr: Only a single character is allowed."
		}
	}
	incr index
	return $attrtext
}

# mediadesc 
proc html::ReadDialogmediadesc {elem attr v ind etext} {
	upvar $v val $ind index
	return [html::ReadDialogcontenttypes $elem $attr val index errtext mediatypes]
}

#===============================================================================
# ×××× Checking attr values ×××× #
#===============================================================================

# Check if a color number is a valid number, or one of the predefined names.
# Returns 0 if not and the color number if it is.
proc html::CheckColorNumber {color} {
	global html::ColorName html::userColors
	set color [string tolower $color]
	if {[info exists html::ColorName($color)]} {return [set html::ColorName($color)]}
	if {[info exists html::userColors($color)]} {return [set html::userColors($color)]}
	if {[string index $color 0] != "#"} {
		set color "#${color}"
	}
	set color [string toupper $color]
	if {[string length $color] != 7 || ![regexp {^#[0-9A-F]+$} $color]} {
		return 0
	} else {
		return $color
	}	
}

# Check if a input is a valid number for the element attribute.
# Returns 1 if it is, otherwise returns an error message.
proc html::CheckAttrNumber {item attr number procent {multilength 0}} {
	regexp {^([-i0-9]+):([-i0-9]+)} [html::GetAttrRange $item $attr] "" minvalue maxvalue
	if {$minvalue == "-i"} {
		set errtext "An integer"
	} elseif {$maxvalue == "i"} {
		set errtext "A number $minvalue or greater"
	} else {
		set errtext "A number in the range $minvalue to $maxvalue"
	}
	if {$item == "FONT"} {append errtext " or -6 to +6"}
	if {$procent} {append errtext " or percentage"}
	if {$multilength} {append errtext " or a relative length"}
	append errtext  " expected." 
	# Is percent allowed?
	if {[string index $number [expr {[string length $number] - 1}]] == "%" } {
		set number [string range $number 0 [expr {[string length $number] - 2}]]
		if {!$procent} {return $errtext}
	}
	# Is multilength allowed?
	if {[string index $number [expr {[string length $number] - 1}]] == "*" } {
		if {$number == "*"} {set number "1*"}
		set number [string range $number 0 [expr {[string length $number] - 2}]]
		if {!$multilength} {return $errtext}
	}
	# FONT can take values -6 - +6. Special case.
	if {$item == "FONT" && [regexp {^(\+|-)[1-6]$} $number]} {return 1}
	# Is input a number?
	if {![regexp {^(\+|-)?[0-9]+$} $number]} {return $errtext}
	# Is input in the valid range?
	if {( $maxvalue != "i" && $number > $maxvalue ) || ( $minvalue != "-i" && $number < $minvalue ) } {
		return $errtext
	}	
	return 1 
}

proc html::CheckDateTime {date} {
	if {[string length [set d [lindex $date 0]]] != 4 || ![is::PositiveInteger $d]} {error "Year must be four digits."}
	if {![is::PositiveInteger [set x [lindex $date 1]]] || $x < 1 || $x > 12} {error "Incorrect month."}
	if {$x < 10} {set x "0[expr $x]"}
	append d "-$x"
	if {![is::PositiveInteger [set x [lindex $date 2]]] || $x < 1 || $x > 31} {error "Incorrect day."}
	if {$x < 10} {set x "0[expr $x]"}
	append d "-$x"
	if {![is::UnsignedInteger [set x [lindex $date 3]]] || $x < 0 || $x > 23} {error "Incorrect hours."}
	if {$x < 10} {set x "0[expr $x]"}
	append d "T$x"
	if {![is::UnsignedInteger [set x [lindex $date 4]]] || $x < 0 || $x > 59} {error "Incorrect minutes."}
	if {$x < 10} {set x "0[expr $x]"}
	append d ":$x"
	if {![is::UnsignedInteger [set x [lindex $date 5]]] || $x < 0 || $x > 59} {error "Incorrect seconds."}
	if {$x < 10} {set x "0[expr $x]"}
	append d ":$x"
	if {[set x [lindex $date 6]] != "Z" && ![regexp {^[-+][0-9][0-9]:[0-9][0-9]$} $x]} {error "Incorrect time zone designator."}
	append d $x
	return $d
}

proc html::CheckId {id} {
	return [regexp {^[A-Za-z][-A-Za-z0-9_:\.]*$} $id]
}

proc html::CheckIds {ids} {
	return [regexp {^[A-Za-z][-A-Za-z0-9_:\.]*([ \t\r\n]+[A-Za-z][-A-Za-z0-9_:\.]*)*$} $ids]
}

#===============================================================================
# ×××× Some extra tests of dialog input ×××× #
#===============================================================================

proc html::OneIsRequired {elem text cmd} {
	if {[string toupper $text] == "<$elem"} {  
		eval {$cmd "At least one of the attributes is required."}
		return 1
	}
	return 0
}

# CODE or OBJECT must be used for APPLET
proc html::APPLETtest {elem text cmd} {
	if {![regexp -nocase {code=} $text] && ![regexp -nocase {object=} $text]} {
		eval {$cmd "At least one of the attributes CODE and OBJECT must be used."}
		return 1
	}
	return 0
}

proc html::FONTtest {elem text cmd} {
	return [html::OneIsRequired $elem $text $cmd]
}

proc html::BASEtest {elem text cmd} {
	if {[regexp -nocase {HREF=(\"[^\"]+\"|'[^']+')} $text "" href] && ![regexp "://" $href]} {
		eval {$cmd "The HREF URL must be absolute."}
		return 1
	}
	return [html::OneIsRequired $elem $text $cmd]
}

proc html::SPANtest {elem text cmd} {
	return [html::OneIsRequired $elem $text $cmd]
}

# Some checks for SPACER.
proc html::SPACERtest {elem text cmd} {
	set horver [regexp -nocase {type=\"(horizontal|vertical)\"} $text]
	set wh [regexp -nocase {width=|height=} $text]
	set sz [regexp -nocase {size=} $text]
	set al [regexp -nocase {align=} $text]
	set invalidInput 1
	if {$horver && ($wh || $al)} {
		eval {$cmd "WIDTH, HEIGHT and ALIGN should only be used when TYPE=BLOCK."}
	} elseif {!$horver && $sz} {
		eval {$cmd "SIZE should only be used when TYPE=HORIZONTAL or VERTICAL."}
	} elseif {$horver && !$sz} {
		eval {$cmd "SIZE is required when TYPE=HORIZONTAL or VERTICAL."}
	} elseif {!$horver && !$wh} {
		eval {$cmd "WIDTH or HEIGHT is required when TYPE=BLOCK."}
	} else {
		set invalidInput 0
	}
	return $invalidInput
}

# For AREA, either HREF or NOHREF must be used, but not both.
proc html::AREAtest {elem text cmd} {
	set hasHref [regexp -nocase {[^o]href=} $text]
	set hasNohref [regexp -nocase {nohref} $text]
	set hasCoords [regexp -nocase {coords=} $text]
	set shapeDefault [regexp -nocase {shape=\"default\"} $text]
	set invalidInput 0
	if {($hasHref && $hasNohref) || (!$hasHref && !$hasNohref)} {
		eval {$cmd "One of the attributes HREF and NOHREF must be used, but not both."}
		set invalidInput 1
	} elseif {!$hasCoords && !$shapeDefault} {
		eval {$cmd "COORDS= is required if SHAPE­DEFAULT"}
		set invalidInput 1
	}
	return $invalidInput
}
