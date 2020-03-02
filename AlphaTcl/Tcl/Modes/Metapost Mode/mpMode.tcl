## -*-Tcl-*- (nowrap) (tabsize:4)
# File: "mpMode.tcl"
#                   Created: 1999-09-21
#         Last modification: 2005-08-31 12:00:15
# Author: Bernard Desgraupes  
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
# Description: this is Metapost Mode for Alpha. This version requires Alpha 7.4 or greater.
# It has been mainly tested with Alpha8.
# Please read the instructions in the Metapost Help file (found in Alpha's Help menu)
# CMacTeX Metapost and OzMetapost are both supported. For better results,
# use CMacTeX version 3.4 or later.
# 
# The Metapost Mode package for Alpha is made of the following files:
# 	    mpCommands.tcl
# 	    mpEngine.tcl
# 	    mpMacros.tcl
# 	    mpMenus.tcl
# 	    mpMode.tcl
# 	    mpUtilities.tcl
# 	    mpServices.tcl
# 	    
# (c) Copyright: Bernard Desgraupes, 1999-2005
#         All rights reserved.
# This software is free software. See licensing terms in the Metapost Help file.

alpha::mode [list Mp Metapost] 2.2 mpMenu {*.mp *.mpx} mpMenu {
    # Script to execute at Alpha startup
    addMenu mpMenu "Mp" Mp
    set unixMode(mp) Mp
} uninstall {
    this-directory
} maintainer {
	"Bernard Desgraupes" <bdesgraupes@easyconnect.fr> <http://webperso.easyconnect.fr/bdesgraupes/> 
} description {
    Supports the editing of Metapost files
} help {
    file "Metapost Help"
}

proc mpMode.tcl {} {}

# Only register these if we've actually loaded the mode or menu at least once.
hook::register requireOpenWindowsHook [list Mp runTheBuffer] 1 
hook::register requireOpenWindowsHook [list Mp saveAndRun] 1 

namespace eval Mp {}

# Metapost mode Preferences
# =========================

prefs::removeObsolete MpmodeVars(electricTab)

newPref var lineWrap {0} Mp
newPref f autoMark {0} Mp
# To automatically indent the new line produced by pressing <return>, turn
# this item on. The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn {1} Mp
# Comment char
newPref v prefixString {% } Mp
# Functions syntax
newPref v funcExpr {^(def|vardef|primarydef|secondarydef|tertiarydef) [^\(=@;\r]+} Mp
newPref v wordBreak {[_\w]+} Mp
# Name of the printer mode for Metafont in case you process a file with
# the mfplain base: for instance cx at 300dpi, canonex at 600dpi etc.
newPref v mpModeForPrinter canonex Mp
# Customize the name of the beginfig macro.
newPref v userBeginfig beginfig Mp
# Customize the name of the endfig macro.
newPref v userEndfig endfig Mp
# Default colo(u)rs for the keywords
newPref v commentColor red Mp
newPref v funcColor cyan Mp
newPref v keywordColor blue Mp
newPref v stringColor green Mp
newPref v primitiveColor magenta Mp
# Set the path to the plain.mp file on your installation.
newPref file pathToPlainMpFile {} Mp
# Set the path to the mfplain.mp file on your installation.
newPref file pathToPlainMpFile {} Mp
# Set the path to the mfplain.mem file on your installation (not necessarily exists).
newPref file pathToMfplainMpFile {} Mp
# Set the path to the plain.mf file on your installation.
newPref file pathToPlainMfFile {} Mp
# Set the path to the modes.mf file on your installation.
newPref file pathToModesMfFile {} Mp


# Initialization of some variables
# ================================
set mp_params(tailname) ""
set mp_params(chosenMode) proof
set mp_params(mag) 1
set mp_params(magstep) 0
set mp_params(memFile) ""
set mp_params(prefix-mpx) "("
set mp_params(prefix-log) "("
set mp_params(extensions) [list log dvi mpx]
foreach v $mp_params(extensions) {
	set mp_params(delete-$v) 0
}
unset v

set Mp::commentCharacters(General) "%"
set Mp::commentCharacters(Paragraph) [list "%% " " %%" " % "]
set Mp::commentCharacters(Box) [list "%" 1 "%" 1 "%" 3]

proc mpMenu {} {}

hook::register activateHook Mp::rebuildMetapostUtils

# Mode specific goodies
# =====================
# 
# Syntax Coloring
# ---------------

set mpKeywords {
	abs ahangle ahlength arrowhead augment auto autogrid background bbox
	bboxmargin beginchar beginfig begingraph beveled black blacker
	blankpicture blue bluepart bot boxit boxjoin btex buildcycle butt bye
	byte capsule_def ceiling center change_width character checksum
	circleit circmargin clear_pen_memory clearit clearpen clearxy clip
	codingscheme color comment counterclockwise currentpen currentpicture
	cutafter cutbefore cutdraw cutoff cuttings dashed dashpattern decr
	defaultdx defaultdy defaultfont defaultpen defaultscale
	define_blacker_pixels define_good_x_pixels define_good_y_pixels
	define_pixels define_whole_pixels dir direction directionpoint ditto
	div dotlabel dotlabel.bot dotlabel.lft dotlabel.llft dotlabel.lrt
	dotlabel.rt dotlabel.top dotlabel.ulft dotlabel.urt dotlabels
	dotlabels.bot dotlabels.lft dotlabels.llft dotlabels.lrt dotlabels.rt
	dotlabels.top dotlabels.ulft dotlabels.urt dotprod downto draw
	drawarrow drawboxed drawboxes drawdblarrow drawdot drawoptions
	drawunboxed endchar endfig endgraph eps epsilon erase etex evenly
	exitunless extra_beginchar extra_beginfig extra_endchar extra_endfig
	extraspace face family fill filldraw flex font_coding_scheme
	font_extra_space font_identifier font_normal_shrink font_normal_space
	font_normal_stretch font_quad font_size font_slant font_x_height
	fontsize format frame fullcircle gdata gdotlabel gdraw gdrawarrow
	gdrawdblarrow gfill glabel gobble gobbled good.bot good.lft good.rt
	good.top good.x good.y green greenpart grid halfcircle har hide
	identity image incr infinity infont init_numbers interact interpath
	intersectionpoint inverse italcorr itick join_radius label label.bot
	label.lft label.llft label.lrt label.rt label.top label.ulft label.urt
	labelfont labeloffset labels lft linecap linejoin llcorner loggingall
	lrcorner mp_params(magstep) makegrid makelabel max min mitered
	miterlimit mod mode_setup mpxbreak Mreadpath numeric_pickup_ numtok
	o_correction or otick OUT pen_bot pen_lft pen_pickup_ pen_rt pen_top
	penlabels penpos penrazor penspeck pensquare penstroke pic pickup plot
	prologues proofrule proofrulethickness quad quartercircle range red
	redpart reflectedabout rotatedaround round rounded rt savepen setbounds
	setcoords setrange shipit shrink slant softjoin solve space squared
	stop stretch superellipse takepower tensepath thelabel thelabel.bot
	thelabel.lft thelabel.llft thelabel.lrt thelabel.rt thelabel.top
	thelabel.ulft thelabel.urt thru tolerance top tracingall
	tracinglostchars tracingnone truecorners ulcorner undraw undrawdot
	unfill unfilldraw unitsquare unitvector upto urcorner verbatimtex
	whatever white withcolor withdots xheight zscale
}

regModeKeywords  -e {%} -c $MpmodeVars(commentColor) \
  -k $MpmodeVars(keywordColor)  -s $MpmodeVars(stringColor) Mp $mpKeywords
unset mpKeywords

set mpPrimitives {
	ASCII addto also and angle at atleast autorounding batchmode begingroup
	boolean char charcode chardp chardx chardy charexists charext charht
	charic charlist charwd contour controls cosd cull curl cycle day
	decimal def delimiters designsize directiontime display doublepath dump
	dropping else elseif end enddef endfor endgroup endinput errhelp
	errmessage errorstopmode everyjob exitif expandafter expr extensible
	false fi fillin floor fontdimen fontmaking forever forsuffixes from
	granularity headerbytes hex hppp if inner input interim
	intersectiontimes inwindow jobname keeping kern known length let
	ligtable makepath makepen message mexp mlog month newinternal
	nonstopmode normaldeviate not nullpen nullpicture numeric numspecial
	oct odd outer pair path pausing pen pencircle penoffset picture point
	postcontrol precontrol primary primarydef proofing quote randomseed
	readstring reverse rotated save scaled scantokens scrollmode
	secondarydef shifted shipout show showdependencies showstats
	showstopping showtoken showvariable sind slanted smoothing special sqrt
	step str string subpath substring suffix tension tertiary tertiarydef
	time to totalweight tracingcapsules tracingchoices tracingcommands
	tracingedges tracingequations tracingmacros tracingonline tracingoutput
	tracingpens tracingrestores tracingspecs tracingstats tracingtitles
	transform transformed true turningcheck turningnumber uniformdeviate
	unknown until vardef vppp warningcheck withpen withweight xoffset xpart
	xscaled xxpart xypart year yoffset ypart yscaled yxpart yypart zscaled
}

regModeKeywords  -a -k $MpmodeVars(primitiveColor) Mp $mpPrimitives
# The mpPrimitives list is used in Mp::DblClick


# Completions
# -----------

set completions(Mp) {contraction completion::cmd completion::electric}

# List of commands for completion: words with less than six letters are not listed.

set Mpcmds [list ahangle ahlength arrowhead atleast augment \
  autogrid autorounding background batchmode bboxmargin beginchar \
  beginfig begingraph begingroup beveled blacker blankpicture \
  bluepart boolean boxjoin buildcycle capsule_def \
  ceiling center change_width character charcode chardp chardx chardy \
  charexists charext charht charic charlist charwd checksum circleit circmargin \
  clear_pen_memory clearit clearpen clearxy codingscheme comment \
  contour controls counterclockwise currentpen currentpicture \
  cutafter cutbefore cutdraw cutoff cuttings dashed dashpattern decimal \
  defaultdx defaultdy defaultfont defaultpen defaultscale \
  define_blacker_pixels define_good_x_pixels define_good_y_pixels define_pixels define_whole_pixels \
  delimiters designsize direction directionpoint directiontime display \
  dotlabel dotlabel.bot dotlabel.lft dotlabel. dotlabel.lrt dotlabel.rt dotlabel.top \
  dotlabel. dotlabel.urt dotlabels dotlabels.bot dotlabels.lft dotlabels. dotlabels.lrt \
  dotlabels.rt dotlabels.top dotlabels. dotlabels.urt dotprod doublepath downto \
  drawarrow drawboxed drawboxes drawdblarrow drawdot drawoptions drawunboxed \
  dropping elseif endchar enddef endfig endfor endgraph endgroup endinput \
  epsilon errhelp errmessage errorstopmode evenly everyjob exitif exitunless expandafter \
  extensible extra_beginchar extra_beginfig extra_endchar extra_endfig \
  extraspace family filldraw fillin font_coding_scheme \
  font_extra_space font_identifier font_normal_shrink font_normal_space \
  font_normal_stretch font_quad font_size font_slant font_x_height fontdimen \
  fontmaking fontsize forever format forsuffixes fullcircle \
  gdotlabel gdrawarrow gdrawdblarrow glabel gobble gobbled \
  good.bot good.lft good.rt good.top good.x good.y granularity greenpart \
  halfcircle headerbytes identity infinity infont init_numbers \
  interact interim interpath intersectionpoint intersectiontimes inverse \
  inwindow italcorr jobname join_radius keeping \
  label.bot label.lft label.llft label.lrt label.rt label.top label.ulft label.urt \
  labelfont labeloffset labels length ligtable linecap linejoin llcorner loggingall lrcorner \
  magstep makegrid makelabel makepath makepen message mitered miterlimit \
  mode_setup mpxbreak Mreadpath newinternal nonstopmode normaldeviate nullpen \
  nullpicture numeric numeric_pickup_ numspecial numtok o_correction \
  pausing pen_bot pen_lft pen_pickup_ pen_rt pen_top pencircle penlabels penoffset \
  penpos penrazor penspeck pensquare penstroke pickup picture \
  postcontrol precontrol primary primarydef prologues proofing proofrule proofrulethickness \
  quartercircle randomseed readstring redpart reflectedabout \
  reverse rotated rotatedaround rounded savepen scaled scantokens \
  scrollmode secondarydef setbounds setcoords setrange shifted shipit shipout \
  showdependencies showstats showstopping showtoken showvariable shrink \
  slanted smoothing softjoin special squared \
  stretch string subpath substring suffix superellipse takepower \
  tensepath tension tertiary tertiarydef thelabel thelabel.bot thelabel.lft thelabel.llft \
  thelabel.lrt thelabel.rt thelabel.top thelabel.ulft thelabel.urt \
  tolerance totalweight tracingall tracingcapsules tracingchoices tracingcommands \
  tracingedges tracingequations tracinglostchars tracingmacros tracingnone \
  tracingonline tracingoutput tracingpens tracingrestores tracingspecs \
  tracingstats tracingtitles transform transformed truecorners turningcheck \
  turningnumber ulcorner undraw undrawdot unfill unfilldraw uniformdeviate \
  unitsquare unitvector unknown urcorner vardef verbatimtex \
  warningcheck whatever withcolor withdots withpen withweight xheight \
  xoffset xscaled xxpart xypart yoffset yscaled yxpart yypart zscale zscaled \
]



# Abbreviations
# -------------
set Mpelectrics(bf)   "×kill0$MpmodeVars(userBeginfig)(\"¥¥\",¥¥,¥¥,¥¥);\"¥¥\";\n¥¥\n\n$MpmodeVars(userEndfig);\n¥¥"
set Mpelectrics(bg)   "×kill0begingroup ¥¥\n\nendgroup;\n¥¥"
set Mpelectrics(bt)   "×kill0btex ¥¥ etex¥¥"
set Mpelectrics(vt)   "×kill0bverbatimtex ¥¥ etex¥¥"
set Mpelectrics(dbp) "×kill0define_blacker_pixels(¥¥);\n¥¥"
set Mpelectrics(dcp) "×kill0define_corrected_pixels(¥¥);\n¥¥"
set Mpelectrics(dgxp) "×kill0define_good_x_pixels(¥¥);\n¥¥"
set Mpelectrics(dgyp) "×kill0define_good_y_pixels(¥¥);\n¥¥"
set Mpelectrics(dhcp) "×kill0define_horizontal_corrected_pixels(¥¥);\n¥¥"
set Mpelectrics(dp) "×kill0define_pixels(¥¥);\n¥¥"
set Mpelectrics(dwp) "×kill0define_whole_pixels(¥¥);\n¥¥"
set Mpelectrics(dwvp) "×kill0define_whole_vertical_pixels(¥¥);\n¥¥"
set Mpelectrics(dwvbp) "×kill0define_whole_vertical_blacker_pixels(¥¥);\n¥¥"
set Mpelectrics(prt) "×kill0proofrulethickness"
set Mpelectrics(sc) "×kill0screen_cols:= ¥¥;"
set Mpelectrics(sr) "×kill0screen_rows:= ¥¥;"
set Mpelectrics(xpa) "×kill0expandafter "

set Mpelectrics(for)  " ¥¥ : ¥¥ endfor;\n¥¥"
set Mpelectrics(def)   " ¥¥=\n¥¥\nenddef;\n¥¥"
set Mpelectrics(prim)   "×kill0primarydef ¥¥=\n¥¥\nenddef;\n¥¥"
set Mpelectrics(sec)   "×kill0secondarydef ¥¥=\n¥¥\nenddef;\n¥¥"
set Mpelectrics(ter)   "×kill0tertiarydef ¥¥=\n¥¥\nenddef;\n¥¥"
set Mpelectrics(var)   "×kill0vardef ¥¥=\n¥¥\nenddef;\n¥¥"
set Mpelectrics(forever)   " ¥¥ endfor;\n¥¥"
set Mpelectrics(forsuffixes)   " ¥¥ : ¥¥ endfor;\n¥¥"
set Mpelectrics(if)   " ¥¥ : ¥¥ fi\n¥¥"

# Contractions
# ------------
set Mpelectrics(cu'n) "×kill0currentpen "
set Mpelectrics(cu'p) "×kill0currentpicture "
set Mpelectrics(di'p) "×kill0directionpoint "
set Mpelectrics(di't) "×kill0directiontime "
set Mpelectrics(re'a) "×kill0reflectedabout(¥¥,¥¥) ¥¥"
set Mpelectrics(ro'a) "×kill0rotatedaround(¥¥,¥¥) ¥¥"
set Mpelectrics(x'b) "×kill0extra_beginfig := \"¥¥\""
set Mpelectrics(x'e) "×kill0extra_endfig := \"¥¥\""
set Mpelectrics(i'p) "×kill0intersectionpoint "
set Mpelectrics(i't) "×kill0intersectiontimes "

	
# Key Bindings
# ------------

# Define Metapost specific key bindings: all of them use 'ctrl-p' followed
# by a letter. p stands for <P>ost.
Bind 'p' <z> prefixChar Mp
# Now key bindings to process the <b>uffer or a <f>ile
# 'ctrl-p b' and 'ctrl-p f' respectively.
Bind 'b' <P> {Mp::menuProc "Metapost" "runTheBuffer"}
Bind 'f' <P> {Mp::menuProc "Metapost" "runAFile"}
# A key binding ('ctrl-p n') to create a new figs template
Bind 'n' <P> {Mp::newtemplateProc} Mp
# A key binding ('ctrl-p g') to edit the log file
Bind 'g' <P> {Mp::editAuxiliary log} Mp
# A key binding ('ctrl-p x') to edit the mpx file
Bind 'x' <P> {Mp::editAuxiliary mpx} Mp

# File Marking
# ------------

# All the beginfig/endfig groups are marked even if the name of this
# environment was changed in the mode specific prefs (if you chose to call
# them "myMpFig", then all the "myMpFig" instructions would be marked)
proc Mp::MarkFile {args} {
	win::parseArgs win
	global MpmodeVars 
	set bgnfig $MpmodeVars(userBeginfig)
	set pos [minPos]
	set end [maxPos -w $win]
	while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "^$bgnfig\[^\r\n\]*$" $pos} res]} {
		set start [lindex $res 0]
		set end [lindex $res 1]
		set txt [getText -w $win [pos::math -w $win $start - 1] $end]
		set pos [nextLineStart -w $win $end]
		set inds($txt) [lineStart -w $win [pos::math -w $win $start - 1]]
	}
	
	if {[info exists inds]} {
		foreach f [lsort -dictionary [array names inds]] {
			set next [nextLineStart -w $win $inds($f)]
			setNamedMark -w $win $f $inds($f) $next $next
		}
	}
}


# The "{}" menu
# -------------
# The "{}" pop-up menu contains all the def, vardef, etc. definitions, as
# well as the files included with an "input" command.
proc Mp::parseFuncs {} {Mf::parseFuncs}



# Command-Double-click
# --------------------
# A Command-Double-Click on a keyword leads to its definition. This proc
# looks first for a definition in the current file itself, then in the list
# of primitives, then in all the Metapost macros files (boxes.mp,
# mfplain.mp, plain.mp etc. Note that plain.mp is scanned first) and
# finally in the other source files located in the same folder and included
# by an "input" command (typically they are macros files).

set mp_params(internals) [list "ahangle" "ahlength" "background" "bboxmargin" "beveled" \
  "black" "blacker" "blue" "butt" "colorblack" "currentwindow" "defaultpen" "defaultscale" \
  "displaying" "eps" "epsilon" "green" "infinity" "join_radius" "labeloffset" "mitered" \
  "number_of_modes" "o_correction" "pair" "path" "pen_bot" "pen_lft" \
  "pen_rt" "pen_top" "pen_bot" "pen_lft" "pen_rt" "pen_top" "pixels_per_inch" \
  "red" "rounded" "screen_cols" "screen_rows" "squared" "tolerance" "white" \
 ]

proc Mp::DblClick {from to} {
	global MpmodeVars mp_params
	selectText $from $to
	set word [getText $from $to]
	set mp_params(parse) 0
	# First we look for the word's definition in the current file
	set pos [minPos]
	if {![catch {eval [concat search -f 1 -r 1 -m 1 -i 0\
	  [list "\(var|primary|secondary|tertiary\)?def\[ \\w\]+$word" $pos]]} res]} {
		goto [lineStart [lindex $res 0]]
		selectText [lindex $res 0] [lindex $res 1]
		return
	}
	# If search failed, check if it is a Metafont or Metapost primitive
	if {[expr {[lsearch -exact $mpPrimitives "$word"] > -1}]} {
		alertnote "\"$word\" is a primitive.\rSee the MetafontBook or Metapost doc."
		return
	}
	# If search failed, check if it is an internal constant
	if {[expr {[lsearch -exact $mp_params(internals) "$word"] > -1}]} {
		alertnote "\"$word\" is a predefined constant.\r\
		  See the MetafontBook or Metapost User's Manual."
		return
	}
	# If search failed, look in the plain.mf macros file. Its path must
	# have been defined in the mode prefs.
	if {![file exists $MpmodeVars(pathToPlainMpFile)]} {
		alertnote "Can't find file plain.mp" "Metapost Mode will now ask you to find it."
		if {[catch {getfile "Find file plain.mp"} thepath]} {return} 
		set MfmodeVars(pathToPlainMpFile) $thepath
		prefs::modified MfmodeVars(pathToPlainMpFile)
	}    
	set mpdir [file dirname $MpmodeVars(pathToPlainMpFile)]
	set cid [scancontext create]
	set searchstri "(var|primary|secondary|tertiary)?def\[ \\w\]+$word\[^\\w\]+"
	set searchstrii "(boolean|newinternal|path|pen|picture|string|transform)\[ ,\\w\]+$word"
	scanmatch $cid $searchstri {set matches(PlainMp) 1}
	scanmatch $cid $searchstrii {set matches(PlainMp) 1}
	# In fact, scan all the .mp files located at the same level as plain.mp
	set filesinmpdir [glob -nocomplain -tail -dir $mpdir *.mp]
	# Reorder this list to scan plain.mp before the others
	set indx [lsearch -exact $filesinmpdir "plain.mp"]
	set filesinmpdir [lreplace $filesinmpdir $indx $indx]
	set filesinmpdir [linsert $filesinmpdir 0 "plain.mp"]
	set found 0
	foreach f $filesinmpdir {
		if {![catch {set fid [open [file join $mpdir $f]]}]} {
			scanfile $cid $fid
			close $fid
		}
		if {[info exists matches]} {
			edit -c -r [file join $mpdir $f]
			goto $matchInfo(offset)
			set res [search -s -f 1 -r 0 -i 0 -n $word $matchInfo(offset)]
			selectText $matchInfo(offset) [lindex $res 1]
			set found 1
			break
		}
	}  
	# As a last resort, search all the include files found in the
	# source file (supposing they are located in the same folder)
	if {!$found} {
		set inputs [Mf::findInputFiles 0]
		foreach filename $inputs {
			set fullname [file join [file dirname [win::Current]] $filename]
			if {[file exists $fullname]} {
				if {![catch {set fid [open $fullname]}]} {
					status::msg "Scanning '$filename'"
					scanfile $cid $fid
					close $fid
				}
			} 
			if {[info exists matches]} {
				edit -c -r $fullname
				goto $matchInfo(offset)
				set res [search -s -f 1 -r 0 -i 0 -n $word $matchInfo(offset)]
				selectText $matchInfo(offset) [lindex $res 1]
				break
			}	
		}
		status::msg "Could'nt find a definition for \"$word\"."
	} 
	
	scancontext delete $cid
}


# Option-click on title bar
# -------------------------
# An Option-Click on a the title bar displays a list of all the mp/mpx and 
# log files located in the "current" folder if one is selected in the
# "Metapost Utils" submenu or, otherwise, in the "local" folder (folder of
# current window).

proc Mp::OptionTitlebar {} {
	global mp_params minItemsInTitlePopup
	set minItemsInTitlePopup 1
	set dir [file dirname [win::Current]]
	set filesinlocaldir [glob -nocomplain -tail -dir $dir *.mp*]
	set logsinlocaldir [glob -nocomplain -tail -dir $dir *.log]
	if {[llength $filesinlocaldir] && [llength $logsinlocaldir]} {
		lappend filesinlocaldir "-"	
	} 
	return [concat $filesinlocaldir $logsinlocaldir]
}


proc Mp::OptionTitlebarSelect {item} {
    global mp_params
    if {$item == "-"} {return}
	edit -c -w [file join [file dirname [win::Current]] $item]
}


# ---------------------------------------------------------------------
# Now load the files containing the menu definitions and xserv services
# ---------------------------------------------------------------------
if {![alpha::tryToLoad "Initializing Metapost modeÉ" \
  mpMenus.tcl {Loading Metapost menusÉ} \
  mpServices.tcl {Loading Metapost servicesÉ} \
  ]} {
    alertnote "Error: the Metapost menu did not properly load."
}

status::msg "Mp mode initialization complete."
