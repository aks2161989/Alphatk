## -*-Tcl-*-
 # ==========================================================================
 # WWW Menu - an extension package for Alpha
 #
 # FILE: "wwwForms.tcl"
 #                                   created: 10/08/2002 {01:17:42 PM} 
 #                               last update: 03/21/2006 {01:53:18 PM} 
 # Description:
 #  
 # Procedures to deal with form dialogs.
 #  
 # See the "wwwVersionHistory.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the wwwMode.tcl file has been loaded.
wwwMode.tcl

proc wwwForms.tcl {} {}

namespace eval WWW  {}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Index Search ×××× #
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::indexSearch" --
 #  
 # Handle <isindex> tags.  Really very easy!  Currently, all args are ignored
 # so we're assuming that this is called while a WWW window is in front.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::indexSearch {args} {
    
    variable UrlSource
    
    if {![info exists UrlSource([win::Current])]} {
	status::msg "Unknown url source for index search."
	return -code return
    } else {
	set url $UrlSource([win::Current])
    }
    regsub {\?.*$} $url "" url

    if {![string length [set query [prompt "Search for" ""]]]} {
	status::msg "Cancelled."
	return -code return
    }
    status::msg "Querying server for '$query'..."
    regsub -all " +" $query "+" query
    WWW::link "${url}?$query"
    return
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Form Item Links ×××× #
# 

proc WWW::formLink {args} {

    variable Forms
    variable FormFieldUserValues
    
    WWW::setWindowVars
    
    # This is necessary because this proc might be called by a hyperlink, or
    # indirectly via "WWW::link" -- points out how "WWW::renderCacheInfo" is
    # kind of quirky ...  might need an 'eval' in "WWW::link" ...  or we
    # could just assume that the window name is the current window...
    if {([lindex [lindex $args 0] 0] eq "WWW::formLink")} {
	set args [lindex [lindex $args 0] 1]
    } else {
	set args [lindex $args 0]
    }
    set formNumber  [lindex $args 0]
    set fieldNumber [lindex $args 1]
    if {![info exists Forms($formNumber,$fieldNumber)]} {
	status::msg "Cannot find the information needed to build this form."
	return -code return
    }
    # Each item is a list containing "itemType typeAtts $pos0 $pos1 $args"
    set title      [win::Current]
    set fieldArgs  $Forms($formNumber,$fieldNumber)
    set itemType   [lindex $fieldArgs 0]
    set itemAtts   [lindex $fieldArgs 1]
    set itemArgs   [lindex $fieldArgs 4]
    # Set up an array with name, value entries.
    html::getAttributes $itemAtts itemArray 1 NAME VALUE ROWS
    # What to do with the item?
    switch -- $itemType {
	"BUTTON" - "SUBMIT" - "IMAGE" {
	    # BUTTON isn't widely supported, so there are few examples of
	    # this around, need to do some more tests to confirm that this
	    # works as expected.  Also need to check the 'IMAGE' type.
	    WWW::submitForm $formNumber $fieldNumber
	}
	"CHECKBOX" {
	    if {[info exists FormFieldUserValues($formNumber,$fieldNumber)]} {
	        set value $FormFieldUserValues($formNumber,$fieldNumber)
	    } elseif {[regexp -nocase "CHECKED" $itemAtts]} {
		set value 1
	    } else {
	        set value 0
	    }
	    set value   [expr {$value ? 0 : 1}]
	    set pos0    [lindex $fieldArgs 2]
	    set pos1    [lindex $fieldArgs 3]
	    set newText [lindex [list {[_]} {[X]}] $value]
	    set FormFieldUserValues($formNumber,$fieldNumber) $value
	    WWW::replaceWindowFormText $fieldNumber
	    refresh
	}
	"FILE" {
	    # Find a file.  Not sure if this needs to be url'd or not.
	    set value [getfile]
	    set FormFieldUserValues($formNumber,$fieldNumber) $value
	}
	"PASSWORD" {
	    set     d {dialog::make -title "Web Form Field" }
	    lappend d [list "" [WWW::passwordDialogItem "Enter password:"]]
	    set value [lindex [eval $d] 0]
	    set FormFieldUserValues($formNumber,$fieldNumber) $value
	}
	"RADIO" {
	    set name $itemArray(NAME)
	    # Collect all radio buttons that have this name.
	    set fieldCounter 0
	    while {[info exists Forms($formNumber,$fieldCounter)]} {
		set tmpArgs $Forms($formNumber,$fieldCounter)
		if {([lindex $tmpArgs 0] eq "RADIO")} {
		    html::getAttributes [lindex $tmpArgs 1] tmpArray 1 NAME VALUE
		    if {($tmpArray(NAME) eq $name)} {
		        # A match !!  Uncheck this if it isn't the current
		        # form field number.  (We do that last.)
			if {$fieldCounter != $fieldNumber} {
			    # This is the current form field number
			    set pos0 [lindex $tmpArgs 2]
			    set pos1 [lindex $tmpArgs 3]
			    set newText {(_)}
			    WWW::replaceWindowFormText $fieldCounter
			    set FormFieldUserValues($formNumber,$fieldCounter) 0
			}
		    }
		}
		incr fieldCounter
	    }
	    # Now set the current value.
	    set pos0    [lindex $fieldArgs 2]
	    set pos1    [lindex $fieldArgs 3]
	    set newText {(¥)}
	    set FormFieldUserValues($formNumber,$fieldNumber) 1
	    WWW::replaceWindowFormText $fieldNumber
	    refresh
	}
	"RESET" {
	    set fieldCounter 0
	    while {[info exists Forms($formNumber,$fieldCounter)]} {
		catch {unset FormFieldUserValues($formNumber,$fieldCounter)}
		set tmpArgs $Forms($formNumber,$fieldCounter)
		set tmpType [lindex $tmpArgs 0]
		if {($tmpType eq "RADIO")} {
		    set checkText [list {( )} {(¥)}]
		} elseif {($tmpType eq "CHECKBOX")} {
		    set checkText [list {[ ]} {[X]}]
		}
		if {[info exists checkText]} {
		    set pos0 [lindex $tmpArgs 2]
		    set pos1 [lindex $tmpArgs 3]
		    set chkd [regexp -nocase -- "CHECKED" [lindex $tmpArgs 1]]
		    set newText [lindex $checkText $chkd]
		    WWW::replaceWindowFormText $fieldCounter
		    unset checkText
		}
		incr fieldCounter
	    }
	    refresh
	    selectText [lindex $fieldArgs 2] [lindex $fieldArgs 3]
	    status::msg "All field values have been set to defaults."
	}
	"SELECT" {
	    # Get the list of available options.
	    if {![info exists WWW::FormFieldCache($formNumber,$fieldNumber)]} {
		WWW::getSelectOptions [lindex $itemArgs 0]
	    }
	    set ffc [set WWW::FormFieldCache($formNumber,$fieldNumber)]
	    # This is a list of optionLabels, optionValues, and defaultIndices.
	    set optionLabels   [lindex $ffc 0]
	    set optionValues   [lindex $ffc 1]
	    # Get the default labels.
	    if {[info exists FormFieldUserValues($formNumber,$fieldNumber)]} {
		set indices $FormFieldUserValues($formNumber,$fieldNumber)
	    } else {
		set indices [lindex $ffc 2]
	    }
	    foreach idx $indices {
		lappend L [lindex $optionLabels $idx]
	    }
	    if {![info exists L]} {
		set L [list [lindex $optionLabels 0]]
	    }
	    # Offer the dialog.
	    if {[regexp -nocase "MULTIPLE" $itemAtts]} {
		set p "Select one or more items:"
		set results [listpick -p $p -L $L -l $optionLabels]
	    } else {
	        set p "Select an item:"
		set results [list [listpick -p $p -L $L $optionLabels]]
	    }
	    foreach result $results {
		if {[set idx [lsearch $optionLabels $result]] >= 0} {
		    lappend values $idx
		}
	    }
	    if {[info exists values]} {
		set FormFieldUserValues($formNumber,$fieldNumber) $values
	    }
	}
	"TEXT" - "TEXTAREA" - "" {
	    set     d {dialog::make -title "Web Form Field" }
	    lappend d [list "" [WWW::textDialogItem "Enter text:"]]
	    set value [lindex [eval $d] 0]
	    set FormFieldUserValues($formNumber,$fieldNumber) $value
	}
    }
    return
}

proc WWW::replaceWindowFormText {fieldNumber} {

    global WWWmodeVars
    
    foreach item [list formNumber pos0 pos1 newText] {
	upvar $item $item
    }
    set title [win::Current]
    setWinInfo -w $title read-only 0
    replaceText $pos0 $pos1 $newText
    set cmd [list WWW::formLink [list $formNumber $fieldNumber]]
    text::color $pos0 $pos1 $WWWmodeVars(formsColor)
    text::hyper $pos0 $pos1 $cmd
    setWinInfo -w $title read-only 1
    selectText -w $title $pos0 $pos1
    return
}

proc WWW::getSelectOptions {selectOptionText} {
    
    variable FormFieldCache

    foreach item [list formNumber fieldNumber] {
	upvar $item $item
    }
    set optionLabels   [list]
    set optionValues   [list]
    set defaultIndices [list]
    # Now collect all of the options.  This is a variation of
    # "html::parseBody" ...  
    set t $selectOptionText
    # Everything within a "SELECT" next should be a set of options, but
    # closing option tags are not required.  We'll deal with that first.
    regsub -all -- "\[\r\n\t \]+" $t " " t
    regsub -all -nocase -- {< */OPTION *>[^<]*< *OPTION} $t {<OPTION} t
    regsub -all -nocase -- {< */OPTION *>}               $t {}        t
    set tagPattern "^(\[^<\]*(?:<\[<>\]\[^<\]*)*)<(\[^<>\]\[^>\]*)>(.*)\$"
    while {[regexp -- $tagPattern $t -> first html t]} {
	regsub -all {[][\$?^|*+()\.\{\}\\]} $html {\\&} qHtml
	switch -regexp -- [string toupper $qHtml] {
	    "^OPTION" {
		# Try to find the limit to the next option tag.
		if {[regexp -nocase -indices -- "<OPTION" $t match]} {
		    # Found it.
		    set pos1  [lindex $match 0]
		    set pos0  [expr {$pos1 - 1}]
		    set label [string range $t 0 $pos0]
		    set t     [string range $t $pos1 end]
		} else {
		    # Didn't find one.  Assume that the rest
		    # of the text is the option element.
		    set label $t
		    set t ""
		}
		html::getAttributes $html "optionArray" 0 VALUE
		# Set the value for this option.
		if {[info exists optionArray(VALUE)]} {
		    set value $optionArray(VALUE)
		} else {
		    set value $label
		}
		# Set the label for this option.
		if {![string length $label]} {
		    set label $value
		}
		if {![string length $label]} {
		    set label " "
		}
		set label [quote::Unhtml $label]
		regsub {^\-} $label " -" label
		# Is this a default item?
		if {[regexp -nocase -- "SELECTED" $html]} {
		    lappend defaultIndices [llength $optionValues]
		}
		# Now save the options.
		lappend optionValues $value
		lappend optionLabels $label
	    }
	    default {}
	}
    }
    if {![llength defaultIndices]} {
	lappend defaultIndices "0"
    }
    set results [list $optionLabels $optionValues $defaultIndices]
    set FormFieldCache($formNumber,$fieldNumber) $results
    return
}

# ×××× Dialog Support ×××× #

proc WWW::passwordDialogItem {{fieldLabel " "}} {
    
    variable FormFieldUserValues
    
    foreach item [list itemArray formNumber fieldNumber] {
	upvar $item $item
    }
    if {[info exists FormFieldUserValues($formNumber,$fieldNumber)]} {
	set value $FormFieldUserValues($formNumber,$fieldNumber)
    } else {
	set value [string trim [quote::Unhtml $itemArray(VALUE)]]
    }
    return [list password $fieldLabel $value]
}

proc WWW::textDialogItem {{fieldLabel " "}} {
    
    global dialog::simple_type alpha::platform alpha::application

    variable FormFieldUserValues
    variable Forms
    
    foreach item [list itemArray formNumber fieldNumber] {
	upvar $item $item
    }
    set rows $itemArray(ROWS)
    if {![string length $rows]} {
	set rows 1
    } elseif {![is::PositiveInteger $rows]} {
	set rows 5
    } else {
	set rows [expr {$rows > 20 ? 20 : $rows}]
    }
    if {![info exists dialog::simple_type(var$rows)]} {
	set dialog::simple_type(var$rows) \
	  "dialog::makeEditItem res script \$left \$right y \$name \$val $rows"
    }
    if {[info exists FormFieldUserValues($formNumber,$fieldNumber)]} {
	set value $FormFieldUserValues($formNumber,$fieldNumber)
    } elseif {[info exists Forms($formNumber,$fieldNumber)]} {
	set value [lindex $Forms($formNumber,$fieldNumber) end 0]
    } else {
	set value [string trim [quote::Unhtml $itemArray(VALUE)]]
    }
    if {(${alpha::platform} eq "alpha") && ([string length $value] > 255)} {
	# Bug# 638: 'getLine' and var prefs dialogs can't handle strings > 255
	set msg "Sorry, but you have run into a core ALPHA bug\
	  that truncates dialog text-edit field values to 256 characters.\
	  \rThis is a known issue that is being worked on.  Unfortunately,\
	  this form cannot be processed by ALPHA."
	regsub -all -- {ALPHA} $msg ${alpha::application} msg
	dialog::alert $msg
	error "Form submission cancelled."
    }
    return [list var$rows $fieldLabel $value]
}

# Even though the individual form fields appear in the rendered window as
# separate hyperlinks, it is a little disconcerting to simply submit a
# form without seeing the actual values in the fields.  The 'radio' and
# 'checkbox' fields are readily apparent, so we'll give the user one last
# chance to review the other information before we submit.  Once you get
# used to this, you can simply scan the window for the fields that need
# to be entered, and hit the 'Submit' button to actually change the
# fields values.

proc WWW::submitDialog {formNumber fieldNumber} {
    
    variable FormFieldCache
    variable FormFieldUserValues
    variable Forms
    
    set submitFieldNumber $fieldNumber
    set d1 {dialog::make -title "Web Form Field" }
    set d2 [list ""]
    set dummyLabel " "
    set fieldNumber 0
    while {[info exists Forms($formNumber,$fieldNumber)]} {
	set tmpArgs $Forms($formNumber,$fieldNumber)
	set itemAtts [lindex $tmpArgs 1]
	# Set up an array with name, value entries.
	html::getAttributes $itemAtts itemArray 1 NAME VALUE ROWS
	set TYPE [string toupper [lindex $tmpArgs 0]]
	switch -- $TYPE {
	    "PASSWORD" {
		set fieldLabel "password:$dummyLabel"
		lappend d2 [WWW::passwordDialogItem $fieldLabel]
		append dummyLabel " "
		lappend fieldsToModify [list $fieldNumber $TYPE]
	    }
	    "SELECT" {
		# Get the list of available options.
		if {![info exists FormFieldCache($formNumber,$fieldNumber)]} {
		    WWW::getSelectOptions [lindex [lindex $tmpArgs 4] 0]
		}
		set ffc $FormFieldCache($formNumber,$fieldNumber)
		# This is a list of optionLabels, optionValues, and defaultIndices.
		set optionLabels   [lindex $ffc 0]
		set optionValues   [lindex $ffc 1]
		# Get the default labels.
		if {[info exists FormFieldUserValues($formNumber,$fieldNumber)]} {
		    set indices $FormFieldUserValues($formNumber,$fieldNumber)
		} else {
		    set indices [lindex $ffc 2]
		}
		if {![llength $indices]} {
		    set indices [list "0"]
		}
		# I am ignoring 'MULTIPLE' option for SELECT fields for now.
		set L [lindex $indices 0]
		set fieldLabel "option:$dummyLabel"
		lappend d2 [list [list menuindex $optionLabels] $fieldLabel $L]
		append dummyLabel " "
		lappend fieldsToModify [list $fieldNumber $TYPE]
	    }
	    "TEXT" - "TEXTAREA" - "" {
		set fieldLabel "text:$dummyLabel"
		lappend d2 [WWW::textDialogItem $fieldLabel]
		append dummyLabel " "
		lappend fieldsToModify [list $fieldNumber $TYPE]
	    }
	}
	lappend d2 [list [list discretionary 325 "(Additional information\
	  can be found in the next pane.)"] dummy$fieldNumber]
	incr fieldNumber
    }
    # Now add the button name.
    set buttonArgs $Forms($formNumber,$submitFieldNumber)
    set buttonAtts [lindex $buttonArgs 1]
    # Set up an array with name, value entries.
    html::getAttributes $buttonAtts itemArray 1 BUTTON
    if {[string length $itemArray(BUTTON)]} {
        append d1 "-ok \"$itemArray(BUTTON)\""
    } else {
        append d1 "-ok Submit"
    }
    # Now present the dialog, and save any new values.
    lappend d1 $d2
    set count 0
    foreach result [eval $d1] {
	set ftm [lindex $fieldsToModify $count]
	set fn  [lindex $ftm 0]
	switch -- [lindex $ftm 1] {
	    "SELECT" {
		set result [list $result]
		set FormFieldUserValues($formNumber,$fn) $result
	    }
	    default {
		set FormFieldUserValues($formNumber,$fn) $result
	    }
	}
	incr count
    }
    return
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Submitting Forms ×××× #
# 
# From <http://htmlhelp.com/reference/html40/forms/form.html>:
# 
# How the form input is sent to the server depends on the METHOD and ENCTYPE
# attributes.  When the METHOD is get (the default), the form input is
# submitted as an HTTP GET request with ?form_data appended to the URI
# specified in the ACTION attribute.
# 
# With a METHOD value of post, the form input is submitted as an HTTP POST
# request with the form data sent in the body of the request.  Most current
# browsers are unable to bookmark POST requests, but POST does not entail the
# character encoding and length restrictions imposed by GET.
# 
# The ENCTYPE attribute specifies the content type used in submitting the
# form, and defaults to application/x-www-form-urlencoded.  This content type
# results in name/value pairs sent to the server as
# name1=value1&name2=value2...  with space characters replaced by "+" and
# reserved characters (like "#") replaced by "%HH" where HH is the ASCII code
# of the character in hexadecimal.  Line breaks are encoded as "%0D%0A"--a
# carriage return followed by a line feed.
# 

proc WWW::submitForm {formNumber fieldNumber} {
    
    global wwwMenuVars
    
    variable BaseUrl
    variable FormFieldCache
    variable FormFieldUserValues
    variable Forms
    variable UrlSource
    
    # We'll give the user one last chance to review the other information
    # before we submit.
    WWW::submitDialog $formNumber $fieldNumber
    # Now get the form action and method
    set formAtts [lindex $Forms($formNumber,0) 1]
    html::getAttributes $formAtts formArray 1 NAME METHOD ACTION
    set formAction $formArray(ACTION)
    switch -- [string toupper $formArray(METHOD)] {
	"GET" - "" {set formMethod "get" ; append formAction "?"}
	"POST"     {set formMethod "post"}
	default {
	    alertnote "Sorry, forms with '$formArray(METHOD)'\
	      methods cannot be handled yet."
	    return -code return
	}
    }
    # Create a list of name / value pairs for the query list.
    # (Each 'pair' is added as an individual list entry.)
    set queryList [list]
    set fieldCounter 0
    while {[info exists Forms($formNumber,$fieldCounter)]} {
	set tmpArgs  $Forms($formNumber,$fieldCounter)
	set tmpAtts  [lindex $tmpArgs 1]
	set TYPE     [string toupper [lindex $tmpArgs 0]]
	# Set up an array with name, value entries.
	html::getAttributes $tmpAtts itemArray 1 NAME VALUE
	set name $itemArray(NAME)
	if {[info exists FormFieldUserValues($formNumber,$fieldCounter)]} {
	    set userValue $FormFieldUserValues($formNumber,$fieldCounter)
	} elseif {[info exists userValue]} {
	    unset userValue
	}
	switch -- $TYPE {
	    "BUTTON" - "SUBMIT" - "IMAGE" {}
	    "CHECKBOX" {
		if {[info exists userValue]} {
		    set onOrOff $userValue
		} elseif {[regexp -nocase "CHECKED" $tmpAtts]} {
		    set onOrOff 1
		} else {
		    set onOrOff 0
		}
		if {$onOrOff} {
		    lappend queryList $name 1
		}
	    }
	    "FILE" {
		# As a security precaution, we only send a file if the user
		# has actually seleted one -- never rely on the default.
		if {[info exists userValue]} {
		    lappend queryList $name $userValue
		}
	    }
	    "RADIO" {
		if {[info exists userValue]} {
		    set onOrOff $userValue
		} elseif {[regexp -nocase "CHECKED" $tmpAtts]} {
		    set onOrOff 1
		} else {
		    set onOrOff 0
		}
		if {$onOrOff} {
		    lappend queryList $name $itemArray(VALUE)
		}
	    }
	    "RESET" {}
	    "SELECT" {
		# Get the list of available options.
		if {![info exists FormFieldCache($formNumber,$fieldCounter)]} {
		    WWW::getSelectOptions $itemArgs
		}
		set ffc $FormFieldCache($formNumber,$fieldCounter)
		# Get the default labels.
		if {[info exists userValue]} {
		    set indices $userValue
		} else {
		    set indices [lindex $ffc 2]
		}
		foreach idx $indices {
		    lappend queryList $name [lindex [lindex $ffc 1] $idx]
		}
	    }
	    default {
		if {[info exists userValue]} {
		    set value $userValue
		} else {
		    set value $itemArray(VALUE)
		}
		lappend queryList $name $value
	    }
	}
	incr fieldCounter
    }
    # We add this button's name and value last.
    set submitArgs $Forms($formNumber,$fieldNumber)
    html::getAttributes [lindex $submitArgs 1] itemArray 1 NAME VALUE
    lappend queryList $itemArray(NAME) $itemArray(VALUE)
    set query [eval ::http::formatQuery $queryList]
    # Now do something with all the info we've labored to collect.
    switch -- $formMethod {
	"get"   {
	    set submitInfo ${formAction}${query}
	    set baseUrl $BaseUrl([win::Current])
	    if {[catch {url::makeAbsolute $baseUrl $submitInfo} newUrl]} {
		alertnote $newUrl
		error "Cancelled"
	    }
	    WWW::forcingUniqueTitle 1
	    WWW::openingFromLink    1
	    WWW::renderRemote $newUrl
	}
	"post"  {
	    set baseUrl $BaseUrl([win::Current])
	    if {[catch {url::makeAbsolute $baseUrl $formAction} newUrl]} {
		alertnote $newUrl
		error "Cancelled"
	    }
	    status::msg "Posting form information to $baseUrl ..."
	    watchCursor
	    # This will actually return the contents of the new web page
	    # i.e. some html source code.
	    set http [::http::geturl $newUrl -query $query]
	    set html [::http::data $http]
	    # Cleanup
	    ::http::cleanup $http
	    status::msg "Posting the new version ... done"
	    # Now we need to render this code.
	    set fileName "[format %08d [incr wwwMenuVars(fetchNumber)]].html"
	    set newFile [file join [temp::directory WWW-fetch] $fileName]
	    set UrlSource([file nativename $newFile]) $baseUrl
	    if {[catch {alphaOpen $newFile "w+"} fid]} {
		alertnote $fid
		error "Cancelled"
	    }
	    puts -nonewline $fid $html
	    close $fid
	    # Posting forms multiple times will generally result in the same
	    # page title, same url being used, so while the new page will be
	    # properly fetched the calling page will be the one brought to
	    # the front.  Unless we force a unique title...
	    WWW::forcingUniqueTitle 1
	    WWW::openingFromLink    1
	    WWW::renderLocal $newFile
	}
    }
    return
}

# ===========================================================================
# 
# .