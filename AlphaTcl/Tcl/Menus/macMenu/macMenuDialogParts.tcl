# File : "macMenuDialogParts.tcl"
#                        Created : 2003-08-30 10:42:04
#              Last modification : 2005-06-20 16:31:27
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
# 
# (c) Copyright : Bernard Desgraupes, 2003-2005
#         All rights reserved.
# This software is free software. See licensing terms in the MacMenu Help file.
#
# Description : this file is part of the macMenu package for Alpha.
# It contains procedures to manage the constituting parts of the 
# various dialog windows in MacMenu.
# 

# Load macMenu.tcl
macMenuTcl

namespace eval mac {}


# # # Dialog windows # # #
# ========================


# Dialog windows elements
# =======================

proc mac::dialogTitlePart {} {
	global mac_params
	if {[regexp -nocase {Change(\w+)} $mac_params(title) -> which]} {
		set mac_params(okbutton) "Change"
		lappend mac_params(args) [list -t "* Change files [string tolower $which] *" 200 5 400 25]        
	} elseif {[regexp -nocase DeleteRezForks $mac_params(title)]} {
		set mac_params(okbutton) "Delete"
		lappend mac_params(args) [list -t "* Delete Resource Forks *" 200 5 400 25]        
	} else  {
		lappend mac_params(args) [list -t "* $mac_params(title) files *" 200 5 400 25]
	}
}

proc mac::dialogFilterPart {} {
	global mac_params
	set rgx $mac_params(regex)
	set rgx [string trimleft $rgx ^]
	set rgx [string trimright $rgx $]
	if {$rgx==""} {
		set rgx ".*"
	} 
	lappend mac_params(args) [list -t "Files filter regexp:" 10 $mac_params(y) 140 [expr $mac_params(y) + 20] \
	  -e "$rgx" 142 $mac_params(y) 540 [expr $mac_params(y) + 20] \
	  -c "case sensitive" $mac_params(iscase) 140 [expr $mac_params(y) + 28] 250 [expr $mac_params(y) + 48] \
	  -c "negate filter" $mac_params(isneg) 270 [expr $mac_params(y) + 28] 380 [expr $mac_params(y) + 48] \
	  -c "" $mac_params(addconditions) 390 [expr $mac_params(y) + 28] 420 [expr $mac_params(y) + 48] \
	  -b "Add Conditions" 415 [expr $mac_params(y) + 29] 540 [expr $mac_params(y) + 49]
	]
	incr mac_params(y) 90
}

proc mac::dialogSubFolderPart { {voffset 60} } {
    global mac::subfoldslist mac_params
	incr mac_params(y) -$voffset
    if {![regexp -nocase "remove" $mac_params(title)]} {
	set y [expr $mac_params(y) - 3]
	eval lappend mac_params(args) [list  [dialog::button "    Extensions    " 415 y]]
    }
    set y [expr {$mac_params(y)+2}]
    eval lappend mac_params(args) [list [dialog::text "Process " 30 y]]
    set y $mac_params(y)
    eval lappend mac_params(args) [list [dialog::menu 85 y $mac::subfoldslist \
      [lindex $mac::subfoldslist $mac_params(subfolds)] 150]]
    set y $mac_params(y)
    eval lappend mac_params(args) [list [list -n [lindex $mac::subfoldslist 1]]]
    set y $mac_params(y)
    eval lappend mac_params(args) [list [dialog::text "nesting depth: " 268 y]] \
      [list [list -e "$mac_params(nest)" 370 $mac_params(y) 384 [expr $mac_params(y) + 15]]]
	incr mac_params(y) $voffset
}

proc mac::dialogSourcePart {} {
    global mac_params
	mac::dialogFolderPart Source "$mac_params(srcfold)"
}

proc mac::dialogTargetPart {} {
    global mac_params
    mac::dialogFolderPart Target "$mac_params(trgtfold)"
}

proc mac::dialogFolderPart {which fold} {
    global mac_params
    lappend mac_params(args) [list -t "$which Folder:" 10 $mac_params(y) 160 [expr $mac_params(y) + 15] \
      -e "$fold" 65 [expr $mac_params(y) + 20] 540 [expr $mac_params(y) + 35] \
      -b Set 10 [expr $mac_params(y) + 18] 55 [expr $mac_params(y) + 38]
    ]
    if {$which=="Target" && $mac_params(title)!="Alias"} {
    lappend mac_params(args) [list -c "Force overwrite" $mac_params(overwrite) 60 [expr $mac_params(y) + 45] 200 [expr $mac_params(y) + 60]]
    } 
    incr mac_params(y) 60
}

proc mac::dialogReplacePart {} {
    global mac_params  
    lappend mac_params(args) [list -t "Replace with :" 10 $mac_params(y) 100 [expr $mac_params(y) + 15] \
      -e "$mac_params(replace)" 110 $mac_params(y) 540 [expr $mac_params(y) + 15]
    ]    
    incr mac_params(y) 10
    lappend mac_params(args) [list  -c "" $mac_params(addoptions) 100 [expr $mac_params(y) + 18] 120 [expr $mac_params(y) + 38] \
      -b "Add Options" 125 [expr $mac_params(y) + 18] 230 [expr $mac_params(y) + 38]
    ]    
    incr mac_params(y) 50
}

proc mac::dialogButtonPart {} {
    global mac_params
    set mac_params(args) [list "-b $mac_params(okbutton) 440 $mac_params(y) 535 [expr $mac_params(y) + 20]" \
      "-b Cancel 350 $mac_params(y) 425 [expr $mac_params(y) + 20]" "[join $mac_params(args)]"
    ]
    incr mac_params(y) 30
}

proc mac::dialogToCreatorPart {} {
    global mac_params mac::creatorslist
    incr mac_params(y) -90
    # This is VERY tricky : the following three widgets have to be inserted in the 'dialogargs' list
    # after the first popup menu (subfolders) but before the -n switch
    set y $mac_params(y)
    set mac_params(args) [linsert $mac_params(args) 6 "[dialog::text "Change creator to : " 30 y]"]
    set y $mac_params(y)
    set mac_params(args) [linsert $mac_params(args) 7 "[dialog::menu 160 y $mac::creatorslist \
      [lindex $mac::creatorslist $mac_params(creatoridx)] 160]"]
    set y $mac_params(y)
    set mac_params(args) [linsert $mac_params(args) 8 "[dialog::button Other 465 y]"]
    incr mac_params(y) 90
}

proc mac::dialogToTypePart {} {
    global mac_params mac::typeslist
    incr mac_params(y) -90
    set y $mac_params(y)
    set mac_params(args) [linsert $mac_params(args) 6 "[dialog::text "Change type to : " 30 y]"]
    set y $mac_params(y)
    set mac_params(args) [linsert $mac_params(args) 7 "[dialog::menu 150 y $mac::typeslist \
      [lindex $mac::typeslist $mac_params(typeidx)] 100]"]
    set y $mac_params(y)
    set mac_params(args) [linsert $mac_params(args) 8 "[dialog::button Other 465 y]"]
    incr mac_params(y) 90
}

proc mac::dialogSortingPart {} {
    global mac_params mac::sortbylist
    incr mac_params(y) -30
    # Same trick as in mac::dialogToCreatorPart : insert the following three widgets 
    # after the subfolders popup menu but before the -n switch
    set y $mac_params(y)
    set mac_params(args) [linsert $mac_params(args) 6 "[dialog::text "Sort by  " 10 y]"]
    set y $mac_params(y)
    set mac_params(args) [linsert $mac_params(args) 7 "[dialog::menu 60 y $mac::sortbylist \
      [lindex $mac::sortbylist $mac_params(sortbyidx)] 120]"]
    incr mac_params(y) 3
    set y $mac_params(y)
    set mac_params(args) [linsert $mac_params(args) 8 "[dialog::checkbox "Include criterion" $mac_params(criterion) 200 y]"]
    incr mac_params(y) 60
}

proc mac::dialogChangeEncodingPart {} {
	global mac_params 
	set mac_params(y) [expr $mac_params(y) - 90]
	# Same trick as in mac::dialogToCreatorPart: insert the following three widgets 
	# after the subfolders popup menu but before the -n switch
	set encodinglist [lsort [encoding names]]
	set y [expr {$mac_params(y)+2}]
	set mac_params(args) [linsert $mac_params(args) 6 "[dialog::text "Convert encoding from  " 20 y]"]
	set y $mac_params(y)
	set mac_params(args) [linsert $mac_params(args) 7 "[dialog::menu 175 y $encodinglist $mac_params(fromencoding) 120]"]
	set y [expr {$mac_params(y)+2}]
	set mac_params(args) [linsert $mac_params(args) 8 "[dialog::text "to  " 305 y]"]
	set y $mac_params(y)
	set mac_params(args) [linsert $mac_params(args) 9 "[dialog::menu 330 y $encodinglist $mac_params(toencoding) 120]"]
	incr mac_params(y) 40
	set y $mac_params(y)
	set mac_params(args) [linsert $mac_params(args) 10 "[dialog::checkbox "Backup originals" $mac_params(backuporigs) 20 y]"]
	incr mac_params(y) 50
}

proc mac::dialogChangeEolsPart {} {
    global mac_params mac::eolslist
    incr mac_params(y) -90
    # Same trick as in mac::dialogToCreatorPart : insert the following three widgets 
    # after the subfolders popup menu but before the -n switch
    set alleolslist [concat $mac::eolslist "-" all]
    set y [expr {$mac_params(y)+2}]
    set mac_params(args) [linsert $mac_params(args) 6 "[dialog::text "Convert eols from  " 20 y]"]
    set y $mac_params(y)
    set mac_params(args) [linsert $mac_params(args) 7 "[dialog::menu 145 y $alleolslist $mac_params(fromeol) 100]"]
    set y [expr {$mac_params(y)+2}]
    set mac_params(args) [linsert $mac_params(args) 8 "[dialog::text "to  " 255 y]"]
    set y $mac_params(y)
    set mac_params(args) [linsert $mac_params(args) 9 "[dialog::menu 280 y $mac::eolslist $mac_params(toeol) 100]"]
    incr mac_params(y) 90
}

proc mac::dialogExtensionsPart {} {
    global mac_params mac::predefext mac::ispredef
    set idx 0
    set nbext [llength $mac::predefext]
    set nbli [expr $nbext/8]
    set rest [expr $nbext % 8]
    set xcoord 30
    lappend mac_params(args) [list -t "Tip: you can add/remove checkboxes via the MacMenu preferences" 30 $mac_params(y) 480 [expr $mac_params(y) + 20]]  
    incr mac_params(y) 25
    for {set j 0} {$j < $nbli} {incr j} {
	set left $xcoord
	foreach e [lrange $mac::predefext $idx [expr $idx + 7]] {
	    eval lappend mac_params(args) [list -c $e $mac::ispredef($e) $left $mac_params(y) [expr $left + 50] [expr $mac_params(y) + 20]]
	    incr left 60
	}
	incr mac_params(y) 30
	incr idx 8
    }
    if {$rest} {
	set left $xcoord
	foreach e [lrange $mac::predefext $idx [expr $idx + $rest]] {
	    eval lappend mac_params(args) [list -c $e $mac::ispredef($e) $left $mac_params(y) [expr $left + 50] [expr $mac_params(y) + 20]]
	    incr left 60
	} 
    }
    incr mac_params(y) 40
    	lappend mac_params(args) [list -t "Other extensions:   " 30 $mac_params(y) 150 [expr $mac_params(y) + 20]\
	  -e "$mac_params(otherexts)" 155 $mac_params(y) 530 [expr $mac_params(y) + 20] ]
    incr mac_params(y) 40
}

proc mac::conditionDialogLine {type title altern xcoord ycoord wd {additlist ""}} {
    global mac_params
    set y $ycoord
    eval lappend mac_params(addconditions) [dialog::text $title $xcoord y]
    set y $ycoord
    eval lappend mac_params(addconditions) [list [dialog::menu 135 y $altern \
      [lindex $altern $mac_params(is$type)] 110]]
    set y $ycoord
    eval lappend mac_params(addconditions) [list [dialog::edit "$mac_params($type)" 285 y $wd]]
    if {$additlist!=""} {
	set y $ycoord
	eval lappend mac_params(addconditions) [list [dialog::menu 390 y $additlist \
	[lindex $additlist 0] 130]]
    } 
}


