// AllRuntimeTests.swift – SkiaUIRuntime test suite
// Top-level serialized suite to prevent cross-suite singleton interference.
// All runtime test suites that touch shared state (StateStorage, DependencyRecorder,
// ScrollOffsetStorage, tapHandlers) must be nested inside this suite.

import Testing

@Suite(.serialized) struct AllRuntimeTests {}
