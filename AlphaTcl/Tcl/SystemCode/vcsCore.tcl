## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "vcsCore.tcl"
 #                                          created: 03/23/2000 {10:59:22 AM}
 #                                      last update: 02/28/2006 {02:50:40 PM}
 # Description:
 # 
 # Provides the basic Version Control support in AlphaTcl.
 # 
 # This code was designed to work with Tcl 7.x as well as 8.x, which is why
 # namespaces aren't handled in the most elegant way.  This should be
 # addressed, especially since AlphaTcl now requires Tcl 8.x.
 # 
 # Copyright (c) 1998-2006 Jon Guyer, Vince Darley
 # All rights reserved.
 # 
 # --------------------------------------------------------------------------
 # 
 # Permission to use, copy, modify, and distribute this software and its
 # documentation for any purpose and without fee is hereby granted, provided
 # that the above copyright notice appear in all copies and that both that
 # the copyright notice and warranty disclaimer appear in supporting
 # documentation.
 # 
 # The authors disclaim all warranties with regard to this software,
 # including all implied warranties of merchantability and fitness.  In no
 # event shall the authors be liable for any special, indirect or
 # consequential damages or any damages whatsoever resulting from loss of
 # use, data or profits, whether in an action of contract, negligence or
 # other tortuous action, arising out of or in connection with the use or
 # performance of this software.
 # 
 # ==========================================================================
 ##

alpha::feature versionControl 0.3.1 "global-only" {
    # Initialization script.
    # Call any support package procs.
    hook::callAll vcsSupportPackages
    namespace eval vcs {
	variable system
	variable vcSystems [concat [list "None" "-"] \
	  [lremove [lsort -dictionary [array names system]] "None"]]
    }
    # We are moving this preference out of the 'vcsmodeVars' array, and no
    # longer present it to the user to change.  If the current window is not
    # part of a fileset, the vcs tool will be 'None'.  The main reason for
    # defining the pref at all is so that it can be used as a prototype for
    # the fileset information.
    prefs::renameOld vcsmodeVars(versionControlSystem) vcSystems
    # The current version control system.
    newPref var vcSystems "None" "global" "" $::vcs::vcSystems
    # To always include the name of the version control system associated
    # with the current window in the pop-up menu, turn this item on||To
    # never include the name of the version control system associated with
    # the current window in the pop-up menu, turn this item off
    newPref flag addNameOfSystemToPopup 1 vcs
    # Includes items related to the Version Control status of the active
    # window; ; this is a duplicate of the VCS pop-up menu that appears at
    # the top of each window's scrollbar
    newPref f vcsMenu 0 contextualMenu
    namespace eval contextualMenu {
	variable menuSections
	# This is set of items potentially appearing at the bottom of the CM.
	lappend menuSections(4) "vcsMenu"
    }
    # Define menu build procs.
    menu::buildProc "vcs"       {vcs::buildVcsCMenu} {vcs::postBuildCM}
    menu::buildProc "vcsMenu"   {vcs::buildVcsMenu}
    # Add a version control prefs page, mapped to the 'vcs' storage
    package::addPrefsDialog versionControl vcs
    # This allows us to attach version control information to any fileset
    fileset::attachNewInformation * \
      {prefItemType vcSystems} "Version Control System" \
      None "The version control system under which these\
      files are placed" vcs::vcsSystemModified
} {
    # Activation script.
    # (Alphatk) Called when the user ctrl/cmd-clicks on the lock icon
    hook::register   unlockHook vcs::manualUnlock *
    hook::register   lockHook   vcs::manualLock   *
} {
    # Deactivation script.
    hook::deregister unlockHook vcs::manualUnlock *
    hook::deregister lockHook   vcs::manualLock   *
} description {
    Creates a "Version Control" pop-up menu in the sidebar of each window, so
    that you to use Alpha to open, check out, check in, diff, merge,...
    files with respect to some local or remote file repository
} help {
    file "Version Control Help"
} maintainer {
    {Jon, Vince and others}
}

proc vcsCore.tcl {} {}

namespace eval vcs {
    variable system
    set system(None) vcs
}

# Dummy procedure
proc vcs::checkCompatibility {name} {}

# This proc should be unnecessary now -- any support packages should just
# use "namespace eval vcs {variable system ; set system(type) ns}" within
# 'preinit' scripts.
proc vcs::register {type {ns ""}} {
    variable system
    if {![string length $ns]} { set ns $type }
    set system($type) $ns
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Building/Executing VCS menu ×××× #
# 

# This is a callback routine for Alpha 8's VCS popup menu
proc ckidMenu {stateIndex locked} {

    set states [list "no-vcs" "checked-out" "read-only" "mro"]
    set state  [lindex $states $stateIndex]
    # This next line suggests that the previous two were pointless?
    set state  [vcs::getState [win::Current]]
    
    set ::menu::items(ckid) [vcs::menuItems $state $locked]
    menu::buildOne ckid
    return "ckid"
}

proc vcs::buildVcsMenu {} {
    
    set state [vcs::getState [win::Current]]
    getWinInfo -w [win::Current] info
    set menuList [menuItems $state $info(read-only)]
    
    return [list build $menuList [procOrDefault menuProc] {}]
}

proc vcs::buildVcsCMenu {} {
    
    if {[catch {vcs::buildVcsMenu} result]} {
        set result ""
    }
    return $result
}

## 
 # -------------------------------------------------------------------------
 # 
 # "vcs::menuItems" --
 # 
 # Used in a callback from Alpha 8 via the above proc, or directly in
 # Alphatk.  An empty state means AlphaTcl has no idea how to get any vcs
 # information for this file (e.g. we're running Alphatk), a state of
 # 'no-cvs' means this file doesn't appear to be under version control, but
 # we should really double-check.
 # 
 # -------------------------------------------------------------------------
 ##

# Just to make sure this exists ...

ensureset ::vcsmodeVars(addNameOfSystemToPopup) 1

proc vcs::menuItems {state locked} {

    set w [win::StripCount [win::Current]]
    set menuItems [list]
    # Icon prefix
    set icn "/\x1e"

    # ckid icon suite runs from 490 to 494
    # subtract 208 (why?!?) + 256
    if {$locked} {
	lappend menuItems "${icn}unlock[icon::FromID 494]" "\(-"
    } else {
	lappend menuItems "${icn}lock[icon::FromID 493]" "\(-"
    }
    set fset [vcs::getFileset]
    set vcs  [vcs::getSystem]
    
    if {[string tolower $vcs] != "none"} {
	# This will force loading of the source file ...
	set ns [vcs::getNamespace]
	if {[info commands ::${ns}::getMenuItems] == ""} {
	    auto_load ::${ns}::getMenuItems
	}
    }
    if {$state == "" || $state == "no-vcs"} {
	# Unknown state
	set state [vcs::call getState $w]
    }
    # 'win::IsFile' automatically strips <2> window count.
    if {![set isFile [win::IsFile $w]]} {
        lappend menuItems "\(Window doesn't exist as file"
    } elseif {$::vcsmodeVars(addNameOfSystemToPopup)} {
	if {[string tolower $vcs] == "none"} {
	    lappend menuItems "ª\(Using No VCS Tool"
	} else {
	    lappend menuItems "ª\(Using '${vcs}' VCS Tool"
	}
    }
    lappend menuItems "getInfoÉ"
    # Active items should depend on whether we have a VCS system 
    # active and on the state of the file.
    # 
    # Currently 'read-only' means the file is either 'up-to-date'
    # or 'needs-patch', but we don't know which (it appears as if
    # the ckid resource doesn't give us enough information?).
    eval lappend menuItems [vcs::call getMenuItems $state]
    # Add any other items the vcs system wants to use
    if {$isFile} {
	set extras [vcs::optionalCall otherCommands $state]
	if {[llength $extras]} {
	    lappend menuItems "(-)"
	    eval lappend menuItems $extras
	}
    }
    # Add prefs and help items.
    lappend menuItems "(-)"
    if {[string length $fset]} {
	lappend menuItems "ª\('${fset}' Fileset" \
	  "updateFileset" "filesetPrefsÉ" "(-)"
     }
    lappend menuItems "showInFinder" "versionControlPrefsÉ" "versionControlHelp"

    return $menuItems
}

## 
 # -------------------------------------------------------------------------
 # 
 # "vcs::getMenuItems" --
 # 
 # Called when there is no active VC System
 # All items disabled.
 # -------------------------------------------------------------------------
 ##

proc vcs::getMenuItems {state} {

    set res [list]
    # Icon prefix
    set icn "/\x1e"

    switch -- $state {
	"no-vcs" { 
	    lappend res "\(${icn}addÉ[icon::FromID 491]"        
	}
	"checked-out" { 
	    lappend res                                         \
	      "\(${icn}checkInÉ[icon::FromID 490]"              \
	      "\(${icn}undoCheckout[icon::FromID 491]"          \
	      "\(${icn}makeWritable[icon::FromID 492]"          \
	      "(-)"                                             \
	      "\(showDifferences" 
	}
	"conflicts" { 
	    lappend res                                         \
	      "\(checkOutCleanÉ"                                \
	      "(-)"                                             \
	      "\(showDifferences" 
	}
	"read-only" { 
	    if {${alpha::macos}} {
		lappend res                                     \
		  "\(${icn}checkOutÉ[icon::FromID 490]"         \
		  "\(${icn}refetchReadOnly[icon::FromID 491]"   \
		  "${icn}makeWritable[icon::FromID 492]"        \
		  "(-)"                                         \
		  "\(showDifferences"
	    } else {
		lappend res                                     \
		  "\(${icn}checkOutÉ[icon::FromID 490]"         \
		  "\(${icn}refetchReadOnly[icon::FromID 491]"   \
		  "\(${icn}makeWritable[icon::FromID 492]"      \
		  "(-)"                                         \
		  "\(showDifferences"
	    }
	}
	"mro" { 
	    lappend res                                         \
	      "\(${icn}checkOutÉ[icon::FromID 490]"             \
	      "\(${icn}fetchReadOnly[icon::FromID 491]"         \
	      "\(${icn}makeWritable[icon::FromID 492]"          \
	      "(-)"                                             \
	      "\(showDifferences"
	}
	"up-to-date" {
	    if {${alpha::macos}} {
		lappend res                                     \
		  "\(${icn}checkOutÉ[icon::FromID 490]"         \
		  "${icn}makeWritable[icon::FromID 492]"
	    } else {
		lappend res                                     \
		  "\(${icn}checkOutÉ[icon::FromID 490]"         \
		  "\(${icn}makeWritable[icon::FromID 492]"
	    }
	}
	"needs-patch" { 
	    lappend res                                         \
	      "\(${icn}refetchReadOnly[icon::FromID 491]"       \
	      "(-)"                                             \
	      "\(showDifferences" 
	}
	"" {
	    # No version control registered, or not possible to place under
	    # version control with current system
	}
	default {
	    # Not sure what happened, but rather than throw a full-blown
	    # error we'll inform the user via the menu.
	    lappend res "\($state"
	}
    }
    
    return $res
}

## 
 # -------------------------------------------------------------------------
 # 
 # "vcs::generalMenuItems" --
 # 
 # General utility function.
 # Most VC Systems will use this to build the bulk of their items
 # -------------------------------------------------------------------------
 ##

proc vcs::generalMenuItems {state} {

    set res [list]
    # Icon prefix
    set icn "/\x1e"

    switch -- $state {
	"no-vcs" { 
	    lappend res "${icn}addÉ[icon::FromID 491]"  
	}
	"checked-out" { 
	    lappend res                                 \
	      "${icn}checkInÉ[icon::FromID 490]"        \
	      "${icn}undoCheckout[icon::FromID 491]"    \
	      "\(${icn}makeWritable[icon::FromID 492]"  \
	      "(-)"                                     \
	      "showDifferences" 
	}
	"conflicts" { 
	    lappend res                                 \
	      "checkOutCleanÉ"                          \
	      "(-)"                                     \
	      "showDifferences" 
	}
	"read-only" { 
	    lappend res                                 \
	      "${icn}checkOutÉ[icon::FromID 490]"       \
	      "${icn}refetchReadOnly[icon::FromID 491]" \
	      "${icn}makeWritable[icon::FromID 492]"    \
	      "(-)"                                     \
	      "showDifferences"
	}
	"mro" { 
	    lappend res                                 \
	      "${icn}checkOutÉ[icon::FromID 490]"       \
	      "${icn}fetchReadOnly[icon::FromID 491]"   \
	      "\(${icn}makeWritable[icon::FromID 492]"  \
	      "(-)"                                     \
	      "showDifferences"
	}
	"up-to-date" {
	    lappend res                                 \
	      "${icn}checkOutÉ[icon::FromID 490]"       \
	      "${icn}makeWritable[icon::FromID 492]"
	}
	"needs-patch" { 
	    lappend res                                 \
	      "${icn}refetchReadOnly[icon::FromID 491]" \
	      "(-)"                                     \
	      "showDifferences" 
	}
	"" {
	    # No version control registered, or not possible to place under
	    # version control with current system
	}
	default {
	    # Not sure what happened, but rather than throw a full-blown
	    # error we'll inform the user via the menu.
	    lappend res "\($state"
	}
    }
    return $res
}

proc vcs::postBuildCM {} {
    
    global contextualMenumodeVars contextualMenu::cmMenuName
    
    if {!"$contextualMenumodeVars(vcsMenu)"} {
	return
    }
    # Dim "VCS" if window isn't a file, or if package isn't activated.
    # 'win::IsFile' automatically strips <2> window count.
    set isFile [win::IsFile [win::Current]]
    if {!$isFile || ![package::active versionControl]} {
	enableMenuItem $contextualMenu::cmMenuName "vcs" 0	    
    } else {
	enableMenuItem $contextualMenu::cmMenuName "vcs" 1
    }
}

proc vcs::menuProc {menuName itemName} {
    
    set w [win::Current]
    switch -- $itemName {
	"lock" {
	    # This just implements non-vcs connected lock/unlock actions
	    catch {win::setInfo $w read-only 1}
	}
	"unlock" {
	    # This just implements non-vcs connected lock/unlock actions
	    catch {win::setInfo $w read-only 0}
	    if {[win::getInfo $w read-only]} {
	        alertnote "The \"[win::Tail $w]\" window is still read-only;\
		  its \"writable\" status might be governed\
		  by a version control system, or you might not\
		  have the necessary permissions to change the status."
	    }
	}
	"updateFileset" {
	    set fset [vcs::getFileset [win::Current]]
	    updateAFileset $fset
	    status::msg "The '$fset' fileset has been updated."
	}
	"filesetPrefs" {
	    editAFileset [vcs::getFileset [win::Current]]
	}
	"showInFinder" {
	    win::showInFinder [win::Current]
	}
	default {
	    # add checkIn undoCheckout makeWritable checkOut
	    # refetchReadOnly fetchReadOnly
	    set w [win::StripCount [win::Current]]
	    vcs::call $itemName $w
	}
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Queries ×××× #
# 

proc vcs::getNamespace {} {
    variable system
    set system([vcs::getSystem])
}

proc vcs::getState {winName} {
    
    if {![win::IsFile $winName fileName]} {
	return ""
    } elseif {!$::alpha::macos} {
	# This is meaningless if we're not on MacOS.
	set state "no-vcs"
    } elseif {[catch {ckid::readResource $fileName ckid}]} {
	return "no-vcs"
    } elseif {$ckid(writable)} {
	set state "checked-out"
    } elseif {$ckid(mro)} {
	set state "mro"
    } else {
	set state "read-only"
    }
    vcs::optionalCall checkCompatibility $fileName
    return $state
}

proc vcs::getFileset {{winName ""}} {
    
    if {![string length $winName]} {
	set winName [win::Current]
    } 
    if {![win::IsFile $winName fileName]} {
	return ""
    } elseif {[string length [set fset [fileset::findForFile $fileName]]]} {
	return $fset
    } else {
	return ""
    }
}

proc vcs::getInfo {filename} {
    
    global alpha::macos
    
    if {![file exists $filename]} {
	alertnote "\"${filename}\" doesn't exist as a file."
	return
    } else {
	set q "No version control information is available for\
	  \r\r$filename\r\rWould you like information about the file\
	  as it exists on your local disk?"
	if {![askyesno $q]} {
	    return
	}
    }
    # Still here? Attempt to display file information.
    if {${alpha::macos} && \
      ([llength [info commands ::mac::getFilesInfo]] \
      || [auto_load ::mac::getFilesInfo])} {
	# Call the 'Mac Menu' procedure.
	if {![mac::getFilesInfo $filename]} {
	    set msg "No further information is available for\r\r$filename"
	} else {
	    mac::showFilesInfo 
	}
    } else {
	foreach {a v} [file attributes $filename] {
	    append msg "[string range $a 1 end] : $v\n"
	}
    }
    if {[info exists msg]} {
        alertnote $msg
    }
    return
}

proc vcs::getFilesetInfo {infoName} {
    return [fileset::getInformation [fileset::checkCurrent] $infoName]
}

# In old versions it wasn't clear if this proc took a fileset name or
# a window name as argument.  It takes a window name.
proc vcs::getSystem {{winName ""}} {
    
    if {![string length $winName]} {
	set winName [win::Current]
    } 
    if {![win::IsFile $winName fileName]} {
        error "Cancelled -- \"${winName}\" doesn't exist as a file."
    }
    set fset [vcs::getFileset $fileName]
    # If the fileset was found, return name of the version control system.
    if {$fset ne ""} {
	set sys [fileset::getInformation $fset "Version Control System"]
    } else {
	set sys "None"
    }
    # We also allow, at least for the moment, CVS version control to
    # be identified by the existence of the 'CVS' directory.  It would
    # be better if we could allow some sort of hook to be used here
    # in the future.
    if {$sys eq "None"} {
	if {[file isdir [file join [file dirname $fileName] CVS]]} {
	    set sys "Cvs"
	}
    }
    return $sys
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Misc Support Stuff ×××× #
# 

# This is called whenever the user changes the fileset information.
proc vcs::vcsSystemModified {fset value} {
    hook::callAll vcsSystemModified $value $fset
}

# Determine if we have a proc to use or not.
proc vcs::procOrDefault {what} {

    set ns [vcs::getNamespace]
    if {[llength [info commands ::${ns}::${what}]]} {
	return ::${ns}::${what}
    } else {
	return ::vcs::${what}
    }
}

# Only call if the vcs system provides the right procedure
# This implies the vcs system must be completely loaded.
proc vcs::optionalCall {what args} {

    set proc [vcs::getNamespace]::${what}
    if {[info commands $proc] != ""} {
	if {[catch {eval $proc $args} err]} {
	    status::msg $err
	}
	return $err
    }
    return ""
}

proc vcs::call {what args} {

    set ns [vcs::getNamespace]
    set proc [vcs::procOrDefault $what]
    if {[catch {eval [list $proc] $args} err]} {
	status::msg $err
    }
    return $err
}

proc vcs::syncLockStatus {name} {

    set fileReadOnly [expr {![file writable [win::StripCount $name]]}]
    getWinInfo winState
    if {$winState(read-only) != $fileReadOnly} {
	setWinInfo read-only $fileReadOnly
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Default VC Operations ×××× #
# 

proc vcs::manualUnlock {name} {
    vcs::call unlock $name
}

proc vcs::manualLock {name} {
    vcs::call lock $name
}

proc vcs::showDifferences {name} {
}

proc vcs::lock {name} {
    try {setWinInfo read-only 1}
}

proc vcs::unlock {name} {
    setWinInfo read-only 0
}

proc vcs::checkIn {name} {
}

proc vcs::checkOut {name} {
}

proc vcs::undoCheckout {name} {
}

proc vcs::refetchReadOnly {name} {
}

proc vcs::makeWritable {name} {
    
    if {$::alpha::macos} {ckid::setMRO $name}
    setWinInfo -w $name read-only 0
}

proc vcs::otherCommands {state} {
    # nothing by default
}

proc vcs::filesetPrefs {args} {
    
    if {![llength [winNames]]} {
        alertnote "This item requires an open window."
	return 0
    } elseif {![string length [set fset [vcs::getFileset]]]} {
	alertnote "\'\"[win::CurrentTail]\" is not part of a\
	  currently recognized fileset."
	return 0
    } else {
	editAFileset $fset
	return 1
    }
}

proc vcs::versionControlPrefs {args} {
    prefs::dialogs::packagePrefs vcs
}

proc vcs::versionControlHelp {args} {
    package::helpWindow versionControl
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× 'ckid' resource handling ×××× #
# 

if {!${alpha::macos}} { return }

namespace eval vcs::ckid {}

proc vcs::ckid::readResource {name aa} {
    global alpha::macos
    
    upvar 1 $aa a
    
    # Bug (#1020224) in Tclresource: workaround is to remove the file permission. is fixed. 
    # This is fixed in Tclresource 1.1.1
    if {${alpha::macos} == 2 && [alpha::package vcompare [package require resource] 1.1] <= 0} {
	set resid [resource open $name]
    } else {
	set resid [resource open $name r]
    }

    if {[catch {set a(id) [lindex [resource list ckid $resid] 0]}]} {
	resource close $resid
        error "Couldn't find ckid resource"
    } elseif {[catch {set ckid [resource read ckid $a(id) $resid]}]} {
	resource close $resid
        error "Couldn't read ckid resource"
    } 
    resource close $resid
    
    if {[verifyCheckSum $ckid]} {
	binary scan $ckid IISa* a(checkSum) a(location) a(version) ckid
	binary scan $ckid Scca* a(writable) a(branch) a(mro) ckid
	binary scan $ckid SSa* a(history) a(historyLen) ckid
	binary scan $ckid IIa* a(dateTime) a(modDate) ckid
	binary scan $ckid IISSSa* a(pidA) a(pidB) a(userID) a(fileID) a(revID) ckid
	binary scan $ckid ca* count ckid
	binary scan $ckid a${count}ca* a(path) EOS ckid
	binary scan $ckid ca* count ckid
	binary scan $ckid a${count}ca* a(user) EOS ckid
	binary scan $ckid ca* count ckid
	binary scan $ckid a${count}ca* a(revision) EOS ckid
	binary scan $ckid ca* count ckid
	binary scan $ckid a${count}ca* a(filename) EOS ckid
	binary scan $ckid ca* count ckid
	binary scan $ckid a${count}ca* a(task) EOS ckid
	# sneaky bastards! comment is a wide string
	binary scan $ckid Sa* count ckid
	binary scan $ckid a${count}ca* a(comment) EOS ckid
    } else {
	# We must rise an error in case of invalid checksum. All 
	# the callers are in a [catch] and depend on its value.
	error "Invalid checksum in ckid resource"
    }
    
    return
}

proc vcs::ckid::writeResource {name aa} {
    global alpha::macos

    upvar 1 $aa a
    
    set ckid ""
    append ckid [binary format IS $a(location) $a(version)]
    append ckid [binary format Scc $a(writable) $a(branch) $a(mro)]
    append ckid [binary format SS $a(history) $a(historyLen)]
    append ckid [binary format II $a(dateTime) $a(modDate)]
    append ckid [binary format IISSS $a(pidA) $a(pidB) $a(userID) $a(fileID) $a(revID)]
    append ckid [binary format ca*x [string length $a(path)] $a(path)]
    append ckid [binary format ca*x [string length $a(user)] $a(user)]
    append ckid [binary format ca*x [string length $a(revision)] $a(revision)]
    append ckid [binary format ca*x [string length $a(filename)] $a(filename)]
    append ckid [binary format ca*x [string length $a(task)] $a(task)]
    # sneaky bastards! comment is a wide string
    append ckid [binary format Sa*x [string length $a(comment)] $a(comment)]
    
    set ckid [binary format Ia* [calculateCheckSum $ckid] $ckid]
    
    set origmtime [file mtime $name]
    
    # Bug (#1020224) in Tclresource: workaround is to remove the file permission.
    # This is fixed in Tclresource 1.1.1
    if {${alpha::macos} == 2 && [alpha::package vcompare [package require resource] 1.1] <= 0} {
	set resid [resource open $name]
    } else {
	set resid [resource open $name w]
    }
    
    if {[string is integer $a(id)]} {
	set caught [catch {resource write -id $a(id) -name "Alpha" -file $resid -force ckid $ckid}]
    } else {
	set caught [catch {resource write -id 128 -name $a(id) -file $resid -force ckid $ckid}]
    }
    resource close $resid
    file mtime $name $origmtime
    # Call [error] only after the resource map has been closed
    if {$caught} {
        error "Coudn't write ckid resource"
    } 
    
    return
}

proc vcs::ckid::verifyCheckSum {ckid} {

    binary scan $ckid Ia* checkSum remainder
    
    return [expr {[calculateCheckSum $remainder] == $checkSum}]
}

proc vcs::ckid::calculateCheckSum {remainder} {

    set sum 0
    set len [expr {[string length $remainder] / 4}]
    for {set i 0} {$i < $len} {incr i} {
	binary scan $remainder Ia* num remainder
	incr sum $num
    }
    
    return $sum
}

proc vcs::ckid::setMRO {name} {

    if {[catch {readResource $name ckid}]} {
	return
    } elseif {!$ckid(writable)} {
	set ckid(mro) 1
    } 
    writeResource $name ckid
}

proc vcs::ckid::getInfo {name} {

    if {[catch {readResource $name ckid} err]} {
	alert -t stop -c "" -o "" "Unable to get version control information" $err
    }
    
    if {$ckid(writable)} {
	set status "Checked out by $ckid(user) at [mtime $ckid(dateTime)]"
    } elseif {$ckid(mro)} {
	set status "Modify-Read-Only by $ckid(user) at [mtime $ckid(modDate)]"
    } else {
	set status "Checked in by $ckid(user) at [mtime $ckid(dateTime)]"
    }
    
    dialog::make -title $ckid(id) \
      [list [file tail $name] \
      [list file "Local Path:" [file dirname $name]] \
      [list static "Status:" $status] \
      [list static "VCS Path:" $ckid(path)] \
      ]
}

proc vcs::ckid::checkCompatibility {name vcsNames} {

    if {![catch {readResource $name ckid} err]} {
	if {[string length $ckid(id)] > 0 
	&& [lsearch -exact $vcsNames $ckid(id)] < 0} {
	    beep
	    status::msg "Current VCS system, [vcs::getSystem],\
	      does not match 'ckid' creator, $ckid(id)"
	} 
    }    
}

# ===========================================================================
# 
# .