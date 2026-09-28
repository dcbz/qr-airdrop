# Native iPhone receiver

This SwiftUI app receives QRA1 packets from the Go sender. It first scans a stationary setup QR and tells the user when to press Enter on the sender. It then uses AVFoundation to capture the automatic timed stream, CryptoKit for per-chunk and final SHA-256 verification, and the native share sheet for exporting the finished file.

## Open the Xcode project

```bash
cd swift-receiver
open QRDrop.xcodeproj
```

Select the `QRDrop` target, choose your Apple development team under **Signing & Capabilities**, connect the iPhone, and press Run. The project targets iOS 17 or newer and has no third-party runtime dependencies. `project.yml` is included only as an optional way to regenerate the project with XcodeGen.

## Test

Run the `QRDropTests` scheme in Xcode or:

```bash
xcodebuild test \
  -project QRDrop.xcodeproj \
  -scheme QRDrop \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

The receiver accepts packets in any order, ignores identical duplicates, rejects conflicting or corrupt chunks, validates declared limits, and writes the file only after its final size and SHA-256 match.
