# QR AirDrop

QR AirDrop is a proof-of-concept file transfer app that sends a file from a terminal to an iPhone by encoding file chunks as QR packets. The sender emits animated QR frames, and the receiver scans them in any order, verifies each chunk, and reconstructs the original file.

## Project structure

- `qr-airdrop/sender` — Go CLI that reads a file, splits it into packetized QR payloads, and displays animated QR frames in a terminal UI.
- `qr-airdrop/receiver` — Expo React Native app that scans QR frames, validates packet metadata and hashes, reassembles the file, and offers the iPhone share sheet.
- `qr-airdrop/PROTOCOL.md` — exact JSON packet format and validation rules.

## Quick start

### 1) Send a file

Requires Go 1.23+

```bash
cd qr-airdrop/sender
go mod tidy
go run . /path/to/file
```

Open a terminal with high contrast, maximize it, and keep the QR code fully visible. Use the on-screen controls to pause, adjust speed, or restart.

### 2) Receive on an iPhone

Requires Node 20+ and Expo Go on the phone.

```bash
cd qr-airdrop/receiver
npm install
npx expo start --tunnel
```

Open the Expo link in Expo Go, grant camera access, and point the device at the terminal while the sender displays QR frames.

## How it works

- The sender chunks a file into JSON packets containing the file name, size, chunk index, total chunks, and SHA-256 hashes.
- Each packet is rendered into a QR code and shown as an animated frame.
- The receiver accepts shuffled and duplicate packets, rejects malformed or tampered payloads, and reconstructs the file once all chunks arrive.
- Final verification checks the total byte length and the final SHA-256 hash before saving the file.

## Verification

```bash
cd qr-airdrop/sender
go test ./...

cd ../receiver
npm test -- --runInBand
npm run typecheck
```

This repository currently passes its sender Go tests and the receiver Jest + TypeScript checks.
