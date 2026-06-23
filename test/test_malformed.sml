(* test_malformed.sml -- malformed WKT returns NONE, and number formatting
   determinism (integral coords print without a trailing ".0"). *)

structure MalformedTests =
struct
  open Support
  structure G = GeoJson

  fun run () =
    let
      val () = Harness.section "malformed: returns NONE"
      val () = checkNone "empty string" ""
      val () = checkNone "garbage" "not wkt at all"
      val () = checkNone "unknown type" "CIRCLE (0 0, 5)"
      val () = checkNone "missing closing paren" "POINT (30 10"
      val () = checkNone "missing opening paren" "POINT 30 10)"
      val () = checkNone "missing coordinate" "POINT (30)"
      val () = checkNone "trailing junk" "POINT (30 10) extra"
      val () = checkNone "empty parens" "POINT ()"
      val () = checkNone "non-numeric coord" "POINT (30 abc)"
      val () = checkNone "linestring missing comma" "LINESTRING (30 10 10 30)"
      val () = checkNone "polygon single paren" "POLYGON (30 10, 40 40, 30 10)"
      val () = checkNone "collection of raw coords" "GEOMETRYCOLLECTION (30 10)"

      val () = Harness.section "number formatting: determinism"
      (* Integral coordinates drop the ".0"; fractional coordinates keep the
         minimal decimal representation. Output uses ASCII '-' for negatives. *)
      val () = checkSerialize "integral drops .0"
                 (G.Point [30.0, 10.0], "POINT (30 10)")
      val () = checkSerialize "fractional kept"
                 (G.Point [30.5, 10.25], "POINT (30.5 10.25)")
      val () = checkSerialize "negative uses ASCII minus"
                 (G.Point [~30.0, ~10.5], "POINT (-30 -10.5)")
      val () = checkSerialize "zero"
                 (G.Point [0.0, ~0.0], "POINT (0 0)")
    in
      ()
    end
end
