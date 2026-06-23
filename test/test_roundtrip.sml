(* test_roundtrip.sml -- parse -> serialize -> parse stability, and
   whitespace / case tolerance on input. *)

structure RoundTripTests =
struct
  open Support
  structure G = GeoJson

  fun run () =
    let
      val () = Harness.section "roundtrip: stability across geometry types"
      val () = checkRoundTrip "rt point" "POINT (30 10)"
      val () = checkRoundTrip "rt linestring" "LINESTRING (30 10, 10 30, 40 40)"
      val () = checkRoundTrip "rt polygon hole"
                 "POLYGON ((35 10, 45 45, 15 40, 10 20, 35 10), (20 30, 35 35, 30 20, 20 30))"
      val () = checkRoundTrip "rt multipoint" "MULTIPOINT ((10 40), (40 30))"
      val () = checkRoundTrip "rt multipolygon"
                 "MULTIPOLYGON (((30 20, 45 40, 10 40, 30 20)), ((15 5, 40 10, 10 20, 5 10, 15 5)))"
      val () = checkRoundTrip "rt collection"
                 "GEOMETRYCOLLECTION (POINT (40 10), LINESTRING (10 10, 20 20, 10 40))"
      val () = checkRoundTrip "rt empty point" "POINT EMPTY"

      val () = Harness.section "roundtrip: whitespace tolerance"
      val () = checkParse "leading/trailing whitespace"
                 ("   POINT (30 10)   ", "POINT (30 10)")
      val () = checkParse "extra interior whitespace"
                 ("POINT   (  30    10  )", "POINT (30 10)")
      val () = checkParse "newlines and tabs"
                 ("LINESTRING\n(30 10,\t10 30)", "LINESTRING (30 10, 10 30)")
      val () = checkParse "no space before paren"
                 ("POINT(30 10)", "POINT (30 10)")

      val () = Harness.section "roundtrip: case tolerance on keywords"
      val () = checkParse "lowercase keyword"
                 ("point (30 10)", "POINT (30 10)")
      val () = checkParse "mixed-case keyword"
                 ("LineString (0 0, 1 1)", "LINESTRING (0 0, 1 1)")
      val () = checkParse "lowercase empty"
                 ("point empty", "POINT EMPTY")
    in
      ()
    end
end
