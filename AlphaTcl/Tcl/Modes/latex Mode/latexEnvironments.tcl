## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "latexEnvironments.tcl"
 #                                          created: 11/10/1992 {10:42:08 AM}
 #                                      last update: 01/25/2006 {03:43:50 PM}
 # Description:
 #
 # Procedures for inserting LaTeX environments.
 #
 # Many procs written/adapted from Pierre Basso's.  Many thanks for the great
 # improvements.
 # 
 # Both this file and "TeXCompletions.tcl" need to be looked at further to
 # see if more streamlining can be done.  Both are currently a hodgepodge of
 # stuff that's been added over the years ...
 #
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the main TeX mode file has been loaded.
latex.tcl

proc latexEnvironments.tcl {} {}

# Make sure that we have this dialog type in place.
namespace eval dialog {
    variable simple_type
    if {![info exists simple_type(var5)]} {
	set simple_type(var5) \
	  "dialog::makeEditItem res script \$left \$right y \$name \$val 5"
    } 
}

namespace eval TeX {}

#This item is off by default now.  Add it to your TeXPrefs.tcl if desired.
#set TeXbodyOptions(enumerate) "\[¥a|i¥\]"

set TeXbodyOptions(list)           "\{¥¥\}\{¥¥\}"
set TeXbodyOptions(figure)         "\[tbp\]"
set TeXbodyOptions(floatingfigure) "\{¥width¥\}"

# ×××× Embeddable environments ×××× #

proc TeX::Figure {} {

    set _t [TeX::indentEnvironment]

    set fig_types [list "Normal" "Floating" \
      "2 side-by-side" "3 side-by-side" "4 side-by-side" \
      "2, one above the other" \
      "4 in a 2x2 block" \
      "6 with 3 across, 2 down" \
      "6 with 2 across, 3 down" \
      "otherÉ" \
      ]
    set fig [listpick -p "Pick a figure type to insert:" $fig_types]
    if {$fig == ""} {return ""}

    global TeXbodyOptions
    if {$fig == "Floating"} {
	set t $TeXbodyOptions(floatingfigure)
    } else {
	set t $TeXbodyOptions(figure)
    }
    append t "\n${_t}"

    switch $fig {
	"Normal" -
	"Floating" {
	    append t "\\centerline\{\\includegraphics\[¥shape,orientation¥\]"
	    append t "\{¥graphics file¥\}\}\r${_t}"
	    append t "\\caption¥\[short title for t.o.f.\]¥\{¥caption¥\}\r${_t}"
	    append t "\\protect[TeX::labelString fig]"
	    if {$fig == "Floating"} {
		text::replace {\begin{figure}} {\begin{floatingfigure}} 0
		text::replace {\end{figure}} {\end{floatingfigure}} 1
		TeX::requirePackage floatflt
	    }
	}
	"2 side-by-side" {
	    append t [TeX::_subFigure 2 1]
	}
	"3 side-by-side" {
	    append t [TeX::_subFigure 3 1]
	}
	"4 side-by-side" {
	    append t [TeX::_subFigure 4 1]
	}
	"2, one above the other" {
	    append t [TeX::_subFigure 1 2]
	}
	"4 in a 2x2 block" {
	    append t [TeX::_subFigure 2 2]
	}
	"6 with 3 across, 2 down" {
	    append t [TeX::_subFigure 3 2]
	}
	"6 with 2 across, 3 down" {
	    append t [TeX::_subFigure 2 3]
	}
	"otherÉ" {
	    set w [prompt "Number of subfigures, horizontally" "2"]
	    set h [prompt "Number of subfigures, vertically" "2"]
	    append t [TeX::_subFigure $w $h]
	}
	
    }
    return $t
}


# This procedure is an improved version of tcl programming
# of tabular environment.
#
# This TeX::tabular procedure asks for vertical and for horizontal
# lines. But the main Improvements  affect   providing
# the list of options. When clicking in TeX menu mode
# the environment "tabular" this procedure asks for a list
# of options given in following way:
#  opt1 opt2 opt3 .....
# opt1, 2, 3, .. are any kind of option allowed by LaTeX
# for environment tabular:
#     c l r c p m b
# Options >, <, @ and ! are also allowed and you can provide:
#     >c >l >r >p >m >b
#     c< l< r< p< m< b<
#     c@ l@ r@ p@ m@ b@
#     c! l! r! p! m! b!
# Procedure tabular will put left and right braces in case of
# options p, m, b, @, !.
#
# WARNING: space is needed between two options!!!!!!l
#
# If the number of options exceed the number of columns
# a message is displayed and the list of options is again asked.
# If the number of options is lesser thanthe number of columns
# the missing options are provided as the last option of the list;
# for example: 5 columns asked and a list of options  "c l r"  with
# vertical line "yes" would create a tabular environment:
# \begin{tabular}{|c|l|r|r|r|}
#
# Pierre BASSO
# email:basso@lim.univ-mrs.fr
#

proc TeX::BuildTabular {env} {

    set _t [TeX::indentEnvironment]

    # Ask for number of rows, columns, vertical and horizontal lines and
    # options.  This dialog is a mess in Alpha8 !!  Best to rewrite it using
    # the new dialogs code.
    
    set values [dialog -w 500 -h 400\
      -t "how many rows? " 10 10 180 30 -e "3" 220 10 240 30 \
      -t "how many columns? " 10 40 180 60 -e "3" 220 40 240 60 \
      -t "vertical line (yes/no)? " 10 80 200 100 -e "yes" 220 80 250 100 \
      -t "horizontal line (yes/no)? " 10 110 200 130 -e "yes" 220 110 250 130 \
      -t "options:  c l r p m b  >c >l >r >p >m >b  c< l< r< p< m< b<" 10 150 400 170\
      -t " c@ l@ r@ p@ m@ b@  c! l! r! p! m! b!" 140 170 400 190\
      -e "c" 220 200 450 230 \
      -t "position  (b/t or empty)" 10 250 180 270 -e "" 220 250 240 270\
      -t "width if tabular*" 10 290 180 310 -e "" 220 290 320 310\
      -b OK 50 350 115 370 -b Cancel 250 350 315 370]
    set cancel [string trim [lindex $values 8]]
    if {$cancel == 1} {beep ; return}

    #   search for number of rows, default 3
    #   search for number of columns, default 3
    #
    set numberRows [string trim [lindex $values 0]]
    set numberColumns [string trim [lindex $values 1]]
    if {![is::PositiveInteger $numberRows] || ![is::PositiveInteger $numberColumns]} {
	beep
	alertnote "invalid input:  unsigned, positive integer required"
	return
    }

    # ask for  vertical lines : default yes
    set vline [string trim [lindex $values 2]]
    if {$vline == "yes"} {set vline "|"} else {set vline ""}

    # tabular options
    set options [string trim [lindex $values 4]]
    set numberOpts [llength $options]
    set arg "\{$vline"
    for {set j 0} {$j < $numberColumns} {incr j} {
	if {$j < $numberOpts} {
	    set optCol [lindex $options $j]
	}
	if {$optCol == "c" || $optCol == "l" || $optCol == "r"} {
	    append arg "$optCol$vline"
	    continue
	}
	if {$optCol == "p" || $optCol == "m" || $optCol == "b"\
	  || $optCol == "@" || $optCol == "!"} {
	    append arg "$optCol\{¥¥\}$vline"
	    continue
	}
	if {$optCol == ">c" || $optCol == ">l" || $optCol == ">r"} {
	    append arg  ">\{¥¥\}"
	    set secondopt [string index $optCol 1]
	    append arg "$secondopt$vline"
	    continue
	}
	if {$optCol == ">p" || $optCol == ">m" || $optCol == ">b"} {
	    append arg  ">\{¥¥\}"
	    set secondopt [string index $optCol 1]
	    append arg "$secondopt\{¥¥\}$vline"
	    continue
	}
	if {$optCol == "c<" || $optCol == "l<" || $optCol == "r<"} {
	    set secondopt [string index $optCol 0]
	    append arg "$secondopt<\{¥¥\}$vline"
	    continue
	}
	if {$optCol == "p<" || $optCol == "m<" || $optCol == "b<"} {
	    set secondopt [string index $optCol 0]
	    append arg "$secondopt\{¥¥\}<\{¥¥\}$vline"
	    continue
	}
	if {$optCol == "c@" || $optCol == "l@" || $optCol == "r@"} {
	    set secondopt [string index $optCol 0]
	    append arg "$secondopt@\{¥¥\}"
	    continue
	}
	if {$optCol == "p@" || $optCol == "m@" || $optCol == "b@"} {
	    set secondopt [string index $optCol 0]
	    append arg "$secondopt\{¥¥\}@\{¥¥\}"
	    continue
	}
	if {$optCol == "c!" || $optCol == "l!" || $optCol == "r!"} {
	    set secondopt [string index $optCol 0]
	    append arg "$secondopt!\{¥¥\}"
	    continue
	}
	if {$optCol == "p!" || $optCol == "m!" || $optCol == "b!"} {
	    set secondopt [string index $optCol 0]
	    append arg "$secondopt\{¥¥\}!\{¥¥\}"
	    continue
	}
    }
    append arg "\}"
    append t $arg "\r${_t}"
    # set horizontal lines
    set hline [string trim [lindex $values 3]]
    if {$hline == "yes"} {set hline "\\hline"} else {set hline ""}
    set body "$hline\r${_t}"
    for {set i 1} {$i <= $numberRows} {incr i} {
	append body "[TeX::buildRow $numberColumns]"
	append body "  \\\\\r${_t}$hline\r${_t}"
    }
    append t $body "¥¥ "
    # set width if tabular*
    if {$env == "tabular*"} {
	set width [string trim [lindex $values 6]]
	if {$width == ""} {set width "¥¥"}
	append t "\{" $width "\}"
    }

    # set position
    set position [string trim [lindex $values 5]]
    if {$position != ""} {
	append t "\[" $position "\]"
    }
    return $t
}

#####################  lists  ##########################

#
# Build lists.
# This procedure is called for building environments itemize, enumerate,
# description, list and trivlist.
#
# Pierre BASSO
# email:basso@lim.univ-mrs.fr

proc TeX::BuildList {env} {
    
    global TeXbodyOptions

    set _t [TeX::indentEnvironment]

    prompt::simple \
      [list "how many items?" numberitems 3 N]
    if [info exists TeXbodyOptions($env)] {
	set body $TeXbodyOptions($env)
    }
    append body "\n${_t}"

    for {set j 1} {$j <= $numberitems} {incr j} {
	if {$env == "description" || $env == "trivlist"} {
	    append body "\\item\[¥¥\] ¥¥"
	} else {
	    append body "\\item ¥¥"
	}
	if {$j < $numberitems} {append body "\r\r${_t}"}
    }
    return $body
}

# ×××× Boxes ×××× #

proc TeX::parbox {} {

    prompt::simple \
      [list "position (optional)?" position ""] \
      [list "height (optional)?" height ""] \
      [list "inner position (optional)?" innerpos ""] \
      [list "width?" width 3in]

    if {$position != ""} {
	append res "\[$position\]"
    }
    if {$height != ""} {
	append res "\[$height\]"
    }
    if {$innerpos != ""} {
	append res "\[$innerpos\]"
    }
    if {$width == ""} {set width "¥required width¥"}
    append res "\{$width\}\{¥¥\}"
    return $res
}

proc TeX::boxes {} {

    prompt::simple \
      [list "width (optional)?" width ""] \
      [list "position (optional)?" position ""]

    if {$width != ""} {
	append res "\[$width\]"
    }
    if {$position != ""} {
	append res "\[$position\]"
    }
    append res "\{¥¥\}"
    return $res
}

proc TeX::raisebox {} {
    prompt::simple \
      [list "lift?" lift ""] \
      [list "height (optional)?" height ""] \
      [list "depth (optional)?" depth ""]
    
    if {$lift == ""} {
	set lift "¥required lift¥"
    }
    append res "\{$lift\}"
    
    if {$height != ""} {
	append res "\[$height\]"
    }
    
    if {$depth != ""} {
	if {$height == ""} {
	    append res "\[\\height\]"
	}
	append res "\[$depth\]"
    }
    
    append res "\{¥¥\}"
    return $res
}


proc TeX::sbox {} {

    prompt::simple \
      [list "command?" command ""]
    if {$command == ""} {set command "¥required command¥"}
    append res "\{$command\}\{¥¥\}"
    return $res
}

proc TeX::savebox {} {

    prompt::simple \
      [list "command?" command ""] \
      [list "width (optional)?" width ""] \
      [list "position (optional)?" position ""]

    if {$command == ""} {set command "¥required command¥"}
    append res "\{$command\}"

    if {$width != ""} {
	append res "\[$width\]"
    }
    if {$position != ""} {
	append res "\[$position\]"
    }

    append res "\{¥body¥\}"
    return $res

}

proc TeX::rule {} {

    prompt::simple \
      [list "lift (optional)?" lift ""] \
      [list "width?" width ""] \
      [list "height?" height ""]
    if {$lift != ""} {
	append res "\[$lift\]"
    }

    if {$width == ""} {set width "¥required width¥"}
    append res "\{$width\}"

    if {$height == ""} {set height "¥required height¥"}
    append res "\{$height\}¥rule body¥"

    return $res
}

proc TeX::minipage {} {

    set _t [TeX::indentEnvironment]

    prompt::simple \
      [list "position (optional)?" position ""] \
      [list "height (optional)?" height ""] \
      [list "inner position (optional)?" innerpos ""] \
      [list "width?" width 3in]
    if {$position != ""} {
	append res "\[$position\]"
    }
    if {$height != ""} {
	append res "\[$height\]"
    }
    if {$innerpos != ""} {
	append res "\[$innerpos\]"
    }
    if {$width == ""} {set width "¥required width¥"}
    append res "\{$width\}\r${_t}¥minipage body¥"
    return $res
}

# ×××× Maths ×××× #

#
# Pierre BASSO
# email:basso@lim.univ-mrs.fr
#

#
# All the types of matrix
#
#

proc TeX::matrix {} {

    set _t [TeX::indentEnvironment]

    prompt::simple \
      [list "how many rows?" numberRows 2 N] \
      [list "how many columns?" numberColumns 2 N]
    set body "\r"
    # build matrix
    for {set i 1} {$i <= $numberRows} {incr i} {
	append body "${_t}[TeX::buildRow $numberColumns]  "
	if {$i != $numberRows} {append body "\\\\\r"}
    }

    return $body
}

proc TeX::eqnarray {} {
    set _t [TeX::indentEnvironment]
    prompt::simple \
      [list "how many equations?" numberRows 2 N]
    #  align is a tabular with three columns
    set numberColumns 3
    # build alignment
    set res "\r"
    for {set i 1} {$i <= $numberRows} {incr i} {
	append res "${_t}¥¥ & ¥¥ & ¥¥ [TeX::labelString eq]"
	if {$i != $numberRows} {append res "\\\\\r"}
    }
    return $res
}
proc TeX::eqnarray* {} {
    set _t [TeX::indentEnvironment]
    prompt::simple \
      [list "how many equations?" numberRows 2 N]
    #  align is a tabular with three columns
    set numberColumns 3
    # build alignment
    set res "\r"
    for {set i 1} {$i <= $numberRows} {incr i} {
	append res "${_t}¥¥ & ¥¥ & ¥¥ "
	if {$i != $numberRows} {append res "\\\\\r"}
    }
    return $res
}

#
# Alignment at a single place of mathematical formula
#

proc TeX::align {} {

    set _t [TeX::indentEnvironment]

    prompt::simple \
      [list "how many equations?" numberRows 2 N]

    #  align is a tabular with two columns
    set numberColumns 2
    # build alignment
    set res "\r"
    for {set i 1} {$i <= $numberRows} {incr i} {
	append res "${_t}¥¥ & ¥¥ [TeX::labelString eq]"
	if {$i != $numberRows} {append res "\\\\\r"}
    }
    return $res
}

proc TeX::align* {} {
    set _t [TeX::indentEnvironment]

    prompt::simple \
      [list "how many equations?" numberRows 2 N]

    #  align is a tabular with two columns
    set numberColumns 2
    # build alignment
    set res "\r"
    for {set i 1} {$i <= $numberRows} {incr i} {
	append res "${_t}¥¥ & ¥¥ "
	if {$i != $numberRows} {append res "\\\\\r"}
    }
    return $res
}


#
# Alignment at several places of mathematical formula
#
proc TeX::alignat {} {

    set _t [TeX::indentEnvironment]

    prompt::simple \
      [list "how many equations?" numberRows 2 N] \
      [list "how many alignments?" numberColumns 2 N]

    append res "\{$numberColumns\}\r"
    set numberColumns [expr $numberColumns*2 - 1]
    # build alignment
    for {set i 1} {$i <= $numberRows} {incr i} {
	set j 1
	while {$j < $numberColumns} {
	    append res "${_t}¥¥ & "
	    incr j
	}
	append res "¥¥  [TeX::labelString eq]"
	if {$i != $numberRows} {append res "\\\\\r"}
    }
    return $res
}

# ×××× embeddable proc helpers ×××× #

##
 # -------------------------------------------------------------------------
 #
 # "TeX::_subFigure" --
 #
 #  This is a helper, it is only called form the above TeX::Figure proc.
 # -------------------------------------------------------------------------
 ##

proc TeX::_subFigure {w h} {

    set _t [TeX::indentEnvironment]

    TeX::requirePackage subfigure
    set t "\\centering\r${_t}"
    set wnum [lindex {x "" two three four five six seven} $w]
    for {set hh $h} {$hh >0} {incr hh -1} {
	for {set ww $w} {$ww >0} {incr ww -1} {
	    append t "\\subfigure\[¥subfig caption¥\]\{[TeX::labelString fig]%\r${_t}"
	    append t "${_t}\\includegraphics\[width=\\figs${wnum}\]"
	    append t "\{¥graphics file¥\}\}"
	    if {$ww != 1} {
		append t "\\goodgap${wnum}\r${_t}"
	    } else {
		if {$hh != 1} {
		    append t "\\\\\r${_t}"
		} else {
		    append t "%\r${_t}"
		}
	    }
	}
    }
    append t "\\caption¥\[short caption for t.o.f.\]¥\{¥caption¥\}\r${_t}"
    append t "[TeX::labelString fig]"
}

#--------------------------------------------------------------------------
# ×××× Environments: ××××
#--------------------------------------------------------------------------

## 
 # --------------------------------------------------------------------------
 # 
 # "TeX::addNewEnvironment" --
 # 
 # Prompts the user to create a new "TeXbodies" array entry, which will then
 # be saved in the user's "TeXPrefs.tcl" file.
 # 
 # --------------------------------------------------------------------------
 ##

proc TeX::addNewEnvironment {{newEnv ""}} {
    
    global TeXmodeVars TeXbodies
    
    # Make sure that we have an environment name.
    if {($newEnv eq "")} {
	set q "You are about to create a new environment to be recognized by\
	  TeX mode electric completion routines.  You will be prompted to\
	  enter a template for the environment, which will then be saved\
	  in your \"TeXPrefs.tcl\" file.\r\rNote: this new environment will\
	  not appear in any of the menus, but will only be available\
	  via electric completions."
	if {![dialog::yesno -y "Continue" -n "Help" -c -- $q]} {
	    TeX::newEnvironmentHelp
	    error "Cancelled."
	}
	set p "Enter the name for the new environment:"
	while {($newEnv eq "")} {
	    set newEnv [string trim [prompt $p $newEnv]]
	    set p "The environment name cannot be an empty string!"
	}
    }
    # Define an initial template.
    if {![info exists TeXbodies($newEnv)]} {
	if {!$TeXmodeVars(indentLaTeXEnvironments)} {
	    set newBody {\\r}
	} else {
	    set newBody {\\r\\t}
	}
	if {[ring::type]} {
	    append newBody {¥body¥\\r}
	} else {
	    append newBody {¥¥\\r}
	}
    } else {
	set q "The environment \"${newEnv}\" has already been defined.\
	  Do you want to over-ride the old version?"
	if {![dialog::yesno $q]} {
	    error "Cancelled."
	} else {
	    set newBody $TeXbodies($newEnv)
	}
	set newBody $TeXbodies($newEnv)
    }
    # Prompt the user to create the new environment body.
    set txt1 "Enter the template for the body of\
	  the new \"${newEnv}\" environment.\
	  Template stops must be indicated by two bullets, as in \"¥¥\""
    if {[ring::type]} {
        append txt1 " -- insert '¥template prompt¥' for a template 'hint'"
    }
    append txt1 ".\r"
    set txt2 "You can use '\\\\r' for new lines and '\\\\r\\\\t'\
      for indented new lines."
    while {1} {
	set dialogScript [list dialog::make \
	  -title "New TeX Environment" \
	  -addbuttons [list \
	  "Help" \
	  "Press this button to close this window and obtain more help" \
	  {::TeX::newEnvironmentHelp ; set retVal "cancel" ; set retCode 1}] \
	  [list "" \
	  [list "text" $txt1] \
	  [list "text" $txt2] \
	  [list "var5" " " $newBody] \
	  ]]
	# Add the new "TeXbodies($newEnv)" variable to the user's prefs file.
	set newBody [string trim [lindex [eval $dialogScript] 0]]
	set q "The body for for the new \"${newEnv}\" is below.\
	  Do you want to save it, or edit it further?\r\r${newBody}"
	if {[dialog::yesno -y "Save" -n "Edit" -c -- $q]} {
	    break
	}
    }
    regsub -all -- {\\\\r}          $newBody "\r"   newBody
    regsub -all -- {\\\\t}          $newBody "\t"   newBody
    regsub -all -- {(\r|(\r?\n))$}  $newBody ""     newBody
    set TeXbodies($newEnv) $newBody
    set w [win::Current]
    mode::addModePrefsLine [list set TeXbodies($newEnv) $TeXbodies($newEnv)] TeX
    bringToFront $w
    # Remind the user how to modify this.
    alertnote "The new environment \"${newEnv}\" has been added to your\
      \"TeXPrefs.tcl\" file, and will be available as an electric completion.\
      \r\r(Select \"Config > TeX Mode Prefs > Edit Prefs File\"\
      later to edit it further if desired.)"
    return [list $newEnv $newBody]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "TeX::newEnvironmentHelp" --
 # 
 # Opens a new window explaining how [TeX::addNewEnvironment] works.  This 
 # is called by the button in that proc's dialog, but it can also be invoked 
 # from any other code (such as a menu item.)
 # 
 # --------------------------------------------------------------------------
 ##

proc TeX::newEnvironmentHelp {} {
    
    global alpha::application
    
    set n "New TeX Environment Help"
    if {[win::Exists $n]} {
        bringToFront $n
	return
    }
    append text "\r" $n "\r" {

	  	Introduction

ALPHA allows you to add new environments to TeX mode for the purposes of
electric completions.  For example, if you have this text (where "|"
indicates the cursor position):

	b'quote|

and press your Completion shortcut, this text will be inserted:

	\begin{quote}
	    |
	\end{quote}
	¥

You can open the "LaTeX Example.tex" file to test this.


	  	Adding New Environments

Suppose that you want to insert an environment that is not recognized by the
default TeX mode routines.  You can easily add one yourself.

	  	 	Defining via the LaTeX menu

Select the menu command "TeX Menu > Environments > Add New Environment" to
start the routine that starts with this <<TeX::addNewEnvironment>> dialog;
you can then define the new environment name and its body.

Add "\\r" to insert a new line, and "\\r\\t" to indent a new line anywhere in
the body of the environment.  If you want to insert a template stop, add two
bullets (¥¥), or surround an informative template "hint" with bullets, as in

	¥some option¥

	  	 	Auto-prompt to define new environments

Another way to invoke this new-environment creation dialog is to attempt to
complete a "b'newEnv" contraction completion.  In order for this to work, you
must first make sure that your preference for

	Unknown Environment Completions

is set to "Prompt for a new template".

Preferences: mode-TeX

If it is, then attempting to complete (e.g.)

	b'proof

should prompt you with <<TeX::addNewEnvironment>> to create the new
environment body.


	  	Editing New Environment bodies

Once you have created a new environment body, you can easily edit the
template whenever you like.  The template will be stored in your
"TeXPrefs.tcl" file, in the variable: TeXbodies .  Just open this file by
selecting the "Config > TeX Mode Prefs > Edit Prefs File" command, find the

	set TeXbodies(envName) ...

line, and make the necessary changes.  When you are finished, select the
command "Tcl Menu > Evaluate" to load the new changes into ALPHA's Tcl
interpreter.

Note: previous versions of ALPHA (using AlphaTcl 8.0 or older) stored all
user-defined "TeXbodies" array values in the "prefs.tcl" file.  You might
want to move all of these to your "TeXPrefs.tcl" file so that they are all
stored in the same place.  (Either file will work; the "TeXPrefs.tcl" is only
sourced when TeX mode is first loaded.)

	  	Tips
	
* In Anglo keyboards of Mac OS X, a bullet can be entered with Option-8.  If
this shortcut doesn't work (and you don't know which one will) you will have
to copy a "¥" into the clipboard and paste it into the dialog or the prefs
file template.

* There is no need to include a trailing new-line character in the template.
The "\end{envName}" statement will always be inserted in a new line.

* Your Completion shortcut can be set in the preferences: SpecialKeys dialog.

* See the "Electrics Help" file for more general information about the use of
electric completions and expansions in ALPHA. A "TeX Tutorial.tex" window is
also available with TeX mode specific electric examples.

* You can use this "new environment" routine to actually re-define any
current template for an existing environment.  Just enter the old
environment's name in the initial prompt, and authorize the re-definition.
This will only, however, be in effect for environments created through
electric completions.
}
    regsub -all -- {ALPHA} $text $alpha::application text
    set w [new -n $n -text $text -read-only 1 -dirty 0]
    goto -w $w [minPos -w $w]
    help::markColourAndHyper -w $w
    return
}

proc TeX::indentEnvironment {} {
    
    global TeXmodeVars
    
    if {$TeXmodeVars(indentLaTeXEnvironments)} {
        return "\t"
    } else {
        return ""
    }
}

proc TeX::itemize {} {
    
    set _t [TeX::indentEnvironment]

    set envName "itemize"
    prompt::var "$envName:  how many items?" numberItems 3 \
      is::PositiveInteger 1 "invalid input:  unsigned, postive integer required"
    if {$numberItems} {
        set body "${_t}\\item  ¥type first item¥"
        for {set i 1} {$i < $numberItems} {incr i} {
            append body "\r\r${_t}\\item  ¥¥"
        }
        append body "\r"
    } else {
        set body "${_t}¥¥\r"
    }
    TeX::insertEnvironment $envName "" $body
}

proc TeX::enumerate {} {

    set _t [TeX::indentEnvironment]

    set envName "enumerate"
    prompt::var "$envName:  how many items?" numberItems 3 \
      is::PositiveInteger 1 "invalid input:  unsigned, postive integer required"
    if {$numberItems} {
        set body "${_t}\\item  ¥type first item¥"
        for {set i 1} {$i < $numberItems} {incr i} {
            append body "\r\r${_t}\\item  ¥¥"
        }
        append body "\r"
    } else {
        set body "${_t}¥¥\r"
    }
    TeX::insertEnvironment $envName "" $body
}

proc TeX::description {} {

    set _t [TeX::indentEnvironment]

    set envName "description"
    prompt::var "$envName:  how many items?" numberItems 3 \
      is::PositiveInteger 1 "invalid input:  unsigned, postive integer required"
    if {$numberItems} {
        set body "${_t}\\item\[¥label¥\]  ¥¥"
        for {set i 1} {$i < $numberItems} {incr i} {
            append body "\r\r${_t}\\item\[¥¥\]  ¥¥"
        }
        append body "\r"
    } else {
        set body "${_t}¥¥\r"
    }
    TeX::insertEnvironment $envName "" $body
}

proc TeX::thebibliography {} {

    set _t [TeX::indentEnvironment]

    set envName "thebibliography"
    prompt::var "$envName:  how many items?" numberItems 3 \
      is::PositiveInteger 1 "invalid input:  unsigned, postive integer required"
    set arg "{9¥length of the key field¥}"
    if {$numberItems} {
        if {$numberItems > 9} {set arg "{99¥length of the key field¥}"}
        set body "${_t}\\bibitem{¥¥}  ¥¥"
        for {set i 1} {$i < $numberItems} {incr i} {
            append body "\r\r${_t}\\bibitem{¥¥} ¥¥"
        }
        append body "\r"
    } else {
        set body "${_t}¥¥\r"
    }
    TeX::insertEnvironment $envName $arg $body
}

proc TeX::slide   {} {TeX::doWrapEnvironment "slide"}
proc TeX::overlay {} {TeX::doWrapEnvironment "overlay"}
proc TeX::note    {} {TeX::doWrapEnvironment "note"}

proc TeX::figure  {} {

    global TeXmodeVars

    set _t [TeX::indentEnvironment]

    set envName "figure"
    set envArg "tbp"
    set arg "\[${envArg}¥Modify this argument?  (t=top; b=bottom; p=page; h=here; !=try harder)¥\]"
    set theIndentation [text::indentString [getPos]]
    append arg "\r$theIndentation${_t}\\centering"
    set body ""
    set macro [lindex $TeXmodeVars(boxMacroNames) 0]
    if {$macro != ""} {
        set restOfMacros [lrange $TeXmodeVars(boxMacroNames) 1 end]
        if {![llength $restOfMacros]} {
            append body "${_t}\\$macro{¥¥}\r"
        } else {
            set cmd [list prompt "Choose a box macro:"]
            lappend cmd $macro ""
            foreach boxMacroName $TeXmodeVars(boxMacroNames) {
                lappend cmd $boxMacroName
            }
            catch $cmd macro
            if {$macro == "cancel"} {
		error "cancel"
            } elseif {$macro == ""} {
                # do nothing
            } else {
                append body "${_t}\\$macro{¥¥}\r"
            }
        }
    }
    append body "${_t}\\caption{¥¥}\r"
    append body "${_t}[TeX::labelString fig]\r"
    if {$macro == ""} {
        TeX::wrapEnvironment $envName $arg $body
    } else {
        TeX::insertEnvironment $envName $arg $body
    }
}

proc TeX::table {} {

    set _t [TeX::indentEnvironment]

    set envName "table"
    set envArg "tbp"
    set arg "\[${envArg}¥Modify this argument?  (t=top; b=bottom; p=page; h=here; !=try harder)¥\]"
    set theIndentation [text::indentString [getPos]]
    append arg "\r$theIndentation${_t}\\centering"
    # The following statement puts the caption at the top:
    append arg "\r$theIndentation${_t}\\caption{¥¥}"
    # The following statement puts the caption at the bottom:
    #   set body "${_t}\\caption{¥¥}\r"
    append body "${_t}[TeX::labelString tbl]\r"
    TeX::wrapEnvironment $envName $arg $body
}

proc TeX::buildRow {jmax} {

    set txt "¥¥"
    for {set j 1} {$j < $jmax} {incr j} {
        append txt " & ¥¥"
    }
    return $txt
}

proc TeX::tabular {} {

    set _t [TeX::indentEnvironment]

    set envName "tabular"
    prompt::var "$envName:  how many rows?" numberRows 3 \
      is::PositiveInteger 1 "invalid input:  unsigned, postive integer required"
    prompt::var "$envName:  how many columns?" numberColumns 3 \
      is::PositiveInteger 1 "invalid input:  unsigned, postive integer required"
    set arg "{|"
    for {set j 1} {$j <= $numberColumns} {incr j} {
        append arg "c¥modify this argument?¥|"
    }
    append arg "}"
    set body "${_t}\\hline\r"
    for {set i 1} {$i <= $numberRows} {incr i} {
        append body "${_t}[TeX::buildRow $numberColumns]"
        append body "  \\\\\r${_t}\\hline\r"
    }
    TeX::insertEnvironment $envName $arg $body
}

proc TeX::verbatim   {} {TeX::doWrapEnvironment "verbatim"}
proc TeX::quote      {} {TeX::doWrapEnvironment "quote"}
proc TeX::quotation  {} {TeX::doWrapEnvironment "quotation"}
proc TeX::verse      {} {TeX::doWrapEnvironment "verse"}
proc TeX::flushleft  {} {TeX::doWrapEnvironment "flushleft"}
proc TeX::center     {} {TeX::doWrapEnvironment "center"}
proc TeX::flushright {} {TeX::doWrapEnvironment "flushright"}

proc TeX::minipage {} {

    set arg "\[¥¥\]{¥¥}"
    TeX::wrapEnvironment "minipage" $arg ""
    status::msg "enter the position \[b|c|t\] of the minipage, then the width"
}

##
 # -------------------------------------------------------------------------
 #	
 # "TeX::addItem"	--
 #	
 # Scan the local environment and insert a new item into that environment,
 # of the appropriate type.
 #	
 # Feel free to add additional switches to support more environment types.
 # -------------------------------------------------------------------------
 ##

proc TeX::addItem {} {
    
    global TeXmodeVars

    if {$TeXmodeVars(useLabelPrefixes)} {
	set prfx "eq$TeXmodeVars(standardTeXLabelDelimiter)"
    } else {
	set prfx ""
    }
    
    set pos  [getPos]
    set pos0 [lineStart $pos]
    set pos1 [pos::math [nextLineStart $pos] - 1]

    set env [lindex [split [eval getText [TeX::searchEnvironment]] "{}"] 1]
    if {![string length $env] || $env == "document"} {
	status::msg "No surrounding environment found."
	return
    } else {
        switch -- $env {
            "align"           {set i "\\\\\n¥next equation l.h.s.¥ &¥¥ \n\\label\{${prfx}¥label¥\}¥¥"}
            "cases"           {set i "¥¥ &¥¥ \\\\¥¥"}
            "description"     {set i "\\item\[¥name¥\] ¥description¥"}
            "enumerate"       {set i "\\item ¥¥"}
            "gather"          {set i "\\\\\n¥¥ \n\\label\{${prfx}¥label¥\}¥¥"}
            "itemize"         {set i "\\item ¥description¥"}
            "split"           {set i "¥¥ &¥¥ \\\\¥¥"}
            "thebibliography" {set i "\\bibitem\{¥¥\} ¥description¥"}
            default {
                status::msg "Sorry, 'Add Item' doesn't work for $env environments."
		return
            }
        }
    }
    if {![is::Whitespace [getText $pos0 $pos1]]} {
	goto $pos1
	elec::Insertion "\n${i}"
    } else {
	bind::IndentLine
	goto [pos::math [nextLineStart $pos0] - 1]
	elec::Insertion $i
    }
}

#--------------------------------------------------------------------------
# ×××× Math Environments: ××××
#--------------------------------------------------------------------------

proc TeX::math      {} {
    
    TeX::checkMathMode     "math" 0
    TeX::doWrapEnvironment "math"
}

proc TeX::equation* {} {

    TeX::checkMathMode     "equation*" 0
    TeX::doWrapEnvironment "equation*"
}

proc TeX::subequations {} {

    TeX::checkMathMode   "subequations" 0
    TeX::wrapEnvironment "subequations" "[TeX::labelString eq]" ""
}

proc TeX::displaymath {} {

    global TeXmodeVars

    TeX::checkMathMode "displaymath" 0

    if {$TeXmodeVars(useBrackets)} {
        TeX::doWrapStructure {\[} {} {\]}
    } else {
        TeX::doWrapEnvironment "displaymath"
    }
}

proc TeX::mathEnvironment {envName} {

    set _t [TeX::indentEnvironment]

    TeX::checkMathMode $envName 0
    set body "${_t}[TeX::labelString eq]\r"
    if {[TeX::wrapEnvironment $envName "" $body]} {
        set msgText "equation wrapped"
    } else {
        set msgText "enter equation"
    }
    status::msg $msgText
}

proc TeX::TeXmathenv {envName} {

    set _t [TeX::indentEnvironment]

    TeX::checkMathMode "$envName" 0

    prompt::var "$envName:  how many rows?" numberRows 3 \
      is::PositiveInteger 1 "invalid input:  unsigned, positive integer required"

    switch $envName {
        "eqnarray*" {
            set row "${_t}[TeX::buildRow 3]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r"
        }
        "eqnarray" {
            set row "${_t}[TeX::buildRow 3]\r${_t}[TeX::labelString eq]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r"
        }
        "flalign*" - "align*" - "aligned" {
            prompt::var "$envName:  how many alignments?" numberColumns 1 \
              is::PositiveInteger 1 "invalid input:  unsigned, positive integer required"
            set numberColumns [expr $numberColumns*2 ]
            set row "${_t}[TeX::buildRow $numberColumns]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r"
        }
        "flalign" - "align" {
            prompt::var "$envName:  how many alignments?" numberColumns 1 \
              is::PositiveInteger 1 "invalid input:  unsigned, positive integer required"
            set numberColumns [expr $numberColumns*2]
            set row "${_t}[TeX::buildRow $numberColumns]\r${_t}[TeX::labelString eq]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r"
        }
        "gather*" - "multline*" - "gathered" - "split"  {
            set row "${_t}[TeX::buildRow 1]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r"
        }
        "multline" {
            set row "${_t}[TeX::buildRow 1]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r${_t}[TeX::labelString eq]\r"
        }
        "gather" {
            set row "${_t}[TeX::buildRow 1]\r${_t}[TeX::labelString eq]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r"
        }
        "cases" {
            set row "${_t}[TeX::buildRow 2]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r${_t}[TeX::labelString eq]\r"
        }
        "array" {
            prompt::var "$envName:  how many columns?" numberColumns 3 \
              is::PositiveInteger 1 "invalid input:  unsigned, positive integer required"
            set arg "{"
            for {set j 1} {$j <= $numberColumns} {incr j} {
                append arg "c"
            }
            append arg "¥Modify this argument?  (c=center; l=left; r=right; p{width}; a{text})¥}"
            set row "${_t}[TeX::buildRow $numberColumns]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r"
            TeX::insertEnvironment $envName $arg $body
            return
        }
        "alignat" {
            prompt::var "$envName:  how many columns?" numberColumns 3 \
              is::PositiveInteger 1 "invalid input:  unsigned, positive integer required"
            set arg "{$numberColumns}"
            set numberColumns [expr $numberColumns*2]
            set row "${_t}[TeX::buildRow $numberColumns]\r${_t}[TeX::labelString eq]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r"
            TeX::insertEnvironment $envName $arg $body
            return
        }
        "alignat*" - "alignedat" {
            prompt::var "$envName:  how many columns?" numberColumns 3 \
              is::PositiveInteger 1 "invalid input:  unsigned, positive integer required"
            set arg "{$numberColumns}"
            set numberColumns [expr $numberColumns*2]
            set row "${_t}[TeX::buildRow $numberColumns]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r"
            TeX::insertEnvironment $envName $arg $body
            return
        }
        "subarray" {
            prompt::var "$envName:  how many columns?" numberColumns 1 \
              is::PositiveInteger 1 "invalid input:  unsigned, positive integer required"
            set arg "{"
            for {set j 1} {$j <= $numberColumns} {incr j} {
                append arg "c"
            }
            append arg "¥Modify this argument?  (c=center; l=left; r=right; p{width}; a{text})¥}"
            set row "${_t}[TeX::buildRow $numberColumns]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r"
            TeX::insertEnvironment $envName $arg $body
            return
        }
        "matrix" - "pmatrix" - "bmatrix" - "Bmatrix" - "vmatrix" - "Vmatrix" - \
          "smallmatrix" {
            prompt::var "$envName:  how many columns?" numberColumns 3 \
              is::PositiveInteger 1 "invalid input:  unsigned, positive integer required"
            set row "${_t}[TeX::buildRow $numberColumns]"
            for {set i 1} {$i < $numberRows} {incr i} {
                append body $row
                append body "  \\\\\r"
            }
            append body $row
            append body "\r"
        }
    }
    TeX::insertEnvironment $envName "" $body
}

# ==========================================================================
#
# .