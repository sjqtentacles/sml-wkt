(* test_multi.sml -- MULTIPOINT, MULTILINESTRING, MULTIPOLYGON. *)

structure MultiTests =
struct
  open Support
  structure G = GeoJson

  fun run () =
    let
      val () = Harness.section "multipoint: parse (both notations)"
      (* Canonical output uses the parenthesized member form. *)
      val () = checkParse "MULTIPOINT parenthesized"
                 ( "MULTIPOINT ((10 40), (40 30), (20 20), (30 10))"
                 , "MULTIPOINT ((10 40), (40 30), (20 20), (30 10))" )
      val () = checkParse "MULTIPOINT bare coords normalizes"
                 ( "MULTIPOINT (10 40, 40 30, 20 20, 30 10)"
                 , "MULTIPOINT ((10 40), (40 30), (20 20), (30 10))" )

      val () = Harness.section "multipoint: serialize / EMPTY"
      val () = checkSerialize "serialize MultiPoint"
                 ( G.MultiPoint [[10.0,40.0],[40.0,30.0]]
                 , "MULTIPOINT ((10 40), (40 30))" )
      val () = checkParse "MULTIPOINT EMPTY"
                 ("MULTIPOINT EMPTY", "MULTIPOINT EMPTY")

      val () = Harness.section "multilinestring: parse"
      val () = checkParse "MULTILINESTRING"
                 ( "MULTILINESTRING ((10 10, 20 20, 10 40), (40 40, 30 30, 40 20, 30 10))"
                 , "MULTILINESTRING ((10 10, 20 20, 10 40), (40 40, 30 30, 40 20, 30 10))" )
      val () = checkParse "MULTILINESTRING EMPTY"
                 ("MULTILINESTRING EMPTY", "MULTILINESTRING EMPTY")

      val () = Harness.section "multipolygon: parse"
      val () = checkParse "MULTIPOLYGON"
                 ( "MULTIPOLYGON (((30 20, 45 40, 10 40, 30 20)), ((15 5, 40 10, 10 20, 5 10, 15 5)))"
                 , "MULTIPOLYGON (((30 20, 45 40, 10 40, 30 20)), ((15 5, 40 10, 10 20, 5 10, 15 5)))" )
      val () = checkParse "MULTIPOLYGON with hole"
                 ( "MULTIPOLYGON (((40 40, 20 45, 45 30, 40 40)), ((20 35, 10 30, 10 10, 30 5, 45 20, 20 35), (30 20, 20 15, 20 25, 30 20)))"
                 , "MULTIPOLYGON (((40 40, 20 45, 45 30, 40 40)), ((20 35, 10 30, 10 10, 30 5, 45 20, 20 35), (30 20, 20 15, 20 25, 30 20)))" )

      val () = Harness.section "multipolygon: structure"
      val () =
        Harness.check "multipolygon with hole: 2 polys, 2nd has 2 rings"
          (case Wkt.parse "MULTIPOLYGON (((0 0, 1 0, 1 1, 0 0)), ((0 0, 2 0, 2 2, 0 0), (0.5 0.5, 1 0.5, 1 1, 0.5 0.5)))" of
               SOME (G.MultiPolygon [p1, p2]) => length p1 = 1 andalso length p2 = 2
             | _ => false)
      val () = checkParse "MULTIPOLYGON EMPTY"
                 ("MULTIPOLYGON EMPTY", "MULTIPOLYGON EMPTY")
    in
      ()
    end
end
