#!/usr/bin/env bash

# Written by Tim Bishop <tim@bishnet.net>, February 2019.

# gitlab-runner-shim is a script that replicates the artifact
# downloading and uploading features found in gitlab-runner. Its
# intended use case is on systems where you can't easily run
# gitlab-runner (or don't want to). It's probably most useful on
# systems where you're using the ssh executor (or the virtualbox or
# parallels executors which both use the ssh executor internally).

# Relevant APIs can be found here (linked commit works as of writing
# this, so check changes from there onwards if things break):
#
# https://gitlab.com/gitlab-org/gitlab-ce/blob/747a5c425a0ce1aa5e9005a03804f2ea513aa73b/lib/api/runner.rb#L298
# https://gitlab.com/gitlab-org/gitlab-ce/blob/747a5c425a0ce1aa5e9005a03804f2ea513aa73b/lib/api/runner.rb#L231
#
# And the gitlab-runner sources doing the same thing:
#
# https://gitlab.com/gitlab-org/gitlab-runner/blob/2979aa0623d58e5af746b6d69b49bbb3613b8443/network/gitlab.go#L486
# https://gitlab.com/gitlab-org/gitlab-runner/blob/2979aa0623d58e5af746b6d69b49bbb3613b8443/network/gitlab.go#L433

if [ X"${1}" = X"artifacts-downloader" ]; then
	curl \
		--silent --location \
		--cacert "${CI_SERVER_TLS_CA_FILE}" \
		--header "JOB-TOKEN: ${5}" \
		"${3}api/v4/jobs/${7}/artifacts" > artifacts.zip
	unzip -o -q artifacts.zip
	rm -f artifacts.zip
fi

if [ X"${1}" = X"artifacts-uploader" ]; then
	rm -f artifacts.zip
	zip -qr artifacts.zip ${9}
	E=`echo ${11} | tr " " "+"` export E
	curl \
		--silent --location \
		--cacert "${CI_SERVER_TLS_CA_FILE}" \
		--header "JOB-TOKEN: ${5}" \
		-F "file=@artifacts.zip" \
		"${3}api/v4/jobs/${7}/artifacts?artifact_format=${13}&artifact_type=${15}&expire_in=${E}" >/dev/null
	rm -f artifacts.zip
fi

# Otherwise implicit success, which is necessary because gitlab-runner
# checks --version works before trying to use the above.
