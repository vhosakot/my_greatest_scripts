package main

import (
  "context"
  "fmt"
  "io"
  "log"
  "time"

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

  var reconnectCount int
  var reconnectStart time.Time

  for {
    if reconnectCount == 0 {
      reconnectStart = time.Now()
    }
    reconnectCount++
    log.Printf("Reconnect attempt # %d to gRPC server", reconnectCount)

    stream, err := client.Chat(ctx, grpc.WaitForReady(true))
    if err != nil {
      elapsed := time.Since(reconnectStart)
      log.Printf("Chat() failed: %v", err)
      log.Printf("Total reconnect time so far: %v", elapsed.Truncate(time.Second))
      time.Sleep(1 * time.Second)
      continue
    }

    log.Printf("Connected to gRPC server after %d attempt(s) and %v of waiting",
      reconnectCount, time.Since(reconnectStart).Truncate(time.Second))

    reconnectCount = 0
    reconnectStart = time.Time{}

    if err := runChatLoop(stream); err != nil {
      log.Printf("stream error: %v; restarting Chat…", err)
      time.Sleep(1 * time.Second)
      continue
    }
    break
  }
}

func runChatLoop(stream ping.PingService_ChatClient) error {
  errCh := make(chan error, 2)

  go startClientHelloLoop(stream, errCh)
  go startClientReceiveLoop(stream, errCh)

  return <-errCh
}

// Goroutine A: send "hello N" every 2s
func startClientHelloLoop(
  stream ping.PingService_ChatClient,
  errCh chan<- error,
) {
  ticker := time.NewTicker(2 * time.Second)
  defer ticker.Stop()

  i := 0
  for range ticker.C {
    i++
    msg := fmt.Sprintf("hello %d", i)
    log.Printf("Client sent: %q", msg)

    if err := stream.Send(&ping.PingRequest{Payload: msg}); err != nil {
      errCh <- err
      return
    }
  }
}

// Goroutine B: receive server pushes and echoes, then ACK pushes
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

    log.Printf("Client got: %q", resp.Payload)

    if len(resp.Payload) >= 12 && resp.Payload[:12] == "Server push " {
      ack := "Client ack: " + resp.Payload
      log.Printf("Client sent ack: %q", ack)
      if err := stream.Send(&ping.PingRequest{Payload: ack}); err != nil {
        errCh <- err
        return
      }
    }
  }
}
