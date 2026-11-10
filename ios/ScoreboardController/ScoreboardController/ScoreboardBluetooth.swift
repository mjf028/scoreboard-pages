import Foundation
import Combine
import CoreBluetooth

struct NearbyScoreboard: Identifiable {
    let peripheral: CBPeripheral
    let name: String
    let signal: Int
    var id: UUID { peripheral.identifier }
}

// CoreBluetooth and all published state use the main queue.
final class ScoreboardBluetooth: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let serviceID = CBUUID(string: "ea180001-7444-4d8e-b83c-3f0c0e473ee1")
    static let commandID = CBUUID(string: "ea180002-7444-4d8e-b83c-3f0c0e473ee1")
    static let stateID = CBUUID(string: "ea180003-7444-4d8e-b83c-3f0c0e473ee1")

    static let namesStateID = CBUUID(string: "ea180004-7444-4d8e-b83c-3f0c0e473ee1")
    static let namesWriteID = CBUUID(string: "ea180005-7444-4d8e-b83c-3f0c0e473ee1")

    @Published private(set) var playerNames: PlayerNames?
    @Published private var pendingNames: PlayerNames?
    var savingNames: Bool { pendingNames != nil }
    var supportsPlayerNames: Bool { namesStateCharacteristic != nil && namesWriteCharacteristic != nil }

    @Published private(set) var status = "Getting Bluetooth ready…"
    @Published private(set) var devices: [NearbyScoreboard] = []
    @Published private(set) var scores: ScoreState?
    @Published private(set) var ready = false
    @Published private(set) var busy = false
    @Published private(set) var searching = false
    @Published private(set) var active = false
    @Published var errorMessage: String?

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?
    private var stateCharacteristic: CBCharacteristic?
    private var namesStateCharacteristic: CBCharacteristic?
    private var namesWriteCharacteristic: CBCharacteristic?
    private var nameSaveDeadline: DispatchWorkItem?
    private var wantsConnection = false
    private var selectedID: UUID?
    private var deadline: DispatchWorkItem?
    private var writeDeadline: DispatchWorkItem?
    private var refresh: DispatchWorkItem?
    private var retry: DispatchWorkItem?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func scan() {
        guard central.state == .poweredOn else { explainBluetooth(); return }
        disconnect()
        devices = []
        errorMessage = nil
        startScan()
    }

    private func startScan() {
        guard central.state == .poweredOn else { return }
        searching = true
        active = wantsConnection
        status = wantsConnection ? "Looking for your scoreboard…" : "Looking for scoreboards…"
        central.scanForPeripherals(withServices: [Self.serviceID], options: nil)
        armDeadline(seconds: 20) { [weak self] in
            guard let self = self else { return }
            self.central.stopScan()
            self.searching = false
            self.active = false
            self.wantsConnection = false
            self.status = self.devices.isEmpty ? "No scoreboard found. Power it on and try again." : "Choose your scoreboard below."
        }
    }

    func connect(_ device: NearbyScoreboard) {
        guard central.state == .poweredOn else { return }
        selectedID = device.id
        wantsConnection = true
        beginConnection(device.peripheral)
    }

    private func beginConnection(_ device: CBPeripheral) {
        central.stopScan()
        searching = false
        clearSession()
        peripheral = device
        device.delegate = self
        active = true
        status = "Connecting…"
        central.connect(device, options: nil)
        armDeadline(seconds: 15) { [weak self] in self?.fail("Connection timed out. Try connecting again.") }
    }

    func disconnect() {
        wantsConnection = false
        selectedID = nil
        deadline?.cancel()
        retry?.cancel()
        central.stopScan()
        searching = false
        if let device = peripheral {
            device.delegate = nil
            central.cancelPeripheralConnection(device)
        }
        peripheral = nil
        clearSession()
        active = false
        status = "Disconnected"
    }

    func synchronize() {
        guard let device = peripheral, device.state == .connected,
              let state = stateCharacteristic, state.isNotifying else { return }
        scores = nil
        ready = false
        status = "Refreshing live scores…"
        armDeadline(seconds: 12) { [weak self] in self?.fail("Could not refresh scores. Reconnect and try again.") }
        device.readValue(for: state)
        if let namesState = namesStateCharacteristic, namesState.isNotifying {
            device.readValue(for: namesState)
        }
    }

    func send(_ command: ScoreCommand) {
        guard ready, !busy, let device = peripheral, let characteristic = commandCharacteristic else { return }
        busy = true
        errorMessage = nil
        // Never change scores locally or replay a scoring command after reconnect.
        device.writeValue(command.data, for: characteristic, type: .withResponse)
        let timeout = DispatchWorkItem { [weak self] in
            self?.fail("The command could not be confirmed. Check the panel before trying again.")
        }
        writeDeadline = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: timeout)
    }

    func saveNames(_ names: PlayerNames) {
        guard ready, !savingNames, let current = playerNames, names != current,
              let device = peripheral, let write = namesWriteCharacteristic else { return }
        pendingNames = names
        errorMessage = nil
        device.writeValue(names.data, for: write, type: .withResponse)
        let timeout = DispatchWorkItem { [weak self] in
            self?.finishNameSave(error: "The scoreboard did not confirm the new names. Check the panel before trying again.")
        }
        nameSaveDeadline = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: timeout)
    }

    private func finishNameSave(error: String? = nil) {
        nameSaveDeadline?.cancel()
        nameSaveDeadline = nil
        pendingNames = nil
        if let error = error {
            errorMessage = error
            if let state = namesStateCharacteristic {
                peripheral?.readValue(for: state)
            }
        }
    }

    private func clearSession() {
        if savingNames {
            errorMessage = "Disconnected before the scoreboard confirmed the new names. Check the labels after reconnecting."
        }
        finishNameSave()
        playerNames = nil
        namesStateCharacteristic = nil
        namesWriteCharacteristic = nil
        ready = false
        busy = false
        scores = nil
        commandCharacteristic = nil
        stateCharacteristic = nil
        writeDeadline?.cancel()
        refresh?.cancel()
    }

    private func armDeadline(seconds: Double, action: @escaping () -> Void) {
        deadline?.cancel()
        let work = DispatchWorkItem(block: action)
        deadline = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func fail(_ message: String) {
        disconnect()
        errorMessage = message
        status = "Connection needs attention"
    }

    private func explainBluetooth() {
        switch central.state {
        case .poweredOff: status = "Turn on Bluetooth to connect."
        case .unauthorized: status = "Allow Bluetooth access in iPhone Settings for Scoreboard."
        case .unsupported: status = "Bluetooth is unavailable. Use a real iPhone for the scoreboard."
        case .resetting: status = "Bluetooth is restarting…"
        default: status = "Getting Bluetooth ready…"
        }
    }

    private func updateReady() {
        ready = peripheral?.state == .connected && commandCharacteristic != nil
            && stateCharacteristic?.isNotifying == true && scores != nil
        if ready {
            deadline?.cancel()
            status = "Connected · Live scores"
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            if wantsConnection { startScan() }
            else { status = "Ready to connect" }
        } else {
            deadline?.cancel()
            retry?.cancel()
            clearSession()
            searching = false
            active = false
            explainBluetooth()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover device: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? device.name ?? "Scoreboard"
        if !devices.contains(where: { $0.id == device.identifier }) {
            devices.append(NearbyScoreboard(peripheral: device, name: name, signal: RSSI.intValue))
        }
        if wantsConnection, device.identifier == selectedID { beginConnection(device) }
    }

    func centralManager(_ central: CBCentralManager, didConnect device: CBPeripheral) {
        guard peripheral === device, wantsConnection else { central.cancelPeripheralConnection(device); return }
        status = "Reading scoreboard…"
        armDeadline(seconds: 12) { [weak self] in self?.fail("Could not read live scores. Reconnect and try again.") }
        device.discoverServices([Self.serviceID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect device: CBPeripheral, error: Error?) {
        guard peripheral === device else { return }
        fail("Could not connect. Disconnect nRF Connect, then try again.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral device: CBPeripheral, error: Error?) {
        guard peripheral === device else { return }
        deadline?.cancel()
        peripheral = nil
        clearSession()
        active = false
        guard wantsConnection else { status = "Disconnected"; return }
        status = "Connection lost. Reconnecting…"
        active = true
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.wantsConnection else { return }
            self.startScan()
        }
        retry = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: work)
    }

    func peripheral(_ device: CBPeripheral, didDiscoverServices error: Error?) {
        guard peripheral === device else { return }
        guard error == nil, let service = device.services?.first(where: { $0.uuid == Self.serviceID }) else {
            fail("This device does not expose the scoreboard service."); return
        }
        device.discoverCharacteristics([Self.commandID, Self.stateID, Self.namesStateID, Self.namesWriteID], for: service)
    }

    func peripheral(_ device: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard peripheral === device else { return }
        guard error == nil,
              let command = service.characteristics?.first(where: { $0.uuid == Self.commandID }),
              let state = service.characteristics?.first(where: { $0.uuid == Self.stateID }),
              command.properties.contains(.write), state.properties.contains(.read), state.properties.contains(.notify) else {
            fail("The scoreboard firmware does not provide the expected controls."); return
        }
        commandCharacteristic = command
        stateCharacteristic = state
        if let namesState = service.characteristics?.first(where: { $0.uuid == Self.namesStateID }),
           let namesWrite = service.characteristics?.first(where: { $0.uuid == Self.namesWriteID }),
           namesState.properties.contains(.read), namesState.properties.contains(.notify),
           namesWrite.properties.contains(.write) {
            namesStateCharacteristic = namesState
            namesWriteCharacteristic = namesWrite
            device.setNotifyValue(true, for: namesState)
        }
        device.setNotifyValue(true, for: state)
    }

    func peripheral(_ device: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard peripheral === device else { return }
        if characteristic === namesStateCharacteristic {
            guard error == nil, characteristic.isNotifying else {
                errorMessage = "Could not enable player name updates. Reconnect to try again."
                return
            }
            device.readValue(for: characteristic)
            return
        }
        guard characteristic.uuid == Self.stateID else { return }
        guard error == nil, characteristic.isNotifying else {
            fail("Could not enable live scores. Reconnect and try again."); return
        }
        device.readValue(for: characteristic)
    }

    func peripheral(_ device: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard peripheral === device else { return }
        if characteristic === namesStateCharacteristic {
            guard error == nil, let data = characteristic.value, let names = PlayerNames(data: data) else {
                errorMessage = "Could not read the scoreboard's player names. Reconnect to try again."
                return
            }
            playerNames = names
            if names == pendingNames { finishNameSave() }
            return
        }
        guard characteristic.uuid == Self.stateID else { return }
        guard error == nil, let data = characteristic.value, let value = ScoreState(data: data) else {
            fail("The scoreboard returned an unreadable score. Reconnect and try again."); return
        }
        scores = value
        updateReady()
    }

    func peripheral(_ device: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard peripheral === device else { return }
        if characteristic === namesWriteCharacteristic {
            if savingNames, error != nil {
                finishNameSave(error: "Could not send the new names. Check the scoreboard and try again.")
            }
            return
        }
        guard characteristic.uuid == Self.commandID else { return }
        writeDeadline?.cancel()
        guard error == nil else {
            fail("The command could not be confirmed. Check the panel before trying again."); return
        }
        // GATT acknowledgment is receipt, not score application. Notifications remain
        // authoritative; follow with a delayed read, never an automatic scoring retry.
        let work = DispatchWorkItem { [weak self, weak device] in
            guard let self = self, let device = device, self.peripheral === device,
                  let state = self.stateCharacteristic else { return }
            // A foreground refresh may already be reading the score.
            if self.ready { device.readValue(for: state) }
            self.busy = false
        }
        refresh = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }
}
