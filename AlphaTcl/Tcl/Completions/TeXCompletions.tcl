## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "TeXCompletions.tcl"
 #                                   created: 02/26/1996 {02:27:17 pm}
 #                               last update: 02/23/2006 {04:48:50 PM}
 # Description:
 #
 # Support for electric completion/expansion.
 #
 # Adds completion routines for TeX mode.  This includes reference (\label)
 # completion, citation completion, environment completion, environment item
 # insertion.
 #	
 # Cool new feature: the '{' key is bound to electric completion.  This means
 # you can just type as normal in most circumstances, and when you hit '{',
 # if the previous text is capable of being extended as a command (e.g.
 # \begin, \frac, ...), then it is!
 #
 # modified by  rev reason
 # -------- --- --- -----------
 # 18/12/97 VMD 1.1 added TeX::IncludeFile completions, better handling of '*'
 # 14/01/98 VMD 1.2 Env completion rewritten, some in core latex mode
 # 28/01/98 VMD 1.3 huge thanks to Pierre Basso for improvements.
 # 
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the main TeX mode file has been loaded.
latex.tcl

proc TeXCompletions.tcl {} {}

namespace eval TeX {
    
    # Back compatibility.
    if {[info exists ::TeXmodeVars(acceptAnyTeXEnvironment))] \
      || [info exists ::TeXmodeVars(promptToCreateTeXEnvironment)]} {
	# "acceptAnyTeXEnvironment" and "promptToCreateTeXEnvironment" are
	# now combined into a single variable preference.
	if {[info exists ::TeXmodeVars(acceptAnyTeXEnvironment)] \
	  && !$::TeXmodeVars(acceptAnyTeXEnvironment)} {
	    set newPrefValue 0
	} elseif {[info exists ::TeXmodeVars(promptToCreateTeXEnvironment)] \
	  && !$::TeXmodeVars(promptToCreateTeXEnvironment)} {
	    set newPrefValue 1
	}
	if {[info exists newPrefValue]} {
	    set ::TeXmodeVars(unknownEnvironmentCompletions) $newPrefValue
	    prefs::modified ::TeXmodeVars(unknownEnvironmentCompletions)
	    unset newPrefValue
	}
	prefs::removeObsolete ::TeXmodeVars(acceptAnyTeXEnvironment) \
	  ::TeXmodeVars(promptToCreateTeXEnvironment)
    }
    # Completion & Expansion routines
    ensureset ::completions(TeX) [list \
      BeginContraction Env Cmd Electric Reference Cite Word]

    ensureset ::expanders(TeX) [list ExCmd]
    
}

# ×××× Preferences ×××× #

# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    0 TeX
# Turn this item on to allow electric contraction completions to begin when
# typing a left brace, as in "b'equ{" -- this requires the "Electric Braces"
# feature to be activated||Turn this item off to never use the '{' key for
# electric contraction completions
newPref flag electricLeftContractions        "1" TeX
# Turn this item on to show a list of all possible reference completions
# rather than cycling through them one by one.||Turn this item off to
# cycle through possible reference completions one by one, rather than
# showing a list of all possible completions.
newPref flag listForRefCompletion 0 TeX
# Turn this item on to always show titles along with citekeys during an
# electric citation completion.  This uses the BibDatabase||Turn this item
# off to only use citekeys as hints during an electric citation completions. 
# This uses the BibIndex
newPref flag showTitlesWithTeXCiteCompletion "1" TeX

# When attempting to complete an environment which is not recognized, the
# unknown environment can be ignored, completed with an empty template, or
# prompt you for a new template to be saved between editing sessions.
newPref var  unknownEnvironmentCompletions      "2" TeX "" [list \
  "Are rejected, ending completion" \
  "Insert an empty template" \
  "Prompt for a new template" ] index

# Additional prefs for the sorted dialog.
prefs::dialogs::setPaneLists "TeX" "Electrics" [list \
  "electricBraces" \
  "electricLeftContractions" \
  "listForRefCompletion" \
  "showTitlesWithTeXCiteCompletion" \
  "unknownEnvironmentCompletions" \
  ]

# ×××× extra invoker key ×××× #

proc TeX::electricLeft {} {
    global TeXmodeVars
    set p [getPos]
    if {$TeXmodeVars(electricLeftContractions)} {
	catch {TeX::Completion::BeginContraction}
    }
    if {[pos::compare [getPos] == $p]} {
	completion::reset
	# First try to perform electric completions
	if {![catch {TeX::Completion::Electric} ok] && $ok} {
	    return
	}
	# Second try to perform reference completions
	if {![catch {set lastWord [completion::lastWord]}] \
	  && [string index $lastWord 0] eq "\\" \
	  && [lsearch -exact $TeXmodeVars(refCommands) \
	  [string range $lastWord 1 end]] != -1} {
	    catch {TeX::Completion::Reference}
	}
    }
    # If the position hasn't changed, then let's just type
    # the opening brace, since it seems nothing happened above.
    if {[pos::compare [getPos] == $p]} {
	insertText "\{"
    }
}

proc TeX::electricRight {} {
    insertText "\}"
    catch {blink [matchIt "\}" [pos::math [getPos] - 2]]}
}

# ×××× Completions ×××× #

namespace eval TeX::Completion {}

##
 # -------------------------------------------------------------------------
 #
 # "TeX::Completion::BeginContraction" --
 #
 # The idea here is to see if you see a hint in the form of "b'<some-word>",
 # if so replace the "b'" with "\begin ".  We go to a little trouble here to
 # ensure that the positions are correct since 'replaceText' 'deleteText'
 # 'insertText' might have slight nuances depending on Alpha version and
 # platform -- shouldn't be the case, but there are still bugs ... 
 # -------------------------------------------------------------------------
 ##

proc TeX::Completion::BeginContraction {} {

    set lastword [completion::lastTwoWords leadingHint]
    if {($leadingHint ne "b'")} {
	return 0
    }
    set pos0 [getPos]
    backwardWord
    set pos1 [getPos]
    set evironmentHint [getText $pos1 $pos0]
    deleteText [set pos2 [pos::math $pos1 - 2]] $pos0
    goto $pos2
    insertText "\\begin"
    goto [pos::math $pos2 + 6]
    # We must restart the completions, because the current position has
    # moved.
    completion::reset
    TeX::Completion::Electric "begin"
    # Again we must restart completions, although in this case we could
    # perhaps do the 'typeText' inside a completion callback, which would
    # remove the problem.
    typeText $lastword
    completion::reset
    return 0
}

##
 # --------------------------------------------------------------------------
 #	
 # "TeX::Completion::Env" --
 #	
 # Complete the contents of a \begin...\end pair as appropriate.  Uses the
 # TeXbodies array.  You can type
 # 
 #     \begin<Complete>figure<Complete>
 #     
 # (for example) or just
 # 
 #     \begin{figure}<Complete>
 #     
 # or, making use of [TeX::BeginContraction],
 # 
 #     b'figure
 # 
 # If the user has set the appropriate preferences, s/he will be prompted to 
 # create a template for unrecognized environments.
 # 
 # --------------------------------------------------------------------------
 ##

proc TeX::Completion::Env {} {
    
    global TeXmodeVars TeXbodies

    set envHint [completion::lastTwoWords begin]
    if {($begin ne "\\begin\{")} {
	return 0
    }
    regexp -- {^(.*)\}$} $envHint -> envHint
    set envNames [completion::fromList $envHint TeXenvironments]
    # Determine the name the environment.
    if {[llength $envNames]} {
	set envName [completion::Find $envHint $envNames]
    } elseif {[info exists TeXbodies($envHint)]} {
	# We already have a body defined for this command.
	set envName $envHint
    }
    if {![info exists envName]} {
        # We're dealing with an unknown environment.
	switch -- $TeXmodeVars(unknownEnvironmentCompletions) {
	    "0" {
		# No body defined, and we don't accept new ones.
		return 0
	    }
	    "1" {
		# No body defined, but we allow it and insert an empty template.
		status::msg "Warning: unrecognized environment"
		set envName $envHint
	    }
	    "2" {
		# Prompt to create a new body template.
		if {![catch {TeX::addNewEnvironment $envHint}]} {
		    # We successfully created a new body.
		    set envName $envHint
		} else {
		    # We attempted to create a new body but cancelled.
		    set envName ""
		}
	    }
	}
    }
    # At this point, we should have "envName" defined.
    if {($envName eq "") || ($envName eq 1)} {
	# No match, or we completed or cancelled somewhere, so move on.
	completion::reset
	return 1
    } elseif {![ring::type]} {
	# "Better Templates" is not turned on.  Delete the stop of the
	# "\end{¥}".  The following search should actually rather be done
	# non-regexp, but there seems to be some problems with that...
	endOfLine
	set pos  [getPos]
	set posL [pos::math $pos + 300]
	set pat  {\end{¥}}
	if {![catch {search -s -f 1 -m 0 -r 0 -l $posL $pat $p} place]} {
	    eval replaceText $place {\\end\{} [list $envName] "\}"
	}
	goto $pos
	completion::reset
	return [elec::findCmd $envName TeXbodies ""]
    } else {
	# "Better Templates" is turned on.
	if {![ring::TMarkAt "environment name" \
	  [pos::math [getPos] - [string length $envName]]]} {
	    # We probably typed '\begin{name}' all in one go
	    set i "¥¥"
	    if {[lookAt [pos::math [getPos] - 1]] ne "\}"} {
		append i "\}"
	    }
	    append i "\r\\end\{${envName}\}\r¥¥"
	    elec::Insertion $i
	    endOfLine
	} else {
	    # Thanks to Craig for this simplicity:
	    ring::replaceStopMatches "end environment" $envName
	    ring::replaceStopMatches "body" ""
	}
	endOfLine
	completion::reset
	set retVal [elec::findCmd $envName TeXbodies ""]
	# Delete the stop of "\begin{¥}" We do this afterwards, otherwise we
	# lose the nesting of templates, which is bad.
	ring::-
	ring::deleteStopAndMove
	# Have to restart in case the position has moved.
	completion::reset
	return $retVal
    }
}

##
 # -------------------------------------------------------------------------
 #	
 # "TeX::Completion::Cmd" --
 #	
 # Takes account of the backslash which commands in TeX use
 # -------------------------------------------------------------------------
 ##

proc TeX::Completion::Cmd {} {

    set cmd [completion::lastWord pos]
    if {[regexp {^\\([^\*]*)\*?$} $cmd "" cmd]} {
	return [completion::cmd $cmd]
    } else {
	return 0
    }
}

proc TeX::Completion::Insert {what} {
    insertText "\\${what}"
    bind::Completion
}

##
 # -------------------------------------------------------------------------
 #	
 #	"TeX::Completion::Electric"	--
 #	
 # An example of calling the completion::electric procedure.  In TeX mode,
 # '{¥¥}¥¥' is a good default.
 # -------------------------------------------------------------------------
 ##

proc TeX::Completion::Electric { {cmd ""} } {

    if {![string length $cmd]} {
	if {[containsSpace $cmd]} { return 0 }
	set cmd [completion::lastWord]
    }
    if {[regexp {^\\([^\*]*)\*?$} $cmd "" cmd]} {
	# Nothing
    } elseif {[regexp {\]\{?$} $cmd got]} {
	# We might have an optional [...] after the command we really want.
	# This should work but doesn't (Alpha bug)!
	#{matchIt "]" [pos::math [getPos] - [expr 1 + [string length $got]]]}
	if {![catch {search -s -f 0 -r 0 -m 0 "\[" [getPos]} where]} {
	    set p [getPos]
	    goto [lindex $where 0]
	    if {[catch {set cmd [completion::lastWord]}]} {
	    } else {
		regexp {^\\([^\*]*)\*?$} $cmd "" cmd
	    }
	    goto $p
	}
    }
    return [completion::electric $cmd "\{¥¥\}¥¥"]
}


##
 # -------------------------------------------------------------------------
 #	
 # "TeX::Completion::Reference"	--
 #	
 # If we're in any kind of reference, search for appropriate labels to get
 # the information from and fill them in.
 # 
 # looks if we are inside a \ref{foo (or similar cross reference construct), 
 # and if so, seeks label definitions starting with foo, and completes the 
 # reference.  foo may be empty and in that case the opening brace can be 
 # absent too; then all labels in the document are cycled.
 #
 # (This version of TeX::Completion::Reference does not rely on word 
 # definition.  Instead it is based on braces --- just like TeX.
 # -------------------------------------------------------------------------
 ##

proc TeX::Completion::Reference {} {   
    set code [catch {
	# build this: \\(ref|eqref|pageref|vref|vpageref) :
	global TeXmodeVars
	set refExpr "\\\\([join $TeXmodeVars(refCommands) |])"
	append refExpr {(\{[^\{\}\r\n]*)?$}
	set pos [getPos]
	set t [getText [lineStart $pos] $pos]
	if { [regexp -- $refExpr $t got refType labelStart ] } {
	    # got:          the whole hint, e.g. "\pageref\{Th"
	    # refType:      e.g. "pageref"  (dummy variable)
	    # labelStart:   what we will actually look for, e.g.  "\{Th"
	    set looking "\\label$labelStart"
	    if { $labelStart eq "" } {
		# the hint was of type "\pageref" (without opening
		# brace).  This means we want to complete with both
		# the opening and closing braces, so both of these
		# are in the pattern
		set pat {( +[a-zA-Z]| *\{[^\}\r\n]*)\}}
		set labelBrace 0
	    } else {
		# the hint was of the type '\pageref{foo|}' (which
		# most likely already has a brace just ahead, for
		# example when the user selects the '\ref' menu item
		# in TeX mode).  Therefore we don't want to add
		# a trailing brace when we complete.
		set pat {[^\}\r\n]*}
		set labelBrace 1
	    }
	} else {	
	    set res 0
	}
	if {![info exists res]}  {
	    if {!$TeXmodeVars(listForRefCompletion) }  {
		# Cycle through all completions:
		set res [completion::general \
		  -excludeBefore [string length $got] \
		  -pattern $pat \
		  -word 0 \
		  -- $looking] 
	    } else {
		# Present a list of possible completions:

		# Get the list of labels matching looking
		set refList [_findAllLabels $looking $pat $labelBrace]
		# check that we have some match
		if {![llength $refList]} {
		    set match $labelStart
		    set msg "No matching label."
		    set labelBrace 0
		} else {
		    # unique match
		    if {[llength $refList] == 1 } {
			set match [lindex $refList 0]
			set msg "Unique matching label \"$match\"."
		    } else {
			# multiple matching labels
			set caption "Pick a completion\
			  (from [llength $refList] matching labels)"
			# pick the completion, the selected by default is 
			# the last one in order to have a behaviour similar to the 
			# old mode (otherwise remove the -L)
			set lastLabel [quote::Regfind [lindex $refList end]]
			if {[catch {listpick -w 550 -h 300 -p $caption \
			  -L $lastLabel $refList} match] \
			  || $match eq "------------------------" } {
			    status::msg "Cancelled"
			    return 1
			}
			set msg ""    
		    }
		}
		completion::reset
		set deltext [expr {[string length $labelStart] - $labelBrace}]
		# complete the \ref command
		completion::action -text "$match" -delete $deltext -msg $msg
		set res 1
	    }
	}
    } err]    
    if {!$code} {
	return $res
    }
    return -code $code $err
}

proc TeX::Completion::_findAllLabels {looking pat labelBrace} {
    set listLabels [list]
    set start [minPos]
    # define pat 2 as to match the full label
    set pat2 [quote::Regfind $looking]
    append pat2 $pat
    # keep searching labels until we don't find any
    while {![catch {search -s -f 1 -r 1 -i 0 -m 0 -- $pat2 $start} data]} {
	# get the text after \ref or after the brace, depending
	# on labelBrace
	set beg [pos::math [lindex $data 0] + 6 + $labelBrace]
	set end [lindex $data 1]
	if {![pos::compare $beg > $end]} {
	    lappend listLabels [getText $beg $end] 
	}
	set start $end  
    }
    return $listLabels  
}
	  
##
 # -------------------------------------------------------------------------
 #
 # "TeX::Completion::Cite" --
 #
 # Checks for any \cite like command, and looks up the partial argument in
 # the known bibliographies, completing the entry as appropriate.
 #
 # This version (JK, Feb2003): Finds bibitems even with punctuation chars.
 # To fine-tune it further, edit the expression bibChars below.
 # The proc now handles the listpick part itself and no longer depends on 
 # completion::Find. (Its special needs were quite different from the 
 # spirit of completion::Find.)
 # -------------------------------------------------------------------------
 ##

proc TeX::Completion::Cite { } {
    set t [getText [lineStart [getPos]] [getPos]]
    # build this: (cite|nocite|citet|citeauthor|citep|citeyear) :
    global TeXmodeVars
    set citeExpr "\\\\(?:[join $TeXmodeVars(citeCommands) |])"
    set bibChars {[a-zA-Z0-9_\.;:/+=-]}
    # Got a \cite-like command:
    if {![regexp -- "$citeExpr\\\{(?:${bibChars}+,)*(${bibChars}+)$" \
      $t -> bibHint] } {
	return 0
    }
    # What to do if everything fails? :
    if { $TeXmodeVars(showTitlesWithTeXCiteCompletion) } {
	set query "Rebuild Bibliography Database"
	set rebuild Bib::rebuildDatabase
    } else {
	set query "Rebuild Bibliography Index"
	set rebuild Bib::rebuildIndex
    }
    # Search database/index for all relevant solutions:
    set relevantBibs [Bib::_FindAllEntries $bibHint \
      $TeXmodeVars(showTitlesWithTeXCiteCompletion)]
    # First treat the special case where nothing was found:
    if { $relevantBibs == "" } {
	if { [catch {dialog::optionMenu \
	  "No matching citations found.  Perhaps you should\
	  rebuild your bib data-base, or create a new entry." \
	  [list "Rebuild database" "New entry" "New entry in new file"]} res] } {
	    # User cancelled
	    return 0
	}
	switch $res {
	    "Rebuild database" {
		$rebuild
		# Try again
		return [TeX::Completion::Cite]
	    }
	    "New entry" {
		Bib::_newEntry $bibHint
	    }
	    "New entry in new file" {
		Bib::_newEntry $bibHint 1
	    }
	}
	return 0
    }
    # Finally we come to the interesting cases: one or more items found:
    if { [llength $relevantBibs] == 1 } {
	set match [lindex $relevantBibs 0]
	set msg "Unique matching bibitem."
    } else {
	# Set up a listpick dialogue the user can choose from:
	lappend $relevantBibs "------------------------" $query
	beep
	if {[catch {set match [listpick -p "Pick a completion" $relevantBibs]}] \
	  || $match == "------------------------" } {
	    status::msg "Cancelled"
	    return 1
	}
	if { $match == $query } {
	    $rebuild
	    return 1
	}
	set msg ""
    }
    # Handle the found match:
    if { $TeXmodeVars(showTitlesWithTeXCiteCompletion) } {
       set match [lindex $match 0]
    }
    # Don't just insert the difference between hint and match.
    # It's much better to delete the hint and insert the whole match.
    # This gives precisely the same behaviour for the current version
    # of [Bib::_FindAllEntries], but fancier versions of that proc
    # might allow you to complete from a hint which is not the leading
    # part of the bibcitekey.  E.g.  given \cite{Bott  then complete
    # and find 'Atiyah-Bott:Clifford-modules'.                         
    # }
    completion::action -delete [string length $bibHint] -text $match -msg $msg
    # Don't add a trailing brace, in case of multiple citations.
    return 1
}

proc TeX::Completion::Word {} {
    # We only complete the word if it doesn't end in some command
    if {[lookAt [pos::math [getPos] - 1]] != "\{" } {
	return [completion::general -pattern {[\w]+} -- [completion::lastWord]]
    }
    return 0
}

# ×××× setup various arrays for electrics ×××× #

# This defines the basic set of "TeXcmds", which might be augmented later.
TeXcmds.tcl

# This is called whenever the TeX mode prefs "standardTeXLabelDelimiter" or
# "indentLaTeXEnvironment" are changed to reset the electric completions.

proc TeX::adjustElectricLabels {args} {
    
    global TeXmodeVars TeXelectrics TeXbodies TeXcmds
    
    if {$TeXmodeVars(useLabelPrefixes)} {
	array set prfx [list \
	  "fig"         "fig$TeXmodeVars(standardTeXLabelDelimiter)" \
	  "eq"          "eq$TeXmodeVars(standardTeXLabelDelimiter)" \
	  "sec"         "sec$TeXmodeVars(standardTeXLabelDelimiter)" \
	  "chap"        "chap$TeXmodeVars(standardTeXLabelDelimiter)" \
	  "tab"         "tab$TeXmodeVars(standardTeXLabelDelimiter)" \
	  ]
    } else {
	array set prfx [list \
	  "fig"         "" \
	  "eq"          "" \
	  "sec"         "" \
	  "chap"        "" \
	  "tab"         "" \
	  ]
    }
    set _t [TeX::indentEnvironment]

    set TeXelectrics(*section)         "\{¥section name¥\}\n¥¥"
    
    if {0} {
	set TeXelectrics(Appendix)         "×kill0Appendix~\\ref\{$prfx(sec)¥label¥\}¥¥"
	set TeXelectrics(Chapter)          "×kill0Chapter~\\ref\{$prfx(chap)¥label¥\}¥¥"
	set TeXelectrics(Eq.)              "~\\eqref\{$prfx(eq)¥label¥\}¥¥"
	set TeXelectrics(Figure)           "×kill0Figure~\\ref\{$prfx(fig)¥label¥\}¥¥"
	set TeXelectrics(Section)          "×kill0Section~\\ref\{$prfx(sec)¥label¥\}¥¥"
	set TeXelectrics(Table)            "~\\ref\{$prfx(tab)¥label¥\}¥¥"
    }
    
    set TeXelectrics(begin)            "\{¥environment name¥\}\n\\end\{¥end environment¥\}\n¥¥"
    #set TeXelectrics(begin) \
      "\{¥environment name¥\}\n${_t}¥body¥\n\\end\{¥end environment¥\}\n¥¥"
    set TeXelectrics(emph)             "×1"
    set TeXelectrics(fbox)             "\{¥¥\}"
    set TeXelectrics(frac)             "\{¥numerator¥\}\{¥denominator¥\}¥¥"
    set TeXelectrics(framebox)         "×\[TeX::boxes\]"
    set TeXelectrics(includegraphics)  "×\[TeX::IncludeFile\]"
    set TeXelectrics(makebox)          "×\[TeX::boxes\]"
    set TeXelectrics(mbox)             "\{¥¥\}"
    set TeXelectrics(mbox)             "\{¥¥\}"
    set TeXelectrics(newsavebox)       "\{¥¥\}"
    set TeXelectrics(parbox)           "×\[TeX::parbox\]"
    set TeXelectrics(raisebox)         "×\[TeX::raisebox\]"
    set TeXelectrics(rule)             "×\[TeX::rule\]"
    set TeXelectrics(savebox)          "×\[TeX::savebox\]"
    set TeXelectrics(sbox)             "×\[TeX::sbox\]"
    set TeXelectrics(sum)              "_\{¥from¥\}^\{¥to¥\}¥¥"
    set TeXelectrics(usebox)           "\{¥¥\}"
    
    # "citeCommands" completions.  This is placed here for convenience, even
    # though it has nothing to do with "labels" -- which is true for other
    # code in here.  We probably need a new [TeX::rebuildTeXElectrics] proc.
    foreach citeCommand $TeXmodeVars(citeCommands) {
	set TeXelectrics($citeCommand) "\{¥¥\}¥¥"
	lappend TeXcmds $citeCommand
    } 
    set TeXcmds [lsort -dictionary -unique $TeXcmds]

    #set TeXelectrics(subfigure)"    \[¥caption¥\]\{\\label\{$prfx(fig)¥¥\}\}\%\r\\includegraphics\[¥width=,height=¥\]\{¥eps file¥\}\}"

    set TeXbodies(array)           "×\[TeX::BuildTabular array\]"
    set TeXbodies(description)     "×\[TeX::BuildList description\]"
    set TeXbodies(enumerate)       "×\[TeX::BuildList enumerate\]"
    set TeXbodies(equation)        "\n${_t}¥equation body¥\n${_t}\\label\{$prfx(eq)¥label¥\}"
    set TeXbodies(figure)          "×\[TeX::Figure\]"
    set TeXbodies(itemize)         "×\[TeX::BuildList itemize\]"
    set TeXbodies(list)            "×\[TeX::BuildList list\]"
    set TeXbodies(quotation)       "\n${_t}¥¥¥¥"
    set TeXbodies(quote)           "\n${_t}¥¥¥¥"
    set TeXbodies(table)           "\n${_t}¥¥\n${_t}\\caption¥\[short title for t.o.t.\]¥\{¥caption¥\}\n${_t}\\protect[TeX::labelString tab]"
    set TeXbodies(trivlist)        "×\[TeX::BuildList trivlist\]"

    set TeXbodies(cases)           "\n${_t}¥¥ & ¥¥ \\\\\n${_t}¥¥ & ¥¥"
    set TeXbodies(gather)          "\n${_t}¥¥ \n${_t}\\label\{$prfx(eq)¥¥\} \\\\\n${_t}¥¥ \n${_t}\\label\{$prfx(eq)¥¥\}"
    set TeXbodies(split)           "\n${_t}¥¥ &¥¥ \\\\\n${_t}¥¥ &¥¥ \\\\"
    set TeXbodies(tabular)         "×\[TeX::BuildTabular tabular\]"
    set TeXbodies(tabular*)        "×\[TeX::BuildTabular tabular*\]"

    set TeXbodies(Vmatrix)         "×\[TeX::matrix\]"
    set TeXbodies(align)           "×\[TeX::align\]"
    set TeXbodies(align*)          "×\[TeX::align*\]"
    set TeXbodies(alignat)         "×\[TeX::alignat\]"
    set TeXbodies(bmatrix)         "×\[TeX::matrix\]"
    set TeXbodies(eqnarray)        "×\[TeX::eqnarray\]"
    set TeXbodies(eqnarray*)       "×\[TeX::eqnarray*\]"
    set TeXbodies(matrix)          "×\[TeX::matrix\]"
    set TeXbodies(minipage)        "×\[TeX::minipage\]"
    set TeXbodies(pmatrix)         "×\[TeX::matrix\]"
    set TeXbodies(vmatrix)         "×\[TeX::matrix\]"

    set TeXbodies(align)           "\n${_t}¥equation 1 l.h.s.¥ &¥¥ \n${_t}\\label\{$prfx(eq)¥¥\} \\\\\n${_t}¥equation 2 l.h.s.¥ &¥¥ \n${_t}\\label\{$prfx(eq)¥¥\}"
    
}

# Call this now.
TeX::adjustElectricLabels

# ×××× environment assistors ×××× #

# ×××× Template embeddable proc's ×××× #

proc TeX::IncludeFile {} {

    # Could try to ensure this file's on the search path?
    if ![regexp {\{, } [lookAt [pos::math [getPos] - 1]]] {
	append res "\{"
    }
    append res [file tail [getfile "Name of file to include:"]]
    return $res
}

# ×××× Expansions ×××× #

namespace eval TeX::Expansion {}

# proc by Tom Fetherston

proc TeX::Expansion::ExCmd { {cmd ""} {dictExt "acronyms"}} {
    global mode
    if ![string length $cmd] {
	set cmd [completion::lastWord]
	# If there's any whitespace in the command then it's no good to us
	if [containsSpace $cmd] { return 0 }
    }

    set hint [string trim [join [split $cmd \\ ]]]

    if { [set matches [elec::acronymListExpansions $hint ${mode}${dictExt}]] == 0 } {
	return 0
    } else {
	set result [elec::expandThis $cmd $matches]
	set match [lindex  $result 0]
	catch {set keystroke [lindex $result 1]}
	if [string length $match] {
	    completion::reset
	    if {![is::Integer $match] || $match == "1"} {
		return 1
	    } else {
		set curPos [getPos]
		set retVal [completion $mode Electric "${match}"]
		if {([pos::compare [getPos] == $curPos]) && [info exists keystroke]} {
		    insertText $keystroke
		}
		return $retVal
	    }
	} else {
	    elec::alreadyExpanding Cmd
	    return 1
	}
    }

}

# ==========================================================================
# 
# .