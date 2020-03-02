## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_large_file.tcl"
 #                                    created: 10/23/2003 {02:18:29 PM}  
 #                                last update: 11/20/2004 {07:23:51 PM} 
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

if {0} {
    toplevel .t
    largetext::create .t.text1 ~/Desktop/PostalOptimisationWhitePaper.pdf
    pack .t.text1 -side left -fill both -expand 1
    pack .t.scroll -side right -fill y
}

proc _listAllTextSubcommands {widget} {
    $widget .alphatktextdummy
    catch {.alphatktextdummy alphatk} msg
    destroy .alphatktextdummy

    regsub ".*must be " $msg "" msg
    regsub ", or " $msg ", " msg
    regsub -all ", " $msg " " msg
    ::split $msg
}

namespace eval largetext {
    proc create {w filename} {
	rename [text $w] ::largetext::$w
	namespace ensemble create -command ::$w -subcommands \
	  [::_listAllTextSubcommands text]
	initWidgetFile $w $filename
	initScrollbar $w
	trace add command $w delete [list rename ::largetext::$w {}]
	return $w
    }
    proc initWidgetFile {w filename} {
	set fin [open $filename r]
	bind $w <Configure> {::largetext::windowConfigure "%W" %w %h}
	largetext::largevar $w topline 1.0
	largetext::largevar $w seekline(1.0) 0
	largetext::largevar $w seekpos(0) 1.0
	largetext::largevar $w channel $fin
    }
    proc initScrollbar {w} {
	set sc [scrollbar [winfo parent $w].scroll -command [list ::largetext::yscroll $w]]
	$w configure -yscroll [list ::largetext::textyscroll $w $sc]
    }
}

proc largetext::windowConfigure {ww w h} {
}

proc largetext::yscroll {ww} {
}

proc largetext::textyscroll {ww ws min max} {
}

proc largetext::largevar {ww var args} {
    variable $ww
    eval [list set ${ww}($var)] $args
}

proc largetext::flashFrame w {
   set bg [$w cget -background]
   foreach colour {black white black white black white} {
      $w configure -background $colour
      update idletasks
      after 150
   }
   $w configure -background $bg
}

proc largetext::index {w args} {
}
