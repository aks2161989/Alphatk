## -*-Tcl-*-
 # ###################################################################
 # 
 #  FILE: "scriptRunner.tcl"
 #                                    created: 00-11-27 18.42.17 
 #                                last update: 02/15/2005 {06:39:29 PM} 
 #  Author: Vince Darley
 #  E-mail: vince@biosgroup.com
 #    mail: Bios Group
 #          617 Paseo de Peralta, Santa Fe, NM 87501
 #     www: http://www.biosgroup.com/
 #  
 # Copyright (c) 2000-2003  Vince Darley
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # Distributable under Tcl-style (free) license.
 #  
 # ###################################################################
 ##

alpha::extension scriptRunner 0.1.2 {} help {
    This auto-loading extension provides some utility procs which enable
    Alpha to run generic Tcl/Tk scripts in a separate interpreter, and
    capture the output.  Useful for those using external Tcl/Tk utilities, or
    those programming in Tcl/Tk.
    
    Slave interpreters are used -- of course if your slave crashes, the whole
    application will crash.  See the "scriptRunner.tcl" file for more
    information about the procs that are available, and what they do.
}


namespace eval script {}

proc script::done {args} {}

proc script::run {name args} {
    global tcl_platform HOME
    
    getOpts {-script}
    set i [file tail $name]
    if {![file exists $name]} {
	if {[file exists [file join $HOME Tools $name]]} {
	    set name [file join $HOME Tools $name]
	} elseif {[file exists [file join $HOME Tools $name.tcl]]} {
	    set name [file join $HOME Tools $name.tcl]
	}
    }

    catch [list script::evaluate [list catch [list interp create $i]]] err
    
    if {$err == 1} {
	global errorInfo
	if {[string match "interpreter named*" $errorInfo]} {
	    set errorInfo ""
	    script::done ; update
	    status::msg "Deleting existing interpreter"
	    script::evaluate [list catch [list $i eval exit]]
	    script::evaluate [list catch [list $i eval [list destroy .]]]
	    update
	    script::evaluate [list catch [list interp delete $i]]
	    script::evaluate [list catch [list interp create $i]]
	} else {
	    puts $errorInfo
	    error $err
	}
    }
    
    status::msg "Interpreter created ok"
    
    if {$tcl_platform(platform) == "macintosh"} {
	script::evaluate [list catch [list package require MacOSDefaults]]
    }

    script::copy_variables i name args
    
    # load in Tk unless we don't want it
    if {![info exists opts(-noTk)]} {
	script::evaluate {
	    load {} Tk $i
            $i eval [list wm protocol . WM_DELETE_WINDOW exit]
	    proc option {args} {}
	}
    }
    # provide the script with our extensions, just in case
    script::evaluate [list $i eval \
      [list lappend auto_path [file join $HOME Tclextensions]]]
    
    # if there's an extra script, do that
    if {[info exists opts(-script)]} {
	script::evaluate [list $i eval $opts(-script)]
    }
    
    if {![info exists opts(-noTk)]} {
	proc ::script::done {args} {
	    global alphaPriv
	    set alphaPriv(scriptDone) 1
	}
    } else {
	proc ::script::done {args} [list interp delete $i]
    }

    script::evaluate {
	namespace eval script {}

	$i eval [list set argc [llength $args]]
	$i eval [list set argv $args]
	# catch exit conditions
	interp alias $i exit "" script::done
	
	# run it
	$i eval [list source $name]
	# wait till it's done
    }
    
    if {[info exists opts(-leaverunning)]} {
	return
    }
    
    if {![info exists opts(-noTk)]} {
	global alphaPriv
	vwait alphaPriv(scriptDone)
	catch [list interp delete $i]
	catch {unset alphaPriv(scriptDone)}
	status::msg "Done"
    } else {
	catch [list interp delete $i]
	status::msg "Done"
    }
}

proc script::copy_variables {args} {
    #foreach v $args {
	#uplevel 1 "script::evaluate \"set $v \[list \[set $v\]\]\""
    #}
}

proc script::evaluate {what} {
    return [uplevel 1 $what]
}
