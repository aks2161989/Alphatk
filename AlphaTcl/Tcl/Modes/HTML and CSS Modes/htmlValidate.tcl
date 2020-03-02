## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlValidate.tcl"
 #                                    created: 99-07-20 17.44.41 
 #                                last update: 2005-02-21 17:52:09 
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
# This file contains procs for validating HTML documents.
#===============================================================================

#===============================================================================
# ×××× Validation ×××× #
#===============================================================================

proc html::FindUnbalancedTags {} {
	global tileLeft tileTop tileWidth errorHeight html::OptionalClosingTags html::EmptyElems browse::separator
	global html::xhtml
	
	if {![llength [winNames]]} {return}
	status::msg "Searching for unbalanced tagsÉ"
	set fil [html::StrippedFrontWindowPath]
	# These may not have an closing tag.
	set empty ${html::EmptyElems}
	lappend empty ?XML !DOCTYPE SPACER WBR EMBED BGSOUND KEYGEN
	# These have an optional closing tag.
	if {$html::xhtml} {
		set closingOptional WINDOW
	} else {
		set closingOptional ${html::OptionalClosingTags}
		lappend closingOptional HEAD BODY HTML WINDOW
	}
	# These have an optional opening tag.
	if {$html::xhtml} {
		set openingOptional {}
	} else {
		set openingOptional {HTML HEAD BODY TBODY}
	}
	
	set tagStack WINDOW
	set pos [minPos]
	while {![catch {search -s -f 1 -r 1 -i 1 -m 0 {<!--|<[^<>]+>} $pos} res]} {
		set tagstart [lindex $res 0]
		set tagend   [lindex $res 1]
		set tagtxt [getText $tagstart $tagend]
		if {[string range $tagtxt 0 3] == "<!--"} {
			# Comment
			if {![catch {search -s -f 1 -r 1 -m 0 -- {-->} $tagstart} res]} {
				set pos [lindex $res 1]
			} else {
				set pos [maxPos]
			}
			continue
		}
		# get element name
		if {![regexp {<(/?[^ \t\r\n/>]+)} $tagtxt tmp tag]} {
			append errtxt "Line [lindex [pos::toRowChar $tagstart] 0]: No element name in tag.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
			set pos $tagend
			continue
		}
		set tag [string toupper $tag]
		# is this a closing tag?
		if {[string index $tag 0] == "/"} {
			set tag [string range $tag 1 end]
			if {[lsearch -exact $empty $tag] >= 0} {
				append errtxt "Line [lindex [pos::toRowChar $tagstart] 0]: $tag may mot have a closing tag.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
			} elseif {[lsearch -exact $tagStack $tag] < 0 && [lsearch -exact $openingOptional $tag] < 0} {
				append errtxt "Line [lindex [pos::toRowChar $tagstart] 0]: Closing $tag tag without a matching opening tag.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
			} else {
				for {set i 0} {$i < [llength $tagStack]} {incr i} {
					if {[set this [lindex $tagStack $i]] != $tag} {
						if {[lsearch -exact $closingOptional $this] < 0} {
							append errtxt "Line [lindex [pos::toRowChar $tagstart] 0]: $this must be closed before $tag.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
						}
					} else {
						break
					}
				}
				set tagStack [lrange $tagStack [expr {$i + 1}] end]
			}
		} else {
			# opening tag
			if {[lsearch -exact $empty $tag] < 0} {
				set tagStack [concat $tag $tagStack]
			} elseif {$html::xhtml && ![regexp {/>$} $tagtxt] && $tag != "?XML" && $tag != "!DOCTYPE"} {
				append errtxt "Line [lindex [pos::toRowChar $tagstart] 0]: The $tag tag is not an empty element tag.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
			}
		}
		set pos $tagend
	}
	# check if there are unclosed tags.
	for {set i 0} {$i < [llength $tagStack]} {incr i} {
		if {[lsearch -exact $closingOptional [set this [lindex $tagStack $i]]] < 0} {
			append errtxt "Line [lindex [pos::toRowChar [maxPos]] 0] : $this must be closed before HTML.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
		}
	}
	if {[info exists errtxt]} {
		new -n "* Errors *" -g $tileLeft $tileTop $tileWidth $errorHeight -m Brws
		insertText "Errors:  (<uparrow> and <downarrow> to browse, <return> to go to file)\r${browse::separator}\r"
		insertText $errtxt
		html::SetWin
	} else {
		alertnote "No unbalanced tags found!"
	}

}

proc html::CheckTagsandAttributes {} {
	html::CheckTags 1
}

proc html::CheckTags {{attributes 0}} {
	global tileLeft tileTop tileWidth errorHeight html::ElemMayContain html::OptionalClosingTags html::EmptyElems browse::separator
	global html::ElemMayContainLoose html::ElemMayContainStrict html::ElemMayContainFrame html::CommentRegexp html::NotInStrict html::xhtml
	if {![llength [winNames]]} {return}
	if {$attributes} {
		status::msg "Checking tags and attributesÉ"
	} else {
		status::msg "Checking tagsÉ"
	}
	set fil [html::StrippedFrontWindowPath]
	
	# These have an optional closing tag.
	if {$html::xhtml} {
		set closingOptional WINDOW
	} else {
		set closingOptional ${html::OptionalClosingTags}
		lappend closingOptional HEAD BODY HTML WINDOW
	}
	html::GetSpec
	set doctype [html::FindDoctype]
	regsub xhtml10 $doctype "" doctype
	if {$doctype == "" && ![catch {search -s -f 1 -r 1 -i 1 -m 0 {<frameset[^<>]+>} [minPos]}]} {
		set doctype "frameset"
	}
	if {$doctype == ""} {set doctype "transitional"}
	# Make some things unknown depending on the doctype.
	if {$doctype == "strict" || $doctype == "xhtml11"} {
		foreach elem [array names html::ElemMayContainStrict] {
			set html::ElemMayContain($elem) [set html::ElemMayContainStrict($elem)]
		}
	}
	if {$doctype == "transitional"} {
		foreach elem [array names html::ElemMayContainLoose] {
			set html::ElemMayContain($elem) [set html::ElemMayContainLoose($elem)]
		}
	} 
	if {$doctype == "frameset"} {
		foreach elem [array names html::ElemMayContainFrame] {
			set html::ElemMayContain($elem) [set html::ElemMayContainFrame($elem)]
		}
	} 
	# Validate
	set nr 0
	set tagName(0) WINDOW
	set tagContent(0) ""
	set pos [minPos]
	while {![catch {search -s -f 1 -r 1 -i 1 -m 0 {<!--|<[^<>]+>} $pos} res]} {
		set tagstart [lindex $res 0]
		set tagend   [lindex $res 1]
		set tagtxt [getText $tagstart $tagend]
		if {[string range $tagtxt 0 3] == "<!--"} {
			set tagtxt "<!--"
			set tagend [pos::math $tagstart + 4]
		}
		set line "Line [lindex [pos::toRowChar $tagstart] 0]:"
		# get element name
		set tag ""
		if {$tagtxt != "<!--" && ![regexp {<(/?[^ \t\r\n/>]+)} $tagtxt "" tag]} {
			append errtxt "$line No element name in tag.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
			set pos $tagend
			continue
		} else {
			set otag $tag
			set tag [string toupper $tag]
		}
		if {[pos::compare $tagstart > $pos]} {
			set prevTxt [getText $pos $tagstart]
		} else {
			set prevTxt ""
		}
		# check for unmatched < in text.
		if {[regexp {<} $prevTxt]} {
			append errtxt "$line Unmatched <.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
		}
		# Check if there is text before the tag.
		if {![regexp {^[ \t\r\n]*$} $prevTxt]} {
			lappend tagContent($nr) text
			set err ""
			html::CheckContent tagName tagContent nr err text
			foreach e $err {
				append errtxt "$line $e\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
			}
		}
		if {$tagtxt == "<!--"} {
			# Comment
			if {![catch {search -s -f 1 -r 1 -m 0 -- {-->} $tagstart} res]} {
				set pos [lindex $res 1]
			} else {
				set pos [maxPos]
			}
			continue
		}
		# Silently ignore !DOCTYPE and ?XML
		if {$tag == "!DOCTYPE" || $tag == "?XML"} {
			set pos $tagend
			continue
		}
		# Check the case
		if {$html::xhtml && $otag != [string tolower $otag]} {
			append errtxt "$line The $tag tag must be in lowercase in XHTML.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
		}
		
		set xtag [string trimleft $tag /]
		if {![info exists html::ElemMayContain($xtag)] && [lsearch -exact ${html::EmptyElems} $xtag] < 0} {
			# Unknown tag?
			append errtxt "$line $xtag is unknown.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
		} elseif {[lsearch -exact ${html::NotInStrict} $xtag] >= 0 && ($doctype == "strict" || $doctype == "xhtml11")} {
			if {$doctype == "strict"} {
				append errtxt "$line $xtag may not be used with the strict DTD.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
			} else {
				append errtxt "$line $xtag may not be used in XHTML 1.1.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
			}
		} elseif {[string index $tag 0] == "/"} {
			# Closing tag
			set tag [string range $tag 1 end]
			# Empty element?
			if {[lsearch -exact ${html::EmptyElems} $tag] >= 0} {
				append errtxt "$line $xtag may mot have a closing tag.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
			}
			while {1} {
				if {$tag == $tagName($nr)} {
					set err ""
					html::PopTag tagName tagContent nr err
					foreach e $err {
						append errtxt "$line $e\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
					}					
					break
				}
				# Closing without matching opening?
				if {[lsearch -exact [array get tagName] $tag] < 0} {
					append errtxt "$line Closing $xtag tag without a matching opening tag.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
					break
				}
				# Silently close those with an optional closing tag.				
				if {[lsearch -exact $closingOptional $tagName($nr)] < 0} {
					append errtxt "$line $tagName($nr) must be closed before $tag.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
				}
				set err ""
				html::PopTag tagName tagContent nr err
				foreach e $err {
					append errtxt "$line $e\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
				}					
			}
			# check if there's anything after </HTML>
			if {$tag == "HTML"} {
				regsub -all ${html::CommentRegexp} [getText $tagend [maxPos]] "" ending
				if {![is::Whitespace $ending]} {
					append errtxt "$line Text after </HTML>.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
				}
				break
			}
		} else {
			# Opening tag
			if {$attributes} {
				set err ""
				html::CheckAttributes $tag [string trimleft $tagtxt "< "] err $tagstart $doctype
				foreach e $err {
					append errtxt "$line $e\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
				}
			}
			# Check empty element tags in XHTML
			if {$html::xhtml && [lsearch -exact ${html::EmptyElems} $xtag] >=0 && ![regexp {/>$} $tagtxt]} {
				append errtxt "$line The $tag tag is not an empty element tag.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
			}
			lappend tagContent($nr) $tag
			set err ""
			html::CheckContent tagName tagContent nr err $tag
			html::PushTag $tag tagName tagContent nr err
			foreach e $err {
				append errtxt "$line $e\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
			}
			# Content of SCRIPT and STYLE end by </
			if {$tag == "SCRIPT" || $tag == "STYLE"} {
				if {![catch {search -s -f 1 -r 1 -m 0 {</} $tagend} res]} {
					set tagend [lindex $res 0]
				} else {
					set tagend [maxPos]
				}
			}
		}
		set pos $tagend
	}
	# check if there are unclosed tags.
	while {$nr > 0} {
		if {[lsearch -exact $closingOptional $tagName($nr)] < 0} {
			append errtxt "$line $tagName($nr) must be closed before HTML.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
		}
		set err ""
		html::PopTag tagName tagContent nr err
		foreach e $err {
			append errtxt "$line $e\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$fil\r"
		}					
	}
	if {[info exists errtxt]} {
		new -n "* Errors *" -g $tileLeft $tileTop $tileWidth $errorHeight -m Brws
		insertText "Errors:  (<uparrow> and <downarrow> to browse, <return> to go to line)\r${browse::separator}\r"
		insertText $errtxt
		html::SetWin
	} else {
		alertnote "No syntax errors found!"
	}
	
}

proc html::CheckContent {name content n e tag {dontclosetbody 0}} {
	upvar $name tagName $content tagContent $n nr $e err
	global html::ElemMayContain html::OptionalClosingTags html::NestRestrictTags html::NestingRestriction html::xhtml
	
	# Is nesting of tag ok?
	if {[lsearch -exact  ${html::NestRestrictTags} $tag] >= 0 && [regexp " [join [set html::NestingRestriction($tag)] |] " " [array get tagName] " t]} {
		lappend err "$tag may not appear anywhere inside [string trim $t]."
	}
	
	# May tag be here?
	if {[lsearch -exact [set html::ElemMayContain($tagName($nr))] $tag] >= 0} {return}
	
	# Insert TBODY in TABLE if possible.
	if {$tagName($nr) == "TABLE" && !$html::xhtml} {
		set tagContent($nr) [lreplace $tagContent($nr) end end]
		lappend tagContent($nr) TBODY
		html::PushTag TBODY tagName tagContent nr err
		lappend tagContent($nr) $tag
		html::CheckContent tagName tagContent nr err $tag 1
		return
	}
	# Insert HEAD or BODY in HTML if possible.
	if {$tagName($nr) == "HTML" && !$html::xhtml} {
		if {$tagContent($nr) == $tag} {
			set tagContent($nr) HEAD
			html::PushTag HEAD tagName tagContent nr err
			lappend tagContent($nr) $tag
			html::CheckContent tagName tagContent nr err $tag
			return
		} elseif {[lrange $tagContent($nr) [expr {[llength $tagContent($nr)] - 2}] end] == [list HEAD $tag] && [lcontains html::ElemMayContain(HTML) BODY]} {
			set tagContent($nr) [lreplace $tagContent($nr) end end BODY]
			html::PushTag BODY tagName tagContent nr err
			lappend tagContent($nr) $tag
			html::CheckContent tagName tagContent nr err $tag
			return
		}
	}
	# Insert BODY in NOFRAMES if possible.
	if {$tagName($nr) == "NOFRAMES" && [set html::ElemMayContain(NOFRAMES)] == "BODY" && $tagContent($nr) == $tag && !$html::xhtml} {
		set tagContent($nr) BODY
		html::PushTag BODY tagName tagContent nr err
		lappend tagContent($nr) $tag
		html::CheckContent tagName tagContent nr err $tag
		return
	}
	
	# Insert HTML if possible.
	if {$tagName($nr) == "WINDOW" && $tagContent($nr) == $tag} {
		if {$html::xhtml} {lappend err "First element must be an HTML element."}
		set tagContent($nr) HTML
		html::PushTag HTML tagName tagContent nr err
		lappend tagContent($nr) $tag
		html::CheckContent tagName tagContent nr err $tag
		return
	}
	# Implicitely insert optional closing tags.
	if {!$html::xhtml && (([lsearch -exact ${html::OptionalClosingTags} $tagName($nr)] >= 0 && !($tagName($nr) == "TBODY" && $dontclosetbody)) || $tagName($nr) == "HEAD")} {
		set tagContent($nr) [lreplace $tagContent($nr) end end]
		html::PopTag tagName tagContent nr err
		lappend tagContent($nr) $tag
		html::CheckContent tagName tagContent nr err $tag
		return
	} else {
		lappend err "$tagName($nr) may not contain $tag."
	}
}

proc html::PushTag {tag name content n e} {
	upvar $name tagName $content tagContent $n nr $e err
	global html::EmptyElems
	if {[info commands html::MustNotContainCheck$tagName($nr)] != "" || [info commands ::html::MustNotContainCheck$tagName($nr)] != ""} {
		html::MustNotContainCheck$tagName($nr) $tagContent($nr) $tag err
	}
	if {[lsearch -exact ${html::EmptyElems} $tag] < 0} {
		incr nr
		set tagName($nr) $tag
		set tagContent($nr) ""
	}
}

proc html::PopTag {name content n e} {
	upvar $name tagName $content tagContent $n nr $e err
	if {[info commands html::MustContainCheck$tagName($nr)] != "" || [info commands ::html::MustContainCheck$tagName($nr)] != ""} {
		html::MustContainCheck$tagName($nr) $tagContent($nr) err
	}
	unset tagName($nr)
	unset tagContent($nr)
	incr nr -1
}

proc html::MustContainCheckBLOCKQUOTE {content e} {
	upvar $e err
	global html::ElemMayContain html::ElemMayContainLoose html::xhtml
	if {$html::xhtml || [set html::ElemMayContain(BLOCKQUOTE)] == [set html::ElemMayContainLoose(BLOCKQUOTE)]} {return}
	if {$content == ""} {lappend err "BLOCKQUOTE must contain at least one block-level or SCRIPT element."}	
}

proc html::MustContainCheckBODY {content e} {
	upvar $e err
	global html::ElemMayContain html::ElemMayContainLoose html::xhtml
	if {$html::xhtml || [set html::ElemMayContain(BODY)] == [set html::ElemMayContainLoose(BODY)]} {return}
	if {$content == ""} {lappend err "BODY must contain at least one block-level or SCRIPT element."}	
}

proc html::MustContainCheckDIR {content e} {
	upvar $e err
	if {$content == ""} {lappend err "DIR must contain at least one LI element."}
}

proc html::MustContainCheckMENU {content e} {
	upvar $e err
	if {$content == ""} {lappend err "MENU must contain at least one LI element."}
}

proc html::MustContainCheckDL {content e} {
	upvar $e err
	if {$content == ""} {lappend err "DL must contain at least one DT or DD element."}
}

proc html::MustContainCheckFIELDSET {content e} {
	upvar $e err
	global html::xhtml
	if {$html::xhtml} {return}
	if {$content == ""} {lappend err "FIELDSET must contain a LEGEND element."}
}

proc html::MustNotContainCheckFIELDSET {content tag e} {
	upvar $e err
	if {$tag == "LEGEND" && [regsub -all "LEGEND" $content "" ""] > 1} {lappend err "FIELDSET may only contain one LEGEND element."}
	if {$tag != "LEGEND" && $content == $tag} {lappend err "LEGEND must be the first element inside FIELDSET."}
}

proc html::MustContainCheckFORM {content e} {
	upvar $e err
	global html::ElemMayContain html::ElemMayContainLoose html::xhtml
	if {$html::xhtml || [set html::ElemMayContain(FORM)] == [set html::ElemMayContainLoose(FORM)]} {return}
	if {$content == ""} {lappend err "FORM must contain at least one block-level or SCRIPT element."}	
}

proc html::MustContainCheckFRAMESET {content e} {
	upvar $e err
	global html::xhtml
	if {$html::xhtml} {return}
	if {[lsearch -exact $content FRAME] < 0 && [lsearch -exact $content FRAMESET] < 0} {lappend err "FRAMESET must contain at least one FRAME or FRAMESET element."}
}

proc html::MustNotContainCheckFRAMESET {content tag e} {
	upvar $e err
	if {$tag == "NOFRAMES" && [regsub -all "NOFRAMES" $content "" ""] > 1} {lappend err "FRAMESET may only contain one NOFRAMES element."}	
}

proc html::MustContainCheckHEAD {content e} {
	upvar $e err
	if {[lsearch -exact $content TITLE] < 0} {lappend err "HEAD must contain a TITLE element."}
}

proc html::MustNotContainCheckHEAD {content tag e} {
	upvar $e err
	if {$tag == "BASE" && [regsub -all "BASE" $content "" ""] > 1} {lappend err "HEAD may only contain one BASE element."}
	if {$tag == "ISINDEX" && [regsub -all "ISINDEX" $content "" ""] > 1} {lappend err "HEAD may only contain one ISINDEX element."}
	if {$tag == "TITLE" && [regsub -all "TITLE" $content "" ""] > 1} {lappend err "HEAD may only contain one TITLE element."}
}

proc html::MustContainCheckHTML {content e} {
	upvar $e err
	global html::ElemMayContain html::ElemMayContainFrame
	if {[lsearch -exact $content HEAD] < 0} {lappend err "HTML must contain a HEAD element."}
	if {[set html::ElemMayContain(HTML)] == [set html::ElemMayContainFrame(HTML)]} {
		if {![regsub -all "FRAMESET" $content "" ""]} {
			lappend err "HTML must contain a FRAMESET element."
		}
	} elseif {![regsub -all "BODY" $content "" ""]} {
		lappend err "HTML must contain a BODY element."
	}		
}

proc html::MustNotContainCheckHTML {content tag e} {
	upvar $e err
	global html::ElemMayContain html::ElemMayContainFrame
	if {$tag != "HEAD" && $content == $tag} {lappend err "HEAD must be the first element inside HTML."}
	if {$tag == "HEAD" && [regsub -all "HEAD" $content "" ""] > 1} {lappend err "HTML may only contain one HEAD element."}
	if {$tag == "BODY" && [set html::ElemMayContain(HTML)] != [set html::ElemMayContainFrame(HTML)] && 
	[regsub -all "BODY" $content "" ""] > 1} {lappend err "HTML may only contain one BODY element."}
	if {$tag == "FRAMESET" && [set html::ElemMayContain(HTML)] == [set html::ElemMayContainFrame(HTML)] && 
	[regsub -all "FRAMESET" $content "" ""] > 1} {lappend err "HTML may only contain one FRAMESET element."}
}

proc html::MustContainCheckMAP {content e} {
	upvar $e err
	if {$content == ""} {lappend err "MAP must contain at least one block-level or AREA element."}
}

proc html::MustNotContainCheckMAP {content tag e} {
	upvar $e err
	global html::xhtml
	if {!$html::xhtml} {return}
	if {[lcontains content AREA] && [llength $content] > [regsub -all "AREA" $content "" ""]} {
		lappend err "When MAP contains AREA elements it may not contain other elements."
	}
}

proc html::MustContainCheckNOSCRIPT {content e} {
	upvar $e err
	global html::ElemMayContain html::ElemMayContainLoose html::xhtml
	if {$html::xhtml} {return}
	if {[set html::ElemMayContain(NOSCRIPT)] == [set html::ElemMayContainLoose(NOSCRIPT)]} {return}
	if {$content == ""} {lappend err "NOSCRIPT must contain at least one block-level element."}	
}

proc html::MustContainCheckOL {content e} {
	upvar $e err
	if {$content == ""} {lappend err "OL must contain at least one LI element."}
}

proc html::MustContainCheckOPTGROUP {content e} {
	upvar $e err
	if {$content == ""} {lappend err "OPTGROUP must contain at least one OPTION element."}
}

proc html::MustContainCheckSELECT {content e} {
	upvar $e err
	if {$content == ""} {lappend err "SELECT must contain at least one OPTGROUP or OPTION element."}
}

proc html::MustContainCheckTABLE {content e} {
	upvar $e err
	if {![regsub "TBODY" $content "" ""]} {lappend err "TABLE must contain at least one TBODY element."}	
}

proc html::MustNotContainCheckTABLE {content tag e} {
	upvar $e err
	global html::xhtml
	switch -- $tag {
		CAPTION {
			if {[regsub -all "CAPTION" $content "" ""] > 1} {
				lappend err "TABLE may only contain one CAPTION element."
			} elseif {[llength $content] > 1} {
				lappend err "CAPTION must be the first element inside TABLE."
			}
		}
		COL -
		COLGROUP {
			if {$tag == "COL" && [regsub "COLGROUP" $content "" ""] ||
			$tag == "COLGROUP" && [regsub "COL " $content " " ""]} {
				lappend err "TABLE may not contain both COL and COLGROUP elements."
			}
			if {[regsub "THEAD|TFOOT|TBODY" $content "" ""]} {lappend err "$tag must appear before THEAD, TFOOT, and TBODY inside TABLE."}
		}
		THEAD {
			if {[regsub -all "THEAD" $content "" ""] > 1} {lappend err "TABLE may only contain one THEAD element."}
			if {[regsub "TFOOT|TBODY" $content "" ""]} {lappend err "THEAD must appear before TFOOT and TBODY inside TABLE."}
		}
		TFOOT {
			if {[regsub -all "TFOOT" $content "" ""] > 1} {lappend err "TABLE may only contain one TFOOT element."}
			if {[regsub "TBODY" $content "" ""]} {lappend err "TFOOT must appear before TBODY inside TABLE."}
		}
		TBODY -
		TR {
			if {!$html::xhtml} {return}
			if {[lcontains content TBODY] && [lcontains content TR]} {
				lappend err "TABLE may not contain both TBODY and TR elements."
			}
		}
	}
}

proc html::MustContainCheckTBODY {content e} {
	upvar $e err
	if {$content == ""} {lappend err "TBODY must contain at least one TR element."}
}

proc html::MustContainCheckTHEAD {content e} {
	upvar $e err
	if {$content == ""} {lappend err "THEAD must contain at least one TR element."}
}

proc html::MustContainCheckTFOOT {content e} {
	upvar $e err
	if {$content == ""} {lappend err "TFOOT must contain at least one TR element."}
}

proc html::MustContainCheckTR {content e} {
	upvar $e err
	if {$content == ""} {lappend err "TR must contain at least one TD or TH element."}
}

proc html::MustContainCheckUL {content e} {
	upvar $e err
	if {$content == ""} {lappend err "UL must contain at least one LI element."}
}

#===============================================================================
# ×××× Attributes ×××× #
#===============================================================================

proc html::CheckAttributes {tag txt e pos doctype} {
	upvar $e err
	global html::xhtml html::xhtmlversion
	if {$tag == "LI"} {
		html::FindList tag $pos
	}
	html::ExtractAttrValues $txt attrs attrVals err " of $tag" $html::xhtml
	set oattrs $attrs
	set attrs [string toupper $attrs]
	if {$tag == "INPUT"} {
		set typeIndex [lsearch -exact $attrs "TYPE="]
		if {$typeIndex >= 0 } {
			set tag [string toupper [lindex $attrVals $typeIndex]]
			if {$html::xhtml} {
				if {[lindex $oattrs $typeIndex] != [string tolower [lindex $oattrs $typeIndex]]} {
					lappend err "The attribute TYPE of INPUT must be in lowercase in XHTML."
				}
				if {[lindex $attrVals $typeIndex] != [string tolower [lindex $attrVals $typeIndex]]} {
					lappend err "INPUT TYPE=\"$tag\": Value must be in lowercase in XHTML."
				}
			}
			set tag "INPUT TYPE=${tag}"
			# Remove TYPE attribute from list.
			set oattrs [lreplace $oattrs $typeIndex $typeIndex]
			set attrs [lreplace $attrs $typeIndex $typeIndex]
			set attrVals [lreplace $attrVals $typeIndex $typeIndex]
		} else {
			set tag "INPUT TYPE=TEXT"
		} 

	} 
	set req [html::GetRequired $tag]
	set allAttrs [string toupper [concat $req [html::GetOptional $tag 1]]]
	set exp "\[ \n\r\t]+([join [concat [html::GetExtensions $tag] [set notin [html::GetNotIn $tag]]] |])"
	regsub -all $exp " $allAttrs" " " allAttrs
	set depr ""
	if {$doctype == "strict" || $doctype == "xhtml11"} {
		set exp "\[ \n\r\t]+([join [set depr [concat TARGET= [html::GetDeprecated $tag]]] |])"
		regsub -all $exp " $allAttrs" " " allAttrs
	}
	foreach a $req {
		if {[lsearch -exact $attrs $a] < 0} {
			lappend err "Required attribute [string trim $a =] of $tag missing."
		}
	}
	set depr [string toupper $depr]
	set notin [string toupper $notin]
	for {set i 0} {$i<[llength $attrs]} {incr i} {
		set a [lindex $attrs $i]
		if {$html::xhtml && [lindex $oattrs $i] != [string tolower [lindex $oattrs $i]]} {
			lappend err "The attribute [string trim $a =] of $tag must be in lowercase in XHTML."
		}
		if {[lsearch -exact $allAttrs [string trim $a =]] >= 0} {
			set a [string trim $a =]
		}
		if {[lsearch -exact $allAttrs $a] < 0} {
			if {[lcontains notin $a] || [lcontains notin [string trim $a =]]} {
				if {!$html::xhtml} {
					lappend err "The attribute [string trim $a =] of $tag can only be used in XHTML."
				} else {
					lappend err "The attribute [string trim $a =] of $tag cannot be used in XHTML ${html::xhtmlversion}."
				}
			} elseif {[lcontains depr $a] || [lcontains depr [string trim $a =]]} {
				if {$doctype == "xhtml11"} {
					lappend err "The attribute [string trim $a =] of $tag cannot be used in XHTML ${html::xhtmlversion}."
				} else {
					lappend err "The attribute [string trim $a =] of $tag may not be used with the strict DTD."
				}
			} else {
				lappend err "Unknown attribute [string trim $a =] of $tag."
			}
			continue
		}
		set attrType [html::GetAttrType $tag $a]
		if {[info commands html::CheckAttribute$attrType] != "" || [info commands ::html::CheckAttribute$attrType] != ""} {
			html::CheckAttribute$attrType $tag $a [string trim [lindex $attrVals $i]] err
		}
	}
	
}

# flag
proc html::CheckAttributeflag {tag attr val e} {
	upvar $e err
	global html::xhtml
	if {$val != "1" && [string toupper $val] != $attr} {
		lappend err "$tag $attr=\"$val\": Incorrect value."
	} elseif {$val == "1" && $html::xhtml} {
		lappend err "Minimized form of $attr in $tag tag not valid in XHTML."
	}
}

# color
proc html::CheckAttributecolor {tag attr val e} {
	upvar $e err
	if {[html::CheckColorNumber $val] == 0} {
		lappend err "$tag $attr\"$val\": Invalid color number."
	}
}

# choices 
proc html::CheckAttributechoices {tag attr val e} {
	upvar $e err
	global html::xhtml
	if {[lsearch -exact [html::GetAttrChoices $tag $attr] [string toupper $val]] < 0} {
		lappend err "$tag $attr\"$val\": Unknown choice."
	} elseif {$html::xhtml && $val != [string tolower $val]} {
		lappend err "$tag $attr\"$val\": Value must be in lowercase in XHTML."
	}
}

# length
proc html::CheckAttributelength {tag attr val e} {
	upvar $e err
	if {[set res [html::CheckAttrNumber $tag $attr $val 1]] != 1} {
		lappend err "$tag $attr\"$val\": $res"
	}
}

# integer
proc html::CheckAttributeinteger {tag attr val e} {
	upvar $e err
	if {[set res [html::CheckAttrNumber $tag $attr $val 0]] != 1} {
		lappend err "$tag $attr\"$val\": $res"
	}
}

#id 
proc html::CheckAttributeid {tag attr val e} {
	upvar $e err
	if {![html::CheckId $val]} {
		lappend err "$tag $attr\"$val\": Value must begin with a letter and only containg letters, digits, and '_' '-' ':' '.'"
	}		
}

#ids 
proc html::CheckAttributeids {tag attr val e} {
	upvar $e err
	if {![html::CheckIds $val]} {
		lappend err "$tag $attr\"$val\": Value must be a list of words beginning with a letter and only containg letters, digits, and '_' '-' ':' '.'"
	}		
}

# multilength
proc html::CheckAttributemultilength {tag attr val e} {
	upvar $e err
	if {[set res [html::CheckAttrNumber $tag $attr $val 1 1]] != 1} {
		lappend err "$tag $attr\"$val\": $res"
	}
}

# multilengths
proc html::CheckAttributemultilengths {tag attr val e {multilength 1}} {
	upvar $e err
	foreach l [split $val ,] {
		set l [string trim $l]
		set numcheck [html::CheckAttrNumber $tag $attr $l 1 $multilength]
		if {$numcheck != 1} {
			lappend err "$tag $attr\"$val\": $numcheck"
			break
		}
	}
}

# coords
proc html::CheckAttributecoords {tag attr val e} {
	upvar $e err
	foreach l [split $val ,] {
		set l [string trim $l]
		set numcheck [html::CheckAttrNumber $tag $attr $l 1 0]
		if {$numcheck != 1} {
			lappend err "$tag $attr\"$val\": $numcheck"
			break
		}
	}
}

# oltype
proc html::CheckAttributeoltype {tag attr val e} {
	upvar $e err
	if {[lsearch -exact [html::GetAttrChoices $tag $attr] $val] < 0} {
		lappend err "$tag $attr\"$val\": Unknown choice."
	}
}

# character
proc html::CheckAttributecharacter {tag attr val e} {
	upvar $e err
	if {[string length $val] != 1} {
		lappend err "$tag $attr\"$val\": Only a single character is allowed."
	}
}

# datetime
proc html::CheckAttributedatetime {tag attr val e} {
	upvar $e err
	if {[regexp {^([0-9]+)-([0-9]+)-([0-9]+)T([0-9]+):([0-9]+):([0-9]+)(Z|[-+][0-9]+:[0-9]+)$} $val "" Y M D h m s tzd]} {
		if {[catch {html::CheckDateTime [list $Y $M $D $h $m $s $tzd]} res]} {
			lappend err "$tag $attr\"$val\": $res"
		}
	} else {
		lappend err "$tag $attr\"$val\": Incorrect date and time."
	}
}

#===============================================================================
# ×××× Specification ×××× #
#===============================================================================

# Empty elements
set html::EmptyElems {BASEFONT BR AREA LINK IMG PARAM HR INPUT COL FRAME ISINDEX BASE META}

proc html::GetSpec {} {
	global html::NestRestrictTags html::NestingRestriction html::ElemMayContain html::ElemMayContainLoose
	global html::ElemMayContainFrame html::ElemMayContainStrict html::xhtml
	unset -nocomplain html::NestRestrictTags html::NestingRestriction html::ElemMayContain \
	  html::ElemMayContainLoose html::ElemMayContainFrame html::ElemMayContainStrict
	if {$html::xhtml} {
		html::XHTMLSpec
	} else {
		html::HTMLSpec
	}
}

proc html::XHTMLSpec {} {
	global html::NestRestrictTags html::NestingRestriction html::ElemMayContain html::ElemMayContainLoose
	global html::ElemMayContainFrame html::ElemMayContainStrict

	set _specialextra {OBJECT APPLET IMG MAP IFRAME}
	set _specialbasic {BR SPAN BDO}
	set _special [concat $_specialextra $_specialbasic]
	set _fontstyleextra {BIG SMALL FONT BASEFONT}
	set _fontstylebasic {TT I B U S STRIKE}
	set _fontstyle [concat $_fontstyleextra $_fontstylebasic]
	set _phraseextra {SUB SUP}
	set _phrasebasic {EM STRONG DFN CODE Q SAMP KBD VAR CITE ABBR ACRONYM}
	set _phrase [concat $_phraseextra $_phrasebasic]
	set _inlineforms {INPUT SELECT TEXTAREA LABEL BUTTON}
	set _miscinline {INS DEL SCRIPT}
	set _misc [concat NOSCRIPT $_miscinline]
	set _inline [concat A $_special $_fontstyle $_phrase $_inlineforms]
	set _Inline [concat text $_inline $_miscinline]
	set _heading {H1 H2 H3 H4 H5 H6}
	set _lists {UL OL DL MENU DIR}
	set _blocktext {PRE HR BLOCKQUOTE ADDRESS CENTER}
	set _block [concat P $_heading DIV $_lists $_blocktext ISINDEX FIELDSET TABLE]
	set _Block [concat $_block FORM $_misc]
	set _Flow [concat text $_block FORM $_inline $_misc]
	
	# Tags with restricted nesting
	set html::NestRestrictTags [list A PRE BUTTON LABEL FORM]

	set html::NestingRestriction(A) A
	set html::NestingRestriction(PRE) {IMG OBJECT BIG SMALL SUB SUP}
	set html::NestingRestriction(BUTTON) {INPUT SELECT TEXTAREA LABEL BUTTON FORM FIELDSET IFRAME ISINDEX}
	set html::NestingRestriction(LABEL) LABEL
	set html::NestingRestriction(FORM) FORM
	
	# Define what each element mayContain contain
	foreach i [concat $_phrase $_fontstyle $_heading BDO CAPTION DT LABEL LEGEND P SPAN] {
		set html::ElemMayContain($i) $_Inline
	}
	unset html::ElemMayContain(BASEFONT)
	foreach i {CENTER DD DEL DIV IFRAME INS LI TD TH} {
		set html::ElemMayContainLoose($i) [concat $_Flow NOFRAMES]
		set html::ElemMayContainStrict($i) $_Flow
		set html::ElemMayContainFrame($i) $_Flow
	}
	foreach i $_lists {
		set html::ElemMayContain($i) LI
	}

	set html::ElemMayContain(A) [concat text $_special $_fontstyle $_phrase $_inlineforms $_miscinline]
	set html::ElemMayContainLoose(ADDRESS) [concat text $_inline $_miscinline P]
	set html::ElemMayContainStrict(ADDRESS) $_Inline
	set html::ElemMayContainFrame(ADDRESS) [concat text $_inline $_miscinline P]
	set html::ElemMayContainLoose(APPLET) [concat text PARAM $_block NOFRAMES FORM $_inline $_misc]
	set html::ElemMayContainFrame(APPLET) [concat text PARAM $_block FORM $_inline $_misc]
	set html::ElemMayContainLoose(BLOCKQUOTE) [concat $_Flow NOFRAMES]
	set html::ElemMayContainStrict(BLOCKQUOTE) $_Block
	set html::ElemMayContainFrame(BLOCKQUOTE) $_Flow
	set html::ElemMayContainLoose(BODY) [concat $_Flow NOFRAMES]
	set html::ElemMayContainStrict(BODY) $_Block
	set html::ElemMayContainFrame(BODY) $_Flow
	set html::ElemMayContainLoose(BUTTON) [concat text P $_heading DIV $_lists $_blocktext NOFRAMES \
      TABLE BR SPAN BDO OBJECT APPLET IMG MAP $_fontstyle $_phrase $_misc]
	set html::ElemMayContainStrict(BUTTON) [concat text P $_heading DIV $_lists $_blocktext \
      TABLE BR SPAN BDO OBJECT APPLET IMG MAP $_fontstyle $_phrase $_misc]
	set html::ElemMayContainFrame(BUTTON) [concat text P $_heading DIV $_lists $_blocktext \
      TABLE BR SPAN BDO OBJECT APPLET IMG MAP $_fontstyle $_phrase $_misc]
	set html::ElemMayContain(COLGROUP) COL
	set html::ElemMayContain(DL) {DT DD}
	set html::ElemMayContainLoose(FIELDSET) [concat text LEGEND $_block NOFRAMES FORM $_inline $_misc]
	set html::ElemMayContainStrict(FIELDSET) [concat text LEGEND $_block FORM $_inline $_misc]
	set html::ElemMayContainFrame(FIELDSET) [concat text LEGEND $_block FORM $_inline $_misc]
	set html::ElemMayContainLoose(FORM) [concat text $_block NOFRAMES $_inline $_misc]
	set html::ElemMayContainStrict(FORM) [concat $_block $_misc]
	set html::ElemMayContainFrame(FORM) [concat text $_block $_inline $_misc]
	set html::ElemMayContain(FRAMESET) {FRAMESET FRAME NOFRAMES}
	set html::ElemMayContain(HEAD) [concat BASE TITLE SCRIPT STYLE META LINK OBJECT ISINDEX]
	set html::ElemMayContainLoose(HTML) {HEAD BODY}
	set html::ElemMayContainStrict(HTML) {HEAD BODY}
	set html::ElemMayContainFrame(HTML) {HEAD FRAMESET}
	set html::ElemMayContainLoose(MAP) [concat $_block NOFRAMES FORM $_misc AREA]
	set html::ElemMayContainStrict(MAP) [concat $_block FORM $_misc AREA]
	set html::ElemMayContainFrame(MAP) [concat $_block FORM $_misc AREA]
	set html::ElemMayContainLoose(NOFRAMES) [concat $_Flow NOFRAMES]
	set html::ElemMayContainFrame(NOFRAMES) BODY
	set html::ElemMayContainLoose(NOSCRIPT) [concat $_Flow NOFRAMES]
	set html::ElemMayContainStrict(NOSCRIPT) $_Block
	set html::ElemMayContainFrame(NOSCRIPT) $_Flow
	set html::ElemMayContainLoose(OBJECT) [concat text PARAM $_block NOFRAMES FORM $_inline $_misc]
	set html::ElemMayContainStrict(OBJECT) [concat text PARAM $_block FORM $_inline $_misc]
	set html::ElemMayContainFrame(OBJECT) [concat text PARAM $_block FORM $_inline $_misc]
	set html::ElemMayContain(OPTGROUP) OPTION
	set html::ElemMayContain(OPTION) text
	set html::ElemMayContain(PRE) [concat text A $_specialbasic $_fontstylebasic $_phrasebasic \
	  $_inlineforms $_miscinline]
	set html::ElemMayContain(SCRIPT) text
	set html::ElemMayContain(SELECT) {OPTGROUP OPTION}
	set html::ElemMayContain(STYLE) text
	set html::ElemMayContain(TABLE) {CAPTION COL COLGROUP THEAD TBODY TFOOT TR}
	set html::ElemMayContain(TBODY) TR
	set html::ElemMayContain(THEAD) TR
	set html::ElemMayContain(TFOOT) TR
	set html::ElemMayContain(TEXTAREA) text
	set html::ElemMayContain(TITLE) text
	set html::ElemMayContain(TR) {TD TH}
	# Dummy tag to start with.
	set html::ElemMayContain(WINDOW) HTML
}

proc html::HTMLSpec {} {
	global html::NestRestrictTags html::NestingRestriction html::ElemMayContain html::ElemMayContainLoose
	global html::ElemMayContainFrame html::ElemMayContainStrict
	
	set _headmisc {SCRIPT STYLE META LINK OBJECT}
	set _headContent {TITLE ISINDEX BASE}
	set _heading {H1 H2 H3 H4 H5 H6}
	set _lists {UL OL DIR MENU}
	set _preformatted {PRE}
	set _fontstyle {TT I B U S STRIKE BIG SMALL}
	set _phrase {EM STRONG DFN CODE SAMP KBD VAR CITE ABBR ACRONYM}
	set _special {A IMG APPLET OBJECT FONT BASEFONT BR SCRIPT MAP Q SUB SUP SPAN BDO IFRAME}
	set _formctrl {INPUT SELECT TEXTAREA LABEL BUTTON}
	set _inline [concat text $_fontstyle $_phrase $_special $_formctrl]
	set _block [concat P $_heading $_lists $_preformatted DL DIV CENTER NOSCRIPT NOFRAMES BLOCKQUOTE FORM ISINDEX HR TABLE FIELDSET ADDRESS]
	set _flow [concat $_inline $_block]

	# Tags with restricted nesting
	set html::NestRestrictTags [concat $_formctrl $_block A LABEL IFRAME IMG OBJECT APPLET BIG SMALL SUB SUP FONT BASEFONT STYLE META LINK INS DEL]

	foreach i {IMG OBJECT APPLET BIG SMALL SUB SUP FONT BASEFONT} {
		set html::NestingRestriction($i) PRE
	}
	foreach i [concat $_formctrl IFRAME A] {
		set html::NestingRestriction($i) BUTTON
	}
	foreach i $_block {
		set html::NestingRestriction($i) {DIR MENU}
	}
	foreach i {STYLE META LINK} {
		set html::NestingRestriction($i) BODY
	}
	foreach i {INS DEL} {
		set html::NestingRestriction($i) HEAD
	}

	lappend html::NestingRestriction(A) A
	lappend html::NestingRestriction(ISINDEX) BUTTON
	lappend html::NestingRestriction(FIELDSET) BUTTON
	lappend html::NestingRestriction(LABEL) LABEL
	lappend html::NestingRestriction(NOFRAMES) NOFRAMES
	lappend html::NestingRestriction(FORM) FORM BUTTON

	# Define what each element mayContain contain
	foreach i [concat $_fontstyle $_phrase $_heading SUB SUP SPAN BDO FONT A P PRE Q DT LABEL LEGEND CAPTION] {
		set html::ElemMayContain($i) [concat $_inline INS DEL STYLE META LINK]
	}
	foreach i {DIV CENTER INS DEL DD LI BUTTON TH TD IFRAME} {
		set html::ElemMayContain($i) [concat $_flow INS DEL STYLE META LINK]
	}

	foreach i $_lists {
		set html::ElemMayContain($i) LI
	}
	set html::ElemMayContainLoose(BODY) [concat $_flow INS DEL]
	set html::ElemMayContainStrict(BODY) [concat $_block SCRIPT INS DEL]
	set html::ElemMayContainFrame(BODY) [concat $_flow INS DEL]
	set html::ElemMayContainLoose(BLOCKQUOTE) [concat $_flow INS DEL STYLE META LINK]
	set html::ElemMayContainStrict(BLOCKQUOTE) [concat $_block SCRIPT INS DEL STYLE META LINK]
	set html::ElemMayContainFrame(BLOCKQUOTE) [concat $_flow INS DEL STYLE META LINK]
	set html::ElemMayContainLoose(FORM) [concat $_flow INS DEL STYLE META LINK]
	set html::ElemMayContainStrict(FORM) [concat $_block SCRIPT INS DEL STYLE META LINK]
	set html::ElemMayContainFrame(FORM) [concat $_flow INS DEL STYLE META LINK]
	set html::ElemMayContainLoose(ADDRESS) [concat $_inline P INS DEL STYLE META LINK]
	set html::ElemMayContainStrict(ADDRESS) [concat $_inline INS DEL STYLE META LINK]
	set html::ElemMayContainFrame(ADDRESS) [concat $_inline P INS DEL STYLE META LINK]
	set html::ElemMayContain(MAP) [concat $_block AREA INS DEL STYLE META LINK]
	set html::ElemMayContain(OBJECT) [concat $_flow PARAM INS DEL STYLE META LINK]
	set html::ElemMayContain(APPLET) [concat $_flow PARAM INS DEL STYLE META LINK]
	set html::ElemMayContain(DL) {DT DD}
	set html::ElemMayContain(SELECT) {OPTGROUP OPTION}
	set html::ElemMayContain(OPTGROUP) OPTION
	set html::ElemMayContain(OPTION) text
	set html::ElemMayContain(TEXTAREA) text
	set html::ElemMayContain(FIELDSET) [concat $_flow LEGEND INS DEL STYLE META LINK]
	set html::ElemMayContain(TABLE) {CAPTION COL COLGROUP THEAD TBODY TFOOT}
	set html::ElemMayContain(TBODY) TR
	set html::ElemMayContain(THEAD) TR
	set html::ElemMayContain(TFOOT) TR
	set html::ElemMayContain(COLGROUP) COL
	set html::ElemMayContain(TR) {TD TH}
	set html::ElemMayContain(FRAMESET) {FRAMESET FRAME NOFRAMES}
	set html::ElemMayContainLoose(NOFRAMES) [concat $_flow INS DEL STYLE META LINK]
	set html::ElemMayContainFrame(NOFRAMES) {BODY}
	set html::ElemMayContainLoose(NOSCRIPT) [concat $_flow INS DEL STYLE META LINK]
	set html::ElemMayContainStrict(NOSCRIPT) [concat $_block INS DEL STYLE META LINK]
	set html::ElemMayContain(HEAD) [concat $_headContent $_headmisc]
	set html::ElemMayContain(TITLE) text
	set html::ElemMayContain(STYLE) text
	set html::ElemMayContain(SCRIPT) text
	set html::ElemMayContainLoose(HTML) {HEAD BODY}
	set html::ElemMayContainStrict(HTML) {HEAD BODY}
	set html::ElemMayContainFrame(HTML) {HEAD FRAMESET}

	# Dummy tag to start with.
	set html::ElemMayContain(WINDOW) HTML
}

