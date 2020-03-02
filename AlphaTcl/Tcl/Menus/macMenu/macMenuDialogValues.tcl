# File : "macMenuDialogValues.tcl"
#                        Created : 2003-08-30 10:44:19
#              Last modification : 2005-06-20 09:19:08
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
# 
# (c) Copyright : Bernard Desgraupes, 2003-2005
#         All rights reserved.
# This software is free software. See licensing terms in the MacMenu Help file.
#
# Description : this file is part of the macMenu package for Alpha.
# It contains procedures to retrieve the values from the 
# various dialog windows in MacMenu.
# 

# Load macMenu.tcl
macMenuTcl

namespace eval mac {}


# # # Dialog values # # #
# =======================
# Retrieving values from the various dialog windows

proc mac::getSelectValues {} {
    global mac_params 
    if {[lindex $mac_params(slvalues) 1]} {return 0}
    mac::_getCommonValues sl
    # In the case of select, there is no 'subfolders' option.
    mac::_getValuesFromList sl subfolds 10 mac::subfoldslist
	mac::_getSimpleValues sl nest 11
	mac::_getFolderValues select sl 8
	if {![mac::_getAdditionalValues select sl 6]} {return 0}
	if {![mac::_getExtensionsValues select sl 9]} {return 0}
    return 1
}

proc mac::getMoveValues {} {
    global mac_params 
    if {[lindex $mac_params(mvvalues) 1]} {return 0}
    mac::_getCommonValues mv
    set diff 0
    if {$mac_params(title) ne "Alias"} {
		set diff 1
		mac::_getSimpleValues mv overwrite 11
    } 
	mac::_getSimpleValues mv nest [expr 13 + $diff]
	mac::_getValuesFromList mv subfolds [expr 12 + $diff] mac::subfoldslist
	mac::_getFolderValues move mv 8
	mac::_getFolderValues move mv 10 trgt
	if {![mac::_getAdditionalValues move mv 6]} {return 0}
  	if {![mac::_getExtensionsValues move mv [expr {11 + $diff}]]} {return 0}
    return 1
}

proc mac::getRenameValues {} {
    global mac_params mac::subfoldslist
    if {[lindex $mac_params(rnvalues) 1]} {return 0}
    mac::_getCommonValues rn
	mac::_getSimpleValues rn replace 7 nest 14
	mac::_getValuesFromList rn subfolds 13 mac::subfoldslist
	mac::_getFolderValues rename rn 11
	if {![mac::_getAdditionalValues rename rn 6]} {return 0}
	if {![mac::_getAdditionalValues rename rn 9 Options]} {return 0}	
	if {![mac::_getExtensionsValues rename rn 12]} {return 0}
	if {![lindex $mac_params(rnvalues) 8]} {
		# Reset defaults
		array set mac_params {casing 0 numbering 0 truncating 0 addoptions 0}
	}
    if {$mac_params(replace)==""} {
		alertnote "Empty replacement string."
		return 0
    }
    return 1
}

proc mac::getAddConditionsValues {} {
    global mac_params 
    if {[lindex $mac_params(advalues) 1]} {return 0}
	mac::_getSimpleValues ad asmo 9 ascd 11 size 13
	mac::_getValuesFromList ad isasty 2 mac::alternlist isfcrt 5 mac::alternlist \
	  isasmo 8 mac::compdatelist isascd 10 mac::compdatelist issize 12 mac::compvaluelist
    if {[lindex $mac_params(advalues) 4] ne "Examples"} {
		mac::_getSimpleValues ad asty 4
    } else {
		mac::_getSimpleValues ad asty 3
    }
    if {[lindex $mac_params(advalues) 7] ne "Examples"} {
        set mac_params(fcrt) [string range [lindex $mac_params(advalues) 7] 0 3]
    } else {
		mac::_getSimpleValues ad fcrt 6
    }
    set str [concat $mac_params(asty) $mac_params(fcrt) $mac_params(asmo) $mac_params(ascd) $mac_params(size)]
    return [string length $str]
} 

proc mac::getAddOptionsValues {} {
    global mac_params
    if {[lindex $mac_params(opvalues) 1]} {return 0}
	mac::_getSimpleValues op casing 2 numbering 4 truncating 9 truncexp 10
	mac::_getValuesFromList op caseopt 3 mac::caselist whereopt 5 mac::wherelist \
	  digitopt 6 mac::digitlist incropt 7 mac::incrlist paddopt 8 mac::paddlist
    if {![regexp {^\d+(\.\d+)?$} $mac_params(truncexp)] && $mac_params(truncating)} {
		alertnote "Invalid truncate string. Should be:\r    m   or   m.n\rwith m and n integers."
		return 0
    } 
    return [expr $mac_params(casing) + $mac_params(numbering) + $mac_params(truncating)]
}

proc mac::getChangeEncodingValues {} {
	global mac_params 
	if {[lindex $mac_params(chvalues) 1]} {return 0}
	mac::_getCommonValues ch
	mac::_getSimpleValues ch fromencoding 11 toencoding 12 backuporigs 13 nest 14
	mac::_getValuesFromList ch subfolds 10 mac::subfoldslist
	mac::_getFolderValues changeEncoding ch 8
	if {![mac::_getAdditionalValues changeEncoding ch 6]} {return 0}
	if {![mac::_getExtensionsValues changeEncoding ch 9]} {return 0}
	return 1
}

proc mac::getChangeEolsValues {} {
	global mac_params 
	if {[lindex $mac_params(chvalues) 1]} {return 0}
	mac::_getCommonValues ch
	mac::_getSimpleValues ch fromeol 11 toeol 12 nest 13
	mac::_getValuesFromList ch subfolds 10 mac::subfoldslist
	mac::_getFolderValues changeEols ch 8
	if {![mac::_getAdditionalValues changeEols ch 6]} {return 0}
	if {![mac::_getExtensionsValues changeEols ch 9]} {return 0}
	return 1
}

proc mac::getChangeCreatorValues {} {
    global mac_params  
    if {[lindex $mac_params(chvalues) 1]} {return 0}
    mac::_getCommonValues ch
	mac::_getSimpleValues ch nest 13
	mac::_getValuesFromList ch subfolds 10 mac::subfoldslist creatoridx 11 mac::creatorslist 
	mac::_getFolderValues changeCreator ch 8
	if {![mac::_getAdditionalValues changeCreator ch 6]} {return 0}
	if {![mac::_getExtensionsValues changeCreator ch 9]} {return 0}
    if {[lindex $mac_params(chvalues) 12]} {
		mac::addCreatorDialog
		return [mac::changeCreatorDialog $mac_params(title)]
    }
    return 1
}

proc mac::getChangeTypeValues {} {
    global mac_params
    if {[lindex $mac_params(chvalues) 1]} {return 0}
    mac::_getCommonValues ch
	mac::_getSimpleValues ch nest 13
	mac::_getValuesFromList ch subfolds 10 mac::subfoldslist typeidx 11 mac::typeslist 
	mac::_getFolderValues changeType ch 8
	if {![mac::_getAdditionalValues changeType ch 6]} {return 0}
	if {![mac::_getExtensionsValues changeType ch 9]} {return 0}
    if {[lindex $mac_params(chvalues) 12]} {
		mac::addTypeDialog
		return [mac::changeTypeDialog $mac_params(title)]
    }
    return 1
}

proc mac::getListValues {} {
    global mac_params mac::sortbylist mac::subfoldslist
    if {[lindex $mac_params(lsvalues) 1]} {return 0}
    mac::_getCommonValues ls
 	mac::_getSimpleValues ls criterion 12 nest 13
	mac::_getValuesFromList ls subfolds 10 mac::subfoldslist sortbyidx 11 mac::sortbylist 
	mac::_getFolderValues list ls 8
	if {![mac::_getAdditionalValues list ls 6]} {return 0}
	if {![mac::_getExtensionsValues list ls 9]} {return 0}
    return 1
}

proc mac::getExtensionsValues {} {
    global mac_params mac::predefext mac::ispredef
    if {[lindex $mac_params(pevalues) 1]} {return 0}
    set len [llength $mac::predefext]
    for {set i 0} {$i<$len} {incr i} {
		set mac::ispredef([lindex $mac::predefext $i]) [lindex $mac_params(pevalues) [expr $i+2]]
    }
	mac::_getSimpleValues pe otherexts [expr $len + 2]
    return 1
}

proc mac::getAddCreatorValues {} {
    global mac_params mac::creatorslist
    if {[lindex $mac_params(acvalues) 1]} {return 0}
    set appname ""
	mac::_getSimpleValues ac addedcreator 3
    set mac_params(creatoridx) [llength $mac::creatorslist]
    if {[lindex $mac_params(acvalues) 4]} {
	if {![catch {getfile ""} fname]} {
	    set mac_params(addedcreator) [mac::getTypeCreator fcrt $fname]
	}
	return [mac::addCreatorDialog]
    } 
    if {$mac_params(addedcreator) ne ""} {
	# Get the name of the application which created the file.
	if {![catch {nameFromAppl $mac_params(addedcreator)} res]} {
	    regsub {\.app$} [file tail $res] "" res
	    set appname "- $res"
	} 
	if {[lindex $mac_params(acvalues) 2]} {
	    lappend mac::creatorslist "$mac_params(addedcreator)$appname" 
	} else {
	    set mac::creatorslist [lreplace $mac::creatorslist 0 0 "$mac_params(addedcreator)$appname"]
	}
    } 
    return 1
}

proc mac::getAddTypeValues {} {
    global mac_params mac::typeslist
    if {[lindex $mac_params(acvalues) 1]} {return 0}
	mac::_getSimpleValues ac addedtype 3
    set mac_params(typeidx) [llength $mac::typeslist]
    if {[lindex $mac_params(acvalues) 4]} {
	if {![catch {getfile ""} fname]} {
	    set mac_params(addedtype) [mac::getTypeCreator asty $fname]
	}
	return [mac::addTypeDialog]
    } 
    if {$mac_params(addedtype) ne ""} {
	if {[lindex $mac_params(acvalues) 2]} {
	    lappend mac::typeslist "$mac_params(addedtype)" 
	} else {
	    set mac::typeslist [lreplace $mac::typeslist 0 0 "$mac_params(addedtype)"]
	}
    } 
    return 1
}

proc mac::getRemoveAliasValues {} {
    global mac_params 
    if {[lindex $mac_params(uavalues) 1]} {return 0}
	mac::_getSimpleValues ua nest 5
	mac::_getValuesFromList ua subfolds 4 mac::subfoldslist
	mac::_getFolderValues removeAlias ua 3
    return 1
}


# # # Retrieve values # # #
# =========================
# Common procs for values retrieval

proc mac::_getCommonValues {prefix} {
	global mac_params
	set values mac_params(${prefix}values)
	set rgx [lindex [set $values] 2]
	set rgx [string trimleft $rgx ^]
	set rgx [string trimright $rgx $]
	if {$rgx==""} {
		set rgx ".*"
	} 
	set mac_params(regex) "^$rgx\$"
	set mac_params(iscase) [lindex [set $values] 3]
	set mac_params(casestr) [expr {$mac_params(iscase) ? "":"-nocase"}]
	set mac_params(isneg) [lindex [set $values] 4]
	set mac_params(addconditions) [lindex [set $values] 5]
	return 1
}


proc mac::_getFolderValues {name prefix idx {which src}} {
	global mac_params
	if {[lindex [set mac_params(${prefix}values)] $idx]} {
		catch {set mac_params(${which}fold) [get_directory -p "Select a folder."]}
		mac::trimRightSeparator mac_params(${which}fold)
		if {$name eq "move" && $which eq "src"} {
			set target [lindex [set mac_params(${prefix}values)] [expr {$idx + 1}]]
			if {$target ne ""} {
			    set mac_params(trgtfold) $target
			} 
		} 
		return [mac::${name}Dialog $mac_params(title)]
	} else {
		set mac_params(${which}fold) [lindex [set mac_params(${prefix}values)] [expr {$idx - 1}]]
		mac::trimRightSeparator mac_params(${which}fold)
	}
}


proc mac::_getAdditionalValues {name prefix idx {which "Conditions"}} {
	global mac_params
	if {[lindex [set mac_params(${prefix}values)] $idx]} {
		set mac_params(add[string tolower $which]) [mac::add${which}Dialog]
		return [mac::${name}Dialog $mac_params(title)]
	} 
	return 1
}


proc mac::_getExtensionsValues {name prefix idx} {
	global mac_params
	if {[lindex [set mac_params(${prefix}values)] $idx]} {
		set oldtitle $mac_params(title)
		if {[mac::predefExtsDialog OK]} {
			mac::refreshFilterExpr
		} 
		return [mac::${name}Dialog $oldtitle]
	}
	return 1
}


# Syntax is
#     mac::_getSimpleValues prefix ?<key index>? ?<key index>?...
proc mac::_getSimpleValues {prefix args} {
	global mac_params
	set len [llength $args]
	for {set i 0} {$i < $len} {incr i 2} {
		set mac_params([lindex $args $i]) [lindex [set mac_params(${prefix}values)] [lindex $args [expr {$i+1}]]]
	}
}


# Syntax is
#     mac::_getValuesFromList prefix ?<key index list>? ?<key index list>?...
proc mac::_getValuesFromList {prefix args} {
	global mac_params
	set len [llength $args]
	for {set i 0} {$i < $len} {incr i 3} {
		set idx [lindex $args [expr {$i+1}]]
		set lst [lindex $args [expr {$i+2}]]
		global $lst
		set mac_params([lindex $args $i]) [lsearch -exact [set $lst] [lindex [set mac_params(${prefix}values)] $idx]]
	}
}


