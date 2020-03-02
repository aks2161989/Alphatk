## -*-Tcl-*-
 # ###################################################################
 #  Vince's Additions - an extension package for Alpha
 # 
 #  FILE: "filesetIndentation.tcl"
 #                                    created: 01/20/2003 {12:31:45 PM}  
 #                                last update: 05/08/2004 {05:11:32 PM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #          317 Paseo de Peralta
 #     www: http://www.santafe.edu/~vince/
 #  
 # Copyright (c) 2003-2004 Vince Darley
 # 
 # Distributable under Tcl-style (free) license.
 # ###################################################################
 ##

alpha::library filesetIndentationPreference 0.2.1 {
    # Make sure that this is no longer in the user's "global::features" list.
    if {([lsearch ${global::features} "filesetIndentationPreference"] > -1)} {
	set tempIdx [lsearch ${global::features} "filesetIndentationPreference"]
	set global::features [lreplace ${global::features} $tempIdx $tempIdx]
	prefs::modified "global::features"
	unset tempIdx
    } 
    # Attach three preferences to each fileset
    fileset::attachNewInformation "" variable "Indentation Amount" "" \
      "If you enter anything here, it is used as the default\
      indentation\
      size for any files opened which are in this fileset.  The default\
      may be overridden by other considerations."
    fileset::attachNewInformation "" variable "Tab Size" "" \
      "If you enter anything here, it is used as the default tab\
      size for any files opened which are in this fileset.  The default\
      may be overridden by other considerations."
    fileset::attachNewInformation "" flag "Indent Using Spaces Only" "" \
      "If you set this anything here, it is used to override the\
      indentation preference for files which are in this fileset.\
      The default may be overridden by other considerations."
    hook::register fileset-file-opening fileset::checkIndentationPreference
} uninstall {
    this-file
} description {
    This "Fileset Information" preference will ensure a given fileset is
    opened with a particular indentation amount, tab size and/or spaces-only
    setting, regardless of your global defaults
} help {
    This "Fileset Information" preference will ensure a given fileset is
    opened with a particular indentation amount, tab size and/or spaces-only
    setting, regardless of your global defaults.

    To use it, you can <<editAFileset>>, click on the "Attach Info" button,
    and click on any of the checkboxes next to
   
	Indentation Amount
	Tab Size
	Indent Using Spaces Only
    
    After clicking on the OK button, the "Edit A Fileset" dialog for this
    particular fileset will now have text-edit fields into which you can
    enter the desired information.
}

namespace eval fileset {}

proc fileset::checkIndentationPreference {fset name} {
    set tab [fileset::getInformation $fset "Tab Size"]
    set indent [fileset::getInformation $fset "Indentation Amount"]
    set spaces [fileset::getInformation $fset "Indent Using Spaces Only"]
    if {[string length $tab]} {
	win::setInitialConfig $name tabsize $tab "fileset"
    }
    if {[string length $indent]} {
	win::setInitialConfig $name indentationAmount $indent "fileset"
    }
    if {[string length $spaces]} {
	win::setInitialConfig $name indentUsingSpacesOnly $spaces "fileset"
    }
}
