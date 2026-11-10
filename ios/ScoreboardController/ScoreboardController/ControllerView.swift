import SwiftUI

struct ControllerView: View {
    @EnvironmentObject private var board: ScoreboardBluetooth
    @Environment(\.scenePhase) private var scenePhase
    @State private var confirmReset = false
    @State private var editingNames = false
    @State private var draftP1 = ""
    @State private var draftP2 = ""
    private let header = Bundle.main.object(forInfoDictionaryKey: "ScoreboardHeader") as? String ?? "COURTSIDE"
    private let green = Color(red: 0.35, green: 0.94, blue: 0.53)
    private let blue = Color(red: 0.36, green: 0.66, blue: 1.0)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(verbatim: header).font(.caption.weight(.bold)).tracking(3).foregroundStyle(.secondary)
                        Text("Scoreboard").font(.largeTitle.bold())
                    }
                    Spacer()
                    Image(systemName: "sportscourt.fill").font(.title).foregroundStyle(green)
                        .accessibilityHidden(true).padding(.top, 10)
                }
                connectionCard
                if let message = board.errorMessage {
                    Text(message).font(.callout).foregroundStyle(.orange)
                        .padding().frame(maxWidth: .infinity, alignment: .leading)
                        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel("Connection error. \(message)")
                }
                playerCard(name: board.playerNames?.p2 ?? "PLAYER 2", score: board.scores?.playerTwo, tint: green,
                           plus: .playerTwoPlus, minus: .playerTwoMinus)
                playerCard(name: board.playerNames?.p1 ?? "PLAYER 1", score: board.scores?.playerOne, tint: blue,
                           plus: .playerOnePlus, minus: .playerOneMinus)
                if let names = board.playerNames {
                    Button {
                        draftP1 = names.p1
                        draftP2 = names.p2
                        editingNames = true
                    } label: {
                        Label(board.savingNames ? "Saving player names…" : "Edit player names", systemImage: "pencil")
                            .frame(maxWidth: .infinity).frame(minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!board.ready || board.savingNames)
                } else if board.ready && !board.supportsPlayerNames {
                    Text("Update the scoreboard firmware to edit player names.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Button(role: .destructive) { confirmReset = true } label: {
                    Label("Reset both scores", systemImage: "arrow.counterclockwise")
                        .font(.headline).frame(maxWidth: .infinity).frame(minHeight: 56)
                        .background(.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!board.ready || board.busy)
                Text("Scores update here when you use the panel’s buttons, too.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center)
            }
            .padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(Color(red: 0.035, green: 0.045, blue: 0.065))
        .preferredColorScheme(.dark)
        .confirmationDialog("Reset both scores to zero?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset both scores", role: .destructive) { board.send(.reset) }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $editingNames) {
            nameEditor
        }
        .onChange(of: board.playerNames) { names in
            if names == nil { editingNames = false }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { board.synchronize() }
        }
    }

    private var nameEditor: some View {
        let names = PlayerNames(p1: draftP1, p2: draftP2)
        return NavigationStack {
            Form {
                Section {
                    TextField("Top player (green)", text: $draftP2)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Bottom player (blue)", text: $draftP1)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                } footer: {
                    Text("Enter 1–8 letters (A–Z), digits, spaces, or hyphens per name. The scoreboard displays names in uppercase.")
                }
            }
            .navigationTitle("Player names")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingNames = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let names = names else { return }
                        board.saveNames(names)
                        editingNames = false
                    }
                    .disabled(!board.ready || board.savingNames || names == nil || names == board.playerNames)
                }
            }
        }
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Circle().fill(board.ready ? green : Color.orange).frame(width: 9, height: 9).padding(.top, 5)
                Text(board.status).font(.subheadline.weight(.medium)).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if board.busy { ProgressView().accessibilityLabel("Sending command") }
            }
            if board.active || board.searching {
                Button(board.ready ? "Disconnect" : "Cancel connection") { board.disconnect() }
                    .font(.subheadline.bold()).buttonStyle(.bordered)
            } else {
                Button { board.scan() } label: {
                    Label("Find scoreboard", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.headline).frame(maxWidth: .infinity).frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent).tint(.white).foregroundStyle(.black)
            }
            if !board.active {
                ForEach(board.devices) { device in
                    Button { board.connect(device) } label: {
                        HStack {
                            Image(systemName: "sportscourt")
                            VStack(alignment: .leading, spacing: 3) {
                                Text(device.name).font(.headline)
                                Text(String(device.id.uuidString.suffix(6))).font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("Connect").font(.subheadline.bold())
                        }.padding(12).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)
                }
            }
        }.padding(16).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
    }

    private func playerCard(name: String, score: UInt32?, tint: Color,
                            plus: ScoreCommand, minus: ScoreCommand) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(name).font(.title2.bold()).tracking(2).foregroundStyle(tint)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                Text(score.map { String($0) } ?? "—")
                    .font(.system(size: 64, weight: .bold, design: .rounded)).monospacedDigit()
                    .minimumScaleFactor(0.3).lineLimit(1)
                    .accessibilityLabel("\(name) score, \(score.map { String($0) } ?? "unavailable")")
            }
            HStack(spacing: 16) {
                scoreButton(symbol: "minus", label: "Subtract one from \(name)", tint: tint, filled: false) { board.send(minus) }
                scoreButton(symbol: "plus", label: "Add one to \(name)", tint: tint, filled: true) { board.send(plus) }
            }
            .disabled(!board.ready || board.busy)
            .opacity(board.ready ? 1 : 0.4)
        }.padding(20).background(tint.opacity(0.085), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(tint.opacity(0.22), lineWidth: 1))
    }

    private func scoreButton(symbol: String, label: String, tint: Color, filled: Bool,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 36, weight: .bold))
                .frame(maxWidth: .infinity).frame(height: 80)
                .foregroundStyle(filled ? Color.black : tint)
                .background(filled ? tint : tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 18))
                .contentShape(RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(.plain).accessibilityLabel(label)
    }
}
