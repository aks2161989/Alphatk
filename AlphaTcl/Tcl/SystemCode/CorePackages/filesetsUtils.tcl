## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 #
 # FILE: "filesetsUtils.tcl"
 #					    created: 05/01/2000 {15:08:49 PM}
 #				        last update: 04/11/2006 {02:07:46 PM}
 # Description:
 # 
 # Various default utilities for filesets.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 # 
 # Copyright (c) 2000-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc filesetsUtils.tcl {} {}

## 
 # -------------------------------------------------------------------------
 #	 
 #	"iterateFileset" --
 # 
 #  Utility procedure to iterate over all files in a project, calling some
 #  predefined function '$fn' for each member of project '$proj'.  The
 #  results of such a call are passed to '$resfn' if given.  Finally "done"
 #  is passed to 'resfn'.
 #	 
 # -------------------------------------------------------------------------
 ##
proc iterateFileset { proj fn { resfn \# } } {
    eval $resfn "first"
    
    set check [expr {![catch {[fileset::type $proj]IterateCheck check}]}]
    
    foreach ff [getFileSet $proj] {
	if { $check && [[fileset::type $proj]IterateCheck $proj $ff] } {
	    continue
	}
	set res [eval $fn [list $ff]]
	eval $resfn [list $res]
    }
    
    if {$check} {
	catch {[fileset::type $proj]IterateCheck done}
    }
    
    eval $resfn "done"
    
}

proc filesetRememberOpenClose { file } {
    global fileset_openorclosed
    set fileset_openorclosed [list "$file" [lsearch -exact [winNames -f] $file]]
}

proc filesetRevertOpenClose { file } {
    global fileset_openorclosed
    if { [lindex $fileset_openorclosed 0] == "$file" } {
	if { [lindex $fileset_openorclosed 1] < 0 } {
	    killWindow
	}
    }	
    unset -nocomplain fileset_openorclosed
}

# ×××× Utils ×××× #

proc printFileset { {fset ""}} {
    if {[catch {pickFileset $fset "Print which Fileset?"} fset]} {return}
    foreach f [getFilesInSet $fset] {
	print $f
    }
}

proc browseFileset {{fset ""}} {
    global tileLeft tileTop tileWidth errorHeight browse::separator browse::jumpTo
    
    if {[catch {pickFileset $fset {Fileset?}} fset]} {return}
    
    foreach f [getFilesInSet $fset] {
	lappend text "\t[file tail $f]${browse::jumpTo}$f"
    }
    new -n "* FileSet '$fset' Browser *" -g $tileLeft $tileTop 200 $errorHeight \
      -m Brws -info "(<cr> to go to file)\r${browse::separator}\r[join $text \r]"
    selectText [nextLineStart [nextLineStart [minPos]]] \
      [nextLineStart [nextLineStart [nextLineStart [minPos]]]]
    status::msg ""
}	

proc saveEntireFileset { fset } {
    foreach f [getFilesInSet $fset] {
	foreach w [file::hasOpenWindows $f] {
	    getWinInfo -w $w arr
	    if {$arr(dirty)} {
		save $w
	    }
	}
    }
}

proc closeEntireFileset { {fset ""} } {
    if {[catch {pickFileset $fset "Close which fileset?"} fset]} {return}
    
    foreach f [getFilesInSet $fset] {
	foreach w [file::hasOpenWindows $f] {
	    killWindow -w $w
	}
    }
}

proc fileToAlpha {f} {
    file::setSig $f [expr {$::alpha::platform == "alpha" ? "ALFA" : "AlTk"}]
}

proc filesetToAlpha {} {
    if {![catch {pickFileset "" {Convert all files from which fileset?}} fset]} {
	iterateFileset $fset fileToAlpha
    }
}

proc openEntireFileset {} {
    set fset [pickFileset "" "Open which fileset?"]
    
    # we use our iterator in case there's something special to do
    iterateFileset $fset {if {[file isfile $ff]} {edit -c -w $ff};#}
}

proc listNewFilesFromFileset {{fset ""}} {
    set fset [pickFileset $fset "List new files from which fileset?"]
    
    set val [dialog -w 330 -h 100 -t "List files modified within the last" 10 10 290 30 -e "" 15 40 45 55 \
      -m {hours days hours minutes} 60 40 200 60 -b OK 20 70 85 90 -b Cancel 110 70 175 90]
    set age [string trim [lindex $val 0]]
    if {[lindex $val 3] || (![is::PositiveInteger $age] && ![lindex $val 4])} {
	status::msg "Cancelled"
	return
    }
    switch -- [lindex $val 1] {
	days {set timelimit [expr [now].0 - $age * 86400]}
	hours {set timelimit [expr [now].0 - $age * 3600]}
	minutes {set timelimit [expr [now].0 - $age * 60]}
    }
    regexp {[^\.]+} ${timelimit} timelimit

    set ::listnewfiles {}
    iterateFileset $fset [format {
	if {[file isfile $ff] && [file mtime $ff] >= %s} {
	    lappend ::listnewfiles $ff
	};# } $timelimit]
    
    new -n "Files from $fset" -text [join $::listnewfiles \r]
    unset ::listnewfiles
}

proc openFilesetFolder {{fset ""}} {
    set fset [pickFileset $fset "Open which fileset's folder?"]
    
    set dir [fileset::getBaseDirectory $fset]

    if {[string length $dir]} {
	file::showInFinder $dir
    } else {
	alertnote "Fileset not connected to a folder."
    }
}

proc stuffFileset {{fset ""}} {
    global alpha::macos
    
    set fset [pickFileset $fset "Stuff which fileset?"]
    if {[string length $fset]} {
	set dir [fileset::getBaseDirectory $fset]
	if {($dir ne "") && [dialog::yesno "Stuff entire directory '$dir'?"]} {
	    if {${alpha::macos}} {
		app::launchFore DStf
		sendOpenEvent reply 'DStf' "${dir}[file separator]"
		sendQuitEvent 'DStf'
	    } else {
		app::runScript stuff \
		  "Stuffing application (DropStuff)" "" 1 0 $dir
	    }
	} else {			
	    if {${alpha::macos}} {
		app::launchFore DStf
		eval [list sendOpenEvents 'DStf'] [getFilesInSet $fset]
		sendQuitEvent 'DStf'
	    } else {
		foreach f [getFilesInSet $fset] {
		    app::runScript stuff \
		      "Stuffing application (DropStuff)" "" 1 0 $f
		}
	    }
	}		
    }
}

proc zipFileset {{fset ""}} {
    global alpha::macos
    
    set fset [pickFileset $fset "Zip which fileset?"]
    if {[string length $fset]} {
	set dir [fileset::getBaseDirectory $fset]
	if {($dir ne "") && [dialog::yesno "Zip entire directory '$dir'?"]} {
	    if {${alpha::macos}} {
		app::launchFore DZip
		sendOpenEvent reply 'DZip' "${dir}[file separator]"
		sendQuitEvent 'DZip'
	    } else {
		app::runScript zip "Zipping application" "" 1 0 $dir
	    }
	} else {			
	    if {${alpha::macos}} {
		app::launchFore DZip
		eval [list sendOpenEvents 'DZip'] [getFilesInSet $fset]
		sendQuitEvent 'DZip'
	    } else {
		foreach f [getFilesInSet $fset] {
		    app::runScript zip "Zipping application" "" 1 0 $f
		}
	    }
	}		
    }
}

proc wordCountFileset {{fset ""}} {
    set fset [pickFileset $fset "Word count in which fileset?"]
    iterateFileset $fset wordCountProc filesetUtilWordCount
}

proc filesetUtilWordCount {count} {
    global fs_ccount fs_wcount fs_lcount
    switch -- $count {
	"first" {
	    set fs_ccount 0
	    set fs_wcount 0
	    set fs_lcount 0
	}       
	"done" {
	    alertnote "There were $fs_ccount lines, $fs_wcount words and $fs_lcount chars"
	    unset fs_ccount fs_wcount fs_lcount
	}
	default {
	    incr fs_ccount [lindex $count 2]
	    incr fs_wcount [lindex $count 1]
	    incr fs_lcount [lindex $count 0]
	}
    }
}


## 
 # -------------------------------------------------------------------------
 # 
 # "wordCountProc" --
 # 
 #  Completely new proc which does the same as the old one
 #  without opening lots of windows.
 #  *Very* memory comsuming for large files, though.
 #  But I think the old one was equally memory consuming.
 #  
 #  OK, this is not exactly a bug fix. It's a IMHO better option.
 #  
 # -------------------------------------------------------------------------
 ##

proc wordCountProc {file} {
    if {![file isfile $file] || ![file readable $file]} {
	return [list 0 0 0]
    }
    status::msg "Counting [file tail $file]É"
    set fid [alphaOpen $file r]
    set filecont [read $fid]
    close $fid
    if {[regexp {\n\r} $filecont]} {
	set newln "\n\r"
    } elseif {[regexp {\n} $filecont]} {
	set newln "\n"
    } else {
	set newln "\r"
    }
    set lines [expr {[regsub -all -- $newln $filecont " " filecont] + 1}]
    set chars [string length $filecont]
    regsub -all {[!=;.,\(\#\=\):\{\"\}]} $filecont " " filecont
    set words [llength $filecont]
    return [list $chars $words $lines]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "replaceInFileset" --
 # 
 #  Quotes things correctly so searches work, and adds a check on
 #  whether there are any windows.
 #  
 #  This procedure is a little obsolete, given what's in the supersearch
 #  package.  However some people may find it useful.
 # -------------------------------------------------------------------------
 ##
proc replaceInFileset {} {
    global win::NumDirty
    set how [dialog::optionMenu "Search type:" \
      [list "Textual replace" "Case-independent textual replace" \
      "Regexp replace" "Case-independent regexp replace"] "" 1]
    set from [prompt "Search string:" [searchString]]
    searchString $from
    if {$how < 2} {set from [quote::Regfind $from]}
    
    set to [prompt "Replace string:" [replaceString]]
    replaceString $to
    if {$how < 2} {set to [quote::Regsub $to]}
    if {[catch {regsub -- $from "$from" $to dummy} err]} {
	alertnote "Regexp compilation problems: $err"
	return
    }
    set fsets [pickFileset "" "Which filesets?" "multilist"]
    
    if {$win::NumDirty} {
	if {[buttonAlert "Save all windows?" "Yes" "Cancel"] != "Yes"} return
	saveAll
    }
    
    set cid [scancontext create]
    set changes 0
    if {$how & 1} {
	set case "-nocase"
	scanmatch -nocase $cid $from {set matches($f) 1 ;incr changes}
    } else {
	set case "--"
	scanmatch $cid $from {set matches($f) 1 ;incr changes}
    }
    
    watchCursor
    foreach fset $fsets {
	foreach f [getFileSet $fset] {
	    if {![catch {set fid [alphaOpen $f]}]} {
		status::msg "Looking at '[file tail $f]'"
		scanfile $cid $fid
		close $fid
	    }
	}
    }
    
    scancontext delete $cid
    
    foreach f [array names matches] {
	status::msg "Modifying ${f}É"
	set cid [alphaOpen $f "r"]
	if {[regsub -all $case $from [read $cid] $to out]} {
	    set ocid [alphaOpen $f "w+"]
	    puts -nonewline $ocid $out
	    close $ocid
	}
	close $cid
    }
    
    eval file::revertThese [array names matches]
    status::msg "Replaced $changes instances"
}

# ===========================================================================
# 
# .