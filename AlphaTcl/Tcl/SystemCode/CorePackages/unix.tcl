#  AlphaTcl - core Tcl engine
#================================================================================

proc cp args {
    eval [list file copy] $args
}

proc mv args {
    eval [list file rename] $args
}

proc rm args {
    set opts(-r) 0
    getOpts
    set files {}
    foreach arg $args {
	eval lappend files [glob -nocomplain $arg]
    }
    __rm $opts(-r) $files
}

proc __rm {recurse names} {
    foreach f $names {
	if {[file isdirectory $f]} {
	    if {$recurse} {
		__rm $recurse [glob -nocomplain -dir $f * .*]
	    } 
	    file delete $f
	} else {			
	    status::msg [file tail $f]		
	    file delete $f				
	}			
    }
}

proc textToAlpha {{dir ""}} {
    if {!$::alpha::macos} { return }
    
    set num 0
    if {$::alpha::platform == "alpha"} {
	set creator "ALFA"
    } else {
	set creator "AlTk"
    }
    
    if {![string length $dir]} {
	set dir [get_directory -p "Creators to '$creator':"]
    }
    
    foreach f [glob -nocomplain -dir $dir *] {
	if {[file isfile $f] && ([file::getType $f] == "TEXT") \
	  && ([file::getSig $f] ne $creator)} {
	    status::msg $f
	    setFileInfo $f creator $creator
	    incr num
	} elseif {[file isdirectory $f]} {
	    incr num [textToAlpha $f]
	}
    }
    status::msg "Converted $num files"
    return $num
}
