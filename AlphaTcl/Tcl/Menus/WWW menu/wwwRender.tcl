## -*-Tcl-*-
 # ==========================================================================
 # WWW Menu - an extension package for Alpha
 # 
 # FILE: "wwwRender.tcl"
 #                                          created: 04/30/1997 {11:04:46 am}
 #                                      last update: 03/02/2005 {01:00:45 PM}
 # Description:
 # 
 # Procedures to fetch remote and then render local html files.
 # 
 # See the "wwwVersionHistory.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the wwwMode.tcl file has been loaded.
wwwMode.tcl

proc wwwRender.tcl {} {}

namespace eval WWW {}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Rendering Urls / Files ×××× #
# 
# We use two different temporary caches here.  The first, 'WWW-fetch', is
# where remote url files land before they are read and parsed.  Saving them
# in this cache allow us to re-render them without downloading them from the
# source every time.  The second, 'WWW-parse', contains the raw parsed text
# obtained from 'WWW::ParsingCache(Text)', and allows us to simply insert it
# and recolorize without having to go through 'html::parseHtml' every time
# the window is re-opened.
# 
# 'WWW::Fetch/ParseNumber' are used to increment the cached url/filenames
# (i.e. 000023.html) whenever we're dealing with a url/filename that we
# haven't seen before.
# 

ensureset wwwMenuVars(fetchNumber) 0
ensureset wwwMenuVars(parseNumber) 0

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::renderUrl" "WWW::renderRemote" --
 #  
 # Attempt to render a url if the http package is available and the url is
 # actually remote.  If local, convert the filename and simply pass it on to
 # [WWW::renderLocal].  
 # 
 # [WWW::renderUrl] differs from [WWW::renderRemote] in that we specify first
 # that we are NOT opening the file from a link, which affects how window
 # geometry, killing current windows is handled.
 #  
 # -------------------------------------------------------------------------
 ##

proc WWW::renderUrl {args} {

    WWW::setWindowVars
    WWW::openingFromLink  0
    WWW::forcingNewWindow 1
    return [eval WWW::renderRemote $args]
}

proc WWW::renderRemote {{url ""} {fileName ""} {target ""} {g ""}} {

    global WWWmodeVars wwwMenuVars
    
    variable UrlAction
    variable UrlSource

    set url [string trim [string trim $url {\"}]]
    set m [WWW::getWindowMode]
    if {![string length $url]} {
	if {![WWW::httpAllowed]} {
	    return [WWW::renderLocal "" $fileName $target $g]
	} elseif {($m eq "WWW") && [info exists UrlSource([win::Current])]} {
	    set url $UrlSource([win::Current])
	} elseif {[catch {getSelect} url]} {
	    set url $WWWmodeVars(homePage)
	}
	status::msg "[dialog::specialView::url $url]"
	set url [dialog::getUrl "Enter the url to be viewed:" $url]
    }
    # Make sure that we can handle this action before attempting to download.
    if {![regexp {^[^:]+:/[/]+} $url]} {
	set url http://$url
    }
    if {[regexp {^file://} $url]} {
	WWW::massagePath  url
	return [WWW::renderLocal $url "" $target $g]
    } elseif {[regexp {^ftp://} $url]} {
	WWW::ftpLink $url
    } elseif {![WWW::httpAllowed]} {
	# We can't handle this yet.
	WWW::externalLink $url
	return
    }
    # More tests.
    foreach pat [array names UrlAction] {
	if {[regexp {^\^} $pat]} {
	    continue
	}
	if {[regexp -nocase $pat $url]} {
	    return [$UrlAction($pat) $url]
	}
    }
    regsub "(^\[\t \]*<)|(>\[\t \]*$)" $url "" url
    # Make sure that this url has a trailing '/' if it is a server.
    set parent [string range $url 0 [string last "/" $url]]
    if {[regexp {^[^:]+:/[/]+$} $parent]} {
	append url "/"
    }
    # Check to make sure that we don't already have this window, or at least
    # the file (so that we don't have to download it again.)
    foreach name [array names UrlSource] {
	if {($UrlSource($name) eq $url)} {
	    # Hmmm...  is it a window or a file?
	    if {[win::Exists $name]} {
		bringToFront $name
		set wwwMenuVars(lastWindow) $name
		return $name
	    } elseif {[file isfile $name]} {
		return [WWW::renderLocal $name "" $target $g]
	    }
	}
    }
    # Fetch the file to our temporary directory.
    if {![string length $fileName]} {
	set fileName "[format %08d [incr wwwMenuVars(fetchNumber)]].html"
    }
    set newFile [file join [temp::directory WWW-fetch] $fileName]
    status::msg "Fetching $url" ; watchCursor
    if {[catch {url::fetch $url [temp::directory WWW-fetch] $fileName} result]} {
	alertnote "Sorry, that url is currently unavailable" \
	  "The error was:" $result
	return
    }
    status::msg "Fetch complete.  RenderingÉ"
    # Make sure we still know the url.
    if {[string length [set redirect [lindex $result 2]]]} {
	set url $redirect
    }
    set UrlSource([file nativename $newFile]) $url
    # This regexp might need fine-tuning.
    if {[regexp {\.php\?} $url]} {
	WWW::forcingUniqueTitle 1
    }
    # Now we render the local file.
    return [WWW::renderLocal $newFile "" $target $g]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::renderFile" "WWW::renderLocal" --
 #  
 # Attempt to render a local (possibly fetched and cached) file if it is
 # actually html code, otherwise just insert the entire contents of the
 # file in a new window.  We go to a bit of trouble here to ensure that the
 # title is unique, and set a bunch of information for the title that will
 # be used elsewhere.  We cache the parsing info so that if the window is
 # closed and then called to be rendered again we don't have to go through
 # the entire parsing routine again.
 #  
 # [WWW::renderFile] differs from [WWW::renderLocal] in that we specify first
 # that we are NOT opening the file from a link, which affects how window
 # geometry, killing current windows is handled.
 #  
 # -------------------------------------------------------------------------
 ##

proc WWW::renderFile {args} {

    WWW::setWindowVars
    WWW::openingFromLink  0
    WWW::forcingNewWindow 1
    return [eval WWW::renderLocal $args]
}

proc WWW::renderLocal {{f ""} {title ""} {target ""} {g ""}} {
    
    global WWWmodeVars wwwMenuVars html::ParsingCache
    
    variable BaseUrl
    variable FileSource
    variable TitleParse
    variable UrlSource
    variable WindowTop

    # Preliminaries
    if {[string length $title] && [win::Exists $title]} {
	# We already have this window open.
	bringToFront $title
	set wwwMenuVars(lastWindow) $title
	return $title
    }
    if {($f eq "") || [file isdir $f]} {
	set f [getfile "View which file?" $f]
    }
    if {![file isfile $f]} {
	if {[win::Exists $f]} {
	    # A current window that doesn't exist on disk.
	    set n [format %08d [incr wwwMenuVars(fetchNumber)]].txt
	    set f [file join [temp::directory WWW-fetch] $n]
	    if {![catch {alphaOpen $f "w+"} fid]} {
		puts -nonewline $fid [getText [minPos] [maxPos]]
		close $fid
	    } else {
		WWW::debuggingWindow
	    }
	} else {
	    set msg "Cancelled -- couldn't find the file '$f' !!"
	    alertnote $msg
	    return -code return
	}
    }

    if {$WWWmodeVars(openGoToUrlWindow)} {
	catch WWWsh::openShellWindow
    }

    set t [file::readAll $f]
    # Is this an html file?
    set isHtml [regexp -nocase {<\s*(!DOCTYPE|HTML|BODY|TITLE)[^>]*>} $t]
    # If this is an html file, does it have its own encoding?  If so, we
    # register the encoding for the local (possibly fetched) file and then
    # reset the "t" variable for the new contents.
    set metaT $t
    set metaPat {<\s*META\s+[^>]*>}
    while {[regexp -nocase -- $metaPat $metaT metaString]} {
	html::getAttributes $metaString "metaArray" 1 CONTENT
	set charsetPat {charset\s*=\s*([-a-zA-Z0-9]+)}
	if {[regexp -nocase -- $charsetPat $metaArray(CONTENT) -> charset]} {
	    # Find a matching encoding name, if possible
	    set encnames [encoding names]
	    set charset [string tolower $charset]
	    set encs [string tolower $encnames]
	    if {([set idx [lsearch -exact $encs $charset]] == -1)} {
		regsub -all -- "-" $encs "" encs
		regsub -all -- "-" $charset "" charset
		set idx [lsearch -exact $encs $charset]
	    }
	    if {($idx != -1)} {
		# Tell AlphaTcl to set the encoding for this window.
		set t [file::readAll $f [lindex $encnames $idx]]
	    }
	    break
	}
	if {![regsub -nocase -- $metaPat $metaT "" metaT]} {
	    # If this failed, then we'll end up in a recursive loop.
	    # Need to look further into why this might happen!
	    # (Most likely caused by a lack of "-nocase" in earlier versions.)
	    break
	}
    }
    unset metaT
    # Try to determine what the title should be.
    if {![string length [string trim $title]]} {
	if {$isHtml} {
	    regexp -nocase {<TITLE[^>]*>(.*)</TITLE>} $t dummy title
	} elseif {[info exists UrlSource([file nativename $f])]} {
	    set url [string trimright $UrlSource([file nativename $f]) "/"]
	    regsub {\?.+$} $url {} url
	    set last  [string last "/" $url]
	    set title [quote::Unurl [string range $url [expr $last + 1] end]]
	} else {
	    set title [file tail $f]
	}
    }
    # Just a little insurance for weirdly formatted pages that might have two
    # </title> tags.  Can happen if the page was reading in the html code
    # from another complete page.
    regsub "</title>.*" $title "" title
    # Convert entities in the title, and trim as necessary.
    html::convertEntities title
    regsub -all "\[\r\n\t \]+" $title " " title
    if {![string length [set title [string trim $title]]]} {
	set title "(no title)"
    } elseif {[string length $title] > 65} {
	set t1 [string range $title 0 30]
	set t2 [string range $title [expr {[string length $title] - 30}] end]
	set title ${t1}É${t2}
    }
    # Determine what the base is for this file.  We have to do this even if
    # the window is going to use framesets.  We'll register the base and any
    # target after we're sure that we have a unique title name.
    set base   ""
    set target ""
    if {[regexp -nocase {<(BASE[^>]+)>} $t dummy baseString]} {
	html::getAttributes $baseString "baseArray" 1 HREF TARGET
	set base   $baseArray(HREF)
	set target $baseArray(TARGET)
    }
    # Any base from <base ...> might still be relative.
    if {[info exists UrlSource([file nativename $f])]} {
	# This should always supercede.
	set base [url::makeAbsolute $UrlSource([file nativename $f]) $base]
    } else {
	set base [url::makeAbsolute [file::toUrl $f] $base]
    }
    # Make sure that we have an initial url source for this file.
    if {![info exist UrlSource([file nativename $f])]} {
	set UrlSource([file nativename $f]) [file::toUrl $f]
    }
    regsub -all {\\} $base {/} base
    # Make sure that we're not dealing with a title that has already been
    # registered, but from a different source.
    set title [WWW::uniqueTitle $title $UrlSource([file nativename $f])]
    # Register the base url and any base target for the window.
    set BaseUrl($title) $base
    if {![info exists FileSource($title)]} {
	set FileSource($title) $f
    }
    if {[info exists UrlSource([file nativename $f])]} {
        set UrlSource($title) $UrlSource([file nativename $f])
    }
    if {![info exist UrlSource($title)]} {
        set UrlSource($title) [file::toUrl $f]
    }
    # If this web page uses frames ...
    if {[regexp -nocase {<FRAMESET([^>]*)>(.+)</FRAMESET>} $t]} {
	WWW::addHistoryItem $f $title
	return [WWW::renderFrames $title $t]
    }
    # Have we seen this window before?
    if {[info exists TitleParse($title)]} {
	set f1 [temp::path WWW-parse $TitleParse($title)]
	if {[file isfile $f1]} {
	    set t [file::readAll $f1]
	    set isHtml 0
	}
    }
    # If this title is not already a window ...
    if {[win::Exists $title]} {
	bringToFront $title
    } else {
	# ...  then create a new shell window, and add the parsed text.  If
	# the 'title' changes here, the base url is probably screwed up.
	# set title [WWW::createNewWindow $title $target]
	WWW::createNewWindow $title $target $g
	# We can't quite handle rendering in background windows, and even if
	# we are in the foreground, it seems as if we really need to force
	# the issue here.  (esp for Alphatk.)
	bringToFront $title
	if {!$isHtml} {
	    # Not an html file, or previously rendered and we're using the
	    # cached info.
	    insertText -w $title $t
	    WWW::rerenderCacheInfo $title
	} else {
	    insertText -w $title "\r\rPlease wait ... rendering html window ..."
	    goto -w $title [minPos]
	    status::msg "RenderingÉ" ; watchCursor
	    # How many links will be parsed?  If we have a lot, let the
	    # user know.
	    set pat {<A[^>]+HREF[^>]+>}
	    set linkLength [regexp -all -nocase $pat $t]
	    if {$linkLength > 500} {
		status::msg "Rendering -- $linkLength links to be parsed, please be patient É"
	    }
	    if {[catch {html::parseHtml $t [WWW::setFillColumn $title]}]} {
		WWW::debuggingWindow
	    }
	    set t [set html::ParsingCache(Text)]\r\r
	    replaceText -w $title [minPos] [maxPos -w $title] $t
	    # Render all of our cache info.
	    if {[catch {WWW::renderCacheInfo $title $BaseUrl($title)}]} {
		WWW::debuggingWindow
	    }
	    # Save the window's text in the cache folder so that if we try
	    # to re-render it after the window has been closed we don't
	    # have to go through the entire parsing routine again.
	    set n  [format %08d [incr wwwMenuVars(parseNumber)]].txt
	    set f2 [file join [temp::directory WWW-parse] $n]
	    if {![catch {alphaOpen $f2 "w+"} fid]} {
		puts -nonewline $fid $t
		close $fid
		set TitleParse($title) $n
	    } else {
		WWW::debuggingWindow
	    }
	}
	setWinInfo -w $title read-only 1
	goto -w $title [minPos]
	refresh
	status::msg ""
    }
    WWW::setTitleTarget $title $target
    if {[catch {
	# Cache this source in various history vars/arrays.
	WWW::visitedLink $UrlSource($title)
	WWW::addHistoryItem $f $title
	# And add it to the command line.
	WWWsh::updateCommandLine $UrlSource($title)
    }]} {
        WWW::debuggingWindow
    }
    set wwwMenuVars(lastWindow) $title
    # Try to move the insertion to the last known line.
    if {[info exists WindowTop($title)]} {
        goto -w $title $WindowTop($title)
	insertToTop -w $title
    }
    if {$WWWmodeVars(autoFloatMarks)} {
	catch floatNamedMarks
    }
    return $title
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::renderFrames" --
 #  
 # The original file has been passed partway through 'WWW::renderLocal', so
 # the title and base url has already been determined.  Now we're going to
 # identify the different files that have to be rendered, and pass them
 # through 'WWW::renderRemote/Local' separately.
 # 
 # We attempt to set different window sizes for each frame.  By setting
 # values in the 'WWW::LinkWindowTarget' array, we're designating links
 # from one frame to be rendered in a different window, using the magic in
 # "wwwMenu.tcl" for determining when WWW browser windows should be killed.
 # 
 # Known limitations:
 # 
 # ¥ Nested <FRAMESET> tags are not dealt with at all.
 # 
 # ¥ Should come up with some method for offering <NOFRAMESET> option if the
 #   tag exists.
 # 
 # ¥ If the COLS or ROWS option is a numeric value (i.e. no % or *), we
 #   attempt to size the windows according to the code.  Could also try to
 #   do something fancy with % or * values, but that will require a bit more
 #   work here -- what we might need to do is rethink that whole 'window
 #   parameters' settings so that we just have one (hopefully wide) window
 #   setting that isn't likely to change without more explicit action from
 #   the user, such as a 'Default Window SizeÉ" menu item in the WWW
 #   menu, which would open a window with instructions and a hyperlink to
 #   save settings.  It all gets more complicated with synching the
 #   behavior between Alpha7/8/X and Alphatk.
 #   
 # ¥ Links created with <A HREF...  TARGET...> store the target info in
 #   the array WWW::Links, and 'WWW::link' passes this info along to the
 #   url handlers, but none of them actually do anything with the info. 
 #   Currently, the target is entirely window dependent, i.e. target
 #   windows are designated for all or no links in the window.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::renderFrames {title t} {
    
    global WWWmodeVars wwwMenuVars
    
    variable BaseUrl
    
    set base $BaseUrl($title)
    # Make sure that we were properly called.
    set pat {<(FRAMESET[^>]*)>(.+)</FRAMESET>}
    if {![regexp -nocase $pat $t dummy framesetAtts frames]} {
	error "'$title' shouldn't have been passed to WWW::renderFrames"
    }
    # Determine any FRAMESET options
    html::getAttributes $framesetAtts framesetArray 1 COLS ROWS
    set frameType ""
    set values [list]
    # Currently only handles one of COLS or ROWS, and even then only
    # for absolute pixel lengths.
    if {[string length framesetArray(COLS)]} {
	set frameType "col"
	set values [split $framesetArray(COLS) ","]
    } elseif {[string length framesetArray(ROWS)]} {
	set frameType "row"
	set values [split $framesetArray(ROWS) ","]
    }
    # Temporarily turn off 'autoFloatMarks'
    set oldAFM $WWWmodeVars(autoFloatMarks)
    set WWWmodeVars(autoFloatMarks) 0
    # Determine the url and any target for each frame.
    while {[regexp -nocase -- {<(FRAME\s+[^>]*)>(.*)} $frames -> frameAtts \
      theRest]} {
	html::getAttributes $frameAtts frameArray 1 SRC NAME
	if {[catch {url::makeAbsolute $base $frameArray(SRC)} url]} {
	    set url "????"
	}
	lappend results $url
	set targetWindow($url) $frameArray(NAME)
	set frames $theRest
    }
    # Let the user know what's going on, and only render the urls specified. 
    # If we're not going to do all of all the frames, then we won't resize
    # any of them later.
    if {![info exists results]} {
	set WWWmodeVars(autoFloatMarks) $oldAFM
	alertnote "This web page uses frames,\
	  but no frame pages could be identified."
	status::msg "Cancelled"
	return -code return
    } elseif {$WWWmodeVars(alwaysOpenFrames)} {
	set framePages $results
    } elseif {![dialog::yesno -y "OK" -n "Choose FramesÉ" -c \
      "This web page uses frames, each of which will be opened\
      in a separate window."]} {
	foreach page $results {
	    set pageView [dialog::specialView::url $page]
	    set pages($pageView) $page
	}
	set p "View which frames?"
	set l [lsort -dictionary [array names pages]]
	set framePages [list]
	foreach pageView [listpick -p $p -l $l] {
	    lappend framePages $pages($pageView)
	}
	set values [list]
    } else {
        set framePages $results
    }
    # Determine any window size parameters in advance.  geometry: l t w h
    # If we don't have a frametype, the defaults will get used.
    switch $frameType {
	"col" {
	    # This is a side by side frame.
	    set w [lindex $values 0]
	    set g [WWW::calculateWindowParameters [list "" "" $w ""]]
	    if {[is::Integer []]} {
		set g [lreplace $g 2 2 $w]
	    }
	}
	"row" {
	    # This is a row by row frame.
	    set h [lindex $values 0]
	    set g [WWW::calculateWindowParameters [list "" "" "" $h]]
	}
	"" {
	    set g ""
	}
	default {error "Unknown frame type: $frameType"}
    }
    # We'll kill the first window if necessary, but not the others.
    set title1 [WWW::renderRemote [lindex $framePages 0] "" "" $g]
    if {[info exists targetWindow([lindex $framePages 0])]} {
	WWW::setWindowTarget $title1 $targetWindow([lindex $framePages 0])
    }
    # Now render the remaining frames.
    foreach url [lrange $framePages 1 end] {
	switch $frameType {
	    "col" {
		# This is a side by side frame.
		set l [lindex $values 0]
		set g [WWW::calculateWindowParameters [list $l "" "" ""]]
	    }
	    "row" {
		# This is a row by row frame.
		set t [lindex $values 0]
		set g [WWW::calculateWindowParameters [list "" $t "" ""]]
	    }
	    "" {
		set g ""
	    }
	}
	set title [WWW::renderUrl $url "" "" $g]
	if {[info exists targetWindow($url)]} {
	    WWW::setWindowTarget $targetWindow($url) $title
	}
    }
    set WWWmodeVars(autoFloatMarks)     $oldAFM
    bringToFront $title1
    set wwwMenuVars(lastWindow) $title1
    return $title1
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Rendering Parsing Cache ×××× #
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::renderCacheInfo" --
 #  
 # All of the colors, links, etc information is now saved in various
 # elements of the 'html::ParsingCache' array.  'Positions' are all relative
 # to the minimum position of the window, and now need to be converted --
 # in Alpha7 we save quite a bit of time because we know that positions are
 # valid as they are.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::renderCacheInfo {title {base ""}} {

    watchCursor

    global wwwMenuVars WWWmodeVars html::ParsingCache
    
    variable DefaultLinkColor
    variable TodaysUrls
    
    foreach item [list Anchors Colors Links LinksReverse Marks Forms] {
	variable $item
	array set $item [list $title [list]]
    }
    # Create the list of visited links.
    if {$title != $wwwMenuVars(historyTitle)} {
	set visitedLinks $wwwMenuVars(visited)
    } else {
	set visitedLinks [array names TodaysUrls]
    }
    # Anchors
    foreach item   [set html::ParsingCache(Anchors)] {
	set name   [lindex $item 0]
	set pos1   [pos::math -w $title [minPos] + [lindex $item 1]]
	lappend Anchors($title) [list $name $pos1]
    }
    # Colors which aren't hyperlinks
    foreach item   [set html::ParsingCache(Colors)] {
	set pos0   [pos::math -w $title [minPos] + [lindex $item 0]]
	set pos1   [pos::math -w $title [minPos] + [lindex $item 1]]
	set color  [lindex $item 2]
	# We attempt to avoid colorizing across empty space if
	# possible.
	set txt    [string trimleft  [getText -w $title $pos0 $pos1]]
	set pos0   [pos::math -w $title $pos1 - [string length $txt]]
	set txt    [string trimright [getText -w $title $pos0 $pos1]]
	set pos1   [pos::math -w $title $pos0 + [string length $txt]]
	text::color $pos0 $pos1 $color
	lappend Colors($title) [list $pos0 $pos1 $color]
	unset color
    }
    # Links
    foreach item   [set html::ParsingCache(Links)] {
	set pos0   [pos::math -w $title [minPos] + [lindex $item 0]]
	set pos1   [pos::math -w $title [minPos] + [lindex $item 1]]
	set link   [lindex $item 2]
	set target [lindex $item 3]
	if {($link eq "IndexSearch")} {
	    set link  [list WWW::indexSearch $base]
	    set cmd   $link
	    set color $WWWmodeVars(formsColor)
	    set DefaultLinkColor($link) $color
	} elseif {[regexp {^(FORM)} $link]} {
	    # Get the info about this form link.
	    set formArgs    [split $link "-"]
	    set formNumber  [lindex $formArgs 1]
	    set fieldNumber [lindex $formArgs 3]
	    set target      [list $formNumber $fieldNumber]
	    # Create the link.
	    set link  [list WWW::formLink $target]
	    set cmd   [list WWW::formLink $target]
	    set color $WWWmodeVars(formsColor)
	    set DefaultLinkColor($link) $color
	} elseif {[catch {url::makeAbsolute $base $link} url]} {
	    set link  "error: unknown base for link."
	    set cmd   [list WWW::errorLink $link]
	    set color red
	    set DefaultLinkColor($link) $color
	} else {
	    set link  $url
	    set cmd   [list WWW::link $url]
	    if {([lsearch -exact $visitedLinks $link] == -1)} {
		set color $WWWmodeVars(linkColor)
	    } else {
		set color $WWWmodeVars(visitedLinkColor)
	    }
	}
	if {($target eq "")} {
	    set target [set html::ParsingCache(BaseTarget)]
	}
	# We attempt to avoid hyperlinking across empty space if
	# possible.
	set txt    [string trimleft  [getText -w $title $pos0 $pos1]]
	set pos0   [pos::math -w $title $pos1 - [string length $txt]]
	set txt    [string trimright [getText -w $title $pos0 $pos1]]
	set pos1   [pos::math -w $title $pos0 + [string length $txt]]
	text::color $pos0 $pos1 $color
	text::hyper $pos0 $pos1 $cmd
	lappend Links($title) [list $pos0 $pos1 $link $target $cmd]
    }
    set LinksReverse($title) [lreverse $Links($title)]
    # Marks
    set marks [list]
    foreach item   [set html::ParsingCache(Marks)] {
	set indent ""
	set hNum   [lindex $item 0]
	if {$hNum > $WWWmodeVars(markHeadingsToLevel)} {
	    continue
	} else {
	    set num $hNum
	}
	while {$num > 1} {append indent "  " ; incr num -1}
	set name [markTrim ${indent}[lindex $item 1]]
	while {[lcontains marks $name]} {append name " "}
	set pos1   [pos::math -w $title [minPos] + [lindex $item 2]]
	set pos2   [pos::math -w $title [minPos] + [lindex $item 3]]
	set txt    [string trimleft  [getText -w $title $pos1 $pos2]]
	set pos1   [pos::math -w $title $pos2 - [string length $txt]]
	set txt    [string trimright [getText -w $title $pos1 $pos2]]
	set pos2   [pos::math -w $title $pos1 + [string length $txt]]
	set pos0   [pos::prevLineStart $pos1]
	if {($hNum == "1")} {
	    # Place a divider between level 1 headings, but not the first.
	    set divider "-"
	    if {[info exists dividers]} {
		while {[lcontains dividers $divider]} {append divider " "}
		setNamedMark $divider $pos0 $pos1 $pos2
		lappend Marks($title) [list $divider $pos0 $pos1 $pos2]
	    }
	    lappend dividers $divider
	}
	setNamedMark $name $pos0 $pos1 $pos2
	lappend Marks($title) [list $name $pos0 $pos1 $pos2]
    }
    # Forms -- saving the form cache for use later.
    foreach item   [set html::ParsingCache(Forms)] {
	# Get the info about this form link.
	set formArgs    [split [lindex $item 0] "-"]
	set formNumber  [lindex $formArgs 1]
	set fieldNumber [lindex $formArgs 3]
	set itemType    [lindex $formArgs 4]
	# Items remaining are "$typeAtts $pos0 $pos1 $args"
	set typeAtts    [lindex $item 1]
	set pos0        [pos::math -w $title [minPos] + [lindex $item 2]]
	set pos1        [pos::math -w $title [minPos] + [lindex $item 3]]
	set args        [lindex $item 4]
	# We attempt to avoid hyperlinking across empty space if
	# possible.
	set txt    [string trimleft  [getText -w $title $pos0 $pos1]]
	set pos0   [pos::math -w $title $pos1 - [string length $txt]]
	set txt    [string trimright [getText -w $title $pos0 $pos1]]
	set pos1   [pos::math -w $title $pos0 + [string length $txt]]
	# Save this info to be dealt with later if the user calls a form
	# item hyperlink.
	set Forms($formNumber,$fieldNumber) \
	  [list $itemType $typeAtts $pos0 $pos1 $args]
    }
    # Remove the cache now, unless it's needed for debugging.
    if {!$wwwMenuVars(debugging)} {
	unset html::ParsingCache
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::rerenderCacheInfo" --
 #  
 # If a window has been saved as a file, and then closed and re-opened, it
 # might not have any colors/hypers/marks info anymore.  So long as the
 # array info has been saved, we can re-render the window again.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::rerenderCacheInfo {{title ""}} {
    
    global WWWmodeVars wwwMenuVars
    
    variable DefaultLinkColor
    variable TodaysUrls
    
    requireOpenWindow
    
    if {![string length $title]} {
        set title [win::Current]
    } elseif {![win::Exists $title]} {
        status::msg "Couldn't find the window '$title'."
	return -code return
    } else {
        bringToFront $title
    }
    set wwwMenuVars(lastWindow) $title
    
    foreach item [list Colors Links Marks Forms] {
	variable $item
	if {![info exists ${item}($title)]} {
	    array set $item [list $title [list]]
	}
    }
    # Create the list of visited links.
    if {$title != $wwwMenuVars(historyTitle)} {
	set visitedLinks $wwwMenuVars(visited)
    } else {
	set visitedLinks [array names TodaysUrls]
    }
    # Colors which aren't hyperlinks
    foreach item $Colors($title) {
	set pos0 [lindex $item 0]
	set pos1 [lindex $item 1]
	text::color $pos0 $pos1 [lindex $item 2]
    }
    # Links
    foreach item $Links($title) {
	set pos0 [lindex $item 0]
	set pos1 [lindex $item 1]
	set link [lindex $item 2]
	if {[info exists DefaultLinkColor($link)]} {
	    set color $DefaultLinkColor($link)
	} elseif {([lsearch -exact $visitedLinks $link] == -1)} {
	    set color $WWWmodeVars(linkColor)
	} else {
	    set color $WWWmodeVars(visitedLinkColor)
	}
	text::color $pos0 $pos1 $color
	text::hyper $pos0 $pos1 [lindex $item 4]
    }
    # Marks
    foreach item $Marks($title) {
	set name [lindex $item 0]
	set pos0 [lindex $item 1]
	set pos1 [lindex $item 2]
	set pos2 [lindex $item 3]
	setNamedMark $name $pos0 $pos1 $pos2
    }
    return
}

# ===========================================================================
# 
# .