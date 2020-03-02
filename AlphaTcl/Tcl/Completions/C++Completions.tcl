## -*-Tcl-*-
 # ###################################################################
 # 
 #  FILE: "C++Completions.tcl"
 # 
 # ###################################################################
 ##

set completions(C++) {completion::cmd Electric Class completion::word}

lunion "C++Templates" createNewClass newFunction

# ×××× Completions ×××× #

# Create the list of 'C++cmds'.  Do this in a way which allows
# other packages to add to this list before/after this file is sourced.

lappend C++cmds #elseif #endif #include class default enum for register \
  return struct switch typedef volatile while

set C++cmds [lsort -dictionary -unique ${C++cmds}]

set C++electrics(for) " (¥init¥;¥test¥;¥increment¥) \{\n\t¥loop body¥\n\}\n¥¥"
set C++electrics(while) " (¥test¥) \{\n\t¥loop body¥\n\}\n¥¥"
set C++electrics(switch) " (¥value¥) \{\nÉcase ¥item¥:\n\t¥case body¥\nÉdefault:\n\t¥default body¥\n\}\n¥¥"
set C++electrics(case) " ¥item¥:\nÉ¥case body¥\ncase"
set C++electrics(do) " \{\n\t¥¥\n\} while (¥test¥);\n¥¥"
set C++electrics(if) " (¥condition¥) \{\n\t¥if body¥\n\} ¥¥"
set C++electrics(else) " \{\n\t¥else body¥\n\} ¥¥"
set C++electrics(class) " ¥object name¥ : public ¥parent¥ \{\nÉpublic:\n\t¥object name¥(¥args¥);\n\t~¥object name¥(void);\n\t¥¥\n\};\n¥¥"
set C++electrics(struct) " ¥struct name¥ \{\n\t¥¥\n\};\n¥¥"
set C++electrics(enum) " ¥name¥ \{ ¥item¥, ¥item ... item¥ \};\n¥¥"
set C++electrics(#if) " ¥¥\n\t¥¥\n#endif\n¥¥"
set C++electrics(#include) " \"¥file¥.h\"\n¥¥"
set C++electrics(try) " \{\r\t¥try body¥\r\}\rcatch (¥...¥) \{\r\t¥catch body¥\r\}\r¥¥"
## 
 # -------------------------------------------------------------------------
 # 
 # "C++::Completion::Class" --
 # 
 #  If we've just typed the name of a class, struct or union, we can
 #  automatically fill in all occurrences of that name in the rest of
 #  the class.  (e.g. in constructors, destructors etc.)
 # -------------------------------------------------------------------------
 ##
proc C++::Completion::Class { {cmd ""}} {
    set cl [completion::lastTwoWords prev]
    if {[lsearch -exact "class struct union" [string trim $prev]] == -1} {
	return 0
    }
    if {[ring::type]} {ring::replaceStopMatches "object name" $cl}
    return 1
}

proc C++::Completion::Electric { {cmd ""} } {
    if {[completion::lastWord] == "case "} { backwardChar }
    return [completion::electric $cmd]
}

