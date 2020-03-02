## -*-Tcl-*- (nowrap)
## 
 # This file : filtersUtils.tcl
 # Created : 2002-11-21 09:32:48
 # Last modification : 2006-01-02 09:37:32
 # Author : Bernard Desgraupes
 # e-mail : <bdesgraupes@easyconnect.fr>
 # Web-page : <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
 # Description :
 #     This file is part of the FiltersMenu package. It contains utility 
 #     procs called by the core engine.
 # 
 # (c) Copyright : Bernard Desgraupes 2002-2006
 # This is free software. See licensing terms in the Filters Help file.
 ##

filtersMenuTcl

namespace eval flt {}


proc flt::selectFolder {} {
	global flt_p
	if {[catch {get_directory -p "Select a folder."} fltfolderpath] || $fltfolderpath == ""} {
		return 0
	} 
	set flt_p(scanfiles) ""
	if {$flt_p(filteringDepth)==-1} {
		flt::listFiles $fltfolderpath 1 1
	} else {
		flt::listFiles $fltfolderpath $flt_p(filteringDepth)
	}
	return [flt::foundFiles folder]
}


proc flt::selectFileset {} {
    global flt_p gfileSets currFileSet
    if {![package::active filesets]} {
	alert -t note -k "OK" -c "" -o "" "You must activate the Filesets package\
	  in order to use filesets."
	return 0
    } 
    if {$flt_p(currfileset) == ""} {
	set flt_p(currfileset) $currFileSet
    } 
    if {[catch {listpick -p "Which fileset to filter?" -L $flt_p(currfileset) \
      [lsort -dictionary [array names gfileSets]]} flt_p(currfileset)]} {
	set flt_p(currfileset) ""
	return 0
    } 
    set flt_p(scanfiles) ""
    # Filtering applies exclusively to TEXT files
    foreach f [getFileSet $flt_p(currfileset)] {
	if {[file exists $f]} {
	    if {[file::getType $f]=="TEXT"} {
		lappend flt_p(scanfiles) $f
	    } 
	} 
    } 
    return [flt::foundFiles fileset]
}


proc flt::foundFiles {in} {
	global flt_p 
	if {![llength $flt_p(scanfiles)]} {
		alertnote "No text files in this $in."
		return 0
	} else {
		return 1
	}
}


proc flt::acceptFilterState {} {
	global flt_p
	catch {lsearch -exact [winNames] "$flt_p(appliedfilter)$flt_p(ext)"} indx
	if {![expr {$indx > -1}]} {
		return 1
	} else {
		getWinInfo -w "$flt_p(appliedfilter)$flt_p(ext)" arr
		set mywindow [win::CurrentTail]
		if {$arr(dirty)} {
			switch [alert -t caution -k "Yes" -c "No" -o "Cancel" "Dirty filter\
			  \"$flt_p(appliedfilter)\".  Do you want to save it?"] {
			"yes" {
				bringToFront "$flt_p(appliedfilter)$flt_p(ext)"
				save
				bringToFront $mywindow
				return 1
			}
			"no" {return 1}
			"cancel" {return 0}
			}
		} else {
			return 1
		}
	}
}


proc flt::cancelIfDirty {} {
	global win::NumDirty
	if {${win::NumDirty}} {
		switch [alert -t caution -k "Yes" -c "No" -o "Cancel" "Save all windows?"\
		  "Files are scanned on disk: make sure your filters are saved."] {
			"Yes" {saveAll}
			"No" {}
			"Cancel" {return 1}
		}
	} 
	return 0
}


proc flt::filterToItself {} {
	global flt_p
	set tail [file tail [win::Current]]
	if {[file rootname $tail] eq $flt_p(appliedfilter) \
	  && [expr {[file ext $tail] eq $flt_p(ext) || \
	  $flt_p(appliedfilter) eq $flt_p(tempfilter)}]} {
		switch [buttonalert "Do you really want to apply $flt_p(appliedfilter)\
		  to itself ?" "no" "yes" ] {
			"yes" {return 0}
			"no" {return 1}
		}
	} else {
		return 0
	}
}    


proc flt::readyToFilter {} {
	return [expr {[flt::acceptFilterState] \
			   && ![flt::filterToItself] \
			   && [flt::getFilterData]} ]
}


proc flt::acceptNotUndoable {} {
	global flt_p filtersMenumodeVars
	if {$filtersMenumodeVars(warnNotUndoable) && !$flt_p(firstapplied)} {
		switch [buttonAlert "This is not undoable. Still want to apply the filter ?"\
		  "Apply" "No" ] {
			"Apply" {return 1}
			"No" {return 0}
		}
	}
	return 1
}


proc flt::filteringDepth {} {
	global flt_p
	if {[catch {prompt "Subfolders filtering depth\r(-1 means unlimited)" \
	  $flt_p(filteringDepth)} res]} {return} 
	set flt_p(filteringDepth) $res
}    


proc flt::listFiles {dir depth {unlimited 0}} {
	global flt_p
	status::msg "Building files list..."
	set tmplist [glob -nocomplain -dir [file join $dir] *]   
	foreach f $tmplist {
		set dp $depth
		if {![file isdirectory $f]} {
			if {[file::getType $f]=="TEXT"} {
				lappend flt_p(scanfiles) $f
			} 
		} elseif {[file isdirectory $f] && [expr $depth > 0]} {
			if {!$unlimited} {incr dp -1} 
			flt::listFiles $f $dp $unlimited
		}
	}
}    

