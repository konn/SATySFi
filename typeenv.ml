open Types

type t = (var_name * type_struct) list


let empty = []


let to_list tyenv = tyenv


let from_list lst = lst


let rec add tyenv (varnm : var_name) (tystr : type_struct) =
  match tyenv with
  | []                                -> (varnm, tystr) :: []
  | (vn, ts) :: tail  when vn = varnm -> (varnm, tystr) :: tail
  | (vn, ts) :: tail                  -> (vn, ts) :: (add tail varnm tystr)


let rec find (tyenv : t) (varnm : var_name) =
  match tyenv with
  | []                               -> raise Not_found
  | (vn, ts) :: tail when vn = varnm -> ts
  | (vn, ts) :: tail                 -> find tail varnm


let get_range_from_type (tystr : type_struct) =
  match tystr with
  | IntType(rng)              -> rng
  | StringType(rng)           -> rng
  | BoolType(rng)             -> rng
  | UnitType(rng)             -> rng
  | FuncType(rng, _, _)       -> rng
  | ListType(rng, _)          -> rng
  | RefType(rng, _)           -> rng
  | ProductType(rng, _)       -> rng
  | TypeVariable(rng, _)      -> rng
  | VariantType(rng, _, _)    -> rng
  | TypeSynonym(rng, _, _, _) -> rng
  | ForallType(_, _)          -> Range.dummy "forall"
  | TypeArgument(rng, _)      -> rng


let overwrite_range_of_type (tystr : type_struct) (rng : Range.t) =
  match tystr with
  | IntType(_)                              -> IntType(rng)
  | StringType(_)                           -> StringType(rng)
  | BoolType(_)                             -> BoolType(rng)
  | UnitType(_)                             -> UnitType(rng)
  | TypeVariable(_, tvid)                   -> TypeVariable(rng, tvid)
  | FuncType(_, tydom, tycod)               -> FuncType(rng, tydom, tycod)
  | ListType(_, tycont)                     -> ListType(rng, tycont)
  | RefType(_, tycont)                      -> RefType(rng, tycont)
  | ProductType(_, tylist)                  -> ProductType(rng, tylist)
  | VariantType(_, tyarglist, varntnm)      -> VariantType(rng, tyarglist, varntnm)
  | TypeSynonym(_, tyarglist, tynm, tycont) -> TypeSynonym(rng, tyarglist, tynm, tycont)
  | ForallType(tvid, tycont)                -> ForallType(tvid, tycont)
  | TypeArgument(_, tyarg)                  -> TypeArgument(rng, tyarg)


let rec erase_range_of_type (tystr : type_struct) =
  let dummy = Range.dummy "erased" in
  let f = erase_range_of_type in
    match tystr with
    | IntType(_)                              -> IntType(dummy)
    | StringType(_)                           -> StringType(dummy)
    | BoolType(_)                             -> BoolType(dummy)
    | UnitType(_)                             -> UnitType(dummy)
    | TypeVariable(_, tvid)                   -> TypeVariable(dummy, tvid)
    | FuncType(_, tydom, tycod)               -> FuncType(dummy, f tydom, f tycod)
    | ListType(_, tycont)                     -> ListType(dummy, f tycont)
    | RefType(_, tycont)                      -> RefType(dummy, f tycont)
    | ProductType(_, tylist)                  -> ProductType(dummy, List.map f tylist)
    | VariantType(_, tyarglist, varntnm)      -> VariantType(dummy, List.map f tyarglist, varntnm)
    | TypeSynonym(_, tyarglist, tynm, tycont) -> TypeSynonym(dummy, List.map f tyarglist, tynm, f tycont)
    | ForallType(tvid, tycont)                -> ForallType(tvid, f tycont)
    | TypeArgument(_, tyargnm)                -> TypeArgument(dummy, tyargnm)


let rec find_in_type_struct (tvid : Tyvarid.t) (tystr : type_struct) =
  match tystr with
  | TypeVariable(_, tvidx)            -> Tyvarid.same tvidx tvid
  | FuncType(_, tydom, tycod)         -> (find_in_type_struct tvid tydom) || (find_in_type_struct tvid tycod)
  | ListType(_, tycont)               -> find_in_type_struct tvid tycont
  | RefType(_, tycont)                -> find_in_type_struct tvid tycont
  | ProductType(_, tylist)            -> find_in_type_struct_list tvid tylist
  | VariantType(_, tylist, _)         -> find_in_type_struct_list tvid tylist
  | TypeSynonym(_, tylist, _, tycont) -> (find_in_type_struct_list tvid tylist) || (find_in_type_struct tvid tycont)
  | _                                 -> false

and find_in_type_struct_list (tvid : Tyvarid.t) (tystrlst : type_struct list) =
  match tystrlst with
  | []         -> false
  | ty :: tail -> if find_in_type_struct tvid ty then true else find_in_type_struct_list tvid tail


let rec find_in_type_environment (tvid : Tyvarid.t) (tyenv : t) =
  match tyenv with
  | []                 -> false
  | (_, tystr) :: tail ->
      if find_in_type_struct tvid tystr then true else find_in_type_environment tvid tail


let unbound_id_list : Tyvarid.t list ref = ref []


let rec listup_unbound_id (tystr : type_struct) (tyenv : t) =
  let f = (fun ty -> listup_unbound_id ty tyenv) in
    match tystr with
    | TypeVariable(_, tvid)     ->
        if find_in_type_environment tvid tyenv then ()
        else if List.mem tvid !unbound_id_list then ()
        else unbound_id_list := tvid :: !unbound_id_list
    | FuncType(_, tydom, tycod)         -> begin f tydom ; f tycod end
    | ListType(_, tycont)               -> f tycont
    | RefType(_, tycont)                -> f tycont
    | ProductType(_, tylist)            -> let _ = List.map f tylist in ()
    | VariantType(_, tylist, _)         -> let _ = List.map f tylist in ()
    | TypeSynonym(_, tylist, _, tycont) -> let _ = List.map f tylist in () (* doubtful implementation *)
    | _                                 -> ()


let rec add_forall_struct (lst : Tyvarid.t list) (tystr : type_struct) =
  match lst with
  | []           -> tystr
  | tvid :: tail ->
      if Tyvarid.is_quantifiable tvid then
        ForallType(tvid, add_forall_struct tail tystr)
      else
        add_forall_struct tail tystr


let make_forall_type (tystr : type_struct) (tyenv : t) =
  begin
    unbound_id_list := [] ;
    listup_unbound_id tystr tyenv ;
    add_forall_struct (!unbound_id_list) tystr
  end


let rec string_of_type_environment (tyenv : t) (msg : string) =
    "    #==== " ^ msg ^ " " ^ (String.make (58 - (String.length msg)) '=') ^ "\n"
  ^ (string_of_type_environment_sub tyenv)
  ^ "    #================================================================\n"

and string_of_type_environment_sub (tyenv : t) =
  match tyenv with
  | []               -> ""
  | (vn, ts) :: tail ->
          "    #  "
            ^ ( let len = String.length vn in if len >= 16 then vn else vn ^ (String.make (16 - len) ' ') )
            ^ " : " ^ ((* string_of_type_struct ts *) "type") ^ "\n" (* remains to be implemented *)
            ^ (string_of_type_environment_sub tail)


let rec string_of_control_sequence_type (tyenv : t) =
    "    #================================================================\n"
  ^ (string_of_control_sequence_type_sub tyenv)
  ^ "    #================================================================\n"

and string_of_control_sequence_type_sub (tyenv : t) =
  match tyenv with
  | []               -> ""
  | (vn, ts) :: tail ->
      ( match String.sub vn 0 1 with
        | "\\" ->
            "    #  "
              ^ ( let len = String.length vn in if len >= 16 then vn else vn ^ (String.make (16 - len) ' ') )
              ^ " : " ^ ((* string_of_type_struct ts *) "type") ^ "\n" (* remains to be implemented *)
        | _    -> ""
      ) ^ (string_of_control_sequence_type_sub tail)


let rec find_id_in_list (elm : Tyvarid.t) (lst : (Tyvarid.t * type_struct) list) =
  match lst with
  | []                                               -> raise Not_found
  | (tvid, tystr) :: tail when Tyvarid.same tvid elm -> tystr
  | _ :: tail                                        -> find_id_in_list elm tail


let rec make_bounded_free qtfbl (tystr : type_struct) = eliminate_forall qtfbl tystr []

and eliminate_forall qtfbl (tystr : type_struct) (lst : (Tyvarid.t * type_struct) list) =
  match tystr with
  | ForallType(tvid, tycont) ->
      let ntvstr = TypeVariable(Range.dummy "eliminate_forall", Tyvarid.fresh qtfbl) in
        eliminate_forall qtfbl tycont ((tvid, ntvstr) :: lst)

  | other ->
      let tyfree    = replace_id lst other in
      let tyqtf     = make_unquantifiable_if_needed qtfbl tyfree in
      let tyarglist = List.map (fun (tvid, ntvstr) -> ntvstr) lst in
        (tyqtf, tyarglist)

and make_unquantifiable_if_needed qtfbl tystr =
  let f = make_unquantifiable_if_needed qtfbl in
    match tystr with
    | TypeVariable(rng, tvid)                   ->
        begin
          match qtfbl with
          | Tyvarid.Quantifiable   -> TypeVariable(rng, tvid)
          | Tyvarid.Unquantifiable -> TypeVariable(rng, Tyvarid.set_quantifiability Tyvarid.Unquantifiable tvid)
        end
    | ListType(rng, tycont)                     -> ListType(rng, f tycont)
    | RefType(rng, tycont)                      -> RefType(rng, f tycont)
    | ProductType(rng, tylist)                  -> ProductType(rng, List.map f tylist)
    | FuncType(rng, tydom, tycod)               -> FuncType(rng, f tydom, f tycod)
    | VariantType(rng, tylist, varntnm)         -> VariantType(rng, List.map f tylist, varntnm)
    | TypeSynonym(rng, tylist, tysynnm, tycont) -> TypeSynonym(rng, List.map f tylist, tysynnm, f tycont)
    | ForallType(tvid, tycont)                  -> ForallType(tvid, f tycont)
    | other                                     -> other

and replace_id (lst : (Tyvarid.t * type_struct) list) (tystr : type_struct) =
  let f = replace_id lst in
    match tystr with
    | TypeVariable(rng, tvid)                   ->
        begin
          try find_id_in_list tvid lst with
          | Not_found -> TypeVariable(rng, tvid)
        end
    | ListType(rng, tycont)                     -> ListType(rng, f tycont)
    | RefType(rng, tycont)                      -> RefType(rng, f tycont)
    | ProductType(rng, tylist)                  -> ProductType(rng, List.map f tylist)
    | FuncType(rng, tydom, tycod)               -> FuncType(rng, f tydom, f tycod)
    | VariantType(rng, tylist, varntnm)         -> VariantType(rng, List.map f tylist, varntnm)
    | TypeSynonym(rng, tylist, tysynnm, tycont) -> TypeSynonym(rng, List.map f tylist, tysynnm, f tycont)
    | ForallType(tvid, tycont)                  ->
        begin
          try let _ = find_id_in_list tvid lst in ForallType(tvid, tycont) with
          | Not_found -> ForallType(tvid, f tycont)
        end
    | other                                     -> other
