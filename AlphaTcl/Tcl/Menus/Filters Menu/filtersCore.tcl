## -*-Tcl-*- (nowrap)
## 
 # This file : filtersCore.tcl
 # Created : 2002-10-12 15:39:37
 # Last modification : 2006-01-02 09:46:12
 # Author : Bernard Desgraupes
 # e-mail : <bdesgraupes@easyconnect.fr>
 # Web-page : <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
 # Description :
 #     This file is part of the FiltersMenu package. It contains the core
 #     filtering procs.
 # 
 # (c) Copyright : Bernard Desgraupes 2000-2006
 # This is free software. See licensing terms in the Filters Help file.
 ##

# Force filtersMenu.tcl loading to have all variables set in case some proc is 
# called while the menu is not global 
filtersMenuTcl

proc filtersCore.tcl {} {}

namespace eval flt {}


proc flt::applyFilterProc {in {temp ""}} {
	global flt_p
	set flt_p(filtersleft) 0
	if {$temp=="Temp"} {
		if {![flt::checkTempOpen]} {
			alertnote "No temporary Filter."
			return
		}
		if {![flt::checkTempDirty]} {return} 
		set flt_p(appliedfilter) $flt_p(tempname)
	} else {
		if {![flt::isFilterSelected]} {return}
		set flt_p(appliedfilter) $flt_p(currentname)
	}
	switch $in {
		"Selection" {
			flt::applyToSelection
		}
		"Window" {
			set flt_p(moveoffscreen) 1
			flt::applyToWindow
		}
		"Fileset" {
			if {![flt::selectFileset]} {return}
			flt::applyToBatch
		}
		"Folder" {
			if {![flt::selectFolder]} {return}
			flt::applyToBatch
		}
	}
	set flt_p(firstapplied) 0
}


proc flt::applyToSelection {} {
	global flt_p filtersMenumodeVars 
	set flt_p(selstart) [getPos]
	set flt_p(selend) [selEnd]
	if {[pos::compare $flt_p(selstart) == $flt_p(selend)]} {
		alertnote "No region selected."
		return
	}
	if {[expr {$filtersMenumodeVars(maxBeforeScrap) > [pos::diff $flt_p(selstart) $flt_p(selend)]}]} {
		flt::filterInSelection
		goto $flt_p(selend)
	} else {
		selectText $flt_p(selstart) $flt_p(selend)
		set flt_p(thesel) [getSelect]
		flt::filterOnScrap
		set flt_p(selend) [pos::math $flt_p(selstart) + [string length $flt_p(thesel)]]
		goto $flt_p(selend)
	}
	status::msg "Filtering done."
}


proc flt::filterOnScrap {} {
	global flt_p   
	if {![flt::readyToFilter]} {return}
	deleteSelection
	flt::getScrapWindow
	set flt_p(moveoffscreen) 0
	flt::filterCore
	flt::returnFromScrap
}


proc flt::getScrapWindow {} {
	global flt_p
	set flt_p(currwindow) [win::CurrentTail]
	catch {lsearch -exact [winNames] "$flt_p(scrapwin)"} indx
	if {![expr {$indx > -1}]} {
		new -n $flt_p(scrapwin) -g 4 50 20 20
		moveWin $flt_p(scrapwin) 10000 10000
	} else {
		bringToFront $flt_p(scrapwin)
	}
	insertText $flt_p(thesel)
}


proc flt::returnFromScrap {} {
	global flt_p
	selectText [minPos] [maxPos]
	set flt_p(thesel) [getSelect]
	setWinInfo -w $flt_p(scrapwin) dirty 0
	killWindow
	bringToFront $flt_p(currwindow)
	insertText $flt_p(thesel)    
}


proc flt::filterInSelection {} {
	global flt_p
	if {![flt::readyToFilter]} {return}
	foreach line $flt_p(filterlines) {
		set flt_p(line) $line
		if { $flt_p(line) != "" && ![regexp {^!!} $flt_p(line)]} {
			flt::parseLine
			flt::prepareReplaceString
			flt::substitute
		}
	}
}


proc flt::applyToWindow {} {
	global flt_p filtersMenumodeVars
	if {![flt::readyToFilter]} {return}
	if {![flt::acceptNotUndoable]} {return}
	incr flt_p(firstapplied)
	flt::filterCore
	status::msg "Filtering done."
}


proc flt::applyToBatch {} {
	global flt_p flt_matches 
	if {![flt::acceptFilterState]} {return}
	if {![flt::acceptNotUndoable]} {return}
	if {![flt::getFilterData]} {return}
	# Check that there are no dirty windows since scanning is done on the disk
	if {[flt::cancelIfDirty]} {return}
	incr flt_p(firstapplied)
	# Scan the files to mark those containing a match :
	set flt_p(cid) [scancontext create]
	flt::buildScanMatches
	flt::scanFiles
	scancontext delete $flt_p(cid)
	# Now the filter will be applied only to those files for which there has been a match :
	flt::filterTheMatches
	if {[info exists flt_matches]} {unset flt_matches}
	status::msg "Filtering done."
}


proc flt::buildScanMatches {} {
	global flt_p flt_matches 
	# one scanmatch command for each line in the filter :
	foreach line $flt_p(filterlines) {
		set flt_p(line) $line
		if { $flt_p(line) != "" && ![regexp {^!!} $flt_p(line) ]} {
			flt::parseLine
			if {$flt_p(grep) == 0} {
				set flt_p(searchstr) [quote::Regfind $flt_p(searchstr)]
			}
			if {$flt_p(nocase)} {
				scanmatch -nocase $flt_p(cid) $flt_p(searchstr) {set flt_matches($f) 1}
			} else {
				scanmatch $flt_p(cid) $flt_p(searchstr) {set flt_matches($f) 1}
			}
		}
	}
}


proc flt::scanFiles {} {
	global flt_p flt_matches 
	# Scan all the files looking for matches :
	foreach f $flt_p(scanfiles) {
		if {![catch {set fid [alphaOpen $f]}]} {
			status::msg "Looking at '[file tail $f]'"
			scanfile $flt_p(cid) $fid
			close $fid
		}
	} 
}


# The 'move' argument tells if the windows have to be moved off screen. When 
# multiple filters are applied to multiple windows, we want to move the 
# windows off screen only the first time.
proc flt::filterTheMatches { {move 1} } {
	global flt_p flt_matches
	foreach f [lsort [array names flt_matches]] {
		if {[file exists "$f"]} {
			set ftail [file tail $f]
			catch {lsearch -exact [winNames] $ftail} indx
			if {[expr {$indx > -1}]} {
				bringToFront $ftail
			} else {
				edit -c -w "$f"
			}
			if {![flt::filterToItself]} {		
				status::msg "Applying \"$flt_p(appliedfilter)\" filter to $ftail..."
				set flt_p(moveoffscreen) $move
				flt::filterCore
			}
		} else {
			alertnote "I can't edit '$f'"
		}
	}
}


proc flt::readLinesFromFilter {filter} {
	global flt_p 
	set fileId [alphaOpen [flt::pathToFilter $filter]] 
	catch {read $fileId} textflt
	close $fileId
	return [split $textflt "\n"]
}


proc flt::getFilterData {} {
	global flt_p 
	set flt_p(filterlines) [flt::readLinesFromFilter $flt_p(appliedfilter)]
	set flt_p(includedepth) 0
	# Are there included filters ?
	while {[flt::lookForIncludes]} {
		incr flt_p(includedepth)
		if {[catch {flt::insertIncludes $flt_p(includedepth)} res]} {
			alertnote $res
			return 0
		} 
	}
	if {$flt_p(debug)} {
		new -n ResultingFilter -info [join $flt_p(filterlines) "\r"]
		return 0
	} 
	return [llength $flt_p(filterlines)]
}


proc flt::lookForIncludes {} {
	global flt_p 
	if {[lsearch -regexp $flt_p(filterlines) $flt_p(includeregex)]!="-1"} {
		return 1
	} 
	return 0
}


proc flt::insertIncludes {depth} {
	global flt_p filtersMenumodeVars
	set indexes ""
	set filterslist ""
	if {$flt_p(includedepth) <= $filtersMenumodeVars(maxIncludeDepth)} {
		while {[set idx [lsearch -regexp $flt_p(filterlines) $flt_p(includeregex)]]!="-1"} {
			lappend indexes $idx
			regexp $flt_p(includeregex) [lindex $flt_p(filterlines) $idx] dum incl fltname
			set fltname [file root [string trimright $fltname " \t"]]
			# The Temporary Folder can be written in an include instruction
			# without asterisks or whitespace
			if {$fltname eq $flt_p(tempname) || [regexp "Temporary *Filter" $fltname]} {
				if {![flt::checkTempOpen]} {
					error "$fltname is called as included filter from level\
					  [expr $flt_p(includedepth) - 1] but no temporary filter is\
					  currently opened."
				} 
				# Check whether the Temporary Filter has been saved 
				# otherwise it might not even exist on disk
				if {![flt::checkTempDirty]} {continue} 
			}
			if {![flt::filterExists $fltname]} {
				error "Can't find filter '$fltname' included \
				  from level [expr $flt_p(includedepth) - 1]."
			} 
			lappend filterslist $fltname
			set flt_p(filterlines) [lreplace $flt_p(filterlines) $idx $idx]
		}
		foreach id [lreverse $indexes] flt [lreverse $filterslist] {
			set flt_p(filterlines) [concat \
			  [lrange  $flt_p(filterlines) 0 [expr {$id - 1}]] \
			  [flt::readLinesFromFilter $flt] \
			  [lrange  $flt_p(filterlines) $id end]]
		} 
	} else {
		# If the level of inclusion is deeper than 
		# maxIncludeDepth, ignore the include's.
		while {[set idx [lsearch -regexp $flt_p(filterlines) $flt_p(includeregex)]]!="-1"} {
			set flt_p(filterlines) [lreplace $flt_p(filterlines) $idx $idx]
		}
	}
}


proc flt::parseLine {} {
	global flt_p
	set prov [split $flt_p(line) "\t"]
	if {[llength $prov] == 1} {
		# If only one arg on the line, empty replacement string
		# and default options
		set flt_p(lineoptions) ""
	} elseif {[llength $prov] == 3} {
		# Now handle the case when there are exactly three tab-separated
		# elements, since we replace below multiple tabs by a single one :
		# otherwise, an empty second arg would be lost.
		set flt_p(lineoptions) [lindex $prov 2]
	} else {
		# Replace multiple tabs by a single one before splitting.
		regsub -all "\t+" $flt_p(line) "\t" flt_p(line)
		set prov [split $flt_p(line) "\t"]
		if {[expr {[llength $prov] > 2}]} {
			set flt_p(lineoptions) [lindex $prov 2]
		} else {
			set flt_p(lineoptions) ""
		}
	}
	set flt_p(searchstr) [lindex $prov 0]
	set flt_p(replstr) [lindex $prov 1]
	set flt_p(grep) [regexp "1" $flt_p(lineoptions)] 
	set flt_p(nocase) [regexp "i" $flt_p(lineoptions)]
	set flt_p(matchword) [regexp "m" $flt_p(lineoptions)]
	set flt_p(line) $prov
}    


proc flt::filterCore {} {
	global flt_p
	# Move window out of the screen
	if {$flt_p(moveoffscreen)} {
		lappend flt_p(currwinpos) [list [win::Current] [getGeometry [win::Current]]]
		moveWin [win::Current] 10000 10000
		set flt_p(moveoffscreen) 0
	} 
	foreach line $flt_p(filterlines) {
		set flt_p(line) $line
		if { $flt_p(line) != "" && ![regexp {^!!} $flt_p(line) ]} {
			flt::parseLine
			flt::prepareReplaceString
			flt::substituteAll
		}
	}
	# Move windows back to their initial position
	if {!$flt_p(filtersleft) && [llength $flt_p(currwinpos)]} {
		set wp [lindex $flt_p(currwinpos) 0] 
		eval moveWin [list [lindex $wp 0] [lindex [lindex $wp 1] 0] [lindex [lindex $wp 1] 1]]
		set flt_p(currwinpos) [lreplace $flt_p(currwinpos) 0 0]
	} 
}


# We do this so that the \r, \n and \t sequences are treated as expected.
proc flt::prepareReplaceString {} {
	global flt_p
	if {$flt_p(grep)} {
		regsub -all {\\\\}  $flt_p(replstr) {þü}   flt_p(replstr)
		regsub -all {\\}    $flt_p(replstr) {\\\\} flt_p(replstr)
		regsub -all {\\\\r} $flt_p(replstr) "\r"   flt_p(replstr)
		regsub -all {\\\\n} $flt_p(replstr) "\n"   flt_p(replstr)
		regsub -all {\\\\t} $flt_p(replstr) "\t"   flt_p(replstr)
		regsub -all {\\\\}  $flt_p(replstr) {\\}   flt_p(replstr)
		regsub -all {þü}    $flt_p(replstr) {\\\\} flt_p(replstr)
	} 
}


proc flt::substitute {} {
	global flt_p
	if {$flt_p(searchstr) == ""} {return}
	set start $flt_p(selstart)
	set end $flt_p(selend)
	while {![catch {performSearch -f 1 -r $flt_p(grep) -m $flt_p(matchword) \
	  -i $flt_p(nocase) -l $end $flt_p(searchstr) $start} res]} {
		replaceString $flt_p(replstr)
		set end [pos::math $end - [pos::diff [getPos] [selEnd]]]
		set start [getPos]
		replace
		set end [pos::math $end + [expr {abs([pos::diff [getPos] $start])}]]
		set start [getPos]
	}
	set flt_p(selend) $end
}


# Makes use of the recent -p (linestop) and -w (lineanchor) flags introduced 
# in supersearch::performSearch to make sure that ^ and $ in regexps are handled 
# correctly. Both of them are set to 1.
proc flt::substituteAll {} {
	global flt_p
	if {$flt_p(searchstr) == ""} {return}
	flt::setSupersearchFlags on
	catch {
		replaceString $flt_p(replstr)
		if {![catch {performSearch -f 1 -r $flt_p(grep) -m $flt_p(matchword) \
		  -i $flt_p(nocase) -linestop 1 -lineanchor 1 -- $flt_p(searchstr) [minPos]}]} {
			replaceAll
		} 
	}
	flt::setSupersearchFlags off
}


proc flt::setSupersearchFlags {toggle} {
	global supersearch flt_p
	if {$flt_p(grep)} {
		switch $toggle {
			"on" {
				set flt_p(savelineanchor) $supersearch(lineanchor)
				set flt_p(savelinestop) $supersearch(linestop)
			}
			"off" {
				set supersearch(lineanchor) $flt_p(savelineanchor)
				set supersearch(linestop) $flt_p(savelinestop)
			}
		}
	} 
}
	
