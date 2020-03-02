#!/bin/sh
#-*-tcl-*-
# the next line restarts using wish \
exec wish "$0" ${1+"$@"}

#####################################################################
#  Alphatk - the ultimate Tcl/Tk editor
# 
#  FILE: "alphatk.tcl"
#                                    created: 04/12/98 {22:45:38 PM} 
#                                last update: 2006-04-11 22:48:41
#  Author: Vince Darley
#  E-mail: vince.darley@kagi.com
#    mail: Flat 10, 98 Gloucester Terrace, London, W2 6HP
#     www: http://www.purl.org/net/alphatk
#  
# Copyright (c) 1998-2003  Vince Darley
# 
# See the file "license.terms" for information on use and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# In particular, Alphatk is NOT free, and cannot be copied in full or in
# part except according to the terms of the license agreement.
# 
#####################################################################

if {[info exists HOME]} {
    # This is actually a very serious problem, potentially,
    # in which we are being sourced recursively.
    return
}

namespace eval alpha {}

lappend alpha::startupTimes \
  [list [clock clicks -milliseconds] "Initializing Alphatk"]

if {$tcl_platform(platform) == "unix" && $tcl_platform(os) == "Darwin"} {
    # We're on MacOS X -- remove bogus '-psn' arguments inserted by the
    # MacOS X environment
    if {[info exists argv]} {
	set new_argv {}
	foreach str $argv {
	    if {![regexp {\-psn_0_[0-9]+} $str]} {
		lappend new_argv $str
	    }
	}
	set argv $new_argv
	unset -nocomplain str new_argv
    }
}

proc alpha::parseCmdLine {argv} {
    set cmdList {}
    if {[lindex $argv 0] == "-"} {
	# use stdin as the input for a new window
	set contents [read stdin]
	lappend cmdList [list new -n "untitled" -text $contents]
    } else {
	set linePat {\+([0-9]+(?:\.[0-9]+)?)(?:[-,]([0-9]+(?:\.[0-9]+)?))?} 
	set ddash 0
	set cygwin 0
	for {set i 0} {$i < [llength $argv]} {incr i} {
	    set str [lindex $argv $i]
	    if {$ddash} {
		set fname $str
		if {$cygwin} {
		    regsub {^(/cygdrive)?/([a-zA-Z])/} $fname {\2:/} fname
		}
		if {![file exists $fname]} {
		    return -code error "No such file \"$fname\""
		}
		lappend cmdList [list edit -c [file join [pwd] $fname]]
	    } elseif {$str == "--"} {
		set ddash 1
	    } elseif {($::tcl_platform(platform) == "windows") \
	      && ($str == "-cygwin")} {
		# Interpret paths as cygwin paths
		set cygwin 1
	    } elseif {[regexp -- $linePat $str -> line to]} {
		if {[string first "." $line] == -1} {
		    append line ".0"
		}
		if {$to == ""} { 
		    set to $line 
		    append to " lineend"
		} else {
		    if {[string first "." $to] == -1} {
			append to ".0 lineend"
		    }
		}
		set fname [lindex $argv [incr i]]
		if {$cygwin} {
		    regsub {^(/cygdrive)?/([a-zA-Z])/} $fname {\2:/} fname
		}
		if {![file exists $fname]} {
		    return -code error "No such file \"$fname\""
		}
		set subCmd [list edit -c [file join [pwd] $fname]]
		lappend cmdList "select -w \[$subCmd\] \"$line\" \"$to\""
	    } elseif {$str == "-c"} {
		set str [lindex $argv [incr i]]
		lappend cmdList [list new -n $str]
	    } else {
		set fname $str
		if {$cygwin} {
		    regsub {^(/cygdrive)?/([a-zA-Z])/} $fname {\2:/} fname
		}
		#console show
		#puts stdout $str
		#update
		if {![file exists $fname]} {
		    return -code error "No such file \"$fname\""
		}
		lappend cmdList [list edit -c [file join [pwd] $fname]]
	    }
	}
    }
    return $cmdList
}

# Store the interpreted command-line, so we don't have to
# worry about pwd changes, etc.
#tk_messageBox -message $argv
set alpha::startupCmdList [alpha::parseCmdLine $argv]
unset argv

# We only want one copy of Alphatk to be running, and if the
# user drops some more files on us, we check if we are already
# running and, if so, just send the appropriate platform-specific
# messages to open the files.
if {[llength $alpha::startupCmdList]} {
    switch -- $tcl_platform(platform) {
	"windows" {
	    if {![catch {package require dde}]} {
		if {[llength [dde services TclEval Alpha]]} {
		    foreach cmd $alpha::startupCmdList {
			dde execute -async TclEval Alpha $cmd
		    }
		    exit
		}
	    }
	}
	"unix" {
	    if {$tcl_platform(os) == "Darwin"} {
		# MacOS X
		if {![catch {exec ps -c -w -w} res]} {
		    if {[regexp {[ \t]Alphatk([ \t\r\n]|$)} $res]} {
			# Alphatk is already running
			set dir [file join [file dirname [info script]] \
			  AlphaTcl Tclextensions tclAE2.0]
			source [file join $dir pkgIndex.tcl]
			package require tclAE 2.0
			foreach cmd $alpha::startupCmdList {
			    tclAE::send 'AlTk' misc dosc ---- \
			      [tclAE::build::TEXT $cmd]
			}
			exit
		    }
		}
	    } else {
		# We need Tk to know if we're running or not
		package require Tk
		if {[lsearch -exact [winfo interps] "Alphatk"] != -1} {
		    foreach cmd $alpha::startupCmdList {
			send Alphatk $cmd
		    }
		    exit
		}
	    }
	}
	"macintosh" {
	    # Classic Mac not really supported
	}
    }
}

if {[info tclversion] < 8.5} {
    error "Sorry, we require Tcl version 8.5 or newer;\
      you have [info tclversion]"
    return
}

# Just in case we're running with tclsh.  We want Tk!
package require Tk
tk appname Alphatk

# Set this to one if you want to have messages
# broadcast to stdout.
if {0} {
    proc echo {txt} {
	# Catch this in case stdout doesn't exist.
	catch {puts stdout $txt}
    }
} else {
    proc echo {txt} {}
}

set now [clock clicks -milliseconds]
wm withdraw .

# Needed for AlphaTcl
set alpha::windowingsystem [tk windowingsystem]

if {[tk windowingsystem] == "aqua" \
  || [tk windowingsystem] == "classic"} {
    catch {tk::unsupported::MacWindowStyle style . plainDBox}
    catch {console hide}
    # This will be overridden later, but during early startup
    # we need to capture this directly into argv rather than
    # calling 'edit' which won't exist.
    proc tk::mac::OpenDocument {args} {
	eval lappend ::alpha::startupCmdList [alpha::parseCmdLine $args]
    }
}

update
# In case we started up in a strange way.
cd [file dirname [info script]]

# Make sure this directory is not on the auto_path and that
# there is no Tcl index.  We do not want auto_loading here!
while {[set idx [lsearch -exact $auto_path [pwd]]] != -1} {
    set auto_path [lreplace $auto_path $idx $idx]
}
unset idx
if {[file exists tclIndex]} {
    catch {file delete -force tclIndex}
}

if {[catch {package require msgcat}]} {
    echo "The msgcat package is required if you want to use\
      a localised version of Alphatk"
    namespace eval msgcat {}
    proc msgcat::mc {str} { return $str }
    proc msgcat::mclocale {args} {}
    proc msgcat::mcunknown {locale string} { return $string }
} else {
    msgcat::mcload Localisation
    # auto_load
    catch {msgcat::mcunknown blah blah}
}
if {[catch {package require Tclx 8.4}]} {
    echo "Installing Tclx speeds up some operations inside Alphatk"
}

# For debugging, you can force this on here.
#console show

if {[info commands quit] == ""} {
    rename exit alpha::_quit
    proc exit {{returnCode ""}} {}

    # MacTk seems to have a bug if we exit using exit.
    # So instead we destroy the root window.  This might
    # be a better default for all platforms, to allow for
    # embedding of Alphatk, or perhaps starting up Alphatk
    # in an interpreter which forms part of a bigger application.
    proc quit {} {
	# We don't really have to do this, but it is nicer
	# of us to clean up the things we know about.
	catch {status::msg "Exiting"}
	global alpha::unmount
	if {[info exists alpha::unmount]} {
	    foreach um $alpha::unmount {
		vfs::zip::Unmount $um
	    }
	    unset -nocomplain um
	}
	destroy .
	# force the exit as well.
	alpha::_quit
    }
}

namespace eval alpha {
    namespace eval index {}
    namespace eval cache {}
    #set haveBasicKeys 1
    proc checkFileExists {dir {isdir 0}} {
	if {![file exists $dir] || \
	  ($isdir && ![file isdirectory $dir]) \
	  || (!$isdir && ![file isfile $dir])} {
	    tk_messageBox -title "Fatal Alphatk error" -message \
	      "Alphatk cannot find its\
	      [expr {$isdir ? {directory} : {file}}]\
	      '[file join [pwd] $dir]'.\
	      You should reinstall Alphatk.  Goodbye."
	    quit
	}
    }
}

# If we are in a starpack or a read-only starkit, then
# we configure outselves to be completely read-only.
set sys [file system [info nameof]]
if {[lindex $sys 0] == "tclvfs"} {
    # if we have a recent enough version of tclvfs
    if {![catch {vfs::attributes [info nameof] -state} sys]} {
	if {$sys == "translucent"} {
	    vfs::attributes [info nameof] -state readonly
	}
    }
}
unset sys

if {[file exists AlphaTcl.zip] && ![file isdir AlphaTcl]} {
    if {![catch {
	package require vfs
	lappend alpha::unmount [vfs::zip::Mount AlphaTcl.zip AlphaTcl.zip]
	set HOME [file join [pwd] AlphaTcl.zip AlphaTcl]
    }]} {
	# we mounted successfully
	echo "Mounted AlphaTcl vfs"
    }
}
if {![info exists HOME]} {
    alpha::checkFileExists [file join AlphaTcl Tcl] 1

    # Do this stuff to deal with aliases/links more easily later on.
    # We want 'HOME' to point to the parent of 'Tcl'.
    set HOME [file join [pwd] AlphaTcl Tcl]
    if {[file type $HOME] == "link"} {
	set HOME [file readlink $HOME]
    }
    set HOME [file dirname $HOME]
    # Fix windows path
    if {$tcl_platform(platform) == "windows"} {
	catch {set HOME [file attributes $HOME -longname]}
    }

    # If we are using a packaged-up AlphaTcl.zip, then mount that
    # as our home directory, if we have the vfs package available
    if {[file exists [file join $HOME AlphaTcl.zip]]} {
	if {![catch {
	    package require vfs
	    lappend alpha::unmount [vfs::zip::Mount \
	      [file join $HOME AlphaTcl.zip] [file join $HOME AlphaTcl.zip]]
	    set HOME [file join $HOME AlphaTcl.zip]
	}]} {
	    # we mounted successfully
	    echo "Mounted AlphaTcl vfs"
	}
    }
}

if {[file exists AlphatkCore.zip] && ![file isdir AlphatkCore]} {
    if {![catch {
	package require vfs
	lappend alpha::unmount [vfs::zip::Mount AlphatkCore.zip AlphatkCore.zip]
	set ALPHATK [file join [pwd] AlphatkCore.zip AlphatkCore]
    }]} {
	# we mounted successfully
	echo "Mounted AlphatkCore vfs"
    }
}
if {![info exists ALPHATK]} {
    alpha::checkFileExists AlphatkCore 1
    set ALPHATK [file normalize AlphatkCore]
}
# This will ensure the right encoding is used
set alpha::coreHierarchy ALPHATK

alpha::checkFileExists [file join $ALPHATK Images] 1

foreach imagefile [glob -directory [file join $ALPHATK Images] *.gif] {
    image create photo [file root [file tail $imagefile]] -file $imagefile
}
unset imagefile

# The internal encoding is ISOmacRoman if we're developing with cvs on a
# Windows or Unix machine, but if we're just a user, we will have
# downloaded a macRoman encoding version.
set alpha::internalEncoding macRoman
set alpha::platform tk

# For pre-building a cache.
if {${alpha::internalEncoding} == "ISOmacRoman"} {
    set alpha::cache [file join $HOME Cache]
}

# We need this in case anything goes wrong.
proc alertnote {message} {
    set root [focus]
    if {![string length $root]} {
	set root .
    }
    if {[winfo exists .startup]} {
	global tcl_platform
	if {$tcl_platform(platform) == "unix"} {
	    destroy .startup
	    set parent .
	} else {
	    set parent .startup
	}
    } else { 
	set parent $root
    }

    tk_messageBox -message $message -parent $parent
    update
}

if {[info commands bgerror] == ""} {
    auto_load bgerror
}
rename bgerror tk_bgerror
# This will be overridden later.
proc bgerror {err} {
    if {[info commands ::status::msg] != ""} {
	status::msg $err
    }
}

alpha::checkFileExists [file join $HOME Tcl SystemCode Init initialize.tcl]

if {[catch [list source [file join $HOME Tcl SystemCode Init initialize.tcl]]]} {
    catch {puts stderr "Problems sourcing initialize.tcl"}
    catch {console show}
    catch {puts stderr $::errorInfo}
}

if {$alpha::macos} {
    catch {
	# Force loading of our tclAE, to ensure we over-ride what
	# comes with Tcl.
	set dir [file join $HOME Tclextensions tclAE2.0]
	source [file join $dir pkgIndex.tcl]
	package require tclAE 2.0
    }
}

if {$alpha::macos} {
    set alpha::modifier_keys [list "Command" "cmd" "Option" "opt"]
    set alpha::command_key "Command"
    set alpha::option_key "Option"
} else {
    switch -- $tcl_platform(platform) {
	"windows" {
	    set alpha::modifier_keys [list "Alt" "alt" "Meta" "meta"]
	    set alpha::command_key "Alt"
	    set alpha::option_key "Meta"
	    # Add these defaults in.
	    event add <<Paste>> <Alt-v>
	    event add <<Copy>> <Alt-c>
	    event add <<Cut>> <Alt-x>
	}
	"unix" -
	default {
	    set alpha::modifier_keys [list "Alt" "alt" "Meta" "meta"]
	    set alpha::command_key "Alt"
	    set alpha::option_key "Meta"
	}
    }
}

# Load in either byte-compiled or source scripts.

# First get default and splash screen.
foreach _f {default alpha_splash} {
    if {[file exists [file join $ALPHATK ${_f}.tbc]]} {
	source [file join $ALPHATK ${_f}.tbc]
    } else {
	source [file join $ALPHATK ${_f}.tcl]
    }
}

# Now show the splash screen, and make a grab on it to stop
# user interaction
default::findDefaults
grab [alpha::makeStartup]

# Check if we have 'dnd' functionality available
set alpha::haveDnd 0
if {$alpha::macos} {
    proc dnd {args} {}
} else {
    if {[catch {package require tkdnd} err]} {
	echo "Install 'tkdnd' to let Alphatk make use of drag and drop\
	  features ($err)."
	# declare dummy proc so we don't have to worry later.
	proc dnd {args} {}
    } else {
	set alpha::haveDnd 1
    }
}

# Now load up everything else.
foreach _f {balloonHelp alpha_menus \
  alpha_commands alpha_dialogs alpha_inter_app \
  alpha_positions alpha_editing alpha_colouring alpha_dnd alpha_gui} {
    if {[file exists [file join $ALPHATK ${_f}.tbc]]} {
	source [file join $ALPHATK ${_f}.tbc]
    } else {
	source [file join $ALPHATK ${_f}.tcl]
    }
}

if {[info exists env(PREF_FOLDER)]} {
    # Good for MacOS
    set PREFS [file join $env(PREF_FOLDER) Alpha]
} elseif {[info exists env(USERPROFILE)]} {
    # Good for WindowsNT/2000
    set PREFS [file join $env(USERPROFILE) Alpha]
} elseif {[info exists env(HOME)]} {
    # Good for Unix
    if {($alpha::macos == 2) \
      && [file exists [file join $env(HOME) Library Preferences]]} {
	set PREFS [file join $env(HOME) Library Preferences Alphatk]
    } else {
	set PREFS [file join $env(HOME) .Alpha]
    }
}

set alpha::application "Alphatk"

if {![info exists skipPrefs]} {
    set skipPrefs 0
}

unset _f

proc alpha::setIcon {w {path ""}} {}
set alpha::useMyIcons 0
switch -- $tcl_platform(platform) {
    "windows" {
	catch {wm iconbitmap . -default [file join $ALPHATK Alpha.icr]}
	proc alpha::setIcon {w {path ""}} {
	    if {![string length $path] || ![file exists $path]} {return}
	    global windowIcons
	    if {[info exists windowIcons]} {
		if {!$windowIcons} {
		    catch {wm iconbitmap $w $path}
		}
	    } else {
		catch {wm iconbitmap $w $path}
	    }
	}
    }
    "macintosh" {
    }
    "unix" -
    default {
	if {[tk windowingsystem] == "aqua"} {
	    proc alpha::setIcon {w {path ""}} {
		if {$path eq ""} {return}
		catch {
		    wm iconbitmap $w $path
		}
		catch {
		    wm attributes $w -titlepath $path
		    wm attributes $w -modified 0
		}
	    }
	}
    }
}

proc alpha::foundPrefs {} {
    set already_running [alpha::initInterApplication]
    if {$already_running} {
	global PREFS HOME
	if {![file::pathStartsWith $PREFS $HOME] && ![file::pathStartsWith \
	  [file join [file dirname [info nameof]] AlphaPrefs] $PREFS]} {
	    if {[askyesno -y Continue -n Quit \
	      "Alphatk already appears to be running; are\
	      you sure you want to start a second copy?  Sharing certain\
	      kinds of preferences between two running copies could cause\
	      problems."] != "yes"} {
		quit
		return
	    }
	}
    }
}

alpha::checkFileExists [file join $HOME Tcl SystemCode] 1

if {[catch alpha::PreGuiStartup]} {
    catch {puts stderr "Problems calling alpha::PreGuiStartup"}
    catch {puts stderr $::errorInfo}
    alertnote $::errorInfo
}

alpha::foundPrefs

# Load up the enhanced text widget package we need
foreach _f {enhancedTextwidget} {
    if {[file exists [file join $ALPHATK TextWidget ${_f}.tbc]]} {
	source [file join $ALPHATK TextWidget ${_f}.tbc]
    } else {
	source [file join $ALPHATK TextWidget ${_f}.tcl]
    }
}

foreach _f {alpha_macros alpha_io alpha_windows} {
    if {[file exists [file join $ALPHATK ${_f}.tbc]]} {
	source [file join $ALPHATK ${_f}.tbc]
    } else {
	source [file join $ALPHATK ${_f}.tcl]
    }
}

if {[info commands newPref] == ""} {
    error "No newPref command; very bad startup problem"
}

switch -- $tcl_platform(platform) {
    "windows" {
	source [file join $ALPHATK alpha_win_print.tcl]
	source [file join $ALPHATK resizer.tcl]
    }
    "macintosh" {
    }
    "unix" -
    default {
    }
}

# Load in either byte-compiled or source scripts.
foreach _f {alpha_startup} {
    if {[file exists [file join $ALPHATK ${_f}.tbc]]} {
	source [file join $ALPHATK ${_f}.tbc]
    } else {
	source [file join $ALPHATK ${_f}.tcl]
    }
}
unset _f

# Try to go to home directory.  We've had bug reports of this
# not even existing for some people!
catch {cd ~}

echo "Startup took [expr {([clock clicks -milliseconds] - $now)/1000.0}] seconds"
unset now

