## -*-Tcl-*-
 # ==========================================================================
 #  Perl mode - an extension package for Alpha
 # 
 #  FILE: "perlMenu.tcl"
 #                                    created: 08/17/1994 {09:12:06 am} 
 #                                last update: 01/19/2005 {01:29:23 PM}
 #  Description: 
 #  
 #  Creating the Perl menu.
 #  
 #  See the "perlVersionHistory.tcl" file for license info, credits, etc.
 #  
 # ==========================================================================
 ## 

# load main Perl file!
perlMenu

proc perlMenu.tcl {} {}

namespace eval Perl {}

# ===========================================================================
# 
# ×××× Build the Perl Menu ×××× #
#            

menu::buildProc perlMenu 	{Perl::buildPerlMenu}
menu::buildProc perlFilterMenu 	{Perl::buildScriptsMenu "perlTextFilters"}
menu::buildProc perlLibMenu 	{Perl::buildScriptsMenu "perlLibScripts" }
menu::buildProc perlPathMenu 	{Perl::buildScriptsMenu "perlPathScripts"}

set menu::posteval(perlMenu)    {Perl::postEval}

proc Perl::buildPerlMenu {} {
    
    global perlMenu PerlmodeVars Perl::PrefsInMenu1 Perl::PrefsInMenu2
    
    # Create the subMenus lists.
    set tellItems [list                 \
      "/O<UOpen This File"              \
      "Save As Droplet"                 \
      "Save As Runtime"                 \
      "Save As CGI"                     \
      "(-)"                             \
      "Get Output Window"               \
      "Close Output Window"             \
      "Quit"                            ]
    set saveItems [list                 \
      "Droplet"                         \
      "Runtime"                         \
      "CGI"                             ]
    set helpItems [list                 \
      "Perl Home Page"                  \
      "(-)"                             \
      "/t<BPerl Mode Help"              \
      "MacPerl Help"                    \
      "Perl 4 Manual"                   \
      "Perl 5 Manual -- local"          \
      "Perl 5 Manual -- www"            \
      "(-)"                             \
      "/t<UWWW Command HelpÉ"           \
      "/t<U<BLocal Command HelpÉ"       ]
    set filterItems [list               \
      "Select Buffer As Filter"         \
      "Select File As Filter"           ]
    set filterPrefs [concat             \
      [set Perl::PrefsInMenu2] "(-)" "lastFilterUsedÉ"]
    if {$PerlmodeVars(includeLocalLibMenu) || $PerlmodeVars(includePerlPathMenu)} {
        lappend filterPrefs "rebuildFiltersMenus"
        if {$PerlmodeVars(includePerlPathMenu)} {
            lappend filterPrefs  "(-)"   \
              "viewSearchPathsÉ" "addSearchPathsÉ" "removeSearchPathsÉ"
        }
    } else {
        lappend filterPrefs "rebuildFiltersMenu"
    }
    set prefItems   [set Perl::PrefsInMenu1]
    set insertItems [list               \
      "/2<BAdd Remove \@"               \
      "/4<BAdd Remove \$"               \
      "/3<BInsert Divider"              \
      "(-)"                             \
      "/'<E<S<BNew Comment"             \
      "/'<S<O<BComment TemplateÉ"       ]
    set navItems [list                  \
      "/N<U<BNext Command"              \
      "/P<U<BPrev Command"              \
      "/S<U<BSelect Command"            \
      "/I<O<BReformat Command"          ]
    
    # The remaining subMenus are built using buildProcs.
    set subMenus [list perlFilterMenu]
    if {$PerlmodeVars(includeLocalLibMenu)} {lappend subMenus "perlLibMenu"}
    if {$PerlmodeVars(includePerlPathMenu)} {lappend subMenus "perlPathMenu"}
    
    # Now create that Perl menu list.
    set menuList [list "/-<UswitchToPerl"]
    lappend menuList "Menu -m -n {tellPerl}    -p Perl::tellPerl \"$tellItems\""
    lappend menuList "Menu -m -n {quickSaveAs} -p Perl::perlSave \"$saveItems\""
    lappend menuList "Menu -m -n {perlHelp}    -p Perl::perlHelp \"$helpItems\""
    lappend menuList                    \
      "(-)"                             \
      "runTheSelection"                 \
      "/R<O<UrunTheBuffer"              \
      "/R<O<BsaveAndRun"                \
      "runAFileÉ"                       \
      "(-)"                             \
      "selectFileAsFilterÉ"             \
      "selectBufferAsFilterÉ"           \
      "/F<U<BrepeatLastFilter"
    lappend menuList [list Menu -n {perlTextFilters} {}]
    if {$PerlmodeVars(includeLocalLibMenu)}  {
        lappend subMenus "perlLibMenu"
        lappend menuList [list Menu -n {perlLibScripts} {}]
    }
    if {$PerlmodeVars(includePerlPathMenu)} {
        lappend subMenus "perlPathMenu"
        lappend menuList [list Menu -n {perlPathScripts} {}]
    }
    lappend menuList                    \
      "(-)"                             \
      "Menu -n {perlFilterOptions} -p Perl::optionsProc \"$filterPrefs\""       \
      "Menu -n {perlModeOptions}   -p Perl::optionsProc \"$prefItems\""         \
      "collectIdentifiers"              \
      "regularExpressionColors"         \
      "defaultColors"                   \
      "(-)"                             \
      "Menu -n {perlInsertions} -p Perl::menuProc \"$insertItems\""             \
      "Menu -n {perlNavigation} -p Perl::menuProc \"$navItems\""
    
    Perl::registerOWH "register"
    
    return [list build $menuList Perl::menuProc $subMenus $perlMenu]
}

# ===========================================================================
# 
# ×××× Scripts Menus Builders ×××× #
# 
# Build a submenu of "preattached" Perl filters using the names of the
# scripts in the Text Filters directory, as well as those contained in
# the local Perl application's library, and anything else set by the user
# (either with the Perl preference 'perlLibFolder' or by the "Search
# Paths" preference.  Menu is rebuilt whenever Perl Lib folder is
# reassigned.
#

proc Perl::buildScriptsMenu {menuName} {
    
    global PerlmodeVars PerlSearchPath
    
    switch $menuName {
	"perlTextFilters" {
	    set filterPaths [list $PerlmodeVars(perlTextFiltersPath)]
	    set exts "*"
	}
	"perlLibScripts"  {
	    set filterPaths [list $PerlmodeVars(perlLibFolder)]
	    regsub -all {[*.]} [mode::filePatterns Perl] { } exts
	}
	"perlPathScripts" {
	    set filterPaths $PerlSearchPath
	    regsub -all {[*.]} [mode::filePatterns Perl] { } exts
	}
    }
    set filterProc  "Perl::scriptsProc"
    regsub -all {((P|p)erl)| } $menuName {} var
    # Need global here because 'menu::buildHierarchy' is looking for an
    # error in the caller's context.
    global Perl::$var
    menu::buildHierarchy $filterPaths $menuName $filterProc Perl::$var $exts
}

# ===========================================================================
# 
# Create a list of folders in which to search for Perl library files,
# including the lib folder in the Perl application directory and the
# $perlLibFolder folder (if it exists).  The current folder is not
# included in the list.  Any folders set by using the "Search Paths"
# package will also be included.  The var 'Perl::SearchPaths' is used by
# the proc Perl::openPerlFile.
#

proc Perl::buildSearchPath {args} {
    
    global PerlmodeVars PerlSearchPath Perl::SearchPaths
    global alpha::platform
    
    status::msg [set msg "Building Perl search pathÉ"]
    set folders $PerlSearchPath
    
    # The local lib folder:
    set localLib $PerlmodeVars(perlLibFolder)
    if {[string length $localLib]} { 
	lappend folders $localLib
	# Search subfolders one level deep:
	eval lappend folders [file::hierarchy $localLib 1]
    }
    # Alpha's 'Text Filters' folder:
    set alphaLib $PerlmodeVars(perlTextFiltersPath)
    if {[string length $alphaLib]} { 
	lappend folders $alphaLib
    }
    # Any "*lib*" folders in the MacPerl application folder:
    # First find the location of the local Perl application.
    if {![catch {Perl::perlFolder} perlPath]} {
	# Bug:  'glob' is case sensitive!
	foreach folder [glob -nocomplain -type d -dir $perlPath "*\[Ll\]ib*"] {
	    lappend folders $folder
	    # Search subfolders one level deep:
	    eval lappend folders [file::hierarchy $folder 1]
	} 
    } 
    set Perl::SearchPaths [lunique $folders]
    menu::buildSome "perlMenu"
    status::msg "$msg finished."
    return
}

# ===========================================================================
# 
# Post Evaluate -- dim or mark menu items as necessary.
# 

proc Perl::postEval {args} {
    
    global PerlmodeVars HOME perlMenu Perl::PrefsInMenu1 Perl::PrefsInMenu2
    global Perl::PrevScript

    foreach item [set Perl::PrefsInMenu1] {
	if {$item == "(-)"} {continue}
	markMenuItem {perlModeOptions} $item $PerlmodeVars($item) Ã
    }
    foreach item [set Perl::PrefsInMenu2] {
	if {$item == "(-)"} {continue}
	markMenuItem {perlFilterOptions} $item $PerlmodeVars($item) Ã
    }
    # After building menu, disable "repeatLastFilter" command if there is
    # no previous script since there isn't a filter yet.
    set script [set Perl::PrevScript]
    if {![string length $script] || $script == {*startup*}} {
	enableMenuItem $perlMenu "repeatLastFilter" 0 
    } else {
	enableMenuItem $perlMenu "repeatLastFilter" 1
    }
}

proc Perl::registerOWH {{which "register"}} {
    
    global PerlmodeVars global::features perlMenu
    
    # This is only necessary if the Perl Menu is global.
    if {![lcontains {global::features} perlMenu]} {return}
    
    set dimItems [list 			\
      "quickSaveAs"			\
      "runTheSelection"		        \
      "runTheBuffer"			\
      "saveAndRun"			\
      "selectBufferAsFilterÉ"           \
      "collectIdentifiers"              \
      "regularExpressionColors"	        \
      "defaultColors"			\
      "perlInsertions"			\
      "perlNavigation"			]
    foreach item $dimItems {
	hook::$which requireOpenWindowsHook [list $perlMenu $item] 1
    }
    set dimItems [list			\
      "Open This File"			\
      "Save As Droplet"			\
      "Save As Runtime"			\
      "Save As CGI"			]
    foreach item $dimItems {
	hook::$which requireOpenWindowsHook [list "-m" "tellPerl" $item] 1
    }
    if {$PerlmodeVars(includePerlPathMenu)} {
        set dimItems {"viewSearchPathsÉ" "addSearchPathsÉ" "removeSearchPathsÉ"}
	foreach item $dimItems {
	    hook::$which requireOpenWindowsHook [list "perlFilterOptions" $item] 1
	}
    } 
}

# Build the menu now.
menu::buildSome perlMenu

# ===========================================================================
# 
# ×××× Menu Procs ×××× #
# 

proc Perl::menuProc {menuName itemName args} {
    
    global PerlmodeVars Perl::ScriptFile Perl::ScriptStart
    
    switch $menuName {
	"perlInsertions" {
	    switch $itemName {
		"Add Remove \@"  {togglePrefix \@}
		"Add Remove \$"  {togglePrefix \$}
		"Insert Divider" {
		    #  Modified from Vince's original to allow you to
		    #  just select part of an already written comment and
		    #  turn it into a Divider.  -trf
		    if {[isSelection]} {
			set enfoldThis [getSelect]
			beginningOfLine
			killLine
			insertText "##### $enfoldThis #####"
		    } else {
			elec::Insertion "##### ¥¥ #####"
		    }
		    if {$PerlmodeVars(autoMark)} {markFile} 
		}
		"New Comment"           {comment::newComment 0}
		"Comment Template"      {comment::commentTemplate}
	    }
	}
	"perlNavigation" {
	    switch $itemName {
		"Next Command"		{function::next}
		"Prev Command"		{function::prev}
		"Select Command"	{function::select}
		"Reformat Command"	{function::reformat}
	    }
	}
	default {
	    switch $itemName {
		"switchToPerl" {
		    Perl::perlFolder
		    app::launchFore $PerlmodeVars(perlSig)
		}
		"runTheSelection" {
		    Perl::perlFolder
		    set Perl::ScriptFile  [win::Current]
		    set Perl::ScriptStart [lindex [pos::toRowChar [getPos]] 0]
		    Perl::executeScript   [getSelect]
		}
		"runTheBuffer" {
		    Perl::perlFolder
		    set Perl::ScriptFile  [win::Current]
		    set Perl::ScriptStart 1
		    Perl::executeScript   [getText [minPos] [maxPos]]
		}
		"saveAndRun" {
		    save
		    Perl::perlFolder
		    set Perl::ScriptFile  [win::Current]
		    set Perl::ScriptStart 1
		    Perl::executeFile     [win::Current]
		}
		"runAFile" {
		    Perl::perlFolder
		    if {![catch {getfile "Select a Perl script"} path]} {
			set Perl::ScriptFile  $path
			set Perl::ScriptStart 1
			Perl::executeFile     $path
		    } else {
			error "cancel"
		    }
		}
		"collectIdentifiers" {
		    status::msg "Collecting identifiers ..."
		    set id_pat {([$@%*][a-zA-Z0-9]+)|(<[a-zA-Z0-9]+>)}
		    set pos [minPos]
		    while {![catch {search -s -f 1 -r 1 -m 0 -i 0 $id_pat $pos} result]} {
			lappend idents [eval getText $result]
			set pos [pos::math [lindex $result 1] + 1]
		    }
		    if {[info exist idents]} {
			set idents [lunique $idents]
			set idents [lsort -command sortByIgnoringFirstChar $idents]
			regsub -all {\{|\}} $idents "" idents
#			regsub -all {\{([^\}])*\}} $idents "" idents
			set count [llength $idents]
			set idents [join $idents "\r# "]
			putScrap "# $idents"
			status::msg "$count identifiers from '[win::CurrentTail]' are now in the clipboard.  Use 'Paste' to insert them."
		    } else {
			status::msg "Could not find any identifiers."
		    }
		}
		"regularExpressionColors"  {
		    regModeKeywords -a -e {} -s {none} -m {$} -k {magenta} \
		      -i "+" -i "-" -i "*" -i "\\" \
		      -I {red} Perl {}
		    refresh
		}
		"defaultColors"  {Perl::colorizePerl}
		default {Perl::$itemName}
	    }
	}
    }
}

# This should probably go into a SystemCode file somewhere.

proc sortByIgnoringFirstChar {one two} {
    string compare [string tolower [string range $one 1 end]] \
      [string tolower [string range $two 1 end]]
}

# ===========================================================================
# 
# Other (Mac)Perl Interactions
# 
# Interact with (Mac)Perl in some other way besides executing a script.
#
# DTH: note addition of two lines for auto-save
# 

proc Perl::tellPerl {menuName itemName} {
    
    Perl::perlFolder

    global PerlmodeVars Perl::PerlName
    
    switch $itemName {
	"Open This File" {
	    # Open the current file under MacPerl.  This used to useful
	    # for saving files as droplets or runtime scripts.  Maybe
	    # it's still useful for something...?
	    if {[winDirty]} {
		switch [askyesno -c "Save '[win::CurrentTail]'?"] {
		    "yes"    {save}
		    "cancel" {return}
		}
	    }
	    Perl::lauchBackPerl
	    sendOpenEvent -n [file tail [set Perl::PerlName]] [win::Current]
	}
	"Save As Droplet"	{Perl::saveThruPerl "droplet"}
	"Save As Runtime"	{Perl::saveThruPerl "runtime"}
	"Save As CGI"		{Perl::saveThruPerl "cgi"}
	"Get Output Window"	{Perl::openOutput}
	"Close Output Window"	{
	    Perl::lauchBackPerl
	    sendCloseWinName MacPerl [set Perl::PerlName]
	    sendCloseWinName MacPerl "Perl Debug"
	}
	"Quit"				{
	    if {[app::isRunning $PerlmodeVars(perlSig) name]} {
		sendQuitEvent $name
		# switchTo is necessary to keep MacPerl from blinking
		switchTo $name	
	    }
	}
    }
}

# ===========================================================================
# 
# Save Thru (Mac)Perl
# 
# Save the script in the current window as a MacPerl droplet or runtime
# script.
#

proc Perl::perlSave {menuName itemName} {
    
    switch $itemName {
	"Droplet"	{Perl::saveThruPerl "auto-droplet"}
	"Runtime"	{Perl::saveThruPerl "auto-runtime"}
	"CGI"		{Perl::saveThruPerl "auto-cgi"}
    }
}

proc Perl::saveThruPerl {type} {
    
  Perl::lauchBackPerl
  global Perl::PerlName
#   global PerlmodeVars ALPHA 
    
    if {[winDirty]} {
	switch [askyesno -c "Save '[win::CurrentTail]'?"] {
	    "yes"    {save}
	    "cancel" {return}
	}
    }
    # DTH note the following "if" block which replaced what is in the 
    # new "else" block
    set myName [lindex [winNames -f] 0]
    if {$type == "auto-droplet" || $type == "auto-runtime"} {
	if {[file extension $myName] == ".pl"} {
	    set destfile [tclAE::build::filename [file rootname $myName]]
	} else {
	    set destfile [tclAE::build::filename [file rootname $myName]]
	}
    } elseif {$type == "auto-cgi"} {
	set destfile [tclAE::build::filename "[file rootname $myName].cgi"]
    } else {
	set destfile [tclAE::build::filename [putfile {Save droplet as} [lindex [winNames] 0]]]
    }
    
    set script [curlyq [getText [minPos] [maxPos]]]
    regsub {auto\-} $type {} type
    switch $type {
	"droplet"   {set saveType "SCPT"}
	"runtime"   {set saveType "MrP7"}
	"cgi"       {set saveType "'WWW?'"}
	"text"      {set saveType "TEXT"}
    }
    set err [catch {eval "tclAE::send -p -t 36000 -r \"${Perl::PerlName}\"" core save {----} [list $script] {dest:} [list $destfile] {fltp:} $saveType } reply ]
    if {$err} {
	error "Cancelled -- tclAE::send -p error code $err in Perl::saveThruMacPerl"
    }
    
    # The following lines could be used to tell MacPerl to take the
    # script file from an existing disk file and then re-save it in the
    # desired form.
    #
    #	set srcfile "\[ [tclAE::build::filename [win::Current]] \]"
    #	set reply [eval "tclAE::send -p -t 36000 -r \"$name\"" core save {----} [list $srcfile] {dest:} [list $destfile] {fltp:} $saveType ]
    #
}

# ===========================================================================
# 
# Run a preattached Perl script selected from one of the menus:
#
# Note: (No special arrangements are made to provide input or capture the
# output when running any scripts.)
#

proc Perl::scriptsProc {menuName itemName} {
    
    global PerlmodeVars

    set varOptions {TextFilters LibScripts PathScripts}
    foreach option $varOptions {
	global Perl::$option
	set what [file join $menuName $itemName]
	if {[info exists Perl::${option}($what)]} {
	    set script [set Perl::${option}($what)]
	    break
	} elseif {[info exists Perl::${option}([file separator]$what)]} {
	    # Is this stuff still required, or will it all work
	    # seamlessly and correctly now?
	    set script [set Perl::${option}([file separator]$what)]
	    break
	}
	
    }
    if {![info exists script] || ![file exists $script]} {
	error "Cancelled -- '$itemName' couldn't be found."
    } 
    # Should we simply run the script, or ask first?
    set modified [getModifiers]
    if {!$modified && !$PerlmodeVars(runWithoutConfirmation)} {
	set question "Run the script '$itemName'?"
	if {[dialog::yesno -y "Run Script" -n "Edit Script" -c $question]} {
	    set modified 0
	} else {
	    set modified 1
	}
    }
    # Should we run the script, or edit it?
    if {$modified} {
	file::openQuietly $script
    } else {
	Perl::fileAsFilter $script
    }
}

# ===========================================================================
# 
# Perl Help items.
#

proc Perl::perlHelp {menuName itemName} {
    
    global PerlmodeVars

    # help::openFile will generate any necessary errors and messages.

    switch -- $itemName {
	"Perl Home Page"        {url::execute $PerlmodeVars(perlHomePage)}
	"Perl Mode Help"        {package::helpWindow "Perl"}
	"MacPerl Help"          {help::openFile "MacPerl Help"}
	"Perl 4 Manual"         {help::openFile "Perl Commands"}
	"Perl 5 Manual -- local" {
	    set helpFile [file join $PerlmodeVars(perlHelpDocsFolder) perl]
	    set question "Couldn't find the 'Perl 5 Docs' folder."
	    if {[file exists $helpFile]} {
		help::openFile $helpFile
	    } elseif {[dialog::yesno -y "Download Archive" -n "Locate Folder" -c $question]} {
		alertnote "Use the 'Perl 5 Manual -- local' menu item to locate the folder after it has been unpacked."
		url::execute "ftp://ftp.ucsd.edu/pub/alpha/Perl_5_Docs.sit.hqx"
	    } else {
		set docFolder [get_directory -p "Locate the Perl 5 Docs Folder:"]
		set PerlmodeVars(perlHelpDocsFolder) $docFolder
		prefs::modified PerlmodeVars(perlHelpDocsFolder)
		set helpFile [file join $PerlmodeVars(perlHelpDocsFolder) perl]
		if {[file exists $helpFile]} {help::openFile $helpFile}
	    }
	}
	"Perl 5 Manual -- www" {urlView $PerlmodeVars(perl5HelpUrl)perl.html}
	"Local Command Help"   {Perl::localCommandSearch}
	"WWW Command Help"     {Perl::wwwCommandSearch}
    }
}

# ===========================================================================
# 
# Toggle the Perl menu flags.
#

proc Perl::optionsProc {menuName itemName} {
    
    global PerlmodeVars mode HOME Perl::PrevScript alpha::platform
    
    if {[getModifiers]} {
	# Open an alertnote with information about the preference.
	if {$itemName == "rebuildFilterMenu"} {
	    set text "Use this menu item to rebuild the 'Perl Filters' menu."
	} elseif {$itemName == "lastFilterUsed"} {
	    set text "Use this menu item to display the last filter used."
	} elseif {$itemName == "viewSearchPaths"} {
	    set text "Use this menu item to view the current Perl mode search paths."
	} elseif {$itemName == "addSearchPaths"} {
	    set text "Use this menu item to add to the current Perl mode search paths."
	} elseif {$itemName == "removeSearchPaths"} {
	    set text "Use this menu item to remove Perl mode search paths."
	} else {
	    set text [help::prefString $itemName "Perl"]
	    if {$PerlmodeVars($itemName)} {set end "on"} else {set end "off"}
	    if {$end == "on"} {
		regsub {^.*\|\|} $text {} text
	    } else {
		regsub {\|\|.*$} $text {} text
	    }
	    set msg "The '$itemName' preference for Perl mode is currently $end."
	}
	alertnote "${text}."
    } elseif {$itemName == "lastFilterUsed"} {
	regsub $HOME [set Perl::PrevScript] "([set alpha::platform])" script
	if {![string length $script] || $script == "*startup*"} {
	    status::msg "There is no 'last' filter available."
	} else {
	    status::msg "$script"
	}
    } elseif {$itemName == "rebuildFiltersMenu"} {
	menu::buildSome "perlMenu"
        set msg "The Perl Filters menu has been rebuilt."
    } elseif {$itemName == "rebuildFiltersMenus"} {
	# We also rebuild the internal cache contained in 'Perl::SearchPaths'.
	Perl::buildSearchPath
	menu::buildSome "perlMenu"
	set msg "The Perl Filters menus have been rebuilt."
    } elseif {[regexp {Search[ ]*Paths} $itemName]} {
	if {$mode != "Perl"} {
	    alertnote "The mode of the frontmost window must be 'Perl' for this menu item."
	    return
	} 
        switch $itemName {
	    "viewSearchPaths"   {mode::viewSearchPath ; return}
	    "addSearchPaths"    {mode::appendSearchPaths}
	    "removeSearchPaths" {mode::removeSearchPaths}
	}
	Perl::buildSearchPath
	menu::buildSome "perlMenu"
	return
    } else {
	set orig $PerlmodeVars($itemName)
	set PerlmodeVars($itemName) [expr {$orig ? 0 : 1}]
	if {$mode == "Perl"} {
	    synchroniseModeVar $itemName $PerlmodeVars($itemName)
	}
	Perl::postEval
	prefs::changed Perl $itemName $orig $PerlmodeVars($itemName)
	
	if {$PerlmodeVars($itemName)} {set end "on"} else {set end "off"}
	set msg "The '$itemName' preference for Perl mode is now $end."
    }
    if {[info exists msg]} {
	status::msg $msg
    }
    return
}

# ===========================================================================
# 
# .
