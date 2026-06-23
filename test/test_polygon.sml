(* test_polygon.sml -- POLYGON with exterior ring and holes; EMPTY. *)

structure PolygonTests =
struct
  open Support
  structure G = GeoJson

  fun run () =
    let
      val () = Harness.section "polygon: simple (exterior ring only)"
      val () = checkParse "POLYGON exterior"
                 ( "POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))"
                 , "POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))" )

      val () = Harness.section "polygon: with a hole"
      val () = checkParse "POLYGON with hole"
                 ( "POLYGON ((35 10, 45 45, 15 40, 10 20, 35 10), (20 30, 35 35, 30 20, 20 30))"
                 , "POLYGON ((35 10, 45 45, 15 40, 10 20, 35 10), (20 30, 35 35, 30 20, 20 30))" )

      val () = Harness.section "polygon: structure (ring count)"
      val () =
        Harness.check "hole polygon has 2 rings"
          (case Wkt.parse "POLYGON ((0 0, 1 0, 1 1, 0 0), (0.2 0.2, 0.4 0.2, 0.4 0.4, 0.2 0.2))" of
               SOME (G.Polygon rings) => length rings = 2
             | _ => false)

      val () = Harness.section "polygon: serialize"
      val () = checkSerialize "serialize Polygon"
                 ( G.Polygon [[[30.0,10.0],[40.0,40.0],[20.0,40.0],[10.0,20.0],[30.0,10.0]]]
                 , "POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))" )

      val () = Harness.section "polygon: EMPTY"
      val () = checkParse "POLYGON EMPTY" ("POLYGON EMPTY", "POLYGON EMPTY")
      val () = checkSerialize "serialize empty Polygon"
                 (G.Polygon [], "POLYGON EMPTY")
    in
      ()
    end
end
