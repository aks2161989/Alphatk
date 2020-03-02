## -*-Tcl-*-
 # ###################################################################
 #  Vince's Additions - an extension package for Alpha
 # 
 #  FILE: "filesetRemoteMirror.tcl"
 #                                    created: 02/23/2001 {21:16:18 PM} 
 #                                last update: 02/15/2005 {09:49:58 AM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #          317 Paseo de Peralta
 #     www: http://www.santafe.edu/~vince/
 #  
 # Copyright (c) 2001-2005 Vince Darley
 # 
 # Distributable under Tcl-style (free) license.
 # ###################################################################
 ##

alpha::library filesetRemoteMirror 0.4.0 {
    # Add the preferences as a group to filesets which want them
    fileset::attachNewInformationGroup "Fileset Remote Mirror" "" \
      "Allows you to mirror a given fileset onto a remote site" \
      [list url "Remote location" "" "Server to upload files to."]
    
    set "filesetUtils(updateFilesetMirror…)" [list * fileset::updateRemoteMirror]
} uninstall {
    this-file
} description {
    This "Fileset Information" preference allows you to mirror a given
    fileset onto a remote site
} help {
    This "Fileset Information" preference allows you to mirror a given
    fileset onto a remote site.  
    
    To use it, you can <<editAFileset>>, click on the "Attach Info" button,
    and click on the checkbox next to "Fileset Remote Mirror".  After clicking
    on the OK button, the "Edit A Fileset" dialog for this particular fileset
    will now have text-edit fields for server/username information.
   
    Now, whenever you would like to mirror the files, select the menu item
    "Fileset Menu > Utilities > Update Fileset Mirror", and you will be given
    a variety of options for which files to upload.
    
    IMPORTANT: If you're using Anarchy/Interarchy, files on your server not
    found on your disk will be deleted from the server!!
}

namespace eval fileset {}

proc fileset::updateRemoteMirror {{fset ""}} {
    if {![string length $fset] \
      && ![llength [fileset::thoseWithInformation "Fileset Remote Mirror"]]} {
	set q "In order to use this menu item you must first edit one or\
	  more filesets and \"attach\" some remote information to them.\
	  Would you like more information?"
	if {[askyesno $q]} {
	    package::helpWindow "filesetRemoteMirror"
	} else {
	    status::msg "Cancelled -- there are no filesets to mirror."
	}
	return
    }
    set fset [pickFileset $fset "Fileset to upload" \
      [list "withinfo" "Fileset Remote Mirror"]]
    if {![string length $fset]} { 
	status::msg "No fileset is available for mirroring.  You should attach\
	  'Fileset Remote Mirror' information to the filesets you want"
	return 
    }
    # Now upload, using urlMirrorHierarchy
    urlMirrorHierarchy [fileset::getBaseDirectory $fset] \
      [fileset::getInformation $fset "Remote location" "Fileset Remote Mirror"]
}
