## -*-Tcl-*-
 # #####################################################################
 # 
 # BSD license
 # 
 # #####################################################################
 ##

package provide pdftext 0.1

package require pdf4tcl

namespace eval pdftext {}

proc pdftext::convert {w filename} {
    pdf4tcl::new mypdf -compress 1 -paper a4
    mypdf startPage
    
    mypdf setFont 8 Helvetica
    
    set x 22
    set y 50
    
    set index 1.0
    while {[$w compare $index < end]} {
	set endline [$w index "$index displaylineend"]
	set text [$w get $index $endline]
	
	mypdf drawTextAt $x $y $text
	incr y 30
	set index [$w index "$endline +1c"]
    }

    mypdf write -file $filename
    
    mypdf cleanup
	
}


