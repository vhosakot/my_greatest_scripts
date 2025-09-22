CRUD data in open-source ClickHouse database using Golang HTTP APIs.

#### Directory structure:

```
% go env | grep GOPATH
GOPATH='/Users/vhosakot/go'

% pwd
/Users/vhosakot/go/src/clickhouse

% tree
.
├── clickhouse.go
├── default-password.xml
└── go.mod
1 directory, 3 files
```

#### Start Docker on Mac and run ClickHouse database in Docker container:

```
% cat default-password.xml
<yandex>
    <users>
        <default>
            <password>password1234</password>
        </default>
    </users>
</yandex>

docker run -d --name clickhouse-server \
  -p 8123:8123 \
  -v $(pwd)/default-password.xml:/etc/clickhouse-server/users.d/default-password.xml \
  clickhouse/clickhouse-server

% docker images
REPOSITORY                     TAG       IMAGE ID       CREATED      SIZE
clickhouse/clickhouse-server   latest    c48c1ed0a54e   2 days ago   969MB

% curl -u default:password1234 "http://localhost:8123/?query=SELECT+1"
1

# ClickHouse config file
docker exec -it clickhouse-server cat /etc/clickhouse-server/users.xml
```

#### Run ClickHouse client in Docker container and check the data in ClickHouse database:

```
% docker exec -it clickhouse-server clickhouse-client
ClickHouse client version 25.8.4.13 (official build).
Connecting to localhost:9000 as user default.
Password for user (default): password1234
Connected to ClickHouse server version 25.8.4.

72cc00484eb0 :) show databases;
SHOW DATABASES
Query id: 140be30e-23ff-4e42-ab80-a7f86d3379a0
   ┌─name───────────────┐
1. │ INFORMATION_SCHEMA │
2. │ default            │
3. │ information_schema │
4. │ system             │
   └────────────────────┘
4 rows in set. Elapsed: 0.003 sec. 

72cc00484eb0 :) show tables;
SHOW TABLES
Query id: 372a9b2e-f32a-44c6-8d62-e7653e926351
   ┌─name──┐
1. │ users │
   └───────┘
1 row in set. Elapsed: 0.004 sec.

72cc00484eb0 :) DESCRIBE TABLE users;
DESCRIBE TABLE users
Query id: 41c7c51f-cb76-4f53-8ec6-1a923594cd41
   ┌─name─────┬─type───┬─default_type─┬─default_expression─┬─comment─┬─codec_expression─┬─ttl_expression─┐
1. │ name     │ String │              │                    │         │                  │                │
2. │ age      │ UInt8  │              │                    │         │                  │                │
3. │ location │ String │              │                    │         │                  │                │
   └──────────┴────────┴──────────────┴────────────────────┴─────────┴──────────────────┴────────────────┘
3 rows in set. Elapsed: 0.002 sec. 

72cc00484eb0 :) SELECT * FROM users;
SELECT *
FROM users
Query id: d55ee105-fd6c-442a-bf28-1432bb5df593
Ok.
0 rows in set. Elapsed: 0.003 sec.

# How to find the Primary Key for the table
6a362a1769f0 :) SELECT primary_key FROM system.tables WHERE name = 'users' AND database = 'default';
SELECT primary_key
FROM system.tables
WHERE (name = 'users') AND (database = 'default')
Query id: 063f3ed3-87fc-41e1-9427-8965ceaba1d3
   ┌─primary_key─┐
1. │ name        │
   └─────────────┘
1 row in set. Elapsed: 0.003 sec. 

6a362a1769f0 :) SELECT * FROM users WHERE location != '';
SELECT *
FROM users
WHERE location != ''
Query id: 8d4e14e7-1a3c-4605-af2e-81ea4d846b15
   ┌─name─┬─age─┬─location──┐
1. │ John │  51 │ cambridge │
   └──────┴─────┴───────────┘
1 row in set. Elapsed: 0.003 sec. 
```

#### Run `clickhouse.go` and test it:

```
go mod init
go mod tidy

% go run clickhouse.go

======== createTable() ========
Response: 200 OK
'users' table created successfully!

======== checkTableExists() ========
Response: 200 OK
Table 'users' exists.

======== countRows() ========
Response: 200 OK
Row count in 'users' table: 0

======== readRows() ========
Response: 200 OK
Rows from 'users' table:    No rows found.

======== insertRow() ========
Response: 200 OK
        ======== cleanupOutdatedRows() ========
        Response: 200 OK
        Outdated rows cleaned up successfully!
Row inserted into 'users' table successfully!

======== countRows() ========
Response: 200 OK
Row count in 'users' table: 1

======== readRows() ========
Response: 200 OK
Rows from 'users' table:    John	50	boston

======== updateRow() ========
Response: 200 OK
        ======== cleanupOutdatedRows() ========
        Response: 200 OK
        Outdated rows cleaned up successfully!
Row updated in 'users' table successfully!

======== countRows() ========
Response: 200 OK
Row count in 'users' table: 1

======== readRows() ========
Response: 200 OK
Rows from 'users' table:    John	51	cambridge

======== readUpdatedRow() ========
Response: 200 OK
Updated Row:    John	51	cambridge

======== deleteRow() ========
Response: 200 OK
        ======== cleanupOutdatedRows() ========
        Response: 200 OK
        Outdated rows cleaned up successfully!
Row deleted from 'users' table successfully!

======== countRows() ========
Response: 200 OK
Row count in 'users' table: 1

======== readRows() ========
Response: 200 OK
Rows from 'users' table:    John	0	

======== readUpdatedRow() ========
Response: 200 OK
Updated Row:    John	0	

======== truncateAndDropTable() ========
Response: 200 OK
Response: 200 OK
Table 'users' truncated and dropped successfully!

======== checkTableExists() ========
Response: 200 OK
Table 'users' does NOT exist.
```

#### Stop the clickhouse-server docker container and remove it:

```
docker stop clickhouse-server && docker rm clickhouse-server
```
