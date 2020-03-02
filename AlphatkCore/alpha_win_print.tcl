# ×××× Printing ×××× #

proc PdfPageSetup {} {
    if {[catch {
	package require pdf4tcl
	package require pdftext
    }]} {
	alertnote "Printing requires the pdf4tcl and pdftext\
	  extensions to Tcl."
	return
    }
    alertnote "Pdf printing has been set up successfully"
}

proc PdfPrint {{win ""}} {
    if {[catch {
	package require pdf4tcl
	package require pdftext
    }]} {
	alertnote "Printing requires the pdf4tcl and pdftext\
	  extensions to Tcl."
	return
    }
    if {$win eq ""} { set win [win::Current] }
    if {![win::Exists $win]} {
	alertnote "Can't print '$win' - it isn't open"
    }
    set filename "[file root $win].pdf"
    set filename [putfile "Save to..." $filename]
    global win::tk
    set widget $win::tk($win)
    pdftext::convert $widget $filename
}

proc winGdiPageSetup {} {
    if {[catch {
	package require gdi
	package require printer
    }]} {
	alertnote "Printing requires the gdi and printer\
	  extensions to Tcl."
	return
    }
    set hDC [lindex [lindex [printer attr -get hDC] 0] 1]
    if {$hDC == ""} {
	printer open
	set hDC [lindex [lindex [printer attr -get hDC] 0] 1]
    }
    printer dialog -hDC $hDC page_setup
}

proc winGdiPrint {f} {
    global printerFont printerFontSize
    if {[catch {
	package require gdi
	package require printer
    }]} {
	alertnote "Printing requires the gdi and printer\
	  extensions to Tcl."
	return
    }
    #printer attr -set [list [list "first page" 1]
    # [list "last page" end]]
    foreach {hDC ok} [printer dialog select] {break}
    if {!$ok} { status::msg "Cancelled" ; return }
    
    set ::printargs(name) $f
    
    if {$printerFont != ""} {
	set font [list $printerFont $printerFontSize]
    } else {
	set font ""
    }
    if {[catch {
	printer attr -hDC $hDC -get [list "print flag"]
    } what]} {
	set what "all"
    } else {
	set what [lindex [lindex $what 0] 1]
    }

    # Get the data:
    switch -- $what {
	"selection" {
	    set data [getSelect]
	}
	"all" -
	default {
	    set data [getText -w $f [minPos] [maxPos -w $f]] 
	}
    }
    set sp [spacesEqualTab -w $f]
    while {[regsub -all "(^|\n|\r)(($sp)*) *\t" \
      $data "\\1\\2$sp" data]} {}
    
    set wrap [expr {[text_wcmd $f cget -wrap] != "none"}]
    print_data $data $wrap $font
}

################################################################
# A set of procs to print text to a printer using
# the GDI and PRINTER extensions.
# Actually, it would be nice to add one to print HTML....
# These procs require version 0.9.1.1 or newer of GDI and
# 0.7.0.1 or newer of printer extension.
#
# $Log: alpha_win_print.tcl,v $
# Revision 1.1  2006/03/28 22:35:50  vincentdarley
# First Alphatk
#
# Revision 1.2  2006/03/25 23:27:43  darley
# improved status bar
#
# Revision 1.2  1998/04/27  01:35:37  Michael_Schwartz
# Provide documentary comments and package require statements
#
# Vince Darley made code print better with tabs/spaces etc, long
# lines and the like.  Some preliminary code in there to print
# with styled text (comments, keywords etc in slightly different
# fonts); not functional yet though.
################################################################

################################################################
## page_args
## Description:
##   This is a helper proc used to parse common arguments for
##   text processing in the other commands.
## Args:
##   Name of an array in which to store the various pieces 
##   needed for text processing
################################################################
proc page_args { array } {
    if {[catch {
	package require gdi
	package require printer
    }]} {
	alertnote "Printing requires the gdi and printer extensions to Tcl."
	return
    }
    upvar #0 $array ary
    
    # First we check whether we have a valid hDC
    # (perhaps we can later make this also an optional argument, defaulting to 
    #  the default printer)
    set attr [ printer attr ]
    foreach attrpair $attr {
	set key [lindex $attrpair 0]
	set val [lindex $attrpair 1]
	switch -exact $key {
	    "hDC"       { set ary(hDC) $val }
	    "copies"    { if { $val >= 0 } { set ary(copies) $val } }
	    "page dimensions" {
		set wid [lindex $val 0]
		set hgt [lindex $val 1]
		if { $wid > 0 } { set ary(pw) $wid }
		if { $hgt > 0 } { set ary(pl) $hgt }
	    }
	    "page margins"    {
		if { [scan [lindex $val 0] %d tmp] > 0 } {
		    set ary(lm) [ lindex $val 0 ]
		    set ary(tm) [ lindex $val 1 ]
		    set ary(rm) [ lindex $val 2 ]
		    set ary(bm) [ lindex $val 3 ]
		}
	    }
	    "resolution"      {
		if { [scan [lindex $val 0] %d tmp] > 0 } {
		    set ary(resx) [ lindex $val 0 ]
		    set ary(resy) [ lindex $val 1 ]
		} else {
		    set ary(resx) 300
		    set ary(resy) 300
		}
	    }
	}
    }
}

################################################################
## print_page_data
## Description:
##   This is the simplest way to print a small amount of text
##   on a page. The text is formatted in a box the size of the
##   selected page and margins.
## Args:
##   data         Text data for printing
##   fontargs     Optional arguments to supply to the text command
################################################################
proc print_page_data { data {fontargs {}} } {
    
    global printargs
    page_args printargs
    if { ! [info exist printargs(hDC)] || ($printargs(hDC) == "0x0")} {
	printer open
	page_args printargs
    }
    
    set tm [ expr {$printargs(tm) * $printargs(resy) / 1000}]
    set lm [ expr {$printargs(lm) * $printargs(resx) / 1000}]
    set pw [ expr {( $printargs(pw) - $printargs(lm) - $printargs(rm) ) \
      / 1000 * $printargs(resx)}]
    printer job start
    eval gdi text $printargs(hDC) $lm $tm \
      -anchor nw -text [list $data] \
      -width $pw \
      $fontargs
    printer job end
}

################################################################
## print_page_file
## Description:
##   This is the simplest way to print a small file
##   on a page. The text is formatted in a box the size of the
##   selected page and margins.
## Args:
##   data         Text data for printing
##   fontargs     Optional arguments to supply to the text command
################################################################
proc print_page_file { filename {fontargs {}} } {
    set fn [open $filename r]
    
    set data [ read $fn ]
    
    close $fn
    
    print_page_data $data $fontargs
}

################################################################
## print_data
## Description:
##   This function prints multiple-page files, using a line-oriented
##   function, taking advantage of knowing the character widths.
##   Many fancier things could be done with it:
##     e.g. page titles, page numbering, user-provided boundary to override
##          page margins, HTML-tag interpretation, etc.
## Args: 
##	data	  Text data for printing
##      breaklines If non-zero, keep newlines in the string as
##                 newlines in the output.
##      font      Font for printing
################################################################
proc print_data { data {breaklines 1 } {font {}} } {
    global printargs
    page_args printargs
    if { ! [info exist printargs(hDC)] || ($printargs(hDC) == "0x0") || ($printargs(hDC) == "?")} {
	printer open
	page_args printargs
    }
    
    if { [string length $font] == 0 } {
	eval gdi characters $printargs(hDC) -array printcharwid
    } else {
	eval gdi characters $printargs(hDC) -font $font -array printcharwid
    }
    
    set pagewid  [expr {($printargs(pw) - $printargs(lm) - $printargs(rm) ) / 1000 * $printargs(resx)}]
    set pagehgt  [expr {($printargs(pl) - $printargs(bm) ) / 1000 * $printargs(resy)}]
    
    set totallen [string length $data]
    set curlen 0
    set curhgt [expr {$printargs(tm) * $printargs(resy) / 1000}]
    
    printer job start
    printer page start
    set page 1
    print_header printargs $page $font
    
    while { $curlen < $totallen } {
	set linestring [string range $data $curlen end]
	set endind [string first "\n" $linestring]
	if { $endind != -1 } {
	    set linestring [string range $linestring 0 $endind] 
	} 
	
	set result [print_page_nextline $linestring $breaklines \
	  printcharwid printargs $curhgt $font]
	incr curlen [lindex $result 0]
	incr curhgt [lindex $result 1]
	if { [expr {$curhgt + [lindex $result 1]}] > $pagehgt } {
	    printer page end
	    printer page start
	    incr page
	    print_header printargs $page $font
	    set curhgt [expr {$printargs(tm) * $printargs(resy) / 1000}]
	}
    }
    printer page end
    printer job end
    status::msg "$page page[expr {$page > 1 ? "s" : ""}] printed"
}

proc print_header { parray page {font {}} } {
    upvar #0 $parray printargs
    set leftheader [printLeftHeader $page $printargs(name)]
    set rightheader [printRightHeader $page $printargs(name)]
    set maxwidth [ expr {( $printargs(pw) - $printargs(lm) - $printargs(rm) ) / 1000 * $printargs(resx)}]
    
    if { [string length $font] > 0 } {
	gdi text $printargs(hDC) 10 10 \
	  -anchor nw -justify left \
	  -text $leftheader \
	  -font "$font bold"
	gdi text $printargs(hDC) [expr {$maxwidth - 10}] 10 \
	  -anchor nw -justify right \
	  -text $rightheader \
	  -font "$font bold"
    } else {
	gdi text $printargs(hDC) 10 10 \
	  -anchor nw -justify left \
	  -text $leftheader
	gdi text $printargs(hDC) [expr {$maxwidth - 10}] 10 \
	  -anchor nw -justify right \
	  -text $rightheader
    }
}

################################################################
## print_file
## Description:
##   This function prints multiple-page files
##   It will either break lines or just let them run over the 
##   margins (and thus truncate).
##   The font argument is JUST the font name, not any additional
##   arguments.
## Args:
##   filename     File to open for printing
##   breaklines   1 to break lines as done on input, 0 to ignore newlines
##   font         Optional arguments to supply to the text command
################################################################
proc print_file { filename {breaklines 1 } { font {}} } {
    if {[catch {
	package require gdi
	package require printer
    }]} {
	alertnote "Printing requires the gdi and printer extensions to Tcl."
	return
    }

    if {[lsearch -exact [winNames -f] $filename] != -1} {
	set data [getText -w $filename [minPos] [maxPos -w $filename]]
	set sp [spacesEqualTab -w $filename]
    } else {
	set fn [open $filename r]
	fconfigure $fn -translation auto
	set data [read $fn]
	close $fn
	# Assume 8 spaces to a tab!
	set sp "        "
    }
    
    while {[regsub -all "(^|\n|\r)(($sp)*) *\t" $data "\\1\\2$sp" data]} {}
    global printargs
    set printargs(name) $filename
    
    print_data $data $breaklines $font
}

################################################################
## print_page_nextline
##
## Args:
##   string           Data to print
##   parray           Array of values for printer characteristics
##   carray           Array of values for character widths
##   y                Y value to begin printing at
##   font             if non-empty specifies a font to draw the line in
## Return:
##   Returns the pair "chars y"
##   where chars is the number of characters printed on the line
##   and y is the height of the line printed
################################################################
proc print_page_nextline { string breaklines carray parray y font } {
    upvar #0 $carray charwidths
    upvar #0 $parray printargs
    
    set endindex 0
    set totwidth 0
    set maxwidth [expr {($printargs(pw) - $printargs(lm) - $printargs(rm) ) / 1000 * $printargs(resx)}]
    set maxstring [string length $string ]
    set lm [expr {$printargs(lm) * $printargs(resx) / 1000}]
    if {$breaklines} {
	for { set i 0 } { $i < $maxstring && $totwidth < $maxwidth } { incr i } {
	    incr totwidth $charwidths([string index $string $i])
	    # set width($i) $totwidth
	}
	set endindex $i
	
	if { $i < $maxstring } {
	    # In this case, the whole data string is not used up, and we wish to break on a 
	    # word. Since we have all the partial widths calculated, this should be easy.
	    set endindex [ expr {[string wordstart $string $endindex] - 1}]
	    # set endindex [string wordstart $string $endindex]
	}
	set string [string range $string 0 $endindex]
    } else {
	set endindex $maxstring
    }
    
    set print [string trim $string "\r\n"]
    if {![string length $print]} { set print " " }
    
    if { [string length $font] > 0 } {
	set result [ gdi text $printargs(hDC) $lm $y \
	  -anchor nw -justify left \
	  -text $print -font $font]
    } else {
	set result [ gdi text $printargs(hDC) $lm $y \
	  -anchor nw -justify left \
	  -text $print]
    }
    
    #echo "Printed line [string trim [string range $string 0 $endindex ] "\r\n" ] at ($lm,$y)"
    return "$endindex $result"
}

