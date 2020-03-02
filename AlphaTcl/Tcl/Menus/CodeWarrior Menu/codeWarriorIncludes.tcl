# -*-Tcl-*- (nowrap) (tabsize:4)
# 
# File: codeWarriorIncludes.tcl
# 							Last modification : 2005-03-26 19:05:29
# 
# Description : this file is part of the CodeWarrior Menu for Alpha.
# It contains the procedures related to 
# These routines implement an includes list for CodeWarrior when you 
# option-click in the title bar. 

namespace eval cw {}



# -----------------------------------------------------------------
# Includes
# -----------------------------------------------------------------
# This proc returns a list of related files: the 'relation' argument can be
# either PRER (prerequisites) or DPND (dependents).

proc cw::relatedFiles {name {reltype PRER}} {
	global cw_params 
	watchCursor
	if {![cw::isInProject $name 0]} {
		error "$cw_params(cwstate)"
	} 
	if {$reltype eq "PRER"} {
		set relname "prerequisites"
	} elseif {$reltype eq "DPND"} {
		set relname "dependents"
	} else {
		error "Unknown type $reltype"
	}
	
	status::msg "Building list of $relname. Please wait..."
	cw::currentTarget
	set targetobj [tclAE::build::nameObject TRGT [tclAE::build::TEXT $cw_params(currTarget)] \
	  [tclAE::build::indexObject PRJD 1]]
	set scrfList [cw::propertyList Path $targetobj "source files"]
	if {![string length $scrfList]} {
		error "No target files"
	} 
	set fileidx [cw::findFileIndex $scrfList $name]
	
	if {$fileidx} {
		set result ""
		set fileobj [tclAE::build::indexObject SRCF $fileidx $targetobj]
		set desc [tclAE::send -t 500000 -r $cw_params(cwsig) core getd \
		  ---- [tclAE::build::propertyObject $reltype $fileobj]]
		
		if {![catch {tclAE::getKeyDesc $desc ----} theobj]} {
			# CW returns a list of objects by ID (like "seld:16777790")
			set count [tclAE::countItems $theobj]
			if {$count == 0} {
				error "Couldn't find any $relname"
			}
			# Let's get a list of all IDs and search therein (it is faster 
			# than asking the path for each ID because it implies one 
			# single AE rather than $count events).
			set IDList [cw::propertyList ID $targetobj "file IDs"]
			for {set i 0} {$i < $count} {incr i} {
				set fid [tclAE::getKeyData [tclAE::getNthDesc $theobj $i] seld]
				set idx [lsearch $IDList $fid]
				set path [lindex $scrfList $idx]
				regsub -all : [file::unixPathToFinder $path] / path
				lappend result $path
			}
			return [lsort -dictionary $result]
		} else {
			error "Couldn't extract $relname"
		}
	} else {
		error "File not found in current project"
	}
}


proc cw::filePrerequisites {} {
	set ret ""
	status::msg ""
	if {[catch {cw::relatedFiles [win::StripCount [win::Current]] PRER} ret]} {
		alertnote $ret
	} else {
		if {[llength $ret]} {
			new -n "[file tail [win::Current]] Prerequisites" -text [join $ret "\r"]
		} 
	}
}


proc cw::fileDependents {} {
	set ret ""
	status::msg ""
	if {[catch {cw::relatedFiles [win::StripCount [win::Current]] DPND} ret]} {
		alertnote $ret
	} else {
		if {[llength $ret]} {
			new -n "[file tail [win::Current]] Dependents" -text [join $ret "\r"]
		} 
	}
}


# This proc attempts to edit the header file corresponding to a particular
# source file and vice-versa. It relies on the file::sourceHeaderToggle proc 
# from modeSearchpath.tcl to take advantage of the user defined headers folders.
proc cw::toggleHeader&Source {} {
	file::sourceHeaderToggle
}
