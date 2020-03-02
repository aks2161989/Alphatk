# to autoload this file
proc m2Utils.tcl {} {}


#================================================================================
# ×××× Utilities providing convenience, e.g. DEF opening from MOD etc. ×××× #
#================================================================================

namespace eval M2 {}


#===============================================================================
# Idea from Raymond Waldrop <rwaldrop@cs.tamu.edu> and Juan Falgueras, author
# of Mod2 mode
#===============================================================================
# The following will switch between the definition and implementation module
# assuming they're in the same directory and file names differ only in extensions. 
# However, actual code of idea generating proc Mod2otherPart has been completely 
# rewritten.
proc M2::otherLibModule {} {
    global tcl_platform HOME
#     if {$tcl_platform(platform) == "unix"} {
# 	regsub {(^.)(.*)$} "${HOME}" "\\1" pathSep
#     } else {
# 	regsub {(^.)(.*)$} [file join "HD"] "\\1" pathSep
#     }
    set pathSep [file separator]
    # alertnote "In M2::otherLibModule: almost at begin"

    set curname "[win::Current]"
	set path "[file dirname $curname]${pathSep}"
	set extension [file extension $curname]
	set tgtBaseName [file rootname [file tail $curname]]
	set tgtName ""
	if       {"$extension" == ".MOD"} then { 
		set tgtName "${tgtBaseName}.DEF" 
	} elseif {"$extension" == ".mod"} then { 
		set tgtName "${tgtBaseName}.def" 
	} elseif {"$extension" == ".DEF"} then { 
		set tgtName "${tgtBaseName}.MOD" 
	} elseif {"$extension" == ".def"} then { 
		set tgtName "${tgtBaseName}.mod" 
	} else {
		status::msg "Current file has not a proper extension of form .DEF, .def, .MOD, or .mod"
	}
	# check if path contains MOD or DEF according to dir naming
	# conventions on DEV server e.g. if $path == pathBegin:Base.MOD
	# then allow for search in pathBegin:Base.DEF or vice versa
    set pathAlt "[file dirname $curname]"
	if {[file extension $pathAlt] == ".MOD"} then {
		set pathAlt "[file root $pathAlt].DEF${pathSep}"
	} elseif {[file extension $pathAlt] == ".DEF"} then {
		set pathAlt "[file root $pathAlt].MOD${pathSep}"
	} else {
		set pathAlt ""
	}
	return [list $path $tgtName $pathAlt]
}

proc M2::openOtherLibModule {} {
	set otherLibModPFN [M2::otherLibModule]
	set path [lindex $otherLibModPFN 0]
	set tgtName [lindex $otherLibModPFN 1]
	set pathAlt [lindex $otherLibModPFN 2]
	if {("$tgtName" != "")} then {
		if {([file exists "${path}${tgtName}"])} then {
			status::msg "Found module '${tgtName}' in directory '${path}'"
			win::OpenQuietly "${path}${tgtName}"
		} elseif {([file exists "${pathAlt}${tgtName}"])} then {
			status::msg "Found module '$tgtName' in directory '${pathAlt}'"
			win::OpenQuietly "${pathAlt}${tgtName}"
		} else {
			status::msg "Module '${tgtName}' not in directory '${path}'"
		}
	}
}

proc M2::M2OptionTitlebar {} {
	# alertnote "In M2::M2OptionTitlebar: at begin"
	set otherLibModPFN [M2::otherLibModule]
	set path [lindex $otherLibModPFN 0]
	set tgtName [lindex $otherLibModPFN 1]
	# alertnote $tgtName
	return "$tgtName"
}


proc M2::SetDfltFont {} {
    global M2modeVars
    setFontsTabs -font $M2modeVars(defaultFont) -fontsize $M2modeVars(defaultFontSize)
    M2::HyperiseURLs
}


proc M2::HyperiseURLs {} {
    help::hyperiseUrls
}




# Reporting that end of this script has been reached
status::msg "m2Utils.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
	alertnote "m2Utils.tcl for Programing in Modula-2 loaded"
}

