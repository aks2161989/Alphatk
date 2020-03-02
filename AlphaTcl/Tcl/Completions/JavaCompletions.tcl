## 
 # This file will be sourced automatically, immediately after the
 # _first_ time the file which defines its mode is sourced.  Use this
 # file to declare completion items and procedures for this mode.
 # 
 # Some common defaults are included below.
 ##

## 
 # These declare, in order, the names of the completion procedures for
 # this mode.  The actual procedure must be named
 # '${mode}Completion::${listItem}', unless the item is 'completion::*'
 # in which case that actual procedure is called.  
 ##
set completions(Java) {completion::cmd completion::electric completion::word}

# Declare some items to add to the elec menu
lunion "JavaTemplates" createNewClass newFunction

# ×××× Completions ×××× #

set Javacmds { 
    abstract boolean break byvalue catch class const continue 
    default double extends false final finally float future generic 
    implements import inner instanceof interface native operator outer 
    package private protected public return short static super switch 
    synchronized throw throws transient volatile while
}

# NOTE FROM VINCE: I just copied these from C++ mode, I'm not sure if
# some ought to be a bit different for Java.
set Javaelectrics(for) " (¥init¥;¥test¥;¥increment¥)\{\n\t¥loop body¥\n\}\n¥¥"
set Javaelectrics(while) " (¥test¥)\{\n\t¥loop body¥\n\}\n¥¥"
set Javaelectrics(switch) " (¥value¥)\{\nÉcase ¥item¥:\n\t¥case body¥\nÉdefault:\n\t¥default body¥\n\}\n¥¥"
set Javaelectrics(case) " ¥item¥:\nÉ¥case body¥\ncase"
set Javaelectrics(do) " \{\n\t¥¥\n\} while (¥test¥);\n¥¥"
set Javaelectrics(if) "(¥condition¥)\{\n\t¥if body¥\n\} ¥¥"
set Javaelectrics(else) " \{\n\t¥else body¥\n\} ¥¥"
set Javaelectrics(class) " ¥object name¥ extends ¥super-class name¥ implements ¥interface-names¥ \{\n\n\tpublic ¥fn name¥(¥args¥)\{\n\t\t¥fn body¥\n\t\}\n\t¥¥\n\}\n¥¥"
set Javaelectrics(try) " \{\r\t¥try body¥\r\}\rcatch (¥...¥) \{\r\t¥catch body¥\r\}\r¥¥"


