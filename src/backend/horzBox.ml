
open LengthInterface
open GraphicData


type stretchable =
  | FiniteStretch of length
  | Fils          of int


let add_stretchable strc1 strc2 =
  match (strc1, strc2) with
  | (FiniteStretch(w1), FiniteStretch(w2)) -> FiniteStretch(w1 +% w2)
  | (Fils(i1), Fils(i2))                   -> Fils(i1 + i2)
  | (Fils(i1), _)                          -> Fils(i1)
  | (_, Fils(i2))                          -> Fils(i2)


type length_info =
  {
    natural     : length;
    shrinkable  : length;
    stretchable : stretchable;
  }

type pure_badness = int
[@@deriving show]

type ratios =
  | TooShort
  | PermissiblyShort of float
  | PermissiblyLong  of float
  | TooLong

type font_abbrev = string
[@@deriving show]

type math_font_abbrev = string
[@@deriving show]

type file_path = string
(*
type encoding_in_pdf =
  | Latin1
  | UTF16BE
  | IdentityH
*)
type font_with_size = font_abbrev * Length.t
[@@deriving show]

type font_with_ratio = font_abbrev * float * float
[@@deriving show]

type page_size =
  | A0Paper
  | A1Paper
  | A2Paper
  | A3Paper
  | A4Paper
  | A5Paper
  | USLetter
  | USLegal
  | UserDefinedPaper of length * length
[@@deriving show { with_path = false }]

type page_content_scheme =
  {
    page_content_origin : point;
    page_content_height : length;
  }

let pp_page_content_scheme fmt _ = Format.fprintf fmt "<page-content-scheme>"

type page_break_info = {
  current_page_number : int;
}
[@@deriving show {with_path = false }]

type page_content_scheme_func = page_break_info -> page_content_scheme

let pp_page_content_scheme_func fmt _ = Format.fprintf fmt "<page-content-scheme-func>"

type paddings =
  {
    paddingL : length;
    paddingR : length;
    paddingT : length;
    paddingB : length;
  }
[@@deriving show { with_path = false }]

(*
type line_dash =
  | SolidLine
  | DashedLine of length * length * length

type line_join =
  | MiterJoin
  | RoundJoin
  | BevelJoin

type line_cap =
  | ButtCap
  | RoundCap
  | ProjectingSquareCap

(* will be deprecated *)
type graphics_state =
  {
    line_width   : length;
    line_dash    : line_dash;
    line_join    : line_join;
    line_cap     : line_cap;
    miter_limit  : length;
    fill_color   : color;
    stroke_color : color;
  }

(* will be deprecated *)
type graphics_command =
  | DrawStroke
  | DrawFillByNonzero
  | DrawFillByEvenOdd
  | DrawBothByNonzero
  | DrawBothByEvenOdd
*)

type horz_string_info =
  {
    font_abbrev    : font_abbrev;
    text_font_size : length;
    text_color     : color;
    rising         : length;
  }

let pp_horz_string_info fmt info =
  Format.fprintf fmt "(HSinfo)"

type math_string_info =
  {
    math_font_abbrev : math_font_abbrev;
    math_font_size   : length;
    math_color       : color;
  }

(* -- internal representation of boxes -- *)

type math_kind =
  | MathOrdinary
  | MathBinary
  | MathRelation
  | MathOperator
  | MathPunct
  | MathOpen
  | MathClose
  | MathPrefix    (* -- mainly for differantial operator 'd', '\partial', etc. -- *)
  | MathInner
  | MathEnd
[@@deriving show { with_path = false }]

type math_char_class =
  | MathItalic
  | MathBoldItalic
  | MathRoman
  | MathBoldRoman
  | MathScript
  | MathBoldScript
  | MathFraktur
  | MathBoldFraktur
  | MathDoubleStruck
[@@deriving show { with_path = false }]
(* TEMPORARY; should add more *)

type math_variant_style =
  {
    math_italic        : Uchar.t list;
    math_bold_italic   : Uchar.t list;
    math_roman         : Uchar.t list;
    math_bold_roman    : Uchar.t list;
    math_script        : Uchar.t list;
    math_bold_script   : Uchar.t list;
    math_fraktur       : Uchar.t list;
    math_bold_fraktur  : Uchar.t list;
    math_double_struck : Uchar.t list;
  }

let pp_math_variant_style =
  (fun fmt _ -> Format.fprintf fmt "<math-variant-style>")


module MathVariantCharMap = Map.Make
  (struct
    type t = string * math_char_class
    let compare = Pervasives.compare
  end)


type context_main = {
  hyphen_dictionary      : LoadHyph.t;
    [@printer (fun fmt _ -> Format.fprintf fmt "<hyph>")]
  hyphen_badness         : int;
  font_size              : length;
  font_scheme            : font_with_ratio CharBasis.ScriptSchemeMap.t;
    [@printer (fun fmt _ -> Format.fprintf fmt "<map>")]
  langsys_scheme         : CharBasis.language_system CharBasis.ScriptSchemeMap.t;
    [@printer (fun fmt _ -> Format.fprintf fmt "<map>")]
  math_font              : math_font_abbrev;
  dominant_wide_script   : CharBasis.script;
  dominant_narrow_script : CharBasis.script;
  space_natural          : float;
  space_shrink           : float;
  space_stretch          : float;
  adjacent_stretch       : float;
  paragraph_width        : length;
  paragraph_top          : length;
  paragraph_bottom       : length;
  leading                : length;
  min_gap_of_lines       : length;
  text_color             : color;
  manual_rising          : length;
  badness_space          : pure_badness;
  math_variant_char_map  : math_variant_value MathVariantCharMap.t;
    [@printer (fun fmt _ -> Format.fprintf fmt "<map>")]
  math_char_class        : math_char_class;
}

and decoration = point -> length -> length -> length -> (intermediate_horz_box list) Graphics.t

and rules_func = length list -> length list -> (intermediate_horz_box list) Graphics.t

and pure_horz_box =
(* -- spaces inserted before text processing -- *)
  | PHSOuterEmpty     of length * length * length
  | PHSOuterFil
  | PHSFixedEmpty     of length
(* -- texts -- *)
  | PHCInnerString    of context_main * Uchar.t list
      [@printer (fun fmt _ -> Format.fprintf fmt "@[FixedString(...)@]")]
  | PHCInnerMathGlyph of math_string_info * length * length * length * OutputText.t
      [@printer (fun fmt _ -> Format.fprintf fmt "@[FixedMathGlyph(...)@]")]
(* -- groups -- *)
  | PHGRising         of length * horz_box list
  | PHGFixedFrame     of paddings * length * decoration * horz_box list
  | PHGInnerFrame     of paddings * decoration * horz_box list
  | PHGOuterFrame     of paddings * decoration * horz_box list
  | PHGEmbeddedVert   of length * length * length * intermediate_vert_box list
  | PHGFixedGraphics  of length * length * length * (point -> (intermediate_horz_box list) Graphics.t)
  | PHGFixedTabular   of length * length * length * intermediate_row list * length list * length list * rules_func
  | PHGFixedImage     of length * length * ImageInfo.key
      [@printer (fun fmt _ -> Format.fprintf fmt "@[PHGFixedImage(...)@]")]
  | PHGHookPageBreak  of (page_break_info -> point -> unit)

and horz_box =
  | HorzPure           of pure_horz_box
  | HorzDiscretionary  of pure_badness * horz_box list * horz_box list * horz_box list
      [@printer (fun fmt _ -> Format.fprintf fmt "HorzDiscretionary(...)")]
  | HorzFrameBreakable of paddings * length * length * decoration * decoration * decoration * decoration * horz_box list
  | HorzScriptGuard    of CharBasis.script * horz_box list

and intermediate_horz_box =
  | ImHorz               of evaled_horz_box
  | ImHorzRising         of length * length * length * length * intermediate_horz_box list
  | ImHorzFrame          of length * length * length * decoration * intermediate_horz_box list
  | ImHorzInlineTabular  of length * length * length * intermediate_row list * length list * length list * rules_func
  | ImHorzEmbeddedVert   of length * length * length * intermediate_vert_box list
  | ImHorzInlineGraphics of length * length * length * (point -> (intermediate_horz_box list) Graphics.t)
  | ImHorzHookPageBreak  of (page_break_info -> point -> unit)

and evaled_horz_box =
  length * evaled_horz_box_main
      (* --
         (1) width
         (2) contents
         -- *)

and evaled_horz_box_main =
  | EvHorzString of horz_string_info * length * length * OutputText.t
      (* --
         (1) string information for writing string to PDF
         (2) content height
         (3) content depth
         (4) content string
         -- *)

  | EvHorzMathGlyph      of math_string_info * length * length * OutputText.t
      [@printer (fun fmt _ -> Format.fprintf fmt "EvHorzMathGlyph(...)")]
  | EvHorzRising         of length * length * length * evaled_horz_box list
  | EvHorzEmpty
  | EvHorzFrame          of length * length * decoration * evaled_horz_box list
  | EvHorzEmbeddedVert   of length * length * evaled_vert_box list
  | EvHorzInlineGraphics of length * length * (point -> (intermediate_horz_box list) Graphics.t)
  | EvHorzInlineTabular  of length * length * evaled_row list * length list * length list * rules_func
  | EvHorzInlineImage    of length * ImageInfo.key
      [@printer (fun fmt _ -> Format.fprintf fmt "EvHorzInlineImage(...)")]
  | EvHorzHookPageBreak  of page_break_info * (page_break_info -> point -> unit)
      (* --
         (1) page number determined during the page breaking
         (2) hook function invoked during the construction of PDF data
         -- *)

and vert_box =
  | VertLine              of length * length * intermediate_horz_box list
      [@printer (fun fmt _ -> Format.fprintf fmt "Line")]
  | VertFixedBreakable    of length
      [@printer (fun fmt _ -> Format.fprintf fmt "Breakable")]
  | VertTopMargin         of bool * length
      [@printer (fun fmt (b, _) -> Format.fprintf fmt "Top%s" (if b then "" else "*"))]
  | VertBottomMargin      of bool * length
      [@printer (fun fmt (b, _) -> Format.fprintf fmt "Bottom%s" (if b then "" else "*"))]
  | VertFrame             of paddings * decoration * decoration * decoration * decoration * length * vert_box list
(*      [@printer (fun fmt (_, _, _, _, _, imvblst) -> Format.fprintf fmt "%a" (pp_list pp_intermediate_vert_box) imvblst)] *)
  | VertClearPage

and intermediate_vert_box =
  | ImVertLine       of length * length * intermediate_horz_box list
  | ImVertFixedEmpty of length
  | ImVertFrame      of paddings * decoration * length * intermediate_vert_box list

and evaled_vert_box =
  | EvVertLine       of length * length * evaled_horz_box list
      [@printer (fun fmt _ -> Format.fprintf fmt "EvLine")]
  | EvVertFixedEmpty of length
      [@printer (fun fmt _ -> Format.fprintf fmt "EvEmpty")]
  | EvVertFrame      of paddings * page_break_info * decoration * length * evaled_vert_box list

and header_or_footer = page_break_info -> intermediate_vert_box list

and page_parts_scheme = {
  header_origin  : point;
    [@printer (fun fmt _ -> Format.fprintf fmt "<point>")]
  header_content : intermediate_vert_box list;
  footer_origin  : point;
    [@printer (fun fmt _ -> Format.fprintf fmt "<point>")]
  footer_content : intermediate_vert_box list;
}

and page_content_info =
  page_break_info
(*
{
  page_number : int;
}
*)

and page_parts_scheme_func = page_content_info -> page_parts_scheme


and math_char_kern_func = length -> length -> length
  (* --
     takes the actual font size and the y-position,
     and returns a kerning value (positive for making characters closer)
     -- *)

and math_kern_func = length -> length
  (* -- takes a y-position as a correction height and then returns a kerning value -- *)

and math_variant_value = math_kind * math_variant_value_main

and math_variant_value_main =
  | MathVariantToChar         of bool * Uchar.t list
      [@printer (fun fmt _ -> Format.fprintf fmt "<to-char>")]
  | MathVariantToCharWithKern of bool * Uchar.t list * math_char_kern_func * math_char_kern_func
      [@printer (fun fmt _ -> Format.fprintf fmt "<to-char'>")]

and paren = length -> length -> length -> length -> color -> horz_box list * math_kern_func
  (* --
     'paren':
       the type for adjustable parentheses.
       An adjustable parenthesis takes as arguments
       (1-2) the height and the depth of the inner contents,
       (3)   the axis height,
       (4)   the font size, and
       (5)   the color for glyphs,
       and then returns its inline box representation and the function for kerning.
     -- *)

and radical = length -> length -> length -> length -> color -> horz_box list
  (* --
     'radical':
       the type for adjustable radicals.
       An adjustable radical takes as arguments
       (1-2) the height and the thickness of the bar required by the math font,
       (3)   the depth of the inner contents,
       (4)   the font size, and
       (5)   the color for glyphs,
       and then returns the inline box representation.
     -- *)

and cell =
  | NormalCell of paddings * horz_box list
  | EmptyCell
  | MultiCell  of int * int * paddings * horz_box list

and row = cell list

and intermediate_cell =
  | ImNormalCell of (length * length * length) * intermediate_horz_box list
  | ImEmptyCell  of length
  | ImMultiCell  of (int * int * length * length * length * length) * intermediate_horz_box list

and intermediate_row = length * intermediate_cell list

and evaled_cell =
  | EvNormalCell of (length * length * length) * evaled_horz_box list
  | EvEmptyCell  of length
  | EvMultiCell  of (int * int * length * length * length * length) * evaled_horz_box list

and evaled_row = length * evaled_cell list
[@@deriving show { with_path = false }]

type column = cell list


let normalize_script ctx script_raw =
  match script_raw with
  | CharBasis.CommonNarrow
  | CharBasis.Inherited
      -> ctx.dominant_narrow_script

  | CharBasis.CommonWide
      -> ctx.dominant_wide_script

  | _ -> script_raw


let get_font_with_ratio ctx script_raw =
  let script = normalize_script ctx script_raw in
    match ctx.font_scheme |> CharBasis.ScriptSchemeMap.find_opt script with
    | None          -> failwith "get_font_with_ratio"
    | Some(fontsch) -> fontsch


let get_language_system ctx script_raw =
  let script = normalize_script ctx script_raw in
    match ctx.langsys_scheme |> CharBasis.ScriptSchemeMap.find_opt script with
    | None          -> CharBasis.NoLanguageSystem
    | Some(langsys) -> langsys


let get_string_info ctx script_raw =
  let (font_abbrev, ratio, rising_ratio) = get_font_with_ratio ctx script_raw in
    {
      font_abbrev    = font_abbrev;
      text_font_size = ctx.font_size *% ratio;
      text_color     = ctx.text_color;
      rising         = ctx.manual_rising +% ctx.font_size *% rising_ratio;
    }
