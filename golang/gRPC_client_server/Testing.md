#### Directory structure:

```
% go env | grep GOPATH
GOPATH='/Users/vhosakot/go'

% pwd
/Users/vhosakot/go/src/grpc_server

% tree
.
├── client.go
├── go.mod
├── go.sum
├── hello
│   ├── hello_grpc.pb.go
│   └── hello.pb.go
├── hello.proto
├── server.go
└── Testing.md
3 directories, 8 files
```

#### Install Protobuf and generate the code in hello/ directory:

```
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
protoc --go_out=. --go-grpc_out=. hello.proto
```

#### Start the server:

```
go mod tidy

% go run server.go                              
🚀 gRPC server is running on 127.0.0.1:50052
```

#### In a different terminal window, test the server with the client:

```
% go run client.go
2025/09/04 08:23:57 Response from server: Hello, Gopher!
```
