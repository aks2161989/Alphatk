## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_splash.tcl"
 #                                    created: 04/08/98 {21:52:56 PM} 
 #                                last update: 2006-03-29 09:00:31 
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

set alpha::version "8.5a1"

# version - Return string of the form "5.31 for ppc, released...".
proc version {args} { 
    global alpha::version
    return "Alphatk $alpha::version, Friday, December 10th 2004" 
}

# Alphatk 7.x and 8.x prefs are compatible
set alpha::majorUpgradePrefsCompatible 1
set alpha::tclversion ""

proc alpha::makeToplevel {w args} {
    if {![winfo exists $w]} {
	eval [list toplevel $w] $args
    }
    bindtags $w [concat "AlphaToplevel" [bindtags $w]]
}

proc alpha::_copyrightYear {} {
    set year [clock format [clock seconds] -format %Y]
    if {$year < 2000} {set year 2000}
    return $year
}

set alpha::colours(alphabackground) #0000ff

# Called by AlphaTclCore (initAlphaTcl.tcl) when we have read in
# the version information.
proc alpha::showStartupVersions {{win .startup}} {
    variable tclversion
    if {[winfo exists $win.f]} {
	$win.f create text 1690 386 -anchor se \
	  -text "and AlphaTcl $tclversion" -fill white -tags alphatcl
    }
}

proc alpha::_fadeIn {win increment} {
    global tcl_platform
    if {![winfo exists $win]} { return }
    set alpha [wm attributes $win -alpha]
    set alpha [expr {$alpha + $increment}]
    
    if {$tcl_platform(platform) == "windows"} {
	# Workaround windows bug
	set limit 0.99
    } else {
        set limit 1.0
    }
    if {$alpha > $limit} {
	wm attributes $win -alpha $limit
	return
    }
    wm attributes $win -alpha $alpha
    after 20 [list ::alpha::_fadeIn $win $increment]
}

proc alpha::makeStartup {{win .startup}} {
    _makeStartup $win
    _fadeIn $win 0.08
    return $win
}

proc alpha::_makeStartup {win} {
    global ALPHATK
    variable colours
    variable version
    variable tclversion
    if {![winfo exists $win]} {
	alpha::makeToplevel $win -background $colours(alphabackground) ; wm overrideredirect $win 1
    } elseif {[winfo toplevel $win] == $win} {
	catch {destroy $win}
	alpha::makeToplevel $win -background $colours(alphabackground) ; wm overrideredirect $win 1
    }
    if {[file exists [file join $ALPHATK Images splash.gif]]} {
	image create photo splash \
	  -file [file join $ALPHATK Images splash.gif]
    } else {
	image create photo splash \
	  -file [file join $ALPHATK Images splash.ppm]
    }
    canvas $win.f -width [image width splash] -height [image height splash] \
      -highlightthickness 0 -borderwidth 0
    $win.f create image 0 0 -image splash -anchor nw
    pack $win.f -fill both -expand yes
    $win.f create text 690 270 -anchor ne -fill white -justify right \
      -text "Copyright © Vince Darley\n1998-[_copyrightYear]"
    $win.f create text 690 350 -anchor se -text "Alphatk version $version" \
      -fill white -tags alphatk
    $win.f create text 1690 368 -anchor se -text "using Tcl [info patchlevel]" \
      -fill white -tags tcl
    if {[string length $tclversion]} {
	$win.f create text 1690 386 -anchor se \
	  -text "and AlphaTcl $tclversion" -fill white -tags alphatcl
    } else {
	$win.f create text 1690 386 -anchor se \
	  -text "" -fill white -tags alphatcl
    }
    set md [clock format [clock seconds] -format "%m-%d"]
    if {$md eq "12-24"} { set md "12-25" }
    set other [file join $ALPHATK Images alphatkother$md.gif]
    if {[file exists $other]} {
	image create photo other -file $other
	$win.f create image [expr {([image width splash] - [image width other])/2}] \
	  [expr {([image height splash] - [image height other])/2}] \
	  -image other -anchor nw
    }
    $win.f create text 690 15 -anchor ne -fill white -justify right -tags credits \
      -text ""
    set h [winfo screenheight .]
    set w [winfo screenwidth .]
    set w [winfo toplevel $win]
    wm withdraw $w
    update idletasks
    wm geometry $w +[expr {([winfo screenwidth .]-[winfo reqwidth $w])/2}]+[expr {([winfo screenheight .]-[winfo reqheight $w])/2}]
    update
    wm attributes $w -alpha 0.01
    wm deiconify $w
    raise $w
    update
    wm geometry $w +[expr {([winfo screenwidth .]-[winfo reqwidth $w])/2}]+[expr {([winfo screenheight .]-[winfo reqheight $w])/2}]
    # This double 'list' is required because the 'after' is eval'ed and
    # then the 'catch' evals again.
    after 1000 "
	catch [list [list $win.f move tcl -1000 0]]
	after 1000 [list catch [list [list $win.f move alphatcl -1000 0]]]
    "
    bind $w <Destroy> {catch {image delete splash ; image delete other}}
    return $w
}

