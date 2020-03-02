# File : "macMenuDialogs.tcl"
#                        Created : 2001-01-22 21:35:13
#              Last modification : 2005-06-20 15:28:08
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
# 
# (c) Copyright : Bernard Desgraupes, 2001-2005
#         All rights reserved.
# This software is free software. See licensing terms in the MacMenu Help file.
#
# Description : this file is part of the macMenu package for Alpha.
# It contains procedures to manage the various dialog windows of macMenu.
# 

# Load macMenu.tcl
macMenuTcl

namespace eval mac {}


# # # Dialog windows # # #
# ========================

proc mac::dialogInit {title} {
	global mac_params
	if {$mac_params(srcfold)==""} {
		set mac_params(srcfold) [file dirname [win::Current]]
	} 
	set mac_params(title) $title
	set mac_params(okbutton) $title
	set mac_params(args) ""
	set mac_params(y) 40    
}

proc mac::selectDialog {title} {
    global mac_params
    mac::dialogInit $title
	mac::dialogTitlePart
    mac::dialogFilterPart
    mac::dialogSourcePart
    mac::dialogButtonPart
    mac::dialogSubFolderPart 120
    set mac_params(slvalues) [eval dialog -w 550 -h $mac_params(y) [join $mac_params(args)]]
    return [mac::getSelectValues]
}

proc mac::moveDialog {title} {
    global mac_params
    mac::dialogInit $title
	mac::dialogTitlePart
    mac::dialogFilterPart
    mac::dialogSourcePart
    mac::dialogTargetPart
    mac::dialogButtonPart
    mac::dialogSubFolderPart 180
    set mac_params(mvvalues) [eval dialog -w 550 -h $mac_params(y) [join $mac_params(args)]]
    return [mac::getMoveValues]    
}

proc mac::renameDialog {title} {
    global mac_params
    mac::dialogInit $title
	mac::dialogTitlePart
    mac::dialogFilterPart
    mac::dialogReplacePart
    mac::dialogSourcePart
    mac::dialogButtonPart
    mac::dialogSubFolderPart 180
    set mac_params(rnvalues) [eval dialog -w 550 -h $mac_params(y) [join $mac_params(args)]]
    return [mac::getRenameValues]
}

proc mac::changeEncodingDialog {title} {
	global mac_params
	mac::dialogInit $title
	mac::dialogTitlePart
	mac::dialogFilterPart
	mac::dialogSourcePart
	# Reserve extra space above buttons
	incr mac_params(y) 60
	mac::dialogButtonPart
	mac::dialogSubFolderPart 180
	mac::dialogChangeEncodingPart
	set mac_params(chvalues) [eval dialog -w 550 -h $mac_params(y) [join $mac_params(args)]]
	return [mac::getChangeEncodingValues]
}

proc mac::changeEolsDialog {title} {
	global mac_params
	mac::dialogInit $title
	mac::dialogTitlePart
	mac::dialogFilterPart
	mac::dialogSourcePart
	# Reserve extra space above buttons
	incr mac_params(y) 60
	mac::dialogButtonPart
	mac::dialogSubFolderPart 180
	mac::dialogChangeEolsPart
	set mac_params(chvalues) [eval dialog -w 550 -h $mac_params(y) [join $mac_params(args)]]
	return [mac::getChangeEolsValues]
}

proc mac::changeCreatorDialog {title} {
    global mac_params 
    mac::dialogInit $title
	mac::dialogTitlePart
    mac::dialogFilterPart
    mac::dialogSourcePart
	# Reserve extra space above buttons
	incr mac_params(y) 60
    mac::dialogButtonPart
    mac::dialogSubFolderPart 180
    mac::dialogToCreatorPart
    set mac_params(chvalues) [eval dialog -w 550 -h $mac_params(y) [join $mac_params(args)]]
    return [mac::getChangeCreatorValues]
}

proc mac::changeTypeDialog {title} {
    global mac_params 
    mac::dialogInit $title
	mac::dialogTitlePart
    mac::dialogFilterPart
    mac::dialogSourcePart
	# Reserve extra space above buttons
	incr mac_params(y) 60
    mac::dialogButtonPart
    mac::dialogSubFolderPart 180
    mac::dialogToTypePart
    set mac_params(chvalues) [eval dialog -w 550 -h $mac_params(y) [join $mac_params(args)]]
    return [mac::getChangeTypeValues]
}

proc mac::listDialog {title} {
    global mac_params
    mac::dialogInit $title
	mac::dialogTitlePart
    mac::dialogFilterPart
    mac::dialogSourcePart
	incr mac_params(y) 30
    mac::dialogButtonPart
	incr mac_params(y) -30
    mac::dialogSubFolderPart 120
    mac::dialogSortingPart
    set mac_params(lsvalues) [eval dialog -w 550 -h $mac_params(y) [join $mac_params(args)]]
    return [mac::getListValues]
}

proc mac::removeAliasDialog {title} {
	global mac_params
	mac::dialogInit $title
	lappend mac_params(args) [list -t "* Remove aliases *" 200 5 400 25]
	incr mac_params(y) 30
	mac::dialogSourcePart
	mac::dialogButtonPart
	mac::dialogSubFolderPart 120
	set mac_params(uavalues) [eval dialog -w 550 -h $mac_params(y) [join $mac_params(args)]]
	return [mac::getRemoveAliasValues]
}

proc mac::predefExtsDialog {title} {
    global mac_params
    mac::dialogInit $title
    lappend mac_params(args) [list -t "* Predefined extensions *" 200 5 400 25]        
    mac::dialogExtensionsPart
    mac::dialogButtonPart
    set mac_params(pevalues) [eval dialog -w 550 -h $mac_params(y) [join $mac_params(args)]]
    return [mac::getExtensionsValues]    
}

proc mac::addConditionsDialog {} {
    global mac_params mac::alternlist mac::compvaluelist mac::compdatelist 
    global mac::creatorslist mac::typeslistatorslist mac::typeslist
    set mac_params(addconditions) ""
    lappend mac_params(addconditions) [list -t "* Additional conditions *" 200 8 500 28 \
      -t "yyyy-mm-dd" 400 85 550 105 \
      -t "yyyy-mm-dd" 400 110 550 130 \
      -t "k" 400 135 550 155 \
      -b Apply 490 170 570 190 \
      -b Cancel 390 170 475 190 ]
    mac::conditionDialogLine asty [list "Type "] $mac::alternlist 84 35 5 [concat Examples [lrange $mac::typeslist 1 end]]
    mac::conditionDialogLine fcrt [list "Creator "] $mac::alternlist 68 60 5 [concat Examples [lrange $mac::creatorslist 1 end]]
    mac::conditionDialogLine asmo [list "Modification date "] $mac::compdatelist 5 85 10
    mac::conditionDialogLine ascd [list "Creation date "] $mac::compdatelist 30 110 10
    mac::conditionDialogLine size [list "Size "] $mac::compvaluelist 88 135 10
    set mac_params(advalues) [eval dialog -w 600 -h 198 [join $mac_params(addconditions)]]
    return [mac::getAddConditionsValues]
}

proc mac::addOptionsDialog {} {
    global mac_params
    global mac::caselist mac::digitlist mac::incrlist mac::paddlist mac::wherelist
    set ycoord 45
    set addoptargs ""
    lappend addoptargs [list -t "* Replacement Options *" 200 10 500 30 \
      -b Apply 470 180 550 200 \
      -b Cancel 370 180 455 200 ]
    set y $ycoord
    eval lappend addoptargs [dialog::checkbox "Casing " $mac_params(casing) 20 y]
    set y $ycoord
    eval lappend addoptargs [list [dialog::menu 100 y $mac::caselist [lindex $mac::caselist $mac_params(caseopt)] 150]]
    incr ycoord 35
    set y $ycoord
    eval lappend addoptargs [dialog::checkbox "Numbering " $mac_params(numbering) 20 y]
    incr ycoord 25
    set y $ycoord
    eval lappend addoptargs [list [dialog::menu 35 y $mac::wherelist [lindex $mac::wherelist $mac_params(whereopt)] 100]]
    set y $ycoord
    eval lappend addoptargs [list [dialog::menu 150 y $mac::digitlist [lindex $mac::digitlist $mac_params(digitopt)] 125]]
    set y $ycoord
    eval lappend addoptargs [list [dialog::menu 290 y $mac::incrlist [lindex $mac::incrlist $mac_params(incropt)] 100]]
    set y $ycoord
    eval lappend addoptargs [list [dialog::menu 405 y $mac::paddlist [lindex $mac::paddlist $mac_params(paddopt)] 150]]
    incr ycoord 40
    set y $ycoord
    eval lappend addoptargs [dialog::checkbox "{Truncate to}" $mac_params(truncating) 20 y]
    set y $ycoord
    eval lappend addoptargs [list [dialog::edit "$mac_params(truncexp)" 125 y 4]]    
    set y $ycoord
    eval lappend addoptargs [dialog::text {n\[.m\]} 180 y 30]
    set mac_params(opvalues) [eval dialog -w 570 -h 208 [join $addoptargs]]
    return [mac::getAddOptionsValues]
}

proc mac::addCreatorDialog {} {
    global mac_params   
    set addcreaargs ""
    lappend addcreaargs [list -t "* Choose a new creator *" 75 10 290 30 \
      -b Apply 230 80 290 100 \
      -b Cancel 10 80 80 100 \
      -b Add&Apply 125 80 215 100 ]
    set mac_params(y) 40    
    lappend addcreaargs [list -t "New creator  " 10 $mac_params(y) 100 [expr $mac_params(y) + 20]\
      -e "$mac_params(addedcreator)" 110 $mac_params(y) 170 [expr $mac_params(y) + 20]\
      -b "Same as..." 210 $mac_params(y) 290 [expr $mac_params(y) + 20]
    ]  
    incr mac_params(y) 70
    set mac_params(acvalues) [eval dialog -w 300 -h $mac_params(y) [join $addcreaargs]]
    return [mac::getAddCreatorValues]    
}

proc mac::addTypeDialog {} {
    global mac_params   
    set addtypargs ""
    lappend addtypargs [list -t "* Choose a new type *" 75 10 290 30 \
      -b Apply 230 80 290 100 \
      -b Cancel 10 80 80 100 \
      -b Add&Apply 125 80 215 100 ]
    set mac_params(y) 40    
    lappend addtypargs [list -t "New type  " 30 $mac_params(y) 100 [expr $mac_params(y) + 20]\
      -e "$mac_params(addedtype)" 110 $mac_params(y) 170 [expr $mac_params(y) + 20]\
      -b "Same as..." 210 $mac_params(y) 290 [expr $mac_params(y) + 20]
    ]  
    incr mac_params(y) 70
    set mac_params(acvalues) [eval dialog -w 300 -h $mac_params(y) [join $addtypargs]]
    return [mac::getAddTypeValues]    
}

# Cleanup
# Free some unneeded memory
proc mac::cleanDialog {which} {
	global mac_params
	unset -nocomplain mac_params(${which}values)
}

