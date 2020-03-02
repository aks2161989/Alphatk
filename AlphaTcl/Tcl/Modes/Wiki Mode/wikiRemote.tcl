## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "wikiRemote.tcl"
 #                                          created: 01/27/2006 {11:20:42 AM}
 #                                      last update: 04/27/2006 {09:14:44 PM}
 # Description:
 # 
 # Enables the editing and posting of wiki pages from Alpha.
 # 
 # See the "wikiMode.tcl" file for author, license information.
 # 
 # ==========================================================================
 ##

proc wikiRemote.tcl {} {}

namespace eval Wiki {}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Editing Wiki Pages ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::editFromUrl" --
 # 
 # Given a url, determine the system associated with it and pass these on to
 # [Wiki::fetchAndEdit].  At present any "args" arguments are ignored, but
 # they might have been passed on by the caller.

 # --------------------------------------------------------------------------
 ##

proc Wiki::editFromUrl {url args} {
    
    # Is this a redirected url?
    set url [Wiki::getRedirectUrl $url]
    if {[catch {Wiki::buildEditPageUrl $url} editingUrl]} {
	# We could not build an edit url.
	dialog::errorAlert $editingUrl
    } elseif {[catch {Wiki::fetchAndEdit $editingUrl} result]} {
	dialog::errorAlert "Cancelled:\r\r$result"
    } else {
	Wiki::currentProject
	status::msg "Current project: \"$project\" ; [lindex $result 1]"
	return [lindex $result 0]
    }

    eval Wiki::fetchAndEdit $to $args
    return [Wiki::fetchAndEdit $url]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::fetchAndEdit" --
 # 
 # Given a url, fetch the contents and insert them in a new window.
 # 
 # Our primary task here is to parse the fetched .html file to determine the
 # <form> and <input> arguments so that these can be used to post the new
 # content back to the server.  We save all of this information in a new
 # "Wiki::$url" array.  A new "editWindows" array entry for the newly created
 # window name contains the original (after resolving redirection) url.
 # 
 # Returns a two-item list with the name of the window that was created and 
 # the (possibly new if discovered via redirection) url that created it.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::fetchAndEdit {url} {
    
    variable editWindows
    variable postWindows
    
    temp::directory wikiTmp
    
    Wiki::httpAvailable 1
    
    set contents [url::contents $url]
    # Write the contents to a temp file
    set name [temp::unique wikiTmp fetched ".html"]
    file::writeAll $name $contents 1
    
    set title [url::extractTag $contents title]
    set title [string trim $title " \n\r\t"]
    if {($title eq "")} {
	# Create a temporary title.
	set title "Edit_WikiPage"
    }
    # What if there are several <form> tags in the file ?  We want the one
    # with action and method attributes.
    set pattern {<form\s([^>]*)>(.*)$}
    set formAttributes [list "action" "method" "id" "enctype" "name"]
    while {1} {
	if {![regexp -nocase -- $pattern $contents -> form theRest]} {
	    # We have trouble...
	    break
	}
	eval [list Wiki::getAttributes $form formArray 0] $formAttributes
	if {[info exists formArray(method)] && \
	  ([string tolower $formArray(method)] eq "post")} {
	    # We now know (at least hope) that we have the correct "<form>"
	    break
	}
	set contents $theRest
    }
    # If there is no 'form' tag, we certainly have a problem.
    if {![info exists form] || ![info exists formArray]} {
	alertnote "No <form> tag was found. Will be unable to save to web."
	set form ""
    }
    # Store all form attributes/values.
    foreach attribute [array names formArray] {
	array set ::Wiki::$url [list $attribute $formArray($attribute)]
    }
    if {[catch {url::extractTag $contents textarea attributes} textarea]} {
	set msg "This '$title' page does not seem to be an edited Wiki page."
	if {[regexp -nocase "regist" $title]} {
	    append msg " Some wikis require that you be registered\
	      to edit a page."
	}
	append msg "\r\rSorry, editing this wiki page must be aborted."
	alertnote $msg
	error "Cancelled."
    }
    # Figure out what formvar we're supposed to pass the contents back as.
    Wiki::getAttributes $attributes textArray 0 "name"
    if {![info exists textArray(name)]} {
	return -code error "Cancelled -- Couldn't figure out the name\
	  of the <textarea>."
    }
    array set ::Wiki::$url [list "textarea" $textArray(name)]
    # Need to remove all html formatting (e.g. &quot;) from 'textarea'
    set editText [quote::Unhtml $textarea]
    # Find and propagate all hidden form variables/defaults.
    set pattern {<input\s([^>]*)>(.*)$}
    set count 0
    while {1} {
	incr count
	if {![regexp -nocase -- $pattern $contents -> input theRest]} {
	    break
	}
	Wiki::getAttributes $input inputArray 1 type name value
	set type  $inputArray(type)
	set name  $inputArray(name)
	set value $inputArray(value)
	if {($name eq "action") && ($value eq "cancel")} {
	    continue
	}
	array set ::Wiki::$url [list "input,$count" [list $type $name $value]]
	set contents $theRest
    }
    # Eliminate all slashes and colons which might be interpreted as filename
    # separators then shorten to 31 chars max.
    regsub -all "\[/: -\]+" $title "_" title
    if {([string length $title] > 30)} {
	set title "[string range $title 0 13]É[string range $title end-13 end]"
    }
    set name [temp::path wikiTmp $title]
    if {[win::Exists $name]} {
	status::msg "Editing conflictÉ (with yourself!)"
	set q "You already have an editing window open for this\
	  particular wiki page.\r\rDo you want to replace its contents?"
	if {[dialog::yesno -y "Replace" -n "Cancel" $q]} {
	    win::setInfo $name dirty 0
	    killWindow -w $name
	} else {
	    error "Cancelled."
	}
    }
    # Write the contents to a temp file and then open it for editing.
    file::writeAll $name $editText 1
    set name [edit -w -mode Wiki $name]
    set editWindows($name) $url
    set postWindows($name) [expr {($form ne "") ? 1 : 0}]
    # Unfortunately, this always get called too soon, before we have set 
    # all of the necessary information using the correct window name.
    Wiki::activateHook $name
    return [list $name $url]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Posting Wiki Pages ×××× #
# 
# We have a basic [Wiki::postToServer] procedure here that should handle most
# standard wikis.  Any other "wikiSystem" can define a special routine.  In
# any case, the current "project" is always passed to the command from
# [Wiki::postSavedWindow], along with the posting url, and the arguments
# potentially used to format the query.  Note that the text of the newly
# saved editing page is always the second item in the list.
# 
# Wiki-specific posting methods are defined in "wikiMethods.tcl"; users can
# also add new ones in a "WikiPrefs.tcl" file.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::postWindowText" --
 # 
 # Grab the contents of the given window, and attempt to post it back to the
 # wiki server.  Once we have received our results, attempt to parse them to
 # figure out how we should refresh the original window (either the one
 # created by the WWW Menu or in the user's browser.)  If we can't parse this
 # information, we offer to display it.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::postWindowText {name} {
    
    global WikimodeVars alpha::platform alpha::application
    
    variable closeWindowWarning
    variable editWindows
    variable lastPostedText
    variable postWindows
    
    Wiki::httpAvailable 1
    
    # Hopefully we won't need these!
    set cantPostQuestion "This window cannot be posted to the web server.  "
    set shouldntPostQuestion "While $alpha::application can attempt to post\
      this window to the web server, this is not recommended.  "
    set postOption "You can, however, open the Wiki page editing url in your\
      browser and paste the window contents into the appropriate form field."
    foreach question [list "cantPostQuestion" "shouldntPostQuestion"] {
	append $question $postOption
    }
    # Save the text of the current window to be reviewed later.
    set windowText [string trim \
      [getText -w $name [minPos -w $name] [maxPos -w $name]]]
    if {![string length $windowText]} {
        dialog::errorAlert "Cancelled -- The current window is empty!"
    } elseif {![info exists editWindows($name)]} {
	dialog::errorAlert "Cancelled -- Could not identify the url source\
	  of \"$name\""
    } elseif {![info exists postWindows($name)] || !$postWindows($name)} {
	if {[dialog::yesno $cantPostQuestion]} {
	    Wiki::saveInBrowser
	    return
	} else {
	    error "Cancelled -- cannot post this page to the web server."
	}
    }
    # Gather information
    set url $editWindows($name)
    upvar \#0 ::Wiki::$url attributes
    # Determine the proper posting method and the window's Project name.
    set system  [Wiki::getPostWikiSystem $name $url]
    set project [Wiki::findWindowProject $name]
    # Another check to see if posting is allowed/recommended.
    set postIsEnabled [Wiki::systemField $system "postIsEnabled" "1"]
    if {($postIsEnabled != "1")} {
	set y "Save In Browser"
	set n "Try To Post"
	switch -- $postIsEnabled {
	    "0" {
		if {[dialog::yesno -y $y -n "Cancel" $cantPostQuestion]} {
		    Wiki::saveInBrowser
		    return
		} else {
		    error "Cancelled -- cannot post this page to the web server."
		}
	    }
	    "2" {
		if {[dialog::yesno -y $y -n $n -c $shouldntPostQuestion]} {
		    Wiki::saveInBrowser
		    return
		}
	    }
	}
    }
    # Create our target url for posting.
    if {[info exists attributes(action)]} {
	set postToUrl [url::makeAbsolute $url $attributes(action)]
    } else {
	alertnote "Sorry, no action was specified in the web form.\
	  \rThe changes cannot be posted to the web."
	return
    }
    # Create our "query" argument for posting.
    if {($alpha::platform eq "alpha")} {
	regsub -all "\r?\n" $windowText "\n" windowText
	regsub -all "\r"    $windowText "\n" windowText
    }
    # Post the changes to the wiki.  If our "wikiSystem" has a special
    # posting routine we use that preferentially.
    append systemPostingProc "::Wiki::" $system "::postToServer"
    if {($system ne "") && [llength [info procs $systemPostingProc]]} {
	set cmd $systemPostingProc
    } else {
	set cmd ::Wiki::postToServer
    }
    set queryList [list $attributes(textarea) [list $windowText]]
    foreach attribute [array names attributes "input,*"] {
	lappend queryList $attribute $attributes($attribute)
    }
    # Post the new page back to the Wiki.  This will return a "token" that
    # can be used with other http commands.  We'll use this to let the user
    # know what happened.
    watchCursor
    status::msg "Posting the new version to <${postToUrl}> É"
    set token [$cmd $project $postToUrl $queryList]
    # Make sure that we didn't have an error.
    if {([set errorMsg [::http::error $token]] ne "")} {
	::http::cleanup $token
        dialog::errorAlert "Cancelled:\r\r$errorMsg"
    } elseif {([::http::status $token] eq "timeout")} {
	::http::cleanup $token
        error "Cancelled -- server timed out."
    }
    set lastPostedText $windowText
    status::msg "Posting the new version É done"
    # We'll assume that everything went according to plan.  Now we want to
    # find out what web page should be updated.  This should be in a <meta>
    # tag in the body returned by [::http::data].  We'll have to verify that
    # we've found the right one.
    set htmlBody [http::data $token]
    set contents $htmlBody
    set pattern  {<meta ([^>]*)>(.*)$}
    while {1} {
	if {![regexp -nocase -- $pattern $contents -> meta theRest]} {
	    # We have trouble...
	    break
	}
	Wiki::getAttributes $meta attributes 1 "http-equiv" "content"
	if {([string tolower $attributes(http-equiv)] eq "refresh")} {
	    # We now know that we have the correct "<meta...>".
	    set refreshArgs $attributes(content)
	    break
	} else {
	    set contents $theRest
	}
    }
    if {[info exists refreshArgs]} {
	# Getting closer...
	foreach item [split $refreshArgs ";"] {
	    Wiki::getAttributes $item attributes 1 "url"
	    if {($attributes(url) ne "")} {
	        set url $attributes(url)
		break
	    }
	}
    }
    if {[info exists url]} {
	set url [url::makeAbsolute $postToUrl $url]
        if {![::WWW::webPageHasChanged $url]} {
            Wiki::viewUrl $url
        }
	if {$WikimodeVars(closeWindowAfterPosting)} {
	    killWindow -w $name
	} elseif {![info exists closeWindowWarning]} {
	    set txt1 "If the wiki page was successfully uploaded, you should\
	      now close the editing window.  Many wikis set editing session\
	      ids which are only valid for one save.\r"
	    set txt2 "You can always review the last text of the edited wiki\
	      page by selecting the \"Wiki Menu > Review Last Post\" command.\r"
	    set dialogScript [list dialog::make \
	      -title "Wiki Window Post Warning" \
	      -width 400 \
	      -cancel "" \
	      [list "" \
	      [list "text" $txt1] [list "text" $txt2] \
	      [list "flag" "Always close windows after posting" 0] \
	      ]]
	    if {[lindex [eval $dialogScript] 0]} {
	        set WikimodeVars(closeWindowAfterPosting) 1
		prefs::modified WikimodeVars(closeWindowAfterPosting)
		killWindow -w $name
	    }
	    set closeWindowWarning 1
	}
	::http::cleanup $token
	return
    }
    # Still here?  Let the user know that we're not sure what happened, and
    # offer to render the "htmlBody" information in a new window.
    if {($htmlBody eq "")} {
	set q "Warning!\rThe Wiki page might not be updatedÉ\
	  You may need to reload the original page 'manually.'"
	alertnote $q
	::http::cleanup $token
	return
    }
    set q "Warning"
    if {![catch {url::extractTag $htmlBody title} title]} {
        append q ": " [string trim $title] "\r\r"
    } else {
        append q "! "
    }
    append q "The Wiki page might not be updated, and\
      you may need to reload the original page 'manually.'"
    set y "View Results"
    set n "Cancel"
    if {[dialog::yesno -n $n -y $y $q]} {
	if {![regexp -nocase {<(BASE[^>]+)>} $htmlBody -> baseString] \
	  && [regexp -nocase -- {^(http://[^/]+/)} $postToUrl -> baseUrl]} {
	    set substitute "<HEAD><BASE HREF=\"${baseUrl}\">"
	    if {![regsub -nocase -- {<HEAD>} $htmlBody $substitute htmlBody]} {
		set htmlBody ${substitute}${htmlBody}
	    }
	}
	temp::directory wikiTmp
	set name [temp::unique wikiTmp "results" ".html"]
	file::writeAll $name $htmlBody 1
	url::execute [file::toUrl $name]
    }
    ::http::cleanup $token
    return
}

##
 # --------------------------------------------------------------------------
 #       
 # "Wiki::postToServer" --
 #      
 # Post the new page back to the Wiki.  Tcl makes this incredibly simple!
 # Thanks to the Tcler's Wiki for appropriate code snippets to help.  Note
 # that the "pageData" is the second item in the "queryList" argument, and
 # that each <input> attribute is followed by a three-item list containing 
 # the input's "type" "name" and "value"
 # where the last item is always the value and the first might be a "type".
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::postToServer {project postToUrl queryList} {
    
    set newQueryList [list]
    foreach {field fieldList} $queryList {
	if {![regexp -- {^input,} $field]} {
	    lappend newQueryList $field [lindex $fieldList end]
	} elseif {([lindex $fieldList 1] ne "")} {
	    lappend newQueryList [lindex $fieldList 1] [lindex $fieldList 2]
	}
    }
    set queryArg [eval ::http::formatQuery $newQueryList]
    set cmdArgs  [list $postToUrl -query $queryArg -timeout -30000]
    if {[catch {eval ::http::geturl $cmdArgs} token]} {
	dialog::errorAlert "Cancelled (error):\r\r$token"
    }
    return $token
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Utilities ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::unsetWindowInfo" --
 # 
 # Remove arrays and variables created for a window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::unsetWindowInfo {name} {
    
    variable editWindows
    
    if {[info exists editWindows($name)]} {
	set url $editWindows($name)
	unset -nocomplain editWindows($name) ::Wiki::$url
    }
    if {[file::pathStartsWith $name [temp::directory wikiTmp]]} {
        catch {file delete $name}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::getAttributes" --
 # 
 # This is an extremely handy procedure that will extract attributes for an 
 # html tag.  "openTagString" is the string potentially containing the 
 # attribute information we need, and "arrayName" is the name of an array 
 # that will be created in the level of the calling code.  "ensureset" will 
 # set all of the "args" items in this array to "", otherwise the entries 
 # won't exist unless they are found.
 # 
 # Based on [html::getAttributes].
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::getAttributes {openTagString arrayName ensureSet args} {

    upvar $arrayName attArray
    
    unset -nocomplain attArray
    if {$ensureSet} {
	foreach arg $args {
	    set attArray($arg) ""
	}
    }
    foreach arg $args {
	set pat1 {\s*=\s*\"([^\"]*)\"}
	set pat2 {\s*=\s*'([^']*)'}
	set pat3 {\s*=\s*([^\s]+)\s*}
	if {[regexp -nocase ${arg}${pat1} $openTagString allofit value]} {
	    set attArray($arg) [string trim $value]
	} elseif {[regexp -nocase ${arg}${pat2} $openTagString allofit value]} {
	    set attArray($arg) [string trim $value]
	} elseif {[regexp -nocase ${arg}${pat3} $openTagString allofit value]} {
	    set attArray($arg) $value
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::getRedirectUrl" --
 # 
 # Given a url, attempt to determine if it is redirected somewhere else.
 # Because a redirected url might itself be redirected, we continue to follow
 # them until our "recursions" limit is reached.  (We don't want to get
 # trapped in a recursive loop if the url redirects to itself somehow.)
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::getRedirectUrl {url {recursions 10}} {
    
    Wiki::httpAvailable 1
    
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
# .