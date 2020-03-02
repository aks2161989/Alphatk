## -*-Tcl-*-
 # ###################################################################
 #  Vince's Additions - an extension package for Alpha
 # 
 #  FILE: "CCompletions.tcl"
 #                                    created: 31/7/97 {2:46:39 pm} 
 #                                last update: 01/24/2005 {12:26:55 AM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2003  Vince Darley, all rights reserved
 # 
 # This file is used for C
 # 
 # ###################################################################
 ##

set completions(C) {completion::cmd Electric Class completion::word}

lunion "CTemplates" createNewClass newFunction

# ×××× Completions ×××× #

# Create the list of 'Ccmds'.  Do this in a way which allows
# other packages to add to this list before/after this file is sourced.

lappend Ccmds #elseif #endif #include default enum for register \
  return struct switch typedef volatile while

set Ccmds [lsort -dictionary -unique $Ccmds]

set Celectrics(for) " (¥init¥;¥test¥;¥increment¥) \{\n\t¥loop body¥\n\}\n¥¥"
set Celectrics(while) " (¥test¥) \{\n\t¥loop body¥\n\}\n¥¥"
set Celectrics(switch) " (¥value¥) \{\nÉcase ¥item¥:\n\t¥case body¥\nÉdefault:\n\t¥default body¥\n\}\n¥¥"
set Celectrics(case) " ¥item¥:\nÉ¥case body¥\ncase"
set Celectrics(do) " \{\n\t¥¥\n\} while (¥test¥);\n¥¥"
set Celectrics(if) " (¥condition¥) \{\n\t¥if body¥\n\} ¥¥"
set Celectrics(else) " \{\n\t¥else body¥\n\} ¥¥"
set Celectrics(struct) " ¥struct name¥ \{\n\t¥¥\n\};\n¥¥"
set Celectrics(enum) " ¥name¥ \{ ¥item¥, ¥item ... item¥ \};\n¥¥"
set Celectrics(#if) " ¥¥\n\t¥¥\n#endif\n¥¥"
set Celectrics(#include) " \"¥file¥.h\"\n¥¥"
## 
 # -------------------------------------------------------------------------
 # 
 # "C::Completion::Class" --
 # 
 #  If we've just typed the name of a class, struct or union, we can
 #  automatically fill in all occurrences of that name in the rest of
 #  the class.  (e.g. in constructors, destructors etc.)
 # -------------------------------------------------------------------------
 ##
proc C::Completion::Class { {cmd ""}} {
    set cl [completion::lastTwoWords prev]
    if {[lsearch -exact "struct union" [string trim $prev]] == -1} {
	return 0
    }
    if {[ring::type]} {ring::replaceStopMatches "object name" $cl}
    return 1
}

proc C::Completion::Electric { {cmd ""} } {
    if {[completion::lastWord] == "case "} { backwardChar }
    return [completion::electric $cmd]
}

