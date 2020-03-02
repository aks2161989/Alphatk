## -*-Tcl-*-
# ===========================================================================
# File: "toolbar.tcl"
#                        Created: 2006-03-27 18:54:12
#              Last modification: 2006-03-27 18:54:12
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@users.sourceforge.net>
# ===========================================================================
# Callback procs invoked by toolbar items

namespace eval toolbar {}


# Called by the Print toolbar item
proc toolbar::doPrint {} {
    ::print
}


# Called by the SearchField toolbar item
proc toolbar::doSearch { {searchStr ""} } {
    if {$searchStr eq ""} {
	supersearch::find
    } else {
	supersearch::searchString $searchStr
	supersearch::basicSearch
    }
}

