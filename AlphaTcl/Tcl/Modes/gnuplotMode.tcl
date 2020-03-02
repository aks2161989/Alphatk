## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # "gnuplotMode.tcl"
 #                                          created: 08/01/1995 {07:59:36 PM}
 #                                      last update: 05/23/2006 {10:36:49 AM}
 # Description:                                     
 # 
 # gnuplotMode.tcl, Version 2.0 For gnuplot 3.6
 # 
 # This is a set of TCL proc's that allow the shareware Macintosh text editor
 # Alpha to serve as a front end for GNUPLOT for Macintosh version 3.6.  This
 # script requires Alpha 7.4 or later.
 # 
 # This mode was written by Jeff Schindall.  Some code was pinched from other
 # TCL files distributed with Alpha and matlab.tcl.
 # 
 # Just use 'shift-ctrl-g' to launch a gnuplot console.
 #                                
 # Author: Jeff Schindall
 # E-mail: <mailto:schindall@nrl.navy.mil>
 #   mail: Naval Research Laboratory
 #         Acoustics Division --- Code 7120
 #         4555 Overlook Ave SW
 #         Washington, DC, 20375 USA ]
 # 
 # (Note: Vince updated this file for use with Alpha 7.1b10)
 # (Note: Craig updated this file for use with Alpha 7.4)
 # 
 # ==========================================================================
 ##

# ===========================================================================
#
# Autoload procedures
#

alpha::mode [list GPLT Gnuplot] 2.1.3 gnuplotMenu {
    *.gp *.gnu *.gnp *.gplt
} {
    gnuplotMenu
} {
    # Script to execute at Alpha startup
    addMenu gnuplotMenu "¥415" GPLT
    set modeCreator(GPLT) GPLT
    set modeCreator(GPSE) GPLT
    if {$alpha::macos} {
	# This mode's communication relies entirely on apple-events,
	# so this sig just isn't relevant to Windows/Unix.
	newPref sig GnuplotSig GPLT
    }
} uninstall {
    this-file
} maintainer {
    "Jeff Schindall" <jeff@wave.nrl.navy.mil>
} description {
    Supports the editing of Gnuplot programming files
} help {
    Gnuplot is a command-line driven interactive function plotting utility for
    UNIX, MSDOS, and VMS platforms.  The software is copyrighted but freely
    distributed (i.e., you don't have to pay for it).  It was originally
    intended as a graphical program which would allow scientists and students
    to visualize mathematical functions and data.

                                                -- <http://www.gnuplot.info/>

    Gnuplot Mode serves as a front end for GNUPLOT for Macintosh version 3.6.
    Alpha acts as Gnuplot's console window.  You can activate the console with
    Command-L or using the Console menu item in the mode's Gnuplot menu.  When
    in console mode you have access to Gnuplot's built-in help.

    A simple floating menu lists all text files in the scripts directory of
    gnuplot home dir.  To run a script, just select it from the scripts menu.
    To edit a script in Alpha, select a script menu item while pressing any
    modifier key (Shift, Option, Command, or Control).

    You can modify some of the GPLT mode behaviour by selecting the menu item
    "Config > GPLT Mode Prefs > Preferences".
    
    Preferences: Mode-GPLT

    Comments, suggestions, and bug reports are always welcome, feel free to
    contact this package's current maintainer.
}

proc gnuplotMode.tcl {} {}

proc gnuplotMenu {} {}

namespace eval GPLT {}

# Would do well to remove some of these
hook::register mode::init              GPLT::graphButton          GPLT
hook::register mode::init              GPLT::offSet               GPLT
hook::register mode::editPrefsFile     GPLT::editCurrentModePrefs GPLT
hook::register closeHook               GPLT::closeHook            GPLT
hook::register deactivateHook          GPLT::deactivateHook       GPLT
hook::register activateHook            GPLT::activateHook         GPLT

# Temporary stuff -- hopefully remove in the future.
set gp_cwd "???"

# ===========================================================================
#
# ×××× GPLT mode preferences ×××× #
# 

# ===========================================================================
#
# remove unused, previously saved preferences
# 

# remove unused, previously saved preferences
# 

foreach oldvar [list FSIG CREA TYPE] {
    prefs::removeObsolete GPLTmodeVars($oldvar)
}
unset oldvar

# ===========================================================================
#

# ===========================================================================
#
# Standard preferences recognized by various Alpha procs
#

newPref var  prefixString {# } GPLT
newPref var  tabSize {3} GPLT
newPref var  prefixString {# } GPLT
newPref var  wordBreak {\w+} GPLT
newPref var  lineWrap {0} GPLT
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 GPLT

# ===========================================================================
#
# Flag preferences
#

newPref flag NevrSavHist {0} GPLT
newPref flag LiveHist {1} GPLT       GPLT::updatePreferences
newPref flag GraphButton {1} GPLT    GPLT::updatePreferences
newPref flag EventHandler {1} GPLT   GPLT::updatePreferences

# ===========================================================================
#
# Variable preferences
#

# The "Gnuplot Home Page" menu item will send this url to your browser.
newPref url gnuplotHomePage      {http://www.cs.dartmouth.edu/gnuplot_info.html}      GPLT

# ===========================================================================
#
# Color preferences
#

newPref color bracesColor blue   GPLT  {GPLT::colorizeGPLT}
newPref color commandColor blue  GPLT  {GPLT::colorizeGPLT}
newPref color commentColor red   GPLT  {stringColorProc}
newPref color stringColor green  GPLT  {stringColorProc}

regModeKeywords -C {GPLT} {}
regModeKeywords -a -e {#} \
  -c $GPLTmodeVars(commentColor) \
  -s $GPLTmodeVars(stringColor) GPLT {}
  
### Commands ###

set gpCommands { 
    \\ console set show plot splot autoscale binary boxxyerrorbars bugs
    call cd clear co-ordinates comments environment exit expressions fit if
    introduction line-editing load pause plot print pwd quit replot reread
    reset save seeking-assistance set shell show splot startup style
    substitution test update userdefined xyerrorbars xerrorbars yerrorbars

    "Copyright(C) 1986 - 1997" 
    "Copyright(C) 1986 - 1998"
    "Copyright(C) 1986 - 1999"
    "Copyright(C) 1986 - 2000"
    "Copyright(C) 1986 - 2001"
}

### GREEN WORDS ###

set gpGreenWords {
    ranges         smooth         data-file      datafile
    parametric     locale         nosquare       errorbars
    gnuplot        gnuplot>       term           square
    angles         arrow          autoscale      bar
    bmargin        border         boxwidth       clabel
    clip           cntrparam      contour        data
    dgrid3d        dummy          encoding       format
    function       grid           hidden3d       isosamples
    key            keytitle       label          lmargin
    logscale       mapping        margin         missing
    multiplot      mx2tics        mxtics         my2tics
    mytics         mztics         noarrow        noautoscale
    noborder       noclabel       noclip         nodgrid3d
    nokey          nolabel        nologscale     nomultiplot
    nomx2tics      nomxtics       nomy2tics      nomytics
    nomztics       noparametric   nopolar        nosurface
    nox2dtics      nox2mtics      nox2tics       nox2zeroaxis
    noxdtics       noxmtics       noxtics        noxzeroaxis
    noy2dtics      noy2mtics      noy2tics       noy2zeroaxis
    noydtics       noymtics       noytics        noyzeroaxis
    nozdtics       nozeroaxis     nozmtics       noztics
    offsets        origin         output         parametric
    pointsize      polar          punctuation    rmargin
    rrange         samples        size           specify
    style          surface        syntax         terminal
    tics           ticscale       ticslevel      time
    timefmt        title          tmargin        trange
    urange         view           vrange         x2dtics
    x2label        x2mtics        x2range        x2tics
    x2zeroaxis     xdata          xdtics         xlabel
    xmtics         xrange         xtics          xzeroaxis
    y2dtics        y2label        y2mtics        y2range
    y2tics         y2zeroaxis     ydtics         ylabel
    ymtics         yrange         ytics          yzeroaxis
    zdtics         zero           zeroaxis       zlabel
    zmtics         zrange         ztics
    threaded
}

### CYAN WORDS ###

set gpCyanWords  {   
    post mac     macintosh      texdraw
    aifm           atari          dumb           enhpost
    epson          epson180       epson60        fig
    gpic           hpljii         imagen         iris4d
    latex          linux          mf             mif
    mtos           nec-cp6        pbm            pcl5
    postscript     pslatex        regis          starc
    table          tandy60        tgif           uniplex
    vdi            windows        unknown        pstricks
    png            dxf            cgm            gif
    emtex          pstex          eepic          tpic
    pstricks       texdraw
}

# ===========================================================================
#
#
# Color keywords for GPLT mode
#

proc GPLT::colorizeGPLT {{pref ""}} {
    
    global GPLTmodeVars gpCommands gpGreenWords gpCyanWords GPLTcmds
    
    set GPLTcmds [lsort -unique [concat \
      $gpCommands $gpGreenWords $gpCyanWords \
      ]]

    regModeKeywords -a \
      -i "\}" -i "\{"  -i ">" -i "<" -i ")" -i "("  -i "/" -i "\\"  \
      -i "\]" -i "\[" -i "\$" -i "\'" -i "\`" -i ">" -i "<" -i "^" -i "_" \
      -I $GPLTmodeVars(bracesColor) \
      -k $GPLTmodeVars(commandColor) GPLT $gpCommands
    regModeKeywords -a -k green GPLT $gpGreenWords
    regModeKeywords -a -k cyan  GPLT $gpCyanWords
    if {$pref != ""} {refresh}
}

# Call this now.

GPLT::colorizeGPLT

# ===========================================================================
#
#  global variables
#

ensureset gp_CREA 				 {ALFA}
ensureset gp_TYPE 				 {TEXT}
ensureset gp_CreatorList [list] 
ensureset gp_TypeList [list] 
ensureset gp_CreatorNames [list] 
ensureset gp_GEOM [list]
ensureset gp_HistGEOM [list ]
ensureset headerSuffices {$GPLTmodeSuffixes}
ensureset sourceSuffices {$GPLTmodeSuffixes}

if {[llength $gp_CreatorList] == 0 \
 || [llength $gp_CreatorList] != [llength $gp_CreatorNames] \
 || [llength $gp_CreatorList] != [llength $gp_TypeList]} {
	set gp_CreatorList [list ALFA GPLT]
	set gp_TypeList [list  TEXT TEXT]
	set gp_CreatorNames [list  alpha gnuplot]
	set gp_CREA {ALFA} 
	set gp_TYPE {TEXT}
}

set gp_CommandHist [list]
set gp_CommandNum 0

set gp_Prompt       "gnuplot> "
set gp_MultiPrompt  "multiplot> "
set gp_ContPrompt   "> "
set gp_HelpPrompt   ": "

set gp_Prompts [list $gp_Prompt $gp_ContPrompt $gp_MultiPrompt ]

set gp_Console  "  gnuplot  "
set gp_Hist     "  history  "
set gp_Graph	 "  graph  "
set gp_sl [list]

set gpTermCt 0

set gp_Launched {0}

# ===========================================================================
# 
# ×××× Key Bindings, Electrics ×××× #
# 

# ===========================================================================
#
#  Bind some keys
#

# Editing .gnu files

Bind '\r' <z>  GPLT::doLine             "GPLT"

# Command Window

Bind '\r'      GPLT::carriageReturn     "GPLT"
Bind up        GPLT::prevCommand        "GPLT"
Bind down      GPLT::nextCommand        "GPLT"
Bind '1'  <z>  GPLT::console            "GPLT"
Bind '2'  <z>  GPLT::activate           "GPLT"
Bind '3'  <z>  GPLT::dumpHistory        "GPLT"
Bind 'f'  <sc> GPLT::saveAndExecute     "GPLT"

# Setting the order of precedence for completions.

set completions(GPLT) {
    completion::cmd completion::electric completion::word
}

set GPLTelectrics(plot)   " \[¥¥:¥¥\] \[¥¥:¥¥\] ¥¥\r¥¥"
set GPLTelectrics(set)    " ¥¥ \[¥¥: ¥¥\]¥¥\r¥¥"
set GPLTelectrics(pause)  " ¥¥ \"¥¥\"\r¥¥"

# ===========================================================================
#
#  Carriage return for command window
#

proc GPLT::carriageReturn {} {
    global gp_CommandHist gp_CommandNum  gp_Console gp_Hist gp_Graph
    
    # enter only if cr in console window...
    set wins [winNames]
    if { [lsearch $wins $gp_Console ]  == 0  } {
	setWinInfo -w $gp_Console dirty 0
	set pos [getPos]

	# I look for > and : instead of the proper prompts... Hmmm...
	# if -1 then we are not on an input line...
	# or we could be waiting for a pause...
	# which should be on the last line...
	set ind [string first ">" [getText [lineStart $pos] $pos] ]
	if {$ind < 0} {
	    set ind [string first ":" [getText [lineStart $pos] $pos] ]
	    if {$ind < 0} {
		endOfBuffer
		# just send a cr to the server
		insertText "\r"
		GPLT::sendCommand [getText [lineStart $pos] $pos] 400
		return
	    }
	}
	set lStart [pos::math [lineStart $pos] + $ind + 2]
	endOfLine
	set lEnd  [getPos]
	set scriptName [getText $lStart $lEnd]
	insertText "\r"
	# if not on last line, then replace text on last line...
	GPLT::sendCommand "$scriptName"  102
    } elseif {[lsearch $wins $gp_Hist ] == 0} {
	# execute the current command in the history window...
	GPLT::histgotoMatch
    } else {
	insertText "\r"
    }
}

# ===========================================================================
# 
# ×××× Command Double Click ×××× #
# 
# In GNUc mode, cmd-double-click highlights area btween consecutive
# gnuplot prompts
#

proc GPLT::DblClick {from to} {
    
    global gp_Prompts
    
    # First find "gnuplot> " prompt above and below cursor entry...
    # don't forget to deal with "multiplot> " and "> "
    
    set gp1 [list]
    foreach gp $gp_Prompts {lappend gp1 [search -s -n -f 0 -r 1 $gp $from] }
    set firstmatch [lindex [lindex $gp1 0 ] 0]
    foreach el $gp1 {
	if {[pos::compare [lindex $el 1] > $firstmatch]} {
	    set firstmatch [lindex $el 0]
	}
    }
    
    if {$firstmatch == {}} {
	status::msg "You are not between prompts"
	return
    } else {

	set firstmatch [nextLineStart $firstmatch]
	endOfBuffer
	set lastmatch [getPos ]
	set gp1 [list]
	foreach gp $gp_Prompts {lappend gp1 [search -s -n -f 1 -r 1 $gp $from] }
	foreach el $gp1 {
	    if {[lindex $el 1]!={} && [pos::compare [lindex $el 0] < $lastmatch] } {
		set lastmatch $el
	    }
	}
	if {$lastmatch == {}} {
	    status::msg "You are not between prompts"
	    return
	} else {
	    
	    goto $lastmatch
	    beginningOfLine
	    selectText $firstmatch [getPos]
	}
    }
}

# ===========================================================================
#
# ×××× Mark File ×××× #
# 

proc GPLT::MarkFile {args} {
    
    win::parseArgs w {type ""}
    
    status::msg "Marking Window É"
    
    set count 0
    set markExpr {^plot([\t ]+\[)}
    # Mark the file
    set pos [minPos -w $w]
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1 $markExpr $pos} match]} {
	incr count
	set pos0 [lindex $match 0]
	set pos1 [pos::nextLineStart -w $w $pos0]
	set mark [markTrim [string trimright [getText -w $w $pos0 $pos1]]]
	while {[lcontains marks mark]} {
	    append mark " "
	}
	lappend marks $mark
	setNamedMark -w $w $mark $pos0 $pos0 $pos0
	set pos $pos1
    }
    status::msg "This file contains $count plot commands."
}

# ×××× --------------------¥ ×××× #

# ===========================================================================
# 
# ×××× Gnuplot Menu Definition ×××× #
# 

# ===========================================================================
#
#  gnuplot Menu
#

Menu -n	$gnuplotMenu -p GPLT::gnuplotMenuProc	{
    "gnuplotHomePage"
    "gnuplotHelp"
    "/S<U<BswitchTo gnuplot"
    "/Q<Uquit gnuplot"
    "(-"
    "/1<Bconsole"
    "/2<Bgraph"
    "/3<Bhistory"
    "(-"
    "<E<SgraphButton"
    "<S<OkillGraphButton"
    "setWorkingFolderÉ"
    "/P<UchoosePlotFileÉ"
    "/L<UloadÉ"
    {Menu -n "saveSettings" -p GPLT::gnuplotMenuProc  {
	"all"
	"(-"
	"setCmds" 
	"functions"
	"variables"
    }}
    "(-"
    "/N<UnewScriptWin"
    "/F<UsaveAndExecute"
    "(-"
    {Menu  -s -m -n mathFunctions -p GPLT::gnuplotMenuProc  {
	{Menu  -s -m -n Trigonometric -p GPLT::gnuplotMenuProc  {
	    "cos"
	    "tan"
	    "sin"
	}}
	{Menu  -s -m -n InverseTrig -p GPLT::gnuplotMenuProc  {
	    "acos"
	    "asin"
	    "atan"	 
	}}
	{Menu  -s -m -n Hyperbolic -p GPLT::gnuplotMenuProc  {
	    "cosh"
	    "sinh"
	    "tanh"
	}}
	{Menu  -s -m -n special -p GPLT::gnuplotMenuProc  {
	    "erf"
	    "erfc"
	    "inverf"
	    "(-"
	    "gamma"
	    "igamma"
	    "lgamma"
	    "(-"
	    "ibeta"
	}}
	{Menu  -s -m -n bessel -p GPLT::gnuplotMenuProc  {
	    "besj0"
	    "besj1"
	    "besy0"
	    "besy1"	 
	}}
	"(-"
	"abs"
	"arg"
	"sgn"
	"sqrt"
	"(-"
	"exp"
	"log"
	"log10"
	"(-"
	"ceil"
	"floor" 
	"rand"
	"norm"
	"invnorm"
	"(-"
	"real" 
	"imag"
	"int"
    }}
    "(-"
    "/M<UdoSelection"
    "doLine"
    "(-"
    {Menu -n gnuplotOptions -p GPLT::gnuplotMenuProc	 {
	"setPointSizeÉ"
	"(-"
	"/H<UclearHistory"
	"(-"
	{Menu -n setOutputCreator -p GPLT::gnuplotMenuProc	 {
	    "selectÉ"
	    "addÉ"
	    "deleteÉ"
	}}
    }}
}

proc GPLT::gnuplotMenuProc {menu item} {
    
    global GPLTmodeVars

    switch $item {
        "add"                           { GPLT::addCreator }
        "all"                           { GPLT::saveSettings "" }
        "choosePlotFile"                { GPLT::choosePlotFile }
        "clearHistory"                  { GPLT::clearHistory }
        "console"                       { GPLT::console }
        "delete"                        { GPLT::deleteCreator }
        "doLine"                        { GPLT::doLine }
        "doSelection"                   { GPLT::doSelection }
        "functions"                     { GPLT::saveSettings "fun" }
        "gnuplot"                       { GPLT::activate }
        "gnuplotHelp"                   { package::helpWindow "GPLT" }
        "gnuplotHomePage"               { url::execute $GPLTmodeVars(gnuplotHomePage)}
        "graph"                         { GPLT::activate }
        "graphButton"                   { GPLT::killGraphButton ; GPLT::graphButton 1 } 
        "gxText"                        { GPLT::dialog "gxtx" }
        "history"                       { GPLT::dumpHistory }
        "killGraphButton"               { GPLT::killGraphButton }
        "labels"                        { GPLT::dialog "labl" }
        "labels"                        { GPLT::dialog "labl" }
        "line styles"                   { GPLT::dialog "line" }
        "load"                          { GPLT::loadScript }
        "newScriptWin"                  { GPLT::newWindow }
        "offsets"                       { GPLT::dialog "oset" }
        "quitgnuplot"                   { GPLT::quit }
        "saveAndExecute"                { GPLT::saveAndExecute }
        "select"                        { GPLT::selectCreator }
        "setCmds"                       { GPLT::saveSettings "set" }
        "setPointSize"                  { GPLT::setPTSZ }
        "setWorkingFolder"              { GPLT::setCWD }
        "switchTognuplot"               { GPLT::activate }
        "text format"                   { GPLT::dialog "text" }
        "variables"                     { GPLT::saveSettings "var" }
        default                         {
            insertText [string tolower $item ] ()
            backwardChar
        }
    }
}

# ===========================================================================
# 
# ×××× Event Handlers ×××× #
# 

# These only exists on Mac OS (or Mac OS X).
if {${alpha::macos}} {

    proc GPLT::_eventHandler {theAppleEvent theReplyAE} {
	variable eventHandlers
	
	set eventClass [tclAE::getAttributeData $theAppleEvent evcl]
	set eventID [tclAE::getAttributeData $theAppleEvent evid]
	
	if {[catch {set handler [set eventHandlers(${eventClass}${eventID})]}]} {
	    error::throwOSErr -1717
	}
	
	set gizmo [tclAE::print $theAppleEvent]
	# tclAE::print seems to swallow the '\' between the class and event
	set gizmo "[string range $gizmo 0 3]\\[string range $gizmo 4 end]"
	set result [eval $handler $gizmo]
	
	tclAE::putKeyData $theReplyAE ---- TEXT $result
    }

    proc GPLT::makeEventHandler {theAEEventClass theAEEventID handler} {
	variable eventHandlers
	
	set eventHandlers(${theAEEventClass}${theAEEventID}) $handler
	
	# All events get routed through here
	tclAE::installEventHandler $theAEEventClass $theAEEventID GPLT::_eventHandler
    }

# ===========================================================================
#
#  setup the event handler for Alpha/gnuplot interapp communication
#  This file only works with Alpha 7.0 or newer so we assume
#  eventHandling actually works.
#

# Setup event Handler for STDOUT
    GPLT::makeEventHandler GPSE OUTP "GPLT::sTDOUThandler"

# Setup event Handler for systems w/o ThreadManager
    GPLT::makeEventHandler GPSE ERRP "GPLT::sTDERRhandler"

# *ICInitializeCommand // This initializes the console.
# Alpha eventhandler is needed.
# 'GPIC init'
    GPLT::makeEventHandler GPIC init "GPLT::consoleH"
#
# *ICInitializePath // sends the working directory as
# stored in preferences.
# Since you aren't displaying the working directory anywhere,
# we can ignore
# this for now.
# 'GPIC path', contains a string in the direct object.
    GPLT::makeEventHandler GPIC path "GPLT::sendPath"
#
# ICExecute // Tells the console to execute a gnuplot command.
# I can't think
# of a reason for this one in Alpha.  The menuing system uses
# this one in the current console.  We could define an event however.
#
# ICInsertCommand // Might be slick.  An example of what this
# does is where
# functions get pasted into the command line.  Not absolutely necessary
# though.
# 'GPIC' 'inse'
    GPLT::makeEventHandler GPIC inse "GPLT::iNSEhandler"
#
# ICComeToFront  // The function will bring Alpha to the front.
# No handler needed.
#
# *ICBringGnuplotToFront // Handler needed.  When you get this one, bring
# gnuplot to the front.
# 'GPIC tofr'
    GPLT::makeEventHandler GPIC tofr "GPLT::activateH"
#
# *ICHandleAEReply // You'll get this one if somebody used a
# gnuplot menu to
# do something which necessitated a reply from gnuplot. The
# gnuplot interface
# will pass the reply to you for display.
# 'GPIC repl', handle this one just like the reply from your exec event.
    GPLT::makeEventHandler GPIC repl "GPLT::sTDERRhandler"
#
# *ICMakeNewDocument  // It sounds like this one is working already.
# 'core crel'
    GPLT::makeEventHandler core crel "GPLT::newWindowH"
#
# *ICOpenDocument // Alpha already knows about this one.
# --already defined in alpha---

# The event 'GPIC' 'cbye' is now sent whenever gnuplot quits.
# This will let you close the console if somebody quits
# gnuplot some other way. You could
# use this to eliminate your 'quit' trapping if you want.
    GPLT::makeEventHandler GPIC cbye "GPLT::closeH"
# I also defined a new event: 'GPIC' 'EXEC'.  All you need to
# do is take the
# data and send it back to gnuplot as a 'GPSE' 'exec' event.
# This is a kludge
# to make the commands in the gnuplot app menus work.
# It will eventually go away.
    GPLT::makeEventHandler GPIC EXEC "GPLT::kludge"

proc GPLT::kludge {it} {
    set outit  [GPLT::filtercurlyq $it]
    GPLT::sTDERR $outit 3600
    if { $it == "Unable to find process" } GPLT::quit
    return 0
}

proc GPLT::sTDERRhandler {it} {
    set outit  [GPLT::filtercurlyq $it]
    GPLT::extractPath $it
    GPLT::results $outit
    if { $it == "Unable to find process" } GPLT::quit
    return 0
}

proc GPLT::sTDOUThandler {it} {
    global gp_Out gpTermCt
    global gp_Console gp_Graph
    global GPLTmodeVars gp_Launched gp_GEOM
    global gp_Prompt gnuplotMenu
    
    set outit  [GPLT::filtercurlyq $it]
    GPLT::extractPath $it
    set wins [winNames]
    
    set itLen [ string length "$it" ]
    set termID [ string range "$outit" 0 20 ]
    set termType [ string range "$it" [expr $itLen -25] [expr $itLen -1] ]
    
    if { [ string first "Sorry," "$termID" ] == 0 } {
	insertText -w  $gp_Console "\n$outit"
	return

    } elseif { [ string first "% GNUPLOT: LaTeX" "$termID" ] == 0 } {	   
	incr gpTermCt 1
	# set gp_Out [prompt "Enter name of output console?" "* TeX output $gpTermCt *" ]
	set gp_Out "* TeX output $gpTermCt *"
	set theMode "TeX"

    } elseif { [string first "%!PS-Adobe" "$termID" ] == 0 } {
	incr gpTermCt 1
	# set gp_Out [prompt "Enter name of output console?" "* PS output $gpTermCt *" ]
	set gp_Out "* PS output $gpTermCt *"
	set theMode "PS"

    } elseif { [string first "<MIFFile 3.00>" "$termID" ] == 0 } {
	incr gpTermCt 1
	# set gp_Out [prompt "Enter name of output console?" "* MIF output $gpTermCt *" ]
	set gp_Out "* MIF output $gpTermCt *"
	set theMode "PS"

    } elseif { [string first "% GNUPLOT: dxf" "$termID" ] >= 0 } {
	incr gpTermCt 1
	# set gp_Out [prompt "Enter name of output console?" "* misc output $gpTermCt *" ]
	set gp_Out "* misc output $gpTermCt *"
	set theMode "TEXT"

    } elseif { [string first "if unknown cmbase" "$termID" ] == 0 } {
	incr gpTermCt 1
	# set gp_Out [prompt "Enter name of output console?" "* MF output $gpTermCt *" ]
	set gp_Out "* MF output $gpTermCt *"
	set theMode "TeX"

    } elseif { [string first "#Curve" "$termID" ] == 0 } {
	incr gpTermCt 1
	# set gp_Out [prompt "Enter name of output console?" "* misc output $gpTermCt *" ]
	set gp_Out "* misc output $gpTermCt *"
	set theMode "TEXT"

    } elseif { [ string index "$termID" 0  ] == " " && [ string first "TERM:ÒdumbÓ" "$termType" ] > 0 } {
	set ns "\n"
	append ns $outit
	set outit "$ns"
	set gp_Out $gp_Console
	# set theMode "TEXT"

    } elseif { ![info exists gp_Out ] || [lsearch $wins $gp_Out ] < 0 } {
	incr gpTermCt 1
	# set gp_Out [prompt "Enter name of output console?" "* misc output $gpTermCt *" ]
	set gp_Out "* misc output $gpTermCt *"
	set theMode "TEXT"
    }
    
    if { $gp_Out == "" } {set gp_Out $gp_Console }
    
    if {  [lsearch $wins $gp_Out ]  < 0 } {
	new  -n $gp_Out -m $theMode
	# set wins [winNames]
	set gp_Out [lindex [winNames] 0]
    } else {
	# catch [ bringToFront $gp_Out ] ans
	# if { ![info exists ans] } { return }
    }
    
    insertText -w $gp_Out $outit
    GPLT::console
    if { $it == "Unable to find process" } GPLT::quit
    return 0
}

proc GPLT::iNSEhandler {it} {
    global gp_Console gp_TYPE gp_CREA GnuplotSig
    set res [GPLT::filtercurlyq $it]
    set wins [winNames]
    if { ( "$res" != "\n" ) && ( "$res" != "" ) && ( "$res" != "\r" ) } {
	if { [ lsearch $wins $gp_Console  ] >= 0} {
	    bringToFront $gp_Console
	}
    }
    
    goto [maxPos]
    insertText -w $gp_Console $res
    
    
    set paren  [string first "()" $res ]
    
    if { $paren >= 1 } {
	goto [pos::math [maxPos] - $paren + 2]
    }
    
    if { "$res" == "\r" }  {
	GPLT::sendCommand "" 3600
    } elseif { "$res" == "\n" }  {
	GPLT::sendCommand "" 3600
    } elseif { "$res" == "" }  {
	GPLT::sendCommand "" 3600
    } else {
	return 0
    }
    
    
}

# ===========================================================================
#
#  Send a command to gnuplot
#

proc GPLT::sendCommand { mycommand tmout} {
    global GPLTmodeVars gnuplotMenu  gp_CommandHist gp_Rsp  gp_CommandNum
    global gp_Prompts gp_Launched
    
    watchCursor
    #	GPLT::console
    
    set tmout 300
    # display command on the last line of the console if its not already there
    GPLT::dispCommand "$mycommand"
    if { [string trim $mycommand '\r'] != {} } {
	GPLT::addToHist $mycommand
    }
    
    # send gnuplot a command
    # display the stderr results on the screen
    # The eventHandler above will display the stdout results first
    set stderr [GPLT::sTDERR "$mycommand\r"  $tmout ]
    
    # Null stderr can mean two things.
    #   (1) a pause
    #   (2) if no thread manager available, it could mean go back
    #       and retrieve the stderr which will help 68k systems
    #       work since eventHandler is broken in 6.01
    
    # This can probably be cleaned up with a little effort
    # What I'm doing in the next line is taking care of the
    # non-threaded macs...
    # which always return "".  Its harmless otherwise.
    # if {$stderr == ""  && $mycommand != "" } { set stderr [GPLT::sTDERR "" $tmout ] }
    # if { $GPLTmodeVars(EventHandler) == "0" &&  $stderr == "" } { set stderr "gnuplot> " }
    if { $stderr != "" } {
	GPLT::results	 "$stderr"
    } else {
	# GPLT::results ""
    }
    
    blink [getPos]
}

proc GPLT::sendPath { dummyVar } {
    global gp_cwd
    # display current path on status bar
    set gp_cwd [ GPLT::filtercurlyq $dummyVar ]
    status::msg "Current gnuplot Path ==> $gp_cwd"
}

proc GPLT::consoleH { dummyVar } {
    GPLT::console
    # this is a dummy routine
}

proc GPLT::newWindowH { dummyVar } {
    switchTo 'ALFA'
    GPLT::newWindow
    # this is a dummy routine
}

proc GPLT::activateH { dummyVar } {
    GPLT::activate
    # this is a dummy routine
}

proc GPLT::closeH { dummyVar } {
    GPLT::quit
    # this is a dummy routine
}

# end of large 'if' block for Mac OS.
}


# ===========================================================================
#
#  Find and launch gnuplot
#

proc GPLT::check {} {
    global gnuplotMenu gp_Launched GPLTmodeVars
    
    # Check if gnuplot app is running.  If not, open the app named in
    # $ (if defined) or have the user select an app via a
    # standard file dialog.  Leave the gnuplot app in the background.
    
    if {![catch {app::launchAnyOfThese {GPSE GPLT} GnuplotSig}]} {
	set gp_Launched 1
	enableMenuItem $gnuplotMenu "quit gnuplot" on
	enableMenuItem $gnuplotMenu "graph" on
	enableMenuItem $gnuplotMenu "history" on
	enableMenuItem $gnuplotMenu "saveSettings" on
	enableMenuItem gnuplotOptions "setPointSizeÉ" on
	enableMenuItem $gnuplotMenu "setWorkingFolderÉ" on
	enableMenuItem $gnuplotMenu "choosePlotFileÉ"	 on
	return 0
    } else {
	return -1
    }
}

# ===========================================================================
#
# ×××× Console ×××× #
#

# ===========================================================================
#
#  Goto command window
#

proc GPLT::console {  } {
    global gp_Console  GPLTmodeVars
    global gp_Launched gp_Prompt
    
    # Check if gnuplot app is running.  If not, open the app named in
    # $ (if defined) or have the user select an app via a
    # standard file dialog.  Leave the gnuplot app in the background.
    
    set wins [winNames]
    if { [lsearch $wins $gp_Console ]  >= 0} {
	bringToFront $gp_Console
	goto [maxPos]
    } else   {
	GPLT::newConsole
    }
}

# ===========================================================================
#
#  Create  command window
#

proc GPLT::newConsole { } {
    global  gp_Console gp_Graph  gp_Path
    global  GPLTmodeVars gp_Launched gp_GEOM GPLT::graphMenu
    global gp_Prompt  gp_cwd gnuplotMenu  gp_home gp_scriptItems
    
    if {[llength $gp_GEOM] != "4" } {
	new -n $gp_Console -m GPLT
	set gp_GEOM [ getGeometry $gp_Console ]
    }
    set wd [lindex $gp_GEOM 2]
    set ht [lindex $gp_GEOM 3]
    set top [lindex $gp_GEOM 1]
    set left [lindex $gp_GEOM 0]
    set gY [expr $top - 15]
    set gX [expr $left + $wd + 5]
    set gW [expr 72 ]
    set gH [expr 50 ]
    
    set wins [winNames]
    if {  [lsearch $wins $gp_Console ]  < 0 } {
	new -g $left $top $wd $ht -n $gp_Console -m GPLT
    }
    catch { setWinInfo -w $gp_Console shell 1 }
    GPLT::graphButton
    if { $GPLTmodeVars(LiveHist) } GPLT::dumpHistory
    insertText -w $gp_Console  "\nWelcome to Alpha's gnuplot 3.6 shell.\n"
    GPLT::check
    bringToFront $gp_Console
    
    set res [ GPLT::sTDERR ""  3600 ]
    insertText -w $gp_Console "$res"
    
    # The following is a huge kludge...to deal with accidentally
    # closing the gnuplot window
    if	{ $res == "" }	{
	GPLT::results "gnuplot> "
    }
    # end kludge
    
    # Now setup the CLIE
    if {[string first "Using threaded console."  $res ] != {-1} \
      | [string first "ppc" [string tolower $res ] ] != {-1}  } {
	set ress [GPLT::sTDERR "" 3600 ]
    }
    
    set gp_home [file join $gp_cwd Scripts]
    set gp_Path "$gp_home"
    GPLT::rebuildScriptMenu
    
    status::msg "Current gnuplot Path ==> $gp_cwd"
    
}

# ===========================================================================
#
#  Rebuild the script menu
#

proc GPLT::rebuildScriptMenu {} {
    global gp_cwd GPLT::graphMenu gp_scriptItems gp_openItems gp_Path
    
    set gp_scriptItems [list]
    set gp_openItems [list]
    set gp_home "$gp_Path"
    
    set gp_sl [ GPLT::scriptList "$gp_home" "Scripts" ]
    set gp_sm [concat Menu -m -n "Scripts" -p GPLT::scriptMenuItems [list "$gp_sl"]  ]
    
    # kill the current floating menu (if any)
    GPLT::killGraphButton
    
    Menu  -n "${GPLT::graphMenu}" -p GPLT::gnuplotMenuProc [list \
      "gnuplot" \
      "(-" \
      {Menu -m -s -n "Settings" -p GPLT::gnuplotMenuProc  {\
      "line stylesÉ&" \
      "text formatÉ&" \
      "labelsÉ&" \
      "offsetsÉ&" \
    }}\
    "(-" \
    "$gp_sm" \
    ]
  
  GPLT::graphButton
}

# ===========================================================================
#
#  Generate a new script window
#

proc GPLT::newWindow {} {
    set wname "Untitled.gp"
    new -n $wname -m GPLT
    GPLT::uFD
    insertText "#\r"
    setWinInfo -w $wname dirty 0
}

# ===========================================================================
#
#  Insert File Description---use Vince's if possible.
#      this used in creating new window and in dumping history list
#

proc GPLT::uFD { } {
    # catch {userFileDescription } ans
    # if { 	$ans != ""	}  {
    insertText "#\r#\r#     " [join [mtime [now] long] ] "\r"
    nextLine
    #}
    endOfBuffer
}

# ===========================================================================
#
#  Tell gnuplot to quit
#

proc GPLT::quit {} {
    global gp_Console
    
    switchTo 'ALFA'
    set wins [winNames]
    if { [set winThere [lsearch $wins $gp_Console ] ] >= 0} {
	set name [lindex $wins $winThere]
	bringToFront $name
	killWindow
    }
    
}

# ===========================================================================
#
#  Switch to gnuplot
#

proc GPLT::activate {  } {
    global   GnuplotSig
    
    if { ![GPLT::check] } {
	switchTo \'$GnuplotSig\'
    }
}

# ===========================================================================
#
#  Filter curlyq's out of sting...We may need to be smarter
#    about this later
#

proc GPLT::filtercurlyq { it } {
    
    set from [string first "Ò" $it]
    set to [string first "Ó" $it]
    set ans [string range $it [expr $from + 1] [expr $to - 1] ]
    if { ![expr [string length $ans] -1 ] } {
	regexp -nocase {[a-z0-9]} $ans nans
	if {[info exists nans]} {
	    set ans $nans
	} else {
	    set ans ""
	}

    }
    
    return $ans
}

# ===========================================================================
#
#  Extract current gnuplot path from event reply
#

proc GPLT::extractPath { ans } {

    if {![dialog::yesno -n "Submit Report" -y "Continue" \
      "This code uses an obsolete routine we are\
      trying to fix.  If you use Gnuplot mode, please submit a\
      bug report with the attached information"]} {
	new -n "submit this" \
	  -text "Place this information in the bug report\r\r$ans"
	return
    }
    
    global gp_cwd
    
    # We need to be tricky since I'm not sure if Dave is sending the
    # path in an alis, or as a string
    #	regexp {Ò(.*)(Ó.*Ò)(.*)Ó} "$ans" dummy spec1 spec2 spec3
    
    set frst [ string first "PSTR:" "$ans" ]
    set lst [ string first "TERM:" "$ans" ]
    
    if { ($frst > 0) } {
	if { $lst <= 0 } { set lst [string length $ans ] }
	set ans [string range "$ans" $frst $lst ]
	regexp {Ò(.*)Ó} "$ans" dummy  spec3   spec1
	if {[info exists spec3]} {
	    set ngp_cwd $spec3
	    if {$ngp_cwd != "" } {
		set gp_cwd "$ngp_cwd"
		return 0
	    } 
	}
    }
    
    regexp {Ç(.*)È} "$ans" dummy spec
    if {[info exists spec]} {
	set ngp_cwd [specToPathName $spec]
	if {$ngp_cwd != "" } {
	    set gp_cwd "$ngp_cwd"
	    return 0
	} 
    }
}

# ===========================================================================
#
#  Send a command to gnuplot and return stderr!
#

proc GPLT::sTDERR { mycommand tmout } {
    global  gp_cwd  GPLTmodeVars GnuplotSig gp_TYPE gp_CREA
    
    if { ! $GPLTmodeVars(EventHandler) } {
	catch { tclAE::send -p -t $tmout -r \'$GnuplotSig\' GPSE  "exec" ---- \
	  [curlyq $mycommand] {CREA:} "$gp_CREA" \
	  {TYPE:} "$gp_TYPE" } ans
    } else {
	catch { tclAE::send -p -t $tmout -r \'$GnuplotSig\' GPSE  "exec" ---- \
	  [curlyq $mycommand] {CLIE:} "ALFA" {CREA:} "$gp_CREA" \
	  {TYPE:} "$gp_TYPE" } ans
    }
    if { $ans == "Unable to find process"  }  GPLT::quit
    GPLT::extractPath $ans
    return [GPLT::filtercurlyq $ans]
}

# ===========================================================================
#
#  Save current window and execute it in GNUPLOT, just like GNUPLOT
#  command ;)
#

proc GPLT::saveAndExecute {} {
    
    if {[winDirty]} {save}
    
    # Get the path of the current window and it's name
    
    # Set the working directory to the current window's
    # current dir.
    set GPLTFilePath "cd \'\:"
    set GPLTFile [lindex [winNames -f] 0]
    set GPLTFP [file dirname $GPLTFile]
    append  GPLTFilePath  $GPLTFP ":\'"
    
    # use unix style file paths
    regsub -all ":" $GPLTFilePath {/} GPLTFilePath
    
    # get the load command ready...
    set scriptName  "load \'"
    append scriptName [file tail $GPLTFile] "\'"
    
    # Change current working directory to window's
    GPLT::sendCommand $GPLTFilePath 600
    
    # Do the script
    GPLT::sendCommand $scriptName 700
}

# ===========================================================================
#
#  Write results to command window

proc GPLT::results { res } {
    global gp_Console gp_cwd
    insertText -w "$gp_Console"  "\n" $res
    setWinInfo -w "$gp_Console" dirty 0
    status::msg "Current gnuplot Path ==> $gp_cwd"
}

# ===========================================================================
#
#  Send line to GNUPLOT
#

proc GPLT::doLine {} {
    
    beginningOfLine
    set bol [getPos]
    endOfLine
    set eol [getPos]
    
    set scriptName [getText $bol $eol]
    GPLT::sendCommand $scriptName 	800
}

# ===========================================================================
#
#  Send selection to GNUPLOT
#

proc GPLT::doSelection {} {
    # Break lines into separate commands.
    foreach sN [split [getSelect] "\r"] {
	GPLT::sendCommand $sN 900
    }
    
}

# ===========================================================================
#
#  Edit current window in GNUPLOT
#

proc GPLT::editFile {} {
    global GnuplotSig
    
    if { ![GPLT::check] } {
	set thisWin  [lindex [winNames] 0]
	if {[winDirty]} {
	    if {[askyesno "Save '$thisWin'?"] == "yes"} {
		save
	    } else {
		return
	    } 
	}
	set thisWin  [lindex [winNames -f ] 0]
	killWindow
	if {![catch {sendOpenEvent -n \'$GnuplotSig\' $thisWin }]} {
	    switchTo \'$GnuplotSig\' 
	}
    }
}

#
#  closeHook procedure so that gnuplot is quit
#  whenever the user closes the console window.  Also ask about
#  saving the history list when the console is closed.
#

proc GPLT::closeHook	{name} {
    global gnuplotMenu GPLTmodeVars
    global gp_CreatorList gp_TypeList gp_Console gp_Graph gp_Hist
    global gp_CreatorNames gp_CommandNum gp_Launched GnuplotSig
    global gp_GEOM gp_HistGEOM
    
    if { [string first "$gp_Console" $name] == 0	} {

	if	{$gp_CommandNum != 0 && ! $GPLTmodeVars(NevrSavHist) } {
	    GPLT::dumpHistory
	    set ans [askyesno -c "Savegnuplot command History?" ]
	} else {	set ans "yes" }

	GPLT::offSet
	switch -exact [string tolower $ans] {
	    "cancel"   { GPLT::console; return $result }
	    "no"       { GPLT::clearHistory }
	    "yes"	   { 
		catch { setWinInfo -w $gp_Hist read-only 0 } jj
		catch { setWinInfo -w $gp_Hist dirty 1 } jj
		catch { bringToFront $gp_Hist } jj
		if { $jj == 0 } {
		    catch { saveAs "history.gp" } jj
		}
		catch { setWinInfo -w $gp_Hist dirty 0 } jj
		catch { setWinInfo -w $gp_Hist read-only 1 } jj
		GPLT::clearHistory
	    }
	}
	# end case
	#		if {$gp_Launched	!=	0 } {
	catch { sendQuitEvent \'$GnuplotSig\' } hhh
	prefs::modified  GnuplotSig
	#            }
	set gp_Launched 0
	set wins [winNames]
	if { [lsearch $wins $gp_Hist  ]  >= 0} {
	    bringToFront $gp_Hist
	    killWindow
	}
	prefs::modified   gp_GEOM
	prefs::modified   gp_HistGEOM

    } elseif {[string first $gp_Hist	$name] == 0} {
	set wins [winNames]
	if { [lsearch $wins "$gp_Console" ]  >= 0} {
	    set GPLTmodeVars(LiveHist) 0
	}
    }
}

# ===========================================================================
#
#  Redefine the deactivateHook procedure so that gnuplot is quit
#  whenever the user closes the console window.  Also ask about
#  saving the history list when the console is closed.
#

proc GPLT::deactivateHook	{name} {
    global  gp_Hist GPLTmodeVars gp_Console gp_Graph
    global  gp_GEOM gp_HistGEOM
    if	{ [string first $gp_Hist $name] == 0	} {
	set gp_HistGEOM [ getGeometry "$gp_Hist" ]
	endOfBuffer
    } elseif {[string first "$gp_Console" $name] == 0} {
	set gp_GEOM [getGeometry "$gp_Console" ]
    }
}

# ===========================================================================
#
#  Redefine the activateHook procedure so that gnuplot is quit
#  whenever the user closes the console window.  Also ask about
#  saving the history list when the console is closed.
#

proc GPLT::activateHook	{name} {
    global  gp_Hist gp_Graph gp_Console
    global  mode gp_cwd GPLTmodeVars mode gp_GEOM
    
    if	{ [string first "$gp_Console" $name] == 0} {
	set gp_GEOM [ getGeometry "$gp_Console" ]
    } elseif	{ [string first $gp_Hist $name] == 0} {
	set gp_HistGEOM [ getGeometry "$gp_Hist" ]
    }
    
    status::msg "Current gnuplot Path ==> $gp_cwd"
}

# ===========================================================================
#
# ×××× Command History ×××× #
# 

# ===========================================================================
#
#  History goto match...
#

proc GPLT::histgotoMatch {} {
    set frst [lineStart [getPos] ]
    endOfLine
    set lst  [getPos]
    endOfBuffer
    beginningOfLine
    GPLT::sendCommand [getText $frst $lst ] 1000
}

# ===========================================================================
#
#  Display or rewrite "command" to command window
#  

proc GPLT::dispCommand {command} {
    global   gp_Prompts gp_cwd
    
    # This is ugly and probably not very efficient.
    
    set lst [maxPos]
    set boll [lineStart $lst]
    set curr [getPos]
    
    if {[pos::compare $curr >= $boll]} {   
	set bol [lineStart $curr]
	set eol [nextLineStart $curr]
	set text [getText $bol $eol]
	set ltext [getText $boll $lst]
	foreach gp $gp_Prompts {
	    set c1 [string first $gp $ltext]
	    set c2 [pos::diff $lst $boll]
	    set c3 [string length $gp]
	    set c4 [pos::diff $lst $curr]
	    set c5 [string length $command]
	    if { $c1 == 0 && [expr {abs($c2) >= $c3 | abs($c4) >= $c5}] } {
		if {[string first $command $text] == -1} {
		    set a [pos::math $boll + [string length $gp] ]
		    set b [string trim $command "\r\n"]
		    replaceText $lst $a $b
		}
	    }
	}
    }
}

# ===========================================================================
#
#  Add command to history list
#

proc GPLT::addToHist  { cmmd } {
    global gp_CommandHist gp_CommandNum gnuplotMenu
    global GPLT::console gp_Hist GPLTmodeVars
    
    enableMenuItem gnuplotOptions "clearHistory" on
    lappend gp_CommandHist $cmmd
    set gp_CommandNum [llength $gp_CommandHist]
    
    if { $GPLTmodeVars(LiveHist) } {
	# if history list active then append $cmmd on last line
	set wins [winNames]
	if { [lsearch $wins $gp_Hist ]  >= 0} {
	    setWinInfo -w $gp_Hist dirty 1
	    setWinInfo -w $gp_Hist  read-only 0
	    insertText -w $gp_Hist "$cmmd\r"
	    setWinInfo -w $gp_Hist  dirty 0
	    setWinInfo    -w $gp_Hist  read-only 1
	} else {
	    GPLT::dumpHistory
	    bringToFront "$gp_Console"
	}

    }
}

# ===========================================================================
#
#  Clear History list
#

proc GPLT::clearHistory {} {
    global  gnuplotMenu gp_CommandHist gp_CommandNum  gp_Hist
    
    set gp_CommandHist [list]
    set gp_CommandNum "0"
    enableMenuItem gnuplotOptions "clearHistory" off
    set wins [winNames]
    if { [lsearch $wins $gp_Hist ] >= 0} {
	bringToFront $gp_Hist
	killWindow
    }
}

# ===========================================================================
#
#  Write History list into a window of its own.
#

proc GPLT::dumpHistory {} {
    global gp_CommandHist gp_CommandNum gp_Console
    global GPLTmodeVars gp_Hist
    global gp_GEOM
    
    set wins [winNames]
    set nw [ llength $wins ]
    
    if { [lsearch $wins $gp_Hist ]  == -1} {
	set l [ expr [lindex $gp_GEOM 0] + 12 + [lindex $gp_GEOM 2] ]
	set t [ expr [lindex $gp_GEOM 1] + 65 ]
	set w 96
	set h [ expr [lindex $gp_GEOM 3] - 65 ]
	new -n $gp_Hist -g $l $t $w $h -m GPLT
	set gp_HistGEOM [getGeometry]
	GPLT::uFD
	set scriptName "# (<cr> to send to gnuplot)\r#-----\r"
	foreach word $gp_CommandHist  {append  scriptName  $word "\r" }
	insertText  -w $gp_Hist $scriptName
	setWinInfo dirty 0
	setWinInfo read-only 1
    } else {
	bringToFront $gp_Hist
    }
}

# ===========================================================================
#
# Navigation
# 

proc GPLT::prevCommand {} {
    global  gp_CommandHist gp_CommandNum gp_Hist gp_Prompt gp_MultiPrompt
    global  gp_ContPrompt gp_Console
    
    # enter only if cr in console window...
    set wins [winNames]
    if { [lsearch $wins "$gp_Console" ] == 0} {

	set text [getText [lineStart [getPos] ] [nextLineStart [getPos] ] ]
	if {[set ind [string first $gp_Prompt $text] ] == 0} {
	    goto [pos::math [lineStart [getPos] ] + $ind + [string length $gp_Prompt] ]
	} elseif {[set ind [string first $gp_MultiPrompt $text] ] == 0} {
	    goto [pos::math [lineStart [getPos] ] + $ind +
	    [string length $gp_Multiprompt] ]
	} elseif {[set ind [string first $gp_ContPrompt $text] ] == 0} {
	    goto [pos::math [lineStart [getPos] ] + $ind + [string length $gp_Contprompt] ]
	} else { return }

	incr gp_CommandNum -1
	if {$gp_CommandNum < 0} {
	    incr gp_CommandNum
	    endOfLine
	    return
	}
	set text [lindex $gp_CommandHist $gp_CommandNum]
	set to [nextLineStart [getPos] ]
	if {[lookAt [pos::math $to -1] ] == "\r"} {set to [pos::math $to -1]}

	replaceText [getPos] $to $text
    } elseif { [lsearch $wins $gp_Hist ]  == 0} {

	set limit [nextLineStart [nextLineStart [minPos]] ]
	if {[pos::compare [getPos] > $limit]} {
	    set limit [pos::math [getPos] - 1]
	}
	selectText [lineStart $limit] [nextLineStart $limit]
    } else {
	previousLine
    }
    
}

proc GPLT::nextCommand {} {
    global  gp_CommandHist gp_CommandNum gp_Prompt gp_MultiPrompt
    global gp_ContPrompt gp_Console gp_Hist
    
    # enter only if cr in console window...
    set wins [winNames]
    if { [lsearch $wins "$gp_Console"  ]  == 0} {

	set text [getText [lineStart [getPos] ] [nextLineStart [getPos] ]]
	if {[set ind [string first $gp_Prompt $text] ] == 0} {
	    goto [pos::math [lineStart [getPos] ] + $ind + 9]
	} elseif {[set ind [string first $gp_MultiPrompt $text] ] == 0} {
	    goto [pos::math [lineStart [getPos] ] + $ind + 11]
	} elseif {[set ind [string first $gp_ContPrompt $text] ] == 0} {
	    goto [pos::math [lineStart [getPos] ] + $ind + 3]
	} else  {
	    endOfBuffer
	    return
	}

	incr gp_CommandNum
	if {$gp_CommandNum > [llength $gp_CommandHist]} {
	    incr gp_CommandNum -1
	    return
	}
	set text [lindex $gp_CommandHist $gp_CommandNum]
	set to [nextLineStart [getPos] ]
	if {[lookAt [pos::math $to -1] ] == "\r"} {set to [pos::math $to -1]}
	replaceText [getPos] $to $text
    } elseif { [lsearch $wins $gp_Hist  ]  == 0} {
	set pos [getPos]
	if {[pos::compare $pos < [nextLineStart [minPos]]]} {
	    set pos [nextLineStart [minPos]]
	}
	if {[pos::compare [nextLineStart $pos] != [maxPos]]} {
	    selectText [nextLineStart $pos] [nextLineStart [nextLineStart $pos] ]
	}
    } else {
	# mv cusor down...
	nextLine
    }
}

# ===========================================================================
# 
# ×××× Additional Menu Support ×××× #
# 

# ===========================================================================
#
#  change behavior of modifyModeFlags
#

proc GPLT::updatePreferences {prefName} {
    global mode GPLTmodeVars gp_HistGEOM gp_GEOM
    global gnuplotMenu  gp_Graph gp_Console  gp_Hist gp_floatmenu
    
    set wins [winNames]
    if { [lsearch $wins "$gp_Console" ]  >= 0}  {
	set gp_GEOM [ getGeometry "$gp_Console" ]
    }
    
    if { [lsearch $wins $gp_Hist] >= 0 } {
	set gp_HistGEOM [ getGeometry "$gp_Hist" ]
    }
    
    if { $GPLTmodeVars(LiveHist) } {
	set wins [winNames]
	if { [lsearch $wins "$gp_Console"  ]  >= 0} {
	    GPLT::dumpHistory
	}
    } else {
	set wins [winNames]
	if {[lsearch $wins $gp_Hist  ]  >= 0} {
	    bringToFront $gp_Hist
	    killWindow
	}
    }
    if { $GPLTmodeVars(EventHandler) } {
    } else {
	set jj1 "The event handler is broken in Alpha (68k)."
	set jj2 "You may need to disable event handling until it is fixed."
	alertnote $jj1 $jj2
    }
    if { $GPLTmodeVars(GraphButton) } {
	GPLT::graphButton
    } else {
	GPLT::killGraphButton
    }
    catch {	bringToFront "$gp_Console" }
}

# ===========================================================================
#
#  Select creator from list
#

proc GPLT::selectCreator {} {
    global gp_CreatorNames  gp_CreatorList   gp_TypeList GPLTmodeVars
    global setOutputCreator
    global gp_CREA gp_TYPE
    
    set crea [listpick -p "Select output file creator:" $gp_CreatorNames  ]
    set creator [lindex $gp_CreatorList [lsearch  $gp_CreatorNames $crea] ]
    set type [lindex $gp_TypeList [lsearch  $gp_CreatorNames $crea] ]
    if {$creator == {} } {
	set gp_CREA 'ALFA'
	set gp_TYPE 'TEXT'
    } else {
	set gp_CREA $creator
	set gp_TYPE $type
    }
    prefs::modified  gp_TYPE
    prefs::modified  gp_CREA
    prefs::modified  gp_CreatorList
    prefs::modified  gp_TypeList
    prefs::modified  gp_CreatorNames
}

# ===========================================================================
#
#  Add creator to list from file dialog
#

proc GPLT::addCreator {} {
    global gp_CreatorNames  gp_CreatorList  gnuplotMenu gp_TypeList
    global GPLTmodeVars
    global gp_CREA gp_TYPE
    
    set fname [getfile "Select file type for creator"]
    #  add to creator list
    if {[file::getType $fname]=="APPL"} {
	alertnote "Sorry, but that was an application. \rTry again."
	return
    }
    
    if {$fname != {}} {
	set nm [prompt "What do you wish to call it?" [file tail $fname ] ]
	if {$nm != {} } {
	    set gp_CREA  [file::getSig $fname]
	    set gp_TYPE  [file::getType $fname]
	    lappend gp_CreatorList  $gp_CREA
	    lappend gp_TypeList     $gp_TYPE
	    lappend gp_CreatorNames $nm
	    enableMenuItem  setOutputCreator "SelectÉ" on
	    enableMenuItem  setOutputCreator "DeleteÉ" on
	    prefs::modified  gp_TYPE
	    prefs::modified  gp_CREA
	    prefs::modified  gp_CreatorList
	    prefs::modified  gp_TypeList
	    prefs::modified  gp_CreatorNames
	}
    }
    
    
}

# ===========================================================================
#
#  Remove creator from list
#

proc GPLT::deleteCreator {} {
    global gp_CreatorNames gnuplotMenu gp_CreatorList  gp_TypeList
    global GPLTmodeVars
    global gp_CREA gp_TYPE
    
    set crea [listpick -p "Select creator to be deleted:"  $gp_CreatorNames ]
    
    if {$crea != {}} {
	#  now remove this creator from both lists....
	set creatorInd [lsearch  $gp_CreatorNames $crea]
	set crea [ lindex $gp_CreatorList $creatorInd]
	set gp_CreatorNames [ lreplace $gp_CreatorNames $creatorInd $creatorInd ]
	set gp_CreatorList  [ lreplace $gp_CreatorList  $creatorInd $creatorInd ]
	set gp_TypeList     [ lreplace $gp_TypeList     $creatorInd $creatorInd ]

	if {$gp_CREA == $crea } {
	    set gp_CREA 'ALFA'
	    set gp_TYPE 'TEXT'
	}
	prefs::modified  gp_TYPE
	prefs::modified  gp_CREA
	prefs::modified  gp_CreatorList
	prefs::modified  gp_TypeList
	prefs::modified  gp_CreatorNames
    }
    
    if {[llength $gp_CreatorList] == 0} {
	enableMenuItem  setOutputCreator "SelectÉ" off
	enableMenuItem setOutputCreator "DeleteÉ" off
    }
}

# ===========================================================================
#
#  Clear a few globals...
#

proc GPLT::clear {} {
    global  GPLTmodeVars
    global  gp_CreatorList gp_CreatorNames
    global gp_GEOM gp_HistGEOM
    global gp_CREA gp_TYPE
    
    if { [info exists gp_GEOM] } { set gp_GEOM [list] }
    if { [info exists gp_CreatorList] } { unset gp_CreatorList }
    if { [info exists gp_TypeList] } { unset gp_TypeList }
    if { [info exists gp_CreatorNames] } { unset gp_CreatorNames }
    if { [info exists gp_HistGEOM] } { unset gp_HistGEOM  }
    if { [info exists gp_CREA] } { unset gp_CREA  }
    if { [info exists gp_TYPE] } { unset gp_TYPE  }
    
    ensureset gp_CreatorList [list ALFA GPLT ]
    ensureset gp_TypeList [list TEXT TEXT ]
    ensureset gp_CreatorNames [list alpha gnuplot]
    ensureset gp_CREA ALFA
    ensureset gp_TYPE TEXT
    ensureset gp_GEOM [list]
    ensureset gp_HistGEOM [list ]
    
    if { [llength $gp_CreatorList] == 0 \
      || [llength $gp_CreatorList] != [llength $gp_CreatorNames] \
      || [llength $gp_CreatorList] != [llength $gp_TypeList]} {
	set gp_CreatorList [list]
	set gp_TypeList [list]
	set gp_CreatorNames [list]
    }
    
    prefs::modified gp_CreatorNames gp_TypeList gp_CreatorList
    prefs::modified gp_HistGEOM gp_GEOM
    prefs::modified gp_TYPE gp_CREA
}

# ===========================================================================
#
#  run load scripts from scripts menu
#

proc GPLT::scriptMenuItems {menu item} {
    global gp_sl gp_home gp_scriptItems gp_Path  gp_openItems
    
    set men [string tolower $menu]
    set ite [string tolower $item]
    
    if { "$item" == "Rebuild Menu" } {
	set cdir [pwd]
	cd $gp_Path
	GPLT::rebuildScriptMenu
	cd "$cdir"
	return 0
    }
    
    foreach it $gp_scriptItems {
	if { [string match "cd \'*$men:\'; load \'*$men:$ite\'" [string tolower $it] ] } {
	    GPLT::sendCommand "$it" 110
	    return 0
	}  
    }
    
    # set men [string tolower [string range $menu 5 [string length $menu] ] ]
    
    # filter out the "¥ edit "  from the selected $menu $item
    set ite [string tolower [string range $item 7 [string length $item] ] ]
    
    foreach it $gp_openItems {
	if { [string match "*$men:$ite" [string tolower $it] ] } {
	    edit -c -mode GPLT "$it"
	    return 0
	}  
    }
}

# ===========================================================================
#
#  Create floating menu
#

set GPLT::graphMenu "gnuplotGraph"

#set gp_grmen [list "Menu  -n ${GPLT::graphMenu} -p GPLT::gnuplotMenuProc" ]
#lappend gp_grmen "gnuplot" "(-"

Menu -n ${GPLT::graphMenu} -p GPLT::gnuplotMenuProc [list "gnuplot"]

# ===========================================================================
#
#  Create a floating gnuplot graph button (Alpha 6.2 or higher)
#

proc GPLT::graphButton {{addButton "0"}} {
    global gp_floatmenu GPLT::graphMenu GPLTmodeVars 
    global gp_sl gp_Path gp_GEOM gp_FLTGEOM
    
    #	if {[llength $gp_FLTGEOM] != 2 } {
    if {[llength $gp_GEOM] == 4 } {
	set l [ expr [lindex $gp_GEOM 0] + 5 + [lindex $gp_GEOM 2] ]
	set t [ expr [lindex $gp_GEOM 1] - 20 ]
	set gp_FLTGEOM [list $l $t ]
    } else {
	set l 20
	set t 20
    }
    #	}  else {
    #  		set l  [lindex $gp_FLTGEOM 0]
    #  		set t  [lindex $gp_FLTGEOM 1]
    #	}
    
    if {$GPLTmodeVars(GraphButton) || $addButton} {
	if {[info exists gp_floatmenu]} {
	    GPLT::killGraphButton
	}
	catch {
	    set gp_floatmenu [float -m ${GPLT::graphMenu} -n "" -M -1 -z GPLT -l $l -t $t ]
	}
    }
}

# ===========================================================================
#
#  Kill a floating gnuplot menu (Alpha 6.2 or higher)
#

proc GPLT::killGraphButton {} {
    global gp_floatmenu
    
    if {[info exists  gp_floatmenu]}  {
	catch {unfloat ${gp_floatmenu}}
	unset gp_floatmenu
    }
}

# ===========================================================================
#
#  Generate the script menu
#

proc GPLT::scriptList { sdir men } {
    global gp_scriptItems  gp_openItems
    
    if {"$men" == "Scripts" } {
	set sl [list "\(Rebuild Menu"]
    } else {
	set sl [list]
    }
    
    # get the list of text files in $sdir
    set gp_fl [ glob -nocomplain -types TEXT -dir "$sdir" *]
    foreach f $gp_fl {
	set mitem [file tail $f]
	# append mitem "&"
	if { $mitem != "" } {
	    lappend sl "<E<S$mitem"
	    lappend sl "<S<I¥ edit $mitem"
	    lappend sl "<S<B¥ edit $mitem"
	    lappend sl "<S<U¥ edit $mitem"
	    lappend sl "<S<O¥ edit $mitem"
	    lappend gp_scriptItems "cd \'$sdir\'; load \'$f\'"
	    lappend gp_openItems "$f"
	}
    }
    
    # get the list of aliased directories in $sdir and
    # perform this operation again on subdirectories
    set dlist [ glob   -types fdrp -nocomplain "$sdir"]
    foreach d $dlist {
	set dn [file tail $d]
	set sl [concat "$sl"  [concat " \{Menu -m -n" "\"$dn\"" -p GPLT::scriptMenuItems  " \{  "  ] ]
	set dnam $d
	# set gp_ssl [ GPLT::scriptList "$dnam" $dn ]
	set gp_ssl [list "(ALIASED FOLDERS NOT WORKING YET"]
	set sl [ concat "$sl "  $gp_ssl " \}  \} " ]
    }
    
    # get the list of directories in $sdir and
    # perform this operation again on subdirectories
    set dlist [ glob -nocomplain -type d -dir "$sdir" *]
    foreach d $dlist {
	set dn [file tail [file dirname $d]]
	set sl [concat "$sl"  [concat " \{Menu -m -n" "\"$dn\"" -p GPLT::scriptMenuItems  " \{  "  ] ]
	set gp_ssl [ GPLT::scriptList $d $dn]
	set sl [ concat "$sl "  $gp_ssl " \}  \} " ]
    }
    
    return  $sl
}

# ===========================================================================
#
#  Load a script into gnuplot
#

proc GPLT::loadScript {} {
    global gp_cwd
    catch { cd "$gp_cwd" } hmm
    set GPLTFile [ getfile "Choose a script to load:" ]
    if { $GPLTFile != "" } {
	GPLT::sendCommand  "load \'$GPLTFile\'" 120
    }
}

# ===========================================================================
#
#  Tell gnuplot to save settings...
#

proc GPLT::saveSettings { what } {
    global  GPLTmodeVars gp_cwd gp_TYPE gp_CREA
    
    catch { cd "$gp_cwd" } hmm
    set tCREA $gp_CREA
    set tTYPE $gp_TYPE
    set gp_CREA {ALFA}
    set gp_TYPE {TEXT}
    set where [ putfile "Save current gnuplot settings" \
      [format "gnuplot%src.gp" [string toupper $what ] ] ]
    if { $where != "" } {
	GPLT::sendCommand "save $what \'$where\'" 130
    }
    set gp_CREA  $tCREA
    set gp_TYPE  $tTYPE
}

# ===========================================================================
#
#  Tell gnuplot where the current dir is...
#

proc GPLT::setCWD {} {
    set gp_cwd [ get_directory -p "Select gnuplot working folder"]
    if { $gp_cwd != "" } {
	GPLT::sendCommand "cd \'$gp_cwd\'" 140
    }
}

# ===========================================================================
#
#  Tell gnuplot to change the point size
#

proc GPLT::setPTSZ {} {
    GPLT::sendCommand " set pointsize [ prompt "Enter point size" 1 ] " 150
}

# ===========================================================================
#
#  Choose a file to plot and write "plot 'filename'" on command line
#

proc GPLT::choosePlotFile { } {
    global gp_Console gp_cwd
    catch { cd "$gp_cwd" } hmm
    set plotfile [ getfile "Choose a file to plot" ]
    if { $plotfile != "" } {
	insertText -w "$gp_Console" "plot \'$plotfile\' "
    }
}

# ===========================================================================
#
#  Setup menu flags, etc ... assuming gnuplot is off
#

proc GPLT::offSet {} {
    global gnuplotMenu gp_CreatorList
    
    enableMenuItem gnuplotOptions "clearHistory" off
    enableMenuItem $gnuplotMenu "quit gnuplot" off
    enableMenuItem $gnuplotMenu "graph" off
    enableMenuItem $gnuplotMenu "history" off
    enableMenuItem $gnuplotMenu "saveSettings" off
    enableMenuItem gnuplotOptions "setPointSizeÉ" off
    enableMenuItem $gnuplotMenu "setWorkingFolderÉ" off
    enableMenuItem $gnuplotMenu "choosePlotFileÉ"	 off
    
    if {[llength $gp_CreatorList] == 0} {
	enableMenuItem  setOutputCreator "SelectÉ" off
	enableMenuItem  setOutputCreator "DeleteÉ" off
    }
    
}

# ===========================================================================
#
#  Called from menu to handle dialogs in the server app
#

proc GPLT::dialog { ans } {
    global  GnuplotSig
    switchTo  \'$GnuplotSig\'
    tclAE::send -p -t 3600 -r 'GPSE' GPLT "DIAG" ---- $ans
    switchTo 'ALFA'
}

# ===========================================================================
#
# ×××× Version History ×××× #
#
#       =======================================================
# 
# 0.1		8/1/95
# -----------------------------------------------
# Converted matlab.tcl to gnuplot.tcl
#
# 0.2		8/2/95
# -----------------------------------------------
# Added a "Switch to gnuplot" menu option
# Added Console modeVar	                   		     
# Added run in background modeVar            
# Command History mostly working in console.
# Cleaned things up a bit.
#
# 0.3		8/3/95
# -----------------------------------------------
# Console position remembered between sessions
#
# Enabled command history to be dumped to a window
# 
# 0.4		8/3/95
# -----------------------------------------------
# User specified colorizing through check pop-up menu in GNUc console.
#     You must quit alpha and restart to see the effects.  Also, you must
#     make sure that keywords and colors don't overlap.
#
# 1.0.1		8/8/95
# -----------------------------------------------
# Handles multiplot mode
# set output file CREATOR modeVar	(not yet)
# 
#
# 1.0.2		8/11/95
# -----------------------------------------------
# When console window is closed the gnuplot app is quit and user
#     is prompted to save the Alpha/gnuplot history
#
# Command-Dbl-Click anywhere between gnuplot prompts to select gnuplot output.
#     Nice if you send term output to the console.
#
# 1.0.3		8/12/95
# -----------------------------------------------
# Fixed bugs in closing console window
# Added wristwatch cursor while waiting for gnuplot
#
# 1.0.4		8/12/95
# -----------------------------------------------
# New modeVar to keep console "clean" 
#
# 1.0.5		8/16/95
# -----------------------------------------------
# Replaced 'dosc' w/tclAE::send -p
# Added eventHandler  (thanks Dave)
# Dumped "clean" window since Pete will add this functionality to "new" in 6.0.2
#
# 1.0.6		8/17/95
# -----------------------------------------------
# Cleaned up several procs
# Quit now works properly
#
# 1.0		8/7/95
# -----------------------------------------------
# Now works with 3.6 (but not with 3.5)
# 
#       ============= Above were really beta's ====================
#
# 1.0		8/21/95  (these release numbers are backwards)
# -----------------------------------------------
# First working release	 
#
# 1.1		8/22/95
# -----------------------------------------------
# Set output creators from gnuplot menu
# Quit Working properly once again
# Added ERRP eventHandler for those w/o the
# Thread Manager
#
# 1.2		8/23/95
# -----------------------------------------------
# Deal w/"pause -1"	 properly
# cmd-dbl-click now works for all prompts
# Cleaned up set output creator
#
# 1.2.1		8/23/95
# -----------------------------------------------
# Now works with unthreaded 68k systems
# DoSelection works for multiple lines
#
# 1.2.2		8/23/95
# -----------------------------------------------
# Repaired help/prompting/etc which broke in
# 
# 1.2.3		8/27/95
# -----------------------------------------------
# Fixed a few prompt related items.
# I need to clean up the code a bit especially in the console output routines
#
# 1.2.4		8/28/95
# -----------------------------------------------
# I honestly don't recall
#
# 1.2.5		8/29/95
# -----------------------------------------------
# File type as well as creator settings in place
#
# 1.3		12/09/95												   
# -----------------------------------------------
# Should work with gnuplot app and
# Fixed an "unknown" bug---thanks Vince
# Files with gnuplot creator open in gnuplot mode
# Added several eventHandler's to work with the
# gnuplot's new personality module
# NOTE:  No longer supports the gnuplot server app, but I might add it
#     back in later...
#
# 1.3.1		12/14/95												   
# -----------------------------------------------
# Consolidated console and script editor modes.
# Supports server once again.   
# History dump working.......
#
# 1.3.2		12/15/95												   
# -----------------------------------------------
# History dump Really working this time.......
# Included a kludge eventHander: GPIC EXEC for Dave (temporary)
#
# 1.3.3		12/20/95												   
# -----------------------------------------------
# Added Live History window  
# Added a function sub-menu
#			 
# 1.3.4		02/01/96												   
# -----------------------------------------------
# Added "iconic" graph window which switches to the gnuplot application
# Added a "gnuplot prefs" submenu
#
# 1.3.5		02/01/96												   
# -----------------------------------------------
# Some minor fixes to console routines
#  
# 1.3.6		02/26/96												   
# -----------------------------------------------
# Added graph button preference and repaired my broken closeHook procedure
#  
# 1.3.7		03/13/96												   
# -----------------------------------------------
# Added support for cwd display on message bar
#			 
# 1.3.8		03/13/96												   
# -----------------------------------------------
# Re-arranged some code.  
#			 
# 1.3.9		04/10/96												   
# -----------------------------------------------
# Keyword coloring editable from gnuplot pref menu.
# Gnuplot pref menu re-arranged
# This package should display the path on the message bar
#  
# 1.4.0		04/14/96												   
# -----------------------------------------------
# GPLT mode preferences accessable from
# config:currentmode:flags... menu
# Keyword coloring now works and is auto-sourced whenever GPTLPrefs.tcl is closed
# Reorganized and added to gnuplot menu
# Reorganized all mode specifice procedures and variable names
#  
# 1.4.1		04/15/96												   
# -----------------------------------------------
# Repaired broken quit and switchto menu options
#  
# 1.4.2		04/17/96
# -----------------------------------------------
# Let alpha do bookkeeping on globals
#  
# 1.4.3		04/24/96
# -----------------------------------------------
# Add trap for broken eventhandler on 68k
#  
# 1.4.4		04/26/96
# -----------------------------------------------
# Modify trap for broken eventhandler on 68k so that pause works correctly
#     and so that gnuplot can bring itself to the front
#  
# 1.5b1		07/02/96
# -----------------------------------------------
# Modify code so that it is compliant with the new mode conventions 
#     Pete added to 6.2 (see changes file).
# This script should still work for Alpha pre 6.2!
# Nifty self-installer!
#  
# 1.5b2		07/16/96
# -----------------------------------------------
#  Now works with Alpha 6.1 and higher.
#
# 1.5b3		07/18/96
# -----------------------------------------------
# Now works with Alpha 6.1 and higher.
# Added Floating menu...
#
# 1.5		10/22/96
# -----------------------------------------------
# Slight bug fixes
#
# 1.5.1		10/23/96
# -----------------------------------------------
# Added some more apple event and floating palatte options.
#
# 1.5.2		11/02/96
# -----------------------------------------------
# Attempt to fix ome context switching weirdness
#
# 1.5.3		11/02/96
# -----------------------------------------------
# See 1.5.2
#
# 1.5.4		11/05/96
# -----------------------------------------------
# Added terminal output windows for PS/TeX/MIF/etc.
#
# 1.5.5		11/06/96
# -----------------------------------------------
# Added a "Scripts" menu which auto loads any script in gnuplots
#     "Scripts" folder (or subfolder)
# Made terminal output window creation faster
#
# 1.5.6		11/07/96
# -----------------------------------------------
# Fixed a few floating menu buggers
#
# 1.5.7		11/13/96
# -----------------------------------------------
# Check OUTP event for "Sorry, " string so that help for unknown item
#     will be sent to console rather than a new output terminal page
#
# 1.5.8		12/05/96
# -----------------------------------------------
# plot '-' now works
# Pause in demo-mode works better
# Added option to rebuild scripts menu
#
# 1.5.9		12/05/96
# -----------------------------------------------
# Repaired broken pwd display
#
# 1.5.9b	12/10/96
# -----------------------------------------------
# Repaired broken scripts menu
# Added a "edit scripts" menu----eventually, this one will go away,
#     but the functionality will be retained
#
# 1.6		12/23/96
# -----------------------------------------------
# Floating palatte now very useful.  User can run a script by selecting
#     a script menu item, or edit the script by selecting the script menu
#     item with the option key held down
#
# 1.7-1.9 	12/05/00
# -----------------------------------------------
# Various updates by Vince.
#
# 2.0 	12/05/00
# -----------------------------------------------
# An update by Craig for distribution with Alpha 7.4.
# Added "graphButton/killGraphButton" to menu.
# Added a simple "plot" electric.
# 
# ===========================================================================

# ===========================================================================
# 
# .