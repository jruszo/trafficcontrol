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
		ca-certificates \
		curl \
		gcc \
		git \
		jq \
		lua5.4 \
		ncat \
		dpkg \
		python3 && \
	rm -rf /var/lib/apt/lists/* && \
	git config --global --add safe.directory '*'

ADD ort_test/trafficcontrol-cache-config*.deb /trafficcontrol-cache-config.deb
RUN dpkg -i --force-depends /trafficcontrol-cache-config.deb

RUN printf '%s\n' 'deb [trusted=yes] http://yumserver ./' > /etc/apt/sources.list.d/ort-test.list

RUN sed -i 's/HOME\/bin/HOME\/bin:\/usr\/local\/go\/bin:/g' /root/.bashrc &&\
	echo "GOPATH=/root/go; export GOPATH" >> /root/.bashrc &&\
	echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config &&\
	mkdir -p /root/go

ADD ort_test/run.sh ort_test/systemctl.sh /

ENTRYPOINT /run.sh
