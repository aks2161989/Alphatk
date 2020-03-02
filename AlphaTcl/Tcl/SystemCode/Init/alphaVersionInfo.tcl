# (PreGui)
# set AlphaTcl version (the version of this library of .tcl files)
# 
# Select "AlphaDev > Alpha Distribution > Update Bugzilla Product Version"
# whenever this changes so that bug reports won't be rejected.
# 
# In addition, it is best to reset the hardcodedCounter in the procedure
# [alpha::rectifyPackageCount] when changing this.  If all you want to do is
# force a package rebuild, then you can just increment that hardcodedCounter
# instead of changing the "alpha::tclversion" version.
set alpha::tclversion 8.1a5

proc setVersionInfo {} {
    global alpha::platform alpha::application ALPHA

    set pat {^(?:(Alpha\w*)\s)?(?:Version\s)?([^\s,]+),}
    regexp -- $pat [version] -> alpha::application alpha::version

    if {![info exists alpha::platform]} {
	set alpha::platform "alpha"
    }
    if {![string length $alpha::application]} {
	set alpha::application "Alphatk"
    }
    if {$alpha::platform eq "alpha"} {
	# Get Alpha's current name. The regexp will fail with the 
	# new [processes] command introduced in Alpha8/X 8.0b15
	set prcsList [processes]
	if {![regexp {"([^"]+)" "ALFA" } $prcsList "" ALPHA]} {
	    set ALPHA ""
	    # Start from the end in case other processes with sig ALFA are 
	    # already running.
	    set last [expr {[llength $prcsList] - 1}]
	    for {set i $last} {$i >= 0} {incr i -1} {
		if {[lindex $prcsList $i 1] eq "ALFA"} {
		    set ALPHA [lindex $prcsList $i 0]
		    break
		}  	        
	    }
	}
    } else {
	set ALPHA [info nameofexecutable]
    }
    rename setVersionInfo ""
}

setVersionInfo
