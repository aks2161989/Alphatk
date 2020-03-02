## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlCustom.tcl"
 #                                    created: 96-06-29 21.36.50 
 #                                last update: 03/21/2006 {03:08:18 PM} 
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
# This file contains proc for handling custom HTML elements.
#===============================================================================

proc htmlCustom.tcl {} {}

set html::AttributeTypesDefs {
	flag url color frametarget choices length integer other contenttype 
	contenttypes eventhandler linktypes multilength multilengths
	languagecode charset charsets coords datetime
	character mediadesc
}
set html::AttributeTypesShow {
	Flag URL Color "Frame target" Choices Length Integer Other "Content type"
	"Content types" "Event handler" "Link types" "Multi length" "Multi lengths"
	"Language code" "Character set" "Character sets" Lengths "Date and time"
	Character "Media descriptors"
}

proc html::NewElement {} {
	global html::ElemAttrOptional
	set invalidInput 1
	set values {"" 1 1 0 0}
	while {$invalidInput} {
		set box "-T [list [list New HTML element]] "
		append box "-t {New element:} 10 10 100 25 -e [list [lindex $values 0]] 110 10 250 25 \
		-c {Has closing tag} [lindex $values 1] 10 40 150 55 \
		-t {Element type} 10 80 100 95 -r Normal [lindex $values 2] 10 100 100 115 \
		-r {INPUT element with TYPE given above} [lindex $values 3] 10 120 300 135 \
		-r {Plug-in using EMBED} [lindex $values 4] 10 140 200 155 \
		-b OK 260 170 325 190 -b Cancel 175 170 240 190"
		set values [eval [concat dialog -w 340 -h 200 $box]]
		if {[lindex $values 6]} {return}
		set element [string toupper [string trim [lindex $values 0]]]
		set closingTag [lindex $values 1]
		if {[lindex $values 2]} {
			set elemType normal
		} elseif {[lindex $values 3]} {
			set elemType input
		} else {
			set elemType plugin
		}
		# Check that input is ok.
		if {$element == ""} {
			alertnote "You must specify the element."
		} elseif {[info exists html::ElemAttrOptional($element)]} {
			alertnote "The element $element is already defined."
		} elseif {![regexp {^[a-zA-Z_][-_.a-zA-Z0-9]*$} $element]} {
			alertnote "Invalid characters in element name. For example, it may not contain spaces."
		} else {
			set invalidInput 0
		}
	}

	if {$elemType == "input"} {set element "INPUT TYPE=$element"}
	# Check if there is already a window.
	if {![catch {bringToFront "* Defining element $element *"}]} {return}
	# Get a key binding.
	if {[catch {dialog::getAKey $element ""} keyStr]} {return}
	# Get the layout.
	if {!$closingTag} {
		set layout [html::SetLayoutEmpty {0 0} $element]
	} elseif {$elemType == "normal"} {
		set layout [html::SetLayoutClosing {1 0 0 0} $element]
	} else {
		# dummy for INPUT and plugins.
		set layout open00
	}
	
	set fid [open [temp::path HTML "NE $element"] w]
	puts $fid "\n$layout\nCustom\n$elemType\n$keyStr\nvisible"
	if {$elemType == "plugin"} {
		set out ""
		set req [html::GetRequired EMBED]
		set attrs [concat $req [html::GetOptional EMBED 1]]
		for {set i 0} {$i < [llength $attrs]} {incr i} {
			set a [lindex $attrs $i]
			append out $a " " [set t [html::GetAttrType EMBED $a]] " " [expr {$i < [llength $req]}]
			if {$t == "length" || $t == "integer" || $t == "multilength" || $t == "multilengths" || $t == "coords"} {
				append out " " [html::GetAttrRange EMBED $a]
			}
			if {$t == "choices"} {
				append out " " [html::GetAttrChoices EMBED $a]
			}
			append out "\n"
		}
		puts -nonewline $fid $out
	}
	close $fid
	
	# Get the attributes	
	html::ChangeAddition $element

}

proc html::EditElement {} {
	global html::ElemAttrOptional html::PrefsFolder
	if {[catch {listpick -p "Select element to edit." \
	  [lsort [array names html::ElemAttrOptional]]} element] || $element == ""} {return}
	if {![file exists [temp::path HTML "NE $element"]] && [file exists [file join ${html::PrefsFolder} "New elements" $element]]} {
		file copy [file join ${html::PrefsFolder} "New elements" $element] \
		  [temp::path HTML "NE $element"]
	}
	html::ChangeAddition $element
}

proc html::ChangeAddition {elem} {
	global html::PrefsFolder screenHeight html::AttributeTypesDefs html::_preDefinedRequired
	global html::AttributeTypesShow html::_tmpRequired html::_tmpOptional html::_tmpChoices
	global html::_tmpRange html::_tmpType html::_preDefinedOptional
	global html::_tmpExtraChoices
	
	# Check if there is already a window.
	if {![catch {bringToFront "* Defining element $elem *"}]} {return}
	set html::_tmpOptional($elem) ""
	set html::_tmpRequired($elem) ""
	foreach var {html::_tmpExtraChoices html::_tmpRange html::_tmpChoices html::_tmpType} {
		foreach arr [array names $var] {
			if {[string match "$elem%*" $arr]} {unset [set var]($arr)}
		}
	}
	new -n "* Defining element $elem *" -m HTMx -g 400 40 270 [expr {$screenHeight - 62}] -shell 1
	set isNew [file exists [temp::path HTML "NE $elem"]]
	set txt "N = new attribute\ndelete or backspace = delete attribute\nreturn or enter = edit attribute\n"
	append txt "Close window to save.\nPress shift key while closing to cancel.\n\n"
	if {$isNew} {
		set fid [open [temp::path HTML "NE $elem"] r]
		set content [read -nonewline $fid]
		close $fid
		foreach l [lrange [split $content "\n"] 6 end] {
			append txt [eval html::AdditionText $l]
		}
		insertText $txt
	} else {
		if {[file exists [file join ${html::PrefsFolder} "Modified elements" $elem]]} {
			set fid [open [file join ${html::PrefsFolder} "Modified elements" $elem] r]
			set content [read -nonewline $fid]
			close $fid
			foreach l [lrange [split $content "\n"] 1 end] {
				if {[string index $l 0] == "#"} {
					set html::_tmpExtraChoices($elem%[string trim [lindex $l 0] #]) [lrange $l 1 end]
				} else {
					append txt [eval html::AdditionText $l]
				}
			}
		}
		set html::_preDefinedRequired($elem) [lremove [html::GetRequired $elem] [set html::_tmpRequired($elem)]]
		set html::_preDefinedOptional($elem) [lremove [html::GetOptional $elem 1] [set html::_tmpOptional($elem)]]
		set attrs [concat [set html::_preDefinedRequired($elem)] [set html::_preDefinedOptional($elem)]]
		for {set i 0} {$i < [llength $attrs]} {incr i} {
			set a [lindex $attrs $i]
			set type [html::GetAttrType $elem $a]
			if {$type == "length" || $type == "integer" || $type == "multilength" || $type == "multilengths" || $type == "coords"} {
				append txt "¥" [html::AdditionText $a $type [expr {$i < [llength [set html::_preDefinedRequired($elem)]]}] [html::GetAttrRange $elem $a]]
			} elseif {$type == "choices"} {
				set ch ""
				foreach c [html::GetAttrChoices $elem $a] {
					if {[lcontains html::_tmpExtraChoices($elem%$a) $c]} {
						lappend ch $c
					} else {
						lappend ch "¥$c"
					}
				}
				append txt "¥" [eval html::AdditionText $a $type [expr {$i < [llength [set html::_preDefinedRequired($elem)]]}] $ch]
			} else {
				append txt "¥" [html::AdditionText $a $type [expr {$i < [llength [set html::_preDefinedRequired($elem)]]}]]
			}
		}
		insertText $txt
	}
	beginningOfBuffer
	selectText [html::customTopLine] [nextLineStart [html::customTopLine]]
	insertColorEscape [minPos] 1
	insertColorEscape [pos::prevLineStart [html::customTopLine]] 0
	refresh
	setWinInfo read-only 1
}

proc html::AdditionText {args} {
	global html::AttributeTypesDefs
	global html::AttributeTypesShow html::_tmpRequired html::_tmpOptional html::_tmpChoices
	global html::_tmpRange html::_tmpType

	set elem [html::FindElemInWindow]
	set optreq {"" " required"}
	set showtype [lindex ${html::AttributeTypesShow} [lsearch -exact ${html::AttributeTypesDefs} [set type [lindex $args 1]]]]
	if {$showtype == ""} {set showtype $type}
	append txt [string trim [lindex $args 0] =] " " $showtype [lindex $optreq [lindex $args 2]] "\n"
	if {[lindex $args 2]} {
		lappend html::_tmpRequired($elem) [lindex $args 0]
	} else {
		lappend html::_tmpOptional($elem) [lindex $args 0]
	}
	set html::_tmpType($elem%[lindex $args 0]) [lindex $args 1]
	if {$type == "length" || $type == "integer" || $type == "multilength" || $type == "multilengths" || $type == "coords"} {
		regexp {([-i0-9]+):([-i0-9]+)} [lindex $args 3] "" min max
		append txt "    Minimum value: "
		if {$min == "-i"} {
			append txt "Not specified\n"
		} else {
			append txt "$min\n"
		}
		append txt "    Maximum value: "
		if {$max == "i"} {
			append txt "Not specified\n"
		} else {
			append txt "$max\n"
		}
		set html::_tmpRange($elem%[lindex $args 0]) [lindex $args 3]
	}
	if {$type == "choices"} {
		foreach c [split [lrange $args 3 end]] {
			append txt "    $c\n"
			lappend html::_tmpChoices($elem%[lindex $args 0]) $c
		}
	}
	return $txt
}

proc html::NewAttribute {{thisattr ""} {pos ""}} {
	global html::AttributeTypesShow html::_tmpRequired html::_tmpOptional
	global html::AttributeTypesDefs html::_tmpType html::_tmpRange html::_tmpChoices
	
	set elem [html::FindElemInWindow]
	set defattr $thisattr
	if {$thisattr == ""} {
		set values {0 0 {} Other 0}
	} else {
		set deftype [set html::_tmpType($elem%$thisattr)]
		set values [list 0 0 [string trim $thisattr =] \
		  [lindex ${html::AttributeTypesShow} [lsearch -exact  ${html::AttributeTypesDefs} [set html::_tmpType($elem%$thisattr)]]] \
		  [lcontains html::_tmpRequired($elem) $thisattr]]
	}
	set invalidInput 1
	while {$invalidInput} {
		set box "[dialog::title [list Attribute for $elem] 250] \
		  -t Name: 10 20 60 35 \
		  -e [list [lindex $values 2]] 65 20 205 35 \
		  -t Type: 220 20 255 35 \
		  -m [list [concat [list [lindex $values 3]] ${html::AttributeTypesShow}]] \
		  260 20 480 40 \
		  -c Required [lindex $values 4] 10 55 130 70"
		set values [eval [concat dialog -w 490 -h 85 \
		  -b OK 410 55 475 75 \
		  -b Cancel 325 55 390 75 $box]]
		if {[lindex $values 1]} {
			error "Cancel"
		} elseif {[lindex $values 0]} {
			set thisattr [string trim [lindex $values 2]]
			set thistype [lindex $values 3]
			if {$thistype != "Event handler"} {set thisattr [string toupper $thisattr]}
			if {$thistype != "Flag"} {append thisattr =}
			set required [lindex $values 4]
			if {$thisattr == ""} {
				alertnote "You must specify the attribute name."
			} elseif {![regexp {^[a-zA-Z_][-_.a-zA-Z0-9]*=?$} $thisattr]} {
				alertnote "Invalid characters in attribute. For example, it may not contain spaces."
			} elseif {$thisattr != $defattr && [lsearch -exact [concat [set html::_tmpOptional($elem)] [set html::_tmpRequired($elem)]] $thisattr] >= 0} {
				alertnote "$elem already has an attribute [string trim $thisattr =]."
			} else {
				set invalidInput 0
				set thistype [lindex ${html::AttributeTypesDefs} [lsearch -exact ${html::AttributeTypesShow} $thistype]]
			}
		}
	}
	
	set rangechoices ""
	if {$thistype == "length" || $thistype == "integer" || $thistype == "multilength" || $thistype == "multilengths" || $thistype == "coords"} {
		if {$defattr != "" && $thistype == $deftype} {
			regexp {([-i0-9]+):([-i0-9]+)} [set html::_tmpRange($elem%$defattr)] "" min max
			if {![regexp {^[0-9]+$} $min]} {set min ""}
			if {![regexp {^[0-9]+$} $max]} {set max ""}
			set rangechoices [html::NewRange $thisattr $min $max]
		} else {
			set rangechoices [html::NewRange $thisattr]
		}
	}
	
	if {$thistype == "choices"} {
		if {$defattr != "" && $thistype == $deftype} {
			set rangechoices [html::NewChoices $thisattr [set html::_tmpChoices($elem%$defattr)]]
		} else {
			set rangechoices [html::NewChoices $thisattr]
		}
	}
	
	if {$pos != ""} {
		html::DeleteAttributes $pos
	}
	set txt [eval html::AdditionText $thisattr $thistype $required $rangechoices]
	if {$pos != ""} {
		goto $pos
	} elseif {![catch {search -s "¥" [minPos]} res]} {
		goto [lindex $res 0]
	} else {
		goto [maxPos]
	}
	setWinInfo read-only 0
	insertText $txt
	setWinInfo read-only 1
}

proc html::NewRange {attr {min ""} {max ""}} {
	set values [list 0 0 $min $max]
	while {1} {
		set box "[dialog::title [list Range for [string trim $attr =]] 290] -t {Minvalue:} 10 40 100 55 \
		  -e [list [lindex $values 2]] 110 40 130 55 -t {Maxvalue:} 150 40 240 55 \
		  -e [list [lindex $values 3]] 250 40 270 55"
		set values [eval [concat dialog -w 300 -h 120 \
		  -b OK 220 90 285 110 -b Cancel 135 90 200 110 $box]]
		set min [string trim [lindex $values 2]]
		set max [string trim [lindex $values 3]]
		if {[lindex $values 1]} {
			error "Cancel"
		} elseif {[lindex $values 0]} {
			if {$min != "" && ![html::IsInteger $min]} {
				alertnote "Not a valid number for minimum value."
			} elseif {$max != "" && ![html::IsInteger $max]} {
				alertnote "Not a valid number for maximum value."
			} elseif {$min != "" && $max != "" && $max < $min} {
				alertnote "Maxvalue is smaller than minvalue."
			} else {
				break
			}
		}
	}
	if {$min == ""} {
		set range "-i:"
	} else {
		set range "$min:"
	}
	if {$max != ""} {
		append range "$max"
	} else {
		append range "i"
	}
	return $range
}

proc html::NewChoices {attr {choices ""}} {
	set i 0
	set done 0
	while {!$done} {
		incr i
		set values {0 0 {}}
		set invalidInput 1
		while {$invalidInput} {
			set box "-T [list [list Choices for [string trimright $attr =]]] "
			append box "-t {Choice $i for [string trimright $attr =]} 10 10 210 25 \
			-e [list [lindex $values 2]] 10 40 200 55"
			if {$i > 1 || [llength $choices]} {append box " -b {No more choices} 220 70 350 90"}
			if {$i > 1} {append box " -b {Remove last} 220 100 350 120"}
			set wi 10
			set ht 90
			if {[llength $choices]} {
				append box " -t {All choices} 10 70 200 85"
				foreach ch $choices {
					append box " -t [string trim $ch ¥] $wi $ht [expr {$wi + 95}] [expr {$ht + 15}]"
					incr wi 100
					if {$wi == 210} {
						set wi 10
						incr ht 20
					}
				}
			}
			if {$wi == 110} {incr ht 20}
			if {$ht < 130} {set ht 130}
			set values [eval [concat dialog -w 360 -h $ht \
			-b OK 220 10 285 30 -b Cancel 220 40 285 60 \
			$box]]
			if {[lindex $values 1]} {
				error "Cancel"
			} elseif {($i > 1 || [llength $choices]) && [lindex $values 3] } {
				set done 1
				break
			} elseif {$i > 1 && [lindex $values 4]} {
				incr i -1
				set choices [lrange $choices 0 [expr {[llength $choices] - 2}]]
			} elseif {[lindex $values 0]} {
				set thischoice [string toupper [string trim [lindex $values 2]]]
				if {$thischoice != "" && ![regexp {^[a-zA-Z_][-_.a-zA-Z0-9]*=?$} $thischoice]} {
					alertnote "Invalid characters in choice.  For example, it may not contain spaces."
				} elseif {$thischoice != ""} {
					if {[lcontains choices $thischoice]} {
						alertnote "$attr already has a choice $thischoice."
					} else {
						set invalidInput 0
					}
				}
			}
		}
		if {!$done} {lappend choices $thischoice}
	}
	return $choices
}

proc html::HTMxStartPos {s e} {
	upvar $s spos $e epos
	set start [pos::fromRowChar 7 0]
	set spos [lineStart [getPos]]
	if {[pos::compare $spos < $start]} {set spos $start}
	set epos [selEnd]
	if {[pos::compare $epos < $spos]} {error "cancel"}
	if {[lookAt [pos::math $epos - 1]] != "\r"} {set epos [nextLineStart $epos]}
}

proc html::EditAttribute {} {
	global html::_tmpChoices html::_tmpExtraChoices
	set elem [html::FindElemInWindow]
	html::HTMxStartPos spos epos
	while {[lookAt $spos] == " "} {set spos [pos::prevLineStart $spos]}
	set txt [getText $spos [nextLineStart $spos]]
	set attr [lindex $txt 0]
	if {[set type [lindex $txt 1]] != "Flag"} {append attr "="}
	if {[lookAt $spos] == "¥"} {
		if {$type != "Choices"} {return}
		set ch [html::NewChoices [set attr [string trim $attr "¥"]] [set html::_tmpChoices($elem%$attr)]]
		if {[set newchoices [lrange $ch [llength [set html::_tmpChoices($elem%$attr)]] end]] == ""} {return}
		append html::_tmpChoices($elem%$attr) " " $newchoices
		append html::_tmpExtraChoices($elem%$attr) " " $newchoices
		set spos [nextLineStart $spos]
		while {[lookAt $spos] == " "} {set spos [nextLineStart $spos]}
		goto $spos
		set txt ""
		foreach c $newchoices {
			append txt "    $c\n"
		}
		setWinInfo read-only 0
		insertText $txt
		setWinInfo read-only 1
	} else {
		html::NewAttribute $attr $spos
	}
}

proc html::DeleteAttributes {{spos ""}} {
	global html::_tmpOptional html::_tmpRequired html::_tmpRange
	global html::_tmpType html::_tmpChoices html::_tmpExtraChoices
	
	set elem [html::FindElemInWindow]
	if {$spos == ""} {
		html::HTMxStartPos spos epos
	} else {
		set epos [nextLineStart $spos]
	}
	while {[lookAt $spos] == " " && [regexp {:} [getText $spos [pos::nextLineStart $spos]]]} {set spos [pos::prevLineStart $spos]}
	set s0pos $spos
	set delchoices 0
	while {[lookAt $spos] == " " && [pos::compare $spos < $epos]} {
		set delchoices 1
		set extra 0
		set s1 $spos
		while {[lookAt $s1] == " "} {set s1 [prevLineStart $s1]}
		set attr [lindex [getText $s1 [pos::nextLineStart $s1]] 0]
		if {[string index $attr 0] == "¥"} {
			set extra 1
			set attr [string trim $attr ¥]
		}
		set choice [lindex [getText $spos [nextLineStart $spos]] 0]
		if {[string index $choice 0] != "¥"} {
			set html::_tmpChoices($elem%$attr=) [lremove [set html::_tmpChoices($elem%$attr=)] $choice]
			if {$extra} {set html::_tmpExtraChoices($elem%$attr=) [lremove [set html::_tmpExtraChoices($elem%$attr=)] $choice]}
		} else {
			set s0pos [nextLineStart $spos]
		}
		set spos [nextLineStart $spos]
	}
	if {$delchoices && ![llength [set html::_tmpChoices($elem%$attr=)]]} {
		set spos [pos::prevLineStart $spos]
		while {[lookAt $spos] == " "} {set spos [pos::prevLineStart $spos]}
		set s0pos $spos
	}
	while {[lookAt $spos] != "¥" && [pos::compare $spos < $epos]} {
		set txt [getText $spos [nextLineStart $spos]]
		set attr [lindex $txt 0]
		if {[set type [lindex $txt 1]] != "Flag"} {append attr "="}
		set html::_tmpRequired($elem) [lremove [set html::_tmpRequired($elem)] $attr]
		set html::_tmpOptional($elem) [lremove [set html::_tmpOptional($elem)] $attr]
		catch {unset html::_tmpRange($elem%$attr)}
		catch {unset html::_tmpChoices($elem%$attr)}
		catch {unset html::_tmpType($elem%$attr)}
		set spos [nextLineStart $spos]
		while {[lookAt $spos] == " "} {set spos [nextLineStart $spos]}
	}
	setWinInfo read-only 0
	deleteText $s0pos $spos
	setWinInfo read-only 1
}

proc html::HTMxCloseHook {name} {
	global html::_tmpRequired html::_tmpOptional html::_tmpChoices HTMLmodeVars CSSmodeVars
	global html::_tmpRange html::_tmpType html::PrefsFolder htmlMenuKey htmlVersion
	global html::ElemAttrRequired html::ElemAttrOptional html::AttrChoices html::AttrRange
	global html::ElemLayout html::AttrType html::_preDefinedRequired
	global html::_preDefinedOptional html::_tmpExtraChoices html::Plugins cssModeIsLoaded
	
	regexp {\* Defining element (.+) +\*$} $name "" elem
	set isNew [file exists [temp::path HTML "NE $elem"]]
	if {[key::shiftPressed]} {
		if {$isNew} {file delete [temp::path HTML "NE $elem"]}
		return
	}
	if {$isNew} {
		set fid [open [temp::path HTML "NE $elem"] r]
		gets $fid
		set out "$htmlVersion\n[set layout [gets $fid]]\n[set custmenu [gets $fid]]\n[set elemType [gets $fid]]\n[set key [gets $fid]]\n[set visibility [gets $fid]]\n"
		close $fid
		file delete [temp::path HTML "NE $elem"]
		set html::ElemAttrRequired($elem) ""
		set html::ElemAttrOptional($elem) ""
		ensureset html::ElemLayout($elem) $layout
		if {$elemType == "plugin"} {
			set html::Plugins [lunique [concat ${html::Plugins} $elem]]
		}
		html::ReadMenuKeys
		set melem $elem
		regexp "INPUT TYPE=(.*)" $elem "" melem
		set defCSSkey 0
		if {![info exists htmlMenuKey(Custom/[set me [string index $melem 0][string tolower [string range $melem 1 end]]])]} {
			set htmlMenuKey(Custom/$me) $key
			set defCSSkey 1
		}
		html::WriteMenuKeys
	} else {
		set out "$htmlVersion\n"
		set html::ElemAttrRequired($elem) [set html::_preDefinedRequired($elem)]
		set html::ElemAttrOptional($elem) [set html::_preDefinedOptional($elem)]
	}
	
	set attrs [concat [set html::_tmpRequired($elem)] [set html::_tmpOptional($elem)]]
	set numreq [llength [set html::_tmpRequired($elem)]]
	if {!$isNew} {
		set attrs [lremove $attrs [concat [set html::_preDefinedRequired($elem)] [set html::_preDefinedOptional($elem)]]]
		incr numreq [expr {-[llength [set html::_preDefinedRequired($elem)]]}]
	}
	
	for {set i 0} {$i < [llength $attrs]} {incr i} {
		set a [lindex $attrs $i]
		append out $a " " [set t [set html::_tmpType($elem%$a)]] " " [expr {$i < $numreq}]
		set html::AttrType($elem%$a) $t
		if {$t == "eventhandler"} {set html::AttrType($elem%[string toupper $a]) $t}
		if {$i < $numreq} {
			lappend html::ElemAttrRequired($elem) $a
		} else {
			lappend html::ElemAttrOptional($elem) $a
		}
		if {$t == "length" || $t == "integer" || $t == "multilength" || $t == "multilengths" || $t == "coords"} {
			append out " " [set html::_tmpRange($elem%$a)]
			set html::AttrRange($elem%$a) [set html::_tmpRange($elem%$a)]
		}
		if {$t == "choices"} {
			append out " " [set html::_tmpChoices($elem%$a)]
			set html::AttrChoices($elem%$a) [set html::_tmpChoices($elem%$a)]
		}
		append out "\n"
	}
	foreach a [array names html::_tmpExtraChoices] {
		if {[string match "$elem%*" $a] && [llength [set html::_tmpExtraChoices($a)]]} {
			append out "#[string range $a [expr {[string length $elem] + 1}] end] " "[set html::_tmpExtraChoices($a)]\n"
			regsub -all "¥" [set html::_tmpChoices($a)] "" c
			set html::AttrChoices($a) $c
		}
	}
	
	if {$isNew} {
		file::ensureDirExists [file join ${html::PrefsFolder} "New elements"]
		set fid [open [file join ${html::PrefsFolder} "New elements" $elem] w]
	} elseif {$out != "$htmlVersion\n"} {
		file::ensureDirExists [file join ${html::PrefsFolder} "Modified elements"]
		set fid [open [file join ${html::PrefsFolder} "Modified elements" $elem] w]
	} else {
		if {[file exists [file join ${html::PrefsFolder} "Modified elements" $elem]]} {
			html::RemoveAdditions2 $elem
		}
		return
	}
	
	puts -nonewline $fid $out
	close $fid
	if {$isNew} {
		if {[llength [glob -dir [file join ${html::PrefsFolder} "New elements"] *]] == 1} {
			menu::buildSome htmlMenu
		} else {
			menu::buildSome Custom
		}
	}
	
	if {!$HTMLmodeVars(simpleColoring)} {
		if {$HTMLmodeVars(ColorImmediately)} {
			regModeKeywords -a -k $HTMLmodeVars(tagColor) HTML $elem
			regsub -all = $attrs "" attrs
		} else {
			regModeKeywords -a -k $HTMLmodeVars(tagColor) HTML [concat "<$elem" "/$elem"]
		}
		regModeKeywords -a -k $HTMLmodeVars(attributeColor) HTML $attrs
	}
	if {[info exists cssModeIsLoaded]} {
		regModeKeywords -a -k $CSSmodeVars(htmlColor) CSS $elem
	}
	html::EnableExtend
	html::DeleteCache "Additions cache"
	html::DeleteCache "Additions coloring cache"

	if {$isNew && $defCSSkey} {
		html::DeleteCache "CSS keybindings cache"
		set csselem $elem
		if {$elemType == "plugin"} {set csselem EMBED}
		if {[regexp "INPUT TYPE=(.*)" $elem]} {set csselem INPUT}
		if {[info exists cssModeIsLoaded]} {css::BindOneKey $key $csselem}
	}
	if {[llength [set html::_tmpOptional($elem)]]} {html::UseAttributes2 $elem}
}

proc html::RemoveAdditions {} {
	global html::PrefsFolder
	if {![html::AdditionsExists]} {return}
	foreach f [concat [glob -nocomplain -dir [file join ${html::PrefsFolder} "New elements"] *] \
	  [glob -nocomplain -dir [file join ${html::PrefsFolder} "Modified elements"] *]] {
		lappend elems [file tail $f]
	}
	if {[catch {listpick -p "Select element to remove additions from." [lsort $elems]} element] || \
	  $element == "" || [askyesno "Remove additions from $element?"] == "no"} {
		return
	}
	html::RemoveAdditions2 $element
	status::msg "Additions removed."
}
  
proc html::RemoveAdditions2 {element} {  
	global html::PrefsFolder html::ElemAttrOptional html::ElemAttrRequired html::AttrChoices 
	global html::AttrRange html::AttrType html::ElemLayout html::ElemAttrUsed html::ElemAttrHidden
	global htmlMenuKey cssModeIsLoaded html::Plugins
	set isNew [file exists [file join ${html::PrefsFolder} "New elements" $element]]
	if {$isNew} {
		foreach a [concat [html::GetRequired $element] [html::GetOptional $element 1]] {
			catch {unset html::AttrChoices($element%$a)}
			catch {unset html::AttrRange($element%$a)}
			catch {unset html::AttrType($element%$a)}
		}
		catch {unset html::ElemAttrRequired($element)}
		catch {unset html::ElemAttrOptional($element)}
		catch {unset html::ElemAttrUsed($element)}
		catch {unset html::ElemAttrHidden($element)}
		catch {unset html::ElemAttrOverride($element)}
		catch {unset html::ElemLayout($element)}
		prefs::removeArrayElement html::ElemAttrUsed $element
		prefs::removeArrayElement html::ElemAttrHidden $element
		prefs::removeArrayElement html::ElemAttrOverride $element
		prefs::removeArrayElement html::ElemLayout $element
		set html::Plugins [lremove ${html::Plugins} [list $element]]
		html::ReadMenuKeys
		set melem $element
		regexp "INPUT TYPE=(.*)" $element "" melem
		if {[catch {set htmlMenuKey(Custom/[string index $melem 0][string tolower [string range $melem 1 end]])} key]} {set key ""}
		catch {unset htmlMenuKey(Custom/[string index $melem 0][string tolower [string range $melem 1 end]])}
		html::WriteMenuKeys
		file delete [file join ${html::PrefsFolder} "New elements" $element]
		if {![llength [glob -nocomplain -dir [file join ${html::PrefsFolder} "New elements"] *]]} {
			menu::buildSome htmlMenu
		} else {
			menu::buildSome Custom
		}
	} else {
		set fid [open [file join ${html::PrefsFolder} "Modified elements" $element] r]
		set content [read -nonewline $fid]
		close $fid
		set reqs ""
		set opts ""
		foreach l [lrange [split $content "\n"] 1 end] {
			set a [lindex $l 0]
			if {[string index $a 0] == "#"} {
				set a [string trim $a #]
				set html::AttrChoices($element%$a) [lremove [set html::AttrChoices($element%$a)] [lrange $l 1 end]]
				continue
			}
			if {[lindex $l 2]} {
				lappend reqs $a
			} else {
				lappend opts $a
			}
			if {[info exists html::ElemAttrUsed($element)]} {set html::ElemAttrUsed($element) [lremove [set html::ElemAttrUsed($element)] [list $a]]}
			if {[info exists html::ElemAttrHidden($element)]} {set html::ElemAttrHidden($element) [lremove [set html::ElemAttrHidden($element)] [list $a]]}
			catch {unset html::AttrChoices($element%$a)}
			catch {unset html::AttrRange($element%$a)}
			catch {unset html::AttrType($element%$a)}
		}
		if {[info exists html::ElemAttrRequired($element)]} {
			set html::ElemAttrRequired($element) [lremove [set html::ElemAttrRequired($element)] $reqs]
		}
		set html::ElemAttrOptional($element) [lremove [set html::ElemAttrOptional($element)] $opts]
		if {[info exists html::ElemAttrUsed($element)]} {prefs::modifiedArrayElement $element html::ElemAttrUsed}
		if {[info exists html::ElemAttrHidden($element)]} {prefs::modifiedArrayElement $element html::ElemAttrHidden}
		file delete [file join ${html::PrefsFolder} "Modified elements" $element]
	}
	
	html::EnableExtend
	html::DeleteCache "Additions cache"
	html::DeleteCache "Additions coloring cache"
	if {$isNew} {
		html::DeleteCache "CSS keybindings cache"
		if {[info exists cssModeIsLoaded]} {css::BindOneKey $key $element un}
	}
}

proc html::CreateAdditionCaches {} {
	global html::PrefsFolder
	
	set files [concat [set newelems [glob -nocomplain -dir [file join ${html::PrefsFolder} "New elements"] *]] \
	  [glob -nocomplain -dir [file join ${html::PrefsFolder} "Modified elements"] *]]
	
	set txt ""
	set ctxt ""
	for {set i 0} {$i < [llength $files]} {incr i} {
		set f [lindex $files $i]
		set elem [file tail $f]
		set isNew [expr {$i < [llength $newelems]}]
		set fid [open $f r]
		set content [split [read -nonewline $fid] "\n"]
		close $fid
		if {$isNew} {
			append txt "set \"html::ElemAttrOptional($elem)\" {}\n"
			append txt "ensureset \"html::ElemLayout($elem)\" [lindex $content 1]\n"
			if {[lindex $content 3] == "plugin"} {append txt "lappend html::Plugins [list $elem]\n"}
			if {[lindex $content 3] != "plugin" && [lindex $content 3] != "input"} {append ctxt "lappend allHTMLwords $elem\n"}
			set content [lrange $content 5 end]
		}
		foreach l [lrange $content 1 end] {
			set attr [lindex $l 0]
			if {[string index $attr 0] == "#"} {
				set attr [string trim $attr #]
				append txt "set \"html::AttrChoices($elem%$attr)\" \{[html::GetAttrChoices $elem $attr]\}\n"
				append txt "lappend \"html::AttrChoices($elem%$attr)\" [lrange $l 1 end]\n"
				continue
			}
			if {[lindex $l 2]} {
				append txt "lappend \"html::ElemAttrRequired($elem)\" [lindex $l 0]\n"
			} else {
				append txt "lappend \"html::ElemAttrOptional($elem)\" [lindex $l 0]\n"
			}
			append txt "set \"html::AttrType($elem%[lindex $l 0])\" [set t [lindex $l 1]]\n"
			if {$t == "length" || $t == "integer" || $t == "multilength" || $t == "multilengths" || $t == "coords"} {
				append txt "set \"html::AttrRange($elem%[lindex $l 0])\" [lindex $l 3]\n"
			}
			if {$t == "choices"} {
				append txt "set \"html::AttrChoices($elem%[lindex $l 0])\" \{[lrange $l 3 end]\}\n"
			}
			if {$t == "eventhandler"} {
				append ctxt "lappend JavaScriptWords [lindex $l 0]\n"
				append txt "set \"html::AttrType($elem%[string toupper [lindex $l 0]])\" $t\n"
			} else {
				append ctxt "lappend attributeWords [lindex $l 0]\n"
			}
		}
	}
	html::SaveCache "Additions cache" $txt
	html::SaveCache "Additions coloring cache" $ctxt
}

proc html::FindElemInWindow {} {
	regexp {\* Defining element (.+) +\*$} [lindex [winNames] 0] "" elem
	return $elem
}

proc html::customBrowseUp {} {
	set limit [html::customTopLine]
	if {[pos::compare [getPos] > $limit]} {
		set limit [pos::math [getPos] - 1]
	}
	selectText [lineStart $limit] [nextLineStart $limit]
}

proc html::customBrowseDown {} {
	set pos [getPos]
	if {[pos::compare $pos < [html::customTopLine]]} {
		set pos [pos::prevLineStart [html::customTopLine]]
	}
	if {[pos::compare [nextLineStart $pos] < [maxPos]]} {
		selectText [nextLineStart $pos] [nextLineStart [nextLineStart $pos]]
	}
}

proc html::customTopLine {} {
	set p [minPos]
	for {set i 0} {$i < 6} {incr i} {
		set p [nextLineStart $p]
	}
	return $p
}

namespace eval HTMx {}

proc HTMx::DblClick {from to} {html::EditAttribute}

Bind 'n' html::NewAttribute HTMx
Bind '\r' html::EditAttribute HTMx
Bind Enter html::EditAttribute HTMx
Bind 0x33 html::DeleteAttributes HTMx
Bind Del html::DeleteAttributes HTMx
Bind down 	html::customBrowseDown HTMx
Bind up 	html::customBrowseUp HTMx
hook::register closeHook html::HTMxCloseHook HTMx
