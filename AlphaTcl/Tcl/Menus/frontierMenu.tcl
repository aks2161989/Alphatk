## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  Frontier menu - tools for using Alpha as Frontier's external editor
 # 
 #  FILE: "frontierMenu.tcl"
 #                                    created: 97-04-03 22.01.22 
 #                                last update: 03/21/2006 {01:51:16 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 2.2
 # 
 # Copyright 1997-2006 by Johan Linde
 #  
 # Much of the tcl code and the Frontier scripts have been written by 
 # Danis Georgiadis <dmg@hyper.gr>
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

alpha::menu frontierMenu 2.2.1 global "•142" {} {
	frontierMenu
} {
	catch {removeMenu $frontierScriptMenu}
} uninstall {
	file delete $pkg_file
	file delete [file join $HOME Help "Frontier Help"]
} maintainer {
	"Johan Linde" <alpha_www_tools@go.to> <http://go.to/alpha_www_tools>
} description {
	Interacts with the Frontier application for .html file suites
} help {
	file "Frontier Help"
} requirements {
	if {$alpha::macos == 0} {
		error "Frontier menu is only supported on Mac OS"
	}
}

proc frontierMenu {} {}
set frontierScriptMenu •144
namespace eval Fron {}

# Preferences
newPref f autoLaunch 0 Fron
newPref v lineWrap 0 Fron
newPref v BrowsePoints {{root root} {Websites websites}} Fron
newPref v OpenPoints {{Websites websites} {Glossary user.html.glossary} {Templates user.html.templates}} Fron

# Register hooks
hook::register closeHook frontierCloseHook

# Do this as late as possible!
addMode Fron frontierMenu {} {}
addMode Odb frontierMenu {} {}

proc frontierBrowseMenu {} {
	global FronmodeVars
	set bl {}
	foreach b $FronmodeVars(BrowsePoints) {
		lappend bl [lindex $b 0]
	}
	return [list Menu -n browseFrontier -p frontierMenuProc -m [concat $bl [list "(-" "Browse at…" Add… Remove…]]]
}

proc frontierOpenMenu {} {
	global FronmodeVars
	set bl {}
	foreach b $FronmodeVars(OpenPoints) {
		lappend bl [lindex $b 0]
	}
	return [list Menu -n openFrontier -p frontierMenuProc -m [concat $bl [list "(-" "Open…" Add… Remove…]]]
}

# Menu definition
proc menu::buildFrontierMenu {} {
	global frontierMenu
	return [list build [list  \
	"<U<O/Fswitch toFrontier" \
	"<U<O/'previewPage" \
	"<B<O/'publishPage" \
	"<I<O/YfrontierShell" \
	[frontierBrowseMenu] \
	[frontierOpenMenu] \
	"rebuildScriptsMenu" \
	preferences…] \
	frontierMenuProc "" $frontierMenu]
}

menu::buildProc frontierMenu menu::buildFrontierMenu
menu::buildSome frontierMenu

proc frontierMenuProc {menu item} {
	global frontierMenu FronmodeVars
	switch -glob $menu {
		•* {
			switch -glob $item {
				"switch*toFrontier" {frontierLaunch Fore}
				preferences {FronmodifyFlags}
				default {eval frontier$item}
			}
		}
		browseFrontier {
			switch $item {
				"Browse at" {frontierBrowseAt}
				Add {frontierAddPoint Browse}
				Remove {frontierRemovePoint Browse}
				default {
					foreach b $FronmodeVars(BrowsePoints) {
						if {[lindex $b 0] == $item} {
							frontierCheckExist [lindex $b 1] $item Browse
							odbBrowse [lindex $b 1]
							break
						}
					}
				}
			}
		}
		openFrontier {
			switch $item {
				Open {frontierOpen}
				Add {frontierAddPoint Open}
				Remove {frontierRemovePoint Open}
				default {
					foreach b $FronmodeVars(OpenPoints) {
						if {[lindex $b 0] == $item} {
							frontierCheckExist [lindex $b 1] $item Open
							frontierDoScript "edit (@[lindex $b 1])" front
							break
						}
					}
				}
			}
		}
	}
}

proc frontierCheckExist {item mitem type} {
	if {[frontierDoScript defined($item)] == "false"} {
		alertnote "$mitem no longer exists in the database. It is removed from the menu."
		frontierDoTheRemove $type $mitem
		error "Cancel"
	}
	
}

proc frontierLaunch {{b Back}} {
	if {![app::isRunning LAND]} {
		if {[catch {eval app::launch$b LAND}]} {
			alertnote "Could not launch Frontier."
			error "Cancel"
		}
	} elseif {$b == "Fore"} {
		switchTo 'LAND'
	}
}

# Executes a script in Frontier.
proc frontierDoScript {script {front 0} {alert 1} {replyHandler ""}} {
	if {[catch frontierLaunch]} {error "Cancelled -- could not launch Frontier."}
	if {$replyHandler != ""} {
		# Never switch to Frontier when queing.
		tclAE::send -Q $replyHandler 'LAND' misc dosc ---- [tclAE::build::TEXT $script]
		return
	} elseif {[catch {tclAE::build::resultData 'LAND' misc dosc ---- [tclAE::build::TEXT $script]} returnvalue]} {
		regsub ": AppleEvent handler failed.$" $returnvalue "" returnvalue
		if {$alert} {
			alertnote "Frontier $returnvalue"
			error "Cancel"
		}
		error $returnvalue
	} elseif {$front == "front"} {
		switchTo 'LAND'
	}
	return $returnvalue
}

# Executes one of the scripts in Frontier, which are required to use Alpha with Frontier.
proc frontierDoAlphaScript {script {replyHandler ""}} {
	global HOME frontierHasWarned
	if {[catch {frontierDoScript $script 0 0 $replyHandler} res]} {
		frontierError
		error $res
	}
	return $res
}

proc frontierError {} {
	global frontierHasWarned HOME
	if {![info exists frontierHasWarned]} {
		alertnote "The Frontier verbs required to integrate Alpha and Frontier have not been\
		  properly installed. See the file 'Frontier Help.'"
		edit -r -c [help::pathToHelp "Frontier Help"]
	}
}
	
# closeHook
# If the window to be closed is a Frontier document, it is removed
# from Frontier's list of open external documents.
proc frontierCloseHook {name} {
	global frontierQSWin frontierCommandHistory frontierCommandNum
	if {$name == $frontierQSWin} {set frontierCommandHistory ""; set frontierCommandNum 0}
}

# Does the same as 'Preview Page' in Frontier's web menu.
proc frontierpreviewPage {} {
	frontierPrePub viewInBrowser
}

# Does the same as 'Publish Page' in Frontier's web menu.
proc frontierpublishPage {} {
	frontierPrePub publishPage
}

proc frontierPrePub {script} {
	global odbedited
	if {![llength [winNames]]} {
		alertnote "No window!"
		return
	}
	set name [lindex [winNames -f] 0]
	if {[info exists odbedited($name)] && [lindex $odbedited($name) 0] == "LAND"} {
		if {[winDirty]} {
			if {[set ask [askyesno -c "Save '[file tail $name]'?"]] == "yes"} {
				save
			} elseif {$ask == "cancel"} {
				return
			}
		}
		set name [file::unixPathToFinder [win::StripCount $name]]
		regsub -all "\"" $name "\\\"" name
		frontierDoScript "Alpha.${script}(\"[string tolower $name]\")"
	} else {
		alertnote "Not a Frontier window."
	}
}

# Open a window in Frontier
proc frontierOpen {} {
	if {![catch {frontierGetAddress} addr]} {
		frontierDoScript "edit (@$addr)" front
	}
}

# Browse a table in Frontier
proc frontierBrowseAt {} {
	if {![catch {frontierGetAddress} addr]} {
		odbBrowse $addr
	}
}

# Add to Browse and Open submenus
proc frontierAddPoint {type} {
	global FronmodeVars
	set values ""
	while {1} {
		set values [dialog -w 450 -h 110 -T "$type menu item" \
			-t "Location in database:" 10 20 160 40 -e [lindex $values 0] 165 20 440 35 \
			-t "Menu text:" 78 50 160 70 -e [lindex $values 1] 165 50 440 65 \
			-b OK 370 80 435 100 -b Cancel 290 80 355 100]
		if {[lindex $values 3]} {return}
		set addr [string trim [lindex $values 0]]
		if {$addr == ""} {alertnote "Location is database must be specified."; continue}
		set text [string trim [lindex $values 1]]
		if {$text == ""} {alertnote "The menu item must be specified."; continue}
		if {[frontierDoScript "defined($addr)"] == "true"} {
			set ex 0
			foreach b $FronmodeVars(${type}Points) {
				if {[lindex $b 0] == $text} {alertnote "A menu item '$text' already exists."; set ex 1}
			}
			if {!$ex} {break}
		} else {
			alertnote "“${addr}” is not a valid database address."
		}
	}
	lappend FronmodeVars(${type}Points) [list $text $addr]
	prefs::modifiedModeVar ${type}Points Fron
	eval [eval frontier${type}Menu]
}

# Remove from Browse and Open submenus.
proc frontierRemovePoint {type} {
	global FronmodeVars
	set points {}
	foreach b $FronmodeVars(${type}Points) {
		lappend points [lindex $b 0]
		set pointat([lindex $b 0]) [lindex $b 1]
	}
	if {![llength $points] || [catch {listpick -p "Select [string tolower $type] point to remove:" -l $points} points] ||
		![llength $points]} {return}
	set points [lindex $points 0]
	if {[askyesno "'$points' points to '$pointat($points)'. Remove?"] != "yes"} {return}
	frontierDoTheRemove $type $points
}

proc frontierDoTheRemove {type points} {
	global FronmodeVars
	set n {}
	foreach b $FronmodeVars(${type}Points) {
		if {[lindex $b 0] != $points} {lappend n $b}
	}
	set FronmodeVars(${type}Points) $n
	prefs::modifiedModeVar ${type}Points Fron
	eval [eval frontier${type}Menu]
}

proc frontierGetAddress {} {
	while {1} {
		if {[catch {set addr [prompt "Location in Frontier database:" ""]}]} {
			error "cancel"
		} else {
			set addr [string trimleft [string trim $addr] {@}]
			switch [frontierDoScript "defined($addr)"] {
				"true"		{return $addr}
				"false"		{alertnote "“${addr}” is not a valid database address"}
				""			{error "cancel"}
			}
		}
	}
}

proc FronmodifyFlags {} {
	global FronmodeVars
	set values [dialog -w 300 -h 90 -T "Frontier Preferences" \
		-c "Launch Frontier at startup" $FronmodeVars(autoLaunch) 10 20 290 40 \
		-b OK 220 60 285 80 -b Cancel 135 60 200 80]
	if {[lindex $values 2]} {return}
	set i -1
	foreach flag [list autoLaunch] {
		global $flag
		incr i
		set val [lindex $values $i]
		if {$FronmodeVars($flag) != $val} {
			set $flag $val
			set FronmodeVars($flag) $val
			prefs::modifiedModeVar $flag Fron
		}
	}
}

proc OdbmodifyFlags {} {
	FronmodifyFlags
}

#===============================================================================
# Script menu
# 
# The code to extract a Frontier menu has been written by
# Danis Georgiadis <dmg@hyper.gr>
# 
#===============================================================================

proc setFrontierMenuScript {menu item scpt} {
	global frontierMenuScripts
	if {[regexp {&$} $item]} {
		set item [string trimright $item &]
	} else {
		regsub -all {<[BUISEO]} $item "" item
		regsub {/[a-zA-Z]} $item "" item
		regsub -all {[!\^].} $item "" item
	}
	set key [string trimright "$menu$item" …]
	set frontierMenuScripts($key) $scpt
}

proc frontierBuildScriptMenu {} {
	global frontierScriptMenu FronmodeVars

	if {![app::isRunning LAND]} {
		if {$FronmodeVars(autoLaunch)} {
			app::launchBack LAND
		} else {
			return
		}
	}
	frontierDoAlphaScript "Alpha.getMenuSource()" frontierGetMenuReplyHandler

}

proc frontierScriptMenuProc {menu item} {
	global frontierMenuScripts frontierScriptMenu
	if {$menu == $frontierScriptMenu} {set menu ""}
	set key "$menu$item"
	frontierDoScript $frontierMenuScripts($key)
}

proc frontierrebuildScriptsMenu {} {
	global frontierMenuScripts
	frontierLaunch
	frontierDoAlphaScript "Alpha.invalMenuSources()" frontierInvalReplyHandler
}

proc frontierGetMenuReplyHandler {args} {
	global frontierScriptMenu
	set reply [lindex $args 0]
	if {![catch {tclAE::getKeyData $reply errs}]} {
		frontierError
	} else {
		set txt [tclAE::getKeyData $reply ----]
		Menu -m -n $frontierScriptMenu -p frontierScriptMenuProc $txt
		insertMenu $frontierScriptMenu
		catch {frontierDoAlphaScript "Alpha.getDefsSource()" frontierGetDefsReplyHandler}
	}
	return
}

proc frontierGetDefsReplyHandler {args} {
	set reply [lindex $args 0]
	if {![catch {tclAE::getKeyData $reply errs}]} {
		frontierError
	} else {
		set txt [tclAE::getKeyData $reply ----]
		catch {eval $txt}
	}
	status::msg "Frontier script menu built."
	return
}

proc frontierInvalReplyHandler {args} {
	unset -nocomplain frontierMenuScripts
	catch {frontierBuildScriptMenu}
	return
}


#===============================================================================
#
# Frontier shell
# 
# Some ideas taken from Matlab mode by Stephen Merkowitz
# 
#===============================================================================
set frontierQSWin "* Frontier shell *"
set frontierCommandHistory ""
set frontierCommandNum 0

proc frontierfrontierShell {} {
	global frontierQSWin
	
	if {[lsearch [winNames] $frontierQSWin] >= 0} {
		bringToFront $frontierQSWin
	} else {
		new -n $frontierQSWin -m Fron
		setWinInfo -w $frontierQSWin shell 1
		insertText "Welcome to Alpha's Frontier shell\r«» "
	}
}


proc frontierRunQuickScript {} {
	global frontierCommandHistory frontierCommandNum frontierQSWin
	set pos [getPos]

	set ind [string first "«» " [getText [lineStart $pos] [nextLineStart [getPos]]]]
	if {$ind >= 0} {
		set lStart [expr [lineStart $pos]+$ind+2]
		endOfLine
		set scriptName [getText $lStart [getPos]]
		if {[getPos] != [maxPos]} {
			goto [maxPos]
			insertText $scriptName
		}
		
		if {[string trim $scriptName] != ""} {
			catch {frontierDoScript $scriptName 0 0} result
			if {[string compare [lindex $frontierCommandHistory [expr [llength $frontierCommandHistory]-1]] $scriptName] != 0} {
				lappend frontierCommandHistory $scriptName
				if {[llength $frontierCommandHistory] > 30} {
					set frontierCommandHistory [lrange $frontierCommandHistory 1 end]
				}
			}
			set frontierCommandNum [llength $frontierCommandHistory]
		} else {
			set result ""
		}
		if {[string length $result]} {
			insertText -w $frontierQSWin "\r" $result \r "«» "
		} else {
			insertText -w $frontierQSWin \r "«» "
		}
	} else {
	   	if {[getPos] == [maxPos]} {
			insertText "«» "
		} else {
			bind::CarriageReturn
		}
	}
	return
}


proc frontierPrevCommand {} {
	global frontierCommandHistory frontierCommandNum
	
	set text [getText [lineStart [getPos]] [nextLineStart [getPos]]]
	if {[set ind [string first "«» " $text]] == 0} {
		goto [expr [lineStart [getPos]] + $ind + 2]
	} else return

	incr frontierCommandNum -1
	if {$frontierCommandNum < 0} {
		incr frontierCommandNum
		endOfLine
		return
	}
	set text [lindex $frontierCommandHistory $frontierCommandNum]
	set to [nextLineStart [getPos]]
	if {[lookAt [expr $to-1]] == "\r"} {incr to -1}
	replaceText [getPos] $to $text
}


proc frontierNextCommand {} {
	global frontierCommandHistory frontierCommandNum
	
	set text [getText [lineStart [getPos]] [nextLineStart [getPos]]]
	if {[set ind [string first "«» " $text]] == 0} {
		goto [expr [lineStart [getPos]] + $ind + 2]
	} else return

	incr frontierCommandNum
	if {$frontierCommandNum >= [llength $frontierCommandHistory]} {
		incr frontierCommandNum -1
		frontierCancelLine
		return
	}
	set text [lindex $frontierCommandHistory $frontierCommandNum]
	set to [nextLineStart [getPos]]
	if {[lookAt [expr $to-1]] == "\r"} {incr to -1}
	replaceText [getPos] $to $text
}

proc frontierCancelLine {} {
	global frontierCommandHistory frontierCommandNum

	set text [getText [lineStart [getPos]] [nextLineStart [getPos]]]
	if {[set ind [string first "«» " $text]] == 0} {
		goto [expr [lineStart [getPos]] + $ind + 3]
	} else return
	
	set to [nextLineStart [getPos]]
	deleteText [getPos] $to
	
	set frontierCommandNum [llength $frontierCommandHistory]
}

proc frontierBol {} {
	set text [getText [lineStart [getPos]] [nextLineStart [getPos]]]
	if {[set ind [string first "«» " $text]] == 0} {
		goto [expr [lineStart [getPos]] + $ind + 3]
	} else {
		goto [lineStart [getPos]]
	}
}

proc Fron::OptionTitlebar {} {
	global frontierCommandHistory
	return $frontierCommandHistory
}

proc Fron::OptionTitlebarSelect {item} {
	insertText [string range $item [expr 1+[string first " " $item]] end]
	if {[key::optionPressed]} {frontierRunQuickScript}
}

regModeKeywords -m {«} Fron {}
Bind up <z> frontierPrevCommand Fron
Bind down <z> frontierNextCommand Fron
Bind '\r' frontierRunQuickScript Fron
Bind 'u'  <z>  frontierCancelLine  Fron
Bind left <c> frontierBol Fron
Bind 'a' <z> frontierBol Fron

#===============================================================================
# Odb browser
# 
# Written by Danis Georgiadis <dmg@hyper.gr> and modified by me to be integrated 
# with the rest.
# 
#===============================================================================

set odbBrowserTabLength 3
set odbBrowserTypeOffset 60

proc odbget120Spaces {} {
	set spaces40 "                                        "
	return "$spaces40$spaces40$spaces40"
}

proc odbGetIndLevel {indStr} {
	global odbBrowserTabLength
	return [expr [string length $indStr] / $odbBrowserTabLength]
}

proc odbGetIndString {indLevel} {
	global odbBrowserTabLength
	return [string range [odbget120Spaces] 0 [expr [expr $indLevel * $odbBrowserTabLength] - 1]]
}

proc odbGetNextIndString {thisIndStr} {
	return [odbGetIndString [expr [odbGetIndLevel $thisIndStr] + 1]]
}

proc odbBrowseGetLineParts {name type addr level} {
	global odbBrowserTypeOffset
	global odbBrowserTabLength
	
	set indPadPart [odbGetIndString $level]
	set namePart [string trim $name "\t "]
	set typePadSize [expr $odbBrowserTypeOffset - [expr [string length $indPadPart] + [string length $name]]]
	set typePadPart [string range [odbget120Spaces] 0 [expr $typePadSize - 1]]
	set typePart "◊${type}◊"
	set addrPart "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t∞${addr}∞"
	
	set res ""
	lappend res $indPadPart $namePart $typePadPart $typePart $addrPart
	
	return $res
}

proc odbBrowseDown {} {
	set curPos [getPos]
	set curLineStart [lineStart $curPos]
	set curLineEnd [nextLineStart $curPos]
	selectText $curLineStart $curLineEnd
	
	set newLineStart [nextLineStart $curLineStart]
	set newLineEnd [nextLineStart $newLineStart]
	if {$newLineStart < [maxPos]} {
		selectText $newLineStart $newLineEnd
	}
}

proc odbBrowseCmdDown {{option 0}} {
	set curPos [getPos]
	set curLineStart [lineStart $curPos]
	set curLineEnd [nextLineStart $curPos]
	
	if {[regexp {^( *).+◊tabl◊\t+∞(.+)∞} [getText $curLineStart $curLineEnd] junk ind addr]} {
		if {[frontierDoScript "defined($addr)"] == "false"} {return}
		if {$option} {killWindow}
		odbBrowse $addr
	}
}

proc odbBrowseUp {} {
	set curPos [getPos]
	set curLineStart [lineStart $curPos]
	set curLineEnd [nextLineStart $curPos]
	selectText $curLineStart $curLineEnd
	
	set newLineStart [pos::prevLineStart $curLineStart]
	set newLineEnd [nextLineStart $newLineStart]
	if {$newLineEnd > 0} {
		selectText $newLineStart $newLineEnd
	}
}

proc odbBrowseCmdUp {{option 0}} {
	regexp {∞(.+)∞} [getText 0 [nextLineStart 0]] junk addr
	if {[set point [string last "." $addr]] >= 0} {
		if {[frontierDoScript "defined($addr)"] == "false"} {return}
		if {$option} {killWindow}
		odbBrowse [string range $addr 0 [expr $point - 1]]
	}
}

proc odbBrowserAddCells {pos cells indLevel} {
	
	set tmp ""
	set colorCodes ""
	set lastPos $pos
	
	foreach cell $cells {
		set cellName [lindex $cell 0]
		set cellType [lindex $cell 1]
		set cellAddr [lindex $cell 2]
		
		set parts [odbBrowseGetLineParts $cellName $cellType $cellAddr $indLevel]
		
		set indPart [lindex $parts 0]
		set namePart [lindex $parts 1]
		set typePartPad [lindex $parts 2]
		set typePart [lindex $parts 3]
		set addrPart [lindex $parts 4]
		
		set nameStart [expr $lastPos + [string length $indPart]]
		set nameEnd [expr $nameStart + [string length $namePart]]
		
		if {$cellType == "TEXT" || $cellType == "wptx"} {
			lappend colorCodes [concat $nameStart 3]
			lappend colorCodes [concat $nameEnd 0]
		} elseif {$cellType == "tabl"} {
			lappend colorCodes [concat $nameStart 5]
			lappend colorCodes [concat $nameEnd 0]
		} else {
			lappend colorCodes [concat $nameStart 1]
			lappend colorCodes [concat $nameEnd 0]
		}
		
		set typeStart [expr $lastPos + [string length $indPart] + [string length $namePart] + [string length $typePartPad]]
		set typeEnd [expr $typeStart + [string length $typePart]]
		lappend colorCodes [concat $typeStart 4]
		lappend colorCodes [concat $typeEnd 0]
		
		set line ""
		append line $indPart $namePart $typePartPad $typePart $addrPart "\n"
		append tmp $line
		
		set lastPos [expr $lastPos + [string length $line]]
	}
	
	selectText $pos $pos
	setWinInfo read-only 0
	
	insertText $tmp
	
	foreach colorCode $colorCodes {
		insertColorEscape [lindex $colorCode 0] [lindex $colorCode 1]
	}
	
	setWinInfo dirty 0
	setWinInfo read-only 1
	refresh
}

proc odbBrowseRight {} {
	set curPos [getPos]
	set curLineStart [lineStart $curPos]
	set curLineEnd [nextLineStart $curPos]
	
	if {[regexp {^( *).+◊tabl◊\t+∞(.+)∞} [getText $curLineStart $curLineEnd] junk ind addr]} {
		set nextIndString [odbGetNextIndString $ind]
		set nextLineText [getText [nextLineStart $curLineStart] [nextLineStart [nextLineStart $curLineStart]]]
		if {![regexp "^$nextIndString" $nextLineText junk]} {
			if {[frontierDoScript "defined($addr)"] == "false"} {return}			
			set cells [frontierDoAlphaScript "Alpha.getCellData(@$addr)"]
			odbBrowserAddCells $curLineEnd $cells [odbGetIndLevel $nextIndString]
			
		}
	}
	
	selectText $curLineStart $curLineEnd
}

proc odbBrowseLeft {} {
	set curPos [getPos]
	set curLineStart [lineStart $curPos]
	set curLineEnd [nextLineStart $curPos]
	
	if {[regexp {^( *).+∞(.+)∞} [getText $curLineStart $curLineEnd] junk ind elems]} {
		set pos [nextLineStart $curLineStart]
		set start $pos
		set nextIndString [odbGetNextIndString $ind]
		while {[regexp "^$nextIndString" [getText $pos [nextLineStart $pos]] junk]} {
			set pos [nextLineStart $pos]
		}
		setWinInfo read-only 0
		deleteText $start $pos
		setWinInfo dirty 0
		setWinInfo read-only 1
	}
	selectText $curLineStart $curLineEnd
}

proc odbBrowseEditObj {} {
	set curPos [getPos]
	set curLineStart [lineStart $curPos]
	set curLineEnd [nextLineStart $curPos]
	
	if {[regexp {^.+∞(.+)∞} [getText $curLineStart $curLineEnd] junk addr]} {
		frontierDoAlphaScript "Alpha.editCell(@$addr)"
	}
}

proc odbBrowse {{addr root}} {
	if {$addr == ""} {
		return
	}
	
	global odbBrowserTypeOffset
	global odbBrowserTabLength
	
	set cell [frontierDoAlphaScript "Alpha.getCellData(@$addr, false)"]
	set wtitle [lindex [lindex $cell 0] 2]
	regsub -all {[][]} $wtitle "" wtitle
	set wtitle "* Frontier “${wtitle}” *"
	
	if {[lsearch [winNames] $wtitle] >= 0} {
		bringToFront $wtitle
	} else {
		new -n $wtitle -g 4 42 449 300 -m Odb
		setWinInfo dirty 0
		odbBrowserAddCells 0 $cell 0
		selectText 0 [nextLineStart 0]
		odbBrowseRight
	}
}

Bind '\r'		odbBrowseEditObj	Odb
Bind enter		odbBrowseEditObj	Odb

Bind down 		odbBrowseDown		Odb
Bind down <c>	odbBrowseCmdDown	Odb
Bind down <co>	{odbBrowseCmdDown 1}	Odb
Bind up			odbBrowseUp			Odb
Bind up <c>		odbBrowseCmdUp		Odb
Bind up <co>	{odbBrowseCmdUp 1}		Odb
Bind right		odbBrowseRight		Odb
Bind left		odbBrowseLeft		Odb

if {![info exists frontierVersion] || $frontierVersion != 2.2} {
	dialog -w 400 -h 180 -t "Welcome to Frontier menu 2.2" 70 10 390 30 \
	  -t "Make sure you install all the scripts in the folder 'Frontier verbs' into Frontier.\r\
	  If you upgrade from a previous version make sure you install the Frontier verbs which have been updated.\r\
	  You find information in the file 'Frontier Help'." 10 50 390 135 \
	  -b OK 320 150 385 170
	catch {edit -r -c [help::pathToHelp "Frontier Help"]}
	prefs::add frontierVersion 2.2
	set frontierHasWarned 1
}


catch {frontierBuildScriptMenu}
unset -nocomplain frontierHasWarned
