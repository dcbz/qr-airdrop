import CryptoKit
import Foundation
import Testing
@testable import QRDrop

struct TransferSessionTests {
    @Test func reconstructsShuffledPacketsAndIgnoresDuplicates() throws {
        let packets = makePackets(Data("hello optical world".utf8), chunkSize: 4)
        let session = try TransferSession(setup: makeSetup(for: packets))

        #expect(session.accept(payload: packets[2]) == .accepted)
        #expect(session.accept(payload: packets[0]) == .accepted)
        #expect(session.accept(payload: packets[0]) == .duplicate)
        for packet in packets.dropFirst() { _ = session.accept(payload: packet) }

        #expect(try session.assemble() == Data("hello optical world".utf8))
    }

    @Test func rejectsDamagedChunk() throws {
        var object = try #require(JSONSerialization.jsonObject(with: Data(makePackets(Data("abcdef".utf8), chunkSize: 3)[0].utf8)) as? [String: Any])
        let session = try TransferSession(setup: makeSetup(for: [String(data: try JSONSerialization.data(withJSONObject: object), encoding: .utf8)!]))
        object["d"] = "AAAA"
        let damaged = String(data: try JSONSerialization.data(withJSONObject: object), encoding: .utf8)!
        #expect(session.accept(payload: damaged) == .invalid)
    }

    private func makePackets(_ data: Data, chunkSize: Int) -> [String] {
        let fileHash = hash(data)
        let total = max(1, Int(ceil(Double(data.count) / Double(chunkSize))))
        return (0..<total).map { index in
            let start = index * chunkSize
            let end = min(data.count, start + chunkSize)
            let chunk = data.subdata(in: start..<end)
            let object: [String: Any] = ["v": 1, "k": "data", "id": "abcdef123456", "n": "x.txt", "s": data.count, "i": index, "t": total, "d": chunk.base64EncodedString(), "h": hash(chunk), "f": fileHash]
            return String(data: try! JSONSerialization.data(withJSONObject: object), encoding: .utf8)!
        }
    }

    private func makeSetup(for packets: [String]) throws -> SetupPacket {
        let packetData = try #require(packets.first?.data(using: .utf8))
        let packet = try JSONDecoder().decode(QRPacket.self, from: packetData)
        return SetupPacket(v: 1, k: "setup", id: packet.id, n: packet.n, s: packet.s, t: packet.t, f: packet.f, ms: 333)
    }

    private func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
