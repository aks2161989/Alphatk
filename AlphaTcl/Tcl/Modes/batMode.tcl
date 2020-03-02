# Automatically created by mode assistant
#
# Mode: bat, for Windows batch files.


# Mode declaration.
#  first two items are: name version
#  then 'source' means source this file when we first use the mode
#  then we list the extensions, and any features active by default
alpha::mode [list bat "DOS Batch"] 0.2 source {*.cmd *.bat *.sys} {
    batchMenu
} {
    # Script to execute at Alpha startup
    addMenu batchMenu "Bat"
} uninstall {
    this-file
} maintainer {
} description {
    Supports the editing of Microsoft Windows and DOS batch files
} help {
    This mode is for editing Microsoft Windows and DOS batch files.
    These files use a rudimentary shell programming language.
}

# For Tcl 8
namespace eval bat {}

# Mode preferences settings, which can be edited by the user (with F12)

newPref var lineWrap 0 bat

# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 1 bat

# These are used by the ::parseFuncs procedure when the user clicks on
# the {} button in a file edited using this mode.  If you need more sophisticated
# function marking, you need to add a bat::parseFuncs proc

newPref variable funcExpr {^:\(\w*\)$} bat
newPref variable parseExpr {^:\((\w*)\)$} bat

# Register comment prefix
set bat::commentCharacters(General) rem
# Register multiline comments
set bat::commentCharacters(Paragraph) {{rem } {rem } {rem }}
# List of keywords
set batKeyWords {
    ansi append assign attrib autofail backup basedev boot break buffers
    cache call cd chcp chdir chkdsk choice cls cmd codepage command comp
    copy country date ddinstal debug del detach device devicehigh devinfo
    dir diskcoache diskcomp diskcopy do doskey dpath dumpprocess eautil
    echo else end endlocal erase errorlevel exist exit exit_vdm extproc
    fcbs fdisk fdiskpm files find for format fsaccess fsfilter goto
    graftabl if iopl join keyb keys label lastdrive lh libpath loadhigh
    makeini maxwait md mem memman mkdir mode move net not off on patch
    path pause pauseonerror picview pmrexx print printmonbufsize priority
    priority_disk_io prompt protectonly protshell pstat rd recover reipl
    ren rename replace restore return rmdir rmsize run say select set
    setboot setlocal shell shift sort spool start subst suppresspopups
    swappath syslevel syslog then threads time timeslice trace tracebuf
    tracefmt trapdump tree type undelete unpack use ver verify view
    vmdisk vol when xcopy xcopy32 xdfcopy
    title
}

# Colour the keywords, comments etc.
if {${alpha::platform} == "alpha"} {
    regModeKeywords -e rem bat $batKeyWords
} else {
    regModeKeywords -e {rem REM ::} bat $batKeyWords
}
# Discard the list
unset batKeyWords

proc bat::correctIndentation {args} {
    uplevel 1 ::correctBracesIndentation $args
}

proc batchMenu {} {}

Menu -p menu::generalProc -n $batchMenu {
    run
}

proc bat::run {} {
    if {![win::IsFile [win::Current] path]} {
	status::msg "Not a file window"
	return
    }
    
    set dir [pwd]
    cd [file dirname $path]
    if {[catch {exec [file tail $path]} res]} {
	alertnote $res
    } else {
        status::msg "Running batch file returned: $res"
    }
    cd $dir
}
