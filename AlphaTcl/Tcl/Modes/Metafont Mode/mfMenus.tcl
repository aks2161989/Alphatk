# File: "mfMenus.tcl"
#                        Created: 2001-02-06 22:07:36
#              Last modification: 2005-07-15 10:28:12
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metafont Mode package for Alpha.
# See comments at the beginning of 'mfMode.tcl'.

namespace eval Mf {}

# This is to load the main file mfMode.tcl first
mfMenu

proc mfMenus.tcl {} {}


# Metafont Menus declarations
# ===========================

menu::buildProc Mf Mf::buildMfMenu
menu::buildProc metafontUtils Mf::buildUtilsMenu
menu::buildProc metafontPostprocess Mf::buildPostprocessMenu

ensureset mf_params(longmenu) 0


# Menu building procs
# -------------------

proc Mf::buildMfMenu {} {
	global mfMenu mf_params
	set ma ""
	lappend ma "switchToMetafont" "(-" "/R<UprocessTheBuffer" 
# 	lappend ma "saveAndRun"
	lappend ma "<E<SprocessAFile�" "<S<IprocessAFolder�" "(-"
	lappend ma [list Menu -n metafontModes -p Mf::chooseModeProc $mf_params(modes)]
	set optionsItems [concat "mag�" "magstep�" "baseFile�" "(-" $mf_params(options) "(-" "clearAllOptions" ]	
	lappend ma [list Menu -n metafontOptions -p Mf::metafontOptionsProc $optionsItems]
	lappend ma "(-"
	lappend ma [list Menu -n metafontPostprocess {}]
	lappend ma [list Menu -n metafontUtils {}]
	lappend ma "(-"
	if {!$mf_params(longmenu)} {
		lappend ma "makeLongMenu"
	} else {
		lappend ma "makeShortMenu" "(-"
		Mf::loadSubmenuItems items
		foreach m [lsort [array names items]] {
			lappend ma [list Menu -n $m -p Mf::${m}Proc [set items($m)] ]
		} 
	}

	return [list build $ma Mf::menuProc {metafontPostprocess metafontUtils} $mfMenu]
}


proc Mf::buildPostprocessMenu {} {
	global mf_params MfmodeVars 

	set mf_params(basename) [file rootname [file tail [win::Current]]]
	set ma ""
	lappend ma "$mf_params(prefix-log)open $mf_params(basename).log"
	lappend ma "$mf_params(prefix-pl)open $mf_params(basename).pl" 
	lappend ma "(-"
	lappend ma "$mf_params(prefix-gf)convertGfToPk"
	lappend ma "<E$mf_params(prefix-gf)convertGfToDvi"
	lappend ma "<E$mf_params(prefix-dvi)view $mf_params(basename).dvi"
	lappend ma "<E$mf_params(prefix-dvi)convert $mf_params(basename).dvi to ps"
	lappend ma "<E<S$mf_params(prefix-tfm)convert $mf_params(basename).tfm to pl"
	lappend ma  "(-" "tfmToPl�" "plToTfm�" "(-" "vfToVpl�" "vplToVf�"
	
	return [list build $ma Mf::metafontPostprocessProc ]
}


proc Mf::buildUtilsMenu {} {
	global mf_params  
	set ma ""
	lappend ma "open modes.mf" "open plain.mf" "(-" "newFontTemplate"
	lappend ma "metafontBindings" "deleteAuxiliaryFiles�"
	
	return [list build $ma Mf::metafontUtilsProc ]
}


proc Mf::loadSubmenuItems {arr} {
	upvar $arr items
	set items(variables) [list boolean numeric pair path pen picture \
	  string transform newinternal ]
	set items(boolean) [list charexists cycle false known true unknown ]
	set items(functions) [list angle ceilling floor cosd sind mexp mlog sqrt \
	  (- round hround vround dotprod (- eps epsilon infinity \
	  (- solve tolerance (- normaldeviate randomseed uniformdeviate whatever ]
	set items(positioning) [list direction directionpoint directiontime penoffset point�of \
	  precontrol�of postcontrol�of intersectionpoint intersectiontimes \
	  (- good.bot good.lft good.rt good.top good.x good.y \
	  (- xpart xxpart xypart ypart yxpart yypart clearxy ]
	set items(paths) [list penstroke build�penstroke (- flex fullcircle halfcircle \
	  quartercircle superellipse unitsquare (- makepath interpath subpath \
	  tensepath counterclockwise reverse (- turningnumber ]
	set items(pens) [list <E<Spencircle <S<Opickup�pencircle <S<Ipencircle�scaled \
	  <S<I<Opickup�pencircle�scaled <E<Spensquare <S<Opickup�pensquare <S<Ipensquare�scaled \
	  <S<I<Opickup�pensquare�scaled penrazor penspeck (- penpos \
	  (- clear_pen_memory clearpen currentpen makepen nullpen savepen \
	  (- pen_bot pen_lft pen_rt pen_top pickup ]
	set items(pictures) [list blankpicture clearit currentpicture nullpicture \
	  (- totalweight unitpixel ]
	set items(transformations) [list currenttransform identity inverse reflectedabout \
	  rotated rotatedaround scaled shifted slanted transformed xscaled yscaled zscaled ]
	set items(definitions) [list def�enddef suffix expr text primarydef�enddef \
	  secondarydef�enddef tertiarydef�enddef vardef�enddef begingroup�endgroup ]
	set items(conditions) [list for�endfor forever�endfor forsuffixes�endfor if�fi \
	  if�elseif�else�fi downto upto step�until exitif exitunless ]
	set items(drawing) [list <Saddto�also <S<Iaddto�currentpicture <E<Saddto�contour \
	  <S<Iaddto�contour�withpen <S<Oaddto�contour�withweight <E<Saddto�doublepath \
	  <S<Iaddto�doublepath�withpen <S<Oaddto�doublepath�withweight <E<Scull�dropping \
	  <S<Ocull�dropping�withweight <E<Scull�keeping <S<Ocull�keeping�withweight cullit \
	  (- <E<Sdraw <S<Iundraw <E<Sdrawdot <S<Iundrawdot <E<Sfill <S<Iunfill \
	  <E<Sfilldraw <S<Iunfilldraw (- cutdraw cutoff erase ]
	set items(characters) [list beginchar�endchar extra_beginchar extra_endchar ]
	set items(units) [list blacker fillin o_correction fix_units mode_setup \
	  pixels_per_inchs aspect_ratio ]
	set items(pixellisation) [list define_pixels define_blacker_pixels define_good_x_pixels \
	  define_good_y_pixels define_corrected_pixels define_horizontal_corrected_pixels \
	  define_whole_pixels define_whole_blacker_pixels define_whole_vertical_pixels \
	  define_whole_vertical_blacker_pixels ]
	set items(fontInternals) [list charlist extensible font_coding_scheme font_extra_space \
	  font_identifier font_normal_shrink font_normal_space font_normal_stretch font_quad \
	  font_size font_slant font_x_height fontdimen headerbytes ligtable kern ]
	set items(strings) [list ditto jobname readstring substring ]
	set items(displaying) [list currentwindow display�inwindow openwindow�from�to�at \
	  screen_cols screen_rows screenrule ]
	set items(output) [list openit shipit showit (- labels labels�range�thru \
	  penlabels makelabel makegrid� (- proofoffset proofrule \
	  proofrulethickness (- grayfont labelfont slantfont titlefont ]
	set items(debugging) [list errhelp errmessage message stop \
	  (- show showdependencies showstats showtoken showvariable \
	  (- loggingall tracingall tracingnone \
	  (- batchmode errorstopmode nonstopmode scrollmode ]
	set items(misc) [list capsule_def expandafter gobble gobbled interact \
	  numtok scantokens special numspecial ]
	set items(internalVariables) [list autorounding designsize fontmaking granularity \
	  pausing proofing showstopping smoothing (- charcode chardp chardx \
	  chardy charext charht charic charwd (- hppp vppp (- xoffset yoffset \
	  (- day month year time (- tracingcapsules tracingchoices tracingcommands \
	  tracingedges tracingequations tracingmacros tracingonline tracingoutput tracingpens \
	  tracingrestores tracingspecs tracingstats tracingtitles turningcheck warningcheck ]
}


# ---------------------------------------------------------------
# Proc to toggle between long and short menus
# ---------------------------------------------------------------
proc Mf::makeLongMenu {len} {
    global mf_params mfMenu
    set mf_params(longmenu) $len
    prefs::modified mf_params(longmenu)
    menu::buildSome Mf 
    markMenuItem metafontModes $mf_params(chosenMode) 1
    Mf::markOptionsMenu
}



# Building Metafont menu now
# --------------------------

menu::buildSome Mf 

markMenuItem metafontModes proof 1
