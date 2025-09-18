Asynchronous communication between gRPC client and gRPC server using gRPC bidirectional streaming.

#### Directory structure:

```
% go env | grep GOPATH
GOPATH='/Users/vhosakot/go'

% pwd
/Users/vhosakot/go/src/gRPC_bidir_streaming

% tree
.
├── client.go
├── client1.go
├── go.mod
├── go.sum
├── pb_files
│   ├── ping_grpc.pb.go
│   └── ping.pb.go
├── ping.proto
└── server.go
2 directories, 8 files
```

#### Install Protobuf and generate the code in pb_files/ directory:

```
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
protoc --go_out=. --go-grpc_out=. ping.proto
```

#### Start the server:

```
go mod init
go mod tidy

% go run server.go 
2025/09/18 16:01:56 gRPC server listening on :50051
```

#### In a different terminal window, test the server with the client:

```
% go run client.go 
2025/09/18 16:02:22 Opening Chat gRPC stream (waits for READY)…

2025/09/18 16:02:24 Client sent to server: "hello 1"
2025/09/18 16:02:24 Client got response from server: "Server echo: hello 1"
...
```

Another client is in `client1.go` and it can be tested too.
