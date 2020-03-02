## -*-Tcl-*-
 # ###################################################################
 # 
 #  FILE: "diffDrivers.tcl"
 #                                    created: 2005-09-23 0:07:08
 #                                last update: 2005-10-11 12:20:57
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 #  Copyright (c) 1997-2005  Vince Darley, all rights reserved
 # 
 #  Description:
 #  
 #  This file contains the xserv 'diff' drivers for Alpha, and also
 #  the compare drivers.  
 #  
 #  The 'diff' service is a low level service: it receives a couple
 #  of paths (and some options) and returns the diff output as a string
 #  
 #  The 'compare' service is a high-level service: given a couple
 #  of paths (and some options) it spawns some graphical interface
 #  to display and navigate the diff result.  The main 'compare'
 #  service is Alpha's 'Diff Mode'.  The 'compare' driver called
 #  "AlphaTcl's internal Diff Mode" essentially just calls
 #  [compare::execute] with the appropriate arguments.
 #  
 ##
 


# ×××× diff drivers ×××× #

proc diffDrivers.tcl {} {}

namespace eval Diff {}
namespace eval compare {}

# Usage: diff [-#] [-abBcdefhHilnNprstTuvw] [-C lines] [-F regexp] [-I regexp]
#        [-L label [-L label]] [-S file] [-D symbol] [+ignore-blank-lines]
#        [+context[=lines]] [+unified[=lines]] [+ifdef=symbol]
#        [+show-function-line=regexp]
#        [+speed-large-files] [+ignore-matching-lines=regexp] [+new-file]
#        [+initial-tab] [+starting-file=file] [+text] [+all-text] [+ascii]
#        [+minimal] [+ignore-space-change] [+ed] [+reversed-ed] [+ignore-case]
#        [+print] [+rcs] [+show-c-function] [+binary] [+brief] [+recursive]
#        [+report-identical-files] [+expand-tabs] [+ignore-all-space]
#        [+file-label=label [+file-label=label]] [+version] path1 path2

::xserv::declare Diff \
  "Calculate differences between files, returning result as a string" \
 oldfile newfile {options ""}

::xserv::register Diff GNUdiff \
  -sig DIFF -path [file join $HOME Tools "GNU Diff"] \
  -driver {
    array set diffopts $params(options)
    set flags ""
    if { [info exists diffopts(diffFlags)] } {
	append flags $diffopts(diffFlags)
    }
    # There is a potential conflict between flags given in diffFlags
    # and flags given in the verbose style:
    if { [info exists diffopts(linesOfContext)] &&
      $diffopts(linesOfContext) != 0 } {
	lappend flags -C $diffopts(linesOfContext)
    }
    if { [info exists diffopts(treatAllFilesAsText)] &&
      $diffopts(treatAllFilesAsText) } {
	lappend flags -a
    }
    if { [info exists diffopts(ignoreCase)] &&
      $diffopts(ignoreCase) } {
	lappend flags -i
    }
    if { [info exists diffopts(ignoreBlankLines)] &&
      $diffopts(ignoreBlankLines) } {
	lappend flags -B
    }
    if { [info exists diffopts(ignoreSpaceChanges)] &&
      $diffopts(ignoreSpaceChanges) } {
	lappend flags -b
    }
    if { [info exists diffopts(ignoreWhiteSpace)] &&
      $diffopts(ignoreWhiteSpace) } {
	lappend flags -w
    }
    if { [info exists diffopts(compareDirectoriesRecursively)] &&
      $diffopts(compareDirectoriesRecursively) } {
	lappend flags -r
    }
    tclAE::build::resultData -n $params(xservTarget) misc dosc \
      --- [tclAE::build::TEXT "$flags $params(oldfile) $params(newfile)"]
}




# compare::canonical_diffopts --
#
#       Convert a list of diff options to canonical (long) form.
#
# Parameters:
#       optL -- The list of options, in a format such that (in 
#               Tcl 8.5+) a command on the form
#                   exec diff {expand}$optL $file1 $file2
#               should work.
#
# Results:
#       An equivalent list of options on canonical form, i.e., 
#       with exactly one list element per option.
#
#       The reference set of options is that of the GNU diffutils
#       (version 2.8.1, 5 April 2002).
#
# Side effects:
#       None.

proc compare::canonical_diffopts {optL} {
    set res [list]
    set argtype none
    foreach opt $optL {
	if {$argtype eq "int"} then {
	    if {[scan $opt %d num]>0} then {
		lappend res $prefix=$num
	    } else {
		lappend res $prefix
	    }
	    set argtype none
	    continue
	} elseif {$argtype eq "string"} then {
	    lappend res $prefix=$opt
	    set argtype none
	    continue
	}
	
	switch -regexp -- $opt {
	    ^-[abBcdeEfilnNpqrstTuvwy]+$ {
		# Simple option, may need to be split up
		foreach c [split $opt ""] {
		    switch -- $c "a" {
			lappend res --text
		    } "b" {
			lappend res --ignore-space-change
		    } "B" {
			lappend res --ignore-blank-lines
		    } "c" {
			lappend res --context
		    } "d" {
			lappend res --minimal
		    } "e" {
			lappend res --ed
		    } "E" {
			lappend res --ignore-tab-expansion
		    } "f" {
			lappend res --forward-ed
		    } "i" {
			lappend res --ignore-case
		    } "l" {
			lappend res --paginate
		    } "n" {
			lappend res --rcs
		    } "N" {
			lappend res --new-file
		    } "p" {
			lappend res --show-c-function
		    } "q" {
			lappend res --brief
		    } "r" {
			lappend res --recursive
		    } "s" {
			lappend res --report-identical-files
		    } "t" {
			lappend res --expand-tabs
		    } "T" {
			lappend res --initial-tab
		    } "u" {
			lappend res --unified
		    } "v" {
			lappend res --version
		    } "w" {
			lappend res --ignore-all-space
		    } "y" {
			lappend res --side-by-side
		    }
		}
		# End processing of simple options
	    }
	    ^-[CUW] {
		# Options with integer argument
		switch -- [string index $opt 1] {
		    C {set prefix --context}
		    U {set prefix --unified}
		    W {set prefix --width}
		}
		if {[scan $opt {-%*[CUW]%d} lines]>0} then {
		    lappend res $prefix=$lines
		} else {
		    set argtype int
		}
	    }
	    ^-[DFISxX] {
		# Options with string argument
		switch -- [string index $opt 1] {
		    D {set prefix --ifdef}
		    F {set prefix --show-function-line}
		    I {set prefix --ignore-matching-lines}
		    S {set prefix --starting-file}
		    x {set prefix --exclude}
		    X {set prefix --exclude-from}
		}
		if {[string length $opt]>2} then {
		    lappend res $prefix=[string range $opt 2 end]
		} else {
		    set argtype string
		}
	    }
	    default {
		# If long option abbreviations are to be supported,
		# code for expanding them must be added here.
		lappend res $opt
	    }
	}
    }
    return $res
}


# Diff::opts_from_modevars --
#
#       Convert the contents of the DiffmodeVars array 
#       (or any array in the calling context with the same 
#       format) to a list of canonical diff options.
#
# Parameters:
#       arrname (optional)  -- The name of the source array.
#                              Defaults to ::DiffmodeVars.
#                              Name is resolved in the calling context.
#
# Results:
#       An equivalent list of options on canonical form.
# 
# Side effects:
#       None.
#
proc Diff::opts_from_modevars {{arrname ::DiffmodeVars}} {
    upvar 1 $arrname A
    set res [list]
    if {[info exists A(treatAllFilesAsText)] && $A(treatAllFilesAsText)}\
      then {lappend res --text}
    if {[info exists A(linesOfContext)] &&\
      [string is integer $A(linesOfContext)]} then {
	lappend res [format {--context=%d} $A(linesOfContext)]
    }
    if {[info exists A(ignoreCase)] && $A(ignoreCase)}\
      then {lappend res --ignore-case}
    if {[info exists A(ignoreBlankLines)] && $A(ignoreBlankLines)}\
      then {lappend res --ignore-blank-lines}
    if {[info exists A(ignoreSpaceChanges)] && $A(ignoreSpaceChanges)}\
      then {lappend res --ignore-space-change}
    if {[info exists A(ignoreWhiteSpace)] && $A(ignoreWhiteSpace)}\
      then {lappend res --ignore-all-space}
    if {[info exists A(compareDirectoriesRecursively)] &&\
      $A(compareDirectoriesRecursively)}\
      then {lappend res --recursive}
    if {[info exists A(diffFlags)]} then {
	eval [list lappend res]\
	  [compare::canonical_diffopts $A(diffFlags)]
    }
    return $res
}

# *** APPLESCRIPT TERMINOLOGY FOR Diff'nPatch ***
# *** with AE sigs, where known
# 
# Required Suite: Terms that every application should support
# 
# MacDiff suite: Specific MacDiff events
# 
# Diff: Execute a diff
#       Diff
#    Oldf       old  alias  -- the old file
#    Newf       new  alias  -- the new file
#    Frmt       [in format  integer]  -- the output format (1=normal, 2=context, 3=unified, 4=side-by-side, 5=ifdef, 6=brief)
#    Cntx       [context lines  integer]  -- the number of context lines
#               [column width  integer]  -- the column width
#               [both endings  Undefined/Mac/Unix/Windows]  -- Line endings for both files. 0=undefined, 1=mac, 2=unix, 3=win. Default is 0: let DiffBOA guess.
#    Eol1       [old endings  Undefined/Mac/Unix/Windows]  -- Line endings for old file. 0=undefined, 1=mac, 2=unix, 3=win. Default is 0: let DiffBOA guess.
#    Eol2       [new endings  Undefined/Mac/Unix/Windows]  -- Line endings for new file. 0=undefined, 1=mac, 2=unix, 3=win. Default is 0: let DiffBOA guess.
#    Text       [treat as text  boolean]  -- 'Treat as text' option (default is 1)
#    Igca       [ignore case  boolean]  -- -ignore-case option
#    Igbl       [ignore blank lines  boolean]  -- -ignore-blank-lines option
#    Igsp       [ignore space change  boolean]  -- -ignore-space-change option
#    Igal       [ignore all space  boolean]  -- -ignore-all-space option
#               [expand tabs  boolean]  -- -expand-tabs option
#               [initial tab  boolean]  -- -initial-tab option
#               [ignore tab expansion  boolean]  -- -ignore-tab-expansion option
#    Recu       [recursive  boolean]  -- the recursive option
#               [report identical files  boolean]  -- -report-identical-files option
#               [new file  boolean]  -- -new-file option
#               [unidir new file  boolean]  -- -unidir-new-file option
#               [show c function  boolean]  -- -show-c-function option
#               [left column  boolean]  -- -left-column option
#               [suppress common  boolean]  -- -suppress-common option
#               [short unified  boolean]  -- Reports only the differing lines nums in unified format
#               [ifdef constant  string]  -- the constant for ifdef format
#    Xpat       [exclude pattern  string]  -- -exclude-pattern option
#               [ign match lines  string]  -- -ign-match-lines option
#               [label1  string]  -- the label1 option
#               [label2  string]  -- the label2 option
#               [new group  string]  -- the new group option
#               [old group  string]  -- the old group option
#               [changed group  string]  -- the changed group option
#               [unchanged group  string]  -- the unchanged group option
#               [new line  string]  -- the new line option
#               [old line  string]  -- the old line option
#               [unchanged line  string]  -- the unchanged line option
#       Result:   string  -- the diff output
# 
# Get version: return the version number
#       Get version
#       Result:   string  -- the GNU diff version and Mac sub-version
# 


proc compare::DiffBOAdriver {target oldfile newfile optL} {
    
    foreach opt $optL {
	switch -glob -- $opt --text {
	    set AE(Text) [tclAE::build::bool 1]
	} --ignore-space-change {
	    set AE(Igsp) [tclAE::build::bool 1]
	} --ignore-blank-lines {
	    set AE(Igbl) [tclAE::build::bool 1]
	} --binary {
	    set AE(Text) [tclAE::build::bool 0]
	} --context* {
	    set AE(Frmt) 2
	    if {[scan $opt --context=%d num]>0} then {
		set AE(Cntx) $num
	    }
	} --changed-group-format=* { # ToDo
	} --minimal { # Apperars unsupported
	} --ifdef=* {
	    set AE(Frmt) 5
	    # ToDo: specify ifdef constant
	} --ed - --forward-ed - --rcs { 
	    # Apperars unsupported
	    # Throw error?
	} --ignore-tab-expansion { # ToDo
	} --show-function-line=* { # ToDo
	} --from-file=* - --to-file=* { 
	    # Unsupported?
	} --help { # Apperars unsupported
	} --horizon-lines=* { # Apperars unsupported
	} --ignore-case {
	    set AE(Igca) [tclAE::build::bool 1]
	} --ignore-matching-lines=* { # ToDo: ign match lines
	} --ignore-file-name-case { # Appears unsupported
	} --paginate { # Appears unsupported
	} --label=* { 
	    # ToDo. 
	    # Note that this option may be given twice
	} --left-column { # ToDo
	} --line-format=* { 
	    # ToDo. 
	    # This would set all of new line, old line, and
	    # unchanged line.
	} --new-file { # ToDo
	} --new-group-format=* { # ToDo.     
	} --new-line-format=* { # ToDo.     
	} --old-group-format=* { # ToDo.     
	} --old-line-format=* { # ToDo.     
	} --show-c-function { # ToDo.     
	} --brief {
	    set AE(Frmt) 6
	} --recursive {
	    set AE(Recu) [tclAE::build::bool 1]
	} --report-identical-files { # ToDo.     
	} --starting-file=* { # Appears unsupported
	} --speed-large-files { # Appears unsupported
	} --strip-trailing-cr { 
	    # Appears unsupported,
	    # perhaps unnecessary
	} --suppress-common-lines { # ToDo.     
	} --expand-tabs { # ToDo.     
	} --initial-tab { # ToDo.     
	} --unchanged-group-format=* { # ToDo.     
	} --unchanged-line-format=* { # ToDo.     
	} --unidirectional-new-file { # ToDo
	} --unified* {
	    set AE(Frmt) 3
	    if {[scan $opt --unified=%d num]>0} then {
		set AE(Cntx) $num
	    }
	} --version {
	    #return [tclAE::build::resultData -n $target Diff ¥¥¥¥]
	    return "To do."
	} --ignore-all-space {
	    set AE(Igal) [tclAE::build::bool 1]
	} --width=* { # ToDo
	} --exclude=* {
	    set AE(Xpat) [tclAE::build::TEXT [string range $opt 11 end]]
	} --exclude-from=* { # Appears unsupported 
	} --side-by-side {
	    set AE(Frmt) 4
	}
    }
    
    set AE(Oldf) [tclAE::build::alis [file normalize $oldfile]]
    if {[llength [set wins [file::hasOpenWindows $oldfile]]]} then {
	set AE(Eol1) [dict get {mac 1 unix 2 win 3}\
	  [win::getInfo [lindex $wins 0] platform]]
    }
    
    set AE(Newf) [tclAE::build::alis [file normalize $newfile]]
    if {[llength [set wins [file::hasOpenWindows $newfile]]]} then {
	set AE(Eol2) [dict get {mac 1 unix 2 win 3}\
	  [win::getInfo [lindex $wins 0] platform]]
    }
    
    eval [linsert [array get AE] 0 \
      tclAE::build::resultData -n $target Diff Diff] 
}
 
set DiffBOAdriver {
   set aevt [list tclAE::build::resultData -n $params(xservTarget) Diff Diff]
   lappend aevt Oldf [tclAE::build::alis $params(oldfile)]
   lappend aevt Newf [tclAE::build::alis $params(newfile)]
   array set diffopts $params(options)
   if { [info exists diffopts(linesOfContext)] &&
     $diffopts(linesOfContext) != 0 } {
     lappend aevt Frmt 2 Cntx $diffopts(linesOfContext)
   }
   
   if {[llength [set wins [file::hasOpenWindows $params(oldfile)]]]} {
     getWinInfo -w [lindex $wins 0] winfo
     switch -exact -- $winfo(platform) {
       "mac"   { lappend aevt Eol1 1 }
       "unix"  { lappend aevt Eol1 2 }
       "win"   { lappend aevt Eol1 3 }
     }
   }
   if {[llength [set wins [file::hasOpenWindows $params(newfile)]]]} {
     getWinInfo -w [lindex $wins 0] winfo
     switch -exact -- $winfo(platform) {
       "mac"   { lappend aevt Eol2 1 }
       "unix"  { lappend aevt Eol2 2 }
       "win"   { lappend aevt Eol2 3 }
     }
   }
   if { [info exists diffopts(treatAllFilesAsText)] &&
     !$diffopts(treatAllFilesAsText) } {
       lappend aevt Text [tclAE::build::bool 0]
       # Default is NOT to treat all files as text
   }
   if { [info exists diffopts(ignoreCase)] && $diffopts(ignoreCase) } {
       lappend aevt Igca [tclAE::build::bool 1]
   }
   if { [info exists diffopts(ignoreBlankLines)] && $diffopts(ignoreBlankLines) } {
       lappend aevt Igbl [tclAE::build::bool 1]
   }
   if { [info exists diffopts(ignoreSpaceChanges)] &&
     $diffopts(ignoreSpaceChanges) } {
       lappend aevt Igsp [tclAE::build::bool 1]
   }
   if { [info exists diffopts(ignoreWhiteSpace)] && $diffopts(ignoreWhiteSpace) } {
       lappend aevt Igal [tclAE::build::bool 1]
   }
   if { [info exists diffopts(compareDirectoriesRecursively)] &&
     $diffopts(compareDirectoriesRecursively) } {
       lappend aevt Recu [tclAE::build::bool 1]
   }
   # Respect the --exclude flag (by default to avoid .DS_Store files).
   # Eventually, this driver should learn to understand other diffFlags.
   # DiffBOA has plenty of support for all those flags...
   if { [info exists diffopts(diffFlags)] } {
       if { [regexp -- {(--exclude=|-x\s*)(\S*)} $diffopts(diffFlags) - -> pat ] } {
	   lappend aevt Xpat [tclAE::build::TEXT $pat]
       }
   }
   eval $aevt
}
::xserv::register Diff DiffBOA -sig DifB -driver $DiffBOAdriver
::xserv::register Diff Diff'nPatch -sig DfPa -driver $DiffBOAdriver
::xserv::register Diff MacDiff -sig MDif -driver $DiffBOAdriver
unset DiffBOAdriver


# It seems that the diff implementation of diff cannot cope with files
# with mac line-endings.  I think it should try to detect that situation
# (using a few blocks of code from the DiffBOA driver script), and abort
# rather than giving an absurd result.  (Unless suddenly diff improves in
# this respect, perhaps the shortcoming should be overcome by writing
# a temporary file, equal but with unix line-endings...  sort of 
# convoluted -- perhaps it is better just to stick with DiffBOA...)
::xserv::register Diff diff -driver {
    set cmdline [list $params(xserv-diff)]
    array set diffopts $params(options)
    if { [info exists diffopts(diffFlags)] } {
	foreach opt $diffopts(diffFlags) {
	    lappend cmdline $opt
	}
    }
    # There is a potential conflict between flags given in diffFlags
    # and flags given in the verbose style:
    if { [info exists diffopts(linesOfContext)] &&
      $diffopts(linesOfContext) != 0 } {
	lappend cmdline -C $diffopts(linesOfContext)
    }
    if { [info exists diffopts(treatAllFilesAsText)] &&
      $diffopts(treatAllFilesAsText) } {
	lappend cmdline -a
    }
    if { [info exists diffopts(ignoreCase)] && $diffopts(ignoreCase) } {
	lappend cmdline -i
    }
    if { [info exists diffopts(ignoreBlankLines)] && $diffopts(ignoreBlankLines) } {
	lappend cmdline -B
    }
    if { [info exists diffopts(ignoreSpaceChanges)] &&
      $diffopts(ignoreSpaceChanges) } {
	lappend cmdline -b
    }
    if { [info exists diffopts(ignoreWhiteSpace)] && $diffopts(ignoreWhiteSpace) } {
	lappend cmdline -w
    }
    if { [info exists diffopts(compareDirectoriesRecursively)] &&
      $diffopts(compareDirectoriesRecursively) } {
	lappend cmdline -r
    }
#     if { [lsearch -regexp $cmdline "(--exclude.*|-x.*)"] == -1 } {
# 	lappend cmdline "--exclude=.DS_Store"
#     }
    lappend cmdline $params(oldfile) $params(newfile)
    return $cmdline
} -progs {diff}

namespace eval list { namespace export longestCommonSubsequence }

# list::longestCommonSubsequence --
#
#       Computes the longest common subsequence of two lists.
#
# Parameters:
#       sequence1, sequence2 -- Two lists to compare.
#
# Results:
#       Returns a list of two lists of equal length.
#       The first sublist is of indices into sequence1, and the
#       second sublist is of indices into sequence2.  Each corresponding
#       pair of indices corresponds to equal elements in the sequences;
#       the sequence returned is the longest possible.
#
# Side effects:
#       None.

proc list::longestCommonSubsequence { sequence1 sequence2 } {

    # Construct a set of equivalence classes of lines in file 2

    set index 0
    foreach string $sequence2 {
	lappend eqv($string) $index
	incr index
    }

    # K holds descriptions of the common subsequences.
    # Initially, there is one common subsequence of length 0,
    # with a fence saying that it includes line -1 of both files.
    # The maximum subsequence length is 0; position 0 of
    # K holds a fence carrying the line following the end
    # of both files.

    lappend K [list -1 -1 {}]
    lappend K [list [llength $sequence1] [llength $sequence2] {}]
    set k 0

    # Walk through the first file, letting i be the index of the line and
    # string be the line itself.

    set i 0
    foreach string $sequence1 {

	# Consider each possible corresponding index j in the second file.

	if { [info exists eqv($string)] } {

	    # c is the candidate match most recently found, and r is the
	    # length of the corresponding subsequence.

	    set c [lindex $K 0]
	    set r 0

	    foreach j $eqv($string) {

		# Perform a binary search to find a candidate common
		# subsequence to which may be appended this match.

		set max $k
		set min $r
		set s [expr { $k + 1 }]
		while { $max >= $min } {
		    set mid [expr { ( $max + $min ) / 2 }]
		    set bmid [lindex [lindex $K $mid] 1]
		    if { $j == $bmid } {
			break
		    } elseif { $j < $bmid } {
			set max [expr {$mid - 1}]
		    } else {
			set s $mid
			set min [expr { $mid + 1 }]
		    }
		}

		# Go to the next match point if there is no suitable
		# candidate.

		if { $j == [lindex [lindex $K $mid] 1] || $s > $k} {
		    continue
		}

		# s is the sequence length of the longest sequence
		# to which this match point may be appended. Make
		# a new candidate match and store the old one in K
		# Set r to the length of the new candidate match.

		set newc [list $i $j [lindex $K $s]]
		lset K $r $c
		set c $newc
		set r [expr $s+1]

		# If we've extended the length of the longest match,
		# we're done; move the fence.

		if { $s >= $k } {
		    lappend K [lindex $K end]
		    incr k
		    break
		}

	    }

	    # Put the last candidate into the array

	    lset K $r $c

	}

	incr i

    }

    set q [lindex $K $k]

    for { set i 0 } { $i < $k } {incr i } {
	lappend seta {}
	lappend setb {}
    }
    while { [lindex $q 0] >= 0 } {
	incr k -1
	lset seta $k [lindex $q 0]
	lset setb $k [lindex $q 1]
	set q [lindex $q 2]
    }

    return [list $seta $setb]

}


::xserv::register Diff "Built in file comparison" -mode Alpha \
  -driver {
    set lines1 [split [file::readAll $params(oldfile)] \n]
    set lines2 [split [file::readAll $params(newfile)] \n]

    set i 0
    set j 0

    #       Puts out a list of lines consisting of:
    #               n1<TAB>n2<TAB>line
    #
    #       where n1 is a line number in the first file, and n2 is a
    #       line number in the second file.  The line is the text of the
    #       line.  If a line appears in the first file but not the
    #       second, n2 is omitted, and conversely, if it appears in the
    #       second file but not the first, n1 is omitted.

    set res {}
    lappend res \
      "*** $params(oldfile)\tdate" \
      "--- $params(newfile)\tdate"
    
    foreach { x1 x2 } [list::longestCommonSubsequence $lines1 $lines2] {
	foreach p $x1 q $x2 {
	    if {$i < $p || $j < $q} {
		lappend res "***************" \
		  "*** $i,$p ***"
	    }
	    # Here's where we'd put in some lines of context before
	    while { $i < $p } {
		set l [lindex $lines1 $i]
		incr i
		lappend res "+ $l"
	    }
	    if {$j < $q} {
		lappend res "--- $j,$q ---"
		while { $j < $q } {
		    set m [lindex $lines2 $j]
		    incr j
		    lappend res "- $m"
		}
		lappend res "  [lindex $lines2 [expr {$j +1}]]"
	    }
	    set l [lindex $lines1 $i]
	    # Here's where we'd put in some lines of context after
	    set dummy "[incr i]\t[incr j]\t$l"
	}
    }
    while { $i < [llength $lines1] } {
	set l [lindex $lines1 $i]
	incr i
	lappend res "+ $l"
    }
    while { $j < [llength $lines2] } {
	set m [lindex $lines2 $j]
	incr j
	lappend res "- $m"
    }
    if {[llength $res] == 2} {
	return "Files are identical"
    }
    # Need to transform this into something similar to Diff's output
    return [join $res \n]
}



# ×××× Compare drivers ×××× #


::xserv::declare Compare "Overall interface to show differences\
  between files or directories" oldpath newpath

::xserv::register Compare TkDiff \
  -path [file join $HOME Tools "tkdiff.tcl"] \
  -driver {
    global tcl_platform HOME
    if {$tcl_platform(platform) == "windows" } {
	regsub -all "\\\\" $params(oldpath) "/" params(oldpath)
	regsub -all "\\\\" $params(newpath) "/" params(newpath)
    }
    eval script::run tkdiff [list -script \
      [list set env(diffcmd) [file join $HOME Tools "tkdiff.tcl"]] \
      [win::StripCount $params(oldpath)] \
      [win::StripCount $params(newpath)]]
} -requirements {
    if {$::alpha::platform ne "tk"} {
	error "Requires Alphatk"
    }
}

::xserv::register Compare WinDiff \
  -mode Exec \
  -driver {
    global tcl_platform
    if {$tcl_platform(platform) == "windows" } {
	regsub -all "\\\\" $params(oldpath) "/" params(oldpath)
	regsub -all "\\\\" $params(newpath) "/" params(newpath)
    }
    set cmdline [list $params(xserv-WinDiff.exe) \
      [win::StripCount $params(oldpath)] \
      [win::StripCount $params(newpath)] &]
    return $cmdline
} -requirements {
    if {$::tcl_platform(platform) ne "windows"} {
	error "Requires Windows"
    }
} -progs {WinDiff.exe}

::xserv::register Compare "AlphaTcl's internal Diff Mode" -driver {
    # Compare drivers only distinguish between the following two cases:
    if {[file isdirectory $params(oldpath)]} {
	set diffType "directories"
	set diffWinName "* Directory Comparison *"
    } else {
	set diffType "files"
	set diffWinName "* File Comparison *"
    }
    ::compare::execute $params(oldpath) $params(newpath) $diffType $diffWinName
    return
}

