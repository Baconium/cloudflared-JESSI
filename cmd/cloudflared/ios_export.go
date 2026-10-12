//go:build ios

package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"os"
	"sync"
	"unsafe"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/urfave/cli/v2"

	"github.com/cloudflare/cloudflared/cmd/cloudflared/access"
	"github.com/cloudflare/cloudflared/cmd/cloudflared/cliutil"
	"github.com/cloudflare/cloudflared/cmd/cloudflared/tunnel"
	"github.com/cloudflare/cloudflared/metrics"
)

var (
	iosMu       sync.Mutex
	iosShutdown chan struct{}
)

//export cloudflared_run
func cloudflared_run(argc C.int, argv **C.char) C.int {
	args := make([]string, 0, int(argc)+1)
	args = append(args, "cloudflared")
	for _, p := range unsafe.Slice(argv, int(argc)) {
		args = append(args, C.GoString(p))
	}

	os.Setenv("QUIC_GO_DISABLE_ECN", "1")
	registry := prometheus.NewRegistry()
	prometheus.DefaultRegisterer = registry
	prometheus.DefaultGatherer = registry
	metrics.RegisterBuildInfo(BuildType, BuildTime, Version)
	bInfo := cliutil.GetBuildInfo(BuildType, Version)

	shutdown := make(chan struct{})
	iosMu.Lock()
	iosShutdown = shutdown
	iosMu.Unlock()

	cli.OsExiter = func(int) {}

	app := &cli.App{}
	app.Name = "cloudflared"
	app.Version = Version
	app.Flags = flags()
	app.Commands = tunnel.Commands()
	tunnel.Init(bInfo, shutdown)
	access.Init(shutdown, Version)

	if err := app.Run(args); err != nil {
		os.Stderr.WriteString("cloudflared: " + err.Error() + "\n")
		return 1
	}
	return 0
}

//export cloudflared_stop
func cloudflared_stop() {
	iosMu.Lock()
	defer iosMu.Unlock()
	if iosShutdown != nil {
		close(iosShutdown)
		iosShutdown = nil
	}
}
