#!/bin/sh
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

set -o errexit
set -o xtrace
trap '[ $? -eq 0 ] && exit 0 || echo "Error on line ${LINENO} of ${0}"; exit 1' EXIT

if [[ -n "$GOFLAGS" ]]; then
	export GOFLAGS="${GOFLAGS} -mod=mod"
else
	export GOFLAGS="-mod=mod"
fi

cd "$TC/traffic_stats"
user=trafficstats
uid="$(stat -c%u "$TC")"
gid="$(stat -c%g "$TC")"
if [[ "$(id -u)" != "$uid" ]]; then
	for dir in "${GOPATH}/bin" "${GOPATH}/pkg"; do
		if [[ -e "$dir" ]] && [[ "$(stat -c%u "$dir")" -ne "$uid" || "$(stat -c%g "$dir")" -ne "$gid" ]] ; then
			chown -R "${uid}:${gid}" "$dir"
		fi
	done

	adduser -Du"$uid" "$user"
	sed -Ei "s/^(${user}:.*:)[0-9]+(:)$/\1${gid}\2/" /etc/group
	exec su "$user" -- "$0"
fi

wait_for_traffic_ops() {
	until curl -skL https://trafficops/api/4.0/ping >/dev/null 2>&1; do
		echo "waiting for Traffic Ops on https://trafficops/api/4.0/ping"
		sleep 2
	done
}

wait_for_traffic_monitor() {
	until nc -z trafficmonitor 80 >/dev/null 2>&1; do
		echo "waiting for Traffic Monitor on trafficmonitor:80"
		sleep 2
	done
}

wait_for_influxdb() {
	until nc -z influxdb 8086 >/dev/null 2>&1; do
		echo "waiting for InfluxDB on influxdb:8086"
		sleep 2
	done
}

init_databases() {
	go run ./influxdb_tools/create \
		-url http://influxdb:8086 \
		-user influxuser \
		-password password \
		-replication 1
}

run_traffic_stats() {
	go run . -cfg "$TC/dev/traffic_stats/traffic_stats.cfg"
}

wait_for_traffic_ops
wait_for_traffic_monitor
wait_for_influxdb
init_databases

run_traffic_stats &
ts_pid="$!"

while inotifywait --include '\.go$' -e modify -r . ; do
	kill "$ts_pid" || true
	wait "$ts_pid" || true
	wait_for_traffic_ops
	wait_for_traffic_monitor
	wait_for_influxdb
	init_databases
	run_traffic_stats &
	ts_pid="$!"
	# for whatever reason, without this the repeated call to inotifywait will
	# sometimes lose track of the current directory.
	sleep 0.5
done
