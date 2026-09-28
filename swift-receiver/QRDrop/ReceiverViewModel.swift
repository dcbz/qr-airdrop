import AVFoundation
import Foundation

@MainActor
final class ReceiverViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case armed
        case receiving
        case verifying
        case complete
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var fileName: String?
    @Published private(set) var received = 0
    @Published private(set) var total = 0
    @Published private(set) var duplicates = 0
    @Published private(set) var invalid = 0
    @Published private(set) var outputURL: URL?
    @Published private(set) var cameraAuthorized = false
    @Published private(set) var cameraDenied = false

    private var session: TransferSession?
    private var processing = false

    var progress: Double { total == 0 ? 0 : Double(received) / Double(total) }
    var missing: Int { max(0, total - received) }

    func requestCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAuthorized = true
            cameraDenied = false
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraAuthorized = granted
            cameraDenied = !granted
        default:
            cameraAuthorized = false
            cameraDenied = true
        }
    }

    func scan(_ payload: String) {
        guard !processing, state != .complete, state != .verifying else { return }
        processing = true
        defer { processing = false }

        if session == nil {
            guard let setup = try? TransferSession.decodeSetup(payload),
                  let newSession = try? TransferSession(setup: setup) else { return }
            session = newSession
            fileName = newSession.fileName
            total = newSession.totalChunks
            state = .armed
            return
        }

        guard let session else { return }
        let result = session.accept(payload: payload)
        if result == .accepted { state = .receiving }
        received = session.received
        duplicates = session.duplicates
        invalid = session.invalid

        if session.isComplete { finish(session) }
    }

    func reset() {
        session = nil
        state = .idle
        fileName = nil
        received = 0
        total = 0
        duplicates = 0
        invalid = 0
        outputURL = nil
    }

    private func finish(_ session: TransferSession) {
        state = .verifying
        do {
            let data = try session.assemble()
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let safeName = session.fileName.replacingOccurrences(
                of: "[^A-Za-z0-9._-]",
                with: "_",
                options: .regularExpression
            )
            let destination = documents.appendingPathComponent(safeName.isEmpty ? "received-file" : safeName)
            try data.write(to: destination, options: .atomic)
            outputURL = destination
            state = .complete
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
