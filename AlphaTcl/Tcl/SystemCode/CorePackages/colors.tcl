## -*-Tcl-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "colors.tcl"
 #                                          created: 08/21/2002 {11:49:06 AM}
 #                                      last update: 12/21/2004 {02:06:16 PM}
 # Description:
 #  
 # Implements color prefs for AlphaTcl.
 # 
 # This file is distributed under a Tcl style license.
 #  
 # ==========================================================================
 ##

alpha::feature colorPrefs 0.1.1 "global-only" {
    # Initialization script.

    # Define the standard colours.
    ensureset colorInds(foreground)	"0 0 0"
    ensureset colorInds(background)	"65535 65535 65535"
    ensureset colorInds(blue)       "0 0 65535"
    ensureset colorInds(cyan)       "0 65535 65535"
    ensureset colorInds(green)      "1151 33551 8297"
    ensureset colorInds(magenta)    "44790 1591 51333"
    ensureset colorInds(red)        "65535 0 0"
    ensureset colorInds(white)      "65535 65535 65535"
    ensureset colorInds(yellow)     "61834 64156 12512"

    colors::makeList
    menu::buildProc redefineColors colors::buildMenu
} {
    menu::insert Config submenu end redefineColors
} {
    menu::uninsert Config submenu end redefineColors
} maintainer {
} description {
    Defines the initial "foreground" "background" "blue" "cyan" etc.  colors
    used in all Alpha windows, especially for syntax coloring, and creates
    the "Config > Redefine Colors" menu
} help {
    Alpha supports automatic coloring of the text.  The "Color Prefs" package
    sets the default colors used, and provides a User Interface to change
    them via the "Config > Redefine Colors" menu.
    
    Coloring can be turned off completely by unchecking 'Coloring' in the
    dialog "Config > Preferences > Interface > Appearance".
    
    Preferences: Appearance

	  	Table Of Contents

    "# Window Colors"
    "# Syntax Coloring Support"
    "# Default Color Pref Values"
    "# Advanced Coloring Customization"

    <<floatNamedMarks>>

    
	  	Window Colors

    The "Config > Redefine Colors" menu allows you to change the colors
    used for the "Foreground" and "Background".  For example, you could
    create a "chalkboard" effect by making the background black and the the
    foreground some shade of white or green.
    
    <<colors::menuProc redefineColors foreground>>
    <<colors::menuProc redefineColors background>>
    
    Note that some color changes might not take full effect until after a
    restart.  This is a known problem (Bug# 257) that will be addressed in
    a later version of Alpha.
    

	  	Syntax Coloring Support
    
    The way Alpha colors the text depends on the current mode.  Alpha can
    automatically color three different categories of text:

	Keywords
    
    A set of words with a special meaning, e.g. keywords in programming
    languages.  Each mode might define keywords in several different
    categories, each with a different color.

	Strings

    Text delimited by double quotes.  Alpha can color single-line strings
    only, and as of this writing does not support strings in single quotes.

	Comments
    
    Comments in programming code.
    

    For details about the coloring in a specific mode, see the help file for
    the mode.  The coloring support in the different modes differ and some
    modes have a more complex coloring support than just the basic things
    mentioned above.

    Colors for keywords, strings, and comments (for applicable modes) can all
    be changed via the "Config > Mode Prefs > Preferences" menu item.  Some
    modes may offer more extensive customization.
    
    Preferences: Mode

    Note that some mode color changes might not take full effect until
    after a restart.  This is a known problem (Bug# 489) that will be
    addressed in a later version of Alpha.
    
    
	  	Default Color Pref Values
    
    By default there are seven different colors to choose between, blue, cyan,
    green, magenta, red, white, and yellow.  If you wish you can redefine
    these via the menu "Config > Redefine Colors".  For instance, you can
    redefine 'red', and any text that is currently red will then be the new
    color you specify.  In addition, there are eight other colors 'Color_9'
    through 'Color_15' which you can use to define your own colors.  Note that
    by default these colors do not show up in the mode preferences dialog
    because until you have given them a value they are undefined.
    

	  	Advanced Coloring Customization 

    If you don't find the color options in the mode preferences dialog
    sufficient, you can customize the coloring by adding some Tcl code to the
    mode preferences file.  This file is opened (or created, if necessary) via
    the "Config > Mode Prefs > Edit Prefs File" menu item.  Syntax coloring is
    defined using the command: regModeKeywords.  See the "Alpha Commands" help
    file for a complete description on how to use this command.

    As an example the line:

	regModeKeywords -a -k blue Fort {blah bladdity}
	
    will add the keywords 'blah' and 'bladdity' colored blue in Fortran mode.
}

proc colors.tcl {} {}

namespace eval colors {}

##
 # -------------------------------------------------------------------------
 #
 # "colors::validStyles" --
 #
 # Return the list of valid styles that can be used by [text::color].  This
 # is binary dependent, and might change in future updates.
 #
 # -------------------------------------------------------------------------
 ##

if {${alpha::platform} == "alpha"} {
    proc colors::validStyles {} {
	return [list "normal" "bold" "condense" "extend" \
	  "italic" "outline" "shadow" "underline"]
    }
} else {
    proc colors::validStyles {} {
	return [list "normal" "bold" "roman" "italic"\
	  "underline" "overstrike"]
    }
}

proc colors::buildMenu {} {
    Menu -n redefineColors -p colors::menuProc {
	foreground
	background
	"(-"
	blue
	cyan
	green
	magenta
	red
	white
	yellow
	"(-"
	color_9
	color_10
	color_11
	color_12
	color_13
	color_14
	color_15
    }
}

proc colors::menuProc {menu item} {
    global colorInds
    
    if {[info exists colorInds($item)]} {
	set default $colorInds($item)
    } else {
	set default "65535 65535 65535"
    }
    
    set color [eval [list colorTriple "New \"$item\":"] $default]
    if {![string length $color]} { return }
    eval setRGB $item $color
    set colorInds($item) $color
    colors::makeList
    prefs::modified colorInds
    if {[llength [winNames]]} {
	refresh
    } 
    return
}
proc colors::makeList {} {
    global alpha::colors colorInds alpha::basiccolors
    # Set up color indices
    foreach ind [array names colorInds] {
	eval setRGB $ind $colorInds($ind)
    }
    set alpha::basiccolors {none blue cyan green magenta red white yellow}
    set alpha::colors ${alpha::basiccolors}
    foreach c {color_9 color_10 color_11 color_12 color_13 color_14 color_15} {
	if {[info exists colorInds($c)]} {lappend alpha::colors $c}
    }
}
	
