
#############################################################################
#   FILE: sql.tcl
#----------------------------------------------------------------------------
# AUTHOR:     Joel D. Elkins
#     of      New Media, Inc.
#             200 South Meridian, Ste. 220
#             Indianapolis, IN 46225
#
# internet:   jdelkins@iquest.net  (preferred)
# compuserve: 72531,314
# AOL:        jdelkins
#
#   Copyright © 1994-1995 by Joel D. Elkins
#   All rights reserved.
#############################################################################
#
#  Alpha mode for SQL and Oracle's PL/SQL programming language
#  Converts SQL and PL/SQL keywords to uppercase on the fly and colorizes
#
#############################################################################
# HISTORY
#                  
# modified who rev reason
# -------- --- --- ------ 
 #  2000-12-07 DWH 1.1.2 updated help text
# 7/29/94  JDE 1.0 Original 
# 2/8/95   JDE 1.1 Added electUpper for tab, cr, and ';'
# 10/31/03 cbu 1.1.3 Turned off the "upcaseCommands" preference by default
#                  after receiving some feedback from a user that this will
#                  break MySQL programming code, and it was difficult for him
#                  to figure out why this was taking place.
#                  Fix to [sql_electUpper] status bar message.
#############################################################################

alpha::mode SQL 1.1.3 dummySQL {*.sql *.pkg} {
} {
} uninstall {
    this-file
} description {
    Supports the editing of SQL programming files
} help {
    SQL Mode is for SQL and Oracle's PL/SQL programming language.  If the SQL
    mode preference "Upcase Commands" is turned on, SQL and PL/SQL keywords
    are converted to uppercase on the fly.
    
    Preferences: Mode-SQL
    
    Automatic file marking with the Marks Menu is supported.
    
    Click on this "SQL Example.sql" link for an example syntax file.
    
    Oracle maintains a faq <http://www.orafaq.org/> with more information
    about SQL.
}

proc dummySQL {} {}

#############################################################################
# PL/SQL mode by Joel D. Elkins
#############################################################################

newPref	v	wordBreak		{(\$)?\w+}	SQL
newPref	v	prefixString		{--}	SQL
newPref	v	lineWrap		{0}	SQL
newPref	v	funcExpr		{(PROCEDURE|FUNCTION)[ \t]+(\w+)}	SQL
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 0 SQL
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 SQL
# Set this preference to automatically upcase command names as you type.
newPref f upcaseCommands {0} SQL

set SQL::commentCharacters(General) "-- "
set SQL::commentCharacters(Paragraph) [list "-- " "-- " "-- "]

Bind '\ ' {sql_electUpper "\ "} "SQL"
Bind 0x30 {sql_electUpper "\t"} "SQL"
Bind '\r' {sql_electUpper "\r"} "SQL"
Bind '\;' {sql_electUpper "\;"} "SQL"


set sqlKeywords {
    ABORT ACCEPT ACCESS ALTER AND ARRAY ARRAYLEN AS ASSERT AT AVG BEGIN BETWEEN BODY
    CASE COLUMNS COMMIT CONSTANT COUNT CREATE CURSOR DECLARE DEFAULT DEFINITION
    DELETE DESC DISPOSE DISTINCT DO DROP ELSE ELSIF END ENTRY EXCEPTION EXISTS EXIT
    FALSE FETCH FOR FROM FUNCTION GOTO IF IN INSERT INTERSECT INTO IS LIKE LOOP MAX MIN
    MINUS MOD NEW OF ON OPEN OR OUT PACKAGE PARTITION POSITIVE PRAGMA PRIVATE
    PROCEDURE PUBLIC RANGE RECORD REM REPLACE RETURN ROLLBACK ROWTYPE RUN SAVEPOINT
    SELECT SET SIZE START STDDEV SUM THEN TO TYPE UNION UNIQUE UPDATE USE VALUES
    VARIANCE WHEN WHERE WHILE WITH XOR
}
###	Just colorize uppercase keywords
#	abort accept access alter and array arraylen as assert at avg begin between body
#	case columns commit constant count create cursor declare default definition
#	delete desc dispose distinct do drop else elsif end entry exception exists exit
#	false fetch for from function goto if in insert intersect into is like loop max min
#	minus mod new of on open or out package partition positive pragma private
#	procedure public range record rem replace return rollback rowtype run savepoint
#	select set size start stddev sum then to type union unique update use values
#	variance when where while with xor
###
regModeKeywords -e {--} -b {/*} {*/} -c red -k blue SQL $sqlKeywords
unset sqlKeywords
#================================================================================

unset -nocomplain plSqlKeywords

lappend plSqlKeywords \
  abort accept access alter and array arraylen as assert at avg begin between body \
  case columns commit constant count create cursor declare default definition \
  delete desc dispose distinct do drop else elsif end entry exception exists exit \
  false fetch for from function goto if in insert intersect into is like loop max min \
  minus mod new of on open or out package partition positive pragma private \
  procedure public range record rem replace return rollback rowtype run savepoint \
  select set size start stddev sum then to type union unique update use values \
  variance when where while with xor


set sql_firstUpcase 1
proc sql_electUpper {char} {
    global SQLmodeVars plSqlKeywords sql_firstUpcase

    set a [getPos]
    backwardWord
    set b [getPos]

    #make sure we're not in a comment
    beginningOfLine
    set commentSearch {(^[ \t]*rem[ \t]+)|(^[ \t]*REM[ \t]+)|--}
    if {[catch {search -s -r 1 -f 1 -l $b -- $commentSearch [getPos]}] != 0} {
	#if not, make the word uppercase if it's a keyword
	set cmd [getText $b $a]
	goto $b
	if {$SQLmodeVars(upcaseCommands) && \
	  [lsearch -exact $plSqlKeywords [string tolower $cmd]] >= 0} {
	    upcaseWord
	    if {$sql_firstUpcase} {
		set sql_firstUpcase 0
		set messageText "Unset the \"upcaseCommands\" preference\
		  to disable automatic upcasing."
	    } else {
		set messageText ""
	    }
	}
    }
    goto $a
    if {0 == [string compare $char "\r"]} {
	bind::CarriageReturn
    } else {
	insertText $char
    }
    if {[info exists messageText]} {
	status::msg $messageText
    } 
}

proc SQL::MarkFile {args} {
    global SQLmodeVars
    win::parseArgs w
    status::msg "Marking \"[win::Tail $w]\" É"
    set pos [minPos -w $w]
    set pat $SQLmodeVars(funcExpr)
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1 -- $pat $pos} res]} {
	set start [lindex $res 0]
	set end [lindex $res 1]
	set text [lindex [getText -w $w $start $end] 1]
	set pos $end
	while {[lcontains marks $text]} {
	    append text " "
	}
	lappend marks $text
	set inds($text) "$start $end"
    }
    set count 0
    if {[info exists inds]} {
	foreach f [lsort [array names inds]] {
	    setNamedMark -w $w $f [pos::lineStart -w $w \
	      [pos::math -w $w [pos::lineStart -w $w \
	      [lindex $inds($f) 0]] - 1]] [lindex $inds($f) 0] [lindex $inds($f) 1]
	    incr count
	}
    }
    set msg "The window \"[win::Tail $w]\" contains $count mark"
    append msg [expr {($count == 1) ? "." : "s."}]
    status::msg $msg
    return
}
