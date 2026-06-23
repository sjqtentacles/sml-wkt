# sml-wkt build
#
#   make            build the test binary with MLton (default)
#   make test       build + run tests under MLton
#   make test-poly  run tests under Poly/ML (use-and-run; no link step)
#   make all-tests  run the suite under both compilers
#   make example    build + run examples/demo.sml
#   make clean      remove build artifacts
#
# Layout B (dependent): own sources live in src/; sml-geo is vendored under
# lib/ and loaded first. sml-geo itself vendors sml-json, which vendors
# sml-parsec, so the WHOLE nested tree is vendored and loaded in dependency
# order (parsec -> json -> geo -> wkt).

MLTON   ?= mlton
POLY    ?= poly
BIN     := bin

GEODIR    := lib/github.com/sjqtentacles/sml-geo
JSONDIR   := lib/github.com/sjqtentacles/sml-json/src
PARSECDIR := lib/github.com/sjqtentacles/sml-json/lib/github.com/sjqtentacles/sml-parsec

TEST_MLB := test/sources.mlb
SRCS    := $(wildcard $(PARSECDIR)/* $(JSONDIR)/* $(GEODIR)/* src/* test/*.sml) $(TEST_MLB)

.PHONY: all test poly test-poly all-tests example clean

all: $(BIN)/test-mlton

example: $(BIN)/demo
	./$(BIN)/demo

$(BIN)/demo: $(SRCS) examples/demo.sml examples/sources.mlb | $(BIN)
	$(MLTON) -output $@ examples/sources.mlb

$(BIN)/test-mlton: $(SRCS) | $(BIN)
	$(MLTON) -output $@ $(TEST_MLB)

test: $(BIN)/test-mlton
	$(BIN)/test-mlton

# Poly/ML has no native .mlb support; the suite runs at top level and exits on
# its own. Load the FULL vendored dependency tree first, in dependency order:
# sml-parsec, then sml-json, then sml-geo, then the wkt sources, then the test
# driver.
poly test-poly:
	printf 'use "$(PARSECDIR)/stream.sig";\nuse "$(PARSECDIR)/parsec.sig";\nuse "$(PARSECDIR)/parsecfn.sml";\nuse "$(PARSECDIR)/charstream.sml";\nuse "$(PARSECDIR)/charparseccore.sml";\nuse "$(PARSECDIR)/charparsec.sig";\nuse "$(PARSECDIR)/charparsec.sml";\nuse "$(PARSECDIR)/expr.sig";\nuse "$(PARSECDIR)/exprfn.sml";\nuse "$(PARSECDIR)/charexpr.sml";\nuse "$(PARSECDIR)/tokenstream.sml";\nuse "$(JSONDIR)/json.sig";\nuse "$(JSONDIR)/json.sml";\nuse "$(JSONDIR)/jsonPretty.sml";\nuse "$(GEODIR)/geo.sig";\nuse "$(GEODIR)/geo.sml";\nuse "src/wkt.sig";\nuse "src/wkt.sml";\nuse "test/harness.sml";\nuse "test/support.sml";\nuse "test/test_point.sml";\nuse "test/test_linestring.sml";\nuse "test/test_polygon.sml";\nuse "test/test_multi.sml";\nuse "test/test_collection.sml";\nuse "test/test_roundtrip.sml";\nuse "test/test_malformed.sml";\nuse "test/entry.sml";\nuse "test/main.sml";\n' | $(POLY) -q --error-exit

all-tests: test test-poly

$(BIN):
	mkdir -p $(BIN)

clean:
	rm -f $(BIN)/test-mlton $(BIN)/demo
