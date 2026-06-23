(* test_point.sml -- POINT parsing/serialization, including 3D and EMPTY. *)

structure PointTests =
struct
  open Support
  structure G = GeoJson

  fun run () =
    let
      val () = Harness.section "point: parse"
      val () = checkParse "POINT (30 10)" ("POINT (30 10)", "POINT (30 10)")
      val () = checkParse "POINT with decimals"
                 ("POINT (30.5 10.25)", "POINT (30.5 10.25)")
      val () = checkParse "POINT 3D"
                 ("POINT (30 10 5)", "POINT (30 10 5)")
      val () = checkParse "POINT negative"
                 ("POINT (-30 -10.5)", "POINT (-30 -10.5)")

      val () = Harness.section "point: structure"
      val () =
        Harness.check "parses to GeoJson.Point"
          (case Wkt.parse "POINT (30 10)" of
               SOME (G.Point [x, y]) => approxPos ([x, y], [30.0, 10.0])
             | _ => false)

      val () = Harness.section "point: serialize"
      val () = checkSerialize "serialize Point"
                 (G.Point [30.0, 10.0], "POINT (30 10)")
      val () = checkSerialize "serialize Point 3D"
                 (G.Point [30.0, 10.0, 5.0], "POINT (30 10 5)")

      val () = Harness.section "point: EMPTY"
      val () = checkParse "POINT EMPTY" ("POINT EMPTY", "POINT EMPTY")
      val () = checkSerialize "serialize empty Point"
                 (G.Point [], "POINT EMPTY")
    in
      ()
    end
end
