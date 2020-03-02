## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlEditing.tcl"
 #                                    created: 99-07-18 12.50.57 
 #                                last update: 03/21/2006 {03:09:10 PM} 
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
# This file contains procs for the Editing submenu.
#===============================================================================

proc htmlEditing.tcl {} {}

#===============================================================================
# ×××× Select container/in container ×××× #
#===============================================================================

# select container, like Balance (cmd-B)
proc html::SelectinContainer {} {html::SelectContainer 1}
  
proc html::SelectContainer {{inside 0}} {
	if {![llength [winNames]]} {return}
	set start [getPos]
	if {[pos::compare $start != [minPos]] &&
	![catch {getText $start [pos::math $start + 2]} lookingAt] &&
	$lookingAt != "</" &&
	[string index $lookingAt 0] == "<"} {
		set start [pos::math $start - 1]
	}
	set tags [html::GetContainer $start [selEnd]]
	if {[llength $tags] == 5} {
		if {$inside} {
			selectText [lindex $tags 1] [lindex $tags 2]
		} else {
			selectText [lindex $tags 0] [lindex $tags 3]
		}
		status::msg "[lindex $tags 4] selected."
	} else {
		beep
		status::msg "Cannot decide on enclosing tags."
	}
}
  
#===============================================================================
# ×××× Select opening/Remove opening ×××× #
#===============================================================================

# Select an opening tag, or remove it, of an element without a closing tag.
proc html::RemoveOpening {} {
	if {![win::checkIfWinToEdit]} {return}
	html::SelectTag 1
}

proc html::SelectTag {{remove 0}} {
	if {![llength [winNames]]} {return}
	set begin [getPos]
	# back up one if possible and selection is wanted.
	if {[pos::compare $begin > [minPos]] && !$remove} {set begin [pos::math $begin - 1]}
	set tag [html::GetOpening $begin [expr !$remove]]
	if {[llength $tag] == 3} {
		if {$remove} {
			set diff [expr {abs([pos::diff [lindex $tag 1] $begin])}]
			deleteText [lindex $tag 0] [lindex $tag 1]
			if {$diff > 0} {
				goto [pos::math [getPos] + $diff]
			}
			status::msg "[lindex $tag 2] deleted."
		} else {
			selectText [lindex $tag 0] [lindex $tag 1]
			status::msg "[lindex $tag 2] selected."
		}
	} else {
		if {$remove} {
			beep
			status::msg "Cannot find opening tag."
		} else {
			beep
			status::msg "Cannot find opening tag."
		}
	}
}

#===============================================================================
# ×××× Untag/Untag and select ×××× #
#===============================================================================

# remove containing tags
proc html::UntagandSelect {} {html::Untag 1}

proc html::Untag {{selectit 0}} {
	if {![win::checkIfWinToEdit]} {return}
	set curPos [getPos]
	set tags [html::GetContainer $curPos [selEnd]]
	if {[llength $tags] < 5} {
		beep
		status::msg "Cannot decide on enclosing tags."
		return
	}
	# delete them
	replaceText [lindex $tags 0] [lindex $tags 3] \
	  [getText [lindex $tags 1] [lindex $tags 2]]
	if {$selectit} {
		selectText [lindex $tags 0] \
		  [pos::math [lindex $tags 2] - [pos::diff [lindex $tags 0] [lindex $tags 1]]]
	} else {
		if {[pos::compare $curPos < [lindex $tags 1]]} {set curPos [lindex $tags 1]}
		if {[pos::compare $curPos > [lindex $tags 2]]} {set curPos [lindex $tags 2]}
		goto [pos::math $curPos - [pos::diff [lindex $tags 0] [lindex $tags 1]]]
	}
	status::msg "[lindex $tags 4] deleted."
}

#===============================================================================
# ×××× Change container/opening ×××× #
#===============================================================================

# Change attributes of a tag.
proc html::EditTag {{option 0}} {
	if {![win::checkIfWinToEdit]} {return}
	set pos [getPos]
	if {!$option && [doubleLookAt $pos] == "</" && [pos::compare $pos > [minPos]]} {set pos [pos::math $pos - 1]}
	if {[catch {search -s -f 0 -r 1 -i 0 -m 0 {<[^<>]+>} $pos} res] || ($option == 2 &&
	[pos::compare [lindex $res 1] < $pos])} {return 0}
	set txt [getText [pos::math [lindex $res 0] + 1] [pos::math [lindex $res 1] - 1]]
	regexp {^[ \t\r\n]*(/?[^ \r\t\n>/]+)} $txt "" tag
	if {[string index $tag 0] == "/" || $tag == "!--"} {return 0}
	if {$option == 2} {set option 0}
	if {[set newTag [html::ChangeElement $txt [string toupper $tag] [lindex $res 0] $option]] != ""} {
		elec::ReplaceText [lindex $res 0] [lindex $res 1] $newTag
		return 1
	}
	return 0
}

#
# Extracts all attributes to a element from a list, and puts up a dialog window
# where the user can change the attributes.
#
proc html::ChangeElement {tag elem {wrPos 0} {maySkipDialog 0}} {
	global HTMLmodeVars html::ElemAttrOptional html::Plugins html::HideDeprecated html::HideExtensions html::HideFrames
	global html::NotInStrict html::NotInTransitional html::HTMLextensions html::DeprecatedElems
	global html::xhtml html::xhtmlversion html::XHTML11Only
	
	set errText ""
	set addSlash 0
	if {[string match "*/" $tag]} {set addSlash 1}
	html::ExtractAttrValues $tag attrs attrVals errText
	set attrs [string toupper $attrs]
	
	# All INPUT elements are defined differently. Must extract TYPE.
	if {$elem == "INPUT"} {
		set typeIndex [lsearch -exact $attrs "TYPE="]
		if {$typeIndex >= 0 } {
			set elem [string toupper [lindex $attrVals $typeIndex]]
			set elem "INPUT TYPE=${elem}"
			# Remove TYPE attribute from list.
			set attrs [lreplace $attrs $typeIndex $typeIndex]
			set attrVals [lreplace $attrVals $typeIndex $typeIndex]
		} else {
			set elem "INPUT TYPE=TEXT"
		} 
	}
	
	set used $elem
	
	# Element known by HTML mode?
	if {![info exists html::ElemAttrOptional($elem)]} {
		alertnote "$elem is unknown."
		return
	}
	
	if {${html::HideExtensions} || ${html::HideDeprecated} || $HTMLmodeVars(hideDeprecated) || $HTMLmodeVars(hideExtensions) } { 
		if {[lcontains html::HTMLextensions $elem]} {
			alertnote "$elem is an extension to HTML. Either you have requested not to use extensions or the DTD excludes them."
			return
		}
		if {(!$html::xhtml || $html::xhtmlversion == 1.0) && [lcontains html::XHTML11Only $elem]} {
			alertnote "$elem can only be used in XHTML 1.1."
			return
		}		
	}
	if {(${html::HideFrames} && [lcontains html::NotInTransitional $elem]) ||
	(${html::HideDeprecated} && [lcontains html::NotInStrict $elem])} {
		alertnote "The DTD of the document excludes $elem."
		return
	}
	if {$HTMLmodeVars(hideDeprecated) && [lcontains html::DeprecatedElems $elem]} {
		alertnote "$elem is a deprecated element. You have requested not to use deprecated elements."
		return
	}
	
	# If EMBED element, choose which
	if {$elem == "EMBED" && [llength ${html::Plugins}] > 1} {
		if {[catch {listpick -p "Which plug-in?" [lsort ${html::Plugins}]} elem] || ![string length $elem]} {return}
	}
	
	# If LI element, check in which list.
	if {$elem == "LI"} {
		html::FindList elem
	}
			
	set useBig $HTMLmodeVars(changeInBigWindows)
	set optatts [html::GetOptional $elem]
	set alloptatts [html::GetOptional $elem 1]
	set exp "\[ \n\r\t]+([join [html::GetNotIn $elem] |])"
	regsub -all $exp " $alloptatts" " " alloptatts
	set reqatts [html::GetRequired $elem]
	set allAttrs [html::GetUsed $elem $reqatts $optatts]
	set reallyAllAtts [string toupper [concat $reqatts $alloptatts]]
	set extensions ""
	set notinhtml ""
	set deprecated ""
	set notinstrict ""
		
	if {${html::HideDeprecated} || $HTMLmodeVars(hideDeprecated)} {
		set extensions [html::GetExtensions $elem]
		set deprecated [html::GetDeprecated $elem]
		set notinhtml [html::GetNotIn $elem]
		set exp "\[ \n\r\t]+([join [concat $extensions $deprecated $notinhtml] |])"
		regsub -all $exp " $allAttrs" " " allAttrs
		regsub -all $exp " $reallyAllAtts" " " reallyAllAtts
		if {${html::HideDeprecated}} {
			set notinstrict "TARGET="
			regsub "TARGET=" $allAttrs " " allAttrs
			regsub "TARGET=" $reallyAllAtts " " reallyAllAtts
		}
	} elseif {${html::HideExtensions} || $HTMLmodeVars(hideExtensions)} {
		set extensions [html::GetExtensions $elem]
		set notinhtml [html::GetNotIn $elem]
		set exp "\[ \n\r\t]+([join [concat $extensions $notinhtml] |])"
		regsub -all $exp " $allAttrs" " " allAttrs
		regsub -all $exp " $reallyAllAtts" " " reallyAllAtts
	}

	# First check if one which is normally not used is used.
	set addNotUsed 0
	set toup [string toupper $allAttrs]
	foreach a $attrs {
		# Check for flags not in short form.
		if {[lcontains reallyAllAtts [set tra [string trim $a =]]]} {
			set attrs [lreplace $attrs [set ww [lsearch -exact $attrs $a]] $ww $tra]
		}
	}
	foreach a $attrs {	
		if {![lcontains toup $a] && [lcontains reallyAllAtts $a]} {
			regsub -all "\[ \n\r\t]+([join $allAttrs |])" " $optatts" " " notUsedAtts
			append allAttrs " $notUsedAtts"
			set addNotUsed 1
			break
		}
	}
	
	# then check some hidden one is used
	set addHidden 0
	set toup [string toupper $allAttrs]
	foreach a $attrs {
		if {![lcontains toup $a] && [lcontains reallyAllAtts $a]} {
			regsub -all "\[ \n\r\t]+([join $optatts |])" " $alloptatts" " " hiddenAtts
			append allAttrs " $hiddenAtts"
			set addNotUsed 1
			set addHidden 1
			break
		}
	}
	# check if some is unknown, deprecated or extension
	set toup [string toupper $allAttrs]
	set extensions [string toupper $extensions]
	set deprecated [string toupper $deprecated]
	set notinhtml [string toupper $notinhtml]
	set notinstrict [string toupper $notinstrict]
	foreach a $attrs {
		if {[lcontains extensions $a]} {
			lappend errText "[string trim $a =] is an extension to HTML."
		} elseif {[lcontains notinhtml $a] || [lcontains notinhtml [string trim $a =]]} {
			if {!$html::xhtml} {
				lappend errText "[string trim $a =] can only be used in XHTML."
			} else {
				lappend errText "[string trim $a =] cannot be used in XHTML ${html::xhtmlversion}."
			}
		} elseif {[lcontains deprecated $a] || [lcontains deprecated [string trim $a =]]} {
			lappend errText "[string trim $a =] is a deprecated attribute."
		} elseif {[lcontains notinstrict $a] || [lcontains notinstrict [string trim $a =]]} {
			lappend errText "[string trim $a =] may not be used with the strict DTD."
		} elseif {![lcontains toup $a]} {
			lappend errText "[string trim $a =] is an unknown attribute."
		}
	}
	
	
	# Add something if all attrs are hidden.
	if {![llength $allAttrs]} {
		# Return if dialog not required.
		if {$maySkipDialog} {return}
		set allAttrs $optatts
		set addNotUsed 1
	} 
	
	# Does this element have any attributes?
	if {![llength $allAttrs]} {
		if {[llength $errText]} {
			if {[askyesno "$elem has no attributes. Remove the ones in the text?"] == "no"} {
				return
			} else {
				return [html::SetCase <$elem>]
			}
		} else {
			beep
			status::msg "$elem has no attributes."
			return
		}
	}
	
	set values ""
	# Add two dummy elements for OK and Cancel buttons.
	if {$useBig} {set values {0 0}}
	# Build a list with attribute vales.
	foreach a $allAttrs {
		set attrIndex [lsearch -exact $attrs [string toupper $a]]
		if {$attrIndex >= 0 } {
			set aval [lindex $attrVals $attrIndex]
		} else {
			set aval ""
		}
		eval html::GetDialog[html::GetAttrType $elem $a] [list $elem] $a [list $aval] $useBig values errText
	}
	# If invalid attributes, continue?
	if {[llength $errText] && ![html::ErrorWindow "$elem not well-defined" $errText 1]} {
		return 
	}
	if {$useBig} {
		set r [html::OpenElemWindow $used $elem [lindex [pos::toRowCol $wrPos] 1] $values $addNotUsed $addHidden $wrPos]
	} else {
		set r [html::OpenElemStatusBar $used $elem [lindex [pos::toRowCol $wrPos] 1] $values $addNotUsed $addHidden $wrPos]
	}
	if {$addSlash && $r != ""} {
		set r [html::EndOfEmptytag $r]
	}
	return $r
}

proc html::ExtractAttrValues {tag attr aval e {errtag ""} {checkquotes 0}} {
	upvar $attr attrs $aval attrVals $e err
	# Remove tabs and returns from list.
	regsub -all "\[\t\r\n\]+" $tag " " tag
	
	# Remove element name.
	regsub { *[^ ]+} $tag "" tag
	set tag [string trim $tag " />"]
	set attrs ""
	set attrVals ""
	
	# Extract the attributes.
	set exp1 {([^ =]+)[ ]*=[ ]*"([^"]*)"}
	set exp2 {([^ =]+)[ ]*=[ ]*'([^']*)'}
	set exp3 {([^ =]+)[ ]*=[ ]*([^ "']+)}
	foreach exp [list $exp1 $exp2 $exp3] {
		while {[regexp -indices $exp $tag tag0 attr aval]} {
			lappend attrs "[eval string range [list $tag] $attr]="
			lappend attrVals [eval string range [list $tag] $aval]
			set tag "[string range $tag 0 [expr {[lindex $tag0 0] - 1}]] [string range $tag [expr {[lindex $tag0 1] + 1}] end]"
			if {$checkquotes && $exp == $exp3} {
				lappend err "The value of the attribute [string toupper [string trim [lindex $attrs end] =]]$errtag must be within quotes."
			}
		}
	}
	if {[regsub -all {([^ =]+)[ ]*=[ ]*"[^"]*} $tag " " tag]} {
		lappend err "Unmatched \"."
	}
	if {[regsub -all {([^ =]+)[ ]*=[ ]*'[^']*} $tag " " tag]} {
		lappend err "Unmatched \'."
	}
	# Finally grab the flags
	while {[regexp -indices {([^ =]+)} $tag "" attr]} {
		lappend attrs [eval string range [list $tag] $attr]
		lappend attrVals 1
		set tag [string range $tag [expr {[lindex $attr 1] + 1}] end]
	}
	# Check for multiple attributes
	regsub -all = $attrs "" attrs2
	set attrs2 [string toupper $attrs2]
	if {[llength $attrs2] != [llength [lunique $attrs2]]} {
		foreach aa $attrs2 {
			if {![info exists count($aa)]} {set count($aa) 1} else {
				incr count($aa)
			}
		}
		foreach aa [array names count] {
			if {$count($aa) > 1} {
				lappend err "Multiple $aa attributes$errtag."
			}
		}
	}
}

#===============================================================================
# ×××× Get dialog ×××× #
#===============================================================================

# flag 
proc html::GetDialogflag {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	if {$aval == "1" || [string toupper $aval] == "$attr"} {
		lappend val 1
	} else {
		if {$aval != "" && [string toupper $aval] != "$attr"} {
			lappend errText "$attr: Incorrect value, $aval"
		}
		lappend val 0
	}
}

# url 
proc html::GetDialogurl {elem attr aval useBig v etext} {
	upvar $v val
	global html::UserURLs
	set aval [string trim $aval]
	if {$aval != ""} {
		set aval [quote::Unurl $aval]
		html::AddToCache URLs $aval
		if {$useBig} {
			if {[lcontains html::UserURLs $aval]} {
				lappend val "" $aval 0
			} else {
				lappend val $aval " " 0
			}
		} else {
			lappend val $aval
		}
	} else {
		if {$useBig} {
			lappend val "" " " 0
		} else {
			lappend val ""
		}
	}
}

# color 
proc html::GetDialogcolor {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	global html::userColorname html::ColorNumber
	set aval [string trim $aval]
	if {$aval != ""} {
		set aval [html::CheckColorNumber $aval]
		if {$aval == 0} {
			lappend errText "$attr: Invalid color number."
			if {$useBig} {
				lappend val "" " " 0
			} else {
				lappend val ""
			}
		} elseif {[info exists html::userColorname($aval)]} {
			if {$useBig} {
				lappend val "" [set html::userColorname($aval)] 0
			} else {
				lappend val [set html::userColorname($aval)]
			}
		} elseif {[info exists html::ColorNumber($aval)]} {
			if {$useBig} {
				lappend val "" [set html::ColorNumber($aval)] 0
			} else {
				lappend val [set html::ColorNumber($aval)]
			}
		} else {
			if {$useBig} {
				lappend val $aval " " 0
			} else {
				lappend val $aval
			}
		}
	} else {
		if {$useBig} {
			lappend val "" " " 0
		} else {
			lappend val ""
		}
	}
}

# frametarget 
proc html::GetDialogframetarget {elem attr aval useBig v etext} {
	upvar $v val
	global html::UserTargets
	set aval [string trim $aval]
	if {$aval != ""} {
		html::AddToCache Targets $aval
		if {$useBig} {
			if {[lcontains html::UserTargets $aval]} {
				lappend val "" $aval
			} else {
				lappend val $aval " "
			}
		} else {
			lappend val $aval
		}
	} else {
		if {$useBig} {
			lappend val "" " "
		} else {
			lappend val ""
		}
	}
}

# choices 
proc html::GetDialogchoices {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	set aval [string trim $aval]
	if {$aval != ""} {
		set aval [string toupper $aval]
		if {[set match [lsearch -exact [set choices [html::GetAttrChoices $elem $attr]] $aval]] >= 0} {
			lappend val [lindex $choices $match]
		} else {
			lappend errText "$attr: Unknown choice, $aval."
			lappend val ""
		}
	} else {
		lappend val ""
	}	
}

# length 
proc html::GetDialoglength {elem attr aval useBig v etext {multilength 0}} {
	upvar $v val $etext errText
	set aval [string trim $aval]
	if {$aval != ""} {
		set numcheck [html::CheckAttrNumber $elem $attr $aval 1 $multilength]
		if {$numcheck == 1} {
			lappend val $aval
		} else {
			lappend errText "$attr: $numcheck"
			lappend val ""
		}
	} else {
		lappend val ""
	}
	if {$useBig && $elem == "IMG" && $attr == "WIDTH="} {lappend val 0}
}

# integer 
proc html::GetDialoginteger {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	set aval [string trim $aval]
	if {$aval != ""} {
		set numcheck [html::CheckAttrNumber $elem $attr $aval 0]
		if {$numcheck == 1} {
			lappend val $aval
		} else {
			lappend errText "$attr: $numcheck"
			lappend val ""
		}
	} else {
		lappend val ""
	}
}

# other 
proc html::GetDialogother {elem attr aval useBig v etext} {
	upvar $v val
	lappend val [string trim $aval]
}

# othernotrim
proc html::GetDialogothernotrim {elem attr aval useBig v etext} {
	upvar $v val
	lappend val $aval
}

# fixed
proc html::GetDialogfixed {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	set aval [string trim $aval]
	if {$aval != "" && $aval != [set fix [html::GetAttrFixed $elem $attr]]} {
		lappend errText "$attr: The value should be $fix."
	}
}

# id
proc html::GetDialogid {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	set aval [string trim $aval]
	if {$aval != ""} {
		if {[html::CheckId $aval]} {
			lappend val $aval
		} else {
			lappend errText "$attr: Must be first a letter and then letters, digits, and '_' '-' ':' '.'"
			lappend val ""
		}
	} else {
		lappend val ""
	}
	
}

# ids
proc html::GetDialogids {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	set aval [string trim $aval]
	if {$aval != ""} {
		if {[html::CheckIds $aval]} {
			lappend val $aval
		} else {
			lappend errText "$attr: Must be first a letter and then letters, digits, and '_' '-' ':' '.'"
			lappend val ""
		}
	} else {
		lappend val ""
	}
	
}

# anchor
proc html::GetDialoganchor {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	if {[set aval [string trim $aval]] != ""} {
		html::AddToCache URLs "#$aval"
	}
	html::GetDialogother $elem $attr $aval $useBig val errText
}

# targetname
proc html::GetDialogtargetname {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	html::AddToCache Targets [string trim $aval]
	html::GetDialogother $elem $attr $aval $useBig val errText
}

# contenttype 
proc html::GetDialogcontenttype {elem attr aval useBig v etext} {
	upvar $v val
	global HTMLmodeVars
	set aval [string tolower [string trim $aval]]
	if {$aval != ""} {
		if {![lcontains HTMLmodeVars(contenttypes) $aval]} {
			lappend HTMLmodeVars(contenttypes) $aval
			prefs::modifiedModeVar contenttypes HTML
		}
		if {$useBig} {
			lappend val "" $aval
		} else {
			lappend val $aval
		}
	} else {
		if {$useBig} {
			lappend val "" " "
		} else {
			lappend val ""
		}
	}
}

# contenttypes
proc html::GetDialogcontenttypes {elem attr aval useBig v etext {types contenttypes} {comma 1}} {
	upvar $v val
	global HTMLmodeVars
	set aval [string trim $aval]
	if {$aval != ""} {
		if {$comma} {
			set alist [split $aval ,]
		} else {
			set alist $aval
		}
		foreach a $alist {
			set a [string tolower [string trim $a]]
			if {![lcontains HTMLmodeVars($types) $a]} {
				lappend HTMLmodeVars($types) $a
				prefs::modifiedModeVar $types HTML
			}
		}
		if {$useBig} {
			lappend val " " $aval 0
		} else {
			lappend val $aval
		}
	} else {
		if {$useBig} {
			lappend val " " "" 0
		} else {
			lappend val ""
		}
	}
}

# eventhandler 
proc html::GetDialogeventhandler {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	html::GetDialogother $elem $attr $aval $useBig val errText
	# to be modified
}

# linktypes 
proc html::GetDialoglinktypes {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	html::GetDialogcontenttypes $elem $attr $aval $useBig val errText linktypes 0
}

# multilength 
proc html::GetDialogmultilength {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	html::GetDialoglength $elem $attr $aval $useBig val errText 1
}

# multilengths 
proc html::GetDialogmultilengths {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	html::GetDialogcoords $elem $attr $aval $useBig val errText 1
}

# languagecode 
proc html::GetDialoglanguagecode {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	html::GetDialogother $elem $attr $aval $useBig val errText
	# to be modified
}

# charset 
proc html::GetDialogcharset {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	html::GetDialogother $elem $attr $aval $useBig val errText
	# to be modified
}

# charsets 
proc html::GetDialogcharsets {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	html::GetDialogother $elem $attr $aval $useBig val errText
	# to be modified
}

# coords 
proc html::GetDialogcoords {elem attr aval useBig v etext {multilength 0}} {
	upvar $v val $etext errText
	set aval [string trim $aval]
	if {$aval != ""} {
		set av ""
		set err 0
		foreach l [split $aval ,] {
			set l [string trim $l]
			set numcheck [html::CheckAttrNumber $elem $attr $l 1 $multilength]
			if {$numcheck == 1} {
				append av ",$l"
			} else {
				lappend errText "$attr: $numcheck"
				set err 1
				lappend val ""
				break
			}
		}
		if {!$err} {lappend val [string trim $av ,]}
	} else {
		lappend val ""
	}
}

# oltype 
proc html::GetDialogoltype {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	set aval [string trim $aval]
	if {$aval != ""} {
		if {[set match [lsearch -exact [set choices [html::GetAttrChoices $elem $attr]] $aval]] >= 0} {
			lappend val [lindex $choices $match]
		} else {
			lappend errText "$attr: Unknown choice, $aval."
			lappend val ""
		}
	} else {
		lappend val ""
	}	
}

# datetime 
proc html::GetDialogdatetime {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	set aval [string trim $aval]
	if {$aval != ""} {
		if {[regexp {^([0-9]+)-([0-9]+)-([0-9]+)T([0-9]+):([0-9]+):([0-9]+)(Z|[-+][0-9]+:[0-9]+)$} $aval "" Y M D h m s tzd]} {
			if {![catch {html::CheckDateTime [list $Y $M $D $h $m $s $tzd]} res]} {
				if {$useBig} {
					lappend val $Y $M $D $h $m $s $tzd 0
				} else {
					lappend val $aval
				}
			} else {
				lappend errText "$attr: $res"
				if {$useBig} {
					lappend val "" "" "" "" "" "" "" 0
				} else {
					lappend val ""
				}
			}
		} else {
			lappend errText "$attr: Incorrect date and time."
			if {$useBig} {
				lappend val "" "" "" "" "" "" "" 0
			} else {
				lappend val ""
			}
		}
	} else {
		if {$useBig} {
			lappend val "" "" "" "" "" "" "" 0
		} else {
			lappend val ""
		}
	}
}

# character 
proc html::GetDialogcharacter {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	set aval [string trim $aval]
	if {$aval != ""} {
		if {[string length $aval] == 1} {
			lappend val $aval
		} else {
			lappend errText "$attr: Only a single character is allowed."
			lappend val ""
		}
	} else {
		lappend val ""
	}
}

# mediadesc 
proc html::GetDialogmediadesc {elem attr aval useBig v etext} {
	upvar $v val $etext errText
	html::GetDialogcontenttypes $elem $attr $aval $useBig val errText mediatypes
}


#===============================================================================
# ×××× Editing help procs ×××× #
#===============================================================================

#
# return positions of tags of including elements, as a list of 5 elements --
# openstart openend closestart closeend elementname.
# Elements without a closing tag are ignored.
# args: point to start search backward from; point which must be enclosed
#
# if any problem, return just {0}
#
proc html::GetContainer {curPos inclPos} {

	set startPos $curPos
	set startPos2 $inclPos
	set searchFinished 0
	status::msg "Searching for enclosing tagsÉ"
	while {!$searchFinished} {
		# find first tag
		set isStartTag 0
		while {!$isStartTag} {
			if {[catch {html::FindFirstOccurance {<[^<>]+>} $startPos 0} res]} {
				status::msg ""
				return {0}
			}
			set tag1start [lindex $res 0]
			set tag1end   [lindex $res 1]
			# get element name
			if {![regexp {<([^ \t\r\n>]+)} [getText $tag1start $tag1end] tmp tag]} {
				status::msg ""
				return {0}
			}
			# is this a closing tag?
			if {[string index $tag 0] != "/"} {set isStartTag 1}
			set startPos [pos::math $tag1start - 1]
		}
		# find closing tag
		set res [html::GetClosing $tag $tag1end]
		
		set tag2start [lindex $res 0]
		set tag2end   [lindex $res 1]
		# If container enclosed along with us, or there is no closing tag,
		# continue searching.
		if {![llength $res] || [pos::compare $tag2end < $inclPos]} {
			# Make sure that we have more text to search in the window.
			if {[pos::compare $tag1start == [minPos]]} {
				status::msg ""
				return {0}
			}
			set startPos [pos::math $tag1start - 1]
		} else {
			set Container "$tag1start $tag1end $tag2start $tag2end" 
			set searchFinished 1
		}
	}
	
	status::msg ""
	return [concat $Container [string toupper $tag]]
}

#
# return position an opening tag if the first element to the left
# of startPos is an element with only an opening tag, as a list of 3 elements --
# openstart openend elementname.
#
# if any problem, return empty string
#

proc html::GetOpening {startPos {anyok 0}} {
	
	while {1} {
		if {[catch {html::FindFirstOccurance {<[^<>]+>} $startPos 0} res]} {
			return
		}
		set tag1start [lindex $res 0]
		set tag1end   [lindex $res 1]
		# get element name
		if {![regexp {<([^ \t\r\n>]+)} [getText $tag1start $tag1end] tmp tag]} {
			return
		}
		# is this a closing tag?
		if {!$anyok && [string index $tag 0] == "/"} {return}
		# comment?
		if {[string range $tag 0 2] != "!--"} {break}
		set startPos [pos::math $tag1start - 1]
	}
	
	# find closing tag
	set res ""
	if {!$anyok} {set res [html::GetClosing $tag $tag1end]}
	
	if {![llength $res] } {
		return "$tag1start $tag1end [string toupper $tag]"
	} else {
		return
	}
	
}

proc html::GetClosing {tag sPos} {
	set x </${tag}>
	set sPos2 $sPos
	while {1} {
		if {[catch {html::FindFirstOccurance $x $sPos} res]} {return} 
		# Look for another opening tag of the same element.
		# Is it further away than the closing tag?
		if {[catch {html::FindFirstOccurance "<${tag}(\[ \t\r\n\]+|>)" $sPos2} res2] || 
		[pos::compare [lindex $res2 0] > [lindex $res 0]]} {break}
		# If not, find the next closing tag.
		set sPos [lindex $res 1]
		set sPos2 [lindex $res2 1]
	}
	return $res
}

# Determines which list the current position is inside.
proc html::FindList {t {pos ""}} {
	upvar $t tag
	if {$pos == ""} {set pos [getPos]}
	set listType ""
	foreach l [list UL OL DIR MENU] {
		set pos1 $pos; set pos2 $pos
		# Search until a single list opening is found.
		while {![catch {html::FindFirstOccurance "<${l}(\[ \t\r\n\]+\[^>\]*>|>)" $pos1 0} listOpening] && 
		![catch {html::FindFirstOccurance </$l> $pos2 0} listClosing] &&
		[pos::compare [lindex $listClosing 0] > [lindex $listOpening 0]]} {
			set pos1 [pos::math [lindex $listOpening 0] - 1]
			set pos2 [pos::math [lindex $listClosing 0] - 1]
		}
		if {![catch {html::FindFirstOccurance "<${l}(\[ \t\r\n\]+\[^>\]*>|>)" $pos1 0} listOpening]} {
			lappend listType "$listOpening $l"
		}
		
	}
	set ltype [lindex [lindex $listType 0] 2]
	set lnum [lindex [lindex $listType 0] 0]
	for {set i 1} {$i < [llength $listType]} {incr i} {
		if {[pos::compare [lindex [lindex $listType $i] 0] > $lnum]} {
			set ltype [lindex [lindex $listType $i] 2]
			set lnum [lindex [lindex $listType $i] 0]
		}
	}
	if {$ltype == "UL"} {
		set tag "LI IN UL"
	} elseif {$ltype == "OL"} {
		set tag "LI IN OL"
	}			
}

#===============================================================================
# ×××× Change choice ×××× #
#===============================================================================

# Change choice of an attribute with pre-defined choices.
proc html::ChangeChoice {} {
	if {![win::checkIfWinToEdit]} {return}
	set pos [pos::math [getPos] - 1]
	if {[catch {search -s -f 0 -r 1 -i 0 -m 0 {<[^<>]+>} $pos} res] ||
	[pos::compare [lindex $res 1] < $pos] || 
	![regexp {<([^ \t\r\n>]+)} [eval getText $res] "" tag] ||
	[catch {search -s -f 0 -r 1 -i 0 -m 0 {[^-a-zA-Z0-9][^= \t\r\n]+[ \t\r\n]*=[ \t\r\n]*(\"|\')?[^\"\' \t\n\r>]*(\"|\')?} $pos} res1] ||
	[pos::compare [lindex $res1 1] < $pos] ||
	![regexp {([^=]+)=([ \t\r\n]*)((\"[^\" \t\r\n]*\")|(\'[^\' \t\r\n]*\')|([^ \t\r\n>]*))} \
	  [getText [pos::math [lindex $res1 0] + 1] [lindex $res1 1]] "" attr sp choice]} {
		beep
		status::msg "Current position is not at an attribute with choices."
		return
	}
	set pos0 [pos::math [lindex $res1 0] + [string length $attr] + [string length $sp] + 2]
	set pos1 [pos::math $pos0 + [string length $choice]]
	set choice [string trim $choice "\"'"]
	set tag [string toupper $tag]
	if {$tag == "INPUT"} {
		if {![regexp -nocase {[^-a-zA-Z0-9]TYPE[ \t\r\n]*=[ \t\r\n]*('|\")?([^ \t\r\"'<>]+)(\"|')?} [eval getText $res] "" "" tag]} {
			set tag TEXT
		}
		set tag "INPUT=[string toupper $tag]"
	}
	if {$tag == "LI"} {
		html::FindList tag
	}
	set attr "[string trim [string toupper $attr]]="
	if {[lsearch -exact [html::GetExcludedElems] $tag] >=0 || ([html::GetAttrType $tag $attr] != "choices" &&
	[html::GetAttrType $tag $attr] != "oltype")} {
		beep
		status::msg "Current position is not at an attribute with choices."
		return
	}
	if {($tag != "OL" && $tag != "LI IN OL") || $attr != "TYPE="} {set choice [string toupper $choice]}
	set choices [html::GetAttrChoices $tag $attr]
	if {[set this [lsearch -exact $choices $choice]] < 0} {set this 0}
	incr this
	if {$this == [llength $choices]} {set this 0}
	set this [lindex $choices $this]
	if {($tag != "OL" && $tag != "LI IN OL") || $attr != "TYPE="} {set this [html::SetCase $this]}
	replaceText $pos0 $pos1 "\"$this\""
	if {[pos::compare [pos::math $pos0 + [string length $this]] > $pos]} {
		goto [pos::math $pos + 1]
	} else {
		goto [pos::math $pos0 + [string length $this] + 1]
	}
}

#===============================================================================
# ×××× Reveal color ×××× #
#===============================================================================

# Convert colour names to numbers and vice versa.
# Or brings up a color picker if cmd-doubleClick.
proc html::RevealColor {{dblClick 0}} {
	global html::ColorName html::ColorNumber html::userColors 
	global html::userColorname
	if {![win::checkIfWinToEdit]} {return}

	set exp "("
	foreach s [html::GetColorAttrs] {
		append exp "[string trimright ${s} =]|"
	} 
	# remove last |
	set exp [string trimright $exp |]
	append exp {)[ \t\r\n]*=[ \t\r\n]*(\"([^\"]*)\"|\'([^\']*)\'|([^ \t\r\n\"\'>]*))}
	set startpos [getPos]
	set endpos [selEnd]
	set cantfind 0
	# find attribute
	set f0 [search -s -f 0 -r 1 -i 1 -n -m 0 "<\[^!\]\[^<>\]*\[ \\t\\n\\r\]+$exp" $startpos]
	set f [search -s -f 0 -r 1 -i 1 -n -m 0 $exp $startpos]
	if {$f0 == "" || [pos::compare [lindex $f0 1] < $endpos] || $f == "" || [pos::compare [lindex $f 1] < $endpos]} {
		set cantfind 1
	}
	if {!$cantfind} {
		set txt [eval getText $f]
		regexp -indices -nocase $exp $txt a b c
		set cpos [pos::math [lindex $f 0] + [lindex $c 0]]
		set epos [pos::math [lindex $f 0] + [lindex $c 1] + 1]
		set col [string trim [string range $txt [lindex $c 0] [lindex $c 1]] "\"'"]
		if {!$dblClick} {
			if {[info exists html::ColorName($col)]} {
				replaceText $cpos $epos "\"[set html::ColorName($col)]\""
			} elseif {[info exists html::ColorNumber($col)]} {
				replaceText $cpos $epos "\"[set html::ColorNumber($col)]\""
			} elseif {[info exists html::userColorname($col)]} {
				replaceText $cpos $epos "\"[set html::userColorname($col)]\""
			} elseif {[info exists html::userColors($col)]} {
				replaceText $cpos $epos "\"[set html::userColors($col)]\""
			} else {
				beep
				status::msg "Don't recognize color."
			}
		} else {
			if {[set ncol [html::CheckColorNumber $col]] != "0"} {
				set ncol [html::HexColor $ncol]
			} else {
				set ncol {65535 65535 65535}
			}
			set newcolor [html::AddANewColor $ncol]
			if {[string length $newcolor]} {
				set newcolor [html::CheckColorNumber $newcolor]
				replaceText $cpos $epos "\"$newcolor\""
			}
			return 1
		}
	} elseif {!$dblClick} {
		beep
		status::msg "Current position is not at a color attribute."
	} else {
		return 0
	}
}

#===============================================================================
# ×××× Insert attributes ×××× #
#===============================================================================

# Inserts an attribute in a tag at the current position.
proc html::InsertAttributes {{attrList ""} {pos ""}} {
	global HTMLmodeVars fillColumn elecStopMarker html::xhtml
	if {![win::checkIfWinToEdit]} {return}
	if {$pos == ""} {set pos [getPos]}
	set useMarks $HTMLmodeVars(useTabMarks)
	if {$attrList == "" && ([set l [html::GetAttributes]] == "" ||
	[catch {listpick -p "Select attributes" -l $l} attrList] || $attrList == "") } {return}
	foreach attr $attrList {
		set epos [pos::math [lindex [search -s -f 0 -r 1 -m 0 {<[^<>]+>} $pos] 1] - 1]
		if {[lookAt [pos::math $epos - 1]] == "/"} {
			set epos [pos::math $epos - 1]
			if {$html::xhtml && $HTMLmodeVars(extraSpace) && [lookAt [pos::math $epos - 1]] == " "} {
				set epos [pos::math $epos - 1]
			}
		}
		if {[lindex [pos::toRowCol $epos] 1] + [string length $attr] > $fillColumn && ($HTMLmodeVars(lineWrap) == 1)} {
			set text "\r"
		} else {
			set text " "
		}
		append text [html::SetCase $attr]
		if {[string match "*=" $attr]} {
			append text "\""
			if {$useMarks} {append text "¥¥"}		
			append text "\""
			if {$useMarks} {append text "¥¥"}		
		} elseif {$html::xhtml} {
			append text = \" [html::SetCase $attr] \"
		}
		if {[doubleLookAt [pos::math [getPos] - 1]] == "\"\""} {
			set rpos [getPos]
			if {$useMarks} {
				if {[string match "*=" $attr]} {
					set text "[string range $text 0 [expr {[string length $text] - 6}]]¥¥¥¥\"¥¥"
				} else {
					append text "¥¥"
				}
			}
			if {[lookAt [pos::math $epos - 1]] == $elecStopMarker} {
				elec::ReplaceText [pos::math $epos - 1] $epos $text
			} else {
				goto $epos
				elec::Insertion $text
			}				
			goto $rpos
		} else {
			goto $epos
			elec::Insertion $text
		}
	}
}

# Returns a list of the attributes not used for the tag at the current position.
proc html::GetAttributes {{pos ""} {tagvar ""}} {
	if {$pos == ""} {set pos [getPos]}
	if {$tagvar != ""} {upvar $tagvar tag}
	if {[catch {search -s -f 0 -r 1 -m 0 {<[^<>]+>} $pos} res] || [pos::compare [lindex $res 1] < $pos]} {
		status::msg "Current position is not at a tag."
		return
	}
	regexp {<([^ \t\r\n/>]*)} [string trim [set all [string toupper [eval getText $res]]]] "" tag
	if {$tag == "LI"} {
		html::FindList tag
	}
	# All INPUT elements are defined differently. Must extract TYPE.
	if {$tag == "INPUT"} {
		if {![regexp -nocase {[^-a-zA-Z0-9]TYPE[ \t\r\n]*=[ \t\r\n]*('|\")?([^ \t\r\"'<>]+)(\"|')?} $all "" "" tag]} {
			set tag TEXT
		}
		set tag [string toupper "INPUT TYPE=$tag"]
	}
	if {[lsearch -exact [html::GetExcludedElems] $tag] >=0} {status::msg "No attributes."; return}
	set ret ""
	foreach a [concat [html::GetRequired $tag] [html::GetOptional $tag]] {
		set exp "\[^-a-zA-Z0-9\]${a}"
		if {[regexp = $a]} {regsub = $exp {[ \t\r\n]*=} exp}
		if {![regexp -nocase $exp $all]} {
			lappend ret $a
		}
	}
	if {$ret == ""} {status::msg "No attributes."}
	return $ret
}

#===============================================================================
# ×××× Quote attributes, Tags to Lowercase/Uppercase ×××× #
#===============================================================================

# Put quotes around all attributes
proc html::QuoteAllAttributes {} {
	html::ScanAllTags quote
}

proc html::TagstoLowercase {} {
	html::ScanAllTags case tolower
}

proc html::TagstoUppercase {} {
	html::ScanAllTags case toupper
}

proc html::ScanAllTags {doWhat {upperLower ""}} {
	if {![win::checkIfWinToEdit]} {return}
	set pos [getPos]
	if {[isSelection]} {
		set start [getPos]
		set end [selEnd]
	} else {
		set start [minPos]
		set end [maxPos]
	}
	set text [getText $start $end]
	while {[regexp -indices {<!--|<[^<>]+>} $text tag]} {
		append newtext [string range $text 0 [lindex $tag 0]]
		set this [string range $text [expr {[lindex $tag 0] + 1}] [lindex $tag 1]]
		if {[string range $this 0 2] == "!--"} {
			set this "!--"
			set tag [list [lindex $tag 0] [pos::math [lindex $tag 0] + 3]]
		}
		set text [string range $text [expr {[lindex $tag 1] + 1}] end]
		if {$this == "!--"} {
			if {[regexp -indices -- {-->} $text commend]} {
				append newtext $this[string range $text 0 [lindex $commend 1]]
				set text [string range $text [expr {[lindex $commend 1] + 1}] end]
			} else {
				append newtext $text
				set text ""
			}
		} else {
			if {$doWhat == "quote"} {
				regsub -all "(\[ \t\r\n\]+\[^=\]+=)(\[ \t\r\n\]*)(\[^'\"\]\[^ >\t\r\n\]+)" $this {\1\2"\3"} newtag
			} else {
				regsub -all {[][\$"\{\}]} $this {\\&} this
				regsub "^\[ \t\r\n\]*\[^ \t\r\n>!]+" $this "\[string $upperLower \"&\"\]" newtag
				set newtag [subst $newtag]
				regsub -all {[][\$"\{\}]} $newtag {\\&} newtag
				regsub -all "(\[^-a-zA-Z0-9\]\[^ \t\r\n=\]+\[ \t\r\n\]*=\[ \t\r\n\]*)(\"\[^\"\]+\"|'\[^'\]+'|\[^ \t\r\n\]+)" $newtag "\[string $upperLower \"\\1\"\]\\2" newtag
				set newtag [subst $newtag]
			}
			append newtext $newtag
		}
	}
	append newtext $text
	replaceText $start $end $newtext
	goto $pos
}

#===============================================================================
# ×××× Remove tags ×××× #
#===============================================================================

# Removes all tags in a selection or the whole document.
proc html::RemoveTags {} {
	if {![llength [winNames]]} {return}
	if {![isSelection]} {
		if {[win::getInfo [win::Current] read-only]} {
			set ync "yes"
		} elseif {[set ync [askyesno -c "Put text without tags in a new window?"]] == "cancel"} {return}
		set txt [html::TagStrip [getText [minPos] [maxPos]]]
		if {$ync == "yes"} {
			new
			insertText $txt
		} else {
			replaceText [minPos] [maxPos] $txt
		}
	} else {
		replaceText [getPos] [selEnd] [html::TagStrip [getSelect]]
	}
}

# Removes all tags from a string.
proc html::TagStrip {str} {
	regsub -all {<[^<>]*>} $str "" str
	return $str
}
