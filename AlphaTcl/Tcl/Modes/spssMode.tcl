## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # Statistical Modes - an extension package for Alpha
 #
 # FILE: "spssMode.tcl"
 #                                          created: 01/15/2000 {07:15:32 pm}
 #                                      last update: 05/23/2006 {10:46:12 AM}
 # Description: 
 #                               
 # For SPSS syntax files.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 2000-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ===========================================================================
#
# ×××× Initialization of SPSS mode ×××× #
# 

alpha::mode SPSS 2.3 "spssMode.tcl" {
    *.sps *.spss *.spp
} {
    spssMenu
} {
    # Script to execute at Alpha startup
    addMenu spssMenu "SPSS" SPSS
    set unixMode(spss) {SPSS}
    set modeCreator(SPSS) {SPSS}
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Supports the editing of SPSS and PSPP statistical batch files
} help {
    file "Statistical Modes Help"
}

hook::register quitHook SPSS::quitHook

proc spssMode.tcl {} {}

namespace eval SPSS {
    
    # Comment Character variables for Comment Line/Paragraph/Box menu items.
    variable commentCharacters
    array set commentCharacters [list \
      "General"         [list "*"] \
      "Paragraph"       [list "** " " **" " * "] \
      "Box"             [list "*" 1 "*" 1 "*" 3] \
      ]
    
    # Set the list of flag preferences which can be changed in the menu.
    variable prefsInMenu [list \
      "noHelpKey" \
      "fullIndent" \
      "(-)" \
      "autoMark" \
      "markHeadingsOnly" \
      ]
    
    # Used in [SPSS::colorizeSPSS].
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
    # SPSS does a lousy job of naming things, or at least is more than
    # willing to give a keyword (as in SPSS keyword) the same name as a
    # function, statement, subcommand or command.  There's little point in
    # trying to distinguish amongst all of this with different colors,
    # because it just won't work.  Instead, I'm just putting them all in one
    # list, calling them all "commands" and reminiscing about the days when
    # S-Plus was my stats package of choice.  The nomenclature of SPSS is
    # only one of its several limitations.
    #
    
    variable keywordLists
    
    # =======================================================================
    #
    # SPSS Commands
    #
    set keywordLists(commands) [list \
      a absolute add adevice adjred afreq after aggregate aic ainds align \
      alpha alsal analysis anova append approximate ar area ascii asresid \
      association automatic autorecode avalue average averf avonly \
      awymmetic backward badcorr barchart bart base basis baverage bcon \
      bcov begin beuclid binomial blank blanks blksize blwmn bmdp bmpd \
      boick bootstrap both boundary box boxm brau break breakdown brief \
      brkspace bseuclid bshape bstep btukey buffno calculate call case \
      casenum cases categorical cc cdfnorm cellinfo cells center centroid \
      cfvar cha chalign charend chdpace chebychev chicdf chisq chol \
      choropleth ci cinterval ckder clabels classify classplot clear clnr \
      cluster cmax cmin cnames cnlr cochran code colconf collect collin \
      collinearity colspace column columnwise combined comm comment compare \
      complete compositional compressed compression compute concat condense \
      condensed condition conditional config constrained content contents \
      continued contour contrast convert cook copy cor corff corr \
      correlations cosine count cov covariances covariates cpi criteria \
      crossbreak crosstabs crshtol cssq csum ctime.days ctime.hours \
      ctime.minures cufreq cupct curpoints cusum cutoff cweight d data \
      date.dmy date.mdy date.moyr date.qur date.wkyr date.yrday default \
      define delta dendrogram density dependent derivatives desc descending \
      descending descriptives design det dev deviation dfbeta dfe dfreq \
      diag diagonal dice dictionary difference digits dimenrdimens \
      directions discrim discriminant disper display distance divide \
      document documents doend dollar double down draw dresid drop dummy \
      duncan duplicate durbin dvalue ebcdid econverge edit effects efsize \
      eigen eject else enclose end enter eof eps equamax error errors estim \
      eta euclid eval every exact examine exclude execute expected \
      experimental export external extraction f facilities factor fgtmlr \
      fieldnames file files fin fin finish first first fixed flip flt \
      fnames footnote for formats fortran forward fout fpair fprecision \
      freq frequencies friedman from frspace fscore fstep ftolerance full \
      functions gamma gcmdfile gcov gdata gdevice gemscal get gg ginv gls \
      gmemory graph great gresid grouped groups groups groupwise gsch \
      guttman hamann handle harmonic hazard hbar head header helmert help \
      hf hicicle hierarchical higher highest hiloglinear histogram history \
      hold homogeneity horizontal host hotelling hsize hypoth id ident if \
      image import in include increment indicator individual indscal info \
      initial inline input input intermed interval intervals into inv istep \
      iter iterate jaccard jdate joint journal k-s k-w k1 k2 kaiser kappa \
      keep kendall key keyed kmo kroneker kurtosis label labels lag lambda \
      last lcon least leave left length let level lever lftolerance limit \
      line linearity list listing listwise log logistic logit loglinear \
      logsurv loop loss lower lowest lpad lpi lresid lsd lstolerance ltrim \
      m-wm macros magic mahal make manova manual map match matrix maxorders \
      maxsteps mconvert mde mean means merge mestimates method missing \
      mixed mode model more moses mprint mrgroup msave mssq msum mult \
      multiple multiply multipunch multiv multivariate muplus mwithin \
      mxerrs mxloops mxwarns n n_matrix n_scalar n_vector name names naname \
      nanames natres navallabs ncol ncomp negative nested new newnames \
      newnames newpage nftolerance ngt nin nlr nlr nmiss no nobox nocatlabs \
      nodiagonal noend noexpand noindex noinitial nokaiser nolabels nolist \
      nominal none nonmissing nonpar noorigin noprint normal normplot \
      normprob norotate nosig nostep notable noulb noupdate novalues nowarn \
      npar nrow ntiles nu null nulline number numbered numeric numiss \
      nvalid oblimin occurs ochaiai of off offexpand offset omeans onepage \
      onetail oneway oneway oneway onexpand optimal options optolerance \
      ordered ordinal origin orthonorm osiris other out outfile outliers \
      output outs overlay overview p pa1 pa2 paf page paired pairs pairwise \
      parall parallel parameters partial partialplot partition pattern pc \
      pcomps pcon pct pearson percent percentiles pgroup pgt ph2 phi pie \
      pin pin plain plot plt pmeans point polynomial pool pooled positional \
      pout power pred preserve presorted previous print printback priors \
      prism probit procedure procedures proportion prox proximities ptile \
      pyramid q quartiles quartimax quick quick quick quote r radial range \
      ranges rank ration raw rcon rconverge recode rectangular reduncancy \
      reformat reg regression regwgt release reliability remove rename \
      repeat repeating replace report reread rescale reshape resid residual \
      residuals response responses restore results reverse rfraction \
      rfraction right rindex risk rlabels rmax rmin rmp rnames rnkorder \
      rotate rotation row rowconf rows rpad rr rssq rsum rt rtrim runs \
      sample sas saslib savage save scale scan scatterplot schedule scheffe \
      scompression scratch scss sd sdresid seed sekurt select semean \
      separate serdiag serial ses seskew set seuclid shape show sig sign \
      signif significance simple since single singledf size skewness skip \
      sm snames snk solve sort space space spearman special split spread \
      spred spss sresid sscon sscp sstype stacked stan standardize starts \
      statistics status stddev step stepdown steplimit stepwise stimwght \
      stressmin strictparallel string strings substr substring subtitle \
      subtract sum summary sumspace survival sval svd sweep symbols \
      symmetric sysmix t t-test table tables tail tape tb1 tb2 tbfonts tcdf \
      tcov temporary terminal test tests then ties tiestore time time.days \
      time.hms title tokens tolerance total transformations translate \
      tspace tukey twotail type type uc uls unclassified uncompressed \
      unconditional undefined underscore uniform unique univ univariate \
      univf unnumbered unquote unselected up upcase update validn value \
      values var variable variables variance varimax vars vector vertical \
      vicile view vin vs vsize w-w ward warn waverage weight width wilcoxon \
      wild workfile write wsdesign wsfactors xdate.date xdate.hour \
      xdate.jday xdate.mday xdate.minute xdate.month xdate.quarter \
      xdate.second xdate.tday xdate.time xdate.week xdate.wkday xdate.year \
      xmdend xprod xsave xsort xtx y yes yrmoda z z zcorr zpp zpred zresid \
      ]
    
    # =======================================================================
    #
    # SPSS Functions
    #
    set keywordLists(functions) [list \
      abs arsin artan cos exp lg10 ln mod rnd sin sqrt trunc \
      ]
    
    # =======================================================================
    #
    # SPSS Operators
    #
    set keywordLists(operators) [list \
      .por .sav .sps all and by eq ge gt into le lt ne not or thru to with \
      xls \
      ]
}

# ===========================================================================
#
# ×××× Setting SPSS mode variables ×××× #
#

# Removing obsolete preferences from earlier versions.

set oldvars {
    addArguments addSymbols argumentColor don'tRemindMe electricTab
    functionColor keywordColor spssHelp
}

foreach oldvar $oldvars {prefs::removeObsolete SPSSmodeVars($oldvar)}

unset oldvar oldvars

# ===========================================================================
#
# Standard preferences recognized by various Alpha procs
#

newPref var  fillColumn        {75}                SPSS
newPref var  leftFillColumn    {0}                 SPSS
newPref var  prefixString      {* }                SPSS
newPref var  wordBreak         {[-\w\.]+}   SPSS
newPref var  lineWrap          {0}                 SPSS
newPref var  commentsContinuation 1                SPSS "" \
  [list "only at line start" "spaces allowed" "anywhere"] index
newPref flag electricBraces    1 SPSS
# To automatically indent the new line produced by pressing Return, turn this
# item on.  The indentation amount is determined by the context||To have the
# Return key produce a new line without indentation, turn this item off
newPref flag indentOnReturn    1 SPSS

# ===========================================================================
#
# Flag preferences
#

# ===========================================================================
#
# Preferences to allow user to include additional commands, arguments, and
# symbols through the Mode Preferences dialog.
# 

# To automatically mark files when they are opened, turn this item on||To
# disable the automatic marking of files when they are opened, turn this
# item off
newPref flag autoMark           {0}     SPSS    {SPSS::rebuildMenu spssMenu}
# To indent all continued commands (indicated by the lack of a period at the
# end of a line) by the full indentation amount rather than half, turn this
# item on|| To indent all continued commands (indicated by the lack of a
# period at the end of a line) by half of the indentation amount rather than
# the full, turn this item off
newPref flag fullIndent         {1}     SPSS    {SPSS::rebuildMenu spssMenu}
# To primarily use a www site for help rather than the local SPSS or PSPP
# application, turn this item on|| To primarily use the local SPSS or PSPP
# application for help rather than on a www site turn this item off
newPref flag localHelp          {0}     SPSS    {SPSS::rebuildMenu spssHelp}
# To only mark "headings" in windows (those preceded by ***), turn this item
# on||To mark both commands and headings in windows, turn this item off
newPref flag markHeadingsOnly   {0}     SPSS    {SPSS::postBuildMenu}
# If your keyboard does not have a "Help" key, turn this item on.  This will
# change some of the menu's key bindings|| If your keyboard has a "Help"
# key, turn this item off.  This will change some of the menu's key bindings
newPref flag noHelpKey          {0}     SPSS    {SPSS::rebuildMenu spssHelp}

# This isn't used yet.
prefs::deregister "localHelp" "SPSS"

# ===========================================================================
#
# Variable preferences
# 

# Enter additional SPSS keywords to be colorized.  These will also be
# included in electric completions.
newPref var addCommands         {}      SPSS    {SPSS::colorizeSPSS}
# Select the statistical application to be used.
newPref var application         {SPSS}  SPSS    {SPSS::rebuildMenu spssMenu} [list PSPP SPSS]
# The "PSPP Home Page" menu item will send this url to your browser.
newPref url psppHomePage        {http://www.gnu.org/software/pspp/}     SPSS
# Click on "Set" to find the local PSPP application.
newPref sig psppSig             {}      SPSS
# Command double-clicking on an SPSS keyword will send it to this url
# for a help reference page.
newPref url helpUrl {http://www.gnu.org/software/pspp/manual/pspp_200.html} SPSS
# The "SPSS Home Page" menu item will send this url to your browser.
newPref url spssHomePage        {http://www.spss.com/}  SPSS
# Click on "Set" to find the local SPSS application.
newPref sig spssSig             {SPSS}  SPSS

# ===========================================================================
#
# Color preferences
#

# See the Statistical Modes Help file for an explanation of these different
# categories, and lists of keywords.
newPref color commandColor      {blue}   SPSS    {SPSS::colorizeSPSS}
newPref color commentColor      {red}    SPSS    {stringColorProc}
newPref color operatorColor     {blue}   SPSS    {SPSS::colorizeSPSS}
newPref color stringColor       {green}  SPSS    {stringColorProc}
# The color of symbols such as +, -, /,  etc.
newPref color symbolColor      {magenta} SPSS    {SPSS::colorizeSPSS}

# ===========================================================================
# 
# Categories of all SPSS preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# Editing
prefs::dialogs::setPaneLists "SPSS" "Editing" [list \
  "autoMark" \
  "electricBraces" \
  "fillColumn" \
  "fullIndent" \
  "indentOnReturn" \
  "leftFillColumn" \
  "lineWrap" \
  "markHeadingsOnly" \
  "wordBreak" \
  ]

# Comments
prefs::dialogs::setPaneLists "SPSS" "Comments" [list \
  "commentColor" \
  "commentsContinuation" \
  "prefixString" \
  ]

# Colors
prefs::dialogs::setPaneLists "SPSS" "Colors" [list \
  "addCommands" \
  "commandColor" \
  "operatorColor" \
  "stringColor" \
  "symbolColor" \
  ]

# Help
prefs::dialogs::setPaneLists "SPSS" "SPSS Help" [list \
  "application" \
  "helpUrl" \
  "localHelp" \
  "noHelpKey" \
  "psppHomePage" \
  "psppSig" \
  "psppSig" \
  "spssHomePage" \
  "spssSig" \
  "spssSig" \
  ]

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::colorizeSPSS" --
 # 
 # Set all keyword lists, and colorize.
 # 
 # Could also be called in a <mode>Prefs.tcl file
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::colorizeSPSS {{pref ""}} {
    
    global SPSSmodeVars SPSScmds SPSSUserCommands
    
    variable firstColorCall
    variable keywordLists
    
    set SPSScmds [list]
    # Create the list of all keywords for completions.  SPSS keywords are not
    # case-sensitive.  To allow for different user styles, we'll include
    # lower case commands as well as ALL CAPS.  The "lowerKeywords" list 
    # will be used by the "SPSS Mode Keywords > List Keywords" command.
    set keywordLists(lowerKeywords) [list]
    # SPSS Commands
    foreach keyword $keywordLists(commands) {
	lappend SPSScmds $keyword [string toupper $keyword]
	lappend keywordLists(lowerKeywords) [string tolower $keyword]
    }
    foreach keyword $SPSSmodeVars(addCommands) {
	lappend SPSScmds $keyword [string toupper $keyword]
	lappend keywordLists(lowerKeywords) [string tolower $keyword]
    }
    if {[info exists SPSSUserCommands]} {
	foreach keyword $SPSSUserCommands {
	    lappend SPSScmds $keyword [string toupper $keyword]
	    lappend keywordLists(lowerKeywords) [string tolower $keyword]
	}
    }
    # SPSS Functions
    foreach keyword $keywordLists(functions) {
	lappend SPSScmds $keyword [string toupper $keyword]
    }
    # "SPSScmds"
    set SPSScmds [lsort -dictionary -unique $SPSScmds]
    
    # Now we colorize keywords.  If this is the first call, we don't include 
    # the "-a" flag.
    if {$firstColorCall} {
	regModeKeywords SPSS {}
	set firstColorCall 0
    }
    
    # Color comments and strings
    regModeKeywords -a -e {*} -b {/*} {*/} -c $SPSSmodeVars(commentColor) \
      -s $SPSSmodeVars(stringColor) SPSS {}
    
    # Color Commands
    regModeKeywords -a -k $SPSSmodeVars(commandColor) SPSS $SPSScmds
    
    # Color Operators
    regModeKeywords -a -k $SPSSmodeVars(operatorColor) \
      SPSS $keywordLists(operators)
    
    # Color Symbols
    regModeKeywords -a -i "+" -i "-" -i "\\" -i "|" \
      -I $SPSSmodeVars(symbolColor) SPSS {}
    
    if {($pref ne "")} {
	refresh
    }
    return
}

# Call this now.

SPSS::colorizeSPSS

# ===========================================================================
#
# ×××× Key Bindings, Electrics ×××× #
#

Bind '\)'           {SPSS::electricRight "\)"} SPSS

# For those that would rather use arrow keys to navigate.  Up and down
# arrow keys will advance to next/prev command, right and left will also
# set the cursor to the top of the window.

Bind    up  <sz>    {SPSS::searchFunc 0 0 0} SPSS
Bind  left  <sz>    {SPSS::searchFunc 0 0 1} SPSS
Bind  down  <sz>    {SPSS::searchFunc 1 0 0} SPSS
Bind right  <sz>    {SPSS::searchFunc 1 0 1} SPSS

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::carriageReturn" --
 # 
 # Inserts a carriage return, and indents properly.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::carriageReturn {} {
    
    global SPSSmodeVars
    
    if {[isSelection]} {
	deleteSelection
    }
    set pos1 [lineStart [getPos]]
    set pos2 [getPos]
    if {[regexp {^([\t ])*(\}|\))} [getText $pos1 $pos2]]} {
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
 # "SPSS::electricLeft" --
 # "SPSS::electricRight" --
 # 
 # Adapted from "tclMode.tcl"
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::electricLeft {} {
    
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
	    elec::Insertion "\} $word \{\r\t••\r\}\r••"
	}
	"elseif" {
	    deleteText [lindex $result 0] $pos
	    elec::Insertion "\} $word \{••\} \{\r\t••\r\}\r••"
	}
    }
    return
}

proc SPSS::electricRight {{char "\}"}} {
    
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

proc SPSS::searchFunc {direction args} {
    
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

# ===========================================================================
#
# ×××× Indentation ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::correctIndentation" --
 # 
 # [SPSS::correctIndentation] is necessary for Smart Paste, and returns the
 # correct level of indentation for the current line.
 # 
 # We have two level of indentation in SPSS, for the continuation of
 # commands, in which case we simply indent to the amount of the SPSS mode
 # variable indentationAmount, and for nested braces.
 # 
 # In [SPSS::correctIndentation] we grab the previous non-commented line,
 # remove all of the characters besides braces and quotes, and then convert
 # it all to a list to be evaluated.  Braces contained within quotes, as well
 # as literal characters, should all be ignored and the remaining braces are
 # used to determine the correct level of nesting.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::correctIndentation {args} {
    
    global SPSSmodeVars indentationAmount
    
    win::parseArgs w pos {next ""}
    
    if {([win::getMode $w] eq "SPSS")} {
	set continueIndent [expr {$SPSSmodeVars(fullIndent) + 1}]
    } else {
	set continueIndent 2
    }
    
    set posBeg    [pos::lineStart -w $w $pos]
    # Get information about this line, previous line ...
    set thisLine  [SPSS::getCommandLine -w $w $posBeg 1 1]
    set prevLine1 [SPSS::getCommandLine -w $w \
      [pos::math -w $w $posBeg - 1] 0 1]
    set prevLine2 [SPSS::getCommandLine -w $w \
      [pos::math -w $w [lindex $prevLine1 0] - 1] 0 1]
    set lwhite    [lindex $prevLine1 1]
    # If we have a previous line ...
    if {[pos::compare -w $w [lindex $prevLine1 0] != $posBeg]} {
	set pL1 [string trim [lindex $prevLine1 2]]
	# Indent if the last line did not terminate the command.
	if {![regexp {\.[\t ]*$} $pL1]} {
	    incr lwhite [expr {$continueIndent * $indentationAmount/2}]
	}
	# Check to make sure that the previous command was not itself a
	# continuation of the line before it.
	if {[pos::compare -w $w [lindex $prevLine1 0] != [lindex $prevLine2 0]]} {
	    set pL2 [string trim [lindex $prevLine2 2]]
	    if {![regexp {\.[\t ]*$} $pL2]} {
		incr lwhite [expr {-$continueIndent * $indentationAmount/2}]
	    }
	}
	# Find out if there are any unbalanced {,},(,) in the last line.
	regsub -all {[^ \{\}\(\)\"\*\/\\]} $pL1 { } line
	# Remove all literals.
	regsub -all {\\\{|\\\}|\\\(|\\\)|\\\"|\\\*|\\\/} $line { } line
	regsub -all {\\} $line { } line
	# Remove everything surrounded by quotes.
	regsub -all {\"([^\"]+)\"} $line { } line
	regsub -all {\"} $line { } line
	# Remove everything surrounded by bracketed comments.
	regsub -all {/\*[^\*/]+\*/} $line { } line
	# Now turn all braces into 1's and -1's
	regsub -all {\{|\(} $line { 1 }  line
	regsub -all {\}|\)} $line { -1 } line
	# This list should now only contain 1's and -1's.
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
	# line is \) or \}.
	set tL [lindex $thisLine 2]
	if {($next eq "\}") || ($next eq "\)") \
	  || [regexp {^[\t ]*(\}|\))} $tL]} {
	    incr lwhite -$indentationAmount
	}
    }
    # Now we return the level to the calling proc.
    return [expr {$lwhite > 0 ? $lwhite : 0}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::getCommandLine" --
 # 
 # Find the next/prev command line relative to a given position, and return
 # the position in which it starts, its indentation, and the complete text of
 # the command line.  If the search for the next/prev command fails, return
 # an indentation level of 0.
 # 
 # We have the luxury here of ignoring any previous/next commented lines.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::getCommandLine {args} {
    
    win::parseArgs w pos {direction 1} {ignoreComments 1}
    
    if {$ignoreComments} {
	set pat {^[\t ]*[^\t\r\n\*/ ]}
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

# ===========================================================================
# 
# ×××× Command Double Click ×××× #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::DblClick" --
 # 
 # Checks to see if the highlighted word appears in any keyword list, and if
 # so, sends the selected word to the www.SPSS.com help site.
 # 
 # Control-Command double click will insert syntax information in status bar.
 # Shift-Command double click will insert commented syntax information in
 # window.
 # 
 # (The above is not yet implemented: need to enter all of the syntax info.)
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::DblClick {from to shift option control} {
    
    global SPSSmodeVars SPSScmds
    
    variable syntaxMessages
    
    selectText $from $to
    set command [getSelect]
    
    if {![lcontains SPSScmds $command]} {
	status::msg "'$command' is not defined as a SPSS system keyword."
	return
    }
    # Any modifiers pressed?
    if {$control} {
	# CONTROL -- Just put syntax message in status bar window
	if {[info exists syntaxMessages($command)]} {
	    status::msg "$syntaxMessages($command)"
	} else {
	    status::msg "Sorry, no syntax information available for $command"
	}
    } elseif {$shift} {
	# SHIFT --Just insert syntax message as commented text
	if {[info exists syntaxMessages($command)]} {
	    endOfLine
	    insertText "\r"
	    insertText "$syntaxMessages($command)"
	    comment::Line
	} else {
	    status::msg "Sorry, no syntax information available for $command"
	}
    } elseif {$option && !$SPSSmodeVars(localHelp)} {
	# Now we have four possibilities, based on "option" key and the
	# preference for "local Help Only".  (Local Help Only actually
	# switches the "normal" behavior of options versus not.)
	# 
	# OPTION, local help isn't checked -- Send command to local application
	SPSS::localCommandHelp $command
    } elseif {$option && $SPSSmodeVars(localHelp)} {
	# OPTION, but local help is checked -- Send command for on-line help.
	SPSS::wwwCommandHelp $command
    } elseif {$SPSSmodeVars(localHelp)} {
	# No modifiers, local help is checked -- Send command to local app.
	SPSS::localCommandHelp $command
    } else {
	# No modifiers, no local help checked -- Send command for on-line
	# help.  This is the "default" behavior.
	SPSS::wwwCommandHelp $command
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::wwwCommandHelp" --
 # 
 # Send command to defined url, prompting for text if necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::wwwCommandHelp {{command ""}} {
    
    global SPSSmodeVars
    
    # For now, this is the best we can do.
    urlView $SPSSmodeVars(helpUrl)
    
    return
    # Need to use xservs
    global viewUrlsUsing
    if {($viewUrlsUsing eq "Internal text-only viewer")} {
	set where [string tolower [string index $command 0]]
	if {($where ne "")} {
	    if {![catch {search -s -f 1 -r 1 "^${where}\$" [minPos]} match]} {
		goto [lindex $match 0]
		insertToTop
	    }
	}
    }
    return
    
    if {($command eq "")} {
	if {[catch {prompt "On-line SPSS/PSPP help for É" ""} command]} {
	    error "cancel"
	}
    }
    status::msg "'$command' sent to $SPSSmodeVars(helpUrl)"
    urlView $SPSSmodeVars(helpUrl)$command
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::localCommandHelp" --
 # 
 # Send command to local application, prompting for text if necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::localCommandHelp {{command ""} {app ""}} {
    
    # Need to work on this.
    SPSS::betaMessage
    
    global SPSSmodeVars tcl_platform
    
    if {($app eq "")} {
	set app $SPSSmodeVars(application)
    }
    if {($command eq "")} {
	set command [prompt "local $app application help for ... " [getSelect]]
	# set command [statusPrompt "local S-Plus application help for ..." ]
    }
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    # Make sure that the Macintosh application for the signature
	    # actually exists.
	    if {[catch {nameFromAppl $SPSSmodeVars(${lowApp}Sig)}]} {
		alertnote "Looking for the $capApp application ..."
		SPSS::setApplication $lowApp
	    }
	}
	"windows" - "unix" {
	    # Make sure that the Windows application for the signature
	    # exists.  We assume that this will work for unix, too.
	    if {![file exists $SPSSmodeVars(${lowApp}Sig)]} {
		alertnote "Looking for the $capApp application ..."
		SPSS::setApplication $lowApp
	    }
	}
    }
    # Now we look for the actual help file.
    set helpFile "????"
    if {![file exists $helpFile]} {
	beep
	status::msg "Sorry, no help file for '$command' was found."
	error "No help file found for '$command'."
    } else {
	help::openFile $helpFile
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
 # "SPSS::MarkFile" --
 # 
 # This will return the first 35 characters from the first non-commented word
 # that appears in column 0.  All other output files (those not recognized)
 # will take into account the additional left margin elements added by
 # SPSS/PSPP.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::MarkFile {args} {
    
    global SPSSmodeVars
    
    win::parseArgs w {type ""}
    
    status::msg "Marking \"[win::Tail $w]\" É"
    
    set pos [minPos -w $w]
    set count1 0
    set count2 0
    # Figure out what type of file this is -- source, frequency, or output.
    # The variable "type" refers to a call from the SPSS menu.
    # Otherwise we try to figure out the type based on the file's suffix.
    if {($type eq "")} {
	if {([win::Tail $w] eq "* SPSS Mode Example *")} {
	    # Special case for Mode Examples, but only if called from
	    # Marks menu.  (Called from SPSS menu, "type" will over-ride.)
	    set type  ".sps"
	} else {
	    set type [file extension [win::Tail $w]]
	}
    }
    # Set the mark expression.
    if {($type eq ".sps")} {
	# Is this a source file?
	if {!$SPSSmodeVars(markHeadingsOnly)} {
	    set markExpr {^(\*\*\*[ ]|\*\*\*\*[ ])?[a-zA-Z]}
	} else {
	    set markExpr {^\*\*\*\**[\t ][^\r\n\t ]}
	}
    } elseif {($type eq ".freq")} {
	# Is this a frequencies file?  Determining what is truly a variable
	# in SPSS output is not straightforward.  This regexp is a little
	# particular, and might only apply to unix output.
	set markExpr {^.+[\r\n]+[ ]+(Valid )}
	catch {set pos [lindex [search -w $w -s -f 1 -m 0 -i 1 {freq} [minPos -w $w]] 0]}
    } else {
	# Assume that it's output.
	set markExpr {^[ ]+[0-9]+(  )(0  )*(\*\*\*[ ]|\*\*\*\*[ ])?[a-zA-Z]}
    }
    # Now mark the file.
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 $markExpr $pos} match]} {
	if {($type eq ".freq")} {
	    set pos0 [pos::lineStart -w $w [lindex $match 0]]
	    set pos1 [pos::nextLineStart -w $w $pos0]
	    set mark [string trimright [getText -w $w $pos0 $pos1]]
	    regsub {[ ]+.+$} $mark {} mark
	    status::msg "# of variables: [incr count1]"
	} else {
	    set pos0 [lindex $match 0]
	    set pos1 [pos::nextLineStart -w $w $pos0]
	    set mark [string trimright [getText -w $w $pos0 $pos1]]
	    # Get rid of the leading "  [0-9]  " for output files
	    if {($type ne ".sps")} {
		regsub {^[ ]+([0-9]*[0-9]*[0-9]*[0-9])} $mark {} mark
		regsub {^  0} $mark {} mark
	    }
	    # Add a little indentation so that section marks show up better
	    set mark "  [string trimleft $mark " "]"
	    if {[regexp -- {^\s*\*+\s*-+\s*$} $mark]} {
		set mark "-"
	    } elseif {[regsub {  \*\*\*\* } $mark {* } mark]} {
		incr count2
	    } elseif {[regsub {  \*\*\* } $mark {¥ } mark]} {
		incr count2
	    } else {
		incr count1
	    }
	    # Get rid of trailing sem-colons, and truncate if necessary.
	    set mark [markTrim [string trimright $mark ";" ]]
	}
	# If the mark starts with "execute", ignore it.
	while {[lcontains marks $mark]} {
	    append mark " "
	}
	lappend marks $mark
	if {![regexp {^  (execute|EXECUTE)} $mark]} {
	    setNamedMark -w $w $mark $pos0 $pos0 $pos0
	}
	set pos $pos1
    }
    # Report how many marks we created.
    if {($type eq ".freq")} {
	# Sorting the marks if this is a frequencies file.
	status::msg "Sorting marks É"
	sortMarksFile
	set msg "This frequencies file describes $count1 variables."
    } elseif {!$SPSSmodeVars(markHeadingsOnly)} {
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
 # "SPSS::parseFuncs" --
 # 
 # This will return only the SPSS command names.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::parseFuncs {} {
    
    global sortFuncsMenu
    
    if {([file extension [win::CurrentTail]] eq ".sps")} {
	set funcExpr {^(\w+)}
    } elseif {([file tail [win::Current]] eq "* SPSS Mode Example *")} {
	# Special case for Mode Examples folder
	set funcExpr {^(\w+)}
    } else {
	# Assume that it's output.
	set funcExpr {^([ ]+[0-9]+(  )(0  )*)([a-zA-Z]+[a-zA-Z])}
    }
    set pos [minPos]
    set m   [list ]
    while {![catch {search -s -f 1 -r 1 -i 0 -n $funcExpr $pos} match]} {
	if {[regexp -- $funcExpr [eval getText $match] "" "" "" "" word]} {
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
# ×××× SPSS Menu ×××× #
# 

proc spssMenu {} {}

# Tell Alpha what procedures to use to build all menus, submenus.

menu::buildProc spssMenu SPSS::buildMenu     SPSS::postBuildMenu
menu::buildProc spssHelp SPSS::buildHelpMenu
menu::buildProc psppHelp SPSS::buildHelpMenu

# First build the main SPSS menu.

proc SPSS::buildMenu {} {
    
    global spssMenu SPSSmodeVars
    
    variable prefsInMenu
    
    set app [string toupper $SPSSmodeVars(application)]
    if {($app eq "SPSS")} {
	set app "Spss"
    } else {
	set app "Pspp"
    }
    set lowApp [string tolower $app]
    
    set optionItems [concat $prefsInMenu "(-)" "spss" "pspp"]
    set keywordItems [list \
      "listKeywords" "checkKeywordsÉ" "addNewCommandsÉ"]
    set markItems [list "source" "output" "codebook"]
    set menuList [list \
      "${lowApp}HomePage" \
      "switchTo${app}" \
      "/P<U<OprocessFile" \
      "/P<U<O<BprocessSelection" \
      "(-)" \
      [list Menu -n ${lowApp}Help -M SPSS {}] \
      [list Menu -n ${lowApp}ModeOptions  -p SPSS::menuProc -M SPSS $optionItems] \
      [list Menu -n ${lowApp}ModeKeywords -p SPSS::menuProc -M SPSS $keywordItems] \
      [list Menu -n mark${app}FileAs      -p SPSS::menuProc -M SPSS $markItems] \
      "(-)" \
      "/'<E<S<BnewComment" \
      "/'<S<O<BcommentTemplateÉ" \
      "(-" \
      "/N<U<BnextCommand" \
      "/P<U<BprevCommand" \
      "/S<U<BselectCommand" \
      "/I<B<OreformatCommand" \
      ]
    set submenus [list ${lowApp}Help]
    return       [list build $menuList "SPSS::menuProc -M SPSS" $submenus $spssMenu]
}

# Then build the "SPSS Help" submenu.

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::buildHelpMenu" --
 # 
 # Build the "Scheme Help" menu.  We leave out these items:
 # 
 #   "${key}<IlocalMacroHelpÉ"
 #   "${key}<OlocalMacroHelpÉ"
 # 
 # until they are properly implemented.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::buildHelpMenu {} {
    
    global SPSSmodeVars
    
    # Determine which key should be used for "Help", with F8 as option.
    if {!$SPSSmodeVars(noHelpKey)} {
	set key "/t"
    } else {
	set key "/l"
    }
    set menuList [list "${key}<OwwwCommandHelpÉ" "(-)" "setSpssApplicationÉ" \
      "setPsppApplicationÉ" "(-)" "${key}<BspssModeHelp"]
    
    return [list build $menuList "SPSS::menuProc -M SPSS" {}]
}

proc SPSS::rebuildMenu {{menuName "spssMenu"} {pref ""}} {
    menu::buildSome $menuName
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::postBuildMenu" --
 # 
 # Mark or dim items as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::postBuildMenu {args} {
    
    global SPSSmodeVars
    
    variable prefsInMenu
    
    set lowApp [string tolower $SPSSmodeVars(application)]
    foreach itemName $prefsInMenu {
	if {[info exists SPSSmodeVars($itemName)]} {
	    markMenuItem ${lowApp}ModeOptions $itemName $SPSSmodeVars($itemName) Ã
	}
    }
    if {($lowApp eq "spss")} {
	markMenuItem ${lowApp}ModeOptions spss 1 ¥
	markMenuItem ${lowApp}ModeOptions pspp 0 ¥
    } else {
	markMenuItem ${lowApp}ModeOptions spss 0 ¥
	markMenuItem ${lowApp}ModeOptions pspp 1 ¥
    }
    return
}

# Now we actually build the SPSS menu.
menu::buildSome spssMenu

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::registerOWH" --
 # 
 # Dim some menu items when there are no open windows.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::registerOWH {{which "register"}} {
    
    global spssMenu SPSSmodeVars
    
    set menuItems [list processFile processSelection \
      newComment commentTemplateÉ \
      nextCommand prevCommand selectCommand reformatCommand]
    lappend menuItems \
      mark[string totitle $SPSSmodeVars(application)]FileAs
    
    foreach i $menuItems {
	hook::${which} requireOpenWindowsHook [list $spssMenu $i] 1
    }
    return
}

# Call this now.
SPSS::registerOWH register

# ===========================================================================
# 
# ×××× SPSS menu support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::menuProc" --
 # 
 # This is the procedure called for all main menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::menuProc {menuName itemName} {
    
    global SPSScmds SPSSmodeVars mode
    
    variable keywordLists
    variable prefsInMenu
    
    switch $menuName {
	"spssHelp" -
	"psppHelp" {
	    switch $itemName {
		"setSpssApplication" -
		"setPsppApplication"  {
		    set app $SPSSmodeVars(application)
		    SPSS::setApplication $app
		}
		"spssModeHelp" {package::helpWindow "SPSS"}
		"spss" -
		"pspp" {
		    SPSS::registerOWH deregister
		    set app [string toupper $itemName]
		    set SPSSmodeVars(application) $app
		    SPSS::registerOWH register
		    prefs::modified SPSSmodeVars(application)
		    status::msg "Default application is now $app."
		}
		default {SPSS::$itemName}
	    }
	}
	"spssModeOptions" -
	"psppModeOptions" {
	    if {[getModifiers]} {
		if {($itemName eq "r") || ($itemName eq "s+")} {
		    set helpText "Use this item to switch the default application."
		} else {
		    set helpText [help::prefString $itemName "SPSS"]
		    if {$SPSSmodeVars($itemName)} {
			set end "on"
		    } else {
			set end "off"
		    }
		    if {($end eq "on")} {
			regsub {^.*\|\|} $helpText {} helpText
		    } else {
			regsub {\|\|.*$} $helpText {} helpText
		    }
		    set msg "The '$itemName' preference for SPSS mode is currently $end."
		}
		dialog::alert "${helpText}."
	    } elseif {[lcontains prefsInMenu $itemName]} {
		set SPSSmodeVars($itemName) [expr {$SPSSmodeVars($itemName) ? 0 : 1}]
		if {($mode eq "SPSS")} {
		    synchroniseModeVar $itemName $SPSSmodeVars($itemName)
		} else {
		    prefs::modified SPSSmodeVars($itemName)
		}
		if {[regexp {Help} $itemName]} {
		    SPSS::rebuildMenu "spssHelp"
		    SPSS::rebuildMenu "psppHelp"
		}
		SPSS::postBuildMenu
		if {$SPSSmodeVars($itemName)} {
		    set end "on"
		} else {
		    set end "off"
		}
		set msg "The '$itemName' preference is now $end."
	    } elseif {($itemName eq "spss") || ($itemName eq "pspp")} {
		set newApp [string toupper $itemName]
		set SPSSmodeVars(application) $newApp
		prefs::modified SPSSmodeVars(application)
		SPSS::rebuildMenu
		set msg "Default application is now $newApp."
	    } else {
		error "Cancelled -- don't know what to do with '$itemName'."
	    }
	    if {[info exists msg]} {
		status::msg $msg
	    }
	}
	"spssKeywords" -
	"psppKeywords" {
	    if {($itemName eq "listKeywords")} {
		set p "Current SPSS mode keywordsÉ"
		set keywords [listpick -l -p $p $keywordLists(lowerKeywords)]
		foreach keyword $keywords {
		    SPSS::checkKeywords $keyword
		}
	    } elseif {($itemName eq "addNewCommands") || ($itemName eq "addNewOptions")} {
		set itemName [string trimleft $itemName "addNew"]
		if {($itemName eq "Commands") && [llength [winNames]] && [askyesno \
		  "Would you like to add all of the 'extra' commands from this window\
		  to the 'Add Commands' preference?"]} {
		    SPSS::addWindowCommands
		} else {
		    SPSS::addKeywords $itemName
		}
	    } else {
		SPSS::$itemName
	    }
	    return
	}
	"markPsppFileAs" -
	"markSpssFileAs" {
	    removeAllMarks
	    switch $itemName {
		"source"    {SPSS::MarkFile ".do"}
		"output"    {SPSS::MarkFile ".out"}
		"codebook"  {SPSS::MarkFile ".codebook"}
	    }
	}
	default {
	    switch $itemName {
		"spssHomePage"    {url::execute $SPSSmodeVars(spssHomePage)}
		"psppHomePage"    {url::execute $SPSSmodeVars(psppHomePage)}
		"switchToSpss" -
		"switchToPspp"    {
		    set app $SPSSmodeVars(application)
		    app::launchFore [SPSS::sig $app]
		}
		"newComment"      {comment::newComment 0}
		"commentTemplate" {comment::commentTemplate}
		"nextCommand"     {function::next}
		"prevCommand"     {function::prev}
		"selectCommand"   {function::select}
		"reformatCommand" {function::reformat}
		default           {SPSS::$itemName}
	    }
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::betaMessage" --
 # 
 # Give a beta message for untested features / menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::betaMessage {{item ""}} {
    
    if {($item eq "")} {
	if {[catch {info level -1} item]} {
	    set item "this item"
	}
    }
    error "Cancelled -- '$item' has not been implemented yet."
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::sig" --
 # 
 # Return the SPSS / PSPP signature.  
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::sig {{app "SPSS"}} {
    
    global SPSSmodeVars tcl_platform
    
    if {($app eq "")} {
	set app $SPSSmodeVars(application)
    }
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    
    switch -- $tcl_platform(platform) {
        "macintosh" {
	    # Make sure that the Macintosh application for the signature
	    # actually exists.
	    if {[catch {nameFromAppl $SPSSmodeVars(${lowApp}Sig)}]} {
		alertnote "Looking for the $capApp application ..."
		SPSS::setApplication $lowApp
	    }
        }
        "windows" - "unix" {
	    # Make sure that the Windows application for the signature
	    # exists.  We assume that this will work for unix, too.
	    if {![file exists $SPSSmodeVars(${lowApp}Sig)]} {
		alertnote "Looking for the $capApp application ..."
		SPSS::setApplication $lowApp
	    }
        }
    }
    return $SPSSmodeVars(${lowApp}Sig)
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::setApplication" --
 # 
 # Prompt the user to locate the local application for either SPSS or PSPP.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::setApplication {{app ""}} {
    
    global mode SPSSmodeVars
    
    set app $SPSSmodeVars(application)
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    set newSig ""
    set newSig [dialog::askFindApp $capApp $SPSSmodeVars(${lowApp}Sig)]
    
    if {($newSig eq "")} {
	error "cancel"
    }
    set SPSSmodeVars(${lowApp}Sig) "$newSig"
    prefs::modified SPSSmodeVars(${lowApp}Sig)
    status::msg "The $capApp signature has been changed to '$newSig'."
    return
}

# ===========================================================================
# 
# ×××× Keywords ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::addWindowCommands" --
 # 
 # Add all of the "extra" commands which appear in entries in this window.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::addWindowCommands {} {
    
    global mode SPSScmds SPSSmodeVars
    
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
	set aCommand [string tolower $aCommand]
	if {![lcontains SPSScmds $aCommand]} {
	    append SPSSmodeVars(addCommands) " $aCommand"
	}
    }
    mode::setVar SPSS addCommands [lsort -unique $SPSSmodeVars(addCommands)]
    if {[llength $SPSSmodeVars(addCommands)]} {
	SPSS::colorizeSPSS
	listpick -p "The 'Add Commands' preference includes:" \
	  $SPSSmodeVars(addCommands)
	status::msg "Use the 'Mode Prefs > Preferences' menu item to edit keyword lists."
    } else {
	status::msg "No 'extra' commands from this window were found."
    }
    return
}

proc SPSS::addKeywords {{category} {keywords ""}} {
    
    global SPSSmodeVars
    
    if {($keywords eq "")} {
	set keywords [prompt "Enter new SPSS $category:" ""]
    }
    
    # The list of keywords should all be lower case.
    set keywords [string tolower $keywords]
    # Check to see if the keyword is already defined.
    foreach keyword $keywords {
	set checkStatus [SPSS::checkKeywords $keyword 1 0]
	if {($checkStatus != 0)} {
	    alertnote "Sorry, '$keyword' is already defined\
	      in the $checkStatus list."
	    error "cancel"
	}
    }
    # Keywords are all new, so add them to the appropriate mode preference.
    lappend SPSSmodeVars(add$category) $keywords
    set SPSSmodeVars(add$category) [lsort $SPSSmodeVars(add$category)]
    prefs::modified SPSSmodeVars(add$category)
    SPSS::colorizeSPSS
    status::msg "'$keywords' added to $category preference."
    return
}

proc SPSS::checkKeywords {{newKeywordList ""} {quietly 0} {noPrefs 0}} {
    
    global SPSSmodeVars SPSSUserCommands
    
    variable keywordLists
    
    set type 0
    if {($newKeywordList eq "")} {
	set quietly 0
	set newKeywordList [prompt "Enter SPSS mode keywords to be checked:" ""]
    }
    # Check to see if the new keyword(s) is already defined.
    foreach newKeyword $newKeywordList {
	set newKeyword [string tolower $newKeyword]
	if {[lcontains keywordLists(commands) $newKeyword]} {
	    set type "default commands"
	} elseif {[lcontains SPSSUserCommands $newKeyword]} {
	    set type "\$SPSSUserCommands"
	} elseif {[lcontains SPSSmodeVars(addCommands) $newKeyword]} {
	    set type "Add Commands preference"
	} elseif {!$noPrefs \
	  && [lcontains keywordLists(functions) $newKeyword]} {
	    set type "default functions"
	} elseif {!$noPrefs \
	  && [lcontains keywordLists(operators) $newKeyword]} {
	    set type "default operators"
	}
	if {$quietly} {
	    # When this is called from other code, it should only contain
	    # one keyword to be checked, and we'll return it's type.
	    return "$type"
	} elseif {!$quietly && ($type eq 0)} {
	    alertnote "'$newKeyword' is not currently defined\
	      as a SPSS mode keyword"
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
 # "SPSS::processFile" --
 # 
 # Send entire file to SPSS for processing, adding carriage return at end of
 # file if necessary.
 # 
 # Optional "f" argument allows this to be called by other code, or to be
 # sent via a Tcl shell window.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::processFile {{f ""} {app ""}} {
    
    global SPSSmodeVars
    
    if {($f ne "")} {
	file::openAny $f
    }
    set f [win::Current]
    
    if {($app eq "")} {
	set app $SPSSmodeVars(application)
    }
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    
    set dirtyWindow [winDirty]
    set dontSave 0
    if {$dirtyWindow && [askyesno \
      "Do you want to save the file before sending it to $capApp?"]} {
	save
    } else {
	set dontSave 1
    }
    if {!$dontSave && [lookAt [pos::math [maxPos] - 1]] ne "\r"} {
	set pos [getPos]
	goto [maxPos]
	insertText "\r"
	goto $pos
	alertnote "Carriage return added to end of file."
	save
    }
    
    app::launchBack '[SPSS::sig $capApp]'
    sendOpenEvent noReply '[SPSS::sig $capApp]' $f
    switchTo '[SPSS::sig $capApp]'
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::processSelection" --
 # 
 # Procedure to implement transfer of selected lines to SPSS for processing.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::processSelection {{selection ""} {app ""}} {
    
    global SPSSmodeVars
    
    if {($app eq "")} {
	set app $SPSSmodeVars(application)
    }
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    
    if {($selection eq "")} {
	if {![isSelection]} {
	    status::msg "No selection -- cancelled."
	    return
	} else {
	    set selection [getSelect]
	}
    }
    set tempDir [temp::directory SPSS]
    set newFile [file join $tempDir temp-SPSS.sps]
    file::writeAll $newFile $selection 1
    
    app::launchBack '[SPSS::sig $capApp]'
    sendOpenEvent noReply '[SPSS::sig $capApp]' $newFile
    switchTo '[SPSS::sig $capApp]'
    return
}

proc SPSS::quitHook {} {
    temp::cleanup SPSS
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
# 01/28/20 cbu 1.0.1  First created SPSS mode, based upon other modes found 
#                       in Alpha's distribution.  Commands are based on 
#                       version 4.0 of SPSS.
# 03/02/20 cbu 1.0.2  Minor modifications to comment handling.
# 03/20/00 cbu 1.0.3  Minor update of keywords dictionaries.
# 04/01/00 cbu 1.0.4  Added new preferences to allow the user to enter 
#                       additional commands, arguments, and symbols.  
#                     Added "Update Colors" proc to avoid need for a restart
# 04/08/00 cbu 1.0.5  Unset obsolete preferences from earlier versions.
#                     Added "Continue Comment", "Electric Return Over-ride",
#                       and "Electric Period".
#                     Renamed "Update Colors" to "Update Preferences".
# 04/16/00 cbu 1.1    Renamed to spssMode.tcl
#                     Added "Mark File" and "Parse Functions" procs.
# 06/22/00 cbu 1.2    "Mark File" now recognizes headings as well as commands.
#                     "Mark File" recognizes source or output files.
#                     Completions, Completions Tutorial added.
#                     "Reload Completions", referenced by "Update Preferences".
#                     Better support for user defined keywords.
#                     Removed "Continue Comment", now global in Alpha 7.4.
#                     Added command double-click for on-line help.
#                     <shift, control>-<command> double-click syntax info.
#                       (Foundations, at least.  Ongoing project.)
# 08/08/00 cbu 1.2.1  Minor electric completions bug fixes.
#                     Added message if no matching ")".
#                     Mark File ignores "execute" commands.
#                     Mark File can mark a frequencies file.
#                     Beta-version of an SPSS menu, based on the Stata menu.
#                     Added "spssSig" preference to allow user to find
#                       local application if necessary.
#                     Added SPSS::sig which returns SPSS signature.
# 08/28/00 cbu 1.2.2  Added some of the flag preferences to "SPSS Help" menu.
#                     Added "flagFlip" to update preference bullets in menu.
#                     Added a "noHelpKey" preference, which switches the
#                       "help" key binding to F8.
#                     Added "Add New Commands / Arguments" to "SPSS Help" menu.
#                     Added "Set SPSS Application to "SPSS Help" menu.
# 11/05/00 cbu 1.3    Added "next/prevCommand", "selectCommand", and
#                       "copyCommand" procs to menu.
#                     Added "SPSS::indentLine".
#                     Added "SPSS::reformatCommand" to menu.
#                     "SPSS::reloadCompletions" is now obsolete.
#                     "SPSS::updatePreferences" is now obsolete.
#                     "SPSS::colorizeSPSS" now takes care of setting all 
#                       keyword lists, including SPSScmds.
#                     Cleaned up completion procs.  This file never has to be
#                       reloaded.  (Similar cleaning up for "SPSS::DblClick").
# 11/16/00 cbu 2.0    New url prefs handling requires 7.4b21
#                     Added "Home Page" pref, menu item.
#                     Removed  hook::register requireOpenWindowsHook from
#                       mode declaration, put it after menu build.
# 12/19/00 cbu 2.1    The menu proc "Add Commands" now includes an option
#                       to grab all of the "extra" command from the current
#                       window, using SPSS::addWindowCommands.
#                     Added "Keywords" submenu, "List Keywords" menu item.
#                     Big cleanup of ::sig, ::setApplication, processing ...
# 01/25/01 cbu 2.1.1  Bug fix for SPSS::processSelection/File.
#                     Better frequency file marking.
#                     Bug fix for comment characters.
# 09/26/01 cbu 2.2    Big cleanup, enabled by new 'functions.tcl' procs.
# 10/31/01 cbu 2.2.1  Minor bug fixes.
# 05/30/03 vmd 2.2.2  Minor changes in light of AlphaTcl SystemCode update
#                       for electric preferences and handling.
# 10/18/05 cbu 2.3    Keywords lists are defined in SPSS namespace variables.
#                     Canonical Tcl formatting changes.
#                     Using [prefs::dialogs::setPaneLists] for preferences.
#                     New "markHeadingsOnly" preference.
#                     Disabled unimplemented features (finally).
# 

# ===========================================================================
# 
# .