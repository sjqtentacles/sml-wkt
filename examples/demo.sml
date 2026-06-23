(* demo.sml

   A tour of `sml-wkt`: parse Well-Known Text into the shared sml-geo geometry
   AST (`GeoJson.geometry`), serialize it back to canonical WKT, and show that
   the very same value re-renders as GeoJSON through the vendored sml-geo
   library. WKT is the text counterpart to sml-geo's GeoJSON; both share one
   geometry model, so the formats interoperate for free.

   Output is byte-identical across MLton and Poly/ML (deterministic coordinate
   formatting, no `Real.toString`). Build and run with `make example`. *)

structure W = Wkt
structure G = GeoJson

fun line s = print (s ^ "\n")

(* Render a geometry as GeoJSON via the vendored sml-geo, to show interop. *)
fun toGeoJson g = JsonPretty.toString (G.toJson (G.Geometry g))

val samples =
  [ "POINT (30 10)"
  , "LINESTRING (30 10, 10 30, 40 40)"
  , "POLYGON ((35 10, 45 45, 15 40, 10 20, 35 10), (20 30, 35 35, 30 20, 20 30))"
  , "MULTIPOINT (10 40, 40 30, 20 20, 30 10)"
  , "MULTIPOLYGON (((30 20, 45 40, 10 40, 30 20)), ((15 5, 40 10, 10 20, 5 10, 15 5)))"
  , "GEOMETRYCOLLECTION (POINT (40 10), LINESTRING (10 10, 20 20, 10 40))"
  , "POINT EMPTY" ]

fun showSample src =
  case W.parse src of
      NONE => (line ("  input : " ^ src); line "  (could not parse)"; line "")
    | SOME g =>
        ( line ("  input : " ^ src)
        ; line ("  wkt   : " ^ W.serialize g)
        ; line ("  geojson: " ^ toGeoJson g)
        ; line "" )

val () = line "=== sml-wkt demo =============================================="
val () = line ""
val () = line "Parse WKT into sml-geo's geometry AST, re-serialize to canonical"
val () = line "WKT, and render the same value as GeoJSON (vendored sml-geo)."
val () = line ""

val () = List.app showSample samples

(* Round-trip: serialize a hand-built geometry, then parse it back. *)
val () = line "Round-trip a hand-built MultiLineString:"
val built = G.MultiLineString [[[0.0,0.0],[1.0,1.5]], [[2.0,2.0],[3.25,3.0]]]
val wkt = W.serialize built
val () = line ("  serialized : " ^ wkt)
val () =
  case W.parse wkt of
      SOME _ => line "  reparsed   : ok"
    | NONE => line "  reparsed   : FAILED"
val () = line ""

val () = line "==============================================================="
