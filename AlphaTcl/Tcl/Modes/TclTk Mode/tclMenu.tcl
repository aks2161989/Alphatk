## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "tclMenu.tcl"
 #                                          created: 04/05/1997 {09:31:10 pm}
 #                                      last update: 04/18/2006 {12:37:45 PM}
 # Description:
 # 
 # Creation of and support for the Tcl menu.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Copyright (c) 1997-2006 Vince Darley
 # All rights reserved.
 # 
 # ==========================================================================
 ##

proc tclMenu.tcl {} {}

# Make sure that the "tclMode.tcl" file has been sourced.
tclMode.tcl

hook::register activateHook     {Tcl::activateHook} Tcl
hook::register changeMode       {Tcl::changeModeHook}

# The build proc for the main menu.
menu::buildProc tclMenu         {Tcl::buildMenu}
# Tcl submenu build procs.
menu::buildProc tcl-tkShells    {Tcl::buildSubmenu Shells}
menu::buildProc tclProcedures   {Tcl::buildSubmenu Procedures}
menu::buildProc tclNavigation   {Tcl::buildSubmenu Navigation}
menu::buildProc tclTracing      {Tcl::buildSubmenu Tracing} \
  {Tcl::postBuildTracing}
menu::buildProc tclIndices      {Tcl::buildSubmenu Indices}
menu::buildProc tclEditing      {Tcl::buildSubmenu Editing}
menu::buildProc tclProUtils     {Tcl::buildSubmenu ProUtils}
menu::buildProc tcl-tkHelp      {Tcl::buildSubmenu -tkHelp 0}

menu::buildProc tclModeOptions  {Tcl::buildOptionsMenu} \
  {Tcl::postBuildOptions}

namespace eval Tcl {
    
    global alpha::application alpha::macos
    
    variable menuItems
    
    # Main Menu
    set menuItems(MainMenu) [list \
      editProjectsÉ run getWikiCodeÉ switchToTclsh evaluate executeCommandÉ \
      displayErrorInfo getVarValueÉ]
    if {$alpha::macos != 1} {
	lappend menuItems(MainMenu) wrapProjectAsStarkitÉ wrapProjectAsStarpackÉ
    }
    # Tcl-tk Shell Windows
    set menuItems(Shells) [list \
      "${alpha::application}TclShell" remoteTclShell]
    if {${alpha::platform} == "tk"} {
        lappend menuItems(Shells) tkconShell
    }
    # Tcl Procedures
    set menuItems(Procedures) [list \
      reloadProc reformatProc selectProc prevProc nextProc (-) \
      findProcDefinitionÉ quickFindProcÉ (-) \
      debugProcÉ applyProcChanges]
    # Tcl Tracing
    set menuItems(Tracing) [list \
      traceThisProc traceTclProcÉ stopTracing displayTraces]
    # Tcl Indices
    set menuItems(Indices) [list \
      rebuildTclIndexForWin rebuildTclIndices]
    # Tcl Editing
    set menuItems(Editing) [list \
      addRemoveDollars insertDivider (-) \
      regularExpressionColors defaultColors]
    # Tcl Help
    set menuItems(-tkHelp) [list \
      "Tcl-tk Command HelpÉ" "Tcl 8.4 Commands" "Regular Expression Syntax" \
      (-) "Tcl Home Page" "Tcl Mode Help"]
    # Tcl Pro Utils
    set menuItems(ProUtils) [list \
      debugInTclPro launchTclProDebugger]
    # Default Key Bindings
    array set defaultBindings {
        switchToTclsh           /-<O<U
        evaluate                /L<O
        executeCommandÉ         /L<O<U
        displayErrorInfo        /E<U<B
        
        reloadProc              /L<O<B
        reformatProc            /I<O<B
        selectProc              /S<U<B
        prevProc                /P<U<B
        nextProc                /N<U<B
        findProcDefinitionÉ     /P<O<U
        quickFindProcÉ          /Q<O<B
        
	traceThisProc           /Z<O<B
	traceTclProcÉ           /Z<O<U
	displayTraces           /D<O<U

	addRemoveDollars        /4<B
	insertDivider           /3<B
    }
    # (special cases.)
    set "defaultBindings(${alpha::application}TclShell)" /Y<O
    if {${alpha::macos}} {
	set defaultBindings(remoteTclShell) /Y<O<I
    } else {
	set defaultBindings(remoteTclShell) /Y<O<B
    }
    # Binding Preferences
    foreach menuName [array names menuItems] {
        foreach item $menuItems($menuName) {
            if {[regexp -- {(\s)|(\(\-\))} $item]} {
                continue
            } elseif {[info exists defaultBindings($item)]} {
                set binding $defaultBindings($item)
            } else {
                set binding ""
            }
            newPref menubinding $item $binding tcl${menuName}Bindings
        }
	global tcl${menuName}BindingsmodeVars
	if {[array exists tcl${menuName}BindingsmodeVars]} {
	    newPref flag activateBindingsInTclModeOnly 1 tcl${menuName}Bindings
	}
    }
    # Cleanup
    unset -nocomplain menuName item binding
}

# ===========================================================================
#
# ×××× Tcl Menu ×××× #
# 

proc Tcl::buildMenu {} {
    
    global TclmodeVars Tclprojects tclMainMenuBindingsmodeVars tclMenu
    
    variable interpCmd [getInterp]
    variable menuItems
    
    # Projects.
    if {[set proj [project]] == "" || $proj == "AlphaTcl"} {
	lappend menuList "internalInterpreter"
    } else {
	set app [lindex [projectInfo $proj] 3]
	if {$app != ""} {
	    set tail [file tail $app]
	} else {
	    set tail "Tcl"
	}
	lappend menuList "${tail}: $TclmodeVars(project)"
    }
    if {[array size Tclprojects] > 0} {
	lappend menuList \
	  [menu::makeFlagMenu "tcl-tk projects" list project TclmodeVars] \
	  "editProjectsÉ"
    }
    # Evaluating, Shell windows, etc.
    lappend menuList \(- run getWikiCodeÉ switchToTclsh \
      [list Menu -n "tcl-tkShells" {}] \
      "(-)" evaluate executeCommandÉ
    if {$alpha::macos != 1} {
	lappend menuList wrapProjectAsStarkitÉ wrapProjectAsStarpackÉ
    }
    lappend subMenus "tcl-tkShells"
    # Submenus.
    lappend menuList "(-) "
    set extras [list \
      Procedures Tracing Indices Editing ProUtils -tkHelp ModeOptions]
    # As of this writing, the 'ProUtils' items are not available in the
    # Classic MacOS.
    if {$alpha::macos == 1} {
	set extras [lremove $extras ProUtils]
	unset -nocomplain menuItems(ProUtils)
    }
    foreach item $extras {
	lappend subMenus tcl${item}
	lappend menuList [list Menu -n tcl${item} {}]
    }
    # Final section, miscellaneous items.
    lappend menuList "(-)  " displayErrorInfo getVarValueÉ
    # Add key bindings.
    for {set idx 0} {[lindex $menuList $idx] != ""} {incr idx} {
	set item [lindex $menuList $idx]
	if {[info exists tclMainMenuBindingsmodeVars($item)]} {
	    set binding $tclMainMenuBindingsmodeVars($item)
	    set menuList [lreplace $menuList $idx $idx ${binding}${item}]
	}
    }
    # Set the menu proc, and return the list.
    if {$tclMainMenuBindingsmodeVars(activateBindingsInTclModeOnly)} {
        set menuProc {Tcl::tclMenuProc}
    } else {
	set menuProc {Tcl::tclMenuProc -M Tcl}
    }
    return [list build $menuList $menuProc $subMenus $tclMenu]
}

proc Tcl::buildSubmenu {menuName {menuConversion 1}} {
    
    global tcl${menuName}BindingsmodeVars
    
    variable menuItems
    
    # This list contains all items, dividers, etc.
    set menuList  $menuItems($menuName)
    set menuPrefs tcl${menuName}BindingsmodeVars
    set abitmo    "activateBindingsInTclModeOnly"
    # Add key bindings.
    for {set idx 0} {[lindex $menuList $idx] != ""} {incr idx} {
	set item [lindex $menuList $idx]
	if {[info exists [set menuPrefs]($item)]} {
	    set binding [set [set menuPrefs]($item)]
	    set menuList [lreplace $menuList $idx $idx ${binding}${item}]
	}
    }
    # Set the menu proc, and return the list.
    set menuProc "Tcl::tcl${menuName}MenuProc"
    if {[info exists ${menuPrefs}($abitmo)] && [set [set menuPrefs]($abitmo)]} {
	append menuProc " -M Tcl"
    }
    if {!$menuConversion} {
	append menuProc " -m"
    }
    return [list build $menuList $menuProc]
}

proc Tcl::buildOptionsMenu {} {

    variable prefsInMenu

    set menuList [concat $prefsInMenu (-) tclMenuBindingsÉ]
    return [list build $menuList Tcl::tclModeOptionsProc {}]
}

proc Tcl::postBuildTracing {} {
    
    variable inTracing
    variable traceInfo
    
    if {$inTracing} {
	enableMenuItem tclTracing "traceTclProcÉ" 0
	enableMenuItem tclTracing "traceThisProc" 0
	enableMenuItem tclTracing "stopTracing"   1
    } else {
	enableMenuItem tclTracing "traceTclProcÉ" 1
	enableMenuItem tclTracing "traceThisProc" 1
	enableMenuItem tclTracing "stopTracing"   0
    }
    if {$traceInfo != 0} {
	enableMenuItem tclTracing "displayTraces" 1
    } else {
	enableMenuItem tclTracing "displayTraces" 0
    }
}

proc Tcl::postBuildOptions {} {
    
    global TclmodeVars

    variable prefsInMenu

    foreach item $prefsInMenu {
	if {[regexp -- {\(\-\)} $item]} {
	    continue
	} elseif {![info exists TclmodeVars($item)]} {
	    enableMenuItem tclModeOptions $item 0
	} else {
	    markMenuItem tclModeOptions $item $TclmodeVars($item) Ã
	}
    }

}

# ===========================================================================
#
# ×××× Tcl Menu support ×××× #
# 

proc Tcl::tclMenuProc {menuName itemName} {
    
    global tclMenu alpha::platform
    
    if {($menuName != $tclMenu) && ($menuName != "Tcl")} {
	return [${menuName}MenuProc $menuName $itemName]
    }
    switch -glob -- $itemName {
	"internalInterpreter" {
	    alertnote "Tcl mode is currently attached to the internal\
	      interpreter of the AlphaTcl library\
	      -- all evaluations of code will apply to it."
	}
	"*:*" {
	    alertnote "Tcl mode is currently attached to $itemName\
	      -- all evaluations of code will apply to it."
	}
        "getWikiCode" {
            set pagenum [prompt "Which Tcl'ers Wiki page?" ""]
            edit -c [Tcl::getWikiCode $pagenum]
        }
	"run" {
	    tcltk::run
	}
	"switch*" {
	    set v "[string tolower [string range $itemName 8 end]]Sig"
	    global $v
	    app::launchFore [set $v]
	}
	"displayErrorInfo" {
	    new -n {* Error Info *} -m Tcl -info [evaluate [list set errorInfo]]
	    shrinkWindow 1
	}
	"executeCommand" {
	    set p "Please enter the script to evaluate in "
	    if {[set interp [getInterp]] == "tcltk::internalEvaluate"} {
		switch -- ${alpha::platform} {
		    "alpha" {append p "Alpha:"}
		    "tk"    {append p "Alphatk:"}
		}
	    } else {
		append p "$interp"
	    }
	    if {[isSelection]} {
		set script [string trim [getSelect]]
		# Turn this into one long string, separating lines by ';; '
		regsub -all -- "\[\r\n\]+\[\t \]*" $script ";; " script
		# Remove all comments.
		regsub -all -- {(^|;;)[\t ]*\#[^;]*(;;|$)} $script {} script
		# Remove all empty lines.
		regsub -all -- {(^|;;)[\t ]*(;;|$)} $script {} script
		# Change double semis back into singles
		regsub -all -- {;;} $script {;} script
	    } else {
		set script ""
	    }
	    set script [getline $p [string trim $script]]
	    if {![string length [string trim $script]]} {
		status::msg "Cancelled -- no script entered."
		return
	    } else {
		# Evaluate, and return the results.
		set result [tcltk::evaluateIn $interp $script]
		if {![string length $result]} {set result "(none)"}
		dialog::alert "Result was:\r$result"
	    }
	}
	default {
	    namespace eval ::Tcl $itemName
	}
    }
}

proc Tcl::tclShellsMenuProc {menuName itemName} {
    
    global alpha::application
    
    set alphaTclShell "[string tolower ${alpha::application}TclShell]"
    if {([string tolower $itemName] eq $alphaTclShell)} {
        ::tclShell
    } else {
        namespace eval ::Tcl $itemName
    }
}

proc Tcl::tclProceduresMenuProc {menuName itemName} {
    
    switch -glob -- $itemName {
	"reloadProc" {
	    procs::loadEnclosing [getPos]
	}
	"reformatProc" {
	    procs::reformatEnclosing [getPos]
	}
	"selectProc" {
	    function::select
	}
	"prevProc" {
	    function::prev
	}
	"nextProc" {
	    function::next
	}
	"findProcDefinition" {
	    procs::findDefinition
	}
	"quickFindProc" {
	    procs::quickFindDefn
	}
	"tcl-tkCommandHelp" {
	    variable tclCommands
	    variable tkCommands
	    set p "Enter a Tcl/Tk command for which you want help:"
	    if {[isSelection]} {set d [getSelect]} else {set d ""}
	    set c [prompt $p $d]
	    set v [concat $tclCommands $tkCommands]
	    if {[lsearch $v $c] == -1} {
		status::msg "'$c' is not a defined Tcl/Tk command."
	    } else {
		Tcl::DblClickHelper $c
	    }
	}
	"debugProc" {
	    set func [procs::pick 1]
	    procs::debug $func
	}
	"applyProcChanges" {
	    set w [win::Current]
	    if {[regexp -- {\* Debug of (.*) \*( <[0-9]+>)?} $w "" proc]} {
		set f [procs::searchFor $proc]
		if {[string length $f]} {
		    if {![catch {procs::replace $f $proc 0}]} {
			bringToFront $w
			setWinInfo -w $w dirty 0
			killWindow
		    }
		} else {
		    status::msg "Couldn't find $proc"
		}
	    } else {
		status::msg "No debug window is foremost"
	    }
	}
	default {
	    namespace eval ::Tcl $itemName
	}
    }
}

proc Tcl::tclTracingMenuProc {menuName itemName} {
    
    switch -- $itemName {
	"stopTracing" {
	    # Calling this again will end the traces.
	    traceTclProc
	}
	"displayTraces" {
	    dumpTraces
	}
	"displayErrorInfo" {
	    new -n {* Error Info *} -m Tcl -info [evaluate [list set errorInfo]]
	    shrinkWindow 1
	}
	default {
	    namespace eval ::Tcl $itemName
	}
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "Tcl::tclIndicesMenuProc" --
 # 
 # 'rebuildTclIndexForWin' menu item --
 # 
 # If the file is in Alpha's source tree, use the currently loaded
 # auto_mkindex.  If it is not, then fire up a separate Tcl application and
 # use its auto_mkindex (i.e. the standard Tcl one).  It just occured to me
 # that for Tcl >= 8.0, we could create a new interp, and execute
 # auto_mkindex within that to the same effect, but without the overhead of
 # a whole new process (especially a Tk one!).
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::tclIndicesMenuProc {menuName itemName} {
    
    switch -- $itemName {
	"rebuildTclIndexForWin" {
	    set dir [file dirname [win::Current]]
	    if {[alpha::inAlphaHierarchy [win::Current]]} {
		auto_mkindex $dir
		auto_reset
	    } else {
		# This will currently launch a Tk shell, which isn't ideal.
		tcltk::launchNewShell [list auto_mkindex $dir] "exit"
	    }
	    set dir [file tail $dir]
	    status::msg "Tcl index for the directory \"$dir\" has been rebuilt."
	}
	default {
	    namespace eval ::Tcl $itemName
	}
    }
}

proc Tcl::tclEditingMenuProc {menuName itemName} {
    
    switch $itemName {
	"addRemoveDollars" {
	    if {[lookAt [set pos [pos::prevChar]]] == "\)"} {
		goto [matchIt "\)" [pos::prevChar $pos]]
		goto [pos::math $pos +1 + [togglePrefix $]]
	    } else {
		togglePrefix $
	    }
	}
	"insertDivider" {
	    set pat1 "# ××××"
	    set pat2 "×××× #"
	    set pos1 [pos::lineStart]
	    set pos2 [pos::lineEnd]
	    set txt1 [getSelect]
	    set txt2 [getText $pos1 $pos2]
	    if {[regexp "^\\s*${pat1}\[-\\s\]+${pat2}\\s*$" $txt2]} {
		typeText "--------"
	    } elseif {![string length $txt1]} {
		elec::Insertion "$pat1 ¥¥ $pat2"
		bind::IndentLine
	    } else {
		deleteText $pos1 $pos2
		elec::Insertion "$pat1 $txt1 $pat2"
		bind::IndentLine
	    }
	}
	default {
	    namespace eval ::Tcl $itemName
	}
    }
}

proc Tcl::tclProUtilsMenuProc {menuName itemName} {
    
    global TclprojectEvalCmd
    
    switch -- $itemName {
	"debugInTclPro" {
	    set project [project]
	    set file [lindex [projectInfo] 1]
	    set sig [lindex [projectInfo] 3]
	    if {![string length $file]} {
		status::msg "Debugging current window"
		set file [win::Current]
		setProject [set project "Current Window"]
		set sig [lindex [projectInfo] 3]
	    }
	    if {![string length [set file [tcltk::ensureFile $file]]]} {
		return
	    }
	    if {![alphadebug::isDebuggerRunning]} {
		alphadebug::startDebugServer
	    }
	    set in [alphadebug::startDebug $file]
	    set TclprojectEvalCmd($project) $in
	}
	"launchTclProDebugger" {
	    if {![alphadebug::isDebuggerRunning]} {
		alphadebug::startDebugServer
	    }
	}
	default {
	    namespace eval ::Tcl $itemName
	}
    }
}

proc Tcl::tcl-tkHelpMenuProc {menuName itemName} {
    
    global TclmodeVars
    
    variable tclCommands
    variable tkCommands
    
    switch -glob -- $itemName {
	"Tcl-tk Command Help" {
	    set p "Enter a Tcl/Tk command for which you want help:"
	    if {[isSelection]} {
		set command [getSelect]
	    } else {
		set command ""
	    }
	    set command [prompt $p $command]
	    if {([lsearch [concat $tclCommands $tkCommands] $command] == -1)} {
		error "Cancelled - '$command' is not a defined Tcl/Tk command."
	    } else {
		Tcl::DblClickHelper $command
	    }
	}
	"Tcl 8.4 Commands" {
	    help::openFile $itemName
	}
	"Regular Expression Syntax" {
	    if {$TclmodeVars(useTextFileForTclCommandHelp)} {
		help::openFile "Regular Expressions"
		return
		# Another option:
		help::openGeneral "Tcl 8.4 Commands" "re_syntax"
		return
	    }
	    set localDir [file join $TclmodeVars(tcl/TkHelpLocalFolder) TclCmd]
	    if {[file isdir $localDir]} {
		htmlView [file join $localDir re_syntax.htm]
	    } else {
		urlView $TclmodeVars(tcl/TkHelpUrlDir)/TclCmd/re_syntax.htm
	    }
	    return
	}
	"Tcl Home Page" {
	    urlView $TclmodeVars(tclHomePage)
	}
	"Tcl Mode Help" {
	    package::helpWindow "Tcl"
	}
	default {
	    error "Unknown menu item: $itemName"
	}
    }
}

proc Tcl::tclModeOptionsProc {menuName itemName} {
    
    global TclmodeVars mode
    
    variable prefsInMenu
    
    if {[getModifiers]} {
	# Poor man's balloon help.
	switch -- $itemName {
	    "tclMenuBindings" {
		set txt "Use this item to change menu bindings."
	    }
	    "tclModeHelp" {
		set txt "Use this item to open the \"Tcl-Tk Help\" file."
	    }
	    default {
		set txt [help::prefString $itemName "Tcl"]
		if {[info exists TclmodeVars($itemName)]} {
		    if {$TclmodeVars($itemName)} {
			set end "on"
			regsub {^.*\|\|} $txt {} txt
		    } else {
			set end "off"
			regsub {\|\|.*$} $txt {} txt
		    }
		    if {$end == "on"} {
			set msg "The '$itemName' preference\
			  for Tcl mode is currently $end."
		    }
		}
	    }
	}
    } elseif {$itemName == "tclModeHelp"} {
	package::helpWindow "Tcl"
    } elseif {[lsearch $prefsInMenu $itemName] > -1} {
	# Flip the flag preference.
	set TclmodeVars($itemName) [expr $TclmodeVars($itemName) ? 0 : 1]
	if {($mode == "Tcl")} {
	    synchroniseModeVar $itemName $TclmodeVars($itemName)
	} else {
	    prefs::modified TclmodeVars($itemName)
	}
	# Anything else to do?  (This will update the menu.)
	Tcl::updatePreferences $itemName
	# Create a message.
	if {$TclmodeVars($itemName)} {
	    set msg "The \"$itemName\" preference is now turned on."
	} else {
	    set msg "The \"$itemName\" preference is now turned off."
	}
    } else {
	namespace eval ::Tcl $itemName
    }
    if {[info exists txt]} {alertnote $txt}
    if {[info exists msg]} {status::msg $msg}
}

proc Tcl::tclMenuBindings {} {
    
    variable menuItems
    
    foreach menuName [array names menuItems] {
	switch -- $menuName {
	    "MainMenu" {set listPickName "Main Tcl Menu"}
	    "Shells"   {set listPickName "Tcl-tk Shells"}
	    default    {set listPickName [quote::Prettify "tcl$menuName"]}
	}
	global tcl${menuName}BindingsmodeVars
	if {![array exists tcl${menuName}BindingsmodeVars]} {continue}
	lappend menuNames $listPickName
	set menuNameConnect($listPickName) $menuName
    }
    set l [set menuNames [lsort $menuNames]]
    set p {Choose a menu to set bindings:}
    while {1} {
	if {[catch {listpick -p $p $l} menuName] || $menuName == "Finish"} {
	    break
	}
	set menuName $menuNameConnect($menuName)
	set pkgName  tcl${menuName}Bindings
	switch -- $menuName {
	    "MainMenu" {set menuName "tclMenu"}
	    "Shells"   {set menuName "tcl-tkShells"}
	    default    {set menuName "tcl$menuName"}
	}
	set title "'[quote::Prettify $menuName]' menu bindings"
        if {![catch {prefs::dialogs::packagePrefs $pkgName}]} {
	    menu::buildSome $menuName
	    status::msg "The '[quote::Prettify $menuName]' menu has been rebuilt."
	}
	set l [concat "Finish" $menuNames]
	set p {Choose another, or Finish:}
    }
}

# ===========================================================================
#
# ×××× Tcl Menu hooks ×××× #
# 

proc Tcl::activateHook {name} {

    set dim1 [regexp -- {\* Debug of} $name]
    set dim2 [win::IsFile $name]
    enableMenuItem tclProcedures applyProcChanges        $dim1
    enableMenuItem tclIndices    rebuildTclIndexForWin   $dim2
    
    # This will adjust the current project, and set the Tcl mode internal
    # 'interpCmd' variable which is used quite a bit.
    Tcl::synchroniseProjectHook $name
    variable interpCmd [Tcl::getInterp]
}

proc Tcl::changeModeHook {newMode} {
    
    global tclMenu

    if {![string length $newMode]} {
        # We'll let the open windows hook deal with this.
        return
    }
    
    global global::features

    if {![lcontains global::features tclMenu] && \
      ![mode::isFeatureActive $newMode tclMenu]} {
	return
    }
    set dim1 [expr {$newMode == "Tcl" ? 1 : 0}]
    set dim2 [expr {[Tcl::isShellWindow] || $dim1 ? 1 : 0}]

    enableMenuItem tclProcedures reloadProc              $dim1
    enableMenuItem tclProcedures reformatProc            $dim1
    enableMenuItem tclProcedures selectProc              $dim1
    enableMenuItem tclProcedures prevProc                $dim1
    enableMenuItem tclProcedures nextProc                $dim1
    enableMenuItem tclProcedures applyProcChanges        $dim1
    enableMenuItem tclTracing    traceThisProc           $dim2
    enableMenuItem tclIndices    rebuildTclIndexForWin   $dim2
    enableMenuItem $tclMenu      tclEditing              $dim2
    enableMenuItem tclEditing    insertDivider           $dim1
    enableMenuItem tclEditing    regularExpressionColors $dim1
    enableMenuItem tclEditing    defaultColors           $dim1
}

proc Tcl::registerOWH {{which "register"}} {
    
    global tclMenu
    
    # Create the lists of items to dim when no open windows.
    set ${::tclMenu}Items  [list "evaluate" "tclEditing"]
    set tclProceduresItems [list \
      "reloadProc" "reformatProc" "selectProc" \
      "prevProc" "nextProc" "applyProcChanges"]
    set tclTracingItems    [list "traceThisProc"]
    set tclIndicesItems    [list "rebuildTclIndexForWin"]
    # Register these items.
    foreach menuName [list $tclMenu Procedures Tracing Indices] {
	if {($menuName != $tclMenu)} {set menuName tcl${menuName}}
	foreach itemName [set ${menuName}Items] {
	    hook::${which} requireOpenWindowsHook [list $menuName $itemName] 1
	}
    }
}

# ×××× Misc ×××× #

proc Tcl::getWikiCode {num} {
    package require http
    global out
    set filename [temp::path wikitcl $num.tcl]
    set out [open $filename w]
    Tcl::reap $num
    close $out
    return $filename
}

proc Tcl::_output {data} {
    global out
    # we don't want to throw an error if output channel has been closed
    catch { puts $out $data }
}

# Factoring out the postamble for clarity and ease of change.
proc Tcl::postamble { } {
    Tcl::_output \n
    Tcl::_output "# EOF"
    Tcl::_output \n
}

# Factoring out the preamble for clarity and ease of change.
proc Tcl::preamble {title url now updated} {
    Tcl::_output "#####"
    Tcl::_output "#"
    Tcl::_output "# \"$title\""
    Tcl::_output "# [string map [list mini.net/tcl wiki.tcl.tk] $url]"
    Tcl::_output "#"
    Tcl::_output "# Tcl code harvested on:  $now GMT"
    Tcl::_output "# Wiki page last updated: $updated"
    Tcl::_output "#"
    Tcl::_output "#####"
    Tcl::_output \n
}

proc Tcl::reap {page} {
    set url  http://mini.net/tcl/[ns_urlencode $page]
    set now  [clock format [clock seconds] -format "%e %b %Y, %H:%M" -gmt 1]
    set html [ns_geturl $url]

    # can't imagine why these characters would be in here, but just to be safe
    set html [string map [list \x00 "" \x0d ""] $html]
    set html [string map [list <pre> \x00 </pre> \x0d] $html]

    if {![regexp -nocase {<title>([^<]*)</title>} $html => title]} {
        set title "(no title!?)"
    }

    if {![regexp -nocase {<i>Updated on ([^G]+ GMT)} $html => updated]} {
        set updated "???"
    }

    Tcl::preamble $title $url $now $updated
    set html [ns_striphtml -tags_only $html]

    foreach chunk [regexp -inline -all {\x00[^\x0d]+\x0d} $html] {
        set chunk [string range $chunk 1 end-1]
        set chunk [string map [list "&quot;" \x22 \
                "&amp;"  &    \
                "&lt;"   <    \
                "&gt;"   >] $chunk]

        foreach line [split $chunk \n] {
            if {[string index $line 0] == " "} {
                set line [string range $line 1 end]
            }
            Tcl::_output $line
        }
    }
    Tcl::postamble
}

proc ns_geturl {url} {
    set conn [http::geturl $url]
    set html [http::data $conn]
    http::cleanup $conn
    return $html
}

proc ns_striphtml {-tags_only html} {
    regsub -all -- {<[^>]+>} $html "" html
    return $html ;# corrected a typo here
}

proc ns_urlencode {string} {
    set allowed_chars  {[a-zA-Z0-9]}
    set encoded_string ""

    foreach char [split $string ""] {
        if {[string match $allowed_chars $char]} {
            append encoded_string $char
        } else {
            scan $char %c ascii
            append encoded_string %[format %02x $ascii]
        }
    }

    return $encoded_string
}

# ===========================================================================
# 
# .