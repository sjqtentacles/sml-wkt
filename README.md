# sml-wkt

A Well-Known Text (WKT) geometry parser and serializer in pure Standard ML —
the OGC Simple Features *text* format (`POINT (30 10)`, `LINESTRING (...)`,
`POLYGON ((...))`, `MULTIPOINT`, `MULTILINESTRING`, `MULTIPOLYGON`,
`GEOMETRYCOLLECTION`). It is the text counterpart to
[`sml-geo`](https://github.com/sjqtentacles/sml-geo)'s GeoJSON support: both
share the **exact same geometry AST** (`GeoJson.geometry`), so the two formats
interoperate for free — parse WKT into a `GeoJson.geometry`, hand it to
sml-geo's GeoJSON serializer, and back. No FFI, no external dependencies at
runtime, and **deterministic**, byte-identically under both
[MLton](http://mlton.org/) and [Poly/ML](https://www.polyml.org/).

[![CI](https://github.com/sjqtentacles/sml-wkt/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-wkt/actions/workflows/ci.yml)

## Status

- 67 assertions, green on MLton and Poly/ML.
- Basis-library + vendored `sml-geo` only (which itself vendors `sml-json`,
  which vendors `sml-parsec`); deterministic across compilers.
- Vendors the whole `sml-geo` dependency tree (Layout B) under
  `lib/github.com/sjqtentacles/`, so the repo builds standalone.

## Purity

No FFI, no IO inside the library, no wall-clock, no ambient randomness, and no
threads. The same input string always parses to the same geometry, and the
same geometry always serializes to the same WKT, across runs, machines, and
compilers — the test suite and the demo are byte-identical under MLton and
Poly/ML. Coordinates are `real`, so the suite never compares them through
`Real.toString` (which differs between compilers): every comparison goes
through the deterministic canonical serialization (`Wkt.fmtCoord`), with an
explicit-epsilon helper (`Support.approxPos`) where numeric values are asserted
directly.

## Relationship to sml-geo (GeoJSON)

`sml-geo` models [GeoJSON](https://datatracker.ietf.org/doc/html/rfc7946) — the
*JSON* encoding of geometry. `sml-wkt` is the *WKT text* encoding of the **same
geometry model**. Rather than defining a parallel geometry type, this library
re-exports and builds on sml-geo's `GeoJson.geometry`:

```sml
type geometry = GeoJson.geometry   (* Point | LineString | Polygon | Multi* | GeometryCollection *)
```

so a value parsed from WKT can be serialized to GeoJSON (and vice versa)
without any conversion. See the demo for the round-trip.

## Install

With [`smlpkg`](https://github.com/diku-dk/smlpkg):

```
smlpkg add github.com/sjqtentacles/sml-wkt
smlpkg sync
```

Include the MLB from your own (it pulls in the vendored `sml-geo`, and
transitively `sml-json` + `sml-parsec`):

```
local
  $(SML_LIB)/basis/basis.mlb
  lib/github.com/sjqtentacles/sml-wkt/... (via smlpkg)
in
  ...
end
```

This brings `structure Wkt` (and the vendored `GeoJson`, `Json`, `JsonPretty`,
`CharParsec`) into scope.

## Quick start

```sml
(* parse WKT into the shared sml-geo geometry AST *)
val SOME g = Wkt.parse "POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))"
(* g : GeoJson.geometry = GeoJson.Polygon [...] *)

(* serialize back to canonical WKT *)
val s = Wkt.serialize g
(* "POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))" *)

(* interoperate with sml-geo's GeoJSON serializer *)
val json = JsonPretty.toString (GeoJson.toJson (GeoJson.Geometry g))
(* {"type":"Polygon","coordinates":[[[30,10],...]]} *)

(* malformed input is NONE, never an exception *)
val NONE = Wkt.parse "CIRCLE (0 0, 5)"
```

## API (`signature WKT`)

```sml
type geometry = GeoJson.geometry

val parse     : string -> geometry option   (* NONE on malformed input *)
val serialize : geometry -> string          (* canonical WKT *)
val fmtCoord  : real -> string               (* deterministic coordinate formatter *)
```

### Supported geometry types

`POINT`, `LINESTRING`, `POLYGON` (exterior ring plus interior rings / holes),
`MULTIPOINT`, `MULTILINESTRING`, `MULTIPOLYGON`, and `GEOMETRYCOLLECTION`
(including nested collections). Positions are 2D (`x y`) or 3D (`x y z`).

### EMPTY handling

WKT's empty geometries (`POINT EMPTY`, `LINESTRING EMPTY`, ...,
`GEOMETRYCOLLECTION EMPTY`) have no dedicated constructor in the shared AST, so
each maps to its constructor applied to an empty coordinate list, and
round-trips exactly:

| WKT                       | `GeoJson.geometry`        |
| ------------------------- | ------------------------- |
| `POINT EMPTY`             | `Point []`                |
| `LINESTRING EMPTY`        | `LineString []`           |
| `POLYGON EMPTY`           | `Polygon []`              |
| `MULTIPOINT EMPTY`        | `MultiPoint []`           |
| `MULTILINESTRING EMPTY`   | `MultiLineString []`      |
| `MULTIPOLYGON EMPTY`      | `MultiPolygon []`         |
| `GEOMETRYCOLLECTION EMPTY`| `GeometryCollection []`   |

### Conventions

- **Parsing tolerance.** Leading/trailing whitespace is ignored, interior
  whitespace is flexible (spaces, tabs, newlines; the space before `(` is
  optional), and the geometry keyword is case-insensitive (`point`, `Point`,
  `POINT`). `MULTIPOINT` accepts both `((x y), (x y))` and the bare
  `(x y, x y)` notations and normalizes to the parenthesized form.
- **Canonical serialization.** Members are separated by `", "`; coordinates
  within a position by a single space; `MULTIPOINT` members are parenthesized
  (`((x y), (x y))`). Output is deterministic and byte-identical across
  compilers.
- **Number formatting (`fmtCoord`).** Coordinates are formatted by hand, never
  via `Real.toString`:
  - an **integral** value prints with no decimal point (`30.0` → `30`);
  - a **fractional** value prints the shortest decimal that recovers the value,
    with no trailing zeros and no exponent (`30.5` → `30.5`, `3.25` → `3.25`);
  - negatives use the **ASCII** hyphen-minus `-`, never `~`.

  The formatter searches for the fewest fixed decimals (0..15) whose string
  reparses to the same `real`, so output is exact and identical under MLton and
  Poly/ML.
- **Errors.** Any malformed input — unknown geometry type, mismatched or
  missing parentheses, missing/extra/non-numeric coordinates, trailing junk —
  returns `NONE`. The parser never raises on bad input.

## Build & test

```
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
make example     # build + run examples/demo.sml
make clean
```

Both compilers run the same strict-TDD suite (67 assertions):

- **per-type parsing** of `POINT`/`LINESTRING`/`POLYGON`/`MULTIPOINT`/
  `MULTILINESTRING`/`MULTIPOLYGON`/`GEOMETRYCOLLECTION` from canonical WKT into
  the correct `GeoJson.geometry`, and serialization back to canonical WKT;
- **nested structure** — a `POLYGON` with a hole (two rings) and a
  `MULTIPOLYGON` whose second polygon has a hole parse to the right ring/poly
  counts; a mixed and a nested `GEOMETRYCOLLECTION`;
- **round-trip** — `parse → serialize → parse → serialize` is stable across
  every geometry type, compared on canonical strings;
- **whitespace / case tolerance** on input;
- **EMPTY** handling for every geometry type;
- **malformed** WKT returns `NONE` (never raises);
- **number formatting** determinism (integral coords drop `.0`, fractional
  coords keep the minimal decimal, negatives use ASCII `-`).

## Vendoring

This library depends on
[`sml-geo`](https://github.com/sjqtentacles/sml-geo), which itself vendors
[`sml-json`](https://github.com/sjqtentacles/sml-json), which vendors
[`sml-parsec`](https://github.com/sjqtentacles/sml-parsec). The **entire**
nested tree is vendored verbatim so the vendored sml-geo still resolves its own
dependencies:

```
lib/github.com/sjqtentacles/
  sml-geo/                       geo.sig, geo.sml, sml-geo.mlb, sources.mlb
  sml-json/
    src/                         json.sig, json.sml, jsonPretty.sml, json.mlb
    lib/github.com/sjqtentacles/
      sml-parsec/                stream.sig, parsec.sig, parsecfn.sml, ... (sources)
```

The relative `.mlb` references inside the vendored libraries are kept intact:
`src/wkt.mlb` references `sml-geo/sources.mlb`, which references
`../sml-json/src/json.mlb`, which references `../lib/.../sml-parsec/parsec.mlb`
— so MLton pulls in the full transitive set (parsec → json → geo → wkt). The
Poly/ML `use`-chain loads the same files in the same dependency order (see the
`test-poly` target in the `Makefile`). `sml.pkg` records `sml-geo` in its
`require` block; the json/parsec transitive requires are satisfied by the
nested vendored copies, so `smlpkg sync` can refresh the tree.

## Example

`make example` parses a handful of WKT strings into sml-geo geometries,
re-serializes them to canonical WKT, and renders each as GeoJSON through the
vendored sml-geo (output is byte-identical under MLton and Poly/ML):

```
=== sml-wkt demo ==============================================

Parse WKT into sml-geo's geometry AST, re-serialize to canonical
WKT, and render the same value as GeoJSON (vendored sml-geo).

  input : POINT (30 10)
  wkt   : POINT (30 10)
  geojson: {"type":"Point","coordinates":[30,10]}

  input : LINESTRING (30 10, 10 30, 40 40)
  wkt   : LINESTRING (30 10, 10 30, 40 40)
  geojson: {"type":"LineString","coordinates":[[30,10],[10,30],[40,40]]}

  input : MULTIPOINT (10 40, 40 30, 20 20, 30 10)
  wkt   : MULTIPOINT ((10 40), (40 30), (20 20), (30 10))
  geojson: {"type":"MultiPoint","coordinates":[[10,40],[40,30],[20,20],[30,10]]}

  ...

  input : POINT EMPTY
  wkt   : POINT EMPTY
  geojson: {"type":"Point","coordinates":[]}

===============================================================
```

### Poly/ML note

CI builds Poly/ML 5.9.1 from source rather than using the Ubuntu package
(Poly/ML 5.7.1), whose X86 code generator crashes (`asGenReg raised while
compiling`) on some code. See `.github/workflows/ci.yml`.

## License

MIT — see [LICENSE](LICENSE).
