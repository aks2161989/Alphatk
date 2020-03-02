## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "vcCvs.tcl"
 #                                          created: 05/19/2000 {04:44:53 PM}
 #                                      last update: 02/20/2006 {04:46:36 PM}
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 2000-2006  Vince Darley.
 # All rights reserved.
 # 
 # Redistributable under standard 'Tcl' license.
 # 
 # Note: when running under Alphatk, the command-line cvs is used.  We
 # cannot (yet) interact properly with the command-line cvs, and hence if
 # cvs asks us for a password, the command will fail.
 # 
 # You should therefore configure things (if possible) so that login occurs
 # automatically.
 # 
 # In the future hopefully this constraint will be removed.
 # 
 # ==========================================================================
 ##

# Feature declaration.
alpha::library vcCvs 0.4.1 {
    hook::register vcsSupportPackages {vcs::cvsSupport}
    namespace eval vcs {
	variable system
	set system(Cvs) cvs
    }
    ;proc vcs::cvsSupport {args} {
	# Any flags you wish to pass the CVS application, which are
	# valid for any cvs action.
	newPref var cvsGlobalFlags "" vcs
	# If we're using the MacOS, we can add fileset information for
	# MacCVS Pro session files.
	if {$::alpha::macos} {
	    fileset::attachNewInformation "" file \
	      "MacCvs Pro Session File" "" \
	      "The CVS session file used by MacCvs Pro for this fileset"
	}
    }
} uninstall {
    this-file
} maintainer {
    {Vince Darley} <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} description {
    Support for CVS version control
} help {
    This package provides support for CVS version control.  It is only useful
    if the package: versionControl has been activated -- consult the help file
    opened by this hyperlink for more general information about using 'version
    control' in Alpha.
    
    'CVS' stands for "Concurrent Versions System", for more information see
    this url:
    
        <http://www.cvshome.org/>
    
    To use this method of version control, you must first edit a fileset
    <<editAFileset>> via the "Filesets > Utilities" submenu and change the
    "Version Control System" variable to "CVS", which should be an option in
    the pop-up menu in this dialog.
    
    If you are using the MacOS and MacCVS Pro, you can specify a .cvs session
    file that should be associated with this fileset.  In the <<editAFileset>>
    dialog, click on the "Attach/Detach Info" button, and then set the
    checkbox for "MacCvs Pro Session File", and the "OK".  As an alert dialog
    should inform you, you can now close this dialog, and then use
    <<editAFileset>> again and edit the same fileset -- there should now be a
    variable for "MacCvs Pro Session File" that you can set.
    
    IMPORTANT: 
    
    For cvs usage to a system which doesn't require a password (e.g. public
    access to alphatcl or any sourceforge project), AlphaTcl's cvs setup
    should work fine.  However, if you need to access a cvs repository which
    needs a password, you will need to set things up with 'ssh' so that you
    don't need to type your password each time.  The best instructions for
    this that I have found are available here:

    unix: <http://www.joot.com/dave/writings/articles/cvs-ssh.html>
    win:  <http://sourceforge.net/docman/display_doc.php?docid=766&group_id=1>

    When running under Alphatk, the command-line cvs is used.  We cannot (yet)
    interact properly with the command-line cvs, and hence if cvs asks us for
    a password, the command will fail.
    
    You should therefore configure things (if possible) so that login occurs
    automatically.  In the future hopefully this constraint will be removed.
}

::xserv::declareBundle cvs "Concurrent Version Control" \
  cvsActionOnFile cvsAction

::xserv::declare cvsAction "Perform CVS action" args
::xserv::declare cvsActionOnFile "Perform CVS action on a file" file action

xserv::register cvsAction "MacCVS" -sig mCVS -driver {
    set tmp [temp::path cvs tmp]
    # There has to be too many 'eval's here!  Please simplify me...
    eval [eval concat tclAE::build::resultData 'mCVS' misc dosc \
      "----" $params(args) MODE FILE FILE \
      [list [list [tclAE::build::TEXT $tmp]]]]
    return [file::readAll $tmp]
}

xserv::register cvsAction "MacCVS Pro" -sig Mcvs -driver {
    
}

xserv::register cvsAction "Command-line CVS" -driver {
    global vcsmodeVars
    return "[list $params(xserv-cvs)] $vcsmodeVars(cvsGlobalFlags) $params(args)"
} -mode Exec -progs cvs

xserv::register cvsActionOnFile "MacCVS" -sig mCVS -driver {
    global vcsmodeVars
    app::ensureRunning mCVS
      "Please locate a Cvs application."
    set script "$vcsmodeVars(cvsGlobalFlags) $params(action)"
    set script [list [tclAE::build::List [concat $script [file tail $params(file)]] -as TEXT] SPWD [tclAE::build::TEXT [file dirname $params(file)]]]
    return [::xserv::infoke cvsAction -args $script]
}

xserv::register cvsActionOnFile "MacCVS Pro" -sig Mcvs -driver {
    # Global flags are ignored for MacCVS Pro.
    app::ensureRunning Mcvs
    
    # The events we understand
    array set MacCvsProEvents {
	commit ChKn
	update updt
	checkout cout
	edit "MRO "
    }

    set com ""
    if {[lindex $params(action) 0] == "commit"} {
	set com [list Cmnt [tclAE::build::TEXT [lindex $params(action) 2]]]
	set action [lindex $params(action) 0]
    } else {
	if {[lindex $params(action) 0] == "edit" \
	  && [vcs::getFilesetInfo "MacCvs Pro Session File"] == ""} {
	    vcs::ckid::setMRO $params(file)
	    return
	}
	set action $params(action)
    }
    if {![info exists MacCvsProEvents($action)]} {
	return "$params(action) not implemented for MacCvs Pro."
    }
    # There has to be too many 'eval's here!  Please simplify me...
    eval [eval concat \
      [list tclAE::send -p 'Mcvs' MCvs $MacCvsProEvents($action) \
      "----" [list [cvs::MacCvsProFileRef $params(file)]]] $com]
}

xserv::register cvsActionOnFile "Command-line CVS" -driver {
    global vcsmodeVars
    if {[file isdirectory $params(file)]} {
	set params(-indir) $params(file)
	return "[list $params(xserv-cvs)] $vcsmodeVars(cvsGlobalFlags) $params(action)"
    } else {
	set params(-indir) [file dirname $params(file)]
	return "[list $params(xserv-cvs)] $vcsmodeVars(cvsGlobalFlags) $params(action)\
	  [list [file tail $params(file)]]"
    }
} -mode Exec -progs cvs -indir {expr {[file isdir $params(file)] ? $params(file) : [file dirname $params(file)]}}



proc vcCvs.tcl {} {}

# ×××× -------- ×××× #

namespace eval cvs {}

proc cvs::getState {name} {
    # Should this be CVS or Cvs on a filesystem that cares about
    # such things?
    if {[file exists [file join [file dirname $name] CVS]]} {
	# it's under version control, to do...
	set status [cvs::actionOnFile status $name]
	if {[regexp {Status: ([^\r\n]*)} $status "" status]} {
	    set status [string trim $status]
	    if {$status == "Needs Patch"} {
		return "needs-patch"
	    } elseif {$status == "Up-to-date"} {
		return "up-to-date"
	    } elseif {$status == "Unknown"} {
		return "no-vcs"
	    } elseif {$status == "File had conflicts on merge"} {
		return "conflicts"
	    } else {
		return "checked-out"
	    }
	} else {
	    status::msg "$status"
	    return ""
	}
    } else {
	return ""
    }
}

# Perform a CVS action on a file.
proc cvs::actionOnFile {action onFile} {
    set onFile [win::StripCount $onFile]
    return [::xserv::invoke cvsActionOnFile \
      -xservInteraction 0 -file $onFile -action $action]
}

# Perform a CVS action on a folder.
proc cvs::actionOnDir {action onDir} {
    return [::xserv::invoke cvsActionOnFile \
      -xservInteraction 0 -file $onDir -action $action]
}

proc cvs::otherCommands {state} {
    return [list updateAll]
}

proc cvs::updateAll {name} {
    status::msg "cvs update all: [cvs::actionOnDir update [file dirname $name]]"
}

proc cvs::lock {name} {
    vcs::lock $name
}

proc cvs::unlock {name} {
    vcs::unlock $name
}

proc cvs::checkIn {name} {
    global vcsmodeVars
    status::msg "cvs checkin: [cvs::actionOnFile [list commit -m [prompt "Log message:" ""]] $name]"
    # cvs modifies the file's header
    revert -w $name
}

# Checkout only apply to folders.
proc cvs::checkOut {name} {
    status::msg "cvs checkout: unimplemented"
#     status::msg "cvs checkout: [cvs::actionOnFile checkout $name]"
}

proc cvs::checkOutClean {name} {
    set result [string trim [cvs::actionOnFile "update -C" $name]]
    if {[string length $result]} {
	revert -w $name
	status::msg "cvs checkOutClean $result"
    } else {
	status::msg "cvs checkOutClean no new version available"
    }
}

proc cvs::undoCheckout {name} {
    status::msg "cvs undoCheckout: unimplemented"
}

proc cvs::add {name} {
    status::msg "cvs add: [cvs::actionOnFile add $name]"
}

proc cvs::makeWritable {name} {
    status::msg "cvs makeWritable: [cvs::actionOnFile edit $name]"
    setWinInfo read-only 0
}

proc cvs::showDifferences {name} {
    set difference [cvs::actionOnFile "diff -u" $name]
    if {[string length $difference]} {
	Diff::of $name $difference
    } else {
	status::msg "cvs diff: no differences to file in repository"
    }
}

proc cvs::refetchReadOnly {name} {
    set result [string trim [cvs::actionOnFile update $name]]
    if {[string length $result]} {
	revert -w $name
	status::msg "cvs refetchReadOnly: $result"
    } else {
	status::msg "cvs refetchReadOnly: no new version available"
    }
}

# Returns the MacCVS Pro session file of the current fileset.
proc cvs::MacCvsProSessionFile {} {
    
    set sessionfile [vcs::getFilesetInfo "MacCvs Pro Session File"]
    if {($sessionfile ne "")} {
        return $sessionfile
    } elseif {([set fset [vcs::getFileset]] eq "")} {
	set q "In order to use this menu item, you must define a\
	  fileset that contains this window."
	if {[dialog::yesno -y "Edit A FilesetÉ" -n "Create A FilesetÉ" -c $q]} {
	    editAFileset
	} else {
	    newFileset 
	}
	return [cvs::MacCvsProSessionFile]
    } else {
	set q "The fileset '${fset}' has not defined any MacCVS Pro\
	  Session File, so this operation cannot be performed."
	if {[dialog::yesno -y "Edit FilesetÉ" -n "Cancel" $q]} {
	    editAFileset $fset
	} else {
	    error "cancel"
	}
	return [cvs::MacCvsProSessionFile]
    }
    error "VC-CVS operation cancelled -- no session file."
}

# Returns the local root of a MacCVS Pro session file.
proc cvs::MacCvsProLocalRoot {name sessionfile} {
    
    sendOpenEvent noReply 'Mcvs' $sessionfile
    set localroot [tclAE::build::resultDataAs TEXT 'Mcvs' core getd ----\
      [tclAE::build::propertyObject lrfs [tclAE::build::nameObject docu \
      [tclAE::build::TEXT [file tail $sessionfile]] [tclAE::build::nullObject]]]]
    # Make sure that we are using the correct local root.
    set localRootPath [file split $localroot]
    set thisFilePath  [file split $name]
    set localRootIdx  [expr {[llength $localRootPath] - 1}]
    if {($localRootPath ne [lrange $thisFilePath 0 $localRootIdx])} {
	dialog::alert "The local root of this window's fileset is $localroot,\
	  but this window is not inside that folder."
	error "wrong local root"
    }
    return $localroot
}

# Returns the relative path to the local root of "name".
proc cvs::MacCvsProFileRef {name} {
    set sessionfile [cvs::MacCvsProSessionFile]
    set root [cvs::MacCvsProLocalRoot $name $sessionfile]
    set name [string range $name [expr {[string length $root] + 1}] end]
    regsub -all : $name / name
    tclAE::build::nameObject file [tclAE::build::TEXT $name] \
      [tclAE::build::nameObject docu [tclAE::build::TEXT \
      [file tail $sessionfile]] [tclAE::build::nullObject]]
}


## 
 # -------------------------------------------------------------------------
 # 
 # "cvs::getMenuItems" --
 # 
 #  Returns menu items pertinent to CVS
 # -------------------------------------------------------------------------
 ##
proc cvs::getMenuItems {state} {
    set res [vcs::generalMenuItems $state]
    if {[llength res]} {
        lappend res "(-)"
    } 
    lappend res updateAll
    
    return $res
}


