# This file (unlike most of the rest of Alphatk core)
# is distributed under a BSD style license.

package provide defaults 0.1

# On high resolution screens we want to scale the gui according to a
# dpi factor.  We only scale if there are more than 96 dpi, and if
# so we scale in proportion to the increased pixel density.

namespace eval alpha {}

set alpha::screenMult \
  [expr {double([winfo screenmmheight .])/double([winfo screenheight .])}]
if {25.4/$alpha::screenMult > 95} {
    set alpha::desired_ppmm [expr {90/25.4}]
    set alpha::scaleGui 1
} else {
    set alpha::desired_ppmm [expr {72/25.4}]
    set alpha::scaleGui 0
}

proc distanceToScreen {args} {
    if {!$::alpha::scaleGui} {
	return $args
    }
    
    foreach d $args {
	lappend res [expr {round($d/ ($::alpha::desired_ppmm * $::alpha::screenMult))}]
    }
    return $res
}

proc screenToDistance {args} {
    if {!$::alpha::scaleGui} {
	return $args
    }
    foreach d $args {
	lappend res [expr {round($d * ($::alpha::desired_ppmm * $::alpha::screenMult))}]
    }
    return $res
}


namespace eval default {
    namespace export color 
    namespace export size
    namespace export font
}

proc default::font {which} {
    variable fonts
    if {![array exists fonts]} {
	findDefaults
    }
    # Return calculated value
    set fonts($which)
}

proc default::color {which} {
    variable colors
    if {![array exists colors]} {
	findDefaults
    }
    # Return calculated value
    lindex $colors($which) 0
}

proc default::size {what} {
    variable sizes
    if {![array exists sizes]} {
	findDefaults
    }
    # Return calculated value
    set sizes($what)

}

proc default::findDefaults {} {
    variable colors
    variable sizes
    variable fonts
    toplevel .default_test ; wm withdraw .default_test
    ::menu .default_test.m ; ::button .default_test.b ; ::scrollbar .default_test.s
    .default_test.m configure -tearoff 0
    .default_test.m add command -label "hello"
    .default_test.m add command -label "hello"
    .default_test.m add command -label "hello"
    .default_test.m add command -label "hello"
    .default_test.m add command -label "hello"
    .default_test.m add command -label "hello"
    .default_test.m add command -label "hello"
    .default_test.m add command -label "hello"
    .default_test.m add command -label "hello"
    .default_test.m add command -label "hello"
    update
    set sizes(menuitemheight) [expr {[winfo reqheight .default_test.m]/10}]
    set colors(activebackground) [.default_test.m cget -activebackground]
    set colors(activeforeground) [.default_test.m cget -activeforeground]
    set colors(background) [.default_test.b cget -background]
    # Convert to RGB.
    foreach color [list activebackground activeforeground background] {
	lappend colors($color) [eval rgbToColor [winfo rgb . $colors($color)]]
    }
    set sizes(scrollbarwidth) [winfo reqwidth .default_test.s]
    destroy .default_test
    set bg [winfo rgb . [lindex $colors(background) 0]]
    set fg [list 65535 65535 65535]
    set types [list "" lightest lighter light]
    for {set i 1} {$i < 4} {incr i} {
	set col {}
	foreach dark_cpt $bg light_cpt $fg {
	    lappend col [expr {($dark_cpt * $i + $light_cpt * (4-$i))/4}]
	}
	set colors([lindex $types $i]background) [list [eval rgbToColor $col]]
    }
    set text "this is a test"
    catch {destroy .defaultButton}
    button .defaultButton -text $text
    variable buttonFont
    variable buttonPadding
    set buttonFont [.defaultButton cget -font]
    set buttonPadding [expr {[winfo reqwidth .defaultButton] - [::font measure $buttonFont $text]}]
    destroy .defaultButton
    
    switch -- [tk windowingsystem] {
	"aqua" {
	    set colors(balloonhelp) #ffffc0
	    set colors(balloonborder) #ffffc0
	    set fonts(balloonhelp) [list helvetica 10]
	    set sizes(menubarheight) 26
	    set sizes(titlebarheight) 26
	}
	"win32" {
	    if {[catch {
		set col [registry get "HKEY_CURRENT_USER\\Control Panel\\Colors" InfoWindow]
		set col [eval [list format "#%02x%02x%02x"] $col]
	    }]} {
		set col #ffffc0
	    }
	    set colors(balloonhelp) $col
	    set colors(balloonborder) #000000
	    if {[catch {
		set scheme [registry get \
		  "HKEY_CURRENT_USER\\Control Panel\\Current" "Color Schemes"]
		regexp -start 28 -- {[a-zA-Z ]*} \
		  [encoding convertfrom unicode \
		  [registry get "HKEY_CURRENT_USER\\Control Panel\\Appearance\\Schemes" "Windows Standard"]] fnt
		set fonts(balloonhelp) [list $fnt 8]
	    }]} {
		set fonts(balloonhelp) [list helvetica 10]
	    }
	    if {$::tcl_platform(os) eq "Windows NT" \
	      && $::tcl_platform(osVersion) eq 5.1} {
		# Windows XP
		if {[catch {
		    set hei [registry get \
		      "HKEY_CURRENT_USER\\Control Panel\\Desktop\\WindowMetrics"\
		      CaptionHeight]
		    set sizes(titlebarheight) [expr {-$hei/12}]
		    incr hei [registry get \
		      "HKEY_CURRENT_USER\\Control Panel\\Desktop\\WindowMetrics"\
		      MenuHeight]
		    # -$hei/12 for the titlebar + menubar.  Not sure
		    # why we need an extra 6.
		    set sizes(menubarheight) [expr {-4-$hei/12}]
		}]} {
		    set sizes(menubarheight) [distanceToScreen 46]
		    set sizes(titlebarheight) [distanceToScreen 26]
		}
	    } else {
		set sizes(menubarheight) 40
		set sizes(titlebarheight) 26
	    }
	}
	default {
	    set colors(balloonhelp) [color lighterbackground]
	    set colors(balloonborder) [color activebackground]
	    set fonts(balloonhelp) [list helvetica 10]
	    set sizes(menubarheight) 40
	    set sizes(titlebarheight) 26
	}
    }
}

proc default::buttonWidth {text} {
    variable buttonFont
    variable buttonPadding
    expr {[::font measure $buttonFont $text] + $buttonPadding}
}

proc default::rgbToColor {r g b} {
    format "#%02x%02x%02x" [expr {$r/256}] [expr {$g/256}] [expr {$b/256}]
}

proc default::showDefaults {} {
    variable colors
    toplevel .colorshow
    set i 0
    foreach name [lsort [array names colors]] {
	set col $colors($name)
	frame .colorshow.square$i -bg $col -width 50 -height 50
	label .colorshow.label$i -text $name
	grid .colorshow.square$i .colorshow.label$i
	incr i
    }
}

proc default::totalGeometry {{w .}} {
    set geom [wm geometry $w]
    regexp -- {([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)} $geom -> \
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

proc default::colorSchemeHasChanged {} {
    variable oldcolors
    variable colors
    global ALPHATK
    lappend args \
      [list source [file join $ALPHATK default.tcl]] \
      default::findDefaults \
      [list array get default::colors] 
    array set oldcolors [array get colors]
    array set colors [eval tcltk::launchNewShell $args]
    tcltk::quitRemote 
    default::recurseOverChildren .
}

proc default::reapplyColorScheme {} {
    variable oldcolors
    variable colors
    array set oldcolors [array get colors]
    findDefaults
    recurseOverChildren .
    unset oldcolors
}

proc default::recurseOverChildren {w} {
    variable oldcolors
    variable colors
    foreach col $oldcolors(background) {
	if {[$w cget -background] eq $col} {
	    $w configure -background [lindex $colors(background) end]
	}
    }
    foreach subw [winfo children $w] {
	recurseOverChildren $subw
    }
    switch -- [winfo class $w] {
	"Menu" {
	    # loop over menu entries
	}
    }
}

namespace import -force default::color
