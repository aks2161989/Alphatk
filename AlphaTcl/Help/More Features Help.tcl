## -*-Tcl-*-
 # ==========================================================================
 # Help Files
 #
 # FILE: "More Features Help.tcl"
 #                                          created: 11/11/2003 {11:17:58 AM}
 #                                      last update: 03/06/2006 {05:53:57 PM}
 # Description: 
 # 
 # Script to open a Help window for any menu.
 #
 # The "Help > More Features Help" menu item sources this file and eventually
 # calls the [::help::openFeatureHelpWindow] procedure.
 # 
 # Press Command-L to test this right now.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # ==========================================================================
 ##

namespace eval ::help {
    
    variable lastChosenFeature
    variable featureHelpOptions
    variable prettifiedFeatures
    
    if {![info exists lastChosenFeature]} {
	foreach featureName [alpha::listAlphaTclPackages "features"] {
	    set FeatureName [quote::Prettify $featureName]
	    set prettifiedFeatures($FeatureName) $featureName
	}
	foreach featureName [alpha::listAlphaTclPackages "auto-loading"] {
	    set FeatureName [quote::Prettify $featureName]
	    set prettifiedFeatures($FeatureName) $featureName
	}
	unset featureName FeatureName
	set featureHelpOptions [lsort -dictionary -unique \
	  [array names prettifiedFeatures]]
	set lastChosenFeature  [lindex $featureHelpOptions 0]
    } 
}

##
 # --------------------------------------------------------------------------
 #
 # "::help::openFeatureHelpWindow" --
 # 
 # The first time this file is sourced, we define this procedure.  We offer
 # the user a listpick dialog of all possible features (including those that
 # are presented "Config > Global Setup > Features", those in preference
 # dialogs, and auto-loading) -- anything in the [index::feature] array that
 # is not a mode or a menu.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info procs ::help::openFeatureHelpWindow]]} {
    ;proc ::help::openFeatureHelpWindow {} {
	
	variable lastChosenFeature
	variable featureHelpOptions
	variable prettifiedFeatures
	
	set p "Choose a feature for which you want help:"
	set f [listpick -p $p -L [list $lastChosenFeature] $featureHelpOptions]
	package::helpWindow $prettifiedFeatures($f)
	set lastChosenFeature $f
	return
    }
}

# Now we call this procedure.
::help::openFeatureHelpWindow

# ===========================================================================
# 
# .