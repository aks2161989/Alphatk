## -*-Tcl-*-
 # ###################################################################
 # 
 #  FILE: "temp.tcl"
 #                                    created: 10/28/2000 {14:17:40 PM} 
 #                                last update: 2005-08-16 14:33:37 
 #  Author: Vince Darley
 #  
 #  Handling of temporary files in AlphaTcl.  Used by ftpMenu, tex
 #  mode.  Goal is to provide utilities useful for extension authors,
 #  and to allow a future version of AlphaTcl to provide only limited
 #  access to the filesystem (and hence use a 'Safe Tcl' model of
 #  extensions, so a malicious extension cannot be written).
 #  
 #  Code under development; the API may change.
 # ###################################################################
 ##

namespace eval temp {}

proc temp::_path {pkg args} {
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    regsub -all "/" $args ":" args
	    set nargs {}
	    foreach a $args {
		# Truncate the arg to 31 chars max
		set a [string range $a 0 30]
		if {[regexp {^[^:].*:} $a]} {
		    lappend nargs ":$a"
		} else {
		    lappend nargs $a
		}
	    }
	    set args $nargs
	}
	"unix" {
	    regsub -all "~" $args "tilde" args
	}
	"windows" {
	    regsub -all ":" $args "-" args
	    regsub -all "~" $args "tilde" args
	    set nargs {}
	    foreach a $args {
		# Truncate the arg to 31 chars max - may not
		# be entirely necessary, but Win does have path
		# limitations.
		lappend nargs $a [string range $a 0 30]
	    }
	    set args $nargs
	}
    }
    global PREFS
    set name [eval [list file join $PREFS tmp $pkg] $args]
    return $name
}

proc temp::path {pkg args} {
    set name [eval [list temp::_path $pkg] $args]
    file::ensureDirExists [file dirname $name]
    return $name
}

proc temp::directory {pkg args} {
    set name [eval [list temp::_path $pkg] $args]
    file::ensureDirExists $name
    return $name
}

# Is the given path 'path' in the temporary package 'pkg'.
proc temp::isIn {pkg path} {
    global PREFS
    file::pathStartsWith $path [file join $PREFS tmp $pkg]
}

# Do NOT give a complete path as $name argument
proc temp::nonunique {pkg name {suffix ""}} {
    global PREFS
    set result [file join $PREFS tmp $pkg ${name}${suffix}]
    file::ensureDirExists [file dirname $result]
    return $result
}

# Do NOT give a complete path as $name argument
proc temp::unique {pkg name {suffix ""}} {
    global PREFS
    set count 1
    while {[file exists [set result \
      [file join $PREFS tmp $pkg ${name}${count}${suffix}]]]} {
	incr count
    }
    file::ensureDirExists [file dirname $result]
    return $result
}

proc temp::uniqueDirectory {pkg name} {
    global PREFS
    set count 1
    while {[file exists [set result [file join $PREFS tmp $pkg $name$count]]]} {
	incr count
    }
    file::ensureDirExists $result
    return $result
}

proc temp::cleanup {pkg} {
    global PREFS
    if {[file exists [file join $PREFS tmp $pkg]]} {
	catch {file delete -force [file join $PREFS tmp $pkg]}
    }
}

proc temp::cleanupAll {} {
    global PREFS
    catch {file delete -force [file join $PREFS tmp]}
}

proc temp::generate {pkg name code} {
    global PREFS
    set num 0
    foreach char [split $code {}] {
	 scan $char "%c" char
	 incr num $char
    }
    set name [file join $PREFS tmp $pkg $name.$num]
    file::ensureDirExists [file dirname $name]
    return $name
}



