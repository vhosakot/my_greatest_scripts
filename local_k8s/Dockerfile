FROM ubuntu:18.04

RUN echo "in Dockerfile" && \
    apt-get -y update && apt-get -y install nmap

# sleep forever
# CMD ["sh", "-c", "while true ; do sleep 1 ; done"]

# start TCP server in docker container
CMD ["sh", "-c", "echo \"== Starting TCP server in docker container ==\" && ncat -v -l -p 2399 -k"]
