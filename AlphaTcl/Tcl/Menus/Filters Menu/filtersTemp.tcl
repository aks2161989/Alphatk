## -*-Tcl-*- (nowrap)
## 
 # This file : filtersTemp.tcl
 # Created : 2002-10-12 15:39:37
 # Last modification : 2006-01-02 09:40:07
 # Author : Bernard Desgraupes
 # e-mail : <bdesgraupes@easyconnect.fr>
 # Web-page : <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
 # Description :
 #     This file is part of the FiltersMenu package. It contains the 
 #     procs concerning the temporary filter.
 # 
 # (c) Copyright : Bernard Desgraupes 2000-2006
 # This is free software. See licensing terms in the Filters Help file.
 ##

filtersMenuTcl

proc filtersTemp.tcl {} {}

namespace eval flt {}


proc flt::temporaryFilter {} {
	global flt_p filtersMenumodeVars  
	global tileLeft tileTop tileWidth errorHeight
	if {[flt::checkTempOpen]} {
		bringToFront $flt_p(tempname)
	} else {
		if {[file exists $flt_p(tempfile)]} {
			file delete $flt_p(tempfile)
		}
		# Recreate the file on disk
		set fid [alphaOpen $flt_p(tempfile) w+]
		fconfigure $fid -translation cr
		set t "!!\r!! In this window, you can create filtering instructions for a temporary use.\r"
		append t "!! To apply them to a window, bring the window to the foreground.\r"
		append t "!! Execute the filter using one of the \"Apply Temp To\" menu items.\r!!\r"
		if {$filtersMenumodeVars(showFilterSyntax)} {
			append txt $flt_p(syntax)
		}
		puts $fid $t
		close $fid
		# Display the window
		edit -c -w $flt_p(tempfile)
		goto [maxPos]
	}
}


proc flt::applyTempProc {in} {
    flt::applyFilterProc $in Temp
}


proc flt::checkTempOpen {} {
	global flt_p
	catch {lsearch -exact [winNames] $flt_p(tempname)} indx
	if {$indx > -1} {
		return 1
	} else {
		return 0
	}
}


proc flt::checkTempDirty {} {
	global flt_p
	getWinInfo -w $flt_p(tempname) arr
	set topwin [win::CurrentTail]
	if {$arr(dirty)} {
		switch [buttonAlert "Dirty Temporary Filter. Do you want to save it \
		  before filtering?" "Yes" "No" "Cancel" ] {
			"Yes" {
				bringToFront $flt_p(tempname)
				# Save the file on disk
				save $flt_p(tempfile)
				bringToFront $topwin
			}
			"No" {}
			"Cancel" {return 0}
		}
	}
	return 1
}


