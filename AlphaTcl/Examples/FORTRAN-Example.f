
c FORTRAN Example.f
c 
c Included in the Alpha distribution as an example of the Fort mode
c 
c source of original document:
c 
c http://www.fortran.com/
c 

       PROGRAM COLORIT

c    *****************************************
c    By Dale Bickel, Senior Electronics Engineer, dbickel@fcc.gov
c    Audio Services Div., FCC (USA)
c    http://www.fcc.gov/mmb/asd/
c    
c    This Fortran CGI application may be copied and/or 
c    modified freely.  No restrictions are placed on its use. 
c    ******************************************
c    This program was created to develop a Fortran CGI.  It 
c    receives input from HTML and generates HTML output.
c    It could easily be modified to allow input from the 
c    keyboard or a Fortran routine.

c    CGI access is required if the program is used as written. 
c    The programming has not been optimized.  
c    ****************************************** 
 
c    This Fortran 77 program prints the HTML color corresponding 
c    to a six-place hexadecimal number.  It also prints, in table form,
c    the colors which result by increasing or decreasing a single
c    digit from the entered number.
c    *******************************************

c    First, we read the six digit value sent over from the HTML.
c    Because this program uses the GET method, this program
c    reads the environment variable QUERY_STRING.   We 
c    read each character from the string, and ignore unnecessary
c    characters (here, ... ?input=  ).
c    ********************************************

c    QS represents the character string  QUERY_STRING
c    Digit is the numerical value of the corresponding character
c    12 places are required to cover the whole QUERY_STRING
c    input=AAAAAA
c    ********************************************

c    Fortran reminders:
c    Column 1 -- enter C for Comments
c    Column 2-5 -- statement labels
c    Column 6 -- continuation character
c    Column 7 -- start commands in this column
c    Column 72 -- Last column of statement -- use continuation
c        characters or another Format statement if command is longer

c    First Statement of Program :  **********************             

       Character*12 QS
       Character*1 newcolor
       Dimension digit(12) 

c    ********************************************

c    Retrieve environment variable QUERY_STRING, using
c    "getenv" get environment variable subroutine on system.
c    This command may differ on other computer systems.
c    QUERY_STRING will be stored in the character string QS.

       call getenv('QUERY_STRING', QS)
    
c    ******************************************
c    Now we set up the Fortran code to generate HTML output.
c    The Content-type: text/html // statement accomplishes
c    this action.  The slashes // are VERY IMPORTANT!! 
c    Watch the placement of the quotes!

       Write(6,55)
 55    Format("Content-Type: text/html"//)

c    ******************************************
c    From now on, the usual HTML tags will appear inside
c    FORMAT statements.  Watch the quotation marks!
c    Note that HTML tags may be placed on the same line, or 
c    one tag may be broken up onto different lines.

       Write(6,64)
       Write(6,65)
       Write(6,66)

 64    Format('<HTML><HEAD><Title>')
 65    Format('COLORIT Color Generator --- A Fortran CGI</Title>')
 66    Format('</Head><Body bgcolor=' '#FFFFFF' '>')

c    Note the placement of the quote marks for the HTML 
c    code bgcolor="#FFFFFF"> in the previous statement
c    ******************************************

c    Here we generate the HTML for the output document's
c    heading:

       Write(6,1400)
       Write(6,1401)
       Write(6,1402)
       Write(6,1403)
       Write(6,1404)
       Write(6,1405)
       Write(6,1406)     
       Write(6,1407)
       Write(6,1408)
       Write(6,1410)
       Write(6,1411)
       Write(6,1412)
       Write(6,1413)
       Write(6,1414)
       Write(6,1415)
       Write(6,1416)
       Write(6,1417)
       Write(6,1418)

 1400  FORMAT('<Center>')      
 1401  FORMAT('<A HREF=' 'http://www.fcc.gov/' '><IMG SRC=' )
 1402  FORMAT('http://www.fcc.gov/fcc-gifs/hpban1.gif ' 'ALT=' )
 1403  FORMAT(' [ Federal Communications Commission ] ' '></A>')
 1404  FORMAT('<BR><a href=' )
 1405  FORMAT('http://www.fcc.gov/fcc-bin/htimage/pub/www/pub/opa.map')
 1406  FORMAT('><img src=' 'http://www.fcc.gov/fcc-gifs/iconbar.gif' )
 1407  FORMAT('height=20' 'width=525' 'alt=' '[icon bar]' 'vspace=5' )
 1408  FORMAT('border=1' 'ismap></a></CENTER><P>' )
 1410  FORMAT('<Center><TABLE Border=0 ><TR ALIGN=LEFT>')
 1411  FORMAT('<TD align=' 'left' '><IMG SRC=' )
 1412  FORMAT('http://www.fcc.gov/fcc-gifs/sealtiny.gif')
 1413  FORMAT(' alt=' '[ FCC Seal ]' '></TD><TD><B><H2>')
 1414  FORMAT('<Font Color="#D81654">COLORIT Color ')
 1415  FORMAT(' Generator</Font> ------ <Font Size=2><A HREF=')
 1416  FORMAT('http://www.fcc.gov/mmb/asd/bickel/fortran.html')
 1417  FORMAT('>A  Fortran CGI</A></Font></H2> Page 2')
 1418  FORMAT(' -- Output</TD></TR></TABLE></Center><P>')
 
c    ************************************************* 
c    Write the pertinent part of the Input QUERY_STRING to output 

       Write(6,79)
 79    Format('<Center><H3><Font Color=' '#FF0000' '>Input Color: ')
       Write(6,81) QS(7:7),QS(8:8),QS(9:9),QS(10:10),QS(11:11),QS(12:12)
 81    Format('</Font><B> '      AAAAAA '</B></H3>')
       Write(6,83)
 83    Format('</Center><P>' )

c    ********************************************
c    Here we replicate the initial HTML Form data entry fields

       Write(6,87)
       Write(6,88)
       Write(6,89)
       Write(6,90)
 
       Write(6,96)
       Write(6,92)
       Write(6,93)
       Write(6,94)
       Write(6,95)
       Write(6,96)


 87    Format('<Center><Form method=' 'GET' ' action=')
 88    Format('http://www.fcc.gov/fcc-bin/colorit' '>')
 89    Format('Change Color Here:   ')
 90    Format("<Input type='text' name='input' maxlength='6'>")
 92    Format("<Input Type='submit'  value='Get New Color' >")
 93    Format('<Font Color=' '#FFFFFE' '> . . .</Font>')
 94    Format("<Input Type='reset'  value='Clear Form' >")
 95    Format('</Form></Center>')
 96    Format('<BR><BR>')

c    ***********************************************
c    Be aware that "numbers" in the query_string really
c    aren't numbers -- they're ASCII characters.  They must 
c    be converted to integer or real numbers before use, 
c    e.g., if(QS(*:*).eq."1") x=1
c    
c    Character entries in the query string can be retrieved
c    by QS(first char. of substring : last char of substring)
c    Both first and last characters will be retrieved.  
c    
c    In the following code, a numerical character is looked for and
c    converted into its decimal counterpart.

       Do i=7,12,1

       If(QS(i:i).eq."0")  then
       digit(i)=0.0
       Else if(QS(i:i).eq."1")  then
       digit(i)=1
       Else if(QS(i:i).eq."2")  then
       digit(i)=2
       Else if(QS(i:i).eq."3")  then
       digit(i)=3
       Else if(QS(i:i).eq."4")  then
       digit(i)=4
       Else if(QS(i:i).eq."5")  then
       digit(i)=5
       Else if(QS(i:i).eq."6")  then
       digit(i)=6
       Else if(QS(i:i).eq."7")  then
       digit(i)=7
       Else if(QS(i:i).eq."8")  then
       digit(i)=8
       Else if(QS(i:i).eq."9")  then
       digit(i)=9
       Else if((QS(i:i).eq."A").or.(QS(i:i).eq."a")) then
       digit(i)=10
       Else if((QS(i:i).eq."B").or.(QS(i:i).eq."b"))  then
       digit(i)=11
       Else if((QS(i:i).eq."C").or.(QS(i:i).eq."c"))  then
       digit(i)=12
       Else if((QS(i:i).eq."D").or.(QS(i:i).eq."d"))  then
       digit(i)=13
       Else if((QS(i:i).eq."E").or.(QS(i:i).eq."e"))   then
       digit(i)=14
       Else if((QS(i:i).eq."F").or.(QS(i:i).eq."f"))   then
       digit(i)=15
       Else if(QS(i:i).eq."") then
       Go to 162
       Else 
       Write(6,159) QS(i:i)
 159   Format(A ' is not a valid character -- ')
       Write(6,160)
 160   Format('Please reenter six characters,<P>')
       Write(6,161) 
 161   Format('of type 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F<P>') 
          Go to 335
 162   End if
 
       End do
 
       Write(6,167)
       Write(6,168)
       Write(6,169)
 167   Format('<P>')
 168   Format('<Center>')
 169   Format('<Table width=' '95%' 'border=1>')

c    Loop through 9 rows, 4 above & 4 below the entered color code


       Do j=-4,4,1
       Write(6,177)
 177   Format('<TR align=' 'center' '>')

       If(j.eq.0) then
       Write(6,181)QS(7:7),QS(8:8),QS(9:9),QS(10:10),QS(11:11),QS(12:12)
 181   Format('<TD colspan=6 bgcolor=' '#'AAAAAA)
       Write(6,183)
 183   Format('align=' 'center' '>.<BR>')

c    Create a small label table, inside the data element

       Write(6,189)
       Write(6,190) QS(7:7),QS(8:8),QS(9:9),QS(10:10),QS(11:11),QS(12:12)
 
 189   Format('<Table border=0><TR><TD bgcolor=' '#FFFFFF' '>')
 190   Format('Submitted color= 'AAAAAA' </TD></TR></Table>')

       Write(6,193)
 193   Format('<BR>*</TD></TR>')
       Go to 320
         else if(j.ne.0) then       

c    Create HTML across the row -- 6 data elements

       Write(6,200)
 200   Format('<TR align=' 'center' '>')

       Do i=7,12,1

       Number=digit(i)+j

        If(number.eq.0) then
       newcolor="0"
        Else if(number.eq.1) then
       newcolor="1"
        Else if(number.eq.2) then
       newcolor="2"
        Else if(number.eq.3) then
       newcolor="3"
        Else if(number.eq.4) then
       newcolor="4"
        Else if(number.eq.5) then
       newcolor="5"
        Else if(number.eq.6) then
       newcolor="6"
        Else if(number.eq.7) then
       newcolor="7"
        Else if(number.eq.8) then
       newcolor="8"
        Else if(number.eq.9) then
       newcolor="9"
        Else if(number.eq.10) then
       newcolor="A"
        Else if(number.eq.11) then
       newcolor="B"
        Else if(number.eq.12) then
       newcolor="C"
        Else if(number.eq.13) then
       newcolor="D"
        Else if(number.eq.14) then
       newcolor="E"
        Else if(number.eq.15) then
       newcolor="F"
        End if

       If((number.lt.0).or.(number.gt.15)) then
       Write(6,243)
 243      Format('<TD bgcolor=')
          Write(6,244)
 244      Format('#FFFFFF' '>No color</TD>')
       Go to 320
       End if
 
       Write(6,243)
 
       If(i.eq.7) then
       write(6,270)newcolor,QS(8:8),QS(9:9),QS(10:10),QS(11:11),QS(12:12)
 
       Else if(i.eq.8) then
       Write(6,270)QS(7:7),newcolor,QS(9:9),QS(10:10),QS(11:11),QS(12:12)
 
       Else if(i.eq.9) then
       Write(6,270)QS(7:7),QS(8:8),newcolor,QS(10:10),QS(11:11),QS(12:12)
 
       Else if(i.eq.10) then
       Write(6,270)QS(7:7),QS(8:8),QS(9:9),newcolor,QS(11:11),QS(12:12)
 
       Else if(i.eq.11) then
       Write(6,270)QS(7:7),QS(8:8),QS(9:9),QS(10:10),newcolor,QS(12:12)
 
       Else if(i.eq.12) then
       Write(6,270)QS(7:7),QS(8:8),QS(9:9),QS(10:10),QS(12:12),newcolor
 
       End if
 270   Format(AAAAAA' align=' 'center' '><BR>')


c    Create a label table inside the data element

       Write(6,276)
 276   Format('<Table border=0><TR align=' 'center' '>')
 
       If(i.eq.7) then
       Write(6,311)
       Write(6,312)newcolor,QS(8:8),QS(9:9),QS(10:10),QS(11:11),QS(12:12)
       Write(6,313)newcolor,QS(8:8),QS(9:9),QS(10:10),QS(11:11),QS(12:12)
 
       Else if(i.eq.8) then
       Write(6,311)
       Write(6,312)QS(7:7),newcolor,QS(9:9),QS(10:10),QS(11:11),QS(12:12)
       Write(6,313)QS(7:7),newcolor,QS(9:9),QS(10:10),QS(11:11),QS(12:12)
 
       Else if(i.eq.9) then
       Write(6,311)
       Write(6,312)QS(7:7),QS(8:8),newcolor,QS(10:10),QS(11:11),QS(12:12)
       Write(6,313)QS(7:7),QS(8:8),newcolor,QS(10:10),QS(11:11),QS(12:12)
 
       Else if(i.eq.10) then
       Write(6,311)
       Write(6,312)QS(7:7),QS(8:8),QS(9:9),newcolor,QS(11:11),QS(12:12)
       Write(6,313)QS(7:7),QS(8:8),QS(9:9),newcolor,QS(11:11),QS(12:12)
 
       Else if(i.eq.11) then
       Write(6,311)
       Write(6,312)QS(7:7),QS(8:8),QS(9:9),QS(10:10),newcolor,QS(12:12)
       Write(6,313)QS(7:7),QS(8:8),QS(9:9),QS(10:10),newcolor,QS(12:12)
 
       Else if(i.eq.12) then
       Write(6,311)
       Write(6,312)QS(7:7),QS(8:8),QS(9:9),QS(10:10),QS(11:11),newcolor
       Write(6,313)QS(7:7),QS(8:8),QS(9:9),QS(10:10),QS(11:11),newcolor
 
       End if
 
       Write(6,314)
 
 311   Format('<TD bgcolor=' '#FFFFFF' '><A HREF=')
 312   Format('http://www.fcc.gov/fcc-bin/colorit?input='AAAAAA'>')
 313   Format(AAAAAA'</A></TD>')
 314   Format('</TR></Table>')

       Write(6,318)
 318   Format('<BR>.</TD>')

 320   Continue
       End do

       Write(6,324)
 324   Format('</TR>')

 99    Continue
       End do
 
       End if
       Write(6,330)
 330   Format('</table></center>')

       Write(6,331)
       Write(6,332)
       Write(6,333)
 331   Format('<P><Center><Font Size=2>NOTE: Because the colors')
 332   Format(' above are shown as BACKGROUNDS, <BR>they will')
 333   Format('  not show up when this page is printed.</Font><P>') 

 335   Continue

       Write(6,337)
       Write(6,338)
       Write(6,339)
       Write(6,338)
       Write(6,340)  
 337   Format('This document may be accessed at <A HREF=')
 338   Format('http://www.fcc.gov/mmb/asd/bickel/colorit.html')
 339   Format('>') 
 340   Format('</A><P></Center>')


c    Now that all of the colors have been shown, set up end-of-page
c    links & gifs

       Write(6,400)
       Write(6,401)
       Write(6,402)
       Write(6,403)
       Write(6,404)

       Write(6,400)
       Write(6,405)
       Write(6,406)
       Write(6,407)
       Write(6,408)
 
       Write(6,406)
       Write(6,409)
       Write(6,410)
       Write(6,406)
       Write(6,411)
       Write(6,412)
       Write(6,406)
       Write(6,413)
       Write(6,414)
       Write(6,406)
       Write(6,415)
       Write(6,416)      
       Write(6,406)
       Write(6,417)
       Write(6,418)
       Write(6,406)
       Write(6,419)
       Write(6,420)
       Write(6,406)
       Write(6,421)
 
       Write(6,422)
       Write(6,406)
       Write(6,423)
       Write(6,424)
       Write(6,406)
       Write(6,425)
       Write(6,426)
       Write(6,406)
       Write(6,427)
       Write(6,428)
       Write(6,400)
 
 400   Format('<CENTER>')
 401   Format('<IMG SRC=' 'http://www.fcc.gov/mmb/gif/yl_bar.gif')
 402   Format(' alt=' ' Line Across Page ' '>')
 403   Format('</Center>')
 404   Format('<P>')
 405   Format('<B>Jump to:</B><BR>')
 406   Format('<A HREF=')
 407   Format('http://www.fcc.gov/mmb/asd/' '>')
 408   Format('ASD Subject Index</A>,')
 409   Format('http://www.fcc.gov/mmb/asd/welcomeALT.html' '>')
 410   Format('ASD Alphabetical Index</A>,')
 411   Format('http://www.fcc.gov/search/' '>')
 412   Format('FCC Search Engine</A></CENTER><BR><UL><LI>')

 413   Format('http://www.fcc.gov/mmb/asd/main/filing.html' '>')
 414   Format('Filing an Application</A><LI>')
 415   Format('http://www.fcc.gov/mmb/asd/main/information.html')
 416   Format('>Application Information</A><LI>')
 417   Format('http://www.fcc.gov/mmb/asd/main/am.html' '>')
 418   Format('AM</A><LI>')
 419   Format('http://www.fcc.gov/mmb/asd/main/fm.html' '>')
 420   Format('FM and FM Translators & Boosters</A><LI>')
 421   Format('http://www.fcc.gov/mmb/asd/main/fact.html' '>')
 422   Format('Fact Sheets</A><LI>')
 423   Format('http://www.fcc.gov/mmb/asd/decdoc/intro.html')
 424   Format('>Decisions</A><LI>')
 425   Format('http://www.fcc.gov/mmb/asd/main/other.html#WITHIN')
 426   Format('>Links Within FCC</A><LI>')
 427   Format('http://www.fcc.gov/mmb/asd/main/other.html#OUTSIDE')
 428   Format('>Links to Outside the FCC</A></UL><P>')

       Write(6,406)
       Write(6,429)
       Write(6,430)
       Write(6,431)
       Write(6,432)
       Write(6,433)
       Write(6,434)
     
 429   Format('http://www.fcc.gov/mmb/' '>Mass Media Bureau</A>')
 430   Format(' -- <A HREF=' 'http://www.fcc.gov/' '>Federal ')
 431   Format('  Communications Commission</A></CENTER><P>')
 432   Format('<BR><BR><CENTER><IMG SRC=')
 433   Format('http://www.fcc.gov/fcc-gifs/small_seal.gif')
 434   Format(' alt=' '[ FCC Seal ]' '></CENTER>')


c    ********************************************
c    Without a closing HTML statement, you may not see ANY output!
     
       Write(6,999)
 999   Format('</Body></HTML>')
       Call Exit

c    END OF PROGRAM   
       END
