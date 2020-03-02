## -*-Tcl-*-
 # ==========================================================================
 # Vince's Additions - an extension package for Alpha
 # 
 # FILE: "elecTemplateExamples.tcl"
 #                                           created: 07/29/1997 {5:09:35 pm}
 #                                      last update: 01/03/2006 {02:04:07 PM}
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #  mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley.
 # 
 # Distributed under a Tcl style license.  This package is not actively
 # improved any more, so if you wish to make improvements, feel free to take
 # it over.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # --------------------------------------------------------------------------
 # 
 # IMPORTANT:
 # 
 # This file is now obsolete, and is retained only to provide these back
 # compatibility notes and procedures.  All of the functionality that this
 # file used to provide can now be found in "licenseTemplates.tcl" in the
 # standard AlphaTcl distribution.  Please take a look at the help text for
 # the [alpha::library] package "licenseTemplates" for more information.
 # 
 # ==========================================================================
 ##

# TAGGED FOR REMOVAL

proc elecTemplateExamples.tcl {} {}

# Soon to be removed, following the release of AlphaTcl 8.1 ...

proc file::year {} {
    warningForObsProc
    return [userInfo::getInfo year]
}

proc file::author {} {
    warningForObsProc
    return [userInfo::getInfo author "¥author¥"]
}

proc file::organisation {} {
    warningForObsProc
    return [userInfo::getInfo "organisation" "¥organisation¥"]
}

proc file::licenseOwner {} {
    warningForObsProc
    return [userInfo::getInfo "owner" "¥author¥"]
}

proc file::licenseOrg {} {
    warningForObsProc
    return [userInfo::getInfo "owner_org" "¥organisation¥"]
}

proc file::allRightsReserved {} {
    warningForObsProc
    return [license::getTemplate "allRightsReserved"]
}

proc file::allRightsReservedOrg {} {
    warningForObsProc
    return [license::getTemplate "allRightsReservedOrg"]
}

proc file::copyrightNotice {} {
    warningForObsProc
    return [license::getTemplate "copyrightNotice"]
}

proc file::seeFileLicenseTerms {} {
    warningForObsProc
    return [license::getTemplate "seeFileLicenseTerms"]
}

proc file::gnuPublicLicense {} {
    warningForObsProc
    return [license::getTemplate "gnuPublicLicense"]
}

proc file::bsdLicense {} {
    warningForObsProc
    return [license::getTemplate "bsdLicense"]
}

proc file::none {} {}

# ===========================================================================
# 
# .