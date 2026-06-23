(* support.sml -- shared helpers for the sml-wkt tests.

   WKT carries coordinate numbers (reals), and `Real.toString` is NOT
   byte-identical across MLton and Poly/ML. So every comparison of parsed
   geometry goes through `Wkt.serialize`, which formats coordinates with our
   own deterministic number formatter (`Wkt.fmtCoord`). That keeps the suite
   compiler-independent: we assert on canonical WKT strings, never on
   `Real.toString`.

   `approxPos` is a structural coordinate comparison with an explicit epsilon,
   used where we want to assert numeric values directly rather than via the
   serialized form. *)

structure Support =
struct
  structure G = GeoJson

  val eps = 1E~9

  (* Compare two positions (coordinate lists) up to a small tolerance. *)
  fun approxPos (a : real list, b : real list) =
    length a = length b
    andalso ListPair.all (fn (x, y) => Real.abs (x - y) <= eps) (a, b)

  (* Assert that `parse src` yields a geometry whose canonical serialization is
     exactly `expected`. *)
  fun checkParse name (src, expected) =
    case Wkt.parse src of
        SOME g => Harness.checkString name (expected, Wkt.serialize g)
      | NONE => Harness.check name false

  (* Assert that `parse src` returns NONE (malformed input). *)
  fun checkNone name src =
    Harness.check name (case Wkt.parse src of NONE => true | SOME _ => false)

  (* Assert that serializing `g` yields exactly `expected`. *)
  fun checkSerialize name (g, expected) =
    Harness.checkString name (expected, Wkt.serialize g)

  (* parse -> serialize -> parse -> serialize is stable, and equals the first
     serialization. *)
  fun checkRoundTrip name src =
    case Wkt.parse src of
        NONE => Harness.check (name ^ " (first parse)") false
      | SOME g1 =>
          let
            val s1 = Wkt.serialize g1
          in
            case Wkt.parse s1 of
                NONE => Harness.check (name ^ " (reparse)") false
              | SOME g2 => Harness.checkString name (s1, Wkt.serialize g2)
          end
end
