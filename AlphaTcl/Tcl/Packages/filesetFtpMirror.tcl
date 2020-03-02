## -*-Tcl-*-
 # ###################################################################
 #  Vince's Additions - an extension package for Alpha
 # 
 #  FILE: "filesetFtpMirror.tcl"
 #                                    created: 02/23/2001 {21:16:18 PM} 
 #                                last update: 02/15/2005 {09:50:19 AM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #          317 Paseo de Peralta
 #     www: http://www.santafe.edu/~vince/
 #  
 # Copyright (c) 2001-2004 Vince Darley
 # 
 # Distributable under Tcl-style (free) license.
 # ###################################################################
 ##

alpha::library filesetFtpMirror 0.3.1 {
    # Make sure that this is no longer in the user's "global::features" list.
    if {([lsearch ${global::features} "filesetFtpMirror"] > -1)} {
	set tempIdx [lsearch ${global::features} "filesetFtpMirror"]
	set global::features [lreplace ${global::features} $tempIdx $tempIdx]
	prefs::modified "global::features"
	unset tempIdx
    } 
    # Add the preferences as a group to filesets which want them
    fileset::attachNewInformationGroup "Fileset Ftp Mirror" "" \
      "Allows you to mirror a given fileset onto an ftp site" \
     [list variable "Ftp server" "" "Server to upload files to."] \
     [list variable "User ID" "" "User name with access to above server."] \
     [list password "Password" "" "Password for above user name."] \
     [list variable "Directory" "" "Directory on the server."]
   
   set "filesetUtils(updateFilesetFtpMirror…)" [list * fileset::updateMirror]
} uninstall {
    this-file
} description {
    This "Fileset Information" preference allows you to mirror a given
    fileset onto an ftp site
} help {
    This "Fileset Information" preference allows you to mirror a given
    fileset onto an ftp site.  
    
    To use it, you can <<editAFileset>>, click on the "Attach Info" button,
    and click on the checkbox next to "Fileset Ftp Mirror".  After clicking
    on the OK button, the "Edit A Fileset" dialog for this particular fileset
    will now have text-edit fields for server/username information.
   
    Now, whenever you would like to mirror the files, select the menu item
    "Fileset Menu > Utilities > Update Fileset Ftp Mirror", and you will be given
    a variety of options for which files to upload.
    
    IMPORTANT: If you're using Anarchy/Interarchy, files on your server not
    found on your disk will be deleted from the server!!
}

namespace eval fileset {}

proc fileset::updateMirror {{fset ""}} {
    if {![string length $fset] \
      && ![llength [fileset::thoseWithInformation "Fileset Ftp Mirror"]]} {
	set q "In order to use this menu item you must first edit one or\
	  more filesets and \"attach\" some ftp information to them.\
	  Would you like more information?"
	if {[askyesno $q]} {
	    package::helpWindow "filesetFtpMirror"
	} else {
	    status::msg "Cancelled -- there are no filesets to mirror."
	}
	return
    }
    set fset [pickFileset $fset "Fileset to upload" \
      [list "withinfo" "Fileset Ftp Mirror"]]
    if {![string length $fset]} { 
	status::msg "No fileset is available for mirroring.  You should attach\
	  'Fileset Ftp Mirror' information to the filesets you want"
	return 
    }
    # Got the fileset, now need the ftp information
    foreach var [list "Ftp server" "User ID" "Password" "Directory"] {
	lappend spec [fileset::getInformation $fset $var "Fileset Ftp Mirror"]
    }
    # Now upload, using ftpMirrorHierarchy
    eval [list ftpMirrorHierarchy [fileset::getBaseDirectory $fset]] $spec
}
