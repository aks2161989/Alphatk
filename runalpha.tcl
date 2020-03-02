#!/bin/sh
#-*-tcl-*-
# the next line restarts using wish \
exec tclsh "$0" ${1+"$@"}

# The purpose of this script is as something which can be executed 
# many times, each time passing off its arguments to the real Alphatk
# application which is a single process (which you usually don't want
# to run multiple times).

set dir [file dirname [info script]]
# This script is best off run with tclsh, but just in case
# we're using Tk, get rid of the '.' window.
if {[llength [info commands wm]]} {
    #wm withdraw .
}

if {[info tclversion] < 8.1} {
    error "We require Tcl version 8.1 or newer; you have [info tclversion]"
    return
}

#tk_messageBox -title "'$argc' '$argv'"
if {$argc > 0} {
    if {[llength $argv] > 0} {
	# We do this so we don't have to mess with Windows native-names
	# which use backslashes which Tcl doesn't like.
	if {[string trim [lindex $argv 0]] != ""} {
	    set name [file nativename [lindex $argv 0]]
	    set args ""
	    
	    if {$argc > 1} {
		set args [lrange $argv 1 end]
		if {![file exists $name]} {
		    if {[string index $name 0] == "\{"} {
			set name [string trim $name "\{\}"]
		    }
		    if {$name == ""} {
			set argc 0
		    }
		    if {![file exists $name]} {
			set name [file nativename [join $argv " "]]
			set args ""
		    }
		}
	    } else {
		if {![file exists $name]} {
		    if {[string index $name 0] == "\{"} {
			set name [string trim $name "\{\}"]
		    }
		    if {$name == ""} {
			set argc 0
		    }
		}
	    }
	    if {[llength $args]} {
		if {[lindex $args 0] == "-line"} {
		    set line [lindex $args 1]
		}
	    }
	    # So we can handle relative path names in the
	    # startup sequence.
	    if {[file pathtype $name] == "relative"} {
		set name [file join [pwd] $name]
	    }
	}
    } else {
	set argc 0
    }
}

switch -- $tcl_platform(platform) {
    "unix" {
	switch -- $argc {
	    0 {
		if {[lsearch -exact [winfo interps] "alpha"] == -1} {
		    # startup the application
		    cd $dir
		    exec [info nameofexecutable] alphatk.tcl &
		}
	    }
	    1 {
		if {[lsearch -exact [winfo interps] "alpha"] == -1} {
		    cd $dir
		    exec [info nameofexecutable] alphatk.tcl [list edit $name] &
		} else {
		    # can't use async because this script ends and the connection
		    # is aborted too early
		    send alpha [list edit $name]
		}
	    }
	    default {
		if {[lsearch -exact [winfo interps] "alpha"] == -1} {
		    cd $dir
		    exec [info nameofexecutable] alphatk.tcl [list edit $name] &
		} else {
		    # can't use async because this script ends and the connection
		    # is aborted too early
		    send alpha [list edit $name]
		}
		#error "Bad arguments $argv to 'alpha'.  Only one argument allowed"
	    }
	}
    }
    "windows" {
	package require dde
	switch -- $argc {
	    0 {
		# startup the application
		if {[lsearch -exact [dde services TclEval ""] {TclEval Alpha}] == -1} {
		    cd $dir
		    exec [info nameofexecutable] alphatk.tcl &
		}
	    }
	    default {
		if {[lsearch -exact [dde services TclEval ""] {TclEval Alpha}] == -1} {
		    cd $dir
		    exec [info nameofexecutable] alphatk.tcl [list edit $name] &
		} else {
		    # can't use async because this script ends and the connection
		    # is aborted too early
		    dde execute TclEval Alpha [list file::openQuietly $name]
		}
		if {[info exists line]} {
		    dde execute TclEval Alpha [list goto "${line}.0"]
		}
	    }
	}
    }
    "macintosh" {
	switch -- $argc {
	    0 {
		# startup the application
		cd $dir
		exec [info nameofexecutable] alphatk.tcl &
	    }
	    1 {
		package require Comm 3
		if {[catch {comm connect 1197}]} {
		    cd $dir
		    exec [info nameofexecutable] alphatk.tcl [list edit $name] &
		} else {
		    # can't use async because this script ends and the connection
		    # is aborted too early
		    comm send 1197 [list edit $name]
		}
	    }
	    default {
		package require Comm 3
		if {[catch {comm connect 1197}]} {
		    cd $dir
		    exec [info nameofexecutable] alphatk.tcl [list edit $name] &
		} else {
		    # can't use async because this script ends and the connection
		    # is aborted too early
		    comm send 1197 [list edit $name]
		}
		#error "Bad arguments $argv to 'alpha'.  Only one argument allowed"
	    }
	}
    }
    default {
	error "No known platform"
    }
}

exit
