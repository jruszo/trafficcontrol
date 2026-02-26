#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at

#  http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

FROM ubuntu:7

RUN apt -y --setopt=tsflags=nodocs update && \
    apt -y --setopt=tsflags=nodocs install httpd && \
    apt -y --setopt=tsflags=nodocs install perl && \
    apt -y --setopt=tsflags=nodocs install git && \
    apt -y --setopt=tsflags=nodocs install golang && \
    apt -y --setopt=tsflags=nodocs install openssl && \
    apt clean all

#EXPOSE 80

# Simple startup script to avoid some issues observed with container restart
ADD setup-and-run.sh setup-and-run.sh /
RUN chmod -v +x /setup-and-run.sh
ADD remap-base-test.json /remap-base-test.json
ADD grove.cfg /grove.cfg
ADD tests /tests
ADD compare_gets.go /compare_gets.go

CMD ["/setup-and-run.sh"]
