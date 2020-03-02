# This file is distributed under a BSD style license

package require Winico

proc alpha::loadIcon { icofile } {
    variable smallIcon -1
    variable bigIcon -1
    
    set ico [winico create $icofile]
    set screendepth [winfo screendepth .]
    set bigsize "32x32"
    set bigpos -1
    set bigdepth 0
    set smallsize "16x16"
    set smallpos -1
    set smalldepth 0
    foreach i [winico info $ico] {
	array set opts $i
	set depth    $opts(-bpp)
	set pos      $opts(-pos)
	set geometry $opts(-geometry)
	if { $geometry=="$bigsize" && $depth<=$screendepth } {
	    if { $depth>$bigdepth } {
		set bigIcon $pos
		set bigdepth $depth
	    }
	} elseif { $geometry=="$smallsize" && $depth<=$screendepth } {
	    if { $depth>$smalldepth } {
		set smallIcon $pos
		set smalldepth $depth
	    }
	}
    }
    if { $bigIcon==-1 && $smallIcon==-1 } {
	catch {puts stderr "couldn't find $bigsize and $smallsize icons in $icofile"}
	return $ico
    } elseif { $bigIcon==-1 } {
	set bigIcon $smallIcon
	catch {puts stderr "couldn't find $bigsize icons in $icofile"}
    } elseif { $smallIcon==-1 } {
	set smallIcon $bigIcon
	catch {puts stderr "couldn't find $smallsize icons in $icofile"}
    }
    return $ico
}


