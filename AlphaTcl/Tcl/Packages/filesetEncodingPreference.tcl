## -*-Tcl-*-
 # ###################################################################
 #  Vince's Additions - an extension package for Alpha
 # 
 #  FILE: "filesetEncodingPreference.tcl"
 #                                    created: 05/09/2000 {19:34:19 PM} 
 #                                last update: 05/08/2004 {05:05:30 PM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #          317 Paseo de Peralta
 #     www: http://www.santafe.edu/~vince/
 #  
 # Copyright (c) 2000-2004 Vince Darley
 # 
 # Distributable under Tcl-style (free) license.
 # ###################################################################
 ##

alpha::library filesetEncodingPreference 0.3 {
    # Make sure that this is no longer in the user's "global::features" list.
    if {([lsearch ${global::features} "filesetEncodingPreference"] > -1)} {
        set tempIdx [lsearch ${global::features} "filesetEncodingPreference"]
	set global::features [lreplace ${global::features} $tempIdx $tempIdx]
	prefs::modified "global::features"
	unset tempIdx
    } 
    # Attach 'encoding' preference to each fileset
    fileset::attachNewInformation "" variable "Encoding" "" \
      "If you enter anything here, it is used as the default encoding\
      for any files opened which are in this fileset.  The default\
      may be overridden by other considerations."
    hook::register fileset-file-opening fileset::checkEncodingPreference
} uninstall {
    this-file
} description {
    This "Fileset Information" preference will ensure a given fileset is
    opened with a particular default encoding, different to that set as a
    global default
} help {
    This "Fileset Information" preference will ensure a given fileset is
    opened with a particular default encoding, different to that set as a
    global default.
    
    To use it, you can <<editAFileset>>, click on the "Attach Info" button,
    and click on the checkbox next to "Encoding".  After clicking on the OK
    button, the "Edit A Fileset" dialog for this particular fileset will now
    have a text-edit field in which you can enter the desired encoding.

    This only works with Alphatk at present.  Alpha 8 has yet to be updated
    for use with different encodings.
}

namespace eval fileset {}

proc fileset::checkEncodingPreference {fset name} {
    set fsetEncoding [fileset::getInformation $fset "Encoding"]
    if {[string length $fsetEncoding]} {
	win::setInitialConfig $name encoding $fsetEncoding "fileset"
    }
}
