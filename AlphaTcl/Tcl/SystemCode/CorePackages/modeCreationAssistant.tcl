## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "modeCreationAssistant.tcl"
 #                                    created: 02/29/2000 {09:40:40 AM} 
 #                                last update: 01/24/2005 {06:33:46 PM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #    mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 2000-2004 Vince Darley
 # 
 # Distributed under a Tcl style license.
 # 
 # Version 0.1.3 : extensions, simple menu, helper app, keywords,
 # comment characters. lineWrap, funcExpr/parseExpr preferences.
 # 
 # I probably won't do much more work on this, so if you'd like
 # to help, please do so.
 # ###################################################################
 ##

namespace eval modeAssistant {}

proc createNewMode {} {
    modeAssistant
}

## 
 # -------------------------------------------------------------------------
 # 
 # "modeAssistant" --
 # 
 # -------------------------------------------------------------------------
 ##
proc modeAssistant {} {
    global modeAssistant
    # We don't clear old values, in case the user cancelled and is
    # trying again
    ensureset modeAssistant(name) ""
    ensureset modeAssistant(extensions) ""
    ensureset modeAssistant(menuname) ""
    ensureset modeAssistant(author) "Maintainer's Name"
    ensureset modeAssistant(email) "Maintainer's E-mail Address"
    ensureset modeAssistant(homePage) "Maintainer's Home Page"
    ensureset modeAssistant(helpText) "This is a nifty mode"
    ensureset modeAssistant(addHelper) 0
    ensureset modeAssistant(helperApplication) "<no current helper>"
    ensureset modeAssistant(helperName) ""
    ensureset modeAssistant(switchhelper) 0
    ensureset modeAssistant(sendtohelper) 0
    ensureset modeAssistant(keywords) ""
    ensureset modeAssistant(comments) ""
    ensureset modeAssistant(multicommentprefix) ""
    ensureset modeAssistant(multicommentsuffix) ""
    ensureset modeAssistant(lineWrap) 0
    ensureset modeAssistant(funcExpr) ""
    ensureset modeAssistant(parseExpr) ""
    
    set modeAssistant(stepNumber) 1

    foreach page {
	welcome options modeHelp modeMenu keywords comments wrapAndMark create
    } {
	modeAssistant::$page
    }
}

proc modeAssistant::start {yy} {
    global modeAssistant
    set title "Mode creation assistant"
    if {$modeAssistant(stepNumber) > 1} {
        append title " - step $modeAssistant(stepNumber) of 7"
    } 
    incr modeAssistant(stepNumber)
    upvar 1 $yy y
    return [list -T $title]
}

proc modeAssistant::welcome {} {
    while {1} {
	global modeAssistant
	set y 20
	set dialog [modeAssistant::start y]
	eval lappend dialog [dialog::text \
	  "Welcome to the Mode creation assistant.  This assistant will guide\
	  you through a few screens to create a new mode for Alpha and Alphatk."\
	  10 y 60]
	
	eval lappend dialog \
	  [dialog::text "Please enter the name for the mode.  This must be\
	  1-4 characters long, and may not contain any spaces:" 20 y 60] \
	  [dialog::edit $modeAssistant(name) 30 y 5] \
	  [dialog::text "Please enter the usual file patterns used for\
	  this mode, separated by spaces.  For example 'C' mode uses\
	  '*.c *.h'.  Extensions are case-sensitive, so you may wish to\
	  enter '*.ext *.EXT', for instance.  Whenever Alpha encounters a file\
	  with these extensions/patterns, it will automatically use your mode.\
	  You may enter as many such patterns as you\
	  like:" 20 y 60] \
	  [dialog::edit $modeAssistant(extensions) 30 y 20]
	
	incr y 20
	
	eval lappend dialog [dialog::button "Continue" 350 y "Cancel" 275 y] 
	set res [eval dialog -w 440 -h $y $dialog]
	
	if {[lindex $res end]} {
	    error "Cancelled!"
	}
	set name [lindex $res 0]
	set modeAssistant(name) $name
	set modeAssistant(extensions) [lindex $res 1]
	if {![string length $name] || [string length $name] > 4 \
	  || [regexp {[ \t\r\n]} $name]} {
	    alertnote "You must enter a name, of 1-4 characters, containing\
	      no whitespace"
	    continue
	}
	if {![is::List $modeAssistant(extensions)]} {
	    alertnote "The list of extensions must be a valid Tcl list"
	    continue
	}
	break
    }
    
}

proc modeAssistant::options {} {

    global modeAssistant

    set y 20
    set dialog [modeAssistant::start y]
    eval lappend dialog [dialog::text \
      "Please enter some information about yourself so that others can\
      contact you with bug reports, high praise, or other feedback."\
      10 y 55]
    incr y 10
    eval lappend dialog \
      [dialog::textedit "Real Name"         $modeAssistant(author)   20 y 35]\
      [dialog::textedit "E-Mail Address"    $modeAssistant(email)    20 y 35]\
      [dialog::textedit "Home Page"         $modeAssistant(homePage) 20 y 35]
    incr y 20
    eval lappend dialog [dialog::button "Continue" 310 y "Cancel" 235 y] 
    set res [eval dialog -w 400 -h $y $dialog]
    if {[lindex $res end]} {
	error "Cancelled!"
    }
    set modeAssistant(author)   [lindex $res 0]
    set modeAssistant(email)    [lindex $res 1]
    set modeAssistant(homePage) [lindex $res 2]
    return
}

proc modeAssistant::modeHelp {} {
    
    global modeAssistant
    
    set y 20
    set dialog [modeAssistant::start y]
    eval lappend dialog [dialog::text  \
      "Please describe why your mode exists, i.e. what types of files would\
      make use of it, its relation to other applications or programming\
      languages, any special features that it might provide, etc.  This\
      information will be offered to users when they access Help for your\
      new \"$modeAssistant(name)\" mode. This information can also be edited\
      later after the mode has been created."\
      10 y 65]
    incr y 10
    eval lappend dialog \
      [dialog::edit $modeAssistant(helpText) 20 y 40 10]
    incr y 20
    eval lappend dialog [dialog::button "Continue" 360 y "Cancel" 285 y] 
    set res [eval dialog -w 450 -h $y $dialog]
    if {[lindex $res end]} {
	error "Cancelled!"
    }
    set modeAssistant(helpText) [lindex $res 0]
    return
}

proc modeAssistant::modeMenu {} {
    global modeAssistant
    while {1} {
	set y 20
	set dialog [modeAssistant::start y]
	eval lappend dialog [dialog::text \
	  "Many modes have their own special menu associated with them.\
	  Whenever you are using the mode, that menu is automatically\
	  placed in the menu bar.  It usually contains commands for two\
	  main purposes: commands very specific to editing in that mode,\
	  or commands to interact with one or more applications which\
	  understand the kind of files you are editing.  For example\
	  when editing .html files, it is convenient to have a menu\
	  containing commands to send the current .html window to your\
	  web browser." 10 y 100]
	incr y 10
	eval lappend dialog [dialog::text "If you would like to create\
	  a menu specific to this mode, please enter a short name for the\
	  menu (for instructions on using an icon as a name, please ask on\
	  the alphatcl-developers mailing list)" 20 y 80]
	eval lappend dialog \
	  [dialog::textedit "Menu name:" $modeAssistant(menuname) 20 y 8] \
	  [dialog::checkbox "Add a helper application" \
	  $modeAssistant(addHelper) 20 y] \
	  [dialog::textedit "Short name for app:" $modeAssistant(helperName) 50 y 8] \
	  [dialog::button "Select helper application:" 50 y] \
	  [dialog::text $modeAssistant(helperApplication) 50 y] \
	  [dialog::checkbox "Add a menu command to switch to the helper" \
	  $modeAssistant(switchhelper) 50 y] \
	  [dialog::checkbox "Add a menu command to send the window to the helper" \
	  $modeAssistant(sendtohelper) 50 y]
	
	incr y 20
	
	eval lappend dialog [dialog::button "Continue" 550 y "Cancel" 475 y] 
	
	set res [eval dialog -w 640 -h $y $dialog]
	if {[lindex $res end]} {
	    error "Cancelled!"
	}
	set modeAssistant(menuname) [lindex $res 0]
	set modeAssistant(addHelper) [lindex $res 1]
	set modeAssistant(helperName) [lindex $res 2]
	set modeAssistant(switchhelper) [lindex $res 4]
	set modeAssistant(sendtohelper) [lindex $res 5]
	if {[lindex $res 3]} {
	    # pick helper button
	    set modeAssistant(helperApplication) [dialog::findAnyApp]
	} else {
	    # Continue
	    break
	}
    }
    
}

proc modeAssistant::keywords {} {
    global modeAssistant
    set y 20
    set dialog [modeAssistant::start y]
    eval lappend dialog [dialog::text \
      "Most modes have particular keywords which should be coloured\
      differently.  Please enter this mode's keywords below."\
      10 y 65]
    incr y 10
    eval lappend dialog \
      [dialog::edit $modeAssistant(keywords) 20 y 40 10]
    incr y 20
    eval lappend dialog [dialog::button "Continue" 360 y "Cancel" 285 y] 
    set res [eval dialog -w 450 -h $y $dialog]
    if {[lindex $res end]} {
	error "Cancelled!"
    }
    set modeAssistant(keywords) [lindex $res 0]
    if {![is::List $modeAssistant(keywords)]} {
	alertnote "The keywords must form a valid Tcl list"
	return [modeAssistant::keywords]
    } else {
	set modeAssistant(keywords) [lsort -dictionary [lindex $res 0]]
    }
}

proc modeAssistant::comments {} {
    global modeAssistant
    set y 20
    set dialog [modeAssistant::start y]
    eval lappend dialog [dialog::text \
      "Most modes have particular codes used to signify\
      a comment.  For example C++ and Java have '//' for a\
      single line comment, and '/*','*/' for multi-line comments.\
      Please enter this mode's comment characters below.  If the mode\
      doesn't have multi-line comments, leave that section blank."\
      10 y 65]
    incr y 10
    eval lappend dialog \
      [dialog::textedit "Comment prefix:" $modeAssistant(comments) 20 y 4]\
      [dialog::textedit "Multi-line prefix:" $modeAssistant(multicommentprefix) 20 y 4]\
      [dialog::textedit "Multi-line suffix:" $modeAssistant(multicommentsuffix) 20 y 4]
    incr y 20
    eval lappend dialog [dialog::button "Continue" 360 y "Cancel" 285 y] 
    set res [eval dialog -w 450 -h $y $dialog]
    if {[lindex $res end]} {
	error "Cancelled!"
    }
    set modeAssistant(comments) [lindex $res 0]
    set modeAssistant(multicommentprefix) [lindex $res 1]
    set modeAssistant(multicommentsuffix) [lindex $res 2]
}

proc modeAssistant::wrapAndMark {} {
    global modeAssistant
    set y 20
    set dialog [modeAssistant::start y]
    eval lappend dialog [dialog::text \
      "For 'textual' modes it is convenient to have Alpha wrap text as\
      you type, so that no lines are excessively long.  For 'programming'\
      modes, such automatic wrapping is usually undesireable.  Would you\
      like your mode to have automatic wrapping? (It can be overridden later)"\
      10 y 100]
    eval lappend dialog \
      [dialog::checkbox "Automatic line wrapping" $modeAssistant(lineWrap) 20 y]
    incr y 10
    # Grab example from man mode
    set j1 {.SH [^\r\n\t]*}
    set j2 {.SH (.*)}
    eval lappend dialog [dialog::text \
      "Alpha provides a 'funcs' menus which is generated by\
      scanning documents for function names/section headings/etc.  The menu\
      can then be used to jump to the location of the stored functions/headings.\
      To do this for your mode, Alpha requires two regular expressions, one which\
      will match a pattern containing something which needs marking, and the other\
      which will take the matched text and extract, or parse, as the first bracketed '()'\
      expression, the name of the item (i.e. the section/function name).  If\
      you need help with this, please ask on the alphatcl-developers\
      mailing list (you may leave them blank). \rFor example, 'man' mode uses\
      '$j1' and '$j2', where the first pattern matches a block of text starting\
      with '.SH ' and continuing up to the next new-line or tab character (this is\
      what a section looks like in that mode), and the second pattern extracts from\
      that block of text, as the first bracketed expression, the actual sub-string\
      to use as the section name, in this case everything after the '.SH '."\
      10 y 100]
    eval lappend dialog [dialog::textedit "Function expression:"\
      $modeAssistant(funcExpr) 20 y 50]
    eval lappend dialog [dialog::textedit "Parse expression:"\
      $modeAssistant(parseExpr) 20 y 50]
    incr y 20
    eval lappend dialog [dialog::button "Continue" 550 y "Cancel" 475 y] 
    set res [eval dialog -w 640 -h $y $dialog]
    if {[lindex $res end]} {
	error "Cancelled!"
    }
    set modeAssistant(lineWrap) [lindex $res 0]
    set modeAssistant(funcExpr) [lindex $res 1]
    set modeAssistant(parseExpr) [lindex $res 2]
}


proc modeAssistant::create {} {
    global modeAssistant
    set t "\n"
    append t "# Automatically created by mode assistant\n#\n"
    append t "# Mode: $modeAssistant(name)\n\n\n"

    if {$modeAssistant(addHelper) && ![string length $modeAssistant(helperName)]} {
	set modeAssistant(helperName) $modeAssistant(name)App
    }
    if {$modeAssistant(addHelper)} {
	set appName "[string toupper [string index $modeAssistant(helperName) 0]][string range $modeAssistant(helperName) 1 end]"
	set sigName "[string tolower $modeAssistant(helperName)]Sig"
	# This will fail if the given path doesn't exist, which will usually
	# mean either it is the empty string, or the file has been moved
	# since the user selected it a little while ago.
	if {[catch [list file::getSig $modeAssistant(helperApplication)] sig]} {
	    set sig ""
	}
    }
    
    append t "# Mode declaration.\n"
    append t "#  first two items are: name version\n"
    append t "#  then 'source' means source this file when we first use the mode\n"
    append t "#  then we list the extensions, and any features active by default\n"
    append t "alpha::mode [list $modeAssistant(name)] 0.1 source\
      [list $modeAssistant(extensions)]"
    
    if {[string length $modeAssistant(menuname)]} {
	append t " $modeAssistant(name)Menu"
    } else {
	append t " {}"
    }
    
    append t " \{\n    \# Script to execute at Alpha startup\n"
    if {[string length $modeAssistant(menuname)]} {
	append t "    addMenu $modeAssistant(name)Menu $modeAssistant(menuname)\n"
	if {$modeAssistant(addHelper) && [string length $modeAssistant(helperName)]} {
	    append t "    ensureset $sigName [list $sig]\n" 
	}
    }
    append t "\} uninstall \{\n    this-file\n\} "
    set author [string trim $modeAssistant(author) "\""]
    regsub -all -- {(^\s*<*)|(>*\s*$)} $modeAssistant(email) "" email
    regsub -all -- {(^\s*<*)|(>*\s*$)} $modeAssistant(homePage) "" homePage
    append t "maintainer \{\n    \"${author}\" <${email}>"
    if {[string length $homePage]} {
        append t "\n    <${homePage}>"
    } 
    append t "\n\} help \{\n"
    append t [breakIntoLines [string trim $modeAssistant(helpText)] 77 4]
    append t "\n\}\n\n"
    
    append t "# For Tcl 8\n"
    append t "namespace eval $modeAssistant(name) {}\n\n"
    
    if {[string length $modeAssistant(menuname)]} {
	append t "# This proc is called every time we turn the menu on.\n"
	append t "# Its main effect is to ensure this code, including the\n"
	append t "# menu definition below, has been loaded.\n"
	append t "proc $modeAssistant(name)Menu {} {}\n"
	append t "# Now we define the menu items.\n"
	append t "Menu -n \$$modeAssistant(name)Menu -p $modeAssistant(name)::menuProc \{\n"
	if {$modeAssistant(addHelper) && $modeAssistant(switchhelper)} {
	    append t "    /S<U<OswitchTo$appName\n"
	}
	if {$modeAssistant(addHelper) && $modeAssistant(sendtohelper)} {
	    append t "    /K<U<OsendWindowTo$appName\n"
	}
	append t "    anotherCommand\n"
	append t "\}\n\n"
	append t "# This procedure is called whenever we select a menu item\n"
	append t "proc $modeAssistant(name)::menuProc \{menu item\} \{\n"
	if {$modeAssistant(addHelper)} {append t "    global $sigName\n"}
	append t "    switch -- \$item \{\n"
	if {$modeAssistant(addHelper) && $modeAssistant(switchhelper)} {
	    append t "        switchTo$appName \{app::launchFore \$$sigName\}\n"
	}
	if {$modeAssistant(addHelper) && $modeAssistant(sendtohelper)} {
	    append t "        sendWindowTo$appName \{openAndSendFile \$$sigName\}\n"
	}
	append t "        anotherCommand \{ alertnote {another command} \}\n"
	append t "    \}\n"
	append t "\}\n\n"
    }

    append t "# Mode preferences settings, which can be edited by the user (with F12)\n\n"
    append t "newPref var lineWrap $modeAssistant(lineWrap) [list $modeAssistant(name)]\n\n"
    if {[string length $modeAssistant(funcExpr)]} {
	append t "# These are used by the ::parseFuncs procedure when the user clicks on\n"
	append t "# the {} button in a file edited using this mode.  If you need more sophisticated\n"
	append t "# function marking, you need to add a $modeAssistant(name)::parseFuncs proc\n\n"
	append t "newPref variable funcExpr [list $modeAssistant(funcExpr)] [list $modeAssistant(name)]\n"
	append t "newPref variable parseExpr [list $modeAssistant(parseExpr)] [list $modeAssistant(name)]\n\n"
    }
    set comments {}
    if {[string length $modeAssistant(comments)]} {
	lappend comments -e $modeAssistant(comments)
	append t "# Register comment prefix\n"
	append t "set $modeAssistant(name)::commentCharacters(General) [list $modeAssistant(comments)]\n"
    }
    if {[string length $modeAssistant(multicommentprefix)]} {
	append t "# Register multiline comments\n"
	# So this works with Tcl 7.x
	set e [string index $modeAssistant(multicommentprefix) [expr {[string length $modeAssistant(multicommentprefix)] -1}]]
	set multi [list "$modeAssistant(multicommentprefix) " " $modeAssistant(multicommentsuffix)" " $e "]
	append t "set $modeAssistant(name)::commentCharacters(Paragraph) [list $multi]\n"
	lappend comments -b $modeAssistant(multicommentprefix) $modeAssistant(multicommentsuffix)
    } elseif {[string length $modeAssistant(comments)]} {
	append t "# Register multiline comments\n"
	set multi [list "$modeAssistant(comments) " "$modeAssistant(comments) " "$modeAssistant(comments) "]
	append t "set $modeAssistant(name)::commentCharacters(Paragraph) [list $multi]\n"
    }
    if {[string length [string trim $modeAssistant(keywords)]]} {
	append t "# List of keywords\n"
	append t "set $modeAssistant(name)KeyWords \{\n"
	append t "    $modeAssistant(keywords)\n"
	append t "\}\n\n"
	append t "# Colour the keywords, comments etc.\n"
	append t "regModeKeywords $comments $modeAssistant(name) \$$modeAssistant(name)KeyWords\n"
	append t "# Discard the list\n"
	append t "unset $modeAssistant(name)KeyWords\n\n"
    } else {
	append t "# Colour the comments etc. (there are no keywords in this mode)\n"
	append t "regModeKeywords $comments $modeAssistant(name) \{\}\n"
    }
    
    append t "# To write indentation code for your new mode (so your mode\n"
    append t "# automatically takes advantage of the automatic indentation\n"
    append t "# possibilities of 'tab', 'return' and 'paste'), you can take\n"
    append t "# advantage of the shared proc ::indentLine.  All you need to write\n"
    append t "# is a [set modeAssistant(name)]::correctIndentation proc, and as a\n"
    append t "# starting point you can copy the code of the generic\n"
    append t "# ::correctIndentation, found in indentation.tcl.\n"

    new -n $modeAssistant(name)Mode.tcl -text $t
    
    # Add a "Document Projects" header if possible.
    catch {file::createHeader}
    
    global HOME
    set modeFile [file join $HOME Tcl Modes $modeAssistant(name)Mode.tcl]

    if {[file exists $modeFile]} {
	if {[dialog::yesno "You already have a file named\
	  '[file tail $modeFile]' in Alpha's 'Modes' directory.\
	  Would you like to delete it?"]} {
	    file delete -force $modeFile
	} else {
	    alertnote "If you wish to retain the new mode file, you will\
	      have to save it yourself.  Any changes in the new\
	      file will not take effect unless this file is placed in\
	      Alpha's 'Modes' folder."
	    return
	}
    }
    # In 7.5d8 we fix saveAs so it works properly on Alpha 7.
    saveAs -f $modeFile
    alertnote "Your new mode has been created and saved in Alpha's 'Modes' folder.\
      Next time you quit and restart Alpha, it will notice the extra file, and rebuild\
      the necessary indices so it knows about your mode."
}
