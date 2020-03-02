#!/usr/bin/env tclsh

set auto_path [linsert $auto_path 0 [pwd]/..]
# puts stderr $auto_path
package require pdf4tcl

pdf4tcl::new p1 -compress false -paper a4
p1 startPage
p1 line 100 140 300 160
p1 setStrokeColor 1 0 0
p1 arrow 100 150 300 170 10 15
p1 qCurve 100 100 200 300 300 100
p1 setStrokeColor 0 0 0
p1 setFillColor 0.3 0.6 0.9
p1 rectangle 400 40 166 166
p1 setFillColor 0 0 0
p1 drawTextAt 100 200 "linksbündig"
p1 drawTextAt 100 214 "rechtsbündig ?" -align right
p1 drawTextAt 100 228 "zentriert" -align center
p1 setFont 8 "Times-Roman"
p1 drawTextAt 100 242 "Dies ist ein etwas längerer Satz in einer kleineren Schriftart."
p1 setFont 12 "Courier-Bold"
for {set w 0} {$w<360} {incr w 15} {
 	p1 drawTextAt 200 400 "   rotierter Text" -angle $w
}
p1 circle 0 200 400 130
p1 setFillColor 1 1 1
p1 setLineStyle 0.1 5 2
p1 rectangle 348 288 224 104
p1 setFillColor 0 0 0
p1 setFont 12 "Times-Italic"
p1 drawTextBox 350 300 220 100 "Dieser Abschnitt sollte im Blocksatz gesetzt sein.\n\nDie Textbox ist 220 Postscript-Punkte breit. pdf4tcl teilt den Text an Leerzeichen, Zeilenendezeichen und Bindestrichen auf." -align justify
p1 setFillColor 0.8 0.8 0.8
p1 rectangle 348 408 224 54
p1 setFillColor 0 0 0
p1 drawTextBox 350 420 220 50 "Eine links- oder rechtsbündige und auch eine zentrierte Ausrichtung in der Textbox sind ebenfalls möglich." -align right
p1 addJpeg tcl.jpg 1
p1 putImage 1 20 20 -height 75
p1 setFillColor 1.0 0 0
p1 setStrokeColor 0 0 1
p1 setLineStyle 0.2 1 0
p1 polygon 1 100 600 300 600 250 650 150 650
p1 setStrokeColor 0 0.5 0
p1 polygon 0 300 650 500 650 450 600 350 600
#
foreach {w h} [pdf4tcl::getPaperSize a4] break
p1 startPage $w $h 0
p1 line 100 140 300 160
p1 setStrokeColor 1 0 0
p1 arrow 100 150 300 170 10 15
p1 qCurve 100 100 200 300 300 100
p1 setStrokeColor 0 0 0
p1 setFillColor 0.3 0.6 0.9
p1 rectangle 400 40 166 166
p1 setFillColor 0 0 0
p1 drawTextAt 100 200 "linksbündig"
p1 drawTextAt 100 214 "rechtsbündig ?" -align right
p1 drawTextAt 100 228 "zentriert" -align center
p1 setFont 8 "Times-Roman"
p1 drawTextAt 100 242 "Dies ist ein etwas längerer Satz in einer kleineren Schriftart."
p1 setFont 12 "Courier-Bold"
for {set w 0} {$w<360} {incr w 15} {
 	p1 drawTextAt 200 400 "   rotierter Text" -angle $w
}
p1 circle 0 200 400 130
p1 setFillColor 1 1 1
p1 setLineStyle 0.1 5 2
p1 rectangle 348 288 224 104
p1 setFillColor 0 0 0
p1 setFont 12 "Times-Italic"
p1 drawTextBox 350 300 220 100 "Dieser Abschnitt sollte im Blocksatz gesetzt sein.\n\nDie Textbox ist 220 Postscript-Punkte breit. pdf4tcl teilt den Text an Leerzeichen, Zeilenendezeichen und Bindestrichen auf." -align justify
p1 setFillColor 0.8 0.8 0.8
p1 rectangle 348 408 224 54
p1 setFillColor 0 0 0
p1 drawTextBox 350 420 220 50 "Eine links- oder rechtsbündige und auch eine zentrierte Ausrichtung in der Textbox sind ebenfalls möglich." -align right
p1 putImage 1 20 20 -height 75
p1 setFillColor 1.0 0 0
p1 setStrokeColor 0 0 1
p1 setLineStyle 0.2 1 0
p1 polygon 1 100 600 300 600 250 650 150 650
p1 setStrokeColor 0 0.5 0
p1 polygon 0 300 650 500 650 450 600 350 600

p1 write -file test4.pdf
p1 cleanup

