# QRA1 protocol

Each QR code contains one compact JSON object. Packets may arrive in any order and may be repeated.

```json
{"v":1,"id":"9fb2d1c4a6e8","n":"photo.jpg","s":145203,"i":4,"t":224,"d":"base64...","h":"chunk sha256 hex","f":"file sha256 hex"}
```

| Field | Meaning |
|---|---|
| `v` | Protocol version; must be `1` |
| `id` | Random transfer identifier |
| `n` | UTF-8 file name without path components |
| `s` | Original file size in bytes |
| `i` | Zero-based chunk index |
| `t` | Total chunk count |
| `d` | Standard padded Base64 of raw chunk bytes |
| `h` | Lowercase SHA-256 hex of raw chunk bytes |
| `f` | Lowercase SHA-256 hex of the complete file |

All packets for one transfer repeat the immutable metadata. A receiver must reject a packet when `id`, `n`, `s`, `t`, or `f` differs from the active session. Duplicate indexes with identical data are ignored. Conflicting duplicates are invalid.

After receiving indexes `0..t-1`, concatenate decoded chunks in index order. The result is accepted only when its byte length equals `s` and its SHA-256 equals `f`.

