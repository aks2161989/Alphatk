## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "HTMLCompletions.tcl"
 #                                    created: 98-04-05 21.30.48 
 #                                last update: 03/21/2006 {01:46:14 PM} 
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

proc HTMLCompletions.tcl {} {}

# We want to be able to use CSS and JavaScript completions in HTML documents.
catch {uplevel #0 {source [file join $HOME Tcl Completions CSSCompletions.tcl]}}
catch {uplevel #0 {source [file join $HOME Tcl Completions JScrCompletions.tcl]}}


set completions(HTML) {word completion::word}

# If current position is inside a tag, complete the tag or attributes
# being written.
proc HTML::Completion::word {args} {
	global html::ElemAttrOptional HTMLmodeVars mode html::ElemLayout html::Plugins html::xhtml
	
	if {[html::IsInContainer SCRIPT]} {
		# Pretend to be in JavaScript mode
		HTML::overrideModesWith JScr bind::Completion
		return 1
	}
	if {[html::IsInContainer STYLE]} {
		cssProperties.tcl
		# Pretend to be in CSS mode.
		HTML::overrideModesWith CSS bind::Completion
		return 1
	}
	
	set pos [getPos]
	set allTags [array names html::ElemAttrOptional]
	set removeElems [html::GetExcludedElems]
	set allTags [lremove $allTags $removeElems]
	set allUseTags $allTags
	set allTags [lremove $allTags ${html::Plugins}]
	if {![lcontains removeElems EMBED]} {lappend allTags EMBED}
	regsub "LI IN UL" $allTags " " allTags
	regsub "LI IN OL" $allTags " " allTags
	regsub -all {\{INPUT TYPE=[^ ]+} $allTags " " allTags
	lappend allTags INPUT
	lappend allUseTags INPUT
	
	# Find the tag.
	if {[catch {search -s -f 0 -r 1 -m 0 {<[ \t\r\n]*(/?[^ \t\r\n<>/]+)} [pos::math $pos - 1]} left]} {return 0}
	if {![catch {search -s -f 0 -r 0 -m 0 {>} [pos::math $pos - 1]} right]
	&& [pos::compare [lindex $right 1] > [lindex $left 1]] && [pos::compare [lindex $right 0] < $pos]} {return 0}
	set tag [string trim [string toupper [string range [eval getText $left] 1 end]]]
	if {$tag == "LI"} {
		html::FindList tag
	}
	# All INPUT elements are defined differently. Must extract TYPE.
	if {$tag == "INPUT"} {
		if {[pos::compare [set dum [pos::math $pos + 500]] > [maxPos]]} {set dum [maxPos]}
		if {[regexp -nocase {^[^<>]* TYPE[ \t\r\n]*=[ \t\r\n]*\"?([^ \t\r\n\"<>]+)\"?} [getText [lindex $left 1] $dum] dum tag]} {
			set tag "INPUT TYPE=[string toupper $tag]"
		}
	}
	set absTagBegin [lindex $left 0]
	set tagBegin [pos::math [lindex $left 0] + 1]
	set tagEnd [lindex $left 1]
	# opening or closing tag
	set opening 1
	if {[string index $tag 0] == "/"} {
		set tag	[string range $tag 1 end]
		set tagBegin [pos::math $tagBegin + 1]
		set opening 0
	}
	# inside < and > or just right of < ?
	if {![catch {search -s -f 1 -r 0 -m 0 {>} $pos} r1] && 
	([catch {search -s -f 1 -r 0 -m 0 {<} $pos} l1] ||
	[pos::compare [lindex $r1 0] < [lindex $l1 0]])} {
		set inside 1
	} else {
		set inside 0
	}
	
	# Are we typing the tag or an attribute?
	if {$tagEnd == $pos} {
		# tag
		set unique 0
		set thetag [html::FindLargestMatch allTags $tag unique 1]
		if {$thetag == ""} {
			selectText $tagBegin $tagEnd
		} else {
			if {$inside} {
				elec::ReplaceText $tagBegin $tagEnd [html::SetCase $thetag]
			} else {
				set newTag <
				if {!$opening} {append newTag /}
				append newTag [html::SetCase $thetag]
				if {$opening || !$unique} {append newTag "¥¥"}
				if {$unique} {append newTag >}
				if {$opening} {
					if {$unique} {
						html::indentCR $thetag
						if {[set blBef$thetag] && [pos::compare [lineStart [getPos]] > [minPos]]} {
							set gpos [getPos]; goto $absTagBegin
							set newTag "[html::OpenCR 1]$newTag"
							goto $gpos
						} elseif {[set crBef$thetag] && [pos::compare [lineStart [getPos]] > [minPos]]} {
							set gpos [getPos]; goto $absTagBegin
							set newTag "[html::OpenCR]$newTag"
							goto $gpos
						}
						if {[string range [set html::ElemLayout($thetag)] 0 3] == "open"} {
							if {$html::xhtml} {
								set newTag [html::EndOfEmptytag $newTag]
							}
							if {[set crAft$thetag]} {
								append newTag [html::CloseCR]
							}
						} else {
							if {[set crAft$thetag]} {
								append newTag "\r"
							}
							if {[lcontains HTMLmodeVars(indentElements) $thetag]} {append newTag "\t"}
							if {$HTMLmodeVars(useTabMarks)} {append newTag "¥content¥"}
							if {[set crBef/$thetag]} {append newTag "\r"}
							append newTag [html::CloseElem $thetag]
							if {[set blAft/$thetag]} {
								append newTag [html::CloseCR2 [getPos]]
							} elseif {[set crAft/$thetag]} {
								append newTag [html::CloseCR]
							}
							if {$HTMLmodeVars(useTabMarks)} {append newTag "¥end¥"}
						}
					}
				} else {
					if {$HTMLmodeVars(useTabMarks) && !$unique} {append newTag "¥¥"}
					set tagBegin [pos::math $tagBegin - 1]
				}
				set newTag $newTag
				deleteText $absTagBegin $tagEnd
				html::elecInsertion newTag
				if {$unique && $HTMLmodeVars(attrDialogAfterCompleting) && [html::EditTag 1] && $HTMLmodeVars(useTabMarks)} {ring::+}
				if {!$opening  && $HTMLmodeVars(adjustIndentation) && [is::Whitespace [getText [lineStart $absTagBegin] $absTagBegin]]} {
					HTML::indentLine
				}
			}
		}
	} else {
		# Attribute
		if {!$opening} {return 1}
		# Unknown tag?
		if {![lcontains allUseTags $tag]} {
			selectText $tagBegin [getPos]
			return 1
		}
		# are we between quotes to type the attribute value?
		if {![catch {search -s -f 0 -r 1 -m 0 {=\"[^\"]*\"} [pos::math $pos - 1]} pos5] &&  [pos::compare [lindex $pos5 0] > $tagBegin] &&
		[pos::compare [lindex $pos5 1] > $pos]} {
			if {![catch {search -s -f 0 -r 1 -m 0 {[ \t\r\n\"][^ \t\r\n\"=]+=\"[^\"]*\"} [pos::math $pos - 1]} attPos] && 
			[pos::compare [lindex $attPos 0] > $tagBegin] && [pos::compare [lindex $attPos 1] > $pos]} {
				set txt [getText [pos::math [lindex $attPos 0] + 1] [lindex $attPos 1]]
				regexp {([^=]+=)\"([^\"]*)\"} $txt dum attr val
				set attr [string toupper $attr]
				set begin [pos::math [lindex $attPos 0] + 2 + [string length $attr]]
				set end [pos::math [lindex $attPos 1] - 1]
				set allattrs [concat [html::GetRequired $tag] [string toupper [html::GetOptional $tag]]]
				if {[lcontains allattrs $attr]} {
					set type [html::GetAttrType $tag $attr]
					if {[info commands html::Complete$type] != "" || [info commands ::html::Complete$type] != ""} {
						set newval [html::Complete$type $tag $attr $val]
					} else {
						return 0
					}
				} else {
					return 0
				}
				if {$newval == ""} {
					selectText $begin $end
				} else {
					replaceText $begin $end $newval
				}
				return 1
			}
		}

		# we are typing the attribute itself.
		set addSpace 0
		if {[set c [lookAt [getPos]]] != " " && $c != ">"} {set addSpace 1} 
		backwardWord
		set attrBegin [getPos]
		set attrEnd $pos
		set attr [string toupper [getText $attrBegin $attrEnd]]
		set eventAtts [html::GetEventHandlers $tag]
		set allAttrs [concat [html::GetRequired $tag] [string toupper [html::GetOptional $tag]]]
		if {$tag == "INPUT"} {set allAttrs TYPE=}
		set unique 0
		set matches [html::FindLargestMatch allAttrs $attr unique 1]
		if {$matches == ""} {
			selectText $attrBegin $attrEnd
		} else {
			if {[lookAt [pos::math $attrBegin - 1]] == "\""} {set newAttr " "}
			append newAttr $matches
			if {!$html::xhtml && [set i [lsearch [string toupper $eventAtts] "[string trim $newAttr]*"]] >= 0} {
				set ext ""
				if {[string index $newAttr 0] == " "} {set ext " "}
				set newAttr "$ext[string range [lindex $eventAtts $i] 0 [expr {[string length [string trim $newAttr]] - 1}]]"
			} else {
				set newAttr [html::SetCase $newAttr]
			}
			if {$unique} {
				if {[regexp {=} $newAttr]} {
					append newAttr "\"¥¥\""
					if {$HTMLmodeVars(useTabMarks)} {append newAttr "¥¥"}
				} elseif {$html::xhtml} {
					append newAttr "=\"" $newAttr "\""
				}
				if {$addSpace} {append newAttr " "} 
			}
			elec::ReplaceText $attrBegin $attrEnd $newAttr
		}
	}
	return 1
}

#===============================================================================
# ×××× Completion help procs ×××× #
#===============================================================================

proc html::Completechoices {elem attr val} {
	set choices [html::GetAttrChoices $elem $attr] 
	return [html::SetCase [html::FindLargestMatch choices [string toupper $val] dum 1]]
}

proc html::Completeurl {elem attr val} {
	global HTMLmodeVars html::UserURLs
	set newval [html::FindLargestMatch html::UserURLs [quote::Unurl $val]]
	if {[string length [set m [quote::UrlExceptAnchor $newval]]]} {
		return $m
	} else {
		return $val
	}
}

proc html::Completeframetarget {elem attr val} {
	global HTMLmodeVars html::UserTargets
	set choices [concat _self _top _blank _parent ${html::UserTargets}] 
	if {[string length [set m [html::FindLargestMatch choices $val]]]} {
		return $m
	} else {
		return $val
	}
}

proc html::Completecolor {elem attr val} {
	global html::basicColors html::userColors html::ColorName
	set colors [lsort [concat ${html::basicColors} [array names html::userColors]]]
	set unique 0
	set match [html::FindLargestMatch colors $val unique]
	if {$unique} {
		if {[info exist html::userColors($match)]} {
			set match [set html::userColors($match)]
		} elseif {[info exist html::ColorName($match)]} {
			set match [set html::ColorName($match)]
		}
	}
	return $match
}

proc html::Completecontenttype {elem attr val} {
	global HTMLmodeVars
	return [html::FindLargestMatch HTMLmodeVars(contenttypes) $val]
}

proc html::Completecontenttypes {elem attr val {type contenttypes}} {
	global HTMLmodeVars
	set cval $val
	regexp {[, \t\r\n]+([^, \t\r\n]*)$} $cval "" cval
	set newval [html::FindLargestMatch HTMLmodeVars($type) $cval]
	if {$newval == ""} {return $val}
	return "[string range $val 0 [expr {[string length $val] - [string length $cval] - 1}]]$newval"
}

proc html::Completelinktypes {elem attr val} {
	return [html::Completecontenttypes $elem $attr $val linktypes]
}

proc html::Completemediadesc {elem attr val} {
	return [html::Completecontenttypes $elem $attr $val mediatypes]
}
