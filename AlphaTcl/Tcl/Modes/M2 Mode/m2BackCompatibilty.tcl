# to autoload this file 
proc m2BackCompatibility.tcl {} {}

namespace eval M2 {}

# As of M2 mode v4.1.1 no more backward compatibility for Alpha < 7.5

# Reporting that end of this script has been reached
status::msg "m2BackCompatibility.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
    alertnote "m2BackCompatibility.tcl for Programing in Modula-2 loaded"
}

