## -*-Tcl-*-
 # ==========================================================================
 # WWW Menu - an extension package for Alpha
 #
 # FILE: "wwwLinks.tcl"
 #                                   created: 04/30/1997 {11:04:46 am} 
 #                               last update: 03/21/2006 {01:53:30 PM} 
 # Description:
 # 
 # Procedures to navigate, process links and the history cache.
 # 
 # See the "wwwVersionHistory.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the wwwMode.tcl file has been loaded.
wwwMode.tcl

proc wwwLinks.tcl {} {}

namespace eval WWW  {}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Processing Links ×××× #
# 
# Link info in the 'WWW::Links/Reverse' arrays include:
# 
# starting position
# ending position
# url
# target
# hyperlink command
# 

# The array WWW::Links now includes 'targets' for hyperlinks as a fifth
# list element.  This should be dealt with here somehow.

proc WWW::link {{to ""} args} {

    global wwwMenuVars WWWmodeVars
    
    variable FileSource
    variable UrlAction
    
    # Preliminaries.
    WWW::setWindowVars
    WWW::openingFromLink 1
    set target ""
    set title  [win::Current]
    set m [WWW::getWindowMode $title]

    # Make sure that the current window is added to the history
    # if necessary.
    if {($m ne "WWW") || ($title eq $wwwMenuVars(historyTitle))} {
	WWW::openingFromLink 0
    } elseif {[info exists FileSource($title)]} {
	set f $FileSource($title)
	WWW::addHistoryItem $f
	WWW::setWindowParameters $title [WWW::isNotPartOfTarget $title]
    }
    if {![string length $to]} {
	if {[catch {WWW::getCurrentLink} linkList]} {
	    status::msg "$linkList"
	    return -code return
	}
	set to     [lindex $linkList 2]
	set target [lindex $linkList 3]
    }
    set to [string trim [string trim $to {\"}]]
    # We have to do this to in order to properly colorize visited links
    # when they are accessed via the mouse.
    if {[llength [winNames]]} {
	set pos0 [set pos1 ""]
	if {![isSelection]} {
	    if {![catch {WWW::getLinks} currentLinks]} {
		foreach linkList $currentLinks {
		    if {([lindex $linkList 2] eq $to)} {
			set pos0 [lindex $linkList 0]
			set pos1 [lindex $linkList 1]
			set target [lindex $linkList 3]
			break
		    }
		}
	    } elseif {[regexp {^[<:]:/[/]+} [getSelect]]} {
		return [WWW::renderRemote [getSelect]]
	    }
	}
	WWW::visitedLink $to $pos0 $pos1
    }
    # Do we have modifiers?  (Ignored in Alphatk.)  This should only be an
    # issue when using modifiers and clicking on link with mouse.
    if {[key::shiftPressed]} {
	if {[key::controlPressed]} {
	    # In new window.
	    WWW::forcingNewWindow 1
	} else {
	    # Send it to the browser.
	    url::execute $to
	    return
	}
    }
    if {[regsub {^\?+:[/]+} $to {} huh]} {
        status::msg "Unknown server for '$huh'"
	return -code return
    }
    foreach pat [array names UrlAction] {
	if {![regexp {^\^} $pat]} {
	    continue
	}
	if {[regexp -nocase $pat $to]} {
	    return [$UrlAction($pat) $to $target]
	}
    }
    # if we didn't return above
    WWW::externalLink $to
    return
}

proc WWW::errorLink {args} {
    status::msg [lindex $args 0]
    return -code return
}

proc WWW::fileLink {to {target ""}} {
    
    variable Anchors

    if {[set anchorSpot [string last "\#" $to]] != -1} {
	set anchor [string range $to [expr {$anchorSpot + 1}] end]
	set to     [string range $to 0 [expr {$anchorSpot - 1}]]
    }
    WWW::massagePath to
    WWW::openingFromLink 1
    set title [WWW::renderLocal $to "" $target]
    # Do we have an anchor?
    if {[info exists anchor] && [info exists Anchors($title)]} {
	set anchor [string trim [quote::Unurl $anchor]]
	foreach item $Anchors($title) {
	    if {($anchor eq [string trim [lindex $item 0]])} {
		goto [lindex $item 1]
		insertToTop
		return
	    }
	}
    }
    return
}

proc WWW::ftpLink {to {target ""}} {

    global WWWmodeVars
    
    if {!$WWWmodeVars(ftpLinksInternal)} {
	url::execute $to ; return
    }

    regsub {^ftp:[/]+} $to {} to
    url::parseFtp $to i
    if {![catch {ftp::browse $i(host) $i(path) $i(user) $i(pass) $i(file)}]} {
	set alert    "This file will be opened in Alpha, but in a temp cache -- "
	append alert "You can use 'WWW --> Save Source AsÉ' to save it on a local disk."
	alertnote $alert
    }
    return
    
    # This doesn't work because the file might not have landed yet.
    
    if {![catch {ftp::browse $i(host) $i(path) $i(user) $i(pass) $i(file)}]} {
	set question    "This file was opened in Alpha.\r"
	append question "Would you prefer to save it on a local disk?"
	if {[askyesno $question]} {
	    menu::fileProc {File} {saveAs}
	    killWindow
	}
    }
    return
}

proc WWW::httpLink {to {target ""}} {

    global WWWmodeVars
    
    variable Anchors
    variable UrlActionhttp
    
    if {![WWW::httpAllowed] || !$WWWmodeVars(httpLinksInternal)} {
	url::execute $to ; return
    } elseif {[set anchorSpot [string last "\#" $to]] != -1} {
	set anchor [string range $to [expr {$anchorSpot + 1}] end]
	set to     [string range $to 0 [expr {$anchorSpot - 1}]]
    }
    # Do we have a special http action to take?
    foreach pat [array names UrlActionhttp] {
	if {[regexp -nocase $pat $to]} {
	    WWW::openingFromLink 1
	    return [eval $UrlActionhttp($pat) [list $to]]
	}
    }
    # Do we have an anchor?
    WWW::openingFromLink 1
    set title [WWW::renderRemote $to "" $target]
    if {[info exists anchor] && [info exists Anchors($title)]} {
	set anchor [quote::Unurl $anchor]
	foreach item $WWW::Anchors($title) {
	    if {[regexp -nocase "^\[\t \]*$anchor" [lindex $item 0]]} {
		goto [lindex $item 1]
		insertToTop
		return
	    }
	}
    }
    return
}

proc WWW::javaLink {to {target ""}} {

    global WWWmodeVars
    
    WWW::massagePath to
    if {$WWWmodeVars(runJavaAppletsDirectly)} {
	# can run applet directly
	alertnote "Sorry, I don't yet know how to run .class files directly."
	javaRun "[file root ${to}].class"
    } else {
	# use html file
	global wwwMenuVars
	xserv::invoke viewJavaApplet \
	  -file [lindex [lindex $wwwMenuVars(goToPages) $wwwMenuVars(goToPagePos)] 0]
    }
    return
}

proc WWW::mailLink {to args} {
    composeEmail $to
    return
}

proc WWW::externalLink {to {target ""}} {
    
    global WWWmodeVars
    
    if {$WWWmodeVars(wwwSendRemoteLinks)} {
	url::execute $to
    } else {
	set    alert "External link to \r'$to',\r"
	append alert "toggle the WWW mode flags to use a helper application, "
	append alert "or to pass on any 'unknown' remote links "
	append alert "to Internet Config."
	alertnote $alert
	refresh
    }
    return
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Managing Links ×××× #
# 

proc WWW::visitedLink {to {pos0 ""} {pos1 ""}} {
    
    global WWWmodeVars wwwMenuVars
    
    variable DefaultLinkColor
    
    if {![llength [winNames]] || [info exists DefaultLinkColor($to)]} {
	# Links that have default colors never change.
	return
    }
    lunion wwwMenuVars(visited) [string trim $to {\"}]
    if {![string length $pos0] || ![string length $pos1]} {
	if {[isSelection]} {
	    set pos0 [getPos]
	    set pos1 [selEnd]
	} else {
	    return
	}
    }
    if {![catch {WWW::getCurrentLink "" 1 $pos0 $pos1} result]} {
	set pos0 [lindex $result 0]
	set pos1 [lindex $result 1]
	set cmd  [lindex $result 4]
	text::color $pos0 $pos1 $WWWmodeVars(visitedLinkColor)
	text::hyper $pos0 $pos1 $cmd
	refresh
    }
    return
}

proc WWW::nextLink {direction {pos ""} {title ""}} {
    
    global WWWmodeVars wwwMenu
    
    if {![string length $title]} {
	set title [win::Current]
    }
    if {![string length $pos]} {
	if {$direction} {
	    set pos [pos::math [selEnd] - 1]
	} else {
	    set pos [getPos]
	}
	# Make sure that the cursor is somewhere in the window.
	set top   [win::getInfo $title currline]
	set lines [win::getInfo $title linesdisp]
	# This is the bottom of the window.
	set pos0  [pos::nextLineStart [pos::fromRowCol [expr {$top + $lines}] 0]]
	# This is the top of the window.
	set pos1  [pos::lineStart [pos::fromRowCol $top 0]]
	if {[pos::compare $pos > $pos0] || [pos::compare $pos < $pos1]} {
	    set pos [set pos${direction}]
	}
    }

    # Now find the closest link.
    if {![catch {WWW::findLink $direction $pos $title} result]} {
	set pos0 [lindex $result 0]
	set pos1 [lindex $result 1]
	set link [lindex $result 2]
	set cmd  [lindex $result 4]
	selectText $pos0 $pos1
	if {$WWWmodeVars(centerRefreshOnNav)} {
	    centerRedraw
	}
	WWW::postBuildMenuLinks
	status::msg $cmd
    } else {
	WWW::postBuildMenuLinks
	status::msg "Couldn't find any links in this window."
	return -code return
    }
    # Make sure that the selection is visible
    if {$direction} {
	while {1} {
	    # This is the bottom of the window.
	    set top   [win::getInfo $title currline]
	    set lines [win::getInfo $title linesdisp]
	    set pos0  [pos::nextLineStart [pos::fromRowCol [expr {$top + $lines}] 0]]
	    if {[pos::compare [selEnd] > $pos0]} {
		scrollDownLine
	    } else {
		break
	    }
	}
    } else {
        while {1} {
	    # This is the top of the window.
	    set top   [win::getInfo $title currline]
	    set pos1  [pos::lineStart [pos::fromRowCol $top 0]]
	    if {[pos::compare [getPos] < $pos1]} {
		scrollUpLine
	    } else {
		break
	    }
	}
    }
    return
}

proc WWW::findLink {direction pos {title ""}} {
    
    foreach linkList [WWW::getLinks $title $direction] {
	set pos0 [lindex $linkList 0]
	if {$direction && [pos::compare $pos >= $pos0]} {
	    # Keep looking for the next link below this one.
	    continue
	} elseif {!$direction && [pos::compare $pos <= $pos0]} {
	    # Keep looking for the next link above this one.
	    continue
	} else {
	    set result $linkList
	    break
	}
    }
    if {[info exists result]} {
	return $result
    } else {
	# We reached the end/beginning of the window.
	beep
	if {$direction} {
	    return [WWW::findLink $direction [minPos] $title]
	} else {
	    return [WWW::findLink $direction [maxPos] $title]
	}
    }
}

proc WWW::getLinks {{title ""} {direction 1}} {

    variable Links
    variable LinksReverse
    
    if {($title eq "")} {
        set title [win::Current]
    }
    set m [WWW::getWindowMode $title]
    if {$m ne "WWW"} {
	error "links are only found in WWW windows."
    }
    # Don't want 'tail' since these are not file windows and may
    # contain strange characters (:/ etc) in the name
    if {![string length $title]} {
	set title [win::Current]
    }
    if {![info exists Links($title)] || ![llength $Links($title)]} {
	status::msg "No links found in '$title'"
	return -code return
    } elseif {![info exists LinksReverse($title)]} {
	# Create the reverse lookup if it doesn't exist.
	set LinksReverse($title) [lreverse $Links($title)]
    }
    if {$direction} {
	return $Links($title)
    } else {
	return $LinksReverse($title)
    }
}

proc WWW::getCurrentLink {{title ""} {quietly 1} {pos0 ""} {pos1 ""}} {

    variable Links

    if {![string length $title]} {
	set title [win::Current]
    }
    if {![string length $pos0]} {
	set pos0 [getPos]
    }
    if {![string length $pos1]} {
	set pos1 [selEnd]
    }
    set links [WWW::getLinks $title]
    foreach link $Links($title) {
	set pos2 [lindex $link 0]
	set pos3 [lindex $link 1]
	if {[pos::compare $pos0 >= $pos2] && [pos::compare $pos1 <= $pos3]} {
	    set result $link
	    break
	} else {
	    continue
	}
    }
    if {[info exists result]} {
	if {!$quietly} {
	    status::msg "Links to [lindex $result 2]"
	}
	return $result
    } else {
	if {!$quietly} {
	    status::msg "The current selection is not a link."
	}
	error "The current selection is not a link."
    }
}

proc WWW::modifyLink {} {
    
    global wwwMenuVars
    
    variable Links
    variable LinksReverse
    
    set m [WWW::getWindowMode $title]
    # Make sure that we have enough info to do this.
    if {($m ne "WWW")} {
	error "'WWW::modifyLink' is only useful in WWW browser mode."
    }
    set title [win::Current]
    if {[catch {set WWW::FileSource($title)} fileSource]} {
        alertnote "Sorry, can't identify the source for '$title'."
	error "Cancelled"
    } elseif {![file exists $fileSource]} {
        alertnote "Sorry, can't find '$fileSource'."
	error "Cancelled"
    }
    # Find the current link to modify.
    set linkList [WWW::getCurrentLink]
    set oldLink  [lindex $linkList 2]
    status::msg "Old link: [dialog::specialView::url $oldLink]"
    set to       [dialog::getUrl "Enter new link location" $oldLink]
    if {($to eq "") || ($to eq $oldLink)} {
	status::msg "Nothing was changed."
	return
    }
    # Find out if the source is already open.
    set w [win::Current]
    if {![catch {getWinInfo -w $fileSource i}]} {
	if {$i(dirty)} {
	    if {![dialog::yesno "Save original file?"]} {
		error "cancel"
	    }
	    status::msg "Saving original file."
	    bringToFront $fileSource
	    save
	    bringToFront $w
	}
    }
    # Update the source file.
    set reglink [quote::Regfind $oldLink]
    set regto   [quote::Regsub $to]
    set cid [alphaOpen $fileSource "r"]
    if {[regsub -all -- $reglink [read $cid] $regto out]} {
	set ocid [alphaOpen $fileSource "w+"]
	puts -nonewline $ocid $out
	close $ocid
	status::msg "Updated original."
    }
    close $cid
    if {[win::Exists $fileSource]} {
	bringToFront $fileSource
	status::msg "Updating window to agree with disk version."
	revert
	bringToFront $w
    }
    setWinInfo read-only 0
    WWW::makeLink [win::Current] [getPos] [selEnd] $to
    setWinInfo read-only 1
    # Now update the link lists.
    set i1 [lsearch $Links($w) $linkList]
    set i2 [lsearch $LinksReverse($w) $linkList]
    set linkList [lreplace $linkList 2 2 "WWW::link \"$to\""]
    set linkList [lreplace $linkList 3 3 $to]
    set Links($w)        [lreplace $Links($w)        $i1 $i1 $linkList]
    set LinksReverse($w) [lreplace $LinksReverse($w) $i2 $i2 $linkList]
    status::msg "WWW::link \"$to\""
    return
}

proc WWW::displayLinks {} {
    
    set title [win::Current]
    set links [WWW::getLinks]

    # Create the introduction.
    set    intro "\rThis window contains all of the hyperlinks found in the rendered\r"
    append intro "°$title° window.\r\r"
    append intro "Click here: <<WWW::hyperlinkLinks>> to hyperlink this window.\r"
    append intro "\r__________________________________________________________________________\r\r"
    set newTitle "* [win::MakeTitle "Links in '$title"]' *"
    if {[win::Exists $newTitle]} {
        bringToFront $newTitle
	killWindow
    }
    # Add the links in the current window.
    set count   0
    set results ""
    foreach linkList $links {
	set pos0 [lindex $linkList 0]
	set pos1 [lindex $linkList 1]
	set link [lindex $linkList 2]
	if {[regexp "WWW::formLink" $link]} {
	    continue
	}
	regsub -all "\[\r\n\t\]+" [getText $pos0 $pos1] { } name
	append results "\t  \t°$name° \r    <${link}>\r\r"
	incr count
    }
    # Create the new window, color and hyperize, remove quotes, and mark it.
    new -n $newTitle -m "Text" -text ${intro}${results} -tabsize 1
    goto [minPos]
    win::searchAndHyperise {<<([^>\r\n]+)>>} {\1} 1 4 +2 -2
    win::searchAndHyperise {°([^\r\n°]+)°}   {}   1 1 +1 -1
    refresh
    set pos [minPos]
    while {![catch {search -s -f 1 -r 0 {°} $pos} match]} {
	set pos [lineStart [lindex $match 1]]
	replaceText [lindex $match 0] [lindex $match 1] ""
    }
    markFile ; sortMarksFile
    goto [minPos]
    winReadOnly
    status::msg "'$title' contains $count hyperlinks."
    return
}

proc WWW::hyperlinkLinks {} {

    win::searchAndHyperise \
      {<([^:]+:/[/]+[^ >]*)>} \
      {WWW::link "\1"} 1 3
    win::searchAndHyperise \
      {<(mailto:[-_a-zA-Z0-9.]+@[-_a-zA-Z0-9.]+)>} \
      {WWW::link "\1"} 1 3
    refresh
    return
}

# ===========================================================================
# 
# .
