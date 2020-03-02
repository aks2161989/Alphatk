## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 #
 # FILE: "manMode.tcl"
 #                                          created: 03/20/2001 {06:58:27 PM}
 #                                      last update: 03/21/2006 {03:20:34 PM}
 # Description:
 # 
 # Unix-style manual pages can be edited with this mode.  Parsing and viewing
 # of man pages is not supported (use 'nroff' or 'man').
 # 
 # Automatically created by mode assistant, with input from Vince.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 # 
 # Copyright (c) 2001-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # History:
 # 
 # 04/01/07 0.1.5 bd Added troff primitives and man keywords.
 #                   Modified funcExpr/parseExpr.
 #                   'tmac' extension (troff macros).
 #                   
 # ==========================================================================
 ##

# Mode declaration.
#  first two items are: name version
#  then 'source' means source this file when we first use the mode
#  then we list the extensions, and any features active by default
alpha::mode [list man Manual] 0.1.5 source {*.n *.3 *.1 *.tmac} {} {
    # Script to execute at Alpha startup
} uninstall {
    this-file
} maintainer {
} description {
    Supports the editing of unix-style manual pages
} help {
    Unix-style manual pages can be edited with this mode.  Parsing and
    viewing of man pages is not supported (use 'nroff' or 'man').
    
    Click on this hyperlink "man-Example.n" for an example.
}

proc manMode.tcl {} {}

# For Tcl 8
namespace eval man {}

newPref v wordBreak {(\\.)?[\w\\]+} man

# Paragraphs limits are either empty lines, or lines starting with a
# dot
set man::startPara {^[ \t]*(\.[^\r\n]*)?$}
set man::endPara {^[ \t]*(\.[^\r\n]*)?$}

# Mode preferences settings, which can be edited by the user (with F12)

newPref var lineWrap 1 man
# Stricto sensu troff's comment char is \" but, at the beginning of a line, 
# it is common to use .\" which will cause the line to be treated as an 
# undefined request and thus ignored completely. Otherwise troff will leave 
# a blank line.
newPref v prefixString  {.\" } man
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 0 man

# These are used by the ::parseFuncs procedure when the user clicks on
# the {} button in man mode. Troff definitions look like this:
# 	.de UL
# 	\\$1\l'|0\(ul'\\$2
# 	..
newPref var funcExpr {^\.de [^\r\n\t]+} man
newPref var parseExpr {\.de ([^\r\n\t]+)} man

# Register comment prefix
set man::commentCharacters(General) {\" }
# Register multiline comments
set man::commentCharacters(Paragraph) {{\" } {\" } {\" }}
# List of keywords from the troff doc. See:
# http://sunsite.ualberta.ca/Documentation/Gnu/groff-1.17.2/html_mono/groff.html#Request%20Index
set manKeyWords {
    .AP .AS .B .BB .BE .BI .BR .BS .BX .DT .EF .EH .EN .EQ .HP .I .IB .IP
    .IR .KF .KS .LP .MC .OF .OH .P .P1 .PD .PP .QP .QS .R .RB .RE .RI .RS
    .SB .SH .SM .SS .ST .SU .TE .TH .TP .TS .UL .VE .ab .ad .af .aln .als
    .am .as .asciify .backtrace .bd .blm .bp .br .break .c2 .cc .ce .cf
    .cflags .ch .char .chop .close .code .continue .cp .cs .cu .da .de .di
    .ds .dt .ec .el .em .eo .ev .evc .ex .fam .fc .fi .fl .fp .fspecial .ft
    .ftr .hc .hcode .hla .hlm .hpf .hw .hy .hym .hys .ie .if .ig .in .it
    .kern .lc .length .lf .lg .ll .ls .lt .mc .mk .mso .na .ne .nf .nh .nm
    .nn .nr .nroff .ns .nx .open .opena .os .pc .pi .pl .pm .pn .pnr .po
    .ps .ptr .rc .rchar .rd .rj .rm .rn .rnn .rr .rs .rt .shc .shift .so
    .sp .special .ss .sty .substring .sv .sy .ta .tc .ti .tkf .tl .tm .tr
    .trf .trnt .troff .uf .ul .unformat .vpt .vs .warn .wh .while .write
    NAME SYNOPSIS KEYWORDS ARGUMENTS DESCRIPTION OPTIONS OPERANDS EXAMPLES
    FILES ATTRIBUTES SEE ALSO NOTES USAGE ENVIRONMENT VARIABLES EXIT STATUS
    BUGS DIAGNOSTICS STANDARDS HISTORY
}


# Colour the keywords, comments etc.
regModeKeywords -C {man} {}
regModeKeywords -a -e {'\"} -k blue man $manKeyWords
# Discard the list
unset manKeyWords

proc man::MarkFile {args} {
    win::parseArgs win
    
    status::msg "Marking '[win::Tail $win]'É"
    set pos [minPos]
    if {![catch {search -w $win -s -f 1 -r 1 -i 0 {^\.SH} [minPos]}]} {
	# A mark-up copy, not formatted.
	set pat {^\.SH\s+}
    } else {
	set pat {^[A-Z][A-Z0-9:\t ]+$}
    }
    set count 0
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 $pat $pos} match]} {
	set pos0 [lindex $match 0]
	set pos1 [lindex $match 1]
	set SH   [string trim [getText -w $win $pos0 $pos1]]
	set pos2 [set pos [nextLineStart -w $win $pos1]]
	if {[regexp "\.SH" $SH]} {
	    # A mark-up man file, not formatted.
	    set SH [string trim [getText -w $win $pos1 $pos2]]
	}
	# (bd 2004-01-07) Commenting the following: the line following NAME is not 
	# necessarily part of the text. It could be another formatting request.
# 	if {$SH == "NAME"} {
# 	    set SH [string trim [getText $pos2 [nextLineStart $pos2]]]
# 	}
	set SH [markTrim $SH]
	while {[lcontains labels $SH]} {append SH " "}
	lappend labels $SH
	setNamedMark -w $win $SH $pos0 $pos0 $pos0
	incr count
    }
    status::msg "This reference manual contains $count sections."
}

proc man::DblClick {from to shift option control} {
    selectText $from $to
    set markName [getSelect]
    set pat "^(\\.SH\\s+)?$markName\\s*$"
    if {[string toupper $markName] != $markName} {
	# This is not an ALL CAP keyword.
	status::msg "Command double-click on ALL CAP section names."
    } elseif {[catch {search -f 1 -r 1 -i 0 -s $pat [minPos]} match]} {
	status::msg "Couldn't find the section '$markName'."
    } else {
	placeBookmark
	goto [lineStart [pos::math [lindex $match 0] - 1]]
	insertToTop
	status::msg "Press Ctrl-. to return to original cursor position."
    }
}

# ===========================================================================
# 
# .