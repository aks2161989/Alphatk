# -*-Tcl-*-
##################################################################
# 
# BibTeX to HTML converter (new version). 
# 
# Pierre BASSO 
# email:basso@lim.univ-mrs.fr
#
# 
# This procedure is inserted as a command in the menu mode BibTeX. You use
# this command in selecting all a bib file or only a part, bibToHtml will
# convert the selected part.  If no selection, all the bib file is
# selected.  The selection is put in a temporary bib file, bibToHtml asks
# for a bib style, it builds an aux temporary file then it launches BibTeX
# which deals this temporary aux and converts the temporary bib file.  If
# your selection is a part of a file, or whole the file, 'fooname.bib' all
# these temporaries files are created in the same folder.
# 
# Then bibToHtml deals with the temporary bbl file created, when it ends it
# asks for directly sending the html file to the browser, else it displays
# this file as a front window.  You may improve this html file, in adding
# titles, figures or any fancies, for example, before sending to the
# browser.
# 
#  WARNING: 
#  
#    If some bib entries of selection are wrong, launching BibTeX will
#    display the errors.  But these errors don't affect the work of
#    bibToHtml, at the output these erroneous entries will be displayed by
#    the browser with wrong fields.
#           
#  NOTE:
#  
#   It is not needed to sort the selection because BibTeX will do it.  So
#   the html outcome of bibToHtml appears correctly sorted.
#  
# I borrowed from "Convert LaTeX to Accents" the table of regular
# expressions for conversion of LaTeX characters.
# 
# Thanks to F. Miguel Dion’sio 
# Includes contributions from Craig Barton Upright
#
#################################################################

alpha::feature bibToHtml 3.0 "Bib" {
    # Initialization script.
    # We require Bib 3.6b1 for new 'bibConversions' submenu.
    alpha::package require -loose Bib 3.6b1
} {
    # Activation script.
    # Insert the menu items into the 'bibConversions' submenu
    menu::insert bibtexConversions items end "bibToHtmlÉ"
    menu::insert bibtexConversions items end "bblToHtmlÉ"
} {
    # Deactivation script.
    # Could uninsert the menu items, but then they won't be in the menu
    # if the BibTeX menu is global but this package is not.
} maintainer {
    "Pierre Basso" <basso@lim.univ-mrs.fr>
} help {
    file "BibToHtml Help"
}

namespace eval Bib {}

proc Bib::bibToHtml {args} {eval Bib::ToHtml::convertBibFile $args} 
proc Bib::bblToHtml {args} {eval Bib::ToHtml::convertBblFile $args} 

# ×××× --------- ×××× #

# These prefs will be saved between sessions, and are changed via the
# "Bib::ToHtml::conversionDialog" procedure.

array set BibToHtmlViewOptions {
    "Edit the html file"       {edit}
    "View the html file"       {htmlView}
    "Show html file in Finder" {file::showInFinder}
}

newPref flag "includeLabels" 1                 BibToHtml

# Used to set the default location for finding a .bbl file via a dialog.
newPref var  "bblFile"    $HOME                BibToHtml
newPref var  "bibStyle"   "plain"              BibToHtml
newPref var  "bibTitle"   "Bibliography"       BibToHtml
newPref var  "prefix"     ""                   BibToHtml
newPref var  "saveDir"    $HOME                BibToHtml
newPref var  "saveName"   "dummy.html"         BibToHtml
newPref var  "startIndex" "1"                  BibToHtml
newPref var  "viewOption" "View the html file" BibToHtml "" \
  BibToHtmlViewOptions array 

# This won't be saved, but it's convenient to save it in the same array.
newPref var  "count"      "0"                  BibToHtml

foreach pref [list "includeLabels" "bblFile" "bibStyle" "bibTitle" \
  "prefix" "saveDir" "saveName" "startIndex" "viewOption"] {
    prefs::modified BibToHtmlmodeVars($pref)
}
unset pref

# ==========================================================================
#
# Dialog which sets variables which will be saved between editing sessions.
# 

namespace eval Bib::ToHtml {}

proc Bib::ToHtml::conversionDialog {{bblFile ""} {askForStyle "1"} {extraNote ""}} {
    
    global BibToHtmlmodeVars HOME BibToHtmlViewOptions
    
    # Find the bblFile if none given.
    if {![string length $bblFile]} {
	# Since we're going to choose a previously created .bbl file, we
	# can assume that the 'style' has already been set.
	set askForStyle 0
	set p "Please choose a .bbl file to convert"
	set bblFile [getfile $p $BibToHtmlmodeVars(bblFile)]
	if {[string tolower [file extension $bblFile]] != ".bbl"} {
	    # Is there a .bbl file in this directory?
	    if {[file exists [file rootname $bblFile].bbl]} {
		set bblFile  [file rootname $bblFile].bbl
	    } else {
		error "Cancelled -- '[file tail $bblFile]' is not a .bbl file"
	    }
	} 
	set BibToHtmlmodeVars(bblFile) $bblFile
	set saveDir  [file dirname $bblFile]
	set saveName "[file rootname [file tail $bblFile]].html"
    } else {
	set saveDir  $BibToHtmlmodeVars(saveDir)
        set saveName $BibToHtmlmodeVars(saveName)
    }
    
    # Determine previously saved settings.
    set labels  $BibToHtmlmodeVars(includeLabels)
    set prefix  $BibToHtmlmodeVars(prefix)
    set start   $BibToHtmlmodeVars(startIndex)
    set style   $BibToHtmlmodeVars(bibStyle)
    set options [array names BibToHtmlViewOptions]
    set option  $BibToHtmlmodeVars(viewOption)
    set title   $BibToHtmlmodeVars(bibTitle)
    
    set     d1 [list dialog::make -title "Bib Convert To HTML"]
    lappend d2 "Settings for the conversion:"
    if {$askForStyle} {
	lappend d2 [list var  "Bibliography Style:" $style]
	set prefs  "bibStyle"
    } 
    lappend d2 [list flag   "Include \[1\] etc labels with entries" $labels]
    lappend d2 [list var    "        Prefix this label with:" $prefix]
    lappend d2 [list var    "        Provide a start index:"  $start]
    lappend d2 [list var    "Converted html page title:" $title]
    lappend d2 [list var    "Save converted html file as:" $saveName]
    lappend d2 [list folder "Save converted html file in:" $saveDir]
    lappend d2 [list [list menu $options] "Viewing options:" $option]
    if {[string length $extraNote]} {
	lappend d2 [list text "______________________\r\r${extraNote}"]
    }
    set values [eval $d1 [list $d2]]
    
    set count 0
    lappend prefs "includeLabels" "prefix" "startIndex" \
      "bibTitle" "saveName" "saveDir" "viewOption"
    foreach pref $prefs {
	set BibToHtmlmodeVars($pref) [lindex $values $count]
	incr count
    } 
    return $bblFile
}

# ==========================================================================
#
# Conversion of a bib file into html file
# 

proc Bib::ToHtml::convertBibFile {} {
    
    global mode BibToHtmlmodeVars HOME
    
    set  count [incr BibToHtmlmodeVars(count)]
    
    # Try to use the front window if it is a .bib file.
    set bibFile [win::StripCount [win::Current]]
    if {$mode != "Bib"} {
	set p "Select a .bib file to convert"
	while {[win::FindMode $bibFile] != "Bib"} {
	    set bibFile [getfile $p $bibFile]
	    set p "[file tail $bibFile] was not a .bib file -- try again."
	}
	set buffer [file::readAll $bibFile]
    } elseif {[isSelection]} {
	# Beginning to end of selection
	set buffer [getSelect]
    } else {
	set buffer [getText [minPos] [maxPos]]
    }
    # Set the target directory for the converted file.
    if {[file isfile $bibFile]} {
        set BibToHtmlmodeVars(saveDir) [file dirname $bibFile]
    } else {
        set BibToHtmlmodeVars(saveDir) $HOME
    }
    set BibToHtmlmodeVars(saveName) "[file rootname [file tail $bibFile]].html"

    # Create a temporary bib file with the selected entries.
    set tmpDir  [temp::directory BibToHtml]
    set tmpBase [file join $tmpDir tmp${count}]
    set tmpBib  ${tmpBase}.bib

    catch {open $tmpBib w} id
    if {[string range $id 0 3] != "file"} {
	alertnote "Cannot open a temporary .bib file"
	error "Cancelled"
    }
    puts $id $buffer ; close $id

    # Ask for a bib style as well as other settings.
    set note "After pressing the OK button, a temporary .bbl file will\
      be created and passed to your BibTeX application.  Please wait until\
      it is finished (it will probably beep) before continuing."

    Bib::ToHtml::conversionDialog $tmpBib 1 $note

    # Create files: .aux, .bak, .bbl, .blg
    foreach type [list Aux Bak Bbl Blg] {
	set suffix  ".[string tolower $type]"
	set tmpType [set tmp${type} "${tmpBase}${suffix}"]
	catch {open $tmpType w} id
	if {[string range $id 0 3] != "file"} {
	    alertnote "Cannot open a temporary '$suffix' file"
	    error "Cancelled"
	} elseif {$type == "Aux"} {
	    set    buffer "\\bibstyle\{$BibToHtmlmodeVars(bibStyle)\}\r"
	    append buffer "\\citation\{*\}\r"
	    append buffer "\\bibdata\{tmp${count}\}"
	    puts $id $buffer
	}
	close $id
    }
    # Before launching BibTeX, we might have to copy any .bst file into
    # the temporary folder so that it can be found.
    set style $BibToHtmlmodeVars(bibStyle)
    set file1 [file join [file dirname $bibFile] ${style}.bst]
    set file2 [file join $tmpDir ${style}.bst]
    if {[file exists $file1] && ![file exists $file2]} {
        file copy $file1 $file2
    } 
    # Launch BibTeX.  We need to ensure TeX mode has been loaded first.
    loadAMode TeX
    bibtexAUXFile  $tmpAux
    # We don't necessarily get a reply from the above, so we'll never be
    # sure when it if finished.
    if {![dialog::yesno -n Cancel "Is BibTeX done?"]} {
	error "cancel"
    }
    # Now that we have all the files created, pass it along.
    Bib::bblToHtml $tmpBbl 
}

# ==========================================================================
#
# Conversion of a bbl file into html file
# 

proc Bib::ToHtml::convertBblFile {{bblFile ""}} {
    
    global BibToHtmlmodeVars BibToHtmlViewOptions

    if {![string length $bblFile]} {set bblFile [Bib::ToHtml::conversionDialog]}

    # Convert the file.
    watchCursor
    if {[catch {Bib::ToHtml::convertBblToHtml $bblFile} buffer]} {
	error "Cancelled -- $buffer"
    }

    # Now put the html code in a new file.
    if {![string length $BibToHtmlmodeVars(saveName)]} {
	set saveName "BibConversion"
    } else {
	set saveName [file rootname $BibToHtmlmodeVars(saveName)]
    }
    if {![file isdir $BibToHtmlmodeVars(saveDir)]} {
	set saveDir $HOME
    } else {
	set saveDir $BibToHtmlmodeVars(saveDir)
    }
    set htmlFile [file join $saveDir ${saveName}.html]
    set idhtml   [open $htmlFile w]
    puts $idhtml $buffer ; close $idhtml
    # And perform some action with the file.
    set option   [set BibToHtmlViewOptions($BibToHtmlmodeVars(viewOption))]
    eval [list $option $htmlFile]
}

# ==========================================================================
#
# Conversion of a bbl file into html code
# 

proc Bib::ToHtml::convertBblToHtml {bblFile} {
    
    global BibToHtmlmodeVars
    
    Bib::ToHtml::setVars
    
    catch {open $bblFile r} id
    
    if {[string range $id 0 3] != "file"} {
	alertnote "Couldn't open the temporary .bbl file"
	error "Cancelled"
    } elseif {![file exists $bblFile]} {
	alertnote "BibTeX didn't create a .bbl file"
	error "Cancelled"
    } elseif {[file size $bblFile] == 0} {
	error "Cancelled -- empty .bbl file"
    }
    
    set labels $BibToHtmlmodeVars(includeLabels)
    set title  $BibToHtmlmodeVars(bibTitle)
    set prefix $BibToHtmlmodeVars(prefix)
    set start  $BibToHtmlmodeVars(startIndex)
    
    set    convertedFile "<HTML>\r <HEAD>\r <TITLE>$title</TITLE>\r </HEAD>\r"
    append convertedFile "<BODY BGCOLOR=$quote#ffffff$quote LINK=$quote#cc0000$quote" 
    append convertedFile "VLINK=$quote#005522$quote ALINK=$quote#ff3300$quote" 
    append convertedFile "topmargin=$quote 5$quote leftmargin=$quote 5$quote>\r\r<DL>\r"   
    append convertedFile "\r<P>"
    
    set bibitem        ""
    set nextbibitem    ""
    set biblabel       0
    set bibindex       0
    set beginthebiblio -1
    
    while {$bibitem != "\\end\{thebibliography\}"} {
	# This message only works if we're including labels -- should figure
	# out some other place in this code to determine when we're dealing
	# with a new entry and incr a variable accordingly.
	status::msg "Converting bibliographic entry [expr {$bibindex + 1}] to html"
	if {$nextbibitem == ""} {
	    set nbchar [gets $id bibitem]
	} else {
	    set bibitem $nextbibitem ; set nextbibitem ""
	}
	if {[string first "\\begin\{thebibliography\}" $bibitem] != -1} {
	    set beginthebiblio 0
	    continue
	} elseif {$beginthebiblio == "-1"} {
	    continue
	} elseif {$nbchar == 0} {
	    append convertedFile "\r</P>\r<P>\r"
	    continue
	} elseif {$bibitem == "\\end\{thebibliography\}"} {
	    continue
	}
	# Deals with labels
	if {[string first "\\bibitem" $bibitem] != "-1"} {
	    if {$labels == 0} {continue}
	    set bibitem [string  range $bibitem 8 end]
	    if {[string index $bibitem 0] == "\{"} {
		incr bibindex 1
		set zz [expr {$bibindex + $start - 1}]
		append convertedFile "\[${prefix}${zz}\]  "
		continue
	    }
	    set aa [string first "\]" $bibitem]
	    if {$aa == -1} {
		set xx [gets $id continuelabel]
		append bibitem $continuelabel
		set aa [string first "\]" $bibitem ]
	    }
	    set bibitem [string range $bibitem 1 [expr {$aa - 1}]]
	    set biblabel 1
	}
	# Deals with \newblock lines
      if {$biblabel == 0} {
	if {[string first  "\\newblock" $bibitem] != -1} {
	    set bibitem [string range $bibitem 10 end]
	    append convertedFile " "
	    set offset 0
	    set newblock ""
	    set endblock 0
	    while {$endblock != 1} {
		set nbchar [gets $id newblock]
		if {[string first  "\\newblock" $newblock] != -1 || $nbchar == 0} {
		    set offset [expr {-$nbchar - 1}]
		    seek $id $offset current
		    set endblock 1
		    continue
		}
		append bibitem $newblock
	    } 		
	} else {
	    set enditem 0
	    while {$enditem != -1} {
		set nbchar [gets $id nextbibitem]
		if {[string first  "\\newblock" $nextbibitem] != -1} {
		    set enditem -1
		    continue
		} elseif {[string first  "\\end\{thebibliography\}" $nextbibitem] != -1} {
		    set enditem -1
		    continue
		} elseif {$nbchar == 0} { 
		    set enditem -1
		    set nextbibitem "\r\r<BR><BR>"
		    continue
		}
		append bibitem $nextbibitem
		set nextbibitem ""
	    }
	}
	regsub -all "\r" $bibitem ""         bibitem
	regsub -all "\b" $bibitem ""         bibitem
	regsub -all "\f" $bibitem ""         bibitem
	regsub -all "\n" $bibitem " "        bibitem
	regsub -all "¥"  $bibitem "\\&#176;" bibitem  
	
	if {[string first "\\" $bibitem] == -1} {
	    regsub -all "\{" $bibitem ""  bibitem
	    regsub -all "\}" $bibitem ""  bibitem
	    regsub -all "\~" $bibitem ""  bibitem
	    regsub -all "Õ"  $bibitem "'" bibitem
	}
    }
	# Searches for command \citeauthoryear and reduces list of arguments
	# at two.
	if {[string first  "\\citeauthoryear" $bibitem] != -1} {
	    set tmpbuf [string range  $bibitem 0 [expr {[string first  "\\citeauthoryear" $bibitem] + [string length "\\citeauthoryear"] - 1}]]
	    set xx [string first  "\}\{" $bibitem]
	    set yy [string last  "\}\{"  $bibitem]
	    if {$yy > $xx} {
		append tmpbuf [string range  $bibitem [expr {$xx + 1}] end]
		set bibitem $tmpbuf
	    }
	}
	
	# Separates date from the name in label of astron, apa, named, .... 
	if {$biblabel == 1} {regsub -all "\}\{" $bibitem ", " bibitem}
	# Converts Tex commands: \bgroup, \egroup and other commands
	set len [llength $TexCommands]
	set i 0
	while {$i < $len} {
	    set c [lindex $TexCommands $i]
	    set s [lindex $SubstitTexCommands $i]
	    regsub -all "$c" $bibitem "$s" bibitem 
	    incr i
	}
	# Converts european accented letters
	regsub -all "\\\\i" $bibitem "i" bibitem 
	set len [llength $tabRegExpr]
	set i 0
	while {$i < $len} {
	    set c [lindex $tabRegExpr $i]
	    set s [lindex $tabHtmlChar $i]
#	    regsub -all [quote::Regsub "$c"] $bibitem "$s" bibitem 
	    regsub -all "$c" $bibitem "$s" bibitem 
	    incr i
	}
	# Searches for and converts greek letters in title of mathematical
	# articles
	set indicbs [string first "\\" $bibitem ]
	if {$indicbs == -1} {
	    regsub -all "\{" $bibitem "" bibitem
	    regsub -all "\}" $bibitem "" bibitem
	}
	set len [llength $GreekExpr]
	set i 0
	while {$i < $len} {
	    set c [lindex $GreekExpr $i]
	    set s [lindex $HtmlGreek $i]
	    regsub -all [quote::Regsub "$c"] $bibitem "$s" bibitem 
	    incr i
	}
	# Searches for styles italic, emphasized, typewriter, bold, underlined.
	if {[string first "\\" $bibitem] == -1} {
	    regsub -all "\{" $bibitem "" bibitem
	    regsub -all "\}" $bibitem "" bibitem
	}
	set len [llength $LatexStyles]
	set j 0
	while {$j < $len} {
	    set style [lindex $LatexStyles $j]
	    set found 1
	    while {$found > 0} {
		set found [regexp -indices $style $bibitem values]
		if {$found == 0} {continue}
		set begtext  [lindex $values 0]
		set bufftmp [string range $bibitem 0 [expr {$begtext - 1}]]
		set htmlconv [lindex $HtmlStyles $j]
		append bufftmp " $htmlconv"
		set i 0
		set braces 1
		set lentmp [expr {[string length  $bibitem ] - [lindex $values 1]}]
		while {$i < $lentmp} {
		    set char [string index $bibitem [expr {[lindex $values 1] + $i + 1}]]
		    if {$char == "\{"} {incr braces}
		    if {$char == "\}"} {
			incr braces -1
			if {$braces == 0} {
			    set char [lindex $endHtmlStyles $j]
			    set ii [expr {$i + 1}]
			    set i $lentmp
			} 
		    }
		    append bufftmp $char
		    incr i
		}
		append bufftmp [string range $bibitem [expr {[lindex $values 1] + $ii + 1}] end]
		set bibitem $bufftmp
	    }
	    incr j
	}
	# Convert small caps expressions <SC> ... </SC>
	set sc [string first "<SC>" $bibitem]
	while {$sc >= 0} {
	    set bufftmp [string  range $bibitem 0 [expr {$sc - 1}]]
	    set bibitem [string range $bibitem [expr {$sc + 4}] end]
	    set expression [string range $bibitem 0  [expr {[string first "</SC>" $bibitem] - 1}]]
	    set bibitem [string range $bibitem [expr {[string first "</SC>" $bibitem] + 5}] end]
	    set namefound 0
	    while {$expression != ""} {
		if {[string range $expression 0 2] == "and"} {
		    append bufftmp "and"
		    set expression [string range $expression 3 end]
		    continue
		}
		set c [string index $expression 0]
		if {$namefound == 0} {
		    if {$c == "\{" || $c == "\}" } {
			set expression [string range $expression 1 end]
			continue
		    }
		    if {$c == " " || $c == "," || $c == "-"} {
			append bufftmp $c
			set expression [string range $expression 1 end]
			continue
		    }
		    set x 0
		    if {$c == "\&"} {if {[string index $expression 1] == " "} {
			append bufftmp $c
			continue
		    } else {
			set x [string first ";" $expression]
			set c [string range $expression 0 $x]}
		    }
		    set cc [string index $expression [expr {$x + 1}]]
		    
		    if {$cc == "."} {
			append bufftmp "$c."
			set expression [string range $expression [expr {$x + 2}] end]
			continue
		    }
		    if {$cc == "-"} {
			set y [string first "." $expression]
			append bufftmp [string range $expression 0 [expr {$x + $y}]]
			set expression [string range $expression [expr {$x + $y + 1}] end]
			continue
		    }
		    set expression [string range $expression [expr {$x + 1}] end]
		    set namefound 1
		    append bufftmp "$c<SMALL>"
		    continue
		}
		# namefound = 1, analyzes a name and converts it into small
		# caps
		set x 0
		set len [string length $expression]
		if {$len == 0} {continue}
		set name ""
		while {$name == ""} {
		    set aa [string index $expression $x]
		    if {$aa == "," || $aa == " " || $aa == "\}" || $aa == "-"} {
			set name [string range $expression 0 [expr {$x - 1}]]
			continue
		    }
		    incr x
		    if {$x == $len} {set name [string range $expression 0 end]} 
		}		   
		set i 0
		while {$i <= 25} {
		    set char [lindex $lowcase $i]
		    regsub -all "$char" $name  "[lindex $upcase $i]" name
		    incr i
		}
		set i 0
		set char [lindex $HtmlUpcasedChar 0]
		while {$char != "?"} {
		    regsub -all "$char" $name  "[lindex $HtmlNormalChar $i]" name
		    incr i
		    set char [lindex $HtmlUpcasedChar $i]
		}
		append bufftmp "$name</SMALL>"
		if {$x == $len} {
		    set expression ""
		} else {
		    set expression [string range $expression $x end]
		}			 
		set namefound 0	 
	    }
	    # searches for following small caps expression		 
	    append bufftmp $bibitem
	    set bibitem $bufftmp
	    set sc [string first "<SC>" $bibitem]
	}
	# Convert superscript  expressions $A^e$
	set super [string first "^" $bibitem]
	while {$super >= 0} {
	    set bufftmp [string  range $bibitem 0 [expr {$super - 1}]]
	    set bibitem [string range $bibitem [expr {$super + 1}] end]
	    set char [string range $bibitem 0  [expr {[string first "$" $bibitem] - 1}]]
	    set bibitem [string range $bibitem [expr {[string first "$" $bibitem] + 1}] end]
	    append bufftmp "<SUP>$char</SUP> "
	    append bufftmp $bibitem
	    set bibitem $bufftmp
	    set super [string first "^" $bibitem]
	}
	# Searches for and converts \uppercase commands
	set uppercase [string first "\\uppercase" $bibitem]
	while {$uppercase >= 0} {
	    set bufftmp [string  range $bibitem 0 [expr {$uppercase - 1}]]
	    set bibitem [string range $bibitem [expr {$uppercase + 11}] end]
	    set closbrace [string first "\}" $bibitem]
	    set char [string range $bibitem 0  $closbrace]
	    set char [string trimright $char "\}"]
	    set char [string toupper $char]
	    append bufftmp $char
	    append bufftmp [string  range $bibitem [expr {$closbrace + 1}] end]
	    set bibitem $bufftmp
	    set uppercase [string first "\\uppercase" $bibitem]
	}
	# Converts bad character "Õ"
	regsub -all "Õ"           $bibitem "'"        bibitem
	# Converts possible \bullet latex commands.
	regsub -all "\(\\\$\)\\\\\(bullet\)\(\\\$\)" $bibitem "\\&#176;" bibitem
	# Clears all possible remaining backslashes
	regsub -all "\\\\"        $bibitem ""         bibitem
	# Clears possible remaining braces.
	regsub -all "\{"          $bibitem ""         bibitem
	regsub -all "\}"          $bibitem ""         bibitem
	# Clears possible tildas
	regsub -all "\~"          $bibitem " "        bibitem
	# Clears possible dollars
	regsub -all "\\\$"        $bibitem ""         bibitem
	# Improves punctuation
	regsub -all "  ,"         $bibitem ","        bibitem
	regsub -all " ,"          $bibitem ","        bibitem
	regsub -all "</EM>,"      $bibitem ",</EM>"   bibitem
	regsub -all "</B>,"       $bibitem ",</B>"    bibitem
	regsub -all ",,"          $bibitem ","        bibitem
	regsub -all ", ,"         $bibitem ","        bibitem
	regsub -all " ,"          $bibitem ","        bibitem
	regsub -all " \\\."       $bibitem "."        bibitem
	regsub -all "ed\\\.\\\."  $bibitem "ed.,"     bibitem
	regsub -all "eds\\\.\\\." $bibitem "eds.,"    bibitem
	regsub -all "\\\: </U>"   $bibitem "</U>: "   bibitem
	regsub -all "\\\:  </U>"  $bibitem "</U>: "   bibitem
	# Converts -- into -
	regsub -all "\\-\\-"      $bibitem "-"        bibitem
	# Converts french inverted commas
	regsub -all "<<"          $bibitem "\\&#171;" bibitem
	regsub -all ">>"          $bibitem "\\&#187;" bibitem
	# Conversion is achieved
	if {$biblabel == 1} {
	    append convertedFile "\[$bibitem\]  "
	    set biblabel 0
	} else {
	    append convertedFile $bibitem
	}
    }
    status::msg "Converted $bibindex bibliographic entries to html"
    
    append convertedFile "\r</P>\r\r</DL>\r\r</BODY>\r </HTML>"
    regsub -all "<P>\[\r\n\t \]+</P>" $convertedFile "" convertedFile
    
    set convertedFile [breakIntoLines $convertedFile 75]
    
    # Close bbl file and return
    close $id
    return $convertedFile
}

# ==========================================================================
#
# Initialise conversion tables
# 

proc Bib::ToHtml::setVars {} {
    
    foreach var [list lowcase upcase \
      HtmlUpcasedChar HtmlNormalChar \
      tabHtmlChar tabRegExpr HtmlGreek GreekExpr \
      LatexStyles HtmlStyles endHtmlStyles quote \
      TexCommands SubstitTexCommands \
      ] {upvar $var $var}
    
    set lowcase [list  \
      "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m"\
      "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"]
    
    set upcase [list \
      "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M"\
      "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z"]
    
    set HtmlUpcasedChar [list \
      "\\&AGRAVE;" "\\&AACUTE;" "\\&ACIRC;" "\\&ATILDE;" "\\&AUML;" "\\&ARING;"\
      "\\&EGRAVE;" "\\&EACUTE;" "\\&ECIRC;"  "\\&EUML;" \
      "\\&IGRAVE;" "\\&IACUTE;" "\\&ICIRC;"  "\\&IUML;" \
      "\\&OGRAVE;" "\\&OACUTE;" "\\&OCIRC;" "\\&OTILDE;" "\\&OUML;" \
      "\\&UGRAVE;" "\\&UACUTE;" "\\&UCIRC;"  "\\&UUML;" \
      "\\&CCEDIL;" "\\&NTILDE;" "\\&YACUTE;" "\\&YUML;" \
      "\\&AELIG;"  "\\&OSLASH;" "?"]
    
    set HtmlNormalChar   [list\
      "\\&Agrave;" "\\&Aacute;" "\\&Acirc;" "\\&Atilde;" "\\&Auml;" "\\&Aring;"\
      "\\&Egrave;" "\\&Eacute;" "\\&Ecirc;"  "\\&Euml;" \
      "\\&Igrave;" "\\&Iacute;" "\\&Icirc;"  "\\&Iuml;" \
      "\\&Ograve;" "\\&Oacute;" "\\&Ocirc;" "\\&Otilde;" "\\&Ouml;" \
      "\\&Ugrave;" "\\&Uacute;" "\\&Ucirc;"  "\\&Uuml;" \
      "\\&Ccedil;" "\\&Ntilde;" "\\&Yacute;" "\\&Yuml;" \
      "\\&Aelig;"  "\\&Oslash;"]
    
    set tabHtmlChar [list  \
      "\\&agrave;" "\\&aacute;" "\\&acirc;" "\\&atilde;" "\\&auml;" "\\&aring;"\
      "\\&Agrave;" "\\&Aacute;" "\\&Acirc;" "\\&Atilde;" "\\&Auml;" "\\&Aring;"\
      "\\&egrave;" "\\&eacute;" "\\&ecirc;"  "\\&euml;" \
      "\\&Egrave;" "\\&Eacute;" "\\&Ecirc;"  "\\&Euml;" \
      "\\&igrave;" "\\&iacute;" "\\&icirc;"    "\\&iuml;" \
      "\\&Igrave;" "\\&Iacute;" "\\&Icirc;"  "\\&Iuml;" \
      "\\&ograve;" "\\&oacute;" "\\&ocirc;" "\\&otilde;" "\\&ouml;" \
      "\\&Ograve;" "\\&Oacute;" "\\&Ocirc;" "\\&Otilde;" "\\&Ouml;" \
      "\\&ugrave;" "\\&uacute;" "\\&ucirc;"  "\\&uuml;" \
      "\\&Ugrave;" "\\&Uacute;" "\\&Ucirc;"  "\\&Uuml;" \
      "Ï" "Î"  "\\&aelig;" "\\&Aelig;" "\\&oslash;"  "\\&Oslash;"\
      "\\&ccedil;" "\\&ntilde;" "\\&Ccedil;" "\\&Ntilde;"\
      "\\&yacute;" "\\&yuml;"  "\\&Yacute;" "\\&Yuml;" ]
    
    set quote    {"}                                  
    set ws       {[ \t]*}
    set sp       {[ \t]}
    set sep      { *( |\b)}
    set seplater {\\\\sepsep//}

    # a|A accents
    set a [Bib::ToHtml::rexp a]
    set regas  [list \
      "\\\\`$a" "\\\\'$a" "\\\\\\^$a"  "\\\\~$a"  "\\\\\\$quote$a" "\\\\aa$sep"]
    set a [Bib::ToHtml::rexp A]
    set regcas  [list \
      "\\\\`$a" "\\\\'$a" "\\\\\\^$a"  "\\\\~$a"  "\\\\\\$quote$a" "\\\\AA$sep"]
    # e|E accents
    set e [Bib::ToHtml::rexp e]
    set reges   [list \
      "\\\\`$e"  "\\\\'$e" "\\\\\\^$e"  "\\\\\\$quote$e"]
    set e [Bib::ToHtml::rexp E]
    set regces  [list \
      "\\\\`$e"  "\\\\'$e" "\\\\\\^$e"  "\\\\\\$quote$e"]
    # i|I accents
#    set i [Bib::ToHtml::rexp \\i$ws]
    set i [Bib::ToHtml::rexp i$ws]
    set regis   [list \
      "\\\\`$i" "\\\\'$i"  "\\\\\\^$i"  "\\\\$quote$i"]
    set i [Bib::ToHtml::rexp I]
    set regcis   [list \
      "\\\\`$i" "\\\\'$i"  "\\\\\\^$i"  "\\\\$quote$i"]
    # o|O accents
    set o [Bib::ToHtml::rexp o]
    set regos    [list \
      "\\\\`$o" "\\\\'$o"  "\\\\\\^$o"  "\\\\~$o"  "\\\\$quote$o"]
    set o [Bib::ToHtml::rexp O]
    set regcos   [list \
      "\\\\`$o" "\\\\'$o"  "\\\\\\^$o"  "\\\\~$o"  "\\\\$quote$o"]
    # u|U accents
    set u [Bib::ToHtml::rexp u]
    set regus    [list \
      "\\\\`$u" "\\\\'$u"  "\\\\\\^$u"  "\\\\$quote$u"]
    set u [Bib::ToHtml::rexp U]
    set regcus   [list \
      "\\\\`$u" "\\\\'$u"  "\\\\\\^$u"  "\\\\$quote$u"]

    # set reglig   [list "\\\\oe$sep"  "\\\\OE$sep" "\\\\ae$sep" "\\\\AE$sep" "\\\\o$sep" "\\\\O$sep"]
    set reglig   [list \
      "\\&\\#339"  "\\&\\#338;" "\\\\ae$sep" "\\\\AE$sep" "\\\\o$sep" "\\\\O$sep"]
    set regoth1  [list \
      "\\\\c$sp[Bib::ToHtml::rexp c]|\\\\c{$ws\(c\)$ws}"  "\\\\~[Bib::ToHtml::rexp n]" "\\\\c$sp[Bib::ToHtml::rexp C]|\\\\c{$ws\(C\)$ws}"  "\\\\~[Bib::ToHtml::rexp N]" ] 
    set regoth2  [list \
      "\\\\\\'[Bib::ToHtml::rexp y]" "\\\\\\$quote[Bib::ToHtml::rexp y]" "\\\\\\'[Bib::ToHtml::rexp Y]" "\\\\\\$quote[Bib::ToHtml::rexp Y]"]
    
    set tabRegExpr [concat \
      $regas $regcas $reges $regces $regis $regcis \
      $regos $regcos $regus $regcus \
      $reglig $regoth1 $regoth2 ]
    
    set GreekExpr [list \
      "\(\\\$\)\\\\\(alpha\)\(\\\$\)" "\(\\\$\)\\\\\(beta\)\(\\\$\)"\
      "\(\\\$\)\\\\\(chi\)\(\\\$\)" "\(\\\$\)\\\\\(delta\)\(\\\$\)"\
      "\(\\\$\)\\\\\(epsilon\)\(\\\$\)" "\(\\\$\)\\\\\(phi\)\(\\\$\)"\
      "\(\\\$\)\\\\\(gamma\)\(\\\$\)" "\(\\\$\)\\\\\(eta\)\(\\\$\)"\
      "\(\\\$\)\\\\\(iota\)\(\\\$\)" "\(\\\$\)\\\\\(varphi\)\(\\\$\)"\
      "\(\\\$\)\\\\\(kappa\)\(\\\$\)" "\(\\\$\)\\\\\(lambda\)\(\\\$\)"\
      "\(\\\$\)\\\\\(mu\)\(\\\$\)" "\(\\\$\)\\\\\(nu\)\(\\\$\)"\
      "\(\\\$\)\\\\\(pi\)\(\\\$\)" "\(\\\$\)\\\\\(theta\)\(\\\$\)"\
      "\(\\\$\)\\\\\(rho\)\(\\\$\)" "\(\\\$\)\\\\\(sigma\)\(\\\$\)"\
      "\(\\\$\)\\\\\(tau\)\(\\\$\)" "\(\\\$\)\\\\\(upsilon\)\(\\\$\)"\
      "\(\\\$\)\\\\\(varpi\)\(\\\$\)" "\(\\\$\)\\\\\(omega\)\(\\\$\)"\
      "\(\\\$\)\\\\\(xi\)\(\\\$\)" "\(\\\$\)\\\\\(psi\)\(\\\$\)"\
      "\(\\\$\)\\\\\(zeta\)\(\\\$\)" "\(\\\$\)\\\\\(Delta\)\(\\\$\)"\
      "\(\\\$\)\\\\\(Phi\)\(\\\$\)" "\(\\\$\)\\\\\(Gamma\)\(\\\$\)"\
      "\(\\\$\)\\\\\(vartheta\)\(\\\$\)" "\(\\\$\)\\\\\(Lambda\)\(\\\$\)"\
      "\(\\\$\)\\\\\(Pi\)\(\\\$\)" "\(\\\$\)\\\\\(Theta\)\(\\\$\)"\
      "\(\\\$\)\\\\\(Sigma\)\(\\\$\)" "\(\\\$\)\\\\\(varsigma\)\(\\\$\)"\
      "\(\\\$\)\\\\\(Omega\)\(\\\$\)" "\(\\\$\)\\\\\(Xi\)\(\\\$\)"\
      "\(\\\$\)\\\\\(Psi\)\(\\\$\)"]
    
    set HtmlGreek [list \
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">a</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">b</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">c</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">d</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">e</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">f</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">g</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">h</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">i</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">j</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">k</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">l</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">m</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">n</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">p</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">q</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">r</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">s</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">t</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">u</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">v</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">w</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">x</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">y</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">z</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">D</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">F</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">G</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">J</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">L</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">P</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">Q</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">S</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">V</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">W</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">X</FONT>"\
      "<FONT SIZE=\"3\" FACE=\"Symbol\" POINT-SIZE=\"3\">Y</FONT>"]
    
    set LatexStyles [list \
      "(\\\\it|\\\\textit\{)" "(\\\{\\\\em|\\\\emph\{)"\
      "(\\\\bf|\\\\textbf\{)" "(\\\\tt|\\\\texttt\{)"\
      "(\\\\sc|\\\\textsc\{)" "(\\\\underline\{)" "(\\\\underline)"]
    
    set HtmlStyles  [list \
      "<I>" "<EM>" "<B>"  "<TT>" "<SC>" "<U>" "<U>"]   
    
    set endHtmlStyles [list \
      "</I>" "</EM>" "</B>" "</TT>" "</SC>" "</U>" "</U>"] 
    
    set TexCommands [list \
      "\\\\bgroup " "\\\\bgroup" "\\\\egroup" "\\\\egroup\{\}," "\\\\egroup\{\}\\." "\\\\egroup\{\}"\
      "\\\\andname\{\}" "\\\\Inname\{\}" "\\\\inname\{\}" "\\\\numbername\{\}" "\\\\Numbername\{\}" "\\\\ofname\{\}"\
      "\\\\pagesname\{\}" "\\\\editorname\{\}" "\\\\editornames\{\}" "\\\\volumename\{\}"\
      "\\\\etalchar\{\\\+\}" "\\\\protect" "\\\\astroncite" "\\\\citename" "\\\\relax" "\\\\citeauthoryear"\
      "\\\\begin\{quotation\}" "\\\\noindent" "\\\\end\{quotation\}" "\\\\bysame" "\\\\fsc"]
    
    set SubstitTexCommands [list \
      "\{" "\{" "\}" "\}," "\}." "\},"\
      "," "In" "in" "n\$^o\$" "N\$^o\$" "of"\
      "" "ed." "eds." "vol."\
      "" "" "" "" "" ""\
      "" "" "" "<SUP>___</SUP>" "\\textsc"]
}

# ==========================================================================
#
# Returns, for argument "a" the regular expression 
# 
# [ \t]*(a|{[ \t]*a[ \t]*}),
# 
# used to look for alternative ways of writing accents, for example ˆ:
# 
# \`a, \` a, \`{a}, etc.
#

proc Bib::ToHtml::rexp  {c {pre ""}} {
    set ws "\[ \t\]*"
    return $ws\($pre$c|{$ws$c$ws}\)
}

