## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "windowZoom.tcl"
 #                                          created: 05/13/2003 {08:23:37 AM}
 #                                      last update: 02/01/2005 {10:50:04 AM}
 # Description:
 # 
 # Provides an easily remembered set of key bindings for manipulating 
 # windows (and font sizes).  Also provides this zoom thing...
 # 
 # Authors: Joachim Kock and Craig Barton Upright
 # E-mail: <kock@math.unice.fr>
 # 
 #    
 # Copyright (c) 2003-2004  Joachim Kock and Craig Barton Upright
 # All rights reserved.
 # 
 # Distributed under a Tcl style license.  
 # 
 # ===========================================================================
 ##

# ×××× Feature Declaration ×××× #
alpha::feature windowZoom 1.0.1 "global-only" {
    # Initialization script
} {
    # Activation script
    winZoom::setBindings "Bind"
} {
    # Deactivation script
    winZoom::setBindings "unBind"
} uninstall {
    this-file
} maintainer {
    "Joachim Kock" <kock@math.unice.fr>
} description {
    This package provides an easily remembered set of key bindings for
    manipulating the current font, geometry, etc of the active window
} help {
    This package provides an easily remembered set of key bindings for
    manipulating the current font, geometry, etc of the active window.
    
    Preferences: Features
    
    The principal functions are to (1) change the 'geometry' or the font sizes
    of the active window, and (2) switch amongst all open windows or arrange
    the open windows in a specific way.

    All operations are bound to two-step key combinations consisting of
    Control-W followed by a single key.  For example:
 
	Control-W I

    means 'zoom [i]n, increasing the font size of the active window'.
    
    Click here <<winZoom::describeBindings>> to open a new window which lists
    all of the current bindings available.
}

proc windowZoom.tcl {} {}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

namespace eval winZoom {
    
    variable geometryBindings
    variable multipleBindings
    
    # Window Geometry
    array set geometryBindings {
	b {shrinkBottom         "shrink active window to [b]ottom of screen"}
	c {shrinkCenter         "shrink active window to [c]enter of screen"}
	d {shrinkDefault        "shrink active window to [d]efault size"}
	f {fullScreen           "toggle [f]ull screen to previous window size"}
	i {zoomIn               "zoom [i]n, increasing font size"}
	l {shrinkLeft           "shrink active window to [l]eft of screen"}
	o {zoomOut              "zoom [o]ut, increasing font size"}
	r {shrinkRight          "shrink active window to [r]ight of screen"}
	s {toggleSplitWindow    "[s]plit the active window"}
	t {shrinkTop            "shrink active window to [t]op of screen"}
    }
# 	m {minimize (genie)}
	
	
    # Multiple Windows.
    array set multipleBindings {
	a {tileAll              "[a]rrange windows, by 'tiling' them"}
	h {arrHorizontally      "arrange top two windows [h]orizontally"}
	n {nextWindow           "bring the [n]ext window to the front"}
	p {prevWindow           "bring the [p]revious window to the front"}
	v {arrVertically        "arrange top two windows [v]ertically"}
    }

    variable fontSizeList [list 7 8 9 10 11 12 14 16 18 20 24]
    # this should be called usableFontSizes, and default to 9 12 16 20

    # Font metrics (Monaco)
    variable colWidth
    variable rowHeight
    
    array set colWidth {
	7       5
	8       6
        9       6
        10      6
        11      7
        12      7
        13      8
        14      8
        15      9
        16      10
        17      10
        18      11
        20      12
        24      14
    }
    array set rowHeight {
	7       9
	8       10
        9       11
        10      13
        11      15
        12      16
        13      17
        14      18
        15      20
        16      21
        17      22
        18      24
        20      27
        24      32
    }
}

proc winZoom::setBindings {{which "Bind"}} {
    
    # Required for the rest of these bindings to work.
    $which 'w' <z> {prefixChar}
    # Bind all registered keys.
    foreach type [list geometry multiple] {
	variable ${type}Bindings
	foreach b [array names ${type}Bindings] {
	    set action [lindex [set ${type}Bindings($b)] 0]
	    
	    $which '${b}' <W> "winZoom::action $action"
	}
    }
    # Help windows
    $which 'b' <Wz> {winZoom::describeBindings}
    $which 'h' <Wz> {package::helpWindow windowZoom}
    # Emacs workaround, since we took over the <control>-W binding.
    $which 'w' <Wz> {::cut}
}

proc winZoom::describeBindings {} {
    
    variable geometryBindings
    variable multipleBindings
    
    set title "* Window Zoom Bindings *"
    if {[win::Exists $title]} {
	catch {bringToFront $title}
	return
    }
    set txt {
Window Zoom Bindings

All bindings start with the prefix Control-W, so the key binding for
'Shrink Left' would be

	Control-W L

which means that you press the Control modifier at the same time as you
press 'W', release those keys, and then type 'L' without modifiers.

}
    append txt "\r\t  \tWindow Geometry\r\r"
    foreach b [lsort [array names geometryBindings]] {
	set B [string toupper $b]
	append txt "    $B   [lindex $geometryBindings($b) 1]\r\r        "
	append txt "<<winZoom::action [lindex $geometryBindings($b) 0]>>\r\r"
    }
    append txt "\r\t  \tMultiple Window Arranging\r\r"
    foreach b [lsort [array names multipleBindings]] {
	set B [string toupper $b]
	append txt "    $B   [lindex $multipleBindings($b) 1]\r\r        "
	append txt "<<winZoom::action [lindex $multipleBindings($b) 0]>>\r\r"
    }
    append txt "\r\t  \tMiscellaneous Bindings\r"
    append txt {
These are special bindings:

    Control-W Control-B  Opens this bindings help window.
    Control-W Control-H  Opens the package: windowZoom help window.
    
This one is a small compensation to users of the package: emacs that will
find that the binding for Control-W no longer calls a [cut] operation:
    
    Control-W Control-W  'Cut Region'
}
    new -n $title -info $txt -mode "Text"
    help::markColourAndHyper
    win::searchAndHyperise {\[[a-zA-Z]\]} "" 1 1
    goto [minPos] ; refresh
}

proc winZoom::action {action} {
    
    switch -- $action {
	"arrHorizontally"       {::menu::winTileProc "" vertically}
	"fullScreen"            {::zoom}
	"shrinkBottom"          {::shrinkLow}
	"shrinkCenter"          {betaMessage $action}
	"shrinkDefault"         {::shrinkFull}
	"shrinkMininal"         {betaMessage $action}
	"shrinkTop"             {::shrinkHigh}
	"tileAll"               {::wintiled}
	"zoomIn"                {trueZoom 1}
	"zoomOut"               {trueZoom -1}
	default                 {::$action}
    }
}

proc winZoom::trueZoom {direction} {
    # ought to remember original position, so that you can get back with
    # zoom-back, without loosing height because of window truncation
    # 
    getWinInfo a
    set newFontSize [nextFontSize $a(fontsize) $direction]
    if {![string length $newFontSize]} {
	status::msg "Can't zoom more than that"
	return
    }
    set geomList  [getGeometry]
    set oldWidth  [lindex $geomList 2]
    set oldHeight [lindex $geomList 3]
    set colNum    [numCols $a(fontsize) $oldWidth]
    set rowNum    [numRows $a(fontsize) $oldHeight]
    set newWidth  [winWidth  $newFontSize $colNum]
    if {$direction == 1} {
	set newHeight [winHeight $newFontSize $rowNum]    
    } else {
	# This makes more sense to me (cbu)
	set newHeight $oldHeight
    }
    # Change the font, window geometry
    setFontsTabs -fontsize $newFontSize
    sizeWin $newWidth $newHeight
    status::msg "Zoomed to font size $newFontSize"
}

# ×××× Zoom Utilities ×××× #

# Returns empty string if no more sizes
proc winZoom::nextFontSize {old direction} {
    
    variable fontSizeList
    
    switch -- $direction {
	"-1" {
	    set s ""
	    foreach t $fontSizeList {
		if {$t >= $old} {break}
		set s $t
	    }
	    return $s
	}
	"1" {
	    foreach s $fontSizeList {
		if {$s > $old} {return $s}
	    }
	}
	default {
	    error "'direction' should be '-1' or '1'"
	}
    }
    # Still here?
    return ""
}

# Here we assume there is a horizontal scrollbar (15)

# Compute window width in terms of the fontsize and the number of columns
proc winZoom::winWidth {fontsize numCols} {
    variable colWidth
    return [expr ( $colWidth($fontsize) * $numCols ) + 15 + 8]
}

# Compute window height in terms of the fontsize and the number of rows
proc winZoom::winHeight {fontsize numRows} {
    variable rowHeight
    return [expr ( $rowHeight($fontsize) * $numRows ) + 15 + 8]
}

# Compute number of columns in terms of fontsize and window width
proc winZoom::numCols {fontsize winWidth} {
    variable colWidth
    return [expr ($winWidth - 15 - 8) / $colWidth($fontsize) ]
}

# Compute number of rows in terms of fontsize and window height
proc winZoom::numRows {fontsize winHeight} {
    variable rowHeight
    return [expr ($winHeight - 15 - 8) / $rowHeight($fontsize) ]
}

proc winZoom::betaMessage {action} {
    alertnote "Sorry, '[quote::Prettify $action]' is not yet available."
}

# ===========================================================================
# 
# .