import SwiftUI

@main
struct ScoreboardControllerApp: App {
    @StateObject private var scoreboard = ScoreboardBluetooth()
    var body: some Scene {
        WindowGroup { ControllerView().environmentObject(scoreboard) }
    }
}
