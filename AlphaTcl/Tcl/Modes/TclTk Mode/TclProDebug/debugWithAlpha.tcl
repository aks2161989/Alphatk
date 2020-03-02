# Add ability to communicate with the tclProDebugger

namespace eval alphadebug {}

set alphadebug::library [file dirname [info script]]

# Run an external script and connect with it from within Alpha
proc alphadebug::startDebug {script} {
    variable library
    set in [tcltk::launchNewShell]
    tcltk::evaluateIn $in [list console show]
    tcltk::evaluateIn $in  [list lappend auto_path $library]
    tcltk::evaluateIn $in  [list lappend auto_path [file join $library debugger]]
    tcltk::evaluateIn $in  [list source [file join $library debugger initdebug.tcl]]
    tcltk::evaluateIn $in update
    status::msg "Starting communication with debugger -- this make take\
      several seconds to complete"
    tcltk::evaluateIn $in \
      [list if {[debugger_init]} [list source $script]] 0
    return $in
}


# Start the debug server within the Alpha process.
proc alphadebug::startDebugServer {} {
    variable library
    script::run [file join $library startDebugger.tcl] -leaverunning
    status::msg "Debugger started"
}

proc alphadebug::isDebuggerRunning {} {
    if {![interp exists startDebugger.tcl]} { return 0 }
    if {[catch {interp eval startDebugger.tcl {winfo exists .}} res]} {
	return 0
    }
    if {$res} {
	set status [interp eval startDebugger.tcl {dbg::getServerPortStatus}]
	if {[lindex $status 1] != "2576"} {
	    set ok [interp eval startDebugger.tcl {dbg::setServerPort 2576}]
	    if {!$ok} {
		error "Coulnd't start debugger listening"
	    }
	}
    }
    return $res
}

proc alphadebug::test {} {
    variable library
    alphadebug::startDebug [file join $library testDebugger.tcl]
}

proc alphadebug::buildExtensions {} {
    variable library
    cd $library
    cd sourceFiles
    
    exec tclkitsh ../critcl.kit -pkg parser
}

# Convert a clean tclpro debugger tree into what we need.
proc alphadebug::convertTclProTree {} {
    variable library
    set root [file join $library debugger]
    set contents [file::readAll [file join $root debugger.tcl.in]]
    regsub -all "@VERSION@" $contents "0.1" contents
    file::writeAll [file join $root debugger.tcl] $contents 1
    
    auto_mkindex [file join $library debugger]
}

proc alphadebug::copyTclProTree {tclprodir} {
    variable library
    
    # copy debugger
    file delete -force [file join $library debugger]
    file mkdir [file join $library debugger]
    foreach f [glob -dir [file join $tclprodir tcldebugger] -type f *] {
	file copy $f [file join $library debugger]
    }
    # copy projectInfo
    file delete -force [file join $library projectInfo]
    file mkdir [file join $library projectInfo]
    foreach f [glob -dir [file join $tclprodir modules projectInfo] -type f *] {
	file copy $f [file join $library projectInfo]
    }
}
