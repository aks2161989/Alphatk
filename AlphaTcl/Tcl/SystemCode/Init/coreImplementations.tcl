## -*-Tcl-*- (PreGui)
 # ###################################################################
 #  AlphaTcl - 
 # 
 #  FILE: "coreImplementations.tcl"
 #                                    created: 10/02/2002 {09:44:53 AM} 
 #                                last update: 03/01/2006 {09:51:27 AM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #          98 Gloucester Terrace, London
 #     www: http://www.santafe.edu/~vince/
 #  
 #  Description: contains implementations of important procedures which
 #  are required by AlphaTcl but not implemented in the core of Alpha (or
 #  where simpler 'building-block' commands are implemented by Alpha, but
 #  we wrap them here to provide the appropriate functionality).
 # 
 # ###################################################################
 ##

proc coreImplementations.tcl {} {}

#¥ capture errors which are thrown in the Tcl event loop
proc bgerror {err} {
    error::occurred $err
}

proc ensureNamespaceExists {cmdOrVar} {
    set ns ""
    # Allow two or more colons as namespace separators
    while {[regexp -- "^((::+)?$ns\[a-zA-Z_\]+::+)" $cmdOrVar ns]} {
	namespace eval $ns {}
    }
}

proc alpha::evaluateWhenGuiIsReady {args} {
    global alpha::guiNotReady
    if {[info exists alpha::guiNotReady]} {
	foreach a $args {
	    hook::register startupHook $a
	}
    } else {
	foreach a $args {
	    uplevel 1 $a
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "new" --
 # 
 # Any additional flags received by this proc are assumed to be arguments to
 # be passed to 'setWinInfo', except without the leading '-'.  So, for
 # instance you can do:
 # 
 #     new -n "blah" -m TeX -tabsize 4 -shell 1
 #     
 # Also args '-text' to set the text, or a useful new flag '-info' which
 # takes the text as the next arg, and automatically sets the window to a
 # read-only shell window, and scrolls to the top after inserting the given
 # text.  Useful for all those 'info' windows Alpha uses!
 # 
 # --------------------------------------------------------------------------
 ##

rename new __new
;proc new {args} {
    global alpha::guiNotReady tcl_platform
    if {[info exists alpha::guiNotReady]} {
	# We don't open windows during startup
	hook::register startupHook "new $args ; #"
	return
    }
    set i 0
    set where {}
    # Set default platform.  A "-platform" argument will over-ride this.
    switch -- $tcl_platform(platform) {
	"macintosh" {set other(-platform) "mac"}
	"unix"      {set other(-platform) "unix"}
	"windows"   {set other(-platform) "dos"}
    }
    while {[set arg [lindex $args $i]] != ""} {
	incr i
	switch -- $arg {
	    "-n" {
		set name [lindex $args $i]
		incr i
	    }
	    "-tabbed" {
		# Tabbed windows are supported by Alphatk.  Alpha 8/X
		# will just throw an error, so that's ok.
		eval lappend where "-tabbed" [lindex $args $i]
		incr i
	    }
	    "-g" {
		eval lappend where "-g" [lrange $args $i [incr i 3]]
		incr i
	    }
	    "-mode" -
	    "-m" { 
		set mode [lindex $args $i]
		set mi $i
		incr i
	    }
	    "-shrink" {
		set shrink 1
	    }
	    default {
		if {[string index $arg 0] eq "-"} {
		    set other($arg) [lindex $args $i]
		    incr i
		} else {
		    return -code error "Bad argument '$arg' given\
		      to 'new'"
		}
	    }
	}
    }
    if {![info exists name]} {
	set name "untitled"
    }
    set newname $name
    
    # Ensure the name doesn't match either the tail or the full
    # name of any existing window.  Since '$name' is not a file
    # by definition (we're using 'new'), we compare the full name
    # against both all tails and all full names
    if {([lsearch -exact [winNames] $name] != -1) \
      || ([lsearch -exact [winNames -f] $name] != -1)} {
	set i 2
	while {([lsearch -exact [winNames] "$name <$i>"] != -1) \
	  || ([lsearch -exact [winNames -f] "$name <$i>"] != -1)} {
	    incr i
	}
	append name " <${i}>"
    }
    
    if {[info exists mode] && ($mode ne "")} {
	# This will handle a mode-specific tab size and any other
	# mode-specific variables, provided Alpha 8/tk call
	# winCreatedHook at the appropriate time.
	win::setInitialConfig $name mode $mode "command"
    }
    
    if {[info exists other(-platform)]} {
	win::setInitialConfig $name platform $other(-platform) "command"
	unset other(-platform)
    }
    if {[info exists other(-tabsize)]} {
	win::setInitialConfig $name tabsize $other(-tabsize) "command"
	unset other(-tabsize)
    }
    if {[info exists other(-fontsize)]} {
	win::setInitialConfig $name fontsize $other(-fontsize) "command"
	unset other(-fontsize)
    }
    if {[info exists other(-visibility)]} {
	win::setInitialConfig $name visibility \
	  $other(-visibility) "command"
	unset other(-visibility)
    }

    global alpha::platform
    if {$alpha::platform ne "alpha"} {
	set newname $name
    }
    if {[info exists other(-info)]} {
	eval __new -n [list $newname -text $other(-info)] $where
	set other(-info) ""
    } elseif {[info exists other(-text)]} {
	eval __new -n [list $newname -text $other(-text)] $where
	goto -w $name [maxPos -w $name]
	unset other(-text)
    } else {
	eval __new -n [list $newname] $where
    }
    if {[info exists other(-info)]} {
	# Make sure window is not dirty before locking.
	setWinInfo -w $name dirty 0
	setWinInfo -w $name read-only 1
	goto -w $name [minPos]
	unset other(-info)
    }
    # We must do shell first, then text, then dirty and then others
    # in any order.  Else we'd get errors like can't make window read-only
    # when dirty if they were in the wrong order...
    if {[info exists other(-shell)]} {
	# Shell windows cannot be dirty, so make sure this hasn't
	# been set to dirty, since Alpha 8/X's core have a bug
	# where dirtiness is forgotten when setting to shell state.
	if {$other(-shell) == 1} {
	    setWinInfo -w $name dirty 0
	    unset -nocomplain other(-dirty)
	}
	setWinInfo -w $name shell $other(-shell)
	unset other(-shell)
    }
    if {[info exists other(-text)]} {
	insertText -w $name $other(-text)
	unset other(-text)
    }
    if {[info exists other(-dirty)]} {
	setWinInfo -w $name dirty $other(-dirty)
	unset other(-dirty)
    }
    if {[info exists other]} {
	foreach a [array names other] {
	    setWinInfo -w $name [string range $a 1 end] $other($a)
	}
    }
    if {[info exists shrink]} {
	shrinkWindow -w $name 1
    }
    return $name 
}

## 
 # -------------------------------------------------------------------------
 # 
 # "edit" --
 # 
 #  This is the start of the chain of events which AlphaTcl expects when
 #  Alpha/Alphatk is asked to 'open' a file.  That request may result
 #  in the file being opened, or, depending on procedures registered
 #  with 'editHook', a different action may be taken.  For example,
 #  installer files should avoid the whole 'edit' completely, non-text
 #  files could be ignored, and even more complex actions could be taken.
 #  For example, with the appropriate Tcl extensions, we can arrange for 
 #  the mounting of 'virtual file systems' (such as .tar, .sit or .zip
 #  files) when the archive is opened by Alpha (hence allowing transparent
 #  editing of their contents in place).  Even urls could be mounted in
 #  this way to provide an alternative method of editing files on remote
 #  ftp sites.
 #  
 #  Anyway, procedures registered to editHook should return 0
 #  if they took no action, or 1 if they accept resposibility for the
 #  file.  No other return values are permitted.  The 'mode' field
 #  of this hook is the file's extension.
 #  
 #  Extensions must be lowercase (in the hook::register call).  For
 #  example:
 #  
 #     hook::register editHook install::editHook .install
 #  
 #  In the future we will integrate this with the above implementations
 #  of edit so that we can, for instance, specify a flag to force Alpha
 #  to edit the file.
 #  
 #  NB: This procedure overwrites the dummy version created in 
 #  'initialize.tcl' which is there to handle 'edit' being called
 #  very early in the startup sequence (e.g. if files are dropped
 #  onto Alpha or sent via apple-events, we have to be careful we
 #  don't process them until we are ready).
 # -------------------------------------------------------------------------
 ##
proc edit {args} {
    global alpha::guiNotReady
    if {[info exists alpha::guiNotReady]} {
	# We don't open windows during startup
	hook::register startupHook "edit $args ; #"
	return
    }
    set filename [lindex $args end]
    if {![hook::callUntil editHook \
      [string tolower [file extension $filename]] $filename]} {
	return [eval [list editDocument] $args]
    }
    return
}

