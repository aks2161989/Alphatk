## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "TeXcmds.tcl"
 #                                   created: 02/26/1996 {02:27:17 pm}
 #                               last update: 08/23/2002 {03:24:32 PM}
 # Description:
 #
 # Support for electric completion/expansion.
 #
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

proc TeXcmds.tcl {} {}

namespace eval TeX {}

# ×××× environment keywords ×××× #

# This is a reasonably exhaustive list of commands and environments
# Short commands (1-2 chars) have been removed since they don't need
# completions.

set TeXenvironments { 
CD
Sb
Sp
Vmatrix
abstract
affil
align
aligned
appendix
array
author
bmatrix
cases
center
cfrac
csname
demo
description
displaymath
document
enumerate
eqnarray
eqnarray*
equation
exambox
example
figure
figure*
filecontents
filecontents*
firsthead
flushleft
flushrignt
fussypar
gather
gathered
group
head
heading
insert
itemize
letter
list
lrbox
math
matrix
minipage
mode
multline
note
overlay
picture
pmatrix
proclaim
quotation
quote
ref
roster
samepage
slide
sloppypar
smallmatrix
split
tabbing
table
table*
tabular
tabular*
thebibliography
theindex
title
titlepage
topmatter
trivlist
tt
verbatim
verbatim*
verse
vmatrix
}

# ×××× envir acronym pairs ×××× #

set TeXenvir_acronyms { 
dm        displaymath
ea        eqnarray
ea*       eqnarray*
eb        exambox
f         figure
f*        figure*
fc        filecontents
fc*       filecontents*
fh        firsthead
fl        flushleft
fp        fussypar
fr        flushrignt
ml        multline
mp        minipage
ol        overlay
sm        smallmatrix
sp        samepage
sp        sloppypar
t         table
t*        table*
tb        thebibliography
ti        theindex
tl        trivlist
tm        topmatter
tp        titlepage
tr        tabular
tr*       tabular*
v         verbatim
v*        verbatim*
}


# ×××× command keywords ×××× #

set TeXcmds {
Alph
AltMacroFont
AmSTeX
Arrowvert
BIBTEX
BIG
Bar
Bbb
Bbbk
BibTeX
Big
Bigg
Biggl
Biggm
Biggr
Bigl
Bigm
Bigr
BlackBoxes
Box
Breve
Bumpeq
CMDA
CMDB
Cal
Cap
CenteredTagsOnSplits
ChangeBuffer
CharacterTable
Check
CheckModules
CheckSum
CodelineIndex
CodelineNumbered
Cup
Ddot
DeclareMathOperator
DeclareTextAccent
DeclareTextAccentDefault
DeclareTextCommand
DeclareTextCommandDefault
DeclareTextComposite
DeclareTextCompositeCommand
DeclareTextSymbol
DeclareTextSymbolDefault
DeleteShortVerb
DescribeEnv
DescribeMacro
Diamond
DisableCrossrefs
DisableTabs
DoNotIndex
DocInput
DocstyleParms
DontCheckModules
Dostar
Dot
Downarrow
ERROR
EnableCrossrefs
EnableTabs
Finale
Finv
Fmtname
Fmtversion
Game
GlossaryMin
GlossaryParms
GlossaryPrologue
Grave
Hat
Huge
IWA
IndexInput
IndexMin
IndexParms
IndexPrologue
Join
LARGE
LATEX
LaTeX
LaTeXe
Large
LimitsOnInts
LimitsOnNames
LimitsOnSums
Lleftarrow
Longleftarrow
Longleftrightarrow
Longrightarrow
Look
Lsh
MacroFont
MacroIndent
MacroTopsep
MacrocodeTopsep
MakePrivateLetters
MakeShortVerb
Module
MultlineGap
NAME
NoBlackBoxes
NoLimitsOnInts
NoLimitsOnNames
NoLimitsOnSums
normalfont
OldMakeindex
OnlyDescription
PCTeX
PageIndex
PaperHeight
PaperWidth
PlainTeX
PrintChanges
PrintDescribeEnv
PrintDescribeMacro
PrintEnvName
PrintIndex
PrintMacroName
ProvideTextCommand
RecordChanges
Refs
Relbar
ResetBuffer
Roman
Rsh
Runinitem
SLITEX
SLiTeX
STYLE
Setbox
SortIndex
SpecialEnvIndex
SpecialEscapechar
SpecialIndex
SpecialMainEnvIndex
SpecialMainIndex
SpecialUsageIndex
StopEventually
Subset
Supset
TagsAsMath
TagsAsText
TagsOnLeft
TagsOnRight
TeX
Tilde
TopOrBottomTagsOnSplits
Uparrow
Updownarrow
UseTextAccent
UseTextSymbol
Vdash
Vec
Vert
Vmatrix
Vvdash
Web
abcfalse
abctrue
above
abovedisplayshortskip
abovedisplayskip
abstractname
accent
accentedsymbol
active
actualchar
acute
add
addcontentsline
addpenalty
address
addtocontents
addtocounter
addtolength
addtoversion
addvspace
adjdemerits
adjustfootnotemark
advance
advancepageno
affil
afterassignment
aleph
alignat
alignedat
allchapters
allocationnumber
allowbreak
allowdisplaybreak
allowdisplaybreaks
allowlinebreak
allowmathbreak
alph
alpha
alsoname
amalg
and
angle
annotations
answer
appendix
appendixname
approx
approxeq
arabic
arccos
arcsin
arctan
arg
arraycolsep
arrayrulewidth
arraystretch
arrowvert
ast
asymp
atop
backepsilon
backmatter
backprime
backsim
backsimeq
backslash
badness
bar
barwedge
baselineskip
baselinestretch
batchmode
because
begin
begingroup
beginitemize
beginlinemode
beginparmode
beginsection
belowdisplayshortskip
belowdisplayskip
beta
beth
between
bezier
bfdefault
bfseries
bgroup
bibcite
bibdata
bibitem
bibliography
bibliographystyle
bibname
bibstyle
bibtex
big
bigbreak
bigcap
bigcirc
bigcup
bigg
biggl
biggm
biggr
bigl
bigm
bigodot
bigoplus
bigotimes
bigpagebreak
bigr
bigskip
bigskipamount
bigsqcup
bigstar
bigtriangledown
bigtriangleup
biguplus
bigvee
bigwedge
binom
blackandwhite
blacklozenge
blacksquare
blacktriangle
blacktriangledown
blacktriangleleft
blacktriangleright
bmod
body
bold
boldmath
boldsymbol
bordermatrix
bot
botaligned
botfigrule
botfoldedtext
botmark
botnum
botshave
botsmash
bottomfraction
bowtie
box
boxdot
boxed
boxmaxdepth
boxminus
boxplus
boxtimes
brace
bracevert
brack
break
breve
brokenpenalty
brokenv
bslash
buildrel
bullet
bumpeq
bye
bysame
cal
cap
caption
captions
casefrac
catcode
catcoded
ccname
cdot
cdots
cell
cellrow
center
centerdot
centering
centerline
changes
chapno
chapter
chaptermark
chaptername
char
chardef
check
checkmark
chi
choose
chw
circ
circeq
circle
circlearrowleft
circlearrowright
circledR
circledS
circledast
circledcirc
circleddash
cite
cleaders
cleardoublepage
clearpage
cleartabs
cline
closein
closeout
closing
clubpenalty
clubsuit
colon
colors
colorslides
columnbox
columns
columnsep
columnseprule
columnwidth
colw
comment
compare
complement
comppare
cong
contentsline
contentsname
coprod
copy
copyright
copyrightspace
cos
cosh
cot
coth
count
countdef
course
crcr
csc
cup
curlyeqprec
curlyeqsucc
curlyvee
curlywedge
curraddr
currentsection
curvearrowleft
curvearrowright
dag
dagger
daleth
dashbox
dashleftarrow
dashrightarrow
dashv
date
dbinom
dblfigrule
dblfloatpagefraction
dblfloatsep
dbltexfloatsep
dbltextfloatsep
dbltopfraction
ddag
ddagger
ddddot
dddot
ddot
ddots
deadcycles
dedicatory
def
define
deg
delcode
delta
depth
descriptionlabel
det
dfrac
diagdown
diagup
diamond
diamondsuit
digamma
digitwidth
dim
dimen
discretionary
displaybreak
displaylimits
displaylines
displaylines;l5
displaystyle
displaywidowpenalty
displaywidth
div
divide
divideontimes
docdate
documentclass
documentstyle
doit
dospecials
dostar
dosupereject
dot
dotbox
doteq
doteqdot
dotfill
dotplus
dots
dotsb
dotsc
dotsi
dotsm
dotso
doublebarwedge
doubleformat
doublehyphendemerits
doublerulesep
downarrow
downbracefill
downdownarrows
downharpoonleft
downharpoonright
due
edef
egroup
eightpoint
eject
ell
else
email
emergencystretch
emph
empty
emptyset
enabletabs
encapchar
encl
enclname
end
endCD
endSb
endSp
endVmatrix
endabstract
endaffil
endaligned
endarray
endauthor
endbmatrix
endcases
endcfrac
endcsname
enddemo
enddisplaymath
enddocument
endenumerate
endeqnarray
endequation
endexambox
endexample
endfigure
endfirsthead
endgathered
endgroup
endhead
endheading
endinsert
enditemize
endletter
endlist
endmatrix
endminipage
endmode
endmultline
endnote
endoverlay
endpicture
endpmatrix
endproclaim
endref
endroster
endslide
endsloppypar
endsmallmatrix
endsplit
endtabbing
endtabular
endthebibliography
endtheindex
endtitle
endtitlepage
endtopmatter
endtrivlist
endtt
endvmatrix
enlargethispage
enskip
enspace
ensuremath
epsfbox
epsfxsize
epsfysize
epsilon
eqalign
eqalignno
eqcirc
eqnarray
eqno
eqref
eqslantgtr
eqslantless
equal
equiv
errmessage
errorstopmode
escapechar
eta
eth
eval
evensidemargin
everydisplay
everyjob
everymath
everypar
exambox
exampage
example
exhyphenpenalty
exists
exlist
exname
exp
expandafter
exrefsearch
extra
extracolsep
fallingdotseq
fam
famzero
fbox
fboxrule
fboxsep
figurename
filbreak
filedate
fileversion
fill
fin
finalhyphendemerits
first
firstmark
firstnumber
firstpart
flat
float
floatingpenalty
floatpagefraction
floatsep
flushbottom
flushleft
flushpar
flushright
fmtname
fmtversion
fnsymbol
foldedtext
folio
font
fontest
fontfamily
fontname
fontseries
fontshape
fontsize
footheight
footins
footinsertskip
footline
footnote
footnotemark
footnoterule
footnotesep
footnotesize
footnotetext
footsep
footskip
footstrut
forall
format
fortyonept
fourteenpt
frac
fracwithdelims
frame
framebox
framerule
framesep
frenchspacing
fromaddress
fromlocation
fromname
fromsig
frontmatter
frown
fullhsize
fullline
fussy
futurelet
galleys
gamma
gather
gathered
gcd
gdef
genfrac
geq
geqq
geqslant
gets
getw
ggg
gimel
global
gloop
glossary
glossaryentry
glue
gnapprox
gneq
gneqq
gnsim
goodbreak
grave
gtrapprox
gtrdot
gtreqless
gtreqqless
gtrless
gtrsim
gvertneqq
halfstep
halfwidth
halign
hang
hangafter
hangindent
hat
hbadness
hbar
hbox
hcorrection
hdots
hdotsfor
head
headheight
heading
headline
headsep
headtoname
heartsuit
height
helevetica
hfil
hfill
hfuzz
hglue
hidewidth
hline
hoffset
hom
hookleftarrow
hookrightarrow
hphantom
hrule
hrulefill
hsize
hskip
hslash
hspace
hss
huge
hvi
hwno
hyphenation
hyphenchar
hyphenpenalty
ialign
idotsint
idxentry
ifLandscape
ifabc
ifcase
ifcat
ifdim
ifeof
iff
iffalse
ifhmode
ifinner
iflanguage
ifmmode
ifnum
ifodd
ifortyonept
ifourteenpt
ifraggedbottom
ifthenelse
ifvmode
ifvoid
ifx
ignorespaces
iiiint
iiint
iint
imath
immediate
impliedby
implies
inbook
include
includeonly
indent
index
indexentry
indexname
indexspace
inf
infty
injlim
innerhdotsfor
input
insert
insertpenalties
int
intercal
interdisplaylinepenalty
interfootnotelinepenalty
interlinepenalty
intertext
intextsep
invisible
iota
isanitize
iseventeenpt
italic
itdefault
item
itemindent
itemitem
itemize
itemsep
iterate
ithirtyfourpt
itshape
itwentyfourpt
itwentyninept
itwentypt
ixpt
jmath
jobname
join
joinrel
jot
jour
kappa
ker
kern
keywords
kill
knuth
lVert
label
labelenum
labelenumi
labelenumii
labelenumiii
labelenumiv
labelitem
labelitemi
labelitemii
labelitemiii
labelitemiv
labelsep
labelwidth
lambda
langle
language
large
lastbox
lastskip
lasy
lbrace
lbrack
lccode
lceil
lcfin
lcfrac
lcol
ldotp
ldots
leaderfill
leaders
leadsto
leavevmode
left
leftappenditem
leftarrow
leftarrowfill
leftarrowtail
leftcolumn
lefteqn
leftharpoondown
leftharpoonup
leftleftarrows
leftline
leftmargin
leftmargini
leftmarginvi
leftmark
leftrightarrow
leftrightarrows
leftrightharpoons
leftrightsquigarrow
leftroot
leftskip
leftthreetimes
leq
leqalignno
leqno
leqq
leqslant
lessapprox
lessdot
lesseqgtr
lesseqqgtr
lessgtr
lesssim
let
letter
levelchar
lfloor
lgroup
lhd
lim
liminf
limits
limsup
line
linebreak
linepenalty
lineskip
lineskiplimit
linethickness
linewidth
linkeseite
list
listfigurename
listfiles
listoffigures
listoftables
listparindent
listtablename
literalcatcodes
llap
llcorner
lll
lmoustache
lnapprox
lneq
lneqq
lnsim
load
location
log
long
longleftarrow
longleftrightarrow
longmapsto
longrightarrow
loop
looparrowleft
looparrowright
looseness
lower
lowercase
lozenge
lqchar
lrcorner
ltcapwidth
ltimes
lvert
lvertneqq
mag
magnification
magnifikation
magstep
magstephalf
main
mainmatter
mainsection
makeatletter
makeatother
makebox
makedateline
makefootline
makeglossary
makeheading
makeheadline
makeindex
makelabel
makelabels
maketitle
maltese
manyby
mapsto
marginpar
marginparpush
marginparsep
marginparwidth
mark
markboth
markright
math
mathaccent
mathbf
mathbin
mathbreak
mathcal
mathchar
mathchardef
mathchoice
mathclose
mathcode
mathhexbox
mathindent
mathinner
mathit
mathnormal
mathop
mathord
mathpalette
mathrel
mathrm
mathscr
mathsf
mathstrut
mathsurround
mathtt
mathversion
matrix
max
maxdeadcycles
maxdepth
maxdimen
maxfootnotes
mbox
mdseries
meaning
measuredangle
medbreak
mediumseries
medmuskip
medpagebreak
medskip
medskipamount
medspace
message
meta
mho
mid
midbox
midinsert
midspace
min
minCDarrowwidth
minipage
mit
mkern
mlabel
mod
models
moreref
moveleft
moveright
mskip
mspace
mul
multicolumn
multimap
multiply
multiput
multispan
multline
multlinegap
muskip
muskipdef
myname
nLeftarrow
nLeftrightarrow
nRightarrow
nVDash
nabla
name
narrower
natural
ncong
nearrow
neg
negmedspace
negthickspace
negthinspace
neq
new
newblock
newbox
newcodes
newcommand
newcount
newcounter
newdimen
newenvironment
newfam
newfont
newhelp
newif
newinsert
newlabel
newlength
newline
newlinechar
newmathalphabet
newmuskip
newpage
newread
newsavebox
newskip
newswitch
newtheorem
newtheoremstyle
newtoks
newwrite
nexists
next
nextnumber
ngeq
ngeqq
ngeqslant
ngtr
nleftarrow
nleftrightarrow
nleq
nleqq
nleqslant
nless
nmid
noalign
nobreak
nobreakdash
nocite
nocorr
noexpand
nofiles
noindent
nointerlineskip
nolimits
nolinebreak
nologo
nomathbreak
nomultlinegap
nonfrenchspacing
nonscript
nonstopmode
nonumber
nopagebreak
nopagenumbers
normalbaselines
normalbaselineskip
normalbottom
normalfont
normallineskip
normalmarginpar
normalshape
normalsize
not
notag
note
notesname
notin
nparallel
nprec
npreceq
nrightarrow
nshortmid
nshortparallel
nsim
nsubseteq
nsubseteqq
nsucc
nsucceq
nsupseteq
nsupseteqq
ntriangleleft
ntrianglelefteq
ntriangleright
ntrianglerighteq
null
nulldelimiterspace
nullfont
number
numberline
numberwithin
nvDash
nvdash
nwarrow
oalign
obeycr
obeylines
obeyspaces
oddrule
oddsidemargin
odot
offinterlineskip
oint
oldcodes
oldnos
oldstyle
omega
ominus
omit
onecolumn
onlynotes
onlyslides
ooalign
openin
opening
openout
openup
operatorname
operatornamewithlimits
oplus
oslash
otimes
outer
output
outputpenalty
oval
over
overbrace
overfullrule
overlay
overleftarrow
overleftrightarrow
overline
overrightarrow
overset
oversetbrace
page
pagebody
pagebreak
pagecontents
pagedepth
pagegoal
pageheight
pageinsert
pagelayout
pagename
pageno
pagenumbering
pageref
pageshrink
pagestyle
pagewidth
paperheight
papersize
paperwidth
par
paragraph
paragraphmark
parallel
parbox
parfillskip
parindent
parsep
parshape
parskip
part
partial
partname
partopsep
partsw
patterns
pausing
pbf
pcomma
pcopyright
pdollar
pem
penalty
perp
phantom
phi
phspace
picture
pit
pitchfork
plainoutput
pldots
plot
pmatrix
pmb
pmod
pod
poptab
poptabs
postdisplaypenalty
pounds
preabstract
preaffil
preauthor
prec
precapprox
preccurlyeq
preceq
precnapprox
precnsim
precsim
predate
predefine
prefacename
prefgraf
prepaper
pretend
pretitle
pretolerance
prevdepth
prevgraf
prime
printindex
printoptions
prm
proclaim
prod
produceref
projlim
propto
protect
providecommand
ps@titlepage
psc
psf
psi
psl
ptt
pushtab
pushtabs
put
qbezier
qed
qedsymbol
qquad
quad
quotation
quote
quotechar
rVert
radical
raggedbottom
raggedleft
raggedright
raise
raisebox
raisetag
rangle
rbrace
rbrack
rceil
rcfrac
read
recurse
ref
refname
refstepcounter
rekurs
relax
relbar
removelastskip
renewcommand
renewenvironment
repeat
restorecr
return
returnaddress
reversemarginpar
rfloor
rgroup
rhd
rho
right
rightarrow
rightarrowfill
rightarrowtail
rightharpoondown
rightharpoonup
rightleftarrows
rightleftharpoons
rightline
rightmargin
rightmark
rightrightarrows
rightskip
rightsquigarrow
rightthreetimes
risingdotseq
rlap
rmdefault
rmfam
rmfamily
rmoustache
roman
romannumber
romannumeral
root
roster
rqchar
rtimes
rule
rvert
samepage
savebox
sbox
scale
scaledocument
scalefont
scalelinespacing
scaletype
scdefault
scriptfont
scriptscriptsize
scriptscriptstyle
scriptsize
scriptstyle
scrollmode
scshape
searrow
sec
secdef
second
secondpart
section
sectionbreak
sectionmark
see
seename
selectfont
selectlanguage
seprow
serialnumber
set
setbox
setcounter
setlength
setlongtables
setmarg
setmargins
setmarginsrb
setmargnohf
setmargnohfrb
setmargrb
setminus
setpapersize
settabs
settodepth
settoheight
settowidth
setw
seventeenpt
sfcode
sfdefault
sffamily
sharp
shave
shiftmargins
shipout
shortmid
shortparallel
shortstack
shoveleft
shoveright
show
showallocations
showbox
showboxbreadth
showboxdepth
showhyphens
showlists
showoutput
showoverfull
showthe
sideset
sigma
signature
sim
simeq
sin
sinh
skeuchar
skew
skip
skipdef
slanted
slash
sldefault
slide
slidepage
sloppy
sloppypar
slshape
small
smallbreak
smallfrown
smallmatrix
smallpagebreak
smallsetminus
smallskip
smallskipamount
smallsmile
smash
smc
smile
snug
space
spacefactor
spacehdots
spaceinnerhdots
spaces
spaceskip
spacute
spadesuit
span
spbar
spbreve
spcheck
spddddot
spdddot
spddot
spdot
special
specialsection
spgrave
sphat
sphericalangle
spike
split
splitbotmark
splitmaxdepth
splittopskip
spreadlines
spreadmatrixlines
sptilde
spvec
sqcap
sqcup
sqrt
sqsubset
sqsubseteq
sqsupset
sqsupseteq
square
stackrel
star
stari
starii
stariii
startbreaks
startlabels
starv
stepcounter
stop
stopbreaks
stopletter
stretch
string
strut
styname
styversion
subheading
subitem
subjclass
subject
subjectname
subparagraph
subparagraphmark
subsection
subsectionmark
subset
subseteq
subseteqq
subsetneq
subsetneqq
substack
subsubitem
subsubsection
subsubsectionmark
succ
succapprox
succcurlyeq
succeq
succnapprox
succnsim
succsim
sum
sup
supereject
suppressfloats
supset
supseteq
supseteqq
supsetneq
supsetneqq
surd
swapnumbers
swarrow
symbol
syntax
tab
tabalign
tabbing
tabbingsep
tabcolsep
table
tableentry
tablename
tableofcontents
tabskip
tabular
tabularnewline
tag
tan
tanh
tau
tbinom
tblraggedright
telephone
telephonenum
temp
tencirc
tencircw
tenln
tenlnw
tenpoint
test
tex
text
textbf
textbullet
textcircled
textcompwordmark
textemdash
textendash
textexclamdown
textfloatsep
textfont
textfonti
textfontii
textfraction
textheight
textindent
textit
textmd
textnormal
textperiodcentered
textquestiondown
textquotedblleft
textquotedblright
textquoteleft
textquoteright
textrm
textsc
textsf
textsl
textstyle
textsuperscript
texttt
textup
textvisiblespace
textwidth
tfrac
thanks
the
theCodelineNo
thebibliography
thechapter
theenumi
theenumii
theenumiii
theenumiv
theequation
thefigure
thefootnote
theindex
thempfn
thempfootnote
thenote
theoremstyle
theoverlay
thepage
theparagraph
thepart
therefore
therosteritem
thesection
theslide
thesubparagraph
thesubsection
thesubsubsection
theta
thetable
thetag
thickapprox
thickfrac
thickfracwithdelims
thicklines
thickmuskip
thicksim
thickspace
thinlines
thinmuskip
thinspace
thirtyfourpt
thispagestyle
tie
tilde
times
tiny
title
titlepage
toaddress
toappear
toc
today
toks
tolerance
toname
top
topaligned
topfigrule
topfoldedtext
topfraction
topins
topinsert
topmargin
topmark
topnewpage
topnum
topnumber
topsep
topshave
topskip
topsmash
topspace
totalheight
tracingall
tracingcommands
tracingmacros
tracingonline
tracingoutput
tracingparagraphs
tracingstats
translator
triangle
triangledown
triangleleft
trianglelefteq
triangleq
triangleright
trianglerighteq
trivlist
ttdefault
ttfamily
ttraggedright
ttspace
twelvepoint
twentyfourpt
twentyninept
twentypt
twocolumn
twoheadleftarrow
twoheadrightarrow
twosided
typein
typeout
uccode
ulcorner
unboldmath
unbox
underbar
underbrace
underleftarrow
underleftrightarrow
underline
underrightarrow
underset
undersetbrace
unhbox
unhcopy
unitlength
unlhd
unrhd
unskip
unvbox
uparrow
upbracefill
updownarrow
upharpoonleft
upharpoonright
uplus
uproot
upshape
upsilon
upuparrows
urcorner
usage
usebox
usecounter
usepackage
usualspace
vDash
vadjust
value
varepsilon
varinjlim
varkappa
varliminf
varlimsup
varnothing
varphi
varpi
varprojlim
varpropto
varrho
varsigma
varsubsetneq
varsubsetneqq
varsupsetneq
varsupsetneqq
vartheta
vartriangle
vartriangleleft
vartriangleright
vbox
vcenter
vcorrection
vdash
vdots
vec
vector
vee
veebar
vektor
verb
verbatim
verbatimchar
verse
vert
vfil
vfill
vfootnote
vfuzz
vglue
viiipt
viipt
vipt
vline
vmatrix
voffset
vphantom
vpt
vrule
vship
vsize
vskip
vspace
vsplit
vss
vtop
wedge
whiledo
widehat
widemargins
widetilde
widowpenalty
width
windowguide
wlog
write
writes
xalignat
xdef
xiipt
xipt
xivpt
xleftarrow
xpt
xrightarrow
xrule
xspaceskip
xvek
xviipt
xxalignat
xxpt
xxvpt
yen
zeta
}

# ×××× cmd acronym pairs ×××× #

#This set of acronym-expansion pairs must be maitained in a sorted format,
# just select full lines and use 'Text->SortLines'.  For a particular acronym
# with multiple ocurrences, if you want to have your choices presented in a 
# particular order, (other than alphabetical), insert extra spaces between the 
# pairs you want higher up in the list.  That will modify the order they will
# sort into.
set TeXacronyms {
10p    tenpoint
12p    twelvepoint
14p    fourteenpt
17p    seventeenpt
20p    twentypt
24p    twentyfourpt
29p    twentyninept
34p    thirtyfourpt
41p    fortyonept
aa     afterassignment
aa     alignat
aa     alignedat
ab     allowbreak
ac     actualchar
ac     allchapters
acl    addcontentsline
acs    arraycolsep
ad     adjdemerits
adb    allowdisplaybreak
adb    allowdisplaybreaks
ads    abovedisplayskip
adss   abovedisplayshortskip
ae     approxeq
af     abcfalse
afm    adjustfootnotemark
al     shoveleft
alb    allowlinebreak
amb    allowmathbreak
amf    AltMacroFont
ams    AmSTeX
an     abstractname
an     allocationnumber
an     alsoname
an     appendixname
ap     addpenalty
apn    advancepageno
ar     shoveright
arw    arrayrulewidth
as     accentedsymbol
as     arraystretch
at     abctrue
at     atop
atc    addtocontents
atc    addtocounter
atl    addtolength
atv    addtoversion
av     Arrowvert
av     arrowvert
avs    addvspace
ba     botaligned
baw    blackandwhite
bb     BlackBoxes
bb     bigbreak
bc     bibcite
bc     bigcap
bc     bigcirc
bc     bigcup
bd     bibdata
bd     boxdot
bds    belowdisplayskip
bdss   belowdisplayshortskip
be     Bumpeq
be     backepsilon
be     brokenv
be     bumpeq
bf     bottomfraction
bfr    botfigrule
bft    botfoldedtext
bg     begingroup
bg     bgroup
bi     beginitemize
bi     bibitem
bl     blacklozenge
blm    beginlinemode
bls    baselineskip
bls    baselinestretch
bm     backmatter
bm     batchmode
bm     boldmath
bm     bordermatrix
bm     botmark
bm     boxminus
bmd    boxmaxdepth
bn     bibname
bn     botnum
bod    bigodot
bop    bigoplus
bot    bigotimes
bp     backprime
bp     boxplus
bp     brokenpenalty
bpb    bigpagebreak
bpm    beginparmode
br     buildrel
bs     backsim
bs     backslash
bs     beginsection
bs     bibliographystyle
bs     bibstyle
bs     bigskip
bs     bigstar
bs     blacksquare
bs     boldsymbol
bs     botshave
bs     botsmash
bs     bslash
bs     bysame
bsa    bigskipamount
bsc    bigsqcup
bse    backsimeq
bt     BIBTEX
bt     BibTeX
bt     bibtex
bt     blacktriangle
bt     boxtimes
btd    bigtriangledown
btd    blacktriangledown
btl    blacktriangleleft
btr    blacktriangleright
btu    bigtriangleup
bup    biguplus
bv     bigvee
bv     bracevert
bw     barwedge
bw     bigwedge
ca     circledast
ca     curraddr
cal    circlearrowleft
cal    curvearrowleft
car    circlearrowright
car    curvearrowright
cb     ChangeBuffer
cb     columnbox
cc     catcode
cc     catcoded
cc     circledcirc
cd     centerdot
cd     chardef
cd     circleddash
cd     countdef
cdp    cleardoublepage
ce     circeq
cep    curlyeqprec
ces    curlyeqsucc
cf     casefrac
ci     closein
cl     centerline
cl     contentsline
cli    CodelineIndex
cln    CodelineNumbered
cm     CheckModules
cm     chaptermark
cm     checkmark
cn     chapno
cn     chaptername
cn     contentsname
co     closeout
cp     clearpage
cp     clubpenalty
cr     cellrow
cr     circledR
cr     coprod
cr     copyright
crs    copyrightspace
cs     CheckSum
cs     circledS
cs     clubsuit
cs     colorslides
cs     columnsep
cs     currentsection
csr    columnseprule
ct     CharacterTable
ct     cleartabs
ctos   CenteredTagsOnSplits
cv     curlyvee
cw     columnwidth
cw     curlywedge
da     Downarrow
da     downarrow
db     dashbox
db     displaybreak
db     dotbox
dbf    downbracefill
dbw    doublebarwedge
dc     deadcycles
dc     delcode
dc     documentclass
dcm    DontCheckModules
dcr    DisableCrossrefs
dd     Ddot
dd     diagdown
dd     docdate
dda    downdownarrows
de     DescribeEnv
de     doteq
ded    doteqdot
df     dotfill
df     doubleformat
dfpf   dblfloatpagefraction
dfr    dblfigrule
dfs    dblfloatsep
dg     digamma
dhd    doublehyphendemerits
dhl    downharpoonleft
dhr    downharpoonright
di     DocInput
dl     descriptionlabel
dl     displaylimits
dl     displaylines
dl15   displaylines;l5
dla    dashleftarrow
dm     DescribeMacro
dm     displaymath
dmo    DeclareMathOperator
dni    DoNotIndex
dot    divideontimes
dp     dotplus
dra    dashrightarrow
drs    doublerulesep
ds     Dostar
ds     diamondsuit
ds     displaystyle
ds     documentstyle
ds     dospecials
dsp    DocstyleParms
dsr    dosupereject
dsv    DeleteShortVerb
dt     DisableTabs
dta    DeclareTextAccent
dtad   DeclareTextAccentDefault
dtc    DeclareTextCommand
dtc    DeclareTextComposite
dtcc   DeclareTextCompositeCommand
dtcd   DeclareTextCommandDefault
dtf    dbltopfraction
dtfs   dbltexfloatsep
dtfs   dbltextfloatsep
dts    DeclareTextSymbol
dtsd   DeclareTextSymbolDefault
du     diagup
dv     dashv
dw     digitwidth
dw     displaywidth
dwp    displaywidowpenalty
ea     eqalign
ea     eqnarray
ea     expandafter
ean    eqalignno
eb     exambox
ec     eqcirc
ec     escapechar
ecc    encapchar
ecr    EnableCrossrefs
ecs    extracolsep
ed     everydisplay
ehp    exhyphenpenalty
ej     everyjob
em     ensuremath
em     errmessage
em     everymath
en     enclname
en     eqno
ep     eightpoint
ep     everypar
ep     exampage
er     eqref
ers    exrefsearch
es     emergencystretch
es     emptyset
esg    eqslantgtr
esl    eqslantless
esm    errorstopmode
esm    evensidemargin
et     EnableTabs
et     enabletabs
etp    enlargethispage
fa     forall
fa     fromaddress
fb     filbreak
fb     flushbottom
fb     framebox
fbr    fboxrule
fbs    fboxsep
fd     filedate
fds    fallingdotseq
ff     fontfamily
fh     firsthead
fh     footheight
fhd    finalhyphendemerits
fhs    fullhsize
fi     Finv
fis    footinsertskip
fl     flushleft
fl     footline
fl     fromlocation
fl     fullline
fl     futurelet
fm     firstmark
fm     frontmatter
fn     Fmtname
fn     figurename
fn     firstnumber
fn     fmtname
fn     fontname
fn     footnote
fn     fromname
fnm    footnotemark
fnr    footnoterule
fns    footnotesep
fns    footnotesize
fnt    footnotetext
fp     firstpart
fp     floatingpenalty
fp     flushpar
fpf    floatpagefraction
fr     flushright
fr     framerule
fs     floatsep
fs     fnsymbol
fs     fontseries
fs     fontshape
fs     fontsize
fs     footsep
fs     footskip
fs     footstrut
fs     framesep
fs     frenchspacing
fs     fromsig
ft     foldedtext
ft     fontest
fv     Fmtversion
fv     fileversion
fv     fmtversion
fwd    fracwithdelims
fz     famzero
ga     gtrapprox
gb     goodbreak
gd     gtrdot
ge     glossaryentry
gel    gtreqless
gel    gtreqqless
gf     genfrac
gl     gtrless
gm     GlossaryMin
gp     GlossaryParms
gp     GlossaryPrologue
gp'e   GlossaryPrologue
gp's   GlossaryParms
gs     gtrsim
gvn    gvertneqq
ha     hangafter
hc     hyphenchar
hdf    hdotsfor
hh     headheight
hi     hangindent
hl     headline
hla    hookleftarrow
hp     hyphenpenalty
hra    hookrightarrow
hrf    hrulefill
hs     halfstep
hs     headsep
hs     heartsuit
htn    headtoname
hw     halfwidth
hw     hidewidth
i14p   ifourteenpt
i17p   iseventeenpt
i20p   itwentypt
i24p   itwentyfourpt
i29p   itwentyninept
i34p   ithirtyfourpt
i41p   ifortyonept
ib     impliedby
ib     inbook
ic     intercal
id     itdefault
idlp   interdisplaylinepenalty
ie     idxentry
ie     indexentry
if     iffalse
iflp   interfootnotelinepenalty
ifnlp  interfootnotelinepenalty
ihdf   innerhdotsfor
ihm    ifhmode
ii     IndexInput
ii     ifinner
ii     itemindent
ii     itemitem
il     ifLandscape
il     iflanguage
ilp    interlinepenalty
im     IndexMin
im     imath
imm    ifmmode
in     ifnum
in     indexname
io     ifodd
io     includeonly
ip     IndexParms
ip     IndexPrologue
ip     insertpenalties
ip'e   IndexPrologue
ip's   IndexParms
irb    ifraggedbottom
is     ignorespaces
is     indexspace
is     itemsep
is     itshape
it     intertext
ite    ifthenelse
its    intextsep
iv     ifvoid
ivm    ifvmode
jm     jmath
jn     jobname
jr     joinrel
kw     keywords
la     leftarrow
la     lessapprox
laf    leftarrowfill
lai    leftappenditem
lal    looparrowleft
lar    looparrowright
lat    leftarrowtail
lb     lastbox
lb     linebreak
lc     leftcolumn
lc     levelchar
lcc    literalcatcodes
ld     lessdot
le     lefteqn
lean   leqalignno
leg    lesseqgtr
leg    lesseqqgtr
lei    labelenumi
leii   labelenumii
leiii  labelenumiii
leiv   labelenumiv
les    leqslant
lf     leaderfill
lf     listfiles
lfn    listfigurename
lg     lessgtr
lhd    leftharpoondown
lhu    leftharpoonup
li     labelitem
li     liminf
lii    labelitemi
liii   labelitemii
liiii  labelitemiii
liiv   labelitemiv
ll     leftline
lla    Lleftarrow
lla    Longleftarrow
lla    leftleftarrows
lla    longleftarrow
llra   Longleftrightarrow
llra   longleftrightarrow
lm     leavevmode
lm     leftmargin
lm     leftmark
lmi    leftmargini
lmt    longmapsto
lmvi   leftmarginvi
ln     labelenum
lof    listoffigures
loi    LimitsOnInts
lon    LimitsOnNames
los    LimitsOnSums
lot    listoftables
lp     linepenalty
lpi    listparindent
lr     leftroot
lra    Longrightarrow
lra    leftrightarrow
lra    leftrightarrows
lra    longrightarrow
lrh    leftrightharpoons
lrsa   leftrightsquigarrow
ls     labelsep
ls     lastskip
ls     leftskip
ls     lesssim
ls     lineskip
lsl    lineskiplimit
lt     leadsto
lt     linethickness
ltn    listtablename
ltt    leftthreetimes
lv     lVert
lw     labelwidth
lw     linewidth
ma     mathaccent
ma     measuredangle
mal    makeatletter
mao    makeatother
mb     makebox
mb     manyby
mb     markboth
mb     mathbin
mb     mathbreak
mb     medbreak
mb     midbox
mc     mathcal
mc     mathchar
mc     mathchoice
mc     mathclose
mc     mathcode
mc     multicolumn
mcd    mathchardef
mcdaw  minCDarrowwidth
mcts   MacrocodeTopsep
md     maxdepth
md     maxdimen
mdc    maxdeadcycles
mdl    makedateline
mf     MacroFont
mf     maxfootnotes
mfl    makefootline
mfn    maxfootnotes
mg     makeglossary
mh     makeheading
mhb    mathhexbox
mhl    makeheadline
mi     MacroIndent
mi     makeindex
mi     mathindent
mi     mathinner
mi     mathit
mi     midinsert
ml     makelabel
ml     makelabels
ml     moveleft
ml     multline
mlg    MultlineGap
mlg    multlinegap
mm     mainmatter
mm     multimap
mms    medmuskip
mn     mathnormal
mn     myname
mo     mathop
mo     mathord
mp     marginpar
mp     mathpalette
mp     minipage
mp     multiput
mpb    medpagebreak
mpl    MakePrivateLetters
mpp    marginparpush
mps    marginparsep
mpw    marginparwidth
mr     markright
mr     mathrel
mr     mathrm
mr     moreref
mr     moveright
ms     magstep
ms     mainsection
ms     mathscr
ms     mathsf
ms     mathstrut
ms     mathsurround
ms     mediumseries
ms     medskip
ms     medspace
ms     midspace
ms     multispan
ms     muskip
msa    medskipamount
msd    muskipdef
msh    magstephalf
msv    MakeShortVerb
mt     maketitle
mt     mapsto
mt     mathtt
mts    MacroTopsep
mv     mathversion
na     noalign
nb     newblock
nb     newbox
nb     nobreak
nb     normalbottom
nbb    NoBlackBoxes
nbd    nobreakdash
nbl    normalbaselines
nbls   normalbaselineskip
nc     newcodes
nc     newcommand
nc     newcount
nc     newcounter
nc     nocite
nc     nocorr
nd     newdimen
nds    negmedspace
nds    nulldelimiterspace
ne     newenvironment
ne     noexpand
nf     newfam
nf     newfont
nf     nofiles
nf     normalfont
nf     nullfont
nfs    nonfrenchspacing
ngn    nopagenumbers
nh     newhelp
ni     newif
ni     newinsert
ni     noindent
ni     notin
nils   nointerlineskip
nl     newlabel
nl     newlength
nl     newline
nl     nolimits
nl     nologo
nl     numberline
nla    nLeftarrow
nla    nleftarrow
nlb    nolinebreak
nlc    newlinechar
nloi   NoLimitsOnInts
nlon   NoLimitsOnNames
nlos   NoLimitsOnSums
nlra   nLeftrightarrow
nlra   nleftrightarrow
nls    normallineskip
nma    newmathalphabet
nmb    nomathbreak
nmlg   nomultlinegap
nmp    normalmarginpar
nms    newmuskip
nn     nextnumber
nn     nonumber
nn     notesname
np     newpage
np     nparallel
np     nprec
npb    nopagebreak
npe    npreceq
nr     newread
nra    nRightarrow
nra    nrightarrow
ns     newskip
ns     newswitch
ns     nonscript
ns     normalshape
ns     normalsize
ns     nsucc
nsb    newsavebox
nse    nsucceq
nsm    nonstopmode
nsm    nshortmid
nsp    nshortparallel
nsse   nsubseteq
nsse   nsubseteqq
nsse   nsupseteq
nsse   nsupseteqq
nt     newtheorem
nt     newtoks
nt     notag
ntl    ntriangleleft
ntle   ntrianglelefteq
ntr    ntriangleright
ntre   ntrianglerighteq
nts    negthickspace
nts    negthinspace
nts    newtheoremstyle
nw     newwrite
nw     numberwithin
ob     overbrace
oc     obeycr
oc     oldcodes
oc     onecolumn
od     OnlyDescription
oils   offinterlineskip
ol     obeylines
ol     overline
ola    overleftarrow
olra   overleftrightarrow
omi    OldMakeindex
on     oldnos
on     onlynotes
on     operatorname
onwl   operatornamewithlimits
oo     openout
op     outputpenalty
or     oddrule
or     overfullrule
ora    overrightarrow
os     obeyspaces
os     oldstyle
os     onlyslides
os     overset
osb    oversetbrace
osm    oddsidemargin
ou     openup
pa     precapprox
pb     pagebody
pb     pagebreak
pb     parbox
pc     PrintChanges
pc     pagecontents
pc     proclaim
pc     providecommand
pce    preccurlyeq
pd     pagedepth
pd     predate
pd     predefine
pd     prevdepth
pde    PrintDescribeEnv
pdm    PrintDescribeMacro
pdp    postdisplaypenalty
pe     preceq
pen    PrintEnvName
pf     prefgraf
pfs    parfillskip
pg     pagegoal
pg     prevgraf
ph     PaperHeight
ph     pageheight
ph     paperheight
pi     PageIndex
pi     PrintIndex
pi     pageinsert
pi     parindent
pi     printindex
pl     pagelayout
pl     projlim
pm     paragraphmark
pmn    PrintMacroName
pn     pagename
pn     pageno
pn     pagenumbering
pn     partname
pn     prefacename
pna    precnapprox
pns    precnsim
po     plainoutput
po     printoptions
pp     prepaper
pr     pageref
pr     produceref
ps     pageshrink
ps     pagestyle
ps     papersize
ps     parsep
ps     parshape
ps     parskip
ps     precsim
pt     PlainTeX
pt     poptab
pt     poptabs
pt     pretitle
pt     pretolerance
pt     propto
pt     pushtab
pt     pushtabs
ptc    ProvideTextCommand
ptp    ps@titlepage
pts    partopsep
pw     PaperWidth
pw     pagewidth
pw     paperwidth
qc     quotechar
qs     qedsymbol
ra     returnaddress
ra     rightarrow
raf    rightarrowfill
rat    rightarrowtail
rb     Relbar
rb     ResetBuffer
rb     raggedbottom
rb     raisebox
rc     RecordChanges
rc     renewcommand
rc     restorecr
rd     rmdefault
rds    risingdotseq
re     renewenvironment
rf     rmfam
rf     rmfamily
rhd    rightharpoondown
rhu    rightharpoonup
rii    Runinitem
rl     raggedleft
rl     rightline
rla    rightleftarrows
rlh    rightleftharpoons
rls    removelastskip
rm     rightmargin
rm     rightmark
rmp    reversemarginpar
rn     refname
rn     romannumber
rn     romannumeral
rr     raggedright
rra    rightrightarrows
rs     rightskip
rsc    refstepcounter
rsq    rightsquigarrow
rt     raisetag
rtt    rightthreetimes
sa     showallocations
sa     sphericalangle
sa     succapprox
sb     Setbox
sb     savebox
sb     sectionbreak
sb     setbox
sb     showbox
sb     smallbreak
sb     startbreaks
sb     stopbreaks
sbb    showboxbreadth
sbd    showboxdepth
sbm    splitbotmark
sc     setcounter
sc     skeuchar
sc     stepcounter
sc     subjclass
sce    succcurlyeq
sd     scaledocument
sd     secdef
sd     skipdef
se     StopEventually
se     subseteq
se     subseteqq
se     succeq
se     supereject
sec    SpecialEscapechar
sei    SpecialEnvIndex
sf     scalefont
sf     scriptfont
sf     selectfont
sf     sldefault
sf     smallfrown
sf     spacefactor
sh     showhyphens
sh     subheading
shd    spacehdots
si     SortIndex
si     SpecialIndex
si     subitem
sihd   spaceinnerhdots
sl     selectlanguage
sl     setlength
sl     showlists
sl     spreadlines
sl     startlabels
sl     stopletter
sls    scalelinespacing
slt    setlongtables
sm     scrollmode
sm     sectionmark
sm     setmarg
sm     setmargins
sm     setminus
sm     shiftmargins
sm     shortmid
sm     smallmatrix
smd    splitmaxdepth
smei   SpecialMainEnvIndex
smi    SpecialMainIndex
sml    spreadmatrixlines
sms    setmarginsrb
sn     seename
sn     serialnumber
sn     styname
sn     subjectname
sn     swapnumbers
sna    succnapprox
sne    subsetneq
sne    subsetneqq
sns    succnsim
so     shipout
so     showoutput
sof    showoverfull
sp     samepage
sp     secondpart
sp     shortparallel
sp     slidepage
sp     sloppypar
sp     subparagraph
spb    smallpagebreak
spf    suppressfloats
spm    subparagraphmark
sps    setpapersize
sr     seprow
sr     stackrel
ss     Supset
ss     scriptsize
ss     scriptstyle
ss     shortstack
ss     sideset
ss     smallskip
ss     smallsmile
ss     spaceskip
ss     spadesuit
ss     specialsection
ss     subsection
ss     substack
ss     succsim
ss     supset
ssa    smallskipamount
sse    sqsubseteq
sse    sqsupseteq
sse    supseteq
sse    supseteqq
ssi    subsubitem
ssm    smallsetminus
ssm    subsectionmark
ssne   supsetneq
ssne   supsetneqq
sss    scriptscriptsize
sss    scriptscriptstyle
sss    sqsubset
sss    sqsupset
sss    subsubsection
sssm   subsubsectionmark
st     scaletype
st     settabs
st     showthe
std    settodepth
sth    settoheight
sts    splittopskip
stw    settowidth
sui    SpecialUsageIndex
sv     styversion
ta     tabalign
ta     thickapprox
ta     toaddress
ta     toappear
ta     topaligned
ta     tracingall
tam    TagsAsMath
tat    TagsAsText
tb     textbullet
tb     thebibliography
tbf    textbf
tc     textcircled
tc     thechapter
tc     tracingcommands
tc     twocolumn
tcln   theCodelineNo
tcs    tabcolsep
tcwm   textcompwordmark
td     triangledown
te     tableentry
te     theenumi
te     theequation
te     triangleq
tf     textfont
tf     textfraction
tf     thefigure
tf     thickfrac
tf     topfraction
tfn    thefootnote
tfr    topfigrule
tfs    textfloatsep
tft    topfoldedtext
tfwd   thickfracwithdelims
th     textheight
th     totalheight
thla   twoheadleftarrow
thra   twoheadrightarrow
ti     textindent
ti     textit
ti     theindex
ti     topins
ti     topinsert
ti     typein
tl     thicklines
tl     thinlines
tl     triangleleft
tl     trivlist
tle    trianglelefteq
tm     textmd
tm     topmargin
tm     topmark
tm     topmatter
tm     tracingmacros
tmd    textemdash
tms    thickmuskip
tms    thinmuskip
tn     tablename
tn     tabularnewline
tn     telephonenum
tn     textnormal
tn     thenote
tn     toname
tn     topnum
tn     topnumber
tnd    textendash
tnp    topnewpage
to     theoverlay
to     tracingoutput
to     typeout
tobtos TopOrBottomTagsOnSplits
toc    tableofcontents
tol    TagsOnLeft
tol    tracingonline
tor    TagsOnRight
tp     thepage
tp     theparagraph
tp     thepart
tp     titlepage
tp     tracingparagraphs
tpc    textperiodcentered
tps    thispagestyle
tqbl   textquotedblleft
tqbr   textquotedblright
tqd    textquestiondown
tql    textquoteleft
tqr    textquoteright
tr     textrm
tr     triangleright
tre    trianglerighteq
tri    therosteritem
trr    tblraggedright
ts     tabbingsep
ts     tabskip
ts     textstyle
ts     theoremstyle
ts     thesection
ts     theslide
ts     thesubparagraph
ts     thicksim
ts     thickspace
ts     thinspace
ts     topsep
ts     topshave
ts     topskip
ts     topsmash
ts     topspace
ts     tracingstats
ts     twosided
tsf    textsf
tsl    textsl
tss    textsuperscript
tss    thesubsection
tsss   thesubsubsection
tt     thetable
tt     thetag
ttcd   textexclamdown
ttt    texttt
tu     textup
tvs    textvisiblespace
tw     textwidth
ua     Uparrow
ua     uparrow
ub     unbox
ub     underbar
ub     underbrace
ub     usebox
ubf    upbracefill
ubm    unboldmath
uc     usecounter
uda    Updownarrow
uda    updownarrow
uhl    upharpoonleft
uhr    upharpoonright
ul     underline
ul     unitlength
ula    underleftarrow
ulra   underleftrightarrow
up     usepackage
ur     uproot
ura    underrightarrow
us     underset
us     upshape
us     usualspace
usb    undersetbrace
uta    UseTextAccent
uts    UseTextSymbol
uua    upuparrows
vc     verbatimchar
vd     Vdash
ve     varepsilon
vk     varkappa
vli    varliminf
vls    varlimsup
vm     Vmatrix
vn     varnothing
vp     varphi
vp     varpi
vpl    varprojlim
vpt    varpropto
vr     varrho
vs     varsigma
vsne   varsubsetneq
vsne   varsubsetneqq
vssne  varsupsetneq
vssne  varsupsetneqq
vt     vartheta
vt     vartriangle
vtl    vartriangleleft
vtr    vartriangleright
vvd    Vvdash
wd     whiledo
wg     windowguide
wh     widehat
wm     widemargins
wp     widowpenalty
wt     widetilde
xaa    xalignat
xla    xleftarrow
xr     xrule
xra    xrightarrow
xss    xspaceskip
xxaa   xxalignat
}
