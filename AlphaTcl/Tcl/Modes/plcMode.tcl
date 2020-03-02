# -*-Tcl-*- (install) (nowrap)
# 
# This file : plcMode.tcl
# Created : 2003-04-13 17:13:54
# Last modification : 2003-05-13 11:11:32
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
# 
#      Please have a look at the example file: Plc-Example.plc.
# 
# (c) Copyright : Bernard Desgraupes, 2003
#         All rights reserved.
# This software is free software, available under the same licensing 
# terms as the AlphaTcl library.


alpha::mode Plc 1.0.4 dummyPlc {*.plc *.ploc} \
  {} {} maintainer {
    "Bernard Desgraupes" <bdesgraupes@easyconnect.fr>  <http://webperso.easyconnect.fr/bdesgraupes/alpha.html> 
} uninstall {
    this-file
} description {
    Supports the editing of Property List Compiler files
} help {
    file "Plc Mode Help"
}

proc plcMode.tcl {} {}

# Dummy proc
proc dummyPlc {} {}

namespace eval Plc {
    variable Values [list "string " "dictionary\r\{\r\tkey \r\}" \
      "array\r\[\r\t\r\]" "boolean " "data " "date " "number "]
    variable CurrIdx 0
    variable LastRow 0
    # See <http://developer.apple.com/techpubs/macosx/Essentials/SystemOverview/PropertyListKeys/index.html>
    variable BundleKeys {
	APFileDescriptionKey APFileDestinationPath APFileName APFileSourcePath APFiles
	APInstallAction APInstallerURL CFAppleHelpAnchor CFBundleDevelopmentRegion
	CFBundleDisplayName CFBundleDocumentTypes CFBundleExecutable CFBundleGetInfoHTML
	CFBundleGetInfoString CFBundleHelpBookFolder CFBundleHelpBookName CFBundleIconFile
	CFBundleIdentifier CFBundleInfoDictionaryVersion CFBundleName CFBundlePackageType
	CFBundleShortVersionString CFBundleSignature CFBundleTypeRole CFBundleURLIconFile
	CFBundleURLName CFBundleURLSchemes CFBundleURLTypes CFBundleVersion 
	CFPlugInDynamicRegisterFunction CFPlugInDynamicRegistration CFPlugInFactories 
	CFPlugInTypes CFPlugInUnloadFunction LSBackgroundOnly LSPrefersCarbon LSPrefersClassic
	LSRequiresCarbon LSRequiresClassic LSUIElement NSAppleScriptEnabled 
	NSHumanReadableCopyright NSJavaNeeded NSJavaPath NSJavaRoot NSKeyEquivalent 
	NSMainNibFile NSMenuItem NSMessage NSPortName NSPrincipalClass NSReturnTypes 
	NSSendTypes NSServices NSTimeout NSUserData
    }
}

# Preferences
# ===========

newPref v leftFillColumn {3} Plc
newPref v prefixString {// } Plc
newPref var lineWrap {0} Plc
newPref f autoMark 0 Plc
newPref color stringColor green Plc
newPref color commentColor red Plc
newPref color macroColor red Plc
newPref color keywordColor blue Plc
newPref color directiveColor magenta Plc
# required for use of C++::correctIndentation
newPref f useFasterButWorseIndentation 0 Plc
newPref v indentComments "code 0" Plc "" indentationTypes varitem
newPref v indentC++Comments "code 0" Plc "" indentationTypes varitem
newPref v indentMacros "fixed 0" Plc "" indentationTypes varitem

# Initialization of variables
# ===========================
set Plc::escapeChar "\\"
set Plc::quotedstringChar "\""
set Plc::lineContinuationChar "\\"

set Plc::commentCharacters(General) "//"
set Plc::commentCharacters(Paragraph) [list "/* " " */" " * "]
set Plc::commentCharacters(Box) [list "/*" 2 "*/" 2 "*" 3]


# Syntax Coloring
# ===============
set PlcKeywords {
    as array boolean comment data date dictionary false file key
    localize number plist string true value 
}
set PlcDirectives {
    #define #elif #else #endif #error #if #ifdef
    #ifndef #include #message #undef #warning
}
# Predefined Macros
set PlcPredefmacros {
    __DATE__ __FILE__ __LINE__ __OUTPUT_CREATOR__ __OUTPUT_FILENAME__
    __OUTPUT_TYPE__ __PLIST__
}


regModeKeywords -C Plc {}
regModeKeywords -a -e {//} -b {/*} {*/} -c $PlcmodeVars(commentColor) \
  -k $PlcmodeVars(keywordColor) \
  -s $PlcmodeVars(stringColor) -m {#} Plc $PlcKeywords

regModeKeywords -a -k $PlcmodeVars(directiveColor) Plc $PlcDirectives
regModeKeywords -a -k $PlcmodeVars(macroColor) Plc $PlcPredefmacros


# Completions
# ===========

namespace eval Plc::Completion {}

set completions(Plc) {completion::electric Plist Value Key completion::cmd}

# Electrics
set Plcelectrics(array) "\r\[\r\t¥\r\]"
set Plcelectrics(dict) "×kill0dictionary\r\{\r\tkey \"¥\" value ¥\r\}"
set Plcelectrics(loc) "×kill0localize \"¥\"\r\{\r\tkey \"¥\" value ¥\r\}"
set Plcelectrics(locas) "×kill0localize \"¥\" as \"¥\"\r\{\r\tkey \"¥\" value ¥\r\}"
set Plcelectrics(localize) $Plcelectrics(loc)
set Plcelectrics(dictionary) $Plcelectrics(dict)
set Plcelectrics(key) " \""

# The format for a date is: YYYY '-' MM '-' DD 'T' HH ':' MM ':' SS 'Z'
# date "2002-12-18T12:00:00Z"
# date __DATE__

set Plccmds [lsort -dictionary [concat $PlcKeywords $PlcDirectives \
  $PlcPredefmacros ${Plc::BundleKeys}]]

unset PlcKeywords PlcDirectives PlcPredefmacros 

# Insert a full plist plc template. Optional arguments are commented.
proc Plc::Completion::Plist {} {
    set cmd [completion::lastWord pos]
    if {[regexp "plist" $cmd "" cmd]} {
	set txt "\r\{\r\tdictionary\r\t\{\r"
	append txt "\t\tkey \"CFBundleVersion\" value string \"¥\"\r"
	append txt "\t\tkey \"CFBundleShortVersionString\" value string \"¥\"\r\r"
	append txt "\t\tkey \"CFBundleName\" value string \"¥\"\r"
	append txt "\t\tkey \"CFBundleExecutable\" value string __OUTPUT_FILENAME__\r"
	append txt "\t\tkey \"CFBundleSignature\" value string __OUTPUT_CREATOR__\r"
	append txt "\t\tkey \"CFBundlePackageType\" value string __OUTPUT_TYPE__\r\r"
	append txt "\t\tkey \"CFBundleIconFile\" value string \"¥\"\r"
	append txt "\t\tkey \"CFBundleIdentifier\" value string \"¥\"\r\r"
	append txt "\t\tkey \"CFBundleInfoDictionaryVersion\" value string \"6.0\"\r\r"
	append txt "// \t\tkey \"CFBundleHelpBookFolder\" value string \"¥\"\r"
	append txt "// \t\tkey \"CFBundleHelpBookName\" value string \"¥\"\r\r"
	append txt "// \t\tkey \"CFBundleDisplayName\" value string \"¥\"\r"
	append txt "// \t\tkey \"CFBundleGetInfoString\" value string \"¥\"\r"
	append txt "// \t\tkey \"CFBundleGetInfoHTML\" value string \"¥\"\r"
	append txt "// \t\tkey \"CFBundleDevelopmentRegion\" value string \"¥\"\r\t\}\r\}\r"
	insertText $txt
	return 1
    } else {
	return 0
    }
}


# After the word 'value', cycle through all possible values (string, array etc.)
# while the complete key is pressed repeatedly
proc Plc::Completion::Value {} {
    set cmd [completion::lastWord pos]
    if {[regexp "^value" $cmd "" cmd]} {
	set currpos [getPos]
	set currRow [lindex [pos::toRowCol $currpos] 0]
	# If we are on a different line, reset the current index
	if {$Plc::LastRow != $currpos} {
	    set Plc::CurrIdx 0
	} 
	set Plc::LastRow $currpos
	set inserted [lindex $Plc::Values $Plc::CurrIdx]
	insertText $inserted
	selectText $currpos [pos::math $currpos + [string length $inserted]]
	incr Plc::CurrIdx
	if {$Plc::CurrIdx == [llength $Plc::Values]} {
	    set Plc::CurrIdx 0
	} 
	return 1
    }
    return 0
}


proc Plc::Completion::Key {} {
    set found 0
    set cmd [completion::lastWord pos]
    # If no quote opened yet, add an opening one
    if {[regexp "^key\[ \\t]+$" $cmd]} {
	insertText "\""
	return 1
    } 
    # If there is just an opening quote, proceed...
    if {[regexp "^key\[ \\t]+\"$" $cmd]} {
	set found 1
	set cmd ""
    } else {
	# ... otherwise find the second (incomplete) word
	set cmd [completion::lastTwoWords begin]
	if {[regexp "^key\[ \\t]*" $begin]} {
	    set found 1
	}
	# If there is already a closing quote, just complete with 'value'
	if {[regexp ".*\"" $cmd]} {
	    insertText " value " 
	    Plc::Completion::KeyMore $cmd
	    return 1
	} 
    }
    if {$found} {
	set matches [completion::fromList $cmd Plc::BundleKeys]
	if { $matches != ""} {
	    set match [completion::Find $cmd $matches]
	    insertText "\" value " 
	    Plc::Completion::KeyMore $match
	    return 1
	}
    }
    return 0
}

# Some keys need further expansion or have particular templates: 
# CFBundleURLTypes, NSServices, APFiles.
proc Plc::Completion::KeyMore {key} {
    set key [string trimright $key "\""]
    switch -- $key {
	"CFBundleURLTypes" {
	    if {[catch {prompt "How many URL types?" 1} num]} {break}
	    insertText "array\r\[\r"
	    for {set i 1} {$i <= $num} {incr i} {
		set txt "\tdictionary\r\t\{\r"
		foreach item [list CFBundleTypeRole CFBundleURLIconFile CFBundleURLName] {
		    append txt "\tkey \"$item\" value string \"\"\r"
		} 
		append txt "\tkey \"CFBundleURLSchemes\" value array\r\t\[\r\t\r\t\]\r"
		insertText "$txt\t\}\r\r"
	    }
	    insertText "\]\r\r"
	}
	"APFiles" {
	    if {[catch {prompt "How many files?" 1} num]} {break}
	    insertText "array\r\[\r"
	    for {set i 1} {$i <= $num} {incr i} {
		set txt "\tdictionary\r\t\{\r"
		foreach item [list APFileDescriptionKey APDisplayedAsContainer\
		  APFileDestinationPath APFileName APFileSourcePath APInstallAction] {
		    append txt "\tkey \"$item\" value string \"\"\r"
		} 
		insertText "$txt\t\}\r\r"
	    }
	    insertText "\]\r\r"
	}
	"CFBundleDocumentTypes" {
	    if {[catch {prompt "How many types?" 1} num]} {break}
	    insertText "array\r\[\r"
	    for {set i 1} {$i <= $num} {incr i} {
		set txt "\tdictionary\r\t\{\r"
		foreach item [list CFBundleTypeName CFBundleTypeIconFile] {
		    append txt "\tkey \"$item\" value string \"\"\r"
		} 
		foreach item [list CFBundleTypeOSTypes CFBundleTypeExtensions] {
		    append txt "\tkey \"$item\" value array\r\t\[\r\tstring \"\"\r\t\]\r"
		} 
		append txt "\tkey \"CFBundleTypeRole\" value string \"Editor/Viewer/None\"\r"
		insertText "$txt\t\}\r\r"
	    }
	    insertText "\]\r\r"
	}
	"NSServices" {
	    if {[catch {prompt "How many URL services?" 1} num]} {break}
	    insertText "array\r\[\r"
	    for {set i 1} {$i <= $num} {incr i} {
		set txt "\tdictionary\r\t\{\r"
		foreach item [list NSPortName NSMessage NSUserData NSTimeout] {
		    append txt "\tkey \"$item\" value string \"\"\r"
		} 
		append txt "\tkey \"NSSendTypes\" value array\r\t\[\r\t\r\t\]\r"
		append txt "\tkey \"NSReturnTypes\" value array\r\t\[\r\t\r\t\]\r"
		append txt "\tkey \"NSMenuItem\" value dictionnary\r\t\{\r\t\r\t\}\r"
		append txt "\tkey \"NSKeyEquivalent\" value dictionnary\r\t\{\r\t\r\t\}\r"
		insertText "$txt\t\}\r\r"
	    }
	    insertText "\]\r\r"
	}
	"CFPlugInFactories" {
	    if {[catch {prompt "How many factories?" 1} num]} {break}
	    insertText "dictionary\r\t\{\r"
	    for {set i 1} {$i <= $num} {incr i} {
		append txt "\tkey \"¥\" value string \"¥\"\r"
	    }
	    insertText "$txt\t\}\r\r"
	}
	"CFPlugInTypes" {
	    if {[catch {prompt "How many UUIDs?" 1} num]} {break}
	    insertText "dictionary\r\t\{\r"
	    insertText "\tkey \"¥\" value array\r\t\t\[\r"
		set txt ""
	    for {set i 1} {$i <= $num} {incr i} {
		append txt "\t\tstring \"\"\r"
	    }
	    insertText "$txt\t\t\]\r"
	    insertText "\t\}\r\r"
	}
	"CFBundleURLSchemes" - "NSJavaPath" - 
	"NSReturnTypes" - "NSSendTypes" {
	    insertText "array\r\[\r\t\r\]" 
	}
	"NSMenuItem" - "NSKeyEquivalent" {
	    insertText "dictionary\r\{\r\tkey \"\" value \r\}" 
	}
	"NSJavaNeeded" {
	    insertText "boolean/string" 
	}
	"CFPlugInDynamicRegistration" {
	    insertText "boolean yes/no" 
	}
	default {insertText string }
    }
}


# Command-Double-Click
# ====================

proc Plc::DblClick {from to} {
    global PlcKeywords
    # First check if it is a PostScript primitive.
    if {[expr {[lsearch -exact $PlcKeywords "$word"] > -1}]} {
	alertnote "\"$word\" is a PLC primitive."
	return
    }
    # Look for the word's definition in the help file :
    set helpfile [help::pathToHelp "Plc Mode Help"]
    if {![file exists $helpfile]} {
	status::msg "Couldn't find \"Plc Mode Help\"."
        return
    } 
    selectText $from $to
    set word [getText $from $to]
    edit -c -w $helpfile
    set searchstr "¥ $word "
    set pos [minPos]
    if {![catch {search -s -f 1 -r 1 -m 1 -i 0 "$searchstr" $pos} res]} {
	goto [lineStart [lindex $res 0]]
	eval selectText $res
	return
    }
    status::msg "Could'nt find a definition for \"$word\"."
}



# File marking
# ============

proc Plc::MarkFile {args} {
    win::parseArgs win
    # Mark 'plist' directive
    set markExpr "^\[ \t\]*plist\[ \t\r\n\]*\{"
    set pos [minPos]
    if {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 1 $markExpr $pos} res]} {
	set start [lindex $res 0]
	setNamedMark -w $win PLIST [pos::prevLineStart -w $win $start] $start [pos::lineEnd -w $win $start]
    }
    # Mark 'key' declarations. There may be multiply 
    # used keys (in different dictionaries).
    set markExpr "^\[ \t\]*key\[ \t\]+\"(\[a-zA-Z0-9 _\#\*\]+)\""
    set pos [minPos]
    set end [maxPos -w $win]
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 1 $markExpr $pos} res]} {
	set start [lindex $res 0]
	set end [lindex $res 1]
	set txt [getText -w $win $start $end]
	regexp $markExpr $txt dum k
	if {[info exists cnts($k)]} {
	    incr cnts($k)
	    set word " $k #$cnts($k)"
	    if {$cnts($k)==2} {
		set word0 " $k"
		set word1 " $k #1"
		set inds($word1) $inds($word0)
		unset inds($word0)
	    }
	} else {
	    set cnts($k) 1
	    set word " $k"
	}
	set pos [nextLineStart -w $win $start]
	set inds($word) [lineStart -w $win [pos::math -w $win $start - 1]]
    }
    if {[info exists inds]} {
	setNamedMark -w $win "KEYS:" [minPos] [minPos] [minPos]
	foreach f [lsort -dictionary [array names inds]] {
	    set next [nextLineStart -w $win $inds($f)]
	    setNamedMark -w $win "  $f" $inds($f) $next [nextLineStart -w $win $next]
	}
	unset inds
    }
    # Mark 'localize' directives
    set markExpr "^\[ \t\]*localize\[ \t\]+\"(\[a-zA-Z0-9 _\#\*\]+)\""
    set pos [minPos]
    set end [maxPos -w $win]
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 1 $markExpr $pos} res]} {
	set start [lindex $res 0]
	set end [lindex $res 1]
	set txt [getText -w $win $start $end]
	regexp $markExpr $txt dum lang
	set pos [nextLineStart -w $win $start]
	set inds($lang) [lineStart -w $win [pos::math -w $win $start - 1]]
    }
    if {[info exists inds]} {
	setNamedMark -w $win "LOCALIZE:" [minPos] [minPos] [minPos]
	foreach f [lsort -dictionary [array names inds]] {
	    set next [nextLineStart -w $win $inds($f)]
	    setNamedMark -w $win "  $f" $inds($f) $next $next
	}
	unset inds
    }
}

proc Plc::parseFuncs {} { C++::parseFuncs }


# Indentation routines
# ====================

proc Plc::indentLine {} { C++::indentLine }

proc Plc::correctIndentation {args} {eval C++::correctIndentation $args}

proc Plc::CommentLine {} { C++::CommentLine }

proc Plc::UncommentLine {} { C++::UncommentLine }

proc Plc::electricLeft {} { C++::electricLeft }


# Electric routines
# =================

proc Plc::carriageReturn {} { C++::carriageReturn }

proc Plc::foldableRegion {pos} { C++::foldableRegion $pos }

