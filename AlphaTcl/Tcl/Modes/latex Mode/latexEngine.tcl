## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "latexEngine.tcl"
 #                                   created: 11/10/1992 {10:42:08 AM}
 #                               last update: 02/13/2005 {02:47:06 PM}
 # Description:
 #
 # Support procedures for various items in TeX mode.
 #
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the main TeX mode file has been loaded.
latex.tcl

proc latexEngine.tcl {} {}

namespace eval TeX {}

##
 # -------------------------------------------------------------------------
 #
 # "TeX::requirePackage" --
 #
 #  Return 1 unless the package wasn't included and the user hit 'cancel',
 #  in which case we return 0.
 #  -------------------------------------------------------------------------
 ##

proc TeX::requirePackage {pkg} {

    # search the document/fileset to ensure we have a 'usepackage'
    # or 'RequirePackage' command for this package.

    set filename [TeX::currentBaseFile]
    set pat {\\(usepackage|RequirePackage)}
    append pat "\{$pkg\}"
    if {[file::searchFor $filename $pat 0] == ""} {
	# search through sub-packages
	set pat2 {^[^\r\n]*\\(usepackage|RequirePackage)\{([^\}]+)\}([^\r\n]*)$}
	set subpkgs [file::findAllInstances $filename $pat2 1]
	foreach f $subpkgs {
	    if ![catch {set sty [TeX::findTeXFile $f ".sty"]}] {
		if {[file::searchFor $sty $pat 0] != ""} {return 1}
	    }
	}
	global TeXmodeVars
	if {$TeXmodeVars(warnIfPackageNotIncluded)} {
	    switch -- [askyesno -c "The '$pkg' package seems not to be included in this LaTeX document.  Shall I insert a 'usepackage' line?"] {
		"yes" {
		    set w [win::Current]
		    placeBookmark
		    TeX::insertInPreamble "\\usepackage\{$pkg\}\r"
		    bringToFront $w
		    returnToBookmark
		}
		"cancel" {
		    return 0
		}			
	    }
	}
    }
    return 1
}

proc TeX::insertInPreamble {text} {

    if {[selectPatternInFile [TeX::currentBaseFile] {\\documentclass(\[[^]]*\])?\{[^\}]*\}} ]} {
	goto [nextLineStart [selEnd]]
	insertText $text
	return 1
    } else {
	alertnote "Can't find the document preamble '\\documentclass...'"
	return 0
    }
}

# Should provide a better approach for 'process windows' in TeX mode
# as a whole, in the future.
proc TeX::currentBaseFile {{currentWin ""}} {
    if {$currentWin eq ""} {
	set currentWin [win::TopNonProcessWindow]
    }
    set currentWin [win::StripCount $currentWin]
    if {[set currentProj [isWindowInFileset $currentWin "tex"]] ne ""} {
	return [texFilesetBaseName $currentProj]
    } else {
	return $currentWin
    }
}

##
 # -------------------------------------------------------------------------
 #	
 # "TeX::ensureSearchPathSet" --
 #	
 #  Make sure TeX mode has built our search path, so we can find
 #  bibliography files.  Perhaps we should have our own variable for these?
 #  -------------------------------------------------------------------------
 ##

proc TeX::ensureSearchPathSet {} {

    global AllTeXSearchPaths

    if {[llength $AllTeXSearchPaths] == 0} {
	status::msg "building TeX search pathÉ"
	set AllTeXSearchPaths [TeX::buildTeXSearchPath]
	status::msg ""
    }
}


##
 # -------------------------------------------------------------------------
 #
 # "TeX::findTeXFile" --
 #
 #  Find a TeX file with given default extension if it exists anywhere on
 #  the TeX search path.
 #  -------------------------------------------------------------------------
 ##

proc TeX::findTeXFile {file {ext ""}} {
    global TeXmodeVars
    
    if {[info exists TeXmodeVars(useKpsewhich)] && $TeXmodeVars(useKpsewhich)} {
	return [TeX::findTeXFileWithKpsewhich $file $ext]
    }
    
    global AllTeXSearchPaths mode

    # Determine absolute file specification
    # Ignore $ext if $file already has an extension
    if {[string length [file extension $file]] == 0} {
	append file $ext
    }
    set filename [file::absolutePath $file]
    if {[file exists $filename]} {
	return $filename
    }
    TeX::ensureSearchPathSet
    foreach folder $AllTeXSearchPaths {
	set filename [file join $folder $file]
	if {[file exists $filename]} {
	    return $filename
	}
    }

    if {$mode == "TeX"} {
	set filename [file join [file dirname [win::Current]] $file]
	if {[file exists $filename]} {
	    return $filename
	}
	# find '\graphicspath{{path}{path}{path}}' if it exists
	if {![catch {search -s -f 1 -r 1 {\\graphicspath\{[^\r\n]*\}} [minPos]} l]} {
	
	    set l [getText [lindex $l 0] [lindex $l 1]]
	    if {![regexp -indices {\{} $l ind]} {
		error "Malformed \\graphicspath"
	    }
	    set l [string range $l [expr [lindex $ind 0] + 1] end]
	    set nesting 1
	    set currentPath [file dirname [win::Current]]
	    set graphicsPaths {}
	    while {$nesting && [regexp -indices {[\{\}]} $l ind]} {
		switch -- [string index $l [set ind [lindex $ind 0]]] {
		    "\{" {
			incr nesting
		    }
		    "\}" {
			if {$nesting == 2} {
			    # graphicspath must have trailing file
			    # separator, but we don't want it
			    set graphicsPath [file dirname \
			      [string range $l 0 [expr $ind - 1]]]
			    # This works whether the path is absolute or
			    # relative.
			    lappend graphicsPath \
			      [file join $currentPath $graphicsPath]
			}
			incr nesting -1
		    }
		}
		set l [string range $l [incr ind] end]
	    }
	    foreach folder $graphicsPaths {
		set filename [file join $folder $file]
		if {[file exists $filename]} {
		    return $filename
		}
	    }
	}
    }

    # Try recursing...
    foreach folder $AllTeXSearchPaths {
	foreach contents [file::recurse $folder] {
	    if {[file tail $contents] eq $file} {
		return $contents
	    }
	}
    }

    error "File not found."
}

# If using teTeX, this is much better!
proc TeX::findTeXFileWithKpsewhich {file {ext ""}} {
    if {[file extension $file] eq ""} {
	append file $ext
    }
    # try in current directory:
    set filename [file::absolutePath $file]
    if {[file exists $filename]} {
	return $filename
    }
    # call kpsewhich, and return its value or error directly.
    set res [exec kpsewhich $file]
    if {$res eq ""} {
	error "File not found."
    }
    set res
}


## 
 # -------------------------------------------------------------------------
 # 
 # "TeX::texApp" --
 # 
 #  Switch to bibtex, latex or makeindex
 # -------------------------------------------------------------------------
 ##

proc TeX::texApp {name} {
    
    set type [string tolower $name]
    global ${type}Sig ${type}AppSignatures
    set supportedApps [array names ${type}AppSignatures]
    foreach app $supportedApps {
	eval lappend sigs [set ${type}AppSignatures($app)]
    }
    set longPrompt "Please locate your ${name} app."
    if {[catch {app::launchAnyOfThese $sigs ${type}Sig $longPrompt} appname]} {
	error "bug in 'app::launchAnyOfThese'"
    }
    set quotedSig "'[string trim [set ${type}Sig] {'}]'"
    switchTo $quotedSig
}

# If the current window is untitled, return its number (i.e., either
# the number 1 or the number  n  in "untitled <n>"); otherwise, return 0.
# By current we mean the top-most window excluding any 'process
# windows'.  (This whole handling of process windows may need to be
# improved in the future).
proc TeX::winUntitled {} {
    set currentWin [win::TopNonProcessWindow]
    if {[win::IsFile $currentWin]} {
	return 0
    } elseif {$currentWin eq "untitled"} { 
	return 1
    } elseif {[regexp -- {^untitled <(\d+)>$} $currentWin "" num] } {
	return $num
    } else {
	# E.g. a shell window.  
	return 0
    }
}

proc TeX::getFormatName {baseFile} {
    
    set baseFormat ""
    set pat        "^%&(\\w+)"
    foreach f [winNames -f] {
	if {[win::StripCount $f] eq $baseFile} {
	    set baseWindow $f
	    set baseWhat   "window"
	    break
	}
    }
    if {[info exists baseWhat]} {
	# The base file is currently open window, so find out if the first
	# line contains the format name.
	set pos0  [minPos]
	set pos1  [nextLineStart -w $baseWindow $pos0]
	set first [string trim [getText -w $baseWindow $pos0 $pos1]]
	regexp $pat $first -> baseFormat
    } elseif {[file isfile $baseFile]} {
	set baseWhat "file"
	# The base file is not open, so get its first line.
	set fileInId [alphaOpen $baseFile]
	gets $fileInId first
	close $fileInId
	regexp $pat [string trim $first] -> baseFormat
    } else {
	# This shouldn't happen, because the base file should default to the
	# current window, but maybe the (closed) base file no longer exists.
	set baseWhat ""
    }
    return [list $baseFormat $baseWhat]
}

# Return a list of folders in which to search for TeX input files,
# including the TeXInputs folder (if it exists) and any folders of the form
# "*input*" in the TeX application directory.  The current folder is not
# included in the list.  Default search depth is two levels deep.
#
# (Note: The TeXInputs folder is assigned from the AppPaths submenu.)
#

proc TeX::buildTeXSearchPath {{depth 2}} {

    global TeXmodeVars texSig

    set folders {}
    # The local 'TeXSearchPath' folder:
    if {[info exists TeXmodeVars(TeXSearchPath)] && \
      [llength $TeXmodeVars(TeXSearchPath)] > 0} {
	foreach path $TeXmodeVars(TeXSearchPath) {
	    lappend folders $path
	    # Search subfolders $depth levels deep:
	    eval lappend folders [file::hierarchy $path $depth]
	}
    }

    # Any "*inputs*" folders in the TeX application folder:
    if {[info exists texSig] && [string length $texSig] > 0} {
	if {![catch {set TeXDir [file dirname [nameFromAppl $texSig]]}]} { 
	    # Problem:  'glob' is case sensitive, macos isn't !
	    foreach folder [glob -nocomplain -type d -dir $TeXDir "*\[Ii\]nputs*"] {
		lappend folders $folder
		# Search subfolders $depth levels deep:
		eval lappend folders [file::hierarchy $folder $depth]
	    }
	    # Now try any folders within a subfolder called 'inputs'
	    foreach folder [glob -nocomplain -type d -dir $TeXDir -join * "*\[Ii\]nputs*"] {
		lappend folders $folder
		# Search subfolders $depth levels deep:
		eval lappend folders [file::hierarchy $folder $depth]
	    }
	}
    }

    return $folders
}


# Extend the argument around the position $from.
# (Args are delimited by commas or curly-braces.)

proc TeX::extendArg {from {to 0}} {

    if {$to == 0} {set to $from}
    set result [list $from $to]
    if {![catch {search -f 0 -r 1 -s -m 0 "\[,\{\]" $from} mtch0]} {
	if {![catch {search -f 1 -r 1 -s -m 0 "\[,\}\]" $to} mtch1]} {
	    set from [lindex $mtch0 1]
	    set to [lindex $mtch1 0]
	    ## Embedded braces in the arg probably mean that the user
	    ## clicked outside a valid command argument
	    if {[regexp "\[\{\}\]" [getText $from $to]] == 0} {
		set result [list $from $to]
	    }
	}
    }
    return $result
}

# Find a LaTeX command with arguments in either direction.  (see
# TeX::findCommandWithArgs in latexMacros.tcl) This version returns the
# positions at which the command options and arguments start, as well.
# 
# Return a list of command start, options start, arguments start
proc TeX::findCommandWithParts {pos direction} {

    set searchString {\\([^@a-zA-Z\t\n\r]|@?[a-zA-Z]+\*?)(\[[^]]*\])*({[^{}]*})?}
    if {![catch {search -s -f $direction -r 1 $searchString $pos} mtch]} {
	set beg [lindex $mtch 0]
	set end [lindex $mtch 1]
	if {![regexp -indices -- $searchString [getText $beg $end] -> cmd opt arg]} {
	    return ""
	}
	if {[lindex $opt 0] == -1} {
	    # No options matched
	    set opt $end
	} else {
	    set opt [pos::math $beg + [lindex $opt 0]]
	}
	if {[lindex $arg 0] == -1} {
	    # No braced arguments matched
	    if {[lookAt $end] eq "\{"} {
		if {![catch {matchIt "\{" [pos::math $end + 1]} newend]} {
		    set end [pos::math $newend +1]
		    regexp -indices -- $searchString \
		      [getText $beg $end] -> cmd opt arg
		}
	    }
	}
	if {[lindex $arg 0] == -1} {
	    # No braced arguments matched
	    set arg $end
	} else {
	    set arg [pos::math $beg + [lindex $arg 0]]
	}
	return [list $beg $opt $arg $end]
    } else {
	return ""
    }
}

#--------------------------------------------------------------------------
# ×××× Insertion routines ×××× #
#--------------------------------------------------------------------------

# Shift each line of $text to the right by inserting a string of
# $whitespace characters at the beginning of each line, returning the
# resulting string.

proc TeX::shiftTextRight {text whitespace} {
    return [doPrefixText "insert" $whitespace $text]
}

# Return an "indented carriage return" if any character preceding the
# insertion point (on the same line) is a non-whitespace character.
# Otherwise, return the null string.

proc TeX::openingCarriageReturn {} {

    set pos [getPos]
    set end $pos
    set start [lineStart $pos]
    set text [getText $start $end]
    if {[is::Whitespace $text]} {
	return ""
    } else {
	return "\r"
    }
}

# Return an "indented carriage return" if any character following the
# insertion point (on the same line) is a non-whitespace character.
# Otherwise, return the null string.

proc TeX::closingCarriageReturn {} {

    set pos [selEnd]
    if {[isSelection] && ([pos::compare $pos == [lineStart $pos]])} {
	return "\r"
    } else {
	set start $pos
	set end [nextLineStart $start]
	set text [getText $start $end]
	if {[is::Whitespace $text]} {
	    return ""
	} else {
	    return "\r"
	}
    }
}

# Insert an object at the insertion point.  If there is a selection and the
# global variable 'deleteObjNoisily' is false, quietly delete the selection
# (like 'paste').  Otherwise, prompt the user for the appropriate action.
# Returns true if the object is ultimately inserted, and false if the user
# cancels the operation.

proc TeX::insertObject {objectName} {

    global TeXmodeVars

    if {[isSelection]} {
	if {$TeXmodeVars(deleteObjNoisily)} {
	    switch -- [askyesno -c "Delete selection?"] {
		"yes"    {deleteText [getPos] [selEnd]}
		"no"     {backwardChar}
		"cancel" {return 0}
	    }
	} else {
	    deleteText [getPos] [selEnd]
	}
    }
    elec::Insertion $objectName
    return 1
}

# Builds and returns a LaTeX environment, that is, a \begin...\end pair,
# given the name of the environment, an argument string, and the
# environment body.  The body should be passed to this procedure fully
# formatted, including indentation.

proc TeX::buildEnvironment {envName envArg envBody trailingComment} {

    append begStruct "\\begin\{" $envName "\}" $envArg
    append endStruct "\\end\{" $envName "\}$trailingComment"
    return [TeX::buildStructure $begStruct $envBody $endStruct]
}

# Builds and returns a fully-formed structure, a string of the form
#
#   <begStruct>
#     <bodyStruct>
#   <endStruct>
#
# For example,
#
#   TeX::buildStructure "if {¥¥} {" "\t¥¥\r" "}"
#
# returns a Tcl if-template.
#

proc TeX::buildStructure {begStruct bodyStruct endStruct} {

    append structure [TeX::openingCarriageReturn] \
      $begStruct "\r" $bodyStruct \
      $endStruct [TeX::closingCarriageReturn]
    return $structure
}

# Inserts a LaTeX environment with the specified name, argument, and body
# at the insertion point.  Deletes the current selection quietly if the
# global variable 'deleteEnvNoisily' is false; otherwise the user is
# prompted for directions.  Returns true if the environment is ultimately
# inserted, and false if the user cancels the operation.

proc TeX::insertEnvironment {envName envArg envBody} {

    global TeXmodeVars

    if {[isSelection]} {
	if {$TeXmodeVars(deleteEnvNoisily)} {
	    switch -- [askyesno -c "Delete selection?"] {
		"yes" {}
		"no" {backwardChar}
		"cancel" {return 0}
	    }
	}
    }
    append begStruct "\\begin{" $envName "}" $envArg
    append endStruct "\\end{" $envName "}¥¥"
    TeX::insertStructure $begStruct $envBody $endStruct
    return 1
}

# Inserts a structure at the insertion point.  Positions the cursor at the
# beginning of the structure, leaving any subsequent action to the calling
# procedure.  Deletes the current selection quietly.

proc TeX::insertStructure {begStruct bodyStruct endStruct} {

    set start [getPos]
    set end [selEnd]
    #set body [TeX::shiftTextRight $bodyStruct [text::indentString $start]]
    elec::ReplaceText $start $end [TeX::buildStructure $begStruct $bodyStruct $endStruct]
}

# Inserts an environment with the given name, argument, and body at the
# insertion point.  If there is currently a selection, cut and paste it
# into the body of the new environment, maintaining proper indentation;
# otherwise, insert a tab stop into the body of the environment.  Returns
# true if there is a selection, and false otherwise.

proc TeX::wrapEnvironment {envName envArg envBody} {

    append begStruct "\\begin{" $envName "}" $envArg
    append endStruct "\\end{" $envName "}¥¥"
    return [TeX::wrapStructure $begStruct $envBody $endStruct]
}

# Inserts a structure at the insertion point.  Positions the cursor at the
# beginning of the structure, leaving any subsequent action to the calling
# procedure.  If there is currently a selection, cut and paste it into the
# body of the new environment, maintaining proper indentation; otherwise,
# insert a tab stop into the body of the environment.  Returns true if
# there is a selection, and false otherwise.

proc TeX::wrapStructure {begStruct bodyStruct endStruct} {
    
    set t [TeX::indentEnvironment]

    set start [getPos]
    set end [selEnd]
    if {[isSelection]} {
	set text [getSelect]
	set textLen [string length $text]
	if {[string index $text [expr {$textLen-1}]] != "\r"} {
	    append text "\r"
	}
	set body [TeX::shiftTextRight $text ${t}]
	append body $bodyStruct
	set returnFlag 1
    } else {
	append body "${t}¥¥\r" $bodyStruct
	set returnFlag 0
    }
    elec::ReplaceText $start $end [TeX::buildStructure $begStruct $body $endStruct]
    return $returnFlag
}

# A generic call to 'TeX::wrapEnvironment' used throughout latex.tcl:

proc TeX::doWrapEnvironment {envName} {

    if {[TeX::wrapEnvironment $envName "" ""]} {
	set msgText "selection wrapped"
    } else {
	set msgText "enter body of $envName environment"
    }
    status::msg $msgText
}

# A generic call to 'TeX::wrapStructure':

proc TeX::doWrapStructure {begStruct bodyStruct endStruct} {

    if {[TeX::wrapStructure $begStruct $bodyStruct $endStruct]} {
	set msgText "selection wrapped"
    } else {
	set msgText "enter body of structure"
    }
    status::msg $msgText
}

# Inserts a structured document template at the insertion point.  Three
# arguments are required: the class name of the document, a preamble
# string, and a string containing the body of the document.  If the
# preamble is null, a generic \usepackage statement is inserted; otherwise,
# the preamble is inserted as is.  This routine does absolutely no
# error-checking (this is totally left up to the calling procedure) and
# returns nothing.

proc TeX::insertDocument {className preamble docBody} {

    set docStr "\\documentclass\[¥¥\]{$className}\r"
    if {$preamble == ""} {
	append docStr "\\usepackage\[¥¥\]{¥¥}\r\r¥¥\r\r"
    } else {
	append docStr $preamble
    }
    append docStr [TeX::buildEnvironment "document" "" $docBody "\r"]
    set start [getPos]
    set end [selEnd]
    elec::ReplaceText $start $end $docStr
    return
}

# Inserts a document template at the insertion point given the class name
# of the document to be inserted.  If ALL of the current document is
# selected, then the routine wraps the text inside a generic document
# template.  If the file is empty, a bullet is inserted in place of the
# document body.  If neither of these conditions is true, no action is
# taken.  Returns true if wrapping occurs, and false otherwise.

proc TeX::wrapDocument {className} {

    global TeXmodeVars

    if {[TeX::isEmptyFile]} {
	append body "\r¥¥\r\r"
	# 		set returnFlag 0
    } else {
	if {[TeX::isSelectionAll]} {
	    set text [getSelect]
	    append body "\r$text\r"
	    # 			set returnFlag 1
	} else {
	    alertnote "nonempty file:  delete text or \'Select All\'\
	      from the Edit menu"
	    return 0
	}
    }
    set docStr "\\documentclass\[¥¥\]{$className}\r"
    append docStr "\\usepackage\[¥¥\]{¥¥}\r\r¥¥\r\r"
    append docStr [TeX::buildEnvironment "document" "" $body "\r"]
    set start [getPos]
    set end [selEnd]
    elec::ReplaceText $start $end $docStr
    # 	return $returnFlag
    return 1
}

#--------------------------------------------------------------------------
# Booleans to determine the location of the insertion point
#--------------------------------------------------------------------------

# Return true if the insertion point is before the preamble, and false
# otherwise.  Define "before the preamble" to be all text to the left of "\"
# in "\documentclass".

proc TeX::isBeforePreamble {} {

    set searchString "\\documentclass"
    set searchResult [search -s -f 1 -r 0 -n $searchString [getPos]]
    if {[llength $searchResult]} {
	return 1
    } else {
	return 0
    }
}

# Return true if the insertion point is in the preamble, and false otherwise. 
# Define "preamble" to be all text to the left of "\" in "\begin{document}",
# but not before the "\" in "\documentclass".

proc TeX::isInPreamble {} {

    set searchString "\\begin\{document\}"
    set searchResult [search -s -f 1 -r 0 -n $searchString [getPos]]
    if {[llength $searchResult]} {
	return 1
    } else {
	return 0
    }
}

# Return true if the insertion point is in the document environment, and
# false otherwise.  Define "document" to be all text between
# "\begin{document}" and "\end{document}", exclusive.

proc TeX::isInDocument {} {

    set pos [getPos]
    set searchString "\\begin\{document\}"
    # adjust for the length of the search string:
    set len [string length $searchString]
    if {[pos::compare $pos < [pos::math [minPos] + $len]]} {
	return 0
    }
    set searchResult [search -s -f 0 -r 0 -n $searchString [pos::math $pos - $len]]
    if {[llength $searchResult]} {
	set searchString "\\end\{document\}"
	set searchResult [search -s -f 1 -r 0 -n $searchString $pos]
	if {[llength $searchResult]} {
	    return 1
	} else {
	    return 0
	}
    } else {
	return 0
    }
}

# Return true if the insertion point is after the document environment, and
# false otherwise.  Define "after the document environment" to be all text
# to the right of "}" in "\end{document}".

proc TeX::isAfterDocument {} {

    set pos [getPos]
    set searchString "\\end\{document\}"
    set searchResult [search -s -f 0 -r 0 -n $searchString $pos]
    if {[llength $searchResult]} {
	set pos1 [lindex $searchResult 0]
	set pos2 [lindex $searchResult 1]
	if {[pos::compare $pos1 <= $pos] && [pos::compare $pos < $pos2]} {
	    return 0
	} else {
	    return 1
	}
    } else {
	return 0
    }
}

# Is the given position inside the given command.  It is assumed the
# actual command text can be found by searching for "\\$command\{".
# Success is defined as 'pos' being somewhere inside the matching
# pair of {} that define the body of the command.
# 
# Returns 1 on success, zero on failure.
# 
# On success, if the optional detailsVar is given, that variable
# is set to a list of three elements: the start of the command (the 
# leading backslash), and the first and last positions which are inside
# the braces.
proc TeX::isInCommand {command pos {detailsVar ""}} {
    set cmdStart [search -s -f 0 -r 0 -n "\\$command\{" $pos]
    if {[llength $cmdStart]} {
	set contentsStart [lindex $cmdStart 1]
	if {[pos::compare $contentsStart <= $pos] \
	  && ![catch {matchIt "\{" $contentsStart} match]} {
	    if {[pos::compare $pos <= $match]} {
		if {$detailsVar ne ""} {
		    upvar 1 $detailsVar local
		    lappend cmdStart $match
		    set local $cmdStart
		}
		return 1
	    }
	}
    }
    return 0
}

# Obsolete?

proc TeX::isInMathMode {} {

    set pos [getPos]
    # Check to see if in LaTeX math mode:
    set searchString {\\[()]}
    set searchResult1 [search -s -f 0 -r 1 -n $searchString [pos::math $pos - 1]]
    if {[llength $searchResult1]} {
	set delim1 [eval getText $searchResult1]
    } else {
	set delim1 "none"
    }
    set searchResult2 [search -s -f 1 -r 1 -n $searchString $pos]
    if {[llength $searchResult2]} {
	set delim2 [eval getText $searchResult2]
    } else {
	set delim2 "none"
    }
    set flag1 [expr [string match {none} $delim1] && [string match {\\)} $delim2]]
    set flag2 [expr [string match {\\(} $delim1] && [string match {none} $delim2]]
    set flag3 [expr [string match {\\(} $delim1] && [string match {\\)} $delim2]]
    set flag4 [expr [string match {\\(} $delim1] && [string match {\\(} $delim2]]
    set flag5 [expr [string match {\\)} $delim1] && [string match {\\)} $delim2]]
    if {$flag3} {
	return 1
    } elseif {$flag1 || $flag2 || $flag4 || $flag5} {
	set messageString "unbalanced math mode delimiters"
	beep
	alertnote $messageString
	error "TeX::isInMathMode:  $messageString"
    }
    # Check to see if in LaTeX displaymath mode:
    set searchString {[^\\]\\\[|\\\]}
    set searchResult1 [search -s -f 0 -r 1 -n $searchString [pos::math $pos - 1]]
    if {[llength $searchResult1]} {
	set begPos [lindex $searchResult1 0]
	set endPos [lindex $searchResult1 1]
	if {[lookAt [pos::math $endPos - 1]] == "\["} {
	    set delim1 [getText [pos::math $begPos + 1] $endPos]
	} else {
	    set delim1 [eval getText $searchResult1]
	}
    } else {
	set delim1 "none"
    }
    set searchResult2 [search -s -f 1 -r 1 -n $searchString $pos]
    if {[llength $searchResult2]} {
	set begPos [lindex $searchResult2 0]
	set endPos [lindex $searchResult2 1]
	if {[lookAt [pos::math $endPos - 1]] == "\["} {
	    set delim2 [getText [pos::math $begPos + 1] $endPos]
	} else {
	    set delim2 [eval getText $searchResult2]
	}
    } else {
	set delim2 "none"
    }
    set flag1 [expr [string match {none} $delim1] && [string match {\\\]} $delim2]]
    set flag2 [expr [string match {\\\[} $delim1] && [string match {none} $delim2]]
    set flag3 [expr [string match {\\\[} $delim1] && [string match {\\\]} $delim2]]
    set flag4 [expr [string match {\\\[} $delim1] && [string match {\\\[} $delim2]]
    set flag5 [expr [string match {\\\]} $delim1] && [string match {\\\]} $delim2]]
    if {$flag3} {
	return 1
    } elseif {$flag1 || $flag2 || $flag4 || $flag5} {
	set messageString "unbalanced math mode delimiters"
	beep
	alertnote $messageString
	error "TeX::isInMathMode:  $messageString"
    }
    # Check to see if in math environment:
    set envName [TeX::extractCommandArg [eval getText [TeX::searchEnvironment]]]
    global mathEnvironments
    if {[lsearch -exact $mathEnvironments $envName] == -1} {
	return 0
    } else {
	return 1
    }
}

#--------------------------------------------------------------------------
# ×××× Dissecting LaTeX commands ×××× #
#--------------------------------------------------------------------------

# Given a LaTeX command string, extract and return the command name.

proc TeX::extractCommandName {commandStr} {

    if {[regexp {\\([^@a-zA-Z\t\n\r]|@?[a-zA-Z]+\*?)} $commandStr dummy commandName]} {
	return $commandName
    } else {
	return ""
    }
}

# Given a LaTeX command string with at most one required argument and no
# embedded carriage returns, extract and return the argument.  (Note: this
# proc needs more testing.)

proc TeX::extractCommandArg {commandStr} {

    if {[regexp {\{(.*)\}} $commandStr dummy arg]} {
	return $arg
    } else {
	return ""
    }
}

#--------------------------------------------------------------------------
# An environment search routine
#--------------------------------------------------------------------------

# Search for the closest surrounding environment and return a list of two
# positions if the environment is found; otherwise return the empty list.
# Assumes the LaTeX document is syntactically correct.  The command 'eval
# select [TeX::searchEnvironment]' selects the "\begin" statement (with
# argument) of the surrounding environment.

proc TeX::searchEnvironment {} {

    watchCursor
    set pos [getPos]
    if {[pos::compare $pos == [minPos]]} {
	return [list $pos $pos]
    }
    # adjust position if insertion point is contained in "\end{...}"
    set searchPos [pos::math $pos - 1]
    set searchString {\\end\{[^\{\}]*\}}
    set searchResult [search -s -f 0 -r 1 -n $searchString $searchPos]
    if {[llength $searchResult]} {
	set pos1 [lindex $searchResult 0]
	set pos2 [lindex $searchResult 1]
	if {[pos::compare $pos1 < $pos] && [pos::compare $pos < $pos2]} {
	    set searchPos [pos::math $pos1 - 1]
	}
    }
    # begin reverse search:
    set searchString {\\(begin|end)\{[^\{\}]*\}}
    set searchResult [search -s -f 0 -r 1 -n $searchString $searchPos]
    if {[llength $searchResult]} {
	set text [eval getText $searchResult]
    } else {
	return [list $pos $pos]
    }
    set depthCounter 0
    set commandName [TeX::extractCommandName $text]
    while {$commandName == "end" || $depthCounter > 0} {
	if {$commandName == "end"} {
	    incr depthCounter
	} else {
	    incr depthCounter -1
	}
	set searchPos [pos::math [lindex $searchResult 0] - 1]
	set searchResult [search -s -f 0 -r 1 -n $searchString $searchPos]
	if {[llength $searchResult]} {
	    set text [eval getText $searchResult]
	} else {
	    return [list $pos $pos]
	}
	set commandName [TeX::extractCommandName $text]
    }
    return $searchResult
}

#--------------------------------------------------------------------------
# ×××× Misc ×××× #
#--------------------------------------------------------------------------

# Returns true if the entire window is selected, and false otherwise.

proc TeX::isSelectionAll {} {
    return [expr {([pos::compare [getPos] == [minPos]]) && ([pos::compare [selEnd] == [maxPos]])}]
}

# Checks to see if the current window is empty, except for whitespace.

proc TeX::isEmptyFile {} {
    return [is::Whitespace [getText [minPos] [maxPos]]]
}

# If there is a selection, make sure it's uppercase.  Otherwise, check to
# see if the character after the insertion point is uppercase.

proc TeX::isUppercase {} {

    if {[isSelection]} {
	set text [getSelect]
    } else {
	set text [lookAt [getPos]]
    }
    return [expr {[string toupper $text] == $text}]
}

# If there is a selection, make sure it's alphabetic.  Otherwise, check to
# see if the character after the insertion point is alphabetic.

proc TeX::isAlphabetic {} {

    if {[isSelection]} {
	set text [getSelect]
    } else {
	set text [lookAt [getPos]]
    }
    return [regexp {^[a-zA-Z]+$} $text]
}

# ???  Perhaps just a filtering proc that makes elec insertions work better?
proc TeX::checkMathMode {args} {}

# ==========================================================================
#
# .