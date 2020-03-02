## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlProcs.tcl"
 #                                    created: 99-07-20 18.20.31 
 #                                last update: 03/21/2006 {03:09:48 PM} 
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
# Temporary workarounds of core bugs
#===============================================================================

proc htmlProcs.tcl {} {}

namespace eval html::quote {}

proc html::quote::Unurl {str} {
	set hexa {0 1 2 3 4 5 6 7 8 9 A B C D E F}
	set nstr ""
	while {[regexp -indices {%[0-9A-F][0-9A-F]} $str hex]} {
		append nstr [string range $str 0 [expr {[lindex $hex 0] - 1}]]
		append nstr [text::Ascii [expr {16 * [lsearch $hexa [string index $str [expr {[lindex $hex 0] + 1}]]] \
		  + [lsearch $hexa [string index $str [expr {[lindex $hex 0] + 2}]]]}] 1]
		set str [string range $str [expr {[lindex $hex 1] + 1}] end]
	}
	return "$nstr$str"
}

#===============================================================================
# end of workarounds
#===============================================================================

proc html::UseOptionalClosingTag {elem} {
	global HTMLmodeVars html::xhtml
	return [expr {$html::xhtml || [lcontains HTMLmodeVars(optionalClosing) $elem]}]
}

proc html::EndOfEmptytag {tag} {
	global HTMLmodeVars
	set repl ""
	if {$HTMLmodeVars(extraSpace)} {set repl " "}
	append repl "/>"
	return [string replace $tag end end $repl]
}

# Checks if the current position is inside the container ELEM.
proc html::IsInContainer {args} {
	win::parseArgs w elem {pos ""}
	set exp1 "<${elem}(\[ \t\r\n\]+\[^<>\]*>|>)"
	set exp2 "</${elem}>"
	return [html::_IsInContainer -w $w $pos $exp1 $exp2]
}

proc html::IsInCommentContainer {args} {
	win::parseArgs w elem {pos ""}
	set exp1 "<!--\[ \t\r\n\]*#${elem}\[ \t\r\n\]*-->"
	set exp2 "<!--\[ \t\r\n\]*/#${elem}\[ \t\r\n\]*-->"
	return [html::_IsInContainer -w $w $pos $exp1 $exp2]
}

proc html::_IsInContainer {args} {
	win::parseArgs w pos exp1 exp2
	if {$pos == ""} {set pos [getPos -w $w]}
	if {![catch {search -w $w -s -f 0 -r 1 -i 1 -m 0 $exp1 $pos} res1] && [pos::compare -w $w $pos > [lindex $res1 1]] &&
	([catch {search -w $w -s -f 0 -r 1 -i 1 -m 0 $exp2 $pos} res2] || 
	[pos::compare -w $w [lindex $res1 0] > [lindex $res2 0]])} {
		return 1
	}
	return 0	
}

proc html::IsThereAHomePage {} {
	global HTMLmodeVars	
	if {![llength $HTMLmodeVars(homePages)]} {
		alertnote "You must set a home page folder."
		html::HomePages
	}
	return [llength $HTMLmodeVars(homePages)]
}

proc html::WhichHomePage {msg} {
	global HTMLmodeVars
	foreach hp $HTMLmodeVars(homePages) {
		lappend hplist "[lindex $hp 1][lindex $hp 2]"
	}
	if {[catch {listpick -p "Select home page to $msg." $hplist} hp] || ![string length $hp]} {error ""}
	set home [lindex $HTMLmodeVars(homePages) [lsearch -exact $hplist $hp]]
	if {![file exists [lindex $home 0]] || ![file isdirectory [lindex $home 0]]} {
		alertnote "Can't find the folder for [lindex $home 1][lindex $home 2]"
		error ""
	}
	return $home
}

# Determines the path to the home page folder corresponding to path.
# If none, return empty string.
proc html::WhichHomeFolder {path} {
	set p [html::BASEfromPath $path]
	if {[lindex $p 0] != "file:///"} {return [list [lindex $p 3] [lindex $p 0] [lindex $p 1]]}
	return ""
}


# Determines the path to the include folder corresponding to path.
# If none, return empty string.
proc html::WhichInclFolder {path} {
	return [lindex [html::BASEfromPath $path] 5]
}

# Puts up a window with error text.
proc html::ErrorWindow {errHeader errText {cancelButton 0}} {
	
	set errbox [dialog::title $errHeader 480]
	set hpos 15
	foreach err $errText {
		if {[string length $err] < 55} {
			lappend errbox -t $err 10 $hpos 450 [expr {$hpos + 15}]
			incr hpos 20
		} else {
			lappend errbox -t $err 10 $hpos 450 [expr {$hpos + 30}]
			incr hpos 35
		}
	}
	if {$cancelButton} {
		lappend errbox -b Cancel 315 [expr {$hpos + 20}] 380 [expr {$hpos + 40}]
	}
	
	set val [eval [concat dialog -w 480 -h [expr {$hpos + 50}] \
	-b OK 400 [expr {$hpos + 20}] 465 [expr {$hpos + 40}] $errbox]]
	return [lindex $val 0]
}


proc html::IsInteger {str} {
	return [regexp {^-?[0-9]+$} [string trim $str]]
}

# Checks to see if the current window is empty, except for whitespace.
proc html::IsEmptyFile {} {
	return [catch {search -s -f 1 -r 1 {[^ \t\r\n]+} [minPos]}]
}


# Quoting of strings for meta tags.
proc html::Quote {str} {
	regsub -all "#" $str {#;} str
	regsub -all "\"" $str {#qt;} str
	regsub -all "<" $str {#lt;} str
	regsub -all ">" $str {#gt;} str
	return $str
}

proc html::UnQuote {str} {
	regsub -all {#qt;} $str "\"" str
	regsub -all {#lt;} $str "<" str
	regsub -all {#gt;} $str ">" str
	regsub -all {#;} $str "#" str
	return $str
}

proc html::FindLargestMatch {ll pat {u ""} {sort 0}} {
	global listPickIfMultCmps
	upvar $ll l
	set matches ""
	foreach p $l {
		if {[string match $pat* $p]} {lappend matches $p}
	}
	if {$sort} {set matches [lsort $matches]}
	if {[llength $matches] > 1 && [info exists listPickIfMultCmps] && $listPickIfMultCmps} {
		set matches [list [listpick -p "Pick a completion" $matches]]
		if {$matches == ""} {error ""}
	}
	if {$u != ""} {
		upvar $u unique
		set unique [expr {[llength $matches] == 1}]
	}
	if {![llength $matches]} {return ""}
	return [largestPrefix $matches]
}

# Find the version number of a program.
proc html::GetVersion {sig} {
	if {[catch {app::ensureRunning $sig}]} {
		return 0
	}
	set res [tclAE::send -r '$sig' core getd ---- [tclAE::build::propertyObject vers]]
	set vers [tclAE::getKeyData $res ---- TEXT]
	tclAE::disposeDesc $res
	return $vers
}

proc html::CommentStrings {} {
	if {[html::IsInContainer SCRIPT] || [html::IsInContainer STYLE]} {
		return [list "/* " " */"]
	} else {
		return [list "<!-- " " -->"]
	}
}

proc html::URLregexp {} {
	set exp "([join [html::GetURLAttrs] |])"
	regsub -all {=} $exp "" exp
	append exp {[ \t\n\r]*=[ \t\n\r]*("[^">]+"|'[^'>]+'|[^ \t\n\r"'>]+)}	
	return $exp
}

# Create a string for URL mapping in Big Brother.
proc html::URLmap {} {
	global HTMLmodeVars alpha::macos
	set urlmap {}
	foreach hp $HTMLmodeVars(homePages) {
		set fld "[quote::Url [lindex $hp 0] [expr {$alpha::macos != 2}]]"
		if {$alpha::macos == 2} {set fld [tclAE::getHFSPath $fld]}
		append fld /
		regsub -all ":" $fld "/" fld
		set url [quote::Url "[lindex $hp 1][lindex $hp 2]"]
		append urlmap " \{Msta:Ò${url}Ó, Mend:Òfile:///${fld}Ó\}"
		append urlmap ","
	}
	set urlmap [string trimright $urlmap ","]
	return $urlmap
}

# Makes a line for browser error window.
proc html::BrwsErr {fil l lnum ln text path} {
	return "$fil[format "%$l\s" ""]; Line $lnum:[format "%$ln\s" ""]$text\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$path\r"
}

proc html::SetWin {} {
	insertColorEscape [minPos] 1
	insertColorEscape [nextLineStart [nextLineStart [minPos]]] 0
	selectText [nextLineStart [nextLineStart [minPos]]] \
	  [nextLineStart [nextLineStart [nextLineStart [minPos]]]]
	setWinInfo dirty 0
	setWinInfo read-only 1
	scrollUpLine; scrollUpLine
	refresh
}
	
proc html::IsTextFile {fil cmd} {
	if {[file isdirectory $fil] || [file::getType $fil] != "TEXT"} {
		$cmd "[file tail $fil] is not a text file."
		return 0
	}
	return 1
}

proc html::AllSaved {msg} {
	set dirty 0
	foreach w [winNames -f] {
		if {![catch {getWinInfo -w $w arr}] && $arr(dirty)} {set dirty 1; break}
	}
	if {$dirty} {
		set yn [eval [concat askyesno $msg]]
		if {$yn == "yes"} {saveAll}
		return $yn
	}
	return yes
}

# Determines in which home page folder a URL points to.
# If none, return empty string.
proc html::InWhichHomePage {url} {
	global HTMLmodeVars
	foreach p $HTMLmodeVars(homePages) {
		if {[string match "[lindex $p 1][lindex $p 2]*" $url]} {return [lindex $p 0]}
	}
	return ""
}

# Asks for a folder and checks that it is not an alias.
proc html::GetDir {prompt} {
	while {1} {
		if {[file isdirectory [set folder [get_directory -p $prompt]]]} {
			break
		} else {
			alertnote "Sorry! Cannot resolve aliases."
		}
	}
	set folder [file join [file dir $folder] [file tail $folder]]
	return $folder
}

proc html::getFileEncoding {f} {
	global alpha::defaultEncoding defaultEncoding
	set enc [alpha::encodingFor $f]
	if {$enc != ""} {return $enc}
	if {[info exists defaultEncoding]} {return $defaultEncoding}
	return ${alpha::defaultEncoding}
}

# Returns a list of all attributes used in any HTML element.
proc html::GetAllAttrs {} {
	global html::ElemAttrOptional html::ElemAttrRequired
	
	foreach elem [array names html::ElemAttrOptional] {
		if {[info exists html::ElemAttrRequired($elem)]} {
			append allHTMLattrs " " [set html::ElemAttrRequired($elem)]
		}
		append allHTMLattrs " " [set html::ElemAttrOptional($elem)]
	}
	return $allHTMLattrs
}


# Snatch the current selection into htmlCurSel, set flag whether there is one
proc html::GetSel {} {
	global htmlCurSel htmlIsSel
	set htmlCurSel [string trim [getSelect]]
	set htmlIsSel [string length $htmlCurSel]
}

proc html::AdditionsExists {} {
	global html::PrefsFolder
	return [expr {![catch {glob -dir [file join ${html::PrefsFolder} "New elements"] *}] || \
	  ![catch {glob -dir [file join ${html::PrefsFolder} "Modified elements"] *}]}]
}

proc html::NewElementsExists {} {
	global html::PrefsFolder
	return [expr {![catch {glob -dir [file join ${html::PrefsFolder} "New elements"] *}]}]
}

proc html::FrontWindowPath {} {
	global tcl_platform
	set w [lindex [winNames -f] 0]
	if {$tcl_platform(platform) == "windows"} {
		regsub -all {\\} $w / w
	}
	return $w
}

proc html::StrippedFrontWindowPath {} {
	return [win::StripCount [html::FrontWindowPath]]
}

proc html::AllWindowPaths {} {
	global tcl_platform
	set w [winNames -f]
	if {$tcl_platform(platform) == "windows"} {
		regsub -all {\\} $w / w
	}
	return $w
}

proc html::FindFirstOccurance {exp pos {dir 1}} {
	while {![catch {search -s -f $dir -r 1 -i 1 -m 0 $exp $pos} res] && 
	![catch {search -s -f 0 -r 1 -i 1 -m 0 "<!--" [lindex $res 0]} res1] &&
	![catch {search -s -f 1 -r 1 -i 1 -m 0 -- "-->" [lindex $res1 1]} res2] && [pos::compare [lindex $res2 1] > [lindex $res 1]]} {
		if {$dir} {
			set pos [lindex $res2 1]
		} else {
			set pos [pos::math [lindex $res1 0] - 1]
		}
	}
	if {![catch {search -s -f $dir -r 1 -i 1 -m 0 $exp $pos} res]} {
		return $res
	}
	error "Not found."
}

proc html::filejoin {folder fil} {
	global tcl_platform
	if {$tcl_platform(platform) == "macintosh"} {
		return [file join $folder "[file separator]$fil"]
	}
	return [file join $folder $fil]
}

proc html::GetLineEndings {fil} {
	if {[catch {open $fil} fid]} {return mac}
	fconfigure $fid -translation binary
	set cont [read $fid 5000]
	close $fid
	if {[regexp "\n\r" $cont] || [regexp "\r\n" $cont]} {return win}
	if {[regexp "\r" $cont]} {
		return mac
	}
	if {[regexp "\n" $cont]} {
		return unix
	}
	return mac
}

#===============================================================================
# The following 5 procs are extracted from html::TidyUp2. They are hardcoded
# into html::TidyUp2 for efficiency reasons
#===============================================================================

proc html::prepareForBreaking {wholeTag} {
	set w ""
	# To avoid line breaks inside attributes
	while {[regexp -indices {=[ \t\r\n]*(\"[^ \"]* [^\"]*\"|'[^ ']* [^']*')} $wholeTag i]} {
		append w [string range $wholeTag 0 [expr {[lindex $i 0] - 1}]]
		regsub -all "\[ \t\r\n\]+" [string range $wholeTag [lindex $i 0] [lindex $i 1]] "" w1
		append w $w1
		set wholeTag [string range $wholeTag [expr {[lindex $i 1] + 1}] end]
	}
	set wholeTag $w$wholeTag
	return $wholeTag
}

proc html::BreakIntoLines {tmp ind} {
	regsub -all "\[ \t\]*\[\r\n\]\[ \t\]*" [string trim $tmp] " " tmp
	set tmp [string trimright [breakIntoLines $tmp]]
	regsub -all "" $tmp " " tmp
	regsub -all "\r" $tmp "\r$ind" tmp
	return $tmp
}

proc html::indentCR {args} {
	global html::ElemLayout
	foreach c $args {
		upvar crBef$c crBef$c crAft$c crAft$c crBef/$c crBef/$c crAft/$c crAft/$c
		upvar blBef$c blBef$c blAft$c blAft$c blBef/$c blBef/$c blAft/$c blAft/$c
		set crBef$c 0; set crAft$c 0; set crBef/$c 0; set crAft/$c 0
		set blBef$c 0; set blAft$c 0; set blBef/$c 0; set blAft/$c 0
		switch [set html::ElemLayout($c)] {
			open00 -
			nocr {}
			open01 {set crAft$c 1}
			open10 {set crBef$c 1}
			open11 {set crBef$c 1; set crAft$c 1}
			cr0 {set crBef$c 1; set crAft/$c 1}
			cr1 {set blBef$c 1; set blAft/$c 1}
			cr2 {set blBef$c 1; set crBef/$c 1; set blAft/$c 1; set crAft$c 1}
		}
	}
}

proc html::crBefore {blBef crBef t ind c cu new} {
	upvar $t text $c cr $cu curr
	if {$blBef || $crBef} {
		if {![is::Whitespace $curr]} {set cr 0; append text $ind}
		append text [html::BreakIntoLines $curr $ind]
		if {$cr == 1 && $blBef} {append text $ind}
		if {$cr == 0} {
			append text \r
			incr cr
			if {$cr == 1 && $blBef} {append text \r; incr cr}
		}
		if {$blBef && $cr < 2} {append text \r}
		set curr $new
	} else {
		append curr $new
	}
}

proc html::crAfter {blAft crAft t i c cu closing indent} {
	upvar $t text $c cr $i ind $cu curr
	set cr 0
	if {$blAft || $crAft} {
		if {$closing && $indent} {
			set ind [string range $ind 1 end]
		}
		if {![is::Whitespace $curr]} {append text $ind}
		append text [html::BreakIntoLines $curr $ind]
		if {$indent && !$closing} {append ind \t}
		append text \r
		incr cr
		if {$blAft} {
			append text $ind
			append text \r
			incr cr
		}
		set curr ""
	}
}

proc html::elecInsertion {text} {
	global HTMLmodeVars
	upvar $text t
	if {$HTMLmodeVars(adjustIndentation) && [is::Whitespace [getText [lineStart [getPos]] [getPos]]]} {HTML::indentLine}
	if {[html::IndentShouldBeAdjusted]} {regsub -all  "\r" $t "\r\t" t}
	if {[pos::compare [set p [text::firstNonWsLinePos [getPos]]] > [getPos]]} {goto $p}
	elec::Insertion $t
}

proc html::SaveBeforeSending {path} {
	global HTMLmodeVars
	if {[info exists HTMLmodeVars(saveWithoutAsking)] && $HTMLmodeVars(saveWithoutAsking)} {
		save 
	} else {
		set ask [dialog -w 300 -h 130 -t "Save '[file tail $path]'?" 10 10 240 30 \
		  -c "Always save without asking when" 0 10 40 250 58 \
		  -t "sending a window to the browser." 25 60 290 80 \
		  -b Yes 220 100 285 120 \
		  -b No 135 100 200 120 -b Cancel 10 100 75 120]
		if {[lindex $ask 3]} {error "Cancel"}
		if {[lindex $ask 0]} {
			set HTMLmodeVars(saveWithoutAsking) 1
			prefs::modifiedModeVar saveWithoutAsking HTML
		}
		if {[lindex $ask 1]} {save}
	}
}

#===============================================================================
# ×××× Help ×××× #
#===============================================================================

# opens the manual in the browser.
proc html::Help {} {
	global HOME HTMLmodeVars browserSig
	set path [help::pathToHelp [file join "HTML Help" HTMLmanual.html]]
	if {![file exists $path]} {
		alertnote "Could not find the HTML manual."
		return
	}
	html::SendWindow $path
	if {!$HTMLmodeVars(browseInForeground)} {switchTo '$browserSig'}
}

#===============================================================================
# ×××× Send file to browser ×××× #
#===============================================================================

proc html::SendWindow {{path ""} {url 0}} {
	global HTMLmodeVars browserSig tcl_platform alpha::macos

	if {$path == ""} {
		if {![llength [winNames]]} {return}
		set path [html::StrippedFrontWindowPath]

		if {[winDirty]} {
			html::SaveBeforeSending $path
			# Get path again, in case it was Untitled before.
			set path [html::StrippedFrontWindowPath]
			if {![file exists $path]} {
				alertnote "Can't send window to browser."
				return
			}
		}
	}
	if {$url} {set path [join [lrange [html::BASEfromPath $path] 0 2] ""]}
	if {${alpha::macos}} {
		if {![info exists browserSig] && [catch {file::getSig [icGetPref -t 1 Helper¥http]} browserSig]} {set browserSig MSIE}
		if {[catch {app::launchBack $browserSig}]} {
			app::getSig "Please locate your web browser" browserSig
			app::launchBack $browserSig
		}
		if {$url} {
			tclAE::send '$browserSig' WWW! OURL "----" [tclAE::build::TEXT ${path}] FLGS 1
		} else {
			if {$browserSig == "MOSS" || $browserSig == "MOZZ" || $browserSig == "hbwr"} {
				sendOpenEvent noReply '$browserSig' $path
			} else {
				set origpath $path
				set path [quote::Url $path [expr {$tcl_platform(platform) == "macintosh"}]]
				regsub -all : $path / path
				if {$tcl_platform(platform) == "macintosh"} {set path "/$path"}
				if {$tcl_platform(platform) == "unix" && $browserSig != "CHIM" && 
				$browserSig != "OWEB" && $browserSig != "MSIE" && $browserSig != "sfri"} {
					if {[regexp {/Volumes} $path]} {
						regsub {/Volumes} $path "" path
					} else {
						set path "/[quote::Url [file::startupDisk]]$path"
					}
				}
				tclAE::send '$browserSig' WWW! OURL "----" [tclAE::build::TEXT file://${path}] FLGS 1
			}
		}
	} else {
		if {![file exists $browserSig]} {
			set browserSig [getfile "Please locate your web browser"]
		}
		if {$tcl_platform(platform) == "windows"} {
		    exec $browserSig [file nativename $path] &
		}
		if {$tcl_platform(platform) == "unix"} {
			if {$url} {
				exec $browserSig -remote openURL($path) &
			} else {
				set path [quote::Url $path]
				exec $browserSig -remote openURL(file://$path) &
			}
		}
	}
	if {$HTMLmodeVars(browseInForeground)} {switchTo '$browserSig'}
}
