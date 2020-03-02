## -*-Tcl-*- (install) (nowrap)
## 
 # This file : postscriptMode.tcl
 # Created : 2001-03-24 00:52:44
 # Last modification : 2003-04-08 14:25:43
 # Author : Bernard Desgraupes
 # e-mail : <bdesgraupes@easyconnect.fr>
 # Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
 # Description :
 #      Postscript mode is useful for editing,  processing,  viewing  the
 #      internal commands of both PostScript (.ps) and Portable  Document
 #      Format (.pdf) files. You can convert  ps  files  to  pdf  format,
 #      manipulate and modifiy ps files with the PsUtils  tools,  convert
 #      Type 1 fonts  with  the  T1Utils  tools  with  all  their options
 #      directly from Alpha. You can also easily edit and execute command
 #      lines for ghostscript.
 #      For all these  features  to  work,  you  should  have  a  working
 #      installation of the CMacTeX distribution (version 3.5 or  greater
 #      preferably) 
 #      Please read the doc in the Postscript Help file (it is located in
 #      the Help menu once the package is installed) and  the  Postscript
 #      mode tutorial.
 # 
 # (c) Copyright : Bernard Desgraupes, 2001-2002, 2003
 #         All rights reserved.
 # This software is free software. See licensing terms in the
 # Postscript Help file.
 ##


alpha::mode [list PS PostScript] 0.6.3 psMenu {*.ps *.eps *.epsf *.afm *.pfa *.pfb *.pdf} {
    psMenu
} {
    # Script to execute at Alpha startup
    addMenu psMenu "PS" PS
} maintainer {
    "Bernard Desgraupes" <bdesgraupes@easyconnect.fr>  <http://webperso.easyconnect.fr/bdesgraupes/alpha.html> 
} uninstall {
    this-file
} description {
    Supports the viewing and processing of PostScript files
} help {
    file "Postscript Help"
}

proc postscriptMode.tcl {} {}

# Only register these if we've actually loaded the mode or menu at least once.
set dimmitemslist [list  "processTheBuffer" "processTheSelection" "sendToViewer"\
  "sendToPrinter" "convertToPdf" "sendToGhostscript" ]
foreach item $dimmitemslist {
    hook::register requireOpenWindowsHook [list PS $item] 1 
}
unset dimmitemslist item


namespace eval PS {}

# Preferences
# ===========

prefs::removeObsolete PSmodeVars(electricTab)

newPref var lineWrap {0} PS
# Set this flag if you want your source file to be marked automatically when it is opened.
newPref f autoMark {1} PS
newPref v prefixString {% } PS
# PostScript mode's notion of what is a word.
newPref v wordBreak {[-_\w]+} PS
# Used in the PS::parseFuncs for the {} popup menu.
newPref v funcExpr {/[-_\w\d]+[ \t]*(\{[^\}]+\}|[^/]+)[ \t]*def\b} PS
# This is used by the -sPAPERSIZE option with Ghostscript and by the PsToPdf command
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 PS
newPref v defaultPaperSize {a4} PS
# Set this flag to build a list of scripts.
# You will have to set the path to the top folder with the ScriptsFolder
# preference.
newPref f buildScriptsList 0 PS PS::shadowList
# Set here the location of a folder containing your ps scripts.
newPref folder ScriptsFolder {} PS PS::shadowList
# Default colo(u)rs for the comments
newPref color commentColor      red PS          stringColorProc
# Default colo(u)rs for the PS keywords
newPref color psKeywordColor    blue PS         PS::colorizePS
# Default colo(u)rs for the PDF keywords
newPref color pdfKeywordColor   magenta PS      PS::colorizePS
# Signature of Pdf Reader
newPref sig PdfReaderSig        {CARO} PS       PS::updateArray
# Signature of afm2tfm
newPref sig Afm2tfmSig          {CMTa} PS       PS::updateArray
# Signature of epstopdf
newPref sig EpstopdfSig         {CMte} PS       PS::updateArray
# Signature of ghostview
newPref sig GhostviewSig        {CMTJ} PS       PS::updateArray
# Signature of gs
newPref sig GsSig               {CMTA} PS       PS::updateArray
# Signature of lwfn2pfa
newPref sig Lwfn2pfaSig         {CMTD} PS       PS::updateArray
# Signature of pfa2lwfn
newPref sig Pfa2lwfnSig         {CMTD} PS       PS::updateArray
# Signature of pfa2pfb
newPref sig Pfa2pfbSig          {CMTD} PS       PS::updateArray
# Signature of pfb2pfa
newPref sig Pfb2pfaSig          {CMTD} PS       PS::updateArray
# Signature of printps
newPref sig PrintpsSig          {PSP*} PS       PS::updateArray
# Signature of psbook
newPref sig PsbookSig           {CMTo} PS       PS::updateArray
# Signature of psnup
newPref sig PsnupSig            {CMTo} PS       PS::updateArray
# Signature of psselect
newPref sig PsselectSig         {CMTo} PS       PS::updateArray
# Signature of pstops
newPref sig PstopsSig           {CMTo} PS       PS::updateArray
# Signature of t1asm
newPref sig T1asmSig            {CMTD} PS       PS::updateArray
# Signature of t1disasm
newPref sig T1disasmSig         {CMTD} PS       PS::updateArray

# Initialization of variables
# ===========================
set PS_params(utilprgs) [list  " epstopdf" " afm2tfm" -	"¥ psutils ¥" -\
  " psbook" " psnup" " psselect" " pstops" - "¥ t1utils ¥" -\
  " lwfn2pfa" " pfa2lwfn" " pfa2pfb" " pfb2pfa" " t1asm" " t1disasm" ]
set PS_params(paperlist) [list 11x17 a0 a1 a10 a2 a3 a4 a4small a5 a6 a7 a8 a9 archA archB archC archD archE \
  b0 b1 b2 b3 b4 b5 c0 c1 c2 c3 c4 c5 c6 flsa flse halfletter ledger legal letter lettersmall ]
set PS_params(gsoptions) [list " -dBATCH" " -dCOLORSCREEN" " -dDELAYBIND" " -dDISKFONTS" " -dDITHERPPI" \
  " -dFIXEDMEDIA" " -dFIXEDRESOLUTION" " -dLOCALFONTS" " -dNOBIND" " -dNOCACHE" " -dNOCIE" " -dNODISPLAY" \
  " -dNOFONTMAP" " -dNOFONTPATH" " -dNOGC" " -dNOINTERPOLATE" " -dNOPAGEPROMPT" " -dNOPAUSE" " -dNOPLATFONTS" \
  " -dNOPROMPT" " -dORIENT1" " -dQUIET" " -dSAFER" " -dSHORTERRORS" " -dSTRICT" " -dWRITESYSTEMDICT" " -sDEVICE" \
  " -sFONTMAP" " -sFONTPATH" " -sOutputFile" " -sPAPERSIZE" " -sSUBSTFONT" "(-" " -dFirstPage" " -dLastPage" \
  " -dPSBinary" " -dPSLevel1" " -dPSNoProcSet" " -sPSFile" ]


proc PS::updateArray {{prefs ""}} {
    global PS_params PSmodeVars
    if {$prefs == ""} {set prefs [array names PSmodeVars]}
    foreach pref $prefs {
	if {[regsub {Sig$} $pref {} item]} {
	    set item [string tolower $item]
	    set PS_params($item) $PSmodeVars($pref)
	} 
    }
}

PS::updateArray
set PS_params(currentdir) ""
set PS_params(scriptnames) ""
set PS_params(PSsubmenuitems) ""
set PS_params(filename) ""
set PS_params(basename) ""
set PS_params(cmdline) ""
set PS_params(dialogtitle) ""
set PS_params(dialogy) 0
set PS_params(gscmdwindow) "Build Ghostscript Command"

set PS::commentCharacters(General) "%"
set PS::commentCharacters(Paragraph) [list "%% " " %%" " % "]
set PS::commentCharacters(Box) [list "%" 1 "%" 1 "%" 3]


# Dummy proc
proc psMenu {} {}


# PostScript Menus declarations
# =============================

menu::buildProc psMenu menu::buildPsMenu
menu::buildProc postscriptUtilities menu::buildPsUtilities
menu::buildProc psScripts menu::buildPsScripts


# Menu building procs
# -------------------

proc menu::buildPsMenu {} {
    global psMenu
    set ma {
	"/P<O<IprocessTheBuffer"
	"processTheSelection"
	"processAFile..."
	"(-"
	"sendToViewer"
	"sendToPrinter"
	"(-"
	"convertToPdf"
	"(-"
	"/G<I<BbuildGsCommand"
	"sendToGhostscript"
	"(-"
    }
    lappend ma [list Menu -n "postscriptUtilities" {}]
    lappend ma [list Menu -n "psScripts" {}]
    
    return [list build $ma PS::menuProc {postscriptUtilities psScripts} $psMenu]
}

proc menu::buildPsUtilities {} {
    global PS_params
    return [list build $PS_params(utilprgs) PS::psUtilitiesProc ]
}

proc menu::buildPsScripts {} {
    set ma [PS::buildScriptsList]
    return [list build $ma PS::psScriptsProc ]
}

proc PS::menuProc {menu item} {
    global PSmodeVars
    switch $item {
	"processTheBuffer" {
	    if {[PS::checkdirty]} {PS::processCurrWin}
	}
	"processAFile..." {
	    catch {getfile "Select a \".ps\" file to process"}  name
	    if {$name==""} {return} 
	    edit -c -w $name
	    PS::processPsFile $name
	}
	"sendToViewer" {
	    if {[PS::checkdirty]} {PS::sendToViewer}
	}
	default {eval PS::$item}
    }
}

# ---------------------------------------------------------------
# List script files
# ---------------------------------------------------------------
proc PS::listScriptsInDir {dir ext} {
    global PS_params
    set PS_params(scriptnames)  ""
    set itemslist [glob -nocomplain -dir $dir *.$ext]
    foreach f $itemslist {
	if {[file isfile $f]} {
	    set f [file tail $f]
	    lappend PS_params(scriptnames) " $f"
	} 
    }
    return $PS_params(scriptnames) 
}

proc PS::buildScriptsList {} {
    global PS_params PSmodeVars 
    set defaultSubmenuItems [list "Rebuild Scripts List" "(-"]
    if {$PSmodeVars(buildScriptsList)} {
	if {$PSmodeVars(ScriptsFolder) == ""} {
	    catch {get_directory -p "Locate a scripts library."} PSdir
	    if {$PSdir != ""} {
		prefs::removeArrayElement PSmodeVars ScriptsFolder
		set PSmodeVars(ScriptsFolder) $PSdir
		prefs::addArrayElement PSmodeVars ScriptsFolder $PSdir
	    } else {
		set PS_params(scriptnames) {}
		return $defaultSubmenuItems
	    }	    
	}	
	if {![info exists PS_params(PSsubmenuitems)] || $PS_params(PSsubmenuitems) == "" } {
	    set PS_params(PSsubmenuitems) $defaultSubmenuItems
	} 
    } else {
	set PS_params(PSsubmenuitems) $defaultSubmenuItems
	return $PS_params(PSsubmenuitems)
    }
    if {$PSmodeVars(ScriptsFolder) != ""} {
	set PS_params(PSsubmenuitems) [concat $PS_params(PSsubmenuitems) \
	  [PS::listScriptsInDir "$PSmodeVars(ScriptsFolder)" ps]]
    }
    return $PS_params(PSsubmenuitems)
}


# Now build the menu
# ------------------
menu::buildSome psMenu 


# Menu items procs
# ----------------

proc PS::psUtilitiesProc {menu item} {
    global PS_params
    if {[regexp "¥" $item]} {return} 
    set item [string trimleft $item]
    PS::runPsUtility $item
}


proc PS::psScriptsProc {menu item} {
    global PS_params PSmodeVars 
    if {$item == "rebuildScriptsList"} {
	if {!$PSmodeVars(buildScriptsList) || $PSmodeVars(ScriptsFolder) == "" } {
	    alertnote "You must check the \"Build Scripts List\" checkbox \
	      and set the  \"Path To Scripts\" path in the PS mode preferences."
	} else {
	    PS::shadowList ""
	}
    } else {
	set item [string trimleft $item]
	edit -c [file join $PSmodeVars(ScriptsFolder) $item]
    } 
}


# ---------------------------------------------------------------
# Processing procs
# ---------------------------------------------------------------

proc PS::sendToViewer {} {
    PS::fileToViewer [win::Current]
}

proc PS::sendToPrinter {} {
    PS::fileToPrinter [win::Current]
}

proc PS::fileToViewer {filename} {
    global PS_params
    switch -- [PS::getExt] {
	"ps" - "PS" - "eps" - "EPS" - "epsf" - "EPSF" {
	    PS::processPsFile $filename
	}
	"pdf" - "PDF" {
	    PS::execute PS_params(pdfreader) viewPDF $filename
	}
	default {
	    # Do as if it were a ps extension (files generated by Metapost have 
	    # numerical extensions for instance, like myfile.1 etc.)
	    PS::processPsFile $filename
	}
    }	
}

proc PS::fileToPrinter {filename} {
    global PS_params
    if {[file exists $filename]} {
	switch -- [PS::getExt] {
	    "ps" -
	    "PS" {
		PS::execute PS_params(printps) printPS $filename
	    }
	    "pdf" -
	    "PDF" {
		PS::execute PS_params(pdfreader) printPDF $filename
	    }
	    default {
		PS::execute PS_params(printps) printPS $filename
	    }
	}	
    } else {
	alertnote "Can't find file $filename"
    }
}

proc PS::processTheSelection {} {
    global PREFS
    if {[pos::compare [getPos] == [selEnd]]} {
	alertnote "No region selected."
	return
    }
    set excerpt [getSelect]
    # These four lines borrowed from latexComm.tcl
    set rootFile [file rootname [win::Current]]
    set tempFile "temp-[file tail $rootFile]"
    if {![file exists [file join $PREFS tmp]]} { file mkdir [file join $PREFS tmp] }
    set tmpname [file join $PREFS tmp $tempFile]
    catch {open $tmpname w+} fileId
    puts $fileId $excerpt
    close $fileId
    PS::processPsFile $tmpname
}

proc PS::processCurrWin {} {
    save
    PS::processPsFile [win::Current]
}

proc PS::processPsFile {filename} {
    PS::execute PS_params(ghostview) viewPS $filename
}

proc PS::execute {sig action filename} {
    app::execute -sigVar $sig -op $action -filename $filename -prompt $action
}

proc PS::oldExecute {ext sig aeclass aeid type filename} {
    if {[file exists $filename]} {
	app::launchFore "$sig"
	tclAE::send -p '$sig' $aeclass $aeid ---- [tclAE::build::$type $filename]
    } else {
	alertnote "Can't find file $filename"
    }
}

proc PS::convertToPdf {} {
    PS::psToPdfFile [win::Current]
    status::msg "Ps to Pdf event sent OK"
}

proc PS::psToPdfFile {filename} {
    global PS_params PSmodeVars
    set basename [file rootname $filename]
    global tcl_platform
    
    if {$tcl_platform(platform) != "macintosh"} {
	# We need to work out how to add the papersize flag here to this
	# version when called on MacOS, then we can use it on all platforms.
	app::execute -sigVar PS_params(gs) -op convertPStoPDF \
	  -filename $filename -showLog 1 \
	  -flags [list -q -dCompatibilityLevel=1.2 -dMaxSubsetPct=100 \
	  -dNOPAUSE -dBATCH -sPAPERSIZE=$PSmodeVars(defaultPaperSize) \
	  -sDEVICE=pdfwrite -sOutputFile=[file tail $basename].pdf \
	  -c save pop -f [file tail $filename]]
    } else {
	app::launchFore "$PS_params(gs)"
	set cmdline "gs -q -dCompatibilityLevel=1.2 -dMaxSubsetPct=100 -dNOPAUSE -dBATCH \
	 -sPAPERSIZE=$PSmodeVars(defaultPaperSize) -sDEVICE=pdfwrite -sOutputFile=[file tail $basename].pdf \
	  -c save pop -f [file tail $basename].ps"
	tclAE::send -p '$PS_params(gs)' CMTX exec ---- [tclAE::build::TEXT $cmdline] dest [tclAE::build::alis "[file dirname $basename]:"] 
    }
}

# ---------------------------------------------------------------
# Postscript utilities procs
# ---------------------------------------------------------------

proc PS::runPsUtility {appl} {
    global PS_params
    if {![PS::buildCmdLine $appl]} {return}
    if {$PS_params(filename)==""} {return} 
    app::launchFore "[set PS_params($appl)]"
    PS::execCmdLine $appl
}

proc PS::buildCmdLine {appl} {
    global PS_params
    set PS_params(cmdline) ""
    switch $appl {
	afm2tfm {
	    PS::quitIfRunning $PS_params(afm2tfm)
	    if {[PS::fileToProcess afm]} {
		set PS_params(cmdline) "afm2tfm $PS_params(filename)"
	    } 
	}
	epstopdf {
	    if {[PS::fileToProcess eps]} {
		set PS_params(cmdline) "epstopdf [file tail $PS_params(filename)] \
		  [file root [file tail $PS_params(filename)]].pdf"
	    } 
	}
	lwfn2pfa {
	    if {[PS::fileToProcess lwfn]} {
		set PS_params(cmdline) "lwfn2pfa $PS_params(filename) $PS_params(basename).pfa"
	    }
	}
	pfa2lwfn {
	    if {[PS::fileToProcess pfa]} {
		set PS_params(cmdline) "pfa2lwfn $PS_params(filename)"
	    }
	}
	pfa2pfb {
	    if {[PS::fileToProcess pfa]} {
		set PS_params(cmdline) "pfa2pfb $PS_params(filename) $PS_params(basename).pfb"
	    }
	}
	pfb2pfa {
	    if {[PS::fileToProcess pfb]} {
		set PS_params(cmdline) "pfb2pfa $PS_params(filename) $PS_params(basename).pfa"
	    }
	}
	psbook -
	psnup -
	psselect -
	pstops {
	    if {[PS::fileToProcess ps]} {
		set outfile "[file rootname $PS_params(filename)].out.ps"
		set PS_params(cmdline) "$appl  $PS_params(filename)  $outfile"
	    }
	    return [PS::getOptions $appl]
	}
	t1asm {
	    if {[PS::fileToProcess ""]} {
		set PS_params(cmdline) "t1asm $PS_params(filename) $PS_params(basename).pfb"
	    }
	}
	t1disasm {
	    if {[PS::fileToProcess [list pfa pfb]]} {
		set PS_params(cmdline) "t1disasm $PS_params(filename) $PS_params(basename).disasm"
	    }
	}
    }
    return 1
}

proc PS::fileToProcess {exts} {
    global PS_params
    if {[expr {$exts != ""} && {[lsearch -exact $exts [PS::getExt]]!=-1}]} {
	set PS_params(filename) [win::Current]
    } else {
	set exts [join [split $exts] /]
	catch {getfile "Select a $exts file to process"}  name
	if {$name==""} {
	    set PS_params(filename) ""
	    return 0
	} 
	set PS_params(filename) $name
    }
    set PS_params(basename) [file rootname $PS_params(filename)]
    return 1
}

proc PS::getOptions {appl} {
    set opts(psbook) "q s"
    set opts(psnup) "qbl2489 hw"
    set opts(psselect) "qeor p"
    set opts(pstops) "qb hw"
    eval return \[PS::buildDialogs $appl [set opts($appl)]\]
}

proc PS::execCmdLine {appl} {
    global PS_params HOME
        if {$PS_params(basename)==""} {
        set PS_params(basename) $HOME
    } 
    catch {tclAE::send -p '[set PS_params($appl)]' CMTX exec \
      ---- [tclAE::build::TEXT $PS_params(cmdline)] \
      dest [tclAE::build::alis "[file dirname $PS_params(basename)]:"] } res     
}

# ---------------------------------------------------------------
# Psutils dialogs
# ---------------------------------------------------------------

proc PS::buildDialogs {appl checkboxes editfields} {
    global PS_params psvalues psargs
    PS::dialogInit "$appl options"
    PS::dialogCmdLinePart
    PS::dialogCheckPart $appl $checkboxes
    PS::dialogEditPart $appl $editfields
    PS::dialogButtonPart
    set psvalues [eval dialog -w 550 -h $PS_params(dialogy) [join $psargs]]
    return [PS::getOptionsValues $appl $checkboxes $editfields]
}

proc PS::dialogInit {title} {
    global PS_params psargs
    set PS_params(dialogtitle) $title
    set psargs ""
    set PS_params(dialogy) 30    
}

proc PS::dialogCmdLinePart {} {
    global PS_params psargs
    lappend psargs [list -t "* $PS_params(dialogtitle) *" 200 5 400 25]
    lappend psargs [list -t "Command line: " 10 $PS_params(dialogy) 140 [expr $PS_params(dialogy) + 20] \
      -e "$PS_params(cmdline)" 142 $PS_params(dialogy) 540 [expr $PS_params(dialogy) + 50] ]
    set PS_params(dialogy) [expr $PS_params(dialogy) + 35]
}

proc PS::dialogCheckPart {appl checkboxes} {
    global PS_params PS_options psargs
    set optlist [split $checkboxes ""]
    set dialogx 30
    foreach check $optlist {
	if {![info exists PS_options($appl$check)]} {
	    set PS_options($appl$check) 0
	}
	lappend psargs [list -c "-$check" [set PS_options($appl$check)] $dialogx [expr $PS_params(dialogy) + 28] \
	  [expr $dialogx + 40] [expr $PS_params(dialogy) + 48] ]
	set dialogx [expr $dialogx + 70]
    } 
    set PS_params(dialogy) [expr $PS_params(dialogy) + 30]
}

proc PS::dialogEditPart {appl editfields} {
    global PS_params psargs PS_options
    set optlist [split $editfields ""]
    set dialogx 30
    foreach field $optlist {
	if {![info exists PS_options($appl$field)]} {
	    set PS_options($appl$field) ""
	}
	lappend psargs [list -t "-$field" $dialogx [expr $PS_params(dialogy) + 28] \
	  [expr $dialogx + 25] [expr $PS_params(dialogy) + 48] \
	  -e [set PS_options($appl$field)] [expr $dialogx + 30] [expr $PS_params(dialogy) + 28] \
	  [expr $dialogx + 90] [expr $PS_params(dialogy) + 48] ]
	set dialogx [expr $dialogx + 140]
    } 
    if {$appl=="pstops"} {
	set dialogx 30
	set PS_params(dialogy) [expr $PS_params(dialogy) + 30]
	lappend psargs [list -t "pagespecs " $dialogx [expr $PS_params(dialogy) + 28] [expr $dialogx + 75] \
	  [expr $PS_params(dialogy) + 48] \
	  -e [set PS_options($appl$field)] [expr $dialogx + 80] [expr $PS_params(dialogy) + 28] \
	  [expr $dialogx + 420] [expr $PS_params(dialogy) + 48] ]
    } 
    set PS_params(dialogy) [expr $PS_params(dialogy) + 20]
}

proc PS::dialogButtonPart {} {
    global PS_params psargs
    lappend psargs [list -b "OK" 445 [expr $PS_params(dialogy) + 40] 530 [expr $PS_params(dialogy) + 60] \
      -b "cancel" 345 [expr $PS_params(dialogy) + 40] 430 [expr $PS_params(dialogy) + 60]
    ]
    set PS_params(dialogy) [expr $PS_params(dialogy) + 70]
}

proc PS::getOptionsValues {appl checkboxes editfields} {
    global PS_params PS_options psvalues
    set numopt [string length "$checkboxes$editfields"]
    if {$appl=="pstops"} {incr numopt}
    if {[lindex $psvalues [expr $numopt + 2]]} {return 0}
    set line [lindex $psvalues 0]
    regsub $appl $line "" line
    set i 1
    set cmd ""
    set optlist [split $checkboxes ""]
    foreach item $optlist {
	set PS_options($appl$item) [lindex $psvalues $i]
	if {[lindex $psvalues $i]==1} {
	    append cmd "-$item "
	} 
	incr i
    }  
    set optlist [split $editfields ""]
    foreach item $optlist {
	set PS_options($appl$item) [lindex $psvalues $i]
	if {[lindex $psvalues $i]!=""} {
	    append cmd "-$item[lindex $psvalues $i] "
	} 
	incr i
    }  
    if {$appl=="pstops" && [lindex $psvalues $i]!=""} {
	append cmd "[lindex $psvalues $i] "
    }
    
    set PS_params(cmdline) "$appl $cmd$line"
    return 1
}


# ---------------------------------------------------------------
# Ghostscript procs
# ---------------------------------------------------------------
proc PS::buildGsCommand {} {
    global tileLeft tileTop tileWidth errorHeight PS_params
    new -g [expr $tileLeft+110] $tileTop [expr $tileWidth - 200] [expr $errorHeight] \
      -n "$PS_params(gscmdwindow)" -mode PS
    insertText "gs "
    PS::showGsPalette
    PS::gsExecPalette
}

proc PS::sendToGhostscript {} {
    global PS_params 
    set inipos [getPos]
    set lastpos [selEnd]
    if {[pos::compare $inipos==$lastpos]} {
	set inipos [minPos]
	set lastpos [maxPos]
    } 
    set cmdline [getText $inipos $lastpos]
    regsub -all "\\\\? *\\\r" $cmdline " " cmdline
    set PS_params(cmdline) $cmdline
    app::launchFore $PS_params(gs)
    PS::execCmdLine gs
}


# ---------------------------------------------------------------
# Misc procs
# ---------------------------------------------------------------
proc PS::shadowList {name} {
    global PS_params
    set PS_params(PSsubmenuitems) ""
    menu::buildSome psScripts
}

proc PS::getExt {{filename ""}} {
    if {$filename==""} {
        set filename [win::Current]
    } 
    return [string trimleft [file extension $filename] "."]
}

proc PS::checkdirty {} {
    if {[winDirty]} {
	switch [askyesno -c "Dirty window '[lindex [winNames] 0]'. Do you want to save it ?"] {
	    "yes" {save}
	    "no" {}
	    "cancel" {return 0}
	}
    }
    return 1
}

proc PS::quitIfRunning {sig} {
    if {[app::isRunning $sig]} {
	sendQuitEvent '$sig'
    }
}

proc PS::showGsPalette {} {
    global PS_params tileTop 
    Menu -m -n gspalette -p PS::gsPaletteProc $PS_params(gsoptions)
    float -m "gspalette" -t $tileTop -l 0 -n "" -z sgs
}

proc PS::gsExecPalette {} {
    global tileTop tileWidth 
    Menu -m -n gsexec -p PS::gsExecProc {
	"EXECUTE"
	"FILE PATH"
	"CLOSE"
    }
    float -m "gsexec" -M 5 -h 35 -w 70 -t [expr $tileTop] -l [expr $tileWidth -80] -n "" -z xgs
}

proc PS::gsExecProc {menu item} {
    global PS_params
    switch $item {
	"EXECUTE" {
	    PS::sendToGhostscript
	}
	"CLOSE" {
	    floatShowHide off xgs
	    floatShowHide off sgs
	    bringToFront $PS_params(gscmdwindow) 
	    setWinInfo -w $PS_params(gscmdwindow) dirty 0
	    killWindow
	}
	"FILE PATH" {
	    catch {getfile "Select a file."}  name
	    if {$name==""} {return} 
	    insertText $name
	}
    }
}

proc PS::gsPaletteProc {menu item} {
    global PS_params PSmodeVars
    set item [string trimleft $item]
    set eqsignlist [list -dCOLORSCREEN -dDITHERPPI -dORIENT1 -sDEVICE -sFONTMAP -sFONTPATH\
      -sOutputFile -sSUBSTFONT -dFirstPage -dLastPage -sPSFile]
    if {$item=="-sPAPERSIZE"} {
	set paper [listpick -L $PSmodeVars(defaultPaperSize) -p "Choose a paper size :" $PS_params(paperlist)]
	if {$paper!=""} {
	    insertText "$item=$paper "
	}
	return
    } 
    if {[lsearch -exact $eqsignlist $item]!=-1} {
	append item "="
	insertText "$item"
	return
    }
    insertText "$item "
}

# =====================
# Mode specific goodies
# =====================
# 
# Syntax Coloring
# ---------------
# We define two groups of keywords :
# -  the Postscript keywords. Default color : blue
# -  the PDF keywords. Default color : magenta
# These colors can be modified in the mode prefs : see "Ps Keyword Color" 
# and "Pdf Keyword Color".

set PSKeyWords {
FontDirectory GlobalFontDirectory ISOLatin1Encoding
StandardEncoding UserObjects VMerror abs add aload anchorsearch
and arc arcn arct arcto array ashow astore atan awidthshow
begin bind bitshift bytesavailable cachestatus ceiling charpath
clear cleardictstack cleartomark clip clippath cliprestore
clipsave closefile closepath colorimage composefont concat
concatmatrix configurationerror copy copypage cos count
countdictstack countexecstack counttomark cshow
currentblackgeneration currentcacheparams currentcmykcolor
currentcolor currentcolorrendering currentcolorscreen
currentcolortransfer currentdash currentdevparams currentdict
currentfile currentflat currentfont currentglobal currentgray
currentgstate currenthalftone currentlinecap currentlinejoin
currentlinewidth currentmatrix currentmiterlimit
currentobjectformat currentoverprint currentpacking
currentpagedevice currentpoint currentrgbcolor currentscreen
currentsmoothness currentstrokeadjust currentsystemparams
currenttransfer currentundercolorremoval currentuserparams
curveto cuttenthsbcolor cvi cvlit cvn cvr cvrs cvs cvx def
defaultmatrix definefont defineresource defineuserobject
deletefile dict dictfull dictstack dictstackoverflow
dictstackunderflow div dtransform dup echo end eoclip eofill eq
erasepage error errordict exch exec execform execstack
execstackoverflow executeonly executive exit exp false file
filenameforall filesposition fill filter findcolorrendering
findefont findencoding findresource flattenpath floor flush
flushfile for forall gcheck ge get getinterval globaldict
glyphshow grestore grestoreall gsave gt handleerror identmatrix
idiv idtransform if ifelse image imagemask index ineofill
infill initclip initgraphics initmatrix instroke interrupt
inueofill inufill inustroke invalidaccess invalidexit
invalidfileaccess invalidfont invalidrestore invertmatrix
ioerror itransform known kshow languagelevel le length
limitcheck lineto ln load log loop lt makefont makepattern
matrix maxlength mod moveto mul ne neg newpath noaccess
nocurrentpoint not null nulldevice or packedarray pathbbox
pathforall pop print printobject product prompt pstack put
putinterval quit rand rangecheck rcheck rcurveto read
readhexstring readline readonly readstring realtime rectclip
rectfill rectstroke renamefile repeat resetfile resourceforall
resourcestatus restore reversepath revision rlineto rmoveto
roll rootfont rotate round rrand run save scale scalefont
search selectfont serialnumber setbbox setblackgeneration
setcachedevice setcachedevice2 setcachelimit setcacheparams
setcharwidth setcmykcolor setcolor setcolorrendering
setcolorscreen setcolorspace setcolortransfer setdash
setdevparams setfileposition setflat setfont setglobal setgray
setgstate sethalftone sethsbcolor setjoin setlinecap
setlinewidth setmatrix setmiterlimit setobjectformat
setoverprint setpacking setpagedevice setpattern setrgbcolor
setscreen setsmoothness setstrokeadjust setsystemparams
settransfer setucacheparams setundercolorremoval setuserparams
setvmthreshold shfill show showpage sin sqrt srand stack
stackoverflow stackunderflow start startjob status statusdict
stop stopped store string stringwidth stroke strokepath sub
syntaxerror systemdict timeout token token transform translate
true truncate type typecheck uappend ucache ucachestatus
ueofill ufill undef undefined undefinedfilename
undefinedresource undefinedresult undefinefont undefineresource
undefineuserobject unmatchedmark unregistered upath userdict
usertime ustroke ustrokepath version vmreclaim vmstatus wcheck
where widthshow write writehexstring writeobject writestring
xcheck xor xshow xyshow yshow
}

set PDFKeyWords { 
ASCII ASCII85Decode ASCIIHexDecode AccurateScreens AcroForm AlphaNum
Alphabetic Alternate Alternates Angle Annot AnnotStates Annots AntiAlias
ApRef ArtBox Ascent Aspect Author AvgWidth BBox Background Base BaseEncoding
BaseFont BitsPerComponent BitsPerCoordinate BitsPerFlag BitsPerSample
BlackIs1 BlackPoint BleedBox Border Bounds ByteRange CCITTFaxDecode
CIDFontType0 CIDFontType0C CIDFontType1 CIDSet CIDSystemInfo CIDToGIDMap
CMapName CalGray CalRGB CapHeight CenterWindow CharProcs CharSet CheckSum
ClassMap ClrF ClrFf Color ColorSpace ColorTransform ColorType Colorants
Colors Columns Comments Contents Coords CosineDot Count CreationDate Creator
CropBox CropFixed CropRect Cross DCTDecode DamagedRowsBeforeError Decode
DecodeParms Default DefaultForPrinting DescendantFonts Descent Dest Dests
DeviceColorant DeviceGray DeviceN DeviceRGB Diamond Differences Dingbats
Direction Domain Double DoubleDot Duration EarlyChange Ellipse EllipseA
EllipseB EllipseC Encode EncodedByteAlign Encoding Encrypt EndOfBlock
EndOfLine ExtGState Extend FDecodeParms FFilter FWPosition FWScale
Fields Filter First FirstChar FirstPage FitWindow Flags FlateDecode
Font FontBBox FontDescriptor FontFauxing FontFile FontFile2 FontFile3
FontMatrix FontName FormType FreeText Frequency Function FunctionType
Functions Gamma Generic GrayMap HKana HRoman HalftoneName HalftoneType
Hangul Hanja Height Height2 Hidden HideMenubar HideToolbar HideWindowUI
HojoKanji Interpolate InvertedDouble InvertedDoubleDot InvertedEllipseA
InvertedEllipseC InvertedSimpleDot Invisible IsMap ItalicAngle JavaScript
Kana Kanji Keywords Kids LZWDecode Lang Last LastChar LastModified LastPage
Leading Length Length1 Length2 Length3 Level1 Limits Line LineX LineY Linearized
Location MCID MMType1 MacExpertEncoding MacRomanEncoding MainImage Mask
Matrix MaxLen MaxWidth MediaBox MissingWidth ModDate Mode Movie Name Names
NeedAppearances NewWindow Next NextPage NoRotate NoView NoZoom
NonFullScreenPageMode None Nums Open OpenAction Operation Order Ordering
Outlines Overprint PDFDocEncoding Page PageLabels PageLayout PageMode
Pages PaintType Panose Params Parent ParentTree ParentTreeNextKey Pattern
PatternType Perceptual PieceInfo Popup Position Poster Predictor Prev
PrevPage Print Private ProcSet Producer Properties Proportional Quadpoints
Range Rate Reason Rect Registry RelativeColorimetric Rename Repeat ResFork
Resolution Resources Rhomboid RoleMap Root Rotate Round Rows RunLengthDecode
Saturation Separation SeparationColorNames SeparationInfo SetF SetFf
Shading ShadingType ShowControls SigFlags SimpleDot Size Sound SpiderInfo
SpotFunction Square StandardEncoding Start Status StemH StemV StmOwn
StructParents StructTreeRoot Style SubFilter Subject Subtype Supplement
Synchronous TRef Tags Templates Threads Thumb TilingType Tint Title ToUnicode
Trans TransferFunction Transparency TrapRegions TrapStyles Trapped TrimBox
TrueType Type0 Type1 Type3 UCR2 URLS Unix UseCMap Version VerticesPerRow
ViewerPreferences Volume WMode WhitePoint Width Width2 Widths WinAnsiEncoding
XHeight XObject XSquare XStep YSquare YStep 
}

# regModeKeywords -e {%} -m {/}  -c $PSmodeVars(commentColor) \
#   -k $PSmodeVars(psKeywordColor) PS $PSKeyWords -i "\}" -i "\{" -i "\[" -i "\]" -I green
# 
# regModeKeywords  -a -k $PSmodeVars(pdfKeywordColor) PS $PDFKeyWords
# 

regModeKeywords -C PS {}
regModeKeywords -a -e {%} -m {/}  -c $PSmodeVars(commentColor) PS {}
  
proc PS::colorizePS {{pref ""}} {
    global PSmodeVars PSKeyWords PDFKeyWords
    regModeKeywords -a -k $PSmodeVars(psKeywordColor) \
      -i "\}" -i "\{" -i "\[" -i "\]" -I green \
      PS $PSKeyWords
    regModeKeywords  -a -k $PSmodeVars(pdfKeywordColor) PS $PDFKeyWords
    if {$pref != ""} {refresh}
}

# Calling PS::colorizePS now.
PS::colorizePS

# Completions
# -----------

set completions(PS) {completion::cmd completion::electric}

set PScmds [lsort -dictionary [concat $PSKeyWords $PDFKeyWords]]

# # We don't need the keywords anymore :
# unset PSKeyWords
# unset PDFKeyWords

# # # # # abbreviations # # # # #

set PSelectrics(def)   "×kill0/¥name¥ {\n¥proc¥\n} def"
set PSelectrics(for)  "×kill0¥start¥ ¥incr¥ ¥end¥ { ¥proc¥ } for"
set PSelectrics(forall)   "×kill0¥obj¥ { ¥proc¥ } for"
set PSelectrics(if)   "×kill0¥bool¥ { ¥proc¥ } if"
set PSelectrics(ifelse)   "×kill0¥bool¥ { ¥procyes¥ } { ¥procno¥ } ifelse"
set PSelectrics(loop)   "×kill0{\n¥proc¥\n} loop"
set PSelectrics(repeat)   "×kill0¥number¥ {\n¥proc¥\n} repeat"


# Key Bindings
# ------------

# Here we define PostScript specific key bindings.
# ctrl-V to process the current window
Bind 'v' <z> PS::processCurrWin PS
# cmd-return, enter and command-enter are bound to the 
# execution of a Ghostscript command line:
Bind 0x24 <c> {PS::sendToGhostscript} PS
Bind 0x4c {PS::sendToGhostscript} PS
Bind 0x4c <c> {PS::sendToGhostscript} PS


# File Marking
# ------------
# Marking is different in PS source files and in AFM metrics files.
# In PS source files :
#    mark the dictionaries declarations, the BeginFont and Page
#    DSC (Document Structured Comments)
# In Adobe metrics files ".afm" :
#    mark the main sections of the file (StartFontMetrics, StartCharMetrics, 
#    StartKernData, StartKernPairs, StartTrackKern) and all the characters 
#    whose metrics are defined.

proc PS::MarkFile {args} {
    win::parseArgs win
    set ext [file extension $win]
    if {$ext==".afm"} {
        PS::MarkMetricsFile -w $win
    } else {
	PS::MarkPSFile -w $win
    }
}

proc PS::MarkPSFile {args} {
    win::parseArgs win
    #  First mark the declarations of dictionaries
    set end [maxPos -w $win]
    set pos [minPos]
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "/\\w+ \\d+ dict def" $pos} res]} {
	set start [lindex $res 0]
	set end [lindex $res 1]
	set txt [getText -w $win  $start $end]
	regsub " .*" $txt "" txt
	set pos [nextLineStart -w $win $start]
	set inds($txt) [lineStart -w $win [pos::math -w $win $start - 1]]
    }
    if {[info exists inds]} {
	foreach f [lsort [array names inds]] {
	    set next [nextLineStart -w $win $inds($f)]
	    setNamedMark -w $win $f $inds($f) $next $next
	}
	unset inds
    }
    #  Then mark the %%BeginFont DSC
    set end [maxPos -w $win]
    set pos [minPos]
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "%%BeginFont:( |\\w|\\d)+" $pos} res]} {
	set start [lindex $res 0]
	set end [lindex $res 1]
	set txt [getText -w $win [pos::math -w $win $start +2] $end]
	set pos $end
	set inds($txt) [lineStart -w $win [pos::math -w $win $start - 1]]
    }
    if {[info exists inds]} {
	foreach f [lsort [array names inds]] {
	    set next [nextLineStart -w $win $inds($f)]
	    setNamedMark -w $win $f $inds($f) $next $next
	}
	unset inds
    }
    #  Then mark the %%Page DSC
    set end [maxPos -w $win]
    set pos [minPos]
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "%%Page:\[^\r\n\]+" $pos} res]} {
	set start [lindex $res 0]
	set end [lindex $res 1]
	set txt [getText -w $win [pos::math -w $win $start +2] $end]
	set pos $end
	set inds($txt) [lineStart -w $win [pos::math -w $win $start - 1]]
    }
    if {[info exists inds]} {
	foreach f [lsort [array names inds]] {
	    set next [nextLineStart -w $win $inds($f)]
	    setNamedMark -w $win $f $inds($f) $next $next
	}
	unset inds
    }
}


proc PS::MarkMetricsFile {args} {
    win::parseArgs win
    #  First mark the start declarations
    set end [maxPos -w $win]
    set pos [minPos]
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "^Start\\w+" $pos} res]} {
	set start [lindex $res 0]
	set end [lindex $res 1]
	set txt [getText -w $win  $start $end]
	regsub " .*" $txt "" txt
	set pos [nextLineStart -w $win $start]
	set inds($txt) [lineStart -w $win [pos::math -w $win $start - 1]]
    }
    if {[info exists inds]} {
	foreach f [lsort [array names inds]] {
	    set next [nextLineStart -w $win $inds($f)]
	    setNamedMark -w $win $f $inds($f) $next $next
	}
	unset inds
    }
    #  Then mark each character's metric information
    set end [maxPos -w $win]
    set pos [minPos]
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "^C +-?\\d+ +; +WX +\\d+ +; +N \\w+" $pos} res]} {
	set start [lindex $res 0]
	set end [lindex $res 1]
	set txt [getText -w $win $start $end]
	regsub ".+; +N " $txt "" txt
	set pos $end
	set inds($txt) [lineStart -w $win [pos::math -w $win $start - 1]]
    }
    if {[info exists inds]} {
	foreach f [lsort -dictionary [array names inds]] {
	    set next [nextLineStart -w $win $inds($f)]
	    setNamedMark -w $win $f $inds($f) $next $next
	}
	unset inds
    }
}

# The "{}" menu
# -------------
# The "{}" pop-up menu contains the 'def' statements  :
# WARNING: there are so many def's in a PostScript file that this proc could
# possibly exceed Alpha's memory and cause a crash.

proc PS::parseFuncs {} {
    global PSmodeVars PS_params
    set searchstr $PSmodeVars(funcExpr)
    set PS_params(parse) 1
    set pos [minPos]
    set m {}
    while {[set res [search -s -f 1 -r 1 -i 0 -n "$searchstr" $pos]] != ""} {
	set txt [eval getText $res]
	regsub "/(\[-_\\w\\d\]+).*" $txt "\\1" txt
	lappend m $txt
	lappend m [lindex $res 0]
	set pos [lindex $res 1]
    }
    return $m
}


# Command-Double-click
# --------------------
# If you Command-Double-Click on a keyword you access  its  definition.  This
# proc looks first for a 'def' in the current file itself then checks if it
# is a PostScript primitive.

proc PS::DblClick {from to} {
    global PS_params PScmds
    selectText $from $to
    set word [getText $from $to]
    set searchstr "/$word\[ \\t\]*(\\\{\[^\\\}\]+\\\}|\[^/\]+)\[ \\t\]*def\\b"
    # First we look for the word's definition in the current file :
    set pos [minPos]
    if {![catch {search -s -f 1 -r 1 -m 1 -i 0 "$searchstr" $pos} res]} {
	goto [lineStart [lindex $res 0]]
	selectText [lindex $res 0] [lindex $res 1]
	return
    }
    # If search failed, check if it is a PostScript primitive.
    if {[expr {[lsearch -exact $PScmds "$word"] > -1}]} {
	alertnote "\"$word\" is a PostScript primitive.\rSee the Reference Manual."
	return
    }
    status::msg "Could'nt find a definition for \"$word\"."
}


# Option-click on title bar
# -------------------------
# If you Option-Click on the title bar, you get a list of all the PS and PDF files located :
# - in the "local" folder (folder of currentwindow). 
# - in the scripts folder (selected in the preferences)
# Selecting any item will open it in a window or bring its window to front if
# it is already open.

proc PS::OptionTitlebar {} {
    global PS_params PSmodeVars minItemsInTitlePopup
    set minItemsInTitlePopup 1
    set PS_params(sep) "-"
    set psinlocaldir [glob -nocomplain -dir [file dirname [win::Current]] *.ps]
    set pdfinlocaldir [glob -nocomplain -dir [file dirname [win::Current]] *.pdf]
    set filesinlocaldir [concat $psinlocaldir $pdfinlocaldir]
    set filesinselecteddir {}
    if {$PSmodeVars(ScriptsFolder) !="" && $PSmodeVars(ScriptsFolder)!=[file dirname [win::Current]]} {
	set psinselecteddir [glob -nocomplain -dir $PSmodeVars(ScriptsFolder) *.ps]
	set pdfinselecteddir [glob -nocomplain -dir $PSmodeVars(ScriptsFolder) *.pdf]
	set filesinselecteddir [concat $psinselecteddir $pdfinselecteddir]
    }
    set l {}
    foreach f $filesinlocaldir {
	lappend l [file tail $f]
    }
    if {[llength $filesinselecteddir]} {
	lappend l $PS_params(sep) 
	foreach f $filesinselecteddir {
	    lappend l [file tail $f]
	}
    }
    return $l
}

proc PS::OptionTitlebarSelect {item} {
    global PS_params PSmodeVars
    if {$item == $PS_params(sep)} {return}
    if {[file exists [file join [file dirname [win::Current]] $item]]} {
	edit -c [file join [file dirname [win::Current]] $item]
    } else {
	edit -c [file join $PSmodeVars(ScriptsFolder) $item]
    }
}



