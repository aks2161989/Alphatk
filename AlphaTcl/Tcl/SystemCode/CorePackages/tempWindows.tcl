## -*-Tcl-*- (nowrap)
 # ###################################################################
 #  AlphaTcl 
 # 
 #                                       created: 2005-08-16
 #                                   last update: 03/21/2006 {12:49:24 PM} 
 # 
 # File: "tempWindows.tcl"
 # Author: Joachim Kock <kock@mat.uab.es>
 # Many thanks to Vince Darley for streamlining all this.
 # 
 # DESCRIPTION: This file contains utility procedures for manipulating
 # temporary window geometries and temporary files linked to windows.  
 # 
 # When the use of this stuff has settled down, we should discuss and
 # decide on an appropriate API and then refactor this code.
 # 
 # ###################################################################
 ##

proc tempWindows.tcl {} {}

# ×××× Temporary files linked to windows ×××× #

# Each temporary file is linked to an open window or to a file on disk.
# 
# The data recorded for each temporary file is a list whose first entry
# is the name of the original open window (or the full path, if the 
# original is not an open window), and whose second entry is a line offset.
# The line offset is the number of lines occurring in the original file
# before the excerpt minus the number of lines inserted before the excerpt
# in the temporary file (e.g. a preamble).  So for example when in TeX
# mode a temporary latex document is created from lines 16--28 in the 
# original file by writing first a certain preamble consisting of 7 lines
# then the line offset should be 15-7=8.
# 
# To have automatic redirection from the temporary file to the original,
# appropriately shifted by the offset, use the proc
# 
#     [file::openWithSelection $file $row0 $col0 $row1 $col1]
# 
# if $file is temporary, then instead the original will be opened, and the
# selection will be adjusted by the line offset.  (If the file is not
# temporary, it will be opened normally.)  
# 
# To get more fine-grained control over redirection, read the data stored
# for a temporary file TEMP by calling [temp::attributesForFile TEMP].
# 
# To write to the array: when a new temporary file is created, register it
# by calling [temp::attributesForFile TEMP ORIGINAL OFFSET], where TEMP is
# the full path of the temporary file, ORIGINAL is the name of original 
# window (or file), and OFFSET is the line offset, calculated as above.

namespace eval temp {}

# Read and write attribute lists for temporary files.
proc temp::attributesForFile {fileName args} {
    variable tmpFileTable
    if {[llength $args]} {
	set tmpFileTable([file normalize $fileName]) $args
    } else {
	return $tmpFileTable([file normalize $fileName])
    }
}
# Remark: nothing prevents a caller from appending other bits of data to
# the list recorded for a given temp file, and reading it off again when
# needed.  If this turns out to be of any use, probably a better design
# would be to represent the data as a dict rather than just an ordered list...


# If the open window is closed then the temporary file is deleted.
hook::register closeHook ::temp::purge
proc temp::purge { windowName } {
    variable tmpFileTable

    foreach tmpFile [array names tmpFileTable] {
	if {$windowName eq [lindex $tmpFileTable($tmpFile) 0]} {
	    file delete $tmpFile
	    set res $tmpFileTable($tmpFile)
	    unset tmpFileTable($tmpFile)
	    return $res
	}
    }
}


# ×××× Temporary geometry ×××× #

# In some cases Alpha opens a file and arranges its window in some special
# way on the screen.  Important examples are diff mode and browser mode.
# To avoid that this geometry is saved and persists the next time you open
# the file, here is a mechanism that registers the original geometry when
# the window is opened, and restores it when it is closed.
# 
# It works by putting the geometry quadruple in the win array, and adding
# a special-purpose 'tempgeom' hookmode, for which there is a 
# [tempgeom::restoreGeometryPreCloseHook].  In fact its also remembers the
# selection (cursor position) and restores that (except if the file is 
# modified).
# 
# To avoid window flicker, the present version resizes the windows while
# they are in invisible state.  Another approach would be to read geometry
# and selection from the MPSR resource of the file before it is opened, and
# and write it again after it has been closed.  See also RFE 982.


# Main proc, to use instead of [edit], and also instead of [sizeWin] and
# [moveWin].  The first argument (mandatory) must be either a complete
# normalised path or a exact window name (including eventual <2> decoration).
# The remaining arguments are geometry arguments.  You should give either all
# four geometry arguments, or the first two or the last two, or none of them.
# (The return value is the exact window name.)
proc openWithTemporaryGeometry { completePathOrExactWinName {left ""} {top ""} {width ""} {height ""} } {
    if { [lcontain [winNames -f] $completePathOrExactWinName] } {
	set win $completePathOrExactWinName
    } else {
	# If the window isn't open, open it hidden to avoid flickering
	set win [edit -c -w -visibility hidden $completePathOrExactWinName]
    }
    
    set geom [getGeometry $win]
    if {$left ne "" && $top ne ""} {
	moveWin $win $left $top
    }
    if {$width ne "" && $height ne ""} {
	sizeWin $win $width $height
    }
    
    windowVisibility -w $win normal
    
    # If there is already a record, don't change it.  Otherwise we are
    # just overriding an older original-geometry with a newer, much less
    # original.  (This could happen if you apply this proc twice.)
    if { ![win::infoExists $win originalgeometry] } {
	win::setInfo $win originalgeometry $geom
    }
    win::adjustInfo $win hookmodes {lunion hookmodes tempgeom}
    if { ![win::infoExists $win originalselection] } {
	win::setInfo $win originalselection [list [getPos -w $win] [selEnd -w $win]]
    }
    return $win
}

namespace eval tempgeom {}

# Restore the original geometry for a file that was opened via
# [openWithTemporaryGeometry]
proc tempgeom::restoreGeometry { name } {
    if {[win::infoExists $name originalgeometry]} {
	set geom [win::getInfo $name originalgeometry]
	moveWin $name [lindex $geom 0] [lindex $geom 1]
	sizeWin $name [lindex $geom 2] [lindex $geom 3]
    }
    if {[win::infoExists $name originalselection]} {
	eval [list selectText -w $name] [win::getInfo $name originalselection]
    }
}

hook::register preCloseHook tempgeom::restoreGeometryPreCloseHook tempgeom
proc tempgeom::restoreGeometryPreCloseHook { name } {
    global alpha::platform alpha::version
    catch {
	# Hide the window to avoid flickering:
	if {($alpha::platform ne "alpha")} {
	    # Bug# 1989: Funky window closing behavior after a Compare operation
	    windowVisibility -w $name hidden
	}
	# Then restore the window geometry:
	restoreGeometry $name
	# Now we are ready to close the window.
    }
}

# If the user saves the file, he must have made modifications to it. 
# In that case there is no idea in remembering the original selection:
hook::register saveHook tempgeom::removeOriginalSelectionTag tempgeom
proc tempgeom::removeOriginalSelectionTag { name } {
    if { [win::infoExists $name originalselection] } {
	win::freeInfo $name originalselection
    }
}
