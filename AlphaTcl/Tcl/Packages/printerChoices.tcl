## -*-Tcl-*- (install)
 # ###################################################################
 #  Alpha - new Tcl folder configuration
 # 
 #  FILE: "printerChoices.tcl"
 #                                    created: 13/9/97 {2:30:36 pm} 
 #                                last update: 05/08/2004 {05:13:02 PM} 
 #  
 # Reorganisation carried out by Vince Darley with much help from Tom 
 # Fetherston, Johan Linde and suggestions from the Alpha-D mailing list.  
 # Alpha is shareware; please register with the author using the register 
 # button in the about box.
 #  
 # Description:
 # 
 # This package converts the basic 'Print…' menu item into a sub-menu
 # from which the user can select a variety of printing methods.
 # This used to be part of standard Alpha, but it seemed a good
 # candidate to split off into a package.
 # ###################################################################
 ##

alpha::extension printerChoicesMenu 0.2.1 {
    menu::buildProc print setupPrintMenu
    menu::replaceWith File [list "/P<Eprint…" "/P<S<I<OprintAll"] submenu print
} uninstall {
    this-file
} description {
    This package replaces the basic "File > Print' menu item into a submenu
    from which you can select a variety of printing methods
} help {
    This package replaces the basic "File > Print' menu item into a submenu
    from which you can select a variety of printing methods.  
    
    Preferences: Features
    
    All of the available printing methods are listed in this menu, with the
    current default printing method indicated by a preceding "•" -- selecting
    a different choice will make that item the new default.
    
    The list of options for printing methods is currently hard-wired in the
    file "printerChoices.tcl".  If you have an alternative printing method
    that is not listed please send a note to one of the listservs described in
    the "Readme" file.
}
    
if {${alpha::macos} == 1} {
    # Don't think many of these are available on OS X.
    lappend printerList Alpha Kodex Enscriptor {Drop•PS} PrettyC
} elseif {${alpha::macos} == 2} {
    lappend printerList Alpha enscript
} elseif {$tcl_platform(platform) == "windows"} {
    lappend printerList Alpha PrintFile
} else {
    lappend printerList Alpha enscript
}

newPref var defaultPrinter "Alpha" global setupPrintMenu $printerList
lunion varPrefs(Printer) defaultPrinter

proc setupPrintMenu {args} {
    global defaultPrinter printerList
    set m [list {/P<EPrint…} {/P<S<I<OPrint All…} "\(-"]
    eval lappend m $printerList
    
    Menu -m -n print -p menu::print $m
    
    foreach item $m {
	if {$item eq $defaultPrinter} {
	    markMenuItem -m print $item on
	} else {
	    markMenuItem -m print $item off
	}
    }
}

proc menu::print {menu item} {
    global defaultPrinter
    switch -glob $item {
	"Print All"	{	
	    if {$defaultPrinter == "Alpha"} {
		printAll
	    } else {
		foreach f [winNames -f] {
		    printFile [win::StripCount $f]
		}
	    }
	}
	"Print"	{
	    printFile [win::StripCount [win::Current]]
	}
	default {
	    set defaultPrinter $item
	    prefs::modified defaultPrinter
	    setupPrintMenu
	}
    }
}

proc printFile {fname} {
    global defaultPrinter
    
    switch -glob $defaultPrinter {
	"Alpha"			{print}
	"Kodex*"		{openAndSendFile KoDX}
	"Enscr*"		{openAndSendFile Ens3}
	"Drop*"			{openAndSendFile {D•PS}}
	"Pret*"			{openAndSendFile niCe}
	"enscript" {
	    status::msg [exec enscript $fname]
	}
	"PrintFile" {
	    global HOME
	    status::msg [exec [file join $HOME Tools PrFile32.exe] $fname]
	}
    }
}

