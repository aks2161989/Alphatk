## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "odbEditor.tcl"
 #                                    created: 5/2/01 {10:04:08 PM} 
 #                                last update: 2006-02-03 23:38:44 
 #  Author: Jonathan Guyer
 #  E-mail: jguyer@his.com
 #    mail: Alpha Cabal
 #     www: http://www.his.com/jguyer/
 #  
 # ========================================================================
 # Copyright (c) 2001-2004 Jonathan Guyer
 # All rights reserved.
 # 
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions are met:
 # 
 #      * Redistributions of source code must retain the above copyright
 #      notice, this list of conditions and the following disclaimer.
 # 
 #      * Redistributions in binary form must reproduce the above copyright
 #      notice, this list of conditions and the following disclaimer in the
 #      documentation and/or other materials provided with the distribution.
 # 
 #      * Neither the name of Alpha Cabal nor the names of its
 #      contributors may be used to endorse or promote products derived from
 #      this software without specific prior written permission.
 # 
 # 
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 # AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 # IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 # ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
 # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 # DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 # SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 # CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 # LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 # OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 # DAMAGE.
 # ========================================================================
 #  Description: 
 # 
 # 	This package allows Alpha to act as an external editor for
 # 	applications that support the Bare Bones' ODB Editor suite
 # 	<http://www.barebones.com/support/developer/odbsuite.html>.
 # 	
 #  History
 # 
 #  modified   by  rev reason
 #  ---------- --- --- -----------
 #  2001-05-02 JEG 1.0 original
 # ###################################################################
 ##

alpha::feature ODBEditor 1.0b3 global-only {} {
    hook::register aevtodocHook odb::aevtodocHook 
    hook::register savePostHook odb::modifiedHook
    hook::register winChangedNameHook odb::winChangedNameHook
    hook::register closeHook odb::closeHook
} {
    hook::deregister aevtodocHook odb::aevtodocHook 
    hook::deregister savePostHook odb::modifiedHook
    hook::deregister winChangedNameHook odb::winChangedNameHook
    hook::deregister closeHook odb::closeHook
} maintainer {
    "Jon Guyer" <jguyer@his.com> <http://www.his.com/jguyer/>
} requirements {
    if {!${alpha::macos}} {
	error "The ODB Editor suite is only supported on the Macintosh"
    }
    alpha::package require Alpha 8.0a3
    alpha::package require aeom 1.0a3
    package require tclAE
} description {
    This package allows Alpha to act as an external editor for
    applications that support Bare Bones' ODB Editor suite
} help {
    This package allows Alpha to act as an external editor for applications
    that support Bare Bones' ODB Editor suite.  
    
    <http://www.barebones.com/support/developer/odbsuite.html>.
 
    Two such applications are Interarchy >= 4.1 and Fetch >= 4.0 .  This
    package allows you use Alpha instead of BBEdit to edit remote files
    listed in the windows of these applications.  Frontier is another example
    of such an application.
 
    This package is only useful in the MacOS, both MacClassic and OSX.
 

	  	Table Of Contents


    "# Integration with Interarchy"
    "#   MacClassic"
    "#   MacOSX"
    "# Integration with Fetch"
    "# Integration with Frontier"

    <<floatNamedMarks>>
      

	  	Integration with Interarchy
 
    Interarchy 4.1 or greater is required.
      
    Interarchy has a "Listing > Edit with <ftp-editor>" menu command.
    Selecting this command fetches the current selected remote file, and opens
    it in your ftp-editor helper application.  Saving the file will
    automatically upload the new version to the remote site.
    
    <http://interarchy.reppep.com/pages/menu-listing.html#EditwithBBEdit>
      
    The "ftp-editor" preference is an OS setting that you can add/edit to open
    files using Alpha following the instructions below.
      
	  	 	MacClassic
 
    To use Alpha as your Interarchy text editor, you must first go to the
    Internet(Config) control panel <<icOpen>>, open the 'Advanced' dialog
    pane, click on the 'Helper Apps' icon in the side-bar, and then press the
    'Add' button to create a new helper app type named 'ftp-editor'.  The
    description should be something like "Edit from Interarchy" and the helper
    application that you select should be your local version of Alpha.  Save
    your Internet(Config) settings.
      
	  	 	MacOSX
      
    Similar to MacClassic, OSX contains system-wide internet preferences for
    Browser, Mailer, File-Mappings, and Protocol Helpers.  For some bizarre
    reason, however, Apple has decided to not make these settings visible to
    the user.  In order to change your "ftp-editor" helper application, you
    must first download and install "MisFox" (Missing Internet Settings For X)
    
    <http://www.clauss-net.de/mac.html>
    
    or some similar application.  Start the program, and inspect your Protocol
    Helpers.  If there is no "ftp-editor" setting available, add it.  If the
    setting for this helper is not Alpha, edit it and change the value for the
    helper to Alpha.
    
    A similar tool is More Internet:

    <http://www.monkeyfood.com/software/MoreInternet/>
    
    which adds a new SystemPreferences pane allowing you to change all of your
    "Protocal Helpers".
      

	  	Integration with Fetch
 
    Fetch 4.0 or greater is required.
 
    Fetch 4.0 includes a "Fetch Example Scripts" folder in its top-level
    hierarchy which includes a file named "SetSecretOptions".  Open this file,
    and if it opens in the AppleScript Editor application press "Run".  You
    will now have a list-pick dialog of options that you can set -- choose
    "Specify external text editor", and then choose Alpha8.  You can then
    close the "SetSecretOptions" file and quit the AppleScript Editor.
 
    (In Fetch 4.0.3 there is actually a "SetSecretOptions" _folder_ that
    includes a separate "Set External Text Editor" script, if this is the case
    then simply launch that file instead and follow the rest of the
    instructions outlined above.)
 
    IMPORTANT: If you have both Fetch 3.0.3 and Fetch 4.x on your local disk,
    be sure to launch the 4.x version before running the script, or else
    running the AppleScript file might throw an error.
 
    Go back to Fetch (or launch it if necessary) and you should now see a
    "Remote > Edit File with Alpha8/X" menu item available.  If you select a
    file in a ftp window, you should be able to edit it in Alpha by selecting
    the appropriate menu item or its key binding.  When you save the file, it
    will automatically be uploaded using Fetch.
 
 
	  	Integration with Frontier
 
    Alpha has been supported as a Frontier editing application for a long
    time.  This package removes the need to change the script found in
    "suites.odbEditor.editors.Text.edit", as was necessary in Alpha 7.x.

    See the "Frontier Help" file for more information.
}


namespace eval odb {}

## 
 # -------------------------------------------------------------------------
 # 
 # "odb::aevtodocHook" --
 # 
 #  aevt/odoc AppleEvent hook for files opened via the ODB Editor suite.
 #  
 #  If the file is ODB Edited, then the file sender parameter 'FSnd' will
 #  always appear.
 #  
 #  The sender token 'FTok' and custom path 'Burl' parameters are optional.
 #  'FTok' is simply stored to resend to the file sender. 'Burl' is interpreted
 #  as well as can be to display the file properly.
 #  
 # 
 # Argument     Default In/Out Description
 # ------------ ------- ------ ---------------------------------------------
 # win                    In   full name of window that was opened by this event
 # index                  In   non-negative index if file was opened as one of a list
 # theAppleEvent          In   the AppleEvent descriptor that triggered this hook
 # theReplyAE           In/Out the reply AppleEvent that will be sent back to the caller
 # 
 # Results:
 #  1 if this was an ODB Edited file
 #  0 otherwise
 # 
 # Side effects:
 #  tracking information is stored so that proper events can be sent back
 #  to the server when the file is modified or closed. Also, if the file is
 #  edited via FTP, proper information is stored so Alpha treats it properly.
 # -------------------------------------------------------------------------
 ##
proc odb::aevtodocHook {win index theAppleEvent theReplyAE} {
    if {![catch {tclAE::getKeyData $theAppleEvent FSnd} sender]} {
	global odbedited fetched
	
	# sender token is optional
	set token ""
	catch {
	    set token [tclAE::getKeyDesc $theAppleEvent FTok]
	    if {$index >= 0} {
		# original file was opened from a list of files
		# extract the corresponding token
		set temp [tclAE::getNthDesc $token $index]
		tclAE::disposeDesc $token
		set token $temp
	    }
	}
	
	# custom path is optional
	catch {
	    set customPath [tclAE::getKeyData $theAppleEvent Burl]
	    if {$index >= 0} {
		# original file was opened from a list of files
		# extract the corresponding custom path
		set customPath [lindex $customPath $index]
	    }
	
	    # determine if the custom path is a url (remote FTP editing)
	    set url [url::parse $customPath]
	    if {[lindex $url 0] == "ftp"} {
		# custom path is an ftp url, so make sure Alpha treats
		# it accordingly
		alpha::package require ftpMenu
		url::parseFtp [lindex $url 1] a
		set fetched($win) [list $a(host) $a(path) $a(user) $a(pass) "ftp"]
	    }
	}
	
	# store ODB Edit information for later use
	set odbedited($win) [list $sender $token]
	
	return 1
    } else {
	# this file was not ODB Edited
	return 0
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "odb::modifiedHook" --
 # 
 #  save(as) hook for ODB Edited files.
 # 
 # Argument     Default In/Out Description
 # ------------ ------- ------ ---------------------------------------------
 # oldName                In   the original path of the file
 # newName        ""    In/Out the new path of the file (if saveAs invoked)
 # 
 # Results:
 #  1 if this was an ODB Edited file
 #  0 otherwise
 # 
 # Side effects:
 #  sender is notified of file change
 # -------------------------------------------------------------------------
 ##
proc odb::modifiedHook {oldName {newName ""}} {
    global odbedited
    
    if {[info exists odbedited($oldName)]} {
	set sender [lindex [set odbedited($oldName)] 0]
	set token [lindex [set odbedited($oldName)] 1]
	
	# build file-modified event
	set event [list tclAE::build::throw '${sender}' R*ch FMod]
	lappend event ---- [tclAE::build::alis $oldName]
	# attach token (if any)
	if {[string length $token] > 0} {
	    lappend event Tokn $token
	} 
	# attach new file name (if any)
	if {[string length $newName] > 0} {
	    lappend event New? [tclAE::build::alis $newName]
	    set odbedited($newName) [set odbedited($oldName)]
	    array unset odbedited $oldName
	}
	
	eval $event
	
	return 1
    } else {
	# this file was not ODB Edited
	return 0
    }
}

# <JK date="Feb2006"> The odb::modifiedHook is triggered both by
# the winChangedNameHook and the savePostHook.  The former provides
# two arguments: newName and oldName.  The latter provides only
# oldName.  Probably this is equal to newName, so it should make
# no difference which argument is missing...  So probably the above
# hybrid hook could be adjusted to accomodate both hooks, simply
# by interchanging the order of the two arguments.  However, since
# I am not too sure about the role of oldName in odb, I have found
# it safer to register this little wrapper for winChangedNameHook:
# in simply inverts the order of the arguments and calls 
# odb::modifiedHook.  These changes instilled by RFE 1942. </JK>
proc odb::winChangedNameHook {name oldName} {
    ::odb::modifiedHook $oldName $name
}

## 
 # -------------------------------------------------------------------------
 # 
 # "odb::closeHook" --
 # 
 #  close hook for ODB Edited files.
 # 
 # Argument     Default In/Out Description
 # ------------ ------- ------ ---------------------------------------------
 # name                   In   the path of the file
 # 
 # Results:
 #  1 if this was an ODB Edited file
 #  0 otherwise
 # 
 # Side effects:
 #  sender is notified of file closing
 # -------------------------------------------------------------------------
 ##
proc odb::closeHook {name} {
    global odbedited
    
    if {[info exists odbedited($name)]} {
	set sender [lindex [set odbedited($name)] 0]
	set token [lindex [set odbedited($name)] 1]
	
	# stored file info is no longer needed
	unset odbedited($name)
	unset -nocomplain fetched($name)
	
	# build file-closed event
	set event [list tclAE::build::throw '${sender}' R*ch FCls]
	lappend event ---- [tclAE::build::alis $name]
	
	# attach token (if any)
	if {[string length $token] > 0} {
	    lappend event Tokn $token
	} 
	
	eval $event

	if {[string length $token] > 0} {
	    tclAE::disposeDesc $token
	}
	
	return 1
    } else {
	# this file was not ODB Edited
	return 0
    }
}

proc odb::editFromFetch {} {
    global HOME ALPHA
    
    tclAE::build::throw 'FTCh' core setd \
      ---- [tclAE::build::propertyObject pETE] \
      data [tclAE::build::alis [file join $HOME $ALPHA]]
}

    