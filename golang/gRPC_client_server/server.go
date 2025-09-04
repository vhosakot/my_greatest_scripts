package main

import (
    "context"
    "fmt"
    "log"
    "net"

    "google.golang.org/grpc"
    pb "grpc_server/hello" // Update this path
)

type server struct {
    pb.UnimplementedHelloServiceServer
}

func (s *server) SayHello(ctx context.Context, req *pb.HelloRequest) (*pb.HelloResponse, error) {
    log.Printf("Received request for name: %s", req.Name)
    return &pb.HelloResponse{Message: "Hello, " + req.Name + "!"}, nil
}

func main() {
    listener, err := net.Listen("tcp", "127.0.0.1:50052")
    if err != nil {
        log.Fatalf("Failed to listen: %v", err)
    }

    grpcServer := grpc.NewServer()
    pb.RegisterHelloServiceServer(grpcServer, &server{})

    fmt.Println("🚀 gRPC server is running on 127.0.0.1:50052")
    if err := grpcServer.Serve(listener); err != nil {
        log.Fatalf("Failed to serve: %v", err)
    }
}
