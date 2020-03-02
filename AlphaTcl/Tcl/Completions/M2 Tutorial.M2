        M2 Mode Completions                V 4.x.y
________________________________________________________________________
Completions do basically two things: i) trigger templates and ii) complete 
a word (reserved word or identifier) you started to type.

See also "M2 Modula-2 Help", topic "Typing and Templates".

¥ Triggering Templates
======================
Mode M2 offers two basic methods to trigger templates. They are triggered by 
typing a reserved word (in capitals) plus the space bar (first method) or by 
typing a particular abbreviation (in lowercase) plus Ctrl^Tab (second method).  
For example typing

    FOR<space bar>

(first method) results in

    FOR  :=  TO  DO
    END;(*FOR*)
    
or typing

    for<Ctrl^Tab>
    
(second method) results in

    FOR  := ¥ TO ¥ DO
      ¥
    END(*FOR*);
    ¥


Move the cursor forward by using Tab to enter the missing parts 
of the FOR statement.  In above example typing (first method)

    FOR<space bar>i<Tab>0<Tab>9<Tab>
    
results in

    FOR i := 0 TO 9 DO
      |<- cursor will be placed here
    END;(*FOR*)

or alternatively (second method)

    for<Ctrl^Tab>i<Tab>0<Tab>9<Tab>
    
results in

    FOR i := 0 TO 9 DO
      |<- cursor will be placed here
    END(*FOR*);
    ¥

    
After you typed your statement(s) you can "jump" out of the entire 
FOR-statement by typing Tab or Shift^Return.  This will place the 
cursor after the FOR-statement ready to accept the next statement in a 
new line.

Note, the first method can be entirely disabled by unchecking the flag 
"Space Bar Expansion" in the mode's preferences dialog (menu command 
"Config > M2 Mode Prefs > Preferences..." (or F12), while you are in 
mode M2).

Note also, some of the templates generated, especially with first method, 
may contain so-called M2 place holders; they are comments of the type 
"(*.  .*)" (such comments can also be generated or removed with bindings 
Ctrl^k or Ctrl^Opt^k (or Ctrl^Shift^k), respectively.  Note, in 
contrast to the bullet '¥' (second method), a source code containing 
Modula-2 place holders is normally fully compilable.  However, it can't be 
jumped at with Tab.  Instead M2 mode offers the bindings Ctrl^g 
(forward jump to next M2 placeholder) or Ctrl^Shift^g (backward jump 
to previous M2 placeholder). 

SUMMARY
-------
The first method "listens" to following keywords (space triggers template):

CASE WHILE FOR IF if ELSIF REPEAT FROM PROCEDURE proce IMPLEMENTATION DEFINITION 
LOOP MODULE WITH


The second method "listens" to following abbreviations (Ctrl^Tab triggers 
template):

from      FROM clause
const     CONST
type      TYPE
var       VAR

bool      BOOLEAN
tr or 1   TRUE
fa or 0   FALSE
ch        CHAR
int       INTEGER
lint      LONGINT
real      REAL
lreal     LONGREAL
card      CARDINAL
lcard     LONGCARD
arr       ARRAY clause
darr      dynamic ARRAY (open array clause by value)
vdarr     VAR dynamic ARRAY (open array clause by name)
str       ARRAY OF CHAR (string clause)
dstr      dynamic ARRAY OF CHAR (open array string clause)
vdstr     VAR dynamic ARRAY OF CHAR (open array string clause by name)
rec       RECORD

for       FOR statement
forby     FOR statement (using BY)
while     WHILE statement
repeat    REPEAT statement
if        IF THEN statement
ife       IF THEN ELSE statement
ifelse    IF THEN ELSE statement (same as ife)
case      CASE statement (case constant and statement on same line)
cases     CASE statement (case constant not on same line as statement(s))
with      WITH statement

elsif     ELSIF THEN clause
else      ELSE clause
acase     CASE clause (same format as case)
acases    CASE clause (same format as cases)
end       END;
endif     END(*IF*); (plus goto next line)
eif       END(*IF*)  (changes currently selected END; into template) 
endwhile  END(*WHILE*);
endfor    END(*FOR*);
erec      END(*RECORD*);

bc        (* (begin comment)
ec        *) (end comment)
cc        (**) (short comment)
vsp       VAR(*speed-up only*) 
vio       VAR(*In/Out*) 
ret       RETURN

pro       PROCEDURE declaration in a DEFINITION MODULE without formal parameters    
proa      PROCEDURE declaration in a DEFINITION MODULE with formal parameters
proac     PROCEDURE declaration in a DEFINITION MODULE with formal parameters and comments

proc      PROCEDURE declaration without formal parameters
procc     PROCEDURE declaration like proc, but with commented name after BEGIN
proca     PROCEDURE declaration with formal parameters (arguments)
procv     PROCEDURE declaration without formal parameters (arguments) but with local variables
procav    PROCEDURE declaration with formal parameters (arguments) and local variables

To customize the behavior of the templates or to add new ones 
see file m2Completions.tcl in folder Completions within the folder Tcl. 

Exception first method:  if<space bar> is designed to trigger a one line 
IF-statement. This is in contrast to the ordinary IF<space bar> template.
The latter offers a multi line IF THEN ELSE statement.

The one line IF THEN ELSE END; statement is best filled up by using Tab to jump 
from one insertion place to the next (invisible bullet). It can later be broken 
up into pieces only if you place the cursor exactly before the reserved words 
ELSE and END. As an alternative of Tab you may also use Return.

To break a line without indentation at a reseved word, place the cursor right
before the reserved word and hit Return. 

Note M2 mode offers several alternatives to the standard <Ctrl^Tab> 
keyboard shortcut. First note that Alpha itself has introduced as standard 
alternative F1 (function key). M2 mode offers also: 
- ESC                    cconvenient single key alternative (also handy on PowerBooks)
- Numeric keypad-1       convenient on PowerBooks, since it is fn^'J' (fn = function key)
                         BTW, the numeric 1 is still available if you press fn^Option^1
                         or turn off the preference electricNumKeypad1
- Cmd^TAB                the old behavior; it switches applications under OS X,
                         but might be still usable under OS <= 9.x




¥ Completions of Reserved Words and Identifiers
===============================================
Expansion is not only available for reserved words, such as typing

    PRO<Ctrl^Tab>
  
resulting in 

    PROCEDURE

ready to trigger the entire template as soon as you press <space bar> (see 
above), but also for your own identifiers present in your code.  For 
example if your module contains a declaration like

  VAR
    myVariableWithLongIdent: INTEGER;

typing anywhere

       myV<Ctrl^Tab>
       
will result in

       myVariableWithLongIdent
       
If your typing provides not a unique match with any of your variables, the 
completion provides all alternatives by any subsequent Ctrl^Tab till they 
are all exhausted.  If you reject all of them the last word provided will 
be selected, ready for overwriting.

