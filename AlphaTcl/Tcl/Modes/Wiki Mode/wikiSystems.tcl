# -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # File : "wikiSystems.tcl"
 #                                          created: 02/03/2006 {05:10:33 PM}
 #                                      last update: 02/09/2006 {11:51:26 AM}
 # Description:
 # 
 # Procedures that support the identification and use of  Wiki Systems.
 # 
 # See the "wikiMode.tcl" file for license information.
 # 
 # ==========================================================================
 ##

proc wikiSystems.tcl {} {}

namespace eval WWW {}

## 
 # --------------------------------------------------------------------------
 # 
 # "WWW::defineEditUrls" --
 # 
 # Define the url patterns that indicate a hyperlink in a WWW Menu window 
 # should be opened as a wiki editing page.
 # 
 # --------------------------------------------------------------------------
 ##

proc WWW::defineEditUrls {} {
    
    variable UrlActionhttp
    
    # Capture urls which match these regexp patterns, and divert them to the
    # Wiki Menu for editing.
    array set UrlActionhttp [list \
      {.*/wiki\?edit=}          {Wiki::fetchAndEdit} \
      {.*wiki.*\?action=edit$}  {Wiki::fetchAndEdit} \
      {.*.wiki.*/\(edit\)/}     {Wiki::fetchAndEdit} \
      ]
    foreach system [Wiki::listSystems 0] {
	set pattern [Wiki::systemField $system "editUrlPattern"]
	if {($pattern ne "")} {
	  array set UrlActionhttp [list $pattern {Wiki::fetchAndEdit}]
	}
    }
    return
}

namespace eval Wiki {
    
    # Used by [Wiki::systemInfo] to determine scripts for hyperlinks.
    variable wwwMenuExists [alpha::package exists wwwMenu]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::defineSystems" --
 # 
 # Create the "wikiSystems" and "WikiSystems" variables, with the names of
 # all defined systems and their prettified equivalents.  New "userSystems" 
 # systems will _not_ be registered until this is called.  If a "system" 
 # argument is added, the "Wiki Systems" menu will be properly dimmed.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::defineSystems {args} {
    
    variable defaultSystems
    variable userSystems
    variable wikiSystems [list]
    variable WikiSystems [list]
    
    # Make sure that this has been sourced.
    wikiMethods.tcl
    
    set wikiSystems [lsort -dictionary -unique [concat \
      [array names userSystems] [array names defaultSystems]]]
    foreach system $wikiSystems {
	lappend WikiSystems [quote::Prettify $system]
    }
    if {[llength $args]} {
        catch {Wiki::postBuildSystems}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::listSystems" --
 # 
 # List all of the registered Wiki Systems.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::listSystems {{prettify 1} {listingType "all"}} {
    
    variable defaultSystems
    variable wikiSystems
    variable WikiSystems
    variable userSystems
    
    if {![info exists wikiSystems]} {
	Wiki::defineSystems
    }
    set removeList [list]
    switch -- $listingType {
        "user-modified" {
	    foreach system [array names userSystems] {
		if {![info exists defaultSystems($system)]} {
		    lappend removeList $system
		}
	    }
	    foreach system [array names defaultSystems] {
		if {![info exists userSystems($system)]} {
		    lappend removeList $system
		}
	    }
        }
        "user-only" {
	    set removeList [array names defaultSystems]
	}
	"default-only" {
	    foreach system [array names userSystems] {
		if {![info exists defaultSystems($system)]} {
		    lappend removeList $system
		}
	    }
	}
	"not-modified" {
	    set removeList [array names userSystems]
        }
	default {
	    if {($listingType ne "all")} {
	        error "Unknown listing type: $listingType"
	    }
	}
    }
    if {!$prettify} {
	return [lremove $wikiSystems $removeList]
    } else {
	set RemoveList [list]
	foreach system $removeList {
	    lappend RemoveList [quote::Prettify $system]
	}
	return [lremove $WikiSystems $RemoveList]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::systemName" --
 # 
 # Massage the given system name as specified.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::systemName {system {prettify 1}} {
    
    set allSystems [Wiki::listSystems 0]
    set AllSystems [Wiki::listSystems 1]
    if {([set idx [lsearch -exact $allSystems $system]] == -1) \
      && ([set idx [lsearch -exact $AllSystems $system]] == -1)} {
	return $system
    } elseif {!$prettify} {
        return [lindex $allSystems $idx]
    } else {
        return [lindex $AllSystems $idx]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::systemField" --
 # 
 # Return the field value for a given Wiki System.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::systemField {system field {defaultValue ""}} {
    
    variable defaultSystems
    variable userSystems
    
    set system [Wiki::systemName $system 0]
    
    if {($system eq "")} {
	return $defaultValue
    } elseif {([lsearch [Wiki::listSystems 0] $system] == -1)} {
	error "Unknown wiki system: $system"
    }
    if {[info exists userSystems($system)]} {
	array set systemInfo $userSystems($system)
    } else {
	array set systemInfo $defaultSystems($system)
    }
    if {[info exists systemInfo($field)]} {
	return $systemInfo($field)
    } else {
	return $defaultValue
    }
    return
}

# ===========================================================================
# 
# ×××× Wiki System <-> Urls ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::buildEditUrl" --
 # 
 # Given the url of a wiki page, generate its corresponding editing url.  The
 # name of the supplied system can be prettified or not.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::buildEditPageUrl {url} {
    
    set system [Wiki::getEditWikiSystem $url]
    if {($system eq "")} {
	error "Cancelled -- no Wiki System recognized for this url."
    }
    Wiki::verifyBuildUrlPat $system 1
    set patterns [Wiki::systemField $system "buildEditUrlPats"]
    append exp  [lindex $patterns 0] "$"
    set subSpec [lindex $patterns 1]
    regsub $exp $url $subSpec url
    return $url
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::verifyBuildUrlPat" --
 # 
 # Using the "wikiExamples" urls, attempt to translate the first into the
 # second using the defined "buildEditUrlPats" patterns.  To test the
 # "buildEditUrlPats" routine for all systems, open a [tclShell] window and
 # enter this
 # 
 #     Wiki::verifyBuildUrlPat -all
 # 
 # to find out which systems need further verification.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::verifyBuildUrlPat {system {throwError "0"}} {
    
    variable defaultSystems
    variable userSystems
    
    if {($system eq "-all")} {
	set buildPatErrors [list]
        foreach system [Wiki::listSystems 0] {
	    if {[catch {Wiki::verifyBuildUrlPat $system 1} errorMsg]} {
		regsub -all -- {^Cancelled -- } $errorMsg {} errorMsg
		lappend buildPatErrors $errorMsg
	    }
	}
	if {![llength $buildPatErrors]} {
	    return "All build edit url patterns were valid."
	} else {
	    append results [string repeat "-" 77] "\r"
	    foreach errorMsg $buildPatErrors {
		append results [breakIntoLines $errorMsg] "\r" \
		  [string repeat "-" 77] "\r"
	    }
	    return $results
	}
    }
    set system [Wiki::systemName $system 0]
    if {[info exists userSystems($system)]} {
	set fieldValueList $userSystems($system)
    } elseif {[info exists defaultSystems($system)]} {
	set fieldValueList $defaultSystems($system)
    } else {
	error "Cancelled -- \"$system\" is not a defined system."
    }
    array set settings $fieldValueList
    # Check the "buildEditUrlPats" patterns.
    set buildPatError ""
    if {![info exists settings(buildEditUrlPats)]} {
	set buildPatError "Missing \"build edit url\" patterns"
    } elseif {([set pat0 [lindex $settings(buildEditUrlPats) 0]] eq "")} {
	set buildPatError "Empty first \"build edit url\" pattern"
    } elseif {([set pat1 [lindex $settings(buildEditUrlPats) 1]] eq "")} {
	set buildPatError "Empty second \"build edit url\" pattern"
    } elseif {![info exists settings(wikiExamples)]} {
	set buildPatError "Missing \"wiki examples\""
    } elseif {([set url0 [lindex $settings(wikiExamples) 0]] eq "")} {
	set buildPatError "Empty first \"wiki example\" url"
    } elseif {([set url1 [lindex $settings(wikiExamples) 1]] eq "")} {
	set buildPatError "Empty first \"wiki example\" url"
    } elseif {[catch {regexp -nocase -- "${pat0}\$" $url0} regexpError]} {
	set buildPatError $regexpError
    } elseif {!$regexpError} {
	set buildPatError "First build edit url pattern doesn't match example."
    } elseif {[catch {regsub -nocase -- "${pat0}\$" $url0 $pat1 newUrl}]} {
	set buildPatError $newUrl
    } elseif {($newUrl ne $url1)} {
	set buildPatError "The \"Edit Url Patterns\" did not produce\
	  the second wiki example url.\
	  \r\rResult:\r\r$newUrl\
	  \r\rExpected:\r\r$url1"
    }
    if {($buildPatError eq "")} {
	return 1
    } elseif {!$throwError} {
	return 0
    } else {
	append errorMsg "\"" [Wiki::systemName $system 1] \
	  "\" wiki system error:\r\r" \
	  $buildPatError
	dialog::alert -title "Build Edit Url Error" -width 550 $errorMsg
	error "Cancelled -- $errorMsg"
    }
}

##
 # --------------------------------------------------------------------------
 #       
 # "Wiki::getEditWikiSystem" --
 #      
 # Attempt to determine the proper "wikiSystem" for a given Wiki window name
 # and its associated url.  We try to rely on pre-defined Projects, but if
 # that fails (as will often be the case when the Edit page was called from a
 # WWW window) we check the patterns defined in the "identifyingPat" array.
 # 
 # The return value is the unprettified name of the Wiki System.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::getEditWikiSystem {url} {
    
    variable editUrlSystem
    
    Wiki::currentProject
    
    # We first attempt to determine if the url is related to the settings for
    # our current project.
    if {[Wiki::validateUrlForProject $url $project 0]} {
	# We have a current project, so we'll use that system.
	set system [Wiki::projectField $project "WikiSystem"]
    } else {
	# If that didn't work, attempt to find it by parsing urls.
	set system [Wiki::getWikiSystemForUrl $url]
    }
    if {([set system [Wiki::systemName $system 0]] ne "")} {
	set editUrlSystem($url) $system
    }
    return $system
}

##
 # --------------------------------------------------------------------------
 #       
 # "Wiki::getPostWikiSystem" --
 #      
 # Attempt to determine the proper "wikiSystem" for a given Wiki window name
 # and its associated url.  We try to rely on pre-defined Projects, but if
 # that fails (as will often be the case when the Edit page was called from a
 # WWW window) we check the patterns defined in the "identifyingPat" array.
 # 
 # The return value is the unprettified name of the Wiki System.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::getPostWikiSystem {winName url} {
    
    variable editUrlSystem
    
    if {[info exists editUrlSystem($url)]} {
	# We determined a system for this url when we created the window.
    }
    set project [Wiki::findWindowProject $winName]
    if {($project ne "")} {
	# We have a project ...
	set System [Wiki::projectField $project "WikiSystem"]
	if {($System ne "undefined")} {
	    # ... and a Wiki System defined for this window.
	    return [Wiki::systemName $System 0]
	}
    }
    # If that didn't work, attempt to find it by parsing urls.
    return [Wiki::getWikiSystemForUrl $url [list "post" "view" "edit"]]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::getUrlWikiSystem" --
 # 
 # Attempt to determine the proper Wiki System for the given url.  This 
 # should work for both "display" and "edit" urls.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::getWikiSystemForUrl {url {urlTypes ""}} {
    
    set allSystems [Wiki::listSystems 0]
    # First try "wikiSiteUrls"
    foreach system $allSystems {
	foreach wikiSiteUrl [Wiki::systemField $system "wikiSiteUrls"] {
	    append pattern "*" $wikiSiteUrl "/*"
	    if {[string match -nocase $pattern $url]} {
		return $system
	    }
	    unset pattern
	}
    }
    # Nothing yet, so we'll try checking url regexp patterns.
    if {![llength $urlTypes]} {
	set urlTypes [list "view" "edit" "post"]
    }
    foreach system $allSystems {
	foreach urlType $urlTypes {
	    set pattern [Wiki::systemField $system ${urlType}UrlPattern]
	    if {($pattern eq "")} {
		continue
	    } elseif {![catch {regexp -nocase -- $pattern $url} match] && $match} {
		return $system
	    }
	}
    }
    # Now we're starting to get desperate.
    foreach system $allSystems {
	set patterns [Wiki::systemField $system "buildEditUrlPats"]
	if {([llength $patterns] != 2)} {
	    continue
	}
	set pattern [lindex $patterns 1]
	regsub -all -- {\\[0-9]}    $pattern {.*}       pattern
	regsub -all -- {([^\\]?)\?} $pattern {\1\\?}    pattern
	regsub -all -- {&}          $pattern {.*}       pattern
	if {[catch {regexp -- $pattern $url} result]} {
	    continue
	} elseif {$result} {
	    return $system
	}
    }
    # Still here?
    return ""
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Systems Menu ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::buildSystemsMenu" --
 # 
 # Return the list of "Wiki Menu > Wiki Systems" items required by the
 # [menu::buildSome] procedure.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::buildSystemsMenu {} {
    
    Wiki::currentProject
    
    set System [Wiki::projectField $project "WikiSystem"]
    if {($System ne "undefined")} {
	set WikiSystemInfo [menu::itemWithIcon "\"$System\" Info" 83]
    } else {
	set WikiSystemInfo [menu::itemWithIcon "(Undefined Wiki System" 82]
    }
    set menuList [list "Wiki Systems InfoÉ" "$WikiSystemInfo" "(-)" \
      "Add New SystemÉ" "Edit SystemÉ" "Rename SystemÉ" "Delete SystemÉ" \
      "Reset SystemsÉ" "(-)" "Export SystemÉ" "Wiki Systems Help"]
    
    set menuProc "Wiki::systemsMenuProc -m -M Wiki"
    return [list "build" $menuList $menuProc]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::postBuildSystems" --
 # 
 # Dim/enable "Wiki Menu > Wiki Systems" menu items as necessary.  Wrap this
 # in a [catch] if it is possible that procedures are being called via Help
 # file hyperlinks when this package has not been turned on.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::postBuildSystems {} {
    
    variable userSystems
    
    set dim1 [expr {([llength [Wiki::listSystems "0" "user-only"]] > 0)}]
    set dim2 [expr {([llength [Wiki::listSystems "0" "user-modified"]] > 0)}]
    set dim3 [expr {([array size userSystems] > 0)}]
    foreach menuItem [list "Rename SystemÉ" "Delete SystemÉ"] {
	enableMenuItem -m "Wiki Systems" $menuItem      $dim1
    }
    enableMenuItem -m "Wiki Systems" "Reset SystemsÉ"   $dim2
    enableMenuItem -m "Wiki Systems" "Export SystemÉ"   $dim3
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::systemsMenuProc" --
 # 
 # Handle all "Wiki Menu > Wiki Systems" menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::systemsMenuProc {menuName menuItem} {
    
    Wiki::currentProject
    
    set System [Wiki::projectField $project "WikiSystem"]
    if {($menuItem eq "\"$System\" Info")} {
	Wiki::systemInfo [list $System]
	return
    }
    switch -- $menuItem {
	"Wiki Systems Info" {
	    Wiki::systemInfo
	}
	"Add New System" {
	    Wiki::newSystem
	}
	"Edit System" {
	    Wiki::editSystem
	}
	"Rename System" {
	    Wiki::renameSystem
	}
	"Delete System" {
	    Wiki::deleteSystem
	}
	"Reset Systems" {
	    Wiki::resetSystems
	}
	"Export System" {
	    Wiki::exportSystem
	}
	"Wiki Systems Help" {
	    help::openGeneral "Wiki Menu Help" "Wiki Systems Help"
	}
    }
    return
}

# ===========================================================================
# 
# ×××× Systems Utilities ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::systemInfo" --
 # 
 # Open a new window with information about a given Wiki System.  The list of
 # systems in "systemsList" can be prettified or not.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::systemInfo {{systemsList ""}} {
    
    global alpha::application WikimodeVars
    
    variable wwwMenuExists
    
    set chooseAll  "(All Systems)"
    set allSystems [set AllSystems [list "(All Systems)"]]
    set allSystems [concat [list $chooseAll] [Wiki::listSystems 0]]
    set AllSystems [concat [list $chooseAll] [Wiki::listSystems 1]]
    if {($systemsList eq "-all")} {
	set systemsList [list $chooseAll]
    } elseif {(![llength $systemsList])} {
	set L [list $chooseAll]
	if {[info exists WikimodeVars(wikiProject)]} {
	    # The Wiki Menu has been activated.
	    set project $WikimodeVars(wikiProject)
	    set System [Wiki::projectField $project "WikiSystem"]
	    if {([lsearch $AllSystems $System] > -1)} {
		set L [list $System]
	    }
	}
	set p "Show information for which Wiki System(s):"
	set indices [listpick -p $p -L $L -l -indices $AllSystems]
	foreach idx $indices {
	    lappend systemsList [lindex $allSystems $idx]
	}
    }
    if {([lsearch $systemsList $chooseAll] > -1)} {
	set systemsList [lrange $AllSystems 1 end]
    }
    set txt "\rWiki Systems Information:\r\r"
    append txt {
This window contains information about the "Wiki Systems" that are
currently registered in ÇALPHAÈ's Wiki Menu.  Each system can be modified
if it is not working properly.  You can also add new systems.  For more
information see the "Wiki Menu # Wiki Systems Help" file.
}
	if {($systemsList ne [list $chooseAll])} {
	    append txt {
Click here

<<Wiki::systemInfo>>

to re-create this window with information about a different wiki system.
}
    }
    foreach system $systemsList {
	set system [Wiki::systemName $system 0]
	set System [Wiki::systemName $system 1]
	foreach field [list "description" "wikiExamples" "homeSite" \
	  "postIsEnabled" "maintainer" "wikiSiteUrls" "buildEditUrlPats" \
	  "editUrlPattern" "viewUrlPattern" "postUrlPattern" "wikiSiteUrls"] {
	    set $field [Wiki::systemField $system $field ""]
	}
	append txt [string repeat "_" 80] "\r\r" \
	  "\t  \t" $System "\r\r" \
	  "Click here <<Wiki::editSystem $system>> " \
	  "to edit the following settings." \
	  "\r\rDescription:\r"
	# Description.
	if {([string trim $description] ne "")} {
	    append txt $description "\r"
	} else {
	    append txt "Sorry, no description is available.\r\r"
	}
	# Examples.
	if {([llength $wikiExamples] == 2)} {
	    append txt "Example Wiki Pages:\r\r" \
	      "    Ü[lindex $wikiExamples 0]Ý\r\r" \
	      "    Ç[lindex $wikiExamples 1]È\r\r"
	}
	# Wiki System Home Page
	if {([string trim $homeSite] ne "")} {
	    append txt "Wiki System Home Site:\r\r\t<" \
	      $homeSite ">\r\r"
	}
	# Posting
	append txt "Internal ÇALPHAÈ posting to remote server:\r\r\t"
	switch -- $postIsEnabled {
	    "-1" {
		append txt "Is available, but not recommended." \
		  "\r\r    (Use \"Wiki Menu > Save in Browser\" instead.)"
	    }
	    "0" {
		append txt "Is not available." \
		  "\r\r    (Use \"Wiki Menu > Save in Browser\" instead.)"
	    }
	    "1" {
		append txt "Is available."
	    }
	    default {
		append txt "Has not been thoroughly tested."
	    }
	}
	append txt "\r\r"
	append txt [string repeat "-" 60] "\r\r"
	# Alpha Wiki System Info
	append txt "ÇALPHAÈ Wiki Menu system name:  \"" $system "\"\r\r"
	# Maintainer
	if {([string trim $maintainer] ne "")} {
	    append txt "AlphaTcl Wiki System Maintainer: " \
	      $maintainer "\r\r"
	}
	# Wiki Sites
	if {([llength $wikiSiteUrls])} {
	    append txt "Url Patterns Indicating Wiki System:\r\r"
	    foreach wikiSiteUrl $wikiSiteUrls {
		append txt "\t" $wikiSiteUrl "\r"
	    }
	    append txt "\r"
	}
	# Build Edit Url Patterns
	append txt "Build Edit Url Regular Expressions:\r\r\t" \
	  [lindex $buildEditUrlPats 0] "\r\t" \
	  [lindex $buildEditUrlPats 1] "\r\r"
	# Other Identifying Patterns
	append txt "Other Identifying Patterns:\r\r"
	foreach type [list "edit" "post" "view"] {
	    if {([set ${type}UrlPattern] ne "")} {
		append txt "\t" [set ${type}UrlPattern] "\r"
	    } else {
		append txt "    (none)\r"
	    }
	}
	append procName "Wiki::" $system "::postToServer"
	if {[llength [info procs ::$procName]]} {
	    append txt "\rSpecial posting proc: $procName\r"
	}
    }
    append txt "\r" [string repeat "_" 80] "\r\r"
    regsub -all {ÇALPHAÈ} $txt $alpha::application txt
    set w "* Wiki Systems Information *"
    if {[win::Exists $w]} {
	bringToFront $w
	win::setInfo $w read-only 0
	replaceText -w $w [minPos -w $w] [maxPos -w $w] $txt
	catch {removeColorEscapes -w $w}
	removeAllMarks -w $w
    } else {
	set w [new -n $w -tabsize 4 -text $txt]
    }
    goto -w $w [minPos -w $w]
    help::markColourAndHyper -w $w
    # Create hyperlinks for our examples.
    set pattern {Ü((https?|news|mailto|ftp|afp|smb):[^ Ý]*)Ý}
    if {$wwwMenuExists} {
	set script {WWW::renderUrl "\1"}
    } else {
	set script {url::execute "\1"}
    }
    win::searchAndHyperise -w $w $pattern $script 1 3
    set pattern {Ç((https?|news|mailto|ftp|afp|smb):[^ È]*)È}
    set script  {Wiki::fetchAndEdit "\1"}
    win::searchAndHyperise -w $w $pattern $script 1 3
    refresh
    winReadOnly $w
    if {([set marks [llength [getNamedMarks -w $w]]] > 1)} {
	status::msg "$marks systems listed; see the Marks menu to navigate."
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::newSystem" --
 # 
 # Allow the user the add new systems.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::newSystem {} {
    
    variable newSystemDefaults
    variable userSystems
    
    # We always save the values entered by the user, since this is something
    # of a complicated set of dialogs and it might take one of two sessions
    # to figure out everything that needs to be added.
    prefs::modified newSystemDefaults
    
    set description "\tAdded by user on [mtime [now]]"
    # (0) Introduction.
    set dialogPanes(0) [list "Introduction" \
      [list "text" "You have started to create a new Wiki System.  This\
      system will be available for any of your Wiki Projects, and can help\
      identify or create the editing url for pages of specific wiki sites.\r"] \
      [list "text" "The following dialogs will help you to create this new\
      system; you can postpone the creation at any time by pressing the\
      \"Cancel\" button, and any previously entered values will be used\
      as the defaults when you start again.\r"] \
      ]
    # (1) Wiki System Name.
    set dialogPanes(1) [list "Wiki System Name and Description" \
      [list "var"  "First you must name your system:" Ç1,0È] \
      [list [list "smallval" "static"] "Description:" $description] \
      [list "text" "Is this system actively maintained by some group of\
      software developers?  If so, identify their web site.\r"] \
      [list [list "smallval" "url"] "System Maintainer Web Site:" Ç1,2È] \
      ]
    # (2) Wiki Page Examples.
    set dialogPanes(2) [list "Example Wiki Pages" \
      [list "text" "You need to define some example wiki pages; both of\
      these should point to \"Sandbox\" or \"Graffiti\" pages.\r"] \
      [list [list "smallval" "url"] "View Url:" Ç2,0È] \
      [list [list "smallval" "url"] "Edit Url:" Ç2,1È] \
      [list "text" ""] \
      [list [list "smallall" "text"] "These urls are used to help verify\
      the next pair of regular expression patterns.\r"]
      ]
    # (3) "Build Edit Url" patterns.
    set dialogPanes(3) [list "\"Build Edit Url\" Patterns" \
      [list "text" "You must add some regular expression patterns that will\
      convert a \"view\" wiki page url into an \"edit\" url.\r"] \
      [list [list "smallval" "static"] "View Url:" Ç2,0È] \
      [list [list "smallval" "static"] "Edit Url:" Ç2,1È] \
      [list "text" "\r"] \
      [list "text" "Define the two regular expression patterns that will\
      convert the first url to the second using \[regsub\].\r"] \
      [list "var" "Pattern:" Ç3,2È] \
      [list "var" "SubSpec:" Ç3,3È] \
      [list [list "smallall" "text"] "These patterns are used by the\
      \"Wiki Menu > Edit Wiki Page\" command to convert a \"view url\".\r"] \
      ]
    # (4) Wiki Site Examples.
    set dialogPanes(4) [list "Wiki Site Examples" \
      [list "text" "If you know of some web sites that use this wiki system,\
      list their base urls here.  This helps ensure that wiki pages will\
      be properly downloaded from and uploaded to the remote server.\r"] \
      [list "var2" "Wiki Web Sites Using This System:" Ç4,0È] \
      [list [list "smallval" "static"] "Instead of:  " "http://www.tcl.tk/wiki/"] \
      [list [list "smallval" "static"] "just include:" "tcl.tk/wiki"] \
      [list "text" "and any leading protocol info or trailing slash will be\
      added when performing a \"string match\" against a given url. Separate\
      each different site with a space.\r"] \
      ]
    # (5) View/Edit/Post patterns.
    set dialogPanes(5) [list "Other Url Patterns" \
      [list "text" "If there are other patterns which will unambiguously\
      identify a url as one created by this wiki system, enter them below.\r"] \
      [list "text" "For example, if a url looked like\r"] \
      [list [list "smallval" "static"] "For example, if a url looked like" \
      "http://openwiki.com/ow.asp?p=SandBox&a=edit"] \
      [list [list "smallval" "static"] "then the patttern would be" \
      "/ow\.asp\?.*&a=edit"] \
      [list "var" "View Pattern:" Ç5,2È] \
      [list "var" "Edit Pattern:" Ç5,3È] \
      [list "var" "Post Pattern:" Ç5,4È] \
      [list [list "smallval" "static"] "If the pattern is ambiguous, like" \
      "\&action=edit"] \
      [list "text" "and could be used by other wiki systems or \"normal\" web\
      pages, then just leave these pattern settings empty.\r"] \
      ]
    # (6) Confirm to continue.
    set dialogPanes(6) [list "Final Confirmation" \
      [list "text" "Please confirm the new settings in the next dialog, and\
      then press \"OK\" to save them."] \
      ]

    set postpone 0
    for {set step 0} {($step <= 6)} {incr step} {
	# Massage the dialog pane as necessary.
	set dialogPane $dialogPanes($step)
	if {![info exists newSystemDefaults($step)]} {
	    set newSystemDefaults($step) [list]
	}
	while {[regexp -- {Ç(\d+),(\d+)È} $dialogPane -> idx1 idx2]} {
	    set defaultValue [lindex $newSystemDefaults($idx1) $idx2]
	    if {[regexp -- {Ç(\d+),(\d+)È} $defaultValue]} {
	        set defaultValue ""
	    }
	    set defaultValue [quote::Regsub $defaultValue]
	    regsub -all -- "Ç${idx1},${idx2}È" $dialogPane $defaultValue dialogPane
	}
	if {($step == 0)} {
	    set title "Add New Wiki System"
	    status::msg $title
	} else {
	    set title "New Wiki System: Step $step of 6"
	    status::msg $title
	}
	set buttons [list "Help" \
	  "Click this button for more Wiki Systems Help" \
	  "set retCode 1 ; set retVal helpWindow"]
	if {($step > 0)} {
	    lappend buttons "Go Back" \
	      "Click here to go back to the previous step" \
	      "set retCode 1 ; set retVal goBack"
	}
	# Now we present the dialog, and deal with the results.
	set dialogScript [list dialog::make -title $title -width 450 \
	  -ok "Continue" -addbuttons $buttons $dialogPane]
        if {![catch {eval $dialogScript} results]} {
	    set newSystemDefaults($step) $results
	} elseif {($results eq "goBack")} {
	    incr step -2
	    continue
        } elseif {($results eq "helpWindow")} {
	    switch -- $step {
		"1"     {set markName "Wiki System Name"}
	        "2"     {set markName "Wiki Example Urls"}
		"3"     {set markName "Build Edit Url Patterns"}
		"4"     {set markName "Wiki Sites Using System"}
		"5"     {set markName "Other Identifying Url Patterns"}
	        default {set markName "Adding New Systems"}
	    }
	    help::openGeneral "Wiki Menu Help" $markName
	    set postpone 1
	    break
        } else {
	    set postpone 1
            break
        }
	# Do a preliminary verification of the settings.
	switch -- $step {
	    "1" {
		set system [string trim [lindex $results 0]]
	        if {($system eq "")} {
	            alertnote "The name cannot be an empty string!"
		    incr step -1
		} elseif {![regexp -- {^[-a-zA-Z0-9 ]+$} $system]} {
		    alertnote "The name must be alpha-numeric!"
		    incr step -1
	        } elseif {([lsearch [Wiki::listSystems 0] $system] > -1) \
		  || ([lsearch [Wiki::listSystems 1] $system] > -1)} {
		    alertnote "The name \"$system\" is already used by a\
		      defined Wiki system.  Please try a different name."
		    incr step -1
	        }
	    }
	    "2" {
		if {([string trim [lindex $results 0]] eq "") \
		  && ([string trim [lindex $results 1]] eq "")} {
		    alertnote "The example urls must be defined!"
		    incr step -1
		}
	    }
	    "3" {
		set "userSystems(New System)" [list \
		  "wikiExamples"     [lrange $newSystemDefaults(2) 0 1] \
		  "buildEditUrlPats" [lrange $newSystemDefaults(3) 2 3] \
		  ]
		if {([string trim [lindex $results 2]] eq "") \
		  && ([string trim [lindex $results 3]] eq "")} {
		    alertnote "The regexp patterns must be defined!"
		    incr step -1
		} elseif {[catch {Wiki::verifyBuildUrlPat "New System" 1}]} {
		    incr step -1
		}
		unset "userSystems(New System)"
	    }
	}
    }
    if {$postpone} {
	status::msg "New Wiki System: postponed."
	return
    }
    # Add the new settings.
    regsub -all -- {\s+} [lindex $newSystemDefaults(1) 0] {} system
    set userSystems($system) [list \
      "description"             [lindex $newSystemDefaults(1) 1] \
      "homeSite"                [lindex $newSystemDefaults(1) 2] \
      "wikiExamples"            [lrange $newSystemDefaults(2) 0 1] \
      "buildEditUrlPats"        [lrange $newSystemDefaults(3) 2 3] \
      "viewUrlPattern"          [lindex $newSystemDefaults(4) 0] \
      "editUrlPattern"          [lindex $newSystemDefaults(4) 1] \
      "postUrlPattern"          [lindex $newSystemDefaults(4) 2] \
      "wikiSiteUrls"            [lindex $newSystemDefaults(5) 0] \
      "postIsEnabled"           "2" \
      ]
    Wiki::defineSystems $system
    if {[catch {Wiki::editSystem $system} errorMsg]} {
        unset userSystems($system)
	Wiki::defineSystems $system
	error "Cancelled."
    } else {
        prefs::modified userSystems($system)
	status::msg "The new system has been added."
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::editSystem" --
 # 
 # Edit the settings of a defined system.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::editSystem {{system ""}} {
    
    variable defaultSystems
    variable userSystems
    
    if {($system ne "")} {
        set askToEdit 0
    } else {
	set askToEdit 1
	set p "Edit which system?"
	set options  [lsort -dictionary [Wiki::listSystems 1]]
	set system   [listpick -p $p $options]
    }
    set system [Wiki::systemName $system 0]
    if {([lsearch [Wiki::listSystems 0] $system] == -1)} {
        error "Cancelled -- \"$system\" is not a defined system."
    }
    append System "\"" [Wiki::systemName $system 1] "\""
    # Make sure that our systems are in the correct order, corresponding to 
    # how we present them in the dialog.
    set systemFields [list "description" "homeSite" "wikiSiteUrls" \
      "editUrlPattern" "postUrlPattern" "viewUrlPattern" \
      "wikiExamples" "buildEditUrlPats" "postIsEnabled"]
    set oldSettings [list]
    foreach field $systemFields {
	lappend oldSettings $field [Wiki::systemField $system $field]
    }
    array set settings $oldSettings
    set postOptions [list "Is Not Allowed" "Is Allowed" "Is Not Recommended" \
      "Needs More Testing"]
    # Create and present an editing dialog.
    set dialogScript [list dialog::make -title "Edit System Settings" \
      -width 450 -addbuttons [list "Help" \
      "Click this button for more Wiki Systems Help" \
      "set retCode 1 ; set retVal cancel ; \
      help::openGeneral {Wiki Menu Help} {Modifying Existing Systems}"] \
      [list "Identification" \
      [list [list "smallval" "url"]  "Home Site:" $settings(homeSite)] \
      [list "var2" "Web site wikis which use the $System system:" \
      $settings(wikiSiteUrls)] \
      [list "text" "These patterns are used to associate a given url with\
      the $System system.  If you cannot create unambiguous patterns here,\
      then leave these fields blank.\r"] \
      [list "var"  "Edit Url Pattern:"  $settings(editUrlPattern)] \
      [list "var"  "View Url Pattern:"  $settings(viewUrlPattern)] \
      [list "var"  "Post Url Pattern:"  $settings(postUrlPattern)] \
      ] \
      [list "Fetching and Posting" \
      [list "text" "Don't change these values unless you're sure that you\
      know what you're doing!  These help verify \"edit\" url patterns.\r"] \
      [list [list "smallval" "url"]  "Example View Page:" \
      [lindex $settings(wikiExamples) 0]] \
      [list [list "smallval" "url"]  "Example Edit Page:" \
      [lindex $settings(wikiExamples) 1]] \
      [list "text" "\r"] \
      [list "text" "These next two patterns are used to build an \"edit\" url\
      given the address of a \"view\" page.\r"] \
      [list "var"  "Edit Pattern:" [lindex $settings(buildEditUrlPats) 0]] \
      [list "var"  "Edit SubSpec:" [lindex $settings(buildEditUrlPats) 1]] \
      [list [list "menuindex" $postOptions] "Internal Posting" \
      $settings(postIsEnabled)] \
      ]]
    set results [eval $dialogScript]
    set newSettings [lrange $oldSettings 0 1]
    set resultsIdx 0
    for {set i 1} {($i < [llength $systemFields])} {incr i} {
	set doubleValueFields [list "wikiExamples" "buildEditUrlPats"]
	set field [lindex $systemFields $i]
	set value [lindex $results $resultsIdx]
	if {([lsearch $doubleValueFields $field] > -1)} {
	    set value [list $value [lindex $results [incr resultsIdx]]]
	}
	lappend newSettings $field $value
	incr resultsIdx
    }
    if {($oldSettings ne $newSettings)} {
	set userSystems($system) $newSettings
	prefs::modified userSystems($system)
	status::msg "The settings for the system $System have been saved."
	WWW::defineEditUrls
	catch {Wiki::postBuildSystems}
    } else {
        status::msg "No changes."
    }
    if {[catch {Wiki::verifyBuildUrlPat $system 1}]} {
	set msg "Please edit the $System system settings to correct\
	  the \"build edit url pattern\" errors"
	if {([lsearch [Wiki::listSystems 0 "default-only"] $system] > -1)} {
	    append msg ", or select the \"Wiki Systems > Reset System\" command\
	      to restore the original version."
	} else {
	    append msg "."
	}
	alertnote $msg
	return [Wiki::editSystem $system]
    }
    set q "Would you like to edit another system?"
    if {$askToEdit && ([llength [Wiki::listSystems]] > 1) && [askyesno $q]} {
	Wiki::editSystem
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::renameSystem" --
 # 
 # Rename a system that has been added by the user.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::renameSystem {} {
    
    variable userSystems
    
    set SystemList [Wiki::listSystems "1" "user-only"]
    if {![llength $SystemList]} {
	catch {Wiki::postBuildSystems}
	dialog::errorAlert "Cancelled -- there are no systems to rename."
    }
    set p "Rename which system?"
    set OldName [listpick -p $p $SystemList]
    set oldName [Wiki::systemName $OldName 0]
    set NewName $OldName
    set p "Rename \"$OldName\" to:"
    while {1} {
        set NewName [prompt $p $NewName]
	if {([string trim $NewName] eq "")} {
	    alertnote "The name cannot be an empty string!"
	} elseif {($OldName eq $NewName)} {
	    break
	} elseif {([lsearch [Wiki::listSystems 0] $NewName] > -1) \
	  || ([lsearch [Wiki::listSystems 1] $NewName] > -1)} {
	    alertnote "The name \"$NewName\" is already used by a\
	      defined Wiki system.  Please try a different name."
	} else {
	    break
	}
    }
    regsub -all -- {\s+} $NewName {} newName
    if {($OldName eq $NewName)} {
	status::msg "No changes."
    } else {
	set userSystems($newName) $userSystems($oldName)
	prefs::modified userSystems($oldName) userSystems($newName)
	unset userSystems($oldName)
	Wiki::defineSystems $system
	status::msg "The system \"$OldName\" has been renamed to \"$NewName\"."
    }
    set q "Would you like to rename another system?"
    if {([llength $SystemList] > 1) && [askyesno $q]} {
	Wiki::renameSystem
    }
    return
}
## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::deleteSystem" --
 # 
 # Delete a system which had been added by the user.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::deleteSystem {} {
    
    variable userSystems
    
    set SystemList [Wiki::listSystems "1" "user-only"]
    if {![llength $SystemList]} {
	catch {Wiki::postBuildSystems}
	dialog::errorAlert "Cancelled -- there are no systems to delete."
    }
    set p "Delete which system(s)?"
    set RemoveList [listpick -p $p -l $SystemList]
    foreach System $RemoveList {
	set system [Wiki::systemName $System 0]
	if {[info exists userSystems($system)]} {
	    prefs::modified userSystems($system)
	    unset userSystems($system)
	}
    }
    Wiki::defineSystems $system
    if {([llength $RemoveList] == 1)} {
        status::msg "The system \"[lindex $RemoveList 0]\" has been deleted."
    } else {
        status::msg "The systems \"[join $RemoveList {, }]\" have been deleted."
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::resetSystems" --
 # 
 # Delete the user's modified settings for a system.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::resetSystems {} {
    
    variable userSystems
    
    set SystemList [Wiki::listSystems "1" "user-modified"]
    if {![llength $SystemList]} {
	catch {Wiki::postBuildSystems}
	dialog::errorAlert "Cancelled -- there are no systems to reset."
    }
    set p "Reset which system(s)?"
    set ResetList [listpick -p $p -l $SystemList]
    set Restored  [list]
    foreach System $ResetList  {
	set q "Are you sure that you want to restore the default \"$System\"\
	  settings? This cannot be undone."
	if {![askyesno $q]} {
	    continue
	}
	set system [Wiki::systemName $System 0]
	if {[info exists userSystems($system)]} {
	    prefs::modified userSystems($system)
	    unset userSystems($system)
	}
	lappend Restored $System
    }
    catch {Wiki::postBuildSystems}
    if {![llength $Restored]} {
	status::msg "No changes."
    } elseif {([llength $Restored] == 1)} {
	status::msg "The system \"[lindex $Restored 0]\" has been restored."
    } else {
	status::msg "The systems \"[join $Restored {, }]\" have been restored."
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::exportSystem" --
 # 
 # Create a new window with the user's modified Wiki System definition so 
 # that it can be e-mailed to this package's maintainer.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::exportSystem {} {
    
    global alpha::application
    
    variable userSystems
    
    set SystemList [list]
    foreach system [lsort -dictionary [array names userSystems]] {
	lappend SystemList [Wiki::systemName $system 1]
    }
    if {![llength $SystemList]} {
	catch {Wiki::postBuildSystems}
	dialog::errorAlert "Cancelled -- there are no systems to export."
    }
    set dialogScript [list dialog::make -title "Export Wiki Systems" \
      -width 450 -ok "Export" -addbuttons [list "Help" \
      "Click this button for more Wiki Systems Help" \
      "set retCode 1 ; set retVal cancel ; \
      help::openGeneral {Wiki Menu Help} {Exporting System Settings}"] \
      [list "" \
      [list "text" "The pop-up menu below includes the names of all of the\
      wiki systems that you have either modified or added.  If you think that\
      these should be included in the next release, you can \"export\" these\
      settings to a new window and then e-mail its contents to the current\
      maintainer of ${alpha::application}'s Wiki Menu.\r"] \
      [list [list "menu" $SystemList] "Modified Wiki Systems:"] \
      ]]
    set System [lindex [eval $dialogScript] 0]
    set system [Wiki::systemName $System 0]
    # Create a window header.
    set txt {
Export Wiki System Settings

This window contains the current settings for the "SYSTEM" Wiki System.

If you would like to suggest that these be included in the next release,
please send them to the current maintainer of the "Wiki Menu" as listed in
the "Installed Packages" help file.
}
    regsub -all -- {SYSTEM} $txt $System txt
    # Gather our settings.
    append txt "\r" [string repeat "_" 80] "\r\r" \
      "set Wiki::userSystems\(" $system "\) \[list \\\r" \
      "  \"buildEditUrlPats\"    \[list " \
      [Wiki::systemField $system "buildEditUrlPats"] "\] \\\r" \
      "  \"viewUrlPattern\"      " \
      [Wiki::systemField $system "viewUrlPattern"] "\\\r" \
      "  \"editUrlPattern\"      " \
      [Wiki::systemField $system "editUrlPattern"] "\\\r" \
      "  \"postUrlPattern\"      " \
      [Wiki::systemField $system "postUrlPattern"] "\\\r" \
      "  \"wikiSiteUrls\"        \[list " \
      [Wiki::systemField $system "wikiSiteUrls"] "\] \\\r" \
      "  \"postIsEnabled\"       \"" \
      [Wiki::systemField $system "postIsEnabled" "3"] "\" \\\r" \
      "  \"wikiExamples\"        \[list \\\r" \
      "  \"" [lindex [Wiki::systemField $system "wikiExamples"] 0] "\" \\\r" \
      "  \"" [lindex [Wiki::systemField $system "wikiExamples"] 1] "\" \\\r" \
      "  \] \\\r" \
      "  \"homeSite\"            \"" \
      [Wiki::systemField $system "homeSite"] "\" \\\r" \
      "  \"description\"         \{" \
      [Wiki::systemField $system "description"] \
      "\} \\\r" \
      "  \]\r\r"
    set procName "Wiki::${system}::postToServer"
    if {[llength [info procs ::$procName]] || [auto_load ::$procName]} {
        append txt "# " [string repeat "-" 75] "\r\r" \
	  "proc $procName \{" [info args ::$procName] "\} \{\r" \
	  [info body ::$procName] "\r\}\r\r"
    }
    set name "* Exported Wiki Settings *"
    set w [new -n $name -text $txt]
    goto -w $w [minPos -w $w]
    help::markColourAndHyper -w $w
    winReadOnly $w
    return
}

# ===========================================================================
# 
# .