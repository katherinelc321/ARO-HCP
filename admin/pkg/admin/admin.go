package admin

import (
	"context"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"strings"
	"sync/atomic"

	"github.com/Azure/ARO-HCP/internal/ocm"
)

type Admin struct {
	clusterServiceConfig ocm.ClusterServiceConfig
	server               http.Server
	listener             net.Listener
	logger               *slog.Logger
	location             string
	done                 chan struct{}
	ready                atomic.Bool
}

func NewAdmin(logger *slog.Logger, listener net.Listener, location string) *Admin {
	a := &Admin{
		logger:   logger,
		listener: listener,
		location: strings.ToLower(location),
		done:     make(chan struct{}),
	}

	// Set up http.Server and routes via the separate routes() function
	a.server = http.Server{
		Handler: a.adminRoutes(), // Separate function for setting up ServeMux
		BaseContext: func(net.Listener) context.Context {
			return context.WithValue(context.Background(), "logger", logger)
		},
	}

	return a
}

func (a *Admin) Run(ctx context.Context, stop <-chan struct{}) {
	if stop != nil {
		go func() {
			<-stop
			a.ready.Store(false)
			_ = a.server.Shutdown(ctx)
		}()
	}

	a.logger.Info(fmt.Sprintf("listening on %s", a.listener.Addr().String()))
	a.ready.Store(true)

	if err := a.server.Serve(a.listener); err != nil && err != http.ErrServerClosed {
		a.logger.Error(err.Error())
		os.Exit(1)
	}

	close(a.done)
}
