## (auto-install)
##
## This is file `eemenu.tcl',
## generated with the docstrip utility.
##
## The original source files were:
##
## eemenu.dtx  (with options: `pkg')
## 
## This file may be distributed and/or modified under the conditions
## of the LaTeX Project Public License, either version 1.2 of this
## license or (at your option) any later version. The latest version
## of this license is in
##    http://www.latex-project.org/lppl.txt
## and version 1.2 or later is part of all distributions of LaTeX
## version 1999/12/01 or later.
## 
## This file may only be distributed together with a copy of the source
## file from which it was generated. You may distribute that source file
## without this generated file.
## 
## You may alternatively distribute, use, and modify this files under
## the conditions of a BSD-style license. In so doing, you should
## however note that
## **************************************
## * This Source is not the True Source *
## **************************************
## the true source is the file from which this one was generated.
## 
alpha::menu eeMenu 0.3.1 global "EE" {
   auto_load eemenu::main
} {
   eemenu::init_bindings
   eemenu::build_menu
} {
   eval eemenu::deactivate [array names eemenu::cmdA]
} requirements {
   alpha::package require AlphaTcl 8.0d1
} uninstall {this-file} description {
    The EE menu provides commands for sending small pieces of code
    from a source file window to various interpreters. It can handle
    multiple languages and multiple source file formats.
} help {
   The EE menu provides commands for sending small pieces of code
   from a source file window to various interpreters. It can handle
   multiple languages and multiple source file formats.

   The commands are built by combining four simple pieces called
   methods. The choice of methods and parameters for methods to
   use in a command is completely configurable through a dialog.
   It is also possible to write extensions that define additional
   methods and provide these through the same easy interface.

   See the file eemenu.dtx for the full documentation.
} maintainer\
  [list "Lars Hellstr\u00f6m" Lars.Hellstrom@math.umu.se]
namespace eval eemenu {}
proc eemenu::Prettify str {
   set a [string toupper [string index $str 0]]
   regsub -all {([^A-Z])([A-Z])} [string range $str 1 end] {\1 \2} b
   regsub -all {((La|Bib|Oz|CMac) )?Te X} $a$b {\2TeX } a
   return $a
}
proc eemenu::Unprettify str {
   regsub -all { } $str {} a
   return "[string tolower [string index $a 0]][string range $a 1 end]"
}
proc eemenu::multiupvar {args} {
   foreach var $args {uplevel 1 [list variable $var]}
}
proc eemenu::main {command args} {
   global eemenu::cmdA
   if {![info exists eemenu::cmdA($command)]} then {
      error "Command '$command' undefined."
   }
   array set CMD [set eemenu::cmdA($command)]
   set extract [eemenu::Unprettify $CMD(extractor)]
   set cmpl [eemenu::Unprettify $CMD(complete)]
   set eval [eemenu::Unprettify $CMD(evaluator)]
   set report [eemenu::Unprettify $CMD(reporter)]
   set win\
     [eval [list eemenu::${extract}::start $CMD(extract_extra)] $args]
   upvar #0 eemenu::${cmpl}::complete complete
   eemenu::${report}::log_open $CMD(report_extra) $win
   set res [eemenu::${eval}::begin $CMD(eval_extra) $win]
   eval [list eemenu::${report}::log_result] $res
   set lines [list]
   set safe 1
   while {![lindex $res 0]} {
      set at_end [catch {eemenu::${extract}::next $safe} line]
      if {$at_end == 1} then {
         global errorInfo
         return -code error -errorinfo $errorInfo
      } elseif {$at_end == 0} then {
         lappend lines $line
      } elseif {![llength $lines]} then {break}
      set safe [expr $complete]
      if {$at_end && !$safe} then {
         set safe [expr {![dialog::yesno -y No -n Yes\
           "The last [llength $lines] lines do not appear to be a\
           complete block of code. Evaluate anyway?"]}]
         if {!$safe} then {
            set res [list 1 "" ""]
            break
         }
      }
      if {$safe} then {
         eemenu::${report}::log_code $lines
         set res [eemenu::${eval}::item $lines]
         eval [list eemenu::${report}::log_result] $res
         set lines [list]
      }
   }
   if {[lindex $res 0]} then {
      eval [list eemenu::${report}::log_result] [eemenu::${eval}::end]
   } else {
      set res [eemenu::${eval}::end]
      eval [list eemenu::${report}::log_result] $res
   }
   eemenu::${extract}::finish [lindex $res 0]
   eemenu::${report}::log_close
}
proc eemenu::binding_index {mode binding} {
   if {"<none>"==$mode} then {set mode ""}
   set mode [string range "[string trim $mode]    " 0 3]
   return "$mode$binding"
}
proc eemenu::init_bindings {} {
   eemenu::multiupvar cmdA binding
   foreach cmd [array names cmdA] {
      array set A $cmdA($cmd)
      if {!$A(active)} then {continue}
      set idx [eemenu::binding_index $A(mode) $A(binding)]
      if {[info exists binding($idx)] &&\
        ![dialog::yesno "To activate '$cmd', I must first deativate\
           '$binding($idx)'. Proceed?"]}\
      then {continue}
      set binding($idx) $cmd
      set call [keys::bindKey $A(binding)]
      lappend call [list eemenu::main $cmd]
      if {[string compare "<none>" $A(mode)]} then {lappend call $A(mode)}
      eval $call
   }
}
proc eemenu::deactivate {args} {
   eemenu::multiupvar binding cmdA
   foreach cmd $args {
      array set A $cmdA($cmd)
      set idx [eemenu::binding_index $A(mode) $A(binding)]
      if {![info exists binding($idx)] ||\
        [string compare $binding($idx) $cmd]} then {continue}
      unset binding($idx)
      set call [keys::unbindKey $A(binding)]
      lappend call ""
      if {[string compare "<none>" $A(mode)]} then {lappend call $A(mode)}
      eval $call
      markMenuItem -m "Active Commands" $cmd off
   }
}
proc eemenu::activate {noisy args} {
   eemenu::multiupvar binding cmdA
   set deactiveL [list]
   foreach cmd $args {
      array set A $cmdA($cmd)
      set idx [eemenu::binding_index $A(mode) $A(binding)]
      if {[info exists binding($idx)]} then {
         if {![string compare $binding($idx) $cmd]} then {continue}
         if {$noisy && ![dialog::yesno "To activate '$cmd', I must\
           first deativate '$binding($idx)'. Proceed?"]} then {continue}
         lappend deactiveL $binding($idx)
         markMenuItem -m "Active Commands" $binding($idx) off
      }
      set binding($idx) $cmd
      set call [keys::bindKey $A(binding)]
      lappend call [list eemenu::main $cmd]
      if {[string compare "<none>" $A(mode)]} then {lappend call $A(mode)}
      eval $call
      markMenuItem -m "Active Commands" $binding($idx) on\
           [text::Ascii 18 1]
   }
   if {!$noisy && [llength $deactiveL]} then {
      status::msg "Deactivated commands: [join $deactiveL ", "]"
   }
}
proc eemenu::build_menu {} {
   eemenu::multiupvar cmdA binding
   set items [list "Edit Commands[text::Ascii 201 1]"]
   if {[array size cmdA] > 0} then {
      set cmdL [lsort -dictionary [array names cmdA]]
      lappend items [list Menu -n "Active Commands" -m\
        -p eemenu::menu_proc $cmdL]
      lappend items "(-)"
      foreach cmd $cmdL {
         array set A $cmdA($cmd)
         if {$A(in_menu)} then {lappend items $cmd}
      }
   }
   global eeMenu
   Menu -n $eeMenu -m -p eemenu::menu_proc $items
   if {[array size cmdA]} then {
      foreach idx [array names binding] {
         markMenuItem -m "Active Commands" $binding($idx) on\
           [text::Ascii 18 1]
      }
   }
}
proc eemenu::menu_proc {menu item} {
   global eeMenu
   eemenu::multiupvar cmdA binding
   switch -- $menu $eeMenu {
      switch -- $item "Edit Commands" {
         eemenu::edit_commands
      } default {
         eemenu::main $item
      }
   } "Active Commands" {
      array set A $cmdA($item)
      set idx [eemenu::binding_index $A(mode) $A(binding)]
      if {[info exists binding($idx)] &&\
        ![string compare $binding($idx) $item]} then {
         eemenu::deactivate $item
      } else {
         eemenu::activate 1 $item
      }
   }
}
array set eemenu::detail_defaultA\
  {Extract {} Complete {} Evaluate {} Report {}}
proc eemenu::define_detail {page name key type {val ""} {help ""}} {
   upvar #0 eemenu::detail_typeA typeA eemenu::detail_helpA helpA\
     eemenu::detail_keyA keyA eemenu::detail_defaultA valA
   set error ""
   set idx "$page,$name"
   if {![info exists keyA($idx)]} then {
      set keyA($idx) $key
   } elseif {"$key" != "$keyA($idx)"} then {
      append error " Different keys: '$keyA($idx)' and '$key'."
   }
   if {![info exists typeA($idx)]} then {
      set typeA($idx) $type
   } elseif {"$type" != "$typeA($idx)"} then {
      append error " Different types: '$typeA($idx)' and '$type'."
   }
   if {[string length $val]} then {
      if {[info exists valA($page)]} then {array set A $valA($page)}
      if {![info exists A($key)] || ![string length $A($key)]} then {
         set A($key) $val
         set valA($page) [array get A]
      }
   }
   if {[string length $help]} then {
      if {![info exists helpA($idx)]} then {
         set helpA($idx) $help
      } elseif {"$help" != "$helpA($idx)"} then {
         append error " Different help texts: '$helpA($idx)' and '$help'."
      }
   }
   if {[string length $error]} then {
      dialog::alert "The detail setting '$name' for '$page' methods\
        has conficting definitions.$error This is an error that should
        be fixed; for now, the second definition will be ignored."
   }
   return $name
}
proc eemenu::edit_commands {} {
   global eemenu::extract eemenu::complete eemenu::evaluate\
     eemenu::report
   set layout [list]
   lappend layout [list active flag Active "Is the binding active?"]
   lappend layout [list binding binding "Command keybinding"]
   lappend layout [list mode mode "Binding mode"]
   lappend layout [list in_menu flag "Put in menu"]
   set M [list]
   foreach method [lsort -dictionary [array names eemenu::extract]] {
      lappend M [eemenu::Prettify $method]
   }
   lappend layout [list extractor [list menu $M] "Extraction method"]
   lappend layout [list extract_extra [list hidden keyval] extract_extra]
   set M [list]
   foreach method [lsort -dictionary [array names eemenu::complete]] {
      lappend M [eemenu::Prettify $method]
   }
   lappend layout [list complete [list menu $M] "Completion test"]
   lappend layout [list complete_extra [list hidden keyval] complete_extra]
   set M [list]
   foreach method [lsort -dictionary [array names eemenu::evaluate]] {
      lappend M [eemenu::Prettify $method]
   }
   lappend layout [list evaluator [list menu $M] "Evaluation method"]
   lappend layout [list eval_extra [list hidden keyval] eval_extra]
   set M [list]
   foreach method [lsort -dictionary [array names eemenu::report]] {
      lappend M [eemenu::Prettify $method]
   }
   lappend layout [list reporter [list menu $M] "Report method"]
   lappend layout [list report_extra [list hidden keyval] report_extra]
   global dialog::ellipsis
   if {![info exists dialog::ellipsis]} then {auto_load dialog::make_paged}
   set call [list dialog::make_paged]
   set buttons [list]
   lappend buttons "New${dialog::ellipsis}" "Add new command"\
     {eemenu::add_command ""}
   lappend buttons "Duplicate${dialog::ellipsis}"\
     "Duplicate this command" {eemenu::add_command $currentpage}
   lappend buttons "Rename${dialog::ellipsis}"\
     "Rename this command" {eemenu::rename_command}
   lappend buttons "Delete${dialog::ellipsis}"\
     "Delete this command" {
        if {[dialog::yesno "Are you sure you want to\
          delete '$currentpage'?"]} {
            set pages [dialog::delete_pages $pages\
              [list $currentpage] delta_pages]
        }
     }
   lappend buttons "Details${dialog::ellipsis}"\
     "Setting details for this command" {
        eemenu::command_details $dial $currentpage
     }
   lappend call -addbuttons $buttons -changeditems mods\
     -alpha7pagelimit 2
   global eemenu::cmdA
   foreach cmd [lsort -dictionary [array names eemenu::cmdA]] {
     lappend call [list $cmd [set eemenu::cmdA($cmd)] $layout]
   }
   set res [eval $call]
   set call [list eemenu::deactivate]
   foreach {cmd keys} $mods {
      if {[lsearch -regexp $keys {^(active|binding|mode)$}]>=0 &&\
        [info exists eemenu::cmdA($cmd)]} then {
         lappend call $cmd
      }
   }
   if {[llength $call]>1} then {eval $call}
   unset eemenu::cmdA
   array set eemenu::cmdA $res
   set call [list eemenu::activate 0]
   set build_menu 0
   foreach {cmd keys} $mods {
      prefs::modified eemenu::cmdA($cmd)
      if {![info exists eemenu::cmdA($cmd)]}\
      then {set build_menu 1; continue}
      array set A [set eemenu::cmdA($cmd)]
      if {$A(active) &&\
        [lsearch -regexp $keys {^(active|binding|mode)$}]>=0}\
      then {lappend call $cmd}
      if {[lsearch -exact $keys in_menu]>=0} then {set build_menu 1}
   }
   if {[llength $call]>2} then {eval $call}
   if {$build_menu} then {eemenu::build_menu}
}
proc eemenu::add_command {templ} {
   set name [getline "Name of new command"]
   if {![string length $name]} then {return}
   foreach {page items} [uplevel 1 {set pages}] {
      if {![string compare $page $name]} then {
         alternote "That name is already in use!"
         return
      }
   }
   set keyvals [list active 0 in_menu 0]
   if {[string length $templ]} then {
      set dial [uplevel 1 {set dial}]
      set cpage [uplevel 1 {set currentpage}]
      foreach {key item}\
       {binding {Command keybinding}  mode {Binding mode}
        extractor {Extraction method} extract_extra extract_extra
        complete {Completion test}    complete_extra complete_extra
        evaluator {Evaluation method} eval_extra eval_extra
        reporter {Report method}      report_extra report_extra} {
         lappend keyvals $key [dialog::valGet $dial "${cpage},${item}"]
      }
   } else {
      lappend keyvals binding "" mode "" extractor "Raw"
      upvar #0 eemenu::detail_defaultA defaultA
      lappend keyvals extract_extra $defaultA(Extract)
      lappend keyvals complete "Entire Selection" complete_extra\
        $defaultA(Complete)
      lappend keyvals evaluator "Internal Tcl" eval_extra\
        $defaultA(Evaluate)
      lappend keyvals reporter "Status Line" report_extra $defaultA(Report)
   }
   uplevel 1 [list dialog::add_page $name $keyvals [uplevel 2 set layout]]
   uplevel 1 [list set currentpage $name]
}
proc eemenu::rename_command {} {
   upvar 1 currentpage cpage dial dial
   set name [getline "New name for command '$cpage'"]
   if {![string length $name]} then {return}
   foreach {page items} [uplevel 1 {set pages}] {
      if {![string compare $page $name]} then {
         alternote "That name is already in use!"
         return
      }
   }
   set keyvals [list]
   foreach {key item} {active Active in_menu {Put in menu}\
     binding {Command keybinding} mode {Binding mode}\
     extractor {Extraction method} extract_extra extract_extra\
     complete {Completion test} complete_extra complete_extra\
     evaluator {Evaluation method} eval_extra eval_extra\
     reporter {Report method} report_extra report_extra} {
      lappend keyvals $key [dialog::valGet $dial "${cpage},${item}"]
   }
   uplevel 1 {
     set pages [dialog::delete_pages $pages [list $currentpage]\
       delta_pages]
   }
   uplevel 1 [list dialog::add_page $name $keyvals [uplevel 2 set layout]]
   set cpage $name
}
proc eemenu::command_details {dial command} {
   global eemenu::detail_typeA eemenu::detail_helpA\
     eemenu::detail_keyA eemenu::extract eemenu::complete\
     eemenu::evaluate eemenu::report
   set pages [list]
   set dial2 [dialog::create]
   foreach {which page layoutarr data arr} {
      {Extraction method} Extract eemenu::extract extract_extra  A1
      {Completion test} Complete eemenu::complete complete_extra A2
      {Evaluation method} Evaluate eemenu::evaluate eval_extra   A3
      {Report method}     Report   eemenu::report   report_extra A4
   } {
      set method [eemenu::Unprettify\
        [dialog::valGet $dial ${command},${which}]]
      set L [set ${layoutarr}($method)]
      if {[llength $L]} then {
         lappend pages $page $L
         array set $arr [dialog::valGet $dial ${command},${data}]
         foreach l $L {
            set v [set eemenu::detail_keyA($page,$l)]
            if {[info exists ${arr}($v)]} then {
               dialog::valSet $dial2 "$page,$l" [set ${arr}($v)]
            } else {
               switch -- [set eemenu::detail_typeA($page,$l)] flag {
                  dialog::valSet $dial2 "$page,$l" 0
               } default {
                  dialog::valSet $dial2 "$page,$l" ""
               }
            }
         }
      }
   }
   if {![llength $pages]} then {
      dialog::alert "There are no details for these methods."
      dialog::cleanup $dial2
      return
   }
   dialog::handle $pages eemenu::detail_typeA $dial2\
     eemenu::detail_helpA page [list]\
     [list [list "Back" "Return to overall dialog" ""] right first]
   set L [dialog::changed_items $dial2]
   foreach item $L {
      switch -glob $item {
        Extract,* {set arr A1}
        Complete,* {set arr A2}
        Evaluate,* {set arr A3}
        Report,* {set arr A4}
      }
      set ${arr}([set eemenu::detail_keyA($item)])\
        [dialog::valGet $dial2 $item]
   }
   foreach {page data arr} {
      Extract  extract_extra  A1
      Complete complete_extra A2
      Evaluate eval_extra     A3
      Report   report_extra   A4
   } {
      if {[lsearch -glob $L "${page},*"] >= 0} then {
         dialog::valChanged $dial "${command},${data}" [array get $arr]
      }
   }
   dialog::cleanup $dial2
}
set eemenu::extract(raw) [list]
namespace eval eemenu::raw {}
proc eemenu::raw::start {details {win ""} {startpos ""} {endpos ""}} {
   eemenu::multiupvar line_queue window cur_pos from_pos safe_pos end_pos
   global alpha::platform
   if {![string length $win]} then {set win [win::Current]}
   switch -- ${alpha::platform} alpha {
      set win_tail [file tail $win]
   } default {
      set win_tail $win
   }
   if {![string length $startpos]} then {
      set startpos [getPos -w $win_tail]
      set endpos [selEnd -w $win_tail]
      if {[pos::compare $startpos == $endpos]} then {
         set startpos [minPos]
         set endpos [maxPos -w $win_tail]
      }
   }
   set line_queue [list ""]
   set window $win_tail
   set cur_pos $startpos
   set from_pos $startpos
   set safe_pos $startpos
   set end_pos $endpos
   return [win::StripCount $win]
}
   proc eemenu::raw::next {at_safe} {
      eemenu::multiupvar line_queue window cur_pos from_pos safe_pos\
        end_pos
      if {[llength $line_queue] < 2} then {
         if {[pos::compare -w $window $cur_pos >= $end_pos]} then {
            return -code 9 "Done"
         }
         set next_pos [pos::math -w $window $from_pos + 1024]
         if {[pos::compare -w $window $next_pos >= $end_pos]} then {
            set next_pos $end_pos
         }
         set text [lindex $line_queue end]
         append text [getText -w $window $from_pos $next_pos]
         set line_queue [split $text "\n\r"]
         set from_pos $next_pos
      }
      if {$at_safe} then {set safe_pos $cur_pos}
      set line [lindex $line_queue 0]
      set line_queue [lreplace $line_queue 0 0]
      set cur_pos\
        [pos::math -w $window $cur_pos + [expr {[string length $line]+1}]]
      set line
   }
proc eemenu::raw::finish {was_error} {
   eemenu::multiupvar line_queue window safe_pos end_pos
   set line_queue [list]
   if {!$was_error} then {return}
   bringToFront $window
   selectText $safe_pos $end_pos
   hiliteToPin
}
set eemenu::extract(regexp) [list\
  [eemenu::define_detail Extract "Filter mode"\
    filter_mode [list menu [list off grep anti-grep]] off]\
  [eemenu::define_detail Extract "Filter regular expression"\
    filterRE var]\
  [eemenu::define_detail Extract "Search (regexp):" searchRE var]\
  [eemenu::define_detail Extract "Replace (regexp):" replaceRE var]]
namespace eval eemenu::regexp {}
proc eemenu::regexp::start {details args} {
   global eemenu::regexp::detA
   array set eemenu::regexp::detA\
     {filter_mode off searchRE {} replaceRE {}}
   array set eemenu::regexp::detA $details
   eval [list eemenu::raw::start $details] $args
}
proc eemenu::regexp::next {at_safe} {
   upvar #0 eemenu::regexp::detA D
   while {1} {
      set line [eemenu::raw::next $at_safe]
      switch -- $D(filter_mode) {
        off {break}
        grep {if {[regexp -- $D(filterRE) $line]} then {break}}
        anti-grep {
           if {![regexp -- $D(filterRE) $line]} then {break}
        }
      }
   }
   regsub -all -- $D(searchRE) $line $D(replaceRE) line
   return $line
}
proc eemenu::regexp::finish {err} {eemenu::raw::finish $err}
set eemenu::extract(docstrip) [list\
  [eemenu::define_detail Extract "File patterns" filePatL var\
    "*.dtx" "List of glob-style file patterns the window must match"]\
  [eemenu::define_detail Extract "Filter by environments"\
    lookAtEnvs flag 0]\
  [eemenu::define_detail Extract "Source environments"\
    sourceEnvsL var {tcl tcl*}]]
namespace eval eemenu::docstrip {}
proc eemenu::docstrip::start {details args} {
   eemenu::multiupvar detA module_included module_stack\
     next_module_idx in_code_env in_verbatim
   set win [eval [list eemenu::raw::start $details] $args]
   array set detA {filePatL *.dtx lookAtEnvs 0}
   array set detA $details
   set ok 0
   foreach pat $detA(filePatL) {
      if {[string match $pat $win]} then {set ok 1; break}
   }
   if {!$ok} then {
      status::msg "Can't extract from that window. Must be\
        [join $detA(filePatL) " or "]."
      return -code 9 "Bad window name"
   }
   set module_included 1
   set in_verbatim 0
   set module_stack [list]
   set next_module_idx 0
   if {!$detA(lookAtEnvs)} then {
      set in_code_env 1
   } else {
      set in_code_env -1
      set detA(envsRE) {\\(begin|end) *\{(}
      foreach env $detA(sourceEnvsL) {
         append detA(envsRE) [quote::Regfind $env] "|"
      }
      append detA(envsRE) ")\}(.*)\$"
   }
   return $win
}
proc eemenu::docstrip::eval_guard {e} {
   global eemenu::docstrip::known
   if {![info exists eemenu::docstrip::known($e)]} then {
      set eemenu::docstrip::known($e)\
        [dialog::yesno "Should <$e> modules be included?"]
   }
   set eemenu::docstrip::known($e)
}
proc eemenu::docstrip::push_module {e p} {
   global eemenu::docstrip::module_stack
   lappend eemenu::docstrip::module_stack [list $e $p]
}
proc eemenu::docstrip::pop_module {e p} {
   eemenu::multiupvar module_stack module_included next_module_idx
   set len [llength $module_stack]
   if {$len==0} then {return}
   set L [lindex $module_stack [expr {$len-1}]]
   if {[lindex $L 0] != $e} then {
      switch [buttonAlert "Module nesting error: <*[lindex $L 0]>\
         module ended by </$e>. For which guards should the positions\
         be pushed?" None Start End Both]\
      {
         Start {eemenu::docstrip::push_bookmarks [lindex $L 1]}
         End {eemenu::docstrip::push_bookmarks $p}
         Both {eemenu::docstrip::push_bookmarks [lindex $L 1] $p}
      }
   }
   set module_stack [lreplace $module_stack end end]
   if {$len<=$next_module_idx} then {
      set next_module_idx [llength $module_stack]
   }
   if {[llength $L]>2} then {
      set module_included [lindex $L 2]
   }
}
proc eemenu::docstrip::push_bookmarks {args} {
   global markStack markName
   upvar #0 eemenu::raw::window win
   set topWin [win::CurrentTail]
   foreach pos $args {
      set name mark$markName
      incr markName
      if {[string compare [win::CurrentTail] $win]}\
      then {bringToFront $win}
      createTMark $name $pos
      set fileName [win::Current]
      set markStack [linsert $markStack 0 [list $fileName $name $pos]]
   }
   if {[string compare [win::CurrentTail] $topWin]}\
   then {bringToFront $topWin}
}
proc eemenu::docstrip::update_included {} {
   eemenu::multiupvar module_stack module_included next_module_idx
   while {$module_included && $next_module_idx<[llength $module_stack]} {
      set L [lindex $module_stack $next_module_idx]
      lappend L $module_included
      set module_stack\
        [lreplace $module_stack $next_module_idx $next_module_idx $L]
      incr next_module_idx
      set module_included [eemenu::docstrip::eval_guard [lindex $L 0]]
   }
}
proc eemenu::docstrip::next {is_safe} {
   eemenu::multiupvar detA module_included in_code_env\
     in_verbatim module_stack next_module_idx end_verb_line
   upvar #0 eemenu::raw::cur_pos raw_cur_pos
   while {1} {
      set cur_pos $raw_cur_pos
      set line [eemenu::raw::next [expr {$is_safe && !$in_verbatim}]]
      set line [string trimright $line "\r\n "]
      if {$in_code_env<0} then {
         switch -glob -- $line {
           %<* {set in_code_env 1}
           %*  {set in_code_env 0}
           default {set in_code_env 1}
         }
      }
      if {$in_verbatim} then {
         if {![string compare $line $end_verb_line]} then {
            set in_verbatim 0
         } elseif {$module_included && $in_code_env} then {
            break
         }
      } else {
         switch -glob -- $line {
            %<<* {
               eemenu::docstrip::update_included
               set in_verbatim 1
               set end_verb_line "%[string range $line 3 end]"
            }
            %<[*/]* {
               if {![regexp {^%<(\*|/)([^>]+)>} $line foo modifier\
                  expression]}\
               then {
                  if {[dialog::yesno "Malformed guard line '$line'\
                     encountered. Push position?"]}\
                  then {eemenu::docstrip::push_bookmarks $cur_pos}
               } elseif {$modifier=="*"} then {
                  eemenu::docstrip::push_module $expression $cur_pos
               } else {
                  eemenu::docstrip::pop_module $expression $cur_pos
               }
            }
            %<* {
               if {![regexp {^%<(-|\+|)([^>]+)>(.*)$} $line\
                  foo modifier expression code]}\
               then {
                  if {[dialog::yesno "Malformed guard line '$line'\
                     encountered. Push position?"]}\
                  then {eemenu::docstrip::push_bookmarks $cur_pos}
               } elseif {$in_code_env} then {
                  eemenu::docstrip::update_included
                  if {$module_included &&\
                    [eemenu::docstrip::eval_guard $expression] !=\
                      ($modifier=="-")} then {
                     set line $code
                     break
                  }
               }
            }
            %* {
               while {$detA(lookAtEnvs) &&\
                 [regexp -- $detA(envsRE) $line foo type env line]} {
                  set in_code_env [expr {"$type"=="begin"}]
               }
            }
            default {
               if {$in_code_env} then {
                  eemenu::docstrip::update_included
                  if {$module_included} then {break}
               }
            }
         }
      }
   }
   return $line
}
proc eemenu::docstrip::finish {was_error} {
   eemenu::raw::finish $was_error
   if {$was_error} then {
   } else {
      global eemenu::docstrip::known
      catch {unset eemenu::docstrip::known}
   }
}
set eemenu::complete(entireSelection) [list]
namespace eval eemenu::entireSelection {}
set eemenu::entireSelection::complete {$at_end}
set eemenu::complete(everyLine) [list]
namespace eval eemenu::everyLine {}
set eemenu::everyLine::complete {1}
set eemenu::complete(tclInfoComplete) [list]
namespace eval eemenu::tclInfoComplete {}
set eemenu::tclInfoComplete::complete\
  {[info complete [join $lines \n]\n]}
set eemenu::evaluate(internalTcl) [list]
namespace eval eemenu::internalTcl {}
proc eemenu::internalTcl::begin {details source} {
   list 0 "" ""
}
proc eemenu::internalTcl::end {} {list 0 "" ""}
proc eemenu::internalTcl::item {lines} {
   set code [catch [list uplevel #0 [join $lines \n]] res]
   if {$code == 1} then {
      global errorInfo
      set L [split $errorInfo \n]
      set L [lrange $L 0 [expr {[llength $L] - 4}]]
      list 1 "Tcl eval error: $res"\
        "Error: $res\nError info:\n[join $L \n]\n"
   } elseif {[string length $res]} then {
      list 0 "Tcl eval OK: $res" "$res\n"
   } else {
      list 0 "Tcl eval OK." ""
   }
}
if {![catch {package require tclAE}]} then {
set eemenu::evaluate(doScriptAE) [list\
  [eemenu::define_detail Evaluate "Target application"\
    targetApp appspec]\
  [eemenu::define_detail Evaluate "Join lines using"\
    joinString [list menuindex [list Lf Cr CrLf Space]] 1]\
  [eemenu::define_detail Evaluate "Prefix" prefix var]\
  [eemenu::define_detail Evaluate "Suffix" suffix var]\
  [eemenu::define_detail Evaluate "Wait for reply" replyQ flag]]
namespace eval eemenu::doScriptAE {}
proc eemenu::doScriptAE::begin {details source} {
   upvar #0 eemenu::doScriptAE::A A
   array set A {prefix {} suffix {} joinString 1 targetApp {} replyQ 0}
   array set A $details
   if {[regexp {'(....)'} $A(targetApp) foo sig]} then {
      set err [catch {app::ensureRunning $sig} passing]
      if {$err == 1} then {set permanent $passing} else {
         set permanent ""
         set A(app) $A(targetApp)
      }
   } else {
      set tail [file tail $A(targetApp)]
         set running 0
         foreach pr [processes] {
            if {![string compare $tail [lindex $pr 0]]} then {
               set running 1
               break
            }
         }
      set err 0
      set permanent ""
      set A(app) $tail
      if {$running} then {
         set passing "App is running."
      } elseif {![catch {launch $A(targetApp)} passing]} then {
         set passing "Launched '$A(targetApp)'"
      } else {
         set err 1
         if {![file exists $A(targetApp)]} then {
            set passing "File '$A(targetApp)' not found."
         }
         set permanent $passing
         unset A(app)
      }
   }
   set A(joinString) [lindex [list \n \r \r\n " "] $A(joinString)]
   return [list $err $passing $permanent]
}
proc eemenu::doScriptAE::item {lines} {
   upvar #0 eemenu::doScriptAE::A A
   set script "$A(prefix)[join $lines $A(joinString)]$A(suffix)"
   if {$A(replyQ)} then {
      if {[catch {tclAE::build::resultData -t 30000 $A(app) misc dosc\
            ---- [tclAE::build::TEXT $script]} res]} then {
         list 1 "Error: $res" "Error: $res\n"
      } elseif {[string length $res]} then {
         list 0 $res "$res\n"
      } else {
         list 0 "Eval OK." ""
      }
   } else {
      tclAE::send $A(app) misc dosc ---- [tclAE::build::TEXT $script]
      list 0 "Sent [llength $lines] lines." ""
   }
}
proc eemenu::doScriptAE::end {} {list 0 "" ""}
}
if {[llength [info commands send]] && [info tclversion]>=8.0} then {
set eemenu::evaluate(tkSend) [list\
  [eemenu::define_detail Evaluate "Target" target var]\
  [eemenu::define_detail Evaluate "Alias behaviour"\
    aliasing [list menu [list "Ask once" "Ask each time" "Fail"]]\
    "Ask once" "The thing to do when the target is unavailable."]\
  [eemenu::define_detail Evaluate "Join lines using"\
    joinString [list menuindex [list Lf Cr CrLf Space]] 0]\
  [eemenu::define_detail Evaluate "Prefix" prefix var]\
  [eemenu::define_detail Evaluate "Suffix" suffix var]\
  [eemenu::define_detail Evaluate "Wait for reply" replyQ flag 1]]
namespace eval eemenu::tkSend {}
set eemenu::tkSend::last_target {}
proc eemenu::tkSend::begin {details source} {
   eemenu::multiupvar A alias last_target
   array set A {prefix {} suffix {} joinString 1 target {} replyQ 1\
     aliasing "Ask once"}
   array set A $details
   set T [lsort -dictionary [tcltk::listInterps]]
   switch -- $A(aliasing) "Ask each time" {
      if {[lsearch -exact $T $A(target)]>=0} then {
         set target $A(target)
      }
   } "Fail" {
      if {[lsearch -exact $T $A(target)]>=0} then {
         set target $A(target)
      } else {
         set passing "Target '$A(target)' unavailable."
         return [list 1 $passing $passing]
      }
   } default {
      set target $A(target)
      if {[info exists alias($target)]} then {
         set target $alias($target)
      }
      if {[lsearch -exact $T $target]<0} then {unset target}
   }
   if {![info exists target]} then {
      if {[catch {listpick -p "Target '$A(target)' unavailable.\
            Please pick a new one." -L [list $last_target]\
            [linsert $T end "------------------" "Launch new shell"]}\
          target]} then {
         return [list 1 "Canceled" ""]
      }
      switch -exact -- $target\
        "------------------" - "Launch new shell" {
	 if {[catch {::xserv::invoke tclInterpreterStart} T]} {
	     return [list 1 $T]
	 }
	 set target [lindex $T 0]
         set passing "Launched new shell '$target'."
      } default {
         set passing "Sending code to '$target'."
      }
      set last_target $target
      if {![string compare $A(aliasing) "Ask once"]} then {
         set alias($A(target)) $target
      }
   } else {
      set passing "Sending code to '$target'."
   }
   set A(target) $target
   set A(joinString) [lindex [list \n \r \r\n " "] $A(joinString)]
   return [list 0 $passing ""]
}
proc eemenu::tkSend::item {lines} {
   upvar #0 eemenu::tkSend::A A
   set script "$A(prefix)[join $lines $A(joinString)]$A(suffix)"
   if {$A(replyQ)} then {
      if {[catch {send $A(target) $script} res]} then {
         list 1 "Error: $res" "Error: $res\n"
      } elseif {[string length $res]} then {
         list 0 "Eval OK: $res" "$res\n"
      } else {
         list 0 "Eval OK." ""
      }
   } else {
      send -async $A(target) $script
      list 0 "Sent [llength $lines] lines." ""
   }
}
proc eemenu::tkSend::end {} {list 0 "" ""}
}
if {[llength [info commands dde]] && [info tclversion]>=8.0} then {
set eemenu::evaluate(windozeDDE) [list\
  [eemenu::define_detail Evaluate "Service" service var "TclEval"]\
  [eemenu::define_detail Evaluate "Target" target var]\
  [eemenu::define_detail Evaluate "Alias behaviour"\
    aliasing [list menu [list "Ask once" "Ask each time" "Fail"]]\
    "Ask once" "The thing to do when the target is unavailable."]\
  [eemenu::define_detail Evaluate "Launch command" launchCmd var2]\
  [eemenu::define_detail Evaluate "Join lines using"\
    joinString [list menuindex [list Lf Cr CrLf Space]] 2]\
  [eemenu::define_detail Evaluate "Prefix" prefix var]\
  [eemenu::define_detail Evaluate "Suffix" suffix var]\
  [eemenu::define_detail Evaluate "Requested data" request var]]
namespace eval eemenu::windozeDDE {}
set eemenu::windozeDDE::last_target {}
proc eemenu::windozeDDE::begin {details source} {
   eemenu::multiupvar A alias last_target
   array set A {service {} target {} aliasing "Ask once" launchCmd {}\
     prefix {} suffix {} joinString 2 request {}}
   array set A $details
   if {![string length $A(service)]} then {
      return [list 1 "No service has been specified." ""]
   }
   set T [list]
   foreach st [dde services $A(service) {}] {lappend T [lindex $st 1]}
   set T [lsort -dictionary $T]
   switch -- $A(aliasing) "Ask each time" {
      if {[lsearch -exact $T $A(target)]>=0} then {
         set target $A(target)
      }
   } "Fail" {
      if {[lsearch -exact $T $A(target)]>=0} then {
         set target $A(target)
      } else {
         set passing "Target '$A(target)' unavailable."
         return [list 1 $passing $passing]
      }
   } default {
      set target $A(target)
      if {[info exists alias($target)]} then {
         set target $alias($target)
      }
      if {[lsearch -exact $T $target]<0} then {unset target}
   }
   if {![info exists target]} then {
      set T2 $T
      if {[string length $A(launchCmd)]} then {
         if {[llength $T2]} then {lappend T2 "------------------"}
         lappend T2 "Launch another"
      }
      if {![llength $T2]} then {
         return [list 1 "No '$A(service)' targets are, or could be\
           made, available." ""]
      }
      if {[catch {listpick -p "Target '$A(target)' unavailable.\
            Please pick a new one." -L [list $last_target] $T2}\
          target]} then {
         return [list 1 "Canceled" ""]
      }
      switch -exact -- $target\
        "------------------" - "Launch another" {
         set before [clock seconds]
         uplevel #0 $A(launchCmd)
         set target {}
         while {[clock seconds] - $before < 60 &&\
           ![string length $target]} {
            foreach st [dde services $A(service) {}] {
               if {[lsearch -exact $T [lindex $st 1]]<0} then {
                  set target [lindex $st 1]
                  break
               }
            }
            update
         }
         if {![string length $target]} then {
            return [list 1 {Timed out; no new target launched within\
              60 seconds.} ""]
         }
         set passing "Launched new shell '$target'."
      } default {
         set passing "Sending code to '$target'."
      }
      set last_target $target
      if {![string compare $A(aliasing) "Ask once"]} then {
         set alias($A(target)) $target
      }
   } else {
      set passing "Sending code to '$target'."
   }
   set A(target) $target
   set A(joinString) [lindex [list \n \r \r\n " "] $A(joinString)]
   return [list 0 $passing ""]
}
proc eemenu::windozeDDE::item {lines} {
   upvar #0 eemenu::windozeDDE::A A
   set script "$A(prefix)[join $lines $A(joinString)]$A(suffix)"
   if {[catch {dde execute $A(service) $A(target) $script} res]} then {
      list 1 "dde error: $res" "$res\n"
   } elseif {![string length $A(request)]} then {
      list 0 "Sent [llength $lines] lines." ""
   } else {
      if {[catch {dde request $A(service) $A(target) $A(request)} res]}\
      then {
         list 1 "dde error: $res" "dde error: $res\n"
      } elseif {[string length $res]} then {
         list 0 $res "$res\n"
      } else {
         list 0 "Eval OK." ""
      }
   }
}
proc eemenu::windozeDDE::end {} {list 0 "" ""}
}
namespace eval eemenu::statusLine {}
set eemenu::report(statusLine) [list]
proc eemenu::statusLine::log_open {details source} {}
proc eemenu::statusLine::log_close {} {}
proc eemenu::statusLine::log_code {lines} {}
proc eemenu::statusLine::log_result {was_err passing permanent} {
   if {[string length $passing]} then {status::msg $passing}
}
set eemenu::report(logWindow) [list\
  [eemenu::define_detail Report "Window name" winName var "Log"]\
  [eemenu::define_detail Report "Window mode" winMode mode "Text"]\
  [eemenu::define_detail Report "Prompt" prompt var\
    "[text::Ascii 200 1] "]\
  [eemenu::define_detail Report "Antiprompt" antiprompt var ""]]
namespace eval eemenu::logWindow {}
proc eemenu::logWindow::log_open {details source} {
   upvar #0 eemenu::logWindow::A A
   array set A {winName {Log window} prompt {} antiprompt {}}
   array set A $details
   set win $A(winName)
   if {[lsearch -exact [winNames] $win] == -1} then {
      set call [list new -n $win -shell 1]
      if {[mode::exists $A(winMode)]} then {lappend call -m $A(winMode)}
      eval $call
   }
   set t [maxPos -w $win]
   selectText -w $win $t $t
}
proc eemenu::logWindow::log_code {lines} {
   upvar #0 eemenu::logWindow::A A
   insertText -w $A(winName) "$A(prompt)[join $lines "\n$A(prompt)"]\n"
}
proc eemenu::logWindow::log_result {was_err passing permanent} {
   if {[string length $permanent]} then {
      upvar #0 eemenu::logWindow::A A
      if {[string length $A(antiprompt)]} then {
         set L [lreplace [split $permanent \n\r] end end]
         set permanent "[join $L "\n$A(antiprompt)"]\n"
      }
      insertText -w $A(winName) "$A(antiprompt)$permanent"
   }
   if {[string length $passing]} then {status::msg $passing}
}
proc eemenu::logWindow::log_close {} {}
if {[info exists eemenu::cmdA]} then {return}
set {eemenu::cmdA(dtx -> internal Tcl)} [list\
  active 1 binding /L<O mode TeX\
  in_menu 0\
  extractor Docstrip extract_extra [list\
    filePatL *.dtx sourceEnvsL {tcl tcl*} lookAtEnvs 1\
  ]\
  complete "Tcl Info Complete" complete_extra {}\
  evaluator "Internal Tcl" eval_extra {}\
  reporter "Status Line" report_extra {}\
]
prefs::modified {eemenu::cmdA(dtx -> internal Tcl)}
catch {unset A}
array set A [set {eemenu::cmdA(dtx -> internal Tcl)}]
set A(active) 0
set A(in_menu) 1
if {[info exists eemenu::evaluate(doScriptAE)]} then {
   set A(evaluator) "Do Script AE"
   set A(eval_extra)\
     [list targetApp '${tclshSig}' joinString 0 replyQ 1]
} \
elseif {[info exists eemenu::evaluate(windozeDDE)]} then {
   set A(evaluator) "Windoze DDE"
   set A(eval_extra) [list\
     service TclEval target Tcl_1 launchCmd\
       {exec $tclshSig [file join $HOME Tools winRemoteShell.tcl] &}\
     joinString 0 prefix "catch \{" suffix "\} alpha_result"\
     request alpha_result]
} \
else {
   set A(evaluator) "Tk Send"
   set A(eval_extra) [list target wish joinString 0 replyQ 1]
}
set {eemenu::cmdA(dtx -> remote Tcl)} [array get A]
prefs::modified {eemenu::cmdA(dtx -> remote Tcl)}
unset A
set {eemenu::cmdA(Tcl Wiki)} [list\
  extractor Regexp extract_extra [list\
    filter_mode anti-grep searchRE {} replaceRE {}\
    filterRE {^[^ ]|^    (\*|[0-9]\.) |^   .+:   [^ ]} ]\
  complete "Tcl Info Complete" complete_extra {}\
  evaluator "Internal Tcl" eval_extra {}\
  reporter "Log Window" report_extra {winName {Wiki code log}\
    winMode Tcl prompt {% } antiprompt {}}\
  mode Wiki active [mode::exists Wiki] binding /L<O in_menu 1]
prefs::modified {eemenu::cmdA(Tcl Wiki)}
set eemenu::cmdA(Mathematica) [list\
  extractor Docstrip extract_extra [list\
    filePatL *.dtx sourceEnvsL {macrocode macrocode*} lookAtEnvs 1\
  ]\
  evaluator "Do Script AE" eval_extra\
     [list targetApp 'Math' joinString 1 replyQ 0]\
  complete "Entire Selection" complete_extra {}\
  reporter "Status Line" report_extra {}\
  active 0 binding /L<O mode TeX in_menu 0]
prefs::modified {eemenu::cmdA(Mathematica)}
## 
##
## End of file `eemenu.tcl'.

