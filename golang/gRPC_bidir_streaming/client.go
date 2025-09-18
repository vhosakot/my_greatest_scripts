package main

import (
	"context"
	"fmt"
	"log"
	"strings"
	"time"

	"io"

	"google.golang.org/grpc"
	"google.golang.org/grpc/backoff"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/keepalive"

	ping "gRPC_bidir_streaming/pb_files"
)

const addr = "localhost:50051"

func main() {
	conn, err := grpc.NewClient(
		addr,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithConnectParams(grpc.ConnectParams{
			Backoff: backoff.Config{
				BaseDelay:  1 * time.Second,
				Multiplier: 1.5,
				MaxDelay:   60 * time.Second,
			},
			MinConnectTimeout: 20 * time.Second,
		}),
		grpc.WithKeepaliveParams(keepalive.ClientParameters{
			Time:                5 * time.Minute,
			Timeout:             10 * time.Second,
			PermitWithoutStream: true,
		}),
	)
	if err != nil {
		log.Fatalf("grpc.NewClient(%q) failed: %v", addr, err)
	}
	defer conn.Close()

	client := ping.NewPingServiceClient(conn)
	ctx := context.Background()

	for {
		log.Println("Opening Chat gRPC stream (waits for READY)…")
		stream, err := client.Chat(ctx, grpc.WaitForReady(true))
		if err != nil {
			log.Printf("Chat() error: %v; retrying…", err)
			time.Sleep(1 * time.Second)
			continue
		}
		if err := runChatLoop(stream); err != nil {
			log.Printf("gRPC stream error: %v; restarting Chat…", err)
			time.Sleep(1 * time.Second)
			continue
		}
		break
	}
}

// runChatLoop launches two independent goroutines and waits for the first error.
func runChatLoop(stream ping.PingService_ChatClient) error {
	errCh := make(chan error, 2)
	ctx := stream.Context()

	go startClientHelloLoop(ctx, stream, errCh)
	go startClientReceiveLoop(stream, errCh)

	return <-errCh
}

// Goroutine A: send "hello N" every 2s
func startClientHelloLoop(
	ctx context.Context,
	stream ping.PingService_ChatClient,
	errCh chan<- error,
) {
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	i := 0
	for {
		select {
		case <-ctx.Done():
			errCh <- nil
			return
		case <-ticker.C:
			i++
			msg := fmt.Sprintf("hello %d", i)
			log.SetPrefix("\n")
			log.Printf("Client sent to server: %q", msg)
			log.SetPrefix("")
			if err := stream.Send(&ping.PingRequest{Payload: msg}); err != nil {
				errCh <- err
				return
			}
		}
	}
}

// Goroutine B: read server pushes and echoes, then ACK pushes
func startClientReceiveLoop(
	stream ping.PingService_ChatClient,
	errCh chan<- error,
) {
	for {
		resp, err := stream.Recv()
		if err == io.EOF {
			errCh <- nil
			return
		}
		if err != nil {
			errCh <- err
			return
		}
		if strings.HasPrefix(resp.Payload, "Server push") {
			log.Printf("Client got push from server: %q ****************", resp.Payload)
		} else {
			log.Printf("Client got response from server: %q", resp.Payload)
		}

		if len(resp.Payload) >= 12 && resp.Payload[:12] == "Server push " {
			ack := "Client ack: " + resp.Payload + " ****************"
			log.SetPrefix("\n")
			log.Printf("Client sent ack to server: %q", ack)
			log.SetPrefix("")
			if err := stream.Send(&ping.PingRequest{Payload: ack}); err != nil {
				errCh <- err
				return
			}
		}
	}
}
