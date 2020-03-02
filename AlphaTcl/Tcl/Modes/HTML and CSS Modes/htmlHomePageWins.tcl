## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlHomePageWins.tcl"
 #                                    created: 99-07-20 18.03.16 
 #                                last update: 03/21/2006 {03:09:27 PM} 
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
# This file contains procs for the Home Page Windows submenu.
#===============================================================================

proc htmlHomePageWins.tcl {} {}

#===============================================================================
# ×××× Home page windows ×××× #
#===============================================================================

proc html::OpenHPwin {{folder ""}} {
	global html::HomePageWins
	# Get folder to open.
	if {$folder == "" && [catch {html::GetDir "Open:"} folder]} {return}
	set tail [file tail [string trimright $folder [file separator]]]
	# Is their already a window for this folder?
	if {[info exists html::HomePageWins($folder)]} {
		bringToFront [set html::HomePageWins($folder)]
		return	
	}
	set fileList [glob -nocomplain -dir $folder *]
	
	set text "$folder\rcmd-shift-C to copy URL\r"
	foreach fil $fileList {
		if {![regexp "Icon\015$" $fil]} {
			append text [file tail $fil] \r
		}
	}
	if {[set winsize [html::GetHPwinSize $folder]] == ""} {
		new -n $tail -m Home
	} else {
		eval new -n [list "$tail"] -g $winsize -m Home
	}
	insertText $text
	if {$winsize == ""} {shrinkWindow 1}
	# make folders boldface
	for {set i 0} {$i < [llength $fileList]} {incr i} {
		set fil [lindex $fileList $i]
		if {[file isdirectory $fil]} {
			insertColorEscape [pos::fromRowChar [expr {$i + 3}] 0] bold
			insertColorEscape [pos::fromRowChar [expr {$i + 4}] 0] 12
		}
	}
	html::SetWin
	set html::HomePageWins($folder) [lindex [winNames] 0]
}

# Reads a saved home page window size.
proc html::GetHPwinSize {folder} {
	global html::PrefsFolder html::HPwinPositions
	if {[info exists html::HPwinPositions($folder)]} {return [set html::HPwinPositions($folder)]}
	if {![file exists [file join ${html::PrefsFolder} "Home page window positions"]]} {return}
	set cid [scancontext create]
	set pos ""
	scanmatch $cid "^\{?$folder\[ \}\]" {
		if {[lindex $matchInfo(line) 0] == $folder} {set pos [lrange $matchInfo(line) 1 end]}
	}
	set fid [open [file join ${html::PrefsFolder} "Home page window positions"]]
	scanfile $cid $fid
	close $fid
	scancontext delete $cid
	return $pos
}

proc html::QuitHook {} {
	global html::PrefsFolder html::HPwinPositions
	if {![info exists html::HPwinPositions]} {return}
	status::msg "Saving home page window positionsÉ"
	set current ""
	if {[file exists [file join ${html::PrefsFolder} "Home page window positions"]] && 
	![catch {open [file join ${html::PrefsFolder} "Home page window positions"]} fid]} {
		set current [split [read -nonewline $fid] \n]
		close $fid
	}
	foreach c $current {
		if {[info exists html::HPwinPositions([lindex $c 0])]} {
			append n [lrange $c 0 0] " " [set html::HPwinPositions([lindex $c 0])] \n
			unset html::HPwinPositions([lindex $c 0])
		} else {
			append n $c \n
		}
	}
	foreach c [array names html::HPwinPositions] {
		append n [list $c] " " [set html::HPwinPositions($c)] \n
	}
	if {![catch {open [file join ${html::PrefsFolder} "Home page window positions"] w} fid]} {
		puts -nonewline $fid $n
		close $fid
	}
}


# Quick search in home page windows just like in Finder windows.
proc html::SearchInHPwin {char} {
	global Home::Time Home::hpWinString
	set t [ticks]
	if {[expr {$t - ${Home::Time}}] > 60} {set Home::hpWinString ""}
	append Home::hpWinString $char
	set Home::Time $t
	if {[catch {search -s -f 1 -m 0 -r 1 -i 1 "^${Home::hpWinString}" [nextLineStart [nextLineStart [minPos]]]} res]} {return}
	selectText [lindex $res 0] [nextLineStart [lindex $res 1]]
}

proc html::HomeBrowseUp {} {
	set limit [nextLineStart [nextLineStart [minPos]]]
	if {[pos::compare [getPos] > $limit]} {
	set limit [pos::math [getPos] - 1]
	}
	selectText [lineStart $limit] [nextLineStart $limit]
}

proc html::HomeBrowseDown {} {
	set pos [getPos]
	if {[pos::compare $pos < [nextLineStart [minPos]]]} {
	set pos [nextLineStart [minPos]]
	}
	if {[pos::compare [nextLineStart $pos] < [maxPos]]} {
	selectText [nextLineStart $pos] [nextLineStart [nextLineStart $pos]]
	}
}

proc html::HomeReturn {{opt 0}} {
	global HTMLmodeVars alpha::macos
	set f [html::GetAhpLine]
	if {![file exists $f]} {alertnote "[file tail $f] not found."; return}
	if {[file isdirectory $f] && (![regexp {\.app$} $f] || ${alpha::macos} != 2)} {
		if {$opt} {killWindow}
		html::OpenHPwin $f
	} else {
		set creator [file::getSig $f]
		set type [file::getType $f]
		if {$type == "TEXT"} {
			if {$opt} {killWindow}
			edit -c $f
		} elseif {$HTMLmodeVars(homeOpenNonTextFile)} {
			if {$type == "APPL"} {
				if {$opt} {killWindow}
				launch -f $f
			} elseif {[info exists $creator] && ($creator == "MACS")} {
				beep; status::msg "Cannot open."
			} else {
				if {$opt} {killWindow}
				launchDoc $f
			}
		} else {
			beep; status::msg "Not a text file."
		}
	}
}

proc html::HpWinBack {{opt 0}} {
	set folder [file dirname [html::GetHpFolder]]
	if {$folder != ""} {
		if {$opt} {killWindow}
		html::OpenHPwin $folder
	}
}

proc html::GetAhpLine {} {
	return [file join [html::GetHpFolder] \
	  [getText [lineStart [getPos]] [pos::math [nextLineStart [getPos]] - 1]]]
}

proc html::GetHpFolder {} {
	return [getText [minPos] [pos::math [nextLineStart [minPos]] - 1]]
}

# Refreshes a Home page window.
proc html::RefreshHpWin {} {
	set curSel [file tail [html::GetAhpLine]]
	set folder [html::GetHpFolder]
	setWinInfo read-only 0
	if {![file exists [string trimright [file join ${folder} " "]]]} {killWindow; return}
	set files [glob -nocomplain -dir $folder *]
	set files [lremove -regexp -- $files [list "Icon\015$"]]
	set len [llength $files]
	set pos [nextLineStart [nextLineStart [minPos]]]
	set ind 0
	while {$pos < [maxPos] && $ind < $len} {
		set f [file tail [lindex $files $ind]]
		set t [string trim [getText $pos [nextLineStart $pos]]]
		while {$pos < [maxPos] && $ind < $len && $t == $f} {
			incr ind
			set pos [nextLineStart $pos]
			set f [file tail [lindex $files $ind]]
			set t [string trim [getText $pos [nextLineStart $pos]]]
		}
		if {[string compare [string tolower $t] [string tolower $f]] == 1} {
			goto $pos
			insertText $f \r
			if {[file isdirectory [lindex $files $ind]]} {
				insertColorEscape $pos bold
				if {![file isdirectory [lindex $files [expr {$ind + 1}]]]} {
					insertColorEscape [nextLineStart $pos] 12
				}
			} elseif {[file isdirectory [lindex $files [expr {$ind + 1}]]]} {
				insertColorEscape $pos 12
				insertColorEscape [nextLineStart $pos] bold
			}			
			set pos [nextLineStart $pos]
			incr ind
		} else {
			deleteText $pos [nextLineStart $pos]
		}
		if {$pos < [maxPos]} {set t [string trim [getText $pos [nextLineStart $pos]]]}
		set f [file tail [lindex $files $ind]]
	}
	if {$pos < [maxPos]} {
		deleteText [pos::math $pos - 1] [maxPos]
	} else {
		goto [maxPos]
		insertColorEscape $pos 12
		foreach f [lrange $files $ind end] {
			insertText [file tail $f] \r
			if {[file isdirectory $f]} {
				insertColorEscape $pos bold
				insertColorEscape [nextLineStart $pos] 12
			}
			set pos [nextLineStart $pos]	
		}
	}
	refresh
	setWinInfo dirty 0
	setWinInfo read-only 1
	beginningOfBuffer
	if {![catch {search -s -f 1 -m 0 -r 1 -- "^$curSel" [minPos]} res]} {
		selectText [lindex $res 0] [nextLineStart [lindex $res 1]]
	}
}

proc html::RefreshWindows {} {
	global html::HomePageWins
	if {![llength [winNames]]} {return}
	set frontWin [lindex [winNames -f] 0]
	foreach folder [array names html::HomePageWins] {
		bringToFront [set html::HomePageWins($folder)]
		html::RefreshHpWin
	}
	bringToFront $frontWin
}

# Copies an URL from a home page window.
proc html::CopyURL {} {
	global html::HomePageWinURL
	set html::HomePageWinURL [html::GetAhpLine]
	status::msg "${html::HomePageWinURL} copied."
}

# Pastes a previously copied URL from a home page window.
proc html::PasteURL {} {
	global html::HomePageWinURL htmlIsSel htmlCurSel HTMLmodeVars html::WrapPos html::AbsPos
	if {![win::checkIfWinToEdit]} {return}
	if {![info exists html::HomePageWinURL]} {status::msg "No URL to paste."; return}
	if {[set link [html::GetFile 0 ${html::HomePageWinURL} 2]] == ""} {return}
	set url [quote::UrlExceptAnchor [lindex $link 0]]
	html::GetSel
	set html::AbsPos [getPos]
	set html::WrapPos [lindex [pos::toRowCol [getPos]] 1]
	if {[llength [set wh [lindex $link 1]]]} {
		set text [html::SetCase <IMG]
		append text [html::WrapTag "[html::SetCase SRC=]\"$url\""]
		append text [html::WrapTag [html::SetCase "WIDTH=\"[lindex $wh 0]\""]]
		append text [html::WrapTag [html::SetCase "HEIGHT=\"[lindex $wh 1]\">"]]
		set closing ""
	} else {
		set text "<[html::SetCase A]"
		append text [html::WrapTag [html::SetCase HREF=]\"$url\">]
		if {!$htmlIsSel} {append text "¥content¥"}
		set closing [html::CloseElem A]
		if {!$htmlIsSel && $HTMLmodeVars(useTabMarks)} {append closing "¥end¥"}
	}
	append text $htmlCurSel
	append text $closing
	if {$htmlIsSel} { deleteSelection }
	elec::Insertion $text
}


# closeHook
proc html::CloseHook {name} {
	global html::HomePageWins
	foreach folder [array names html::HomePageWins] {
		if {$name == [set html::HomePageWins($folder)]} {
			unset html::HomePageWins($folder)
		}
	}
}

# deactivateHook
proc html::DeactivateHook {name} {
	global html::HPwinPositions
	set winSize [getGeometry]
	# When closing size is {0 0 0 0}
	if {$winSize == {0 0 0 0}} {return}
	set html::HPwinPositions([html::GetHpFolder]) $winSize
}

namespace eval Home {}
proc Home::DblClick {from to} {html::HomeReturn}

proc Home::OptionTitlebar {} {
	return [file split [html::GetHpFolder]]
}

proc Home::OptionTitlebarSelect {item} {
	set folders [file split [html::GetHpFolder]]
	if [key::optionPressed] {killWindow}
	html::OpenHPwin [eval file join [lrange $folders 0 [lsearch -exact $folders $item]]]
}

foreach __char {a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 . _ -} {
	Bind '$__char' "html::SearchInHPwin $__char" Home
}
unset __char

Bind '\r' html::HomeReturn Home
Bind '\r' <o> {html::HomeReturn 1} Home
Bind down <c> html::HomeReturn Home
Bind down <co> {html::HomeReturn 1} Home
Bind enter html::HomeReturn Home
Bind enter {html::HomeReturn 1} Home
Bind down 	html::HomeBrowseDown Home
Bind up 	html::HomeBrowseUp Home
Bind '\r' <c> html::HpWinBack Home
Bind '\r' <co> {html::HpWinBack 1} Home
Bind enter <c> html::HpWinBack Home
Bind enter <co> {html::HpWinBack 1} Home
Bind up <c> html::HpWinBack Home
Bind up <co> {html::HpWinBack 1} Home
Bind 'r' <c> html::RefreshHpWin Home
Bind 'c' <cs> html::CopyURL Home

set Home::Time 0
