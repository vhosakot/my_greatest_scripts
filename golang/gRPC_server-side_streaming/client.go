package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	greeterpb "gRPC_server-side_streaming/greeterpb"
)

func main() {
	for {
		// Try to connect
		fmt.Println("Connecting to server...")
		conn, err := grpc.Dial("localhost:50051",
			grpc.WithTransportCredentials(insecure.NewCredentials()),
			grpc.WithBlock(), // wait until connection succeeds or fails
		)
		if err != nil {
			log.Printf("dial failed: %v", err)
			time.Sleep(5 * time.Second)
			continue
		}

		client := greeterpb.NewGreeterClient(conn)

		// Use a fresh context each attempt
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		stream, err := client.SayHelloStream(ctx, &greeterpb.HelloRequest{
			Name:  "Natick",
			Count: 7,
		})
		if err != nil {
			log.Printf("SayHelloStream failed: %v", err)
			cancel()
			conn.Close()
			time.Sleep(5 * time.Second)
			continue
		}

		// Receive messages until error
		for {
			resp, recvErr := stream.Recv()
			if recvErr != nil {
				fmt.Println("stream ended:", recvErr)
				break
			}
			fmt.Printf("received: seq=%d message=%q\n", resp.GetSeq(), resp.GetMessage())
		}

		// Clean up before retry
		cancel()
		conn.Close()
		time.Sleep(5 * time.Second)
	}
}
