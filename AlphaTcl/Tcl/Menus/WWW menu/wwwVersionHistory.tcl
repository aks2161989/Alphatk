## -*-Tcl-*-
 # ==========================================================================
 # WWW Menu - an extension package for Alpha
 #
 # FILE: "wwwVersionHistory.tcl"
 #                                          created: 04/30/1997 {11:04:46 am}
 #                                      last update: 02/28/2006 {05:00:37 PM}
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #    
 # Includes contributions from Craig Barton Upright
 # 
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu/>
 #    
 # Copyright (c) 1997-2006 Vince Darley, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc wwwVersionHistory.tcl {} {}

# This is a back compatibility proc, in case it is still used in other files.

proc wwwParseFile {{f ""} {title ""}} {
    WWW::renderFile $f $title
    return
}

##
 # ==========================================================================
 # 
 # ×××× ---- ×××× #
 # 
 # ×××× Version History ×××× #
 # 
 #  modified   by  rev   reason
 #  ---------- --- ---   -----------
 #  1997-04-30 VMD 1.0   Original
 #  ????-??-?? ??? 1.1.x Various updates.
 #  2000-12-07 DWH 1.2.2 updated help text
 #  2001-09-05 cbu 1.3   Put all procs in the WWW namespace.
 #                       Added WWW::renderUrl, available with Alphatk/8
 #  2001-09-09 VMD 1.4   Added mode declaration, rather than 'addMode'
 #  2001-09-13 cbu 1.5   Major restructuring of how links are handled, by
 #                         saving them as Tcl array vars rather than by
 #                         attempting to extract info via 'getColors'.
 #                         See notes below in "# WWW proc archives".
 #                       Added 'bookmarks' menu, history, search engines.
 #                       Incorporated Dominique's suggestions for improved
 #                         [WWW::parseHtml] and [WWW::wrapInsertText].
 #  2001-09-13 cbu 1.6   Lots of fixes.
 #  2001-09-13 cbu 1.6.1 Lots of fixes.
 #  2001-09-13 cbu 1.6.2 Lots of fixes.
 #                       History window now treated more like regular WWW.
 #                       <PRE> is now working again, better than before.
 #  2001-10-03 cbu 1.7   Options to ignore forms, images added.
 #                       New 'WWW::findClosingTag', used in creating links.
 #                       Many more links supported, esp those with 'extra'
 #                         arguments embedded in the tag.  Links that have
 #                         nested style tags will link but ignore style.
 #                       Many more web pages can be rendered.
 #                       Reloading a page after a cache flush now works, by
 #                         re-fetching the page (using WWW::UrlSource).
 #                       Non-html pages are simply inserted, not rendered.
 #                       The original wwwMenu.tcl file became much too large.
 #                       Broke it into four smaller ones, for mode, menu,
 #                         parsing, links.  Plus a fifth for history :)
 #  2002-04-01 VMD 1.8-9 Various minor bug fixes, adapted to interact better
 #                         with editing Wiki pages.
 #  2002-05-10 cbu 2.0   Major update, improving parsing, adding support for
 #                         framesets, contextual menu.
 #                         
 # Changes include:
 # 
 # ==  wwwLinks.tcl  ==
 # 
 # ¥ It's now up to individual url handlers to decide if the links are handled
 #   internally or not, and to deal with any possible target anchors.
 # ¥ [WWW::link] now just figures out what the handler is and passes the url.
 # 
 # ==  wwwMenu.tcl  ==
 # 
 # ¥ Fix to the [WWW::reload] so that we don't delete local html files
 #   that are being viewed.
 # ¥ We now save the window's size parameters when appropriate, so that after
 #   the user resizes the windows subsequent windows will respect new size.
 # ¥ Improved support for 'linksOpenNewWindows', including frameset windows.
 #   
 # ==  wwwMode.tcl  ==
 # 
 # ¥ Removed 'mailtoLinksInternal' preference, now we simply use the global 
 #   pref for 'composeEmailUsing'.
 # ¥ Changed all WWW::UrlAction array names to represent regexps.
 # ¥ Added url handlers for image files (to send them to internet config)
 # ¥ Added contextual menu modules for 'bookmarks' and 'gotoPage' menus, plus
 #   new 'Www Links' and 'Www Window' contextual menus, and 'Page Forward/Back'
 #   items.  All of these are optional, but turned on by default.
 # ¥ New [WWW::httpAllowed] proc, to replace 'WWW::NoUrls' variable.  The goal
 #   here is to reduce the number of procedures that will have to be changed
 #   one Alpha8 can use the http package.  ([WWW::httpAllowed] should really be
 #   itself replaced by some [url::httpPackageAvailable] proc in the AlphaTcl
 #   core.)
 # ¥ WWW mode preferences for WWW window sizes can now be set, Tcl 8.0.
 #   
 # ==  wwwParsing.tcl  ==
 # 
 # ¥ Major performance boost achieved by caching all text and color/hyper info
 #   during parsing, and the inserting it all at the end.  Here's some stats
 #   comparing different versions for the amount of time it takes to render
 #   the first page of the "HTML Mode Manual" in my iBook, MacOS 9.2, where
 #   WWW version 2.0 is the one contained in this distribution:
 # 
 # Alpha*:  WWW (AlphaTcl):   Time to render:
 # -------  --- -----------   ---------------
 # 
 # Alpha7   1.2  (7.3)        12.7 seconds
 # Alpha7   1.7  (7.5)        14.3 seconds
 # Alpha7   2.0  (7.6d2)       8.9 seconds
 # 
 # Alpha8   1.2  (7.3)         3.9 seconds
 # Alpha8   1.7  (7.5)         4.8 seconds
 # Alpha8   2.0  (7.6d2)       1.1 seconds
 # 
 # Alphatk seems to render pages in about 45% of the previous time.  For
 # Alpha8 and Alphatk, there is an additional significant speed increase for
 # longer files brought about by splitting the code into manageable strings
 # that we manipulate in order.  (Performing complicated 'regexp' on strings
 # longer than 500 seems to start to dramatically slow things down. 
 # Interestingly, this doesn't seem to have any effect in Alpha7.)
 # 
 # ¥ Improved handling of image links.  If the image serves as a hyperlink
 #   and includes an 'alt' option, then we simply include the link as
 #   hypertext and the user never knows that it was supposed to be an image. 
 #   Other images show up as hyperlinks, clicking on them will send the source
 #   url to the Finder.
 # ¥ We now try to adjust the length of the 'fillColumn' when wrapping
 #   text, respecting the width of the newly created window.  This can be
 #   turned off with the WWW mode pref 'autoAdjustWidth'.
 # ¥ Better parsing of <DL> lists, and general improvements all around in
 #   parsing, wrapping text.
 # ¥ We know longer try to second guess the spacing of words when tags are
 #   present -- just use the spacing found in the file
 #   
 # ==  wwwRender.tcl  ==
 # 
 # ¥ Added this file, splitting off all of the code that is used for rendering
 #   as opposed to parsing.
 # ¥ We can finally deal with frameset windows, although currently only
 #   does side by side or top and bottom -- multiple frames aren't handled so
 #   very well, although all of the windows do get rendered.  Windows from one
 #   frame can be directed to open in a different window.
 #     
 # ==  wwwWindow.tcl  ==
 # 
 # ¥ Added this file, splitting off all of the code that is used for creating
 #   new WWW windows and storing window parameters.
 #   
 #  2002-05-24 cbu 2.1   More shuffling of some items to make "wwwParsing.tcl"
 #                         completely independent from the rest of AlphaTcl.
 #                         Put all of these procs in the 'html' namespace.
 #                       Better handling of frameset targets.
 #                       Better parsing when the segments break html code.
 #                       Better spacing, hopefully resolved the last of the
 #                         issues around 'smart' spacing so that we simply
 #                         do what the html code says.
 #                       Another speed improvement by only giving status bar
 #                         messages if the percentage actually changes,
 #                         reduces parsing time by approx 25 %.  (Unfortunately,
 #                         additional parsing improvements result in more
 #                         regexp's and slows it back to to 2.0 speeds.)
 #                       Supposedly [httpFetch] will work now for Alpha8 with
 #                         the newer version of MacTcl, so viewing remote
 #                         urls is enabled.
 #                       Added Option Titlebar Click support.
 #                       All of the parsing cache info is now saved so that
 #                         if a window is closed and then called to be
 #                         re-opened, we just read the text from the cached
 #                         file and re-render the colors/hyperlinks/marks.
 #                       [WWW::createNewWindow] now accepts geometry args.
 #                       [WWW::renderFrames] now determines window geometry
 #                         in advance, and passes that along.
 #                       All table rows in a single line, i.e. no wrapping.
 #                       Various fixes for bugs reported by Vince.
 #  2002-05-24 vmd 2.1.x Various minor fixes, esp for newer AlphaTcl
 #  2002-10-08 cbu 2.2   [WWW::getAttributes] now optionally ensures that
 #                         the array items are set to a null string.  Sometimes
 #                         empty values are valid, i.e. contain information
 #                         suggesting that a default value should be used.
 #                       Various parsing bugs fixed.
 #                       Table cells do NOT require closing tags, and if they
 #                         were absent then the parsing of tables usually
 #                         failed.  We only check to see if the text should be
 #                         wrapped or not, so this should never happen.
 #                       Preliminary code to support form dialogs.
 #                       New "wwwForms.tcl" file to contain form support.
 #                       New mode pref to determine how deep headers should
 #                         be marked.
 #                       Duplicate header names now have unique mark names.
 #                       Better navigation when current window is History.
 #                       New "wwwHistory.tcl" file with history window support.
 #                       Sending source file to browser if the current window
 #                         was fetched from a remote source now finds the url
 #                         and passes it to [url::execute] rather than sending
 #                         the address of the local copy.
 #  2002-10-13 cbu 2.3   Much different approach to handling forms.  Now we
 #                         cache all of the form input, render form fields,
 #                         and render any surrounding text normally.  Selecting
 #                         a form field hyperlink will open a dialog allowing
 #                         just that field to be edited.  Checkboxes and radio
 #                         buttons are rendered in the window and changed as
 #                         necessary.  Clicking on a 'Submit' button will
 #                         present a minimal dialog confirming what is contained
 #                         in the text/select fields, and then post/get the
 #                         form data as necessary.
 #  2002-10-15 cbu 2.3.1 New "wwwShell.tcl" file, which adds a shell window
 #                         named "Go To Url..." for typing in urls and
 #                         sending them to the rendering engine.
 #                       Alpha7 form links are now disabled.
 #                       More parsing, rendering improvements.
 #                       I think that I (finally) figured out a good solution
 #                         for the "Table cell with both <img> and <br>"
 #                         issue, to determine if we should have line breaks
 #                         or just spaces.
 #                       There was a bit of confusion about when to use the
 #                         WWW::BaseUrl versus the WWW::UrlSource array to
 #                         link titles, especially with creating unique titles.
 #                         I think that this is all cleared up -- this explains
 #                         some where history navigation weirdness came from.
 #                       When reloading previously seen windows, we now try
 #                         to scroll down to where we were before.
 #  2002-12-30 cbu 2.4   Removed use of [status::errorMsg] from entire package.
 #                       Removed use of [dialog::errorAlert] from entire package.
 #                       "View Url" menu item is now "View Url Or File"
 #                       All 'list' type vars are now in "wwwMenuVars" array,
 #                         true arrays are still in WWW namespace.
 #                       Default window geometry is no longer set after frameset
 #                         windows are viewed, navigated.  (There were several
 #                         issues here, related to creating new windows but
 #                         not knowing if they were called from links or not
 #                         (set the WWW::OpeningFromLink var now), and the
 #                         default window size was set inappropriately when
 #                         the current window was a 'target'.) Current behavior
 #                         is much better, more consistent.
 #                       "linksOpenNewWindows" pref is now only queried if
 #                         the new page is actually opened from a link.
 #                         Otherwise, we always create new windows.
 #                       The frameset dialog is now optional.
 #                       History limit preferences (time, length) in place.
 #                       History is used for initial list of visited links.
 #                       Deleting history no longer kills history window.
 #                       Individual history items can be deleted via new
 #                         hyperlinks, [WWW::deleteThisHistoryItem]
 #                       New binding preference to cycle all WWW windows.
 #                       Added Dominique's fixes for parsing.
 #                       Parsing of <H1> etc headers much better.
 #                       HTML windows that don't exist on disk can now be
 #                         rendered anyway, by treating them as fetched files.
 #                       Finally (hopefully) figured out why 'Go To' menu 
 #                         sometimes dropped ignored named pages.  Using
 #                         [lsearch -glob $pages [list * $title]] would find
 #                         close but not exact matches.  (And then reverted
 #                         back to original -- need to look into this more.)
 #  2003-01-07 VMD 2.4.1 Minor bug fixes, Alphatk compatibility.
 #  2003-01-07 cbu 2.4.2 Minor bug fixes, Alpha8 compatibility!
 #                       Minor history 'newDate' fix.
 #                       Re-opening previous rendered frameset windows
 #                         properly remembers window geometry.  (Another big
 #                         pain to debug, but code is now more robust.)
 #  2003-01-20 cbu 2.4.3 History bugs.  "History Days" preferences is now
 #                         disabled in Alpha7.  Still need to address how
 #                         Alpha8/tk handle [now].0 differently.
 #                       [WWW::refreshFrontWindow] now asks if you want to
 #                         refresh if prefs were changed via mode prefs dialog.
 #                         Otherwise it could be refreshed several times in
 #                         succession, which could be a long delay.
 #                       Various changes to make it clearer what code is
 #                         specific to Alpha7 vs httpAllowed.  Should make it
 #                         easier to clean up for AlphaTcl 8.0.
 #                       A few more bugs re window geometry, frameset windows
 #                         addressed, hopefully it all works now!
 # 2003-09-09 cbu 2.4.4  Minor bug fixes, code cleanup
 #                       Activate hook only called for WWW mode, not global.
 #                       Using the new AlphaTcl "changeModeFrom" hook.
 #                       Recognizing charset encoding in <meta ...> tags.
 #                         (Still needs work, esp in Alpha8/X.)
 # 2003-09-18 cbu 2.4.5  Minor html parsing "quoting" bug fix.
 #                       Titlebar hook to copy current source url.
 # 2005-01-31 cbu 2.5    Use [variable] for internal variable names.
 #                       New [WWW::getWindowMode] procedure.
 #                       New [WWW::requireWwwWindow] procedure.
 #                       Tcl formatting changes.
 #                       
 # ==========================================================================
 ##

##
 # ==========================================================================
 # 
 # ×××× To Do ×××× #
 # 
 # ¥ Remember relevant vars when window is saved, so that reopening it will
 #   allow for proper navigation, and not force rendering the 'original'
 #   local file.  This will not be easy.
 # ¥ Find some general solution for [now].0 issues.
 # ¥ When windows are reloaded, should make sure that variables related to
 #   older fetched files are unset.
 # 
 # ==========================================================================
 ## 

##
 # ==========================================================================
 # 
 # ×××× WWW proc archives ×××× #
 # 
 # Earlier version of the WWW menu used a different method for navigating
 # links within a document, by scanning the window for colors and then
 # performing a complicated series of regexps/subs to determine what
 # message should be displayed in the status bar window.  Alphatk tends to
 # complicate this method, and throws errors that I (cbu) can't trace.
 # 
 # The alternative method used above employs two principles:
 # 
 # -- all links are now made absolute before being embedded as hypertext
 # -- all link information is stored as a Tcl variable specific to the 
 #    window, and accessed as needed.
 # 
 # Hopefully, this exposes much of what is taking place and allows the
 # hypertexting/navigating/etc to be very OS independent.  One nice
 # by-product of this scheme is that it made the resolution of relative
 # urls a relative breeze.
 # 
 # One disadvantage that I've come across with the newer method is that if
 # a WWW window is saved and subsequently opened, it is not possible to
 # navigate the window using the arrow keys.  However, with the additional
 # 'bookmarks' and 'history' support, hopefully it won't be necessary to
 # actually save these WWW windows, since they can be easily rendered once
 # again using the WWW menu items.  Another disadvantage is that if there
 # are a large number of links in the window, navigating is a little slower
 # than one might expect due to the 'foreach' statement.
 # 
 # Anyway, since the earlier versions were pretty slick (at least for
 # Alpha7), I'm including them below.  To really see them in use, you'll
 # have to find an earlier version of this package, I'm afraid.
 # 
 # --------------------------------------------------------------------------
 # 
 # proc wwwUp {} {
 #     set link [wwwGetCurrentLink]
 #     _wwwHighlightLink [expr [lindex $link 1] -1]		
 # }
 # 
 # proc wwwDown {} {
 #     set link [wwwGetCurrentLink]
 #     _wwwHighlightLink [expr [lindex $link 0] +1]		
 # }
 # 
 # proc _wwwHighlightLink {l} {
 #     global _wwwLinks
 #     if {[set len [llength $_wwwLinks]] == 0} {return}
 #     if {$l < 0 || $l >= $len} {
 #         set l [expr ($l + $len) % $len]
 #         beep
 #     }
 #     set link [lindex $_wwwLinks $l]
 #     eval select $link
 #     set p [getPos]
 #     set q [selEnd]
 #     if {[info tclversion] >= 8.0} {
 #         regexp "\{ ?$p 15 \{wwwLink \"(\[^\"\]*)\"\} ?\}" [getColors] dmy link
 #     } else {
 #         regexp "\{ ?$p 15 \{wwwLink \"(\[^\"\]*)\"\} ?\} \{ ?$q 12 ?\}" [getColors] dmy link
 #     }
 #     status::msg "Links to '$link'"
 #     return $link
 # }
 # 
 # proc wwwHighlightLink {l} {
 #     global _wwwLinks
 #     set _wwwLinks [_wwwGetLinks]
 #     _wwwHighlightLink $l
 # }
 # 
 # proc wwwGetCurrentLink {} {
 #     global _wwwLinks
 #     set _wwwLinks [_wwwGetLinks]
 #     set p [getPos]
 #     set i 0
 #     while 1 {
 #         if {[set j [lindex [lindex $_wwwLinks $i] 0]] == ""} {
 #             return [list [expr {$i-2}] [expr {$i-1}]]
 #         }
 #         if {[pos::compare $p <= $j]} {
 #             if {[pos::compare $p == $j]} {
 #                 return [list $i $i]
 #             } else {
 #                 return [list [expr {$i-1}] $i]
 #             }
 #         }
 #         incr i
 #     }
 #     incr i -1
 #     return [list $i $i]
 # }
 # 
 # proc wwwCopyLinkLocation {} {
 #     alertnote "Unimplemented."
 # }
 # 
 # proc _wwwGetLinks {} {
 #     regsub -all {\{wwwLink "[^"]*"\} ?} [getColors] "" g
 #     # remove all non 12,15 items
 #     regsub -all {\{ ?[.0-9]+ ([0-9]|1[0134]) ?\} ?} $g "" g
 #     # remove superimposed links (caused by editing)
 #     regsub -all {(\{ ?[.0-9]+ 15 ?\} )+(\{ ?[.0-9]+ 15 ?\} ?)} $g {\2} g
 #     # convert 15-12 list pairs into single items
 #     regsub -all { ?([.0-9]+) 15 ?\} \{ ?([.0-9]+) 12 ?} $g {\1 \2} g
 #     # remove random left-overs items
 #     regsub -all {\{ ?[.0-9]+ 12 ?\} ?} $g "" g
 #     return $g
 # }
 # 
 # ==========================================================================
 ##
