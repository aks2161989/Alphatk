## -*-Tcl-*-
 # ==========================================================================
 # WWW Menu - an extension package for Alpha
 #
 # FILE: "wwwHistory.tcl"
 #                                   created: 04/30/1997 {11:04:46 am} 
 #                               last update: 02/01/2005 {03:57:59 PM} 
 # Description:
 # 
 # Procedures to navigate, process links and the history cache.
 # 
 # See the "wwwVersionHistory.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the wwwMode.tcl file has been loaded.
wwwMode.tcl

proc wwwHistory.tcl {} {}

namespace eval WWW  {}

proc WWW::initializeHistory {{reset 0}} {
    
    global wwwMenuVars WWWmodeVars
    
    if {!$reset && [info exists wwwMenuVars(historyInitialized)]} {
	# "$reset" is mainly a debugging tool.
	return "The WWW History has already been initialized."
    }
    
    set historyItems $wwwMenuVars(history)
    if {([llength [lindex $historyItems 0]] == "1")} {
        # This was the older version of the history cache, in which the first
        # item only included [mtime [now] short], and each subsequent item
        # was a list of two items, 'title' and 'baseUrl'.  Now we want to
        # also include a timestamp for each item so that we know how long ago
        # we saw it (and can remove the really old ones if desired.)
	set newNow  [now]
	set newDate [lindex [mtime $newNow short] 0]
	lappend newHistory [list "History start" $newDate $newNow]
	foreach item [lrange $historyItems 1 end] {
	    set title [lindex $item 0]
	    set base  [lindex $item 1]
	    lappend newHistory [list $title $base $newNow]
	}
	set wwwMenuVars(history) $newHistory
    }
    WWW::truncateHistory
    # Create two lists of 'remembered' urls.
    set reversedHistory [lreverse [lrange $wwwMenuVars(history) 1 end]]
    foreach item $reversedHistory {
	set url [lindex $item 1]
	# The first time that this file is called we use all of the urls in
	# the standard history cache to create this list.  Thereafter, any
	# time that a url is added to the history it is added at the front of
	# the list.
	if {![lcontains wwwMenuVars(uniqueHistory) $url]} {
	    lappend wwwMenuVars(uniqueHistory) $url
	}
	# Use the history cache for the initial list of visited links.
	if {![lcontains wwwMenuVars(visited) $url]} {
	    lappend wwwMenuVars(visited) $url
	}
    }
    set wwwMenuVars(historyInitialized) 1
    return "The WWW History has now been initialized."
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Managing History Cache ×××× #
# 

proc WWW::truncateHistory {args} {
    
    global wwwMenuVars WWWmodeVars
    
    # Only remember those items more recent than the "historyDays" pref.
    if {[is::PositiveInteger $WWWmodeVars(historyDays)]} {
	set firstItem [lindex $wwwMenuVars(history) 0]
	set nowTime   [now].0
	set oldStart  [lindex $firstItem 2]
	set newStart  [expr {$nowTime - ($WWWmodeVars(historyDays) * 86400)}]
	if {$newStart > $oldStart} {
	    # This might not work in Alpha ...
	    if {![catch {expr {int($newStart)}} newStart1]} {
		# ...  but it is required for Alphatk.  (Probably need to
		# look at this more, determine if [now].0 is needed, and when
		# and why ...)
	       set newStart $newStart1
	    }
	    set newDate [lindex [mtime $newStart short] 0]
	    set firstItem [list "History start" $newDate $newStart]
	}
	lappend newHistory $firstItem
	foreach item [lrange $wwwMenuVars(history) 1 end] {
	    if {[lindex $item 2] > $newStart} {
		lappend newHistory $item
	    }
	}
	set wwwMenuVars(history) $newHistory
    }
    # Uniquify.
    if {[llength $wwwMenuVars(history)] > 1} {
	set firstItem  [lindex $wwwMenuVars(history) 0]
	set newHistory [list]
	set reversedHistory [lreverse [lrange $wwwMenuVars(history) 1 end]]
	foreach item [lreverse [lrange $wwwMenuVars(history) 1 end]] {
	    set url [lindex $item 1]
	    if {![lcontains urls $url]} {
		lappend newHistory $item
	    }
	    lappend urls $url
	}
	set wwwMenuVars(history) [concat [list $firstItem] [lreverse $newHistory]]
    }
    # Truncate.
    if {[is::PositiveInteger [set limit $WWWmodeVars(historyLimit)]]} {
	set wwwMenuVars(history) [lrange $wwwMenuVars(history) 0 $limit]
    }
    set hLength [expr {[llength $wwwMenuVars(history)] - 1}]
    return "The history cache has been truncated, $hLength items."
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::addHistoryItem" --
 #  
 # Add an item to the history cache.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::addHistoryItem {f {title ""}} {
    
    global wwwMenuVars
    
    variable TodaysPages
    variable TodaysUrls
    variable UrlSource
    
    WWW::initializeHistory
    
    if {![string length $title]} {
	set title [win::Current]
    }
    if {($f eq $wwwMenuVars(historyTitle)) \
      || ($title eq $wwwMenuVars(historyTitle))} {
	return
    }
    # First add it to the 'Go To Page' menu if it is not a redirecting
    # frameset window.  (The idea here is that since you might be going
    # back to that original frameset window several times, you still want
    # to keep track of where you've been and not remove the history.
    # Others may disagree -- wait to hear any user feedback.)
    if {![WWW::linksToTarget $title 0]} {
	# Each 'page' is a list of two items, with some file name, and then
	# the actual name of the page.  Since we're pretty sure that all page
	# names rendered in this package are unique, we try to figure out if
	# this one is already in the list.
	set pages $wwwMenuVars(goToPages)
	set pageP $wwwMenuVars(goToPagePos)
	if {[set i [lsearch -glob $pages [list * [win::CurrentTail]]]] != -1} {
	    set pageP $i
	} else {	
	    set  pages [lrange $pages 0 $pageP]
	    incr pageP
	    lappend pages [list $f [win::CurrentTail]]
	}

# 	foreach page $pages {
# 	    set page [lindex $page 1]
# 	    if {$page == [win::Current]} {
# 		set foundIt $pageI
# 		break
# 	    }
# 	    incr pageI
# 	}
# 	if {[info exists foundIt]} {
# 	    set pageP $foundIt
# 	} else {		
# 	    set  pages [lrange $pages 0 $pageP]
# 	    incr pageP
# 	    lappend pages [list $f $title]
# 	}

	set wwwMenuVars(goToPages)   $pages
	set wwwMenuVars(goToPagePos) $pageP
    }
    # Now add it to the History cache.
    if {[info exists UrlSource($title)]} {
	set url $UrlSource($title)
	lappend wwwMenuVars(history) [list [string trim $title] $url [now]]
	# We maintain a separate 'UniqueHistory' list because some operations
	# need to have it available quickly without having to do a large
	# "while {![lcontains someList [lindex ...]]} ..."  routine combined
	# with lunique, lreverse, etc.
	if {([llength $wwwMenuVars(uniqueHistory)] > 1) && \
	    ([set idx [lsearch $wwwMenuVars(uniqueHistory) $url]] != "-1")} {
	    # We're going to move this item to the front of the list.
	    set wwwMenuVars(uniqueHistory) \
	      [lreplace $wwwMenuVars(uniqueHistory) $idx $idx]
	}
	set firstUnique [lindex $wwwMenuVars(uniqueHistory) 0]
	set wwwMenuVars(uniqueHistory) \
	  [lreplace $wwwMenuVars(uniqueHistory) 0 0 $url $firstUnique]
	set TodaysUrls($url) $title
    }
    menu::buildSome goToPage
    # Now add it to the list of pages seen during this editing session.
    set TodaysPages($title) $f
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::deleteHistoryItem" --
 #  
 # Delete an item from the history cache.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::deleteHistoryItem {{deleteItems ""}} {
    
    global wwwMenuVars

    if {![llength $deleteItems]} {
	set itemsList   [lunique [lrange $wwwMenuVars(history) 1 end]]
	set itemsList   [lsort -dictionary [lreverse $itemsList]]
	set deleteItems [listpick -l -p "Remove which history items?" $itemsList]
    } else {
        set recreate 0
    }
    foreach item $deleteItems {
	set wwwMenuVars(history) [lremove $wwwMenuVars(history) [list $item]]
    }
    if {![info exists recreate] && [win::Exists $wwwMenuVars(historyTitle)]} {
	if {[askyesno "Recreate History Window?"]} {
	    set recreate 1
	} else {
	    set recreate 0
	}
    }
    if {$recreate} {
	if {[win::Exists $wwwMenuVars(historyTitle)]} {
	    bringToFront $wwwMenuVars(historyTitle)
	    killWindow
	}
	WWW::historyWindow
    }
    status::msg "Selected items have been removed."
    return
}

proc WWW::addHistoryCheckboxes {} {
    
    set title [win::Current]
    setWinInfo -w $title read-only 0
    set pos [minPos]
    set pat {^    [a-zA-Z]+:}
    set cmd "WWW::deleteThisHistoryItem"
    while {![catch {search -s -f 1 -r 1 -- $pat $pos} match]} {
	set pos0 [lindex $match 0]
	set pos1 [pos::math $pos0 + 3]
	set pos  [pos::nextLineStart $pos0]
	replaceText $pos0 $pos1 {[_]}
	text::color $pos0 $pos1 1
	text::hyper $pos0 $pos1 "$cmd $pos0"
    }
    setWinInfo -w $title read-only 1
    refresh
    return
}

proc WWW::deleteThisHistoryItem {pos0} {

    global wwwMenuVars

    set pos1 [pos::math $pos0 + 3]
    set pos2 [pos::math $pos0 + 4]
    set pos3 [pos::lineEnd $pos0]
    set url  [string trim [getText $pos2 $pos3]]
    foreach item $wwwMenuVars(history) {
	if {($url eq [lindex $item 1])} {
	    lappend deleteItems $item
	    lappend wwwMenuVars(deletedHistoryItems) $url
	} elseif {[lcontains wwwMenuVars(deletedHistoryItems) $url]} {
	    lappend alreadyGone $url
	}
    }
    if {[info exists deleteItems]} {
	WWW::deleteHistoryItem $deleteItems
	set title [win::Current]
	setWinInfo -w $title read-only 0
	replaceText $pos0 $pos1 {[X]}
	setWinInfo -w $title read-only 1
	refresh
	set msg "This item has been deleted from the history."
    } elseif {![info exists alreadyGone]} {
	set msg "Couldn't properly identify history item."
    } elseif {([llength $alreadyGone] == 1)} {
	set msg "This item has already been removed."
    } else {
	set msg "These items have already been removed."
    }
    status::msg $msg
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::clearHistory" --
 #  
 # Remove all items from the history cache.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::clearHistory {} {
    
    global wwwMenuVars

    set wwwMenuVars(history) [list \
      [list "History start" [mtime [now] short] [now]]]
    WWW::postBuildMenu
    status::msg "The WWW history has been flushed."
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::historyWindow" --
 #  
 # Create a new window containing hyperlinks to all pages rendered by the 
 # WWW menu since the last time that the history cache was cleared.
 # 
 # ------------------------------------------------------------------------- ##

proc WWW::historyWindow {} {

    global wwwMenuVars html::ParsingCache
    
    WWW::initializeHistory
    WWW::truncateHistory
    
    if {([llength $wwwMenuVars(history)] == "1")} {
	status::msg "There are no items in the history cache."
	return
    } elseif {[win::Current] eq [set title $wwwMenuVars(historyTitle)]} {
	WWW::setWindowParameters $title 1
	killWindow
    } elseif {[win::Exists $title]} {
	bringToFront $title
	return
    }
    WWW::createNewWindow $title
    html::resetCache
    set html::ParsingCache(FillColumn) 1000
    set html::ParsingCache(CR)         "\r"

    set count 0
    # This history will contain a lot of duplicates.  We'll
    # reverse the order (so that the most recent entries appear
    # first), then make the list unique.  While we're at it,
    # we'll save this unique list as the history so that it is
    # a little easier the next time that this is called.
    set wwwMenuVars(history) [lunique [lreverse $wwwMenuVars(history)]]
    set wwwMenuVars(history) [lreverse $wwwMenuVars(history)]
    set thisDate [mtime [now] short]
    set histDate [lindex [lindex $wwwMenuVars(history) 0] 1]
    set t {-*-WWW-*-

WWW History

Current date and time:   ¥THISDATE¥
WWW pages rendered since ¥HISTDATE¥

This window is in WWW mode, and the history links below can be navigated
using the arrow keys, use <return> to open them in a new browser window.

To remove individual history entries click here: <<WWW::deleteHistoryItem>>,
or here <<WWW::addHistoryCheckboxes>> to add more hyperlinks in this window
which allow you to delete individual items by clicking on the 'checkbox'.
You can use this hyperlink <<WWW::clearHistory>> to clear the entire list.

____________________________________________________________________________

}
    regsub "¥THISDATE¥" $t $thisDate t
    regsub "¥HISTDATE¥" $t $histDate t
    regsub -all "(\r|\r?\n)" $t "\r" t
    html::cacheText $t
    foreach page [lreverse [lrange $wwwMenuVars(history) 1 end]] {
	# Make sure that we're only dealing with valid names.
	if {![string length [set name [lindex $page 0]]]} {
	    continue
	}
	# Make sure that we're only dealing with unique urls.
	if {![string length [set link [lindex $page 1]]]} {
	    continue
	} elseif {[lcontains links $link]} {
	    continue
	} else {
	    lappend links $link
	}
	lappend reversedPages $page
	set pos  [html::cacheText "\"$name\""]
	set pos0 [lindex $pos 0]
	set pos1 [lindex $pos 1]
	html::cacheText "  --\r    "
	html::linkText  $link $link
	html::cacheText \r\r
	set name [win::MakeTitle $name]
	while {[lcontains marks $name]} {append name " "}
	lappend marks $name
	html::cacheItem Marks 0 $name $pos0 $pos1
	incr count
    }
    replaceText -w $title [minPos] [maxPos] [set html::ParsingCache(Text)]
    WWW::renderCacheInfo $title
    sortMarksFile
    win::searchAndHyperise {<<([^>\r\n]+)>>} {\1} 1 1 +2 -2
    help::colourTitle 5
    refresh
    goto [minPos]
    winReadOnly
    status::msg "The history cache currently includes $count pages."
    return
}

# ===========================================================================
# 
# .