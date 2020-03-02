## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the ultimate editor
 # 
 #  FILE: "tkhtmlViewer.tcl"
 #                                    created: 11/15/2000 {16:47:09 PM} 
 #                                last update: 01/26/2006 {12:54:04 PM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #     www: http://www.santafe.edu/~vince/
 #  
 # ###################################################################
 ##

alpha::library tkhtmlViewer 0.2 {
    # Make sure that this is no longer in the user's "global::features" list.
    if {([lsearch ${global::features} "tkhtmlViewer"] > -1)} {
	set tempIdx [lsearch ${global::features} "tkhtmlViewer"]
	set global::features [lreplace ${global::features} $tempIdx $tempIdx]
	prefs::modified "global::features"
	unset tempIdx
    } 
    if {$alpha::platform eq "tk"} {
	set "htmlViewer(Internal tkhtml widget)" viewInTkhtml
    }
} uninstall this-file maintainer {
    "Vince Darley" <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} description {
    Allows viewing of html files (for example, some of Alphatk's help
    pages) in Alphatk, by launching a Tkhtml widget in a separate 
    interpreter
} help {
    Allows viewing of html files (for example, some of Alphatk's help pages)
    in Alphatk, by launching a Tkhtml widget in a separate interpreter.  A
    new "View Html Using" preference option named "Internal tkhtml widget" is
    available in the WWW preferences dialog.
    
    Preferences: Helpers-viewHTML
    
    If you select this option, Alphatk will use the Tkhtml widget for viewing
    local .html files.
} requirements {
    if {${alpha::platform} != "tk"} {
	error "Requires Alphatk"
    }
}

proc viewInTkhtml {filename} {
    global HOME
    # The tkhtml widget is a little buggy regarding its
    # treatment of relative links.
    set pwd [pwd]
    cd [file dirname $filename]
    script::run [file join $HOME Tools hv.tcl] \
      -script "package require Tkhtml" [file tail $filename]
    cd [pwd]
}

