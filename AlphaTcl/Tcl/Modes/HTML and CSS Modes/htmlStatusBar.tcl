## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlStatusBar.tcl"
 #                                    created: 96-06-16 14.24.31 
 #                                last update: 01/27/2005 {05:52:04 PM} 
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
# This file contains procs for giving values to attributes in the status bar.
#===============================================================================

# Opening or only tag of an element - include attributes
# Status bar for each attribute.
# Return empty string if user skips an attribute which must be used.
proc html::OpenElemStatusBar {elem used wrPos {values ""} {addNotUsed 0} {addHidden 0} {absPos ""}} {
	global HTMLmodeVars
	global html::WrapPos html::AbsPos
	global html::ActiveWidth html::ActiveHeight html::ActiveElem html::ActiveUsed
	
	if {![string length $used]} {set used $elem}
	set elem [set html::ActiveElem [string toupper $elem]]
	set used [set html::ActiveUsed [string toupper $used]]
	
	# if there are attributes to ask about, do so
	set reqatts [html::GetRequired $used]
	set optatts [html::GetOptional $used]
	set allatts [html::GetUsed $used $reqatts $optatts]
	regsub -all "\[ \n\r\t]+([join $allatts |])" " $optatts" " " notUsedAtts
	if {$addNotUsed} {
		append allatts " " $notUsedAtts
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
	
	set useatts $allatts
	append allatts " " $notUsedAtts
	set html::ActiveWidth ""
	set html::ActiveHeight ""
	
	# wrapping
	if {$absPos == ""} {
		set html::AbsPos [getPos]
	} else {
		set html::AbsPos $absPos
	}
	set html::WrapPos [expr {$wrPos == -1 ? [lindex [pos::toRowCol [getPos]] 1] : $wrPos}]
	incr html::WrapPos [expr {[string length $text] + 1}]
	for {set i 0} {$i < [llength $allatts] && [llength $useatts]} {incr i} {
		set attr [lindex $allatts $i]
		if {[lcontains reqatts $attr]} {
			set required 1
		} else {
			set required 0
		}
		set attrType [html::GetAttrType $used $attr]
		if {[expr {!$i}] && $HTMLmodeVars(promptNoisily)} {beep}
		set flash ""
		if {[catch {html::StatusBar$attrType $elem $used $attr $required $flash [lindex $values $i]} res]} {
			if {$res == "Cancel"} {return}
			if {$res == "Skip rest!"} {
				if {!$required} {
					set i [llength $allatts]
				} else {
					alertnote "You must give $attr a value."
					incr i -1
				}
			}
		} elseif {$res == "" && $required} {
			alertnote "You must give $attr a value."
			incr i -1
		} else {
			append text $res
		}
	}

	status::msg ""
	# Some tests that input is ok.
	if {([info commands html::${elem}test] != "" || [info commands ::html::${elem}test] != "") && [eval html::${elem}test $elem [list "$text"] status::msg]} { 
		beep
		set text ""
	}
	if {[string length $text]} {append text ">"}
	catch {unset html::ActiveWidth}
	catch {unset html::ActiveHeight}
	return ${text}
}

proc html::StatusElemPrompt {elem attr req def} {
	global html::Plugins html::ActiveUsed
	if {!$req} { set pr "(optional) "}
	if {[lcontains html::Plugins ${html::ActiveUsed}] && ${html::ActiveUsed} != "EMBED"} {
		append pr "$elem, ${html::ActiveUsed}:$attr"
	} else {
		append pr ${elem}:${attr}
	}
	if {$def != ""} {append pr " \[$def\] "}
	return $pr
}


#===============================================================================
# ×××× Flag ×××× #
#===============================================================================

# flag
proc html::StatusBarflag {elem used attr required flash def} {
	global html::xhtml
	set v ""
	set text ""
	set yn no
	if {$def == "1"} {set yn yes}
	while {[catch {html::StatusPrompt $flash "${elem}:$attr \[$yn\] " html::StatusAskYesOrNo} v]} {
		if {[html::statusError v no]} {break}
	}
	if {$v == ""} {set v $yn}
	if {$v == "yes"} {
		if {$html::xhtml} {
			append text [html::WrapTag "[html::SetCase $attr]=[html::AddQuotes [html::SetCase $attr]]"]
		} else {
			append text [html::WrapTag [html::SetCase $attr]]
		}
	}
	return $text
}

# Force yes or no in the status window
proc html::StatusAskYesOrNo {args} {
	eval html::statusArgs curr c $args
	if {$c == ""} {return}
	set c [string tolower $c]
	if {[string match "$curr$c*" "no"]} {return [html::statusReturn [string trim "no" $curr]]}
	if {[string match "$curr$c*" "yes"]} {return [html::statusReturn [string trim "yes" $curr]]}
	beep
	return [html::statusReturn ""]
}

#===============================================================================
# ×××× URL / Frame target / Contenttype ×××× #
#===============================================================================

# url
proc html::StatusBarurl {elem used attr required flash def} {
	global html::ActiveCache
	set html::ActiveCache URLs
	set text ""
	if {[catch {html::AskURL $elem $attr $required $flash $def} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes [quote::UrlExceptAnchor $v]]"]
	}
	return $text
}

# frametarget
proc html::StatusBarframetarget {elem used attr required flash def} {
	global html::ActiveCache
	set html::ActiveCache Targets
	set text ""
	if {[catch {html::AskURL $elem $attr $required $flash $def} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
	}
	return $text
}

# contenttype
proc html::StatusBarcontenttype {elem used attr required flash def} {
	global html::ActiveCache HTMLmodeVars
	set html::ActiveCache contenttypes
	set text ""
	if {[catch {html::AskURL $elem $attr $required $flash $def} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
		if {![lcontains HTMLmodeVars(contenttypes) [string tolower $v]]} {
			lappend HTMLmodeVars(contenttypes) [string tolower $v]
			prefs::modifiedModeVar contenttypes HTML
		}
	}
	return $text
}

# contenttypes
proc html::StatusBarcontenttypes {elem used attr required flash def {types contenttypes} {comma 1}} {
	global html::ActiveCache HTMLmodeVars
	set html::ActiveCache $types
	set text ""
	set sep " "
	if {$comma} {set sep ","}
	if {[catch {html::AskURL $elem $attr $required $flash $def $sep} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
		if {$comma} {
			set tlist [split $v ,]
		} else {
			set tlist $v
		}
		foreach t $tlist {
			set t [string tolower [string trim $t]]
			if {![lcontains HTMLmodeVars($types) $t]} {
				lappend HTMLmodeVars($types) $t
				prefs::modifiedModeVar $types HTML
			}
		}
	}
	return $text
}

# linktypes 
proc html::StatusBarlinktypes {elem used attr required flash def} {
	return [html::StatusBarcontenttypes $elem $used $attr $required $flash $def linktypes 0]
}

# mediadesc 
proc html::StatusBarmediadesc {elem used attr required flash def} {
	return [html::StatusBarcontenttypes $elem $used $attr $required $flash $def mediatypes]
}

# HREF attributes are handled as a listpick from a cached list
proc html::AskURL {elem attr required flash def {sep ""}} {
	global html::URLTabSeen html::ActiveAttr html::StatusSepString
	global html::ActiveCache html::ActiveURL
	
	set html::StatusSepString $sep
	set html::ActiveAttr $attr
	set html::URLTabSeen 0
	set pr [html::StatusElemPrompt $elem $attr $required $def]
	while {[catch {html::StatusPrompt $flash $pr html::URLStatusFunc} r]} {
		if {$r == "Cancel all!"} {
			error "Cancel all!"
		}
		if {$r == "Continue!"} {
			set r ${html::ActiveURL}
			unset html::ActiveURL
			break
		}
		if {$r == "Skip rest!"} {error "Skip rest!"}
		if {$r == "No value"} {return}
	}
	set r [string trim $r]
	if {${html::ActiveCache} == "URLs" || ${html::ActiveCache} == "Targets"} {html::AddToCache ${html::ActiveCache} $r}
	if {$r == ""} {return $def}
	return $r
}


proc html::URLStatusFunc {args} {
	global html::ActiveAttr html::URLTabSeen html::ActiveCache html::ActiveURL
	global html::ActiveElem html::ActiveWidth html::ActiveHeight html::StatusSepString
	global html::UserURLs html::UserTargets HTMLmodeVars
	
	eval html::statusArgs curr c $args
	if {${html::ActiveCache} == "Targets"} {set URLs {_self _top _parent _blank}}
	if {${html::ActiveCache} == "URLs" || ${html::ActiveCache} == "Targets"} {
		append URLs " " [set html::User${html::ActiveCache}]
	} else {
		append URLs " " $HTMLmodeVars(${html::ActiveCache})
	}
	
	# ctrl-f for file dialog.
	if {$c == "\006"} {
		if {${html::ActiveCache} != "URLs"} {
			beep
			return [html::statusReturn ""]
		}
		set newURL [html::GetFile]
		if {[string length $newURL]} {
			set html::ActiveURL [lindex $newURL 0]
			if {[llength [set nnn [lindex $newURL 1]]] && ${html::ActiveAttr} == "SRC="} {
				set html::ActiveWidth [lindex $nnn 0]
				set html::ActiveHeight [lindex $nnn 1]
			}
			error "Continue!"
		} else {
			return [html::statusReturn ""]
		}
	}

	if {$c != "\t"} {
		set html::URLTabSeen 0
		return [html::statusReturn $c]
	}

	set matches {}
	set matchcurr $curr
	if {${html::StatusSepString} != ""} {
		set matchcurr [string trimleft [string range $matchcurr [expr {[string last ${html::StatusSepString} $matchcurr] + 1}] end]]
	}
	
	foreach w $URLs {
		if {[string match "$matchcurr*" $w]} {
			lappend matches $w
		}
	}
	if {![llength $matches]} {
		beep
	} else {
		if {${html::URLTabSeen}} {
			if {[catch {listpick -p ${html::ActiveElem}:${html::ActiveAttr} $matches} ret]} {
				set ret ""
			}
			if {[string length $ret]} {
				set html::ActiveURL $ret
				if {${html::StatusSepString} == ""} {
					error "Continue!"
				} else {
					set ret [string range $ret [string length $matchcurr] end]
				}
			}
			set html::URLTabSeen 0
		} else {
			set html::URLTabSeen 1
			set ret [string range [largestPrefix $matches] [string length $matchcurr] end]
		}
		return [html::statusReturn $ret]
	}
	return [html::statusReturn ""]
}

#===============================================================================
# ×××× Color ×××× #
#===============================================================================

# color
proc html::StatusBarcolor {elem used attr required flash def} {
	set text ""
	if {[catch {html::AskColor $elem $attr $required $flash $def} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
	}
	return $text	
}
# Choose a color name or add a color number

proc html::AskColor {elem attr required flash def} {
	global html::ColorTabSeen html::ColorName html::ActiveAttr
	global html::basicColors html::userColors htmlColors html::ActiveColor
	
	set htmlColors [lsort [array names html::userColors]]
	append htmlColors " " ${html::basicColors}
	set html::ActiveAttr $attr
 	
 	while {1} {
 		# Loop until input is valid or everything is cancelled, then something is returned
 		set html::ColorTabSeen 0
 		set pr [html::StatusElemPrompt $elem $attr $required $def]
 		while {[catch {html::StatusPrompt $flash $pr html::ColorStatusFunc} r]} {
 			if {$r == "Cancel all!"} {
  				error "Cancel all!"
 			}
 			if {$r == "Continue!"} {
 				set r ${html::ActiveColor}
 				unset html::ActiveColor
 				break
 			}
 			if {$r == "Skip rest!"} {error "Skip rest!"}
 			if {$r == "No value"} {return}
 		}
 		set r [string trim $r]
 		if {$r == ""} {return $def}
 		# Users own color?
 		if {[info exists html::userColors($r)]} {return [set html::userColors($r)]}
 		# Predefined color?
 		if {[info exists html::ColorName($r)]} {
 			return [set html::ColorName($r)]
 		} else {
 			set col [html::CheckColorNumber $r]
 			if {$col != 0} {
 				return $col
 			} else {
 				alertnote "$r is not a valid color number. It should be of the form #RRGGBB."
 			}
 		}
 	}
}
 
proc html::ColorStatusFunc {args} {
	global html::ActiveAttr html::ColorTabSeen html::ColorName
	global htmlColors html::ActiveColor html::ActiveElem
	
	eval html::statusArgs curr c $args
	# ctrl-f is new color.
	if {$c == "\006"} {
		set newcolor [html::AddANewColor]
		if {[string length $newcolor]} {
			set html::ActiveColor $newcolor
			error "Continue!"
		} else {
			return [html::statusReturn ""]
		}
	}
	
	if {$c != "\t"} {
		set html::ColorTabSeen 0
		return [html::statusReturn $c]
	}

	set matches {}
	set attr ${html::ActiveAttr}
	foreach w $htmlColors {
		if {[string match "$curr*" $w]} {
			lappend matches $w
		}
	}
	if {![llength $matches]} {
		beep
	} else {
		if {${html::ColorTabSeen}} {
			if {[catch {listpick -p ${html::ActiveElem}:${html::ActiveAttr} $matches} ret]} {
				set ret ""
			}
			if {[string length $ret]} {
				set html::ActiveColor $ret
				error "Continue!"
			}
			set html::ColorTabSeen 0
		} else {
			set html::ColorTabSeen 1
			set ret [string range [largestPrefix $matches] [string length $curr] end]
		}
		return [html::statusReturn $ret]
	}
	return [html::statusReturn ""]
}


#===============================================================================
# ×××× Choices / Oltype / Other etc. ×××× #
#===============================================================================

# choices
proc html::StatusBarchoices {elem used attr required flash def {casesensitive 0}} {
	set text ""
	if {[catch {html::StatusAskAttr $elem $used $attr $required $flash $def 1 $casesensitive [html::GetAttrChoices $used $attr]} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
	}
	return $text
}

# oltype
proc html::StatusBaroltype {elem used attr required flash def} {
	html::StatusBarchoices $elem $used $attr $required $flash $def 1
}

# other
proc html::StatusBarother {elem used attr required flash def} {
	set text ""
	if {[catch {html::StatusAskAttr $elem $used $attr $required $flash $def 1 0 ""} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
	}
	return $text
}

# othernotrim
proc html::StatusBarothernotrim {elem used attr required flash def} {
	set text ""
	if {[catch {html::StatusAskAttr $elem $used $attr $required $flash $def 0 0 ""} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
	}
	return $text
}

# fixed
proc html::StatusBarfixed {elem used attr required flash def} {
	return [html::WrapTag "[html::SetCase $attr][html::AddQuotes [html::GetAttrFixed $elem $attr]]"]
}

# anchor
proc html::StatusBaranchor {elem used attr required flash def} {
	set text ""
	if {[catch {html::StatusAskAttr $elem $used $attr $required $flash $def 1 0 ""} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
		html::AddToCache URLs "#$v"
	}
	return $text
}

# targetname
proc html::StatusBartargetname {elem used attr required flash def} {
	set text ""
	if {[catch {html::StatusAskAttr $elem $used $attr $required $flash $def 1 0 ""} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
		html::AddToCache Targets $v
	}
	return $text
}

# eventhandler
proc html::StatusBareventhandler {elem used attr required flash def} {
	set text ""
	if {[catch {html::StatusAskAttr $elem $used $attr $required $flash $def 1 0 ""} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "$attr[html::AddQuotes $v]"]
	}
	return $text
}

# id
proc html::StatusBarid {elem used attr required flash def} {
	set text ""
	if {[catch {html::StatusAskAttr $elem $used $attr $required $flash $def 1 0 "" html::CheckId "Must be first a letter and then letters, digits, and '_' '-' ':' '.'"} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
	}
	return $text
}

# ids
proc html::StatusBarids {elem used attr required flash def} {
	set text ""
	if {[catch {html::StatusAskAttr $elem $used $attr $required $flash $def 1 0 "" html::CheckIds "Must be first a letter and then letters, digits, and '_' '-' ':' '.'"} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
	}
	return $text
}

# languagecode 
proc html::StatusBarlanguagecode {elem used attr required flash def} {
	html::StatusBarother $elem $used $attr $required $flash $def
	# to be modified
}

# charset 
proc html::StatusBarcharset {elem used attr required flash def} {
	html::StatusBarother $elem $used $attr $required $flash $def
	# to be modified
}

# charsets 
proc html::StatusBarcharsets {elem used attr required flash def} {
	html::StatusBarother $elem $used $attr $required $flash $def
	# to be modified
}

# coords 
proc html::StatusBarcoords {elem used attr required flash def {multilength 0}} {
	global html::ActiveAttr
	set html::ActiveAttr $attr
	set func html::CheckStatusCoords
	if {$multilength} {set func html::CheckStatusMultiLengths}
	set text ""
	if {[catch {html::StatusAskAttr $elem $used $attr $required $flash $def 1 0 "" $func "Incorrect number."} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
	}
	return $text
}

# multilengths 
proc html::StatusBarmultilengths {elem used attr required flash def} {
	html::StatusBarcoords $elem $used $attr $required $flash $def 1
}

# datetime 
proc html::StatusBardatetime {elem used attr required flash def} {
	set text ""
	if {[catch {html::StatusAskAttr $elem $used $attr $required $flash $def 1 0 "" html::CheckStatusDateTime "Incorrect date and time."} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		if {[string tolower $v] == "now"} {set v [mtime [now] iso]}
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
	}
	return $text
}

proc html::StatusAskAttr {elem used attr required flash def trim casesensitive {choices ""} {checkFunc ""} {errMsg ""}} {
	global htmlAttrTabSeen htmlActiveInput htmlActiveChoices html::ActiveUsed html::ActiveAttr htmlCaseSensitive

	set html::ActiveAttr $attr
	set html::ActiveUsed $used
	set htmlActiveChoices $choices
	set htmlAttrTabSeen 0
	set htmlCaseSensitive $casesensitive
	set pr [html::StatusElemPrompt $elem $attr $required $def]
	while {1} {
		set v ""
		while {[catch {html::StatusPrompt $flash $pr html::AttrStatusFunc} v]} {
			if {$v == "Cancel all!"} {
				error "Cancel all!"
			}
			if {$v == "Continue!"} {
				set v $htmlActiveInput
				unset htmlActiveInput
				break
			}
			if {$v == "Skip rest!"} {error "Skip rest!"}
			if {$v == "No value"} {return}
		}
		
		if {$trim} {set v [string trim $v]}
		if {$v == ""} {return $def}
		# Check value
		if {$checkFunc != ""} {
			if {![$checkFunc $v]} {
				alertnote $errMsg
			} else {
				break
			}
		} else {
			break
		}
	}
	
 	# if there are choices, check if the user has typed one.
	if {![llength $choices]} {
		return $v
	} else {
		set matches ""
		foreach w $choices {
			if {$casesensitive} {
				set c $v
			} else {
				set c [string toupper $v]	
			}
			if {[string match "${c}*" $w]} {
				lappend matches $w 
			}
		} 
		# if unique extension, add what's needed, otherwise return nothing.
		if {[llength $matches] == 1 && [string length $v]} {
			set ret $matches
			if {!$casesensitive} {
				set ret [html::SetCase $ret] 
			}
			return $ret
		} else {
			return
		}
	}
}

# CDATA element attribute, status window match completion
proc html::AttrStatusFunc {args} {
	global html::ActiveUsed htmlActiveChoices html::ActiveAttr htmlAttrTabSeen htmlActiveInput htmlCaseSensitive

	eval html::statusArgs curr c $args
	# should we set the case or not (are there predefined choices)?
	set matches {}
	set attr ${html::ActiveAttr}
	foreach w $htmlActiveChoices {
		if {$htmlCaseSensitive} {
			if {[string match "${curr}*" $w]} {
				lappend matches $w
			}
		} elseif {[string match [string toupper "${curr}*"] $w]} {
			lappend matches $w
		}
	}
	
	if {$c != "\t" } {
		set htmlAttrTabSeen 0
		if {[llength $htmlActiveChoices]} {
		# check if the last character matches
			set matches {}
			foreach w $htmlActiveChoices {
				if {[string match [string toupper "${curr}${c}*"] $w]} {
					lappend matches $w
				}
			}
			if {[llength $matches]} { 
				if {!$htmlCaseSensitive} {
					set c [html::SetCase $c] 
				}
				return [html::statusReturn $c]
			} else {
				beep
				return [html::statusReturn ""]
			} 
		} else {
			return [html::statusReturn $c]
		}
	}
	
	# it's a tab
	if {![llength $matches]} {
		beep
	} else {
		if {$htmlAttrTabSeen} {
			if {[catch {listpick -p ${html::ActiveUsed}:${html::ActiveAttr} $matches} ret]} {
				set ret ""
			}
			if {[string length $ret]} {
				set htmlActiveInput $ret
				error "Continue!"
			}
			set htmlAttrTabSeen 0
		} else {
			set htmlAttrTabSeen 1
			set ret [string range [largestPrefix $matches] [string length $curr] end]
		}
		if {!$htmlCaseSensitive} { 
			# special case 
			set ret [html::SetCase $ret] 
		}
		return [html::statusReturn $ret]
	}
	return [html::statusReturn ""]
}

#===============================================================================
# ×××× Character ×××× #
#===============================================================================

# character
proc html::StatusBarcharacter {elem used attr required flash def} {
	set text ""
	set pr [html::StatusElemPrompt $elem $attr $required $def]
	while {[catch {html::StatusPrompt $flash $pr html::AskCharacter} v]} {
		if {$v == "No value"} {return}
		html::statusError v ""
	}
	if {$v == ""} {set v $def}
	if {$v != ""} {append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]}
	return $text
}

# Force yes or no in the status window
proc html::AskCharacter {args} {
	eval html::statusArgs curr c $args
	if {$curr == "" && $c != " "} {return [html::statusReturn $c]}
	beep
	return [html::statusReturn ""]
}

#===============================================================================
# ×××× Length / Integer ×××× #
#===============================================================================

# length
proc html::StatusBarlength {elem used attr required flash def} {
	global html::StatusNumRegexp
	set html::StatusNumRegexp {^(\+|-)?([0-9]*|[0-9]+%?)$}
	html::_AskNumber $elem $used $attr $required $flash $def 1 0
}

# integer
proc html::StatusBarinteger {elem used attr required flash def} {
	global html::StatusNumRegexp
	set html::StatusNumRegexp {^(\+|-)?[0-9]*$}
	html::_AskNumber $elem $used $attr $required $flash $def 0 0
}

# multilength 
proc html::StatusBarmultilength {elem used attr required flash def} {
	global html::StatusNumRegexp
	set html::StatusNumRegexp {^(\*|(\+|-)?([0-9]*|[0-9]+(\*|%)?))$}
	html::_AskNumber $elem $used $attr $required $flash $def 1 1
}

proc html::_AskNumber {elem used attr required flash def procent multilength} {
	set text ""
	if {[catch {html::AskNumber $elem $used $attr $required $flash $def $procent $multilength} v]} {
		html::statusError v ""
	} elseif {[string length $v]} {
		append text [html::WrapTag "[html::SetCase $attr][html::AddQuotes $v]"]
	}
	return $text	
}

# ask for an attribute which is a number. Returns "" if input is not valid.
proc html::AskNumber {elem used attr required flash default procent multilength} {
	global html::ActiveWidth html::ActiveHeight
	
	
	# loop until input is valid, then something is returned
	while {1} { 
		set pr [html::StatusElemPrompt $elem $attr $required ""]
		
		if {$elem == "IMG" && $attr == "WIDTH=" && ${html::ActiveWidth} != ""} {
			append pr " \[${html::ActiveWidth}\] "
		} elseif {$elem == "IMG" && $attr == "HEIGHT=" && ${html::ActiveHeight} != ""} {
			append pr " \[${html::ActiveHeight}\] "
		} elseif {$default != ""} {
			append pr " \[$default\] "
		}
		while {[catch {html::StatusPrompt $flash $pr html::NumberStatusFunc} r]} { 
			if {$r == "Cancel all!"} {error "Cancel all!"}
			if {$r == "Skip rest!"} {error "Skip rest!"}
			if {$r == "No value"} {return}
		}
		set r [string trim $r]
		# if no input, return default
		if {$r == ""} {
			if {$elem == "IMG" && $attr == "WIDTH=" && ${html::ActiveWidth} != ""} {
				return ${html::ActiveWidth}
			} elseif {$elem == "IMG" && $attr == "HEIGHT=" && ${html::ActiveHeight} != ""} {
				return ${html::ActiveHeight}
			} else {
				return $default
			}
		}
		# check that input is valid.
		set numcheck [html::CheckAttrNumber $used $attr $r $procent $multilength]
		if {$numcheck == 1} {
			return $r 
		} else {
			alertnote "Invalid input. $numcheck"
		}
	}
}

proc html::NumberStatusFunc {args} {
	global html::StatusNumRegexp
	eval html::statusArgs curr c $args
	if {![regexp ${html::StatusNumRegexp} $curr$c]} {
		beep
		set c ""
	}
	return [html::statusReturn $c]
}
	

#===============================================================================
# ×××× Help procs ×××× #
#===============================================================================

proc html::StatusPrompt {flash prompt func} {
	
	set patt ""
	if {[catch {eval [concat status::prompt $flash -appendvar patt -add anything -command $func [list $prompt]]} r]} {
		if {$r == "return"} {return $patt}
		error $r
	} else {
		return $patt
	}
}

proc html::statusArgs {current char args} {
	upvar $current curr $char c
	upvar 2 patt patt
	set c [lindex $args 0]
	if {$c == "\b"} {
		set c ""
		set patt [string range $patt 0 [expr {[string length $patt] - 2}]]
	}
	if {$c == "\033"} {error "escape"}
	set curr $patt
	if {[lindex $args 1] == "" || [lindex $args 0] == "\r"} {error "return"}
	if {[expr {[lindex $args 1] & 144}]} {
		if {$c == "q"} {set c "\021"}
		if {$c == "d"} {set c "\004"}
		if {$c == "z"} {set c "\032"}
		if {$c == "f"} {set c "\006"}
	}
	if {[expr {[lindex $args 1] & 1}]} {
		if {$c == "v"} {set c [getScrap]}
	}
	if {$c == "\032"} {error "Cancel all!"}
	if {$c == "\021"} {error "Skip rest!"}
	if {$c == "\004"} {error "No value"}
	
}

proc html::statusReturn {c} {
	global alpha::platform
	upvar 2 patt patt
	append patt $c
	upvar 2 prompt pr
	status::msg "$pr$patt "
	return ""
}

proc html::statusError {val def} {
	upvar $val var
	if {$var == "Cancel all!"} {
		status::msg "Cancel"
		error "Cancel"
	}
	if {$var == "Skip rest!"} {
		error "Skip rest!"
	}
	if {$var == "No value"} {
		set var $def
		return 1
	}
	return 0
}

proc html::CheckStatusDateTime {val} {
	if {[string tolower $val] == "now"} {return 1}
	if {[regexp {^([0-9]+)-([0-9]+)-([0-9]+)T([0-9]+):([0-9]+):([0-9]+)(Z|[-+][0-9]+:[0-9]+)$} $val "" Y M D h m s tzd]} {
		return [expr ![catch {html::CheckDateTime [list $Y $M $D $h $m $s $tzd]}]]
	}
	return 0
}

proc html::_CheckStatusCoords {val multilength} {
	global html::ActiveUsed html::ActiveAttr
	if {$val != ""} {
		foreach l [split $val ,] {
			set l [string trim $l]
			set numcheck [html::CheckAttrNumber ${html::ActiveUsed} ${html::ActiveAttr} $l 1 $multilength]
			if {$numcheck != 1} {
				return 0
			}
		}
	}
	return 1
}

proc html::CheckStatusCoords {val} {
	html::_CheckStatusCoords $val 0
}

proc html::CheckStatusMultiLengths {val} {
	html::_CheckStatusCoords $val 1
}
