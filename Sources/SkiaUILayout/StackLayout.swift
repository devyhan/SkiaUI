// StackLayout.swift – SkiaUILayout module
// VStack and HStack layout strategies with ProposedSize-based layout.

import SkiaUIElement

public struct VStackLayout: LayoutStrategy, Sendable {
    public let spacing: Float
    public let alignment: Int // 0=leading, 1=center, 2=trailing

    public init(spacing: Float = 8, alignment: Int = 1) {
        self.spacing = spacing; self.alignment = alignment
    }

    public func layout(children: [Element], proposal: ProposedSize, measure: (Element, ProposedSize) -> LayoutNode) -> LayoutNode {
        guard !children.isEmpty else { return LayoutNode() }

        let totalSpacing = spacing * Float(children.count - 1)

        // Extract priority and compute flexibility for each child
        let priorities = children.map { Self.extractPriority(from: $0) }

        // Measure min and max sizes for each child along major axis
        var minSizes = [Float](repeating: 0, count: children.count)
        var maxSizes = [Float](repeating: 0, count: children.count)
        for i in 0..<children.count {
            let minNode = measure(children[i], ProposedSize(width: proposal.width, height: 0))
            let maxNode = measure(children[i], ProposedSize(width: proposal.width, height: .infinity))
            minSizes[i] = minNode.height
            maxSizes[i] = maxNode.height
        }

        // Sort indices by priority (descending), then flexibility (ascending) within same priority
        let sortedIndices = (0..<children.count).sorted { a, b in
            if priorities[a] != priorities[b] { return priorities[a] > priorities[b] }
            let flexA = maxSizes[a] - minSizes[a]
            let flexB = maxSizes[b] - minSizes[b]
            return flexA < flexB
        }

        // Group by priority
        var allocatedSizes = [Float](repeating: 0, count: children.count)
        let totalAvailable = (proposal.height ?? .infinity) - totalSpacing

        // Track remaining space
        var remaining = max(0, totalAvailable)

        // Subtract all minSizes first
        let totalMinSize = minSizes.reduce(Float(0), +)
        remaining = max(0, totalAvailable - totalMinSize)

        // Distribute extra space by priority groups
        var processed = Set<Int>()
        var currentGroupStart = 0

        while currentGroupStart < sortedIndices.count {
            let currentPriority = priorities[sortedIndices[currentGroupStart]]
            // Find end of this priority group
            var currentGroupEnd = currentGroupStart
            while currentGroupEnd < sortedIndices.count && priorities[sortedIndices[currentGroupEnd]] == currentPriority {
                currentGroupEnd += 1
            }

            let groupIndices = Array(sortedIndices[currentGroupStart..<currentGroupEnd])

            // Calculate how much extra each member of this group can take
            var groupRemaining = remaining
            var groupProcessed = [Int]()

            // Sort group by flexibility (ascending) - less flexible first
            let groupSorted = groupIndices.sorted { a, b in
                (maxSizes[a] - minSizes[a]) < (maxSizes[b] - minSizes[b])
            }

            var unprocessedInGroup = groupSorted.count
            for idx in groupSorted {
                let share = groupRemaining / Float(unprocessedInGroup)
                let extra = min(share, maxSizes[idx] - minSizes[idx])
                allocatedSizes[idx] = minSizes[idx] + max(0, extra)
                groupRemaining -= max(0, extra)
                unprocessedInGroup -= 1
                groupProcessed.append(idx)
            }

            remaining = groupRemaining
            processed.formUnion(groupProcessed)
            currentGroupStart = currentGroupEnd
        }

        // Measure children at allocated sizes
        var childNodes = [LayoutNode](repeating: LayoutNode(), count: children.count)
        for i in 0..<children.count {
            let childProposal = ProposedSize(width: proposal.width, height: allocatedSizes[i])
            childNodes[i] = measure(children[i], childProposal)
        }

        // Position children
        var y: Float = 0
        let maxWidth = childNodes.reduce(Float(0)) { max($0, $1.width) }
        let containerWidth: Float
        if let pw = proposal.width {
            containerWidth = min(maxWidth, pw)
        } else {
            containerWidth = maxWidth
        }

        for i in 0..<childNodes.count {
            childNodes[i].y = y
            switch alignment {
            case 0: childNodes[i].x = 0
            case 2: childNodes[i].x = containerWidth - childNodes[i].width
            default: childNodes[i].x = (containerWidth - childNodes[i].width) / 2
            }
            y += childNodes[i].height
            if i < childNodes.count - 1 { y += spacing }
        }

        let totalHeight = y
        return LayoutNode(width: containerWidth, height: totalHeight, children: childNodes)
    }

    static func extractPriority(from element: Element) -> Double {
        switch element {
        case .spacer: return -.infinity
        case .modified(_, .layoutPriority(let p)): return p
        case .modified(let inner, _): return extractPriority(from: inner)
        default: return 0
        }
    }
}

public struct HStackLayout: LayoutStrategy, Sendable {
    public let spacing: Float
    public let alignment: Int // 0=top, 1=center, 2=bottom

    public init(spacing: Float = 8, alignment: Int = 1) {
        self.spacing = spacing; self.alignment = alignment
    }

    public func layout(children: [Element], proposal: ProposedSize, measure: (Element, ProposedSize) -> LayoutNode) -> LayoutNode {
        guard !children.isEmpty else { return LayoutNode() }

        let totalSpacing = spacing * Float(children.count - 1)

        let priorities = children.map { VStackLayout.extractPriority(from: $0) }

        // Measure min and max sizes for each child along major axis (width)
        var minSizes = [Float](repeating: 0, count: children.count)
        var maxSizes = [Float](repeating: 0, count: children.count)
        for i in 0..<children.count {
            let minNode = measure(children[i], ProposedSize(width: 0, height: proposal.height))
            let maxNode = measure(children[i], ProposedSize(width: .infinity, height: proposal.height))
            minSizes[i] = minNode.width
            maxSizes[i] = maxNode.width
        }

        // Sort indices by priority (descending), then flexibility (ascending)
        let sortedIndices = (0..<children.count).sorted { a, b in
            if priorities[a] != priorities[b] { return priorities[a] > priorities[b] }
            let flexA = maxSizes[a] - minSizes[a]
            let flexB = maxSizes[b] - minSizes[b]
            return flexA < flexB
        }

        var allocatedSizes = [Float](repeating: 0, count: children.count)
        let totalAvailable = (proposal.width ?? .infinity) - totalSpacing

        var remaining = max(0, totalAvailable)
        let totalMinSize = minSizes.reduce(Float(0), +)
        remaining = max(0, totalAvailable - totalMinSize)

        var processed = Set<Int>()
        var currentGroupStart = 0

        while currentGroupStart < sortedIndices.count {
            let currentPriority = priorities[sortedIndices[currentGroupStart]]
            var currentGroupEnd = currentGroupStart
            while currentGroupEnd < sortedIndices.count && priorities[sortedIndices[currentGroupEnd]] == currentPriority {
                currentGroupEnd += 1
            }

            let groupIndices = Array(sortedIndices[currentGroupStart..<currentGroupEnd])

            let groupSorted = groupIndices.sorted { a, b in
                (maxSizes[a] - minSizes[a]) < (maxSizes[b] - minSizes[b])
            }

            var groupRemaining = remaining
            var unprocessedInGroup = groupSorted.count
            var groupProcessed = [Int]()

            for idx in groupSorted {
                let share = groupRemaining / Float(unprocessedInGroup)
                let extra = min(share, maxSizes[idx] - minSizes[idx])
                allocatedSizes[idx] = minSizes[idx] + max(0, extra)
                groupRemaining -= max(0, extra)
                unprocessedInGroup -= 1
                groupProcessed.append(idx)
            }

            remaining = groupRemaining
            processed.formUnion(groupProcessed)
            currentGroupStart = currentGroupEnd
        }

        // Measure children at allocated sizes
        var childNodes = [LayoutNode](repeating: LayoutNode(), count: children.count)
        for i in 0..<children.count {
            let childProposal = ProposedSize(width: allocatedSizes[i], height: proposal.height)
            childNodes[i] = measure(children[i], childProposal)
        }

        // Position children
        var x: Float = 0
        let maxHeight = childNodes.reduce(Float(0)) { max($0, $1.height) }
        let containerHeight: Float
        if let ph = proposal.height {
            containerHeight = min(maxHeight, ph)
        } else {
            containerHeight = maxHeight
        }

        for i in 0..<childNodes.count {
            childNodes[i].x = x
            switch alignment {
            case 0: childNodes[i].y = 0
            case 2: childNodes[i].y = containerHeight - childNodes[i].height
            default: childNodes[i].y = (containerHeight - childNodes[i].height) / 2
            }
            x += childNodes[i].width
            if i < childNodes.count - 1 { x += spacing }
        }

        let totalWidth = x
        return LayoutNode(width: totalWidth, height: containerHeight, children: childNodes)
    }
}
