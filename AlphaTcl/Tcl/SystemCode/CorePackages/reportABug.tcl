## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "reportABug.tcl"
 #                                          created: 01/11/2001 {12:37:11 AM}
 #                                      last update: 05/17/2006 {03:10:15 PM}
 # Description:
 # 
 # Provides a useful interface to Alpha Bugzilla from within Alpha, allowing
 # the user to report a bug, search the database, create summary bug lists ...
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #      
 # Includes contributions from Craig Barton Upright, Jon Guyer
 # 
 # Copyright (c) 2001-2006 Vince Darley, Craig Barton Upright, Jon Guyer
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ===========================================================================
 ##

# Feature declaration.  This is registered as an alpha::library, which
# is an 'auto-loading' extension with a script that will be evaluated
# when Alpha is first launched.  The menu build proc will then be used
# if/when the AlphaDev menu is built.
alpha::library reportABug 1.7.4 {
    # This is how we register the "Alpha Bugzilla" menu build proc without
    # having a formal init script.  This is used by the AlphaDev menu, as
    # well as [bugzilla::floatBugzillaMenu] below.
    menu::buildProc "Alpha Bugzilla" {bugzilla::buildMenu}
    # Register this so that previous crashes can be reported.
    hook::register "startupHook" {bugzilla::checkPriorCrash}
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Provides support for interacting with Alpha-Bugzilla, the on-line
    database of reports for the occasional bug discovered in Alpha8/X/tk and
    their supporting AlphaTcl library files
} help {
    file "Alpha-Bugzilla Help"
}

proc reportABug.tcl {} {}

##
 # --------------------------------------------------------------------------
 # 
 # "reportABug"  --
 # "reportACrash"  --
 # "makeASuggestion"  --
 # "floatBugzillaMenu"  --
 # 
 # These four procedures in the global namespace are the only ones that
 # should be called by outside code -- all of the others should be considered
 # "private" and are subject to change.
 # 
 # --------------------------------------------------------------------------
 ##

proc reportABug {} {
    bugzilla::reportABug
    return
}

proc reportACrash {} {
    bugzilla::reportACrash
    return
}

proc makeASuggestion {} {
    bugzilla::makeASuggestion
    return
}

proc floatBugzillaMenu {} {
    bugzilla::floatBugzillaMenu
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Preferences ×××× #
# 
# We create some preferences in the "bugzillamodeVars" array to make it
# easier for the user to adjust them if necessary, and to simplify the
# setting and storage of them in the code below.
# 

# Turn this preference on if you have already created an account with
# Alpha-Bugzilla.  This will bypass the reminder to register.
newPref flag "registeredBugzillaAccount" 0 bugzilla {bugzilla::rebuildMenu}
# Turn this preference on to submit bugs internally.  Otherwise, the
# information in the Report Window will be sent to an "Enter Bug" web page at
# the Alpha-Bugzilla web site.
newPref flag "submitBugInternally" 1 bugzilla

# The account name registered with Alpha-Bugzilla.
newPref var "accountName" "Enter a valid e-mail" bugzilla
# The password associated with the Alpha-Bugzilla account name.
newPref var "accountPassword" "" bugzilla

##
 # --------------------------------------------------------------------------
 # 
 # "namespace eval bugzilla"  --
 # 
 # The whole "Report A Bug" routine is heavily dependent on a bunch of
 # variables that correspond to fields and values in Alpha-Bugzilla.  This is
 # also where we define defaults, and some items that make it easier for us
 # to figure out what to do in various dialogs.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval bugzilla {
    
    variable AlphaApp $::alpha::application
    variable crashLog \
      [file join ~ Library Logs CrashReporter ${::ALPHA}.crash.log]
    variable dialogTitle "Bug Reporter"
    
    variable advancedHelpTag "Advanced dialogs are not necessary to create\
      the report, but allow you to add more information.  Fewer options means\
      that you'll finish this process slightly faster."
    variable backError "goBackOneStep"
    variable backButton [list "Go Back" \
      "Click here to go back to the previous step." \
      "set retVal $backError ; set retCode 1"]
    variable continueHelpTag "Click here to continue creating the report."
    variable postponeHelpTag "Click here to postpone the report creation."
    
    # Submitting a report to Alpha-Bugzilla might require reqistration.
    variable requireRegistration
    if {![info exists requireRegistration]} {
	# Boolean -- used by [bugzilla::checkRegistration] to determine what
	# we need to tell the user about registration requirements.
	set requireRegistration 0
    }
    
    # Required dialog variables.
    if {![info exists ::dialog::simple_type(var10)]} {
	set ::dialog::simple_type(var10) \
	  "dialog::makeEditItem res script -20 \$right y \$name \$val 10"
    }
    if {![info exists ::dialog::simple_type(var5)]} {
	set ::dialog::simple_type(var5) \
	  "dialog::makeEditItem res script -20 \$right y \$name \$val 5"
    }
    if {![info exists ::dialog::simple_type(emptyVar)]} {
	set ::dialog::simple_type(emptyVar) \
	  "dialog::makeEditItem res script -50 \$right y \$name \$val 1"
    }
    
    # ×××× Default Field Values ×××× #
    
    # Set some report fields.  Note that these are never unset, in case the
    # user cancels midway and then starts over.
    variable ReportInfo
    variable ReportOptions
    
    set reportFields [list product component version reproducible advanced \
      lastBuild alwaysOnPkgs autoLoadPkgs globalFeatures globalMenus ssFiles \
      originalMode modePackages packageInfoSet \
      crashInfo short_desc details fix suggestion rfeFix \
      action specificAction lastSelectedProc tracingProc lastBugNumber \
      assigned_to cc keywords groupset ]
    
    # Actions that might cause the bug.
    set ReportOptions(actions) [list \
      "Key-Combination" \
      "Menu Selection" \
      "Other" \
      "Specific Procedure" \
      ]
    
    # Some of these default values are set below as we create the list
    # of possible options.
    foreach reportField $reportFields {
	if {![info exists ReportInfo($reportField)]} {
	    set value ""
	    switch -- $reportField {
		"action"        {set value [lindex $ReportOptions(actions) 1]}
		"advanced"      {set value [package::active alphaDeveloperMenu]}
		"alwaysOnPkgs"  {
		    append value "Always-on Feature/Menus :" \r\r \
		      [breakIntoLines \
		      [alpha::listAlphaTclPackages "always-on"] 77 2]
		}
		"autoLoadPkgs"  {
		    append value "Auto-loading Features :" \r\r \
		      [breakIntoLines \
		      [alpha::listAlphaTclPackages "auto-loading"] 77 2]
		}
		"lastBuild"     {
		    set value "  AlphaTcl package indices last rebuilt: "
		    set dir   [file join $::PREFS Cache index]
		    set files [glob -nocomplain -dir $dir -- "help"]
		    if {[llength $files]} {
			append value [lindex [clock format \
			  [file mtime [lindex $files 0]] \
			  -format [list "%d %b %Y \{%I:%M:%S %p (%Z)\}"] \
			  -gmt 1] 0]
		    } else {
			append value "(could not be determined.)"
		    }
		    unset dir files
		}
		"packageInfoSet" -
		"reproducible"  {set value "0"}
		"component"     {set value "Other"}
		"product"       {set value "AlphaTcl"}
		"version"       {set value $::alpha::tclversion}
		default         {set value ""}
	    }
	    set ReportInfo($reportField) $value
	}
    }
    
    # ×××× Bugzilla Fields ×××× #
    
    # The following fields are the only ones allowed by bugzilla as of this
    # writing, lifted from the email generated by sending an empty message to
    # <alpha-bugzilla+help@ics.mq.edu.au>.
    
    variable BugzillaFields [list product component version short_desc \
      bug_severity priority rep_platform op_sys \
      assigned_to cc keywords groupset bit-512]
    
    variable RequiredFields [list product component version short_desc ]
    
    variable FieldOptions
    variable OptionalFields [list]
    variable HiddenFields [list "priority" "groupset" "bit-512"]
    
    foreach bugzillaField $BugzillaFields {
	if {![info exists FieldOptions($bugzillaField)]} {
	    set FieldOptions($bugzillaField) [list]
	}
	if {![lcontains RequiredFields $bugzillaField]} {
	    lappend OptionalFields $bugzillaField
	}
    }
    foreach bugzillaField $HiddenFields {
	set idx [lsearch $OptionalFields $bugzillaField]
	set OptionalFields [lreplace $OptionalFields $idx $idx]
    }
    
    # If an incorrect field value is sent with a bug report, the user will
    # receive a reply from bugzilla suggesting a list of possible correct
    # values, which certainly won't lead to many new users using this item.
    # 
    # The goal here, then, is to make sure that the choices are at least
    # valid, even if not completely up to date.  Of course, if the user
    # upgrades, ideally this file will have already been updated to include
    # the new allowed values.  Whenever the bugzilla fields are changed,
    # then, this file should be updated as well.
    
    # We don't include the alternative Alpha* product because we have no
    # access to its correct version number and the report submission will
    # fail.  Use Alphatk to report bugs with Alphatk, and Alpha for Alpha!
    if {($::alpha::platform eq "alpha")} {
	variable Products [list Alpha AlphaTcl - ]
    } else {
	variable Products [list AlphaTk AlphaTcl - ]
    }
    lappend Products Alpha-Bugzilla {Online Tools} TclAE
    
    # ×××× Product Components ×××× #
    variable Components
    variable DefaultComponent
    variable DefaultVersion
    
    set Components(Alpha)               [list Core \
      Dialogs Displays "File I/O"  Floats "Key Bindings" \
      Menus Regexps Search "Status Bar" "Text Rendering"]
    set Components(AlphaTk)             [list AlphatkCore \
      Dialogs Displays "File I/O"  Floats "Key Bindings" \
      Menus Regexps Search "Status Bar" "Text Rendering"]
    set Components(Alpha-Bugzilla)      [list cgi html test]
    set Components(AlphaTcl)            [list BibTeX C Dialogs Diff \
      Documentation Electrics FTP Filesets Frontier  {HTML & CSS} \
      JavaScript {Key Bindings} LaTeX Perl Search SystemCode Tcl WWW \
      Xserv - Other]
    set "Components(Online Tools)"      [list CVS Wiki AIDA]
    set Components(TclAE)               [list AlphaTcl .shlb]
    
    set DefaultComponent(Alpha)                 "Core"
    set DefaultComponent(Alpha-Bugzilla)        "html"
    set DefaultComponent(AlphaTcl)              "SystemCode"
    set DefaultComponent(AlphaTk)               "AlphatkCore"
    set "DefaultComponent(Online Tools)"        "CVS"
    set DefaultComponent(TclAE)                 ".shlb"
    
    # Make sure that these are proper lists.
    foreach product [array names Components] {
	set Components($product) [join [split $Components($product)]]
    }
    
    # ×××× Product Versions ×××× #
    variable Versions
    
    # Remove any "D5" e.g. designation from beta version numbers.  We only 
    # retain the first letter designation, i.e "8.0b17d1" becomes "8.0b17"
    regsub -- {([a-z]+[0-9]+)\-?([a-z]+[0-9]+)$} \
      $::alpha::version "\\1" Versions(Alpha)
    
    set Versions(AlphaTk) $Versions(Alpha)
    set Versions(Alpha-Bugzilla) {
	2.9
	2.9.1
	2.9.2
	2.9.3
	2.9.4
	2.11
	2.11.1
	2.11.2
	2.18
	2.18.1
	2.18.2
	2.18.3
	2.18.4
    }
    set Versions(AlphaTcl) [alpha::package versions AlphaTcl]
    set Versions(AlphaTk)  [alpha::package versions Alpha]
    set "Versions(Online Tools)" [list N/A]
    set Versions(TclAE) {
	2.0b1
	2.0b2
	2.0b3
	2.0b4
	2.0b5
	2.0b6
	2.0b7
	2.0b8
	2.0b9
	2.0b10
	2.0b11
	2.0b12
	2.0b13
	2.0b14
	2.0b15
    }
    
    # Make sure that these are proper lists.
    foreach product [array names Versions] {
	set Versions($product) [join [split $Versions($product)]]
    }
    
    set DefaultVersion(Alpha)           $Versions(Alpha)
    set DefaultVersion(AlphaTk)         $Versions(Alpha)
    set DefaultVersion(Alpha-Bugzilla)  [lindex $Versions(Alpha-Bugzilla) end]
    set DefaultVersion(AlphaTcl)        [alpha::package versions AlphaTcl]
    set "DefaultVersion(Online Tools)"  "N/A"
    if {[info exists ::tclAE_version]} {
	set DefaultVersion(TclAE)       $::tclAE_version
    } else {
	# Package might have thrown an error when loading.
	set DefaultVersion(TclAE)       2.0
    }
    # Ensure that defaults are included in each list.
    foreach product [array names DefaultVersion] {
	lappend Versions($product) $DefaultVersion($product)
	set Versions($product) [lsort -dictionary -unique $Versions($product)]
    }
    
    # ×××× Field Options ×××× #
    
    # More field options.  Set default values here as well.  Note that we
    # never clear old values, in case the user cancelled and is trying
    # again.
    
    set FieldOptions(rep_platform) {
	All
	"Macintosh PowerPC"
	"Macintosh Carbon"
	"Macintosh 68k"
	Unix
	Windows
	Other
    }
    set ReportInfo(rep_platform) "All"
    
    set FieldOptions(op_sys) {
	"All"
	"Mac System 7"
	"Mac System 7.5.5"
	"Mac System 7.6.1"
	"Mac System 8"
	"Mac System 8.1"
	"Mac System 8.5"
	"Mac System 8.6"
	"Mac System 9"
	"Mac System 9.0.4"
	"Mac System 9.1"
	"Mac System 9.2"
	"Mac System 9.2.1"
	"Mac System 9.2.2"
	"Mac OS X"
	"Mac OS X 10.0"
	"Mac OS X 10.1"
	"Mac OS X 10.1.2"
	"Mac OS X 10.1.3"
	"Mac OS X 10.1.4"
	"Mac OS X 10.1.5"
	"Mac OS X 10.2"
	"Mac OS X 10.2.1"
	"Mac OS X 10.2.2"
	"Mac OS X 10.2.3"
	"Mac OS X 10.2.4"
	"Mac OS X 10.2.5"
	"Mac OS X 10.2.6"
	"Mac OS X 10.2.7"
	"Mac OS X 10.2.8"
	"Mac OS X 10.3"
	"Mac OS X 10.3.1"
	"Mac OS X 10.3.2"
	"Mac OS X 10.3.3"
	"Mac OS X 10.3.4"
	"Mac OS X 10.3.5"
	"Mac OS X 10.3.6"
	"Mac OS X 10.3.7"
	"Mac OS X 10.3.8"
	"Mac OS X 10.3.9"
	"Mac OS X 10.4"
	"Mac OS X 10.4.1"
	"Mac OS X 10.4.2"
	"Tcl/Tk"
	"Tcl/Tk 8.1"
	"Tcl/Tk 8.2"
	"Tcl/Tk 8.2.1"
	"Tcl/Tk 8.2.2"
	"Tcl/Tk 8.3"
	"Tcl/Tk 8.3.1"
	"Tcl/Tk 8.3.2"
	"Tcl/Tk 8.3.3"
	"Tcl/Tk 8.3.4"
	"Tcl/Tk 8.4a1"
	"Tcl/Tk 8.4a2"
	"Tcl/Tk 8.4a3"
	"Tcl/Tk 8.4a4"
	"Tcl/Tk 8.4a5"
	"Tcl/Tk 8.4b1"
	"Tcl/Tk 8.4"
	"Tcl/Tk 8.4.1"
	"Tcl/Tk 8.4.2"
	"Tcl/Tk 8.4.3"
	"Tcl/Tk 8.4.4"
	"Tcl/Tk 8.4.5"
	"Tcl/Tk 8.4.6"
	"Tcl/Tk 8.4.7"
	"Tcl/Tk 8.4.8"
	"Tcl/Tk 8.4.9"
	"Tcl/Tk 8.4.10"
	"Tcl/Tk 8.4.11"
	"Tcl/Tk 8.5a0"
	"Tcl/Tk 8.5a1"
	"Tcl/Tk 8.5a2"
	"Tcl/Tk 8.5a3"
	"Tcl/Tk 8.5a4"
	"Other"
    }
    set ReportInfo(op_sys) "All"
    
    set FieldOptions(bug_severity) {
	blocker
	critical
	major
	normal
	minor
	trivial
	enhancement
	faq
    }
    set ReportInfo(bug_severity) "normal"
    
    set FieldOptions(bug_status) {
	UNCONFIRMED
	NEW
    }
    set ReportInfo(bug_status) "UNCONFIRMED"
    
    set FieldOptions(keywords) {
	ALPHA-D
	alphaAlpha
	cabal
	crash
	dummy
	FAQ
	helpwanted
	mail-interface
	meta
	patch
	pending
	perf
	pp
	votesrequested
    }
    set ReportInfo(keywords) ""
    
    set ReportInfo(crashTime) ""
    set ReportInfo(crashInfo) ""
    
    # This one is handled by checkboxes, so each group must be a list with
    # two items: the actual group name, and the text that describes it.
    # 
    # (Currently disabled -- Alpha8/X bugs are now open to the public.)
    # 
    # set FieldOptions(groupset) {
    #     {alphatesters
    #     {Only people in the "Alpha8 alpha Testers" group can see this bug}}
    # }
    
    # Make sure that these are proper lists.
    foreach field [array names FieldOptions] {
	set FieldOptions($field) [join [split $FieldOptions($field)]]
    }
    # Cleanup.
    unset -nocomplain bugzillaField tclAEVersion \
      reportField value field product
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Crash Cache Check ×××× #
# 
# This start-up check determines if the previous Alpha editing session was
# shut down properly, or if it was aborted by a crash.
# 

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::checkPriorCrash"  --
 # 
 # We create a cache file named "lastCrashLog" whose sole purpose is to
 # record a timestamp so that we can compare its date to the last modified
 # date of the CrashReporter "Alpha.crash.log" file.  If our cache file
 # doesn't exist, the user must be launching Alpha for the first time, so
 # we simply create the file and exit.  If the crash.log file doesn't
 # exist, then Alpha has never crashed before (or the log was removed by
 # the user.)  If the crash.log file is newer than our previously created
 # cache file, then we suspect a crash recently took place so we parse the
 # log to confirm this.  If a recent crash occurred, offer to create a new
 # "crash report" that can be sent to bugzilla.  
 # 
 # Upon the successful completion of this report, [bugzilla::reportACrash]
 # will reset the cache file date so that this dialog isn't presented
 # again.  This also happens when the user declines to create one.
 # 
 # This is MacOSX specific, on other platforms we simply return.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::checkPriorCrash {} {
    
    global alpha::macos
    
    variable AlphaApp
    variable crashLog
    variable ReportInfo
    
    # If our "lastCrashLog" doesn't exist, create it and move on, otherwise
    # make sure that the "crashLog" file actually exists.
    if {([set alpha::macos] != 2)} {
	return
    } elseif {![cache::exists "lastCrashLog"]} {
	bugzilla::resetCrashCache
	return
    } elseif {![file exists $crashLog]} {
	return
    }
    set time1 [file mtime [cache::name "lastCrashLog"]]
    set time2 [file mtime $crashLog]
    # Check to see if we have recent crashes.
    if {($time1 < $time2)} {
	# There was apparently a recent crash, but check the log to make
	# sure that the file wasn't simply modified by the user.
	bugzilla::parseCrashLog
	set time3 [clock scan $ReportInfo(crashTime)]
	if {![string length $time3] || ($time1 > $time3)} {
	    bugzilla::resetCrashCache
	    return
	}
	# Offer to create a new "crash report."
	set q "It appears that $AlphaApp\
	  recently crashed, on\r\r    [clock format $time3 -format "%c"]\
	  \r\rDo you want to file a bug report?"
	switch -- [alert -t caution -k Yes -c Later -o No $q] {
	    "Yes" {
		# This will reset the time-stamp as necessary.
		bugzilla::reportACrash
	    }
	    "No" {
		# Reset the time-stamp.
		bugzilla::resetCrashCache
	    }
	    default {
		# Do nothing.
	    }
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::resetCrashCache"  --
 # 
 # We use the timestamp of the "lastCrashLog" cache file to compare it to
 # the CrashReporter "Alpha.crash.log" file, so resetting this means
 # changing the last modified date.  Creating it (using [cache::create])
 # automatically updates the last modified date, which means we don't have
 # to mess with [file mtime ...]
 # 
 # This is MacOSX specific, on other platforms we simply return.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::resetCrashCache {} {
    
    global alpha::macos
    
    if {([set alpha::macos] == 2)} {
	cache::create "lastCrashLog"
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::parseCrashLog"  --
 # 
 # Parse the Alpha.crash.log file to get the information about the most
 # recent crash.  We assume that Apple isn't going to monkey with the format 
 # of these files anytime soon, the dividing lines
 # 
 # **********
 # 
 # are pretty essential here.  At present we parse the entire file but we're
 # only concerned with the last one.  The "crashTimes" and "crashStarts"
 # lists can be used to get each entry if that is ever required.  The new
 # values (if any) are placed in the "ReportInfo" array.
 # 
 # This is MacOSX specific, on other platforms we simply return because the 
 # "crashLog" file won't exist.
 # 
 # --------------------------------------------------------------------------
 # 
 # There's a stupid Tcl bug with [clock scan] where a positive GMT lag
 # will throw an error, as in
 # 
 #     ÇÈ clock scan "2004-09-29 11:43:46 +0200"
 #     Error: unable to convert date-time string "2004-09-29 11:43:46 +0200"
 #     ÇÈ clock scan "2004-09-29 11:43:46"
 #     1096451026
 # 
 # As Joachim describes it, "This is a known bug in Tcl, and it is a scan-dal
 # that it has not been fixed, because in previous versions of Tcl (say 8.3,
 # if I am not mistaken) it worked fine.  The bug only affects time shifts
 # indicated with a plus sign (not minus sign!)  so it is very likely some
 # stupid typo in the internal regexps of [clock scan]."
 # 
 # So we need to strip this off first.  Fortunately, this doesn't appear to
 # change the results, as in
 # 
 #     ÇÈ clock scan "2004-09-29 11:43:46 -0500"
 #     1096476226
 #     ÇÈ clock scan "2004-09-29 11:43:46"
 #     1096476226
 # 
 # so long as the offset represents the same GMT lag used in the OS. We do
 # this here, and make sure that [clock scan] is only used on the variable
 # "ReportInfo(crashTime)" throughout this file.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::parseCrashLog {} {
    
    variable crashLog
    variable ReportInfo
    
    array set ReportInfo [list  \
      "crashTime"       ""      \
      "crashInfo"       ""      \
      "lastCrashPos"    ""      \
      ]
    
    if {![file exists $crashLog]} {
	# No crash log information is available.
	return
    }
    
    # Get the entire crash report log.
    set crashReport [file::readAll $crashLog]
    
    # Create the list of all crashes and times.
    set crashStarts [list]
    set crashTimes  [list]
    
    set cid [scancontext create]
    
    scanmatch $cid {\*{10}} \
      {lappend crashStarts $matchInfo(offset)}
    scanmatch $cid {Date/Time:\s*(.*)} \
      {lappend crashTimes $matchInfo(submatch0)}
    
    set fid [open $crashLog]
    scanfile $cid $fid
    close $fid
    
    scancontext delete $cid
    
    # Get the last crash time and information.
    set lastCrashTime [lindex $crashTimes end]
    set lastCrashPos  [lindex $crashStarts end]
    if {($lastCrashPos eq "")} {
	set lastCrashPos 0
    }
    set lastCrashInfo [string trim \
      [string range $crashReport $lastCrashPos end]]
    # Remove the "Binary Images Description" information.
    regsub -- {Binary Images Description.*} $lastCrashInfo "" lastCrashInfo
    # [clock scan] bug workaround.
    regexp {(.+)\s+\+\d{4}} $lastCrashTime -> lastCrashTime
    # And another...
    regsub -- {(\d+:\d+:\d+)\.\d+ } $lastCrashTime {\1 } lastCrashTime
    set lastCrashInfo [string trim $lastCrashInfo]
    
    array set ReportInfo [list          \
      "crashTime"       $lastCrashTime  \
      "crashInfo"       $lastCrashInfo  \
      "lastCrashPos"    $lastCrashPos   \
      ]
    return 0
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Reporter Dialog Support ×××× #
# 
# Note that [bugzilla::helpWindow] will always abort the current procedure as
# well as any calling procs by throwing a harmless error (one that will only
# appear in the status bar, and not propogate to an alertnote or a window.)
# 

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::introduction"  --  ?reportType?
 # 
 # This is the introduction to the Report A Bug sequence of dialogs.  The
 # user can choose to create a new bug report, but a number of other buttons
 # are offered to search bugzilla, open the "Known Bugs" help file, get more
 # help about this routine, etc.
 # 
 # "reportType" options include "bug" "crash" and "RFE".
 # 
 # If the user chooses anything but "Create a new (report window)" we don't
 # allow the calling code to continue.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::introduction {{reportType "bug"}} {
    
    global alpha::platform
    
    variable AlphaApp
    variable continueHelpTag
    variable crashLog
    variable ReportInfo
    
    set ReportInfo(reportType) $reportType
    set what $reportType
    append whats $reportType "s"
    switch -- $reportType {
	"bug" {
	    set reporterType "Bug Reporter"
	    set intro "Welcome to the Bug Reporter - this assistant will\
	      help you create a new bug report."
	    bugzilla::helpButton "Report A Bug"
	}
	"crash" {
	    set reporterType "Crash Reporter"
	    set whats "crashes"
	    set intro "Welcome to the Crash Reporter - this assistant will\
	      help you create a new crash report."
	    bugzilla::helpButton "Report A Crash"
	}
	"RFE" {
	    set reporterType "Suggestion Maker"
	    set intro "Welcome to the Suggestion Maker - this assistant will\
	      help you create a new \"Request For Enhancement\" (RFE)."
	    bugzilla::helpButton "Make A Suggestion"
	}
	default {
	    error "Unknown reportType: $reporterType"
	}
    }
    set buttons $helpButton
    # Create the list of options, specific to the $what type.
    set options [list \
      "Create a new $what report" \
      "Check for newer versions of $AlphaApp" \
      "Open the \"Known Bugs\" help file" \
      "Search the Alpha-Bugzilla database" \
      ]
    if {($what ne "RFE")} {
	lappend options \
	  "Perform a Tcl 'stack trace'"\
	  "Attach file to an existing report"
    } else {
	set options [lreplace $options 2 2 "Open the \"Filed RFEs\" help file"]
    }
    if {($what ne "RFE") && [file exists $crashLog]} {
	lappend options "Review the $AlphaApp Crash Log"
    }
    # Create the introductory dialog.
    set dialogTitle "$reporterType -- Introduction"
    set dialogScript [list dialog::make -title $dialogTitle \
      -width "450" \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancelhelptag "Click here to cancel the report creation." \
      -addbuttons $buttons \
      [list "" \
      [list "text" "${intro}\r"] \
      [list "text" "All known $whats for $AlphaApp are maintained in a\
      searchable on-line database known as \"Alpha-Bugzilla\" -- you\
      might want to review the local \"Known Bugs\" help file that was\
      updated just prior to this release, or check to see if any newer $whats\
      have been filed.\r"] \
      [list "text" "You might also want to see if a newer version of $AlphaApp\
      has been released -- this $what might have already been addressed.\r"] \
      [list [list "menu" $options] "Options:" [lindex $options 0]] \
      [list "divider" "divider"] \
      [list "text" "If you choose to create a new $what report,\
      you will be presented with a series of dialogs to help you fill\
      in the necessary information that will help an $AlphaApp developer\
      what further action should be taken.\r"] \
      [list "text" "You can press the \"Help\" button at any time\
      to postpone the $reporterType to obtain more information."] \
      ]]
    if {[catch {eval $dialogScript} result]} {
	status::msg "$reporterType cancelled."
	return -code return
    }
    set createReport 0
    switch -regexp -- [lindex $result 0] {
	"^Attach file"  {bugzilla::createAttachment}
	"^Check for"    {eval helpMenu "AlphaTcl home page"}
	"^Create a new" {set createReport 1}
	"^Open the"     {
	    if {($what eq "RFE")} {
		help::openGeneral "Known Bugs" "Requests For Enhancement"
	    } else {
		help::openGeneral "Known Bugs"
	    }
	}
	"^Perform a"    {bugzilla::traceProc}
	"^Review the"   {bugzilla::menuProc "" "reviewCrashLog"}
	"^Search the"   {bugzilla::menuProc "" "searchBugsFor"}
	default         {error "Unknown option: [lindex $result 0]"}
    }
    if {!$createReport} {
	status::msg "$reporterType postponed"
	return -code return
    } else {
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::conclusion" --
 # 
 # Final dialog which allows the user to go back one more time to review the 
 # information, or "Finish" and create the report window.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::conclusion {} {
    
    variable backButton
    variable dialogTitle
    variable postponeHelpTag
    variable ReportInfo
    variable skippedSteps
    
    bugzilla::helpButton "Sending The Report"
    eval [list lappend buttons] $helpButton $backButton
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 450 \
      -ok "Finish" \
      -okhelptag "Click here to finish creating the report." \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      ]
    set dialogPage [list "" \
      [list "text" "Your bug report is now being compiled, and will be\
      opened in a new window where you can edit it further.  When you\
      are ready to submit the report read the introductory text that\
      will be inserted at the top of bug report window.\r"] \
      ]
    set skipped [llength [lunique $skippedSteps]]
    if {!$ReportInfo(advanced) && [llength $skipped]} {
	if {($skipped == 1)} {
	    set skippedText "\(One step was "
	} else {
	    set skippedText "\($skipped steps were "
	}
	append skippedText "skipped because you chose to not include\
	  \"advanced\" options.  You can Go Back to revisit them.\)\r"
        lappend dialogPage [list "text" $skippedText]
    }
    lappend dialogScript $dialogPage
    eval $dialogScript
    return 1
}

## 
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::helpButton" --
 # 
 # Create a "helpButton" variable for the calling procedure, directing the 
 # user to a specified "Alpha Bugzilla Help" file section.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::helpButton {{helpWindowSection ""}} {
    
    upvar helpButton helpButton
    
    set helpButton [list "Help" \
      "Click here to postpone the report creation\
      and get more information about this step." \
      [list bugzilla::helpWindow $helpWindowSection "1"]]
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::helpWindow"  -- ?sectionMark? ?fromButtonScript?
 # 
 # Open the "Report A Bug" help window and possibly navigate to a specific
 # section mark.  If "fromButtonScript" (boolean) is "1" then we are being
 # called from a dialog, in which case we need to let the calling code know
 # that we're throwing an error to postpone whatever is taking place.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::helpWindow {{sectionMark ""} {fromButtonScript 1}} {
    
    package::helpWindow reportABug
    if {[string length $sectionMark]} {
	help::goToSectionMark $sectionMark
    }
    if {!$fromButtonScript} {
	error "Cancelled -- Bug reporter postponed."
    } else {
	uplevel 1 [list set retCode "1"]
	uplevel 1 [list set retVal "cancel"]
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::checkRegistration"  --
 # 
 # This can be called by any bug report window creation routine, or just
 # prior to a bug being sent somewhere.  It simply serves as a reminder that
 # the user should create a bugzilla account in order to file new bugs.  Once
 # the user checks the "I've registered" box s/he will never be bothered by
 # it again.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::checkRegistration {} {
    
    global bugzillamodeVars
    
    variable continueHelpTag
    variable dialogTitle
    variable postponeHelpTag
    variable requireRegistration
    
    if {$requireRegistration} {
	set txt "If not, you need to register your e-mail address.\r"
    } else {
	set txt "Registration is recommended, though not required.\r"
    }
    bugzilla::helpButton "Bugzilla Registration"
    set registerButton [list "Register" \
      "Click here to open a web page to register with Alpha-Bugzilla.\
      Registration is free, and only requires a valid e-mail address.\
      \r\rIf you don't register, your reports will always be sent\
      \"anonymously.\"" \
      {bugzilla::menuProc "" "createAccount" ;\
      set retVal "cancel" ; set retCode 1}]
    eval [list lappend buttons] $helpButton $registerButton
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 400 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "Do you already have an \"account\" with\
      Alpha-Bugzilla?\r"] \
      [list "text" $txt] \
      [list [list "smallval" "flag"] "I have already registered" \
      $bugzillamodeVars(registeredBugzillaAccount) \
      "If you have already registered an Alpha-Bugzilla account, you won't\
      be prompted to do so in the future. Registration helps ensure that\
      AlphaTcl developers can ask you questions when necessary."] \
      ]]
    set registered [lindex [eval $dialogScript] 0]
    if {$registered ne $bugzillamodeVars(registeredBugzillaAccount)} {
	set bugzillamodeVars(registeredBugzillaAccount) $registered
	prefs::modified bugzillamodeVars(registeredBugzillaAccount)
	bugzilla::rebuildMenu
    }
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::checkAccountInfo"  --
 # 
 # Obtain the user's bugzilla e-mail and password, and store the results.  We
 # don't actually authenticate here, the [bugzilla::submitReport] results
 # window in should take care of that for us.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::checkAccountInfo {} {
    
    global bugzillamodeVars alpha::platform bugzillaHomePage
    
    variable AlphaApp
    variable requireRegistration
    
    # Dialog buttons
    bugzilla::helpButton "Bugzilla Registration"
    set registerButton [list "Register" \
      "Click here to open a web page to register with Bugzilla." \
      {bugzilla::menuProc "" "createAccount" ;\
      set retVal "cancel" ; set retCode 1}]
    eval [list lappend buttons] $helpButton $registerButton
    
    set dialogScript [list dialog::make -title "Bugzilla Account Information" \
      -width 400 \
      -ok "Continue" \
      -okhelptag "Click here to continue submitting the report." \
      -cancel "Postpone" \
      -cancelhelptag "Click here to postpone the report submission." \
      -addbuttons [list \
      "Help" \
      "Click here to cancel the submission and obtain more information." \
      {bugzilla::helpWindow "Bugzilla Registration" "1"}]]
    set dialogPage [list ""]
    if {$requireRegistration || $bugzillamodeVars(registeredBugzillaAccount)} {
	lappend dialogScript "-addbuttons" $buttons
	lappend dialogPage \
	  [list "text" "In order to continue, you must enter your registered\
	  Alpha-Bugzilla account name and password.\r"]\
	  [list "text" "Please verify the information below.\r"] \
	  [list "var" "Account Name:" $bugzillamodeVars(accountName)] \
	  [list "password" "Account Password:" $bugzillamodeVars(accountPassword)]
	# Give some extra information about the password field.
	if {![alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
	    lappend dialogPage \
	      [list "text" "\r(The password field does contain any previous\
	      value you've entered, i.e.\
	      \"[string repeat "¥" \
	      [string length $bugzillamodeVars(accountPassword)]]\" --\
	      it will be remembered for future bug reports.\
	      Future versions of ${alpha::application} will have more\
	      aesthetic password fieldsÉ)\r"]
	}
    } else {
	lappend dialogPage \
	  [list "text" "In order to continue, you must supply a valid\
	  e-mail address.  (Don't worry, $AlphaApp will only send this\
	  information to the Alpha-Bugzilla database and nowhere else.)\r"] \
	  [list "var" "E-mail Address:" $bugzillamodeVars(accountName)] \
	  [list "text" "\rYou will be contacted if more information is\
	  required, or if a solution is discovered for your problem.\r"]
    }
    lappend dialogScript $dialogPage
    set results [eval $dialogScript]
    set email [string trim [lindex $results 0]]
    # E-mail validation check.
    if {![regexp {^[^@,\t ]+@[^@,\t ]+\.+[^@,\t ]+$} $email]} {
	alertnote "The e-mail address you entered didn't match our minimal\
	  syntax checking for a legal email address.\r\rA legal address must\
	  contain exactly one '@', and at least one '.' after the @,\
	  and may not contain any commas or spaces."
	set bugzillamodeVars(accountName) $email
	return [bugzilla::checkAccountInfo]
    } elseif {($email ne $bugzillamodeVars(accountName))} {
	set bugzillamodeVars(accountName) $email
	prefs::modified bugzillamodeVars(accountName)
    }
    if {([llength $results] == 1)} {
	return 1
    }
    # Password validation check.
    set pword [string trim [lindex $results 1]]
    if {![string length $pword]} {
	alertnote "The password you supplied was an empty string!"
	return [bugzilla::checkAccountInfo]
    } elseif {($pword ne $bugzillamodeVars(accountPassword))} {
	set bugzillamodeVars(accountPassword) $pword
	prefs::modified bugzillamodeVars(accountPassword)
    }
    return 1
}

## 
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::setPackageInfo" --
 # 
 # Set some field info that will be included in the footer of each report.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::setPackageInfo {} {
    
    global global::features smarterSourceFolder PREFS
    
    variable ReportInfo
    
    # Create the lists of menus/features for the mode of the active window.
    if {[llength [winNames]]} {
	set m [win::getMode]
	append modePackages $m " Mode Menus/Features : "
	if {[llength [set modePkgs [mode::getFeatures $m]]]} {
	    append modePackages \r\r \
	      [breakIntoLines [join $modePkgs " "] 77 2]
	} else {
	    append modePackages "(none)"
	}
    } else {
	set m            ""
	set modePackages ""
    }
    # Create the lists of current features/menus.
    set allMenus [alpha::listAlphaTclPackages "menus"]
    foreach pkg [lsort -dictionary $global::features] {
	if {([lsearch $ReportInfo(alwaysOnPkgs) $pkg] > -1)} {
	    continue
	} elseif {([lsearch $ReportInfo(autoLoadPkgs) $pkg] > -1)} {
	    continue
	} elseif {([lsearch $allMenus $pkg] > -1)} {
	    lappend Menus $pkg
	} else {
	    lappend Features $pkg
	}
    }
    foreach item [list "Menus" "Features"] {
	set global$item "Global $item : "
	if {![info exists $item]} {
	    append global$item "(none)"
	} else {
	    append global$item \r\r \
	      [breakIntoLines [join [set $item] " "] 77 2]
	}
    }
    # Smarter Source files.
    set ssFiles "Smarter Source files : "
    if {[package::active "smarterSource"]} {
	set files [file::recurse $smarterSourceFolder "*.tcl"]
	foreach f $files {
	    lappend fileNames [file tail $f]
	}
	if {[info exists fileNames]} {
	    set fileNames [lsort -dictionary -unique $fileNames]
	    append ssFiles \r\r [breakIntoLines [join $fileNames " "] 77 2]
	} else {
	    append ssFiles \r\r "  (none -- Smarter Source folder is empty.)"
	}
    } else {
	append ssFiles \r\r "  (none -- Smarter Source is not turned on.)"
    }
    # Does the user have any prefs file additions?
    set globalPrefsFile [file exists [file join $PREFS "prefs.tcl"]]
    append ssFiles \r\r "  A \"prefs.tcl\" file does " \
      [expr {$globalPrefsFile ? "" : "not "}] \
      "exist in the user's \$PREFS folder."
    if {($m ne "")} {
	set modePrefsFile [file exists [file join $PREFS "${m}Prefs.tcl"]]
	append ssFiles \r "  A \"${m}Prefs.tcl\" file does " \
	  [expr {$modePrefsFile ? "" : "not "}] "exist."
    }
    # Now we set the report information.
    array set ReportInfo [list \
      "originalMode"    $m \
      "globalFeatures"  $globalFeatures \
      "globalMenus"     $globalMenus \
      "modePackages"    $modePackages \
      "packageInfoSet"  1 \
      "ssFiles"         $ssFiles \
      ]
    
    return
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Bug Reporting Dialogs ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::reportABug"  --
 # 
 # Called (indirectly) by "Help > Report A Bug" plus other hyperlinks in
 # various files, this procedure establishes which dialogs will be presented
 # to the user in order to create a bug report window.  In each case, the
 # returned result is used to increment the "Step X" in the next dialog's
 # title, so "0" indicates that (for whatever reason) nothing was presented
 # to the user, while "1" indicates that something was.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::reportABug {} {
    
    global bugzillamodeVars
    
    variable backError
    variable dialogTitle
    variable ReportInfo
    variable skippedSteps [list]
    variable step 1
    
    # Reset some fields.
    bugzilla::setPackageInfo
    array set ReportInfo [list \
      "crashInfo"       "" \
      "bug_severity"    "normal" \
      "keywords"        "" \
      ]
    # Now run through the dialogs required to create the report.
    bugzilla::introduction "bug"
    set pages [list checkRegistration bugProduct bugComponent bugSummary \
      actionCausingBug bugDetails bugSolution bugFields bugKeywords conclusion]
    set ignore [list]
    if {$bugzillamodeVars(registeredBugzillaAccount)} {
	lappend ignore "checkRegistration"
    }
    # For now we remove the "keywords" dialog.
    lappend ignore "bugKeywords"
    set pages [lremove $pages $ignore]
    # Now we offer each dialog, and go back when requested.
    set steps [expr {[llength $pages] - 1}]
    for {set i 0} {($i < [llength $pages])} {incr i} {
	set dialogTitle "Bug Reporter"
	set page [lindex $pages $i]
	if {($page eq [lindex $pages end])} {
	    append dialogTitle " - Done!"
	} elseif {($step > 0)} {
	    append dialogTitle " - Step " $step " of " $steps
	}
	if {![catch {bugzilla::$page} result]} {
	    incr step
	} elseif {($result eq $backError)} {
	    set ReportInfo(advanced) 1
	    incr i -2
	    incr step -1
	    continue
	} elseif {($result eq "cancel")} {
	    status::msg "Bug reporter postponed."
	    return
	} else {
	    # ???
	    dialog::alert "Dialog error ($page):\r\r$result"
	    incr step
	}
	if {!$result} {
	    lappend skippedSteps $page
	}
    }
    bugzilla::createBugWindow
    status::msg "Thanks for using the Bug Reporter !!"
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::bugProduct"  --
 # 
 # Offer the list of products for which bugs can be filed.  Note that the
 # "Products" variable only includes one of Alpha or Alphatk -- you cannot
 # file a bug for the other software because we don't have access to the
 # correct version number and the report submission will most likely fail.
 # 
 # At this point we also ask if the user wants the "advanced" set of dialogs
 # that follow.  When this is turned off, the number of remaining steps is
 # quite a bit smaller.
 # 
 # Bugzilla fields:
 # 
 # --  product
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::bugProduct {} {
    
    global alpha::platform
    
    variable advancedHelpTag
    variable AlphaApp
    variable backButton
    variable continueHelpTag
    variable dialogTitle
    variable postponeHelpTag
    variable Products
    variable ReportInfo
    variable step
    
    set introText "You must first pick a \"product\" for this bug."
    if {($alpha::platform eq "alpha")} {
	append introText "  Note that 'Alpha' includes both Alpha8 and AlphaX."
    }
    bugzilla::helpButton "Products"
    if {($step == "1")} {
	set buttons $helpButton
    } else {
	eval [list lappend buttons] $helpButton $backButton
    }
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 400 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "${introText}\r"] \
      [list "text" "(If you're not sure, just choose \"AlphaTcl\")\r"] \
      [list [list "menu" $Products] "Products:" $ReportInfo(product)] \
      [list "divider" "divider"] \
      [list [list "smallval" "flag"] \
      "Include advanced options in subsequent dialogs" $ReportInfo(advanced) \
      $advancedHelpTag] \
      ]]
    
    set result [eval $dialogScript]
    set ReportInfo(product)   [lindex $result 0]
    set ReportInfo(advanced)  [lindex $result 1]
    
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::bugComponent"  --
 # 
 # Given the product, offer the possible components and version numbers
 # associated with it.  
 # 
 # Bugzilla fields:
 # 
 # --  component
 # --  version
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::bugComponent {} {
    
    variable backButton
    variable Components
    variable continueHelpTag
    variable DefaultComponent
    variable DefaultVersion
    variable dialogTitle
    variable postponeHelpTag
    variable ReportInfo
    variable Versions
    
    set product $ReportInfo(product)
    
    if {!$ReportInfo(advanced)} {
	set ReportInfo(component) $DefaultComponent($product)
	set ReportInfo(version)   $DefaultVersion($product)
	return 0
    }
    
    set components $Components($product)
    set versions   $Versions($product)
    
    bugzilla::helpButton "Components And Version Numbers"
    eval [list lappend buttons] $helpButton $backButton
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 400 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "Please select a component for '${product}'"] \
      [list "text" "(If you're not sure, make a good guess.)\r"] \
      [list [list "menu" $Components($product)] \
      "Component:" $DefaultComponent($product)] \
      [list "divider" "divider"] \
      [list "text" "Please select a version number for '${product}' :\r"] \
      [list [list "menu" $Versions($product)] \
      "Version:" $DefaultVersion($product)] \
      ]]
    
    set result [eval $dialogScript]
    set ReportInfo(component) [lindex $result 0]
    set ReportInfo(version)   [lindex $result 1]
    set DefaultComponent($product) $ReportInfo(component)
    set DefaultVersion($product)   $ReportInfo(version)
    
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::bugSummary"  --
 # 
 # Obtain the short description that identifies the bug.  We're also going to
 # figure out what type of action caused the bug, and confirm that the user
 # is able to reproduce it.
 # 
 # Bugzilla fields:
 # 
 # --  short_desc
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::bugSummary {} {
    
    variable AlphaApp
    variable backButton
    variable continueHelpTag
    variable dialogTitle
    variable postponeHelpTag
    variable ReportInfo
    variable ReportOptions
    
    if {!$ReportInfo(advanced)} {
	set actions [lrange $ReportOptions(actions) 0 2]
    } else {
	set actions $ReportOptions(actions)
    }
    set product $ReportInfo(product)
    
    bugzilla::helpButton "Basic Information"
    eval [list lappend buttons] $helpButton $backButton
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 450 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "Please enter a brief description for the bug.\r"] \
      [list "var"  "Summary:" $ReportInfo(short_desc)] \
      [list "divider" "divider"] \
      [list "text" "What action did you take that showed the bug?\r"]\
      [list [list "menu" $actions] "Action:" $ReportInfo(action)] \
      [list "divider" "divider"] \
      [list "text" "Have you quit and restarted ${AlphaApp}?\
      Are you still able to reproduce the bug again with the\
      same sequence of actions?\r"] \
      [list [list "smallval" "flag"] \
      "I can reproduce this bug" $ReportInfo(reproducible) \
      "If you can't reproduce the bug, it is very unlikely\
      that anyone else will be able to do anything about it.\r\rYou\
      should probably investigate further before reporting it."] \
      [list "divider" "divider"] \
      ]]
    
    set result [eval $dialogScript]
    
    set ReportInfo(short_desc)        [lindex $result 0]
    set ReportInfo(action)            [lindex $result 1]
    set ReportInfo(reproducible)      [lindex $result 2]
    
    if {![string length [string trim $ReportInfo(short_desc)]]} {
	alertnote "You must enter a summary line for the bug."
	return [bugzilla::bugSummary]
    } elseif {!$ReportInfo(reproducible)} {
	alertnote "If you can't reproduce the bug, it is very unlikely\
	  that anyone else will be able to do anything about it.\r\rYou\
	  should probably investigate further before reporting it."
    }
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::bugDetails"  --
 # 
 # This is the longer set of comments that describe the bug.
 # 
 # Bugzilla fields:
 # 
 # --  comment
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::bugDetails {} {
    
    variable backButton
    variable continueHelpTag
    variable dialogTitle
    variable postponeHelpTag
    variable ReportInfo
    
    bugzilla::helpButton "Details"
    eval [list lappend buttons] $helpButton $backButton
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 450 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "Please include any further details about this\
      $ReportInfo(reportType) that might help a developer replicate\
      the problem and resolve it."] \
      [list "var10" " " $ReportInfo(details)] \
      ]]
    
    set ReportInfo(details) [lindex [eval $dialogScript] 0]
    if {![string length [string trim $ReportInfo(details)]]} {
	alertnote "You must enter some comments about the bug."
	return [bugzilla::bugDetails]
    }
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::bugSolution"  --
 # 
 # If the reporter has a possible solution to fix the bug, we'll put that in
 # a separate section.
 # 
 # Bugzilla fields:
 # 
 # --  comment (cont.)
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::bugSolution {} {
    
    variable backButton
    variable continueHelpTag
    variable dialogTitle
    variable postponeHelpTag
    variable ReportInfo
    
    if {!$ReportInfo(advanced)} {
	return 0
    }
    
    bugzilla::helpButton "Possible Solution"
    eval [list lappend buttons] $helpButton $backButton
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 450 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "If you know of any possible solutions or patches \
      for this bug, please include them here, or simply press 'Continue'"] \
      [list "var10" " " $ReportInfo(fix)] \
      ]]
    
    set ReportInfo(fix) [lindex [eval $dialogScript] 0]
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::bugFields"  --
 # 
 # Offer some of the more minor fields used by bugzilla.  The "bug_severity" 
 # is probably the most often adjusted.
 # 
 # Bugzilla fields:
 # 
 # --  assigned_to
 # --  bug_severity
 # --  cc
 # --  groupset
 # --  keywords
 # --  op_sys
 # --  rep_platform
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::bugFields {} {
    
    variable backButton
    variable continueHelpTag
    variable dialogTitle
    variable FieldOptions
    variable OptionalFields
    variable postponeHelpTag
    variable ReportInfo
    
    if {!$ReportInfo(advanced)} {
	return 0
    }
    
    bugzilla::helpButton "Additional Fields"
    eval [list lappend buttons] $helpButton $backButton
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 450 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons]
    # These are handled differently.
    set optionalFields [lremove -- $OptionalFields keywords groupset]
    # These have edit fields, not menus.
    set textFields [list assigned_to cc]
    set dialogPage [list "" \
      [list "text" "Change any default bugzilla fields here if desired,\
      or simply press 'Continue'."]]
    foreach field $optionalFields {
	if {![lcontains textFields $field]} {
	    lappend dialogPage \
	      [list [list "menu" $FieldOptions($field)] $field $ReportInfo($field)]
	} else {
	    lappend dialogPage \
	      [list "var" $field $ReportInfo($field)]
	}
    }
    # Now add the groupset items to the dialog.
    foreach item $FieldOptions(groupset) {
	lappend dialogPage [list "flag" [lindex $item 0] [lindex $item 1]]
    }
    # Present the dialog to the user.
    lappend dialogScript $dialogPage
    set results [eval $dialogScript]
    
    # Adjust the ReportInfo field info.
    set count 0
    foreach field $optionalFields {
	set ReportInfo($field) [lindex $results $count]
	incr count
    }
    # Adjust the ReportInfo groupset items.
    set ReportInfo(groupset) [list]
    foreach item $FieldOptions(groupset) {
	if {[lindex $results $count]} {
	    lappend ReportInfo(groupset) [lindex $item 0]
	}
	incr count
    }
    set ReportInfo(groupset) [join $ReportInfo(groupset) ", "]
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::bugKeywords"  --
 # 
 # Offer all of the currently recognized keywords in a list-pick dialog.
 # 
 # Bugzilla fields:
 # 
 # --  keywords
 # 
 # At present this is disabled: nobody seems to add keywords to their
 # reports, and ideally we'd like to use some [dialog::make] construction to
 # build this dialog anyway.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::bugKeywords {} {
    
    variable FieldOptions
    variable dialogTitle
    variable ReportInfo
    
    if {!$ReportInfo(advanced)} {
	return 0
    }
    
    # Now we get the key word list in a separate dialog.
    set p "Select any keywords for this report."
    set keywordOptions [concat [list "(No keywords)" "(Help)"] \
      $FieldOptions(keywords)]
    if {[catch {listpick -p $p -l $keywordOptions} result]} {
	error "Cancelled."
    } elseif {[lcontains result "(No keywords)"]} {
	set result [list]
    } elseif {[lcontains result "(Help)"]} {
	bugzilla::helpWindow "Keywords"
    }
    set ReportInfo(keywords) [join $result ", "]
    return 1
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Crash Dialogs ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::reportACrash"  --
 # 
 # Called (indirectly) by "AlphaDev > Alpha Bugzilla > Report A Crash" and by
 # the startup hook if necessary.  Similar to [bugzilla::reportABug], this
 # procedure establishes which dialogs will be presented to the user in order
 # to create a bug report window.  In each case, the returned result is used
 # to increment the "Step X" in the next dialog's title, so "0" indicates
 # that (for whatever reason) nothing was presented to the user, while "1"
 # indicates that something was.
 # 
 # This is just a simplified version of [bugzilla::reportABug], wherein we
 # know that a crash took place (thus a problem specifically with the binary
 # and not AlphaTcl) and we want to offer the option to add crash-log
 # details.  At the end of this routine, we reset the "lastCrashLog" cache so
 # that the user won't be troubled by "Do you want to report a crash?"
 # during the next startup.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::reportACrash {} {
    
    global alpha::platform mode bugzillamodeVars
    
    variable backError
    variable DefaultComponent
    variable DefaultVersion
    variable dialogTitle
    variable ReportInfo
    variable skippedSteps [list]
    variable step 1
    
    # Reset some fields.
    bugzilla::setPackageInfo
    if {(${alpha::platform} == "alpha")} {
	array set ReportInfo [list "product" "Alpha"]
    } else {
	array set ReportInfo [list "product" "AlphaTk"]
    }
    array set ReportInfo [list \
      "advanced"        "1" \
      "bug_severity"    "blocker" \
      "component"       $DefaultComponent($ReportInfo(product)) \
      "crashInfo"       "" \
      "keywords"        "crash" \
      "version"         $DefaultVersion($ReportInfo(product)) \
      ]
    
    # Now run through the dialogs required to create the report.
    bugzilla::introduction "crash"
    set step 1
    set pages [list checkRegistration crashSummary actionCausingBug \
      bugDetails crashLogInReport conclusion]
    set ignore [list]
    if {$bugzillamodeVars(registeredBugzillaAccount)} {
	lappend ignore "checkRegistration"
    }
    bugzilla::parseCrashLog
    if {![string length $ReportInfo(crashTime)]} {
	lappend ignore "crashLogInReport"
    }
    set pages [lremove $pages $ignore]
    set steps [expr {[llength $pages] - 1}]
    for {set i 0} {($i < [llength $pages])} {incr i} {
	set dialogTitle "Crash Reporter"
	set page [lindex $pages $i]
	if {($page eq [lindex $pages end])} {
	    append dialogTitle " - Done!"
	} elseif {($step > 0)} {
	    append dialogTitle " - Step " $step " of " $steps
	}
	if {![catch {bugzilla::$page} result]} {
	    incr step
	} elseif {($result eq $backError)} {
	    set ReportInfo(advanced) 1
	    incr i -2
	    incr step -1
	    continue
	} elseif {($result eq "cancel")} {
	    status::msg "Crash reporter postponed."
	    return
	} else {
	    # ???
	    dialog::alert "Dialog error ($page):\r\r$result"
	    incr step
	}
	if {!$result} {
	    lappend skippedSteps $page
	}
    }
    bugzilla::createBugWindow
    status::msg "Thanks for using the Crash Reporter !!"
    # If we're still here, reset the "lastCrashLog" cache file.
    bugzilla::resetCrashCache
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::crashSummary"  --
 # 
 # A modifed version of [bugzilla::bugSummary] that substitutes the string
 # "crash" for "bug."  It might have more changes later.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::crashSummary {} {
    
    variable AlphaApp
    variable backButton
    variable continueHelpTag
    variable dialogTitle
    variable postponeHelpTag
    variable ReportInfo
    variable ReportOptions
    variable step
    
    if {!$ReportInfo(advanced)} {
	set actions [lrange $ReportOptions(actions) 0 2]
    } else {
	set actions $ReportOptions(actions)
    }
    bugzilla::helpButton "Report A Bug"
    if {($step == "1")} {
	set buttons $helpButton
    } else {
	eval [list lappend buttons] $helpButton $backButton
    }
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 450 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "Please enter a brief description for the crash.\r"] \
      [list "var"  "Summary:" $ReportInfo(short_desc)] \
      [list "divider" "divider"] \
      [list "text" "What action did you take that caused the crash?\r"]\
      [list [list "menu" $actions] "Action:" $ReportInfo(action)] \
      [list "divider" "divider"] \
      [list "text" "Have you quit and restarted ${AlphaApp}?\
      Are you still able to reproduce the crash again with the\
      same sequence of actions?\r"] \
      [list [list "smallval" "flag"] \
      "I can reproduce this crash" $ReportInfo(reproducible) \
      "If you can't reproduce the crash, it is very unlikely\
      that anyone else will be able to do anything about it.\r\rYou\
      should probably investigate further before reporting it."] \
      [list "divider" "divider"] \
      ]]
    
    set result [eval $dialogScript]
    
    set ReportInfo(short_desc)        [lindex $result 0]
    set ReportInfo(action)            [lindex $result 1]
    set ReportInfo(reproducible)      [lindex $result 2]
    
    if {![string length [string trim $ReportInfo(short_desc)]]} {
	alertnote "You must enter a summary line for the bug."
	return [bugzilla::crashSummary]
    } elseif {!$ReportInfo(reproducible)} {
	alertnote "If you can't reproduce the crash, it is very unlikely\
	  that anyone else will be able to do anything about it.  You\
	  should probably investigate further before reporting it."
    }
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::crashLogInReport"  --
 # 
 # First parse the crash log, to make sure that we have some information to
 # offer.  If so, ask the user if it should be included in the report.
 # 
 # This is MacOSX specific, on other platforms we simply return because the 
 # "crashLog" file won't exist.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::crashLogInReport {} {
    
    variable AlphaApp
    variable backButton
    variable continueHelpTag
    variable dialogTitle
    variable postponeHelpTag
    variable ReportInfo
    
    bugzilla::parseCrashLog
    if {![string length $ReportInfo(crashTime)]} {
	return 0
    }
    if {![info exists ReportInfo(includeLog)]} {
	set ReportInfo(includeLog) 1
    }
    
    bugzilla::helpButton "Additional Fields"
    eval [list lappend buttons] $helpButton $backButton
    
    set ct [clock format [clock scan $ReportInfo(crashTime)] -format "%c"]
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 450 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "The last $AlphaApp \"crash log\" entry is dated\r"] \
      [list "text" "${ct}\r"] \
      [list "text" "Do you want to include this entry in the bug report?\
      (It might not make any sense to you, but it could help the\
      developers track down the problem.)\r"] \
      [list [list "smallval" "flag"] "Include crash log" \
      $ReportInfo(includeLog)] \
      [list "divider" "divider"] \
      ]]
    set result [eval $dialogScript]
    if {![lindex $result 0]} {
	# No, so set this variable to an empty string.
	ReportInfo(crashInfo) ""
    }
    return 1
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Suggestion Dialogs ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::makeASuggestion"  --
 # 
 # Called (indirectly) by "Help > Make A Suggestion" plus other hyperlinks in
 # various files, this procedure establishes which dialogs will be presented
 # to the user in order to create an RFE window.  In each case, the returned
 # result is used to increment the "Step X" in the next dialog's title, so
 # "0" indicates that (for whatever reason) nothing was presented to the
 # user, while "1" indicates that something was.
 # 
 # This is just a simplified version of version of [bugzilla::reportABug].
 # We assume that the request is made for AlphaTcl (developers can easily
 # change this later if necessary).  It automatically prepends the string
 # "RFE:" to the short description, and sets other bugzilla fields as needed.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::makeASuggestion {} {
    
    global bugzillamodeVars
    
    variable backError
    variable dialogTitle
    variable ReportInfo
    variable skippedSteps [list]
    variable step 1
    variable Versions
    
    # Set up some default values for the RFE. They will automatically be
    # filed as requests for AlphaTcl -- if they pertain to a particular
    # binary, developers can always change the relevant fields after the
    # report has been filed.
    array set ReportInfo [list          \
      "bug_severity"    "enhancement"   \
      "component"       "SystemCode"    \
      "crashInfo"       ""              \
      "keywords"        ""              \
      "originalMode"    ""              \
      "product"         "AlphaTcl"      \
      "version"         $Versions(AlphaTcl) \
      ]
    
    # Now run through the set of dialogs to create the report.
    bugzilla::introduction "RFE"
    set pages [list checkRegistration suggestionSummary suggestionProduct \
      suggestionComponent suggestionDetails suggestionSolution \
      bugKeywords conclusion]
    set ignore [list]
    if {$bugzillamodeVars(registeredBugzillaAccount)} {
	lappend ignore "checkRegistration"
    }
    # For now we remove the "keywords" dialog.
    lappend ignore "bugKeywords"
    set pages [lremove $pages $ignore]
    # Now we offer each dialog, and go back when requested.
    set steps [expr {[llength $pages] - 1}]
    for {set i 0} {($i < [llength $pages])} {incr i} {
	set dialogTitle "Suggestion Maker"
	set page [lindex $pages $i]
	if {($page eq [lindex $pages end])} {
	    append dialogTitle " - Done!"
	} elseif {($step > 0)} {
	    append dialogTitle " - Step " $step " of " $steps
	}
	if {![catch {bugzilla::$page} result]} {
	    incr step
	} elseif {($result eq $backError)} {
	    set ReportInfo(advanced) 1
	    incr i -2
	    incr step -1
	    continue
	} elseif {($result eq "cancel")} {
	    status::msg "Suggestion Maker postponed."
	    return
	} else {
	    # ???
	    dialog::alert "Dialog error ($page):\r\r$result"
	    incr step
	}
	if {!$result} {
	    lappend skippedSteps $page
	}
    }
    bugzilla::createRfeWindow
    status::msg "Thanks for using the Suggestion Maker !!"
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::suggestionSummary"  --
 # 
 # Obtain the short description that identifies the RFE.
 # 
 # At this point we also ask if the user wants the "advanced" set of dialogs
 # that follow.  When this is turned off, the number of remaining steps is
 # quite a bit smaller.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::suggestionSummary {} {
    
    variable advancedHelpTag
    variable backButton
    variable continueHelpTag
    variable dialogTitle
    variable postponeHelpTag
    variable ReportInfo
    variable step
    
    set rfePat {^RFE(:?)\s*}
    regsub -nocase -- $rfePat $ReportInfo(short_desc) "" ReportInfo(short_desc)
    
    bugzilla::helpButton "Make A Suggestion"
    if {($step == "1")} {
	set buttons $helpButton
    } else {
	eval [list lappend buttons] $helpButton $backButton
    }
    set buttons $helpButton
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 450 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "Please enter a brief description for your suggestion.\r"] \
      [list "var"  "Summary:" $ReportInfo(short_desc)] \
      [list "divider" "divider"] \
      [list [list "smallval" "flag"] \
      "Include advanced options in subsequent dialogs" $ReportInfo(advanced) \
      $advancedHelpTag] \
      ]]
    set result  [eval $dialogScript]
    set summary [lindex $result 0]
    set ReportInfo(advanced)  [lindex $result 1]
    regsub -nocase -- $rfePat $summary "" summary
    if {![string length [string trim $summary]]} {
	alertnote "You must enter a summary line for the suggestion."
	return [bugzilla::suggestionSummary]
    }
    set ReportInfo(short_desc) "RFE: $summary"
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::suggestionProduct"  --
 # 
 # Offer the list of products for which RFEs can be filed.  Note that the
 # "Products" variable only includes one of Alpha or Alphatk -- you cannot
 # file an RFE for the other software because we don't have access to the
 # correct version number and the report submission will most likely fail.
 # 
 # Bugzilla fields:
 # 
 # --  product
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::suggestionProduct {} {
    
    variable AlphaApp
    variable backButton
    variable continueHelpTag
    variable dialogTitle
    variable postponeHelpTag
    variable Products
    variable ReportInfo
    
    if {!$ReportInfo(advanced)} {
	return 0
    }
    set introText "You must first pick a \"product\" for this RFE."
    if {(${alpha::platform} == "alpha")} {
	append introText "  Note that 'Alpha' includes both Alpha8 and AlphaX."
    }
    
    bugzilla::helpButton "Products"
    eval [list lappend buttons] $helpButton $backButton
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 400 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "${introText}\r"] \
      [list "text" "(If you're not sure, just choose \"AlphaTcl\")\r"] \
      [list [list "menu" $Products] "Products:" $ReportInfo(product)] \
      ]]
    
    set result [eval $dialogScript]
    set ReportInfo(product) [lindex $result 0]
    
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::suggestionComponent"  --
 # 
 # Given the product, offer the possible components and version numbers
 # associated with it.  
 # 
 # Bugzilla fields:
 # 
 # --  component
 # --  version
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::suggestionComponent {} {
    
    variable backButton
    variable Components
    variable continueHelpTag
    variable DefaultComponent
    variable DefaultVersion
    variable dialogTitle
    variable postponeHelpTag
    variable ReportInfo
    variable Versions
    
    set product $ReportInfo(product)
    
    if {!$ReportInfo(advanced)} {
	set ReportInfo(component) $DefaultComponent($product)
	set ReportInfo(version)   $DefaultVersion($product)
	return 0
    }
    
    set components $Components($product)
    set versions   $Versions($product)
    
    bugzilla::helpButton "Components And Version Numbers"
    eval [list lappend buttons] $helpButton $backButton
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 400 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "Please select a component for '${product}'"] \
      [list "text" "(If you're not sure, make a good guess.)\r"] \
      [list [list "menu" $Components($product)] \
      "Component:" $DefaultComponent($product)] \
      [list "divider" "divider"] \
      [list "text" "Please select a version number for '${product}' :\r"] \
      [list [list "menu" $Versions($product)] \
      "Version:" $DefaultVersion($product)] \
      [list "divider" "divider"] \
      ]]
    
    set result [eval $dialogScript]
    set ReportInfo(component) [lindex $result 0]
    set ReportInfo(version)   [lindex $result 1]
    set DefaultComponent($product) $ReportInfo(component)
    set DefaultVersion($product)   $ReportInfo(version)
    
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::suggestionDetails"  --
 # 
 # Obtain the longer set of comments for the suggestion.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::suggestionDetails {} {
    
    variable backButton
    variable continueHelpTag
    variable dialogTitle
    variable postponeHelpTag
    variable ReportInfo
    
    bugzilla::helpButton "Make A Suggestion"
    eval [list lappend buttons] $helpButton $backButton
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 450 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "Please include your suggestion below.  You will have a\
      chance to review this information before submitting the request."] \
      [list "var10" " " $ReportInfo(suggestion)] \
      ]]
    
    set ReportInfo(suggestion) [lindex [eval $dialogScript] 0]
    if {![string length [string trim $ReportInfo(suggestion)]]} {
	alertnote "Your suggestion is empty!"
	return [bugzilla::suggestionDetails]
    }
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::suggestionSolution"  --
 # 
 # If the reporter has a possible solution to implement the suggestion, we'll
 # put that in a separate section.
 # 
 # Bugzilla fields:
 # 
 # --  comment (cont.)
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::suggestionSolution {} {
    
    variable backButton
    variable continueHelpTag
    variable dialogTitle
    variable postponeHelpTag
    variable ReportInfo
    
    if {!$ReportInfo(advanced)} {
	return 0
    }
    
    bugzilla::helpButton "Possible Solution"
    eval [list lappend buttons] $helpButton $backButton
    
    set dialogScript [list dialog::make -title $dialogTitle \
      -width 450 \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "" \
      [list "text" "If you know of any possible solutions to implement this \
      suggestion include them here, or simply press 'Continue'"] \
      [list "var10" " " $ReportInfo(rfeFix)] \
      ]]
    
    set ReportInfo(rfeFix) [lindex [eval $dialogScript] 0]
    return 1
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Action Causing Bug ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::actionCausingBug"  --
 # 
 # Assuming the user has already identified an action that caused the bug,
 # we attempt to get a little more information.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::actionCausingBug {} {
    
    variable backButton
    variable backError
    variable continueHelpTag
    variable dialogTitle
    variable postponeHelpTag
    variable ReportInfo
    
    set type $ReportInfo(reportType)
    set Type [string totitle $type]
    set specificAction ""
    
    bugzilla::helpButton "Action That Caused Bug"
    eval [list lappend buttons] $helpButton $backButton
    
    switch -- $ReportInfo(action) {
	"Key-Combination" {
	    if {[info exists ReportInfo(specificKey)]} {
		set specificKey $ReportInfo(specificKey)
	    } else {
		set specificKey ""
	    }
	    set dialogScript [list dialog::make -title $dialogTitle \
	      -width 450 \
	      -ok "Continue" \
	      -okhelptag $continueHelpTag \
	      -cancel "Postpone" \
	      -cancelhelptag $postponeHelpTag \
	      -addbuttons $buttons \
	      [list "" \
	      [list "text" "Please click the \"Set\" button to identify\
	      the specific keyboard shortcut that caused the ${type}.\r"] \
	      [list [list "smallval" "binding"] "Shortcut:" $specificKey] \
	      [list "text" "\r"] \
	      ]]
	    set specificKey [lindex [eval $dialogScript] 0]
	    if {($specificKey ne "")} {
		set specificAction [dialog::specialView::binding $specificKey]
	    }
	    set ReportInfo(specificKey) $specificKey
	}
	"Menu Selection" {
	    set dialogScript [list dialog::make -title $dialogTitle \
	      -width 450 \
	      -ok "Continue" \
	      -okhelptag $continueHelpTag \
	      -cancel "Postpone" \
	      -cancelhelptag $postponeHelpTag \
	      -addbuttons $buttons \
	      [list "" \
	      [list "text" "Which specific menu item caused the ${type}?\r"] \
	      [list "emptyVar"  "" $ReportInfo(specificAction)] \
	      [list "text" "\r"] \
	      ]]
	    set specificAction [lindex [eval $dialogScript] 0]
	}
	"Specific Procedure" {
	    if {[catch {bugzilla::selectProc} specificProc]} {
		error $backError
	    }
	    set dialogScript [list dialog::make -title $dialogTitle \
	      -width 450 \
	      -ok "Continue" \
	      -cancel "Trace This Proc" \
	      -addbuttons $buttons \
	      [list "" \
	      [list "text" "Do you want to perform a trace of\
	      \[$specificProc\]?\r"] \
	      [list "text" "If so, the ${Type} Reporter will be postponed,\
	      and the trace will be set up for you automatically.\
	      You should then perform the action that caused the ${type}.\r\r\
	      The \"Tcl Menu > Tcl Tracing > Stop Tracing\" command will\
	      then create a trace window; after the report has been filed\
	      you can attach a compressed archive of this trace window\
	      to the report via the web interface.\r"] \
	      [list "text" "Press the Continue button to finish creating\
	      the report without starting any tracing routine.\r"] \
	      ]]
	    if {![catch {eval $dialogScript} result]} {
		set specificAction $specificProc
	    } elseif {($result eq "cancel")} {
		bugzilla::traceProc $specificProc
		error "Cancelled."
	    } else {
		error $result
	    }
	}
	default {
	    set dialogScript [list dialog::make -title $dialogTitle \
	      -width 450 \
	      -ok "Continue" \
	      -okhelptag $continueHelpTag \
	      -cancel "Postpone" \
	      -cancelhelptag $postponeHelpTag \
	      -addbuttons $buttons \
	      [list "" \
	      [list "text" "What action caused the ${type}?"] \
	      [list "var5" "" $ReportInfo(specificAction)] \
	      [list "text" "\r"] \
	      ]]
	    set specificAction [lindex [eval $dialogScript] 0]
	}
    }
    set ReportInfo(specificAction) $specificAction
    return 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::selectProc"  -- ?procName? ?intro?
 # 
 # If the previously selected procedure isn't the right one, this dialog
 # includes a "Browse Procs" buttion that calls [procs::pick] to choose from
 # the currently defined options.
 # 
 # If "procName" is supplied, that will be the default text field value.
 # 
 # If "intro" is supplied, that will be included at the top of the dialog.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::selectProc {{procName ""} {intro ""} {helpScript ""}} {
    
    variable ReportInfo
    
    if {($procName ne "")} {
	set ReportInfo(lastSelectedProc) $procName
    } elseif {![info exists ReportInfo(lastSelectedProc)]} {
	set ReportInfo(lastSelectedProc) ""
    }
    # Text for the dialog page.
    set txt0 "Enter the name of an AlphaTcl procedure, or press the\
      \"Browse Procs\" button to navigate lists of those that are\
      currently defined.\r"
    if {($intro eq "")} {
	set intro $txt0
    }
    set txt1 "AlphaTcl Proc:"
    # Create a "Help" button.
    if {($helpScript eq "")} {
	bugzilla::helpButton "Action That Caused Bug"
    } else {
	set helpButton [list "Help" "Click here for more help." $helpScript]
    }
    # Create a "Browse Procs..."  button.
    set browseScript {
	if {![catch {procs::pick} newProc]} {
	    eval [list dialog::valSet $dial [list NAME] $newProc]
	}
    }
    regsub -- {NAME} $browseScript ",$txt1" browseScript
    set browseButton [list "Browse ProcsÉ" \
      "Click this button to browse a list of defined procedures" \
      $browseScript]
    eval [list lappend buttons] $helpButton $browseButton
      
    # Present the dialog, and record the values.
    set result [dialog::make -title "AlphaTcl Procedure" \
      -addbuttons $buttons \
      [list "" \
      [list "text" $intro] \
      [list "var"  $txt1 $ReportInfo(lastSelectedProc)] \
      ]]
    regsub -- "^::" [lindex $result 0] "" procName
    set ReportInfo(lastSelectedProc) "::$procName"
    return $ReportInfo(lastSelectedProc)
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::traceProc"  --  ?procName?
 # 
 # Set up a trace for a specific procedure.  If none is supplied, then we
 # allow the user to select one.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::traceProc {{procName ""}} {
    
    variable ReportInfo
    
    # Make sure that "Tcl" mode exists.
    if {![alpha::package exists "Tcl"]} {
	alernote "Sorry, this function requires \"Tcl\" mode, which\
	  doesn't exist in your installation."
	error "Cancelled."
    }
    # This script is for the "Help" button in [bugzilla::selectProc]
    set helpScript {
	help::openGeneral "Debugging Help" "Tracing Procedures" ;
	set retCode "1" ; set retVal "cancel"
    }
    # If the name of a procedure is supplied, then we use that to create the
    # "Trace Instructions" window and start the trace.  Otherwise, we allow
    # the user to select the name of the procedure.
    if {($procName ne "")} {
	set ReportInfo(tracingProc) $procName
    } else {
	set intro {
	    You have elected to perform a 'stack trace' on an AlphaTcl
	    procedure.  After selecting the procedure, a new window will be
	    created with further instructions.
	}
	regsub -all {\s+} [string trim $intro] { } intro
	append intro "\r"
	bugzilla::selectProc "" $intro $helpScript
	set ReportInfo(tracingProc) $ReportInfo(lastSelectedProc)
    }
    # Make sure that the proc name has been defined/loaded.
    while {![llength [info procs $ReportInfo(tracingProc)]] \
      && ![auto_load $ReportInfo(tracingProc)]} {
	dialog::yesno -y "OK" -c -n "" \
	  "There was a problem loading the procedure" \
	  $ReportInfo(tracingProc) \
	  "Please select a different procedure."
	bugzilla::selectProc $ReportInfo(tracingProc) $helpScript
	set ReportInfo(tracingProc) $ReportInfo(lastSelectedProc)
    }
    # Create the "Trace Instructions" window.
    bugzilla::createTraceWindow
    # Now we start the trace.
    if {[catch {procs::traceProc $ReportInfo(tracingProc)} err]} {
	dialog::alert "There was an error in setting up the trace:" $err
    } else {
	status::msg "Tracing \[$ReportInfo(tracingProc)\] É"
    }
    return
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Report Windows ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::createBugWindow"  --
 # 
 # Using the information we've been assembling, create a new bug report
 # window, add some more system information, and color/hyper it so that the
 # user can edit the relevant bits and then send the report.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::createBugWindow {} {
    
    global alpha::tclversion mode global::features

    variable AlphaApp
    variable BugzillaFields
    variable ReportInfo
    
    set txt {
Bug Report


Please review the following information to ensure its accuracy.

In the "DETAILS" section please explain what you were expecting to happen, as
well as the erroneous behavior that did happen.  Please note that phrases
like "this didn't work" are generally worse than saying nothing at all, and
are unlikely to lead to a proper fix, while including information about any
error messages you might have encountered is extremely helpful.  Please see
the "Known Bugs" help file for more information.  You might find the floating
'Bugzilla Menu' palette useful, click on this hyperlink <<floatBugzillaMenu>>
to create it if it is not on your screen.

Do NOT edit any of the blue "@field :" header names in the BUGZILLA FIELDS
section below, which ensure that bugzilla's web interface works properly.
(You can edit the values within these fields if you are sure that you know
what the correct ones should be, although this should not be necessary, and
if you enter an invalid value the bug report will not be properly filed.)

ALPHA version information will be automatically included in the report.

When you are satisfied with your report, click here <<Send This Report>> to
submit it to Bugzilla over the internet, following the instructions in the
dialog that appears.  Once the report has been filed, you can create an
attachment to it by clicking on this <<bugzilla::createAttachment>>
hyperlink.  Attachments might be image files, traces, or proposed patches.

Thanks for using the Bug Reporter !!

_______________________________________________________________

}
    # Include the email field headers.  These have been set either by
    # using default values assigned above, or in [bugzilla::bugFields].
    append txt "BUGZILLA FIELDS"                        \r\r
    foreach field $BugzillaFields {
	ensureset ReportInfo($field) ""
	if {![string length $ReportInfo($field)]} {
	    continue
	}
	append txt "@[format {%-13s} $field]: $ReportInfo($field)" \r
    }
    append txt \r \
      "BRIEF DESCRIPTION" \r\r \
      $ReportInfo(short_desc) \r\r
    if {[string length $ReportInfo(specificAction)]} {
	append txt "ACTION THAT PRODUCED BUG" \r\r \
	  "$ReportInfo(action): " $ReportInfo(specificAction) \r\r
    }
    append txt "DETAILS" \r\r \
      [breakIntoLines $ReportInfo(details) 77 0] \r\r
    if {[string length $ReportInfo(fix)]} {
	append txt "POSSIBLE SOLUTION" \r\r \
	  [breakIntoLines $ReportInfo(fix) 77 0] \r\r
    }
    if {[string length $ReportInfo(crashInfo)]} {
	append txt "CRASH LOG" \r\r \
	  $ReportInfo(crashInfo) \r\r
    }

    new -n "* Bug Report *" -text $txt

    bugzilla::markColourHyper
    goto [set pos [minPos]]
    setWinInfo -w [win::Current] dirty 0
    bugzilla::floatBugzillaMenu
    hook::register closeHook {bugzilla::unfloatBugzillaMenu} *
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::createRfeWindow"  --
 # 
 # Using the information we've been assembling, create a new RFE report
 # window, and color/hyper it so that the user can edit the relevant bits and
 # then send the report.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::createRfeWindow {} {
    
    variable AlphaApp
    variable BugzillaFields
    variable ReportInfo
    
    set txt {
ALPHA Suggestion


Please review the following information to ensure its accuracy.

If you know of some method for implementing your proposal, you can include it
in this report.  You might find the floating 'Bugzilla Menu' palette useful,
click on this hyperlink <<floatBugzillaMenu>> to create it if it is not on
your screen.

Do NOT edit any of the blue "@field :" header names in the BUGZILLA FIELDS
section below, which ensure that bugzilla's web interface works properly.
(You can edit the values within these fields if you are sure that you know
what the correct ones should be, although this should not be necessary, and
if you enter an invalid value the suggestion will not be properly filed.)

ALPHA version information will be automatically included in the report.

When you are satisfied with your RFE, click here <<Send This Report>> to
submit it to Bugzilla over the internet, following the instructions in the
dialog that appears.
}
    append txt {
Thanks for using the Suggestion Maker !!

_______________________________________________________________

}
    regsub -all -- "ALPHA" $txt $AlphaApp txt
    # Include the email field headers.  These have been set either by
    # using default values assigned above, or in [bugzilla::bugFields].
    append txt "BUGZILLA FIELDS"                        \r\r
    foreach field $BugzillaFields {
	ensureset ReportInfo($field) ""
	if {![string length $ReportInfo($field)]} {
	    continue
	}
	append txt "@[format {%-13s} $field]: $ReportInfo($field)" \r
    }
    append txt \r \
      "BRIEF DESCRIPTION" \r\r \
      $ReportInfo(short_desc) \r\r \
      "SUGGESTION" \r\r \
      [breakIntoLines $ReportInfo(suggestion) 77 0] \r\r
    if {([string trim $ReportInfo(rfeFix)] ne "")} {
	append txt "POSSIBLE SOLUTION" \r\r \
	  [breakIntoLines $ReportInfo(rfeFix) 77 0] \r\r
    }
    
    new -n "* $AlphaApp Suggestion *" -text $txt
    
    bugzilla::markColourHyper
    goto [set pos [minPos]]
    setWinInfo -w [win::Current] dirty 0
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::createTraceWindow"  --
 # 
 # Using the information we've been assembling, create a new window with
 # instructions on completing and sending the trace.  Note that this window
 # is created _before_ the trace has been started, to ensure that procedure
 # called here is not itself traced!  (Called by [bugzilla::traceProc].)
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::createTraceWindow {} {
    
    variable AlphaApp
    variable ReportInfo
    
    # Create the new "Tracing Instructions" window.
    set txt {
Tracing Instructions

You are performing a 'stack trace' on the proc: TRACINGPROC .

This window provides further instructions on completing the trace, and on the
steps that should be taken once the trace is done.

	  	Table of Contents

"# Creating the Trace"
"# 'Dumping' the Trace"
"# Sending the Trace"

<<floatNamedMarks>>


	  	Creating the Trace

The trace has already been started.  All that you need to do is perform the
action that calls this procedure.

To the left of this window you should see a 'floating menu palette' that is
named "Tcl Tracing" -- this is your tracing "console" that can be used to
stop the tracing routine or display the results.  If you don't see this
palette, or if you perhaps accidentally dismissed it, click here

<<bugzilla::floatTracingMenu>>

to make it appear.

	  	'Dumping' the Trace

As soon as you have performed the action, the "Display Traces" button in the
floating palette will be enabled.  This is the sign that the trace buffer is
no longer empty, and you can "dump" its contents into a new window.  You can
now click on the "Stop Tracing" command.

If the trace was not successful, then after you click on "Stop Tracing" you
will receive no further prompts.  This suggests that the trace wasn't
actually performed, i.e. you did not perform an operation that called the
procedure you want.  In this case, click on this hyperlink to try again:

<<bugzilla::traceProc>>

If the trace was successful, after you select the "Stop Tracing" command you
will be asked if you want to "Dump traces" -- your response should be "Yes".
This will create yet another new window, one that contains a the contents of
the "trace buffer," a record of each step of the procedure and how the
interpreter handled the instruction.  This information can be very useful to
the AlphaTcl developer who will inspect the trace log to determine exactly
why an observed bug is encountered.

	  	Sending the Trace

The next steps to take include

(1) Saving this new Tcl Tracing window to your local disk.

In order to attach this file to a bug report, it must first exist as an
actual file somewhere.

(2) Compressing this file as a .sit or .zip archive.

These files can be very large.  Compressing them makes it much easier to send
the trace, and to store it in the Alpha-Bugzilla database.

(3) Attaching it to a pre-existing bug report, or e-mailing it to a developer.

If you have already created a bug report, click on this hyperlink

<<bugzilla::createAttachment>>

to open the report in your local browser, and follow the instructions there
to attach your trace archive.  If you want to create a new report, select the
"Help > Report A Bug" menu item (or click on this <<reportABug>> hyperlink.)

	====================================================================

Questions?  Please ask them on one of the mailing lists described in the
"Mailing Lists" page of the AlphaTcl Wiki:

<http://www.purl.org/net/alpha/wikipages/mail-lists> .

Thanks for your efforts to debug ALPHA to improve it for the next release.
}
    regsub -all {TRACINGPROC} $txt $ReportInfo(tracingProc) txt
    regsub -all {ALPHA} $txt $AlphaApp txt
    set title "* Tracing Instructions *"
    if {[win::Exists $title]} {
	set w $title
	bringToFront $w
	win::setInfo $w read-only 0
	win::setInfo $w dirty 0
	replaceText -w $w [minPos -w $w] [maxPos -w $w] $txt
    } else {
	set w [new -n $title -text $txt -tabsize 4]
    }
    help::markAsAlphaManual -w $w 1
    help::colourTitle -w $w 5
    help::colourMarks -w $w 5 1
    help::hyperiseEmails -w $w 1
    help::hyperiseUrls -w $w 1
    help::hyperiseExtras -w $w 1
    help::colourCodeInserts -w $w 1
    refresh -w $w
    goto -w $w [set pos [minPos -w $w]]
    winReadOnly $w
    # Float the Tracing palette.
    bugzilla::floatTracingMenu
    hook::register closeHook {bugzilla::unfloatTracingMenu} *
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::createTestWindow"  --
 # 
 # Create a test window that will file an "Alpha-Bugzilla / test" report that 
 # can then be filed.
 # 
 # This does not appear in any menu, and is not called by any other code. 
 # Just source [bugzilla::createTestWindow] to test it.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::createTestWindow {} {
    
    variable ReportInfo
    
    if {![info exists ReportInfo(testSummary)]} {
	set ReportInfo(testSummary) \
	  "Why are you creating this test?"
    }
    if {![info exists ReportInfo(testDetails)]} {
	set ReportInfo(testDetails) \
	  "How will you know if the test was successful?"
    }
    
    set dialogScript [list dialog::make -title "Create Test Bug" \
      -width 500 \
      -ok "Create Window" \
      [list "" \
      [list "text" "This dialog will help you create a test report window.\
      It will be for the \"Alpha-Bugzilla\" product, and will only be visible\
      to those who have privileges to see testing bugs.\r"] \
      [list "text" "Enter a brief description of this test."] \
      [list "var"  "Summary:" $ReportInfo(testSummary)] \
      [list "text" "Now describe what you hope to accomplish."] \
      [list "var5" " " $ReportInfo(testDetails)] \
      ]]
    set results [eval $dialogScript]
    set ReportInfo(testSummary) [lindex $results 0]
    set ReportInfo(testDetails) [lindex $results 1]
    set txt {
Test Bug Report

This window is just for beta-testing, to send a "dummy" bug to bugzilla.
Click here <<Send This Report>> to send it.
__________________________________________________________________

BUGZILLA FIELDS

@product      : Alpha-Bugzilla
@component    : test
@version      : 2.18.4
@short_desc   : [SUMMARY]
@bug_severity : normal
@rep_platform : All
@op_sys       : All

BRIEF DESCRIPTION

[SUMMARY]

DETAILS

}
    regsub -all {\[SUMMARY\]} $txt $ReportInfo(testSummary) txt
    append txt [breakIntoLines $ReportInfo(testDetails) 77 0] \r\r
    
    new -n "* Bugzilla Test Report *" -text $txt
    
    bugzilla::markColourHyper
    goto [set pos [minPos]]
    setWinInfo -w [win::Current] dirty 0
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::createAttachment"  --
 # 
 # At present we rely on the web version of Alpha-Bugzilla to create
 # attachments to previously filed bug reports.  We might be able to do this
 # internally, using http-post, but that option needs to be explored.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::createAttachment {} {
    
    global bugzillaHomePage
    
    variable ReportInfo
    
    set url $bugzillaHomePage
    set intro "To create an attachment to an existing bug report,\
      you must enter its identifying number below.\
      A new web browser page will then be opened allowing you\
      to identify the local file and supply a description.\
      \r\rAttachment files might be include images, traces,\
      or proposed patches.  Please compress large files.\r"
    
    bugzilla::helpButton "Creating Attachments"
    set buttons $helpButton
    
    # Present the dialog, and record the values.
    set result [dialog::make -title "Create Bugzilla Attachment" \
      -addbuttons $buttons \
      [list "" \
      [list "text" $intro] \
      [list "var"  "Bug Number:" $ReportInfo(lastBugNumber)] \
      ]]
    set ReportInfo(lastBugNumber) [lindex $result 0]
    append url "attachment.cgi?bugid=" $ReportInfo(lastBugNumber) \
      "&action=enter"
    
    url::execute $url
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::markColourHyper"  --
 # 
 # Mark and color the active window to highlight bugzilla report sections. 
 # This assumes a standard format used for all new report windows.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::markColourHyper {args} {
    
    win::parseArgs w
    
    variable AlphaApp
    
    removeAllMarks -w $w
    catch {removeColorEscapes -w $w}
    
    win::searchAndHyperise -w $w "\"((Known Bugs)|(Readme))\"" \
      {help::openGeneral "\1"}  1 3 +1 -1
    win::searchAndHyperise -w $w "\"@field :\""                 {} 1 1 +1 -1
    win::searchAndHyperise -w $w "^@\[-a-zA-Z0-9_\]+\[\\t \]+:" {} 1 1
    win::searchAndHyperise -w $w "<<Send This Report>>"  "bugzilla::submitReport 1" 1 5
    win::searchAndHyperise -w $w "<<floatBugzillaMenu>>" "floatBugzillaMenu" 1 4
    win::searchAndHyperise -w $w {<<bugzilla::([\w]+)>>} "bugzilla::\\1" 1 4
    help::colourTitle -w $w 5
    help::colourAllCapLines -w $w 5
    help::hyperiseEmails -w $w 1
    help::hyperiseUrls -w $w 1
    refresh -w $w
    # A quick file marking.
    set pos [minPos -w $w]
    while {![catch {search -w $w -f 1 -r 1 -i 0 -s {^[A-Z][-A-Z ]+$} $pos} pp]} {
	set pos0 [lindex $pp 0]
	set pos1 [lindex $pp 1]
	set pos  [nextLineStart -w $w $pos0]
	setNamedMark -w $w [getText -w $w $pos0 $pos1] $pos0 $pos0 $pos0
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::isReportWindow"  --
 # 
 # Attempt to determine if the active window is a report for bugzilla created 
 # by one of the procedures in this package.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::isReportWindow {} {
    
    set pat {^((BUGZILLA FIELDS)|(VERSION INFO))}
    if {![llength [search -n -s -f 1 -r 1 -- $pat [minPos]]]} {
	return 0
    } else {
	return 1
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::submitReport"  --
 # 
 # Verify that the active window is a valid bug report, and if so submit it
 # using the [bugzilla::submitViaHttp] procedure below.  (We could check to
 # see if _any_ of the active windows look like bug reports, but at present
 # we do not.)
 # 
 # If an error is thrown, we go to the extreme step of presenting it to the
 # user in a new window since errors caused by hyperlink code usually just
 # disappear.  (Ideally, [bugzilla::submitViaHttp] never throws an error!)
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::submitReport {fromHyperlink} {
    
    global errorInfo
    
    if {![bugzilla::isReportWindow]} {
	alertnote "Cancelled -- This window does not appear to be a bug report."
    } elseif {![catch {bugzilla::submitViaHttp}]} {
	status::msg "The report has been successfully submitted."
    } elseif {[regexp "^cancel" $errorInfo]} {
	status::msg "Report submission postponed."
    } elseif {$fromHyperlink} {
	error::window $errorInfo
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::submitViaHttp"  --
 # 
 # Submit the bug report by creating a .cgi url that is sent to the browser.
 # This should only be called by a hyperlink or the Alpha Bugzilla menu item,
 # not by other code.  We're assuming that the report window is now in front.
 # 
 # Because extensive comments will create a very long .cgi url that might
 # cause some browsers (or bugzilla itself) to choke, these are placed in the
 # Clipboard for the user to paste into the appropriate form field.
 # 
 # We need to convert all "&5f" strings in the field names to "_" after
 # calling [::http::formatQuery] -- does this represent a bug in bugzilla, or
 # is this "normal" .cgi behavior and thus a bug with the
 # [::http::formatQuery] procedure?
 # 
 # In this procedure, section (7) deals with adding account information.  At
 # present, we use the dummy account method for anonymous reporting.  It is
 # possible for the skillful vandal to use this information for evil rather
 # than good -- we will disable this feature if that occurs.
 # 
 # In section (8) we attempt to deal with some encoding issues.  In versions
 # of the "http" package < 2.5 we have no "-urlEncoding" option for
 # [::http::config].  According to the "http" package documentation, the
 # default "urlEncoding" is "utf-8", but in the MacOS "iso8859-1" seems to
 # work much better.  (It looks like the real default used in the http
 # package is actually "iso8859-1", but we're not taking any chances here.)
 # We first convert the string to unicode from our [encoding system], that
 # seems to be a good safeguard.
 # 
 # Also in http < 2.5, [::http::formatQuery] will throw an error if no
 # "http::formMap" entry exists for an item.  Thus we catch this call.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::submitViaHttp {} {
    
    global bugzillamodeVars bugzillaHomePage tcl_platform \
      alpha::version alpha::tclversion
    
    variable AlphaApp
    variable BugzillaFields
    variable requireRegistration
    variable ReportInfo
    variable RequiredFields
    
    package require http
    
    # (1) Verify that the user is registered.
    if {!$bugzillamodeVars(registeredBugzillaAccount)} {
	bugzilla::checkRegistration
    }
    bugzilla::checkAccountInfo
    if {!$bugzillamodeVars(registeredBugzillaAccount)} {
	set email $bugzillamodeVars(accountName)
	regsub -all {@}  $email { [at] }  email
	regsub -all {\.} $email { [dot] } email
	set comment "Reporter: $email\r\r"
    }
    
    # (2) Tell the user what's going to happen next.
    if {$bugzillamodeVars(submitBugInternally)} {
	set whatHappensNext1 "The bug report will be sent internally.\r"
	set whatHappensNext2 "A new browser window will then be opened\
	  with more information about your submission.\r"
	set ok "Submit Report"
	set okhelptag "Click here to submit the report."
    } else {
	set whatHappensNext1 "You can then complete the submission by pressing\
	  the \"Commit\" button found in the form found in the web page\
	  that will be opened in your browser.\r"
	set whatHappensNext2 "IMPORTANT: The \"comments\" section will be\
	  placed in the Clipboard, and you will have to paste that yourself\
	  into the appropriate text field.\
	  (It's too long to send any other way.)"
	set ok "Send To Browser"
	set okhelptag "Click here to open a browser report window."
    }
    set dialogScript [list dialog::make -title "Sending Bug Report" \
      -width "450" \
      -ok $ok \
      -okhelptag $okhelptag \
      -cancel "Postpone" \
      -cancelhelptag "Click here to postpone the report submission." \
      -addbuttons [list \
      "Help" \
      "Click here to cancel the submission and obtain more information." \
      {bugzilla::helpWindow "Sending The Report"}] \
      [list "" \
      [list "text" "After you press the \"Submit Report\" button\
      in this dialog, the information from the report window\
      will be compiled and sent to the Alpha-Bugzilla database.\
      An active internet connection is thus required.\r"] \
      [list "text" $whatHappensNext1] \
      [list "text" $whatHappensNext2]]]
    eval $dialogScript
    status::msg "Please wait: compiling bug reportÉ"
    
    # (3) Put some defaults in place.  These might be over-ridden by
    # information in the report window.
    array set windowInfo [list \
      "bug_severity"    "normal" \
      "priority"        "P2" \
      ]
    if {0 && !$bugzillamodeVars(registeredBugzillaAccount)} {
	set windowInfo(cc) $bugzillamodeVars(accountName)
    }
    
    # (4) Scan the report for the bugzilla field names/values.  "pos"
    # represents the moving start for the iterative search.
    set pos [minPos]
    while {1} {
	set pat {^@([-a-zA-Z0-9_]+) *: *([^\r\n]+)$}
	if {![llength [set pp [search -n -f 1 -r 1 $pat $pos]]]} {
	    break
	}
	regexp $pat [eval getText $pp] -> fieldName fieldValue
	set windowInfo($fieldName) $fieldValue
	set pos [pos::nextLineStart [lindex $pp 1]]
    }
    append comment [string trim [getText $pos [maxPos]]]
    # Set the "bug_status" field.
    if {($windowInfo(bug_severity) eq "enhancement")} {
	set windowInfo(bug_status) "NEW"
    } else {
	set windowInfo(bug_status) "UNCONFIRMED"
    }
    
    # (5) Create the footer for the report.
    if {!$ReportInfo(packageInfoSet)} {
	bugzilla::setPackageInfo
    }
    append footer \r\r "VERSION INFORMATION" \r\r \
      "  " $AlphaApp " " $alpha::version \
      " (" $tcl_platform(platform) ", " $tcl_platform(os) ")," \
      " with Tcl " [info patchlevel] " and AlphaTcl " $alpha::tclversion \r\r \
      $ReportInfo(lastBuild) \r\r
    if {($windowInfo(bug_severity) ne "enhancement")} {
	if {($ReportInfo(originalMode) ne "")} {
	    append footer "Mode of active window :" \r\r "  " \
	      $ReportInfo(originalMode)
	    if {![catch {alpha::package versions $ReportInfo(originalMode)} vn]} {
	        append footer ", version $vn"
	    }
	    append footer \r\r $ReportInfo(modePackages) \r\r
	} else {
	    append footer "Mode: (none / no active window)" \r\r
	}
	append footer $ReportInfo(globalMenus) \r\r \
	  $ReportInfo(globalFeatures) \r\r $ReportInfo(alwaysOnPkgs) \r\r \
	  $ReportInfo(autoLoadPkgs) \r\r $ReportInfo(ssFiles) \r\r \
	  "SYSTEM ENVIRONMENT" \r [global::listEnvironment] \r\r
    }
    append footer "This report was generated by ${AlphaApp}'s " \
      "\"Report A Bug\" package.\r" \
      "\(version [alpha::package versions reportABug] ; "
    if {$bugzillamodeVars(submitBugInternally)} {
	append footer "submitted internally using http-post\)"
    } else {
	append footer "submitted via web-interface\)"
    }
    append comment $footer
    
    # (6) Add all of the report information to a "queryList" for formatting.
    if {$bugzillamodeVars(submitBugInternally)} {
	lappend queryList "comment" $comment
    } else {
	lappend queryList "comment" "The \"comments\" text was too long to insert\
	  into this field automatically, and was instead put in the Clipboard.\
	  \r\rJust paste it in here."
	putScrap $comment
    }
    foreach fieldName $BugzillaFields {
	if {([lsearch $RequiredFields $fieldName] > -1)} {
	    # Check for required fields.
	    if {![info exists windowInfo($fieldName)]} {
		alertnote "The report window does not contain a field for\
		  \"${fieldName}\" -- this is a fatal error.  You should\
		  run through \"Help > Report a bug\" again to re-create\
		  a window with the proper fields added."
		status::msg "Cancelled."
		return
	    } elseif {![string length $windowInfo($fieldName)]} {
		alertnote "No value was given for the field\
		  \"${fieldName}\" -- this is a fatal error.  You should\
		  run through \"Help > Report a bug\" again to re-create\
		  a window with the proper fields added."
		status::msg "Cancelled."
		return
	    }
	}
	if {[info exists windowInfo($fieldName)] \
	  && [string length $windowInfo($fieldName)]} {
	    lappend queryList $fieldName $windowInfo($fieldName)
	}
    }
    
    # (7) Deal with account information.
    if {$requireRegistration || $bugzillamodeVars(registeredBugzillaAccount)} {
	lappend queryList \
	  "reporter"            $bugzillamodeVars(accountName) \
	  "Bugzilla_login"      $bugzillamodeVars(accountName) \
	  "Bugzilla_password"   $bugzillamodeVars(accountPassword)
    } else {
	# Attempt to send it anonymously?
	lappend queryList "reporter" "alphauser@users.sourceforge.net"  "Bugzilla_login" "alphauser@users.sourceforge.net" "Bugzilla_password" [string trim [namespace current] ":"]
    }
    
    # (8) Format, and convert all "&...%5f" strings in the field names to
    # "_", and "%2d" to "-".  (See notes above re encoding issues.)
    for {set i 0} {($i < [llength $queryList])} {incr i} {
	set oldString [lindex $queryList $i]
	set newString [encoding convertfrom [encoding system] $oldString]
	set queryList [lreplace $queryList $i $i $newString]
    }
    set urlEncoding "iso8859-1"
    if {![catch {package require http 2.5}]} {
	::http::config -urlencoding $urlEncoding
    } else {
	for {set i 0} {($i < [llength $queryList])} {incr i} {
	    set oldString [lindex $queryList $i]
	    set newString [encoding convertto $urlEncoding $oldString]
	    set queryList [lreplace $queryList $i $i $newString]
	}
    }
    if {[catch {eval ::http::formatQuery $queryList} query]} {
	dialog::alert "Sorry, this bug report cannot be sent by\
	  ${alpha::application} in its current form.\
	  The error is most likely associated with the inclusion of\
	  \"high-bit\" characters -- you might try removing them and\
	  trying again.\r\rError message: $query"
	error "cancel"
    }
    regsub -all {(&\w+)%5f(\w+=)} $query {\1_\2} query
    regsub -all {(&\w+)%2d(\w+=)} $query {\1-\2} query
    
    # (9) Find out if our "bugzillaHomePage" url is redirected.
    set bugzillaUrl [bugzilla::getRedirectUrl $bugzillaHomePage]
    # (10) Send the report .cgi url using the desired method.
    if {!$bugzillamodeVars(submitBugInternally)} {
	# Fill in forms in an "Enter Bug" web page using a browser.
	append bugzillaEnterUrl $bugzillaUrl "enter_bug.cgi?" $query
	url::execute $bugzillaEnterUrl
    } else {
	# Send using the http package rather than a web browser.
	status::msg [set msg "Please wait: submitting bug reportÉ"]
	watchCursor
	append bugzillaPostUrl $bugzillaUrl "post_bug.cgi?"
	# Now we submit our bug.
	if {[catch {::http::geturl $bugzillaPostUrl -query $query} token]} {
	    dialog::alert "Error:\r\r$token"
	    return
	}
	set html [::http::data $token]
	::http::cleanup $token
	status::msg "$msg done"
	# Now display the results to the user.  Use the local browser instead
	# of the WWW Menu?  (Use [htmlView $f] instead of [url::execute...]?)
	regsub -nocase -- {<HEAD>} $html \
	  "<HEAD><BASE HREF=\"${bugzillaUrl}\">" html
	set f [temp::unique reportABug "postBugResults" ".html"]
	file::writeAll $f $html 1
	catch {setFileInfo $f creator ""}
	if {[catch {file::sendToBrowser $f}] \
	  && [catch {htmlView $f}] \
	  && [catch {file::openInDefault $f}]} {
	    edit -c -r $f
	}
    }
    return
}

proc bugzilla::getRedirectUrl {url {recursions 10}} {
    
    set count 0
    set tokens [list]
    set ncodes [list "301" "302" "303" "305" "307"]
    while {($count < $recursions)} {
	incr count
	unset -nocomplain metaFields
	# Is this a redirected url?
	if {[catch {::http::geturl $url -validate 1} token]} {
	    dialog::alert "Error:\r\r$token"
	    error "Cancelled -- $token"
	}
	lappend tokens $token
	if {([lsearch $ncodes [::http::ncode $token]] == -1)} {
	    break
	}
	array set metaFields [lindex [array get $token "meta"] 1]
	if {[info exists metaFields(Location)]} {
	    set url $metaFields(Location)
	} else {
	    break
	}
    }
    foreach token $tokens {
	::http::cleanup $token
    }
    return $url
}


# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Alpha Bugzilla menu ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "namespace eval bugzilla"  --
 # 
 # More package specific variables, but mainly for the menu.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval bugzilla {
    
    # Bugzilla Menu Vars
    
    variable hookRegistered 0
    
    # Bugzilla dialog vars.
    variable  searchBugzilla
    array set searchBugzilla {
	txt  ""
	opt1 "substring"
	opt2 "All"
	opt3 "All"
	pln  "0"
    }
    variable summaryLists
    array set summaryLists {
	product   "0 1 0 0 0 0 0"
	bugStatus "Open"
	plain     "0"
	bugType   "All"
	sortBy    "Bug Number"
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::buildMenu"  --
 # 
 # Return the list of items needed by [menu::buildSome].
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::buildMenu {} {
    
    global bugzillamodeVars
    
    variable crashLog
    variable hookRegistered
    
    lappend menuList reportABugÉ reportACrashÉ makeASuggestionÉ (-) \
      markWindow sendThisReportÉ (-)
    if {[file exists $crashLog]} {
	lappend menuList reviewCrashLog insertLastCrashInfoÉ \
	  deleteCrashLogÉ (-)
    }
    lappend menuList  bugzillaHome createAccount queryPage \
      searchBugsForÉ summaryBugListsÉ (-) \
      goToBugÉ createAttachmentÉ createNewTraceÉ (-) \
      bugzillaPrefsÉ bugzillaHelp
    
    if {$bugzillamodeVars(registeredBugzillaAccount)} {
	set idx [lsearch $menuList "createAccount"]
	set menuList [lreplace $menuList $idx $idx]
    }
    
    set openWindowItems [list "markWindow" "sendThisReportÉ"]
    if {[file exists $crashLog]} {
	lappend openWindowItems "insertLastCrashInfoÉ"
    }
    if {!$hookRegistered} {
	foreach item $openWindowItems {
	    hook::register requireOpenWindowsHook \
	      [list "Alpha Bugzilla" $item] 1
	}
	set hookRegistered 1
    }
    return [list build $menuList {bugzilla::menuProc}]
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::rebuildMenu"  --
 # 
 # Just a little shortcut to make it easier to rebuild the menu without
 # having to deal with the presence of "args".
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::rebuildMenu {args} {
    
    menu::buildSome "Alpha Bugzilla"
    if {[llength $args]} {
	status::msg "The \Alpha-Bugzilla\" menu has been rebuilt."
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::menuProc"  --
 # 
 # We don't use [::http::formatQuery] here because some of our fields have
 # '-' in their names that will be improperly converted.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::menuProc {menuName itemName} {
    
    global alpha::platform bugzillaHomePage
    
    package require http
    
    variable AlphaApp
    variable crashLog
    variable ReportInfo
    
    set url $bugzillaHomePage
    
    switch $itemName {
	"bugzillaHelp" {
	    package::helpWindow reportABug
	    return
	}
	"bugzillaPrefs" {
	    prefs::dialogs::packagePrefs "bugzilla"
	    return
	}
	"createAccount" {
	    append url "createaccount.cgi"
	}
	"createAttachment" {
	    bugzilla::createAttachment
	    return
	}
	"createNewTrace" {
	    bugzilla::traceProc
	    return
	}
	"deleteCrashLog" {
	    set q "Do you want to remove the entire $AlphaApp \"crash log\"?\
	      This cannot be undone."
	    if {![file exists $crashLog]} {
		set msg "The $AlphaApp \"crash log\" doesn't exist."
	    } elseif {[askyesno $q]} {
		file delete -force $crashLog
		set msg "The $AlphaApp \"crash log\" has been deleted."
	    } else {
		set msg "Cancelled."
	    }
	    bugzilla::rebuildMenu
	    status::msg $msg
	    return
	}
	"insertLastCrashInfo" {
	    bugzilla::parseCrashLog
	    if {![string length $ReportInfo(crashInfo)]} {
		status::msg "The $AlphaApp \"crash log\" is empty."
		return
	    }
	    set q "The last $AlphaApp \"crash log\" entry is dated\
	      \r\r$ReportInfo(crashTime)\
	      \r\rDo you want to insert this entry into the active window?"
	    if {![askyesno $q]} {
		set msg "Cancelled."
	    } else {
		set currentLine [getText [pos::lineStart] [pos::lineEnd]]
		if {[string length [string trim $currentLine]]} {
		    goto [pos::nextLineStart]
		    set t "\r"
		}
		append t "CRASH LOG" "\r\r" $ReportInfo(crashInfo) "\r"
		set p [getPos]
		insertText $t
		goto $p
		bugzilla::markColourHyper
		set msg "The entry for the last crash has been inserted."
	    }
	    status::msg $msg
	    return
	}
	"goToBug" {
	    append url "show_bug.cgi?"
	    set p "Enter a bug number:"
	    set bugNumber [prompt $p $ReportInfo(lastBugNumber)]
	    while {![regexp {^[0-9]+$} $bugNumber]} {
		set p "'$bugNumber' is not a natural numberÉ"
		set bugNumber [prompt $p $bugNumber]
	    }
	    set ReportInfo(lastBugNumber) $bugNumber
	    append url "id=" $ReportInfo(lastBugNumber)
	}
	"makeASuggestion" {
	    bugzilla::makeASuggestion
	    return
	}
	"markAndColor" - "markWindow" {
	    if {![bugzilla::isReportWindow]} {
		set msg "Cancelled --\
		  This window does not appear to be a bug report."
	    } else {
		bugzilla::markColourHyper
		set msg "The \"Marks\" pop-up menu in the side-bar\
		  provides easy navigation of this window."
	    }
	    status::msg $msg
	    return
	}
	"reportABug" {
	    bugzilla::reportABug
	    return
	}
	"reportACrash" {
	    bugzilla::reportACrash
	    return
	}
	"reviewCrashLog" {
	    if {![file exists $crashLog]} {
		set msg "The $AlphaApp \"crash log\" is empty."
	    } else {
		bugzilla::parseCrashLog
		edit -c -r -mode "Text" $crashLog
		goto $ReportInfo(lastCrashPos)
		insertToTop
		set msg "This is the entry for the last crash."
	    }
	    status::msg $msg
	    return
	}
	"queryPage" {
	    append url "query.cgi"
	}
	"searchBugsFor" {
	    variable searchBugzilla
	    variable Products
	    foreach item [list "txt" "opt1" "opt2" "opt3" "pln"] {
		set $item $searchBugzilla($item)
	    }
	    set title  "Search bugs for ..."
	    set opts1  [list "substring" "any words" "regexp"]
	    set opts2  [list "All" "Open" "New"]
	    set opts3  [concat "All" $Products]
	    set     d1 [list dialog::make -title $title]
	    set     d2 [list " "]
	    lappend d2 [list var "Search string:" $txt]
	    lappend d2 [list [list "menu" $opts1] "Search option:" $opt1]
	    lappend d2 [list [list "menu" $opts2] "Bug status:   " $opt2]
	    lappend d2 [list [list "menu" $opts3] "Products:     " $opt3]
	    lappend d2 [list flag "Plaintext bug list" $pln]
	    set values [eval $d1 [list $d2]]
	    set searchBugzilla(txt)  [lindex $values 0]
	    set searchBugzilla(opt1) [lindex $values 1]
	    set searchBugzilla(opt2) [lindex $values 2]
	    set searchBugzilla(opt3) [lindex $values 3]
	    set searchBugzilla(pln)  [lindex $values 4]
	    set txt [quote::Url $searchBugzilla(txt)]
	    regsub -all -- {\s+} $searchBugzilla(opt1) "" opt1
	    append url "buglist.cgi?" \
	      "&value0-0-0=$txt" \
	      "&value0-0-1=$txt" \
	      "&type0-0-0=$opt1" \
	      "&type0-0-1=$opt1" \
	      "&field0-0-0=short_desc" \
	      "&field0-0-1=longdesc" \
	      "&order=Bug+Number"
	    switch -- $searchBugzilla(opt2) {
		"Open" {
		    append url \
		      "&bug_status=UNCONFIRMED" \
		      "&bug_status=NEW" \
		      "&bug_status=ASSIGNED" \
		      "&bug_status=REOPENED"
		}
		"New" {
		    append url \
		      "&bug_status=UNCONFIRMED" \
		      "&bug_status=NEW"
		}
	    }
	    if {($searchBugzilla(opt3) != "All")} {
		set p [quote::Url $searchBugzilla(opt3)]
		append url "&product=${p}"
	    }
	    if {$searchBugzilla(pln)} {
		append url "&plaintext=on"
	    }
	}
	"sendThisReport" {
	    bugzilla::submitReport 0
	    return
	}
	"summaryBugLists" {
	    append url "buglist.cgi?"
	    # Obtain previously set values for the dialog.
	    variable summaryLists
	    set products [list "All" "AlphaTcl" "Alpha" "Alphatk" \
	      "Alpha-Bugzilla" "Online Tools" "TclAE"]
	    foreach item [list product bugStatus bugType sortBy plain] {
		set $item $summaryLists($item)
	    }
	    # Create and present the dialog.
	    set title "Summary bug lists"
	    set opts1 [list "All" "Open" "New"]
	    set opts2 [list "All" "Bugs Only" "RFEs Only"]
	    set opts3 [list "Bug Number" "Severity" "Assignee"]
	    set   d1  [list dialog::make -title $title]
	    set   d2  [list " " [list text "$title for which products?"]]
	    for {set i 0} {$i < 7} {incr i} {
		lappend d2 [list flag [lindex $products $i] \
		  [lindex $product $i]]
	    }
	    lappend d2 [list "divider" "divider"]
	    lappend d2 [list [list "menu" $opts1] "Bug Status:" $bugStatus]
	    lappend d2 [list [list "menu" $opts2] "Bug Type:" $bugType]
	    lappend d2 [list [list "menu" $opts3] "Sort By:" $sortBy]
	    lappend d2 [list flag "Plaintext bug list" $plain]
	    set values [eval $d1 [list $d2]]
	    # Remember some of the values for the next round.
	    set product   [lrange $values 0 6]
	    set bugStatus [lindex $values 7]
	    set bugType   [lindex $values 8]
	    set sortBy    [lindex $values 9]
	    set plain     [lindex $values 10]
	    foreach item [list product bugStatus bugType sortBy plain] {
		set summaryLists($item) [set $item]
	    }
	    # Create the url based on the new values.
	    set queryList ""
	    if {[lindex $values 0]} {
		append queryList \
		  "&field0-0-0=product" \
		  "&field0-0-1=component"
	    } else {
		for {set i 1} {$i <= 6} {incr i} {
		    if {[lindex $values $i]} {
			set p [quote::Url [lindex $products $i]]
			append queryList "&product=${p}"
		    }
		}
	    }
	    if {![string length $queryList]} {
		status::msg "Cancelled -- no product chosen."
		return
	    }
	    append url [string trimleft $queryList "&"]
	    switch -- $bugStatus {
		"Open" {
		    append url \
		      "&bug_status=UNCONFIRMED" \
		      "&bug_status=NEW" \
		      "&bug_status=ASSIGNED" \
		      "&bug_status=REOPENED"
		}
		"New" {
		    append url \
		      "&bug_status=UNCONFIRMED" \
		      "&bug_status=NEW"
		}
	    }
	    switch -- $bugType {
		"Bugs Only" {
		    append url \
		      "&bug_severity=blocker" \
		      "&bug_severity=critical" \
		      "&bug_severity=major" \
		      "&bug_severity=normal" \
		      "&bug_severity=minor" \
		      "&bug_severity=trivial"
		}
		"RFEs Only" {
		    append url \
		      "&bug_severity=enhancement"
		}
		"FAQs Only" {
		    append url \
		      "&bug_severity=faq"
		}
	    }
	    switch -- $sortBy {
		"Bug Number" {
		    append url "&order=bugs.bug_id"
		}
		"Severity" {
		    append url "&order=bugs.bug_severity,bugs.bug_id"
		}
		"Assignee" {
		    append url "&order=map_assigned_to.login_name,bugs.bug_id"
		}
	    }
	    if {$plain} {
		append url "&plaintext=on"
	    }
	}
	"updateBugzillaProductVersion" {
	    set p "Choose a product:"
	    set L [list "AlphaTcl"]
	    set products [list Alpha AlphaTcl AlphaTk TclAE]
	    set product  [listpick -p $p -L $L $products]
	    append url "editversions.cgi?product=$product"
	}
    }
    url::execute $url
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::floatBugzillaMenu"  --
 # 
 # Turn the Alpha-Bugzilla menu into a floating palette.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::floatBugzillaMenu {} {
    
    global defTop defWidth
    
    variable floatingMenuID
    
    bugzilla::rebuildMenu
    set t $defTop
    set l [expr {$defWidth + 20}]
    catch {unfloat $floatingMenuID(Bugzilla)}
    catch {
	set floatingMenuID(Bugzilla) [float -m "Alpha Bugzilla" -t $t -l $l]
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::unfloatBugzillaMenu"  --
 # 
 # Registered as a "closeHook" when a new Bug Report window is opened, and
 # called after the window has been killed.  We close the floating menu if
 # there are no other bug report windows opened.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::unfloatBugzillaMenu {winName} {
    
    variable floatingMenuID
    
    foreach w [winNames] {
	if {[string match "* Bug Report *" $w]} {
	    return
	}
    }
    catch {unfloat $floatingMenuID(Bugzilla)}
    hook::deregister closeHook {bugzilla::unfloatBugzillaMenu} *
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::floatTracingMenu"  --
 # 
 # Float the "Tcl Tracing" menu palette.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::floatTracingMenu {} {
    
    global defTop defWidth
    
    variable floatingMenuID
    
    if {![alpha::package exists "Tcl"]} {
	alernote "Sorry, this function requires \"Tcl\" mode, which\
	  doesn't exist in your installation."
	error "Cancelled."
    }
    loadAMode "Tcl"
    menu::buildSome "tclMenu"
    set t $defTop
    set l [expr {$defWidth + 20}]
    catch {unfloat $floatingMenuID(Tracing)}
    catch {
	set floatingMenuID(Tracing) [float -m "tclTracing" -t $t -l $l]
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "bugzilla::unfloatBugzillaMenu"  --
 # 
 # Registered as a "closeHook" when a new Bug Report window is opened, and
 # called after the window has been killed.  We close the floating menu if
 # there are no other bug report windows opened.
 # 
 # --------------------------------------------------------------------------
 ##

proc bugzilla::unfloatTracingMenu {winName} {
    
    global Tcl::inTracing
    
    variable floatingMenuID
    
    foreach w [winNames] {
	if {[string match "*Tracing Instructions*" $w]} {
	    return
	}
    }
    if {[info exists Tcl::inTracing] && ${Tcl::inTracing}} {
	dumpTraces
    }
    catch {unfloat $floatingMenuID(Tracing)}
    hook::deregister closeHook {bugzilla::unfloatTracingMenu} *
    return
}

# ===========================================================================
# 
# .