## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl
 # 
 #  FILE: "printing.tcl"
 #                                    created: 01/06/2004 {01:39:41 PM} 
 #                                last update: 12/14/2004 {05:53:47 PM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #          98 Gloucester Terrace, London
 #     www: http://www.santafe.edu/~vince/
 #  
 # ###################################################################
 ##


# ×××× Printing helpers ×××× #

proc printAll {} {
    foreach f [winNames -f] {
	print $f
    }
}

# If we're using Alpha 8/X, then the above function is all we need.
if {$::alpha::platform eq "alpha"} { 
    return
}

#¥ print - print front or given window
proc print {{f ""}} {
    if {$f == ""} {
	set f [win::Current]
    }
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"unix" {
	    if {![dialog::yesno -y "Print" -n "Cancel" \
	      "Printing will use the 'enscript' command. Do you\
	      wish to proceed?"]} {
		status::msg "Cancelled"
		return
	    }
	    catch {set env(PRINTER) [getEnvVarFromShell PRINTER]}
	    update idletasks
	    global enscriptOptions
	    ensureset enscriptOptions ""
	    catch {eval exec enscript $enscriptOptions \
	      [list [win::StripCount $f]]} result
	    status::msg $result
	}
	"windows" {
	    winGdiPrint $f
	}
	"macintosh" {
	    alertnote "Printing not currently implemented"
	}
    }
}

#¥ pageSetup - display the printing PageSetup dialog.
proc pageSetup {} {
    global tcl_platform 
    switch -- $tcl_platform(platform) {
	"windows" {
	    winGdiPageSetup
	}
	"unix" {
	    global enscriptOptions
	    ensureset enscriptOptions ""
	    catch {set env(PRINTER) [getEnvVarFromShell PRINTER]}
	    set res [getline "Enscript command line flags" $enscriptOptions]
	    if {[string length $res]} {
		set enscriptOptions $res
		prefs::modified enscriptOptions
	    }
	}
	"macintosh" {
	    alertnote "Printing not currently implemented"
	}
    }
}
