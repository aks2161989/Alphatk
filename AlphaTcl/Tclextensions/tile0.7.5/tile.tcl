#
# $Id: tile.tcl,v 1.87 2006/01/20 20:00:25 jenglish Exp $
#
# Tile widget set initialization script.
#

namespace eval tile {}		;# Old namespace, being phased out
namespace eval ttk {}		;# New official namespace

### Source library scripts.
#

namespace eval tile {
    if {![info exists library]} {
	variable library [file dirname [info script]]
    }
}

source [file join $tile::library keynav.tcl]
source [file join $tile::library fonts.tcl]
source [file join $tile::library cursors.tcl]
source [file join $tile::library icons.tcl]
source [file join $tile::library utils.tcl]

### Deprecated aliases.
#

## ttk::deprecated $old $new --
#	Define $old command as a deprecated alias for $new command
#	$old and $new must be fully namespace-qualified.
#
proc ttk::deprecated {old new} {
    interp alias {} $old {} ttk::do'deprecate $old $new
}
## do'deprecate --
#	Implementation procedure for deprecated commands --
#	issue a warning (once), then re-alias old to new.
#
proc ttk::do'deprecate {old new args} {
    deprecated'warning $old $new
    interp alias {} $old {} $new
    eval [linsert $args 0 $new]
}

## deprecated'warning --
#	Gripe about use of deprecated commands. 
#
proc ttk::deprecated'warning {old new} {
    puts stderr "$old deprecated -- use $new instead"
}

### Widgets.
#	Widgets are all defined in the ::ttk namespace.
#
#	For compatibility with earlier Tile releases, we temporarily 
#	create aliases ::tile::widget, and ::t$widget.
#	Using any of the aliases will issue a warning.
#

namespace eval ttk {
    variable widgets {
	button checkbutton radiobutton menubutton label entry
	frame labelframe scrollbar
	notebook progressbar combobox separator 
	scale
    }

    variable wc
    foreach wc $widgets {
	namespace export $wc

	deprecated ::t$wc ::ttk::$wc
	deprecated ::tile::$wc ::ttk::$wc
	namespace eval ::tile [list namespace export $wc]
    }
}

### tile::ThemeChanged --
#	Called from [style theme use].
#	Sends a <<ThemeChanged>> virtual event to all widgets.
#
proc tile::ThemeChanged {} {
    set Q .
    while {[llength $Q]} {
	set QN [list]
	foreach w $Q {
	    event generate $w <<ThemeChanged>>
	    foreach child [winfo children $w] {
		lappend QN $child
	    }
	}
	set Q $QN
    }
}

### Public API.
#

## tile::availableThemes --
#	Return list of themes registered in the package database.
#
proc tile::availableThemes {} {
    set themes [list]

    foreach pkg [lsearch -inline -all -glob [package names] tile::theme::*] {
	lappend themes [lindex [split $pkg :] end]
    }

    return $themes
}

## tile::setTheme $theme --
#	Set the current theme to $theme, loading it if necessary.
#
proc tile::setTheme {theme} {
    variable currentTheme	;# @@@ Temp -- [style theme use] doesn't work
    if {[lsearch [style theme names] $theme] < 0} {
	package require tile::theme::$theme
    }
    style theme use $theme
    set currentTheme $theme
}

### Load widget bindings.
#
source [file join $tile::library button.tcl]
source [file join $tile::library menubutton.tcl]
source [file join $tile::library scrollbar.tcl]
source [file join $tile::library scale.tcl]
source [file join $tile::library progress.tcl]
source [file join $tile::library notebook.tcl]
source [file join $tile::library paned.tcl]
source [file join $tile::library entry.tcl]
source [file join $tile::library combobox.tcl]
source [file join $tile::library treeview.tcl]
source [file join $tile::library dialog.tcl]

## Label and Labelframe bindings:
#  (not enough to justify their own file...)
#
bind TLabelframe <<Invoke>>	{ keynav::traverseTo [tk_focusNext %W] }
bind TLabel <<Invoke>>		{ keynav::traverseTo [tk_focusNext %W] }

### Load themes.
#
source [file join $tile::library defaults.tcl]
source [file join $tile::library classicTheme.tcl]
source [file join $tile::library altTheme.tcl]
source [file join $tile::library stepTheme.tcl]
source [file join $tile::library clamTheme.tcl]


### Choose platform-specific default theme.
#
# Notes: 
#	+ xpnative takes precedence over winnative if available.
#	+ On X11, users can use the X resource database to
#	  specify a preferred theme (*TkTheme: themeName)
#

set ::tile::defaultTheme "default"

if {[package provide tile::theme::winnative] != {}} {
    source [file join $tile::library winTheme.tcl]
    set ::tile::defaultTheme "winnative"
}
if {[package provide tile::theme::xpnative] != {}} {
    source [file join $tile::library xpTheme.tcl]
    set ::tile::defaultTheme "xpnative"
}
if {[package provide tile::theme::aqua] != {}} {
    source [file join $tile::library aquaTheme.tcl]
    set ::tile::defaultTheme "aqua"
}

set tile::userTheme [option get . tkTheme TkTheme]
if {$tile::userTheme != {}} {
    if {    [lsearch [style theme names] $tile::userTheme] >= 0
        || ![catch [list package require tile::theme::$tile::userTheme]]
    } {
	set ::tile::defaultTheme $tile::userTheme
    }
}

tile::setTheme $::tile::defaultTheme

#*EOF*
