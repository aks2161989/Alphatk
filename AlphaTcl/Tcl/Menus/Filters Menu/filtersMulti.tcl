## -*-Tcl-*- (nowrap)
## 
 # This file : filtersMulti.tcl
 # Created : 2002-10-12 15:39:37
 # Last modification : 2006-01-02 09:46:47
 # Author : Bernard Desgraupes
 # e-mail : <bdesgraupes@easyconnect.fr>
 # Web-page : <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
 # Description :
 #     This file is part of the FiltersMenu package. It contains the 
 #     procs concerning the multi-filters.
 # 
 # (c) Copyright : Bernard Desgraupes 2000-2006
 # This is free software. See licensing terms in the Filters Help file.
 ##

filtersMenuTcl

proc filtersMulti.tcl {} {}

namespace eval flt {}


proc flt::applyMultiProc {in} {
	global flt_p
	set flt_p(filtersleft) [llength $flt_p(multilist)]
	if {!$flt_p(filtersleft)} {
		alertnote "Multifilter is empty."
		return
	}
	switch $in {
		"Selection" {
			flt::applyMultiToSelection
		}
		"Window" {
			set flt_p(moveoffscreen) 1
			flt::applyMultiToWindow
		}
		"Fileset" {
			if {![flt::selectFileset]} {return}
			flt::applyMultiToBatch
		}
		"Folder" {
			if {![flt::selectFolder]} {return}
			flt::applyMultiToBatch
		}
	}
	set flt_p(firstapplied) 0
}


proc flt::applyMultiToSelection {} {
	global flt_p filtersMenumodeVars 
	set flt_p(selstart) [getPos]
	set flt_p(selend) [selEnd]
	if {$flt_p(selstart) == $flt_p(selend)} {
		alertnote "No region selected."
		return
	}
	if {$filtersMenumodeVars(maxBeforeScrap) > [pos::diff $flt_p(selstart) $flt_p(selend)]} {
		flt::applyMultiInSelection
	} else {
		set flt_p(moveoffscreen) 0
		selectText $flt_p(selstart) $flt_p(selend)
		set flt_p(thesel) [getSelect]
		deleteSelection
		flt::getScrapWindow
		foreach filt $flt_p(multilist) {
			incr flt_p(filtersleft) -1
			set flt_p(appliedfilter) $filt
			if {![flt::getFilterData]} {continue}
			flt::filterCore
		}
		flt::returnFromScrap
		set flt_p(selend) [pos::math $flt_p(selstart) + [string length $flt_p(thesel)]]
		goto $flt_p(selend)
	}
}


proc flt::applyMultiInSelection {} {
	global flt_p
	foreach filt $flt_p(multilist) {
		incr flt_p(filtersleft) -1
		set flt_p(appliedfilter) $filt
		flt::filterInSelection
	}
	goto $flt_p(selend)
}


proc flt::applyMultiToWindow {} {
	global flt_p
	foreach filt $flt_p(multilist) {
		incr flt_p(filtersleft) -1
		set flt_p(appliedfilter) $filt
		flt::applyToWindow
	}
}


proc flt::applyMultiToBatch {} {
	global flt_p flt_matches filtersMenumodeVars
	watchCursor
	if {![flt::acceptNotUndoable]} {return}
	# Check that there are no dirty windows before scanning
	if {[flt::cancelIfDirty]} {return}
	incr flt_p(firstapplied)
	# Scan the files to mark those containing a match :
	set flt_p(cid) [scancontext create]
	flt::buildMultiScanMatches
	flt::scanFiles
	scancontext delete $flt_p(cid)
	# Now each filter will be applied only to those files for which there has been a match :
	set move 1
	foreach filt $flt_p(multilist) {
		incr flt_p(filtersleft) -1
		set flt_p(appliedfilter) $filt
		if {![flt::getFilterData]} {continue}
		flt::filterTheMatches $move
		set move 0
	}
	if {[info exists flt_matches]} {unset flt_matches}
}


proc flt::buildMultiScanMatches {} {
	global flt_p flt_matches
	# here all the filters instructions are gathered in one scan context :
	foreach filt $flt_p(multilist) {
		set flt_p(appliedfilter) $filt
		if {[flt::getFilterData]} {
			if {![flt::acceptFilterState]} {return}
			# one scanmatch command for each line in all the filters :
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
	}
}


# Multi filters utilities
# -----------------------

proc flt::showMultiFilter {} {
	global flt_p
	if {![llength $flt_p(multilist)]} {
		alertnote "Multifilter is empty."
		return
	}
	catch {set filt [listpick -p "List of filters in the current\
	  Multifilter. Confirm ?"  $flt_p(multilist)]} rep
	if {$rep == ""} {flt::buildMultiFilter}
}


proc flt::editMultiFilter {} {
	global flt_p
	if {![llength $flt_p(multilist)]} {
		alertnote "Multifilter is empty."
		return
	}
	foreach f $flt_p(multilist) {
		edit -c [flt::pathToFilter $f]
	}
}


proc flt::clearMultiFilter {} {
	global flt_p
	set flt_p(multilist) ""
}


proc flt::buildAMultiFilter {} {
	global flt_p
	flt::getFiltersList
	flt::buildMultiFilter
}


proc flt::buildMultiFilter {} {
	global flt_p
	set args ""
	lappend args [list -t "* Multi filter building window *" 97 8 400 28 \
	  -b OK 315 180 380 200 \
	  -b Cancel 225 180 295 200 \
	  -b Rebuild 135 180 205 200 \
	  -b Add 33 51 83 71 \
	  -t "Multi filter" 30 82 150 102 \
	  -e "$flt_p(multilist)" 30 105 380 165
	]
	set y 35
	eval lappend args [dialog::text "Filters " 105 y] \
	  [list [dialog::menu 105 y $flt_p(names) 0 150]]
	set flt_p(values) [eval dialog -w 390 -h 210 [join $args]]
	return [flt::getMultDialogValues]
}


proc flt::getMultDialogValues {} {
	global flt_p
	if {[lindex $flt_p(values) 1]} {return 0}
	if {[lindex $flt_p(values) 3]} {
		lappend flt_p(multilist) [lindex $flt_p(values) 5]
		flt::buildMultiFilter
		return 1
	}
	if {[lindex $flt_p(values) 2]} {
		flt::clearMultiFilter
		flt::buildMultiFilter
		return 1
	}
	set flt_p(multilist) [lindex $flt_p(values) 4]
	return 1	    
}

