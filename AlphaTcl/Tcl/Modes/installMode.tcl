## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "installMode.tcl"
 #                                          created: 05/10/2000 {02:53:35 pm}
 #                                      last update: 02/08/2006 {03:08:00 PM}
 # Description: 
 # 
 # A mode used for installation scripts used by Alpha, which also provides
 # a little support for developers writing these scripts.
 # 
 # You should not remove this file.  
 # Alpha may not function very well without it.
 # 
 # Original by Vince Darley
 # Includes contributions from Craig Barton Upright
 # 
 # Copyright 2000-2006 Vince Darley
 # All rights reserved.
 # 
 # ==========================================================================
 ##

alpha::mode [list Inst Install] 0.2 source [list "*Install" "*INSTALL"] {
    installMenu
} {
    # Initialization script.
    alpha::internalModes "Inst" "Install"
    addMenu installMenu "Install"
    hook::register openHook install::openHook Inst
    hook::register editHook install::editHook .install
} description {
    Provides internal support for AlphaTcl installation scripts
} help {
    The mode is for used by install scripts for adding additional packages or
    upgrading Alpha.  Install mode places an "Install" menu in the menu bar,
    although installation scripts generally use an installation dialog which
    provides an even better user interface.
    
    Users are always given the option to back-up any currently existing files
    in the AlphaTcl library -- these will be placed in an "AlphaTcl" folder
    in the same level as the "Alpha" folder.

    Click on this link "Install Example" for an example of such a dialog.  To
    see the actual script, hold down any modifier key when clicking on the
    link (or while the file is opening.)

    For more information about installation, see "install.tcl".
    For more information about writing packages, see "Extending Alpha".

    This mode is not intended for text editing beyond installation scripts. 
    AlphaTcl developers who are using this mode should take advantage of
    command double-clicking on optional arguments, and the use of the
    'electric dash' feature.  The "install::packageInstallationDialog" string
    is also available as an electric completion.
}

proc installMode.tcl {} {}

namespace eval Inst {

    variable commentCharacters
    set commentCharacters(General)    "# "
    set commentCharacters(Paragraph)  [list "## " " ##" " # "]
    set commentCharacters(Box)        [list "#" 2 "#" 2 "#" 3]
}

newPref v prefixString {# } Inst
newPref v wordBreak {(\$)?[-\w:_]+} Inst

set Instcmds [list \
  -ignore -remove -rebuildquit -require -provide -forcequit \
  -SystemCode -Modes -Menus \
  -BugFixes -Completions -Packages \
  -ExtensionsCode -UserModifications \
  -Tools -Tests -Source ]

# The color of comments, lines starting with '#'.  The default is 'blue' to
# give a visual clue that we're not in "Tcl" mode.
newPref color commentColor "blue" Inst
regModeKeywords -C -e {#} -c $InstmodeVars(commentColor) -s {green} Inst {}
regModeKeywords -a -k blue    Inst {install::packageInstallationDialog}
regModeKeywords -a -k magenta Inst $Instcmds

lappend Instcmds "install::packageInstallationDialog"
set Instcmds [lsort -dictionary $Instcmds]

# ×××× Command Double-Click ×××× #

Bind 'l' <c> {evaluate} Inst

proc Inst::DblClick {args} {
    set txt [getText [lindex $args 0] [lindex $args 1]]
    switch -- $txt {
	-ignore      {
	    set msg {'list of files to ignore'}
	}
	-remove      {
	    set msg {'list of files to remove from Alpha hierarchy'}
	}
	-rebuildquit {
	    set msg "'0 or 1'\r\r(prompts the user to rebuild \
	      indices and quit; default is \"1\")"
	}
	-require {
	    set msg "'?Pkg version? ?Pkg version?' É \r\re.g.\r\r \
	      -require {Alpha 6.52 elecCompletions 7.99}"
	}
	-provide {
	    set msg {'?Pkg version? ?Pkg version? É'}
	}
	-forcequit {
	    set msg "'0' or '1' or '2'.\r\r\
	      Note: default is \"0\".  -forcequit 2 is only designed for \
	      use by Alpha Core updaters; \
	      it should not really be used by other code."
	}
	-SystemCode - -Modes - -Menus -
	-BugFixes - -Completions - -Packages -
	-ExtensionsCode - -UserModifications - 
	-Tools - -Tests - -Source {
	    set msg {'force the placement of the following list of files.'}
	}
    }
    if {[info exists msg]} {
	status::msg "'$txt' syntax:"
	regsub {^'(.*)'$} $msg \\1 msg1
	alertnote $msg1
	regsub -all {\s+} $msg " " msg2
	regsub -all {'|([^']+$)} $msg2 "" msg2
	status::msg "'$txt' syntax: $msg2"
    } else {
	eval Tcl::DblClick $args
    }
}

# ×××× Option Titlebar ×××× #

proc Inst::OptionTitlebar {} {
    set files [list]
    if {[win::Exists [set w [win::Current]]]} {
	set winDir [file dirname $w]
	foreach f [file::recurse $winDir]  {
	    if {$f eq $w} {continue}
	    regsub [quote::Regfind $winDir] $f "" f
	    lappend files [string trimleft $f [file separator]]
	}
	foreach d [file::hierarchy $winDir 7] {
	    regsub [quote::Regfind $winDir] $d "" d
	    set d [string trimleft $d [file separator]]
	    lappend files $d[file separator]
	}
    }
    return [lsort -dictionary $files]
}

proc Inst::OptionTitlebarSelect {name} {

    set name [string trim $name [file separator]]
    set winDir  [file dirname [win::Current]]
    set newName [file join $winDir [file separator]$name]
    if {[file isfile $newName]} {
	file::openQuietly $newName
    } elseif {[file isdir $newName]} {
        file::showInFinder $newName
    } else {
        error "$newName doesn't exist"
    }
}

# ×××× Electrics ×××× #

proc Inst::carriageReturn {} {

    if {[isSelection]} {deleteSelection} 
    set pat {install::packageInstallationDialog}
    if {[llength [search -n -s -f 0 -i 0 $pat [getPos]]]} {
	if {![regexp {\\[\t ]*$} [getText [pos::lineStart] [getPos]]]} {
	    insertText "\\"
	} 
    } 
    insertText "\r"
}

set completions(Inst) {
    completion::cmd completion::electric completion::word
}

array set Instelectrics {
    -ignore             " \{¥list of files to ignore¥\}"
    -remove             " \{¥list of files to remove from Alpha hierarchy¥\}"
    -rebuildquit        " ¥0 or 1 (default is '1')¥"
    -require            " \{¥?Pkg version?¥ ¥?Pkg version?¥\}"
    -provide            " \{¥?Pkg version?¥ ¥?Pkg version?¥\}"
    -forcequit          " ¥0 or 1 or 2¥"
    -SystemCode         " \{¥force placement of the list of files.¥\}"
    -Modes              " \{¥force placement of the list of files.¥\}"
    -Menus              " \{¥force placement of the list of files.¥\}"
    -BugFixes           " \{¥force placement of the list of files.¥\}"
    -Completions        " \{¥force placement of the list of files.¥\}"
    -Packages           " \{¥force placement of the list of files.¥\}"
    -ExtensionsCode     " \{¥force placement of the list of files.¥\}"
    -UserModifications  " \{¥force placement of the list of files.¥\}"
    -Tools              " \{¥force placement of the list of files.¥\}"
    -Tests              " \{¥force placement of the list of files.¥\}"
    -Source             " \{¥force placement of the list of files.¥\}"
}

set Instelectrics(install::packageInstallationDialog) \
  " \"¥pkgname \"Package\"¥\" \"\\\r¥description¥ \"\\\r¥args¥"

Bind '-' Inst::electricDash Inst

proc Inst::electricDash {} {
    
    typeText "-"
    set txt [getText [pos::math [set pos1 [getPos]] - 2] $pos1]
    if {$txt != "--"} {return}
    foreach option $::Instcmds {
	if {[regsub -- "^\-" $option "" option]} {
	    lappend options $option
	}
    }
    set completion [listpick -p "Choose an option:" $options]
    # Remove any leading "-"
    set pos0 $pos1
    while {[lookAt [pos::math $pos0 - 1]] == "-"} {
	set pos0 [pos::math $pos0 - 1]
    } 
    deleteText $pos0 $pos1
    insertText -$completion
    bind::Completion
}

# ===========================================================================
# 
# .
