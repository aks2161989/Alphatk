# File: "mfMacros.tcl"
#                        Created: 2001-02-06 22:07:36
#              Last modification: 2005-07-12 16:14:23
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metafont Mode package for Alpha.
# See comments at the beginning of 'mfMode.tcl'.

namespace eval Mf {}


# --------------------------------------
# Creating a new font template
# --------------------------------------

proc Mf::newFontTemplate {} {
	global MfmodeVars 
	# How many chars in the font
	if {[catch {prompt "How many chars in the new font ?" 128} nbchr]} {
		return
	} elseif {![is::PositiveInteger $nbchr]} {
		status::msg "invalid input: please enter a positive integer"
		return
	}
	new -n "untitled.mf"
	goto [minPos]
	# Preambule instructions
	set date [ISOTime::ISODateAndTimeRelaxed]
	set t "% File: ¥\r"
	append t "% Created: $date\r"	
	append t "% Modified"	
	append t ": $date\r% Comments: ¥\r% \r% \r% \r\r"	
	append t "font_size  ¥pt\#;    % the \"design size\" of this font\r\r"
	append t "mode_setup;"
	append t "\r\r%%%% Parameters %%%%\r\r"
	append t "\r\r%%%% Pixellisation %%%%\r\r"
	append t "define_pixels(¥);\r"
	append t "define_whole_pixels(¥);\r"
	append t "define_whole_vertical_pixels(¥);\r"
	append t "define_blacker_pixels(¥);\r"
	append t "define_good_x_pixels(¥);\r"
	append t "define_good_y_pixels(¥);\r"
	append t "define_corrected_pixels(¥);\r"
	append t "define_horizontal_corrected_pixels(¥);\r"
	append t "\r\r%%%% Macros and definitions %%%%\r\r"
	append t "\r\r%%%% Drawing instructions for the characters %%%%\r\r"
	insertText $t
	set i 0
	for {set i 0} {$i < $nbchr} {incr i} {
		insertText "$MfmodeVars(userBeginchar)([set i],¥,¥,¥);\"¥\";\r\r\r\r$MfmodeVars(userEndchar);\r\r"
	}
	# Postambule instructions
	set t "\r\r%%%% Ligtables and kerning %%%%\r\r"
	append t "ligtable \"¥\": \"¥\" kern ¥ \#;\r"
	append t "\r\r%%%% General Font Parameters %%%%\r\r"	
	append t "font_slant:=¥ ;\t\t\t\t% slant per point\r"
	append t "font_normal_space:=¥ ;\t\t% interword spacing\r"
	append t "font_normal_stretch:=¥ ;\t% stretchability of interword spacing\r"
	append t "font_normal_shrink:=¥;\t\t% shrinkability of interword spacing\r"
	append t "font_x_height:=¥ ;\t\t\t% TeX's ex unit\r"
	append t "font_quad:=¥ ;\t\t\t\t% TeX's em unit\r"
	append t "font_extra_space:=¥ ;\t\t% additional spacing between sentences\r"
	append t "\rfont_coding_scheme:= \"¥\";\t% coding scheme (optional)\r"
	append t "font_identifier:= \"¥\";\t\t% family (optional)\r"
	append t "\r\rbye"
	insertText $t
	goto [minPos]
}


# -----------------------------------------
# Submenus to insert Metafont commands
# -----------------------------------------


proc Mf::variablesProc {menu item} {
	set item [string trimleft $item]
	insertText "$item ¥;\r¥"
}

proc Mf::booleanProc {menu item} {
	set item [string trimleft $item]
	insertText "$item "
}

proc Mf::functionsProc {menu item} {
	switch $item {	
		"angle" {insertText "angle ¥;\r¥"}
		"ceilling" {insertText "ceilling ¥;\r¥"}
		"floor" {insertText "floor(¥)¥"}
		"cosd" {insertText "cosd(¥)¥"}
		"sind" {insertText "sind(¥)¥"}
		"mexp" {insertText "mexp(¥)¥"}
		"mlog" {insertText "mlog(¥)¥"}
		"sqrt" {insertText "sqrt(¥)¥"}
		"dotprod" {insertText "dotprod ¥ = ¥;\r¥"}
		"eps" {insertText "eps "}
		"epsilon" {insertText "epsilon "}
		"infinity" {insertText "infinity "}
		"round" {insertText "round(¥)¥"}
		"hround" {insertText "hround(¥)¥"}
		"vround" {insertText "vround(¥)¥"}
		"solve" {insertText "solve ¥(¥,¥);\r¥"}
		"tolerance" {insertText "tolerance:= ¥;\r¥"}
		"normaldeviate" {insertText "normaldeviate(¥)¥"}
		"randomseed" {insertText "randomseed:= ¥;\r¥"}
		"uniformdeviate" {insertText "uniformdeviate(¥)¥"}
		"whatever" {insertText "whatever "}
	}
}

proc Mf::positioningProc {menu item} {
	switch $item {	
		"clearxy" {insertText "clearxy ¥;\r¥"}
		"direction" {insertText "direction ¥ of ¥"}
		"directionpoint" {insertText "directionpoint ¥ of ¥"}
		"directiontime" {insertText "directiontime ¥ of ¥;\r¥"}
		"penoffset" {insertText "penoffset ¥ of ¥"}
		"pointÉof" {insertText "point ¥ of ¥"}
		"precontrolÉof" {insertText "precontrol ¥ of ¥"}
		"postcontrolÉof" {insertText "postcontrol ¥ of ¥"}
		"intersectionpoint" {insertText " ¥ intersectionpoint ¥"}
		"intersectiontimes" {insertText "¥ intersectiontimes ¥"}
		"good.bot" {insertText "good.bot "}
		"good.lft" {insertText "good.lft "}
		"good.rt" {insertText "good.rt "}
		"good.top" {insertText "good.top "}
		"good.x" {insertText "good.x "}
		"good.y" {insertText "good.y "}
		"xpart" {insertText "xpart(¥)¥"}
		"xxpart" {insertText "xxpart(¥)¥"}
		"xypart" {insertText "xypart(¥)¥"}
		"ypart" {insertText "ypart(¥)¥"}
		"yxpart" {insertText "yxpar(¥)¥"}
		"yypart" {insertText "yypart(¥)¥"}
	}
}

proc Mf::pathsProc {menu item} {
	switch $item {	
		"penstroke" {insertText "penstroke ¥;\r¥"}
		"buildÉpenstroke" {Mf::penstrokeProc}
		"flex" {Mf::mkflexProc}
		"fullcircle" {insertText "fullcircle "}
		"halfcircle" {insertText "halfcircle "}
		"quartercircle" {insertText "quartercircle "}
		"superellipse" {insertText "superellipse(¥,¥,¥,¥,¥);\r¥"}
		"unitsquare" {insertText "unitsquare "}
		"makepath" {insertText "makepath ¥;\r¥"}
		"interpath" {insertText "interpath(¥,¥,¥);\r¥"}
		"subpath" {insertText "subpath(¥,¥) of ¥"}
		"tensepath" {insertText "tensepath "}
		"counterclockwise" {insertText "counterclockwise "}
		"reverse" {insertText "reverse "}
		"turningnumber" {insertText "turningnumber "}
	}
}

proc Mf::pensProc {menu item} {
	switch $item {	
		"clear_pen_memory" {insertText "clear_pen_memory;"}
		"clearpen" {insertText "clearpen;"}
		"currentpen" {insertText "currentpen "}
		"makepen" {insertText "makepen "}
		"nullpen" {insertText "nullpen;"}
		"savepen" {insertText "¥:=savepen;¥"}
		"pencircle" {insertText "pencircle "}
		"pickupÉpencircle" {insertText "pickup pencircle "}
		"pencircleÉscaled" {insertText "pencircle ¥ xscaled ¥ yscaled ¥;\r¥"}
		"pickupÉpencircleÉscaled" {insertText "pickup pencircle ¥ xscaled ¥ yscaled ¥;\r¥"}
		"pensquare" {insertText "pensquare "}
		"pickupÉpensquare" {insertText "pickup pensquare "}
		"pensquareÉscaled" {insertText "pensquare ¥ xscaled ¥ yscaled ¥;\r¥"}
		"pickupÉpensquareÉscaled" {insertText "pickup pensquare ¥ xscaled ¥ yscaled ¥;\r¥"}
		"penrazor" {insertText "penrazor;"}
		"penspeck" {insertText "penspeck;"}
		"penpos" {insertText "penpos¥(¥,¥);\r¥"}
		"pen_bot" {insertText "pen_bot"}
		"pen_lft" {insertText "pen_lft"}
		"pen_rt" {insertText "pen_rt"}
		"pen_top" {insertText "pen_top"}
		"pickup" {insertText "pickup "}
	}
}

proc Mf::picturesProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"clearit" {insertText "$item ¥;\r¥"}
		default {insertText "$item "}
	}
}

proc Mf::stringsProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"ditto" -
		"jobname" {insertText "$item"}
		"readstring" {insertText "¥:=readstring;¥"}
		"substring" {insertText "substring(¥,¥) of ¥"}
	}
}

proc Mf::transformationsProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"reflectedabout" -
		"rotatedaround" {insertText "${item}(¥,¥) ¥"}
		default {insertText "$item "}
	}
}

proc Mf::definitionsProc {menu item} {
	switch $item {	
		"defÉenddef" {insertText "def ¥=\r¥\renddef;\r¥"}
		"suffix" {insertText "(suffix ¥)¥"}
		"expr" {insertText "(expr ¥)¥"}
		"text" {insertText "(text ¥)¥"}
		"primarydefÉenddef" {insertText "primarydef ¥=\r¥\renddef;\r¥"}
		"secondarydefÉenddef" {insertText "secondarydef ¥=\r¥\renddef;\r¥"}
		"tertiarydefÉenddef" {insertText "tertiarydef ¥=\r¥\renddef;\r¥"}
		"vardefÉenddef" {insertText "vardef ¥=\r¥\renddef;\r¥"}
		"begingroupÉendgroup" {insertText "begingroup ¥\r\rendgroup;\r¥"}
	}
}

proc Mf::conditionsProc {menu item} {
	switch $item {	
		"forÉendfor" {insertText "for ¥ : ¥ endfor;\r¥"}
		"foreverÉendfor" {insertText "forever ¥ endfor;\r¥"}
		"forsuffixesÉendfor" {insertText "forsuffixes ¥ : ¥ endfor;\r¥"}
		"ifÉfi" {insertText "if ¥ : ¥ fi\r¥"}
		"ifÉelseifÉelseÉfi" {insertText "if ¥ elseif ¥ else ¥ fi\r¥"}
		"downto" {insertText "downto "}
		"upto" {insertText "upto "}
		"stepÉuntil" {insertText "step ¥ until ¥ : ¥"}
		"exitif" {insertText "exitif ¥;"}
		"exitunless" {insertText "exitunless ¥;"}
	}
}

proc Mf::drawingProc {menu item} {
	switch $item {	
		"addtoÉalso" {insertText "addto ¥ also ¥;\r¥"}
		"addtoÉcurrentpicture" {insertText "addto currentpicture also currentpicture;\r¥"}
		"addtoÉcontour" {insertText "addto ¥ contour ¥ ;\r¥"}
		"addtoÉcontourÉwithpen" {insertText "addto ¥ contour ¥ withpen ¥;\r¥"}
		"addtoÉcontourÉwithweight" {insertText "addto ¥ contour ¥ withweight ¥;\r¥"}
		"addtoÉdoublepath" {insertText "addto ¥ doublepath ¥;\r¥"}
		"addtoÉdoublepathÉwithpen" {insertText "addto ¥ doublepath ¥ withpen ¥;\r¥"}
		"addtoÉdoublepathÉwithweight" {insertText "addto ¥ doublepath ¥ withweight ¥;\r¥"}
		"cullÉdropping" {insertText "cull ¥ dropping (¥,¥);\r¥"}
		"cullÉdroppingÉwithweight" {insertText "cull ¥ dropping (¥,¥) withweight ¥;\r¥"}
		"cullÉkeeping" {insertText "cull ¥ keeping (¥,¥);\r¥"}
		"cullÉkeepingÉwithweight" {insertText "cull ¥ keeping (¥,¥) withweight ¥;\r¥"}
		"cullit" {insertText "cullit ¥;\r¥"}
		"cutdraw" {insertText "cutdraw "}
		"cutoff" {insertText "cutoff(¥,¥);\r¥"}
		"draw" {insertText "draw "}
		"drawdot" {insertText "drawdot ¥;\r¥"}
		"erase" {insertText "erase ¥;\r¥"}
		"fill" {insertText "fill ¥;\r¥"}
		"filldraw" {insertText "filldraw ¥;\r¥"}
		"undraw" {insertText "undraw "}
		"undrawdot" {insertText "undrawdot ¥;\r¥"}
		"unfill" {insertText "unfill ¥;\r¥"}
		"unfilldraw" {insertText "unfilldraw ¥;\r¥"}
	}
}

proc Mf::charactersProc {menu item} {
	global MfmodeVars 
	switch $item {	
		"begincharÉendchar" {insertText "$MfmodeVars(userBeginchar)(\"¥\",¥,¥,¥);\"¥\";\r¥\r$MfmodeVars(userEndchar);\r¥"}
		"extra_beginchar" {insertText "extra_beginchar:=\" ¥ \";\r¥"}
		"extra_endchar" {insertText "extra_endchar:=\" ¥ \";\r¥"}
	}
}

proc Mf::unitsProc {menu item} {
	switch $item {	
		"blacker" {insertText "blacker:=¥;\r¥"}
		"fillin" {insertText "fillin:=¥;\r¥"}
		"o_correction" {insertText "o_correction:= ¥;\r¥"}
		"fix_units" {insertText "fix_units;\r"}
		"mode_setup" {insertText "mode_setup;\r"}
		"pixels_per_inchs" {insertText "pixels_per_inchs:=¥;\r¥"}
		"aspect_ratio" {insertText "aspect_ratio:=¥;\r¥"}
	}
}

proc Mf::pixellisationProc {menu item} {
	set item [string trimleft $item]
	insertText "${item}(¥);\r¥"
}

proc Mf::fontInternalsProc {menu item} {
	switch $item {	
		"charlist" {insertText "charlist ¥: ¥ : ¥ : ¥ : ¥"}
		"extensible" {insertText "extensible ¥: ¥, ¥, ¥, ¥"}
		"font_coding_scheme" {insertText "font_coding_scheme:= \"¥\";\r¥"}
		"font_extra_space" {insertText "font_extra_space:= ¥;\r¥"}
		"font_identifier" {insertText "font_identifier:= \"¥\";\r¥"}
		"font_normal_shrink" {insertText "font_normal_shrink:= ¥;\r¥"}
		"font_normal_space" {insertText "font_normal_space:= ¥;\r¥"}
		"font_normal_stretch" {insertText "font_normal_stretch:= ¥;\r¥"}
		"font_quad" {insertText "font_quad:= ¥;\r¥"}
		"font_size" {insertText "font_size:= ¥;\r¥"}
		"font_slant" {insertText "font_slant:= ¥;\r¥"}
		"font_x_height" {insertText "font_x_height:= ¥;\r¥"}
		"fontdimen" {insertText "fontdimen ¥: ¥, ¥, ¥, ¥\r¥"}
		"headerbytes" {insertText "headerbytes ¥: ¥, ¥, ¥, ¥"}
		"ligtable" {insertText "ligtable \"¥\" : \"¥\" =: oct\"¥\";\r¥"}
		"kern" {insertText "kern ¥\#¥"}
	}
}

proc Mf::displayingProc {menu item} {
	switch $item {	
		"currentwindow" {insertText "currentwindow:= ¥;\r¥"}
		"displayÉinwindow" {insertText "display ¥ inwindow ¥;\r¥"}
		"openwindowÉfromÉtoÉat" {insertText "openwindow ¥ from (¥,¥) to (¥,¥) at (¥,¥);\r¥"}
		"screen_cols" {insertText "screen_cols:= ¥;\r¥"}
		"screen_rows" {insertText "screen_rows:= ¥;\r¥"}
		"screenrule" {insertText "screenrule(¥,¥);\r¥"}
	}
}

proc Mf::outputProc {menu item} {
	switch $item {	
		"openit" {insertText "openit;\r"}
		"shipit" {insertText "shipit;\r"}
		"showit" {insertText "showit;\r"}
		"labels" {insertText "labels(¥);\r¥"}
		"labelsÉrangeÉthru" {insertText "labels(range ¥ thru ¥);\r¥"}
		"penlabels" {insertText "penlabels(¥);\r¥"}
		"makelabel" {insertText "makelabel(\"¥\",¥);\r¥"}
		"makegrid" {Mf::mkgridProc}
		"proofoffset" {insertText "proofoffset(¥,¥);\r¥"}
		"proofrule" {insertText "proofrule(¥,¥);\r¥"}
		"proofrulethickness" {insertText "proofrulethickness:=¥;\r¥"}
		"grayfont" {insertText "grayfont \"¥\";\r¥"}
		"labelfont" {insertText "labelfont \"¥\";\r¥"}
		"slantfont" {insertText "slantfont \"¥\";\r¥"}
		"titlefont" {insertText "titlefont \"¥\";\r¥"}
	}
}

proc Mf::debuggingProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"errhelp" {insertText "errhelp "}
		"errmessage" {insertText "errmessage \"¥\";\r¥"}
		"message" {insertText "message \"¥\";\r¥"}
		"show" {insertText "show ¥;\r¥"}
		"showtoken" {insertText "showtoken ¥;\r¥"}
		"showvariable" {insertText "showvariable ¥;\r¥"}
		default {insertText "$item;\r¥"}
	}
}

proc Mf::miscProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"interact" {insertText "interact;\r¥"}
		"capsule_def" {insertText "capsule_def ¥;\r¥"}
		"special" {insertText "special \"¥\";\r¥"}
		"numspecial" {insertText "numspecial ¥;\r¥"}
		default {insertText "$item "}
	}
}

proc Mf::internalVariablesProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"day" -
		"month" -
		"year" -
		"time" {insertText "$item;"}
		default {insertText "$item= ¥;\r¥"}
	}
}
