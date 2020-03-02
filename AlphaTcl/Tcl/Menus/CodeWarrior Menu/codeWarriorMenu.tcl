## -*-Tcl-*- (install) (nowrap)
## 
 # File: codeWarriorMenu.tcl
 # 							Last modification: 2005-03-26 13:44:54
 # 
 # Version 3.0 of the CodeWarrior Menu for Alpha merges the commands and features defined 
 # in the two previously existing versions (codeWarriorMenu.tcl and codeWarriorMenu2.tcl). 
 # One part of the code was written by Bernard Desgraupes (bdesgraupes@easyconnect.fr) 
 # and the other by Jon Guyer (jguyer@his.com)
 #
 # # The CodeWarrior Menu is now split into several files. It will not work
 # properly if any of them is missing:
 #	codeWarriorCompile.tcl
 #	codeWarriorDebug.tcl
 #	codeWarriorErrors.tcl
 #	codeWarriorFilesets.tcl
 #	codeWarriorIncludes.tcl
 #	codeWarriorInspectors.tcl
 #	codeWarriorMenu.tcl
 #	codeWarriorPanels.tcl
 #	codeWarriorTargets.tcl
 #	codeWarriorUtils.tcl
 #	
 # This is free software. See licensing terms in the CodeWarrior Menu Help file.
 ##

alpha::menu codewarriorMenu 3.1 "C C++ Objc C# Java" "¥268" {
	alpha::package require searchPaths 1.0

	# # Global prefs
	# Building options
	newPref flag buildBeforeRunning 1 cw cw::setFlagInProject
	newPref flag playSoundAfterUpdt&Make 0 cw cw::setFlagInProject
	newPref flag useExternalEditor 0 cw cw::setFlagInProject
	newPref flag saveOpenFilesBeforeBuild 1 cw cw::setFlagInProject
	
	# # Target-specific prefs
	# Compiling options
	newPref flag activateBrowser 1 cw cw::setFlagInProject
	newPref flag forceC++Compilation 0 cw cw::setFlagInProject
	newPref flag enableC++Exceptions 0 cw cw::setFlagInProject
	newPref flag enableObjectiveC 0 cw cw::setFlagInProject
	newPref flag enableRunTimeTypeInfo 0 cw cw::setFlagInProject
	newPref flag treatWarningsAsErrors 0 cw cw::setFlagInProject
	# Linking options
	newPref flag generateLinkMap 0 cw cw::setFlagInProject
	newPref flag generateSymFile 1 cw cw::setFlagInProject
	
	# CWmenu-specific prefs
	newPref flag switchWhenCompiling 1 cw
	newPref flag touchWhenSaving 1 cw
	newPref sig CWCompilerSig CWIE
	newPref sig CWDebuggerSig MWDB
	newPref color winkyColor red cw
	
	# Now build the menu
	menu::buildProc codewarriorMenu cw::buildMenu
	menu::buildProc werksFlags {
		menu::buildFlagMenu werksFlags array cwmodeVars
	}
	
	menu::buildSome codewarriorMenu
	
	hook::register savePostHook cw::modified "C" "C++" "Objc" "C#" "Java"

} {codewarriorMenu} {} uninstall {this-directory} maintainer {
    "Bernard Desgraupes" <bdesgraupes@easyconnect.fr> <http://webperso.easyconnect.fr/bdesgraupes/> 
    "Jon Guyer" <jguyer@his.com> <http://www.his.com/jguyer/>
} description {
    Interacts with the Metrowerks CodeWarrior program so that you can develop
    your C/C++ project and control CodeWarrior actions from within Alpha
} help {
    file "CodeWarrior Menu Help"
} requirements {
    if {[info tclversion] < 8.0} {
		error "codewarrior menu requires Tcl 8"
    }
} preinit {
    if {$alpha::macos} {
		fileset::registerNewType codewarrior "list"
    }
}

hook::register requireOpenWindowsHook [list projectParts "addCurrentFile"] 1
hook::register requireOpenWindowsHook [list projectParts "removeCurrentFile"] 1
hook::register requireOpenWindowsHook [list compiling "touch"] 1
hook::register requireOpenWindowsHook [list compiling "checkSyntax"] 1
hook::register requireOpenWindowsHook [list compiling "preprocess"] 1
#hook::register requireOpenWindowsHook [list compiling "precompile"] 1
hook::register requireOpenWindowsHook [list compiling "compile"] 1
hook::register requireOpenWindowsHook [list compiling "disassemble"] 1
hook::register requireOpenWindowsHook [list debugging "setBreakpoint"] 1
hook::register requireOpenWindowsHook [list debugging "clearBreakpoint"] 1
hook::register requireOpenWindowsHook [list inspectors "fileInfo"] 1
hook::register requireOpenWindowsHook [list $codewarriorMenu "Toggle Header & Source"] 1

hook::register activateHook cw::rebuildSearchPathMenu "C" "C++" "Objc" "C#" "Java"

# set cwdebugMenu	"¥274"

namespace eval cw {}

proc codewarriorMenu {} {}


# -----------------------------------------------------------------
# # Initialisations
# -----------------------------------------------------------------
# Global parameters
set cw_params(cwclass) MMPR
set cw_params(dbgclass) MWDB
set cw_params(0) "no"
set cw_params(1) "yes"
set cw_params(cwsig) ""
set cw_params(cwname) ""
set cw_params(cwstate) ""
set cw_params(currProjectName) ""
set cw_params(currProjectPath) ""
set cw_params(currTarget) ""
set cw_params(currClass) ""
set cw_params(Projectlist) ""
set cw_params(Targetlist) ""
set cw_params(errWinTitle) "* Errors and Warnings *"
set cw_params(target) [list "Access Paths" "Build Extras" "C/C++ Compiler&" "C/C++ Warnings&" \
  "Custom Keywords" "File Mappings" "MacOS Merge Panel" "Output Flags" "PPC Disassembler" \
  "PPC Linker" "PPC PEF" "PPC Project" "PPCAsm Panel" "PPC Global Optimizer" "Rez Compiler" \
  "Runtime Settings" "Target Source Trees" "Target Settings" ]
set cw_params(global) [list "Build Settings" "Debugger Display" "Debugger Global" "Extras" "Font" \
  "Layout Editor" "MetroNub Panel" "Plugin Settings" "Shielded Folders" "Syntax Coloring" \
  "Global Source Trees" "VCS Setup" ]


# Load the info arrays
catch {uplevel #0 {source [file join $HOME Tcl Completions codeWarriorCompletions.tcl]}}


# -----------------------------------------------------------------
# Building the CodeWarrior menu
# -----------------------------------------------------------------
proc cw::buildMenu {} {
    global codewarriorMenu cw_params

    set ma {
		"ª/-<USwitch to IDE"
		"switchToConstructor"
		"(-"
	}
	lappend ma [list Menu -n projectParts -p cw::menuProc {
	    "selectProjectÉ"
	    "selectTargetÉ"
	    "<E<SaddCurrentFile"
	    "<S<IremoveCurrentFile"
	    "(-"
	    "ªCreate CW Fileset"
	    "(-"
	    "resetProjectEntryPaths"
	    "exportProject"
	    "(-"
	    "ªOpen a Resource FileÉ"
	}]
	lappend ma [list Menu -n compiling -p cw::menuProc {
	    "/T<Utouch"
	    "checkSyntax"
	    "preprocess"
	    "/K<E<S<Ucompile"
	    "/K<S<O<U<IcompileFiles"
	    "<E<Sdisassemble"
	    "<S<IeditDumpInAlpha"
	    "(-"
	    "/U<E<U<Oupdate"
	    "/M<E<U<Omake"
	    "(-"
	    "/R<E<B<Odebug"
	    "/R<E<I<B<Orun"
	    "(-"
	    "removeObjectCode"
	}]
	lappend ma [list Menu -n debugging -p cw::menuProc {
		"/B<E<U<OsetBreakpoint"
		"/J<E<U<OclearBreakpoint"
		"(-"
		"/N<E<U<OnextError"
		"/P<E<U<OprevError"
		"ª/I<E<U<OShow in IDE"
		"(-"
		"editLinkMap"
	}]
	lappend ma [list Menu -m -n headers {}]
	lappend ma "Toggle Header & Source&"
	lappend ma "(-"
	lappend ma [list Menu -n werksFlags {}]
	lappend ma "syncFlagsWithProject" 
	lappend ma "(-"
	lappend ma [list Menu -n inspectors -p cw::menuProc {
		"fileInfo"
		"filePrerequisites"
		"fileDependents"
		"(-"
		"targetInfo"
		"projectInfo"
		"(-"
		"linkOrder"
		"(-"
		"nonSimpleClasses"
		"openClassBrowserÉ"
		"getClassInfoÉ"
	}]
	lappend ma [list Menu -m -n globalPrefs -p cw::prefPanelsProc \
	  [concat $cw_params(global) "(-" [list "All Globals"]]]
	lappend ma [list Menu -m -n targetPrefs -p cw::prefPanelsProc \
	  [concat $cw_params(target) "(-" [list "All Panels"]]]
	lappend ma "(-"
	lappend ma "ªCW Menu PreferencesÉ"
	lappend ma "ªCW Menu Help"

    return [list build $ma cw::menuProc [list werksFlags] $codewarriorMenu]
}


# -----------------------------------------------------------------
# Menu procs
# -----------------------------------------------------------------

proc cw::menuProc {menu item} {
    regsub -all " +" $item "" item
    cw::$item
}


proc cw::prefPanelsProc {menu item} {
	global cw_params
	if {![cw::checkRunning]} {return} 
	watchCursor
	set trgtPnl 0
	switch $item {
		"All Globals" {
			append result [cw::allSettings global]
		}
		"All Panels" {
			append result [cw::allSettings target]
		}
		default {
			status::msg "Collecting '$item' prefs. Please wait..."
			append result "PREFS PANEL '$item'\n"
			if {[lsearch -exact $cw_params(global) $item] == "-1"} {
				if {![cw::isProjectOpen]} {return} 
				cw::currentTarget
				append result "Current target: $cw_params(currTarget)\n"
				append title "$cw_params(currTarget): "
			} 
			append result "[ISOTime::ISODateAndTimeRelaxed]\n\n"
			append result [cw::extractPanelInfo $item]
		}
	}
	append title $item
	status::msg ""
	new -n "$title" -info $result
}


proc cw::rebuildSearchPathMenu {{name ""}} {
    global mode
    global ${mode}modeVars
	mode::rebuildSearchPathMenu headers
	if {![info exists ${mode}modeVars(includeMenu)]} {
	    status::msg "No 'Include Menu' pref in '$mode' mode"
	} elseif {![set ${mode}modeVars(includeMenu)]} {
	    status::msg "'Include Menu' pref not set for '$mode' mode"
	}
}