## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "elecCorrections.tcl"
 #                                          created: 10/05/2000 {02:18:05 pm}
 #                                      last update: 02/21/2006 {06:57:23 PM}
 #                               
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Description:
 # 
 # Activating this feature allows Alpha to automatically correct spelling
 # mistakes using keyword lists defined by the user.  Inspired by the proc
 # "sql_electUpper", in sqlMode.tcl .  See the "Electric Corrections Help"
 # file for details.
 # 
 # Most of the procedures in this file concern the "Electric Corrections"
 # menu, more specifically the manipulation of user defined corrections.  The
 # correcting procedure, [correction::correctTypo], is actually quite simple
 # and speedy.
 # 
 # --------------------------------------------------------------------------
 # 
 # Copyright (c) 2000-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::feature elecCorrections 1.1b2 "global-only" {
    # Create the "Electric Corrections" menu.
    menu::buildProc electricCorrections correction::buildCorrectionsMenu
    namespace eval correction {
	variable correctTypos 0
	variable correctI     0
	correction::initialize
    }
} {
    # Insert the menu into "Config > Packages".
    menu::insert   preferences submenu "(-)" electricCorrections
    # Bind space, return keys to spell correct check.
    ascii   0x20 {correction::correctTypo "\ "}
    Bind    '\r' {correction::correctTypo "\r"}
    hook::register   changeMode {correction::resetVariables}
} {
    # Deactivation script.
    menu::uninsert preferences submenu "(-)" electricCorrections
    # unBind space, return keys from spell correct check.
    unascii 0x20 {correction::correctTypo "\ "}
    ascii   0x20 {spaceBar}
    unBind  '\r' {correction::correctTypo "\r"}
    Bind    '\r' {bind::CarriageReturn}
    hook::deregister changeMode {correction::resetVariables}
} uninstall {
    catch {file delete [file join $HOME Tcl Packages elecCorrections.tcl]}
    catch {file delete [file join $HOME Help "Electric Corrections Help"]}
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
}  description {
    This package helps check for and correct spelling mistakes or typos as
    you type
}  help {
    This package helps check for and correct spelling mistakes or typos as
    you type.  Select "Config > Global Setup > Features" to turn it on.
    
    Preferences: Features
    
	  	Table Of Contents

    "# Introduction"
    "# Preferences"
    "# Electric Corrections Menu"
    "# Usage"
    "# Possible future directions"
    "# Acknowledgments"

    <<floatNamedMarks>>
    
	  	Introduction

    This is not a spell-checking extension -- instead it is more of a
    "misspell-checker": you must teach Alpha the common misspellings or typos
    to correct using the menu items described below.

    Whenever you press the return or space key, Alpha will then compare the
    previous word to the list of all typos, and correct it if necessary.
    This package also includes a "Smart i" preference, if this has been
    turned on then Alpha will automatically change "i" to "I" as you type.

    Activating the extension will create four new preferences and insert a
    new "Config > Preferences > Electric Corrections" submenu described
    below.
    

	  	Preferences

    Select "Config > Preferences > Electric Corrections > Corrections Prefs"
    to change the values of these preferences.

	Smart i

    Automatically convert " i " to " I ".

	Smart i Modes

    Allows you to specify the modes that use the "Smart i" feature, initially
    including only "Text TeX Bib HTML".  If this list is empty, automatic
    correction applies to all modes.

	Turn Corrections On/Off

    Turns automatic corrections of typos on or off.  This does not affect the
    "Smart i" preference.

	Correcting Modes

    Allows you to specify the modes that check for misspellings.  If this
    list is empty (the default value), automatic correction applies to all
    modes.

	  	Electric Corrections Menu

	View Corrections

    Open a window with all current typos.  The package only supplies one typo
    to initially correct, changing "hte" to "the"

	Add Corrections

    Open a dialog to create new typos.  Only lower-case typos need to be
    entered -- both lower-case and capitalized typos will be corrected
    automatically.

	Edit Corrections

    Open a list-pick dialog to edit all typos.

	Remove Corrections

    Open a list-pick dialog to remove all user-defined typos.

	Smart i

    Automatically convert " i " to " I ".

    (This is a toggleable menu item, turning the preference on and off.)

	Smart i Modes

    Allows you to specify the modes that use the "Smart i" preference,
    initially including only "Text TeX Bib HTML".  If this list is empty,
    automatic correction applies to all modes.

	Turn Corrections On/Off

    Turns automatic corrections of misspellings or typos on or off.  This
    does not affect the "Smart i" preference.

	Correcting Prefs

    Allows you to specify the modes that check for typos.  You can select any
    subset of the modes currently available, or choose the option for "All"
    or "None".

	Corrections Help

    Open this file.

	  	Usage

    Following every Space or Return keystroke, the desired whitespace is
    inserted into the window, and then the preceding word is checked against
    the list of defined typos -- if the word matches, it is deleted and the
    correction is inserted.  If the "Smart i" preference is set, then any
    lone i will be converted to I. Preceding words are checked even if
    followed by an intermediate character such as , .  ; etc.  -- the
    correction is inserted without disturbing the following characters.  So

	Where was i?
	i decided to ask hte, well, obviously oblivious inn-keeper, ...

    corrects to

	Where was I?
	I decided to ask the, well, obviously oblivious inn-keeper, ...

    All user-defined misspellings/typos are automatically converted to both
    lower case and capitalized words -- both "hte --> the" and "Hte --> The"
    work, but only the first must be defined.  Note that if you have multiple
    misspellings for the same word, you must defined each one separately,
    such as "teh --> the".  All typos will be corrected in any mode listed in
    the "Correcting Modes" preference.  It is not possible to define
    mode-specific typos.

    Here's one way to exploit this feature: I have defined the following
    "typos", which I generally will not accidentally type:

    "sgy  --> sociology"
    "scal --> sociological"
    "slly --> sociologically"
    "sc   --> social capital"

    Now whenever I type "sgy" or "Sgy", the "correction" is automatically
    inserted if I follow it with a Space or Return.  Suppose that I have the
    terms "screaming" and "somethingCruddy" in my file, and I have just typed
    "sc".  Note the following electric options:

	Space or Return:        correct to      "social capital"
	Completion Key:         complete to     "screaming"
	Expansion Key:          expand to       "somethingCruddy"

    If you would like to define "Electric Corrections Over-Ride" keys, open a
    "prefs.tcl" file and add these lines:
    
	Bind '\ ' <s> {insertText "\ "}
	Bind '\r' <s> {bind::CarriageReturn}

    Pressing the Shift key in combination with Space or Return will then
    over-ride corrections and simply enter a space or a carriage return.

	  	Possible future directions

    ¥ Include a pre-defined set of typos that has something more than simply
    "hte".  I would just as soon leave it up to the user to create them, but
    if somebody has a list that they would like to send along (with common
    typos and the corrections, please) I'll include it in future versions.
    One concern that I have is that for such a list to be truly useful, it
    should be comprehensive, and that will both make it much more difficult
    for the user to know what's in there and potentially slow down the
    correcting process.
    
    Procedures have already been written to unset/restore the default list.
    It would be possible to come up with several different lists to
    accommodate different editing settings, or languages ...
    
    ¥ Allow the creation of mode-specific corrections, similarly to
    mode-specific completions.  I don't have any objections, but I'm not sure
    about the best way to accomplish this.
    
    Source code can be found in "elecCorrections.tcl" -- contributions are
    certainly welcome.

	  	Acknowledgments

    This package was inspired by "Electric Completions / Expansions", and
    based upon the proc: sql_electUpper found in "sqlMode.tcl" (Joel D.
    Elkins.)  Many thanks to Vince Darley and Bernard Desgraupes for several
    bug fixes and suggestions.
}

proc elecCorrections.tcl {} {}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

namespace eval dialog::specialView {}

# We need this special dialog view type.

proc dialog::specialView::allNoneModes {v} {
    set m [string tolower $v]
    if {([lsearch $m "all"] > -1)} {
	set result "All modes"
    } elseif {([lsearch $m "none"] > -1)} {
	set result "No modes"
    } elseif {([lsearch $m "exclude"] > -1)} {
	set v [lremove $v "exclude"]
	if {([set vl [llength $v]] > 5)} {
	    set v1 [lrange $v 0 2]
	    set v2 [lrange $v [expr {$vl - 2}] end]
	    set result "All except [join $v1 {, }]É [join $v2 {, }]"
	} else {
	    set result "All except [join $v {, }]"
	}
    } elseif {([set vl [llength $v]] > 7)} {
	set v1 [lrange $v 0 3]
	set v2 [lrange $v [expr {$vl - 3}] end]
	set result "[join $v1 {, }]É [join $v2 {, }]"
    } else {
	set result [join $v {, }]
    }
    return $result
}

proc dialog::specialView::listModes {v} {
    set m [string tolower $v]
    if {([set vl [llength $v]] > 7)} {
	set v1 [lrange $v 0 3]
	set v2 [lrange $v [expr {$vl - 3}] end]
	set result "[join $v1 {, }]É [join $v2 {, }]"
    } else {
	set result [join $v {, }]
    }
    return $result
}

namespace eval dialog::specialSet {}

# We need this special dialog set type.

proc dialog::specialSet::allNoneModes {itemInfo {setCmd ""}} {
    # SetÉ pressed
    set old [dialog::getFlag $itemInfo]
    if {![catch {dialog::modesAllNoneList $old} ff] \
      && $ff != $old} {
	dialog::modified $itemInfo $ff $setCmd
    }
    return
}

proc dialog::specialSet::listModes {itemInfo {setCmd ""}} {
    # SetÉ pressed
    set old [dialog::getFlag $itemInfo]
    if {![catch {dialog::listModes $old} ff] \
      && $ff != $old} {
	dialog::modified $itemInfo $ff $setCmd
    }
    return
}

namespace eval dialog {
    
    # We need this special preference type.
    prefs::addType allNoneModes
    # This one could be useful for other code.
    prefs::addType listModes

    # We need this special dialog type.
    variable complex_type

    # 'multiflagcols' will insert a set of checkboxes into the dialog with
    # a specified number of columns (default is '2') , with these items
    # listed either across rows or down columns (default is '1').
    # 
    # Usage:
    # 
    # list multiflagcols $items <columns> <downCols>
    # 
    # as in (e.g.) 2 columns, ordered across rows:
    # 
    # lappend [list [list multiflagcols $items 2 0] $text $values]
    # 
    #   Ada     Bib
    #   Brws    C
    #   C#      C++
    #   Calc    Caml
    #   ...
    # 
    # or (e.g.) 5 columns, ordered down columns:
    # 
    # lappend [list [list multiflagcols $items 5 1] $text $values]
    # 
    #   Ada     CSS     Java    Mf      SAS
    #   Bib     Dico    Jscr    MPW     Scil
    #   Brws    Diff    Lisp    ObjC    Scm
    #   ...     ...     ...     ...     ...
    # 
    if {![info exists complex_type(multiflagcols)]} {
	set complex_type(multiflagcols) {
	    eval [list lappend res] [dialog::lines_to_text \
	      [dialog::width_linebreak $name [expr {$right - $left}]] \
	      $left $right y]
	    incr y 10
	    set flag_list [lindex $type 1]
	    set columns   [lindex $type 2]
	    if {![string length $columns]} {
		set columns 2
	    }
	    set i [expr {($left + $right - 30)/$columns}]
	    for {set c 1} {$c <= $columns} {incr c} {
		set l$c [expr {(($c - 1) * $i) + 20}]
		set r$c [expr {($c * $i) + 5}]
		set y$c $y
	    }
	    if {([lindex $type 3] == 1)} {
		# Order across rows.
		for {set c 0 ; set n 0} {$n < [llength $flag_list]} {incr n} {
		    set c [expr {$c % $columns + 1}]
		    lappend res -c [lindex $flag_list $n] [lindex $val $n]
		    lappend res -font 2
		    lappend res [set l$c] [incr y$c 3] [set r$c] [incr y$c 15]
		}
	    } else {
		# Order down columns.
		set defaultRows [expr {[llength $flag_list] / $columns}]
		set remainder   [expr {[llength $flag_list] % $columns}]
		set count 0
		for {set c 1} {$c <= $columns} {incr c} {
		    set offset [expr {$remainder > 0 ? 1 : 0}]
		    set cR$c   [expr {$defaultRows + $offset}]
		    incr remainder -1
		}
		set cR $cR1
		for {set c 1 ; set n 0} {$n < [llength $flag_list]} {incr n} {
		    if {(($n + 1) > $cR)} {
			incr c ; incr cR [set cR$c]
		    }
		    lappend res -c [lindex $flag_list $n] [lindex $val $n]
		    lappend res -font 2
		    lappend res [set l$c] [incr y$c 3] [set r$c] [incr y$c 15]
		}
	    }
	    set y [expr {$y1 + 5}]
	    while {[llength $help] < [llength $flag_list]} {
		lappend help ""
	    }
	    eval [list lappend helpL] $help
	    unset help
	    set script    [list dialog::valChanged $dial $page,$name]
	    append script { [lrange $res $count [incr count }
	    append script [expr {[llength $flag_list] - 1}] {]]}
	}
    }
}

# We need these special dialogs.

## 
 # --------------------------------------------------------------------------
 # 
 # "dialog::modesList"  --
 # 
 # Presents a checkbox listing all modes currently available.  Returns a
 # list of all modes checked by the user.
 # 
 # --------------------------------------------------------------------------
 ## 

proc dialog::modesList {{defaultModes ""} {title "Choose Modes"}} {

    # Create the list of modes in the list.
    set allModes     [mode::listAll]
    set checkedModes [list]
    set result       [list]
    foreach m [set allModes [mode::listAll]] {
	lappend checkedModes [llength [lsearch -inline $defaultModes $m]]
    }
    # Create the dialog.
    set     d1 [list dialog::make -title $title]
    set     d2 [list "Check any of the modes below."]
    lappend d2 [list [list multiflagcols $allModes 5 0] \
      "" $checkedModes]
    set values [eval $d1 [list $d2]]
    for {set n 0} {$n < [llength $allModes]} {incr n} {
	if {[lindex $values 0 $n]} {
	    lappend result [lindex $allModes $n]
	}
    }
    return $result
}

## 
 # --------------------------------------------------------------------------
 # 
 # "dialog::modesAllNoneList"  --
 # 
 # Similar to the above, but also allows the user to select 'All modes' or
 # 'No modes', in which case the returned list begins with 'all' or 'none.'
 # All of the checked modes are also included in the returned list, so that
 # this information is not deleted -- this allows the user to create a list
 # of modes, later turn them all off/on by selecting the global option, but
 # then revert back to using the checked list later if desired.
 # 
 # --------------------------------------------------------------------------
 ## 

proc dialog::modesAllNoneList {{defaultModes ""} {title "Choose Modes"}} {
    
    # Create the list of modes in the list.
    set allModes     [mode::listAll]
    set checkedModes [list]
    set result       [list]
    foreach m [set allModes [mode::listAll]] {
	lappend checkedModes [llength [lsearch -inline $defaultModes $m]]
    }
    set globalOpts [list \
      "Use modes checked belowÉ" \
      "Use all modes exceptÉ" "-" \
      "Use all modes available" \
      "Don't use any modes" ]
    # Are we using all modes?  No modes?  Even when these are selected,
    # the list of modes are still presented in checkboxes.
    if {([lsearch $defaultModes "exclude"] > -1)} {
	set globalOpt 1
    } elseif {([lsearch $defaultModes "all"] > -1)} {
	set globalOpt 3
    } elseif {([lsearch $defaultModes "none"] > -1)} {
	set globalOpt 4
    } else {
	set globalOpt 0
    }
    set optText1 "Selection method:"
    set optText2 "Which might use the modes listed below ..."
    set optText2 [string repeat "_" 45]
    # Create the dialog.
    set     d1 [list dialog::make -title $title]
    set     d2 [list ""]
    lappend d2 [list [list menuindex $globalOpts] $optText1 $globalOpt]
    lappend d2 [list [list multiflagcols $allModes 5 0] \
      $optText2 $checkedModes]
    set values [eval $d1 [list $d2]]
    switch -- [lindex $values 0] {
	1 {lappend result "exclude"}
	3 {lappend result "all"}
	4 {lappend result "none"}
    }
    for {set n 0} {$n < [llength $allModes]} {incr n} {
	if {[lindex $values 1 $n]} {
	    lappend result [lindex $allModes $n]
	}
    }
    return $result
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Preferences ×××× #
# 

namespace eval correction {
    foreach item [list doTypos doI] {
	variable $item
	if {![info exists $item]} {
	    set $item 0
	}
    }
    unset item
}

proc correction::initialize {} {
    
    global userCorrections
    
    # These used to be in the global scope, but now we keep them all in the
    # 'electricCorrectionsmodeVars' array.  This is mainly because they will
    # get put in there by [prefs::dialogs::packagePrefs].
    foreach pref [list smartI smartIModes correctTypos correctionsModes] {
	prefs::renameOld $pref electricCorrectionsmodeVars($pref)
    }

    # Automatically convert " i " to " I ".
    newPref flag smartI            {1} \
      electricCorrections {correction::rebuildMenu}
    # Automatically correct misspellings/typos for the specified modes.
    newPref flag correctTypos      {1} \
      electricCorrections {correction::rebuildMenu}
    # The "Smart i" correction will only take place for the modes listed
    # here.  If the list is empty, the correction take place for all modes.
    newPref allNoneModes smartIModes {Bib HTML TeX Text} \
      electricCorrections {correction::ensureValidPref}
    # Electric corrections only take place for the modes listed here.  If
    # the list is empty, corrections take place for all modes.
    newPref allNoneModes typoModes   {all} \
      electricCorrections {correction::ensureValidPref}
    
    # Make sure that our prefs are valid.  They changed in version 1.0 of this
    # package, so that an empty value is now 'all'.
    correction::ensureValidPref "smartIModes"
    correction::ensureValidPref "typoModes"
    
    correction::resetVariables
    
    # Create the initial array of corrections.  These need to be lower-case.
    # More could be added ...
    variable correctionsSet
    array set correctionsSet {
	hte "the"
    }
    # These are not yet defined as misspellings -- they're simply a list that
    # we can add (or remove) using the "Electric Corrections" menu.  We only
    # add them if the correction has not already been (re)defined in
    # "arrdefs.tcl"
    foreach typo [array names correctionsSet] {
	if {![info exists userCorrections($typo)]} {
	    correction::capitalizeTypo $typo $correctionsSet($typo)
	}
    }
    return
}

proc correction::resetVariables {{newMode ""}} {
    
    global electricCorrectionsmodeVars mode

    variable doTypos
    variable doI
    
    set typoModes    $electricCorrectionsmodeVars(typoModes)
    set smartIModes  $electricCorrectionsmodeVars(smartIModes)
    set smartI       $electricCorrectionsmodeVars(smartI)
    set correctTypos $electricCorrectionsmodeVars(correctTypos)
    
    if {![string length $newMode]} {
	if {![string length $mode]} {
	    return
	} else {
	    set newMode $mode
	}
    }
    
    # Typo mode?
    set isInTyposList [expr {[lsearch $typoModes $newMode] > -1 ? 1 : 0}]
    if {![string length $newMode] || !$correctTypos} {
	set doTypos 0
    } elseif {([lsearch $typoModes "all"] > -1)} {
	set doTypos 1
    } elseif {([lsearch $typoModes "none"] > -1)} {
	set doTypos 0
    } elseif {([lsearch $typoModes "exclude"] > -1)} {
	set doTypos [expr {1 - $isInTyposList}]
    } else {
	set doTypos $isInTyposList
    }
    # Smart I mode?
    set isInSmartIList [expr {[lsearch $smartIModes $newMode] > -1 ? 1 : 0}]
    if {![string length $newMode] || !$smartI} {
	set doI 0
    } elseif {([lsearch $smartIModes "all"] > -1)} {
	set doI 1
    } elseif {([lsearch $smartIModes "none"] > -1)} {
	set doI 0
    } elseif {([lsearch $smartIModes "exclude"] > -1)} {
	set doI [expr {1 - $isInSmartIList}]
    } else {
	set doI $isInSmartIList
    }
    return
}

# ===========================================================================
# 
# When called via the 'Electrics' dialog, make sure that the modes listed
# are valid.
# 

proc correction::ensureValidPref {prefName} {
    
    global electricCorrectionsmodeVars mode
    
    set exceptions [list "all" "none" "exclude"]
    if {![llength [set electricCorrectionsmodeVars($prefName)]]} {
	# A legacy from earlier versions.
	set electricCorrectionsmodeVars($prefName) "all"
    } else {
	set value $electricCorrectionsmodeVars($prefName)
	set modes [mode::listAll]
	foreach m $electricCorrectionsmodeVars($prefName) {
	    if {([lsearch $exceptions $m] > -1)} {
		continue
	    }
	    if {![lcontains modes $m]} {
		alertnote "'$m' is not a valid mode,\
		  and will be removed from the list for '$prefName'."
		set value [lremove $value [list $m]]
	    }
	}
	set electricCorrectionsmodeVars($prefName) $value
    }
    correction::resetVariables $mode
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Electric Correction menu procs ×××× #
# 

proc correction::buildCorrectionsMenu {} {
    
    global electricCorrectionsmodeVars
    
    set     menulist "viewCorrectionsÉ"
    lappend menulist "addCorrectionsÉ"
    lappend menulist "editCorrectionsÉ"
    lappend menulist "removeCorrectionsÉ"
    lappend menulist "(-)"
    # Toggleable menu item -- smart I preference.
    if {$electricCorrectionsmodeVars(smartI)} {
	lappend menulist "!¥smart i"
    } else {
	lappend menulist "smart i"
    }
    # Toggle the use of corrections.
    if {$electricCorrectionsmodeVars(correctTypos)} {
	lappend menulist "turnCorrectionsOff"
    } else {
	lappend menulist "turnCorrectionsOn"
    }
    lappend menulist "correctionsPrefsÉ" "(-)" "correctionsHelp"
    return [list build $menulist correction::menuProc {} "electricCorrections"]
}

proc correction::rebuildMenu {} {
    menu::buildOne electricCorrections
    return
}

proc correction::menuProc {menuName itemName} {
    
    global electricCorrectionsmodeVars mode
    
    if {($itemName == "smarti") || ($itemName == "smart i")} {
	# Flip the value of the "smartI" preference.
	set electricCorrectionsmodeVars(smartI) \
	  [expr {$electricCorrectionsmodeVars(smartI) ? 0 : 1}]
	prefs::modified electricCorrectionsmodeVars(smartI)
	correction::resetVariables $mode
	correction::rebuildMenu
	if {$electricCorrectionsmodeVars(smartI)} {
	    set onOrOff "on"
	} else {
	    set onOrOff "off"
	}
	set modes $electricCorrectionsmodeVars(smartIModes)
	if {![llength $electricCorrectionsmodeVars(smartIModes)]} {
	    set modes "all modes"
	}
	status::msg "The \"Smart i\" preference is currently $onOrOff for $modes."
    } elseif {[regsub {turnCorrections} $itemName {} onOrOff]} {
	# Flip the value of the "correctTypos" preference.
	if {($onOrOff == "off")} {
	    set electricCorrectionsmodeVars(correctTypos) "0"
	} else {
	    set electricCorrectionsmodeVars(correctTypos) "1"
	}
	prefs::modified electricCorrectionsmodeVars(correctTypos)
	correction::resetVariables $mode
	correction::rebuildMenu
	set onOrOff [string tolower $onOrOff]
	set modes $electricCorrectionsmodeVars(typoModes)
	if {![llength $electricCorrectionsmodeVars(typoModes)]} {
	    set modes "all modes"
	}
	status::msg "Automatic corrections have been turned $onOrOff for $modes ."
    } elseif {($itemName == "correctionsPrefs")} {
	prefs::dialogs::packagePrefs "electricCorrections"
    } elseif {($itemName == "correctionsHelp")} {
	package::helpWindow "elecCorrections"
    } else {
	# Just use the proc defined below.
	$itemName
    }
    return
}

# ===========================================================================
# 
# View Corrections
# 
# Place the names and elements of the array in a new window, and shrink it.
# 

proc correction::viewCorrections {} {
    
    global mode
    
    # Make sure that the list of lower typos is up to date.
    correction::lowercaseTypos
    
    set windows [winNames]
    foreach w $windows {
	# Close any open "* Corrections *" windows.
	if {[regexp "\\* Corrections \\*" [win::StripCount $w]]} {
	    bringToFront $w
	    killWindow
	}
    }
    if {([listArray userCorrections] == "")} {
	status::msg "There are currently no defined misspellings."
	return
    }
    # We only show the lower case typos / corrections
    new -n "* Corrections *" -text [listArray lowerTypos] -m $mode
    # if 'shrinkWindow' is loaded, call it to trim the output window.
    goto [minPos]
    insertText "Use the \"Edit Corrections\" \rmenu item to re-define them.\r\r"
    shrinkWindow 2
    winReadOnly
    status::msg ""
    return
}

# ===========================================================================
# 
# Add Corrections
# 
# Present the user with a dialog to create a new misspelling.
# 

proc correction::addCorrections {{title ""} {typo ""} {correction ""}} {
    
    set finish [correction::addCorrectionsDialog "" $typo $correction]
    # Offer the dialog again to add more.
    set title "Create another Correction, or press Finish:"
    while {$finish != "1"} {
	set finish [correction::addCorrectionsDialog $title]
    }
    correction::rebuildMenu
    correction::viewCorrections
    return
}

# ===========================================================================
# 
# Edit Corrections
# 
# Present the user with a dialog to edit a current misspelling.
# 

proc correction::editCorrections {} {
    
    global userCorrections lowerTypos
    
    # Make sure that the list of lower typos is up to date.
    correction::lowercaseTypos
    
    set typo [listpick -p "Select a Typo to edit:" \
      [array names lowerTypos]]
    set correction $userCorrections($typo)
    set title "Edit the \"$typo\" correction:"
    set finish [correction::addCorrectionsDialog $title $typo $correction]
    # Offer the dialog again to add more.
    while {$finish != "1"} {
	set typo [listpick -p \
	  "Select another Typo to edit, or Cancel:" \
	  [array names lowerTypos]]
	set correction $userCorrections($typo)
	set title "Edit the \"$typo\" correction:"
	set finish [correction::addCorrectionsDialog $title $typo $correction]
    }
    correction::viewCorrections
    return
}

# ===========================================================================
# 
# Remove Corrections
# 
# Present the user with a dialog to remove a current misspelling.
# 

proc correction::removeCorrections {{removeList ""}} {
    
    global userCorrections lowerTypos
    
    variable correctionsSet
    
    if {($removeList == "")} {
	# First list the user defined misspellings.
	set userTypos ""
	foreach typo  [array names userCorrections] {
	    set first [string tolower [string index $typo 0]]
	    set typo  [concat $first[string range $typo 1 end]]
	    if {![info exists correctionsSet($typo)]} {
		# We know that this is user defined.
		lappend userTypos $typo
	    } elseif {($userCorrections($typo) != $correctionsSet($typo))} {
		# We know that this has not been redefined.
		lappend userTypos $typo
	    }
	}
	if {![llength $userTypos]} {
	    status::msg "Cancelled -- there are no user defined misspellings to remove."
	    correction::rebuildMenu
	    return
	}
	set removeList [listpick -l -p "Select some Typos to remove:" \
	  [lunique $userTypos]]
    }
    set correctionsToRemove [list]
    foreach typo $removeList {
	lappend correctionsToRemove $typo
	# First create upper and lower case typo.
	set upperCaseTypo [string toupper [string index $typo 0]]
	append upperCaseTypo [string range $typo 1 end]
	lappend correctionsToRemove $upperCaseTypo
    }
    foreach typo $correctionsToRemove {
	if {[info exists userCorrections($typo)]} {
	    prefs::modified userCorrections($typo)
	    unset userCorrections($typo)
	}
	if {[info exists lowerTypos($typo)]} {
	    unset lowerTypos($typo)
	}
    }
    correction::viewCorrections
    return
}

proc correction::addCorrectionsDialog {{title ""} {typo ""} {correction ""}} {
    
    global userCorrections
    
    if {($title == "")} {
	set title "Create a new Correction, or redefine an existing one:"
    }
    set y 10
    set aCD [list -T $title]
    set yb 20
    
    eval lappend aCD [dialog::button   "Finish"                    300 yb   ]
    eval lappend aCD [dialog::button   "More"                      300 yb   ]
    incr yb 10
    eval lappend aCD [dialog::button   "Cancel"                    300 yb   ]
    if {($typo == "")} {
	eval lappend aCD [dialog::textedit "Typo :" $typo           10  y 25]
    } else {
	eval lappend aCD [dialog::text     "Typo :"                 10  y   ]
	eval lappend aCD [dialog::menu 10 y $typo $typo 200                 ]
    }
    eval lappend aCD [dialog::textedit "Correction :"  $correction  10  y 25]
    incr y 20
    set result [eval dialog -w 380 -h $y $aCD]
    if {[lindex $result 2]} {
	# User pressed "Cancel'
	error "cancel"
    }
    set finish     [lindex $result 0]
    set typo       [string trim [lindex $result 3]]
    set correction [lindex $result 4]
    if {($typo != "") && ($correction != "")} {
	set userCorrections($typo) $correction
	prefs::modified userCorrections($typo)
	# Add the Capitalized Typo if appropriate.
	correction::capitalizeTypo $typo $correction
	status::msg "\"$typo -- $correction\" has been added."
	return $finish
    } elseif {($finish == "1")} {
	return $finish
    } else {
	error "Cancelled -- one of the dialog fields was empty."
    }
    return
}

# ×××× Manipulating Corrections ×××× #

proc correction::capitalizeTypo {typo correction} {
    
    global userCorrections
    
    # Should we add an upper case correction?
    set first1 [string index $typo 0]
    if {[regexp {^[a-zA-Z]} $first1]} {
	set First1 [string toupper $first1]
	append Typo $First1 [string range $typo 1 end]
	set First2 [string toupper [string index $correction 0]]
	append Correction $First2 [string range $correction 1 end]
	set userCorrections($Typo) $Correction
	prefs::modified userCorrections($Typo)
	# Make sure that the list of lower typos is up to date.
	correction::lowercaseTypos
    }
    return
}

proc correction::lowercaseTypos {} {
    
    global userCorrections lowerTypos
    
    foreach typo  [array names userCorrections] {
	set first [string index $typo 0]
	set First [string toupper $first]
	if {![regexp {^[a-zA-Z]} $first] || ($first ne $First)} {
	    set lowerTypos($typo) $userCorrections($typo)
	}
    }
    return
}

# ===========================================================================
# 
# Unset Corrections List
# 
# Remove all of the pre-defined corrections.  This is not currently used in
# the menu, but if the pre-defined list was exanded, we would want to be able
# to add and remove the predefined list.
# 

proc correction::unsetCorrectionsList {} {
    
    global userCorrections
    
    variable correctionsSet
    
    set removeList ""
    foreach typo [array names correctionsSet] {
	if {![info exists userCorrections($typo)]} {
	    # The list has already been unset
	    status::msg "The pre-defined list of correction has already been unset."
	    return
	}
	if {($userCorrections($typo) == $correctionsSet($typo))} {
	    # We know that this has not been redefined.
	    lappend removeList $typo
	}
    }
    if {([llength $removeList] != "0")} {
	correction::removeCorrections $removeList
	correction::viewCorrections
	status::msg "The pre-defined list of corrections has been removed."
	
    } else {
	status::msg "There were no pre-defined corrections to remove."
    }
    return
}

# ===========================================================================
# 
# Restore Corrections List
# 
# Restore all of the pre-defined corrections.  This is not currently used in
# the menu, but if the pre-defined list was exanded, we would want to be able
# to add and remove the predefined list.
# 

proc correction::restoreCorrectionsList {} {
    
    variable correctionsSet
    
    foreach typo [array names correctionsSet] {
	correction::capitalizeTypo $typo $correctionsSet($typo)
    }
    correction::viewCorrections
    status::msg "The pre-defined list of corrections has been restored."
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Correct Typo ×××× #
# 
# This is all it takes to correct spelling mistakes as you type.  Note that
# even though this is only bound to Space Return, intermediate characters
# (such as , .  ; etc) are generally ignored when finding the last "word".
# This means that i.  should be corrected to I. as soon as the <space> or
# <return> keys are pressed, without disturbing the subsequent period.  This
# depends on the "wordBreak" preference of the current mode...
# 

proc correction::correctTypo {nextChar} {
    
    global userCorrections
    
    if {![llength [winNames]]} {
	# No window, so silently return.
	return
    } elseif {[win::getInfo [win::Current] read-only]} {
	if {($nextChar == " ")} {
	    scrollReadOnlyWindow
	} else {
	    beep ; status::msg "Read-only!"
	}
	return
    }

    variable doTypos
    variable doI
    
    if {[isSelection]} {
	deleteSelection
    } elseif {$doTypos || $doI} {
	# What was the word that was just entered?
	set pos0 [pos::lineStart]
	set txt1 [getText $pos0 [getPos]]
	append pat1 {[\t ]*(} [win::getModeVar [win::Current] wordBreak] \
	  {)([!?.,;:'"\)]*)$}
	if {[regexp -indices $pat1 $txt1 -> wordLimits]} {
	    set word [eval [list string range $txt1] $wordLimits]
	    set pat2 {([!?.,;:'"\)]*)$}
	    if {[regexp -indices $pat2 $txt1 -> puncLimits]} {
		set punc [eval [list string range $txt1] $puncLimits]
	    } else {
	        set punc ""
	    }
	    # Do we need to delete the word and insert a correction?
	    if {$doI && ($word == "i")} {
		# Smart i -- automatically change to I
		set correction "I"
	    } elseif {$doTypos && [info exists userCorrections($word)]} {
		# A defined typo -- automatically insert the correction.
		set correction $userCorrections($word)
	    }
	}
	# 
    }
    # Now insert the calling character, which was bound to this proc.  We
    # do this first, so that the first 'undo' will remove the 'correction.'
    set pos1 [getPos]
    if {[is::Eol $nextChar]} {
	bind::CarriageReturn
    } else {
	insertText $nextChar
    }
    set pos2 [getPos]
    if {![info exists correction]} {
	return
    }
    # Now replace with the correction.
    set txt2 [getText $pos1 $pos2]
    set len1 [pos::diff $pos1 $pos2]
    set pos3 [pos::math $pos0 + [lindex $wordLimits 0]]
    replaceText $pos3 $pos2 ${correction}${punc}${txt2}
    set len2 [string length $correction]
    set len3 [string length $word]
    goto [pos::math $pos1 + $len1 + $len2 - $len3]
    return
}

# These next two are provided mainly for when we are turned off.

proc spaceBar {} {
    
    if {![llength [winNames]]} {
	# No window, so silently return.
	return
    } elseif {![win::getInfo [win::Current] read-only]} {
	# Just insert a space (removing any selection if necessary.)
	typeText " "
    } else {
	scrollReadOnlyWindow
    }
    return
}

proc scrollReadOnlyWindow {} {
    
    global moveInsertion
    
    # Window is read-only, so scroll down one page.
    set oldMI $moveInsertion
    set moveInsertion 1
    set pos [getPos]
    pageForward
    set moveInsertion $oldMI
    if {[pos::compare $pos == [getPos]]} {
	# We're at the end of the window.  Should we kill it?
	set msg "At the window of the window.\rDo you want to close it?"
	if {[askyesno $msg]} {
	    killWindow
	}
    }
    return
}

# ===========================================================================
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ----- -----------
# 10/05/00 cbu 0.1   First version, named "mispellCorrect".
#                     "mispellCorrect" submenu is inserted in "Text" menu.
# 10/11/00 cbu 0.2    Renamed "elecCorrections".
#                     "electricCorrections" submenu is inserted in
#                       "Config > Packages" menu.
#                     Corrections are only bound to <space>, <return>.
#                     Added "Electric Corrections Help" file.
# 10/15/00 cbu 0.3    Numerous fixes, many from Vince (thanks!).
#                     Namespace is now "correction".
#                     Calling character is now inserted before typo correction.
# 10/20/00 cbu 0.3.1  Better [correction::correctTypo] cursor movement.
# 11/11/00 cbu 0.3.2  Users can now define a lower case typo with a capitalized
#                       correction. (thanks Bernard!)
#                     Back compatibility issue addressed with win::StripCount.
#                     Fixed "isSelection" bug, so that hilited selection will
#                       now delete without checking for a correction.
# 04/01/01 cbu 0.3.3  Better dialogs, especially with Alphatk/8.
# 06/01/01 cbu 0.4    Package is now a global-only feature, to allow for a
#                       de-activation script.
# 02/01/03 cbu 1.0    Various minor fixes throughout past year.
#                     Major update for Tcl 8.4 (which is now required).
#                     Preferences are no longer added to "Electrics" dialog pane.
#                     Special dialog for setting modes.
#                     We now do a check when switching modes to determine if
#                       we should en/disable both correctTypos and smartI.  This
#                       makes the [correction::correctTypo] procedure much more
#                       efficient.
#                     More efficient grabbing of the last word.  If there is any
#                       whitespace in front of the cursor, then we do nothing.
#                       The word must now be an exact match of something in the
#                       "::correctionsSet" array -- we don't count on the 'word'
#                       grabbed by [backwardWord|forwardWord] etc.  (There was a
#                       problem with '$i' being corrected to '$I in TeX mode.)
#                     Better replacement of correction, so that the first 'undo'
#                       will correctly replace text and position the cursor.
# 07/01/03 cbu 1.0.1  Package prefs now in "electricCorrectionsmodeVars" array.
# 09/02/03 cbu 1.0.2  Minor Tcl formatting changes.
# 09/08/03 cbu 1.0.3  Calling procs with full namespaces.
# 01/02/04 cbu 1.0.4  Make sure we call [correction::resetVariables] after
#                       changing the value of package preferences.
#                     Minor formatting changes in help, annotation.
# 01/28/05 cbu 1.1    [correction::correctTypo] uses mode's "wordBreak" pref.
#                     Better handling of typos that do not start with a letter.

# ===========================================================================
# 
# .