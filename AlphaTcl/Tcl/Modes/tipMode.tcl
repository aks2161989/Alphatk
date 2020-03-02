##############################################################################
# TIP mode.
# 
# For Tcl Improvement Proposals.  As Donal Fellows says:
# 
# If you want it to be a *formal* proposal to the TCT (as opposed to just
# some idea that you're floating about) then format it according to the
# rules described in TIP#3:
# 
#   <http://purl.org/tcl/tip/3.html>
# 
# and email it to the TCT or (preferably) the acting TIP Editor
# (attachments OK) at:
# 
#   <mailto:donal.fellows@cs.man.ac.uk>
# 
#=============================================================================
# Automatically created by mode assistant, with input from Vince.
# 
# This file is distributed under a Tcl-style free license.
#
# Mode: TIP


# Mode declaration.
#  first two items are: name version
#  then 'source' means source this file when we first use the mode
#  then we list the extensions, and any features active by default
alpha::mode TIP 0.4.4 source *.tip {TIPMenu indentUsingSpacesOnly} {
    # Script to execute at Alpha startup
    addMenu TIPMenu TIP TIP
    # Register a specific action for editing remote TIPs.
    set WWW::UrlActionhttp(.*/tip/edit/\[0-9\]+\$) TIP::editRemoteTIP
} uninstall {
    this-file
} maintainer {
} description {
    Provides support for writing Tcl Improvement Proposals
} help {
    Tcl Improvement Proposals are the best of way of getting a particular
    change to Tcl into the official Tcl releases.  Alpha's TIP mode
    includes a TIP menu which makes it easier to write such proposals --
    see the "TIP Example.tip" file for an example.
    
    Once a TIP has been formally proposed to the Tcl Core Team (TCT) it
    is placed on an open repository.  This mode also allows remote
    editing of the TIP on that repository.

    See the TIP web page at <http://purl.org/tcl/tip/>
    for further information.
}

proc tipMode.tcl {} {}

namespace eval TIP {}

# Mode preferences settings, which can be edited by the user (with F12)

# The email address of the current TIP editor
newPref variable tipEditor donal.fellows@cs.man.ac.uk TIP
# The url of the current TIP web site
newPref url tipWebsite http://purl.org/tcl/tip/ TIP
# faster link to the TIP web site
newPref url mirrorWebsite http://www.tcl.tk/cgi-bin/tct/tip/ TIP
# The url of the TIP formatting guidelines
newPref url tipFormat http://purl.org/tcl/tip/3.html TIP
# The url of the tclcore mailing list archives
newPref url tclcoreArchives \
  "http://sourceforge.net/mailarchive/forum.php?forum=alphatcl-developers" TIP

# newPref url tclcoreArchives \
#   "http://www.geocrawler.com/redir-sf.php3?list=tcl-core" TIP
# # Note (03/04/13): Geocrawler is obsolete, SF now archive mailing 
# # lists themselves:

newPref var lineWrap 1 TIP
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 0 TIP

# These are used by the ::parseFuncs procedure when the user clicks on
# the {} button in a file edited using this mode.  If you need more
# sophisticated function marking, you need to add a TIP::parseFuncs
# proc

newPref var funcExpr {^~ [^\r\n]+} TIP
newPref var parseExpr {~ (.*)} TIP

# This proc is called every time we turn the menu on.
# Its main effect is to ensure this code, including the
# menu definition below, has been loaded.
proc TIPMenu {} {}
# Now we define the menu items.
Menu -n $TIPMenu -p TIP::menuProc {
    createDraftTip
    (-)
    mailToEditor
    convertToHtml
    (-)
    tagAsPreformatted
    tipFormatting
    (-)
    gotoTipÉ
    viewTipÉ
    (-)
    tipIndex
    tipWebsite
    (-)
    tclcoreArchive
}

proc TIP::OWH {which} {
    global TIPMenu
    # Dim some menu items when there are no open windows.
    set menuItems [list mailToEditor convertToHtml tagAsPreformatted]
    foreach i $menuItems {
	hook::${which} requireOpenWindowsHook [list $TIPMenu $i] 1
    } 
}

TIP::OWH register ; rename TIP::OWH {}

# This procedure is called whenever we select a menu item
proc TIP::menuProc {menu item} {
    global TIPmodeVars
    switch -- $item {
	createDraftTip {
	    global HOME
	    file::openAsTemplate [help::pathToExample TIP-Example.tip] \
	      "DraftTIP.tip" 0
	}
	mailToEditor {
	    set tip [getText [minPos] [maxPos -w [win::Current]]]
	    composeEmail [url::mailto $TIPmodeVars(tipEditor) \
	      body $tip subject TIP]
	}
	convertToHtml {
	    global HOME
	    set to "[file rootname [win::StripCount [win::Current]]].html"
	    script::run [file join $HOME Tools parse.tcl] -noTk $to
	    if {[file exists $to]} {
		htmlView $to
	    }
	}
	tagAsPreformatted {
	    TIP::tagAsPreFormatted
	}
	tipFormatting {
	    urlView $TIPmodeVars(tipFormat)
	}
	viewTip - gotoTip {
	    if {![catch {prompt "TIP number" ""} num]} {
		if {![is::PositiveInteger $num]} {
		    alertnote "Enter a positive integer."
		    return
		}
	    } else {
	        error "Cancelled."
	    }
	    if {$item == "viewTip"} {
		WWW::renderRemote "$TIPmodeVars(mirrorWebsite)$num.html"
	    } else {
		urlView "$TIPmodeVars(tipWebsite)$num.html"
	    }
	}
	tipIndex {
	    WWW::renderRemote "$TIPmodeVars(mirrorWebsite)short.html"
	}
	tipWebsite {
	    urlView $TIPmodeVars(tipWebsite)
	}
	tclcoreArchive {
	    urlView $TIPmodeVars(tclcoreArchives)
	}
    }
}

# Register comment prefix
set TIP::commentCharacters(General) ~
# Register multiline comments
set TIP::commentCharacters(Paragraph) {{~ } {~ } {~ }}
# List of keywords
set TIPKeyWords {
    Title TIP Version Author State Type Tcl-Version Vote Created Post-History
}

# Colour the keywords, comments etc.
regModeKeywords -C TIP {}
regModeKeywords -a -e ~ -i > -s green TIP $TIPKeyWords
# Discard the list
unset TIPKeyWords

newPref f autoMark 1 TIP

proc TIP::MarkFile {args} {
    win::parseArgs win 
    set pos  [minPos -w $win]
    set markExpr {^~ [^\r\n]+}

    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 1 $markExpr $pos} match]} {
	set start [lindex $match 0]
	set end   [nextLineStart -w $win $start]
	regsub    {^~ } [getText -w $win $start $end] {} text
	setNamedMark -w $win [string trimright $text] $start $start $start
	set pos $end
    }
}

proc TIP::tagAsPreFormatted {} {
    set sel [getSelect]
    if {![string length $sel]} {
	error "No current selection"
    }
    # Turn into spaces
    set sel [text::maxSpaceForm $sel]
    # split and join with leading '|'
    set sel "|[join [split $sel \r\n] \r|]"
    # remove a trailing | if necessary
    set sel [string trimright $sel "|"]
    replaceText [getPos] [selEnd] $sel
}

hook::register savePostHook TIP::justSavedHook TIP
hook::register closeHook TIP::closeHook TIP

proc TIP::editRemoteTIP {url args} {
    set contents [url::contents $url]
    regexp "<title>(\[^\r\n\]*)</title>" $contents -> title
    regexp "<form (\[^>\]*)>" $contents -> form
    
    set title "Edit $title"
    
    set edit ""
    foreach {n area} [html::parseTagtype textarea $contents] {
	append edit "FORM: $n" "\n\n" $area "\n\n" "END FORM: $n" "\n\n"
    }
    
    set name [temp::path tiptmp $title]
    file::writeAll $name $edit 1
    
    # When fully supported, add '-mode TIP' to this.
    set name [edit -c -w -mode TIP $name]
    foreach attr $form {
	foreach {arg val} [split $attr =] {}
	set ::TIP::${url}($arg) [string trim $val \"]
    }
    set ::TIP::page($name) $url

}

proc TIP::closeHook {name} {
    catch {
	set to $::TIP::page($name)
	unset ::TIP::page($name)
	unset ::TIP::$to
    }
}

array set TIP::author {
    Email "" Name ""
}

# This doesn't yet work!
proc TIP::justSavedHook {name} {
    if {![info exists ::TIP::page($name)]} { return }
    # Gather information
    set to $::TIP::page($name)
    upvar \#0 ::TIP::${to} attr
    # I really don't understand how to generate the correct POST
    # url automatically.  Why do I need to munge 'to'
    if {[info exists attr(action)]} {
	regsub {/[^/]*$} $to "" to
	set postTo [url::makeAbsolute $to $attr(action)]
    } else {
	set postTo "[string trimright $to @].html"
    }
    
    global TIP::author
    if {[catch {prefs::dialogs::editArrayVar TIP::author "Enter your details"}]} {
	return
    }
    
    set email $TIP::author(Email)
    set name $TIP::author(Name)
    
    set contents [getText [minPos] [maxPos]]
    foreach section {abstract body log} {
	set tag "FORM: *$section"
	if {![regexp "${tag}(.*)END $tag" $contents -> val]} {
	    alertnote "Couldn't match $tag in $contents"
	}
	set $section [string trim $val]
    }
    # Post the new page back to the TIP archive.  Tcl makes this
    # incredibly simple!  Thanks to the Tcler's Wiki for
    # appropriate code snippets to help.

    package require http
    status::msg "Posting the new version to $postTo ..."
    set query [::http::formatQuery email $email name $name \
      abstract $abstract body $body log $log operation commit]
    
    if {[catch {::http::geturl $postTo -query $query} http]} {
	alertnote "Post to $postTo failed: $http"
	return
    }
    
    status::msg "Posting the new version...done"
    # This will actually return the contents of the new web page
    # i.e. some html source code.
    set html [::http::data $http]
    # cleanup
    ::http::cleanup $http

    if {$html == ""} {
	status::msg "Edited page has been submitted successfully."
    } else {
	if {[regexp {<font color="red"><strong>([^<]+)</strong></font>} $html -> error]} {
	    alertnote $error
	} else {
	    alertnote "That posting may not have been successful: $html"
	}
	#new -n tmp.html -text $html
    }
    # Now do something with the results.  If we were created by
    # the WWW mode, we might want to auto-reload whatever page
    # it was using the information we've got here (saves having
    # to reload it from the internet).
    #WWW::webPageHasChanged "[string trim $to @].html" $html
}
