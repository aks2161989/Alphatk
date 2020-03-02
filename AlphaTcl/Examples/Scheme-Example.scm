;; Scheme-Example.scm
;; 
;; Included in the Alpha distribution as an example of the Scm mode
;; 
;; original document can be found at
;; 
;; <http://www.cs.rice.edu/~dorai/>
;; 
;; reproduced with permission of the author.
;; 
;; (c) Dorai Sitaram, 1998-2000  All Rights Reserved


;; A clock for infinity
;; 
;; The Guile [FSF] procedure alarm provides an interruptable timer mechanism. 
;; The user can set or reset the alarm for some time units, or stop it.  When
;; the alarm's timer runs out of this time, it will set off an alarm, whose
;; consequences are user-settable.  Guile's alarm is not quite the clock of
;; sec 15.1, but we can modify it easily enough.
;; 
;; The alarm's timer is initially stopped or quiescent, ie, it will not set
;; off an alarm even as time goes by.  To set the alarm's time-to-alarm to be
;; n seconds, where n is not 0, run (alarm n).  If the timer was already set
;; (but has not yet set off an alarm), the (alarm n) procedure call will
;; return the number of seconds remaining from the previous alarm setting.  If
;; there is no previous alarm setting, (alarm n) returns 0.
;; 
;; The procedure call (alarm 0) stops the alarm's timer, ie, the countdown of
;; time is stopped, the timer becomes quiescent and no alarm will go off. 
;; (alarm 0) also returns the seconds remaining from a previous alarm setting,
;; if any.
;; 
;; By default, when the alarm's countdown reaches 0, Guile will display a
;; message on the console and exit.  More useful behavior can be obtained by
;; using the procedure sigaction, as follows:

(sigaction SIGALRM
  (lambda (sig)
    (display "Signal ")
    (display sig)
    (display " raised.  Continuing...")
    (newline)))

;; The first argument SIGALRM (which happens to be 14) identifies to sigaction
;; that it is the alarm handler that needs setting.9 The second argument is a
;; unary alarm-handling procedure of the user's choice.  In this example, when
;; the alarm goes off, the handler displays "Signal 14 raised.  Continuing..." 
;; on the console without exiting Scheme.  (The 14 is the SIGALRM value that
;; the alarm will pass to its handler.  Don't worry about it now.)
;; 
;; From our point of view, this simple timer mechanism poses one problem.  A
;; return value of 0 from a call to the procedure alarm is ambiguous: It could
;; either mean that the alarm was quiescent, or that it was just about to run
;; out of time.  We could resolve this ambiguity if we could include
;; ``*infinity*'' in the alarm arithmetic.  In other words, we would like a
;; clock that works almost like alarm, except that a quiescent clock is one
;; with *infinity* seconds.  This will make many things natural, viz,
;; 
;; (1) (clock n) on a quiescent clock returns *infinity*, not 0.
;; 
;; (2) To stop the clock, call (clock *infinity*), not (clock 0).
;; 
;; (3) (clock 0) is equivalent to setting the clock to an infinitesimally
;; small amount of time, viz, to cause it to raise an alarm instantaneously.
;; 
;; In Guile, we can define *infinity* as the following ``number'':

(define *infinity* (/ 1 0))

;; We can define clock in terms of alarm.

(define clock
  (let ((stopped? #t)
        (clock-interrupt-handler
         (lambda () (error "Clock interrupt!"))))
    (let ((generate-clock-interrupt
           (lambda ()
             (set! stopped? #t)
             (clock-interrupt-handler))))
      (sigaction SIGALRM
                 (lambda (sig) (generate-clock-interrupt)))
      (lambda (msg val)
        (case msg
          ((set-handler)
           (set! clock-interrupt-handler val))
          ((set)
           (cond ((= val *infinity*)
                  ;This is equivalent to stopping the clock.
                  ;This is almost equivalent to (alarm 0), except
                  ;that if the clock is already stopped,
                  ;return *infinity*.

                  (let ((time-remaining (alarm 0)))
                    (if stopped? *infinity*
                        (begin (set! stopped? #t) time-remaining))))

                 ((= val 0)
                  ;This is equivalent to setting the alarm to
                  ;go off immediately.  This is almost equivalent
                  ;to (alarm 0), except you force the alarm
                  ;handler to run.

                  (let ((time-remaining (alarm 0)))
                    (if stopped?
                        (begin (generate-clock-interrupt) *infinity*)
                        (begin (generate-clock-interrupt) time-remaining))))

                 (else
                  ;This is equivalent to (alarm n) for n != 0.
                  ;Just remember to return *infinity* if the
                  ;clock was previously quiescent.

                  (let ((time-remaining (alarm val)))
                    (if stopped?
                        (begin (set! stopped? #f) *infinity*)
                        time-remaining))))))))))

;; The clock procedure uses three internal state variables:
;; 
;; (1) stopped?, to describe if the clock is stopped;
;; 
;; (2) clock-interrupt-handler, which is a thunk describing the user-specified
;; part of the alarm-handling action; and
;; 
;; (3) generate-clock-interrupt, another thunk which will set stopped?  to
;; false before running the user-specified alarm handler.
;; 
;; The clock procedure takes two arguments.  If the first argument is
;; set-handler, it uses the second argument as the alarm handler.
;; 
;; If the first argument is set, it sets the time-to-alarm to the second
;; argument, returning the time remaining from a previous setting.  The code
;; treats 0, *infinity* and other values for time differently so that the user
;; gets a mathematically transparent interface to alarm.
