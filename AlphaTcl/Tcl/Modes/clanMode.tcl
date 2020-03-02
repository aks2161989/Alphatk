## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 #
 # FILE: "clanMode.tcl"
 #                                          created: 09/07/2001 {05:43:51 PM}
 #                                      last update: 05/23/2006 {10:31:57 AM}
 # Description:
 # 
 # Supports the editing of Child Language Data Exchange System transcripts.
 # 
 # Author: ??
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::mode Clan 1.1 clanMenu { *.cha } {
    clanMenu
} {
    # Script to execute at Alpha startup
    addMenu clanMenu "Clan"
} uninstall {
    this-file
} maintainer {
} description {
    Supports the editing of Child Language Data Exchange System transcripts
} help {
    CLAN is a program that is designed specifically to analyze data
    transcribed in the format of the Child Language Data Exchange System
    (CHILDES).  CLAN was written by Leonid Spektor at Carnegie Mellon
    University.  The current version uses a graphic user interface and runs
    on both Macintosh and Windows machines.  Earlier versions also ran on DOS
    and Unix without a graphic user interface.  CLAN allows you to perform a
    large number of automatic analyses on transcript data.  The analyses
    include fre-quency counts, word searches, co-occurrence analyses, mean
    length of utterance (MLU) counts, interactional analyses, text changes,
    and morphosyntactic analysis.

    For more information, see <http://childes.psy.cmu.edu>.

    Click here "CLAN Example.cha" for an example syntax file.
}

proc clanMode.tcl {} {}

proc clanMenu {} {}
ensureset clanSig MCED

newPref v wordBreak {([\$%*])?[\w_]+} Clan
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 0 Clan

newPref v lineWrap 0 Clan
newPref v paraColumn 10000 Clan
regModeKeywords -C Clan {}
regModeKeywords -a -m \$ Clan {}
regModeKeywords -a -k blue Clan {*MOT *TEA *INT *INV}
regModeKeywords -a -k red Clan {
    *CHI *CH1 *CH2 *CH3 *CH4 *STU *S10 *S11 *ST1 *ST2 *ST3 *ST4 *ST5 *ST6 *ST7 *ST8 *ST9
}
regModeKeywords -a -k green -e @ -c magenta Clan {
    %tim %co
    m %gpx %pho %act %spa %par %bg %lan %cod %mor %err
}

Menu -n $clanMenu -p clan::MenuProc {
    "switchToClan"
    "(-"
    "/K<U<OopenFileInClan"
    "checkUtterances"
    "convert"
    "count"
    "fixMultiline"
    "compareCodes"
    "continueComparingCodes"
}

#insertMenu $clanMenu

namespace eval clan {}

proc clan::MenuProc {menu item} {
    global clanSig
    switch $item {
	switchToClan {app::launchFore $clanSig}
	openFileInClan {
	    openAndSendFile $clanSig
	}
	checkUtterances {
	    clan::checkUtterances
	}
	convert {
	    clan::convert
	}
	count {
	    clan::count
	}
	fixMultiline {
	    clan::fixMultiline
	}
	compareCodes {
	    clan::compareCodes
	}
	continueComparingCodes {
	    clan::continueComparingCodes
	}
    }
}

proc clan::checkUtterances {} {
    set p [minPos]
    browse::Start 
    while {1} {
	while {1} {
	    set text [getText $p [nextLineStart $p]]
	    if {[string range $text 0 1] == "*C"} {break}
	    set p [nextLineStart $p]
	    if {[pos::compare $p == [maxPos]]} {
		status::msg "Done"
		break
	    }
	}
	if {[pos::compare $p == [maxPos]]} {break}
	set chi [getText $p [set p [nextLineStart $p]]]
	set lan [getText $p [set p [nextLineStart $p]]]
	if {[string range $lan 0 3] != "%lan"} {
	    set col [lindex [pos::toRowChar $p] 0]
	    incr col -1
	    browse::Add [win::Current] [string trim $chi$lan] $col
	    continue
	}
	set cod [getText $p [set p [nextLineStart $p]]]
	regsub -all "\\\[\[^\]\[\]+\\\]" $chi "" chi
	regsub -all "\\\[\[^\]\[\]+\\\]" $lan "" lan
	regsub -all "\\\[\[^\]\[\]+\\\]" $cod "" cod
	regsub -all "\[ \t\]+" [string trim $chi] " " chi
	regsub -all "\[.?!\]\[ \t\]+" $chi "." chi
	regsub -all "\[ \t\]+" [string trim $lan] " " lan
	regsub -all "\[ \t\]+" [string trim $cod] " " cod
	set chicount [regsub -all "\[.?!\]+" $chi X X]
	set lcount [regsub -all " " $lan X X]
	set ccount [regsub -all " " $cod X X]
	if {($lcount != $ccount) || ($chicount != $lcount)} {
	    #status::msg "Got $ucount , $ccount, $utterance, $code"
	    #goto [pos::prevLineStart $p]
	    #return
	    set col [lindex [pos::toRowChar $p] 0]
	    incr col -3
	    browse::Add [win::Current] [string trim $chi\r$lan\r$cod] $col
	}
    }
    browse::Complete
}

proc clan::fixMultiline {} {
    set text [getText [minPos] [maxPos]]
    while {[regsub -all "(\\*CHI:\[^\r\n\]+)\[\r\n\](\[^%\])" $text "\\1 \\2" text]} {}
    replaceText [minPos] [maxPos] $text
}

proc clan::convert {} {
    set text [getText [minPos] [maxPos]]
    regsub -all "%cod:(\[^\r\n\]+\[\r\n\]%cod:)" $text "%lan:\\1" text
    replaceText [minPos] [maxPos] $text
}

proc clan::count {} {
    set text [getText [minPos] [maxPos]]
    set p [minPos]
    set countlan 0
    set countcod 0
    set counterr 0
    set countmor 0
    while {1} {
	if {[pos::compare $p == [maxPos]]} {break}
	set lan [getText $p [set p [nextLineStart $p]]]
	if {[string index $lan 0] != "%"} {continue}
	set type [string range $lan 1 3]
	regsub -all "\\\[\[^\]\[\]+\\\]" $lan "" lan
	regsub -all "\[ \t\]+" [string trim $lan] " " lan
	set lcount [regsub -all " " $lan X X]
	incr count$type $lcount
    }
    foreach v [info vars count*] {
	alpha::log stdout "$v = [set $v]"
    }
}

proc clan::continueComparingCodes {{p1 ""} {p2 ""}} {
    set w1 [lindex [winNames -f] 0]
    set w2 [lindex [winNames -f] 1]

    bringToFront $w1
    if {$p1 == ""} { set p1 [getPos] }
    bringToFront $w2
    if {$p2 == ""} { set p2 [getPos] }
    
    while {1} {
	bringToFront $w1
	set p1 [lindex [search -s -n -f 1 -i 0 -r 1 -m 0 {^\*(TEA|S|MOT|CH)} $p1] 0]
	if {$p1 == ""} break
	set type [getText $p1 [pos::math $p1 + 4]]
	if {$type == "*STR"} {
	    set p1 [nextLineStart $p1]
	    bringToFront $w2
	    set p2 [lindex [search -s -n -f 1 -i 0 -r 1 -m 0 {^\*(TEA|S|MOT|CH)} $p2] 0]
	    set type2 [getText $p2 [pos::math $p2 + 4]]
	    set p2 [nextLineStart $p2]
	    continue
	}
	set p1 [lindex [search -s -n -f 1 -r 1 -m 0 "^%cod:" $p1] 1]
	set c1 [getText $p1 [nextLineStart $p1]]
	bringToFront $w2
	set p2 [lindex [search -s -n -f 1 -i 0 -r 1 -m 0 {^\*(TEA|S|MOT|CH)} $p2] 0]
	set type2 [getText $p2 [pos::math $p2 + 4]]
	if {$type2 != $type} {
	    bringToFront $w1
	    goto $p1
	    selectText $p1 [nextLineStart $p1]
	    bringToFront $w2
	    goto $p2
	    selectText $p2 [nextLineStart $p2]
	    beep
	    return
	}
	set p2 [lindex [search -s -n -f 1 -r 1 -m 0 "^%cod:" $p2] 1]
	set c2 [getText $p2 [nextLineStart $p2]]
	
	set n1 [regsub -all {\$} $c1 "" x]
	set n2 [regsub -all {\$} $c2 "" x]
	if {$n1 != $n2} {
	    bringToFront $w1
	    goto $p1
	    selectText $p1 [nextLineStart $p1]
	    bringToFront $w2
	    goto $p2
	    selectText $p2 [nextLineStart $p2]
	    beep
	    status::msg "[file tail $w1] has $n1 , [file tail $w2] has $n2"
	    return
	}
	set codes1 [split [string trim $c1 "\$ \t"] \$]
	set codes2 [split [string trim $c2 "\$ \t"] \$]
	if {[string range $type 0 2] == "*CH"} {
	    set type "CHI"
	} elseif {[string range $type 0 1] == "*S"} {
	    set type "STU"
	}
	for {set i 0} {$i < [llength $codes1]} {incr i} {
	    set got1 [string range [lindex $codes1 $i] 0 2]
	    set got2 [string range [lindex $codes2 $i] 0 2]
	    if {![info exists result($type,$got1,$got2)]} {
		set result($type,$got1,$got2) 1
	    } else {
		incr result($type,$got1,$got2)
	    }
	}
    }
    set res "Left is $w1\rRight is $w2\r"
    foreach n [lsort [array names result]] {
	append res "$result($n)\t$n\r"
    }
    new -n "diff-[file tail $w1]" -text $res
}

proc clan::compareCodes {} {
    clan::continueComparingCodes [minPos] [minPos]
    
}

# ===========================================================================
# 
# .