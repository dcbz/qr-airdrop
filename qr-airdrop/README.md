# QR AirDrop

QR AirDrop transfers a file from a terminal to an iPhone using only animated QR codes. The sender splits the file into JSON packets and renders each packet as a QR frame. The receiver scans those frames in any order, verifies chunk integrity, reconstructs the file, and shares it from the device.

## Components

- `sender/` — Go terminal program that reads a file, creates packetized QR frames, and renders them with a Bubble Tea UI.
- `receiver/` — Expo React Native app that scans QR codes, validates transfer metadata, reassembles the file, and saves it to the app document directory.
- `PROTOCOL.md` — concise protocol definition for packet structure and validation rules.

No server, account, pairing step, Wi‑Fi, or USB link is required.

## Quick start

### Sender

```bash
cd sender
go mod tidy
go run . /path/to/file
```

Maximize the terminal window and keep the whole QR code visible. The app displays controls underneath the QR animation.

### Receiver

```bash
cd receiver
npm install
npx expo start --tunnel
```

Install Expo Go on the iPhone, open the generated QR link, allow camera access, and point the device at the sender output.

## Sender controls

| Key | Action |
|---|---|
| Space | Pause or resume |
| Left / Right | Move to previous or next frame |
| Up / Down | Increase or decrease playback speed |
| `r` | Restart from the first frame |
| `q` | Quit |

## Protocol summary

Each QR payload is a JSON packet with fields for:

- transfer id
- file name
- original length
- chunk index and total count
- base64 chunk data
- chunk SHA-256 hash
- file SHA-256 hash

The receiver rejects malformed packets, duplicate indexes, and mismatched metadata. A transfer is accepted only after all chunks are present and the reconstructed file matches the declared byte length and hash.

## Validation

```bash
cd sender && go test ./...
cd receiver && npm test -- --runInBand
cd receiver && npm run typecheck
```

The project currently passes the sender Go tests and the receiver Jest + TypeScript checks.
