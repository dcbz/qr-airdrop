import SwiftUI

struct ContentView: View {
    @StateObject private var model = ReceiverViewModel()
    @State private var showingShareSheet = false

    var body: some View {
        ZStack {
            if model.cameraAuthorized {
                QRScannerView { payload in model.scan(payload) }
                    .ignoresSafeArea()

                Color.black.opacity(0.22).ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack(spacing: 0) {
                statusPanel
                Spacer()
                scanTarget
                Spacer()
                actionPanel
            }
        }
        .task { await model.requestCameraAccess() }
        .sheet(isPresented: $showingShareSheet) {
            if let url = model.outputURL { ShareSheet(url: url) }
        }
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(statusLabel)
                .font(.caption.bold())
                .tracking(1.5)
                .foregroundStyle(.mint)
            Text(model.fileName ?? "Point at the QR transfer")
                .font(.title2.bold())
                .lineLimit(1)

            if model.total > 0 {
                Text("\(model.received) / \(model.total)  ·  \(Int(model.progress * 100))%")
                    .font(.system(size: 30, weight: .light, design: .rounded))
                ProgressView(value: model.progress)
                    .tint(.mint)
                Text("Missing \(model.missing)    Duplicates \(model.duplicates)    Invalid \(model.invalid)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(.ultraThinMaterial)
    }

    private var scanTarget: some View {
        RoundedRectangle(cornerRadius: 26)
            .stroke(model.state == .receiving || model.state == .armed ? Color.mint : Color.white.opacity(0.75), lineWidth: 3)
            .frame(width: 270, height: 270)
            .shadow(color: .black.opacity(0.4), radius: 8)
    }

    @ViewBuilder
    private var actionPanel: some View {
        VStack(spacing: 10) {
            if model.cameraDenied {
                Text("Camera access is disabled. Enable it in Settings to receive files.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.orange)
            }

            switch model.state {
            case .idle:
                Text("The sender can loop continuously. Missed frames will be collected on the next pass.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .armed:
                Label("Setup QR received", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.mint)
                Text("Ready — press Enter on the sender")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
            case .receiving:
                Button("Cancel Transfer", role: .destructive) { model.reset() }
            case .verifying:
                ProgressView("Verifying file…")
            case .complete:
                Label("Transfer complete", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.mint)
                Button("Share or Save File") { showingShareSheet = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.mint)
                    .foregroundStyle(.black)
                Button("Receive Another") { model.reset() }
            case .error(let message):
                Text(message).foregroundStyle(.red).multilineTextAlignment(.center)
                Button("Start Over") { model.reset() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(.ultraThinMaterial)
    }

    private var statusLabel: String {
        switch model.state {
        case .idle: "READY TO RECEIVE"
        case .armed: "READY"
        case .receiving: "RECEIVING"
        case .verifying: "VERIFYING"
        case .complete: "COMPLETE"
        case .error: "ERROR"
        }
    }
}
