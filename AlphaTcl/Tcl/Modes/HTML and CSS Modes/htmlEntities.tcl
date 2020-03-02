## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlEntities.tcl"
 #                                    created: 98-02-15 18.04.08 
 #                                last update: 2005-02-21 17:51:40 
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
# ◊◊◊◊ Character entities ◊◊◊◊ #
#===============================================================================

proc htmlEntities.tcl {} {}

proc html::AddCommonChars {} {
	global HTMLmodeVars html::SmallCharsMenu html::CapitalCharsMenu
	global html::OtherChars1Menu html::OtherChars2Menu
	set commonChars $HTMLmodeVars(commonChars)
	set pick [lremove [concat ${html::SmallCharsMenu} ${html::CapitalCharsMenu} ${html::OtherChars1Menu} ${html::OtherChars2Menu}] $commonChars]
	regsub -all ! $pick "" pick1
	if {![catch {listpick -l -p "Select chars for the commonly used char list" \
	  $pick1} newchars] && $newchars != ""} {
		foreach c $newchars {
			if {[lcontains pick $c]} {
				lappend commonChars $c
			} else {
				lappend commonChars "!$c"
			}
		}
		set commonChars [lsort $commonChars]
		prefs::modifiedModeVar commonChars HTML
		set HTMLmodeVars(commonChars) $commonChars
		menu::buildSome "Character Entities"
		status::msg "New characters added to the common list."
	}
}

proc html::RemoveCommonChars {} {
	global HTMLmodeVars 
	set commonChars $HTMLmodeVars(commonChars)
	regsub -all ! $commonChars "" pick
	if {![catch {listpick -l -p "Select chars to remove from the commonly used char list" \
	  $pick} chars] && $chars != ""} {
		foreach c $chars {
			if {[lcontains commonChars $c]} {
				lappend rem $c
			} else {
				lappend rem "!$c"
			}
		}
		set commonChars [lremove $commonChars $rem]
		prefs::modifiedModeVar commonChars HTML
		set HTMLmodeVars(commonChars) $commonChars
		menu::buildSome "Character Entities"
		status::msg "Characters removed from the common list."
	}
	
}


#
# Insert special character entity
#
proc html::InsertCharacter {char} {
	global html::SpecialCharacter html::CapCharSpecMenu
	if {[isSelection]} { deleteSelection }
	foreach c [list SpecialCharacter CapCharSpecMenu] {
		if {[info exists html::${c}($char)]} {
			insertText &[set html::${c}($char)]\;
			return
		}
	}
}


proc html::SetEntityKeys {meny} {
	global html::SmallCharsMenu html::CapitalCharsMenu html::OtherChars1Menu html::OtherChars2Menu html::PrefsFolder
	if {[file exists [file join ${html::PrefsFolder} "HTML entity keys"]]} {source [file join ${html::PrefsFolder} "HTML entity keys"]}
	set allkeys [set html::[join $meny ""]Menu]
	foreach key $allkeys {
		set dkey $key
		if {[string index $key 0] == "!"} {
			set dkey "[string index $key 1] [set key [string range $key 2 end]]"
		}
		if {[info exists htmlEntityKeys($key)]} {
			lappend keys [list $htmlEntityKeys($key) $dkey]
		} else {
			lappend keys [list {} $dkey]
		}
	}
	bind::fromArray htmlEntityKeys htmlEntityKeysProc 1 HTML
	if {[eval dialog::adjustBindings [list $meny] newkeys modified 0 $keys] != "Cancel"} {
		foreach key $modified {
			set dkey $key
			if {[lcontains allkeys "![string index $key 0][string range $key 2 end]"]} {
				set dkey [string range $key 2 end]
			}
			if {$newkeys($key) == ""} {unset htmlEntityKeys($dkey) htmlEntityKeysProc($dkey); continue}
			set htmlEntityKeys($dkey) $newkeys($key)
			set htmlEntityKeysProc($dkey) [list html::InsertCharacter $dkey]
		}
	}
	bind::fromArray htmlEntityKeys htmlEntityKeysProc 0 HTML
	html::SaveCache "HTML entity keys" "array set htmlEntityKeys [list [array get htmlEntityKeys]]\rarray set htmlEntityKeysProc [list [array get htmlEntityKeysProc]]"
}

set html::SmallCharsMenu {eth thorn à á â ã ä å æ ç è é ê ë ì í î 
ï ñ ò ó ô õ ö ø œ ù ú û ü y´ ÿ}

set html::CapitalCharsMenu {ETH THORN À A´ A^ Ã Ä Å Æ Ç E` É E^ E¨ I` 
I´ I^ I¨ Ñ O` O´ O^ Õ Ö Ø Œ U` U´ U^ Ü Y´ Y¨}

set html::OtherChars1Menu {ampersand {greater than} {less than} {!≤less-than or equal} {!≥greater-than or equal}
{!≈approximately equal to} {!≠not equal to} {nonbreak space} {!"quotation mark} {!“left double quotation}
{!”right double quotation} {!‘left single quotation} {!’right single quotation} {!‚single low quotation}
{!„double low quotation} {!«left double angle} {!»right double angle} {!‹left single angle}
{!›right single angle} {!¿inverted question mark} {!¡inverted excl. mark} {!ªfeminine ordinal ind.}
{!ºmasculine ordinal ind.} {superscript one} {superscript two} {superscript three} {!®registered sign}
{!©copyright sign} {!™trade mark sign} !°degree {!|broken bar}}

set html::OtherChars2Menu {currency !¢cent !£pound !¥yen !?euro !ƒflorin {!´acute accent} !¨diearesis !¸cedilla
{!§section sign} {!¶paragraph sign} {soft hyphen} {!–en dash} {!—em dash} {one half} {one quarter}
{three quarters} {!‰per mille sign} !…ellipsis !¯macron {!·middle dot} !•bullet !†dagger {!‡double dagger}
{!µmicro sign} {!¬not sign} !±plus-minus !÷divide times {!√square root} !∞infinity !∫integral}

loadHtmlUtilities.tcl
