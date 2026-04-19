import Foundation
import Observation

// MARK: - APM Mode

enum APMMode: String, CaseIterable, Hashable {
    case peak, offPeak

    var label: String {
        switch self {
        case .peak: return "Peak"
        case .offPeak: return "Off-peak"
        }
    }
}

// MARK: - Planned Route

/// Routing-service result. Lives alongside `RouteResult` from the model layer
/// rather than replacing it: this type carries explicit `isStub` flags per
/// segment so the UI can show "TBD — needs measurement" badges where the
/// underlying graph data is incomplete.
struct PlannedRoute: Hashable {
    let segments: [PlannedSegment]
    let verdict: RouteVerdict

    var totalSeconds: Double? {
        let times = segments.compactMap(\.timeSeconds)
        guard times.count == segments.count else { return nil }
        return times.reduce(0, +)
    }

    var hasAnyStub: Bool {
        segments.contains(where: \.isStub)
    }
}

struct PlannedSegment: Identifiable, Hashable {
    let id = UUID()
    let kind: EdgeKind
    /// Display label of the originating endpoint (bay or graph-node label).
    let from: String
    /// Display label of the terminating endpoint.
    let to: String
    /// Stable id of the originating endpoint — bay id for gate endpoints,
    /// graph-node id (e.g. "CONCOURSE_A_HUB") for routing nodes. Used by the
    /// schematic map to look up coordinates without parsing display labels.
    let fromId: String
    /// Stable id of the terminating endpoint.
    let toId: String
    /// nil when the underlying graph edge has no measured time yet (stub).
    let timeSeconds: Double?
    let isStub: Bool
    /// Free-text label shown beneath the segment (e.g. "APM ride", source citation).
    let detail: String?
}

// MARK: - Route Engine

@Observable
final class RouteEngine {

    // MARK: - Raw types matching routing_graph.json shape exactly

    private struct RawGraph: Decodable {
        let nodes: [RawNode]
        let edges: [RawEdge]
    }

    private struct RawNode: Decodable {
        let id: String
        let kind: String
        let label: String?
        let concourse: String?
    }

    private struct RawEdge: Decodable {
        let from: String
        let to: String
        let kind: String
        let timeSeconds: Double?
        let rideTimeSeconds: Double?
        let stationDwellSeconds: Double?
        let expectedWaitSeconds: WaitTimes?
        let oneWay: Bool?
    }

    private struct WaitTimes: Decodable {
        let peak: Double?
        let offPeak: Double?
    }

    // MARK: - Stored graph

    private let nodes: [String: RawNode]
    private let edges: [RawEdge]
    private let adjacency: [String: [(neighbor: String, edge: RawEdge)]]

    // MARK: - Init / loading

    init() {
        let raw = Self.load()
        self.nodes = Dictionary(uniqueKeysWithValues: raw.nodes.map { ($0.id, $0) })
        self.edges = raw.edges
        self.adjacency = Self.buildAdjacency(edges: raw.edges)
    }

    private static func load() -> RawGraph {
        guard let url = Bundle.main.url(forResource: "routing_graph", withExtension: "json") else {
            fatalError("RouteEngine: routing_graph.json missing from bundle Resources")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(RawGraph.self, from: data)
        } catch {
            fatalError("RouteEngine: failed to decode routing_graph.json — \(error)")
        }
    }

    private static func buildAdjacency(edges: [RawEdge]) -> [String: [(neighbor: String, edge: RawEdge)]] {
        var map: [String: [(neighbor: String, edge: RawEdge)]] = [:]
        for edge in edges {
            map[edge.from, default: []].append((edge.to, edge))
            // Treat as bidirectional unless the JSON marks oneWay: true.
            if edge.oneWay != true {
                map[edge.to, default: []].append((edge.from, edge))
            }
        }
        return map
    }

    // MARK: - Public planning entry point

    func plan(
        origin: Bay,
        destination: Bay,
        apmMode: APMMode,
        boardingMinutes: Int
    ) -> PlannedRoute {
        let originHubId = hubId(for: origin.concourse)
        let destHubId = hubId(for: destination.concourse)

        guard nodes[originHubId] != nil, nodes[destHubId] != nil else {
            return PlannedRoute(
                segments: [],
                verdict: .unrealistic(reason: "Could not locate concourse hub for one or both bays")
            )
        }

        var segments: [PlannedSegment] = []

        // Intra-concourse walk: origin gate → origin hub
        segments.append(PlannedSegment(
            kind: .walk,
            from: origin.displayLabel,
            to: nodeLabel(originHubId),
            fromId: origin.bayId,
            toId: originHubId,
            timeSeconds: nil,
            isStub: true,
            detail: "Intra-concourse walk — not measured"
        ))

        // Inter-concourse path
        if origin.concourse != destination.concourse {
            let path = bfsPath(from: originHubId, to: destHubId)
            for edge in path {
                segments.append(translate(edge: edge, apmMode: apmMode))
            }
        }

        // Intra-concourse walk: dest hub → destination gate
        segments.append(PlannedSegment(
            kind: .walk,
            from: nodeLabel(destHubId),
            to: destination.displayLabel,
            fromId: destHubId,
            toId: destination.bayId,
            timeSeconds: nil,
            isStub: true,
            detail: "Intra-concourse walk — not measured"
        ))

        return PlannedRoute(
            segments: segments,
            verdict: computeVerdict(segments: segments, boardingMinutes: boardingMinutes)
        )
    }

    // MARK: - Hub mapping

    private func hubId(for concourse: Concourse) -> String {
        switch concourse {
        case .A: return "CONCOURSE_A_HUB"
        case .B: return "CONCOURSE_B_HUB"
        case .C: return "CONCOURSE_C_HUB"
        case .D: return "CONCOURSE_D_HUB"   // T1 — no graph edges yet, routes will fail
        case .F: return "CONCOURSE_F_HUB"   // T2 — no graph edges yet, routes will fail
        case .G: return "APRON_G_HUB"       // Remote apron — pax don't normally route here
        case .E: return "APRON_E_HUB"       // Remote apron — same
        case .H: return "APRON_H_HUB"       // Royal Airwing — restricted access
        case .Q: return "APRON_Q_HUB"       // EK maintenance — staff only
        case .S: return "APRON_S_HUB"       // Remote apron — same
        }
    }

    private func nodeLabel(_ id: String) -> String {
        nodes[id]?.label ?? id
    }

    // MARK: - BFS shortest hop path

    /// Returns the list of edges traversed from origin to destination, in order.
    /// Empty array if no path. Uses BFS so picks the topologically shortest path
    /// (fewest segments) — appropriate for this small graph where all simple
    /// paths between any two hubs are unique.
    private func bfsPath(from origin: String, to destination: String) -> [RawEdge] {
        if origin == destination { return [] }

        var visited: Set<String> = [origin]
        var queue: [(node: String, path: [RawEdge])] = [(origin, [])]

        while !queue.isEmpty {
            let (current, path) = queue.removeFirst()
            for (neighbor, edge) in adjacency[current] ?? [] {
                if visited.contains(neighbor) { continue }
                let nextPath = path + [edge]
                if neighbor == destination {
                    return nextPath
                }
                visited.insert(neighbor)
                queue.append((neighbor, nextPath))
            }
        }
        return []
    }

    // MARK: - Edge → PlannedSegment

    private func translate(edge: RawEdge, apmMode: APMMode) -> PlannedSegment {
        let kind = EdgeKind(rawValue: edge.kind) ?? .walk
        let fromLabel = nodeLabel(edge.from)
        let toLabel = nodeLabel(edge.to)

        switch kind {
        case .train:
            return translateTrain(edge: edge, kind: kind, from: fromLabel, to: toLabel, apmMode: apmMode)
        case .walk, .elevator, .stairs:
            return translateSimple(edge: edge, kind: kind, from: fromLabel, to: toLabel)
        }
    }

    private func translateTrain(
        edge: RawEdge,
        kind: EdgeKind,
        from: String,
        to: String,
        apmMode: APMMode
    ) -> PlannedSegment {
        let waitSec: Double? = {
            switch apmMode {
            case .peak: return edge.expectedWaitSeconds?.peak
            case .offPeak: return edge.expectedWaitSeconds?.offPeak
            }
        }()
        let dwell = edge.stationDwellSeconds
        let ride = edge.rideTimeSeconds

        if let waitSec, let dwell, let ride {
            // Total transit = wait + boarding dwell + ride + arrival dwell
            let total = waitSec + dwell + ride + dwell
            let waitMin = Int(waitSec / 60)
            let rideMin = Int(ride / 60)
            return PlannedSegment(
                kind: kind,
                from: from,
                to: to,
                fromId: edge.from,
                toId: edge.to,
                timeSeconds: total,
                isStub: false,
                detail: "APM (\(apmMode.label)) — wait ~\(waitMin) min, ride ~\(rideMin) min, plus dwells"
            )
        }
        return PlannedSegment(
            kind: kind,
            from: from,
            to: to,
            fromId: edge.from,
            toId: edge.to,
            timeSeconds: nil,
            isStub: true,
            detail: "APM timing unavailable"
        )
    }

    private func translateSimple(
        edge: RawEdge,
        kind: EdgeKind,
        from: String,
        to: String
    ) -> PlannedSegment {
        if let time = edge.timeSeconds {
            return PlannedSegment(
                kind: kind,
                from: from,
                to: to,
                fromId: edge.from,
                toId: edge.to,
                timeSeconds: time,
                isStub: false,
                detail: nil
            )
        }
        return PlannedSegment(
            kind: kind,
            from: from,
            to: to,
            fromId: edge.from,
            toId: edge.to,
            timeSeconds: nil,
            isStub: true,
            detail: detailForStub(kind: kind, from: edge.from, to: edge.to)
        )
    }

    private func detailForStub(kind: EdgeKind, from: String, to: String) -> String {
        switch kind {
        case .walk:
            if from == "B_C_WALKWAY" || to == "B_C_WALKWAY" {
                return "Control-tower walkway — ~300m, time not measured"
            }
            return "Walk — time not measured"
        case .elevator: return "Sky Train lift — time not measured"
        case .stairs: return "Stairs — time not measured"
        case .train: return "Train — timing unavailable"
        }
    }

    // MARK: - Verdict

    private func computeVerdict(segments: [PlannedSegment], boardingMinutes: Int) -> RouteVerdict {
        let allMeasured = segments.allSatisfy { !$0.isStub }
        guard allMeasured else {
            return .unrealistic(
                reason: "Route includes unmeasured walking segments — totals incomplete"
            )
        }
        let totalSec = segments.compactMap(\.timeSeconds).reduce(0, +)
        let totalMin = Int(totalSec / 60)
        let spare = boardingMinutes - totalMin
        if spare > 25 {
            return .comfortable
        } else if spare > 0 {
            return .tight(minutesSpare: spare)
        } else {
            return .unrealistic(reason: "Route exceeds available time before boarding")
        }
    }
}
