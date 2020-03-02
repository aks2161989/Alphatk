# Some of this derived from "init.tcl" in the standard Tcl distribution,
# and therefore:
# Copyright (c) 1991-2006 The Regents of the University of California.
# Copyright (c) 1994-1997 Sun Microsystems, Inc.
# Some additions copyright (c) 1997-2004 Vince Darley.
# 
# Over-rides some components of Tcl's auto_load/unknown functionality
# with components which better integrate with AlphaTcl.

namespace eval procs {}

# Alphatk/8/X all use standard Tcl indices and so procs like
# auto_load etc are already loaded.
# 
# AlphaTcl still uses a different version of
# auto_mkindex/auto_reset to the core (they contain more
# error-checking, for example), but the tclIndex file formats
# are identical, and the core's unknown is therefore used.

proc procs::findIn {cmd pathlist} {
    for {set i [expr {[llength $pathlist] - 1}]} {$i >= 0} {incr i -1} {
	set dir [lindex $pathlist $i]
	set f ""
	if {[catch {set f [alphaOpen [file join $dir tclIndex]]}]} {
	    continue
	} else {
	    set error [catch {
		set id [gets $f]
		if {$id == "# Tcl autoload index file, version 2.0"} {
		    eval [read $f]
		} elseif {$id == \
		    "# Tcl autoload index file: each line identifies a Tcl"} {
		    while {[gets $f line] >= 0} {
			if {([string index $line 0] == "#")
				|| ([llength $line] != 2)} {
			    continue
			}
			set name [lindex $line 0]
			set auto_index($name) \
			    "source [file join $dir [lindex $line 1]]"
		    }
		} else {
		    error \
		      "[file join $dir tclIndex] isn't a proper Tcl index file"
		}
	    }]
	    if {$f != ""} {
		close $f
	    }
	    if {$error} {
		continue
	    }
	}
    }
    set namespace [uplevel {namespace current}]
    set nameList [auto_qualify $cmd $namespace]
    # workaround non canonical auto_index entries that might be around
    # from older auto_mkindex versions
    lappend nameList $cmd
    foreach name $nameList {
	if {[info exists auto_index($name)]} {
	    return [lindex $auto_index($name) 1]
	}
    }
    return ""
}

proc procs::find {cmd} {
    set entry [uplevel 1 [list findIndexEntry $cmd]]
    if {[string length $entry]} {
	return [lindex $entry 1]
    }
    return ""
}

# Basically the same as 'auto_load', but doesn't load the
# command, instead it returns the index entry which should
# be used.
proc findIndexEntry {cmd {namespace ""}} {
    global auto_index auto_path

    if {[string length $namespace] == 0} {
	set namespace [uplevel {namespace current}]
    }
    set nameList [auto_qualify $cmd $namespace]
    # workaround non canonical auto_index entries that might be around
    # from older auto_mkindex versions
    lappend nameList $cmd
    foreach name $nameList {
	if {[info exists auto_index($name)]} {
	    return $auto_index($name)
	}
    }
    if {![info exists auto_path]} {
	return 0
    }

    if {![auto_load_index]} {
	return 0
    }

    foreach name $nameList {
	if {[info exists auto_index($name)]} {
	    return $auto_index($name)
	}
    }
    return ""
}

if {[info tclversion] > 8.4} {
    # We do not want to have auto_reset destroy the core Alphatk procedures,
    # so we use this modified version.
    proc auto_reset {} {
	variable ::tcl::auto_oldpath
	global auto_execs auto_index 
	unset -nocomplain auto_execs
	unset -nocomplain auto_index
	unset -nocomplain auto_oldpath
    }
} else {
    # We do not want to have auto_reset destroy the core Alphatk procedures,
    # so we use this modified version.
    proc auto_reset {} {
	global auto_execs auto_index auto_oldpath
	unset -nocomplain auto_execs
	unset -nocomplain auto_index
	unset -nocomplain auto_oldpath
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alpha::useFilesFor" --
 # 
 # Returns a list of a single file which is to be used in place of the one
 # given for sourcing/reading.  This procedure (and its use in [source] and
 # AlphaTcl package index building routines) allows the user or sysadmin to
 # install packages 'on top of' a read-only AlphaTcl distribution.  These
 # packages have to be placed in a SUPPORT folder.  The user's version will
 # always take precedence, followed by the sysadmin's, and then the default
 # file contained in the read-only distribution.  
 #  
 # The package Smarter Source will over-ride this when it is activated, and
 # may return a list of multiple files to be used.
 # 
 # Only those files in "$HOME/Tcl" and "$SUPPORT(local)/AlphaTcl/Tcl" will be
 # queried for a substitution.  There are some files that we never want to
 # over-ride, such as "tclIndex" files.
 # 
 # This function must certainly *not* ever throw an error.  [file readable]
 # will return "0" if the specified filename doesn't exist.  "args" is
 # included only for future back compatibility purposes, in case we decide to
 # include additional arguments.
 # 
 # --------------------------------------------------------------------------
 ##

proc alpha::useFilesFor {filename args} {
    global HOME SUPPORT
    
    if {([file tail $filename] eq "tclIndex")} {
	return [list $filename]
    }
    set homeHome  [file join $HOME Tcl]
    set localHome [file join $SUPPORT(local) AlphaTcl Tcl]
    set userHome  [file join $SUPPORT(user)  AlphaTcl Tcl]
    # Is there a copy of the original in "$SUPPORT(local)/AlphaTcl/Tcl" ?
    if {($SUPPORT(local) ne "") \
      && [file::pathStartsWith $filename $homeHome relName] \
      && [file readable [file join $localHome $relName]]} {
	set filename [file join $localHome $relName]
    }
    # Is there a copy of the original in "$SUPPORT(user)/AlphaTcl/Tcl" ?
    if {($SUPPORT(user) ne "") \
      && ([info exists relName] \
      || [file::pathStartsWith $filename $homeHome relName] \
      || [file::pathStartsWith $filename $localHome relName]) \
      && [file readable [file join $userHome $relName]]} {
	set filename [file join $userHome $relName]
    }
    return [list $filename]
}

proc alpha::makeAutoPath {{skipPrefs 0}} {
    global HOME PREFS SUPPORT auto_path

    set root [file join $HOME Tcl]

    # Not really clear why this is necessary?
    if {[file type $root] eq "link"} {
	set root [file readlink $root]
    }
    
    foreach dir {SystemCode Modes Menus Completions Packages "User Packages"} {
	if {($dir == "Packages") || ($dir == "User Packages")} {
	    if {$skipPrefs} {
		# If we're skipping preferences these two folders
		# are not added to the auto path.
		continue
	    }
	}
	if {$dir == "User Packages"} {
	    set p [file join $PREFS $dir]
	} else {
	    set p [file join $root $dir]
	}
	eval [list lappend add $p] \
	  [glob -types d -nocomplain -dir $p *] \
	  [glob -types d -nocomplain -join -dir $p * *]
    }
    foreach domain [list user local] {
	if {($SUPPORT($domain) ne "") \
	  && [file exists [file join $SUPPORT($domain) AlphaTcl Tcl]]} {
	    foreach dir [list SystemCode Modes Menus Completions Packages] {
		set p  [file join $SUPPORT($domain) AlphaTcl Tcl $dir]
		eval [list lappend add $p] \
		  [glob -types d -nocomplain -dir $p *] \
		  [glob -types d -nocomplain -join -dir $p * *]
	    }
	} 
    } 
    if {[file exists [file join $HOME Tclextensions]]} {
	lappend add [file join $HOME Tclextensions]
    }
    foreach d $add {
	if {[file tail $d] eq "CVS"} {
	    # Don't include any CVS directories
	    continue 
	}
	if {[lsearch -exact $auto_path $d] == -1} {
	    lappend new_paths $d
	}
    }
    if {[info exists new_paths]} {
	set auto_path [eval [list linsert $auto_path 0] $new_paths]
    }
}

