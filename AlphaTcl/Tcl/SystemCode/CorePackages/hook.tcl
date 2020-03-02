## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "hook.tcl"
 #                                    created: 18/7/97 {5:10:18 pm} 
 #                                last update: 01/13/2006 {06:30:45 PM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley, all rights reserved
 #  
 # Description: 
 #  
 #  Allows procedures to be registered and called at a specific time,
 #  according to the current mode.  This means it is no longer necessary
 #  or desireable to rename the standard hook procedures.  Previously
 #  (in Alpha 5.x-6.x) you had to do this:
 #  
 #   if {[info commands blahSaveHook] == ""} {
 #   	rename saveHook blahSaveHook
 #   	proc saveHook {name} { ... ; blahSaveHook $name}
 #   }
 # 
 #  But now you just need to add a line like this to your code:
 #  
 #  	hook::register 'hook-name' 'your proc' 'mode' ?... 'mode'?
 # 
 #  Here are two examples:
 #  
 #  	hook::register savePostHook codeWarrior_modified "C++" "C"
 #  	hook::register savePostHook ftpPostHook
 #  
 #  If you don't include a 'mode', then your proc will be called no
 #  matter what the current mode is.   Avoid this unless absolutely
 #  necessary.  
 #  
 #  Use of such lists as 'savePostHooks' is obsolete.
 #  These lists are ignored, use hook::register instead.
 #  
 #  History
 # 
 #  modified by  rev reason
 #  -------- --- --- -----------
 #  18/7/97  VMD 1.0 original
 #  22/7/97  VMD 1.1 fixed all bugs ;-) and added the above examples.
 # ###################################################################
 ##

namespace eval hook {}
set hook::version 1.2

# ×××× Registering ×××× #

proc hook::register {hook procname args} {
    if {![llength $args]} {lappend args "*"}
    ensureNamespaceExists ::hook::${hook}
    global hook::${hook}
    foreach mode $args {
	if {![info exists hook::${hook}($mode)] || \
	  [lsearch -exact [set hook::${hook}($mode)] $procname] == -1} {
	    lappend hook::${hook}($mode) $procname
	}
    }
}

proc hook::anythingRegistered {hook {_detail ""}} {
    global hook::${hook}
    if {[string length $_detail]} {
	return [info exists hook::${hook}($_detail)]
    } else {
	return [array exists hook::$hook]
    }
}

proc hook::information {{hook ""} {_mode ""}} {
    if {$hook == ""} {
	# just list the names of hooks which exist
	set l [uplevel #0 {info vars hook::*}]
	foreach a $l {
	    if {![uplevel #0 "array exists $a"]} {
		set i [lsearch $l $a]
		set l [lreplace $l $i $i]
	    }
	}
	regsub -all "(::)?hook::" $l "" l
	return [lsort -dictionary $l]
    } else {
	global hook::${hook}
	if {${_mode} == ""} {
	    # return all the attached procs for given hook
	    if {[array exists hook::$hook]} {
		return [array get hook::${hook}]
	    } else {
		return ""
	    }
	} else {
	    if {[info exists hook::${hook}($_mode)]} {
		return [set hook::${hook}($_mode)]
	    } else {
		return ""
	    }
	}
    }
}

proc hook::deregister {hook {procname ""} args} {
    if {![llength $args]} {set args "*"}
    ensureNamespaceExists ::hook::${hook}
    global hook::${hook}
    if {$procname == ""} { 
	# clear all hooks
	unset hook::${hook} 
    } else {		
	foreach mode $args {
	    if {[info exists hook::${hook}($mode)] && \
	      [set i [lsearch -exact [set hook::${hook}($mode)] $procname]] != -1} {
		set new [lreplace [set hook::${hook}($mode)] $i $i]
		if {[llength $new]} {
		    set hook::${hook}($mode) $new
		} else {
		    unset hook::${hook}($mode)
		}
	    }
	}
    }
}

# ×××× Calling hooks ×××× #

set hook::_queued {}

proc hook::_callAllQueued {} {
    variable _queued
    
    # Continue while there's anything in the queue.
    while {[llength $_queued]} {
	set next [lindex $_queued 0]

	# Call first queued hook, which may add further hooks to
	# the queue (modifying the _queued variable).
	set code [catch [linsert $next 0 callNow] res]

	# First item in the queue gives our overall result.
	if {![info exists result]} {
	    set result [list $code $res]
	}
	# Now remove the hook we just called
	set _queued [lreplace $_queued 0 0]
    }
    return -code [lindex $result 0] [lindex $result 1]
}

proc hook::callNow {hook type {modelist ""} args} {
    if {[catch "global hook::${hook}"] || ![llength $modelist]} {
	if {$type eq "untilok"} {
	    error "No hooks were ok"
	} else {
	    return 0
	}
    }

    set err 0
    if {[lsearch -exact $modelist "*"] == -1} {
	lappend modelist "*"
    }
    switch -- $type {
	"all" {
	    foreach _mode $modelist {
		if {[info exists hook::${hook}($_mode)]} {  
		    foreach proc [set hook::${hook}($_mode)] {
			if {[catch {uplevel \#0 [list eval $proc $args]} debug]} {
			    # Uncomment for testing/debugging
			    alpha::log stderr "'$hook' hook error log for '$proc': $debug, $::errorInfo"
			    incr err
			}
		    }
		}
	    }
	    return $err
	}
	"until" {
	    foreach _mode $modelist {
		if {[info exists hook::${hook}($_mode)]} {  
		    foreach proc [set hook::${hook}($_mode)] {
			if {[catch {uplevel \#0 [list eval $proc $args]} res]} {
			    # Uncomment for testing/debugging
			    alpha::log stderr "'$hook' hook error log for '$proc': $res, $::errorInfo"
			} else {
			    if {$res} {
				return 1
			    }
			}
		    }
		}
	    }
	    return 0
	}
	"untilok" {
	    foreach _mode $modelist {
		if {[info exists hook::${hook}($_mode)]} {  
		    foreach proc [set hook::${hook}($_mode)] {
			if {![catch {uplevel \#0 [list eval $proc $args]} res]} {
			    return $res
			}
		    }
		}
	    }
	    error "No hooks were ok"
	}
	default {
	    alertnote "Bug in hook calling: $hook $type"
	}
    }
}  

proc hook::callAll {hook {_mode ""} args} {
    variable _queued
    if {$_mode eq ""} { global mode ; set _mode $mode }
    lappend _queued [linsert $args 0 $hook "all" [list $_mode]]
    if {[llength [set _queued]] == 1} {
	return [_callAllQueued]
    }
}  

# 2004: Still experimental and may be changed before next final release.
proc hook::callForWin {hook type win args} {
    set info [linsert $args 0 $hook $type [win::getHookModes $win]]
    
    # We currently only stack 'all' hooks, since for the other hooks,
    # we typically want a return value.
    if {$type eq "all"} {
	variable _queued

	lappend _queued $info
	if {[llength [set _queued]] == 1} {
	    return [_callAllQueued]
	}
    } else {
	return [eval [list callNow] $info]
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "hook::callUntil" --
 # 
 #  Rather like 'callAll', except it is used to implement a stacked
 #  hook.  This is a hook in which registered procedures are called
 #  one by one, _until_ one of them claims to be able to handle
 #  the request.  It does that by taking action and returning '1'.
 #  Procedures which cannot handle the action return 0.
 #  
 #  Procedures should not throw an error (although currently we
 #  are kind enough to ignore it).
 # -------------------------------------------------------------------------
 ##
proc hook::callUntil {hook {_mode ""} args} {
    variable _queued
    if {$_mode eq ""} { global mode ; set _mode $mode }
    eval [list callNow $hook "until" [list $_mode]] $args
}

proc hook::callUntilOk {hook {_mode ""} args} {
    variable _queued
    if {$_mode eq ""} { global mode ; set _mode $mode }
    eval [list callNow $hook "untilok" [list $_mode]] $args
}

# ×××× Find mode hooks ×××× #

# 2004: Still experimental and may be changed before next final release.
# 
# When called on the non-frontmost window, this will add a
# -w <win> argument.  This means any hooked procedure which
# might be called by this, when non frontmost, must accept
# these optional arguments.  However, procedures which
# will only be called when frontmost (OptionTitlebarProc, say)
# need not take -w <win>.
proc hook::callProcForWin {hook {win ""} args} {
    if {($win ne "") && ($win ne [win::Current])} {
	set args [linsert $args 0 "-w" $win]
    }
    eval [list [procForWin $hook $win]] $args
}

# 2004: Still experimental and may be changed before next final release.
proc hook::procForWin {hook {win ""}} {
    if {$win eq ""} { set win [win::Current] }
    foreach hookMode [win::getHookModes $win] {
	set cmd ::${hookMode}::${hook}
	if {[llength [info commands $cmd]]} {
	    return $cmd
	}
    }
    return ::$hook
}

# ×××× Over-riding procs ×××× #

# Take over from a proc/cmd 'origName', replacing it with 'useName'
proc hook::procRename {origName useName} {
    # Get the command in normalized form
    regsub -all "^:*" "[namespace which -command $origName]" "::" origName
    set newName ::hook::[regsub -all : $useName _]
    if {[llength [info commands $newName]]} {
	return -code error "'$origName' already overridden by $useName"
    }
    hook::_safeRename $origName $newName
    variable procRenames
    set procRenames($useName) [list $origName $newName]
    # Make use of a wonderful Tcl feature.
    interp alias {} $origName {} $useName
    trace add command $origName rename [list hook::_procBeingRenamed $useName]
}

if {[info tclversion] < 8.5} {
    # This bug in Tcl has been fixed.
    proc hook::_safeRename {origName newName} {
	set alias [interp alias {} $origName]
	if {[string length $alias]} {
	    set trace [trace info command $origName]
	    rename $origName $newName
	    # Must re-create the alias, and any traces
	    interp alias {} $newName {} $alias
	    foreach t $trace {
		eval [list trace add command $newName] $t
	    }
	} else {
	    rename $origName $newName
	}
    }
} else {
    proc hook::_safeRename {origName newName} {
	::rename $origName $newName
    }
}

# Call the original proc for 'useName'
proc hook::procOriginal {useName args} {
    variable procRenames
    uplevel 1 [lindex $procRenames($useName) 1] $args
}

# Keep track of any further renaming of the proc so we know what
# to revert to in the end
proc hook::_procBeingRenamed {useName oldname newname op} {
    variable procRenames
    lset procRenames($useName) 0 $newname
}

# Revert from 'useName' to the proc's current name (the original name
# unless it has been renamed in the mean-time), forgetting about
# everything we've done.
proc hook::procRevert {useName} {
    variable procRenames
    rename [lindex $procRenames($useName) 0] ""
    hook::_safeRename \
      [lindex $procRenames($useName) 1] [lindex $procRenames($useName) 0]
    unset procRenames($useName)
}

