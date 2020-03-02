
/* Posted by Daniel K. Schneider at  */
/* http://tecfa.unige.ch/guides/php/ */

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<HTML>
  <HEAD>
    <TITLE>Php Test (17-Apr-1998)</TITLE>
    <!-- Created by: D.K.S., 14-Apr-1998 -->
    <!-- Changed by: D.K.S., 17-Apr-1998 -->


  </HEAD>
  <BODY>
    <H1>Php Test</H1>

Hello <? getenv("REMOTE_USER") ?>. This file
contains a few HTTP related php tricks. You can <A HREF="test.phps">look at the pretty printed source code !</A>

    <hr><h2>Date</H2>
    <?php
      $birthday = mktime (0,0,0,6,13,1998);
      $now = time();
      $diff = $birthday - $now;
      ?>
    Hello, it's 
    <?php echo (date("H:i, l F d Y", $now)); ?>.
    Still <?php echo (date ("z", $diff))?> days to go until my birthday.


    <hr><h2>Request Headers:</H2>

    Will display the request headers (sent by the client):
    <p>
    <?php
    $headers = getallheaders();
    for(reset($headers); $key = key($headers); next($headers)) {
    echo "headers[$key] = ".$headers[$key]."<br>\n";
    }
    ?>
    <p>
    Will display all environment variables in $argv (probably none here):<br>
   <?

   for ($i=0; $i<sizeOf($argv); $i++) {
	// echo "{key=".key($argv)." }";
    $element = $argv[$i];
    echo $element;
    }    
   ?>

   <p>

    <hr><h2>Standard CGI variables:</H2>
.... a long scary list about yourself and ourselves 
<p>
   <?
//echo $GLOBALS["DOCUMENT_ROOT"];
    for(reset($GLOBALS); $key = key($GLOBALS); next($GLOBALS)) {
    echo "GLOBALS[$key] = ".$GLOBALS[$key]."<br>\n";
    }
   ?>

   <p>
   Will display get, post, cookie variables (probably none here) <br>
   ($HTTP_GET_VARS[], $HTTP_POST_VARS[] and $HTTP_COOKIE_VARS[] arrays):
   <br>
   <?
    // echo "$HTTP_GET_VARS";
    if ($HTTP_GET_VARS) {
    for(reset($HTTP_GET_VARS); $key = key($HTTP_GET_VARS); next($HTTP_GET_VARS)) {
    echo "\$HTTP_GET_VARS[$key] = ".$HTTP_GET_VARS[$key]."<br>\n";
    }
    echo "<p>";
    }

    if ($HTTP_POST_VARS) {
    for(reset($HTTP_POST_VARS); $key = key($HTTP_POST_VARS); next($HTTP_POST_VARS)) {
    echo "\$HTTP_POST_VARS[$key] = ".$HTTP_POST_VARS[$key]."<br>\n";
    }
    echo "<p>";
    }


    if ($HTTP_COOKIE_VARS) {
    for(reset($HTTP_COOKIE_VARS); $key = key($HTTP_COOKIE_VARS); next($HTTP_COOKIE_VARS)) {
    echo "\$HTTP_COOKIE_VARS[$key] = ".$HTTP_COOKIE_VARS[$key]."<br>\n";
    }
   }
   ?>



    <hr><h2>Check language and customize output</H2>
    
    This example shows how to select a language based on the clients preference
and what you decide to offer. Modified example from
<A HREF="http://www.sklar.com/px/section.html?section_id=6">PX:PHP Code Exchange</A>.<br>

    <?
    echo ("Client/Browser accepted languages = $HTTP_ACCEPT_LANGUAGE. ");
    $supported_languages = array(
    "en" => 1,    /* English */
    "fr" => 1    /* French */
    );
    $default_language = "en";
    /* echo for testing, ought to have a loop here */
    echo ("Languages we support in this script = en, fr. Default language = $default_language. <p>");
    
    /* Try to figure out which language to use.
    */
    function negotiate_language() {
    global $supported_languages, $HTTP_ACCEPT_LANGUAGE, $default_language;
    
    /* If the client has sent an Accept-Language: header,
    * see if it is for a language we support.
    */
    if ($HTTP_ACCEPT_LANGUAGE) {
       $accepted = explode(",", $HTTP_ACCEPT_LANGUAGE);

       for ($i = 0; $i < count($accepted); $i++) {
	  if ($supported_languages[$accepted[$i]]) {
      return $accepted[$i];
      } 
       }
    }

    return $default_language;
  }
  ?>

  <? $chosen_language = (negotiate_language()); ?>
  Selected language ==&gt;: <? echo($chosen_language . "<p>"); ?>

  Result ==&gt; : 
  <? switch ($chosen_language) {
    case "fr":
       print "Ah bonjour !";
       break;
    case "en":
       print "Oh hello !";
       break;
   }
  ?>


    <hr>
    <ADDRESS>
      <A NAME="Signature"
     HREF="http://tecfa.unige.ch/tecfa-people/schneider.html">D.K.S.</A>
    </ADDRESS>
  </BODY>
</HTML>
