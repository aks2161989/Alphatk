## -*-Tcl-*-
 # ==========================================================================
 # WWW Menu - an extension package for Alpha
 #
 # FILE: "wwwWindow.tcl"
 #                                   created: 04/30/1997 {11:04:46 am} 
 #                               last update: 01/29/2006 {11:44:19 PM} 
 # Description:
 # 
 # Procedures that support the creation of WWW windows/info.
 # 
 # See the "wwwVersionHistory.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the wwwMode.tcl file has been loaded.
wwwMode.tcl

proc wwwWindow.tcl {} {}

namespace eval WWW  {}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::setWindowVars" --
 # 
 # A handy way to ensure that we don't have values from possibly cancelled
 # procedures affecting current behavior.  Should be called at the start of
 # all menu procs, before any subsequent proc attempts to set them again.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::setWindowVars {args} {
    
    WWW::forcingUniqueTitle [lindex $args 0]
    WWW::forcingNewWindow   [lindex $args 1]
    WWW::openingFromLink    [lindex $args 2]
    WWW::openingAsTarget    [lindex $args 3]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "WWW::getWindowMode" --
 # 
 # Determine the 'mode' of the current window.  Returns "WWW" if the window
 # was created by some WWW Menu procedure.
 # 
 # --------------------------------------------------------------------------
 ##

proc WWW::getWindowMode {{winName ""}} {
    
    if {![llength [winNames]]} {
        return ""
    } elseif {($winName eq "")} {
        set winName [win::Current]
    }
    return [win::getMode $winName]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "WWW::requireWwwWindow" --
 # 
 # A handy procedure to abort procedures that are only applicable to windows
 # created by the WWW Menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc WWW::requireWwwWindow {{winName ""}} {
    
    if {($winName eq "")} {
	set winName [win::Current]
    }
    if {([WWW::getWindowMode $winName] ne "WWW")} {
	error "Cancelled -- this action is only allowed in WWW windows."
    } else {
	return
    }
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× WWW Window Parameters ×××× #
# 
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::setWindowParameters" "WWW::getWindowParameters" --
 # 
 # These are the parameters used for new WWW browser windows.  Whenever the
 # user changes the size of the browser window and either chooses a hyperlink
 # or refreshes/reloads the window, the parameters of the open window are
 # used as the new defaults, so long as the window does not send its links to
 # a target window.
 # 
 # "WWW::calculateWindowParameters" --
 # 
 # Determine the proper parameters to use for window geometry.  'g' should
 # be a list with four (possibly empty) items -- any integer will be
 # substituted for the default window size.
 # 
 # "WWW::flushWindowParameters" --
 # 
 # Forget all window parameter information.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::setWindowParameters {window {setDefault "0"}} {
        
    variable WindowParameters
    variable WindowTop
    
    set m [WWW::getWindowMode $window]
    if {($m ne "WWW") || ![win::Exists $window]} {
	return
    }
    
    # alertnote "'$window', [info level -1]"
    set g [getGeometry $window]
    set WindowParameters($window) $g
    if {$setDefault} {
	set WindowParameters(Default) $g
    }
    # This is the top of the window.
    set top [win::getInfo $window currline]
    set WindowTop($window) [pos::lineStart [pos::fromRowCol $top 0]]
    return
}

proc WWW::getWindowParameters {window {useSavedSettings 1}} {
    
    variable WindowParameters
    
    if {![string length $window]} {
	set window [win::Current]
    }
    if {!$useSavedSettings} {
        global defLeft defTop defWidth defHeight
	set p [list $defLeft $defTop $defWidth $defHeight]
    } elseif {[info exists WindowParameters($window)]} {
	set p $WindowParameters($window)
    } else {
	set p $WindowParameters(Default)
    }
    return $p
}

proc WWW::calculateWindowParameters {g} {

    set p [WWW::getWindowParameters Default]
    foreach {l t w h} $g {}
    set count 0
    foreach item [list l t w h] {
	if {![string length [set $item]] || ![is::Integer [set $item]]} {
	    set $item [lindex $p $count]
	} else {
	    switch $item {
		"l" {set l [expr {$l + 12}]}
		"t" {set t [expr {$t + 25}]}
		"w" {set w $w}
		"h" {set h $h}
	    }
	}
	incr count
    }
    return [list $l $t $w $h]
}

proc WWW::flushWindowParameters {} {
    
    global wwwMenuVars
    
    variable WindowParameters
    
    foreach item [array names WindowParameters] {
	if {$item != "Default"} {
	    unset WindowParameters($item)
	}
    }
    foreach item [list LinkTargetWindow LinkWindowTarget] {
	if {[info exists WWW::$item]} {
	    unset WWW::$item
	}
    }
    foreach item [list targetWindows] {
	set wwwMenuVars($item) [list]
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::setFillColumn"  --
 # 
 # Determine the fill column length.
 # 
 # If the WWW mode pref 'Auto Adjust Width' is not set, adjusting the WWW
 # mode pref 'fillColumn' will change the length of the text line strings in
 # the window.  Otherwise, since we know that the window was created with
 # 'WWW::createNewWindow', the font settings are known.  The formula used to
 # determine the fill column variable in this case probably could be fine
 # tuned, but works reasonably well for now.
 #  
 # -------------------------------------------------------------------------
 ##

proc WWW::setFillColumn {{window ""}} {
    
    global WWWmodeVars alpha::platform 
    
    variable WindowParameters

    if {!$WWWmodeVars(autoAdjustWidth)} {
	return $WWWmodeVars(fillColumn)
    } 
    if {($window eq "")} {
	set window [win::Current]
    }
    if {[win::Exists $window]} {
	set width [lindex [getGeometry $window] 2] ; # l t w h
    } elseif {[info exists WindowParameters($window)]} {
        set width [lindex $WindowParameters($window) 2]
    } elseif {[info exists WindowParameters(Default)]} {
	set width [lindex $WindowParameters(Default) 2]
    } else {
	set width $defWidth
    }
    set fontname $WWWmodeVars(wwwFont)
    set fontsize $WWWmodeVars(wwwFontSize)
    set X [string repeat "abcdeABCDE" 10]
    switch -- ${alpha::platform} {
	"alpha" {
	    # Yes, this is crude.
	    set fontMeas [expr {(($fontsize + 5) / 2.0)}]
	}
	"dummy" {
	    # We'd like to use this for "alpha", but [getTextDimensions]
	    # either fails or returns bogus specs.  See bug# 1783, 1788.
	    set fontDims [getTextDimensions -font $fontname -size $fontsize $X]
	    set fontMeas [expr {[lindex $fontDims 2] / 90.0}]
	}
	"tk" {
	    set fontDims [font measure [list $fontname $fontsize] $X]
	    set fontMeas [expr {[screenToDistance $fontDims] / 90.0}]
	}
    }
    set fillCol [expr {int($width / $fontMeas)}]
    set fillCol [expr {$fillCol < 20 ? 20 : $fillCol}]
    return $fillCol
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× WWW Window Titles ×××× #
# 
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::uniqueTitle" --
 # 
 # Make sure that the title we want to use isn't already used.  We also
 # massage special characters so it works in the menus.  There's a known
 # issue if the window title actually gets trimmed via 'win::MakeTitle' and
 # a second window with a similar name also gets trimmed, but I'm not sure
 # yet where the problem lies.  Can be observed in some of the AlphaTcl CVS
 # web pages where the titles are especially long -- only the first page
 # with that name gets properly rendered.
 # 
 # If "WWW::ForceUniqueTitle" is set to "1", then we simply make sure that
 # the suggested title has not been seen (and registered) before.  This is
 # true when the .html file has been obtained from a "POST" form method,
 # possibly true in other situations.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::uniqueTitle {title urlSource} {
    
    variable UrlSource
    
    # We need to preserve any empty space at the end of the title.
    regexp {(.*[^ ])( +)$} [quote::Unhtml $title] allofit title titleTail
    regsub -all "\[\r\n\t \]+"         $title { } title
    regsub -all "/|[quote::Regfind [file separator]]" $title {-} title
    regsub -all {[\{\(\<]+}            $title {Ç} title
    regsub -all {[\}\)\>]+}            $title {È} title
    set title [string trimleft $title]
    if {[info exists titleTail]} {
	append title $titleTail
    }
    if {[WWW::forcingUniqueTitle]} {
	return [WWW::registerTitle $title 1]
    } elseif {![info exists UrlSource($title)]} {
	set UrlSource($title) $urlSource
    } elseif {$urlSource ne $UrlSource($title)} {
	# 2 titles, different url sources.  We'll create a different title
	# for this page.
	while {1} {
	    if {![info exists "UrlSource($title )"]} {
		set title "$title "
		break
	    } elseif {([set "UrlSource($title )"] eq $urlSource)} {
		set title "$title "
		break
	    } else {
		set title "$title "
	    }
	}
    }
    WWW::registerTitle $title
    return $title
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::registerTitle" --
 # 
 # Remember the titles all of the windows that have been created, generally
 # by being passed through [WWW::uniqueTitle].
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::registerTitle {title {forceUnique 0}} {
    
    global wwwMenuVars
    
    if {$forceUnique} {
	while {[lcontains wwwMenuVars(registeredTitles) $title]} {
	    append title " "
	}
    }
    lappend wwwMenuVars(registeredTitles) $title
    WWW::forcingUniqueTitle 0
    return $title
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::forcingUniqueTitle" --
 # 
 # If "wwwMenuVars(forceUniqueTitle)" is set to "1", then we simply make sure
 # that the suggested title has not been seen (and registered) before.  This
 # is true when the .html file has been obtained from a "POST" form method,
 # possibly true in other situations.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::forcingUniqueTitle {{newValue ""}} {
    
    global wwwMenuVars
    
    if {[string length $newValue]} {
	set result [set wwwMenuVars(forceUniqueTitle) $newValue]
    } elseif {[info exists wwwMenuVars(forceUniqueTitle)]} {
	set result $wwwMenuVars(forceUniqueTitle)
	unset wwwMenuVars(forceUniqueTitle)
    } else {
	set result 0
    }
    return $result
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× WWW Window Creation ×××× #
# 
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::createNewWindow" --
 # 
 # Create a new window into which rendered html code will be inserted.  We
 # go to some trouble here to determine what a window's 'target' window
 # might be (currently used only for frameset windows), and to kill current
 # WWW windows if the preference for doing so is set.  The 'target' arg
 # is currently ignored.
 # 
 # Optional 'g' argument should be a list with "l t w h" corresponding to
 # window geometry that will be used to create the new window.  (Any of
 # these parameters could be empty to indicate that the default should be
 # used, but the list should be of length 4.)  This is mainly useful for
 # setting frameset window size parameters in advance.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::createNewWindow {title {target ""} {g ""}} {

    global WWWmodeVars wwwMenuVars forceMainScreen
    
    set targetTo ""
    set m [WWW::getWindowMode]
    # Remember this window's history?
    if {[set window [win::Current]] eq $wwwMenuVars(historyTitle)} {
        set noKill 1
	WWW::setWindowParameters $window 0
    } elseif {($m ne "WWW")} {
	set noKill 1
    } else {
	set noKill 0
	if {[WWW::isNotPartOfTarget $window] && $WWWmodeVars(rememberWindowGeometry)} {
	    set setDefault 1
	} else {
	    set setDefault 0
	}
	WWW::setWindowParameters $window $setDefault
    }
    # Should we kill the current window? ...
    if {![WWW::openingFromLink] || $noKill} {
	set p [WWW::getWindowParameters [set window $title] \
	  $WWWmodeVars(rememberWindowGeometry)]
    } else {
	# Is the current window part of a frameset target?
	if {![WWW::openingAsTarget]} {
	    set p [WWW::getWindowParameters $title]
	} else {
	    set targetTo [WWW::linksToTarget $window]
	    if {[string length $targetTo]} {
		# The current window links to a target window.
		set window [WWW::findTargetWindow $targetTo]
		WWW::setWindowParameters $window 0
		set p [WWW::getWindowParameters $window]
	    } elseif {![WWW::isNotPartOfTarget $title]} {
		# This title is part of a target set.
		set p [WWW::getWindowParameters $title]
	    } elseif {![WWW::isNotPartOfTarget $window]} {
		# The current window is part of a target set.
		set p [WWW::getWindowParameters $window]
	    } else {
		# This title, window have nothing to do with a target set.
		set p [WWW::getWindowParameters $title \
		  $WWWmodeVars(rememberWindowGeometry)]
	    }
	}
	if {![WWW::forcingNewWindow] && [win::Exists $window]} {
	    bringToFront $window
	    killWindow
	}
    }
    # Use default window parameters unless others are given.
    set i 0
    foreach item $g {
	if {[string length $item]} {
	    set p [lreplace $p $i $i $item]
	}
	incr i
    }
    set g $p
    # Now we finally create the window.
    set oldFMS $forceMainScreen
    set forceMainScreen 1
    set f  $WWWmodeVars(wwwFont)
    set fs $WWWmodeVars(wwwFontSize)
    eval [list new -n $title -m "WWW" -shell 1 -font $f -fontsize $fs -g] $g
    set forceMainScreen $oldFMS
    set window [win::Current]
    if {[string length $target]} {
	WWW::setWindowTarget $target $window
    }
    if {[string length $targetTo]} {
	WWW::setWindowTarget $targetTo $window
    }
    # Always (re)set these.
    WWW::setWindowParameters    $window
    set wwwMenuVars(lastWindow) $window
    return $window
}

#bringToFront foo ; killWindow ; new -n "foo" -m WWW -shell 1 -font $defaultFont -fontsize $fontSize -g 40 40 300 300 ; insertText [glob *]

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::forcingNewWindow" --
 # 
 # If "wwwMenuVars(forcingNewWindow)" is set to "1", then we won't kill any
 # current window in [WWW::createNewWindow].  If it hasn't been set earlier
 # by some code, then use the value of the "WWWmodeVars(linksOpenNewWindow)"
 # preference.  If we're not being called from a link, then this value might
 # be ignored no matter what.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::forcingNewWindow {{newValue ""}} {
    
    global wwwMenuVars WWWmodeVars
    
    if {[string length $newValue]} {
        set result [set wwwMenuVars(forcingNewWindow) $newValue]
    } elseif {[info exists wwwMenuVars(forcingNewWindow)]} {
        set result $wwwMenuVars(forcingNewWindow)
	unset wwwMenuVars(forcingNewWindow)
    } elseif {[win::Current] eq $wwwMenuVars(historyTitle)} {
	set result 1
    } else {
        set result $WWWmodeVars(linksOpenNewWindow)
    }
    return $result
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::openingFromLink" --
 # 
 # If "wwwMenuVars(openingFromLink)" is set to "1", then we won't kill
 # any current window in [WWW::createNewWindow].
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::openingFromLink {{newValue ""}} {
    
    global wwwMenuVars
    
    if {[string length $newValue]} {
	set result [set wwwMenuVars(openingFromLink) $newValue]
    } elseif {[info exists wwwMenuVars(openingFromLink)]} {
	set result $wwwMenuVars(openingFromLink)
	unset wwwMenuVars(openingFromLink)
    } else {
	set result 0
    }
    return $result
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::openingAsTarget" --
 # 
 # If "wwwMenuVars(openingAsTarget)" is set to "0", then we know that we
 # should NOT try to find any target window info, otherwise we'll perform
 # some tests as required.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::openingAsTarget {{newValue ""}} {

    global wwwMenuVars
    
    if {[string length $newValue]} {
	set result [set wwwMenuVars(openingAsTarget) $newValue]
    } elseif {[info exists wwwMenuVars(openingAsTarget)]} {
	set result $wwwMenuVars(openingAsTarget)
	unset wwwMenuVars(openingAsTarget)
    } else {
	set result 1
    }
    return $result
    
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× WWW Window Targets ×××× #
# 
# This section is something of a misnomer, because what we're really
# concerned with here is whether the windows are associated with framesets
# that use targets to open links from one window to another, so 'target' is
# more restrictive than that used in HTML. Target types of "_new" "_top" etc
# aren't handled at all -- when they are implemented, we might want to rename
# some of these to make all of this madness a little more transparent.
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::setWindowTarget" "WWW::setTitleTarget" --
 # 
 # Support for frameset windows, although this might be expanded to deal
 # with 'targets' associated with other hyperlinks as well.  If a window
 # declares a target for links, we register that window and its target in
 # 'WWW::setWindowTarget'.  
 # 
 # The 'target' is the name associated with another window.  However, since
 # we might have multiple windows open at the same time, we attempt to make
 # sure that all of them associated with the original target get associated
 # with that particular name.  This occurs in 'WWW::createNewWindow'.  It's
 # in this proc that we actually use this info to determine which window
 # should be brought to the front (optionally killing it).
 # 
 # This could probably be revised to make it a little more transparent, but
 # it works ...
 # 
 # "WWW::validTarget"  --
 # 
 # For now, we ignore any of the builtin html target facilities, such as
 # "_self" "_parent" "_new" etc.  though we could probably do something
 # with them later (in "WWW::createNewWindow").
 # 
 # "WWW::linksToTarget"  --
 # 
 # Determine if links in the window specified by 'title' should be
 # redirected to a different target window.  If 'returnName' is set to 1,
 # then we return the name, otherwise return 1 or 0.
 # 
 # "WWW::isTargetWindow"  --
 # 
 # Determine if the window specified by 'title' is used as a target by other
 # windows.  (Most often used in framesets, in which case we don't use its
 # geometry as the 'Default' value.)  If 'returnName' is set to 1, then we
 # return the name, otherwise return 1 or 0.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::setWindowTarget {window target} {
    
    global wwwMenuVars
    
    variable LinkWindowTarget
    
    if {[string length [set target [WWW::validTarget $target]]]} {
	set LinkWindowTarget($window) $target
	lunion wwwMenuVars(targetWindows) $window
    }
    return
}

proc WWW::setTitleTarget {title target} {
    
    global wwwMenuVars
    
    variable LinkTargetWindow
    
    if {[string length [set target [WWW::validTarget $target]]]} {
	set LinkTargetWindow($title) [WWW::validTarget $target]
	lunion wwwMenuVars(targetWindows) $title
    }
    return
}

proc WWW::validTarget {target} {
    if {[regexp "^\[\r\n\t \]*_" $target]} {
	set target ""
    }
    return $target
}

proc WWW::linksToTarget {title {returnName 1}} {
    
    variable LinkTargetWindow

    set result ""
    if {[info exists LinkTargetWindow($title)]} {
	set result $LinkTargetWindow($title)
    }
    if {$returnName} {
        return $result
    } else {
        return [expr {[string length $result] > 0}]
    }
}

proc WWW::isTargetWindow {window {returnName 1}} {
    
    variable LinkWindowTarget
    
    set result ""
    foreach item [array names LinkWindowTarget] {
	if {![string length $item]} {
	    continue
	} elseif {($LinkWindowTarget($item) eq $window)} {
	    set result $item
	    break
	}
    }
    if {$returnName} {
	return $result
    } else {
	return [expr {[string length $result] > 0}]
    }
}

proc WWW::findTargetWindow {targetTo} {
    
    variable LinkWindowTarget
    
    if {[info exists LinkWindowTarget($targetTo)]} {
        return $LinkWindowTarget($targetTo)
    } else {
        return ""
    }
}

proc WWW::isNotPartOfTarget {title} {
    
    global wwwMenuVars
    
    if {[lsearch $wwwMenuVars(targetWindows) $title] >= 0} {
        return 0
    } elseif {![WWW::linksToTarget $title 0] && ![WWW::isTargetWindow $title 0]} {
	return 1
    } else {
        return 0
    }
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× WWW Window Utilities ×××× #
# 
# 

proc WWW::listOpenWindows {{includeUrls 0}} {
    
    variable UrlSource
    
    set windows [list]
    foreach window [lsort -dictionary [winNames -f]] {
	if {![info exists UrlSource($window)]} {
	    continue
	} elseif {!$includeUrls} {
	    lappend windows $window
	} else {
	    lappend windows [list $window $UrlSource($window)]
	}
    }
    return $windows
}

proc WWW::refreshWindow {{window ""}} {
    
    global WWWmodeVars wwwMenuVars
    
    variable FileSource
    variable UrlSource
    
    if {![string length $window]} {
	set window [win::Current]
    }
    
    # Forget previous window cache.
    WWW::resetWindowCache $window
    # But remember current window geometry (?)
    if {![set setDefault [WWW::isNotPartOfTarget $window]]} {
        set setDefault $WWWmodeVars(rememberWindowGeometry)
    }
    WWW::setWindowParameters $window $setDefault
    WWW::setWindowVars
    WWW::openingFromLink 0
    WWW::forcingNewWindow 1
    WWW::openingAsTarget 0

    if {($window eq $wwwMenuVars(historyTitle))} {
	set script [list WWW::menuProc "" history]
    } elseif {[info exists FileSource($window)] && \
      [file exists $FileSource($window)]} {
	set script [list WWW::renderLocal $FileSource($window)]
    } elseif {[info exists UrlSource($window)]} {
	set script [list WWW::renderRemote $UrlSource($window)]
    } else {
	status::msg "Couldn't find the source of '$window'."
	return -code return
    }
    # ... then refresh the file from the source.
    killWindow
    eval $script
    return
}

# Need to adjust this to make sure that windows only have one fetched file
# associated with them -- otherwise scripts like those found in the proc
# [WWW::webPageHasChanged] might find the 'old' file mappings which are not
# appropriate for the task at hand.  (For example, reload a wiki page, and
# then edit it, save it, but the rendered window is not properly updated.)

proc WWW::reload {{window ""} {fromCache 0}} {

    global wwwMenuVars
    
    variable FileSource
    variable UrlSource
    
    if {![string length $window]} {
	set window [win::Current]
    }
    
    # Forget previous window cache.
    WWW::resetWindowCache $window
    # But remember current window geometry.
    WWW::setWindowParameters $window [WWW::isNotPartOfTarget $window]

    if {($window eq $wwwMenuVars(historyTitle))} {
	set script [list WWW::navigationProc "" history]
    } elseif {[info exists FileSource($window)]} {
	set fileSource $FileSource($window)
	if {$fromCache || ![temp::isIn WWW-fetch $fileSource]} {
	    set script [list WWW::renderLocal $fileSource]
	} else {
	    # Make sure that the source file isn't open.
	    if {[win::Exists $fileSource]} {
		bringToFront $fileSource
		set msg "Kill Window?\r\r(The temporary source\
		  file of '$window' has to be deleted in order\
		  to re-fetch the window.)"
	        if {[askyesno $msg]} {
	            killWindow
	        } else {
		    status::msg "Cancelled -- temporary source file has to be deleted."
		    return -code return
	        }
	    }
	    file delete $fileSource
	    unset FileSource($window)
	}
    }
    if {![info exists script]} {
	if {[info exists UrlSource($window)]} {
	    if {!$fromCache} {
		if {[file isfile $window]} {
		    file delete $window
		}
	    }
	    set script [list WWW::renderRemote $UrlSource($window)]
	} else {
	    status::msg "Couldn't find the source of '$window'."
	    return -code return
	}
    }
    killWindow
    eval $script
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::resetWindowCache" --
 #  
 # If a window is reloaded or refreshed, we remove all of the previously
 # cached info, and any previously cached file.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::resetWindowCache {{window ""}} {
    
    variable TitleParse
    
    if {![string length $window]} {
	set window [win::Current]
    }
    
    foreach item [list Colors Links Marks] {
	global WWW::${item}
	catch {unset WWW::${item}($window)}
    }
    if {[info exists TitleParse($window)]} {
	set f [temp::path WWW-parse $TitleParse($window)]
	if {[file isfile $f]} {
	    file delete $f
	}
    }
    return
}

# Used, e.g., by Wiki mode.

proc WWW::webPageHasChanged {url {newContents ""}} {

    variable UrlSource
    variable FileSource

    set localfiles [list]
    foreach name [array names UrlSource] {
	if {($UrlSource($name) eq $url)} {
	    lappend localfiles $name
	}
    }
    if {![llength localfiles]} {
	return 0
    }
    foreach localfile $localfiles {
	if {[win::Exists $localfile]} {
	    set localwindow $localfile
	    break
	}
    }
    if {[info exists localwindow] && [info exists FileSource($localwindow)]} {
	bringToFront $localwindow
	if {[info exists FileSource($localwindow)]} {
	    if {[string length $newContents]} {
		file::writeAll $FileSource($localwindow) $newContents 1
		WWW::reload $localwindow 1
	    } else {
		WWW::reload $localwindow
	    }
	}
	return 1
    } else {
	return 0
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::prevBrowserWindow" --
 #  
 # Called by the WWW Mode binding, bring a different WWW window to the front. 
 # Yeah, the order here is NOT the most recent WWW window, because that would
 # mean that we could only toggle between the current and most recent
 # windows, and each time they would switch places in the order.  The only
 # alternative would be to do something similar to [prevWindow].
 # -------------------------------------------------------------------------
 ##

proc WWW::prevBrowserWindow {} {
    
    global wwwMenuVars
        
    foreach window [lreverse [lrange [winNames -f] 1 end]] {
	if {([WWW::getWindowMode $window] eq "WWW")} {
	    bringToFront $window
	    set wwwMenuVars(lastWindow) $window
	    return
	}
    }
    # Still here?
    status::msg "No additional WWW browser windows found."
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::debuggingWindow" --
 #  
 # This is a developers tool.  Some of these code is wrapped in a catch, and
 # will call this procedure if we throw an error.  Set wwwMenuVars(debugging)
 # to '1' in order to immediately find out what went wrong.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::debuggingWindow {} {

    global wwwMenuVars errorInfo

    if {!$wwwMenuVars(debugging)} {
	return
    }
    error::window $errorInfo
    return -code return
}

# ===========================================================================
# 
# .