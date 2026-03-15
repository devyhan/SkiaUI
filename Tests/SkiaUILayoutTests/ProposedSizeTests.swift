// ProposedSizeTests.swift – SkiaUILayout test suite
// Tests for ProposedSize type and Constraints bridge.

import Testing
@testable import SkiaUILayout
import SkiaUIElement

@Suite struct ProposedSizeTests {

    // MARK: - ProposedSize creation and sentinels

    @Test func zeroSentinel() {
        let p = ProposedSize.zero
        #expect(p.width == 0)
        #expect(p.height == 0)
    }

    @Test func unspecifiedSentinel() {
        let p = ProposedSize.unspecified
        #expect(p.width == nil)
        #expect(p.height == nil)
    }

    @Test func infinitySentinel() {
        let p = ProposedSize.infinity
        #expect(p.width == .infinity)
        #expect(p.height == .infinity)
    }

    @Test func customValues() {
        let p = ProposedSize(width: 100, height: 200)
        #expect(p.width == 100)
        #expect(p.height == 200)
    }

    @Test func partialNil() {
        let p = ProposedSize(width: 50, height: nil)
        #expect(p.width == 50)
        #expect(p.height == nil)
    }

    @Test func equatable() {
        #expect(ProposedSize(width: 10, height: 20) == ProposedSize(width: 10, height: 20))
        #expect(ProposedSize(width: nil, height: nil) == ProposedSize.unspecified)
        #expect(ProposedSize(width: 10, height: 20) != ProposedSize(width: 10, height: 30))
    }

    // MARK: - Constraints ↔ ProposedSize bridge

    @Test func constraintsToProposedSize() {
        let c = Constraints(maxWidth: 300, maxHeight: 400)
        let p = c.proposedSize
        #expect(p.width == 300)
        #expect(p.height == 400)
    }

    @Test func unconstrainedToProposedSize() {
        let c = Constraints.unconstrained
        let p = c.proposedSize
        #expect(p.width == nil)  // infinity → nil
        #expect(p.height == nil)
    }

    @Test func proposedSizeToConstraints() {
        let p = ProposedSize(width: 200, height: 150)
        let c = Constraints(proposed: p)
        #expect(c.minWidth == 0)
        #expect(c.maxWidth == 200)
        #expect(c.minHeight == 0)
        #expect(c.maxHeight == 150)
    }

    @Test func unspecifiedToConstraints() {
        let p = ProposedSize.unspecified
        let c = Constraints(proposed: p)
        #expect(c.maxWidth == .infinity)
        #expect(c.maxHeight == .infinity)
    }

    // MARK: - ProposedSize-based layout entry point

    @Test func layoutViaProposalMatchesConstraints() {
        let engine = LayoutEngine()
        let el = Element.text("Hello", .init(fontSize: 14))

        let viaConstraints = engine.layout(el, constraints: Constraints(maxWidth: 200, maxHeight: 100))
        let viaProposal = engine.layout(el, proposal: ProposedSize(width: 200, height: 100))

        #expect(viaConstraints.width == viaProposal.width)
        #expect(viaConstraints.height == viaProposal.height)
    }
}
