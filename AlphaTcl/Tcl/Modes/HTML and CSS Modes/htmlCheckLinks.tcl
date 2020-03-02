## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlCheckLinks.tcl"
 #                                    created: 97-06-26 12.51.42 
 #                                last update: 03/21/2006 {03:08:04 PM} 
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
# This file contains the procs for the Check Links submenu.
#===============================================================================

proc htmlCheckLinks.tcl {} {}

# Check that links are valid.
proc html::CheckWindow {} {html::CheckLinks Window}
proc html::CheckHomePage {} {html::CheckLinks Home}
proc html::CheckFolder {} {html::CheckLinks Folder}
proc html::CheckFile {} {html::CheckLinks File}

# Checks if a folder contains a home page folder or an include folder as a subfolder.
proc html::ContainHpFolder {folder} {
	global HTMLmodeVars
	foreach p $HTMLmodeVars(homePages) {
		foreach i {0 4} {
			if {[llength $p] == $i} {continue}
			if {[string match [file join $folder *] [file join [lindex $p $i] " "]] && 
			[file join [lindex $p $i] " "] != [file join $folder " "]} {
				return 1
			}
		}
	}
	return 0
}


proc html::CheckLinks {where {checking 1}} {
	global HTMLmodeVars
		
	# Save all open window?
	if {$where != "Window" && 
	[html::AllSaved "-c {Save all open windows before checking links?}"] == "cancel"} { return}
	set filebase 0
	if {$where == "File"} {
		if {[catch {getfile "Select file to scan."} files]} {return}
		# Is this a text file?
		if {![html::IsTextFile $files alertnote]} {return}
		set base [html::BASEfromPath $files]
		if {$HTMLmodeVars(useBigBrother)} {html::BigBrother "$files"; return}
		set path [lindex $base 1]
		set homepage [lindex $base 3]
		set isinfld [lindex $base [expr {3 + [lindex $base 4] / 2}]]
		set base [lindex $base 0]
		if {$base == "file:///"} {set filebase [expr {[string length [file dirname $files]] + 1}]}
		set filelist [html::OpenAfile]
		puts [lindex $filelist 0] $files
		close [lindex $filelist 0]
		set files [lindex $filelist 1]
	} elseif {$where == "Window"} {
		if {![llength [winNames]]} {return}
		set files [html::StrippedFrontWindowPath]
		if {![file exists $files]} {
			if {[alert -t caution -k Save -c Cancel -o "" "You must save the window."] == "Cancel"} {
				error "cancel"
			}
			if {![catch {saveAs}]} {
				set files [html::StrippedFrontWindowPath]
			} else {
				error "cancel" 
			}
		} else {
			if {[winDirty] && [askyesno "Save window?"] == "yes"} {save}
		}
		set base [html::BASEfromPath $files]
		if {$checking != 2 && $HTMLmodeVars(useBigBrother)} {html::BigBrother "$files"; return}
		set path [lindex $base 1]
		set homepage [lindex $base 3]
		set isinfld [lindex $base [expr {3 + [lindex $base 4] / 2}]]
		set base [lindex $base 0]
		if {$base == "file:///"} {set filebase [expr {[string length [file dirname $files]] + 1}]}
		set filelist [html::OpenAfile]
		puts [lindex $filelist 0] $files
		close [lindex $filelist 0]
		set files [lindex $filelist 1]
	} elseif {$where == "Folder"} {
		if {[catch {html::GetDir "Folder to scan."} folder]} {return}
		set base [html::BASEfromPath $folder]
		set subFolders [expr {![string compare yes [askyesno "Check files in subfolders?"]]}]
		if {$subFolders && ![set subFolders [expr {![html::ContainHpFolder $folder]}]] &&
		[lindex [dialog -w 410 -h 135 -t "The folder '[file tail $folder]' contains a\
		home page folder or an include folder, but is itself not inside one. You can't\
		simultaneously check links both inside and outside home page or include folders.\
		Sorry!\rBut\
		you can still check this folder and skip the subfolders." 10 10 400 90\
		-b Check 330 105 395 125 -b Cancel 245 105 310 125] 1]} {return}
		if {$HTMLmodeVars(useBigBrother)} {html::BigBrother [string trimright [file join $folder " "]] $subFolders; return}
		set path [lindex $base 1]
		set homepage [lindex $base 3]
		set isinfld [lindex $base [expr {3 + [lindex $base 4] / 2}]]
		set base [lindex $base 0]
		if {$base == "file:///"} {set filebase [expr {[string length $folder] + 1}]}
		if {$subFolders} {
			set files [html::AllHTMLfiles $folder 1]
		} else {
			set files [html::GetHTMLfiles $folder 1]
		}
	} else {
		# Check that a home page is defined.
		if {![html::IsThereAHomePage]} {return}
		if {[catch {html::WhichHomePage "check links in"} hp]} {return}
		set homepage [lindex $hp 0]
		set isinfld $homepage
		if {$HTMLmodeVars(useBigBrother)} {html::BigBrother [string trimright [file join $homepage " "]] 1; return}
		set files [html::AllHTMLfiles $homepage 1]
		set base [lindex $hp 1]
		set path [lindex $hp 2]
	}
	return [html::ScanFiles $files $base $path $homepage $isinfld $checking $filebase]
}

# Select a new file for an invalid link.
proc html::LinkToNewFile {} {
	if {![string match "*Invalid URLs*" [set win [lindex [winNames] 0]]] || [lindex [pos::toRowChar [getPos]] 0] < 3} {return}
	set str [getText [lineStart [getPos]] [pos::math [nextLineStart [getPos]] - 1]]
	browse::Goto
	regexp {Line [0-9]+:([^∞]+)} $str dum url
	regsub -all {\((BASE|Invalid|anchor|case)[^\)]+\)} $url "" url
	set url [string trim $url]
	set str ""
	regexp {[^#]*} $url str
	set anchor [string trim [string range $url [string length $str] end] "\"' \t\r\n"]
	regsub -all {[\(\)]} $url {\\\0} url
	regsub { *= *} $url "\[ \t\r\n\]*=\[ \t\r\n\]*" url1
	if {[catch {search -s -f 1 -i 0 -r 1 -m 0 $url1 [getPos]} res] || 
	[pos::compare [lindex $res 0] > [selEnd]]} {
		alertnote "Can't find link to change on selected line."
		return
	}
	if {[set newFile [html::GetFile 0]] == ""} {return}
	set newLink [lindex $newFile 0]
	set wh [lindex $newFile 1]
	if {$wh == "" && $anchor != "" && [html::CheckAnchor $pathToNewFile [string trim $url "\"' \t\r\n"]]} {
		append newLink $anchor
	}
	set f [quote::UrlExceptAnchor $newLink]
	if {![regsub "(\[^=\]+\[ \t\r\n\]*=\[ \t\r\n\]*)(\"\[^\"\]+\"|'\[^'\]+'|\[^ \]+)" \
	  [eval getText $res] "\\1\"$f\"" url]} {set url url(\"$f\")}
	replaceText [set start [lindex $res 0]] [lindex $res 1] $url
	# If it's an IMG tag, replace WIDTH and HEIGHT.
	if {$wh != "" && [string toupper [string range $url 0 2]] == "SRC" &&
	![catch {search -s -f 0 -i 1 -r 1 -m 0 {<IMG[ \t\r\n]+[^<>]+>} $start} res1] &&
	[pos::compare [lindex $res1 1] > [lindex $res 1]]} {
		if {![catch {search -s -f 1 -i 1 -r 1 -m 0 -l [pos::math [lindex $res1 1] + 1] \
		  {WIDTH[ \t\r\n]*=[ \t\r\n]*("[0-9]*"|'[0-9]*'|[0-9]*)} [lindex $res1 0]} res2]} {
			regsub -nocase "(WIDTH\[ \t\r\n\]*=\[ \t\r\n\]*)(\"\[0-9\]*\"|'\[0-9\]*'|\[0-9\]*)" \
			  [eval getText $res2] "\\1\"[lindex $wh 0]\"" ww
			replaceText [lindex $res2 0] [lindex $res2 1] $ww
		}
		if {![catch {search -s -f 1 -i 1 -r 1 -m 0 -l [pos::math [lindex $res1 1] + 1] \
		  {HEIGHT[ \t\r\n]*=[ \t\r\n]*("[0-9]*"|'[0-9]*'|[0-9]*)} [lindex $res1 0]} res2]} {
			regsub -nocase "(HEIGHT\[ \t\r\n\]*=\[ \t\r\n\]*)(\"\[0-9\]*\"|'\[0-9\]*'|\[0-9\]*)" \
			  [eval getText $res2] "\\1\"[lindex $wh 1]\"" hh
			replaceText [lindex $res2 0] [lindex $res2 1] $hh
		}
	}
	# Remove line with corrected link.
	bringToFront $win
	setWinInfo read-only 0
	deleteText [lineStart [getPos]] [nextLineStart [getPos]]
	selectText [lineStart [getPos]] [nextLineStart [getPos]]
	setWinInfo dirty 0
	setWinInfo read-only 1
}

Bind '\r' <o> html::LinkToNewFile Brws
Bind enter <o> html::LinkToNewFile Brws

proc html::BbthReadSettings {} {
	set res [tclAE::send -r 'Bbth' core getd ---- "obj{want:type('reco'),from:null(),form:'prop',seld:type('allS')}"]
	set allSettings [tclAE::getKeyDesc $res ----]
	tclAE::disposeDesc $res
	return $allSettings
}

proc html::BbthRestoreSettings {settings} {
	tclAE::send 'Bbth' core setd "----" "obj{want:type('reco'),from:null(),form:'prop',seld:type('allS')}" "data" $settings
}

proc html::BigBrother {path {searchSubFolder 0}} {
	global HTMLmodeVars
	# define url mapping
	set urlmap [html::URLmap]
	# launches Big Brother
	if {![app::isRunning Bbth] && [catch {app::launchBack Bbth}]} {
		alertnote "Could not find or launch Big Brother."
		return
	}
	if {[set vers [html::GetVersion Bbth]] >= 1.1} {
		# Read all settings.
		set allSettings [html::BbthReadSettings]
		# Change settings
		if {!$HTMLmodeVars(useBBoptions)} {
			tclAE::send 'Bbth' core setd "----" "obj{want:type('bool'),from:null(),form:'prop',seld:type('Loly')}" "data" "bool(«0$HTMLmodeVars(ignoreRemote)»)"
			tclAE::send 'Bbth' core setd "----" "obj{want:type('bool'),from:null(),form:'prop',seld:type('Roly')}" "data" "bool(«0$HTMLmodeVars(ignoreLocal)»)"
		}
		tclAE::send 'Bbth' core setd "----" "obj{want:type('bool'),from:null(),form:'prop',seld:type('Sfld')}" "data" "bool(«0${searchSubFolder}»)"
		tclAE::send 'Bbth' core setd "----" "obj{want:type('mapG'),from:null(),form:'prop',seld:type('mapS')}" "data" "\[$urlmap\]"
		if {$vers >= 1.2} {
			tclAE::send 'Bbth' core setd "----" "obj{want:type('bool'),from:null(),form:'prop',seld:type('CasS')}" "data" "bool(«0$HTMLmodeVars(caseSensitive)»)"		
		}
	} else {
		alertnote "Cannot change the settings in Big Brother. You need Big Brother 1.1 or later."
	}
	# Sends a file or folder to be opened.
	sendOpenEvent noReply 'Bbth' $path
	# Restore settings
	if {$vers >= 1.1} {html::BbthRestoreSettings $allSettings}
	if {$HTMLmodeVars(checkInFront)} {switchTo 'Bbth'}
}


#  Checking of remote links in a document
proc html::CheckRemoteLinks {} {
	global htmlNumBbthChecking
	if {![llength [winNames]]} {return}
	if {[html::GetVersion Bbth] < 1.2} {
		alertnote "You need Big Brother 1.2 or later to check and fix remote links."
		return
	}
	set urlList [html::CheckLinks Window 2]
	if {![llength $urlList]} {alertnote "No remote links to check."; return}
	if {![app::isRunning Bbth] && [catch {app::launchBack Bbth}]} {
		alertnote "Could not find or launch Big Brother."
		return
	}
	set htmlBbthChkdWin [html::StrippedFrontWindowPath]
	set sep ""
	foreach url $urlList {
		append theRecord "$sep{Url :“[lindex $url 1]”, Id# :“[concat $url $htmlBbthChkdWin]”}"
		set sep ", "
	}
	# Read all settings.
	set allSettings [html::BbthReadSettings]
	
	# Don't ignore remote links
	tclAE::send 'Bbth' core setd "----" "obj{want:type('bool'),from:null(),form:'prop',seld:type('Loly')}" "data" "bool(«00»)"
	# No url mappings.
	tclAE::send 'Bbth' core setd "----" "obj{want:type('mapG'),from:null(),form:'prop',seld:type('mapS')}" "data" "\[\]"
	tclAE::send 'Bbth' "Bbth" "Chck" "----" "\[$theRecord\]"
	html::BbthRestoreSettings $allSettings
	incr htmlNumBbthChecking [llength $urlList]
}

# Takes care of events sent from Big Brother.
proc html::BbthChkdHandler {args} {
	global tileLeft tileTop tileWidth errorHeight htmlNumBbthChecking browse::separator
	set data [tclAE::getKeyDesc [lindex $args 0] ----]
	set id [tclAE::getKeyData $data "Id# "]
	set result [tclAE::getKeyData $data CRes]
	set win [lrange $id 2 end]
	switch $result {
		RSuc {set str "The remote document exists."; set color 3}
		LSuc {set str "The local document exists."; set color 3}
		SFld {
			set color 5
			set code [tclAE::getKeyData $data SCod]
			switch $code {
				"204" {set str "The document exists but contains no data."}
				"400" {set str "The server (or the proxy) reports a bad request."}
				"401" {set str "The document seems to exist but a password is required to access it."}
				"403" {set str "The document still exists but the server refuses to deliver it."}
				"404" {set str "The remote document doesn't exist."}
				"500" {set str "The server reports an internal error while trying to serve our request."}
				"501" {set str "The server doesn't seem to support checking the existence of a link."}
				"502" {set str "A gateway reported an error."}
				"503" {set str "The server is currently unable to deliver this document. This situation might be temporary."}
				default {set str "The server answered with an unknown HTTP response code."}
			}
		}
		SMvd {
			set color 1
			set code [tclAE::getKeyData $data SCod]
			set newURL [tclAE::getKeyData $data nURL]
			switch $code {
				"301" {set str "The document has moved permanently to $newURL."}
				"302" {set str "The document has moved temporarily to $newURL."}
				default {set str "The document has moved to $newURL."}
			}
			edit -c -w $win
			set l [pos::fromRowChar [lindex $id 0] 0]
			if {![catch {search -s -f 1 -i 1 -m 0 -r 0 -l [nextLineStart $l] [lindex $id 1] [lineStart $l]} res]} {
				eval replaceText $res $newURL
			}
		}
		sFld {
			set color 5
			set reason [tclAE::getKeyData $data sRsn]		
			switch $reason {
				bnAb {set str "Invalid base URL: it should be an absolute URL."}
				nTCP {set str "MacTCP or Open Transport TCP/IP is needed to check remote links."}
				locF {set str "Invalid local link."}
				Open {set str "Initializing the network services failed."}
				Bind {set str "Selecting a local port failed."}
				Rslv {set str "Resolving the host name failed."}
				Conn {set str "Establishing the connection failed."}
				Send {set str "Sending the request failed."}
				Recv {set str "Receiving the server's answer failed."}
				Disc {set str "Closing the connection failed."}
				Pars {set str "The server's response doesn't conform to the HTTP/1.0 protocol."}
				Empt {set str "The server closed the connection without answering."}
				IncT {set str "The server sent only part of the document."}
				SWDr {set str "The server said the document exists, but wasn't able to deliver it."}
				NTr/ {set str "This URL should end with a slash because it points to a directory."}
				default {set str "Checking the link failed for an unknown reason."}
			}
		}
		Sntx {set str "URL syntax error."; set color 5}
	}
	tclAE::disposeDesc $data
	if {[lsearch -exact [html::AllWindowPaths] "* Remote URLs *"] < 0} {
		new -n "* Remote URLs *" -g $tileLeft $tileTop $tileWidth $errorHeight -m Brws
		insertText "Link checking results:  (<uparrow> and <downarrow> to browse, <return> to go to line\rLinks to moved pages have been changed.\r${browse::separator}\r"
		html::SetWin
	}
	bringToFront "* Remote URLs *"
	setWinInfo read-only 0
	goto [maxPos]
	insertText "Line [lindex $id 0]: "
	insertColorEscape [getPos] $color 
	insertText "$str"
	insertColorEscape [getPos] 0
	insertText " [lindex $id 1]\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t∞$win\r"
	incr htmlNumBbthChecking -1
	if {!$htmlNumBbthChecking} {insertText "Done.\r"}
	refresh
	setWinInfo dirty 0
	setWinInfo read-only 1
}

# Returns a list of all HTML and CSS files in a folder and its subfolders.
proc html::AllHTMLfiles {folder {CSS 0} {toExclude ""}} {
	status::msg "Building file list…"
	set filelist [html::OpenAfile]
	set fid [lindex $filelist 0]
	set files [lindex $filelist 1]
	set folders [list $folder]
	while {[llength $folders]} {
		set newFolders ""
		foreach fl $folders { 
			html::GetHTMLfiles $fl $CSS $fid $toExclude
			# Get folders in this folder.
			append newFolders " " [glob -nocomplain -types d -dir $fl *]
		}
		set folders $newFolders
	}
	close $fid
	return $files
}

# Finds all HTML files in a folder
proc html::GetHTMLfiles {folder {CSS 0} {fid ""} {toExclude ""}} {
	set pats [mode::filePatterns HTML]
	if {$CSS} {
	    eval lappend pats [mode::filePatterns CSS]
	}
	set files ""
	set cl 0
	if {$fid == ""} {
		set filelist [html::OpenAfile]
		set fid [lindex $filelist 0]
		set files [lindex $filelist 1]
		set cl 1
	}
	if {![catch {glob -types TEXT -dir $folder *} filelist]} {
		foreach fil $filelist {
			foreach suffix $pats {
				if {[string match $suffix $fil] && ![lcontains toExclude $fil]} {
					puts $fid $fil
					break
				}
			}
		}
	}
	if {$cl} {close $fid}
	return $files
}

# Opens a filelist file. Returns fileid and path.
proc html::OpenAfile {{enc ""}} {
	global tcl_platform
	set tmpfil [temp::unique HTML tempfile]
	set fid [open $tmpfil w+]
	if {$enc != ""} {
		fconfigure $fid -encoding $enc
	}
	return [list $fid $tmpfil]
}



# checking = 1 or 2: called from html::CheckLinks
# checking = 1:
# Scan a list of files for HTML links and check if they point to existing files.
# checking = 2:
# Scan a list of files for HTML links and return the remote ones for checking with Big Brother.
# checking = 0: called from htmlMoveFiles
# Build a list of links which point to the files just moved.
proc html::ScanFiles {files baseURL basePath homepage isInFolder checking filebase {movedFiles ""}} {
	global HTMLmodeVars browse::separator
	global tileLeft tileTop tileWidth errorHeight
	global htmlCaseFolders htmlCaseFiles

	set htmlCaseFolders ""; set htmlCaseFiles ""
	set chCase $HTMLmodeVars(caseSensitive)
	set chAnchor $HTMLmodeVars(checkAnchors)
	
	# Build regular expressions with URL attrs.	
	set expBase "<base\[ \\t\\n\\r\]+\[^>\]*>"
	set expBase2 "(href\[ \\t\\n\\r\]*=\[ \\t\\n\\r\]*)(\"\[^\"\]+\"|'\[^'\]+'|\[^ \\t\\n\\r\"'>\]+)"
	set exp1 "<!--|<\[^<>\]+\[ \\t\\n\\r\]+[html::URLregexp]"
	set exp2 {/\*|[ \t\r\n]+(url)\([ \t\r\n]*("[^"]+"|'[^']+'|[^ "'\t\n\r\)]+)[ \t\r\n]*\)}
	set toCheck ""
	if {$checking != 2} {
		set result [html::OpenAfile]
		set fidr [lindex $result 0]
	}
	set checkFail 0
	
	set commStart1 "<!--"
	set commEnd1 "-->"
	set commStart2 {/*}
	set commEnd2 {\*/}
	
	# Open file with filelist
	set fid0 [open $files]

	while {![eof $fid0]} {
		gets $fid0 f
		if {$f == "" || [catch {open $f} fid]} {continue}
		set base $baseURL
		set path $basePath
		set hpPath $homepage
		if {$isInFolder == ""} {
			set epath $f
		} else {
			set epath [string range $f [expr {[string length $isInFolder] + 1}] end]
		}
		regsub -all [quote::Regfind [file separator]] $epath {/} epath
		set baseText ""
		status::msg "Looking at [file tail $f]…"
		set filecont [read $fid 16384]
		set limit [expr {[eof $fid] ? 0 : 300}]
		if {[regexp {\n} $filecont]} {
			set newln "\n"
		} else {
			set newln "\r"
		}
		# Look for BASE.
		if {[regexp -nocase -indices $expBase $filecont thisLine]} {
			set preBase [string range $filecont 0 [lindex $thisLine 0]]
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
			if {!$comm && [regexp -nocase $expBase2 [string range $filecont [lindex $thisLine 0] [lindex $thisLine 1]] href b url]} {
				set url [string trim $url "\"' \t\r\n"]
				if {![catch {html::BASEpieces $url} basestr]} {
					set base [lindex $basestr 0]
					set path [lindex $basestr 1]
					set epath [lindex $basestr 2]
					set hpPath ""
					set baseText "(BASE used) "
				} else {
					set baseText "(Invalid BASE) "
				}
			}
		}
		for {set i1 1} {$i1 < 3} {incr i1} {
			set exprr [set exp$i1]
			if {$i1 == 2} {
				seek $fid 0
				set filecont [read $fid 16384]
				set limit [expr {[eof $fid] ? 0 : 300}] 
			}
			set commStart [set commStart$i1]
			set commEnd [set commEnd$i1]
			set linenum 1
			set comment 0
			while {1} {
				# Find all links in every line.
				while {$comment || ([regexp -nocase -indices $exprr $filecont href attr url] &&
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
							incr linenum [regsub -all $newln [string range $filecont 0 [expr {[lindex $href 1] + [lindex $cend 1]}]] {} dummy]
							set filecont [string range $filecont [expr {[lindex $href 1] + [lindex $cend 1]}] end]
							set comment 0
							continue
						} else {
							set comment 1
							break
						}
					}
					incr linenum [regsub -all $newln [string range $filecont 0 [lindex $url 0]] {} dummy]
					set linkTo [quote::Unurl [string trim [string range $filecont [lindex $url 0] [lindex $url 1]] "\"' \t\r\n"]]
					set nogood 0
					if {[catch {html::PathToFile $base $path $epath $hpPath $linkTo} linkToPath]} {
						if {$linkToPath == ""} {
							set nogood 1
						} elseif {$checking == 2 && [string range $linkToPath 0 6] == "http://"} {
							# Checking remote links
							lappend toCheck [list $linenum $linkToPath]
						}
						set linkToPath ""
					} else {
						# Anchors always point to the file itself, unless there's a BASE. 
						if {[string index $linkTo 0] == "#" && $baseText == ""} {set linkToPath [list $f $f]}
						set casePath [lindex $linkToPath 1]
						set linkToPath [lindex $linkToPath 0]
					}
					# If this is BASE HREF, ignore it.
					if {[string length $baseText] && [regexp -nocase -indices $expBase $filecont thisLine] \
					&& [regexp -nocase $expBase2 [string range $filecont [lindex $thisLine 0] [lindex $thisLine 1]]]\
					&& [lindex $thisLine 0] < [lindex $url 0] && [lindex $thisLine 1] > [lindex $url 1]} {
						set linkToPath ""
					}
					if {$checking == 1} {
						set anchorCheck 1
						set caseOK 1
						set fext [file exists $linkToPath]
						if {$chAnchor && $linkToPath != "" && [regexp {#} $linkTo] && $fext} {set anchorCheck [html::CheckAnchor $linkToPath $linkTo]}
						if {$chCase && $linkToPath != "" && $fext} {set caseOK [html::CheckLinkCase $linkToPath $casePath]}
						# Does the file exist? Ignore it if it's outside home page folder.
						# Then it point to someone else's home page.
						if {!$anchorCheck || $nogood || !$caseOK || ( $linkToPath != "" && !$fext)} {
							set bText $baseText
							if {!$anchorCheck} {append bText "(anchor missing) "}
							if {!$caseOK} {append bText "(case doesn't match) "}
							if {$homepage == ""} {
								set line [string range $f $filebase end]
							} else {
								set line [string range $f [expr {[string length $isInFolder] + 1}] end]
							}
							set l [expr {20 - [string length [file tail $f]]}]
							set ln [expr {5 - [string length $linenum]}]
							set href [string trim [string range $filecont [lindex $attr 0] [lindex $href 1]]]
							set lnum [expr {$linenum - [regsub -all "\n\r|\r|\n" $href "" href]}]
							append line "[format "%$l\s" ""] Line $lnum:[format "%$ln\s" ""]$bText$href"\
							"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t∞$f"
							puts $fidr $line
							set checkFail 1
						}
					} elseif {!$checking && [lcontains movedFiles $linkToPath]} {
						set href [string trim [string range $filecont [lindex $href 0] [lindex $href 1]]]
						set lnum [expr {$linenum - [regsub -all "\n\r|\r|\n" $href "" href]}]
						puts $fidr [list $f $lnum $base $path $epath $linkToPath $href]
					}
					set filecont [string range $filecont [lindex $url 1] end]
				}
				if {![eof $fid]} {
					incr linenum [regsub -all $newln [string range $filecont 0 [expr {[string length $filecont] - 301}]] {} dummy]
					set filecont "[string range $filecont [expr {[string length $filecont] - 300}] end][read $fid 16384]"
					set limit [expr {[eof $fid] ? 0 : 300}] 
				} else {
					break
				}
			}
		}
		close $fid
	}
	close $fid0
	catch {file delete $files}
	unset -nocomplain htmlCaseFolders htmlCaseFiles filecont
	status::msg ""
	if {$checking == 1} {
		if {$checkFail} {
			seek $fidr 0
			new -n "* Invalid URLs *" -g $tileLeft $tileTop $tileWidth $errorHeight -m Brws
			insertText "Incorrect links:  (<uparrow> and <downarrow> to browse, <return> to go to file,\ropt-<return> to select a new file)\r${browse::separator}\r[read $fidr]"
			html::SetWin
			browse::Down
		} else {
			alertnote "All links are OK."
		}
		close $fidr
		catch {file delete [lindex $result 1]}
	} elseif {!$checking} {
		return $result
	} else {
		return $toCheck
	}
}

proc html::CheckAnchor {anchorFile url} {
	regexp {[^#]*#(.*)} $url dum anchor
	if {[catch {open $anchorFile r} fid]} {return 1}
	set exp "<!--|<(A|MAP)\[ \t\r\n\]+\[^<>\]*NAME\[ \t\n\r\]*=\[ \t\n\r\]*(\"\[ \t\n\r\]*$anchor\[ \t\n\r\]*\"|'\[ \t\n\r\]*$anchor\[ \t\n\r\]*'|$anchor)(>|\[ \t\r\n\]+\[^<>\]*>)"
	set filecont [read $fid 16384]
	set limit [expr {[eof $fid] ? 0 : 300}]
	set comment 0
	while {1} {
		while {$comment || ([regexp -nocase -indices $exp $filecont anch] &&
		[expr {[string length $filecont] - [lindex $anch 0]}] > $limit)} {
			if {$comment || [string range $filecont [lindex $anch 0] [lindex $anch 1]] == "<!--"} {
				if {$comment} {
					set anch {0 0}
					set subcont $filecont
				} else {
					set subcont [string range $filecont [expr {[lindex $anch 1] + 1}] end]
				}
				if {[regexp -indices -- "-->" $subcont cend] &&
				[expr {[string length $subcont] - [lindex $cend 0]}] > $limit} {
					set filecont [string range $filecont [expr {[lindex $anch 1] + [lindex $cend 1]}] end]
					set comment 0
					continue
				} else {
					set comment 1
					break
				}
			} else {
				close $fid
				return 1
			}
		} 
		if {![eof $fid]} {
			set filecont "[string range $filecont [expr {[string length $filecont] - 300}] end][read $fid 16384]"
			set limit [expr {[eof $fid] ? 0 : 300}] 
		} else {
			break
		}
	}
	close $fid
	return 0
}

# Checks that the case in a link match the case in the path to file.
proc html::CheckLinkCase {path link} {
	global htmlCaseFolders htmlCaseFiles
	
	set path [string trimright $path [file separator]]
	set link [string trimright $link [file separator]]
	if {[lcontains htmlCaseFiles $path]} {return 1}
	set path [file split $path]
	set plen [llength $path]
	set llen [llength [file split $link]]
	set j [expr {$plen - $llen ? $plen - $llen - 1 : 0}]
	for {set i $j} {$i < $plen - 1} {incr i} {
		set l [lindex $path [expr {$i + 1}]]
		set psub [eval file join [lrange $path 0 $i]]
		if {![lcontains htmlCaseFolders $psub]} {
			lappend htmlCaseFolders $psub
			append htmlCaseFiles " " [glob -nocomplain -dir $psub *]
		}
		if {![lcontains htmlCaseFiles [file join $psub $l]]} {return 0}
	}
	return 1
}

