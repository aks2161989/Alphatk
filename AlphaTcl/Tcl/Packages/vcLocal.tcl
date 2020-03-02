## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "vcLocal.tcl"
 #                                          created: 03/27/2000 {14:57:19 PM}
 #                                      last update: 05/08/2004 {05:13:33 PM}
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 2000-2003  Vince Darley.
 # 
 # Redistributable under standard 'Tcl' license.
 # 
 # Not all of the logic here is 100% correct, so use with caution.
 # 
 # ==========================================================================
 ##

# Feature declaration.
alpha::library vcLocal 0.2 {
    hook::register vcsSupportPackages {vcs::localSupport}
    namespace eval vcs {
	variable system
	set system(Local) vclocal
    }
    ;proc vcs::localSupport {args} {
	hook::register vcsSystemModified Local vclocal::attachToFileset
	fileset::attachAdditionalInformation "Version Control System" \
	  Local folder "Local Repository"
    }
} maintainer {
    {Vince Darley} <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} uninstall {
    this-file
} description {
    Support for a simple local version control
} help {
    This package provides support for a simple local version control.  It is
    only useful if the package: versionControl has been activated -- consult
    the help file opened by this hyperlink for more general information about
    using 'version control' in Alpha.
    
    Local version control is the simple situation in which you maintain one
    file-tree as the 'repository' which you do not edit, and another duplicate
    file-tree which you do edit.  Files in the duplicate tree may be checked
    in/out of the original when they are ready.  Also useful if you are trying
    to gradually merge your source tree with someone else's.
    
    It is an experimental way of dealing with development versus robust code.
    
    To use this method of version control, you must first edit a fileset
    <<editAFileset>> via the "Filesets > Utilities" submenu and change the
    "Version Control System" variable to "Local", which should be an option in
    the pop-up menu in this dialog.  Close this dialog, and then use
    <<editAFileset>> again and edit the same fileset -- there should now be a
    variable for a 'Local Repository' folder that you can set.  Remember --
    the fileset contains the files that you're editing, and the local
    repository is the one to which you are comparing (and the one to which you
    are possibly checking changes into).
    
    N.B. Vince once wrote:
    
	Not all of the logic here is 100% correct, so use with caution.
    
    which certainly isn't very confidence inspiring, and he also gave no
    indication as to which portions of the 'logic' might be subject to failure
    or what sort of harm this package might cause.  If curious, you can
    inspect the "vcLocal.tcl" file for more information.
} 

# ×××× -------- ×××× #

namespace eval vclocal {}

proc vclocal::attachToFileset {fset} {
    # no-op right now.
}

## 
 # -------------------------------------------------------------------------
 # 
 # "vclocal::getRepositoryFile" --
 # 
 #  For a file in the current fileset, under Local version control,
 #  find the equivalent file in the repository.  The actual file
 #  need not exist, since everything is handled via relative paths.
 # -------------------------------------------------------------------------
 ##
proc vclocal::getRepositoryFile {name} {
    set vcHierarchy [vcs::getFilesetInfo "Local Repository"]
    if {![string length $vcHierarchy]} {
	error "The local repository has not been set"
    }
    set relative [fileset::relativePath $name]
    set repositoryFile [file join $vcHierarchy $relative]
}

proc vclocal::getState {name} {
    set repositoryFile [vclocal::getRepositoryFile $name]
    if {[file exists $repositoryFile]} {
	# it's under version control, must check mod dates
	switch -- [file::compareModifiedDates $name $repositoryFile] {
	    -1 {
		return "needs-patch"
	    }
	    0 {
		return "up-to-date"
	    }
	    1 {
		return "checked-out"
	    }
	}
    } else {
	return "no-vcs"
    }
}

proc vclocal::otherCommands {state} {
    return [list updateAll]
}

proc vclocal::updateAll {name} {
    status::msg "vclocal update all: unimplemented"
}

proc vclocal::lock {name} {
    vcs::lock $name
}

proc vclocal::unlock {name} {
    vcs::unlock $name
}

proc vclocal::checkIn {name} {
    set repositoryFile [vclocal::getRepositoryFile $name]
    if {[file exists $repositoryFile]} {
	file delete $repositoryFile
    }
    file copy $name $repositoryFile
    vclocal::lock $name
    status::msg "vclocal checkin: done"
}

proc vclocal::checkOut {name} {
    vclocal::unlock $name
    status::msg "vclocal checkout: done"
}

proc vclocal::undoCheckout {name} {
    vclocal::lock $name
    status::msg "vclocal undoCheckout: done"
}

proc vclocal::add {name} {
    set repositoryFile [vclocal::getRepositoryFile $name]
    file copy $name $repositoryFile
    status::msg "vclocal add: successful"
}

proc vclocal::showDifferences {name} {
    set repositoryFile [vclocal::getRepositoryFile $name]
    compare::files $name $repositoryFile 0
}

proc vclocal::refetchReadOnly {name} {
    set repositoryFile [vclocal::getRepositoryFile $name]
    set mod [file::compareModifiedDates $name $repositoryFile]
    if {$mod == 1} {
	if {[dialog::yesno -y "Overwite" -n "Cancel operation" "Are you sure?  The current file is newer"]} {
	    set mod 0
	} else {
	    status::msg "vclocal refetchReadOnly: cancelled"
	    return
	}
    }
    if {!$mod} {
	file delete $name
	file copy $repositoryFile $name
	revert -w $name
	status::msg "vclocal refetchReadOnly: replaced with repository version"
    } else {
	status::msg "vclocal refetchReadOnly: no new version available"
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "vclocal::getMenuItems" --
 # 
 #  Returns menu items pertinant to local version control
 # -------------------------------------------------------------------------
 ##
proc vclocal::getMenuItems {state} {
    set res [vcs::generalMenuItems $state]
    if {[llength res]} {
        lappend res "(-)"
    } 
    lappend res updateAll
    
    return $res
}

