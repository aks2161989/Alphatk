## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "alphaTclCvs.tcl"
 #                                          created: 06/27/2003 {02:16:38 PM}
 #                                      last update: 05/25/2006 {10:06:35 AM}
 # Description:
 # 
 # Provides access to the AlphaTcl CVS server via an "Alpha Tcl Cvs" 
 # submenu inserted into the AlphaDev menu.
 # 
 # Based on code originally included in "alphaDeveloperMenu.tcl" written by
 # Bernard Desgraupes.
 # 
 # We currently assume that Alphatk in OSX should check out from the CVS like
 # AlphaX. If this is not the case, then the setting of the "updatingOS"
 # variable below needs to be changed accordingly.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #
 # Copyright (c) 2003-2006  Bernard Desgraupes, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc alphaTclCvs.tcl {} {}

namespace eval alphadev::cvs {
    
    global alpha::macos tcl_platform
    
    variable menuName "AlphaTcl CVS"

    # The main cvs server url.
    variable cvsServer {http://www.purl.org/net/Alpha/AlphaTclCVS/}

    # Used when building the "AlphaTcl CVS" menu for the first time.
    variable hooksRegistered 0
    # Module to check out from CVS, and module options
    variable currentCvsModule "Default"
    variable cvsModuleOptions [list Default - \
      Tcl Help Examples Tools Developer - \
      Tcl/Completions Tcl/Menus Tcl/Modes Tcl/Packages \
      Tcl/SystemCode Tcl/UserModifications]
    # Tag to check out to from CVS, and tag options
    variable currentCvsTag "CURRENT"
    variable cvsTagOptions [list \
      "STABLE" "CURRENT" "HEAD"]
    # Used to determine if actions are valid, and if so what platform specific
    # procedure should be used to update from the cvs.  We currently assume
    # that Alphatk in OSX should behave like AlphaX. If this is not the case,
    # then the setting of this variable needs to be changed accordingly.
    variable updatingOS
    
    if {$alpha::macos} {
	set updatingOS "macintosh"
    } else {
	set updatingOS $tcl_platform(platform)
    }
    # Includes items to view cvs changes to the active window, browse the
    # AlphaTcl cvs repository, and update your AlphaTcl library.
    newPref flag alphaTclCvsMenu 0 contextualMenuTcl
    menu::buildProc "alphaTclCvs" {alphadev::cvs::buildMenu "1"}
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× AlphaTcl CVS Menu ×××× #
# 

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::cvs::buildMenu" --
 # 
 # Create the menu of items available, register the 'activateHook'.  When
 # the menu is built for the menubar "AlphaDev" menu, we don't hard-wire
 # anything in here to be dimmed.  When built for the contextual menu, we
 # check to see if the current window is in AlphaTcl.  (The CM version gets
 # built each time the CM is called.)
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::cvs::buildMenu {{forContextualMenu "0"}} {
    
    global global::features alphaDevMenuBindingsmodeVars
    
    variable updatingOS
    variable hooksRegistered
    variable menuName
    
    # If building for the contextual menu, determine now if the menu item
    # "View CVS Changes To Window" is valid.
    if {!$forContextualMenu || [fileIsInAlphaTcl [win::Current]]} {
	set dim1 ""
    } else {
	set dim1 "\("
    }
    # Determine if checking out is available.
    if {[validateCvsCheckout 0]} {
	set dim2 ""
    } else {
        set dim2 "\("
    }
    # Create the list of menu items.
    set menuList [list \
      "${dim1}View CVS Changes To Window" "Browse AlphaTcl CVS Repository" \
      "(-)" \
      "${dim2}AlphaTcl Checkout" "${dim2}AlphaTcl Devel Checkout" \
      "${dim2}Checkout A ModuleÉ" \
      ]
    if {${alpha::macos}} {
        lappend menuList "Get MacCVS Pro Messages" "(-)" "MacCVS Pro Help"
    } else {
	lappend menuList "(-)"
    }
    lappend menuList "AlphaTcl CVS Help"
    # Add key bindings.
    set arrayName "alphaDevMenuBindingsmodeVars"
    set menuList  [alphadev::addMenuBindings $menuList $arrayName]
    # Set the menu proc.
    if {!$alphaDevMenuBindingsmodeVars(activateBindingsInTclModeOnly)} {
	set menuProc {alphadev::cvs::menuProc -m}
    } else {
	set menuProc {alphadev::cvs::menuProc -m -M Tcl}
    }
    # Register the activate, open window hook.
    if {!$hooksRegistered} {
	hook::register activateHook {alphadev::cvs::activateHook}
	if {[lsearch ${global::features} alphaDeveloperMenu] > -1} {
	    hook::register requireOpenWindowsHook \
	      [list -m $menuName "View CVS Changes To Window"] 1
	}
	set hooksRegistered 1
    } 
    # Return the list of items for the menu.
    return [list build $menuList $menuProc]
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::cvs::menuProc" --
 # 
 # Execute the menu items, redirecting as necessary.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::cvs::menuProc {menuName itemName} {
    
    global HOME
    
    variable cvsServer
    variable currentCvsModule
    variable updatingOS
    
    switch -- $itemName {
	"View CVS Changes To Window" {
	    set filename [win::StripCount [win::Current]]
	    if {![file::pathStartsWith $filename $HOME rest]} {
		status::msg "File not part of AlphaTcl"
		return
	    }
	    set rest [string trimleft [file::toUrl $rest] file:///]
	    url::execute ${cvsServer}${rest}
	}
	"Browse AlphaTcl CVS Repository" {
	    url::execute $cvsServer
	}
	"AlphaTcl Checkout" {
	    alphadev::cvs::validateCvsCheckout
	    ${updatingOS}::updateFromCvs alphaTcl
	}
	"AlphaTcl Devel Checkout" {
	    alphadev::cvs::validateCvsCheckout
	    ${updatingOS}::updateFromCvs alphaTclDevel
	}
	"Checkout A Module" {
	    alphadev::cvs::validateCvsCheckout
	    if {[pickCvsModule]} {
		${updatingOS}::updateFromCvs alphaTclDevel $currentCvsModule
	    } else {
	        status::msg "Cancelled."
	    }
	}
	"Get MacCVS Pro Messages" {
	    alphadev::cvs::getMacCvsProMessages
	}
	"MacCVS Pro Help" {
	    urlView "http://www.purl.org/net/alpha/maccvspro"
	}
	"AlphaTcl CVS Help" {
	    alphadev::cvs::helpWindow
	}
    }
    return
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::cvs::getMacCvsProMessages" --
 # 
 # Contributed by Craig Barton Upright based on TclAE scripts provided by
 # Bernard Desgraupes in the AlphaTcl Wiki.
 # 
 # <http://www.purl.org/net/alpha/wikipages/cvs-info>
 # 
 # This version creates a temporary window that the user can then save if
 # desired.  Handy "Setext" style marks are created in the window.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::cvs::getMacCvsProMessages {} {
    
    global alpha::macos
    
    # Preliminaries
    if {!${alpha::macos}} {
	alertnote "This item is only useful in the MacOS."
	return
    } elseif {![app::isRunning Mcvs]} {
        alertnote "The MacCVS Pro application must be running\
	  in order to retrieve information from its Messages window."
	return
    }
    
    # Create the window's title and a simple header.
    set title "MacCVS Pro Messages"
    set txt [mtime [now]]
    append txt "\r[string repeat "-" [string length $txt]]\r\r"
    # Add the name of the current project.
    if {[catch {
	tclAE::build::resultData 'Mcvs' core getd \
	  ---- [tclAE::build::propertyObject pnam \
	  [tclAE::build::indexObject cwin 1]]
    } project]} {
	alertnote "Cancelled -- $project"
	return
    } 
    regexp {[^\.]+} $project project
    append txt "Project: ${project}\r"
    # Get the text of the Messages window.
    if {[catch {
	tclAE::build::resultData 'Mcvs' core getd \
	  ---- [tclAE::build::propertyObject Msgs \
	  [tclAE::build::indexObject docu -1]]
    } messages]} {
	alertnote "Cancelled -- $messages"
	return
    } elseif {![string length $messages]} {
        append txt "\r\r(No messages found.)"
    }
    # Reformat the messages to make them more readable.
    foreach msg [split [string trim $messages] "\r\n"] {
	if {![regexp {^\s} $msg]} {
	    append txt \r
	}
	append txt "[breakIntoLines $msg 77]\r"
    }
    # Add the text to an existing window, or create a new one.
    if {[win::Exists $title]} {
	bringToFront $title
	set w $title
    } else {
	set w [new -n $title -mode "Setx"]
	set txt "${title}\r[string repeat "=" [string length $title]]\r\r${txt}"
    }
    goto -w $w [set p [pos::max -w $w]]
    insertText -w $w "\r${txt}\r\r"
    goto -w $w [pos::nextLineStart -w $w $p]
    return
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::cvs::helpWindow" --
 # 
 # Open a new window with information about this submenu.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::cvs::helpWindow {} {
    
    set title "AlphaTcl CVS Help"
    if {[win::Exists $title]} {
	bringToFront $title
	return
    }

    set txt {
AlphaTcl CVS Help

The "AlphaDev --> AlphaTcl CVS" submenu provides support for accessing the
AlphaTcl CVS server.  An "AlphaTcl Cvs" contextual menu module is also
available for Tcl mode.
	    

		Table Of Contents

"# What is AlphaTcl?"
"# AlphaTcl CVS Menu Items"
"# Additional Checkout Notes"
"#   Macintosh OS"
"#   Windows OS"
"#   Unix OS"

<<floatNamedMarks>>


	  	What is AlphaTcl?


AlphaTcl is the opensource collection of Tcl (Tool Command Language) code
driving the family of Alpha* text editor engines:

	Alpha   (MacOS Classic)
	Alpha8  (MacOS Classic)
	AlphaX  (MacOS X)
	Alphatk (Windows, UNIX, MacOS X)

AlphaTcl is not a text editor.  It is a collection of utilities and
infrastructure code which allows the above text editors to operate, and
which implements a lot of the advanced functionality of those editors.  All
of the above editors implement a visual editing environment (windows, menus,
dialogs, keyboard interaction, etc), and manage an application event loop,
which together with AlphaTcl make a text editor.

Most of functionality of these editors is implemented in its collection of
Tcl extension scripts that create the various modes, menus, and other
features.  All of these scripts use the building blocks provided by the core
commands of the binary applications to create the user interface.  Because
these script files are not embedded in the core application, it is much
easier to change various aspects of this interface, or to create additional
modes, menus, and features.  All of these script files are known
collectively as AlphaTcl, which are maintained in the AlphaTcl CVS.

For more information about AlphaTcl, see this web site:

    <http://www.purl.org/net/Alpha/AlphaTcl>

For more information about the AlphaTcl CVS, see this web site:

    <http://www.purl.org/net/Alpha/WikiPages/cvs-info>

You can browse the AlphaTcl CVS repository here:

    <http://www.purl.org/net/Alpha/AlphaTclCVS/>


	  	AlphaTcl CVS Menu Items

The menu includes the following items:

	View CVS Changes To Window
    
If the current window is part of the AlphaTcl library, this item will open
the "View CVS" web page specific to that window using your local browser.
This page contains all revisions related to that file.

	Browse AlphaTcl CVS Repository

Opens the main "View CVS" web page for the AlphaTcl library using your local
browser.
    
	AlphaTcl Checkout
	AlphaTcl Devel Checkout

Two different items for checking out are available, the differences between
them are platform dependent.  For more information see the section below on
"# Additional Checkout Notes"

	Checkout A ModuleÉ

This presents a dialog <<alphadev::cvs::pickCvsModule>> offering several
different AlphaTcl modules that can be checked out.  By default this module
will use the "AlphaTcl Devel Checkout" method.

	Get MacCVS Pro Messages

If you are using the MacOS, and if the MacCVS Pro application has been
launched, this menu item will open a new window in Alpha containing the
current messages.  This is useful primarily because MacCVS Pro doesn't allow
you to save that window or to copy text from that window into the Clipboard.

	MacCVS Pro Help

(Only available in the MacOS.)

This item opens the home page for the MacCVS Pro application -- the
documentation is a little bit out of date, but it's the best place to first
look for information on how the application works.

	AlphaTcl CVS Help

Opens this window.


	  	Additional Checkout Notes

	  	 	Macintosh OS

In the Macintosh OS (both Classic and OSX), checking out from the CVS
utilizes the MacCVS Pro application that should have been included with this
distribution.  There are two different items in the "AlphaTcl CVS" menu,
named

	AlphaTcl Checkout
	AlphaTcl Devel Checkout

The first will attempt to open the file

	/Tools/AlphaTcl.maccvs

(relative to your Alpha folder) while the second will open

	/Developer/Tools/AlphaTclDevel.maccvs
    
If you have moved these files, the checkout will fail.  Each file will have
its own "Revision" preference in the "Edit --> Session Settings" dialog.
This preference should reflect the cvs tag to which you want to update your
AlphaTcl library.

See this url: <http://www.purl.org/net/alpha/maccvspro> for more information
about the MacCVS Pro application.

	  	 	Windows OS

Sorry, no support is provided (yet) for this platform.

	  	 	Unix OS

Sorry, no support is provided (yet) for this platform.


As always, feedback and code contributions are always welcome, see the
"alphaTclCvs.tcl" file for the current sources.
    }
    
    new -n $title -tabsize 4 -info $txt
    help::markColourAndHyper
    return
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::cvs::activateHook" --
 # 
 # If the AlphaDev menu is active, we check to see if the current window
 # (or the one being brought to the fore) is part of the AlphaTcl library,
 # and if not we dim the "View CVS Changes" menu item.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::cvs::activateHook {name} {
    
    if {![package::active alphaDeveloperMenu]} {return}

    set enable [fileIsInAlphaTcl $name]
    enableMenuItem -m "AlphaTcl CVS" "View CVS Changes To Window" $enable
    return
}

proc alphadev::cvs::fileIsInAlphaTcl {name} {
    
    global PREFS HOME
    
    if {[win::IsFile $name] && ![file::pathStartsWith $name $PREFS] && \
      [file::pathStartsWith $name $HOME]} {
	return 1 
    } else {
	return 0
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× CVS Checkout Support ×××× #
# 

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::cvs::validateCvsCheckout" --
 # 
 # A first check to see if some of the CVS actions can actually be taken.
 # 
 # It is possible that Alphatk in OSX will have a different method than that
 # used for AlphaX, in which case the variable "updatingOS" defined above
 # should be set appropriately in order to call the correct procedure below.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::cvs::validateCvsCheckout {{throwError 1}} {
    
    variable updatingOS
    
    switch -- $updatingOS {
	"macintosh" {
	    set result 1
	}
	"unix" {
	    set result 0
	}
	"windows" {
	    set result 0
	}
	default {
	    # ???
	    set result 0
	}
    }
    if {!$result && $throwError} {
	return [alphadev::cvs::betaMessage]
    } else {
        return $result
    }
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::cvs::betaMessage" --
 # 
 # A handy proc to check if the action can be performed, and if not then we
 # let the user know and abort whatever procedure called us.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::cvs::betaMessage {{itemName ""}} {
    
    if {[string length $itemName]} {
	set msg "'${itemName}' "
    } else {
	set msg "this item "
    }
    status::msg [append msg "is not available on this platform (yet)."]
    error "Cancelled -- $msg"
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::cvs::pickCvsModule" --
 # 
 # Present a list of valid options for the module to be checked out.  If the
 # user cancels the dialog, return "0", otherwise "1".  The module is saved
 # as a namespace variable that can be picked up by any other proc.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::cvs::pickCvsModule {} {
    
    variable currentCvsModule
    variable cvsModuleOptions
    
    set p "Pick a module to check out:"
    if {[catch {
	eval [list prompt $p $currentCvsModule modules:] $cvsModuleOptions
    } currentCvsModule]} {
	set currentCvsModule "Default"
	return 0
    } else {
	return 1
    }
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::cvs::pickCvsTag" --
 # 
 # Present a list of valid options for the CVS tag to be checked out to.  If
 # the user cancels the dialog, return "0", otherwise "1".  The tag is saved
 # as a namespace variable that can be picked up by any other proc.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::cvs::pickCvsTag {} {
    
    variable currentCvsTag
    variable cvsTagOptions
    
    set p "Pick a tag to check out to:"
    if {[catch {
	eval [list prompt $p $currentCvsTag "CVS tags:"] $cvsTagOptions
    } currentCvsTag]} {
	set currentCvsTag "STABLE"
	return 0
    } else {
	return 1
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× CVS Checkout Procedures ×××× #
# 
# Checking out from the CVS is platform/binary specific.  At present we have
# three different methods, based on OS platform (where we are calling OSX
# 'macintosh' for simplicity).  Each platform specific procedure should accept
# two arguments, 'checkoutMethod' and (optionally) 'module'.  At present
# the 'checkoutMethod' will be one of two values:
# 
#   alphaTcl
#   alphaTclDevel
# 
# indicating what type of update is desired by the user.  (In future
# versions we might explicitly query for a specific cvs tag, such as STABLE,
# CURRENT, HEAD, etc., though any of the procs below could obtain this by
# calling [alphadev::cvs::pickCvsTag] if desired.)
# 

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::cvs::macintosh::updateFromCvs" --
 # 
 # Here the 'checkoutMethod' name corresponds exactly to a .cvs filename
 # that is distributed with Alpha8/AlphaX. We rely here on MacCVSPro to
 # take care of everything for us.
 # 
 # -------------------------------------------------------------------------
 ##

namespace eval alphadev::cvs::macintosh {}

proc alphadev::cvs::macintosh::updateFromCvs {checkoutMethod {module ""}} {
    
    global HOME
    
    set fileTail ${checkoutMethod}.maccvs
    switch -- $checkoutMethod {
	"alphaTcl" {
	    set dir "Tools"
	}
	"alphaTclDevel" {
	    set dir [file join Developer Tools]
	}
	default {
	    error "Uknown checkout method -- $checkoutMethod"
	}
    }
    if {![file exists [set f [file join $HOME $dir $fileTail]]]} {
	return [alertnote "Couldn't find file \"${fileTail}\" \
	  \r\rIt should be located in the $dir subfolder of Alpha's folder."]
    } 
    app::launchFore Mcvs
    tclAE::send 'Mcvs' aevt odoc ---- [tclAE::build::alis $f]
    set cmd "tclAE::send 'Mcvs' MCvs cout ---- \
      [list [tclAE::build::indexObject docu -1]]"
    if {$module != "" && $module != "Default"} {
	append cmd " modl [list [tclAE::build::TEXT "$module"]]"
    } 
    eval $cmd
    return
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::cvs::unix::updateFromCvs" --
 # 
 # Currently waiting for a proper implementation!
 # 
 # -------------------------------------------------------------------------
 ##

namespace eval alphadev::cvs::unix {}

proc alphadev::cvs::unix::updateFromCvs {args} {
    alphadev::cvs::betaMessage "Update From Cvs"
    return
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::cvs::windows::updateFromCvs" --
 # 
 # Currently waiting for a proper implementation!
 # 
 # -------------------------------------------------------------------------
 ##

namespace eval alphadev::cvs::windows {}

proc alphadev::cvs::windows::updateFromCvs {args} {
    alphadev::cvs::betaMessage "Update From Cvs"
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  vers#  reason
# -------- --- ------ -----------
# 06/28/03 cbu 0.1    First version.
# 07/01/03 cbu 0.2    Renamed some menu items.
#                     Removed "MacCVS Pro Home Page" menu item.
#                     Modified 'preinit' script to reflect changes in how
#                       the AlphaDev menu recognizes extra submenus.
# 07/03/03 cbu 0.3    Minor formatting changes.
# 07/11/03 cbu 0.4    No longer a stand-alone package, incorporated into
#                       the new "AlphaDev Menu" folder.
# 01/22/04 cbu 0.5    Added [alphadev::cvs::getMacCvsProMessages] based on
#                       proc provided by Bernard in the AlphaTcl Wiki.
#                     Added the "MacCVS Pro Help" menu item.
#                     All items called using full namespaces.
# 

# ===========================================================================
# 
# .