
# Automatically created by mode assistant
# All other misconceptions by Joachim Kock
#
# Mode: dot
# 
# Keyword colouring, comment definition, indentation, funcs marking,
# and communication with dot and Graphviz, if available.
# 
#  modified   who rev   reason
#  --------   --- ----- ------
#  22/07/2004 JK  0.1   Original.
#  18/04/2005 BD  0.2   Completion. More keywords.
# ---------------------------------------------------------------------


# Mode declaration.
#  first two items are: name version
#  then 'source' means source this file when we first use the mode
#  then we list the extensions, and any features active by default
alpha::mode dot 0.2 source {*.dot} dotMenu {
    # Script to execute at Alpha startup
    addMenu dotMenu " ¥ "
} uninstall {
    this-file
} maintainer {
    "Joachim Kock" <kock@math.uqam.ca>
} description {
    Supports the editing of "dot" language files and Graphvix interaction
} help {
    For editing files in the dot language (for automatic graph design), and
    communicating with Graphviz (a package of graph utilities, including the
    dot program, as well as a graphical front-end).
    
    Open this "Dot Example.dot" window to see its syntax coloring and
    indentation scheme, as well as the special "Dot" menu.
    
    (See <http://www.pixelglow.com/graphviz/> for more information.)
}

# For Tcl 8
namespace eval dot {}

# This proc is called every time we turn the menu on.
# Its main effect is to ensure this code, including the
# menu definition below, has been loaded.
proc dotMenu {} {}
# Now we define the menu items.
Menu -n $dotMenu -p dot::menuProc {
    /T<OproducePdf
    /S<U<OsendWindowToGraphviz
    graphvizManual
    dotGuide
}

# This procedure is called whenever we select a menu item
proc dot::menuProc {menu item} {
    variable dotPath
    switch -- $item {
        producePdf {dot::sendToDot}
        sendWindowToGraphviz {dot::sendToGraphviz}
	graphvizManual {exec open [file join $dotPath \
	  "../Resources/English.lproj/GraphvizHelp/GraphvizHelp.html"]}
	dotGuide {exec open [file join $dotPath \
	  "../Resources/English.lproj/Guides/dotguide.pdf"]}

    }
}

# Mode preferences settings, which can be edited by the user (with F12)
newPref var lineWrap 0 dot
newPref flag indentOnReturn    1 dot
newPref color commentColor red dot 
newPref color keywordColor blue dot 
newPref color attributesColor magenta dot 
newPref color stringColor green dot 

# These are used by the ::parseFuncs procedure when the user clicks on
# the {} button in a file edited using this mode.  If you need more sophisticated
# function marking, you need to add a dot::parseFuncs proc

newPref variable funcExpr  {(?:|di|sub)graph\s+\"?(\w+)\"?\s+\{} dot
newPref variable parseExpr {(?:|di|sub)graph\s+\"?(\w+)\"?\s+\{} dot

newPref f sortFuncsMenu 0 dot

# Comment chars:
set dot::commentCharacters(General) //
set dot::commentCharacters(Paragraph) {{/* } { */} { * }}
set dot::commentCharacters(Box) [list "/*" 2 "*/" 2 "*" 3]
newPref var  prefixString      {// }    dot

# List of keywords
# ================

set graphKeywords [list digraph edge graph node subgraph ]
# This list also includes 'neato' keywords not found in 'dot:'
# 		height, id, len, overlap, pos, sep, splines, start, width
set attrKeywords [list \
  arrowhead arrowsize arrowtail bgcolor bottomlabel center clusterrank \
  color comment compound concentrate constraint decorate dir distortion \
  fillcolor fixedsize fontcolor fontname fontpath fontsize group headURL \
  headlabel headport height id label labelangle labeldistance labelfloat \
  labelfontcolor labelfontname labelfontsize labeljust labelloc layer \
  layers len lhead ltail margin mclimit minlen nodesep nslimit nslimit1 \
  ordering orientation overlap page pagedir peripheries pos quantum rank \
  rankdir ranksep ratio regular remincross rotate samehead sametail \
  samplepoints searchsize sep shape shapefile sides size skew splines start \
  style tailURL taillabel tailport toplabel URL weight width \
]

# Colour the keywords, comments etc.
regModeKeywords -e // -b {/* } { */} \
  -c $dotmodeVars(commentColor) \
  -k $dotmodeVars(keywordColor) \
  -s $dotmodeVars(stringColor) dot $graphKeywords

regModeKeywords -a -k $dotmodeVars(attributesColor) dot $attrKeywords

# Completion
# ==========
set completions(dot) {completion::cmd completion::electric}

# Complete keywords longer than 4 chars only
set dotcmds {}
foreach dotw [lsort -dictionary [concat $graphKeywords $attrKeywords]] {
    if {[string length $dotw] > 4} {
	lappend dotcmds $dotw
    } 
} 

# # Discard the keywords lists
unset -nocomplain dotw graphKeywords attrKeywords


# To write indentation code for your new mode (so your mode
# automatically takes advantage of the automatic indentation
# possibilities of 'tab', 'return' and 'paste'), you can take
# advantage of the shared proc ::indentLine.  All you need to write
# is a dot::correctIndentation proc, and as a
# starting point you can copy the code of the generic
# ::correctIndentation, found in indentation.tcl.


# Guess where the command line dot is:
if {[catch {exec which dot} ::dot::dotPath]} {
    if { [file executable /Applications/Graphviz.app/Contents/MacOS/dot] } {
	set dot::dotPath /Applications/Graphviz.app/Contents/MacOS
    } else {
	set dot::dotPath \
	  [lindex [glob -nocomplain /Applications/*/Graphviz.app/Contents/MacOS] 0]
	if {![file executable $dot::dotPath/dot] } {
	    # Should not throw an error just because the user wants to
	    # edit a .dot file, even if they don't have Graphviz
	    # installed.  Also, presumably on Unix/Windows this
	    # application will be elsewhere.

	    # error "Can't find dot"
	}
    }
}


proc dot::sendToGraphviz {{file ""} } {
    if { $file == "" } {
	set file [win::Current]
    }
   exec open -a Graphviz $file
}


proc dot::sendToDot { {file ""} } {
    if { $file == "" } {
	set file [win::Current]
    }
    set psOut [file rootname $file].ps
    set pdfOut [file rootname $file].pdf
    variable dotPath
    catch { exec $dotPath/dot -Tps $file -o $psOut }
    exec ps2pdf13 $psOut $pdfOut
#     file delete $psOut
    exec open -a TeXShop $pdfOut
}


# dot::correctIndentation adapted from ::correctBracesIndentation,
# but detecting all braces, not just those at line end.  This is needed
# for typical 
# { rank = sink
#    N1 N2 N3
# }
# syntax...

proc dot::correctIndentation {args} {
    win::parseArgs w pos {next ""}
    set pos [lineStart -w $w $pos]
    if {[pos::compare -w $w $pos == [minPos -w $w]]} {
	return 0
    }
    
    global commentsArentSpecialWhenIndenting
    # Find last previous non-comment line and get its leading whitespace
    while 1 {
	if {[pos::compare -w $w $pos == [minPos -w $w]] \
	  || [catch {search -w $w -s -f 0 -r 1 -i 0 -m 0 \
	  "^\[ \t\]*\[^ \t\r\n\]" [pos::math -w $w $pos - 1]} lst]} {
	    # search failed at top of file
	    set line "#"
	    set lwhite 0
	    break
	}
	if {!$commentsArentSpecialWhenIndenting && \
	  [text::isInDoubleComment -w $w [lindex $lst 0] res]} {
	    set pos [lindex $res 0]
	} else {
	    set line [getText -w $w [lindex $lst 0] \
	      [pos::math -w $w [nextLineStart -w $w [lindex $lst 0]] - 1]]
	    set lwhite [lindex [pos::toRowCol -w $w \
	      [pos::math -w $w [lindex $lst 1] - 1]] 1]
	    break
	}
    }
    
    set ia [text::getIndentationAmount -w $w]
    if { [regexp -- {^[^\}]*\{[^\}]*$} $line] } {
	incr lwhite $ia
    }
    set text [getText -w $w [lineStart -w $w $pos] $pos]
    append text $next
    if { [regexp -- {^[^\{]*\}[^\{]*$} $text] } {
	incr lwhite [expr {-$ia}]
    }
    return $lwhite
}
