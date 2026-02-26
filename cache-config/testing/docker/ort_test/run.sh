#!/bin/bash
#
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
#

set -o errexit -o nounset -o pipefail

ping_to() {
	t3c \
		"apply" \
		"--traffic-ops-insecure=true" \
		"--traffic-ops-timeout-milliseconds=3000" \
		"--traffic-ops-user=$TO_ADMIN_USER" \
		"--traffic-ops-password=$TO_ADMIN_PASS" \
		"--traffic-ops-url=$TO_URI" \
		"--cache-host-name=atlanta-edge-03" \
		"-vv" \
		"--run-mode=badass"
}

export GOPATH=/root/go
export PATH=$PATH:/usr/local/go/bin
export TERM=xterm

/bin/ln -sf /root/go/src/github.com/jruszo/trafficcontrol /trafficcontrol
/bin/ln -sf /trafficcontrol/cache-config/testing/ort-tests /ort-tests

if [ -f /trafficcontrol/GO_VERSION ]; then
	go_version=$(cat /trafficcontrol/GO_VERSION)
	curl -Lo go.tar.gz "https://dl.google.com/go/go${go_version}.linux-amd64.tar.gz"
	tar -C /usr/local -xzf go.tar.gz
	ln -sf /usr/local/go/bin/go /usr/bin/go
	rm go.tar.gz
else
	echo "no GO_VERSION file, unable to install go"
	exit 1
fi

if [[ -f /systemctl.sh ]]; then
	if [[ -x /bin/systemctl ]]; then
		mv /bin/systemctl /bin/systemctl.save
	elif [[ -x /usr/bin/systemctl ]]; then
		mv /usr/bin/systemctl /usr/bin/systemctl.save
	fi
	cp /systemctl.sh /bin/systemctl
	chmod 0755 /bin/systemctl
fi

# Wait for the local test package repo to be up, then refresh apt metadata.
until curl --silent --fail http://yumserver/Packages.gz >/dev/null; do
	echo "waiting for yumserver apt index"
	sleep 2
done
apt-get update

cd "$(realpath /ort-tests)"
go mod vendor

cp /ort-tests/tc-fixtures.json /tc-fixtures.json

ats_deb_file="$(ls /yumserver/test-debs/trafficserver*.deb | head -n1 || true)"
if [[ -z "${ats_deb_file}" ]]; then
	echo "ERROR: No Traffic Server DEB was found"
	exit 2
fi

ats_deb_version="$(dpkg-deb -f "${ats_deb_file}" Version)"
if [[ -z "${ats_deb_version}" ]]; then
	echo "ERROR: Unable to read Traffic Server DEB version"
	exit 2
fi

cat /ort-tests/tc-fixtures.json | jq --arg ATS_VER "${ats_deb_version}" '.profiles[] |= (
	select(.params != null).params[] |= (
		select(.configFile == "package" and .name == "trafficserver").value = $ATS_VER
	)
)' > /ort-tests/tc-fixtures.json.tmp

if ! jq -r --arg ATS_VER "${ats_deb_version}" '.profiles[] |
	select(.params != null).params[] |
	select(.configFile == "package" and .name == "trafficserver").value' /ort-tests/tc-fixtures.json.tmp | grep -qF "${ats_deb_version}"; then
	echo "Traffic Server package version ${ats_deb_version} was not set"
	exit 2
fi

ping_to

echo "waiting for all the to_server container to initialize."
i=0
sleep_time=3
while ! nc "$TO_HOSTNAME" "$TO_PORT" </dev/null; do
	echo "waiting for $TO_HOSTNAME:$TO_PORT"
	sleep "$sleep_time"
	((i+=1))
	if [ "$i" -gt 10 ]; then
		d=$((i * sleep_time))
		echo "$TO_HOSTNAME:$TO_PORT is unavailable after $d seconds, giving up"
		exit 1
	fi
done

mv /ort-tests/tc-fixtures.json.tmp /tc-fixtures.json
(touch test.log && chmod a+rw test.log && tail -f test.log) &

go test --cfg=conf/docker-edge-cache.conf 2>&1 >> test.log
if [[ $? != 0 ]]; then
	echo "ERROR: ORT tests failure"
	exit 3
fi

exit 0
