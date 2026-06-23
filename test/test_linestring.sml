(* test_linestring.sml -- LINESTRING parsing/serialization and EMPTY. *)

structure LineStringTests =
struct
  open Support
  structure G = GeoJson

  fun run () =
    let
      val () = Harness.section "linestring: parse"
      val () = checkParse "LINESTRING basic"
                 ( "LINESTRING (30 10, 10 30, 40 40)"
                 , "LINESTRING (30 10, 10 30, 40 40)" )
      val () = checkParse "LINESTRING decimals"
                 ( "LINESTRING (0.5 0.5, 1.5 2.5)"
                 , "LINESTRING (0.5 0.5, 1.5 2.5)" )

      val () = Harness.section "linestring: structure"
      val () =
        Harness.check "parses to GeoJson.LineString"
          (case Wkt.parse "LINESTRING (30 10, 10 30)" of
               SOME (G.LineString [p1, p2]) =>
                 approxPos (p1, [30.0, 10.0]) andalso approxPos (p2, [10.0, 30.0])
             | _ => false)

      val () = Harness.section "linestring: serialize"
      val () = checkSerialize "serialize LineString"
                 ( G.LineString [[30.0, 10.0], [10.0, 30.0], [40.0, 40.0]]
                 , "LINESTRING (30 10, 10 30, 40 40)" )

      val () = Harness.section "linestring: EMPTY"
      val () = checkParse "LINESTRING EMPTY"
                 ("LINESTRING EMPTY", "LINESTRING EMPTY")
      val () = checkSerialize "serialize empty LineString"
                 (G.LineString [], "LINESTRING EMPTY")
    in
      ()
    end
end
