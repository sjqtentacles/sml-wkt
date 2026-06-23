(* wkt.sml

   Well-Known Text (WKT) parser and serializer, built on the geometry AST of
   the vendored sml-geo (`GeoJson.geometry`). Pure SML: no FFI, no IO, no
   clock, no randomness, no threads. Output is byte-identical across MLton and
   Poly/ML thanks to the hand-written coordinate formatter (`fmtCoord`). *)

structure Wkt :> WKT =
struct
  type geometry = GeoJson.geometry

  open GeoJson

  (* ======================================================================
   * Deterministic coordinate formatting
   *
   * `Real.toString` is not byte-identical across compilers, so format every
   * coordinate ourselves. Integral values print without a fraction; otherwise
   * print the shortest fixed-decimal string (1..15 places) that recovers the
   * value, with trailing zeros trimmed. Negatives use ASCII '-'.
   * ====================================================================== *)

  (* Trim trailing zeros (and a dangling '.') from a fixed-decimal string with
     no sign and no exponent, e.g. "30.500" -> "30.5", "30.000" -> "30". *)
  fun trimZeros s =
    if CharVector.exists (fn c => c = #".") s
    then
      let
        fun dropZeros i =
          if i >= 0 andalso String.sub (s, i) = #"0"
          then dropZeros (i - 1)
          else i
        val last = dropZeros (size s - 1)
        val last = if last >= 0 andalso String.sub (s, last) = #"."
                   then last - 1
                   else last
      in
        String.substring (s, 0, last + 1)
      end
    else s

  fun fmtCoord (x : real) : string =
    if Real.isNan x then "NaN"
    else if not (Real.isFinite x) then (if x < 0.0 then "-Inf" else "Inf")
    else
      let
        (* Normalize negative zero to a positive sign. *)
        val neg = x < 0.0 andalso Real.!= (x, 0.0)
        val a = Real.abs x
        (* Find the fewest decimals that round-trips a back to itself. *)
        fun search k =
          if k >= 15 then Real.fmt (StringCvt.FIX (SOME 15)) a
          else
            let val s = Real.fmt (StringCvt.FIX (SOME k)) a
            in
              case Real.fromString s of
                  SOME r => if Real.== (r, a) then s else search (k + 1)
                | NONE => search (k + 1)
            end
        val body = trimZeros (search 0)
        (* Guard against a "-0" result after trimming. *)
        val body = if body = "" then "0" else body
      in
        if neg andalso body <> "0" then "-" ^ body else body
      end

  (* ======================================================================
   * Serializer
   * ====================================================================== *)

  fun fmtPos (p : pos) = String.concatWith " " (List.map fmtCoord p)

  (* "p1, p2, ..." *)
  fun fmtPosList ps = String.concatWith ", " (List.map fmtPos ps)

  (* "(p1, p2, ...)" -- a parenthesized coordinate sequence (a ring/line). *)
  fun fmtRing ps = "(" ^ fmtPosList ps ^ ")"

  (* "(r1), (r2), ..." -- a list of rings. *)
  fun fmtRings rings = String.concatWith ", " (List.map fmtRing rings)

  fun serialize g =
    case g of
        Point [] => "POINT EMPTY"
      | Point p => "POINT (" ^ fmtPos p ^ ")"
      | LineString [] => "LINESTRING EMPTY"
      | LineString ps => "LINESTRING (" ^ fmtPosList ps ^ ")"
      | Polygon [] => "POLYGON EMPTY"
      | Polygon rings => "POLYGON (" ^ fmtRings rings ^ ")"
      | MultiPoint [] => "MULTIPOINT EMPTY"
      | MultiPoint ps =>
          "MULTIPOINT (" ^ String.concatWith ", " (List.map (fn p => "(" ^ fmtPos p ^ ")") ps) ^ ")"
      | MultiLineString [] => "MULTILINESTRING EMPTY"
      | MultiLineString lines => "MULTILINESTRING (" ^ fmtRings lines ^ ")"
      | MultiPolygon [] => "MULTIPOLYGON EMPTY"
      | MultiPolygon polys =>
          "MULTIPOLYGON (" ^ String.concatWith ", " (List.map (fn rings => "(" ^ fmtRings rings ^ ")") polys) ^ ")"
      | GeometryCollection [] => "GEOMETRYCOLLECTION EMPTY"
      | GeometryCollection gs =>
          "GEOMETRYCOLLECTION (" ^ String.concatWith ", " (List.map serialize gs) ^ ")"

  (* ======================================================================
   * Parser
   *
   * A small hand-rolled recursive-descent parser over a character list with an
   * explicit position. Every primitive returns `(value, rest)` or raises
   * `Bad`; `parse` catches `Bad` and returns NONE.
   * ====================================================================== *)

  exception Bad

  fun isWs c = c = #" " orelse c = #"\t" orelse c = #"\n" orelse c = #"\r"

  fun skipWs cs =
    case cs of
        c :: rest => if isWs c then skipWs rest else cs
      | [] => cs

  (* Consume the literal character `c` (after leading whitespace). *)
  fun expect c cs =
    case skipWs cs of
        d :: rest => if d = c then rest else raise Bad
      | [] => raise Bad

  (* Peek the next non-whitespace character, if any. *)
  fun peek cs =
    case skipWs cs of
        c :: _ => SOME c
      | [] => NONE

  fun isDigit c = c >= #"0" andalso c <= #"9"

  (* Parse a number: optional sign, digits, optional fraction, optional
     exponent. Accepts forms like 30, -30, 30.5, .5, 3e2, -3.0E-1. *)
  fun parseNumber cs =
    let
      val cs = skipWs cs
      fun takeWhile p cs acc =
        case cs of
            c :: rest => if p c then takeWhile p rest (c :: acc) else (rev acc, cs)
          | [] => (rev acc, cs)

      (* sign *)
      val (sign, cs) =
        case cs of
            #"-" :: rest => ([#"-"], rest)
          | #"+" :: rest => ([], rest)
          | _ => ([], cs)
      val (intPart, cs) = takeWhile isDigit cs []
      val (fracPart, cs) =
        case cs of
            #"." :: rest =>
              let val (fs, cs') = takeWhile isDigit rest []
              in (#"." :: fs, cs') end
          | _ => ([], cs)
      (* must have at least one digit overall *)
      val () = if null intPart andalso (case fracPart of [] => true | [#"."] => true | _ => false)
               then raise Bad else ()
      val (expPart, cs) =
        case cs of
            e :: rest =>
              if e = #"e" orelse e = #"E"
              then
                let
                  val (esign, rest2) =
                    case rest of
                        #"-" :: r => ([#"-"], r)
                      | #"+" :: r => ([#"+"], r)
                      | _ => ([], rest)
                  val (eds, rest3) = takeWhile isDigit rest2 []
                  val () = if null eds then raise Bad else ()
                in (e :: (esign @ eds), rest3) end
              else ([], cs)
          | [] => ([], cs)
      val str = String.implode (sign @ intPart @ fracPart @ expPart)
    in
      case Real.fromString str of
          SOME r => (r, cs)
        | NONE => raise Bad
    end

  (* Parse a position: two numbers, optionally a third (z), separated by
     whitespace, stopping at a comma or close paren. A fourth bare number is a
     malformed coordinate sequence. *)
  fun parsePos cs =
    let
      val (x, cs) = parseNumber cs
      val (y, cs) = parseNumber cs
      (* optional third coordinate, only if the next token is a number *)
      val (coords, cs) =
        case peek cs of
            SOME c =>
              if c = #"," orelse c = #")" then ([x, y], cs)
              else let val (z, cs') = parseNumber cs in ([x, y, z], cs') end
          | NONE => ([x, y], cs)
      (* after an optional z, the next token must be a separator/terminator *)
      val () =
        case peek cs of
            SOME c => if c = #"," orelse c = #")" then () else raise Bad
          | NONE => ()
    in
      (coords, cs)
    end

  (* Parse a comma-separated, parenthesized list using `item`:
       ( item , item , ... )
     `item` consumes one element and returns (value, rest). *)
  fun parseParenList item cs =
    let
      val cs = expect #"(" cs
      fun loop acc cs =
        let
          val (v, cs) = item cs
        in
          case peek cs of
              SOME #"," => loop (v :: acc) (expect #"," cs)
            | SOME #")" => (rev (v :: acc), expect #")" cs)
            | _ => raise Bad
        end
    in
      loop [] cs
    end

  (* A comma-separated list of positions (a line / ring body), parenthesized. *)
  fun parseCoordSeq cs = parseParenList parsePos cs

  (* Try to consume the keyword EMPTY (case-insensitive) after whitespace.
     Returns SOME rest if matched. *)
  fun tryEmpty cs =
    let
      val cs0 = skipWs cs
      fun matchKw kw cs =
        let
          fun go [] cs = SOME cs
            | go (k :: ks) (c :: rest) =
                if Char.toUpper c = k then go ks rest else NONE
            | go _ [] = NONE
        in go (String.explode kw) cs end
    in
      matchKw "EMPTY" cs0
    end

  (* Read the leading geometry keyword (letters), upper-cased. *)
  fun parseKeyword cs =
    let
      val cs = skipWs cs
      fun isAlpha c = (c >= #"A" andalso c <= #"Z") orelse (c >= #"a" andalso c <= #"z")
      fun go acc cs =
        case cs of
            c :: rest => if isAlpha c then go (Char.toUpper c :: acc) rest else (String.implode (rev acc), cs)
          | [] => (String.implode (rev acc), cs)
      val (kw, cs) = go [] cs
      val () = if kw = "" then raise Bad else ()
    in
      (kw, cs)
    end

  (* A single parenthesized position: "(x y)". *)
  fun parseParenPos cs =
    let
      val cs = expect #"(" cs
      val (p, cs) = parsePos cs
      val cs = expect #")" cs
    in
      (p, cs)
    end

  (* Parse a MULTIPOINT body, accepting both notations:
       ((x y), (x y))   and   (x y, x y)
     Both normalize to a `pos list`. *)
  fun parseMultiPoint cs =
    let
      (* an item is either "(x y)" or "x y" *)
      fun item cs =
        case peek cs of
            SOME #"(" => parseParenPos cs
          | _ => parsePos cs
    in
      parseParenList item cs
    end

  (* The empty geometry for a given keyword. *)
  fun emptyFor kw =
    case kw of
        "POINT" => Point []
      | "LINESTRING" => LineString []
      | "POLYGON" => Polygon []
      | "MULTIPOINT" => MultiPoint []
      | "MULTILINESTRING" => MultiLineString []
      | "MULTIPOLYGON" => MultiPolygon []
      | "GEOMETRYCOLLECTION" => GeometryCollection []
      | _ => raise Bad

  (* Parse a geometry (recursively, for GEOMETRYCOLLECTION). Returns
     (geometry, rest). Handles the EMPTY form for every type. *)
  fun parseGeometry cs =
    let
      val (kw, cs) = parseKeyword cs
    in
      case tryEmpty cs of
          SOME cs' => (emptyFor kw, cs')
        | NONE =>
            (case kw of
                 "POINT" =>
                   let val (p, cs) = parseParenPos cs in (Point p, cs) end
               | "LINESTRING" =>
                   let val (ps, cs) = parseCoordSeq cs in (LineString ps, cs) end
               | "POLYGON" =>
                   let val (rings, cs) = parseParenList parseCoordSeq cs
                   in (Polygon rings, cs) end
               | "MULTIPOINT" =>
                   let val (ps, cs) = parseMultiPoint cs in (MultiPoint ps, cs) end
               | "MULTILINESTRING" =>
                   let val (lines, cs) = parseParenList parseCoordSeq cs
                   in (MultiLineString lines, cs) end
               | "MULTIPOLYGON" =>
                   let val (polys, cs) = parseParenList (parseParenList parseCoordSeq) cs
                   in (MultiPolygon polys, cs) end
               | "GEOMETRYCOLLECTION" =>
                   let val (gs, cs) = parseParenList parseGeometry cs
                   in (GeometryCollection gs, cs) end
               | _ => raise Bad)
    end

  (* Top-level entry. *)
  fun parse s =
    let
      val cs = String.explode s
      val (g, cs) = parseGeometry cs
    in
      case skipWs cs of
          [] => SOME g
        | _ => NONE
    end
    handle Bad => NONE | _ => NONE
end
