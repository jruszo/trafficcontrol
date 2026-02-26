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

FROM ubuntu:24.04
MAINTAINER dev@trafficcontrol.apache.org
EXPOSE 80 443

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		brotli \
		ca-certificates \
		curl \
		gcc \
		git \
		hwloc \
		jq \
		libjansson-dev \
		libjansson4 \
		libmaxminddb0 \
		lua5.4 \
		luajit \
		man-db \
		ncat \
		tcl \
		dpkg && \
	rm -rf /var/lib/apt/lists/*

ADD health-check-test/systemctl.sh /
RUN if [[ -x /usr/bin/systemctl ]]; then cp /usr/bin/systemctl /usr/bin/systemctl.save; fi && \
	cp /systemctl.sh /usr/bin/systemctl && chmod 0755 /usr/bin/systemctl

ADD health-check-test/trafficserver*.deb /trafficserver.deb
ADD health-check-test/trafficcontrol-health-client*.deb /trafficcontrol-health-client.deb
RUN dpkg -i --force-depends /trafficserver.deb /trafficcontrol-health-client.deb

ADD health-check-test/tc-health-client.json /etc/trafficcontrol/

RUN sed -i 's/HOME\/bin/HOME\/bin:\/usr\/local\/go\/bin:/g' /root/.bashrc &&\
	echo "GOPATH=/root/go; export GOPATH" >> /root/.bashrc &&\
	mkdir -p /etc/ssh &&\
	echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config &&\
	mkdir -p /root/go

ADD variables.env /
ADD health-check-test/run.sh /
ADD health-check-test/parent.config /
ADD health-check-test/strategies.yaml /
RUN chmod +x /run.sh

ENTRYPOINT /run.sh
