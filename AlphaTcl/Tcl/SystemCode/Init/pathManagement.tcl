# (PreGui)

# Current values.
if {![info exists alpha::internalEncoding]} {
    set alpha::internalEncoding macRoman
}

# We set for the raw and normalised forms, in case these
# directories are links to directories elsewhere.
set alpha::pathEncoding($HOME) $alpha::internalEncoding
set alpha::pathEncoding([file normalize $HOME]) $alpha::internalEncoding
if {[info exists ALPHATK]} {
    set alpha::pathEncoding($ALPHATK) $alpha::internalEncoding
    set alpha::pathEncoding([file normalize $ALPHATK]) $alpha::internalEncoding
}
set alpha::pathEncoding($PREFS) macRoman ; #[prefs::findEncoding]
foreach domain [list user local] {
    if {($SUPPORT($domain) ne "") && [file exists $SUPPORT($domain)]} {
	set alpha::pathEncoding([set SUPPORT($domain)]) $alpha::internalEncoding
    } 
} 
unset domain

proc alpha::registerEncodingFor {path enc} {
    global alpha::pathEncoding
    # We may want to add 'file normalize' here.
    set alpha::pathEncoding($path) $enc
}

proc alpha::deregisterEncodingFor {path} {
    global alpha::pathEncoding
    unset alpha::pathEncoding($path)
}

proc alpha::encodingFor {filename} {
    global alpha::pathEncoding
    # Find most specific encoding for the given path.  Since paths
    # here are unique, we search for the longest registered path
    # in which the given filename lies.
    set got {}
    foreach path [array names alpha::pathEncoding] {
	if {([string length $path] > [string length $got]) \
	  && [file::pathStartsWith $filename $path]} {
	    set got $path
	}
    }
    if {[string length $got]} {
	return [set alpha::pathEncoding($got)]
    } else {
	return ""
    }
}

proc alpha::ensureHomeOk {} {
    global HOME tcl_platform auto_path
    if {[info exists tcl_platform(isWrapped)]} {
	return
    }
    if {![file exists $HOME]} {
	global alpha::platform
	alertnote "Alpha's home directory '$HOME' does not seem to exist. This\
	  must be found."
	while {1} {
	    if {[catch {
		get_directory -p "Where is Alpha's home directory"} new_home]
	    } {
		return
	    }
	    if {[file exists [file join $new_home Tcl]]} {
		set HOME $new_home
		break
	    }
	    # Probably running on Alphatk
	    if {[file exists [file join $new_home Alpha Tcl]]} {
		set HOME [file join $new_home Alpha]
		break
	    }
	    if {$alpha::platform eq "alpha"} {
		alertnote "That didn't seem to be Alpha's home directory.\
		  The home directory must contain the Alpha application and\
		  the 'Tcl' subdirectory."
	    } else {
		alertnote "That didn't seem to be Alpha's home directory.\
		  The home directory must contain alphatk and \
		  the 'Alpha' subdirectory."
	    }
	}
	# Remove anything which has gone from the auto_path
	set new_auto_path {}
	foreach dir $auto_path {
	    if {[file exists $dir]} {
		lappend new_auto_path $dir
	    }
	}
	set auto_path $new_auto_path
    }
}

# We allow Alpha distributions to come with a pre-built Cache distributed
# in $HOME. This allows first-time Alpha users to avoid a lengthy startup
# and thereby provide a nicer experience.  In the future we might be able
# to extend this to handle a fixed AlphaTcl core and a variable
# user-packages directory.  We copy over a pre-built cache under the
# following conditions: it exists in $HOME, and either no cache currently
# exists in $PREFS, or one exists but it is marked as 'pristine' by the
# existence of a file with that name.  Finally the encoding must be
# the same (we could in the future remove this last constraint).
# If we couldn't re-use the cache, we return 0.  If we can and we
# copied ours over return 1, and we can but in fact the copy is
# identical to what we have return 1 as well.
proc alpha::checkForPreBuiltCache {} {
    global HOME PREFS alpha::cache
    set pcache [file join $PREFS Cache]
    set hcache [file join $HOME Cache]
    set date [file join $pcache date]
    # Ensure prebuilt cache and date file exists
    if {![file exists [file join $hcache date]]} {
	return 0
    }
    # If date file isn't ok return
    if {[file exists $pcache]} {
	if {![file exists $date]} {
	    return 0
	} else {
	    if {[file mtime $date] == [file mtime [file join $hcache date]]} {
		# if the dates are equal, we've already copied it over.
		return 1
	    }
	}
    }
    # If we're actually *using* the prebuilt cache, then of course
    # we don't want to copy it over.
    if {[info exists alpha::cache] && ($alpha::cache eq $hcache)} {
	return 0
    }
    # We don't deal with encoding differences.
    if {[alpha::encodingFor $pcache] ne [alpha::encodingFor $hcache]} {
	return 0
    }
    if {[catch {
	if {[file exists $pcache]} {
	    file delete -force $pcache
	}
	file copy $hcache $pcache
	# Make this tag file and specify the date.
	file mtime [file join $pcache date] \
	  [file mtime [file join $hcache date]]
	# Don't delete the pre-built version, in case the user
	# copies the whole distribution to another computer and
	# we want to go through this time-saving process again.
    }]} {
	catch {file delete -force $pcache}
	return 0
    }
    return 1
}

proc alpha::inAlphaHierarchy {filename} {
    variable coreHierarchy

    foreach v $coreHierarchy {
	global $v
	if {[info exists $v] && [file::pathStartsWith $filename [set $v]]} {
	    return 1
	}
    }
    return 0
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alphaOpen" --
 # 
 #  Open a file, for whatever purpose, and set the encoding correctly.
 #  
 #  We can either be given optional arguments '-encoding $env', or
 #  the 'alpha::encodingFor' test can tell us a different encoding to
 #  use.
 #  
 #  An optional '-eol platform' argument is used to decide the type
 #  of line-endings to use (else we use the current platform default).
 #  
 #  Share Alphatk and Alpha 8 implementation of this
 # -------------------------------------------------------------------------
 ##
proc alphaOpen {filename args} {
    while {1} {
	if {[lindex $args 0] eq "-encoding"} {
	    set encoding [lindex $args 1]
	    set args [lrange $args 2 end]
	} elseif {[lindex $args 0] eq "-eol"} {
	    set eol [lindex $args 1]
	    set args [lrange $args 2 end]
	} else {
	    break
	}
    }
    
    set newFile [expr {$::alpha::macos && ![file exists $filename]}]
    
    set fid [eval [list open $filename] $args]
    
    if {![info exists encoding] || ![string length $encoding]} {
	set encoding [alpha::encodingFor $filename]
    }
    if {![string length $encoding] && [info exists ::defaultEncoding]} {
	set encoding $::defaultEncoding
    }
    if {[string length $encoding]} {
	if {[catch {fconfigure $fid -encoding $encoding} err]} {
	    alertnote "Error setting encoding '$encoding' for\
	      '$filename': $err"
	}
    }
    if {[info exists eol] && ([string length $eol] > 0)} {
	switch -- $eol {
	    "macintosh" {
		fconfigure $fid -translation cr
	    }
	    "unix" {
		fconfigure $fid -translation lf
	    }
	    "windows" {
		fconfigure $fid -translation crlf
	    }
	}
    }
    
    if {$newFile} {
	# On MacOS (classic or OS X) we want to set the type and creator
	# of the file, to TEXT/AlTk.
	set creator [expr {($::alpha::platform eq "alpha") ? "ALFA" : "AlTk"}]
	catch {
	    if {([info tclversion] < 8.5)} {
		setFileInfo $filename type "TEXT"
		setFileInfo $filename creator $creator
	    } else {
		file attributes $filename -type TEXT -creator $creator
	    }
	}
    }
    return $fid
}

# We have copied this in from fileManipulation.tcl because we
# need it very early in startup!

namespace eval file {}

## 
 # -------------------------------------------------------------------------
 # 
 # "file::pathStartsWith" --
 # 
 #  This proc must not throw an error!
 #  
 #  Checks in cross-platform way whether the given file $name lies
 #  in the given directory.  Complicated by Windows.  This proc is
 #  crucially important to the ability of AlphaTcl to operate with
 #  a different encoding to the system.
 # -------------------------------------------------------------------------
 ##
proc file::pathStartsWith {name prepath {relative ""}} {
    global tcl_platform
    if {$tcl_platform(platform) eq "windows"} {
	if {[file exists $name]} {
	    if {[lsearch -exact [file attributes $name] "-longname"] != -1} {
		# Catch this in case we're in a vfs.
		catch {set name [file join [file attributes $name -longname]]}
	    }
	}
	if {[file exists $prepath]} {
	    if {[lsearch -exact [file attributes $prepath] "-longname"] != -1} {
		# Catch this in case we're in a vfs.
		catch {set prepath [file join [file attributes $prepath -longname]]}
	    }
	}
    }
	 
    if {[file pathtype $name] eq "relative"} {
	set name [file join [pwd] $name]
    } else {
	set name [file join $name]
    }

    append in [file join $prepath]
    # If they're the same length, then check whether they are
    # equal.  Otherwise we assume 'prepath' is a directory.
    if {[string length $name] == [string length $in]} {
	if {[string first $in $name] == 0} {
	    if {[string length $relative]} {
		upvar 1 $relative here
		set here ""
	    }
	    return 1
	}
    }

    if {$tcl_platform(platform) eq "macintosh"} {
	if {![regexp "[file separator]\$" $in]} {
	    append in [file separator]
	}
        set sep [file separator]
    } elseif {$tcl_platform(platform) eq "windows"} {
	# We need to make this proc more robust on windows.
        set sep /
	append in $sep
    } else {
        set sep [file separator] 
        append in $sep
    }

    if {[string first $in $name] != 0} {
	if {![file exists $prepath] || ([file type $prepath] != "link")} {
	    return 0
	}
	set in [file readlink $prepath]
	if {![regexp "$sep\$" $in]} {
	    append in $sep
	}
	if {[string first $in $name] != 0} {
	    return 0
	}
    }
    
    # We've found it
    if {[string length $relative]} {
	upvar 1 $relative here
	if {$tcl_platform(platform) eq "macintosh"} {
	    set here [string range $name \
	      [expr {[string length $in] -1}] end]
	} else {
	    set here [string range $name [string length $in] end]
	}
    }
    return 1
}

#############################################################################
#  Read and return the complete contents of the specified file.
#
proc file::readAll {fileName {enc ""}} {
    if {[file exists $fileName] && [file readable $fileName]} {
	if {$enc != ""} {
	    set fileid [::open $fileName "r"]
	    fconfigure $fileid -encoding $enc
	} else {
	    set fileid [::alphaOpen $fileName "r"]
	}
	set contents [::read $fileid]
	::close $fileid
	return $contents
    } else {
	error "No readable file '$fileName' found"
    }
}
