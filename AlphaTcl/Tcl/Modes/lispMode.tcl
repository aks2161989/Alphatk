## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl extension packages
 #
 # FILE: "lispMode.tcl"  
 #                                          created: 01/28/2000 {07:38:42 PM}
 #                                      last update: 05/23/2006 {10:41:30 AM}
 # Description: 
 #
 # For editing Lisp files.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 2000-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ===========================================================================
#
# ×××× Initialization of Lisp mode ×××× #
# 

alpha::mode Lisp 2.3 lispMenu {
    *.el *.elc *.lisp *.lsp
} {
    lispMenu
} {
    # Script to execute at Alpha startup
    addMenu lispMenu "Lisp" Lisp
    set modeCreator(ROSA)   Lisp
    set modeCreator(xlsp)   Lisp
} uninstall {
    catch {file delete [file join $HOME Tcl Modes lispMode.tcl]}
    catch {file delete [file join $HOME Tcl Completions LispCompletions.tcl]}
    catch {file delete [file join $HOME Tcl Completions "Lisp Tutorial.el"]}
    catch {file delete [file join $HOME Help "Lisp Help"]}
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Supports the editing of [LIS]t [P]rocessing (Lisp) programming files
} help {
    file "Lisp Help"
}

proc lispMode.tcl {} {}

namespace eval Lisp {
    
    # Comment Character variables for Comment Line/Paragraph/Box menu items.
    variable commentCharacters
    array set commentCharacters [list \
      "General"         "; " \
      "Paragraph"       [list ";; " " ;;" " ; "] \
      "Box"             [list ";" 2 ";" 2 ";" 3] \
      ]
    
    # Set the list of flag preferences which can be changed in the menu.
    variable prefsInMenu [list \
      "fullIndent" \
      "noHelpKey" \
      "(-)" \
      "autoMark" \
      "markHeadingsOnly" \
      ]
    
    # Used in [Lisp::colorizeLisp].
    variable firstColorCall
    if {![info exists firstColorCall]} {
	set firstColorCall 1
    }
    
    # =======================================================================
    #
    # ×××× Keyword Dictionaries ×××× #
    #
    
    variable keywordLists
    
    # =======================================================================
    #
    # Lisp Accessors
    #
    
    set keywordLists(accessors) [list \
      aref bit caaaar caaadr caaar caadar caaddr caadr caar cadaar cadadr \
      cadar caddar cadddr caddr cadr car cdaaar cdaadr cdaar cdadar cdaddr \
      cdadr cdar cddaar cddadr cddar cdddar cddddr cdddr cddr cdr char \
      compiler-macro-function eighth elt fdefinition fifth fill-pointer \
      find-class first fourth get getf gethash ldb \
      logical-pathname-translations macro-function mask-field ninth nth \
      readtable-case rest row-major-aref sbit schar second seventh sixth \
      subseq svref symbol-function symbol-plist symbol-value tenth third \
      values \
      ]
    
    # =======================================================================
    #
    # Lisp Classes
    #
    
    set keywordLists(classes) [list standard-object structure-object]
    
    # =======================================================================
    #
    # Lisp Condition Types
    #
    
    set keywordLists(conditionTypes) [list \
      cell-error condition control-error division-by-zero end-of-file error \
      file-error floating-point-inexact floating-point-invalid-operation \
      floating-point-overflow floating-point-underflow package-error \
      parse-error print-not-readable program-error reader-error \
      serious-condition simple-condition simple-error simple-type-error \
      simple-warning storage-condition stream-error style-warning type-error \
      unbound-slot unbound-variable undefined-function warning \
      ]
    
    # =======================================================================
    #
    # Lisp Constant Variables
    #
    
    set keywordLists(constantVariables) [list \
      array-dimension-limit array-rank-limit array-total-size-limit boole-1 \
      boole-2 boole-and boole-andc1 boole-andc2 boole-c1 boole-c2 boole-clr \
      boole-eqv boole-ior boole-nand boole-nor boole-orc1 boole-orc2 \
      boole-set boole-xor call-arguments-limit char-code-limit \
      double-float-epsilon double-float-negative-epsilon \
      internal-time-units-per-second lambda-list-keywords \
      lambda-parameters-limit least-negative-double-float \
      least-negative-long-float least-negative-normalized-double-float \
      least-negative-normalized-long-float \
      least-negative-normalized-short-float \
      least-negative-normalized-single-float least-negative-short-float \
      least-negative-single-float least-positive-double-float \
      least-positive-long-float least-positive-normalized-double-float \
      least-positive-normalized-long-float \
      least-positive-normalized-short-float \
      least-positive-normalized-single-float least-positive-short-float \
      least-positive-single-float long-float-epsilon \
      long-float-negative-epsilon most-negative-double-float \
      most-negative-fixnum most-negative-long-float \
      most-negative-short-float most-negative-single-float \
      most-positive-double-float most-positive-fixnum \
      most-positive-long-float most-positive-short-float \
      most-positive-single-float multiple-values-limit nil pi \
      short-float-epsilon short-float-negative-epsilon single-float-epsilon \
      single-float-negative-epsilon t \
      ]
    
    
    # =======================================================================
    #
    # Lisp Declarations
    #
    
    set keywordLists(declarations) [list \
      declaration dynamic-extent ftype ignorable ignore, inline notinline \
      optimize special \
      ]
    
    # =======================================================================
    #
    # Lisp Functions
    #
    
    set keywordLists(functions) [list \
      - 1 1+ 1- => abort abs acons acos adjoin adjust-array \
      adjustable-array-p alpha-char-p alphanumericp append apply apropos \
      apropos-list arithmeti array-dimension array-dimensions \
      array-displacement array-element-type array-has array-in-bounds-p \
      array-rank array-row-major-index array-total-size arrayp ash asin \
      assoc assoc-if-not at-arguments atan atanh bit-and bit-andc1 \
      bit-andc2 bit-eqv bit-ior bit-nand bit-nor bit-not bit-orc1 bit-orc2 \
      bit-vector-p bit-xor boole both-case-p boundp break broadcast butlast \
      byte byte-position byte-size cal-pathname ceiling cell-error-name \
      cerror char char-code char-downcase char-equal char-greaterp char-int \
      char-lessp char-name char-not-equal char-not-greaterp char-not-lessp \
      char-upcase character characterp cis class-of clear-input \
      clear-output close clrhash code-char coerce compile compile-file \
      compile-file-pathname compiled-function-p complement complex complexp \
      compute-restarts concatenate conjugate cons consp constantly \
      constantp continue copy-alist copy-list copy-pprint-dispatch \
      copy-readtable copy-seq copy-structure copy-symbol copy-tree cos cosH \
      count count-if count-if-not dable-object decode-fl decode-float \
      decode-universal-time decoded-time delete delete-duplicates \
      delete-file delete-if delete-if-not delete-package denominator \
      deposit-field describe digit-char digit-char-p directory \
      directory-namestring disassemble dpb dribble echo-stream echo-stream \
      echo-stream-input-stream echo-stream-output-stream ed \
      encode-universal-time endp enough-namestring ensure-di ensure-ge eq \
      eql equal equalp error eval evenp every exp export expt fboundp \
      fceiling ffloor file-author file-error-pathname file-length \
      file-namestring file-position file-string-length file-write-date fill \
      find find-all-symbols find-if find-if-not find-package find-restart \
      find-symbol finish-output float floatp floor fmakunbound force-output \
      format fresh-line fround fround ftruncate funcall \
      function-lambda-expression functionp gcd gensym gentemp \
      get-dispatch-macro-character get-internal-real-time \
      get-internal-run-time get-macro-character get-outpu get-properties \
      get-setf-expansion get-unive graphic-char-p hash-table-count \
      hash-table-p hash-table-rehash-size hash-table-rehash-threshold \
      hash-table-size hash-table-test host-namestring identity imagpart \
      import input-stream input-stream-p inspect integer-length integerp \
      interactive-stream-p intern intersect intersection \
      invalid-method-error invoke-debugger invoke-re invoke-restart isqrt \
      keywordp last lcm ldb-test ldiff length lisp-implementation-type \
      lisp-implementation-version list list-all-packages list-length listen \
      listp listst ll-pointer-p load load-logi log logand logandc1 logandc2 \
      logbitp logcount logeqv logical-pathname logior lognand lognor lognot \
      logorc1 logorc2 logtest logxor long-site-name lower-case-p \
      machine-instance machine-type machine-version macroexpand \
      macroexpand-1 make-array make-broadcast-stream \
      make-concatenated-stream make-condition make-dispatch-macro-character \
      make-echo-stream make-hash-table make-list \
      make-load-form-saving-slots make-package make-pathname \
      make-random-state make-sequence make-string make-string-input-stream \
      make-symbol make-synonym-stream make-two-way-stream makunbound map \
      map-into mapc mapcan mapcar mapcon mapcon maphash mapl maplist max \
      member member-if member-if-not merge merge-pathnames \
      method-combination-error min minusp mismatch mod muffle-warning \
      name-char name-version namestring nbutlast nconc not notany notevery \
      nreconc nreverse nset-difference nset-exclusive-or nstring-capitalize \
      nstring-downcase nstring-upcase nsublis nsubst nsubst-if \
      nsubst-if-not nteractively nthcdr null numberp numerator nunion oddp \
      open open-stream-p or-operation output-stream output-stream-p \
      package-error-package package-name package-nicknames package-s \
      package-use-list package-used-by-list packagep pairlis parse-integer \
      parse-namestring pathname pathname- pathname-match-p pathnamep \
      peek-char phase pl plusp position position-if position-if-not pprint \
      pprint-dispatch pprint-fill pprint-indent pprint-linear \
      pprint-newline pprint-tab pprint-tabular prin1 prin1-to-string princ \
      princ-to-string print print-not probe-file proclaim provide random \
      random-state-p rassoc rassoc-if rassoc-if-not rational rationalize \
      rationalp read read-byte read-char read-char-no-hang \
      read-delimited-list read-from-string read-line \
      read-preserving-whitespace read-sequence readtablep realp realpart \
      ream-streams ream-streams reduce rem remhash remove remove-duplicates \
      remove-if remove-if-not remprop rename-file rename-package replace \
      require restart-name revappend reverse ric-function room round rplaca \
      rplacd search set set-difference set-dispatch-macro-character \
      set-exclusive-or set-macro-character set-pprint-dispatch \
      set-syntax-from-char shadow shadowing-import short-site-name signal \
      signum simple-bit-vector-p simple-condition-format-arguments \
      simple-condition-format-control simple-string-p simple-vector-p sin \
      sinh sl sleep slot-boundp slot-exists-p slot-makunbound slot-value \
      software-type software-version some sort special-operator-p sqrt st \
      stable-sort standard-char-p store-value stream-element-type \
      stream-error-stream stream-external-format streamp string string \
      string-capitalize string-downcase string-equal string-greaterp \
      string-left-trim string-lessp string-not-equal string-not-greaterp \
      string-not-lessp string-right-trim string-trim string-upcase \
      stringeqc stringp sublis subsetp subst subst-if subst-if-not \
      subst-if-not substitute subtypep sxhash symbol-name symbol-package \
      symbolp synonym-stream-symbol tailp tan terpri tories-exist translate \
      translate-pathname translations tream-string tree-equal truename \
      truncate two-way-stream-input-stream two-way-stream-output-stream \
      type-error-datum type-error-expected-type type-of typep \
      unbound-slot-instance unexport unintern union unread-char \
      unuse-package upgraded-array-element-type upgraded-complex-part-type \
      upper-case-p use-package use-value user-homedir-pathname values-list \
      vector vector-pop vector-push vector-push-extend vectorp warn \
      wild-pathname-p wing-symbols write write-byte write-char write-line \
      write-sequence write-string write-to-string y-or-n-p yes-or-no-p \
      zerop \
      ]
    
    # =======================================================================
    #
    # Lisp Macros
    #
    
    set keywordLists(macros) [list \
      and assert case ccase check-type cond decf declaim defclass \
      defconstant defgeneric define-compiler-macro define-condition \
      define-method-combination define-setf-expander define-symbol-macro \
      defmacro defmethod defpackage defparameter defsetf defstruct deftype \
      defun defvar destructuring-bind do do-all-symbols do-external-symbols \
      do-symbols dolist dotimes ecase etypecase formatter handler-bind \
      handler-case ignore-errors in-package incf lambda loop \
      multiple-value-bind multiple-value-list multiple-value-setq nth-value \
      or pop pprint-logical-block print-unreadable-object prog prog1 prog2 \
      progst psetf psetq push pushnew remf restart-bind restart-case return \
      rotatef setf shiftf step time trace typecase unless untrace when \
      with-accessors with-compilation-unit with-condition-restarts \
      with-hash-table-iterator with-input-from-string with-open-file \
      with-open-stream with-output-to-string with-package-iterator \
      with-simple-restart with-slots with-standard-io-syntax \
      ]
    
    # =======================================================================
    #
    # Lisp Restarts
    #
    
    set keywordLists(restarts) [list abort continue muffle-warning]
    
    # =======================================================================
    #
    # Lisp Specials
    #
    
    set keywordLists(specials) [list \
      block catch eval-when flet function go if labels let load-time-value \
      locally macrolet multiple-value-call multiple-value-prog1 progn progv \
      quote return-from setq symbol-macrolet tagbody the throw \
      unwind-protect \
      ]
    
    # =======================================================================
    #
    # Lisp Standard Generic Functions
    #
    
    set keywordLists(standardGenericFunctions) [list \
      add-method allocate-instance change-class class-name class-name \
      compute-applicable-methods describe-object documentation find-method \
      function-keywords initialize-instance make-instance \
      make-instances-obsolete make-load-form method-qualifiers \
      no-applicable-method no-next-method print-object \
      reinitialize-instance remove-method shared-initialize slot-missing \
      slot-unbound update-instance-for-different-class \
      update-instance-for-redefined-class \
      ]
    
    # =======================================================================
    #
    # Lisp Symbols
    #
    
    set keywordLists(symbols) [list declare lambda]
    
    # =======================================================================
    #
    # Lisp System Classes
    #
    
    set keywordLists(systemClasses) [list \
      array bit-vector broadcast-stream built-in-class character class \
      complex concatenated-stream cons echo-stream file-stream float \
      function generic-function hash-table integer list logical-pathname \
      method method-combination null number package pathname random-state \
      ratio rational readtable real restart sequence standard-class \
      standard-generic-function standard-method stream string string-stream \
      structure-class symbol synonym-stream t two-way-stream vector \
      ]
    
    # =======================================================================
    #
    # Lisp Types
    #
    
    set keywordLists(types) [list \
      atom base-char base-string bignum bit boolean compiled-function \
      double-float extended-char fixnum keyword long-float nil short-float \
      signed-byte simple-array simple-base-string simple-bit-vector \
      simple-string simple-vector single-float standard-char unsigned-byte \
      ]
    
    # =======================================================================
    #
    # Lisp Type Specifiers
    #
    
    set keywordLists(typeSpecifiers) [list \
      and eql member mod not or satisfies values \
      ]
    
    # =======================================================================
    #
    # Lisp Variables
    #
    
    set keywordLists(variables) [list \
      *break-on-signals* *compile-file-pathname* *compile-file-truename* \
      *compile-print* *compile-verbose* *debug-io* *debugger-hook* \
      *default-pathname-defaults* *error-output* *features* \
      *gensym-counter* *load-pathname* *load-print* *load-truename* \
      *load-verbose* *macroexpand-hook* *modules* *package* *print-array* \
      *print-base* *print-case* *print-circle* *print-escape* \
      *print-gensym* *print-length* *print-level* *print-lines* \
      *print-miser-width* *print-pprint-dispatch* *print-pretty* \
      *print-radix* *print-readably* *print-right-margin* *query-io* \
      *read-base* *read-default-float-format* *read-eval* *read-suppress* \
      *readtable* *standard-input* *standard-output* *terminal-io* \
      *trace-output* random-statest \
      ]
    
    # =======================================================================
    #
    # Lisp Emacs Functions
    # 
    # ??
    # 
    
    set keywordLists(emacsMacros) [list \
      autoload beep cs defalias defconst defcustom defdir defgroup defsubst \
      ding force fset insert interactive mapconcat memq message prompt put \
      setcar switch vconcat while \
      ]
    
    # =======================================================================
    #
    # Lisp Emacs Arguments
    # 
    # ??
    # 
    
    set keywordLists(emacsArguments) [list \
      dirname fbuffer fname insertpos key nil node nodocs nomessage olist \
      position switches t tbuffer \
      ]
}

hook::register quitHook Lisp::quitHook

# ===========================================================================
#
# ×××× Setting Lisp mode variables ×××× #
#

# ===========================================================================
#
# Standard preferences recognized by various Alpha procs
#

newPref var  fillColumn        {75}            Lisp
newPref var  indentationAmount {4}             Lisp
newPref var  leftFillColumn    {0}             Lisp
newPref var  prefixString      {; }            Lisp
newPref var  wordBreak         {[\w\-]+}       Lisp
newPref var  lineWrap          {0}             Lisp
newPref var  commentsContinuation 1            Lisp "" \
  [list "only at line start" "spaces allowed" "anywhere"] index
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 Lisp
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Lisp


# ===========================================================================
#
# Flag preferences
#

# To automatically mark files when they are opened, turn this item on||To
# disable the automatic marking of files when they are opened, turn this
# item off
newPref flag autoMark          {0}      Lisp
# To indent all continued commands (indicated by unmatched parantheses) by
# the full indentation amount rather than half, turn this item on|| To
# indent all continued commands (indicated by unmatched parantheses) by half
# of the indentation amount rather than the full, turn this item off
newPref flag fullIndent        {1}      Lisp
# To primarily use a www site for help rather than the local Lisp
# application, turn this item on|| To primarily use the local Lisp
# application for help rather than on a www site turn this item off
newPref flag localHelp          {0}     Lisp     {Lisp::rebuildMenu lispHelp}
# To only mark "headings" in windows (those preceded by ;;;), turn this item
# on||To mark both commands and headings in windows, turn this item off
newPref flag markHeadingsOnly   {0}     Lisp     {Lisp::postBuildMenu}
# If your keyboard does not have a "Help" key, turn this item on.  This will
# change some of the menu's key bindings|| If your keyboard has a "Help"
# key, turn this item off.  This will change some of the menu's key bindings
newPref flag noHelpKey          {0}     Lisp     {Lisp::rebuildMenu lispHelp}

# This isn't used yet.
prefs::deregister "localHelp" "Lisp"

# ===========================================================================
#
# Variable preferences
# 

# Enter additional arguments to be colorized.
newPref var addArguments      {}              Lisp    {Lisp::colorizeLisp}
# Enter additional Lisp macros to be colorized.  
newPref var addMacros         {}              Lisp    {Lisp::colorizeLisp}
# Command double-clicking on a Lisp keyword will send it to this url
# for a help reference page.
newPref url lispHelp {http://www.lispworks.com/documentation/HyperSpec/} Lisp
# The "Lisp Home Page" menu item will send this url to your browser.
newPref url lispHomePage      {http://www.lisp.org/}      Lisp
# Click on "Set" to find the local Lisp application.
newPref sig lispSig          {ROSA}          Lisp

# ===========================================================================
# 
# Color preferences
#

prefs::renameOld LispmodeVars(commandColor) LispmodeVars(macroColor)

newPref color argumentColor     {magenta}       Lisp    {Lisp::colorizeLisp}
newPref color macroColor        {blue}          Lisp    {Lisp::colorizeLisp}
newPref color commentColor      {red}           Lisp    {stringColorProc}
newPref color stringColor       {green}         Lisp    {stringColorProc}
newPref color symbolColor       {magenta}       Lisp    {Lisp::colorizeLisp}

# ===========================================================================
# 
# Categories of all Lisp preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# Editing
prefs::dialogs::setPaneLists "Lisp" "Editing" [list \
  "autoMark" \
  "electricBraces" \
  "fillColumn" \
  "fullIndent" \
  "indentOnReturn" \
  "indentationAmount" \
  "leftFillColumn" \
  "lineWrap" \
  "markHeadingsOnly" \
  "wordBreak" \
  ]

# Comments
prefs::dialogs::setPaneLists "Lisp" "Comments" [list \
  "commentColor" \
  "commentsContinuation" \
  "prefixString" \
  ]

# Colors
prefs::dialogs::setPaneLists "Lisp" "Colors" [list \
  "addArguments" \
  "addMacros" \
  "argumentColor" \
  "macroColor" \
  "stringColor" \
  "symbolColor" \
  ]

# Help
prefs::dialogs::setPaneLists "Lisp" "Lisp Help" [list \
  "lispHelp" \
  "lispHomePage" \
  "lispSig" \
  "localHelp" \
  "noHelpKey" \
  ]

# ===========================================================================
# 
# Colorize Lisp.
# 
# Used to update preferences, and could be called in a <mode>Prefs.tcl file
# 

proc Lisp::colorizeLisp {{pref ""}} {
    
    global LispmodeVars Lispcmds LispUserMacros LispUserArguments
    
    variable firstColorCall
    variable keywordLists
    
    set Lispcmds [list]
    # First setting aside only the commands, for [Lisp::Completion::Macro].
    set keywordLists(macroList) [list]
    eval [list lappend macroList] \
      $keywordLists(accessors) $keywordLists(classes) \
      $keywordLists(conditionTypes) $keywordLists(constantVariables) \
      $keywordLists(declarations) $keywordLists(functions) \
      $keywordLists(macros) $keywordLists(restarts) \
      $keywordLists(specials) $keywordLists(standardGenericFunctions) \
      $keywordLists(symbols) $keywordLists(systemClasses) \
      $keywordLists(types) $keywordLists(typeSpecifiers) \
      $keywordLists(variables) $keywordLists(emacsMacros) \
      $LispmodeVars(addMacros)
    
    if {[info exists LispUserMacros]} {
	eval [list lappend macroList] $LispUserMacros
    }
    set keywordLists(macroList) [lsort -dictionary -unique $macroList]
    # Create a list of arguments for colorizing.
    eval [list lappend arguments] \
      $keywordLists(emacsArguments) $LispmodeVars(addArguments)
    
    if {[info exists LispUserArguments]} {
	eval [list lappend arguments] $LispUserArguments
    }
    
    # "Lispcmds"
    eval [list lappend Lispcmds] $macroList $arguments
    set Lispcmds [lsort -dictionary -unique $Lispcmds]
    
    # Now we colorize keywords.  If this is the first call, we don't include 
    # the "-a" flag.
    if {$firstColorCall} {
	regModeKeywords -C Lisp {}
	set firstColorCall 0
    }
    # Color comments and strings
    regModeKeywords -a -e {;} -c $LispmodeVars(commentColor) \
      -s $LispmodeVars(stringColor) Lisp
    
    # Commmands
    regModeKeywords -a -k $LispmodeVars(macroColor) Lisp $macroList
    
    # Arguments
    regModeKeywords -a -k $LispmodeVars(argumentColor) Lisp $arguments
    
    # Symbols
    regModeKeywords -a -i "+" -i "-" -i "*" -i "\\" -i "/" \
      -I $LispmodeVars(symbolColor) Lisp {}
    regModeKeywords -a -i "'" -i "`" \
      -I $LispmodeVars(stringColor) Lisp {}
    
    if {($pref ne "")} {
	refresh
    }
    return
}

# Call this now.
Lisp::colorizeLisp

# ===========================================================================
#
# ×××× Key Bindings, Electrics ×××× #
# 
# abbreviations:  <o> = option, <z> = control, <s> = shift, <c> = command
# 

# Known bug: Key-bindings from other global menus might conflict with those
# defined in the Lisp menu.  This will help ensure that this doesn't happen.

Bind '\r'   <s>     {Lisp::continueMacro} Lisp
Bind '\)'           {Lisp::electricRight "\)"} Lisp

# For those that would rather use arrow keys to navigate.  Up and down
# arrow keys will advance to next/prev command, right and left will also
# set the cursor to the top of the window.

Bind    up  <sz>    {Lisp::searchFunc 0 0 0} Lisp
Bind  left  <sz>    {Lisp::searchFunc 0 0 1} Lisp
Bind  down  <sz>    {Lisp::searchFunc 1 0 0} Lisp
Bind right  <sz>    {Lisp::searchFunc 1 0 1} Lisp

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::carriageReturn" --
 # 
 # Inserts a carriage return, and indents properly.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::carriageReturn {} {
    
    global LispmodeVars
    
    if {[isSelection]} {
	deleteSelection
    }
    set pos1 [lineStart [getPos]]
    set pos2 [getPos]
    if {[regexp {^[\t ]*\)} [getText $pos1 $pos2]]} {
	createTMark temp $pos2
	bind::IndentLine
	gotoTMark temp
	removeTMark temp
    }
    insertText "\r"
    bind::IndentLine
    return
}

proc Lisp::electricRight {{char "\}"}} {
    
    set pos [getPos]
    typeText $char
    if {![regexp {[^ \t]} [getText [lineStart $pos] $pos]]} {
	set pos [lineStart $pos]
	createTMark temp [getPos]
	bind::IndentLine
	gotoTMark temp
	removeTMark temp
	bind::CarriageReturn
    }
    if {[catch {blink [matchIt $char [pos::math $pos - 1]]}]} {
	beep
	status::msg "No matching $char !!"
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::continueMacro" --
 # 
 # Over-rides the automatic indentation of lines that begin with \) so that
 # additional text can be entered.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::continueMacro {} {
    
    global LispmodeVars indentationAmount
    
    Lisp::carriageReturn
    if {[pos::compare [getPos] != [maxPos]]} {
	set nextChar [getText [getPos] [pos::math [getPos] + 1]]
	if {($nextChar eq "\)")} {
	    set continueIndent [expr {$LispmodeVars(fullIndent) + 1}]
	    insertText [text::indentOf \
	      [expr {$continueIndent * $indentationAmount/2}]]
	}
    }
    return
}

proc Lisp::searchFunc {direction args} {
    
    if {![llength $args]} {
	set args [list 0 2]
    }
    if {$direction} {
	eval function::next $args
    } else {
	eval function::prev $args
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::getLimits" --
 # 
 # This is used preferentially by 'function::getLimits'
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::getLimits {args} {
    
    win::parseArgs w pos direction
    
    set posBeg ""
    set posEnd ""
    set what   "macro"
    # The idea is to find the start of the closest macro (in the
    # specified direction, and based solely on indentation), the start
    # of the next, and then back up to remove empty lines.  Trailing
    # parens are not ignored backing up, so that they are retained as
    # part of the macro.
    set pat1 {^\([^\r\n\t \;]}
    set pat2 {^[\t ]*(;.*)?$}
    set pos1 $pos
    set posBeg ""
    set posEnd ""
    if {![catch {search -w $w -f $direction -s -r 1 -i 1 $pat1 $pos1} match]} {
	# This is the start of the closest function.
	set posBeg [lindex $match 0]
	set pos2   [lindex $match 1]
	if {![catch {search -w $w -s -f 1 -r 1 $pat1 $pos2} match]} {
	    # This is the start of the next one.
	    set posEnd [lindex $match 0]
	} else {
	    set posEnd [maxPos -w $w]
	}
	# Now back up to skip empty lines, ignoring comments as well.
	while {1} {
	    set posEndPrev [pos::math -w $w $posEnd - 1]
	    set prevLine   [getText -w $w \
	      [pos::lineStart -w $w $posEndPrev] $posEndPrev]
	    if {![regexp $pat2 $prevLine]} {
		break
	    }
	    set posEnd [lineStart -w $w $posEndPrev]
	}
    }
    return [list $posBeg $posEnd $what]
}

# ===========================================================================
#
# ×××× Indentation ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::correctIndentation" --
 # 
 # [Lisp::correctIndentation] is necessary for Smart Paste, and returns the
 # correct level of indentation for the current line.
 # 
 # Adapted from "schemeMode.tcl", which includes this rationale:
 # 
 # -------- 
 # 
 # Computing the balance of parentheses within the 'line'.
 # 
 # This appears to be utterly elementary.  One has to keep in mind however
 # that parentheses might appear in comments and/or quoted strings, in which
 # case they shouldn't count.  Although it's easy to detect a Scheme comment
 # by a semicolon, a semicolon can also appear within a quoted string.  Note
 # that a double quote isn't that sure a sign of a quoted string: the double
 # quote may be escaped.  And the backslash can be escaped in turn...  Thus
 # we face a full-blown problem of parsing a string according to a
 # context-free grammar.  We note however that a TCL interpretor does similar
 # kind of parsing all the time.  So, we can piggy-back on it and have it
 # decide what is the quoted string and when a semicolon really starts a
 # comment.  To this end, we replace all non-essential characters from the
 # 'line' with spaces, separate all parens with spaces (so each paren would
 # register as a separate token with the TCL interpretor), replace a
 # semicolon with an opening brace (which, if unescaped and unquoted, acts as
 # some kind of "comment", that is, shields all symbols that follows).  After
 # that, we get TCL interpretor to convert thus prepared 'line' into a list,
 # and simply count the balance of '(' and ')' tokens.
 # 
 # -------- 
 # 
 # Given that initial plan, I have adapted it to simply remove anything
 # surrounded by double quotes (taking pains to still honor literal
 # characters), remove valid comments, and convert the remaining parans into
 # "more" and "less".  No need to piggy-back on the Tcl interpreter anymore.
 # 
 # -- cbu
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::correctIndentation {args} {
    
    global LispmodeVars indentationAmount
    
    win::parseArgs w pos {next ""}
    
    if {([win::getMode $w] eq "Lisp")} {
	set continueIndent [expr {$LispmodeVars(fullIndent) + 1}]
    } else {
	set continueIndent 1
    }
    set continueIndent [expr {$indentationAmount * $continueIndent/2}]
    
    set posBeg   [pos::lineStart -w $w $pos]
    # Get information about this line, previous line ...
    set thisLine [Lisp::getMacroLine -w $w $posBeg 1 1]
    set prevLine [Lisp::getMacroLine -w $w [pos::math -w $w $posBeg - 1] 0 1]
    set lwhite   [lindex $prevLine 1]
    # If we have a previous line ...
    if {[pos::compare -w $w [lindex $prevLine 0] != $posBeg]} {
	# Find out if there are any unbalanced (,) in the last line.
	regsub -all {[^ \(\)\"\;\\]} $prevLine { } line
	# Remove all literals.
	regsub -all {\\\(|\\\)|\\\"|\\;} $line { } line
	regsub -all {\\} $line { } line
	# If there is only one quote in a line, next to a closing brace,
	# assume that this is a continued quote from another line.  So add
	# a double quote at the beginning of the line (which will make us
	# ignore everything up to that point).  Not entirely foolproof ...
	if {![regexp -- {\".+\"} $line] && [regexp {\"[\t ]*\)} $line]} {
	    set line [concat \"$line]
	}
	# Remove everything surrounded by quotes.
	regsub -all {\"([^\"]+)\"} $line { } line
	regsub -all {\"} $line { } line
	# Remove all characters following the first valid comment.
	if {[regexp -- {;} $line]} {
	    set line [string range $line 0 [string first {;} $line]]
	}
	# Now turn all braces into "more" and "less"
	regsub -all {\(} $line { more } line
	regsub -all {\)} $line { less } line
	# Now indent based upon more and less.
	foreach i $line {
	    if {($i eq "more")} {
		incr lwhite $continueIndent
	    } elseif {($i eq "less")} {
		incr lwhite -$continueIndent
	    }
	}
	# Did the last line start with a lone \) ?  If so, we want to keep the
	# indent, and not make call it an unbalanced line.
	if {[regexp {^[\t ]*\)} [lindex $prevLine 2]]} {
	    incr lwhite $continueIndent
	}
    }
    # If we have a current line ...
    if {[pos::compare -w $w [lindex $thisLine 0] == $posBeg]} {
	# Reduce the indent if the first non-whitespace character of this
	# line is \) or \}.
	if {($next eq "\)") || [regexp {^[\t ]*\)} [lindex $thisLine 2]]} {
	    incr lwhite -$continueIndent
	}
    }
    # Now we return the level to the calling proc.
    return [expr {($lwhite > 0) ? $lwhite : 0}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::getMacroLine" --
 # 
 # Find the next/prev command line relative to a given position, and return
 # the position in which it starts, its indentation, and the complete text of
 # the command line.  If the search for the next/prev command fails, return
 # an indentation level of 0.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::getMacroLine {args} {
    
    win::parseArgs w pos {direction 1} {ignoreComments 1}
    
    if {$ignoreComments} {
	set pat {^[\t ]*[^\t\r\n\; ]}
    } else {
	set pat {^[\t ]*[^\t\r\n ]}
    }
    set posBeg [pos::math -w $w [pos::lineStart -w $w $pos] - 1]
    if {[pos::compare -w $w $posBeg < [minPos -w $w]]} {
	set posBeg [minPos -w $w]
    }
    set lwhite 0
    if {![catch {search -w $w -s -f $direction -r 1 $pat $pos} match]} {
	set posBeg [lindex $match 0]
	set lwhite [lindex [pos::toRowCol -w $w \
	  [pos::math -w $w [lindex $match 1] - 1]] 1]
    }
    set posEnd [pos::math -w $w [pos::nextLineStart -w $w $posBeg] - 1]
    if {[pos::compare -w $w $posEnd > [maxPos -w $w]]} {
	set posEnd [maxPos -w $w]
    } elseif {[pos::compare -w $w $posEnd < $posBeg]} {
	set posEnd $posBeg
    }
    return [list $posBeg $lwhite [getText -w $w $posBeg $posEnd]]
}

# ===========================================================================
# 
# ×××× Command Double Click ×××× #
#
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::DblClick" --
 # 
 # Checks to see if the highlighted word appears in any keyword list, and if
 # so, sends the selected word to the www.Lisp.com help site.
 # 
 # Control-Command double click will insert syntax information in status bar.
 # Shift-Command double click will insert commented syntax information in window.
 # 
 # (The above is not yet implemented: need to enter all of the syntax info.)
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::DblClick {from to shift option control} {
    
    global LispmodeVars Lispcmds 
    
    variable syntaxMessages
    
    selectText $from $to
    set command [getSelect]
    
    set varDef "(def|make)+(\[-a-zA-Z0-9\]+(\[\t\' \]+$command)+\[\t\r\n\(\) \])"
    
    if {![catch {search -s -f 1 -r 1 -m 0 $varDef [minPos]} match]} {
	# First check current file for a function, variable (etc)
	# definition, and if found ...
	placeBookmark
	goto [lineStart [lindex $match 0]]
	status::msg "press <Ctl .> to return to original cursor position"
	return
	# Could next check any open windows, or files in the current
	# window's folder ...  but not implemented.  For now, variables
	# (etc) need to be defined in current file.
    }
    if {![lcontains Lispcmds $command]} {
	status::msg "'$command' is not defined as a Lisp system keyword."
	return
    }
    # Any modifiers pressed?
    if {$control} {
	# CONTROL -- Just put syntax message in status bar window
	if {[info exists syntaxMessages($command)]} {
	    status::msg "$syntaxMessages($command)"
	} else {
	    status::msg "Sorry, no syntax information available for $command"
	}
    } elseif {$shift} {
	# SHIFT --Just insert syntax message as commented text
	if {[info exists syntaxMessages($command)]} {
	    endOfLine
	    insertText "\r"
	    insertText "$syntaxMessages($command)"
	    comment::Line
	} else {
	    status::msg "Sorry, no syntax information available for $command"
	}
    } else {
	# No modifiers -- Send command for on-line help.  This is the
	# "default" behavior.
	status::msg "'$command' sent to $LispmodeVars(lispHelp)$command"
	Lisp::wwwMacroHelp $command
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::wwwMacroHelp" --
 # 
 # Send command to defined url, prompting for text if necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::wwwMacroHelp {{command ""}} {
    
    global LispmodeVars
    
    # Do we have a command?
    if {($command eq "")} {
	if {[catch {getSelect} command]} {
	    set command ""
	}
	set command [prompt "On-line Lisp help for É" $command]
    }
    if {[regexp " " $command]} {
	# No spaces allowed.
	set returnMsg "only enter one command to be queried."
    } elseif {[set type [Lisp::checkKeywords [list $command] 1 1]] eq 0} {
	# Unknown type.
	set returnMsg "this keyword is not recognized by Lisp mode."
    } else {
	# Change the type for the url.  In some cases, we should also do a
	# switch of 'command' to properly map some urls that combine two or
	# more commands, but that will have to wait.
	switch -- $type {
	    "accessors"                  {set type "acc"}
	    "classes"                    {set type "cla"}
	    "condition types"            {set type "contyp"}
	    "constant variables"         {set type "convar"}
	    "declarations"               {set type "dec"}
	    "functions"                  {set type "fun"}
	    "default macros"             {set type "mac"}
	    "restarts"                   {set type "res"}
	    "specials"                   {set type "speope"}
	    "standard genericfunctions"  {set type "stagenfun"}
	    "symbols"                    {set type "sym"}
	    "system classes"             {set type "syscla"}
	    "types"                      {set type "typ"}
	    "type specifiers"            {set type "typspe"}
	    "variables"                  {set type "var"}
	    default {
		set returnMsg "No www help is available for keywords of type '$type'."
	    }
	}
    }
    if {[info exists returnMsg]} {
	status::msg $returnMsg
    } else {
	status::msg "'$command' sent to $LispmodeVars(lispHelp)"
	# The Lisp HyperSpec web sites used to use this:
	# 
	# urlView $LispmodeVars(lispHelp)${type}_${command}.html
	# 
	# but now the best we can do is an index page.
	set First [string toupper [string index $command 0]]
	urlView $LispmodeVars(lispHelp)Front/X_Mast_${First}.htm
    }
    return
}

proc Lisp::localMacroHelp {args} {
    Lisp::betaMessage
    return
}

# ===========================================================================
#
# ×××× Mark File and Parse Functions ×××× #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::MarkFile" --
 # 
 # This will return the first 35 characters from the first non-commented word
 # that appears in position 0.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::MarkFile {args} {
    
    global LispmodeVars
    
    win::parseArgs w
    
    status::msg "Marking \"[win::Tail $w]\" É"
    
    set count1 0
    set count2 0
    set pos [minPos -w $w]
    if {!$LispmodeVars(markHeadingsOnly)} {
	set pat {^(;;\*;;[ ]|;;;\*;;;[ ]|\()[a-zA-Z0-9]}
    } else {
	set pat {^(;;\*;;|;;;\*;;;)[\t ][^\r\n\t ]}
    }
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1 $pat $pos} match]} {
	set pos0 [lindex $match 0]
	set pos1 [pos::nextLineStart -w $w $pos0]
	set mark [string trimright [getText -w $w $pos0 $pos1]]
	# Add a little indentation so that section marks show up better
	set mark "  [string trimleft $mark " "]"
	if {[regexp -- {^\s;;;*\*;;;*\s*-+\s*$} $mark]} {
	    set mark "-"
	} elseif {[regsub {  ;;;\*;;; } $mark {* } mark]} {
	    incr count2
	} elseif {[regsub {  ;;\*;; } $mark {¥ } mark]} {
	    incr count2
	} else {
	    incr count1
	}
	# Truncate if necessary.
	set mark [markTrim [string trimright $mark ";" ]]
	while {[lcontains marks $mark]} {
	    append mark " "
	}
	lappend marks $mark
	setNamedMark -w $w $mark $pos0 $pos0 $pos0
	set pos $pos1
    }
    if {!$LispmodeVars(markHeadingsOnly)} {
	set msg "The window \"[win::Tail $w]\" contains $count1 command"
	append msg [expr {($count1 == 1) ? "." : "s."}]
    } else {
	set msg "The window \"[win::Tail $w]\" contains $count2 heading"
	append msg [expr {($count2 == 1) ? "." : "s."}]
    }
    status::msg $msg
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::parseFuncs" --
 # 
 # This will return only the Lisp command names.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::parseFuncs {} {
    
    global sortFuncsMenu
    
    set pos [minPos]
    set m   [list ]
    while {![catch {search -s -f 1 -r 1 -i 0 {^\((\w+)} $pos} match]} {
	if {[regexp -- {(\w+)} [eval getText $match] "" word]} {
	    lappend m [list $word [lindex $match 0]]
	}
	set pos [lindex $match 1]
    }
    if {$sortFuncsMenu} {
	set m [lsort -dictionary $m]
    }
    return [join $m]
}

# ===========================================================================
# 
# ×××× -------------------- ×××× #
# 
# ×××× Lisp Menu ×××× #
# 

proc lispMenu {} {}

# Tell Alpha what procedures to use to build all menus, submenus.
menu::buildProc lispMenu Lisp::buildMenu      Lisp::postBuildMenu
menu::buildProc lispHelp Lisp::buildHelpMenu

# First build the main Lisp menu.

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::buildMenu" --
 # 
 # Build the Lisp menu.  We leave out these items:
 # 
 #   "/P<U<OprocessFile"
 #   "/P<U<O<BprocessSelection"
 # 
 # until they are properly implemented.
 #   
 # --------------------------------------------------------------------------
 ##

proc Lisp::buildMenu {} {
    
    global lispMenu
    
    variable prefsInMenu
    
    set optionItems $prefsInMenu
    set keywordItems [list \
      "listKeywords" "checkKeywordsÉ" "addNewMacrosÉ" "addNewArgumentsÉ"]
    set menuList [list \
      "lispHomePage" \
      "switchToLisp" \
      "(-)" \
      [list Menu -n lispHelp           -M Lisp {}] \
      [list Menu -n lispModeOptions -p Lisp::menuProc -M Lisp $optionItems] \
      [list Menu -n lispKeywords    -p Lisp::menuProc -M Lisp $keywordItems] \
      "(-)" \
      "/b<UcontinueMacro" \
      "/'<E<S<BnewComment" \
      "/'<S<O<BcommentTemplateÉ" \
      "(-)" \
      "/N<U<BnextMacro" \
      "/P<U<BprevMacro" \
      "/S<U<BselectMacro" \
      "/I<B<OreformatMacro" \
      ]
    set submenus [list lispHelp]
    return       [list build $menuList "Lisp::menuProc -M Lisp" $submenus $lispMenu]
}

# Then build the "Lisp Help" submenu.

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::buildHelpMenu" --
 # 
 # Build the "Scheme Help" menu.  We leave out these items:
 # 
 #   "${key}<IlocalMacroHelpÉ"
 #   "${key}<OlocalMacroHelpÉ"
 # 
 # until they are properly implemented.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::buildHelpMenu {} {
    
    global LispmodeVars
    
    # Determine which key should be used for "Help", with F8 as option.
    if {!$LispmodeVars(noHelpKey)} {
	set key "/t"
    } else {
	set key "/l"
    }
    set menuList [list "${key}<IwwwMacroHelpÉ" "setLispApplicationÉ" \
      "${key}<BlispModeHelp"]
    
    return [list build $menuList "Lisp::menuProc -M Lisp" {}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::postBuildMenu" --
 # 
 # Mark or dim items as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::postBuildMenu {args} {
    
    global LispmodeVars
    
    variable prefsInMenu
    
    foreach itemName $prefsInMenu {
	if {[info exists LispmodeVars($itemName)]} {
	    markMenuItem lispModeOptions $itemName $LispmodeVars($itemName) Ã
	}
    }
    return
}

# Now we actually build the Lisp menu.
menu::buildSome lispMenu

proc Lisp::rebuildMenu {{menuName "lispMenu"}} {
    menu::buildSome $menuName
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::registerOWH" --
 # 
 # Dim some menu items when there are no open windows.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::registerOWH {{which "register"}} {
    
    global lispMenu
    
    set menuItems {
	processFile processSelection continueMacro
	newComment commentTemplateÉ
	nextMacro prevMacro selectMacro reformatMacro
    }
    foreach i $menuItems {
	hook::${which} requireOpenWindowsHook [list $lispMenu $i] 1
    }
    return
}

# Call this now.
Lisp::registerOWH register
rename Lisp::registerOWH ""

# ===========================================================================
# 
# ×××× Lisp menu support ×××× #
# 
# We make some of these items "Lisp Mode Only", in case Scheme mode also
# uses this menu.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::menuProc" --
 # 
 # This is the procedure called for all main menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::menuProc {menuName itemName} {
    
    global Lispcmds LispmodeVars mode
    
    variable prefsInMenu
    
    switch $menuName {
	"lispHelp" {
	    switch $itemName {
		"setLispApplication"  {Lisp::setApplication "Lisp"}
		"lispModeHelp"        {package::helpWindow "Lisp"}
		default               {Lisp::$itemName}
	    }
	}
	"lispModeOptions" {
	    if {[getModifiers]} {
		set helpText [help::prefString $itemName "Lisp"]
		if {$LispmodeVars($itemName)} {
		    set end "on"
		} else {
		    set end "off"
		}
		if {($end eq "on")} {
		    regsub {^.*\|\|} $helpText {} helpText
		} else {
		    regsub {\|\|.*$} $helpText {} helpText
		}
		set msg "The '$itemName' preference for Lisp mode is currently $end."
		dialog::alert "${helpText}."
	    } elseif {[lcontains prefsInMenu $itemName]} {
		set LispmodeVars($itemName) [expr {$LispmodeVars($itemName) ? 0 : 1}]
		if {($mode eq "Lisp")} {
		    synchroniseModeVar $itemName $LispmodeVars($itemName)
		} else {
		    prefs::modified $LispmodeVars($itemName)
		}
		if {[regexp {Help} $itemName]} {
		    Lisp::rebuildMenu "lispHelp"
		}
		Lisp::postBuildMenu
		if {$LispmodeVars($itemName)} {
		    set end "on"
		} else {
		    set end "off"
		}
		set msg "The '$itemName' preference is now $end."
	    } else {
		set msg "Don't know what to do with '$itemName'."
	    }
	    if {[info exists msg]} {
		status::msg $msg
	    }
	}
	"lispKeywords" {
	    if {$itemName eq "listKeywords"} {
		set keywords [listpick -l -p "Current Lisp mode keywordsÉ" $Lispcmds]
		foreach keyword $keywords {
		    Lisp::checkKeywords $keyword
		}
	    } elseif {($itemName eq "addNewMacros") \
	      || ($itemName eq "addNewArguments")} {
		set itemName [string trimleft $itemName "addNew"]
		Lisp::addKeywords $itemName
	    } else {
		Lisp::$itemName
	    }
	    return
	}
	"markLispFileAs" {
	    removeAllMarks
	    switch $itemName {
		"source"    {Lisp::MarkFile}
	    }
	}
	default {
	    switch $itemName {
		"lispHomePage"    {url::execute $LispmodeVars(lispHomePage)}
		"switchToLisp"    {app::launchFore $LispmodeVars(lispSig)}
		"newComment"      {comment::newComment 0}
		"commentTemplate" {comment::commentTemplate}
		"nextMacro"       {Lisp::searchFunc 1 0 0}
		"prevMacro"       {Lisp::searchFunc 0 0 0}
		"selectMacro"     {function::select}
		"reformatMacro"   {function::reformat}
		default           {Lisp::$itemName}
	    }
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::betaMessage" --
 # 
 # Give a beta message for untested features / menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::betaMessage {{item ""}} {
    
    if {($item eq "")} {
	if {[catch {info level -1} item]} {
	    set item "this item"
	}
    }
    status::msg "Sorry -- '$item' has not been implemented yet."
    return -code return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::sig" --
 # 
 # Return the Lisp signature.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::sig {{app "Lisp"}} {
    
    global LispmodeVars
    
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    if {($LispmodeVars(${lowApp}Sig) eq "")} {
	alertnote "Looking for the $capApp application ..."
	Lisp::selectApplication $lowApp
    }
    return $LispmodeVars(${lowApp}Sig)
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::setApplication" --
 # 
 # Prompt the user to locate the local Lisp application.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::setApplication {{app "Lisp"}} {
    
    global LispmodeVars
    
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    
    set newSig ""
    set newSig [dialog::askFindApp $capApp $LispmodeVars(${lowApp}Sig)]
    
    if {($newSig ne "")} {
	set LispmodeVars(${lowApp}Sig) "$newSig"
	prefs::modified LispmodeVars(${lowApp}Sig)
	status::msg "The $capApp signature has been changed to '$newSig'."
	return
    } else {
	status::msg "Cancelled."
	return -code return
    }
}

# ===========================================================================
# 
# ×××× Keywords ×××× #
# 

proc Lisp::addKeywords {{category} {keywords ""}} {
    
    global LispmodeVars
    
    if {($keywords eq "")} {
	set keywords [prompt "Enter new Lisp mode $category:" ""]
    }
    
    # Check to see if the keyword is already defined.
    foreach keyword $keywords {
	set checkStatus [Lisp::checkKeywords $keyword 1 0]
	if {($checkStatus ne 0)} {
	    alertnote "Sorry, '$keyword' is already defined\
	      in the $checkStatus list."
	    status::msg "Cancelled."
	    return -code return
	}
    }
    # Keywords are all new, so add them to the appropriate mode preference.
    append LispmodeVars(add$category) " $keywords"
    set LispmodeVars(add$category) [lsort $LispmodeVars(add$category)]
    synchroniseModeVar add$category $LispmodeVars(add$category)
    Lisp::colorizeLisp
    status::msg "'$keywords' added to Lisp $category preference."
    return
}

proc Lisp::checkKeywords {{newKeywordList ""} {quietly 0} {noPrefs 0}} {
    
    global LispmodeVars
    
    global LispUserMacros LispUserArguments
    
    variable keywordLists
    
    set type 0
    if {($newKeywordList eq "")} {
	set quietly 0
	set newKeywordList [prompt "Enter Lisp mode keywords to be checked:" ""]
    }
    # Check to see if the new keyword(s) is already defined.
    foreach newKeyword $newKeywordList {
	if {[lcontains keywordLists(accessors) $newKeyword]} {
	    set type "accessors"
	} elseif {[lcontains keywordLists(classes) $newKeyword]} {
	    set type "classes"
	} elseif {[lcontains keywordLists(conditionTypes) $newKeyword]} {
	    set type "condition types"
	} elseif {[lcontains keywordLists(constantVariables) $newKeyword]} {
	    set type "constant variables"
	} elseif {[lcontains keywordLists(declarations) $newKeyword]} {
	    set type "declarations"
	} elseif {[lcontains keywordLists(functions) $newKeyword]} {
	    set type "functions"
	} elseif {[lcontains keywordLists(macros) $newKeyword]} {
	    set type "default macros"
	} elseif {[lcontains keywordLists(restarts) $newKeyword]} {
	    set type "restarts"
	} elseif {[lcontains keywordLists(specials) $newKeyword]} {
	    set type "specials"
	} elseif {[lcontains keywordLists(standardGenericFunctions) $newKeyword]} {
	    set type "standard generic functions"
	} elseif {[lcontains keywordLists(symbols) $newKeyword]} {
	    set type "symbols"
	} elseif {[lcontains keywordLists(systemClasses) $newKeyword]} {
	    set type "system classes"
	} elseif {[lcontains keywordLists(types) $newKeyword]} {
	    set type "types"
	} elseif {[lcontains keywordLists(typeSpecifiers) $newKeyword]} {
	    set type "type specifiers"
	} elseif {[lcontains keywordLists(variables) $newKeyword]} {
	    set type "variables"
	} elseif {[lcontains keywordLists(emacsMacros) $newKeyword]} {
	    set type "emacs macros"
	} elseif {[lcontains keywordLists(emacsArguments) $newKeyword]} {
	    set type "emacs arguments"
	} elseif {[lcontains LispUserMacros $newKeyword]} {
	    set type "\$LispUserMacros"
	} elseif {[lcontains LispUserArguments $newKeyword]} {
	    set type "\$LispUserArguments"
	} elseif {!$noPrefs && [lcontains LispmodeVars(addMacros) $newKeyword]} {
	    set type "Add Macros preference"
	} elseif {!$noPrefs && [lcontains LispmodeVars(addArguments) $newKeyword]} {
	    set type "Add Arguments preference"
	}
	if {$quietly} {
	    # When this is called from other code, it should only contain
	    # one keyword to be checked, and we'll return it's type.
	    return "$type"
	} elseif {!$quietly && ($type eq 0)} {
	    alertnote "'$newKeyword' is not currently defined\
	      as a Lisp mode keyword"
	} elseif {($type ne 0)} {
	    # This will work for any other value for "quietly", such as "2"
	    alertnote "'$newKeyword' is currently defined as a keyword\
	      in the '$type' list."
	}
	set type 0
    }
    return
}

# ===========================================================================
# 
# ×××× Processing ×××× #
# 

# ===========================================================================
# 
# Process File
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Lisp::processFile" --
 # 
 # Send entire file to Lisp for processing, adding carriage return at end of
 # file if necessary.
 # 
 # Optional "f" argument allows this to be called by other code, or to be
 # sent via a Tcl shell window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Lisp::processFile {{f ""} {app "Lisp"}} {
    
    # Need to work on this.
    Lisp::betaMessage
    
    if {($f ne "")} {
	file::openAny $f
    }
    getWinInfo myArray
    set theLastChar [getText [pos::math [maxPos] -1] [maxPos]]
    if {($theLastChar ne "\r")} {
	set myPos [getPos]
	goto [maxPos]
	insertText "\r"
	goto $myPos
	# If window not originally dirty, remind user why s/he is being
	# asked to save file.
	if {!$myArray(dirty)} {
	    alertnote "Carriage return added to end of file."
	}
    }
    openAndSendFile [Lisp::sig]
    return
}

proc Lisp::processSelection {{selection ""} {app "Lisp"}} {
    
    # Need to work on this.
    Lisp::betaMessage
    
    global LispmodeVars
    
    if {($selection eq "")} {
	if {![isSelection]} {
	    status::msg "No selection -- cancelled."
	    return
	} else {
	    set selection [getSelect]
	}
    }
    set tempDir [temp::directory Lisp]
    set newFile [file join $tempDir temp-Lisp.lisp]
    file::writeAll $newFile $selection 1
    
    app::launchBack '$LispmodeVars(lispSig)'
    sendOpenEvent noReply '$LispmodeVars(LispSig)' $newFile
    switchTo '$LispmodeVars(LispSig)'
    return
}

proc Lisp::quitHook {} {
    temp::cleanup Lisp
    return
}

# ===========================================================================
# 
# ×××× -------------------- ×××× #
# 
# ×××× version history ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 01/28/00 cbu 1.0.1  First created Lisp mode, based upon other modes found 
#                       in Alpha's distribution, by looking at the syntax of 
#                       Emacs Speaks Statistics (ESS) suite.
# 04/01/00 cbu 1.0.2  Fixed a little bug with "comment box".
#                     Added new preferences to allow the user to optionally 
#                       use $ as a Magic Character, and to enter additional 
#                       commands and arguments.
#                     Renamed mode Lisp, from lisp  
#                     Reduced the number of different user-specified colors.
# 04/08/00 cbu 1.0.3  Added "Update Colors" proc to avoid need for a restart
# 04/16/00 cbu 1.0.4  Unset obsolete preferences from earlier versions.
#                     Added "Continue Comment" and "Electric Return Over-ride".
#                     Renamed "Update Colors" to "Update Preferences".
# 04/16/00 cbu 1.1    Renamed to lispMode.tcl
#                     Added "Mark File" and "Parse Functions" procs.
# 06/22/00 cbu 1.2    "Mark File" now recognizes headings as well as commands.
#                     Completions, Completions Tutorial added.
#                     "Reload Completions", referenced by "Update Preferences".
#                     Better support for user defined keywords.
#                     Removed "Continue Comment", now global in Alpha 7.4.
#                     Added command double-click for on-line help.
#                     <shift, control>-<command> double-click syntax info.
#                       (Foundations, at least.  Ongoing project.)
#                     Lisp-Mode split off from Statistical Modes.
# 08/08/00 cbu 1.2.1  Added message if no matching ")".
#                     DblClick now looks for function, variable (etc) 
#                       definitions in current file.
# 11/05/00 cbu 1.3    Added Lisp menu.
#                     Lisp menu is fully functional for Scheme mode, too.
#                     Added "next/prevCommand", "selectCommand", and
#                       "copyCommand" procs.
#                     Added "Lisp::indentLine".
#                     Added "Lisp::reformatCommand" to menu.
#                     Added "Lisp::continueCommand" to over-ride indents. 
#                     "Lisp::reloadCompletions" is now obsolete.
#                     "Lisp::updatePreferences" is now obsolete.
#                     "Lisp::colorizeLisp" now takes care of setting all 
#                       keyword lists, including Lispcmds.
#                     Cleaned up completion procs.  This file never has to be
#                       reloaded.  (Similar cleaning up for "Lisp::DblClick").
# 11/30/00 cbu 1.4    Fix to Lisp menu, suggested by Tom Fetherston, to make
#                       sure that the menu builds even if prefs don't exist.
# 12/01/00 cbu 2.0    New url prefs handling requires 7.4b21
#                     Added "Home Page" pref, menu item.
#                     Removed  hook::register requireOpenWindowsHook from
#                       mode declaration, put it after menu build.
# 09/26/01 cbu 2.1    Big cleanup, enabled by new 'functions.tcl' procs.
# 10/31/01 cbu 2.1.1  Minor bug fixes.
# 01/06/03 cbu 2.2    Minor bug fixes.
#                     Removed use of [status::errorMsg] from package.
#                     Updated url help routine, preference.
# 02/24/06 cbu 2.3    Keywords lists are defined in S namespace variables.
#                     Canonical Tcl formatting changes.
#                     Using [prefs::dialogs::setPaneLists] for preferences.
#                     New "markHeadingsOnly" preference.
#                     Disabled unimplemented features (finally).
#   

# ===========================================================================
# 
# .