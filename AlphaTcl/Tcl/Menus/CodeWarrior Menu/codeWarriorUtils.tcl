# -*-Tcl-*- (nowrap) (tabsize:4)
# 
# File: codeWarriorUtils.tcl
# 							Last modification : 2005-03-27 09:57:38
# 
# Description : this file is part of the CodeWarrior Menu for Alpha.
# It contains utility procedures.
# 

proc codeWarriorUtils.tcl {} {}

namespace eval cw {}

# Make sure the CW menu is loaded
codewarriorMenu

# -----------------------------------------------------------------
# Utility procs
# -----------------------------------------------------------------

proc cw::switchtoIDE {} {
	global cw_params
	cw::checkCompilerSig
	switchTo $cw_params(cwsig)
}


proc cw::switchIfNecessary {} {
	global cw_params cwmodeVars
	if {$cwmodeVars(switchWhenCompiling)} {
		switchTo $cw_params(cwsig)
	}
}


proc cw::switchToConstructor {} {app::launchFore MWC2}


proc cw::checkCompilerSig {} {
    global cw_params CWCompilerSig 
    app::launchElseTryThese {CWIE MMCC MPCC} CWCompilerSig
    set cw_params(cwsig) "'$CWCompilerSig'"
    set cw_params(cwname) [file tail [app::launchBack $CWCompilerSig]]
}


proc cw::checkDebuggerSig {} {
    global cw_params CWDebuggerSig
    app::launchElseTryThese {CWIE MPDB MWDB} CWDebuggerSig
    set cw_params(dbgsig) "'$CWDebuggerSig'"
    set cw_params(dbgname) [file tail [app::launchBack $CWDebuggerSig]]
}


proc cw::checkRunning {{msg 1}} {
	global cw_params CWCompilerSig
	if {![info exists CWCompilerSig] \
	  || ![app::isRunning $CWCompilerSig cw_params(cwname)]} {
		if {![app::isRunning {CWIE MMCC MPCC} cw_params(cwname) CWCompilerSig]} {
			set cw_params(cwstate) "CodeWarrior is not running."
			cw::message $cw_params(cwstate) $msg 
			return 0
		}
	}
	set cw_params(cwsig) "'$CWCompilerSig'"
	return 1
}


# The fastest way to know if a project is opened is to get the projects list.
# Side effect: stores the name of the current project in cw_params(currProjectName).
# It also updates cw_params(Projectlist).
# One could also use a core/cnte event but it is less efficient:
# tclAE::build::resultData $cw_params(cwsig) core cnte ---- 'null'() kocl type(PRJD)
proc cw::isProjectOpen {{msg 1}} {
	global cw_params
	if {![cw::checkRunning $msg]} {return 0} 
	set len [llength [cw::getProjectsList]]
	if {!$len} {
		set cw_params(cwstate) "No open project"
		set cw_params(currProjectName) ""
		cw::message $cw_params(cwstate) $msg 
	} else {
		# The first project in the list is the current one
		set cw_params(currProjectName) [lindex $cw_params(Projectlist) 0]
	}
	return $len
}


proc cw::isInProject {name {msg 1}} {
	global cw_params 
	if {![cw::isProjectOpen $msg]} {return 0} 
	# Caveat: if the event succeeds (which means that the file IS in the project),
	# the return value will be 0 !
	set res [tclAE::build::resultData $cw_params(cwsig) $cw_params(cwclass) FInP \
	  ---- [tclAE::build::TEXT [file tail $name]]]
	if {$res} {
		set cw_params(cwstate) "File not in project $cw_params(currProjectName)"
		cw::message $cw_params(cwstate) $msg 
		return 0
	} else {
		cw::message "File is in current project." $msg 
		return 1
	}
}


proc cw::openaResourceFile {} {
	global cw_params
	watchCursor
	if {![cw::projectToFront]} {return} 
	status::msg "Building resource files list. Please wait..."
	set resList [cw::resFilesList]
	status::msg ""
	switch [llength $resList]  {
		0 {
			alertnote "No resource file found in the current target."
			return
		}
		1 {
			set resName [lindex $resList 0]
		}
		default {
			set shortlist ""
			foreach resf $resList {
				# CW returns paths mixing "/" and ":" (like "hd/usr:lib:crt1.o"), 
				# so we must extract the tail manually.
				set idx [string last : $resf]
				lappend shortlist [string range $resf [incr idx] end]
			}  
			if {[catch {set shortName [listpick -p "Resource file to open:" $shortlist]}]} {
				return
			} 
			set resName [lindex $resList [lsearch $shortlist $shortName]]
		}
	}
	sendOpenEvent noReply 'MACS' $resName
}


proc cw::selectPartDialog {what} {
	global cw_params
	set dialogy 10
	set dialogargs ""
	if {$what=="Target"} {
		append dialogargs "-t [list "Project '$cw_params(currProjectName)'"] 10 $dialogy 280 [expr $dialogy + 20] "
		set dialogy [expr $dialogy + 20]    
	} 
	append dialogargs "-t [list "Select a $what :"] 20 $dialogy 280 [expr $dialogy + 20] "
	set dialogy [expr $dialogy + 65]    
	append dialogargs "-b OK 245 $dialogy 305 [expr $dialogy + 20] "
	append dialogargs "-b Cancel 150 $dialogy 220 [expr $dialogy + 20] "
	set dialogy [expr $dialogy - 40]    
	set y $dialogy
	append dialogargs [dialog::menu 60 y $cw_params(${what}list) [cw::currentTarget] 200]
	set dialogy [expr $dialogy + 70]    
	set values [eval dialog -w 320 -h $dialogy $dialogargs]
	if {[lindex $values 1]} {return} ; # user cancelled
	set cw_params(curr$what) [lindex $values 2]
	if {$cw_params(curr$what) == ""} {return}
	eval cw::set$what [list $cw_params(curr$what)]
}


proc cw::selectClassDialog {} {
	global cw_params
	set args ""
	lappend args [list -t "Enter a class name :" 5 5 190 25 \
	  -e $cw_params(currClass) 10 30 270 50 \
	  -b "Get Info" 185 70 270 90 \
	  -b Cancel 90 70 170 90 ]
	set values [eval dialog -w 280 -h 100 [join $args]]
	if {[lindex $values 2]} {return 0}
	set cw_params(currClass) [lindex $values 0]
	if {$cw_params(currClass) == ""} {return 0}
	return 1
}


# Panels and property keys corresponding to the prefs flags
proc cw::setPanelKeys {arr} {
	upvar $arr thearray
	array set thearray {
		activateBrowser {"Build Extras" "EX09"}
		buildBeforeRunning {"Build Settings" "BX04"}
		enableC++Exceptions {"C/C++ Compiler" "FE09"}
		enableObjectiveC {"C/C++ Compiler" "FE26"}
		enableRunTimeTypeInfo {"C/C++ Compiler" "FE15"}
		forceC++Compilation {"C/C++ Compiler" "FE01"}
		generateLinkMap {"PPC Linker" "LN04"}
		generateSymFile {"PPC Linker" "LN02"}
		playSoundAfterUpdt&Make {"Build Settings" "BX01"}
		saveOpenFilesBeforeBuild {"Build Settings" "BX07"}
		treatWarningsAsErrors {"C/C++ Warnings" "WA08"}
		useExternalEditor {"Extras" "EX11"}
	}
}


proc cw::versionGreaterThanFour {} {
	global cw_params
	if {![info exists cw_params(version)]} {cw::getVersionNumber} 
	if {[regexp "^\\d+" $cw_params(version) major]} {
		return [expr {$major > 4}]
	} else {
		error "Error checking version info"
	}
}


proc cw::getVersionNumber {} {
	global cw_params
	if {![cw::checkRunning]} {return} 
	set cw_params(version) ""
	# Find the version string of the appli
	set res [tclAE::send -r 'MACS' core getd \
	  ---- [tclAE::build::propertyObject \
	  vers [tclAE::build::nameObject appf \
	  [tclAE::build::TEXT [file::unixPathToFinder [nameFromAppl $cw_params(cwsig)]]]]]]
	set cw_params(version) [tclAE::getKeyData $res ---- TEXT]
	regexp {v([0-9.]+)} $cw_params(version) & cw_params(version)
	return $cw_params(version)
}


proc cw::propertyList {prop objDesc {msg ""}} {
	global cw_params
	# List property for all source files
	set theList [tclAE::send -t 500000 -r $cw_params(cwsig) core getd \
	  ---- [tclAE::build::propertyObject $prop \
	  [tclAE::build::indexObject SRCF "abso('all ')" $objDesc]]]
	# Extract direct obj parameter
	if {[catch {tclAE::getKeyData $theList ---- } res]} {
		if {$msg ne ""} {
			status::msg "Couldn't get $msg list"
		} 
		return ""
	} else {
		return $res
	}
}


proc cw::sortByTail {one two} {
    string compare -nocase [file tail $one] [file tail $two]
}


proc cw::message {str {type 0}} {
	if {$type} {
		alertnote $str
	} else {
		status::msg $str
	}
}


proc cw::sound {var} {
    if {$var != "None"} {beep $var} 
}


proc cw::cWMenuPreferences {} {
    prefs::dialogs::packagePrefs cw
}


proc cw::cWMenuHelp {} {
	help::openFile "CodeWarrior Menu Help"
}

