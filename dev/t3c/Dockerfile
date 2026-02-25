# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
ARG ATS_VERSION=9.2.4
ARG GO_VERSION=1.26.0
ARG TRAFFICSERVER_ALPINE_IMAGE=trafficserver-alpine-local

# Default local ATS base image build to avoid requiring GHCR access.
FROM alpine:3.18 AS build-trafficserver
ARG ATS_VERSION
ADD https://archive.apache.org/dist/trafficserver/trafficserver-${ATS_VERSION}.tar.bz2 /tmp/
RUN set -o errexit -o nounset -o xtrace; \
    cd /tmp; \
    dirname=trafficserver-${ATS_VERSION}; \
    tar xf ${dirname}.tar.bz2; \
    rm ${dirname}.tar.bz2; \
    apk add --update --no-cache \
        # configure dependencies
        g++ \
        perl \
        openssl-dev \
        pcre-dev \
        make \
        # build dependencies
        fortify-headers \
        linux-headers \
        zlib-dev; \
    # Alpine versions above 3.16 do not contain package libexecinfo-dev,
    # which ATS needs.
    apk add --update --no-cache \
        --repository=https://dl-cdn.alpinelinux.org/alpine/v3.16/main/ \
        libexecinfo-dev; \
    cd $dirname; \
    # Fix is from apache/trafficserver-ingress-controller#151
    sed -i 's/PTHREAD_RWLOCK_WRITER_NONRECURSIVE_INITIALIZER_NP/PTHREAD_RWLOCK_INITIALIZER/' \
        include/tscore/ink_rwlock.h \
        include/tscpp/util/TsSharedMutex.h; \
    ./configure \
        --disable-tests \
        --enable-experimental-plugins \
        --prefix=/ \
        --with-user=ats \
        --with-group=ats; \
    threads=$(( $(nproc) )); \
    make -j $threads; \
    adduser -D ats; \
    make install DESTDIR=/tmp/built; \
    cd ..; \
    rm -r $dirname

FROM alpine:3.18 AS trafficserver-alpine-local
COPY --from=build-trafficserver /tmp/built/ /
RUN apk add --update --no-cache \
        # runtime dependencies
        libstdc++ \
        pcre && \
    # Alpine versions above 3.16 do not contain package libexecinfo,
    # which ATS needs.
    apk add --update --no-cache \
        --repository=https://dl-cdn.alpinelinux.org/alpine/v3.16/main/ \
        libexecinfo && \
    adduser -D ats
USER ats
CMD /bin/traffic_server

FROM golang:${GO_VERSION}-alpine AS get-go
FROM ${TRAFFICSERVER_ALPINE_IMAGE}
COPY --from=get-go /usr/local/go /usr/local/go
ENV PATH=/usr/local/go/bin:${PATH} \
	GOPATH=/go
ENV PATH=${GOPATH}/bin:${PATH}

ENV TC="/go/src/github.com/jruszo/trafficcontrol" GOFLAGS="--buildvcs=false"
VOLUME $TC
EXPOSE 80 8081

USER root
RUN apk add --no-cache \
	# inotify-tools is used for inotifywait in run.sh
	inotify-tools \
	# make is used for the t3c Makefile
	make \
	# gcc and musl-dev are used to build packages using CGO
	gcc musl-dev && \
	go install github.com/go-delve/delve/cmd/dlv@v1.26.0 && \
	rm -rf $GOPATH/pkg/*

RUN echo "stats_over_http.so" >> /etc/trafficserver/plugin.config && echo "system_stats.so" >> /etc/trafficserver/plugin.config

CMD ${TC}/dev/t3c/run.sh
