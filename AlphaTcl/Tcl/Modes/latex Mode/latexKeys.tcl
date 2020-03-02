## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "latexKeys.tcl"
 #                                   created: 11/10/1992 {10:42:08 AM}
 #                               last update: 02/07/2005 {04:17:17 PM}
 # Description:
 #
 # Support for keypad, greek key-bindings.
 # Support for user-defined menu key-bindings.
 #
 # abbreviations:  <o> = option, <z> = control, <s> = shift, <c> = command
 #
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the main TeX mode file has been loaded.
latex.tcl

proc latexKeys.tcl {} {}

namespace eval TeX {}

# ==========================================================================
#
# ×××× -------- ×××× #
#
# Initial binding of LaTeX command keys.
#

proc TeX::bindLaTeXKeys {args} {

    TeX::bindKeypadKeys
    TeX::bindGreekKeys  "Bind"

    # Bind double quote:
    ascii 0x22 <s> TeX::smartDQuote  "TeX"
    # Bind single quote:
    ascii 0x27     TeX::smartQuote   "TeX"
    # Bind period:
    ascii 0x2e     TeX::smartDots    "TeX"
    # Bind delete key: (use ascii to avoid dead-key problem)
    #Bind 0x33 TeX::escapeSmartStuff "TeX"
    ascii 0x08 TeX::escapeSmartStuff "TeX"
}

proc TeX::bindKeypadKeys {args} {

    global TeXmodeVars

    # Completely take over the keypad:
    set mods [list \
      <> <c> <o> <z> <s> <co> <cz> <cs> <oz> <os> <zs>  <coz> <cos> <ozs> <cozs>]
    set keys [list \
	Kpad0 Kpad1 Kpad2 Kpad3 Kpad4 Kpad5 Kpad6 Kpad7 Kpad8 Kpad9 Kpad= \
	Kpad/ Kpad* Kpad- Kpad+ Enter Kpad.  Kpad0]
    
    if {$TeXmodeVars(takeOverNumericKeypad)} {
        set which "Bind"
    } else {
        set which "unBind"
    }
    # Make sure that all of the keypad keys are 'dummys'.
    foreach mod $mods {
	foreach key $keys {
	    $which $key $mod latex.tcl "TeX"
	}
    }

    $which Kpad8      {TeX::menuProc Goto {Prev Subsection}}               "TeX"
    $which Kpad2      {TeX::menuProc Goto {Next Subsection}}               "TeX"
    $which Kpad8 <s>  {TeX::menuProc Goto {Prev Subsection Select}}        "TeX"
    $which Kpad2 <s>  {TeX::menuProc Goto {Next Subsection Select}}        "TeX"
    $which Kpad8 <c>  {TeX::menuProc Goto {Prev Section}}                  "TeX"
    $which Kpad2 <c>  {TeX::menuProc Goto {Next Section}}                  "TeX"
    $which Kpad8 <sc> {TeX::menuProc Goto {Prev Section Select}}           "TeX"
    $which Kpad2 <sc> {TeX::menuProc Goto {Next Section Select}}           "TeX"
    $which Kpad4      {TeX::menuProc Goto {Prev Command}}                  "TeX"
    $which Kpad6      {TeX::menuProc Goto {Next Command}}                  "TeX"
    $which Kpad4 <s>  {TeX::menuProc Goto {Prev Command Select}}           "TeX"
    $which Kpad6 <s>  {TeX::menuProc Goto {Next Command Select}}           "TeX"
    $which Kpad4 <so> {TeX::menuProc Goto {Prev Command Select With Args}} "TeX"
    $which Kpad6 <so> {TeX::menuProc Goto {Next Command Select With Args}} "TeX"
    $which Kpad4 <c>  {TeX::menuProc Goto {Prev Environment}}              "TeX"
    $which Kpad6 <c>  {TeX::menuProc Goto {Next Environment}}              "TeX"
    $which Kpad4 <sc> {TeX::menuProc Goto {Prev Environment Select}}       "TeX"
    $which Kpad6 <sc> {TeX::menuProc Goto {Next Environment Select}}       "TeX"
}

proc TeX::bindGreekKeys {{which "Bind"}} {

    $which 'm' <z>   {prefixChar "Greek letter:"}                 "TeX"
    $which 'a' <M>   [list TeX::macroMenuProc {Greek} alpha]      "TeX"
    $which 'b' <M>   [list TeX::macroMenuProc {Greek} beta]       "TeX"
    $which 'c' <M>   [list TeX::macroMenuProc {Greek} chi]        "TeX"
    $which 'd' <M>   [list TeX::macroMenuProc {Greek} delta]      "TeX"
    $which 'd' <sM>  [list TeX::macroMenuProc {Greek} Delta]      "TeX"
    $which 'e' <M>   [list TeX::macroMenuProc {Greek} epsilon]    "TeX"
    $which 'e' <zM>  [list TeX::macroMenuProc {Greek} varepsilon] "TeX"
    $which 'f' <M>   [list TeX::macroMenuProc {Greek} phi]        "TeX"
    $which 'f' <sM>  [list TeX::macroMenuProc {Greek} Phi]        "TeX"
    $which 'f' <zM>  [list TeX::macroMenuProc {Greek} varphi]     "TeX"
    $which 'g' <M>   [list TeX::macroMenuProc {Greek} gamma]      "TeX"
    $which 'g' <sM>  [list TeX::macroMenuProc {Greek} Gamma]      "TeX"
    $which 'h' <M>   [list TeX::macroMenuProc {Greek} eta]        "TeX"
    $which 'i' <M>   [list TeX::macroMenuProc {Greek} iota]       "TeX"
    $which 'k' <M>   [list TeX::macroMenuProc {Greek} kappa]      "TeX"
    $which 'l' <M>   [list TeX::macroMenuProc {Greek} lambda]     "TeX"
    $which 'l' <sM>  [list TeX::macroMenuProc {Greek} Lambda]     "TeX"
    $which 'm' <M>   [list TeX::macroMenuProc {Greek} mu]         "TeX"
    $which 'n' <M>   [list TeX::macroMenuProc {Greek} nu]         "TeX"
    $which 'o' <M>   [list TeX::macroMenuProc {Greek} omicron]    "TeX"
    $which 'p' <M>   [list TeX::macroMenuProc {Greek} pi]         "TeX"
    $which 'p' <sM>  [list TeX::macroMenuProc {Greek} Pi]         "TeX"
    $which 'p' <zM>  [list TeX::macroMenuProc {Greek} varpi]      "TeX"
    $which 'q' <M>   [list TeX::macroMenuProc {Greek} theta]      "TeX"
    $which 'q' <sM>  [list TeX::macroMenuProc {Greek} Theta]      "TeX"
    $which 'q' <zM>  [list TeX::macroMenuProc {Greek} vartheta]   "TeX"
    $which 'r' <M>   [list TeX::macroMenuProc {Greek} rho]        "TeX"
    $which 'r' <zM>  [list TeX::macroMenuProc {Greek} varrho]     "TeX"
    $which 's' <M>   [list TeX::macroMenuProc {Greek} sigma]      "TeX"
    $which 's' <sM>  [list TeX::macroMenuProc {Greek} Sigma]      "TeX"
    $which 's' <zM>  [list TeX::macroMenuProc {Greek} varsigma]   "TeX"
    $which 't' <M>   [list TeX::macroMenuProc {Greek} tau]        "TeX"
    $which 'u' <M>   [list TeX::macroMenuProc {Greek} upsilon]    "TeX"
    $which 'u' <sM>  [list TeX::macroMenuProc {Greek} Upsilon]    "TeX"
    $which 'v' <M>   [list TeX::macroMenuProc {Greek} nabla]      "TeX"
    $which 'w' <M>   [list TeX::macroMenuProc {Greek} omega]      "TeX"
    $which 'w' <sM>  [list TeX::macroMenuProc {Greek} Omega]      "TeX"
    $which 'x' <M>   [list TeX::macroMenuProc {Greek} xi]         "TeX"
    $which 'x' <sM>  [list TeX::macroMenuProc {Greek} Xi]         "TeX"
    $which 'y' <M>   [list TeX::macroMenuProc {Greek} psi]        "TeX"
    $which 'y' <sM>  [list TeX::macroMenuProc {Greek} Psi]        "TeX"
    $which 'z' <M>   [list TeX::macroMenuProc {Greek} zeta]       "TeX"
}

# A few extra key bindings

Bind  down <sz> {nextWhat 0 0} TeX
Bind right <sz> {nextWhat 0 1} TeX
Bind    up <sz> {prevWhat 0 0} TeX
Bind  left <sz> {prevWhat 0 1} TeX

Bind   's' <sz> {selectWhat}   TeX

# This is called by 'function::next/prev' etc when the 'navigateParagraphs'
# preference is turned off.  A simplified version of "TeX::findEnvironment"

proc TeX::getLimits {args} {
    
    win::parseArgs w pos direction

    set pat1 {^[ \t]*\\begin\{([^\}]*)\}}
    
    if {![catch {search -w $w -s -f $direction -r 1 -- $pat1 $pos} match1]} {
	set pos0 [lindex $match1 0]
	regexp $pat1 [getText -w $w $pos0 [lindex $match1 1]] allofit environment
	set pat2 "^\[ \t\]*\\\\end\{${environment}\}"
	if {![catch {search -w $w -s -f 1 -r 1 -- $pat2 $pos0} match2]} {
	    set pos1 [pos::nextLineStart -w $w [lindex $match2 1]]
	    return [list $pos0 $pos1 "environment"]
	} 
    }
    return [list "" "" "environment"]
}

# ==========================================================================
#
# ×××× -------- ×××× #
#
# ×××× Menu Bindings ×××× #
#
# It's only necessary to list the menu items that actually have default
# bindings in the TeX::MenuKeysDefault array -- items with no bindings will
# be recognized as such.
#

# ×××× "Goto" ×××× #

array set TeX::MenuKeysDefault {

    "LaTeX application"         "<U/S"
}

# # ×××× "LaTeX Utilities" ×××× #
#
# # ×××× "LaTeX Help" ×××× #
#
# ×××× "Documents" ×××× #

array set TeX::MenuKeysDefault {

    "New DocumentÉ"             "<U<O/N"
    "usepackage"                "<B<I/U"
}

# # ×××× "Packages" ×××× #
#
# # ×××× "Page Layout" ×××× #
#
# # ×××× "Sectioning" ×××× #
#
# # ×××× "Text Style" ×××× #

array set TeX::MenuKeysDefault  {

    "emph"                      "<B<I/E"
    "em"                        "<U<B<I/E"
    "underline"                 "<B<O/U"
    "textit"                    "<B<I/I"
    "itshape"                   "<U<B<I/I"
    "textsl"                    "<B<I/S"
    "slshape"                   "<U<B<I/S"
    "textsc"                    "<B<I/H"
    "scshape"                   "<U<B<I/H"
    "textbf"                    "<B<I/B"
    "bfseries"                  "<U<B<I/B"
    "textrm"                    "<B<I/R"
    "rmfamily"                  "<U<B<I/R"
    "textsf"                    "<B<I/W"
    "sffamily"                  "<U<B<I/W"
    "texttt"                    "<B<I/Y"
    "ttfamily"                  "<U<B<I/Y"
}

# # ×××× Text Commands ×××× #
#
# # ×××× "International" ×××× #
#
# ×××× "Environments" ×××× #

array set TeX::MenuKeysDefault {

    "itemizeÉ"                  "<I/k"
    "enumerateÉ"                "<U<I/k"
    "descriptionÉ"              "<B<I/k"
    "slide"                     "<I/l"
    "overlay"                   "<U<I/l"
    "note"                      "<B<I/l"
    "figure"                    "<I/m"
    "table"                     "<U<I/m"
    "tabularÉ"                  "<B<I/m"
    "verbatim"                  "<I/n"
    "quote"                     "<U<I/n"
    "quotation"                 "<B<I/n"
    "center"                    "<I/o"
    "flushleft"                 "<U<I/o"
    "flushright"                "<B<I/o"
    "Add Item"                  "<U<I/I"
    "Choose EnvironmentÉ"       "<U<O/E"
}

# ×××× "Boxes" ×××× #

array set TeX::MenuKeysDefault  {

    "mbox"                      "<B<I/M"
}


# ×××× "Miscellaneous" ×××× #

array set TeX::MenuKeysDefault {

    "verb"                      "<B<I/V"
    "footnote"                  "<B<I/F"
    "marginal note"             "<B<I/N"
    "label"                     "<B<I/L"
    "ref"                       "<B<I/X"
    "pageref"                   "<B<I/P"
    "cite"                      "<B<I/C"
    "nocite"                    "<U<B<I/C"
    "item"                      "<B<I/J"
    "quotes"                    "<B<I/'"
    "double quotes"             "<U<B<I/'"
}

# # ×××× "Math Modes" ×××× #
#
# # ×××× "Math Style" ×××× #

array set TeX::MenuKeysDefault {

    "mathit"                    "<B<I<O/I"
    "mathrm"                    "<B<I<O/R"
    "mathbf"                    "<B<I<O/B"
    "mathsf"                    "<B<I<O/W"
    "mathtt"                    "<B<I<O/Y"
    "mathcal"                   "<B<I<O/C"
    "mathbb"                    "<B<I<O/Z"
    "displaystyle"              "<B<I<O/D"
    "textstyle"                 "<B<I<O/T"
    "scriptstyle"               "<B<I<O/S"
}

# # ×××× "Text Size" ×××× #

proc TeX::setTextSizeKeys {} {

    global TeXmodeVars TeX::MenuKeysDefault

    if {$TeXmodeVars(useAMSLaTeX)} {

	array set TeX::MenuKeysDefault  {
	    "Tiny"         "<B<I/1"
	    "tiny"         "<B<I/2"
	    "SMALL"        "<B<I/3"
	    "Small"        "<B<I/4"
	    "small"        "<B<I/5"
	    "normalsize"   ""
	    "large"        "<B<I/6"
	    "Large"        "<B<I/7"
	    "LARGE"        "<B<I/8"
	    "huge"         "<B<I/9"
	    "Huge"         "<B<I/0"
	}

    } else {

	array set TeX::MenuKeysDefault  {
	    "tiny"          "<B<I/1"
	    "scriptsize"    "<B<I/2"
	    "footnotesize"  "<B<I/3"
	    "small"         "<B<I/4"
	    "normalsize"    "<B<I/5"
	    "large"         "<B<I/6"
	    "Large"         "<B<I/7"
	    "LARGE"         "<B<I/8"
	    "huge"          "<B<I/9"
	    "Huge"          "<B<I/0"
	}
    }
}

# # ×××× "Math Environments" ×××× #

proc TeX::setMathEnvsKeys {} {

    global TeXmodeVars TeX::MenuKeysDefault

    if {$TeXmodeVars(useAMSLaTeX)} {

        array set TeX::MenuKeysDefault {

            "math"                      "<I/i"
            "equation*"                 "<B/i"
            "equation"                  "<I<B/i"
            "align*É"                   "<B/j"
            "alignÉ"                    "<B<I/j"
            "gather*É"                  "<U/j"
            "gatherÉ"                   "<I<U/j"
            "multline*É"                "<B<U/j"
            "multlineÉ"                 "<I<B<U/j"
            "Choose EnvironmentÉ"       "<U<O/E"
        }

    } else {

        array set TeX::MenuKeysDefault {

            "math"                      "<I/i"
            "displaymath"               "<U<I/i"
            "equation"                  "<B<I/i"
            "eqnarrayÉ"                 "<B<I/j"
            "eqnarray*É"                "<U<I/j"
            "arrayÉ"                    "<I/j"
            "Choose EnvironmentÉ"       "<U<O/E"
        }
    }
}

# # ×××× "Theorem" ×××× #
#
# ×××× "Formulas" ×××× #

array set TeX::MenuKeysDefault {

    "frac"                      "<B<O/F"
    "sqrt"                      "<B<O/R"
    "one parameterÉ"            "<B<O/1"
    "two parametersÉ"           "<B<O/2"
}

# # ×××× "Greek" ×××× #
#
# ×××× "Binary Operators" ×××× #

array set TeX::MenuKeysDefault {

    "pm"                        "<I<U/+"
}

# # ×××× "Relations" ×××× #

array set TeX::MenuKeysDefault {

    "neq"                       "<I/="
}

# # ×××× "Arrows" ×××× #
#
# # ×××× "Dots" ×××× #
#
# # ×××× "Symbols" ×××× #

array set TeX::MenuKeysDefault {

    "emptyset"                  "/0<I"
}

# ×××× "Functions" ×××× #

array set TeX::MenuKeysDefault {

    "lim"                       "<B<O/L"
}

# ×××× "Large Operators" ×××× #

array set TeX::MenuKeysDefault  {

    "sum"                       "<B<O/S"
    "prod"                      "<B<O/P"
    "int"                       "<B<O/I"
}

# # ×××× "Delimiters" ×××× #
#
# ×××× "Math Accents" ×××× #

array set TeX::MenuKeysDefault  {

    "acute"                     "<B<O/A"
    "bar"                       "<B<O/B"
    "check"                     "<B<O/C"
    "dot"                       "<B<O/D"
    "grave"                     "<B<O/G"
    "hat"                       "<B<O/H"
    "tilde"                     "<B<O/T"
    "vec"                       "<B<O/V"
}

# ×××× "Grouping" ×××× #

array set TeX::MenuKeysDefault  {

    "underline"                 "<B<O/U"
    "overline"                  "<B<O/O"
    "underbrace"                "<B<I<O/U"
    "overbrace"                 "<B<I<O/O"
}

# # ×××× "Spacing" ×××× #

# ×××× -------- ×××× #

proc TeX::assignMenuBindings {{title "Select a menu:"} {includeFinish "0"}} {

    global TeX::ChangeableMenus TeX::MenuKeysDefault TeX::MenuKeysUser \
      menu::items menu::additions 

    set menuNames [set TeX::ChangeableMenus]
    if {$includeFinish} {set menuNames [concat [list "(Finish)"] $menuNames]}
    if {[catch {listpick -p $title $menuNames} menuName]} {
	error "cancel"
    } elseif {$menuName == "(Finish)"} {
        status::msg "The new bindings have been added to the TeX menu."
	return -code return
    }
    set menuItems [set menu::items($menuName)]
    if {[info exists menu::additions($menuName)]} {
        foreach item [set menu::additions($menuName)] {
	    if {[lindex $item 0] == "item"} {
		lappend menuItems [lindex $item 2]
	    }
	}
    } 
    foreach menuItem $menuItems {
        regsub {^([!<].)+} $menuItem "" menuItem
        if {[regexp {(^\(-\))|/} $menuItem]} {
	    # Either a divider, or the item has its own default binding
	    # which can't be changed.
            continue
        } elseif {[info exists TeX::MenuKeysUser($menuItem)]} {
            set menuBindings($menuItem) [set TeX::MenuKeysUser($menuItem)]
        } elseif {[info exists TeX::MenuKeysDefault($menuItem)]} {
            set menuBindings($menuItem) [set TeX::MenuKeysDefault($menuItem)]
        } else {
            set menuBindings($menuItem) ""
        }
    }
    set title "'[string trim $menuName]'  key bindings É"
    catch {dialog::arrayBindings $title menuBindings 1}

    set menuItems [set menu::items($menuName)]
    if {[info exists menu::additions($menuName)]} {
	foreach item [set menu::additions($menuName)] {
	    if {[lindex $item 0] == "item"} {
		lappend menuItems [lindex $item 2]
	    }
	}
    } 
    foreach menuItem $menuItems {
	regsub {^([!<].)+} $menuItem "" menuItem
        if {![info exists menuBindings($menuItem)]} {continue}
	set newBinding $menuBindings($menuItem)
	# Check to see if this is different from the previous binding.
	if {[info exists TeX::MenuKeysUser($menuItem)]} {
	    set defaultBinding [set TeX::MenuKeysUser($menuItem)]
	} elseif {[info exists TeX::MenuKeysDefault($menuItem)]} {
	    set defaultBinding [set TeX::MenuKeysDefault($menuItem)]
	} else {
	    set defaultBinding ""
	}
	if {$newBinding != $defaultBinding} {
	    set TeX::MenuKeysUser($menuItem) $newBinding
	    prefs::modified TeX::MenuKeysUser($menuItem)
	}
    }
    TeX::rebuildMenu
    # Now offer the list pick again.
    set title "Select another menu, or 'Finish'"
    if {[catch {TeX::assignMenuBindings $title 1}]} {
	status::msg "New bindings have been assigned, and appear in the TeX menus."
    } 
}

proc TeX::restoreDefaultBindings {} {
    
    global TeX::ChangeableMenus TeX::MenuKeysDefault TeX::MenuKeysUser \
      menu::items menu::additions

    set menuNames [set TeX::ChangeableMenus]
    # Now try to pare down the list.
    set menusWithUserBindings [list]
    foreach menuItem [array names TeX::MenuKeysUser] {
	foreach menuName $menuNames {
	    set menuItems [set menu::items($menuName)]
	    if {[info exists menu::additions($menuName)]} {
		foreach item [set menu::additions($menuName)] {
		    if {[lindex $item 0] == "item"} {
			lappend menuItems [lindex $item 2]
		    }
		}
	    } 
	    regsub -all {([!<].)+} $menuItems "" menuList
	    if {[lsearch $menuNames $menuItem] != "-1"} {
	        lappend menusWithUserBindings $menuName
		break
	    } 
	}
    }
    if {[llength $menusWithUserBindings]} {
        set menuNames [lunique $menusWithUserBindings]
    } else {
        status::msg "There are no user defined key bindings to unset."
	TeX::rebuildMenu
	return
    }
    set title  "Restore default bindings for these menus:"
    if {[catch {listpick -p $title -l $menuNames} menuNames]} {
	error "cancel"
    }
    foreach menuName $menuNames {
	set menuItems [set menu::items($menuName)]
	if {[info exists menu::additions($menuName)]} {
	    foreach item [set menu::additions($menuName)] {
		if {[lindex $item 0] == "item"} {
		    lappend menuItems [lindex $item 2]
		}
	    }
	} 
	foreach menuItem $menuItems {
	    regsub {^([!<].)+} $menuItem "" menuItem
	    if {[info exists TeX::MenuKeysUser($menuItem)]} {
		catch {unset TeX::MenuKeysUser($menuItem)}
		prefs::modified TeX::MenuKeysUser($menuItem)]
	    }
	}
    }
    TeX::rebuildMenu
    status::msg "The bindings for the selected menus have been restored to defaults."
}

# ==========================================================================
#
# .