## -*-Tcl-*- (nowrap)
 # ###################################################################
 #  AlphaTcl 
 # 
 #                                        created: 10/05/2003 18:23:45
 #                                    last update: 03/21/2006 {03:12:17 PM}
 # 
 # File: "tetexComm.tcl"
 # Author: Joachim Kock <kock@mat.uab.es>
 # Many thanks to Juan Falgueras, Vince Darley, Aaron Montgomery, Geoffrey 
 # Vallis, Konrad Podczeck, Michael Hoppe, Dominique Dhumieres, and Andreas
 # Fischlin, for corrections, patches, improvements, and suggestions.  
 # Thanks to Andrew Trevorrow for writing OzTeX, then main inspiration for 
 # tetexComm.
 # 
 # DESCRIPTION: Pipe-based interface to tetex
 # 
 # To use it, choose tetexComm as 'Helper Application' for 'Typeset', and
 # use Cmd-T to typeset a document.
 # 
 # This is an fully interactive interface to tetex, based on pipes rather
 # than simply exec: when you tex the current document you get the usual TeX
 # output rolling down line by line in an interactive TeX Console inside
 # Alpha: if there is an error you can type an answer (h, e, q, x, or the
 # name of a not-found input file, etc., which will be processed).  In
 # particular if 'e' is chosen, the error line is opened immediately in your
 # TeX source document.  (Furthermore, in this case (and in the case of
 # 'x'), in an attempt to be smart, the script preserves the previous .aux
 # file, so that in next run you don't get all those missing-refs errors you
 # usually get after an interrupted tex run.)
 # 
 # When the tex run has finished, there is support for browser-like handling
 # of errors and warnings, running bibtex or makeindex, or sending the 
 # resulting dvi or pdf to the viewer of choice.  There is a fixed keybinding
 # for each of these actions, and in addition, the most likely next action is 
 # dynamically bound to <space>.  This next action can also be automatised
 # by setting the prefs variable 'autoView' to 'autoNextAction'.
 # 
 # Error/warning handling: the functions popup menu of the TeX Console
 # contains a list of all errors, warnings, and wrongfull hboxes, for easy
 # navigation within the log, and with the cursor positioned at any of
 # these, there is direct access to the corresponding position in the 
 # appropriate tex source file.  Alternatively, Ctrl-w gives a browser-like 
 # list of warnings (with functionality like a standard Alpha browser window).
 # 
 # Viewing: you'll want a viewer that automatically refreshes when the file 
 # changes on disk.  Currently the following viewers sport that feature:
 # 
 #    TeXShop <http://www.uoregon.edu/~koch/texshop/texshop.html>
 #    iTeXMac <http://itexmac.sourceforge.net>
 #    PDFViewer <http://evolve.lse.ac.uk/software/PDFViewer.app.sit>
 #    TeXniscope <http://www.ing.unipi.it/~d9615/homepage/mac.html>
 #        
 #    xdvi --- part of Gerben Wierda's tetex distribution, but requires X11.
 #    MacDviX <http://www.kiffe.com/textools.html>
 #    OzTeX <http://www.trevorrow.com/oztex/>
 # 
 # Choose which viewer you want to use in the Helper Applications Dialogue,
 # or in the TeXC Mode Prefs.
 # 
 # You can also choose 'usingPDFViewer' as dvi viewer.  This results in 
 # calling dvips and gs, before sending the resulting pdf to the chosen
 # pdf viewer.  This solution is preferred to altpdflatex because the
 # time consuming steps of dvips and gs are only performed when the pdf
 # output is actually needed, i.e. not as long as we are correcting tex
 # errors and retypesetting.

 # TeX formats and programmes: The first line of the tex source file is
 # scanned for an instruction like %&cmdname which will then be the command
 # to call the tex engine.  If cmdname is not executable it will be
 # interpreted as a -format=cmdname instruction to tex.  See the section on
 # settings and bindings for more information.


 # ------------------------------------------------------------------------
 # 
 # Changes since the version distributed with AlphaTcl 8.0b4:
 # 
 #  - TeX fileset aware (including check for dirty fileset)
 #  - preserves pwd and is conscious about closing the pipe (killing child)
 #    when interrupted
 #  - handles %&myownlatex as a command (not a format) if 'myownlatex' is
 #    executable
 #  - non-interrupted tex runs are timed a la OzTeX
 #  - shortcut for viewing, preference flag for going directly to viewer,
 #    preference flag for sending console to back while viewing
 #  - new interface to errors and warnings: ctrl-w gives a list of errors or 
 #    warnings in a browser-like window
 #  - uses its own mode TeXC, cloned from Aaron's TeXL mode, for syntax 
 #    colouring, functions menu, and better control over <return>
 #  - there is a kpsewhich-based version of TeX::findTeXFile included
 #    (To use it, uncomment Section 6.)
 #  - console fontsize is $::fontSize (possibly mode dependent)
 #  - experimental suppport for newer versions of xdvik (v.22.77).
 #    (To use it, uncomment some lines in Section 2.)
 #  - better attempt to avoid multiple xdvi processes (even with v.22.40)
 #  - bindings for returning to source file or for opening log file
 #  - error browsing now handles include files of the form ../file and 
 #    ../../file correctly
 #  - In the special case where a log files contains unbalanced parens,
 #    goto-error now opens calling file (with an apologising message).  
 #    This will be correct in nearly all cases, and in any event this sort 
 #    of log file is rare.  (Previously goto-error did not work at all for 
 #    such exceptional logs.)
 # (05/11) Correctly handles missing-file error messages and refers to 
 #         correct line in source file (even though these error messages 
 #         contain no line number information).
 #     -   Early versions of this package were reported to work under 
 #         Windows, surprisingly, although it was all desgined for unix.  
 #         The October versions did not work under Windows, due to fancy 
 #         tricks with [exec which] and [exec ps] --- these are used in the 
 #         viewing section.  The current version should eliminate these 
 #         problems by simply reverting to standard TeX mode technology if 
 #         the operating system is not unix.  
 # (06/11) Preference flag for automatically saving top window on Typeset.
 #         (This was requested by Konrad Podczeck and Geoffrey Vallis.)
 #     -   More flexible handling of format/command determination:
 #         (1) The formats which should be interpreted as commands are now 
 #         organised into a single list, for easier user modification.
 #         (2) There is furthermore an override array where the user can
 #         specify command substitutions.  This is useful in at least two
 #         situations: one is the situation where you prefer to view
 #         the output as pdf.  Then you can do for example
 #             set Tex::altComm::overrideCommands(latex) altpdflatex
 #         The other situation is if you use the epstopdf package to 
 #         convert eps graphics to pdf on the fly.  In that case you need 
 #         to enable shell-escapes, so you'll do for example
 #             set Tex::altComm::overrideCommands(pdftex) "pdftex --shell-escape".
 # (07/11) Refined regexps for errors and warnings (notably w.r.t linebreaks).
 #     -   Now handles 'multiply defined labels'!  (This is actually rather 
 #         tricky...)  Also handles missing graphics better.
 # (08/11) Several internal improvements and clean-ups: disposes of the texRun 
 #         array when the TeX Console is closed; better variable names, better
 #         path handling, better handling of unbalanced parens. 
 # (14/11) Paths are handled more generically and it might even work on Windows
 #         now --- thanks Vince for feedback and instructions.
 # (17/11) Better handling of xdvi v.22.40 --- thanks Konrad for input.
 # (19/11) Still more tolerant about unmatched parens...
 # (27/11) Support for TeXShop --- TeXShop now has refresh!
 #         Better handling of viewers.
 #     -   Installation instruction included.
 # (18/12) Fixed stupid typo obstructing dvi viewing.
 # (20/12) New and better method for determining what to view: view the
 #         most recent file!  This is much more robust than the old method
 #         of guessing from the format name...  In particular the old method
 #         failed when producing dvi with pdftex.  At the same time 
 #         incorporated rudimentary support for output formats ps and html.
 # (24/12) It is now revealed in the 'readme' that typeset is Cmd-shift-R.
 # --2004-------------
 # (15/01) Internal: reorganisation of temp aux handling.
 #     -   Support for running bibtex and makeindex in the console.  Bibtex is
 #         bound to Ctrl-b (in TeXC mode).
 # (16/01) POST-RUN SMARTNESS!  There is now a notion (and an entry in the
 #         texRun array) of 'nextAction'.  The next action is determined
 #         automatically by the sort of messages given by tex.  If there
 #         are errors then the suggested nextAction will be to
 #         error-browse.  If 'label(s) may have changed', the suggested
 #         nextAction is to run tex again.  If there is a missing bib item
 #         the suggested nextAction is to run bibtex.  (Here the mechanism
 #         is very discrete and does not insist: only the *first* time a
 #         missing bib is reported, the suggested nextAction will be
 #         'bibtex'.  If subsequently the same error is reported, we
 #         understand that the user doesn't care about bib questions right
 #         now, and he won't be bothered any more with this problem.  There
 #         is still a discrete message, but nextAction is not set to
 #         'bibtex'.)  In most cases the suggested nextAction is to view.
 #         Finally the interface to this exaggerated abuse of memory is a
 #         proc called TeX::altComm::takeNextAction, bound to <space> (in
 #         TeXC mode).  Typesetting becomes a matter of pressing space and
 #         nothing else...
 #     -   PRECISE ERROR SELECTION: When tex encounters an error it displays
 #         the line number and a few words of text surrounding the error,
 #         with a line break indicating where the error was detected.  This
 #         precious information is now taken into account when you press
 #         'e' at the error in interactive mode: instead of highlighting
 #         the whole line, the cursor is put at the exact spot where tex got
 #         upset.  Of course, often it happens that tex gets upset pretty far
 #         from where the error actually is, but in any event the precise
 #         indication is a much better starting point for the cursor movements
 #         leading to the error --- this will save you many cursor movements!  
 #         (The mechanism is conservative: if the pattern can't be found,
 #         the whole line remains selected just as in the oldfashioned
 #         way.)  This precise error selection does not yet work when going
 #         to the errors from a browser-like window.  (To implement this
 #         will require redoing the browser mechanism...)
 #     -   Internal change: tex now runs through /bin/sh like in the
 #         original tetexComm (altComm).  This seems necessary to get hold
 #         of tex's exit status.
 # (20/01) Stabler interactions with TeXShop: now uses raw Apple events 
 #         instead of osascript AppleScript, and references objects by name 
 #         instead of by index.  This resolves a bug when TeXShop had several 
 #         open pdf windows.
 # (25/01) Previously, -src-specials was appended blindly to every non-pdf
 #         command; this caused problems for some compile scripts.  Now,
 #         more conservatively, by default this option is enabled only for
 #         latex.  Please use the array of override commands to enable 
 #         source specials for other programmes if needed, or for making 
 #         other fine tunings like  pdftex  -->  "pdfetex --shell-escape".
 # (28/01) Support for TeXShop as 'dvi viewer', by callling dvips and gs
 #         behind the scenes.  (This is preferred to altpdflatex because 
 #         the time-consuming steps of dvips and gs are only performed when 
 #         the pdf output is actually needed.)
 # (03/02) Some internal reorganisation related to format determination.
 # (09/02) More automatisation options: 'autoTakeNextAction', 'autoViewAfterTexRun',
 #         or the default 'autoViewWhenNoErrors'.
 #      -  Doesn't suggest bibtex as nextAction if the latex job doesn't use
 #         bibtex!
 #      -  More flexible tex command building.  Some users didn't like the
 #         default choice of etex --- they can now change the preference
 #         variable TeX::altComm::defaultEngine to "tex" if they prefer.
 #         Behaviour change: previously, when building these compound commands,
 #         -progname was set equal to -fmt.  I don't know why...  The new
 #         default (which is set in the preference variable defaultProgName)
 #         is now "latex".  Perhaps an even more natural choice would be the
 #         empty string, in which case no -progname option is passed to tex...
 #         Please instruct me on this point.
 #      -  amstex, context, and omega recognised as known commands.
 #      -  Properly handles extension-less tex files.
 # (15/03) Fixes -editor flag for xdvi.  Also provides an example of 'expert'
 #         parameters to xdvi.
 #      -  TeXShop is given second chance if it is too slow to launch.
 # (25/03) Several internal changes at the occasion of going into CVS.
 #         Henceforth, this log can be complemented by diffs to previous
 #         version in CVS!  
 #         The most visible change is that all preference flags can now be 
 #         set in the TeXC Mode Preference Pane (in the Config Menu while the 
 #         TeX Console is frontmost). 
 #      -  Better command handling using the new -usebinsh flag to 
 #         [app::setupLineBasedInteraction].  Can now typeset also .dtx
 #         files --- thanks Vince, for all these changes.
 # (01/04) Fixed some transitional bugs: launch TeXShop error, xdvi-running
 #         issue, save-dirty problem, background running improvement, bibtex-
 #         not-working bug.
 # (02/04) Attempt to be strict about unbalanced parentheses in log files.
 #         A substitution mechanism eliminates known sources of spurious
 #         parens before parsing the log file.
 #      -  Fixes ps file removal when distilling pdf.
 # (02/05) Fixes problem in the situation where the declared dvi viewer is
 #         really a pdf viewer, but not the same as the declared pdf viewer.
 #      -  Writes a line of warning if an existing dvi or ps file is being 
 #         bypasses by pdftex and hence becomes outdated.
 #      -  Support for pdf synchronisation with iTeXMac --- thank JŽr™me
 #         Laurens and Geoff Vallis for help.  Synchronisation from source
 #         to pdf is bound to Cmd-= just like in iTeXMac.
 # (05/05) Modified [newestOutput] to be be independent of $texRun for
 #         usage outside tetexComm.  Corresponding changes in [view] and
 #         [checkForObsoleteFiles].
 # (13/05) Improved handling of unmatched parens in the case of interactive
 #         'e' command ([TeX::altComm::goToError]) (this case was not covered 
 #         by the improvements of 02/04 which only concerned error browsing).
 #         The new strategy consists in checking if the found word is a 
 #         readable file, and if not then look further back...
 # (16/05) Improved handling of unmatched parens (substitution algorithm):
 #         one more case covered (spurious parens in certain error messages).
 # (10/08) The aux file is preserved even if tex is interrupted brutally.
 #      -  Fix to [isTexRunning]: now works also before first tex run.
 #      -  There is a short Help File now!
 #         (This version is in Alpha b16, 2004-09-09.)
 # ===================================================================
 # (03/09) Fix to viewing with xdvi: handle file names with spaces in.
 #         Respect the sendConsoleToBackWhileViewing flag.
 # (05/09) No longer uses those proprietary variables
 #         TeX::altComm::DVIViewer and TeX::altComm::PDFViewer.  Instead
 #         honours the user's settings in the Helper Applications Pane.
 #         This is actually just an intermediate step towards migration
 #         to xserv, Alpha's future helper-application scheme.  Already
 #         now you can let tetexComm use xserv for viewing helpers by
 #         setting the flag TeX::altComm:useXSERV equal to 1.  Technically
 #         this means that a lot of the programme-specific viewer code
 #         has been removed from [TeX::altComm::view] and placed in
 #         viewPDF/viewDVI scripts (in appPaths.tcl and latexComm.tcl), 
 #         and drivers for xserv.
 #     --  Automatically guess document root.  If the calling tex file is
 #         not the root document in the tex project (and if it is not part
 #         of a tex fileset), a mechanism figures out which is the root
 #         file.  This works by scanning log files; it is very accurate and
 #         goes so far as to also scan tex files in order to give a correct
 #         result.  If no information is found, just use the calling file
 #         like all other tex implementations do.  (In rare cases where the
 #         calling file is part of two different projects, the user will
 #         be asked to choose.)  All this is also very fast: for a standard
 #         one-file tex job, all it takes is a [file readable jobname.log],
 #         and for complicated situations it takes a fraction of a second.
 #         This mechanism is also used by the new synchronisation code.
 # (07/09) Cmd-. is interrupt
 # (13/09) Experimental 'guess command from log file'.  If that pref flag
 #         is set, then try to do this as a last resort before using the
 #         default command.  While the guess-work seems to work well, it
 #         is not clear whether this is useful at all, or it will be just
 #         a mechanism to confuse the poor user, trapping him in an
 #         deceitful log file...
 # (15/09) There is a new proc [promptForUnixCommand] that inserts a prompt
 #         in the console and accepts any command.  Currently bound to
 #         Cmd-shift-E in TeXC mode.  This makes the tetex console a 
 #         little shell, whose pwd is the pwd of the current texRun.  
 #         This is very useful for an occasional query, like 'ls -l' or 
 #         'kpsewhich diagrams.sty', or for an exceptional tex instruction 
 #         like 'etex --ini "&latex" someFile'.  If the command is a 
 #         tex-like command, then the usual postproc meachisms take 
 #         over when finished, otherwise a new prompt is inserted.
 #         Still it is just the tetexComm console, and all the usual
 #         keyboard shortcuts continue to work.
 #     --  Fixed problem with automated retexing if the user was doing
 #         other things while tex runs: no longer calls [findOutWhichFileToTex]
 #         in second run.  To avoid this, the [typeset] command has been split 
 #         up into three procs, also needed for the custom command mechanism.
 #     --  The typesetting command is now sent as a list rather than as a 
 #         string.  This is recommended by the experts, since in this case 
 #         Tcl automatically takes care of certain quote and whitespace 
 #         problems.  It is not sufficient to protect &format tokens.  From 
 #         the shell you would quote like this: "&format", but doing this 
 #         before sticking it into the pipe does not work, because somehow it 
 #         will come out in the other end of the pipe as {&format} which the 
 #         shell will not accept.  The general trick seems to be to quote like
 #         this: '&format'.  This goes through the pipe unaltered. 
 # (16/09) The flags 'autoViewAfterTexRun', 'autoViewWhenNoErrors', 
 #         'autoNextAction' have been merged into a single variable
 #         'autoView', which can take three values: 'no automatisation',
 #         'autoViewWhenNoErrors' (default), and 'autoNextAction'.  This
 #         simplifies the prefs pane and is also the natural reflection of
 #         the fact that these flags were not at all independent.  (In fact,
 #         it also turned out that 'autoViewAfterTexRun' was not in use...)
 #         All prefs have a short description now.
 #     --  Other internal change in [postProc]: tex runs with interaction 
 #         are now nextAction-bound to "browse". 
 #         Timing uses [clock seconds] instead of [now].
 # (17/09) Better error-browse handling of 'Unknown graphics extension'
 #         in pdflatex.
 # (20/09) New flag 'cmdTIsTypesetWithtetex' which hijacks Cmd-T and
 #         redirects it to tetexComm.  This also enables typesetSelection
 #         through tetexComm.
 # (27/09) autoViewAfterTexRun restored.
 #     --  Previously -src-special was enabled for latex always.  However
 #         this is not recommended in final tex runs since it may affect 
 #         page breaking.  Hence the necessity of the new prefs flag
 #         useSrcSpecialsWithLatex, allowing the user to turn src specials
 #         on and off as needed.
 # (03/10) You can set dvi and pdf viewers in the TeXC mode prefs pane.
 #         There are also keyboard shortcuts: Shift-ctrl-v to shift
 #         viewer before viewing.  There are also new shorcuts (active in
 #         the tetex console): Ctrl-d for viewing dvi, ctrl-p for viewing
 #         pdf, in case you want to override the default mechanism of
 #         viewing always the most recent output.  Similarly there are
 #         shortcuts shift-ctrl-d for shifting dvi viewer, and shift-ctrl-p
 #         for shifting pdf viewer.  (Shifting means changing, but the
 #         word shifting is better for memorising the key binding.)
 #         This is all based on ideas and code contributed by Konrad
 #         --- thanks a lot!
 #     --  Better handling of xdvik version 22.77 (thanks Konrad).
 # (10/10) Fixed some quirks with postproc (introduced 16/09), and some
 #         further fine tuning: no longer displays key bindings if next
 #         action is taken automatically.
 #     --  Also the toc file is preserved in case of interrupted tex run.
 # (01/11) Better doc-root guessing: scan the last 1000 chars of the log
 #         file for the string "No pages of output", and don't bother with
 #         such files.
 # (11/11) Can type 'v' while tex runs to go directly to viewing (a la 
 #         OzTeX).  Typing space should trigger Next Action, but currently
 #         this does not work, since <space> is a bound key.  It will work
 #         when tetexComm adopts bindtags and hooktags.
 # --2005-------------
 # -------------------------------------------------------------------
 # The above changes and experiments were not submitted to CVS until March 2005.
 # The Cmd-T trick (20/09) has been removed again -- hopefully there will soon
 # be a more official way to merge tetexComm into mainstream Alpha-TeX...
 # -------------------------------------------------------------------
 # (March) Dropped SIG support.  Now it is all for xserv.  The ad-hoc 
 #         mechanism for synchronising tetexComm viewer settings with xserv
 #         has been replaced by a real two-way trace on the variables.
 #         The convoluted [viewPDFWithTheApplicationChosenAsDVIVIewer]
 #         has been replaced by a 'usingPDFViewer' implementation of the
 #         viewDVI xservice.  This is only slightly less flexible but ten
 #         times more transparent.  The [view] proc has been simplified
 #         considerably, since many of the special cases have moved to
 #         xserv implementations.
 #         Only xdvi is still having its own "tetexComm driver", mostly
 #         to support version 22.40.  Soon this will evolve into a proper
 #         xserv implementation.
 #     --  The tex console now uses consoleAttributes, so it can be
 #         resized and dragged around and will remember such attributes.
 #     --  More pragmatic log file scanning error reporting, cf. Bug 1815.
 #     --  Fatal errors are no longer lost, cf. Bug 1816.
 # (14/04) 'Precise error selection' now flashes the error line before 
 #         selecting the offending char.  This makes it much easier to 
 #         follow.
 # (07/07) Many changes from this Spring incorporated into the 'main branch':
 #     --  BINDTAGS!  This has simplified many things: the following procs
 #         have been abolished: TeX::altComm::carriageReturn, TeX::altComm::space,
 #         TeX::altComm::texIsRunning, TeX::altComm::isBrowserLikeWindow,
 #         TeX::altComm::downArrow, TeX::altComm::upArrow.
 #         Eventually TeXC mode will cease to exist.  
 #         There are five states, depending on the current task of the TeX Console:
 #           TeXC.idle            - nothing is happening, standard keys work
 #           TeXC.texinteraction  - tex runs, keystrokes are recorded
 #           TeXC.nextaction      - ready for next action, unmodified keys
 #           Brws                 - used for error browsing
 #           TeXC.unixprompt      - obvious
 #     --  More keybindings, and in particular un-modified ones.  Typing
 #         <space> while tex is running now works, triggering next action 
 #         as soon as the tex run has finished.
 #     --  INTEGRATION WITH THE TEX MENU AND CMD-T!
 #         (These changes are mostly in the file latexComm.tcl.)
 #         There is a xservice called 'typeset'.  The old command [TeX::typeset]
 #         determines the file to typeset and invokes this service.  So now
 #         finally, Cmd-T can be routed to tetexComm (just choose tetexComm 
 #         as implementation for the typeset service).  Additional benefits:
 #         typeset-selection works with tetexComm.
 #     --  log file scanning has been decoupled from tex run and tex console.
 #         Now operates on specified log file.  (One particular benefit of this 
 #         decoupling is that it makes it a lot easier to debug and test 
 #         user-contributed log files!)
 #     --  Improved wrongful-box patterns -- thanks Aaron!
 #     --  Namespace name changed to tetexComm.  This is a better name, and it
 #         also marks the abolition of many old prefs flags which now 
 #         follow standard helper apps and Alpha TeX mode settings.
 # (16/07) One more spurious-parenthesis case covered.
 # (18/07) tetexComm bibtex and makeindex x-services.  Thanks Konrad for
 #         code contribution.
 #         TODO: There is some overlap between the procs [bibtex], [makeindex],
 #         [bibtexCurrent], [makeindexCurrent].  This can be designed better.
 #         These two xservs fail if invoked from the menu if the TeX Console 
 #         is frontmost.  As usual, the infamous [win::TopNonProcessWindow]
 #         is to blame.
 # (15/08) Fixed Bug 1904 (bad treatment of capital 'E' and 'X' in tex prompt).
 # (24/10) Fixed [newestOutput] (Bug 1939), thanks Juan.
 # --2006-------------
 # (01/01) Fixed some key-bindings and messages.  Documentation updated.
 # (12/01) Fixed win <2> issue with [bringToFront].
 # (25/01) Better ConTeXt support.
 # (19/02) Intelligent handling of the case where an error occurs in the aux
 #         file (this sometimes happens with hyperref), and it could interfere
 #         in an unfortunate way with the auxFileCopy mechanism.  In case of a
 #         tex error in the aux file, offer the user the possibility to 
 #         automatically delete the aux file and rerun tex.
 # ###################################################################
 ##


namespace eval TeX::tetexComm {}


######################################################################
# SECTION 1: MODE.
######################################################################

proc TeX::tetexComm::setConsoleState { state } {
    variable texConsole
    win::setInfo $texConsole bindtags [list $state "TeXC"]
    win::setInfo $texConsole hookmodes [list $state "TeXC" "consoleattributes"]
}

# This part is mostly cloned from Aaron Montgomery's TeXL mode.
# Thanks a lot for this code.

proc tetexComm.tcl {} {}

alpha::mode [list TeXC "TeX Console"] 0.1.2 tetexComm.tcl {} {
    texMenu
} {
    # Initialization script.
    alpha::internalModes "TeXC" "TeX Console"
    # Place this here otherwise the binding won't be seen
    # since this file is never sourced.
    Bind 'r' <cs> {TeX::tetexComm::typeset} "TeX"
} uninstall {
    this-file
} help {
    file "teTeX Help"
}

namespace eval TeXC {}

# Used for identifying different types of errors/warnings
array set TeXC::patterns {
    errorFuncExpr {^! .*}
    errorParseExpr {! (.*)}
    warnFuncExpr {^(LaTeX|Class) (.*)Warning: .*}
    warnParseExpr {Warning: (.*)}
    overFuncExpr {^Overfull .*}
    overParseExpr {Overfull (.*)}
    underFuncExpr {^Underfull .*}
    underParseExpr {Underfull (.*)}
}

#we find errors/warnings
#group them into four categories
#then list them in order they occur (within each category)
proc TeXC::parseFuncs {} {
    variable patterns
    
    set L [list \
      "=== ERRORS ===" "$patterns(errorFuncExpr)" "$patterns(errorParseExpr)" \
      "=== WARNINGS ===" "$patterns(warnFuncExpr)" "$patterns(warnParseExpr)" \
      "=== OVERFULL BOXES ===" "$patterns(overFuncExpr)" "$patterns(overParseExpr)" \
      "=== UNDERFULL BOXES ===" "$patterns(underFuncExpr)" "$patterns(underParseExpr)" \
      ]
    foreach { divider expr pars } $L {
	lappend m $divider 0 
	set pos [minPos]
	while {[set res [search -s -f 1 -r 1 -i 0 -n -- $expr $pos]] != ""} {
	    if {[regexp -- $pars [eval getText $res] dummy word]} {
		lappend m "$word" [lindex $res 0]
	    }
	    set pos [lindex $res 1]
	}	
    }
    return $m
}

#red flag everything starting with a !
#this will pick out the error lines (and a few non-error lines)
set TeXC::commentCharacters(General) !
set TeXC::commentCharacters(Paragraph) {{! } {! } {! }}
#red flag these warnings
set TeXCKeyWords {
    Overfull Underfull "LaTeX Warning:" "LaTeX Font Warning:" "Class exam Warning:"
}
regModeKeywords -e ! -c red -k red TeXC $TeXCKeyWords
unset TeXCKeyWords
#and put commands in blue (I'm used to that)
regModeKeywords -a  -m "\\" -k blue TeXC {}


# It would be nice to colour file names in cyan.  First approximation:
# regModeKeywords  -a -m "/" -k cyan TeXC {}

hook::register closeHook TeX::tetexComm::properClose "TeXC"


######################################################################
# SECTION 2: SETUP, BINDINGS, PREFERENCES
######################################################################

# Bind Shift-Command-R to interactive typesetting:
Bind 'r' <cs> {TeX::tetexComm::typeset} "TeX"
Bind 'r' <cs> {TeX::tetexComm::typeset} "TeXC"
Bind 't' <c> {TeX::tetexComm::typeset} "TeXC"

Bind 'e' <cs> {TeX::tetexComm::promptForUnixCommand} "TeXC"

# Cmd-. is [interrupt]
Bind 0x2f <c> TeX::tetexComm::interrupt "TeXC.texinteraction"

# Bindings for when the tex run has finished:
Bind 'v' <z> TeX::tetexComm::view "TeXC"
Bind 'w' <z> TeX::tetexComm::displayErrorsAndWarnings "TeXC"
Bind 'l' <z> TeX::tetexComm::openLog "TeXC"
Bind 'e' <z> TeX::tetexComm::editSource "TeXC"
Bind 't' <z> TeX::tetexComm::typeset "TeXC"
Bind 'b' <z> TeX::tetexComm::bibtexCurrent "TeXC"
Bind 'm' <z> TeX::tetexComm::makeindexCurrent "TeXC"
Bind 'u' <z> TeX::tetexComm::promptForUnixCommand "TeXC"
# Bindings for when the tex run has finished:
Bind 'v' TeX::tetexComm::view "TeXC.nextaction"
Bind 'w' TeX::tetexComm::displayErrorsAndWarnings "TeXC.nextaction"
Bind 'l' TeX::tetexComm::openLog "TeXC.nextaction"
Bind 'e' TeX::tetexComm::editSource "TeXC.nextaction"
Bind 'b' TeX::tetexComm::bibtexCurrent "TeXC.nextaction"
Bind 'm' TeX::tetexComm::makeindexCurrent "TeXC.nextaction"
Bind 't' TeX::tetexComm::typeset "TeXC.nextaction"


# Binding of the magic auto key <space>:
Bind 0x31 TeX::tetexComm::takeNextAction "TeXC.nextaction"

# Carriage return in the TeX Console:
ascii 0x0d TeX::tetexComm::sendMore "TeXC.texinteraction"
# ascii 0x0d ::browse::Goto "TeXC.errorbrowsing"
ascii 0x0d TeX::tetexComm::sendMoreToUnix "TeXC.unixprompt"



# Bindings for browser-like errors/warnings lists:
# Bind up TeX::tetexComm::upArrow "TeXC.errorbrowsing"
# Bind down TeX::tetexComm::downArrow "TeXC.errorbrowsing"
# Bind 0x31 TeX::tetexComm::downArrow "TeXC.errorbrowsing"

set TeX::tetexComm::texConsole "*TeX Console*"



# Control to what extent viewing takes place automatically after
# a tex run.
newPref v autoView 1 TeXC "" [list \
  "no automatisation" \
  "auto view when no errors no warnings" \
  "auto view when no errors" \
  "auto view after tex run" \
  "auto next action"\
] index


# Check this to automatically send the console to back while vieweing,
# so that when you return to Alpha the tex source window is frontmost.
newPref f sendConsoleToBackWhileViewing 0 TeXC
# Check this flag to automatically save when invoking Typeset, instead
# of asking.  Or instead of first pressing Cmd-S and then Typeset.
newPref f autoSaveTopWinOnTypeset 0 TeXC
# The font size used in the tetex console.  To fit with the size of the
# console, the font size should really always be 9.
newPref v fontSize 9 TeXC
# Automatically figure out which is the base tex file (for multiple file 
# tex jobs, that have not been declared as a fileset).  (This works by
# scanning some log files.)
newPref f guessDocumentRoot 1 TeXC
# In case no magic first line is specified in the tex source file, use
# the same format as was used in previous compilation of this document
# (according to the log file).
newPref f guessFormatFromLog 0 TeXC
# When using pdf viewer for dvi, we must first distill the pdf.
# This can be done using dvipdfm which is faster, or dvips-ghostscript
# which understands all postscript specials.  (dvipdf isn't good at
# ps rotation specials, for example).
newPref f usedvipdfm 0 TeXC
# Compile with dvi src specials to allow dvi synchronisation.  This should
# be turned off at final run since src specials may interfere with page
# breaking.
newPref f useSrcSpecialsWithLatex 1 TeXC


# TeX commands and formats
# 
# The tendency seems to be that pdflatex is default in OSX:
newPref v defaultCommand "pdflatex" TeXC

# If the format specified in first line with %&format (or the lowercased
# version of it) is among the following commands, then instead of using 
# format syntax, we'll invoke tex through this command.
set TeX::tetexComm::knownCommands [list \
  tex latex pdftex pdflatex \
  simpdftex altpdftex altpdflatex \
  amstex omega \
  ]

set TeX::tetexComm::overrideCommands(context)  "texexec --pdf"

# For fine tuning or custom tex command usage, there is an array of
# override commands.  The names of the array is a command name (as
# specified in the magic %&line), and the value is the command to use.
# For example, in order to enable source specials in latex documents, use:
# set TeX::tetexComm::overrideCommands(latex)  "latex -src-specials"

# To force pdf(la)tex also of documents with %&(la)tex instruction, 
# uncomment the following lines:
# set TeX::tetexComm::overrideCommands(tex)    "pdftex"
# set TeX::tetexComm::overrideCommands(latex)  "pdflatex"

# This will not work if there are eps figures included.  In that case
# you can override with Gerben Wierda's tex-dvi-ps-pdf script:
# set TeX::tetexComm::overrideCommands(tex)    "altpdftex"
# set TeX::tetexComm::overrideCommands(latex)  "altpdflatex"

# Or you can try to use pdflatex with enabled shell escapes, allowing
# on-the-fly conversion of eps figures into pdf figures:
# set TeX::tetexComm::overrideCommands(tex)    "pdftex --shell-escape"
# set TeX::tetexComm::overrideCommands(latex)  "pdflatex --shell-escape"




######################################################################
# SECTION 3: INTERACTING WITH TEX
######################################################################

# Each time tex is launched from this interface, an array variable
# TeX::tetexComm::texRun is updated to contain information about the
# current process.  The entries in this array are:
# 
# texRun(jobName)      The name of the base file of the tex job
#                      (without path, and without extension).
# texRun(pwd)          Working directory of the tex run (i.e. directory
#                      of the base file).
# texRun(ext)          Extension of the texed file (typically ".tex" , but
#                      it might also be empty).
# texRun(callingFile)  The full path of the file from whose window the
#                      last tex run was started.
# texRun(pipeName)     Handle to the pipe through which the communication
#                      with tex takes place.
# texRun(command)      The tex command.
# texRun(pdf)          Boolean controlling viewing.
# # # texRun(xdviPid)      Pid of xdvi process launched by this interface.
# texRun(time0)        Absolute start time of the current tex process.
# texRun(_res)         Internal record of data received from tex.
# texRun(nextAction)   Suggested next action (depending on tex messages).
# texRun(missingBib)   Used only by the nextAction suggesiton mechanism.
# texRun(keystrokes)   Record of keys pressed while tex runs.
# 
# For log file scanning there is another array, texLog, which in principle 
# is independent of the texRun array.  It has just two entries:
# 
# texLog(logTxt)       Content of the log file on disk (not the console).
# texLog(includesList) A list of all files sourced by tex, with positions
#                      of where in the log file they are opened and closed.


# This proc determines which file to send to typeset.  It return a full
# pathname, and in addition five entries in the texRun array are set:
# texRun(callingFile), texRun(jobName), texRun(pwd), texRun(ext), and
# texRun(fullPathName).  If no tex'able file is found an error is raised.
# 
# If an argument is given (supposed to be a full path name), then this
# file is used as base for the calculation.  This does not mean that it
# is necessarily that file that will be tex'ed, because it might be part
# of a fileset, or the guess-doc-root mechanism might guess something else.
# 
# (This proc was previously called [findOutWhichFileToTex].)
proc TeX::tetexComm::whichFileToTypeset { {fullPathName ""} } {
    if { [string length $fullPathName] } {
	set winName $fullPathName
    } else {
	set winName [win::Current]
	set fullPathName [win::StripCount $winName]
    }
    
    variable texRun
    variable texConsole
    global TeXCmodeVars
    
    # Which file to send to tex? there are five cases:
    # 1: frontmost window is the *TeX Console*.  Use values from previous run.
    # 2: frontmost window is part of TeX fileset.  Use the base file.
    # 3: frontmost window is a stand-alone file.  Just tex it.
    # 4: frontmost window is untitled.  Save and retry.
    # 5: something else (some shell-like window).  Give up.
    
    if { $winName eq $texConsole } {
	# Case 1.
	# Since we are in a TeX console, most probably the path,
	# file name, and command are still recorded in the texRun 
	# array --- we trust this, and don't change anything:
	return $texRun(fullPathName)
    } elseif { [file readable $fullPathName] } {
	set texRun(callingFile) $fullPathName
	# Cases 2 & 3.
	if { $TeXCmodeVars(autoSaveTopWinOnTypeset) && [winDirty] } {
	    # This concerns top window, even though the fullPathName
	    # might be another window, or not a window at all...
	    save
	}
	
	# Is the current window part of TeX fileset?
	set fset [isWindowInFileset $fullPathName "tex"]
	if { [string length $fset] } {
	    # Case 2.  We are in a fileset.
	    if { [dirtyFileset $fset] } {
		switch -- [askyesno "Save current TeX fileset?"] {
		    "yes" {
			if { [catch { saveEntireFileset $fset }] } {
			    status::errorMsg "Cancelled."
			}
		    }
		    "no" {
			status::errorMsg "Cancelled."
		    }
		}
	    }
	    set fullPathName [texFilesetBaseName $fset]
	} else {
	    # Case 3.  We are not in a fileset.
	    if { [win::isDirty $winName] } {
		# -t stop|caution|note|plain
		switch -- [alert -t stop -o "" -k "Save and TeX" \
		  "The window [file tail $winName] has unsaved changes!" \
		  "Do you want to save it before you TeX it?"] {
		    "Save and TeX" {
			if { [catch {save $winName}] } {
			    status::errorMsg "Cancelled."
			} 
		    }
		    "Cancel" {
			status::errorMsg "Cancelled."
		    }
		}
	    }
	} 
	if { $::TeXCmodeVars(guessDocumentRoot) } {
	    if { [catch { set fullPathName [::TeX::guessDocRoot $fullPathName] }] } {
		status::msg "Couldn't determine root document"
	    }
	}
	
	set texRun(fullPathName) $fullPathName
	set texRun(pwd) [file dirname $fullPathName]
	set texRun(jobName) [file tail $fullPathName]
	# We don't want the tex or dtx or other extension:
	set texRun(ext) [file extension $texRun(jobName)]
	set texRun(jobName) [file root $texRun(jobName)]
    } elseif { [regexp -- {^untitled( <\d+>)?$} $winName] } {
	# Case 4.
	alertnote "Save the file first, then try again"
	error ""
    } else {
	# Case 5.
	# The window is some other sort of temporary window, 
	# not associated to a file...
	status::errorMsg "Can't typeset this window"
    }
    return $fullPathName
}

# The following proc determines which tex command to send to unix by looking 
# in the first line of the file (the file is the one whose name is stored 
# in textRun(jobName)).  No value is returned, but the entry texRun(command) 
# is set.
# 
# While it is easy to read an eventual %&token indication, it is a somewhat
# complex algorithm to build the best tex command out of it: first we see if 
# the grabbed token corresponds to some wellknown command like latex or plain.
# Otherwise we check if the token is executable.  Finally, otherwise
# we give it to tex as a -fmt argument...  In that case we are faced
# with the choice of etex versus tex:
newPref v defaultEngine "etex" TeXC;# cf. Gerben Wierda's tetex distros.
# And also with the choice of -progname...
newPref v defaultProgName latex TeXC;# which means pdflatex if pdf is detected...

proc TeX::tetexComm::findOutWhichCommand { } {
    variable texRun
    global TeXCmodeVars
    
    set thisFile [file join $texRun(pwd) $texRun(jobName)$texRun(ext)]
    
    # Grab format from the first line if possible:
    set format [lindex [TeX::getFormatName $thisFile] 0]
    set lowercaseFormat [string tolower $format]
    set texRun(pdf) [string match -nocase *pdf* $format]
    
    # Now decide what to do.  If there is no format indication...
    if { $format eq "" } {
	# ... we might try to look in the log file:
	if { $TeXCmodeVars(guessFormatFromLog) } {
	    set log [file join $texRun(pwd) $texRun(jobName).log]
	    if { [file readable $log] } {
		set cmd [reconstructCommandFromLog $log]
		if { [llength $cmd] } {
		    set texRun(command) $cmd
		}
		# If we found a good command in the log file just use it.
		# Since this is most likely a composite command of type
		# etex &latex we do not try to apply override commands to
		# these commands... 
		return
	    }
	}
	
	# If nothing was found in the log file, just use the default command:
	if { [string length $TeXCmodeVars(defaultCommand)] } {
	    set texRun(command) $TeXCmodeVars(defaultCommand)
	} else {
	    # If by accident that default command is empty, we set
	    set texRun(command) "latex"
	}
	set texRun(pdf) [string match -nocase *pdf* $texRun(command)]
	
	# If $format is a known command, use this command directly:
    } elseif { $lowercaseFormat eq "plain" } {
	set texRun(command) "tex"
    }  elseif { [lsearch -exact $::TeX::tetexComm::knownCommands $format] != -1 } {
	set texRun(command) $format
    } elseif { [lsearch -exact $::TeX::tetexComm::knownCommands $lowercaseFormat] != -1 } {
	set texRun(command) $lowercaseFormat
	
	# If $format is executable, use it as a command, even though not in
	# the list of known commands (cf. above):
    } elseif { ![catch {exec which $format} cmdPath] \
      && [string equal -length 1 "/" $cmdPath] } {
	set texRun(command) $format
	
	# Finally, if no matching command could be found, then $format is
	# used as argument to the option -fmt, and we'll now have to build
	# such a compound tex command.  There are three independent choices to
	# make: (1) pdf or not, (2) extended tex or not, (3) which -progname
	# should be given:
    } else {
	set pdf ""
	if { $texRun(pdf) } {
	    append pdf "pdf"
	}
	if { $TeXCmodeVars(defaultEngine) eq "etex" } {
	    set fmt "efmt"
	} else {
	    set fmt "fmt"
	}
	set texRun(command) "${pdf}$TeXCmodeVars(defaultEngine) -${fmt}=$format"
	# Example: "pdfetex -efmt=superpdflatex"
	if { [string length $TeXCmodeVars(defaultProgName)] } {
	    append texRun(command) " -progname=${pdf}$TeXCmodeVars(defaultProgName)"
	    # And in the example, the final command would be perhaps
	    # "pdfetex -efmt=superpdflatex -progname=pdflatex"
	}
    }
    
    # Remark <JK>: in recent versions of Gerben Wierda's tetex distro, 
    # latex is shorthand for "etex -efmt=latex -progname latex", not for 
    # "tex -fmt=latex -progname latex" as in older distributions.  
    # Because of this discrepancy, it is much safer to call tex using 
    # the 'format' as command name, as done in the switches above --- 
    # then the tex installation will take care of the rest.   (Whereas
    # calling the wrong (e)tex with -(e)fmt is likely to result in an 
    # error because the format doesn't exist and cannot be created on 
    # the fly because of lacking permission to the relevant directory.) 
    # 
    # In the last switch, we are probably in the case of a user's custom 
    # format (ztex, say), and we cannot assume that ztex exists as an
    # executable programme.  So in this case we call "etex -efmt=ztex"
    # or something similar like "pdftex -fmt=ztex -progname=latex"...
    # The exact choice depends on preference variables defaultEngine
    # and defaultProgName, as well as whether pdf appears in the
    # format string...
    
    
    
    # Override certain commands (typically substitute "tex" by "pdftex" or
    # "altpdftex", if pdf viewing is preferred to dvi viewing):
    variable overrideCommands
    if { [lsearch -exact [array names overrideCommands] $texRun(command)] != -1 } {
	set texRun(command) $overrideCommands($texRun(command))
	set texRun(pdf) [string match -nocase *pdf* $texRun(command)]
    }
    
    if { $TeXCmodeVars(useSrcSpecialsWithLatex) && 
    ![regexp -- "-src" $texRun(command)] } {
	if { $texRun(command) eq "latex" ||
	[regexp -- {(&|fmt(=|\s+))latex} $texRun(command)] } {
	    append texRun(command) " --src-special"
	}
    }
    
}



# $logfile is assumed to exist, otherwise will throw error.
# Return a tex command as a list, like for example 
#     [list etex -src-specials &latex]
# Note that this list may be empty, if no hint could be found in
# the log file.  Hence the caller should make a miminal check with
# [llength] before trying to execute the suggested command.
proc TeX::tetexComm::reconstructCommandFromLog { logfile } {
    set fd [open $logfile]
    set txt [read $fd 480]
    close $fd
    set cmd [list]
    # First find the programme:
    if { ![regexp -- {^This is ([^,]*), Version} $txt -> prog] } {
	# Without a programme it is not worth pursuing this further:
	return $cmd
    }
    switch -regexp "$prog" {
	(?i)pdfetex? {
	    set prog pdfetex
	}
	(?i)e-?tex? {
	    set prog etex
	}
	(?i)pdftex? {
	    set prog pdftex
	}
	(?i)tex? {
	    set prog tex
	}
	context {
	    set prog context
	}
    }
    lappend cmd $prog
    
    # Then look for some special instructions:
    if { [regexp -- {Source specials enabled\.} $txt] } {
	lappend cmd "-src-specials"
    }
    if { [regexp -- {\\write18 enabled\.} $txt] } {
	lappend cmd "--shell-escape"
    }

    # Finally look for a format:
    regexp -- {\(format=(\S*) } $txt -> format
    # (Sometimes (with mylatex dynamical format creation, the dynamical
    # format will be called filename_latex.efmt or something like this,
    # and in this case tex is so stupid as to write in the log that
    # the format is filename although in reality is it filename_latex.
    # We can correct this error by looking at the actual calling sequence:
    if { [regexp -- {\*\*&(\S*)} $txt -> betterFormat] } {
	set format $betterFormat
    }
    if { [info exists format] } {
	lappend cmd '&$format'
    }
    
    return $cmd
}





# Given a filename, look in nearby directories for all logfiles.  Scan each
# log file to see if it includes $filename.  Look first in the directory of
# $filename, then in its parent and grandparent, and finally in its child
# directories.  If in any of these directories some relevant log files are
# found, the subsequent dirs are not searched.  
# 
# If no log files are found, just return the trivial guess, namely that the
# file itself is the root.  If one log file is found, and there is a
# corresponding tex file, then return the name of this tex file.  If more
# than one valid log file is found in the directory, then ask the user to
# help choosing...
# 
# If the optional argument checkRefname = 1 is given then the return value
# will be a pair consisting of the doc root name and the name used to
# invoke the $filename (typically a relative name).  This variant is needed
# when invoking xdvi with sourcepositions, since for some reason xdvi only
# understands source file names if specified in exactly the same way as in
# the root document.
proc TeX::guessDocRoot { filename {checkRefname 0} } { 
    if { ![file exists $filename] } {
	error "Can't find file \"$filename\""
    }
    set filename [file normalize $filename]
    set thisdir [file dirname $filename]
    set trivialGuess [file rootname $filename]
    set skipThese [list]
    # If a log file exists for this file...
    if { [file exists ${trivialGuess}.log] } {
	set fd [open ${trivialGuess}.log]
	set logTxt [read $fd]
	close $fd
	# ...and it was not a disaster tex run:
	set endTxt [string range $logTxt end-1000 end]
	if { [regexp -- "No pages of output" $endTxt] || [string is space $endTxt]} {
	    # In this case we do not want even to suggest this
	    # file as root, ever:
	    if { $checkRefname } {
		lappend skipThese [list $filename [file tail $filename]]
	    } else {
		lappend skipThese $filename
	    }
	} else {
	    # Then we will assume that this file is in fact
	    # its own root file:
	    if { $checkRefname } {
		return [list $filename [file tail $filename]]
	    } else {
		return $filename
	    }
	    # Otherwise we'll pick it up in the thorough treatment below.
	} 
    }
    # Which dirs to look in?  Two levels up and one level down:
    lappend dirlist $thisdir
    lappend dirlist [file normalize [file join $thisdir ..]]
    lappend dirlist [file normalize [file join $thisdir .. ..]]
    foreach childdir [glob -nocomplain -type d -dir $thisdir *] {
	lappend dirlist $childdir
    }
    # Patterns for logfile scanning:
    if { $::tcl_platform(platform) eq "unix" } {
	set filePat {\(\.{0,2}/[^\s\)\{]+}
    } else {
	# Windows tex doesn't use ./ and ../ for relative paths...
	set filePat {\([^\s\)\{]+}
    }
    set res [list]
    foreach dir $dirlist {
	foreach logfile [glob -nocomplain -dir $dir *.log] {
	    set fd [open $logfile]
	    set logTxt [read $fd]
	    close $fd
	    set index 0
	    # Run through the log file and investigate everything that
	    # looks like an input file:
	    while { [regexp -indices -start $index -- $filePat $logTxt pair] } {
		set i0 [lindex $pair 0]
		set i1 [lindex $pair 1]
		set inpFile [string range $logTxt [expr $i0 + 1] $i1]
		set inpFullPath [file normalize [file join $dir $inpFile]]
		if { [string equal $inpFullPath $filename] } {
		    set jobname [file rootname $logfile]
		    # Here we are simply guessing the extension...:
		    set rootfile ${jobname}.tex
		    if { [file readable $rootfile] } {
			if { $checkRefname } {
			    # Now we know which tex file is the root document,
			    # and we know how our input file is referenced in
			    # the log file.  The problem is that in the log file 
			    # the input file is likely referred to as ./somefile.tex, 
			    # but in the actual rootfile it may be referenced by
			    # \input{somefile.tex}, possibly without the .tex
			    # extension.  
			    if { [regsub -- {^\./} $inpFile "" inpFile] } {
				# We'll have to open the root file to see:
				set fd [open $rootfile]
				set rootTxt [read $fd]
				close $fd
				set essentialName [file rootname $inpFile]
				# Now look for an input line:
				set pat "\\\\(?:include|input)\\s*\{\\s*(${essentialName}(\.tex)?)\\s*\}"
				if { [regexp -line -- $pat $rootTxt -> inpFile] } {
				    # But here the extension might be missing...
				    if { ![regexp -- {\.tex$} $inpFile] } {
					append inpFile .tex
				    }
				} else {
				    # If we didn't find the input line, then we can
				    # still use the result we had, and it is most
				    # likely that the ./ is not included.
				}
			    }
			    lappend res [list $rootfile $inpFile]
			} else {
			    lappend res $rootfile
			}
		    }
		}
		set index $i1
		incr index
	    }
	}
	# The list of dirs is prioritised: if we have already found a log
	# file, we won't spend time with dits of lower priority:
	if { [llength $res] } {
	    break
	}
    }
    set newres [list ]
    foreach r $res {
	if { ![lcontain $skipThese $r] } {
	    lappend newres $r
	}
    }
    set res $newres  
    # For some reason, the following doesn't work:
    #     set res [lremove -exact -- $res $skipThese]
    
    if { [llength $res] == 1} {
	return [lindex $res 0]
    } elseif { [llength $res] > 1} {
	set rootfile  [listpick -w 450 -h 150 \
	  -p "Please help to determine the document root: " $res]
	# This message can be annoying when synchronising, but the 
	# user will admit that it would be even more annoying if it 
	# didn't work at all.  After getting this message three times 
	# the user should think about creating a fileset!
	return $rootfile
    } elseif { [llength $res] == 0 } {
	if { $checkRefname } {
	    return [list $filename [file tail $filename]]
	} else {
	    return $filename
	}
    }
}


# Main typeset button.  If a full path name is given then that
# specific file is typeset (after filling in the corresponding
# data in the texRun array).
proc TeX::tetexComm::typeset { {fullPathName ""} } {
    variable texRun
    if { [string length $fullPathName] } {
	set texRun(callingFile) $fullPathName
	set texRun(pwd) [file dirname $fullPathName]
	set texRun(jobName) [file tail $fullPathName]
	# We don't want the tex or dtx or other extension:
	set texRun(ext) [file extension $texRun(jobName)]
	set texRun(jobName) [file root $texRun(jobName)]
    } else {
	if { [catch { whichFileToTypeset }] } {
	    status::msg "Couldn't find out which file to tex."
	    return
	}
    }
    findOutWhichCommand
    typesetCurrent
}

# Typeset as specified in the texRun array
proc TeX::tetexComm::typesetCurrent {} {
    variable texRun
    
    set completeCommand $texRun(command)
    # The extension needed for .dtx files:
    lappend completeCommand  '$texRun(jobName)$texRun(ext)'
    status::msg [join $completeCommand " "]
    # The extra exit code business here is for emulating altpdftex:
    lappend completeCommand 2>&1 && exit 0 || \
      echo TeX returned non zero exit status && exit 1
    # If no errors arise in the tex run, the typical nextAction will
    # be to view the resulting dvi or pdf:
    set texRun(nextAction) "view"
    # For timing a la OzTeX:
    set texRun(time0) [clock seconds]
    # Reset the keystrokes variable:
    set texRun(keystrokes) ""
    
    if { [info exists texRun(pipeName)] &&
	[lcontain [file channels] $texRun(pipeName)] } {
	# We are interrupting a tex run.   Perhaps it is just as correct
	# just to look if we are in TeXC.texinteraction state...
	# 
	# This means current aux file is incomplete.  If there's a cached
	# copy it's better to use that one:
	auxFileCopy copyback
    } else {
	# Save a copy of the aux file in case we interrupt tex:
	auxFileCopy create
    }

    ensureConsole -clean
    executeCommand $completeCommand
}


proc TeX::tetexComm::executeCommand { completeCommand } {
    variable texRun
    # Reset:
    closeAllPipes
    # Preserve pwd:
    set oldPwd [pwd]
    cd $texRun(pwd)
    # Set up the main pipe:
    set texRun(pipeName) [app::setupLineBasedInteraction \
      -read read -callback ::TeX::tetexComm::receiveAndDisplay \
      -closeproc ::TeX::tetexComm::postProc -usebinsh \
      $completeCommand]
    # Restore previous pwd:
    cd $oldPwd
    ensureConsole
    setConsoleState TeXC.texinteraction
}

# If a full path name is given then that specific file is bibtex
# (after filling in the corresponding data in the texRun array).
# Note that the extension is ignored, so you can call with either
# .tex or .aux, or whatever.
proc TeX::tetexComm::bibtex { {fullPathName ""} } {
    variable texRun
    if { [string length $fullPathName] } {
	set texRun(pwd) [file dirname $fullPathName]
	set texRun(jobName) [file tail $fullPathName]
	set texRun(jobName) [file root $texRun(jobName)]
    } else {
	if { [catch { whichFileToTypeset }] } {
	    status::msg "Couldn't find out which file to bibtex."
	    return
	}
    }
    bibtexCurrent
}

proc TeX::tetexComm::bibtexCurrent {} {
    variable texRun
    lappend command bibtex $texRun(jobName)
    # Typically the next action will be to retypeset:
    set texRun(nextAction) "typeset"
    # We don't want to time these auxiliary programmes:
    unset -nocomplain texRun(time0)
    ensureConsole -clean
    executeCommand $command
}

# If a full path name is given then that specific file is makeindex
# (after filling in the corresponding data in the texRun array).
# Note that the extension is ignored, so you can call with either
# .tex or .aux, or whatever.
proc TeX::tetexComm::makeindex { {fullPathName ""} } {
    variable texRun
    if { [string length $fullPathName] } {
	set texRun(pwd) [file dirname $fullPathName]
	set texRun(jobName) [file tail $fullPathName]
	set texRun(jobName) [file root $texRun(jobName)]
    } else {
	if { [catch { whichFileToTypeset }] } {
	    status::msg "Couldn't find out which file to makeindex."
	    return
	}
    }
    makeindexCurrent
}

proc TeX::tetexComm::makeindexCurrent {} {
    variable texRun
    lappend command makeindex $texRun(jobName)
    # Typically the next action will be to retypeset:
    set texRun(nextAction) "typeset"
    # We don't want to time these auxiliary programmes:
    unset -nocomplain texRun(time0)
    ensureConsole -clean
    executeCommand $command
}


# Console: 80 cols 20 rows (of Monaco 9) ---
# (the numbers 300 are arbitary):
console::create $::TeX::tetexComm::texConsole -mode TeXC \
-fontsize 9 -font Monaco -g 300 300 503 243


proc TeX::tetexComm::ensureConsole { args } {
    variable texConsole
    # TeX needs a window to write in:
    if { ![win::Exists $texConsole] } {
	::console::open $texConsole
    } else {
	if { [lindex $args 0] eq "-clean" } {
	    deleteText -w $texConsole [minPos] [maxPos -w $texConsole]
	}
    }
    bringToFront $texConsole
}


# Handles all output from tex.  For the meaning of the parameters,
# see the proc app::setupLineBasedInteraction in the file appPaths.tcl.
proc TeX::tetexComm::receiveAndDisplay {pipe status result} {
     variable texRun
     variable texConsole
     # Record the result in the global variable (needed by sendMore):
     set texRun(_res) $result
     # Print the line to the TeX console:
     if { [string length $result] } {
	 # The line we have read was nonempty
	 insertText -w $texConsole $result
	 goto -w $texConsole [maxPos -w $texConsole]
     }
}

# # Handles error signals from tex.  All it does it to set the texRun(error)
# # flag...
# proc TeX::tetexComm::errorDetector {} {
#     variable texRun
#     set texRun(error) 1
#     fileevent  $texRun(errorPipe) readable {}
# }



# Monitor all keystrokes in the TeXC.texinteraction.  Simply record the 
# last keystroke in texRun(keystrokes), then the [postProc] will look 
# there and immediately take the corresponding next action.  We only record
# one char, and only if it is known.
# there is anything to learn from it.  The only case working presently is
# if the user presses 'v' during the tex run: this will pass us directly
# to viewing (this behaviour is copied from OzTeX).
proc TeX::tetexComm::monitorKeystrokes { win pos char } {
    variable texRun
    if { [string length $char]} {
	if { [regexp {[vwtbdpm ]} $char] } {
	    set texRun(keystrokes) $char
	}
    } else {
	# This is backspace
	set texRun(keystrokes) ""
    }
}
hook::register characterInsertedHook TeX::tetexComm::monitorKeystrokes "TeXC.texinteraction"

# Carriage return in the TeX Console while tex is NOT running: 
# send the command to the tex pipe:
proc TeX::tetexComm::sendMoreToUnix {} {
    variable texRun
    # Get the last line from the console:
    set more [getText [pos::lineStart [getPos]] [pos::lineEnd [getPos]]]
    variable promptPat
    if { [regexp -- $promptPat $more "" promptPwd cmd] } {
	if { $promptPwd eq [file tail $texRun(pwd)] } {
	    append cmd " 2>&1"
	    set texRun(nextAction) "none"
	    set texRun(time0) [clock seconds]
	    insertText "\r"
	    executeCommand $cmd
	} else {
	    # This should never happen since all directory-changing
	    # procs also write to the console, and hence overwrite
	    # any old prompt that might have been out of synch with
	    # the true texRun(pwd).  All this care is taken just to
	    # ensure that the user does not issue a command from 
	    # another directory than he thinks...
	    error "Wrong pwd"
	}
    } else {
	error "Could not find unix prompt"
    }
}


# Carriage return in the TeX Console while tex is running: 
# send the command to the tex pipe:
proc TeX::tetexComm::sendMore {} {
    variable texRun
    # Get the last line from the console:
    set more [getText [pos::lineStart [getPos]] [pos::lineEnd [getPos]]]
    # Since we are now interacting with tex it is uninteresting to time it:
    unset -nocomplain texRun(time0)
    # Reset the keystrokes variable:
    set texRun(keystrokes) ""
    # Find out what the prompt is:
    regexp {[^\r\n]*$} $texRun(_res) prompt
    # The rest is what we want to send to the pipe:
    regsub "^[quote::Regfind $prompt]" $more "" more
    # Insert carriage return:
    insertText "\r"
    
    # Intercept the command 'e' for edit.  Instead of sending it to tex
    # we kill the tex run (closing the pipe) and go directly to the source
    # window for editing the error line:
    if { $prompt eq "? " } {
	if { [string equal -nocase $more "e"] } {
	    # Go to the error line in the appropriate file:
	    goToError 0 ; # 0 for searching backwards for the line number
	    interrupted
	    return
	}
    }
    # We use 'x' to interrupt, regardless of prompt type:
    if { [string equal -nocase $more "x"] } {
	interrupted
	return
    }
    # All other types of input is passed to tex raw:
    puts $TeX::tetexComm::texRun(pipeName) $more
}

proc TeX::tetexComm::interrupted {} {
    variable texConsole
    variable texRun
    insertText -w $texConsole "TeX interrupted.  No pages of output.\rTranscript written on $texRun(jobName).log.\r"
    closeAllPipes
    if { [lcontain [auxFileCopy copyback] "aux"] } {
	insertText -w $texConsole "Previous .aux file preserved.\r"
    }
    setConsoleState TeXC.idle
}


# Search for a TeX line specification (as given in error or warning),
# and open the relevant file at that line.
proc TeX::tetexComm::goToError { {forward 1} } {
    variable texRun
    
    # Find the error's line indication:
    set pat {((l.(\d+)\s)|(lines (\d+)-)|(line (\d+).))[^\r\n]*(\r|\n)}
    if { [catch {search -f $forward -r 1 $pat [getPos] } posPair] } {
	# Problem: we get into this case when the error is:
	# 
	# Runaway argument?
	# {\line (0,1){40} \put (15,23){\makebox (0,0)[b]{\scriptsize $a$}} \put \ETC.
	# ! File ended while scanning use of \put.
	# <inserted text> 
	#                 \par 
	# <*> evidence
	#                    
	# ? 
	# 
	# }
	
	status::msg "No TeX error or warning with line number found."
	return		
    }
    set errorSpec [getText [lindex $posPair 0] [lindex $posPair 1]]
    regexp {(\d+)\s*(.*)(\r|\n)} $errorSpec "" errorLine errorPat
    # Now $errorLine is the line we will open, and errorPat is hopefully
    # the error we will look for on that line... 
#     # Cut down the pattern a bit (the error is only the last token):
#     regexp -- {^.*\s(.*)} $errorPat "" errorPat
    regsub {.*^^} $errorPat "" errorPat
    regsub {.*\.\.\.} $errorPat "" errorPat
    
    # Next, determine the file...
    
    # Take a step backwards in case we are up against a ")":
    set pos [pos::math [lindex $posPair 0] - 1]
    # Search backwards for last unclosed "(" in log file
    # when we find one we'll check that it is really a file name.
    # Currently it is not:
    set file ""
    while { ![file readable $file] } {
	# search back:
	if { [catch { matchIt ")" $pos } opParPos] } {
	    status::msg "Could not properly determine source file.  Opened calling file" 
	    set file $texRun(callingFile)
	    break
	} 
	# Extract the line in which the filename occurs:
	set line [getText [pos::math $opParPos + 1] [pos::lineEnd $opParPos]]
	set file [lindex $line 0]
	# Drop the configuration data from teTeX's pdf*tex runs (Juan's patch):
	regexp {[^\{)]*} $file file
	# Turn the filename into an absolute one:
	set file [file normalize [file join $texRun(pwd) $file]]
	# Take a step backwards because of weird backward search convention:
	set pos [pos::math $opParPos - 1]
	# And search further back:
    }
    
    # If the error is in an aux file, suggest the user to delete it and rerun tex:
    if { [file extension $file] eq ".aux" } {
	# Avoid interference with any cached aux file:
	catch {file delete ${file}.tmp}
	# -t stop|caution|note|plain
	switch -- [alert -t caution -o "Edit aux file" -k "Trash and tex" \
	  "The error is in the aux file \"[file tail $file]\"" \
	  "It is recommended you trash this aux file, and run tex again."] {
	    "Edit aux file" {
		# relax
	    }
	    "Trash and tex" {
		if { [catch {file delete $file}] } {
		    status::msg "Cancelled.  Could not delete \"$file\""
		    return
		}
		# Dirty trick: the caller of this proc will issue an
		# [interrupted] immeditately after the following return.
		# This happens up in the proc [TeX::tetexComm::sendMore].
		# Hence we need to wait for this interruption to take
		# place before we initiate the new tex run:
		after 50 { TeX::tetexComm::typesetCurrent }
		return
	    }
	    "Cancel" {
		return
	    }
	}
    }
    # In the normal case, just go there:
    gotoLineAndSelectPattern $file $errorLine $errorPat
}


# Create a copy of the aux file, copy it back, or delete the copy.
# Applies also to toc files.  Return a list of those extensions the
# operation actually applied to.
proc TeX::tetexComm::auxFileCopy { subCmd } {
    # We assume that we have write access to current directory --- it 
    # doesn't make sense to run tex otherwise.
    variable texRun
    set res [list]
    foreach ext [list aux toc] {
	set auxFileName [file join $texRun(pwd) $texRun(jobName)].$ext
	set auxFileCopyName ${auxFileName}.tmp
	switch -exact -- $subCmd {
	    create {
		if { [file readable $auxFileName] } {
		    file copy -force $auxFileName $auxFileCopyName
		    lappend res $ext
		}
	    }
	    copyback {
		# We should *copy* it back, not move it, because if tex is
		# interrupted once again, we still need the cached copy...
		if { [file readable $auxFileCopyName] } {
		    file copy -force $auxFileCopyName $auxFileName
		    lappend res $ext
		}
	    }
	    delete {
		if { [file writable $auxFileCopyName] } {
		    file delete -force $auxFileCopyName
		    lappend res $ext
		}
	    }
	    default {
		error "Unknown subcommand" 
	    }
	}
    }
    return $res 
}

# Called after the tex run, just to make sure.  Actually this is
# only needed for the two ends of the error pipe --- and the error
# pipe is not currently in use!
proc TeX::tetexComm::closeAllPipes {} {
    variable texRun
    catch { close $texRun(pipeName) }
#     catch { close $texRun(errorIn) }
#     catch { close $texRun(errorPipe) }
}

# Called whenever TeX Console is closed
proc TeX::tetexComm::properClose { name } {
    variable texConsole
    if { [string equal $name $texConsole] } {
	closeAllPipes
	unset -nocomplain texRun
    }
}

proc TeX::tetexComm::interrupt {} {
    variable texConsole
    if { [string equal [win::Current] $texConsole] } {
	closeAllPipes
	auxFileCopy copyback
	insertText -w $texConsole "\r\r - interrupted -\r"
	setConsoleState TeXC.idle
    }
}


# Support for sending arbitrary unix command (using tetex console as shell)
# -------------------------------------------------------------------------
proc TeX::tetexComm::promptForUnixCommand {} {
    closeAllPipes
    whichFileToTypeset
    ensureConsole -clean
    insertPrompt
}

# Regexp pattern for recognising prompt.  
# MUST follow definition in [insertPrompt]
set ::TeX::tetexComm::promptPat {^\[([^\]]+)\]\$\s+(.+)}

# Insert a prompt in the tetex console.  The prompt
# definition used must match the above prompt pattern.
proc TeX::tetexComm::insertPrompt {} {
    ensureConsole
    variable texRun
    append prompt \[ [file tail $texRun(pwd)] \] "\$ "
    set pos [getPos]
    insertText $prompt    
    setConsoleState TeXC.unixprompt
    text::color $pos [getPos] blue
    refresh
    status::msg "Send any unix command"    
}




# Called when the tex run has finished (without having been interrupted)
# What to do depends on how the tex run went, and depends on the setting
# of the variable autoView.  The possible values are
#   0: "no automatisation"
#   1: "auto view when no errors no warnings"
#   2: "auto view when no errors"
#   3: "auto view after tex run"
#   4: "auto next action"
proc TeX::tetexComm::postProc {} {
    variable texRun
    variable texConsole
    
    setConsoleState TeXC.nextaction

    # Since we cannot be sure a TeXC window is frontmost, we have to refer
    # to the TeXCmodeVars manually in this proc: 
    global TeXCmodeVars
    
    # Clean up:
    closeAllPipes
    auxFileCopy delete

    set logfile [file join $texRun(pwd) $texRun(jobName).log]
    if { ![file exists $logfile] } {
	insertText -w $texConsole "\rWarning: no log file found\r"
	return
    }
	
    set nextActionAuthorised 0
    if { [string length $texRun(keystrokes)] } {
	set key [string index $texRun(keystrokes) 0]
	switch -- $key {
	    "v" {
		set texRun(keystrokes) ""
		view 
		return
	    }
	    "w" {
		set texRun(keystrokes) ""
		# Here we have to build the includesList!
		if { [catch { createIncludesList [file join $texRun(pwd) $texRun(jobName).log] }] } {
		    # We don't want an outdated list:
		    unset -nocomplain texRun(includesList)
		}

		displayErrorsAndWarnings 
		return
	    }
	    "t" {
		set texRun(keystrokes) ""
		typesetCurrent 
		return
	    }
	    "b" {
		set texRun(keystrokes) ""
		bibtexCurrent
		return
	    }
	    "m" {
		set texRun(keystrokes) ""
		makeindexCurrent
		return
	    }
	    "l" {
		set texRun(keystrokes) ""
		openLog
		return
	    }		
	    " " {
		set texRun(keystrokes) ""
		set nextActionAuthorised 1
	    }
	}
    }
    
    set obsoleteFiles [checkForObsoleteFiles]
    if { [string length $obsoleteFiles] } {
	insertText -w $texConsole "\rWarning: $obsoleteFiles outdated: older than\
	  [file tail $texRun(callingFile)]\r"
    }

    if { $texRun(nextAction) eq "none" } {
	# This means that we are doing post processing for an unknown
	# custom command.  Look if the log file is newer than texRun(time0).
	# In that case the unknown run was a tex run.
	# However, if there was interaction with tex, then texRun(time0) is
	# unset, but we also think it's a tex run if the log file is less
	# than 5 seconds old.
	if { [info exists texRun(time0)] &&
	  [file mtime $logfile] > $texRun(time0) } {
	    # This is tex.
	    set texRun(nextAction) "view"
	} elseif { [file mtime $logfile] > [expr [clock seconds] - 5] } {
	    # This is tex.
	    # Since there was no texRun(time0) the tex run was
	    # interrupted.  Hence most likely there was an error.
	    set texRun(nextAction) "browse"
	} else {
	    unset -nocomplain texRun(time0)
	    # There is no evidence that the programme was a tex programme,
	    # so perhaps the best is to insert a new prompt:
	    insertPrompt
	    return
	    # (Note that we also come in here in the following case:
	    # the programme is altpdflatex and there was some interaction
	    # during the tex run.  In this case, texRun(time0) is unset,
	    # and because altpdflatex does dvips and ps2pdf after latex
	    # the log file may be older than 5 seconds...)
	}
    }
    
    set txt  "\rType Ctrl-v to view resulting dvi/pdf file.\r"
    append txt "Type Ctrl-e to edit source file.\r"
    append txt "Type Ctrl-l to open log file.\r"
    append txt "Type Ctrl-w for list of warnings and such.\r"
    
    if { $texRun(nextAction) eq "typeset" } {
	# This happens after bibtex and makeindex runs.  In this case there 
	# is no reason to check for tex run errors, so just do
	if { $TeXCmodeVars(autoView) == "4" || $nextActionAuthorised } {
	    # "4" is "auto next action"
	    takeNextAction
	} else {
	    insertText -w $texConsole "$txt\rPress <space> to typeset again.\r"
	}
	return
    }
    if { [info exists texRun(time0)] } {
	# Non-interrupted tex run --- display the elapsed time: 
	insertText -w $texConsole "\rTime elapsed: \
	  [expr [clock seconds] - $texRun(time0)] seconds.\r"
    } else {
	# Probably there were errors.  Hence
	set texRun(nextAction) "browse"
    }
    
    # Prepare the includeslist in the texLog array, so that it is ready for error browsing.
    if { [catch { createIncludesList [file join $texRun(pwd) $texRun(jobName).log] }] } {
	# We don't want an outdated list:
	unset -nocomplain texRun(includesList)
    }
    if { $TeXCmodeVars(autoView) == "3" } {
	# "3" is "auto view after tex run"
	view
	return
    }
    
    
    # There are some things at the end of the console we want to look at.
    set searchStart [pos::math [maxPos -w $texConsole] - 2000]
    # pdftex prints a lot of junk at the end of the tex run, so in this case
    # we need to go further back:
    if { $texRun(pdf) } {
	set searchStart [pos::math $searchStart - 4000]
    }
    
    # First criterion: if TeX returns nonzero exit status, then most likely 
    # what we want to do is to browse the errors.  Suggest this on the screen:
    if { ![catch {search -w $texConsole -f 1 -r 0 \
      "TeX returned non zero exit status" \
      $searchStart}] } {
	set texRun(nextAction) "browse"
	if { $TeXCmodeVars(autoView) == "4" || $nextActionAuthorised } {
	    takeNextAction
	} else {
	    insertText -w $texConsole "$txt\rTHERE WERE ERRORS! Press <space> to browse errors.\r"
	}
	return
    } elseif { $TeXCmodeVars(autoView) == "2" } {
	# "2" is "auto view when no errors"
	view
	return
    }

    # Second criterion: If there was a missing citation, then the most likely 
    # next action is to run bibtex.  Suggest this:
    variable texLog
    if { [regexp -- {Citation `([^']*)'[^\n\r]* undefined} $texLog(logTxt) "" missBib] } {
	# Bib out of synch.  If bibtex is used for this tex job...
	if { [usesBibtex] } {
	    # ... suggest to run bibtex.  But if once the user doesn't pay 
	    # attention, don't insist.  So we check against the previous missing 
	    # bib, and only make noise if there is a new problem which hasn't 
	    # been reported before...
	    if { ![info exists texRun(missingBib)] \
	      || [string compare $missBib $texRun(missingBib)] } {
		set texRun(missingBib) $missBib
		set texRun(nextAction) bibtex
		if { $TeXCmodeVars(autoView) == "4" || $nextActionAuthorised } {
		    takeNextAction
		} else {
		    insertText -w $texConsole "$txt\rBIB OUT OF SYNCH!  Press <space> to run bibtex.\r"
		}
		return
	    } else {
		if { $TeXCmodeVars(autoView) == "4" || $nextActionAuthorised } {
		    # We don't actually propose bibtex in this case.
		    # We don't know yet what the next action will be,
		    # so just continue
		} else {
		    # Otherwise we give a more discrete message:
		    insertText -w $texConsole "${txt}\r(Bib still out of synch.  Type Ctrl-b to run bibtex.)\r"
		    return
		}	
	    }
	}
    }
    
    # Third criterion: if labels have changed, suggest to re-typeset:
    if { ![catch {search -w $texConsole -f 1 -r 0 \
      "Label(s) may have changed. Rerun to get cross-references right." \
      $searchStart}] } {
	set texRun(nextAction) "typeset"
	if { $TeXCmodeVars(autoView) == "4" || $nextActionAuthorised } {
	    takeNextAction
	} else {
	    insertText -w $texConsole "$txt\rLABELS MAY HAVE CHANGED! Press <space> to typeset again.\r"
	}
	return
    } 
    # Fourth criterion: undefined reference.  
    # We might suggest to error browse.
    if { ![catch {search -w $texConsole -f 1 -r 0 \
      "LaTeX Warning: There were undefined references." \
      $searchStart}] } {
	set texRun(nextAction) "browse"
	if { $TeXCmodeVars(autoView) == "4" || $nextActionAuthorised } {
	    takeNextAction
	} elseif { $TeXCmodeVars(autoView) == "2" } {
	    # "2" is "auto view when no errors"
	    view
	} else {
	    insertText -w $texConsole \
	      "$txt\rThere were undefined references.  Press <space> to browse errors.\r"
	}
	return
    } 

    # Fourth criterion: somebody already suggested that we browse:
    if { $texRun(nextAction) eq "browse" } {
	if { $TeXCmodeVars(autoView) == "4" || $nextActionAuthorised } {
	    takeNextAction
	} else {
	    insertText -w $texConsole "$txt\rPress <space> to browse errors.\r"
	}
	return
    }
    
    if { $TeXCmodeVars(autoView) && $texRun(nextAction) eq "view" } {
	# This means autoView is 1, 2, 3,  or 4, which is
	# autoViewWhenNoErrorsNoWarning,
	# autoViewWhenNoErrors,
	# autoViewAfterTexRun and autoNextAction...
	view
	return
    }
#     if { $TeXCmodeVars(autoViewWhenNoErrors) } {
# 	view
# 	return
#     }
    
    # In other cases, the best suggestion is to view
    set texRun(nextAction) "view"
    insertText -w $texConsole "$txt\rPress <space> to view.\r"
    if { $TeXCmodeVars(autoView) == "4" || $nextActionAuthorised } {
	takeNextAction
    }
    return
    
}


# Returns a list of obsolete dvi or ps files.
# Such a file is considered obsolete if a newer tex file exists, and also a
# newer pdf file exists.  This means that it is an old dvi or ps file left
# from a previous tex run.  Of course, this will never happen in normal
# usage, only if sometimes the source file is compiled with standard latex
# producing dvi (and perhaps ps) and later the same file is compiled with
# pdflatex (or altpdflatex).
proc TeX::tetexComm::checkForObsoleteFiles {} {
    variable texRun
    set baseName [file normalize [file join $texRun(pwd) $texRun(jobName)]]
    if { [newestOutput $baseName] eq "pdf" } {
	set texName $texRun(callingFile)
	set obsoletes ""
	append dviName $baseName .dvi
	if { [file exists $dviName] } {
	    if { [file mtime $dviName] < [file mtime $texName] } {
		lappend obsoletes [file tail $dviName]
	    }
	} 
	append psName $baseName .ps
	if { [file exists $psName] } {
	    if { [file mtime $psName] < [file mtime $texName] } {
		lappend obsoletes [file tail $psName]
	    }
	}	
	return $obsoletes
    }
}




# Guess whether this tex job uses bibtex.  It is faster to check whether
# there is a .bbl file, but it is more exact to check whether a bibdata
# entry has been written to the .aux file...
proc TeX::tetexComm::usesBibtex {} {
    variable texRun
    if { [file exists [file join $texRun(pwd) $texRun(jobName).bbl]] } {
	return 1
    }
    set aux [file::readAll [file join $texRun(pwd) $texRun(jobName).aux]]
    if { [regexp {\\bibdata} $aux] } {
	return 1
    }
    return 0
}


######################################################################
# SECTION 4: POST-RUN UTILITIES
######################################################################



proc TeX::tetexComm::takeNextAction {} {
    variable texRun
    switch -exact -- $texRun(nextAction) {
	bibtex {
	    bibtexCurrent
	}
	makeindex {
	    makeindexCurrent
	}
	browse {
	    displayErrorsAndWarnings
	}
	typeset {
	    typesetCurrent
	}
	none {
	    status::msg "No prescribed next action"
	}
	default {
	    $texRun(nextAction)
	}
    }
}

# Utilities related to error-browsing are in Part 5.

proc TeX::tetexComm::editSource { } {
    variable texRun
    if { [catch { edit -c $texRun(callingFile) }] } {
	set fileName [file join $texRun(pwd) $texRun(jobName)]
	append fileName $texRun(ext)
	edit -c $fileName
	# We should not use TeX Console's fontSize here, 
	# but rather the global fontSize
	setFontsTabs -fontsize $::fontSize
    }
}

proc TeX::tetexComm::openLog { } {
    variable texRun
    set fileName [file join $texRun(pwd) $texRun(jobName)]
    append fileName ".log"
    if { [file readable $fileName] } {
	edit -c $fileName
	# We should not use TeX Console's fontSize here, 
	# but rather the global fontSize
	setFontsTabs -fontsize $::fontSize
    } else {
	status::msg "Log file not found"
    }    
}

# This proc is independent of $texRun and can be used also
# outside tetexComm.  Requires complete path as argument.
# If the tex file is the newest then we return that one!
proc TeX::tetexComm::newestOutput { baseFile } {
#     set baseFile [file rootname $baseFile]
    set t 0
    foreach ext [list dvi ps pdf html tex] {
	if { [file readable $baseFile.$ext] } {
	    if { [file mtime $baseFile.$ext] > $t } {
		set t [file mtime $baseFile.$ext]
		set format $ext
	    }
	}
    }
    if { [info exists format] } {
	return $format
    }
}



# VIEWING -------------------------------------------


set TeX::tetexComm::availableViewers(DVI) \
  [lsort -dictionary [::xserv::getImplementationsOf viewDVI]]
set TeX::tetexComm::availableViewers(PDF) \
  [lsort -dictionary [::xserv::getImplementationsOf viewPDF]]

# The next two prefs are just links to xserv settings, via a two-way trace:
newPref var DVIViewer "xdvi" TeXC  "" \
  $::TeX::tetexComm::availableViewers(DVI)
newPref var PDFViewer "TeXShop" TeXC  "" \
  $::TeX::tetexComm::availableViewers(PDF)

# Here is the proc called whenever there is a change to one of the variables
#   xserv::currentImplementations(viewDVI)
#   xserv::currentImplementations(viewPDF)
#   TeXCmodeVars(DVIViewer)
#   TeXCmodeVars(PDFViewer)
# 
proc TeX::tetexComm::viewerVarLink { arr key op } {
    global ::xserv::currentImplementations
    global ::TeXCmodeVars
    switch -glob -- $arr {
	"*xserv::currentImplementations" {
	    upvar 1 $arr A 
	    set viewer [dict get $A($key) "" -name]
# 	    alertnote "viewer according to xserv: $viewer"
	    switch -exact -- $key {
		"viewPDF" {
		    if { $viewer != $::TeXCmodeVars(PDFViewer) } { 
			set ::TeXCmodeVars(PDFViewer) $viewer
		    }   
		}
		"viewDVI" {
		    if { $viewer != $::TeXCmodeVars(DVIViewer) } {
			set ::TeXCmodeVars(DVIViewer) $viewer
		    }
		}
	    }
	}
	"*TeXCmodeVars" {
	    set viewer $::TeXCmodeVars($key) 
# 	    alertnote "viewer according to tetexComm: $viewer"
	    switch -exact -- $key { 
		"PDFViewer" {
		    if { $viewer != [::xserv::getCurrentImplementationNameFor viewPDF ""] } {
			::xserv::chooseImplementationFor viewPDF [list -name $viewer]
		    }   
		}
		"DVIViewer" {
		    if { $viewer != [::xserv::getCurrentImplementationNameFor viewDVI ""] } {
			::xserv::chooseImplementationFor viewDVI [list -name $viewer]
		    }
		}
	    }
	}
    }
}


trace add variable ::xserv::currentImplementations(viewPDF) write TeX::tetexComm::viewerVarLink
trace add variable ::xserv::currentImplementations(viewDVI) write TeX::tetexComm::viewerVarLink
trace add variable ::TeXCmodeVars(DVIViewer) write TeX::tetexComm::viewerVarLink
trace add variable ::TeXCmodeVars(PDFViewer) write TeX::tetexComm::viewerVarLink

# AND HERE COMES THE MANUAL QUICK CHANGE PROC
proc TeX::tetexComm::changeAndView { {ext ""} } {
    variable texRun
    set fileName [file join $texRun(pwd) $texRun(jobName)]
    if { ![string length $ext] } {
	set ext [newestOutput $fileName]
    }
    set TYPE [string toupper $ext]
    
    set current [::xserv::getCurrentImplementationNameFor view$TYPE ""]
    variable availableViewers
    # The user picks a new viewer:
    if { [catch {listpick -p "Pick $ext viewer" \
      -L [list $current] $availableViewers($TYPE)} newViewer] } {
	status::msg "Cancelled"
	return
    }
    set ::TeXCmodeVars(${TYPE}Viewer) $newViewer
    # And now view
    view $ext
}

Bind 'v' <z> {TeX::tetexComm::view} TeX
Bind 'v' <sz> TeX::tetexComm::changeAndView TeX
Bind 'v' <sz> TeX::tetexComm::changeAndView TeXC

Bind 'd' <z> {TeX::tetexComm::view dvi} TeXC
Bind 'p' <z> {TeX::tetexComm::view pdf} TeXC
Bind 'd' <sz> {TeX::tetexComm::changeAndView dvi} TeXC
Bind 'p' <sz> {TeX::tetexComm::changeAndView pdf} TeXC



# Main view proc, with special support for xdvi.
proc TeX::tetexComm::view { {ext ""} } {
    global TeXCmodeVars
    variable texRun
    set fileName [file join $texRun(pwd) $texRun(jobName)]
    if { ![string length $ext] } {
	set ext [newestOutput $fileName]
    }
    append fileName .$ext
    switch -exact -- $ext {
	tex {
	    catch { edit -c $fileName }
	}
	pdf {
	    viewPDFFile $fileName
	} 
	dvi {
	    # One special case:
	    if { $::tcl_platform(platform) eq "unix" } {
		set DVIViewer [::xserv::getCurrentImplementationNameFor viewDVI ""]
		if { [string match -nocase "xdvi" $DVIViewer] } {
		    TeX::viewWithXdvi $fileName
		    
		    # Usual [sendConsoleToBackWhileViewing] (at the end of 
		    # this proc) doesn't behave well with xdvi: the effect 
		    # is that the Alpha editing window is put on top of the xdvi 
		    # viewing window...  So we'll put the tex file window
		    # frontmost *before* switching to xdvi (even though
		    # this may appear a little bit flashy...)
		    if { $TeXCmodeVars(sendConsoleToBackWhileViewing) } {
			catch {bringToFront [lindex [file::hasOpenWindows $texRun(callingFile)] 0]}
		    }
		    catch { switchTo X11 }
		    return
		}
	    }
	    # The general case:
	    viewDVIFile $fileName
	}
	html {
	    html::SendWindow $fileName
	}
	ps {
	    viewPSFile $fileName
	}
	default {
	    # Don't know what happened... 
	    # 
	    # Solution 1: open the log file to see if there is any
	    # clue to get there:
	    # openLog
	    # 
	    # Solution 2: Try to let the system open the file
	    # exec open $fileName
	    # 
	    # Solution 3:
	    status::msg "Nothing to view for \"$fileName\""
	}
    }
    
    if { $TeXCmodeVars(sendConsoleToBackWhileViewing) &&
      (($ext ne "dvi") || ($::TeXCmodeVars(DVIViewer) ne "usingPDFViewer")) } {
	# While the viewer is in the front, let us secretly make 
	# the source file the frontmost Alpha window, so that we 
	# are ready to edit it when we later return to Alpha:
	after 1500  {catch {bringToFront [lindex [file::hasOpenWindows $::TeX::tetexComm::texRun(callingFile)] 0]}}
	# (We don't do this if the DVIViewer is really usingPDFViewer,
	# because then there is a delay for runnging dvips and ghostscript,
	# and we only want to bring the source window to front after that.)
    }
}

# Produce a pdf file from a dvi file, 
# and open it in the chosen pdf viewer.
proc TeX::tetexComm::distillPDF { {filename ""} } {
    if { [string length $filename] } {
	set pwd [file dirname $filename]
	set jobName [file root [file tail $filename]]
    } else {
	variable texRun
	set pwd $texRun(pwd) 
	set jobName $texRun(jobName)
    }
    global TeXCmodeVars

    # Reset:
    closeAllPipes
    # Preserve pwd:
    set oldPwd [pwd]
    cd $pwd

    if { $TeXCmodeVars(usedvipdfm) } {
	lappend cmd echo && dvipdfm '$jobName' 2>&1
    } else {
	lappend cmd echo && \
	  dvips -R -Poutline \
	  -o '$jobName.ps' '$jobName' 2>&1  && echo && \
	  gs -dCompatibilityLevel=1.3 -dNOPAUSE -dBATCH -sDEVICE=pdfwrite \
	  '-sOutputFile=$jobName.pdf' -dCompatibilityLevel=1.3 \
	  -c .setpdfwrite -f '$jobName.ps' 2>&1 && \
	  /bin/rm -f '$jobName.ps'
    }

    #Set up the main pipe:
    set texRun(pipeName) [app::setupLineBasedInteraction -read read \
      -callback ::TeX::tetexComm::receiveAndDisplay -closeproc \
      ::TeX::tetexComm::viewPDF -usebinsh $cmd]
    
    ensureConsole
    setConsoleState TeXC.texinteraction
   
    # Restore previous pwd:
    cd $oldPwd    
}


# This proc is ONLY to serve as postproc for TeX::tetexComm::distillPDF:
proc TeX::tetexComm::viewPDF {} {
    setConsoleState TeXC.idle
    view pdf
}

# ------------------------
# Special support for xdvi
# ------------------------
# This will eventually be a xserv driver.

# This proc might eventually be moved to the app:: namespace...
proc TeX::tetexComm::isAlive { pid } {
    set L [split [exec ps -c -p $pid] \n]
    # This list looks like:
    #      PID  TT  STAT      TIME COMMAND
    #     5247  ??  S      5:22.12 AlphaX
    # There is always a header line, and either 0 or 1 result line.  Hence:
    return [expr [llength $L] - 1]
}


# =================================================
# Support for xdvi version < 22.77:  the tricky part is to avoid spawning 
# a new window for a dvi file that is already displayed.  This is achieved
# with the -sourceposition trick.


# General xdvi command --- tell it that the editor is Alpha
set TeX::xdviCommand [list xdvi \
  -editor "[file norm [file join $::HOME Tools alphac]] +%l %f"]
# Remark: in previous AlphaTcl it was necessary to include a -display :0.0
# flag, but now this is set in alphaDefinitions.tcl, and the user might
# have another setting, so it is better not to include it hard coded at
# this point.

# Use this extra xdvi flag if your xdvi is at least version 22.77:
lappend TeX::xdviCommand -unique
# 
#     or
# 
# Use this extra xdvi flag if your xdvi is version < 22.77:
# lappend TeX::xdviCommand -sourceposition 0none
# Unfortunately the common version 22.40 does not understand the -unique
# flag to prevent creating a new preview window for each call.  But we can
# fool xdvi to enter client mode by sending a dummy -sourceposition flag.
# See the xdvi man page for more info.

# The power user may want to give more options here, but note that the
# correct place to give such permanent options is in the xdvi.cfg file
# cf. the xdvi man page.  But here is an example:
# lappend TeX::xdviCommand -geometry 1028x768 \
#   -s 5 -expert +statusline -hushstdout
# 
# -geometry 1028x768 is a full screen of some portable computers, 
# -s 5 is shrink factor 5, which corresponds to filling that full screen,
# -expert means no buttons (to maximise viewing area), 
# +statusline -hushstdout means no statusline and no messages...

# Currently this proc is only called from tetexComm, but in fact it is
# completely general.
proc TeX::viewWithXdvi { fileName } {
    # Make sure X11 is running:
    if { ![::app::isRunning X11] } {
	if { [catch { exec open -a X11 }] } {
	    alertnote "Couldn't launch X11"
	    return
	}
	# Just to give X11 half a second to launch:
	after 500
    }
    
    # Now adjust the DISPLAY variable:
    set currentDisplay [determineX11Display]
    if { [string length $currentDisplay] } {
	set ::env(DISPLAY) $currentDisplay
    }

    # A better method would be perhaps to use the users DISPLAY setting
    # and only if it fails try to figure out what he meant.  That is,
    # catch the exec xdvi and if it is "Can't open display :0.0" then
    # try to figure out what it should have been.  Two advantages:
    # 1) we don't reset the variable at every view operation, 2) we
    # do try to respect the user's setting before thinking that we can do
    # better.
    
    variable xdviCommand
    catch { eval exec $xdviCommand \"$fileName\" & } err
    # The following is a dirty hack to find the pid of xdvi.
    # (The number returned by the previous command is the pid of
    # some sh which runs xdvi.bin.  Killing sh doesn't kill xdvi.bin.)
    # We also need this number if we want to send a SIGUSR1 signal to
    # xdvi...
    after 1000 {
	catch {
	    set L [split [exec ps -x -c -o pid,command | grep xdvi] \n]
	    set ::TeX::tetexComm::texRun(xdviPid) [lindex $L end 0]
	    unset L
	}
    }
    return
}

proc determineX11Display {} {
    # The open displays are sockets listed in /tmp/.X11-unix/
    # of names Xn for some nonegative integer n.  Pick the
    # first one owned by the current user.
    foreach socket [glob -nocomplain /tmp/.X11-unix/X*] {
	if { [file owned $socket] &&
	   [regsub {/tmp/\.X11-unix/X} $socket ":" display] } {
	    return $display
	}
    }
}

if { 0 } {
    ::xserv::register viewDVI xdvi -driver {
	::TeX::viewWithXdvi $params(file)
	if { $params(xservInteraction) } {
	    switchTo X11
	}
    } -mode Alpha
}




######################################################################
# SECTION 5: ERROR BROWSING
######################################################################

#### Here comes the first stab at intelligent log file handling ####

# Create a list whose entries (one for each included file) are triples:
# index 0: position in .log file of include statement
# index 1: corresponding closing parenthesis
# index 2: name of included file (possibly just a relative file name)
# 
# This new version (April 2004) tries to be very serious about handling log
# files with unbalanced parens.  Since such unbalanced log files are quite
# rare, and since the new technique takes more time, we only use it when
# the old plain method fails, even if this means trying twice in this case.

# As of July 2005, this mechanism has been completely decoupled from the
# tex run and the TeX Console.  it now operates relative to any specified
# log file (so the TeX Console has to specify the log file).  There are
# basically just two public methods: [createIncludesList], which scans the
# log file and puts the information in an array, and
# [displayErrorsAndWarnings], which displays the result.  (Eventually this
# proc will return data instead of displaying it, in order really to make
# it independent of the TeX Console.  (One particular benefit of this 
# decoupling is that it makes it a lot easier to debug and test 
# user-contributed log files!)

proc TeX::tetexComm::createIncludesList { logfile } {
    # Since the specified log file might be completely unrelated to the
    # last tex run (e.g. a user-contributed log file), we should no longer
    # refer to $texRun at all.  Instead we use an array $texLog.
    
    variable texLog
    set texLog(pwd) [file dir $logfile]
    variable _parens
    variable _logTxt
    
    set f [open $logfile r]
    set texLog(logTxt) [read $f]
    close $f
    # For the sake of parsing parens, we'll need to modify the logTxt,
    # so we make a copy for this purpose:
    set _logTxt $texLog(logTxt)
    
    # Create the parens array.  This is actually done by _findMatchingClose
    array unset _parens
    set index 0
    set unbalanced 0
    while { [regexp -indices -start $index -- {\(} $_logTxt pair] } {
	# The balancing is really done by _findMatchingClose in the next line.
	if { [catch { set index [_findMatchingClose [lindex $pair 0]] }] } {
	    # There are unbalanced parens.  Just break and then fire up the 
	    # fancy machine...
	    set unbalanced 1
	    break
	    # In previous versions of this proc we would just look for the
	    # next parenthesis, but if there is a mismatch it is better to
	    # try to resolve it properly first, before going on to
	    # guesswork...
	}
	incr index
    }
#     alertnote $unbalanced
    if { $unbalanced } {
	# There were unbalanced parens in the log file --- too bad.  
	# Let us try to eliminate them.  
	set logLength [string length $_logTxt]
	set patList [list ]
	# Most unbalanced parens are caused by overfull and underfull
	# boxes, since these warnings include a small excerpt from the
	# source file, and that may contain parens.  We simply substitute
	# all these chunks by whitespace of the same length before matching
	# the parens.
	lappend patList {(?:Overfull|Underfull).+?\s\[\](?:\r|\n)}
	# Another common source of unbalanced parens are font warnings
	# about no ( in font foo.  We eliminate those in the same way:
	lappend patList {Missing character: There is no \( in font}
	# And of course, any error message might include a paren:
	lappend patList {! Undefined control sequence.(?:\r|\n)(?:.*?(?:\r|\n)){0,3}\?}
	
	foreach pat $patList {
	    set start 0
	    while { [regexp -start $start -indices -- $pat $_logTxt ind] } {
		set i0 [lindex $ind 0]
		set i1 [lindex $ind 1]
		set dummystring [string repeat " " [expr $i1 - $i0 + 1]]
		set _logTxt [string replace $_logTxt $i0 $i1 $dummystring]
		set start $i1
	    }
	}
	if { [string length $_logTxt] != $logLength } {
	    # This should never happen
	    alertnote "Error in log file parsing..."
	}
	# Now we've got a version of the log file with hopefully fewer
	# spurious parens.  Create the parens array once again and see if
	# it works better now:
	array unset _parens
	set index 0
	set unbalanced 0
	while { [regexp -indices -start $index -- {\(} $_logTxt pair] } {
	    # The balancing is really done by _findMatchingClose in the next line.
	    # If it still fails, we just look forward for the next parenthesis...
	    if { [catch { set index [_findMatchingClose [lindex $pair 0]] }] } {
# 		alertnote [lindex $pair 0]
# 		global eee
# 		set eee [lindex $pair 0]
		set unbalanced 1
		set index [lindex $pair 1]
	    }
	    incr index
	}
	if { $unbalanced } {
	    alertnote "Unbalanced parentheses in the log file could not be resolved. \
	    Please report this, annexing the log file to the report."
	}
    }
    
#         alertnote $unbalanced

    # Now we have finished with the parens parsing, and we can discard the
    # temporary version of logTxt:
    unset _logTxt
    # From now on we use the original version of logTxt
    
    set texLog(includesList) ""
    set index 0
    
    # This depends on the machin, not on the provded log file!  
    # Careful when testing foreign log files!:
    if { $::tcl_platform(platform) eq "unix" } {
	# The path may contain spaces, but not linebreaks:
	set filePat {\(\.{0,2}/[^\r\n\)\{]+}
    } else {
	# Windows tex doesn't use ./ and ../ for relative paths...
	set filePat {\([^\r\n\)\{]+}
    }
    while { [regexp -indices -start $index -- $filePat $texLog(logTxt) pair] } {
# 	alertnote $index
	set i0 [lindex $pair 0]
	set i1 [lindex $pair 1]
	set fileName [string range $texLog(logTxt) [expr $i0 + 1] $i1]
# 		puts $fileName
	if { [file readable [file normalize [file join $texLog(pwd) $fileName]]] } {
	    if {[info exists _parens($i0)]} {
		lappend texLog(includesList) [list $i0 $_parens($i0) $fileName]
	    } else {
		# Vince sees this problem from time to time.
# 		puts "Rejected position $i0"
	    }
	}
	set index $i1
	incr index
    }
    unset _parens
}


# Helper proc for createIncludesList
proc TeX::tetexComm::_findMatchingClose { index } {
    # Use the temporary parens-corrected version of the logTxt:
    variable _logTxt
    if { ![string equal [string index $_logTxt $index] {(}] } {
	error "The ${index}th char is not a ("
    }
    # Use a 'remember' table:
    variable _parens
    set i0 $index
    if { [lsearch -exact [array names _parens] $i0] != -1 } {
	return $_parens($i0)
    }
    
    incr index
    
    while { [regexp -indices -start $index -- {(?:(\()|(\)))} \
      $_logTxt "" nextOpen nextClose] } {
	# We found a closing parenthesis:
	if { [lindex $nextClose 0] != -1 } {
	    set _parens($i0) [lindex $nextClose 0]
	    return [lindex $nextClose 0]
	}
	# We found an opening parenthesis:
	if { [lindex $nextOpen 0] != -1 } {
	    set index [_findMatchingClose [lindex $nextOpen 0]]
	}
	incr index
    }
    error "Can't match parens"
}


# Given a position in the log file, find the source file being read here.
# This requires that the includesList has been built.  The log file does
# not have to be open.  May return errors, if no source file can be 
# determined. 
proc TeX::tetexComm::_currentSourceFile { pos } {
    variable texLog
    if { $pos > [string length $texLog(logTxt)] } {
	error "invalid position"
    }
#     if { ![info exists texLog(includesList)] } {
# 	status::msg "Could not properly determine source file.  Opened calling file" 
# 	return $texRun(callingFile)
#     }
    
    # Run through the includesList and find last embracing parens pair:
    set i 1
    while { $i <= [llength $texLog(includesList)] } {
	set triple [lindex $texLog(includesList) end-$i]
	if { [lindex $triple 0] < $pos && [lindex $triple 1] > $pos } {
	    # This is latest embracing include file parenthesis.
	    # Just return the name of this file:
	    return [lindex $triple 2]
	}
	incr i
    }
    # We did not find anything... 
    error "Could not properly determine source file" 
}




# Patterns with line numbers.  Each pattern must be a complete-lines 
# pattern, so it must begin and end with \n .  These two chars are 
# stripped from the matches.  Each pattern must contain exactly one 
# subpattern which will match the line number.  (Other subexpressions
# must be non-capturing (?:<expr>).)
# 
# The subexpression is the line number.  
array set TeX::tetexComm::patternsWithLineNumbers {
    warnings  {\nLaTeX(?:[^\r\n]*)Warning: (?:[^\n]|[\n][^\n])*?input\s+line\s+((?:\d\n?)+)\.\n}
    errors    {\n! (?:[^\n]|[\n][^\n])*?\nl\.(\d+)\s.*?\n}
    wrongEnd    {\n! LaTeX Error: \\begin.*?ended by (?:.*?\n){4} \.\.\.\s+?l\.(\d+)\s.*?\n}
    grExtErrors    {\n! LaTeX Error: Unknown graphics extension:(?:.*?\n){4} \.\.\.\s+?l\.(\d+)\s.*?\n}
    envErrors {\n! LaTeX Error: Environment.*?undefined\.\n.*?\.(\d+)\s.*?\n}
    overfulls    {\nOverfull \\hbox (?:[^\n]|[\n][^\n])*? at lines?? (\d+?)(?:-|\s)(?:.*?\n){1,4}\s\[\].*?\n}
    underfulls  {\nUnderfull \\hbox (?:[^\n]|[\n][^\n])*? at lines?? (\d+?)(?:-|\s)(?:.*?\n){1,4}\s\[\].*?\n}
}
# Remark: the expression  (?:[^\n]|[\n][^\n])*?  means 'anything but a blank line'.
# This is needed in order not to pick up e.g. missing-file errors (which have no
# line numbers).
# 
# Warnings: note that the line number may be broken across a line, 
# so it contains \n between the digits.  Hence the regexp is ((?:\d\n?)+)
# The pattern for warnings also picks up LaTeX Font Warnings.

# The oneline expressions pick up overfulls like this:
# Here's an example of the error message in context:
# 
# [87 <./geometry-1.pdf> <./geometry-1a.pdf>] <xymatrix 5x2 318>
# Overfull \hbox (34.93367pt too wide) detected at line 204
# []
# [88] [89] [90]) [91] (./gnihparg.tex

#     onelineOverfulls   {\nOverfull \\hbox (?:[^\n]|[\n][^\n])*? at lines? (\d+?)(?:-|\s).*?\n}
#     onelineUnderfulls {\nUnderfull \\hbox (?:[^\n]|[\n][^\n])*? at lines? (\d+?)(?:-|\s).*?\n}







# # The following regexp is quite accurate, but it is handled more generally
# # by the missing-file regexp (even though that one doesn't have line numbers
# # in general...)
# # =====================================
# set TeX::tetexComm::patternsWithLineNumbers(missingGraphics) \
#   {\n! LaTeX Error: File `[^\n]*?' not found\.\n\nSee the LaTeX manual(?:[^\n]*?\n){4}l\.(\d+) \\includegraphics[^\n]*?\n}
# # This regexp matches things like this:
# # =====================================
# # ! LaTeX Error: File `sdf' not found.
# # 
# # See the LaTeX manual or LaTeX Companion for explanation.
# # Type  H <return>  for immediate help.
# #  ...                                              
# #                                                   
# # l.216 \includegraphics{sdf}
# # =====================================


# NEED TO BUILD A SPECIAL REGEXP FOR THESE ONES --- it now exists, called 
# wrongEnd
# 
# ! LaTeX Error: \begin{taller} on input line 217 ended by \end{blanxko}.
# 
# See the LaTeX manual or LaTeX Companion for explanation.
# Type  H <return>  for immediate help.
#  ...                                              
# 						  
# l.227 \end{blanxko}
		   


# Note that 'missing file' errors do not have line numbers.  They are
# handled separately in the proc buildListOfMissingFiles below.


proc TeX::tetexComm::buildListOf { type } {
    if { $type eq "missingFiles" } {
	return [buildListOfMissingFiles]
    }
    if { $type eq "multiplyDefinedLabels" } {
	return [buildListOfMultiplyDefinedLabels]
    }
    
    # We are a little inconsistent here: we ought to answer solely on the 
    # basis of the information in the log file (cf. obtained in 
    # [createIncludesList]).  But here we use $texRun information as help:
    # if for some reason an included file can not be determined we use the
    # calling file.
    variable texRun
    variable texLog
    variable patternsWithLineNumbers
    
    set L [regexp -all -indices -inline \
      -- $patternsWithLineNumbers($type) $texLog(logTxt)]
    # L is now a list whose even entries are pairs of positions of the whole
    # pattern, and whose odd entries are pairs of positions of the subpattern
    # (which in most cases will be the line number).
    set res ""
    foreach {warningPos linePos} $L {
	set wPos0 [expr {[lindex $warningPos 0] + 1}]
	set wPos1 [expr {[lindex $warningPos 1] - 1}]
	set warning [string range $texLog(logTxt) $wPos0 $wPos1]
	set lPos0 [lindex $linePos 0]
	set lPos1 [lindex $linePos 1]
	if { [catch {_currentSourceFile $lPos0} file] } {
	    set file $texRun(callingFile)
	}
	# Turn the filename into an absolute one:
	set file [file normalize [file join $texLog(pwd) $file]]
	set line [string range $texLog(logTxt) $lPos0 $lPos1]
	# Remove linebreaks inside the line numnber:
	regsub -all {\n} $line "" line
	
	append res [browse::Format $file $warning $line 1 "---- ¥ "]\n
    }
    return $res
}
    
    
#Special treatment of 'missing files' errors
proc TeX::tetexComm::buildListOfMissingFiles {} {
    # We are a little inconsistent here: we ought to answer solely on the 
    # basis of the information in the log file (cf. obtained in 
    # [createIncludesList]).  But here we use $texRun information as help:
    # if for some reason an included file can not be determined we use the
    # calling file.
    variable texRun
    variable texLog
    set pat {\n! LaTeX Error: File `(.*?)' not found\.\n}
    set L [regexp -all -indices -inline -- $pat $texLog(logTxt)]
    # L is now a list whose even entries are pairs of positions of the whole
    # pattern, and whose odd entries are pairs of positions of the subpattern.
    set res ""
    foreach {warningPos subPatPos} $L {
	set wPos0 [expr [lindex $warningPos 0] + 1]
	set wPos1 [expr [lindex $warningPos 1] - 1]
	set warning [string range $texLog(logTxt) $wPos0 $wPos1]
	set spPos0 [lindex $subPatPos 0]
	set spPos1 [lindex $subPatPos 1]
	if { [catch {_currentSourceFile $spPos0} file] } {
	    set file $texRun(callingFile)
	}
	# Turn the filename into an absolute one:
	set file [file normalize [file join $texLog(pwd) $file]]
	
	set filePat [string range $texLog(logTxt) $spPos0 $spPos1]
	# the pattern $filePat is a missing file, so the
	# extension might not be in present
	regsub {\.(tex|sty|cls)} $filePat {(&)?} filePat
	
	append fullFilePat {\\(input|include|usepackage|includegraphics)\{} $filePat {\}}
	# Find $filePat in $file.  If not found, use line 1:
	set line 1
	set f [open $file]
	while { [gets $f txt] != -1 } {
	    if { [regexp -- $fullFilePat $txt] } {
		break
	    }
	    incr line
	}
	close $f
	append res [browse::Format $file $warning $line 1 "---- ¥ "]\n
    }
    return $res
}


# Special treatment of 'multiply defined labels'.  These warnings do not
# have line numbers so we need to find them manually.  This is very cumbersome
# because we don't know a priori in which file the problem lies (the warning
# itself is issued from jobname.aux, which is not the file we want to open...)
proc TeX::tetexComm::buildListOfMultiplyDefinedLabels {} {
    variable texLog
    set pat {\nLaTeX Warning: Label `(.*?)' multiply defined\.\n}
    set L [regexp -all -indices -inline -- $pat $texLog(logTxt)]
    # L is now a list whose even entries are pairs of positions of the whole
    # pattern, and whose odd entries are pairs of positions of the subpattern.
    set res ""
    foreach {warningPos subPatPos} $L {
	set wPos0 [expr [lindex $warningPos 0] + 1]
	set wPos1 [expr [lindex $warningPos 1] - 1]
	set warning [string range $texLog(logTxt) $wPos0 $wPos1]
	set spPos0 [lindex $subPatPos 0]
	set spPos1 [lindex $subPatPos 1]
	set labelPat [string range $texLog(logTxt) $spPos0 $spPos1]	
	append fullLabelPat {\\label\{} $labelPat {\}}
	
	# The warning 'multiply defined label' is issued from jobname.aux.
	# This is not the file we want to open.  Instead let us look at
	# all sourced files with a relative name:
	if { [info exists texLog(includesList)] } {
	    foreach f $texLog(includesList) {
		set f [lindex $f 2]
		if { [file pathtype $f] eq "relative" } {
		    lappend fileList $f
		}
	    }
	} else {
	    # We are in the very unfortunate situation that the includesList
	    # does not exist (due to unbalanced parens in the log file).
	    # We just look in the root file, and possibly in the fileset 
	    # it is in:
	    set rootfile [file normalize [file root $texLog(logfile).tex]]
	    set fset [isWindowInFileset $rootfile "tex"]
	    if { [string length $fset] } {
		set fileList [getFilesInSet $fset]
	    } else {
		set fileList [list $rootfile]
	    }
	}
	
	# Find $fullLabelPat in our list of files.  In fact there should be 
	# at least two occurrences, so why don't we list them all?
	foreach file $fileList {
	    # Turn the filename into an absolute one:
	    set file [file normalize [file join $texLog(pwd) $file]]

	    set f [open $file]
	    set line 1
	    while { [gets $f txt] != -1 } {
		if { [regexp -- $fullLabelPat $txt] } {
		    append res [browse::Format $file $warning $line 1 "---- ¥ "]\n
		}
		incr line
	    }
	    close $f
	    # If not found, use line 1:
	    if { ![string length $res] } {
		append res [browse::Format $file $warning 1 1 "---- ¥ "]\n
	    }
	}
    }
    return $res
}

proc TeX::tetexComm::displayErrorsAndWarnings {} {
    append txt [buildListOf missingFiles]
#     append txt [buildListOf missingGraphics]
    append txt [buildListOf errors]
    append txt [buildListOf wrongEnd]
    append txt [buildListOf grExtErrors]
    append txt [buildListOf envErrors]
    append txt [buildListOf warnings]
    append txt [buildListOf multiplyDefinedLabels]
    append txt [buildListOf overfulls]
#     append txt [buildListOf onelineOverfulls]
    append txt [buildListOf underfulls]
#     append txt [buildListOf onelineUnderfulls]
    
    if { [string length $txt] } {
	variable texConsole
	bringToFront $texConsole
	deleteText [minPos] [maxPos]
	win::setInfo $texConsole overrideGeometry 1
	setConsoleState "Brws"

	insertText "<cr> to go to match\n"
	insertText "${::browse::separator}\n"
	
	set pos [getPos]
	insertText "$txt"
	browse::Select $pos
    } else {
	status::msg "No errors, warnings, or overfull boxes"
    }
}


proc TeX::tetexComm::gotoLineAndSelectPattern { fname line {str ""} } {
    file::gotoLine $fname $line
    if { [string length $str] } {
	set str [quote::Regfind $str]
	set txt [getSelect]
	if { [regexp -indices -- $str $txt relPosPair] } {
# 	    set p0 [pos::math [getPos] + [lindex $relPosPair 0]]
	    variable _p1 [pos::math [getPos] + [lindex $relPosPair 1] + 1]
# 	    selectText $p0 $p1
# 	    goto $p1
	    after 500 { 
		selectText [pos::math $::TeX::tetexComm::_p1 - 1] $::TeX::tetexComm::_p1
		refresh
		unset ::TeX::tetexComm::_p1 
	    }
# 	    backwardWordSelect 
	}
    }
}

