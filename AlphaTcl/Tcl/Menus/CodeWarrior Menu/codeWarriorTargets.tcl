# -*-Tcl-*- (nowrap)
# 
# File: codeWarriorTargets.tcl
# 							Last modification : 2005-03-26 19:04:34
# 
# Description : this file is part of the CodeWarrior Menu for Alpha.
# It contains the procedures related to targets management.

namespace eval cw {}



proc cw::selectProject {} {
	watchCursor
	if {![cw::isProjectOpen]} {return} 
	cw::getProjectsList
	cw::selectPartDialog Project
}


proc cw::selectTarget {} {
	watchCursor
	if {![cw::projectToFront]} {return} 
	cw::getTargetsList
	cw::selectPartDialog Target
}


proc cw::getProjectsList {} {
	global cw_params
	status::msg "Looking for projects..."
	set aedesc [tclAE::send -t 500000 -r $cw_params(cwsig) core getd ---- [tclAE::build::propertyObject pnam \
	  [tclAE::build::indexObject PRJD "abso('all ')"]]]
	if {![catch {tclAE::getKeyData $aedesc ---- } res]} {
		set cw_params(Projectlist) $res
	} else {
		set cw_params(Projectlist) ""
	}
	status::msg ""
	return $cw_params(Projectlist)
}


proc cw::getTargetsList {} {
	global cw_params
	status::msg "Looking for targets..."
	set aedesc [tclAE::send -t 500000 -r $cw_params(cwsig) core getd ---- [tclAE::build::propertyObject pnam \
	  [tclAE::build::indexObject TRGT "abso('all ')" [tclAE::build::indexObject PRJD 1]]]]
	if {![catch {tclAE::getKeyData $aedesc ---- } res]} {
		set cw_params(Targetlist) $res
	} else {
		set cw_params(Targetlist) ""
	}
	status::msg ""
	return $cw_params(Targetlist)
}


proc cw::setTarget {trgt} {
	global cw_params
	if {[catch {tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) STrg \
	  ---- [tclAE::build::TEXT $trgt]} res]} {
		cw::errors $res
		return 
	} else {
		status::msg "Current target set to '$trgt'"
	}
}


proc cw::setProject {proj} {
	global cw_params
	tclAE::send -t 500000 $cw_params(cwsig) misc slct ---- [tclAE::build::winByName $proj]
	status::msg "Current project set to '$proj'"
}


# Return the full path of the current project
proc cw::currentProject {} {
	global cw_params
	set cw_params(currProjectPath) ""
	set aedesc [tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) GetP]
	if {![cw::checkErrorInReply $aedesc]} {
		set cw_params(currProjectPath) [tclAE::getKeyData $aedesc ---- TEXT]
	} else {
		error "Couldn't get location of current project"
	}
	return $cw_params(currProjectPath)
}


# Return the name of the current target
proc cw::currentTarget {} {
	global cw_params
	set cw_params(currTarget) ""
	set aedesc [tclAE::send -t 500000 -r $cw_params(cwsig) core getd ---- [tclAE::build::propertyObject CURT \
	  [tclAE::build::indexObject PRJD 1]]]
	if {![catch {tclAE::getKeyDesc $aedesc ---- } theobj] && \
	  ![catch {tclAE::getKeyData $theobj seld} res]} {
		set cw_params(currTarget) $res
	} 
	return $cw_params(currTarget)
}


# Bring the current project window to the front (amongst CW windows)
# without switching to CW.
proc cw::projectToFront {} {
	global cw_params
	if {![cw::isProjectOpen]} {return 0} 
	tclAE::send -t 500000 $cw_params(cwsig) misc slct ---- [tclAE::build::winByName $cw_params(currProjectName)]
	return 1
}


proc cw::addCurrentFile {} {
	global cw_params
	set fname [win::StripCount [win::Current]]
	watchCursor
	if {[cw::isInProject $fname 0]} {
		status::msg "File '[file tail $fname]' already in current project"
		return
	} 
	set res [tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) AddF \
	  ---- [tclAE::build::alis $fname]]
	if {![cw::checkErrorInReply $res]} {
		status::msg "File '[file tail $fname]' added to current project"
	} 
}


proc cw::removeCurrentFile {} {
	global cw_params
	set fname [win::StripCount [win::Current]]
	watchCursor
	if {![cw::isInProject $fname 0]} {
		status::msg "File '[file tail $fname]' not in current project"
		return
	} 
	set res [tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) RemF \
	  ---- [tclAE::build::alis $fname]]
	if {![cw::checkErrorInReply $res]} {
		status::msg "File '[file tail $fname]' removed current project"
	} 
}


# Outrageous! CW sometimes returns paths mixing "/" and ":" 
# like for instance "hd/usr:lib:crt1.o".
# Note also that this proc returns the CodeWarrior index of the file. This
# is a 1-based index (not 0-based as in Tcl list procs). This is useful to
# build objects such as: 
#     [tclAE::build::indexObject SRCF $fileidx $targetobj]
proc cw::findFileIndex {itemsList name} {
	set fileidx [lsearch -regexp $itemsList "\[/:\][file tail $name]"]
	return [expr $fileidx + 1]
}


proc cw::findTargetIndex {targ} {
	global cw_params
	cw::getTargetsList
	# CW indices are 1-based
	return [expr [lsearch $cw_params(Targetlist) $targ] + 1]
}


proc cw::findProjectIndex {proj} {
	# CW indices are 1-based
	return [expr [lsearch [cw::getProjectsList] $proj] + 1]
}


proc cw::setFlagInProject {{name ""}} {
	global cw_params cwmodeVars
	if {![cw::isProjectOpen 0]} {
		alertnote "The new value couldn't be sent to CodeWarrior"
		return
	}
	
	cw::setPanelKeys PanelKey
	set panel [lindex $PanelKey($name) 0]
	set key [lindex $PanelKey($name) 1]
	
	if {$name == "saveOpenFilesBeforeBuild" && ![cw::versionGreaterThanFour]} {return}
	# Possible values for buildBeforeRunning: 'BXb1' (always), 'BXb2' (ask) ou 'BXb3' (never).
	if {$name == "buildBeforeRunning"} {
		tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) Pref \
		  PNam [tclAE::build::TEXT $panel] \
		  PRec "{'$key':[expr {$cwmodeVars(buildBeforeRunning) ? "'BXb1'" : "'BXb3'"}]}"
		return
	} 
	
	tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) Pref \
	  PNam [tclAE::build::TEXT $panel] \
	  PRec "{'$key':[tclAE::build::bool $cwmodeVars($name)]}"
}


proc cw::syncFlagsWithProject {} {
	global cwmodeVars cw_params
	status::msg "Synchronizing flags..." 
	if {![cw::isProjectOpen 0]} {return}
	
	cw::setPanelKeys PanelKey
	foreach flag [array names PanelKey] {
		set key [lindex $PanelKey($flag) 1]
		set res [tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) Gref \
		  PNam [tclAE::build::TEXT [lindex $PanelKey($flag) 0]] \
		  PRec [tclAE::build::propertyObject $key]]
		set theobj [tclAE::getKeyDesc $res ---- ]
		if {![catch {tclAE::getKeyData $theobj $key bool} res]} {
			set cwmodeVars($flag) $res
			markMenuItem werksFlags $flag $res
			prefs::modified cwmodeVars($flag)
			status::msg "$flag $res" 
		} 
	} 
	status::msg "Flags synchronization done" 
}


