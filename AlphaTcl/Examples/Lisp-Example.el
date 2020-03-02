;; 
 ; ==========================================================================
 ; Lisp-Example.el
 ; 
 ; Distributed as an example of Alpha's Lisp mode.
 ;  
 ; Lisp mode is available at
 ; 
 ; <http://www.princeton.edu/~cupright/computing/alpha/>
 ; ==========================================================================
 ;;

;;; S-mode.el --- Support for editing S source code
;; Copyright (C) 1989-2000 Bates, Kademan, Ritter and Smith

;; Author: David Smith <dsmith@stats.adelaide.edu.au>
;; Maintainer: David Smith <dsmith@stats.adelaide.edu.au>
;; Created: 7 Jan 1994
;; Modified: $Date: 1997/03/10 16:16:21 $
;; Version: $Revision: 1.21 $
;; RCS: $Id: S-mode.el,v 1.21 1997/03/10 16:16:21 rossini Exp $

;;
;; $Log: S-mode.el,v $
;; Revision 1.21  1997/03/10 16:16:21  rossini
;; added hooks for XEmacs menu
;;
;; Revision 1.20  1997/03/07 23:34:51  rossini
;; moved relevant S-menu stuff into S-mode.
;;
;; Revision 1.19  1997/03/07 20:59:25  rossini
;; added Kurt H.'s version of S-mark-function.
;; changed settings for R-mode (ala Kurt H.)
;;
;; Revision 1.18  1997/02/10 17:36:14  rossini
;; removed the additional work, again.
;; It's not happening, this time.
;;
;; Revision 1.17  1997/02/10 16:55:52  rossini
;; fixed my stupid patching, I hope!
;;
;; Revision 1.16  1997/02/09 21:34:05  rossini
;; menus correct for S-mode (keymaps not inherited from comint, but
;; rather from text-mode!  Whoops!)
;;
;;

;; This file is part of S-mode

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; Code for editing S source code. See S.el for more details.

;;; Code:

;;; Requires and autoloads

(require 'S)

(autoload 'S-mode-minibuffer-map "S-inf" "" nil 'keymap)
(autoload 'S-read-object-name "S-inf" "" nil)
(autoload 'S-list-object-completions "S-inf" "" nil)

;;; User changeable variables
;;;=====================================================
;;; Users note: Variables with document strings starting
;;; with a * are the ones you can generally change safely, and
;;; may have to upon occasion.

(defvar S-mode-silently-save t
  "*If non-nil, automatically save S source buffers before loading")

;;*;; Variables controlling editing

;;;*;;; Edit buffer processing
(defvar S-function-template " <- function( )\n{\n\n}\n"
  "If non-nil, function template used when editing nonexistent objects.
The edit buffer will contain the object name in quotes, followed by
this string. Point will be placed after the first parenthesis or
bracket.")

;;; By K.Shibayama 5.14.1992
;;; Setting any of the following variables in your .emacs is equivalent
;;; to modifying the DEFAULT style.

;;;*;;; Indentation parameters

(defvar S-auto-newline nil
  "*Non-nil means automatically newline before and after braces
inserted in S code.")

(defvar S-tab-always-indent t
  "*Non-nil means TAB in S mode should always reindent the current line,
regardless of where in the line point is when the TAB command is used.")

(defvar S-indent-level 2
  "*Indentation of S statements with respect to containing block.")

(defvar S-brace-imaginary-offset 0
  "*Imagined indentation of a S open brace that actually follows a statement.")

(defvar S-brace-offset 0
  "*Extra indentation for braces, compared with other text in same context.")

(defvar S-continued-statement-offset 2
  "*Extra indent for lines not starting new statements.")

(defvar S-continued-brace-offset 0
  "*Extra indent for substatements that start with open-braces.
This is in addition to S-continued-statement-offset.")

(defvar S-arg-function-offset 2
  "*Extra indent for internal substatements of function `foo' that called
in `arg=foo(...)' form.
If not number, the statements are indented at open-parenthesis following foo.")

(defvar S-else-offset 2
  "*Extra indent for `else' lines.")

(defvar S-expression-offset 4
  "*Extra indent for internal substatements of `expression' that specified
in `obj <- expression(...)' form.
If not number, the statements are indented at open-parenthesis following
`expression'.")

;;;*;;; Editing styles

(defvar S-default-style-list
  (list 'DEFAULT
        (cons 'S-indent-level S-indent-level)
        (cons 'S-continued-statement-offset S-continued-statement-offset)
        (cons 'S-brace-offset S-brace-offset)
        (cons 'S-expression-offset S-expression-offset)
        (cons 'S-else-offset S-else-offset)
        (cons 'S-brace-imaginary-offset S-brace-imaginary-offset)
        (cons 'S-continued-brace-offset S-continued-brace-offset)
        (cons 'S-arg-function-offset S-arg-function-offset))
  "Default style constructed from initial values of indentation variables.")

(defvar S-style-alist
  (cons S-default-style-list
        '((GNU (S-indent-level . 2)
               (S-continued-statement-offset . 2)
               (S-brace-offset . 0)
               (S-arg-function-offset . 4)
               (S-expression-offset . 2)
               (S-else-offset . 0))
          (BSD (S-indent-level . 8)
               (S-continued-statement-offset . 8)
               (S-brace-offset . -8)
               (S-arg-function-offset . 0)
               (S-expression-offset . 8)
               (S-else-offset . 0))
          (K&R (S-indent-level . 5)
               (S-continued-statement-offset . 5)
               (S-brace-offset . -5)
               (S-arg-function-offset . 0)
               (S-expression-offset . 5)
               (S-else-offset . 0))
          (C++ (S-indent-level . 4)
               (S-continued-statement-offset . 4)
               (S-brace-offset . -4)
               (S-arg-function-offset . 0)
               (S-expression-offset . 4)
               (S-else-offset . 0))))
  "Predefined formatting styles for S code")

(defvar S-default-style 'DEFAULT
  "*The default value of S-style")

(defvar S-style S-default-style
  "*The buffer specific S indentation style.")

;;*;; Variables controlling behaviour of dump files

(defvar S-source-directory "/tmp/"
  "*Directory in which to place dump files.
This can be a string (an absolute directory name ending in a slash) or
a lambda expression of no arguments which will return a suitable string
value.  The lambda expression is evaluated with the process buffer as the
current buffer.")
;;; Possible value:
;;; '(lambda () (file-name-as-directory
;;;           (expand-file-name (concat (car S-search-list) "/.Src"))))
;;; This always dumps to a sub-directory (".Src") of the current S
;;; working directory (i.e. first elt of search list)

(defvar S-dump-filename-template (concat (user-login-name) ".%s.S")
  "*Template for filenames of dumped objects.
%s is replaced by the object name.")
;;; This gives filenames like `user.foofun.S', so as not to clash with
;;; other users if you are using a shared directory. Other alternatives:
;;; "%s.S" ; Don't bother uniquifying if using your own directory(ies)
;;; "dump" ; Always dump to a specific filename. This makes it impossible
;;;          to edit more than one object at a time, though.
;;; (make-temp-name "scr.") ; Another way to uniquify

;;; System variables
;;;=====================================================
;;; Users note: You will rarely have to change these
;;; variables.

;;*;; Regular expressions

(defvar S-function-pattern
  (concat
   "\\(" ; EITHER
   "\\s\"" ; quote
   "\\(\\sw\\|\\s_\\)+" ; symbol
   "\\s\"" ; quote
   "\\s-*\\(<-\\|_\\)\\(\\s-\\|\n\\)*" ; whitespace, assign, whitespace/nl
   "function\\s-*(" ; function keyword, parenthesis
   "\\)\\|\\(" ; OR
   "\\<\\(\\sw\\|\\s_\\)+" ; symbol
   "\\s-*\\(<-\\|_\\)\\(\\s-\\|\n\\)*" ; whitespace, assign, whitespace/nl
   "function\\s-*(" ; function keyword, parenthesis
   "\\)")
  "The regular expression for matching the beginning of an S function.")

(defvar S-dumped-missing-re
  "\\(<-\nDumped\n\\'\\)\\|\\(<-\\(\\s \\|\n\\)*\\'\\)"
  "If a dumped object's buffer matches this re, then it is replaced
by S-function-template.")

(defvar S-dump-error-re
  (if (string= S-version-running "3.0") "\nDumped\n\\'" "[Ee]rror")
  "Regexp used to detect an error when loading a file.")

;;*;; Miscellaneous system variables

(defvar S-source-modes '(S-mode)
  "A list of modes used to determine if a buffer contains S source code.")
;;; If a file is loaded into a buffer that is in one of these major modes, it
;;; is considered an S source file.  The function S-load-file uses this to
;;; determine defaults.

(defvar S-error-buffer-name "*S-errors*"
  "Name of buffer to keep error messages in.")

;;*;; Font-lock support
(defvar S-mode-font-lock-keywords
 '(("\\s\"?\\(\\(\\sw\\|\\s_\\)+\\)\\s\"?\\s-*\\(<-\\|_\\)\\(\\s-\\|\n\\)*function" 1 font-lock-function-name-face t)
   ("<-" . font-lock-reference-face)
   ("\\<\\(TRUE\\|FALSE\\|T\\|F\\|NA\\|NULL\\|Inf\\|NaN\\)\\>" . font-lock-type-face)
   ("\\<\\(library\\|attach\\|detach\\|source\\)\\>" . font-lock-reference-face)
   "\\<\\(while\\|for\\|in\\|repeat\\|if\\|else\\|switch\\|break\\|next\\|return\\|stop\\|warning\\|function\\)\\>")
 "Font-lock patterns used in S-mode bufffers.")


;;; S mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; In this section:
;;;;
;;;; * The major mode S-mode
;;;; * Commands for S-mode
;;;; * Code evaluation commands
;;;; * Indenting code and commands
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;*;; Major mode definition
(defvar S-mode-map nil)
(if S-mode-map
    nil
 
  (cond ((string-match "XEmacs\\|Lucid" emacs-version)
         ;; Code for XEmacs
         (setq S-mode-map (make-keymap))
         (set-keymap-parent S-mode-map text-mode-map) ;; was comint?!?
         ))

  (cond ((not (string-match "XEmacs\\|Lucid" emacs-version))
         ;; Code specific to FSF GNU Emacs
         (setq S-mode-map (make-sparse-keymap))))

  (define-key S-mode-map "\C-c\C-r"    'S-eval-region)
  (define-key S-mode-map "\C-c\M-r"    'S-eval-region-and-go)
  (define-key S-mode-map "\C-c\C-b"    'S-eval-buffer)
  (define-key S-mode-map "\C-c\M-b"    'S-eval-buffer-and-go)
  (define-key S-mode-map "\C-c\C-f"    'S-eval-function)
  (define-key S-mode-map "\C-c\M-f"    'S-eval-function-and-go)
  (define-key S-mode-map "\M-\C-x"     'S-eval-function)
  (define-key S-mode-map "\C-c\C-n"    'S-eval-line-and-next-line)
  (define-key S-mode-map "\C-c\C-j"    'S-eval-line)
  (define-key S-mode-map "\C-c\M-j"    'S-eval-line-and-go)
  (define-key S-mode-map "\M-\C-a"     'S-beginning-of-function)
  (define-key S-mode-map "\M-\C-e"     'S-end-of-function)
  (define-key S-mode-map "\C-c\C-y"    'S-switch-to-S)
  (define-key S-mode-map "\C-c\C-z"    'S-switch-to-end-of-S)
  (define-key S-mode-map "\C-c\C-l"    'S-load-file)
  (define-key S-mode-map "\C-c\C-v"    'S-display-help-on-object)
  (define-key S-mode-map "\C-c\C-d"    'S-dump-object-into-edit-buffer)
;(define-key S-mode-map "\C-c5\C-d"'S-dump-object-into-edit-buffer-other-frame)
  (define-key S-mode-map "\C-c\C-t"    'S-execute-in-tb)
  (define-key S-mode-map "\C-c\t"      'S-complete-object-name)
  (define-key S-mode-map "\M-\t"       'comint-replace-by-expanded-filename)
  (define-key S-mode-map "\M-?"        'S-list-object-completions)
  ;; wrong here (define-key S-mode-map "\C-c\C-k" 'S-request-a-process)
  (define-key S-mode-map "\C-c\C-k"    'S-force-buffer-current)
  (define-key S-mode-map "\C-x`"       'S-parse-errors)
  (define-key S-mode-map "{"           'S-electric-brace)
  (define-key S-mode-map "}"           'S-electric-brace)
  (define-key S-mode-map "\e\C-h"      'S-mark-function)
  (define-key S-mode-map "\e\C-q"      'S-indent-exp)
  (define-key S-mode-map "\177"        'backward-delete-char-untabify)
  (define-key S-mode-map "\t"          'S-indent-command)
)







(easy-menu-define
 S-mode-menu S-mode-map
 "Menu for use in S-mode"
 '("S-mode"
   ["Describe"  describe-mode t]
   ;;["About"  (lambda nil (interactive) (S-goto-info "Editing")) t]
   ["Send bug report"  S-submit-bug-report t]    
   "------"
   ["Load file"  S-load-file t]
   ("Eval and Go"
    ["Eval buffer"   S-eval-buffer-and-go   t]
    ["Eval region"   S-eval-region-and-go   t]
    ["Eval function" S-eval-function-and-go t]
    ["Eval line"     S-eval-line-and-go     t]
    ;;["About" (lambda nil (interactive) (S-goto-info "Evaluating code")) t]
    )
   ("S Eval"
    ["Eval buffer"       S-eval-buffer             t]
    ["Eval region"       S-eval-region             t]
    ["Eval function"     S-eval-function           t]
    ["Step through line" S-eval-line-and-next-line t]
    ["Enter expression"  S-execute-in-tb           t]
    ["Eval line"         S-eval-line               t]
    ;;["About" (lambda nil (interactive) (S-goto-info "Evaluating code"))]
    )
   ("Motion..." 
    ["Edit new object"       S-dump-object-into-edit-buffer t]
    ["Goto end of S buffer"  S-switch-to-end-of-S           t]
    ["Switch to S buffer"    S-switch-to-S                  t]
    ["End of function"      S-end-of-function              t]
    ["Beginning of function" S-beginning-of-function        t])
   ("S list..."
    ["Backward list"         backward-list                   t]
    ["Forward list"          forward-list                    t]
    ["Next parenthesis"      down-list                       t]
    ["Enclosing parenthesis" backward-up-list                t]
    ["Backward sexp"         backward-sexp                   t]
    ["Forward sexp"          forward-sexp                    t]
    ;;["About"                 (Info-goto-node "(Emacs)Lists") t]
    )
   ("S Edit"
    ["Complete Filename" comint-replace-by-expanded-filename t]
    ["Complete Object"   S-complete-object-name              t]
    ["Kill sexp"         kill-sexp                           t]
    ["Mark function"     S-mark-function                     t]
    ["Indent expression" S-indent-exp                        t]
    ["Indent line"       S-indent-command                    t]
    ["Undo"              undo                                t]
    ;;["About"   (lambda nil (interactive) (S-goto-info "Edit buffer")) t]
    )
   ))

(if (not (string-match "XEmacs" emacs-version))
    (progn
      (if (featurep 'S-mode)
           (define-key S-mode-map
             [menu-bar S-mode]
             (cons "S-mode" S-mode-menu))
         (eval-after-load "S-mode"
                          '(define-key S-mode-map
                             [menu-bar S-mode]
                             (cons "S-mode"
                                   S-mode-menu))))))

(defun S-mode-xemacs-menu ()
  "Hook to install S-mode menu for XEmacs (w/ easymenu)"
  (if 'S-mode
        (easy-menu-add S-mode-menu)
    (easy-menu-remove S-mode-menu)))

(if (string-match "XEmacs" emacs-version)
    (add-hook 'S-mode-hook 'S-mode-xemacs-menu))


(defun R-mode  (&optional proc-name) 
  "Major mode for editing R source.  See S-mode for more help."
  (interactive)
  (setq S-proc-prefix "R"
        ;; S-set-style "GNU"
        S-default-style 'GNU
        )
  (S-mode proc-name))

(defun S-mode (&optional proc-name)
  "Major mode for editing S source.
Optional arg PROC-NAME is name of associated inferior process.

\\{S-mode-map}

Customization: Entry to this mode runs the hooks in S-mode-hook.

You can send text to the inferior S process from other buffers containing
S source.
    S-eval-region sends the current region to the S process.
    S-eval-buffer sends the current buffer to the S process.
    S-eval-function sends the current function to the S process.
    S-eval-line sends the current line to the S process.
    S-beginning-of-function and S-end-of-function move the point to
        the beginning and end of the current S function.
    S-switch-to-S switches the current buffer to the S process buffer.
    S-switch-to-end-of-S switches the current buffer to the S process
        buffer and puts point at the end of it.

    S-eval-region-and-go, S-eval-buffer-and-go,
        S-eval-function-and-go, and S-eval-line-and-go switch to the S
        process buffer after sending their text.

    S-load-file sources a file of commands to the S process.

\\[S-indent-command] indents for S code.
\\[backward-delete-char-untabify] converts tabs to spaces as it moves back.
Comments are indented in a similar way to Emacs-lisp mode:
       `###'     beginning of line
       `##'      the same level of indentation as the code
       `#'       the same column on the right, or to the right of such a
                 column if that is not possible.(default value 40).
                 \\[indent-for-comment] command automatically inserts such a
                 `#' in the right place, or aligns such a comment if it is
                 already inserted.
\\[S-indent-exp] command indents each line of the S grouping following point.

Variables controlling indentation style:
 S-tab-always-indent
    Non-nil means TAB in S mode should always reindent the current line,
    regardless of where in the line point is when the TAB command is used.
 S-auto-newline
    Non-nil means automatically newline before and after braces inserted in S
    code.
 S-indent-level
    Indentation of S statements within surrounding block.
    The surrounding block's indentation is the indentation of the line on
    which the open-brace appears.
 S-continued-statement-offset
    Extra indentation given to a substatement, such as the then-clause of an
    if or body of a while.
 S-continued-brace-offset
    Extra indentation given to a brace that starts a substatement.
    This is in addition to S-continued-statement-offset.
 S-brace-offset
    Extra indentation for line if it starts with an open brace.
 S-arg-function-offset
    Extra indent for internal substatements of function `foo' that called
    in `arg=foo(...)' form.
   If not number, the statements are indented at open-parenthesis following
   `foo'.
 S-expression-offset
    Extra indent for internal substatements of `expression' that specified
    in `obj <- expression(...)' form.
    If not number, the statements are indented at open-parenthesis following
    `expression'.
 S-brace-imaginary-offset
    An open brace following other text is treated as if it were
    this far to the right of the start of its line.
 S-else-offset
    Extra indentation for line if it starts with `else'.

Furthermore, \\[S-set-style] command enables you to set up predefined S-mode
indentation style. At present, predefined style are `BSD', `GNU', `K&R' `C++'
 (quoted from C language style)."
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'S-mode)
  (setq mode-name "S")
  (use-local-map S-mode-map)
  (set-syntax-table S-mode-syntax-table)
  (make-local-variable 'paragraph-start)
  (setq paragraph-start (concat "^$\\|" page-delimiter))
  (make-local-variable 'paragraph-separate)
  (setq paragraph-separate paragraph-start)
  (make-local-variable 'paragraph-ignore-fill-prefix)
  (setq paragraph-ignore-fill-prefix t)
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'S-indent-line)
  (make-local-variable 'require-final-newline)
  (setq require-final-newline t)
  (make-local-variable 'comment-start)
  (setq comment-start "#")
  (make-local-variable 'comment-start-skip)
  (setq comment-start-skip "#+ *")
  (make-local-variable 'comment-column)
  (setq comment-column 40)
  (make-local-variable 'comment-indent-function)
  (setq comment-indent-function 'S-comment-indent)
  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments t)
  (S-set-style S-default-style)
  (make-local-variable 'S-local-process-name)
  (make-local-variable 'S-keep-dump-files)
  (put 'S-local-process-name 'permanent-local t) ; protect from RCS
  (setq mode-line-process ;; AJR: in future, XEmacs will use modeline-process.
        '(" [" (S-local-process-name S-local-process-name "none") "]"))
  ;; font-lock support
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(S-mode-font-lock-keywords))
  (run-hooks 'S-mode-hook))

;;*;; User commands in S-mode

;;;*;;; Handy commands

(defun S-execute-in-tb nil
  "Like S-execute, but always evaluates in temp buffer."
  (interactive)
  (let ((S-execute-in-process-buffer nil))
    (call-interactively 'S-execute)))

;;;*;;; Buffer motion/manipulation commands

(defun S-beginning-of-function nil
  "Leave the point at the beginning of the current S function."
  (interactive)
  (let ((init-point (point))
        beg end done)
    (if (search-forward "(" nil t) (forward-char 1))
    ;; in case we're sitting in a function header
    (while (not done)
      (if
          (re-search-backward S-function-pattern (point-min) t)
          nil
        (goto-char init-point)
        (error "Point is not in a function."))
      (setq beg (point))
      (forward-list 1)                  ; get over arguments
      (forward-sexp 1)                  ; move over braces
      (setq end (point))
      (goto-char beg)
      ;; current function must begin and end around point
      (setq done (and (>= end init-point) (<= beg init-point))))))


(defun S-end-of-function nil
  "Leave the point at the end of the current S function."
  (interactive)
  (S-beginning-of-function)
  (forward-list 1)                      ; get over arguments
  (forward-sexp 1)                      ; move over braces
  )

(defun S-extract-word-name ()
  "Get the word you're on."
  (save-excursion
    (re-search-forward "\\<\\w+\\>" nil t)
    (buffer-substring (match-beginning 0) (match-end 0))))

;;; Original S-mode 4.8.6 version
;;(defun S-mark-function ()
;;  "Put mark at end of S function, point at beginning."
;;  (interactive)
;;  (push-mark (point))
;;  (S-end-of-function)
;;  (push-mark (point))
;;  (S-beginning-of-function))

;;; Kurt's version, suggested 970306.
(defun S-mark-function ()
  "Put mark at end of S function, point at beginning."
  (interactive)
  (S-beginning-of-function)
  (push-mark (point))
  (S-end-of-function)
  (exchange-point-and-mark))

;;*;; Code evaluation commands

;;;*;;; Evaluate only

(defun S-eval-region (start end toggle &optional message)
  "Send the current region to the inferior S process.
With prefix argument, toggle meaning of S-eval-visibly-p."
  (interactive "r\nP")
  (require 'S-inf)                      ; for S-eval-visibly-p
  (S-force-buffer-current "Process to load into: ")
  (let ((visibly (if toggle (not S-eval-visibly-p) S-eval-visibly-p)))
    (if visibly
        (S-eval-visibly (buffer-substring start end))
      (if S-synchronize-evals
          (S-eval-visibly (buffer-substring start end)
                          (or message "Eval region"))
        (process-send-region (get-S-process S-current-process-name)
                             start end)
        (process-send-string (get-S-process S-current-process-name)
                             "\n")))))

(defun S-eval-buffer (vis)
  "Send the current buffer to the inferior S process.
Arg has same meaning as for S-eval-region."
  (interactive "P")
  (S-eval-region (point-min) (point-max) vis "Eval buffer"))

(defun S-eval-function (vis)
  "Send the current function to the inferior S process.
Arg has same meaning as for S-eval-region."
  (interactive "P")
  (save-excursion
    (S-end-of-function)
    (let ((end (point)))
      (S-beginning-of-function)
      (princ (concat "Loading: " (S-extract-word-name)) t)
      (S-eval-region (point) end vis
                     (concat "Eval function " (S-extract-word-name))))))

(defun S-eval-line (vis)
  "Send the current line to the inferior S process.
Arg has same meaning as for S-eval-region."
  (interactive "P")
  (save-excursion
    (end-of-line)
    (let ((end (point)))
      (beginning-of-line)
      (princ (concat "Loading line: " (S-extract-word-name) " ...") t)
      (S-eval-region (point) end vis "Eval line"))))
(defun S-eval-line-and-next-line ()
  "Evaluate the current line visibly and move to the next line."
  ;; From an idea by Rod Ball (rod@marcam.dsir.govt.nz)
  (interactive)
  (save-excursion
    (end-of-line)
    (let ((end (point)))
      (beginning-of-line)
      ;; RDB modified to go to end of S buffer so user can see result
      (S-eval-visibly (buffer-substring (point) end) nil t)))
  (next-line 1))

;; goes to the real front, in case you do double function definition
;; 29-Jul-92 -FER
;; don't know why David changed it.

;; FER's versions don't work properly with nested functions. Replaced
;; mine. DMS 16 Nov 92

;;;*;;; Evaluate and switch to S

(defun S-eval-region-and-go (start end vis)
  "Send the current region to the inferior S and switch to the process buffer.
Arg has same meaning as for S-eval-region."
  (interactive "r\nP")
  (S-eval-region start end vis)
  (S-switch-to-S t))

(defun S-eval-buffer-and-go (vis)
  "Send the current buffer to the inferior S and switch to the process buffer.
Arg has same meaning as for S-eval-region."
  (interactive "P")
  (S-eval-buffer vis)
  (S-switch-to-S t))

(defun S-eval-function-and-go (vis)
  "Send the current function to the inferior S process and switch to
the process buffer. Arg has same meaning as for S-eval-region."
  (interactive "P")
  (S-eval-function vis)
  (S-switch-to-S t))

(defun S-eval-line-and-go (vis)
  "Send the current line to the inferior S process and switch to the
process buffer. Arg has same meaning as for S-eval-region."
  (interactive "P")
  (S-eval-line vis)
  (S-switch-to-S t))

;;*;; Loading files

(defun S-force-buffer-current (prompt &optional force)
  "Make sure the current buffer is attached to an S process. If not,
prompt for a process name with PROMPT. S-local-process-name is set to
the name of the process selected."
  (interactive 
   (list (concat S-proc-prefix " process to use: ") prefix-arg))
  (if (S-make-buffer-current) nil
    ;; Make sure the source buffer is attached to a process
    (if S-local-process-name
        (error "Process %s has died." S-local-process-name)
      ;; S-local-process-name is nil -- which process to attach to
      (save-excursion
        (let ((proc (S-request-a-process prompt 'no-switch)))
          (make-local-variable 'S-local-process-name)
          (setq S-local-process-name proc)
          ;; why is the mode line not updated ??
          )))))

(defun S-check-modifications nil
  "Check whether loading this file would overwrite some S objects
which have been modified more recently than this file, and confirm
if this is the case."
  ;; FIXME: this should really cycle through all top-level assignments in
  ;; the buffer
  (and (buffer-file-name) S-inf-filenames-map
       (let ((sourcemod (nth 5 (file-attributes (buffer-file-name))))
             (objname))
         (save-excursion
           (goto-char (point-min))
           ;; Get name of assigned object, if we can find it
           (setq objname
                 (and
                  (re-search-forward "^\\s *\"?\\(\\(\\sw\\|\\s_\\)+\\)\"?\\s *[<_]" nil t)
                  (buffer-substring (match-beginning 1) (match-end 1)))))
         (and
          sourcemod                     ; the file may have been deleted
          objname                       ; may not have been able to find name
          (S-modtime-gt (S-object-modtime objname) sourcemod)
          (not (y-or-n-p (format "The S object %s is newer than this file. Continue? " objname)))
          (error "Aborted")))))

(defun S-check-source (fname)
  "If file FNAME has an unsaved buffer, offer to save it.
Returns t if the buffer existed and was modified, but was not saved"
  (let ((buff (get-file-buffer fname)))
    (if buff
        (let ((deleted (not (file-exists-p (buffer-file-name)))))
          (if (and deleted (not (buffer-modified-p buff)))
              ;; Buffer has been silently deleted, so silently save
              (save-excursion
                (set-buffer buff)
                (set-buffer-modified-p t)
                (save-buffer))
            (if (and (buffer-modified-p buff)
                     (or S-mode-silently-save
                         (y-or-n-p
                          (format "Save buffer %s first? "
                                  (buffer-name buff)))))
                (save-excursion
                  (set-buffer buff)
                  (save-buffer))))
          (buffer-modified-p buff)))))

(defun S-load-file (filename)
  "Load an S source file into an inferior S process."
  (interactive (list
                (or
                 (and (eq major-mode 'S-mode) (buffer-file-name))
                 (expand-file-name
                  (read-file-name "Load S file: " nil nil t)))))
  (require 'S-inf)
  (S-make-buffer-current)
  (let ((source-buffer (get-file-buffer filename)))
    (if (S-check-source filename)
        (error "Buffer %s has not been saved" (buffer-name source-buffer))
      ;; Find the process to load into
      (if source-buffer
          (save-excursion
            (set-buffer source-buffer)
    (S-force-buffer-current "Process to load into: ")
            (S-check-modifications))))
    (let ((errbuffer (S-create-temp-buffer S-error-buffer-name))
          error-occurred nomessage)
      (S-command (format inferior-S-load-command filename) errbuffer)
      (save-excursion
        (set-buffer errbuffer)
        (goto-char (point-max))
        (setq error-occurred (re-search-backward S-dump-error-re nil t))
        (setq nomessage (= (buffer-size) 0)))
      (if error-occurred
          (message "Errors: Use %s to find error."
                   (substitute-command-keys
                    "\\<inferior-S-mode-map>\\[S-parse-errors]"))
        ;; Load did not cause an error
        (if nomessage (message "Load successful.")
          ;; There was a warning message from S
          (S-display-temp-buffer errbuffer))
        ;; Consider deleting the file
        (let ((skdf (if source-buffer
                        (save-excursion
                          (set-buffer source-buffer)
                          S-keep-dump-files)
                      S-keep-dump-files))) ;; global value
          (cond
           ((null skdf)
            (delete-file filename))
           ((memq skdf '(check ask))
            (let ((doit (y-or-n-p (format "Delete %s " filename))))
              (if doit (delete-file filename))
              (and source-buffer
                   (local-variable-p 'S-keep-dump-files source-buffer)
                   (save-excursion
                     (set-buffer source-buffer)
                     (setq S-keep-dump-files doit)))))))
        (S-switch-to-S t)))))

(defun S-parse-errors (showerr)
  "Jump to error in last loaded S source file.
With prefix argument, only shows the errors S reported."
  (interactive "P")
  (S-make-buffer-current)
  (let ((errbuff (get-buffer S-error-buffer-name)))
    (if (not errbuff)
        (error "You need to do a load first!")
      (set-buffer errbuff)
      (goto-char (point-max))
      (if
          (re-search-backward
           "^\\(Syntax error: .*\\) at line \\([0-9]*\\), file \\(.*\\)$"
           nil
           t)
          (let* ((filename (buffer-substring (match-beginning 3) (match-end 3)))
                 (fbuffer (get-file-buffer filename))
                 (linenum (string-to-int (buffer-substring (match-beginning 2) (match-end 2))))
                 (errmess (buffer-substring (match-beginning 1) (match-end 1))))
            (if showerr
                  (S-display-temp-buffer errbuff)
              (if fbuffer nil
                (setq fbuffer (find-file-noselect filename))
                (save-excursion
                  (set-buffer fbuffer)
                  (S-mode)))
              (pop-to-buffer fbuffer)
              (goto-line linenum))
            (princ errmess t))
        (message "Not a syntax error.")
        (S-display-temp-buffer errbuff)))))

;;*;; S code formatting/indentation

;;;*;;; User commands

(defun S-electric-brace (arg)
  "Insert character and correct line's indentation."
  (interactive "P")
  (let (insertpos)
    (if (and (not arg)
             (eolp)
             (or (save-excursion
                   (skip-chars-backward " \t")
                   (bolp))
                 (if S-auto-newline (progn (S-indent-line) (newline) t) nil)))
        (progn
          (insert last-command-char)
          (S-indent-line)
          (if S-auto-newline
              (progn
                (newline)
                ;; (newline) may have done auto-fill
                (setq insertpos (- (point) 2))
                (S-indent-line)))
          (save-excursion
            (if insertpos (goto-char (1+ insertpos)))
            (delete-char -1))))
    (if insertpos
        (save-excursion
          (goto-char insertpos)
          (self-insert-command (prefix-numeric-value arg)))
      (self-insert-command (prefix-numeric-value arg)))))

(defun S-indent-command (&optional whole-exp)
  "Indent current line as S code, or in some cases insert a tab character.
If S-tab-always-indent is non-nil (the default), always indent current line.
Otherwise, indent the current line only if point is at the left margin
or in the line's indentation; otherwise insert a tab.

A numeric argument, regardless of its value,
means indent rigidly all the lines of the expression starting after point
so that this line becomes properly indented.
The relative indentation among the lines of the expression are preserved."
  (interactive "P")
  (if whole-exp
      ;; If arg, always indent this line as S
      ;; and shift remaining lines of expression the same amount.
      (let ((shift-amt (S-indent-line))
            beg end)
        (save-excursion
          (if S-tab-always-indent
              (beginning-of-line))
          (setq beg (point))
          (backward-up-list 1)
          (forward-list 1)
          (setq end (point))
          (goto-char beg)
          (forward-line 1)
          (setq beg (point)))
        (if (> end beg)
            (indent-code-rigidly beg end shift-amt)))
    (if (and (not S-tab-always-indent)
             (save-excursion
               (skip-chars-backward " \t")
               (not (bolp))))
        (insert-tab)
      (S-indent-line))))

(defun S-indent-exp ()
  "Indent each line of the S grouping following point."
  (interactive)
  (let ((indent-stack (list nil))
        (contain-stack (list (point)))
        (case-fold-search nil)
        restart outer-loop-done innerloop-done state ostate
        this-indent last-sexp last-depth
        at-else at-brace
        (opoint (point))
        (next-depth 0))
    (save-excursion
      (forward-sexp 1))
    (save-excursion
      (setq outer-loop-done nil)
      (while (and (not (eobp)) (not outer-loop-done))
        (setq last-depth next-depth)
        ;; Compute how depth changes over this line
        ;; plus enough other lines to get to one that
        ;; does not end inside a comment or string.
        ;; Meanwhile, do appropriate indentation on comment lines.
        (setq innerloop-done nil)
        (while (and (not innerloop-done)
                    (not (and (eobp) (setq outer-loop-done t))))
          (setq ostate state)
          (setq state (parse-partial-sexp (point) (progn (end-of-line) (point))
                                          nil nil state))
          (setq next-depth (car state))
          (if (and (car (cdr (cdr state)))
                   (>= (car (cdr (cdr state))) 0))
              (setq last-sexp (car (cdr (cdr state)))))
          (if (or (nth 4 ostate))
              (S-indent-line))
          (if (nth 4 state)
              (and (S-indent-line)
                   (setcar (nthcdr 4 state) nil)))
          (if (or (nth 3 state))
              (forward-line 1)
            (setq innerloop-done t)))
        (if (<= next-depth 0)
            (setq outer-loop-done t))
        (if outer-loop-done
            nil
          ;; If this line had ..))) (((.. in it, pop out of the levels
          ;; that ended anywhere in this line, even if the final depth
          ;; doesn't indicate that they ended.
          (while (> last-depth (nth 6 state))
            (setq indent-stack (cdr indent-stack)
                  contain-stack (cdr contain-stack)
                  last-depth (1- last-depth)))
          (if (/= last-depth next-depth)
              (setq last-sexp nil))
          ;; Add levels for any parens that were started in this line.
          (while (< last-depth next-depth)
            (setq indent-stack (cons nil indent-stack)
                  contain-stack (cons nil contain-stack)
                  last-depth (1+ last-depth)))
          (if (null (car contain-stack))
              (setcar contain-stack (or (car (cdr state))
                                        (save-excursion (forward-sexp -1)
                                                        (point)))))
          (forward-line 1)
          (skip-chars-forward " \t")
          (if (eolp)
              nil
            (if (and (car indent-stack)
                     (>= (car indent-stack) 0))
                ;; Line is on an existing nesting level.
                ;; Lines inside parens are handled specially.
                (if (/= (char-after (car contain-stack)) ?{)
                    (setq this-indent (car indent-stack))
                  ;; Line is at statement level.
                  ;; Is it a new statement?  Is it an else?
                  ;; Find last non-comment character before this line
                  (save-excursion
                    (setq at-else (looking-at "else\\W"))
                    (setq at-brace (= (following-char) ?{))
                    (S-backward-to-noncomment opoint)
                    (if (S-continued-statement-p)
                        ;; Preceding line did not end in comma or semi;
                        ;; indent this line  S-continued-statement-offset
                        ;; more than previous.
                        (progn
                          (S-backward-to-start-of-continued-exp (car contain-stack))
                          (setq this-indent
                                (+ S-continued-statement-offset (current-column)
                                   (if at-brace S-continued-brace-offset 0))))
                      ;; Preceding line ended in comma or semi;
                      ;; use the standard indent for this level.
                      (if at-else
                          (progn (S-backward-to-start-of-if opoint)
                                 (setq this-indent (+ S-else-offset
                                                      (current-indentation))))
                        (setq this-indent (car indent-stack))))))
              ;; Just started a new nesting level.
              ;; Compute the standard indent for this level.
              (let ((val (S-calculate-indent
                           (if (car indent-stack)
                               (- (car indent-stack))))))
                (setcar indent-stack
                        (setq this-indent val))))
            ;; Adjust line indentation according to its contents
            (if (= (following-char) ?})
                (setq this-indent (- this-indent S-indent-level)))
            (if (= (following-char) ?{)
                (setq this-indent (+ this-indent S-brace-offset)))
            ;; Put chosen indentation into effect.
            (or (= (current-column) this-indent)
                (= (following-char) ?\#)
                (progn
                  (delete-region (point) (progn (beginning-of-line) (point)))
                  (indent-to this-indent)))
            ;; Indent any comment following the text.
            (or (looking-at comment-start-skip)
                (if (re-search-forward comment-start-skip (save-excursion (end-of-line) (point)) t)
                    (progn (indent-for-comment) (beginning-of-line)))))))))
                                        ; (message "Indenting S expression...done")
  )
;;;*;;; Support functions for indentation

(defun S-comment-indent ()
  (if (looking-at "###")
      (current-column)
    (if (looking-at "##")
        (let ((tem (S-calculate-indent)))
          (if (listp tem) (car tem) tem))
      (skip-chars-backward " \t")
      (max (if (bolp) 0 (1+ (current-column)))
           comment-column))))

(defun S-indent-line ()
  "Indent current line as S code.
Return the amount the indentation changed by."
  (let ((indent (S-calculate-indent nil))
        beg shift-amt
        (case-fold-search nil)
        (pos (- (point-max) (point))))
    (beginning-of-line)
    (setq beg (point))
    (cond ((eq indent nil)
           (setq indent (current-indentation)))
          (t
           (skip-chars-forward " \t")
           (if (looking-at "###")
               (setq indent 0))
           (if (and (looking-at "#") (not (looking-at "##")))
               (setq indent comment-column)
             (if (eq indent t) (setq indent 0))
             (if (listp indent) (setq indent (car indent)))
             (cond ((and (looking-at "else\\b")
                         (not (looking-at "else\\s_")))
                    (setq indent (save-excursion
                                   (S-backward-to-start-of-if)
                                   (+ S-else-offset (current-indentation)))))
                   ((= (following-char) ?})
                    (setq indent (- indent S-indent-level)))
                   ((= (following-char) ?{)
                    (setq indent (+ indent S-brace-offset)))))))
    (skip-chars-forward " \t")
    (setq shift-amt (- indent (current-column)))
    (if (zerop shift-amt)
        (if (> (- (point-max) pos) (point))
            (goto-char (- (point-max) pos)))
      (delete-region beg (point))
      (indent-to indent)
      ;; If initial point was within line's indentation,
      ;; position after the indentation.
      ;; Else stay at same point in text.
      (if (> (- (point-max) pos) (point))
          (goto-char (- (point-max) pos))))
    shift-amt))

(defun S-calculate-indent (&optional parse-start)
  "Return appropriate indentation for current line as S code.
In usual case returns an integer: the column to indent to.
Returns nil if line starts inside a string, t if in a comment."
  (save-excursion
    (beginning-of-line)
    (let ((indent-point (point))
          (case-fold-search nil)
          state
          containing-sexp)
      (if parse-start
          (goto-char parse-start)
        (beginning-of-defun))
      (while (< (point) indent-point)
        (setq parse-start (point))
        (setq state (parse-partial-sexp (point) indent-point 0))
        (setq containing-sexp (car (cdr state))))
      (cond ((or (nth 3 state) (nth 4 state))
             ;; return nil or t if should not change this line
             (nth 4 state))
            ((null containing-sexp)
             ;; Line is at top level.  May be data or function definition,
             (beginning-of-line)
             (if (and (/= (following-char) ?\{)
                      (save-excursion
                        (S-backward-to-noncomment (point-min))
                        (S-continued-statement-p)))
                 S-continued-statement-offset
               0))   ; Unless it starts a function body
            ((/= (char-after containing-sexp) ?{)
             ;; line is expression, not statement:
             ;; indent to just after the surrounding open.
             (goto-char containing-sexp)
             (let ((bol (save-excursion (beginning-of-line) (point))))

               ;; modified by shiba@isac 7.3.1992
               (cond ((and (numberp S-expression-offset)
                           (re-search-backward "[ \t]*expression[ \t]*" bol t))
                      ;; This regexp match every "expression".
                      ;; modified by shiba
                      ;;(forward-sexp -1)
                      (beginning-of-line)
                      (skip-chars-forward " \t")
                      ;; End
                      (+ (current-column) S-expression-offset))
                     ((and (numberp S-arg-function-offset)
                           (re-search-backward "=[ \t]*\\s\"*\\(\\w\\|\\s_\\)+\\s\"*[ \t]*" bol t))
                      (forward-sexp -1)
                      (+ (current-column) S-arg-function-offset))
                     ;; "expression" is searched before "=".
                     ;; End

                     (t
                      (progn (goto-char (1+ containing-sexp))
                             (current-column))))))
            (t
             ;; Statement level.  Is it a continuation or a new statement?
             ;; Find previous non-comment character.
             (goto-char indent-point)
             (S-backward-to-noncomment containing-sexp)
             ;; Back up over label lines, since they don't
             ;; affect whether our line is a continuation.
             (while (eq (preceding-char) ?\,)
               (S-backward-to-start-of-continued-exp containing-sexp)
               (beginning-of-line)
               (S-backward-to-noncomment containing-sexp))
             ;; Now we get the answer.
             (if (S-continued-statement-p)
                 ;; This line is continuation of preceding line's statement;
                 ;; indent  S-continued-statement-offset  more than the
                 ;; previous line of the statement.
                 (progn
                   (S-backward-to-start-of-continued-exp containing-sexp)
                   (+ S-continued-statement-offset (current-column)
                      (if (save-excursion (goto-char indent-point)
                                          (skip-chars-forward " \t")
                                          (eq (following-char) ?{))
                          S-continued-brace-offset 0)))
               ;; This line starts a new statement.
               ;; Position following last unclosed open.
               (goto-char containing-sexp)
               ;; Is line first statement after an open-brace?
               (or
                 ;; If no, find that first statement and indent like it.
                 (save-excursion
                   (forward-char 1)
                   (while (progn (skip-chars-forward " \t\n")
                                 (looking-at "#"))
                     ;; Skip over comments following openbrace.
                     (forward-line 1))
                   ;; The first following code counts
                   ;; if it is before the line we want to indent.
                   (and (< (point) indent-point)
                        (current-column)))
                 ;; If no previous statement,
                 ;; indent it relative to line brace is on.
                 ;; For open brace in column zero, don't let statement
                 ;; start there too.  If S-indent-level is zero,
                 ;; use S-brace-offset + S-continued-statement-offset instead.
                 ;; For open-braces not the first thing in a line,
                 ;; add in S-brace-imaginary-offset.
                 (+ (if (and (bolp) (zerop S-indent-level))
                        (+ S-brace-offset S-continued-statement-offset)
                      S-indent-level)
                    ;; Move back over whitespace before the openbrace.
                    ;; If openbrace is not first nonwhite thing on the line,
                    ;; add the S-brace-imaginary-offset.
                    (progn (skip-chars-backward " \t")
                           (if (bolp) 0 S-brace-imaginary-offset))
                    ;; If the openbrace is preceded by a parenthesized exp,
                    ;; move to the beginning of that;
                    ;; possibly a different line
                    (progn
                      (if (eq (preceding-char) ?\))
                          (forward-sexp -1))
                      ;; Get initial indentation of the line we are on.
                      (current-indentation))))))))))

(defun S-continued-statement-p ()
  (let ((eol (point)))
    (save-excursion
      (cond ((memq (preceding-char) '(nil ?\, ?\; ?\} ?\{ ?\]))
             nil)
            ;; ((bolp))
            ((= (preceding-char) ?\))
             (forward-sexp -2)
             (looking-at "if\\b[ \t]*(\\|function\\b[ \t]*(\\|for\\b[ \t]*(\\|while\\b[ \t]*("))
            ((progn (forward-sexp -1)
                    (and (looking-at "else\\b\\|repeat\\b")
                         (not (looking-at "else\\s_\\|repeat\\s_"))))
             (skip-chars-backward " \t")
             (or (bolp)
                 (= (preceding-char) ?\;)))
            (t
             (progn (goto-char eol)
                    (skip-chars-backward " \t")
                    (or (and (> (current-column) 1)
                             (save-excursion (backward-char 1)
                                             (looking-at "[-:+*/_><=]")))
                        (and (> (current-column) 3)
                             (progn (backward-char 3)
                                    (looking-at "%[^ \t]%"))))))))))
(defun S-backward-to-noncomment (lim)
  (let (opoint stop)
    (while (not stop)
      (skip-chars-backward " \t\n\f" lim)
      (setq opoint (point))
      (beginning-of-line)
      (search-forward "#" opoint 'move)
      (skip-chars-backward " \t#")
      (setq stop (or (/= (preceding-char) ?\n) (<= (point) lim)))
        (if stop (point)
          (beginning-of-line)))))

(defun S-backward-to-start-of-continued-exp (lim)
  (if (= (preceding-char) ?\))
      (forward-sexp -1))
  (beginning-of-line)
  (if (<= (point) lim)
      (goto-char (1+ lim)))
  (skip-chars-forward " \t"))

(defun S-backward-to-start-of-if (&optional limit)
  "Move to the start of the last ``unbalanced'' if."
  (or limit (setq limit (save-excursion (beginning-of-defun) (point))))
  (let ((if-level 1)
        (case-fold-search nil))
    (while (not (zerop if-level))
      (backward-sexp 1)
      (cond ((looking-at "else\\b")
             (setq if-level (1+ if-level)))
            ((looking-at "if\\b")
             (setq if-level (1- if-level)))
            ((< (point) limit)
             (setq if-level 0)
             (goto-char limit))))))

;;;*;;; Predefined indentation styles

(defun S-set-style (&optional style)
  "Set up the S-mode style variables from the S-style variable or if
  STYLE argument is given, use that.  It makes the S indentation style
  variables buffer local."

  (interactive)

  (let ((S-styles (mapcar 'car S-style-alist)))

    (if (interactive-p)
        (setq style
              (let ((style-string ; get style name with completion
                     (completing-read
                      (format "Set S mode indentation style to (default %s): "
                              S-default-style)
                      (vconcat S-styles)
                      (function (lambda (arg) (memq arg S-styles)))
                      )))
                (if (string-equal "" style-string)
                    S-default-style
                  (intern style-string))
                )))

    (setq style (or style S-style)) ; use S-style if style is nil

    (make-local-variable 'S-style)
    (if (memq style S-styles)
        (setq S-style style)
      (error (concat "Bad S style: " style))
      )
    (message "S-style: %s" S-style)

    ; finally, set the indentation style variables making each one local
    (mapcar (function (lambda (S-style-pair)
                        (make-local-variable (car S-style-pair))
                        (set (car S-style-pair)
                             (cdr S-style-pair))))
            (cdr (assq S-style S-style-alist)))
    S-style))

;;*;; Creating and manipulating dump buffers

;;;*;;; The user command

(defun S-dump-object-into-edit-buffer (object)
  "Edit an S object in its own buffer.

Without a prefix argument, this simply finds the file pointed to by
S-source-directory. If this file does not exist, or if a
prefix argument is given, a dump() command is sent to the S process to
generate the source buffer."
  (interactive
   (progn
     (require 'S-inf)
     (S-force-buffer-current "Process to dump from: ")
     (S-read-object-name "Object to edit: ")))
  (let* ((dirname (file-name-as-directory
                   (if (stringp S-source-directory)
                       S-source-directory
                     (save-excursion
                       (set-buffer (process-buffer
                                    (get-S-process S-local-process-name)))
                       (apply S-source-directory nil)))))
         (filename (concat dirname (format S-dump-filename-template object)))
         (old-buff (get-file-buffer filename)))

    ;; If the directory doesn't exist, offer to create it
    (if (file-exists-p (directory-file-name dirname)) nil
      (if (y-or-n-p     ; Approved
           (format "Directory %s does not exist. Create it? " dirname))
          (make-directory (directory-file-name dirname))
        (error "Directory %s does not exist." dirname)))

    ;; Three options:
    ;;  (1) Pop to an existing buffer containing the file in question
    ;;  (2) Find an existing file
    ;;  (3) Create a new file by issuing a dump() command to S
    ;; Force option (3) if there is a prefix arg

    (if current-prefix-arg
        (S-dump-object object filename)
      (if old-buff
          (progn
            (pop-to-buffer old-buff)
            (message "Popped to edit buffer."))
        ;; No current buffer containing desired file
        (if (file-exists-p filename)
            (progn
              (S-find-dump-file-other-window filename)
              (message "Read %s" filename))
          ;; No buffer and no file
          (S-dump-object object filename))))))

(defun S-dump-object (object filename)
  "Dump the S object OBJECT into file FILENAME."
  (let ((complete-dump-command (format inferior-S-dump-command
                                       object filename)))
    (if (file-writable-p filename) nil
      (error "Can't dump %s as %f is not writeable." object filename))

    ;; Make sure we start fresh
    (if (get-file-buffer filename)
        (or (kill-buffer (get-file-buffer filename))
            (error "Aborted.")))

    (S-command complete-dump-command)
    (message "Dumped in %s" filename)

    (S-find-dump-file-other-window filename)

    ;; Don't make backups for temporary files; it only causes clutter.
    ;; The S object itself is a kind of backup, anyway.
    (if S-keep-dump-files nil
      (make-local-variable 'make-backup-files)
      (setq make-backup-files nil))

    ;; Don't get confirmation to delete dumped files when loading
    (if (eq S-keep-dump-files 'check)
        (setq S-keep-dump-files nil))

    ;; Delete the file if necessary
    (if S-delete-dump-files
        (delete-file (buffer-file-name)))))

(defun S-find-dump-file-other-window (filename)
  "Find S source file FILENAME in another window."
  (if (file-exists-p filename) nil
    (error "%s does not exist." filename))

  ;; Generate a buffer with the dumped data
  (find-file-other-window filename)
  (S-mode)

  (auto-save-mode 1)            ; Auto save in this buffer
  (setq S-local-process-name S-current-process-name)

  (if S-function-template
      (progn
        (goto-char (point-max))
        (if (re-search-backward S-dumped-missing-re nil t)
            (progn
              (replace-match S-function-template t t)
              (set-buffer-modified-p nil) ; Don't offer to save if killed now
              (goto-char (point-min))
              (condition-case nil
                  ;; This may fail if there are no opens
                  (down-list 1)
                (error nil)))))))


;; AJR: XEmacs, makes sense to dump into "other frame".

(defun S-dump-object-into-edit-buffer-other-frame (object)
  "Edit an S object in its own frame."
  (switch-to-buffer-other-frame (S-dump-object-into-edit-buffer object)))



(provide 'S-mode)

;;; Local variables section

;;; This file is automatically placed in Outline minor mode.
;;; The file is structured as follows:
;;; Chapters:     ^L ;
;;; Sections:    ;;*;;
;;; Subsections: ;;;*;;;
;;; Components:  defuns, defvars, defconsts
;;;              Random code beginning with a ;;;;* comment

;;; Local variables:
;;; mode: emacs-lisp
;;; mode: outline-minor
;;; outline-regexp: "\^L\\|\\`;\\|;;\\*\\|;;;\\*\\|(def[cvu]\\|(setq\\|;;;;\\*"
;;; End:

;;; S-mode.el ends here

