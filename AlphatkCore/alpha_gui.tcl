## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_gui.tcl"
 #                                    created: 04/08/98 {21:52:56 PM} 
 #                                last update: 04/18/2006 {09:52:20 PM} 
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

proc alpha::thanks {} {
    set l [list "Pete Keleher" "Jon Guyer" "Johan Linde" \
      "Tom Scavo" "Tom Pollard" "Tom Fetherston" "Mark Nagata" "Juan Falgeras"\
      "Jim Ingham" "Craig Upright" "Joachim Kock" "Daniel Steffen"\
      "Lars Hellström" "Bernard Desgraupes" "Frédéric Boulanger" \
      "Dominique d'Humieres"]
    return [lsort -dictionary -index 1 $l]
}

# make .status

set alpha::theming 0

namespace eval ttk {}

if {[info commands ::tk::button] == ""} {
    foreach widget {
	button frame checkbutton radiobutton menubutton label
	entry labelframe
    } {
	rename ::$widget ::tk::$widget
	interp alias {} ::$widget {} ::tk::$widget
	if {[info commands ::ttk::$widget] eq ""} {
	    interp alias {} ::ttk::$widget {} ::tk::$widget 
	}
    }
    unset widget
}

# Super-experimental...
proc alpha::setTheme {} {
    variable theming
    
    ::package require tile

    set theming 1
    style configure Small.TButton -font TkHeadingFont
    style configure Small.TCheckbutton -font TkHeadingFont

    return
    foreach theme [style theme names] {
	style theme settings $theme {
	    style layout TCheckbutton {
		Checkbutton.indicator -side left -sticky nws
		Checkbutton.label -side left -sticky nwse
	    }
	    style default TCheckbutton \
	      -justify left -anchor nw
	}
    }
}

# Try to use theming on all platforms
catch {alpha::setTheme}

proc alpha::smallMenuButton {w args} {
    if {1 && [tk windowingsystem] == "aqua"} {
	foreach opt {padx pady relief activebackground activeforeground font} {
	    set idx [lsearch -exact $args -$opt]
	    if {$idx != -1} {
		set args [lreplace $args $idx [expr {$idx + 1}]]
	    }
	}
	style default Slim.Toolbutton -padding 0 -font "system 9"
	eval [list ::ttk::menubutton $w] $args -style Slim.Toolbutton
    } elseif {1 || [tk windowingsystem] == "aqua"} {
	# We need to create a label to mimic a menubutton, because
	# menubuttons on MacOS X are much too wide for us.
	if {[set midx [lsearch -exact $args "-menu"]] != -1} {
	    set menuName [lindex $args [expr {$midx + 1}]]
	    set args [lreplace $args $midx [expr {$midx + 1}]]
	}
	set direction "below"
	if {[set midx [lsearch -exact $args "-direction"]] != -1} {
	    set direction [lindex $args [expr {$midx + 1}]]
	    set args [lreplace $args $midx [expr {$midx + 1}]]
	}
	eval [list ::tk::label $w] $args
	regsub -all "Label" [bindtags $w] "Menubutton" newtags
	bindtags $w $newtags
	rename $w ::alpha::__$w
	alpha::buildWidgetProc $w $direction
	bind $w <Destroy> [list rename $w {}]
    } else {
	eval [list ::menubutton $w] $args
    }
}

proc alpha::buildWidgetProc {w direction} {
    proc ::$w {args} [format {
	if {[lindex $args 0] == "cget"} {
	    switch -- [lindex $args 1] {
		"-menu" {
		    set m "%s.menu"
		    if {[winfo exists $m]} {
			return $m
		    } else {
			return ""
		    }
		}
		"-direction" {
		    return %s
		}
		"-indicatoron" {
		    return 0
		}
	    }
	} elseif {[lindex $args 0] == "configure"} {
	    # Not a perfect implementation at all, but
	    # good enough for our uses.
	    if {[lindex $args 1] == "-menu"} {
		return "%s.menu"
	    }
	    if {[lindex $args 1] == "-direction"} {
		set direction [lindex $args 2]
		::alpha::buildWidgetProc %s $direction
		return $direction
	    }
	}
	uplevel 1 ::alpha::__%s $args
    } $w $direction $w $w $w]
}

proc alpha::makeStatus {} {
    global tcl_platform locationOfStatusBar pixelOffsetFromBottomOfWindow
    # Note: Must not just 'update' until the status bar is built, because
    # we might have something happen which wants to put a message in the
    # status bar, and that will be unhappy.
    if {[tk windowingsystem] == "classic" \
      || [tk windowingsystem] == "aqua"} {
	set haveNativeMenuBar 1
	set mac 1
    } else {
	set haveNativeMenuBar 0
	set mac 0
    }
    if {![winfo exists .status]} {
	if {$mac} {
	    catch {
		::tk::unsupported::MacWindowStyle style . plainDBox
		#::tk::unsupported::MacWindowStyle style . floating sideTitlebar
	    }
	}
	# If we have a native menubar, then the '.' window is always used for
	# the status bar.  If not, then '.' is used for the menubar, and the
	# status bar is only added to it if it is 'under the menus'.  Therefore
	# if the status bar is at the bottom of the screen it needs its own
	# toplevel.
	if {$locationOfStatusBar || $haveNativeMenuBar} {
	    wm geometry . [winfo screenwidth .]x[distanceToScreen 15]+0+0
	    ::ttk::frame .status -width [winfo screenwidth .] -height [distanceToScreen 20]
	    alpha::packStatus 1
	    update idletasks
	    wm geometry . [winfo screenwidth .]x[winfo reqheight .]+0+0
	} else {
	    alpha::makeToplevel .status ; wm overrideredirect .status 1
	    global statusWindowAlwaysOnTop
	    if {[info exists statusWindowAlwaysOnTop]} {
		wm attributes .status -topmost $statusWindowAlwaysOnTop
	    }
	}
	if {$haveNativeMenuBar} {
	    set theStatus .
	} else {
	    set theStatus .status
	}

	::ttk::label .status.text -text "" -anchor w
	if {[tk windowingsystem] eq "aqua"} {
	    style default Active.TLabel -foreground black
	    style map Active.TLabel -foreground {disabled #a3a3a3}
	    style default Active.TMenubutton -foreground black
	    style map Active.TMenubutton -foreground {disabled #a3a3a3}
	    .status.text configure -style Active.TLabel
	}
	grid .status.text -sticky snew -row 0 -column 0
	grid columnconfigure .status 0 -weight 2

	# We must add the 'Alpha' bindings to .status otherwise if
	# it gets the focus, no key-bindings will trigger anything!
	set bt [bindtags .status]
	set idx [lsearch -exact $bt ".status"]
	incr idx
	bindtags .status [linsert $bt $idx Alpha]
	# Also, we don't want .status.text getting the focus, else
	# our keybindings won't trigger properly.
	bindtags .status.text [concat [bindtags .status.text] Alpha]

	::tk::frame .status.w -width 250 -height 20
	::tk::label .status.w.position -text "" -width 7 -anchor c
	bindtags .status.w.position \
	  [concat Positionpopup [bindtags .status.w.position]]
	if {[tk windowingsystem] == "aqua"} {
	    .status.text configure -font "system 11"
	    .status.w.position configure -font "system 11"
	}
	if {$locationOfStatusBar} {
	    set direction "below"
	} else {
	    set direction "above"
	}
	set cmd ::tk::menubutton
	set cmd ::alpha::smallMenuButton
	# mode menu
	$cmd .status.w.mode -text {} \
	  -direction $direction -relief ridge \
	  -activebackground [color activebackground] \
	  -activeforeground [color activeforeground] \
	  -pady 0
	bindtags .status.w.mode \
	  [concat Modepopup [bindtags .status.w.mode]]
	# encoding menu
	$cmd .status.w.encoding -text {} \
	  -direction $direction \
	  -relief ridge\
	  -activebackground [color activebackground] \
	  -activeforeground [color activeforeground] \
	  -pady 0
	bindtags .status.w.encoding \
	  [concat Encodingpopup [bindtags .status.w.encoding]]
	# wrap menu
	$cmd .status.w.wrap -text {} \
	  -direction $direction \
	  -relief ridge\
	  -activebackground [color activebackground] \
	  -activeforeground [color activeforeground] \
	  -pady 0
	bindtags .status.w.wrap \
	  [concat Wrappopup [bindtags .status.w.wrap]]
	# fileinfo menu
	$cmd .status.w.fileinfo -text {} \
	  -direction $direction \
	  -relief ridge\
	  -activebackground [color activebackground] \
	  -activeforeground [color activeforeground] \
	  -pady 0
	bindtags .status.w.fileinfo \
	  [concat Fileinfopopup [bindtags .status.w.fileinfo]]
	::tk::label .status.w.state -text ""

	if {[tk windowingsystem] == "aqua"} {
	    catch {
		style default Status.Toolbutton -padding 0 \
		  -foreground black -font "system 9"
		style map Status.Toolbutton -foreground {disabled #a3a3a3}
		.status.w.mode configure -style Status.Toolbutton
		.status.w.encoding configure -style Status.Toolbutton
		.status.w.fileinfo configure -style Status.Toolbutton
		.status.w.wrap configure -style Status.Toolbutton
	    }
	    catch {
		.status.w.state configure -font "system 11" -padx 2
		.status.w.mode configure -font "system 11" -padx 4
		.status.w.encoding configure -font "system 11" -padx 4
		.status.w.fileinfo configure -font "system 11" -padx 4
		.status.w.wrap configure -font "system 11" -padx 4
	    }
	}

	pack .status.w.position -side right
	pack .status.w.state -side right
	pack .status.w.mode -side right
	pack .status.w.encoding -side right
	pack .status.w.wrap -side right
	pack .status.w.fileinfo -side right

	if {[winfo toplevel $theStatus] eq $theStatus} {
	    # It's a standalone window
	    update idletasks
	    set h [winfo screenheight .]
	    set w [winfo screenwidth .]
	    set sh [winfo reqheight .status]
	    if {$sh < 16} { set sh 18 }
	    if {$locationOfStatusBar} {
		# Top of screen, and standalone -- macos only
		wm geometry $theStatus \
		  ${w}x[distanceToScreen 20]+0+[distanceToScreen $sh]
	    } else {
		# At bottom of screen
		wm geometry $theStatus \
		  ${w}x[distanceToScreen 20]+0+[expr {$h - \
		  [distanceToScreen [expr {$sh + $pixelOffsetFromBottomOfWindow}]]}]
	    }
	    update idletasks
	}

	update
	if {$mac} {
	    balloon::help .status "This bar is used for quick interaction\
	      with the user.  To change its location, go to the 'Window'\
	      preferences dialog."
	} else {
	    balloon::help .status "This bar is used for quick interaction\
	      with the user.  To change its location, go to the 'Window'\
	      preferences dialog.  You may also drag files onto it to\
	      open them."
	}
	if {$mac} {
	    wm deiconify .
	}
    }
}

proc alpha::packStatus {on} {
    set top_w [winfo reqwidth .]
    set top_h [winfo reqheight .]
    if {$on} {
	if {[lsearch -exact [pack slaves .] .status] == -1} {
	    pack .status -expand 1 -fill x
	    set h [winfo reqheight .status]
	    pack propagate .status 0
	    wm geometry . ${top_w}x[expr {$top_h + $h -3}]
	}
    } else {
	set geom [wm geometry .]
	set h [winfo height .status]
	pack forget .status
	wm geometry . ${top_w}x[expr {$top_h - $h}]
    }
}

proc alpha::statusVisibility {visible} {
    global hideStatusBarWhenInBackground
    if {![info exists hideStatusBarWhenInBackground] \
      || !$hideStatusBarWhenInBackground} {
	return
    }
    if {[tk windowingsystem] == "classic" \
      || [tk windowingsystem] == "aqua"} {
	set haveNativeMenuBar 1
	set theStatus .
    } else {
	set haveNativeMenuBar 0
	set theStatus .status
    }
    if {!([winfo toplevel $theStatus] eq $theStatus)} {
	# Here the status bar is part of the menu bar, which means we must
	# be running on Windows, Unix or MacOS X with X windows.  We want
	# to roll the status bar up into the menu bar to make it hide.
	set top [winfo toplevel $theStatus]
	puts $visible
	if {$visible} {
	    alpha::packStatus 1
	} else {
	    set grab [grab current]
	    
	    if {($grab != "") \
	      && ([winfo toplevel $grab] == [winfo toplevel $theStatus])} {
		# Mustn't hide the status bar if it has a grab
		return
	    }
	    alpha::packStatus 0
	}
    } else {
	if {$visible} {
	    wm deiconify $theStatus
	} else {
	    set grab [grab current]
	    
	    if {($grab != "") && ([winfo toplevel $grab] eq $theStatus)} {
		# Mustn't hide the status bar if it has a grab
		return
	    }
	    wm withdraw $theStatus
	}
    }
}

proc alpha::updateStatusLocation {args} {
    global pixelOffsetFromBottomOfWindow locationOfStatusBar \
      tcl_platform alpha::menuBarGeometry
    if {[tk windowingsystem] == "classic" \
      || [tk windowingsystem] == "aqua"} {
	set haveNativeMenuBar 1
	set theStatus .
    } else {
	set haveNativeMenuBar 0
	set theStatus .status
    }
    if {$locationOfStatusBar ^ !([winfo toplevel $theStatus] eq $theStatus)} {
	set geom [wm geometry .]
	set height [lindex [split $geom "+x"] 1]
	if {[winfo toplevel .status] != ".status"} {
	    wm geometry . [winfo screenwidth .]x[expr {$height - 16}]
	} else {
	    wm geometry . [winfo screenwidth .]x[expr {$height + 16}]
	}
	# Ok, we're changing it on the fly
	destroy .status
	makeStatus
    } else {
	if {!$locationOfStatusBar} {
	    # It's a standalone window
	    set h [winfo screenheight .]
	    set w [winfo screenwidth .]
	    wm geometry $theStatus \
	      ${w}x[distanceToScreen 20]+0+[expr {$h - [distanceToScreen [expr {18 + $pixelOffsetFromBottomOfWindow}]]}]
	    update
	}
    }
    if {$locationOfStatusBar} {
	set direction "below"
    } else {
	set direction "above"
    }
    .status.w.mode configure -direction $direction
    .status.w.encoding configure -direction $direction
    .status.w.wrap configure -direction $direction
    .status.w.fileinfo configure -direction $direction
    
    if {[info exists alpha::menuBarGeometry]} {
	prefs::modified alpha::menuBarGeometry
	unset alpha::menuBarGeometry
    }
    status::msg "Status bar moved"
}

proc alpha::resizeMenuBar {} {
    wm resizable . 1 0
    global tcl_platform alpha::systemMenu
    if {$tcl_platform(platform) != "macintosh"} {
	if {![catch {$alpha::systemMenu index "Resize"}]} {
	    $alpha::systemMenu delete "Resize"
	}
	$alpha::systemMenu add command -label "Fix size" \
	  -command alpha::fixMenuBarSize
	if {($tcl_platform(platform) == "windows") \
	  && ($alpha::systemMenu == ".menubar.system")} {
	    # These two lines are required to work around a windows bug
	    catch {.menubar delete tmp}
	    .menubar add cascade -menu $alpha::systemMenu -label tmp
	}
    }
}

proc alpha::fixMenuBarSize {} {
    setMenuBarSize
    
    # Now remember it permanently
    global alpha::earlyPrefs
    lappend alpha::earlyPrefs alpha::menuBarGeometry
    prefs::modified alpha::menuBarGeometry
}

proc alpha::setMenuBarSize {} {
    wm resizable . 0 0
    # The above line resets Alphatk's icon on Windows!
    if {[llength [info commands alpha::setIcon]]} {alpha::setIcon .}
    global tcl_platform alpha::systemMenu
    if {$tcl_platform(platform) != "macintosh"} {
	if {![catch {$alpha::systemMenu index "Fix size"}]} {
	    $alpha::systemMenu delete "Fix size"
	}
	$alpha::systemMenu add command -label "Resize" \
	  -command alpha::resizeMenuBar
	if {($tcl_platform(platform) == "windows") \
	  && ($alpha::systemMenu == ".menubar.system")} {
	    # These two lines are required to work around a windows bug
	    catch {.menubar delete tmp}
	    .menubar add cascade -menu $alpha::systemMenu -label tmp
	}
	global alpha::menuBarGeometry
	set alpha::menuBarGeometry [wm geometry .]
    }
}

proc alpha::positionMenuBar {{startup 0} {andSize 1}} {
    variable menuBarGeometry
    variable topYPixel
    if {[info exists menuBarGeometry]} {
	set geom $menuBarGeometry
    } else {
	if {$startup} {
	    # This looks rather confused.  The idea is to generate a long thin
	    # window across the top of the screen, containing the Tk menu
	    # bar.  However some unix systems include the height of the menu
	    # bar in '.', so settings its height to 0 is very bad... we don't
	    # get any menus!  Also we somehow need a bunch of updates etc, so
	    # that this works on different versions of WinTk (there have been
	    # a number of behavioural changes in the wm code of 8.2.x-8.3.x).
	    # 
	    # Anyway, I think it works for all platforms now!
	    wm geometry . +0+0
	    frame .dummy -height 0 -width [winfo screenwidth .]
	    pack .dummy
	    update
	    wm geometry . +0+0
	    update
	    destroy .dummy

	    if {[llength [info commands alpha::setIcon]]} {
		alpha::setIcon .
	    }
	    set geom +0+0
	} else {
	    set geom [wm geometry .]
	}
    }
    wm deiconify .
    if {$andSize} {
	wm geometry . $geom
    } else {
	regexp -- {\+.*} $geom geom
	wm geometry . $geom
    }
    if {$startup} {
	frame .dummy -height 0 -width [winfo reqwidth .]
	pack .dummy -side bottom -expand 1
    }
    update
    if {$startup} {
	set topYPixel [winfo rooty .dummy]
	destroy .dummy
    }
}

proc alpha::makeSystemMenu {} {
    global tcl_platform alpha::systemMenu
    switch -- [tk windowingsystem] {
	"classic" - "aqua" {
	    .menubar add cascade -menu .menubar.apple
	    ::menu .menubar.apple -tearoff 0
	    .menubar.apple add command -label "About Alphatk\u2026" \
	      -command "alpha::about"
	    if {[tk windowingsystem] == "aqua"} {
		.menubar.apple add separator
	    }
	}
	"win32" - "windows" {
	    .menubar.help insert 0 command -label "About Alphatk\u2026" \
	      -command "alpha::about"
	    # This update is absolutely required on WinNT at least, or
	    # the .menubar.system menu will not have its contents added
	    # to the system menu.
	    set alpha::systemMenu .menubar.system
	    ::menu $alpha::systemMenu -tearoff 0

	    update idletasks
	    setMenuBarSize
	}
	default {
	    # unix
	    .menubar.help insert 0 command -label "About Alphatk\u2026" \
	      -command "alpha::about"
	    set alpha::systemMenu .menubar.help.system
	    ::menu $alpha::systemMenu -tearoff 0
	    .menubar.help insert 1 cascade -menu $alpha::systemMenu \
	      -label "Adjust"
	    
	    update idletasks
	    setMenuBarSize
	}
    }
}

proc tkAboutDialog {} {
    alpha::about
}

proc alpha::about {} {
    set w ".startup"
    if {[winfo exists $w]} {
	catch {destroy $w}
    }
    _makeStartup $w 
    _fadeIn $w 0.02
    bind all <ButtonPress> "set alphaAbout(startupdone) 1; set alphaAbout(done) 2"
    grab $w

    lappend credits \
      "Implemented by Vince Darley" "" "" \
      "inspired by Pete Keleher's" "Classic editor 'Alpha'" "" "" \
      "Many thanks to" "" 
    eval lappend credits [alpha::thanks]
    lappend credits "" "" \
      "graphic design by" "flip phillips"
    
    after 100 [list alpha::_arrangeScroll $w.f credits 13 $credits]
    global alphaAbout
    vwait alphaAbout(startupdone)
    bind all <ButtonPress> ""
    foreach a [after info] {
	if {[lindex [after info $a] 0] == "alpha::_arrangeScroll"} {
	    after cancel $a
	}
    }
    destroy $w
    unset alphaAbout
}

proc alpha::_arrangeScroll {can tag vislines text} {
    global alphaAbout
    for {set i 0} {$i < $vislines} {incr i} {
	lappend show ""
    }
    set height [font metrics [$can itemcget $tag -font] -linespace]
    set delay 30
    eval lappend lines $show $text $show
    for {set i 0} {$i < [llength $lines]} {incr i} {
	$can itemconfigure $tag -text \
	  [join [lrange $lines $i [expr {$i + $vislines -1}]] "\n"]
	for {set j 0} {$j < $height} {incr j} {
	    $can move $tag 0 -1
	    after $delay {set alphaAbout(done) 1}
	    vwait alphaAbout(done)
	    if {$alphaAbout(done) == 2} {return}
	}
	$can move $tag 0 $height
    }
    _showLogo $can
}

proc alpha::_showLogo {can} {
    global tk_library
    set img [file join $tk_library images pwrdLogo150.gif]
    if {[file exists $img] && [winfo exists $can]} {
	image create photo logo -file $img
	$can create image 690 15 -anchor ne -image logo
    }
}

proc alpha::iconifyAll {w {icon 1}} {
    # Bindings are triggered both for the toplevel and all children
    if {$w != "."} { return }
    foreach w [array names win::tk] {
	set ww $win::tk($w)
	if {[winfo exists $ww]} {
	    set top [winfo toplevel $ww]
	    if {![string length [$top cget -use]]} {
		if {$icon} {
		    wm iconify $top
		} else {
		    wm deiconify $top
		}
	    }
	}
    }
    if {[winfo toplevel .status] == ".status"} {
	if {$icon} {
	    wm withdraw .status
	} else {
	    wm deiconify .status
	}
    }
}

#• displayMode <mode> - Up to four characters of the 'mode' string are 
#  displayed in the status line at the bottom of a window.
proc displayMode {m} {
    .status.w.mode configure -text $m
    verifyDisplayStatus $m
}
#• displayEncoding <enc> - The 'enc' string is 
#  displayed in the status line at the bottom of the screen
proc displayEncoding {enc} {
    .status.w.encoding configure -text $enc
    verifyDisplayStatus
}

proc displayPlatform {plat} {
    .status.w.fileinfo configure -text $plat
    verifyDisplayStatus
}

proc displayWrap {wrapStyle} {
    .status.w.wrap configure -text $wrapStyle
    verifyDisplayStatus
}

proc verifyDisplayStatus {args} {
    if {[llength $args]} {
	if {[lindex $args 0] != ""} {
	    if {[lsearch -exact [grid slaves .status] ".status.w"] == -1} {
		grid .status.w -row 0 -column 2 -sticky e
		grid columnconfigure .status 2 -weight 0
	    }
	} else {
	    .status.w.position configure -text ""
	    grid forget .status.w
	}
    } else {
        # nothing
    }
    if {[llength [winNames -f]]} {
    } else {
    }
}

proc alpha::isOk {} {
    if {0 && ([tk windowingsystem] == "aqua")} {
	alertnote "This is a beta-release of Alphatk.  Please check\
	  frequently for newer releases which will fix reported problems!"
	alpha::forceFocus .
	return 1 
    }
    variable registration 
    variable userName
    if {[info exists registration] \
      && [string match "*4*3*2*1*" $registration]} {
	if {[info exists userName]} {
	    foreach w [split $userName " "] {
		set char [string index $w 0]
		if {[regexp -- {[a-zA-Z]} $char]} {
		    if {![string match \
		      "*[string toupper $char]*" $registration]} {
			return 0
		    }
		}
	    }
	    return 1
	}
	return 1
    } else {
	return 0
    }
}

proc alpha::finalStartup {{direct 0}} {
    if {[alpha::isOk]} {
	if {$direct} {
	    alertnote "You're already registered -- thanks!"
	}
	return
    }
    variable registration
    variable userName
    variable timeOfFirstUse
    variable timeOfLastUse
    if {![info exists userName]} { set userName "" }
    if {![info exists registration]} { set registration "" }
    
    prefs::modified alpha::userName alpha::registration
    
    set count 0

    if {![info exists timeOfFirstUse]} {
	set timeOfFirstUse [now]
	prefs::modified alpha::timeOfFirstUse
    }
    
    if {![info exists timeOfLastUse]} { set timeOfLastUse [now] }
    set daysSinceLastUse [expr {([now] - $timeOfLastUse) / (24*60*60)}]
    
    if {!$direct && ($daysSinceLastUse > 12)} {
	alertnote "I notice you haven't used Alphatk recently.\
	  Your trial period will be reset."
	set timeOfFirstUse [now]
	prefs::modified alpha::timeOfFirstUse
    }

    if {[now] < $timeOfFirstUse} {
	set timeOfFirstUse [now]
	prefs::modified alpha::timeOfFirstUse
    }
    
    set daysOfUse [expr {([now] - $timeOfFirstUse) / (24*60*60)}]
    
    set daysLeft [expr {45 - $daysOfUse}]
    set timeOfLastUse [now]
    prefs::modified alpha::timeOfLastUse

    if {($daysLeft > 25) && !$direct} {
	return
    }
    
    if {$daysLeft != 1} {
	append daysLeft " days"
    } else {
	append daysLeft " day"
    }


    while {1} {
	set resvar ""
	set y 10
	set args ""
	eval lappend args [dialog::image alphatk 10 y]
	incr y 10
	lappend args -T "Welcome to Alphatk"
	eval lappend args [dialog::text "Welcome to Alphatk.\
	  You have a free license to evaluate Alphatk for 45 days, with\
	  no limitations.  If you decide to\
	  continue using Alphatk beyond that time, you must\
	  buy a permanent license.  Once your payment has been received\
	  you will be sent a registration code to allow full, unhampered\
	  access to Alphatk.\r\rYou may purchase Alphatk at\
	  <http://order.kagi.com/?1GU> or by pressing the button below." 20 y 65]

	if {![info exists userName] || ![string length $userName]} {
	    set userName ""
	    eval lappend args [dialog::textedit "User name" $userName 40 y 20 1 100]
	    lappend resvar userName
	} else {
	    eval lappend args [dialog::text "User name: $userName" 40 y]
	}
	incr y 5
	if {$daysOfUse < 46} {
	    eval lappend args [dialog::text "If you would like to\
	      continue evaluating Alphatk (you have $daysLeft left),\
	      please leave the following\
	      field blank.  Once you have paid for and registered Alphatk,\
	      you may enter your registration code below." 20 y 65]
	} else {
	    eval lappend args [dialog::text "You've used Alphatk for\
	      at least $daysOfUse days.  If you use Alphatk beyond this time,\
	      you must pay for it.  If you do not quit now you are breaking\
	      the licence agreement." 20 y 65]
	}
	incr y 5
	eval lappend args [dialog::textedit "Registration code" "" 40 y 20 1 120]
	lappend resvar registration
	incr y 15
	
	set x 20
	eval lappend args [dialog::button "Purchase Online" "" y "Ok" "" y "Quit" "" y "Send Feedback" "" y]
	incr y 10
	lappend resvar register ok quit feedback
	foreach var $resvar val [eval dialog -w 480 -h $y $args] {
	    set $var $val
	}
	if {$quit} {
	    after 1 quit
	    return
	}
	if {$register} {
	    catch {url::execute "http://order.kagi.com/?1GU"}
	    continue
	}
	if {$feedback} {
	    catch {url::execute "mailto:vince.darley@kagi.com"}
	    continue
	}
	incr count
	if {[string trim $userName] != ""} {
	    if {[alpha::isOk]} {
		alertnote "Thank you for registering, $userName.  Updated versions\
		  of Alphatk are released at <ftp://ftp.ucsd.edu/pub/alpha/tcl/alphatk/>,\
		  which you may wish to check from time to time.  The author also\
		  appreciates feedback at <vince.darley@kagi.com>"
		break
	    } else {
		if {$registration == ""} {
		    # The user gets 45 days relatively hassle-free,
		    # then after that they have to wait a while for
		    # the dialog to let them continue.
		    if {$daysOfUse < 46} {
			if {$daysOfUse < 30} { break }
			if {$daysOfUse < 40} {
			    set res [dialog -w 500 -h 173 -b {Go to purchase website} 317 147 480 167 \
			      -b Continue 220 147 305 167 \
			      -t "You have $daysLeft left to\
			      evaluate Alphatk.  I hope you find it useful.\
			      Feel free to send feedback to vince.darley@kagi.com\n\n\
			      During the evaluation period, you will receive occasional\
			      reminders to pay for Alphatk." 5 5 593 79]
			} else {
			    set res [dialog -w 500 -h 173 -b {Go to purchase website} 317 147 480 167 \
			      -b Continue -delay 2000 220 147 305 167 \
			      -t "You have $daysLeft left to\
			      evaluate Alphatk.  I hope you find it useful.\
			      Feel free to send feedback to vince.darley@kagi.com\n\n\
			      During the evaluation period, you will receive occasional\
			      reminders to pay for Alphatk." 5 5 593 79]
			}
			if {[lindex $res 0]} {
			    catch {url::execute "http://order.kagi.com/?1GU"}
			}
			break
		    } else {
			set res [dialog -w 500 -h 73 -b {Go to purchase website} 317 47 480 67 \
			  -b Continue -delay 10000 220 47 305 67 \
			  -t "You have already used Alphatk for $daysOfUse days.\
			  If you want to continue using" 5 5 593 19 \
			  -t {Alphatk, please pay for and register it.  Thank You.} 5 21 425 35]
			if {[lindex $res 0]} {
			    catch {url::execute "http://order.kagi.com/?1GU"}
			}
			after 2000000 alpha::finalStartup
			break
		    }
		} else {
		    alertnote "That code is invalid.  Please enter another."
		    set registration ""
		}
	    }
	} else {
	    alertnote "You must enter your name to use Alphatk\
	      (don't worry, Alphatk\
	      never sends any information anywhere)."
	}
    }
}

bind Modepopup <Button-1> "alphatk::menuForPopup %W ::modeMenuHook \"%W.menu\""
bind Encodingpopup <Button-1> "alphatk::menuForPopup %W ::encodingMenuHook \"%W.menu\""
bind Wrappopup <Button-1> "alphatk::menuForPopup %W ::wrapMenuHook \"%W.menu\""
bind Fileinfopopup <Button-1> "alphatk::menuForPopup %W ::fileInfoMenuHook \"%W.menu\""

bind Positionpopup <Button-1> gotoLine
balloon::help Modepopup "Click here to change the mode of the current window"
balloon::help Encodingpopup "Click here to change the encoding of the\
  current window"
balloon::help Wrappopup "Click here to change the word-wrap style of\
  the current window's mode"
balloon::help Fileinfopopup "Click here to change properties of the file or\
  window."
balloon::help Positionpopup "The current row and column.\
  Click here to 'goto line'"
