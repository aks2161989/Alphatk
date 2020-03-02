## -*-Tcl-*-
 # ###################################################################
 #  AlphaVOODOO - integrates Alpha with VOODOO
 # 
 #  FILE: "voodooEvents.tcl"
 #                                    created: 6/27/97 {10:48:05 pm} 
 #                                last update: 12/22/2004 {10:58:47 AM} 
 #                                    version: 2.0.1
 #  Author: Jonathan Guyer
 #  E-mail: <jguyer@his.com>
 #     www: <http://www.his.com/jguyer/>
 #  
 # 
 #  Copyright (C) 1997-2001  Jonathan Guyer
 #  
 #  This program is free software; you can redistribute it and/or modify
 #  it under the terms of the GNU General Public License as published by
 #  the Free Software Foundation; either version 2 of the License, or
 #  (at your option) any later version.
 #  
 #  This program is distributed in the hope that it will be useful,
 #  but WITHOUT ANY WARRANTY; without even the implied warranty of
 #  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 #  GNU General Public License for more details.
 #  
 #  You should have received a copy of the GNU General Public License
 #  along with this program; if not, write to the Free Software
 #  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 # ###################################################################
 ##

namespace eval voodoo {}
namespace eval voodoo::projects {}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::window" --
 # 
 #  Execute $cmd on the topmost window, if eligible
 # -------------------------------------------------------------------------
 ##
proc voodoo::window {cmd} {
    voodoo::isConnected 1
    set window [list [lindex [winNames -f] 0]]
    $cmd [voodoo::eligibleFiles $window]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::allWindows" --
 # 
 #  Execute $cmd on all eligible windows
 # -------------------------------------------------------------------------
 ##
proc voodoo::allWindows {cmd} {
    voodoo::isConnected 1
    $cmd [voodoo::eligibleFiles [winNames -f]]
}	

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::fileset" --
 # 
 #  Execute $cmd on eligible files of current fileset
 # -------------------------------------------------------------------------
 ##
proc voodoo::fileset {cmd} {
    global currFileSet
    
    # NOTE: This executes $cmd on all files in the current 
    # fileset, regardless of whether they are are openable by Alpha.
    # If this is not the behavior you want, change 'getFilesInSet'
    # to 'getFileSet' and then only 'TEXT' files will be acted upon.
    
    voodoo::isConnected 1
    $cmd [voodoo::eligibleFiles [getFilesInSet $currFileSet]]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::eligibleFiles" --
 # 
 #  Return the subset of $files which is elibible for action by
 #  VOODOO, i.e., those which have a corresponding physical file
 # -------------------------------------------------------------------------
 ##
proc voodoo::eligibleFiles {files} {
    upvar cmd command
    
    set eligibleFiles ""
    
    # If we're storing, see if user wants to save any
    # dirty windows first
    if {$command == "voodoo::store"} {
	foreach window [winNames -f] {
	    getWinInfo -w $window winInfo
	    if {$winInfo(dirty)} {
		
		# Make sure $window is actually in $files.
		# We don't care about other dirty windows.
		
		# First try an exact search on filename.
		if {[set index [lsearch -exact $files $window]] < 0} {
		    # Clip off the window index...
		    regsub { <[0-9]+>$} $window {} clipWindow
		    # ...and try again with 
		    set index [lsearch -regexp $files "[quote::Regfind $clipWindow]\( <\[0-9\]+>\)?$"]
		}
		
		if {$index >= 0} {
		    switch [askyesno -c \
		      "[file tail $window] has unsaved changes. \
		      \rDo you wish to save before storing?"] {
			
			"yes" {
			    bringToFront $window
			    set saved [save]
			    if {[string length $saved]} {
				set files \
				  [lreplace $files $index $index $saved]
			    }
			}
			"cancel" {return}
		    }
		}
	    }
	}
    }
    
    foreach file $files {
	
	# See if there's actually a physical file associated with 
	# $file. We discard windows internal to Alpha because
	# they're meaningless in the context of VOODOO
	
	if {[file dirname $file] != ""} {
	    if {[file exists $file] \
	      ||	[expr [regsub { <[0-9]+>$} $file {} file] \
	      &&	[file exists $file]]} {
		# If $file doesn't exactly exist, clip off any window 
		# index and try again. We don't do this first, as
		# the index suffix may actually be part of the
		# window name (bad idea, but possible).  
		# There appears to be no reliable way
		# to associate a window with a file, even though Alpha
		# knows
		
		lappend eligibleFiles $file
	    }
	}
    }
    
    set eligibleFiles [lunique $eligibleFiles]
    
    if {[llength $eligibleFiles] == 0} {
	if {[llength $files] == 1} {
	    error "$files is not eligible for VOODOO"
	} else {
	    error "None of $files are eligible for VOODOO"
	}
    }
    
    return $eligibleFiles
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::try" --
 # 
 #  Try to execute $cmd on $files (if present), connecting to VOODOO
 #  if necessary and displaying error messages as appropriate
 # -------------------------------------------------------------------------
 ##
proc voodoo::try {script args} {	
    watchCursor
    
    set opts(-preError) {}
    set opts(-postError) {}
    getOpts {preError postError}
    
    set onError {
	{12[0-9][0-9][0-9]} {
	    set errorCode [list VOODOO $errorCode $errorMsg]
	    error::display
	}
	NONE {
	    if {$errorMsg != "cancel"} {
		error::display
	    } 
	}
    }
    set onError [concat $opts(-preError) $onError $opts(-postError)]
    
    return [try::level 2 $script -onError $onError -regexp]
}

# ×××× Projects ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::projects" --
 # 
 #  Return a list of known projects
 #  Generate this on the fly, to avoid list of projects ever being
 #  out of synch with the actual projects
 # -------------------------------------------------------------------------
 ##
proc voodoo::projects {} {
    set projects ""
    
    foreach project [info globals "voodoo::projects::*"] {
	global $project
	lappend projects [set ${project}(projectName)]
    }
    
    return [lsort $projects]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::chooseProject" --
 # 
 #  Allow user to select a new VOODOO project using an SFGetBox.
 # -------------------------------------------------------------------------
 ##
proc voodoo::chooseProject {} {
    global voodooProject voodoo
    
    if {[set path [voodoo::path]] == ""} {
	return
    }
    
    set project [file tail [file rootname $path]]
    set project [voodoo::newProject $project]
    
    voodoo::changeProject $project 0
    
    set voodooProject(path) $path
    
    voodoo::settings 1
    
    set voodoo(projects) [voodoo::projects]
}

proc voodoo::projectFromName {name} {
    set result ""
    
    foreach project [info globals voodoo::projects::*] {
	global $project
	
	if {[set ${project}(projectName)] == $name} {
	    set result $project
	    break
	} 
    }
    
    return $result
}

proc voodoo::newProject {name} {
    if {$name != [set newname [voodoo::legalizeName $name]]} {
	set name [voodoo::chooseName $newname]		
    } 
    
    set projects [info globals voodoo::projects::*]
    for {set i 0} {[lsearch -exact $projects "voodoo::projects::$i"] >= 0} {incr i} {}
    
    global voodoo::projects::$i
    set voodoo::projects::${i}(projectName) $name
    
    return $name
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::changeProject" --
 # 
 #  Change the active project to $project.
 #  Connect to it if desired.
 # -------------------------------------------------------------------------
 ##
proc voodoo::changeProject {project {connect 1}} {
    global voodooCurrent voodooProject voodoo
    
    if {[info exists voodooProject(projectName)]
    &&	$project != $voodooProject(projectName)} {
	voodoo::disconnect
    }	
    
    trace vdelete voodooProject w voodoo::synchronize
    voodoo::defaultSettings
    set voodoo(actual) [voodoo::projectFromName $project]
    uplevel \#0 [list voodoo::popVars $voodoo(actual)]
    trace variable voodooProject w voodoo::synchronize
    set voodooCurrent $project
    
    prefs::modified $voodoo(actual)
    
    if {$connect} {
	voodoo::connect
    } 
}
## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::legalizeName" --
 # 
 #  Ensure that 'name' is unique and can be displayed in a menu.
 # -------------------------------------------------------------------------
 ##
proc voodoo::legalizeName {name} {
    # squish out the curly brackets
    regsub -all {[\{\}]} $name "" name
    
    if {[regexp {^\s*$} $name]} {
	# name can't just be whitespace
	set result [voodoo::legalizeName "name"]
    } else {
	# see if $name already has been numbered
	# try unnumbered version first
	regexp {(.*)\s+\[[0-9]+\]$} $name blah name
	set number ""
	set projects [voodoo::projects]
	if {[lsearch -exact $projects $name] >= 0} {
	    set i 2
	    while {[lsearch -exact $projects "$name \[$i\]"] >= 0} {
		incr i
	    }
	    set number " \[$i\]"
	}
	
	set result "$name$number"
    }
    return $result
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::isConnected" --
 # 
 #  Returns 1 if currently connected to the project, 0 otherwise
 # -------------------------------------------------------------------------
 ##
proc voodoo::isConnected {{tryConnect 0}} {
    global errorCode voodooProject
    
    if {![file exists $voodooProject(path)]} {
	if {[info exists voodooProject(projectName)]
	&&  $voodooProject(projectName) != ""} {
	    set msg "The project file \"$voodooProject(projectName)\" \
	      does not exist. Check your project settings."
	    
	    error $msg "" [list VOODOO PROJECT $msg]			
	} else {
	    return 0
	}
    }
    
    # We make an innocuous call to get the variants of the current project. 
    # We don't care about the result, it's just a way to make sure that we're 
    # connected to the project.
    
    # In the event of error "NONE" with status::msg "Unable to find process" 
    # (VOODOO isn't running) or error 12001, "The VOODOO project could 
    # not be found.", try to launch VOODOO and connect to the project 
    try {
	if {$voodooProject(alis) == ""} {
	    if {$tryConnect} {
		set result [voodoo::connect]
	    } else {
		set result 0
	    }
	} else {			
	    voodoo::getVariants
	    set result 1
	}
    } -onError {
	"Unable to find process" -
	"The VOODOO project could not be found." {
	    if {$tryConnect} {
		set result [voodoo::connect]
	    } else {
		set result 0
	    }
	}
	default error::rethrow
    } -message
    
    return $result
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::disconnect" --
 # 
 #  Disconnect from the current project
 # -------------------------------------------------------------------------
 ##
proc voodoo::disconnect {} {
    global errorCode
    
    ::try {
	voodoo::closeProject
    } -onError {
	"Unable to find process" {}
	default error::rethrow
    } -message
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::onlyInProject" --
 # 
 #  Return the subset of $files which the current user is eligible to
 #  manipulate
 #  
 # -------------------------------------------------------------------------
 ##
proc voodoo::onlyInProject {files} {
    set status [voodoo::status $files -nodisplay]
    
    set i -1
    set inProject ""
    foreach file $files {
	switch [lindex $status [incr i]] {
	    "unlocked" -
	    "reserved" {
		lappend inProject $file
	    }
	}
    }
    
    return $inProject
}

# ×××× Settings ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::defaultSettings" --
 # 
 #  Assign default settings for $project.
 # -------------------------------------------------------------------------
 ##
proc voodoo::defaultSettings {} {
    global voodooProject
    
    set voodooProject(path)		""
    set voodooProject(alis)		""
    set voodooProject(lockFiles)	0
    set voodooProject(lockNodes)	1
    set voodooProject(user)		[tclAE::build::userName]
    set voodooProject(showLogon)	0
    set voodooProject(savePass)		0
    set voodooProject(useFilter)	0
    set voodooProject(variants)		""
    set voodooProject(selectedVariants) ""
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::modernizeProjects" --
 # 
 #  Find any old-style voodoo project settings (from 1.0b*) and
 #  render them in the new format
 # -------------------------------------------------------------------------
 ##
proc voodoo::modernizeProjects {} {
    global voodoo
    
    set oldProjects [info globals "voodoo:*"]
    set newProjects [info globals "voodoo::projects::*"]
    set oldProjects [eval lremove [list $oldProjects] $newProjects]
    
    if {[llength $oldProjects] > 0} {
	alertnote "Updating archaic VOODOO project settings"
	
	foreach project $oldProjects {
	    regsub "voodoo:" $project "" projectName
	    set newProjectName [voodoo::projectFromName [voodoo::newProject $projectName]]
	    
	    upvar \#0 $project oldProject
	    upvar \#0 $newProjectName newProject
	    
	    foreach item {path lockFiles lockNodes user showLogon savePass \
	      useFilter variants selectedVariants} {
		if {[info exists oldProject($item)]} {
		    set newProject($item) $oldProject($item)
		} 
	    }
	    
	    prefs::removeArray $project
	    unset oldProject
	    
	    prefs::modified $newProjectName
	}
	
	set voodoo(projects) [voodoo::projects]
    }
    
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::pushVars" --
 # 
 #  Copy voodoo settings to $to
 # -------------------------------------------------------------------------
 ##
proc voodoo::pushVars {to} {
    global voodooProject
    
    upvar 1 $to storage
    foreach name [array names voodooProject] {
	set storage($name) $voodooProject($name)
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::popVars" --
 # 
 #  Assign voodoo settings for current project to saved values from $from
 # -------------------------------------------------------------------------
 ##
proc voodoo::popVars {from} {
    global voodooProject
    
    upvar 1 $from storage
    
    foreach name [array names storage] {
	set voodooProject($name) $storage($name)
    }
}

# ×××× VOODOO AppleEvents ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::openProject" --
 # 
 #  Open the current project, using the supplied password
 # -------------------------------------------------------------------------
 ##
proc voodoo::openProject {password} {
    global voodooProject
    
    set voodooProject(alis) [tclAE::build::alis $voodooProject(path)]
    
    app::launchBack Vodo
    
    tclAE::build::throw 'Vodo' Vodo odoc \
      ---- $voodooProject(alis)  \
      kNam [tclAE::build::TEXT $voodooProject(user)] \
      kPwd [tclAE::build::TEXT $password]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::closeProject" --
 # 
 #  Close the current project
 # -------------------------------------------------------------------------
 ##
proc voodoo::closeProject {} {
    global voodooProject
    
    if {$voodooProject(alis) != ""} {
	# an error 12001 is generated if the project isn't open,
	# but we're closing it anyway, so who cares?
	voodoo::try {
	    tclAE::build::throw 'Vodo' Vodo clos ---- $voodooProject(alis)
	} -preError {
	    12001 {}
	} 		
	set voodooProject(alis) ""
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::add" --
 # 
 #  Add $files to the current project
 # -------------------------------------------------------------------------
 ##
proc voodoo::add {{files ""}} {
    global voodooProject
    
    voodoo::enterDesignMode
    
    set addDesc [tclAE::build::resultDesc 'Vodo' Vodo VoAd \
      ---- $voodooProject(alis) \
      kFil [tclAE::build::List $files -as alis] \
      ]
    
    set adds [voodoo::listFromListDesc $addDesc]
    tclAE::disposeDesc $addDesc
    
    voodoo::displayResult $files $adds {* Add *}
    
    voodoo::leaveDesignMode
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::store" --
 # 
 #  Store $files in the current VOODOO project
 # -------------------------------------------------------------------------
 ##
proc voodoo::store {{files ""}} {
    global voodoo voodooProject errorCode
    
    if {$voodoo(dialog)} {
	app::launchFore Vodo
    }
    
    set alis [tclAE::build::List $files -as alis]
    
    voodoo::filter
    
    tclAE::build::throw 'Vodo' Vodo VoSt \
      ---- $voodooProject(alis) \
      kFil $alis \
      kUNd [tclAE::build::bool $voodooProject(lockNodes)] \
      kLFl [tclAE::build::bool $voodooProject(lockFiles)] \
      kDia [tclAE::build::bool $voodoo(dialog)]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::status" --
 # 
 #  Determine the locking status of $files
 # -------------------------------------------------------------------------
 ##
proc voodoo::status {{files ""} args} {
    global voodooProject
    
    set opts(-nodisplay) 0
    getOpts
    
    voodoo::filter
    
    set statusDesc [tclAE::build::resultDesc 'Vodo' Vodo VoGL \
      ---- $voodooProject(alis) \
      kFil [tclAE::build::List $files -as alis] \
      ]
    
    set status [voodoo::listFromListDesc $statusDesc]
    tclAE::disposeDesc $statusDesc
    
    if {!$opts(-nodisplay)} {
	voodoo::displayResult $files $status {* Locking Status *}
    }
    
    return $status
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::compare" --
 # 
 #  Compare $file to it's most recent archived version in the
 #  current project
 # -------------------------------------------------------------------------
 ##
proc voodoo::compare {{file ""}} {
    global voodooProject
    
    set minVersion "1.8.1"
    
    if {![catch {set version [file::version -creator Vodo]}]} {
	if {[alpha::package vcompare $version $minVersion] >= 0} {
	    voodoo::filter
	    
	    # Do this first so errors don't clutter up the replyHandler stack
	    set alis [tclAE::build::alis [lindex $file 0]]
	    
	    # Reply from VOODOO is queued for processing by handleReply
	    currentReplyHandler voodoo::handleDiffReply
	    
	    # tell application "VOODOO" to compare alias "voodooProject" Â
	    #   file alias "file" using application "Alpha"
	    
	    tclAE::send -p -q 'Vodo' Vodo VoCp \
	      ---- $voodooProject(alis) \
	      kFil $alis \
	      kCAp type(ALFA)
	} else {
	    alertnote "VOODOO $minVersion\
	      is the minimum version that will perform file comparison \
	      with Alpha"
	}
    } 
    
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::enterDesignMode" --
 # 
 #  Just like it says
 # -------------------------------------------------------------------------
 ##
proc voodoo::enterDesignMode {} {
	global voodooProject
	
	# tell application "VOODOO" to enter design mode alias "voodooProject"
	
	tclAE::build::throw 'Vodo' Vodo VoED ---- $voodooProject(alis)
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::leaveDesignMode" --
 # 
 #  Leave design mode, optionally presenting a dialog (in VOODOO) to
 #  assign a revision name and comment
 # -------------------------------------------------------------------------
 ##
proc voodoo::leaveDesignMode {} {
    global voodoo voodooProject
    
    if {$voodoo(dialog)} {
	app::launchFore Vodo
    } 
    
    # tell application "VOODOO" to leave design mode alias "voodooProject" Â
    #   comment ÒFrom AlphaÓ with(out) dialog
    
    tclAE::build::throw 'Vodo' Vodo VoLD \
      ---- $voodooProject(alis) \
      kCom [tclAE::build::TEXT "From Alpha"] \
      kDia [tclAE::build::bool $voodoo(dialog)]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::fetch" --
 # 
 #  Fetch $files from the current project
 # -------------------------------------------------------------------------
 ##
proc voodoo::fetch {{files ""}} {
    global voodoo voodooProject
    
    # We'll get an error if we attempt to retrieve files that
    # are not in the project
    set files [voodoo::onlyInProject $files]
    
    if {$voodoo(dialog)} {
	app::launchFore Vodo
    } 
    
    # Replace both older and newer files by default.
    # The user can override these options by holding down
    # the <option> key to obtain a VOODOO dialog.
    tclAE::build::throw 'Vodo' Vodo VoFe \
      ---- $voodooProject(alis) \
      kFil [tclAE::build::List $files -as alis] \
      kLNd [tclAE::build::bool $voodooProject(lockNodes)] \
      kUFl [tclAE::build::bool $voodooProject(lockFiles)] \
      kRpO [tclAE::build::bool 1] \
      kRpN [tclAE::build::bool 1] \
      kDia [tclAE::build::bool $voodoo(dialog)]
    
    # VoFe is supposed to return a kRCL, but it doesn't seem to
    
    # Refresh the members of $files that were already open
    foreach file $files {
	foreach win [file::hasOpenWindows $file] {
	    bringToFront $win
	    revert
	    setWinInfo read-only 0
	}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::fetchReadOnly" --
 # 
 #  Fetch read-only copies of $files from the current project
 # -------------------------------------------------------------------------
 ##
proc voodoo::fetchReadOnly {{files ""}} {
    global voodoo voodooProject
    
    # We'll get an error if we attempt to retrieve files that
    # are not in the project
    set files [voodoo::onlyInProject $files]
    
    if {$voodoo(dialog)} {
	app::launchFore Vodo
    } 
    
    # Replace both older and newer files by default.
    # The user can override these options by holding down
    # the <option> key to obtain a VOODOO dialog.
    tclAE::build::throw 'Vodo' Vodo VoGe \
      ---- $voodooProject(alis) \
      kFil [tclAE::build::List $files -as alis] \
      kRpO [tclAE::build::bool 1] \
      kRpN [tclAE::build::bool 1] \
      kDia [tclAE::build::bool $voodoo(dialog)]
    
    # VoGe is supposed to return a kRCL, but it doesn't seem to.
    
    # Refresh and lock the members of $files that were already open
    foreach file $files {
	foreach win [file::hasOpenWindows $file] {
	    bringToFront $win
	    revert
	    setWinInfo read-only 1
	}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::filter" --
 # 
 #  Tell VOODOO to act only on the specified variants
 # -------------------------------------------------------------------------
 ##
proc voodoo::filter {} {	
    global voodooProject
    
    if {$voodooProject(useFilter)} {
	tclAE::build::throw 'Vodo' Vodo VoFi \
	  ---- $voodooProject(alis) \
	  kVar [tclAE::build::List $voodooProject(selectedVariants) -as TEXT]
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::getVariants" --
 # 
 #  Obtain a list of variants from VOODOO
 # -------------------------------------------------------------------------
 ##
proc voodoo::getVariants {} {
    global voodooProject
    
    # ask VOODOO for a list of variants
    set voodooProject(variants) \
      [tclAE::build::resultData 'Vodo' Vodo VoGV ---- $voodooProject(alis)]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::listFromListDesc" --
 # 
 #  Convert list of enumerators into list of equivalent strings
 # -------------------------------------------------------------------------
 ##
proc voodoo::listFromListDesc {listDesc} {
    set count [tclAE::countItems $listDesc]
    
    set resultList {}
    
    for {set i 0} {$i < $count} {incr i} {
	lappend resultList [tclAE::getNthData $listDesc $i TEXT]
    }
    
    return $resultList
}

namespace eval voodoo::coerce {}

# ××××   kLSt - locking status codes ××××

# 'eNIP'
# 'eUnl'
# 'eLSe'
# 'eLOt'

# ××××   kRCA - add result codes ××××

# 'eOK '
# 'eFnf'
# 'eInP'

# ××××   kRCL - store or fetch result codes ××××

#  (contrary to VOODOO's aete resource, these codes are not actually 
#  returned)

# 'eOK ', 'eNIP', and 'eLOt' already defined

# 'eNoR'

# ××××   kRCC - comparison result codes ××××

# 'eEqu'
# 'eDif'
# 'eNa '


proc voodoo::coerce::enum>TEXT {typeCode data toType resultDesc} {
    binary scan $data a4 enum
    
    switch $enum {
	"eNIP" {
	    set result "not in project"
	}
	"eUnl" {
	    set result "unlocked"
	}
	"eLSe" {
	    set result "reserved"
	}
	"eLOt" {
	    set result "locked by another user"
	}
	
	"eOK " {
	    set result "OK"
	}
	"eFnf" {
	    set result "file not found"
	}
	"eInP" {
	    set result "already in project"
	}
	
	"eNoR" {
	    set result "no rights"
	}
	
	"eEqu" {
	    set result "equal"
	}
	"eDif" {
	    set result "different"
	}
	"eNa " {
	    set result "n.a."
	}
	
	default {
	    error::throwOSerr -1700
	}
	
    }
    
    tclAE::replaceDescData $resultDesc TEXT $result
}

