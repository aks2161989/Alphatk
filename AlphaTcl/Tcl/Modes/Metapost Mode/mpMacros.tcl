# File: "mpMacros.tcl"
#                        Created: 2001-02-20 23:43:20
#              Last modification: 2005-07-15 19:40:59
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metapost Mode package for Alpha. 
# See comments at the beginning of 'mpMode.tcl'.

namespace eval Mp {}

# --------------------------------------
# Creating a new figs file template
# --------------------------------------

proc Mp::newtemplateProc {} {
	global MpmodeVars
	if {[catch {prompt "How many figs in the new file?" 10} nbchr]} {
		return
	} 
	if {![is::PositiveInteger $nbchr]} {
		status::msg "invalid input: please enter a positive integer"
		return
	}
	set fname "newfigs.mp"
	new -n $fname
	# Preambule instruction
	set t "\% This file: $fname\r"
	append t "\% Created: [ISOTime::ISODateAndTimeRelaxed]\r"	
	append t "\% Author: •\r"	
	append t "\% e-mail: •\r"	
	append t "\% Comments: •\r% \r% \r% \r\r"	
	append t "\r\r\%\%\%\% Parameters \%\%\%\%\r\r"
	append t "\r\r\%\%\%\% Macros and definitions \%\%\%\%\r\r"
	append t "\r\r\%\%\%\% Drawing instructions… \%\%\%\%\r\r"
	insertText $t
	set i 1
	for {set i 1} {$i <= $nbchr} {incr i} {
		insertText "$MpmodeVars(userBeginfig)($i);\r\r$MpmodeVars(userEndfig);\r\r"
	}
	# Postambule instruction
	set t "\r\r\%\%\%\% Ligtables and kerning \%\%\%\%\r\r"
	append t "\r\r\%\%\%\% General Font Parameters \%\%\%\%\r\r"	
	append t "\r\rend"
	insertText $t
	goto [minPos]
}


# -----------------------------------------
# Submenus for Metapost commands insertion
# -----------------------------------------

proc Mp::variablesProc {menu item} {
	set item [string trimleft $item]
	insertText "$item •;\r•"
}


proc Mp::booleanProc {menu item} {
	set item [string trimleft $item]
	insertText "$item "
}


proc Mp::functionsProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"floor" - "cosd" - "sind" - "mexp" - 
		"normaldeviate" - "uniformdeviate" -
		"mlog" - "sqrt" - "round" {insertText "${item}(•)•"}
		
		"angle" - "ceilling" - "solve" {insertText "$item •;\r•"}
		
		"mod" {insertText "• mod •"}
		"tolerance" {insertText "tolerance:= •;\r•"}
		"randomseed" {insertText "randomseed:= •;\r•"}
		default {insertText "$item "}
	}
}


proc Mp::positioningProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"xpart" - "xxpart" - "xypart" - "ypart" -
		"yxpart" - "yypart" {insertText "${item}(•)•"}
		
		"direction" - "penoffset" - "point…of" - "precontrol…of" -
		"postcontrol…of" - "directionpoint" {insertText "$item • of •"}
		
		"directiontime" {insertText "directiontime • of •;\r•"}
		"intersectionpoint" {insertText " • intersectionpoint •"}
		"intersectiontimes" {insertText "• intersectiontimes •"}
		"penpos" {insertText "penpos•(•,•);\r•"}
		"penstroke" {insertText "penstroke •;\r•"}
		"clearxy" {insertText "clearxy •;\r•"}
	}
}


proc Mp::pathsProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"flex" {Mf::mkflexProc}
		"superellipse" {insertText "superellipse(•,•,•,•,•);\r•"}
		"interpath" {insertText "interpath(•,•,•);\r•"}
		"subpath…of" {insertText "subpath(•,•) of • ;"}
		"arctime" {insertText "arctime • of • ;"}
		default {insertText "$item "}
	}
}


proc Mp::pensProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"pencircle" - "pickup" - "pensquare" - "defaultpen" -
		"currentpen" - "makepen" {insertText "$item "}
		
		"penrazor" - "penspeck" - "clear_pen_memory" -
		"clearpen" - "nullpen" {insertText "${item};"}
		
		"pencircle…scaled" {insertText "pencircle • xscaled • yscaled •;\r•"}
		"pensquare…scaled" {insertText "pensquare • xscaled • yscaled •;\r•"}
		"savepen" {insertText ":=savepen;"}
		"makepath" {insertText "makepath •;\r•"}
		
		default {insertText "$item"}
	}
}


proc Mp::figuresProc {menu item} {	
	switch $item {	
		"beginfig…endfig" {insertText "beginfig(•);\r•\rendfig;\r•"}
		"extra_beginfig" {insertText "extra_beginfig := \"•\" ;\r• "}
		"extra_endfig" {insertText "extra_endfig := \"•\" ;\r• "}
		"btex_etex" {insertText "btex • etex•"}
		"verbatimtex_etex" {insertText "verbatimtex • etex•"}
		"shipout" {insertText "shipout;\r"}
	}
}


proc Mp::picturesProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"clearit" {insertText "clearit •;\r•"}
		"addto…also" {insertText "addto • also •;\r•"}
		"addto…contour" {insertText "addto • contour • ;\r•"}
		"addto…contour…withpen" {insertText "addto • contour • withpen •;\r•"}
		"addto…doublepath" {insertText "addto • doublepath •;\r•"}
		"addto…doublepath…withpen" {insertText "addto • doublepath • withpen •;\r•"}
		default {insertText "$item"}
	}
}


proc Mp::transformationsProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"reflectedabout" - "rotatedaround" {insertText "${item}(•,•) •"}
		default {insertText "$item "}
	}
}


proc Mp::drawingProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"buildcycle" - "cutdraw" - "draw" {insertText "$item "}
		"ahangle" - "ahlength"  {insertText "${item}:=•;\r•"}
		"beveled-linejoin"  {insertText "linejoin:= beveled;\r•"}
		"butt-linecap"  {insertText "linecap:= butt;\r•"}
		"clip"  {insertText "clip • to •;\r•"}
		"cutoff" {insertText "cutoff(•,•);\r•"}
		"dashpattern"  {insertText "dashpattern(on • off • on •);\r•"}
		"drawdot…withcolor"  {insertText "drawdot • withcolor •;\r•"}
		"drawoptions"  {insertText "drawoptions(•);\r•"}
		"draw…dashed…evenly"  {insertText "draw • dashed evenly;\r•"}
		"draw…dashed…withdots"  {insertText "draw • dashed withdots;\r•"}
		"draw…dashed"  {insertText "draw • dashed;\r•"}
		"draw…withcolor"  {insertText "draw • withcolor •;\r•"}
		"filldraw…withcolor"  {insertText "filldraw • withcolor •;\r•"}
		"fill…withcolor"  {insertText "fill • withcolor •;\r•"}
		"linecap"  {insertText "linecap:= •;\r•"}
		"linejoin"  {insertText "linejoin:= •;\r•"}
		"mitered-linejoin"  {insertText "linejoin:= mitered;\r•"}
		"miterlimit"  {insertText "miterlimit:= •;\r•"}
		"rounded-linecap"  {insertText "linecap:= rounded;\r•"}
		"rounded-linejoin"  {insertText "linejoin:= rounded;\r•"}
		"squared-linecap"  {insertText "linecap:= squared;\r•"}
		default {insertText "$item •;\r•"}
	}
}


proc Mp::colorProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"color" {insertText "color •;\r• "}
		default {insertText "$item "}
	}
}


proc Mp::boxesProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"setbounds" {insertText "setbounds • to •;\r•"}
		"bboxmargin" {insertText "bboxmargin:= •;\r•"}
		default {insertText "$item "}
	}
}


proc Mp::labelsProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"dotlabels" {Mp::mkdotlabelsProc nil}
		"dotlabels.bot" - "dotlabels.lft" - "dotlabels.llft" - "dotlabels.lrt" -
		"dotlabels.rt" - "dotlabels.top" - "dotlabels.ulft" - "dotlabels.urt" {
			regexp "\w+\.(\w+)" $item dum ext
			Mp::mkdotlabelsProc $ext
		}
		default {insertText "$item :=•;\r•"}
	}
}


proc Mp::definitionsProc {menu item} {
	switch $item {	
		"def…enddef" {insertText "def •=\r•\renddef;\r•"}
		"suffix" {insertText "(suffix •)•"}
		"expr" {insertText "(expr •)•"}
		"text" {insertText "(text •)•"}
		"primarydef…enddef" {insertText "primarydef •=\r•\renddef;\r•"}
		"secondarydef…enddef" {insertText "secondarydef •=\r•\renddef;\r•"}
		"tertiarydef…enddef" {insertText "tertiarydef •=\r•\renddef;\r•"}
		"vardef…enddef" {insertText "vardef •=\r•\renddef;\r•"}
		"begingroup…endgroup" {insertText "begingroup •\r\rendgroup;\r•"}
	}
}


proc Mp::conditionsProc {menu item} {
	switch $item {	
		"for…endfor" {insertText "for • : • endfor;\r•"}
		"forever…endfor" {insertText "forever • endfor;\r•"}
		"forsuffixes…endfor" {insertText "forsuffixes • : • endfor;\r•"}
		"if…fi" {insertText "if • : • fi\r•"}
		"if…elseif…else…fi" {insertText "if • elseif • else • fi\r•"}
		"downto" {insertText "downto "}
		"upto" {insertText "upto "}
		"step…until" {insertText "step • until • : •"}
		"exitif" {insertText "exitif •;"}
		"exitunless" {insertText "exitunless •;"}
	}
}


proc Mp::fontinternalsProc {menu item} {
	switch $item {	
		"fontsize" {insertText "fontsize •;\r•"}
		"infont" {insertText "infont "}
		"char…infont" {insertText "char(•) infont •"}
		"charlist" {insertText "charlist •: • : • : • : •"}
		"extensible" {insertText "extensible •: •, •, •, •"}
		"fontdimen" {insertText "fontdimen •: •, •\r•"}
		"headerbytes" {insertText "headerbytes •: •, •, •, •"}
		"ligtable" {insertText "ligtable \"•\" : \"•\" =: oct\"•\";\r•"}
		"kern" {insertText "kern •\#•"}
	}
}


proc Mp::miscellaneousProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"readstring" {insertText ":=readstring;"}
		"substring…of" {insertText "substring(•,•) of •"}
		"interact" {insertText "interact;\r•"}
		"special" {insertText "special \" •\";\r•"}
		default {insertText "$item "}
	}
}


proc Mp::debuggingProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"errhelp" {insertText "errhelp "}
		"errmessage" {insertText "errmessage \"•\";\r•"}
		"message" {insertText "message \"•\";\r•"}
		"show" {insertText "show •;\r•"}
		"showtoken" {insertText "showtoken •;\r•"}
		"showvariable" {insertText "showvariable •;\r•"}
		default {insertText "$item;\r•"}
	}
}


proc Mp::internalVariablesProc {menu item} {
	set item [string trimleft $item]
	switch $item {	
		"day" - "month" - "year" - "time" {insertText "$item;"}
		default {insertText "$item= •;\r•"}
	}
}


# # Additional macros from the boxes.mp package
proc Mp::boxes.mpMacrosProc {menu item} {
	switch $item  {	
		"drawboxed" {insertText "drawboxed(•);\r•"}
		"drawunboxed" {insertText "drawunboxed(•);\r•"}
		"drawboxes" {insertText "drawboxes(•);\r•"}
		"boxit" {insertText  "boxit.•(•);\r•"}
		"boxjoin" {insertText "boxjoin(•.•=•.•,•.•=•.•);\r•" }
		"bpath" {insertText "bpath •" }
		"circleit" {insertText "circleit.•(•);\r•" }
		"circmargin" {insertText "circmargin:= •;\r•"  }
		"defaultdx" {insertText "defaultdx:= •;\r•"  }
		"defaultdy" {insertText "defaultdy:= •;\r•" }
		"pic" {insertText "pic(•);\r•" }
	}
}


# # Additional macros from the graph.mp package
proc Mp::graph.mpMacrosProc {menu item} {
	switch $item {	
		"begingraph…endgraph" {insertText "draw begingraph(•,•);\r•\rendgraph;\r•" }
		"setcoords" {insertText "setcoords(•,•) " }
		"setcoords…lin…lin" {insertText "setcoords(lin,lin);\r•" }
		"setcoords…log…log" {insertText "setcoords(log,log);\r•" }
		"setcoords…log…lin" {insertText "setcoords(log,lin);\r•" }
		"setcoords…lin…log" {insertText "setcoords(lin,log);\r•" }
		"setrange" {insertText "setrange(•,•,•,•);\r•" }
		"gdraw" {insertText "gdraw \"•\";\r•" }
		"gdrawarrow" {insertText "gdrawarrow " }
		"gdrawdblarrow" {insertText "gdrawdblarrow " }
		"gfill" {insertText "gfill " }
		"glabel" {insertText "glabel.•(\"•\",•,•);\r•" }
		"gdotlabel" {insertText "gdotlabel.•(\"•\",•,•);\r•" }
		"auto.x" {insertText "auto.x; " }
		"auto.y" {insertText "auto.y; " }
		"autogrid" {insertText "autogrid(•,•) •;\r•" }
		"frame" {insertText "frame.• •;\r•" }
		"grid" {insertText "grid.•(•,•) •;\r•" }
		"itick" {insertText "itick.•" }
		"otick" {insertText "otick.•" }
		"augment" {insertText "augment.•(•,•);\r•" }
		"format" {insertText "format(\"\%•\",•)" }
		"gdata" {insertText "gdata(\"•\",•,•);\r•" }
		"init_numbers" {insertText "init_numbers(•,•,•,•,•);\r•" }
		"Mreadpath" {insertText "Mreadpath(\"•\") •;\r•" }
		"plot" {insertText "plot " }
	}
}


proc Mp::charactersDesignProc {menu item} {
	set item [string trimleft $item]
	switch $item  {	
		"makegrid" {Mf::mkgridProc}
		"beginchar…endchar" {insertText "beginchar(\"•\",•,•,•);\"•\";\r•\rendchar;\r•"}
		"extra_beginchar" {insertText "extra_beginchar:=\" • \";\r•"}
		"extra_endchar" {insertText "extra_endchar:=\" • \";\r•"}
		"change_width" {insertText "change_width;\r•"}
		"makebox" {insertText "makebox(•);\r•"}
		"maketicks" {insertText "maketicks(•);\r•"}
		"labelfont" {insertText "labelfont \"•\";\r•"}
		"italcorr" {insertText "italcorr •;\r•"}
		"rulepen" {insertText "rulepen:= •;\r•"}
		"capsule_def" {insertText "capsule_def •;\r•"}
		default {insertText "$item "}
	}
}


proc Mp::fontCodingProc {menu item} {
	set item [string trimleft $item]
	switch $item  {	
		"font_identifier" - "font_coding_scheme" {insertText "${item}:= \"•\";\r•"}
		default {insertText "${item}:= •;\r•"}
	}
}


proc Mp::modeDefinitionsProc {menu item} {
	switch $item  {	
		"mode_def" {insertText "mode_def;\r"}
		"mode_setup" {insertText "mode_setup;\r"}
		"extra_setup" {insertText "extra_setup= \"•\";\r"}
		"blacker" {insertText "blacker= •;\r•"}
		"o_correction" {insertText "o_correction= •;\r•"}
		"smode" {insertText "smode;\r•"}
		"proofrule" {insertText "proofrule(•,•);\r•"}
		"proofrulethickness" {insertText "proofrulethickness:=•;\r•"}
	}
}


proc Mp::pixellisationProc {menu item} {
	set item [string trimleft $item]
	insertText "${item}(•);\r•"
}

