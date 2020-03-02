/* -*-Objc-*-
 * Gerrit Huizenga
 * HTML-ized by Michael Chui
 * 
 * source:  <http://www.cs.indiana.edu/classes/c304/ObjC.html>
 * 
 * An introduction to object oriented programming concepts is also
 * available.
 * 
 */

/*
In Objective-C, we describe the interface to a class using the
@interface declaration:
*/

@interface Stack : Object

/*
followed by the variables used to implement the object (these are
called the class's instance variables, and each instance of this class
has its own copy of these variables):
*/

{
  StackLink *top;
  unsigned int size;
}

/* 
Then we list the methods that this class implements (i.e. the messages
that objects of this class understand):
*/

- push: (int) anInt;

- (int) pop;

- (unsigned int) size;

/*
and finish up with the @end declaration:
*/

@end

/*
This would normally be stored in a header file called Stack.h. The
definitions for the superclass of the class you are subclassing are
imported at the beginning of the file.  An import uses the #import
directive which is similar to the #include directive, but ensures that
the file is only included by your file once.  With all of this in place
the file would look like this:
*/

Stack.h

#import < objc/Object.h>


@interface Stack : Object
{
  StackLink *top;
  unsigned int size;
}

- free;
- push: (int) anInt;
- (int) pop;
- (unsigned int) size;

@end

/*
Note that in the @interface declaration, we specify the class that this
class inherits from (its superclass).  The superclass of the Stack
class is the Object class (all classes are at least a subclass of the
Object class).

Method names always contain a colon (":") before any of the arguments
that are passed along in the message (e.g. push).

Any number of parameters may be sent in a message, each separated by a
keyword ending in a colon.  For example, if we wanted to be able to
push two integers onto the stack with one message, we could define the
method:
*/

- push: (int) first and: (int) second;

/*
The name of this method is "push:and:".

Parameters passed in the message are declared using the C "typecast"
notation.  Any type that is valid as a C function parameter is valid as
a method parameter.  The return type of a method is also specified
using the typecast notation.  If no return type is specified, then the
method is assumed to return a pointer to an object.

Implementation

We define the implementation of a class (in a separate file from the
interface) using the @implementation directive:
*/

@implementation Stack

/*
Objective-C is just like normal ANSI C (as implemented by the GNU C
compiler), except that it provides the ability to define classes,
create instances of objects, and send messages to objects.  Two new
fundamental types are added to the language:

id 
     pointer to an object 
SEL 
     a message (we sometimes call messages selectors, thus the abbreviation). 

Both variables of type id and type SEL are valid parameters that can be
send in messages or passed to a C function.

Messages are sent using a Smalltalk-like syntax:
*/

id s;
int i;

s = [Stack new];  // Send the message "new" to the factory object "Stack"
[s push:34];      // Send the message "push" with the argument 34 to s.
i = [s pop];      // Send the message "pop" to the object s.

/*
In the implementation of a class, methods can manipulate the class'
instance variables (e.g. the linked list pointed to by top in the Stack
class), can generally do anything normally allowed in C, and can send
messages to objects.

What objects can an object send messages to?

     itself (this is very common) 
     itself, but use its superclass' implementation! 
     objects pointed to by one of its instance variables (i.e. instance variables of type id). 
     objects passed to it as a parameter in a message sent to it by some other object 
     factory objects (factory objects are sometimes known as class objects) 

How does an object send a message to itself? Here is an example:
*/

[self push:34.0];

/*
self is a special variable which is a pointer to the object which
received the message which invoked the currently executing method(!).
In other words, it is the receiver of the message.

Example: Remember push:and:?  Here is probably how that method would be
implemented:
*/

- push: (int) first and: (int) second
{
  [self push: first];
  [self push: second];
  return self;
}

/*
Notice that the push:and: method returns self.  Remember that if a
method does not specify the type of its return value, the default is to
return a pointer to an object (i.e. something of type id).  This means
that, barring any other sensible thing to return, methods should always
return self!

How can an object send a message to itself but use its superclass'
implementation?  And why would someone ever want to do that?

Why?  Because in the implementation of a method which is overridden
(i.e. the superclass implements it, and the subclass implements it
differently, a class might want (and often does want)to perform its
superclass' implementation as part of its own implementation.

How?  Any message an object sends to the pseudo-variable super will
cause its superclass' implementation of the method to be performed.

An object can send a message to super in any method.  super implicitly
means " self, but use superclass' implementation."

There is one and only one factory object per class.  There is a global
id variable which points to it, and that variable's name is the same as
the class' name.  You send messages to it to create new instances of
that class or to query class-specific (as opposed to instance-specific)
information.

Example:
*/

id s;

s = [Stack new];

/*
In this case, we are sending the message new to the factory object
Stack.  This factory object will return an object of type Stack.

The file which contains the implementation of a class ends with the
@end directive (just like the interface file does).
*/

Stack.m

@implementation Stack

- free
{
  StackLink *next;

  while (top != (StackLink *) 0)
    {
      next = top->next;
      free ((char *) top);
      top = next;
    }
  return [super free];
}

/* other methods */

@end

/*
Factory Objects

Objective-C automatically creates a factory object for each class used
in an application.

	  Exactly one instance of a factory object exists at runtime.  The
	  name of the factory object is the same as the name of the class.

The primary purpose of a factory object is to provide a mechanism to
create instances of the class:
*/

id myStack

myStack = [Stack new];

/*
Factory objects respond to factory methods.

Factory methods are indicated by a "+" preceding the name when declared
and defined.
*/

+ new
{
  self = [super new];
  top = (StackLink *) 0;
  return self;
}

/*
Factory objects are not instances of the class and therefore do not
have access to the instance variables associated with an instance of
the class, so factory methods typically redefine self before accessing
instances variables.

Here are the interface and implementation files for the Stack class in
their entirety:
*/

Stack.h

#import < objc/Object.h>


@interface Stack : Object
{
  StackLink *top;
  unsigned int size;
}

- free;
- push: (int) anInt;
- (int) pop;
- (unsigned int) size;

@end

Stack.m

#import "Stack.h"

@implementation Stack

#define NULL_LINK (StackLink *) 0

+ new
{
  self = [super new];
  top = (StackLink *) 0;
  return self;
}

- free
{
  StackLink *next;

  while (top != NULL_LINK)
    {
      next = top->next;
      free ((char *) top);
      top = next;
    }
  return [super free];
}

- push: (int) value
{
  StackLink *newLink;

  newLink = (StackLink *) malloc (sizeof (StackLink));
  if (newLink == 0)
    {
      fprintf(stderr, "Out of memory\n");
      return nil;
    }
  newLink->data = value;
  newLink->next = top;
  top = newLink;
  size++;

  return self;
}

- (int) pop
{
  int value;
  StackLink *topLink;

  if (0 != size)
    {
      topLink = top;
      top = top->next;
      value = topLink->data;
      free (topLink);
      size--;
    }
  else
    {
      value = 0;
    }
  return value;
}

- (unsigned int) size
{
  return size;
}

@end

/*
Go back to the index of sources for information about object oriented
programming in Objective-C.
*/


