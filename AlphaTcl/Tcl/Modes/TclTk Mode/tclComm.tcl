## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "tclComm.tcl"
 #                                          created: 09/11/2002 {05:44:06 PM}
 #                                      last update: 2005-02-24 10:17:30
 # Description:
 # 
 # Communication with Tcl interpreters.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Copyright (c) 1997-2004 Vince Darley
 # All rights reserved.
 # 
 # ==========================================================================
 ##

proc tclComm.tcl {} {}

# auto-load the xserv declarations for this mode
tclMode.tcl

namespace eval tcltk {}

# Need to document behaviour of this function
proc tcltk::run {} {
    global TclprojectEvalCmd
    
    set project [Tcl::project]
    set file [lindex [Tcl::projectInfo] 1]
    set sig [lindex [Tcl::projectInfo] 3]
    if {![string length $file]} {
	status::msg "Sending current window to interpreter"
	set file [win::Current]
	Tcl::setProject [set project "Current Window"]
	set sig [lindex [Tcl::projectInfo] 3]
    }
    set shel [tcltk::executeInShell $file]
    set TclprojectEvalCmd($project) $shel
}

proc tcltk::ensureFile {f} {
    if {![llength [winNames]]} {
	status::msg "No window"
	return ""
    }
    if {![win::IsFile $f]} {
	if {![dialog::yesno -y "Save To Temp" -n "Cancel" \
	  "This window doesn't actually exist on disk.  Press \"Cancel\"\
	  and save it as a local file, or save it as a temporary file\
	  in order to continue."]} {
	    error "cancel"
	}
	set tail [file tail $f]
	regsub -all " " [file::makeNameLegal $tail] "-" newName
	saveAs -f [temp::unique tcltk [file root $newName] .tcl]
	set f [win::Current]
    }
    return $f
}

proc tcltk::executeInShell {f} {
    if {![string length [set f [ensureFile $f]]]} {
	return
    }
    set realName [win::StripCount $f]
    return [launchShell \
      [list cd [file dirname $realName]] \
      [list set argc 0] \
      [list set argv [list]] \
      [list set argv0 [file tail $realName]] \
      [list source [file tail $realName]]]
}

proc tcltk::launchNewShell {args} {
    set shel [launchShell]

    global tclshInterp
    if {[llength $args]} {
	foreach cmd $args {
	    evaluateIn $tclshInterp $cmd
	}
    }
    return $shel
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tcltk::launchShell" --
 # 
 #  Startup up a new Tcl shell, ensuring that we can communicate with that
 #  shell.  On Unix/MacOS this should be easy using 'send' or apple-events
 #  respectively.  On Windows we have to set up the new shell as a dde
 #  server.  We do this with the script 'winRemoteShell.tcl'.
 #  
 #  Any extra 'args' passed to this procedure are executed, one by one,
 #  in the new shell.
 # -------------------------------------------------------------------------
 ##

proc tcltk::launchShell {args} {
    set shel [::xserv::invoke tclInterpreterStart]

    if {[catch {
	if {[llength $args]} {
	    foreach arg $args {
		set res [::xserv::invoke tclEvaluate \
		  -interp $shel -script $arg]
	    }
	    return $shel
	}
    } err]} {
	# Probably the initial launch failed with an error
	status::msg $err
    }
    return $shel
}

# ×××× Evaluate implementations ×××× #

proc evaluate {args} {
    
    global alpha::platform
    
    win::parseArgs w {script ""}
    
    if {![string length $script]} {
	if {![llength [winNames]]} {
	    status::msg "No open window!"
	    return
	} elseif {[isSelection -w $w]} {
	    set script [getSelect -w $w]
	    if {[pos::compare -w $w [getPos -w $w] == [pos::min -w $w]] \
	      && [pos::compare -w $w [selEnd -w $w] == [pos::max -w $w]]} {
		set simulateSource $w
	    }
	} else {
	    set script [getText -w $w [pos::min -w $w] [pos::max -w $w]]
	    set simulateSource $w
	}
    } 
    if {![string length [string trim $script]]} {
	status::msg "Nothing found to evaluate!"
	return
    } elseif {${alpha::platform} == "alpha"} {
	regsub -all "\r" $script "\n" script
    }
    if {[info exists simulateSource] && [win::IsFile $simulateSource fn]} {
	# We're evaluating the entire file contents, so emulate source
	# by setting 'info script' in case the window's contents
	# requires it.  If we were sure the interpreter used Tcl 8.5 or
	# newer we could just set the script to:
	# 
	#   source -encoding [win::Encoding $simulateSource] $fn
	#   
	# which would do the same thing for us.
	set orig [eval [tcltk::getInterpCmd] [list [list info script]]]
	eval [tcltk::getInterpCmd] [list [list info script $fn]]
	set code [catch {eval [tcltk::getInterpCmd] [list $script]} result]
	eval [tcltk::getInterpCmd] [list [list info script $orig]]
    } else {
	set code [catch {eval [tcltk::getInterpCmd] [list $script]} result]
    }
    if {![string length $result]} {set result {(none)}}
    if {$code == 0} {
	status::msg "Result: $result"
    } elseif {$code == 1} {
	status::msg "Error: $result"
    } else {
	status::msg "Non-zero return code ($code): $result"
    }
    return $result
}

proc tcltk::directEvaluation {script} {
    set evalCmd [getInterpCmd]
    eval $evalCmd [list $script]
}

proc tcltk::getInterpCmd {} {
    Tcl::synchroniseProjectHook
    Tcl::getInterp
}

proc tcltk::isInternal {in} {
    if {$in == "tcltk::internalEvaluate"} {
	return 1
    } else {
	return 0
    }
}

proc tcltk::evaluateIn {in what args} {
    eval $in [list $what] $args
}

proc tcltk::slaveInterpEvaluate {in what} {
    $in eval $what
}

proc tcltk::internalEvaluate {what args} {
    uplevel \#0 $what
}

proc tcltk::tclaeEvaluate {to what args} {
    if {[catch {tclAE::build::resultData -t 30000 '$to' \
      misc dosc ---- [tclAE::build::TEXT $what]} res]} {
        if {$res eq "Process \"'$to'\" not found"} {
            # probably still launching
            after 1000
            return [tclAE::build::resultData -t 30000 '$to' \
              misc dosc ---- [tclAE::build::TEXT $what]]
        }
        return -code error $res
    }
    return $res
}

proc tcltk::ddeEvaluate {to what {withResult 1}} {
    if {[dde services TclEval $to] == ""} {
	if {[catch {Tcl::interpDied $to} interp]} {
	    return -code error $interp
	} else {
	    return [eval $interp [list $what $withResult]]
	}
    }
    # Special case to avoid some simple problems.
    if {[string trim $what] == "exit"} { set withResult 0 }
    if {$withResult} {
	dde execute TclEval $to [list catch $what alpha_result]
	return [dde request TclEval $to alpha_result]
    } else {
	catch {dde execute -async TclEval $to $what}
	return ""
    }
}

proc tcltk::sendEvaluate {to what args} {
    send $interp $what
}

# ×××× Helpers ×××× #

proc tcltk::quitRemote {evalCmd} {
    eval $evalCmd [list "exit" 0]
}

proc tcltk::listInterps {} {
    ::xserv::invoke listTclInterpreters
}

proc tcltk::findTclshInterp {} {
    set shel [listpick -p "Use which Tcl shell?" [concat [listInterps] \
      [list "------------------" "Launch new shell"]]]
    if {$shel == "Launch new shell"} {
	set shel [::xserv::invoke tclInterpreterStart]
    } else {
	return $shel
    }
}

# Helper procedure to ensure an interpreter is up and running, or 
# throw a time-out error.
proc tcltk::ensureNewInterp {startscript} {
    set old [::xserv::invoke listTclInterpreters]
    eval $startscript
    set before [clock seconds]
    while {[set newlist [::xserv::invoke \
      listTclInterpreters -excluding $old]] == "" \
      && [clock seconds] - $before < 60} {update}
    if {$newlist eq ""} {
	error "Timed out; no new shell started within 60 seconds."
    }
    return [lindex $newlist 0]
}


# ===========================================================================
# 
# .
