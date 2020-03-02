## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlDocumentUtils.tcl"
 #                                    created: 99-07-20 17.17.35 
 #                                last update: 03/21/2006 {03:08:38 PM} 
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
# This file contains procs for the menu items "New Document", "New with Content"
# "New Doc. with Frames", "Document Size", "Document Type", and "Document Index"
#===============================================================================

proc htmlDocumentUtils.tcl {} {}

#===============================================================================
# ×××× New document ×××× #
#===============================================================================

#
# Template for new file: HTML, TITLE, HEAD, BODY or FRAMESET
# Optionally input BASE, LINK, ISINDEX, META and SCRIPT in HEAD.
proc html::NewDocument {} {html::NewTemplate BODY}
proc html::NewwithContent {} {
	if {![win::checkIfWinToEdit]} {return}
	html::NewTemplate BODY 1
}
proc html::NewDoc.withFrames {} {html::NewTemplate FRAMESET}

proc html::NewTemplate {doctype {withContent 0}} {
	global htmlCurSel htmlIsSel HTMLmodeVars html::HeadElements html::HideDeprecated
	global html::LastNewHP html::LastNewTempl

	set indentHTML [lcontains HTMLmodeVars(indentElements) HTML]
	set indentHEAD [lcontains HTMLmodeVars(indentElements) HEAD]
	set indentBODY [lcontains HTMLmodeVars(indentElements) $doctype]
	set headIndent ""
	set bodyIndent ""
	set htmlIndent ""
	if {$indentHTML} {
		append htmlIndent "\t"
		append headIndent "\t"
		append bodyIndent "\t"
	}
	if {$indentHEAD} {append headIndent "\t"}
	if {$indentBODY} {append bodyIndent "\t"}
	
	if {![info exists html::LastNewHP]} {set html::LastNewHP " "}
	if {![info exists html::LastNewTempl]} {set html::LastNewTempl " "}
	
	if {$doctype == "FRAMESET"} {
		set htxt "New document with frames"
	} else {
		set htxt "New document"
	}
	
	set box "[dialog::title {Choose template} 300] -t {Home Page:} 10 20 100 35 \
	  -t {Template:} 10 50 100 65"
	set j 0
	if {!$withContent} {
		set fname ""
		if {[html::IsEmptyFile]} {
			set fname [win::StripCount [lindex [winNames] 0]]
		}
		append box " -t {File name:} 10 80 100 95 \
		  -e [list $fname] 110 80 340 95"
		incr j
	}
	set hpflds ""
	set sites ""
	foreach hp $HTMLmodeVars(homePages) {
		lappend hpflds [lindex $hp 0]
		lappend sites "[lindex $hp 1][lindex $hp 2]"
	}
	lappend box -m [concat [list ${html::LastNewHP}] $sites] 110 20 350 40
	set i 0
	incr j 3
	foreach hp $hpflds {
		foreach f $HTMLmodeVars(templateFolders) {
			if {[lindex $f 0] == $hp} {
				set tmpls($hp) {{ }}
				set tmplindex($hp) $j
				set tmplfld($hp) [lindex $f 1]
				incr j
				foreach t [glob -nocomplain -types TEXT -dir [lindex $f 1] *] {
					lappend tmpls($hp) [file tail $t]
				}
				lappend box -n [lindex $sites $i] -m [concat [list ${html::LastNewTempl}] $tmpls($hp)] 110 50 350 70
				break
			}
		}
		incr i
	}

	set values [eval [concat dialog -w 360 -h 140 -b OK 280 110 345 130 \
	  -b Cancel 195 110 260 130 $box]]
	if {[lindex $values 1]} {return}
	
	set hpfld [lindex $hpflds [lsearch -exact $sites [set html::LastNewHP [lindex $values [expr {2 + !$withContent}]]]]]
	if {[info exists tmpls($hpfld)] && [set html::LastNewTempl [lindex $values $tmplindex($hpfld)]] != " "} {
		set template [file join $tmplfld($hpfld) ${html::LastNewTempl}]
	}
	
	set bodyText ""
	if {$withContent} {
		set bodyText [getText [minPos] [maxPos]]
		deleteText [minPos] [maxPos]
	} else {
		if {[set filename [string trim [lindex $values 2]]] == ""} {set filename Untitled.html}
		if {![html::IsEmptyFile] || [win::StripCount [lindex [winNames] 0]] != $filename} {
			new -n $filename -m HTML
		}
	} 
	
	if {$indentHTML || $indentBODY} {regsub -all "\r" "\r$bodyText" "\r$bodyIndent" bodyText}
	
	if {[info exists template]} {
		if {[catch {file::readAll $template} templText]} {
			alertnote "Could not read template file."
		} else {
			insertText $templText
		}
	}

	if {![catch {search -s -f 1 -r 0 -i 1 -m 0 {#CONTENT#} [minPos]} res]} {
		replaceText [lindex $res 0] [lindex $res 1] $bodyText
	} elseif {![catch {search -s -f 1 -r 0 -i 1 -m 0 [html::CloseElem $doctype] [minPos]} res] || 
	  ![catch {search -s -f 1 -r 0 -i 1 -m 0 {</HTML>} [minPos]} res]} {
		goto [lindex $res 0]
		elec::Insertion $bodyText "\r\r"
	} else {
		goto [maxPos]
		elec::Insertion $bodyText "\r\r"
	}
		
	set docTitle ""
	if {![catch {html::FindFirstOccurance {<title[^<>]*>[^<>]*</title>} [minPos]} res]} {
		regexp -nocase {<title[^<>]*>([^<>]*)</title>} [eval getText $res] "" docTitle
	}	
	
	set inHead "0 0 [list $docTitle]"
	foreach elem ${html::HeadElements} {
		lappend inHead 0
	}
	if {[set dt [html::FindDoctype]] != ""} {
		set m0 [lindex [set types {"HTML 4.01 Strict" "HTML 4.01 Strict" "HTML 4.01 Transitional" "HTML 4.01 Frameset" \
		  "XHTML 1.0 Strict" "XHTML 1.0 Transitional" "XHTML 1.0 Frameset" "XHTML 1.1"}] \
		  [lsearch -exact {{} strict transitional frameset xhtml10strict xhtml10transitional xhtml10frameset xhtml11} $dt]]
		lappend inHead $m0
	} elseif {$doctype == "BODY"} {
		lappend inHead $HTMLmodeVars(lastDocType)
	} elseif {$doctype == "FRAMESET"} {
		lappend inHead $HTMLmodeVars(lastFrameDocType)
	}
	set first 1
	while {$first || $docTitle == ""} {
		set first 0
		# Construct the dialog box.
		set box "[dialog::title $htxt 300] -t {TITLE} 10 20 60 35 \
		-e [list [lindex $inHead 2]] 70 20 440 35 \
		-t {Select the elements you want in the document\'s HEAD} 10 50 390 65"
		set hpos 80
		set wpos 10
		set i 3
		foreach elem ${html::HeadElements} {
			append box " -c $elem [lindex $inHead $i] $wpos $hpos [expr {$wpos + 100}] [expr {$hpos + 15}]"
			incr wpos 100
			if {$wpos > 110} {set wpos 10; incr hpos 20}
			incr i
		}
		if {$wpos > 10} {incr hpos 20}
		incr hpos 10
		append box " -t {Document type declaration:} 220 80 405 95"
		if {$doctype == "BODY"} {
			append box " -m [list [list [lindex $inHead $i] None {HTML 4.01 Transitional} \
			  {HTML 4.01 Strict} {XHTML 1.0 Transitional} {XHTML 1.0 Strict} {XHTML 1.1}]] \
			  220 105 440 120"
		} else {
			append box " -m [list [list [lindex $inHead $i] None {HTML 4.01 Frameset} \
			  {XHTML 1.0 Frameset}]] 220 105 440 120"
		}
		append box " -t {XML encoding:} 220 130 315 150 \
		  -e [list [lindex $inHead [expr {$i + 1}]]] 325 130 440 145"
		set inHead [eval [concat dialog -w 450 -h [expr {$hpos + 30}] \
		-b OK 370 $hpos 435 [expr {$hpos + 20}] \
		-b Cancel 295 $hpos 360 [expr {$hpos + 20}] $box]]
		if {[lindex $inHead 1]} {return}
		set docTitle [string trim [lindex $inHead 2]]
		if {$docTitle == ""} {
			alertnote "A document title is required."
		}
	}
	
	set dtd [lindex $inHead $i]
	if {$dtd != "None"} {
		regsub {HTML 4.01 Strict} $dtd "HTML 4.01" xdtd
		if {[regexp {^X} $dtd]} {
			set type html
			set text {<?xml version="1.0"}
			if {[set enc [string trim [lindex $inHead [expr {$i + 1}]]]] != ""} {
				append text " encoding=\"$enc\""
			}
			append text "?>\r"
		} else {
			set text ""
			set type HTML
		}
		append text "<!DOCTYPE $type PUBLIC \"-//W3C//DTD $xdtd//EN\">\r"
		if {![catch {search -s -f 1 -r 1 -i 1 -m 0 {<!doctype[^<>]+>} [minPos]} res]} {
			replaceText [lindex $res 0] [lindex $res 1] $text
		} else {
			goto [minPos]
			insertText $text "\r"
		}
		if {$doctype == "BODY"} {
			set HTMLmodeVars(lastDocType) $dtd
			prefs::modifiedModeVar lastDocType HTML
		} else {
			set HTMLmodeVars(lastFrameDocType) $dtd
			prefs::modifiedModeVar lastFrameDocType HTML
		}
	} else {
		if {![catch {search -s -f 1 -r 1 -i 1 -m 0 {<!doctype[^<>]+>} [minPos]} res]} {
			eval deleteText $res
		}
		if {$doctype == "BODY"} {		
			set HTMLmodeVars(lastDocType) $dtd
			prefs::modifiedModeVar lastDocType HTML
		} else {
			set HTMLmodeVars(lastFrameDocType) $dtd
			prefs::modifiedModeVar lastFrameDocType HTML
		}
	}
	html::ActivateHook

	if {[catch {search -s -f 0 -r 0 -i 1 -m 0 {</HTML>} [maxPos]}]} {
		goto [maxPos]
		elec::Insertion [html::CloseElem HTML]
	}
	set htmlpos [search -s -f 0 -r 0 -i 1 -m 0 {</HTML>} [maxPos]]
	if {[catch {search -s -f 0 -r 0 -i 1 -m 0 "</$doctype>" [lindex $htmlpos 0]} res]} {
		goto [lindex $htmlpos 0]
		elec::Insertion "$htmlIndent[html::CloseElem $doctype]\r\r"
	}

	set pos [minPos]
	if {![catch {search -s -f 1 -r 1 -i 1 -m 0 {<!doctype[^<>]+>} [minPos]} res]} {
		set pos [lindex $res 1]
		if {[is::Whitespace [getText $pos [nextLineStart $pos]]]} {set pos [nextLineStart $pos]}
	}
	if {![catch {html::FindFirstOccurance {<html[^<>]*>} $pos} res]} {
		goto [pos::math [lindex $res 0] + 1]
		html::EditTag 1
		set pos [lindex $res 1]
	} else {
		goto $pos
		insertText [html::OpenElem HTML "" 0] "\r"
		set pos [getPos]
	}
	if {![catch {html::FindFirstOccurance {<head[^<>]*>} $pos} res]} {
		goto [pos::math [lindex $res 0] + 1]
		html::EditTag 1
		set pos [lindex $res 1]
	} else {
		goto $pos
		elec::Insertion $htmlIndent [html::OpenElem HEAD "" 0] "\r"
		set pos [getPos]
	}
	if {![catch {html::FindFirstOccurance {<title[^<>]*>[^<>]*</title>} $pos} res]} {
		regsub -nocase "(<title\[^<>\]*>)\[^<>\]*(</title>)" [eval getText $res] "\\1$docTitle\\2" dt
		replaceText [lindex $res 0] [lindex $res 1] $dt
		goto [pos::math [lindex $res 0] + 1]
		html::EditTag 1
		set pos [lindex [html::FindFirstOccurance "</title>" $pos] 1]
	} else {
		goto $pos
		insertText $docTitle
		selectText $pos [pos::math $pos + [string length $docTitle]]
		html::Tag TITLE
		set pos [getPos]
	}
	if {[catch {html::FindFirstOccurance {</head>} $pos} res]} {
		while {![catch {search -s -f 1 -r 1 -i 1 -m 0 {<!--|<[^<>]+>} $pos} res]} {
			set tagtxt [eval getText $res]
			if {[string range $tagtxt 0 3] == "<!--"} {
				# Comment
				if {![catch {search -s -f 1 -r 0 -m 0 -- {-->} [lindex $res 0]} res]} {
					set pos [lindex $res 1]
				} else {
					set pos [maxPos]
				}
				continue
			}
			if {![regexp -nocase "<([join ${html::HeadElements} |]|/SCRIPT|/STYLE|/OBJECT)(\[ \t\r\n\]+|>)" $tagtxt]} {break}
			set pos [lindex $res 1]
		}
		if {[is::Whitespace [getText $pos [nextLineStart $pos]]]} {set pos [nextLineStart $pos]}
		goto $pos
		elec::Insertion "\r" $htmlIndent [html::CloseElem HEAD] "\r"
	}
	
	for {set i 0} {$i < [llength  ${html::HeadElements}]} {incr i} {
		if {[lindex $inHead [expr {$i + 3}]]} {
			set he [lindex ${html::HeadElements} $i]
			if {$he == "ISINDEX" && $html::HideDeprecated} {alertnote "ISINDEX cannot be used in strict HTML."; continue}
			if {($he == "ISINDEX" || $he == "BASE") && ![catch {html::FindFirstOccurance "<$he\[^<>\]*>" [minPos]} res]} {
				goto [pos::math [lindex $res 0] + 1]
				html::EditTag 1
			} else {
				set pos [lindex [html::FindFirstOccurance {</head>} [minPos]] 0]
				goto $pos
				html::Tag $he				
				if {($he == "STYLE" || $he == "SCRIPT" || $he == "OBJECT") && $HTMLmodeVars(useTabMarks)} {
					insertText ¥
					catch {ring::+}
				} 
			}
		}
	}
	
	if {![catch {html::FindFirstOccurance "<$doctype\[^<>\]*>" [minPos]} res]} {
		goto [pos::math [lindex $res 0] + 1]
		html::EditTag 1
	} else {
		set pos [lindex [html::FindFirstOccurance {</head>} [minPos]] 1]
		if {[is::Whitespace [getText $pos [nextLineStart $pos]]]} {set pos [nextLineStart $pos]}
		goto $pos
		elec::Insertion "\r" $htmlIndent [html::OpenElem $doctype "" 0] "\r"
	}
	refresh
	html::ActivateHook
	goto [minPos]
	catch {ring::+}
}

#===============================================================================
# ×××× Document type ×××× #
#===============================================================================

proc html::DocumentType {} {
	if {![win::checkIfWinToEdit]} {return}
	set dt [html::FindDoctype]
	set m0 [lindex [set types {"HTML 4.01 Strict" "HTML 4.01 Strict" "HTML 4.01 Transitional" "HTML 4.01 Frameset" \
	  "XHTML 1.0 Strict" "XHTML 1.0 Transitional" "XHTML 1.0 Frameset" "XHTML 1.1"}] \
	  [lsearch -exact {{} strict transitional frameset xhtml10strict xhtml10transitional xhtml10frameset xhtml11} $dt]]
	set box [dialog::title {Document type declaration} 250]
	lappend box -m [concat [list $m0] [lrange $types 1 end]] 10 25 240 45 \
	  -b OK 170 70 235 90 -b Cancel 85 70 150 90
	set v [eval [concat dialog -w 250 -h 100 $box]]
	if {[lindex $v 2]} {return}
	set pos [pos::diff [minPos] [getPos]]
	goto [minPos]
	switch [lindex $v 0] {
		"HTML 4.01 Strict" {set dtd "HTML 4.01"}
		"HTML 4.01 Transitional" {set dtd "HTML 4.01 Transitional"}
		"HTML 4.01 Frameset" {set dtd "HTML 4.01 Frameset"}
		"XHTML 1.0 Strict" {set dtd "XHTML 1.0 Strict"}
		"XHTML 1.0 Transitional" {set dtd "XHTML 1.0 Transitional"}
		"XHTML 1.0 Frameset" {set dtd "XHTML 1.0 Frameset"}
		"XHTML 1.1" {set dtd "XHTML 1.1"}
	}
	if {[regexp {^X} $dtd]} {
		set type html
	} else {
		set type HTML
	}
	set txt "<!DOCTYPE $type PUBLIC \"-//W3C//DTD $dtd//EN\">"
	if {![regexp {^X} $dtd] && ![catch {search -s -f 1 -i 1 -m 0 -r 1 {<\?xml[^<>]+>[ \t\r\n]*<!DOCTYPE[^<>]+>} [minPos]} res]} {
		eval deleteText $res
	} elseif {![catch {search -s -f 1 -i 1 -m 0 -r 1 {<!DOCTYPE[^<>]+>} [minPos]} res]} {
		eval deleteText $res		
	} elseif {[regexp {^X} $dtd] && ![catch {search -s -f 1 -i 1 -m 0 -r 1 {<\?xml[^<>]+>} [minPos]} res]} {
		set res [list [lindex $res 1] [lindex $res 1]]
		goto [lindex $res 1]
	} else {
		set res [list [minPos] [minPos]]
	}
	insertText $txt [html::CloseCR]
	goto [pos::math [minPos] + $pos + [string length $txt] - [pos::diff [lindex $res 0] [lindex $res 1]]]
	html::ActivateHook
}

#===============================================================================
# ×××× Document size ×××× #
#===============================================================================

# Calculate the total size of a document including images etc.
proc html::DocumentSize {} {
	# Get path to this window.
	if {![llength [winNames]]} {return}
	if {[set thisURL [html::ThisFilePath 3]] == ""} {return}
	set exp1 {<!--|[ \t\n\r]+(DATA|CLASSID|SRC|LOWSRC|DYNSRC|BACKGROUND|USEMAP)[ \t\n\r]*=[ \t\n\r]*("[^"]+"|'[^']+'|[^ \t\n\r"'>]+)}
	set exp2 {[ \t\r\n]+(url)\([ \t\r\n]*("[^"]+"|'[^']+'|[^ \t\n\r"'\)]+)[ \t\r\n]*\)}
	set commStart1 "<!--"
	set commEnd1 "-->"
	set commStart2 {/*}
	set commEnd2 {*/}
	set size 0
	set counted {}
	set external 0
	set notfound 0
	for {set i 1} {$i < 3} {incr i} {
		set pos [minPos]
		set exp [set exp$i]
		set commStart [set commStart$i]
		set commEnd [set commEnd$i]
		while {![catch {search -s -f 1 -i 1 -m 0 -r 1 $exp $pos} res]} {
			set restxt [eval getText $res]
			# Comment?
			if {$restxt == $commStart} {
				if {![catch {search -s -f 1 -m 0 -i 0 -r 0 -- $commEnd [lindex $res 1]} res]} {
					set pos [lindex $res 1]
					continue
				} else {
					break
				}
			}
			# Get path to link.
			regexp -nocase $exp $restxt dum1 dum2 linkTo
			set linkTo [quote::Unurl [string trim $linkTo "\"' \t\r\n"]]
			if {[string index $linkTo 0] != "#"} {
				if {![catch {lindex [html::PathToFile [lindex $thisURL 0] [lindex $thisURL 1] [lindex $thisURL 2] [lindex $thisURL 3] $linkTo] 0} linkToPath]} {
					if {[file exists $linkToPath] && ![file isdirectory $linkToPath]} {
						if {![lcontains counted $linkToPath]} {
							incr size [file sizr $linkToPath]
							lappend counted $linkToPath
						}
					} else {
						set notfound 1
					}
				} else {
					set external 1
				}
			}
			set pos [lindex $res 1]
		}
	}
	incr size [pos::diff [minPos] [maxPos]]
	if {$size > 1000} {
		set size "[expr {$size /1024}] kB"
	} else {
		append size " bytes"
	}
	set txt "Total size: $size."
	if {$notfound} {append etxt "Some files not found. "}
	if {$external} {append etxt "External sources excluded."}
	if {$notfound || $external} {append txt " ([string trim $etxt])"}
	alertnote $txt
}


#===============================================================================
# ××××  Document index ×××× #
#===============================================================================

proc html::DocumentIndex {} {
	global HTMLmodeVars
	
	if {![win::checkIfWinToEdit]} {return}
	set liIndent ""
	set indLists [lcontains HTMLmodeVars(indentElements) UL]
	set indItems [lcontains HTMLmodeVars(indentElements) LI]
	if {$indLists} {set liIndent "\t"}
	html::indentCR UL LI
	if {![catch {search -s -f 1 -r 1 -m 0 -i 1 {<!--[ \t\r\n]+#DOCINDEX[ \t\r\n]+[^>]+>} [minPos]} begin] &&
	![catch {search -s -f 1 -r 1 -m 0 -i 1 {<!--[ \t\r\n]+/#DOCINDEX[ \t\r\n]+[^>]+>} [lindex $begin 1]} endind] &&
	[regexp -nocase {TYPE=\"(UL|PRE,[0-9]+)\"} [getText [lindex $begin 0] [lindex $begin 1]] dum type]} {
		if {![regexp -nocase {DEPTH=\"([1-6])\"} [getText [lindex $begin 0] [lindex $begin 1]] dum depth]} {set depth 6}
		set type [string toupper $type]
		if {$type != "UL"} {
			regexp {(PRE),([0-9]+)} $type dum type indent
			set indStr [string range "                                  " 1 $indent]
		}
		set replace 1
	} else {
		set replace 0
		set values [list 0 0 6 PRE 3]
		while {1} {
			set box "[dialog::title {Document index} 250] \
			  -t {Header depth:} 10 20 100 40 \
			  -e [list [lindex $values 2]] 110 20 130 35 \
			  -m {[list [lindex $values 3]] PRE UL} 10 50 80 70 \
			  -n PRE -t Indent 85 50 130 70 \
			  -e [list [lindex $values 4]] 135 50 165 65 \
			  -t characters 170 50 290 70"
			set values [eval [concat dialog -w 300 -h 110 \
			  -b OK 220 80 285 100 \
			  -b Cancel 135 80 200 100 $box]]
			set depth [lindex $values 2]
			set type [lindex $values 3]
			if {[lindex $values 1]} {return}
			if {[expr {($depth > 0) && ($depth < 7)}]} {
			    if {$type == "PRE"} {
				    set indent [lindex $values 4]
				    if {[is::PositiveInteger $indent]} {
					    set indStr [string range "                                  " 1 $indent]
					    break
				} else {
					alertnote "The number of characters to indent must be specified."
				}
			    } else {
				    break
			    }
			} else {
			    alertnote "The header depth must be between 1 and 6"
			}
		}

	}

	set pos [minPos]
	set exp "<\[Hh\]\[1-$depth\]\[^<>\]*>"
	set exp2 "</\[Hh\]\[1-$depth\]>"
	set indLevel 1
	set headSize 0
	set toc "\r\r<[html::SetCase $type]>"
	set cr 0
	set curr ""
	while {![catch {search -s -f 1 -r 1 -m 0 -i 0 $exp $pos} rs] && 
	![catch {search -s -f 1 -r 1 -m 0 -i 0 $exp2 [lindex $rs 1]} res]} {
		set start [lindex $rs 0]
		set end [lindex $res 1]
		set text [getText $start $end]
		set thisSize [getText [pos::math $start + 2] [pos::math $start + 3]]
		set text2 [getText [lindex $rs 1] [lindex $res 0]]
		regsub -all "\[\t\r\n\]+" $text " " text
		# remove all tags from text
		set headtext [string trim [html::TagStrip $text]]
		# Remove " from text.
		regsub -all "\"" $headtext "" headtext
		# Check if there is already an anchor
		if {[regexp -nocase {<A[ \t\r\n]+[^<>]*NAME[ \t\r\n]*=[ \t\r\n]*(\"[^\">]+\"|'[^'>]+'|[^ \t\n\r>]+)} $text2 dum anchor]} {
			set anchor [string trim $anchor "\"'"]
		} else {
			# Insert an anchor
			set anchor [string trim [string range $headtext 0 15]]
			# Make sure a &xxx; is not chopped.
			if {[set amp [string last & $anchor]] > [set semi [string last \; $anchor]]} {
				set rest [string range $headtext 16 end]
				append anchor [string range $rest 0 [string first \; $rest]]
			}
			# Is there an <A> tag?
			if {[regexp -nocase -indices {<A([ \t\r\n]+[^<>]+>|>)} $text2 atag]} {
				set text3 " [html::SetCase NAME]=\"$anchor\""
				replaceText [set blah [pos::math [lindex $rs 1] + [lindex $atag 0] + 2]] $blah $text3
				set end [pos::math $end + [string length $text3]]
			} else {
				set text3 "<[html::SetCase {A NAME}]=\"$anchor\">$text2[html::CloseElem A]"
				replaceText [lindex $rs 1] [lindex $res 0] $text3
				set end [pos::math $end + [string length $text3] - [string length $text2]]
			}
		}
		
		if {!$headSize} {
			# first header
			set headSize $thisSize
		} elseif {$thisSize > $headSize && $headSize} {
			# new list
			for {set i $headSize} {$i < $thisSize} {incr i} { 
				if {$type == "UL"} {
					html::crBefore $blBefUL $crBefUL toc $liIndent cr curr [html::SetCase <UL>]
					html::crAfter $blAftUL $crAftUL toc liIndent cr curr 0 $indLists
				}
			}
			incr indLevel [expr {$thisSize - $headSize}]
			set headSize $thisSize
		} elseif {$thisSize < $headSize && $indLevel} {
			# close a list
			for {set i $thisSize} {$i < $headSize && $indLevel > 1} {incr i} {
				if {$type == "UL"} {
					html::crBefore ${blBef/UL} ${crBef/UL} toc $liIndent cr curr [html::CloseElem UL]
					html::crAfter ${blAft/UL} ${crAft/UL} toc liIndent cr curr 1 $indLists
				}
				incr indLevel -1
			}
			set headSize $thisSize
		}
		if {$type == "UL"} {
			html::crBefore $blBefLI $crBefLI toc $liIndent cr curr [html::SetCase <LI>]
			html::crAfter $blAftLI $crAftLI toc liIndent cr curr 0 $indItems
		} else {
			append toc \r
			for {set i 1} {$i < $indLevel} {incr i} {
				append toc $indStr
			}
		}
		if {$type == "UL"} {
			append curr [html::prepareForBreaking "[html::SetCase {<A HREF}]=\"#$anchor\">$headtext[html::CloseElem A]"]
		} else {
			append toc "[html::SetCase {<A HREF}]=\"#$anchor\">$headtext[html::CloseElem A]"
		}
		if {$type == "UL" && [html::UseOptionalClosingTag LI]} {
			html::crBefore ${blBef/LI} ${crBef/LI} toc $liIndent cr curr [html::CloseElem LI]
			html::crAfter ${blAft/LI} ${crAft/LI} toc liIndent cr curr 1 $indItems
		}
		set pos $end
	}
	if {$type == "UL"} {
		for {set i $indLevel} {$i > 0} {incr i -1} {
			html::crBefore ${blBef/UL} ${crBef/UL} toc $liIndent cr curr [html::CloseElem UL]
			html::crAfter ${blAft/UL} ${crAft/UL} toc liIndent cr curr 1 $indLists
		}
		if {$curr != ""} {
			if {![is::Whitespace $curr]} {append toc $liIndent}
			append toc [html::BreakIntoLines $curr $liIndent]
		}
	} else {
		append toc "\r[html::CloseElem PRE]\r\r"
	}
	if {$replace} {
		if {[pos::compare $pos == [minPos]]} {set toc ""}
		# Find list again in case it has moved.
		set begin [search -s -f 1 -r 1 -m 0 -i 1 {<!--[ \t\r\n]+#DOCINDEX[ \t\r\n]+[^>]+>} [minPos]]
		set endind [search -s -f 1 -r 1 -m 0 -i 1 {<!--[ \t\r\n]+/#DOCINDEX[ \t\r\n]+[^>]+>} [lindex $begin 1]]
		if {$type == "PRE"} {
			replaceText  [lindex $begin 1] [lindex $endind 0] [string trimright $toc] \r\r
		} else {
			elec::ReplaceText [lindex $begin 1] [lindex $endind 0] [string trimright $toc] \r\r
		}
	} else {
		set tt ""
		if {[pos::compare $pos == [minPos]]} {alertnote "Empty index."; return}
		if {$type == "PRE"} {
			set tt ",$indent"
			set ind ""
		}
		append toctext [html::OpenCR 1] [html::SetCase "<!-- #DOCINDEX TYPE=\"$type$tt\" DEPTH=\"$depth\" -->"] \
		  [string trimright $toc] \r\r [html::SetCase "<!-- /#DOCINDEX -->"] [html::CloseCR2 [getPos]]
		if {$type == "PRE"} {
			insertText $toctext
		} else {
			html::elecInsertion toctext
		}
	}
}
