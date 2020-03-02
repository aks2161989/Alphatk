-- Ada-Example.ada
-- 
-- Included in the Alpha distribution as an example of the Ada mode

-- Source of original document:
-- 
-- http://gserver.grads.vt.edu/cgi.adb


with Ada.Strings.Unbounded;  use  Ada.Strings.Unbounded;

package CGI is
-- This package is an Ada 95 interface to the "Common Gateway Interface" (CGI).
-- This package makes it easier to create Ada programs that can be
-- invoked by World-Wide-Web HTTP servers using the standard CGI interface.
-- CGI is rarely referred to by its full name, so the package name is short.
-- General information on CGI is available at "http://hoohoo.ncsa.uiuc.edu/cgi/".

-- Developed by (C) David A. Wheeler (wheeler@ida.org) June 1995.
-- This is version 1.0.

-- This was inspired by a perl binding by Steven E. Brenner at
--   "http://www.bio.cam.ac.uk/web/form.html"
-- and another perl binding by L. Stein at
--   "http://www-genome.wi.mit.edu/ftp/pub/software/WWW/cgi_docs.html"
-- A different method for interfacing binding Ada with CGI is to use the
-- "Un-CGI" interface at "http://www.hyperion.com/~koreth/uncgi.html".

-- This package automatically loads information from CGI on program start-up.
-- It loads information sent from "Get" or "Post" methods and automatically
-- splits the data into a set of variables that can be accessed by position or
-- by name.  An "Isindex" request is translated into a request with a single
-- key named "isindex" with its Value as the query value.

-- This package provides two data access methods:
-- 1) As an associative array; simply provide the key name and the
--    value associated with that key will be returned.
-- 2) As a sequence of key-value pairs, indexed from 1 to Argument_Count.
--    This is similar to Ada library Ada.Command_Line.
-- The main access routines support both String and Unbounded_String.

-- See the documentation file for more information and sample programs.

function Parsing_Errors return Boolean;  -- True if Error on Parse.
function Input_Received return Boolean;  -- True if Input Received.
function Is_Index       return Boolean;  -- True if an Isindex request made.
  -- An "Isindex" request is turned into a Key of "isindex" at position 1,
  -- with Value(1) as the actual query.

type CGI_Method_Type is (Get, Post, Unknown);

function CGI_Method return CGI_Method_Type;  -- True if Get_Method used.

-- Access data as an associative array - given a key, return its value.
-- The Key value is case-sensitive.
-- If a key is required but not present, raise Constraint_Error;
-- otherwise a missing key's value is considered to be "".
-- These routines find the Index'th value of that key (normally the first one).
function Value(Key : in Unbounded_String; Index : in Positive := 1;
               Required : in Boolean := False) return Unbounded_String;
function Value(Key : in String; Index : in Positive := 1;
               Required : in Boolean := False) return String;
function Value(Key : in Unbounded_String; Index : in Positive := 1;
              Required : in Boolean := False) return String;
function Value(Key : in String; Index : in Positive := 1;
               Required : in Boolean := False) return Unbounded_String;

-- Was a given key provided?
function Key_Exists(Key : in String; Index : in Positive := 1) return Boolean;
function Key_Exists(Key : in Unbounded_String; Index : in Positive := 1)
         return Boolean;

-- How many of a given key were provided?
function Key_Count(Key : in String) return Natural;
function Key_Count(Key : in Unbounded_String) return Natural;


-- Access data as an ordered list (it was sent as Key=Value);
-- Keys and Values may be retrieved from Position (1 .. Argument_Count).
-- Constraint_Error will be raised if (Position < 1 or Position > Argument_Count)
function Argument_Count return Natural;          -- 0 means no data sent.
function Key(Position : in Positive) return Unbounded_String;
function Key(Position : in Positive) return String;
function Value(Position : in Positive) return Unbounded_String;
function Value(Position : in Positive) return String;

-- The following are helpful subprograms to simplify use of CGI.

function My_URL return String; -- Returns the URL of this script.

procedure Put_CGI_Header(Header : in String := "Content-type: text/html");
-- Put CGI Header to Current_Output, followed by two carriage returns.
-- This header determines what the program's reply type is.
-- Default is to return a generated HTML document.

procedure Put_HTML_Head(Title : in String; Mail_To : in String := "");
-- Puts to Current_Output an HTML header with title "Title".  This is:
--   <HTML><HEAD><TITLE> _Title_ </TITLE>
--   <LINK REV="made" HREF="mailto:  _Mail_To_ ">
--   </HEAD><BODY>
-- If Mail_To is omitted, the "made" reverse link is omitted.

procedure Put_HTML_Heading(Title : in String; Level : in Positive);
-- Put an HTML heading at the given level with the given text.
-- If level=1, this puts:  <H1>Title</H1>.

procedure Put_HTML_Tail;
-- This is called at the end of an HTML document. It puts to Current_Output:
--   </BODY></HTML>

procedure Put_Error_Message(Message : in String);
-- Put to Current_Output an error message.
-- This Puts an HTML_Head, an HTML_Heading, and an HTML_Tail.
-- Call "Put_CGI_Header" before calling this.

procedure Put_Variables;
-- Put to Current_Output all of the CGI variables as an HTML-formatted String.

function Line_Count (Value : in String) return Natural;
-- Given a value that may have multiple lines, count the lines.
-- Returns 0 if Value is the empty/null string (i.e., length=0)
 
function Line_Count_of_Value (Key : String) return Natural;
-- Given a Key which has a Value that may have multiple lines,
-- count the lines.  Returns 0 if Key's Value is the empty/null
-- string (i.e., length=0) or if there's no such Key.
-- This is the same as Line_Count(Value(Key)).

function Line (Value : in String; Position : in Positive)
               return String;
-- Given a value that may have multiple lines, return the given line.
-- If there's no such line, raise Constraint_Error.

function Value_of_Line (Key : String; Position : Positive)
                        return String;
-- Given a Key which has a Value that may have multiple lines,
-- return the given line.  If there's no such line, raise Constraint_Error.
-- If there's no such Key, return the null string.
-- This is the same as Line(Value(Key), Position).

function Get_Environment(Variable : in String) return String;
-- Return the given environment variable's value.
-- Returns "" if the variable does not exist.

end CGI;




with Ada.Strings.Maps, Ada.Characters.Handling, Interfaces.C.Strings, Text_IO;
use  Ada.Strings.Maps, Ada.Characters.Handling, Interfaces.C.Strings, Text_IO;

package body CGI is
-- This package is an Ada 95 interface to the "Common Gateway Interface" (CGI).
-- This package makes it easier to create Ada programs that can be
-- invoked by HTTP servers using CGI.

-- Developed by David A. Wheeler, wheeler@ida.org, (C) June 1995.


-- The following are key types and constants.

type Key_Value_Pair is record
   Key, Value : Unbounded_String;
   end record;

type Key_Value_Sequence is array(Positive range <>) of Key_Value_Pair;
type Access_Key_Value_Sequence is access Key_Value_Sequence;


Ampersands :    constant Character_Set      := To_Set('&');
Equals     :    constant Character_Set      := To_Set('=');
Plus_To_Space : constant Character_Mapping  := To_Mapping("+", " ");



-- The following are data internal to this package.

Parsing_Errors_Occurred : Boolean := True;
Is_Index_Request_Made   : Boolean := False; -- Isindex request made?

CGI_Data : Access_Key_Value_Sequence; -- Initially nil.

Actual_CGI_Method : CGI_Method_Type := Get;


-- The following are private "Helper" subprograms.

function Value_Without_Exception(S : chars_ptr) return String is
-- Translate S from a C-style char* into an Ada String.
-- If S is Null_Ptr, return "", don't raise an exception.
begin
  if S = Null_Ptr then return "";
  else return Value(S);
  end if;
end Value_Without_Exception;
pragma Inline(Value_Without_Exception);


function Image(N : Natural) return String is
-- Convert Positive N to a string representation.  This is just like
-- Ada 'Image, but it doesn't put a space in front of it.
 Result : String := Natural'Image(N);
begin
 return Result( 2 .. Result'Length);
end Image;


function Field_End(Data: Unbounded_String; Field_Separator: Character;
               Starting_At : Positive := 1) return Natural is
-- Return the end-of-field position in Data after "Starting_Index",
-- assuming that fields are separated by the Field_Separator.
-- If there's no Field_Separator, return the end of the Data.
begin
  for I in Starting_At .. Length(Data) loop
    if Element(Data, I) = Field_Separator then return I-1; end if;
  end loop; 
  return Length(Data);
end Field_End;


function Hex_Value(H : in String) return Natural is
 -- Given hex string, return its Value as a Natural.
 Value : Natural := 0;
begin
 for P in 1.. H'Length loop
   Value := Value * 16;
   if H(P) in '0' .. '9' then Value := Value + Character'Pos(H(P)) -
                                               Character'Pos('0');
   elsif H(P) in 'A' .. 'F' then Value := Value + Character'Pos(H(P)) -
                                               Character'Pos('A') + 10;
   elsif H(P) in 'a' .. 'f' then Value := Value + Character'Pos(H(P)) -
                                               Character'Pos('a') + 10;
   else raise Constraint_Error;
   end if;
 end loop;
 return Value;
end Hex_Value;


procedure Decode(Data : in out Unbounded_String) is
 I : Positive := 1;
-- In the given string, convert pattern %HH into alphanumeric characters,
-- where HH is a hex number. Since this encoding only permits values
-- from %00 to %FF, there's no need to handle 16-bit characters.
begin
 while I <= Length(Data) - 2 loop
   if Element(Data, I) = '%' and Is_Hexadecimal_Digit(Element(Data, I+1)) and
      Is_Hexadecimal_Digit(Element(Data, I+2)) then
       Replace_Element(Data, I, Character'Val(Hex_Value(Slice(Data, I+1, I+2))));
       Delete(Data, I+1, I+2);
   end if;
   I := I + 1;
 end loop;
end Decode;




-- The following are public subprograms.


function Get_Environment(Variable : String) return String is
-- Return the value of the given environment variable.
-- If there's no such environment variable, return an empty string.

  function getenv(Variable : chars_ptr) return chars_ptr;
  pragma Import(C, getenv);
  -- getenv is a standard C library function; see K&R 2, 1988, page 253.
  -- it returns a pointer to the first character; do NOT free its results.

  Variable_In_C_Format : chars_ptr := New_String(Variable);
  Result_Ptr : chars_ptr := getenv(Variable_In_C_Format);
  Result : String := Value_Without_Exception(Result_Ptr);
begin
 Free(Variable_In_C_Format);
 return Result;
end Get_Environment;


function Parsing_Errors return Boolean is
begin
 return Parsing_Errors_Occurred;
end Parsing_Errors;


function Argument_Count return Natural is
begin
  if CGI_Data = null then return 0;
  else                   return CGI_Data.all'Length;
  end if;
end Argument_Count;


function Input_Received return Boolean is
  -- True if Input Received.
begin
  return Argument_Count /= 0; -- Input received if nonzero data entries.
end Input_Received;


function CGI_Method return CGI_Method_Type is
  -- Return Method used to send data.
begin
  return Actual_CGI_Method;
end CGI_Method;


function Is_Index return Boolean is
begin
  return Is_Index_Request_Made;
end Is_Index;


function Value(Key : in Unbounded_String; Index : in Positive := 1;
               Required : in Boolean := False)
         return Unbounded_String is
 My_Index : Positive := 1;
begin
 for I in 1 .. Argument_Count loop
   if CGI_Data.all(I).Key = Key then
      if Index = My_Index then
        return CGI_Data.all(I).Value;
      else
        My_Index := My_Index + 1;
      end if;
   end if;
 end loop;
 -- Didn't find the Key.
 if Required then
   raise Constraint_Error;
 else
   return To_Unbounded_String("");
 end if;
end Value;


function Value(Key : in String; Index : in Positive := 1;
               Required : in Boolean := False)
         return String is
begin
  return To_String(Value(To_Unbounded_String(Key), Index, Required));
end Value;


function Value(Key : in String; Index : in Positive := 1;
               Required : in Boolean := False)
         return Unbounded_String is
begin
  return Value(To_Unbounded_String(Key), Index, Required);
end Value;


function Value(Key : in Unbounded_String; Index : in Positive := 1;
               Required : in Boolean := False)
         return String is
begin
  return To_String(Value(Key, Index, Required));
end Value;


function Key_Exists(Key : in Unbounded_String; Index : in Positive := 1)
         return Boolean is
 My_Index : Positive := 1;
begin
 for I in 1 .. Argument_Count loop
   if CGI_Data.all(I).Key = Key then
      if Index = My_Index then
        return True;
      else
        My_Index := My_Index + 1;
      end if;
   end if;
 end loop;
 return False;
end Key_Exists;

function Key_Exists(Key : in String; Index : in Positive := 1) return Boolean is
begin
 return Key_Exists(To_Unbounded_String(Key), Index);
end Key_Exists;

function Key_Count(Key : in Unbounded_String) return Natural is
 Count : Natural := 0;
begin
 for I in 1 .. Argument_Count loop
   if CGI_Data.all(I).Key = Key then
        Count := Count + 1;
   end if;
 end loop;
 return Count;
end Key_Count;

function Key_Count(Key : in String) return Natural is
begin
  return Key_Count(To_Unbounded_String(Key));
end Key_Count;

function Key(Position : in Positive) return Unbounded_String is
begin
 return CGI_Data.all(Position).Key;
end Key;


function Key(Position : in Positive) return String is
begin
 return To_String(Key(Position));
end Key;


function Value(Position : in Positive) return Unbounded_String is
begin
 return CGI_Data.all(Position).Value;
end Value;


function Value(Position : in Positive) return String is
begin
 return To_String(Value(Position));
end Value;


function My_URL return String is
 -- Returns the URL of this script.
begin
  return "http://" & Get_Environment("SERVER_NAME") &
          Get_Environment("SCRIPT_NAME");
end My_URL;


procedure Put_CGI_Header(Header : in String := "Content-type: text/html") is
-- Put Header to Current_Output, followed by two carriage returns.
-- Default is to return a generated HTML document.
begin
  Put_Line(Header);
  New_Line;
end Put_CGI_Header;


procedure Put_HTML_Head(Title : in String; Mail_To : in String := "") is
begin
  Put_Line("<HTML><HEAD><TITLE>" & Title & "</TITLE>");
  if Mail_To /= "" then
    Put_Line("<LINK REV=""made"" HREF=""mailto:" &  Mail_To  & """>");
  end if;
  Put_Line("</HEAD><BODY>");
end Put_HTML_Head;


procedure Put_HTML_Heading(Title : in String; Level : in Positive) is
-- Put an HTML heading, such as <H1>Title</H1>
begin
  Put_Line("<H" & Image(Level) & ">" & Title & "</H" & Image(Level) & ">");
end Put_HTML_Heading;
 

procedure Put_HTML_Tail is
begin
  Put_Line("</BODY></HTML>");
end Put_HTML_Tail;


procedure Put_Error_Message(Message : in String) is
-- Put to Current_Output an error message.
begin
  Put_HTML_Head("Fatal Error Encountered by Script " & My_URL);
  Put_HTML_Heading("Fatal Error: " & Message, 1);
  Put_HTML_Tail;
  New_Line;
end Put_Error_Message;


procedure Put_Variables is
-- Put to Current_Output all of the data as an HTML-formatted String.
begin
 for I in 1 .. Argument_Count loop
   Put("<B>");
   Put(To_String(CGI_Data.all(I).Key));
   Put("</B> is <I>");
   Put(To_String(CGI_Data.all(I).Value));
   Put_Line("</I><BR>");
 end loop;
end Put_Variables;



-- Helper routine -
 
function Next_CRLF (S : in String; N : in Natural)
         return Natural
-- Return the location within the string of the next CRLF sequence
-- beginning with the Nth character within the string S;
-- return 0 if the next CRLF sequence is not in the string
is
   I : Natural := N;
begin
   while I < S'LAST loop
      if S(I) = ASCII.CR  and then  S(I+1) = ASCII.LF then
         return I;
      else
         I := I + 1;
      end if;
   end loop;
   return 0;
end;
 
 
 
function Line_Count (Value : in String) return Natural
-- Count the number of lines inside the given string.
-- returns 0 if Key_Value is the empty/null string,
-- i.e., if its length is zero; otherwise, returns
-- the number of "lines" in Key_Value, effectively
-- returning the number of CRLF sequences + 1;
-- for example, both "AB/CDEF//GHI" and "AB/CDEF//"
-- (where / is CRLF) return Line_Count of 4.
is
   Number_of_Lines : Natural := 0;
   I : Natural := Value'FIRST;
begin
   if Value'LENGTH = 0 then
      return 0;
   else
      loop
         I := Next_CRLF (Value, I+1);
      exit when I = 0;
         Number_of_Lines := Number_of_Lines + 1;
      end loop;
      -- Always count the line (either non-null or null) after
      -- the last CRLF as a line
      Number_of_Lines := Number_of_Lines + 1;
      return Number_of_Lines;
   end if;
end;
 

function Line (Value : in String; Position : in Positive)
               return String
-- Return the given line position value.
-- that is separated by the n-1 and the nth CRLF sequence
-- or if there is no nth CRLF sequence, then returns the line
-- delimited by the n-1 CRLF and the end of the string
 
is
   Next : Natural := 1;
   Line_Number : Natural := 0;
   Start_of_Line, End_of_Line : Natural;
begin
   End_of_Line := Next_CRLF (Value, 1);
   if End_of_Line = 0 then
      -- no CRLF sequence on the "line"
      if Position > 1 then
         -- raise an exception if requesting > 1
         raise Constraint_Error;
      else
         -- otherwise, requesting first line
         -- return original string, even if null string
         return Value;
      end if;
   else
      -- There's at least one CRLF on the "line"
      for I in 1..Position loop
         Start_of_Line := Next;
         End_of_Line := Next_CRLF (Value, Next);
         -- normally, the line is Start_of_Line .. End_of_Line-1
         -- if no more CRLFs on line, it's Start_of_Line .. 'LAST
         exit when End_of_Line = 0;
         Line_Number := Line_Number + 1;
         -- skip past the 2 chars, CRLF, to start next search
         Next := End_of_Line + 2;
      end loop;
      -- if we fall out of loop normally, End_of_Line is non-zero
      if End_of_Line > 0 then
         -- and Position had better be equal to Line_Number
         if Position = Line_Number then
            return Value (Start_of_Line .. End_of_Line-1);
         else
            raise Constraint_Error;
         end if;
      else
         -- we exit the loop prematurely because there's not
         -- enough CRLFs in the line,
         -- thus Line_Number is one less than Position
         if Position = Line_Number+1 then
            return Value (Start_of_Line .. Value'LAST);
         else
            raise Constraint_Error;
         end if;
      end if;
 end if;
end Line;
 

function Line_Count_of_Value (Key : String) return Natural is
begin
   if Key_Exists (Key) then
      return Line_Count (Value(Key));
   else
      return 0;
   end if;
end Line_Count_of_Value;


function Value_of_Line (Key : String; Position : Positive) return String is
begin
   if Key_Exists (Key) then
      return Line (Value(Key), Position);
   else
      return "";
   end if;
end Value_of_Line;



-- Initialization routines, including some private procedures only
-- used during initialization.

procedure Set_CGI_Position(Key_Number : in Positive;
                           Datum : in Unbounded_String) is
  Last : Natural := Field_End(Datum, '=');
-- Given a Key number and a datum of the form key=value
-- assign the CGI_Data(Key_Number) the values of key and value.
begin
  CGI_Data.all(Key_Number).Key   := To_Unbounded_String(Slice(Datum, 1, Last));
  CGI_Data.all(Key_Number).Value := To_Unbounded_String(Slice(Datum,
                                                      Last+2, Length(Datum)));
  Decode(CGI_Data.all(Key_Number).Key);
  Decode(CGI_Data.all(Key_Number).Value);
end Set_CGI_Position;


procedure Set_CGI_Data(Raw_Data : in Unbounded_String) is
-- Set CGI_Data using Raw_Data.
  Key_Number : Positive := 1;
  Character_Position : Positive := 1;
  Last : Natural;
begin
 while Character_Position <= Length(Raw_Data) loop
   Last := Field_End(Raw_Data, '&', Character_Position);
   Set_CGI_Position(Key_Number, To_Unbounded_String(
                       Slice(Raw_Data, Character_Position, Last)));
   Character_Position := Last + 2; -- Skip over field separator.
   Key_Number := Key_Number + 1;
 end loop;
end Set_CGI_Data;


procedure Initialize is
  Raw_Data : Unbounded_String;  -- Initially an empty string (LRM A.4.5(73))
  Request_Method_Text : String := To_Upper(Get_Environment("REQUEST_METHOD"));
  -- Initialize this package, most importantly the CGI_Data variable.
begin
 if Request_Method_Text = "GET" then
    Actual_CGI_Method := Get;
    Raw_Data := To_Unbounded_String(Get_Environment("QUERY_STRING"));
 elsif Request_Method_Text = "POST" then
    Actual_CGI_Method := Post;
    declare
      Raw_Data_String : String(1 ..
                         Integer'Value(Get_Environment("CONTENT_LENGTH")));
    begin
      Get(Raw_Data_String);
      Raw_Data := To_Unbounded_String(Raw_Data_String);
    end;
 else
    Actual_CGI_Method := Unknown;
 end if;

 Translate(Raw_Data, Mapping => Plus_To_Space); -- Convert "+"s to spaces.

 if Length(Raw_Data) > 0 then
   if Index(Raw_Data, Equals) = 0 then
     -- No "=" found, so this is an "Isindex" request.
     Is_Index_Request_Made := True;
     Raw_Data := "isindex=" & Raw_Data;
   end if;
   CGI_Data := new Key_Value_Sequence(1 .. 
                   Ada.Strings.Unbounded.Count(Raw_Data, Ampersands)+1);
   Set_CGI_Data(Raw_Data); 
   Parsing_Errors_Occurred := False;
 end if;

end Initialize;


-- This library automatically parses CGI input on program start.
begin
  Initialize;
end CGI;

