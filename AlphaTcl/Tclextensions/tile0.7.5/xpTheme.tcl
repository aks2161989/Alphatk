#
# $Id: xpTheme.tcl,v 1.30 2006/02/06 04:12:43 jenglish Exp $
#
# Tile widget set: XP Native theme
#
# @@@ todo: spacing and padding needs tweaking

namespace eval tile {

    style theme settings xpnative {

	style configure . \
	    -background SystemButtonFace \
	    -foreground SystemWindowText \
	    -selectforeground SystemHighlightText \
	    -selectbackground SystemHighlight \
	    -font TkDefaultFont \
	    ;

	style map "." \
	    -foreground [list disabled SystemGrayText] \
	    ;

	style configure TButton -padding {1 1} -width -11
	style configure TRadiobutton -padding 2
	style configure TCheckbutton -padding 2
	style configure TMenubutton -padding {8 4}

	style configure TNotebook -expandtab {2 2 2 2}

	style configure TLabelframe -foreground "#0046d5"

	# OR: -padding {3 3 3 6}, which some apps seem to use.
	style configure TEntry -padding {2 2 2 4}
	style map TEntry \
	    -selectbackground [list !focus SystemWindow] \
	    -selectforeground [list !focus SystemWindowText] \
	    ;
	style configure TCombobox -padding 2

	style configure Toolbutton -padding {4 4}
    }
}
