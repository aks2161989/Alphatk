# Taken from the Tcl's Wiki.
# trains2.tcl

# sep_rr.tcl -- TITLE: More model railroading with Tcl
# R. Suchenwirth, Konstanz 2001-03-10
if 0 {
[Richard Suchenwirth] - This weekend fun project varies the theme of
[Model railroading with Tcl] and takes a windshield perspective. Imagine
you're standing at a railroad crossing, red lights are flashing...
and then the train runs by - an armour yellow F7A, boxcars, gondola,
trailer on flat car.. and finally, the caboose. That's what the
following piece shows on a Tk canvas. You can control train speed with
left (faster), middle (emergency stop), and right (slower, or back)
mouse buttons.

In order to cope with the higher data complexity, some more structure and a
''rr'' namespace were introduced. The API, so to speak, is simple:
 rr::init   $canvas ;# creates and packs a canvas, if not existing
 rr::create $type $number [$otherdata] ;# make a vehicle (loco or car) 
 rr::train  $number $consist ;# vehicles of which a train is made up
 rr::run    $trainnumber ;# guess what that does ;-)
See the demo at end for concrete examples.
}
 namespace eval rr {
    variable data
    set data(curx) 700
    set data(y) 190
    proc init w {
	variable data
	set data(c) $w
	set data(speed) 10
	if ![winfo exists $w] {
	    canvas $w -width 700 -height 220 -bg lightblue
	    pack $w -expand 1 -fill both
	}
	$w delete all
	foreach i [after info] {after cancel $i}
	bind . <Shift-1> [list source [info script]]
	bind . <1> {incr rr::data(speed) 1}
	bind . <2> {set rr::data(speed) 0}
	bind . <3> {incr rr::data(speed) -1}
	bind .c <Motion> {wm title . [.c canvasx %x],[expr [.c canvasy %y]-190]}
	$w create poly 0 1000 0 77 42 67 99 130 155 73 199 102 255 83 312 126\
	     380 116 433 105 501 75 600 104 1200 100 1200 1000   -fill green3 -tag bg
	$w create rect 0 191 7000 200 -fill brown -outline brown ;# ballast
	$w create poly -500 720 100 130 700 720 -fill gray50 ;# road
	$w create poly 80 720 100 130 120 720 -outline yellow -fill gray50
	$w create line 0 190 7000 190 -fill gray -width 3 ;# rail
	crossing 210 215
    }
    proc define {name def} {
	variable data
	set data($name) $def
    }
    proc create {type id args} {
	variable data
	set c $data(c)
	set tag $type:$id
	foreach i [split $data($type) \n] {
	    set cmd [lindex $i 0]
	    switch $cmd {
	    bogie {
		set x [lindex $i 1]
		set diameter 21
		$c create oval $x -$diameter [expr $x+$diameter] 0\
		    -fill black -outline white -tag $tag
		set x1 [expr $x+[lindex $i 2]]
		$c create oval $x1 -$diameter [expr $x1+$diameter] 0\
		    -fill black -outline white -tag $tag
		set m [expr {$x+($x1+$diameter-$x)/2}]
		$c create rect [expr $m-10] -10 [expr $m+10] -30 -fill black -tag $tag
		$c create rect [expr $x-5] [expr -$diameter/2-5]\
		     [expr $x1+$diameter+5] [expr -$diameter/2+5] -fill gray20 -tag $tag
	    }
	    gp38body {
		set t [list gp38body $tag]
		$c create rect 0 -28 430 -21 -fill black -tag $t
		$c create rect 25 -28 70 -80 -fill red -tag $t    ;#nose
		$c create rect 70 -100 130 -28 -fill red -tag $t  ;#cab
		$c create rect 130 -100 410 -28 -fill red2 -tag $t ;#body
		$c create poly 180 -102 264 -102 264 -102 244 -90 200 -90\
		    180 -102 -fill red -outline black -tag $t
		$c create rect 54 -103 170 -93 -fill red -tag $t  ;#cab roof
		$c create line 290 -105 300 -105 -fill red -arrow both \
		    -arrowshape {-6 -5 3} -width 2 -tag $t ;# horns
		$c create rect 190 -22 255 -6 -fill black -tag $t ;#tank
		window $t 86 -90 26 18
		$c create line 100 -90 100 -72 -tag $tag ;# window separator
		$c create line 15 -8 15 -55 -fill white -width 2 -tag $tag
		$c create line 35 -8 35 -60 45 -60 57 -70 72 -70 -tag $t
		$c create line 128 -70 130 -70 140 -60 315 -60 320 -55 \
		    405 -55 405 -8 -tag "$t handrail"
		for {set x 150} {$x<400} {incr x 45} {
		    $c create line $x -60 $x -20 -tag "$t handrail"
		}
		$c create line 425 -8 425 -55 -fill white -width 2 -tag $tag
		for {set y -70} {$y<=-30} {incr y 10} {
		    $c create line 25 $y 30 [expr $y-8] -width 3 -fill white\
			-tag $t
		}
		$c create text 100 -60 -text $id\
		     -font {Helvetica 11 {bold italic}} -fill white -tag $t
		$c create text 225 -75 -text "CP Rail" \
		     -font {Helvetica 24 {bold italic}} -fill white -tag $t
		$c create oval 350 -90 400 -40 -fill white -outline white -tag $t
		$c create rect 375 -90 400 -40 -fill white -outline white -tag $t
		$c create poly 375 -65 400 -40 400 -90 -fill black -tag $t
		$c raise handrail
	    }
	    f7abody {
		set t [list f7abody $tag]
		$c create rect 0 -25 430 -22 -fill black -tag $tag
		$c create rect 400 -30 430 -90 -fill black -tag $tag
		$c create poly \
		17 -9 30 -85 35 -88 58 -90 60 -92 67 -106 70 -108 73 -110 \
		    425 -110 425 -15 410 -15 400 -25 295 -25 290 -15 165 -15 \
		    160 -25 45 -25 35 -9 -fill gold -tag $t
		$c create rect 30 -71 51 -59 -fill black -tag $t 
		$c create text 31 -71 -text $id -anchor nw -fill white -tag $t
		$c create poly 67 -102 72 -101 76 -97 70 -87 62 -92 \
		    -fill white -outline black -tag $t
		$c create poly 71 -81 80 -94 94 -94 94 -81 -fill white \
		    -outline black -tag $t
		$c create rect 98 -97 114 -52 -outline gold3 -tag $t
		$c create rect 101 -94 111 -81 -fill white -tag $t ;# cab door window
		$c create rect 118 -97 420 -80 -outline gold3 \
		     -tag $t ;# cooler grill
		for {set i 121} {$i<420} {incr i 3} {
		    $c create line $i -97 $i -80 -fill gold3 -tag $t
		}
		$c create rect 140 -110 424 -100 -fill gray75 \
		    -outline gray75 -tag $t;# roof
		$c create line 100 -113 110 -113 -arrow both \
		    -arrowshape {-5 -5 3} -width 2 -tag $t ;# horns
		$c create rect 103 -115 107 -110 -fill black -tag $t
		$c create oval 150 -77 165 -62 -fill gray50 -tag $t
		$c create oval 300 -77 315 -62 -fill gray50 -tag $t
		$c create text 145 -56 -text "U N I O N    P A C I F I C" -fill red \
		-font {Helvetica 13 bold} -anchor nw -tag $t
		$c create text 55 -56 -text $id -fill red -font {Helvetica 13 bold}\
		     -anchor nw -tag $t
		$c create line 55 -37 423 -37 -fill red -width 3 -tag $t
	    }
	    f7bbody {
		set t [list f7bbody $tag]
		$c create rect 0 -25 430 -22 -fill black -tag $tag
		$c create rect 0 -30 430 -90 -fill black -tag $tag
		$c create poly 17 -110 \
		    425 -110 425 -15 410 -15 400 -25 295 -25 290 -15 165 -15 \
		    160 -25 45 -25 35 -15 17 -15 -fill gold -tag $t
		$c create rect 22 -97 420 -80 -outline gold3 \
		     -tag $t ;# cooler grill
		for {set i 25} {$i<420} {incr i 3} {
		    $c create line $i -97 $i -80 -fill gold3 -tag $t
		}
		$c create rect 18 -110 424 -100 -fill gray75 \
		    -outline gray75 -tag $t;# roof
		$c create oval 150 -77 165 -62 -fill gray50 -tag $t
		$c create oval 300 -77 315 -62 -fill gray50 -tag $t
		$c create text 145 -56 -text "U N I O N    P A C I F I C" -fill red \
		-font {Helvetica 13 bold} -anchor nw -tag $t
		$c create text 55 -56 -text $id -fill red -font {Helvetica 13 bold}\
		     -anchor nw -tag $t
		$c create line 25 -37 423 -37 -fill red -width 3 -tag $t
	    }
	    boxcarbody {
		$c create rect 0 -25 380 -22 -fill black -tag $tag
		$c create rect 10 -26 370 -105 -fill [lindex $args 1] -tag $tag
		set rgrey grey[expr round(rand()*40+50)]
		$c create rect 10 -100 370 -105 -fill $rgrey -tag $tag
		$c create rect 160 -95 220 -30 -tag $tag
		$c create text 100 -70 -text [lindex $args 0] -fill white -tag $tag
		$c create text 100 -50 -text $id -fill white -tag $tag
	    }
	    baggagebody {
		$c create rect 0 -25 420 -22 -fill black -tag $tag
		$c create rect 0 -30 420 -92 -fill black -tag $tag
		$c create rect 5 -24 415 -100 -fill [lindex $args 1] -tag $tag
		set rgrey grey[expr round(rand()*20+70)]
		$c create rect 5 -90 415 -100 -fill $rgrey -tag $tag
		$c create text 205 -83 -text [join [split [lindex $args 0] ""] "       "]\
		     -fill red -font {Times 7 bold} -tag $tag
		$c create text 71 -44 -text $id  -tag $tag
		door $tag 20 -78 20 50 15
		$c create rect 190 -75 240 -30 -tag $tag
		door $tag 380 -78 20 50 16              
	    }
	    coachbody {
		$c create rect 0 -25 420 -22 -fill black -tag $tag
		$c create rect 0 -30 420 -90 -fill black -tag $tag
		$c create rect 5 -23 415 -100 -fill [lindex $args 1] -tag $tag
		set rgrey grey[expr round(rand()*20+70)]
		$c create rect 5 -90 415 -100 -fill $rgrey -tag $tag
		for {set y -50} {$y<=-30} {incr y 3} {
		    $c create line 11 $y 410 $y -fill white -tag $tag
		}
		$c create text 205 -83 -text [join [split [lindex $args 0] ""] "       "]\
		     -fill red -font {Times 7 bold} -tag $tag
		$c create text 71 -44 -text $id  -tag $tag
		door $tag 10 -75 20 50 15
		window $tag 45 -72 21 16 12 7
		door $tag 390 -75 20 50 16              
	    }
	    ocoachbody {
		$c create rect 0 -25 420 -22 -fill black -tag $tag
		$c create rect 20 -23 400 -90 -fill [lindex $args 1] -tag $tag
		set rgrey grey[expr round(rand()*20+40)]
		$c create rect 5 -90 415 -95 -fill $rgrey -tag $tag
		$c create poly 20 -95 40 -102 380 -102 400 -95 -fill grey\
		    -outline black -width 2 -tag $tag
		for {set x 50} {$x<=370} {incr x 20} {
		    $c create line $x -95 $x -102 -width 2 -tag $tag
		}
		$c create line 5 -5 5 -90 -tag $tag
		$c create line 415 -5 415 -90 -tag $tag
		$c create line 20 -88 400 -88 -fill yellow -tag $tag
		$c create text 205 -83 -text [join [split [lindex $args 0] ""] "       "]\
		     -fill yellow -font {Times 7 bold} -tag $tag
		$c create line 20 -78 400 -78 -fill yellow -tag $tag
		$c create text 40 -40 -text $id -fill yellow -tag $tag
		$c create text 380 -40 -text $id -fill yellow -tag $tag
		window $tag 50 -72 15 22 16 5
		$c create line 50 -65 350 -65 -tag $tag
		$c create line 20 -27 400 -27 -fill yellow -tag $tag
	    }
	    domebody {
		$c create rect 0 -25 420 -22 -fill black -tag $tag
		$c create rect 0 -30 420 -90 -fill black -tag $tag
		$c create rect 5 -24 415 -100 -fill [lindex $args 1] -tag $tag
		set rgrey grey[expr round(rand()*20+70)]
		$c create rect 5 -90 415 -100 -fill $rgrey -tag $tag
		$c create poly 110 -92 100 -100 130 -120 300 -120 330 -100 320 -92 \
		    -fill lightcyan -outline black -tag $tag ;# dome
		for {set x 130} {$x<=300} {incr x 34} {
		    $c create line $x -120 $x -90 -tag $tag
		}
		$c create line 123 -115 130 -110 300 -110 308 -118 -tag $tag
		$c create text 210 -83 -text [join [split [lindex $args 0] ""] "       "]\
		     -fill red -font {Times 7 bold} -tag $tag
		for {set y -50} {$y<=-30} {incr y 3} {
		    $c create line 11 $y 410 $y -fill white -tag $tag
		}
		$c create text 71 -44 -text $id  -tag $tag
		door $tag 20 -75 20 50 15
		window $tag 110 -60 25 15 6 10 
		door $tag 380 -75 20 50 16              
	    }
	    caboosebody {
		$c create rect 0 -25 300 -22 -fill black -tag $tag
		$c create poly 35 -25 35 -100 120 -100 120 -130 190 -130\
		     190 -100 270 -100 270 -25\
		     -fill [lindex $args 1] -tag $tag
		$c create line 10 -10 10 -100 -tag $tag
		$c create line 290 -10 290 -100 -tag $tag
		set rgrey grey[expr round(rand()*40+10)]
		$c create rect 10 -100 120 -105 -fill $rgrey -tag $tag
		$c create rect 115 -125 195 -130 -fill $rgrey -tag $tag
		$c create rect 190 -100 290 -105 -fill $rgrey -tag $tag
		$c create rect 210 -105 215 -130 -fill black -tag $tag
		window $tag 130 -120 18 15 2 15
		window $tag  50 -75 19 17 2 15
		window $tag 200 -75 19 17 2 15
		$c create text 150 -90 -text [lindex $args 0] -fill white -tag $tag
		$c create text 150 -50 -text $id -fill white -tag $tag
		$c create arc 40 -30 85 -85 -style arc -start 180 \
		    -extent 90 -outline yellow -width 1 -tag $tag
		$c create arc 220 -30 265 -85 -style arc -start 270 \
		    -extent 90 -outline yellow -width 1 -tag $tag
	    }
	    flatcarbody {
		$c create rect 0 -25 380 -22 -fill black -tag $tag
		$c create rect 10 -26 370 -35 -fill [lindex $args 1] -tag $tag
		$c create text 80 -29 -text [lindex $args 0] -fill white -tag $tag
		$c create text 220 -29 -text $id -fill white -tag $tag
	    }
	    gondolabody {
		$c create rect 0 -25 380 -22 -fill black -tag $tag
		$c create rect 10 -26 370 -90 -fill [lindex $args 1] -tag $tag
		$c create text 100 -70 -text [lindex $args 0] -fill white -tag $tag
		$c create text 100 -50 -text $id -fill white -tag $tag
	    }
	    hopperbody {
		$c create rect 0 -25 380 -22 -fill black -tag $tag
		$c create poly 10 -100 10 -50 120 -10 130 -30 180 -10 190 -30\
		    200 -10 250 -30 260 -10 370 -50 370 -100 -fill [lindex $args 1] -tag $tag
		$c create rect 10 -26 370 -100 -width 2 -tag $tag
		for {set x 52} {$x<360} {incr x 93} {
		    $c create line $x -26 $x -100 -width 2 -tag $tag
		}
		$c create text 90 -50 -text "[lindex $args 0] $id" -fill white -tag $tag
		$c create text 190 -60 -text [lindex $args 0] -font {Times 24 bold}\
		    -fill white -tag $tag
	   }
	    trailer {
		set color [lindex $i 1]
		$c create rect 40 -110 340 -50 -fill $color -tag $tag
		$c create text 190 -80 -text "ROADWAY" \
		    -font {Helvetica 40} -fill green4 -tag $tag
		$c create line 80 -50 80 -35 -width 3 -tag $tag
		$c create oval 240 -50 260 -30 -fill gray50 -tag $tag 
		$c create oval 280 -50 300 -30 -fill gray50 -tag $tag
		$c create oval 245 -45 255 -35 -fill $color -tag $tag 
		$c create oval 285 -45 295 -35 -fill $color -tag $tag
	    }
	    "" continue
	    default {error "bad definition word $cmd:\n$i"}
	    }
	}
    }
    proc train {name rstock} {
	variable data
	set c $data(c)
	set newx 0
	foreach i $rstock {
		$c move $i $data(curx) $data(y)
		set data(curx) [lindex [$c bbox $i] 2]
		$c addtag $name withtag $i
	}
	incr data(curx) 3000
    }
    proc crossing {x y} {
	variable data
	set c $data(c)
	$c create line [expr $x-10] [expr $y-40] [expr $x+15] [expr $y-40]\
	    -width 3 -tag fg
	$c create rect $x $y [expr $x+5] [expr $y-70] -fill orange -tag fg
	$c create line [expr $x-15] [expr $y-80] [expr $x+20] [expr $y-60]\
	     -width 5 -fill white -tag fg
	$c create line [expr $x-15] [expr $y-60] [expr $x+20] [expr $y-80]\
	     -width 5 -fill white -tag fg
	$c create oval [expr $x-8] [expr $y-45] [expr $x-18] [expr $y-35]\
	    -fill white -tag fg
	$c create oval [expr $x-10] [expr $y-43] [expr $x-16] [expr $y-37]\
	    -fill black -tag {fg blink0}
	$c create oval [expr $x+15] [expr $y-45] [expr $x+25] [expr $y-35]\
	    -fill white -tag fg
	$c create oval [expr $x+17] [expr $y-43] [expr $x+23] [expr $y-37]\
	    -fill black -tag {fg blink1}
	set data(blink) 1
	flashCrossing 0
    }
    proc flashCrossing {which} {
	variable data
	set c $data(c)
	if $data(blink) {$c itemconfig blink$which -fill red -outline red}
	set which [expr 1-$which]
	$c itemconfig blink$which -fill black -outline black
	after 250 [list rr::flashCrossing $which]
    }
    proc window {t x y w h {n 1} {space 10}} {
	variable data
	set c $data(c)
	for {set i 0} {$i<$n} {incr i} {
	    $c create rect $x $y [expr $x+$w] [expr $y+$h] -fill black -tag $t
	    $c create rect [expr $x+3] [expr $y+3] [expr $x+$w] [expr $y+$h]\
		 -fill white -tag $t
	    set x [expr $x+$w+$space]
	}
    }
    proc door {t x y w h winh} {
	variable data
	set c $data(c)
	$c create rect $x $y [expr $x+$w] [expr $y+$h] -tag $t
	incr w -8
	incr x 4
	incr y 4
	window $t $x $y $w $winh

    }
    proc run {trains} {
	variable data
	set c $data(c)
	foreach train $trains {
	    $c move $train [expr {-$data(speed)}] 0
	    update idletasks
	    if [lindex [$c bbox $train] 2]<0 {
		$c move $train 15000 0
		set data(blink) 0
	    } elseif [lindex [$c bbox $train] 0]<1500 {
		set data(blink) 1
	    }
	    after 40 [list rr::run $train]
	    $c raise fg
	}
    }
 define F7A {
    bogie 55 60
    bogie 305 60
    f7abody
 }
 define F7B {
    bogie 55 60
    bogie 305 60
    f7bbody
 }
 define GP38 {
    bogie 60 50
    bogie 310 50
    gp38body
 }
 define boxcar {
    bogie 40 40
    bogie 280 40
    boxcarbody
 }
 define coach {
    bogie 50 40
    bogie 310 40
    coachbody
 }
 define ocoach {
    bogie 50 40
    bogie 310 40
    ocoachbody
 }
 define domecar {
    bogie 50 40
    bogie 310 40
    domebody
 }
 define baggage {
    bogie 50 40
    bogie 310 40
    baggagebody
 }
 define gondola {
    bogie 40 40
    bogie 280 40
    gondolabody
 }
 define hopper {
    bogie 30 40
    bogie 290 40
    hopperbody
 }
 define flatcar {
    bogie 40 40
    bogie 280 40
    trailer gray85
    flatcarbody
 }
 define caboose {
    bogie 40 40
    bogie 190 40
    caboosebody
 }
 }
# Usage examples, and demo:
 rr::init .c
 rr::create F7A I50I
 rr::create F7B I308
 rr::create GP38 3018
 rr::create GP38 3022
 rr::create hopper 12988 "N & W" grey30
 rr::create boxcar 42135 ATSF brown
 rr::create boxcar 42199 C&NW orange
 rr::create gondola 745219 N.Y.C. salmon4
 rr::create baggage 93152 "UNION PACIFIC" grey90
 rr::create coach 4312 "UNION PACIFIC" grey90
 rr::create domecar 7001 "UNION PACIFIC" grey95
 rr::create coach 4319 "UNION PACIFIC" grey90
 rr::create ocoach 4711 "BALTIMORE & OHIO" darkgreen
 rr::create ocoach 5006 "PENNSYLVANIA" firebrick
 rr::create caboose 18832 "U N I O N   P A C I F I C" red2
 rr::create flatcar 88402 "BOSTON & MAINE" black

 rr::train UP1 {
     F7A:I50I F7B:I308 baggage:93152 coach:4319 domecar:7001 coach:4312
     ocoach:4711 ocoach:5006
 }

 rr::train CP123 {
    GP38:3018 GP38:3022 hopper:12988
    boxcar:42135 flatcar:88402 gondola:745219 boxcar:42199 
    caboose:18832
 }
 rr::run {CP123 UP1}
if 0 {[Arts and crafts of Tcl-Tk programming]}

