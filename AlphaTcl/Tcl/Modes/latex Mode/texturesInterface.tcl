## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "texturesInterface.tcl"
 #                                          created: 11/10/1992 {10:42:08 AM}
 #                                      last update: 03/21/2006 {03:12:44 PM}
 # Description:
 #
 # Support for Textures (MacOS only).
 #
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

proc texturesInterface.tcl {} {}

namespace eval TeX           {}
namespace eval TeX::Textures {}

# ==========================================================================
#
# ×××× -------- ×××× #
#
# ×××× Textures support ×××× #
#

if {![info exists TeXmodeVars(versionForTextures)]} {return}

proc TeX::Textures::setInfo {args} {

    global TeX::PackagesSubmenuItems AllTeXSearchPaths texSig \
      TeXmodeVars

    # Reset the Packages submenu so that it will be rebuilt:
    set TeX::PackagesSubmenuItems ""
    # Set things up for Textures
    if {$texSig == $texAppSignatures(Textures)} {

	hook::register   launch TeX::Textures::launched "*TEX"
	hook::register   closeHook        TeX::Textures::closeHook      TeX
	hook::register   winChangedNameHook TeX::Textures::winChangedNameHook     TeX
	hook::register   openHook         TeX::Textures::openHook       TeX
	if {$TeXmodeVars(versionForTextures)} {
	    hook::register   changeTextHook TeX::Textures::doFlash      TeX
	    tclAE::installEventHandler BSRs SelP TeX::Textures::setSelect
	    tclAE::installEventHandler BSRs GetT TeX::Textures::getBSRText
	    # In case it isn't running!
	    catch {
		eval lunion TeXmodeVars(availableTeXFormats) "(-)" [TeX::Textures::formats]
	    }
	}
    } else {
	hook::deregister launch TeX::Textures::launched "*TEX"
	hook::deregister closeHook        TeX::Textures::closeHook      TeX
	hook::deregister winChangedNameHook  TeX::Textures::winChangedNameHook     TeX
	hook::deregister openHook         TeX::Textures::openHook       TeX
	if {$TeXmodeVars(versionForTextures)} {
	    hook::deregister changeTextHook TeX::Textures::doFlash      TeX
	    lunion TeXmodeVars(availableTeXFormats) "(-)" "LaTeX" \
	      "Big-LaTeX" "AMS-TeX" "Plain TeX"
	}
    }

}

# Registered only if we're using Textures

proc TeX::Textures::openHook {name} {
    global Texturesconnections
    set TeXjob ""
    
    # Temporary windows need to be saved before textures will
    # deal with them
    if {![win::IsFile $name name]} { return }
    
    if {[info exists Texturesconnections]} {
        foreach entry $Texturesconnections {
            if {[lindex $entry 0] == $name} {
                set TeXjob [lindex $entry 1]
                break
            }
        }
    }
    if {$TeXjob == "" } {
	set quotedSig '*TEX'
	if {![catch {tclAE::build::event $quotedSig BSRs Begi \
	  "----" [tclAE::build::alis $name]} jobDesc]} {
	    set TeXjob [tclAE::getKeyData $jobDesc Jobi]
	    tclAE::disposeDesc $jobDesc
	    lappend Texturesconnections [list $name $TeXjob]
	}
    }
}

proc TeX::Textures::closeHook {name} {

    global Texturesconnections

    if {[info exists Texturesconnections]} {
        set winNames [list]
        foreach tc $Texturesconnections {lappend winNames [lindex $tc 0]}
        if {[set pos [lsearch -exact $winNames $name]] > -1 } {
            # Close Textures' connection:
            set TeXjob [lindex [lindex $Texturesconnections $pos] 1]
            tclAE::send '*TEX' BSRs Disc Jobi $TeXjob
            # Update list of connections:
            set Texturesconnections [lreplace $Texturesconnections $pos $pos]
        }
    }
}

proc TeX::Textures::winChangedNameHook {newName oldName} {
    TeX::Textures::closeHook $oldName
    TeX::Textures::openHook  $newName
}

proc TeX::Textures::formats {} {
    set fmtDesc [tclAE::build::event '*TEX' BSRs Info Fmts long(0)]
    set fmts [tclAE::getKeyData $fmtDesc Fmts]
    tclAE::disposeDesc $fmtDesc
    return $fmts
}

proc TeX::Textures::launched {args} {

    global Texturesconnections menu::items

    set Texturesconnections ""

    set "menu::items(Format)" [TeX::Textures::formats]
}

proc TeX::Textures::doFlash {args} {

    global TeXmodeVars

    if {$TeXmodeVars(useTexturesFlashMode)} {
	if {[set currentWin [win::StripCount [win::Current]]] == ""} {return}
	
	global Texturesconnections
	
	if {[info exists Texturesconnections]} {
	    set winNames [list]
	    foreach tc $Texturesconnections {lappend winNames [lindex $tc 0]}
	    if {[set pos [lsearch -exact $winNames $currentWin]] > -1 } {
		# Tell Textures to typeset
		set connection [lindex $Texturesconnections $pos]
		set TeXjob [lindex $connection 1]
		tclAE::send '*TEX' BSRs Typf \
		  Jobi $TeXjob \
		  Fmat [tclAE::build::TEXT LaTeX]
	    }
	}
    }
}

# Called by command-click on Textures dvi window to move Alpha selection
# point

# tclAE::installEventHandler BSRs SelP TeX::Textures::setSelect

proc TeX::Textures::setSelect {theAppleEvent theReplyAE} {
    global Texturesconnections

    # find window for the jobid
    set TeXwin 0
    set TeXjob [tclAE::getKeyData $theAppleEvent Jobi]
    if {[info exists Texturesconnections]} {
        foreach entry $Texturesconnections {
            if {[lindex $entry 1] == $TeXjob} {
                set TeXwin [lindex $entry 0]
                break
            }
        }
    }

    set selpt [tclAE::getKeyData $theAppleEvent ----]
    switchTo '[expr {$::alpha::platform == "alpha" ? "ALFA" : "AlTk"}]'
    bringToFront [file tail $TeXwin]
    selectText -w $TeXwin $selpt [pos::math $selpt + 1]
    centerRedraw
    refresh
}

# tclAE::installEventHandler BSRs GetT TeX::Textures::getBSRText

proc TeX::Textures::getBSRText {theAppleEvent theReplyAE} {
    global Texturesconnections
    
    set TeXwin ""

    # find window for the jobid
    set TeXjob [tclAE::getKeyData $theAppleEvent Jobi]
    if {[info exists Texturesconnections]} {
	foreach entry $Texturesconnections {
	    if {[lindex $entry 1] == $TeXjob} {
		set TeXwin [lindex $entry 0]
		break
	    }
	}
    }
    
    if {$TeXwin != ""} {
	set str [tclAE::build::TEXT [getText -w $TeXwin [minPos] [maxPos -w $TeXwin]]]
	tclAE::send -t 1200 '*TEX' BSRs TTeX \
	  TEXT $str \
	  Jobi $TeXjob
    }
}

proc TeX::Textures::synchronizeDoc {args} {

    if {[set currentWin [win::StripCount [win::Current]]] == ""} {return}

    global Texturesconnections

    set TeXjob ""

    # Is the current window part of TeX fileset?
    if {[info exists Texturesconnections]} {
	foreach entry $Texturesconnections {
	    if {[lindex $entry 0] == $currentWin} {
		set TeXjob [lindex $entry 1]
		break
	    }
	}
	tclAE::send '*TEX' BSRs FFoc long [getPos] Jobi $TeXjob
    }
}

# ==========================================================================
#
# .