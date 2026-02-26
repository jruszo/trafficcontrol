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
	echo "Verifying the build configuration environment."
	local script scriptdir
	script="$(realpath "$0")"
	scriptdir="$(dirname "$script")"
	TR_DIR='' TC_DIR=''
	TR_DIR="$(dirname "$scriptdir")"
	TC_DIR="$(dirname "$TR_DIR")"
	export TR_DIR TC_DIR
	functions_sh="$TC_DIR/build/functions.sh"
	if [ ! -r "$functions_sh" ]; then
		echo "Error: Can't find $functions_sh"
		return 1
	fi
	. "$functions_sh"
}

#----------------------------------------
builddebTrafficRouter () {
	echo "Building the deb."

	export STARTUP_SCRIPT_DIR="/lib/systemd/system"
	export STARTUP_SCRIPT_LOC="../core/src/main/lib/systemd/system"
	export LOGROTATE_SCRIPT_DIR="/etc/logrotate.d"
	export LOGROTATE_SCRIPT_LOC="../core/src/main/lib/logrotate"

	cd "$TR_DIR" || { echo "Could not cd to $TR_DIR: $?"; return 1; }
	mvn -P deb-build -Dmaven.test.skip=true -DminimumTPS=1 clean package ||  \
		{ echo "DEB BUILD FAILED: $?"; return 1; }

	local deb
	deb="$(find . -name \*.deb | head -n1)"
	if [ -z "$deb" ]; then
		echo "Could not find deb file $DEB in $(pwd)"
		return 1;
	fi
	echo "========================================================================================"
	echo "DEB BUILD SUCCEEDED, See $DIST/$DEB for the newly built deb."
	echo "========================================================================================"
	echo
	mkdir -p "$DIST" || { echo "Could not create $DIST: $?"; return 1; }

	debDest="."
	if [[ "$SIMPLE" -eq 1 ]]; then
		debDest="traffic_router.deb";
	fi


	cp -f "$deb" "$DIST/$debDest" || { echo "Could not copy $deb to $DIST: $?"; return 1; }

}


#----------------------------------------
adaptEnvironment() {
	echo "Verifying the build configuration environment."
	# get traffic_control src path -- relative to build_deb.sh script
	PACKAGE='' TC_VERSION='' debbuild='' DIST='' DEB=''
	PACKAGE="traffic_router"
	TC_VERSION=$(getVersion "$TC_DIR")
	BUILD_NUMBER=${BUILD_NUMBER:-$(getBuildNumber)}
	WORKSPACE=${WORKSPACE:-$TC_DIR}
	debbuild="$WORKSPACE/debbuild"
	DIST="$WORKSPACE/dist"
	DEB="${PACKAGE}-${TC_VERSION}-${BUILD_NUMBER}.noarch.deb"
	deb_TARGET_OS="${deb_TARGET_OS:-linux}"
	source "${TC_DIR}/.env" # contains TOMCAT_VERSION
	export PACKAGE TC_VERSION BUILD_NUMBER WORKSPACE debbuild DIST DEB deb_TARGET_OS TOMCAT_VERSION

	echo "=================================================="
	echo "WORKSPACE: $WORKSPACE"
	echo "BUILD_NUMBER: $BUILD_NUMBER"
	echo "TOMCAT_VERSION=$TOMCAT_VERSION"
	echo "TC_VERSION: $TC_VERSION"
	echo "DEB: $DEB"
	echo "--------------------------------------------------"
}

# ---------------------------------------
initBuildArea() {
	echo "Initializing the build area."
	(mkdir -p "$debbuild"
	 cd "$debbuild"
	 mkdir -p SPECS SOURCES debS SdebS BUILD BUILDROOT) || { echo "Could not create $debbuild: $?"; return 1; }

	tr_dest=$(createSourceDir traffic_router)

	export MVN_CMD="mvn versions:set -DnewVersion=$TC_VERSION"
	echo "$MVN_CMD"
	(cd "$TR_DIR"; $MVN_CMD)
	cp -r "$TR_DIR"/build "$TR_DIR"/connector "$TR_DIR"/core "$tr_dest"/. || { echo "Could not copy to $tr_dest: $?"; return 1; }
	cp  "$TR_DIR"/pom.xml "$tr_dest" || { echo "Could not copy to $tr_dest: $?"; return 1; }

	# tar/gzip the source
	tar -czf "$tr_dest".tgz -C "$debbuild/SOURCES" "$(basename "$tr_dest")" || { echo "Could not create tar archive $tr_dest: $?"; return 1; }

	echo "The build area has been initialized."
}

#----------------------------------------
builddebTomcat () {
	echo "Building the deb for Tomcat."

	cd "$TR_DIR"/tomcat-deb || { echo "Could not cd to $TR_DIR/tomcat-deb: $?"; return 1; }
				bash ./build_deb.sh
}

# ---------------------------------------

importFunctions
checkEnvironment -i mvn
adaptEnvironment
initBuildArea
builddebTrafficRouter
builddebTomcat
