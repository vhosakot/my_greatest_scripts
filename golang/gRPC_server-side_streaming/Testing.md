#### Directory structure:
```
% tree
.
├── client.go
├── go.mod
├── go.sum
├── greeter.proto
├── greeterpb
│   ├── greeter_grpc.pb.go
│   └── greeter.pb.go
└── server.go
2 directories, 7 files
```

#### Install Protobuf and generate the code in greeterpb/ directory:
```
go get google.golang.org/grpc@latest
go get google.golang.org/protobuf@latest
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
protoc --go_out=. --go-grpc_out=. greeter.proto

go mod tidy
```

#### Start the server:
```
% go run server.go
2025/11/24 14:03:35 gRPC server listening on :50051
Received from client: name:"Natick" count:7
Sending to client: message:"Hello, Natick! (1/7)" seq:1
Sending to client: message:"Hello, Natick! (2/7)" seq:2
Sending to client: message:"Hello, Natick! (3/7)" seq:3
Sending to client: message:"Hello, Natick! (4/7)" seq:4
Sending to client: message:"Hello, Natick! (5/7)" seq:5
Sending to client: message:"Hello, Natick! (6/7)" seq:6
Sending to client: message:"Hello, Natick! (7/7)" seq:7
```

#### In a different terminal window, test the server with the client:
```
% go run client.go
received: seq=1 message="Hello, Natick! (1/7)"
received: seq=2 message="Hello, Natick! (2/7)"
received: seq=3 message="Hello, Natick! (3/7)"
received: seq=4 message="Hello, Natick! (4/7)"
received: seq=5 message="Hello, Natick! (5/7)"
received: seq=6 message="Hello, Natick! (6/7)"
received: seq=7 message="Hello, Natick! (7/7)"
stream ended: EOF
```
