(* test_collection.sml -- GEOMETRYCOLLECTION of mixed geometry types. *)

structure CollectionTests =
struct
  open Support
  structure G = GeoJson

  fun run () =
    let
      val () = Harness.section "geometrycollection: mixed types"
      val () = checkParse "GEOMETRYCOLLECTION point + linestring"
                 ( "GEOMETRYCOLLECTION (POINT (40 10), LINESTRING (10 10, 20 20, 10 40))"
                 , "GEOMETRYCOLLECTION (POINT (40 10), LINESTRING (10 10, 20 20, 10 40))" )
      val () = checkParse "GEOMETRYCOLLECTION with polygon"
                 ( "GEOMETRYCOLLECTION (POINT (40 10), POLYGON ((0 0, 1 0, 1 1, 0 0)))"
                 , "GEOMETRYCOLLECTION (POINT (40 10), POLYGON ((0 0, 1 0, 1 1, 0 0)))" )

      val () = Harness.section "geometrycollection: nested"
      val () = checkParse "GEOMETRYCOLLECTION nested collection"
                 ( "GEOMETRYCOLLECTION (POINT (1 1), GEOMETRYCOLLECTION (POINT (2 2)))"
                 , "GEOMETRYCOLLECTION (POINT (1 1), GEOMETRYCOLLECTION (POINT (2 2)))" )

      val () = Harness.section "geometrycollection: structure"
      val () =
        Harness.check "collection has 2 members"
          (case Wkt.parse "GEOMETRYCOLLECTION (POINT (1 1), LINESTRING (0 0, 1 1))" of
               SOME (G.GeometryCollection gs) => length gs = 2
             | _ => false)

      val () = Harness.section "geometrycollection: EMPTY"
      val () = checkParse "GEOMETRYCOLLECTION EMPTY"
                 ("GEOMETRYCOLLECTION EMPTY", "GEOMETRYCOLLECTION EMPTY")
      val () = checkSerialize "serialize empty collection"
                 (G.GeometryCollection [], "GEOMETRYCOLLECTION EMPTY")
    in
      ()
    end
end
