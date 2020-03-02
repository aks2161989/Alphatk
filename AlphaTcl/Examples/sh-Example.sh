## -*-sh-*-
 # ==========================================================================
 # sh-Example.sh
 # 
 # Distributed as an example of Alpha's sh Scripts mode.
 #
 # Source of original file:
 # 
 # <http://www.softlab.ntua.gr/~christia/man-cgi>
 # 
 # This file demonstrates a 'command' style syntax -- toggle the sh mode
 # preference 'Navigate Blocks' to explore file marking and navigation.
 # 
 # ==========================================================================
 ##

#!/bin/sh
# Man-cgi : a Common Gateway Interface which converts the output of
#           the "man" command to HTML
#
VERSION="1.15"
#
# Author  : Panagiotis J. Christias <christia@theseas.ntua.gr>
#
# Usage   : it goes in the /cgi-bin/ directory. When called without 
#           arguments (http://www-server/cgi-bin/man-cgi) it outputs a
#           "Front Page" with a section list and query form. When called
#           with arguments, the first argument is the topic (e.g. ls)
#           and the second argument (optional) is the section to look in.
#
#           Examples:
#               http://www.ntua.gr/cgi-bin/man-cgi?ls
#               http://www.ntua.gr/cgi-bin/man-cgi?sleep+3
#
# Notice  : Man-cgi uses the following two images, you may want to get them
#           and put them in your w3 server:
#               http://www.ntua.gr/images/doty.gif
#               http://www.ntua.gr/images/pages.gif
#
# History :
#   1.15    Multiple blank lines are supressed.
#   1.14    Man-cgi now recognizes cross-references that
#           contain periods (e.g. foo.foo(3)).
#   1.13    Really fixed problems occuring in pages which used
#           multi-overstrike for emboldening (hopefully).
#   1.12    Fixed problems occuring in pages which used multi-overstrike
#           for emboldening. Now Man-cgi works any number of overstrike.
#   1.11    Fixed problem with hyphenated cross-references.
#   1.10 and earlier, no history at that time...
#
# Last update: Fri May 5 1995
#

### CONFIGURATION SECTION : change the following variables to fit your needs ###

# The HTTPD server may not pass the enviroment variables to the script.
# You should add your system path here :
PATH=/usr/gnu/bin:/bin:/usr/ucb:/usr/bin:/usr/local/bin:/usr/misc/bin
export PATH

# The same for the man path here :
MANPATH=/usr/gnu/man:/usr/local/man:/usr/X11R5/man:/usr/new/man:/usr/misc/man:/usr/man:/usr/openwin/man:/usr/lang/man
export MANPATH

# The full URL of the Man-cgi :
MANCGI='http://www.ntua.gr/cgi-bin/man-cgi'

# The URL of the two images :
DOT=http://www.ntua.gr/images/doty.gif
PAGES=http://www.ntua.gr/images/pages.gif

### END OF CONFIGURATION SECTION ###############################################

SECTION=$2
COMMAND=$1

echo "Content-type: text/html"
echo ""

if [ $# -eq 2 ] ; then
  if [ $2 = "00" ] ; then
    read a

    COMMAND=`echo $a | sed 's/command=\(.*\)&.*/\1/'`
    SECTION=`echo $a | sed 's/command=.*&section=\(.*\)
/\1/'`

    if [ $SECTION = "ANY" ] ; then
	SECTION=""
      fi;
  fi;
fi

if [ $# -ne 0 ] ; then
  cat <<END
  <TITLE>UNIX man pages : $COMMAND ($SECTION)</TITLE>
  <h4>NOTE: click <A HREF="$MANCGI?$COMMAND">here</A> if you get an empty page.</h4>
  <hr>
END
  man "$SECTION" "$COMMAND" | \
  sed \
          -e '/-$/N
{
s/\([0-9A-z][-,0-9A-z]*\)-\n\(  *\)\([0-9A-z][-,0-9A-z]*([1-9][A-z]*)\)/\1\3\
\2/
}' \
          -e '/-$/N
{
s/\([0-9A-z][-,0-9A-z]*\)-\n\(  *\)\([0-9A-z][-,0-9A-z]*([1-9][A-z]*)\)/\1\3\
\2/
}' \
          -e '/-$/N
{
s/\([0-9A-z][-,0-9A-z]*\)-\n\(  *\)\([0-9A-z][-,0-9A-z]*([1-9][A-z]*)\)/\1\3\
\2/
}' \
          -e '/-$/N
{
s/\([0-9A-z][-,0-9A-z]*\)-\n\(  *\)\([0-9A-z][-,0-9A-z]*([1-9][A-z]*)\)/\1\3\
\2/
}' \
	  -e 's/</«/g' \
	  -e 's/>/»/g' \
   \
	  -e '/^[A-Z]/s/.//g' \
	  -e 's/^[A-Z][ ,A-Z]*$/<H2>&<\/H2>/' \
   \
	  -e 's/_\(.\)/<i>\1<\/i>/g' \
	  -e 's/.\(.\)/<b>\1<\/b>/g' \
   \
          -e 's#</b><b>.##g' \
          -e 's#</b>.<b>##g' \
          -e 's#.##g' \
          -e 's#_</i<b><</b>i>##g'  \
   \
	  -e 's/<\/i><i>//g' \
	  -e 's/<\/b><b>//g' \
   \
	  -e 's/^  \([A-Z][ ,0-9A-z]*\)$/  <b>\1<\/b>/' \
	  -e 's/^   \([A-Z][ ,0-9A-z]*\)$/  <b>\1<\/b>/' \
   \
	  -e "/^   /s#\(\([0-9A-z][-.,0-9A-z]*\)(\([1-9]\)[A-z]*)\)#<A HREF=\"$MANCGI\?\2+\3\">\1</A>#g" \
	  -e "/^   /s#\(<i>\([0-9A-z][-.,0-9A-z]*\)</i>(\([1-9]\)[A-z]*)\)#<A HREF=\"$MANCGI\?\2+\3\">\1</A>#g" \
   \
	  -e "s#<b>+<\/b>#<IMG SRC=$DOT>#" \
   \
          -e 's/«/\&lt;/g' \
          -e 's/»/\&gt;/g' \
   \
          -e '1s/^/<PRE>
/' \
          -e '$s/$/
<\/PRE>
/' | \
awk '/^$/     { if(!blank) { print; blank=1 } }
     /^..*$/  { print; blank=0 }'

else
  cat <<END
  <HEAD>
  <TITLE>UNIX man pages</TITLE>
  </HEAD>
  <BODY>
  <H1><IMG SRC=$PAGES> UNIX ON-LINE Man Pages</H1>
  <hr><P>
  These are the UNIX man pages. The html versions are created on the fly
  by a <i>simple</i> shell/sed/awk script.
  <P>
  <H5>NOTICE: There are still problems with
  the man pages that are not stored in the right section. In
  this case you'll get an empty page. Follow the link at the top of the
  empty page and you'll get your man page (hopefully).</H5>
  
  Here are the intro pages of each section:
  <P>
  <OL>
  <LI><A HREF="$MANCGI?intro+1">USER COMMANDS</A>
  <LI><A HREF="$MANCGI?intro+2">SYSTEM CALLS</A>
  <LI><A HREF="$MANCGI?intro+3">C LIBRARY FUNCTIONS</A>
  <LI><A HREF="$MANCGI?intro+4">DEVICES AND NETWORK INTERFACES</A>
  <LI><A HREF="$MANCGI?intro+5">FILE FORMATS</A>
  <LI><A HREF="$MANCGI?intro+6">GAMES AND DEMOS</A>
  <LI><A HREF="$MANCGI?intro+7">ENVIRONMENTS, TABLES, AND TROFF MACROS</A>
  <LI><A HREF="$MANCGI?intro+8">MAINTENANCE COMMANDS</A>
  <LI><A HREF="$MANCGI?X+1">X WINDOW SYSTEM</A>
  </OL>
  <P><hr>
  You can also request a man page by name and (optionally) by section:
  <P>
  <FORM METHOD=POST ACTION=$MANCGI?00+00>
  Set command name :  <INPUT NAME=command SIZE=24>
  <INPUT TYPE=submit VALUE="Fetch man page">
  <P>Set Section number : <SELECT NAME=section>
  <OPTION VALUE="ANY"> ANY
  <OPTION VALUE="1" > 1
  <OPTION VALUE="2" > 2
  <OPTION VALUE="3" > 3
  <OPTION VALUE="4" > 4
  <OPTION VALUE="5" > 5
  <OPTION VALUE="6" > 6
  <OPTION VALUE="7" > 7
  <OPTION VALUE="8" > 8
  <OPTION VALUE="n" > n
  <OPTION VALUE="x" > x
  </SELECT>
  </FORM>
END
fi
cat <<END
  <hr>
  <ADDRESS>
  © 1994 <A HREF="http://www.ntua.gr/~christia/man-cgi.html">Man-cgi $VERSION</A>, Panagiotis Christias &lt;christia@theseas.ntua.gr&gt;
  </ADDRESS>
END
