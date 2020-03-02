#!/usr/bin/env tclsh

package provide txt2pdf 0.1

namespace eval txt2pdf {
	variable debug 3
	# use a4 paper by default
	variable page_width 595.0
	variable page_depth 842.0
	variable margin 30.0
	variable font_size 10
	variable lead_size 10
	variable object_id 1
	variable page_tree_id 0
	variable chars_out 0
	variable page_id_list {}
	variable num_pages 0
	variable xrefs
	variable pdf

	proc my_printf {format_string args} {
		variable chars_out
		variable pdf

		set tmpbuf [eval "format {$format_string} $args"]
		incr chars_out [string length $tmpbuf]
		append pdf $tmpbuf
	}

	proc store_page {page_id} {
		variable page_id_list
		variable num_pages

		lappend page_id_list $page_id
		incr num_pages
	}

	proc start_object {id} {
		variable xrefs
		variable chars_out
		variable debug

		if {$debug>2} {
			puts stderr "xrefs($id) = $chars_out"
		}

		set xrefs($id) $chars_out
		my_printf "%d 0 obj\r" $id
	}

	proc start_page {} {
		variable object_id
		variable stream_id
		variable stream_len_id
		variable chars_out
		variable font_size
		variable ypos
		variable page_depth
		variable margin
		variable lead_size
		variable stream_start

		set stream_id $object_id
		incr object_id
		set stream_len_id $object_id
		incr object_id
		start_object $stream_id
		my_printf "<< /Length %d 0 R >>\r" $stream_len_id
		my_printf "stream\r"
		set stream_start $chars_out
		my_printf "BT\r/F0 %g Tf\r" $font_size
		set ypos [expr {$page_depth - $margin}]
		my_printf "%g %g Td\r" $margin $ypos
		my_printf "%g TL\r" $lead_size
	}

	proc end_page {} {
		variable object_id
		variable chars_out
		variable stream_len_id
		variable stream_start
		variable stream_len
		variable page_id
		variable stream_id
		variable page_tree_id

		set page_id $object_id
		incr object_id
		store_page $page_id
		my_printf "ET\r"
		set stream_len [expr {$chars_out - $stream_start}]
		my_printf "endstream\rendobj\r"
		start_object $stream_len_id
		my_printf "%ld\rendobj\r" $stream_len
		start_object $page_id
		my_printf "<</Type/Page/Parent %d 0 R/Contents %d 0 R>>\rendobj\r" $page_tree_id $stream_id
	}

	proc do_text {} {
		variable ypos
		variable margin
		variable lead_size

		start_page
		while {[gets stdin buffer]!=-1} {
			if {$ypos<$margin} {
				end_page
				start_page
			}
			if {[string length $buffer]==-1} {
				my_printf "T*\r"
			} else {
				if {[string index $buffer 0]=="\f"} {
					end_page
					start_page
				} else {
					regsub -all {\\} $buffer {\\\\} ps_buffer
					regsub -all {\(} $ps_buffer {\(} ps_buffer
					regsub -all {\)} $ps_buffer {\)} ps_buffer
					my_printf "(%s)'\r" $ps_buffer
				}
			}
			set ypos [expr {$ypos-$lead_size}]
		}
		end_page
	}

	proc topdf {args} {
		variable object_id
		variable page_tree_id
		variable num_pages
		variable page_id_list
		variable page_width
		variable page_depth
		variable xrefs
		variable chars_out
		variable pdf

		my_printf "%%PDF-1.0\r"
		set page_tree_id $object_id
		incr object_id
		do_text
		set font_id $object_id
		incr object_id
		start_object $font_id
		my_printf "<</Type/Font/Subtype/Type1/BaseFont/Courier/Encoding/WinAnsiEncoding>>\rendobj\r"
		start_object $page_tree_id
		my_printf "<</Type /Pages /Count %d\r" $num_pages
		my_printf "/Kids\[\r"
		foreach page_id $page_id_list {
			my_printf "%d 0 R\r" $page_id
		}
		my_printf "\]\r"
		my_printf "/Resources<</ProcSet\[/PDF/Text\]/Font<</F0 %d 0 R>> >>\r" $font_id
		my_printf "/MediaBox \[ 0 0 %g %g \]\r" $page_width $page_depth
		my_printf ">>\rendobj\r"
		set catalog_id $object_id
		incr object_id
		start_object $catalog_id
		my_printf "<</Type/Catalog/Pages %d 0 R>>\r\endobj\r" $page_tree_id
		set start_xref $chars_out
		my_printf "xref\r"
		my_printf "0 %d\r" $object_id
		my_printf "0000000000 65535 f \r"
		for {set i 1} {$i<$object_id} {incr i} {
			my_printf "%010ld 00000 n \r" $xrefs($i)
		}
		my_printf "trailer\r<<\r/Size %d\r/Root %d 0 R\r>>\r" $object_id $catalog_id
		my_printf "startxref\r%ld\r%%%%EOF\r" $start_xref
		return $pdf
	}
}

puts -nonewline [txt2pdf::topdf]

