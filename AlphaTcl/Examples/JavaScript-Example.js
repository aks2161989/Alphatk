// Java-Example.java
// 
// Included in the Alpha distribution as an example of the JScr mode.
// 
// Source of original document:
// 
// http://www.npac.syr.edu/projects/tutorials/JavaScript/examples/

<HTML>

<HEAD>
<TITLE>JavaScript Example:  Array Sort</TITLE>

<SCRIPT LANGUAGE="JavaScript">
<!-- hide script from old browsers

president = new Array(10);
president[0] = "Washington";
president[1] = "Adams";
president[2] = "Jefferson";
president[3] = "Madison";
president[4] = "Monroe";
president[5] = "Adams";
president[6] = "Jackson";
president[7] = "Van Buren";
president[8] = "Harrison";
president[9] = "Tyler";

// Returns -1,0,1 if the first string is lexicographically 
// less than, equal to, or greater than the second string,
// respectively:
function compareStrings(a, b) {
  if ( a < b ) return -1;
  if ( a > b ) return 1;
  return 0;
}

// Return -1,0,1 if the first string is shorter than, equal to
// (in length), or longer than the second string, respectively:
function compareStringLength(a, b) {
  if ( a.length < b.length ) return -1;
  if ( a.length > b.length ) return 1;
  return 0;
}

// Sort and display array:
function sortIt(form, compFunc) {
  var separator = ";";
  if ( compFunc == null ) {
    president.sort();     // lexicographical sort, by default
  } else {
    president.sort(compFunc);  // use comparison function
  }
  // display results
  form.output.value = president.join(separator);
}

// end script hiding -->
</SCRIPT>

</HEAD>

<BODY BGCOLOR="#FFFFFF"
      onLoad="document.forms[0].output.value = president.join(';')">

<H2>An array of character strings</H2>

Listed below are the first ten Presidents of the United States. <P>

<FORM>
<INPUT TYPE="text" NAME="output" SIZE=100> <P>
Click on a button to sort the array: <P>
<INPUT TYPE="button" VALUE="Alphabetical" 
       onClick="sortIt(this.form, compareStrings)">
<INPUT TYPE="button" VALUE="Name Length" 
       onClick="sortIt(this.form, compareStringLength)">
<INPUT TYPE="button" VALUE="Chronological" 
       onClick="self.location.reload()">
</FORM>

<P> <HR> Note:
<OL>
  <LI>Alphabetical: uses JavaScript sort() default method on text strings
  <LI>Name Length: uses user-defined comparison function
  <LI>Chronological: reloads original array
</OL>

</BODY>
 </HTML>

