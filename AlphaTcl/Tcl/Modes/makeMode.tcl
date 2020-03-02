## -*-Tcl-*-
 # ###################################################################
 #  Please help with this mode! (also see makeMenu.tcl)
 # 
 #  FILE: "makeMode.tcl"
 #                                    created: 09/03/2001 {23:29:40 PM} 
 #                                last update: 2005-04-01 13:50:57
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #          317 Paseo de Peralta, Santa Fe
 #     www: http://www.santafe.edu/~vince/
 #  
 #  
 #  modified   who rev   reason
 #  --------   --- ----- ------
 #  09/03/2001 VD  0.1   Original.
 #  31/03/2005 bd  0.2   Keywords. Color proc and prefs. Completions.
 # ###################################################################
 ##

# mode declaration
alpha::mode make 0.2 source {Makefile makefile makefile.vc GNUmakefile configure} {makeMenu} {
    # Script to execute at Alpha startup
} maintainer {
    {Vince Darley} <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} uninstall {
    this-file
} description {
    Supports the editing of "make" files
} help {
    For 'make' files.  This mode currently supports File Marking, syntax
    coloring, and uses the package: makeMenu .  See "makeMode.tcl" to make
    additional improvements.
}

namespace eval make {}

# ×××× mode preferences ×××× #

newPref f autoMark 0 make
newPref v prefixString {# } make
newPref var wordBreak {[_/\w.]+} make

# Default colors for the make keywords
newPref color keywordColor blue make make::colorizeMake
newPref color implicitVarsColor magenta make make::colorizeMake
newPref color targetNamesColor magenta make make::colorizeMake
newPref color stringColor green make make::colorizeMake
newPref color commentColor red make make::colorizeMake

# List in the parseFuncs proc all the "simply expanded" variables (defined
# with := or ?=) as opposed to "recursively expanded" variables (defined
# with a simple equal sign)

newPref	v funcExpr {^([^ ?=]+) *(\?|:)=(.+)$} make
newPref	v parseExpr {^([^ ?=]+) *(\?|:)=(.+)$} make

set make::commentCharacters(General) "#"
set make::commentCharacters(Paragraph) [list "## " " ##" " # "]
set make::commentCharacters(Box) [list "#" 1 "#" 1 "#" 3]


# Syntax coloring
# ---------------

set makeKeywords [list addprefix addsuffix basename call define dir else \
  endef endif error export filter filter-out findstring firstword foreach \
  foreach if ifdef ifeq ifndef ifneq include join notdir origin override \
  patsubst shell sort strip subst suffix unexport vpath warning wildcard word \
  wordlist words ]

set makeTargetNames [list .DEFAULT .DELETE_ON_ERROR .EXPORT_ALL_VARIABLES \
  .IGNORE .INTERMEDIATE .LIBPATTERNS .NOTPARALLEL .PHONY .POSIX .PRECIOUS \
  .SECONDARY .SILENT .SUFFIXES all check clean dist distclean dvi info \
  install installcheck installdirs mostlyclean uninstall ]

# ImplicitVariables
set makeImplicitVars [ list AR ARFLAGS AS ASFLAGS CC CFLAGS CO COFLAGS CPP \
  CPPFLAGS CTANGLE CWEAVE CXX CXXFLAGS FC FFLAGS GET GFLAGS GPATH LDFLAGS \
  LEX LFLAGS MAKECMDGOALS MAKEFLAGS MAKEINFO MAKELEVEL MAKEOVERRIDES \
  MAKE_VERSION MFLAGS PC PFLAGS RFLAGS RM TAGS TANGLE TEX TEXI2DVI VPATH \
  WEAVE YACC YACCR YFLAGS ]


regModeKeywords -C make {}

proc make::colorizeMake {{pref ""}} {
	global makemodeVars makeKeywords makeImplicitVars makeTargetNames
	regModeKeywords -a -c $makemodeVars(commentColor) \
	  -e {#} -i "\$" make {}
	regModeKeywords -a -k $makemodeVars(keywordColor) make $makeKeywords
	regModeKeywords -a -k $makemodeVars(implicitVarsColor) make $makeImplicitVars
	regModeKeywords -a -k $makemodeVars(targetNamesColor) make $makeTargetNames
	if {$pref != ""} {refresh}
}

# Calling make::colorizeMake now.
make::colorizeMake

# Completions
# -----------

set completions(make) {completion::cmd completion::electric}

set makecmds [lsort -dictionary [concat $makeKeywords $makeImplicitVars $makeTargetNames]]

# # # # # # abbreviations # # # # #

set makeelectrics(ifdef)   " ¥¥\r¥¥\relse\r¥¥\rendif"
set makeelectrics(ifndef)   " ¥¥\r¥¥\relse\r¥¥\rendif"
set makeelectrics(ifeq)   " (¥¥,¥¥)\r¥¥\relse\r¥¥\rendif"
set makeelectrics(ifneq)   " (¥¥,¥¥)\r¥¥\relse\r¥¥\rendif"
set makeelectrics(define)  " ¥¥\r\t¥¥\rendef"


# File marking
# ------------

proc make::MarkFile {} {
    status::msg "MarkingÉ"
    set pos  [minPos]
    set markExpr {^([a-zA-Z]+):}

    while {![catch {search -s -f 1 -r 1 -m 0 -i 1 $markExpr $pos} match]} {
	set start [lindex $match 0]
	set end   [pos::math [lindex $match 1] -1]
	set text  [getText $start $end]
	setNamedMark $text $start $start $start
	set pos [nextLineStart $end]
    }
    status::msg ""
}


