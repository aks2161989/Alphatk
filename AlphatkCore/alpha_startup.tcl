## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_startup.tcl"
 #                                    created: 04/08/98 {21:52:56 PM} 
 #                                last update: 03/29/2006 {09:46:41 PM} 
 #  Author: Vince Darley
 #  E-mail: vince.darley@kagi.com
 #    mail: Flat 10, 98 Gloucester Terrace, London W2 6HP
 #     www: http://www.purl.org/net/alphatk
 #  
 # Copyright (c) 1998-2005  Vince Darley
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

namespace eval alpha {}
namespace eval win {}

switch -- $tcl_platform(platform) {
    "macintosh" {
	set pixelOffsetFromBottomOfWindow 0
    }
    "windows" {
	# The status bar at the bottom of the screen can be placed 
	# according to your preferences for OS-dependent taskbars.
	# If your taskbar automatically hides itself, then there is
	# no need to have any pixel offset.  Otherwise an offset of
	# 18-48 may be useful.  If the status bar is under the menus,
	# this setting is ignored.
	newPref earlyvariable pixelOffsetFromBottomOfWindow 18 global alpha::updateStatusLocation
	lappend varPrefs(Window) pixelOffsetFromBottomOfWindow
	# The status bar at the bottom of the screen can float above
	# all other windows.
	newPref earlyflag statusWindowAlwaysOnTop 0 global "wm attributes .status -topmost \$statusWindowAlwaysOnTop ;#"
	lappend flagPrefs(Window) statusWindowAlwaysOnTop
    }
    "unix" -
    default {
	# The status bar at the bottom of the screen can be placed 
	# according to your preferences for OS-dependent taskbars.
	# If your taskbar automatically hides itself, then there is
	# no need to have any pixel offset.  Otherwise an offset of
	# 18-48 may be useful.  If the status bar is under the menus,
	# this setting is ignored.
	newPref earlyvariable pixelOffsetFromBottomOfWindow 48 global alpha::updateStatusLocation
	lappend varPrefs(Window) pixelOffsetFromBottomOfWindow
    }
}

# Alpha contains the infrastructure for localisation (i.e. translation)
# of most menu items, dialogs, alerts etc. to any language.  This is 
# accomplished through the use of the 'msgcat' package, part of Tcl 8.1.
# If a .msg file for your language exists, you can select it here.
newPref earlyvar localisation c global alpha::updateLocalisation

auto_load msgcat::mcunknown
rename ::msgcat::mcunknown ::msgcat::_mcunknown
proc ::msgcat::mcunknown {locale args} {
    switch -- $locale {
	"en_uk" {
	    regsub -all {ization} $args {isation} args
	    regsub -all {(C|c)olor} $args {\1olour} args
	    return $args
	}
	default {
	    return [uplevel 1 [list ::msgcat::_mcunknown $locale] $args]
	}
    }
}

# We might only want to do this on restart
proc alpha::updateLocalisation {args} {
    global localisation ALPHATK
    ::msgcat::mclocale $localisation
    ::msgcat::mcload [file join $ALPHATK Localisation]
}

alpha::updateLocalisation
alpha::makeStatus
alpha::initDnd

proc totalGeometry {{w .}} {
    set geom [wm geometry $w]
    regexp -- {([0-9]+)x([0-9]+)\+(\-?[0-9]+)\+(\-?[0-9]+)} $geom -> \
      width height decorationLeft decorationTop
    set contentsTop [winfo rooty $w]
    set contentsLeft [winfo rootx $w]
    
    # Measure left edge, and assume all edges except top are the
    # same thickness
    set decorationThickness [expr {$contentsLeft - $decorationLeft}]
    
    # Find titlebar and menubar thickness
    set menubarThickness [expr {$contentsTop - $decorationTop}]
    
    incr width [expr {2 * $decorationThickness}]
    incr height $decorationThickness
    incr height $menubarThickness
    
    return [list $width $height $decorationLeft $decorationTop]
}

foreach {screenWidth screenHeight} [getMainDevice] {}
set menubarHeight [screenToDistance [default::size menubarheight]]
set titlebarHeight [screenToDistance [default::size titlebarheight]]
set statusbarHeight [screenToDistance [winfo height .status]]

set ModeSuffixes { default {set winMode ""} }
set encoding ""
set platform $tcl_platform(platform)

status::msg "Starting up"

if {![winfo exists .menubar]} {
    menu .menubar
    wm title . "Alphatk"
    . configure -menu .menubar
    menu .menubar.help -tearoff 0
    .menubar add cascade -menu .menubar.help -label "Help"
    bind . <<Destroy>> quit
    wm protocol . WM_DELETE_WINDOW {
	if {[tk_messageBox \
	  -icon    question \
	  -type    yesno \
	  -default no \
	  -message "Are you sure you want to quit Alphatk?" \
	  -title  "Quit Application?"] == "yes"} {           
	    quit
	}
    }
}

namespace eval hook {}

bind all <[lindex $alpha::modifier_keys 0]-Key-period> "abortEm"
set alpha::abort 0

if {[tk windowingsystem] != "classic" \
  && [tk windowingsystem] != "aqua"} {
    alpha::positionMenuBar 1
    # Hiding the main menu bar unmaps all windows.
    bind . <Unmap> [list alpha::iconifyAll %W]
    bind . <Map> [list alpha::iconifyAll %W 0]
} else {
    set alpha::topYPixel 20
}

# Do this after early prefs are in, but before building everything.
alpha::makeSystemMenu

if {1} {
proc decorationGeometry {{w .}} {
    set geom [wm geometry $w]
    regexp -- {([0-9]+)x([0-9]+)\+(\-?[0-9]+)\+(\-?[0-9]+)} $geom -> \
      width height decorationLeft decorationTop
    set contentsTop [winfo rooty $w]
    set contentsLeft [winfo rootx $w]
    # Measure left edge, and assume all edges except top are the
    # same thickness
    set decorationThickness [expr {$contentsLeft - $decorationLeft}]
    
    # Find titlebar + menubar (if it exists) thickness
    set titleMenubarThickness [expr {$contentsTop - $decorationTop}]
    
    return [list $titleMenubarThickness $decorationThickness]
}
if {$alpha::macos == 0} {
    set menubarHeight [screenToDistance [lindex [decorationGeometry] 0]]
    if {$menubarHeight == 0} {
	if {$locationOfStatusBar} {
	    # At top
	    set menubarHeight [screenToDistance [winfo rooty .status]]
	} else {
	    # At bottom of screen
	    set menubarHeight [screenToDistance $::alpha::topYPixel]
	}
    }
}
toplevel .tt ; wm withdraw .tt ; update idletasks
set titlebarHeight [screenToDistance [lindex [decorationGeometry .tt] 0]]
if {$titlebarHeight == 0} {
    # We're on Unix/MacOS X, where we need to do more
    wm geometry .tt +[expr {5 * [winfo screenwidth .]}]+0
    wm deiconify .
    update
    set titlebarHeight [screenToDistance [lindex [decorationGeometry .tt] 0]]
    if {$titlebarHeight == 0} {
	# On Unix/X11
	frame .tt.dummy -height 0 -width [winfo reqwidth .tt]
	pack .tt.dummy -side bottom -expand 1
	update
 	set titlebarHeight [screenToDistance [winfo rooty .tt.dummy]]
	if {$titlebarHeight == 0} {
	    wm deiconify .tt
	    update
	    set titlebarHeight [screenToDistance [winfo rooty .tt.dummy]]
	    if {$locationOfStatusBar} {
		# At top
		set menubarHeight [screenToDistance [winfo rooty .status]]
	    } else {
		# At bottom of screen
		set menubarHeight [screenToDistance $::alpha::topYPixel]
	    }
	}
    }
}
destroy .tt
}

if {[info exists alpha::topYPixel]} {
    #puts stderr "Have $alpha::topYPixel"
}

alpha::Startup

# Only apply these bindings after alpha::Startup, else they will trigger 
# problems if the user starts to press keys during Alphatk's startup
# sequence.
bindtags . [concat Alpha [bindtags .]]
destroy .startup

if {[llength [info commands alpha::setIcon]]} {
    update idletasks
    alpha::setIcon .
}

if {[info commands console] == "console"} {
    menu::insert Utils items "wordCount" "showTkConsole"
    proc showTkConsole {} {
	console show
	if {[tk windowingsystem] == "aqua" \
	  || [tk windowingsystem] == "classic"} {
	    console eval {wm title . "Console - click on status bar to return to Alphatk"}
	} else {
	    console eval {wm title . "Alphatk console"}
	}
	console eval {raise .}
    }
    if {[tk windowingsystem] == "aqua" \
      || [tk windowingsystem] == "classic"} {
	catch {console eval {wm title . "Console - click on status bar to return to Alphatk"}}
    } else {
	catch {console eval {wm title . "Alphatk console"}}
    }
    catch {
	console eval {
	    bindtags . [concat AlphaToplevel [bindtags .]]
	    bind AlphaToplevel <FocusIn> "consoleinterp eval {alpha::focusState in}"
	    bind AlphaToplevel <FocusOut> "consoleinterp eval {alpha::focusState out}"
	}
    }
    catch {console hide}
}

# If there were any extra arguments, evaluate the commands we
# interpreted earlier.
foreach cmd $alpha::startupCmdList {
    if {[catch $cmd err]} {
	alertnote "There was an error '$err' while trying to '$cmd'"
    }
    unset err
}
unset -nocomplain cmd alpha::startupCmdList

hook::register diskModifiedHook win::diskModified *
hook::register uninstallHook ::windows::DeleteGroup *

alpha::finalStartup

# Deal with suspend, resume events.
bindtags . [concat "AlphaToplevel" [bindtags .]]
bind AlphaToplevel <FocusIn> "alpha::focusState in"
bind AlphaToplevel <FocusOut> "alpha::focusState out"
bind Alpha <Unmap> "alpha::unmap %W"
if {[tk windowingsystem] eq "aqua"} {
    bind Alpha <Command-KeyPress-q> "quit"
}
proc alpha::unmap {w} {
    if {$w eq "." || $w eq ".status"} return
    global win::tktitle
    if {![info exists win::tktitle($w)]} { return }
    # We're mimizing an editing window, so make sure we have
    # something in front.
    alpha::focusOnFrontmost
}

proc alpha::focusOnFrontmost {} {
    # We do this so the menubar or statusbar are not the frontmost.
    set nextWin [win::Current]
    if {$nextWin ne "" && [windowVisibility -w $nextWin] eq "normal"} {
	bringToFront $nextWin
    }
}

proc alpha::focusState {d} {
    variable Priv
    if {[info exist Priv(lostFocusIgnore)]} { return }
    switch -- $d {
	"in" {
	    after cancel [list alpha::focusState "lostFocus"]
	    if {[info exists Priv(lostFocusIdle)]} {
		after cancel $Priv(lostFocusIdle)
		unset Priv(lostFocusIdle)
	    }
	    if {[info exists Priv(suspended)]} {
		unset Priv(suspended)
		alpha::statusVisibility 1
		resumeHook
	    }
	}
	"out" {
	    after idle [list alpha::focusState "lostFocus"]
	}
	"lostFocus" {
	    # Call AlphaTcl suspendHook
	    set Priv(lostFocusIdle) \
	      [after idle {
		unset -nocomplain ::alpha::Priv(lostFocusIdle)
		set ::alpha::Priv(suspended) 1
		alpha::statusVisibility 0
		suspendHook
	    }]
	    #puts "Alphatk suspended"
	}
    }
}

if {$tcl_platform(platform) eq "windows"} {
    menu::insert fileUtils items end associateTypeWithAlpha associateTypeWithEditInAlpha
}
