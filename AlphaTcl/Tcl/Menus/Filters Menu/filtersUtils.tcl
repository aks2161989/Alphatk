## -*-Tcl-*- (nowrap) (tabsize:4)
## 
 # This file : filtersUtils.tcl
 # Created : 2002-10-12 15:39:37
 # Last modification : 2006-01-02 09:37:00
 # Author : Bernard Desgraupes
 # e-mail : <bdesgraupes@easyconnect.fr>
 # Web-page : <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
 # Description :
 #     This file is part of the FiltersMenu package. It contains utility procs.
 # 
 # (c) Copyright : Bernard Desgraupes 2000-2006
 # This is free software. See licensing terms in the Filters Help file.
 ##

filtersMenuTcl

proc filtersUtils.tcl {} {}

namespace eval flt {}


proc flt::displaySyntax {} {
	global flt_p
	global tileLeft tileTop tileWidth errorHeight
	catch {lsearch -exact [winNames] $flt_p(syntaxwin)} indx
	if {$indx > -1} {
		bringToFront $flt_p(syntaxwin)
	} else {
		new -g $tileLeft $tileTop $tileWidth [expr int($errorHeight * 2)] \
		  -n "$flt_p(syntaxwin)" -info $flt_p(syntax)
		flt::colorUsage
	}
}


proc flt::colorUsage {} {
	global flt_p
	if {![catch {search -s -r 0 $flt_p(usage) [minPos]} res]} {
		eval text::color $res 1
	} 
	set start [minPos]
	while {![catch {search -f 1 -s -r 1 "!!( |\t)+(0|1|i|m) " $start} res]} {
		text::color [pos::math [lindex $res 1]-2] [lindex $res 1] 1
		set start [lindex $res 1]
	}
	refresh
}


proc flt::currentFilter {} {
	global flt_p
	if {$flt_p(currentname) == ""} {
		set mess "No filter currently selected.\r"
	} else {
		set mess "Current Filter is: $flt_p(currentname).\r"
	}
	if {![llength $flt_p(multilist)]} {
		append mess "MultiFilter empty."
	} else {
		append mess "MultiFilter contains: $flt_p(multilist)"
	}
	alertnote $mess
}


# Check the syntax of an edited filter.
proc flt::checkSyntax {} {
	global flt_p filtersMenumodeVars
	global tileLeft tileTop tileWidth tileHeight
	set flt_p(errorinfo) ""
	# First verify that the front window is a filter
	set winName [win::CurrentTail]
	if { [file extension $winName] != $flt_p(ext) && [file rootname $winName] != $flt_p(tempfilter)} {
		alertnote "Current window is not a filter. It must have an \"$flt_p(ext)\" extension."
		return
	}
	# Read the contents of the filter's window
	set flt_p(filterlines) [getText [minPos] [maxPos]]
	set flt_p(filterlines) [split $flt_p(filterlines) "\r\n"]
	if {![llength $flt_p(filterlines)]} {return}
	# Parse each line
	set flt_p(lignenum) 0
	set flt_p(errnum) 0
	set countIncl 0
	set includes {}
	foreach line $flt_p(filterlines) {
		set flt_p(line) $line
		incr flt_p(lignenum)
		if { $flt_p(line) != "" && ![regexp {^!!} $flt_p(line)]} {
			# Splitting the flt_p(line)
			flt::parseLine
			# 	No more than three args on a line :
			if {[expr {[llength $flt_p(line)] > 3}]} {
				flt::errRecord "Too many args ([llength $flt_p(line)]) on line \#$flt_p(lignenum).\n\n"
			}
			if [flt::stopChecking] break
			# First arg (searchString) must not be empty :
			if {$flt_p(searchstr) == ""} {
				flt::errRecord "First argument is empty on line \#$flt_p(lignenum).\n\n"
			}
			if [flt::stopChecking] break
			# The line options must contain only a combination of 0, 1, i, m
			if {![regexp "^\[01im\]*$" $flt_p(lineoptions)]} {
				flt::errRecord "Wrong third arg on line \#$flt_p(lignenum) : \
				  $flt_p(lineoptions).\nIt should be a combination of 0, 1, i and m or empty.\n\n"
			} 
			if [flt::stopChecking] break
			# Options 0 and 1 are mutually exclusive
			if {[regexp 0 $flt_p(lineoptions)] && [regexp 1 $flt_p(lineoptions)]} {
				flt::errRecord "Mutually exclusive options 0 and 1 on line \#$flt_p(lignenum) : \
				  $flt_p(lineoptions).\n\n"
			} 
			if [flt::stopChecking] break
			if {$flt_p(grep) == 1} {
				# Check the patterns validity (borrowed from search.tcl)
				if {[catch {regexp -- $flt_p(searchstr) {} dmy} dmy]} {
					flt::errRecord "Syntax error in pattern \"$flt_p(searchstr)\" \
					  for searchString on line \#$flt_p(lignenum) -\n$dmy\n\n"
				}
				if [flt::stopChecking] break
				if {[catch {regsub -- $flt_p(searchstr) {} $flt_p(replstr) dmy} dmy]} {
					flt::errRecord "Syntax error in pattern \"$flt_p(replstr)\" \
					  for replaceString on line \#$flt_p(lignenum) -\n$dmy\n\n"
				} 
				if [flt::stopChecking] break
			}	
		} elseif {[regexp $flt_p(includeregex) $flt_p(line) dum incl fltname]} {
			incr countIncl
			lappend includes $fltname
		}
	}
	if {[expr {$flt_p(errnum) > 0}]} {
		set errmess "\n\n*** That makes $flt_p(errnum) errors. ***\n"
		if {[expr {$flt_p(errnum) > $filtersMenumodeVars(maxNumbErr) - 1}]} {
			append errmess "Maximum number of errors is $filtersMenumodeVars(maxNumbErr) "
			append errmess "(see the Filters Menu prefs).\n"
			append errmess "Syntax checking aborted.\n\nUsage :\n$flt_p(syntax)"
		}
		append flt_p(errorinfo) $errmess
	} else {
		append flt_p(errorinfo) "*** Syntax OK ***"
	}
	if {$countIncl} {
		set includes [lunique $includes]
		set countIncl [llength $includes]
		append flt_p(errorinfo) "Warning: the current filter has $countIncl included filter(s).\n"
		append flt_p(errorinfo) "Syntax checking is not recursive: you should also check the syntax for every included filter.\n"
	} 
	set top [expr {$tileTop + $tileHeight - 160}]
	new -n $flt_p(checkwin) -g [expr {$tileLeft + 10}] $top [expr {$tileWidth - 20}] 160
	insertText $flt_p(errorinfo)
	flt::colorUsage
}


proc flt::errRecord {arg} {
	global flt_p
	append flt_p(errorinfo) $arg
	incr flt_p(errnum)
}


proc flt::stopChecking {} {
	global flt_p filtersMenumodeVars  
	return [expr {$flt_p(errnum) > $filtersMenumodeVars(maxNumbErr) - 1}]
}


proc flt::doFilterAction {action} {
	global flt_p
	flt::getFiltersList
	if {[llength $flt_p(names)] == 0} {
		alertnote "No filters were found. Weird."
		return
	} else {
		if {![catch {listpick -L [list $flt_p(currentname)] -p "Filter to ${action}:" $flt_p(names)} filtername]} {
			set filterfile [flt::pathToFilter $filtername]
			if {$filterfile ne ""} {
				switch -- $action {
					"edit" {
						edit -c $filterfile
						set flt_p(currentname) $filtername
						menu::buildSome filtersMenu
						win::ChangeMode Fltr
					}
					"delete" {
						switch [buttonAlert "OK to delete filter \"$filtername\" ?" "no" "yes" ] {
							"yes" {
								file delete $filterfile
								status::msg "Filter $filtername deleted."
								if {$flt_p(currentname) == $filtername} {
									set flt_p(currentname) ""
									menu::buildSome filtersMenu
								}
							}
							"cancel" {return}
						}
					}
				}
			} else {
				alertnote "I can't find the '$filtername$flt_p(ext)' file"
				return
			}
		} 
	}
}


proc flt::editCurrentFilter {} {
	global flt_p
	if {$flt_p(currentname) == ""} {
		alertnote "No filter currently selected."
		return
	}
	set f [flt::pathToFilter $flt_p(currentname)]
	if {[file exists $f]} {
		edit -c $f
	} else {
		alertnote "I can't find the '$filtername$flt_p(ext)' file"
	}
}


proc flt::filtersBindings {} {
    global tileLeft tileTop tileWidth errorHeight
    new -g $tileLeft $tileTop [expr int($tileWidth*.5)] [expr int($errorHeight *2.6)] \
      -n "* Filters Bindings *" -info [flt::bindingsInfoString]
    if {![catch {search -f 1 -all -s -r 1 -i 1 {('|<)[a-z=-]+('|>)} 0} res]} {
	foreach {beg end} $res {
	    text::color $beg $end 1
	}
    }
    text::color [minPos] [nextLineStart [minPos]] 5
    refresh
}


proc flt::bindingsInfoString {} {
    global tileLeft tileTop tileWidth errorHeight
    set mess "KEY BINDINGS AVAILABLE FOR THE FILTERS MENU\n\n"
    append mess "Press 'ctrl-f', release, then hit one of the following keys:\n"
    append mess "  'b'  to show the <b>indings\n"
    append mess "  'c'  to <c>heck the filter's syntax\n"
    append mess "  'd'  to apply filter to a fol<d>er (or <d>irectory)\n"
    append mess "  'e'  to <e>dit a filter\n"
    append mess "  'f'  to apply filter to a <f>ileset\n"
    append mess "  'm'  to build a <m>ultifilter\n"
    append mess "  'n'  to create a <n>ew filter\n"
    append mess "  'p'  to <p>ick a filter\n"
    append mess "  's'  to apply filter to a <s>election\n"
    append mess "  't'  to call up the <t>emporary filter\n"
    append mess "  'w'  to apply filter to the current <w>indow\n"
    append mess "  'opt-e'    to <e>dit the current filter\n"
    append mess "  'shift-d'  to apply multifilter to a fol<d>er (or <d>irectory)\n"
    append mess "  'shift-e'  to <e>dit a multifilter\n"
    append mess "  'shift-f'  to apply multifilter to a <f>ileset\n"
    append mess "  'shift-s'  to apply multifilter to the <s>election\n"
    append mess "  'shift-w'  to apply multifilter to the current <w>indow\n"
    append mess "\nPress 'ctrl-t', release, then hit one of the following keys:\n"
    append mess "  'd'  to apply temporary filter to a fol<d>er\n"
    append mess "  'f'  to apply temporary filter to a <f>ileset\n"
    append mess "  's'  to apply temporary filter to a <s>election\n"
    append mess "  'w'  to apply temporary filter to the current <w>indow\n"
    return $mess
}


# # # Exporting procs # # #
# Here we define two procs to export the filtering capacity in other scripts.
# Introduced in version 1.4.
# Just say "alpha::package require filtersMenu 1.4" at the beginning of your script
# and then use one of the following commands
#     flt::filterThisFile $filtername $filename
#     flt::filterThisSelection $filtername $selection
# If filename is not specified then flt::filterThisFile applies to the current window.
# If filename is specified, it should be either the name of a window or the pathname 
# of a file on disk.
proc flt::filterThisFile {filtername {filename ""}} {
	global flt_p
	if {$filename == ""} {
		if {![llength [winNames]]} {
			error "No window currently opened."
		}
		# There is some confusion here.  If 'filename' is a file then we
		# should use file::hasOpenWindows instead of bringToFront which
		# will work even if it is not the unique representation of the
		# file.  Alternatively, the edit -c -w should work anyway, so
		# bringToFront isn't needed.
	} elseif {[win::Exists $filename]]} {
		bringToFront $filename
	} elseif {[catch {edit -c -w $filename}]} {
		error "Can't find file '$filename'"
	} 
	if {![file exists [flt::pathToFilter $filtername]]} {
		error "Can't find '$filtername' filter."
	} 
	set flt_p(appliedfilter) $filtername
	if {![flt::getFilterData]} {return 0}
	set flt_p(moveoffscreen) 1
	set flt_p(filtersleft) 0
	flt::filterCore
}


proc flt::filterThisSelection {filtername text} {
	global flt_p
	if {![file exists [flt::pathToFilter $filtername]]} {
		return ""
	} 
	set flt_p(appliedfilter) $filtername
	if {![flt::getFilterData]} {return ""}
	return [flt::applyFilterLinesToText $flt_p(filterlines) $text]
}


proc flt::applyFilterLinesToText {filterlines text} {
	global flt_p
	# Set filtering parameters
	set flt_p(filterlines) $filterlines
	set flt_p(thesel) $text
	set flt_p(moveoffscreen) 0
	set flt_p(filtersleft) 0
	# Do the filtering in a scrap window
	flt::getScrapWindow
	flt::filterCore
	# Retrieve the result
	set result [getText [minPos] [maxPos]]
	setWinInfo -w $flt_p(scrapwin) dirty 0
	killWindow
	return $result
}
