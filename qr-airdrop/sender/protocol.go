package main

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"path/filepath"
)

type packet struct {
	Version   int    `json:"v"`
	ID        string `json:"id"`
	Name      string `json:"n"`
	Size      int    `json:"s"`
	Index     int    `json:"i"`
	Total     int    `json:"t"`
	Data      string `json:"d"`
	ChunkHash string `json:"h"`
	FileHash  string `json:"f"`
}

func makePackets(path string, data []byte, chunkSize int) ([][]byte, error) {
	if chunkSize < 1 { return nil, fmt.Errorf("chunk size must be positive") }
	idBytes := make([]byte, 6)
	if _, err := rand.Read(idBytes); err != nil { return nil, err }
	id := hex.EncodeToString(idBytes)
	fileSum := sha256.Sum256(data)
	total := (len(data) + chunkSize - 1) / chunkSize
	if total == 0 { total = 1 }
	frames := make([][]byte, 0, total)
	for i := 0; i < total; i++ {
		start := i * chunkSize
		end := start + chunkSize
		if end > len(data) { end = len(data) }
		chunk := data[start:end]
		chunkSum := sha256.Sum256(chunk)
		p := packet{1, id, filepath.Base(path), len(data), i, total,
			base64.StdEncoding.EncodeToString(chunk), hex.EncodeToString(chunkSum[:]), hex.EncodeToString(fileSum[:])}
		encoded, err := json.Marshal(p)
		if err != nil { return nil, err }
		frames = append(frames, encoded)
	}
	return frames, nil
}

