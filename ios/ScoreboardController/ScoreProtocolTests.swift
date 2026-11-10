import XCTest
@testable import ScoreboardController

final class ScoreProtocolTests: XCTestCase {
    func testFirmwarePlayerOrderAndLittleEndian() {
        let value = ScoreState(data: Data([1, 0, 0, 0, 2, 0, 0, 0]))
        XCTAssertEqual(value?.playerOne, 1)
        XCTAssertEqual(value?.playerTwo, 2)
        let larger = ScoreState(data: Data([0x78, 0x56, 0x34, 0x12, 0xff, 0xff, 0xff, 0x7f]))
        XCTAssertEqual(larger?.playerOne, 0x12345678)
        XCTAssertEqual(larger?.playerTwo, 2_147_483_647)
    }
    func testRejectsTruncatedAndOversizedPackets() {
        for length in [0, 1, 7, 9, 20] {
            XCTAssertNil(ScoreState(data: Data(repeating: 0, count: length)))
        }
    }
    func testNamesUsePanelOrderAndCanonicalPacket() {
        let names = PlayerNames(p1: "  blue-1 ", p2: "green 2")
        let packet = Data("1BLUE-1|GREEN 2".utf8)
        XCTAssertEqual(names?.p1, "BLUE-1")
        XCTAssertEqual(names?.p2, "GREEN 2")
        XCTAssertEqual(names?.data, packet)
        XCTAssertEqual(PlayerNames(data: packet), names)
        XCTAssertEqual(PlayerNames(p1: "ABCDEFGH", p2: "12345678")?.data.count, 18)
    }

    func testRejectsMalformedNamePackets() {
        for packet in ["", "2A|B", "1|B", "1A|", "1A|B|C", "1a|B", "1 A|B",
                       "1A|B ", "1ABCDEFGHI|B", "1A|B\n", "1A|B!", "1A|É"] {
            XCTAssertNil(PlayerNames(data: Data(packet.utf8)), packet)
        }
        XCTAssertNil(PlayerNames(p1: "  ", p2: "B"))
        XCTAssertNil(PlayerNames(p1: "É", p2: "B"))
    }

    func testCommandsMatchFirmwareWithoutNewlines() {
        XCTAssertEqual(ScoreCommand.playerOnePlus.data, Data([0x50, 0x31, 0x2b]))
        XCTAssertEqual(ScoreCommand.playerOneMinus.data, Data([0x50, 0x31, 0x2d]))
        XCTAssertEqual(ScoreCommand.playerTwoPlus.data, Data([0x50, 0x32, 0x2b]))
        XCTAssertEqual(ScoreCommand.playerTwoMinus.data, Data([0x50, 0x32, 0x2d]))
        XCTAssertEqual(ScoreCommand.reset.data, Data([0x52, 0x45, 0x53, 0x45, 0x54]))
    }
}
