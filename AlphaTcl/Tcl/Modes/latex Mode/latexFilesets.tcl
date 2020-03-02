## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "latexFilesets.tcl"
 #                                   created: 03/23/1996 {05:10:08 PM}
 #                               last update: 2006-05-03 18:27:08
 # Description:
 #
 # Support for LaTeX filesets.
 #
 # Used to be in Vince's Additions - an extension package for Alpha.
 #
 # This is the tex-fileset code.  It is an example of the ability of the new
 # fileset code to incorporate much more sophisticated fileset types.
 #
 # Limitations/Features:
 #
 #   ¥ Don't use file names with spaces. TeX doesn't like this, and nor
 #      does my code.
 #
 #   ¥ Commented out %\include or %\input commands are considered to
 #     represent a part of the fileset. If you don't want them, delete
 #     them.
 #
 #   ¥ Assumes all the \included files are in the same directory
 #     as the base file, or given by a relative path or in TeXInputsFolder.
 #     I  think this is ok.  Tell me if you disagree
 #
 #   ¥ You have to use the notation '\include{file}' not '\include file'
 #
 # History:
 #
 # modified  by  rev reason
 # --------  --- --- -----------
 # 04/08/95  VMD 1.0 original
 # 01/24/96  VMD 1.1 added comments for Tom
 # 02/21/96  VMD 1.2 integrated with LaTeX mode for Alpha core code
 # 03/06/96  VMD 1.3 got rid of 'bib:' and 'tex:' in favour of 3-item
 #                   lists. A number of other simplifications.
 # 03/24/96  VMD 1.4 integrated with new fileset-menu code rather than
 #                    the latex menu in particular.
 # 08/13/97  JEG 1.5 Added support for .eps \includegraphics
 # 08/21/98  JEG 1.6 Merged changes with Vince's unnumbered update for
 #                   Alpha 7.1
 # 08/24/98  VMD 1.7 Fixed tabs/spaces problem
 # 03/01/99  VMD 1.8 Various fixes/improvements for Tcl 8
 #
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

proc latexFilesets.tcl {} {}

# We do NOT want this file to load latex.tcl automatically because this
# might be loaded by the filesets code without the latex mode or menu
# being active at all.

set "filesetUtils(extractEpsBoxSizes)" [list "tex" texfs_extractProjectEpsBoxes]
set "filesetUtils(deleteEpsBoxSizes)"  [list "tex" texfs_deleteProjectEpsBoxes]

prefs::renameOld filesetmodeVars(hierarchicalBibFiles) \
  TeXmodeVars(scanBibFilesInFilesets)
prefs::renameOld filesetmodeVars(includeGraphicsFiles) \
  TeXmodeVars(includeGraphicsFilesInFilesets)

# To scan .bib files for '\input' commands when building TeX filesets, turn 
# this item on||To never scan .bib files for '\input' commands when building 
# TeX filesets, turn this item off
newPref flag scanBibFilesInFilesets 0 "TeX" filesetMenu::rebuildSome

# To include graphics files in TeX filesets (e.g. eps files), turn this item 
# on||To restrict TeX filesets to textual files only, turn this item off
newPref flag includeGraphicsFilesInFilesets 0 "TeX" filesetMenu::rebuildSome

prefs::dialogs::setPaneLists "TeX" "TeX Filesets" [list \
  "scanBibFilesInFilesets" \
  "includeGraphicsFilesInFilesets" \
  ]

hook::register fileset-delete {fileset::tex::deleteFileset} "tex"

namespace eval fileset::tex {}

proc fileset::tex::setDetails {name args} {

    global gfileSets fileSetsExtra
    
    set gfileSets($name) [lrange $args 0 0]
    set fileSetsExtra(${name},additionalFiles) [lindex $args 1]
    prefs::modified gfileSets($name) fileSetsExtra(${name},additionalFiles)
}

proc fileset::tex::getDialogItems {name} {
    
    global gfileSets fileSetsExtra
    
    if {![info exists fileSetsExtra(${name},additionalFiles)]} {
        set fileSetsExtra(${name},additionalFiles) [list]
    }
    return [list \
      [list [list "smallval" "file"] \
      "Base TeX File" [lindex $gfileSets($name) 0]] \
      [list [list "smallval" "filepaths"] \
      "Additional Related Files" $fileSetsExtra(${name},additionalFiles)] \
      ]
}

##
 # Given a fileset name and hence base file, scan through to create/update
 # everything that is included in it. Then add it all to the main menu.
 ##

proc fileset::tex::updateContents {name {andMenu 0}} {

    global fileSets gfileSets fileSetsExtra filesetmodeVars

    # get the base file
    set f [lindex $gfileSets($name) 0]

    # find all component .tex and .bib files
    set includes [texfs_findIncludes "[file dirname $f]" "$f" ]

    # store the document parts permanently
    set fileSetsExtra($name) $includes
    set fileSets($name) [fileset::tex::listFiles $name]

    # This line is troublesome when called from 'create', since
    # while it works, it doesn't follow quite the same behaviour
    # as the other filesets types, especially in the case of
    # temporary filesets.
    prefs::modified fileSets($name) fileSetsExtra($name)

    if {!$andMenu} return

    # the base file
    set pmenu [file tail [lindex $gfileSets($name) 0]]
    # the tex files
    set tmenu {}
    # the bib files
    set bmenu {}
    # extra files
    set emenu {}
    
    foreach f $fileSetsExtra($name) {
	# each item is a list whose first element says
	# if it's a bib or tex file.
	set ftype [lindex $f 0]
	set depth [expr {[lindex $f 1] *3}]
	set indent [string repeat " " [expr {$depth+1}]]
	# we don't show the directory in the menu
	set fname [file tail [lindex $f 2]]
	switch -- $ftype {
	    "tex" {
		if {$filesetmodeVars(sortFilesetItems) \
		  || !$filesetmodeVars(indentFilesetItems)} {
		    lappend tmenu "${fname}\&"
		} else {
		    lappend tmenu "${indent}${fname}\&"
		}
	    }
	    "eps" {
		if {$filesetmodeVars(sortFilesetItems)	\
		  || !$filesetmodeVars(indentFilesetItems)} {
		    lappend tmenu "È ${fname}\&"
		} else {
		    lappend tmenu "${indent}È ${fname}\&"
		}
	    }
	    "bib" {
		if {$filesetmodeVars(sortFilesetItems) \
		  || !$filesetmodeVars(indentFilesetItems)} {
		    # add a space to distinguish bib items
		    lappend bmenu "${fname} \&"
		} else {
		    # add a space to distinguish bib items
		    lappend bmenu "${indent}${fname} \&"
		}
	    }
	}
    }
    foreach f $fileSetsExtra(${name},additionalFiles) {
	lappend emenu "[file tail $f]\&"
    } 
    # make the menu
    set menu [list "$pmenu" "\(-"]
    if {$filesetmodeVars(sortFilesetItems)} {
	eval lappend menu [lsort -dictionary $tmenu]
	if [llength $bmenu] {
	    eval lappend menu "\(-" [lsort -dictionary $bmenu]
	}
	if [llength $emenu] {
	    eval lappend menu "\(-" [lsort -dictionary $emenu]
	}
    } else {
	eval lappend menu $tmenu
	if [llength $bmenu] {
	    eval lappend menu "\(-" $bmenu
	}
	if [llength $emenu] {
	    eval lappend menu "\(-" $emenu
	}
    }

    return [filesetMenu::makeSub $name $name fileset::openItemProc $menu]

}

##
 # ------------------------------------------------------------------------
 #	
 # "fileset::tex::selected" --
 #	
 # A tex fileset item was selected in a menu.  This proc should jump to the
 # actual file if it can find it.
 # ------------------------------------------------------------------------
 ##

proc fileset::tex::selected {fset menu item} {

    if {($menu eq "")} {
	set menu $fset
    }
    if {[file exists $item]} {
	set ff $item
    } else {
	set ff [texfs_awkwardGetFile [string trim $menu] [string trimleft ${item}]]
    }
    if {$ff != ""} {
	autoUpdateFileset $menu
	switch -- [string tolower [file extension $ff]] {
	    ".ps" -
	    ".eps" -
	    ".epsf" {
		switch -- [buttonAlert \
		  "Do you wish to view or edit \"[file tail $ff]\"?" \
		  "View" "Edit" "Cancel"] {
		    "View" {
			viewPSFile $ff
		    }
		    "Edit" {
			edit -c $ff
		    }
		}
	    }
	    default {
		edit -c $ff
	    }
	}
    } else {
	alertnote "Couldn't find '[string trim ${item}]'.  If this file is\
	  located in a sub-directory, you may need to set your\
	  'TeX Search Path' preference."
    }
    return
}

##
 # -------------------------------------------------------------------------
 #	
 # "fileset::tex::create" --
 #	
 # Create and add a TeX fileset.  Most of the work is done by
 # 'texFilesetUpdate'.
 # -------------------------------------------------------------------------
 ##

proc fileset::tex::create {{name ""}} {

    global gfileSets gfileSetsType fileSetsExtra

    # Base filename must end in ".tex" or ".ltx":
    set f [string trimright [getfile "Choose the base TeX file for this fileset."]]
    if {![string length $f]} return
    set ext [file extension $f]
    if {$ext != ".tex" && $ext != ".ltx"} {
	beep
	alertnote "File name must end in \".tex\" or \".ltx\"!"
	return [fileset::tex::create]
    }

    # Default fileset name is the name of the enclosing folder:
    set defaultName [file tail [file dirname $f]]
    if {![string length $name]} {
	set name [prompt "New TeX fileset name:" $defaultName]
    }
    if {![string length $name]} {
	status::msg "Cancelled -- no text was entered."
	return
    }
    # store the fileset name-basefile connection permanently
    set gfileSets($name) [list $f]
    set gfileSetsType($name) "tex"

    # this is used to create as well as update a fileset
    fileset::tex::updateContents $name 1
    return $name
}

proc fileset::tex::deleteFileset {args} {
    
    global fileSetsExtra
    
    set name [lindex $args 0]
    if {[info exists fileSetsExtra(${name},additionalFiles)]} {
        prefs::modified fileSetsExtra(${name},additionalFiles)
	unset fileSetsExtra(${name},additionalFiles)
    }
    return
}


proc texFilesetBaseName {fset} {
    global gfileSets
    return [lindex $gfileSets($fset) 0]
}

##
 # -------------------------------------------------------------------------
 #
 # "fileset::tex::listFiles" --
 #
 # Replacement for the original in latexFilesets.tcl.  Takes an optional
 # argument which should be either 'bib', 'tex', or 'eps'.  In such cases it
 # returns only the corresponding set of files from the set.
 # -------------------------------------------------------------------------
 ##

proc fileset::tex::listFiles {name {which "*"}} {

    global gfileSets fileSetsExtra

    if {![info exists fileSetsExtra(${name},additionalFiles)]} {
	set fileSetsExtra(${name},additionalFiles) [list]
    }
    set f [lindex $gfileSets($name) 0]

    set dir "[file dirname $f]"
    if {[string match $which "tex"]} {
	set fset [list $f]
    } else {
	set fset ""
    }
    foreach ff $fileSetsExtra($name) {
	if [string match $which [lindex $ff 0]] {
	    set newf [texfs_getFile "$dir" "$ff"]
	    if {$newf != ""} {
		lappend fset "$newf"
	    } elseif {[lindex $ff 0] == "eps"} {
		# look in graphicspath (4th item in $ff)
		foreach path [lindex $ff 3] {
		    # works for relative or absolute $path
		    set theDir [file dirname \
		      [file join [lindex $gfileSets($name) 0] $path]]
		    set newf [texfs_getFile $theDir $ff]
		    if {$newf != ""} {break}
		}
		if {$newf != ""} {
		    lappend fset "$newf"
		}
	    }
	}
    }
    foreach ff $fileSetsExtra(${name},additionalFiles) {
	lappend fset $ff
    }
    return $fset
}

##
 # -------------------------------------------------------------------------
 #
 # "texfs_findIncludes" --
 #
 # Does the bulk of creating a new fileset.  Gets all document parts by
 # scanning through a given file, recursively if necessary (although LaTeX
 # won't allow recursive \include, only \input
 #
 # Results:
 #
 #   A list of 'file descriptors' for each document component.  These are of
 #   the form {(tex|bib|eps) depth name (graphicspath)?}.
 #
 # -------------------------------------------------------------------------
 ##
proc texfs_findIncludes {dir file {already ""} {depth 0} {graphicspath ""} \
  {commands {input include DocInput DocInclude includegraphics}}} {

    global TeXmodeVars

    if {[string length $already]} {
	upvar 1 $already alreadyVar
    } else {
	set alreadyVar [list]
    }
    
    # Get graphicspath (if any), so we can pass it to our recursive search
    # of \include's

    # find '\graphicspath{{path}{path}{path}}' if it exists
    set pattern1 {\\graphicspath\{.*\}}
    set l [file::searchFor $file $pattern1]
    if {[string length $l]} {
	if {![regexp -indices {\{} $l ind]} {
	    error "Malformed \\graphicspath"
	}
	set l [string range $l [expr {[lindex $ind 0] + 1}] end]
	set nesting 1
	while {$nesting && [regexp -indices {[\{\}]} $l ind]} {
	    switch -- [string index $l [set ind [lindex $ind 0]]] {
		"\{" {
		    incr nesting
		}
		"\}" {
		    if {$nesting == 2} {
			lappend graphicspath \
			  [string range $l 0 [expr {$ind - 1}]]
		    }
		    incr nesting -1
		}
	    }
	    set l [string range $l [incr ind] end]
	}
    }

    set inc [list]

    # Do a grep for \input-like commands
    append pattern2 "\\\\" "\(" [join $commands "|"] "\)"
    set lgrep [grep $pattern2 $file]

    if {([lsearch -exact $alreadyVar $file] != -1)} {
	# We don't allow infinite recursion!  Assume this must be an old
	# include which is commented out.
	status::msg "Warning: found recursive include for $file"
	return [list]
    }
    lappend alreadyVar $file
    
    # Then look a bit closer at the lines that matched.  (This requires
    # arguments that make sense.)
    append pattern3 {\\input [-a-zA-Z0-9._:/]+} "\[" "\n " "\\\\" "\}\]" "|" \
      {\\(input|include|DocInclude|DocInput)} {\{([-a-zA-Z0-9._:/]+)\}} "|" \
      {\\includegraphics\*?(\[[^\]]*\])?\{([-a-zA-Z0-9._:/]+)\}}

    while {[regexp -indices $pattern3 $lgrep a]} {
	set match [string range $lgrep [lindex $a 0] [lindex $a 1]]
	set lgrep [string range $lgrep [lindex $a 1] end]
	# Now identify the command
	set rCmds $commands
	if {[regexp {^\\input } $match]} then {
	    # TeX-style \input
	    regexp {\\input ([-a-zA-Z0-9._:/]+)} $match a include
	    lappend inc [list tex $depth $include]
	} else {
	    regexp {\{([-a-zA-Z0-9._:/]+)\}$} $match a include
	    switch -glob -- $match {\\input*} {
		# LaTeX-style \input
		lappend inc [list tex $depth $include]
	    } {\\includegraphics*} {
		if {$TeXmodeVars(includeGraphicsFilesInFilesets)} {
		    lappend inc [list eps $depth $include $graphicspath]
		}
		continue
	    } {\\include*} {
		lappend inc [list tex $depth $include]
		set rCmds [lremove -- $commands include DocInclude]
	    } {\\DocInput*} {
		lappend inc [list tex $depth $include]
		set rCmds [list includegraphics]
	    } {\\DocInclude*} {
		append include .dtx
		lappend inc [list tex $depth $include]
		set rCmds [list includegraphics]
	    }
	}

	# recurse over input'ed files.
	set ff [texfs_getFile $dir [list tex $depth $include]]
	if {[string length $ff]} {
	    eval [list lappend inc] [texfs_findIncludes $dir $ff\
	      alreadyVar [expr {$depth+1}] $graphicspath $rCmds]
	} else {
	    status::msg "Warning: couldn't find '$include'"
	}
    }
    set pattern4 {\\(bibliography)(\{[^\{\}]+\})}
    # we can't use glob because the \bib... often spans multiple
    # lines
    set l [file::searchFor $file $pattern4]

    # find a '\bibliography{??,??,??}' if it exists
    if {$l != ""} {
	set include [join [split [string range $l 13 end] "\{\}%"]]
	# there may be multiple bibliographies
	foreach bibinclude [split $include ","] {
	    lappend inc [list bib $depth [string trim $bibinclude]]
	}

	# a flag to not search through .bib files, because
	# they can be enormous. (not yet implemented)
	if {$TeXmodeVars(scanBibFilesInFilesets)} {
	    set ff [texfs_getFile "$dir" [list bib $depth "$include"] ]
	    if {$ff != ""} {
		eval lappend inc \
		  [texfs_findIncludes "$dir" "$ff" alreadyVar \
		  [expr {$depth+1}]]
	    } else {
		status::msg "Warning: couldn't find '$include'"
	    }
	}


    }

   ##
    # Note that we use lists with 'tex' and 'bib' first elements above because
    # bibliographies and tex files may have the same name and we'd get confused
    # otherwise, because the array wouldn't have enough information (it doesn't
    # store full file extensions, just what was in the \include{})
    ##

    return $inc
}

##
 # -------------------------------------------------------------------------
 #
 # "texfs_awkwardGetFile" --
 #
 # Constructs the list with 'bib', 'tex', or 'eps' as appropriate and asks
 # for the correct full filename.  We use this procedure to get from an item
 # selected in a sub-menu to the actual file itself; i.e. we must deduce
 # whether it is a tex, bib, or eps file and where it comes from etc.
 #
 # -------------------------------------------------------------------------
 ##

proc texfs_awkwardGetFile {proj fname}  {

    global fileSetsExtra gfileSets
    
    # First find out if this is an additional file specified by the user.
    if {![info exists fileSetsExtra(${proj},additionalFiles)]} {
        set fileSetsExtra(${proj},additionalFiles) [list]
    }
    foreach fileName $fileSetsExtra(${proj},additionalFiles) {
	set fileName1 [file tail $fileName]
	set fileName2 [file root $fileName1]
        if {($fileName1 eq $fname) || ($fileName2 eq $fname)} {
            return $fileName
        }
    } 
    # we cheated by adding a space to the end of the bibliographies and a
    # 'È' to the start of graphics includes
    if {[string first "È" $fname] != -1} {
	set type "eps"
	set fname  [string trimleft $fname " È"]
    } elseif {[string last " " $fname] != -1} {
	set type "bib"
	set fname [string trimright $fname]
    } else {
	set type "tex"
    }

    # if it's the actual fileset file, return it.
    if {[file tail [lindex $gfileSets($proj) 0]] eq $fname} {
	return [lindex $gfileSets($proj) 0]
    }

    foreach f $fileSetsExtra($proj) {
	if {[lindex $f 0] eq $type && [string equal $fname [lindex $f 2] ]} {
	    set fdesc $f
	    break
	}
    }
    if {![info exists fdesc]} {
	set fpat "*${fname}"
	foreach f $fileSetsExtra($proj) {
	    if {[lindex $f 0] eq $type && [string match $fpat [lindex $f 2] ]} {
		set fdesc $f
		break
	    }
	}
    }

    if {[info exists fdesc]} {
	set ff [texfs_getFile [file dirname [lindex $gfileSets($proj) 0]] $fdesc]
	if {$ff == "" && $type == "eps"} {
	    foreach path [lindex $f 3] {
		# Works for relative or absolute $path
		set thePath [file join [file dirname [lindex $gfileSets($proj) 0]] $path]
		set ff [texfs_getFile $path $fdesc]	
		if {$ff != ""} {break}
	    }
	}
	return $ff
    } else {
	alertnote "Internal latex fileset error: couldn't find a file\
	  for '$fname'."
	return ""
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "texfs_getFile" --
 #
 # Search for the file.  'fdesc' is actually a list whose first element is
 # either 'bib', 'tex', or 'eps', and whose third element is the filename
 # (possibly with a relative path incorporated).  'dir' is the base directory
 # of the fileset.  We also search in TeXInputs.  For 'eps' files, we search
 # the fourth element, which is the graphicspath.
 #
 # We've now added a 3rd parameter, which prevents recursion while avoiding
 # the old bug which could prevent the texsearchpath from being searched.
 #
 # -------------------------------------------------------------------------
 ##

proc texfs_getFile {dir fdesc {recurse 0}} {

    global TeXmodeVars

    set f [string trim [lindex $fdesc 2]]
    set type [lindex $fdesc 0]
    # build path if filename has path specification
    if {[string trimleft $f [file separator]] eq $f \
      || "[file separator][string trimleft $f [file separator]]" eq $f} {
    } else {
	set dirsUp [expr {[string length $f] - [string length [string trimleft $f [file separator]]]}]
	incr dirsUp -1
	for {set iDirNum 1} {$iDirNum <= $dirsUp} {incr iDirNum} {
	    set dir [file dirname $dir]
	}
    }
    set ff [file normalize [file join ${dir} $f]]
    if {[file exists ${ff}.${type}]} {
	append ff ".$type"
    }
    if {[file exists $ff]} {
	return "$ff"
    } else {
	# try in 'TeXSearchPath'
	if {[info exists TeXmodeVars(TeXSearchPath)] && !$recurse} {
	    foreach dd $TeXmodeVars(TeXSearchPath) {
		set ff [texfs_getFile $dd $fdesc 1]
		if {[file exists $ff]} {
		    return "$ff"
		} else {
		    return ""
		}
	    }
	    return ""
	} else {
	    return ""
	}
    }
}

# ×××× -------- ×××× #

# From here down are all the things for the Fileset Utilities sub-menu.

##
 # -------------------------------------------------------------------------
 #
 # "texfs_boxManipulation" --
 #
 # Searches for boxMacroName command, and calls a given proc for each one in
 # turn.
 # -------------------------------------------------------------------------
 ##

proc texfs_boxManipulation {proc {file ""}} {

    global TeXmodeVars

    if {$file == ""} {
	set dir [file dirname [win::Current]]
    } else {
	filesetRememberOpenClose "$file"
	file::openQuietly "$file"
	set dir [file dirname "$file" ]
    }

    foreach boxMacroName $TeXmodeVars(boxMacroNames) {
	set exp "\\${boxMacroName}(\\\[.*\\\])\{(\[-a-zA-Z0-9._\]+)\}"
	set p [search -s -f 1 -r 1 -n $exp [minPos]]
	set n 0
	
	while {$p != ""} {
	    eval $proc $p
	    incr n
	    set p [search -s -f 1 -r 1 -n $exp [lindex $p 1]]
	}
    }

    if {$file != ""} {
	filesetRevertOpenClose $file
    }

    return $n
}

# proc texfs_boxManipulation {proc {file ""}} {
#   global boxMacroName
#   if {$file == ""} {
#     set dir [file dirname [win::Current]]
#   } else {
#     filesetRememberOpenClose "$file"
#     file::openQuietly "$file"
#     set dir [file dirname "$file" ]
#   }
#
#   # find all '\$boxMacroName{??}'
#   set exp "\\${boxMacroName}(\\\[.*\\\])\{(\[-a-zA-Z0-9._\]+)\}"
#   set p [search -s -f 1 -r 1 -n $exp [minPos]]
#   set n 0
#
#   while {$p != ""} {
#     eval $proc $p
#     incr n
#     set p [search -s -f 1 -r 1 -n $exp [lindex $p 1]]
#   }
#
#   if {$file != ""} {
#     filesetRevertOpenClose $file
#   }
#
#   return $n
# }

proc texfs_deleteFilesetEpsBoxes {} {

    global currFileSet

    iterateFileset "$currFileSet" "texfs_boxManipulation texfs_deleteEpsBoxes"
}

proc texfs_deleteEpsBoxes {start end} {

    set found [getText $start $end]
    set bbfound ""

    if {[regexp -indices {bb *= *[0-9.]+ +[0-9.]+ +[0-9.]+ +[0-9.]+} "$found" a ]} {
	set spos [pos::math $start + [lindex $a 0] ]
	set epos [pos::math $start + [lindex $a 1] +1]
	replaceText $spos $epos ""
	if {[lookAt $spos] == ","} {
	    replaceText $spos [pos::math $spos + 1] ""
	} elseif {[getText [pos::math $spos -1] [pos::math $spos +1]] == "\[\]"} {
	    replaceText [pos::math $spos -1] [pos::math $spos + 1] ""
	}
    }
}

proc texfs_extractFilesetEpsBoxes {} {

    global currFileSet
    # don't do bib files
    iterateFileset "$currFileSet" "texfs_boxManipulation texfs_extractEpsBoxes"
}

proc texfs_extractEpsBoxes {start end} {

    #   global boxMacroName
    set eexp "\{(\[-a-zA-Z0-9._\]+)\}"
    set dir [file dirname [win::Current]]

    set found [getText $start $end]
    set bbfound ""

    regexp {bb *= *([0-9.]+ +[0-9.]+ +[0-9.]+ +[0-9.]+)} "$found" dummy bbfound
    regexp {^\\([a-zA-Z]*\*?)} $found dummy boxMacroName
    set insertpos [pos::math $start + [string length $boxMacroName]]
    regexp -- $eexp $found dummy epsfile
    set epsfile [texfs_getFile $dir "eps:$epsfile" ]
    set bb [texfs_getEpsBoxFromFile $epsfile]

    if {$bbfound != ""} {
	# there already is a bounding box specified
	regsub -all " +" $bbfound " " bbfound
	regsub -all " +" $bb " " bb
	if {$bb != $bbfound} {
	    alertnote "Bounding box for '$found' has changed.\
	      Remove the old definition to re-extract."
	}
    } else {
	# no 'bb=' so let's put one in if we can.
	if {$bb != ""} {
	    if {[lookAt $insertpos] != "\["} {
		replaceText $insertpos $insertpos "\[\]"
		incr insertpos
	    } else {
		incr insertpos
		replaceText $insertpos $insertpos ","
	    }
	    replaceText $insertpos $insertpos "bb=${bb}"
	
	}
    }

}

proc texfs_getEpsBoxFromFile {f} {

    if {[file exists $f]} {
	set bb [grep "%%BoundingBox" "$f"]
	regexp {[0-9.]+ +[0-9.]+ +[0-9.]+ +[0-9.]+} "$bb" bb
	return $bb
    } else {
	return ""
    }
}

##
 # proc	texFindTag {} {
 #	   global gfileSets	tagFile	currFileSet
 #	   set t $tagFile
 #	   set tagFile [file join [file dirname $gfileSets($currFileSet)] ${currFileSet}TAGS]
 #	   findTag
 #	   set tagFile $t
 # }
 ##

proc texCreateTagFile {}  {

    global funcExpr tagFile

    # finds all labels in the current fileset.
    set tagFile [tags::name]
    set f "$funcExpr"
    set funcExpr {\\label\{[-a-zA-Z0-9_]+\}}
    uplevel \#0 tags::createFile
    set funcExpr $f
}

#set  "texfs_filesetUtils(extractEpsBoxSizes)" "texfs_boxManipulation texfs_extractEpsBoxes"
#set  "texfs_filesetUtils(deleteEpsBoxSizes)" "texfs_boxManipulation texfs_deleteEpsBoxes"

proc texIterateCheck {{proj ""} {f ""}} {

    global texfs_notex texfs_nobib

    switch -- $proj {
	"check" {
	    set type [listpick -p "TeX, Bib or both?" \
	      -L "TeX only" {"TeX only" "Bib only" "both"} ]
	    switch -- $type {
		"Bib only" {
		    set texfs_notex 1
		    set texfs_nobib 0
		}
		"both" {
		    set texfs_notex 0
		    set texfs_nobib 0
		}
		default {
		    set texfs_notex 0
		    set texfs_nobib 1
		}					
	    }		
	
	}
	"done" {
	    unset texfs_notex
	    unset texfs_nobib
	}
	default {
	    set isbib [expr {![string compare [file extension $f] ".bib"]}]
	    if {$isbib && $texfs_nobib} {return 1}
	    if {!$isbib && $texfs_notex} {return 1}
	    return 0
	}
    }
}

# ==========================================================================
#
# .