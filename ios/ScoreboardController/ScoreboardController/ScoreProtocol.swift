import Foundation

struct ScoreState: Equatable {
    let playerOne: UInt32
    let playerTwo: UInt32
    init?(data: Data) {
        guard data.count == 8 else { return nil }
        let bytes = Array(data)
        func word(_ start: Int) -> UInt32 {
            (0..<4).reduce(UInt32(0)) { $0 | (UInt32(bytes[start + $1]) << (8 * $1)) }
        }
        playerOne = word(0)
        playerTwo = word(4)
    }
}

struct PlayerNames: Equatable {
    static let maxLength = 8

    let p1: String
    let p2: String

    init?(p1: String, p2: String) {
        guard let p1 = Self.normalized(p1), let p2 = Self.normalized(p2) else { return nil }
        self.p1 = p1
        self.p2 = p2
    }

    init?(data: Data) {
        guard let packet = String(data: data, encoding: .ascii), packet.first == "1" else { return nil }
        let names = packet.dropFirst().split(separator: "|", omittingEmptySubsequences: false)
        guard names.count == 2, let decoded = Self(p1: String(names[0]), p2: String(names[1])),
              decoded.data == data else { return nil }
        self = decoded
    }

    var data: Data { Data("1\(p1)|\(p2)".utf8) }

    private static func normalized(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...maxLength).contains(trimmed.utf8.count),
              trimmed.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0)
                      || (48...57).contains($0) || $0 == 32 || $0 == 45
              }) else { return nil }
        return trimmed.uppercased()
    }
}

enum ScoreCommand: String, CaseIterable {
    case playerOnePlus = "P1+", playerOneMinus = "P1-"
    case playerTwoPlus = "P2+", playerTwoMinus = "P2-", reset = "RESET"
    var data: Data { Data(rawValue.utf8) }
}
