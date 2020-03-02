## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "prefsDialogs.tcl"
 #                                          created: 02/15/2006 {04:36:17 PM}
 #                                      last update: 05/16/2006 {01:04:21 PM}
 # Description:
 # 
 # Creates dialogs allowing the user to change preference settings.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #  
 # Copyright (c) 1997-2006  Pete Keleher, Vince Darley, Johan Linde,
 #                          Lars Hellstršm, Craig Barton Upright,
 #                          and many other AlphaTcl developers.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # All rights reserved.
 # 
 # ==========================================================================
 ##

proc prefsDialogs.tcl {} {}

namespace eval prefs::dialogs {
    variable variablesSet
    if {![info exists variablesSet]} {
	set variablesSet 0
    }
    # Used to determine the initial "Helper Applications" dialog.
    variable helperAppsDialog
    if {![info exists helperAppsDialog]} {
        set helperAppsDialog "basic"
    }
    # This is always saved.
    prefs::modified helperAppsDialog
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::setVariables" --
 # 
 # Define the boundaries for standard Prefs dialogs, including the height,
 # width, and the number of flag columns that should be used.  We call this
 # immediately after defining it, i.e. the first time that this file is
 # sourced.  We might also want to call it each time the user changes the
 # screen resolution.
 # 
 # While we could create all of these in the [namespace eval ...]  above, we
 # have this procedure so that AlphaTcl code outside of this file will always
 # have access to them.
 # 
 # Returns a six-item list containing
 # 
 # "standardHeight" --
 # 
 # A "prefs::" variable used by the prefs dialogs.  We have a minimum here
 # for extremely small monitors.
 # 
 # "standardWidth" --
 # 
 # A "prefs::" variable used by the prefs dialogs.  The initial value is
 # based on "standardHeight".  This will serve as the maximum width we'll
 # use, but then we'll trim it down based on how many columns will be able to
 # fit in this width, and add padding.
 # 
 # The "padding" is currently based on platform -- Alphatk uses "pager"
 # dialogs, with panes listed in a separate column, so we make a special
 # allowance for that.  (We might want a separate variable to indicate that
 # "pager" styles are available.)
 # 
 # "flagColumns"
 # 
 # A "prefs::" variable used by the prefs dialogs.  There's no reason to
 # include more than 3 columns, because the dialog will be too wide for the
 # text-edit fields used in "var" preferences.
 # 
 # "listboxAvailable"
 # 
 # On Alphatk and newer versions of Alpha (>= 8.1a1) we support a more
 # user-friendly style of multi-pane dialog with a listbox to select the
 # right pane.  Provided we actually have multiple panes, we use that if it
 # is available.  (Single-pane dialogs which will wrap into multiple panes
 # due to discretionary handling tend to look nicer with the popup menu
 # pane-selector, so we don't worry about that issue here.)
 # 
 # If the Alpha* core's version of [dialog] allows for "listbox" creation,
 # then this is "1", otherwise "0".
 # 
 # "listboxOffset"
 # 
 # When listbox dialogs are used, the width needs to be increased by this
 # amount.  This value might vary depending on platform.
 # 
 # "tooltipAvailable"
 # 
 # If the Alpha* core's version of [dialog] automatically includes tooltip 
 # tags (formerly balloon help), then this is "1", otherwise "0".
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::setVariables {{reset "0"}} {
    
    global alpha::macos alpha::platform screenHeight flagPrefs varPrefs
    
    variable flagColumns
    variable listboxAvailable
    variable listboxOffset
    variable standardHeight
    variable standardWidth
    variable tooltipAvailable
    variable variablesSet
    
    if {$variablesSet && !$reset} {
	return [list $standardHeight $standardWidth $flagColumns \
	  $listboxAvailable $listboxOffset $tooltipAvailable]
    }
    
    # Set the "flagWidth" variable.
    switch -- $alpha::macos {
	"0" {set flagWidth 200}
	"1" {set flagWidth 225}
	"2" {set flagWidth 250}
    }
    # Set the "standardHeight" variable.
    set standardHeight [expr {round($screenHeight * .5)}]
    if {($standardHeight < 350)} {
	set standardHeight 350
    }
    # Set the initial "standardWidth" variable.
    set standardWidth [expr {int($standardHeight * 1.618)}]
    # Set the "flagColumns" variable.
    set flagColumns [expr {$standardWidth / $flagWidth}]
    if {($flagColumns > 3)} {
	set flagColumns 3
    }
    # Do our final calculation for the width, adding some extra padding.
    if {(${alpha::platform} eq "alpha")} {
	set padding 25
    } else {
	set padding 100
    }
    set standardWidth [expr {$padding + ($flagColumns * $flagWidth)}]
    set listboxAvailable \
      [alpha::package vsatisfies -loose [dialog::coreVersion] 2.0]
    # This might need to be adjusted according to platform.
    set listboxOffset "150"
    # Probably the same as "listboxAvailable", but just in case we need a
    # more sophisticated test later...
    set tooltipAvailable \
      [alpha::package vsatisfies -loose [dialog::coreVersion] 2.0]
    # Return all of the variables we've created.
    set variablesSet 1
    return [list $standardHeight $standardWidth $flagColumns \
      $listboxAvailable $listboxOffset $tooltipAvailable]
}

# Call this now so that all of the procedures in this file will know that 
# these variables have been created.
prefs::dialogs::setVariables

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::menuProc" --
 # 
 # The menu handling procedure for most of the "Config" menu items that deal 
 # with preferences.
 # 
 # (If the "Config" menu was its own separate package, we would just include
 # this procedure there and handle the items with the procedures found in
 # this file.)
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::menuProc {menuName itemName} {
    
    global flagPrefs varPrefs PREFS
    
    variable helperAppsDialog
    
    if {($menuName eq "globalSetup")} {
	switch -- $itemName {
	    "menus" {
		prefs::dialogs::globalMenusFeatures "menus"
	    }
	    "features" {
		prefs::dialogs::globalMenusFeatures "features"
	    }
	    "fileMappings" - "suffixMappings" {
		prefs::dialogs::fileMappings
	    }
	    "arrangeMenus" {
		prefs::dialogs::arrangeMenus
	    }
	    "helperApplications" {
		if {($helperAppsDialog eq "basic")} {
		    prefs::dialogs::helperApplications
		} else {
		    prefs::dialogs::externalHelpers
		}
	    }
	    default {
		;namespace eval ::global $itemName
	    }
	}
	return
    } elseif {($menuName eq "preferences")} {
	# The "Config > Preferences" menu.
	regsub -all {[\s+\-]} [string tolower $itemName] "" itemname
	switch -- $itemname {
	    "allglobalpreferences" - "globalpreferences" - "allpreferences" {
		prefs::dialogs::globalPrefs
	    }
	    "interfacepreferences" {
		prefs::dialogs::globalPrefs "Interface Preferences"
	    }
	    "inputoutputpreferences" {
		prefs::dialogs::globalPrefs "Input-Output Preferences"
	    }
	    "systempreferences" {
		prefs::dialogs::globalPrefs "System Preferences"
	    }
	    "packagepreferences" {
		prefs::dialogs::packagePrefs "allPackages"
	    }
	    "viewsavedsetting" {
		prefs::viewSavedSetting
	    }
	    "removesavedsetting" {
		prefs::removeSavedSetting
	    }
	    "searchforsetting" {
		prefs::searchForSetting
	    }
	    "savepreferencesnow" {
		prefs::saveNow
	    }
	    "editprefsfile" {
		prefs::editPrefsFile
	    }
	    "showprefsfolder" {
		file::showInFinder $PREFS
	    }
	    "edituserpackages" {
		set userPackages [file join $PREFS "User Packages"]
		if {![file exists $userPackages]} {
		    if {[dialog::yesno "You currently haven't added any extra\
		      packages.  Would you like to create an empty directory\
		      to contain some?"]} {
			file mkdir $userPackages
			close [open [file join $userPackages \
			  "Place new packages here.txt"] w]
		    } else {
			return
		    }
		}
		file::showInFinder $userPackages
		return
	    }
	    default {
		# Check for a specific preferences pane.
		if {[info exists flagPrefs($itemName)] \
		  || [info exists varPrefs($itemName)]} {
		    prefs::dialogs::globalPrefs $itemName
		    return
		}
		# Check for a procedure defined for this item.
		foreach ns [list "::" "::global::" "::prefs::"] {
		    set procName "${ns}${itemName}"
		    if {[llength [info procs $procName]] \
		      || [auto_load $procName]} {
			return [$procName]
		    }
		}
		# Still here?
		error "Cancelled -- unknown menu item: $itemName"
	    }
	}
    } elseif {[regexp {Mode Prefs$} $menuName]} {
	if {![llength [winNames -f]]} {
	    alertnote "Cancelled -- Mode operations require a current mode,\
	      and hence an active window."
	    return
	}
	regsub -all {[\s+\-]} [string tolower $itemName] "" itemname
	switch -- $itemname {
	    "preferences" {
		prefs::dialogs::modePrefs
	    }
	    "loadprefsfile" {
		mode::sourcePrefsFile
	    }
	    "describemode" {
		mode::describe
	    }
	    "changemode" {
		mode::changeDialog
	    }
	    default {
		;namespace eval ::mode $itemName
	    }
	}
	return
    }
    
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Config > Global Setup ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::globalMenusFeatures" -- types
 # 
 # Present a dialog where "types" is either "menus" or "features", allowing
 # the user to change the global set-up.  All changes are saved between
 # editing sessions by [package::makeOnOrOff].  The "Help" button will call
 # [prefs::dialogs::packagesHelp] and open any available windows, and then return to
 # the original dialog.
 # 
 # There are at least two pages (panes) here, for Global and "Mode Specific"
 # packages.  If the user has balloon help available, we construct the dialog
 # with "multiflag" checkboxes using our own "discretionary" page handling.
 # Otherwise, we include all package descriptions with the items, each of
 # which is then presented in a separate row.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::globalMenusFeatures {types} {
    
    global global::features
    
    if {($types ne "menus") && ($types ne "features")} {
	error "Must supply 'menus' or 'features'"
    }
    watchCursor
    set Types [string totitle $types]
    # Collect the list of global and mode-specific menus/features.
    set alwaysOn   [alpha::listAlphaTclPackages "always-on"]
    set autoLoad   [alpha::listAlphaTclPackages "auto-loading"]
    set invalid    [alpha::listAlphaTclPackages "invalid"]
    set globalPkgs [alpha::listAlphaTclPackages "${types}-global"]
    set globalPkgs [lremove $globalPkgs $alwaysOn $autoLoad $invalid]
    set modePkgs   [alpha::listAlphaTclPackages "${types}-mode"]
    set modePkgs   [lremove $modePkgs $globalPkgs $alwaysOn $autoLoad $invalid]
    set allPkgs    [concat $globalPkgs $modePkgs]
    # Prettify the package names for the dialog, and remember current values.
    foreach pkg $globalPkgs {
	lappend GlobalPkgs [quote::Prettify $pkg]
	lappend globalVals [lcontains features $pkg]
	lappend globalHelp [help::itemDescription $pkg]
    }
    foreach pkg $modePkgs {
	lappend ModePkgs [quote::Prettify $pkg]
	lappend modeVals [lcontains features $pkg]
	lappend modeHelp [help::itemDescription $pkg]
    }
    set oldValues [concat $globalVals $modeVals]
    # These are used for the two iterations in creating the dialog.
    set pkgPages  [list "General"    "Mode Specific"]
    set pkgTypes  [list "GlobalPkgs" "ModePkgs"]
    set pkgVals   [list "globalVals" "modeVals"]
    set helpVals  [list "globalHelp" "modeHelp"]
    # Introductory text for the dialog panes.
    set txt0 "These $types have been designed to be used \"globally\",\
      i.e. they provide utilities that might be useful regardless\
      of the mode of the active window."
    set txt1 "These $types provide special functions that are generally\
      specific to certain modes, and are usually only turned on for\
      those modes.  They can also be turned on \"globally\" if desired."
    # Below, each "dialogPage$paneNumber" is the start of a new dialog pane,
    # "paneName" is the default pane name.  We run through this [foreach] for
    # Global and Mode Specific $types.
    set paneNumber 0
    foreach i [list 0 1] {
	set paneName "[lindex $pkgPages $i] $Types"
	set pkgType [set [lindex $pkgTypes $i]]
	set pkgVal  [set [lindex $pkgVals  $i]]
	set helpVal [set [lindex $helpVals $i]]
	# "partNumber" is a counter used for discretionary splitting into
	# new panes.
	set partNumber 0
	# Determine how many columns to use.
	if {$types eq "features"} {
	    set cols 3
	} else {
	    set cols 3
	}
	# Only add 10 rows of checkboxes to each pane.
	set idx1 [expr {$cols * 10}]
	set idx0 [expr {$idx1 - 1}]
	while {[llength $pkgType]} {
	    incr partNumber
	    set pane $paneName
	    if {($partNumber > 1)} {
		if {($partNumber == 2)} {
		    set dialogPage$paneNumber [lreplace \
		      [set dialogPage$paneNumber] 0 0 "$paneName (1)"]
		}
		append pane " ($partNumber)"
	    }
	    incr paneNumber
	    set dummyVar [string repeat " " $paneNumber]
	    set pkgs [lrange $pkgType 0 $idx0]
	    set vals [lrange $pkgVal  0 $idx0]
	    set help [lrange $helpVal 0 $idx0]
	    set dialogPage$paneNumber [list $pane \
	      [list "text" [set txt$i]] \
	      [list [list multiflag $pkgs $cols 0] \
	      $dummyVar $vals $help]]
	    set pkgType [lrange $pkgType $idx1 end]
	    set pkgVal  [lrange $pkgVal  $idx1 end]
	    set helpVal [lrange $helpVal $idx1 end]
	}
    }
    # Add a "Help" button which will open package Help windows.
    set button1 [list \
      "$Types HelpÉ" \
      "Click here to open Help files for selected $types" \
      "prefs::dialogs::packagesHelp \"Global $Types\" \{$allPkgs\}"]
    # Create the dialog.
    set dialogScript [list dialog::make -title "Global $Types" \
      -width 550 -addbuttons $button1]
    for {set number 1} {$number <= $paneNumber} {incr number} {
	if {![info exists dialogPage$number]} {
	    continue
	}
	lappend dialogScript [set dialogPage$number]
    }
    set newValues [join [eval $dialogScript]]
    # Turn on/off the global menus/features as necessary.
    set changes 0
    foreach oldValue $oldValues newValue $newValues pkgName $allPkgs {
	if {($oldValue == $newValue)} {
	    continue
	} elseif {$newValue} {
	    package::makeOnOrOff $pkgName "basic-on" "global"
	} else {
	    package::makeOnOrOff $pkgName "basic-off" "global"
	}
	incr changes
    }
    if {$changes} {
	set msg "The new settings for global $types have been saved."
    } else {
	set msg "No changes."
    }
    status::msg $msg
    return
}

proc prefs::dialogs::describeMenusFeatures {{what "Help"}} {
    
    if {($what eq "Help")} {
	set p "Read help for which package?"
    } else {
	set p "Describe which package?"
    }
    set pkgSets  [package::partition]
    set pkgTypes [list "ÇÇ  Menus  ÈÈ" "ÇÇ  Packages  ÈÈ" "ÇÇ  Modes  ÈÈ"]
    set pkgNames [list]
    set PkgNames [list]
    for {set i 0} {($i <= 2)} {incr i} {
	lappend pkgNames [lindex $pkgTypes $i]
	lappend PkgNames [lindex $pkgTypes $i]
	foreach pkgName [lindex $pkgSets $i] {
	    lappend pkgNames $pkgName
	    if {($i < 2)} {
		lappend PkgNames [quote::Prettify $pkgName]
	    } else {
		lappend PkgNames "$pkgName Mode"
	    }
	}
    }
    while {1} {
	if {[catch {listpick -p $p -indices $PkgNames} pkgIdx]} {
	    return
	}
	set pkgName [lindex $pkgNames $pkgIdx]
	if {([lsearch $pkgTypes $pkgName] > -1)} {
	    alertnote "Please choose an actual package, not a category!"
	} else {
	    break
	}
    }
    if {($what eq "Help")} {
	package::helpWindow $pkgName
    } else {
	package::describe $pkgName
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::packagesHelp" -- promptType packagesList ?prettify?
 # 
 # Present a list-pick dialog with all of the items in the "packagesList",
 # optionally prettifying their names.  This is mainly intended as a button
 # script for the Global/Mode Menus/Features dialogs, which is why it will
 # never throw an error, or return any information about what the user might
 # have actually chosen.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::packagesHelp {promptType packagesList {prettify 1}} {
    
    foreach pkg $packagesList {
	if {$prettify} {
	    set Pkg [quote::Prettify $pkg]
	} else {
	    set Pkg $pkg
	}
	set PkgConnect($Pkg) $pkg
    }
    set options [lsort -dictionary [array names PkgConnect]]
    set p "Open Help windows for which $promptType ?"
    if {![catch {listpick -p $p -l $options} results]} {
	foreach Pkg $results {
	    catch {package::helpWindow $PkgConnect($Pkg)}
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::helperApps" --
 # 
 # This is largely obsolete, handling global "*Sig" preferences.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::helperApps {} {
    
    set sigs [info globals *Sig]
    regsub -all {Sig} $sigs {} sigs
    set p "Change/inspect which helper?"
    set sig [listpick -p $p [lsort -dictionary $sigs]]
    set sig ${sig}Sig
    global $sig
    if {![info exists $sig]} {
	set $sig ""
    }
    set nsig [dialog::askFindApp $sig [set $sig]]
    if {($nsig ne "") && !([set $sig] eq $nsig)} {
	set $sig $nsig
	prefs::modified $sig
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::helperApplications" --
 # 
 # This provides an abbreviated [prefs::dialogs::externalHelpers] so that we
 # can hopefully avoid overwhelming the user with too many initial options.
 # This is the "Basic Options" version; clicking on the "Advanced Options"
 # dialog will save any current changes and create a new dialog using with
 # the full [prefs::dialogs::externalHelpers] settings.
 # 
 # For several of the helpers defined below, changing one will attempt to
 # change all related helpers to the same setting.  This should only take
 # place when the related helper's options include the new setting.
 # 
 # The main drawback to this entire routine is that, unlike most of the other
 # procedures in this file, this one is not agnostic about how the settings 
 # are defined in the rest of AlphaTcl.  It expects certain external helper 
 # protocols to exist with very specific names.  It is possible that this 
 # could be generalized in "xserv.tcl"
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::helperApplications {{category ""} {defaultPane ""}} {
    
    global ::xserv::currentImplementations alpha::application \
      index::prefshelp execSearchPath
    
    variable advancedHelperAppsDialog 0
    variable helperAppsDialog "basic"
    variable lastChosenPane
    variable listboxAvailable
    
    watchCursor
    if {($defaultPane eq "")} {
	set defaultPane $category
    }
    array set helpers [::xserv::sortServices]
    set categories [lsort -dictionary [array names helpers]]
    if {($category ne "")} {
	regsub -- {\s+\(\d+\)$} $category {} category
        if {(![lsearch -exact $categories $category] == -1)} {
            error "Unknown category, valid options include: $categories"
        } else {
            set categories [list $category]
        }
    }
    if {([llength $categories] > 1)} {
	set title "$alpha::application Helper Applications (Basic)"
    } else {
	set title "[lindex $categories 0] Helper Applications"
    }
    # Attempt to sort the categories.
    set defaultOrder [list "Internet" "TeX" "Metafont" "DVI" \
      "PostScript" "PDF"]
    set unsortedList [list]
    set sortedList   [list]
    foreach category $defaultOrder {
        if {([lsearch -exact $categories $category] > -1)} {
            lappend sortedList $category
        }
    }
    foreach category $categories {
	if {([lsearch -exact $sortedList $category] == -1)} {
	    lappend sortedList $category
	}
    }
    if {([set idx [lsearch $sortedList "Miscellaneous"]] > -1)} {
	set sortedList [lreplace $sortedList $idx $idx]
	lappend sortedList "Miscellaneous"
    }
    set categories $sortedList
    set prefsListing [list]
    # Create an introduction.
    if {([llength $categories] > 1)} {
	set introText1 "$alpha::application uses many \"helper\" applications\
	  to perform various tasks.  These helpers might typeset a LaTeX file,\
	  open a web page, fetch a file from a remote server, etc.\
	  If you have not set a helper application for a particular service,\
	  you will be prompted to define it when this is necessary.\
	  \r\rThe following dialog panes allow you to set external\
	  helper applications for ${alpha::application}.\r"
	set introText2 "This is the \"Basic Options\" version of this dialog;\
	  it only includes the settings most commonly required to make\
	  $alpha::application accomplish a desired task. Clicking on\
	  the \"Advanced Options\" button will save any changes you have\
	  already made and then present a new dialog will the full range\
	  of settings.\r\rIn some cases changing one \"Basic Options\"\
	  helper application setting will also automatically set related\
	  ones that appear in the Advanced dialog."
	lappend paneItems [list thepage "thepage" "thepage"] \
	  [list intro "text" $introText1] \
	  [list divider "divider" "divider"] \
	  [list intro "text" $introText2]
	set paneValues [list]
	lappend prefsListing [list "Introduction" $paneValues $paneItems]
	lappend paneNames "Introduction"
    }
    foreach category $categories {
	if {($category eq "TeX")} {
	    set Category "TeX / LaTeX"
	} else {
	    set Category $category
	}
	set paneValues [list]
	if {$listboxAvailable} {
	    set paneItems [list [list dummy text "$Category Helpers"] \
	      [list dummy divider divider]]
	} else {
	    set paneItems [list]
	}
	set paneName $Category
	set categoryHelpers  [list]
	set explanation ""
	switch -- $category {
	    "DVI" {
		# From <http://www.tex.ac.uk/cgi-bin/texfaq2html?label=dvi>
		set explanation "A DVI file (that is, a file with the type\
		  or extension .dvi) is (La)TeX's main output file. 'DVI' is\
		  supposed to be an acronym for DeVice-Independent, meaning\
		  that the file can be printed on almost any kind of\
		  typographic output device. The DVI file is designed\
		  to be read by a driver (DVI drivers) to produce further\
		  output designed specifically for a particular printer\
		  (e.g., a LaserJet) or to be used as input to a previewer\
		  for display on a computer screen."
		set categoryHelpers [list "dvips" "dvipdf"]
		set relatedHelpers(dvips) [list "viewDVI" "printDVI"]
	    }
	    "Internet" {
		set explanation "$alpha::application can perform various\
		  internet operations on remote files, such as fetching\
		  them from a remote server, or viewing them using your\
		  desired web browser."
		set categoryHelpers [list "ftpFetch" "viewHTML" "viewURL"]
		set relatedHelpers(ftpFetch) [list "ftpStore" "ftpList" \
		  "ftpMkdir" "ftpMirror"]
	    }
	    "PDF" {
		# From <http://en.wikipedia.org/wiki/PDF>
		set explanation "Portable Document Format (PDF)\
		  is a proprietary file format developed by Adobe Systems\
		  for representing two dimensional documents in a device\
		  independent and resolution independent format. \
		  Importantly, PDF files don't encode information that is\
		  specific to the application software, hardware, or\
		  operating system used to create or view the document.\
		  This feature ensures that a valid PDF will render exactly\
		  the same regardless of its origin or destination."
		set categoryHelpers [list "pdfViewer"]
	    }
	    "PostScript" {
		# From <http://en.wikipedia.org/wiki/PostScript>
		set explanation "PostScript (PS) is a page description\
		  language and programming language used primarily in the\
		  electronic and desktop publishing areas.  PostScript\
		  is a Turing-complete programming language; typically\
		  PostScript programs are not produced by humans, but by\
		  other programs. However, it is possible to produce graphics\
		  or to perform calculations by hand-crafting PostScript programs."
		set categoryHelpers [list "distillPS" "viewPS"]
	    }
	    "Metafont" {
		# From <http://www.tex.ac.uk/cgi-bin/texfaq2html?label=MF>
		set explanation "Metafont was written by Donald E. Knuth\
		  as a companion to TeX; whereas TeX defines the layout of\
		  glyphs on a page, Metafont defines the shapes of the glyphs\
		  and the relations between them.\
		  \r\r The MetaPost system (by John Hobby) implements a\
		  picture-drawing language very much like that of Metafont\
		  except that it outputs Encapsulated PostScript files instead\
		  of run-length-encoded bitmaps."
		set categoryHelpers [list "Mf" "Mp"]
		set relatedHelpers(Mf) [list "GfToPk" "GfToDvi" "PlToTfm" \
		  "TfmToPl" "VfToVpl" "VplToVf" "MakeTexPk"]
		set relatedHelpers(Mp) [list]
	    }
	    "TeX" {
		set category "TeX / LaTeX"
		# From <http://www.tex.ac.uk/cgi-bin/texfaq2html?label=whatTeX>
		# From <http://www.tex.ac.uk/cgi-bin/texfaq2html?label=latex>
		set explanation "TeX is a typesetting system written by\
		  Donald E. Knuth, who says in the Preface to his book on TeX\
		  that it is \"intended for the creation of beautiful books -\
		  and especially for books that contain a lot of mathematics\".\
		  TeX is a macro processor, and offers its users a powerful\
		  programming capability. \r\rLaTeX is a TeX macro package,\
		  originally written by Leslie Lamport, that provides a\
		  document processing system. LaTeX allows markup to describe\
		  the structure of a document, so that the user need not think\
		  about presentation. By using document classes and add-on\
		  packages, the same document can be produced in a variety of\
		  different layouts."
		set categoryHelpers [list "tex"]
		set relatedHelpers(tex) [list "etex" "pdftex" "pdfetex" \
		  "bibtex" "makeindex" "makeglossary" "typeset"]
	    }
	    "Miscellaneous" {
		set explanation "$alpha::application interacts with several\
		  additional \"helper\" applications that do not fit into\
		  any of the preceding categories.  Only a few of them are\
		  listed below; see the \"Advanced Options\" for the full\
		  set."
		set categoryHelpers [list "Diff" "Spellcheck"]
	        
	    }
	    default {
		# Unknown category.
		continue
	        
	    }
	}
	lappend paneItems [list explanation text $explanation]
	foreach helper $categoryHelpers {
	    if {[catch {::xserv::getCurrentImplementationFor $helper ""} curImp]} {
		continue
	    }
	    lappend paneItems [list "${helper}-divider" "divider" "divider"]
	    set name $helper
	    set serv [::xserv::describe $helper]
	    if {[dict exists $serv desc]} {
		lappend paneItems [list ${helper}-desc text [dict get $serv desc]]
	    }
	    lappend paneValues $helper $curImp
	    set Helper "${helper}:"
	    lappend paneItems [list $helper [list "smallall" "xhelper"] $Helper] \
	      [list {} text {}]
	}
	lappend prefsListing [list $paneName $paneValues $paneItems]
	lappend paneNames $paneName
    }
    # Now we include the old-style "*Sig" helpers.
    set oldHelpers [list]
    foreach oldHelper [list "browserSig"] {
	if {[info exists ::$oldHelper]} {
	    lappend oldHelpers $oldHelper
	}
    }
    if {([llength $categories] > 1) && [llength $oldHelpers]} {
	set devNote "Developers Note: All of the helper applications listed\
	  below use the old \"*Sig\" preference setting method, and should\
	  be reformed to make use of \"xserv\" technology."
	if {([llength [info globals *Sig]] > 1)} {
	    append devNote "\r\r(The \"Advanced Options\" version of this\
	      dialog contains more \"old-style\" helpers.)"
	}
	set paneValues [list]
	set paneItems  [list [list devNote text $devNote]]
	foreach helper $oldHelpers {
	    lappend paneItems [list "${helper}-divider" "divider" "divider"]
	    if {[info exists index::prefshelp($helper)]} {
		set desc $index::prefshelp($helper)
	    } else {
		set desc "\r"
	    }
	    set value [prefs::dialogs::_getPrefValue "standard" $helper]
	    if {($alpha::platform eq "alpha")} {
		set value "'${value}'"
	    }
	    lappend paneItems [list ${helper}-desc text $desc] \
	      [list $helper [list "smallall" "appspec"] $helper]
	    lappend paneValues $helper $value
	}
	# Now add all of these helpers.
	set paneName "Old-style Helpers"
	lappend paneNames $paneName
	lappend prefsListing [list $paneName $paneValues $paneItems]
    }
    # Use "-listbox" if available.
    if {$listboxAvailable && ([llength $paneNames] > 1)} {
	set options [list -pager "listbox"]
	set width   "650"
    } else {
	set options [list]
	set width   "525"
    }
    # Add extra buttons.
    lappend options -addbuttons [list \
      "Help" \
      "Click here to obtain more information about helper applications." \
      {help::openFile {Xserv Help} ;\
      set retCode 1 ; set retVal cancel} \
      "Advanced OptionsÉ" \
      "Click here to save any changes you have made and then \
      view the full set of helper application settings." \
      {set ::prefs::dialogs::advancedHelperAppsDialog 1 ;\
      set retCode 0 ; set retVal Advanced} \
      ]
    # Attempt to set the initial dialog pane.
    if {($defaultPane ne "")} {
	set defaultPane1 $defaultPane
	regsub -- {\s+\(\d+\)$} $defaultPane1 {} defaultPane2
	append defaultPane2 "*"
	if {([set idx [lsearch -exact $paneNames $defaultPane1]] > -1) \
	  || ([set idx [lsearch -glob $paneNames $defaultPane2]] > -1)} {
	    set initialPane [lindex $paneNames $idx]
	}
    }
    if {![info exists initialPane]} {
	if {[info exists lastChosenPane($title)] \
	  && ([lsearch $paneNames $lastChosenPane($title)] > -1)} {
	    set initialPane $lastChosenPane($title)
	} else {
	    set initialPane [lindex $paneNames 0]
	}
    }
    lappend options "-defaultpage" $initialPane
    set lastChosenPane($title) $initialPane
    # Returns a pane-keyval dictionary of all results
    set results [eval [list dialog::make_paged -title $title \
      -changeditems changes -width $width] $options $prefsListing]
    # We only look at those we know have changed
    foreach dialogPane [dict keys $changes] {
	foreach item [dict get $changes $dialogPane] {
	    if {($item eq "thepage")} {
		set value [dict get [dict get $results $dialogPane] $item]
		set lastChosenPane($title) $value
		prefs::modified lastChosenPane($title)
	    } elseif {($item eq "execSearchPath") \
	      || ([lsearch $oldHelpers $item] > -1)} {
		set value [dict get [dict get $results $dialogPane] $item]
		set setCmd "prefs::dialogs::_setPrefValue standard"
		eval $setCmd [list $item $value]
		lappend changedNames [quote::Prettify $item]
	    } else {
		# Get the correct pane results and then from that pane get
		# the correct result item.
		set impl [dict get [dict get $results $dialogPane] $item]
		set script [list ::xserv::chooseImplementationFor $item $impl]
		if {[catch {eval $script} err]} {
		    alpha::stderr "$err\r   while executing\r$script"
		    continue
		}
		lappend changedNames $item
		# Now attempt to set related helpers.
		if {![info exists relatedHelpers($item)] \
		  || [catch {::xserv::getCurrentImplementationNameFor $item ""} newVal] \
		  || ($newVal eq "")} {
		    continue
		}
		foreach helper $relatedHelpers($item) {
		    if {[catch {::xserv::getImplementationsOf $helper} options]} {
			continue
		    }
		    regsub -all -- {\s*[<>].*$} $newVal {} NewVal
		    if {([set idx [lsearch -exact $options $newVal]] > -1) \
		      || ([set idx [lsearch -glob $options $NewVal]] > -1)} {
			set value [lrange $options $idx $idx]
			catch {::xserv::chooseImplementationFor $helper $value}
		    }
		}
	    }
	}
    }
    if {[info exists changedNames]} {
	prefs::saveNow
	status::msg "Recorded changes to [join $changedNames {, }]."
    } else {
	status::msg "No changes."
    }
    if {[info exists advancedHelperAppsDialog] && $advancedHelperAppsDialog} {
	catch {prefs::dialogs::externalHelpers "" $lastChosenPane($title)}
    }
    unset -nocomplain advancedHelperAppsDialog
    return
}


## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::externalHelpers" --
 # 
 # Create a dialog with all "external" helper applications.  At present the
 # "group" variable is passed on when required, although it appears to have
 # very little use to us here.
 # 
 # We include the old-style "*Sig" helpers here as well; our goal is to 
 # remove these by converting them to xserv technology.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::externalHelpers {{group ""} {defaultPane ""}} {
    
    global ::xserv::currentImplementations alpha::application \
      index::prefshelp execSearchPath
    
    variable basicHelperAppsDialog 0
    variable helperAppsDialog "advanced"
    variable lastChosenPane
    variable listboxAvailable
    
    watchCursor
    array set helpers [::xserv::sortServices]
    set categories [lsort -dictionary [array names helpers]]
    if {[llength $categories] > 1} {
	set title "$alpha::application Helper Applications (Advanced)"
    } else {
	set title "[lindex $categories 0] Helper Applications"
    }
    if {([set idx [lsearch $categories "Miscellaneous"]] > -1)} {
	set categories [lreplace $categories $idx $idx]
	lappend categories "Miscellaneous"
    }
    # Attempt to sort the categories.
    set defaultOrder [list "Internet" "TeX" "Metafont" "DVI" \
      "PostScript" "PDF"]
    set unsortedList [list]
    set sortedList   [list]
    foreach category $defaultOrder {
	if {([lsearch -exact $categories $category] > -1)} {
	    lappend sortedList $category
	}
    }
    foreach category $categories {
	if {([lsearch -exact $sortedList $category] == -1)} {
	    lappend sortedList $category
	}
    }
    if {([set idx [lsearch $sortedList "Miscellaneous"]] > -1)} {
	set sortedList [lreplace $sortedList $idx $idx]
	lappend sortedList "Miscellaneous"
    }
    set categories $sortedList
    set prefsListing [list]
    # Create an introduction.
    set introText "$alpha::application uses many \"helper\" applications\
      to perform various tasks.  These helpers might typeset a LaTeX file,\
      open a web page, fetch a file from a remote server, etc.\
      If you have not set a helper application for a particular service,\
      you will be prompted to define it when this is necessary.\
      \r\rThe following dialog panes allow you to set external\
      helper applications for ${alpha::application}.\r"
    lappend paneItems [list intro "text" $introText] \
      [list thepage "thepage" "thepage"]
    if {[info exists execSearchPath]} {
	lappend paneItems [list divider "divider" "divider"]
	if {[info exists index::prefshelp(execSearchPath)]} {
	    lappend paneItems \
	      [list espHelp "text" "$index::prefshelp(execSearchPath)\r"] \
	      [list execSearchPath [list "smallall" "searchpath"] \
	      "execSearchPath:"]
	}
	lappend paneValues execSearchPath $execSearchPath
    } else {
	set paneValues [list]
    }
    lappend prefsListing [list "Introduction" $paneValues $paneItems]
    lappend paneNames "Introduction"
    foreach category $categories {
	if {($category eq "TeX")} {
	    set Category "TeX / LaTeX"
	} else {
	    set Category $category
	}
	set paneValues [list]
	if {$listboxAvailable} {
	    set paneItems [list [list dummy text "$Category Helpers"] \
	      [list dummy divider divider]]
	} else {
	    set paneItems [list]
	}
	set count 0
	if {([llength $helpers($category)] > 5)} {
	    set pane 1
	} else {
	    set pane ""
	}
	foreach helper [lsort -dictionary -unique $helpers($category)] {
	    if {($count > 0)} {
		lappend paneItems [list "${helper}-divider" "divider" "divider"]
	    }
	    set name $helper
	    set serv [::xserv::describe $helper]
	    if {[dict exists $serv desc]} {
		lappend paneItems [list ${helper}-desc text [dict get $serv desc]]
	    }
	    set curImp [::xserv::getCurrentImplementationFor $helper $group]
	    lappend paneValues $helper $curImp
	    set Helper "${helper}:"
	    lappend paneItems [list $helper [list "smallall" "xhelper"] $Helper] \
	      [list {} text {}]
	    incr count
	    # This is our internal "discretionary" handling.
	    if {($count == 5)} {
		if {($pane ne "")} {
		    set paneName "$Category (${pane})"
		    incr pane
		} else {
		    set paneName $Category
		}
		lappend paneNames $paneName
		lappend prefsListing [list $paneName $paneValues $paneItems]
		set paneValues [list]
		if {$listboxAvailable} {
		    set paneItems [list [list dummy text "$Category Helpers"] \
		      [list dummy divider divider]]
		} else {
		    set paneItems [list]
		}
		set count 0
	    }
	}
	# Now add anything that was still remaining.
	if {($count > 0)} {
	    if {($pane ne "") && ($pane > 1)} {
		set paneName "$Category (${pane})"
		incr pane
	    } else {
		set paneName $Category
	    }
	    lappend paneNames $paneName
	    lappend prefsListing [list $paneName $paneValues $paneItems]
	}
    }
    # Now we include the old-style "*Sig" helpers.
    if {[llength [set oldHelpers [lsort -dictionary [info globals *Sig]]]]} {
	set devNote "Developers Note: All of the helper applications listed\
	  below use the old \"*Sig\" preference setting method, and should\
	  be reformed to make use of \"xserv\" technology."
	set category "Old-style Helpers"
	set paneValues [list]
	set paneItems  [list [list devNote text $devNote] \
	  [list divider "divider" "divider"]]
	set count 0
	if {([llength $oldHelpers] > 4)} {
	    set pane 1
	} else {
	    set pane ""
	}
	foreach helper [lsort -dictionary -unique $oldHelpers] {
	    if {($count > 0)} {
		lappend paneItems [list "${helper}-divider" "divider" "divider"]
	    }
	    if {[info exists index::prefshelp($helper)]} {
		set desc $index::prefshelp($helper)
	    } else {
		set desc "\r"
	    }
	    set value [prefs::dialogs::_getPrefValue "standard" $helper]
	    if {($alpha::platform eq "alpha")} {
		set value "'${value}'"
	    }
	    lappend paneItems [list ${helper}-desc text $desc] \
	      [list $helper [list "smallall" "appspec"] $helper]
	    lappend paneValues $helper $value
	    incr count
	    # This is our internal "discretionary" handling.
	    if {($count == 4)} {
		if {($pane ne "")} {
		    set paneName "$category (${pane})"
		    incr pane
		} else {
		    set paneName $category
		}
		lappend paneNames $paneName
		lappend prefsListing [list $paneName $paneValues $paneItems]
		set paneValues [list]
		set paneItems  [list [list devNote text $devNote] \
		  [list divider "divider" "divider"]]
		set count 0
	    }
	}
	# Now add anything that was still remaining.
	if {($count > 0)} {
	    if {($pane ne "") && ($pane > 1)} {
		set paneName "$category (${pane})"
		incr pane
	    } else {
		set paneName $category
	    }
	    lappend paneNames $paneName
	    lappend prefsListing [list $paneName $paneValues $paneItems]
	}
    }
    # Use the "-listbox" dialog format if it is available.
    if {$listboxAvailable && ([llength $prefsListing] > 6)} {
	set options [list -pager "listbox"]
	set width   "650"
    } else {
	set options [list]
	set width   "525"
    }
    # Add extra buttons.
    lappend options -addbuttons [list \
      "Help" \
      "Click here to obtain more information about helper applications." \
      {help::openFile {Xserv Help} ;\
      set retCode 1 ; set retVal cancel} \
      "Basic OptionsÉ" \
      "Click here to save any changes you have made and then \
      view a simplified set of helper application settings." \
      {set ::prefs::dialogs::basicHelperAppsDialog 1 ;\
      set retCode 0 ; set retVal Basic} \
      ]
    # Attempt to set the initial dialog pane.
    if {($defaultPane ne "")} {
	set defaultPane1 $defaultPane
	regsub -- {\s+\(\d+\)$} $defaultPane1 {} defaultPane2
	append defaultPane2 "*"
	if {([set idx [lsearch -exact $paneNames $defaultPane1]] > -1) \
	  || ([set idx [lsearch -glob $paneNames $defaultPane2]] > -1)} {
	    set initialPane [lindex $paneNames $idx]
	}
    }
    if {![info exists initialPane]} {
	if {[info exists lastChosenPane($title)] \
	  && ([lsearch $paneNames $lastChosenPane($title)] > -1)} {
	    set initialPane $lastChosenPane($title)
	} else {
	    set initialPane [lindex $paneNames 0]
	}
    }
    lappend options "-defaultpage" $initialPane
    set lastChosenPane($title) $initialPane
    # Returns a pane-keyval dictionary of all results
    set results [eval [list dialog::make_paged -title $title \
      -changeditems changes -width $width] $options $prefsListing]
    # We only look at those we know have changed
    foreach dialogPane [dict keys $changes] {
	foreach item [dict get $changes $dialogPane] {
	    if {($item eq "thepage")} {
		set value [dict get [dict get $results $dialogPane] $item]
		set lastChosenPane($title) $value
		prefs::modified lastChosenPane($title)
	    } elseif {($item eq "execSearchPath") \
	      || ([lsearch $oldHelpers $item] > -1)} {
		set value [dict get [dict get $results $dialogPane] $item]
		set setCmd "prefs::dialogs::_setPrefValue standard"
		eval $setCmd [list $item $value]
		lappend changedNames [quote::Prettify $item]
	    } else {
		# Get the correct pane results and then from that pane get
		# the correct result item.
		set impl [dict get [dict get $results $dialogPane] $item]
		set script [list ::xserv::chooseImplementationFor $item $impl]
		if {[catch {eval $script} err]} {
		    alpha::stderr "$err\r   while executing\r$script"
		    continue
		}
		lappend changedNames $item
	    }
	}
    }
    if {[info exists changedNames]} {
	prefs::saveNow
	status::msg "Recorded changes to [join $changedNames {, }]."
    } else {
	status::msg "No changes."
    }
    if {[info exists basicHelperAppsDialog] && $basicHelperAppsDialog} {
        catch {prefs::dialogs::helperApplications "" $lastChosenPane($title)}
    }
    unset -nocomplain basicHelperAppsDialog
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::fileMappings" --
 # 
 # Create and present a dialog with all of the currently installed modes and
 # their File Mapping preferences.  Modes with longer lists will be given a
 # two line text editing field.  The dialog includes two buttons to obtain
 # more help.  The first, "Mode Selection Help" opens the relevant section in
 # the "Alpha Manual", while "File Patterns Help" opens a new dialog with the
 # basic information.  All changes to suffix mappings are saved between
 # editing sessions.
 # 
 # If the initial "ModeList" is empty, all modes will be displayed.  All
 # modes in the "ModeList" can be user-interface or internal names.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::fileMappings {args} {
    
    global alpha::macos alpha::application
    
    variable lastChosenPane
    variable listboxAvailable
    variable listboxOffset
    variable standardHeight
    variable standardWidth
    
    if {![llength $args]} {
	set ModeList [mode::listAll 1]
    } else {
	set ModeList [lsort -dictionary -unique $args]
    }
    set textEditModes    [list]
    set nonTextEditModes [list]
    foreach ModeName $ModeList {
	set modeName [mode::getName $ModeName 0]
	if {![mode::exists $modeName] || ($modeName eq "Text")} {
	    # Don't allow editing of the 'default' setting for Text mode.
	    continue
	} elseif {([lsearch [alpha::internalModes] $modeName] == -1)} {
	    lappend textEditModes $modeName
	} else {
	    lappend nonTextEditModes $modeName
	}
    }
    if {![llength $textEditModes] && ![llength $nonTextEditModes]} {
	error "Cancelled -- no valid modes listed to change."
    }
    watchCursor
    set title "$alpha::application File Mappings"
    # Create the dialog script in several pieces: the main options and
    # several different panes with a limited number of mode options.
    set paneNames    [list]
    set dialogPanes  [list]
    set dialogScript [list dialog::make \
      -title $title \
      -addbuttons [list\
      "Initial Mode Help"\
      "Click this button for more information about how the initial mode\
      is chosen for a window."\
      "help::openGeneral {Alpha Manual} {Initial Mode Selection}" \
      "Patterns Help"\
      "Click this button for more information about file patterns."\
      "prefs::dialogs::_filePatternsHelp" \
      ]]
    set width $standardWidth
    # Use the "-listbox" dialog format if it is available.
    if {[llength $textEditModes] && [llength $nonTextEditModes] \
      && ($listboxAvailable)} {
	lappend dialogScript -pager "listbox"
	incr width $listboxOffset
    }
    lappend dialogScript -width $width
    set height [expr {(300 < $standardHeight) ? 300 : $standardHeight}]
    set rows   [expr {(($height - 50)/50)}]
    # Create the Introduction pane.
    if {[llength $textEditModes]} {
	if {$alpha::macos} {
	    lappend methods {"File Creators"}
	    set joiner ", "
	} else {
	    set joiner " "
	}
	lappend methods {"unix executable lines"} {and "Smart mode" lines}
	set methods [join $methods $joiner]
	lappend dialogPanes [list "Introduction" \
	  [list "thepage" "thepage"] \
	  [list "text" \
	  "The following dialog panes allow you to adjust the\
	  file mappings of each mode current installed in $alpha::application.\
	  \r\r\"File Mappings\" are used by $alpha::application to help\
	  determine the initial mode when a file is opened.\
	  (Other methods include ${methods}; see the \"Alpha Manual\"\
	  for more information.)\
	  \r\rEach mapping is a list of file patterns.\
	  A file pattern is given as a string including special characters,\
	  which allow automatic substitution of characters in file names.\
	  \r\rIn general, it is not necessary to list both lower and UPPER\
	  case mappings.  If both are present for a given file extension,\
	  case sensitivity will be checked, otherwise case insensitive\
	  mappings will be used.\
	  \r\rFor more information, press the help buttons below.\r"\
	  ]]
	lappend paneNames "Introduction"
    }
    # Add individual mode file mapping panes.
    set modesLength [llength $textEditModes]
    for {set i 0} {($i < $modesLength)} {incr i $rows} {
	set idx1 $i
	if {([set idx2 [expr {$i + $rows - 1}]] >= $modesLength)} {
	    set idx2 "end"
	}
	set paneName  "Editing: "
	set ModeName1 [mode::getName [lindex $textEditModes $idx1] 1]
	set ModeName2 [mode::getName [lindex $textEditModes $idx2] 1]
	append paneName [string range $ModeName1 0 1] " - " \
	  [string range $ModeName2 0 1]
	while {([lsearch $paneNames $paneName] > -1)} {
	    append paneName " "
	}
	lappend paneNames $paneName
	set dialogPane [list $paneName]
	foreach modeName [lrange $textEditModes $idx1 $idx2] {
	    set ModeName [mode::getName $modeName 1]
	    set pat [mode::filePatterns $modeName]
	    set description [help::itemDescription $modeName]
	    lappend dialogPane [list var2 $ModeName $pat $description]
	    
	}
	lappend dialogPanes $dialogPane
    }
    # Add the internal modes.
    incr rows -2
    set internalModeInfo \
      "$alpha::application has several \"internal\" modes\
      which are not intended for text editing.  Some of these still have\
      special file mappings that help recognize that an active window has\
      been opened or created by a particular feature.\
      \r\rYou should not adjust these unless you are sure that you know\
      what you are doing!\r"
    set modesLength [llength $nonTextEditModes]
    for {set i 0} {($i < $modesLength)} {incr i $rows} {
	set idx1 $i
	if {([set idx2 [expr {$i + $rows - 1}]] >= $modesLength)} {
	    set idx2 "end"
	}
	set paneName  "Internal: "
	set ModeName1 [mode::getName [lindex $nonTextEditModes $idx1] 1]
	set ModeName2 [mode::getName [lindex $nonTextEditModes $idx2] 1]
	append paneName [string range $ModeName1 0 1] " - " \
	  [string range $ModeName2 0 1]
	while {([lsearch $paneNames $paneName] > -1)} {
	    append paneName " "
	}
	lappend paneNames $paneName
	set dialogPane [list $paneName [list "text" $internalModeInfo]]
	foreach modeName [lrange $nonTextEditModes $idx1 $idx2] {
	    set ModeName [mode::getName $modeName 1]
	    set pat [mode::filePatterns $modeName]
	    set description [help::itemDescription $modeName]
	    lappend dialogPane [list var2 $ModeName $pat $description]
	    
	}
	lappend dialogPanes $dialogPane
    }
    # Attempt to set the initial dialog pane.
    if {[info exists lastChosenPane($title)] \
      && ([lsearch $paneNames $lastChosenPane($title)] > -1)} {
	lappend dialogScript "-defaultpage" $lastChosenPane($title)
    }
    set results [eval $dialogScript $dialogPanes]
    if {([lindex $paneNames 0] eq "Introduction")} {
	set lastChosenPane($title) [lindex $results 0]
	prefs::modified lastChosenPane($title)
	set results [lrange $results 1 end]
    }
    # Validate the changes.
    foreach pat $results modeName [concat $textEditModes $nonTextEditModes] {
	set oldPattern [string trim [mode::filePatterns $modeName]]
	set newPattern [string trim $pat]
	if {$oldPattern eq $newPattern} {
	    continue
	} elseif {![is::List $newPattern]} {
	    lappend errors [mode::getName $modeName 1]
	} else {
	    mode::filePatterns $modeName $newPattern
	    lappend changed [mode::getName $modeName 1]
	}
    }
    if {[info exists changed]} {
	prefs::saveNow
	status::msg "File mappings for \"[join $changed {, }]\"\
	  have been saved."
    } else {
	status::msg "No changes were made."
    }
    if {[info exists errors]} {
	# This happens if the user enters, say, just an open brace as a
	# mode's file pattern.
	if {([llength $errors] == 1)} {
	    set problem "mode had an illegal list"
	} else {
	    set problem "modes had illegal lists"
	}
	alertnote "\"[join $errors {, }]\" $problem of patterns.\
	  \r\rPlease make sure \\\{,\\\} are properly quoted or balanced."
	return [eval prefs::dialogs::fileMappings $errors]
    }
    return
}

proc prefs::dialogs::arrangeMenus {} {
    
    set globalMenus [global::menuArrangement]
    # Now we have the global menus in the current order, and
    # we need to arrange them
    if {[catch {dialog::arrangeItems $globalMenus} newOrder]} {
	return
    }
    if {$newOrder ne $globalMenus} {
	global::menuArrangement $newOrder
    }
}

# ===========================================================================
# 
# ×××× Config > Preferences ×××× #
# 

proc prefs::dialogs::globalPrefs {{which "AllPreferences"}} {
    
    global flagPrefs varPrefs package::prefs allFlags
    
    global::updateHelperFlags
    global::updatePackageFlags
    watchCursor
    set prefsListing [list]
    # Unfortunate hack to load the help prefs.  Need to resolve this.
    # (1) "help.tcl" is a dummy proc, why can't we just call that?
    # (2) The file "help.tcl" is always sourced during startup, isn't it?
    #     Why would this ever be called before startup is complete?
    #     
    # TODO: Please report a bug if there's a problem, else it will
    # never be fixed.
    if {![llength [info commands help.tcl]]} {
	alpha::log "stdout" "prefs::dialogs::globalPrefs help.tcl hack..."
	auto_load help.tcl
    }
    if {($which eq "All Global Preferences") ||
    ($which eq "AllGlobalPreferences")} {
	set which "AllPreferences"
    }
    if {($which eq "Global Preferences") ||
    ($which eq "GlobalPreferences")} {
	set which "AllPreferences"
    }
    set title [quote::Prettify $which]
    set AllPreferences [lsort [array names flagPrefs]]
    set InterfacePreferences [list \
      Appearance Completions Electrics Text Tiling Window]
    set Input-OutputPreferences [list \
      Backups Files Printer WWW]
    set SystemPreferences [lremove -- $AllPreferences \
      $InterfacePreferences ${Input-OutputPreferences} \
      [list "Packages" "Helper Applications"]]
    
    set AllPreferences [lremove -- $AllPreferences \
      [list "Packages" "Helper Applications"]]
    
    if {[info exists package::prefs]} {
	foreach pkg $package::prefs {
	    lappend PackagePreferences "${pkg}PrefsÉ"
	}
    }
    if {[info exists [join $which ""]]} {
	set categories [set [join $which ""]]
    } else {
	set categories $which
    }
    foreach category $categories {
	set flagList $flagPrefs($category)
	set varList  [list]
	foreach prefName $varPrefs($category) {
	    if {([llength $prefName] == 1)} {
		lappend varList $prefName
		continue
	    }
	    # What situation are we dealing with here?
	    foreach extraPrefName [lrange $prefName 1 end] {
		if {([lsearch -exact $allFlags $extraPrefName] != -1)} {
		    lappend flagList $extraPrefName
		} else {
		    lappend varList $extraPrefName
		}
	    }
	}
	lappend prefsListing "" $category $flagList $varList \
	  [list prefs::dialogs::_getPrefValue "standard"] \
	  [list prefs::dialogs::_setPrefValue "standard"]
    }
    prefs::dialogs::makePrefsDialog $title $prefsListing
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "prefs::dialogs::packagePrefs" --
 # 
 # Make a dialog for the given package.
 #  
 # -------------------------------------------------------------------------
 ##

proc prefs::dialogs::packagePrefs {{pkgName ""} {title ""}} {
    
    global package::prefs allFlags flagPrefs varPrefs alpha::prefs
    
    set prefsListing [list]
    if {($pkgName eq "") || ($pkgName eq "allPackages")} {
	if {($title eq "")} {
	    set title "AlphaTcl Package Preferences"
	}
	global::updatePackageFlags
	if {[info exists package::prefs]} {
	    set pkgList [concat $package::prefs [list miscellaneousPackages]]
	} else {
	    set pkgList [list miscellaneousPackages]
	}
	foreach pkg [lsort -dictionary $pkgList] {
	    if {($pkg eq "miscellaneousPackages")} {
		set prefsListing [linsert $prefsListing 0 \
		  "" "Miscellaneous Packages"\
		  $flagPrefs(Packages) $varPrefs(Packages)\
		  [list prefs::dialogs::_getPrefValue "standard"] \
		  [list prefs::dialogs::_setPrefValue "standard"]]
		continue
	    }
	    if {[info exists alpha::prefs($pkg)]} {
		set pkg $alpha::prefs($pkg)
	    }
	    if {[array size ::${pkg}modeVars]} {
		set prefNames   [array names ::${pkg}modeVars]
		set sortedPrefs [prefs::dialogs::_sortPrefsList $prefNames $pkg]
		set flagList    [lindex $sortedPrefs 0]
		set varList     [lindex $sortedPrefs 1]
		lappend prefsListing $pkg [quote::Prettify $pkg] \
		  $flagList $varList \
		  [list prefs::dialogs::_getPrefValue "package" $pkg] \
		  [list prefs::dialogs::_setPrefValue "package" $pkg]
	    }
	}
    } else {
	if {($title eq "")} {
	    set title "[quote::Prettify $pkgName] Package Preferences"
	}
	set prefNames   [array names ::${pkgName}modeVars]
	set sortedPrefs [prefs::dialogs::_sortPrefsList $prefNames $pkgName]
	set flagList    [lindex $sortedPrefs 0]
	set varList     [lindex $sortedPrefs 1]
	set prefsListing [list $pkgName "" \
	  $flagList $varList \
	  [list prefs::dialogs::_getPrefValue "package" $pkgName] \
	  [list prefs::dialogs::_setPrefValue "package" $pkgName] \
	  ]
    }
    prefs::dialogs::makePrefsDialog $title $prefsListing
    return
}

# ===========================================================================
# 
# ×××× Config > Mode Prefs ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::modeMenusFeatures" -- types ?m?
 # 
 # Present a dialog where "types" is either "menus" or "features", allowing
 # the user to change the mode's feature set.  All changes are saved between
 # editing sessions by [package::makeOnOrOff], although we explicitly call
 # [prefs::saveNow] to ensure that the prefs are saved in the event of a
 # crash.  The "Help" button will call [prefs::dialogs::packagesHelp] and
 # open any available windows, and then return to the original dialog.
 # 
 # We need to create 6 separate lists of packages:
 # 
 # (1) Normal Mode packages which are not on globally
 # (2) Global packages which are off globally
 # (3) Global packages which are off globally but are "preference" packages.
 # (4) Normal Mode packages which are on globally
 # (5) Global packages which are on globally
 # (6) Global packages which are on globally but are "preference" packages.
 # 
 # There are at most two panes here, for turning items On and Off,
 # but in minimal (or maximal) user feature sets one of the panes might be
 # omitted.  As of this writing, and with a fully loaded AlphaTcl library, no
 # discretionary handling is required here since so many of Alpha's packages
 # are global-only.
 # 
 # If the user has balloon help available, we construct the dialog with
 # "multiflag" checkboxes using our own "discretionary" pane handling.
 # Otherwise, we have a separate pane for each list and include all package
 # descriptions with the items, each presented in a separate row.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::modeMenusFeatures {types {m ""}} {
    
    global global::features mode::features
    
    if {($types ne "menus") && ($types ne "features")} {
	error "Must supply 'menus' or 'features'"
    }
    set type [string range $types 0 end-1]
    if {($m eq "") && ([set m [win::getMode]] eq "")} {
	error "No mode was specified."
    }
    set M "\"[mode::getName $m 1]\""
    watchCursor
    set Types [string totitle $types]
    # Collect the list of mode-specific menus/features.
    set alwaysOn   [alpha::listAlphaTclPackages "always-on"]
    set autoLoad   [alpha::listAlphaTclPackages "auto-loading"]
    set invalid    [alpha::listAlphaTclPackages "invalid"]
    set globalOnly [alpha::listAlphaTclPackages "${types}-global-only"]
    set modePkgs   [alpha::listAlphaTclPackages "${types}-mode-${m}"]
    set globalPkgs [alpha::listAlphaTclPackages "${types}-global"]
    if {($types eq "features")} {
	set prefPkgs [alpha::listAlphaTclPackages "preferences"]
    } else {
	set prefPkgs [list]
    }
    set globalPkgs [concat $globalPkgs $prefPkgs]
    set modePkgs   [lremove $modePkgs $alwaysOn $autoLoad $invalid $globalOnly]
    set globalPkgs [lremove $globalPkgs $alwaysOn $autoLoad $invalid \
      $globalOnly $modePkgs]
    set allPkgs    [concat $globalPkgs $modePkgs]
    # Now create lists based on current activation status.  Prettify the
    # package names for the dialog, and remember current values.
    for {set number 1} {$number <= 6} {incr number} {
	foreach var [list "names" "values" "descs"] {
	    set "list${number}${var}" [list]
	    set "list${number}Names"  [list]
	}
    }
    foreach pkg $modePkgs {
	if {![lcontains global::features $pkg]} {
	    # (1) Normal Mode packages which are not on globally
	    lappend list1names  $pkg
	    lappend list1Names  [quote::Prettify $pkg]
	    lappend list1values [lcontains mode::features($m) $pkg]
	    lappend list1descs  [help::itemDescription $pkg]
	} else {
	    # (4) Normal Mode packages which are on globally
	    lappend list4names $pkg
	    lappend list4Names [quote::Prettify $pkg]
	    if {[lcontains mode::features($m) "-$pkg"]} {
		lappend list4values 0
	    } else {
		lappend list4values 1
	    }
	    lappend list4descs [help::itemDescription $pkg]
	}
    }
    foreach pkg $globalPkgs {
	if {![lcontains global::features $pkg]} {
	    if {![lcontains prefPkgs $pkg]} {
		# (2) Global packages which are off globally
		lappend list2names  $pkg
		lappend list2Names  [quote::Prettify $pkg]
		lappend list2values [lcontains mode::features($m) $pkg]
		lappend list2descs  [help::itemDescription $pkg]
	    } else {
		# (3) Global packages which are off globally but are
		# "preference" packages.
		lappend list3names  $pkg
		lappend list3Names  [quote::Prettify $pkg]
		lappend list3values [lcontains mode::features($m) $pkg]
		lappend list3descs  [help::itemDescription $pkg]
	    }
	} elseif {![lcontains prefPkgs $pkg]} {
	    # (5) Global packages which are on globally
	    lappend list5names $pkg
	    lappend list5Names [quote::Prettify $pkg]
	    if {[lcontains mode::features($m) "-$pkg"]} {
		lappend list5values 0
	    } else {
		lappend list5values 1
	    }
	    lappend list5descs [help::itemDescription $pkg]
	} else {
	    # (6) Global packages which are on globally but are "preference"
	    # packages.
	    lappend list6names $pkg
	    lappend list6Names [quote::Prettify $pkg]
	    if {[lcontains mode::features($m) "-$pkg"]} {
		lappend list6values 0
	    } else {
		lappend list6values 1
	    }
	    lappend list6descs [help::itemDescription $pkg]
	}
    }
    # Remember old values, and create context specific header texts.  We make
    # the header strings grammatical and context sensitive.
    set oldValues [list]
    for {set number 1} {$number <= 6} {incr number} {
	set oldValues  [concat $oldValues [set "list${number}values"]]
	set listLength [llength [set "list${number}Names"]]
	set tog "turned on globally"
	set yct "You can turn"
	set fmm "for $M mode"
	switch -- $number {
	    "1" {
		set paneName "Turn $M $Types on"
		if {($listLength == 1)} {
		    set txt "This $type has been designed specifically ${fmm}."
		} else {
		    set txt "These $types have been designed specifically ${fmm}."
		}
	    }
	    "2" {
		set paneName "Turn Global $Types on"
		if {($listLength == 1)} {
		    set txt "This $type has been designed for use by any mode.\
		      You can turn this $type on $fmm windows."
		} else {
		    set txt "These $types have been designed for use by any mode.\
		      You can turn these $types on $fmm windows."
		}
	    }
	    "3" {
		set paneName "Turn Preference $Types on"
		if {($listLength == 1)} {
		    set txt "This is a special type of feature that appears\
		      in the \"Config > Preferences\" dialogs, and have\
		      not been ${tog}. $yct it on $fmm windows"
		} else {
		    set txt "These are special types of features that appear\
		      in the \"Config > Preferences\" dialogs.\
		      $yct any of them on $fmm windows"
		}
	    }
	    "4" {
		set paneName "Turn $M $Types off"
		if {($listLength == 1)} {
		    set txt "This $type has been designed specifically\
		      for $M mode, and is currently ${tog}."
		} else {
		    set txt "These $types have been designed specifically\
		      for $M mode, and are currently ${tog}."
		}
	    }
	    "5" {
		set paneName "Turn Global $Types off"
		if {($listLength == 1)} {
		    set txt "This is a general $type which is ${tog}."
		} else {
		    set txt "These are general $types which are ${tog}."
		}
	    }
	    "6" {
		set paneName "Turn Preference $Types off"
		if {($listLength == 1)} {
		    set txt "This is a special type of feature that appears\
		      in the \"Config > Preferences\" dialogs,\
		      and it has been ${tog}."
		} else {
		    set txt "These are special types of features that appear\
		      in the \"Config > Preferences\" dialogs,\
		      and they have been ${tog}."
		}
	    }
	}
	append txt "\r"
	set header$number $txt
	set "list${number}PageName" $paneName
    }
    # Create the various dialog panes.
    set paneNumber 0
    set checkNote "An unchecked checkbox indicates that the item is still\
      on globally, but turned off whenever you switch to a $M mode window."
    if {($types eq "features")} {
	set globalPkgs [concat $globalPkgs $prefPkgs]
	set cols 2
    } else {
	set cols 3
    }
    for {set number 1} {$number <= 6} {incr number} {
	# Create list specific variables.
	set Names  [set "list${number}Names"]
	set values [set "list${number}values"]
	set descs  [set "list${number}descs"]
	# Construct the pane using "multiflag" checkboxes with all
	# package descriptions in balloon help.
	if {($number == 1)} {
	    incr paneNumber
	    set txt "None of the items in this dialog pane are currently\
	      turned on globally."
	    set dialogPage$paneNumber [list "Turn Items On"]
	    lappend dialogPage$paneNumber [list "text" $txt]
	} elseif {($number == 4)} {
	    incr paneNumber
	    set txt "All of the items in this dialog pane are currently turned\
	      on globally. $checkNote"
	    set dialogPage$paneNumber [list "Turn Items Off"]
	    lappend dialogPage$paneNumber [list "text" $txt]
	}
	# Do we have anything to add?
	if {[llength $Names]} {
	    # All lists in this category on one pane.
	    lappend dialogPage$paneNumber [list \
	      [list multiflag $Names $cols 0] \
	      [set header$number] $values $descs]
	}
    }
    # Add a "Help" button which will open package Help windows.  It requires
    # a button name, balloon help, and a script to be evaluated.
    set button1 [list \
      "$Types HelpÉ" \
      "Click here to open Help files for selected $types" \
      "prefs::dialogs::packagesHelp \"$m mode $Types\" \{$allPkgs\}"]
    # Create the dialog.
    set dialogScript [list dialog::make -title "$M Mode $Types" \
      -width 550 -addbuttons $button1]
    # Add all of the dialog panes we created.
    for {set number 1} {$number <= $paneNumber} {incr number} {
	if {![info exists dialogPage$number]} {
	    continue
	} elseif {([llength [set dialogPage$number]] > 2)} {
	    lappend dialogScript [set dialogPage$number]
	}
    }
    set newValues [join [eval $dialogScript]]
    # Turn on/off the global menus/features as necessary.
    set changes 0
    set idx 0
    foreach pkg [concat $list1names $list2names $list3names] {
	# We know that these are not in the "mode::features" list as "-$pkg"
	set newValue [lindex $newValues $idx]
	set oldValue [lindex $oldValues $idx]
	if {($newValue == $oldValue)} {
	    incr idx
	    continue
	} elseif {$newValue} {
	    package::makeOnOrOff $pkg "basic-on" $m
	    incr changes
	} else {
	    package::makeOnOrOff $pkg "basic-off" $m
	    incr changes
	}
	incr idx
    }
    foreach pkg [concat $list4names $list5names $list6names] {
	# These might be in the "mode::features" list as "-$pkg"
	set newValue [lindex $newValues $idx]
	set oldValue [lindex $oldValues $idx]
	if {($newValue == $oldValue)} {
	    incr idx
	    continue
	} elseif {$newValue} {
	    if {[lcontains mode::features($m) "-$pkg"]} {
		package::makeOnOrOff $pkg "mode-not-off" $m
	    }
	    package::makeOnOrOff $pkg "basic-on" $m
	    incr changes
	} else {
	    if {[lcontains mode::features($m) "$pkg"]} {
		package::makeOnOrOff $pkg "basic-off" $m
	    }
	    package::makeOnOrOff $pkg "mode-off" $m
	    incr changes
	}
	incr idx
    }
    if {$changes} {
	prefs::saveNow
	set msg "The new settings for $M $types have been saved."
    } else {
	set msg "No changes."
    }
    status::msg $msg
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::modePrefs" --
 # 
 # Create the "Config > Mode Prefs > Preferences" dialog.  If the mode has 
 # defined a procedure named one of
 # 
 #     ::<mode>::modePrefsDialog
 #     ::<mode>modifyFlags
 # 
 # then these will be called.  (The first version is preferred, the second is
 # for back compatibility only.)
 # 
 # If the mode has not defined these procedures but has defined preference
 # pane names using [prefs::dialogs::setPaneLists] then these will be used to
 # create a categorized dialog.  If no mode mode preference panes have been
 # defined, then we create our own pane groups.
 # 
 # No matter how the panes are defined, a "Miscellaneous" pane will always
 # be added at the end if necessary, and flags will always be presented at
 # the top of each dialog pane,
 # 
 # Based on [TeX::modifyModePrefs], contributed by FrŽdŽric Boulanger.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::modePrefs {{m ""} {title ""}} {
    
    if {($m eq "") && ([set m [win::getMode]] eq "")} {
	alertnote "The current mode is undefined: no preferences can be set."
	return
    }
    global ${m}modeVars mode
    
    if {($m ne $mode)} {
	# If it's not the current mode, make sure the prefs are loaded
	loadAMode $m
    }
    # Check for mode specific proc -- used by HTML mode for example
    if {[llength [info commands ::${m}::modePrefsDialog]]} {
	::${m}::modePrefsDialog
	return
    } elseif {[llength [info commands ::${m}modifyFlags]]} {
    } elseif {[llength [info commands ::${m}modifyFlags]]} {
	# We'll remove this older version in the future.  We want to switch
	# to namespace procs, and procs with more accurate names.
	::${m}modifyFlags
	return
    }
    # We'll create the dialog ourselves.
    set M [mode::getName $m 1]
    if {![info exists ${m}modeVars]} {
	error "Cancelled -- no preferences have been set for \"${M}\" mode."
    }
    if {($title eq "")} {
	set title "$M Mode Preferences"
    }
    set modePaneLists [prefs::dialogs::setPaneLists $m]
    if {[llength $modePaneLists]} {
	# This mode has defined preference panes.
	foreach {category prefList} $modePaneLists {
	    lappend modePrefPanes $category
	    set modePrefLists($category) $prefList
	}
    } else {
	# This mode has not defined preference panes.
	set modePrefPanes [list "Editing" "Navigation" "Comments" \
	  "Colors" "$M Help"]
	set modePrefNames [array names ${m}modeVars]
	array set modePrefLists [list \
	  "Editing" [list autoMark fillColumn indentOnReturn indentationAmount \
	  leftFillColumn lineWrap tabSize wordBreak] \
	  "Navigation" [list autoMark funcExpr parseExpr sortFuncsMenu] \
	  "Comments" [list commentsContinuation prefixString suffixString] \
	  ]
	foreach prefName [lsort -dictionary [array names ${m}modeVars]] {
	    if {![prefs::isRegistered $prefName $m]} {
		continue
	    } elseif {[regexp -nocase -- {electric|indent} $prefName]} {
		lappend modePrefLists(Editing) $prefName
	    } elseif {[regexp -- {^smart} $prefName]} {
		lappend modePrefLists(Editing) $prefName
	    } elseif {[regexp -- {(^mark|Mark)} $prefName]} {
		lappend modePrefLists(Navigation) $prefName
	    } elseif {[regexp -- {(^comment|Comment)} $prefName]} {
		lappend modePrefLists(Comments) $prefName
	    } elseif {[regexp -- {(^help|homePage|Help|HomePage|Url)} $prefName]} {
		lappend "modePrefLists($M Help)" $prefName
	    } elseif {[regexp -- {(Color$)} $prefName]} {
		lappend modePrefLists(Colors) $prefName
	    }
	}
	foreach category $modePrefPanes {
	    if {![info exists modePrefLists($category)]} {
		set modePrefLists($category) [list]
	    } else {
		set modePrefLists($category) \
		  [lsort -dictionary -unique $modePrefLists($category)]
	    }
	}
    }
    # Make sure that "Miscellaneous" is the last item.
    foreach category $modePrefPanes {
	if {($category ne "Miscellaneous")} {
	    lappend categories $category
	}
    }
    lappend categories "Miscellaneous"
    set modePrefLists(Miscellaneous) [list]
    # Collect our preference names information.
    set seenPrefs [list]
    set seenCats  [list]
    set prefNames [lsort -dictionary [array names ${m}modeVars]]
    # Add each preference pane to the listing.
    set prefsListing [list]
    foreach category $categories {
	if {![info exists modePrefLists($category)]} {
	    continue
	}
	set prefsList $modePrefLists($category)
	if {($category eq "Miscellaneous")} {
	    # This will always be the last preference pane, so we 
	    # collect anything that hasn't been added yet.
	    eval [list lappend prefsList] $prefNames
	}
	# Sort the preferences for this pane.
	set sortedPrefs [prefs::dialogs::_sortPrefsList $prefsList $m]
	set flagList    [lindex $sortedPrefs 0]
	set varList     [lindex $sortedPrefs 1]
	foreach prefList [list flagList varList] {
	    foreach prefName [set $prefList] {
		if {([lsearch -exact $seenPrefs $prefName] > -1) \
		  || ![info exists ${m}modeVars($prefName)]} {
		    set $prefList [lremove [set $prefList] [list $prefName]]
		}
	    }
	}
	# Do we add this dialog pane?
	if {($category ne "Miscellaneous") \
	  && ([llength $flagList] + [llength $varList] < 2)} {
	    # If there are not many prefs in this pane, suppress the pane
	    # altogether and put the items in the "Miscellaneous" pane.
	    set prefNames [concat $prefNames $flagList]
	    set prefNames [concat $prefNames $varList]
	} elseif {![prefs::dialogs::hideShowPane $m $category]} {
	    # We allow modes to completely disable a preference pane.
	    eval [list lappend seenPrefs] $flagList $varList
	    continue
	} elseif {[llength $flagList] + [llength $varList]} {
	    # We only add it if it isn't empty.
	    if {(![llength $seenCats]) && ($category eq "Miscellaneous")} {
	        set category ""
	    }
	    lappend prefsListing $m $category $flagList $varList \
	      [list prefs::dialogs::_getPrefValue "package" $m] \
	      [list prefs::dialogs::_setPrefValue "package" $m]
	    eval [list lappend seenPrefs] $flagList $varList
	    lappend seenCats $category
	}
    }
    prefs::dialogs::makePrefsDialog $title $prefsListing
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::setPaneLists" --  <pkg> ?<pane> <list>? ?<pane> <list>? ...
 # 
 # Alternate usage:
 # 
 # "prefs::dialogs::setPaneLists" --  <pkg> ?<pane>?
 # 
 # Create a list of preference panes for a given package.  When preference
 # dialogs are created, each pane will contain the lists which have been
 # registered by this procedure.
 # 
 # In the first case, "args" should be an even-numbered list, such as
 # 
 #   prefs::dialogs::setPaneLists "TeX" \
 #     "Electrics"      [list "electricBraces" "indentOnReturn" ...] \
 #     "Navigation"     [list "autoMark" "funcExpr" ...]
 # 
 # This procedure can then be called to add more items, such as
 # 
 #   prefs::dialogs::setPaneLists "TeX" "Electrics" [list \
 #     "electricLeftContractions" \
 #     "listForRefCompletion" \
 #     ]
 # 
 # which will append the new items to the end of the previous "Electrics"
 # preference pane list.
 # 
 # Returns an even-numbered list containing the name of each specified pane
 # and its current list of associated preferences.  
 # 
 # If no arguments are supplied, this will return the entire current
 # preference pane listing as an even-numbered list, such as
 # 
 #   Electrics {electricBraces indentOnReturn} Navigation {autoMark funcExpr}
 # 
 # which can then be used in [foreach] and/or [array set ...]  constructions.
 # This is used by the preference dialog procedures in "prefsDialogs.tcl",
 # notably [prefs::dialogs::modePreferences].  
 # 
 # If only one argument is given, then that pane is registered (with an 
 # empty list if it didn't already exist) and the current contents are 
 # returned as a two-item list:
 # 
 #   Electrics {electricBraces indentOnReturn}
 # 
 # Note that the order of the pane names is determined by the order in which
 # the arguments are given here, and the first call to this procedure for a
 # given package will have those pane names listed first.  It is possible to
 # include "placeholders" for panes that other code might add later, such as
 # 
 #   prefs::dialogs::setPaneLists "TeX" \
 #     "Electrics"      [list "electricBraces" "indentOnReturn" ...] \
 #     "Navigation"     [list "autoMark" "funcExpr" ...]
 #     "TeX Filesets"   [list] \
 #     "Comments"       [list "prefixString" ...]
 # 
 # Recommended pane names (for user-interface consistency) include
 # 
 #   Editing
 #   Electrics
 #   Navigation
 #   Comments
 #   Colors
 #   <mode> Help
 # 
 # As explained in [prefs::dialogs::modePrefs], a "Miscellaneous" pane will
 # be created if necessary to present any preferences that have not been
 # included in a defined pane group.
 # 
 # Developers can issue this in an AlphaTcl Shell window
 # 
 #   % join [prefs::dialogs::setPaneLists <pkg>] \r
 # 
 # to get a listing of the current panes and their contents, as in
 # 
 #   % join [prefs::dialogs::setPaneLists Tcl] \r
 #   Editing
 #   fillColumn indentSlashEndLines lineWrap wordBreak
 #   Comments
 #   commentsContinuation prefixString commentColor insertCommentString
 #   Colors
 #   recogniseItcl recognisePseudoTcl recogniseTk recognizeObsoleteProcs ...
 #   Electrics
 #   electricBraces electricDblLeftParen electricTripleColon ...
 # 
 # The [prefs::dialogs::resetPaneLists] procedure described below is also
 # useful for debugging.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::setPaneLists {pkg args} {
    
    variable paneLists
    
    if {([llength $args] == 1)} {
        lappend args [list]
    } elseif {(([llength $args] % 2) != 0)} {
	error "Usage: <pkg> ?<pane> <list>? ?<pane> <list>? ..."
    }
    if {![info exists paneLists($pkg)]} {
	set paneLists($pkg) [list]
    }
    if {![llength $args]} {
	return $paneLists($pkg)
    }
    # Create an ordered list of pane names and list or preferences for each
    # from the saved settings.
    set paneNames [list]
    foreach {paneName prefList} $paneLists($pkg) {
	lappend paneNames $paneName
	set panePrefs($paneName) $prefList
    }
    # Add the pane names (if necessary) and the preference names for each.
    set thesePanes [list]
    foreach {paneName prefList} $args {
	lappend thesePanes $paneName
	if {([lsearch -exact $paneNames $paneName] == -1)} {
	    lappend paneNames $paneName
	    set panePrefs($paneName) $prefList
	    continue
	}
	if {![info exists panePrefs($paneName)]} {
	    set panePrefs($paneName) [list]
	}
	foreach prefName $prefList {
	    if {([lsearch -exact $panePrefs($paneName) $prefName] == -1)} {
		lappend panePrefs($paneName) $prefName
	    }
	}
    }
    # Re-create our list using the current pane names order.
    set newPaneList [list]
    foreach paneName $paneNames {
	lappend newPaneList $paneName $panePrefs($paneName)
    }
    set paneLists($pkg) $newPaneList
    # Now return the listings for the panes we just registered.
    set results [list]
    foreach paneName $thesePanes {
	lappend results $paneName $panePrefs($paneName)
    }
    return $results
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::resetPaneLists" --  <pkg> ?<paneName>? ?<paneName>? ...
 # 
 # Remove the specified preference panes from the storage variable.  If no
 # pane names are specified, all panes for the given package are removed.
 # This is mainly for debugging so that AlphaTcl package developers are able
 # to experiment with different pane configurations.
 # 
 # Returns a message describing what has been removed.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::resetPaneLists {pkg args} {
    
    variable paneLists
    
    if {![llength $args]} {
        unset -nocomplain paneLists($pkg)
	return "All preference panes for '$pkg' have been forgotten."
    }
    # Create an ordered list of pane names and list or preferences for each
    # from the saved settings.
    set paneNames [list]
    foreach {paneName prefList} $paneLists($pkg) {
	lappend paneNames $paneName
	set panePrefs($paneName) $prefList
    }
    foreach paneName $args {
	if {[info exists panePrefs($paneName)]} {
	    unset panePrefs($paneName)
	}
    }
    # Re-create our list using the current pane names order.
    set newPaneList [list]
    foreach paneName $paneNames {
	if {[info exists panePrefs($paneName)]} {
	    lappend newPaneList $paneName $panePrefs($paneName)
	}
    }
    set paneLists($pkg) $newPaneList
    # Now return the listings for the panes we just registered.
    if {([llength $args] == 1)} {
	return "The $pkg \"[lindex $args 0]\" pref pane has been removed."
    } else {
	return "The $pkg \"[join $args {, }]\" pref panes have been removed."
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::hideShowPane" --
 # 
 # Entire panes of preferences can be suppressed from the dialog.  If the
 # "value" supplied here is not the null string, we assign that value.
 # Otherwise if a value has been assigned, we return that, otherwise "1"
 # indicates that the pane is not hidden.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::hideShowPane {pkg paneName {value ""}} {
    
    variable hiddenPanes
    
    if {($value ne "")} {
	set hiddenPanes($pkg,$paneName) $value
    } elseif {[info exists hiddenPanes($pkg,$paneName)]} {
	return $hiddenPanes($pkg,$paneName)
    } else {
	return 1
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Standard Preference Dialog ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::makePrefsDialog" --
 # 
 # Create a standard preferences dialog with "title", using all of the
 # information given in the "prefsListing" list.  The "prefsListing" list
 # should come in multiples of six, containing these items for each
 # individual dialog pane:
 # 
 #   pkgName    -- An installed AlphaTcl package (can be empty.)
 #   paneName   -- The name of the dialog pane.
 #   flagList   -- The list of all flag preference names.
 #   varList    -- The list of all non-flag preference names.
 #   valGetter  -- The procedure used to obtain the old preference value.
 #   valSetter  -- The procedure used to set the new preference value.
 # 
 # The height and width of the dialog will be standardized, and each pane
 # will be "discretionary" and extend into an additional pane when necessary.
 # 
 # Any changes to the preference values will be automatically saved, as will 
 # the last dialog pane viewed by the user.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::makePrefsDialog {title prefsListing} {
    
    variable lastChosenPane
    variable listboxAvailable
    variable listboxOffset
    variable standardWidth
    variable tooltipAvailable
    
    set dialogPanes [list]
    set paneNames   [list]
    set mpdListVals [list pkgName paneName flagList varList valGetter valSetter]
    foreach $mpdListVals $prefsListing {
	foreach {paneValue paneItems} \
	  [prefs::dialogs::_makePrefsDialog $pkgName \
	  $flagList $varList $valGetter $valSetter] {}
	if {$listboxAvailable && ([llength $prefsListing] > 6)} {
	    set paneItems [linsert $paneItems 0 \
	      [list header "text" "$paneName Preferences"] \
	      [list divider "divider" "divider"]]
	}
	if {![llength $dialogPanes]} {
	    set paneItems [linsert $paneItems 0 \
	      [list thepage "thepage" "thepage"]]
	}
	lappend paneNames $paneName
	lappend dialogPanes [list $paneName $paneValue $paneItems]
	set setter($paneName) $valSetter
    }
    # Use the "-listbox" dialog format if it is available.
    set options [list]
    set width $standardWidth
    if {$listboxAvailable && ([llength $paneNames] > 1)} {
	lappend options "-pager" "listbox"
	incr width $listboxOffset
    }
    # Attempt to set the initial dialog pane.
    if {[info exists lastChosenPane($title)] \
      && ([lsearch $paneNames $lastChosenPane($title)] > -1)} {
	lappend options "-defaultpage" $lastChosenPane($title)
    }
    set buttons [list]
    if {!$tooltipAvailable} {
	lappend buttons "Help" \
	  "Click here for information about specific preferences" \
	  [list prefs::dialogs::_prefsHelp $title]
    }
    lappend buttons "Search PrefsÉ" \
      "Click here to search for specific preferences" \
      [list prefs::dialogs::_prefsSearch]
    set dialogScript [list dialog::make_paged -title $title \
      -addbuttons $buttons -changeditems changes -width $width]
    # Returns a pane-keyval dictionary of all results
    set results [eval $dialogScript $options $dialogPanes]
    # We only look at those we know have changed
    foreach dialogPane [dict keys $changes] {
	set setCmd $setter($dialogPane)
	foreach item [dict get $changes $dialogPane] {
	    # Get the correct pane results and then from that pane
	    # get the correct result item.
	    set value [dict get [dict get $results $dialogPane] $item]
	    if {($item eq "thepage")} {
		set lastChosenPane($title) $value
		prefs::modified lastChosenPane($title)
	    } else {
		eval $setCmd [list $item $value]
		lappend changedNames [quote::Prettify $item]
	    }
	}
    }
    if {![info exists changedNames]} {
	status::msg "No changes."
	return
    }
    prefs::saveNow
    if {([llength $changedNames] == 1)} {
	set what "preference"
    } else {
	set what "preferences"
    }
    status::msg "Saved ${what}: \"[join $changedNames {, }]\""
}

proc prefs::dialogs::_makePrefsDialog {pkgName flagList varList varGetter varSetter} {
    
    global alpha::platform dialog::simple_type
    
    variable flagColumns
    variable listboxAvailable
    variable standardHeight
    
    set paneItems  [list]
    set paneValues [list]
    
    foreach prefList [list $flagList $varList] isFlag {1 0} {
	foreach prefName $prefList {
	    # Displayed preference name.
	    set PrefName [prefs::dialogs::_translateText $prefName]
	    # Current value.
	    set prefVal  [eval $varGetter [list $prefName]]
	    # Preference help.
	    set prefHelp [help::itemDescription $prefName $pkgName]
	    if {$isFlag} {
		lappend flagL $PrefName
		lappend paneItems [list $prefName {hidden flag} $PrefName $prefHelp]
	    } else {
		set prefType [dialog::prefItemType $prefName]
		if {($prefType eq "appspec") &&\
		  ($alpha::platform eq "alpha")} {
		    set prefVal '$prefVal'
		} elseif {$prefType eq "geometry"} {
		    set prefType [list "geometry" \
		      [concat $varSetter [list $prefName]]]
		}
		lappend paneItems \
		  [list dummy [list discretionary $standardHeight] {}]
		if {[info exists dialog::simple_type($prefType)]} {
		    set prefType [list "smallval" $prefType]
		}
		lappend paneItems [list $prefName $prefType $PrefName $prefHelp]
	    }
	    lappend paneValues $prefName $prefVal
	}
	if {$isFlag && [info exists flagL]} {
	    lappend paneItems [list "" \
	      [list flaggroup [lsort -dictionary $flagL] \
	      -columns $flagColumns] "     "]
	    if {[llength $varList]} {
	        lappend paneItems [list "" "divider" "divider" ""]
	    }
	}
	if {$isFlag} {
	    lappend paneItems [list space0 "text" " \r" ""]
	}
    }
    return [list $paneValues $paneItems]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::_translateText" --
 # 
 # We might wish to think about allowing all messages in AlphaTcl to be
 # translated.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::_translateText {textString} {
    
    return [quote::Prettify $textString]
}

proc prefs::dialogs::_sortPrefsList {prefsList {pkgName ""}} {
    
    global allFlags prefs::type
    
    set flagList  [list]
    set varList   [list]
    set bindList  [list]
    set colorList [list]
    foreach prefName [lsort -dictionary -unique $prefsList] {
	if {![prefs::isRegistered $prefName $pkgName]} {
	    continue
	}
	if {([lsearch -exact $allFlags $prefName] > -1)} {
	    lappend flagList $prefName
	} elseif {[regexp {Color$} $prefName]} {
	    lappend colorList $prefName
	} elseif {[info exists prefs::type($prefName)] \
	  && [regexp {binding$} $prefs::type($prefName)]} {
	    lappend bindList $prefName
	} else {
	    lappend varList $prefName
	}
    }
    return [list $flagList [concat $varList $bindList $colorList]]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::_getPrefValue" --
 # 
 # Get a value for a given "type" that will be included in a preferences
 # dialog.  Types here include:
 # 
 # "array" -- <arrayName> <prefName>
 # 
 # This is how we go from variable names to values for preferences that are 
 # stored in an array.
 # 
 # "package" -- <pkgName> <prefName>
 # 
 # This is how we go from variable names to values for standard packages.
 # 
 # "standard" -- <itemName>
 # 
 # This is how we go from variable names to values for standard dialog items
 # for the global dialogs.  Items can be flag-features as well as standard
 # variables, and might be shadowed by mode-specific values.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::_getPrefValue {type args} {
    
    switch -- $type {
	"array" {
	    set arrayName [lindex $args 0]
	    set prefName  [lindex $args 1]
	    return [uplevel \#0 [list set ${arrayName}($prefName)]]
	}
	"package" {
	    set pkgName  [lindex $args 0]
	    set prefName [lindex $args 1]
	    return [uplevel \#0 [list set ${pkgName}modeVars($prefName)]]
	}
	"standard" {
	    set itemName [lindex $args 0]
	    global index::feature global::features
	    if {[info exists index::feature($itemName)]} {
		return [expr \
		  {([lsearch -exact $global::features $itemName] != -1)}]
	    } elseif {[globalVarIsShadowed $itemName]} {
		return [globalVarSet $itemName]
	    } else {
		return [uplevel \#0 [list set $itemName]]
	    }
	}
	default {
	    error "Unknown 'type': should be 'array' 'package' or 'standard'"
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::_setPrefValue" --
 # 
 # Set a new value for a given "type" that has been changed in a preferences 
 # dialog.  Types here include:
 # 
 # "array" -- <arrayName> <prefName> <newValue>
 # 
 # This is how we go from variable names to values for preferences that are 
 # stored in an array.
 # 
 # "package" -- <pkgName> <prefName> <newValue>
 # 
 # This is how we go from variable names to values for standard packages,
 # such as modes.  Notice that this proc will ensure that the <mode>modeVars
 # are kept in sync with the global variables, if this is the current mode.
 # It also assumes that the previous values were already in sync (for
 # '$orig').
 # 
 # "standard" -- <itemName> <newValue>
 # 
 # This is how we go from variable names to values for standard dialog items
 # for the global dialogs.  Items can be flag-features as well as standard
 # variables, and might be shadowed by mode-specific values.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::_setPrefValue {type args} {
    
    switch -- $type {
        "array" {
	    set arrayName [lindex $args 0]
	    set prefName  [lindex $args 1]
	    set newValue  [lindex $args 2]
	    global $arrayName
	    array set $arrayName [list $prefName $newValue]
	    prefs::modified ${arrayName}($prefName)
	    return
        }
        "package" {
	    set pkgName  [lindex $args 0]
	    set prefName [lindex $args 1]
	    set newValue [lindex $args 2]
	    global ${pkgName}modeVars mode
	    set oldValue [set ${pkgName}modeVars($prefName)]
	    set ${pkgName}modeVars($prefName) $newValue
	    # Also set global variable if it's the current mode.
	    if {($mode eq $pkgName)} {
		global $prefName
		set $prefName $newValue
	    }
	    prefs::changed $pkgName $prefName $oldValue $newValue
	    return
        }
	"standard" {
	    set itemName [lindex $args 0]
	    set newValue [lindex $args 1]
	    global index::feature global::features $itemName
	    if {[info exists index::feature($itemName)]} {
		if {$newValue} {
		    if {[package::do_activate $itemName]} {
			package::throwActivationError
		    } else {
			lunion global::features $itemName
			package::activate $itemName
		    }
		} else {
		    set global::features \
		      [lremove $global::features [list $itemName]]
		    global mode
		    if {($mode ne "")} {
			if {![mode::isFeatureActive $mode $itemName]} {
			    package::deactivate $itemName
			}
		    } else {
			package::deactivate $itemName
		    }
		}
		return $newValue
	    } else {
		if {[globalVarIsShadowed $itemName]} {
		    set oldValue [globalVarSet $itemName]
		    globalVarSet $itemName $newValue
		} else {
		    set oldValue [set $itemName]
		    set $itemName $newValue
		}
		prefs::changed "" $itemName $oldValue $newValue
		return
	    }
	}
        default {
            error "Unknown 'type': should be 'array' 'package' or 'standard'"
        }
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Dialog Buttons ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::_prefsHelp" --
 # 
 # A nice button script which scans through the documented internal dialog
 # variables to extract the help on all dialog items and then give it back to
 # the user.  Provided to any new dialog with
 # 
 #   -addbuttons [list Help ... [list prefs::dialogs::_prefsHelp $title]
 # 
 # as in the proc [prefs::dialogs::makePrefsDialog].
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::_prefsHelp {title} {
    
    variable standardHeight
    variable standardWidth
    
    upvar 1 helpA helpA
    upvar 1 pages pages
    upvar 1 currentpage currentpage
    
    set dialogPanes [list]
    foreach {paneName prefItems} $pages {
	set dialogPane [list $paneName]
	foreach prefItem $prefItems {
	    if {([string trim $prefItem] eq "") || ($prefItem eq "divider")} {
	        continue
	    }
	    if {[info exists helpA($paneName,$prefItem)]} {
		set help [dialog::helpdescription $helpA($paneName,$prefItem)]
		if {([string trim $help] eq "")} {
		    set help "(No information available.)"
		}
		lappend dialogPane \
		  [list [list discretionary $standardHeight]] \
		  [list "text" "$prefItem : $help \r"]
	    }
	}
	lappend dialogPanes $dialogPane
    }
    return [eval [list dialog::make -cancel {} -defaultpage $currentpage \
      -title "Help for $title" -width $standardWidth] $dialogPanes]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::_prefsSearch" --
 # 
 # Another button script which allows the user to search for a specific
 # preference via [prefs::searchForSetting].  Provided to any new dialog with
 # 
 #   -addbuttons [list "SearchÉ" ... [list prefs::dialogs::_prefsSearch]]
 # 
 # as in the proc [prefs::dialogs::makePrefsDialog].
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::_prefsSearch {} {
    
    if {![catch {prefs::searchForSetting}]} {
	uplevel [list set retCode 1]
	uplevel [list set retVal "Cancelled -- No changes to preferences."]
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::_filePatternsHelp" --
 # 
 # Open a dialog that explains the file patterns syntax.
 # 
 # This can be safely called by any AlphaTcl procedure.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::_filePatternsHelp {} {
    
    set dialogScript [list dialog::make -title "File Patterns Help" \
      -width "500" \
      -cancel "" \
      -okhelptag "Click here to close this dialog." \
      [list "" \
      [list "text" "A file pattern is given as a string including special\
      characters, which allow for automatic substitution of characters in\
      file names.\r"] \
      [list divider divider1] \
      [list [list "smallval" "static"] "?" \
      "Matches any single character.\r"] \
      [list divider divider2] \
      [list [list "smallval" "static"] "*" \
      "Matches any sequence of zero or more characters.\r"] \
      [list divider divider3] \
      [list [list "smallval" "static"] "\[chars\]" \
      "Matches any single character in chars.\r"] \
      [list "text" "If chars contains a\
      sequence of the form a-b then any character between a and b\
      (inclusive) will match. To match '-' give it as the first\
      character between the brackets.\r"] \
      [list divider divider4] \
      [list [list "smallval" "static"] "\\x" \
      "Matches the character \"x\".\r"] \
      [list "text" "This is useful if you want to\
      match any of the special characters, e.g to matching '*' is\
      done by the pattern '\\*'.\r"] \
      ]]
    eval $dialogScript
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::_regexpHelp" --
 # 
 # Open a dialog with multiple panes that explain various aspects of the
 # regular expression syntax.  When the dialog is closed, the last pane is
 # remembered so that the next call will open the dialog there.  The "Cancel"
 # button is replaced by "More Help" which closes the dialog and opens the
 # "Help > Regular Expressions" file.  If this takes place, we instruct the
 # dialog which spawned this to throw a cancel error and return "0".  (If no
 # windows are opened, "1" is returned.  Some dialogs will lead to funky user
 # interaction if the current window (and possibly the mode) changes.)
 # 
 # If this is not going to be called from a dialog button, then the procedure
 # [help::regexpHelpDialog] should be called instead.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::_regexpHelp {} {
    
    variable lastREDialogPane
    variable listboxAvailable
    
    if {![info exists lastREDialogPane]} {
	set lastREDialogPane "Introduction"
    }
    # This is the list of dialog panes used in this dialog.
    set dialogPanes [list "intro" "examples" \
      "atoms1" "atoms2" "brackets" "classes" "quantifiers" \
      "constraints" "escapes1" "escapes2" "metasyntax"]
    # Introduction
    set introTitle "Introduction"
    lappend introText {
	A regular expression (referred to here as a "regexp") describes
	strings of characters.  It's a pattern that matches certain strings
	and doesn't match others.
    }
    lappend introText {
	This dialog provides a quick reference guide for the most common
	regexp syntax elements.  In each case the string "--" separates the
	regexp element from its description.
    }
    lappend introText {
	Some of the concepts cannot be completely explained here -- at any
	time you can click on the "More Help" button to close this dialog and
	open the "Help > Regular Expressions" help file.
    }
    lappend introText "divider" {
	A regexp is one or more branches, separated by '|', matching anything
	that matches any of the branches.
    }
    lappend introText {
	A branch is zero or more constraints or quantified atoms,
	concatenated.  It matches a match for the first, followed by a match
	for the second, etc; an empty branch matches the empty string.
    }
    lappend introText "divider" {
	A regexp might look something like the following string:
    }
    lappend introText {
	^[\t ]*This (c|w)ould match (\w+[^0-9:])text\??$
    }
    # Examples -- to be added
    set examplesTitle "Examples"
    lappend examplesText {
	Here are some very basic regexp examples.
    }
    lappend examplesText "divider" {
	(a|A)bc
    } {
	Will match "abc" or "Abc" but not "abbc"
    }
    lappend examplesText "divider" {
	(a|A)b*c
    } {
	Will match "abc" or "Abc" or "abbc" or "ac"
    }
    lappend examplesText "divider" {
	(a|A)b+c
    } {
	Will match "abc" or "Abc" or "abbc" but not "ac"
    }
    lappend examplesText "divider" {
	(a|A)b*c.+d
    } {
	Will match "abbcXd" or "AcXd" but not "abcd"
    }
    lappend examplesText "divider" {
	\w+[0-9]+\.(html|pdf)\s+file
    } {
	Will match "test1.html file" or "Another_One_23.pdf file"
    }
    # Atoms -- part 1
    set atoms1Title "Atoms"
    lappend atoms1Text {An atom is one of:} "divider"
    lappend atoms1Text {
	. -- matches any single character
    }
    lappend atoms1Text {
	\k -- (where k is a non-alphanumeric character) matches that
	character taken as an ordinary character, e.g. \\ matches a backslash
	character
    }
    lappend atoms1Text {
	\c -- where c is alphanumeric (possibly followed by other
	characters), an escape
    }
    lappend atoms1Text {
	[LB] -- when followed by a character other than a digit, matches the
	left-brace character '[LB]'; when followed by a digit, it is the
	beginning of a bound
    }
    lappend atoms1Text {
	x -- where x is a single character with no other significance,
	matches that character.
    }
    lappend atoms1Text "divider" {
	Advanced atoms, surrounded by (parentheses) or [brackets] are
	described in the next dialog pane.
    }
    # Atoms -- part 2
    set atoms2Title "Atoms (continued)"
    lappend atoms2Text {
	An atom can also be surrounded by (parentheses) or [brackets].
    }
    lappend atoms2Text "divider"
    lappend atoms2Text {
	(re) -- [where re is any regular expression] matches a match for re,
	with the match noted for possible reporting
    }
    lappend atoms2Text {
	(?:re) -- as previous, but does no reporting (a "non-capturing" set
	of parentheses)
    }
    lappend atoms2Text {
	() -- matches an empty string, noted for possible reporting
    }
    lappend atoms2Text {
	(?:) -- matches an empty string, without reporting
    }
    lappend atoms2Text {
	[chars] -- a bracket expression, matching any one of the chars
    }
    lappend atoms2Text "divider" {
	Atoms that are "reported" can be used in substitutions, where \1 will
	contain the first reported atom, \2 contains the next, etc.
    }
    # Bracket Epressions
    set bracketsTitle "Bracket Expressions"
    lappend bracketsText {
	A bracket expression is a list of characters enclosed in '[]'.  It
	normally matches any single character from the list.  If the list
	begins with '^', it matches any single character not from the rest of
	the list.
    }
    lappend bracketsText {
	If two characters in the list are separated by '-', this is shorthand
	for the full range of characters between those two (inclusive) in the
	sequence, e.g. [0-9] in ASCII matches any decimal digit.  Two ranges
	may not share an endpoint, so e.g. a-c-e is illegal.
    }
    lappend bracketsText {
	To include a literal ] or - in the list, the simplest method is to
	enclose it in [.  and .]  to make it an element.  Alternatively, make
	it the first character (following a possible `^'), or precede it with
	'\'.  Alternatively, for '-', make it the last character, or the
	second endpoint of a range.  To use a literal - as the first endpoint
	of a range, make it an element or precede it with '\'.
    }
    lappend bracketsText {
	With the exception of these, some combinations using '[', and
	escapes, all other special characters lose their special significance
	within a bracket expression.
    }
    # Character Classes
    set classesTitle "Character Classes"
    lappend classesText {
	Within a bracket expression, the name of a character class enclosed
	in [: and :] stands for the list of all characters belonging to
	that class, such as '[[:alpha:]]' to match any letter.
    }
    lappend classesText {
	Standard character classes include:
    }
    lappend classesText "divider" \
      {alnum -- An alphanumeric (letter or digit)} \
      {alpha -- A letter} \
      {blank -- A space or tab character} \
      {cntrl -- A control character} \
      {digit -- A decimal digit} \
      {graph -- A character with a visible representation} \
      {lower -- A lower-case letter} \
      {print -- An alphanumeric (same as alnum)} \
      {punct -- A punctuation character} \
      {space -- A character producing white space in displayed text} \
      {upper -- An upper-case letter} \
      {xdigit -- A hexadecimal digit}
    # Quantifiers
    set quantifiersTitle "Quantifiers"
    lappend quantifiersText {
	A quantified atom is an atom possibly followed by a single
	quantifier.  Without a quantifier, it matches a match for the atom.
    }
    lappend quantifiersText {
	The quantifiers, and what a so-quantified atom matches, include:
    }
    lappend quantifiersText "divider" {
	* -- a sequence of 0 or more matches of the atom
    }
    lappend quantifiersText {
	+ -- a sequence of 1 or more matches of the atom
    }
    lappend quantifiersText {
	? -- a sequence of 0 or 1 matches of the atom
    }
    lappend quantifiersText {
	{m} -- a sequence of exactly m matches of the atom
    }
    lappend quantifiersText {
	{m,} -- a sequence of m or more matches of the atom
    }
    lappend quantifiersText {
	{m,n} -- a sequence of m through n (inclusive) matches of the atom; m
	may not exceed n
    }
    lappend quantifiersText {
	*?  +?  ??  {m}?  {m,}?  {m,n}?  -- non-greedy quantifiers, which
	match the same possibilities, but prefer the smallest number rather
	than the largest number of matches
    }
    # Constraints
    set constraintsTitle "Constraints"
    lappend constraintsText {
	A constraint matches an empty string when specific conditions are
	met.  A constraint may not be followed by a quantifier.  The simple
	constraints are as follows.
    }
    lappend constraintsText "divider" {
	^ -- matches at the beginning of a line
    }
    lappend constraintsText {
	$ -- matches at the end of a line
    }
    lappend constraintsText {
	(?=re) -- positive lookahead, matches at any point where a substring
	matching re begins
    }
    lappend constraintsText {
	(?!re) -- negative lookahead, matches at any point where no substring
	matching re begins
    }
    lappend constraintsText "divider" {
	The lookahead constraints may not contain back references, and all
	parentheses within them are considered non-capturing.
    }
    lappend constraintsText {
	Note that a regexp may not end with `\'.
    }
    # Escapes -- part 1
    set escapes1Title "Escapes"
    lappend escapes1Text {
	Escapes, which begin with a \ followed by an alphanumeric character,
	come in several varieties: character entry, class shorthands,
	constraint escapes, and back references.  A \ followed by an
	alphanumeric character but not constituting a valid escape is illegal.
    }
    lappend escapes1Text {
	Character-entry escapes exist to make it easier to specify
	non-printing and otherwise inconvenient characters in REs.  These
	include:
    }
    lappend escapes1Text "divider" {
	\n -- newline[\N]
	\r -- carriage return[\N]
	\t -- horizontal tab[\R]
	\m -- matches only at the beginning of a word[\N]
	\M -- matches only at the end of a word[\N]
	\y -- matches only at the beginning or end of a word[\N]
	\Y -- will not match at the beginning/end of a word
    }
    # Escapes -- part 2
    set escapes2Title "Escapes (continued)"
    lappend escapes2Text {
	Class-shorthand escapes provide shorthands for certain commonly-used
	character classes:
    }
    lappend escapes2Text "divider" \
      {\d -- [[:digit:]]} \
      {\s -- [[:space:]]} \
      {\w -- [[:alnum:]_] (note underscore)} \
      {\D -- [^[:digit:]]} \
      {\S -- [^[:space:]]} \
      {\W -- [^[:alnum:]_] (note underscore)}
    lappend escapes2Text "divider" {Unicode escapes:}
    lappend escapes2Text {
	\uwxyz -- (where wxyz is exactly four hexadecimal digits) the Unicode
	character U+wxyz in the local byte ordering
    }
    lappend escapes2Text {
	\Ustuvwxyz -- (where stuvwxyz is exactly eight hexadecimal digits)
	reserved for a somewhat-hypothetical Unicode extension to 32 bits
    }
    # Metasyntax
    set metasyntaxTitle "Metasyntax"
    lappend metasyntaxText {
	A sequence (?xyz) (where xyz is one or more alphabetic characters)
	specifies options affecting the rest of the RE. The available option
	letters include:
    }
    lappend metasyntaxText "divider" \
      {(?b) -- rest of RE is a BRE} \
      {(?c) -- case-sensitive matching (usual default)} \
      {(?e) -- rest of RE is an ERE} \
      {(?i) -- case-insensitive matching} \
      {(?m) -- historical synonym for n} \
      {(?p) -- partial newline-sensitive matching, where '.' and '[^ ]' expressions will never match the newline character} \
      {(?n) -- newline-sensitive matching, as with (?p) but in addition ^ and $ will match the empty string before and after a newline respectively} \
      {(?q) -- rest of RE is a literal ("quoted") string} \
      {(?s) -- non-newline-sensitive matching (usual default, where the newline '\n' is not special in any way)} \
      {(?t) -- tight syntax (usual default)} \
      {(?w) -- inverse partial newline-sensitive ("weird") matching}
    # Set up the main dialog script.
    append buttonScript {help::openGeneral "Regular Expressions" ; } \
      {set retCode 1 ; set retVal "cancel"}
    set dialogScript [list dialog::make -title "Regular Expressions Syntax" \
      -defaultpage $lastREDialogPane \
      -ok "Close" \
      -okhelptag "Click here to close this dialog." \
      -cancel "More Help" \
      -cancelhelptag "Click here to open the \"Help > Regular Expressions\" help file." \
      ]
    if {$listboxAvailable} {
	lappend dialogScript -width "650" -pager "listbox"
    } else {
	lappend dialogScript -width "450"
    }
    # Add all of the dialog panes.
    foreach pane $dialogPanes {
	set dialogPane [list [set ${pane}Title]]
	if {($pane eq "intro")} {
	    lappend dialogPane [list "thepage"]
	}
	if {![info exists ${pane}Text]} {
	    continue
	}
	foreach textItem [set ${pane}Text] {
	    if {($textItem eq "divider")} {
		lappend dialogPane [list "divider" "divider"]
		continue
	    }
	    regsub -all {\s+} $textItem { } textItem
	    regsub -all {\[LB\]} $textItem "\{" textItem
	    regsub -all {\[\\R\]} $textItem "\r" textItem
	    regsub -all {\[\\N\]} $textItem "\n" textItem
	    lappend dialogPane [list "text" [string trim $textItem]]
	}
	lappend dialogScript $dialogPane
    }
    if {![catch {eval $dialogScript} results]} {
	set lastREDialogPane [lindex $results 0]
	prefs::modified lastREDialogPane
	return 1
    } else {
	help::openGeneral "Regular Expressions"
	uplevel \#1 {
	    set retVal "cancel"
	    set retCode "1"
	}
	return 0
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Miscellaneous Prefs Dialogs ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::dialogs::chooseOption" --
 # 
 # Allow the user to set a preference option based upon the names in a given 
 # "prefArray" array.  For example,
 # 
 #   set "eMailer(Choose each time)" \
 #     [list prefs::dialogs::chooseOption eMailer composeEmailUsing WWW]
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::dialogs::chooseOption {prefArray prefName prefPage args} {
    
    global $prefArray
    
    set p "[quote::Prettify $prefName]É"
    set options [lremove [array names $prefArray] [list "Choose each time"]]
    if {![llength $options]} {
	error "Cancelled -- no options for $prefName available !"
    } elseif {([llength $options] == "1")} {
	set val [lindex $options 0]
    } else {
	set setPref "(Set $prefPage preferences to avoid this dialog É)"
	lappend options $setPref
	set val [listpick -p $p $options]
	if {($val eq $setPref)} {
	    prefs::dialogs::menuProc "preferences" $prefPage
	    global $prefName
	    set val [set $prefName]
	}
    }
    eval [set [set prefArray]($val)] $args
    return
}

proc prefs::dialogs::editArrayVar {arrayName {title ""}} {
    
    global $arrayName
    
    if {($title eq "")} {
	set title "\"${arrayName}\" Array Contents"
    }
    set prefsListing [list $arrayName "" "" [array names $arrayName] \
      [list prefs::dialogs::_getPrefValue "array" $arrayName] \
      [list prefs::dialogs::_setPrefValue "array" $arrayName]]
    prefs::dialogs::makePrefsDialog $title $prefsListing
    return
}

proc prefs::dialogs::editOneOfManyVars {title var store tempStore {what ""}} {
    
    global $tempStore $store
    
    if {[regexp -- {(.*)\((.*)\)$} $var "" arr elt]} {
	global $arr
    } else {
	global $var
    }
    
    set oldInfo [array get $tempStore]
    if {[catch {prefs::dialogs::editArrayVar $tempStore $title}] \
      || ($oldInfo eq [array get $tempStore])} {
	return
    }
    set oldId [set $var]
    set q "Update [set $var] $what, or make a new one?"
    if {![dialog::yesno -y "Update" -n "New $what" $q]} {
	# Ask for new name
	set name [eval prompt [list "Enter tag for new $what" \
	  "<Tag>" "Old ids:"] [array names $store]]
	set ${store}($name) [array get $tempStore]
	set $var $name
	# Have to store Usual id too.
	prefs::modified ${store}($name)
	prefs::modified $var
    } else {
	set ${store}($oldId) [array get $tempStore]
    }
    prefs::modified ${store}($oldId)
    return
}

# ===========================================================================
# 
# .