## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "alphaDevWebSites.tcl"
 #                                          created: 06/27/2003 {02:16:38 PM}
 #                                      last update: 03/06/2006 {08:06:52 PM}
 # Description:
 # 
 # Provides access to various web sites which might be useful for Alpha
 # developers, including some specific AlphaTcl wiki pages, by creating a
 # submenu inserted into the AlphaDev menu.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #
 # Copyright (c) 2003-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # Distributed under a Tcl style license.
 # 
 # ==========================================================================
 ##

proc alphaDevWebSites.tcl {} {}

namespace eval alphadev::www {
    
    variable menuName "AlphaDev Web Sites"
    
    # Web site arrays  "webSites" was from older versions.
    variable alphaSites
    variable webSites
    variable wikiSites
    variable userSites
    # Define the default sites.
    array set alphaSites {
	"AlphaTcl CVS Repository" \
	  {http://www.purl.org/net/alpha/cvs}
	"AlphaTcl PreRelease" \
	  {http://www.purl.org/net/alpha/pre-release}
	"Bugzilla Home Page" \
	  {http://www.purl.org/net/alpha/bugzilla}
	"MacCVS Pro Home Page" \
	  {http://www.purl.org/net/alpha/maccvspro}
	"Mailing List Options" \
	  {http://www.purl.org/net/alpha/mail}
	"Tcl-tk Developer Site" \
	  {http://www.purl.org/net/alpha/tcltkdevelopers}
    }
    array set wikiSites {
	"AlphaTcl Wiki" \
	  {http://www.purl.org/net/alpha/wiki}
	"AlphaTcl CVS Info" \
	  {http://www.purl.org/net/alpha/wikipages/cvs-info}
	"Mailing Lists" \
	  {http://www.purl.org/net/alpha/wikipages/mail-lists}
	"New Packages" \
	  {http://www.purl.org/net/alpha/wikipages/new-packages}
	"Recent Changes" \
	  {http://www.purl.org/net/alpha/wikipages/changes}
	"To Do List" \
	  {http://www.purl.org/net/alpha/wikipages/to-do-lists}
    }
    # Make sure that any previous changes by the user for these 
    # now-persistent urls are forgotten.
    set allDefaults [concat [array names alphaSites] [array names wikiSites]]
    foreach siteName [array names webSites] {
	if {([lsearch $allDefaults $siteName] == -1)} {
	    set userSites($siteName) $webSites($siteName)
	}
	prefs::modified webSites($siteName)
	unset webSites($siteName)
    }
    # Used in wiki searching, see [alphadev::www::searchWiki] below.
    variable wikiSearchText
    if {![info exists wikiSearchText]} {
        set wikiSearchText ""
    }
    # Cleanup.
    unset -nocomplain allDefaults siteName
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::www::listSites" --
 # 
 # Create a list of available web sites based on the given criteria.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::www::listSites {{listType "all"}} {
    
    variable alphaSites
    variable userSites
    variable wikiSites
    
    set webSiteList [list]
    # Now we create the desired list.
    switch -- $listType {
	"all" {
	    # All web sites that we have available.
	    set webSiteList [lsort -dictionary -unique [eval [list lappend] \
	      [alphadev::www::listSites "alpha"] \
	      [alphadev::www::listSites "wiki"] \
	      [alphadev::www::listSites "user"] \
	      ]]
	}
	"alpha" {
	    # Alpha web sites that haven't been removed by the user.
	    foreach siteName [lsort -dictionary [array names alphaSites]] {
	        if {![info exists userSites($siteName)] \
		  || ($userSites($siteName) ne "")} {
	            lappend webSiteList $siteName
	        }
	    }
	}
	"wiki" {
	    # Wiki web pages that haven't been removed by the user.
	    foreach siteName [lsort -dictionary [array names wikiSites]] {
		if {![info exists userSites($siteName)] \
		  || ($userSites($siteName) ne "")} {
		    lappend webSiteList $siteName
		}
	    }
	    # Make sure that "AlphaTcl Wiki" is listed first.
	    if {([set idx [lsearch $webSiteList "AlphaTcl Wiki"]] > -1)} {
	        set webSiteList [lreplace $webSiteList $idx $idx]
		set webSiteList [linsert $webSiteList 0 "AlphaTcl Wiki"]
	    }
	}
	"user" {
	    # Sites that have been added/edited by the user.
	    set webSiteList [lsort -dictionary [array names userSites]]
	}
	"added" {
	    # Sites that have been added by the user.
	    foreach siteName [lsort -dictionary [array names userSites]] {
		if {![info exists alphaSites($siteName)] \
		  && ![info exists wikiSites($siteName)]} {
		    lappend webSiteList $siteName
		}
	    }
	}
	"revised" {
	    # Sites that have been revised by the user.
	    foreach siteName [lsort -dictionary [array names userSites]] {
		if {[info exists alphaSites($siteName)] \
		  || [info exists wikiSites($siteName)]} {
		    lappend webSiteList $siteName
		}
	    }
	}
    }
    return $webSiteList
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× AlphaDev Web Sites Menu ×××× #
# 

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::www::buildMenu" --
 # 
 # Create the menu of items available, called when the AlphaDev menu is
 # first built and whenever the user edits the web sites to be included.
 # 
 # "alphadev::www::postBuildMenu" --
 # 
 # Dim 'editing' options as appropriate.  This is called by AlphaTcl after
 # the menu has been built (using [menu::buildSome]).
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::www::buildMenu {} {
    
    variable menuName
    
    if {[llength [set menuList [alphadev::www::listSites "added"]]]} {
        lappend menuList "(-)"
    }
    set menuList [concat $menuList \
      [alphadev::www::listSites "alpha"] \
      [list "(-)"] \
      [alphadev::www::listSites "wiki"] \
      [list "Search WikiÉ" "(-)" "Add Web SiteÉ" \
      "Edit Web SitesÉ" "Copy Web SiteÉ" "Rename Web SiteÉ" \
      "Remove Web SiteÉ" "Restore DefaultsÉ" "(-)" "$menuName Help"] \
      ]
    # Return the list of items required to build the menu.
    return [list "build" $menuList {alphadev::www::menuProc -m}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::www::postBuildMenu" --
 # 
 # Dim/enable utility menu items as appropriate.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::www::postBuildMenu {} {
    
    variable menuName
    
    set dim1 [expr {([llength [alphadev::www::listSites "all"]] > 0) ? 1 : 0}]
    set dim2 [expr {([llength [alphadev::www::listSites "revised"]] > 0) ? 1 : 0}]
    foreach menuItem [list "Copy" "Rename" "Remove"] {
	append menuItem " Web SiteÉ"
        enableMenuItem -m $menuName $menuItem $dim1
    }
    foreach menuItem [list "Restore DefaultsÉ"] {
	enableMenuItem -m $menuName $menuItem $dim2
    }
    return
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::www::menuProc" --
 # 
 # Execute the menu items, redirecting as necessary.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::www::menuProc {menuName itemName} {
    
    variable alphaSites
    variable wikiSites
    variable userSites
    
    foreach siteArray [list "userSites" "alphaSites" "wikiSites"] {
	if {[info exists ${siteArray}($itemName)]} {
	    urlView [set ${siteArray}($itemName)]
	    return
	}
    }
    switch -- $itemName {
	"Search Wiki" {
	    alphadev::www::searchWiki
	}
	"Add Web Site" {
	    alphadev::www::addWebSite
	}
	"Edit Web Sites" {
	    alphadev::www::editWebSites
	}
	"Copy Web Site" {
	    alphadev::www::copyWebSite
	}
	"Rename Web Site" {
	    alphadev::www::renameWebSite
	}
	"Remove Web Site" {
	    alphadev::www::removeWebSite
	}
	"Restore Defaults" {
	    alphadev::www::restoreDefaults
	}
	"AlphaDev Web Sites Help" {
	    alphadev::www::helpWindow
	}
	default {
	    alertnote "Couldn't find the proper url for '${itemName}'"
	}
    }
    return
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::www::searchWiki" --
 # 
 # Create a dialog asking for search text, and set the flag for searching in
 # the contents of the pages as well as the titles.  All field values are
 # saved for the next call of the dialog, but are not saved between editing
 # sessions.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::www::searchWiki {{searchText ""}} {
    
    variable wikiSearchText
    
    if {($searchText eq "")} {
	set t1 "The AlphaTcl wiki is a searchable index.\
	  You can search for strings in the contents of all of the pages.\r"
	set t2 "Search string:"
	# Create and present the dialog.
	set dialogScript [list dialog::make -title "Search Wiki for ..." \
	  [list " " \
	  [list text $t1] \
	  [list var  $t2 $wikiSearchText] \
	  ]]
	set wikiSearchText [lindex [eval $dialogScript] 0]
	if {([string trim $wikiSearchText] eq "")} {
	    alertnote "The search string cannot be empty!"
	    return [alphadev::www::searchWiki]
	}
	prefs::modified wikiSearchText
    }
    set searchText [quote::Url $wikiSearchText]
    append url "http://www.purl.org/net/alpha/wiki-search/" $searchText
    urlView $url
    return
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::www::helpWindow" --
 # 
 # Open a new window with information about this submenu.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::www::helpWindow {} {
    
    global bugzillaHomePage
    
    set title "AlphaDev Web Sites Help"
    if {[win::Exists $title]} {
	bringToFront $title
	return
    }

    set txt {
AlphaDev Web Sites Help

The "AlphaDev > AlphaDev Web Sites" submenu provides support for access to
various AlphaDev Web Sites.  All sites and their corresponding urls can be
edited by the user.  By default it includes some specific pages in the
AlphaTcl wiki which are listed in the second section of the menu.
    
The service defined in your preferences: Helpers-viewURL determines how
the files will be viewed.
    

	  	Table Of Contents

"# What are the default web sites?"
"# What is the AlphaTcl Wiki?"
    

	  	What are the default web sites?

    
There are a number of web resources out there which Alpha developers might
find useful.  Some are specific to Alpha, others to Tcl, and several pages
in the AlphaTcl Wiki provide development guidelines or are ongoing
discussions about future efforts.

These are some of the default sites listed:
    
	AlphaTcl CVS Repository
 
<http://www.purl.org/net/alpha/cvs>
    
This site contains the collection of all AlphaTcl files, along with their
complete revision history.  See the package: alphaTclCvs for more
information about how to use the CVS and updating your AlphaTcl library.
    
	AlphaTcl PreRelease
 
<http://www.purl.org/net/alpha/pre-release>
    
This site contains archived versions of AlphaTcl that can be installed
between major public releases of the family of Alpha editors.
    
	AlphaTcl Wiki Home Page
 
<http://www.purl.org/net/alpha/wiki/>
    
This site serves as the home page for AlphaTcl.  For more information see
the "# What is the AlphaTcl Wiki?"  section below.  This url and any other
pages found in the wiki site are separated into the second section of the
menu.
    
	Bugzilla Home Page
 
<http://www.purl.org/net/alpha/bugzilla>
    
"Alpha Bugzilla" is the database of all reported bugs associated with
AlphaTcl and its supporting editors.  See the package: reportABug for more
information about how to use this system.
    
	MacCVS Pro Home Page
 
<http://www.purl.org/net/alpha/maccvspro>
    
The "MacCVS Pro" application can be used on the MacOS to update your
AlphaTcl library.  While this site is in need of a major update (at least as
of this writing), it provides the only public documentation that is
available for this application.
    
	Mailing List Options
 
<http://www.purl.org/net/alpha/mail>
    
There are two primary public listserv forums devoted to both the use and the
development of AlphaTcl and its editors.  This web site includes information
about signing up for the listservs (daily digests are also available), or
for searching the mailing list archives.
    
The "Users" forum is for, well, 'users' of Alpha that need help for some
specific editing operation or want to provide feedback for future
development.  In general, the traffic on this list is relatively light.
    
The "Developers" forum is more technical, addressing programming issues in
both AlphaTcl as well as the core applications.  Most developers are also
subscribed and monitor the "Users" list (providing help there when
necessary).  All bug reports from "Alpha Bugzilla" are automatically
forwarded to the developers list.
    
	Tcl Developer Site
 
<http://www.purl.org/net/alpha/tcltkdevelopers>
    
Most of Alpha's functionality lies in its set of AlphaTcl source files,
written in Tcl, creating the set of modes, menus, and other features
associated with the graphic user interface.
    
"Tcl" stands for "Tool Command Language", a cross-platform computer language
created by John Ousterhout which provides a basic set of commands that can
be used by any application.  All versions of the Alpha* text editor rely on
Tcl to perform basic tasks of variable creation and manipulation, OS file
accessing, and script evaluation.  Tcl must be installed on your local drive
in order for Alpha to function properly -- if it isn't installed, you won't
be able to launch Alpha and read this Help file!
    
Some of Alpha's developers are active members of the Tcl development team as
well, and many changes to Tcl are proposed due to limitations discovered in
Alpha.  This site is the home page for Tcl.
    

	  	What is the AlphaTcl Wiki?


The 'AlphaTcl Wiki' is a web site found here:
    
<http://www.purl.org/net/alpha/wiki>
    
This serves as the home page for the developers and users of the suite of
files known collectively as "AlphaTcl".  These files provide most of the
functionality for the various "Installed Packages" such as modes, menus, and
other features which make Alpha a very powerful text editor.
    
Wiki sites are simply a collection of interactive www pages that can be
edited by anyone visiting the web site.  Each page is retained on some
remote web server, and is generally identified as a file number with an
'alias' name which allows them to all be hyperlinked amongst themselves.
    
These pages (as well as any other urls) can also be viewed in Alpha using the
package: wwwMenu -- you can set your preferences: Helpers-viewURL in order to
automatically download and view urls using Alpha.  Wiki pages from any site
can also be edited and saved to the wiki's remote server using the AlphaTcl
package: Wiki -- the 'Edit' hyperlink found at the bottom of wiki pages which
have been rendered by the WWW Menu will set everything up for you, creating a
new window that you can edit and 'Save' to the remote server!


As always, feedback and code contributions are always welcome, see the
"alphaDevWebSites.tcl" file for the current sources.
}
    new -n $title -tabsize 4 -info $txt
    help::markColourAndHyper
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Web Site Utilities ×××× #
# 
# A default set of web sites is created above.  Additional sites can be
# added, and all of these can be edited, renamed, or removed permanently.
# Changes are saved between editing sessions.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::www::addWebSite" --
 # 
 # Add a new site to the menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::www::addWebSite {args} {

    variable menuName
    
    set siteName [lindex $args 0]
    set siteUrl  [lindex $args 1]
    
    # Explanatory text.
    set t {
	You can create a new 'favorite' web site that will be inserted into
	the "MENUNAME" submenu (and saved between editing sessions) by
	entering a name and its associated url in this dialog.  The name
	does not have to correspond to that used by the url itself.  All
	favorites can be later edited, renamed, or removed permanently from
	the menu.
    }
    regsub -all {\s+} $t " " t
    regsub -all {MENUNAME} $t $menuName t
    # Create, present the dialog.
    set dialogScript [list dialog::make -title "New AlphaDev Web Site" \
      [list "" \
      [list text $t] \
      [list var "Site Name:" $siteName] \
      [list url "Site Url: " $siteUrl] \
      ]]
    set result [eval $dialogScript]
    set siteName [lindex $result 0]
    set siteUrl  [lindex $result 1]
    # Make sure that our information was valid.
    if {([string trim $siteName] eq "")} {
	alertnote [set msg "The 'Site Name' cannot be an empty string!"]
    } elseif {([string trim $siteUrl] eq "")} {
	alertnote [set msg "The 'Site Url' cannot be an empty string!"]
    } elseif {[info exists alphaSites($siteName)] \
      || [info exists wikiSites($siteName)]} {
        alertnote "Sorry, the name \"$siteName\" is reserved."
    } elseif {![info exists userSites($siteName)] \
      || [dialog::yesno "The name \"$siteName\" is already used.\
      Do you want to replace it?"]} {
	set saveSite 1
    }
    if {![info exists saveSite]} {
	return [alphadev::www::addWebSite $siteName $siteUrl]
    }
    set userSites($siteName) $siteUrl
    prefs::modified userSites($siteName)
    menu::buildSome $menuName
    status::msg "Changes have been saved."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::www::editWebSites" --
 # 
 # Edit the url of a pre-existing web site.  If the chosen item is one of 
 # our defaults, we add a new "userSites(<siteName>)" array entry.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::www::editWebSites {} {
    
    variable alphaSites
    variable wikiSites
    variable userSites
    
    if {![llength [set allSites [alphadev::www::listSites "all"]]]} {
        status::msg "There are no web sites to edit."
	return
    }
    set sites $allSites
    set p1 "Select a web site to edit:"
    while {1} {
	if {[set siteName [listpick -p $p1 $sites]] eq "(Finish)"} {
	    break
	}
	set p2 "Url for '${siteName}'"
	foreach siteArray [list "userSites" "alphaSites" "wikiSites"] {
	    if {[info exists ${siteArray}($siteName)]} {
		set siteUrl [set ${siteArray}($siteName)]
		break
	    }
	}
	while {1} {
	    if {([set siteUrl [dialog::getUrl $p2 $siteUrl]] eq "")} {
		alertnote "The url cannot be an empty string!"
	    } else {
	        break
	    }
	}
	set userSites($siteName) $siteUrl
	prefs::modified userSites($siteName)
	status::msg "'${siteName}' number has been changed to '${siteUrl}'."
	alphadev::www::postBuildMenu
	set sites [concat "(Finish)" $allSites]
	set p1 "Select another, or finish:"
    }
    status::msg "Changes have been saved."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::www::copyWebSite" --
 # 
 # Make a copy of an existing web site.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::www::copyWebSite {} {
    
    variable alphaSites
    variable menuName
    variable userSites
    variable wikiSites

    if {![llength [set sites [alphadev::www::listSites "all"]]]} {
	status::msg "There are no web sites to copy."
	return
    }
    set p "Select a web page to copy:"
    while {1} {
	if {([set oldName [listpick -p $p $sites]] eq "(Finish)")} {
	    break
	}
	if {([set newName [prompt "Copy to:" $oldName]] eq $oldName)} {
	    set msg "No changes"
	    break
	} elseif {($newName eq "")} {
	    alertnote [set msg "The 'Page Name' cannot be an empty string!"]
	    continue
	} elseif {([lsearch $sites $newName] > -1)} {
	    alertnote "The name \"$newName\" is already used by another item."
	    continue
	} elseif {[info exists userSites($oldName)]} {
	    set userSites($newName) $userSites($oldName)
	    prefs::modified userSites($newName)
	} elseif {[info exists alphaSites($oldName)]} {
	    set userSites($newName) $alphaSites($oldName)
	    prefs::modified userSites($newName)
	} elseif {[info exists wikiSites($oldName)]} {
	    set userSites($newName) $wikiSites($oldName)
	    prefs::modified userSites($newName)
	} else {
	    # ???
	    alertnote "Sorry, couldn't find the original item!"
	    continue
	}
	menu::buildSome $menuName
	set msg "'${oldName}' has been copied to '${newName}'."
	status::msg $msg
	set sites [concat "(Finish)" [alphadev::www::listSites "all"]]
	set p "Select another, or finish:"
    }
    status::msg "Changes have been saved."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::www::renameWebSite" --
 # 
 # Rename a pre-existing web site menu item.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::www::renameWebSite {} {
    
    variable alphaSites
    variable menuName
    variable userSites
    variable wikiSites

    if {![llength [set sites [alphadev::www::listSites "all"]]]} {
	status::msg "There are no web sites to edit."
	return
    }
    set p "Select a web page to rename:"
    while {1} {
	if {([set oldName [listpick -p $p $sites]] eq "(Finish)")} {
	    break
	}
	if {([set newName [prompt "Rename to:" $oldName]] eq $oldName)} {
	    set msg "No changes"
	    break
	} elseif {($newName eq "")} {
	    alertnote [set msg "The 'Page Name' cannot be an empty string!"]
	    continue
	} elseif {([lsearch $sites $newName] > -1)} {
	    alertnote "The name \"$newName\" is already used by another item."
	    continue
	} elseif {[info exists userSites($oldName)]} {
	    set userSites($newName) $userSites($oldName)
	    prefs::modified userSites($newName) userSites($oldName)
	    unset userSites($oldName)
	} elseif {[info exists alphaSites($oldName)]} {
	    set userSites($newName) $alphaSites($oldName)
	    set userSites($oldName) ""
	    prefs::modified userSites($newName) userSites($oldName)
	} elseif {[info exists wikiSites($oldName)]} {
	    set userSites($newName) $wikiSites($oldName)
	    set userSites($oldName) ""
	    prefs::modified userSites($newName) userSites($oldName)
	} else {
	    # ???
	    alertnote "Sorry, couldn't find the original item!"
	    continue
	}
	menu::buildSome $menuName
	set msg "'${oldName}' has been renamed to '${newName}'."
	status::msg $msg
	set sites [concat "(Finish)" [alphadev::www::listSites "all"]]
	set p "Select another, or finish:"
    }
    status::msg "Changes have been saved."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::www::removeWebSite" --
 # 
 # Remove web sites from the menu.  If the site is one of our defaults, then 
 # we set the "userSites(<siteName>)" array entry to the null string, which 
 # means that it won't appear in the menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::www::removeWebSite {} {
    
    variable alphaSites
    variable menuName
    variable userSites
    variable wikiSites

    if {![llength [set sites [alphadev::www::listSites "all"]]]} {
	status::msg "There are no web sites to remove."
	return
    }
    set p "Select some web sites to remove:"
    foreach siteName [listpick -p $p -l $sites] {
	prefs::modified userSites($siteName)
	if {[info exists userSites($siteName)]} {
	    unset -nocomplain userSites($siteName)
	} else {
	    set userSites($siteName) ""
	}
    }
    menu::buildSome $menuName
    status::msg "The selected sites have been removed from the menu."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::www::restoreDefaults" --
 # 
 # Restore the default url for sites that have been revised by the user.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::www::restoreDefaults {} {
    
    variable userSites
    
    if {![llength [set sites [alphadev::www::listSites "revised"]]]} {
	status::msg "There are no web sites to reset."
	return
    }
    set p "Restore the default urls of which site(s) ?"
    foreach siteName [listpick -p $p -l $sites] {
	prefs::modified userSites($siteName)
	unset -nocomplain userSites($siteName)
    }
    alphadev::www::postBuildMenu
    status::msg "The urls for the selected sites have been restored."
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
# 06/28/03 cbu 0.1    First version, named "alphaTclWiki"
# 07/01/03 cbu 0.2    Corrected calls to [menu::buildSome] to rebuild the
#                       correct name of the menu.
#                     Modified 'preinit' script to reflect changes in how
#                       the AlphaDev menu recognizes extra submenus.
# 07/03/03 cbu 0.3    Renamed "alphaDevWebSites", incorporating web sites
#                       previously hard-wired in the AlphaDev menu.
#                     New variable "menuName" that is used throughout.
#                     Some default pages can never be edited or removed.
# 07/11/03 cbu 0.4    No longer a stand-alone package, incorporated into
#                       the new "AlphaDev Menu" folder.
# 01/26/06 cbu 0.5    Now using persistent urls (purls) for all defaults.
#                     Defaults can no longer be edited.
#                     User sites saved in "userSites" array, listed at top.
# 

# ===========================================================================
# 
# .