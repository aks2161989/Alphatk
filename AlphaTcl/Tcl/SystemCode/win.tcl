## -*-Tcl-*- (install) (nowrap)
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 #  
 #  Chuck's Additions - an Alpha hack
 #
 #  FILE: "win.tcl"
 #  					created: 4/6/98
 #					last update: 02/25/2006 {04:28:47 AM}
 #  Author: Chuck Gregory
 #  E-mail: <cgregory@mail.arc.nasa.gov>
 #	mail: Logicon
 #		  NASA Ames Research Center, Moffett Field, CA  94035
 #
 #  Description:
 #
 #	Window handling routines. All procs are bound in AlphaBits.tcl.
 #	  Recommend the following global interface preference settings:
 #
 #					MacOS 8.0	 MacOS < 8
 #		  defLeft		 6		     0
 #		  defTop		41		    38
 #		  defWidth	       510		   510
 #		  horMargin	         6		     2
 #		  tileHeight	     [707]		   426
 #		  tileLeft	         6		     0
 #		  tileMargin		22		    20
 #		  tileTop	        41		    38
 #		  tileWidth	    [1014]		   640
 #
 #  History:
 #
 #  modified  by   rev  reason
 #  --------  ---  ---  -----------
 #  04/06/98		7.1b6 original
 #  04/08/98  czg  1.0  modified for MacOS 8
 #  07/15/98  VMD	removed lisp'ish functions
 #  07/21/98  czg  1.1  fixed margin bugs in shrinkLeft & shrinkRight;
 #			documented prefs recommendations
 # ###################################################################
 ##

proc win.tcl {} {}

proc shrinkHigh {} {
    global numWinsToTile tileTop tileHeight tileMargin
    set names [winNames -f]
    set numWins [llength $names]
    if {$numWins<2} {set numWins 2}
    if {$numWins>$numWinsToTile} {set numWins $numWinsToTile}
    set width [lindex [getGeometry] 2]
    set height [expr {($tileHeight - $tileMargin) / $numWins}]
    set left [lindex [getGeometry] 0]
    sizeWin $width $height
    moveWin $left $tileTop
}

proc shrinkLow {} {
    global numWinsToTile tileTop tileHeight tileMargin
    set names [winNames -f]
    set numWins [llength $names]
    if {$numWins<2} {set numWins 2}
    if {$numWins>$numWinsToTile} {set numWins $numWinsToTile}
    set width [lindex [getGeometry] 2]
    set height [expr {($tileHeight - $tileMargin) / $numWins}]
    set left [lindex [getGeometry] 0]
    sizeWin $width $height
    moveWin $left [expr {$tileTop + $height + $tileMargin}]
}

proc singlePage {} {shrinkFull}

proc defaultSize {{win ""}} {
    global defWidth defHeight defTop defLeft
    
    if {![llength [winNames]]} {return}
    if {$win == ""} {
	set win [win::Current]
    }
    moveWin $win $defLeft $defTop
    sizeWin $win $defWidth $defHeight
}

proc shrinkFull {{win ""}} {
    global tileTop tileHeight tileLeft defWidth
    if {![llength [winNames]]} {return}
    if {$win == ""} {
	set win [win::Current]
    }
    moveWin $win $tileLeft $tileTop
    sizeWin $win $defWidth $tileHeight
}

proc shrinkLeft {} {
    global horMargin tileWidth tileLeft
    if {![llength [winNames]]} {return}
    set width [expr {($tileWidth-$horMargin)/2}]
    set oldwidth [lindex [getGeometry] 2]
    if {$oldwidth < $width} { set width $oldwidth }
    set height [lindex [getGeometry] 3]
    set top [lindex [getGeometry] 1]
    moveWin $tileLeft $top
    sizeWin $width $height
}

proc shrinkRight {} {
    global horMargin tileWidth tileLeft
    if {![llength [winNames]]} {return}
    set width [expr {($tileWidth-$horMargin)/2}]
    set oldwidth [lindex [getGeometry] 2]
    if {$oldwidth < $width} { set width $oldwidth }
    set height [lindex [getGeometry] 3]
    set top [lindex [getGeometry] 1]
    moveWin [expr {$tileWidth - $width}] $top
    sizeWin $width $height
}

# Toggle between frontmost two windows
proc swapWithNext {} {
    if {[llength [win::StackOrder]] < 2} return
    bringToFront [lindex [win::StackOrder] 1]
}
	
# Go to the window that you originally opened after the current
# window.
proc nextWindow {} {
    set len [llength [win::CreationOrder]]
    if {$len < 2} {return}
    set f [win::Current]
    set ind [lsearch -exact [win::CreationOrder] $f]
    if {$ind < 0} {error "No win '$f'"}
    set ind [expr {($ind +1) % $len}]
    bringToFront [lindex [win::CreationOrder] $ind]
}

proc nextWin {} {
    if {[llength [win::CreationOrder]] < 2} {return}
    set f [win::Current]
    set ind [lsearch -exact [win::CreationOrder] $f]
    if {$ind < 0} {error "No win '$f'"}
    set ind [expr {($ind +1) % [llength [win::CreationOrder]]}]
    set nextWindow [lindex [win::CreationOrder] $ind]
    if {[win::IsFile $nextWindow]} {
	return [file tail $nextWindow]
    } else {
	return $nextWindow
    }
}

# Go to the window that you originally opened before the current
# window.
proc prevWindow {} {
    set len [llength [win::CreationOrder]]
    if {$len < 2} {return}
    set f [win::Current]
    set ind [lsearch -exact [win::CreationOrder] $f]
    if {$ind < 0} {error "No win '$f'"}
    set ind [expr {($len + $ind -1) % $len}]
    bringToFront [lindex [win::CreationOrder] $ind]
}

proc bufferOtherWindow {} {
    global tileHeight tileTop tileWidth tileMargin
    global numWinsToTile
    set margin $tileMargin
    set win [win::Current]
    set numWins 2
    set hor 2
    set height [expr {($tileHeight/$numWins)-$margin}]
    set height [expr {$height + $margin / $numWins}]
    set width $tileWidth
    set ver $tileTop
    
    if {[llength [winNames]] < 2} {status::msg "No other window!"; return}
    set res [prompt::fromChoices "Window other half" [nextWin] -command winNames]
    
    set geo [getGeometry]
    if {([lindex $geo 2] != $width) || ([lindex $geo 3] != $height) || ([lindex $geo 0] != $hor) || (([lindex $geo 1] != $ver) && ([lindex $geo 1] != [expr {$ver + $height + $margin}]))} {
	moveWin $win 1000 0
	sizeWin $win $width $height
	moveWin $win $hor $ver
	incr ver [expr {$height + $margin}]
    } else {
	if {[lindex $geo 1] == $ver} {
	    incr ver [expr {$height + $margin}]
	} 
    }
    
    set geo [getGeometry $res]
    if {([lindex $geo 0] != $hor) || ([lindex $geo 1] != $ver) || ([lindex $geo 2] != $width) || ([lindex $geo 3] != $height)} {
	moveWin $res 1000 0
	sizeWin $res $width $height
	moveWin $res $hor $ver
    }
    bringToFront $res
}

		
	
		

proc winvertically {} {
    global tileHeight tileTop tileWidth tileMargin
    global numWinsToTile defWidth tileLeft
    set margin $tileMargin
    set names [winNames -f]
    set numWins [llength $names]
    if {$numWins<=1} return
    if {$numWins>$numWinsToTile} {set numWins $numWinsToTile}
    if {$numWins == 0} {return}
    set height [expr {($tileHeight/$numWins)-$margin}]
    set height [expr {$height + $margin / $numWins}]
    set width $defWidth
    set ver $tileTop
    for {set i 0} {$i < $numWins} {incr i} {
	sizeWin [lindex $names $i] $width $height
	moveWin [lindex $names $i] $tileLeft $ver
	set ver [expr {$ver+$margin+$height}]
    }
}

proc winhorizontally {} {
    global tileHeight tileLeft tileWidth tileTop numWinsToTile horMargin
    set names [winNames -f]
    set numWins [llength $names]
    if {$numWins<=1} return
    if {$numWins>$numWinsToTile} {set numWins $numWinsToTile}
    if {$numWins == 0} {return}
    set width [expr {($tileWidth/$numWins)-$horMargin}]
    set width [expr {$width + $horMargin / $numWins}]
    set height $tileHeight
    set hor $tileLeft
    for {set i 0} {$i < $numWins} {incr i} {
	sizeWin [lindex $names $i] $width $height
	moveWin [lindex $names $i] $hor $tileTop
	set hor [expr {$hor+$width+$horMargin}]
    }
}


proc winunequalHor {} {
    global tileLeft tileHeight tileWidth tileTop numWinsToTile horMargin
    global tileProportion
    set names [winNames -f]
    set numWins [llength $names]
    if {$numWins<2} return
    sizeWin [lindex $names 0] \
      [expr {int($tileProportion*$tileWidth) - $horMargin/2}] $tileHeight
    moveWin [lindex $names 0] $tileLeft $tileTop
    sizeWin [lindex $names 1] \
      [expr {int((1-$tileProportion)*$tileWidth) - $horMargin/2}] $tileHeight
    moveWin [lindex $names 1] \
      [expr {$tileLeft + int($tileProportion*$tileWidth) + $horMargin/2}] $tileTop
}


proc winunequalVert {} {
    global tileLeft tileMargin tileHeight tileWidth tileTop numWinsToTile
    global horMargin tileProportion defWidth
    set names [winNames -f]
    set numWins [llength $names]
    if {$numWins<2} return
    set height [expr {$tileHeight + $tileMargin}]
    sizeWin [lindex $names 0] \
      $defWidth [expr {int($tileProportion*$height) - $tileMargin}]
    moveWin [lindex $names 0] $tileLeft $tileTop
    sizeWin [lindex $names 1] \
      $defWidth [expr {int((1-$tileProportion)*$height) - $tileMargin}]
    moveWin [lindex $names 1] \
      $tileLeft [expr {$tileTop + int($tileProportion*$height)}]
}


proc wintiled {} {
    global tileHeight tileWidth numWinsToTile tileTop tcl_platform
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    set xPan 8
	    set yPan 10
	}
	default {
	    set xPan 16
	    set yPan 16
	}
    }
    set xMarg 2
    set yMarg $tileTop
    set yMax 50
    set names [winNames -f]
    set numWins [llength $names]
    if {$numWins<1} return
    set line 0	
    set height [expr {$tileHeight-$yPan*($numWins-1)}]
    set width [expr {$tileWidth-$xPan*($numWins-1)}]
    
    for {set i 0} {$i < $numWins} {incr i} {
	set j [expr {$numWins-$i-1}]
 	moveWin [lindex $names $j] [expr {$xMarg+$i*$xPan}] [expr {$yMarg+$line}]
	set line [expr {$line+$yPan}]
	if {$line>$yMax} {set line 0}
	sizeWin [lindex $names $j] $width $height
    }
}


proc winoverlay {} {
    global defHeight defWidth numWinsToTile tileTop
    set names [winNames -f]
    set numWins [llength $names]
    if {$numWins<1} return
    for {set i 0} {$i < $numWins} {incr i} {
	moveWin [lindex $names $i] 2 $tileTop
	sizeWin [lindex $names $i] $defWidth $defHeight
    }
}

proc chooseAWindow {} {
    switch -- [llength [winNames -f]] {
	0 {
	    status::msg "No window!"; return
	}
	1 {
	    if {[windowVisibility] eq "normal"} {
		status::msg "No other window!"; return
	    } else {
	        set default [win::Tail [win::Current]]
	    }
	}
    }
    if {![info exists default]} {
	set default [lindex [winNames] 1]
    }
    set name [prompt::fromChoices "Window" $default \
      -command "lsort -dictionary \[winNames\]"]
    if {[string length $name]} {
	bringToFront $name
	if {[icon -q]} { icon -f $name -o }
    }
}

proc closeAWindow {} {
    if {![llength [winNames]]} {status::msg "No window!"; return}
    set name [prompt::fromChoices "Close window" [win::CurrentTail] \
      -command "lsort -dictionary \[winNames\]"]
    bringToFront $name
    killWindow
}

proc minimizeAll {{minimize 1}} {
    set cur [win::Current]
    foreach w [winNames -f] {
	bringToFront $w
	if {$minimize} {
	    if {![icon -q]} {icon -t}
	} else {
	    if {[icon -q]}  {icon -o}
	}
    }
    bringToFront $cur
}

proc minimize {} { 
    if {![llength [winNames]]} {return}
    icon -t 
    if {[icon -q]} {
	nextWindow
    }
}

proc zoom {{win ""}} {
    global tileHeight tileWidth tileTop tileLeft
    
    if {![llength [winNames]]} {return}
    if {$win == ""} {
	set win [win::Current]
    }
    if {[win::infoExists $win nzmState]} {
	# Probably already a zoom in progress
	if {![win::infoExists $win zoomedGeo]} { return }
	if {[getGeometry $win] == [win::getInfo $win zoomedGeo]} {
	    set state [win::getInfo $win nzmState]
	    moveWin $win [lindex $state 0] [lindex $state 1]
	    sizeWin $win [lindex $state 2] [lindex $state 3]
	    win::freeInfo $win nzmState
	    return
	}
    }
    
    win::setInfo $win nzmState [getGeometry $win]
    moveWin $win $tileLeft $tileTop
    sizeWin $win $tileWidth $tileHeight
    
    win::setInfo $win zoomedGeo [list $tileLeft $tileTop $tileWidth $tileHeight]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "openDuplicate" --
 # 
 # A very basic procedure here.  We know that [win::Current] is an open
 # window, so [edit] without the "-c" flag will ask the user if s/he wants to
 # open a duplicate.  The main purpose here is to allow all other AlphaTcl to
 # _use_ the "-c" flag to avoid the "Do you want to open a copy" dialog while
 # preserving this functionality when it is needed.
 # 
 # --------------------------------------------------------------------------
 ##

proc openDuplicate {} {
    
    requireOpenWindow
    if {[win::IsFile [win::Current] fileName]} {
        return [edit $fileName]
    } else {
        error "Cancelled: you can only open a duplicate\
	  of windows that exist as files."
    }
}

#================================================================================

proc otherThing {} {
    set win [win::Current]
    getWinInfo -w $win arr
    if {$arr(split)} {
	otherPane
    } else {
	swapWithNext
    }
}

proc winAttribute {att {win {}}} {
    if {![string length $win]} {
	set win [win::Current]
    }
    getWinInfo -w $win arr
    return $arr($att)
}

proc floatName {str} {
    if {[string match "¥*" $str]} {
	foreach n [info globals {*Menu}] {
	    global $n
	    if {![catch {set $n}] && ([set $n] == $str)} {
		regexp {(.*)Menu} $n dummy name
		return "[string toupper [string index $name 0]][string range $name 1 end]"
	    }
	}
    }
    # Remove any special codes to indicate we have an icon or a keyboard
    # shortcut.
    regsub -all {(^/.|\^.$)} $str {} str
    return "[string toupper [string index $str 0]][string range $str 1 end]"
}
proc winDirty {} {
    getWinInfo arr
    return $arr(dirty)
}

proc winReadOnly {{win ""}} {
    if {$win == ""} {set win [win::Current]}
    # Bug 1206
    #goto -w $win [minPos]
    setWinInfo -w $win dirty 0
    setWinInfo -w $win read-only 1
}

proc shrinkWindow {args} {
    win::parseArgs win {shrinkWidth 0}
    
    global defHeight defWidth
    # These old constants work for 9-pt Monaco type
    #set lineht 11
    #set chwd 6
    
    # Find the size of a typical character in the window's
    # font.
    set sizing [getTextDimensions -w $win "0"]
    set lineht [expr {[lindex $sizing 3] - [lindex $sizing 1]}]
    set chwd [expr {[lindex $sizing 2] - [lindex $sizing 0]}]
    set htoff 22
    set choff 20
    
    foreach {left top wd ht} [getGeometry $win] {}
    
    set mxht [expr {[lindex [getMainDevice] 3] - $top - 5 -15}]
    set mxwd [expr {[lindex [getMainDevice] 2] - $left - 5}]
    set mnht 120
    set mnwd 200
    
    foreach {lines chars} [fileHtWd -w $win $shrinkWidth] {}
    
    if {$lines <= 1} {set lines 10}
    
    if {$lines > 0} {
	set ht [expr {$htoff + ( $lineht * (1 + $lines)) }]
    } elseif {$ht > $defHeight} {
	set ht $defHeight
    }
    
    if {$chars > 0} {
	set wd [expr {$choff + ( $chwd * (2 + $chars)) }]
    } elseif {$wd > $defWidth} {
	set wd $defWidth
    }
    
    if {$ht > $mxht} {set ht $mxht}
    if {$wd > $mxwd} {set wd $mxwd}
    if {$ht < $mnht} {set ht $mnht}
    if {$wd < $mnwd} {set wd $mnwd}
    sizeWin $win $wd $ht
}

#############################################################################
# Return the number of lines and the maximum number of characters in any 
# line of a file.  It would be nice if there was a built-in command to
# do this (i.e., compiled C code) because this is a pretty slow way to
# get the maximum line width.

proc fileHtWd {args} {
    win::parseArgs win {checkWidth 0}
    
    set text [getText -w $win [minPos] [maxPos]] 
    getWinInfo -w $win arr
    set tabw [expr {$arr(tabsize) - 1}]
    
    set lines [split $text "\r\n"]
    set nlines [llength $lines]
    
    if {$checkWidth > 1} {
	set lines [eval [list lrange $lines] [displayedLines $win]]
    }
    
    set llen 0
    if {$checkWidth > 0} {
	foreach line $lines {
	    regsub {				+°.*$} $line {} line
	    regsub {	} $line {    } line
	    set len [string length $line]
	    if {[set ntab [llength [split $line "\t"]]] > 1} {
		set len [expr {$len + $tabw*($ntab-1)}]
	    }
	    if { $len > $llen} {
		set llen $len
	    }
	}
    }
    #	alertnote "Text Height : $nlines ; Text Width : $llen "
    return [list $nlines $llen]
}

# Report what range of lines are displayed in any window.
# (A side effect is that the insertion point is moved to the 
# top of the window, if it was previously off-screen)
#
proc displayedLines {{window {}}} {
    if {$window eq {}} { set window [win::Current] }
    
    set oldPos [getPos -w $window]
    moveInsertionHere -w $window
    set top [getPos -w $window]
    set first [lindex [pos::toRowChar -w $window $top] 0]
    moveInsertionHere -w $window -last
    set bottom [getPos -w $window]
    set last [lindex [pos::toRowChar -w $window $bottom] 0]
    
    if {[pos::compare -w $window $oldPos < $top] \
      || [pos::compare -w $window $oldPos > $bottom]} {
	goto -w $window $top
    } else {
	goto -w $window $oldPos
    }
    
    return [list $first $last]
}

# ===========================================================================
# 
# .