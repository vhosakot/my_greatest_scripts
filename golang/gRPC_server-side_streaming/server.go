package main

import (
	"fmt"
	"log"
	"net"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/reflection"

	greeterpb "gRPC_server-side_streaming/greeterpb"
)

type greeterServer struct {
	greeterpb.UnimplementedGreeterServer
}

func (s *greeterServer) SayHelloStream(req *greeterpb.HelloRequest, stream greeterpb.Greeter_SayHelloStreamServer) error {
	fmt.Printf("Received from client: %+v\n", req)

	name := req.GetName()
	count := req.GetCount()
	if count <= 0 {
		count = 5
	}

	// Stream responses periodically; honor client cancellation.
	for i := int32(1); i <= count; i++ {
		// Check if the client canceled or deadline exceeded.
		if err := stream.Context().Err(); err != nil {
			return err
		}

		msg := fmt.Sprintf("Hello, %s! (%d/%d)", name, i, count)
		resp := &greeterpb.HelloResponse{
			Message: msg,
			Seq:     i,
		}

		fmt.Printf("Sending to client: %+v\n", resp)
		if err := stream.Send(resp); err != nil {
			return err
		}

		time.Sleep(500 * time.Millisecond)
	}

	return nil
}

func main() {
	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("listen: %v", err)
	}

	grpcServer := grpc.NewServer()

	// Register Greeter
	greeterpb.RegisterGreeterServer(grpcServer, &greeterServer{})

	// Health and reflection for tooling
	healthSrv := health.NewServer()
	healthSrv.SetServingStatus("", healthpb.HealthCheckResponse_SERVING)
	healthpb.RegisterHealthServer(grpcServer, healthSrv)
	reflection.Register(grpcServer)

	log.Println("gRPC server listening on :50051")
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("serve: %v", err)
	}
}
