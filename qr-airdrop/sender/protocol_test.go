package main

import (
	"encoding/json"
	"testing"
)

func TestPacketsRoundTripMetadata(t *testing.T) {
	data := []byte("abcdefghijklmnopqrstuvwxyz")
	frames, err := makePackets("/tmp/test.txt", data, 10)
	if err != nil { t.Fatal(err) }
	if len(frames) != 3 { t.Fatalf("got %d frames", len(frames)) }
	var first, last packet
	if err := json.Unmarshal(frames[0], &first); err != nil { t.Fatal(err) }
	if err := json.Unmarshal(frames[2], &last); err != nil { t.Fatal(err) }
	if first.Name != "test.txt" || first.Size != len(data) || first.Total != 3 { t.Fatalf("bad metadata: %+v", first) }
	if first.ID != last.ID || first.FileHash != last.FileHash || last.Index != 2 { t.Fatal("inconsistent transfer") }
}

