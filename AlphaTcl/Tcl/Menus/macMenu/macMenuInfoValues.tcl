# File : "macMenuInfoValues.tcl"
#                        Created : 2003-08-30 10:56:14
#              Last modification : 2005-06-19 20:59:23
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
# various info windows in MacMenu.
# 

# Load macMenu.tcl
macMenuTcl

namespace eval mac {}



# # # Info values # # #
# =====================
# Retrieving values from the various info windows

proc mac::getFileValues {} {
    global macfileinfo mac::saveinfo mac_params
    if {[lindex $mac_params(infovalues) 0]} {return}
    if {[lindex $mac_params(infovalues) 1]} {
	mac::getInfoAsText
	return
    }
    set len [llength $mac_params(infovalues)]
    set mac::saveinfo(name) $macfileinfo(name)
    set mac::saveinfo(asty) $macfileinfo(asty)
    set mac::saveinfo(fcrt) $macfileinfo(fcrt)
    set mac::saveinfo(aslk) $macfileinfo(aslk)
    set mac::saveinfo(pspd) $macfileinfo(pspd)
    set macfileinfo(name) [lindex $mac_params(infovalues) 2]
    set macfileinfo(asty) [lindex $mac_params(infovalues) 3]
    set macfileinfo(fcrt) [lindex $mac_params(infovalues) 4]
    set macfileinfo(aslk) [lindex $mac_params(infovalues) 5]
    set macfileinfo(pspd) [lindex $mac_params(infovalues) 6]
    if {[lindex $mac_params(infovalues) end-$mac_params(isshared)]} {
	mac::setFileValues
	return
    }
    if {[lindex $mac_params(infovalues) end]} {
	mac::showSharingInfo file
	mac::showFilesInfo
	return
    }
}

proc mac::getFolderValues {} {
    global macfolderinfo mac_params
    if {[lindex $mac_params(infovalues) 0]} {return}
    if {[lindex $mac_params(infovalues) 1]} {
	mac::getInfoAsText
	return
    }
    if {[lindex $mac_params(infovalues) end]} {
	mac::showSharingInfo folder
	mac::showFolderInfo
	return
    }
}

proc mac::getVolumeValues {} {
    global macvolumeinfo mac_params
    if {[lindex $mac_params(infovalues) 0]} {return}
    if {[lindex $mac_params(infovalues) 1]} {
	mac::getInfoAsText
	return
    }
    if {[lindex $mac_params(infovalues) end]} {
	mac::showSharingInfo volume
	mac::showVolumeInfo
	return
    }
}

proc mac::getApplValues {} {
    global macapplinfo mac_params
    if {[lindex $mac_params(infovalues) 0]} {return}
    if {[lindex $mac_params(infovalues) 1]} {
	mac::getInfoAsText
	return
    }
    if {[lindex $mac_params(infovalues) end]} {
	mac::showSharingInfo appl
	mac::showApplInfo
	return
    }
}

proc mac::getHardwareValues {} {
    global mac_params
    if {[lindex $mac_params(infovalues) 0]} {return}
    if {[lindex $mac_params(infovalues) 1]} {
	mac::getInfoAsText
	return
    }    
}

proc mac::getOtherValues {} {
    global mac_params
    if {[lindex $mac_params(infovalues) 0]} {return}
    if {[lindex $mac_params(infovalues) 1]} {
	mac::getInfoAsText
	return
    }
}

proc mac::setFileValues {} {
    global macfileinfo mac::saveinfo
    set fname [file join $macfileinfo(path) $mac::saveinfo(name)]
    if {$mac::saveinfo(aslk)!=$macfileinfo(aslk)} {
	catch {tclAE::send 'MACS' core setd ---- [tclAE::build::propertyObject aslk \
	  [tclAE::build::filename $fname]] \
	  data [tclAE::build::bool $macfileinfo(aslk)]}
    }
    if {$mac::saveinfo(pspd)!=$macfileinfo(pspd)} {
	catch {tclAE::send 'MACS' core setd ---- [tclAE::build::propertyObject pspd \
	  [tclAE::build::filename $fname]] \
	  data [tclAE::build::bool $macfileinfo(pspd)]}
    }
    set warned 0
    foreach prop [list asty fcrt] {
	if {[set mac::saveinfo($prop)] != [set macfileinfo($prop)]} {
	    if {[string length $macfileinfo($prop)] > 4} {
		if {!$warned} {
		    alertnote "Type and creator can't have more than four chars"
		    set warned 1
		} 
	    } else {
		catch {tclAE::send 'MACS' core setd ---- [tclAE::build::propertyObject $prop \
		  [tclAE::build::filename $fname]] \
		  data [tclAE::build::objectType $macfileinfo($prop)]} 
	    } 
	}
    } 
    # Renaming should come last
    if {$mac::saveinfo(name)!=$macfileinfo(name)} {
	catch {tclAE::send 'MACS' core setd ---- [tclAE::build::propertyObject pnam \
	  [tclAE::build::filename $fname]] \
	  data [tclAE::build::TEXT $macfileinfo(name)]} 
    }
}


