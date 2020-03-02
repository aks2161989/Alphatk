## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "latexNavigation.tcl"
 #                                          created: 11/10/1992 {10:42:08 AM}
 #                                      last update: 03/21/2006 {03:11:20 PM}
 # Description:
 #
 # Support for navigating TeX files.
 #
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the main TeX mode file has been loaded.
latex.tcl

proc latexNavigation.tcl {} {}

namespace eval TeX {}

# Find the next or previous environment.  Search forward (or backward,
# depending on $forward) for either \begin or \end.  If \begin is found,
# search forward for corresponding \end; otherwise, search backward for
# corresponding \begin.  Select the found environment, or display an error
# message if no environment is found.

proc TeX::findEnvironment {forward {searchPos ""}} {

    set searchString1 {^[ \t]*\\begin\{[^\{\}]*\}|\\end\{[^\{\}]*\}[ \t]*\r?}
    if {![string length $searchPos]} {
	set searchPos [getPos]
	if {[isSelection]} {
	    if {$forward} {
		set searchPos [selEnd]
	    } else {
		set searchPos [pos::math $searchPos - 1]
	    }
	} else {
	    if {$forward} {
		set searchPos [pos::math $searchPos + 1]
	    } else {
		set searchPos [pos::math $searchPos - 1]
	    }
	}
    }
    set searchResult [search -s -f $forward -r 1 -n $searchString1 $searchPos]
    if {[llength $searchResult]} {
	set begPos [lindex $searchResult 0]
	set endPos [lindex $searchResult 1]
	set searchText [getText $begPos $endPos]
	regexp {\{(.*)\}} $searchText dummy envName
	set envName [quote::Regfind $envName]
	if {[string match {*begin*} $searchText]} {
	    set begEnv $begPos
	    append searchString2 {\\end\{} $envName {\}[ \t]*\r?}
	    set searchPos $endPos
	    set searchResult [search -s -f 1 -r 1 -n $searchString2 $searchPos]
	    if {[llength $searchResult]} {
		set endPos [lindex $searchResult 1]
		return [list $begPos $endPos]
	    } else {
		return "matching \\end not found"
	    }
	} else {
	    set endEnv $endPos
	    append searchString2 {^[ \t]*\\begin\{} $envName {\}}
	    set searchPos $begPos
	    set searchResult [search -s -f 0 -r 1 -n $searchString2 $searchPos]
	    if {[llength $searchResult]} {
		set begPos [lindex $searchResult 0]
		return [list $begPos $endPos]
	    } else {
		return "matching \\begin not found"
	    }
	}
    } else {
	if {$forward} {
	    return "next environment not found"
	} else {
	    return "previous environment not found"
	}
    }
}

proc TeX::prevEnvironment {} {

    set findResult [TeX::findEnvironment 0]
    if {[llength $findResult] == 2} {
	goto [lindex $findResult 0]
    } else {
	status::msg $findResult
    }
}

proc TeX::nextEnvironment {} {

    set findResult [TeX::findEnvironment 1]
    if {[llength $findResult] == 2} {
	goto [lindex $findResult 0]
    } else {
	status::msg $findResult
    }
}

proc TeX::prevEnvironmentSelect {} {

    set forward 0
    set findResult [TeX::findEnvironment $forward]
    if {[llength $findResult] == 2} {
	set endPos [lindex $findResult 1]
	# if {[regexp {\r} [lookAt [expr $endPos + 1]]]} {
	#     set endPos [expr $endPos + 1]
	# }
	selectText [lindex $findResult 0] $endPos
    } else {
	status::msg $findResult
    }
}

proc TeX::nextEnvironmentSelect {} {

    set forward 1
    set findResult [TeX::findEnvironment $forward]
    if {[llength $findResult] == 2} {
	set endPos [lindex $findResult 1]
	# if {[regexp {\r} [lookAt [expr $endPos + 1]]]} {
	#     set endPos [expr $endPos + 1]
	# }
	selectText [lindex $findResult 0] $endPos
    } else {
	status::msg $findResult
    }
}

# Find a LaTeX command in either direction.  It's up to the calling
# procedure to pass the correct starting position of the search.

proc TeX::findCommand {pos direction} {

    #	Handle "\ " and "\[" separately:
    set searchString {(\\([^a-zA-Z\t\r* []|[a-zA-Z]+)\*?)|([^\\]\\\ )|([^\\]\\\[)}
    set searchResult [search -s -f $direction -r 1 -n $searchString $pos]
    if {[llength $searchResult]} {
	set begPos [lindex $searchResult 0]
	set endPos [lindex $searchResult 1]
	set lastChar [lookAt [pos::math $endPos - 1]]
	if {$lastChar == "\ " || $lastChar == "\["} {
	    return [list [pos::math $begPos + 1] $endPos]
	} else {}
    }
    return $searchResult
    # Handles everything but "\ " and "\[":
    # 	set searchString {\\([^a-zA-Z\t\r* []|[a-zA-Z]+)\*?}
    # 	return [search -s -f $direction -r 1 -n $searchString $pos]
}

# Find a LaTeX command with arguments in either direction.  It's up
# to the calling procedure to pass the starting position of the search.
# (Handles everything but "\ " and commands whose arguments contain
# embedded braces.)

proc TeX::findCommandWithArgs {pos direction} {
    set searchString {\\([^a-zA-Z\t\r]|[a-zA-Z]+\*?)(\[.*\])*({[^{}]*})*}
    return [search -s -f $direction -r 1 -n $searchString $pos]
}

# Find a LaTeX sectioning command in either direction.  It's up to the
# calling procedure to pass the starting position of the search.

proc TeX::findSection {pos direction} {
    global funcExprAlt
    return [search -s -f $direction -r 1 -n $funcExprAlt $pos]
}

proc TeX::prevSectionSelect {} {

    set pos [getPos]
    if {[pos::compare $pos > [minPos]]} {
	set searchResult [TeX::findSection [pos::math $pos - 1] 0]
	if {[llength $searchResult]} {
	    set begPos [lindex $searchResult 0]
	    set searchPos [pos::math [lindex $searchResult 1] + 1]
	    set searchResult [TeX::findSection $searchPos 1]
	    if {[llength $searchResult]} {
		set endPos [lindex $searchResult 0]
	    } else {
		set searchResult [search -s -f 1 -r 0 -n "\\end{document}" $searchPos]
		if {[llength $searchResult]} {
		    set endPos [lindex $searchResult 0]
		} else {
		    set endPos [maxPos]
		}
	    }
	    selectText $begPos $endPos
	    return
	}
    }
    status::msg {previous section not found}
}

# Select the next LaTeX sectioning command.

proc TeX::nextSectionSelect {} {

    set pos [getPos]
    if {$pos < [maxPos]} {
	if {[isSelection]} {
	    set pos [pos::math $pos + 1]
	}
	set searchResult [TeX::findSection $pos 1]
	if {[llength $searchResult]} {
	    set begPos [lindex $searchResult 0]
	    set searchPos [pos::math [lindex $searchResult 1] + 1]
	    set searchResult [TeX::findSection $searchPos 1]
	    if {[llength $searchResult]} {
		set endPos [lindex $searchResult 0]
	    } else {
		set searchResult [search -s -f 1 -r 0 -n "\\end{document}" $searchPos]
		if {[llength $searchResult]} {
		    set endPos [lindex $searchResult 0]
		} else {
		    set endPos [maxPos]
		}
	    }
	    selectText $begPos $endPos
	    return
	}
    }
    status::msg {next section not found}
}

# Find a LaTeX subsectioning command in either direction.  It's up to the
# calling procedure to pass the starting position of the search.

proc TeX::findSubsection {pos direction} {
    global funcExpr
    return [search -s -f $direction -r 1 -n $funcExpr $pos]
}

proc TeX::prevSubsectionSelect {} {

    set pos [getPos]
    if {[pos::compare $pos > [minPos]]} {
	set searchResult [TeX::findSubsection [pos::math $pos - 1] 0]
	if {[llength $searchResult]} {
	    set begPos [lindex $searchResult 0]
	    set endPos [lindex $searchResult 1]
	    set searchPos [pos::math $endPos + 1]
	    set commandName [TeX::extractCommandName [getText $begPos $endPos]]
	    if {[string match {section*} $commandName]} {
		set searchResult [TeX::findSection $searchPos 1]
	    } else {
		set searchResult [TeX::findSubsection $searchPos 1]
	    }
	    if {[llength $searchResult]} {
		set endPos [lindex $searchResult 0]
	    } else {
		set searchResult [search -s -f 1 -r 0 -n "\\end{document}" $searchPos]
		if {[llength $searchResult]} {
		    set endPos [lindex $searchResult 0]
		} else {
		    set endPos [maxPos]
		}
	    }
	    selectText $begPos $endPos
	    return
	}
    }
    status::msg {previous (sub)*section not found}
}

# Select the next LaTeX sectioning command.

proc TeX::nextSubsectionSelect {} {

    set pos [getPos]
    if {[pos::compare $pos < [maxPos]]} {
	if {[isSelection]} {
	    set pos [pos::math $pos + 1]
	}
	set searchResult [TeX::findSubsection $pos 1]
	if {[llength $searchResult]} {
	    set begPos [lindex $searchResult 0]
	    set endPos [lindex $searchResult 1]
	    set searchPos [pos::math $endPos + 1]
	    set commandName [TeX::extractCommandName [getText $begPos $endPos]]
	    if {[string match {section*} $commandName]} {
		set searchResult [TeX::findSection $searchPos 1]
	    } else {
		set searchResult [TeX::findSubsection $searchPos 1]
	    }
	    if {[llength $searchResult]} {
		set endPos [lindex $searchResult 0]
	    } else {
		set searchResult [search -s -f 1 -r 0 -n "\\end{document}" $searchPos]
		if {[llength $searchResult]} {
		    set endPos [lindex $searchResult 0]
		} else {
		    set endPos [maxPos]
		}
	    }
	    selectText $begPos $endPos
	    return
	}
    }
    status::msg {next (sub)*section not found}
}

proc TeX::prev {what {select 0} {msg ""}} {

    set pos [getPos]
    if {[pos::compare $pos > [minPos]]} {
	set searchResult [TeX::find$what [pos::math $pos - 1] 0]
	if {[llength $searchResult]} {
	    if {$select} {
		eval selectText $searchResult
	    } else {
		goto [lindex $searchResult 0]
	    }
	    return
	}
    }
    if {$msg == ""} {set msg [string tolower $what]}
    status::msg "previous $msg not found"
}

proc TeX::next {what {select 0} {msg ""}} {

    set pos [getPos]
    if {[pos::compare $pos < [maxPos]]} {
	if {[isSelection]} {
	    set pos [pos::math $pos + 1]
	}
	set searchResult [TeX::find$what [pos::math $pos + 1] 1]
	if {[llength $searchResult]} {
	    if {$select} {
		eval selectText $searchResult
	    } else {
		goto [lindex $searchResult 0]
	    }
	    return
	}
    }
    if {$msg == ""} {set msg [string tolower $what]}
    status::msg "next $msg not found"
}

# ×××× Navigating Environments ×××× #

# These are called by 'function::next/prev' etc when the 'navigateParagraphs'
# preference is turned off.



# ==========================================================================
#
# .