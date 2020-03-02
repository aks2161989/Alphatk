# to autoload this file
proc m2Menu.tcl {} {}

namespace eval M2 {}

#===========================================================================
# ×××× M2 menu ×××× #
#===========================================================================
proc m2Menu {} {}

menu::buildProc m2Menu menu::buildM2

# redeclaration of proc menu::buildM2 fails when m2Menu.tcl is sourced 
# from within proc M2::adjustLatestDevModeUse in m2AdjPrefs.tcl
if {(![info exists M2::whileAdjusting]) | ([info exists M2::whileAdjusting] && ![set M2::whileAdjusting])} {

proc menu::buildM2 {} {
    global m2Menu
    set menulst [list \
      "<B/0openWorkFiles" \
      "<B/EfindNextError" \
      "(-" \
      "<B/1launchShellAndSimulate" \
      "<B/2launchShell" \
      "(-" \
      "<B/GnextPlaceholder" \
      "<I<B/GprevPlaceholder" \
      "<U<B/MselectLine" \
      "(-" \
      "<B/KcommentSelection" \
      "<I<B/KuncommentSelection" \
      "<B/AwrapComment" \
      "<U<B/AwrapText" \
      "<B/3textToStructuralMark" \
      "<B/4textToSectionMark" \
      "<B/8setDefaultFont" \
      "(-" \
      "defToMod" \
      "makeProjectFile" \
      "<E<U/FautoEditCompilerFlags" \
      ]
    set submenulst	[list \
      "CASE" \
      "FOR" \
      "FROM IMPORT" \
      "IF" \
      "if on one line" \
      "LOOP" \
      "PROCEDURE" \
      "REPEAT" \
      "WHILE" \
      "WITH" \
      "(-" \
      "New DEFINITION ModuleÉ" \
      "New IMPLEMENTATION ModuleÉ" \
      "New Program MODULEÉ" \
      ] 
    lappend menulst [list Menu -n templates -m -p M2::dispatchSubMenuCmds ${submenulst}]
    lappend menulst \
      "(-" \
      "configureLaunching" \
      "(-" \
      "m2Help"
    # Only use these bindings for M2 mode
    return [list build $menulst [list M2::dispatchMenuCmds -M M2] "" $m2Menu]
}

}


menu::buildSome m2Menu

proc M2::dispatchMenuCmds {menu cmd} {
    if {[regexp {([^-]+)([-]*.*)} $cmd ]} then {
	regsub -- {([^-]+)([-]*.*)} $cmd "\\1" cmd
    }
    if {"$cmd" == "configureLaunching"} {
	M2::configureLaunching 1 1
    } elseif {"$cmd" == "setDefaultFont"} {
	M2::SetDfltFont
    } elseif {[catch {M2::$cmd}]} {
	$cmd
    }
}


proc M2::dispatchSubMenuCmds {menu cmd} {
    set cmd [string trim $cmd]
    # set cmd [MinorizeStringBeg $cmd]
    regsub -all -- {[ ]+} $cmd "" cmd
    set cmd "smcmd$cmd"
    if {[catch {M2::$cmd}]} {
        $cmd
    } 
}



# Reporting that end of this script has been reached
status::msg "m2Menu.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
    alertnote "m2Menu.tcl for Programing in Modula-2 loaded"
}

