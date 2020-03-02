## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "tclKeywords.tcl"
 #                                          created: 04/05/1997 {09:31:10 pm}
 #                                      last update: 03/16/2006 {11:22:47 PM}
 # Description:
 # 
 # Define tcl-tk keyword lists for colorizing and other utilities.
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

proc tclKeywords.tcl {} {}

namespace eval Tcl {
    
    global Tclcmds

    variable tcltkKeywordRedirect

    # ×××× Tcl Keywords ×××× #
    
    variable tclCommands
    variable tclCommands.8.5
    variable tclKeywords
    
    # All are basic Tcl commands.  (Some others, i.e. beep, echo, etc will be
    # coloured but are not defined in this list for command double-click.) 
    # This list is kept separate from "tclKeywords" in case other utilities
    # want to know if a given string is strictly a built-in Tcl command.
    set tclCommands {
	after append array binary break case catch cd clock close concat
	continue dde else elseif encoding eof error eval exec exit expr
	fblocked fconfigure fcopy file fileevent flush for foreach format gets
	glob global history if incr info interp join lappend lindex linsert
	list llength load lrange lreplace lsearch lset lsort namespace open
	package pid proc puts pwd read regexp regsub rename resource return
	scan seek set slave socket source split string subst switch tclLog
	tclMacPkgSearch tclPkgSetup tclPkgUnknown tell then time trace unknown
	unset update uplevel upvar variable vwait while
    }
    # These are in Tcl 8.5:
    set tclCommands.8.5 {
	dict lassign lrepeat 
    }
    eval [list lappend tclCommands] ${tclCommands.8.5}
    
    set tclKeywords $tclCommands
    # This is potentially used by completions...
    ensureset Tclcmds $tclCommands

    
    # Extra utilities provided by some built in packages.
    lappend extraUtils http
    set httpUtils {
	http::cleanup http::code http::config http::data http::error
	http::formatQuery http::geturl http::ncode http::register http::reset
	http::size http::status http::unregister http::wait
    }
    lappend extraUtils library
    set libraryUtils {
	auto_execok auto_import auto_load auto_mkindex auto_mkindex_old
	auto_qualify auto_reset parray pkg::create pkg_mkIndex tcl_endOfWord
	tcl_findLibrary tcl_startOfNextWord tcl_startOfPreviousWord
	tcl_wordBreakAfter tcl_wordBreakBefore
    }
    lappend extraUtils msgcat
    set msgcatUtils {
	msgcat::mc msgcat::mcload msgcat::mclocale msgcat::mcmax
	msgcat::mcmset msgcat::mcpreferences msgcat::mcset msgcat::mcunknown
    }
    lappend extraUtils safe
    set safeUtils {
	safe::interpConfigure safe::interpCreate safe::interpDelete
	safe::interpFindInAccessPath safe::interpInit safe::setLogCmd
    }
    lappend extraUtils tcltest
    set tcltestUtils {
	tcltest::bytestring tcltest::cleanupTests tcltest::configure
	tcltest::configure tcltest::configure tcltest::customMatch
	tcltest::debug tcltest::errorChannel tcltest::errorFile
	tcltest::interpreter tcltest::limitConstraints tcltest::loadFile
	tcltest::loadScript tcltest::loadTestedCommands
	tcltest::makeDirectory tcltest::makeFile tcltest::match
	tcltest::matchDirectories tcltest::matchFiles tcltest::normalizeMsg
	tcltest::normalizePath tcltest::outputChannel tcltest::outputFile
	tcltest::preserveCore tcltest::removeDirectory tcltest::removeFile
	tcltest::runAllTests tcltest::singleProcess tcltest::skip
	tcltest::skipDirectories tcltest::skipFiles
	tcltest::temporaryDirectory tcltest::test tcltest::test tcltest::test
	tcltest::testConstraint tcltest::testsDirectory tcltest::verbose
	tcltest::viewFile tcltest::workingDirectory
    }
    foreach utilName $extraUtils {
	foreach utilProc [set ${utilName}Utils] {
	    regsub "Utils$" $utilName "" util
	    set tcltkKeywordRedirect($utilProc) $util
	    lappend tclKeywords $utilProc
	}
    }
    # These are used in command double clicking, and might over-write some
    # of the redirections defined above.
    array set tcltkKeywordRedirect {
	else                            if
	elseif                          if
	pkg::create                     packagens
	pkg_mkIndex                     pkgMkIndex
	slave                           interp
	then                            if
	expand                          Tcl
    }
    # Add ::<keyword> to the list.
    foreach keyword $tclKeywords {
	lappend tclKeywords ::$keyword
    }
    set tclKeywords [lsort -unique -dictionary $tclKeywords]

    # ×××× Tk Keywords ×××× #

    variable tkCommands
    variable tkKeywords
    variable tkProcs

    # All are basic Tk commands.  This list is kept separate from
    # "tkKeywords" in case any other utilities want to know if a given string
    # is strictly a built-in Tk command.
    set tkCommands {
	bell bind bindtags button canvas checkbutton console destroy entry
	event focus font frame grab grid image label labelframe listbox
	menu menubutton message option pack panedwindow place radiobutton
	raise scale selection scrollbar text tk tkerror tkvars tkwait
	toplevel winfo wm
    }
    # I'm not sure if 'tkProcs' is the proper name here ...
    set tkProcs {
	tk_bisque tk_chooseColor tk_chooseDirectory tk_dialog
	tk_focusFollowsMouse tk_focusNext tk_focusPrev tk_getOpenFile
	tk_getSaveFile tk_menuSetFocus tk_messageBox tk_optionMenu tk_popup
	tk_setPalette tk_textCopy tk_textCut tk_textPaste
    }
    set tkKeywords [concat $tkCommands $tkProcs]
    # These are used in command double clicking.
    array set tcltkKeywordRedirect {
	tk_bisque               palette
	tk_chooseColor          chooseColor
	tk_chooseDirectory      chooseDirectory
	tk_dialog               dialog
	tk_focusFollowsMouse    focusNext
	tk_focusNext            focusNext
	tk_focusPrev            focusNext
	tk_getOpenFile          getOpenFile
	tk_getSaveFile          getOpenFile
	tk_menuSetFocus         menu
	tk_messageBox           messageBox
	tk_optionMenu           optionMenu
	tk_popup                popup
	tk_setPalette           palette
	tk_textCopy             text
	tk_textCut              text
	tk_textPaste            text
    }
    # Add ::<keyword> to the list.
    foreach keyword $tkKeywords {
	lappend tkKeywords ::$keyword
    }
    set tkKeywords [lsort -unique -dictionary $tkKeywords]
    
    # ×××× Tk Commands ×××× #
    
    # I'm not sure if 'TkCommands' is the proper name here ...
    variable TkCommands
    
    set TkCommands {
	tk::ButtonDown tk::ButtonEnter tk::ButtonInvoke tk::ButtonLeave
	tk::ButtonUp tk::CancelRepeat tk::CheckRadioInvoke tk::Darken
	tk::EntryAutoScan tk::EntryBackspace tk::EntryButton1
	tk::EntryClosestGap tk::EntryInsert tk::EntryKeySelect
	tk::EntryMouseSelect tk::EntryNextWord tk::EntryPaste
	tk::EntryPreviousWord tk::EntrySeeInsert tk::EntrySetCursor
	tk::EntryTranspose tk::EventMotifBindings tk::FDGetFileTypes
	tk::FirstMenu tk::FocusGroup_BindIn tk::FocusGroup_BindOut
	tk::FocusGroup_Create tk::FocusGroup_Destroy tk::FocusGroup_In
	tk::FocusGroup_Out tk::FocusOK tk::ListboxAutoScan
	tk::ListboxBeginExtend tk::ListboxBeginSelect
	tk::ListboxBeginToggle tk::ListboxCancel tk::ListboxDataExtend
	tk::ListboxExtendUpDown tk::ListboxMotion tk::ListboxSelectAll
	tk::ListboxUpDown tk::MbButtonUp tk::MbEnter tk::MbLeave
	tk::MbMotion tk::MbPost tk::MenuButtonDown tk::MenuDownArrow
	tk::MenuDup tk::MenuEscape tk::MenuFind tk::MenuFindName
	tk::MenuFirstEntry tk::MenuInvoke tk::MenuLeave tk::MenuLeftArrow
	tk::MenuMotion tk::MenuNextEntry tk::MenuNextMenu
	tk::MenuRightArrow tk::MenuUnpost tk::MenuUpArrow tk::MessageBox
	tk::PostOverPoint tk::RecolorTree tk::RestoreOldGrab
	tk::SaveGrabInfo tk::ScaleActivate tk::ScaleButton2Down
	tk::ScaleButtonDown tk::ScaleControlPress tk::ScaleDrag
	tk::ScaleEndDrag tk::ScaleIncrement tk::ScreenChanged
	tk::ScrollButton2Down tk::ScrollButtonDown tk::ScrollButtonUp
	tk::ScrollByPages tk::ScrollByUnits tk::ScrollDrag
	tk::ScrollEndDrag tk::ScrollSelect tk::ScrollStartDrag
	tk::ScrollToPos tk::ScrollTopBottom tk::TabToWindow
	tk::TearOffMenu tk::TextAutoScan tk::TextButton1
	tk::TextClosestGap tk::TextInsert tk::TextKeyExtend
	tk::TextKeySelect tk::TextNextPara tk::TextNextPos
	tk::TextNextWord tk::TextPaste tk::TextPrevPara tk::TextPrevPos
	tk::TextResetAnchor tk::TextScrollPages tk::TextSelectTo
	tk::TextSetCursor tk::TextTranspose tk::TextUpDownLine
	tk::TraverseToMenu tk::TraverseWithinMenu
    }
    # Add ::<keyword> to the list.
    foreach keyword $TkCommands {
	lappend TkCommands ::$keyword
    }
    set TkCommands [lsort -unique -dictionary $TkCommands]

    # ×××× iTcl Keywords ×××× #
    
    variable itclKeywords
    
    set itclKeywords {
	@scope body class code common component configbody constructor
	define destructor hull import inherit itcl itk itk_component
	itk_initialize itk_interior itk_option iwidgets keep method
	private protected public
    }
    # Add ::<keyword> to the list.
    foreach keyword $itclKeywords {
	lappend itclKeywords ::$keyword
    }
    set itclKeywords [lsort -unique -dictionary $itclKeywords]

    # ×××× TclX Keywords ×××× #
    
    variable tclXKeywords
    
    set tclXKeywords {
	dirs commandloop echo infox for_array_keys for_recursive_glob loop
	popd pushd recursive_glob showproc try_eval
	
	cmdtrace edprocs profile profrep saveprocs
	
	alarm execl chroot fork id kill link nice readdir signal sleep system
	sync times umask wait
	
	bsearch chmod chown chgrp dup fcntl flock for_file funlock fstat
	ftruncate lgets pipe read_file select write_file
	
	host_info
	
	scancontext scanfile scanmatch
	
	abs acos asin atan2 atan ceil cos cosh double exp floor fmod hypot
	int log10 log pow round sin sinh sqrt tan tanh max min random
	
	intersect intersect3 lcontain lempty lmatch lrmdups lvarcat
	lvarpop lvarpush union
	
	keyldel keylget keylkeys keylset
	
	ccollate cconcat cequal cindex clength crange csubstr ctoken ctype
	replicate translit
	
	catopen catgets catclose mainloop
	
	tclhelp help helpcd helppwd apropos
	
	auto_commands buildpackageindex convert_lib loadlibindex
	auto_packages auto_load_file searchpath
    }
    # Add ::<keyword> to the list.
    foreach keyword $tclXKeywords {
	lappend tclXKeywords ::$keyword
    }
    set tclXKeywords [lsort -unique -dictionary $tclXKeywords]

    # ×××× Pseudo Tcl Keywords ×××× #
    
    variable pseudoTclKeywords [list lcontains lunion lreverse lremove lunique]
    # Add ::<keyword> to the list.
    foreach keyword $pseudoTclKeywords {
	lappend pseudoTclKeywords ::$keyword
    }

    # ×××× Tcl-tk Variables ×××× #
    
    variable tclVariables
    variable tkVariables
    
    set tclVariables {
	env errorCode errorInfo tcl_library tcl_patchLevel tcl_pkgPath
	tcl_platform tcl_precision tcl_rcFileName tcl_rcRsrcName
	tcl_traceCompile tcl_traceExec tcl_wordchars tcl_nonwordchars
	tcl_version
    }
    # Add ::<keyword> to the list.
    foreach keyword $tclVariables {
	lappend tclVariables ::$keyword
    }

    set tkVariables {
	tk_library tk_patchLevel tk::Priv tk_strictMotif tk_textRedraw
	tk_version
    }
    # Add ::<keyword> to the list.
    foreach keyword $tkVariables {
	lappend tkVariables ::$keyword
    }
    
    # This list is needed by some help/info procs.
    variable tcltkKeywords [lsort -unique -dictionary \
      [concat $tclKeywords $tkKeywords]]
    
    # Cleanup
    unset -nocomplain keyword utilName utilProc util
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Color Tcl-tk Keywords ×××× #
#

proc Tcl::colorTclKeywords {args} {
    
    global TclmodeVars
    
    variable tclKeywords
    
    set keywords [concat $tclKeywords beep default echo]
    regModeKeywords -a \
      -e {#} -c $TclmodeVars(commentColor) \
      -s $TclmodeVars(stringColor)  \
      -k $TclmodeVars(commandColor) Tcl $keywords
    # Refresh is necessary (called after pref has changed.)
    if {[llength $args]} {
	refresh
    }
    return
}

proc Tcl::colorTkKeywords {args} {
    
    global TclmodeVars
    
    variable tkKeywords
    variable TkCommands
    
    set keywords [concat $tkKeywords $TkCommands]
    if {$TclmodeVars(recogniseTk)} {
	# add this line if we can handle double 'magic chars'
	# -m {tk}
	regModeKeywords -a -k $TclmodeVars(commandColor) Tcl $keywords
    } else {
	regModeKeywords -a -k {none} Tcl $keywords
    }
    # Refresh is necessary (called after pref has changed.)
    if {[llength $args]} {
	refresh
    }
    return
}
  
proc Tcl::colorItclKeywords {args} {
    
    global TclmodeVars
    
    variable itclKeywords
    
    if {$TclmodeVars(recogniseItcl)} {
	regModeKeywords -a -k $TclmodeVars(commandColor) Tcl $itclKeywords
    } else {
	regModeKeywords -a -k {none} Tcl $itclKeywords
    }
    # Refresh is necessary (called after pref has changed.)
    if {[llength $args]} {
	refresh
    }
    return
}

proc Tcl::colorPseudoTclKeywords {args} {
    
    global TclmodeVars
    
    variable pseudoTclKeywords
    
    if {$TclmodeVars(recognisePseudoTcl)} {
	regModeKeywords -a -k $TclmodeVars(commandColor) Tcl $pseudoTclKeywords
    } else {
	regModeKeywords -a -k {none} Tcl $pseudoTclKeywords
    }
    # Refresh is necessary (called after pref has changed.)
    if {[llength $args]} {
	refresh
    }
    return
}

proc Tcl::colorTclXKeywords {args} {
    
    global TclmodeVars
    
    variable tclXKeywords
    
    if {$TclmodeVars(recogniseTclX)} {
	regModeKeywords -a -k $TclmodeVars(commandColor) Tcl $tclXKeywords
    } else {
	regModeKeywords -a -k {none} Tcl $tclXKeywords
    }
    # Refresh is necessary (called after pref has changed.)
    if {[llength $args]} {
	refresh
    }
    return
}

proc Tcl::colorSymbols {args} {
    
    global TclmodeVars
    
    regModeKeywords -a -i "+" -i "-" -i "*" -i "\\" \
      -I $TclmodeVars(symbolColor) Tcl {}
    # Refresh is necessary (called after pref has changed.)
    if {[llength $args]} {
	refresh
    }
    return
}

proc Tcl::colorVariables {args} {
    
    global TclmodeVars
    
    variable tclVariables 
    variable tkVariables

    set keywords $tclVariables
    if {!$TclmodeVars(recogniseTk)} {
	set keywords $tclVariables
    } else {
        set keywords [concat $tclVariables $tkVariables]
    }
    
    regModeKeywords -a -m {$} \
      -k $TclmodeVars(variablesColor) Tcl $tclVariables
    # Refresh is necessary (called after pref has changed.)
    if {[llength $args]} {
	refresh
    }
    return
}

proc Tcl::colorizeTcl {args} {
    
    global tclCmdColourings tclExtraColourings
    
    variable tclKeywords
    variable tkKeywords
    
    # Colour all keywords
    foreach p $tclCmdColourings {$p}
    # For some reason, these want to be done last -trf
    foreach p $tclExtraColourings {$p}
    # Refresh is necessary (called after pref has changed.)
    if {[llength $args]} {
	refresh
    }
    return
}

# ===========================================================================
#
# ×××× -------- ×××× #
# 
# Regular Expression Color Support
# 

##
 # --------------------------------------------------------------------------
 #
 # "Tcl::regularExpressionColors" --
 # "Tcl::defaultColors" --
 # 
 # Changes color scheme of current window to make it easier to read regular
 # expressions.  Preferences aren't actually changed.  [Tcl::defaultColors]
 # will restore to the last stored values of the colors.
 # 
 # Contributed by Craig Barton Upright
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::regularExpressionColors {} {
    
    regModeKeywords -a -e {} -s {none} -m {$} -k {magenta} \
      -i "+" -i "-" -i "*" -i "\\" \
      -I {red} Tcl {}
    
    refresh
    return
}

proc Tcl::defaultColors {} {
    Tcl::colorizeTcl 1
    return
}

# ===========================================================================
# 
# .