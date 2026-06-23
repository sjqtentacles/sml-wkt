(* entry.sml -- runs every suite and exits with a status code. *)

fun runAllSuites () =
  ( Harness.reset ()
  ; PointTests.run ()
  ; LineStringTests.run ()
  ; PolygonTests.run ()
  ; MultiTests.run ()
  ; CollectionTests.run ()
  ; RoundTripTests.run ()
  ; MalformedTests.run ()
  ; Harness.run () )

fun main () =
  OS.Process.exit
    (if runAllSuites () then OS.Process.success else OS.Process.failure)
