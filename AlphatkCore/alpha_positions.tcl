## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_positions.tcl"
 #                                    created: 04/12/98 {23:17:46 PM} 
 #                                last update: 02/21/2004 {07:12:32 PM} 
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

namespace eval pos {}

proc pos::compare {args} {
    ::win::parseArgs w p1 op p2
    text_wcmd $w compare $p1 $op $p2
}

proc pos::math {args} {
    ::win::parseArgs w i args
    switch -- [llength $args] {
	0 {
	    return [text_wcmd $w index $i]
	}
	1 {
	    return [text_wcmd $w index "$i [join $args {}]c"]
	}
	default {
	    return [text_wcmd $w index "$i +[eval expr $args]c"]
	}
    }
}

proc pos::diff {args} {
    ::win::parseArgs w p1 p2
    return [text_wcmd $w count $p1 $p2]
}

#¥ pos::toRowCol <pos> - converts from index position to row, column.
#  Here 'column' counts multiple times for each tab character and is
#  therefore a visual reference and may depend on the current window's
#  tabSize.
proc pos::toRowCol {args} {
    ::win::parseArgs w pos
    set row [lindex [split [text_wcmd $w index $pos] .] 0]
    set line [getText -w $w [::lineStart -w $w $pos] $pos]
    set line [text::maxSpaceForm -w $w $line]
    list $row [string length $line]
}
#¥ pos::toRowChar <pos> - converts from index position to row, char.
#  Here 'char' counts just once for each 'tab' character.
proc pos::toRowChar {args} {
    ::win::parseArgs w pos
    split [text_wcmd $w index $pos] .
}
#¥ pos::fromRowCol [-w <win>] <row> <col> - converts to window position.
#  Accepts optional -w parameter that allows window to be specified.
#  Not sure if this is ok, but can't be too bad!
proc pos::fromRowCol {args} {
    ::win::parseArgs w row col
    if {$col < 0} {
	return -code error "Negative column!"
    } elseif {$col == 0} {
	return ${row}.0
    }
    set lineStart "${row}.0"
    set lineEnd [lindex [split [text_wcmd $w index "${row}.0 lineend"] .] 1]
    set char 0
    while {$char < $lineEnd} {
	set line [getText -w $w $lineStart ${row}.$char]
	set len [string length [text::maxSpaceForm -w $w $line]]
	if {$len >= $col} {
	    break
	}
	incr char
    }
    return $row.$char
}
#¥ pos::fromRowChar [-w <win>] <row> <char> - converts to window position.
#  Accepts optional -w parameter that allows window to be specified.
proc pos::fromRowChar {args} {
    ::win::parseArgs w row char
    return $row.$char
}

