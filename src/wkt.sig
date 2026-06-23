(* wkt.sig

   Well-Known Text (WKT) geometry parser and serializer in pure Standard ML.

   WKT is the OGC Simple Features text encoding for geometry, e.g.
   `POINT (30 10)`, `LINESTRING (...)`, `POLYGON ((...))`, and the `MULTI*`
   and `GEOMETRYCOLLECTION` aggregates. This module is the *text* counterpart
   to the GeoJSON support in the vendored sml-geo library: both share the
   exact same geometry abstract syntax tree, `GeoJson.geometry`, so the two
   formats interoperate freely (parse WKT into a `GeoJson.geometry`, hand it to
   sml-geo's GeoJSON serializer, and vice versa).

   Geometry model (re-used from sml-geo, NOT redefined here)
   ---------------------------------------------------------
   `type geometry = GeoJson.geometry`, whose constructors are:

     - `Point of pos`                       single position
     - `MultiPoint of pos list`             several positions
     - `LineString of pos list`             a polyline
     - `MultiLineString of pos list list`   several polylines
     - `Polygon of pos list list`           exterior ring + interior rings (holes)
     - `MultiPolygon of pos list list list` several polygons
     - `GeometryCollection of geometry list`

   where `pos = real list` is `[x, y]` or `[x, y, z]`.

   EMPTY handling
   --------------
   WKT allows an empty geometry, written `POINT EMPTY`, `LINESTRING EMPTY`,
   `POLYGON EMPTY`, `MULTIPOINT EMPTY`, ..., `GEOMETRYCOLLECTION EMPTY`. There
   is no dedicated "empty" constructor in the shared AST, so an empty geometry
   is represented as the corresponding constructor applied to an empty
   coordinate list:

     - `POINT EMPTY`              <->  `Point []`
     - `LINESTRING EMPTY`         <->  `LineString []`
     - `POLYGON EMPTY`            <->  `Polygon []`
     - `MULTIPOINT EMPTY`         <->  `MultiPoint []`
     - `MULTILINESTRING EMPTY`    <->  `MultiLineString []`
     - `MULTIPOLYGON EMPTY`       <->  `MultiPolygon []`
     - `GEOMETRYCOLLECTION EMPTY` <->  `GeometryCollection []`

   These representations round-trip exactly.

   Number formatting
   -----------------
   `serialize` formats every coordinate with a deterministic, byte-identical
   formatter (`fmtCoord`), independent of the host compiler's `Real.toString`:

     - an integral value prints with no decimal point or fraction
       (`30.0` -> `"30"`);
     - a fractional value prints the shortest decimal that recovers the value,
       with no trailing zeros and no exponent (`30.5` -> `"30.5"`);
     - negatives use the ASCII hyphen-minus `-`, never `~`.

   This makes `serialize` output byte-identical under MLton and Poly/ML. *)

signature WKT =
sig
  (* The shared geometry AST, re-exported from sml-geo. *)
  type geometry = GeoJson.geometry

  (* Parse a WKT string into a geometry. Returns `NONE` for any malformed
     input (unknown geometry type, mismatched parentheses, missing or
     non-numeric coordinates, trailing junk, etc.). Leading and trailing
     whitespace is ignored, interior whitespace is flexible, and the geometry
     keyword is case-insensitive. *)
  val parse : string -> geometry option

  (* Serialize a geometry to canonical WKT. Coordinates are formatted with
     `fmtCoord`; members are separated by `", "`; `MULTIPOINT` members use the
     parenthesized form `((x y), (x y))`; empty geometries serialize to the
     `... EMPTY` form. The result is deterministic and byte-identical across
     compilers. *)
  val serialize : geometry -> string

  (* Deterministic coordinate formatter (exposed for tests and callers that
     want WKT-identical number formatting). Integral values print without a
     fraction; negatives use ASCII `-`. *)
  val fmtCoord : real -> string
end
