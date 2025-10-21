import Foundation

public enum BeamingRules {
    /// Compute beamed groups and beam levels from a sequence.
    /// - Parameters:
    ///   - beatPos: position within bar for each event (0..beatsPerBar).
    ///   - beatsPerBar: e.g., 4 in 4/4, 6 in 6/8.
    ///   - beatUnit: denominator of a single beat (e.g., 4 for quarter, 8 for eighth).
    ///   - isNote: true if event is a note (vs rest).
    ///   - denoms: duration denominators for events (1,2,4,8,16,...; 0 for rests).
    public static func computeGroups(
        beatPos: [Double],
        beatsPerBar: Int,
        beatUnit: Int,
        isNote: [Bool],
        denoms: [Int]
    ) -> (groups: [[Int]], levels: [Int]) {
        let count = beatPos.count
        var groups: [[Int]] = []
        var levels: [Int] = Array(repeating: 0, count: count)
        let isCompound = (beatUnit == 8) && (beatsPerBar % 3 == 0)
        let groupSize: Double = isCompound ? 3.0 : 1.0
        func intBeatIndex(_ pos: Double) -> Int {
            let rounded = round(pos)
            if abs(pos - rounded) < 1e-9 { return Int(max(0, rounded - 1)) }
            return Int(floor(pos))
        }
        func beamLevel(_ den: Int) -> Int {
            switch den { case 8: return 1; case 16: return 2; case 32: return 3; case 64: return 4; default: return 0 }
        }
        func compoundIndex(forStartPos pos: Double) -> Int { Int(floor(pos / groupSize)) }

        var i = 0
        while i < count {
            guard i < beatPos.count, isNote[i], denoms[i] >= 8 else { i += 1; continue }
            levels[i] = beamLevel(denoms[i])
            let startGroup = isCompound ? compoundIndex(forStartPos: (i == 0 ? 0.0 : beatPos[i-1])) : intBeatIndex(beatPos[i])
            var j = i + 1
            var group: [Int] = [i]
            while j < count, j < beatPos.count, isNote[j], denoms[j] >= 8 {
                let gIdx = isCompound ? compoundIndex(forStartPos: (j == 0 ? 0.0 : beatPos[j-1])) : intBeatIndex(beatPos[j])
                if gIdx != startGroup { break }
                levels[j] = beamLevel(denoms[j])
                group.append(j)
                j += 1
            }
            if group.count >= 2 { groups.append(group) }
            i = j
        }
        return (groups, levels)
    }
}

