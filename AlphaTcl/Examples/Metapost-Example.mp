% Metapost-Example.mp
% 
% This is a sample file for the Metapost mode with Alpha. 
% 
% The features which are herein described will work only if Metapost Mode
% has been properly installed.
% 
% - syntax coloring : the Metapost and Metafont primitives are colored in
% magenta.  The plain macros are in blue.
% 
% - the 'M' pop-up menu contains a list of the various definitions (def,
% primarydef etc.  and vardef) and a list of all the beginfig commands. 
% Each of them is marked so you can navigate easily among them.
% 
% - the '{}' pop-up menu shows a list of the included files and of the
% defined macros.
% 
% - if you option-click on the title bar, a list of all the .mpx, .mpx and
% .log files in the current directory (if any) will show up.
% 
% - command-double-clicking on a word leads to its definition provided the
% paths to the macro files have been set correctly in the mode prefs.  The
% procedure looks first for a definition in the current file itself, then
% in the list of primitives, then in all the Metapost macros files
% (boxes.mp, mfplain.mp, plain.mp etc.  Note that plain.mp is scanned
% first) and finally in the other ".mp" text files called in the current
% file by an 'input' command and located at the same level (typically they
% are user defined macros files).
% 
% - If the 'elecCompletion' package is activated, you have a system of
% keywords completions and abbreviations.  For instance, typing "bt"
% (without the quotes) immediatly followed by the F1 key will result in
% "btex etex•" (you move to the next bullet with the tab key).  If you type
% "proo" and hit the F1 key, the word is completed to "proof" ; if you hit
% the F1 key again, then a window shows up proposing several completions :
% proofing proofrule proofrulethickness.  Type the word "input" and the
% first letter of the input file : it will be completed too.  For instance
% "input r" + F1 key, will result in "input rboxes".  See the doc for more.
% 
% 
% Please see the Metapost Help file for more information.  
% Please check for the latest version of Metapost Mode on :
% <http://webperso.easyconnect.fr/bdesgraupes/alpha.tcl>
% 
% The examples below are borrowed, with his kind permission, from Laurent
% Chéno's Metapost Web Page :
% 
% <http://altern.org/zuben/mp/cheno/exemples/>
% 

input boxes 
% input mfplain

prologues := 2 ;


vardef miArete(suffix a,b) expr p =
        drawarrow p cutbefore bpath.a cutafter bpath.b ;
        point .5*length p of p
enddef ;

vardef miBoucle@# expr p = miArete(@#,@#) @#.c{curl0}..@#.c+p..{curl0}@#.c enddef ;

def cercle(suffix a,b) = circleit.a() ; a.c = z.b ; enddef ;
        
% An automaton
beginfig(1)
interim circmargin := 6bp ;
z0 = (0,0) ;
z1 - z0 = z7 - z6 = z8 - z7 = z9 - z8
	     = z10 - z9 = z11 - z10 = z3 - z2 = z5 - z4
	     = (z2 - z1) rotated -60 = (z4 - z1) rotated 60 = (z6 - z3) rotated 60
	     = (14mm,0) ;

cercle(a)(0) ; cercle(b)(1) ; cercle(c)(2) ; cercle(d)(3) ; cercle(e)(4) ; cercle(f)(5) ; 
cercle(g)(6) ; cercle(h)(7) ; cercle(i)(8) ; cercle(j)(9) ; cercle(k)(10) ; cercle(l)(11) ; 

drawboxed(a,b,c,d,e,f,g,h,i,j,k,l) ;
interim circmargin := 8bp ;
circleit.ll(pic l) ; ll.c = z11 ;
drawboxed(ll) ;
drawarrow (-1cm,0)--z0 cutafter bpath.a ;

label.top(btex $\varepsilon$ etex,miArete(a,b) a.c--b.c) ;
label.ulft(btex $\varepsilon$ etex,miArete(b,c) b.c--c.c) ;
label.top(btex $a$ etex,miArete(c,d) c.c--d.c) ;
label.urt(btex $\varepsilon$ etex,miArete(d,g) d.c--g.c) ;
label.urt(btex $\varepsilon$ etex,miArete(b,e) b.c--e.c) ;
label.top(btex $b$ etex,miArete(e,f) e.c--f.c) ;
label.ulft(btex $\varepsilon$ etex,miArete(f,g) f.c--g.c) ;
label.top(btex $\varepsilon$ etex,miArete(g,h) g.c--h.c) ;
label.top(btex $\varepsilon$ etex,miArete(h,i) h.c--i.c) ;
label.top(btex $b$ etex,miArete(i,j) i.c--j.c) ;
label.top(btex $\varepsilon$ etex,miArete(j,k) j.c--k.c) ;
label.top(btex $a$ etex,miArete(k,ll) k.c--l.c) ;
label.top(btex $\varepsilon$ etex,miArete(g,b) g.c{dir72}..b.c) ;
label.bot(btex $\varepsilon$ etex,miArete(a,h) a.c{down}..h.c) ;

endfig ;


% A tree
beginfig(2)
diameter = 20 pt ; h = 50 pt ; v = 60 pt ;
path halfleft,halfright ; 
halfright = halfcircle scaled diameter rotated -90 -- cycle ; 
halfleft = halfright xscaled -1 ;

picture bb,bn,nb ;
fill fullcircle scaled diameter withcolor white ; 
draw fullcircle scaled diameter ; bb := currentpicture ;

currentpicture := nullpicture ;
fill halfright withcolor black ;
fill halfleft withcolor white ; 
draw fullcircle scaled diameter ; 
bn := currentpicture ;

currentpicture := nullpicture ;
fill halfleft withcolor black ; 
fill halfright withcolor white ; draw
fullcircle scaled diameter ; nb := currentpicture ; 
currentpicture := nullpicture ;

% Coords of the nodes
z0 = (0,0) ;
y0 - y1 = y1 - y3 = y3 - y6 = y9 - y11 = v ; y1 = y2 ; y3 = y4 = y5 ; y6 = y7 = y8 = y9 = y10 ;
x10 - x9 = x9 - x8 = x8 - x7 = x7 - x6 = x4 - x3 = h ;
x4 = 1/2[x7,x8] ; x5 = 1/2[x9,x10] ; x1 = 1/2[x3,x4] ; x0 = 1/2[x1,x2] ;
x5 - x2 = x9 - x11 = h/2 ;
% Drawing the edges
draw z0 -- z1 -- z3 -- z6 ;
draw z1 -- z4 -- z8 ;
draw z4 -- z7 ;
draw z0 -- z2 -- z5 -- z10 ;
draw z5 -- z9 -- z11 ;
% Drawing the vertices
def sbb(text g)(expr a)(text d) =
draw bb shifted a ;
label(g,a - (14pt,0)) ; label(d,a + (14pt,0)) ;
enddef ;

def sbn(text g)(expr a)(text d) =
draw bn shifted a ;
label(g,a - (14pt,0)) ; label(d,a + (14pt,0)) ;
enddef ;

def snb(text g)(expr a)(text d) =
draw nb shifted a ;
label(g,a - (14pt,0)) ; label(d,a + (14pt,0)) ;
enddef ;

snb("6")(z0)("5") ; sbn("2")(z1)("3") ; sbn("0")(z2)("4") ; snb("1")(z3)("0") ;
sbb("1")(z4)("1") ; snb("2")(z5)("1") ; sbb("0")(z6)("0") ; sbb("0")(z7)("0") ;
sbb("0")(z8)("0") ; snb("1")(z9)("0") ; sbb("0")(z10)("0") ; sbb("0")(z11)("0") ;
endfig ;

% Ford's circles
beginfig(3)
def iteration(expr a,b,ra,rb,n) =
    if n = 0 :
    else :
	begingroup
	    save t,m,r ;
	    numeric t,r ;
	    pair m ;
	    t := sqrt(ra) + sqrt(rb) ;
	    r := ra * rb / (t * t) ;
	    m := (sqrt(ra)/t)[a,b] ;
	    draw fullcircle scaled (r * 2u) shifted (m + (0,r*u)) ;
	    iteration(a,m,ra,r,n-1) ;
	    iteration(m,b,r,rb,n-1) ;
	endgroup
    fi
enddef ;

u = 10cm ;
z0 = (0,0) ; z1 = (u,0) ;

drawarrow (0,0)--(0,6cm) ; label.rt("y",(0,6cm)) ;
drawarrow (0,0)--(11cm,0) ; label.bot("x",(11cm,0)) ;
dotlabel.bot("1",z1) ; dotlabel.lrt("0",z0) ;
draw fullcircle scaled u shifted (0,u/2) ;
draw fullcircle scaled u shifted (u,u/2) ;
pickup pencircle scaled 0.1bp ;
iteration(z0,z1,1/2,1/2,6) ;
clip currentpicture to (-1cm,-1cm)--(12cm,-1cm)--(12cm,7cm)--(-1cm,7cm)--cycle ;
endfig ;

end
