# (install)
###############################################################################
# camlMode.tcl  
##############################################################################

alpha::mode Caml 1.0.2 dummyCaml {*.ml *.mli} {
    camlMenu
} {
    # Script to execute at Alpha startup
    addMenu camlMenu "¥321" Caml
    set modeCreator(Caml) Caml
    set unixMode(caml) {Caml}
} uninstall {
    this-file
} maintainer {
    "Patrick Cousot" <cousot@dmi.ens.fr> <http://www.dmi.ens.fr/~cousot/>
} description {
    Supports the editing of Caml programming files
} help {
    This mode is for editing Caml Light code.  Caml Light is a small,
    portable implementation of the ML language that runs on most Unix
    machines, the Macintosh, the PC, and other microcomputers (freely
    distributed on <ftp://ftp.inria.fr/lang/caml-light>).

    Caml Mode provides a menu for easy switching between Alpha and Caml
    Light; and provides keyword coloring and function marking with the
    Marks Menu.
    
    Click on this "Caml Example.ml" link for an example syntax file.
}

namespace eval Caml {}

#=============================================================================
# dummy proc to load the Caml mode.  
#
proc dummyCaml {} {}

#=============================================================================
# dummy proc to load the code to make the camlMenu 
#
proc camlMenu {} {}

#=============================================================================
#	Set up package-specific mode variables
#
newPref v lineWrap 0 Caml
newPref f autoMark 1 Caml
# Number of blanks left at beginning of lines by 'fill' routines.
newPref v leftFillColumn {3} Caml
# Set to the regular expression that ALPHA uses to find function 
# declarations.
newPref v funcExpr  {(let|type|and|value|exception)([\s\t\r\n]+rec)?[\s\t\r\n]+([a-zA-Z][a-zA-Z0-9_']*)} Caml
newPref v parseExpr {(let|type|and|value|exception)([\s\t\r\n]+rec)?[\s\t\r\n]+([a-zA-Z][a-zA-Z0-9_']*)} Caml
# Regular expression used to defines words for all internal operations.
newPref v wordBreak {\w+} Caml
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 Caml
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Caml
# Colorization setup
newPref v commentColor red Caml
newPref v directiveColor green Caml
newPref v exceptionColor magenta Caml
newPref v functionColor cyan Caml
newPref v keywordColor blue Caml
newPref v specialCharColor red Caml
newPref v stringColor green Caml

set Caml::commentCharacters(Paragraph) [list "(* " " *)" " * "]

# ALL THE ABOVE VARS ARE NOW GLOBAL AND MODE-VARS
 
#=============================================================================
# Caml Menu:
#

Menu -n $camlMenu -p camlMenuProc -M Caml {
    "caml"
    "(-"
    "/C<U<OcopySelectionToCaml"
    "/C<U<O<BcopyFileToCaml"
}

proc camlSwitch {} {
    global camlLightSig
    app::launchAnyOfThese Caml camlLightSig "Please locate Caml Light:"
    switchTo '$camlLightSig'
}

proc camlMenuProc {menu item} {
    switch $item {
	caml {
	    camlSwitch
	}
	copySelectionToCaml {
	    putScrap [getSelect]
	    camlSwitch
	}
	copyFileToCaml {
	    putScrap [getText 0 [maxPos]]
	    camlSwitch
	}
    }
}

#=============================================================================
# Colorize Caml comments, strings and keywords
#
proc colorCamlKeywords {} {
    global CamlmodeVars

    set camlKeyWords		{
	and as begin close do done downto else end exception for fun function if in 
	let match mutable not of open or prefix rec then to try type value while 
	with
    }
 
    regModeKeywords -b {(*} {*)} -c $CamlmodeVars(commentColor) -k $CamlmodeVars(keywordColor) -s $CamlmodeVars(stringColor) Caml $camlKeyWords
    # regModeKeywords -a -i "#" -i "!" -i "=" -i "&" -i "." -i "+" -i "," -i "-" -i ">" -i "/" -i ":" -i ";" -i "<" -i ">" -i "@" -i "["  -i "]" -i "\{" -i "\}" -i "'" -i "|" -i "^" -I $CamlmodeVars(specialCharColor) Caml {}
    unset camlKeyWords
} 
# call it now
regModeKeywords -C Caml {}
colorCamlKeywords; rename colorCamlKeywords ""

#=============================================================================
# Colorize Caml directives
#
proc colorCamlDirectives {} {
    global CamlmodeVars

    set camlDirectives {
	cd include #open #close load compile load_object
    }
    regModeKeywords -a -k $CamlmodeVars(directiveColor) Caml $camlDirectives
    unset camlDirectives
}
# call it now
colorCamlDirectives; rename colorCamlDirectives ""

#=============================================================================
# Colorize Caml exceptions
#
proc colorCamlExceptions {} {
	global CamlmodeVars

	set camlExceptions	{
		 Bad Break Division_by_zero Empty End_of_file Exit Failure Graphic_failure 
		 Invalid_argument Match_failure Not_found Out_of_memory Parse_error 
		 Parse_failure Sys_error
	}
	regModeKeywords -a -k $CamlmodeVars(exceptionColor) Caml $camlExceptions
	unset camlExceptions
}
# call it now
colorCamlExceptions; rename colorCamlExceptions ""

#=============================================================================
# Colorize Caml functions, types and modules
#
proc colorCamlFunctions {} {
	global CamlmodeVars

set camlFunctions		{
     abs abs_float acos add add_float add_int arg asin asr assoc assq atan atan2 
     basename black blit_image blit_string blit_vect blue bool builtin 
     button_down catch_break char char_for_read char_of_int chdir check_suffix 
     clear clear_graph clear_parser close_graph clos_in close_out color combine 
     command_line compare_strings concat concat_vect cos create_image 
     create_lexer create_lexer_channel create_lexer_string create_string 
     current_dir_name current_point cyan decr dirname div_float div_int do_list 
     do_list_combine do_stream do_table do_vect draw_arc draw_char draw_circle 
     draw_ellipse draw_image draw_string dump_image end_of_stream eq eq_Float 
     eq_int eq_string event exc except exceptq exists exit exn exp failwith fhar 
     file_perm filename fill_arc fill_circle fill_ellipse fill_poly fill_rect 
     fill_string fill_vect find find_all flat_map float float_of_int 
     float_of_string flush for_all fprint fprintf fst fstring fvect gc ge_float 
     ge_int ge_string genlex get_image get_lexeme get_lexeme_char get_lexee_end 
     get_lexeme_start getenv graphics green gt_float gt_int gt_string hash 
     hash_param hashtbl hd image in_channel in_channel_length incr index init 
     input input_binary_int input_byte input_char input_line input_value int 
     int_of_char int_of_float int_of_string interactive intersect invalid_arg 
     is_absolute it_list it_list2 iter key_pressed land le_float le_int 
     le_string length lexbuf lexing lineto list list_it list_it2 list_length 
     list_of_vect lnot log lor lshift_left lshift_right lsl lsr lt_float lt_int 
     lt_string lxor magenta make_image make_lexer make_matrix make_string 
     make_vect map map2 map_combine map_vect map_vect_list max mem mem_assoc 
     memq merge min minus minus_float minus_int mod mouse_pos moveto mult_float 
     mult_int neq_float neq_int neq_string new nth_char open_descriptor_in 
     open_descriptor_out open_flag open_graph open_in open_in_bin open_in_gen 
     open_out open_out_bin open_out_gen out_channel out_channel_length output 
     output_binary_int output_byte output_char output_string output_value pair 
     parse parsing peek plot point_color pop pos_in pos_out power pred 
     prerr_char prerr_endline prerr_float prerr_int prerr_string print 
     print_char print_endline print_float print_int print_newline print_string 
     printexc printf push queue quit quo raise random read_float read_int 
     read_key read_line really_input red ref remove rename replace_string rev 
     rgb hs_end rhs_start s_irall s_irgrp s_iroth s_irusr s_isgid s_isuid 
     s_iwall s_iwgrp s_iwoth s_iwusr s_ixall s_iwgrp s_ixoth s_ixusr seek_in 
     seek_out set_color set_font set_line_width set_nth_char set_text_size sin 
     size_x size_y snd sort sound spec split sqrt stqck status std_err std_in 
     std_out stderr stdin stdout stream stream_check stream_from stream_get 
     stream_next stream_of_channel stream_of_string string string_for_read 
     string_length string_of_float string_of_int sub_float sub_int sub_string 
     sub_vect subtract succ symbol_end symbol_start sys take tan text-size tl 
     token toplevel trace transp union unit untrace vect vect_assign vect_item 
     vect_length vect_of_list wait_next_event white yellow
 }
regModeKeywords -a -k $CamlmodeVars(functionColor) Caml $camlFunctions
unset camlFunctions
}
# call it now
colorCamlFunctions; rename colorCamlFunctions ""

#=============================================================================
# Mark Menu:
#
proc Caml::MarkFile {args} {
    win::parseArgs win
    
    global CamlmodeVars
    set pat $CamlmodeVars(funcExpr)
    set end [maxPos -w $win]
    set pos [minPos -w $win]
    set l {}
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 1 $pat $pos} mtch]} {
	regexp -nocase -- $pat [eval [list getText -w $win] $mtch] allofit binding opttrec name
	set start [lindex $mtch 0]
	set end [nextLineStart -w $win $start]
	set pos $end
	set inds($name) [lineStart -w $win [pos::math -w $win $start - 1]]
    }
    
    if {[info exists inds]} {
	foreach f [lsort -dictionary [array names inds]] {
	    set next [nextLineStart -w $win $inds($f)]
	    setNamedMark -w $win $f $inds($f) $next $next
	}
    }
}

proc Caml::correctIndentation {args} {
    uplevel 1 ::correctBracesIndentation $args
}
