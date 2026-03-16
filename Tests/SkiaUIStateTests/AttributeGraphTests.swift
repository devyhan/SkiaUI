// AttributeGraphTests.swift – SkiaUIState test suite
// Tests for Eval/vite AttributeGraph incremental evaluation.

import Testing
@testable import SkiaUIState

@Suite struct AttributeGraphTests {
    private func makeGraph() -> AttributeGraph {
        let graph = AttributeGraph()
        return graph
    }

    @Test func sourceChangeMarksComputedOutOfDate() {
        let graph = makeGraph()
        let sourceID = AttributeNodeID(sourcePath: [0])
        let computedID = AttributeNodeID(viewPath: [0])

        // First evaluation: establishes dependency source → computed
        var evalCount = 0
        _ = graph.evaluate(computedID) {
            graph.recordSourceRead(sourceID)
            evalCount += 1
            return AnyHashableSendable("v1")
        }
        #expect(evalCount == 1)

        // Mark source changed → computed becomes out-of-date
        graph.markSourceChanged(sourceID)

        // Re-evaluate: should call evaluator again
        _ = graph.evaluate(computedID) {
            graph.recordSourceRead(sourceID)
            evalCount += 1
            return AnyHashableSendable("v2")
        }
        #expect(evalCount == 2)
    }

    @Test func upToDateReturnsCache() {
        let graph = makeGraph()
        let sourceID = AttributeNodeID(sourcePath: [0])
        let computedID = AttributeNodeID(viewPath: [0])

        var evalCount = 0
        let v1 = graph.evaluate(computedID) {
            graph.recordSourceRead(sourceID)
            evalCount += 1
            return AnyHashableSendable("cached")
        }
        #expect(evalCount == 1)

        // No source change → should return cache without calling evaluator
        let v2 = graph.evaluate(computedID) {
            graph.recordSourceRead(sourceID)
            evalCount += 1
            return AnyHashableSendable("should not run")
        }
        #expect(evalCount == 1)
        #expect(v1 == v2)
    }

    @Test func pendingEdgeTriggersReevaluation() {
        let graph = makeGraph()
        let sourceID = AttributeNodeID(sourcePath: [0])
        let computedID = AttributeNodeID(viewPath: [0])

        _ = graph.evaluate(computedID) {
            graph.recordSourceRead(sourceID)
            return AnyHashableSendable("v1")
        }

        graph.markSourceChanged(sourceID)

        var evalCount = 0
        let result = graph.evaluate(computedID) {
            graph.recordSourceRead(sourceID)
            evalCount += 1
            return AnyHashableSendable("v2")
        }
        #expect(evalCount == 1)
        let value: String? = result.unwrap()
        #expect(value == "v2")
    }

    @Test func noPendingSkipsReevaluation() {
        let graph = makeGraph()
        let sourceID = AttributeNodeID(sourcePath: [0])
        let parentID = AttributeNodeID(viewPath: [0])
        let childID = AttributeNodeID(viewPath: [0, 0])

        // Establish: source → parent → child (parent depends on source, child depends on parent)
        _ = graph.evaluate(parentID) {
            graph.recordSourceRead(sourceID)
            return AnyHashableSendable("same")
        }
        _ = graph.evaluate(childID) {
            graph.recordComputedRead(parentID)
            return AnyHashableSendable("child")
        }

        // Change source
        graph.markSourceChanged(sourceID)

        // Re-evaluate parent: returns SAME value → generation unchanged
        _ = graph.evaluate(parentID) {
            graph.recordSourceRead(sourceID)
            return AnyHashableSendable("same") // same value!
        }

        // Re-evaluate child: parent's generation didn't change → skip
        var childEvalCount = 0
        _ = graph.evaluate(childID) {
            graph.recordComputedRead(parentID)
            childEvalCount += 1
            return AnyHashableSendable("child2")
        }
        #expect(childEvalCount == 0) // skipped because parent value unchanged
    }

    @Test func indirectionEdgeUpdate() {
        let graph = makeGraph()
        let sourceA = AttributeNodeID(sourcePath: [0])
        let sourceB = AttributeNodeID(sourcePath: [1])
        let computedID = AttributeNodeID(viewPath: [0])

        // First eval: depends on sourceA
        _ = graph.evaluate(computedID) {
            graph.recordSourceRead(sourceA)
            return AnyHashableSendable("a")
        }

        // Change sourceA → mark computed out-of-date
        graph.markSourceChanged(sourceA)

        // Re-eval: now depends on sourceB instead of sourceA
        _ = graph.evaluate(computedID) {
            graph.recordSourceRead(sourceB)
            return AnyHashableSendable("b")
        }

        // Change sourceA → should NOT affect computed (no longer depends on it)
        graph.markSourceChanged(sourceA)
        var evalCount = 0
        _ = graph.evaluate(computedID) {
            evalCount += 1
            return AnyHashableSendable("should not run")
        }
        #expect(evalCount == 0) // sourceA change has no effect

        // Change sourceB → should trigger re-eval
        graph.markSourceChanged(sourceB)
        _ = graph.evaluate(computedID) {
            graph.recordSourceRead(sourceB)
            evalCount += 1
            return AnyHashableSendable("b2")
        }
        #expect(evalCount == 1)
    }

    @Test func computedToComputedDependency() {
        let graph = makeGraph()
        let sourceID = AttributeNodeID(sourcePath: [0])
        let parentID = AttributeNodeID(viewPath: [0])
        let childID = AttributeNodeID(viewPath: [0, 0])

        _ = graph.evaluate(parentID) {
            graph.recordSourceRead(sourceID)
            return AnyHashableSendable(10)
        }
        _ = graph.evaluate(childID) {
            graph.recordComputedRead(parentID)
            return AnyHashableSendable(20)
        }

        // Change source → both should be out-of-date
        graph.markSourceChanged(sourceID)

        var parentEvalCount = 0
        var childEvalCount = 0

        _ = graph.evaluate(parentID) {
            graph.recordSourceRead(sourceID)
            parentEvalCount += 1
            return AnyHashableSendable(11) // changed value
        }
        _ = graph.evaluate(childID) {
            graph.recordComputedRead(parentID)
            childEvalCount += 1
            return AnyHashableSendable(21)
        }

        #expect(parentEvalCount == 1)
        #expect(childEvalCount == 1)
    }

    @Test func pruneDeadNodes() {
        let graph = makeGraph()
        let sourceID = AttributeNodeID(sourcePath: [0])
        let liveID = AttributeNodeID(viewPath: [0])
        let deadID = AttributeNodeID(viewPath: [1])

        _ = graph.evaluate(liveID) {
            graph.recordSourceRead(sourceID)
            return AnyHashableSendable("live")
        }
        _ = graph.evaluate(deadID) {
            graph.recordSourceRead(sourceID)
            return AnyHashableSendable("dead")
        }

        // Prune: only liveID survives
        graph.pruneDeadNodes(liveIDs: [liveID])

        // Source change → should only mark liveID
        graph.markSourceChanged(sourceID)

        var liveEvalCount = 0
        _ = graph.evaluate(liveID) {
            graph.recordSourceRead(sourceID)
            liveEvalCount += 1
            return AnyHashableSendable("live2")
        }
        #expect(liveEvalCount == 1)

        // Dead node should be fresh (no cache)
        var deadEvalCount = 0
        _ = graph.evaluate(deadID) {
            deadEvalCount += 1
            return AnyHashableSendable("new")
        }
        #expect(deadEvalCount == 1) // evaluated as new node
    }
}
