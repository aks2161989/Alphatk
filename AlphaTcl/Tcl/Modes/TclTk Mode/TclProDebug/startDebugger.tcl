
lappend auto_path [file dirname [info script]]

# dummy - not that important
package provide dbgext 1.0
# dummy - very important!
if {[catch {package require parser 1.4}]} {
    tk_messageBox -message "Couldn't find the 'parser' Tcl extension;\
      part of the TclPro tools.  I will create a dummy, but most\
      functionality will not be available."
    package provide parser 1.0
    proc parse {args} {
	return -code error "can't parse"
    }
}

cd [file join [file dirname [info script]] debugger]
source codeWin.tcl
# now override some things
#proc code::createWindow {masterFrm} {}

source debugger.tcl
set argv0 ""

if {1} {
    source ../startup.tcl
    proc exit {args} {destroy .}
} else {

    proc exit {args} {destroy .}

    debugger::init "" ""
}

dbg::setServerPort 2576
