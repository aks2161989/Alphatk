## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_inter_app.tcl"
 #                                    created: 03/01/2000 {15:19:43 PM} 
 #                                last update: 04/12/2006 {11:33:48 PM} 
 #  Author: Vince Darley
 #  E-mail: vince.darley@kagi.com
 #    mail: Flat 10, 98 Gloucester Terrace, London W2 6HP
 #     www: http://www.purl.org/net/alphatk
 #  
 # Copyright (c) 2000-2005  Vince Darley
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # In particular, while this is 'open source', it is NOT free, and
 # cannot be copied in full or in part except according to the terms
 # of the license agreement.
 # 
 # ###################################################################
 ##

proc alpha::initInterApplication {} {
    global tcl_platform
    set isRunning 0
    # This code initialises inter-application communication
    switch -- $tcl_platform(platform) {
	"unix" {
	    if {[tk windowingsystem] == "aqua"} {
		# On MacOS, Tk calls one of these two procedures when it
		# receives 'open document' events, for example if you drag a
		# file onto the Wish application.
		proc ::tkOpenDocument {args} {
		    foreach f $args {
			edit $f
		    }
		}
		# Version for newer Tk.
		namespace eval ::tk {}
		namespace eval ::tk::mac {}
		proc ::tk::mac::OpenDocument {args} {
		    foreach f $args {
			edit $f
		    }
		}
		proc ::tk::mac::ShowPreferences {args} {
		    alertnote "Please use the Config->Preferences submenu"
		}
		if {[info commands ::tk::unsupported::MacWindowStyle] == ""} {
		    namespace eval ::tk::unsupported {}
		    proc ::tk::unsupported::MacWindowStyle {args} {
			eval [list unsupported1] $args
		    }
		}
		if {![catch {exec ps -c -w -w} res]} {
		    if {[regexp {[ \t]Alphatk([ \t\r\n]|$)} $res]} {
			# It's already running
			set isRunning 1
		    }
		}
	    }
	    # we have send
	    set copies 0
	    foreach interp [winfo interps] {
		if {$interp == "Alphatk"} {
		    incr copies
		}
	    }
	    if {$copies > 1} { set isRunning 1 }
	}
	"windows" {
	    # On windows we're supposed to use the 'dde' package instead of send.
	    if {[info commands ::send] == ""} {
		proc ::send {args} {
		    echo "No send! Ignored $args"
		}
	    }
	    alpha::recordTimingData "Loading dde services"
	    if {[catch {package require dde}]} {
		echo "Problems loading dde package.  Interaction with other"
		echo "windows applications will be much impaired."
		alpha::recordTimingData "No dde services."
	    } else {
		alpha::recordTimingData "Starting dde services..."
		if {[lsearch -exact [dde services TclEval {}] "TclEval Alpha"] != -1} {
		    set isRunning 1
		}
		dde servername Alpha
		update idletasks
		# Under very strange conditions, the dde services on
		# Windows can hang completely, and this line never returns.
		# In this case Alphatk will not startup (it will also
		# hang), and you should simply reboot your machine.
		echo "Creating dde server. Current services:\
		  [dde services TclEval {}]"
		alpha::recordTimingData "Starting dde services... ready"
	    }
	}
	"macintosh" {
	    if {[catch {
		package require Comm 3
		# let's hope this isn't used!
		comm config -port 1197 -local 1 -listen 1
	    }]} {
		echo "Problems loading Comm package or port already in use."
		echo "Won't be able to use remote invocation."
	    }
	    # On MacOS, Tk calls one of these two procedures when it
	    # receives 'open document' events, for example if you drag a
	    # file onto the Wish application.
	    proc ::tkOpenDocument {args} {
		foreach f $args {
		    edit $f
		}
	    }
	    # Version for newer Tk.
	    namespace eval ::tk {}
	    namespace eval ::tk::mac {}
	    proc ::tk::mac::OpenDocument {args} {
		foreach f $args {
		    edit $f
		}
	    }
	    if {[info commands ::tk::unsupported::MacWindowStyle] == ""} {
		namespace eval ::tk::unsupported {}
		proc ::tk::unsupported::MacWindowStyle {args} {
		    eval [list unsupported1] $args
		}
	    }
	}
	default {
	    error "No known platform"
	}
    }
    return $isRunning
}

#¥ alpha::executeURL <URL> - passes arg to Internet Config, if present. Error if not 
#  present. 
proc alpha::executeURL {url} {
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    global env
	    if {![info exists env(BROWSER)]} {
		set env(BROWSER) "Browse the Internet"
	    }
	    if {[catch {
		AppleScript execute\
		    "tell application \"$env(BROWSER)\"
			 open url \"$url\"
		     end tell
		"} emsg]
	    } then {
		error "Error displaying $url in browser\n$emsg"
	    }
	}
	"windows" {
	    if {[regexp -- "^mailto:" $url] || [regexp -- "&" $url]} {
		# This one seems to sometimes hang your machine for
		# a long time, for http's or file's...
		# For some silly reason we must convert "htm" into
		# something else first.
		regsub -all -nocase {htm} $url {ht%6D} url
		eval exec rundll32 url.dll,FileProtocolHandler [list $url] &
	    } else {
		# ..and this one doesn't seem to work with mailto's
		# or with urls containing '&'
		eval exec [auto_execok start] [list $url] &
	    }
	}
	"unix" {
	    if {[regexp -- "^mailto:" $url]} {
		# Pipe mailto's direct to 'mail'.
		regexp -- "^mailto:(.*)" $url "" msg
		set parts [split $msg "?&"]
		set f [open "|mail [lindex $parts 0]" w]
		set parts [lrange $parts 1 end]
		foreach part $parts {
		    foreach {field val} [split $part =] {}
		    if {$field == "body"} {
			set body [quote::Unurl $val]
		    } else {
			puts $f "${field}: [quote::Unurl $val]"
		    }
		}
		puts $f ""
		if {[info exists body]} {
		    puts $f $body
		}
		close $f
	    } else {
		global browserSig alpha::macos
		app::getSig "Please locate your browser :" browserSig
		if {[file exists $browserSig]} {
		    if {[exec $browserSig -remote openURL($url)] != 0} {
			# the browser isn't running
			exec $browserSig $url &
		    }
		} elseif {${alpha::macos}} {
		    app::ensureRunning $browserSig 1
		    tclAE::send -p -r '$browserSig' GURL GURL ---- "Ò$urlÓ"
		} else {
		    error "Browser not known"
		}
	    }
	}
    }
}

#¥ switchTo <appName> - Switches to application 'appName'.
proc switchTo {app} {
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    set dosc "tell application \"$app\"\n \"\"\nend tell"
	    AppleScript execute $dosc
	}
	"windows" -
	"unix" {
	    global alpha::macos
	    if {${alpha::macos}} {
		# remove the quotes
		if {[regexp -- {^'(.*)'$} $app -> sig]} {
		    if {![app::isRunning [list $sig]]} {
			launch [nameFromAppl $sig]
		    }
		} else {
		    if {![app::isRunning [list $app]]} {
			launch $app
		    }
		}
		tclAE::send $app 'misc' 'actv'
		return
	    }
	    # nothing
	    # echo "switchTo $app ineffective."
	}
    }
}

# ×××× Inter-application communcation ×××× #

#¥ launch -f <name> - launch the named app into the background. Note that 
#  for some yet unexplained reason, some applications (MicroSoft Word) 
#  won't launch completely in the background. 'launch'ing such 
#  applications won't insert the application into any system menu that 
#  specifies running applications (although "About the Finder..." will 
#  list it. The only way to get to such an app is through Alpha's 
#  'switchTo', after which the application will finish launching. The '-f' 
#  option gets around this by launching the application in the foreground 
#  instead.
proc launch {args} {
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    set dosc "tell application \"$app\"\n \"\"\nend tell"
	    AppleScript execute $dosc
	}
	"windows" -
	"unix" {
	    if {[lindex $args 0] == "-f"} {
		set name [lindex $args 1]
		set bg 0
	    } else {
		set name [lindex $args 0]
		set bg 1
	    }
	    
	    if {[tk windowingsystem] == "aqua"} {
		exec open -a $name
		return
	    }
	    if {$bg} {
		exec $name &
	    } else {
		exec $name
	    }
	}
    }
}


#¥ processes - returns info of active processes. A list of lists, each 
#  sublist contain a file-name, an application signature, the application 
#  memory size, and the number of ticks the application has been active.
proc processes {} {
    global tcl_platform alpha::macos

    if {${alpha::macos} == 2} {
	set longnames {}
	foreach app [split [exec ps -w -w -x] \n] {
	    if {[info exists column]} {
		set name [string range $app $column end]
		regsub { -psn[_0-9]+$} $name "" name
		lappend longnames $name
	    } else {
		set column [string first "COMMAND" $app]
	    }
	}
	return $longnames
    } else {
	set res [list]
	foreach ps [split [exec ps -W] \n] {
	    lappend res $ps
	}
	return $res
    }
}

#¥ icGetPref [<-t <type>] <pref name> - Gets preference from 
#  Internet Config. '-t' allows type to be set, '0' returns a string 
#  (default), '1' returns a path name, commonly used for helper apps. A 
#  <pref name> of 'all' returns all valid preferences.
proc icGetPref {args} {
    global tcl_platform

    if {[llength $args] == 3 && ([lindex $args 0] == "-t")} {
	set type [lindex $args 1]
	set pref [lindex $args 2]
    } elseif {[llength $args] != 1} {
	error {Incorrect arguments: [-t type] <pref>}
    } else {
	set type 0
	set pref [lindex $args 0]
    }
    set errorMsg "'icGetPref $args' not supported on this platform"
    if {$pref == "all"} {
	# Return a list of all prefs available
	switch -- $tcl_platform(platform) {
	    "windows" {
		return [list Helper¥http Helper¥ftp]
	    }
	    "macintosh" {error $errorMsg}
	    "unix"      {error $errorMsg}
	}
    } elseif {$type == "0"} {
	# Return the path of the given preference app
	switch -- $tcl_platform(platform) {
	    "windows"   {error $errorMsg}
	    "macintosh" {error $errorMsg}
	    "unix"      {error $errorMsg}
	}
    } elseif {$type == "1"} {
	# Return the name of the preference's application
	switch -- $tcl_platform(platform) {
	    "windows" {
		switch -- [string tolower $pref] {
		    "helper¥http"  {
			return [windows::AppFor .html]
		    }
		    "helper¥ftp" {
			return [windows::AppFor .html]
		    }
		    default {
			# Otherwise, options not supported yet.
			error $errorMsg
		    }
		}
	    }
	    "macintosh" {error $errorMsg}
	    "unix"      {error $errorMsg}
	}
    } elseif {$type == "2"} {
	# Return the creator code for the preference's application
	switch -- $tcl_platform(platform) {
	    "windows"   {error $errorMsg}
	    "macintosh" {error $errorMsg}
	    "unix"      {error $errorMsg}
	}
    } else {
	error "Unknown type: $type"
    }
}
#¥ icOpen - Opens Internet Config
proc icOpen {args} {
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"windows" {
	    error "icOpen is not supported on this platform"
	}
	default {
	    error "Not implemented -- please make a suggestion!"
	}               
    }
}
#¥ nameFromAppl '<app sig>' - Interrogates the desktop database for the first 
#  existing app that has the desired signature. <app sig> is four chars 
#  inside single quotes.
proc nameFromAppl {sig} {
    if {[file exists $sig]} {
	return $sig
    } else {
	# This fails (intentionally) if not particular signature is not
	# known (use catch to call this procedure)
	global alpha::macos
	if {${alpha::macos} == 2} {
	    set ansr [tclAE::send  -r 'MACS' core getd  ---- \
	      [tclAE::build::propertyObject pURL \
	      "obj {want:type(appf), seld:Ò$sigÓ, form:ID  , from:'null'()}" ]]
	    set url [tclAE::getKeyData $ansr '----' TEXT]
	    tclAE::disposeDesc $ansr
	    return [file::fromUrl $url]
	}
    }
    error "Unknown sig '$sig'"
}

namespace eval file {}

proc file::associateTypeWithAlpha {} {
    if {[win::Current] ne ""} {
	set ext [file extension [win::Current]]
    } else {
	set ext [file extension [getfile "Pick a file of the type you want to associate with Alphatk"]]
    }
    windows::AssociateActionWithAlphatk [file extension [win::Current]]
}

proc file::associateTypeWithEditInAlpha {} {
    if {[win::Current] ne ""} {
	set ext [file extension [win::Current]]
    } else {
	set ext [file extension [getfile "Pick a file of the type you want to associate with Alphatk"]]
    }
    windows::AssociateActionWithAlphatk [file extension [win::Current]] "edit"
}

proc file::makeShortcut {name to} {
    error "Not yet implemented."
    exec rundll32.exe appwiz.cpl,NewLinkHere $name $to
    return
    error "Not yet implemented."
    set sout [open ${name}.lnk w]
    fconfigure $sout -encoding binary
    puts $sout "Not yet..."
    close $sout
}

namespace eval windows {}

# USE EXTREME CAUTION WITH THIS PROC.
# It changes items in the registry, and could therefore
# really mess things up if the wrong things are changed.
proc windows::AssociateActionWithAlphatk {ext {what "open"}} {
    package require registry
    set root HKEY_CLASSES_ROOT
    # Get the application key for these files
    if {[catch {registry get $root\\$ext ""} appKey]} {
	# no app-key exists we must create one
	registry set $root\\$ext "" "[string range $ext 1 end]file"
    }
    set appKey [registry get $root\\$ext ""]
    if {[catch {registry keys $root\\$appKey\\shell\\${what}} types]} {
	# no types known, so we'll have to create a dde one.
	set types ""
    }
    if {[lsearch -exact $types "ddeexec"] != -1} {
	# dde opener already exists
	registry set \
	  $root\\$appKey\\shell\\${what}\\ddeexec "" {edit {%1}}
	registry set \
	  $root\\$appKey\\shell\\${what}\\ddeexec\\Application "" TclEval
	registry set \
	  $root\\$appKey\\shell\\${what}\\ddeexec\\topic "" Alpha
	
    } else {
	# no dde: we need to create it.  This seems to work
	registry set \
	  $root\\$appKey\\shell\\${what}\\ddeexec "" {edit {%1}}
	registry set \
	  $root\\$appKey\\shell\\${what}\\ddeexec\\Application "" TclEval
	registry set \
	  $root\\$appKey\\shell\\${what}\\ddeexec\\topic "" Alpha
    }
    #puts $root\\$appKey
    global ALPHATK
    set prefix "[file nativename [info nameofexecutable]] "
    if {[lindex [file system [info nameof]] 0] eq "native"} {
	append prefix [file nativename [file normalize \
	  [file join [file dirname $ALPHATK] alphatk.tcl]]]
	append prefix " "
    }
    registry set $root\\$appKey\\shell\\${what}\\command {} \
	"$prefix \"%1\""
}

proc windows::GetShellCmds {filename} {
    foreach type [windows::ShellCmd $filename *] {
	lappend res [list $type [windows::ShellCmd $filename $type]]
    }
    return $res
}

proc windows::Launch {filename} {
    # If the application isn't launched, we'll get an error
    if {[catch {eval [windows::ShellCmd $filename]}]} {
	eval [windows::ShellCmd $filename open 1]
    }
}

proc windows::AppFor {filename {what "open"}} {
    package require registry
    if {[file pathtype $filename] == "relative"} {
	set filename [file join [pwd] $filename]
    }
    set ext [file extension $filename]
    # Look for the application under
    # HKEY_CLASSES_ROOT
    set root HKEY_CLASSES_ROOT
    # Get the application key for these files
    set appKey [registry get $root\\$ext ""]
    # What actions are possible on these files?
    if {$what == "*"} {
	return [registry keys $root\\$appKey\\shell]
    } else {
	set types [registry keys $root\\$appKey\\shell\\${what}]
    }
    # use command
    set cmd [registry get \
      $root\\$appKey\\shell\\${what}\\command ""]
    # Substitute out various percentage stuff
    set cmd [windows::SubstCommand $cmd $filename]
    # Double up the backslashes for 
    regsub -all {\\} $cmd  {\\\\} cmd
    # Return the required command
    return [file join [lindex $cmd 0]]
}

proc windows::SetIconFor {{filename ""}} {
    if {![string length $filename]} {
	set filename [win::Current]
    }
    global win::tk
    set icon [windows::DefaultIcon [file extension $filename]]
    set tkw [winfo toplevel $win::tk($filename)]
    set iconfile [lindex $icon 0]
    set idx [lindex $icon 1]
    if {![string length $idx] || ($idx == 0)} {
	if {[lsearch -exact [list .ico .icr] [file extension $iconfile]] != -1} {
	    wm iconbitmap $tkw $iconfile
	} else {
	    # not yet supported
	}
    } else {
	# not yet supported
    }
}

proc windows::RegistryRoot {ext} {
    package require registry
    # Look for the application under
    # HKEY_CLASSES_ROOT
    set root HKEY_CLASSES_ROOT
    # Get the application key for these files
    set appKey [registry get $root\\$ext ""]
    return "$root\\$appKey"
}

proc windows::DefaultIcon {ext} {
    set root [windows::RegistryRoot $ext]
    # This won't always work
    set icon [windows::SubstCommand [registry get "$root\\DefaultIcon" ""]]
    set last [string last , $icon]
    if {$last == -1} {
	set iconfile $icon
	set iconnumber ""
    } else {
	set iconfile [string range $icon 0 [expr {$last -1}]]
	incr last
	set iconnumber [string trim [string range $icon $last end]]
    }
    return [list $iconfile $iconnumber]
}

proc windows::SetIcon {ext iconfile {number ""}} {
    set root [windows::RegistryRoot $ext]
    set iconfile [file nativename $iconfile]
    if {[string length $number]} {
	append iconfile ",$number"
    }
    registry set "$root\\DefaultIcon" "" "$iconfile"
}

proc windows::ShellCmd {filename {what "open"} {forceexec 0}} {
    set root [windows::RegistryRoot [file extension $filename]]
    if {$what == "*"} {
	return [registry keys $root\\shell]
    } else {
	set types [registry keys $root\\shell\\${what}]
    }

    if {[file pathtype $filename] == "relative"} {
	set filename [file join [pwd] $filename]
    }

    # Choose 'dde' in preference to execution if it's there.
    if {!$forceexec && ([lsearch -exact $types "ddeexec"] != -1)} {
	set app [registry get \
	  $root\\shell\\${what}\\ddeexec\\Application ""]
	set topic [registry get \
	  $root\\shell\\${what}\\ddeexec\\topic ""]
	set cmd [registry get \
	  $root\\shell\\${what}\\ddeexec ""]
	set cmd [windows::SubstCommand $cmd $filename]
	# Return the required command
	return [list dde execute -async $app $topic $cmd]
    } else {
	# use command
	set cmd [registry get \
	  $root\\shell\\${what}\\command ""]
	set cmd [windows::SubstCommand $cmd $filename]
	# Double up the backslashes for eval (below)
	regsub -all {\\} $cmd  {\\\\} cmd
	# Return the required command
	return "exec $cmd &"
    }
}

proc windows::SubstCommand {cmd args} {
    # Substitute the arguments into the
    # command for %1,%2,... or add them to the end.
    set i 1
    set origcmd $cmd
    # Continue until no more substitutions except for possible %*
    while {[regsub -all "%${i}" $origcmd "" origcmd]} {
	set arg [lindex $args [expr {$i-1}]]
	regsub -all {\\|&} $arg {\\\0} arg
	regsub -all "%${i}" $cmd $arg cmd
	incr i
    }
    set extra ""
    foreach arg [lrange $args [expr {$i-1}] end] {
	append extra " \"$arg\""
    }
    if {[regsub -all {%\*} $origcmd "" origcmd]} {
	regsub -all {\\|&} $extra {\\\0} extra
	regsub -all {%\*} $cmd $extra cmd
    } else {
	append cmd $extra
    }
    # Substitute for things like '%SystemRoot%'
    while {[regexp -- {%([a-zA-Z]+)%} $cmd "" var]} {
	global env
	regsub "%${var}%" $cmd $env($var) cmd
    }
    return $cmd
}

proc windows::GetProgmanGroups {} {
    regsub -all "\r\n" [dde request PROGMAN PROGMAN Groups] "\n" res
    split [string trim $res] \n
}

# From Usenet:
# 
# show can be:
#1       Activates and displays the group window. If the window is minimized or
#        maximized, Windows restores it to its original size and position.
#2       Activates the group window and displays it as an icon.
#3       Activates the group window and displays it as a maximized window.
#4       Displays the group window in its most recent size and position. The
#        window that is currently active remains active.
#5       Activates the group window and displays it in its current size and
#        position.
#6       Minimizes the group window.
#7       Displays the group window as an icon. The window that is currently
#        active remains active.
#8       Displays the group window in its current state. The window that is
#        currently active remains active.

proc windows::ShowGroup {name {foreground 1}} {
    # The first call, despite the above stuff, seems not to work
    # as advertised.  At least on Windows 2000, a '7' seems best,
    # and if we want the window in the foreground, another 7 after
    # a second or so seems to do the trick.
    windows::RepeatIfInForeground [list windows::ProgmanExecute ShowGroup $name 7] $foreground
}

# Should try using REGEDIT (HKEY_CLASSES_ROOT\Drive\shell\find) or
# DDESpy

# ToggleDesktop, FindFolder, ShellFile

proc windows::Show {filename {foreground 1}} {
    global showFileInExplorer
    if {![file isdirectory $filename]} {
	set filename [file dirname $filename]
    }
    if {$showFileInExplorer} {
	set how "ViewFolder"
    } else {
	set how "ExploreFolder"
    }
    # In this case a last argument of '5' seems to do the trick.
    windows::RepeatIfInForeground [list windows::DdeExecute Folders \
      AppProperties $how $filename $filename 5] $foreground
}

proc windows::RepeatIfInForeground {cmd {foreground 1}} {
    eval $cmd
    if {0 && $foreground} {
	update
	after 1000 "$cmd ; set windows::Done 1"
	global windows::Done
	vwait windows::Done
	unset windows::Done
    }
}

proc windows::CreateGroup {{name Alphatk}} {
    global env ALPHATK

    # Need to be careful if we have a starkit or starpack.
    set root [file dirname $ALPHATK]
    windows::ProgmanExecute CreateGroup $name
    if {[lindex [file system $root] 0] != "native"} {
	if {[info exists env(ProgramFiles)]} {
	    set pf $env(ProgramFiles)
	} else {
	    foreach vol [file volumes] {
		if {[file exists [file join $vol "Program Files"]]} {
		    set pf [file join $vol "Program Files"]
		    break
		}
	    }
	    if {![info exists pf]} {
		alertnote "Sorry, couldn't find your 'Program Files'\
		  directory, so no Windows Group will be created."
		return
	    }
	}
	file mkdir [file join $pf Alphatk]
	catch {file copy [file join $root Readme.txt] [file join $pf Alphatk]}
	if {[file isdirectory [file join $root alphatk.kit]]} {
	    catch {file copy [file join $ALPHATK Alpha.icr] \
	      [file join $pf Alphatk]}
	    windows::ProgmanExecute AddItem [file join $root alphatk.kit] \
	      $name [file attributes [file join $pf Alphatk Alpha.icr] -shortname]
	} else {
	    windows::ProgmanExecute AddItem [info nameof] $name
	}
	windows::ProgmanExecute AddItem [file join $pf Alphatk Readme.txt] \
	  Readme
    } else {
	windows::ProgmanExecute AddItem [file join $root alphatk.tcl] \
	  $name [file attributes [file join $ALPHATK Alpha.icr] -shortname]
	windows::ProgmanExecute AddItem [file join $root Readme.txt] \
	  Readme
    }
}

proc windows::ProgmanExecute {name args} {
    eval [list windows::DdeExecute PROGMAN PROGMAN $name] $args
}

proc windows::DdeExecute {service topic name args} {
    set cmd "\[$name\("
    set subcmds [list]
    foreach a $args {
	lappend subcmds "\"$a\""
    }
    append cmd [join $subcmds ","] "\)\]"
    #puts stderr "dde execute $service $topic $cmd"
    dde execute $service $topic $cmd
}

proc windows::DeleteGroup {{name Alphatk}} {
    windows::ProgmanExecute DeleteGroup $name
}

