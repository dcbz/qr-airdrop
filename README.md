# QR AirDrop

QR AirDrop sends a file from a terminal to an iPhone using QR packets. The sender begins with a stationary setup QR. Once the native receiver confirms it is ready, pressing Enter starts an automatic timed stream. The receiver scans frames in any order, verifies each chunk, and reconstructs the original file.

## Project structure

- `qr-airdrop/sender` — Go CLI that reads a file, splits it into packetized QR payloads, and displays animated QR frames in a terminal UI.
- `swift-receiver` — native SwiftUI iPhone receiver using AVFoundation, CryptoKit, and the iOS share sheet.
- `qr-airdrop/receiver` — earlier Expo receiver retained for reference.
- `qr-airdrop/PROTOCOL.md` — exact JSON packet format and validation rules.

## Quick start

### 1) Send a file

Requires Go 1.23+

```bash
cd qr-airdrop/sender
go mod tidy
go run . /path/to/file
```

Open a terminal with high contrast, maximize it, and keep the QR code fully visible. Scan the stationary setup QR. When the iPhone says **Ready — press Enter on the sender**, press Enter to begin the fixed-rate stream.

### 2) Build the native iPhone receiver

Open the checked-in project in Xcode:

```bash
cd swift-receiver
open QRDrop.xcodeproj
```

Select the `QRDrop` target, choose your Apple development team under **Signing & Capabilities**, connect the iPhone, and press Run. The app targets iOS 17 or newer and has no third-party runtime dependencies.

## How it works

- The sender chunks a file into JSON packets containing the file name, size, chunk index, total chunks, and SHA-256 hashes.
- Each packet is rendered into a QR code and shown as an animated frame.
- The receiver accepts shuffled packets and identical duplicates, rejects malformed, conflicting, or tampered payloads, and reconstructs the file once all chunks arrive.
- Final verification checks the total byte length and SHA-256 before the file is written and offered through the native share sheet.

## Verification

```bash
cd qr-airdrop/sender
go test ./...

xcodebuild test \
  -project swift-receiver/QRDrop.xcodeproj \
  -scheme QRDrop \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
