
type file_path = string

exception InvalidYOJSON                of file_path * string
exception DumpFileOtherThanAssoc       of file_path
exception DumpFileValueOtherThanString of file_path * string * string

val initialize : file_path -> bool

type answer =
  | NeedsAnotherTrial
  | CanTerminate of string list
  | CountMax

val needs_another_trial : file_path -> answer

val register : string -> string -> unit

val probe : string -> string option

val get : string -> string option
