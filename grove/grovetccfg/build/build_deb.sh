#!/usr/bin/env sh
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# shellcheck shell=ash
trap 'exit_code=$?; [ $exit_code -ne 0 ] && echo "Error on line ${LINENO} of ${0}" >/dev/stderr; exit $exit_code' EXIT;
set -o errexit -o nounset -o pipefail;

#----------------------------------------
importFunctions() {
	[ -n "$TC_DIR" ] || { echo "Cannot find repository root." >&2 ; exit 1; }
	export TC_DIR
	functions_sh="$TC_DIR/build/functions.sh"
	if [ ! -r "$functions_sh" ]; then
		echo "Error: Can't find $functions_sh"
		return 1
	fi
	. "$functions_sh"
}

#----------------------------------------
checkGroveEnvironment() {
	echo "Verifying the build configuration environment."
	local script scriptdir
	script=$(realpath "$0")
	scriptdir=$(dirname "$script")

	GROVETC_DIR='' GROVE_DIR='' GROVE_VERSION='' PACKAGE='' debbuild='' DIST='' DEB=''
	GROVETC_DIR=$(dirname "$scriptdir")
	GROVE_DIR=$(dirname "$GROVETC_DIR")
	GROVE_VERSION="$(cat "${GROVE_DIR}/VERSION")"
	PACKAGE="grovetccfg"
	BUILD_NUMBER=${BUILD_NUMBER:-$(getBuildNumber)}
	debbuild="${GROVE_DIR}/debbuild"
	DIST="${TC_DIR}/dist"
	DEB="${PACKAGE}-${GROVE_VERSION}-${BUILD_NUMBER}.${ubuntu_VERSION}.$(deb --eval %_arch).deb"
	SDEB="${PACKAGE}-${GROVE_VERSION}-${BUILD_NUMBER}.${ubuntu_VERSION}.src.deb"
	GOOS="${GOOS:-linux}"
	deb_TARGET_OS="${deb_TARGET_OS:-$GOOS}"
	export GROVETC_DIR GROVE_DIR GROVE_VERSION PACKAGE BUILD_NUMBER debbuild DIST DEB GOOS deb_TARGET_OS

	echo "=================================================="
	echo "GO_VERSION: $GO_VERSION"
	echo "TC_DIR: $TC_DIR"
	echo "PACKAGE: $PACKAGE"
	echo "GROVE_DIR: $GROVE_DIR"
	echo "GROVETC_DIR: $GROVETC_DIR"
	echo "GROVE_VERSION: $GROVE_VERSION"
	echo "BUILD_NUMBER: $BUILD_NUMBER"
	echo "DIST: $DIST"
	echo "DEB: $DEB"
	echo "debbuild: $debbuild"
	echo "--------------------------------------------------"
}

# ---------------------------------------
initBuildArea() {
	cd "$GROVETC_DIR"

	# prep build environment
	[ -e "$debbuild" ] && rm -rf "$debbuild"
	[ ! -e "$debbuild" ] || { echo "Failed to clean up deb build directory '$debbuild': $?" >&2; return 1; }
	(mkdir -p "$debbuild"
	 cd "$debbuild"
	 mkdir -p BUILD debS SOURCES) || { echo "Failed to create build directory '$debbuild': $?" >&2; return 1; }
}

# ---------------------------------------
builddebGrove() {
	# build
	ldflags='-s -w'
	export CGO_ENABLED=0
	go mod vendor -v || { echo "Failed to vendor go dependencies: $?" >&2; return 1; }
	go build -v -ldflags "${ldflags} -X main.Version=$GROVE_VERSION" || { echo "Failed to build $PACKAGE: $?" >&2; return 1; }

	# tar
	tar -cvzf "${debbuild}/SOURCES/${PACKAGE}-${GROVE_VERSION}.tgz" ${PACKAGE}|| { echo "Failed to create archive for debbuild: $?" >&2; return 1; }

	# Work around bug in debbuild. Fixed in debbuild 4.13.
	# See: https://github.com/deb-software-management/deb/commit/916d528b0bfcb33747e81a57021e01586aa82139
	# Takes ownership of the spec file.
	spec=build/${PACKAGE}.spec
	spec_owner=$(stat -c%u $spec)
	spec_group=$(stat -c%g $spec)
	if ! id "$spec_owner" >/dev/null 2>&1; then
		chown "$(id -u):$(id -g)" build/${PACKAGE}.spec

		give_spec_back() {
		chown "${spec_owner}:${spec_group}" build/${PACKAGE}.spec
		}
		trap give_spec_back EXIT
	fi

	build_flags="-ba";
	if [[ "$NO_SOURCE" -eq 1 ]]; then
		build_flags="-bb";
	fi


	# build DEB with xz level 2 compression
	debbuild \
		--define "_topdir $debbuild" \
		--define "version ${GROVE_VERSION}" \
		--define "build_number ${BUILD_NUMBER}.${ubuntu_VERSION}" \
		--define "_target_os ${deb_TARGET_OS}" \
		--define '%_source_payload w2.xzdio' \
		--define '%_binary_payload w2.xzdio' \
		$build_flags build/${PACKAGE}.spec ||
		{ echo "debbuild failed: $?" >&2; return 1; }


	debDest=".";
	srcdebDest=".";
	if [[ "$SIMPLE" -eq 1 ]]; then
		debDest="grovetccfg.deb";
		srcdebDest="grovetccfg.src.deb";
	fi

	# copy build DEB to .
	[ -d "$DIST" ] || mkdir -p "$DIST";

	cp -f "$debbuild/debS/$(deb --eval %_arch)/${DEB}" "$DIST/$debDest";
	code="$?";
	if [[ "$code" -ne 0 ]]; then
		echo "Could not copy $deb to $DIST: $code" >&2;
		return "$code";
	fi

	if [[ "$NO_SOURCE" -eq 1 ]]; then
		return 0;
	fi

	cp -f "$debbuild/SdebS/${SDEB}" "$DIST/$srcdebDest";
	code="$?";
	if [[ "$code" -ne 0 ]]; then
		echo "Could not copy $sdeb to $DIST: $code" >&2;
		return "$code";
	fi
}

importFunctions
checkEnvironment -i go
checkGroveEnvironment
initBuildArea
builddebGrove
