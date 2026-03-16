// AllGoldenTests.swift – GoldenTests suite
// Top-level serialized suite to prevent cross-suite singleton interference.
// All golden test suites that touch shared state (ScrollOffsetStorage,
// scroll ID counter, RootHost) must be nested inside this suite.

import Testing

@Suite(.serialized) struct AllGoldenTests {}
