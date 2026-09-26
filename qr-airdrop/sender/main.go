package main

import (
	"fmt"
	"os"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	qrcode "github.com/skip2/go-qrcode"
)

type tickMsg time.Time
type model struct { frames [][]byte; file string; index int; fps float64; paused bool; width, height int; err error }

func tick(fps float64) tea.Cmd { return tea.Tick(time.Duration(float64(time.Second)/fps), func(t time.Time) tea.Msg { return tickMsg(t) }) }
func (m model) Init() tea.Cmd { return tick(m.fps) }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch v := msg.(type) {
	case tea.WindowSizeMsg: m.width, m.height = v.Width, v.Height
	case tickMsg:
		if !m.paused { m.index = (m.index + 1) % len(m.frames) }
		return m, tick(m.fps)
	case tea.KeyMsg:
		switch v.String() {
		case "q", "ctrl+c": return m, tea.Quit
		case " ": m.paused = !m.paused
		case "left": m.index = (m.index - 1 + len(m.frames)) % len(m.frames)
		case "right": m.index = (m.index + 1) % len(m.frames)
		case "up": if m.fps < 8 { m.fps += .5 }
		case "down": if m.fps > .5 { m.fps -= .5 }
		case "r": m.index = 0
		}
	}
	return m, nil
}

func (m model) View() string {
	if m.err != nil { return "Error: " + m.err.Error() + "\n\nPress q to quit.\n" }
	qr, err := qrcode.New(string(m.frames[m.index]), qrcode.Medium)
	if err != nil { return "QR error: " + err.Error() }
	bitmap := qr.Bitmap()
	var b strings.Builder
	// Each half-block stores two square QR modules: foreground above,
	// background below. This keeps the QR's geometry square and compact.
	pad := 4
	size := len(bitmap) + pad*2
	module := func(x, y int) bool {
		if x < pad || y < pad || x >= size-pad || y >= size-pad { return false }
		return bitmap[y-pad][x-pad]
	}
	for y := 0; y < size; y += 2 {
		for x := 0; x < size; x++ {
			top, bottom := module(x, y), module(x, y+1)
			fg, bg := 97, 107
			if top { fg = 30 }
			if bottom { bg = 40 }
			b.WriteString(fmt.Sprintf("\x1b[%d;%dm▀", fg, bg))
		}
		b.WriteString("\x1b[0m\n")
	}
	state := "PLAYING"; if m.paused { state = "PAUSED" }
	b.WriteString(fmt.Sprintf("\n%s  •  frame %d/%d  •  %.1f fps  •  %s\n", m.file, m.index+1, len(m.frames), m.fps, state))
	b.WriteString("space pause  ←/→ frame  ↑/↓ speed  r restart  q quit\n")
	return b.String()
}

func main() {
	if len(os.Args) != 2 { fmt.Fprintln(os.Stderr, "usage: qrairdrop <file>"); os.Exit(2) }
	data, err := os.ReadFile(os.Args[1])
	if err != nil { fmt.Fprintln(os.Stderr, err); os.Exit(1) }
	frames, err := makePackets(os.Args[1], data, 650)
	if err != nil { fmt.Fprintln(os.Stderr, err); os.Exit(1) }
	m := model{frames: frames, file: os.Args[1], fps: 3}
	if _, err := tea.NewProgram(m, tea.WithAltScreen()).Run(); err != nil { fmt.Fprintln(os.Stderr, err); os.Exit(1) }
}
