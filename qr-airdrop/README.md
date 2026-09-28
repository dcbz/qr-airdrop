# QR AirDrop

Transfer a file from a computer to an iPhone using only animated QR codes.

The project has two parts:

- `sender/`: a Go terminal UI that splits a file into QR frames and loops them.
- `receiver/`: an Expo iPhone app that scans frames in any order, verifies them, reconstructs the file, and opens the iOS share sheet.

No account, server, local network, or cable is used for the transfer.

## Quick start

### Sender

Install Go 1.23 or newer, then:

```bash
cd sender
go run . path/to/file.zip
```

Maximize the terminal and keep the entire QR code visible. Scan the stationary setup QR first. When the iPhone says **Ready — press Enter on the sender**, press Enter and the timed data stream begins automatically.

### iPhone receiver

Install Node 20 or newer, then:

```bash
cd receiver
npm install
npx expo start --tunnel
```

Install **Expo Go** on the iPhone and open the Expo link. Grant camera access, point the phone at the terminal, and hold it steady while the progress increases.

The app writes the reconstructed bytes to its document directory, verifies SHA-256, then opens the iOS share sheet.

## Sender controls

| Key | Action |
|---|---|
| Enter | Start the timed data stream after setup succeeds |
| `r` | Stop and show the setup QR again |
| `q` | Quit |

## Practical settings

The default payload is 650 raw bytes per frame at a fixed 3 frames per second. The setup QR advertises the 333 ms frame interval. Start close to the screen and move back until the entire quiet border fits inside the scanner guide.

Terminal QR codes depend on accurate module geometry. The sender uses each Unicode half-block's foreground and background to draw two square modules in one terminal cell. This fits a useful payload into an ordinary 120-column terminal. Disable terminal transparency and font ligatures if scanning is unreliable.

## Test

```bash
cd sender && go test ./...
cd receiver && npm test
```

See [PROTOCOL.md](PROTOCOL.md) for the exact packet format.
