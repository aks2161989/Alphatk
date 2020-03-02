## -*-Tcl-*- (nowrap)
# File: "mfMode.tcl"
#                        Created: 1999-03-28 14:31:57
#              Last modification: 2005-07-15 10:28:02
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: 
# Metafont Mode is a mode for the text editor Alpha: it is designed to make
# writing, processing and testing of Metafont source files easier.
# 
# As of this release, both <CMacTeX Metafont> and <OzMetafont> are  supported
# (together with their respective gftopk, gftodvi, dvipreviewer and tftopl).
# 
# Read the instructions in the Metafont Help file (found in Alpha's Help menu)
# 
# The Metafont Mode package for Alpha is made of the following files and 
# will not work properly (will not work at all) if any of them is missing:
# 	    mfCommands.tcl
# 	    mfEngine.tcl
# 	    mfMacros.tcl
# 	    mfMenus.tcl
# 	    mfMode.tcl
# 	    mfPostprocess.tcl
# 	    mfServices.tcl
# 	    mfUtilities.tcl
#  
# (c) Copyright: Bernard Desgraupes, 1999-2005
#         All rights reserved.
# This software is free software. See licensing terms in the Metafont Help file.
#  
##

alpha::mode [list Mf Metafont] 2.1 mfMenu {*.mf *.vpl} mfMenu {
    # Script to execute at Alpha startup
    addMenu mfMenu "Mf" Mf
    set unixMode(mf) Mf
} uninstall {
    this-directory
} maintainer {
    "Bernard Desgraupes" <bdesgraupes@easyconnect.fr> <http://webperso.easyconnect.fr/bdesgraupes/alpha.html> 
} description {
    Supports the editing of Metafont files
} help {
    file "Metafont Help"
}

proc mfMode.tcl {} {}

# Only register these if we've actually loaded the mode or menu at least once.
hook::register requireOpenWindowsHook [list Mf processTheBuffer] 1 
hook::register requireOpenWindowsHook [list Mf saveAndRun] 1 

namespace eval Mf {}

# Preferences
# ===========

prefs::removeObsolete MfmodeVars(electricTab)

newPref var lineWrap {0} Mf
# Set this flag if you want your source file to be marked automatically when it is opened.
newPref f autoMark {0} Mf
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn {1} Mf
# Metafont particular processing option.
newPref f gfcorners 0 Mf  Mf::shadowPrefs
# Metafont particular processing option.
newPref f imagerules 0 Mf   Mf::shadowPrefs
# Metafont particular processing option.
newPref f nodisplays 0 Mf   Mf::shadowPrefs
# Metafont particular processing option.
newPref f notransforms 0 Mf   Mf::shadowPrefs
# Metafont particular processing option.
newPref f screenstrokes 0 Mf   Mf::shadowPrefs
# Metafont particular processing option.
newPref f screenchars 0 Mf   Mf::shadowPrefs
# How to handle comments continuation
newPref v commentsContinuation 2 Mf "" \
  [list "only at line start" "spaces allowed" "anywhere"] index
# Name of the printer mode for Metafont: for instance cx at 300dpi, 
# canonex at 600dpi etc. Default is canonex.
newPref v mfModeForPrinter canonex Mf
# Prefix for comments in Metafont source files.
newPref v prefixString {% } Mf
# Regular expression used in the Functions pop-up menu 
# (above the M pop-up menu, top right of the current window).
newPref v funcExpr {^(def|vardef|primarydef|secondarydef|tertiarydef) [^\(=@;\r]+} Mf
# Metafont mode's notion of what is a word.
newPref v wordBreak {[_\w]+} Mf
# To customize the denomination of the beginchar macro.
newPref v userBeginchar beginchar Mf
# To customize the denomination of the endchar macro.
newPref v userEndchar endchar Mf
# Default colo(u)rs for the keywords
newPref v commentColor red Mf
newPref v keywordColor blue Mf
newPref v stringColor green Mf
newPref v primitiveColor magenta Mf
# Access path to file modes.mf defining the parameters for all possible
# Metafont modes.
newPref file pathToModesMfFile {} Mf
# Access path to file plain.mf defining Metafont's basic macros.
newPref file pathToPlainMfFile {} Mf


# Initialization of some variables
# ================================

set mf_params(tailname) ""
set mf_params(chosenMode) proof
set mf_params(baseFile) ""
set mf_params(done) 0
set mf_params(tfmdone) 0
set mf_params(mag) 1
set mf_params(magstep) 0
set mf_params(modes) [list proof smoke localfont userDefined]
set mf_params(options) [list gfcorners imagerules nodisplays notransforms screenchars screenstrokes]
foreach v $mf_params(options) {
	set mf_params($v) [set MfmodeVars($v)]
}
foreach v [list tfm pl gf dvi log] {
    set mf_params(prefix-$v) "("
}
set mf_params(extensions) [list log gf pk dvi tfm vf pl vpl]
foreach v $mf_params(extensions) {
	set mf_params(delete-$v) 0
}
unset v

set Mf::commentCharacters(General) "%"
set Mf::commentCharacters(Paragraph) [list "%% " " %%" " % "]
set Mf::commentCharacters(Box) [list "%" 1 "%" 1 "%" 3]


proc mfMenu {} {}

hook::register activateHook Mf::rebuildSubmenus Mf



# Mode specific goodies
# =====================
# 
# Syntax Coloring
# ---------------
# We define two groups of keywords:
# -  the macros of the Metafont plain format. Default color: blue
# -  the Metafont primitives. Default color: magenta
# These colors can be modified in the mode prefs: see "Keyword Color" 
# and "Primitives Color".

set mfKeyWords { 
	abs beginchar blacker blankpicture bot bye byte capsule_def ceilling 
	change_width checksum clear_pen_memory clearit clearpen 
	clearxy codingscheme counterclockwise cullit currentpen currentpicture 
	currenttransform currentwindow cutdraw cutoff decr define_blacker_pixels 
	define_good_x_pixels define_good_y_pixels define_pixels define_whole_pixels 
	direction directionpoint displaying ditto dotprod downto draw drawdot endchar 
	eps epsilon erase exitunless extra_beginchar extra_endchar extraspace face 
	family fill filldraw fix_units flex font_coding_scheme font_extra_space 
	font_identifier font_normal_shrink font_normal_space font_normal_stretch 
	font_quad font_size font_slant font_x_height fullcircle gfcorners gobble 
	gobbled good.bot good.lft good.rt good.top good.x good.y grayfont halfcircle 
	hide hround identity imagerules incr infinity interact interpath intersectionpoint 
	inverse italcorr join_radius label labelfont labels lft loggingall makegrid 
	makelabel max min mod mode_setup nextlarger nodisplays notransforms numtok 
	o_correction of openit or pen_bot pen_lft pen_rt pen_top penlabels 
	penpos penrazor penspeck pensquare penstroke pickup pixels_per_inchs proofoffset 
	proofrule proofrulethickness quad quartercircle range reflectedabout relax rep 
	rotatedaround round rt savepen screen_cols screen_rows screenchars screenrule 
	screenstrokes secondary shipit showit shrink slant slantfont solve space stop 
	stretch superellipse tensepath text thru titlefont tolerance top tracingall 
	tracingnone undraw undrawdot unfill unfilldraw unitpixel unitsquare upto 
	varchar vround whatever xheight 
}

regModeKeywords -C Mf {}
regModeKeywords -a -e {%} -c $MfmodeVars(commentColor) \
  -k $MfmodeVars(keywordColor)  -s $MfmodeVars(stringColor) Mf $mfKeyWords

set mfPrimitives { 
	ASCII addto also and angle at atleast autorounding batchmode
	begingroup boolean char character charcode chardp chardx chardy charexists
	charext charht charic charlist charwd comment contour controls cosd cull curl
	cycle day decimal def delimiters designsize designunits directiontime
	display doublepath dump dropping else elseif end enddef endfor
	endgroup endinput errhelp errmessage errorstopmode everyjob exitif
	expandafter expr extensible false fi fillin floor fontdimen fontmaking
	fontname fontdsize fontat forever forsuffixes from granularity
	headerbytes hex hppp if inner input interim intersectiontimes inwindow
	jobname keeping kern known krn length let lig ligtable makepath
	makepen map mapfont message mexp mlog month newinternal nonstopmode
	normaldeviate not nullpen nullpicture numeric numspecial oct odd
	openwindow outer pair parameter path pausing pen pencircle penoffset picture
	point postcontrol precontrol primary primarydef proofing quote
	randomseed readstring reverse rotated save scaled scantokens
	scrollmode secondarydef setchar shifted shipout show showdependencies
	showstats showstopping showtoken showvariable sind slanted smoothing
	special sqrt step str string subpath substring suffix tension tertiary
	tertiarydef time to totalweight tracingcapsules tracingchoices
	tracingcommands tracingedges tracingequations tracingmacros
	tracingonline tracingoutput tracingpens tracingrestores tracingspecs
	tracingstats tracingtitles transform transformed true turningcheck
	turningnumber uniformdeviate unknown until vardef vppp warningcheck
	withpen withweight xoffset xpart xscaled xxpart xypart year yoffset
	ypart yscaled yxpart yypart zscaled 
}

regModeKeywords  -a -k $MfmodeVars(primitiveColor) Mf $mfPrimitives


# Completions
# -----------

set completions(Mf) {contraction completion::cmd completion::electric}

set Mfcmds [lsort -dictionary [concat $mfKeyWords $mfPrimitives]]

# We don't need mfKeyWords anymore (but mfPrimitives is used in Mf::DblClick):
unset mfKeyWords 

  
# # # # # Abbreviations # # # # #
set Mfelectrics(bc)   "×kill0$MfmodeVars(userBeginchar)(\"¥¥\",¥¥,¥¥,¥¥);\"¥¥\";\r¥¥\r\r$MfmodeVars(userEndchar);\r¥¥"
set Mfelectrics(bg)   "×kill0begingroup ¥¥\r\rendgroup;\r¥¥"
set Mfelectrics(dp) "×kill0define_pixels(¥¥);\r¥¥"
set Mfelectrics(dbp) "×kill0define_blacker_pixels(¥¥);\r¥¥"
set Mfelectrics(dcp) "×kill0define_corrected_pixels(¥¥);\r¥¥"
set Mfelectrics(dgxp) "×kill0define_good_x_pixels(¥¥);\r¥¥"
set Mfelectrics(dgyp) "×kill0define_good_y_pixels(¥¥);\r¥¥"
set Mfelectrics(dhcp) "×kill0define_horizontal_corrected_pixels(¥¥);\r¥¥"
set Mfelectrics(dwp) "×kill0define_whole_pixels(¥¥);\r¥¥"
set Mfelectrics(dwvp) "×kill0define_whole_vertical_pixels(¥¥);\r¥¥"
set Mfelectrics(dwvbp) "×kill0define_whole_vertical_blacker_pixels(¥¥);\r¥¥"
set Mfelectrics(sc) "×kill0screen_cols:= ¥¥;"
set Mfelectrics(sr) "×kill0screen_rows:= ¥¥;"
set Mfelectrics(xpa) "×kill0expandafter "

set Mfelectrics(for)  " ¥¥ : ¥¥ endfor;\r¥¥"
set Mfelectrics(def)   " ¥¥=\r¥¥\renddef;\r¥¥"
set Mfelectrics(prim)   "×kill0primarydef ¥¥=\r¥¥\renddef;\r¥¥"
set Mfelectrics(sec)   "×kill0secondarydef ¥¥=\r¥¥\renddef;\r¥¥"
set Mfelectrics(ter)   "×kill0tertiarydef ¥¥=\r¥¥\renddef;\r¥¥"
set Mfelectrics(vardef)   " ¥¥=\r¥¥\renddef;\r¥¥"
set Mfelectrics(forever)   " ¥¥ endfor;\r¥¥"
set Mfelectrics(forsuffixes)   " ¥¥ : ¥¥ endfor;\r¥¥"
set Mfelectrics(if)   " ¥¥ : ¥¥ fi\r¥¥"

# # # # # contractions # # # # #
set Mfelectrics(cu'n) "×kill0currentpen "
set Mfelectrics(cu'p) "×kill0currentpicture "
set Mfelectrics(cu't) "×kill0currenttransform "
set Mfelectrics(cu'w) "×kill0currentwindow "
set Mfelectrics(di'p) "×kill0directionpoint "
set Mfelectrics(di't) "×kill0directiontime "
set Mfelectrics(re'a) "×kill0reflectedabout(¥¥,¥¥) ¥¥"
set Mfelectrics(ro'a) "×kill0rotatedaround(¥¥,¥¥) ¥¥"	


# Key Bindings
# ------------

# Metafont specific key bindings: all of them
# use 'ctrl-m' followed by a letter.
# For instance, key bindings to choose the processing mode:
#    hit ctrl-m and then one of the letters p, s, l or u to select
#    "proof", "smoke", "localfont" or "user defined" modes respectively.
Bind 'm' <z> prefixChar Mf
Bind 'p' <M> {Mf::chooseModeProc "metafontModes" "proof"} Mf
Bind 's' <M> {Mf::chooseModeProc "metafontModes" "smoke"} Mf
Bind 'l' <M> {Mf::chooseModeProc "metafontModes" "localfont"} Mf
Bind 'u' <M> {Mf::chooseModeProc "metafontModes" "userDefined"} Mf
# Now key bindings to process the <b>uffer, a <f>ile or a <d>irectory:
# 'ctrl-m b', 'ctrl-m f' and 'ctrl-m d' respectively.
Bind 'b' <M> {Mf::menuProc "Metafont" "processTheBuffer"} Mf
Bind 'f' <M> {Mf::menuProc "Metafont" "processAFile"} Mf
Bind 'd' <M> {Mf::processAFolder} Mf
# A key binding ('ctrl-m n') to create a new font template:
Bind 'n' <M> {Mf::newFontTemplate} Mf
# A key binding ('ctrl-m g') to edit the log file:
Bind 'g' <M> {Mf::setNames [win::Current] ; Mf::editLogFile} Mf
# A key binding ('ctrl-m t') to convert <t>fm file to pl:
Bind 't' <M> {Mf::setNames [win::Current];Mf::doplProc;set mf_params(prefix-pl) "";menu::buildSome metafontPostprocess;Mf::editPlFile} Mf
# A key binding ('ctrl-m i') to convert gf file to dv<i>:
Bind 'i' <M> {Mf::metafontUtilsProc "metafontUtils" "convertGfToDvi"} Mf
# A key binding ('ctrl-m k') to convert gf file to p<k>:
Bind 'k' <M> {Mf::metafontUtilsProc "metafontUtils" "convertGfToPk"} Mf
# A key binding ('ctrl-m v') to <v>iew the d<v>i:
Bind 'v' <M> {Mf::setNames [win::Current];Mf::viewDvi} Mf



# File Marking
# ------------
# Marking is different for mf source files and for pl or vpl files.
# 
# # # With mf source files:
# All the 'beginchar/endchar' groups are marked.
# The name of the 'beginchar' routines can be changed in the mode prefs:
# if you chose to call them "myfontchar" then all the "myfontchar"
# instructions will be marked.
# 
# # # With property list files:
# the LIGTABLE and FONTDIMEN arrays are marked as well as all the character
# dimensions data.

proc Mf::MarkFile {args} {
	win::parseArgs win
	global MfmodeVars mf_params
	Mf::setNames $win
	if {$mf_params(extname) == ".mf"} {
		#  Mark the 'beginchar' instructions
		set bgnchar $MfmodeVars(userBeginchar)
		set end [maxPos -w $win]
		set pos [minPos]
		while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "^$bgnchar\[^\r\n\]*$" $pos} res]} {
			set start [lindex $res 0]
			set end [lindex $res 1]
			set txt [getText -w $win [pos::math -w $win $start - 1] $end]
			if {[regexp -- "$bgnchar" $txt]} {
				if {![regexp -- {; *\"[^"]*\" *;} $txt txt]} {
					regexp -- "$bgnchar\[ _\\w\\d\\\(\\\"\]*" $txt txt 
					set txt "${txt}\)"
				} else {
					set txt [string trim $txt " ;\""]
				}
			}
			set pos [nextLineStart -w $win $start]
			set inds($txt) [lineStart -w $win [pos::math -w $win $start - 1]]
		}
		if {[info exists inds]} {
			foreach f [lsort [array names inds]] {
				set next [nextLineStart -w $win $inds($f)]
				setNamedMark -w $win $f $inds($f) $next $next
			}
		}
	} else {
		set pos [minPos]
		set end [maxPos -w $win]
		while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 {^[\(](FONTDIMEN|LIGTABLE)} $pos} res]} {
			set start [lindex $res 0]
			set end [lindex $res 1]
			set txt [getText -w $win [pos::math -w $win $start +1] $end]
			set pos [nextLineStart -w $win $start]
			set inds($txt) [lineStart -w $win [pos::math -w $win $start - 1]]
		}
		
		if {[info exists inds]} {
			foreach f  [array names inds] {
				set next [nextLineStart -w $win $inds($f)]
				setNamedMark -w $win $f $inds($f) $next $next
			}
		}
		
		set pos [minPos]
		set end [maxPos -w $win]
		while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 {^[\(]CHARACTER[ \w\d]*} $pos} res]} {
			set start [lindex $res 0]
			set end [lindex $res 1]
			set txt [getText -w $win [pos::math -w $win $start +1] $end]
			set pos [nextLineStart -w $win $start]
			set inds($txt) [lineStart -w $win [pos::math -w $win $start - 1]]
		}
		
		if {[info exists inds]} {
			foreach f [lsort -increasing [array names inds]] {
				set next [nextLineStart -w $win $inds($f)]
				setNamedMark -w $win $f $inds($f) $next $next
			}
		}
	}
}


# The "{}" menu
# -------------
# The "{}" pop-up menu contains all the def, vardef, etc. definitions, as
# well as the files included with an "input" command.
proc Mf::parseFuncs {} {
	global funcExpr 
	set pos [minPos]
	set m {}
	while {[set res [search -s -f 1 -r 1 -i 0 -n "$funcExpr" $pos]] != ""} {
		lappend m "[eval getText $res]" [lindex $res 1]
		set pos [lindex $res 1]
	}
	set f [lsort -dictionary [Mf::findInputFiles 1]]
	if {[llength $f]} {
		set f [linsert $f 0 "INPUT FILES: " "0"]
		if {[llength $m]} {
			set m [linsert $m 0 "-" "0"]
		}
	}
	return [concat $f $m]
}


proc Mf::findInputFiles {parsing} {
	set files {}
	set pos [minPos]
	while {[set res [search -s -f 1 -r 1 -i 0 -n {^input[^\r\n]+$} $pos]] != ""} {
		set txt [eval getText $res]
		regsub -all "input +" $txt "" txt
		lappend files $txt
		if {$parsing} {lappend files $txt}
		set pos [lindex $res 1]
	}
	return $files
}


# Command-Double-click
# --------------------

# A Command-Double-Click on a keyword leads to its definition. This proc
# looks first for a definition in the current file itself, then in the
# list of primitives, then in the plain Metafont macros file and finally in
# the other source files located in the same folder and included in the current
# file by an "input" command (typically they are macros files).

set mf_params(internals) [list "blacker" "currentwindow" "displaying" "eps" "epsilon" \
  "infinity" "join_radius" "number_of_modes" "o_correction" "pair" "path" "pen_bot" \
  "pen_lft" "pen_rt" "pen_top" "pixels_per_inch" "screen_cols" "screen_rows" "tolerance" ]

	# # Not used
	# set mf_params(constants) [list "basename" "base_version" \
	#   "blankpicture" "currentpen" "currentpen_path" "currenttransform" \
	#   "ditto" "extra_beginchar" "extra_endchar" "extra_setup" "fullcircle" \
	#   "halfcircle" "identity" "mode_name" "penspeck" "quartercircle" \
	#   "rulepen" "unitpixel" "unitsquare" ]

proc Mf::DblClick {from to} {
	global MfmodeVars mf_params mfPrimitives
	selectText $from $to
	set word [getText $from $to]
	# First we look for the word's definition in the current file:
	set pos [minPos]
	if {![catch {search -s -f 1 -r 1 -m 1 -i 0\
	  "(var|primary|secondary|tertiary)?def\[ \t\]+$word" $pos} res]} {
		goto [lineStart [lindex $res 0]]
		selectText [lindex $res 0] [lindex $res 1]
		return
	}
	# If search failed, check if it is a Metafont primitive.
	if {[expr {[lsearch -exact $mfPrimitives "$word"] != -1}]} {
		alertnote "\"$word\" is a Metafont primitive.\rSee the MetafontBook."
		return
	}
	# If search failed, check if it is a 'newinternal'.
	if {[expr {[lsearch -exact $mf_params(internals) "$word"] != -1}]} {
		alertnote "\"$word\" is a constant of type \"newinternal\".\r\
		  See the MetafontBook or Metapost User's Manual."
		return
	}
	# If search failed, look in the plain.mf macros file. Its path must
	# have been defined in the mode prefs.
	if {![file exists $MfmodeVars(pathToPlainMfFile)]} {
		alertnote "Can't find file plain.mf: where is it ?"
		if {[catch {getfile "Find file plain.mf"} thepath]} {return} 
		set MfmodeVars(pathToPlainMfFile) $thepath
		prefs::modified MfmodeVars(pathToPlainMfFile)
	}    
	set cid [scancontext create]
	set searchstri "(var|primary|secondary|tertiary)?def\[ \\w\]+$word\[^\\w\]+"
	set searchstrii "(path|pen|picture|string|transform)\[ ,\\w\]+$word"
	scanmatch $cid $searchstri {set matches(PlainMf) 1}
	scanmatch $cid $searchstrii {set matches(PlainMf) 1}
	if {![catch {set fid [open $MfmodeVars(pathToPlainMfFile)]}]} {
		scanfile $cid $fid
		close $fid
	}
	if {[info exists matches]} {
		edit -c -r $MfmodeVars(pathToPlainMfFile)
		goto $matchInfo(offset)
		set res [search -s -f 1 -r 0 -i 0 -m 1 -n $word $matchInfo(offset)]
		selectText $matchInfo(offset) [lindex $res 1]
	} else {
		# As a last resort, search all the include files found in the
		# source file (supposing they are located in the same folder)
		set inputs [Mf::findInputFiles 0]
		foreach filename $inputs {
			set filename [file root $filename]
			set fullname [file join [file dirname [win::Current]] $filename.mf]
			if {[file exists $fullname]} {
				if {![catch {set fid [open $fullname]}]} {
					status::msg "Scanning '$filename.mf'"
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
# An Option-Click on a the title bar displays a list of all the mf and the
# log files located in the "current" folder if one is selected in the
# "Metafont Utils" submenu or, otherwise, in the "local" folder (folder of
# current window).

proc Mf::OptionTitlebar {} {
	global mf_params minItemsInTitlePopup
	set minItemsInTitlePopup 1
	set dir [file dirname [win::Current]]
	set filesinlocaldir [glob -nocomplain -tail -dir $dir *.mf]
	set logsinlocaldir [glob -nocomplain -tail -dir $dir *.log]
	if {[llength $filesinlocaldir] && [llength $logsinlocaldir]} {
		lappend filesinlocaldir "-"	
	} 
	return [concat $filesinlocaldir $logsinlocaldir]
}


proc Mf::OptionTitlebarSelect {item} {
    global mf_params
    if {$item == "-"} {return}
	edit -c -w [file join [file dirname [win::Current]] $item]
}


# ---------------------------------------------------------------------
# Now load the files containing the menu definitions and xserv services
# ---------------------------------------------------------------------
if {![alpha::tryToLoad "Initializing Metafont mode" \
  mfMenus.tcl {Loading Metafont menusÉ} \
  mfServices.tcl {Loading Metafont servicesÉ} \
]} {
    alertnote "Error: the Metafont menu did not properly load."
}

status::msg "Mf mode initialization complete."
