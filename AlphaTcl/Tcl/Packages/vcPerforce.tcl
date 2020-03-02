## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "vcPerforce.tcl"
 #                                          created: 03/27/2000 {14:57:19 PM}
 #                                      last update: 2005-02-23 23:44:49
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 2000-2004  Vince Darley
 # All rights reserved.
 # 
 # Redistributable under standard 'Tcl' license.
 # 
 # ==========================================================================
 ##

# Feature declaration.
alpha::library vcPerforce 0.3 {
    namespace eval vcs {
	variable system
	set system(Perforce) perforce
    }
} uninstall {
    this-file
} maintainer {
    {Vince Darley} <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} description {
    Perforce version control
} help {
    This package provides support for perforce version control.  It is only
    useful if the package: versionControl has been activated -- consult the
    help file opened by this hyperlink for more general information about
    using 'version control' in Alpha.

    So far it requires you to setup your client using some other tool.  Once
    that is setup, you can do simple checkout/checkin operations from within
    Alpha.
    
    See <http://www.perforce.com/> for more information about Perforce.
}

::xserv::declare perforceAction "Perform Perforce action" args

xserv::register perforceAction "Command-line Perforce" -driver {
    return "[list $params(xserv-perforce)] $params(args)"
} -mode Exec -progs perforce

proc vcPerforce.tcl {} {}

# ×××× -------- ×××× #

namespace eval perforce {}

proc perforce::getState {name} {
    set st [perforce::execute opened $name]
    if {[string first "is not under client's root" $st] != -1} {
	# not in correct path to be in repository
	return ""
    } elseif {[string first " - file(s) not opened on this client." $st] != -1} {
	# either not open, or not in repository
	set st [perforce::execute files $name]
	if {[string first " - no such file(s)." $st] != -1} {
	    # not in repository
	    return "no-vcs"
	} else {
	    # it's in there, but not open
	    return "read-only"
	}
    } else {
	# it is open in edit mode
	return "checked-out"
    }
}

proc perforce::makeChangeSpec {description} {
    set changelist [perforce::execute change -o]
    regsub {<enter description here>} $changelist [quote::Regsub $description] changelist

    set filename [temp::path tmp perforce.tmp]
    set fout [open $filename w]
    puts -nonewline $fout $changelist
    close $fout
    return $filename
}

proc perforce::execute {args} {
    xserv::invoke perforceAction -args $args
}

proc perforce::otherCommands {state} {
    return ""
}

proc perforce::lock {name} {
    status::msg "perforce lock: [perforce::execute revert [win::StripCount $name]]"
}

proc perforce::unlock {name} {
    status::msg "perforce unlock: [perforce::execute edit [win::StripCount $name]]"
}

proc perforce::add {name} {
    status::msg "perforce add: [perforce::execute add [win::StripCount $name]]"
}

proc perforce::checkIn {name {description ""}} {
    if {![string length $description]} {
	set description [getline "Description of change"]
	if {![string length $description]} {
	    error "Cancelled -- no text was entered."
	}
    }
    set result [perforce::execute submit -i [win::StripCount $name] \
      < [perforce::makeChangeSpec $description]]
    status::msg "perforce checkin: $result"
    vcs::syncLockStatus $name
}

proc perforce::undoCheckout {name} {
    set result [perforce::execute revert [win::StripCount $name]]
    revert -w $name
    status::msg "perforce undoCheckout: $result"
}

proc perforce::checkOut {name} {
    status::msg "perforce checkout: [perforce::execute edit [win::StripCount $name]]"
}

proc perforce::refetchReadOnly {name} {
    set result [perforce::execute sync [win::StripCount $name]]
    if {![string match "* - file(s) up-to-date." $result]} {
	revert -w $name
    }
    status::msg "perforce refetchReadOnly: $result"
}

proc perforce::showDifferences {name} {
    set difference [perforce::execute diff -dc $name]
    if {![string match "* - file(s) not opened on this client." $difference]} {
	Diff::of $name $difference
    } else {
	status::msg "cvs diff: $difference"
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "perforce::getMenuItems" --
 # 
 #  Returns menu items pertinant to Perforce
 # -------------------------------------------------------------------------
 ##
proc perforce::getMenuItems {state} {
    return [vcs::generalMenuItems $state]
}



