## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlMoveFiles.tcl"
 #                                    created: 99-07-20 18.26.09 
 #                                last update: 02/25/2006 {03:57:44 AM} 
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

proc htmlMoveFiles.tcl {} {}

#===============================================================================
# This file contains procs for moving and renaming files.
#===============================================================================

proc html::RenameFile {} {
	html::MoveFiles 1
}

proc html::RenameFolder {} {
	html::MoveFiles 1 1
}

# Moves files from one folder to another and update all links to the moved files
# as well as all links in the moved files.
proc html::MoveFiles {{rename 0} {renamefolder 0}} {
	global HTMLmodeVars
	
	set mrtxt {moved renamed}
	set filfol {"Files have" "Folder has"}
	# Check that a home page is defined.
	if {![html::IsThereAHomePage]} {return}
	
	if {[html::AllSaved "{All windows must be saved before you can move files. Save?}"] == "no"} {return}

	if {$rename} {
		if {$renamefolder} {
			set fromFolder [html::GetDir "Rename."]
			set mf [file::recurse $fromFolder]
			set movefiles ""
			foreach mm $mf {
				lappend movefiles [string range $mm [expr {[string length $fromFolder] + 1}] end]
			}
		} else {
			set movefiles [getfile "Select file to rename."]
			set fromFolder [file dirname $movefiles]
			set movefiles [list [file tail $movefiles]]
		}
	} else {
		set fromFolder [html::GetDir "Move from."]
	}
	
	set base [html::BASEfromPath $fromFolder]
	# Is this folder in a home page folder?
	if {[lindex $base 0] == "file:///"} {
		alertnote "'[file tail $fromFolder]' is not in a home page folder or an include folder."
		return 
	}
	set fromPath [lindex $base 1]
	set homepage [lindex $base 3]
	set fromBase [lindex $base 0]
	set isInInclFldr [lindex $base 4]
	set inclFld [lindex $base 5]
	
	# Check that the corresponding include or home page folder exists.
	if {$isInInclFldr} {
		if {![file isdirectory $homepage]} {
			alertnote "Could not find the corresponding home page folder for\
			${fromBase}$fromPath. Fix that and try again."
			html::HomePages "${fromBase}$fromPath"
			return
		}
	} elseif {$inclFld != "" && ![file isdirectory $inclFld]} {
		alertnote "Could not find the corresponding include folder for\
		${fromBase}$fromPath. Fix that and try again."
		html::HomePages "${fromBase}$fromPath"
		return
	}
	
	# Get files to move.
	if {!$rename} {
		set files [glob -nocomplain -dir $fromFolder *]
		foreach f $files {
			if {![file isdirectory $f]} {
				lappend filelist [file tail $f]
			}
		}
		if {![info exists filelist]} {
			alertnote "Empty folder."
			return
		}
	
		if {[catch {listpick -p "Select files to move." -l $filelist} movefiles] || \
		  ![string length $movefiles]} {return}
	
		
		# Get folder to move to.
		if {[catch {html::GetDir "Move to."} toFolder]} {return}
		if {$fromFolder == $toFolder} {
			alertnote "This is the same folder as you moved from."
			return
		}
	}

	if {$renamefolder} {
		set toFolder [putfile "New folder name." [file tail $fromFolder]]
	} elseif {$rename} {
		set newname [lindex $movefiles 0]
		while {$newname == [lindex $movefiles 0]} {
			set newname [putfile "New filename." $newname]
			set toFolder [file dirname $newname]
			set newname [file tail $newname]
			if {$newname == [lindex $movefiles 0]} {alertnote "You must give the file a new name."}
		}
	}
	
	# Is this folder in the same home page folder?
	if {!$isInInclFldr && ![string match [file join $homepage *] [file join $toFolder " "]] ||
	$isInInclFldr && ![string match [file join $inclFld *] [file join $toFolder " "]]} {
		set msg {"home page" "" "" "" "include"}
		alertnote "'[file tail $toFolder]' is not in the same [lindex $msg $isInInclFldr] folder."
		return
	}
		
	# Move the files.
	set reopenmessage 0
	set replaceexisting 0
	foreach f $movefiles {
		if {$rename && !$renamefolder} {
			set f1 $newname
		} else {
			set f1 $f
		}
		if {[file exists [file join $toFolder $f1]]} {
			if {!$rename && ($replaceexisting == 0 || $replaceexisting == 2)} {
				set replaceexisting [lsearch -exact [dialog -w 400 -h 70 -t "Replace '$f1' in folder '[file tail $toFolder]'?" 10 10 290 30 \
				  -b Yes 320 40 385 60 -b "Yes to all" 230 40 310 60 -b No 155 40 220 60 -b "No to all" 65 40 145 60] 1]
			}
			if {$rename || $replaceexisting == 0 || $replaceexisting == 1} {
				file delete [file join $toFolder $f1]
			} else {
				continue
			}
		}
		set reo 0
		foreach w [html::AllWindowPaths] {
			if {[win::StripCount $w] == [file join $fromFolder $f]} {
				if {!$reopenmessage} {
					alertnote "Open windows must be closed before they can be [lindex $mrtxt $rename]. They will be reopened again."
					set reopenmessage 1
				}
				bringToFront $w
				killWindow
				set reo 1
			}
		}
		if {!$renamefolder && [catch {file rename [file join $fromFolder $f] [file join $toFolder $f1]}] && \
		  ![file exists [file join $toFolder $f]]} {
			alertnote "Could not move $f. An error occurred."
			if {$reo} {lappend reOpen [file join $fromFolder $f]}
		} else {
			lappend movedFiles [file join $fromFolder $f]
			lappend movedFiles2 [file join $toFolder $f1]
			if {$reo} {lappend reOpen [file join $toFolder $f1]}
		}
	}
	
	if {$renamefolder && [catch {file rename $fromFolder $toFolder}]} {
		alertnote "Could not rename $fromFolder. An error occurred."
	} elseif {[info exists movedFiles] && [lindex [dialog -w 400 -h 70 -t "[lindex $filfol $renamefolder] been [lindex $mrtxt $rename]. Update links?" \
	  10 10 290 30 -b Update 320 40 385 60 -b Cancel 235 40 300 60] 0]} {
		if {$isInInclFldr} {
			# Update include links in home page files pointing to moved files in include folder.
			set allFiles [html::AllHTMLfiles $homepage]
			set x [html::UpdateAfterMove3 $movedFiles $movedFiles2 $homepage $inclFld $allFiles]
			set num [lindex $x 0]
			set changed [lindex $x 1]
			# Update include links in include files pointing to moved files in include folder.
			set allFiles [html::AllHTMLfiles $inclFld 0 $movedFiles2]
			set x [html::UpdateAfterMove3 $movedFiles $movedFiles2 $homepage $inclFld $allFiles]
			incr num [lindex $x 0]
			set changed [concat $changed [lindex $x 1]]
			# Update include links in moved files.
			set filelist [html::OpenAfile]
			set fid [lindex $filelist 0]
			foreach ff $movedFiles2 {
				puts $fid $ff
			}
			close $fid
			set x [html::UpdateAfterMove3 $movedFiles $movedFiles2 $homepage $inclFld [lindex $filelist 1] 1]
			set changed [concat $changed [lindex $x 1]]			
		} else {
			# Update links in home page files pointing to moved files in home page folder.
			set x [html::UpdateAfterMove $movedFiles $movedFiles2 $fromBase $fromPath $homepage $homepage]
			set num [lindex $x 0]
			set changed [lindex $x 1]
			# Update links in moved files.
			incr num [html::UpdateAfterMove2 $movedFiles $movedFiles2 $fromBase $fromPath $homepage]
			# Update links in include folder files pointing to moved files in home page folder.
			if {$inclFld != ""} {
				set x [html::UpdateAfterMove $movedFiles $movedFiles2 $fromBase $fromPath $homepage $inclFld 1]
				incr num [lindex $x 0]
				set changed [concat $changed [lindex $x 1]]
			}
			# Update include links in home page files pointing to moved files in home page folder.
			set allFiles [html::AllHTMLfiles $homepage 0 $movedFiles2]
			set x [html::UpdateAfterMove3 $movedFiles $movedFiles2 $homepage $inclFld $allFiles]
			incr num [lindex $x 0]
			set changed [concat $changed [lindex $x 1]]
			# Update include links in moved files.
			set filelist [html::OpenAfile]
			set fid [lindex $filelist 0]
			foreach ff $movedFiles2 {
				puts $fid $ff
			}
			close $fid
			set x [html::UpdateAfterMove3 $movedFiles $movedFiles2 $homepage $inclFld [lindex $filelist 1] 1]
			set changed [concat $changed [lindex $x 1]]			
		}
	}
	
	# BUG!!! Make sure $num is correct. Files can be double counted.
	catch {status::msg "$num files have been modified including the ones [lindex $mrtxt $rename]."}

	if {[info exists reOpen] && [askyesno "Reopen previously closed windows?"] == "yes"} {
		foreach r $reOpen {
			edit -c $r
		}
	}
	
	if {[info exists changed] && [llength $changed]} {
		foreach r [lunique $changed] {
			bringToFront $r
			revert
		}
	}
}

# Updates links to moved files.
proc html::UpdateAfterMove {movedFiles movedFiles2 fromBase fromPath homepage isinfld {inclfiles 0}} {
	global HTMLmodeVars alpha::macos
	
	set allfiles [html::AllHTMLfiles $isinfld 1 $movedFiles2]
	
	# Build regular expressions with URL attrs.
	set exprr [html::URLregexp]
	set exprr2 {(url)\([ \t\r\n]*("[^"]+"|'[^']+'|[^ \t\n\r\)]+)[ \t\r\n]*\)}

	# Update links to the moved files.
	set toModify [html::ScanFiles $allfiles $fromBase $fromPath $homepage $isinfld 0 0 $movedFiles]
	set fidr [lindex $toModify 0]
	seek $fidr 0
	set num 0
	set changed ""
	set thisfile ""
	while {![eof $fidr]} {
		gets $fidr modify
		if {$modify == ""} {continue}

		set fil [lindex $modify 0]
		if {$thisfile != $fil} {
			if {[string length $thisfile]} {
				if {[catch {open $thisfile w} fid]} {
					alertnote "Could not update [file tail $thisfile]. An error occurred."
				} else {
					fconfigure $fid -encoding [html::getFileEncoding $thisfile]
					puts -nonewline $fid [join $filecont "\r"]
					close $fid
					if {$HTMLmodeVars(preserveLineEndings) && (!${alpha::macos} || 
					(${alpha::macos} == 1 && $lineending != "mac") || 
					(${alpha::macos} == 2 && $lineending != "unix"))} {
						file::convertLineEndings $thisfile $lineending
					}
				}
			}
			status::msg "Modifying [file tail $fil]É"
			foreach w [html::AllWindowPaths] {
				if {[win::StripCount $w] == "$fil"} {
					lappend changed $w
				}
			}
			if {$HTMLmodeVars(preserveLineEndings)} {set lineending [html::GetLineEndings $fil]}
			set fid [open $fil r]
			fconfigure $fid -encoding [html::getFileEncoding $fil]
			incr num
			set filec [read $fid]
			close $fid
			if {[regexp {\n} $filec]} {
				set newln "\n"
			} else {
				set newln "\r"
			}
			set filec [split $filec $newln]
			set filecont ""
			foreach fc $filec {
				lappend filecont [string trimleft $fc "\r"]
			}
		}
		set thisfile $fil
		set linenum [expr {[lindex $modify 1] - 1}]
		set line [lindex $filecont $linenum]
		set path [lindex $movedFiles2 [lsearch -exact $movedFiles [lindex $modify 5]]]
		set lnk [html::BASEfromPath $path]
		if {$inclfiles && "[lindex $modify 2][lindex $modify 3]" == "[lindex $lnk 0][lindex $lnk 1]"} {
			set linkTo ":HOMEPAGE:[lindex $lnk 2]"
		} elseif {[lindex $modify 2] == [lindex $lnk 0]} {
			set linkTo [html::RelativePath "[lindex $modify 3][lindex $modify 4]" "[lindex $lnk 1][lindex $lnk 2]"]
		} else {
			set linkTo [join [lrange $lnk 0 2] ""]
		}
		set linkTo [quote::UrlExceptAnchor $linkTo]
		set tomod [quote::Regfind [lindex $modify 6]]
		set ii $linenum
		set maxnline [llength $filecont]
		while {![regexp -indices "$tomod" $line href] && $ii < $maxnline} {
			append line "" [lindex $filecont [incr ii]]
		}
		regsub -all "" $line "\r" line
		# This shouldn't fail!
		if {[regexp -nocase -indices $exprr [string range $line [lindex $href 0] [lindex $href 1]] a b url] ||
		[regexp -nocase -indices $exprr2 [string range $line [lindex $href 0] [lindex $href 1]] a b url]} {
			set anchor ""
			regexp {[^#]*(#[^\"]*)} $tomod a anchor
			set line "[string range $line 0 [expr {[lindex $href 0] + [lindex $url 0] - 1}]]\"$linkTo$anchor\"[string range $line [expr {[lindex $href 0] + [lindex $url 1] + 1}] end]"
			set filecont [eval lreplace [list $filecont] $linenum $ii [split $line "\r"]]
		} else {
			alertnote "An error occured when updating a link in [file tail $thisfile]."
		}
	}
	if {$thisfile != ""} {
		if {[catch {open $thisfile w} fid]} {
			alertnote "Could not update [file tail $thisfile]. An error occurred."
		} else {
			fconfigure $fid -encoding [html::getFileEncoding $thisfile]
			puts -nonewline $fid [join $filecont "\r"]
			close $fid
			if {$HTMLmodeVars(preserveLineEndings) && (!${alpha::macos} || 
			(${alpha::macos} == 1 && $lineending != "mac") || 
			(${alpha::macos} == 2 && $lineending != "unix"))} {
				file::convertLineEndings $thisfile $lineending
			}
		}
	}
	close $fidr
	catch {file delete [lindex $toModify 1]}
	return [list $num $changed]
}

# Updates links in moved files.
proc html::UpdateAfterMove2 {movedFiles movedFiles2 fromBase fromPath homepage} {
	global HTMLmodeVars alpha::macos
	
	set expBase "<(base\[ \\t\\n\\r\]+)\[^>\]*>"
	set expBase2 "(href\[ \\t\\n\\r\]*=\[ \\t\\n\\r\]*)(\"\[^\"\]+\"|'\[^'\]+'|\[^ \\t\\n\\r>\]+)"

	# Build regular expressions with URL attrs.
	set exprr1 "<!--|<\[^<>\]+\[ \\t\\n\\r\]+[html::URLregexp]"
	set exprr2 {/\*|[ \t\r\n]+(url)\([ \t\r\n]*("[^"]+"|'[^']+'|[^ \t\n\r\)]+)[ \t\r\n]*\)}
	set commStart1 "<!--"
	set commEnd1 "-->"
	set commStart2 {/*}
	set commEnd2 {\*/}

	set num 0
	foreach f $movedFiles2 {
		if {[file::getType $f] != "TEXT"} {continue}
		status::msg "Modifying [file tail $f]É"
		file stat $f finfo
		set created $finfo(ctime)
		if {$HTMLmodeVars(preserveLineEndings)} {set lineending [html::GetLineEndings $f]}
		set fid [open $f r]
		set enc [html::getFileEncoding $f]
		fconfigure $fid -encoding $enc
		set filecont [read $fid 16384]
		set limit [expr {[eof $fid] ? 0 : 300}]
		set temp [html::OpenAfile $enc]
		set tempf [lindex $temp 1]
		set tempfid [lindex $temp 0]
		set oldfile [lindex $movedFiles [lsearch -exact $movedFiles2 $f]]
		set base $fromBase
		set path $fromPath
		set hpPath $homepage
		set epath [string range $oldfile [expr {[string length $homepage] + 1}] end]
		regsub -all [quote::Regfind [file separator]] $epath {/} epath
		# Replace newline chars in IBM files.
		regsub -all "\n\r" $filecont "\r" filecont
		# If BASE is used, only modify links to moved files.
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
				set url1 [string trim $url1 "\"' \t\r\n"]
				set hasBase 1
			}
		}
		if {$hasBase && ![catch {html::BASEpieces $url1} basestr]} {
			set base [lindex $basestr 0]
			set path [lindex $basestr 1]
			set epath [lindex $basestr 2]
			set hpPath ""
		}
		incr num
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
					
					set urltxt [string trim [string range $filecont [lindex $url 0] [lindex $url 1]] "\"' \t\r\n"]
					# No need to update links beginning with a /
					if {[string index $urltxt 0] == "/"} {
						puts -nonewline $tempfid [string range $filecont 0 [lindex $url 1]]
						set filecont [string range $filecont [expr {[lindex $url 1] + 1}] end]
						continue
					}	
					set anchor ""
					regexp {[^#]*(#.*)} $urltxt a anchor
					set urltxt [quote::Unurl $urltxt]
					if {[catch {lindex [html::PathToFile $base $path $epath $hpPath $urltxt] 0} topath]} {set topath ""}
					# Ignore anchors if not moved and BASE.
					# Is the link pointing to a previously moved file?
					if {[set mvind [lsearch -exact $movedFiles $topath]] >= 0} {
						set topath [lindex $movedFiles2 $mvind]
						if {!$hasBase && [string index $urltxt 0] == "#"} {set topath ""}
					} elseif {[string index $urltxt 0] == "#"} {
						set topath ""
					}
						
					if {$hasBase && [regexp -nocase -indices $expBase $filecont thisLine] \
					&& [regexp -nocase $expBase2 [string range $filecont [lindex $thisLine 0] [lindex $thisLine 1]]]\
					&& [lindex $thisLine 0] < [lindex $url 0] && [lindex $thisLine 1] > [lindex $url 1]} {
						set topath ""
					}
					if {[string length $topath]} {
						set lnk [html::BASEfromPath $topath]
						if {!$hasBase} {
							set lnk1 [html::BASEfromPath $f]
							set path2 [lindex $lnk1 1]
							set epath2 [lindex $lnk1 2]
						} else {
							set path2 $path
							set epath2 $epath
						}
						if {$base == [lindex $lnk 0]} {
							set newurl [html::RelativePath "$path2$epath2" "[lindex $lnk 1][lindex $lnk 2]"]
						} else {
							set newurl [join [lrange $lnk 0 2] ""]
						}
						append newurl $anchor
					} elseif {!$hasBase && ($urltxt == ".." || [string range $urltxt 0 2] == "../")} {
						# Special case with relative links outside home page.
						set urlspl [split $urltxt /]
						set old [split $oldfile [file separator]]
						set new [split $f [file separator]]
						if {[llength $new] > [llength $old]} {
							set newurl ""
							for {set i 0} {$i < [expr {[llength $new] - [llength $old]}]} {incr i} {
								append newurl "../"
							}
							append newurl $urltxt
						} else {
							set ok 1
							for {set i 0} {$i < [expr {[llength $old] - [llength $new]}]} {incr i} {
								if {[lindex $urlspl $i] != ".."} {set ok 0}
							}
							if {$ok} {
								set newurl "[join [lrange $urlspl [expr {[llength $old] - [llength $new]}] end] /]$anchor"
							} else {
								set newurl $urltxt
							}
						}
					} else {
						set newurl $urltxt
					}
					puts -nonewline $tempfid [string range $filecont 0 [expr {[lindex $url 0] - 1}]]
					puts -nonewline $tempfid "\"[quote::UrlExceptAnchor $newurl]\""
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
		if {[catch {file delete $f}] && [file exists $f]} {
			alertnote "Could not update [file tail $f]. An error occurred."
		} else {
			catch {
				file copy [lindex $temp 1] $f
				if {$HTMLmodeVars(preserveLineEndings) && (!${alpha::macos} || 
				(${alpha::macos} == 1 && $lineending != "mac") || 
				(${alpha::macos} == 2 && $lineending != "unix"))} {
					file::convertLineEndings $f $lineending
				}
				setFileInfo $f created $created
				setFileInfo $f creator ALFA
				setFileInfo $f type TEXT
			}
		}
		catch {file delete [lindex $temp 1]}
		catch {file delete $tempf}
	}
	return $num
}

# Updates include links to moved files in include folder or include links in moved files.
proc html::UpdateAfterMove3 {movedFiles movedFiles2 homepage inclFldr allFiles {inmoved 0}} {
	global HTMLmodeVars alpha::macos
	set num 0
	set changed ""
	set fid0 [open $allFiles]

	while {![eof $fid0]} {
		gets $fid0 fil
		if {$fil == ""} {continue}
		if {$HTMLmodeVars(preserveLineEndings)} {set lineending [html::GetLineEndings $fil]}
		if {[catch {open $fil} fid]} {continue}
		set enc [html::getFileEncoding $fil]
		fconfigure $fid -encoding $enc
		set filecont [read $fid 16384]
		set limit [expr {[eof $fid] ? 0 : 300}]
		status::msg "Looking at [file tail $fil]É"
		file stat $fil finfo
		set created $finfo(ctime)
		regsub -all "\n\r" $filecont "\r" filecont
		set temp [html::OpenAfile $enc]
		set tmpfid [lindex $temp 0]
		set ismod 0
		while {1} {
			while {[regexp -nocase -indices {<!--[ \t\r\n]+#INCLUDE[ \t\r\n]+[^>]+>} $filecont res] &&
			[expr {[string length $filecont] - [lindex $res 0]}] > $limit} {
				set link [string range $filecont [lindex $res 0] [lindex $res 1]]
				if {[regexp -nocase -indices {(FILE|PATH|INCLPATH)=\"[^\"]+\"} $link res1]} {
					if {!$inmoved && [set ind [lsearch -exact $movedFiles [html::ResolveInclPath \
					  [string range $link [lindex $res1 0] [lindex $res1 1]] $inclFldr [file dirname $fil]]]] >= 0} {
						puts -nonewline $tmpfid [string range $filecont 0 [expr {[lindex $res 0] + [lindex $res1 0] - 1}]]
						puts -nonewline $tmpfid [html::ConvertInclPath [lindex $movedFiles2 $ind] $inclFldr $fil]
						puts -nonewline $tmpfid [string range $filecont [expr {[lindex $res 0] + [lindex $res1 1] + 1}] [lindex $res 1]]
						set ismod 1
						status::msg "Modifying [file tail $fil]É"
					} elseif {$inmoved} {
						set ind [lsearch -exact $movedFiles2 $fil]
						set inpath [html::ResolveInclPath [string range $link [lindex $res1 0] [lindex $res1 1]] $inclFldr \
						  [file dirname [lindex $movedFiles $ind]]]
						puts -nonewline $tmpfid [string range $filecont 0 [expr {[lindex $res 0] + [lindex $res1 0] - 1}]]
						puts -nonewline $tmpfid [html::ConvertInclPath $inpath $inclFldr $fil]
						puts -nonewline $tmpfid [string range $filecont [expr {[lindex $res 0] + [lindex $res1 1] + 1}] [lindex $res 1]]
						set ismod 1
						status::msg "Modifying [file tail $fil]É"
					} else {
						puts -nonewline $tmpfid [string range $filecont 0 [lindex $res 1]]	
					}
				} else {
					puts -nonewline $tmpfid [string range $filecont 0 [lindex $res 1]]
				}
				set filecont [string range $filecont [expr {[lindex $res 1] + 1}] end]
			}
			if {![eof $fid]} {
				puts -nonewline $tmpfid [string range $filecont 0 [expr {[string length $filecont] - 301}]]
				set filecont "[string range $filecont [expr {[string length $filecont] - 300}] end][read $fid 16384]"
				set limit [expr {[eof $fid] ? 0 : 300}]
			} else {
				break
			}
		}
		puts -nonewline $tmpfid $filecont
		close $tmpfid
		close $fid
		if {$ismod} {
			if {[catch {file delete $fil}] && [file exists $fil]} {
				alertnote "Could not update [file tail $fil]. An error occurred."
			} else {
				catch {
					file copy [lindex $temp 1] $fil
					if {$HTMLmodeVars(preserveLineEndings) && (!${alpha::macos} || 
					(${alpha::macos} == 1 && $lineending != "mac") || 
					(${alpha::macos} == 2 && $lineending != "unix"))} {
						file::convertLineEndings $fil $lineending
					}
					setFileInfo $fil created $created
					setFileInfo $fil creator ALFA
					setFileInfo $fil type TEXT
				}
			}
			incr num
			foreach w [html::AllWindowPaths] {
				if {[win::StripCount $w] == "$fil"} {
					lappend changed $w
				}
			}
		}
		catch {file delete [lindex $temp 1]}
	}
	close $fid0
	catch {file delete $allFiles}
	return [list $num $changed]
}

