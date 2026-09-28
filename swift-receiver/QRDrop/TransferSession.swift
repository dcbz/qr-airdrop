import CryptoKit
import Foundation

struct QRPacket: Codable, Sendable {
    let v: Int
    let k: String
    let id: String
    let n: String
    let s: Int
    let i: Int
    let t: Int
    let d: String
    let h: String
    let f: String
}

struct SetupPacket: Codable, Sendable {
    let v: Int
    let k: String
    let id: String
    let n: String
    let s: Int
    let t: Int
    let f: String
    let ms: Int
}

enum PacketResult: Equatable {
    case accepted
    case duplicate
    case invalid
    case otherTransfer
    case setup
}

enum TransferError: LocalizedError {
    case invalidPacket
    case incomplete
    case sizeMismatch
    case hashMismatch

    var errorDescription: String? {
        switch self {
        case .invalidPacket: "The QR packet is malformed."
        case .incomplete: "The transfer is not complete."
        case .sizeMismatch: "The reconstructed file has the wrong size."
        case .hashMismatch: "The reconstructed file failed SHA-256 verification."
        }
    }
}

final class TransferSession {
    static let maximumFileSize = 100 * 1024 * 1024
    static let maximumChunks = 200_000
    static let maximumChunkSize = 8 * 1024

    let transferID: String
    let fileName: String
    let fileSize: Int
    let totalChunks: Int
    let fileHash: String

    private var chunks: [Int: Data] = [:]
    private(set) var duplicates = 0
    private(set) var invalid = 0

    init(setup: SetupPacket) throws {
        guard Self.isValid(setup) else { throw TransferError.invalidPacket }
        transferID = setup.id
        fileName = setup.n
        fileSize = setup.s
        totalChunks = setup.t
        fileHash = setup.f
    }

    var received: Int { chunks.count }
    var isComplete: Bool { received == totalChunks }
    var progress: Double { Double(received) / Double(totalChunks) }
    var missingCount: Int { totalChunks - received }

    @discardableResult
    func accept(payload: String) -> PacketResult {
        if let setup = try? JSONDecoder().decode(SetupPacket.self, from: Data(payload.utf8)),
           setup.k == "setup" {
            return setup.id == transferID ? .setup : .otherTransfer
        }
        guard let packet = try? JSONDecoder().decode(QRPacket.self, from: Data(payload.utf8)),
              Self.isValid(packet) else {
            invalid += 1
            return .invalid
        }

        guard packet.id == transferID else { return .otherTransfer }
        guard packet.n == fileName,
              packet.s == fileSize,
              packet.t == totalChunks,
              packet.f == fileHash,
              let bytes = Data(base64Encoded: packet.d),
              bytes.count <= Self.maximumChunkSize,
              Self.sha256(bytes) == packet.h else {
            invalid += 1
            return .invalid
        }

        if let existing = chunks[packet.i] {
            if existing == bytes {
                duplicates += 1
                return .duplicate
            }
            invalid += 1
            return .invalid
        }

        chunks[packet.i] = bytes
        return .accepted
    }

    func assemble() throws -> Data {
        guard isComplete else { throw TransferError.incomplete }
        var output = Data()
        output.reserveCapacity(fileSize)

        for index in 0..<totalChunks {
            guard let chunk = chunks[index] else { throw TransferError.incomplete }
            output.append(chunk)
            guard output.count <= fileSize else { throw TransferError.sizeMismatch }
        }

        guard output.count == fileSize else { throw TransferError.sizeMismatch }
        guard Self.sha256(output) == fileHash else { throw TransferError.hashMismatch }
        return output
    }

    static func decodeSetup(_ payload: String) throws -> SetupPacket {
        let setup = try JSONDecoder().decode(SetupPacket.self, from: Data(payload.utf8))
        guard isValid(setup) else { throw TransferError.invalidPacket }
        return setup
    }

    private static func isValid(_ packet: QRPacket) -> Bool {
        packet.v == 1 && packet.k == "data" &&
        packet.id.count == 12 && packet.id.allSatisfy(\.isHexDigit) &&
        !packet.n.isEmpty && packet.n == URL(fileURLWithPath: packet.n).lastPathComponent &&
        packet.s >= 0 && packet.s <= maximumFileSize &&
        packet.t > 0 && packet.t <= maximumChunks &&
        packet.i >= 0 && packet.i < packet.t &&
        packet.h.count == 64 && packet.h.allSatisfy(\.isHexDigit) &&
        packet.f.count == 64 && packet.f.allSatisfy(\.isHexDigit)
    }

    private static func isValid(_ setup: SetupPacket) -> Bool {
        setup.v == 1 && setup.k == "setup" &&
        setup.id.count == 12 && setup.id.allSatisfy(\.isHexDigit) &&
        !setup.n.isEmpty && setup.n == URL(fileURLWithPath: setup.n).lastPathComponent &&
        setup.s >= 0 && setup.s <= maximumFileSize &&
        setup.t > 0 && setup.t <= maximumChunks &&
        setup.f.count == 64 && setup.f.allSatisfy(\.isHexDigit) &&
        setup.ms >= 100 && setup.ms <= 5_000
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
