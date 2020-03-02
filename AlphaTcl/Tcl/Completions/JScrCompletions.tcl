## -*-Tcl-*-
 # ###################################################################
 #  JavaScript mode - tools for editing JavaScript documents
 # 
 #  FILE: "JScrCompletions.tcl"
 #                                    created: 98-02-07 12.29.10 
 #                                last update: 98-02-14 19.10.10 
 #  Author: Johan Linde
 #  E-mail: <jl@theophys.kth.se>
 #     www: <http://bach.theophys.kth.se/~jl/Alpha.html>
 #  
 # Version: 1.1
 # 
 # Copyright 1997, 1998 by Johan Linde
 #  
 # This software may be used freely, and distributed freely, as long as the 
 # receiver is not obligated in any way by receiving it.
 #  
 # If you make improvements to this file, please share them!
 # 
 # ###################################################################
 ##

set completions(JScr) {completion::electric completion::word}

set JScrelectrics(for) " (•init•; •test•; •increment•) \{\n\t•loop body•\n\}\n••"
set JScrelectrics(while) " (•test•)\{\n\t•loop body•\n\}\n••"
set JScrelectrics(switch) " (•value•)\{\n…case •item•:\n\t•case body•\n…default:\n\t•default body•\n\}\n••"
set JScrelectrics(case) " •item•:\n…•case body•\ncase"
set JScrelectrics(do) " \{\n\t••\n\} while (•test•);\n••"
set JScrelectrics(if) " (•condition•)\{\n\t•if body•\n\} ••"
set JScrelectrics(else) " \{\n\t•else body•\n\} ••"
set JScrelectrics(function) " •name•(•arguments•) \{\n\t•function body•\n\}\n••"
