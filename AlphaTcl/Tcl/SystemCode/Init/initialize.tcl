## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "initialize.tcl"
 #                                    created: 25/4/02 5:28:24 
 #                                last update: 03/23/2006 {12:44:02 PM} 
 #  Author: Daniel A. Steffen
 #  E-mail: <steffen@maths.mq.edu.au>
 #    mail: Macquarie University
 #          Mathematics Department, NSW 2109, Australia
 #     www: <http://www.maths.mq.edu.au/~steffen/>
 #  
 #  Description: 
 #  
 #  initialize.tcl should be the first file sourced in the AlphaTcl
 #  startup sequence when running under Alpha8/X/Tk.
 #  It can be sourced very early as it only assumes that the
 #  following global variables have been setup
 #      HOME, PREFS, alpha::platform
 #  and that the [alert] command or the [alertnote] proc exists
 #  (for startup error reporting).
 #  
 #  This file defines the procs [alpha::PreGuiStartup] and
 #  [alpha::Startup] which need to be called later in the AlphaTcl
 #  startup process by the embedding application.
 #  
 #  The 'Init' directory in which this file is located is just for
 #  any code that needs to run in the PreGuiStartup phase.  Once
 #  that phase is complete, we will then begin to access files
 #  outside this directory.
 #  
 #  Obviously we should try to keep as little as possible in the
 #  PreGuiStartup phase (and therefore as little as possible in the
 #  Init directory).
 #  
 #  History
 # 
 #  modified   by  rev reason
 #  ---------- --- --- -----------
 #  2002-04-25 DAS 1.0 original
 # ###################################################################
 ##

# If we have already sourced this file, then this proc will exist.
if {[llength [info procs initialize.tcl]]} {
    return
}

proc initialize.tcl {} {}

namespace eval alpha {}

# This will be redefined later.
;proc alpha::useFilesFor {filename args} {
    return [list $filename]
}

##
 # -------------------------------------------------------------------------
 # 
 # "alpha::recordTimingData" --
 # "alpha::returnTimingData" --
 # 
 # This is a developers tool to help time how long it takes to perform
 # certain startup routines.  Simply add a line like
 # 
 #     alpha::recordTimingData "Requiring 'Tclx' package ..."
 # 
 # at an appropriate juncture to add to the list.  Best to include such
 # calls in pairs to know when something starts and is complete.  This can
 # also be added by AlphaTcl developers to [alpha::package] scripts or
 # source files to record how long it takes to activate various modes,
 # menus, and features.  Once Alpha has been initialized, select the menu
 # item "AlphaDev > Alpha Testing > List Startup Times".
 # 
 # The companion proc [alpha::returnTimingData] exists so that other code
 # doesn't have to know how this information is stored internally.  If the
 # "clearList" argument is "1", all previous information is cleared.
 # 
 # -------------------------------------------------------------------------
 ##

if {0} {
    # Change the 'if {1}' to a 0 to record timing information.
    proc alpha::recordTimingData {args} {}
} else {
    proc alpha::recordTimingData {{note "some AlphaTcl routine"}} {
	variable startupTimes
	lappend startupTimes [list [clock clicks -milliseconds] $note]
	return
    }
}

proc alpha::returnTimingData {{clearList 0}} {
    variable startupTimes
    if {![info exists startupTimes]} {
	return
    }
    if {$clearList} {
	set startupTimes [list]
	return
    } else {
	return $startupTimes
    }
}

alpha::recordTimingData "Initializing AlphaTcl"

# We define the 'alpha::macos' variable as follows.  This basically
# tells us that we are able to use Apple-specific technology such
# as apple-events, applescript, resources, etc.
if {$tcl_platform(platform) == "macintosh"} {
    set alpha::macos 1
} elseif {$tcl_platform(platform) == "unix" && $tcl_platform(os) == "Darwin"} {
    set alpha::macos 2
} else {
    set alpha::macos 0
}

if {![info exists alpha::windowingsystem]} {
    set alpha::windowingsystem "alpha"
}

proc alpha::checkFileExists {path {isdir 0}} {
    if {![file exists $path] || \
      ($isdir && ![file isdirectory $path]) \
      || (!$isdir && ![file isfile $path])} {
	alertnote "Fatal Alpha error:\
	  Alpha cannot find its\
	  [expr {$isdir ? {directory} : {file}}]\
	  '[file join [pwd] $path]'.\
	  You should reinstall Alpha.  Goodbye."
	quit
    }
}

if {[file exists [file join $HOME Tclextensions]]} {
    set auto_path [linsert $auto_path 0 [file join $HOME Tclextensions]]
}

if {$alpha::platform == "alpha" && [llength [info commands alert]]} {
    if {[llength [info commands alertnote]] > 0} {rename alertnote __alertnote}
    ;proc alertnote {args} {
	alert -t stop -c "" -o "" [lindex $args 0] [join [lrange $args 1 end] " "]
	return
    }
    
    
    if {[llength [info commands askyesno]] > 0} {rename askyesno __askyesno}
    ;proc askyesno {args} {
	if {[lindex $args 0] == "-c"} {
	    set button [alert -t note -k "Yes" -c "No" -o "Cancel" -C other [lindex $args 1]]
	} else {
	    set button [alert -t note -k "Yes" -c "No" -o "" -C none [lindex $args 0]]
	}
	
	return [string tolower $button]
    }
    
    
    if {[llength [info commands buttonAlert]] > 0} {rename buttonAlert __buttonAlert}
    ;proc buttonAlert {prompt args} {
	set buttonCount [llength $args]
	
	if {$buttonCount > 3} {
	    if {[llength [info commands __buttonAlert]] > 0} {
		eval __buttonAlert [list $prompt] $args
	    }
	} else {
	    set cmd [list alert -t caution -c "" -o ""]
	    if {$buttonCount > 0} {
		set defaultText [lindex $args 0]
		lappend cmd -k $defaultText
		if {[string tolower $defaultText] == "cancel"} {
		    lappend cmd -C ok -K cancel
		} 
		if {$buttonCount > 1} {
		    set cancelText [lindex $args 1]
		    lappend cmd -c $cancelText
		    if {[string tolower $cancelText] == "cancel"} {
			lappend cmd -C cancel
		    } 
		    if {$buttonCount > 2} {
			set otherText [lindex $args 2]
			lappend cmd -o $otherText
			if {[string tolower $otherText] == "cancel"} {
			    lappend cmd -C other
			} 
		    }
		}
	    }
		    
	    lappend cmd $prompt
	    
	    eval $cmd
	}
    }
} else {
    if {[info commands alert] == "alert"} {
	rename alert __alert
    }
    ;proc alert {args} {
	# Note: currently the "t C K O h" flags are ignored.
	set opts(-c) "Cancel"
	getOpts {t c k o C K O h}
	# 'args' is now the message to be placed in the alert dialog.
	if {![llength $args]} {
	    error {wrong # args: should be "alert ?options? <error> ?explanation?"}
	}
	set msg [lindex $args 0]
	if {[llength $args] > 1} {
	    append msg "\r\r[join [lrange $args 1 end] " "]"
	}
	# Manipulate button text, ensuring that they'll be properly registered
	# in the [eval] below.
	foreach opt [list k c o] {
	    if {[info exists opts(-$opt)]} {
		set opts(-$opt) [list $opts(-$opt)]
	    } else {
		switch -- $opt {
		    "k"     {set opts(-$opt) [list "OK"]}
		    default {set opts(-$opt) ""}
		}
	    }
	}
	eval [list buttonAlert $msg] $opts(-k) $opts(-c) $opts(-o)
    }
}

if {![info exists alpha::internalEncoding]} {
    set alpha::internalEncoding macRoman
}

set alpha::defaultEncoding [encoding system]
if {($alpha::macos == 2)} {
    set alpha::defaultEncoding "macRoman"
}

lappend alpha::coreHierarchy HOME PREFS

# This will be over-ridden later, by a simpler version.
proc alpha::inAlphaHierarchy {filename} {
    variable coreHierarchy
    global tcl_platform
    if {$tcl_platform(platform) == "windows"} {
	catch {set filename [file join [file attributes $filename -longname]]}
    } else {
	set filename [file join $filename]
    }
    if {[file pathtype $filename] == "relative"} {
	set filen [file join [pwd] $filename]
    } else {
	set filen $filename
    }
    # Is file in any of the core hierarchy (HOME or PREFS or ALPHATK)
    foreach v $coreHierarchy {
	global $v
	if {![info exists $v]} {
	    continue
	}
	set val [set $v]
	if {([string first [file join $val] $filen] != 0) \
	  && !([file type [file join $val]] == "link" \
	  && [string first [file readlink [file join $val]] $filen] == 0)} {
	    continue
	} else {
	    return 1
	}
    }
    return 0
}

# This will be over-ridden later
proc alpha::encodingFor {filename} {
    if {[alpha::inAlphaHierarchy $filename]} {
	return $::alpha::internalEncoding
    } else {
	return ""
    }
}

# Handling of stdout, stderr (the first two of these procedures can be 
# called by Alpha 8/X/tk's core).
proc alpha::stdout {string} {
    log stdout $string
}
proc alpha::stderr {string} {
    log stderr $string
}
proc alpha::log {channel string} {
    variable logCache
    lappend logCache($channel) $string
    if {[catch {insertText -w "* Tcl Shell *" "\r" $string}]} {
	catch {status::msg $string}
    }
}

# Convert the .tcl files from their default encoding when we source
# them.  Other files (prefs etc.) will be stored in their correct
# encoding, so we only apply this to files in the Alpha:Tcl directory.
if {[lsearch -exact [encoding names] $alpha::internalEncoding] == -1} {
    catch {alertnote "We don't have a $alpha::internalEncoding encoding;\
      this will cause serious problems!"}
} else {
    rename source __enc_source
    proc source {args} {
	foreach filename [alpha::useFilesFor [lindex $args end]] {
	    alpha::recordTimingData "Sourcing '${filename}'"
	    if {[llength $args] > 1} {
		# Pass on -encoding, -rsrc, -rsrcid direct
		set args   [lreplace $args end end $filename]
		set retVal [uplevel 1 __enc_source $args]
	    } elseif {![file exists $filename] || ![file readable $filename]} {
		# This will probably throw an error.
		set retVal [uplevel 1 [list __enc_source $filename]]
	    } elseif {([set enc [alpha::encodingFor $filename]] eq "")} {
		# No encoding previously registered for this file.
		set retVal [uplevel 1 [list __enc_source $filename]]
	    } elseif {[info tclversion] >= 8.5} {
		# Use the registered encoding.
		set retVal [uplevel 1 [list __enc_source -encoding $enc $filename]]
	    } else {
		# Use the registered encoding.
		if {[catch {
		    set fileid [open $filename "r"]
		    fconfigure $fileid -encoding $enc 
		    set contents [read $fileid]
		    close $fileid
		} err]} {
		    # This is pretty desperate if we get here!
		    error "Error while pre-sourcing $filename : $err"
		}
		set oldscript [info script]
		info script $filename
		set code [catch {uplevel 1 $contents} retVal]
		info script $oldscript
		if {($code == 1)} {
		    error $retVal $::errorInfo $::errorCode
		}
	    }
	}
	return $retVal
    }
}

if {![llength [info procs alpha::Init]]} {
    proc alpha::Init {} {
	global alpha::macos
	alpha::recordTimingData "Starting  proc: alpha::Init"
	rename alpha::Init {}

	# Not much to do anymore, since AlphaTcl 8.0d1

	# For AlphaX, the [resource] command is defined via an extension
	if {($alpha::macos == 2)} {
	    alpha::recordTimingData "Requiring 'resource' ..."
	    if {[catch {package require resource} err]} {
		alpha::recordTimingData "(Requiring 'resource' failed)"
		alpha::recordTimingData "(Error info: $err)"
	    }
	    unset -nocomplain err
	    alpha::recordTimingData "Requiring 'resource' ... finished"
	}
	alpha::recordTimingData "Finishing proc: alpha::Init"
    }
}

if {![llength [info procs alpha::PreGuiStartup]]} {
    proc alpha::PreGuiStartup {} {
	alpha::recordTimingData "Starting  proc: alpha::PreGuiStartup"
	rename alpha::PreGuiStartup {}
	set file [file join $::HOME Tcl SystemCode Init initAlphaTcl.tcl]
	checkFileExists $file
	uplevel #0 [list source $file]
	alpha::recordTimingData "Finishing proc: alpha::PreGuiStartup"
    }
}

if {![llength [info procs alpha::Startup]]} {
    proc alpha::Startup {} {
	global alpha::macos
	alpha::recordTimingData "Starting  proc: alpha::Startup"
	rename alpha::Startup {}
	# (Workaround: see bug# 2014)
	if {($alpha::macos == 2) && [catch {package present resource}]} {
	    alpha::recordTimingData "Requiring 'resource' ..."
	    if {[catch {package require resource} err]} {
		alpha::recordTimingData "(Requiring 'resource' failed)"
		alpha::recordTimingData "(Error info: $err)"
	    }
	    unset -nocomplain err
	    alpha::recordTimingData "Requiring 'resource' ... finished"
	}
	set file [file join $::HOME Tcl SystemCode AlphaBits.tcl]
	checkFileExists $file
	uplevel #0 [list source $file]
	alpha::recordTimingData "Finishing proc: alpha::Startup.\
	  Startup now complete"
    }
}

alpha::Init

# ===========================================================================
# 
# .