## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlPrefsUpdater.tcl"
 #                                    created: 99-07-16 21.48.03 
 #                                last update: 2005-02-21 17:52:11 
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

proc htmlPrefsUpdater.tcl {} {}

#===============================================================================
# ×××× HTML mode vars ×××× #
#===============================================================================

if {[info exists HTMLmodeVars]} {
	set __tmpind {TR TD TH}
	if {![info exists HTMLmodeVars(pIsContainer)] || $HTMLmodeVars(pIsContainer)} {
		lappend __tmpind P
	}
	if {[info exists HTMLmodeVars(lidtAreContainers)] && $HTMLmodeVars(lidtAreContainers)} {
		lappend __tmpind LI DD DT
	}

	if {![info exists HTMLmodeVars(optionalClosing)]} {
		set HTMLmodeVars(optionalClosing) $__tmpind
		prefs::addArrayElement HTMLmodeVars optionalClosing $__tmpind
	}

	set __tmp ""
	foreach __tmpind {DIR DL MENU OL TABLE TR UL} {
		if {![info exists HTMLmodeVars(indent$__tmpind)] || $HTMLmodeVars(indent$__tmpind)} {
			lappend __tmp $__tmpind
		}
	}
	foreach __tmpind {APPLET BLOCKQUOTE BODY CENTER DIV FIELDSET FORM FRAMESET HEAD 
	MAP MULTICOL NOEMBED NOFRAMES NOSCRIPT OBJECT OPTGROUP P SELECT} {
		if {[info exists HTMLmodeVars(indent$__tmpind)] && $HTMLmodeVars(indent$__tmpind)} {
			lappend __tmp $__tmpind
		}
	}
	if {![info exists HTMLmodeVars(indentElements)]} {
		set HTMLmodeVars(indentElements) $__tmp
		prefs::addArrayElement HTMLmodeVars indentElements $__tmp
	}
		
	if {[info exists HTMLmodeVars(commonChars)] && [set __where [lsearch -exact $HTMLmodeVars(commonChars) "!?currency"]] >= 0} {
		set HTMLmodeVars(commonChars) [lreplace $HTMLmodeVars(commonChars) $__where $__where currency]
		prefs::addArrayElement HTMLmodeVars commonChars $HTMLmodeVars(commonChars)
	}
		
	foreach __tmp {elecRBrace elecLBrace electricSemi electricTab htmlPackageToUse lidtAreContainers footers
	hideNetscape hideIE inclEventHandler hideStyleAttrs useAttsApplyToDialogs pIsContainer defaultCommonChars
	indentAPPLET indentBLOCKQUOTE indentBODY indentCENTER indentDIR indentDIV indentDL 
	indentFIELDSET indentFORM indentFRAMESET indentHEAD indentMAP indentMENU indentMULTICOL
	indentNOEMBED indentNOFRAMES indentNOSCRIPT indentOBJECT indentOL indentOPTGROUP
	indentP indentSELECT indentTABLE indentTR indentUL flashStatusBar manualStartPage} {
		if {[info exists HTMLmodeVars($__tmp)]} {
			prefs::removeArrayElement HTMLmodeVars $__tmp
			catch {unset HTMLmodeVars($__tmp)}
		}
	}
}

#===============================================================================
# ×××× URLs and windows ×××× #
#===============================================================================

if {[info exists HTMLmodeVars(URLs)]} {
	file::ensureDirExists [file join ${html::PrefsFolder} URLs]
	set __fnm ""
	while {[file exists [file join ${html::PrefsFolder} URLs [string trim "Default $__fnm"]]]} {
		if {$__fnm == ""} {set __fnm 1} else {incr __fnm}
	}
	if {![catch {open [file join ${html::PrefsFolder} URLs [string trim "Default $__fnm"]] w} fid]} {
		puts $fid [join $HTMLmodeVars(URLs) "\r"]
		close $fid
	}
	lappend HTMLmodeVars(activeURLSets) [string trim "Default $__fnm"]
	prefs::addArrayElement HTMLmodeVars activeURLSets $HTMLmodeVars(activeURLSets)
	set HTMLmodeVars(addURLsTo) [string trim "Default $__fnm"]
	prefs::addArrayElement HTMLmodeVars addURLsTo $HTMLmodeVars(addURLsTo)
	prefs::removeArrayElement HTMLmodeVars URLs
	catch {unset HTMLmodeVars(URLs)}
} elseif {![info exists html::PrefsVersion] || ${html::PrefsVersion} < 3.09} {
	file::ensureDirExists [file join ${html::PrefsFolder} URLs]
	if {[catch {glob -dir [file join ${html::PrefsFolder} URLs] *}]} {
		if {![catch {open [file join ${html::PrefsFolder} URLs Default] w} fid]} {close $fid}
		lappend HTMLmodeVars(activeURLSets) Default
		prefs::addArrayElement HTMLmodeVars activeURLSets $HTMLmodeVars(activeURLSets)
		set HTMLmodeVars(addURLsTo) Default
		prefs::addArrayElement HTMLmodeVars addURLsTo $HTMLmodeVars(addURLsTo)
	}
}

if {[info exists HTMLmodeVars(windows)]} {
	file::ensureDirExists [file join ${html::PrefsFolder} Targets]
	set __fnm ""
	while {[file exists [file join ${html::PrefsFolder} Targets [string trim "Default $__fnm"]]]} {
		if {$__fnm == ""} {set __fnm 1} else {incr __fnm}
	}
	if {![catch {open [file join ${html::PrefsFolder} Targets [string trim "Default $__fnm"]] w} fid]} {
		puts $fid [join $HTMLmodeVars(windows) "\r"]
		close $fid
	}
	lappend HTMLmodeVars(activeTargetSets) [string trim "Default $__fnm"]
	prefs::addArrayElement HTMLmodeVars activeTargetSets $HTMLmodeVars(activeTargetSets)
	set HTMLmodeVars(addTargetsTo) [string trim "Default $__fnm"]
	prefs::addArrayElement HTMLmodeVars addTargetsTo $HTMLmodeVars(addTargetsTo)
	prefs::removeArrayElement HTMLmodeVars windows
	catch {unset HTMLmodeVars(windows)}
} elseif {![info exists html::PrefsVersion] || ${html::PrefsVersion} < 3.09} {
	file::ensureDirExists [file join ${html::PrefsFolder} Targets]
	if {[catch {glob -dir [file join ${html::PrefsFolder} Targets] *}]} {
		if {![catch {open [file join ${html::PrefsFolder} Targets Default] w} fid]} {close $fid}
		lappend HTMLmodeVars(activeTargetSets) Default
		prefs::addArrayElement HTMLmodeVars activeTargetSets $HTMLmodeVars(activeTargetSets)
		set HTMLmodeVars(addTargetsTo) Default
		prefs::addArrayElement HTMLmodeVars addTargetsTo $HTMLmodeVars(addTargetsTo)
	}
}

#===============================================================================
# ×××× CSS mode vars ×××× #
#===============================================================================

if {[info exists CSSmodeVars]} {
	foreach __tmp {elecRBrace elecLBrace electricSemi createWithoutAsking openNonTextFile} {
		if {[info exists CSSmodeVars($__tmp)]} {
			prefs::removeArrayElement CSSmodeVars $__tmp
			catch {unset CSSmodeVars($__tmp)}
		}
	}
}

#===============================================================================
# ×××× Element prefs ×××× #
#===============================================================================

foreach __tmp [array names htmlElemAttrUsed] {
	set html::ElemAttrUsed($__tmp) $htmlElemAttrUsed($__tmp)
	prefs::addArrayElement html::ElemAttrUsed $__tmp $htmlElemAttrUsed($__tmp)
	prefs::removeArrayElement htmlElemAttrUsed $__tmp
}

foreach __tmp [array names htmlElemAttrHidden] {
	set html::ElemAttrHidden($__tmp) $htmlElemAttrHidden($__tmp)
	prefs::addArrayElement html::ElemAttrHidden $__tmp $htmlElemAttrHidden($__tmp)
	prefs::removeArrayElement htmlElemAttrHidden $__tmp
}

foreach __tmp [array names htmlElemAttrMore] {
	prefs::removeArrayElement htmlElemAttrMore $__tmp
}

#===============================================================================
# ×××× Entity keys ×××× #
#===============================================================================

if {[file exists [file join ${html::PrefsFolder} "HTML entity keys"]]} {
	source [file join ${html::PrefsFolder} "HTML entity keys"]
	foreach key [array names htmlEntityKeys] {
		set htmlEntityKeysProc($key) [list html::InsertCharacter $key]
	}
	bind::fromArray htmlEntityKeys htmlEntityKeysProc 0 HTML
	html::SaveCache "HTML entity keys" "array set htmlEntityKeys [list [array get htmlEntityKeys]]\rarray set htmlEntityKeysProc [list [array get htmlEntityKeysProc]]"
}

#===============================================================================
# ×××× Colors ×××× #
#===============================================================================

if {[info exists htmluserColors]} {
	foreach __tmp [array names htmluserColors] {
		append __txt "if {!\[info exists \"colorNumber($__tmp)\"\] && !\[info exists \"colorName($htmluserColors($__tmp))\"\]}"
		append __txt " {set \"colorNumber($__tmp)\" {$htmluserColors($__tmp)}; set \"colorName($htmluserColors($__tmp))\" {$__tmp}}\r"
	}
	if {[info exists __txt]} {
		file::ensureDirExists [file join ${html::PrefsFolder} Colors]
		set __fnm ""
		while {[file exists [file join ${html::PrefsFolder} Colors [string trim "Default $__fnm"]]]} {
			if {$__fnm == ""} {set __fnm 1} else {incr __fnm}
		}
		html::SaveCache [file join Colors [string trim "Default $__fnm"]] $__txt
		lappend HTMLmodeVars(activeColorSets) [string trim "Default $__fnm"]
		prefs::addArrayElement HTMLmodeVars activeColorSets $HTMLmodeVars(activeColorSets)
	}	
}

foreach __tmp [array names htmluserColors] {
	prefs::removeArrayElement htmluserColors $__tmp
}
foreach __tmp [array names htmluserColorname] {
	prefs::removeArrayElement htmluserColorname $__tmp
}

#===============================================================================
# ×××× Menu keys ×××× #
#===============================================================================

html::ReadMenuKeys
if {[info exists htmlMenuKey]} {
	foreach __tmp {{"HTML/Use AttributesÉ" "Preferences/Use AttributesÉ"}
	{"Preferences/AttributesÉ" "Preferences/Attributes GloballyÉ"}
	{"Utilities/Home PagesÉ" "Preferences/Home PagesÉ"}
	{"Utilities/Key BindingsÉ" "Preferences/Key BindingsÉ"}
	{"Editing/Change ContainerÉ/Change OpeningÉ" "Editing/Edit TagÉ"}
	{"Lists/Bulleted/UL no attr" "Lists/Unordered List/UL no attr"}
	{"Lists/Numbered/OL no attr" "Lists/Ordered List/OL no attr"}
	{"Lists/New List Item" "Lists/List Item"}
	{"Lists/Discursive" "Lists/Definition List"}
	{"Lists/New Discursive Entry" "Lists/Definition Entry"}
	{"Style/ImportÉ" "CSS/@Import"}
	{"Style/Font" "Fonts/Font"}
	{"Style/Color" "Color/Color"}
	{"Style/Background" "Color/Background"}
	{"Style/Text" "CSS/Text"}
	{"Style/Margin" "Box/Margin"}
	{"Style/Padding" "Box/Padding"}
	{"Style/Border" "Box/Border"}
	{"Style/Border Width" "Box/Border Width"}
	{"Style/Border Style" "Box/Border Style"}
	{"Style/Border Color" "Box/Border Color"}
	{"Style/Size" "Paged/Size"}
	{"Style/Float" "Visual/Floats"}
	{"Style/Display" "Visual/Display"}
	{"Style/List Style" "Generated/List Style"}
	} {
		if {[info exists htmlMenuKey([lindex $__tmp 0])]} {
			if {![info exists htmlMenuKey([lindex $__tmp 1])]} {
				set htmlMenuKey([lindex $__tmp 1]) [set htmlMenuKey([lindex $__tmp 0])]
			}
			catch {unset htmlMenuKey([lindex $__tmp 0])}
		}
	}
	foreach __tmp {{"Utilities/Save to FTP Server/Forget Passwords" "FTP/Save to FTP Server" "FTP/Forget Passwords"}
	{"Utilities/Reformat Paragraph/Reformat Document" "Formatting/Reformat Paragraph" "Formatting/Reformat Document"}
	{"Home/Paste URL/Paste Include Tags" "Home/Paste URL" "Home/Paste Include Tags"}
	{"Blocks/Insert Line Breaks/Remove Line Breaks" "Blocks/Insert Line Breaks" "Blocks/Remove Line Breaks"}
	{"Tables/Tabs to RowsÉ/Rows to Tabs" "Tables/Tabs to RowsÉ" "Tables/Rows to Tabs"}
	{"Editing/Select Container/Select Opening" "Editing/Select Container" "Editing/Select Tag"}
	{"Editing/Untag/Untag and Select" "Editing/Untag" "Editing/Untag and Select"}
	{"Editing/Tags to Uppercase/Tags to Lowercase" "Editing/Tags to Uppercase" "Editing/Tags to Lowercase"}} {
		if {[info exists htmlMenuKey([lindex $__tmp 0])]} {
			if {![info exists htmlMenuKey([lindex $__tmp 1])]} {
				set htmlMenuKey([lindex $__tmp 1]) [set htmlMenuKey([lindex $__tmp 0])]
			}
			if {![info exists htmlMenuKey([lindex $__tmp 2])]} {
				set htmlMenuKey([lindex $__tmp 2]) "<I[set htmlMenuKey([lindex $__tmp 0])]"
			}
			catch {unset htmlMenuKey([lindex $__tmp 0])}
		}
	}
	foreach __tmp {"Style/Clear" "Preferences/JavaScript and CSSÉ"
	"Utilities/ColorsÉ" "Utilities/FootersÉ"
	"Extend/New AttributesÉ" "Extend/New ChoicesÉ" "Extend/Change Key BindingÉ"
	"Extend/Change Type and LayoutÉ" "Extend/Remove AttributesÉ"} {
		catch {unset htmlMenuKey($__tmp)}
	}
	html::WriteMenuKeys
}

if {[file exists [file join ${html::PrefsFolder} "HTML menu cache"]]} {
	catch {file delete [file join ${html::PrefsFolder} "HTML menu cache"]}
}
if {[file exists [file join ${html::PrefsFolder} "HTML Utilities menu cache"]]} {
	catch {file delete [file join ${html::PrefsFolder} "HTML Utilities menu cache"]}
}
if {[file exists [file join ${html::PrefsFolder} "CSS menu cache"]]} {
	catch {file delete [file join ${html::PrefsFolder} "CSS menu cache"]}
}

#===============================================================================
# ×××× Custom elements ×××× #
#===============================================================================

# Update pre 3.0a7 Custom element prefs
foreach __fil [glob -nocomplain -dir [file join ${html::PrefsFolder} "New elements"] *] {
	if {![catch {open $__fil r+} __fid]} {
		set __vers [gets $__fid]
		if {$__vers > 2.9} {
			close $__fid
			continue
		}
		set __out "$htmlVersion\n"
		append __out [gets $__fid] "\n" [gets $__fid] "\n" [gets $__fid] "\n" [gets $__fid] "\n"
		append __out "visible\n"
		append __out [read $__fid]
		seek $__fid 0
		puts $__fid [string trimright $__out]
		close $__fid
	}
}

# Updating 2.x  Custom element prefs
if {[file exists [file join $PREFS HTMLadditions.tcl]] &&
![catch {open [file join $PREFS HTMLadditions.tcl] r} __fid]} {
	status::msg "Updating custom elementsÉ"
	html40.tcl
	html::ReadMenuKeys
	set __additions [read -nonewline $__fid]
	close $__fid
	set __lines [split $__additions "\n"]

	set __allattrs [html::GetAllAttrs]

	set __tmpSpecURL ""
	set __tmpSpecColor ""
	set __tmpSpecWindow ""
	set __htmlURLAttr [html::GetURLAttrs]
	set __htmlColorAttr [html::GetColorAttrs]
	set __htmlWindowAttr [html::GetAttrOfType frametarget]
	set __newElems ""
	set __modifiedElems ""
	catch {unset __AttrChoices}
	catch {unset __ExtraChoices}
	catch {unset __AttrType}
	catch {unset __AttrRange}
	catch {unset __AttrOptional}
	catch {unset __AttrRequired}
	foreach __line [lrange $__lines 1 end] {
		set __elem [lindex $__line 0]
		if {[lsearch -exact {TEXT CHECKBOX RADIO SUBMIT RESET PASSWORD HIDDEN IMAGE FILE LIVEAUDIO LIVEVIDEO
		"QUICKTIME MOVIE" "QUICKTIME VR" REALAUDIO} $__elem] >=0} {continue}
		set __command [lindex $__line 1]
		set __elemExists [info exists html::ElemAttrOptional($__elem)]
		if {$__elemExists} {
			lappend __modifiedElems $__elem
			foreach __x [list AttrOptional AttrRequired] {
				if {[info exists html::Elem${__x}($__elem)]} {
					set htmlElem${__x}1 [string toupper [set html::Elem${__x}($__elem)]]
				} else {
					set htmlElem${__x}1 ""
				}
			}
			set __attrs [concat $htmlElemAttrOptional1 $htmlElemAttrRequired1]
			foreach __at $__attrs {
				if {[string trimright $__at =] == $__at} {
					lappend __attrs "${__at}="
				} else {
					lappend __attrs [string trimright $__at =]
				}
			}
		} else {
			lappend __newElems $__elem
			set __attrs {}
		}
		set __var [lindex $__command 1]
		foreach __ucw [list URL Color Window] {
			if {$__var == "html${__ucw}Attr"} {
				set __tmp [lindex $__command 2]
				lappend __html${__ucw}Attr $__tmp
				if {$__ucw == "URL"} {set __AttrType($__elem%$__tmp) url}
				if {$__ucw == "Color"} {set __AttrType($__elem%$__tmp) color}
				if {$__ucw == "Window"} {set __AttrType($__elem%$__tmp) frametarget}
			}
			if {$__var == "htmlSpec${__ucw}"} {
				set __tmpadd [lrange $__command 2 end]
				foreach __x $__tmpadd {
					regexp {[^!=](!?=)(.*)} $__x __ __sign __tmp
					# Only add if attr doesn't exist.
					if {[lsearch -exact $__attrs $__tmp] < 0} {
						if {$__sign == "!="} {
							if {![info exists __AttrType($__elem%$__tmp=)] && ![info exists __AttrType($__elem%[string trim $__tmp =])]} {
								set __AttrType($__elem%$__tmp=) other
							}
						} else {
							if {$__ucw == "URL"} {set __AttrType($__elem%$__tmp=) url}
							if {$__ucw == "Color"} {set __AttrType($__elem%$__tmp=) color}
							if {$__ucw == "Window"} {set __AttrType($__elem%$__tmp=) frametarget}
						}
					}
				}
			}
		}
		if {[lsearch {htmlURLAttr htmlColorAttr htmlWindowAttr htmlSpecURL \
		  htmlSpecColor htmlSpecWindow} $__var] < 0} {
			if {[string match "htmlElemKeyBinding*" $__var]} {
				if {!$__elemExists} {
					eval $__command
				}
				continue
			}
			if {[string match "htmlElemProc*" $__var]} {
				if {!$__elemExists} {
					eval $__command
				}
				continue
			}
			if {$__var == "htmlPlugins"} {
				if {!$__elemExists} {
					eval $__command
				}
				continue
			}
			
		  	regexp {([^\(]+)\(([^\)]+)\)[ ]+(.+)} [lrange $__command 1 end] __ __var __arg __added
			set __added [string trimleft [string trimright $__added \}] \{]
			foreach __c $__added {
				if {$__var == "htmlElemAttrChoices1"} {
					regexp {([^=]*=)(.*)} $__c __ __tmp __ch
					# Don't add choices if they exist or if attr isn't a choice attr.
					if {[lsearch -exact $__attrs $__tmp] < 0} {
						set __AttrType($__elem%$__tmp) choices
						lappend __AttrChoices($__elem%$__tmp) $__ch
					} elseif {[html::GetAttrType $__elem $__tmp] == "choices"} {
						if {[lsearch -exact [html::GetAttrChoices $__elem $__tmp] $__ch] < 0} {
							lappend __ExtraChoices($__elem) $__tmp
							lappend __AttrChoices($__elem%$__tmp) $__ch
						}
					}
				}
				if {$__var == "htmlElemAttrNumber1"} {
					regexp {([^=]*=)(.*)} $__c __ __tmp __num
					if {[lsearch -exact $__attrs $__tmp] < 0} {
						regexp {([^:]+:[^:]+):(.*)} $__num __ __val __proc
						if {$__proc == "n"} {
							set __AttrType($__elem%$__tmp) integer
						} else {
							set __AttrType($__elem%$__tmp) length
						}
						set __AttrRange($__elem%$__tmp) $__val
					}
				}
				if {$__var == "htmlElemAttrOptional1"} {
					if {[lsearch -exact $__attrs $__c] < 0} {
						lappend __AttrOptional($__elem) $__c
						if {![info exists __AttrType($__elem%$__c)] && ![info exists __AttrType($__elem%[string trim $__c =])]} {
							if {[regexp = $__c]} {
								if {[lcontains __htmlURLAttr $__c]} {
									set __AttrType($__elem%$__c) url
								} elseif {[lcontains __htmlColorAttr $__c]} {
									set __AttrType($__elem%$__c) color
								} elseif {[lcontains __htmlWindowAttr $__c]} {
									set __AttrType($__elem%$__c) frametarget
								} else {
									set __AttrType($__elem%$__c) other
								}
							} else {
								set __AttrType($__elem%$__c) flag
							}
						}
					}
				}
				if {$__var == "htmlElemAttrRequired1"} {
					if {[lsearch -exact $__attrs $__c] < 0} {
						lappend __AttrRequired($__elem) $__c
						if {![info exists __AttrType($__elem%$__c)] && ![info exists __AttrType($__elem%[string trim $__c =])]} {
							if {[regexp = $__c]} {
								if {[lcontains __htmlURLAttr $__c]} {
									set __AttrType($__elem%$__c) url
								} elseif {[lcontains __htmlColorAttr $__c]} {
									set __AttrType($__elem%$__c) color
								} elseif {[lcontains __htmlWindowAttr $__c]} {
									set __AttrType($__elem%$__c) frametarget
								} else {
									set __AttrType($__elem%$__c) other
								}
							} else {
								set __AttrType($__elem%$__c) flag
							}
						}
					}
				}
			}
		}
	}
	file::ensureDirExists [file join ${html::PrefsFolder} "New elements"]
	file::ensureDirExists [file join ${html::PrefsFolder} "Modified elements"]
	foreach __tmp [lunique $__newElems] {
		set __out "$htmlVersion\n"
		set __input [string match htmlBuildInputElem* $htmlElemProc($__tmp)]
		if {[lcontains htmlPlugins $__tmp] || $__input} {
			append __out "open00\n"
		} else {
			set __proc [lindex $htmlElemProc($__tmp) 0]
			if {$__proc == "htmlBuildElem"} {append __out "nocr\n"}
			if {$__proc == "htmlBuildCRElem" && [llength $htmlElemProc($__tmp)] == 2} {append __out "cr0\n"}
			if {$__proc == "htmlBuildCRElem" && [llength $htmlElemProc($__tmp)] == 3} {append __out "cr1\n"}
			if {$__proc == "htmlBuildCR2Elem"} {append __out "cr2\n"}
			if {$__proc == "htmlBuildOpening"} {append __out "open[join [lrange $htmlElemProc($__tmp) 2 3] ""]\n"}
		}
		append __out "Custom\n"
		if {[lcontains htmlPlugins $__tmp]} {
			append __out "plugin\n"
		} elseif {$__input} {
			append __out "input\n"
		} else {
			append __out "normal\n"
		}
		append __out "$htmlElemKeyBinding($__tmp)\n"
		append __out "visible\n"
		if {[info exists __AttrOptional($__tmp)]} {
			foreach __a $__AttrOptional($__tmp) {
				if {![info exists __AttrType($__tmp%$__a)]} {set __AttrType($__tmp%$__a) other}
				append __out "$__a $__AttrType($__tmp%$__a) 0"
				if {$__AttrType($__tmp%$__a) == "choices" && [info exists __AttrChoices($__tmp%$__a)]} {append __out " " $__AttrChoices($__tmp%$__a)}
				if {($__AttrType($__tmp%$__a) == "integer" || $__AttrType($__tmp%$__a) == "length") &&
				[info exists __AttrRange($__tmp%$__a)]} {
					append __out " " $__AttrRange($__tmp%$__a)
				}
				append __out "\n"
			}
		}
		if {[info exists __AttrRequired($__tmp)]} {
			foreach __a $__AttrRequired($__tmp) {
				if {![info exists __AttrType($__tmp%$__a)]} {set __AttrType($__tmp%$__a) other}
				append __out "$__a $__AttrType($__tmp%$__a) 1"
				if {$__AttrType($__tmp%$__a) == "choices" && [info exists __AttrChoices($__tmp%$__a)]} {append __out " " $__AttrChoices($__tmp%$__a)}
				if {$__AttrType($__tmp%$__a) == "integer" || $__AttrType($__tmp%$__a) == "length" && 
				[info exists __AttrRange($__tmp%$__a)]} {
					append __out " " $__AttrRange($__tmp%$__a)
				}
				append __out "\n"
			}
		}
		if {$__input} {
			if {[file exists [file join ${html::PrefsFolder} "New elements" "INPUT TYPE=$__tmp"]] || 
			[catch {open [file join ${html::PrefsFolder} "New elements" "INPUT TYPE=$__tmp"] w} __fid]} {continue}
		} else {
			if {[file exists [file join ${html::PrefsFolder} "New elements" "$__tmp"]] || 
			[catch {open [file join ${html::PrefsFolder} "New elements" "$__tmp"] w} __fid]} {continue}
		}
		set htmlMenuKey(Custom/[string index $__tmp 0][string tolower [string range $__tmp 1 end]]) $htmlElemKeyBinding($__tmp)
		puts -nonewline $__fid $__out
		close $__fid
	}
	foreach __tmp [lunique $__modifiedElems] {
		set __out "$htmlVersion\n"
		if {[info exists __AttrOptional($__tmp)]} {
			foreach __a $__AttrOptional($__tmp) {
				if {![info exists __AttrType($__tmp%$__a)]} {set __AttrType($__tmp%$__a) other}
				append __out "$__a $__AttrType($__tmp%$__a) 0"
				if {$__AttrType($__tmp%$__a) == "choices" && [info exists __AttrChoices($__tmp%$__a)]} {append __out " " $__AttrChoices($__tmp%$__a)}
				if {($__AttrType($__tmp%$__a) == "integer" || $__AttrType($__tmp%$__a) == "length") &&
				[info exists __AttrRange($__tmp%$__a)]} {
					append __out " " $__AttrRange($__tmp%$__a)
				}
				append __out "\n"
			}
		}
		if {[info exists __AttrRequired($__tmp)]} {
			foreach __a $__AttrRequired($__tmp) {
				if {![info exists __AttrType($__tmp%$__a)]} {set __AttrType($__tmp%$__a) other}
				append __out "$__a $__AttrType($__tmp%$__a) 1"
				if {$__AttrType($__tmp%$__a) == "choices" && [info exists __AttrChoices($__tmp%$__a)]} {append __out " " $__AttrChoices($__tmp%$__a)}
				if {$__AttrType($__tmp%$__a) == "integer" || $__AttrType($__tmp%$__a) == "length" && 
				[info exists __AttrRange($__tmp%$__a)]} {
					append __out " " $__AttrRange($__tmp%$__a)
				}
				append __out "\n"
			}
		}
		if {[info exists __ExtraChoices($__tmp)]} {
			foreach __a [lunique $__ExtraChoices($__tmp)] {
				if {[info exists __AttrChoices($__tmp%$__a)]} {append __out "#" $__a " " $__AttrChoices($__tmp%$__a) "\n"}
			}
		}
		if {$__out == "$htmlVersion\n" || [file exists [file join ${html::PrefsFolder} "Modified elements" "$__tmp"]] || 
		[catch {open [file join ${html::PrefsFolder} "Modified elements" "$__tmp"] w} __fid]} {continue}
		puts -nonewline $__fid $__out
		close $__fid
	}
	html::WriteMenuKeys
	rename html40.tcl ""
	catch {file delete [file join $PREFS HTMLadditions.tcl]}
	if {[file exists [file join ${html::PrefsFolder} "Additions cache"]]} {
		catch {file delete [file join ${html::PrefsFolder} "Additions cache"]}
	}
	if {[file exists [file join ${html::PrefsFolder} "Additions coloring cache"]]} {
		catch {file delete [file join ${html::PrefsFolder} "Additions coloring cache"]}
	}
	if {[file exists [file join ${html::PrefsFolder} "CSS keybindings cache"]]} {
		catch {file delete [file join ${html::PrefsFolder} "CSS keybindings cache"]}
	}
}

unset -nocomplain __tmp

set html::PrefsVersion $htmlVersion
prefs::add html::PrefsVersion $htmlVersion

status::msg "Updating of preferences done."
