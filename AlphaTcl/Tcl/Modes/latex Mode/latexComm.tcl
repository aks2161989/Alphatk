## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "latexComm.tcl"
 #                                          created: 11/10/1992 {10:42:08 AM}
 #                                      last update: 03/13/2006 {02:41:22 PM}
 # Description:
 #
 # Support for typesetting, executing other TeX commands, other items in the
 # "Process" submenu.
 #
 # Any procedure that is NOT in the TeX namespace should be able to be safely
 # called from any code outside of LaTeX mode, along with "TeX::typesetFile".
 # 
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the main TeX mode file has been loaded.
latex.tcl

proc latexComm.tcl {} {}

namespace eval TeX {}

# ×××× TeX etc. Application Interface ×××× #

####
# Xserv versions for TeX mode procs
####

proc pdflatexTEXFile {filename} {
    xserv::invoke pdftex -file $filename -format pdflatex
}

proc bibtexAUXFile {filename} {
    xserv::invoke bibtex -file $filename
}

proc makeindexIDXFile {filename} {
    xserv::invoke makeindex -file $filename
}

proc makeindexGLOFile {filename} {
    ::xserv::invoke makeglossary -file $filename
}

proc viewDVIFile {filename} {
    ::xserv::invoke viewDVI -file $filename
}

proc viewPDFFile {filename} {
    ::xserv::invoke viewPDF -file $filename
}

proc printDVIFile {filename} {
    ::xserv::invoke printDVI -file $filename
}

proc dvipsDVIFile {filename} {
    ::xserv::invoke dvips -file $filename
}

proc dvipdfDVIFile {filename} {
    ::xserv::invoke dvipdf -file $filename
}

proc viewPSFile {filename} {
    if {[catch {::xserv::invoke viewPS -file $filename}]} {
	status::msg "View aborted."
    }
}

proc printPSFile {filename} {
    ::xserv::invoke printPS -file $filename
}

proc distillPSFile {filename} {
    ::xserv::invoke distillPS -file $filename
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Typesetting ×××× #
# 
# There are no longer tex, pdftex and so on TeX commands.  You just typeset a
# file, what amounts to asking the current TeX program to compile the file
# using the current TeX format which is either set when the file is brought
# to the front or manually selected.
# 
# This proc is called by the 'helperApps' implementation of 'typeset':
proc TeX::typesetFile {filename {bg 0}} {
    global TeXmodeVars TeX::TypesetFile
    global showTeXLog
    
    if {$filename == ""} {
	set filename [getfile "Choose a file to typeset:"]
    }
    TeX::typesetFirstMessage
    # Just so other code knows what we're dealing with.
    set TeX::TypesetFile $filename
    
    set interact [expr {!$bg}]
    set xservname "[string tolower $TeXmodeVars(nameOfTeXProgram)]"
    if {!$bg && $showTeXLog == 2} {
	::xserv::addEndExecHook $xservname TeX::showLogHook
    } else {
	::xserv::removeEndExecHook $xservname TeX::showLogHook
    }
    
    set format [TeX::effectiveFormat]
    if {[string equal -nocase -length 3 "pdf" $format]} {
	# Ensure pdf file is closed
	xserv::invoke closePDF -file "[file root $filename].pdf"
    }
    
    set status [::xserv::invoke $xservname -xservInteraction $interact\
      -options "$TeXmodeVars(additionalTeXFlags)" \
      -format $format \
      -file $filename]
    status::msg "$status"
}

# Apply $op to a file with extension $ext.  (See latexMenu.tcl for many
# examples.)  If 'forcecurrent == 1', use the current window even if it
# belongs to a TeX fileset.
#
proc TeX::doTypesetCommand {op {ext ""} {forcecurrent 0}} {
    
    if {[set filename [TeX::findAuxiliaryFile $ext $forcecurrent]] != ""} {
	if {$op == "open"} {
	    edit -c -r -w $filename 
	} else {
	    if {$ext == ""} {set ext "TEX"}
	    $op${ext}File $filename
	}
    } else {
	alertnote "No $ext file found!"
    }
}

proc TeX::syncronizeDoc {} {
    
    # Textures has its own handling of this.  The 'if' needs
    # updating for xserv.
    if {0} {
	TeX::Textures::synchronizeDoc
	return
    }
    
    # Find out which base file and choose between dvi and pdf
    if {![win::IsFile [set currentWin [win::Current]]]} {
	status::msg "No valid open window"
	return
    }
    set lineNum [lindex [pos::toRowCol [getPos]] 0]
    set currentWin [win::StripCount $currentWin]
    set fset [isWindowInFileset $currentWin "tex"]
    if {$fset != ""} {
	set baseFile [texFilesetBaseName $fset]
    } else {
	set baseFile $currentWin
    }
    set baseFile [file rootname [file normalize $baseFile]]
    set ext [::TeX::tetexComm::newestOutput $baseFile]
    append baseFile .$ext
    
    switch -exact -- $ext {
	pdf {
	    # Check if there is a pdfsync file -- otherwise it makes no sense 
	    # to try to synchronise.  This check is for all viewers.
	    if { ![file exists ${baseFile}sync] } {
		status::msg "File ${baseFile}sync not found"
		viewPDFFile $baseFile
		return
	    }
	    # Now treat the two known pdf-synchers separately:
	    xserv::invoke viewPDF -file $baseFile \
	      -line $lineNum -source $currentWin
	    return
	}
	dvi - ps {
	    # (We come into this case also if for some reason there is a ps
	    # file newer than the dvi file...)
	    
	    xserv::invoke viewDVI -file $baseFile \
	      -line $lineNum -source $currentWin
	    return
	}
	# end of the dvi case
    }
    # end of dvi-pdf switch
    alertnote "Sorry, jumping to the current source line in your viewer\
      isn't implemented for your viewer and/or platform.\
      Please do ask for further information on the alphatcl-users mailing\
      list."
}

# ×××× --------- ×××× #

#--------------------------------------------------------------------------
# ×××× Typeset submenu commands ×××× #
#--------------------------------------------------------------------------

# This is the command called whenever the user selects Typeset in the TeX
# menu or presses Cmd-T. It's task is first to figure out which file to
# typeset and then call [xserv::invoke typeset -file $fileName].
# 
# (Unfortunately, the old scheme of determining which file to tex based on
# [win::TopNonProcessWindow] is unacceptable to tetexComm, so currently
# there is an [if] statement to bypass this.)

proc TeX::typeset {{bg 0}} {
    if { [::xserv::getCurrentImplementationNameFor typeset ""] eq "tetexComm" } {
	xserv::invoke typeset -file [TeX::tetexComm::whichFileToTypeset]
    } else {
	set fg [expr {1-$bg}]
	xserv::invoke typeset -file [TeX::whichFileToTypeset] -xservInteraction $fg
    }
}

# This proc contains all the yoga previously found at top-level in 
# [TeX::typeset].  The [getFile] statements come from [TeX::typesetFile],
# where previously they were the result of calling this proc with "" argument.
# 
# To the best of my conviction, this refactorisation does not change the
# behaviour of [TeX::typeset].
proc TeX::whichFileToTypeset {} {
    global TeXmodeVars
    # Is there a window open?
    if {[set currentWin [win::TopNonProcessWindow]] == ""} {
	# This functionality was previously preformed in [TeX::typesetFile]
	return [getfile "Choose a file to typeset:"]
    }
    # Strip off trailing garbage (if any):
    set currentWin [win::StripCount $currentWin]
    # Is the current window part of TeX fileset?
    set fset [isWindowInFileset $currentWin "tex"]
    if {$fset != ""} {
	if {[dirtyFileset $fset]} {
	    switch -- [askyesno "Save current TeX fileset?"] {
		"yes" {
		    if {[catch {saveEntireFileset $fset}]} {
			error "cancel"
		    }
		}
		"no" {
		    error "cancel"
		}
	    }
	}
	return [texFilesetBaseName $fset]
    }
    # Is the window untitled or dirty?
    set currentDoc [file tail $currentWin]
    if {[TeX::winUntitled]} {
	switch -- [askyesno -c "Save \"$currentDoc\"?"] {
	    "yes" {
		if {[catch {menu::fileProc "File" "save"}]} {
		    error "cancel"
		} else {
		    set currentWin [win::Current]
		}
	    }
	    "no" {
		set newDoc [temp::unique TeX untitled ".tex"]
		set text [getText [minPos] [maxPos]]
		file::writeAll $newDoc $text 1
		set currentWin $newDoc
	    }
	    "cancel" {
		error "cancel"
	    }
	}
    } elseif {[winDirty]} {
	switch -- [askyesno -c "Save \"$currentDoc\"?"] {
	    "yes" {
		if {[catch {menu::fileProc "File" "save"}]} {
		    error "cancel"
		} else {
		    set currentWin [win::Current]
		}
	    }
	    "no"  {
		set text [getText [minPos] [maxPos]]
		set currentDoc [file root $currentDoc]
		set newDoc [temp::unique TeX temp-$currentDoc ".tex"]
		file::writeAll $newDoc $text 1
		set currentWin $newDoc
	    }
	    "cancel" {return}
	}
    }
    # Is the current window TeX-able?
    set ext [file extension $currentWin]
    if {[lsearch -exact $TeXmodeVars(texableFileExtensions) $ext] < 0} {
	# These files are run by tex/latex
	return [getfile "Choose a file to typeset:"]
    } else {
	# For all others we let the extension determine things
	return $currentWin
    }
}

proc TeX::typesetSelection {} {
    requireSelection
    watchCursor
    status::msg "Processing selectionÉ"
    # Is the current window part of TeX fileset?
    set currentWin [win::Current]
    if {[set fset [isWindowInFileset $currentWin "tex"]] == ""} {
	if {![TeX::isInDocument]} {
	    set msg "Selection not in document environment.  Continue?"
	    if {([askyesno $msg] eq "no")} {
		error "cancel"
	    }
	}
	set searchText [getText [minPos] [maxPos]]
    } else {
	# Will not handle a base file that is open and dirty:
	set searchText [TeX::buildFilecontents [texFilesetBaseName $fset]]
    }
    set thisFileOffSet [lindex [pos::toRowChar [getPos]] 0]
    set latexBody "\r[getSelect]\r"
    status::msg "Building temporary documentÉ"
    set pattern {(\\documentclass.*)\\begin\{document\}}
    if {![regexp -- $pattern $searchText dummy preamble]} {
	set preamble "\\documentclass\{article\}\r"
    } else {
	# Special quirk in case '\begin{document} appears elsewhere in the
	# file !!
	regsub {\\begin\{document\}.*} $preamble "" preamble
    }
    set rootFile [file rootname $currentWin]
    set tempFile "temp-[file tail $rootFile]"
    set newFile  [temp::nonunique TeX $tempFile ".tex"]
    set auxFile  ${rootFile}.aux
    if {[file exists $auxFile]} {
	set latexDoc [TeX::buildFilecontents $auxFile $tempFile.aux]
    } else {
	set latexDoc {}
    }
    append latexDoc $preamble [TeX::buildEnvironment "document" "" $latexBody "\r"]
    set currentDir [file dirname $currentWin]
    set latexDoc   [TeX::resolveAll $latexDoc $currentDir]
    file::writeAll $newFile $latexDoc 1
    set lineOffset [expr \
      {[llength [split $latexDoc "\r"]] - [llength [split $latexBody "\r"]] - 2}]
    ##### The offset to put into the table is: 
        #   number of lines preceeding the excerpt
        #   minus number of lines preceeding the excerpt in the temporary file
    set offSetDifference [expr {$thisFileOffSet - $lineOffset - 2}]
    
    temp::attributesForFile $newFile $currentWin $offSetDifference

    xserv::invoke typeset -file $newFile
}

proc TeX::typesetClipboard {} {
    set body "\r[getScrap]\r"
    set pat1 {\\begin\{document\}.*\\end\{document\}}
    set pat2 {\\documentclass}
    set preamble "\\documentclass\{article\}\r"
    # Check to see if there's a document environment:
    if {![regexp -- $pat1 $body]} {
	append text $preamble [TeX::buildEnvironment "document" "" $body "\r"]
    } else {
	# Check to see if there's a \documentclass command:
	if {![regexp -- $pat2 $body]} {
	    append text $preamble $body
	} else {
	    set text $body
	}
    }
    set newFile [temp::nonunique TeX temp-noname ".tex"]
    file::writeAll $newFile $text 1
    xserv::invoke typeset -file $newFile
}


# Should reform this to use new dialogs code.
proc TeX::typesetFirstMessage {} {
    
    global TeXmodeVars
    
    if {!$TeXmodeVars(showFirstTimeTypesettingMessage)} {return}
    
    set msg {
	This is the first time you've tried to typeset something.

	The TeX mode you are using can interact with many different formats
	(TeX, LaTeX, pdfTeX, pdfLaTeX, eTeX, etc.)  and many different
	implementations (teTeX, OzTeX, Textures, TeXShop, etc).

	You can use the 'TeX Format' and 'TeX Program' submenus of the
	'Process' menu to make your selection between the kind of
	typesetting, and the "Config --> Global Setup --> Helper Applications"
	dialog to choice the application to use for these actions (you may
	need to set any or all of your 'tex sig', 'pdftex sig' and 'pdflatex
	sig' preferences).
	
	Some helper applications can only perform basic TeXing, while others
	may allow the full range of options, and others may be more
	intelligent about determining the appropriate format automatically.
	
	You are about to run a 'NAMEOFTEXPROGRAM' operation, and will most
	likely be prompted for the application to use for that operation.  If
	this is not what you want, please cancel now.
	
	If you press the 'OK' button, you will not see this message again.
    }
    regsub "NAMEOFTEXPROGRAM" $msg $TeXmodeVars(nameOfTeXProgram) msg
    set pat "(\[-a-zA-Z0-9\\\),.'\"\])(\r?\n)\[\t \]+(\[-a-zA-Z0-9\\\('\"\])"
    regsub -all $pat $msg "\\1 \\3" msg
    if {![dialog::yesno -y "OK" -n "Cancel" [string trim $msg]]} {
	error "cancel"
    }
    set TeXmodeVars(showFirstTimeTypesettingMessage) 0
    prefs::modified TeXmodeVars(showFirstTimeTypesettingMessage)
}

# ×××× --------- ×××× #

#--------------------------------------------------------------------------
# ×××× Utility procs: ×××× #
#--------------------------------------------------------------------------

proc TeX::openFile {file {ext ""}} {

    if {[catch {TeX::findTeXFile $file $ext} f]} {
	beep
	error "Cancelled: can't find TeX input file \"$file\""
    } else {
	file::openQuietly $f
	status::msg $f
    }
}

# Note that we'd like to give more options here in the buttonAlert dialog,
# but Alpha8 really messes things up with more than 3 of them.

proc TeX::removeAuxiliaryFiles {} {
    
    global TeXmodeVars
    
    if {[set currentWin [win::Current]] == ""} {return}
    set baseFile [TeX::currentBaseFile [win::Current]]
    set baseRoot [file root $baseFile]
    set baseDir  [file dirname $baseFile]
    set exts     $TeXmodeVars(auxFileExtensions)
    set question "Would you like to remove all [file tail $baseRoot]\
      files with the following extensions:\r\r${exts}\r\r\
      or be asked about each one?"
    set b0 "Remove File"
    set b1 "Remove All"
    set b2 "Keep File"
    set b3 "Ask Each Time"
    set b4 "Edit extensions"
    set b5 "Cancel"
    switch -- [buttonAlert $question $b1 $b3 $b5] {
	"Remove All"      {set removeAll 1}
	"Ask Each Time"   {set removeAll 0}
	"Cancel"          {error "cancel"}
	"Edit extensions" {
	    if {[catch {getline "Edit the list of extensions" $exts} exts]} {
		error "cancel"
	    } elseif {![string length $exts]} {
		error "cancel"
	    } else {
		set TeXmodeVars(auxFileExtensions) $exts
		TeX::removeAuxiliaryFiles ; return
	    }
	}
    }
    foreach ext $exts {
	if {[file exists ${baseRoot}${ext}]} {
	    lappend removeList1 ${baseRoot}${ext}
	    lappend removeList2 ${baseRoot}${ext}
	} 
    }
    if {![info exists removeList1]} {
	status::msg "No files were found to remove."
	return
    } elseif {$removeAll} {
	foreach fileName $removeList1 {file delete $fileName}
	if {[llength $removeList1] > 1} {
	    status::msg "[llength $removeList1] files were deleted."
	} else {
	    status::msg "1 file was deleted."
	}
	return
    } else {
	if {[llength $removeList1] > 1} {
	    status::msg "[llength $removeList1] files were found."
	} else {
	    status::msg "1 file was found."
	}
	foreach fileName $removeList1 {
	    set question "Remove '[file tail $fileName]' ?"
	    switch -- [buttonAlert $question $b0 $b2 $b5] {
		"Cancel" {
		    error "cancel"
		}
		"Remove File" {
		    file delete $fileName
		}
		"Remove All" {
		    foreach fileName $removeList2 {file delete $fileName}
		    status::msg "All remaining files ([llength $removeList2])\
		      were deleted."
		    return
		}
	    }
	    set left [llength [set removeList2 [lremove $removeList2 [list $fileName]]]]
	    if {$left > 1} {
		status::msg "[llength $removeList2] files remaining."
	    } elseif {$left == 1} {
		status::msg "One file remaining."
	    } else {
		status::msg "There are no more auxiliary files in the list."
		return
	    }
	}
    }
}

# Find a LaTeX auxiliary file with extension $ext.  If 'forcecurrent' is
# true, search the current directory without checking for TeX filesets.

proc TeX::findAuxiliaryFile {ext {forcecurrent 0}} {
    
    set currentWin [win::TopNonProcessWindow]
    if {$currentWin == ""} {return ""}
    set currentDoc [file tail $currentWin]
    
    if {$ext == ""} {
	set ext [string toupper [string range [file ext $currentDoc] 1 end]]
    }
    
    if {$forcecurrent} {
	# pretend there are no TeX filesets:
	set fset ""
    } else {
	set fset [isWindowInFileset $currentWin "tex"]
    }
    
    if {$fset != ""} {
	set currentWin  [texFilesetBaseName $fset]
	set currentDoc  [file tail $currentWin]
	set currentDir  [file dirname $currentWin]
	set docBasename [file rootname $currentDoc]
	set lowerExt    [string tolower $ext]
    } else {
	# we do all this if it's not a project:
	set currentDir  [file dirname $currentWin]		
	set docBasename [file rootname $currentDoc]
	set lowerExt    [string tolower $ext]
	
	# Is the window untitled or dirty?
	if {[set num [TeX::winUntitled]]} {
	    set tempDir  [temp::directory TeX]
	    set filename [file join $tempDir Untitled${num}.${lowerExt}]
	    if {[file exists $filename]} {
		return $filename
	    } else {
		return ""
	    }
	} elseif {[winDirty]} {
	    switch [askyesno "Window dirty---continue anyway?"] {
		"yes" {
		    set tempDir  [temp::directory TeX]
		    set filename [file join temp-${currentDoc}.${lowerExt}]
		    if {[file exists $filename]} {return $filename}
		}
		"no" {return -code return ""}
	    }
	}
    }
    
    # Check the current directory:
    set filename [file join $currentDir ${docBasename}.${lowerExt}]
    if {[file exists $filename]} {
	return $filename
    } else {
	return ""
    }
}

# TeX services using teTeX
proc TeX::buildTeTeXcmd {progname} {
  upvar params params
  set params(shellmode) TeX
  set cmd {}
  # We must change directory here, since Xserv won't do it for us,
  # and we won't find included files otherwise.  We need a better
  # mechanism for this, or we should have Xserv simply always
  # remember the pwd and restore it after invocation of any service.
  cd [file dirname $params(file)]
  lappend cmd $params(xserv-$progname)
  if {[regexp "etex" $progname] || [regexp "etex" $params(xserv-$progname)]} {
    lappend cmd -efmt=$params(format)
  } else {
    lappend cmd -fmt=$params(format)
  }
  lappend cmd $params(options) [file tail $params(file)]
  return $cmd
}

# With a shell in between so that we can first "cd" to the right directory.
# Works even with files in a directory with a full name which contains 
# spaces, however, the tail file name may not contain spaces.
# May not work on Windows since "sh" may not exist.
proc TeX::changeToFileDir {} {
  upvar params params
  return [list cd [file dirname $params(file)] \;]
}

proc TeX::buildTeTeXshcmd {progname} {
  upvar params params
  set params(shellmode) TeX
  set cmd [TeX::changeToFileDir]
  lappend cmd $params(xserv-$progname)
  if {[regexp "etex" $progname] || [regexp "etex" $params(xserv-$progname)]} {
    lappend cmd -efmt=$params(format)
  } else {
    lappend cmd -fmt=$params(format)
  }
  lappend cmd $params(options) [file tail $params(file)]
  lappend cmd "2>&1"
  return $cmd
}

proc TeX::showLogHook {implArray argsArray result} {
    array set impl $implArray
    array set args $argsArray
    if {!$args(xservInteraction) || ($impl(mode) == "App")} {
	return
    }
    set filename $args(file)
    set wins [winNames -f]
    set logname "[file rootname $filename].log"
    set idx [lsearch -exact $wins $logname]
    if {$idx == -1} {
	edit -c -r -w "[file rootname $filename].log"
    } else {
	bringToFront "$logname"
	revert
    }
}

# Fix some TeX mode procs
# Send a command line to CMacTeX >= 4.0
proc TeX::buildNewCMacTeXAE {target command filename} {
    return [tclAE::send -p $target CMTX exec \
      ---- [tclAE::build::TEXT "$command [file tail $filename]"] \
      dest [tclAE::build::alis "[file dirname $filename][file separator]"] \
      ]
}

# Return the effective format to use.
# This is extracted from TeX::buildCMacTeXcommand because it is useful
# by itself and used by xserv (it has nothing to do with CMacTeX and
# works perfectly with teTeX too).
proc TeX::effectiveFormat {} {
    global TeXmodeVars TeX::TypesetFile
    
    set TeXprogram    [string tolower $TeXmodeVars(nameOfTeXProgram)]
    set TeXformat     $TeXmodeVars(nameOfTeXFormat)
    set formatOptions $TeXmodeVars(availableTeXFormats)
    
    set format ""
    if {![string length $TeXformat]} {
	# Format names are generally auto-adjusted when the window is
	# activated, but maybe we're being called without the window
	# being open.
	set formatName [lindex [TeX::getFormatName [set TeX::TypesetFile]] 0]
	# Make sure that it's a valid option.
	if {[lsearch $formatOptions $formatName] != "-1"} {
	    set TeXformat $TeXmodeVars(nameOfTeXFormat)
	} 
	if {![string length $TeXformat]} {
	    # We still don't have one.
	    regsub -all {\(-\)*} $formatOptions "-" formatOptions
	    set pArgs [list  "Please choose a format" "LaTeX" "options:"]
	    if {[catch {eval prompt $pArgs $formatOptions} formatName]} {
		error "cancel"
	    } 
	    set TeXformat $TeXmodeVars(nameOfTeXFormat)
	} 
	set TeXmodeVars(nameOfTeXFormat) $formatName
    } 
    regsub -nocase -- {(la)?(tex)} ${TeXformat} "\\1\\2" TeXformat
    return $TeXformat
}

# Updated to use TeX::effectiveFormat.
# Has exactly the same behavior as the original version. The only
# change is that the code that determines the name of the format
# to use has been put in a separate proc (TeX::effectiveFormat).
proc TeX::buildCMacTeXcommand {} {
    set cmdline [string tolower $TeXmodeVars(nameOfTeXProgram)]
    set format "[TeX::effectiveFormat]"
    if {$format != ""} {
	append cmdline " &$format"
    }
    return $cmdline
}

# ==========================================================================
# 
# .
