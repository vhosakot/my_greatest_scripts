# python ubuntu xenial docker image
#
# to build the docker image:
#     docker build --rm -t python_ubuntu .
#
# to run the docker container:
#     $ docker run --hostname python_ubuntu --name python_ubuntu -d python_ubuntu
#     $ sudo docker exec -it python_ubuntu /bin/bash
#       root@python_ubuntu:/# python -V
#       Python 2.7.12
#
FROM ubuntu:16.04

RUN apt-get -y update && apt-get -y upgrade && \
    apt-get -y install --no-install-recommends \
        python2.7 python-setuptools python-minimal \
        python-pip && \
    pip install --upgrade pip && \
    # remove unwanted stuff in the container
    apt-get -y clean all && apt-get -y autoclean && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip

CMD ["sh", "-c", "while true ; do sleep 1 ; done"]
