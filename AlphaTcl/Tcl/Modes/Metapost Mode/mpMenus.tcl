# File: "mpMenus.tcl"
#                        Created: 2001-02-20 22:43:27
#              Last modification: 2005-08-31 12:00:21
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metapost Mode package for Alpha. 
# See comments at the beginning of 'mpMode.tcl'.

namespace eval Mp {}
namespace eval menu {}

# This is to load the main file mpMode.tcl first
mpMenu

proc mpMenus.tcl {} {}


# Metafont Menus declarations
# ===========================

menu::buildProc Mp menu::buildMpMenu
menu::buildProc metapostUtils… menu::buildMpUtils
menu::buildProc mfplainMacros… menu::buildMfplainMacros

ensureset mp_params(longmenu) 0
ensureset mp_params(extname) ""

# Menu building procs
# -------------------

proc menu::buildMpMenu {} {	
	global mpMenu mp_params
	set ma ""
	lappend ma "switchToMetapost" "(-" "/B<UrunTheBuffer" 
	lappend ma "runAFile…" "(-"
	lappend ma [list Menu -n metapostUtils… {}]
	lappend ma "(-"   
	if {!$mp_params(longmenu)} {
		lappend ma "makeLongMenu"
	} else {
		lappend ma "makeShortMenu" "(-"
		Mp::loadSubmenuItems items
		foreach m [lsort [array names items]] {
			lappend ma [list Menu -n "$m…" -p Mp::${m}Proc [set items($m)] ]
		} 
		lappend ma "(-"
		lappend ma [list Menu -n mfplainMacros… {}]
	}
	return [list build $ma Mp::menuProc [list "metapostUtils…" "mfplainMacros…"] $mpMenu]
}


proc menu::buildMpUtils {} {
	global mp_params
	set ma 	""
	if {$mp_params(extname) eq ".mp" || $mp_params(extname) eq ".mpx"} {
		lappend ma "$mp_params(prefix-log)open $mp_params(basename).log"
		lappend ma "$mp_params(prefix-mpx)open $mp_params(basename).mpx"
		lappend ma "(-"
	}
	foreach i {"plain.mp" "mfplain.mp" "plain.mf" "modes.mf"} {
		lappend ma "open $i"
	}
	lappend ma "(-" "figsFileTemplate" "metapostBindings" "deleteAuxiliaryFiles…"

	return [list build $ma Mp::metapostUtilsProc ]
}


proc menu::buildMfplainMacros {} {
	global mp_params 
	set mp_params(basename) [file rootname [file tail [win::Current]]]
	set items(charactersDesign) [list beginchar…endchar extra_beginchar \
	  extra_endchar (- good.bot good.lft good.rt good.top good.x good.y (- \
	  change_width makebox makegrid maketicks labelfont italcorr (- rulepen \
	  capsule_def ]
	set items(pixellisation) [list define_pixels define_blacker_pixels \
	  define_good_x_pixels define_good_y_pixels define_corrected_pixels \
	  define_horizontal_corrected_pixels define_whole_pixels \
	  define_whole_blacker_pixels define_whole_vertical_pixels \
	  define_whole_vertical_blacker_pixels ]
	set items(modeDefinitions) [list mode_def mode_setup extra_setup (- blacker \
	  o_correction smode (- proofrule proofrulethickness ]
	set items(fontCoding) [list font_coding_scheme font_extra_space \
	  font_identifier font_normal_shrink font_normal_space font_normal_stretch \
	  font_quad font_size font_slant font_x_height ]
	set ma 	 ""
	foreach m [lsort [array names items]] {
		lappend ma [list Menu -n "$m…" -p Mp::${m}Proc [set items($m)] ]
	} 
	return [list build $ma Mp::mfplainMacrosProc]
}


proc Mp::loadSubmenuItems {arr} {
	upvar $arr items
	set items(variables) [list boolean numeric pair path pen picture string \
	  transform newinternal ]
	set items(boolean) [list charexists cycle false known true unknown ]
	set items(functions) [list angle ceilling floor cosd sind mexp mlog sqrt \
	  mod round (- eps epsilon infinity (- ascii hex oct decimal (- solve \
	  tolerance (- normaldeviate randomseed uniformdeviate whatever ]
	set items(positioning) [list direction directionpoint directiontime \
	  penoffset point…of precontrol…of postcontrol…of intersectionpoint \
	  intersectiontimes (- penpos penstroke (- xpart xxpart xypart ypart yxpart \
	  yypart clearxy ]
	set items(paths) [list flex fullcircle halfcircle quartercircle \
	  superellipse unitsquare (- cutbefore cutafter cuttings subpath…of interpath \
	  tensepath counterclockwise reverse (- arclength arctime length \
	  turningnumber ]
	set items(pens) [list <E<Spencircle <S<Ipencircle…scaled <E<Spensquare \
	  <S<Ipensquare…scaled penrazor penspeck defaultpen (- clear_pen_memory \
	  clearpen currentpen makepen nullpen savepen makepath (- pen_bot pen_lft \
	  pen_rt pen_top pickup ]
	set items(figures) [list beginfig…endfig extra_beginfig extra_endfig \
	  btex_etex verbatimtex_etex shipout ]
	set items(pictures) [list blankpicture currentpicture nullpicture clearit \
	  (- addto…also <E<Saddto…contour <S<Iaddto…contour…withpen \
	  <E<Saddto…doublepath <S<Iaddto…doublepath…withpen ]
	set items(transformations) [list identity inverse reflectedabout rotated \
	  rotatedaround scaled shifted slanted transformed xscaled yscaled zscaled ]
	set items(drawing) [list <E<Sdraw <S<Iundraw <S<Odraw…withcolor \
	  <E<Sdraw…dashed <S<Idraw…dashed…withdots <S<Odraw…dashed…evenly dashpattern \
	  <E<Sdrawdot <S<Iundrawdot <S<Odrawdot…withcolor <E<Sfill <S<Iunfill \
	  <S<Ofill…withcolor <E<Sfilldraw <S<Iunfilldraw <S<Ofilldraw…withcolor \
	  cutdraw erase (- drawarrow drawdblarrow ahangle ahlength (- <E<Slinecap \
	  <S<Ibutt-linecap <S<Orounded-linecap <S<Bsquared-linecap <E<Slinejoin \
	  <S<Imitered-linejoin <S<Orounded-linejoin <S<Bbeveled-linejoin miterlimit \
	  clip buildcycle (- drawoptions ]
	set items(color) [list black blue green red white (- background color (- \
	  bluepart greenpart redpart ]
	set items(boxes) [list bbox center llcorner lrcorner ulcorner urcorner \
	  setbounds bboxmargin ]
	set items(labels) [list <Slabel <S<Idotlabel <S<Uthelabel <S<Odotlabels \
	  <E<Slabel.lft <S<Idotlabel.lft <S<Uthelabel.lft <S<Odotlabels.lft \
	  <E<Slabel.rt <S<Idotlabel.rt <S<Uthelabel.rt <S<Odotlabels.rt <E<Slabel.top \
	  <S<Idotlabel.top <S<Uthelabel.top <S<Odotlabels.top <E<Slabel.bot \
	  <S<Idotlabel.bot <S<Uthelabel.bot <S<Odotlabels.bot <E<Slabel.ulft \
	  <S<Idotlabel.ulft <S<Uthelabel.ulft <S<Odotlabels.ulft <E<Slabel.urt \
	  <S<Idotlabel.urt <S<Uthelabel.urt <S<Odotlabels.urt <E<Slabel.llft \
	  <S<Idotlabel.llft <S<Uthelabel.llft <S<Odotlabels.llft <E<Slabel.lrt \
	  <S<Idotlabel.lrt <S<Uthelabel.lrt <S<Odotlabels.lrt (- labeloffset \
	  defaultfont defaultscale ]
	set items(definitions) [list def…enddef suffix expr text primarydef…enddef \
	  secondarydef…enddef tertiarydef…enddef vardef…enddef begingroup…endgroup ]
	set items(conditions) [list for…endfor forever…endfor forsuffixes…endfor \
	  if…fi if…elseif…else…fi downto upto step…until exitif exitunless ]
	set items(fontInternals) [list fontsize <E<Sinfont <S<Ichar…infont charlist \
	  extensible fontdimen headerbytes ligtable kern ]
	set items(miscellaneous) [list ditto readstring substring…of expandafter \
	  gobble gobbled interact numtok scantokens special ]
	set items(debugging) [list errmessage message stop (- show showdependencies \
	  showstats showtoken showvariable (- loggingall tracingall tracingnone (- \
	  batchmode errorstopmode nonstopmode scrollmode ]
	set items(internalVariables) [list designsize fontmaking pausing \
	  showstopping truecorners (- charcode chardp charext charht charic charwd (- \
	  day month year time (- tracingcapsules tracingchoices tracingcommands \
	  tracingequations tracinglostchars tracingmacros tracingonline tracingoutput \
	  tracingrestores tracingspecs tracingstats tracingtitles " warningcheck" ]
	set items(boxes.mpMacros) [list <E<Sdrawboxed <S<Idrawunboxed drawboxes (- \
	  boxit boxjoin bpath (- circleit circmargin (- defaultdx defaultdy pic ]
	set items(graph.mpMacros) [list begingraph…endgraph <E<Ssetcoords \
	  <S<Isetcoords…lin…lin <S<Osetcoords…log…log <S<Bsetcoords…log…lin \
	  <S<Usetcoords…lin…log setrange (- Mreadpath plot (- gdraw gdrawarrow \
	  gdrawdblarrow gfill glabel gdotlabel (- auto.x auto.y autogrid frame grid \
	  itick otick (- augment format gdata init_numbers ]
}


# ---------------------------------------------------------------
# Proc to toggle between long and short menus
# ---------------------------------------------------------------
proc Mp::makeLongMenu {len} {
    global mp_params mpMenu
    set mp_params(longmenu) $len
    prefs::modified mp_params(longmenu)
    menu::buildSome Mp 
}


# ---------------------------------------------------------------
# Effective building of Metapost menu
# ---------------------------------------------------------------

menu::buildSome Mp 



