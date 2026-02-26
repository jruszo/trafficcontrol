/*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

"use strict";
const child_process = require("child_process");
const fs = require("fs");
const path = require("path");
const dockerBuildProgress = process.env.CIAB_DOCKER_BUILD_PROGRESS || "auto";
const ciabBuildRetries = Number.parseInt(process.env.CIAB_BUILD_RETRIES || "2", 10);
const ciabBuildRetryDelaySeconds = Number.parseInt(process.env.CIAB_BUILD_RETRY_DELAY_SECONDS || "20", 10);
const spawnOptions = {
	stdio: "inherit",
	stderr: "inherit"
};
const dockerCompose = [
	"docker",
	"compose",
	`--progress=${dockerBuildProgress}`,
	"-f",
	"docker-compose.yml",
	"-f",
	"docker-compose.readiness.yml"
];
process.env.DOCKER_BUILDKIT = 1;
process.env.COMPOSE_DOCKER_CLI_BUILD = 1;
process.env.BUILDKIT_PROGRESS = dockerBuildProgress;
const workspace = process.env.GITHUB_WORKSPACE;
const distDirectory = `${workspace}/dist`;
const ciabDirectory = `${workspace}/infrastructure/cdn-in-a-box`;

function listFiles(directoryPath) {
	const entries = fs.readdirSync(directoryPath, {withFileTypes: true});
	return entries.flatMap(entry => {
		const entryPath = path.join(directoryPath, entry.name);
		if (entry.isDirectory()) {
			return listFiles(entryPath);
		}
		return [entryPath];
	});
}

function movePackageArtifactsToDistRoot() {
	process.chdir(distDirectory);
	for (const item of fs.readdirSync(".")) {
		if (!fs.lstatSync(item).isDirectory()) {
			continue;
		}
		const artifactFiles = listFiles(item)
			.filter(filePath => filePath.endsWith(".deb"));
		for (const artifactFile of artifactFiles) {
			const destination = path.basename(artifactFile);
			if (artifactFile === destination) {
				continue;
			}
			fs.renameSync(artifactFile, destination);
		}
	}
}

function listDebArtifacts() {
	return fs.readdirSync(distDirectory)
		.filter(item => item.endsWith(".deb"))
		.map(file => ({file, lower: file.toLowerCase()}));
}

function findDebArtifact(description, predicate, required = true) {
	const debFile = listDebArtifacts().find(predicate);
	if (debFile) {
		return debFile.file;
	}
	if (!required) {
		return null;
	}
	console.error(`Missing required Debian package for ${description} in ${distDirectory}`);
	process.exit(1);
}

function copyDebArtifact(sourceDebFile, destinationPathRelativeToCIAB) {
	if (!sourceDebFile) {
		return;
	}
	const destination = path.join(ciabDirectory, destinationPathRelativeToCIAB);
	fs.mkdirSync(path.dirname(destination), {recursive: true});
	fs.copyFileSync(path.join(distDirectory, sourceDebFile), destination);
}

function stageCiabDebArtifacts() {
	const trafficServerDevelDeb = findDebArtifact(
		"Traffic Server development package",
		deb => deb.lower.includes("trafficserver-devel"),
		false
	);
	const trafficServerDeb = findDebArtifact(
		"Traffic Server package",
		deb => deb.lower.includes("trafficserver") && !deb.lower.includes("devel")
	);
	const cacheConfigDeb = findDebArtifact(
		"Cache Config package",
		deb => deb.lower.includes("trafficcontrol-cache-config")
	);
	const healthClientDeb = findDebArtifact(
		"tc-health-client package",
		deb => deb.lower.includes("trafficcontrol-health-client") || deb.lower.includes("tc-health-client")
	);
	const trafficMonitorDeb = findDebArtifact(
		"Traffic Monitor package",
		deb => deb.lower.includes("traffic_monitor") || deb.lower.includes("traffic-monitor")
	);
	const trafficOpsDeb = findDebArtifact(
		"Traffic Ops package",
		deb => deb.lower.includes("traffic_ops") || deb.lower.includes("traffic-ops")
	);
	const trafficPortalDeb = findDebArtifact(
		"Traffic Portal package",
		deb => (deb.lower.includes("traffic_portal") || deb.lower.includes("traffic-portal")) &&
			!deb.lower.includes("v2")
	);
	const trafficPortalV2Deb = findDebArtifact(
		"Traffic Portal v2 package",
		deb => deb.lower.includes("traffic_portal_v2") || deb.lower.includes("traffic-portal-v2"),
		false
	);
	const trafficRouterDeb = findDebArtifact(
		"Traffic Router package",
		deb => deb.lower.includes("traffic_router") || deb.lower.includes("traffic-router")
	);
	const tomcatDeb = findDebArtifact(
		"Tomcat package",
		deb => deb.lower.startsWith("tomcat")
	);
	const trafficStatsDeb = findDebArtifact(
		"Traffic Stats package",
		deb => deb.lower.includes("traffic_stats") || deb.lower.includes("traffic-stats")
	);

	copyDebArtifact(trafficServerDeb, "cache/trafficserver.deb");
	copyDebArtifact(trafficServerDevelDeb, "cache/trafficserver-devel.deb");
	copyDebArtifact(cacheConfigDeb, "cache/trafficcontrol-cache-config.deb");
	copyDebArtifact(healthClientDeb, "health/trafficcontrol-health-client.deb");
	copyDebArtifact(healthClientDeb, "cache/trafficcontrol-health-client.deb");
	copyDebArtifact(trafficMonitorDeb, "traffic_monitor/traffic_monitor.deb");
	copyDebArtifact(trafficOpsDeb, "traffic_ops/traffic_ops.deb");
	copyDebArtifact(trafficPortalDeb, "traffic_portal/traffic_portal.deb");
	copyDebArtifact(trafficPortalV2Deb, "optional/traffic_portal_v2/traffic_portal_v2.deb");
	copyDebArtifact(trafficRouterDeb, "traffic_router/traffic_router.deb");
	copyDebArtifact(tomcatDeb, "traffic_router/tomcat.deb");
	copyDebArtifact(trafficStatsDeb, "traffic_stats/traffic_stats.deb");
}

function runProcess(...commandArguments) {
	console.info(...commandArguments);
	const proc = child_process.spawnSync(
		commandArguments[0],
		commandArguments.slice(1),
		spawnOptions
	);
	if (proc.error) {
		console.error("Child process", ...commandArguments, "failed to start:", proc.error);
		return 1;
	}
	return proc.status === null ? 1 : proc.status;
}

function sleepSeconds(seconds) {
	child_process.spawnSync("sleep", [String(seconds)], spawnOptions);
}

function runProcessWithRetries(commandArguments, retries, retryDelaySeconds) {
	for (let attempt = 1; attempt <= retries + 1; attempt++) {
		const exitCode = runProcess(...commandArguments);
		if (exitCode === 0) {
			return;
		}
		if (attempt <= retries) {
			console.warn(
				`Command failed with exit code ${exitCode} (attempt ${attempt}/${retries + 1}); retrying in ${retryDelaySeconds}s...`
			);
			sleepSeconds(retryDelaySeconds);
			continue;
		}
		console.error("Child process", ...commandArguments, "exited with status code", exitCode, "!");
		process.exit(exitCode);
	}
}

function nonNegativeInteger(value, fallbackValue) {
	return Number.isInteger(value) && value >= 0 ? value : fallbackValue;
}

function positiveInteger(value, fallbackValue) {
	return Number.isInteger(value) && value > 0 ? value : fallbackValue;
}

const effectiveRetries = nonNegativeInteger(ciabBuildRetries, 2);
const effectiveRetryDelaySeconds = positiveInteger(ciabBuildRetryDelaySeconds, 20);

movePackageArtifactsToDistRoot();
stageCiabDebArtifacts();
process.chdir(ciabDirectory);
runProcessWithRetries([...dockerCompose, "build", "--parallel"], effectiveRetries, effectiveRetryDelaySeconds);
