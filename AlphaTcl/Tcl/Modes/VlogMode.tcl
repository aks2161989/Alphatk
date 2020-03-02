# Automatically created by mode assistant
#
# Mode: Vlog, for Verilog code.


# Mode declaration.
#  first two items are: name version
#  then 'source' means source this file when we first use the mode
#  then we list the extensions, and any features active by default
alpha::mode [list Vlog Verilog] 0.2.1 source {*.v *.vmd} {} {
    # Script to execute at Alpha startup
} uninstall {
    this-file
} maintainer {
} description {
    Supports the editing of Verilog language files
} help {
    This mode is for editing Verilog language files.
    
    Verilog HDL is a hardware description language used to design and
    document electronic systems.  Verilog HDL allows designers to design
    at various levels of abstraction.  It is the most widely used HDL
    with a user community of more than 50,000 active designers.
    
    More information can be found here: <http://www.verilog.com/>
}

# For Tcl 8
namespace eval Vlog {}

# Mode preferences settings, which can be edited by the user (with F12)

newPref var lineWrap 0 Vlog
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 0 Vlog

newPref v funcExpr {^[a-z0-9]+[ \t]+([a-z_0-9]+)[ \t]+\(} Vlog
newPref v parseExpr {^[a-z0-9]+[ \t]+([a-z_0-9]+)[ \t]+\(} Vlog

# Register comment prefix
set Vlog::commentCharacters(General) //
# Register multiline comments
set Vlog::commentCharacters(Paragraph) {{/* } { */} { * }}
# List of keywords
set VlogKeyWords {
    always and assign begin buf bufif0 bufif1 case casex casez cmos
    deassign default defparam disable edge else end endcase endfunction
    endmodule endprimitive endspecify endtable endtask event for for
    force forever function highz0 highz1 if ifnone initial inout input
    integer join large macromodule medium module nand negedge nmos nor
    not notif0 notif1 or output parameter pmos posedge primitive pull0
    pull1 pulldown pullup rcmos real realtime reg release repeat rnmos
    rpmos rtran rtranif0 rtranif1 scalared small specify specparam
    strong0 strong1 supply0 supply1 table task time tran tranif0 tranif1
    tri tri0 tri1 triand trior trireg vectored wait wand weak0 weak1
    while wire wor xnor xor accelerate autoexepand_vectornets celldefine
    default_nettype define else endcelldefine endif endprotect
    endprotected expand_vectornets ifdef include noaccelerate
    noexpand_vectornets noremove_gatenames noremove_netnames
    nounconnected_drive protect protected remove_gatenames
    remove_netnames resetall timescale unconnected_drive
}

# Colour the keywords, comments etc.
regModeKeywords -e // -b /* */ Vlog $VlogKeyWords
# Discard the list
unset VlogKeyWords

# To write indentation code for your new mode (so your mode
# automatically takes advantage of the automatic indentation
# possibilities of 'tab', 'return' and 'paste'), you can take
# advantage of the shared proc ::indentLine.  All you need to write
# is a Vlog::correctIndentation proc, and as a
# starting point you can copy the code of the generic
# ::correctIndentation, found in indentation.tcl.
