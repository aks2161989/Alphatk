# (After status bar exists)
# 
# Code for rebuilding Tcl indices and Alpha package indices.  Only
# used once the status bar is present.

# Provide Tclx emulation, if needed
if {[info commands scancontext] == ""} {
    namespace eval scancontext {
	namespace export *
    }
    proc scancontext::scancontext {cmd args} {
	switch -- $cmd {
	    "create" {
		uplevel 1 {
		    set __scan 0
		    while {1} {
			incr __scan
			variable scancontext$__scan
			if {![info exists scancontext$__scan]} {
			    break
			}
		    }
		    set scancontext[set __scan] {}
		    return scancontext$__scan
		}
	    }
	    "delete" {
		variable [lindex $args 0]
		unset [lindex $args 0]
	    }
	}
    }

    proc scancontext::scanmatch {scanid args} {
	if {[string match "-*" $scanid]} {
	    lappend regexp $scanid
	    set scanid [lindex $args 0]
	    set args [lrange $args 1 end]
	}
	if {[llength $args] < 1 || [llength $args] > 2} {
	    return -code error "Wrong number arguments"
	}
	variable $scanid
	if {[llength $args] == 2} {
	    lappend regexp -- [lindex $args 0]
	    set script [lindex $args 1]
	} else {
	    # Don't allow more than one default match:
	    if { [set i [lsearch -exact [set $scanid] ""]] >= 0 && ![expr {$i % 2}] } {
		error "scanmatch: default match already specified for this context"
	    }
	    # The default match is just recorded as an empty pattern.
	    # Then [scanfile] takes care of interpreting this as a default pattern:
    	    set regexp {}
	    set script [lindex $args 0]
	}
	lappend $scanid $regexp $script
	return $scanid
    }

    proc scancontext::scanfile {scanid fid} {
	variable $scanid
	upvar 1 matchInfo m
	set m(linenum) 0
	set m(offset) 0
	set m(handle) $fid
	set actionlist [set $scanid]
	while {[set count [gets $fid m(line)]] >= 0} {
	    incr m(linenum)
	    incr m(offset) [expr {$count +1}]
	    set matched 0
	    foreach {reg script} $actionlist {
		if {$reg eq ""} { 
		    set default $script 
		} elseif {[eval [list regexp] $reg [list $m(line) \
		  "" m(submatch0) m(submatch1) m(submatch2)]]} {
		    incr m(offset) [expr {-[string length $m(submatch0)]}]
		    uplevel 1 $script
		    incr m(offset) [string length $m(submatch0)]
		    set matched 1
		}
	    }
	    if {[info exists default]} {
		if {!$matched} {
		    uplevel 1 $default
		}
		unset default
	    }
	}
    }
    namespace import -force scancontext::*
}

proc alpha::rebuildPackageIndices {} {
    # Rebuild the standard filesets, if they exist.  This is useful
    # because we will normally reach here because a package has been
    # installed or uninstalled, or the user has upgraded AlphaTcl.
    alpha::evaluateWhenGuiIsReady {
	foreach fset [list AlphaTclCore Menus Modes Packages] {
	    if {[fileset::exists $fset]} {
		catch {updateAFileset $fset}
	    }
	}
    }
    alpha::makeIndices
}

proc alpha::makeIndices {} {
    global pkg_file HOME PREFS ALPHATK alpha::rebuilding alpha::version \
      index::oldmode alpha::tclversion index::loaded SUPPORT \
      mode::internalNames mode::interfaceNames rebuild_cmd_count
    # Reset the list of scanned files.
    variable scannedFiles
    unset -nocomplain scannedFiles mode::internalNames mode::interfaceNames
    set msg "Building AlphaTcl indices: \[warming up É |  0 %\] É"
    # Add all new directories to the auto_path.
    status::msg "$msg making auto_path É"
    alpha::makeAutoPath
    # Ensure count is correctly set - otherwise we'd probably have to rebuild
    # next time we started up.
    alpha::rectifyPackageCount
    set types [list index::feature index::mode index::uninstall \
      index::requirements index::preinit index::maintainer \
      index::description index::help index::disable index::flags \
      index::prefshelp]
    eval global $types
    # Remember the old feature array, so we can re-instantiate mode-menus
    # which otherwise disappear from the array.
    array set feature_temp [array get index::feature]
    # store old mode information so we can check what changed
    catch {cache::readContents index::mode}
    catch {array set index::oldmode [array get index::mode]}
    
    # Delete all old cache data, from disk and memory
    status::msg "$msg deleting old cache É"
    catch {eval cache::delete $types}
    foreach type $types {
	unset -nocomplain $type
    }
    # Delete record of all caches we have already loaded
    unset -nocomplain index::loaded
    
    status::msg "$msg creating directory listings É"
    foreach dir [list SystemCode Modes Menus Packages "User Packages"] {
	if {$dir eq "User Packages"} {
	    set p [file join $PREFS $dir]
	} else {
	    set p [file join $HOME Tcl $dir]
	}
	lappend dirs $p
	eval lappend dirs [glob -types d -dir $p -nocomplain *]
    }
    if {[info exists ALPHATK] && [file exists $ALPHATK]} {
	lappend dirs $ALPHATK
    }
    foreach domain [list user local] {
	if {($SUPPORT($domain) ne "") \
	  && [file exists [file join $SUPPORT($domain) AlphaTcl Tcl]]} {
	    foreach dir [list SystemCode Modes Menus Packages] {
		set p [file join $SUPPORT($domain) AlphaTcl Tcl $dir]
		lappend dirs $p
		eval lappend dirs [glob -types d -dir $p -nocomplain *]
	    }
	}
    } 
    set alpha::rebuilding 1
    
    # provide the 'Alpha' and 'AlphaTcl' packages
    ;alpha::extension Alpha $alpha::version {} help {file "Alpha Manual"}
    ;alpha::extension AlphaTcl $alpha::tclversion {} help {file "Extending Alpha"}

    # declare 2 different scan contexts:
    set scans [alpha::_setupIndexScans]
    set cid_scan [lindex $scans 0]
    set cid_help [lindex $scans 1]

    set totalFiles 0
    foreach d $dirs {
	incr totalFiles [llength [glob -nocomplain -dir $d "*.tcl"]]
    }
    set seenFiles 0
    set splitHome [file split $HOME]
    set splitIdx2 [llength $splitHome]
    set splitIdx1 [expr {$splitIdx2 - 1}]
    set progress  "            ¥¥¥¥¥¥¥¥¥¥¥¥            "
    foreach d $dirs {
	foreach fn [glob -nocomplain -dir $d *.tcl] {
	    set msg "Building AlphaTcl indices: "
	    incr seenFiles
	    set pcnt [expr {100 * $seenFiles / $totalFiles}]
	    set idx2 [expr {35 - ($seenFiles % 24)}]
	    set idx1 [expr {$idx2 - 12}]
	    set pbar [string range $progress $idx1 $idx2]
	    append msg "\[$pbar|[format %3s $pcnt] %\]"
	    set splitFile [lrange [file split $fn] 0 end-1]
	    if {([lrange $splitFile 0 $splitIdx1] eq $splitHome)} {
		set splitFile [lrange $splitFile $splitIdx2 end]
	    }
	    append msg " É" [eval [list file join] $splitFile] " É"
	    status::msg $msg
	    alpha::_indexScanFile $fn
	}
    }
    set msg "Building AlphaTcl indices: \[finishing É  |100 %\] É"
    unset -nocomplain rebuild_cmd_count
    set alpha::rebuilding 0
    
    scancontext delete $cid_scan
    scancontext delete $cid_help
    status::msg "$msg creating 'help' cache É"
    cache::create index::prefshelp variable index::prefshelp
    
    # We now write out the indexed information to disk.  Since we zeroed
    # the arrays before rebuilding the indices, we can be sure the cache
    # accurately reflects the current state of the various Modes/Menus/etc.
    # directories.
    foreach type $types {
	status::msg "$msg creating '$type' cache É"
	cache::add $type "variable" $type
	if {![regexp {::(feature|flags|requirements|prefshelp)$} $type]} {
	    unset -nocomplain $type 
	}
    }
    
    unset -nocomplain index::oldmode
    unset -nocomplain pkg_file
    
    # Re-initialise those features which were created on the fly.  If
    # we completely deleted some packages which had registered menus
    # with 'addMenu', their information will be recreated here, until
    # the next time you quit Alpha.  We could perhaps check for each of
    # these items whether the index element of the creating package
    # still exists (and if not, then remove the item).  The purpose
    # of this block of code (and the next) is to try to put AlphaTcl
    # into a good state if package indices are rebuilt at any time
    # other than at startup.  However we must make sure we don't
    # compromise the startup state (which is most important).
    status::msg "$msg re-initializing features É"
    global global::tmpfeatures
    if {[info exists global::tmpfeatures]} {
	foreach pkg $global::tmpfeatures {
	    if {![info exists index::feature($pkg)]} {
		if {[info exists feature_temp($pkg)]} {
		    set index::feature($pkg) $feature_temp($pkg)
		}
	    }
	}
    }
    
    # Check package requirements.  This *MUST* be done as late as
    # possible because the side effects of 'requires' statements could
    # be quite significant.
    status::msg "$msg checking package requirements É"
    global alpha::packageRequirementsFailed
    set alpha::packageRequirementsFailed [list]
    foreach pkg [array names index::requirements] {
	set requires [lindex [set index::requirements($pkg)] 1]
	if {[catch {uplevel \#0 $requires} res]} {
	    lappend alpha::packageRequirementsFailed $pkg
	}
    }
    prefs::modified alpha::packageRequirementsFailed
    # Remove any date tag file since we have rebuilt the cache,
    # and recreate it if we're using a prebuilt cache.
    global alpha::cache
    cache::delete "date"
    if {[info exists alpha::cache] \
      && ($alpha::cache eq [file join $HOME Cache])} {
	# Make our date file.
	close [open [file join $alpha::cache date] w]
    }
    # Comment to debug.  This array contains all of the files scanned, and
    # the "original" files that prompted the scanning of each one.
    unset -nocomplain scannedFiles
    status::msg "Building AlphaTcl indices: complete."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alpha::_newScanFile" --
 # 
 # Avoid scanning the same file twice.
 # 
 # --------------------------------------------------------------------------
 ##

proc alpha::_newScanFile {filename {original ""}} {
     variable scannedFiles
     lappend scannedFiles($filename) $original
     return [expr {[llength $scannedFiles($filename)] == 1}]
}

proc alpha::_testScanFile {fn} {
    global alpha::rebuilding pkg_file HOME
    set alpha::rebuilding 1
    
    # declare 2 different scan contexts:
    set scans [alpha::_setupIndexScans]
    set cid_scan [lindex $scans 0]
    set cid_help [lindex $scans 1]
    
    global rebuild_cmd_count
    alpha::_indexScanFile $fn
    unset -nocomplain rebuild_cmd_count
    set alpha::rebuilding 0
    
    scancontext delete $cid_scan
    scancontext delete $cid_help
}

proc alpha::_indexScanFile {fn} {
    uplevel 1 {
	foreach f [::alpha::useFilesFor $fn] {
	    if {[::alpha::_newScanFile $f $fn] && ![catch {alphaOpen $f} fid]} {
		set numprefs 0
		set rebuild_cmd_count 0
		# check for 'newPref' or 'alpha::package' statements
		scanfile $cid_scan $fid
		if {$numprefs > 0} {
		    # status::msg "scanning [file tail $f]É($numprefs prefs)"
		    incr newpref_start -520
		    seek $fid [expr {$newpref_start > 0 ? $newpref_start : 0}]
		    set linenum -2
		    set hhelp ""
		    if {[catch [list scanfile $cid_help $fid] err]} {
			if {$err != "done"} {
			    if {[askyesno "Had a problem extracting\
			      preferences help information\
			      from '[file tail $f]'.  View error?"] eq "yes"} {
				alertnote [string range $err 0 240]
			    }
			}
		    }
		}
		close $fid
		if {$rebuild_cmd_count > 0} {
		    # status::msg "scanning [file tail $f] for packages"
		    set pkg_file $f
		    if {[catch {uplevel \#0 [list source $f]} res] && ($res ne "")} {
			if {[askyesno "Had a problem extracting package\
			  information from [file tail $f]. \
			  View error?"] eq "yes"} {
			    alertnote [string range $res 0 240]
			}
		    }
		}
	    }
	}
    }
}

proc alpha::_setupIndexScans {} {
    set cid_scan [scancontext create]
    scanmatch $cid_scan "^\[ \t\]*alpha::(declare|menu|mode|library|flag|extension|feature|package\[ \t\]+(uninstall|disable|maintainer|help))\[ \t\\\\\]" {
	incr rebuild_cmd_count 1
    }
    scanmatch $cid_scan "^\[ \t\]*newPref\[ \t\]" {
	if {[incr numprefs] == 1} {
	    set newpref_start $matchInfo(offset)
	}
    }
    set cid_help [scancontext create]
    scanmatch $cid_help "^\[ \t\]*#" {
	if {($linenum +1) != $matchInfo(linenum)} { set hhelp "" }
	append hhelp [string trimleft $matchInfo(line) " \t#"] " "
	set linenum $matchInfo(linenum)
    }

    scanmatch $cid_help "^\[ \t\]*newPref\[ \t\]" {
	if {($linenum +1) == $matchInfo(linenum)} {
	    if {$hhelp != ""} {
		set got $matchInfo(line)
		# While the line either ends in a continuation backslash,
		# or has an unmatched brace:
		while {![info complete "${got}\n"]} {
		    append got \n [gets $matchInfo(handle)]
		    if {[eof $matchInfo(handle)]} {break}
		}
		# Tcl really ought to supply us with a built-in 'parseWords'
		if {[catch {parseWords $got} res]} {
		    if {[askyesno "Had a problem extracting preferences\
		      help information from '$got'.  View error?"] eq "yes"} {
			alertnote [string range $res 0 240]
		    }
		    error "problem: $res"
		}
		set pkg [lindex $res 4]
		set var [lindex $res 2]
		# allow comment to over-ride the mode/package
		regexp "^\\((\\w+)\\)\[ \t\]*(.*)\$" $hhelp "" pkg hhelp
		if {$pkg == "" || $pkg == "global"} {
		    set index::prefshelp($var) $hhelp
		} else {
		    set index::prefshelp($pkg,$var) $hhelp
		}
	    }
	}
	set hhelp ""
	if {[incr numprefs -1] == 0} {
	    error "done"
	}
    }
    return [list $cid_scan $cid_help]
}

proc alpha::checkConfiguration {} {
    global alpha::version alpha::tclversion
    
    if {![cache::exists index::feature] || (![cache::exists index::mode]) \
      || ([alpha::package versions Alpha] != $alpha::version) \
      || ([alpha::package versions AlphaTcl] != $alpha::tclversion)} {
	set rebuild 1
	# We no longer zap the cache - it is internal only and so
	# we commit ourselves to ensuring backwards compatibility
	# (or if not then we must change this 0 to a 1).
	if {0} {
	    # If there's no package information stored at all, or if Alpha's
	    # version number has changed, zap the cache.  This may not be
	    # required, but is safer since core-code changes may modify the
	    # form of the cache, or change the format of cached menus etc.
	    global PREFS
	    file delete -force [file join $PREFS Cache]
	    file mkdir [file join $PREFS Cache]
	}
    } else {
	set rebuild [alpha::rectifyPackageCount]
    }
    return $rebuild
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::rectifyPackageCount" --
 # 
 #  Returns 1 if count has changed.  As of 7.5a3 we do also check for a
 #  changed count in 'SystemCode', since users might install stuff there
 #  through cvs or some other remote way of updating AlphaTcl without
 #  actually running an installer.
 # -------------------------------------------------------------------------
 ##
proc alpha::rectifyPackageCount {} {
    # Increment this value any time you want to force anyone upgrading
    # from CVS to rebuild their package indices when they restart (even
    # if no version number has changed).  Any time that the actual
    # version of AlphaTcl changes we can reset this number.
    # 
    # This is used particularly when making potentially incompatible
    # changes to development releases.
    set hardcodedCounter 6
    
    global HOME PREFS
    # check things haven't changed
    foreach d {SystemCode Modes Menus Packages "User Packages"} {
	# add two elements to count, the number of .tcl files
	# in this directory and the number of subdirectories 
	# which are not called 'CVS'
	if {$d == "User Packages"} {
	    set dir [file join $PREFS $d]
	} else {
	    set dir [file join $HOME Tcl $d]
	}
	lappend count [llength [glob -nocomplain -dir $dir *.tcl]]\
	  [expr {[llength [glob -nocomplain -dir $dir -types d *]]\
	  - [llength [glob -nocomplain -dir $dir -types d CVS]]}]
    }
    lappend count $hardcodedCounter
    if {![cache::exists index::count[join $count {}]]} {
	cache::deletePat index::count*
	cache::create index::count[join $count {}]
	return 1
    } else {
	return 0
    }
}

# auto_mkindex:
# Regenerate a tclIndex file from Tcl source files.  Takes two arguments:
# the name of the directory in which the tclIndex file is to be placed,
# and a glob pattern to use in that directory to locate all of the relevant
# files.  For Alpha's core files we cannot use the standard Tcl 8
# 'auto_mkindex' because it sources the files in question, and many of
# Alpha's files have nasty side-effects when sourced (e.g. AlphaBits.tcl!)
#
# We could look into using 'auto_mkindex_old', but this version here provides
# much better error reporting...
proc auto_mkindex {dir args} {
    global tcl_platform HOME alpha::application tclIndexCounts
    # Due to some peculiarities with current working directories
    # under some MacOS/HFS+/other conditions, we avoid using
    # 'cd' and 'pwd' explicitly if possible.
    set dir [file nativename $dir]
    if {![llength $args]} {
        set args [list "*.tcl"]
    }
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    if {($dir eq ":") || ($dir eq ".")} {
		set dir [pwd]
	    }
	}
	default {
	    if {($dir eq ".")} {
		set dir [pwd]
	    }
	}
    }
    # So we can handle relative path names
    if {([file pathtype $dir] eq "relative")} {
	set dir [file join [pwd] $dir]
    }
    if {([file type $dir] eq "link")} {
	set dir [file readlink $dir]
    }
    set dir [string trim $dir :]
    # This line is very important, or Tcl will reject the file...
    append index "# Tcl autoload index file, version 2.0\n"
    
    set cid [scancontext create]
    # This pattern is used to extract procedures when the 'scanfile'
    # command is used below.  We don't do anything too dramatic if
    # the procedure name can't be extracted.  The most likely cause
    # is a garbled file.
    scanmatch $cid "^\[ \t\]*proc\[ \t\]" {
	if {[regexp -- "^\[ \t\]*proc\[ \t\]+((\"\[^\"\]+\")|(\{\[^\}\]+\})|(\[^ \t\]*))" \
	  $matchInfo(line) match procName]} {
	    set procName [lindex [auto_qualify $procName "::"] 0]
	    append index "set [list auto_index($procName)]\
	      \[list source \[file join \$dir [list [file tail $file]]\]\]\n"
	} else {
	    # status::msg "Couldn't extract a proc from '$matchInfo(line)'!"
	}
    }
    # The variable name 'file' must match what is in the scanmatch above!
    watchCursor
    set splitHome [file split $HOME]
    set splitIdx2 [llength $splitHome]
    set splitIdx1 [expr {$splitIdx2 - 1}]
    set progress  "            ¥¥¥¥¥¥¥¥¥¥¥¥            "
    foreach file [eval [list glob -dir $dir --] $args] {
	set msg "Building Tcl indices: "
	if {[info exists tclIndexCounts]} {
	    incr tclIndexCounts(seen)
	    set pcnt [expr {100*$tclIndexCounts(seen)/$tclIndexCounts(total)}]
	    set idx2 [expr {35 - ($tclIndexCounts(seen) % 24)}]
	    set idx1 [expr {$idx2 - 12}]
	    set pbar [string range $progress $idx1 $idx2]
	    append msg "\[$pbar|[format %3s $pcnt] %\]"
	} 
	set splitFile [lrange [file split $file] 0 end-1]
	if {([lrange $splitFile 0 $splitIdx1] eq $splitHome)} {
	    set splitFile [lrange $splitFile $splitIdx2 end]
	}
	append msg " É" [eval [list file join] $splitFile] " É"
	status::msg $msg
	if {[catch {alphaOpen $file r} fid]} {
	    lappend errors $fid
	    lappend errorFiles $file
	} elseif {[catch {scanfile $cid $fid} err]} {
	    lappend errors $err
	    lappend errorFiles $file
	}
	catch {close $fid}
	unset -nocomplain fid err
    }
    
    scancontext delete $cid
    
    if {[info exists errors]} {
	if {[dialog::yesno -y "View the error" -n "Continue" \
	  "The following files: [join $errorFiles ,] were unable\
	  to be opened or scanned for procedures to store in Tcl index\
	  files.  This is a serious error.  $alpha::application will not be\
	  able to find procedures stored in those files, and will\
	  therefore fail to function correctly.  You should\
	  ascertain the cause of these\
	  problems and fix them.  Your disk may be damaged.\r\
	  To avoid some of these problems, the Tcl index file\
	  in $dir will not be replaced."]} {
	    dialog::alert [join $errors "\r"]
	}
    } else {
	if {[catch {alphaOpen [file join $dir tclIndex] w} fid]} {
	    if {[file exists [file join $dir tclIndex]] && \
	      (![file writable $dir] || \
	      ($tcl_platform(platform) eq "macintosh") && ![file::isLocal $dir])} {
		# Bug #405: fix proposed by Lars Hellstrom.
		# We're assuming non-local files which we failed
		# to write to reside in some directory where we
		# haven't got write permission. 
		
		# This is a read-only directory, so there isn't
		# a problem that we couldn't write to it.  Probably
		# it's a system directory such as the base Tcl library.
		# status::msg "'$dir' is read-only, so I'll use the existing Tcl index."
	    } else {
		dialog::alert "The Tcl index file in $dir could not\
		  be rewritten.  Perhaps the file is locked or read-only?\
		  The old index will be left intact, but you should fix\
		  this problem so $alpha::application can index new files in\
		  this directory."
	    }
	} else {
	    if {[catch {puts -nonewline $fid $index} err]} {
		if {[dialog::yesno -y "View the error" -n "Continue" \
		  "The Tcl index file in $dir was successfully opened,\
		  but $alpha::application encountered an error while writing to the\
		  file.  This is a very serious problem, and $alpha::application will\
		  probably no longer function correctly.  At the very\
		  least you will need to reinstall that directory, and\
		  perhaps all of $alpha::application."]} {
		    dialog::alert $err
		}
	    }
	    catch {close $fid}
	    unset -nocomplain err fid
	}
    }
    
}

## 
 # --------------------------------------------------------------------------
 # 
 # "rebuildTclIndices" --
 # 
 # Called during initialization when tests indicate that all tclIndex files 
 # need to be rebuilt.  Can also be called by other AlphaTcl code if the 
 # user finds it necessary.
 # 
 # There are a number of messages here that might be useful to an AlphaTcl
 # developer, but not for most users.  This procedure will return a list of 
 # all possible errors encountered for each directory.
 # 
 # --------------------------------------------------------------------------
 ##

proc rebuildTclIndices {} {
    global auto_path tclIndexCounts
    # Make sure nothing weird has happened.
    alpha::ensureHomeOk
    set errors [list]
    set tclIndexCounts(total) 0
    set tclIndexCounts(seen)  0
    foreach d $auto_path {
	incr tclIndexCounts(total) [llength [glob -nocomplain -dir $d "*.tcl"]]
    }
    foreach dir [lsort -dictionary $auto_path] {
	if {![file isdirectory $dir]} {
	    # Directory doesn't exist
	    lappend errors [list $dir "directory doesn't appear to exist."]
	} elseif {[catch {glob -dir $dir *.*tcl} err]} {
	    # There are no files
	    lappend errors [list $dir "directory contains no Tcl files!"]
	} elseif {![file writable $dir] \
	  || ([file exists [file join $dir tclIndex]] \
	  && ![file writable [file join $dir tclIndex]])} {
	    # Directory isn't writable.
	    lappend errors [list $dir "index directory was not writable"]
	} elseif {[catch {auto_mkindex $dir *.*tcl} errorMsg]} {
	    # We finally tried to rebuild the indices and failed.
	    lappend errors [list $dir $errorMsg]
	}
    }
    # Make Alpha forget its old information so the new stuff will be loaded
    # when required.
    catch {auto_reset}
    status::msg "Building Tcl indices: complete"
    unset tclIndexCounts 
    return $errors
}

###########################################################################
#  Parse a string into "word"s, which include blocks of non-space text,
#  double- and single-quoted strings, and blocks of text enclosed in 
#  balanced parentheses or curly brackets.
#
#  If a word is delimited by a quote or paren character (\", \', \(, or \{),
#  then _that_ particular delimiter may be included within the word if it is 
#  backslash-quoted, as above.  No other characters are special or need quoting
#  with that word.  The quoted delimiters are unquoted in the list of words 
#  returned.  
#
# There is currently a bug in this procedure, when, say, 'entry' looks 
# something like this:      proc Setx::electricRight {{char "\}"}} {}
proc parseWords {entry} {
    # perform a backslash new-line substitutions 
    # (perhaps we should use '-all' ?)
    regsub "((^|\[^\\\\\])(\\\\\\\\)*)\\\\\n\[ \t\]*" $entry {\1 } entry
    
    set slash "\\"
    set qslash "\\\\"
    
    set words {}
    set entry [string trim $entry]
    
    while {[string length $entry]} {
	set delim [string range $entry 0 0]
	set entry [string range $entry 1 end]
	
	#		regexp $endPat   matches the end of the word
	#		       $openPat  matches the open delimiter
	#		       $unescPat matches escaped instances of the open/close delimiters
	#
	#		$type == "quote" means open/close delimiters are the same
	#		      == "paren" means there's a close delimiter and nesting is possible
	#		      == "unquoted" means the word is delimited by whitespace.
	#
	if {$delim == {"}} {			
	    set endPat {^([^"]*)"}
	    set unescPat {\\(")}
	    set type quote
	    
	} elseif {$delim == {'}} {		
	    set endPat {^([^']*)'}
	    set unescPat {\\(')}
	    set type quote
	    
	} elseif {$delim == "\{"} {		
	    set endPat "^(\[^\}\]*)\}"
	    set openPat "\{"
	    set unescPat "\\\\(\[\{\}\])"
	    set type paren
	    
	} elseif {$delim == "("} {		
	    set endPat {^([^)]*)\)}
	    set openPat {(}
	    set unescPat {\\([()])}
	    set type paren
	    
	} elseif {$delim == "\["} {		
	    set endPat {^([^]]*)\]}
	    set openPat {[}
	    set unescPat {\\([][])}
	    set type paren
	    
	} else {						
	    set type unquoted
	}
	
	if {$type == "quote"} {
	    set ck $qslash
	    set fld ""
	    while {$ck eq $qslash} {
		set ok [regexp -indices -- $endPat $entry mtch sub1]
		if {$ok} {
		    append fld [string range $entry [lindex $mtch 0] [lindex $mtch 1]]
		    set ck $slash[string range $entry [lindex $sub1 1] [lindex $sub1 1]]
		    set pos [expr {1 + [lindex $mtch 1]}]
		    set entry [string range $entry $pos end]
		} else {
		    error "Couldn't match $delim as field delimiter"
		}
	    }
	    set pos [expr {[string length $fld] - 2}]
	    set fld [string range $fld 0 $pos]
	    regsub -all -- $unescPat $fld {\1} fld
	    
	} elseif {$type == "paren"} {
	    
	    set nopen 1
	    set nclose 0
	    set fld ""
	    while {$nopen - $nclose != 0} {
		set ok [regexp -indices -- $endPat $entry mtch sub1]
		if {$ok} {
		    append fld [string range $entry [lindex $mtch 0] [lindex $mtch 1]]
		    set ck $slash[string range $entry [lindex $sub1 1] [lindex $sub1 1]]
		    set entry [string range $entry [expr {1 + [lindex $mtch 1]}] end]
		    regsub -all -- $unescPat $fld {} fld1
		    set nopen [llength [split $fld1 $openPat]]
		    if {($ck ne $qslash)} { incr nclose }
		} else {
		    error "Couldn't match $delim as field delimiter"
		} 
	    }
	    set pos [expr {[string length $fld] - 2}]
	    set fld [string range $fld 0 $pos]
	    regsub -all -- $unescPat $fld {\1} fld
	    
	} elseif {$type == "unquoted"} {
	    
	    set entry ${delim}${entry}
	    set ok [regexp -indices {^([^ 	]*)} $entry mtch sub1]
	    if {$ok} {
		set fld [string range $entry [lindex $sub1 0] [lindex $sub1 1]]
		set pos [expr {1 + [lindex $mtch 1]}]
		set entry [string range $entry $pos end]
	    } else {
		set fld ""
		set entry ""
	    }
	} else {
	    error "parseWords: unrecognized case"
	}
	
	lappend words $fld
	set entry [string trimleft $entry]
    }
    return $words
}

