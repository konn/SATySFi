
open Types_

exception ExecError of string

val exec : syntactic_value list -> vmenv -> instruction list -> (vmenv * instruction list) list -> syntactic_value
