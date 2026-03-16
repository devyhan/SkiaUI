// AttributeGraph.swift – SkiaUIState module
// Eval/vite incremental evaluation DAG (Hudson 1993).
// Phase 1 (Push): source change → BFS forward → mark computed nodes out-of-date.
// Phase 2 (Pull): on evaluate → skip if up-to-date, re-evaluate if out-of-date,
//                  stop propagation if value unchanged.

import Foundation

public final class AttributeGraph: @unchecked Sendable {
    // MARK: - Node types

    enum NodeStatus {
        case upToDate
        case outOfDate
    }

    final class ComputedNode {
        var cachedValue: AnyHashableSendable?
        var status: NodeStatus = .outOfDate
        var dependencies: Set<AttributeNodeID> = []
        var dependents: Set<AttributeNodeID> = []
        var generation: UInt64 = 0
        var lastSeenGeneration: [AttributeNodeID: UInt64] = [:]
    }

    final class SourceNode {
        var generation: UInt64 = 0
        var dependents: Set<AttributeNodeID> = []
    }

    // MARK: - Storage

    private let lock = NSLock()
    private var computedNodes: [AttributeNodeID: ComputedNode] = [:]
    private var sourceNodes: [AttributeNodeID: SourceNode] = [:]

    // Evaluation context (single-threaded rendering)
    private var _evaluatingNode: AttributeNodeID?
    private var _recordedDependencies: Set<AttributeNodeID> = []

    // When true, child nodes encountered during an evaluator must also re-evaluate.
    // This ensures correctness when a parent's body creates child View instances
    // with potentially different props.
    private var _forceReevaluateChildren: Bool = false

    public init() {}

    // MARK: - Phase 1 (Push): Mark out-of-date

    /// Called when a @State value changes. Increments source generation and
    /// BFS-forward marks all reachable computed nodes as out-of-date.
    public func markSourceChanged(_ sourceID: AttributeNodeID) {
        lock.lock()
        defer { lock.unlock() }

        let source = sourceNodes[sourceID] ?? {
            let s = SourceNode()
            sourceNodes[sourceID] = s
            return s
        }()
        source.generation += 1

        // BFS forward through dependents
        var queue = Array(source.dependents)
        var visited = Set<AttributeNodeID>()
        while !queue.isEmpty {
            let nodeID = queue.removeFirst()
            guard !visited.contains(nodeID) else { continue }
            visited.insert(nodeID)

            if let computed = computedNodes[nodeID] {
                computed.status = .outOfDate
                queue.append(contentsOf: computed.dependents)
            }
        }
    }

    // MARK: - Phase 2 (Pull): Lazy evaluation

    /// Evaluates a computed node. Returns cached value if up-to-date or if
    /// dependencies haven't actually changed (pending-edge optimization).
    public func evaluate(
        _ nodeID: AttributeNodeID,
        evaluator: () -> AnyHashableSendable
    ) -> AnyHashableSendable {
        lock.lock()
        let computed = computedNodes[nodeID] ?? {
            let c = ComputedNode()
            computedNodes[nodeID] = c
            return c
        }()

        let isForced = _forceReevaluateChildren

        // Fast path: up-to-date with cached value (only if not forced by parent)
        if !isForced && computed.status == .upToDate, let cached = computed.cachedValue {
            lock.unlock()
            return cached
        }

        // Check pending edges: if all dependency generations match what we last saw
        // AND no computed dependency is out-of-date, the value can't have changed.
        if !isForced && computed.cachedValue != nil {
            var allClean = true
            for dep in computed.dependencies {
                // A computed dependency that is out-of-date might change its value
                // after re-evaluation — we can't trust our cache.
                if dep.kind == .computed,
                   let depNode = computedNodes[dep],
                   depNode.status == .outOfDate {
                    allClean = false
                    break
                }
                let currentGen = generationOf(dep)
                if currentGen != computed.lastSeenGeneration[dep] {
                    allClean = false
                    break
                }
            }
            if allClean {
                computed.status = .upToDate
                let cached = computed.cachedValue!
                lock.unlock()
                return cached
            }
        }

        // Must re-evaluate: set up evaluation context
        let outerNode = _evaluatingNode
        let outerDeps = _recordedDependencies
        let outerForce = _forceReevaluateChildren
        _evaluatingNode = nodeID
        _recordedDependencies = []
        _forceReevaluateChildren = true // children of this node must re-evaluate
        lock.unlock()

        let newValue = evaluator()

        lock.lock()
        // Update dependency edges
        let oldDeps = computed.dependencies
        let newDeps = _recordedDependencies

        // Remove edges from old dependencies that are no longer needed
        for dep in oldDeps.subtracting(newDeps) {
            removeDependentEdge(from: dep, to: nodeID)
        }
        // Add edges for new dependencies
        for dep in newDeps.subtracting(oldDeps) {
            addDependentEdge(from: dep, to: nodeID)
        }

        computed.dependencies = newDeps

        // Record current generation of each dependency
        for dep in newDeps {
            computed.lastSeenGeneration[dep] = generationOf(dep)
        }

        // Compare with cached value
        let valueChanged = computed.cachedValue != newValue
        computed.cachedValue = newValue
        computed.status = .upToDate

        if valueChanged {
            computed.generation += 1
        }

        // Restore evaluation context
        _evaluatingNode = outerNode
        _recordedDependencies = outerDeps
        _forceReevaluateChildren = outerForce
        lock.unlock()

        return newValue
    }

    // MARK: - Dependency recording

    /// Record that the currently evaluating node reads a source node.
    public func recordSourceRead(_ sourceID: AttributeNodeID) {
        lock.lock()
        defer { lock.unlock() }
        if sourceNodes[sourceID] == nil {
            sourceNodes[sourceID] = SourceNode()
        }
        if _evaluatingNode != nil {
            _recordedDependencies.insert(sourceID)
        }
    }

    /// Record that the currently evaluating node reads a computed node.
    public func recordComputedRead(_ computedID: AttributeNodeID) {
        lock.lock()
        defer { lock.unlock() }
        if _evaluatingNode != nil {
            _recordedDependencies.insert(computedID)
        }
    }

    // MARK: - Pruning

    /// Remove computed nodes that are no longer in the live set.
    /// Expands liveIDs to include transitive computed dependencies so that
    /// cached parent nodes keep their children alive even when the children's
    /// interceptors were not called (parent returned cached element).
    public func pruneDeadNodes(liveIDs: Set<AttributeNodeID>) {
        lock.lock()
        defer { lock.unlock() }

        // Expand: any computed dependency of a live node is also live.
        var expanded = liveIDs
        var queue = Array(liveIDs)
        while !queue.isEmpty {
            let id = queue.removeFirst()
            if let node = computedNodes[id] {
                for dep in node.dependencies where dep.kind == .computed {
                    if !expanded.contains(dep) {
                        expanded.insert(dep)
                        queue.append(dep)
                    }
                }
            }
        }

        let dead = Set(computedNodes.keys).subtracting(expanded)
        for id in dead {
            if let node = computedNodes[id] {
                for dep in node.dependencies {
                    removeDependentEdge(from: dep, to: id)
                }
            }
            computedNodes.removeValue(forKey: id)
        }
    }

    /// Reset all state (for testing).
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        computedNodes.removeAll()
        sourceNodes.removeAll()
        _evaluatingNode = nil
        _recordedDependencies = []
        _forceReevaluateChildren = false
    }

    // MARK: - Internal helpers

    /// Get the generation of any node (source or computed).
    /// Must be called with lock held.
    private func generationOf(_ nodeID: AttributeNodeID) -> UInt64 {
        switch nodeID.kind {
        case .source:
            return sourceNodes[nodeID]?.generation ?? 0
        case .computed:
            return computedNodes[nodeID]?.generation ?? 0
        }
    }

    /// Add a dependent edge from `dep` to `dependent`.
    /// Must be called with lock held.
    private func addDependentEdge(from dep: AttributeNodeID, to dependent: AttributeNodeID) {
        switch dep.kind {
        case .source:
            sourceNodes[dep]?.dependents.insert(dependent)
        case .computed:
            computedNodes[dep]?.dependents.insert(dependent)
        }
    }

    /// Remove a dependent edge from `dep` to `dependent`.
    /// Must be called with lock held.
    private func removeDependentEdge(from dep: AttributeNodeID, to dependent: AttributeNodeID) {
        switch dep.kind {
        case .source:
            sourceNodes[dep]?.dependents.remove(dependent)
        case .computed:
            computedNodes[dep]?.dependents.remove(dependent)
        }
    }
}
