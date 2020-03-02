# to autoload this file (tabsize:4) 
proc m2ShellUse.tcl {} {}

#===============================================================================
# ×××× Communication with shell, for launching and compiler error display ×××× #
#===============================================================================

namespace eval M2 {}

# the following is only used to switch m2ShellUse.tcl into a debug mode
set M2DoDebugging 0

# force loading of mode or variables won't be defined
M2::loadMode	
set m2ErrRing ""

# This procedure is called by the event handlers. It could contain any 
# script to be executed.  However, currently (March 89), MacMETH shell 
# as well as the RAMSES shell do not use anything else than AlphaEdit,
# which in its current implementation writes only openWorkFiles into
# the "token.ALPHA" file. Thus omitting the use of this proc speeds 
# things up.
proc M2::handleM2TokenFile {} {
	global M2TokenFile
#	alertnote "In M2::handleM2TokenFile"
	if {[file exists "$M2TokenFile"]} {
		source  "$M2TokenFile"
		file delete "$M2TokenFile"
	}
}



# Set up responding to events received from the Modula-2 shell
# In particular the class "oM2f" (stands for open M2 files)
# with event "comp" (after compilation) lets you display
# automatically the involved work files and show the errors
# Implementation of Alpha command eventHandler did only
# really work after version "Alpha (68k) 6.2b2, Jun 8, 1996"
# Appears to have worked in the PPC version of Alpha always
# ------------------------------------------------------------

proc M2::checkForErrALPHA {} {
	global M2ErrFile
	if {[info exists M2ErrFile] && [file exists $M2ErrFile]} then {
		return 1
	} else {
		return 0
	}
}

proc M2::checkForTokenALPHA {} {
	global M2TokenFile
	if {[info exists M2TokenFile] && [file exists $M2TokenFile]} then {
		return 1
	} else {
		return 0
	}
}

proc M2::checkForM2Shell {} {
	global M2ShellName
	if {[info exists M2ShellName] && [file exists $M2ShellName]} then {
		return 1
	} else {
		return 0
	}
}

proc M2::checkForErrDOKFile {} {
	global M2errDOKFile
	if {[info exists M2errDOKFile] && [file exists $M2errDOKFile]} then {
		return 1
	} else {
		return 0
	}
}


# The initially used eventhandler to ensure proper configuration if launched via M2 shell
proc M2::m2EventHandler {dummy} {
    M2::installAEventHandler M2::m2EventHandlerSimple 0
	if {![M2::checkForErrALPHA] | ![M2::checkForM2Shell] | ![M2::checkForErrDOKFile]} {
		M2::checkM2Configuration
	}
	# Alternative for handling more complicated cases than just M2::openWorkFiles
	# M2::handleM2TokenFile
    M2::openWorkFiles
}

# Normally used eventhandler, more efficient, since does no configuration checking anymore
proc M2::m2EventHandlerSimple {dummy} {
    global M2DoDebugging
	# Alternative for handling more complicated cases than just M2::openWorkFiles
	# M2::handleM2TokenFile
    M2::openWorkFiles
}


# M2::m2EventHandlerAlpha8 moved to m2Mode.tcl

proc M2::installAEventHandler {theHandler verbous} {
	global M2::curAlphaV
	global M2DoDebugging
	set class "oM2f"
	set event "comp"
	# You can't compare with '6.2b2' very effectively.
	set firstAlphaWorkingV "6.2"
	set firstAlphaUsingTclAEV "8.0"
	if {![info exists M2::curAlphaV] || ([set M2::curAlphaV] == "")} {
	    return
	    if $M2DoDebugging { alertnote "in M2::installAEventHandler: wrong Alpha version" }
	} elseif {[set M2::curAlphaV] >= $firstAlphaWorkingV} {
	    status::msg "Modula-2 working files are automatically opened in this version of Alpha"
	    if $M2DoDebugging { alertnote "in M2::installAEventHandler: before declaring event handler" }
	    # Here comes now the actual declaration
	    if {[set M2::curAlphaV] >= $firstAlphaUsingTclAEV} {
		tclAE::installEventHandler $class $event ${theHandler}
	    } else {
		eventHandler $class $event "$theHandler"
	    }
	} else {
		if $M2DoDebugging { alertnote "in M2::installAEventHandler: outdated Alpha" }
		if $verbous {
		    set msg "Modula-2 working files are NOT automatically opened in this outdated "
		    set msg "$msg version of Alpha! "
		    set msg "$msg Please upgrade to a version >=$firstAlphaWorkingV."
			alertnote $msg
		}	
	}
}


#================================================================================
proc M2::callM2Shell {} {
	global M2ShellName
	launch  -f "$M2ShellName"
}

proc M2::reportOnShellLaunchFail {} {
	global M2ShellName
	beep
	set msg "Call of M2 shell failed!\r"
	if {[info exists M2ShellName]} then { 
		set testfile $M2ShellName 
	} else {
		set testfile ""
	}
	if {![file exists "$testfile"]} then {
		if {"$M2ShellName" == ""} then {
			append msg "M2 mode works fully only if MacMETH or RAMSES are installed. Both appear to be missing"
			alertnote "${msg}." 
		} else {
			append msg "Hint: Open a scratch window, enter M2 mode and try menu M2 -> Configure launching"
			alertnote "$msg." 
		}
	} else {	
		append msg "Please enter at least once M2 mode, or reconfigure launching"
	    alertnote "$msg, and/or make sure sufficient RAM and disk space are available."
	}
}

proc M2::launchShell {} {
	if {[catch M2::callM2Shell]} { M2::reportOnShellLaunchFail }
}

proc M2::launchShellAndSimulate {} {
	global M2ShellName
	if {[info exists M2ShellName]} then { 
		set shellName [file tail $M2ShellName]
	    # requires a dummy string in order to avoid dialog for selecting the
	    # receiving application
		if {[catch {
			tclAE::send $shellName DMEv COMP ---- [tclAE::build::TEXT dumy]
		}]} then {
		}
	 	# The following alternative does not work, althouth it should (Bug in Alpha)
	    # dosc -c "RAMS" -k 'DMEv' -e 'COMP' -r -s "gaga"
	    # dosc -n "$shellName" -k 'DMEv' -e 'COMP' -r -s "gaga"
        # dosc -n $appName -k 'aevt' -e 'odoc' -r -f $currentWin
	}
	if {[catch M2::callM2Shell]} { M2::reportOnShellLaunchFail }
}

proc M2::AskRAMSESToOpenFile {relPath moduleName} {
	global M2ShellName
	set module [file dirname $M2ShellName]
    set module "$module$relPath$moduleName"
	set shellName [file tail $M2ShellName]
	tclAE::send $shellName aevt odoc ---- [tclAE::build::alis $module]
	if {[catch M2::callM2Shell]} { M2::reportOnShellLaunchFail }
}

# M2::AskRAMSESToOpenFile ":" "User.Profile"
# M2::AskRAMSESToOpenFile ":Work:" "Logistic.OBM"
# M2::AskRAMSESToOpenFile ":Work:" "Logistic.DAT"



# Reporting that end of this script has been reached
status::msg "m2ShellUse.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
    alertnote "m2ShellUse.tcl for Programing in Modula-2 loaded"
}
