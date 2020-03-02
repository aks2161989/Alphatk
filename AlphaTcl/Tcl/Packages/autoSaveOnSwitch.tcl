## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "autoSaveOnSwitch.tcl"
 #                                          created: 06/10/2001 {10:19:51 pm}
 #                                      last update: 03/06/2006 {08:10:23 PM}
 # Description:
 #  
 # Activating this feature via "Config --> Preferences --> Backups" will
 # automatically save all windows which exist as local files when switching
 # from Alpha to another application.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #
 # Copyright (c) 2001-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::declare flag autoSaveOnSwitch 0.1.1 "global-only" {
    # Initialization script.
    
    # To automatically save all open windows which exists as local files
    # (i.e. not new buffers) whenever switching from Alpha to another
    # program, turn this item on||To disable the automatic saving of all
    # open windows when switching from Alpha to another program, turn this
    # item off \
    newPref flag autoSaveOnSwitch 0
    set autoSaveOnSwitch 0
    lunion flagPrefs(Backups) autoSaveOnSwitch
    set flagPrefs(Backups) [lsort -dictionary $flagPrefs(Backups)]
} {
    # Activation script.
    set autoSaveOnSwitch 1
    hook::register   suspendHook {autoSave::saveOnSwitch}
} {
    # Deactivation script.
    set autoSaveOnSwitch 0
    hook::deregister suspendHook {autoSave::saveOnSwitch}
} { 
    # off
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} uninstall {
    this-file
} description {
    This feature instructs ÇALPHAÈ to always save open windows when you
    switch to another application
} help {
    Activating this feature via "Config > Preferences > Input-Output" will
    automatically save all windows which exist as local files when switching
    from Alpha to another application.
    
    Preferences: Backups
}

namespace eval autoSave {}

proc autoSave::saveOnSwitch {args} {

    if {![llength [set windows [winNames -f]]]} {return} 
    
    # While we'd like to use 'saveAll' here, if there is a new file (i.e
    # one that hasn't not been saved to disk yet) the save dialog is pretty
    # messed up -- best to only save files that currently exist.
    
    set currentWindow [win::CurrentTail]
    foreach window $windows {
	if {![win::IsFile $window]} {continue}
	getWinInfo -w $window arr
	if {$arr(dirty) && ![catch {bringToFront $window}]} {
	    menu::fileProc "file" "save"
	}
    }
    catch {bringToFront $currentWindow}
}

# ===========================================================================
#
# ×××× ------------ ×××× #
# 
# ×××× Version History ×××× #
# 
#  modified by  rev    reason
#  -------- --- ------ -----------
#  06-10-01 cbu 0.1    Original.
#  03-20-02 cbu 0.2    Split off from "backups.tcl" into separate package.
#                      

# ===========================================================================
#
# .