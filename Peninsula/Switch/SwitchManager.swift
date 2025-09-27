import AppKit
import Foundation

// Centralizes logic for expanding the current switch state into
// a list of items the UI can render. We cache results only when
// searching to avoid unnecessary recomputation while typing.

final class SwitchManager {
    static let shared = SwitchManager()
    private init() {}

    private var cachedSearchExpansion: [(any Switchable, NSImage, [MatchableString.MatchResult])] = []
    private var lastSearchState: SwitchState = .none
    private var lastSearchFilter: String = ""

    // Returns the number of items for the current state without materializing
    // the full mapped list (except when searching, where we keep a cache).
    func itemsCount(
        state: SwitchState,
        contentType: NotchContentType,
        filterString: String
    ) -> Int {
        if contentType == .searching {
            // Ensure cache is up-to-date and return count from cache
            _ = items(state: state, contentType: contentType, filterString: filterString)
            return cachedSearchExpansion.count
        }
        return rawExpansion(state: state).count
    }

    func items(
        state: SwitchState,
        contentType: NotchContentType,
        filterString: String
    ) -> [(any Switchable, NSImage, [MatchableString.MatchResult])] {
        let rawExpansion = rawExpansion(state: state)

        // Cache only for the searching content type
        if contentType == .searching {
            let lowered = filterString.lowercased()
            if state != lastSearchState || lowered != lastSearchFilter {
                lastSearchState = state
                lastSearchFilter = lowered
                cachedSearchExpansion = rawExpansion.compactMap { item in
                    if let match = item.getMatchableString().matches(string: lowered) {
                        return (
                            item,
                            item.getIcon() ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)!,
                            match
                        )
                    }
                    return nil
                }
            }
            return cachedSearchExpansion
        }

        // Non-searching modes: compute on demand (no caching)
        return rawExpansion.map { item in
            (
                item,
                item.getIcon() ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)!,
                [.unmatched(item.getTitle() ?? "")]
            )
        }
    }

    // Returns only the requested slice of the expansion, minimizing work.
    // Indices are relative to the filtered list (same semantics as before).
    func itemsSlice(
        state: SwitchState,
        contentType: NotchContentType,
        filterString: String,
        range: Range<Int>
    ) -> [(Int, (any Switchable, NSImage, [MatchableString.MatchResult]))] {
        if contentType == .searching {
            let list = items(state: state, contentType: contentType, filterString: filterString)
            let upper = min(range.upperBound, list.count)
            let lower = min(range.lowerBound, upper)
            if lower >= upper { return [] }
            return Array(list[lower..<upper]).enumerated().map { offset, element in
                (lower + offset, element)
            }
        }
        // Non-searching: map only the requested slice
        let base = rawExpansion(state: state)
        let upper = min(range.upperBound, base.count)
        let lower = min(range.lowerBound, upper)
        if lower >= upper { return [] }
        return (lower..<upper).map { idx in
            let item = base[idx]
            return (
                idx,
                (
                    item,
                    item.getIcon() ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)!,
                    [.unmatched(item.getTitle() ?? "")]
                )
            )
        }
    }

    // MARK: - Helpers
    private func rawExpansion(state: SwitchState) -> [any Switchable] {
        switch state {
        case .interWindows:
            return Windows.shared.coll
        case .interApps:
            return Apps.shared.useableInner
        case .intraApp:
            if Windows.shared.coll.count > 0 {
                return Windows.shared.coll[0].application.windows.coll
            } else {
                return []
            }
        case .none:
            return []
        }
    }
}
