## -*-Tcl-*-
 # -------------------------------------------------------------------------
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "BackCompatibility.tcl"
 #                                         created: 04/04/2001 {07:13:29 pm}
 #                                     last update: 03/21/2006 {04:09:45 PM}
 #                                
 # You should avoid calling any of these procs: They are slower, and will be
 # removed at some point in the future.
 # 
 # Some of these may currently be called from Alpha's core, but that is only
 # temporary.  The contents of this file changes regularly to reflect
 # procedures which are kept around to ensure nothing breaks; once we are
 # sure they are no longer used, they are removed.
 # 
 # All procs here are just wrappers around other procs.  They can call
 # [warningForObsProc] to inform the user that obsolete code is in use.
 # 
 # -------------------------------------------------------------------------
 ##

proc BackCompatibility.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "warningForObsProc" --  <type>
 # 
 # If "warningForObsoleteProcedures" is "0" then we simply return without
 # doing anything, and hope that all works well for the user.
 # 
 # If "warningForObsoleteProcedures" is "1" then we inform the user that some
 # obsolete procedure (most likely defined below) is being called.  We then
 # present a dialog with options, which include throwing an error so that the
 # exact code path can be determined.  If "type" is the name of a procedure 
 # then we can optionally open the file that defines it.
 # 
 # The "warningForObsoleteProcedures" preference can be changed via the
 # AlphaDev Menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc warningForObsProc {{type "obsolete"}} {
    
    global warningForObsoleteProcedures obsoleteListSoFar auto_index
    
    if {![info exists warningForObsoleteProcedures] \
      || !$warningForObsoleteProcedures} {
        return
    } elseif {[catch {info level -1} callingCode]} {
	# If we call this proc at the global level, "level -1" doesn't exist.
        return "Don't call \[warningForObsProc\] at the global level!"
    }
    # Return if we've already warned the user about this one and we've been
    # instructed to shut up already.
    if {[info exists obsoleteListSoFar] \
      && ([lsearch -exact $obsoleteListSoFar $callingCode] != -1)} {
        return
    }
    if {([set invoker [info level 1]] eq $callingCode)} {
	set invoker "Some code"
    } else {
        set invoker "\[${invoker}\]"
    }
    if {([string length $callingCode] < 60)} {
	set _callingCode $callingCode
    } else {
        set _callingCode "[string range $callingCode 0 60]É"
    }
    if {($type eq "obsolete") || ($type ne "")} {
	set depend "deprecated procedure"
    } else {
	set depend "unsupported procedure (on this platform)"
    }
    set options [list \
      "Execute the procedure anyway" \
      "Execute and don't warn me again" \
      "Throw an error to trace the code path" \
      ]
    regsub -- {^:+} $type "" newProcName
    if {[info exists auto_index(::$newProcName)] \
      || [llength [info procs ::$newProcName]]} {
        lappend options "Copy the new proc name to the Clipboard"
    } else {
        set newProcName ""
    }
    if {($newProcName ne "") \
      && [info exists auto_index(::$newProcName)] \
      && [file exists [lindex $auto_index(::$newProcName) 1]]} {
        lappend options "Open the file with the new procedure"
    }
    set dialogScript [list dialog::make \
      -title "Warning For Obsolete Procedure" \
      -width 450 \
      -ok "Continue" \
      -okhelptag "Click here to execute the selected option" \
      -cancelhelptag "Click here to cancel the original operation" \
      -addbuttons [list "Help" \
      "Click here to open a window with more information" \
      "obsoleteProcHelpWindow \{$callingCode\} \{$newProcName\} ; \
      set retVal cancel ; set retCode 1"]
      ]
    set dialogPane [list "" \
      [list "text" "$invoker is trying to execute an obsolete procedure:"] \
      [list [list "smallval" "static"] " " $_callingCode] \
      [list "text" "This is an error and should be corrected.  Please try to\
      remove the dependence on the $depend, or inform the AlphaTcl-developers\
      mailing list.\r"] \
      [list "text" "How would you like to proceed?\r"] \
      [list [list "menu" $options] "Options:" [lindex $options 0]] \
      ]
    if {($newProcName ne "")} {
        set dialogPane [linsert $dialogPane end-2 \
	  [list "divider" "divider"] \
	  [list "text" "The new procedure that should be used is:\r"] \
	  [list [list "smallval" "static"] "  " $newProcName] \
	  [list "divider" "divider"] \
	  ]
    }
    lappend dialogScript $dialogPane
    if {[catch {eval $dialogScript} result]} {
        return -code error "cancel"
    }
    switch -- [lindex $result end] {
        "Execute and don't warn me again" {
	    lappend obsoleteListSoFar $callingCode
        }
        "Throw an error to trace the code path" {
	    return -code error "Obsolete procedure: $what"
        }
        "Open the file with the new procedure" {
	    edit -c -r [lindex $auto_index(::$newProcName) 1]
	    catch {Tcl::DblClickHelper $newProcName}
	    return -code error "cancel"
        }
        "Copy the new proc name to the Clipboard" {
	    putScrap $newProcName
	    alertnote "\"$newProcName\" has been inserted into the Clipboard."
        }
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "obsoleteProcHelpWindow" --
 # 
 # Called by the [warningForObsProc] "Help" button, create a new window with
 # more information about the obsolete code and steps to take in order to
 # remove this dependency.
 # 
 # --------------------------------------------------------------------------
 ##

proc obsoleteProcHelpWindow {callingCode newProcName} {
    
    global auto_index alpha::application alpha::macos errorInfo
    
    set codePath [list]
    set level -4
    while {![catch {info level $level} levelInfo]} {
	lappend codePath $levelInfo
	incr level -1
	if {($level < -1000)} {
	    # Something is going wrong here.
	    break
	}
    }
    set title "* Obsolete Procedure Help *"
    
    set windowText {
Obsolete Procedure Help

You have encountered some AlphaTcl operation which relies on an obsolete
procedure.  Unfortunately, you will encounter this "Warning" routine every
time that you call this operation.  (You can instruct ÇALPHAÈ to stop warning
you about this operation by selecting the appropriate option in the warning
dialog, but it will appear the next time that you launch ÇALPHAÈ and repeat
the operation which led you here.)


	  	Obsolete Code

At some point this code path should be updated so that you (and other users)
won't run into this problem ever again.  The specific code which caused this
error is
ÇCALLINGCODEÈ
ÇCODEPATHINFOÈ

Unless the code in question is part of your personal code library this
problem should be addressed in the standard distribution, i.e. it should be
reported to the AlphaTcl developers.  You can <<reportABug>> by selecting the
"Help > Report A Bug" command, and include the code blocks listed above.

Or you could send a note directly to the AlphaTcl Developers listserv; see
<http://www.purl.org/net/alpha/mail> for subscription information.


	  	Debugging AlphaTcl

You can highlight any AlphaTcl procedure in the above block of text and
ÇCOMMANDÈ-Double-Click on it to open the file containing that particular
procedures's definition.

Most likely the obsolete proc which actually caused this warning is defined
in the "BackCompatibility.tcl" file, in which case it might be annotated so
that you can figure out why this code has been deprecated.
ÇNEWPROCNAMEÈ

See the "Debugging Help" file for more information.


	  	Applying Patches

If you can figure out what how to fix this by constructing a new procedure
definition, open the "Support Folders Help" file for more information about
how you can modify the original AlphaTcl source file so that you won't run
into this problem again.

Sorry that you're running into trouble, hopefully this problem can be
corrected for the next release.

}
    # Now present the calling code.
    set newCallingCode ""
    foreach line [split [string trim $callingCode] "\r\n"] {
	foreach brokenLine [split [breakIntoLines $line 77] "\r\n"] {
	    append newCallingCode "\r\t" $brokenLine
	}
    }
    set codePathInfo ""
    if {[llength $codePath]} {
	append codePathInfo "\rCode Path:\r"
	foreach pathItem $codePath {
	    append codePathInfo "\r\t" $pathItem
	}
    }
    set newProcInfo ""
    if {($newProcName ne "")} {
	append newProcInfo "\r" [breakIntoLines "The proc: $newProcName\
	  is the recommended replacement that should be used in the\
	  AlphaTcl code." 77]
    }
    # foreach item [list "newCallingCode" "codePathInfo" "newProcInfo"] {
    #     set $item [string trim [set $item]]
    # } 
    regsub -all {ÇCALLINGCODEÈ}  $windowText $newCallingCode     windowText
    regsub -all {ÇCODEPATHINFOÈ} $windowText $codePathInfo       windowText
    regsub -all {ÇNEWPROCNAMEÈ}  $windowText $newProcInfo        windowText
    regsub -all {ÇALPHAÈ}        $windowText $alpha::application windowText
    if {($alpha::macos)} {
        regsub -all {ÇCOMMANDÈ}  $windowText {Command} windowText
    } else {
        regsub -all {ÇCOMMANDÈ}  $windowText {Alt} windowText
    }
    set w [new -tabsize 4 -dirty 0 -n $title -text $windowText]
    goto -w $w [minPos -w $w]
    winReadOnly $w
    help::markColourAndHyper -w $w
    refresh -w $w
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "select" --
 # 
 # This command was renamed [selectText] in AlphaX 8.1.?  because of a
 # potential conflict with the Tclx command with the same name.
 # 
 # See bug# 1979.
 # 
 # The [warningForObsProc] line will inform users when third-party packages
 # that have not yet been updated call [select].  Any AlphaTcl package that
 # requires the Tclx package is encouraged to also immediately call
 # 
 #     auto_load "::select"
 #     
 # to restore this "BackCompatibility.tcl" version unless the Tclx [select]
 # is really required and used.
 # 
 # (Once all instances of [select] have been changed to [selectText] in all
 # AlphaTcl standard distribution files, this line will be uncommented.)
 # 
 # --------------------------------------------------------------------------
 ##

proc select {args} {
    warningForObsProc "selectText"
    return [eval selectText $args]
}

namespace eval status {}

## 
 # --------------------------------------------------------------------------
 # 
 # "status::errorMsg" --
 # 
 # This procedure was implemented to allow error message to be displayed to
 # the user in Alpha7, but in Alpha8/X/tk any "cancel" error message is
 # automatically presented in the status bar.  Calling code should now just
 # use [error "cancel"] or [error "Cancelled -- <something informative]".
 # 
 # --------------------------------------------------------------------------
 ##

proc status::errorMsg {args} {
    warningForObsProc
    set msg [lindex $args 0]
    if {![string length $msg]} {
	set msg "cancel"
    } elseif {![string match -nocase "*cancel*" $msg]} {
	set msg "Cancelled -- $msg"
    }
    eval error [lreplace $args 0 0 $msg]
}

proc modeALike {{m ""}} {
    warningForObsProc
    global mode completionsLike
    if {$m == ""} {set m $mode}
    if {[info exists completionsLike($m)]} {
	set m $completionsLike($m)
    }
    return $m
}

proc modes {args} {
    warningForObsProc "mode::listAll"
    return [mode::listAll]
}

namespace eval mode {}

proc mode::proc {name args} {
    warningForObsProc
    global ::mode
    namespace eval ::$mode "$name $args"
}

proc mode::getProc {name {m ""}} {
    warningForObsProc
    if {$m eq ""} {
	set m $::mode
    }
    namespace eval ::$m "namespace which $name"
}

proc splitWindow {args} {
    warningForObsProc
    uplevel 1 toggleSplitWindow $args
}

namespace eval flag {}

proc flag::addType {type} {
    warningForObsProc "::prefs::addType"
    ::prefs::addType $type
}

proc flag::isIndex {v} {
    warningForObsProc
    return [regexp -- {index$} [lindex $::prefs::list($v) 0]]
}

proc flag::options {v} {
    warningForObsProc "::prefs::options"
    ::prefs::options $v
}

proc shell {} {
    warningForObsProc "tclShell"
    tclShell
}

namespace eval file {}

proc file::move {from to {overwrite 0}} {
    warningForObsProc
    if {$overwrite} {
	file rename -force $from $to
    } else {
        file rename $from $to
    }
}

# eventHandler has been removed in Alpha 8, but needs to exist for
# legacy code. Patch it through to tclAE::installEventHander.

namespace eval aeom {}

proc ::aeom::_eventHandler {theAppleEvent theReplyAE} {
    global aeom::eventHandlers
    
    set eventClass [tclAE::getAttributeData $theAppleEvent evcl]
    set eventID [tclAE::getAttributeData $theAppleEvent evid]
    
    if {[catch {set handler [set aeom::eventHandlers(${eventClass}${eventID})]}]} {
	error::throwOSErr -1717
    }
    
    set gizmo [tclAE::print $theAppleEvent]
    # tclAE::print seems to swallow the '\' between the class and event
    set gizmo "[string range $gizmo 0 3]\\[string range $gizmo 4 end]"
    set result [eval $handler $gizmo]
    
    tclAE::putKeyData $theReplyAE ---- TEXT $result
}

proc ::eventHandler {theAEEventClass theAEEventID handler} {
    warningForObsProc
    global aeom::eventHandlers
    
    set aeom::eventHandlers(${theAEEventClass}${theAEEventID}) $handler
    
    # All events get routed through here
    tclAE::installEventHandler $theAEEventClass $theAEEventID aeom::_eventHandler
}

# AEBuild has been removed in Alpha 8, but needs to exist for
# legacy code. Patch it through to tclAE::send.
proc ::AEBuild {args} {
    warningForObsProc
    # AEBuild expects an AEGizmos AEPrint string
    eval tclAE::send -p $args
}
	
# dosc has been removed in Alpha 8, but needs to exist for
# legacy code. Patch it through to tclAE::send.
proc ::dosc {args} {
    warningForObsProc
    set opts(-k) "'misc'"
    set opts(-e) "'dosc'"
    
    set opts(-t) 0
    set opts(-r) 0
    set opts(-q) 0
    
    getOpts {c n k e s f t}
    
    # set reply form
    if {$opts(-q)} {
	# queue
	set cmd {tclAE::send -q}
    } elseif {!$opts(-r)} {
	# directly (-r is backwards)
	set cmd {tclAE::build::resultData}
	
	if {$opts(-t) > 0} {
	    # set timeout
	    lappend cmd -t $opts(-t)
	}
    } else {
	set cmd {tclAE::send}
    }
    
    # set target
    if {[info exists opts(-c)]} {
	# by creator
	lappend cmd $opts(-c)
    } elseif {[info exists opts(-n)]} {
	# by name
	lappend cmd $opts(-n)
    } else {
	# prompt user
	set target [tclAE::PPCBrowser]
    }
    
    regexp {^'([^']*)'$} $opts(-k) blah class
    lappend cmd $class
    
    regexp {^'([^']*)'$} $opts(-e) blah event
    lappend cmd $event
    
    if {[info exists opts(-s)]} {
	lappend cmd ---- [tclAE::build::TEXT $opts(-s)]
    } elseif {[info exists opts(-f)]} {
	lappend cmd ---- [tclAE::build::alis $opts(-f)]
    } else {
	error "You must supply either a script or a file path"
    }
    eval $cmd
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× From "dialogs.tcl" ×××× #
# 

proc helperApps {args} {
    warningForObsProc "prefs::dialogs::helperApps"
    return [eval prefs::dialogs::helperApps $args]
}

proc suffixMappings {args} {
    warningForObsProc "prefs::dialogs::fileMappings"
    return [eval prefs::dialogs::fileMappings $args]
}

proc trans {str} {
    warningForObsProc "prefs::dialogs::_translateText"
    return [eval prefs::dialogs::_translateText $args]
}

proc setExternalHelpers {args} {
    warningForObsProc "prefs::dialogs::externalHelpers"
    return [eval prefs::dialogs::externalHelpers $args]
}

namespace eval dialog {}

proc dialog::chooseOption {args} {
    warningForObsProc "prefs::dialogs::chooseOption"
    return [eval prefs::dialogs::chooseOption $args]
}

proc dialog::fileMappings {args} {
    warningForObsProc "prefs::dialogs::fileMappings"
    return [eval prefs::dialogs::fileMappings $args]
}

proc dialog::preferences {args} {
    warningForObsProc "prefs::dialogs::menuProc"
    return [eval prefs::dialogs::menuProc $args]
}

proc dialog::arrangeMenus {args} {
    warningForObsProc "prefs::dialogs::arrangeMenus"
    return [eval prefs::dialogs::arrangeMenus $args]
}

proc dialog::globalMenusFeatures {args} {
    warningForObsProc "prefs::dialogs::globalMenusFeatures"
    return [eval prefs::dialogs::globalMenusFeatures $args]
}

proc dialog::modeMenusFeatures {args} {
    warningForObsProc "prefs::dialogs::modeMenusFeatures"
    return [eval prefs::dialogs::modeMenusFeatures $args]
}

proc dialog::packagesHelp {args} {
    warningForObsProc "prefs::dialogs::packagesHelp"
    return [eval prefs::dialogs::packagesHelp $args]
}

proc dialog::pickMenusAndFeatures {formode {mfb 0}} {
    switch -- $mfb {
	"1" {set types "features"}
	"2" {set types "menus"}
	default {
	    error "Must supply 1 or 2 as the argument."
	}
    }
    if {($formode eq "") || ($formode eq "global")} {
	return [prefs::dialogs::globalMenusFeatures $types]
    }
}

proc dialog::describeMenusAndFeatures {args} {
    warningForObsProc
    error "Cancelled -- this procedure is no longer supported."
}

proc dialog::_simpleDescribeMenusAndFeatures {args} {
    warningForObsProc "prefs::dialogs::describeMenusFeatures"
    return [eval prefs::dialogs::describeMenusFeatures $args]
}

proc dialog::modifyModeFlags {args} {
    warningForObsProc "prefs::dialogs::modePrefs"
    return [eval prefs::dialogs::modePrefs $args]
}

proc dialog::pkg_options {args} {
    warningForObsProc "prefs::dialogs::packagePrefs"
    return [eval prefs::dialogs::packagePrefs $args]
}

proc dialog::edit_array {args} {
    warningForObsProc "prefs::dialogs::editArrayVar"
    return [eval prefs::dialogs::editArrayVar $args]
}

proc dialog::editOneOfMany {args} {
    warningForObsProc "prefs::dialogs::editOneOfManyVars"
    return [eval prefs::dialogs::editOneOfManyVars $args]
}

proc dialog::setDefaultGeometry {args} {
    warningForObsProc "prefs::dialogs::setVariables"
    return [eval prefs::dialogs::setVariables $args]
}

proc dialog::makePreferencePages {args} {
    warningForObsProc "prefs::dialogs::makePrefsDialog"
    return [eval prefs::dialogs::makePrefsDialog $args]
}

proc dialog::makePage {args} {
    return [eval prefs::dialogs::_makePrefsDialog [lreplace $args 1 1]]
}

proc dialog::standard_help {args} {
    warningForObsProc
    return [eval prefs::dialogs::_prefsHelp $args]
}

proc dialog::prefs_search {args} {
    warningForObsProc "prefs::dialogs::_prefsSearch"
    return [eval prefs::dialogs::_prefsSearch $args]
}

# Because these will be called in iterations, don't warn each time.  Anything
# calling these will call other obsolete procedures as well.
proc dialog::_sortPrefs {args} {
    return [eval prefs::dialogs::_sortPrefsList $args]
}

proc dialog::_arrGet {args} {
    return [eval prefs::dialogs::_getPrefValue "array" $args]
}

proc dialog::_pkgGet {args} {
    return [eval prefs::dialogs::_getPrefValue "package" $args]
}

proc dialog::_standardGet {args} {
    return [eval prefs::dialogs::_getPrefValue "standard" $args]
}

proc dialog::_arrSet {args} {
    return [eval prefs::dialogs::_setPrefValue "array" $args]
}

proc dialog::_pkgSet {args} {
    return [eval prefs::dialogs::_setPrefValue "package" $args]
}

proc dialog::_standardSet {args} {
    return [eval prefs::dialogs::_setPrefValue "standard" $args]
}

namespace eval global {}

proc global::allPrefs {args} {
    warningForObsProc "prefs::dialogs::globalPrefs"
    return [eval prefs::dialogs::globalPrefs $args]
}

proc global::allPackages {} {
    warningForObsProc "prefs::dialogs::packagePrefs"
    return [eval prefs::dialogs::packagePrefs "allPackages"]
}

proc global::menusAndFeatures {{mfb 0}} {
    warningForObsProc
    return [dialog::pickMenusAndFeatures global $mfb]
}

proc global::menus {} {
    warningForObsProc "prefs::dialogs::globalMenusFeatures"
    return [prefs::dialogs::globalMenusFeatures "menus"]
}

proc global::features {} {
    warningForObsProc "prefs::dialogs::globalMenusFeatures"
    return [prefs::dialogs::globalMenusFeatures "features"]
}

namespace eval mode {}

proc mode::menuProc {args} {
    warningForObsProc "prefs::dialogs::menuProc"
    return [eval prefs::dialogs::menuProc $args]
}

# ===========================================================================
# 
# .