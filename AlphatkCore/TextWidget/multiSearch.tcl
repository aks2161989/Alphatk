## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "multiSearch.tcl"
 #                                    created: 04/08/98 {21:52:56 PM} 
 #                                last update: 2006-03-29 09:06:23 
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

if {[info tclverson] >= 8.5} {
    return
}

namespace eval tw {}

set tw::checkForEmbeddedObjects 0

proc tw::multisearch {w args} {
    set debug 0
    if {$debug} {catch {puts stderr "$w search $args"}}
    
    set nocase 0 
    set forwards 1 
    set exact 1 
    set singleline 0
    set elide 0
    set badargs ""
    while {[string match \-* [set arg [lindex $args 0]]]} { 
	set args [lreplace $args 0 0] 
	switch -glob -- $arg { 
	    "--" break 
	    "-f*" { 
		set forwards 1 
	    } 
	    "-b*" { 
		set forwards 0 
	    } 
	    "-ex*" { 
		set exact 1 
	    } 
	    "-el*" { 
		set elide 1
	    } 
	    "-r*" { 
		set exact 0 
	    } 
	    "-n*" { 
		set nocase 1 
	    } 
	    "-s*" { 
		set singleline 1 
	    } 
	    "-c*" {
		if {![llength $args]} { 
		    error {no value given for "-count" option} 
		}
		if {[catch {upvar 1 [lindex $args 0] count} err]} {
		    regsub "access" $err "set" err
		    error $err
		}
		set args [lreplace $args 0 0] 
	    } 
	    default { 
		lappend badargs $arg 
	    } 
	} 
    } 
    if {[set llen [llength $badargs]]} {
	set ok "--, -backward, -count, -elide, -exact,\
	  -forward, -nocase, or -regexp"
	if {$llen > 1} { 
	    error "bad switches \"$badargs\":\
	      must be $ok" 
	} else { 
	    error "bad switch \"$badargs\":\
	      must be $ok" 
	} 
    } 
    
    switch -- [llength $args] { 
	2 { 
	    foreach {pat pos} $args {} 
	    if {$forwards} {
		if {$singleline} {
		    set limit "$pos lineend"
		} else {
		    set limit end
		}
	    } else { 
		if {$singleline} {
		    set limit "$pos linestart"
		} else {
		    set limit 1.0 
		}
	    } 
	} 
	3 { 
	    foreach {pat pos limit} $args {}
	    # Do this primarily to throw the correct
	    # error message if this limit doesn't exist.
	    set limit [index $w $limit]
	} 
	default { 
	    error "wrong # args: should be \"$w search\
	      ?switches? pattern index ?stopIndex?\""
	} 
    }
    set start 0

    if {!$exact} {
	# Setup the correct text block
	if {$forwards} {
	    set pos [tw::index $w $pos]
	    if {[lindex [::split $pos .] 1] == 0} {
		set start 0
		set text [tw::get $w $pos $limit]
	    } else {
		set start 1
		set text [tw::get $w "$pos -1c" $limit]
	    }
	    set limit [tw::index $w $limit]
	} else { 
	    set text0 [tw::get $w $pos end] 
	    set indices0 [list -1 -1] 
	    if {$nocase} { 
		regexp -nocase -indices -lineanchor -- $pat $text0 indices0 
	    } else {
		regexp -indices -lineanchor -- $pat $text0 indices0 
	    }
	    if {$debug} {
		catch {puts stderr "$indices0 '[eval string range [list $text0] $indices0]'"}
		#puts "[string length $text0] : $text0"
	    }
	    if {[lindex $indices0 0] > -1} {
		# We need this curious check to avoid problems with patterns
		# which can match an empty string.
		if {[lindex $indices0 0] > [lindex $indices0 1]} {
		    set pos0 "$pos + [lindex $indices0 1]c" 
		} else {
		    set pos0 "$pos + [lindex $indices0 0]c" 
		}
	    } else { 
		set pos0 end 
	    }
	    set text [tw::get $w $limit $pos]
	    set maxprefix [string length $text]
	    set len [string length $text] 
	    append text [tw::get $w $pos $pos0]
	    if {$debug} {
		catch {puts stderr "$len $maxprefix $text"}
	    }
	}

	set indices [list -1 -1] 
	if {$forwards} {
	    if {$nocase} {
		regexp -nocase -indices -lineanchor -start $start -- $pat $text indices 
	    } else { 
		regexp -indices -lineanchor -start $start -- $pat $text indices 
	    }
	} else {
	    while {1} {
		set back 1000
		while {1} {
		    if {[set from [expr {[string length $text] - $back}]] < 0} {
			set from 0
		    }
		    if {$nocase} { 
			if {[regexp -nocase -indices -lineanchor -start $from -- "(?:.*)($pat)" $text "" indices]} {
			    break
			}
		    } else { 
			if {[regexp -indices -lineanchor -start $from -- "(?:.*)($pat)" $text "" indices]} {
			    break
			}
		    }
		    if {$from == 0} {break}
		    incr back 1000
		}
		if {[lindex $indices 0] > $maxprefix} {
		    # We found something later than we should have.  This
		    # generally occurs because the ?:.* sucks up lots of
		    # the input string, and the real pattern we are 
		    # matching is simple and matches far along.
		    set diff [expr {[lindex $indices 0] - $maxprefix}]
		    if {$diff > 10} { set diff 10 }
		    set text [string range $text 0 [expr {[string length $text] - $diff}]]
		    set indices [list -1 -1] 
		} else { 
		    break 
		}
	    }
	    #puts stderr "$text $got $indices"
	    if {[lindex $indices 0] > $maxprefix} {
		error "Problem"
	    }
	} 
	if {[set found [lindex $indices 0]] != -1} {
	    set count [expr {1 + [lindex $indices 1] - $found}] 
	} 
    } else {
	# Exact matching
	set extralen [expr {[string length $pat]-1}]
	if {$forwards} {
	    set text [tw::get $w $pos "$limit + ${extralen}c"]
	} else {
	    set endpos "$pos + ${extralen}c"
	    if {[$w compare $endpos >= end]} {
		set endpos "end"
		set extralen [string length [$w get $pos $endpos]]
		if {$debug} {
		    puts stderr "setting extralen to $extralen"
		}
	    }
	    set text [tw::get $w $limit $endpos] 
	}
	if {$debug} {
	    puts "X${text}X"
	}
	if {$nocase} { 
	    set text [string tolower $text] 
	    set pat [string tolower $pat] 
	}
	if {[string length $pat]} {
	    if {$forwards} { 
		set found [string first $pat $text] 
	    } else { 
		set found [string last $pat $text]
		set len [expr {[string length $text] - $extralen}]
		if {$debug} {
		    puts "$found $len $extralen"
		}
	    } 
	} else {
	    if {$forwards} {
		set found 0
	    } else {
		set found [string length $text]
		set len [expr {[string length $text] - $extralen}]
	    }
	}
	if {$found != -1} { 
	    set count [string length $pat]
	} 
    } 
    if {$found == -1} { 
	set res "" 
    } else {
	if {$forwards} {
	    set res [tw::index $w "$pos + ${found}c - ${start}c"] 
	} else { 
	    set res [tw::index $w "$pos - [expr {$len - $found}]c"] 
	    if {[compare $w $res > $pos]} {
		error "Bug in multisearch backwards search: found\
		  position $res which is after start pos $pos!\
		  Called with $w $args"
	    }
	}
	variable checkForEmbeddedObjects
	if {$checkForEmbeddedObjects} {
	    if {$count > 0} {
		set origCount $count
		while {1} {
		    if {![string length [get $w $res]]} {
			# We are currently matching at the beginning of an
			# embedded image/window
			set res [index $w "$res +1c"]
			continue
		    }
		    set len [string length [get $w $res "$res + ${count}c"]]
		    if {$len == $origCount} {
			break
		    } elseif {$len > $origCount} {
			error "Found more than we thought: $res $len $count"
		    } else {
			# There is something embedded, taking up 'index' space.
			incr count [expr {$origCount - $len}]
		    }
		}
	    }
	}
    }
    if {$debug} {catch {puts stderr "$res"}}
    return $res 
} 


