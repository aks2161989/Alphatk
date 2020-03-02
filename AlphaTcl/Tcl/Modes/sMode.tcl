## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # Statistical Modes - an extension package for Alpha
 # 
 # FILE: "sMode.tcl"
 #                                          created: 01/15/2000 {07:15:32 pm}
 #                                      last update: 05/23/2006 {10:44:48 AM}
 # Description: 
 #                                
 # For S (or S-Plus) syntax files, as well as the free distribution of R.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # -------------------------------------------------------------------
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
# ×××× Initialization of S mode ×××× #
# 

alpha::mode [list S "S+/R"] 2.3 "sMode.tcl" {
    *.s *.S *.R
} {
    sMenu
} {
    # Script to execute at Alpha startup
    addMenu sMenu "S+/R" S
    set unixMode(splus) {S}
} uninstall {
    catch {file delete [file join $HOME Tcl Modes sMode.tcl]}
    catch {file delete [file join $HOME Tcl Completions SCompletions.tcl]}
    catch {file delete [file join $HOME Tcl Completions "S Tutorial.s"]}
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Supports the editing of S+ and R statistical batch files
} help {
    file "Statistical Modes Help"
}

hook::register quitHook S::quitHook

proc sMode.tcl {} {}

namespace eval S {
    
    # Comment Character variables for Comment Line/Paragraph/Box menu items.
    variable commentCharacters
    array set commentCharacters [list \
      "General"         "# " \
      "Paragraph"       [list "## " " ##" " # "] \
      "Box"             [list "#" 1 "#" 1 "#" 3] \
      ]
    
    # Set the list of flag preferences which can be changed in the menu.
    variable prefsInMenu [list \
      "localHelp" \
      "noHelpKey" \
      "useMassLibrary" \
      "(-)" \
      "autoMark" \
      "markHeadingsOnly" \
      ]
    
    # Used in [S::colorizeS].
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
    # S-Plus is remarkably elegant in structure.  Commands have arguments,
    # and rarely does the language use the same names for both.  There are a
    # few exceptions, listed initially in the argument category.
    #
    
    variable keywordLists
    
    # =======================================================================
    #
    # S Commands
    #
    set keywordLists(commands) [list \
      .First .First.lib .First.local .Last .Last.value .Options \
      .Random.seed abbreviate abline abs ace acf acf.plot acos add1 adm.ave \
      adm.filt adm.smo aggregate aggregrate.ts agnes akima alias all \
      all.equal allocated anova any aov aov.genyates aperm append apply \
      approx ar ar.burg ar.gm ar.yw arg.dialog args arima.diag arima.filt \
      arima.forecast arima.fracdiff arima.fracdiff.sim arima.mle arima.sim \
      arima.td array arrows as.character as.data.frame as.data.frame.array \
      as.data.frame.ts as.design as.matrix as.numeric as.vector as.xxx asin \
      assign atan attach attr attributes avas axis backsolve banking \
      barchart barplot BATCH bcv becnorm binomial biplot biplot.default \
      bootstrap boxplay browser brush bs butterfly bwplot by c cancor cat \
      cbind cdf.compare ceiling cex character charmatch chissq.gof chol \
      clara class close.screen cloud cmdscale coef coefficients contour \
      contr.helmert contr.poly contr.sdif contr.sum contr.treatment \
      contrasts cor cor.test correlogram cos cosh count.fields countourplot \
      cov.mve cov.wt cox.zph coxph crossprod crosstabs cts cummax cummin \
      cumprod cumsum cut cutree cv.tree D daisy data.class data.dump \
      data.frame data.matrix data.restore database.object date dates \
      dbwrite debugger demod density densityplot deparse deriv deriv3 \
      design det detach dev.ask dev.copy dev.cur dev.list dev.next dev.off \
      dev.prev dev.print dev.set deviance dget diag Diagonal diana diff dim \
      dimnames dist dmvnorm do.call dos dos.time dotchart dotplot dput drop \
      drop1 dummy.corf dump dump.calls dump.frames dumpdata duplicated ed \
      eigen equal.count Error eval exists exp expand.grid expcov expn \
      expression F fac/desogm faces factanal factor family fanny fft fig \
      file.exists filter find fitted fitted.values fix fixed.effects floor \
      for format formula fpl fractionate frame frequency.polygram gam \
      gam.plot gamma gaucov gaussian get getwd glm glm.links glm.variances \
      graphics.off graphsheet grep hclust help help.off help.start hist \
      hist.FD hist.scott hist2d histogram history hpgl hplg I() identify if \
      ifelse Im image inspect integrate interaction.plot interp \
      inverse.gaussian invisible iris4d is.characger is.na is.random is.xxx \
      its julian Kaver keep.order Kenvl key Kfn kmeans kruskal.test ks.gof \
      ksmooth l1fit lag lapply last.dump leaps legend length letters \
      levelplot levels lgamma library limits.bca limits.emp lines list lm \
      lm.influence lme lmsreg lo loadings location.m locator loess log \
      log10 loglin lower.tri lowess ltsreg lu mad mahalanobis mai make.call \
      make.family make.fileds make.groups manova mar masked mat2tr match \
      match.arg matplot matrix Matrix.class max mclass mclust mean median \
      memory.size merge mex mfcol mfrow min misclass.tree missing mkh mode \
      model.frame.tree model.matrix model.tables mona monthplot motif \
      mreloc ms mstree mtext multinom na.action na.fail na.gam.replace \
      na.omit names nchar nclass.FD nclass.scott ncol neg.bin next \
      NextMethod nlme nlminb nlregb nls nlsList nnet nnet.Hess nnls.fit \
      norm nroff nrow ns ntrellis numeric objdiff objects offset oma omd \
      omi on.exit openlook optimize optimize options order ordered outer \
      output pairs pam par partition.tree paste pdf pdf.graph persp \
      persp.setup perspp pi pie piechart plclust plot.gam plot.survfit \
      pltree pmatch pmax pmin pmvnorm pnorm points poisson poly polygon \
      polyroot post.tree postscript ppinit pplik ppoints ppreg ppregion \
      prcomp predict predict.factanal predict.gam predict.lm predict.lme \
      predict.tree princomp print.summary print.trellis printgraph prmat \
      proc.time prod profile proj prompt prompt.screen prune.misclass \
      prune.tree Psim pty q qda qqline qqnorm qqplot qr qr.coef qr.fitted \
      qr.Q qr.R qr.resid qr.X quantile quasi range rank raov rbind rbiwt \
      rcond Re read.table Recall remove reorder.factor rep repeat \
      replications resid residuals restart return rev rm rmv rmvnorm rnorm \
      rotate rotate.default round row row.names RowPermutation Rows rreg \
      rts rug s sabl sample sapply scale scale.a scale.tau scan \
      scatter.smooth screen screenplot se.contrast search segments semat \
      seq set.seed setwd show.settings sign signig sin sinh sink \
      slice.index slm smooth.spline solve solve.qr solve.upper sort \
      sort.list source spatial spec.ar spec.pgram spec.taper spectrum \
      sphercov spin spline split split.screen splom sqrt SSI stars \
      state.name statlib stdres stem step stepAIC stepfun stepwise stl stop \
      Strauss stripplot structure studres subplot subset substring \
      substutute sum summary summary.coxph summary.gam summary.lm supsmu \
      surf.gls surf.ls Surv survdiff survexp survfit survreg svd sweep \
      switch symbol symbols synchronize sys.parent system t t.test table \
      tan tanh tapply tempfile terms text text.default title tpois tprint \
      trace traceback tree tree.control trellis trellis.3d.args \
      trellis.args trellis.device trellis.par.get trellis.par.set trmat \
      trunc ts.intersect ts.lines ts.plot ts.points ts.union tspar ttest \
      tue.file.name twoway unclass unique uniroot unix unix.time unlink \
      unlist unpack update usa UseMethod usr var var.test varcomp variogram \
      vcov.mlreg vcov.nlminb vi warning while wilcox.text win.colorscheme \
      win.graph win.printer win3 window wireframe write write.table xor \
      xyplot \
      ]
    
    # =======================================================================
    #
    # S Arguments
    #
    set keywordLists(arguments) [list \
      add aic all angle append as.is aux axes bandwidth best border \
      box.ratio boxplots byrow center circles cohort col.names collapse \
      conditional conf.int constant cor cuts data decay degree delta demean \
      density depth detail detrend device df dframe differences \
      dimmames.write dist drape eig else end entropy erase et evaluate \
      exclude extrap factors family fence file fileout fill first frame \
      frequency full.precision FUN fun gof.lag gradient h head header \
      height help Hess hessian highlight hist horizontal in inches \
      individual int inter.max intercept inverse inverted iter jacobian \
      jitter k kernel labels lag lims lineout link local low lower lty lwd \
      max max.subdiv maxit menu message method metric more multi.line n NA \
      na.action na.last na.rm name ndeltat new nf ng niter noise normalize \
      nu NULL nv offline onefile only.values orthogonal p parameters \
      partial pattern pivot plane plotit pos prior prob probability probs \
      psi.fun rang rectangles reverse rho rotation save scale scores se.fit \
      sep short side sim simplify skip softmax span spar spin squares stars \
      start subset summ symmetric taper test thermometers ticks tol trace \
      trim tuning twodig type upper v var.axes what where which window wt x \
      xl xlab xu y yl ylab yu \
      \
      TRUE FALSE \
      ]
    
    # =======================================================================
    #
    # S Mass Library
    #
    set keywordLists(MASS) [list \
      abbey accdeaths addterm Aids2 animals anova.negbin area austres bcv \
      beaver1 beaver2 biopsy biplot.princomp birthwt Boston boxcox Cars93 \
      cats cement chem Choleski coop corresp cov.trob cpgram cpus crabs \
      Cushings DDT deaths digamma drivers dropterm eqscplot faithful farms \
      fdeaths fgl forbes fractions GAGurine galaxies gamma.dispersion \
      gamma.shape.glm gehan genotype gilgais ginv glm.convert glm.nb hills \
      histplot huber hubers immer Insurance IQR isoMDS janka kde2d lda \
      ldahist leuk lh loglm logtrans mammals mca mcycle mdeaths Melanoma \
      menarche michelson minn38 motors mvrnorm negative.binomial newcomb \
      nottem npr1 oats OME painters pairs.lda petrol phones Pima.tr \
      plot.lda plot.mca predict.lda predict.mca predict.qda qda quine \
      Rabbit rational rlm rms.curv rnegbin road rock rotifer Rubber sammon \
      ships shoes shrimp shuttle Sitka Sitka89 Skye snails stdres steam \
      stepAIC stormer studres summary.loglm summary.negbin summary.rlm \
      survey synth.tr theta.md theta.mm topo Traffic trees trigamma \
      truehist ucv UScereal UScrime vcov vcov.nlregb waders width.SJ \
      write.matrix wtloss \
      ]
}

# ===========================================================================
#
# ×××× Setting S mode variables ×××× #
#

# Removing obsolete preferences from earlier versions.

set oldvars {
    don'tRemindMe funcExpr parseExpr keywordColor eitherorColor
    functionColor useMagicCharacter eitherOrs eitherOrColor sHelp
}

foreach oldvar $oldvars {prefs::removeObsolete SmodeVars($oldvar)}

unset oldvar oldvars

# ===========================================================================
#
# Standard preferences recognized by various Alpha procs
#

newPref var  leftFillColumn     {0}                     S
newPref var  fillColumn         {75}                    S
newPref var  prefixString       {# }                    S
newPref var  wordBreak          {[-\w\.]+}      S
newPref var  lineWrap           {0}                     S
newPref var  commentsContinuation 1                     S "" \
  [list "only at line start" "spaces allowed" "anywhere"] index

# To automatically perform context relevant formatting after typing a left
# or right curly brace or parenthesis, turn this item on||To have the brace
# and parenthesis keys produce a brace without additional formatting, turn
# this item off
newPref flag electricBraces    1 S
# To automatically indent the new line produced by pressing Return, turn
# this item on.  The indentation amount is determined by the context||To
# have the Return key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 S

# ===========================================================================
#
# Flag preferences
#

# To automatically mark files when they are opened, turn this item on||To
# disable the automatic marking of files when they are opened, turn this
# item off
newPref flag autoMark           {0}     S   {S::rebuildMenu markSFileAs}
# To primarily use a www site for help rather than the local S+ or R
# application, turn this item on|| To primarily use the local S+ or R
# application for help rather than on a www site turn this item off
newPref flag localHelp          {0}     S   {S::rebuildMenu sMenu}
# To only mark "headings" in windows (those preceded by ###), turn this item
# on||To mark both commands and headings in windows, turn this item off
newPref flag markHeadingsOnly   {0}     S   {S::postBuildMenu}
# If your keyboard does not have a "Help" key, turn this item on.  This will
# change some of the menu's key bindings|| If your keyboard has a "Help"
# key, turn this item off.  This will change some of the menu's key bindings
newPref flag noHelpKey          {0}     S   {S::rebuildMenu sMenu}
# Check this preference to use Venable and Ripley's MASS library for keyword
# colorizing and completions
newPref flag useMassLibrary     {1}     S   {S::colorizeS}

# ===========================================================================
#
# Variable preferences
# 

# Enter additional arguments to be colorized. 
newPref var addArguments        {c dimnames list plot replace} S {S::colorizeS}
# Enter additional S commands to be colorized.
newPref var addCommands         {print} S   {S::colorizeS}
# Select the statistical application to be used.
newPref var application         {S+}    S   {S::rebuildMenu sMenu} [list R S+]
# Command double-clicking on an S keyword will send it to this url for a
# help reference page.
newPref url helpUrl \
  {http://www.stat.math.ethz.ch/R-manual/R-patched/library/base/html/} S
# The "R Home Page" menu item will send this url to your browser.
newPref url rHomePage           {http://cran.r-project.org/}    S
# Click on "Set" to find the local R application.
newPref sig rSig                {}      S   {}
# The "S+ Home Page" menu item will send this url to your browser.
newPref url s+HomePage          {http://www.insightful.com/products/splus/} S
# Click on "Set" to find the local S+ application.  (As of this writing
# there are no such applications for the Macintosh.)
newPref sig s+Sig               {}      S   {}

# ===========================================================================
#
# Color preferences
#

# See the Statistical Modes Help file for an explanation of these different
# categories, and lists of keywords.
newPref color argumentColor     {magenta}       S   {S::colorizeS}
newPref color commandColor      {blue}          S   {S::colorizeS}
newPref color commentColor      {red}           S   {stringColorProc}
# Color of the magic character $.  Magic Characters will colorize any
# string which follows them, up to the next empty space.
newPref color magicColor        {none}          S   {S::colorizeS}
newPref color stringColor       {green}         S   {stringColorProc}
# The color of symbols such as "/", "@", etc.
newPref color symbolColor       {magenta}       S   {S::colorizeS}

# ===========================================================================
# 
# Categories of all S+/R preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# Editing
prefs::dialogs::setPaneLists "S" "Editing" [list \
  "autoMark" \
  "electricBraces" \
  "fillColumn" \
  "indentOnReturn" \
  "leftFillColumn" \
  "lineWrap" \
  "markHeadingsOnly" \
  "wordBreak" \
  ]

# Comments
prefs::dialogs::setPaneLists "S" "Comments" [list \
  "commentColor" \
  "commentsContinuation" \
  "prefixString" \
  ]

# Colors
prefs::dialogs::setPaneLists "S" "Colors" [list \
  "addArguments" \
  "addCommands" \
  "argumentColor" \
  "commandColor" \
  "magicColor" \
  "stringColor" \
  "symbolColor" \
  "useMassLibrary" \
  ]

# Help
prefs::dialogs::setPaneLists "S" "S+/R Help" [list \
  "application" \
  "helpUrl" \
  "localHelp" \
  "noHelpKey" \
  "rHomePage" \
  "rSig" \
  "s+HomePage" \
  "s+Sig" \
  ]

## 
 # --------------------------------------------------------------------------
 # 
 # "S::colorizeS" --
 # 
 # Set all keyword lists, and colorize.
 # 
 # Could also be called in a <mode>Prefs.tcl file
 # 
 # --------------------------------------------------------------------------
 ##

proc S::colorizeS {{pref ""}} {
    
    global SmodeVars Scmds SUserCommands SUserArguments
    
    variable firstColorCall
    variable keywordLists
    
    set Scmds [list]
    # Create the "allCommands" list for [S::Completion::Command].
    set keywordLists(allCommands) [list]
    foreach keyword $keywordLists(commands) {
	lappend Scmds $keyword
	lappend keywordLists(allCommands) $keyword
    }
    foreach keyword $SmodeVars(addCommands) {
	lappend Scmds $keyword
	lappend keywordLists(allCommands) $keyword
    }
    if {[info exists SUserCommands]} {
	foreach keyword $SUserCommands {
	    lappend Scmds $keyword
	    lappend keywordLists(allCommands) $keyword
	}
    }
    if {$SmodeVars(useMassLibrary)} {
	foreach keyword $keywordLists(MASS) {
	    lappend Scmds $keyword
	    lappend keywordLists(allCommands) $keyword
	}
    }
    # Arguments
    set arguments [list]
    foreach keyword $keywordLists(arguments) {
	lappend Scmds $keyword
	lappend arguments $keyword
    }
    foreach keyword $SmodeVars(addArguments) {
	lappend Scmds $keyword
	lappend arguments $keyword
    }
    if {[info exists SUserArguments]} {
	foreach keyword $SUserArguments {
	    lappend Scmds $keyword
	    lappend arguments $keyword
	}
    }
    # "Scmds"
    set Scmds [lsort -dictionary -unique $Scmds]
    
    # Now we colorize keywords.  If this is the first call, we don't include 
    # the "-a" flag.
    if {$firstColorCall} {
	regModeKeywords -C S {}
	set firstColorCall 0
    }
    
    # Color comments and strings
    regModeKeywords -a -e {#} -c $SmodeVars(commentColor) \
      -s $SmodeVars(stringColor) S
    
    # Color Commands
    regModeKeywords -a -k $SmodeVars(commandColor) S $keywordLists(allCommands)
    
    if {$SmodeVars(useMassLibrary)} {
	regModeKeywords -a -k $SmodeVars(commandColor) S $keywordLists(MASS)
    } else {
	regModeKeywords -a -k {none} S $keywordLists(MASS)
    }
    # Color Arguments
    regModeKeywords -a -k $SmodeVars(argumentColor) S $arguments
    
    # Color Symbols
    regModeKeywords -a -i "+" -i "-" -i "*" -i "\\" -i "/" -i "|" -i "=" \
      -I $SmodeVars(symbolColor) S {}
    regModeKeywords -a -m {$} -k $SmodeVars(magicColor) S {}
    
    if {$pref ne ""} {
	refresh
    }
    if {$pref eq "useMassLibrary"} {
	S::rebuildMenu sMenu
    }
    return
}

# Call this now.
S::colorizeS

# ===========================================================================
#
# ×××× Key Bindings, Electrics ×××× #
# 

Bind '\r'   <s>     {S::continueCommand} S
Bind '\)'           {S::electricRight "\)"} S

# For those that would rather use arrow keys to navigate.  Up and down
# arrow keys will advance to next/prev command, right and left will also
# set the cursor to the top of the window.

Bind    up  <sz>    {S::searchFunc 0 0 0} S
Bind  left  <sz>    {S::searchFunc 0 0 1} S
Bind  down  <sz>    {S::searchFunc 1 0 0} S
Bind right  <sz>    {S::searchFunc 1 0 1} S

## 
 # --------------------------------------------------------------------------
 # 
 # "S::carriageReturn" --
 # 
 # Inserts a carriage return, and indents properly.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::carriageReturn {} {
    
    if {[isSelection]} {
	deleteSelection
    }
    set pos1 [lineStart [getPos]]
    set pos2 [getPos]
    if {[regexp {^([\t ])*(\}|\)|dev\.off)} [getText $pos1 $pos2]]} {
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
 # "S::electricLeft" --
 # "S::electricRight" --
 # 
 # Adapted from "tclMode.tcl"
 # 
 # --------------------------------------------------------------------------
 ##

proc S::electricLeft {} {
    
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
    
proc S::electricRight {{char "\}"}} {
    
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

## 
 # --------------------------------------------------------------------------
 # 
 # "S::continueCommand" --
 # 
 # Over-rides the automatic indentation of lines that begin with \} or \)
 # so that additional text can be entered.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::continueCommand {} {
    
    global indentationAmount
    
    bind::CarriageReturn
    if {[pos::compare [getPos] != [maxPos]]} {
	set nextChar [getText [getPos] [pos::math [getPos] + 1]]
	if {($nextChar eq "\}") || ($nextChar eq "\)")} {
	    insertText [text::indentOf $indentationAmount]
	}
    }
    return
}

proc S::searchFunc {direction args} {
    
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
 # "S::correctIndentation" --
 # 
 # [S::correctIndentation] is necessary for Smart Paste, and returns the
 # correct level of indentation for the current line.
 # 
 # In [S::correctIndentation] we grab the previous non-commented line, remove
 # all of the characters besides braces, quotes, and hashmarks, and then
 # convert it all to a list to be evaluated.  Braces and hashmarks contained
 # within quotes, as well as literal characters, should all be ignored and
 # the remaining braces are used to determine the correct level of nesting.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::correctIndentation {args} {
    
    global SmodeVars indentationAmount
    
    win::parseArgs w pos {next ""}
    
    set posBeg    [pos::lineStart -w $w $pos]
    # Get information about this line, previous line ...
    set thisLine  [S::getCommandLine -w $w $posBeg 1 1]
    set prevLine1 [S::getCommandLine -w $w \
      [pos::math -w $w $posBeg - 1] 0 1]
    set prevLine2 [S::getCommandLine -w $w \
      [pos::math -w $w [lindex $prevLine1 0] - 1] 0 1]
    set lwhite    [lindex $prevLine1 1]
    # If we have a previous line ...
    if {[pos::compare -w $w [lindex $prevLine1 0] != $posBeg]} {
	# Indent if the preceding command was a postscript/pdf command.
	set pL1 [string trim [lindex $prevLine1 2]]
	if {[regexp {^[\t ]*(postscript|pdf)([\t ]*\()} $pL1]} {
	    incr lwhite $indentationAmount
	}
	# Indent if the last line did not terminate the command.
	if {([string trimright $pL1 "\\"] ne $pL1)} {
	    incr lwhite [expr {$indentationAmount/2}]
	}
	# Check to make sure that the previous command was not itself a
	# continuation of the line before it.
	if {[pos::compare -w $w [lindex $prevLine2 0] != [lindex $prevLine1 0]]} {
	    set pL2 [string trim [lindex $prevLine2 2]]
	    if {([string trimright $pL2 "\\"] ne $pL2)} {
		incr lwhite [expr {-$indentationAmount/2}]
	    }
	}
	# Find out if there are any unbalanced {,},(,) in the last line.
	regsub -all {[^ \{\}\(\)\"\#\\]} $pL1 { } line
	# Remove all literals.
	regsub -all {\\\{|\\\}|\\\(|\\\)|\\\"|\\\#} $line { } line
	regsub -all {\\} $line { } line
	# Remove everything surrounded by quotes.
	regsub -all {\"[^\"]+\"} $line { } line
	regsub -all {\"} $line { } line
	# Remove all characters following the first valid comment.
	if {[regexp {\#} $line]} {
	    set line [string range $line 0 [string first {#} $line]]
	}
	# Now turn all braces into 1's and -1's
	regsub -all {\{|\(} $line { 1 }  line
	regsub -all {\}|\)} $line { -1 } line
	# This list should now only contain 1's and -1's.
	foreach i $line {
	    if {($i eq "1") || ($i eq "-1")} {
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
	if {($next eq "\}") || ($next eq ")") || [regexp {^[\t ]*(\}|\)|dev\.off)} $tL]} {
	    incr lwhite -$indentationAmount
	}
    }
    # Now we return the level to the calling proc.
    return [expr {$lwhite > 0} ? $lwhite : 0]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "S::getCommandLine" --
 # 
 # Find the next/prev command line relative to a given position, and return
 # the position in which it starts, its indentation, and the complete text of
 # the command line.  If the search for the next/prev command fails, return
 # an indentation level of 0.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::getCommandLine {args} {
    
    win::parseArgs w pos {direction 1} {ignoreComments 1}
    
    if {$ignoreComments} {
	set pat {^[\t ]*[^\t\r\n\# ]}
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
 # "S::DblClick" --
 # 
 # Checks to see if the highlighted word appears in any keyword list, and if
 # so, sends the selected word to the www.mathsoft.com help site.
 # 
 # (The above is not yet implemented: where's a S help site ???)
 #
 # Control-Command double click will insert syntax information in status bar.
 # Shift-Command double click will insert commented syntax information in
 # window.
 # 
 # (The above is not yet implemented: need to enter all of the syntax info.)
 # 
 # --------------------------------------------------------------------------
 ##

proc S::DblClick {from to shift option control} {
    
    # First make sure that Scmds has been defined.
    
    SCompletions.tcl
    
    global SmodeVars Scmds SSyntaxMessage
    
    set where [getPos]
    
    selectText $from $to
    set command [getSelect]
    
    set varDef "$command+\[\t \]+(<\-|_)"
    
    # First found out if "$command" is a file in the same directory, or a 
    # complete path.  If the file exists, open it in Alpha.
    if {[file::tryToOpen $command 0]} {
	return
    }
    # Not a file, so try something else.
    if {![catch {search -s -f 1 -r 1 -m 0 $varDef [minPos]} match]} {
	# First check current file for a variable (etc) definition, and if
	# found ...
	placeBookmark
	goto [lineStart [lindex $match 0]]
	status::msg "press <Ctl .> to return to original cursor position"
	return
	# Could next check any open windows, or files in the current
	# window's folder ...  but not implemented.  For now, variables
	# (etc) need to be defined in current file.
    } elseif {![lcontains Scmds $command]} {
	status::msg "'$command' is not defined as an S system keyword."
	return
    }
    # Defined as a keyword, determine if there's a syntax message.
    # Any modifiers pressed?
    if {$control} {
	# CONTROL -- Just put syntax message in status bar window
	if {[info exists SSyntaxMessage($command)]} {
	    status::msg "$SSyntaxMessage($command)"
	} else {
	    status::msg "Sorry, no syntax information available for $command"
	}
    } elseif {$shift} {
	# SHIFT --Just insert syntax message as commented text
	if {[info exists SSyntaxMessage($command)]} {
	    endOfLine
	    insertText "\r"
	    insertText "$SSyntaxMessage($command)"
	    comment::Line
	} else {
	    status::msg "Sorry, no syntax information available for $command"
	}
    } elseif {$option && !$SmodeVars(localHelp)} {
	# Now we have four possibilities, based on "option" key and the
	# preference for "local Help".
	# 
	# OPTION, local help isn't checked -- Send command to local application
	S::localCommandHelp $command
    } elseif {$option && $SmodeVars(localHelp)} {
	# OPTION, but local help is checked -- Send command for on-line help.
	S::wwwCommandHelp $command
    } elseif {$SmodeVars(localHelp)} {
	# No modifiers, local help is checked -- Send command to local app.
	S::localCommandHelp $command
    } else {
	# No modifiers, no local help checked -- Send command for on-line
	# help.  This is the "default" behavior.
	S::wwwCommandHelp $command
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "S::wwwCommandHelp" --
 # 
 # Send command to defined url, prompting for text if necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::wwwCommandHelp {{command ""}} {
    
    global SmodeVars
    
    if {($command eq "")} {
	if {[catch {prompt "On-line S+/R help for É" ""} command]} {
	    error "cancel"
	}
    }
    status::msg "'$command' sent to $SmodeVars(helpUrl)"
    urlView $SmodeVars(helpUrl)${command}.html
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "S::localCommandHelp" --
 # 
 # Find a local help file, and open it in a browser.  Prompt for text if
 # necessary.
 # 
 # We're assuming that the help does exist as a file somewhere, as opposed to
 # being an internal application help function.  At the moment, we also
 # assume that this file is html, although that could be a mode option as
 # well.
 # 
 # This needs more work ...
 # 
 # --------------------------------------------------------------------------
 ##

proc S::localCommandHelp {{command ""}} {
    
    global SmodeVars
    
    set app $SmodeVars(application)
    
    if {($command eq "")} {
	set command [prompt "local $app application help for ... " [getSelect]]
	# set command [statusPrompt "local S application help for ... " ] 
    }
    S::processSelection "help ($command,  htmlhelp=TRUE)" "$app"
    return
}

# proc S::localCommandHelp {{command ""} {app ""}} {
#     
#     global SmodeVars tcl_platform
#     
#     if {($app eq "")} {
#         set app $SmodeVars(application)
#     } 
#     if {($command eq "")} {
#         set command [prompt "local $app application help for ... " [getSelect]]
#         # set command [statusPrompt "local S-Plus application help for ..." ]
#     }
#     set pf $tcl_platform(platform)
#     
#     # We have six possible options here, based on platform and application.
#     # For each option, we want to create the path to the help file.
#     
#     if {($pf eq "macintosh")} {
#         # We'll kill this right now.  The rest is for future code ...
#         S::betaMessage 
#         # Make sure that the Macintosh application for the signature exists.
#         if {[catch {[nameFromAppl [S::sig $app]]}]} {
#             S::setApplication $app
#         } 
#         if {($SmodeVars(application) eq "R")} {
#             # Macintosh, R
#         } else {
#             # Macintosh, S+
#         }
#     } elseif {($pf eq "windows") || ($pf eq "unix")} {
#         # Make sure that the Windows application for the signature exists. 
#         # We assume that this will work for unix, too.
#         if {![file exists [S::sig $app]]} {
#             S::setApplication $app
#         } 
#         if {($SmodeVars(application) eq "R")} {
#             # Windows, R
#             set appRoot  [file dirname [file dirname [S::sig]]]
#             set helpLib  [file join $appRoot library base html]
#             set helpFile [file join $helpLib ${command}.html]
#         } else {
#             # Windows, S+
#             S::betaMessage
#         }
#     }
#     # Now we look for the actual help file.
#     if {![file exists $helpFile]} {
#         beep
#         status::msg "Sorry, no help file for '$command' was found."
#         error "No help file found for '$command'."
#     } else {
#         help::openFile $helpFile 
#     } 
#     return
# }


# ===========================================================================
#
# ×××× Mark File and Parse Functions ×××× #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "S::MarkFile" --
 # 
 # This will return the first 35 characters from the first non-commented word
 # that appears in column 0.  All other output files (those not recognized)
 # will take into account the additional left margin elements added by S+/R.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::MarkFile {args} {
    
    global SmodeVars
    
    win::parseArgs w {type ""}
    
    status::msg "Marking \"[win::Tail $w]\" É"
    
    set pos [minPos -w $w]
    set count1 0
    set count2 0
    # Figure out what type of file this is -- source, or output.
    # The variable "type" refers to a call from the S menu.
    # Otherwise we try to figure out the type based on the file's suffix.
    if {($type eq "")} {
	if {([win::Tail $w] eq "* S Mode Example *")} {
	    # Special case for Mode Examples, but only if called from
	    # Marks menu.  (Called from S menu, "type" will over-ride.)
	    set type  ".s"
	} else {
	    set type [string tolower [file extension [win::Tail $w]]]
	}
    }
    # Now set the mark regexp.
    if {$type eq ".s" || $type eq ".r"} {
	# Source file.
	if {!$SmodeVars(markHeadingsOnly)} {
	    set markExpr {^(###[ ]|####[ ])?[-\w]}
	} else {
	    set markExpr {^####*[\t ][^\r\n\t ]}
	}
    } else {
	# None of the above, so assume that it's output
	set markExpr {^(> )+(###[ ]|####[ ])?[-a-zA-Z0-9]}
    }
    # Mark the file
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1 $markExpr $pos} match]} {
	set pos0 [lindex $match 0]
	set pos1 [pos::nextLineStart -w $w $pos0]
	set mark "  [string trimright [getText -w $w $pos0 $pos1]]"
	# Get rid of the leading "> " for output files.
	regsub {^ *>} $mark {} mark
	if {[regexp -- {^\s*#+\s*-+\s*$} $mark]} {
	    set mark "-"
	} elseif {[regsub {  #### } $mark {* } mark]} {
	    incr count2
	} elseif {[regsub {  ### } $mark {¥ } mark]} {
	    incr count2
	} else {
	    incr count1
	}
	# Truncate if necessary.
	set mark [markTrim $mark]
	while {[lcontains marks $mark]} {
	    append mark " "
	}
	lappend marks $mark
	setNamedMark -w $w $mark $pos0 $pos0 $pos0
	set pos $pos1
    }
    # Report how many marks we created.
    if {!$SmodeVars(markHeadingsOnly)} {
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
 # "S::parseFuncs" --
 # 
 # Borrowed from C++, with modifications.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::parseFuncs {} {
    
    global sortFuncsMenu
    
    set funcExpr  {[A-Za-z0-9~_.]+[A-Za-z0-9~_.]+[\t ]*\(}
    set parseExpr {\b([-\w_:.]+)[\t ]*\(}
    
    set pos [minPos]
    set m {}
    while {([set result [search -s -f 1 -r 1 -i 0 -n $funcExpr $pos]] ne "")} {
	set pos1 [lindex $result 0]
	set pos2 [lindex $result 1]
	regexp -- $parseExpr [getText $pos1 $pos2] match command
	# Get the line that contains this command.
	set commandLine [getText [lineStart $pos1] $pos2]
	# Strip off anything after the first valid comment.
	regsub -all {\\\#} $commandLine { } commandLine
	if {[regexp {\#} $commandLine]} {
	    set firstComment [string first {#} $commandLine]
	    set commandLine [string range $commandLine 0 $firstComment]
	}
	if {[regexp $command $commandLine]} {
	    # The command is still in the line.
	    lappend m [list $command $pos1]
	}
	set pos [nextLineStart $pos2]
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
# ×××× S Menu ×××× #
# 

proc sMenu {} {}

# Tell Alpha what procedures to use to build all menus, submenus.

menu::buildProc sMenu  S::buildMenu     S::postBuildMenu
menu::buildProc s+Help S::buildHelpMenu
menu::buildProc rHelp  S::buildHelpMenu

# First build the main S+ menu.

proc S::buildMenu {} {
    
    global sMenu SmodeVars 
    
    variable prefsInMenu
    
    set app    $SmodeVars(application)
    set lowApp [string tolower $SmodeVars(application)]
    
    set optionItems [concat $prefsInMenu "(-)" "r" "s+"]
    set keywordItems [list \
      "listKeywords" "checkKeywordsÉ" "addNewCommandsÉ" "addNewArgumentsÉ"]
    set markItems [list "source" "output"]
    set menuList [list \
      "${lowApp}HomePage" \
      "switchTo${app}" \
      "/P<U<OprocessFile" \
      "/P<U<O<BprocessSelection" \
      "(-)" \
      [list Menu -n ${lowApp}Help -M S {}] \
      [list Menu -n ${lowApp}ModeOptions  -p S::menuProc -M S $optionItems] \
      [list Menu -n ${lowApp}ModeKeywords -p S::menuProc -M S $keywordItems] \
      [list Menu -n mark${app}FileAs   -p S::menuProc -M S $markItems] \
      "(-)" \
      "/b<UcontinueCommand" \
      "/'<E<S<BnewComment" \
      "/'<S<O<BcommentTemplateÉ" \
      "(-" \
      "/N<U<BnextCommand" \
      "/P<U<BprevCommand" \
      "/S<U<BselectCommand" \
      "/I<B<OreformatCommand" \
      ]
    set submenus [list ${lowApp}Help]
    return       [list build $menuList "S::menuProc -M S" $submenus $sMenu]
}

# Then build the "S+ Help" submenu.

proc S::buildHelpMenu {} {
    
    global SmodeVars 
    
    # Determine which key should be used for "Help", with F8 as option.
    if {!$SmodeVars(noHelpKey)} {
	set key "/t"
    } else {
	set key "/l"
    }
    
    # Reverse the local, www key bindings depending on the value of the
    # 'Local Help" variable.
    if {!$SmodeVars(localHelp)} {
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
    lappend menuList "(-)"
    lappend menuList "setRApplicationÉ"
    lappend menuList "setS+ApplicationÉ"
    lappend menuList "(-)"
    lappend menuList "${key}<BsModeHelp"
    
    return [list build $menuList "S::menuProc -M S" {}]
}

proc S::rebuildMenu {{menuName "sMenu"} {pref ""}} {
    menu::buildSome $menuName
    return
}

# Mark or dim items as necessary.

proc S::postBuildMenu {args} {
    
    global SmodeVars 
    
    variable prefsInMenu
    
    set lowApp [string tolower $SmodeVars(application)]
    foreach itemName $prefsInMenu {
	if {[info exists SmodeVars($itemName)]} {
	    markMenuItem ${lowApp}ModeOptions $itemName $SmodeVars($itemName) Ã
	}
    }
    if {($lowApp eq "s+")} {
	markMenuItem ${lowApp}ModeOptions s+ 1 ¥
	markMenuItem ${lowApp}ModeOptions r  0 ¥
    } else {
	markMenuItem ${lowApp}ModeOptions s+ 0 ¥
	markMenuItem ${lowApp}ModeOptions r  1 ¥
    }
    return
}

# Now we actually build the S+ menu.

menu::buildSome sMenu

# Dim some menu items when there are no open windows.

proc S::registerOWH {{which "register"}} {
    
    global sMenu
    
    set menuItems {
	processFile processSelection continueCommand
	markS+FileAs markRFileAs newComment commentTemplateÉ
	nextCommand prevCommand selectCommand reformatCommand
    }
    foreach i $menuItems {
	hook::${which} requireOpenWindowsHook [list $sMenu $i] 1
    }
    return
}

# Call this now.
S::registerOWH register
rename S::registerOWH ""

# ===========================================================================
# 
# ×××× S-Plus menu support ×××× #
# 

# This is the procedure called for all main menu items.

proc S::menuProc {menuName itemName} {
    
    global Scmds SmodeVars mode
    
    variable prefsInMenu
    
    switch $menuName {
	"rHelp" -
	"s+Help" -
	"sHelp" {
	    switch $itemName {
		"setS+Application" {S::setApplication "S+"}
		"setRApplication"  {S::setApplication "R"}
		"sModeHelp"        {package::helpWindow "S"}
		default            {S::$itemName}
	    }
	}
	"rModeOptions" -
	"s+ModeOptions" -
	"sModeOptions" {
	    if {[getModifiers]} {
		if {($itemName eq "r") || ($itemName eq "s+")} {
		    set helpText "Use this item to switch the default application."
		} else {
		    set helpText [help::prefString $itemName "S"]
		    if {$SmodeVars($itemName)} {
			set end "on"
		    } else {
			set end "off"
		    }
		    if {($end eq "on")} {
			regsub {^.*\|\|} $helpText {} helpText
		    } else {
			regsub {\|\|.*$} $helpText {} helpText
		    }
		    set msg "The '$itemName' preference for S mode is currently $end."
		}
		dialog::alert "${helpText}."
	    } elseif {[lcontains prefsInMenu $itemName]} {
		set SmodeVars($itemName) [expr {$SmodeVars($itemName) ? 0 : 1}]
		if {($mode eq "S")} {
		    synchroniseModeVar $itemName $SmodeVars($itemName)
		} else {
		    prefs::modified SmodeVars($itemName)
		}
		if {[regexp {Help} $itemName]} {
		    S::rebuildMenu "s+Help"
		    S::rebuildMenu "rHelp"
		} elseif {($itemName eq "useMassLibrary")} {
		    S::colorizeS
		}
		S::postBuildMenu
		if {$SmodeVars($itemName)} {
		    set end "on"
		} else {
		    set end "off"
		}
		set msg "The '$itemName' preference is now $end."
	    } elseif {($itemName eq "r") || ($itemName eq "s+")} {
		set newApp [string toupper $itemName]
		set SmodeVars(application) $newApp
		prefs::modified SmodeVars(application)
		S::rebuildMenu
		set msg "Default application is now $newApp."
	    } else {
		error "Cancelled -- don't know what to do with '$itemName'."
	    }
	    if {[info exists msg]} {
		status::msg $msg
	    }
	}
	"rModeKeywords" -
	"s+ModeKeywords" -
	"sModeKeywords" {
	    if {($itemName eq "listKeywords")} {
		set p "Current Stata mode keywordsÉ"
		set keywords [listpick -l -p $p $Scmds]
		foreach keyword $keywords {
		    S::checkKeywords $keyword
		}
	    } elseif {($itemName eq "addNewCommands") || ($itemName eq "addNewArguments")} {
		set itemName [string trimleft $itemName "addNew"]
		if {($itemName eq "Commands") && [llength [winNames]] && [askyesno \
		  "Would you like to add all of the 'extra' commands from this window\
		  to the 'Add Commands' preference?"]} {
		    S::addWindowCommands
		} else {
		    S::addKeywords $itemName
		}
	    } else {
		S::$itemName
	    }
	    return
	}
	"markRFileAs" -
	"markS+FileAs" -
	"markSFileAs" {
	    removeAllMarks
	    switch $itemName {
		"source"    {S::MarkFile ".s"}
		"output"    {S::MarkFile ".out"}
	    }
	}
	default {
	    switch $itemName {
		"s+HomePage"      {url::execute $SmodeVars(s+HomePage)}
		"rHomePage"       {url::execute $SmodeVars(rHomePage)}
		"switchToS+"      {app::launchFore [S::sig "S+"]}
		"switchToR"       {app::launchFore [S::sig "R"]}
		"newComment"      {comment::newComment 0}
		"commentTemplate" {comment::commentTemplate}
		"nextCommand"     {function::next}
		"prevCommand"     {function::prev}
		"selectCommand"   {function::select}
		"reformatCommand" {function::reformat}
		default           {S::$itemName}
	    }
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "S::betaMessage" --
 # 
 # Give a beta message for untested features / menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::betaMessage {{item ""}} {
    
    if {($item eq "")} {
	if {[catch {info level -1} item]} {
	    set item "this item"
	}
    }
    error "Cancelled.  Sorry -- '$item' has not been implemented yet."
}

## 
 # --------------------------------------------------------------------------
 # 
 # "S::sig" --
 # 
 # Return the S+ / R signature.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::sig {{app "S+"}} {
    
    global SmodeVars tcl_platform
    
    if {($app eq "")} {
	set app $SmodeVars(application)
    }
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    set pf     $tcl_platform(platform)
    
    if {($pf eq "macintosh") || ($pf eq "unix")} {
	# Make sure that the Macintosh application for the signature exists.
	if {[catch {nameFromAppl $SmodeVars(${lowApp}Sig)}]} {
	    alertnote "Looking for the $capApp application ..."
	    S::setApplication $lowApp
	}
    } elseif {($pf eq "windows")} {
	# Make sure that the Windows application for the signature exists. 
	if {![file exists $SmodeVars(${lowApp}Sig)]} {
	    alertnote "Looking for the $capApp application ..."
	    S::setApplication $lowApp
	}
    } elseif {($pf eq "unix")} {
    }
    return $SmodeVars(${lowApp}Sig)
}

## 
 # --------------------------------------------------------------------------
 # 
 # "S::setApplication" --
 # 
 # Prompt the user to locate the local S application.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::setApplication {{app ""}} {
    
    global SmodeVars
    
    if {($app eq "")} {
	set app $SmodeVars(application)
    }
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    
    set newSig ""
    set newSig [dialog::askFindApp $capApp $SmodeVars(${lowApp}Sig)]
    
    if {($newSig ne "")} {
	set SmodeVars(${lowApp}Sig) "$newSig"
	prefs::modified SmodeVars(${lowApp}Sig)
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
 # "S::addWindowCommands" --
 # 
 # Add all of the "extra" commands which appear in entries in this window.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::addWindowCommands {} {
    
    global Scmds SmodeVars
    
    if {![llength [winNames]]} {
	status::msg "Cancelled -- no current window!"
	return
    }
    
    status::msg "Scanning [win::CurrentTail] for all commandsÉ"
    
    set pos  [minPos]
    set pat1 {[A-Za-z0-9~_.]+[A-Za-z0-9~_.]+[\t ]*\(}
    set pat2 {\b([-\w_:.]+)\s*\(}
    while {![catch {search -s -f 1 -r 1 $pat1 $pos} match]} {
	set pos  [nextLineStart [lindex $match 1]]
	set pos1 [lindex $match 0]
	set pos2 [lindex $match 1]
	regexp -- $pat2 [getText $pos1 $pos2] match aCommand
	# Get the line that contains this command.
	set commandLine [getText [lineStart $pos1] $pos2]
	# Strip off anything after the first valid comment.
	regsub -all {\\\#} $commandLine { } commandLine
	if {[regexp {\#} $commandLine]} {
	    set firstComment [string first {#} $commandLine]
	    set commandLine [string range $commandLine 0 $firstComment]
	}
	if {[regexp $aCommand $commandLine] && ![lcontains Scmds $aCommand]} {
	    # The command is still in the line, and not recognized.
	    append SmodeVars(addCommands) " $aCommand"
	}
    }
    set SmodeVars(addCommands) [lsort -unique $SmodeVars(addCommands)]
    prefs::modified SmodeVars(addCommands)
    if {[llength $SmodeVars(addCommands)]} {
	S::colorizeS
	listpick -p "The 'Add Commands' preference includes:" \
	  $SmodeVars(addCommands)
	status::msg "Use the 'Mode Prefs > Preferences' menu item to edit keyword lists."
    } else {
	status::msg "No 'extra' commands from this window were found."
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "S::addKeywords" --
 # 
 # Prompt the user to add keywords for a given category.  Query existing
 # lists of keywords, and add to the mode preferences.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::addKeywords {category {keywords ""}} {
    
    global SmodeVars
    
    if {($keywords eq "")} {
	set keywords [prompt "Enter new $SmodeVars(application) $category:" ""]
    }
    
    # Check to see if the keyword is already defined.
    foreach keyword $keywords {
	set checkStatus [S::checkKeywords $keyword 1 0]
	if {($checkStatus ne 0)} {
	    alertnote "Sorry, '$keyword' is already defined\
	      in the $checkStatus list."
	    error "cancel"
	}
    }
    # Keywords are all new, so add them to the appropriate mode preference.
    append SmodeVars(add$category) " $keywords"
    set SmodeVars(add$category) [lsort $SmodeVars(add$category)]
    prefs::modified SmodeVars(add$category)
    S::colorizeS
    status::msg "'$keywords' added to $category preference."
    return
}

proc S::checkKeywords {{newKeywordList ""} {quietly 0} {noPrefs 0}} {
    
    global SmodeVars
    
    global SUserCommands SUserArguments
    
    variable keywordLists
    
    set type ""
    if {($newKeywordList eq "")} {
	set quietly 0
	set newKeywordList [prompt "Enter S mode keywords to be checked:" ""]
    }
    # Check to see if the new keyword(s) is already defined.
    foreach newKeyword $newKeywordList {
	if {[(lcontains keywordLists(commands) $newKeyword)] != "-1"} {
	    set type "default commands"
	} elseif {([lcontains SUserCommands $newKeyword] != "-1")} {
	    set type "\$SUserCommands"
	} elseif {([lcontains keywordLists(arguments) $newKeyword] != "-1")} {
	    set type "default arguments"
	} elseif {([lcontains SUserArguments $newKeyword] != "-1")} {
	    set type "\$SUserArguments"
	} elseif {([lcontains keywordLists(MASS) $newKeyword] != "-1")} {
	    set type "default MASS"
	} elseif {(!$noPrefs && \
	  [lcontains SmodeVars(addCommands) $newKeyword] != "-1")} {
	    set type "Add Commands preference"
	} elseif {(!$noPrefs && \
	  [lcontains SmodeVars(addArguments) $newKeyword] != "-1")} {
	    set type "Add Arguments preference"
	}
	if {$quietly} {
	    # When this is called from other code, it should only contain
	    # one keyword to be checked, and we'll return it's type.
	    return "$type"
	} elseif {!$quietly && $type eq ""} {
	    alertnote "'$newKeyword' is not currently defined\
	      as a S mode keyword"
	} elseif {$type ne ""} {
	    # This will work for any other value for "quietly", such as 2
	    alertnote "'$newKeyword' is currently defined as a keyword\
	      in the '$type' list."
	}
	set type ""
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
 # "S::processFile" --
 # 
 # Send entire file to S+ / R for processing, adding carriage return at end
 # of file if necessary.
 # 
 # Optional "f" argument allows this to be called by other code, or to be
 # sent via a Tcl shell window.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::processFile {{f ""} {app ""}} {
    
    global SmodeVars
    
    if {($f ne "")} {
	file::openAny $f
    }
    set f [win::Current]
    
    if {($app eq "")} {
	set app $SmodeVars(application)
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
    if {!$dontSave && ([lookAt [pos::math [maxPos] - 1]] ne "\r")} {
	set pos [getPos]
	goto [maxPos]
	insertText "\r"
	goto $pos
	alertnote "Carriage return added to end of file."
	save
    }
    
    app::launchBack '[S::sig $capApp]'
    sendOpenEvent noReply '[S::sig $capApp]' $f
    switchTo '[S::sig $capApp]'
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "S::processSelection" --
 # 
 # Procedure to implement transfer of selected lines to S+/R for processing.
 # 
 # --------------------------------------------------------------------------
 ##

proc S::processSelection {{selection ""} {app ""}} {
    
    global SmodeVars
    
    if {($app eq "")} {
	set app $SmodeVars(application)
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
    set tempDir [temp::directory S]
    set newFile [file join $tempDir temp-S.s]
    file::writeAll $newFile $selection 1
    
    app::launchBack '[S::sig $capApp]'
    sendOpenEvent noReply '[S::sig $capApp]' $newFile
    switchTo '[S::sig $capApp]'
    return
}

proc S::quitHook {} {
    temp::cleanup S
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
# 01/28/20 cbu 1.0.1  First created S mode, based upon other modes found 
#                       in Alpha's distribution.   Commands are based on 
#                       release number 3.3, taken from the "common commands" 
#                       as listed in Venable and Ripley's "Modern Applied 
#                       Statistics with S-PLUS", second edition.
# 03/02/20 cbu 1.0.2  Minor modifications to comment handling.
# 03/20/00 cbu 1.0.3  Minor update of keywords dictionaries.
#                     Removed markFile and parseFuncs procs, because they're 
#                       not stable or properly worked out.
# 04/01/00 cbu 1.0.4  Fixed a little bug with "comment box".
#                     Added new preferences to allow the user to optionally 
#                       use $ as a Magic Character, and to enter additional 
#                       commands and options.  
#                     Removed the "Either/Ors" category, put them into arguments.
#                     Added the C++ MarkFile and parseFuncs procs.
#                     Added "Update Colors" proc to avoid need for a restart
# 04/08/00 cbu 1.0.5  Unset obsolete preferences from earlier versions.
#                     Added "Continue Comment" and "Electric Return Over-ride".
#                     Renamed "Update Colors" to "Update Preferences".
#                     Added the tcl indentation routines.
# 04/16/00 cbu 1.1    Renamed to sMode.tcl
#                     Wrote my own "Mark File" proc, replaced the C++ MarkFile.
#                     Removed indentation routines, at least for now.
# 06/22/00 cbu 1.2    "Mark File" now recognizes headings as well as commands.
#                     Completions, Completions Tutorial added.
#                     "Reload Completions", referenced by "Update Preferences".
#                     Better support for user defined keywords.
#                     Removed "Continue Comment", now global in Alpha 7.4.
#                     Added command double-click for on-line help.
#                     <shift, control>-<command> double-click syntax info.
#                       (Foundations, at least.  Ongoing project.)
# 08/07/00 cbu 1.2.1  DblClick now looks for variable (etc) definitions
#                       in current file.
#                     Added message if no matching ")".
#                     Mark File can mark a frequencies file.
#                     Beta-version of an S-Plus menu, based on the Stata menu.
#                       No Macintosh versions of S-Plus or R limit its
#                       functionality ...
#                     Added "s+Sig" preference to allow user to find
#                       local application if necessary, in case S+/R is ever
#                       ported to the Macintosh.
#                     Added S::sig which returns S-Plus signature.
# 08/28/00 cbu 1.2.2  Added some of the flag preferences to "S+/R Help" menu.
#                     Added "flagFlip" to update preference bullets in menu.
#                     Added "application" preference, used in menu.
#                     Added "rSig" preference.
#                     Added a "noHelpKey" preference, which switches the
#                       "help" key binding to F8.
#                     Added "Add New Commands / Arguments" to "S+/R Help" menu.
#                     Added "Set S+/R Application to "S+/R Help" menu.
#                     Starting to differentiate code based on platform.
#                     Including a "beta message" for untested menu items.
# 11/05/00 cbu 1.3    Added "next/prevCommand", "selectCommand", and
#                       "copyCommand" procs to menu.
#                     Added "S::indentLine".
#                     Added "S::reformatCommand" to menu.
#                     Added "S::continueCommand" to over-ride indents. 
#                     "S::reloadCompletions" is now obsolete.
#                     "S::updatePreferences" is now obsolete.
#                     "S::colorizeS" now takes care of setting all 
#                       keyword lists, including Scmds.
#                     Cleaned up completion procs.  This file never has to be
#                       reloaded.  (Similar cleaning up for "S::DblClick").
# 11/16/00 cbu 2.0    New url prefs handling requires 7.4b21
#                     Added "Home Page" pref, menu item.
#                     Removed  hook::register requireOpenWindowsHook from
#                       mode declaration, put it after menu build.
# 12/19/00 cbu 2.1    The menu proc "Add Commands" now includes an option
#                       to grab all of the "extra" command from the current
#                       window, using S::addWindowCommands.
#                     Added "Keywords" submenu, "List Keywords" menu item.
#                     Big cleanup of ::sig, ::setApplication, processing ...
# 01/25/01 cbu 2.1.1  Bug fix for S::processSelection/File.
#                     Bug fix for comment characters.
# 09/26/01 cbu 2.2    Big cleanup, enabled by new 'functions.tcl' procs.
# 10/31/01 cbu 2.2.1  Minor bug fixes.
# 10/16/03 cbu 2.2.3  S+/R interactions are only available in MacClassic,
#                       until I can come up with a proper cross-platform
#                       implementation.  Might use the "xserv" package.
# 10/17/03 af  2.2.4  Fixing failure to switch to R/S application (Bugzilla bug #?) 
#                       under OSX in proc [S::sig].
#                     Updated urls for home pages, help.
# 10/18/05 cbu 2.3    Keywords lists are defined in S namespace variables.
#                     Minor updates to keyword lists.
#                     pdf() will signal indentation increase.
#                     Canonical Tcl formatting changes.
#                     New "markHeadingsOnly" preference.
#                     Using [prefs::dialogs::setPaneLists] for preferences.
#

# ===========================================================================
# 
# .