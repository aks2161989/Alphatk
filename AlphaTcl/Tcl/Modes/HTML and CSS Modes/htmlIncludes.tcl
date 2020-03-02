## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlIncludes.tcl"
 #                                    created: 99-07-20 18.23.04 
 #                                last update: 2005-02-21 17:51:50 
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
# This file contains procs for the Includes submenu.
#===============================================================================

#===============================================================================
# ×××× Includes ×××× #
#===============================================================================
proc html::ConvertInclPath {fil path win} {
	global tcl_platform
	if {$path != "" && [string match "${path}*" $fil]} {
		return "[html::SetCase INCLPATH=]\"[html::Quote [string range $fil [expr {[string length $path] + 1}] end]]\""
	} elseif {$path != "" && [string match "${path}*" $win]} {
		return "[html::SetCase FILE=]\"[html::Quote $fil]\""
	} else {
		set fromdir [split [file dirname $win] [file separator]]
		set todir [split $fil [file separator]]
		
		# Remove the common path.
		set i 0
		while {[llength $fromdir] > $i && [llength $todir] > $i \
		&& [lindex $fromdir $i] == [lindex $todir $i]} {
			incr i
		}
	
		# No common path?
		if {!$i || ($i == 1 && $tcl_platform(platform) == "unix")} {
			return "[html::SetCase FILE=]\"[html::Quote $fil]\""
		}
		# Insert :
		foreach f [lrange $fromdir $i end] {
			append linkTo ":"
		}
		# Add the path.
		append linkTo [join [lrange $todir $i end] [file separator]]
		return "[html::SetCase PATH=]\"[html::Quote $linkTo]\""
	}
}

proc html::ResolveInclPath {fil folder basefldr} {
	global tcl_platform alpha::macos
	regexp {^([^=]+)="([^"]+)"} $fil "" type fil
	set fil [html::UnQuote $fil]
	switch [string toupper $type] {
		FILE {
			if {[regexp -nocase {^:INCLUDE:} $fil]} {
				regsub -nocase {^:INCLUDE:} $fil "$folder[file separator]" fil
				if {${alpha::macos} == 2} {regsub -all : $fil / fil}
			} else {
				if {${alpha::macos} == 2 && ![regexp / $fil]} {
					regsub -all : $fil / fil
					if {![regsub "^[file::startupDisk]" $fil "" fil]} {
						set fil "/Volumes/$fil"
					}
				}
				if {${alpha::macos} == 1 && ![regexp : $fil]} {
					regsub -all / $fil : fil
					if {![regsub ":Volumes:" $fil "" fil]} {
						set fil [file join "[file::startupDisk]:" $fil]
					}
				}
			}
		}
		INCLPATH {
			if {${alpha::macos} == 2} {regsub -all : $fil / fil}
			if {${alpha::macos} == 1} {regsub -all / $fil : fil}
			set fil [html::filejoin $folder $fil]
		}
		PATH {
			set colons 0
			while {[string index $fil $colons] == ":"} {
				incr colons
			}
			if {$tcl_platform(platform) == "windows"} {
				regexp -nocase {([a-z]:/)(.*)} $basefldr "" disk basefldr
			}
			set b [file split $basefldr]
			if {$colons > [llength $b]} {error "File not found."}
			set fil [string trimleft $fil :]
			if {${alpha::macos} == 2} {regsub -all : $fil / fil}
			if {${alpha::macos} == 1} {regsub -all / $fil : fil}
			set fil [html::filejoin [eval file join [lrange $b 0 [expr {[llength $b] - $colons - 1}]]] $fil]
			if {$tcl_platform(platform) == "windows"} {set fil "$disk$fil"}
		}
	}
	return $fil
}


proc html::PasteIncludeTags {} {
	global html::HomePageWinURL
	if {![info exists html::HomePageWinURL]} {status::msg "No file to paste."; return}
	html::InsertIncludeTags ${html::HomePageWinURL}
}

# Inserts new include tags at the current position.
proc html::InsertIncludeTags {{fil ""}} {
	global HTMLmodeVars html::WrapPos html::AbsPos
	if {![win::checkIfWinToEdit]} {return}
	set win [html::StrippedFrontWindowPath]
	if {![file exists $win]} {
		if {[alert -t caution -k Save -c Cancel -o "" "You must save the window before inserting include tags."] == "Cancel"} {return}
		saveAs
	}
	set sexpr {<!--[ \t\r\n]+#INCLUDE[ \t\r\n]+[^>]+>}
	set eexpr {<!--[ \t\r\n]+/#INCLUDE[ \t\r\n]+[^>]+>}
	if {![catch {search -s -f 0 -r 1 -i 1 -m 0 $sexpr [getPos]} res] &&
		([catch {search -s -f 0 -r 1 -i 1 -m 0 $eexpr [getPos]} res1]
		|| [lindex $res 0] > [lindex $res1 0])} {
		alertnote "Current position is inside an include container."
		return
	}
	if {![catch {search -s -f 1 -r 1 -i 1 -m 0 $eexpr [getPos]} res] &&
		([catch {search -s -f 1 -r 1 -i 1 -m 0 $sexpr [getPos]} res1]
		|| [lindex $res 0] < [lindex $res1 0])} {
		alertnote "Current position is inside an include container."
		return
	}
	set incl [html::WhichInclFolder [set win [html::StrippedFrontWindowPath]]]
	if {$fil == "" && [catch {getfile "Select file to include." [file join $incl " "]} fil]} {return}
	if {![html::IsTextFile $fil alertnote]} {return}
	set uniqueparams ""
	if {![catch {open $fil} fid]} {
		set text [read $fid]
		close $fid
		set params ""
		while {[regexp -indices {##[^# \t\r\n]+##} $text par]} {
			lappend params [string trim [string range $text [lindex $par 0] [lindex $par 1]] #]
			set text [string range $text [expr [lindex $par 1] + 1] end]
		}
		if {[llength $params]} {
			set hpos 35
			foreach p $params {
				if {![lcontains uniqueparams [string toupper $p]]} {
					lappend uniqueparams [string toupper $p]
				} else {
					continue
				}
				lappend box -t $p: 10 $hpos 150 [expr $hpos + 15] -e {} 160 $hpos 490  [expr $hpos + 15]
				incr hpos 25
			} 
			set hbox "-T {Place holders}"
			append hbox " -w 500 -h [expr $hpos + 40] -t [list [list Include place holders for [file tail $fil]]] 10 10 490 25 -b OK 420 [expr $hpos + 10] \
			  485 [expr $hpos + 30] -b Cancel 335 [expr $hpos + 10] 400 [expr $hpos + 30]"
			set vals [eval [concat dialog $hbox $box]]
			if {[lindex $vals 1]} {return}
		}
		
	}
	set fil1 [html::ConvertInclPath $fil $incl $win]
	set html::WrapPos 0
	set html::AbsPos [getPos]
	set text "<!-- [html::SetCase {#INCLUDE }]$fil1"
	set i 2
	foreach p $uniqueparams {
		append text [html::WrapTag [html::SetCase $p]=[html::AddQuotes [lindex $vals $i]]]
		incr i
	}
	append text	" -->\r\r"
	if {$HTMLmodeVars(includeOnlyTags)} {append text "<B>The file [file tail $fil1] will be inserted here when the window is updated.</B>"}
	append text "\r\r" "<!-- [html::SetCase /#INCLUDE] -->"
	insertText [html::OpenCR 1] $text "\r\r"
	if {!$HTMLmodeVars(includeOnlyTags)} {html::UpdateWindow $fil1}
}

# Updates the text between all include tags.
proc html::UpdateWindow {{fil ""}} {
	if {![win::checkIfWinToEdit]} {return}
	set win [html::StrippedFrontWindowPath]
	if {![file exists $win]} {
		if {[alert -t caution -k Save -c Cancel -o "" "You must save the window before updating."] == "Cancel"} {return}
		saveAs
	}
	html::UpdateInclude Window $fil
}

proc html::UpdateHomePage {} {html::UpdateInclude "Home page"}
proc html::UpdateFolder {} {html::UpdateInclude Folder}
proc html::UpdateFile {} {html::UpdateInclude File}

proc html::UpdateInclude {where {onlyThis ""}} {
	global HTMLmodeVars htmlUpdateErr htmlUpdateList htmlUpdateBase htmlUpdatePath htmlUpdateHome browse::separator
	global tileLeft tileTop tileWidth errorHeight html::TmpInclFolder html::TmpXinclFolder
	# Clean up after previous update
	temp::cleanup HTML
	set html::TmpInclFolder [temp::directory HTML incl]
	set html::TmpXinclFolder [temp::directory HTML xincl]
	
	set sexpr {<!--[ \t\r\n]+#INCLUDE[ \t\r\n]+[^>]+>}
	set eexpr {<!--[ \t\r\n]+/#INCLUDE[ \t\r\n]+[^>]+>}
	set expBase "<(base\[ \\t\\n\\r\]+)\[^>\]*>"
	set expBase2 "(href\[ \\t\\n\\r\]*=\[ \\t\\n\\r\]*)(\"\[^\"\]+\"|'\[^'\]+'|\[^ \\t\\n\\r>\]+)"
	set htmlUpdateErr ""
	if {$where == "Window"} {
		set wname [html::StrippedFrontWindowPath]
		set htmlUpdateList [list $wname]
		set inclFldr [html::WhichInclFolder $wname]
		set home [html::WhichHomeFolder $wname]
		if {$home != ""} {
			set htmlUpdateBase [lindex $home 1]
			set htmlUpdatePath [lindex $home 2]
			set htmlUpdateHome [list [lindex $home 1] [lindex $home 2]]
			regsub -all [quote::Regfind [file separator]] [string range $wname [expr {[string length [lindex $home 0]] + 1}] end] / tp
			append htmlUpdatePath [string range $tp 0 [string last / $tp]]
		} else {
			set htmlUpdateHome [list [set htmlUpdateBase "file:///"] ""]
			regsub -all [quote::Regfind [file separator]] [file dirname $wname] / htmlUpdatePath
			append htmlUpdatePath /
		}
		set hasBase 0
		if {![catch {search -s -f 1 -i 1 -m 0 -r 1 $expBase [minPos]} this]} {
			set preBase [lindex $this 0]
			set comm 0
			set spos [minPos]
			while {![catch {search -s -f 1 -i 1 -m 0 -l $preBase {<!--} $spos} bCom]} {
				set spos [lindex $bCom 1]
				set comm 1
				if {![catch {search -s -f 1 -i 1 -m 0 -l $preBase -- {-->} $spos} bCom]} {
					set spos [lindex $bCom 1]
					set comm 0
				} else {
					break
				}
			}
			if {!$comm && [regexp -nocase $expBase2 [getText [lindex $this 0] [lindex $this 1]] d1 d2 url1]} {
				set url1 [string trim $url1 {"'}]
				set hasBase 1
			}
		}
		if {$hasBase && ![catch {html::BASEpieces $url1} basestr]} {
			set htmlUpdateBase [lindex $basestr 0]
			set tp [lindex $basestr 2]
			set htmlUpdatePath "[lindex $basestr 1][string range $tp 0 [string last / $tp]]"
		}
		set pos [minPos]
		while {![catch {search -s -f 1 -r 1 -i 1 -m 0 $sexpr $pos} res]} {
			set lnum [lindex [pos::toRowChar [lindex $res 0]] 0]
			set ln [expr {5 - [string length $lnum]}]
			if {[catch {search -s -f 1 -r 1 -i 1 -m 0 $eexpr [lindex $res 1]} res1]} {
				append htmlUpdateErr "Line $lnum:[format "%$ln\s" ""]Opening include tag without a matching end tag."\
						"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$wname\r"
				break
			}
			if {![catch {search -s -f 1 -r 1 -i 1 -m 0 $sexpr [lindex $res 1]} res2]
			&& [lindex $res2 0] < [lindex $res1 0]} {
				append htmlUpdateErr "Line $lnum:[format "%$ln\s" ""]Nested include tags."\
						"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$wname\r"
				set pos [lindex $res1 1]
				continue
			}	
			if {[catch {html::ReadInclude [eval getText $res] 1 [file dirname $wname] $inclFldr 0 $onlyThis} text]} {
				if {$text != "Not this file"} {append htmlUpdateErr "Line $lnum:[format "%$ln\s" ""]$text"\
						"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$wname\r"}
				set pos [lindex $res1 1]
			} else {
				replaceText [lindex $res 1] [lindex $res1 0] "\r\r" $text "\r\r"
				set pos [pos::math [lindex $res 1] + [string length $text] + 4]
			}
		}
	} else {
		if {[html::AllSaved "-c {Save all open windows before updating?}"] == "cancel"} {return}
		if {$where == "File"} {
			if {[catch {getfile "Select file to update."} files]} {return}
			if {![html::IsTextFile $files alertnote]} {return}
			set inclFldr [html::WhichInclFolder $files]
			set home [html::WhichHomeFolder $files]
			set folder [file dirname $files]
			set filelist [html::OpenAfile]
			puts [lindex $filelist 0] $files
			close [lindex $filelist 0]
			set files [lindex $filelist 1]
		} elseif {$where == "Folder"} {
			if {[catch {html::GetDir "Update folder:"} folder]} {return}
			set inclFldr [html::WhichInclFolder ${folder}]
			set home [html::WhichHomeFolder ${folder}]
			set subFolders [expr {![string compare yes [askyesno "Update files in subfolders?"]]}]
			if {$subFolders} {
				set files [html::AllHTMLfiles $folder]
			} else {
				set files [html::GetHTMLfiles $folder]
			}
		} else {
			if {![html::IsThereAHomePage] ||
			[catch {html::WhichHomePage "update"} home]} {return}
			set folder [lindex $home 0]
			set inclFldr [html::WhichInclFolder ${folder}]
			set files [html::AllHTMLfiles $folder]
		}
		set fid0 [open $files]
		while {![eof $fid0]} {
			gets $fid0 f
			if {$f == "" || [catch {open $f} fid1]} {continue}
			set filecont [read $fid1 16384]
			close $fid1
			if {$home != ""} {
				set htmlUpdateBase [lindex $home 1]
				set htmlUpdatePath [lindex $home 2]
				set htmlUpdateHome [list [lindex $home 1] [lindex $home 2]]
				regsub -all [quote::Regfind [file separator]] [string range $f [expr {[string length [lindex $home 0]] + 1}] end] / tp
				append htmlUpdatePath [string range $tp 0 [string last / $tp]]
			} else {
				set htmlUpdateHome [list [set htmlUpdateBase "file:///"] ""]
				regsub -all [quote::Regfind [file separator]] [file dirname $f] / htmlUpdatePath
				append htmlUpdatePath /
			}
			set hasBase 0
			if {[regexp -nocase -indices $expBase $filecont this]} {
				set preBase [string range $filecont 0 [lindex $this 0]]
				set comm 0
				while {[regexp -indices {<!--} $preBase bCom]} {
					set preBase [string range $preBase [expr {[lindex $bCom 1] - 1}] end]
					set comm 1
					if {[regexp -indices -- {-->} $preBase bCom]} {
						set preBase [string range $preBase [expr {[lindex $bCom 1] - 1}] end]
						set comm 0
					} else {
						break
					}
				}
				if {!$comm && [regexp -nocase $expBase2 [string range $filecont [lindex $this 0] [lindex $this 1]] d1 d2 url1]} {
					set url1 [string trim $url1 {"'}]
					set hasBase 1
				}
			}
			if {$hasBase && ![catch {html::BASEpieces $url1} basestr]} {
				set htmlUpdateBase [lindex $basestr 0]
				set tp [lindex $basestr 2]
				set htmlUpdatePath "[lindex $basestr 1][string range $tp 0 [string last / $tp]]"
			}
			set htmlUpdateList [list $f]
			if {[html::UpdateOneFile $f $f $folder $inclFldr 0 [html::getFileEncoding $f]]} {lappend modified $f}
		}
		close $fid0
		catch {file delete $files}
	}
	if {$htmlUpdateErr != ""} {
		new -n "* Errors *" -g $tileLeft $tileTop $tileWidth $errorHeight -m Brws
		set name [lindex [winNames] 0]
		insertText "Errors:  (<uparrow> and <downarrow> to browse, <return> to go to file)\r${browse::separator}\r"
		insertText $htmlUpdateErr
		html::SetWin
	}
	if {[info exists modified]} {
		foreach w [html::AllWindowPaths] {
			if {[lcontains modified [win::StripCount $w]]} {
				foreach ww [html::AllWindowPaths] {
					if {[lcontains modified [win::StripCount $ww]]} {
						bringToFront $ww
						revert
					}
				}
				if {$htmlUpdateErr != ""} {bringToFront $name}
				break
			}
		}
	}
	# Clean up
	temp::cleanup HTML
	if {$htmlUpdateErr == ""} {status::msg "$where updated successfully."}
	unset htmlUpdateErr htmlUpdateList htmlUpdateBase htmlUpdatePath
}

proc html::UpdateOneFile {f f1 folder inclFldr depth enc} {
	global htmlUpdateErr htmlUpdateBase htmlUpdatePath htmlUpdateHome HTMLmodeVars
	if {$HTMLmodeVars(preserveLineEndings)} {set lineending [html::GetLineEndings $f1]}
	if {[catch {open $f1} fid]} {return 0}
	fconfigure $fid -encoding $enc
	status::msg "Updating [file tail $f1]É"
	set sexpr {<!--[ \t\r\n]+#INCLUDE[ \t\r\n]+[^>]+>}
	set eexpr {<!--[ \t\r\n]+/#INCLUDE[ \t\r\n]+[^>]+>}
	set exprr1 "<!--|\[ \\t\\n\\r\]+[html::URLregexp]"
	set exprr2 {/\*|[ \t\r\n]+(url)\([ \t\r\n]*("[^"]+"|'[^']+'|[^ \t\n\r\)]+)[ \t\r\n]*\)}
	set commStart1 "<!--"
	set commEnd1 "-->"
	set commStart2 {/*}
	set commEnd2 {\*/}
	file stat $f1 finfo
	if {!$depth} {set created $finfo(ctime)}
	set filecont [read $fid 16384]
	set limit [expr {[eof $fid] ? 0 : 300}]
	regsub -all "\n\r" $filecont "\r" filecont
	if {[regexp {\n} $filecont]} {
		set newln "\n"
	} else {
		set newln "\r"
	}
	set linenum 1
	set ismod 0
	set errf [string range $f [expr {[string length $folder] + 1}] end]
	set temp [html::OpenAfile $enc]
	set tmpfid [lindex $temp 0]
	if {$depth} {puts $tmpfid "$htmlUpdateBase$htmlUpdatePath"}
	set opening 0
	set l [expr {20 - [string length [file tail $f]]}]
	while {1} {
		while {$opening || ([regexp -nocase -indices $sexpr $filecont res] && 
		[expr {[string length $filecont] - [lindex $res 0]}] > $limit)} {
			if {!$opening} {
				incr linenum [regsub -all $newln [string range $filecont 0 [lindex $res 0]] {} dummy]
				set ln [expr {5 - [string length $linenum]}]
				puts -nonewline $tmpfid [string range $filecont 0 [lindex $res 1]]
				set readName [string range $filecont [lindex $res 0] [lindex $res 1]]
				set filecont [string range $filecont [expr {[lindex $res 1] + 1}] end]
			}
			if {![regexp -nocase -indices $eexpr $filecont res1] ||
			[expr {[string length $filecont] - [lindex $res1 0]}] <= $limit} {
				if {[eof $fid]} {
					append htmlUpdateErr [html::BrwsErr $errf $l $linenum $ln "Opening include tag without a matching end tag." $f]
				} else {
					set opening 1
				}
				break
			}
			set toReplace [string trim [string range $filecont 0 [expr {[lindex $res1 0] - 1}]]]
			set opening 0
			if {[regexp -nocase -indices $sexpr $filecont res2]
			&& [lindex $res2 0] < [lindex $res1 0]} {
				append htmlUpdateErr [html::BrwsErr $errf $l $linenum $ln "Nested include tags." $f]
				puts -nonewline $tmpfid [string range $filecont 0 [lindex $res1 1]]
				incr linenum [regsub -all $newln [string range $filecont 0 [lindex $res1 1]] {} dummy]
				set filecont [string range $filecont [expr {[lindex $res1 1] + 1}] end]
				continue
			}
			if {[catch {html::ReadInclude $readName 0 [file dirname $f1] $inclFldr $depth} text]} {
				append htmlUpdateErr [html::BrwsErr $errf $l $linenum $ln $text $f]
				puts -nonewline $tmpfid [string range $filecont 0 [lindex $res1 1]]					
				incr linenum [regsub -all $newln [string range $filecont 0 [lindex $res1 1]] {} dummy]
				set filecont [string range $filecont [expr {[lindex $res1 1] + 1}] end]
				continue
			}
			if {[string trim $text] != $toReplace} {
				set ismod 1
			}
			puts -nonewline $tmpfid "$newln$newln$text$newln$newln"
			puts -nonewline $tmpfid [string range $filecont [lindex $res1 0] [lindex $res1 1]]
			incr linenum 4
			incr linenum [regsub -all $newln $text "" ""]
			incr linenum [regsub -all $newln [string range $filecont [lindex $res1 0] [lindex $res1 1]] {} dummy]
			set filecont [string range $filecont [expr {[lindex $res1 1] + 1}] end]
		}
		if {![eof $fid]} {
			if {$opening} {
				append filecont [read $fid 16384]
			} else {
				puts -nonewline $tmpfid [string range $filecont 0 [expr {[string length $filecont] - 301}]]
				incr linenum [regsub -all $newln [string range $filecont 0 [expr {[string length $filecont] - 301}]] {} dummy]
				set filecont "[string range $filecont [expr {[string length $filecont] - 300}] end][read $fid 16384]"
			}
			set limit [expr {[eof $fid] ? 0 : 300}] 
		} else {
			break
		}					
	}
	close $fid
	if {$ismod || $depth} {puts -nonewline $tmpfid $filecont}
	close $tmpfid
	if {$ismod && !$depth} {
		set linenum 1
		set opening 0
		set fid [open [set temp1 [lindex $temp 1]]]
		fconfigure $fid -encoding $enc
		set filecont [read $fid 16384]
		set limit [expr {[eof $fid] ? 0 : 300}]
		set temp [html::OpenAfile $enc]
		set tmpfid [lindex $temp 0]
		while {1} {
			while {$opening || ([regexp -nocase -indices {<!--[ \t\r\n]+#LASTMODIFIED[ \t\r\n]+[^>]+>} $filecont res] &&
			[expr {[string length $filecont] - [lindex $res 0]}] > $limit)} {
				if {!$opening} {
					incr linenum [regsub -all "\n" [string range $filecont 0 [lindex $res 0]] {} dummy]
					set ln [expr {5 - [string length $linenum]}]
					puts -nonewline $tmpfid [string range $filecont 0 [lindex $res 1]]
					set lastMod [string range $filecont [lindex $res 0] [lindex $res 1]]
					set filecont [string range $filecont [expr {[lindex $res 1] + 1}] end]
				}
				if {![regexp -nocase -indices {<!--[ \t\r\n]+/#LASTMODIFIED[ \t\r\n]+[^>]+>} $filecont res1] ||
				[expr {[string length $filecont] - [lindex $res1 0]}] <= $limit} {
					if {[eof $fid]} {
						append htmlUpdateErr [html::BrwsErr $errf $l $linenum $ln "Opening 'last modified' tag without a matching closing tag." $f]
					} else {
						set opening 1
					}
					break
				}
				set str [html::GetLastMod $lastMod]
				if {$str == "0"} {
					append htmlUpdateErr [html::BrwsErr $errf $l $linenum $ln "Invalid 'last modified' tags." $f]
					puts -nonewline $tmpfid [string range $filecont 0 [lindex $res1 1]]
					incr linenum [regsub -all "\n" [string range $filecont 0 [lindex $res1 1]] {} dummy]
					set filecont [string range $filecont [expr {[lindex $res1 1] + 1}] end]
				} else {
					set oldstr [string range $filecont 0 [expr {[lindex $res1 0] - 1}]]
					regexp {^[\r\n\t ]*} $oldstr prenl
					regexp {[\r\n\t ]*$} $oldstr postnl
					puts -nonewline $tmpfid "$prenl$str$postnl"
					incr linenum [regsub -all "\n" $prenl "" ""]
					incr linenum [regsub -all "\n" $postnl "" ""]
					set filecont [string range $filecont [lindex $res1 0] end]
				}
				set opening 0
			}
			if {![eof $fid]} {
				if {$opening} {
					append filecont [read $fid 16384]
				} else {
					puts -nonewline $tmpfid [string range $filecont 0 [expr {[string length $filecont] - 301}]]
					incr linenum [regsub -all "\n" [string range $filecont 0 [expr {[string length $filecont] - 301}]] {} dummy]
					set filecont "[string range $filecont [expr {[string length $filecont] - 300}] end][read $fid 16384]"
				}
				set limit [expr {[eof $fid] ? 0 : 300}] 
			} else {
				break
			}
		}
		puts -nonewline $tmpfid $filecont
		while {![eof $fid]} {
			puts -nonewline $tmpfid [read $fid 16384]
		}
		close $fid
		close $tmpfid
		if {[catch {file delete $f1}] && [file exists $f1]} {
			append htmlUpdateErr "$errf[format "%$l\s" ""]; Could not write update to file. An error occurred.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$f\r"
		} else {
			catch {
				file copy [lindex $temp 1] $f1
				if {$HTMLmodeVars(preserveLineEndings) && (!${alpha::macos} || 
				(${alpha::macos} == 1 && $lineending != "mac") || 
				(${alpha::macos} == 2 && $lineending != "unix"))} {
					file::convertLineEndings $f1 $lineending
				}
				setFileInfo $f1 created $created
				setFileInfo $f1 creator ALFA
				setFileInfo $f1 type TEXT
			}
		}
		catch {file delete $temp1}
	} elseif {$depth} {
		set fid [open [set temp1 [lindex $temp 1]]]
		fconfigure $fid -encoding $enc
		set filecont [read $fid 16384]
		set limit [expr {[eof $fid] ? 0 : 300}]
		set temp [html::OpenAfile $enc]
		set tempf [lindex $temp 1]
		set tempfid [lindex $temp 0]
		for {set i1 1} {$i1 < 3} {incr i1} {
			if {$i1 == 2} {
				close $fid
				seek $tempfid 0
				set fid $tempfid
				set filecont [read $fid 16384]
				set limit [expr {[eof $fid] ? 0 : 300}]
				set temp [html::OpenAfile $enc]
				set tempfid [lindex $temp 0]
			}
			set commStart [set commStart$i1]
			set commEnd [set commEnd$i1]
			set exprr [set exprr$i1]
			set comment 0
			while {1} {
				while {$comment || ([regexp -nocase -indices $exprr $filecont href b url] &&
				[expr {[string length $filecont] - [lindex $href 0]}] > $limit)} {
					# Comment?
					if {$comment || [string range $filecont [lindex $href 0] [lindex $href 1]] == $commStart} {
						if {$comment} {
							set href {0 0}
							set subcont $filecont
						} else {
							set subcont [string range $filecont [expr {[lindex $href 1] + 1}] end]
						}
						if {[regexp -indices -- $commEnd $subcont cend] &&
						[expr {[string length $subcont] - [lindex $cend 0]}] > $limit} {
							puts -nonewline $tempfid [string range $filecont 0 [expr {[lindex $href 1] + [lindex $cend 1] - 1}]]
							set filecont [string range $filecont [expr {[lindex $href 1] + [lindex $cend 1]}] end]
							set comment 0
							continue
						} else {
							set comment 1
							break
						}
					}
					set urltxt [string trim [string range $filecont [lindex $url 0] [lindex $url 1]] {"'}]
					set url2 [quote::Unurl $urltxt]
					if {[regsub -nocase ":HOMEPAGE:" $url2 [lindex $htmlUpdateHome 1] url2]} {
						if {[lindex $htmlUpdateHome 0] == $htmlUpdateBase} {
							set newurl [html::RelativePath $htmlUpdatePath $url2]
						} else {
							set newurl "[lindex $htmlUpdateHome 0]$url2"
						}
						set newurl [quote::UrlExceptAnchor $newurl]
					} else {
							set newurl $urltxt
					}
					puts -nonewline $tempfid [string range $filecont 0 [expr {[lindex $url 0] - 1}]]
					puts -nonewline $tempfid "\"$newurl\""
					set filecont [string range $filecont [expr {[lindex $url 1] + 1}] end]
				}
				if {![eof $fid]} {
					puts -nonewline $tempfid [string range $filecont 0 [expr {[string length $filecont] - 301}]]
					set filecont "[string range $filecont [expr {[string length $filecont] - 300}] end][read $fid 16384]"
					set limit [expr {[eof $fid] ? 0 : 300}] 
				} else {
					break
				}
			}
			puts -nonewline $tempfid $filecont
		}
		close $fid
		close $tempfid
		if {[catch {file delete $f1}] && [file exists $f1]} {
			append htmlUpdateErr "$errf[format "%$l\s" ""]; Could not write update to file. An error occurred.\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t°$f\r"
		} else {
			catch {file copy [lindex $temp 1] $f1}
		}
		catch {file delete $temp1}
	}
	catch {file delete [lindex $temp 1]}
	catch {file delete $tempf}
	return $ismod
}

# Read content of a file to be included.
proc html::ReadInclude {incl nr basefldr fldr depth {onlyThis ""}} {
	global htmlUpdateList tcl_platform html::IncludeParameter html::TmpInclFolder html::TmpXinclFolder
	set htmlUpdateList [lrange $htmlUpdateList 0 $depth]
	if {![regexp -nocase {(file|inclpath|path)=\"[^\"]+\"} $incl fil]} {
		error "Invalid opening include tag."
	}
	if {$onlyThis != "" && $fil != $onlyThis} {error "Not this file"}
	if {$depth == 10} {error "Too deep recursive includes."}
	if {$fldr == "" && [regexp -nocase {^FILE=":INCLUDE:} $fil]} {error ":INCLUDE: doesn't map to a folder."}
	set params ""; set parvals ""; set errs ""
	html::ExtractAttrValues [string range $incl 5 [expr [string length $incl] - 4]] params parvals errs
	set params [string toupper $params]
	if {[llength $errs]} {error [lindex $errs 0]}
	set basefldr [html::InclGetBaseFolder $basefldr]
	set fil [html::ResolveInclPath $fil $fldr $basefldr]
	if {[lcontains htmlUpdateList $fil]} {error "Infinite loop of includes."}
	if {![file exists $fil]} {
		error "File not found."
	}
	lappend htmlUpdateList $fil
	set fil0 $fil
	set enc [html::getFileEncoding $fil]
	if {$tcl_platform(platform) == "windows"} {regsub : $fil0 # fil0}
	if {$fldr != "" && [string match "$fldr*" $fil]} {
		set folder $fldr
		set tmpfil [html::filejoin ${html::TmpInclFolder} [string trimleft [string range $fil0 [string length $fldr] end] [file separator]]]
	} else {
		set folder [file dirname $fil]
		set tmpfil [html::filejoin ${html::TmpXinclFolder} [string trimleft $fil0 [file separator]]]
	}
	if {![file exists $tmpfil] || ![html::UpdateSameBase $tmpfil $enc]} {
		file::ensureDirExists [file dirname $tmpfil]
		if {[file exists $tmpfil]} {catch {file delete $tmpfil}}
		catch {file copy $fil $tmpfil}
		html::UpdateOneFile $fil $tmpfil $folder [html::WhichInclFolder $fil] [incr depth] $enc
	}
	if {[catch {open $tmpfil} fid]} {
		error "Could not read file."
	}
	fconfigure $fid -encoding $enc
	gets $fid
	set text [read $fid]
	close $fid
	regsub -all "\n\r" $text "\r" text
	if {$nr} {regsub -all "\n" $text "\r" text}
	# Remove include tags from inserted text
	regsub -all -nocase "<!--\[ \t\r\n\]+/?#INCLUDE\[ \t\r\n\]+\[^>\]+>" $text "" text
	for {set i 0} {$i < [llength $params]} {incr i} {
		set par [string trimright [lindex $params $i] =]
		set html::IncludeParameter [lindex $parvals $i]
		if {[regexp -nocase {^(file|inclpath|path)$} $par]} {continue}
		if {[catch {uplevel #0 {subst ${html::IncludeParameter}}} pval]} {
			error "Error in $par: $pval"
		}
		regsub -all -nocase "##$par##" $text $pval text
	}
	return $text
}

proc html::UpdateSameBase {fil enc} {
	global htmlUpdateBase htmlUpdatePath
	if {[catch {open $fil} fid]} {return 0}
	fconfigure $fid -encoding $enc
	set l [gets $fid]
	close $fid
	if {$l == "$htmlUpdateBase$htmlUpdatePath"} {return 1}
	return 0
}

proc html::InclGetBaseFolder {basefldr} {
	global tcl_platform html::TmpInclFolder html::TmpXinclFolder
	if {[string match [file join ${html::TmpInclFolder} *] $basefldr]} {
		set basefldr [string range $basefldr [expr {[string length ${html::TmpInclFolder}] + 1}] end]
		if {$tcl_platform(platform) == "unix"} {set basefldr "/$basefldr"}
		if {$tcl_platform(platform) == "windows"} {regsub # $basefldr : basefldr}
	}
	if {[string match [file join ${html::TmpXinclFolder} *] $basefldr]} {
		set basefldr [string range $basefldr [expr {[string length ${html::TmpXinclFolder}] + 1}] end]
		if {$tcl_platform(platform) == "unix"} {set basefldr "/$basefldr"}
		if {$tcl_platform(platform) == "windows"} {regsub # $basefldr : basefldr}
	}
	return $basefldr
}
