## -*-Tcl-*- (nowrap)
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "dialogs.tcl"
 #                                    created: 01-10-03 19.48.52 
 #                                last update: 04/18/2006 {05:01:39 PM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Much copyright (c) 1997-2006  Vince Darley
 # rest Pete Keleher, Johan Linde.
 # 
 # Reorganisation carried out by Vince Darley with much help from Tom
 # Fetherston, Johan Linde and suggestions from the alphatcl-developers
 # mailing list.  Alpha is shareware; please register with the author
 # using the register button in the about box.
 #  
 #  Description: 
 # 
 # Flexible dialogs for querying the user about flags and vars.  These
 # may be global, mode-dependent, or package-dependent.
 # 
 # Things you may wish to do:
 # 
 #  dialog::pkg_options Pkg
 #  dialog::modifyModeFlags ?mode?
 #  dialog::edit_array <arrayName> ?title?
 #  
 # creates a dialog for all array entries 'PkgmodeVars'.  These
 # must have been previously declared using 'newPref'.  These
 # variables are _not_ copied into the global scope; only
 # existing as array entries.
 # 
 # Use the procedure 'newPref' to declare preferences.  See its comments
 # for details.  It has optional arguments which allow you to declare:
 # lists, indexed lists, folders, files, bindings, menu-bindings,
 # applications, variable-list elements, array elements, all of which
 # can be set using the same central mode/global dialogs.  Note that
 # rather than setting up traces on variables, you are often better off
 # using the optional proc argument to newPref; the name of a procedure
 # to call if that element is changed by the user.
 # 
 # Most modes will just want to declare their vars using newPref.  
 # There is usually no need to do _anything_ else.
 # 
 # ---
 # 
 # The prefs dialog procs below were based upon Pete Keleher's 
 # originals.  Almost all of these have now been discarded in
 # favour of versions using dialog::make(_paged)?
 # ###################################################################
 ##

proc dialogs.tcl {} {}

namespace eval dialog {}

if {($::alpha::macos == 2)} {
    proc dialog::charsToFit {w} { expr {int($w/7.5)} }
} else {
    proc dialog::charsToFit {w} { expr {int($w/6.7)} }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "dialog::coreVersion" --
 # 
 # Used to determine if the new dialogs code is available in the core.
 # 
 # --------------------------------------------------------------------------
 ##

proc dialog::coreVersion {} {

    global alpha::macos alpha::platform alpha::version

    variable coreDialogVersion

    if {![info exists coreDialogVersion]} {
	if {($alpha::macos == 1)} {
	    set coreDialogVersion 1.0
	} elseif {($::alpha::platform eq "tk")} {
	    set coreDialogVersion 3.0
	} elseif {[alpha::package vsatisfies -loose $alpha::version 8.1a4]} {
	    set coreDialogVersion 2.3
	} elseif {[alpha::package vsatisfies -loose $alpha::version 8.1a3]} {
	    set coreDialogVersion 2.2
	} elseif {[alpha::package vsatisfies -loose $alpha::version 8.1a2]} {
	    set coreDialogVersion 2.1
	} elseif {[alpha::package vsatisfies -loose $alpha::version 8.1a1]} {
	    set coreDialogVersion 2.0
	} else {
	    set coreDialogVersion 1.0
	}
    }
    return $coreDialogVersion
}

# ×××× Simple queries and alerts ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 # "dialog::buttonAlert" ?-width w? ?-title <text>? prompt ?button...?
 # 
 #  Create a dialog with the specified buttons, returning the one
 #  selected.  Optionally specify a dialog width and a title.
 #  
 #  Can replace the core's buttonAlert if desired.
 # -------------------------------------------------------------------------
 ##
proc dialog::buttonAlert {args} {
    set opts(-title) ""
    getOpts {-width -title}

    if {![llength $args]} {
        return -code error "wrong # args: should be \"buttonAlert\
          ?options? prompt args\""
    } elseif {[llength $args] == 1} {
        lappend args "OK"
    }
    set prompt [lindex $args 0]
    set dial [list dialog::make -cancel "" -title $opts(-title) \
      -ok [lindex $args 1]]
    if {([llength $args] > 2)} {
        set buttons [list]
        foreach name [lreverse [lrange $args 2 end]] {
            if {$name eq ""} {
                return -code error "Each button must have a name"
            }
            # Construct the script very carefully, in case $name
            # contains braces or quotes characters.  Each button
            # operates as a cancel button, which is the easiest
            # way to have dialog::make return a string to us.
            set script [list set retVal $name]
            append script " ; set retCode 1"
            # Add the button (no help text)
            lappend buttons $name "" $script
        }
        lappend dial -addbuttons $buttons
    }
    if {[info exists opts(-width)]} {
        lappend dial -width $opts(-width)
    }
    lappend dial [list "" [list text $prompt]]

    if {![catch {eval $dial} result]} {
        # Not cancelled - therefore the default button
        return [lindex $args 1]
    } else {
        # Cancelled, and the result is the name of the button
        return $result
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "dialog::value_for_variable" --
 # 
 #  Ask for a value, with default given by the given variable, and using
 #  that variable's type (list, file, ...) as a constraint.
 #  
 #  Currently assumes the variable is a list var, but this will change.
 # -------------------------------------------------------------------------
 ##
proc dialog::value_for_variable {var {title ""}} {
    if {$title == ""} { set title [quote::Prettify $var] }
    return [dialog::optionMenu $title [prefs::options $var] \
      [uplevel [list set $var]]]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "dialog::getAKey" --
 # 
 #  Returns a keystring to be used for binding a key in a menu, 
 #  using a nice dialog box to ask the user.
 # 
 #  Possible improvements: we could replace the dialog
 #  box with a status-line prompt (which would allow the use of
 #  getModifiers to check what keys the user pressed).
 #  
 #  Now handles 'prefixChar' bindings for non-menu items.
 #  i.e. you can use this dialog to bind something to 'ctrl-x ctrl-s',
 #  for instance.
 # 
 #  If the name contains '/' it is considered to be two items,
 #  separated by that '/', which are to take the same binding,
 #  except that one of them will use the option key.
 #  
 #  Similarly '//' means use shift, '///' means shift-option,
 #  For instance 'dialog::getAKey close/closeAll//closeFloat /W<O'
 #  would give you the menu-item for 'close' in the file menu. 
 #  except these last two aren't implemented yet ;-)
 # --Version--Author------------------Changes-------------------------------
 #    1.0     Johan Linde		 original
 #    1.1     <vince@santafe.edu> can do non-menu bindings too
 #    1.2     <vince@santafe.edu> handles arrow keys
 #    1.2.1   Johan Linde        handles key pad keys
 # -------------------------------------------------------------------------
 ##
proc dialog::getAKey {{name {}} {keystr {}} {for_menu 1}} {
    global keys::func
    # two lists for any other keys which look better with a text description
    set otherKeys {"<No binding>" "-" Space}
    set otherKeyChars [list "" "" " "]
    if {!$for_menu} {
	lappend otherKeys Left Right Up Down "Key pad =" \
	  "Key pad /" "Key pad *" "Key pad -" "Key pad +" "Key pad ."
	lappend otherKeyChars "" "" "\x10" "" Kpad= \
	  Kpad/ Kpad* Kpad- Kpad+ Kpad.
	for {set i 0} {$i < 10} {incr i} {
	    lappend otherKeys "Key pad $i"
	    lappend otherKeyChars Kpad$i
	}
    }
    set nname $name
    set shift-opt [expr {![regsub {///} $nname { so-} $nname]}]
    set shift  [expr {![regsub {//} $nname { s-} $nname]}]
    set option [expr {![regsub {/} $nname { o-} $nname]}]
    if {[string length $keystr]} {
	set values "0 0"
	set mkey [keys::verboseKey $keystr normal]
	if {$normal} {
	    lappend values "Normal key"
	} else {
	    lappend values $mkey
	    set mkey {}
	}
	lappend values [regexp {<U} $keystr]
	lappend values [regexp {<B} $keystr]
	if {!$for_menu} {
	    if {[regexp "Ç(.*)È" $keystr "" i]} {
		if {$i == "e"} {
		    lappend values "escape"
		} else {
		    lappend values "ctrl-$i"
		}
	    } else {
		lappend values "<none>"
	    }
	}
	if {$option} {lappend values [regexp {<I} $keystr]}
	lappend values [regexp {<O} $keystr]
	lappend values $mkey
    } else {
	set values {0 0 "" 0 0}
	if {!$for_menu} { lappend values <none> }
	if {$option} {lappend values 0}
	lappend values 0 ""
    }
    if {$for_menu} {
	set title "Menu key binding"
    } else {
	set title "Key binding"
	set prefixes [keys::findPrefixChars]
	foreach i $prefixes {
	    lappend prefix "ctrl-$i"
	}
	lappend prefixes e
	lappend prefix "escape"
    }
    if {$name != ""} { append title " for '$name'" }
    set usep [info exists prefix]
    global alpha::modifier_keys
    while {1} {
	set box ""
	# Build box
	lappend box -T $title
	lappend box -t Key 10 40 40 55 \
	  -m [concat [list [lindex $values 2]] \
	  [list "Normal key"] $otherKeys ${keys::func}] 80 40 220 57 \
	  -c Shift [lindex $values 3] 10 70 60 85 \
	  -c Control [lindex $values 4] 80 70 150 85
	if {$usep} {
	    lappend box -t Prefix 190 40 230 55  \
	      -m [concat [list [lindex $values 5]]  "<none>" "-" $prefix] \
	      235 40 315 57
	}
	if {$option} {
	    lappend box -c [lindex ${alpha::modifier_keys} 2] \
	      [lindex $values [expr {5 + $usep}]] 160 70 228 85
	}
	lappend box -c [lindex ${alpha::modifier_keys} 0] \
	  [lindex $values [expr {5 + $option +$usep}]] 230 70 315 85
	lappend box -n "Normal key" -e [lindex $values [expr {6 + $option +$usep}]] 50 40 70 55
	set values [eval [concat dialog -w 330 -h 130 -b OK 250 100 315 120 -b Cancel 170 100 235 120 $box]]
	# Interpret result
	if {[lindex $values 1]} {error "Cancel"}
	# work around a little Tcl problem
	regsub "\{\{\}" $values "\\\{" values
	set elemKey [string toupper [string trim [lindex $values [expr {6 + $option +$usep}]]]]
	set special [lindex $values 2]
	set keyStr ""
	if {[lindex $values 3]} {append keyStr "<U"}
	if {[lindex $values 4]} {append keyStr "<B"}
	if {$option && [lindex $values [expr {5 + $usep}]]} {append keyStr "<I"}
	if {[lindex $values [expr {5 + $option +$usep}]]} {append keyStr "<O"}
	if {$usep} {
	    set pref [lindex $values 5]
	    if {$pref != "<none>"} {
		set i [lsearch -exact $prefix $pref]
		append keyStr "Ç[lindex $prefixes $i]È"
	    }
	}
	if {[string length $elemKey] > 1 && $special == "Normal key"} {
	    alertnote "You should only give one character for key binding."
	} else {
	    if {$for_menu} {
		if {$special == "Normal key" && [text::Ascii $elemKey] > 126} {
		    alertnote "Sorry, can't define a key binding with $elemKey."
		} elseif {$elemKey != "" && $special == "Normal key" \
		  && ($keyStr == "" || $keyStr == "<U")} {
		    alertnote "You must choose at least one of\
		      the modifiers control, option and command."
		} elseif {![regexp {F[0-9]} $special] && $special != "Tab"\
		  && $special != "Normal key" && $special != "<No binding>"\
		  && $keyStr == ""} {
		    alertnote "You must choose at least one modifier."
		} else {
		    break
		}
	    } else {
		break
	    }
	}
    }
    if {$special == "<No binding>"} {set elemKey ""}
    if {$special != "Normal key" && $special != "<No binding>"} {
	if {[set i [lsearch -exact $otherKeys $special]] != -1} {
	    set elemKey [lindex $otherKeyChars $i]
	} else {
	    set elemKey [text::Ascii [expr {[lsearch -exact ${keys::func} $special] + 97}] 1]
	}
    }
    if {![string length $elemKey]} {
	set keyStr ""
    } else {
	append keyStr "/$elemKey"
    }	
    return $keyStr
}

## 
 # -------------------------------------------------------------------------
 # 
 # "dialog::optionMenu" --
 # 
 #  names is the list of items.  An item '-' is a divider, and empty items
 #  are not allowed.
 # -------------------------------------------------------------------------
 ##
proc dialog::optionMenu {prompt names {default ""} {index 0}} {
    if {$default == ""} {set default [lindex $names 0]}
    
    set y 5
    set w [expr {[string length $prompt] > 20 ? 350 : 200}]
    if {[string length $prompt] > 60} { set w 500 }
    
    # in case we need a wide pop-up area that needs more room
    set popUpWidth [eval dialog::_reqWidth $names]
    set altWidth [expr {$popUpWidth + 60}]
    set w [expr {$altWidth > $w ? $altWidth : $w}]
    
    set dialog [dialog::text $prompt 5 y [dialog::charsToFit $w]]
    incr y 10
    eval lappend dialog [dialog::menu 30 y $names $default $popUpWidth]
    incr y 20
    eval lappend dialog [dialog::okcancel [expr {20 - $w}] y 0]
    set res [eval dialog -w $w -h $y $dialog]
    
    if {[lindex $res 2]} { error "Cancel" } 
    # cancel was pressed
    if {$index} {
	# we have to take out the entries correponding to pop-up 
	# menu separator lines -trf
	set possibilities [lremove -all $names "-"]
	return [lsearch -exact $possibilities [lindex $res 0]]
    } else {
	return [lindex $res 0]
    }
}

proc dialog::getDate {{prompt "Please type your date, or use the\
  button below"} {date ""}} {
    while {1} {
	set y 5
	set w 400
	set dialog [list -T "Select Date"]
	
	eval lappend dialog [dialog::text $prompt 5 y [dialog::charsToFit $w]]
	incr y 10
	if {![info exists formattedDate]} {
	    if {$date != ""} {
		set formattedDate [clock format $date]
	    } else {
		set formattedDate ""
	    }
	}
	eval lappend dialog [dialog::edit $formattedDate 10 y 35]
	incr y 35
	eval lappend dialog [dialog::okcancel [expr {20 - $w}] y 0]
	incr y -55
	eval lappend dialog [dialog::button "Get modification\
	  date from a file" 10 y \
	  "Check date format" 260 y]

	incr y 30
	set res [eval dialog -w $w -h $y $dialog]
	
	set formattedDate [string trim [lindex $res 0]]

	if {[lindex $res 3]} {
	    # pick file
	    if {![catch {getfile "Pick file from which to get\
	      modification date"} file]} {
		set date [file mtime $file]
		unset formattedDate
	    }
	} elseif {[lindex $res 4]} {
	    # check format
	    if {[catch {clock scan $formattedDate} newdate]} {
		alertnote "There was an error interpreting your date: $newdate"
	    } else {
		alertnote "I understood '[clock format $newdate]'"
	    }
	} elseif {[lindex $res 1]} { 
	    # ok, trim the result in case it was pasted in with
	    # spaces/new-lines before or after
	    if {[catch {clock scan $formattedDate} newdate]} {
		alertnote "There was an error interpreting your date: $newdate"
	    } else {
		return $newdate
	    }
	} elseif {[lindex $res 2]} { 
	    # cancel
	    error "Cancel" 
	}
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "dialog::getUrl" --
 # 
 # Create a very wide dialog with a single text-edit field into which the
 # user can type a url.  We always offer the option to choose a local file,
 # which can then be edited if the user wanted its folder instead.  If the
 # [url::browserWindow] procedure doesn't throw an error, then we also
 # include a button allowing the user to grab the name of the url in the
 # frontmost browser window.
 # 
 # If the url is not valid, we offer the dialog again.
 # 
 # --------------------------------------------------------------------------
 ##

proc dialog::getUrl {{p ""} {url ""}} {
    
    variable getUrlDialogUrl $url
    
    if {![string length $p]} {
	set p "Please type your url, or use one of the buttons below:\r"
    }
    # Buttons.  For each we need a name, balloon help, and a script.
    set button1 [list \
      "Pick Local FileÉ" \
      "Click this button to select a local file" \
      {dialog::valSet $dial {,Url:} [dialog::getFileUrl]}]
    set button2 [list \
      "Use Frontmost Browser Page" \
      "Click this button to select the url in your browser window" \
      {dialog::valSet $dial {,Url:} [url::browserWindow]}]
    set button3 [list \
      "Specify Ftp SiteÉ" \
      "Click this button to specify an ftp site" \
      {dialog::valSet $dial {,Url:} [dialog::getFtpUrl]}]
    
    set buttons $button1
    if {![catch {url::browserWindow}]} {
	eval lappend buttons $button2
    }
    eval lappend buttons $button3
    # Present the dialog to the user.
    set result [dialog::make -title "Select URL" -width 650 \
      -addbuttons $buttons [list "" \
      [list "text" $p] \
      [list "var"  "Url:" $url]]]
    set url [string trim [lindex $result 0]]
    if {[catch {url::parse $url}]} {
	alertnote "${url}\r\ris not a valid url!"
	set url [dialog::getUrl $p $url]
    } 
    return $url
}

proc dialog::getFtpUrl {{origUrl ""}} {
    set old ""
    if {$origUrl ne ""} {
	set uinfo [url::parse $origUrl]
	if {[lindex $uinfo 0] eq "ftp"} {
	    url::parseFtp [lindex $uinfo 1] i
	    lappend old $i(host) $i(path) $i(user) $i(password)
	}
    }
    foreach {host path user password} \
      [eval [list dialog::ftpLogin "" 0 ""] $old] {}
    set url "ftp://"
    if {$user ne ""} {
	append url $user
	if {$password ne ""} {
	    append url ":" $password
	}
	append url "@"
    }
    append url $host "/" $path
    return $url
}

##
 # --------------------------------------------------------------------------
 # 
 # "dialog::getFileUrl" --
 # 
 # Offer the [getFile] dialog, and properly convert the chosen file name to
 # a url.  The default "url" argument can be either the full filesystem path,
 # or a url equivalent of an existing file.
 # 
 # Because this procedure is called by a button script in [dialog::getUrl],
 # we don't throw an error if the user cancelled the [getfile] dialog, and
 # instead return the original "url" argument that was provided.  The last
 # file chosen is remembered the next time that this procedure is called, and
 # will be used as the default if none is provided.
 # 
 # --------------------------------------------------------------------------
 ##

proc dialog::getFileUrl {{p ""} {url ""}} {
    
    variable getUrlDialogUrl
    
    if {![string length $p]} {
	set p "Select a local file to use as url"
    } 
    if {[string length $url]} {
	set defaultFile $url
    } elseif {[info exists getUrlDialogUrl]} {
	set defaultFile $getUrlDialogUrl
    } else {
	set defaultFile ""
    }
    if {[string range $defaultFile 0 6] == "file://"} {
	set defaultFile [file::fromUrl $url]
    } 
    if {![file isfile $defaultFile]} {
	set defaultFile ""
    }
    if {![catch {getfile $p $defaultFile} fileName]} {
	set url [file::toUrl $fileName]
	set getUrlDialogUrl $url
    }
    return $url
}

## 
 # -------------------------------------------------------------------------
 # 
 # "dialog::alert" --
 # 
 # Identical to [alertnote] but copes with larger blocks of text, and resizes
 # to that text as appropriate.  The "args" list can include the "-title" and
 # "-width" and any other switches accepted by [dialog::yesno], with the
 # exception of the "-y" and "-n" switches.
 # 
 # -------------------------------------------------------------------------
 ##

proc dialog::alert {args} {
    if {[catch {eval [list dialog::yesno -y "OK" -n ""] $args}]} {
	# probably ran into a problem with Alpha 7's dialogs
	alertnote [string range [join $args " "] 0 250]
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "dialog::errorAlert" --
 # 
 # Identical to [dialog::alert] but throws after the user presses the "OK"
 # button.  Add the string "cancel" somewhere in the first argument to
 # ensure that the error message remains in the status bar.
 # 
 # -------------------------------------------------------------------------
 ##

proc dialog::errorAlert {args} {
    eval [list dialog::alert -title "Error Alert"] $args
    error [lindex $args 0]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "dialog::yesno" --  ?switches? text ?text text ...?
 # 
 # This dialog should be used instead of [askyesno] when the string
 # length of the text is greater than 256 (on Alpha 8/X), or when the
 # calling code wants more control over the names of the buttons.  Valid
 # switches include:
 # 
 # -n           : the name of the "No" button.  Default is "No".
 # -y           : the name of the "Yes" button.  Default is "Yes".
 # -c           : include a "Cancel" button.  Default is not included.
 # -t           : the "type" of icon presented in the dialog.
 # -title       : the title of the dialog.  Default is the null string.
 # -width       : the width of the dialog.  If not supplied, shorter text
 #                strings (< 60) will be "350", otherwise default is "500".
 # -noAlert     : never use the MacOS [::alert] dialog.  This is mainly for
 #                debugging purposes.
 # 
 # "--" indicates the end of switches.
 # 
 # The remaining arguments will be presented as blocks of text in the dialog, 
 # each beginning on a new line.  For back compatibility, a single text arg
 # will be split at each "\r" or "\n" to create multiple text blocks.
 # 
 # If "-c" is present and the user presses Cancel, then a cancel error is
 # thrown.  Otherwise, returns "1" for the "Yes" button and "0" for "No".
 # 
 # --------------------------------------------------------------------------
 # 
 # In Alpha8/X, if the total length of the dialog text is < 256 characters,
 # and -title, -width are not given, then we use the core [::alert] dialog
 # which is more aesthetic.  You can bypass this and ensure the
 # [dialog::make] is used by supplying "-noAlert".
 # 
 # Otherwise, if "-c" is supplied we ensure that the Cancel button is to the
 # far left of the dialog, with the "Yes/No" to the far right, side by side.
 # We do this by replacing the "normal" [dialog::make] Cancel button with our
 # "No" text and using the "retVal" value in the "-addbuttons" argument to
 # determine which button was actually pressed.
 # 
 # --------------------------------------------------------------------------
 # 
 # Tip: This can be an "OK/Cancel" dialog by calling this:
 # 
 #     dialog::yesno -y "OK" -n "Cancel" -- "text argument"
 # 
 # In this case, the user is allowed to press the Escape key to cancel the
 # dialog.  Pressing the Escape key or the Cancel button still returns "0"
 # without any error thrown.
 # 
 # --------------------------------------------------------------------------
 ##

proc dialog::yesno {args} {
    global alpha::platform
    
    # Set defaults, then get options to determine which buttons to present.
    array set opts [list \
      "-y"      "Yes" \
      "-n"      "No" \
      "-t"      "note" \
      "-title"  "" \
      "-width"  "" \
      ]
    getOpts [list "-y" "-n" "-t" "-title" "-width"]
    if {![string length $opts(-y)]} {
	error "The 'yes' button name cannot be an empty string."
    } 
    regsub -all {[\r\n]+\s*[\r\n]*} [join $args "\r"] "\r\r" textArgs
    # If possible, use the MacOS alert dialog
    if {($alpha::platform eq "alpha") \
      && ![info exists opts(-noAlert)] && ![string length $opts(-width)] \
      && ![string length $opts(-title)] && ([string length $textArgs] < 256)} {
	set script [list ::alert -t $opts(-t) -k $opts(-y) -c $opts(-n)]
	if {[info exists opts(-c)]} {
	    lappend script -o "Cancel" -C other
	} elseif {($opts(-n) eq "Cancel")} {
	    lappend script -o "" -C cancel
	} else {
	    lappend script -o "" -C none
	}
	lappend script $textArgs
	switch -- [eval $script] [list  \
	  $opts(-y)     {return 1} \
	  $opts(-n)     {return 0} \
	  default       {error "cancel"} \
	  ]
    }
    # Create the initial dialog script.  
    if {![string length $opts(-width)]} {
	# We'll automatically adjust the width for small text prompts.
	if {([string length $textArgs] < 60)} {
	    set opts(-width) "350"
	} else {
	    set opts(-width) "500"
	}
    }
    set dialogScript [list dialog::make -title $opts(-title) \
      -width $opts(-width) -ok $opts(-y) -cancel $opts(-n)]
    # If we add a "Cancel" button, put it to the far left.
    if {[info exists opts(-c)]} {
	lappend dialogScript "-addbuttons" [list "Cancel" "" \
	  {set retCode "1" ; set retVal "cancelButton"}]
    }
    # Add the text to the dialog pane.
    set dialogPane [list ""]
    set i 0
    foreach textArg [split $textArgs "\r"] {
	if {[string length [set textArg [string trim $textArg]]]} {
	    lappend dialogPane \
	      [list [list discretionary 350]] \
	      [list "text" "${textArg}\r"]
	}
    }
    lappend dialogScript $dialogPane
    # Present the dialog, and return the results.
    if {![catch {eval $dialogScript} result]} {
	return 1
    } elseif {![info exists opts(-c)] || ($result ne "cancelButton")} {
	return 0
    } else {
	error "cancel"
    }
}


proc dialog::password {{msg "Please enter password:"}} {
    set values [dialog -w 300 -h 90 -t $msg 10 20 290 35 \
      -e "" 10 40 290 42 -b OK 220 60 285 80 -b Cancel 140 60 205 80]
    if {[lindex $values 2]} {error "Cancel"}
    return [lindex $values 0]
}

# ×××× Finding applications ×××× #


# Doesn't actually set '$var' to the new value.  It is up to our caller
# to do that.
proc dialog::askFindApp {var sig} {
    if {$sig == ""} {
	set text "Currently unassigned.   Set?"
    } elseif {[catch {nameFromAppl '$sig'} name]} {
	set text "App w/ sig '$sig' doesn't seem to exist.   Change?"
    } else {
	set text "Current value is '$name'.   Change?"
    }
    if {[dialog::yesno $text]} {
	set nsig [dialog::findApp $var "" $sig]
	set app [nameFromAppl $nsig]
	if {[dialog::yesno "Are you sure you want to set $var to '$nsig'\
	  (mapped to '$app')?"]} {
	    return $nsig
	}
    }
    return ""
}

# The optional third argument can be used to prompt the user
# with the 'old' value.  This function doesn't actually set
# the variable '$var' to the new value.  It is up to the calling
# procedure to do that.
proc dialog::findApp {var {prompt ""} {sig ""}} {
    if {[regexp -- {(.*)\((.*)\)$} $var "" arr elt]} {
	global $arr ${elt}s
    } else {
	global $var ${var}s
	set elt $var
    }

    # First of all create a list of acceptable signatures for
    # the given variable.  '$var' is something like 'texSig',
    # and there is an associated variable 'texSigs' which contains
    # all the tex signatures we know about (some are predefined).
    # Whenever we discover a new signature (at the end of this proc,
    # for example), it will be added to that list.
    if {[info exists $var]} {
	lappend sigs [set $var]
    } else {
	set sigs {}
    }
    if {[info exists ${elt}s]} {
	# have a list of items
	eval [list lappend sigs] [set ${elt}s]
    }
    set sigs [lunique $sigs]
    # For each acceptable signature, try to find any applications
    # in the filesystem which might be ok for that sig.  Also count
    # how many we found, and store the full paths in 'itemFullPaths' and
    # the minimal distinct tails of the paths (to present to the user)
    # in 'itemShowUser'
    set itemFullPaths [list]
    set itemShowUser [list]
    set s 0
    foreach f $sigs {
	set possiblePaths [app::getPathsFromSig $f typeArr]
	eval [list lappend itemFullPaths] $possiblePaths
	incr s [llength $possiblePaths]
	# This could be problematic if this call acutally removes
	# any of the paths.  We assume it doesn't.
	eval [list lappend itemShowUser] \
	  [file::minimalDistinctTails $possiblePaths]
    }
    
    set thepage 1
    # Now, if we found any full paths, we can prompt the user with them,
    # since that is much easier than trying to find an application 
    # through a file dialog.  However we will also let the user specify
    # the application in a number of other ways:
    # (1) Select from the list we generate
    # (2) Locate manually in a file dialog
    # (3) Enter the signature directly
    # (4) Enter the path directly
    if {$s} {
	set option "Select from items found"
	lappend pages $option
	set page [list $option]
	if {[info exists thepage]} {
	    lappend page [list thepage]
	    unset thepage
	}
	
	lappend page [list [list "menuindex" $itemShowUser] \
	  "The following applications were found:"]
	lappend dialog $page
    }
    global alpha::macos tcl_platform
    # If we're on MacOS (of any kind), then we should have apple-events
    # available.
    if {${alpha::macos}} {
	set AE 1
    } else {
	set AE 0
    }
    
    # If we're not on classic macos (i.e. we're on Windows, Unix or
    # MacOSX) then we have command-line tools available.
    if {$tcl_platform(platform) != "macintosh"} {
	set EXEC 1
    } else {
	set EXEC 0
    }
    
    # Note: assumption that at least one of AE, EXEC is 1.
    if {1} {
	set option "Locate manually"
	lappend pages $option
	set page [list $option]
	if {[info exists thepage]} {
	    lappend page [list thepage]
	    unset thepage
	}
	if {$AE && $EXEC} {
	    # We have to ask the user which they have selected
	    # If only one or other of these options is available
	    # then the choice is given.
	    set msg "The application:"
	    lappend page [list [list "menu" [list \
	      "apple-events" \
	      "the command-line"]] "Communicate via"]
	} elseif {$AE} {
	    set msg "The application (communication via apple-events):"
	} elseif {$EXEC} {
	    set msg "The application (communication via command-line):"
	}
	lappend page [list file $msg ""]
	lappend dialog $page
    }
    if {$AE} {
	set option "Application signature"
	lappend pages $option
	set page [list $option]
	if {[app::type $sig] == "tclae"} {
	    set old $sig
	} else {
	    set old ""
	}
	lappend page [list variable "4-char creator code" $old]
	lappend dialog $page
    }
    if {$EXEC} {
	set option "Full path of a command-line application"
	lappend pages $option
	set page [list $option]
	if {[app::type $sig] == "exec"} {
	    set old $sig
	} else {
	    set old ""
	}
	lappend page [list variable "Full path of application" $old]
	lappend dialog $page
    }
    set res [eval [list dialog::make -title $prompt] $dialog]
    set page [lsearch -exact $pages [lindex $res 0]]

    set index 1
    if {$s && !$page} {
	set choice [lindex $itemFullPaths [lindex $res $index]]
	set type $typeArr($choice)
	switch -- $type {
	    "ae" {
		return [file::getSig $choice]
	    }
	    "exec" {
		return $choice
	    }
	}
    } else {
	if {$s} { incr index 1 }
	if {!$s} { incr page 1 }
	if {$page == 1} {
	    if {$AE && $EXEC} {
		set how [lindex $res $index]
		incr index
	    } elseif {$AE} {
		set how "apple-events"
	    } else {
		set how "the command-line"
	    }
	    set choice [lindex $res $index]
	    if {$how == "apple-events"} {
		return [file::getSig $choice]
	    } else {
		return $choice
	    }
	} else {
	    if {$AE && $EXEC} {
		incr index 2
	    } else {
		incr index 1
	    }
	    if {$page == 3} {
		incr index
	    }
	    set choice [lindex $res $index]
	    if {$AE && ($page == 2)} {
		# We have AE
		return $choice
	    } else {
		# We have exec.
		return $choice
	    }
	}
    }
}

proc dialog::findAnyApp {{prompt "Locate application:"}} {
    if {[catch {getfile $prompt} path]} {return ""}
    return $path
}

proc dialog::_findApp {var prompt {sig ""}} {
    global alpha::platform
    if {${alpha::platform} == "alpha"} {
	set dir ""
    } else {
	set dir [file dirname $sig]
    }
    if {[catch {getfile $prompt $sig} path]} { return "" }
    set nsig [file::getSig $path]
    set app [nameFromAppl $nsig]
    if {($app ne $path)} {
	alertnote "Appl sig '$nsig' is mapped to '$app', not '$path'.\
	  Remove the former, or rebuild your desktop."
	return ""
    }
    return $nsig
}

## 
 # --------------------------------------------------------------------------
 # 
 # "dialog::arrangeItems" --
 # 
 # Given an original list of items, allow the user to change the order.  If 
 # the new order is ultimately rejected, a "cancel" error is thrown.
 # 
 # --------------------------------------------------------------------------
 ##

proc dialog::arrangeItems {origItems} {
    
    set msg "(Use the following order:)"
    set items [list $msg]
    set items [concat $items $origItems]
    set p1 "Select item to move:"
    set L  [lindex $items 1]
    while {1} {
	if {[catch {listpick -p $p1 -L [list $L] $items} item]} {
	    break
	}
	if {($item eq "") || ($item eq $msg)} {
	    break
	}
	set p2 "Move '$item' to position:"
	set where [lsearch -exact $items $item]
	if {![catch {prompt $p2 $where or first last} res]} {
	    switch -- $res {
		0 - first {set res 1}
		last      {set res [llength $items]}
		default   {
		    if {![is::UnsignedInteger $res]} {
			alertnote "Please enter a position number."
			set L $item
			continue
		    } elseif {$res > [llength $items]} {
			set res [llength $items]
		    }
		}
	    }
	    set index [lsearch -exact $items $item]
	    set items [lreplace $items $index $index]
	    set items [linsert $items $res $item]
	    set p1 "Move another item?"
	    set L $msg
	}
    }
    set items [lrange $items 1 end]
    if {($items eq $origItems) \
      || ![dialog::yesno -y "Accept" -n "Cancel" "New order is: $items"]} {
	error "cancel"
    }
    return $items
}

# ×××× Multiple bindings dialogs ×××× #

proc dialog::arrayBindings {name array {for_menu 0}} {
    upvar 1 $array a
    foreach n [lsort -dictionary [array names a]] {
	lappend l [list $a($n) $n]
    }
    if {[info exists l]} {
	eval dialog::adjustBindings [list $name modified "" $for_menu] $l
    }
    array set a [array get modified]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "dialog::adjustBindings" --
 # 
 #  'args' is a list of pairs.  The first element of each pair is the 
 #  menu binding, and the second element is a descriptive name for the
 #  element. 'array' is the name of an array in the calling proc's
 #  scope which is used to return modified bindings.
 # 
 # Results:
 #  
 # --Version--Author------------------Changes-------------------------------
 #    1.0     Johan Linde			   original for html mode
 #    1.1     <vince@santafe.edu> general purpose version
 #    1.2     Johan Linde              split into two pages when many items
 # -------------------------------------------------------------------------
 ##
proc dialog::adjustBindings {name array {rmod {}} {for_menu 1} args} {
    global screenHeight
    upvar 1 $array key_changes
    
    set items $args
    
    foreach it $items {
	if {$it == "\(-"} {continue}
	if {[info exists key_changes([lindex $it 1])]} {
	    set tmpKeys([lindex $it 1]) $key_changes([lindex $it 1])
	} else {
	    set tmpKeys([lindex $it 1]) [lindex $it 0]
	}
    }
    # do we return modified stuff?
    if {$rmod != ""} { upvar 1 $rmod modified }
    set modified ""
    set page "Page 1 of $name"
    # Can't currently set in place, so this is ok.
    set mod ""
    while {1} {
	# Build dialog.
	set twoWindows 0
	set box ""
	set h 30
	foreach it $items {
	    if {$it == "\(-"} {continue}
	    set w 210
	    set w2 370
	    set key $tmpKeys([lindex $it 1])
	    set key1 [dialog::specialView::binding $key]
	    set it2 [split [lindex $it 1] /]
	    if {[llength $it2] == 1} {
		lappend box -t [lindex $it2 0] 65 $h 205 [expr {$h + 15}] -t $key1 $w $h $w2 [expr {$h + 15}]
		eval lappend box [dialog::buttonSet $mod 10 $h]
		incr h 22
	    } else {
		lappend box -t [lindex $it2 0] 65 $h 205 [expr {$h + 15}] -t $key1 $w $h $w2 [expr {$h + 15}]
		eval lappend box [dialog::buttonSet $mod 10 [expr {$h +8}]]
		incr h 22
		if {$key1 != "<no binding>"} {regsub {((ctrl-)?(shift-)?)(.*)} $key1 {\1opt-\4} key1}
		lappend box -t [lindex $it2 1] 65 $h 205 [expr {$h + 15}] -t $key1 $w $h $w2 [expr {$h + 15}]
		incr h 22
	    }
	    if {$it != [lindex $items [expr {[llength $items] -1}]] && !$twoWindows && [set twoWindows [expr {$h + 200 > $screenHeight}]]} {
		set box " -n [list [concat Page 1 of $name]] $box -n [list [concat Page 2 of $name]] "
		set hmax $h; set h 30
	    }
	}
	if {[info exists hmax]} {set h $hmax}
	if {$twoWindows} {
	    set top "-m [list [list $page [concat Page 1 of $name] [concat Page 2 of $name]]] 10 10 370 25"
	} else {
	    set top [dialog::title $name 250]
	}
	set buttons "-b OK 300 [expr {$h + 10}] 365 [expr {$h + 30}] -b Cancel 220 [expr {$h + 10}] 285 [expr {$h + 30}]"
	set values [eval [concat dialog -w 380 -h [expr {$h + 40}] $buttons $top $box]]
	if {$twoWindows} {set page [lindex $values 2]}
	if {[lindex $values 1]} {
	    # Cancel
	    return "Cancel"
	} elseif {[lindex $values 0]} {
	    # Save new key bindings
	    foreach it $modified {
		set key_changes($it) $tmpKeys($it)
	    }
	    return
	} else {
	    # Get a new key.
	    set it [lindex [lindex $items [expr {[lsearch $values 1] - 2 - $twoWindows}]] 1]
	    if {![catch {dialog::getAKey $it $tmpKeys($it) $for_menu} newKey]  && $newKey != $tmpKeys($it)} {
		set tmpKeys($it) $newKey
		lappend modified $it
	    }
	}
    }
}

# ===========================================================================
# 
# .