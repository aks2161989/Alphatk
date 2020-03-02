## -*-Tcl-*- (install) (nowrap)
 # This file : manipCols.tcl 
 #           Created : 2000-05-26 00:20:13
 # Last modification : 2005-04-25 19:58:03
 # Author : Bernard Desgraupes
 # e-mail : <bdesgraupes@easyconnect.fr> 
 # Web-page : <http://webperso.easyconnect.fr/bdesgraupes/> 
 # Comments : this is a feature for Alpha.
 # It allows you to manipulate columns  in  a  tabulated  text  material  :
 # copying, inserting, appending, transposing, twiddling, deleting,  sorting,
 # numbering or (un/)equalizing columns, formatting text in columns etc.
 #            For more information, click here : <ManipCols Help> or just
 #            edit this help file from the Help menu.
 # 
 # (c) Copyright : Bernard Desgraupes, 2000-2005
 #         All rights reserved.
 # This software is free software. See licensing terms in the ManipCols Help file.
 ##


alpha::feature manipCols 1.2.2 global-only {} {
    menu::buildProc Columns menu::buildcolumnsMenu
    menu::buildProc ColumnsUtilities menu::buildColsUtilsMenu
    menu::buildProc ColumnsSorting menu::buildColsSortingMenu
    menu::buildProc ColumnsFormatting menu::buildColsFormatMenu
    menu::insert Text items 0 "(-)"
    menu::insert Text submenu "(-)" Columns
    package::addPrefsDialog manipCols
    hook::register requireOpenWindowsHook [list Text Columns] 1
} {
    menu::uninsert Text submenu end Columns
    menu::uninsert Text items end "(-"
    if {[info exists cols_params]} {
        unset cols_params
    } 
} uninstall {this-file} maintainer {
    "Bernard Desgraupes" <bdesgraupes@easyconnect.fr> <http://webperso.easyconnect.fr/bdesgraupes/> 
}  help {file "ManipCols Help"}

namespace eval cols {}

# # # # # Columns menu preferences # # # # #
# 
# Color for columns colorizing
newPref v columnsColor blue manipCols
# Default separator between columns
newPref v columnsSeparator "\\t" manipCols
# Minimum width allowed for text columnizing
newPref v minColumnWidth {15} manipCols
if {$tcl_platform(platform) == "windows"} {
    # Character to use for prefix bindings
    newPref v prefixBindingChar "D" manipCols
} else {
    # Character to use for prefix bindings
    newPref v prefixBindingChar "C" manipCols
}

# # # # # Initialisation of some variables # # # # #
# The current separating character :
set cols_params(colsep) $manipColsmodeVars(columnsSeparator)
# The number of the last numbered row :
set cols_params(lastnumrow) 1

# # # # # Building the menu # # # # #

proc menu::buildcolumnsMenu {} {
    set ma {
	"copyColumns"
	"insertColumns"
	"appendColumns"
	"cutColumns"
	"deleteColumns"
	"twiddleColumns"
	"transposeColumns"
	"colorizeColumns"
	"(-"
    }
    lappend ma [list Menu -n ColumnsFormatting {}]
    lappend ma [list Menu -n ColumnsSorting {}]
    lappend ma [list Menu -n ColumnsUtilities {}]
    
    return [list build $ma cols::MenuProc {ColumnsFormatting ColumnsSorting ColumnsUtilities} "Columns"]
}

proc menu::buildColsFormatMenu {} {
    set ma {
	"equalizeColumns"
	"unequalizeColumns"
	"completeRows"
	"(-"
	"rightJustify"
	"center"
	"leftJustify"
	"(-"
	"insertRowsNumbers"
	"insertNumbersFrom…"
	"(-"
	"columnizeText"
	"multiColumnizeText"
	"uncolumnizeText"
}
    return [list build $ma cols::colsFormatProc {} ]
}

proc menu::buildColsSortingMenu {} {
    set ma {
	"sortColumns"
	"reverseSortColumns"
	"numSortColumns"
	"reverseNumSortColumns"
	"(-"
	"sortRows"
	"reverseSortRows"
	"numSortRows"
	"reverseNumSortRows"
    }
    return [list build $ma cols::colsSortingProc {} ]
}

proc menu::buildColsUtilsMenu {} {
    set ma {
	"setMargins…"
	"columnsSeparator…" 
	"columnsBindings…"
	"columnsTutorial" 
}
    return [list build $ma cols::colsUtilsProc {} ]
}

# # # # # Menu items procs # # # # #

proc cols::MenuProc {menu item} {
    regsub " " $item "" item
    set item "[string tolower [string range $item 0 0]][string range $item 1 end]"
    eval cols::$item
}

proc cols::colsFormatProc {menu item} {
    regsub " " $item "" item
    set item "[string tolower [string range $item 0 0]][string range $item 1 end]"
    switch -- $item {
	"insertRowsNumbers"  {cols::insertRowsNumbers }
	"insertNumbersFrom"  {cols::insertRowsNumbers 1}
	default {
	    eval cols::$item
	}
    }
}

proc cols::colsSortingProc {menu item} {
    switch $item {
	"sortColumns"  {cols::sortColumns increasing}
	"reverseSortColumns"  {cols::sortColumns decreasing}
	"numSortColumns"  {cols::sortColumns increasing integer}
	"reverseNumSortColumns"  {cols::sortColumns decreasing integer}
	"sortRows"  {cols::sortRows increasing}
	"reverseSortRows"  {cols::sortRows decreasing}
	"numSortRows"  {cols::sortRows increasing integer}
	"reverseNumSortRows"  {cols::sortRows decreasing integer}
    }
}

proc cols::colsUtilsProc {menu item} {
    global tileLeft tileTop tileWidth errorHeight manipColsmodeVars
    regsub " " $item "" item
    set item "[string tolower [string range $item 0 0]][string range $item 1 end]"
    switch $item {
	"columnsBindings"  {
	    set mess "KEY BINDINGS AVAILABLE FOR COLUMNS MANIPULATION\n\n"
	    append mess "Press 'ctrl-[string tolower $manipColsmodeVars(prefixBindingChar)]',\
	      release, then hit one of the following letters:\n"
	    append mess "  'a'    to <a>ppend columns\n"
	    append mess "  'b'    to show this info about <b>indings\n"
	    append mess "  'c'    to <c>opy columns\n"
	    append mess "  'd'    to <d>elete columns\n"
	    append mess "  'e'    to <e>qualize columns (left jusified)\n"
	    append mess "  'f'    to insert rows numbers <f>rom a certain value\n"
	    append mess "  'i'    to <i>nsert columns\n"
	    append mess "  'j'    to <j>ustify text\n"
	    append mess "  'k'    to <k>olorize columns\n"
	    append mess "  'm'    to center columns (m for <m>iddle)\n"
	    append mess "  'n'    to <n>umber rows\n"
	    append mess "  'o'    to sort columns in increasing <o>rder\n"
	    append mess "  'p'    to com<p>lete rows\n"
	    append mess "  'r'    to <r>ight justify columns\n"
	    append mess "  's'    to change the columns <s>eparator\n"
	    append mess "  't'    to <t>ranspose columns and rows\n"
	    append mess "  'u'    to <u>nequalize columns\n"
	    append mess "  'v'    to set the margin <v>alues for columnizing\n"
	    append mess "  'w'    to t<w>iddle columns\n"
	    append mess "  'x'    to e<x>tract columns and copy to the scrap\n"
	    append mess "  'z'    to uncolumni<z>e\n"
	    if {[package::active moreCols]} {
		append mess "Available only with the \'More Cols\' feature :\n"
		append mess "  'h'    to convert a table to <h>tml code\n"
		append mess "  'l'    to convert a table to a <l>atex tabular environment\n"
	    } 
	    new -g $tileLeft $tileTop [expr int($tileWidth*.5)] \
	      [expr int($errorHeight *2.8)] -n "* Columns Bindings *" -info $mess
	    set start [minPos]
	    while {![catch {search -f 1 -s -r 1 {('|<)[a-z-]+('|>)} $start} res]} {
		eval text::color $res 1
		set start [lindex $res 1]
	    }
	    text::color [minPos] [nextLineStart [minPos]] 5
	    refresh
	}
	"columnsTutorial"   {help::openExample "ManipCols Example"}
	default {
	    eval cols::$item
	}
    }
}


# # # # # Columns geometry procs # # # # #

proc cols::findColsRange {} {
    global cols_params 
    set start [getPos]
    set end [selEnd]
    set char [lookAt [pos::math $end - 1]]
    if {$char == "\r" || $char == "\n"} {
	set end [pos::math $end -1]
    }
    set cols_params(lastcolpos) [cols::endOfColumn $end]
    set cols_params(lastlipos) [cols::endOfLinePos $end]    
    set cols_params(inicolpos) [cols::startOfColumn $start]
    set cols_params(inilipos) [lineStart $start]
    set cols_params(botcol) [cols::getColsPos $end]
    set pos [cols::getColsPos $start]
    if {[expr {$pos > $cols_params(botcol)}]} {
	set cols_params(topcol) $cols_params(botcol)
	set cols_params(botcol) $pos
    } else {
	set cols_params(topcol) $pos
    }
    if {$cols_params(topcol)=="0"} {set cols_params(topcol) 1}
    if {$cols_params(botcol)=="0"} {set cols_params(botcol) 1}
}

proc cols::findTableWidth {} {
    global cols_params storedtbl
    if {[pos::compare [getPos] == [selEnd]]} {
	alertnote "No region selected."
	return
    }
    set cols_params(inilipos) [lineStart [getPos]]
    set cols_params(lastlipos) [cols::endOfLinePos [selEnd]]    
    set storedtbl [split [getText $cols_params(inilipos) $cols_params(lastlipos)] "\n\r"]
    set tblwd 1
    foreach line $storedtbl {
	eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	if {[expr {[llength $line] > $tblwd}]} {set tblwd [llength $line]}
    }
    return $tblwd
}


# # # # # Columns manipulation procs # # # # #

proc cols::copyColumns {} {
    global cols_params 
    cols::findColsRange
    set result ""
    set storedtbl [split [getText $cols_params(inilipos) $cols_params(lastlipos)] "\n\r"]
    foreach line $storedtbl {
	eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	set line [lrange $line [expr {$cols_params(topcol)-1}] [expr {$cols_params(botcol)-1}]]
	eval [concat lappend result \[join \{$line\} \"$cols_params(colsep)\"\]]
    }
    set storedtbl [join $result "\r"]
    putScrap $storedtbl
    if {$cols_params(botcol)==$cols_params(topcol)} {
	set mess "column $cols_params(botcol)"
    } else {
	set mess "columns $cols_params(topcol) to $cols_params(botcol)"
    }
    status::msg "Copied region: $mess"
}

proc cols::appendColumns {} {
    global cols_params 
    set scraptbl [split [getScrap] "\n\r"]
    cols::findColsRange
    set result ""
    set storedtbl [split [getText $cols_params(inilipos) $cols_params(lastlipos)] "\n\r"]
    set lenscrap [llength $scraptbl]
    set lentbl [llength $storedtbl]
    if {[expr {$lenscrap < $lentbl}]} {
	set numli $lenscrap
	set tmp [lindex [pos::toRowChar $cols_params(inilipos)] 0]
	set tmp [expr {$tmp + $numli -1}]
	set tmp [pos::fromRowChar $tmp 0]
	set cols_params(lastlipos) [cols::endOfLinePos $tmp]    
    } else {
	set numli $lentbl
    }
    for {set i 0} {$i < $numli} {incr i} {
	set line [lindex $storedtbl $i]
	eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	set appline [lindex $scraptbl $i]
	lappend line $appline
	eval [concat lappend result \[join \{$line\} \"$cols_params(colsep)\"\]]
    }
    deleteText $cols_params(inilipos) $cols_params(lastlipos)
    insertText [join $result "\r"]
    status::msg "Appended columns to table"
}

proc cols::insertColumns {} {
    global cols_params 
    set scraptbl [split [getScrap] "\n\r"]
    cols::findColsRange
    set result ""
    set storedtbl [split [getText $cols_params(inilipos) $cols_params(lastlipos)] "\n\r"]
    set lenscrap [llength $scraptbl]
    set lentbl [llength $storedtbl]
    if {[expr {$lenscrap < $lentbl}]} {
	set numli $lenscrap
	set tmp [lindex [pos::toRowChar $cols_params(inilipos)] 0]
	set tmp [expr {$tmp + $numli -1}]
	set tmp [pos::fromRowChar $tmp 0]
	set cols_params(lastlipos) [cols::endOfLinePos $tmp]    
    } else {
	set numli $lentbl
    }
    for {set i 0} {$i < $numli} {incr i} {
	set line [lindex $storedtbl $i] 
	eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	set line [linsert $line [expr {$cols_params(topcol)-1}] [lindex $scraptbl $i]]
	eval [concat lappend result \[join \{$line\} \"$cols_params(colsep)\"\]]
    }
    deleteText $cols_params(inilipos) $cols_params(lastlipos)
    insertText [join $result "\r"]
    status::msg "Inserted columns before column $cols_params(topcol)"
}

proc cols::insertRowsNumbers {{setStart 0}} {
	global cols_params
	set scraptbl [split [getScrap] "\n\r"]
	cols::findColsRange
	set result ""
	if {$setStart != 0} {
		if {[catch {prompt "From which number ?" $cols_params(lastnumrow)} start]} {
			return
		} 
	} else {
		set start 1
	}
	set i [expr {$start-1}]
	set storedtbl [split [getText $cols_params(inilipos) $cols_params(lastlipos)] "\n\r"]
	foreach line $storedtbl {
		set i [incr i]
		eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
		set line [linsert $line 0 $i]
		eval [concat lappend result \[join \{$line\} \"$cols_params(colsep)\"\]]
	}
	set cols_params(lastnumrow) [incr i]
	deleteText $cols_params(inilipos) $cols_params(lastlipos)
	insertText [join $result "\r"]
	status::msg "[expr $i - $start] rows numbered"
}

proc cols::twiddleColumns {} {
    global cols_params 
    cols::findColsRange
    if {$cols_params(botcol)==$cols_params(topcol)} {return}
    set result ""
    set storedtbl [split [getText $cols_params(inilipos) $cols_params(lastlipos)] "\r\n"]
    foreach line $storedtbl {
	eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	if {[expr {[llength $line]<$cols_params(botcol)}]} {
	    alertnote "Some rows are too short for twiddling. Use \"Complete Rows\" to make your rows equal"
	    return
	} 
	set lft [lindex $line [expr {$cols_params(topcol)-1}]]
	set rt [lindex $line [expr {$cols_params(botcol)-1}]]
	set line [lreplace $line [expr {$cols_params(topcol)-1}] [expr {$cols_params(topcol)-1}] $rt]
	set line [lreplace $line [expr {$cols_params(botcol)-1}] [expr {$cols_params(botcol)-1}] $lft]
	eval [concat lappend result \[join \{$line\} \"$cols_params(colsep)\"\]]
	}
	deleteText $cols_params(inilipos) $cols_params(lastlipos)
	insertText [join $result "\r"]
	status::msg "Twiddled columns $cols_params(topcol) and $cols_params(botcol)"
}
   
proc cols::transposeColumns {} {
    global cols_params 
    cols::findColsRange
    
    set nbcols [cols::findTableWidth]
    set res ""
    set eol ""
    set end $cols_params(lastlipos)
    set char [lookAt [pos::math $end - 1]]
    if {$char == "\r" || $char == "\n"} {
	set end [pos::math $end -1]
	set eol $char
    }
    set storedtbl [split [getText $cols_params(inilipos) $end] "\r\n"]
    foreach line $storedtbl {
	eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	if {[expr {[llength $line]<$cols_params(botcol)}]} {
	    alertnote "All rows must have the same number of cells. Use \"Complete Rows\" to make your rows equal"
	    return
	} 
	for {set i 0} {$i < $nbcols} {incr i} {
	eval [concat lappend result($i) \{[lindex $line $i]\}]
	}
    }
    deleteText $cols_params(inilipos) $cols_params(lastlipos)
    for {set i 0} {$i < $nbcols} {incr i} {
	eval [concat lappend res \[join \{$result($i)\} \"$cols_params(colsep)\"\]]
	}
    insertText "[join $res "\r"]$eol"
    status::msg "Transposed rows and columns"
}

proc cols::deleteColumns {} {
    global cols_params 
    cols::findColsRange
    if {$cols_params(botcol)==$cols_params(topcol)} {
	set mess "column $cols_params(botcol)"
    } else {
	set mess "columns $cols_params(topcol) to $cols_params(botcol)"
    }
    set ans [askyesno "OK to delete selection in $mess ?"]
    if {$ans=="yes"} {
	set result ""
	set storedtbl [split [getText $cols_params(inilipos) $cols_params(lastlipos)] "\n\r"]
	foreach line $storedtbl {
	    eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	    set lenli [llength $line]
	    if {![expr {$lenli < $cols_params(topcol)}]} {
		set line [lreplace $line [expr {$cols_params(topcol)-1}] [expr {$cols_params(botcol)-1}]]   
	    } 
	    eval [concat lappend result \[join \{$line\} \"$cols_params(colsep)\"\]]
	}
	deleteText $cols_params(inilipos) $cols_params(lastlipos)
	insertText [join $result "\r"]
	status::msg "Deleted selected region in $mess"
    } else {return}
}


proc cols::cutColumns {} {
    global cols_params 
    cols::findColsRange
    if {$cols_params(botcol)==$cols_params(topcol)} {
	set mess "column $cols_params(botcol)"
    } else {
	set mess "columns $cols_params(topcol) to $cols_params(botcol)"
    }
    set ans [askyesno "OK to cut off selection in $mess and send a copy to the system scrap ?"]
    if {$ans=="yes"} {
	set result ""
	set texttoscrap ""
	set storedtbl [split [getText $cols_params(inilipos) $cols_params(lastlipos)] "\n\r"]
	foreach line $storedtbl {
	    eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	    set lenli [llength $line]
	    if {![expr {$lenli < $cols_params(topcol)}]} {
		set tmpline [lrange $line [expr {$cols_params(topcol)-1}] [expr {$cols_params(botcol)-1}]]
		eval [concat lappend texttoscrap \[join \{$tmpline\} \"$cols_params(colsep)\"\]]
		set line [lreplace $line [expr {$cols_params(topcol)-1}] [expr {$cols_params(botcol)-1}]]   
	    } 
	    eval [concat lappend result \[join \{$line\} \"$cols_params(colsep)\"\]]
	}
	deleteText $cols_params(inilipos) $cols_params(lastlipos)
	insertText [join $result "\r"]
	set texttoscrap [join $texttoscrap "\r"]
	putScrap $texttoscrap
	status::msg "Cut selected region in $mess and copied to scrap"
    } else {return}
}

proc cols::sortColumns {order {int ""}} {
    global cols_params
    cols::findColsRange
    set ans [askyesno "OK to sort column(s) in $int $order order ?"]
    if {$ans=="yes"} {
	set result ""
	set i 0
	set storedtbl [split [getText $cols_params(inilipos) $cols_params(lastlipos)] "\n\r"]
	foreach line $storedtbl {
	    eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	    set lftli($i) [lrange $line 0 [expr {$cols_params(topcol)-2}]]
	    if {$int == ""} {
		set extract [lrange $line [expr {$cols_params(topcol)-1}] [expr {$cols_params(topcol)-1}]]		    
	    } else {
		set extract [lindex $line [expr {$cols_params(topcol)-1}]]
	    }
	    if {[expr ![regexp {^\{} $extract] && {$int==""}]} {set extract "\{$extract\}"}
	    lappend remain($extract) [lrange $line $cols_params(topcol) [expr {$cols_params(botcol)-1}]]
	    set rtli($i) [lrange $line $cols_params(botcol) end]
	    lappend result $extract
	    set i [incr i]
	}
	if {$int == ""} {
	    set insidetbl [lsort -dictionary -$order $result]
	} else {
	    set insidetbl [lsort -dictionary -$order -$int $result]
	}
	set result ""
	set i 0
	foreach line $insidetbl {
	    set resli $lftli($i)
	    lappend resli [lindex $line 0]
	    if {$cols_params(topcol)!=$cols_params(botcol)} {
		eval [concat lappend resli \[join \{[lindex $remain($line) 0]\} \"$cols_params(colsep)\"\]]
		set remain($line) [lreplace $remain($line) 0 0]  
	    } 
	    if {$rtli($i)!={}} {
		eval [concat lappend resli \[join \{$rtli($i)\} \"$cols_params(colsep)\"\]]
	    }
	    eval [concat lappend result \[join \{$resli\} \"$cols_params(colsep)\"\]]
	    set i [incr i]
	}
	deleteText $cols_params(inilipos) $cols_params(lastlipos)
	insertText [join $result "\r"]
	unset remain
	status::msg "Columns sorting done"
    } else {return}
}

proc cols::sortRows {order {int ""}} {
    global cols_params
    cols::findColsRange
    set ans [askyesno "OK to sort each row in $int $order order ?"]
    if {$ans=="yes"} {
	set result ""
	set storedtbl [split [getText $cols_params(inilipos) $cols_params(lastlipos)] "\n\r"]
	foreach line $storedtbl {
	    eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	    if {$int == ""} {
		set line [lsort -dictionary -$order $line]   		    
	    } else {
		set line [lsort -dictionary -$order -$int $line]   		    
	    }
	    eval [concat lappend result \[join \{$line\} \"$cols_params(colsep)\"\]]
	}
	deleteText $cols_params(inilipos) $cols_params(lastlipos)
	insertText [join $result "\r"]
	status::msg "Rows sorting done"
    } else {return}
}

# This proc calculates the max length of each of  the  selected  columns  and
# appends the necessary amount of blank space  to  each  item  so  that  each
# column has a unique width. It uses a flag to specify alignment  within  the
# colums : l for left, c for center, r for right. Default is left  justified.
# Depending on the effect you want to achieve, you could first  equalize  all
# the columns, then right justify or center some of them.
proc cols::equalizeColumns { {side "l"} } {
    global cols_params 
    cols::findColsRange
    set result ""
    set storedtbl [split [getText $cols_params(inilipos) $cols_params(lastlipos)] "\n\r"]
    # First find the max length of each column
    foreach line $storedtbl {
	eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	set lenli [llength $line]
	if {[expr $lenli > $cols_params(botcol)]} {
	    set lenli $cols_params(botcol)
	} 
	for {set i [expr $cols_params(topcol) - 1]} {$i < $lenli} {incr i} {
	    set itemlen [string length [lindex $line $i]]
	    if {![info exists collen($i)]} {		
		set collen($i) $itemlen
	    } else {		
		if {[expr {$itemlen>$collen($i)}]} {
		    set collen($i) $itemlen
		} 
	    }
	}
    }
    # Now extend each column to its max length adding spaces to the right
    foreach line $storedtbl {
	eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	set lenli [llength $line]
	if {[expr $cols_params(topcol) > 1]} {
	    set resli [lrange $line 0 [expr $cols_params(topcol) - 2]]
	} else {
	    set resli ""
	}
	if {[expr $lenli > $cols_params(botcol)]} {
	    set lenli $cols_params(botcol)
	} 
	for {set i [expr $cols_params(topcol) - 1]} {$i < $lenli} {incr i} {
	    set itm [string trim [lindex $line $i] " "]
	    set itemlen [string length $itm]
	    set diff [expr {$collen($i) - $itemlen}]
	    if {$diff} {
		switch $side {
		    "l" {lappend resli "$itm[format %${diff}s ""]"}
		    "r" {lappend resli "[format %${diff}s ""]$itm"}
		    "c" {
			set rt [expr $diff/2]
			set lf [expr $diff - $rt]
			lappend resli "[format %${lf}s ""]$itm[format %${rt}s ""]"
		    }
		}
	    } else {
		lappend resli $itm
	    }
	}
	set rtli [lrange $line $cols_params(botcol) end]
	if {$rtli!={}} {
	    eval [concat lappend resli \[join \{$rtli\} \"$cols_params(colsep)\"\]]
	}
	eval [concat lappend result \[join \{$resli\} \"$cols_params(colsep)\"\]]
    }
    deleteText $cols_params(inilipos) $cols_params(lastlipos)
    insertText [join $result "\r"]
    status::msg "Equalisation done"
}

# This proc removes any trailing blank spaces at the right of any item.
proc cols::unequalizeColumns {} {
    global cols_params 
    cols::findColsRange
    set result ""
    set txt [getText $cols_params(inilipos) $cols_params(lastlipos)]
    if {$cols_params(colsep) == " "} {
	regsub -all " +" $txt " " txt
    } else {
	set storedtbl [split $txt "\n\r"]
	foreach line $storedtbl {
	    set resli ""
	    eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	    set lenli [llength $line]
	    for {set i 0} {$i < $lenli} {incr i} {
		lappend resli [string trim [lindex $line $i] " "]
	    }
	    eval [concat lappend result \[join \{$resli\} \"$cols_params(colsep)\"\]]
	}
	set txt [join $result "\r"]
    }    
    deleteText $cols_params(inilipos) $cols_params(lastlipos)
    insertText $txt
    status::msg "Unequalisation done"
}

proc cols::completeRows {} {
    global storedtbl cols_params
    set tblwd [cols::findTableWidth]
    foreach line $storedtbl {
	eval [concat set line \[split {$line} \"$cols_params(colsep)\"\]]
	set diff [expr {$tblwd - [llength $line]}]
	if {$tblwd} {
	    for {set i 0} {$i < $diff} {incr i} {
		lappend line {}
	    }
	}
	eval [concat lappend result \[join \{$line\} \"$cols_params(colsep)\"\]]
    }
    deleteText $cols_params(inilipos) $cols_params(lastlipos)
    insertText [join $result "\r"]
    status::msg "Rows completed to $tblwd cols."
}

proc cols::rightJustify {} {cols::equalizeColumns r}
    
proc cols::center {} {cols::equalizeColumns c}
    
proc cols::leftJustify {} {cols::equalizeColumns l}



# # # # # Positioning utilities # # # # #

# A proc to find the number of the column where the cursor is currently positionned.
# Cursor doesn't move.
proc cols::getColsPos {pos} {
    global cols_params
    set currpos $pos
    set tmp [getText [lineStart $pos] $currpos]
    eval [concat set tmp \[split {$tmp} \"$cols_params(colsep)\"\]]
    return [llength $tmp]
}

# A proc to find the absolute position of the beginning of the current column
# (column where the cursor is located).
proc cols::startOfColumn {pos} {
    return [cols::edgeOfColumn 0 $pos]
}

# A proc to find the absolute position of the end of the current column
# (column where the cursor is located).
proc cols::endOfColumn {pos} {
    return [cols::edgeOfColumn 1 $pos]
}

# Get the position of the end of a line without any movement of cursor
proc cols::endOfLinePos {pos} {
    set end [nextLineStart $pos]
    set char [lookAt [pos::math $end - 1]]
    if {$char == "\r" || $char == "\n"} {
	set end [pos::math $end -1]
    }
    return $end
}

# A proc to find the absolute position of the edge (0 for beginning, 1 for end)
# of the current column. Cursor does't move. Positions (end, start, currpos) are quoted 
# for Alphatk compatibility: it would otherwise break them in case they contain spaces
# because of the 'eval concat'.
proc cols::edgeOfColumn {seadir pos} {
    global cols_params
    set currpos $pos
    # looking (upto the end of the line) for the ending of the column
    if {$seadir} {
	set end [cols::endOfLinePos $pos]
	if {![catch {eval [concat search -f $seadir -s -r 1 -l \"$end\" {$cols_params(colsep)} \"$currpos\"]} res]} {
	    set idx [expr {$seadir? 0:1}]
	    return [lindex $res $idx]
	} else {
	    return $end
	}
    }
    # looking (upto to the start of the line) for the beginning of the column
    set start [lineStart [getPos]]
    if {![catch {eval [concat search -f $seadir -s -r 1 {$cols_params(colsep)} \"$currpos\"]} res] && [expr {[lindex $res 0] >= $start}]} {
	set idx [expr {$seadir? 0:1}]
	return [lindex $res $idx]  
    } else {
	return $start
    }
}

# A proc to find the absolute position of the n-th column when
# moving to the right on the same line. If such a column does not exist 
# (n is too big), then return the position of the end of the line.
proc cols::nextColPos {pos {offset 1}} {
    global cols_params
    set start $pos
    set end [cols::endOfLinePos $pos]
    set cnt 0
    while {![catch {eval [concat search -f 1 -s -r 1 -l \"$end\" {$cols_params(colsep)} \"$start\"]} res]} {
	set cnt [incr cnt]
	if {[expr {$cnt==$offset}]} {
	    return [lindex $res 1]
	}
	set start [lindex $res 1]
    }
    return $end
}

proc cols::columnsSeparator {} {
	global cols_params
	if {$cols_params(colsep)!="\\t"} {
		set sep [string trimleft $cols_params(colsep) "\\" ]
	} else {
		set sep $cols_params(colsep)
	}
	if {[catch {prompt "Choose a columns separator:\rsingle char only (\\t for tab)." $sep} rep]} {
		return
	} 
	if {$rep == "-" || $rep == "$" || $rep == "^" || $rep == "*" || $rep == "+" || $rep == "." || $rep == "\""} {
		set cols_params(colsep) "\\$rep"
	} elseif {$rep==""} {
		return
	} else {
		set cols_params(colsep) $rep
	}
}

# # # # # Columns colorizing # # # # #

proc cols::colorizeColumns {} {
    global cols_params
    cols::findColsRange
    cols::colorize $cols_params(topcol) $cols_params(botcol) $cols_params(inicolpos) $cols_params(lastcolpos)
}

proc cols::colorize {topcol botcol start end} {
    global cols_params manipColsmodeVars 
    set color $manipColsmodeVars(columnsColor)
    if {[llength [getColors]]} {removeColorEscapes}
    set offset [expr {$botcol - $topcol +1}]
    set lastlipos [cols::endOfLinePos $end]    
    set inilipos [lineStart $start]
    while {[pos::compare $inilipos < $lastlipos]} {
	if {[expr {$topcol>1}]} {
	    set fromcol [expr {$topcol-1}]
	    set inilipos [cols::nextColPos $inilipos $fromcol]
	} 
	text::color $inilipos [cols::nextColPos $inilipos $offset] $manipColsmodeVars(columnsColor)
	set inilipos [nextLineStart $inilipos]
    }
    refresh
}

# # # # # Text columnizing # # # # #

proc cols::setMargins {} {
    global leftFillColumn fillColumn 
    prompt::var "Left margin (leftFillColumn) ?" numlftcols 0 \
      is::UnsignedInteger 1 "Error : must be a positive integer"
    prompt::var "Text width (fillColumn) ?" numlcols 70 \
      is::UnsignedInteger 1 "Error : must be a positive integer"
    if {$numlftcols>=$numlcols} {
	alertnote "Text width is too small : choose less columns or change the minimum width in the prefs."
	return
    }
    set leftFillColumn $numlftcols
    set fillColumn $numlcols
}

proc cols::setRectDefaultValues {} {
    global leftFillColumn fillColumn
    set leftFillColumn 5
    set fillColumn 75
}

proc cols::columnizeText {} {
    global leftFillColumn fillColumn
    set debsel [getPos]
    set finsel [selEnd]
    if {$debsel == $finsel} {
	alertnote "No region selected."
	return
    }
    set texte [getText $debsel $finsel]
    catch {regsub -all "\[\n\r\]( +)?(-|\\*|•)" $texte "Ÿ-" texte}  
    catch {regsub -all "\[\n\r\](\[\n\r\]+)" $texte "Ÿ" texte} 
    set texte [split $texte "Ÿ"]
    set result ""
    foreach parag $texte {
	lappend result [cols::rectParagraph $parag]
    }    
    deleteText $debsel $finsel
    insertText [join $result "\r"]
    status::msg "Rectangulation done"
}

proc cols::rectParagraph {parag} {
    global leftFillColumn fillColumn manipColsmodeVars 
    set width [expr {$fillColumn - $leftFillColumn}]
    if {$manipColsmodeVars(minColumnWidth)>=$width} {
	alertnote "Text width is too small : choose less columns or change minimum width in the prefs."
	return
    }
    catch {regsub -all "\[\r\n\]" $parag " " parag}
    catch {regsub -all "\t" $parag " " parag}
    catch {regsub -all " +" $parag " " parag}
    set txt [breakIntoLines $parag]
    set txt [split $txt "\n\r"]
    set result ""
    set j 0
    foreach line $txt {
	set newline [string trim [concat $line] " "]
	if {![regexp { } $newline]} {
	    set dif [expr {$width-[string length $newline]}]
	    if {$dif} {
		set newline "$newline[format %${dif}s ""]"
	    } else {
		set newline "$newline"
	    }
	} else {
	    while {[expr {[string length $newline] < $width}]} {
		regsub -all " " $newline "  " newline
	    }
	    set exc [expr {[string length $newline]-$width}]
	    if {$exc} {
		for {set i 0} {$i < $exc} {incr i} {
		    regsub  "  " $newline " " newline
		}
	    } 
	}
	set j [incr j]
	# If it is the last line, then flushleft :
	if {$j==[llength $txt]} {
	    regsub -all " +" $newline " " newline
	} 
	lappend result "[format %${leftFillColumn}s ""]$newline\n"
    }
    return "[join $result ""]"
}

proc cols::unRectRegion {} {
    global leftFillColumn fillColumn
    if {[getPos] == [selEnd]} {
	alertnote "No region selected."
	return
    }
    set texte [getText [getPos] [selEnd]]
    catch {regsub -all " +" $texte " " texte}
    deleteText [getPos] [selEnd]
    insertText "$texte"
    status::msg "Unrectangulation done"
}

proc cols::multiColumnizeText {} {
    prompt::var "How many columns ?" nbcol 2 \
      is::PositiveInteger 1 "Error : must be a non negative integer"
    cols::multiColumnizing $nbcol
}

proc cols::multiColumnizing {{nbcol 2}} {
    global leftFillColumn fillColumn
    global manipColsmodeVars 
    set debsel [getPos]
    set finsel [selEnd]
    if {$debsel == $finsel} {
	alertnote "No region selected."
	return
    }
    set texte [getText $debsel $finsel]
    catch {regsub -all "\[\r\n\]( +)?(-|\\*|•)" $texte "Ÿ-" texte}  
    catch {regsub -all "\[\r\n\](\[\r\n\]+)" $texte "Ÿ" texte} 
    set texte [split $texte "Ÿ"]
    set result ""
    set savefillColumn $fillColumn
    set fillColumn [expr {$fillColumn / $nbcol}]
    if {$fillColumn<$manipColsmodeVars(minColumnWidth)} {
	alertnote "Text width is too small : choose less columns or change minimum width in the prefs."
	return
    }
    set multcolres ""
    foreach parag $texte {
	set result [cols::rectParagraph $parag]
	set result [split $result "\n"]
	set len [expr [llength $result] - 1]
	set quot [expr {$len / $nbcol}]
	set rest [expr {$len % $nbcol}]
	#     Construction of the lines :
	#     r columns + p-r columns
	set multcoltxt ""
	set line ""
	set lenlfcol [expr {$quot+1}]
	for {set l 0} {$l < $lenlfcol} {incr l} {
	    for {set i 0} {$i<$rest} {incr i} {
		lappend line [lindex $result [expr {$l+ $i * $lenlfcol}]]
	    }
	    if {$l!=$quot} {
		for {set i 0} {$i<[expr {$nbcol - $rest}]} {incr i} {
		    lappend line [lindex $result [expr {$l+ $rest*$quot + $i*$quot + $rest}]]
		}
	    } 
	    append multcoltxt "[format %${leftFillColumn}s ""][join $line "\t"]\n"
	    set line ""
	}
	lappend multcolres $multcoltxt
    }
    deleteText $debsel $finsel
    insertText [join $multcolres "\r"]
    set fillColumn $savefillColumn
    status::msg "Columnizing done"
}

proc cols::uncolumnizeText {} {
    global storedtbl cols_params
    set tblwd [cols::findTableWidth]
    set l 0
    foreach li $storedtbl {
	eval [concat set line($l) \[split {$li} \"$cols_params(colsep)\"\]]
	set l [incr l]
    }
    set tblht $l
    set result ""
    for {set i 0} {$i < $tblwd} {incr i} {
	for {set l 0} {$l < $tblht} {incr l} {
	    if {[lindex $line($l) $i]!={}} {
		lappend result [lindex $line($l) $i]
	    }
	}
    }
    deleteText $cols_params(inilipos) $cols_params(lastlipos)
    insertText [join $result "\r"]
    status::msg "Converted $tblwd columns to single"
}

set P [string toupper [string index $manipColsmodeVars(prefixBindingChar) 0]]

# # # # # Key Bindings # # # # #
# All the key bindings will use 'ctrl-c' (c for columns !) followed by a letter.
Bind '[string tolower $P]' <z> prefixChar 

# Key binding to append columns: <ctrl-c a> 
Bind 'a' <$P> {cols::appendColumns} 
# Key binding to display info about bindings: <ctrl-c b> 
Bind 'b' <$P> {cols::colsUtilsProc "ColumnsUtilities" "columnsBindings"} 
# Key binding to copy columns: <ctrl-c c> 
Bind 'c' <$P> {cols::copyColumns} 
# Key binding to delete columns: <ctrl-c d> 
Bind 'd' <$P> {cols::deleteColumns} 
# Key binding to equalize columns: <ctrl-c e> 
Bind 'e' <$P> {cols::equalizeColumns} 
# Key binding to insert rows numbers <f>rom a certain value: <ctrl-c f> 
Bind 'f' <$P> {cols::insertRowsNumbers 1} 
# Key binding : <ctrl-c g> 

# Key binding : <ctrl-c h> 

# Key binding to insert columns: <ctrl-c i> 
Bind 'i' <$P> {cols::insertColumns} 
# Key binding to justify text: <ctrl-c j> 
Bind 'j' <$P> {cols::columnizeText} 
# Key binding to colorize columns: <ctrl-c k> 
Bind 'k' <$P> {cols::colorizeColumns} 
# Key binding to center columns (m for <m>iddle): <ctrl-c m> 
Bind 'm' <$P> {cols::equalizeColumns c} 
# Key binding to insert rows numbers: <ctrl-c n> 
Bind 'n' <$P> {cols::insertRowsNumbers} 
# Key binding to sort columns in increasing <o>rder: <ctrl-c n> 
Bind 'o' <$P> {cols::sortColumns increasing} 
# Key binding to complete rows: <ctrl-c p> 
Bind 'p' <$P> {cols::completeRows} 
# Key binding : <ctrl-c q> 
 
# Key binding to <r>ight justify columns: <ctrl-c r> 
Bind 'r' <$P> {cols::equalizeColumns r} 
# Key binding to choose the columns separator: <ctrl-c s> 
Bind 's' <$P> {cols::columnsSeparator} 
# Key binding to transpose columns: <ctrl-c t> 
Bind 't' <$P> {cols::transposeColumns} 
# Key binding to unequalize columns: <ctrl-c u> 
Bind 'u' <$P> {cols::unequalizeColumns}
# Key binding to set the values for columnizing: <ctrl-c v> 
Bind 'v' <$P> {cols::setMargins} 
# Key binding to twiddle columns: <ctrl-c w> 
Bind 'w' <$P> {cols::twiddleColumns} 
# Key binding to cut columns: <ctrl-c x> 
Bind 'x' <$P> {cols::cutColumns} 
# Key binding : <ctrl-c y> 
 
# Key binding to uncolumni<z>e a table: <ctrl-c z> 
Bind 'z' <$P> {cols::uncolumnizeText} 

unset P
