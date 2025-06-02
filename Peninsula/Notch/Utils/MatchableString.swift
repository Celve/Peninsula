import Foundation
import SwiftUI

class MatchableString {
    let string: String
    var pos: [Character: [Int]]
    
    enum MatchResult: Identifiable {
        var id: String {
            switch self {
            case .matched(let matchedString):
                return matchedString
            case .unmatched(let unmatchedString):
                return unmatchedString
            }
        }

        case matched(String)
        case unmatched(String)
    }

    init(string: String) {
        self.string = string
        self.pos = [:]
        for (index, char) in string.lowercased().enumerated() {
            if self.pos[char] == nil {
                self.pos[char] = []
            }
            self.pos[char]?.append(index)
        }
    }

    func matches(string: String) -> [MatchResult]? {
        var lastMatch = -1
        var matchIndices: [Int] = []
        for char in string {
            let pos = self.pos[char]
            guard let positions = pos else { return nil }
            var left = 0
            var right = positions.count - 1
            var result = -1
            
            while left <= right {
                let mid = (left + right) / 2
                if positions[mid] > lastMatch {
                    result = positions[mid]
                    right = mid - 1
                } else {
                    left = mid + 1
                }
            }
            
            if result == -1 {
                return nil
            }
            lastMatch = result
            matchIndices.append(result)
        }

        var matchResults: [MatchResult] = []
        for (index, char) in self.string.enumerated() {
            if matchIndices.contains(index) {
                if case .matched(let matchedString) = matchResults.last {
                    matchResults[matchResults.count - 1] = .matched(matchedString + String(char))
                } else {
                    matchResults.append(.matched(String(char)))
                }
            } else {
                if case .unmatched(let unmatchedString) = matchResults.last {
                    matchResults[matchResults.count - 1] = .unmatched(unmatchedString + String(char))
                } else {
                    matchResults.append(.unmatched(String(char)))
                }
            }
        }
        return matchResults
    }
}
