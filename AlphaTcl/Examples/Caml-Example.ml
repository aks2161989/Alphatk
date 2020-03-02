(* One hundred lines of Caml
 *
 * Contact the author Pierre.Weis@inria.fr
 *
 * Created in January 1996.
 *)

(* Elementary functions
 *
 * Using the interactive system, I define the square function, and the
 * recursive factorial function.  Then I try my new functions with some
 * examples:
 *)

(* > Caml Light version 0.74  *)

#let square (x) = x * x;;
square : int -> int = <fun>
#let rec fact (x) =
  if x <= 1 then 1 else x * fact (x - 1);;
fact : int -> int = <fun>
#fact (5);;
- : int = 120
#square (120);;
- : int = 14400

(* Automatic memory management
 *  
 * All allocation and deallocation operations are fully automatic.
 * I give the example of lists.
 *  
 * Lists are predefined in Caml, the empty list is [], and the list
 * constructor is denoted by :: (binary and infix). 
 *)

#let l = 1 :: 2 :: 3 :: [];;
l : int list = [1; 2; 3]
#[1; 2; 3];;
- : int list = [1; 2; 3]
#5 :: l;;
- : int list = [5; 1; 2; 3]

(* Polymorphism: sorting lists
 * 
 * Insertion sort is defined with two recursive routines, 
 * using pattern matching on lists.
 *)

#let rec sort = function
  | [] -> []
  | x :: l -> insert x (sort l)

and insert elem = function
 | [] -> [elem]
 | x :: l -> if elem < x then elem :: x :: l else x :: insert elem l;;
sort : 'a list -> 'a list = <fun>
insert : 'a -> 'a list -> 'a list = <fun>
#sort [2; 1; 0];;
- : int list = [0; 1; 2]
#sort ["yes"; "ok"; "sure"; "ya"; "yep"];;
- : string list = ["ok"; "sure"; "ya"; "yep"; "$yes"]

(* Imperative features
 * 
 * Polynoms being represented as arrays, I add two polynoms by first creating
 * the resulting polynom, and then filling its slots with two ``for'' loops.
 *)  

#let add_polynom p1 p2 =
 let result = make_vect (max (vect_length p1) (vect_length p2)) 0 in
 for i = 0 to vect_length p1 - 1 do result.(i) <- p1.(i) done;
 for i = 0 to vect_length p2 - 1 do result.(i) <- result.(i) + p2.(i) done;
 result;;
add_polynom : int vect -> int vect -> unit
#add_polynom [| 1; 2 |] [| 1; 2 |];;
- : int vect = [|2; 4|]

(* Accumulators are defined in Caml using updatable cells, named references. *)

ref init returns a new cell with initial contents init,
!cell returns the actual contents of cell, and 
cell := val updates cell with the value val. 

(* I define fact with an accumulator and a ``for'' loop: *)

#let fact n =
 let result = ref 1 in
 for i = 1 to n do
  result := i * !result
 done;
 !result;;
fact : int -> int = <fun>
#fact 5;;
- : int = $120

(* Functionality
 *
 * No restrictions on functions, that may be higher-order.  I define the sigma
 * function that returns the sum of results of applying a given function f to
 * each element of list:
 *)

#let rec sigma f = function
 | [] -> 0
 | x :: l -> f x + sigma f l;;
sigma : ('a -> int) -> 'a list -> int = <fun>

(* Temporary functions may be defined as no-name functional values with the
 * ``function'' construct: *)

#sigma (function x -> x * x) [1; 2; 3];;
- : int = 14

(* Combined with polymorphism, higher-order functionality allows the
 * definition of the functional composition of two functions. *)

#let compose f g = function x -> f (g (x));;
compose : ('a -> 'b) -> ('c -> 'a) -> 'c -> 'b = <fun>
#let square_o_fact = compose square fact;;
square_o_fact : int -> int = <fun>
#square_o_fact 5;;
- : int = 14400

(* Symbolic computation
 *
 * I consider simple symbolic expressions with integers, variables, let
 * bindings, and binary operators.  These symbolic expressions are defined as
 * a new data type, using a type definition:
 *)

#type expression =
 | Num of int
 | Var of string
 | Let of string * expression * expression
 | Binop of string * expression * expression;;
Type expression defined.

(* Symbolic evaluation of these expressions involves an environment which is
 *  just a list of pairs (identifier, value). *)

#let rec eval env = function
  | Num i -> i
  | Var x -> assoc x env
  | Let (x, e1, in_e2) ->
     let val_x = eval env e1 in
     eval ((x, val_x) :: env) in_e2
  | Binop (op, e1, e2) ->
     let v1 = eval env e1 in
     let v2 = eval env e2 in
     eval_op op v1 v2

and eval_op op v1 v2 =
 match op with
 | "+" -> v1 + v2
 | "-" -> v1 - v2
 | "*" -> v1 * v2
 | "/" -> v1 / v2
 | _ -> failwith ("Unknown operator: " ^ op);;
eval : (string * int) list -> expression -> int = <fun>
eval_op : string -> int -> int -> int = <fun>

(* As an example, we evaluate the phrase ``let x = 1 in x + x'':  *)

#eval [] (Let ("x", Num 1, Binop ("+", Var "x", Var "x")));;
- : int = 2

(*  In addition to data type definition, the pattern matching facility leads to
 *  an easy way of defining functions on symbolic data.  For instance, from the
 *  type definition of expressions:
 *)

type expression =
 | Num of int
 | Var of string
 | Let of string * expression * expression
 | Binop of string * expression * expression

(* we get the skeleton of the printing procedure for expression: *)

let print_expression = function
 | Num int ->
 | Var string ->
 | Let (string, expression1, expression2) ->
 | Binop (string, expression1, expression2) ->

(* We just have to complete the pattern matching clauses to get the printing
 * routine: *)

#let rec print_expression = function
 | Num int -> print_int int
 | Var string -> print_string string
 | Let (string, expression1, expression2) ->
    print_string "let "; print_string string; print_string " = ";
    print_expression expression1; print_string " in ";
    print_expression expression2
 | Binop (string, expression1, expression2) ->
    print_string "("; print_expression expression1;
    print_string (" "^string^" ");
    print_expression expression2; print_string ")";;
print_expression : expression -> unit = <fun>
#print_expression (Let ("x", Num 1, Binop ("+", Var "x", Var "x")));;
let x = 1 in (x + x)- : unit = ()

(* Parsing data
 *
 * Caml offers a rich panel of parsing tools: it includes traditional lex and
 * yacc interfaces, but also an original stream primitive data type, with its
 * associated ``functional parsing'' technology.
 
 * Writing a parser is always a bit technical, you may like to omit it. 
 * However, you can find a parser for the above expression data type.
 *)

(* Elementary debugging
 * 
 * Just for completeness, let me show you the simplest way to debug programs,
 * using the trace facility:
 *)

#let rec fib x = if x <= 1 then 1 else fib (x - 1) + fib (x - 2);;
fib : int -> int = <fun>
#trace "fib";;

(* The function fib is now traced. *)

- : unit = ()
#fib 3;;
fib <-- 3
fib <-- 1
fib --> 1
fib <-- 2
fib <-- 0
fib --> 1
fib <-- 1
fib --> 1
fib --> 2
fib --> 3
- : int = 3

(* More
 *
 * If you know the lambda calculus, click here to see a more significative
 * example of symbolic data manipulation using Caml: the definition of
 * lambda-terms with their associated lexical analyzer, parser and printer,
 * within about fifty lines of Caml code.
 *
 * Caml home page Last modified: Friday, March 27, 1998 
 * Copyright © 1995, 1996, 1997, 1998, 1999, 2000 INRIA all rights reserved. 
 *
 * Contact the author Pierre.Weis@inria.fr
 *)
