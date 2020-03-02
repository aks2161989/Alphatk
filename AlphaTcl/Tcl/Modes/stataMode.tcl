## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # Statistical Modes - an extension package for Alpha
 #
 # FILE: "stataMode.tcl"
 #                                          created: 01/15/2000 {07:15:32 pm}
 #                                      last update: 05/23/2006 {10:46:42 AM}
 # Description: 
 #
 # For Stata "do" and output files.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Original Stata menu written by L. Phillip Schumm <pschumm@uchicago.edu> 
 # 
 # Copyright (c) 2000-2006  Craig Barton Upright, L. Phillip Schumm
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ===========================================================================
# 
# ×××× Initialization of Stta mode ×××× #
# 

alpha::mode [list Stta Stata] 2.3b1 "stataMode.tcl" {
    *.do *.ado
} {
    stataMenu
} {
    # Script to execute at Alpha startup
    addMenu stataMenu "¥155" Stta
    set unixMode(stata) {Stta}
    set modeCreator(S5x8) {Stta}
} uninstall {
    catch {file delete [file join $HOME Tcl Modes stataMode.tcl]}
    catch {file delete [file join $HOME Tcl Completions SttaCompletions.tcl]}
    catch {file delete [file join $HOME Tcl Completions "Stta Tutorial.do"]}
} description {
    Supports the editing of Stata statistical "do" files
} help {
    file "Statistical Modes Help"
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
}

hook::register quitHook Stta::quitHook

proc stataMode.tcl {} {}

namespace eval Stta {
    
    # Comment Character variables for Comment Line/Paragraph/Box menu items.
    variable commentCharacters
    array set commentCharacters [list \
      "General"         "* " \
      "Paragraph"       [list "/* " " */" " * "] \
      "Box"             [list "/*" 1 "*/" 1 "*" 3] \
      ]
    
    # Set the list of flag preferences which can be changed in the menu.
    variable prefsInMenu [list \
      "localStataHelp" \
      "noHelpKey" \
      "/;<U<BsemiDelimiter" \
      "fullIndent" \
      "(-)" \
      "autoMark" \
      "markHeadingsOnly" \
      ]
    
    # Used in [Stta::colorizeStta].
    variable firstColorCall
    if {![info exists firstColorCall]} {
	set firstColorCall 1
    }
    
    # =======================================================================
    # 
    # ×××× Keyword Dictionaries ×××× #
    #
    # Nomenclature notes:
    # 
    # Stata has five levels of processes.
    # 
    #   1. "commands", "subcommands", "prefixes":  describe, define, quietly, 
    #   2. "parameters": textsize, maxobs, prefix, more,
    #   3. "functions": abs(), log(), sin(), ge, lt,
    #   4. "options": saving(), naxis graph, matrix graph,
    #   5. "modifiers": [weights= ], [frequency= ]
    # 
    #  and, just to help make sure that everything goes smoothly, we have
    #  
    #   6. out of date (or "dated") commands:  genrank, grebar
    #   
    # For the most part, Stata is very good about not using the same name for
    # a command to refer to a function, parameter, or modifier.  Options,
    # however, often have the same names as commands.
    # 
    # The default setup of this mode is to colorize all of commands,
    # subcommands, prefixes, parameters, and macros blue.  Options,
    # functions, modifiers, and symbols are colorized magenta.  Dated
    # commands are red.  The user does not have to specify all of these
    # different levels -- only Command, Comment, Option, String, and Symbol
    # colors appear in the preferences.
    # 
    # In addition, non-ambiguous abbreviations of command names are allowed.
    # They could be entered as Additional Commands or Additional Options
    # through "Config > Mode > Mode Preferences".
    # 
    # The sections which follow are based on release 3.1 of Stata, because
    # that was the latest full manual that I could get my hands on ...
    #
    
    variable keywordLists
    
    # =======================================================================
    # 
    # Stata Commands
    #
    # This also includes a select few unix shell commands.
    #
    set keywordLists(commands) [list \
      _qreg _robust accum acprplot adopath alpha anova aorder append areg \
      assert auto.dta avplot avplots bcskew0 begin bitest bitesti blogit \
      bmemsize boxcox bprobit brier bs bsample bsqreg bstat bstrap canon cc \
      cchart cci cd centile cf ci cii clear clogit cmdtool cnreg cnsreg \
      codebook coleq collapse colnames compare compress confirm constraint \
      convert copy correlate count cox cprplot cross cs csi cumul cusum \
      decode define degph delimit depnames describe dfbeta dictionary dir \
      discard dispCns display do dprobit drop ds dydx echo egen eivreg else \
      encode end erase ereg error existence exit expand factor fillin for \
      foreach format fsl function generate gladder global glogit glsaccum \
      gnbreg gphdot gphpen gprobit graph greigen grmeanby groups gunzip \
      gzip hadimvo heckman help hilite hold hotel if impute infile input \
      insheet inspect integ intreg ipolate iqreg ir iri kap kappa kapwgt \
      keep ksm ksmirnov ktau kwallis ladder lfit linktest list lnskew0 \
      local log logistic logit loneway lookfor lroc lrtest ls lstat ltable \
      lv lvr2plot makeCns man matcproc maximize mcc mcci means memsize menu \
      merge method mhodds mlogit mlout model move mvdecode mvencode mvreg \
      mx_param nbreg nl nlinit nptrend ologit oprobit order outfile \
      outsheet pause pchart pchi pcorr pd pd.ix pd.sunview pd.wy99 pd.X \
      plot pnorm poisson post postclose postfile predict preserve probit \
      profile.do pwcorr pwd qchi qnorm qqplot qreg quantile query range \
      ranksum rchart recast recode regph regress rename renpfix replace \
      report restore review rm rotate roweq rownames rreg run runtest \
      rvfplot rvpplot sample save score sdtest sdtesti search serrbar \
      sfrancia shell shewhart signrank signtest sktest smooth sort spearman \
      sqreg stack STATA stem substitute summarize sureg svd swilk symeigen \
      symplot sysdir tab1 tab2 tabi tabodds tabulate tempfile tempname \
      tempvar testparm tobit touch translate ttest ttesti type uncompress \
      unhold use vars vecaccum verinst version weibull which while window \
      xchart xpose \
      ]
    
    # =======================================================================
    # 
    # Prefixes
    
    # This includes not only prefixes proper {capture, noisily, quietly}, but
    # also commands that are only part of command-phrases.  These are
    # distinguished from "commands" for the Stta::Completions::Commands proc.
    #
    set keywordLists(prefixes) [list \
      capture constraint eq estimates label macro matrix ml noisily program \
      quietly reshape scalar set window xi: \
      ]
    
    # =======================================================================
    # 
    # Parameters
    #
    set keywordLists(parameters) [list \
      adosize ANSI beep contents graphics IBM level linesize logtype \
      matsize maxobs maxvar memory more obs output pagesize prefix rmsg \
      seed textsize trace video virtual width \
      ]
    
    # =======================================================================
    # 
    # Functions
    #
    set keywordLists(functions) [list \
      abs atan autocode Binomial chiprob comma condcos diff exp float fprob \
      gammap ge get group gt ibeta index int invbimonial invnorm invt iqr \
      le length ln lngamma lower lt ltrim ma max mean median min mod \
      norprob pctile rank rawsum real rmean rmiss robs round rsum rtrim sd \
      sign sin sqrt std string substr sum thru tprob trim uniform upper \
      ]
    
    # =======================================================================
    # 
    # Options
    #
    set keywordLists(options) [list \
      ..  accumulate accuracy adjust all alt asif b1title b2title backward \
      bands bar bartlett basecategory beta bin bonferroni border box bsize \
      bwidth cell censored chi2 column connect constraints continuity \
      cooksd corr covariance cutoff ddeviance dead delta density depname \
      depv detail deviance df dof dx2 eform eps equal equation exact \
      exposure factors failure fcnlabel fenter forward from fstay gamma gap \
      genwt get group half hascons hat hazard histogram hlines horst hr i \
      incr init initial intervals ipf irr iterate jitter l1title l2title \
      leave lf0 limits line lines lnlsq lnnormal lock lower lowess lrchi2 \
      ltolerance margin mineigen missing mse1 noadjust noalt noanova noauto \
      noaxis noborder nocoef nocone noconf nocons noconstant nodetail \
      noformat nofreq nograph noheader nolabel nolog nomeans noobs norotate \
      nostandard notab notable notest noties noweight number oneway or \
      outcome pc pcd pe pen pie pr pr2 promax protect psize r1title r2title \
      random rbox reps Rescale rescale resid residuals rlabel rlog root rrr \
      rscale rstandard rstudent rtick rules scheffe select shading sidak \
      split stabilzied star stdf stdp stdr strata symbol symbolic t1title \
      t2title taub threshold title tlabel tolerance total tr trim ttick \
      tune tvid twoway unequal unpaired upper V varimax varp vlines vwidth \
      wgt wide wlsiter wrap xb xlabel xlog xscale xtick ylabel ylog yscale \
      ytick zero \
      ]
    
    # =======================================================================
    # 
    # Modifiers
    #
    set keywordLists(modifiers) [list \
      .do .dot .dta .gph .help .log .pen .raw .xp _all _b _coef _merge _N \
      _n _pi _rc _se aweight by fast frequency fweight in iweight \
      ltolerance off old on pddefs pweight saving stata.do stata.hlp \
      stata.lic stata.mnu stata.usr statpd TEMP title using value values \
      variable variables weight \
      ]
    
    # =======================================================================
    # 
    # Stata Macros
    #
    set keywordLists(macros) [list \
      A_DATE S_ADO S_E_ S_E_11 S_E_tdf S_FLAVOR S_FN S_MACHID S_mdf \
      S_mldbug S_MODE S_nobs S_NOFKEY S_OS S_OSDTL S_TIME \
      ]
    
    # =======================================================================
    # 
    # Dated Commands
    #
    set keywordLists(dated) [list \
      _huber boot bootsamp chdir clogitp corc coxbase coxhaz coxvar datetof \
      dbeta deff disp_res disp_s etodow etof etomdy fit fpredict ftodate \
      ftoe ftomdy ftowdate genrank genstd genvmean glmpred grebar gwood \
      hareg hereg hlogit hlu hprobit hreg huber kapmeier leverage logiodds \
      logiodds2 loglogs logrank lpredict mantel mdytoe mdytof modify nlpred \
      ologitp oprobitp parse regdw remap repeat stepwise survcurv survival \
      survsum swcnreg swcox swereg swlogis swlogit swologit swoprbt swpois \
      swprobit swqreg swtobit swweib textstd wdatetof wilcoxon xtpred \
      ]
}

# ===========================================================================
# 
# ××××  Stata mode variables ×××× #
#

# ===========================================================================
#
# Standard preferences recognized by various Alpha procs
#

newPref var  fillColumn         {75}                    Stta
newPref var  leftFillColumn     {0}                     Stta
newPref var  prefixString       {* }                    Stta
newPref var  wordBreak          {[-\w\._\#]+}    Stta
newPref var  lineWrap           {0}                     Stta
newPref var  commentsContinuation 1 			Stta "" \
  [list "only at line start" "spaces allowed" "anywhere"] index

# ===========================================================================
#
# Flag preferences
#

# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 Stta
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 Stta
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Stta
# To automatically mark files when they are opened, turn this item on||To
# disable the automatic marking of files when they are opened, turn this
# item off
newPref flag autoMark           {0}     Stta    {Stta::rebuildMenu markStataFileAs}
# To only mark "headings" in windows (those preceded by ***), turn this item
# on||To mark both commands and headings in windows, turn this item off
newPref flag markHeadingsOnly   {0}     Stta    {Stta::postBuildMenu}
# To indent all continued commands (indicated by a comment or the lack of a
# semi-colon at the end of a line) by the full indentation amount rather
# than half, turn this item on|| To indent all continued commands (indicated
# by a comment or the lack of a semi-colon at the end of a line) by half of
# the indentation amount rather than the full, turn this item off
newPref flag fullIndent         {1}     Stta    {Stta::rebuildMenu markStataFileAs}
# To use semicolons as a delimiter in do files, turn this item on.  This
# affects indentation as well as all electric completions|| To stop using
# semicolons as a delimiter in do files, turn this item off.  This affects
# indentation as well as all electric completions
newPref flag semiDelimiter      {0}     Stta    {Stta::rebuildMenu stataHelp}
# To primarily use a www site for help rather than the local Stata
# application, turn this item on|| To primarily use the local Stata
# application for help rather than on a www site turn this item off
newPref flag localStataHelp     {0}     Stta    {Stta::rebuildMenu stataHelp}
# If your keyboard does not have a "Help" key, turn this item on.  This will
# change some of the menu's key bindings|| If your keyboard has a "Help"
# key, turn this item off.  This will change some of the menu's key bindings
newPref flag noHelpKey          {0}     Stta    {Stta::rebuildMenu stataHelp}

# ===========================================================================
#
# Variable preferences
# 

# Enter additional Stata commands  or abbreviations to be colorized.
newPref var addCommands         {}      Stta    {Stta::colorizeStta}
# Enter additional options or abbreviations to be colorized.  
newPref var addOptions          {gen rep}       Stta    {Stta::colorizeStta}
# Command double-clicking on a Stata keyword will send it to this url for a
# help reference page.
newPref url helpUrl             {http://www.stata.com/help.cgi?}        Stta
# The "Stata Home Page" menu item will send this url to your browser.
newPref url stataHomePage       {http://www.stata.com/} Stta
# Click on "Set" to find the local Stata application.
newPref sig stataSig            {S5x8}  Stta

# ===========================================================================
# 
# Color preferences
#

# See the Statistical Modes Help file for an explanation of these different
# categories, and lists of keywords.
newPref color commandColor      {blue}      Stta    {Stta::colorizeStta}
newPref color commentColor      {red}       Stta    {stringColorProc}
# Color of the magic character $.  Magic Characters will colorize any
# string which follows them, up to the next empty space.
newPref color magicColor        {none}      Stta    {Stta::colorizeStta}
newPref color optionColor       {magenta}   Stta    {Stta::colorizeStta}
newPref color stringColor       {green}     Stta    {stringColorProc}
# The color of symbols such as "+", "-", etc.
newPref color symbolColor       {magenta}   Stta    {Stta::colorizeStta}

# ===========================================================================
# 
# Categories of all Stata preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be unset.)
# 

# Editing
prefs::dialogs::setPaneLists "Stta" "Editing" [list \
  "autoMark" \
  "electricBraces" \
  "electricSemicolon" \
  "indentOnReturn" \
  "fillColumn" \
  "fullIndent" \
  "leftFillColumn" \
  "lineWrap" \
  "markHeadingsOnly" \
  "semiDelimiter" \
  "wordBreak" \
  ]

# Comments
prefs::dialogs::setPaneLists "Stta" "Comments" [list \
  "commentColor" \
  "commentsContinuation" \
  "prefixString" \
  ]

# Colors
prefs::dialogs::setPaneLists "Stta" "Colors" [list \
  "addCommands" \
  "addOptions" \
  "commandColor" \
  "magicColor" \
  "optionColor" \
  "stringColor" \
  "symbolColor" \
  ]

# Help
prefs::dialogs::setPaneLists "Stta" "Stata Help" [list \
  "helpUrl" \
  "localStataHelp" \
  "noHelpKey" \
  "stataHomePage" \
  "stataSig" \
  ]

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::colorizeStta" --
 # 
 # Set all keyword lists, and colorize.
 # 
 # Could also be called in a <mode>Prefs.tcl file
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::colorizeStta {{pref ""}} {
    
    global SttamodeVars Sttacmds SttaUserCommands SttaUserOptions
    
    variable firstColorCall
    variable keywordLists
    
    set Sttacmds [list]
    # Create the "allCommands" list for [Stta::Completion::Command].
    set keywordLists(allCommands) [list]
    foreach keyword $keywordLists(commands) {
	lappend Sttacmds $keyword
	lappend keywordLists(allCommands) $keyword
    }
    foreach keyword $keywordLists(prefixes) {
	lappend Sttacmds $keyword
	lappend keywordLists(allCommands) $keyword
    }
    foreach keyword $keywordLists(parameters) {
	lappend Sttacmds $keyword
	lappend keywordLists(allCommands) $keyword
    }
    foreach keyword $keywordLists(macros) {
	lappend Sttacmds $keyword
	lappend keywordLists(allCommands) $keyword
    }
    foreach keyword $SttamodeVars(addCommands) {
	lappend Sttacmds $keyword
	lappend keywordLists(allCommands) $keyword
    }
    if {[info exists SttaUserCommands]} {
	foreach keyword $SttaUserCommands {
	    lappend Sttacmds $keyword
	    lappend keywordLists(allCommands) $keyword
	}
    }
    
    # Then create the list of all options, for the "Sttaelectric" array.
    set keywordLists(allOptions) [list]
    foreach keyword $keywordLists(options) {
	lappend Sttacmds $keyword
	lappend keywordLists(allOptions) $keyword
    }
    foreach keyword $SttamodeVars(addOptions) {
	lappend Sttacmds $keyword
	lappend keywordLists(allOptions) $keyword
    }
    if {[info exists SttaUserOptions]} {
	foreach keyword $SttaUserOptions {
	    lappend Sttacmds $keyword
	    lappend keywordLists(allOptions) $keyword
	}
    }
    
    # Add other keyword lists to "Sttacmds".
    set otherKeywords [list]
    foreach keyword $keywordLists(functions) {
	lappend Sttacmds $keyword
	lappend otherKeywords $keyword
    }
    foreach keyword $keywordLists(modifiers) {
	lappend Sttacmds $keyword
	lappend otherKeywords $keyword
    }
    foreach keyword $keywordLists(dated) {
	lappend Sttacmds $keyword
    }
    
    # "Sttacmds"
    set Sttacmds [lsort -dictionary -unique $Sttacmds]
    
    # Now we colorize keywords.  If this is the first call, we don't include 
    # the "-a" flag.
    if {$firstColorCall} {
	regModeKeywords -C Stta {}
	set firstColorCall 0
    }
    
    # Color comments and strings.
    regModeKeywords -a -e {*} -b {/*} {*/} -c $SttamodeVars(commentColor) \
      -s $SttamodeVars(stringColor) Stta
    
    # Color Commands, Prefixes, Parameters, User Macros
    regModeKeywords -a -k $SttamodeVars(commandColor) \
      Stta $keywordLists(allCommands)
    
    # Color Options
    regModeKeywords -a -k $SttamodeVars(optionColor) \
      Stta $keywordLists(allOptions)
    
    # Functions, Options, Modifiers, Stata-Macros, 
    regModeKeywords -a -k $SttamodeVars(optionColor) Stta $otherKeywords
    
    # Dated
    regModeKeywords -a -k red Stta $keywordLists(dated)
    
    # Symbols
    regModeKeywords -a -i "+" -i "-" -i "\\" -i "|" \
      -I $SttamodeVars(symbolColor)  Stta {}
    
    # 'Magic' color for dollar sign.
    regModeKeywords -a -m {$} -k $SttamodeVars(magicColor) Stta {}
    
    if {$pref ne ""} {
	refresh
    }
    return
}

# Call this now.

Stta::colorizeStta

# ===========================================================================
#
# ×××× Key Bindings, Electrics ×××× #
# 
# abbreviations:  <o> = option, <z> = control, <s> = shift, <c> = command
# 

Bind '\;'   <sz>    {Stta::menuProc stataModeOptions semiDelimiter} Stta
Bind ':'    <sz>    {Stta::menuProc stataModeOptions semiDelimiter} Stta

Bind '\r'   <s>     {Stta::continueCommand} Stta
Bind '\)'           {Stta::electricRight "\)"} Stta

# For those that would rather use arrow keys to navigate.  Up and down
# arrow keys will advance to next/prev command, right and left will also
# set the cursor to the top of the window.

Bind    up  <sz>    {Stta::searchFunc 0 0 0} Stta
Bind  left  <sz>    {Stta::searchFunc 0 0 1} Stta
Bind  down  <sz>    {Stta::searchFunc 1 0 0} Stta
Bind right  <sz>    {Stta::searchFunc 1 0 1} Stta

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::carriageReturn" --
 # 
 # Inserts a carriage return, and indents properly.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::carriageReturn {} {
    
    global SttamodeVars
    
    if {[isSelection]} {
	deleteSelection
    }
    set pos1 [lineStart [getPos]]
    set pos2 [getPos]
    if {[regexp {^([\t ])*(end|\}|\))} [getText $pos1 $pos2]]} {
	createTMark temp $pos2
	catch {bind::IndentLine}
	gotoTMark temp
	removeTMark temp
    }
    insertText "\r"
    catch {bind::IndentLine}
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::electricSemi" --
 # 
 # Inserts a semi, carriage return, and indents properly.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::electricSemi {} {
    
    global SttamodeVars
    
    if {[isSelection]} {
	deleteSelection
    }
    if {[literalChar] || !$SttamodeVars(semiDelimiter)} {
	typeText {;}
	return
    }
    set pos1 [lineStart [getPos]]
    set pos2 [getPos]
    insertText {;}
    bind::CarriageReturn
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::electricLeft" --
 # "Stta::electricRight" --
 # 
 # Adapted from "tclMode.tcl"
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::electricLeft {} {
    
    if {[literalChar]} {
	typeText "\{"
	return
    }
    set pat "\}\[ \t\r\n\]*(else(if)?)\[ \t\r\n\]*\$"
    set pos [getPos]
    if {([set result [findPatJustBefore "\}" $pat $pos word]] eq "")} {
	insertText "\{"
	return
    }
    # we have an if/else(if)/else
    switch -- $word {
	"else" {
	    deleteText [lindex $result 0] $pos
	    elec::Insertion "\} $word \{\r\t¥¥\r\}\r¥¥"
	}
	"elseif" {
	    deleteText [lindex $result 0] $pos
	    elec::Insertion "\} $word \{¥¥\} \{\r\t¥¥\r\}\r¥¥"
	}
    }
    return
}
    
proc Stta::electricRight {{char "\}"}} {
    
    if {[literalChar]} {
	typeText $char
	return
    }
    set pos [getPos]
    typeText $char
    if {![regexp {[^ \t]} [getText [lineStart $pos] $pos]]} {
	set pos [lineStart $pos]
	createTMark temp [getPos]
	catch {bind::IndentLine}
	gotoTMark temp
	removeTMark temp
	bind::CarriageReturn
    }
    if {[catch {blink [matchIt $char [pos::math $pos - 1]]}]} {
	beep
	status::msg "No matching $char !!"
    }
    return
}

proc Stta::searchFunc {direction args} {
    
    if {![llength $args]} {
	set args [list 0 2]
    }
    if {$direction} {
	eval function::next $args
    } else {
	eval function::prev $args
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::continueCommand" --
 # 
 # Indenting continuation lines relative to start of command.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::continueCommand {} {
    
    set thisLine [lindex [Stta::getCommandLine [lineStart [getPos]] 1 0] 2]
    set thisLine [string trim $thisLine]
    if {![regexp {/\*([^\*]*)$} $thisLine]} {
	typeText " /*"
    }
    Stta::carriageReturn
    insertText "*/ "
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::CommentLine" --
 # "Stta::UncommentLine" --
 # 
 # An over-ride for the SystemCode [::CommentLine] procedure.
 # 
 # In the default routine, if the commentCharacters(Paragraph) are different
 # then [::CommentLine] will automatically be bracketed.  We just want to be
 # able to comment a single line without considering it to be a paragraph.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::CommentLine {} {
    insertPrefix
    return
}

proc Stta::UncommentLine {} {
    removePrefix
    return
}

# ===========================================================================
#
# ×××× Indentation ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::correctIndentation" --
 # 
 # [Stta::correctIndentation] is necessary for Smart Paste, and returns the
 # correct level of indentation for the current line.
 # 
 # We have three levels of indentation in Stata.  The first is for the
 # continuation of commands, in which case we simply indent respecting the
 # Stta mode variable fullIndent.  The second is for programs, in which case
 # we indent the start of each command by indentationAmount until we reach an
 # "end" command.  The third is for nested {} statements.
 # 
 # In [Stta::correctIndentation] we grab the previous line, remove all of the
 # characters besides braces and quotes, and then convert it all to a list to
 # be evaluated.  Braces contained within quotes, as well as literal
 # characters, should all be ignored and the remaining braces are used to
 # determine the correct level of nesting.
 # 
 # This works really well for "simple" syntax files, without multi-line block
 # commented sections embedded in either program definitions or actual
 # commands.
 # 
 # Known limitation (or a feature, depending on your point of view): Indented
 # lines of block comments will be recognized as "valid" commands that are
 # being continued, and themselves indented when a region is formatted,
 # leading to a construction that looks like this:
 # 
 #       command var
 #       
 #       /* 
 #           * It is important to note that the CPS files produced
 #           * by the Census Bureau do not have decimal points in
 #           * the data.  
 #           */
 #        
 #       next command var
 # 
 # or maybe
 # 
 #       command var
 #       
 #       /*  It is left to the documentation to inform
 #           the user how many decimals are implied.  The user
 #           must make the proper adjustment before using
 #           weights.  This is true for all the weights. 
 #           */
 # 
 # In this case, it's important that the ending */ appear on a line by itself
 # to signal that this line was a "continued" command, now complete.  It all
 # gets messier when trying to figure out what a syntax file "should" look
 # like given the semi delimiter possibility, too ...
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::correctIndentation {args} {
    
    global SttamodeVars indentationAmount
    
    win::parseArgs w pos {next ""}
    
    if {([win::getMode $w] eq "Stta")} {
	set continueIndent [expr {$SttamodeVars(fullIndent) + 1}]
    } else {
	set continueIndent 2
    }
    
    set posBeg    [pos::lineStart -w $w $pos]
    # Get information about this line, previous line ...
    set thisLine  [Stta::getCommandLine -w $w $posBeg 1 2]
    set prevLine1 [Stta::getCommandLine -w $w \
      [pos::math -w $w $posBeg - 1] 0 2]
    set prevLine2 [Stta::getCommandLine -w $w \
      [pos::math -w $w [lindex $prevLine1 0] - 1] 0 2]
    set lwhite    [lindex $prevLine1 1]
    # If we have a previous line ...
    if {[pos::compare -w $w [lindex $prevLine1 0] != $posBeg]} {
	set pL1 [string trim [lindex $prevLine1 2]]
	# Indent if the preceding command was a program definition.
	if {[regexp {^[\t ]*program+[\t ]+define} $pL1]} {
	    incr lwhite $indentationAmount
	}
	# Indent if the last line did not terminate the command.
	if {![Stta::endOfCommand $pL1]} {
	    incr lwhite [expr {$continueIndent * $indentationAmount/2}]
	}
	# Check to make sure that the previous command was not itself a
	# continuation of the line before it.
	if {[pos::compare -w $w [lindex $prevLine1 0] != [lindex $prevLine2 0]]} {
	    set pL2 [string trim [lindex $prevLine2 2]]
	    if {![Stta::endOfCommand $pL2]} {
		incr lwhite [expr {-$continueIndent * $indentationAmount/2}]
	    }
	}
	# Find out if there are any unbalanced {,},(,) in the last line.
	regsub -all {[^ \{\}\(\)\"\*\/\\]} $pL1 { } line
	# Remove all literals.
	regsub -all {\\\{|\\\}|\\\(|\\\)|\\\"|\\\*|\\\/} $line { } line
	regsub -all {\\} $line { } line
	# Remove everything surrounded by quotes.
	regsub -all {\"[^\"]+\"} $line { } line
	regsub -all {\"} $line { } line
	# Remove everything surrounded by bracketed comments.
	regsub -all {/\*[^\*/]+\*/} $line { } line
	# Now turn all braces into 2's and -2's
	regsub -all {\{|\(} $line { 1 }  line
	regsub -all {\}|\)} $line { -1 } line
	# This list should now only contain 2's and -2's.
	foreach i $line {
	    if {($i == "1") || ($i == "-1")} {
		incr lwhite [expr {$i * $indentationAmount}]
	    }
	}
	# Did the last line start with a lone \) or \} ?  If so, we want to
	# keep the indent, and not make call it an unbalanced line.
	if {[regexp {^[\t ]*(\}|\))} $pL1]} {
	    incr lwhite $indentationAmount
	}
    }
    # If we have a current line ...
    if {[pos::compare -w $w [lindex $thisLine 0] == $posBeg]} {
	# Reduce the indent if the first non-whitespace character of this
	# line is \) or \}, or an "end" command.
	set tL [lindex $thisLine 2]
	if {($next eq "\}") || ($next eq "\)") \
	  || [regexp {^[\t ]*(\}|\)|end)} $tL]} {
	    incr lwhite -$indentationAmount
	}
    }
    # Now we return the level to the calling proc.
    return [expr {$lwhite > 0 ? $lwhite : 0}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::getCommandLine" --
 # 
 # Find the next/prev command line relative to a given position, and return
 # the position in which it starts, its indentation, and the complete text
 # of the command line.  If the search for the next/prev command fails,
 # return an indentation level of 0.
 # 
 # Unlike SPSS and SAS modes, we don't have the luxury of ignoring commented
 # lines since they could simply indicate the continuation of commands.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::getCommandLine {args} {
    
    win::parseArgs w pos {direction 1} {ignoreComments 1}
    
    if {($ignoreComments == 1)} {
	set pat {^[\t ]*[^\t\r\n\*/ ]}
    } elseif {($ignoreComments == 2)} {
	set pat {^[\t ]*[^\t\r\n/ ]}
    } else {
	set pat {^[\t ]*[^\t\r\n ]}
    }
    set posBeg [pos::math -w $w [pos::lineStart -w $w $pos] - 1]
    if {[pos::compare -w $w $posBeg < [minPos -w $w]]} {
	set posBeg [minPos -w $w]
    }
    set lwhite 0
    if {![catch {search -w $w -s -f $direction -r 1 $pat $pos} match]} {
	set posBeg [lindex $match 0]
	set lwhite [lindex [pos::toRowCol -w $w \
	  [pos::math -w $w [lindex $match 1] - 1]] 1]
    }
    set posEnd [pos::math -w $w [pos::nextLineStart -w $w $posBeg] - 1]
    if {[pos::compare -w $w $posEnd > [maxPos -w $w]]} {
	set posEnd [maxPos -w $w]
    } elseif {[pos::compare -w $w $posEnd < $posBeg]} {
	set posEnd $posBeg
    }
    return [list $posBeg $lwhite [getText -w $w $posBeg $posEnd]]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::endOfCommand" --
 # 
 # Determine if the command in a line of a given position was terminated.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::endOfCommand {line} {
    
    global SttamodeVars
    
    if {!$SttamodeVars(semiDelimiter)} {
	# Check to see if the last line ended with /*, indicating continuation.
	if {[regexp {/\*([^\*]*)$} $line]} {
	    return 0
	} else {
	    return 1
	}
    } else {
	# Check to see if the last line ended with ;, indicating termination.
	if {[regexp {;([\t ]*)$} $line]} {
	    return 1
	} else {
	    return 0
	}
    }
}

# ===========================================================================
# 
# ×××× Command Double Click ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::DblClick" --
 # 
 # First checks to see if this is a macro defined in current window.
 # 
 # Then checks to see if the highlighted word appears in any keyword list,
 # and if so, sends the selected word to the www.stata.com help site.  Stata
 # commands are case-sensitive, and so is the help search engine.
 #
 # Control-Command double click will insert syntax information in status bar.
 # Shift-Command double click will insert commented syntax information in
 # window.  Option-Command double click will send the command to Stata
 # application.  (lps)
 # 
 # If "Local Help" is checked, option vs not is reversed, so that command
 # double-click will send to local Stata application.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::DblClick {from to shift option control} {
    
    global SttamodeVars
    
    variable keywordLists
    variable syntaxMessages
    
    set validCommands  [concat \
      $keywordLists(commands)  $keywordLists(prefixes) \
      $keywordLists(parameters) $keywordLists(functions) \
      $keywordLists(modifiers) $keywordLists(macros) $keywordLists(dated) \
      ]
    
    selectText $from $to
    set command [getSelect]
    set macroDef {program[\t ]define[\t ]*$command[\t\r\n; ]}
    
    # First found out if "$command" is a file in the same directory, or a 
    # complete path.  If the file exists, open it in Alpha.
    if {[file::tryToOpen $command 0]} {
	return
    }
    # Not a file, so try something else.
    if {![catch {search -s -f 1 -r 1 $macroDef [minPos]} match]} {
	# First check current file for macro definition, and if found ...
	placeBookmark
	goto [lineStart [lindex $match 0]]
	status::msg "press <Ctl .> to return to original cursor position"
	return
	# Could next check any open windows, or files in the current
	# window's folder ...  but not implemented.  For now, macros need
	# to be defined in current file.
    } elseif {([lcontains validCommands $command] == "-1")} {
	# If not a defined macro, check to see if it's a defined keyword.
	status::msg "'$command' is not defined as a Stata system keyword."
	return
    }
    # Any modifiers pressed?
    if {$control} {
	# CONTROL -- Just put syntax message in status bar window
	if {[info exists syntaxMessages($command)]} {
	    status::msg $syntaxMessages($command)
	} else {
	    status::msg "Sorry, no syntax information available for $command"
	}
    } elseif {$shift} {
	# SHIFT --Just insert syntax message as commented text
	if {([lcontains keywordLists(dated) $command] != "-1")} {
	    status::msg "$syntaxMessages($command)"
	} elseif {[info exists syntaxMessages($command)]} {
	    endOfLine
	    insertText "\r"
	    insertText "$syntaxMessages($command)"
	    comment::Line
	} else {
	    status::msg "Sorry, no syntax information available for $command"
	}
    } elseif {$option && !$SttamodeVars(localStataHelp)} {
	# Now we have four possibilities, based on "option" key and the
	# preference for "local Help".
	# 
	# OPTION, local help isn't checked -- Send command to local application
	Stta::localCommandHelp $command
    } elseif {$option && $SttamodeVars(localStataHelp)} {
	# OPTION, but local help is checked -- Send command for on-line help.
	Stta::wwwCommandHelp $command
    } elseif {$SttamodeVars(localStataHelp)} {
	# No modifiers, local help is checked -- Send command to local app.
	Stta::localCommandHelp $command
    } else {
	# No modifiers, no local help checked -- Send command for on-line
	# help.  This is the "default" behavior.
	Stta::wwwCommandHelp $command
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::wwwCommandHelp" --
 # 
 # Send command to defined url, prompting for text if necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::wwwCommandHelp {{command ""}} {
    
    global SttamodeVars
    
    if {![string length $command]} {
	if {[catch {prompt "On-line Stata help for É" ""} command]} {
	    error "cancel"
	}
    }
    status::msg "'$command' sent to $SttamodeVars(helpUrl)"
    urlView $SttamodeVars(helpUrl)$command
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::localCommandHelp" --
 # 
 # Send command to local application, prompting for text if necessary.
 # 
 # -- lps
 # 
 # Supposedly, this works on all platforms ... -- cbu
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::localCommandHelp {{command ""}} {
    
    if {($command eq "")} {
	set command [prompt "local Stata application help for ... " [getSelect]]
	# set command [statusPrompt "local Stata application help for ... " ] 
    }
    Stta::doSelection "whelp $command"
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::commandHelp" --
 # 
 # Send the command to a local Stata application if it exists, otherwise send
 # it the defined web site.  (Used in the "Statistical Modes Help" file,
 # could easily be used in the menu if desired ...)
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::commandHelp {{command ""}} {
    
    global SttamodeVars tcl_platform
    
    if {($command eq "")} {
	set command [prompt "Stata help for ..." ""]
    }
    if {([set command [string trim $command]] eq "")} {
	error "Cancelled -- no command was entered."
    }
    if {[regexp $command " "]} {
	error "Cancelled -- only enter one command for help."
    }
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    # Make sure that the Macintosh application for the signature
	    # actually exists.
	    if {![catch {nameFromAppl $SttamodeVars(stataSig)}]} {
		set local 1
	    } else {
	        set local 0
	    }
	}
	"windows" - "unix" {
	    # Make sure that the Windows application for the signature
	    # exists.  We assume that this will work for unix, too.
	    if {[file exists $SttamodeVars(stataSig)]} {
		set local 1
	    } else {
		set local 0
	    }
	}
    }
    if {$local} {
	Stta::localCommandHelp $command
    } else {
	Stta::wwwCommandHelp $command
    }
    return
}

# ===========================================================================
# 
# ×××× Mark File and Parse Functions ×××× #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::MarkFile" --
 # 
 # This will return the first 35 characters from the first non-commented word
 # appearing in column 0.  Codebook files will be marked differently, listing
 # variable names.  All other output files (those not recognized) will take
 # into account the additional left margin elements added by Stata.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::MarkFile {args} {
    
    global SttamodeVars
    
    win::parseArgs w {type ""}
    
    status::msg "Marking \"[win::Tail $w]\" É"
    
    set pos [minPos]
    set count1 0
    set count2 0
    # Figure out what type of file this is -- source, codebook, or output.
    # The variable "type" refers to a call from the Stata menu.
    # Otherwise we try to figure out the type based on the file's suffix.
    if {($type eq "")} {
	if {([win::Tail $w] eq "* Stata Mode Example *")} {
	    # Special case for Mode Examples, but only if called from
	    # Marks menu.  (Called from Stata menu, "type" will over-ride.)
	    set type  ".do"
	} else {
	    set type [file extension [win::Tail $w]]
	}
    }
    # Now set the mark regexp.
    if {($type eq ".do") || ($type eq ".ado")} {
	# Source file.
	if {!$SttamodeVars(markHeadingsOnly)} {
	    set markExpr {^(!+[\t ]|\*\*\*[ ]|\*\*\*\*[ ])?[a-zA-Z0-9_\#]}
	} else {
	    set markExpr {^\*\*\*\**[\t ]*[^\r\n\t *]}
	}
    } elseif {($type eq ".codebook")} {
	# Codebook file, called from the Stata menu
	set markExpr {^[a-zA-Z0-9]+( \-)}
    } else {
	# None of the above, so assume that it's output
	set markExpr {^(\. )+((!+[\t ]|\*\*\*[ ]|\*\*\*\*[ ])?[a-zA-Z0-9_\#])}
    }
    # Mark the file
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1 $markExpr $pos} match]} {
	set pos0 [lindex $match 0]
	set pos1 [pos::nextLineStart -w $w $pos0]
	set mark [string trimright [getText -w $w $pos0 $pos1]]
	# Get rid of the leading ". " for output files
	# Add a little indentation so that section marks show up better.
	set mark "  [string trimleft  $mark ". "]"
	if {[regexp -- {^\s*\*+\s*-+\s*$} $mark]} {
	    set mark "-"
	} elseif {[regsub -- {  \*\*\*\* } $mark {* } mark]} {
	    incr count2
	} elseif {[regsub -- {  \*\*\* } $mark {¥ } mark]} {
	    incr count2
	} else {
	    incr count1
	}
	# Get rid of trailing sem-colons, and truncate if necessary.
	set mark [markTrim [string trimright $mark ";" ]]
	while {[lcontains marks $mark]} {
	    append mark " "
	}
	lappend marks $mark
	if {($type eq ".codebook")} {
	    # Get rid of the trailing "-" for frequency / codebook files.
	    regsub {[-]+( É)} $mark { } mark
	    set mark [string trimleft  $mark " "]
	    status::msg "# of variables: $count1"
	}
	setNamedMark -w $w $mark $pos0 $pos0 $pos0
	set pos $pos1
    }
    # Report how many marks we created.
    if {($type eq ".codebook")} {
	# Sort the marks if this is a codebook.
	status::msg "Sorting marks É"
	sortMarksFile
	set msg "This codebook describes $count1 variables."
    } elseif {!$SttamodeVars(markHeadingsOnly)} {
	set msg "The window \"[win::Tail $w]\" contains $count1 command"
	append msg [expr {($count1 == 1) ? "." : "s."}]
    } else {
	set msg "The window \"[win::Tail $w]\" contains $count2 heading"
	append msg [expr {($count2 == 1) ? "." : "s."}]
    }
    status::msg $msg
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::parseFuncs" --
 # 
 # This will return only the Stta command names.  All other output files
 # (those not recognized) will take into account the additional left margin
 # elements added by Stata.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::parseFuncs {} {
    
    global sortFuncsMenu
    
    set ext [file extension [win::CurrentTail]]
    
    # Determine the file type.
    if {($ext eq ".do") || ($ext eq ".ado")} {
	set funcExpr {^(\w+)}
    } elseif {([file tail [win::Current]] eq "* Stta Mode Example *")} {
	# Special case for Mode Examples folder
	set funcExpr {^(\w+)}
    } else {
	# We don't worry about codebooks here, we'll just parse as output.
	set funcExpr {^(\. )(\w+)}
    }
    # Parse the file.
    set pos [minPos]
    set m   [list ]
    while {![catch {search -s -f 1 -r 1 -i 0 $funcExpr $pos} match]} {
	if {[regexp -- {^(\w+)} [eval getText $match] "" word]} {
	    lappend m [list $word [lindex $match 0]]
	}
	set pos [lindex $match 1]
    }
    if {$sortFuncsMenu} {
	set m [lsort -dictionary $m]
    }
    return [join $m]
}

# ===========================================================================
# 
# ×××× -------------------- ×××× #
# 
# ×××× Stata Menu ×××× #
# 
# version: 1.2
# 
# Author: L. Phillip Schumm
# E-mail: <pschumm@uchicago.edu>
# 
# If Stata is launched from Alpha, then Stata's own directory will become
# the working directory unless a profile.do file is used to change it.
#
# version history:
# 
# 1.1  lps  Contributed menu to stataMode.tcl
# 1.2  cbu  Added "Mark File As", simplified Stta::menuProc .
#           Added "Help", added optional argument to doFile .
#           Changed "Menu -n ..." proc to "menu::buildProc stataMenu ...".
# 1.3  cbu  Added more preferences to Help section, and Navigation section.
# 2.0  cbu  Updated for Alpha 7.4, added "Stata Home Page" menu item.
# 2.1  cbu  Added "Keywords" submenu, cleaning up "Help"
# 

proc stataMenu {} {}

# This was the old menu definition proc.

# Menu -n $stataMenu -p Stta::menuProc -M Stta {
#     "/S<U<OswitchToStata"
#     "(-"
#     "/D<U<OdoFile"
#     "/D<U<O<BdoSelection"
#     {Menu -n markStataFileAs -p Stta::markFileProc {
#         "source"
#         "output"
#         "codebook"  }
#     }
#     {Menu -n StataHelp -p Stta::helpProc {
#         "/t<BstataModeHelp"
#         "/t<IlocalCommandHelpÉ"
#         "/t<OwwwCommandHelpÉ" }
#     }
#     "(-"
#     "/P<U<OinsertPath"
#     "/P<U<O<BprogramTemplate"
# }

# Tell Alpha what procedures to use to build all menus, submenus.

menu::buildProc stataMenu Stta::buildMenu     Stta::postBuildMenu
menu::buildProc stataHelp Stta::buildHelpMenu

# First build the main Stata menu.

proc Stta::buildMenu {} {
    
    global stataMenu 
    
    variable prefsInMenu
    
    set optionItems $prefsInMenu
    set keywordItems [list \
      "listKeywords" "checkKeywordsÉ" "addNewCommandsÉ" "addNewOptionsÉ"]
    set markItems [list "source" "output" "codebook"]
    set menuList [list \
      "stataHomePage" \
      "switchToStata" \
      "/D<U<OdoFile" \
      "/D<U<O<BdoSelection" \
      "(-)" \
      [list Menu -n stataHelp           -M Stta {}] \
      [list Menu -n stataModeOptions -p Stta::menuProc -M Stta $optionItems] \
      [list Menu -n stataKeywords    -p Stta::menuProc -M Stta $keywordItems] \
      [list Menu -n markStataFileAs  -p Stta::menuProc -M Stta $markItems] \
      "(-)" \
      "/P<U<OprogramTemplate" \
      "/b<UcontinueCommand" \
      "/'<E<S<BnewComment" \
      "/'<S<O<BcommentTemplateÉ" \
      "(-)" \
      "/N<U<BnextCommand" \
      "/P<U<BprevCommand" \
      "/S<U<BselectCommand" \
      "/I<B<OreformatCommand" \
      ]
    set submenus [list stataHelp]
    return       [list build $menuList "Stta::menuProc -M Stta" $submenus $stataMenu]
}

# Then build the "Stata Help" submenu.

proc Stta::buildHelpMenu {} {
    
    global SttamodeVars
    
    # Determine which key should be used for "Help", with F8 as option.
    
    if {!$SttamodeVars(noHelpKey)} {
	set key "/t"
    } else {
	set key "/l"
    }
    
    # Reverse the local, www key bindings depending on the value of the
    # 'Local Help" variable.
    
    if {!$SttamodeVars(localStataHelp)} {
	set menuList [list \
	  "${key}<OwwwCommandHelpÉ" \
	  "${key}<IlocalCommandHelpÉ" \
	  ]
    } else {
	set menuList [list \
	  "${key}<OlocalCommandHelpÉ" \
	  "${key}<IwwwCommandHelpÉ" \
	  ]
    }
    lappend menuList "(-)" "setStataApplicationÉ" \
      "(-)" "${key}<BstataModeHelp"
    
    return [list build $menuList "Stta::menuProc -M Stta" {}]
}

proc Stta::rebuildMenu {{menuName "stataMenu"} {pref ""}} {
    menu::buildSome $menuName
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::postBuildMenu" --
 # 
 # Mark or dim items as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::postBuildMenu {args} {
    
    global SttamodeVars 
    
    variable prefsInMenu
    
    foreach itemName $prefsInMenu {
	regsub {/;<U<B} $itemName {} itemName
	if {[info exists SttamodeVars($itemName)]} {
	    markMenuItem stataModeOptions $itemName $SttamodeVars($itemName) Ã
	}
    }
    return
}

# Now we actually build the Stata menu.
menu::buildSome stataMenu

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::registerOWH" --
 # 
 # Dim some menu items when there are no open windows.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::registerOWH {{which "register"}} {
    
    global stataMenu
    
    set menuItems {
	doFile doSelection programTemplate continueCommand
	markStataFileAs newComment commentTemplateÉ
	nextCommand prevCommand selectCommand reformatCommand
    }
    foreach i $menuItems {
	hook::${which} requireOpenWindowsHook [list $stataMenu $i] 1
    }
    return
}

# Call this now.
Stta::registerOWH register
rename Stta::registerOWH ""

# ===========================================================================
# 
# ×××× Stata menu support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::menuProc" --
 # 
 # This is the procedure called for all main menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::menuProc {menuName itemName} {
    
    global Sttacmds SttamodeVars mode
    
    variable prefsInMenu
    
    switch $menuName {
	"stataHelp" {
	    switch $itemName {
		"setStataApplication" {Stta::setApplication "Stata"}
		"stataModeHelp"       {package::helpWindow "Stta"}
		default               {Stta::$itemName}
	    }
	}
	"stataModeOptions" {
	    set prefName $itemName
	    regsub {semiDelimiter} $itemName {/;<U<BsemiDelimiter} itemName
	    if {[getModifiers] && ($prefName ne "semiDelimiter")} {
		# Can't use this because of the key binding.
		set helpText [help::prefString $prefName "Stta"]
		if {$SttamodeVars($prefName)} {
		    set end "on"
		} else {
		    set end "off"
		}
		if {($end eq "on")} {
		    regsub {^.*\|\|} $helpText {} helpText
		} else {
		    regsub {\|\|.*$} $helpText {} helpText
		}
		set msg "The '$prefName' preference for Stta mode is currently $end."
		dialog::alert "${helpText}."
	    } elseif {[lcontains prefsInMenu $itemName]} {
		set SttamodeVars($prefName) [expr {$SttamodeVars($prefName) ? 0 : 1}]
		if {($mode eq "Stta")} {
		    synchroniseModeVar $prefName $SttamodeVars($prefName)
		} else {
		    prefs::modified SttamodeVars($prefName)
		}
		if {[regexp {Help} $prefName]} {
		    Stta::rebuildMenu "stataHelp"
		}
		Stta::postBuildMenu
		if {$SttamodeVars($prefName)} {
		    set end "on"
		} else {
		    set end "off"
		}
		set msg "The '$prefName' preference is now $end."
	    } else {
		set msg "Don't know what to do with '$itemName'."
	    }
	    if {[info exists msg]} {
		status::msg $msg
	    }
	}
	"stataKeywords" {
	    if {($itemName eq "listKeywords")} {
		set p "Current Stata mode keywordsÉ"
		set keywords [listpick -l -p $p $Sttacmds]
		foreach keyword $keywords {
		    Stta::checkKeywords $keyword
		}
	    } elseif {($itemName eq "addNewCommands") || ($itemName eq "addNewOptions")} {
		set itemName [string trimleft $itemName "addNew"]
		if {($itemName eq "Commands") && [llength [winNames]] && ([askyesno \
		  "Would you like to add all of the 'extra' commands from this window\
		  to the 'Add Commands' preference?"] eq "yes")} {
		    Stta::addWindowCommands
		} else {
		    Stta::addKeywords $itemName
		}
	    } else {
		Stta::$itemName
	    }
	    return
	}
	"markStataFileAs" {
	    switch $itemName {
		"source"    {Stta::MarkFile ".do"}
		"output"    {Stta::MarkFile ".out"}
		"codebook"  {Stta::MarkFile ".codebook"}
	    }
	}
	default {
	    switch $itemName {
		"stataHomePage" {url::execute $SttamodeVars(stataHomePage)}
		"switchToStata" {app::launchFore $SttamodeVars(stataSig)}
		"programTemplate" {
		    set end [lindex [function::getLimits [getPos] 1] 1]
		    if {($end ne "") && [pos::compare $end > [getPos]]} {
			goto $end
		    }
		    if {$SttamodeVars(semiDelimiter)} {
			set eol " ;\r"
		    } else {
			set eol "\r"
		    }
		    set    pt "program define ¥progName¥${eol}\tversion 6.0${eol}\tif \"`1'\""
		    append pt " == \"?\" {\r\t\tglobal S_1 \"¥variable names¥\"${eol}\t\t"
		    append pt "exit${eol}\t}${eol}\t¥¥\r\t* (each result below must correspond"
		    append pt " to a variable in S_1)${eol}\tpost `1' ¥results¥${eol}end${eol}"
		    elec::Insertion $pt
		}
		"newComment"      {comment::newComment 0}
		"commentTemplate" {comment::commentTemplate}
		"nextCommand"     {function::next}
		"prevCommand"     {function::prev}
		"selectCommand"   {function::select}
		"reformatCommand" {function::reformat}
		default           {Stta::$itemName}
	    }
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::betaMessage" --
 # 
 # Give a beta message for untested features / menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::betaMessage {{item ""}} {
    
    if {![string length $item]} {
	if {[catch {info level -1} item]} {
	    set item "this item"
	}
    }
    error "Cancelled -- '$item' has not been implemented yet."
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::setApplication" --
 # 
 # Prompt the user to locate the local Stata application.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::setApplication {{app "Stata"}} {
    
    global mode SttamodeVars
    
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    
    set newSig ""
    set newSig [dialog::askFindApp $capApp $SttamodeVars(${lowApp}Sig)]
    
    if {($newSig ne "")} {
	mode::setVar Stta ${lowApp}Sig $newSig
	status::msg "The $capApp signature has been changed to '$newSig'."
	return
    } else {
	error "cancel"
    }
}

# ===========================================================================
# 
# ×××× Keywords ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::addWindowCommands" --
 # 
 # Add all of the "extra" commands which appear in entries in this window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::addWindowCommands {} {
    
    global Sttacmds SttamodeVars
    
    if {![llength [winNames]]} {
	status::msg "Cancelled -- no current window!"
	return
    }
    
    status::msg "Scanning [win::CurrentTail] for all commandsÉ"
    
    set pos [minPos]
    set pat {^([a-zA-Z0-9]+[a-zA-Z0-9])+[\t ]}
    while {![catch {search -s -f 1 -r 1 $pat $pos} match]} {
	set pos [nextLineStart [lindex $match 1]]
	set commandLine [getText [lindex $match 0] [lindex $match 1]]
	regexp $pat $commandLine match aCommand
	if {![lcontains Sttacmds $aCommand]} {
	    append SttamodeVars(addCommands) " $aCommand"
	}
    }
    set SttamodeVars(addCommands) [lsort -unique $SttamodeVars(addCommands)]
    prefs::modified SttamodeVars(addCommands)
    if {[llength $SttamodeVars(addCommands)]} {
	Stta::colorizeStta
	listpick -p "The 'Add Commands' preference includes:" \
	  $SttamodeVars(addCommands)
	status::msg "Use the 'Mode Prefs > Preferences' menu item to edit keyword lists."
    } else {
	status::msg "No 'extra' commands from this window were found."
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::addKeywords" --
 # 
 # Prompt the user to add keywords for a given category.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::addKeywords {{category} {keywords ""}} {
    
    global SttamodeVars
    
    if {($keywords eq "")} {
	set keywords [prompt "Enter new Stata $category:" ""]
    }
    
    # Check to see if the keyword is already defined.
    foreach keyword $keywords {
	set checkStatus [Stta::checkKeywords $keyword 1 0]
	if {($checkStatus ne 0)} {
	    alertnote "Sorry, '$keyword' is already defined\
	      in the $checkStatus list."
	    error "cancel"
	}
    }
    # Keywords are all new, so add them to the appropriate mode preference.
    append SttamodeVars(add$category) " $keywords"
    set SttamodeVars(add$category) [lsort $SttamodeVars(add$category)]
    prefs::modified SttamodeVars(add$category)
    Stta::colorizeStta
    status::msg "'$keywords' added to $category preference."
    return
}

proc Stta::checkKeywords {{newKeywordList ""} {quietly 0} {noPrefs 0}} {
    
    global SttamodeVars SttaUserCommands SttaUserOptions
    
    variable keywordLists
    
    set type 0
    if {($newKeywordList eq "")} {
	set quietly 0
	set newKeywordList [prompt "Enter Stata mode keywords to be checked:" ""]
    }
    # Check to see if the new keyword(s) is already defined.
    foreach newKeyword $newKeywordList {
	if {([lcontains keywordLists(commands) $newKeyword] != "-1")} {
	    set type "default commands"
	} elseif {([lcontains SttaUserCommands $newKeyword] != "-1")} {
	    set type "\$SttaUserCommands"
	} elseif {([lcontains keywordLists(prefixes) $newKeyword] != "-1")} {
	    set type "default prefixes"
	} elseif {([lcontains keywordLists(parameters) $newKeyword] != "-1")} {
	    set type "default parameters"
	} elseif {([lcontains keywordLists(functions) $newKeyword] != "-1")} {
	    set type "default functions"
	} elseif {([lcontains keywordLists(options) $newKeyword] != "-1")} {
	    set type "default options"
	} elseif {([lcontains SttaUserOptions $newKeyword] != "-1")} {
	    set type "\$SttaUserOptions"
	} elseif {([lcontains keywordLists(modifiers) $newKeyword] != "-1")} {
	    set type "default modifiers"
	} elseif {([lcontains keywordLists(macros) $newKeyword] != "-1")} {
	    set type "default macros"
	} elseif {([lcontains keywordLists(dated) $newKeyword] != "-1")} {
	    set type "default dated commands"
	} elseif {(!$noPrefs && \
	  [lcontains SttamodeVars(addCommands) $newKeyword] != "-1")} {
	    set type "Add Commands preference"
	} elseif {(!$noPrefs && \
	  [lcontains SttamodeVars(addOptions) $newKeyword] != "-1")} {
	    set type "Add Options preference"
	}
	if {$quietly} {
	    # When this is called from other code, it should only contain
	    # one keyword to be checked, and we'll return it's type.
	    return "$type"
	} elseif {!$quietly && ($type eq 0)} {
	    alertnote "'$newKeyword' is not currently defined\
	      as a Stta mode keyword."
	} elseif {($type ne 0)} {
	    # This will work for any other value for "quietly", such as 2
	    alertnote "'$newKeyword' is currently defined as a keyword\
	      in the '$type' list."
	}
	set type 0
    }
    return
}

# ===========================================================================
# 
# ×××× Processing ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::doFile" --
 # 
 # Send entire file to Stata for processing, adding carriage return at end of
 # file if necessary.  Note that unlike Stata's do-file editor, the name of
 # the actual file appears in Stata's output window!
 # 
 # Optional "f" argument allows this to be called by other code, or to be
 # sent via a Tcl shell window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::doFile {{f ""} {app "Stata"}} {
    
    global SttamodeVars
    
    if {($f ne "")} {
	file::openAny $f
    }
    set f [win::Current]
    
    set dirtyWindow [winDirty]
    set dontSave 0
    if {$dirtyWindow && [askyesno \
      "Do you want to save the file before sending it to Stata?"]} {
	save
    } else {
	set dontSave 1
    }
    if {!$dontSave && ([lookAt [pos::math [maxPos] - 1]] ne "\r")} {
	set pos [getPos]
	goto [maxPos]
	insertText "\r"
	goto $pos
	alertnote "Carriage return added to end of file."
	save
    }
    
    app::launchBack '$SttamodeVars(stataSig)'
    sendOpenEvent noReply '$SttamodeVars(stataSig)' $f
    switchTo '$SttamodeVars(stataSig)'
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::doSelection" --
 # 
 # Procedure to implement transfer of selected lines to Stata for processing.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::doSelection {{selection ""} {app "Stata"}} {
    
    global SttamodeVars
    
    if {($selection eq "")} {
	if {![isSelection]} {
	    status::msg "No selection -- cancelled."
	    return
	} else {
	    set selection [getSelect]
	}
    }
    if {![regexp -- {[\r\n]} $selection]} {
	append selection "\r"
    }
    set tempDir [temp::directory Stata]
    set newFile [file join $tempDir temp-Stata.do]
    file::writeAll $newFile $selection 1
    
    app::launchBack '$SttamodeVars(stataSig)'
    sendOpenEvent noReply '$SttamodeVars(stataSig)' $newFile
    switchTo '$SttamodeVars(stataSig)'
    return
}

proc Stta::quitHook {} {
    temp::cleanup Stata
    return
}

# ===========================================================================
# 
# ×××× --------------------- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  vers#  reason
# -------- --- ------ -----------
# 01/28/20 cbu 1.0.1  First created Stata mode, based upon other modes found 
#                       in Alpha's distribution.  Commands are based on 
#                       release version 3.1 of Stata.
# 03/02/20 cbu 1.0.2  Minor modifications to comment handling.
# 03/20/00 cbu 1.0.3  Minor update of keywords dictionaries. 
#                     Renamed mode Stta, from stta 
# 04/01/00 cbu 1.0.4  Added new preferences to allow the user to enter 
#                       additional commands and options.  
#                     Reduced the number of different user-specified colors.
#                     Added "Stta::updateColors" to avoid need for a restart.
# 04/08/00 cbu 1.0.5  Unset obsolete preferences from earlier versions.
#                     Modified "Stta::electricSemi", added key-bindings for
#                       "Continue Comment", and "Electric Return Over-ride".
#                     Renamed "Stta::updateColors" to "Stta::updatePreferences".
# 04/16/00 cbu 1.1    Renamed to stataMode.tcl
#                     Added "Stta::MarkFile" and "Stta::parseFuncs".
#                     Added command double-click for on-line help.
# 06/20/00 cbu 1.2    "Mark File" now recognizes headings as well as commands.
#                     "Mark File" recognizes source, output, or codebook files.
#                     Completions, Completions Tutorial added.
#                     "Reload Completions", referenced by "Update Preferences".
#                     Better support for user defined keywords.
#                     Removed "Continue Comment", now global in Alpha 7.4.
#                     <shift, control>-<command> double-click syntax info.
#          lps        <option>-<command> double-click Stata app .hlp help.
#          lps        Added Phil Schumm's Stata Menu.
#          lps        Added "Continue Command" key binding and proc.
#                     Added "localHelpOnly" variable for command double-click.
# 08/23/00 cbu 1.2.1  "Mark File As" added to Stata menu.  (Required adding
#                       an optional argument to Stta::MarkFile, reworking
#                       of the stata menu build procs.)
#                     "Help" added to Stata menu.  (Required splitting off
#                       "wwwCommandHelp" and "localCommandHelp" from
#                       command double-click, giving them optional arguments.
#                     Gave "doFile" an optional argument, so that it could
#                       be called from other code, or a shell.
#                     DblClick now looks for macro definitions in current file.
#                     "localHelpOnly" preference changed to "localHelp"
#                     Changing "localHelp" changes Stata Help menu bindings.
#                     Small fixes to SttaCompletions.tcl.
#                     Removed "codebookSuffix" preference, now that the 
#                       menu has "Mark File AsÉ".
#                     Added "stataSig" preference to allow user to find
#                       local application if necessary.
#                     Added "Stta::sig" which returns Stata signature.
# 08/28/00 cbu 1.2.2  Added some of the flag preferences to "Stata Help" menu.
#                     Added "Stta::flagFlip" to change bullets in menu.
#                     Added a "noHelpKey" preference, which switches the
#                       "help" key binding to F8.
#                     Added "addNewCommands/Options" to "Stata Help" menu.
#                     Added "setStataApplication to "Stata Help" menu.
# 11/05/00 cbu 1.3    Added "next/prevCommand", "selectCommand", and
#                       "copyCommand" procs to menu.
#                     Added "continueComment" to menu.
#                     Added "Stta::indentLine".
#                     Added "reformatCommand" to menu.
#                     Modified "Stta::continueCommand" to take advantage of
#                       automatic indentation using Stta::indentLine.
#                     Modified Stta::programTemplate to take semi delimiter
#                       into account, and to not insert within a command.
#                     "Stta::reloadCompletions" is now obsolete.
#                     "Stta::updatePreferences" is now obsolete.
#                     "Stta::colorizeStta" now takes care of setting all 
#                       keyword lists, including Sttacmds.
#                     Cleaned up completion procs.  This file never has to be
#                       reloaded.  (Similar cleaning up for "Stta::DblClick").
# 11/16/00 cbu 2.0    New url prefs handling requires 7.4b21
#                     Added "Home Page" pref, menu item.
#                     Removed  hook::register requireOpenWindowsHook from
#                       mode declaration, put it after menu build.
# 12/19/00 cbu 2.1    The menu proc "Add Commands" now includes an option
#                       to grab all of the "extra" command from the current
#                       window, using Stta::addWindowCommands.
#                     Added "Keywords" submenu, "List Keywords" menu item.
#                     Big cleanup of ::sig, ::setApplication, processing ...
# 01/25/01 cbu 2.1.1  Bug fix for Stta::doSelection.
#                     Bug fix for comment characters.
#                     Better codebook marking.
#                     Added Stta::commandHelp for help file hyperlinks.
# 09/26/01 cbu 2.2    Big cleanup, enabled by new 'functions.tcl' procs.
# 10/31/01 cbu 2.2.1  Minor bug fixes.
# 05/30/03 vmd 2.2.2  Minor changes in light of AlphaTcl SystemCode update
#                       for electric preferences and handling.
# 10/04/05 cbu 2.2.3  Added some keywords.
#                     "$" can be colorized as a "magic" character.
#                     [Stta::doSelection] ensures text ends with CR.
#                     Corrected "l'vr" electric completion.
#                     Additional recent minor changes have included:
#                     * "wordBreakPreface" preference removed
#                     * new [help::prefString] procedure
#                     * removed indent_amounts array
#                     * use \w in wordBreak definitions
#                     * converted wordWrap to variable pref,
#                     * [status::errorMsg] -> [error "Cancelled ..."]
#                     * package "description" arguments, plus "help"
#                     * add optional window arguments to <mode>::MarkFile
#                     * removed some odd uses of 'set mode'
#                     * Renamed 'word wrap' to 'line wrap'
#                     * [Stta::correctIndentation] accepts 'args' (-w <win>)
# 10/18/05 cbu 2.3    Keywords lists are defined in Stta namespace variables.
#                     Minor updates to keyword lists.
#                     Canonical Tcl formatting changes.
#                     New "markHeadingsOnly" preference.
#                     Using [prefs::dialogs::setPaneLists] for preferences.
# 

# ===========================================================================
# 
# .