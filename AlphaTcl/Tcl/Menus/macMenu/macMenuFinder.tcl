# File : "macMenuFinder.tcl"
#                        Created : 2003-08-23 13:23:35
#              Last modification : 2005-06-19 19:33:25
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
# 
# (c) Copyright : Bernard Desgraupes, 2003-2005
#         All rights reserved.
# This software is free software. See licensing terms in the MacMenu Help file.
#
# Description : this file is part of the macMenu package for Alpha.
# It contains procs used by macMenu for systemwide actions.

# Load macMenu.tcl
macMenuTcl

namespace eval mac {}


# # # Misc actions procs # # #
# ============================

proc mac::emptyTrash {} {
    catch {
	set desc [tclAE::send  -r 'MACS' fndr empt]
	mac::testIfError $desc
    }	
}

# -------------------------------------------------------------------------
# Action can be:  rest (restart), slep (sleep) or shut (shutdown).
# -------------------------------------------------------------------------
proc mac::systemAction {action} {
    app::launchFore sevs
    tclAE::send -r 'sevs' fndr $action
}

proc mac::shutDown {} {mac::systemAction shut}

proc mac::restart {} {mac::systemAction rest}

proc mac::sleep {} {mac::systemAction slep}

# -------------------------------------------------------------------------
# Build list of all mounted volumes
# -------------------------------------------------------------------------
proc mac::getAllVolsList {} {
    set theAE [tclAE::send -r 'MACS' core getd ---- \
      [tclAE::build::propertyObject pnam [tclAE::build::indexObject cdis "abso('all ')"]]]
    if {[mac::testIfError $theAE]} {
	alertnote "Couldn't get the list of volumes."
	return ""
    } else {
	set objDesc [tclAE::getKeyDesc $theAE ----]
	set theCount [tclAE::countItems $objDesc]
	set volsList ""
	for {set i 0} {$i < $theCount} {incr i} {
	    lappend volsList [tclAE::getNthData $objDesc $i TEXT]
	}
	tclAE::disposeDesc $objDesc
	tclAE::disposeDesc $theAE
    }
    return $volsList
}

# -------------------------------------------------------------------------
# Build list of ejectable volumes
# -------------------------------------------------------------------------
proc mac::getEjectVolsList {} {
    set ejectlist ""
    status::msg "Looking for ejectable volumes..."
    app::launchBack sevs
    # Get list of names
    set theAE [tclAE::send -r 'sevs' core getd ---- \
      [tclAE::build::propertyObject pnam [tclAE::build::indexObject cdis "abso('all ')"]]]
    set volsDesc [tclAE::getKeyDesc $theAE ----]
    set theCount [tclAE::countItems $volsDesc]
    tclAE::disposeDesc $theAE
    # Get list of ejectable properties
    set theAE [tclAE::send -r 'sevs' core getd ---- \
      [tclAE::build::propertyObject isej [tclAE::build::indexObject cdis "abso('all ')"]]]
    set ejectDesc [tclAE::getKeyDesc $theAE ----]
    tclAE::disposeDesc $theAE
    for {set i 0} {$i < $theCount} {incr i} {
	if {[tclAE::getNthData $ejectDesc $i TEXT] eq "true"} {
	    lappend ejectlist [tclAE::getNthData $volsDesc $i TEXT]
	} 
    }
    tclAE::disposeDesc $volsDesc
    tclAE::disposeDesc $ejectDesc
    status::msg ""
    return $ejectlist
}

proc mac::eject {} {
    global mac_params
    set ejectVolsList [mac::getEjectVolsList]
    set l [llength $ejectVolsList]
    switch $l {
	0 {
	    set mess "No ejectable volumes."
	    if {!$mac_params(fromshell)} {alertnote $mess}
		return $mess
	}
	1 {mac::doEject $ejectVolsList}
	default {
	    set volume [listpick  -p "Volume to eject:" $ejectVolsList]
	    if {$volume!=""} {
		mac::doEject $volume
	    } 
	}
    }
}

# -------------------------------------------------------------------------
# Under OSX, the Finder seems to always return true for the isej property. 
# We must ask System Events in order to get the right answer.
# -------------------------------------------------------------------------
proc mac::isEjectable {vol} {
    app::launchBack sevs
    return [tclAE::build::resultData 'sevs' core getd ---- [tclAE::build::propertyObject isej\
      [tclAE::build::nameObject cdis [tclAE::build::TEXT $vol] ]]]
}

# -------------------------------------------------------------------------
# Under OSX, use the 'fndr ejct' Apple Event.
# -------------------------------------------------------------------------
proc mac::doEject {vol} {
    set vol [string trim $vol "\{\}"]
    status::msg "Ejecting '$vol'..."
    catch {
	set desc [tclAE::send -r 'MACS' fndr ejct ---- \
	  [tclAE::build::nameObject cdis [tclAE::build::TEXT $vol]]]
	if {[mac::testIfError $desc]} {
	    status::msg ""
	    return
	}
    }	
    status::msg "'$vol' ejected"
}

# -------------------------------------------------------------------------
# Build list of running processes.
# Could use [processes] as well.
# -------------------------------------------------------------------------
proc mac::getProcessesList {} {
    # Launch System Events
    app::launchBack sevs
    set theAE [tclAE::send -r 'sevs' core getd ---- \
      [tclAE::build::propertyObject pnam [tclAE::build::indexObject prcs "abso('all ')"]]]
    if {[mac::testIfError $theAE]} {
	alertnote "Couldn't get processes from System Events"
	return ""
    } else {
	set objDesc [tclAE::getKeyDesc $theAE ----]
	set theCount [tclAE::countItems $objDesc]
	set processList ""
	for {set i 0} {$i < $theCount} {incr i} {
	    lappend processList [tclAE::getNthData $objDesc $i TEXT]
	}
	tclAE::disposeDesc $objDesc
	tclAE::disposeDesc $theAE
    }
    return $processList
}


# -------------------------------------------------------------------------
# Build list of aliases contained in a folder.
# -------------------------------------------------------------------------
proc mac::getAliasesList {fol} {
    set theAE [tclAE::send -r 'MACS' core getd ---- \
      [tclAE::build::indexObject alia "abso('all ')" [tclAE::build::foldername $fol]]]
    if {[mac::testIfError $theAE]} {
	alertnote "Couldn't get the list of aliases."
	return ""
    } else {
	set objDesc [tclAE::getKeyDesc $theAE ----]
	set theCount [tclAE::countItems $objDesc]
	set aliasList ""
	for {set i 0} {$i < $theCount} {incr i} {
	    lappend aliasList [tclAE::getNthDesc $objDesc $i]
	}
	tclAE::disposeDesc $objDesc
	tclAE::disposeDesc $theAE
    }
    return $aliasList
}



