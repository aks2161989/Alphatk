## -*-Tcl-*-
 # ==========================================================================
 # Vince's Additions - an extension package for Alpha
 #
 # FILE: "bibAdditions.tcl"
 #                                   created: 08/06/1995 {04:23:11 PM}
 #                               last update: 03/21/2006 {01:58:33 PM}
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #
 # This file is part of the package "Vince's Additions".  See its
 # documentation for more details.
 #
 # This file contains basic utility procedures used by the bibliography
 # tools so they work both under Alpha and under more general (e.g. Unix)
 # Tcl interpreters.
 #
 # Bug reports and feature requests to: <mailto:vince@santafe.edu>
 # ==========================================================================
 ##

##
 # In case we wish to use auto-loading: just call this procedure to ensure
 # 'bibAdditions.tcl' is loaded.
 ##

proc bibAdditions.tcl {} {}

# Check if we're using Alpha, and if so sort out the interface
if {![catch {alpha::package exists Alpha}]} {
    # only do this first time we're sourced
    set vince_usingAlpha [alpha::package exists Alpha]
} else {
    set vince_usingAlpha 0
}

##
 # Given an input file name, an output extension, a set of possible input
 # extensions, a possible output file name, and a possible mapping from
 # abbreviated input extensions to full extensions, this procedure will
 # make sure the input file exists (either as given or with one of the
 # extensions attached), will generate the output file name if necessary,
 # and will return the full extension of the input file.
 #
 # See my 'proc bibConvert' for an example of using this procedure.
 ##

proc vince_parseFileNames {fileIn outExt extList {fileOut default} {abbrev ""}} {
    
    global vince_usingAlpha
    
    if {[set extension [file extension $fileIn]] != ""} {
	if {![file exists $fileIn]} {
	    vince_message "Input file '$fileIn' does not exist"
	    return
	} else {
	    # We have an extension, and file exists.  We don't care if it's
	    # in the extList, but do care if it's in the abbreviation
	    # list.
	    if {$abbrev != ""} {
		upvar 1 $abbrev extArray
		set e [string range $extension 1 end]
		if {[info exists extArray($e)]} {
		    set extension $extArray($e)
		}
	    }
	}
    } else {
	# No extension was supplied, we must generate our own
	if {$abbrev != ""} {
	    set fileExt [vince_findFile $fileIn $abbrev 1]
	} else {
	    set fileExt [vince_findFile $fileIn $extList 0]
	}
	if {[llength $fileExt]} {
	    set fileIn    [lindex $fileExt 0]
	    set extension [lindex $fileExt 1]
	} else {
	    vince_message "Couldn't find an appropriate existing extension for '$fileIn'"
	    set extension ""
	}
    }
    # Now we have both 'fileIn' and 'extension'.  Just need 'fileOut'
    if {$fileOut == "default"} {
	set fileOut [file rootname $fileIn].$outExt
    }
    return [list $fileIn $fileOut $extension]
}

##
 # Used	by the above procedure.
 #
 # Given an input file name and a set of possible extensions or
 # abbreviated extension mappings, this procedure will find the correct
 # input file if it exists.
 ##

proc vince_findFile {fileIn extList isArray} {

    if {$isArray} {
	upvar 1 $extList extAbbrevs
	# if we have an abbreviation list
	foreach suf [array names extAbbrevs] {
	    if {[file exists ${fileIn}.${suf}]} {
		return [list ${fileIn}.${suf} $extAbbrevs($suf)]
	    }
	}
    } else {
	# else use the full extensions
	foreach suf $extList {
	    if {[file exists ${fileIn}.${suf}]} {
		return [list ${fileIn}.${suf} $suf]
	    }
	}
    }

    return ""
}

proc vince_open {args} {

    global vince_usingAlpha

    if {$vince_usingAlpha} {
	eval alphaOpen $args
    } else {
	eval open $args
    }
}

# ×××× -------- ×××× #

##
 # The following procedures are here so that this code can be used without
 # Alpha being present (perhaps under Tickle or on a unix workstation).
 ##

proc vince_message {msg {killProcedure "0"}} {

    global vince_usingAlpha

    if {$vince_usingAlpha} {
	status::msg $msg
    } else {
	puts $msg
    }
    if {$killProcedure} {return -code return}
}

proc vince_askyesno {text} {

    global vince_usingAlpha

    if {$vince_usingAlpha} {
	return [askyesno $text]
    } else {
	puts $text
	gets stdin yes
	return $yes
    }
}

proc vince_getFile {text {action ""}} {
    
    global vince_usingAlpha
    
    if {$vince_usingAlpha} {
	# find window
	if {[set fname [win::StripCount [win::Current]]] == ""} {
	    if {[catch {getfile $text} fname]} {
		error "cancel"
	    } 
	    switch -- $action {
		"edit" {edit -c $fname}
	    }
	}
	cd [file dirname $fname]
    } else {
	puts $text
	gets stdin fname
	cd [file dirname $fname]
    }
    return [file tail $fname]
}

# ×××× -------- ×××× #

# These last two are specific to the bibConvert package.

proc vince_bibConvertDialog {} {
    
    global vince_usingAlpha bibConvertVars bibConvert::types
    
    if {!$vince_usingAlpha} {return}

    # We're using Alpha, so we're going to be more sophisticated here about
    # selections, and the output will be saved in a temp file and dealt
    # with later.  No need to upvar or return values here because all of
    # the relevant info should already be in the 'bibConvertVars' and we're
    # just sneaking some new information in there before scanning.
    
    # These prefs are only used in these two Alpha-specific procs.
    if {![info exists bibConvertVars(insertAction)]} {
	set bibConvertVars(insertAction) "Create New Window"
    } 
    if {![info exists bibConvertVars(tempFileCount)]} {
	set bibConvertVars(tempFileCount) 0
	# Save these prefs between editing sessions.  If we're setting
	# the 'tempFileCount' for the first time, we know that these have
	# not yet been added to the 'modified' list.
	foreach pref [list "insertAction" "lastBibType" "truncateYear" \
	  "authorTag" "handleAbstract"] {
	    prefs::modified bibConvertVars($pref)
	}
	unset pref
    } 

    set count   [incr bibConvertVars(tempFileCount)]
    set tempDir [temp::directory bibConvert]
    set winTail [win::StripCount [win::CurrentTail]]
    set suffix  [string tolower [string trimleft [file extension $winTail] "."]]
    set bibConvertVars(fileOut)  [file join $tempDir temp${count}.bib]
    set bibConvertVars(saveName) [file rootname $winTail]
    
    # Make sure that we have a valid type available for the dialog.
    if {[lsearch [set bibConvert::types] $suffix] != "-1"} {
	set bibType $suffix
    } else {
	set bibType $bibConvertVars(lastBibType)
    }
    # Get some additional options.
    if {[llength [winNames]]} {
	if {[isSelection]} {
	    # Put the selection in a new temp file, which will become the new
	    # 'fileIn' variable.
	    set count    [incr bibConvertVars(tempFileCount)]
	    set fileIn   [file join $tempDir temp${count}.${suffix}]
	    set fileInId [alphaOpen $fileIn w]
	    set bibConvertVars(fileIn) $fileIn
	    puts $fileInId [getSelect]
	    close $fileInId
	    # And insert options specific to location of selection.
	    set insertOptions [list "Above Selection" "Below Selection" \
	      "Replacing Selection" "-"]
	}
	lappend insertOptions "At Beginning Of Window" "At End Of Window" "-" \
	  "Replacing Window Contents"
    } 
    lappend insertOptions "In New Window"
    if {[lsearch $insertOptions $bibConvertVars(insertAction)] == "-1"} {
	set insertAction "In New Window"
    } else {
	set insertAction $bibConvertVars(insertAction)
    }
    # How should we handle abstracts?
    set handleAbstract  $bibConvertVars(handleAbstract)
    set abstractOptions [list "Included in 'annote' field" \
      "Included in 'abstract' field" "Ignored"]
    # How should the author be handled in the citekey tag?
    set authorTag     $bibConvertVars(authorTag)
    set authorOptions [list "First Author's Surname" "Each Author's Surname"]
    # How should the year be handled in the citekey tag?
    set truncateYear $bibConvertVars(truncateYear)


    set     d1 [list dialog::make -title "Convert To Bib"]
    lappend d2 "Basic Conversion Settings"
    lappend d2 [list [list menu ${bibConvert::types}] "Original Bibliography Format:" $bibType]
    lappend d2 [list [list menu $insertOptions] "Insert Results:" $insertAction]
    lappend d3 "Advanced Conversion Settings"
    lappend d3 [list [list menu $abstractOptions] "Abstracts should be:" $handleAbstract]
    lappend d3 [list [list menu $authorOptions] "Citekey should include:" $authorTag]
    lappend d3 [list flag "Strip Century in Citekey tag" $truncateYear]
    set values [eval $d1 [list $d2 $d3]]
    
    set count 0
    foreach pref [list "bibType" "insertAction" "handleAbstract" "authorTag" \
      "truncateYear"] {
	set bibConvertVars($pref) [lindex $values $count]
	incr count
    } 
}

proc vince_bibConvertInsert {} {

    global vince_usingAlpha bibConvertVars

    if {!$vince_usingAlpha} {return}
    
    set fileOut $bibConvertVars(fileOut)
    
    if {![file exists $fileOut] || [file size $fileOut] == "0"} {
	error "Cancelled -- conversion results are empty."
    } else {
	regsub -all "\r?\n" [file::readAll $fileOut] "\r" newText
    }
    # Note that we check the 'read-only' status mainly because we could be
    # dealing with 'example' windows which are initially locked.
    set wC [win::Current]
    switch -- $bibConvertVars(insertAction) {
	"In Temporary File" {
	    edit -c $fileOut
	}
	"Above Selection"  {
	    if {[win::getInfo $wC read-only]} {setWinInfo read-only 0} 
	    goto [set pos [lineStart [getPos]]]
	    insertText -w $wC $newText ; goto $pos
	    selectText $pos [pos::math $pos + [string length $newText]]
	}
	"Below Selection"  {
	    if {[win::getInfo $wC read-only]} {setWinInfo read-only 0} 
	    goto [set pos [lineStart [selEnd]]]
	    insertText -w $wC $newText ; goto $pos
	    selectText $pos [pos::math $pos + [string length $newText]]
	}
	"Replacing Selection"       {
	    if {[win::getInfo $wC read-only]} {setWinInfo read-only 0} 
	    replaceText -w $wC [set pos [getPos]] [selEnd] $newText
	    if {![isSelection]} {
		selectText $pos [pos::math $pos + [string length $newText]]
	    } 
	}
	"At Beginning Of Window" {
	    goto [minPos]
	    insertText -w $wC $newText\r ; goto [minPos]
	}
	"At End Of Window" {
	    goto [set pos [maxPos]]
	    insertText -w $wC \r$newText ; goto $pos
	}
	"Replacing Window Contents" {
	    if {[win::getInfo $wC read-only]} {setWinInfo read-only 0} 
	    replaceText -w $wC [minPos] [maxPos] $newText ; goto [minPos]
	}
	"In New Window"       {
	    set newName "$bibConvertVars(saveName).bib"
	    new -n $newName -m "Bib" -text $newText
	    goto [minPos]
	}
	default {
	    error "Cancelled -- unknown action option:\
	      $bibConvertVars(insertAction)"
	}
    }
}

# ===========================================================================
# 
# .