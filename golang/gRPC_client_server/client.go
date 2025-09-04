package main

import (
    "context"
    "log"
    "time"

    pb "grpc_server/hello" // Make sure this matches your module + package
    "google.golang.org/grpc"
)

func main() {
    // Connect to the gRPC server
    conn, err := grpc.Dial("127.0.0.1:50052", grpc.WithInsecure())
    if err != nil {
        log.Fatalf("Failed to connect: %v", err)
    }
    defer conn.Close()

    // Create a client stub
    client := pb.NewHelloServiceClient(conn)

    // Prepare the request
    req := &pb.HelloRequest{Name: "Gopher"}

    // Send the request with a timeout
    ctx, cancel := context.WithTimeout(context.Background(), time.Second)
    defer cancel()

    resp, err := client.SayHello(ctx, req)
    if err != nil {
        log.Fatalf("Error calling SayHello: %v", err)
    }

    log.Printf("Response from server: %s", resp.Message)
}
