import Foundation
import SwiftData
import CoreGraphics

// MARK: - StackResolver

/// Computes auto-category clusters of free polaroids and reconciles
/// `PolaroidStack` rows accordingly. Idempotent: calling twice on
/// unchanged data produces no further mutations.
struct StackResolver: Sendable {

    // MARK: Tunables

    static let defaultRadius: Double = 500.0

    // MARK: Resolve

    func resolveAutoStacks(in context: ModelContext) throws {
        let allPolaroids = try context.fetch(FetchDescriptor<PolaroidEvidence>())
        let allStacks = try context.fetch(FetchDescriptor<PolaroidStack>())

        // Stable iteration order keeps clustering deterministic.
        let sortedPolaroids = allPolaroids.sorted { $0.id.uuidString < $1.id.uuidString }

        let eligible = sortedPolaroids

        // Track polaroids assigned to a surviving auto-stack this pass.
        var assignedPolaroidIDs: Set<UUID> = []

        // Group eligible polaroids by category (raw value as key).
        let byCategory: [String: [PolaroidEvidence]] = Dictionary(grouping: eligible) { $0.categoryRaw }

        for (categoryRaw, group) in byCategory {
            let clusters = clusterPolaroids(group, radius: Self.defaultRadius)

            for cluster in clusters where cluster.count >= 3 {
                let category = EvidenceCategory(rawValue: categoryRaw)
                let chosenStack = pickOrCreateAutoStack(
                    for: cluster,
                    category: category,
                    in: context
                )

                for polaroid in cluster {
                    assignedPolaroidIDs.insert(polaroid.id)
                    if polaroid.stack?.id != chosenStack.id {
                        polaroid.stack = chosenStack
                    }
                }

                let c = centroid(of: cluster)
                let cx = Double(c.x)
                let cy = Double(c.y)
                if chosenStack.canvasX != cx { chosenStack.canvasX = cx }
                if chosenStack.canvasY != cy { chosenStack.canvasY = cy }
                if chosenStack.categoryRaw != categoryRaw {
                    chosenStack.categoryRaw = categoryRaw
                }
            }
        }

        // Step f: polaroids previously in an auto-stack but no longer in
        // a 3+ cluster get detached.
        for polaroid in eligible where !assignedPolaroidIDs.contains(polaroid.id) {
            if let s = polaroid.stack, s.kind == .autoCategory {
                polaroid.stack = nil
            }
        }

        // Step g: delete any auto-stack with fewer than 2 polaroids.
        // Recount from the polaroid side to avoid relying on cached
        // inverse arrays mid-resolution.
        let refreshedPolaroids = try context.fetch(FetchDescriptor<PolaroidEvidence>())
        let countByStack: [UUID: Int] = refreshedPolaroids.reduce(into: [:]) { dict, p in
            if let id = p.stack?.id { dict[id, default: 0] += 1 }
        }

        for stack in allStacks where stack.kind == .autoCategory {
            let count = countByStack[stack.id] ?? 0
            if count < 2 {
                context.delete(stack)
            }
        }
    }

    // MARK: Clustering

    /// Greedy single-link clustering: pick a seed, transitively grow the
    /// cluster to include every polaroid within `radius` of any current
    /// member, then repeat with the remaining polaroids.
    func clusterPolaroids(_ polaroids: [PolaroidEvidence], radius: Double) -> [[PolaroidEvidence]] {
        var remaining = polaroids
        var clusters: [[PolaroidEvidence]] = []

        while !remaining.isEmpty {
            let seed = remaining.removeFirst()
            var cluster: [PolaroidEvidence] = [seed]
            var grew = true

            while grew {
                grew = false
                var stillRemaining: [PolaroidEvidence] = []
                for candidate in remaining {
                    if cluster.contains(where: { distance($0, candidate) <= radius }) {
                        cluster.append(candidate)
                        grew = true
                    } else {
                        stillRemaining.append(candidate)
                    }
                }
                remaining = stillRemaining
            }

            clusters.append(cluster)
        }

        return clusters
    }

    func centroid(of polaroids: [PolaroidEvidence]) -> CGPoint {
        guard !polaroids.isEmpty else { return .zero }
        let count = Double(polaroids.count)
        let sumX = polaroids.reduce(0.0) { $0 + $1.canvasX }
        let sumY = polaroids.reduce(0.0) { $0 + $1.canvasY }
        return CGPoint(x: sumX / count, y: sumY / count)
    }

    // MARK: Helpers

    private func distance(_ a: PolaroidEvidence, _ b: PolaroidEvidence) -> Double {
        let dx = a.canvasX - b.canvasX
        let dy = a.canvasY - b.canvasY
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Reuse the existing autoCategory stack with the most cluster members
    /// (if any), otherwise insert a new one.
    private func pickOrCreateAutoStack(
        for cluster: [PolaroidEvidence],
        category: EvidenceCategory?,
        in context: ModelContext
    ) -> PolaroidStack {
        var counts: [UUID: (stack: PolaroidStack, count: Int)] = [:]
        for polaroid in cluster {
            if let s = polaroid.stack, s.kind == .autoCategory {
                counts[s.id, default: (s, 0)].count += 1
            }
        }

        if let winner = counts.values.max(by: { $0.count < $1.count })?.stack {
            return winner
        }

        let newStack = PolaroidStack(
            kind: .autoCategory,
            category: category,
            position: centroid(of: cluster)
        )
        context.insert(newStack)
        return newStack
    }
}
