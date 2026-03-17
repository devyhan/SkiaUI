// LayoutEngine.swift – SkiaUILayout module
// ProposedSize-based layout engine for computing element geometry.

import SkiaUIElement

public struct LayoutEngine: Sendable {
    private let cache = LayoutCache()
    private let textMeasurer: any TextMeasurer

    public init(textMeasurer: any TextMeasurer = EstimatedTextMeasurer()) {
        self.textMeasurer = textMeasurer
    }

    public func clearCache() {
        cache.clear()
    }

    // Existing public API (backward compatible)
    public func layout(_ element: Element, constraints: Constraints) -> LayoutNode {
        layout(element, proposal: constraints.proposedSize)
    }

    // New ProposedSize-based public API
    public func layout(_ element: Element, proposal: ProposedSize) -> LayoutNode {
        layoutElement(element, proposal: proposal)
    }

    private func layoutElement(_ element: Element, proposal: ProposedSize) -> LayoutNode {
        let cacheKey = LayoutCache.CacheKey(element: element, proposal: proposal)
        if let cached = cache.get(cacheKey) {
            return cached
        }
        let result = computeLayout(element, proposal: proposal)
        cache.set(cacheKey, result)
        return result
    }

    private func computeLayout(_ element: Element, proposal: ProposedSize) -> LayoutNode {
        switch element {
        case .empty:
            return LayoutNode()

        case .text(let text, let props):
            let measurement = textMeasurer.measure(
                text: text,
                fontSize: props.fontSize,
                fontWeight: props.fontWeight,
                fontFamily: props.fontFamily,
                maxWidth: proposal.width,
                lineLimit: props.lineLimit
            )
            let w: Float
            if let pw = proposal.width {
                w = min(measurement.width, pw)
            } else {
                w = measurement.width
            }
            let h: Float
            if let ph = proposal.height {
                h = min(measurement.height, ph)
            } else {
                h = measurement.height
            }
            return LayoutNode(width: max(0, w), height: max(0, h))

        case .rectangle:
            let w = proposal.width ?? 0
            let h = proposal.height ?? 0
            return LayoutNode(width: w, height: h)

        case .spacer(let minLength):
            // Spacer is maximally flexible: accepts proposed size, clamped to minLength
            let minLen = minLength ?? 0
            let w = max(minLen, proposal.width ?? 0)
            let h = max(minLen, proposal.height ?? 0)
            return LayoutNode(width: w, height: h)

        case .image:
            // Image uses proposed size if available, otherwise defaults to 100×100
            let w = proposal.width ?? 100
            let h = proposal.height ?? 100
            return LayoutNode(width: w, height: h)

        case .container(let props, let children):
            let strategy: any LayoutStrategy = switch props.layout {
            case .vstack(let spacing, let alignment):
                VStackLayout(spacing: spacing, alignment: alignment)
            case .hstack(let spacing, let alignment):
                HStackLayout(spacing: spacing, alignment: alignment)
            case .zstack(let alignment):
                ZStackLayout(alignment: alignment)
            case .scroll(let axis, _):
                ScrollViewLayout(axis: axis)
            }
            return strategy.layout(children: children, proposal: proposal) { child, p in
                layoutElement(child, proposal: p)
            }

        case .modified(let inner, let modifier):
            return layoutModified(inner, modifier: modifier, proposal: proposal)
        }
    }

    private func applyFontToElement(_ element: Element, size: Float, weight: Int, family: String? = nil) -> Element {
        switch element {
        case .text(let text, var props):
            props.fontSize = size
            props.fontWeight = weight
            if let family { props.fontFamily = family }
            return .text(text, props)
        case .modified(let inner, let mod):
            return .modified(applyFontToElement(inner, size: size, weight: weight, family: family), mod)
        default:
            return element
        }
    }

    private func layoutModified(_ element: Element, modifier: Element.Modifier, proposal: ProposedSize) -> LayoutNode {
        switch modifier {
        case .padding(let top, let leading, let bottom, let trailing):
            let innerProposal = ProposedSize(
                width: proposal.width.map { max(0, $0 - leading - trailing) },
                height: proposal.height.map { max(0, $0 - top - bottom) }
            )
            var inner = layoutElement(element, proposal: innerProposal)
            inner.x += leading
            inner.y += top
            let totalWidth = inner.width + leading + trailing
            let totalHeight = inner.height + top + bottom
            return LayoutNode(width: totalWidth, height: totalHeight, children: [inner])

        case .frame(let fp):
            // Resolve proposal per axis using min/ideal/max
            let resolvedW = resolveFrame(proposal: proposal.width, min: fp.minWidth, ideal: fp.idealWidth, max: fp.maxWidth)
            let resolvedH = resolveFrame(proposal: proposal.height, min: fp.minHeight, ideal: fp.idealHeight, max: fp.maxHeight)
            let childProposal = ProposedSize(width: resolvedW, height: resolvedH)
            var child = layoutElement(element, proposal: childProposal)
            // Frame size = child size clamped to [min, max]
            let frameW = clampFrame(child.width, min: fp.minWidth, max: fp.maxWidth)
            let frameH = clampFrame(child.height, min: fp.minHeight, max: fp.maxHeight)
            let hAlign = fp.alignment % 3  // 0=leading, 1=center, 2=trailing
            let vAlign = fp.alignment / 3  // 0=top, 1=center, 2=bottom
            child.x = switch hAlign {
            case 0: Float(0)
            case 2: frameW - child.width
            default: (frameW - child.width) / 2
            }
            child.y = switch vAlign {
            case 0: Float(0)
            case 2: frameH - child.height
            default: (frameH - child.height) / 2
            }
            return LayoutNode(width: frameW, height: frameH, children: [child])

        case .font(let size, let weight, let family):
            let patched = applyFontToElement(element, size: size, weight: weight, family: family)
            return layoutElement(patched, proposal: proposal)

        case .layoutPriority:
            // Transparent: priority only affects stack distribution, not individual sizing
            return layoutElement(element, proposal: proposal)

        case .fixedSize(let horizontal, let vertical):
            let p = ProposedSize(
                width: horizontal ? nil : proposal.width,
                height: vertical ? nil : proposal.height
            )
            return layoutElement(element, proposal: p)

        case .background, .foregroundColor, .onTap, .onLongPress, .onDrag,
             .accessibilityLabel, .accessibilityRole, .accessibilityHint, .accessibilityHidden,
             .drawingGroup:
            return layoutElement(element, proposal: proposal)
        }
    }

    /// Resolve a frame axis: if proposal is nil, use ideal; clamp result to [min, max].
    private func resolveFrame(proposal: Float?, min: Float?, ideal: Float?, max: Float?) -> Float? {
        // If no frame constraints on this axis, pass through the proposal
        if min == nil && ideal == nil && max == nil { return proposal }
        let value: Float
        if let p = proposal {
            value = p
        } else {
            // nil proposal → use ideal size
            value = ideal ?? 0
        }
        var result = value
        if let lo = min { result = Swift.max(result, lo) }
        if let hi = max { result = Swift.min(result, hi) }
        return result
    }

    /// Clamp a dimension to [min, max] if specified.
    private func clampFrame(_ value: Float, min: Float?, max: Float?) -> Float {
        var result = value
        if let lo = min { result = Swift.max(result, lo) }
        if let hi = max { result = Swift.min(result, hi) }
        return result
    }
}

// MARK: - Layout Cache

/// Reference-type cache for layout results, keyed by (Element, ProposedSize).
/// Uses a class to avoid mutating self issues in LayoutStrategy measure closures.
final class LayoutCache: @unchecked Sendable {
    struct CacheKey: Hashable {
        let element: Element
        let proposal: ProposedSize
    }

    private var entries: [CacheKey: LayoutNode] = [:]

    func get(_ key: CacheKey) -> LayoutNode? {
        entries[key]
    }

    func set(_ key: CacheKey, _ value: LayoutNode) {
        entries[key] = value
    }

    func clear() {
        entries.removeAll()
    }
}
