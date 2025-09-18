package main

import (
	"context"
	"io"
	"log"
	"net"
	"strconv"
	"strings"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/keepalive"
	"google.golang.org/grpc/reflection"

	ping "gRPC_bidir_streaming/pb_files"
)

type pingServer struct {
	ping.UnimplementedPingServiceServer
}

func (s *pingServer) Chat(stream ping.PingService_ChatServer) error {
	ctx := stream.Context()
	errCh := make(chan error, 2)

	// Launch both behaviors in separate goroutines
	go startServerPushes(ctx, stream, errCh)
	go startServerReceive(stream, errCh)

	// Return on first error or ctx.Done()
	return <-errCh
}

// Goroutine A: send Server push messages every 10s
func startServerPushes(
	ctx context.Context,
	stream ping.PingService_ChatServer,
	errCh chan<- error,
) {
	ticker := time.NewTicker(10 * time.Second)
	defer ticker.Stop()

	i := 0
	for {
		select {
		case <-ctx.Done():
			errCh <- nil
			return
		case <-ticker.C:
			i++
			msg := "Server push " + strconv.Itoa(i)
			log.SetPrefix("\n")
			log.Printf("Server sent push to client: %q ****************", msg)
			log.SetPrefix("")
			if err := stream.Send(&ping.PingResponse{Payload: msg}); err != nil {
				errCh <- err
				return
			}
		}
	}
}

// Goroutine B: receive client messages and echo them
func startServerReceive(
	stream ping.PingService_ChatServer,
	errCh chan<- error,
) {
	for {
		req, err := stream.Recv()
		if err == io.EOF {
			errCh <- nil
			return
		}
		if err != nil {
			errCh <- err
			return
		}
		if strings.HasPrefix(req.Payload, "Client ack: Server push") {
			log.Printf("Server received response for push from client: %q", req.Payload)
		} else {
			log.Printf("Server received hello from client: %q", req.Payload)
		}

		echo := "Server echo: " + req.Payload
		if err := stream.Send(&ping.PingResponse{Payload: echo}); err != nil {
			errCh <- err
			return
		}
	}
}

func main() {
	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	srv := grpc.NewServer(
		grpc.KeepaliveParams(keepalive.ServerParameters{
			MaxConnectionIdle: 30 * time.Minute,
			Time:              10 * time.Minute,
			Timeout:           20 * time.Second,
		}),
		grpc.KeepaliveEnforcementPolicy(keepalive.EnforcementPolicy{
			MinTime:             1 * time.Minute,
			PermitWithoutStream: true,
		}),
	)

	ping.RegisterPingServiceServer(srv, &pingServer{})
	reflection.Register(srv)

	log.Println("gRPC server listening on :50051")
	if err := srv.Serve(lis); err != nil {
		log.Fatalf("server terminated: %v", err)
	}
}
