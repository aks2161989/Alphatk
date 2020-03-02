## (indentationAmount:3)
## This is file `dialogsNew.tcl',
## generated with the docstrip utility.
##
## The original source files were:
##
## dialogsNew.dtx  (with options: `core')
## 
## ===================================================================
## AlphaTcl - core Tcl engine
## 
## Source file version data:
##                                    created: 12/1/96 {5:36:49 pm}
##                                last update: 03/10/2006 {02:23:12 PM}
##  Author: Vince Darley
##  E-mail: <vince@santafe.edu>
##    mail: 317 Paseo de Peralta, Santa Fe, NM 87501
##     www: <http://www.santafe.edu/~vince/>
##
##  Author: Lars Hellstr\"om
##  E-mail: <Lars.Hellstrom@math.umu.se>
##
##  Author: Jonathan Guyer
##  E-mail: <jguyer@his.com>
##  
## Copyright (c) 1997-2006  Vince Darley, Lars Hellstr\"om, Jonathan Guyer
## Distributed under Tcl style free license.
## ===================================================================
namespace eval dialog {}
if {${alpha::platform}=="alpha"} then {
   set code 0
   foreach w {0 6 12 12 6 14 11 14 0 4 16 14 14 0 6 6 9 11 11 9 11 6 6\
     16 12 9 12 11 13 6 6 6 4 6 7 10 7 11 10 3 5 5 7 7 4 7 4 7 8 8 8 8\
     8 8 8 8 8 8 4 4 6 8 6 8 11 8 8 8 8 7 7 8 8 6 7 9 7 12 9 8 8 8 8 7\
     6 8 8 12 8 8 8 5 7 5 8 8 6 8 8 7 8 8 6 8 8 4 6 8 4 12 8 8 8 8 6 7\
     6 8 8 12 8 8 8 5 5 5 8 6 8 8 8 7 9 8 8 8 8 8 8 8 8 7 8 8 8 8 4 4\
     4 4 8 8 8 8 8 8 8 8 8 8 5 6 7 9 7 7 9 8 10 10 11 6 6 9 11 8 14 7\
     6 6 8 10 8 9 10 11 6 7 7 10 12 8 8 6 7 12 6 8 9 9 9 14 8 8 8 8 11\
     12 6 10 7 7 4 4 7 9 8 8 3 8 6 6 10 10 5 4 4 7 15 8 7 8 7 7 6 6 6\
     6 8 8 11 8 8 8 8 4 6 8 6 6 6 6 6 6 6 6} {
      if {[info tclversion] < 8.1} then {
         set charwidth([format %c $code]) $w
      } else {
         set charwidth([encoding convertfrom macRoman [format %c $code]]) $w
      }
      incr code
   }
   proc dialog::text_width {str} {
      global charwidth
      set w 0
      foreach ch [split $str ""] {incr w $charwidth($ch)}
      set w
   }
} else {
   proc dialog::text_width {str} {screenToDistance [font measure system $str]}
}
if {${alpha::platform} == "alpha"} then {
   proc dialog::width_abbrev {str width {ratio 0.33}} {
      global charwidth dialog::ellipsis
      set w 0
      set tw [expr {$width - [dialog::text_width ${dialog::ellipsis}]}]
      set abbr ""
      set t [expr {$ratio * $tw}]
      foreach ch [split $str ""] {
         incr w $charwidth($ch)
         if {$w < $t} then {append abbr $ch}
      }
      if {$w <= $width} then {return $str}
      append abbr ${dialog::ellipsis}
      set t [expr {(1-$ratio) * $tw}]
      foreach ch [split $str ""] {
         if {$w < $t} then {append abbr $ch}
         incr w -$charwidth($ch)
      }
      set abbr
   }
} else {
   proc dialog::width_abbrev {str width {ratio 0.33}} {
      global dialog::ellipsis
      if {[screenToDistance [font measure system $str]] <= $width} then {return $str}
      set tw [expr {$width - [screenToDistance [font measure system ${dialog::ellipsis}]]}]
      set lower -1
      set upper [expr {[string length $str] - 1}]
      set t [expr {$ratio * $tw}]
      while {$upper - $lower > 1} {
         set middle [expr {($upper + $lower) / 2}]
         if {[screenToDistance [font measure system [string range $str 0 $middle]]] > $t}\
         then {set upper $middle} else {set lower $middle}
      }
      set abbr [string range $str 0 $lower]
      append abbr ${dialog::ellipsis}
      set upper [string length $str]
      set t [expr {(1 - $ratio) * $tw}]
      while {$upper - $lower > 1} {
         set middle [expr {($upper + $lower) / 2}]
         if {[screenToDistance [font measure system [string range $str $middle end]]] > $t}\
         then {set lower $middle} else {set upper $middle}
      }
      append abbr [string range $str $upper end]
   }
}
if {![info exists dialog::ellipsis]} then {
   if {[info tclversion] >= 8.1} then {
      set dialog::ellipsis \u2026
   } else {
      set dialog::ellipsis \xc9
   }
}
if {${alpha::platform} == "alpha"} {
    set dialog::strlength 253
} else {
    set dialog::strlength 2000
}
proc dialog::width_linebreak {str w} {
   if {![string length $str]} then {return {}}
   set res [list]
   foreach s [split $str \r] {
      lappend res \r
      foreach s2 [split $s \n] {
         eval [list lappend res]\
           [dialog::width_linebreak2 [string trim $s2] $w]
      }
   }
   lrange $res 1 end
}
if {${alpha::platform} == "alpha"} then {
   proc dialog::width_linebreak2 {str w} {
      global charwidth
      set res [list]
      set line ""
      set more ""
      set x 0
      set was 1
      foreach ch [split $str ""] {
         set is [expr {$ch==" " || $ch=="\t"}]
         if {!$is && $was} then {
            if {![string length $line]} then {
               set more ""
               set x 0
            }
            set x0 $x
         } elseif {$is && !$was} then {
            append line $more
            set more ""
         }
         set was $is
         incr x $charwidth($ch)
         if {$x>=$w} then {
            if {[string length $line]} then {
               lappend res $line
               set line ""
               set more [string trimleft $more]
               set x [expr {$x-$x0}]
            } else {
               lappend res $more
               set more ""
               set x $charwidth($ch)
            }
            set x0 0
         }
         append more $ch
      }
      set line [string trim "$line$more"]
      if {[string length $line]} then {lappend res $line}
      return $res
   }
} else {
   proc dialog::width_linebreak2 {str w} {
      set res [list]
      set idx -1
      while {[regexp -indices -start [expr {$idx+1}] -- {\S($|\s)} $str t]} {
         if {$w > [dialog::text_width\
             [string range $str 0 [lindex $t 0]]]} then {
            set idx [lindex $t 0]
         } elseif {$idx>=0} then {
            lappend res [string range $str 0 $idx]
            set str [string trim [string range $str [expr {$idx+1}] end]]
            set idx -1
         } else {
            set upper [lindex $t 0]
            set lower 0
            while {$upper-$lower>1} {
               set middle [expr {($upper+$lower)/2}]
               if {$w > [dialog::text_width\
                   [string range $str 0 $middle]]}\
               then {set lower $middle} else {set upper $middle}
            }
            lappend res [string range $str 0 $lower]
            set str [string trim [string range $str [expr {$lower+1}] end]]
            set idx -1
         }
      }
      if {$idx>=0} then {lappend res [string range $str 0 $idx]}
      return $res
   }
}
ensureset dialog::globalCount 0
proc dialog::create {} {
    global dialog::globalCount
    incr dialog::globalCount
    upvar #0 "dialog::changed_tcldial${dialog::globalCount}" chvar
    set chvar [list]
    return "tcldial${dialog::globalCount}"
}
proc dialog::cleanup {mod} {
    global dialog::${mod} dialog::changed_${mod}
    if {[info exists dialog::${mod}]} {
        unset dialog::${mod}
    }
    if {[info exists dialog::changed_${mod}]} {
        unset dialog::changed_${mod}
    }
}
proc dialog::valGet {mod name} {
    uplevel #0 [list set dialog::${mod}($name)]
}
proc dialog::valSet {mod name val} {
    uplevel #0 [list set dialog::${mod}($name) $val]
}
proc dialog::valExists {mod name} {
    uplevel #0 [list info exists dialog::${mod}($name)]
}
proc dialog::valChanged {mod name val} {
   global dialog::${mod} dialog::changed_${mod}
   if {![info exists dialog::${mod}($name)] \
     || ($val ne [set dialog::${mod}($name)])} {
       set dialog::${mod}($name) $val
       lunion dialog::changed_${mod} $name
   }
}
proc dialog::changed_items {mod} {
    uplevel #0 [list set dialog::changed_${mod}]
}
proc dialog::handle {pages typevar dial helpvar pagevar optionL args} {
   global dialog::indentsame dialog::indentnext dialog::simple_type\
     dialog::complex_type alpha::platform
   variable pager
   upvar 1 $typevar typeA $helpvar helpA $pagevar currentpage
   if {![info exists currentpage]} then {
      set currentpage [lindex $pages 0]
   }
   metrics Metrics
   set opts(-title) ""
   set opts(-width) 400
   set opts(-pager) "popupmenu"
   array set opts $optionL
   if {[info exists opts(-geometryvariable)]} {
      upvar 1 $opts(-geometryvariable) geometryA
   }
   set multipage 0
   while {1} {
      set res [list]
      set ymax 4
      if {!$multipage} {
         set multipage [expr {[llength $pages] > 2}]
      }
      # Need to clean up and then document in dialogsNew.dtx the
      # handling of these edges/offsets for different pager
      # types.
      set rightEdge [expr {$opts(-width) - 10}]
      set buttonLeft 20
      set buttonOffset 0
      if {$multipage} {
         eval [lindex $pager($opts(-pager)) 0]
      } else {
         set leftEdge 20
         set topEdge 42
      }
      set left $leftEdge
      set right $rightEdge
      set pagemenu [list $currentpage]
      set helpL [list]
      set postprocL [list]
      foreach {page items} $pages {
         set visualpagename $page
         if {$multipage} then {
            if {$visualpagename eq ""} {
               set visualpagename "Page"

               set vpname "$visualpagename (1)"
               set pagemap($vpname) $page
            } else {
               set vpname $visualpagename
            }
            lappend res -n $vpname
            lappend pagemenu $vpname
            if {[info exists singlepage]} { break }
            set y $topEdge
         } elseif {$page eq ""} {
            set y 10
            set singlepage 1
         } else {
            set y 38
            set singlepage 1
         }
         foreach name $items {
            set type $typeA($page,$name)
            set val [dialog::valGet $dial $page,$name]
            set help {}
            catch {set help $helpA($page,$name)}
            set script [list dialog::valChanged $dial $page,$name]
            append script { [lindex $res $count]}
            set visible 1
            while {1} {
               if {[llength $type] == 1} then {
                  if {![info exists dialog::simple_type($type)]}\
                  then {set type var}
                  eval [set dialog::simple_type($type)]
               } elseif {[info exists\
                    dialog::complex_type([lindex $type 0])]} then {
                  eval [set dialog::complex_type([lindex $type 0])]
               } else {
                  dialog::cleanup $dial
                  error "Unsupported item type '$type'"
               }
               break
            }
            if {$visible} then {
               incr y 7
               if {[info exists help]} {lappend helpL $help}
            }
            lappend postprocL $script
         }
         if {$y > $ymax} {set ymax $y}
      }
      if {[info exists singlepage] && $multipage} {
         unset singlepage
         continue
      }
      incr ymax 6
      set buttons [list]
      set button_help [list]
      set button_press [list]
      # extra for multipage controls
      set left $buttonLeft
      set right [expr {$opts(-width) - 10}]
      incr ymax $buttonOffset
      set l $left
      set r $right
      foreach group $args {
         set b_names [list]
         set b_help [list]
         set b_press [list]
         foreach {name help val} [lindex $group 0] {
            lappend b_names $name
            lappend b_help $help
            lappend b_press $val
         }
         set group [lrange $group 1 end]
         set b_names [dialog::makeSomeButtons $b_names\
           [expr {[lsearch -exact $group "right"] >= 0}]\
           $left l r $right ymax]
         if {[lsearch -exact $group "first"] < 0} then {
            eval [list lappend buttons] $b_names
            eval [list lappend button_help] $b_help
            eval [list lappend button_press] $b_press
         } else {
            set buttons [concat $b_names $buttons]
            set button_help [concat $b_help $button_help]
            set button_press [concat $b_press $button_press]
         }
      }
      if {![llength $button_press]} then {
         dialog::cleanup $dial
         error "No buttons in dialog."
      }
      incr ymax 33
      if {$multipage} then {
         set help {}
         eval [lindex $pager($opts(-pager)) 1]
         set res [concat $pageitem $buttons $res]
         set helpL [concat $help $button_help $helpL]
      } else {
         set title_width [dialog::text_width $currentpage]
         if {$title_width > 200} {
            set border [expr {($opts(-width) - $title_width)/2}]
            if {$border < 0} { set border 0 }
            set l $border
            set r [expr {$opts(-width) - $border}]
         } else {
            set l 100
            set r 300
         }
         if {[llength $pages]} then {
            set currentpage [lindex $pages 0]
            set res [concat [list -t $currentpage $l 10 $r 25]\
              $buttons $res]
         } else {
            set res [concat $buttons $res]
         }
         set helpL [concat $button_help $helpL]
      }
      set dialCmd [list dialog -w $opts(-width) -h $ymax\
        -T $opts(-title)]
      if {$alpha::platform == "tk"} {
         lappend dialCmd -geometryvariable geometryA
      }
      set res [eval $dialCmd $res [list -help $helpL]]
      if {$multipage} then {
         set currentpage [lindex $res 0]
         if {[info exists pagemap($currentpage)]} {
            set currentpage $pagemap($currentpage)
            lset res 0 $currentpage
         }
         eval [lindex $pager($opts(-pager)) 2]
      } else {
         set res [linsert $res 0 $currentpage]
      }
      set count [expr {[llength $button_press] + 1}]
      foreach script $postprocL {
         eval $script
         incr count
      }
      set count [lsearch -exact\
        [lrange $res 1 [llength $button_press]] 1]
      if {$count>=0} then {return [lindex $button_press $count]}
   }
}
if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.0]} {
   proc dialog::switchPane {dialogItemIDs} {
       set pane [getControlValue [lindex $dialogItemIDs 0]]
       setControlValue [lindex $dialogItemIDs 1] $pane
   }
   set dialog::pager(popupmenu) {
      {
         set leftEdge 20
         set topEdge 42
      }
      {
         set pageitem [list -m $pagemenu 100 10 300\
           [expr {$Metrics(PopupButtonHeight) + 15}]]
         set help [list "Use this popup menu or the cursor keys to go to\
           a different page of the dialog."]
      }
      {
         # Nothing
      }
   }
   set dialog::pager(listbox) {
      {
         set leftEdge 10
         set topEdge 14
         set rightEdge [expr {$opts(-width) - 220}]
         set buttonLeft 210
         set buttonOffset 10
      }
      {
         # Use '-action' on listitem to control
         # a separate multipane dialog item.
         set pageitem [list -listitem $pagemenu {active scrolled} {} \
           -action {dialog::switchPane {+0 pager}} \
           10 10 180 [expr {$ymax - 10}] \
           -multipane $pagemenu -tag pager 200 $topEdge \
           [expr {$opts(-width) - 20}] [expr {$ymax - 10}]]
         set help [list "Use this list or the cursor keys to go to\
           a different page of the dialog." {}]
      }
      {
         # We have both the listitem and the multipane returning a
         # value, so remove the second of them.
         set res [lreplace $res 1 1]
      }
   }
   set dialog::pager(tabs) {
      {
         set leftEdge 10
         set topEdge 14
         set rightEdge [expr {$opts(-width) - 40}]
         set buttonOffset 30
      }
      {
         set pageitem [list -tab $pagemenu \
           20 10 [expr {$opts(-width) - 20}] \
           [expr {$Metrics(PopupButtonHeight) + 15}]]
         set help [list "Use these tabs or the cursor keys to go to\
           a different page of the dialog."]
      }
      {
         # Nothing
      }
   }
} else {
   set dialog::pager(popupmenu) {
      {
         set leftEdge 20
         set topEdge 42
      }
      {
         set pageitem [list -m $pagemenu 100 10 300\
           [expr {$Metrics(PopupButtonHeight) + 15}]]
         set help [list "Use this popup menu or the cursor keys to go to\
           a different page of the dialog."]
      }
      {
         # Nothing
      }
   }
}
proc dialog::makeSomeButtons {titleL justification xmin leftvar\
  rightvar xmax yvar {minwidth 58}} {
   upvar 1 $leftvar left $rightvar right $yvar y
   set widthL [list]
   if {[llength $titleL] == 0} {
      return [list]
   }
   foreach title $titleL {
      set w [expr {[dialog::text_width $title] + 17}]
      if {$w < $minwidth} then {set w $minwidth}
      lappend widthL $w
   }
   if {[expr [join $widthL "+13+"]] > $right - $left &&\
     ($xmin<$left || $right<$xmax)} then {
      incr y 33
      set left $xmin
      set right $xmax
   }
   set n 0
   foreach title $titleL {
      set w [lindex $widthL $n]
      incr n
      if {$w > $right - $left && ($xmin<$left || $right<$xmax)} then {
         incr y 33
         set left $xmin
         set right $xmax
      }
      lappend res -b $title
      if {$justification} then {
         lappend res [expr {$right-$w}] $y $right [expr {$y+20}]
         set right [expr {$right - $w - 13}]
      } else {
         lappend res $left $y [incr left $w] [expr {$y+20}]
         incr left 13
      }
   }
   set res
}
set dialog::indentsame 80
set dialog::indentnext 40
proc dialog::makeEditItem {mvar svar left right yvar name val {lines 1}\
  {minwidth 110} {maxwidth {}}} {
    upvar 1 $mvar M $yvar y
    global dialog::indentsame dialog::indentnext
    if {$maxwidth==""} then {set maxwidth [expr {$right-$left}]}
    set nw [expr {[dialog::text_width $name] + 2}]
    if {$nw<${dialog::indentsame}-13} then {
        set nw [expr {${dialog::indentsame}-13}]
    }
    if {$lines == 1 && $nw+19+$minwidth < $right-$left ||\
      $nw+19+$maxwidth <= $right-$left} then {
        incr y 3
        lappend M -t $name $left $y [expr {$left+$nw}] [expr {$y+15}]
        set ew [expr {$right - $left - $nw - 19}]
        if {$ew>$maxwidth} then {set $ew $maxwidth}
        lappend M -e $val [expr {$left+$nw+16}] $y\
          [expr {$left+$nw+$ew+16}] [expr {$y + 16*$lines - 1}]
    } else {
        lappend M -t $name $left $y [expr {$left+$nw}] [expr {$y+15}]
        incr y 20
        set ew [expr {$right - $left - ${dialog::indentnext} - 6}]
        if {$ew>$maxwidth} then {set $ew $maxwidth}
        lappend M -e $val [expr {$right - 3 - $ew}] [incr y 4]\
          [expr {$right - 3}] [expr {$y + 16*$lines - 1}]
    }
    set y [expr {$y + 16*$lines + 2}]
}
array set dialog::simple_type {var\
  {dialog::makeEditItem res script $left $right y $name $val}}
array set dialog::simple_type {var2\
  {dialog::makeEditItem res script $left $right y $name $val 2}}
array set dialog::simple_type {password {
   if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
      eval $::dialog::simple_type(var)
      set res [linsert $res end-4 -password]
   } else {
      set nw [expr {[dialog::text_width $name] + 1}]
      lappend res -t $name $left $y [expr {$left + $nw}] [expr {$y + 15}]
      incr nw 13
      if {$nw<${dialog::indentsame}} then {set nw ${dialog::indentsame}}
      regsub -all {.} $val { } vv
      lappend res -e $vv [expr {$left + $nw + 3}] [expr {$y + 6}]\
        [expr {$right - 3}] [expr {$y + 7}]
      incr y 15
      set script [list set T $page,$name]
      append script {
         regsub -all {.} [dialog::valGet $dial $T] { } vv
         if {[string compare $vv [lindex $res $count]]} then {
            dialog::valChanged $dial $T [lindex $res $count]
         }
      }
   }
}}
proc dialog::lines_to_text {lineL left right yvar} {
   upvar 1 $yvar y
   global dialog::strlength
   set res [list]
   set item_lines [list]
   set item_length -1
   foreach line $lineL {
      if {$line!="\r"} then {
         incr item_length [expr {1 + [string length $line]}]
         if {${dialog::strlength}<$item_length} then {
            lappend res -t [join $item_lines \r] $left $y $right\
              [incr y [expr {[llength $item_lines] * 16}]]
            set item_lines [list $line]
            set item_length [string length $line]
         } else {
            lappend item_lines $line
         }
      } else {
         if {[llength $item_lines]} then {
            lappend res -t [join $item_lines \r] $left $y $right\
              [incr y [expr {[llength $item_lines] * 16}]]
         }
         incr y 6
         set item_lines [list]
         set item_length -1
      }
   }
   if {[llength $item_lines]} then {
      lappend res -t [join $item_lines \r] $left $y $right\
        [incr y [expr {[llength $item_lines] * 16}]]
   }
   if {[llength $res]} then {incr y -1}
   return $res
}
array set dialog::simple_type {text {
    eval [list lappend res] [dialog::lines_to_text\
      [dialog::width_linebreak $name [expr {$right-$left}]]\
      $left $right y]
    unset help
    set script {continue}
}}
array set dialog::simple_type {static {
    set nw [expr {[dialog::text_width $name] + 1}]
    if {$nw<${dialog::indentsame}-13} then {
        set nw [expr {${dialog::indentsame}-13}]
    }
    lappend res -t $name $left $y [expr {$left+$nw}] [expr {$y+15}]
    set vw [expr {[dialog::text_width $val] + 1}]
    lappend res -t $val
    if {$nw + 13 + $vw < $right - $left} then {
        lappend res [expr {$left + $nw + 13}] $y
    } else {
        incr y 16
        lappend res [expr {$left + ${dialog::indentnext}}] $y
    }
    lappend res $right [incr y 15]
    unset help
    set script {continue}
}}
if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.0]} {
   array set dialog::simple_type {divider {
      lappend res -separator $left $y $right [incr y 3]
      unset help
      set script {continue}
   }}
} else {
   array set dialog::simple_type {divider {
      lappend res -t [string repeat "-" 1000] $left $y $right [incr y 12]
      unset help
      set script {continue}
   }}
}
set dialog::mute_types [list text static divider]
array set dialog::simple_type {flag {
    lappend res -c $name $val
    lappend res $left $y $right [incr y 15]
}}
array set dialog::complex_type {multiflag {
   eval [list lappend res] [dialog::lines_to_text\
     [dialog::width_linebreak $name [expr {$right-$left}]]\
     $left $right y]
   set flag_list [lindex $type 1]
   set columns   [lindex $type 2]
   if {![string length $columns]} {
      set columns 2
   }
   set i [expr {($left + $right - 30)/$columns}]
   for {set c 1} {$c <= $columns} {incr c} {
      set l$c [expr {(($c - 1) * $i) + 20}]
      set r$c [expr {($c * $i) + 5}]
      set y$c $y
   }
   if {([lindex $type 3] == 1)} {
      # Order across rows.
      for {set c 0 ; set n 0} {$n < [llength $flag_list]} {incr n} {
         set c [expr {$c % $columns + 1}]
         lappend res -c [lindex $flag_list $n] [lindex $val $n]
         lappend res -font 2
         lappend res [set l$c] [incr y$c 8] [set r$c] [incr y$c 15]
      }
   } else {
      # Order down columns.
      set defaultRows [expr {[llength $flag_list] / $columns}]
      set remainder   [expr {[llength $flag_list] % $columns}]
      set count 0
      for {set c 1} {$c <= $columns} {incr c} {
         set offset [expr {$remainder > 0 ? 1 : 0}]
         set cR$c   [expr {$defaultRows + $offset}]
         incr remainder -1
      }
      set cR $cR1
      for {set c 1 ; set n 0} {$n < [llength $flag_list]} {incr n} {
         if {(($n + 1) > $cR)} {
            incr c ; incr cR [set cR$c]
         }
         lappend res -c [lindex $flag_list $n] [lindex $val $n]
         lappend res -font 2
         lappend res [set l$c] [incr y$c 8] [set r$c] [incr y$c 15]
      }
   }
   set y [expr {$y1 + 5}]
   while {[llength $help]<[llength $flag_list]} {lappend help ""}
   eval [list lappend helpL] $help
   unset help
   set script    [list dialog::valChanged $dial $page,$name]
   append script { [lrange $res $count [incr count }
   append script [expr {[llength $flag_list] - 1}] {]]}
}}
proc dialog::makeMenuItem {mvar svar left right yvar name itemL value} {
    upvar 1 $mvar M $yvar y
    global dialog::indentsame dialog::indentnext
    set nw [expr {[dialog::text_width $name]+1}]
    if {([lsearch -exact $itemL $value] == -1)} {
       if {($value ne "")} {
          alpha::stderr "Invalid default value specified\
            for \[dialog::makeMenuItem\] (pop-up menu)\
            \r  name:  $name\
            \r  list:  $itemL\
            \r  value: $value"
       }
       set value [lindex $itemL 0]
    }
    set itemL [linsert $itemL 0 $value]
    if {$nw<${dialog::indentsame}} then {set nw ${dialog::indentsame}}
    if {$right - $left - $nw < 50} then {
       lappend M -t $name $left $y [expr {$left+$nw}] [incr y 15]
       incr y 5
       lappend M -m $itemL [expr {$left+${dialog::indentnext}+1}]
    } else {
       incr y
       lappend M -t $name $left $y [expr {$left+$nw}] [expr {$y+15}]
       lappend M -m $itemL [expr {$left+$nw+14}]
    }
    metrics Metrics
    set menuWidth 30
    foreach item $itemL {
        if {([set newWidth [dialog::text_width $item]] > $menuWidth)} {
            set menuWidth $newWidth
        }
    }
    set menuRight [expr {$menuWidth + $left + $nw + 55}]
    if {$menuRight > ($right -2 )} {
        set menuRight [expr {$right - 2}]
    }
    lappend M $y $menuRight [incr y [expr {$Metrics(PopupButtonHeight) + 5}]]
}
array set dialog::complex_type {menu\
  {dialog::makeMenuItem res script $left $right y $name\
    [lindex $type 1] $val}}
array set dialog::simple_type {colour {
    global alpha::colors
    dialog::makeMenuItem res script $left $right y $name\
      ${alpha::colors} $val
} mode {
    dialog::makeMenuItem res script $left $right y $name\
      [linsert [mode::listAll] 0 "<none>"] $val
}}
array set dialog::complex_type {menuindex {
    set script [list dialog::valChanged $dial $page,$name]
    append script { [} [list lsearch -exact [lindex $type 1]]
    append script { [lindex $res $count]]}
    catch {lindex [lindex $type 1] $val} val
    dialog::makeMenuItem res script $left $right y $name\
      [lindex $type 1] $val
}}
proc dialog::makeSetItem {Mvar Svar left right yvar name bscript\
  {cond {[info tclversion]>=8.0}}} {
   upvar 1 $Mvar M $Svar S $yvar y
   global dialog::ellipsis dialog::indentsame
   set nw [expr {[dialog::text_width $name]+5}]
   set bw [expr {[dialog::text_width "Set${dialog::ellipsis}"] + 21}]
   lappend M -t $name $left $y [expr {$left + $nw}] [expr {$y + 15}]
   lappend M -b "Set${dialog::ellipsis}"
   if $cond then {
      lappend M -set [list $bscript +1]
      set S {}
   } else {
      set S [list if {[lindex $res $count] == 1} then $bscript]
   }
   lappend M [expr {$right - $bw}] $y $right [expr {$y + 15}]
   set nw [expr {$nw+13}]
   if {$nw<${dialog::indentsame}} then {set nw ${dialog::indentsame}}
   list [expr {$left + $nw}] $y [expr {$right - $bw - 13}] [incr y 15]
}
proc dialog::makeStaticValue\
  {left right yvar value subopt {ratio 0.33} {rect {0 0 0 0}}} {
   global dialog::indentnext alpha::platform
   upvar 1 $yvar y
   set vw [expr {[dialog::text_width $value] + 1}]
   if {[lindex $rect 2] - [lindex $rect 0] >= $vw} then {
      set res [list -t $value]
      if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} then {
         set res [concat $res $subopt]
      }
      if {[lindex $rect 3] > $y} then {set y [lindex $rect 3]}
      concat $res $rect
   } else {
      set res [list -t]
      lappend res [dialog::width_abbrev $value\
        [expr {$right - $left - ${dialog::indentnext} - 1}] $ratio]
      if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} then {
         set res [concat $res $subopt]
         incr y
      } else {
         incr y 5
      }
      lappend res [expr {$left + ${dialog::indentnext}}] $y\
        $right [incr y 15]
   }
}
array set dialog::simple_type {binding {
    set R [dialog::makeSetItem res script $left $right y $name\
      [list dialog::specialSet::binding [list $dial "$page,$name" binding]]]
    set vv [dialog::specialView::binding $val]
    eval [list lappend res]\
      [dialog::makeStaticValue $left $right y $vv {} 0.33 $R]
} menubinding {
    set R [dialog::makeSetItem res script $left $right y $name\
      [list dialog::specialSet::menubinding [list $dial "$page,$name" menubinding]]]
    set vv [dialog::specialView::menubinding $val]
    eval [list lappend res]\
      [dialog::makeStaticValue $left $right y $vv {} 0.33 $R]
}}
array set dialog::simple_type {file {
    set R [dialog::makeSetItem res script $left $right y $name\
      [list dialog::specialSet::file [list $dial "$page,$name" file]]]
    eval lappend res\
      [dialog::makeStaticValue $left $right y $val\
      [list "-drop" [dialog::makeDropArgList \
      [dialog::makeItemInfo $dial "$page,$name" $type]]] 0.33 $R]
} folder {
    set R [dialog::makeSetItem res script $left $right y $name\
      [list dialog::specialSet::folder [list $dial "$page,$name" folder]]]
    eval lappend res\
      [dialog::makeStaticValue $left $right y $val\
      [list "-drop" [dialog::makeDropArgList \
      [dialog::makeItemInfo $dial "$page,$name" folder]]] 0.33 $R]
} io-file {
    set R [dialog::makeSetItem res script $left $right y $name\
      [list dialog::specialSet::io-file [list $dial "$page,$name" io-file]]]
    eval lappend res\
      [dialog::makeStaticValue $left $right y $val\
      [list "-drop" [dialog::makeDropArgList \
      [dialog::makeItemInfo $dial "$page,$name" $type]]] 0.33 $R]
} url {
    set R [dialog::makeSetItem res script $left $right y $name\
      [list dialog::specialSet::url [list $dial "$page,$name" url]]]
    eval lappend res\
      [dialog::makeStaticValue $left $right y $val\
      [list "-drop" [dialog::makeDropArgList \
      [dialog::makeItemInfo $dial "$page,$name" $type]]] 0.33 $R]
}\
  date {
    set R [dialog::makeSetItem res script $left $right y $name\
      [list dialog::specialSet::date [list $dial "$page,$name" date]]]
    eval lappend res\
      [dialog::makeStaticValue $left $right y [clock format $val]\
        {} 1 $R]
}}
array set dialog::simple_type {appspec {
   if {${alpha::platform} == "alpha" &&\
      [regexp {^'(....)'$} $val "" sig]} then {
        if {[catch {nameFromAppl $sig} vv]} then {
           set vv "Unknown application with sig '$sig'"
        }
    } else {
        set vv $val
    }
    set R [dialog::makeSetItem res script $left $right y $name\
      [list dialog::specialSet::sig [list $dial "$page,$name" appspec]]]
    eval lappend res\
      [dialog::makeStaticValue $left $right y $vv\
      [list "-drop" [dialog::makeDropArgList \
      [dialog::makeItemInfo $dial "$page,$name" appspec]]] 0.33 $R]
}}
if {![alpha::package vsatisfies [dialog::coreVersion] 2.1]} then {
   array set dialog::simple_type {searchpath {
      set R [dialog::makeSetItem res script $left $right y $name\
        [list dialog::specialSet::searchpath [list $dial "$page,$name" searchpath]] 0]
      if {![llength $val]} then {
         eval [list lappend res]\
           [dialog::makeStaticValue $left $right y\
             "No search paths currently set." {} 1 $R]
      } else {
         foreach path $val {
            eval [list lappend res]\
              [dialog::makeStaticValue $left $right y $path {}]
         }
      }
   }}
} else {
   array set dialog::simple_type {searchpath {
      set itemInfo [dialog::makeItemInfo $dial "$page,$name" searchpath]
      dialog::makeSetItem res script $left $right y $name\
        [list dialog::specialSet::searchpath $itemInfo]
      lappend res "-l" $val 3
      set script {incr count}
      lappend res "-drop" [dialog::makeDropArgList $itemInfo]
      lappend res [expr {$left + ${dialog::indentnext}}] [incr y 5]\
        $right [incr y 90]
      lappend helpL {}
   }}
}
if {![alpha::package vsatisfies [dialog::coreVersion] 2.1]} then {
   array set dialog::simple_type {filepaths {
      set R [dialog::makeSetItem res script $left $right y $name\
	[list dialog::specialSet::filepaths [list $dial "$page,$name" filepaths]] 0]
      if {![llength $val]} then {
	 eval [list lappend res]\
	   [dialog::makeStaticValue $left $right y\
	     "No file paths currently set." {} 1 $R]
      } else {
	 foreach path $val {
	    eval [list lappend res]\
	      [dialog::makeStaticValue $left $right y $path {}]
	 }
      }
   }}
} else {
   array set dialog::simple_type {filepaths {
      set itemInfo [dialog::makeItemInfo $dial "$page,$name" filepaths]
      dialog::makeSetItem res script $left $right y $name\
	[list dialog::specialSet::filepaths $itemInfo]
      lappend res "-l" $val 3
      set script {incr count}
      lappend res "-drop" [dialog::makeDropArgList $itemInfo]
      lappend res [expr {$left + ${dialog::indentnext}}] [incr y 5]\
	$right [incr y 90]
      lappend helpL {}
   }}
}
proc dialog::edit_subset {setL dial page name prompt} {
   if {![catch {
      listpick -p $prompt -l -L [dialog::valGet $dial $page,$name] $setL
   } res]} then {
      set val [list]
      catch {
          foreach item $res {lappend val $item}
          dialog::valChanged $dial $page,$name $val
      }
   }
}
array set dialog::complex_type {subset {
    dialog::makeSetItem res script $left $right y $name\
      [list dialog::edit_subset [lindex $type 1] $dial $page $name\
        "Edit subset"]
    eval [list lappend res]\
      [dialog::makeStaticValue $left $right y $val {} 1]
}}
array set dialog::simple_type {modeset {
    dialog::makeSetItem res script $left $right y $name\
      [list dialog::edit_subset [mode::listAll] $dial $page $name\
        "Select modes"]
    eval [list lappend res]\
      [dialog::makeStaticValue $left $right y $val {} 1]
}}
array set dialog::complex_type {prefItemType {
    set type [dialog::prefItemType [lindex $type 1]]
    continue
}}
array set dialog::simple_type {thepage {
   set script [list dialog::valChanged $dial $page,$name]
   append script { $currentpage
      continue
   }
   set visible 0
}}
array set dialog::complex_type {smallval {
   if {![info exists ::dialog::simple_type([lindex $type 1])]} {
      error "The \"small\" complex type can only be used in conjuction\
        with \"simple\" dialog types."
   }
   switch -- [lindex $type 1] {
      "application" -
      "appspec" -
      "binding" -
      "date" -
      "file" -
      "folder" -
      "io-file" -
      "menubinding" -
      "mode" -
      "modeset" -
      "password" -
      "static" -
      "url" -
      "xhelper" {
         eval $::dialog::simple_type([lindex $type 1])
         set res [linsert $res end-4 -font 2]
      }
      "flag" {
         dialog::metrics Metrics
         set flagWidth [expr {$right - $left - $Metrics(CheckBoxWidth)}]
         set flagBounds [getTextDimensions -font -2 -width $flagWidth $name]
         set flagHeight [expr {-[lindex $flagBounds 1]+[lindex $flagBounds 3]}]
         if {$flagHeight < $Metrics(CheckBoxHeight)} {
             set flagHeight $Metrics(CheckBoxHeight)
         }
         lappend res -c $name $val -font 2 \
           $left $y $right [incr y $flagHeight]
         incr y $Metrics(TightCheckBoxSpacingY)
      }
      "filepaths" - "searchpath" {
         eval $::dialog::simple_type([lindex $type 1])
         if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
            set res [linsert $res end-4  -font 2]
         } else {
            if {[llength $val]} {
               set lval [llength $val]
            } else {
               set lval 1
            }
            for {set i $lval} {($i >= 1)} {incr i -1} {
               set res [linsert $res end-[expr {4+ (($i - 1) * 6)}] -font 2]
            }
            unset i lval
         }
      }
      "text" {
         dialog::metrics Metrics
         set width [expr {$right - $left}]
         set bounds [getTextDimensions -font -2 -width $width $name]
         set height [expr {-[lindex $bounds 1]+[lindex $bounds 3]}]
         lappend res -t $name -font 2 $left $y $right [incr y $height]
      }
      default {
         eval $::dialog::simple_type([lindex $type 1])
      }
   }
}}
array set dialog::complex_type {smallall {
   if {![info exists ::dialog::simple_type([lindex $type 1])]} {
      error "The \"small\" complex type can only be used in conjuction\
        with \"simple\" dialog types."
   }
   switch -- [lindex $type 1] {
      "application" -
      "binding" -
      "date" -
      "menubinding" -
      "modeset" -
      "xhelper" {
         eval $::dialog::simple_type([lindex $type 1])
         set res [linsert $res end-18 -font 2]
         set res [linsert $res end-10 -font 2]
         set res [linsert $res end-4  -font 2]
      }
      "appspec" -
      "file" -
      "folder" -
      "io-file" -
      "url" {
         if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
            eval $::dialog::simple_type([lindex $type 1])
            set res [linsert $res end-20 -font 2]
            set res [linsert $res end-12 -font 2]
            set res [linsert $res end-4  -font 2]
         } else {
            eval $::dialog::simple_type([lindex $type 1])
            set res [linsert $res end-18 -font 2]
            set res [linsert $res end-10 -font 2]
            set res [linsert $res end-4  -font 2]
         }
      }
      "colour" -
      "var" -
      "var2" {
         eval $::dialog::simple_type([lindex $type 1])
         set res [linsert $res end-10 -font 2]
      }
      "flag" {
         dialog::metrics Metrics
         set flagWidth [expr {$right - $left - $Metrics(CheckBoxWidth)}]
         set flagBounds [getTextDimensions -font -2 -width $flagWidth $name]
         set flagHeight [expr {-[lindex $flagBounds 1]+[lindex $flagBounds 3]}]
         if {$flagHeight < $Metrics(CheckBoxHeight)} {
             set flagHeight $Metrics(CheckBoxHeight)
         }
         lappend res -c $name $val -font 2 \
           $left $y $right [incr y $flagHeight]
         incr y $Metrics(TightCheckBoxSpacingY)
      }
      "text" {
         dialog::metrics Metrics
         set width [expr {$right - $left}]
         set bounds [getTextDimensions -font -2 -width $width $name]
         set height [expr {-[lindex $bounds 1]+[lindex $bounds 3]}]
         lappend res -t $name -font 2 $left $y $right [incr y $height]
      }
      "mode" -
      "password" -
      "static" {
         eval $::dialog::simple_type([lindex $type 1])
         set res [linsert $res end-10 -font 2]
         set res [linsert $res end-4  -font 2]
      }
      "filepaths" - "searchpath" {
         eval $::dialog::simple_type([lindex $type 1])
         if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
            set res [linsert $res end-21 -font 2]
            set res [linsert $res end-13 -font 2]
            set res [linsert $res end-4  -font 2]
         } else {
            if {[llength $val]} {
               set lval [llength $val]
            } else {
               set lval 1
            }
            set res [linsert $res end-[expr 10 + {$lval * 6}] -font 2]
            set res [linsert $res end-[expr  4 + {$lval * 6}] -font 2]
            for {set i $lval} {($i >= 1)} {incr i -1} {
               set res [linsert $res end-[expr {4+ (($i - 1) * 6)}] -font 2]
            }
            unset i lval
         }
      }
      default {
         eval $::dialog::simple_type([lindex $type 1])
      }
   }
}}
proc dialog::hide_item {page item {typevar typeA}} {
   upvar 1 $typevar typeA
   if {[lindex $typeA($page,$item) 0]!="hidden"} then {
       set typeA($page,$item) [linsert $typeA($page,$item) 0 hidden]
   }
}
proc dialog::show_item {page item {typevar typeA}} {
   upvar 1 $typevar typeA
   if {[lindex $typeA($page,$item) 0]=="hidden"} then {
      set typeA($page,$item) [lreplace $typeA($page,$item) 0 0]
   }
}
array set dialog::complex_type {hidden {
   set script {continue}
   set visible 0
}}
array set dialog::complex_type {geometry {
    set R [dialog::makeSetItem res script $left $right y $name\
      [list dialog::specialSet::asyncGeometry [lindex $type 1] \
      [list $dial "$page,$name" geometry]]]
    set vv [dialog::specialView::geometry $val]
    eval lappend res\
      [dialog::makeStaticValue $left $right y $vv {} 0.33 $R]
}}
array set dialog::complex_type {discretionary {
   set script {continue}
   unset help
   if {$y<=[lindex $type 1]} then {
      if {[string length [lindex $type 4]]} then {
         eval [list lappend res] [dialog::lines_to_text\
           [dialog::width_linebreak [lindex $type 4]\
             [expr {$right-$left}]]\
           $left $right y]
      } else {
         set visible 0
      }
   } else {
      if {!$multipage} then {
         set pagemenu [list $currentpage $page]
         set res [linsert $res 0 -n $page]
         set multipage 1
      }
      if {[string length [lindex $type 2]]} then {
         eval [list lappend res] [dialog::lines_to_text\
           [dialog::width_linebreak [lindex $type 2]\
             [expr {$right-$left}]]\
           $left $right y]
         incr y 7
      }
      if {$y>$ymax} then {set ymax $y}
      set y $topEdge
      if {$page ne $visualpagename \
        || ![string equal $visualpagename [lindex $pagemenu end]]} then {
         regexp {\(([0-9]+)\)$} [lindex $pagemenu end] -> T
         set T "$visualpagename ([incr T])"
      } else {
         set T "$page (2)"
      }
      set pagemap($T) $page
      lappend res -n $T
      lappend pagemenu $T
      if {[string length [lindex $type 3]]} then {
         eval [list lappend res] [dialog::lines_to_text\
           [dialog::width_linebreak [lindex $type 3]\
             [expr {$right-$left}]]\
           $left $right y]
      } else {
         set visible 0
      }
   }
}}
lappend dialog::mute_types discretionary
array set dialog::complex_type {flaggroup {
   dialog::build_flaggroup res script $dial $type $page $name\
     y $left $right helpL helpA
   unset help
}}
lunion dialog::mute_types flaggroup
proc dialog::build_flaggroup {Mvar scriptvar dial type page name\
  yvar left right helpLvar helpAvar} {
   upvar 1 $Mvar M $scriptvar script $yvar y $helpLvar helpL\
     $helpAvar helpA
   array set Opt {-justification left}
   array set Opt [lrange $type 2 end]
   if {![info exists Opt(-style)]} then {
      if {[info exists Opt(-columns)]} then {
         set Opt(-style) columns
      } else {
         set Opt(-style) paragraph
      }
   } elseif {![info exists Opt(-columns)]} {
      set Opt(-columns) 1
   }
   dialog::metrics Metrics
   set measurefont -2
   eval [list lappend M] [dialog::lines_to_text\
      [dialog::width_linebreak $name [expr {$right-$left}]]\
      $left $right y]
   incr y $Metrics(StaticTextSpacingY)
   set subitemL [list]
   set script ""
   foreach sname [lindex $type 1] {
      set item [list $sname]
      lappend item [regexp -nocase {1|on|yes}\
        [dialog::valGet $dial $page,$sname]]
      lappend item {}
      lappend subitemL $item
      if {[info exists helpA($page,$sname)]} then {
         lappend helpL $helpA($page,$sname)
      } else {
         lappend helpL {}
      }
      append script [list dialog::valChanged $dial $page,$sname]\
        { [lindex $res $count]} \n {incr count} \n
   }
   append script {continue}
   switch -- $Opt(-style) columns {
      set colsep [expr {$Metrics(StaticTextSpacingX) +\
        $Metrics(CheckBoxSpacingX)}]
      set colwidth [expr {($right-$left+$colsep) / $Opt(-columns)\
        - $colsep}]
      set linewidth [expr {$colwidth - $Metrics(CheckBoxWidth)}]
      set sumheight 0
      for {set n 0} {$n < [llength $subitemL]} {incr n} {
         set bounds [getTextDimensions -font $measurefont\
           -width $linewidth [lindex $subitemL $n 0]]
         set height [expr {-[lindex $bounds 1] + [lindex $bounds 3]}]
         if {$height < $Metrics(CheckBoxHeight)}\
         then {set height $Metrics(CheckBoxHeight)}
         lset subitemL $n 2 $height
         incr sumheight $height
         incr sumheight $Metrics(TightCheckBoxSpacingY)
      }
      set goalheight [expr {($sumheight-1)/$Opt(-columns) + 1}]
      set sumheight $goalheight
      set colno 0
      set ymax $y
      set coly $y
      foreach item $subitemL {
         if {$sumheight >= $goalheight && $colno<$Opt(-columns)} then {
            if {$coly>$ymax} then {set ymax $coly}
            set coly $y
            set colleft [expr {$left + round(\
              double($right+$colsep-$left)*$colno/$Opt(-columns)\
              )}]
            incr colno
            set colright [expr {$left - $colsep + round(\
              double($right+$colsep-$left)*$colno/$Opt(-columns)\
              )}]
            set sumheight 0
         } else {
            incr coly $Metrics(TightCheckBoxSpacingY)
         }
         lappend M -c [lindex $item 0] [lindex $item 1] -font 2\
           $colleft $coly $colright [incr coly [lindex $item 2]]
         incr sumheight [lindex $item 2]
         incr sumheight $Metrics(TightCheckBoxSpacingY)
      }
      if {$coly>$ymax} then {set y $coly} else {set y $ymax}
   } paragraph {
      for {set n 0} {$n < [llength $subitemL]} {incr n} {
         set bounds\
           [getTextDimensions -font $measurefont [lindex $subitemL $n 0]]
         lset subitemL $n 2 [expr {[lindex $bounds 2] +\
             $Metrics(CheckBoxSeparationX) + $Metrics(CheckBoxWidth)}]
      }
      lappend subitemL [list {} {} [expr {$right - $left}]]
      set colsep [expr {$Metrics(StaticTextSpacingX) +\
        $Metrics(CheckBoxSpacingX)}]
      set avail [expr {$right - $left}]
      set lineL [list]
      foreach item $subitemL {
         if {$avail >= [lindex $item 2]} then {
            lappend lineL $item
            incr avail [expr {-([lindex $item 2]+$colsep)}]
            continue
         }
         set x $left
         set y2 [expr {$y + $Metrics(CheckBoxHeight)}]
         set spaces [expr {[llength $lineL] - 1}]
         if {$spaces==0} then {
            lappend M -c [lindex $lineL 0 0] [lindex $lineL 0 1]\
              -font 2 $left $y $right $y2
         } else {
            set avail [expr {double($avail+$colsep) / $spaces}]
            for {set n 0} {$n<[llength $lineL]} {incr n} {
               lappend M -c [lindex $lineL $n 0] [lindex $lineL $n 1]\
                 -font 2 $x $y [incr x [lindex $lineL $n 2]] $y2
               set x [expr {$x + $colsep +\
                 ($Opt(-justification) ne "fullwidth" ? 0 :
                    round($avail*($n+1)) - round($avail*$n) )}]
            }
         }
         set y [expr {$y2 + $Metrics(CheckBoxSpacingY)}]
         set avail [expr {$right - $left}]
         if {$avail >= [lindex $item 2]} then {
            set lineL [list $item]
            incr avail [expr {-([lindex $item 2]+$colsep)}]
         } else {
            set bounds [getTextDimensions -font $measurefont\
              -width [expr {$avail - $Metrics(CheckBoxWidth)}]\
              [lindex $item 0]]
            set y2 [expr {$y +\
              [lindex $bounds 3] - [lindex $bounds 1]}]
            lappend M -c [lindex $item 0] [lindex $item 1] -font 2\
              $left $y $right $y2
            set y [expr {$y2 + $Metrics(CheckBoxSpacingY)}]
            set lineL [list]
         }
      }
      set y $y2
   }
}
proc dialog::make {args} {
   global alpha::platform
   set opts(-ok) OK
   set opts(-okhelptag) "Click here to use the current settings."
   set opts(-cancel) Cancel
   set opts(-cancelhelptag) "Click here to discard any\
        changes you've made to the settings."
   set opts(-title) ""
   set opts(-width) 400
   set opts(-debug) 0
   set opts(-pager) "popupmenu"
   set opts(-hidepages) [list]
   getOpts {-title -defaultpage -ok -okhelptag -cancel -cancelhelptag \
     -addbuttons -width -debug -hidepages -alpha7pagelimit -pager}
   set dial [dialog::create]
   set pages [list]
   foreach pagearg $args {
      set page [lindex $pagearg 0]
      set pageA($page) [list]
      foreach item [lrange $pagearg 1 end] {
         set name [lindex $item 1]
         if {[info exists typeA($page,$name)]} {
            dialog::checkItemOk $page $name \
              $typeA($page,$name) [lindex $item 0]
         }
         set typeA($page,$name) [lindex $item 0]
         dialog::valSet $dial $page,$name [lindex $item 2]
         if {[llength $item]>3} then {
            set helpA($page,$name) [lindex $item 3]
         }
         lappend pageA($page) $name
      }
      if {[lsearch -exact $opts(-hidepages) $page]<0} then {
         lappend pages $page $pageA($page)
      }
   }
   if {[info exists opts(-defaultpage)]} then {
      set currentpage $opts(-defaultpage)
   } else {
      set currentpage [lindex $pages 0]
   }
   if {![info exists opts(-alpha7pagelimit)] || [info tclversion]>=8.0}\
   then {
      set splitstate off
   } elseif {[llength $pages]/2 <= $opts(-alpha7pagelimit)} then {
      set splitstate below
   } else {
      set splitstate menu
   }
   set view_button [list [list {View dialog page}\
     {Click here to see the items on this page.}\
     {set splitstate page}]]
   set back_button [list [list "Back"\
     {Click here to go back to the pages menu.}\
     {set splitstate menu}] first right]
   set optionL [list -width $opts(-width) -title $opts(-title)\
     -pager $opts(-pager)]
   if {$alpha::platform eq "tk"} {
      lappend optionL -geometryvariable geometry
   }
   set main_buttons \
     [list $opts(-ok) $opts(-okhelptag)\
       {set retCode 0}]
   if {$opts(-cancel) ne ""} {
      lappend main_buttons $opts(-cancel) $opts(-cancelhelptag)\
        {set retCode 1; set retVal "cancel"}
   }
   set main_buttons [list $main_buttons first right]
   set state 0
   while {![info exists retCode]} {
      switch -exact -- $splitstate off - below {
         if {[info exists opts(-addbuttons)]} then {
            set script [dialog::handle $pages typeA $dial helpA\
              currentpage $optionL [list $opts(-addbuttons)]\
              $main_buttons]
         } else {
            set script [dialog::handle $pages typeA $dial helpA\
              currentpage $optionL $main_buttons]
         }
      } menu {
         set altpages [list]
         set n 1
         foreach item $pages {
            if {$n} then {
               lappend altpages $item
               set n 0
            } else {
               lappend altpages {}
               set n 1
            }
         }
         set script [dialog::handle $altpages typeA $dial helpA\
             currentpage $optionL $view_button $main_buttons]
      } page {
         set altpages [list $currentpage $pageA($currentpage)]
         if {[info exists opts(-addbuttons)]} then {
            set script [dialog::handle $altpages typeA $dial helpA\
              currentpage $optionL [list $opts(-addbuttons)]\
              $back_button]
         } else {
            set script [dialog::handle $altpages typeA $dial helpA\
              currentpage $optionL $back_button]
         }
      }
      if {[set errcode [catch $script err]]} then {
         if {$errcode == 1} {
             global errorInfo
             set errinfo $errorInfo
         } else {
             # Not clear how best to handle error-codes for
             # break, return, etc., but we don't want to
             # report 'errorInfo' which is irrelevant.
             set errinfo $errcode
         }
         if {$opts(-debug)} then {
            alpha::stderr "Error in button script '$script'"
            alpha::stderr $err
         }
         dialog::cleanup $dial
         return -code 1 -errorinfo $errinfo\
           "Error '$err' when evaluating button script."
      }
   }
   if {$retCode==0} then {
      set retVal [list]
      global dialog::mute_types
      foreach pagearg $args {
         set page [lindex $pagearg 0]
         foreach item [lrange $pagearg 1 end] {
            # Strip off leading 'hidden' if present
            set complete_type [lindex $item 0]
            if {[lindex $complete_type 0] == "hidden"} {
                set type [lindex $complete_type 1]
            } else {
                set type [lindex $complete_type 0]
            }
            if {[lsearch -exact ${dialog::mute_types} $type] < 0}\
            then {lappend retVal\
              [dialog::valGet $dial "$page,[lindex $item 1]"]}
         }
      }
   }
   dialog::cleanup $dial
   return -code $retCode $retVal
}
proc dialog::checkItemOk {page name origType type} {
   if {$type eq $origType} return
   if {[lindex $origType 0] eq "hidden"} {
      set origType [lrange $origType 1 end]
   }
   if {[lindex $type 0] eq "hidden"} {
      set type [lrange $type 1 end]
   }
   if {$type eq $origType} return
   return -code error "Attempt to change type of dialog\
     item named \"$name\" on page \"$page\" from type\
     \"$typeA($page,$name)\" to \"[lindex $item 0]\""
}
proc dialog::make_paged {args} {
   global alpha::platform
   set opts(-ok) OK
   set opts(-okhelptag) "Click here to use the current settings."
   set opts(-cancel) Cancel
   set opts(-cancelhelptag) "Click here to discard any\
        changes you've made to the settings."
   set opts(-title) ""
   set opts(-width) 400
   set opts(-debug) 0
   set opts(-pager) "popupmenu"
   getOpts {-title -defaultpage -ok -okhelptag -cancel -cancelhelptag \
     -addbuttons -width -debug -alpha7pagelimit -changedpages -changeditems -pager}
   set dial [dialog::create]
   set pages [list]
   set delta_pages [list]
   if {[info exists opts(-alpha7pagelimit)] && [info tclversion]<8.0}\
   then {
      set splitstate below
   } else {
      set splitstate off
   }
   foreach pagearg $args {
      eval [list dialog::add_page] $pagearg
   }
   set delta_pages [list]
   if {$splitstate=="page"} then {set splitstate menu}
   if {[info exists opts(-defaultpage)]} then {
      set currentpage $opts(-defaultpage)
   } else {
      set currentpage [lindex $pages 0]
   }
   set optionL [list -width $opts(-width) -title $opts(-title)\
     -pager $opts(-pager)]
   if {$alpha::platform eq "tk"} {
      lappend optionL -geometryvariable geometry
   }
   set main_buttons \
     [list $opts(-ok) $opts(-okhelptag)\
       {set retCode 0}]
   if {$opts(-cancel) ne ""} {
      lappend main_buttons $opts(-cancel) $opts(-cancelhelptag)\
        {set retCode 1; set retVal "cancel"}
   }
   set main_buttons [list $main_buttons first right]
   set view_button [list [list {View dialog page}\
     {Click here to see the items on this page.}\
     {set splitstate page}]]
   set back_button [list [list "Back"\
     {Click here to go back to the pages menu.}\
     {set splitstate menu}] first right]
   set state 0
   while {![info exists retCode]} {
      switch -exact -- $splitstate off - below {
         if {[info exists opts(-addbuttons)]} then {
            set script [dialog::handle $pages typeA $dial helpA\
              currentpage $optionL [list $opts(-addbuttons)]\
              $main_buttons]
         } else {
            set script [dialog::handle $pages typeA $dial helpA\
              currentpage $optionL $main_buttons]
         }
      } menu {
         set altpages [list]
         set n 1
         foreach item $pages {
            if {$n} then {
               lappend altpages $item
               set n 0
            } else {
               lappend altpages {}
               set n 1
            }
         }
         set script [dialog::handle $altpages typeA $dial helpA\
             currentpage $optionL $view_button $main_buttons]
      } page {
         if {![info exists pageA($currentpage)]} then {
            set splitstate menu
            continue
         }
         set altpages [list $currentpage $pageA($currentpage)]
         if {[info exists opts(-addbuttons)]} then {
            set script [dialog::handle $altpages typeA $dial helpA\
              currentpage $optionL [list $opts(-addbuttons)]\
              $back_button]
         } else {
            set script [dialog::handle $altpages typeA $dial helpA\
              currentpage $optionL $back_button]
         }
      }
      if {[catch $script err]} then {
         global errorInfo
         set errinfo $errorInfo
         if {$opts(-debug)} then {
            alpha::stderr "Error in button script '$script'"
            alpha::stderr $err
         }
         dialog::cleanup $dial
         return -code 1 -errorinfo $errinfo\
           "Error '$err' when evaluating button script."
      }
   }
   if {$retCode==0} then {
      set retVal [list]
      global dialog::mute_types
      foreach page $delta_pages {
         foreach name $pageA($page) {
            lappend cA($page) $keyA($page,$name)
         }
      }
      foreach item [dialog::changed_items $dial] {set cS($item) ""}
      foreach {page items} $pages {
         set res [list]
         foreach name $items {
            set T "$page,$name"
            if {[lsearch -exact ${dialog::mute_types}\
                 [lindex $typeA($T) 0]] < 0} then {
               lappend res $keyA($T) [dialog::valGet $dial $T]
               if {[info exists cS($T)]} then {
                  lunion cA($page) $keyA($T)
               }
            }
         }
         lappend retVal $page $res
      }
      if {[info exists opts(-changedpages)]} then {
         upvar 1 $opts(-changedpages) cp
         set cp [array names cA]
      }
      if {[info exists opts(-changeditems)]} then {
         upvar 1 $opts(-changeditems) ci
         set ci [array get cA]
      }
   }
   dialog::cleanup $dial
   return -code $retCode $retVal
}
proc dialog::add_page {page keyvalL itemsL {pos end}} {
   upvar 1 pageA pageA typeA typeA helpA helpA keyA keyA\
      dial dial pages pages delta_pages delta_pages\
      splitstate splitstate opts opts
   array set local $keyvalL
   set pageA($page) [list]
   lunion delta_pages $page
   foreach item $itemsL {
      set key [lindex $item 0]
      set name [lindex $item 2]
      set keyA($page,$name) $key
      if {[info exists local($key)]} then {
         dialog::valSet $dial $page,$name $local($key)
      } else {
         dialog::valSet $dial $page,$name ""
      }
      if {[info exists typeA($page,$name)]} {
         dialog::checkItemOk $page $name \
           $typeA($page,$name) [lindex $item 1]
      }
      set typeA($page,$name) [lindex $item 1]
      if {[llength $item]>3} then {
         set helpA($page,$name) [lindex $item 3]
      }
      lappend pageA($page) $name
   }
   if {$pos!="end"} then {
      set pages [linsert $pages [expr {2*$pos}] $page $pageA($page)]
   } else {
      lappend pages $page $pageA($page)
   }
   if {$splitstate=="menu" || ($splitstate=="below" &&\
       [llength $pages]>2*$opts(-alpha7pagelimit))} then {
      set splitstate page
   }
}
proc dialog::delete_pages {pages deleteL {deletedvar {}}} {
   set res [list]
   if {[string length $deletedvar]} then {upvar 1 $deletedvar diffL}
   foreach {page items} $pages {
      if {[lsearch -exact $deleteL $page] == -1} then {
         lappend res $page $items
      } else {
         lunion diffL $page
      }
   }
   if {[string length $deletedvar]} then {
      upvar 1 splitstate state opts(-alpha7pagelimit) limit
      switch -exact -- $state page - menu {
         if {[llength $res]<=2*$limit} then {
            set state below
         } else {
            set state menu
         }
      }
   }
   return $res
}
proc dialog::prefItemType {prefname} {
   prefs::getDialogType $prefname
}
proc dialog::editGroup {args} {
    global dialog::ellipsis
    set opts(-current) ""
    set opts(-title) "Edit"
    getOpts {-array -title -current -new -delete -alpha7pagelimit}
    upvar 1 $opts(-array) local
    set dialog [list]
    foreach item [lsort -dictionary [array names local]] {
        lappend dialog [list $item $local($item) $args]
    }
    set buttons [list]
    if {[info exists opts(-delete)]} {
        if {$opts(-delete)=="dontask"} then {
           lappend buttons "Delete" "Click here to delete this page"\
             {set pages [dialog::delete_pages $pages\
                [list $currentpage] delta_pages]}
        } else {
           lappend buttons "Delete${dialog::ellipsis}"\
             "Click here to delete this page" {
                if {[dialog::yesno "Are you sure you want to\
                  delete '$currentpage'?"]} {
                    set pages [dialog::delete_pages $pages\
                      [list $currentpage] delta_pages]
                }
             }
        }
    }
    if {[info exists opts(-new)]} {
        lappend buttons "New${dialog::ellipsis}"\
          "Click here to add a new page"\
          [list dialog::editGroupNewPage $args $opts(-new)]
    }
    set call [list dialog::make_paged -changedpages mods]
    lappend call -title $opts(-title) -defaultpage $opts(-current)
    if {[info exists opts(-alpha7pagelimit)]} then {
       lappend call -alpha7pagelimit $opts(-alpha7pagelimit)
    }
    if {[llength $buttons]} then {lappend call -addbuttons $buttons}
    set res [eval $call $dialog]
    unset local
    array set local $res
    return $mods
}
proc dialog::editGroupNewPage {layout cmd} {
   set T [eval $cmd]
   if {![llength $T]} then {return}
   foreach {page items} [uplevel 1 {set pages}] {
      if {$page==[lindex $T 0]} then {
         alertnote "That name is already in use!"
         return
      }
   }
   uplevel 1 [concat dialog::add_page $T [list $layout]]
   uplevel 1 [list set currentpage [lindex $T 0]]
}
## 
##
## End of file `dialogsNew.tcl'.
