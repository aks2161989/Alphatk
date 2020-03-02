# library of tcl procedures for generating portable document format files
# this is a port of pdf4php from php to tcl

# Copyright (c) 2004 by Frank Richter <frichter@truckle.in-chemnitz.de> and
# Jens Pšnisch <jens@ruessel.in-chemnitz.de>

# See the file "licence.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

# Version 0.1	base features for generating correct pdf files
# Version 0.2	more graphic operators, fixed font handling

package provide pdf4tcl 0.2

package require pdf4tcl::metrics
package require pdf4tcl::glyphnames

namespace eval pdf4tcl {
	# helper variables (constants) packaged into arrays to minimize
	# variable import statements
	variable g
	variable font_widths
	variable glyph_names
	variable font_afm
	variable paper_sizes

	# state variable, indexed by user supplied name
	variable pdf

	# path to adobe afm files
	set g(ADOBE_AFM_PATH) {}
	# change this to reflect your machines install!
	set g(ADOBE_AFM_PATH) {/usr/share/texmf/fonts/afm/adobe/*}

	# font width array
	array set font_widths {}
	
	# font name to afm file mapping array
	array set font_afm {}

	# known papersizes
	array set paper_sizes {
		a0 {2380 3368}
		a1 {1684 2380}
		a2 {1190 1684}
		a3 {842 1190}
		a4 {595 842}
		a5 {421 595}
		a6 {297 421}
		11x17 {792 1224}
		ledger {1224 792}
		legal {612 1008}
		letter {612 792}
	}

	# state variable
	array set pdf {}

	if [catch {package require zlib} err] {
		set g(haveZlib) 0
	} else {
		set g(haveZlib) 1
	}

	proc Init {} {
		loadAfmMapping
	}

	proc loadAfmMapping {} {
		variable font_afm
		variable g

		foreach path $g(ADOBE_AFM_PATH) {
			foreach file [glob -nocomplain [file join $path "*.afm"]] {
				set if [open $file "r"]
				while {[gets $if line]!=-1} {
					if {[regexp {^FontName\s*(.*)$} $line dummy fontname]} {
						close $if
						set font_afm($fontname) $file
						break
					}
				}
			}
		}
	}

	proc getPaperSize {papername} {
		variable paper_sizes

		if {[info exists paper_sizes($papername)]} {
			return $paper_sizes($papername)
		} else {
			return {}
		}
	}

	# PDF-Struktur:
	# 1 = Root
	#     2 = Pages
	#     3 = Resources
	#     4 = First page
	#             .
	#             .
	#             .
	#     X = Fonts

	proc new {name args} {
		variable pdf
		variable g
		
		if {[info exists pdf($name)]} {
			return -code error "pdf $name already exists"
		}

		set pdf($name) $name
		set pdf($name,xpos) 0
		set pdf($name,width) 0
		set pdf($name,ypos) 0
		set pdf($name,height) 0
		set pdf($name,orient) 1
		set pdf($name,pages) 0
		set pdf($name,pdf_obj) 4
		set pdf($name,font_size) 8
		set pdf($name,out_pos) 0
#		set pdf($name,xref,0) 0
		set pdf($name,data_start) 0
		set pdf($name,data_len) 0
		set pdf($name,fonts) {}
		set pdf($name,current_font) ""
		set pdf($name,font_set) false
		set pdf($name,in_text_object) false
		set pdf($name,images) {}
		set pdf($name,compress) 0
		set pdf($name,finished) false
		set pdf($name,inPage) false

		# output buffer (we need to compress whole pages)
		set pdf($name,ob) ""

		# collect output in memory
		set pdf($name,pdf) ""

		# Offsets
		set pdf($name,xoff) 0
		set pdf($name,yoff) 0

		# we use a4 paper by default
		set pdf($name,paperwidth) 595
		set pdf($name,paperheight) 842

		foreach {arg value} $args {
			switch -- $arg {
				"-paper" {
					set papersize [getPaperSize $value]
					if {[llength $papersize]==0} {
						cleanup $name
						return -code error "papersize $value is unknown"
					}
					set pdf($name,paperwidth) [lindex $papersize 0]
					set pdf($name,paperheight) [lindex $papersize 1]
				}
				"-compress" {
					if {$value} {
						if {$g(haveZlib)} {
							set pdf($name,compress) 1
						} else {
							puts stderr "Package zlib not available. Sorry, no compression."
						}
					} else {
						set pdf($name,compress) 0
					}
				}
				default {
					cleanup $name
					return -code error \
						"unknown option $arg"
				}
			}
		}

		pdfout $name "%PDF-1.3\n"

		# start with Helvetica as default font
		set pdf($name,font_size) 12
		set pdf($name,current_font) "Helvetica"

		set proccmd {proc ::%name {args} {set subcmd [lindex $args 0]; set otherargs [lrange $args 1 end]; eval "pdf4tcl::$subcmd %name $otherargs"}}
		regsub -all {%name} $proccmd "$name" proccmd
		eval $proccmd
	}

	proc pdfout {name out} {
		variable pdf

		append pdf($name,ob) $out
		incr pdf($name,out_pos) [string length $out]
	}

	proc startPage {name args} {
		variable pdf
		set orient 1
		switch [llength $args] {
			0 {
				set width $pdf($name,paperwidth)
				set height $pdf($name,paperheight)
			}
			1 {
				set papersize [getPaperSize [lindex $args 0]]
				if {[llength $papersize]==0} {
					return -code error "papersize $value is unknown"
				}
				set width [lindex $papersize 0]
				set height [lindex $papersize 1]
			}
			2 {
				set width [lindex $args 0]
				set height [lindex $args 1]
			}
			3 {
				set width [lindex $args 0]
				set height [lindex $args 1]
				set orient [lindex $args 2]
			}
		}

		if {$pdf($name,inPage)} {
			endPage $name
		}
		set pdf($name,inPage) 1
		set pdf($name,ypos) $height
		set pdf($name,width) $width
		set pdf($name,height) $height
		set pdf($name,orient) $orient
		set pdf($name,xpos) 0
		incr pdf($name,pages)

		# dimensions
		set oid [get_oid $name]
		store_xref $name
		pdfout $name "$oid 0 obj\n"
		pdfout $name "<</Type /Page\n"
		pdfout $name "/Parent 2 0 R\n"
		pdfout $name "/Resources 3 0 R\n"
		pdfout $name [format "/MediaBox \[0 0 %g %g\]\n" $width $height]
		pdfout $name "/Contents \[[next_oid $name] 0 R \]\n"
		pdfout $name ">>\n"
		pdfout $name "endobj\n\n"

		# start of contents
		set oid [incr_oid $name]
		store_xref $name
		pdfout $name "$oid 0 obj\n"
		pdfout $name "<<\n/Length [next_oid $name] 0 R\n"
		if {$pdf($name,compress)} {
			pdfout $name "/Filter \[/FlateDecode\]\n"
		}
		pdfout $name ">>\nstream\n"
		set pdf($name,data_start) $pdf($name,out_pos)
		set pdf($name,in_text_object) false
		incr_oid $name

		# no font set on new pages
		set pdf($name,font_set) false

		# capture output
		append pdf($name,pdf) $pdf($name,ob)
		set pdf($name,ob) ""
	}

	proc endPage {name} {
		variable pdf

		if {! $pdf($name,inPage)} {
			return
		}
		if {$pdf($name,in_text_object)} {
			pdfout $name "\nET\n"
		}
		# get buffer
		set data $pdf($name,ob)
		set pdf($name,ob) ""
		if {$pdf($name,compress) >0} {
			set data [zlib compress $data]
		}
		append pdf($name,pdf) $data
		set data_len [string length $data]
		set pdf($name,out_pos) [expr {$pdf($name,data_start)+$data_len}]
		pdfout $name "\nendstream\n"
		pdfout $name "endobj\n\n"
		store_xref $name
		pdfout $name "[get_oid $name] 0 obj\n"
		incr data_len
		pdfout $name "$data_len\n"
		pdfout $name "endobj\n\n"
		incr_oid $name
		set pdf($name,inPage) false
	}

	proc finish {name} {
		variable pdf

		if {$pdf($name,finished)} {
			return
		}

		if {$pdf($name,inPage)} {
			endPage $name
		}
		set pdf($name,xref,1) $pdf($name,out_pos)
		pdfout $name "1 0 obj\n"
		pdfout $name "<<\n"
		pdfout $name "/Type /Catalog\n"
		pdfout $name "/Pages 2 0 R\n"
		pdfout $name ">>\n"
		pdfout $name "endobj\n\n"

		set pdf($name,xref,2) $pdf($name,out_pos)
		pdfout $name "2 0 obj\n"
		pdfout $name "<<\n/Type /Pages\n"
		pdfout $name "/Count $pdf($name,pages)\n"
		pdfout $name "/Kids \["
		for {set a 0} {$a<$pdf($name,pages)} {incr a} {
			set b [expr {4 + $a*3}]
			pdfout $name "$b 0 R "
		}
		pdfout $name "\]\n"
		pdfout $name ">>\n"
		pdfout $name "endobj\n\n"

		set pdf($name,xref,3) $pdf($name,out_pos)
		pdfout $name "3 0 obj\n"
		pdfout $name "<<\n"
		pdfout $name "/ProcSet\[/PDF /Text /ImageC\]\n"
		pdfout $name "/Font <<\n"

		# font references
		set count 0
		foreach fontname $pdf($name,fonts) {
			set nr [expr {$pdf($name,pdf_obj)+$count}]
			pdfout $name "/$fontname $nr 0 R\n"
			incr count
		}
		pdfout $name ">>\n"

		# image references
		if {[llength $pdf($name,images)]>0} {
			pdfout $name "/XObject <<\n"
			foreach {key value} $pdf($name,images) {
				set nr [expr {$pdf($name,pdf_obj)+$count}]
				pdfout $name "/$key $nr 0 R\n"
				incr count
			}
			pdfout $name ">>\n"
		}
		pdfout $name ">>\nendobj\n\n"

		# fonts
		foreach fontname $pdf($name,fonts) {
			store_xref $name
			pdfout $name "[get_oid $name] 0 obj\n"
			pdfout $name "<<\n/Type /Font\n"
			pdfout $name "/Subtype /Type1\n"
			pdfout $name "/Encoding /WinAnsiEncoding\n"
			pdfout $name "/Name /$fontname\n"
			pdfout $name "/BaseFont /$fontname\n"
			pdfout $name ">>\n"
			pdfout $name "endobj\n\n"
			incr_oid $name
		}

		# images
		foreach {key value} $pdf($name,images) {
			store_xref $name
			foreach {img_width img_height img_depth img_length img_data} $value {break}
			pdfout $name "[get_oid $name] 0 obj\n"
			pdfout $name "<<\n/Type /XObject\n"
			pdfout $name "/Subtype /Image\n"
			pdfout $name "/Width $img_width\n/Height $img_height\n"
			pdfout $name "/ColorSpace /DeviceRGB\n"
			pdfout $name "/BitsPerComponent $img_depth\n"
			pdfout $name "/Filter /DCTDecode\n"
			pdfout $name "/Length $img_length >>\n"
			pdfout $name "stream\n"
			pdfout $name $img_data
			pdfout $name "\nendstream\n"
			pdfout $name "endobj\n\n"
			incr_oid $name
		}

		# cross reference
		set xref_pos $pdf($name,out_pos)
		pdfout $name "xref\n"
		store_xref $name
		pdfout $name "0 [get_oid $name]\n"
		pdfout $name "0000000000 65535 f \n"
		for {set a 1} {$a<[get_oid $name]} {incr a} {
			set xref $pdf($name,xref,$a)
			pdfout $name [format "%010ld 00000 n \n" $xref]
		}
		pdfout $name "trailer\n"
		pdfout $name "<<\n"
		pdfout $name "/Size [get_oid $name]\n"
		pdfout $name "/Root 1 0 R\n"
		pdfout $name ">>\n"
		pdfout $name "\nstartxref\n"
		pdfout $name "$xref_pos\n"
		pdfout $name "%%EOF\n"
		append pdf($name,pdf) $pdf($name,ob)
		set pdf($name,ob) ""
		set pdf($name,finished) true
	}

	proc get {name} {
		variable pdf

		if {$pdf($name,inPage)} {
			endPage $name
		}
		if {! $pdf($name,finished)} {
			finish $name
		}
		return $pdf($name,pdf)
	}

	proc write {name args} {
		variable pdf

		set chan stdout
		set outfile 0
		foreach {arg value} $args {
			switch -- $arg {
				"-file" {
					if [catch {open $value "w"} chan] {
						return -code error "Could not open file $value for writing: $chan"
					} else {
						set outfile 1
					}
				}
				default {
					return -code error "unknown option $arg."
				}
			}
		}

		fconfigure $chan -translation binary
		puts -nonewline $chan [get $name]
		if {$outfile} {
			close $chan
		}
		return
	}

	proc cleanup {name} {
		variable pdf

		foreach key [array names pdf "$name,*"] {
			unset pdf($key)
		}
		unset pdf($name)
		proc ::$name {} {}
		return
	}

	proc setFont {name size {fontname ""}} {
		variable pdf
		variable font_widths
		
		if {[string length $fontname]==0} {
			set fontname $pdf($name,current_font)
		}
		# font width already loaded?
		if {! [info exists font_widths($fontname)]} {
			if [catch {loadFontMetrics $fontname} tmp] {
				return -code error "Could not load font metrics for $fontname"
			} else {
				set font_widths($fontname) $tmp
			}
		}
		set pdf($name,font_size) $size
		pdfout $name "/$fontname $size Tf\n"
		pdfout $name "0 Tr\n"
		pdfout $name "$size TL\n"
		if {[lsearch $pdf($name,fonts) $fontname]==-1} {
			lappend pdf($name,fonts) $fontname
		}
		set pdf($name,current_font) $fontname

		set pdf($name,font_set) true
	}

	proc loadFontMetrics {font} {
		variable font_afm
		variable g

		set file $font_afm($font)
		if [catch {open $file "r"} if] {
			return ""
		} else {
			set started false
			array set widths {}
			while {[gets $if line]!=-1} {
				if {! $started} {
					if {[string first "StartCharMetrics" $line]==0} {
						set started true
					}
				} else {
					# Done?
					if {[string first "EndCharMetrics" $line]==0} {
						break
					}
					if {[string index $line 0]=="C"} {
						scan [string range $line 1 4] "%d" ch
						if {($ch>0) && ($ch<256)} {
							set pos [string first "WX" $line]
							incr pos 2
							set endpos $pos
							incr endpos 4
							scan [string range $line $pos $endpos] "%d" w
							set char [format "%c" $ch]
							set widths($char) $w
						}
					}
				}
			}
			close $if
			return [array get widths]
		}
	}

	proc getStringWidth {name txt} {
		variable pdf
		variable font_widths

		set w 0
		for {set i 0} {$i<[string length $txt]} {incr i} {
			set ch [string index $txt $i]
			set w [expr {$w + [getCharWidth $name $ch]}]
		}
		return $w
	}

	proc getCharWidth {name ch} {
		variable pdf
		variable font_widths
		variable glyph_names

		if {$ch=="\n"} {
			return 0
		}

		set afm2point [expr {0.001 * $pdf($name,font_size)}]
		if {[scan $ch %c n]!=1} {
			return 0
		}
		set ucs2 [format "%04.4X" $n]

		array set widths $font_widths($pdf($name,current_font))
		set glyph_name zero
		set w 0
		catch {set w $widths("zero")}
		catch {set glyph_name $glyph_names($ucs2)}
		switch -- $glyph_name {
			"spacehackarabic" {set glyph_name "space"}
		}
		catch {set w $widths($glyph_name)}
###		puts stderr "ch: $ch  n: $n  ucs2: $ucs2  glyphname: $glyph_name  width: $w"
		return [expr {$w*$afm2point}]
	}

	proc setTextPosition {name x y} {
		variable pdf
		variable g

		beginTextObj $name
		set pdf($name,xpos) [expr {$x + $pdf($name,xoff)}]
		if {$pdf($name,orient)} {
		  set pdf($name,ypos) [expr {$pdf($name,height) - $y - \
			$pdf($name,yoff)}]
		} else {
		  set pdf($name,ypos) [expr {$y + $pdf($name,yoff)}]
		}
		pdfout $name [format "1 0 0 1 %s %s Tm\n" \
			[nf $pdf($name,xpos)] [nf $pdf($name,ypos)]]
	}

	# draw text at current position with angle ang
	proc drawText {name str {ang 0}} {
		variable pdf

		beginTextObj $name
		if {! $pdf($name,font_set)} {
#			SetBaseFont $name $pdf($name,current_font)
			setFont $name $pdf($name,font_size) $pdf($name,current_font)
		}
		pdfout $name "([cleanText $str]) '\n"
		set pdf($name,ypos) [expr {$pdf($name,ypos) + \
			$pdf($name,font_size)}]
	}

	proc drawTextAt {name x y str args} {
		variable pdf
		variable g

		set align "left"
		set angle 0
		foreach {arg value} $args {
			switch -- $arg {
				"-align" {
					set align $value
				}
				"-angle" {
					set angle $value
				}
				default {
					return -code error \
						"unknown option $arg"
				}
			}
		}

		beginTextObj $name

		if {! $pdf($name,font_set)} {
			setFont $name $pdf($name,font_size)
		}

		if {$align == "right"} {
			set x [expr $x - [getStringWidth $name $str]]
		} elseif {$align == "center"} {
			set x [expr $x - [getStringWidth $name $str] / 2 * cos($angle*3.1415926/180.0)]
			set y [expr $y - [getStringWidth $name $str] / 2 * sin($angle*3.1415926/180.0)]
		}
		if {$angle != 0} {
			set pdf($name,xpos) [expr $x + $pdf($name,xoff)]
			if {$pdf($name,orient)} {
			  set pdf($name,ypos) [expr $pdf($name,height) - $y - $pdf($name,yoff)]
			} else {
			  set pdf($name,ypos) [expr {$y + $pdf($name,yoff)}]
			}
			rotateText $name $angle
		} else {
			setTextPosition $name $x $y
		}
		pdfout $name "([cleanText $str]) Tj\n"
	}

	proc drawTextBox {name x y width height txt args} {
		variable pdf
		variable g

		foreach {arg value} $args {
			switch -- $arg {
				"-align" {
					set align $value
				}
				default {
					return -code error \
						"unknown option $arg"
				}
			}
		}

		beginTextObj $name

		# pre-calculate some values
		set font_height $pdf($name,font_size)
		set space_width [getCharWidth $name " "]
		set ystart $y
		if {!$pdf($name,orient)} {
		  set y [expr {$y+$height-3*$font_height/2}]
		}
		set len [string length $txt]

		# run through chars until we exceed width or reach end
		set start 0
		set pos 0
		set cwidth 0
		set lastbp 0
		set done false

		while {! $done} {
			set ch [string index $txt $pos]
			# test for breakable character
			if {[regexp "\[ \t\r\n-\]" $ch]} {
				set lastbp $pos
			}
			set w [getCharWidth $name $ch]
			if {($cwidth+$w)>$width || $pos>=$len || $ch=="\n"} {
				if {$pos>=$len} {
					set done true
				} else {
					# backtrack to last breakpoint
					set pos $lastbp
				}
				set sent [string trim [string range $txt $start $pos]]
				switch -- $align {
					"justify" {
						# count number of spaces
						set words [split $sent " "]
						if {[llength $words]>1 && (!$done) && $ch!="\n"} {
							# determine additional width per space
							set sw [getStringWidth $name $sent]
							set add [expr {($width-$sw)/([llength $words]-1)}]
							# display words
							set xx $x
							for {set i 0} {$i<[llength $words]} {incr i} {
								drawTextAt $name $xx $y [lindex $words $i]
								set xx [expr {$xx+[getStringWidth $name [lindex $words $i]]+$space_width+$add}]
							}
						} else {
							drawTextAt $name $x $y $sent
						}
					}
					"right" {
						drawTextAt $name [expr {$x+$width}] $y $sent -align right
					}
					"center" {
						drawTextAt $name [expr {$x+$width/2.0}] $y $sent -align center
					}
					default {
						drawTextAt $name $x $y $sent
					}
				}
				if {$pdf($name,orient)} {
				  set y [expr {$y+$font_height}]
				} else {
				  set y [expr {$y-$font_height}]
				}
				# too big?
				if {($y+$font_height-$ystart)>=$height} {
					return [string range $txt $pos end]
				}
				set start $pos
				incr start
				set cwidth 0
				set lastbp 0
			} else {
				set cwidth [expr {$cwidth+$w}]
			}
			incr pos
		}
		return ""
	}

###<jpo 2004-11-08: replaced "on off" by "args"
###                 to enable resetting dashed lines
	proc setLineStyle {name width args} {
		variable pdf

		endTextObj $name
		pdfout $name "$width w\n"
		pdfout $name "\[$args\] 0 d\n"
	}

	proc line {name x1 y1 x2 y2} {
		variable pdf
		variable g

		endTextObj $name
		if {$pdf($name,orient)} {
		  set y1 [expr {$pdf($name,height)-$y1}]
		  set y2 [expr {$pdf($name,height)-$y2}]
		}
		pdfout $name [format "%g %g m\n" [nf [expr {$x1+$pdf($name,xoff)}]] [nf [expr {$y1+$pdf($name,yoff)}]]]
		pdfout $name [format "%g %g l\n" [nf [expr {$x2+$pdf($name,xoff)}]] [nf [expr {$y2+$pdf($name,yoff)}]]]
		pdfout $name "S\n"
	}

###>2004-11-03 jpo
	proc qCurve {name x1 y1 xc yc x2 y2} {
		variable pdf
		variable g

		endTextObj $name
		if {$pdf($name,orient)} {
		  set y1 [expr {$pdf($name,height)-$y1}]
		  set y2 [expr {$pdf($name,height)-$y2}]
		  set yc [expr {$pdf($name,height)-$yc}]
		}
		pdfout $name [format "%g %g m\n" [nf [expr {$x1+$pdf($name,xoff)}]] [nf [expr {$y1+$pdf($name,yoff)}]]]
		pdfout $name [format "%g %g %g %g %g %g c\n" \
		  [nf [expr {0.3333*$x1+0.6667*$xc+$pdf($name,xoff)}]] \
		  [nf [expr {0.3333*$y1+0.6667*$yc+$pdf($name,yoff)}]] \
		  [nf [expr {0.3333*$x2+0.6667*$xc+$pdf($name,xoff)}]] \
		  [nf [expr {0.3333*$y2+0.6667*$yc+$pdf($name,yoff)}]] \
		  [nf [expr {$x2+$pdf($name,xoff)}]] \
		  [nf [expr {$y2+$pdf($name,yoff)}]] \
		]
		pdfout $name "S\n"
	}
###<jpo

###>2004-11-07 jpo
	# polygon name isFilled x0 y0 x1 y1 ...
	proc polygon {name isFilled args} {
	  variable pdf
	  variable g

	  endTextObj $name
	  if {$isFilled} {set op "b"} else {set op "s"}
	  set start 1
	  foreach {x y} $args {
	    if {$pdf($name,orient)} {
	      set y [expr {$pdf($name,height)-$y}]
	    }
	    if {$start} {
	      pdfout $name [format "%g %g m\n" \
		[nf [expr {$x+$pdf($name,xoff)}]] \
		[nf [expr {$y+$pdf($name,yoff)}]]]
	      set start 0
	    } else {
	      pdfout $name [format "%g %g l\n" \
		[nf [expr {$x+$pdf($name,xoff)}]] \
		[nf [expr {$y+$pdf($name,yoff)}]]]
	    }
	  }
	  pdfout $name " $op\n"
	}

	proc circle {name isFilled x y r} {
	  variable pdf
	  variable g

	  endTextObj $name
	  if {$isFilled} {set op "b"} else {set op "s"}
	  if {$pdf($name,orient)} {
	    set y [expr {$pdf($name,height)-$y}]
	  }
	  set sq [expr {4.0*(sqrt(2.0)-1.0)/3.0}]
	  set x0(0) [expr {$x+$r}]
	  set y0(0) $y
	  set x1(0) [expr {$x+$r}]
	  set y1(0) [expr {$y+$r*$sq}]
	  set x2(0) [expr {$x+$r*$sq}]
	  set y2(0) [expr {$y+$r}]
	  set x3(0) $x
	  set y3(0) [expr {$y+$r}]
	  set x1(1) [expr {$x-$r*$sq}]
	  set y1(1) [expr {$y+$r}]
	  set x2(1) [expr {$x-$r}]
	  set y2(1) [expr {$y+$r*$sq}]
	  set x3(1) [expr {$x-$r}]
	  set y3(1) $y
	  set x1(2) [expr {$x-$r}]
	  set y1(2) [expr {$y-$r*$sq}]
	  set x2(2) [expr {$x-$r*$sq}]
	  set y2(2) [expr {$y-$r}]
	  set x3(2) $x
	  set y3(2) [expr {$y-$r}]
	  set x1(3) [expr {$x+$r*$sq}]
	  set y1(3) [expr {$y-$r}]
	  set x2(3) [expr {$x+$r}]
	  set y2(3) [expr {$y-$r*$sq}]
	  set x3(3) [expr {$x+$r}]
	  set y3(3) $y
	  pdfout $name [format "%g %g m\n" \
	    [nf [expr {$x0(0)+$pdf($name,xoff)}]] \
	    [nf [expr {$y0(0)+$pdf($name,yoff)}]]]
	  for {set i 0} {$i < 4} {incr i} {
	    pdfout $name [format "%g %g %g %g %g %g c\n" \
	      [nf [expr {$x1($i)+$pdf($name,xoff)}]] \
	      [nf [expr {$y1($i)+$pdf($name,yoff)}]] \
	      [nf [expr {$x2($i)+$pdf($name,xoff)}]] \
	      [nf [expr {$y2($i)+$pdf($name,yoff)}]] \
	      [nf [expr {$x3($i)+$pdf($name,xoff)}]] \
	      [nf [expr {$y3($i)+$pdf($name,yoff)}]]]
	  }
	  pdfout $name " $op\n"
	}

        # scale with r, rotate by phi, and move by (dx, dy)
	proc transform {r phi dx dy points} {
	  set cos_phi [expr {$r*cos($phi)}]
	  set sin_phi [expr {$r*sin($phi)}]
	  set res [list]
	  foreach {x y} $points {
	    set xn [expr {$x*$cos_phi - $y*$sin_phi + $dx}]
	    set yn [expr {$x*$sin_phi + $y*$cos_phi + $dy}]
	    lappend res $xn $yn
	  }
	  return $res
	}

	proc simplearc {phi2} {
	  set x0 [expr {cos($phi2)}]
	  set y0 [expr {-sin($phi2)}]
	  set x3 $x0
	  set y3 [expr {-$y0}]
	  set x1 [expr {0.3333*(4.0-$x0)}]
	  set y1 [expr {(1.0-$x0)*(3.0-$x0)/(3.0*$y0)}]
	  set x2 $x1
	  set y2 [expr {-$y1}]
	  return [list $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3]
	}

	proc arc {name x0 y0 r phi extend} {
	  variable pdf
	  variable g

	  if {abs($extend) >= 360.0} {
	    circle $name 0 $x0 $y0 $r
	    return
	  }
	  endTextObj $name
	  if {abs($extend) < 0.01} return
	  if {$pdf($name,orient)} {
	    set y0 [expr {$pdf($name,height)-$y0}]
	  }
	  set count 1
	  while {abs($extend) > 90} {
	    set count [expr {2*$count}]
	    set extend [expr {0.5*$extend}]
	  }
	  set phi [expr {$phi/180.0*3.1416}]
	  set extend [expr {$extend/180.0*3.1416}]
	  set phi2 [expr {0.5*$extend}]
	  set x [expr {$x0+$r*cos($phi)}]
	  set y [expr {$y0+$r*sin($phi)}]
	  pdfout $name [format "%g %g m\n" \
	    [nf [expr {$x+$pdf($name,xoff)}]] \
	    [nf [expr {$y+$pdf($name,yoff)}]]]
	  set points [simplearc $phi2]
	  set phi [expr {$phi+$phi2}]
	  for {set i 0} {$i < $count} {incr i} {
	    foreach {x y x1 y1 x2 y2 x3 y3} \
	      [transform $r $phi $x0 $y0 $points] break
	    set phi [expr {$phi+$extend}]
	    pdfout $name [format "%g %g %g %g %g %g c\n" \
	      [nf [expr {$x1+$pdf($name,xoff)}]] \
	      [nf [expr {$y1+$pdf($name,yoff)}]] \
	      [nf [expr {$x2+$pdf($name,xoff)}]] \
	      [nf [expr {$y2+$pdf($name,yoff)}]] \
	      [nf [expr {$x3+$pdf($name,xoff)}]] \
	      [nf [expr {$y3+$pdf($name,yoff)}]]]
	  }
	  pdfout $name " S\n"
	}
###<jpo

	proc arrow {name x1 y1 x2 y2 sz {angle 20}} {
		line $name $x1 $y1 $x2 $y2
		set rad [expr {$angle*3.1415926/180.0}]
		set ang [expr {atan2(($y1-$y2), ($x1-$x2))}]
		line $name $x2 $y2 [expr {$x2+$sz*cos($ang+$rad)}] [expr {$y2+$sz*sin($ang+$rad)}]
		line $name $x2 $y2 [expr {$x2+$sz*cos($ang-$rad)}] [expr {$y2+$sz*sin($ang-$rad)}]
	}

	proc setFillColor {name red green blue} {
		pdfout $name "$red $green $blue rg\n"
	}
	
	proc setStrokeColor {name red green blue} {
		pdfout $name "$red $green $blue RG\n"
	}

	proc rectangle {name x y w h args} {
		variable pdf
		variable g

		set filled 0
		foreach {arg value} $args {
			switch -- $arg {
				"-filled" {
					set filled 1
				}
				default {
					return -code error "unknown option $arg"
				}
			}
		}
		endTextObj $name
		if {$pdf($name,orient)} {
		  set y [expr {$pdf($name,height)-$y}]
		  set h [expr {0-$h}]
		}
		pdfout $name [format "%g %g $w $h re\n" [nf [expr {$x+$pdf($name,xoff)}]] [nf [expr {$y+$pdf($name,yoff)}]]]
		if {$filled} {
			pdfout $name "B\n"
		} else {
			pdfout $name "B\n"
		}
	}

	proc moveTo {name x1 y1} {
		variable pdf

		endTextObj $name
		set y1 [expr {$pdf($name,height)-$y1}]
		pdfout $name [format "%g %g m\n" [nf [expr {$x1+$pdf($name,xoff)}]] [[expr {$y1+$pdf($name,yoff)}]]]
	}

	proc closePath {name} {
		pdfout $name "b\n"
	}

	proc rotateText {name angle} {
		variable pdf
		variable g

		beginTextObj $name
		set rad [expr {$angle*3.1415926/180.0}]
		set c [nf [expr {cos($rad)}]]
		set s [nf [expr {sin($rad)}]]
		pdfout $name "$c [expr {0-$s}] $s $c $pdf($name,xpos) $pdf($name,ypos) Tm\n"
	}

	proc skewText {name xangle yangle} {
		variable pdf

		set tx [expr {tan($xangle*3.1415926/180.0)}]
		set ty [expr {tan($yangle*3.1415926/180.0)}]
		pdfout $name [format "1 %g %g 1 %g %g Tm\n" $tx $ty $pdf($name,xpos) $pdf($name,ypos)]
		set pdf($name,xpos) 0
		set pdf($name,ypos) $pdf($name,height)
	}

	proc addJpeg {name filename id} {
		variable pdf

		set imgOK false
		if [catch {open $filename "r"} if] {
			return -code error "Could not open file $filename"
		}
		fconfigure $if -translation binary
		set img [read $if]
		close $if
		binary scan $img "H4" h
		if {$h != "ffd8"} {
			close $if
			return -code error "file does not contain JPEG data."
		}
		set pos 2
		set img_length [string length $img]
		while {$pos < $img_length} {
			set endpos [expr {$pos+4}]
			binary scan [string range $img $pos $endpos] "H4S" h length
			set length [expr {$length & 0xffff}]
			if {$h == "ffc0"} {
				incr pos 4
				set endpos [expr {$pos+6}]
				binary scan [string range $img $pos $endpos] "cSS" depth height width
				set height [expr {$height & 0xffff}]
				set width [expr {$width & 0xffff}]
				set imgOK true
				break
			} else {
				incr pos 2
				incr pos $length
			}
		}
		if {$imgOK} {
			lappend pdf($name,images) $id [list $width $height $depth $img_length $img]
		} else {
			return -code error "something is wrong with jpeg data in file $filename"
		}
	}

	proc putImage {name id x y args} {
		variable pdf

		array set aimg $pdf($name,images)
		foreach {width height depth length data} $aimg($id) {break}

		set w $width
		set h $height
		set wfix 0
		set hfix 0
		foreach {arg value} $args {
			switch -- $arg {
				"-width" {set w $value; set wfix 1}
				"-height" {set h $value; set hfix 1}
			}
		}
		if {$wfix && !$hfix} {
			set h [expr {$height*$w/$width}]
		}
		if {$hfix && !$wfix} {
			set w [expr {$width*$h/$height}]
		}

		endTextObj $name
		if {$pdf($name,orient)} {
		  set y [expr {$pdf($name,height)-$y-$h}]
		}
		pdfout $name "q\n$w 0 0 $h $x $y cm\n/$id Do\nQ\n"
		return
	}
	
	# start text object, if not already in text
	proc beginTextObj {name} {
		variable pdf

		if {! $pdf($name,in_text_object)} {
			pdfout $name "BT\n"
			set pdf($name,in_text_object) true
		}
	}
	
	# end text object, if in text, else do nothing
	proc endTextObj {name} {
		variable pdf

		if {$pdf($name,in_text_object)} {
			pdfout $name "ET\n"
			set pdf($name,in_text_object) false
		}
	}

	# helper function: mask parentheses and backslash
	proc cleanText {in} {
		return [string map {( \\( ) \\) \\ \\\\} $in]
	}

	# helper function: return current object id
	proc get_oid {name} {
		variable pdf

		return $pdf($name,pdf_obj)
	}

	# helper function: return next object id (without incrementing)
	proc next_oid {name} {
		variable pdf

		set oid [get_oid $name]
		return [expr {$oid+1}]
	}

	# helper function: increment object id and return new value
	proc incr_oid {name} {
		variable pdf

		incr pdf($name,pdf_obj)
		return $pdf($name,pdf_obj)
	}

	# helper function: set xref of current oid to current out_pos
	proc store_xref {name} {
		variable pdf

		set oid $pdf($name,pdf_obj)
		set pdf($name,xref,$oid) $pdf($name,out_pos)
	}

	# helper function for formatting floating point numbers
	proc nf {n} {
		# precision: 4 digits
		set factor 10000.0
		return [expr {round($n*$factor)/$factor}]
	}

	Init
}

# vim: tw=0
