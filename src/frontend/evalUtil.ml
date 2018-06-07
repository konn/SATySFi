
module Types = Types_
open LengthInterface
open Types


let report_bug_vm msg =
  Format.printf "[Bug]@ %s:" msg;
  failwith ("bug: " ^ msg)


let report_bug_ast msg ast =
  Format.printf "[Bug]@ %s:" msg;
  Format.printf "%a" pp_abstract_tree ast;
  failwith ("bug: " ^ msg)


let report_bug_value msg value =
  Format.printf "[Bug]@ %s:" msg;
  Format.printf "%a" pp_syntactic_value value;
  failwith ("bug: " ^ msg)


let report_bug_reduction msg ast value =
  Format.printf "[Bug]@ %s:" msg;
  Format.printf "%a@ --->*@ %a" pp_abstract_tree ast pp_syntactic_value value;
  failwith ("bug: " ^ msg)


let chop_space_indent s =
  let imax = String.length s in
  let rec aux i s =
    if i >= imax then
      (i, "")
    else
      match String.get s i with
      | ' ' -> aux (i + 1) s
      | _   -> (i, String.sub s i (imax - i))
  in
  try
    aux 0 s
  with
  | Invalid_argument(_) -> assert false


let get_string (value : syntactic_value) : string =
  match value with
  | StringEmpty       -> ""
  | StringConstant(s) -> s
  | _                 -> report_bug_value "get_string" value


let get_list getf value =
  let rec aux acc value =
    match value with
    | ListCons(vhead, vtail) -> aux (Alist.extend acc (getf vhead)) vtail
    | EndOfList              -> Alist.to_list acc
    | _                      -> report_bug_value "get_list" value
  in
    aux Alist.empty value


let graphics_of_list value : (HorzBox.intermediate_horz_box list) Graphics.t =
  let rec aux gracc value =
    match value with
    | EndOfList                             -> gracc
    | ListCons(GraphicsValue(grelem), tail) -> aux (Graphics.extend gracc grelem) tail
    | _                                     -> report_bug_value "make_frame_deco" value
  in
    aux Graphics.empty value


let get_paddings (value : syntactic_value) =
  match value with
  | TupleCons(LengthConstant(lenL),
              TupleCons(LengthConstant(lenR),
                        TupleCons(LengthConstant(lenT),
                                  TupleCons(LengthConstant(lenB), EndOfTuple)))) ->
    {
      HorzBox.paddingL = lenL;
      HorzBox.paddingR = lenR;
      HorzBox.paddingT = lenT;
      HorzBox.paddingB = lenB;
    }

  | _ -> report_bug_value "interpret_paddings" value


let get_cell value : HorzBox.cell =
    match value with
    | Constructor("NormalCell", TupleCons(valuepads,
                                  TupleCons(Horz(hblst), EndOfTuple))) ->
        let pads = get_paddings valuepads in
          HorzBox.NormalCell(pads, hblst)

    | Constructor("EmptyCell", UnitConstant) -> HorzBox.EmptyCell

    | Constructor("MultiCell", TupleCons(IntegerConstant(nr),
                                 TupleCons(IntegerConstant(nc),
                                   TupleCons(valuepads,
                                     TupleCons(Horz(hblst), EndOfTuple))))) ->
        let pads = get_paddings valuepads in
          HorzBox.MultiCell(nr, nc, pads, hblst)

    | _ -> report_bug_value "get_cell" value


let get_color (value : syntactic_value) : GraphicData.color =
  let open GraphicData in
    match value with
    | Constructor("Gray", FloatConstant(gray)) -> DeviceGray(gray)

    | Constructor("RGB", TupleCons(FloatConstant(fltR),
                                   TupleCons(FloatConstant(fltG),
                                             TupleCons(FloatConstant(fltB), EndOfTuple)))) -> DeviceRGB(fltR, fltG, fltB)

    | Constructor("CMYK", TupleCons(FloatConstant(fltC),
                                    TupleCons(FloatConstant(fltM),
                                              TupleCons(FloatConstant(fltY),
                                                        TupleCons(FloatConstant(fltK), EndOfTuple))))) -> DeviceCMYK(fltC, fltM, fltY, fltK)

    | _ -> report_bug_value "interpret_color" value


let make_color_value color =
  let open GraphicData in
    match color with
    | DeviceGray(gray) ->
        Constructor("Gray", FloatConstant(gray))

    | DeviceRGB(r, g, b) ->
        Constructor("RGB", TupleCons(FloatConstant(r),
                             TupleCons(FloatConstant(g),
                               TupleCons(FloatConstant(b), EndOfTuple))))

    | DeviceCMYK(c, m, y, k) ->
        Constructor("CMYK", TupleCons(FloatConstant(c),
                              TupleCons(FloatConstant(m),
                                TupleCons(FloatConstant(y),
                                  TupleCons(FloatConstant(k), EndOfTuple)))))


let get_decoset (value : syntactic_value) =
  match value with
  | TupleCons(valuedecoS,
      TupleCons(valuedecoH,
        TupleCons(valuedecoM,
          TupleCons(valuedecoT, EndOfTuple)))) ->
    (valuedecoS, valuedecoH, valuedecoM, valuedecoT)

  | _ -> report_bug_value "interpret_decoset" value


let get_font (value : syntactic_value) : HorzBox.font_with_ratio =
  match value with
  | TupleCons(valueabbrev,
      TupleCons(FloatConstant(sizer),
        TupleCons(FloatConstant(risingr), EndOfTuple))) ->
      let abbrev = get_string valueabbrev in
        (abbrev, sizer, risingr)

  | _ -> report_bug_value "interpret_font" value


let make_font_value (abbrev, sizer, risingr) =
  TupleCons(StringConstant(abbrev),
    TupleCons(FloatConstant(sizer),
      TupleCons(FloatConstant(risingr), EndOfTuple)))


let get_vert value =
  match value with
  | Vert(imvblst) -> imvblst
  | _             -> report_bug_value "get_vert" value


let get_horz value =
  match value with
  | Horz(hblst) -> hblst
  | _           -> report_bug_value "get_horz" value


let get_point value =
  match value with
  | TupleCons(LengthConstant(lenx),
      TupleCons(LengthConstant(leny), EndOfTuple)) -> (lenx, leny)

  | _ -> report_bug_value "get_point" value


let get_script (value : syntactic_value) =
  match value with
  | Constructor("HanIdeographic", UnitConstant) -> CharBasis.HanIdeographic
  | Constructor("Kana"          , UnitConstant) -> CharBasis.HiraganaOrKatakana
  | Constructor("Latin"         , UnitConstant) -> CharBasis.Latin
  | Constructor("Other"         , UnitConstant) -> CharBasis.OtherScript
  | _                                           -> report_bug_value "get_script" value


let make_script_value script =
  let label =
    match script with
    | CharBasis.HanIdeographic     -> "HanIdeographic"
    | CharBasis.HiraganaOrKatakana -> "Kana"
    | CharBasis.Latin              -> "Latin"
    | CharBasis.OtherScript        -> "OtherScript"
    | _                            -> report_bug_value "make_script_value" UnitConstant
  in
    Constructor(label, UnitConstant)


let get_uchar_list (value : syntactic_value) =
  match value with
  | StringEmpty       -> []
  | StringConstant(s) -> InternalText.to_uchar_list (InternalText.of_utf8 s)
  | _                 -> report_bug_value "get_uchar_list" value


let get_language_system (value : syntactic_value) =
  match value with
  | Constructor("Japanese"        , UnitConstant) -> CharBasis.Japanese
  | Constructor("English"         , UnitConstant) -> CharBasis.English
  | Constructor("NoLanguageSystem", UnitConstant) -> CharBasis.NoLanguageSystem
  | _                                             -> report_bug_value "get_language_system" value


let make_language_system_value langsys =
  let label =
    match langsys with
    | CharBasis.Japanese         -> "Japanese"
    | CharBasis.English          -> "English"
    | CharBasis.NoLanguageSystem -> "NoLanguageSystem"
  in
    Constructor(label, UnitConstant)


let get_list getf (value : syntactic_value) =
  let rec aux acc value =
    match value with
    | ListCons(vhead, vtail) -> aux (Alist.extend acc (getf vhead)) vtail
    | EndOfList              -> Alist.to_list acc
    | _                      -> report_bug_vm "get_list"
  in
    aux Alist.empty value


let get_math_char_class (value : syntactic_value) =
  match value with
  | Constructor("MathItalic"      , UnitConstant) -> HorzBox.MathItalic
  | Constructor("MathBoldItalic"  , UnitConstant) -> HorzBox.MathBoldItalic
  | Constructor("MathRoman"       , UnitConstant) -> HorzBox.MathRoman
  | Constructor("MathBoldRoman"   , UnitConstant) -> HorzBox.MathBoldRoman
  | Constructor("MathScript"      , UnitConstant) -> HorzBox.MathScript
  | Constructor("MathBoldScript"  , UnitConstant) -> HorzBox.MathBoldScript
  | Constructor("MathFraktur"     , UnitConstant) -> HorzBox.MathFraktur
  | Constructor("MathBoldFraktur" , UnitConstant) -> HorzBox.MathBoldFraktur
  | Constructor("MathDoubleStruck", UnitConstant) -> HorzBox.MathDoubleStruck
  | _                                             -> report_bug_value "get_math_char_class" value


let get_math_class (value : syntactic_value) =
  match value with
  | Constructor("MathOrd"   , UnitConstant) -> HorzBox.MathOrdinary
  | Constructor("MathBin"   , UnitConstant) -> HorzBox.MathBinary
  | Constructor("MathRel"   , UnitConstant) -> HorzBox.MathRelation
  | Constructor("MathOp"    , UnitConstant) -> HorzBox.MathOperator
  | Constructor("MathPunct" , UnitConstant) -> HorzBox.MathPunct
  | Constructor("MathOpen"  , UnitConstant) -> HorzBox.MathOpen
  | Constructor("MathClose" , UnitConstant) -> HorzBox.MathClose
  | Constructor("MathPrefix", UnitConstant) -> HorzBox.MathPrefix
  | _                                       -> report_bug_value "get_math_class" value


let get_option (getf : syntactic_value -> 'a) (value : syntactic_value) : 'a option =
  match value with
  | Constructor("None", UnitConstant) -> None
  | Constructor("Some", valuesub)     -> Some(getf valuesub)
  | _                                 -> report_bug_vm "interpret_option"


let get_page_size (value : syntactic_value) : HorzBox.page_size =
  match value with
  | Constructor("A0Paper" , UnitConstant) -> HorzBox.A0Paper
  | Constructor("A1Paper" , UnitConstant) -> HorzBox.A1Paper
  | Constructor("A2Paper" , UnitConstant) -> HorzBox.A2Paper
  | Constructor("A3Paper" , UnitConstant) -> HorzBox.A3Paper
  | Constructor("A4Paper" , UnitConstant) -> HorzBox.A4Paper
  | Constructor("A5Paper" , UnitConstant) -> HorzBox.A5Paper
  | Constructor("USLetter", UnitConstant) -> HorzBox.USLetter
  | Constructor("USLegal" , UnitConstant) -> HorzBox.USLegal

  | Constructor("UserDefinedPaper",
                TupleCons(LengthConstant(pgwid), TupleCons(LengthConstant(pghgt), EndOfTuple))) ->
    HorzBox.UserDefinedPaper(pgwid, pghgt)

  | _ -> report_bug_vm "interpret_page"


let get_tuple3 getf value =
  match value with
  | TupleCons(v1, TupleCons(v2, TupleCons(v3, EndOfTuple))) ->
      let c1 = getf v1 in
      let c2 = getf v2 in
      let c3 = getf v3 in
        (c1, c2, c3)

  | _ -> report_bug_value "get_tuple3" value


let get_context (value : syntactic_value) : input_context =
  match value with
  | Context(ictx) -> ictx
  | _             -> report_bug_value "get_context" value


let get_length (value : syntactic_value) : length =
  match value with
  | LengthConstant(len) -> len
  | _                   -> report_bug_value "get_length" value


let get_math value : math list =
    match value with
    | MathValue(mlst) -> mlst
    | _               -> report_bug_value "get_math" value


let get_bool value : bool =
  match value with
  | BooleanConstant(bc) -> bc
  | other               -> report_bug_value "get_bool" value


let get_int (value : syntactic_value) : int =
  match value with
  | IntegerConstant(nc) -> nc
  | _                   -> report_bug_value "get_int" value


let get_float value : float =
  match value with
  | FloatConstant(nc) -> nc
  | _                 -> report_bug_value "get_float" value


let get_page_size value =
  match value with
  | Constructor("A0Paper" , UnitConstant) -> HorzBox.A0Paper
  | Constructor("A1Paper" , UnitConstant) -> HorzBox.A1Paper
  | Constructor("A2Paper" , UnitConstant) -> HorzBox.A2Paper
  | Constructor("A3Paper" , UnitConstant) -> HorzBox.A3Paper
  | Constructor("A4Paper" , UnitConstant) -> HorzBox.A4Paper
  | Constructor("A5Paper" , UnitConstant) -> HorzBox.A5Paper
  | Constructor("USLetter", UnitConstant) -> HorzBox.USLetter
  | Constructor("USLegal" , UnitConstant) -> HorzBox.USLegal

  | Constructor("UserDefinedPaper",
      TupleCons(LengthConstant(pgwid), TupleCons(LengthConstant(pghgt), EndOfTuple))) ->
        HorzBox.UserDefinedPaper(pgwid, pghgt)

  | _ -> report_bug_value "get_page_size" value


let get_regexp (value : syntactic_value) : Str.regexp =
  match value with
  | RegExpConstant(regexp) -> regexp
  | _                      -> report_bug_value "get_regexp" value


let get_path_value (value : syntactic_value) : GraphicData.path list =
  match value with
  | PathValue(pathlst) -> pathlst
  | _                  -> report_bug_value "get_path_value" value


let get_prepath (value : syntactic_value) : PrePath.t =
    match value with
    | PrePathValue(prepath) -> prepath
    | _                     -> report_bug_value "get_prepath" value


let get_math_variant_style value =
  let rcd =
    match value with
    | RecordValue(rcd) -> rcd
    | _                -> report_bug_value "get_math_variant_style: not a record" value
  in
    match
      ( Assoc.find_opt rcd "italic",
        Assoc.find_opt rcd "bold-italic",
        Assoc.find_opt rcd "roman",
        Assoc.find_opt rcd "bold-roman",
        Assoc.find_opt rcd "script",
        Assoc.find_opt rcd "bold-script",
        Assoc.find_opt rcd "fraktur",
        Assoc.find_opt rcd "bold-fraktur",
        Assoc.find_opt rcd "double-struck" )
    with
    | ( Some(vcpI),
        Some(vcpBI),
        Some(vcpR),
        Some(vcpBR),
        Some(vcpS),
        Some(vcpBS),
        Some(vcpF),
        Some(vcpBF),
        Some(vcpDS) ) ->
          let uchlstI  = get_uchar_list vcpI  in
          let uchlstBI = get_uchar_list vcpBI in
          let uchlstR  = get_uchar_list vcpR  in
          let uchlstBR = get_uchar_list vcpBR in
          let uchlstS  = get_uchar_list vcpS  in
          let uchlstBS = get_uchar_list vcpBS in
          let uchlstF  = get_uchar_list vcpF  in
          let uchlstBF = get_uchar_list vcpBF in
          let uchlstDS = get_uchar_list vcpDS in
            HorzBox.({
              math_italic        = uchlstI ;
              math_bold_italic   = uchlstBI;
              math_roman         = uchlstR ;
              math_bold_roman    = uchlstBR;
              math_script        = uchlstS ;
              math_bold_script   = uchlstBS;
              math_fraktur       = uchlstF ;
              math_bold_fraktur  = uchlstBF;
              math_double_struck = uchlstDS;
            })

    | _ -> report_bug_value "get_math_variant_style: missing some fields" value


let make_page_break_info pbinfo =
  let asc =
    Assoc.of_list [
      ("page-number", IntegerConstant(pbinfo.HorzBox.current_page_number));
    ]
  in
    RecordValue(asc)


let make_page_content_info pcinfo =
  make_page_break_info pcinfo  (* temporary *)
(*
  let asc =
    Assoc.of_list [
      ("page-number", IntegerConstant(pcinfo.HorzBox.page_number));
    ]
  in
    RecordValue(asc)
*)


let make_hook (reducef : syntactic_value -> syntactic_value list -> syntactic_value) (valuehook : syntactic_value) : (HorzBox.page_break_info -> point -> unit) =
  (fun pbinfo (xpos, yposbaseline) ->
     let valuept = TupleCons(LengthConstant(xpos), TupleCons(LengthConstant(yposbaseline), EndOfTuple)) in
     let valuepbinfo = make_page_break_info pbinfo in
     let valueret = reducef valuehook [valuepbinfo; valuept] in
       match valueret with
       | UnitConstant -> ()
       | _            -> report_bug_vm "make_hook"
  )


let make_page_content_scheme_func reducef valuef : HorzBox.page_content_scheme_func =
  (fun pbinfo ->
     let valuepbinfo = make_page_break_info pbinfo in
     let valueret = reducef valuef [valuepbinfo] in
       match valueret with
       | RecordValue(asc) ->
           begin
             match
               (Assoc.find_opt asc "text-origin",
                Assoc.find_opt asc "text-height")
             with
             | (Some(vTO), Some(LengthConstant(vTHlen))) ->
               HorzBox.({
                   page_content_origin = get_point(vTO);
                   page_content_height = vTHlen;
                 })

             | _ -> report_bug_value "make_page_scheme_func:1" valueret
           end

       | _ -> report_bug_value "make_page_scheme_func:2" valueret
  )


and make_page_parts_scheme_func reducef valuef : HorzBox.page_parts_scheme_func =
  (fun pcinfo ->
     let valuepcinfo = make_page_content_info pcinfo in
     let valueret = reducef valuef [valuepcinfo] in
       match valueret with
       | RecordValue(asc) ->
         begin
           match
             (Assoc.find_opt asc "header-origin",
              Assoc.find_opt asc "header-content",
              Assoc.find_opt asc "footer-origin",
              Assoc.find_opt asc "footer-content")
           with
           | (Some(vHO), Some(Vert(vHCvert)), Some(vFO), Some(Vert(vFCvert))) ->
               HorzBox.({
                 header_origin  = get_point vHO;
                 header_content = PageBreak.solidify vHCvert;
                 footer_origin  = get_point vFO;
                 footer_content = PageBreak.solidify vFCvert;
               })

           | _ -> report_bug_vm "make_page_parts_scheme_func"
         end

       | _ -> report_bug_vm "make_page_parts_scheme_func"
  )


let make_frame_deco reducef valuedeco =
  (fun (xpos, ypos) wid hgt dpt ->
     let valuepos = TupleCons(LengthConstant(xpos), TupleCons(LengthConstant(ypos), EndOfTuple)) in
     let valuewid = LengthConstant(wid) in
     let valuehgt = LengthConstant(hgt) in
     let valuedpt = LengthConstant(Length.negate dpt) in
     (* -- depth values for users are nonnegative -- *)
     let valueret = reducef valuedeco [valuepos; valuewid; valuehgt; valuedpt] in
       graphics_of_list valueret
  )


let make_math_kern_func reducef valuekernf : HorzBox.math_kern_func =
  (fun corrhgt ->
    let astcorrhgt = LengthConstant(corrhgt) in
    let valueret = reducef valuekernf [astcorrhgt] in
      get_length valueret
  )


let make_paren reducef valueparenf : HorzBox.paren =
  (fun hgt dpt hgtaxis fontsize color ->
     let valuehgt      = LengthConstant(hgt) in
     let valuedpt      = LengthConstant(Length.negate dpt) in
     (* -- depth values for users are nonnegative -- *)
     let valuehgtaxis  = LengthConstant(hgtaxis) in
     let valuefontsize = LengthConstant(fontsize) in
     let valuecolor    = make_color_value color in
     let valueret = reducef valueparenf [valuehgt; valuedpt; valuehgtaxis; valuefontsize; valuecolor] in
       match valueret with
       | TupleCons(Horz(hblst), TupleCons(valuekernf, EndOfTuple)) ->
           let kernf = make_math_kern_func reducef valuekernf in
             (hblst, kernf)

       | _ ->
           report_bug_vm "make_paren"
  )


let make_math_char_kern_func reducef valuekernf : HorzBox.math_char_kern_func =
  (fun fontsize ypos ->
     let valuefontsize = LengthConstant(fontsize) in
     let valueypos     = LengthConstant(ypos) in
     let valueret = reducef valuekernf [valuefontsize; valueypos] in
       get_length valueret
  )


let make_inline_graphics reducef valueg =
  (fun (xpos, ypos) ->
     let valuepos = TupleCons(LengthConstant(xpos), TupleCons(LengthConstant(ypos), EndOfTuple)) in
     let valueret = reducef valueg [valuepos] in
       graphics_of_list valueret
  )


let make_length_list lenlst =
  List.fold_right (fun l acc ->
    ListCons(LengthConstant(l), acc)
  ) lenlst EndOfList


let make_list (type a) (makef : a -> syntactic_value) (lst : a list) : syntactic_value =
  List.fold_right (fun x ast -> ListCons(makef x, ast)) lst EndOfList


let make_line_stack (hblstlst : (HorzBox.horz_box list) list) =
  let open HorzBox in
  let wid =
    hblstlst |> List.fold_left (fun widacc hblst ->
      let (wid, _, _) = LineBreak.get_natural_metrics hblst in
       Length.max wid widacc
    ) Length.zero
  in
  let trilst = hblstlst |> List.map (fun hblst -> LineBreak.fit hblst wid) in
  let imvblst =
    trilst |> List.fold_left (fun imvbacc (imhblst, hgt, dpt) ->
      Alist.extend imvbacc (VertLine(hgt, dpt, imhblst))
    ) Alist.empty |> Alist.to_list
  in
    (wid, imvblst)


let adjust_to_first_line (imvblst : HorzBox.intermediate_vert_box list) =
  let open HorzBox in
  let rec aux optinit totalhgtinit imvblst =
    imvblst |> List.fold_left (fun (opt, totalhgt) imvb ->
      match (imvb, opt) with
      | (ImVertLine(hgt, dpt, _), None)  -> (Some(totalhgt +% hgt), totalhgt +% hgt +% (Length.negate dpt))
      | (ImVertLine(hgt, dpt, _), _)     -> (opt, totalhgt +% hgt +% (Length.negate dpt))
      | (ImVertFixedEmpty(vskip), _)     -> (opt, totalhgt +% vskip)

      | (ImVertFrame(pads, _, _, imvblstsub), _) ->
          let totalhgtbefore = totalhgt +% pads.paddingT in
          let (optsub, totalhgtsub) = aux opt totalhgtbefore imvblstsub in
          let totalhgtafter = totalhgtsub +% pads.paddingB in
            (optsub, totalhgtafter)

    ) (optinit, totalhgtinit)
  in
    match aux None Length.zero imvblst with
    | (Some(hgt), totalhgt) -> (hgt, Length.negate (totalhgt -% hgt))
    | (None, totalhgt)      -> (Length.zero, Length.negate totalhgt)


let adjust_to_last_line (imvblst : HorzBox.intermediate_vert_box list) =
    let open HorzBox in
    let rec aux optinit totalhgtinit evvblst =
      let evvblstrev = List.rev evvblst in
        evvblstrev |> List.fold_left (fun (opt, totalhgt) imvblast ->
            match (imvblast, opt) with
            | (ImVertLine(hgt, dpt, _), None)  -> (Some((Length.negate totalhgt) +% dpt), totalhgt +% (Length.negate dpt) +% hgt)
            | (ImVertLine(hgt, dpt, _), _)     -> (opt, totalhgt +% (Length.negate dpt) +% hgt)
            | (ImVertFixedEmpty(vskip), _)     -> (opt, totalhgt +% vskip)

            | (ImVertFrame(pads, _, _, evvblstsub), _) ->
                let totalhgtbefore = totalhgt +% pads.paddingB in
                let (optsub, totalhgtsub) = aux opt totalhgtbefore evvblstsub in
                let totalhgtafter = totalhgtsub +% pads.paddingT in
                  (optsub, totalhgtafter)

        ) (optinit, totalhgtinit)
    in
      match aux None Length.zero imvblst with
      | (Some(dpt), totalhgt) -> (totalhgt +% dpt, dpt)
      | (None, totalhgt)      -> (totalhgt, Length.zero)
