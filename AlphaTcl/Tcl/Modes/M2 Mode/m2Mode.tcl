## -*-Tcl-*- (nowrap)
## -*-Tcl-*- (install)
## -*-Tcl-*- (auto-install)
#####################################################################################
#                                                                                   #
#   m2Mode.tcl:  Macros and bindings for Modula 2 programmers                       #
#                                                                                   #
#                Supports the M2 mode under Alpha >= 7.x                            #
#                useful to programing with MacMETH or RAMSES, both featuring        #
#                a fast Modula-2 language system, freeware available from           #
#                these links:                                                       #
#                                                                                   #
#                   <ftp://ftp.ito.umnw.ethz.ch/pub/mac/RAMSES>                     #
#                   <http://www.ito.umnw.ethz.ch/SysEcol>                           #
#                                                                                   #
#   Installation:  Double-click accompanying file "OPEN-TO-INSTALL"                 #
#   Deinstallation:   Alpha's menu "Config > Packages > Uninstall Package..." M2    #
#                                                                                   #
#   Usage:  See "Modula-2   Help"                                                   #
#                                                                                   #
#   Programing:                                                                     #
#     First implementation was made by Juerg Thoeny, formerly Systems Ecology ETHZ  #
#     All later work, i.e. reimplementation and improvements, by Andreas Fischlin   #
#     <andreas.fischlin@env.ethz.ch>                                                #
#                                                                                   #
#   ou make improvements to this code, please send them to us!  Thanks!             #
#   E-Mail:  mailto:RAMSES@env.ethz.ch                                              #
#                                                                                   #
#   Other URLs possibly of interest in the context of this mode:                    #
#                                                                                   #
#   http://www.ito.umnw.ethz.ch/SysEcol                                             #
#   ftp://ftp.ito.umnw.ethz.ch/pub/mac/RAMSES                                       #
#                                                                                   #
#   For details see Help file accompanying this file                                #
#                                                                                   #
#####################################################################################
# 
#   Author    Date        Modification
#   ------    ----        ------------
#   af        21.05.95    Initialization for new Alpha >= 6.0b7 fixed
#                         All module templates fixed to behave usefully
#   af        01.09.95    Initialization for new Alpha >= 6.01 fixed
#                         All module templates fixed to behave usefully
#   af        10.06.96    Fixed a few Modula-2 tcl bugs (see SysEcol
#                         bug list)
#   af        24.06.96    Fixed a indentation and mark file bugs (see SysEcol
#                         bug list)
#   af        28.06.96    Wrap bug fixed and new configuration added to better
#                         support new features, e.g. defineFileSaveFormat
#   af        13.09.96    Fixed a bug when "ErrList.DOK" wasn't found
#                         during start-up
#   af        17.09.96    Fixes for the Alpha-bug with the prefs.tcl
#                         execution (twice, instead of just once)
#                         Testing this script while using Alpha 6.5
#   af        30.12.96    M2MarkFile bug fixed to properly deal with
#                         procIdent ::= char {char | digit }
#                         (jt's version was: procIdent ::= {char} )
#   af        06.03.97    Attempt to improve the nasty, confusing behavior
#                         of wrapComment by giving the user better hints,
#                         however, without being able to really fix the problem
#   af        26.05.97    Template menu did no longer work for unknwon reasons
#                         proc dispatchSubMenuCmds added. Template menu offers
#                         now more all template items
#   af        05.06.97    askForModuleName improved for editing of names
#   af        21.09.97    Improving error messages of launching
#   af        16.09.97    setLnBreakBehavior added which sets now (finally,
#                         sic!) Alpha's global fillColumn, wrapLow, and
#                         wrapHigh variables to avoid annoying line breaks
#                         during programming of long lines.
#   af        22.01.98    Adaptations for Alpha 7.x, M2 is now an ordinary mode
#   af        01.02.98    Fixed long-standing bug with err.ALPHA remaining
#                         open if working file(s) couldn't be opened
#                         Final version having all (even for long outstanding
#                         issues) resolved.
#                         Note configuration uses its own variables, since those
#                         mechanisms were introduced long before Alpha offered
#                         its newPref feature.  Since this script ought to work
#                         also with pre 7 Alphas, this a bit complex
#                         implementation technique is (not yet?) abandoned
#   af        08.02.98    Finalizing M2 mode for release 3.0
#   af        09.02.98    Adding contributions from Tom Fetherston (
#                         M2::parseFuncs, replacement for M2::MarkFile,
#                         M2::insertDivider. Thanks!
#   af        09.02.98    Adding Programmer font flip menu addon by Johan Linde
#                         Thanks!
#   af        11.02.98    Changing behavior of RET. Does now break line and
#                         SHIFT-RET jumps out of line.
#   af        13.02.98    Adding bug fixes by Tom Fetherston for M2::parseFuncs
#                         and new M2::MarkFile, which does now also recognize
#                         modules. Release 3.0 completed.
#   af        17.02.98    V 3.0.1 fixing rshift, lshift menu bug
#   af        19.02.98    V 3.0.2 Omitting PROC from expandWords
#                         adjCurLnToIndent added, new initializiation of
#                         M2modeVars(m2_shellName) and m2_errListDOK if
#                         never configured
#   af        21.02.98    V 3.0.3 Quiet autoconfiguration added
#   af        23.02.98    V 3.0.4 Minor message display fixes. Better (module
#                         specific) behavior of jumpToTemplatePlaceHolder
#                         and M2:carriageReturn
#   af        03.03.98    V 3.0.5 Minor improvements in self-documentation of
#                         newPref vars and a bit of cleaning up, i.e. removing,
#                         of stuff gone obsolete with latest Alpha 7.1b2
#                         openOtherLibModule and section marks added
#   af        09.03.98    V 3.0.6
#                         - Fixed bug in adjCurLnToIndent if no preceeding
#                           white space
#   af        20.03.98    V 3.1b1 Command and Cntrl^Cmd Doubleclick added
#   af        24.03.98    V 3.1b2 JoinToOneSpace added (Ctrl^j no longer equi-
#                         valent to Ctrl^e (find modula-2 error - findNextError)
#   af        27.03.98    V 3.1b3 wrapComment kills extra empty line before *)
#                         Ctrl^m no longer equivalent to CTRL-SHIFT-DOWN but
#                         minimizes now surrounding white space to single blank
#    af       30.03.98    V 3.1b4 Complete revision of M2::MarkFile for new
#                         prefs and fixing bugs in appearance of M-button lists;
#                         Making commentSelection and uncommentSelection behave
#                         more robustly.  Ctrl^c and Ctrl^Shift^c for simple
#                         commenting (uses prefix/suffixString) added.
#                         doM2ShiftLeft/Right selects now line if no selection.
#                         killWholeLine removes now also empty line
#    af       04.04.98    V 3.1
#    af       06.04.98    Fixing bug in menu for Alpha 7.0px but<7.1bx
#    af       09.04.98    V 3.1.1 menu/Menu bug fixed removed again, since Vince
#                         fixed it in Alpha 7.1b6. However, new version checking
#                         added, especially also in OPEN-TO-INSTALL to ensure
#                         user is well informed about compatibility of M2 mode
#                         with certain Alpha versions
#    af       15.04.98    V 3.1.2 Cmd^Cntrl^doubleclik finds now also marks in
#                         any definition module residing within same folder
#    af       17.04.98    New key bindings:
#                         old                         new
#                         ---------------------       -----------------------------
#                         Cmd^Return                  - jumpOutOfLnAndRet (similar
#                         - skipLnReturn              to jumpOutOfLnAndReturn
#                                                     but never indents)
#                         Cmd^Shift^Return            - openNewAbove
#                         - skipPrevLnOpenNew         (skipPrevLnOpenNew dropped)
# 
#                         Cmd^Ctrl^Shift^Return       - skipLnReturn
#    af       20.04.98    M2::DblClickHelper buggy bevavior fixed, skips search in
#                         currently open files if Ctrl^Cmd^Click and search does
#                         in currently open files succeeds only if match exact
#    af       07.05.98    V 3.1.3 Using Juan Fualgeras better completions
#                         Recognizes extension DTF
#    af       12.05.98    V 3.1.4 Searches also in RAMSES Sys DEFs
#                         - removing configureM2Mode from M2 menu if Alpha is 7.x
#                         solution to Juan's suggestion of avoiding use of a trace
#                         which slows down entering of M2 mode.
#    af       13.07.98    Testing phase for V 3.1.4 with Alpha 7.1fc1, 7.1fc2, and
#                         7.1fc3 over => Mode is fit for release
#    af       15.07.98    V 3.1.4 released
#    af       27.08.98    Testing phase for V 3.1.5 with Alpha 7.1fc6, 7.1prerelease
#    af       30.08.98    Adding openFileQuietly replacement by Jonathan Guyer
#    af       30.10.98    V 3.1.6  Fixed bugs in adjCurLnToIndentAbove and
#                         adjCurLnToIndentBelow; showFullName added
#    af       08.12.98    V 3.1.7  Adjustments made for Alpha 7.1p4, i.e. use now
#                         Menu instead of menu if Alpha V >= 7
#    af       01.03.99    V 3.2.0 Finds now also modules if cmd-clicking module name
#                         - bug fixed with finding always marks in currently open
#                           windows
#    af       17.03.99    - M2::MarkFile does now permanently save marks, even if
#                           file was opened as read-only. Useful when
#                           ctrl^cmd^double-clicking names of procedures or modules.
#                         - Double-clicking module names, e.g. in import lists, does
#                           jump to either the corresponding quick reference section
#                           or the definition module as suggested by Juan Falgueras.
#                         - Fixed bug with autoconfiguration in case of a corrupted
#                           desktop or otherwise bad or missing MacMETH or RAMSES
#                           installation. User is now notified. Important, since
#                           lots of mode's function are likely to fail if the
#                           autoconfiguration fails, e.g. cmd^double-click, and user
#                           may not understand at all why.
#    af       22.03.99    V 3.2.1 Colorizing of UNTIL added
#    af       24.03.99    V 3.2.2 intelCutPaste flag turned off
#    af       08.04.99    Minor modifications in section determining version, which
#                         have no effect on the mode
#    af       24.03.99    V 3.2.3 fixing quick reference problem (case sensitivity)
#    af       14.04.99    V 3.2.4 intelCutPaste renamed to smartCutPaste
#                         - M2::correctIndentation fixed to perform according to
#                           specs to support smartPaste feature.
#                         - getIndentation fixed to expand tabs (which are inserted
#                           against all rules by some routines, e.g. by smartPaste
#                           despite there is a routine M2:indentLine, which does
#                           NOT insert a horizontal tab
#                         - doM2ShiftLeft and doM2ShiftRight expand now tabs before
#                           shifting to avoid unsuccessful shift in case there
#                           should be tabs present in the involved line(s)
#                         - prefs indentUsingSpacesOnly now set
#    af       22.04.99    V 3.2.5 attempt to fix some installation problems if
#                         installed from scratch on a machine without a RAMSES shell
#                         - openWorkFiles renamed to M2::openWorkFiles (since it
#                           uses a global binding)
#                         - installDebugFlag and various message production inserted
#                           for easier debugging in case of installation problems
#                         - reportOnShellLaunchFail improved
#                         - copyRing is no longer by default active (slows mode
#                           entering down and is currently rather unstable)
#    af       17.05.99    V 3.2.6 EXPORT added to reserved words
#                         - Uses now a menu icon (ID = 145) to avoid bug of Alpha
#    af       23.05.99    V 3.3b0 complete overhaul to split mode in several files
#                         and to make it Tcl 8 compatible
#    af       27.05.99    V 3.3b1 works with real 7.2 only if I restart System once
#                         from another HFS+ disk volume. On non HFS+ start up disks
#                         no problem.
#                         - distinguishing now wether Alpha is really 7.2, since
#                           only the latter contains the new blue M2 menu resource
#                           (different addMenu and see m2Menu.tcl)
#                         - curAlphaV determined that it contains punctuation
#    af       29.07.99    V 3.3b2 attempt to get M2 mode initialization back to work
#                         - m2Mode.tcl was never really sourced because startup hook
#                           was not really installed. => opening of work object
#                           failed when launching Alpha e.g. via RAMSES shell. Now
#                           fixed.
#    af       02.09.99    V 3.3b3 Attempt to get marking working again. Bug in 
#                         Alpha 7.2.1b10: Aautoloading of procs M2::parseFuncs  
#                         and M2::MarkFile via {}- and M-buttons doesn't work. 
#    af       02.09.99    V 3.3b4 Attempt to improve command double-clicking 
#                         - Moved in m2HelpLookup.tcl the code for <<Is it a 
#                           mark in one of the currently opened file(s)? Skip this if 
#                           Control^Command^Click>> towards the end, so that quick
#                           reference lookup is still possible if concurrently a
#                           definition module is also open, e.g. "SimMaster.DEF" as well
#                           as "ModelWorks Quickreference".
#    af       02.09.99    V 3.4.0 Preparation of release for Alpha 7.3
#                         - m2Marking.tcl more general regexp expressions
#                         - m2Edit.tcl
#    af       02.09.99    V 3.5.0 
#                         - new M2 menu command MakeProjectFile introduced
#                         - new template ife added
#    af       14.02.01    V 3.5.1
#                         - Extension .MOD.MSTR triggers mode
#                         - Fixing version info 
#    af       13.04.01    V 3.5.2
#                         - Extension .m2 .M2 triggers mode so that
#                           Mode Examples Help should work 
#    af       02.05.01    V 3.5.3
#                         - getDirContent extended by parameter dirFiles and recursive
#                         - project files are no longer marked to avoid recompilation
#                           when only opened
#    af       15.06.01    V 3.6.0
#                         - autoEditCompilerFlags added
#    af       29.06.01    V 3.6.1
#                         - autoEditCompilerFlags for IBM fixed, i.e. extending by AuxLib
#    vd       12.09.01    V 3.7.0
#                         - Adjustments for Alpha 7.5 and Tk by Vince Darley
#                           Mode is no longer upward compatible with Alpha versions
#                           earlier than 7.5
#                         - any addDef call replaced by prefs::modified
#                         - in proc adjustM2Prefs from m2AdjPrefs.tcl switch with '--' option
# 			  - any dir separators used in path replaced by join commands
# 			  - in proc defineM2Completions sourcing with uplevel
# 			  - in m2Bindings.tcl using now Bind or unBind instead of bind or unbind
# 			  - in m2Bindings.tcl, m2Config.tcl, m2HelpLookup.tcl, m2Menu.tcl,
# 			    m2Templates.tcl, and m2Utils.tcl
# 			    omitting any conditional statements depending on
# 			    if {$alphaVersionIsAtLeast7} then {
# 			  - in m2CompErr.tcl proc like getCurWord use other routines, e.g. 
# 			    pos::compare etc.
# 			  - M2::forceReadTrigger in m2Config.tcl
# 			  - proc isNotMODModule from m2Edit.tcl and many more procs in here
# 			  - position routines in m2GlobAux.tcl
# 			  - m2Load.tcl added
# 			  - position routines in m2Marking.tcl
# 			  - In m2Menu.tcl  menu::buildSome m2Menu  inserted
# 			  - In m2Mode.tcl proc enterM2Mode calls M2load
# 			  - In m2ShellUse.tcl proc installAEventHandler compares only with V 6.2
# 			  - position routines in m2Templates.tcl
#    af       25.09.01    V 3.7.1
#                         - In m2Prefs.tcl assignment of variables
#                             M2ShellName, M2errDOKFile, M2Author,
#                             M2RightShift, M2LeftShift, M2WrapRightMargin,
#                             M2MaxLineLength, and M2SaveState
#                             M2ShellHome and M2ErrFile
# 			      (the latter 2 are needed to have same
# 			      precondition as resulting from a call to 
# 			      proc adjustShellLaunching from m2AdjPrefs.tcl)
#                           in case the var does not exist to avoid failure
#                           and alert in routine M2::triggerOnRead from m2Config.tcl
#                           when mode is first time entered.
# 			  - m2Load.tcl does source m2Mode.tcl if var curAlphaV does not exist
#                         - Forced loading of mode via a call to proc M2load
# 			    from m2Load.tcl at begin of m2CompErr.tcl and m2ShellUse.tcl
# 			    This ensures that launching Alpha from the RAMSES shell or
# 			    opening work files (Ctrl^0) from within Alpha when mode
# 			    has never been properly initialized will work
#    af       12.10.01    V 3.7.2
#                         - Moving installation info to help
#                         - several cosmetic modifications
#    af       27.10.01    - renaming "M2 Modula-2 Help" back to "Modula-2 Help" as wished by Vince
#    af       13.11.01    V 3.7.3
#                         - Improving m2Help from m2HelpLookup.tcl to mark and color
#                           the help file the standard way
#                         - Improved help file (cosmetic changes only)
#    af       23.12.01    V 3.7.4
#                         - Making code more portable (avoiding ":" as dir separator) and
#                           more robust (glob fails on large machines) in getDirContent 
#                           and listDirContent from m2GlobAux.tcl
#    cbu      05.09.02    V 3.8
#                         - All procs now in 'M2' namespace
#                         - When mode is first sourced, user is given the option
#                           to make bindings global.
#    af       23.02.03    V 3.8.1
#                         - Fixing web site under maintainer
#                         - Merging with independently developed version Craig B Upright
#                           has made
#                         - wordWrap (later lineWrap) is now supported as
#                           mode specific preference (by default off) but
#                           it does not work
#                         - smartPaste is now supported as mode specific preference (by default off,
#                           since it fails to work properly)
#                         - M2::showFullName bindings are global, now treated together
#                           with the other global bindings 
#                         - M2::unsetGlobalBindings (m2Mode.tcl) called conditionally
#                         - M2::fromWhichDir from m2GlobAux.tcl default dir set to
#                           Work dir within M2ShellHome
#                         - M2::expandWords includes now many more of the Modula-2
#                           reserved words such as SET, DIV, MOD etc. (m2Syntax.tcl)
#                         - Same is true for M2::standardProcs. which
#                           includes FLOATD LONG MIN MAX (m2Syntax.tcl)
#                         - MacMETH specific reserved words or standard procedures
#                           are added in separate lines (m2Syntax.tcl)
#                         - newPref variable standardProcColor green and little
#                           used libColor blue 
#                         - templateDEFINITION renamed to M2::templateDEFINITION (m2Templates.tcl)
#                         - 2nd variant of completions made the final one (1st discarded)
#                         - electricSemicolon now M2 pref to turn it off by default
#                         - M2::expandSpace now also bound to standard Ctrl^TAB (and F1) instead
#                           of Cmd^TAB only (expansions should now again be accessible in OS X)
#                         - same for M2::completePrevWord, but this causes a conflict with
#                           previous real TAB insertion (Ctrl^Opt^TAB)
#                         - Real TAB insertion now bound to even less accessible 
#                           (Ctrl^Opt^Cmd^TAB), which is quite good so, since this feature
#                           is there only for "emergency cases"
#                         - M2::expandSpace now also bound to new more convenient
#                           alternatives, notably on PowerBook keyboards: Numkeypad-1 and ESC 
#                         - new preference electricNumKeypad_1 allows to control electric feature
#                           of Numkeypad-1
#                         - All binding management from m2AdjPrefs.tcl moved to m2Bindings.tcl
#                           => introduced procs M2::activateSpaceBarExpansion,
#                           M2::deactivateSpaceBarExpansion, M2::activateElectricNumKeypad1,
#                           and M2::deactivateElectricNumKeypad1
#                         - improving uninstallation, which did not work reliably
#                           anymore under Alpha 7.6. However, it appears not to be
#                           possible to really remove everything properly. E.g. there
#                           remains a hidden CVS folder inside the "$HOME:Tcl:Modes:M2 Mode:" 
#                           folder.
#                         - fixed procs M2::wrapComment and M2::wrapText from m2Edit.tcl
#                           They failed miserably due to changes in the underlying Alpha
#                           commands routines.
#                         - improved the behavior of above 2 procs by testing for meaningful
#                           parameters. Avoids touching the text if M2_FillRightMargin <=
#                           leftMargColumn and informs user about problem.
#                           
#                           REMAINING ISSUE(s): Global bindings issue not resolved, since
#                           V 3.8.1 does now initially ask user for activation of
#                           the global bindings. This behavior is quite convenient
#                           and should not interfere with any Alpha users never
#                           activating the mode. However, the proposed feature
#                           solution (globalM2Bindings 1.0) forming part of the 
#                           Alpha 7.6 release is an alternative, which looks even 
#                           better.  Yet, I would prefer to have an activation mechanism
# 			    of this feature available for first time users, which is
# 			    of a similar convenience as the existing implementation.  
# 			    
#    af       26.02.03    V 3.8.2
#                         - Deinstallation sequence modified (prefs deleted only at end)
#                         - However, deinstallation should no longer be attempted
#                           since Alpha 7.6 does not like this at all => warning added
#                         - globalM2Bindings.tcl integrated as additional feature
#                           "alpha::feature globalM2Bindings 1.0" to control global 
#                           bindings anytime. User is only asked about this global
#                           feature (yet implementation would allow to control the
#                           behavior merely from within the M2 mode; cheap 
#                           implementation, yet the behavior is conceptually only
#                           as if a global feature is used.
#                         - newPref flag globalOpenBindings statement moved from
#                           alpha::mode M2 3.8.2 {... to m2Prefs.tcl 
#                         - All code involved in the interaction between M2 mode
#                           and globalM2Bindings.tcl made safe, so that the
#                           dependence of globalM2Bindings.tcl on M2 mode is
#                           properly checked first before doing anything. 
#                           Otherwise warning messages.
#                         - fixing of all prefs assignments done which were
#                           assigned explicitely before newPref statements. E.g.
#                           M2WrapRightMargin was assigned two blanks instead of 65
#                           if M2modeVars(m2_fillRightMargin) didn't yet exist
#                         - global pref indentUsingSpacesOnly made a mode requirement
#                           since M2 specific setting never got recognized and 
#                           outcommented in m2Prefs.tcl, since it showed up
#                           in prefs dialog (F12) twice. Bug in Alpha 7.6?
#                         - M2::showFullName now available only in M2 mode
#                         - m2Prefs.tcl and m2Config.tcl assign m2_shellName,
#                           m2_errListDOK etc. with [file join
#                         - M2::adjustGlobalOpenBindings in m2AdjPrefs.tcl
#                           does now call package::activate "globalM2Bindings"
#                           or package::deactivate "globalM2Bindings"
#                         - Same for m2Bindings.tcl
#                         - No more binding done in alpha::mode activation
#                           script
#                         - M2::setGlobalBindings in m2Bindings.tcl made
#                           more effective (ensures M2 specific bindings)
#                         - M2::makeOnOrOff from Vince used to make status
#                           of global feature "globalM2Bindings" consistent
#                           with possible changes of pref 
#                           M2modeVars(globalOpenBindings). This new
#                           proc should form part of AlphaTcl >= 8.0d1
#                           as package::makeOnOrOff
#                           
#                         No known remaining issue(s)
# 			    
#    af       28.02.03    V 3.8.3
#                         - M2::adjCurLnToIndentBelow now bound to 
#                           Opt^Shift^Tab instead of previous Cmd^Shift^Tab
#                           since the latter fails under OS X (reverse of
#                           Cmd^Tab)
#    af       03.03.03    V 3.8.4
#                         - wordWrap (later lineWrap) assignment in
#                           m2Prefs.tcl fixed (was done twice)
#    af       07.03.03    - Made another attempt at getting better control
#                           over wordWrap (later lineWrap) by cleaning up
#                           more of m2Prefs.tcl (contained "newPref flag
#                           wordWrap {0} M2" twice) Unfortunately did not
#                           really help
#    af       28.03.03    V 3.8.5
#                         - Added all changes made and committed to cvs by
#                           Vince Darley (m2Marking.tcl, m2ShellUse.tcl)
#    af       29.03.03    V 3.8.6
#                         - Added one more change in m2Marking.tcl
#    af       12.04.03    V 3.8.7
#                         - unixMode case fix by Vince Darley
#                         - broken templates fixed by conditional calls to
#                           tabsToSpaces in m2Edit.tcl
#                         - broken previousLine (in Alpha8 8.0b8) circumvented
#                           in M2::getIndentation in m2Edit.tcl by using 
#                           prevLineSelect to fix endless loop (was pretty nasty 
#                           bug, which crashed the entire system regularly)
#    af       30.04.03    V 3.8.8
#                         - elecCompletions removed (by Vince Darley - v1.11 -> 1.12)
#    af       18.05.03    V 3.8.9
#                         - calling tclAE::installEventHandler instead of eventHandler
#                           in m2ShellUse.tcl if Alpha >= 8 (however, does not work)
#                           To support Alpha 7.6 I still use eventHandler (the only
#                           technqiue which seems to work in Alpha8 8.0b8
#                         - global prefs (in m2Prefs.tcl) handled in more general way
#                           to support Alpha 7.6 again (Vince's changes made the mode
#                           to be partly broken under 7.6)
#                         - M2Completions.tcl and m2Marking.tcl was broke under 7.6 due to 
#                           lsort -dictionary. Made this conditional for >= 8.0 only.
#                         - Explicit deinstallation of entire mode, since Alpha's
#                           core no longer supports any deinstallation (uninstall
#                           is of course an ugly action, but obviously wanted by 
#                           some users)
#                         - globalM2Bindings v1.1: Improved activation and deinstallation
#                           Works now for any combination of deinstallation or installation
#                           of mode M2 and global feature  globalM2Bindings
#                         - Fixing in m2Config.tcl file name assignment for err.ALPHA
#                           and token.ALPHA
#                         - Tried out M2::dummyHandler approach as suggested by Craig
#                           Upright in an attempt to fix opening of work files via
#                           Apple Events (oM2f,comp) without needing to load/launch
#                           M2 mode once per Alpha session. Did not help, but did not
#                           hurt either
#                         - Fixed opening of work files for AlphaX vs Alpha8 (Classic)
#                           by adding proc mac2unix (from Frédéric Boulanger) into 
#                           m2GlobAux.tcl and altering opening algos accordingly in 
# 			    M2::openM2WorkFiles from m2CompErr.tcl
#                         - Moved proc M2::makeOnOrOff from m2Bindings.tcl to 
#                           m2BackCompatibility.tcl
#                         - In proc M2::DblClick forced M2 mode by win::ChangeMode M2
#                           to overcome effect of bug #933 in Alpha8/X
#                         - Fixing broken M2::openOtherLibModule from m2Utils.tcl in 
#                           Alpha8/X: In Alpha 7.6 a construction like set path 
#                           "[file join $path ""] results in a path separator at end.  
#                           None is added in Alpha8/X. In procs M2::otherLibModule
#                           statements added ot  assign variable pathSep 
#                           which makes the code portable among all current AlphaTcl 
#                           versions. 
#                         - Reversed use of M2::dummyHandler, since events were not
#                           reliable passed on for all Alpha versions (7.6 8 X)
#                         - m2BackCompatibilty.tcl belongs now to kernel of M2 mode and 
#                           is loaded always by m2Load.tcl to ensure accessibility of 
#                           proc M2::makeOnOrOff (for package::makeOnOrOff available
#                           only in Alpha 8/X)
#                         - Including Vince's changes to m2Mode.tcl (v1.12 -> v1.13)
#                         - Including Vince's changes to Modula-2 Help (v1.7 -> v1.8)
#                         - Source should now be fully CVS controlled
#                         - Testing of mode in OS 9.2.2, Classic, and OS X 10.2.6 using 
#                           Alpha 7.6, Alpha8 8.0b8, and AlphaX 8.0b8. All known bugs 
#                           removed. Seems to work in all combinations of OS and Alpha.
#                         - Final cleanup for release of this mode (commitment)
#    af       25.06.03    V 3.9.0
#                         - electricReturn removed and newPref flag indentOnReturn
#                           added (see CVS modification by Vince Darley - v1.14 -> 1.15)
#                         - Fixing a bug in m2CompErr.tcl where M2::openWorkFiles failed 
#                           with a relative path in fileToEditName which attempted to 
#                           access a file outside the shell's directory.
#                         - Improved error message display for M2::openWorkFiles
#    af       12.07.03    V 3.9.1
#                         - Explanations by Craig Upright for pref indentOnReturn 
#                           added (see CVS modification by Craig Upright 
#                           (see "mode electric prefs balloon/help text" 
#                           m2Mode.tcl - v1.15 -> v1.16) and m2Prefs.tcl - 1.7 and 1.8)
#                         - Ignoring latest change made by Vince Darley (see CVS 
#                           modification of m2Prefs.tcl - v1.8 -> 1.9), since he
#                           obviously overlooked that the purpose of the newPref flag
#                           elecCompletions is only for support of Alpha 7.6.
#                         - m2Load.tcl - v1.4 -> v1.5 by Vince
#    af       22.08.03    V 3.9.2
#                         - Introducing in m2Utils proc M2::SetDfltFont, menu cmd CTRL-8
#    af       23.09.03    V 3.9.3
#                         - Removal of pref wordBreakPreface 
#                           (Bernhard Desgraupes m2Prefs.tcl v1.10 -> v1.11)
#                         - Bind 0x54 to Bind KPad2
#                           (Vincent Darley m2Bindings.tcl v1.6 -> v1.7)
#                         - Further fixings of key pad bindings
#                         - Fixing binding for KPad2 to proper proc, i.e. M2::SetDfltFont
#    af       21.10.03    V 3.9.4
#                         - Removal of pref wordBreakPreface 
#                           (Vincent Darley m2Edit.tcl v1.6 -> v1.7)
#    af       06.11.03    V 3.9.5
#                         - Fixing broken M2::defToMod with lineStart problem
#                           (af m2Templates.tcl v1.3 -> v1.4)
#                         - New feature in M2::defToMod copies now also
#                           section markers into the MOD file
#    af       11.12.03    V 3.9.6
#                         - Fixing broken M2::deactivateElectricNumKeypad1
#                           in AlphaX 8.0b14 in m2Bindings.tcl
#                         - Major cleaning up help texts (preceeding comments)
#                           for all preferences in m2Prefs.tcl
#    af       03.01.04    V 4.0.0
#                         - Adding proce for space bar expansion to support
#                           procedure declaration in definition modules
#    af       14.05.04    V 4.0.1
#                         - globalM2bindings.tcl offers now description
#                           (Craig Upright v1.3 -> v1.4)
#                         - m2Config.tcl using prompt instead of getline
#                           (Craig Upright v1.5 -> v1.6)
#                         - m2Templates.tcl using prompt instead of getline
#                           (Craig Upright v1.5 -> v1.6)
#                         - m2Prefs.tcl converted wordWrap (later lineWrap)
#                           to variable pref and added Help button to new
#                           prefs dialogs
#                           (Vince Darley v1.13 -> 1.14 -> 1.15)
#                         - m2BackCompatibilty.tcl lremove use fixed and 
#                           adjusted (Vince Darley v1.2 -> 1.3)
#                         - m2HelpLookup.tcl implemented first part of rfe 
#                           1396 to resolve help vs description, etc.
#                           (Vince Darley v1.6 -> 1.7)
#                         - msMode.tcl package description argument
#                           (Craig Upright v1.21 -> v1.22)
#    af       24.09.04    V 4.0.2
#                         - proc M2::adjustGlobalOpenBindings in 
#                           m2AdjPrefs.tcl uses now package::makeOnOrOff
#                           instead of the defunct M2::makeOnOrOff. This
#                           fixes the bug with M2 preference settings (F12)
#                           for pref "GlobalOpenBindings" (Ctrl-0, -1,
#                           and Ctrl-2)
#                         - Renaming pref globalOpenBindings to globalM2Bindings
#                         - Adding support for new (optional) developer flags:
#                           useLatestDevM2Mode and m2ModeDevFolder
#                           
#                           This allows to have the following few
#                           statements in the M2Prefs.tcl file:
#                           
#                                   namespace eval M2 {}
#                                   # Use latest development M2 mode instead of the preinstalled one
#                                   newPref flag useLatestDevM2Mode  {1} M2 M2::adjustM2Prefs
#                                   # Folder in which the latest development M2 mode resides 
#                                   newPref variable m2ModeDevFolder 
#                                   {/Volumes/HD/Documents/Origs!!/M2 Mode/M2 Mode/Modes/M2 Mode} M2
#                                   # Make latest development M2 mode active if necessary
#                                   if $M2modeVars(useLatestDevM2Mode) {
#                                     set m2ModeDir "$M2modeVars(m2ModeDevFolder)"
#                                     # Source the M2 mode
#                                     source [file join ${m2ModeDir} m2Load.tcl] 
#                                     # Source global feature global M2 bindings
#                                     source [file join ${m2ModeDir} globalM2bindings.tcl]
#                                   }
#                           
#                         - Introducing M2::adjustLatestDevModeUse in 
#                           m2AdjPrefs.tcl
#                         - Conditional creation of critical procs when using 
#                           new pref flag useLatestDevM2Mode for:
#                            - M2::loadMode in m2Load.tcl
#                            - menu::buildM2 in m2Menu.tcl
#                         - For same reason global var defaultFont is
#                           no longer assumed to exist in m2Prefs.tcl
#    af       27.09.04    V 4.0.3
#                         - Fixing initialization bug in m2Bindings.tcl
#                           still using M2::makeOnOrOff instead of 
#                           package::makeOnOrOff
#                         - namespace eval M2 {} in m2Load.tcl
#    af       11.11.04    V 4.1.0
#                         - Support for P1 Modula-2 compiler flags:
#                           pref m2_P1CompFlagList from m2Prefs.tcl 
#                           new case in proc M2::autoEditCompilerFlags
#                           from m2GlobAux.tcl
#                         - Bug fix: M2::templatePROCEDURE in
#                           m2Templates.tcl did call prompt only
#                           with one argument instead of the now
#                           required two
#                         - Adding completion procd
#    af       20.02.05    V 4.1.1
#                         - Adjustments for latest AlphaTcl:
#                         - Removing essential content of m2BackCompatibilty.tcl
#                           (Vincent Darley m2BackCompatibilty.tcl v1.3 -> v1.4
#                           more alphaHooks.tcl cleanup, renaming changeMode) 
#                         - m2Config.tcl: tclLog -> alpha::log
#                           (Vincent Darley m2Config.tcl v1.7 -> v1.8
#                           remove tclLog usage from AlphaTcl)
#                         - m2Edit.tcl: M2::notAComment and M2::selectNestedM2Comment
#                           fixed
#                           (Vincent Darley m2Edit.tcl v1.8 -> v1.9 
#                           more MarkFile procs handle -w $win)
#                         - m2Edit.tcl: M2::getCurLine, M2::discardBullet,
#                           M2::jumpToTemplatePlaceHolder, M2::getIndentation,
#                           M2::correctIndentation, M2::indentCurLine,
#                           M2::indentLine, M2::modulaTab (fixed)
#                           (Craig Upright m2Edit.tcl v1.9 -> v1.10 
#                           * [M2::correctIndentation] accepts 'args' (-w <win>))
#                         - m2HelpLookup.tcl: M2::m2Help (actually already
#                           fixed in v4.1.0 but my version not uploaded on cvs)
#                           (Vincent Darley m2HelpLookup.tcl v1.6 -> v1.7 
#                           implemented first part of rfe 1396 to resolve
#                           help vs description, etc.)
#                         - m2Marking.tcl: M2::M2MarkFile
#                           (Vincent Darley m2Marking.tcl v1.8 -> v1.9 
#                           -> v1.10 more MarkFile procs handle -w $win)
#                         - m2Mode.tcl: 
#                           (Vincent Darley m2Mode.tcl v1.26 -> v1.27
#                           more alphaHooks.tcl cleanup, renaming changeMode)
#                           wordWrap vs. lineWrap fixed the erroneous 
#                           global replace
#                           (Vincent Darley m2Mode.tcl v1.27 -> v1.28
#                           Renamed 'word wrap' to 'line wrap')
#                           (Vincent Darley m2Mode.tcl v1.28 -> v1.29
#                           more MarkFile procs handle -w $win)
#                         - m2Prefs.tcl: 
#                           (Vincent Darley m2Prefs.tcl v1.18 -> v1.19
#                           Renamed 'word wrap' to 'line wrap')
#                         - m2ShellUse.tcl: M2::launchShellAndSimulate
#                           and M2::AskRAMSESToOpenFile
#                           (Vincent Darley m2ShellUse.tcl v1.8 -> v1.9
#                           replaced all uses of dosc by AE code)
#                         - Updating URLs in M2Completions.tcl and
#                           otherwise everywhere to latest values
#    af       12.05.05    V 4.1.2
#                         - Improved launch failure message for the case of
#                           disk full condition
#    af       23.05.05    V 4.1.3
#                         - Updating Help for latest URLs
#                         - Updating M2Completions.tcl for latest URLs 
#                         - Adding new proc M2::HyperiseURLs in m2Utils.tcl
#                         - M2::SetDfltFont from m2Utils.tcl calls M2::HyperiseURLs
#                         - M2::defBODY from m2Templates.tcl calls M2::HyperiseURLs
#                         - M2::modBODY from m2Templates.tcl distinguishes 2 
#                           new modes: M2IsProgModule and M2IsLocalModule. 
#                           Behavior adjusts accordingly (long overdue 
#                           distinction)
#                         - M2::askForModuleName counts for user length of
#                           module name (long overdue)
#    af       03.06.05    V 4.1.4
#                         - Fixing bugs in new template functions (flags not 
#                           always consistently set)
#                         - New and more consistent completions for 
#                           procedure declarations in DEFINITION modules
#                         - Dialog for local modules no longer asks for 
#                           ident of program module
#                         - Local modules may have an ident longer than 12
#                           chars
#                         - Local module generation results in proper 
#                           placing of cursor after insertion
#                         - Expansion of reserved word DEFINITION results
#                           in proper placing of cursor after insertion
#                         - New binding (Ctrl-Shift-J) as reverse of 
#                           Ctrl-Shift). It splits a line at the current 
#                           position and indents second part in a M2
#                           syntax specific way (BTW Ctrl-J joins).
#                         - M2::jumpToTemplatePlaceHolder improved so
#                           that it is possible to break current line
#                           if cursor is exactly before an END or ELSE
#                           (value 4 returned to indicate unindent)
#                           This measure improves behavior to RETURN 
#                           considerably.
#    af       24.06.05    V 4.2
#                         - Bug fix: M2::findNextError failed for multiple 
#                           files containing errors to switch windows
#                         - Introducing M2::getM2ErrMsg in m2CompErr.tcl
#                           to support improved behavior of M2::findNextError
#                           in case user has closed a file currently
#                           contained in m2ErrRing
#                         - M2::convertErrLstToErrALPHA introduced to
#                           create M2_err.ALPHA from a possibly present
#                           M2_err.LST. Note, the RAMSES shell deletes the
#                           err.LST from the M2ShellHome.  First parameter from
#                           AppleScript (osascript generated by sh function
#                           openM2WorkFiles) passed to M2::EventHandlerAlpha8
#                           can be used to distinguish whether to call
#                           M2::convertErrLstToErrALPHA or not.  The file
#                           M2_err.ALPHA is written in a format, which lists
#                           errors per row and column instead of the absolute
#                           file positions as in err.ALPHA.
#                         - Introduced preferences openP1WorkFiles and
#                           m2_P1AuxFileCacheFolder. Flag openP1WorkFiles
#                           indicates how proc M2::openM2WorkFiles should
#                           call M2::openM2WorkFiles.
#                         - M2::EventHandlerAlpha8 maintains new 
#                           preference flag openP1WorkFiles to indicate to
#                           M2::openM2WorkFiles in which mode to operate, so the
#                           M2 mode can distinguish whether it is called via the
#                           RAMSES shell (MacMETH compiler, p1InUse = FALSE) or
#                           RASS-OSX utilities 'mk' and 'mk1'.  Since flag
#                           openP1WorkFiles indicates how proc
#                           M2::openM2WorkFiles should call M2::openM2WorkFiles,
#                           this means that last call of AlphaX via a shell
#                           determines how the next menu command "M2 -> Open
#                           Work Files" (CTRL-0) should operate. You can anytime
#                           override what M2::EventHandlerAlpha8 by using the
#                           standard preference dialog of the M2 mode.
#                         - p1InUse = TRUE (see procs M2::openWorkFiles and 
#                           M2::openM2WorkFiles) requires the presence of
#                           M2_ErrListP1.DOK as well as M2_err.LST in
#                           folder as given by pref m2_P1AuxFileCacheFolder
#                         - Thanks to all changes described above, proc 
#                           M2::openM2WorkFiles fully supports now the marking
#                           and display of errors either for MacMETH compiler or
#                           the P1 compiler (behavior depends on actual
#                           parameter value p1InUse as determined by M2 pref
#                           openP1WorkFiles)
#                         - proc M2::curUsersHome (m2GlobAux.tcl) introduced
#                         - Bug fix: proc M2::removeAllM2ErrMarks (m2CompErr.tcl) 
#                           no longer affects windows (e.g. belonging even to
#                           another mode) which are not listed in m2ErrRing
#    cbu      21.03.06    V 4.2.1
#                         - [select] replaced by [selectText].
#                           
#===========================================================================
# ◊◊◊◊ Basic initialization of the M2 mode ◊◊◊◊ #
#===========================================================================

alpha::mode M2 4.2.1 {
    # activation script, only when we first activate the mode
    M2::enterM2Mode
} {*.mod *.MOD *.def *.DEF *.prj *.PRJ *.DTF *.MOD.MSTR *.m2 *.M2} {
    m2Menu indentUsingSpacesOnly
} {
    # This block will be automatically evaluated when Alpha starts
    # up, irrespective of whether M2 mode is ever used.
    if {${alpha::macos}} {
	# The following allows to force the activation of M2 mode
	# such as this file is scanned and mode can receive anytime
	# a message to open M2 working files
	if {[set alpha::version] >= "8.0"} {
	    namespace eval M2 {}
	    tclAE::installEventHandler oM2f comp M2::EventHandlerAlpha8
	    # proc M2::dummyHandler {arg1 arg2} {eval M2::EventHandlerAlpha8 "$arg1" "$arg2"}
	} else {
	    eventHandler oM2f comp M2::m2EventHandler
	}
    }
    
    # Do final configuration checking to ensure preconditions
    # for M2 mode if M2 is actually activated first time
    hook::register mode::init M2::initializeM2 M2
    set unixMode(Modula2) {M2}
    # Ramses shell uses creator 'RAMS' for 'TEXT' and 'MoTx'
    # (MDP - Model Definition Programs) files
    set modeCreator(RAMS) M2

    addMenu m2Menu "•145" "M2"
} maintainer { 
    "Andreas Fischlin" <RAMSES@env.ethz.ch>
    <http://www.ito.ethz.ch/SysEcol/People/af/Fischlin_Andreas.html>
    and
    <http://www.sysecol.ethz.ch/SimSoftware/RAMSES/>
} uninstall {
    if {[askyesno "You should NOT deinstall preinstalled modes (see also Modula-2 Help). \
        For upgrading try a reinstallation. Really proceed?"] == "yes"} {
	# Prefs and variables
	M2::uninstallAllDefs
	# Help
	M2::uninstallFile "[file join $HOME Help "Modula-2 Help"]"
	# Completions and Completions tutorial
	M2::uninstallFile "[file join $HOME Tcl Completions "M2Completions.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Completions "M2 Tutorial.M2"]"
        # Mode
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2ShellUse.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2Marking.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2Prefs.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2Edit.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2Bindings.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2AdjPrefs.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2Config.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2Menu.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2Syntax.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2Templates.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2HelpLookup.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2Utils.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2GlobAux.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2BackCompatibilty.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2CompErr.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2Load.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "m2Mode.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Packages "globalM2bindings.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "globalM2bindings.tcl"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" "tclIndexx"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" CVS "Entries"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" CVS "Repository"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" CVS "Root"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" CVS "Tag"]"
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode" CVS][file join ""]"
	# The following will fail, since the folder still contains a
	# hidden CVS folder, containing files 'Entries', 'Repository', 'Root',
	# and 'Tag'. I decide to leave this folder untouched during a deinstallation.
	M2::uninstallFile "[file join $HOME Tcl Modes "M2 Mode"][file join ""]"
	# 
	set msg "M2 deinstallation done: All mode's objects removed unless reported otherwise."
	if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
	    alertnote [set msg]
	} else {
	    status::msg [set msg]
	}
    }
} description {
     Supports the editing of source files programed in Modula-2
} help {
    file "Modula-2 Help"
}

proc m2Mode.tcl {} {}

namespace eval M2 {}

# If installation of mode fails, it may help to set M2::installDebugFlag to "1"
set M2::installDebugFlag 1
set M2::installDebugFlag 0
if {[set M2::installDebugFlag]} {
    alertnote "At very begin of scanning/parsing of m2Mode.tcl"
}

# In Alpha8/X normally used eventhandler
proc M2::EventHandlerAlpha8 {p1InUse dummy} {
    global M2::installDebugFlag
    global M2modeVars
    global tcl_platform
    if {[set M2::installDebugFlag]} {
	alertnote "in M2::EventHandlerAlpha8"
    } else {
	# alertnote "in M2::EventHandlerAlpha8"
    }
    # p1InUse contains "oM2f\comp..." if called by RAMSES or MacMETH shell"
    if { [ regexp {oM2f} $p1InUse ] | ($tcl_platform(platform) != "unix") } then {
	set p1InUse "FALSE"
	if {![M2::checkForErrALPHA] | ![M2::checkForM2Shell] | ![M2::checkForErrDOKFile]} {
	    M2::checkM2Configuration
	}
    }
    # Adjust preference automatically so that call of M2::openWorkFiles
    # via M2 menu "Open Work Files" or global bindings (Ctrl-0) works the
    # the same as last used call of this routine. Moreover, M2 mode preference
    # openP1WorkFiles can be set by the user anytime by using the mode's 
    # ordinary preference setting mechanisms.
    if { "$p1InUse" == "TRUE" } then {
	# alertnote "Called by RASS-OSX utility"
	set M2modeVars(openP1WorkFiles) "1"
    } elseif { "$p1InUse" == "FALSE" } then {
	# alertnote "Called by RAMSES or MacMETH shell"
	set M2modeVars(openP1WorkFiles) "0"
    } else {
	alertnote "Error: Called by unknown mechanisms. Will abort opening M2 working files!"
	return
    }
    #loadAMode M2
    prefs::modified M2modeVars(openP1WorkFiles)
    # alertnote "M2modeVars(openP1WorkFiles) $M2modeVars(openP1WorkFiles)"
    M2::openWorkFiles
}


# Determine current Alpha version (M2::curAlphaV)
# make sure M2::curAlphaV exists always
set M2::curAlphaV [set alpha::version]
regexp {[0-9]+\.[0-9]+} [set M2::curAlphaV] M2::curAlphaV

# Alternative methods to determine versions:
# alertnote "Alpha: [alpha::package versions Alpha]"
# alertnote "AlphaTcl: [alpha::package versions AlphaTcl]"
# alertnote "Tcl/Tk: [info tclversion] ([info patchlevel])"


# this procedure is called each time the mode M2 is entered, e.g. by opening a file 
# with the appropriate extension
# (Note, the mode fails if this procedure would be named to M2::enterMode)
proc M2::enterM2Mode {} {
    # We need this one first to make sure that any AlphaTcl procs are in
    # place for older versions.
    m2BackCompatibility.tcl
    global M2::installDebugFlag
    if {[set M2::installDebugFlag]} {
	alertnote "Entering M2 mode"
    }
    status::msg "Entering M2 mode"
    M2::loadMode
}

# Called the first time M2 mode is entered
proc M2::initializeM2 {} {
    global M2::installDebugFlag
    status::msg "Initializing M2 mode"
    M2::checkM2Configuration
    M2::setDefltM2Configuration
    M2Completions.tcl
    status::msg "M2 mode successfully initialized"
    if {[set M2::installDebugFlag]} {
	alertnote "In M2::initializeM2: M2 mode successfully initialized"
    }
}

# Used during deinstallation to actually remove not just tcl,
# completions, and help files but also these defs added by prefs::add plus
# the global bindings to really remove all M2 stuff
proc M2::uninstallAllDefs {} {
    global M2TokenFile M2LeftShift M2ShellName M2MaxLineLength M2ShellHome M2ErrFile
    global M2Author M2RightShift M2WrapRightMargin M2errDOKFile M2SaveState 
    global M2firstInitForBindings M2modeVars M2::installDebugFlag

    # unBind global bindings should they be active
    if {[info exists M2firstInitForBindings] && [info exists M2modeVars(globalOpenBindings)]} {
	if {$M2modeVars(globalOpenBindings)} {
	    # first clear flag or M2::unsetGlobalBindings won't unbind
	    set M2modeVars(globalOpenBindings) "0"
	    prefs::modified M2modeVars(globalOpenBindings)
	    M2::unsetGlobalBindings
	    set msg "Returning from call to M2::unsetGlobalBindings"
	    if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
		alertnote [set msg]
	    } else {
		status::msg [set msg]
	    }    
	}
    }
    # Make sure global bindings vars/flags get really purged completely
    if {[info exists M2firstInitForBindings]} {prefs::removeObsolete M2firstInitForBindings}
    if {[info exists M2modeVars(globalOpenBindings)]} {prefs::removeObsolete M2modeVars(globalOpenBindings)}

    # delete all other mode variables
    set uninstallDefs [list \
      TokenFile LeftShift ShellName MaxLineLength ShellHome ErrFile \
      Author RightShift WrapRightMargin errDOKFile SaveState \
      firstInitForBindings modeVars]
    foreach def $uninstallDefs {
	if {![info exists M2$def]} {continue}
	prefs::modified M2$def
	unset M2$def
    }

    # report on result
    set msg "At end of M2::uninstallAllDefs"
    if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
	alertnote [set msg]
    } else {
	status::msg [set msg]
    }    
}

proc M2::uninstallFile {pfn} {
    global M2::installDebugFlag
    catch {file delete -force ${pfn}}
    if {[file exists ${pfn}]} {
	alertnote "M2 deinstallation: Unexpected error - ${pfn} could not be removed."
    } else {
	set msg "Success M2 uninstall: file ${pfn} removed."
	if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
	    alertnote [set msg]
	} else {
	    status::msg [set msg]
	}
    }
}



# M-button and curly-button don't autload the following functions
# Make sure autoloading works by implementing the two buttons
# procedures the following way

# called by the "{}" button 
proc M2::parseFuncs {} { M2::M2parseFuncs }

# called by the "M" button
proc M2::MarkFile {args} { uplevel 1 M2::M2MarkFile $args }

# option titlebar 
proc M2::OptionTitlebar {} { "M2::M2OptionTitlebar }

# called by Help file (even if mode not (yet) loaded)
proc M2::openErrListFile {} {
    global M2ShellName
    
    if {[info exists M2ShellName]} then {
	# alertnote "M2ShellName = «$M2ShellName»"
	ensureset $M2ShellName
	# win::OpenQuietly "[file join [file dirname $HOME] RMS M2Tools ErrList.DOK]" 
	win::OpenQuietly [file join [file dirname $M2ShellName] M2Tools ErrList.DOK]
    } else {
	set msg "Can't open 'ErrList.DOK', since no Modula-2 shell present or var 'M2ShellName' undefined! "
	append msg "Hint: If you have a Modula-2 shell on your system, open a new window, enter M2 mode, and close it. Then try once more."
	alertnote $msg
    }
}



