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

ARG BASE_IMAGE=ubuntu \
    ubuntu_version=24.04
FROM ${BASE_IMAGE}:${ubuntu_version}

ARG VNC_BUILD_USER
ENV VNC_USER=$VNC_BUILD_USER

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dnsutils \
        fluxbox \
        net-tools \
        netcat-openbsd \
        openssl \
        passwd \
        sudo \
        tigervnc-common \
        tigervnc-standalone-server \
        vlc \
        wget \
        xfonts-terminus \
        xterm \
        fonts-noto-core && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m $VNC_USER && \
    echo "$VNC_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER $VNC_USER
WORKDIR /home/$VNC_USER

RUN rm -rf /home/$VNC_USER/.vnc && \
    mkdir /home/$VNC_USER/.vnc && \
    mkdir /home/$VNC_USER/.fluxbox && \
    fluxbox-generate_menu -k -g -B -su -t xterm -b xterm && \
    sed 's/{xterm}/{xterm -bg black -fg white +sb}/g' -i /home/$VNC_USER/.fluxbox/menu && \
    dd if=/dev/urandom of=/dev/stdout count=12 bs=1 | vncpasswd -f > /home/$VNC_USER/.vnc/passwd && \
    chmod 600 /home/$VNC_USER/.vnc/passwd

ADD optional/vnc/vnc_startup.sh /home/$VNC_USER/.vnc/xstartup 

USER root

RUN systemd-machine-id-setup && \
    chmod +x /home/$VNC_USER/.vnc/xstartup

ADD optional/vnc/run.sh /

COPY dns/set-dns.sh \
     dns/insert-self-into-dns.sh \
     /usr/local/sbin/

EXPOSE 5909/tcp

CMD /run.sh
